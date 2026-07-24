/// inventory_screen.dart
/// ---------------------------------------------------------------------------
/// The INVENTORY TAB — re-imagining the old spreadsheet's "Inventory" tab.
///
/// APPAREL is fully modelled after the site's Apparel sub-system: each piece
/// has a Craftsmanship Grade (→ Craft DC / Apparel Grade / Quality Slots), an
/// Apparel Category, a Size, a Worn/Layer state, a Break Value, and a list of
/// Apparel Qualities chosen from the `data/apparel.dart` catalogue. The derived
/// Apparel Bonus, Category benefit, Quality-Slot budget, Break-Value maximum,
/// multi-layer Apparel Penalty and Armor Damage Reduction are all computed by
/// [CharacterCalculator] and fed into the sheet's stats — see that engine.
///
/// WEAPONS are likewise fully modelled after the site's Weapon sub-system: each
/// has a Weapon Type (Physical/Energy/Magic), Size, Category, Craftsmanship
/// Grade (→ Craft DC / Quality Slots), Life Points and a list of Weapon
/// Qualities from the `data/weapons.dart` catalogue. The Weapon Penalty,
/// per-Attack Strike/Wound modifiers, Life Points and Warding Damage Reduction
/// are computed by [CharacterCalculator] — see that engine.
///
/// ACCESSORIES / GEAR remain freeform, un-automated trackers (see
/// [InventoryItem]) until their own sub-systems are modelled — a future
/// milestone. Nothing in those two sections is applied to any stat.
///
/// Follows the shared tab contract `({character, stats, onUpdate})`.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/accessories.dart';
import '../data/apparel.dart';
import '../data/basic_items.dart';
import '../data/dbu_rules.dart';
import '../data/homebrew_registry.dart';
import '../data/weapons.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import 'widgets/sheet_widgets.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  /// The SAME working copy the other tabs are editing.
  final Character character;

  /// Freshly recomputed derived stats (Apparel reads its own derived values
  /// off the calculator directly; the freeform sections ignore this).
  final DerivedCharacterStats stats;

  /// Applies a mutation to [character] and tells the parent to recompute.
  final void Function(VoidCallback mutate) onUpdate;

  Character get _c => character;

  /// Signed-integer formatter ("+3" / "-1").
  // Signed formatter with a clean "+0" for zero (guards a negative-zero double
  // that would otherwise render "+-0.0") and no spurious trailing ".0".
  String _fmt(num n) {
    final v = n == n.roundToDouble() ? n.toInt() : n;
    return v == 0 ? '+0' : (v > 0 ? '+$v' : '$v');
  }

  @override
  Widget build(BuildContext context) {
    // Freeform sections: everything except the structured ones (Apparel,
    // Weapons, Accessories). Only Gear remains freeform.
    const freeform = [
      InventoryCategory.gear,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildIntro(context),
            _buildApparelSection(context),
            _buildWeaponsSection(context),
            _buildAccessoriesSection(context),
            _buildBasicItemsSection(context),
            for (final category in freeform)
              _buildFreeformSection(context, category),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return SectionCard(
      title: 'Inventory',
      icon: Icons.backpack_outlined,
      child: Text(
        'Apparel, Weapons and Accessories — their '
        'Category, Qualities, Break/Life values, per-Attack modifiers and '
        '"while equipped" effects feed your stats automatically. Basic '
        'Items are a reference catalogue, '
        'Gear is a freeform tracker for anything else.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  // ==========================================================================
  // APPAREL  (structured / automated)
  // ==========================================================================
  Widget _buildApparelSection(BuildContext context) {
    final needsNaturalArmor = CharacterCalculator.grantsNaturalArmor(_c) &&
        !CharacterCalculator.hasNaturalArmorPiece(_c);
    return SectionCard(
      title: 'Apparel',
      icon: Icons.checkroom_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Add Natural Armor',
            icon: const Icon(Icons.shield_moon_outlined),
            onPressed: () => onUpdate(() => _c.apparel.add(_newNaturalArmor())),
          ),
          IconButton(
            tooltip: 'Add Apparel',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onUpdate(() => _c.apparel.add(ApparelPiece())),
          ),
        ],
      ),
      child: Column(
        children: [
          if (needsNaturalArmor) _buildNaturalArmorHint(context),
          _buildBattleUniformInfo(context),
          if (_c.apparel.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No Apparel yet.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          for (final piece in _c.apparel) _buildApparelPiece(context, piece),
          if (_c.apparel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DerivedStat(
                  label: 'Armor Damage Reduction',
                  value: '${stats.apparelDamageReduction}',
                  emphasize: true,
                ),
                DerivedStat(
                  label: 'Apparel Penalty (Combat Rolls)',
                  value: _fmt(-stats.apparelPenalty),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Toggles a piece to/from Natural Armor, keeping its other fields in a
  /// legal state (Natural Armor is always Integrated Armor on the Bottom
  /// Layer, and drops any Quality that isn't valid for the Armor Category).
  void _setNaturalArmor(ApparelPiece piece, bool on) {
    piece.isNaturalArmor = on;
    if (!on) return;
    piece.category = ApparelCategory.armor;
    piece.layer = WornLayer.bottom;
    piece.worn = true;
    if (piece.name.trim().isEmpty) piece.name = 'Natural Armor';
    piece.qualities.removeWhere((q) {
      final def = HomebrewRegistry.resolveApparelQuality(q.name);
      return def != null && !def.categories.contains(ApparelCategory.armor);
    });
  }

  /// A read-only, bordered field mirroring the look of the editable dropdowns —
  /// used for values Natural Armor derives and doesn't let the player change.
  Widget _readOnlyField(BuildContext context,
      {required String label, required String value}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        enabled: false,
      ),
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  /// A fresh Natural Armor piece — Integrated Armor whose Grade derives from
  /// the wearer's base Tier of Power (see `CharacterCalculator`).
  ApparelPiece _newNaturalArmor() => ApparelPiece(
        name: 'Natural Armor',
        isNaturalArmor: true,
        category: ApparelCategory.armor,
        layer: WornLayer.bottom,
        worn: true,
        // Break Value starts full; it is fully repaired each Combat Encounter.
        breakValue: kDefaultApparelBreakValue,
      );

  /// Shown when a Racial/Factor/Custom-Species Trait grants Natural Armor but
  /// the player hasn't created the piece yet — one tap adds it.
  /// Read-only panel listing the Battle Uniform(s) auto-equipped by the
  /// character's in-effect Transformations. While one is active the manual
  /// Apparel below is suppressed — the uniform's Grade/Category feed the
  /// derived stats. Renders nothing when no Battle Uniform is in effect.
  Widget _buildBattleUniformInfo(BuildContext context) {
    final uniforms = CharacterCalculator.activeBattleUniforms(_c).toList();
    if (uniforms.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom,
                  size: 18, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Text('Battle Uniform — auto-equipped',
                  style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          for (final u in uniforms)
            Text(
              '${u.source}: ${u.uniform.category.displayName}, '
              'Craftsmanship Grade ${u.uniform.craftsmanshipGrade}',
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 2),
          Text(
            uniforms.length > 1
                ? 'While a Battle Uniform is in effect you lose access to your '
                    'manual Apparel. Only the highest-priority uniform '
                    "(an Enhancement's) applies its Grade/Category."
                : 'While in effect you lose access to your manual Apparel; the '
                    'uniform\'s Grade/Category feed the derived stats.',
            style: theme.textTheme.labelSmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildNaturalArmorHint(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_moon_outlined,
              size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'One of your Traits grants Natural Armor. Add it to apply its '
              'Damage Reduction (it scales with your Tier of Power).',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () => onUpdate(() => _c.apparel.add(_newNaturalArmor())),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildApparelPiece(BuildContext context, ApparelPiece piece) {
    final theme = Theme.of(context);
    final nat = piece.isNaturalArmor;
    final info = craftsmanshipInfo(
        CharacterCalculator.effectiveCraftGrade(_c, piece));
    final bonus = CharacterCalculator.apparelBonus(_c, piece);
    final maxBv = CharacterCalculator.apparelMaxBreakValue(piece);
    final slotsUsed = CharacterCalculator.apparelQualitySlotsUsed(piece);
    final slotsAvail = info.qualitySlots;
    final overSlots = slotsUsed > slotsAvail;
    final active = CharacterCalculator.apparelIsActive(piece);
    final unbreakable = CharacterCalculator.apparelIsUnbreakable(piece);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: piece.name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() => piece.name = v),
                ),
              ),
              // Active/inactive indicator, mirroring the sheet's "(inactive)".
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  active ? 'Active' : '(inactive)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onUpdate(() => _c.apparel.remove(piece)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Natural Armor toggle — flips the piece to Integrated Armor whose
          // Grade tracks the wearer's Tier of Power (see CharacterCalculator).
          Row(
            children: [
              FilterChip(
                avatar: Icon(
                  Icons.shield_moon_outlined,
                  size: 18,
                  color: nat ? theme.colorScheme.onSecondaryContainer : null,
                ),
                label: const Text('Natural Armor'),
                selected: nat,
                onSelected: (v) => onUpdate(() => _setNaturalArmor(piece, v)),
              ),
              if (nat) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Integrated Armor · Grade from Tier of Power · always active',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Grade / Category / Size selectors. Natural Armor derives its Grade
          // and is always Armor, so those two are read-only for it.
          // A Wrap, not a 3-across Row: on a phone three dropdowns each got
          // ~88px and truncated their values ("Stan"/"Medi"); at a fixed width
          // they reflow 2-up and stay readable.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 128,
                child: nat
                    ? _readOnlyField(
                        context,
                        label: 'Craft',
                        value: '${info.grade} · ${info.craftDc}',
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: piece.craftsmanshipGrade.clamp(1, 5),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Craft',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final g in kCraftsmanshipGrades)
                            DropdownMenuItem(
                              value: g.grade,
                              child: Text('${g.grade} · ${g.craftDc}'),
                            ),
                        ],
                        onChanged: (v) => onUpdate(() =>
                            piece.craftsmanshipGrade =
                                v ?? piece.craftsmanshipGrade),
                      ),
              ),
              SizedBox(
                width: 128,
                child: nat
                    ? _readOnlyField(
                        context,
                        label: 'Category',
                        value: ApparelCategory.armor.displayName,
                      )
                    : DropdownButtonFormField<ApparelCategory>(
                        initialValue: piece.category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final cat in ApparelCategory.values)
                            DropdownMenuItem(
                                value: cat, child: Text(cat.displayName)),
                        ],
                        // Changing Category may invalidate chosen Qualities —
                        // drop any that no longer apply to the new Category.
                        onChanged: (v) => onUpdate(() {
                          if (v == null) return;
                          piece.category = v;
                          piece.qualities.removeWhere((q) {
                            final def =
                                HomebrewRegistry.resolveApparelQuality(q.name);
                            return def != null && !def.categories.contains(v);
                          });
                        }),
                      ),
              ),
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<DbuSize>(
                  initialValue: piece.size,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final s in DbuSize.values)
                      DropdownMenuItem(value: s, child: Text(s.displayName)),
                  ],
                  onChanged: (v) => onUpdate(() => piece.size = v ?? piece.size),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Worn + Layer + Break Value. Natural Armor is Integrated (always the
          // Bottom Layer and always active), so it hides Worn/Layer and keeps
          // only the Break Value (which auto-repairs each Combat Encounter).
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!nat) ...[
                FilterChip(
                  label: const Text('Worn'),
                  selected: piece.worn,
                  onSelected: (v) => onUpdate(() => piece.worn = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<WornLayer>(
                    initialValue: piece.layer,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Layer',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final l in WornLayer.values)
                        DropdownMenuItem(value: l, child: Text(l.displayName)),
                    ],
                    onChanged: piece.worn
                        ? (v) => onUpdate(() => piece.layer = v ?? piece.layer)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                Expanded(
                  child: _readOnlyField(
                    context,
                    label: 'Layer',
                    value: 'Bottom (Integrated)',
                  ),
                ),
              if (nat) const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: TextFormField(
                  key: ValueKey('bv-${identityHashCode(piece)}-$maxBv'),
                  initialValue: '${piece.breakValue}',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Break',
                    helperText: unbreakable
                        ? 'Unbreakable'
                        : (nat ? 'max $maxBv · auto-repairs' : 'max $maxBv'),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() =>
                      piece.breakValue = (int.tryParse(v.trim()) ?? 0).clamp(0, maxBv)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Derived readouts.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Apparel Grade',
                value: info.apparelGrade.displayName,
              ),
              DerivedStat(label: 'Apparel Bonus', value: '$bonus', emphasize: true),
              DerivedStat(
                label: 'Quality Slots',
                value: '$slotsUsed / $slotsAvail',
                warn: overSlots,
                tooltip: overSlots
                    ? 'Over the Quality-Slot budget for this Craftsmanship Grade'
                    : null,
              ),
              DerivedStat(label: 'Craft DC', value: info.craftDc),
              DerivedStat(label: 'Category Effect', value: _categoryEffect(piece, bonus)),
            ],
          ),
          const SizedBox(height: 12),
          _buildQualityList(context, piece),
          const SizedBox(height: 4),
          ResizableTextField(
            key: ValueKey('apparel-notes-${identityHashCode(piece)}'),
            label: 'Notes',
            value: piece.notes,
            initialLines: 2,
            onChanged: (v) => onUpdate(() => piece.notes = v),
          ),
        ],
      ),
    );
  }

  /// A short human-readable summary of the piece's Category benefit.
  String _categoryEffect(ApparelPiece piece, int bonus) {
    switch (piece.category) {
      case ApparelCategory.armor:
        return piece.isNaturalArmor
            ? 'Damage Reduction +$bonus (Integrated)'
            : 'Damage Reduction +$bonus (Top Layer)';
      case ApparelCategory.weights:
        return '${_fmt(-bonus)} all Combat Rolls';
      case ApparelCategory.combatClothing:
        return 'Defense Value +${(bonus + 1) ~/ 2} (Top Layer)';
      case ApparelCategory.standardClothing:
        return 'No Apparel Penalty; −1 Craft DC';
    }
  }

  Widget _buildQualityList(BuildContext context, ApparelPiece piece) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Apparel Qualities',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Quality'),
              onPressed: () => _pickQuality(context, piece),
            ),
          ],
        ),
        if (piece.qualities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('No Qualities on this piece.',
                style: theme.textTheme.bodySmall),
          ),
        for (final sel in piece.qualities) _buildQualityRow(context, piece, sel),
      ],
    );
  }

  Widget _buildQualityRow(
      BuildContext context, ApparelPiece piece, ApparelQualitySelection sel) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.resolveApparelQuality(sel.name);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sel.name.isEmpty ? '(unknown Quality)' : sel.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (def != null && def.isSpecial)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('Special',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.tertiary)),
                ),
              Icon(
                def?.isAutomated == true ? Icons.bolt : Icons.notes,
                size: 16,
                color: def?.isAutomated == true
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              // Slot count — a stepper when the Quality has a range, else a
              // static "1 slot" label.
              if (def != null && def.hasSlotRange)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: sel.slots > def.minSlots
                          ? () => onUpdate(() => sel.slots -= 1)
                          : null,
                    ),
                    Text('${sel.slots} slot${sel.slots == 1 ? '' : 's'}',
                        style: theme.textTheme.labelMedium),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: sel.slots < def.maxSlots
                          ? () => onUpdate(() => sel.slots += 1)
                          : null,
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${sel.slots} slot${sel.slots == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall),
                ),
              IconButton(
                tooltip: 'Remove Quality',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    onUpdate(() => piece.qualities.remove(sel)),
              ),
            ],
          ),
          if (def != null) ...[
            Text(def.effects, style: theme.textTheme.bodySmall),
            if (def.prerequisites != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Prereq (wearer): ${def.prerequisites}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
            if (!def.isAutomated)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Not automated — apply this effect yourself.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
          // Optional per-Quality note (Team Name, chosen Skill, etc.).
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextFormField(
              initialValue: sel.notes,
              decoration: const InputDecoration(
                labelText: 'Notes (chosen Skill / Team Name / …)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onUpdate(() => sel.notes = v),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a picker of the Qualities available to this piece's Category
  /// (filtering out ones already on the piece), grouped Standard / Special.
  Future<void> _pickQuality(BuildContext context, ApparelPiece piece) async {
    final taken = piece.qualities.map((q) => q.name).toSet();
    final available = [
      ...apparelQualitiesFor(piece.category),
      ...HomebrewRegistry.apparelQualityDefs()
          .where((q) => q.categories.contains(piece.category)),
    ].where((q) => !taken.contains(q.name)).toList();
    final chosen = await showDialog<ApparelQualityDef>(
      context: context,
      builder: (ctx) => _ApparelQualityPickerDialog(
        category: piece.category,
        qualities: available,
      ),
    );
    if (chosen == null) return;
    onUpdate(() => piece.qualities.add(
          ApparelQualitySelection(name: chosen.name, slots: chosen.minSlots),
        ));
  }

  // ==========================================================================
  // WEAPONS  (structured / automated)
  // ==========================================================================
  Widget _buildWeaponsSection(BuildContext context) {
    final theme = Theme.of(context);
    final wielded = _c.weapons.where((w) => w.wielded).length;
    final overWield = wielded > kMaxWieldedWeapons;
    return SectionCard(
      title: 'Weapons',
      icon: Icons.sports_martial_arts,
      trailing: IconButton(
        tooltip: 'Add Weapon',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => onUpdate(() => _c.weapons.add(WeaponPiece())),
      ),
      child: Column(
        children: [
          if (_c.weapons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No Weapons yet.',
                  style: theme.textTheme.bodySmall),
            ),
          for (final weapon in _c.weapons) _buildWeaponPiece(context, weapon),
          if (_c.weapons.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DerivedStat(
                  label: 'Weapon Penalty (Strike)',
                  value: _fmt(-stats.weaponPenalty),
                  tooltip: CharacterCalculator.hasWeaponSpecialist(_c)
                      ? 'Nullified by the Weapon Specialist Talent'
                      : 'While wielding any Weapon: −2(T) Strike',
                ),
                if (stats.weaponDamageReduction > 0)
                  DerivedStat(
                    label: 'Warding Damage Reduction',
                    value: '${stats.weaponDamageReduction}',
                    emphasize: true,
                  ),
                DerivedStat(
                  label: 'Wielded',
                  value: '$wielded / $kMaxWieldedWeapons',
                  warn: overWield,
                  tooltip: overWield
                      ? 'You can only wield two Weapons at a time'
                      : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeaponPiece(BuildContext context, WeaponPiece weapon) {
    final theme = Theme.of(context);
    final info = craftsmanshipInfo(weapon.craftsmanshipGrade);
    final maxLife = CharacterCalculator.weaponMaxLife(_c, weapon);
    final curLife = CharacterCalculator.weaponCurrentLife(_c, weapon);
    final slotsUsed = CharacterCalculator.weaponQualitySlotsUsed(weapon);
    final slotsAvail = info.qualitySlots;
    final overSlots = slotsUsed > slotsAvail;
    final active = CharacterCalculator.weaponIsActive(_c, weapon);
    final unbreakable = CharacterCalculator.weaponIsUnbreakable(weapon);
    final selfDr = CharacterCalculator.weaponSelfDamageReduction(_c);

    // Per-Weapon Armed-Attack totals: the sheet's base Strike/Wound (which
    // already include the global Weapon Penalty) plus this Weapon's own Size/
    // Category/Quality modifiers.
    final mods = CharacterCalculator.weaponModifiers(_c, weapon);
    final woundStat = switch (weapon.type) {
      WeaponType.physical => stats.woundPhysical,
      WeaponType.energy => stats.woundEnergy,
      WeaponType.magic => stats.woundMagic,
    };
    final woundAffected = switch (weapon.type) {
      WeaponType.physical => AffectedStat.woundPhysical,
      WeaponType.energy => AffectedStat.woundEnergy,
      WeaponType.magic => AffectedStat.woundMagic,
    };
    final armedStrike = stats.strike.total + (mods[AffectedStat.strike] ?? 0);
    final armedWound = woundStat.total + (mods[woundAffected] ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: weapon.name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() => weapon.name = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  active ? 'Active' : '(inactive)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onUpdate(() => _c.weapons.remove(weapon)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Type / Size / Craftsmanship selectors. A Wrap so the three
          // dropdowns reflow 2-up on a phone instead of truncating their values.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<WeaponType>(
                  initialValue: weapon.type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final t in WeaponType.values)
                      DropdownMenuItem(value: t, child: Text(t.displayName)),
                  ],
                  // Changing Type invalidates the Category and any Type-specific
                  // Qualities — clear the Category and drop stale Qualities.
                  onChanged: (v) => onUpdate(() {
                    if (v == null) return;
                    weapon.type = v;
                    weapon.category = '';
                    weapon.qualities.removeWhere((q) {
                      final def =
                          HomebrewRegistry.resolveWeaponQuality(q.name);
                      return def != null && !def.types.contains(v);
                    });
                  }),
                ),
              ),
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<WeaponSize>(
                  initialValue: weapon.size,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final s in WeaponSize.values)
                      DropdownMenuItem(value: s, child: Text(s.displayName)),
                  ],
                  onChanged: (v) => onUpdate(() => weapon.size = v ?? weapon.size),
                ),
              ),
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<int>(
                  initialValue: weapon.craftsmanshipGrade.clamp(1, 5),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Craft',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final g in kCraftsmanshipGrades)
                      DropdownMenuItem(
                        value: g.grade,
                        child: Text('${g.grade} · ${g.craftDc}'),
                      ),
                  ],
                  onChanged: (v) => onUpdate(() =>
                      weapon.craftsmanshipGrade = v ?? weapon.craftsmanshipGrade),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Category + Wielded + Life Points.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Builder(builder: (context) {
                  final available = weaponCategoriesFor(weapon.type);
                  // Guard against a stale Category (e.g. from a corrupt save
                  // where it doesn't match the current Type) — the dropdown
                  // asserts if given a value absent from its items.
                  final valid =
                      available.any((cat) => cat.name == weapon.category);
                  return DropdownButtonFormField<String>(
                    initialValue: valid ? weapon.category : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    hint: const Text('None'),
                    items: [
                      for (final cat in available)
                        DropdownMenuItem(value: cat.name, child: Text(cat.name)),
                    ],
                    onChanged: (v) => onUpdate(() => weapon.category = v ?? ''),
                  );
                }),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Wielded'),
                selected: weapon.wielded,
                onSelected: (v) => onUpdate(() => weapon.wielded = v),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: TextFormField(
                  key: ValueKey('wlp-${identityHashCode(weapon)}-$maxLife'),
                  initialValue: '$curLife',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Life',
                    helperText: unbreakable ? 'Unbreakable' : 'max $maxLife',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() => weapon.lifePoints =
                      (int.tryParse(v.trim()) ?? 0).clamp(0, maxLife)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Derived readouts.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Life Points',
                value: '$curLife / $maxLife',
                emphasize: true,
              ),
              DerivedStat(label: 'Damage Reduction', value: '$selfDr'),
              DerivedStat(
                label: 'Quality Slots',
                value: '$slotsUsed / $slotsAvail',
                warn: overSlots,
                tooltip: overSlots
                    ? 'Over the Quality-Slot budget for this Craftsmanship Grade'
                    : null,
              ),
              DerivedStat(label: 'Craft DC', value: info.craftDc),
              DerivedStat(
                label: 'Armed Strike',
                value: _fmt(armedStrike),
                tooltip: 'Your Strike Roll for an Armed Attack with this Weapon '
                    '(includes the Weapon Penalty and this Weapon’s Size / '
                    'Category / Quality modifiers).',
              ),
              DerivedStat(
                label: 'Armed Wound (${weapon.type.displayName})',
                value: _fmt(armedWound),
                tooltip: 'Your Wound Roll for an Armed Attack with this Weapon.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWeaponQualityList(context, weapon),
          const SizedBox(height: 4),
          ResizableTextField(
            key: ValueKey('weapon-notes-${identityHashCode(weapon)}'),
            label: 'Notes',
            value: weapon.notes,
            initialLines: 2,
            onChanged: (v) => onUpdate(() => weapon.notes = v),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponQualityList(BuildContext context, WeaponPiece weapon) {
    final theme = Theme.of(context);
    final cat = CharacterCalculator.weaponCategory(weapon);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The chosen Category's effects (verbatim) + any free granted Quality.
        if (cat != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cat.name} Category',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(cat.effects, style: theme.textTheme.bodySmall),
                if (cat.grantedQuality.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Grants the ${cat.grantedQuality} Quality free '
                      '(no Quality Slot).',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text('Weapon Qualities',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Quality'),
              onPressed: () => _pickWeaponQuality(context, weapon),
            ),
          ],
        ),
        if (weapon.qualities.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('No Qualities on this Weapon.',
                style: theme.textTheme.bodySmall),
          ),
        for (final sel in weapon.qualities)
          _buildWeaponQualityRow(context, weapon, sel),
      ],
    );
  }

  Widget _buildWeaponQualityRow(
      BuildContext context, WeaponPiece weapon, WeaponQualitySelection sel) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.resolveWeaponQuality(sel.name);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sel.name.isEmpty ? '(unknown Quality)' : sel.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (def != null && def.isSpecial)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('Special',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.tertiary)),
                ),
              Icon(
                def?.isAutomated == true ? Icons.bolt : Icons.notes,
                size: 16,
                color: def?.isAutomated == true
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (def != null && def.hasSlotRange)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: sel.slots > def.minSlots
                          ? () => onUpdate(() => sel.slots -= 1)
                          : null,
                    ),
                    Text('${sel.slots} slot${sel.slots == 1 ? '' : 's'}',
                        style: theme.textTheme.labelMedium),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: sel.slots < def.maxSlots
                          ? () => onUpdate(() => sel.slots += 1)
                          : null,
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('${sel.slots} slot${sel.slots == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall),
                ),
              IconButton(
                tooltip: 'Remove Quality',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onUpdate(() => weapon.qualities.remove(sel)),
              ),
            ],
          ),
          if (def != null) ...[
            Text(def.effects, style: theme.textTheme.bodySmall),
            if (def.prerequisites != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Prereq (wielder): ${def.prerequisites}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
            if (!def.isAutomated)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Not automated — apply this effect yourself.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextFormField(
              initialValue: sel.notes,
              decoration: const InputDecoration(
                labelText: 'Notes (chosen Profile / Alignment / …)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onUpdate(() => sel.notes = v),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a picker of the Qualities available to this Weapon's Type (filtering
  /// out ones already on the Weapon), grouped Standard / Special.
  Future<void> _pickWeaponQuality(
      BuildContext context, WeaponPiece weapon) async {
    final taken = weapon.qualities.map((q) => q.name).toSet();
    final available = [
      ...weaponQualitiesFor(weapon.type),
      ...HomebrewRegistry.weaponQualityDefs()
          .where((q) => q.types.contains(weapon.type)),
    ].where((q) => !taken.contains(q.name)).toList();
    final chosen = await showDialog<WeaponQualityDef>(
      context: context,
      builder: (ctx) => _WeaponQualityPickerDialog(
        type: weapon.type,
        qualities: available,
      ),
    );
    if (chosen == null) return;
    onUpdate(() => weapon.qualities.add(
          WeaponQualitySelection(name: chosen.name, slots: chosen.minSlots),
        ));
  }

  // ==========================================================================
  // ACCESSORIES  (structured / automated — catalogue picks)
  // ==========================================================================
  Widget _buildAccessoriesSection(BuildContext context) {
    final theme = Theme.of(context);
    final equipped = CharacterCalculator.equippedAccessoryCount(_c);
    final overEquip = equipped > kMaxEquippedAccessories;
    return SectionCard(
      title: 'Accessories',
      icon: Icons.diamond_outlined,
      trailing: IconButton(
        tooltip: 'Add Accessory',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _pickAccessory(context),
      ),
      child: Column(
        children: [
          if (_c.accessories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No Accessories yet.',
                  style: theme.textTheme.bodySmall),
            ),
          for (final sel in _c.accessories) _buildAccessoryRow(context, sel),
          if (_c.accessories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DerivedStat(
                  label: 'Equipped',
                  value: '$equipped / $kMaxEquippedAccessories',
                  warn: overEquip,
                  tooltip: overEquip
                      ? 'You can only equip up to 2 Accessories at once'
                      : null,
                ),
                if (stats.accessoryDamageReduction > 0)
                  DerivedStat(
                    label: 'Accessory Damage Reduction',
                    value: '${stats.accessoryDamageReduction}',
                    emphasize: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessoryRow(BuildContext context, AccessorySelection sel) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.resolveAccessory(sel.name);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name on its own full-width line; the badges + Equipped chip +
          // delete sit on a second line — crammed onto the name row they
          // starved a badged accessory's name to a 1-2 word vertical stack.
          Text(
            sel.name.isEmpty ? '(unknown Accessory)' : sel.name,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (def != null && def.isTech)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('Tech',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.secondary)),
                ),
              if (def != null && def.isSpecial)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('Special',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.tertiary)),
                ),
              Icon(
                def?.isAutomated == true ? Icons.bolt : Icons.notes,
                size: 16,
                color: def?.isAutomated == true
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Equipped'),
                selected: sel.equipped,
                onSelected: (v) => onUpdate(() => sel.equipped = v),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onUpdate(() => _c.accessories.remove(sel)),
              ),
            ],
          ),
          if (def != null) ...[
            if (def.craftDc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Craft DC: ${def.craftDc}',
                    style: theme.textTheme.labelSmall),
              ),
            Text(def.effects, style: theme.textTheme.bodySmall),
            if (!def.isAutomated)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Not automated — apply this effect yourself.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextFormField(
              initialValue: sel.notes,
              decoration: const InputDecoration(
                labelText: 'Notes (Intended Character / connected Item / …)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onUpdate(() => sel.notes = v),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the Accessories catalogue picker (grouped Standard / Special,
  /// searchable) and adds the chosen Accessory.
  Future<void> _pickAccessory(BuildContext context) async {
    final taken = _c.accessories.map((a) => a.name).toSet();
    final available = [...kDbuAccessories, ...HomebrewRegistry.accessoryDefs()]
        .where((a) => !taken.contains(a.name))
        .toList();
    final chosen = await showDialog<AccessoryDef>(
      context: context,
      builder: (ctx) => _AccessoryPickerDialog(accessories: available),
    );
    if (chosen == null) return;
    onUpdate(() => _c.accessories.add(AccessorySelection(name: chosen.name)));
  }

  // ==========================================================================
  // BASIC ITEMS  (structured catalogue — reference only, not automated)
  // ==========================================================================
  Widget _buildBasicItemsSection(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Basic Items',
      icon: Icons.category_outlined,
      trailing: IconButton(
        tooltip: 'Add Basic Item',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _pickBasicItem(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Consumables and gadgets. These are Action-triggered — read the '
              "effect and apply it yourself "
              'Tags: [Tech] Technology · [Med] Medicine · [Food] cooked.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          if (_c.basicItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No Basic Items yet.',
                  style: theme.textTheme.bodySmall),
            ),
          for (final sel in _c.basicItems) _buildBasicItemRow(context, sel),
        ],
      ),
    );
  }

  Widget _buildBasicItemRow(BuildContext context, BasicItemSelection sel) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.resolveBasicItem(sel.name);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  sel.name.isEmpty ? '(unknown Basic Item)' : sel.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (def != null && def.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(def.tagLabel,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.secondary)),
                ),
              if (def != null && def.isSpecial)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text('Special',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.tertiary)),
                ),
              // Quantity stepper.
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 18),
                onPressed: sel.quantity > 1
                    ? () => onUpdate(() => sel.quantity -= 1)
                    : null,
              ),
              Text('×${sel.quantity}', style: theme.textTheme.labelLarge),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => onUpdate(() => sel.quantity += 1),
              ),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onUpdate(() => _c.basicItems.remove(sel)),
              ),
            ],
          ),
          if (def != null) ...[
            if (def.craftDc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('Craft DC: ${def.craftDc}',
                    style: theme.textTheme.labelSmall),
              ),
            Text(def.effects, style: theme.textTheme.bodySmall),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextFormField(
              initialValue: sel.notes,
              decoration: const InputDecoration(
                labelText: 'Notes (trigger / charges / assigned target / …)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onUpdate(() => sel.notes = v),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the Basic Items catalogue picker (grouped Standard / Special,
  /// searchable) and adds the chosen item (duplicates allowed — you might carry
  /// several distinct Bombs, etc.; Quantity covers stacks of the same item).
  Future<void> _pickBasicItem(BuildContext context) async {
    final chosen = await showDialog<BasicItemDef>(
      context: context,
      builder: (ctx) => const _BasicItemPickerDialog(),
    );
    if (chosen == null) return;
    onUpdate(() => _c.basicItems.add(BasicItemSelection(name: chosen.name)));
  }

  // ==========================================================================
  // FREEFORM SECTIONS  (Gear)
  // ==========================================================================
  Widget _buildFreeformSection(
      BuildContext context, InventoryCategory category) {
    final items = _c.inventory
        .where((i) => i.category == category)
        .toList(growable: false);
    return SectionCard(
      title: category.displayName,
      icon: _iconFor(category),
      trailing: IconButton(
        tooltip: 'Add ${category.singular}',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => onUpdate(
          () => _c.inventory.add(InventoryItem(category: category)),
        ),
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No ${category.displayName} yet.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          for (final item in items) _buildItemRow(context, item),
        ],
      ),
    );
  }

  IconData _iconFor(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.apparel:
        return Icons.checkroom_outlined;
      case InventoryCategory.weapon:
        return Icons.sports_martial_arts;
      case InventoryCategory.accessory:
        return Icons.diamond_outlined;
      case InventoryCategory.gear:
        return Icons.inventory_2_outlined;
    }
  }

  String _detailHint(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.accessory:
        return 'Kind';
      case InventoryCategory.apparel:
      case InventoryCategory.weapon:
      case InventoryCategory.gear:
        return '';
    }
  }

  Widget _buildItemRow(BuildContext context, InventoryItem item) {
    final theme = Theme.of(context);
    final isGear = item.category == InventoryCategory.gear;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() => item.name = v),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onUpdate(() => _c.inventory.remove(item)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isGear)
                SizedBox(
                  width: 130,
                  child: TextFormField(
                    initialValue: '${item.quantity}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => onUpdate(
                        () => item.quantity = int.tryParse(v.trim()) ?? 1),
                  ),
                )
              else ...[
                Expanded(
                  child: TextFormField(
                    key: ValueKey('detail-${item.category}'),
                    initialValue: item.detail,
                    decoration: InputDecoration(
                      labelText: 'Details',
                      hintText: _detailHint(item.category),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => onUpdate(() => item.detail = v),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: Text(item.category.equippedLabel),
                  selected: item.equipped,
                  onSelected: (v) => onUpdate(() => item.equipped = v),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ResizableTextField(
            key: ValueKey('inv-notes-${identityHashCode(item)}'),
            label: 'Notes / Effect',
            value: item.notes,
            initialLines: 2,
            onChanged: (v) => onUpdate(() => item.notes = v),
          ),
          const Divider(height: 8, color: Colors.transparent),
          Divider(height: 1, color: theme.dividerColor),
        ],
      ),
    );
  }
}

/// A search-and-pick dialog over the Apparel Qualities available to one
/// Apparel Category, grouped Standard / Special (Special ones are ARC-granted
/// and very powerful — the site warns against more than one per piece).
class _ApparelQualityPickerDialog extends StatefulWidget {
  const _ApparelQualityPickerDialog({
    required this.category,
    required this.qualities,
  });

  final ApparelCategory category;
  final List<ApparelQualityDef> qualities;

  @override
  State<_ApparelQualityPickerDialog> createState() =>
      _ApparelQualityPickerDialogState();
}

class _ApparelQualityPickerDialogState
    extends State<_ApparelQualityPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = widget.qualities
        .where((q) =>
            query.isEmpty ||
            q.name.toLowerCase().contains(query) ||
            q.effects.toLowerCase().contains(query))
        .toList();
    final standard = matches.where((q) => !q.isSpecial).toList();
    final special = matches.where((q) => q.isSpecial).toList();

    Widget group(String title, List<ApparelQualityDef> defs) {
      if (defs.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final q in defs)
            ListTile(
              dense: true,
              title: Row(
                children: [
                  Flexible(child: Text(q.name)),
                  const SizedBox(width: 6),
                  Text('(${q.slotLabel} slot${q.maxSlots == 1 ? '' : 's'})',
                      style: theme.textTheme.labelSmall),
                  if (q.isAutomated)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.bolt,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              subtitle: Text(q.effects,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(q),
            ),
        ],
      );
    }

    return AlertDialog(
      title: Text('${widget.category.displayName} Qualities'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Qualities',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No available Qualities.'))
                  : ListView(
                      children: [
                        group('Standard', standard),
                        group('Special', special),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// A search-and-pick dialog over the Weapon Qualities available to one Weapon
/// Type, grouped Standard / Special (Special ones are ARC-granted and very
/// powerful — the site warns against more than one per Weapon).
class _WeaponQualityPickerDialog extends StatefulWidget {
  const _WeaponQualityPickerDialog({
    required this.type,
    required this.qualities,
  });

  final WeaponType type;
  final List<WeaponQualityDef> qualities;

  @override
  State<_WeaponQualityPickerDialog> createState() =>
      _WeaponQualityPickerDialogState();
}

class _WeaponQualityPickerDialogState
    extends State<_WeaponQualityPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = widget.qualities
        .where((q) =>
            query.isEmpty ||
            q.name.toLowerCase().contains(query) ||
            q.effects.toLowerCase().contains(query))
        .toList();
    final standard = matches.where((q) => !q.isSpecial).toList();
    final special = matches.where((q) => q.isSpecial).toList();

    Widget group(String title, List<WeaponQualityDef> defs) {
      if (defs.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final q in defs)
            ListTile(
              dense: true,
              title: Row(
                children: [
                  Flexible(child: Text(q.name)),
                  const SizedBox(width: 6),
                  Text('(${q.slotLabel} slot${q.maxSlots == 1 ? '' : 's'})',
                      style: theme.textTheme.labelSmall),
                  if (q.isAutomated)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.bolt,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              subtitle: Text(q.effects,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(q),
            ),
        ],
      );
    }

    return AlertDialog(
      title: Text('${widget.type.displayName} Weapon Qualities'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Qualities',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No available Qualities.'))
                  : ListView(
                      children: [
                        group('Standard', standard),
                        group('Special', special),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// A search-and-pick dialog over the Accessories catalogue, grouped Standard /
/// Special (Special ones are ARC-granted Special Basic Items).
class _AccessoryPickerDialog extends StatefulWidget {
  const _AccessoryPickerDialog({required this.accessories});

  final List<AccessoryDef> accessories;

  @override
  State<_AccessoryPickerDialog> createState() => _AccessoryPickerDialogState();
}

class _AccessoryPickerDialogState extends State<_AccessoryPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = widget.accessories
        .where((a) =>
            query.isEmpty ||
            a.name.toLowerCase().contains(query) ||
            a.effects.toLowerCase().contains(query))
        .toList();
    final standard = matches.where((a) => !a.isSpecial).toList();
    final special = matches.where((a) => a.isSpecial).toList();

    Widget group(String title, List<AccessoryDef> defs) {
      if (defs.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final a in defs)
            ListTile(
              dense: true,
              title: Row(
                children: [
                  Flexible(child: Text(a.name)),
                  if (a.isTech)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text('[Tech]',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.secondary)),
                    ),
                  if (a.craftDc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child:
                          Text(a.craftDc, style: theme.textTheme.labelSmall),
                    ),
                  if (a.isAutomated)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.bolt,
                          size: 16, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              subtitle: Text(a.effects,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(a),
            ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Accessories'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Accessories',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No available Accessories.'))
                  : ListView(
                      children: [
                        group('Standard', standard),
                        group('Special', special),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// A search-and-pick dialog over the Basic Items catalogue, grouped Basic /
/// Special. The whole catalogue is always offered (duplicates allowed — Quantity
/// covers stacks of the same item).
class _BasicItemPickerDialog extends StatefulWidget {
  const _BasicItemPickerDialog();

  @override
  State<_BasicItemPickerDialog> createState() => _BasicItemPickerDialogState();
}

class _BasicItemPickerDialogState extends State<_BasicItemPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = [...kDbuBasicItems, ...HomebrewRegistry.basicItemDefs()]
        .where((b) =>
            query.isEmpty ||
            b.name.toLowerCase().contains(query) ||
            b.effects.toLowerCase().contains(query))
        .toList();
    final standard = matches.where((b) => !b.isSpecial).toList();
    final special = matches.where((b) => b.isSpecial).toList();

    Widget group(String title, List<BasicItemDef> defs) {
      if (defs.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final b in defs)
            ListTile(
              dense: true,
              title: Row(
                children: [
                  Flexible(child: Text(b.name)),
                  if (b.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(b.tagLabel,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.secondary)),
                    ),
                  if (b.craftDc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child:
                          Text(b.craftDc, style: theme.textTheme.labelSmall),
                    ),
                ],
              ),
              subtitle: Text(b.effects,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.of(context).pop(b),
            ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Basic Items'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Basic Items',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No matching Basic Items.'))
                  : ListView(
                      children: [
                        group('Basic Items', standard),
                        group('Special Basic Items', special),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
