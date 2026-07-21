/// references_screen.dart
/// ---------------------------------------------------------------------------
/// The REFERENCES TAB — the community sheet's "References" page: an interactive
/// ATTACK-ROLL calculator. Pick a Profile or one of your Signature Techniques
/// and the sheet assembles the exact rolls (Strike / Wound / Dodge / Duel). Each
/// roll is shown as a full, **copyable** dice string of everything currently
/// rolled — base `1d10` + every Tier-of-Power Extra Dice (one extra set per
/// Energy Charge on the Wound) + Greater Dice when the "Greater Dice active"
/// toggle is on + the flat bonus (Crit Target) — plus a copyable "On a Critical"
/// variant that appends the Critical Dice. Also derives the Ki Cost, Max Ki
/// Wager and Damage Category, and folds in an equipped Weapon (only if its
/// Foundation matches the attack).
///
/// This is a pure scratchpad calculator — NOTHING persists (its inputs are
/// ephemeral widget state, exactly like the Character tab's Damage Calculator),
/// so this tab is a `StatefulWidget` and takes no `onUpdate`.
///
/// The math lives in `CharacterCalculator.attackReference` (unit-tested); this
/// file is just the layout + inputs.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/homebrew_registry.dart';
import '../data/signature_modifiers.dart';
import '../data/signature_profiles.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import 'widgets/sheet_widgets.dart';

class ReferencesTab extends StatefulWidget {
  const ReferencesTab({
    super.key,
    required this.character,
    required this.stats,
    this.leadingCard,
    this.onAttackMade,
  });

  final Character character;
  final DerivedCharacterStats stats;

  /// Optional card rendered above the calculator (the Combat page's Attacking
  /// Maneuver tab passes its "triggers on an attack" reminders here).
  final Widget? leadingCard;

  /// Combat mode: when non-null, the calculator shows Ki/Capacity/Wager
  /// warnings and an "Attack made" button that reports the total Ki spent
  /// (Ki Cost + Ki Wager) so the caller can deduct it and count the attack.
  /// Null on the edit screen (a pure scratchpad — no button, no warnings).
  final void Function(int kiSpent)? onAttackMade;

  @override
  State<ReferencesTab> createState() => _ReferencesTabState();
}

class _ReferencesTabState extends State<ReferencesTab> {
  // Ephemeral Attack Reference inputs (nothing persists).
  String _attackName = 'Simple';
  SigFoundation _foundation = SigFoundation.physical;
  String _weaponName = ''; // '' = Unarmed
  String _offHandName = ''; // '' = Unarmed (tracked; one Weapon applies/attack)
  String _extraProfile = ''; // '' = none
  int _energyCharges = 0;
  int _wager = 0;
  int _targetRange = 0;
  int _targetSizeRelative = 0; // target's Size vs yours (− smaller / + larger)
  bool _inMelee = false;
  bool _greaterDiceActive = false;
  int _miscStrike = 0;
  int _miscWound = 0;
  int _miscDodge = 0;

  // Advantage/Disadvantage applied to the referenced attack.
  String _advName = '';
  int _advRank = 1;

  Character get _c => widget.character;
  DerivedCharacterStats get _stats => widget.stats;

  /// The chosen attack is a Multi-Foundation Profile (Foundation is selectable).
  bool get _isMultiFoundation {
    if (_c.signatureTechniques.any((t) => t.name == _attackName)) return false;
    final p = signatureProfileByName(_attackName);
    return p != null && p.foundation == SigFoundation.multi;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (widget.leadingCard != null) widget.leadingCard!,
            _buildAttackReference(context),
            _buildAdvantageReference(context),
            _buildStateAndResources(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Attack Reference
  // ==========================================================================
  Widget _buildAttackReference(BuildContext context) {
    final theme = Theme.of(context);
    final ref = CharacterCalculator.attackReference(
      _c,
      _stats,
      attackName: _attackName,
      multiFoundationChoice: _foundation,
      weaponName: _weaponName,
      extraProfileName: _extraProfile,
      advantageName: _advName,
      advantageRank: _advRank,
      energyCharges: _energyCharges,
      wager: _wager,
      targetRange: _targetRange,
      targetSizeRelative: _targetSizeRelative,
      greaterDiceActive: _greaterDiceActive,
      miscStrike: _miscStrike,
      miscWound: _miscWound,
      miscDodge: _miscDodge,
    );

    // Attack options: the 27 Profiles, then the character's Signature Techniques.
    final attackItems = <DropdownMenuItem<String>>[
      for (final p in kDbuSignatureProfiles)
        DropdownMenuItem(value: p.name, child: Text(p.name)),
      for (final t in _c.signatureTechniques)
        if (t.name.trim().isNotEmpty)
          DropdownMenuItem(
              value: t.name, child: Text('${t.name} (Signature)')),
    ];
    final validAttack = attackItems.any((i) => i.value == _attackName);

    return SectionCard(
      title: 'Attack Reference',
      icon: Icons.sports_kabaddi_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Attack + Foundation.
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: validAttack ? _attackName : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Attack Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: attackItems,
                  onChanged: (v) =>
                      setState(() => _attackName = v ?? _attackName),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<SigFoundation>(
                  initialValue: _foundation,
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
                  // Only meaningful for a Multi-Foundation Profile; a
                  // single-Foundation Profile/Signature drives its own.
                  onChanged: _isMultiFoundation
                      ? (v) => setState(() => _foundation = v ?? _foundation)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weapon Equipped + Off-Hand.
          Row(
            children: [
              Expanded(child: _weaponDropdown('Weapon Equipped', _weaponName,
                  (v) => setState(() => _weaponName = v))),
              const SizedBox(width: 8),
              Expanded(child: _weaponDropdown('Off-Hand', _offHandName,
                  (v) => setState(() => _offHandName = v))),
            ],
          ),
          const SizedBox(height: 10),
          // Extra Profile + Energy Charges + Wager.
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue:
                      signatureProfileByName(_extraProfile) == null ? '' : _extraProfile,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Extra Profile',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('None')),
                    for (final p in kDbuSignatureProfiles)
                      DropdownMenuItem(value: p.name, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _extraProfile = v ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Energy Charges',
                  value: _energyCharges,
                  onChanged: (v) => setState(() => _energyCharges = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  label: 'Wagers',
                  value: _wager,
                  onChanged: (v) => setState(() => _wager = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Top-line derived values.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(label: 'Ki Cost', value: '${ref.kiCost}', emphasize: true),
              DerivedStat(
                label: 'Damage Cat.',
                value: ref.damageCategory?.displayName ?? '—',
              ),
              DerivedStat(
                label: 'Max Wager',
                value: '${ref.maxWager}',
                tooltip: '½ of Max Capacity (a Wager adds 1:1 to the Wound Roll)',
              ),
              DerivedStat(
                label: 'Total Energy Charges',
                value: '${ref.energyCharges}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dice-affecting toggles: Greater Dice are only rolled while an
          // effect grants them, so they're opt-in here.
          Row(
            children: [
              FilterChip(
                label: Text('Greater Dice active (${ref.greaterDice})'),
                selected: _greaterDiceActive,
                onSelected: (v) => setState(() => _greaterDiceActive = v),
                tooltip: 'Some States/effects add your Greater Dice to Combat '
                    'Rolls — toggle on to fold them into the rolls below',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // The three attack rolls, each a full copyable dice string.
          _rollBlock(context, 'Attack\'s Strike (CT)', ref.strike, ref,
              misc: _miscStrike, onMisc: (v) => setState(() => _miscStrike = v)),
          _rollBlock(
              context, 'Attack\'s Wound (${ref.foundation.displayName})', ref.wound, ref,
              misc: _miscWound,
              onMisc: (v) => setState(() => _miscWound = v),
              chargeNote: true),
          _rollBlock(context, 'Dodge Roll (CT)', ref.dodge, ref,
              misc: _miscDodge, onMisc: (v) => setState(() => _miscDodge = v)),
          // Duel Clash (VERIFY).
          _rollBlock(context, 'Duel Clash', ref.duel, ref,
              showMisc: false,
              helpMessage:
                  'Higher of Force/Magic Modifier, +2(T)/Energy Charge, '
                  '+1(T) per Super Stack & Raging/Mindful State'),
          const SizedBox(height: 10),
          // Target's Size relative to yours → Punching Up / Punching Down.
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: 'Target Size (± categories)',
                  value: _targetSizeRelative,
                  min: -6,
                  onChanged: (v) => setState(() => _targetSizeRelative = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _targetSizeRelative <= -2
                      ? 'Punching Down: +1d6(T) damage (Wound)'
                      : _targetSizeRelative >= 2
                          ? 'Punching Up: +1(T)/category to Wound, no Called '
                              'Shot penalty'
                          : 'Target\'s Size vs yours (− smaller / + larger)',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: _targetSizeRelative.abs() >= 2
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Target range / melee (informational for now).
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: "Target's Range (sq.)",
                  value: _targetRange,
                  onChanged: (v) => setState(() => _targetRange = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text("In Target's Melee"),
                      selected: _inMelee,
                      onSelected: (v) => setState(() => _inMelee = v),
                    ),
                    const SizedBox(width: 8),
                    if (_targetRange >= 9)
                      Text('Long Range: Strike −2(bT) applied',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.tertiary)),
                  ],
                ),
              ),
            ],
          ),
          if (_offHandName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Off-Hand ($_offHandName) is tracked only — one Weapon applies '
                'per Attacking Maneuver, so it does not buff this attack. Select '
                'it as "Weapon Equipped" to reference an attack made with it.',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          if (ref.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Description', style: theme.textTheme.titleSmall),
            Text(ref.description, style: theme.textTheme.bodySmall),
          ],
          if (_weaponName.isNotEmpty && !_weaponBuffs(ref.foundation))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'This Weapon does not buff a ${ref.foundation.displayName} '
                'attack (Weapons only apply to their own Foundation).',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          // Combat mode: cost warnings + the deducting "Attack made" button.
          if (widget.onAttackMade != null) _attackMadeControls(context, ref),
        ],
      ),
    );
  }

  /// Combat-only footer for the Attack Reference: warns when the Ki this
  /// attack spends (Ki Cost + Ki Wager) exceeds the current Ki pool or
  /// current Capacity, or the Wager exceeds its maximum, then the "Attack
  /// made" button that spends that Ki + Capacity and counts the attack.
  Widget _attackMadeControls(BuildContext context, AttackReference ref) {
    final theme = Theme.of(context);
    final kiSpent = ref.kiCost + _wager;
    final overKi = kiSpent > _stats.currentKi;
    final overCapacity = kiSpent > _stats.currentCapacity;
    final overWager = _wager > ref.maxWager;

    final warnings = <String>[
      if (overKi)
        'Ki spent ($kiSpent) exceeds your current Ki '
            '(${_stats.currentKi} / ${_stats.maxKi}).',
      if (overCapacity)
        'Ki spent ($kiSpent) exceeds your current Capacity '
            '(${_stats.currentCapacity} / ${_stats.maxCapacity}).',
      if (overWager)
        'Ki Wager ($_wager) exceeds your Max Ki Wager (${ref.maxWager} = '
            '½ Max Capacity).',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Text('Cost of this attack', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Ki Cost ${ref.kiCost}${_wager > 0 ? ' + Wager $_wager' : ''} = '
          '$kiSpent Ki & Capacity spent.',
          style: theme.textTheme.bodySmall,
        ),
        if (warnings.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final w in warnings)
                        Text(w,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: Text(kiSpent > 0
              ? 'Attack made (spend $kiSpent Ki & Capacity)'
              : 'Attack made'),
          onPressed: () => widget.onAttackMade!(kiSpent),
        ),
      ],
    );
  }

  /// A Weapon-selector dropdown (Unarmed + the character's Weapons).
  Widget _weaponDropdown(
      String label, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: _c.weapons.any((w) => w.name == value) ? value : '',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Unarmed')),
        for (final w in _c.weapons)
          if (w.name.trim().isNotEmpty)
            DropdownMenuItem(
              value: w.name,
              child: Text('${w.name} (${w.type.displayName})'),
            ),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }

  /// Whether the currently-selected Weapon buffs an attack of [f].
  bool _weaponBuffs(SigFoundation f) {
    final w = _c.weapons
        .cast<WeaponPiece?>()
        .firstWhere((x) => x?.name == _weaponName, orElse: () => null);
    return w != null &&
        CharacterCalculator.weaponMatchesFoundation(w.type, f);
  }

  /// One attack-roll block: the full copyable dice expression (everything
  /// currently rolled), a copyable "on a Critical Result" variant, and an
  /// optional Misc bonus field.
  Widget _rollBlock(
    BuildContext context,
    String label,
    AttackRollLine line,
    AttackReference ref, {
    int misc = 0,
    ValueChanged<int>? onMisc,
    bool showMisc = true,
    bool chargeNote = false,
    String? helpMessage,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: theme.textTheme.labelMedium),
                        if (helpMessage != null) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: helpMessage,
                            child: Icon(Icons.help_outline,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    Text(line.expression,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              _copyButton(context, line.expression),
              if (showMisc && onMisc != null)
                SizedBox(
                  width: 104,
                  child: _NumberField(
                    label: 'Misc',
                    value: misc,
                    min: -999,
                    onChanged: onMisc,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // On a Critical Result — the same roll plus the Critical Dice.
          Row(
            children: [
              Expanded(
                child: Text('On a Critical: ${line.criticalExpression}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
              _copyButton(context, line.criticalExpression, dense: true),
            ],
          ),
          if (chargeNote && ref.energyCharges > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                // "Each Energy Charge gained increases the Wound Roll of an
                // Attacking Maneuver by 1d6(T), or 1d8(T) if that Attacking
                // Maneuver is a Signature Technique." (already in the pool).
                '${ref.energyCharges} Energy Charge(s) add '
                '${ref.energyCharges * _stats.tierOfPower}d'
                '${ref.isSignature ? 8 : 6} to the Wound '
                '(1d${ref.isSignature ? 8 : 6}(T) each — included above).',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  /// A compact copy-to-clipboard button for a roll expression.
  Widget _copyButton(BuildContext context, String text, {bool dense = false}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: dense ? 16 : 20,
      tooltip: 'Copy',
      icon: const Icon(Icons.copy_outlined),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied: $text'), duration: const Duration(seconds: 1)),
        );
      },
    );
  }

  // ==========================================================================
  // Advantage / Disadvantage Reference (lookup only)
  // ==========================================================================
  Widget _buildAdvantageReference(BuildContext context) {
    final theme = Theme.of(context);
    final all = [
      ...kDbuSignatureAdvantages,
      ...kDbuSignatureDisadvantages,
      ...HomebrewRegistry.sigModifierDefs(disadvantages: false),
      ...HomebrewRegistry.sigModifierDefs(disadvantages: true),
    ];
    final def = _advName.isEmpty
        ? null
        : HomebrewRegistry.resolveSignatureModifier(_advName);
    return SectionCard(
      title: 'Advantage / Disadvantage Reference',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      all.any((m) => m.name == _advName) ? _advName : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Advantage / Disadvantage',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Apply an Advantage or Disadvantage'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('None')),
                    for (final m in all)
                      DropdownMenuItem(
                        value: m.name,
                        child: Text('${m.name}  (${m.tpLabel} TP)'),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _advName = v ?? '';
                    _advRank = 1;
                  }),
                ),
              ),
              // Rank stepper for ranked modifiers.
              if (def != null && def.isRanked) ...[
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: _advRank > 1
                      ? () => setState(() => _advRank -= 1)
                      : null,
                ),
                Text('R$_advRank', style: theme.textTheme.labelLarge),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: _advRank < def.maxRank
                      ? () => setState(() => _advRank += 1)
                      : null,
                ),
              ],
            ],
          ),
          if (def != null) ...[
            const SizedBox(height: 8),
            Text('${def.category.displayName} · ${def.tpLabel} TP'
                '${def.ultimateOnly ? ' · Ultimate only' : ''}',
                style: theme.textTheme.labelSmall),
            if (def.requirement != 'N/A')
              Text('Requirement: ${def.requirement}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Text(def.effect, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              def.isAutomated
                  ? 'Applied to the Attack Reference rolls above.'
                  : 'Not automated — situational effect, not folded into the rolls.',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: def.isAutomated
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // State Reference + Resources (read-outs)
  // ==========================================================================
  Widget _buildStateAndResources(BuildContext context) {
    final theme = Theme.of(context);
    final states = _c.states.where((s) => s.name.trim().isNotEmpty).toList();
    return SectionCard(
      title: 'States & Resources',
      icon: Icons.dashboard_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Life',
                value: '${_stats.currentLife} / ${_stats.maxLife}',
              ),
              DerivedStat(
                label: 'Ki',
                value: '${_stats.currentKi} / ${_stats.maxKi}',
              ),
              DerivedStat(
                label: 'Capacity',
                value: '${_stats.currentCapacity} / ${_stats.maxCapacity}',
              ),
              DerivedStat(label: 'Might', value: '${_stats.might}'),
            ],
          ),
          const SizedBox(height: 10),
          Text('States', style: theme.textTheme.titleSmall),
          if (states.isEmpty)
            Text('No States tracked.', style: theme.textTheme.bodySmall)
          else
            for (final s in states)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${s.name} — ${s.stacks}/${s.maxStacks}'
                  '${s.notes.trim().isEmpty ? '' : ' · ${s.notes}'}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
        ],
      ),
    );
  }
}

/// A compact labelled integer field with −/+ steppers (ephemeral; manages its
/// own controller so typing doesn't fight the parent's rebuilds).
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(_NumberField old) {
    super.didUpdateWidget(old);
    // Sync when the value changes programmatically (e.g. the steppers).
    if (widget.value != int.tryParse(_controller.text)) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(int v) {
    widget.onChanged(v.clamp(widget.min, 9999));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
        prefixIcon: IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove, size: 18),
          onPressed: () => _set(widget.value - 1),
        ),
        suffixIcon: IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add, size: 18),
          onPressed: () => _set(widget.value + 1),
        ),
      ),
      onChanged: (v) => _set(int.tryParse(v.trim()) ?? 0),
    );
  }
}
