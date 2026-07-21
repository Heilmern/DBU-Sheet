/// character_edit_screen.dart
/// ---------------------------------------------------------------------------
/// The CHARACTER PAGE — used for both creating a new character and editing an
/// existing one. It re-imagines the old spreadsheet's "Character" tab with the
/// current dbu-rpg.com rules, organised into the same familiar sections:
///
///   1. Basic Information   (identity, race, size, power level)
///   2. Attributes          (7 editable Scores → live Modifiers)
///   3. Skills              (editable Ranks → live Skill Bonuses)
///   4. Status              (Life/Ki/Capacity, quick-adjust, Super Stacks,
///                           Health Thresholds, Healing/Power Surges)
///   5. Dice & Ranges        (ToP Extra/Critical/Greater Dice, Melee/Long Range)
///   6. Aptitudes           (Might, Haste, Awareness, Speed, Initiative, DV, Soak)
///   7. Saving Throws       (Impulsive / Cognitive / Corporeal / Morale)
///   8. Combat Rolls        (Strike, Dodge, Wound Physical/Energy/Magic)
///   9. Damage Calculator   (Category/Parry/Reduction → Health Reduction)
///  10. Resources / Conditions / States (freeform tracked lists)
///  11. Custom Buffs & Debuffs (generic Flat/(bT)/(T) stat modifiers)
///  12. Z-Soul              (quote, alignment, karma, description)
///
/// The screen edits a *working copy* of the character. Every keystroke updates
/// that copy and triggers a recompute via [CharacterCalculator], so all derived
/// numbers refresh instantly. Tapping SAVE returns the copy to the caller (the
/// list screen), which persists it; backing out discards the copy untouched.
///
/// Editable inputs = white/outlined fields. Computed values = tinted read-only
/// [DerivedStat] chips, mirroring how the spreadsheet greyed-out its formulas.
///
/// The Character tab is responsive: below 1000 logical px it's one 900-wide
/// column in the numbered order above; at or above it the sections regroup into
/// two columns under one shared scroll view (1/2/3/12 left, 4–11 right) so the
/// sheet scrolls roughly half as far on desktop.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/custom_buff_targets.dart';
import '../data/dbu_rules.dart';
import '../data/homebrew_registry.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import '../services/progression_talent_sync.dart';
import '../services/race_resource_sync.dart';
import '../services/trait_talent_sync.dart';
import 'combat_screen.dart' show CombatScreen;
import 'information_screen.dart' show InformationTab;
import 'inventory_screen.dart' show InventoryTab;
import 'references_screen.dart' show ReferencesTab;
import 'signatures_screen.dart' show SignaturesTab;
import 'unique_abilities_screen.dart' show UniqueAbilitiesTab;
import 'progression_screen.dart' show ProgressionTab;
import 'transformations_screen.dart' show TransformationsTab;
import 'widgets/sheet_widgets.dart';

class CharacterEditScreen extends StatefulWidget {
  const CharacterEditScreen({
    super.key,
    required this.character,
    required this.isNew,
    required this.onSave,
  });

  /// A working copy of the character being edited (safe to mutate).
  final Character character;

  /// True when creating a brand-new character (affects the title/labels).
  final bool isNew;

  /// Persists the current working copy (e.g. `repository.upsert`) and refreshes
  /// the roster. Called by the Save action, which then stays on this page — the
  /// editor no longer closes on Save; the player leaves via the back button.
  final Future<void> Function(Character) onSave;

  @override
  State<CharacterEditScreen> createState() => _CharacterEditScreenState();
}

class _CharacterEditScreenState extends State<CharacterEditScreen>
    with SingleTickerProviderStateMixin {
  late Character _c;

  /// Freshly recomputed derived stats; rebuilt on every edit via [_recompute].
  late DerivedCharacterStats _stats;

  /// Drives the Character/Information/Progression sheet tabs (like
  /// spreadsheet tabs — all operate on the same [_c] working copy and
  /// [_stats], so switching tabs never loses or desyncs an edit).
  late final TabController _tabController =
      TabController(length: 8, vsync: this);

  // Transient "Modify Life/Ki" and "Healing Surge roll" quick-adjust inputs.
  // These are NOT persisted on the Character — only the resulting Current
  // Life/Ki matters, mirroring the old sheet's scratch-cell behaviour.
  final _modifyLifeController = TextEditingController();
  final _modifyKiController = TextEditingController();
  final _healingSurgeRollController = TextEditingController();

  // Damage Calculator inputs. Ephemeral (not persisted on Character) — it's
  // a one-off calculator utility, not a tracked character trait, mirroring
  // the old sheet's "Damage Calculator" tab.
  DamageCategory _dmgCategory = DamageCategory.standard;
  ParryOption _dmgParry = ParryOption.none;
  int _dmgReduction = 0;
  int _dmgWoundRoll = 0;

  @override
  void initState() {
    super.initState();
    _c = widget.character;
    _recompute();
  }

  @override
  void dispose() {
    _modifyLifeController.dispose();
    _modifyKiController.dispose();
    _healingSurgeRollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Recomputes all derived numbers from the current working copy. Also
  /// re-syncs any Resources granted by the current Race's active Traits/
  /// Options (see `ensureRaceGrantedResources`) and any Talents picked via
  /// the Progression tab (see `ensureProgressionTalentsInTalentList`) so
  /// they always show up without the player adding them by hand too.
  void _recompute() {
    ensureRaceGrantedResources(_c);
    ensureProgressionTalentsInTalentList(_c);
    ensureTraitGrantedTalents(_c);
    _stats = CharacterCalculator.compute(_c);
  }

  /// Applies a +/- delta typed into a "Modify" field to a current pool, then
  /// clears the field.
  void _applyDelta(
    TextEditingController controller,
    int? Function() getCurrent,
    void Function(int) setCurrent,
    int max,
  ) {
    final delta = int.tryParse(controller.text.trim());
    if (delta == null) return;
    _update(() {
      final current = getCurrent() ?? max;
      setCurrent((current + delta).clamp(0, max));
    });
    controller.clear();
  }

  /// Applies a mutation to the working copy and refreshes derived stats.
  void _update(VoidCallback mutate) {
    setState(() {
      mutate();
      _recompute();
    });
  }

  /// Persists the working copy without leaving the page, then confirms with a
  /// toast — so the player can keep editing after saving. Guards against
  /// double-taps while a save is in flight.
  bool _saving = false;
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_c);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Character saved.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Opens the Combat tracker page on the SAME working copy — Life/Ki/stack
  /// changes made there show up here and persist via SAVE (or are discarded
  /// together on back-out). Refreshes on return in case combat mutated it.
  Future<void> _startCombat() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CombatScreen(character: _c)),
    );
    if (mounted) _update(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Character' : 'Edit Character'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Character', icon: Icon(Icons.badge_outlined)),
            Tab(text: 'Information', icon: Icon(Icons.info_outline)),
            Tab(text: 'Progression', icon: Icon(Icons.trending_up)),
            Tab(text: 'Transformations', icon: Icon(Icons.bolt)),
            Tab(text: 'Inventory', icon: Icon(Icons.backpack_outlined)),
            Tab(text: 'Signatures', icon: Icon(Icons.auto_awesome)),
            Tab(text: 'Unique Abilities', icon: Icon(Icons.psychology_alt_outlined)),
            Tab(text: 'References', icon: Icon(Icons.menu_book_outlined)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _startCombat,
            icon: const Icon(Icons.sports_mma),
            label: const Text('Start Combat'),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCharacterTab(),
          InformationTab(character: _c, stats: _stats, onUpdate: _update),
          ProgressionTab(character: _c, stats: _stats, onUpdate: _update),
          TransformationsTab(character: _c, stats: _stats, onUpdate: _update),
          InventoryTab(character: _c, stats: _stats, onUpdate: _update),
          SignaturesTab(character: _c, stats: _stats, onUpdate: _update),
          UniqueAbilitiesTab(character: _c, stats: _stats, onUpdate: _update),
          ReferencesTab(character: _c, stats: _stats),
        ],
      ),
    );
  }

  /// Minimum tab width at which the Character sheet splits into two columns —
  /// below this each column would be too narrow for the stat chips to breathe.
  static const double _twoColumnBreakpoint = 1000;

  /// The Character tab's sections, in single-column reading order.
  ///
  /// [_buildCharacterTab] regroups these into two balanced columns on wide
  /// windows; the split is curated rather than computed because the sections
  /// differ wildly in height (Skills alone is ~21 rows).
  /// Left column / start of the single-column order. Z-Soul is appended by the
  /// caller: it tails the left column when split, and the whole sheet when not.
  List<Widget> _characterSectionsLeft() => [
        _buildBasicInfo(),
        _buildAttributes(),
        _buildSkills(),
      ];

  List<Widget> _characterSectionsRight() => [
        _buildStatus(),
        _buildDiceAndRanges(),
        _buildAptitudes(),
        _buildSavingThrows(),
        _buildCombatRolls(),
        _buildDamageCalculator(),
        _buildResourcesList(),
        _buildConditionsList(),
        _buildStatesList(),
        _buildCustomBuffs(),
      ];

  Widget _buildResourcesList() => _buildTrackedList(
        title: 'Resources',
        icon: Icons.bolt_outlined,
        entries: _c.resources,
        header: _buildDefaultResources(),
      );

  Widget _buildConditionsList() => _buildTrackedList(
        title: 'Conditions',
        icon: Icons.sick_outlined,
        entries: _c.conditions,
        // Official Conditions plus homebrew ones (same automated-penalty
        // machinery — see HomebrewConditionData).
        catalog: [...kDbuConditions, ...HomebrewRegistry.conditionDefs()],
        lookupByName: HomebrewRegistry.resolveConditionDef,
        automatedEffectText: (entry, def) {
          final condition = def as ConditionDef;
          final penalty = CharacterCalculator.conditionPenalty(_c, entry);
          return '${_fmt(-penalty)} '
              '${condition.affectedStats.map((s) => s.displayName).join(', ')}';
        },
      );

  Widget _buildStatesList() => _buildTrackedList(
        title: 'States',
        icon: Icons.local_fire_department_outlined,
        entries: _c.states,
        // Official States plus homebrew ones (same Level-gated automation).
        catalog: [...kDbuStates, ...HomebrewRegistry.stateDefs()],
        lookupByName: HomebrewRegistry.resolveStateDef,
        automatedEffectText: (entry, def) {
          final effect = CharacterCalculator.statePerStatEffect(_c, entry);
          final parts = [
            for (final e in effect.entries)
              '${_fmt(e.value)} ${e.key.displayName}',
          ];
          if (CharacterCalculator.stateIgnoresHealthThresholdPenalties(
              _c, entry)) {
            parts.add('Ignores Health Threshold Penalties');
          }
          return parts.isEmpty ? '—' : parts.join(', ');
        },
      );

  Widget _buildCharacterTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoColumnBreakpoint) {
          return Center(
            child: ConstrainedBox(
              // Comfortable reading width on large desktop/web windows.
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._characterSectionsLeft(),
                  ..._characterSectionsRight(),
                  _buildZSoul(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
        // Wide window: one shared scroll view over two columns, so the sheet
        // scrolls roughly half as far.
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._characterSectionsLeft(),
                        _buildZSoul(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ..._characterSectionsRight(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 1. BASIC INFORMATION
  // ==========================================================================
  Widget _buildBasicInfo() {
    return SectionCard(
      title: 'Basic Information',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _textField(
            label: 'Character Name',
            value: _c.name,
            onChanged: (v) => _update(() => _c.name = v),
          ),
          _textField(
            label: 'Player',
            value: _c.player,
            onChanged: (v) => _update(() => _c.player = v),
          ),
          Row(
            children: [
              Expanded(child: _raceDropdown()),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(
                  label: 'Subspecies',
                  value: _c.subspecies,
                  onChanged: (v) => _update(() => _c.subspecies = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _sizeDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _powerLevelField()),
              const SizedBox(width: 12),
              // Tier of Power is derived, shown read-only alongside PL.
              DerivedStat(
                label: 'Tier of Power',
                value: '${_stats.tierOfPower}',
                emphasize: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Cosmetic / biography fields, wrapped so they flow on any width.
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _shortField('Age', _c.age, (v) => _c.age = v),
              _shortField('Gender', _c.gender, (v) => _c.gender = v),
              _shortField('Height', _c.height, (v) => _c.height = v),
              _shortField('Weight', _c.weight, (v) => _c.weight = v),
              _shortField('Hair Color', _c.hairColor, (v) => _c.hairColor = v),
              _shortField('Eye Color', _c.eyeColor, (v) => _c.eyeColor = v),
              _shortField('Skin Tone', _c.skinTone, (v) => _c.skinTone = v),
            ],
          ),
        ],
      ),
    );
  }

  Widget _raceDropdown() {
    // Build the option list from the rules plus any homebrew Races, ensuring
    // the character's current race is present even if it isn't listed.
    final names = kDbuRaces.map((r) => r.name).toList();
    for (final r in HomebrewRegistry.raceDefs()) {
      if (!names.contains(r.name)) names.add(r.name);
    }
    if (!names.contains(_c.race)) names.insert(0, _c.race);
    return DropdownButtonFormField<String>(
      initialValue: _c.race,
      decoration: const InputDecoration(
        labelText: 'Race',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: names
          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
          .toList(),
      onChanged: (v) => _update(() => _c.race = v ?? _c.race),
    );
  }

  Widget _sizeDropdown() {
    return DropdownButtonFormField<DbuSize>(
      initialValue: _c.size,
      decoration: const InputDecoration(
        labelText: 'Base Size',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: DbuSize.values
          .map((s) =>
              DropdownMenuItem(value: s, child: Text(s.displayName)))
          .toList(),
      onChanged: (v) => _update(() => _c.size = v ?? _c.size),
    );
  }

  Widget _powerLevelField() {
    return _numberField(
      label: 'Power Level',
      value: _c.powerLevel,
      min: PowerLevelRules.minPowerLevel,
      max: PowerLevelRules.maxPowerLevel,
      onChanged: (v) => _update(() {
        _c.powerLevel = v;
        // Changing PL changes the maximums; clear "current" overrides so
        // Life/Ki snap back to full (null = full in the model) and reset
        // Capacity spending (there's no equivalent "full" sentinel for it).
        _c.currentLife = null;
        _c.currentKi = null;
        _c.capacitySpent = 0;
      }),
    );
  }

  // ==========================================================================
  // 2. ATTRIBUTES  (Score editable → Modifier computed)
  // ==========================================================================
  Widget _buildAttributes() {
    final race = HomebrewRegistry.resolveRace(_c.race);
    final scoreLimit = CharacterCalculator.attributeScoreLimit(_c);
    return SectionCard(
      title: 'Attributes',
      icon: Icons.fitness_center,
      trailing: Text('Modifier = Score  ·  Max $scoreLimit (ToP)',
          style: Theme.of(context).textTheme.labelSmall),
      child: Column(
        children: [
          for (final attr in DbuAttribute.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Attribute name + abbreviation.
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${attr.displayName} (${attr.abbreviation})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  // Computed Score (Race + Progression — see Progression tab).
                  Expanded(
                    flex: 3,
                    child: DerivedStat(
                      label: 'Score',
                      value: '${_c.scoreOf(attr)}',
                      warn: _c.scoreOf(attr) > scoreLimit,
                      tooltip: _c.scoreOf(attr) > scoreLimit
                          ? 'Over the Tier-of-Power Score limit of $scoreLimit'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Computed Modifier.
                  Expanded(
                    flex: 2,
                    child: DerivedStat(
                      label: 'Modifier',
                      value: '${_stats.attributeModifiers[attr]}',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (race.attributeIncrease.choices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Racial Attribute Bonus Choice(s)',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            if (race.attributeIncreaseText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  race.attributeIncreaseText,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            for (var i = 0; i < race.attributeIncrease.choices.length; i++)
              _raceAttributeChoiceDropdown(race, i),
            if (_duplicateAttributeChoice(race))
              Text(
                'Each slot must be a different Attribute.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ],
      ),
    );
  }

  /// Whether two of this Race's Attribute-increase slots point at the same
  /// Attribute. Every Race with more than one slot words it as "two different
  /// Attributes … a third Attribute" (Bio Android, Custom Species) or "one
  /// other Attribute" (Shinjin), so a repeat is always illegal — surfaced as a
  /// warning rather than being clamped, per this app's convention.
  bool _duplicateAttributeChoice(RaceDef race) {
    final picked = <DbuAttribute>[];
    for (var i = 0; i < race.attributeIncrease.choices.length; i++) {
      final attr = i < _c.raceAttributeIncreaseChoices.length
          ? _c.raceAttributeIncreaseChoices[i]
          : null;
      if (attr != null) picked.add(attr);
    }
    return picked.toSet().length != picked.length;
  }

  /// One dropdown for a single `RaceAttributeIncrease.choices[index]` slot —
  /// e.g. Cerealian's "either Force or Magic score is increased by +1".
  Widget _raceAttributeChoiceDropdown(RaceDef race, int index) {
    final choice = race.attributeIncrease.choices[index];
    final options = choice.options.isEmpty
        ? DbuAttribute.values.toList()
        : choice.options;
    final current = index < _c.raceAttributeIncreaseChoices.length
        ? _c.raceAttributeIncreaseChoices[index]
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<DbuAttribute>(
        initialValue: current,
        decoration: InputDecoration(
          labelText: '+${choice.amount} to…',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final attr in options)
            DropdownMenuItem(value: attr, child: Text(attr.displayName)),
        ],
        onChanged: (value) => _update(() {
          while (_c.raceAttributeIncreaseChoices.length <= index) {
            _c.raceAttributeIncreaseChoices.add(null);
          }
          _c.raceAttributeIncreaseChoices[index] = value;
        }),
      ),
    );
  }

  // ==========================================================================
  // 3. SKILLS  (Ranks editable → Bonus computed; specialties expanded)
  // ==========================================================================
  Widget _buildSkills() {
    final theme = Theme.of(context);
    final budget = CharacterCalculator.raceSkillRanks(_c);
    final spent = _c.skills.values.fold<int>(
      0,
      (a, sp) => a + sp.ranks.values.fold<int>(0, (x, y) => x + y),
    );
    final over = spent > budget;
    final rankLimit = CharacterCalculator.skillRankLimit(_c);
    return SectionCard(
      title: 'Skills',
      icon: Icons.school_outlined,
      trailing: Text('Bonus = ½ Score + 2×Total Ranks  ·  Max $rankLimit (ToP)',
          style: theme.textTheme.labelSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Base Skill Ranks: $spent / $budget spent'
              '${over ? '  (over budget!)' : ''}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: over ? theme.colorScheme.error : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Racial Skill Ranks — tick one Skill each '
              "Progression Skill "
              'Improvements add on top.'
              '${_c.race == 'Custom Species' ? ' A Flaw Trait can raise the '
                  'total by 1 — see the Information tab.' : ''}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          for (final skill in kDbuSkills) ..._skillRows(skill),
        ],
      ),
    );
  }

  /// Builds one row per skill, or one row per specialty for Encompassing skills.
  List<Widget> _skillRows(SkillDef skill) {
    final progress = _c.skills[skill.name] ?? SkillProgress();

    Widget row(String rowLabel, String specialtyKey, int bonus) {
      final totalRanks =
          CharacterCalculator.totalSkillRanks(_c, skill, specialty: specialtyKey);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: rowLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextSpan(
                    text: '  (${skill.attribute.abbreviation})',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ]),
              ),
            ),
            Expanded(
              flex: 3,
              // Racial Skill Ranks: 1 per Skill, no Skill chosen twice — so
              // this is a checkbox (0/1), not a free count. Progression Skill
              // Improvements add on top via `totalSkillRanks`.
              child: Row(
                children: [
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: progress.ranksFor(specialtyKey) > 0,
                    onChanged: (v) => _update(() {
                      progress.setRanks(specialtyKey, v == true ? 1 : 0);
                      _c.skills[skill.name] = progress;
                    }),
                  ),
                  Flexible(
                    child: Text('Racial Rank',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DerivedStat(
                label: 'Total',
                value: '$totalRanks',
                warn: totalRanks >
                    CharacterCalculator.skillRankLimit(_c),
                tooltip: totalRanks >
                        CharacterCalculator.skillRankLimit(_c)
                    ? 'Over the Tier-of-Power limit of '
                        '${CharacterCalculator.skillRankLimit(_c)} Ranks'
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DerivedStat(label: 'Bonus', value: _fmt(bonus)),
            ),
          ],
        ),
      );
    }

    if (skill.isEncompassing) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(skill.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        for (final spec in skill.specialties)
          row(
            '  • $spec',
            spec,
            CharacterCalculator.skillBonus(_c, skill, specialty: spec),
          ),
      ];
    }
    return [
      row(skill.name, SkillProgress.normalKey,
          CharacterCalculator.skillBonus(_c, skill)),
    ];
  }

  // ==========================================================================
  // 4. STATUS  (computed maximums + editable current trackers)
  // ==========================================================================
  Widget _buildStatus() {
    return SectionCard(
      title: 'Status',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          _resourceRow(
            label: 'Life Points',
            current: _stats.currentLife,
            max: _stats.maxLife,
            statusChip: _stats.healthStatus,
            onCurrentChanged: (v) =>
                _update(() => _c.currentLife = v.clamp(0, _stats.maxLife)),
            onReset: () => _update(() => _c.currentLife = null),
          ),
          _modifyRow(
            controller: _modifyLifeController,
            label: 'Modify Life (+/-)',
            onApply: () => _applyDelta(
              _modifyLifeController,
              () => _c.currentLife,
              (v) => _c.currentLife = v,
              _stats.maxLife,
            ),
          ),
          const SizedBox(height: 8),
          _resourceRow(
            label: 'Ki Pool',
            current: _stats.currentKi,
            max: _stats.maxKi,
            onCurrentChanged: (v) =>
                _update(() => _c.currentKi = v.clamp(0, _stats.maxKi)),
            onReset: () => _update(() => _c.currentKi = null),
          ),
          _modifyRow(
            controller: _modifyKiController,
            label: 'Modify Ki (+/-)',
            onApply: () => _applyDelta(
              _modifyKiController,
              () => _c.currentKi,
              (v) => _c.currentKi = v,
              _stats.maxKi,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Text('Capacity',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Expanded(
                flex: 3,
                child: _numberField(
                  label: 'Spent',
                  value: _c.capacitySpent,
                  min: 0,
                  max: _stats.maxCapacity,
                  onChanged: (v) => _update(() => _c.capacitySpent = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DerivedStat(
                  label: 'Left / Max',
                  value: '${_stats.currentCapacity} / ${_stats.maxCapacity}',
                  emphasize: true,
                ),
              ),
              IconButton(
                tooltip: 'Reset to full',
                icon: const Icon(Icons.refresh),
                onPressed: () => _update(() => _c.capacitySpent = 0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Super Stacks',
                  value: _c.superStacks,
                  min: 0,
                  max: CapacityRules.maxSuperStacks,
                  onChanged: (v) => _update(() => _c.superStacks = v),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Health Thresholds (checked = Steadfast Check passed)',
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              _thresholdCheckbox(
                'Bruised',
                _c.bruisedSteadfastPassed,
                (v) => _c.bruisedSteadfastPassed = v,
              ),
              _thresholdCheckbox(
                'Injured',
                _c.injuredSteadfastPassed,
                (v) => _c.injuredSteadfastPassed = v,
              ),
              _thresholdCheckbox(
                'Critical',
                _c.criticalSteadfastPassed,
                (v) => _c.criticalSteadfastPassed = v,
              ),
              DerivedStat(
                label: 'Threshold Penalty',
                value: _fmt(-_stats.healthThresholdPenalty),
              ),
            ],
          ),
          const Divider(height: 24),
          Text('Surges', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: DerivedStat(
                  label: 'Healing Surge',
                  value: _stats.healingSurgeDice,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _healingSurgeRollController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Rolled amount',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _applyDelta(
                    _healingSurgeRollController,
                    () => _c.currentLife,
                    (v) => _c.currentLife = v,
                    _stats.maxLife,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Apply Healing Surge to Current Life',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _applyDelta(
                  _healingSurgeRollController,
                  () => _c.currentLife,
                  (v) => _c.currentLife = v,
                  _stats.maxLife,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DerivedStat(
                  label: 'Power Surge Ki',
                  value: '+${_stats.powerSurgeKi}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DerivedStat(
                  label: 'Power Surge Capacity',
                  value: '+${_stats.powerSurgeCapacity}',
                ),
              ),
              IconButton(
                tooltip: 'Apply Power Surge to Current Ki/Capacity',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _update(() {
                  final curKi = _c.currentKi ?? _stats.maxKi;
                  _c.currentKi =
                      (curKi + _stats.powerSurgeKi).clamp(0, _stats.maxKi);
                  _c.capacitySpent = (_c.capacitySpent - _stats.powerSurgeCapacity)
                      .clamp(0, _stats.maxCapacity);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A compact "Modify" quick-adjust row: a delta text field plus an Apply
  /// button that adds/subtracts it from a current pool and clears itself.
  Widget _modifyRow({
    required TextEditingController controller,
    required String label,
    required VoidCallback onApply,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: 'e.g. +6 or -20',
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          IconButton(
            tooltip: 'Apply',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: onApply,
          ),
        ],
      ),
    );
  }

  Widget _thresholdCheckbox(
      String label, bool value, ValueChanged<bool> setter) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: (v) => _update(() => setter(v)),
    );
  }

  /// One resource line: an editable "current" value, its computed max, an
  /// optional health label, and a reset-to-full button.
  Widget _resourceRow({
    required String label,
    required int current,
    required int max,
    String? statusChip,
    required ValueChanged<int> onCurrentChanged,
    required VoidCallback onReset,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall),
              if (statusChip != null)
                Text(statusChip,
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: _numberField(
            label: 'Current',
            value: current,
            min: 0,
            max: max,
            onChanged: onCurrentChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DerivedStat(label: 'Max', value: '$max', emphasize: true),
        ),
        IconButton(
          tooltip: 'Reset to full',
          icon: const Icon(Icons.refresh),
          onPressed: onReset,
        ),
      ],
    );
  }

  // ==========================================================================
  // 5. DICE & RANGES  (all computed)
  // ==========================================================================
  Widget _buildDiceAndRanges() {
    return SectionCard(
      title: 'Dice & Ranges',
      icon: Icons.casino_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          DerivedStat(label: 'ToP Extra Dice', value: _stats.topExtraDice),
          DerivedStat(label: 'Critical Dice', value: _stats.criticalDice),
          DerivedStat(label: 'Greater Dice', value: _stats.greaterDice),
          const DerivedStat(
              label: 'Melee Reach', value: RangeRules.meleeReachLabel),
          const DerivedStat(
              label: 'Long Range', value: RangeRules.longRangeLabel),
        ],
      ),
    );
  }

  // ==========================================================================
  // 6. APTITUDES  (all computed)
  // ==========================================================================
  Widget _buildAptitudes() {
    return SectionCard(
      title: 'Aptitudes',
      icon: Icons.auto_graph,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          DerivedStat(label: 'Might', value: '${_stats.might}'),
          if (_stats.mightForClashes != _stats.might)
            DerivedStat(
                label: 'Might (Clashes)',
                value: '${_stats.mightForClashes}',
                tooltip: 'Might used in Might Clashes'),
          DerivedStat(label: 'Haste', value: '${_stats.haste}'),
          DerivedStat(label: 'Awareness', value: '${_stats.awareness}'),
          DerivedStat(label: 'Speed (Normal)', value: '${_stats.speedNormal}'),
          DerivedStat(
              label: 'Speed (Boosted)', value: '${_stats.speedBoosted}'),
          DerivedStat(label: 'Initiative', value: '${_stats.initiative}'),
          DerivedStat(label: 'Defense Value', value: '${_stats.defenseValue}'),
          DerivedStat(label: 'Soak', value: '${_stats.soak}'),
        ],
      ),
    );
  }

  // ==========================================================================
  // 7. SAVING THROWS  (all computed)
  // ==========================================================================
  Widget _buildSavingThrows() {
    return SectionCard(
      title: 'Saving Throws',
      icon: Icons.shield_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final save in DbuSavingThrow.values)
            DerivedStat(
              label: '${save.displayName} (${save.attribute.abbreviation})',
              value: _stats.savingThrows[save]!.label,
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 8. COMBAT ROLLS  (all computed)
  // ==========================================================================
  Widget _buildCombatRolls() {
    return SectionCard(
      title: 'Combat Rolls',
      icon: Icons.sports_martial_arts,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          DerivedStat(
              label: 'Strike',
              value: '${_stats.strikeDice}${_stats.strike.label}'),
          DerivedStat(
              label: 'Dodge',
              value: '${_stats.dodgeDice}${_stats.dodge.label}'),
          DerivedStat(
              label: 'Wound (Physical)',
              value: '${_stats.woundDice}${_stats.woundPhysical.label}'),
          DerivedStat(
              label: 'Wound (Energy)',
              value: '${_stats.woundDice}${_stats.woundEnergy.label}'),
          DerivedStat(
              label: 'Wound (Magic)',
              value: '${_stats.woundDice}${_stats.woundMagic.label}'),
        ],
      ),
    );
  }

  // ==========================================================================
  // 9. DAMAGE CALCULATOR  (ephemeral — not persisted on Character)
  // ==========================================================================
  /// Names the auto-included Damage Reduction sources for the calculator note.
  String _damageReductionSources() {
    final parts = <String>[];
    if (_stats.apparelDamageReduction > 0) parts.add('worn Armor');
    if (_stats.weaponDamageReduction > 0) parts.add('a wielded Warding Weapon');
    if (_stats.accessoryDamageReduction > 0) parts.add('equipped Accessories');
    if (_stats.bonusDamageReduction != 0) {
      parts.add('automated Trait/Buff effects');
    }
    if (_stats.hasArmoredAspect) {
      parts.add('the Armored Aspect (Damage Category −1)');
    }
    // Join with commas + a trailing "and" for readability.
    if (parts.length <= 1) return parts.join('');
    if (parts.length == 2) return parts.join(' and ');
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }

  Widget _buildDamageCalculator() {
    // Worn Armor's, wielded Weapons' (Warding) and equipped Accessories' Damage
    // Reduction are auto-included on top of the manual Damage Reduction field
    // (see the Inventory → Apparel / Weapons / Accessories sections).
    final autoReduction = _stats.apparelDamageReduction +
        _stats.weaponDamageReduction +
        _stats.accessoryDamageReduction +
        _stats.bonusDamageReduction;
    final result = CharacterCalculator.computeDamage(
      _stats,
      category: _dmgCategory,
      parry: _dmgParry,
      manualDamageReduction: _dmgReduction + autoReduction,
      woundRoll: _dmgWoundRoll,
      // Armored Aspect: incoming Damage Categories drop by 1.
      armoredAspect: _stats.hasArmoredAspect,
      // "I'm being Bludgeoned" Custom Buff halves Damage Reduction.
      beingBludgeoned: _stats.beingBludgeoned,
    );
    return SectionCard(
      title: 'Damage Calculator',
      icon: Icons.calculate_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DamageCategory>(
                  initialValue: _dmgCategory,
                  decoration: const InputDecoration(
                    labelText: 'Damage Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: DamageCategory.values
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(d.displayName)))
                      .toList(),
                  onChanged: (v) => setState(
                      () => _dmgCategory = v ?? DamageCategory.standard),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<ParryOption>(
                  initialValue: _dmgParry,
                  decoration: const InputDecoration(
                    labelText: 'Parry',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ParryOption.values
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.displayName)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _dmgParry = v ?? ParryOption.none),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Damage Reduction',
                  value: _dmgReduction,
                  min: 0,
                  max: 999,
                  onChanged: (v) => setState(() => _dmgReduction = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  label: 'Wound Roll',
                  value: _dmgWoundRoll,
                  min: 0,
                  max: 999,
                  onChanged: (v) => setState(() => _dmgWoundRoll = v),
                ),
              ),
            ],
          ),
          if (autoReduction > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Includes +$autoReduction Damage Reduction from '
                '${_damageReductionSources()} (Inventory).',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DerivedStat(
                  label: 'Total Reduction',
                  value: '${result.totalReduction}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DerivedStat(
                  label: 'Health Reduction',
                  value: '${result.healthReduction}',
                  emphasize: true,
                ),
              ),
              IconButton(
                tooltip: 'Apply to Current Life',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _update(() {
                  final current = _c.currentLife ?? _stats.maxLife;
                  _c.currentLife =
                      (current - result.healthReduction).clamp(0, _stats.maxLife);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 10. RESOURCES / CONDITIONS / STATES  (freeform tracked lists)
  // ==========================================================================
  /// A repeatable list of [TrackedEntry] rows shared by the Resources,
  /// Conditions and States sections — same shape (Name/Stacks/Max/Notes). If
  /// [catalog] is given (Conditions or States, both implement `CatalogDef`),
  /// each row offers a dropdown of known entries that auto-fill Max
  /// Stacks/Notes and, for the ones with an automated effect, a live
  /// "Automated effect" readout via [automatedEffectText] — otherwise it's a
  /// plain freeform tracker with no stat effects (see `TrackedEntry` doc in
  /// models/character.dart).
  Widget _buildTrackedList({
    required String title,
    required IconData icon,
    required List<TrackedEntry> entries,
    Widget? header,
    List<CatalogDef>? catalog,
    CatalogDef? Function(String name)? lookupByName,
    String Function(TrackedEntry entry, CatalogDef def)? automatedEffectText,
  }) {
    return SectionCard(
      title: title,
      icon: icon,
      trailing: IconButton(
        tooltip: 'Add $title row',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _update(() => entries.add(TrackedEntry())),
      ),
      child: Column(
        children: [
          ?header,
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No other $title tracked yet.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          for (var i = 0; i < entries.length; i++)
            _trackedEntryRow(
              entries,
              i,
              catalog: catalog,
              lookupByName: lookupByName,
              automatedEffectText: automatedEffectText,
            ),
        ],
      ),
    );
  }

  /// Sentinel shown in the catalog dropdown for a freeform/homebrew entry
  /// not in the official list.
  static const String _customCatalogEntry = 'Custom…';

  /// The three Resources every character has access to by default (see
  /// `DefaultResourceRules`), shown above the freeform Resources list. Unlike
  /// those freeform rows, these have known formulas and are auto-applied by
  /// the calculator — the steppers are bound directly to their own Character
  /// fields.
  Widget _buildDefaultResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _numberField(
                label: 'Power (Power Up)',
                value: _c.powerStacks,
                min: 0,
                max: DefaultResourceRules.maxPowerStacks,
                onChanged: (v) => _update(() => _c.powerStacks = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DerivedStat(
                label: 'Effect',
                value: '+${CharacterCalculator.powerCombatRollBonus(_c)} '
                    'Combat Rolls, +${CharacterCalculator.powerMaxCapacityBonus(_c)} '
                    'Max Capacity',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _numberField(
                label: 'Holding Back',
                value: CharacterCalculator.holdingBackStacks(_c),
                min: 0,
                max: CharacterCalculator.baseTierOfPower(_c),
                onChanged: (v) => _update(() => _c.holdingBackStacks = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DerivedStat(
                label: 'Effect',
                value: CharacterCalculator.holdingBackStacks(_c) == 0
                    ? '—'
                    : '−${CharacterCalculator.holdingBackStacks(_c)} Tier of '
                        'Power, +${CharacterCalculator.holdingBackStacks(_c).clamp(0, 3)} '
                        'Concealment'
                        '${CharacterCalculator.holdingBackStacks(_c) >= CharacterCalculator.baseTierOfPower(_c) ? ', −1(bT) Combat Rolls (ToP set to 1)' : ''}',
                tooltip: 'Holding Back Maneuver: −1 Tier of Power per Stack '
                    '(max = base ToP). At the maximum, ToP is set to 1 and '
                    'Combat Rolls take −1(bT). +1 Concealment per Stack '
                    '(max 3).',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _numberField(
                label: 'Diminishing Offense',
                value: _c.diminishingOffenseStacks,
                min: 0,
                max: 99,
                onChanged: (v) =>
                    _update(() => _c.diminishingOffenseStacks = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DerivedStat(
                label: 'Effect',
                value:
                    '${_fmt(-CharacterCalculator.diminishingOffensePenalty(_c))} Strike',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _numberField(
                label: 'Diminishing Defense',
                value: _c.diminishingDefenseStacks,
                min: 0,
                max: 99,
                onChanged: (v) =>
                    _update(() => _c.diminishingDefenseStacks = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: DerivedStat(
                label: 'Effect',
                value:
                    '${_fmt(-CharacterCalculator.diminishingDefensePenalty(_c))} Dodge',
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Gain '
            '${CharacterCalculator.diminishingDefenseStacksPerHit(_c)} '
            'stack(s) of Diminishing Defense each time you\'re hit '
            '(scales with Base Tier of Power).',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _trackedEntryRow(
    List<TrackedEntry> entries,
    int index, {
    List<CatalogDef>? catalog,
    CatalogDef? Function(String name)? lookupByName,
    String Function(TrackedEntry entry, CatalogDef def)? automatedEffectText,
  }) {
    final entry = entries[index];
    final knownNames = catalog?.map((c) => c.name).toSet() ?? const {};
    final isCustom = catalog == null || !knownNames.contains(entry.name);
    final selectedDef =
        catalog == null ? null : lookupByName!(entry.name); // null if custom
    final catalogLabel = catalog == null
        ? ''
        : catalog.first is StateDef
            ? 'State'
            : 'Condition';

    final deleteButton = IconButton(
      tooltip: 'Remove',
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _update(() => entries.removeAt(index)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: catalog != null
                    ? DropdownButtonFormField<String>(
                        // Row-identity key: without it, deleting a middle row
                        // leaves this dropdown (whose FormField state is
                        // element-local) showing the DELETED row's pick.
                        key: ObjectKey(entry),
                        initialValue: isCustom ? _customCatalogEntry : entry.name,
                        decoration: InputDecoration(
                          labelText: catalogLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final def in catalog)
                            DropdownMenuItem(
                                value: def.name, child: Text(def.name)),
                          const DropdownMenuItem(
                            value: _customCatalogEntry,
                            child: Text(_customCatalogEntry),
                          ),
                        ],
                        onChanged: (v) => _update(() {
                          if (v == null || v == _customCatalogEntry) {
                            entry.name = '';
                            entry.notes = '';
                            entry.maxStacks = 1;
                            return;
                          }
                          final def = lookupByName!(v)!;
                          entry.name = def.name;
                          entry.maxStacks = def.maxStacks;
                          entry.notes = def.description;
                          if (entry.stacks > def.maxStacks) {
                            entry.stacks = def.maxStacks;
                          }
                        }),
                      )
                    : _textField(
                        // Row identity (never the typed name — that would
                        // remount per keystroke); re-seeds after deletes.
                        key: ValueKey(('tracked-name', entry)),
                        label: 'Name',
                        value: entry.name,
                        onChanged: (v) => _update(() => entry.name = v),
                      ),
              ),
              deleteButton,
            ],
          ),
          if (catalog != null && isCustom) ...[
            const SizedBox(height: 8),
            _textField(
              key: ValueKey(('tracked-name', entry)),
              label: 'Name',
              value: entry.name,
              onChanged: (v) => _update(() => entry.name = v),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 160,
                child: _numberField(
                  label: catalogLabel == 'State' ? 'Level' : 'Stacks',
                  value: entry.stacks,
                  min: 0,
                  max: entry.maxStacks,
                  onChanged: (v) => _update(() => entry.stacks = v),
                ),
              ),
              SizedBox(
                width: 160,
                child: _numberField(
                  label: catalogLabel == 'State' ? 'Max Level' : 'Max Stacks',
                  value: entry.maxStacks,
                  min: 1,
                  max: 999,
                  onChanged: (v) => _update(() {
                    entry.maxStacks = v;
                    if (entry.stacks > v) entry.stacks = v;
                  }),
                ),
              ),
            ],
          ),
          if (selectedDef != null) ...[
            const SizedBox(height: 8),
            if (selectedDef.isAutomated)
              DerivedStat(
                label: 'Automated effect',
                value: automatedEffectText!(entry, selectedDef),
              )
            else
              Text(
                'Not automated — this effect is not applied to any stat '
                'automatically; apply it yourself when it matters.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
          ],
          const SizedBox(height: 10),
          ResizableTextField(
            key: ValueKey('tracked-notes-$index-${entry.name}'),
            label: 'Notes / Effect',
            value: entry.notes,
            initialLines: 3,
            onChanged: (v) => _update(() => entry.notes = v),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 11. CUSTOM BUFFS & DEBUFFS
  // ==========================================================================
  Widget _buildCustomBuffs() {
    return SectionCard(
      title: 'Custom Buffs & Debuffs',
      icon: Icons.tune,
      trailing: IconButton(
        tooltip: 'Add Custom Buff',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _update(() => _c.customBuffs.add(CustomBuff())),
      ),
      child: Column(
        children: [
          if (_c.customBuffs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No Custom Buffs yet.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          for (var i = 0; i < _c.customBuffs.length; i++)
            _customBuffRow(i),
        ],
      ),
    );
  }

  Widget _customBuffRow(int index) {
    final buff = _c.customBuffs[index];
    final total = CharacterCalculator.customBuffTotal(_c, buff);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _textField(
                  label: 'Name',
                  value: buff.name,
                  onChanged: (v) => _update(() => buff.name = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _textField(
                  label: 'Group',
                  value: buff.group,
                  onChanged: (v) => _update(() => buff.group = v),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: buff.active,
                onChanged: (v) => _update(() => buff.active = v),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _update(() => _c.customBuffs.removeAt(index)),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<CustomBuffTarget>(
                  initialValue: buff.target,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Affected Stat',
                    helperText: buff.target.isAutomated
                        ? buff.target.group.displayName
                        : '${buff.target.group.displayName} · manual — '
                            'apply yourself',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  // Enum declaration order is already grouped; each item is
                  // prefixed with its group and flagged when manual.
                  items: [
                    for (final t in CustomBuffTarget.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.isAutomated
                              ? '${t.group.displayName} · ${t.displayName}'
                              : '${t.group.displayName} · ${t.displayName}  '
                                  '(manual)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) =>
                      _update(() => buff.target = v ?? buff.target),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: 'Flat',
                  value: buff.flat,
                  min: -999,
                  max: 999,
                  onChanged: (v) => _update(() => buff.flat = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: '(bT)',
                  value: buff.perBaseTier,
                  min: -99,
                  max: 99,
                  onChanged: (v) => _update(() => buff.perBaseTier = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: '(T)',
                  value: buff.perTier,
                  min: -99,
                  max: 99,
                  onChanged: (v) => _update(() => buff.perTier = v),
                ),
              ),
              const SizedBox(width: 8),
              DerivedStat(label: 'Total', value: _fmt(total)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 12. Z-SOUL
  // ==========================================================================
  Widget _buildZSoul() {
    return SectionCard(
      title: 'Z-Soul',
      icon: Icons.psychology_alt_outlined,
      child: Column(
        children: [
          _textField(
            label: 'Quote',
            value: _c.zSoul.quote,
            onChanged: (v) => _update(() => _c.zSoul.quote = v),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: kZSoulAlignments.contains(_c.zSoul.alignment)
                      ? _c.zSoul.alignment
                      : 'Neutral',
                  decoration: const InputDecoration(
                    labelText: 'Alignment',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: kZSoulAlignments
                      .map((a) =>
                          DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) =>
                      _update(() => _c.zSoul.alignment = v ?? 'Neutral'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  label: 'Karma',
                  value: _c.zSoul.karma,
                  min: 0,
                  max: KarmaRules.maxKarma,
                  onChanged: (v) => _update(() => _c.zSoul.karma = v),
                ),
              ),
            ],
          ),
          ResizableTextField(
            label: 'Description',
            value: _c.zSoul.description,
            initialLines: 3,
            onChanged: (v) => _update(() => _c.zSoul.description = v),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Reusable input helpers
  // ==========================================================================

  /// Formats a signed integer bonus like "+3" / "-1" / "+0".
  String _fmt(int n) => n >= 0 ? '+$n' : '$n';

  /// A standard multi-purpose text field bound to a string value.
  Widget _textField({
    Key? key,
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        // `initialValue` seeds the field's own controller on first build only;
        // because these fields are only ever changed by the user (never
        // programmatically) the element is reused across rebuilds and the typed
        // text and cursor are preserved without needing an explicit key. When a
        // field CAN change programmatically (e.g. auto-filled Notes from a
        // Condition catalog pick), callers pass a `key` that changes alongside
        // that programmatic update so Flutter remounts it and re-seeds
        // `initialValue` instead of keeping the stale text.
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  /// A narrower text field used in the biography Wrap.
  Widget _shortField(
      String label, String value, ValueChanged<String> setter) {
    return SizedBox(
      width: 150,
      child: _textField(
        label: label,
        value: value,
        onChanged: (v) => _update(() => setter(v)),
      ),
    );
  }

  /// An integer field with +/- steppers and clamping. Used for Scores, Ranks,
  /// Power Level, current pools, karma, etc.
  Widget _numberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    // No value-based key here: keeping the same element preserves the text
    // field's focus/cursor while the user types. The stepper syncs its display
    // to [value] via didUpdateWidget when the value changes programmatically
    // (e.g. the +/- buttons, reset-to-full, or a Power Level change).
    return _IntStepperField(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
    );
  }
}

/// A compact integer input with decrement/increment buttons and a text field
/// in the middle. Clamps to [min]..[max] and rejects non-numeric input.
class _IntStepperField extends StatefulWidget {
  const _IntStepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_IntStepperField> createState() => _IntStepperFieldState();
}

class _IntStepperFieldState extends State<_IntStepperField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(covariant _IntStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the text ONLY when the value changed for a reason other than the
    // user's own typing (e.g. +/- buttons, reset-to-full, PL change). If the
    // field already shows the new value, we leave the controller — and the
    // cursor position — untouched so typing is never interrupted.
    if (widget.value != oldWidget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit(int v) {
    final clamped = v.clamp(widget.min, widget.max);
    _controller.text = '$clamped';
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => _emit(widget.value - 1),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
                signed: widget.min < 0),
            inputFormatters: [
              // Allow a leading "-" whenever negative values are in range
              // (e.g. Custom Buff debuffs), otherwise digits only.
              FilteringTextInputFormatter.allow(
                widget.min < 0 ? RegExp(r'^-?\d*$') : RegExp(r'^\d*$'),
              ),
            ],
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (text) => _emit(int.tryParse(text) ?? widget.min),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) {
                widget.onChanged(
                  parsed.clamp(widget.min, widget.max));
              }
            },
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => _emit(widget.value + 1),
        ),
      ],
    );
  }
}
