/// signatures_screen.dart
/// ---------------------------------------------------------------------------
/// The SIGNATURES TAB — the site's Signature Techniques sub-system, mirroring
/// the old sheet's dedicated tab.
///
/// A Signature Technique is a player-built attack: a Level (Super / Ultimate /
/// Dramatic Finisher), a Foundation + Profile, and any number of Advantages
/// (+TP) and Disadvantages (−TP). The calculator derives the Technique Point
/// (TP) Cost and Ki Point (KP) Cost, the per-Tier spend cap, and the automated
/// per-Technique Strike/Wound modifiers — all from the `data/signature_*.dart`
/// catalogues. Only unconditional numeric modifier effects are automated;
/// everything else is verbatim reference text (labelled "not automated").
///
/// The shared [TpBudgetCard] (also on the Unique Abilities tab) shows the
/// character's Technique Point pool. A Technique's "Free TP" field and any
/// Advantage flagged "Free" discount what it spends from that pool (via
/// `signatureTpSpent`) without changing its TP Cost (which still drives KP and
/// the spend cap).
///
/// Follows the shared tab contract `({character, stats, onUpdate})`.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dbu_rules.dart' show AffectedStat;
import '../data/homebrew_registry.dart';
import '../data/signature_modifiers.dart';
import '../data/signature_profiles.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import 'widgets/sheet_widgets.dart';
import 'widgets/tp_budget.dart';

class SignaturesTab extends StatelessWidget {
  const SignaturesTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  final Character character;
  final DerivedCharacterStats stats;
  final void Function(VoidCallback mutate) onUpdate;

  Character get _c => character;

  String _fmt(int n) => n >= 0 ? '+$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final warnings = CharacterCalculator.signatureUltimateWarnings(_c);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Budget first — it's the number the player checks constantly.
            TpBudgetCard(character: _c, onUpdate: onUpdate),
            _buildIntro(context, warnings),
            for (final tech in _c.signatureTechniques)
              _buildTechniqueCard(context, tech),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context, List<String> warnings) {
    final theme = Theme.of(context);
    final supers = CharacterCalculator.signatureSuperCount(_c);
    final ultimates = CharacterCalculator.signatureUltimateCount(_c);
    return SectionCard(
      title: 'Signature Techniques',
      icon: Icons.auto_awesome,
      trailing: IconButton(
        tooltip: 'Add Signature Technique',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () =>
            onUpdate(() => _c.signatureTechniques.add(SignatureTechnique())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Build a Signature Technique: pick a Level, a Foundation + Profile, then '
            'Advantages (+TP) and Disadvantages (−TP). ',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(label: 'Super', value: '$supers'),
              DerivedStat(label: 'Ultimate', value: '$ultimates'),
              DerivedStat(
                label: 'TP Spend Cap',
                value: '${CharacterCalculator.signatureTpSpendCap(_c)}',
                tooltip: 'Max Technique Points per Technique at this Tier of '
                    'Power',
              ),
            ],
          ),
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(w,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ),
          if (_c.signatureTechniques.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No Signature Techniques yet.',
                  style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _buildTechniqueCard(BuildContext context, SignatureTechnique tech) {
    final theme = Theme.of(context);
    final profile = CharacterCalculator.signatureProfileFor(tech);
    final tp = CharacterCalculator.signatureTpCost(tech);
    final spent = CharacterCalculator.signatureTpSpent(tech);
    final kp = CharacterCalculator.signatureKpCost(_c, tech);
    final cap = CharacterCalculator.signatureTpSpendCap(_c);
    final overCap = tp > cap;
    final mods = CharacterCalculator.signatureModifiers(_c, tech);
    final strikeMod = mods[AffectedStat.strike] ?? 0;
    final woundStat = switch (tech.foundation) {
      SigFoundation.magic => AffectedStat.woundMagic,
      SigFoundation.energy => AffectedStat.woundEnergy,
      _ => AffectedStat.woundPhysical,
    };
    final woundMod = mods[woundStat] ?? 0;

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
          // Name + delete.
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: tech.name,
                  decoration: const InputDecoration(
                    labelText: 'Technique Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => onUpdate(() => tech.name = v),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    onUpdate(() => _c.signatureTechniques.remove(tech)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Level + Foundation.
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SignatureLevel>(
                  initialValue: tech.level,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final l in SignatureLevel.values)
                      DropdownMenuItem(value: l, child: Text(l.displayName)),
                  ],
                  onChanged: (v) => onUpdate(() {
                    if (v == null) return;
                    tech.level = v;
                    // Super Profile only applies to a Dramatic Finisher.
                    if (v != SignatureLevel.dramaticFinisher) {
                      tech.superProfileName = '';
                    }
                    // Drop Ultimate-only Advantages if no longer Ultimate.
                    if (!v.isUltimate) {
                      tech.advantages.removeWhere((a) =>
                          HomebrewRegistry.resolveSignatureModifier(a.name)
                                  ?.ultimateOnly ??
                              false);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<SigFoundation>(
                  initialValue: tech.foundation,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Foundation',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final f in SigFoundation.concrete)
                      DropdownMenuItem(value: f, child: Text(f.displayName)),
                  ],
                  // Changing Foundation may invalidate the chosen Profile.
                  onChanged: (v) => onUpdate(() {
                    if (v == null) return;
                    tech.foundation = v;
                    final p = signatureProfileByName(tech.profileName);
                    if (p != null &&
                        p.foundation != SigFoundation.multi &&
                        p.foundation != v) {
                      tech.profileName = '';
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Profile.
          _buildProfileSelector(context, tech),
          if (tech.level == SignatureLevel.dramaticFinisher) ...[
            const SizedBox(height: 10),
            _buildSuperProfileSelector(context, tech),
          ],
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Profile effect: ${profile.effect}',
                  style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          // Derived chips.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'TP Cost',
                value: '$tp',
                emphasize: true,
                warn: overCap,
                tooltip: overCap ? 'Over the $cap TP spend cap' : null,
              ),
              if (spent != tp)
                DerivedStat(
                  label: 'TP Spent',
                  value: '$spent',
                  tooltip: 'Cost against your TP budget after free TP',
                ),
              DerivedStat(
                label: 'KP Cost',
                value: profile == null ? '—' : '$kp',
                emphasize: true,
              ),
              if (strikeMod != 0)
                DerivedStat(label: 'Strike', value: _fmt(strikeMod)),
              if (woundMod != 0)
                DerivedStat(
                    label: 'Wound (${tech.foundation.displayName})',
                    value: _fmt(woundMod)),
              if (tech.level.isUltimate)
                DerivedStat(
                  label: 'Used this Encounter',
                  value: tech.usedThisEncounter ? 'Yes' : 'No',
                ),
            ],
          ),
          if (tech.level.isUltimate)
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Used this Combat Encounter'),
                selected: tech.usedThisEncounter,
                onSelected: (v) => onUpdate(() => tech.usedThisEncounter = v),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: TextFormField(
                  key: ValueKey('sig-freetp-${identityHashCode(tech)}'),
                  initialValue: tech.freeTp == 0 ? '' : '${tech.freeTp}',
                  decoration: const InputDecoration(
                    labelText: 'Free TP',
                    border: OutlineInputBorder(),
                    isDense: true,
                    helperText: 'discount',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d*')),
                  ],
                  onChanged: (v) =>
                      onUpdate(() => tech.freeTp = int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A Trait/effect that grants free TP for this Technique '
                  '(discounts what it costs your budget).',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildModifierList(context, tech, isDisadvantage: false),
          const SizedBox(height: 8),
          _buildModifierList(context, tech, isDisadvantage: true),
          const SizedBox(height: 4),
          ResizableTextField(
            key: ValueKey('sig-notes-${identityHashCode(tech)}'),
            label: 'Notes',
            value: tech.notes,
            initialLines: 2,
            onChanged: (v) => onUpdate(() => tech.notes = v),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSelector(BuildContext context, SignatureTechnique tech) {
    final available = profilesForFoundation(tech.foundation);
    final valid = available.any((p) => p.name == tech.profileName);
    return DropdownButtonFormField<String>(
      initialValue: valid ? tech.profileName : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Profile',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      hint: const Text('Choose a Profile'),
      items: [
        for (final p in available)
          DropdownMenuItem(
            value: p.name,
            child: Text('${p.name}  ·  ${p.kpLabel} KP'),
          ),
      ],
      onChanged: (v) => onUpdate(() => tech.profileName = v ?? ''),
    );
  }

  Widget _buildSuperProfileSelector(
      BuildContext context, SignatureTechnique tech) {
    final valid =
        kDbuSuperProfiles.any((p) => p.name == tech.superProfileName);
    return DropdownButtonFormField<String>(
      initialValue: valid ? tech.superProfileName : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Super Profile (Dramatic Finisher)',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      hint: const Text('Choose a Super Profile'),
      items: [
        for (final p in kDbuSuperProfiles)
          DropdownMenuItem(value: p.name, child: Text(p.name)),
      ],
      onChanged: (v) => onUpdate(() => tech.superProfileName = v ?? ''),
    );
  }

  Widget _buildModifierList(BuildContext context, SignatureTechnique tech,
      {required bool isDisadvantage}) {
    final theme = Theme.of(context);
    final list = isDisadvantage ? tech.disadvantages : tech.advantages;
    final title = isDisadvantage ? 'Disadvantages' : 'Advantages';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add ${isDisadvantage ? 'Disadvantage' : 'Advantage'}'),
              onPressed: () =>
                  _pickModifier(context, tech, isDisadvantage: isDisadvantage),
            ),
          ],
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('None.', style: theme.textTheme.bodySmall),
          ),
        for (final sel in list)
          _buildModifierRow(context, tech, sel, isDisadvantage: isDisadvantage),
      ],
    );
  }

  Widget _buildModifierRow(
      BuildContext context, SignatureTechnique tech, SigModifierSelection sel,
      {required bool isDisadvantage}) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.resolveSignatureModifier(sel.name);
    final list = isDisadvantage ? tech.disadvantages : tech.advantages;
    final tp = def?.tpCostForRank(sel.rank) ?? 0;
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
                  sel.name.isEmpty ? '(unknown)' : sel.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              // TP contribution of this modifier at its current rank.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('${tp >= 0 ? '+' : ''}$tp TP',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: isDisadvantage
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary)),
              ),
              Icon(
                def?.isAutomated == true ? Icons.bolt : Icons.notes,
                size: 16,
                color: def?.isAutomated == true
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              // Rank stepper for ranked modifiers.
              if (def != null && def.isRanked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: sel.rank > 1
                          ? () => onUpdate(() => sel.rank -= 1)
                          : null,
                    ),
                    Text('R${sel.rank}', style: theme.textTheme.labelMedium),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: sel.rank < def.maxRank
                          ? () => onUpdate(() => sel.rank += 1)
                          : null,
                    ),
                  ],
                ),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onUpdate(() => list.remove(sel)),
              ),
            ],
          ),
          if (def != null) ...[
            Text(def.effect, style: theme.textTheme.bodySmall),
            if (!isDisadvantage)
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  visualDensity: VisualDensity.compact,
                  label: const Text('Free (no TP)'),
                  selected: sel.free,
                  onSelected: (v) => onUpdate(() => sel.free = v),
                  tooltip: 'A Trait/effect grants this Advantage without paying '
                      'its TP',
                ),
              ),
            if (def.requirement != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Requirement: ${def.requirement}',
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
        ],
      ),
    );
  }

  Future<void> _pickModifier(BuildContext context, SignatureTechnique tech,
      {required bool isDisadvantage}) async {
    final list = isDisadvantage ? tech.disadvantages : tech.advantages;
    final taken = list.map((m) => m.name).toSet();
    final chosen = await showDialog<SigModifierDef>(
      context: context,
      builder: (ctx) => _SigModifierPickerDialog(
        isDisadvantage: isDisadvantage,
        isUltimate: tech.level.isUltimate,
        taken: taken,
      ),
    );
    if (chosen == null) return;
    onUpdate(() => list.add(SigModifierSelection(name: chosen.name)));
  }
}

/// A search-and-pick dialog over the Advantages (or Disadvantages) catalogue,
/// grouped by category. Ultimate-only Advantages are shown but disabled unless
/// the Technique is an Ultimate.
class _SigModifierPickerDialog extends StatefulWidget {
  const _SigModifierPickerDialog({
    required this.isDisadvantage,
    required this.isUltimate,
    required this.taken,
  });

  final bool isDisadvantage;
  final bool isUltimate;
  final Set<String> taken;

  @override
  State<_SigModifierPickerDialog> createState() =>
      _SigModifierPickerDialogState();
}

class _SigModifierPickerDialogState extends State<_SigModifierPickerDialog> {
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
    final source = [
      ...widget.isDisadvantage
          ? kDbuSignatureDisadvantages
          : kDbuSignatureAdvantages,
      ...HomebrewRegistry.sigModifierDefs(
          disadvantages: widget.isDisadvantage),
    ];
    final matches = source
        .where((m) =>
            !widget.taken.contains(m.name) &&
            (query.isEmpty ||
                m.name.toLowerCase().contains(query) ||
                m.effect.toLowerCase().contains(query)))
        .toList();
    // Preserve catalogue order, grouped by category.
    final categories = <SigModifierCategory>[];
    for (final m in matches) {
      if (!categories.contains(m.category)) categories.add(m.category);
    }

    return AlertDialog(
      title: Text(widget.isDisadvantage ? 'Disadvantages' : 'Advantages'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search',
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
                  ? const Center(child: Text('No matches.'))
                  : ListView(
                      children: [
                        for (final cat in categories) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(cat.displayName,
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          for (final m
                              in matches.where((m) => m.category == cat))
                            _tile(context, m),
                        ],
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

  Widget _tile(BuildContext context, SigModifierDef m) {
    final theme = Theme.of(context);
    final locked = m.ultimateOnly && !widget.isUltimate;
    return ListTile(
      dense: true,
      enabled: !locked,
      title: Row(
        children: [
          Flexible(child: Text(m.name)),
          const SizedBox(width: 6),
          Text('${m.tpLabel} TP', style: theme.textTheme.labelSmall),
          if (m.isAutomated)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.bolt,
                  size: 16, color: theme.colorScheme.primary),
            ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('Ultimate only',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.error)),
            ),
        ],
      ),
      subtitle: Text(m.effect, maxLines: 3, overflow: TextOverflow.ellipsis),
      onTap: locked ? null : () => Navigator.of(context).pop(m),
    );
  }
}
