/// progression_screen.dart
/// ---------------------------------------------------------------------------
/// The PROGRESSION TAB — a companion to the Character/Information tabs,
/// re-imagining the old spreadsheet's "Character Progression" tab (Main
/// Progression + Progression Preview + Bonus Perks; Downtime, Unification &
/// Fission, Path to Power/Godhood and Age Rules are deferred).
///
/// Unlike `InformationTab` (stateless), this tab owns one piece of transient
/// UI-only state — the "Preview through Level" number — so it's a
/// StatefulWidget, same spirit as `character_edit_screen.dart`'s own
/// transient quick-adjust controllers.
///
///   1. Main Progression   (PL 1-30 grant slots — Character Perks redeemed
///                          as Attribute/Talent/Skill, concrete grants
///                          filled in directly; drives computed Attribute
///                          Scores/Skill Ranks — see `Character.scoreOf`/
///                          `CharacterCalculator.totalSkillRanks`)
///   2. Progression Preview (computed snapshot at a chosen Level)
///   3. Bonus Perks         (freeform, gained outside the Power Level Table)
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/dbu_rules.dart';
import '../data/talents.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import 'widgets/sheet_widgets.dart';

class ProgressionTab extends StatefulWidget {
  const ProgressionTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  /// The SAME working copy the Character/Information tabs are editing.
  final Character character;

  /// Freshly recomputed derived stats, owned/refreshed by the parent.
  final DerivedCharacterStats stats;

  /// Applies a mutation to [character] and tells the parent to recompute.
  final void Function(VoidCallback mutate) onUpdate;

  @override
  State<ProgressionTab> createState() => _ProgressionTabState();
}

class _ProgressionTabState extends State<ProgressionTab> {
  /// Transient "preview through this Level" input — defaults to the
  /// character's current Power Level but can be raised to preview planned
  /// future picks, per the old sheet's own Progression Preview feature.
  late int _previewLevel = widget.character.powerLevel;

  Character get _c => widget.character;
  void _update(VoidCallback mutate) => widget.onUpdate(mutate);

  /// First Skill (or Skill + Specialty, for an Encompassing skill) whose key
  /// isn't already present in [existing] — so "Add Skill" always introduces a
  /// NEW, distinct skill instead of piling more Ranks onto one already listed.
  /// Null when every skill/specialty is already present.
  String? _firstUnusedSkillKey(Map<String, int> existing) {
    for (final s in kDbuSkills) {
      if (s.isEncompassing) {
        for (final spec in s.specialties) {
          final key = '${s.name}::$spec';
          if (!existing.containsKey(key)) return key;
        }
      } else {
        final key = '${s.name}::${SkillProgress.normalKey}';
        if (!existing.containsKey(key)) return key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildMainProgression(context),
            _buildProgressionPreview(context),
            _buildBonusPerks(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 1. MAIN PROGRESSION
  // ==========================================================================
  Widget _buildMainProgression(BuildContext context) {
    return SectionCard(
      title: 'Main Progression',
      icon: Icons.stairs_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'What your character got at each Power Level — plan ahead by '
              'filling in levels you haven\'t reached yet. A Character Perk '
              'can be redeemed as an Attribute Addition, Talent Addition, or '
              'Skill Improvement; concrete grants are filled in directly.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          for (final entry in kPowerLevelGrants) _levelGroup(context, entry),
        ],
      ),
    );
  }

  Widget _levelGroup(BuildContext context, PowerLevelGrants entry) {
    final theme = Theme.of(context);
    final reached = entry.powerLevel <= _c.powerLevel;
    final tint =
        reached ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: tint,
          collapsedBackgroundColor: tint,
          title: Text(
            'Power Level ${entry.powerLevel} '
            '(Tier of Power ${PowerLevelRules.tierOfPower(entry.powerLevel)})',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            entry.grants.map((g) => g.displayName).join(', '),
            style: theme.textTheme.labelSmall,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < entry.grants.length; i++)
                    _slotEditor(context, entry.powerLevel, i, entry.grants[i]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One grant slot within a Power Level — a `characterPerk` slot shows a
  /// "Redeem as…" dropdown driving which sub-editor appears below it; a
  /// concrete slot shows only that kind's sub-editor.
  Widget _slotEditor(
    BuildContext context,
    int powerLevel,
    int slotIndex,
    ProgressionGrantKind staticKind,
  ) {
    final key = '$powerLevel:$slotIndex';
    final choice = _c.progressionChoices[key];
    final effectiveKind = staticKind == ProgressionGrantKind.characterPerk
        ? choice?.resolvedKind
        : staticKind;

    ProgressionChoice ensureChoice(ProgressionGrantKind kind) =>
        _c.progressionChoices.putIfAbsent(
          key,
          () => ProgressionChoice(resolvedKind: kind),
        );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staticKind.displayName,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (staticKind == ProgressionGrantKind.characterPerk)
              _redeemAsDropdown(
                value: choice?.resolvedKind,
                onChanged: (kind) => _update(() {
                  _c.progressionChoices[key] = ProgressionChoice(
                    resolvedKind: kind,
                  );
                }),
              ),
            if (effectiveKind == ProgressionGrantKind.attributeAddition) ...[
              const SizedBox(height: 6),
              _attributePointsEditor(
                points: choice?.attributePoints ?? const {},
                onChanged: (attr, value) => _update(() {
                  final c = ensureChoice(ProgressionGrantKind.attributeAddition);
                  if (value == 0) {
                    c.attributePoints.remove(attr);
                  } else {
                    c.attributePoints[attr] = value;
                  }
                }),
              ),
            ] else if (effectiveKind == ProgressionGrantKind.talentAddition) ...[
              const SizedBox(height: 6),
              _talentEditor(
                fieldKey: 'main-$key',
                name: choice?.talentName ?? '',
                onChanged: (name) => _update(() {
                  ensureChoice(ProgressionGrantKind.talentAddition).talentName =
                      name;
                }),
              ),
            ] else if (effectiveKind ==
                ProgressionGrantKind.skillImprovement) ...[
              const SizedBox(height: 6),
              _skillRanksEditor(
                skillRanks: choice?.skillRanks ?? const {},
                // Only PL1's concrete Skill Improvement grants 6 Ranks (with 2
                // that may stack); every other Skill Improvement grants 4.
                rankBudget: (powerLevel == 1 &&
                        staticKind == ProgressionGrantKind.skillImprovement)
                    ? kSkillImprovementRanks + kSkillImprovementFirstBonusRanks
                    : kSkillImprovementRanks,
                allowStacking: powerLevel == 1 &&
                    staticKind == ProgressionGrantKind.skillImprovement,
                onSet: (skillKey, ranks) => _update(() {
                  final c = ensureChoice(ProgressionGrantKind.skillImprovement);
                  if (ranks <= 0) {
                    c.skillRanks.remove(skillKey);
                  } else {
                    c.skillRanks[skillKey] = ranks;
                  }
                }),
                onRename: (oldKey, newKey) => _update(() {
                  final c = ensureChoice(ProgressionGrantKind.skillImprovement);
                  // Don't let two rows collapse onto the same skill.
                  if (newKey != oldKey && c.skillRanks.containsKey(newKey)) {
                    return;
                  }
                  final ranks = c.skillRanks.remove(oldKey) ?? 1;
                  c.skillRanks[newKey] = ranks;
                }),
                onAdd: () => _update(() {
                  final c = ensureChoice(ProgressionGrantKind.skillImprovement);
                  final key = _firstUnusedSkillKey(c.skillRanks);
                  if (key != null) c.skillRanks[key] = 1;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 2. PROGRESSION PREVIEW
  // ==========================================================================
  Widget _buildProgressionPreview(BuildContext context) {
    final theme = Theme.of(context);
    final level = _previewLevel.clamp(
      PowerLevelRules.minPowerLevel,
      PowerLevelRules.maxPowerLevel,
    );
    final talents = CharacterCalculator.progressionTalentsThroughLevel(
      _c,
      level,
    );
    final tp = CharacterCalculator.progressionTpThroughLevel(_c, level);
    final attrPoints = CharacterCalculator.progressionAttributePointsThroughLevel(
      _c,
      level,
    );
    final skillRanks = CharacterCalculator.progressionSkillRanksThroughLevel(
      _c,
      level,
    );

    return SectionCard(
      title: 'Progression Preview',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A snapshot of everything gained through a given Level.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: _numberField(
              label: 'Preview through Level',
              value: _previewLevel,
              min: PowerLevelRules.minPowerLevel,
              max: PowerLevelRules.maxPowerLevel,
              onChanged: (v) => setState(() => _previewLevel = v),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DerivedStat(label: 'Total TP', value: '$tp'),
              for (final attr in DbuAttribute.values)
                if ((attrPoints[attr] ?? 0) != 0)
                  DerivedStat(
                    label: attr.abbreviation,
                    value: '+${attrPoints[attr]}',
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Talents gained',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          talents.isEmpty
              ? const Text('—')
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in talents) Chip(label: Text(t)),
                  ],
                ),
          const SizedBox(height: 12),
          Text('Skill Ranks gained',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          skillRanks.isEmpty
              ? const Text('—')
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in skillRanks.entries)
                      Chip(
                        label: Text(
                          '${entry.key.split('::').first}: +${entry.value}',
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. BONUS PERKS (freeform)
  // ==========================================================================
  Widget _buildBonusPerks(BuildContext context) {
    return SectionCard(
      title: 'Bonus Perks',
      icon: Icons.star_outline,
      trailing: IconButton(
        tooltip: 'Add',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _update(() => _c.bonusPerks.add(BonusPerkEntry())),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Bonus Perks gained outside the Power Level Table (a Trait, or '
              'ARC benevolence). Leave Level blank for one that always '
              'applies.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (_c.bonusPerks.isEmpty)
            const Text('No Bonus Perks recorded.')
          else
            for (var i = 0; i < _c.bonusPerks.length; i++)
              _bonusPerkRow(context, i),
        ],
      ),
    );
  }

  Widget _bonusPerkRow(BuildContext context, int index) {
    final perk = _c.bonusPerks[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 130,
                  child: _numberField(
                    label: 'Level (0 = always)',
                    value: perk.powerLevel ?? 0,
                    min: 0,
                    max: PowerLevelRules.maxPowerLevel,
                    onChanged: (v) => _update(() {
                      perk.powerLevel = v == 0 ? null : v;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _textField(
                    label: 'Source',
                    value: perk.source,
                    onChanged: (v) => _update(() => perk.source = v),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      _update(() => _c.bonusPerks.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _redeemAsDropdown(
              value: perk.resolvedKind,
              onChanged: (kind) => _update(() => perk.resolvedKind = kind),
            ),
            const SizedBox(height: 8),
            if (perk.resolvedKind == ProgressionGrantKind.attributeAddition)
              _attributePointsEditor(
                points: perk.attributePoints,
                onChanged: (attr, value) => _update(() {
                  if (value == 0) {
                    perk.attributePoints.remove(attr);
                  } else {
                    perk.attributePoints[attr] = value;
                  }
                }),
              )
            else if (perk.resolvedKind == ProgressionGrantKind.talentAddition)
              _talentEditor(
                fieldKey: 'bonus-$index',
                name: perk.talentName,
                onChanged: (name) => _update(() => perk.talentName = name),
              )
            else if (perk.resolvedKind == ProgressionGrantKind.skillImprovement)
              _skillRanksEditor(
                skillRanks: perk.skillRanks,
                rankBudget: kSkillImprovementRanks,
                allowStacking: false,
                onSet: (skillKey, ranks) => _update(() {
                  if (ranks <= 0) {
                    perk.skillRanks.remove(skillKey);
                  } else {
                    perk.skillRanks[skillKey] = ranks;
                  }
                }),
                onRename: (oldKey, newKey) => _update(() {
                  // Don't let two rows collapse onto the same skill.
                  if (newKey != oldKey &&
                      perk.skillRanks.containsKey(newKey)) {
                    return;
                  }
                  final ranks = perk.skillRanks.remove(oldKey) ?? 1;
                  perk.skillRanks[newKey] = ranks;
                }),
                onAdd: () => _update(() {
                  final key = _firstUnusedSkillKey(perk.skillRanks);
                  if (key != null) perk.skillRanks[key] = 1;
                }),
              ),
            const SizedBox(height: 8),
            ResizableTextField(
              label: 'Notes',
              value: perk.notes,
              initialLines: 2,
              onChanged: (v) => _update(() => perk.notes = v),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Shared sub-editors (Main Progression slots + Bonus Perks)
  // ==========================================================================

  Widget _redeemAsDropdown({
    required ProgressionGrantKind? value,
    required ValueChanged<ProgressionGrantKind> onChanged,
  }) {
    return DropdownButtonFormField<ProgressionGrantKind>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Redeem as…',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(
          value: ProgressionGrantKind.attributeAddition,
          child: Text('Attribute Addition'),
        ),
        DropdownMenuItem(
          value: ProgressionGrantKind.talentAddition,
          child: Text('Talent Addition'),
        ),
        DropdownMenuItem(
          value: ProgressionGrantKind.skillImprovement,
          child: Text('Skill Improvement'),
        ),
      ],
      onChanged: (kind) {
        if (kind != null) onChanged(kind);
      },
    );
  }

  Widget _attributePointsEditor({
    required Map<DbuAttribute, int> points,
    required void Function(DbuAttribute attr, int value) onChanged,
  }) {
    final spent = points.values.fold<int>(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spent $spent / $kAttributeAdditionPoints points',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: spent > kAttributeAdditionPoints ? Colors.orange : null,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final attr in DbuAttribute.values)
              SizedBox(
                width: 100,
                child: _numberField(
                  label: attr.abbreviation,
                  value: points[attr] ?? 0,
                  min: 0,
                  max: 20,
                  onChanged: (v) => onChanged(attr, v),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _talentEditor({
    required String fieldKey,
    required String name,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('talent-$fieldKey-$name'),
            initialValue: name,
            decoration: const InputDecoration(
              labelText: 'Talent',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          tooltip: 'Pick from Talents catalogue',
          icon: const Icon(Icons.list_alt_outlined),
          onPressed: () async {
            final chosen = await showDialog<Object>(
              context: context,
              builder: (dialogContext) => const TalentCataloguePickerDialog(),
            );
            if (chosen is TalentDef) onChanged(chosen.name);
          },
        ),
      ],
    );
  }

  Widget _skillRanksEditor({
    required Map<String, int> skillRanks,
    required int rankBudget,
    required bool allowStacking,
    required void Function(String skillKey, int ranks) onSet,
    required void Function(String oldKey, String newKey) onRename,
    required VoidCallback onAdd,
  }) {
    final used = skillRanks.values.fold<int>(0, (a, b) => a + b);
    final over = used > rankBudget;
    // "Select N different Skills, each one gains a Skill Rank" — so each Skill
    // caps at 1 Rank, EXCEPT the PL1 first Skill Improvement whose 2 bonus
    // Ranks "may be placed in the same Skill".
    final maxPerSkill = allowStacking ? rankBudget : 1;
    final canAdd =
        used < rankBudget && _firstUnusedSkillKey(skillRanks) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skill Ranks: $used / $rankBudget'
          '${allowStacking ? '  (4 different Skills + 2 that may stack)' : '  (each a different Skill)'}',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: over ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 4),
        for (final entry in skillRanks.entries)
          _skillRankRow(entry.key, entry.value, maxPerSkill,
              skillRanks.keys.toSet(), onSet, onRename),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Skill'),
            onPressed: canAdd ? onAdd : null,
          ),
        ),
      ],
    );
  }

  Widget _skillRankRow(
    String skillKey,
    int ranks,
    int maxRank,
    Set<String> usedKeys,
    void Function(String skillKey, int ranks) onSet,
    void Function(String oldKey, String newKey) onRename,
  ) {
    final parts = skillKey.split('::');
    final skillName = parts.isNotEmpty ? parts[0] : '';
    final specialtyKey =
        parts.length > 1 ? parts[1] : SkillProgress.normalKey;
    final skill = kDbuSkills.firstWhere(
      (s) => s.name == skillName,
      orElse: () => kDbuSkills.first,
    );

    // First specialty (or normalKey) for [s] that no OTHER row already uses.
    String? freeSpecialty(SkillDef s) {
      if (s.isEncompassing) {
        for (final spec in s.specialties) {
          if (!usedKeys.contains('${s.name}::$spec')) return spec;
        }
        return null;
      }
      final key = '${s.name}::${SkillProgress.normalKey}';
      return usedKeys.contains(key) ? null : SkillProgress.normalKey;
    }

    // The row is keyed by its Skill key so widget state (dropdown display)
    // tracks the DATA, not its position — otherwise renaming/reordering an
    // entry leaves a stale specialty dropdown behind (Encompassing → normal).
    return Padding(
      key: ValueKey(skillKey),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<SkillDef>(
              initialValue: skill,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                // Exclude Skills that are already fully used by other rows, so
                // a switch can never collide onto an existing key.
                for (final s in kDbuSkills)
                  if (s == skill || freeSpecialty(s) != null)
                    DropdownMenuItem(value: s, child: Text(s.name)),
              ],
              onChanged: (newSkill) {
                if (newSkill == null || newSkill == skill) return;
                final spec = freeSpecialty(newSkill) ??
                    (newSkill.isEncompassing
                        ? newSkill.specialties.first
                        : SkillProgress.normalKey);
                onRename(skillKey, '${newSkill.name}::$spec');
              },
            ),
          ),
          if (skill.isEncompassing) ...[
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: skill.specialties.contains(specialtyKey)
                    ? specialtyKey
                    : skill.specialties.first,
                isDense: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  // Only offer specialties not already taken by another row.
                  for (final spec in skill.specialties)
                    if (spec == specialtyKey ||
                        !usedKeys.contains('$skillName::$spec'))
                      DropdownMenuItem(value: spec, child: Text(spec)),
                ],
                onChanged: (newSpec) {
                  if (newSpec == null || newSpec == specialtyKey) return;
                  onRename(skillKey, '$skillName::$newSpec');
                },
              ),
            ),
          ],
          const SizedBox(width: 6),
          SizedBox(
            width: 80,
            child: _numberField(
              label: 'Ranks',
              value: ranks,
              min: 0,
              max: maxRank,
              onChanged: (v) => onSet(skillKey, v),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            onPressed: () => onSet(skillKey, 0),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Reusable input helpers (mirrors character_edit_screen.dart's own)
  // ==========================================================================
  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    // No value-based key: keeping the same element preserves the text
    // field's focus/cursor while the user types (see the equivalent note on
    // `character_edit_screen.dart`'s own `_numberField`).
    return TextFormField(
      initialValue: '$value',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed == null) return;
        onChanged(parsed.clamp(min, max));
      },
    );
  }
}
