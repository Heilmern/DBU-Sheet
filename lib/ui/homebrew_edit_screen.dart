/// homebrew_edit_screen.dart
/// ---------------------------------------------------------------------------
/// The Homebrew MAKER. Lets a player author a custom entry: pick a category,
/// write the name / flavor / effect text, and add any number of automated
/// numeric effects via dropdowns.
///
/// The automation editor's dropdowns are driven directly by the app's real
/// automation vocabulary — `AffectedStat` (each with a `displayName`), the
/// magnitude kinds (`TraitMagnitudeKind`), tier scaling (`TierScaling`) and the
/// computable conditions (`TraitCondition`). Because the pickers iterate the
/// enum values, they stay current automatically: the day a new `AffectedStat`
/// or condition is added to the engine, it appears here with no extra work.
///
/// STRUCTURED CATEGORIES additionally get their own editor section, mirroring
/// what the matching official catalogue records (see `models/homebrew.dart`):
///   • Race — Racial Life Modifier, Attribute Score Increases (fixed +
///     choice slots), Racial Saving Throw(s), Racial Skill Ranks.
///   • Condition — Max Stacks, automated penalty per Stack (+ Tier scaling)
///     and the penalized stats.
///   • Transformation / Enhancement / Form — Awakening/Form kind, ToP
///     requirement, Racial Requirement, Prerequisites, Max Stacks / Grades
///     and the full per-Attribute AMB table (flat or ×(T)).
///   • Factor Trait — what it must replace (or any Secondary), Racial
///     Requirement, Prerequisites and Maximum Factor.
///
/// The screen produces the exact `RaceTraitAutomation` objects the calculator
/// consumes, so nothing is lost in translation when homebrew is later applied
/// to a live character sheet.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/accessories.dart';
import '../data/apparel.dart';
import '../data/aspects.dart';
import '../data/dbu_rules.dart';
import '../data/race_traits.dart';
import '../data/signature_modifiers.dart';
import '../data/talents.dart';
import '../data/transformations.dart';
import '../data/unique_abilities.dart';
import '../data/weapons.dart';
import '../models/homebrew.dart';
import 'widgets/sheet_widgets.dart';

/// Turns a camelCase enum name into readable words ("perPowerLevel" →
/// "Per Power Level"). Used so enums that lack a `displayName` still show a
/// sensible, auto-updating label in the pickers.
String _prettify(String enumName) {
  final buf = StringBuffer();
  for (var i = 0; i < enumName.length; i++) {
    final ch = enumName[i];
    if (i == 0) {
      buf.write(ch.toUpperCase());
    } else if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
      buf.write(' $ch');
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

String _tierScalingLabel(TierScaling t) => switch (t) {
      TierScaling.none => 'Flat (no Tier)',
      TierScaling.current => '× Tier of Power  (T)',
      TierScaling.base => '× Base Tier  (bT)',
    };

/// A mutable working copy of a single [RaceTraitAutomation] while editing.
class _AutomationDraft {
  _AutomationDraft({required this.key});

  /// Stable identity so text fields keep their state across list rebuilds.
  final int key;

  final Set<AffectedStat> stats = {};
  int coefficient = 1;
  TierScaling tierScaling = TierScaling.none;
  TraitMagnitudeKind kind = TraitMagnitudeKind.flat;
  DbuAttribute? attribute;
  int fractionDenominator = 1;
  bool roundUp = false;
  String resourceName = '';
  TraitCondition? condition;
  String conditionStateName = '';
  String conditionResourceName = '';
  int conditionAmount = 1;
  String conditionTransformationName = '';
  String conditionAspectName = '';
  bool perTransformationStack = false;
  bool perTransformationGrade = false;

  factory _AutomationDraft.from(int key, RaceTraitAutomation a) {
    final d = _AutomationDraft(key: key)
      ..stats.addAll(a.affectedStats)
      ..coefficient = a.coefficient
      ..tierScaling = a.tierScaling
      ..kind = a.kind
      ..attribute = a.attribute
      ..fractionDenominator = a.fractionDenominator
      ..roundUp = a.roundUp
      ..resourceName = a.resourceName ?? ''
      ..condition = a.condition
      ..conditionStateName = a.conditionStateName ?? ''
      ..conditionResourceName = a.conditionResourceName ?? ''
      ..conditionAmount = a.conditionAmount
      ..conditionTransformationName = a.conditionTransformationName ?? ''
      ..conditionAspectName = a.conditionAspectName ?? ''
      ..perTransformationStack = a.perTransformationStack
      ..perTransformationGrade = a.perTransformationGrade;
    return d;
  }

  String? _nz(String s) => s.trim().isEmpty ? null : s.trim();

  RaceTraitAutomation build() => RaceTraitAutomation(
        affectedStats: stats.toList(),
        coefficient: coefficient,
        tierScaling: tierScaling,
        kind: kind,
        attribute: kind == TraitMagnitudeKind.fractionOfAttribute
            ? attribute
            : null,
        fractionDenominator: fractionDenominator < 1 ? 1 : fractionDenominator,
        roundUp: roundUp,
        resourceName: _needsResourceName ? _nz(resourceName) : null,
        condition: condition,
        conditionStateName:
            _condNeedsStateName ? _nz(conditionStateName) : null,
        conditionResourceName:
            condition == TraitCondition.whileNamedResourceAtLeast
                ? _nz(conditionResourceName)
                : null,
        conditionAmount: conditionAmount < 1 ? 1 : conditionAmount,
        conditionTransformationName:
            condition == TraitCondition.whileNamedTransformationActive
                ? _nz(conditionTransformationName)
                : null,
        conditionAspectName:
            condition == TraitCondition.whileFormWithAspectActive
                ? _nz(conditionAspectName)
                : null,
        perTransformationStack: perTransformationStack,
        perTransformationGrade: perTransformationGrade,
      );

  bool get _needsResourceName =>
      kind == TraitMagnitudeKind.perNamedResourceStack ||
      kind == TraitMagnitudeKind.perNamedTransformationStack;

  bool get _condNeedsStateName =>
      condition == TraitCondition.whileNamedStateActive ||
      condition == TraitCondition.whileNamedConditionActive;
}

class HomebrewEditScreen extends StatefulWidget {
  const HomebrewEditScreen({
    super.key,
    required this.entry,
    required this.isNew,
  });

  final HomebrewEntry entry;
  final bool isNew;

  @override
  State<HomebrewEditScreen> createState() => _HomebrewEditScreenState();
}

class _HomebrewEditScreenState extends State<HomebrewEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _flavor;
  late final TextEditingController _effect;
  late HomebrewCategory _category;
  late final List<_AutomationDraft> _drafts;
  int _nextKey = 0;

  /// Keys + automation drafts for the Transformation payload's extra Traits
  /// (parallel to `_transformation.extraTraits`). Each Trait row owns its own
  /// draft list, rebuilt into `HomebrewTraitData.automations` on save.
  final List<int> _traitKeys = [];
  final Map<int, List<_AutomationDraft>> _traitDrafts = {};

  /// Same machinery for a homebrew Race's directly authored Racial Traits
  /// (parallel to `_race.traits`).
  final List<int> _raceTraitKeys = [];
  final Map<int, List<_AutomationDraft>> _raceTraitDrafts = {};

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _name = TextEditingController(text: e.name);
    _flavor = TextEditingController(text: e.flavor);
    _effect = TextEditingController(text: e.effectText);
    _category = e.category;
    _drafts = [
      for (final a in e.automations) _AutomationDraft.from(_nextKey++, a),
    ];
    for (final t in e.transformationData.extraTraits) {
      final key = _nextKey++;
      _traitKeys.add(key);
      _traitDrafts[key] = [
        for (final a in t.automations) _AutomationDraft.from(_nextKey++, a),
      ];
    }
    for (final t in e.raceData.traits) {
      final key = _nextKey++;
      _raceTraitKeys.add(key);
      _raceTraitDrafts[key] = [
        for (final a in t.automations) _AutomationDraft.from(_nextKey++, a),
      ];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _flavor.dispose();
    _effect.dispose();
    super.dispose();
  }

  /// True when the category typically lives inside the Transformation pipeline,
  /// where per-Stack (Z) / per-Grade (G) scaling is meaningful.
  bool get _isTransformationLike =>
      _category == HomebrewCategory.transformation ||
      _category == HomebrewCategory.enhancement ||
      _category == HomebrewCategory.form;

  void _save() {
    final e = widget.entry
      ..category = _category
      ..name = _name.text
      ..flavor = _flavor.text
      ..effectText = _effect.text;
    e.automations
      ..clear()
      ..addAll(_drafts.map((d) => d.build()));
    // The structured payloads are edited in place on the working copy; only
    // the per-Trait automation drafts need rebuilding into their payloads.
    for (var i = 0; i < _transformation.extraTraits.length; i++) {
      final drafts = _traitDrafts[_traitKeys[i]] ?? const [];
      _transformation.extraTraits[i].automations
        ..clear()
        ..addAll(drafts.map((d) => d.build()));
    }
    for (var i = 0; i < _race.traits.length; i++) {
      final drafts = _raceTraitDrafts[_raceTraitKeys[i]] ?? const [];
      _race.traits[i].automations
        ..clear()
        ..addAll(drafts.map((d) => d.build()));
    }
    Navigator.of(context).pop(e);
  }

  // ==========================================================================
  // Structured category editors (see the library doc)
  // ==========================================================================

  HomebrewRaceData get _race => widget.entry.raceData;
  HomebrewConditionData get _condition => widget.entry.conditionData;
  HomebrewTransformationData get _transformation =>
      widget.entry.transformationData;
  HomebrewFactorData get _factor => widget.entry.factorData;

  /// A small labelled integer field bound to a payload value.
  Widget _intField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    double width = 130,
    bool signed = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        key: ValueKey('hb-int-$label-${_category.name}'),
        initialValue: value.toString(),
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.numberWithOptions(signed: signed),
        onChanged: (v) => onChanged(int.tryParse(v.trim()) ?? 0),
      ),
    );
  }

  Widget _sectionHint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.bodySmall),
      );

  Widget _raceSection(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Race details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Everything an official Race records. A character picking this '
              'Race gets all of it automatically (Life per Power Level, '
              'Attribute Scores, Racial Saving Throw Bonus, Skill Ranks) — '
              'including the Racial Traits authored in the section below.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _intField(
                label: 'Racial Life Modifier',
                value: _race.racialLifeModifier,
                signed: true,
                width: 150,
                onChanged: (v) => _race.racialLifeModifier = v,
              ),
              _intField(
                label: 'Racial Skill Ranks',
                value: _race.skillRanks,
                width: 150,
                onChanged: (v) => _race.skillRanks = v,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Attribute Score Increases (always applied)',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final attr in DbuAttribute.values)
                _intField(
                  label: attr.abbreviation,
                  value: _race.fixedAttributeIncreases[attr] ?? 0,
                  signed: true,
                  width: 64,
                  onChanged: (v) {
                    if (v == 0) {
                      _race.fixedAttributeIncreases.remove(attr);
                    } else {
                      _race.fixedAttributeIncreases[attr] = v;
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Choice slots ("+N to an Attribute of your choice")',
              style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < _race.choiceAmounts.length; i++)
                InputChip(
                  label: Text('+${_race.choiceAmounts[i]} of choice'),
                  onDeleted: () =>
                      setState(() => _race.choiceAmounts.removeAt(i)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('+1 slot'),
                onPressed: () => setState(() => _race.choiceAmounts.add(1)),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('+2 slot'),
                onPressed: () => setState(() => _race.choiceAmounts.add(2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Racial Saving Throw Bonus', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in DbuSavingThrow.values)
                FilterChip(
                  label: Text(s.displayName),
                  selected: _race.savingThrows.contains(s),
                  onSelected: (on) => setState(() {
                    if (on) {
                      if (!_race.savingThrows.contains(s)) {
                        _race.savingThrows.add(s);
                      }
                    } else {
                      _race.savingThrows.remove(s);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _talentSection(BuildContext context) {
    final t = widget.entry.talentData;
    return SectionCard(
      title: 'Talent details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'This Talent joins the Talents catalogue picker (Information '
              'tab and Progression) under its Talent Category, beside the '
              'official Talents. Its text comes from the Flavor/Effect '
              'fields above; its automated effects from the Automated '
              'Effects section.'),
          DropdownButtonFormField<TalentCategory>(
            isExpanded: true,
            initialValue: t.category,
            decoration: const InputDecoration(
              labelText: 'Talent Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final c in TalentCategory.values)
                DropdownMenuItem(value: c, child: Text(c.displayName)),
            ],
            onChanged: (v) => setState(
                () => t.category = v ?? TalentCategory.miscellaneous),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-talent-prereq'),
            initialValue: t.prerequisitesText,
            decoration: const InputDecoration(
              labelText: 'Prerequisites',
              hintText: 'e.g. "Force Score 6+" — reference text, like the '
                  'catalogue\'s.',
            ),
            onChanged: (v) => t.prerequisitesText = v,
          ),
        ],
      ),
    );
  }

  Widget _raceTraitsSection(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Racial Traits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'The Race\'s own Racial Traits. A character of this Race gets '
              'them exactly like official ones — they show on the '
              'Information tab, can be swapped for Factor Traits, feed the '
              'combat reminders, and each can carry its own automated '
              'effects.'),
          for (var i = 0; i < _race.traits.length; i++)
            _raceTraitCard(context, theme, i),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _race.traits.add(HomebrewRaceTraitData());
              final key = _nextKey++;
              _raceTraitKeys.add(key);
              _raceTraitDrafts[key] = [];
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add Racial Trait'),
          ),
        ],
      ),
    );
  }

  Widget _raceTraitCard(BuildContext context, ThemeData theme, int index) {
    final trait = _race.traits[index];
    final key = _raceTraitKeys[index];
    final drafts = _raceTraitDrafts[key]!;
    return Card(
      key: ValueKey('hb-racetrait-$key'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Racial Trait ${index + 1}',
                    style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _race.traits.removeAt(index);
                    _raceTraitKeys.removeAt(index);
                    _raceTraitDrafts.remove(key);
                  }),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('hb-racetrait-name-$key'),
              initialValue: trait.name,
              decoration: const InputDecoration(labelText: 'Trait name'),
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => trait.name = v,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<RaceTraitTier>(
                    isExpanded: true,
                    initialValue: trait.tier,
                    decoration: const InputDecoration(
                      labelText: 'Tier',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final tier in RaceTraitTier.values)
                        DropdownMenuItem(
                            value: tier, child: Text(tier.displayName)),
                    ],
                    onChanged: (v) => setState(
                        () => trait.tier = v ?? RaceTraitTier.secondary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TraitCategory>(
                    isExpanded: true,
                    initialValue: trait.category,
                    decoration: const InputDecoration(
                      labelText: 'Body / Mind',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final cat in TraitCategory.values)
                        DropdownMenuItem(
                            value: cat, child: Text(cat.displayName)),
                    ],
                    onChanged: (v) => setState(
                        () => trait.category = v ?? TraitCategory.body),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('hb-racetrait-desc-$key'),
              initialValue: trait.description,
              decoration: const InputDecoration(
                labelText: 'Effect text',
                hintText: 'Verbatim flavour + numbered effects — (T)/(bT) '
                    'tokens are annotated live on the sheet.',
              ),
              minLines: 2,
              maxLines: 8,
              onChanged: (v) => trait.description = v,
            ),
            const SizedBox(height: 8),
            Text('Automated effects of this Trait',
                style: theme.textTheme.labelMedium),
            for (var i = 0; i < drafts.length; i++)
              _AutomationCard(
                key: ValueKey(drafts[i].key),
                draft: drafts[i],
                index: i,
                showTransformationScaling: false,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => drafts.removeAt(i)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => drafts.add(_AutomationDraft(key: _nextKey++))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add automated effect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionSection(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Condition details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Character tab\'s Conditions tracker. The penalty '
              'below is auto-applied per Stack to the chosen stats (like '
              'Blinded); leave the stats empty for a reference-only '
              'Condition whose Effect text is shown but not computed.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _intField(
                label: 'Max Stacks',
                value: _condition.maxStacks,
                width: 110,
                onChanged: (v) => _condition.maxStacks = v < 1 ? 1 : v,
              ),
              _intField(
                label: 'Penalty / Stack',
                value: _condition.penaltyPerStack,
                width: 120,
                onChanged: (v) => _condition.penaltyPerStack = v,
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<TierScaling>(
                  isExpanded: true,
                  initialValue: _condition.tierScaling,
                  decoration: const InputDecoration(labelText: 'Scaling'),
                  items: [
                    for (final t in TierScaling.values)
                      DropdownMenuItem(
                          value: t, child: Text(_tierScalingLabel(t))),
                  ],
                  onChanged: (v) => setState(
                      () => _condition.tierScaling = v ?? TierScaling.none),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Penalized stats', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final s in _condition.affectedStats)
                InputChip(
                  label: Text(s.displayName),
                  onDeleted: () =>
                      setState(() => _condition.affectedStats.remove(s)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Stat'),
                onPressed: () async {
                  final picked = await showDialog<Set<AffectedStat>>(
                    context: context,
                    builder: (_) => _StatPickerDialog(
                        selected: _condition.affectedStats.toSet()),
                  );
                  if (picked != null) {
                    setState(() {
                      _condition.affectedStats
                        ..clear()
                        ..addAll(picked);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transformationSection(BuildContext context) {
    final theme = Theme.of(context);
    final isAwakening = _category == HomebrewCategory.transformation;
    final isForm = _category == HomebrewCategory.form;
    final t = _transformation;
    return SectionCard(
      title: 'Transformation details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Resolved exactly like a catalogue Transformation: an '
              "Awakening's AMB is always-on (× Stacks) and counts toward the "
              'Awakening Limits; an Enhancement/Form applies while Active '
              '(a Form also gains the Ki Multiplier). The Effect text and '
              'Automated effects below become its Trait — always-on for an '
              'Awakening, while-active otherwise.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isAwakening)
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<AwakeningType>(
                    isExpanded: true,
                    initialValue: t.awakeningType,
                    decoration:
                        const InputDecoration(labelText: 'Awakening Type'),
                    items: [
                      for (final a in AwakeningType.values)
                        DropdownMenuItem(
                            value: a, child: Text(a.displayName)),
                    ],
                    onChanged: (v) => setState(
                        () => t.awakeningType = v ?? t.awakeningType),
                  ),
                ),
              if (isForm)
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<FormType>(
                    isExpanded: true,
                    initialValue: t.formType,
                    decoration: const InputDecoration(labelText: 'Form Type'),
                    items: [
                      for (final f in FormType.values)
                        DropdownMenuItem(
                            value: f, child: Text(f.displayName)),
                    ],
                    onChanged: (v) =>
                        setState(() => t.formType = v ?? t.formType),
                  ),
                ),
              _intField(
                label: 'ToP Requirement',
                value: t.tierOfPowerRequirement,
                width: 140,
                onChanged: (v) =>
                    t.tierOfPowerRequirement = v < 1 ? 1 : v,
              ),
              if (isAwakening)
                _intField(
                  label: 'Max Stacks',
                  value: t.maxStacks,
                  width: 110,
                  onChanged: (v) => t.maxStacks = v < 1 ? 1 : v,
                ),
              _intField(
                label: 'Grades (1 = none)',
                value: t.maxGrade,
                width: 140,
                onChanged: (v) => t.maxGrade = v < 1 ? 1 : v,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('hb-racial-req-${_category.name}'),
            initialValue: t.racialRequirement,
            decoration: const InputDecoration(
              labelText: 'Racial Requirement',
              hintText: "'Any' or an exact Race name",
            ),
            onChanged: (v) => t.racialRequirement = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('hb-prereq-${_category.name}'),
            initialValue: t.prerequisiteText,
            decoration: const InputDecoration(
              labelText: 'Prerequisite(s) (reference text)',
            ),
            minLines: 1,
            maxLines: 4,
            onChanged: (v) => t.prerequisiteText = v,
          ),
          const SizedBox(height: 16),
          Text('Aspects', style: theme.textTheme.labelMedium),
          Text(
            'The automated Aspects (Enhanced Save, Raging, Mindful, High '
            'Speed…) auto-apply exactly like on catalogue Transformations; '
            'the rest show as reference chips. Grades set above already add '
            'the Graded Aspect for you.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          _aspectChips(context),
          const SizedBox(height: 16),
          Text('Attribute Modifier Bonus table',
              style: theme.textTheme.labelMedium),
          Text(
            'Leave 0 for no bonus. Tick (T) for the site\'s "+N(T)" shape '
            '(scaled by current Tier of Power).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          for (final attr in DbuAttribute.values)
            Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                      '${attr.displayName} (${attr.abbreviation})',
                      style: theme.textTheme.bodyMedium),
                ),
                _intField(
                  label: 'Bonus',
                  value: t.amb[attr]?.coefficient ?? 0,
                  signed: true,
                  width: 90,
                  onChanged: (v) {
                    if (v == 0) {
                      t.amb.remove(attr);
                    } else {
                      (t.amb[attr] ??= HomebrewAmb()).coefficient = v;
                    }
                  },
                ),
                const SizedBox(width: 8),
                Checkbox(
                  value: t.amb[attr]?.tierScaled ?? false,
                  onChanged: (v) => setState(() {
                    (t.amb[attr] ??= HomebrewAmb()).tierScaled = v ?? false;
                  }),
                ),
                const Text('(T)'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _factorSection(BuildContext context) {
    final f = _factor;
    return SectionCard(
      title: 'Factor Trait details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Appears in the Information tab\'s "Swap for Factor" picker. By '
              'default it can replace any Secondary Racial Trait of the '
              "player's choice; name a specific Racial Trait below to force "
              'that swap instead (which may even be a Primary Trait). The '
              'Effect text and Automated effects become the swapped-in '
              "Trait's — it is a Racial Trait once applied."),
          TextFormField(
            key: const ValueKey('hb-factor-replaces'),
            initialValue: f.mustReplaceTraitName,
            decoration: const InputDecoration(
              labelText: 'Must replace Racial Trait (empty = any Secondary)',
              hintText: 'Exact Racial Trait name',
            ),
            onChanged: (v) => f.mustReplaceTraitName = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-factor-race'),
            initialValue: f.racialRequirement,
            decoration: const InputDecoration(
              labelText: 'Racial Requirement (empty = Any)',
              hintText: 'Exact Race name',
            ),
            onChanged: (v) => f.racialRequirement = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-factor-prereq'),
            initialValue: f.prerequisiteText,
            decoration: const InputDecoration(
              labelText: 'Prerequisite(s) (reference text)',
            ),
            minLines: 1,
            maxLines: 4,
            onChanged: (v) => f.prerequisiteText = v,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _intField(
              label: 'Maximum Factor',
              value: f.maxFactor,
              width: 140,
              onChanged: (v) => f.maxFactor = v < 1 ? 1 : v,
            ),
          ),
        ],
      ),
    );
  }

  /// A reusable AffectedStat chip row bound to a mutable stat list.
  Widget _statChipRow(BuildContext context, List<AffectedStat> stats) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in stats)
          InputChip(
            label: Text(s.displayName),
            onDeleted: () => setState(() => stats.remove(s)),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Stat'),
          onPressed: () async {
            final picked = await showDialog<Set<AffectedStat>>(
              context: context,
              builder: (_) => _StatPickerDialog(selected: stats.toSet()),
            );
            if (picked != null) {
              setState(() {
                stats
                  ..clear()
                  ..addAll(picked);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _stateSection(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.entry.stateData;
    return SectionCard(
      title: 'State details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Character tab\'s States tracker. Each Trait row '
              'unlocks at its Level and applies '
              '"amount × current Level × scaling" to the chosen stats '
              '(positive = buff, negative = debuff, like Raging/Undying). '
              'No rows = a reference-only State.'),
          Align(
            alignment: Alignment.centerLeft,
            child: _intField(
              label: 'Max Level',
              value: s.maxLevel,
              width: 110,
              onChanged: (v) => s.maxLevel = v < 1 ? 1 : v,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < s.traits.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Trait ${i + 1}',
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => s.traits.removeAt(i)),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _intField(
                          label: 'Unlocks at Level',
                          value: s.traits[i].level,
                          width: 130,
                          onChanged: (v) =>
                              s.traits[i].level = v < 1 ? 1 : v,
                        ),
                        _intField(
                          label: 'Amount / Level',
                          value: s.traits[i].coefficientPerLevel,
                          signed: true,
                          width: 130,
                          onChanged: (v) =>
                              s.traits[i].coefficientPerLevel = v,
                        ),
                        SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<TierScaling>(
                            isExpanded: true,
                            initialValue: s.traits[i].tierScaling,
                            decoration:
                                const InputDecoration(labelText: 'Scaling'),
                            items: [
                              for (final t in TierScaling.values)
                                DropdownMenuItem(
                                    value: t,
                                    child: Text(_tierScalingLabel(t))),
                            ],
                            onChanged: (v) => setState(() =>
                                s.traits[i].tierScaling =
                                    v ?? TierScaling.none),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _statChipRow(context, s.traits[i].affectedStats),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title:
                          const Text('Ignores Health Threshold Penalties'),
                      value: s.traits[i].ignoresHealthThresholdPenalties,
                      onChanged: (v) => setState(() => s.traits[i]
                          .ignoresHealthThresholdPenalties = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => s.traits.add(HomebrewStateTraitData())),
            icon: const Icon(Icons.add),
            label: const Text('Add State Trait'),
          ),
        ],
      ),
    );
  }

  /// Chip picker for the Transformation payload's Aspect labels.
  Widget _aspectChips(BuildContext context) {
    final t = _transformation;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < t.aspects.length; i++)
          InputChip(
            label: Text(t.aspects[i]),
            onDeleted: () => setState(() => t.aspects.removeAt(i)),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Aspect'),
          onPressed: () async {
            final label = await showDialog<String>(
              context: context,
              builder: (_) => const _AspectPickerDialog(),
            );
            if (label != null && label.trim().isNotEmpty) {
              setState(() => t.aspects.add(label.trim()));
            }
          },
        ),
      ],
    );
  }

  Widget _extraTraitsSection(BuildContext context) {
    final theme = Theme.of(context);
    final t = _transformation;
    final isAwakening = _category == HomebrewCategory.transformation;
    return SectionCard(
      title: 'Extra Traits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Traits beyond the main one (which comes from the Effect text '
              'above). A Stack requirement mirrors the site\'s "(2)"/"(3)" '
              'suffix — the Trait stays locked until the Awakening has that '
              'many Stacks. A Mastery Trait unlocks via the Transformation\'s '
              'recorded Mastery level. Each Trait can carry its own automated '
              'effects; its text updates live with the real (T)/Z/G values on '
              'the Transformations tab.'),
          for (var i = 0; i < t.extraTraits.length; i++)
            _extraTraitCard(context, theme, i, isAwakening),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              t.extraTraits.add(HomebrewTraitData());
              final key = _nextKey++;
              _traitKeys.add(key);
              _traitDrafts[key] = [];
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add Trait'),
          ),
        ],
      ),
    );
  }

  Widget _extraTraitCard(
      BuildContext context, ThemeData theme, int index, bool isAwakening) {
    final trait = _transformation.extraTraits[index];
    final key = _traitKeys[index];
    final drafts = _traitDrafts[key]!;
    return Card(
      key: ValueKey('hb-trait-$key'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Trait ${index + 1}', style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _transformation.extraTraits.removeAt(index);
                    _traitKeys.removeAt(index);
                    _traitDrafts.remove(key);
                  }),
                ),
              ],
            ),
            TextFormField(
              key: ValueKey('hb-trait-name-$key'),
              initialValue: trait.name,
              decoration: const InputDecoration(labelText: 'Trait name'),
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => trait.name = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('hb-trait-desc-$key'),
              initialValue: trait.description,
              decoration: const InputDecoration(
                labelText: 'Effect text',
                hintText: 'Verbatim effect — (T)/(bT)/Z/G tokens are '
                    'annotated live on the sheet.',
              ),
              minLines: 2,
              maxLines: 8,
              onChanged: (v) => trait.description = v,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (isAwakening && !trait.isMastery)
                  _intField(
                    label: 'Needs Stacks',
                    value: trait.minStacks,
                    width: 110,
                    onChanged: (v) => trait.minStacks = v < 1 ? 1 : v,
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: trait.isMastery,
                      onChanged: (v) =>
                          setState(() => trait.isMastery = v ?? false),
                    ),
                    const Text('Mastery Trait'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Automated effects of this Trait',
                style: theme.textTheme.labelMedium),
            for (var i = 0; i < drafts.length; i++)
              _AutomationCard(
                key: ValueKey(drafts[i].key),
                draft: drafts[i],
                index: i,
                showTransformationScaling: true,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => drafts.removeAt(i)),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => drafts.add(_AutomationDraft(key: _nextKey++))),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add automated effect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _apparelQualitySection(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.entry.apparelQualityData;
    return SectionCard(
      title: 'Apparel Quality details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Inventory tab\'s Quality picker for the ticked '
              'Categories. The automated fields below apply while the piece '
              'is worn (and not broken); anything else stays reference text.'),
          Text('Allowed Categories', style: theme.textTheme.labelMedium),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in ApparelCategory.values)
                FilterChip(
                  label: Text(c.displayName),
                  selected: a.categories.contains(c),
                  onSelected: (on) => setState(() {
                    if (on) {
                      a.categories.add(c);
                    } else {
                      a.categories.remove(c);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _intField(
                label: 'Min Slots',
                value: a.minSlots,
                width: 100,
                onChanged: (v) => a.minSlots = v < 1 ? 1 : v,
              ),
              _intField(
                label: 'Max Slots',
                value: a.maxSlots,
                width: 100,
                onChanged: (v) => a.maxSlots = v < 1 ? 1 : v,
              ),
              _intField(
                label: 'Apparel Bonus +N(bT)',
                value: a.apparelBonusPerBaseTier,
                signed: true,
                width: 160,
                onChanged: (v) => a.apparelBonusPerBaseTier = v,
              ),
              _intField(
                label: 'Break Value bonus',
                value: a.breakValueBonus,
                signed: true,
                width: 140,
                onChanged: (v) => a.breakValueBonus = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('hb-apq-prereq'),
            initialValue: a.prerequisites,
            decoration: const InputDecoration(
                labelText: 'Prerequisites (wearer, reference text)'),
            onChanged: (v) => a.prerequisites = v,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Unbreakable (Break Value can\'t be reduced)'),
            value: a.unbreakable,
            onChanged: (v) => setState(() => a.unbreakable = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Excluded from the Apparel Penalty'),
            value: a.excludedFromApparelPenalty,
            onChanged: (v) =>
                setState(() => a.excludedFromApparelPenalty = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Halves the Armor\'s Damage Reduction'),
            value: a.halvesArmorDamageReduction,
            onChanged: (v) =>
                setState(() => a.halvesArmorDamageReduction = v ?? false),
          ),
          const SizedBox(height: 4),
          Text('Automated stat effects (while worn)',
              style: theme.textTheme.labelMedium),
          for (var i = 0; i < a.statEffects.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Effect ${i + 1}',
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => a.statEffects.removeAt(i)),
                        ),
                      ],
                    ),
                    _statChipRow(context, a.statEffects[i].stats),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _intField(
                          label: 'Amount',
                          value: a.statEffects[i].coefficient,
                          signed: true,
                          width: 100,
                          onChanged: (v) =>
                              a.statEffects[i].coefficient = v,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              DropdownButtonFormField<ApparelEffectBasis>(
                            isExpanded: true,
                            initialValue: a.statEffects[i].basis,
                            decoration:
                                const InputDecoration(labelText: 'Basis'),
                            items: const [
                              DropdownMenuItem(
                                  value: ApparelEffectBasis.perBaseTier,
                                  child: Text('× Base Tier (bT)')),
                              DropdownMenuItem(
                                  value: ApparelEffectBasis.apparelBonus,
                                  child: Text('× Apparel Bonus')),
                              DropdownMenuItem(
                                  value: ApparelEffectBasis
                                      .halfApparelBonusRoundUp,
                                  child: Text('× ½ Apparel Bonus (up)')),
                            ],
                            onChanged: (v) => setState(() =>
                                a.statEffects[i].basis =
                                    v ?? ApparelEffectBasis.perBaseTier),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => a.statEffects.add(HomebrewApparelEffect())),
            icon: const Icon(Icons.add),
            label: const Text('Add stat effect'),
          ),
        ],
      ),
    );
  }

  Widget _weaponQualitySection(BuildContext context) {
    final theme = Theme.of(context);
    final w = widget.entry.weaponQualityData;
    return SectionCard(
      title: 'Weapon Quality details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Inventory tab\'s Weapon Quality picker for the '
              'ticked Types. Strike/Wound effects apply per-Attack while the '
              'Weapon is wielded (like Artisan/Super Heavy); the rest stays '
              'reference text.'),
          Text('Allowed Weapon Types', style: theme.textTheme.labelMedium),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in WeaponType.values)
                FilterChip(
                  label: Text(t.displayName),
                  selected: w.types.contains(t),
                  onSelected: (on) => setState(() {
                    if (on) {
                      w.types.add(t);
                    } else {
                      w.types.remove(t);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _intField(
                label: 'Min Slots',
                value: w.minSlots,
                width: 100,
                onChanged: (v) => w.minSlots = v < 1 ? 1 : v,
              ),
              _intField(
                label: 'Max Slots',
                value: w.maxSlots,
                width: 100,
                onChanged: (v) => w.maxSlots = v < 1 ? 1 : v,
              ),
              _intField(
                label: 'Life Points / PL',
                value: w.lifePointsPerLevel,
                signed: true,
                width: 130,
                onChanged: (v) => w.lifePointsPerLevel = v,
              ),
              _intField(
                label: 'Wielder DR +N(bT)',
                value: w.damageReductionPerBaseTier,
                signed: true,
                width: 150,
                onChanged: (v) => w.damageReductionPerBaseTier = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('hb-wq-prereq'),
            initialValue: w.prerequisites,
            decoration: const InputDecoration(
                labelText: 'Prerequisites (wielder, reference text)'),
            onChanged: (v) => w.prerequisites = v,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Life Points / PL are multiplied by Slots'),
            value: w.lifePointsPerLevelPerSlot,
            onChanged: (v) =>
                setState(() => w.lifePointsPerLevelPerSlot = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Unbreakable (Life Points can\'t be reduced)'),
            value: w.unbreakable,
            onChanged: (v) => setState(() => w.unbreakable = v ?? false),
          ),
          const SizedBox(height: 4),
          Text('Armed-Attack Strike/Wound effects',
              style: theme.textTheme.labelMedium),
          for (var i = 0; i < w.statEffects.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<WeaponEffectTarget>(
                        isExpanded: true,
                        initialValue: w.statEffects[i].target,
                        decoration:
                            const InputDecoration(labelText: 'Roll'),
                        items: const [
                          DropdownMenuItem(
                              value: WeaponEffectTarget.strike,
                              child: Text('Strike')),
                          DropdownMenuItem(
                              value: WeaponEffectTarget.wound,
                              child: Text('Wound')),
                        ],
                        onChanged: (v) => setState(() => w.statEffects[i]
                            .target = v ?? WeaponEffectTarget.wound),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _intField(
                      label: 'Amount',
                      value: w.statEffects[i].coefficient,
                      signed: true,
                      width: 90,
                      onChanged: (v) => w.statEffects[i].coefficient = v,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<WeaponEffectBasis>(
                        isExpanded: true,
                        initialValue: w.statEffects[i].basis,
                        decoration:
                            const InputDecoration(labelText: 'Basis'),
                        items: const [
                          DropdownMenuItem(
                              value: WeaponEffectBasis.perTier,
                              child: Text('× Tier (T)')),
                          DropdownMenuItem(
                              value: WeaponEffectBasis.perBaseTier,
                              child: Text('× Base Tier (bT)')),
                        ],
                        onChanged: (v) => setState(() => w.statEffects[i]
                            .basis = v ?? WeaponEffectBasis.perTier),
                      ),
                    ),
                    Column(
                      children: [
                        Checkbox(
                          value: w.statEffects[i].perSlot,
                          onChanged: (v) => setState(() =>
                              w.statEffects[i].perSlot = v ?? false),
                        ),
                        const Text('×Slots',
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => w.statEffects.removeAt(i)),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => w.statEffects.add(HomebrewWeaponEffect())),
            icon: const Icon(Icons.add),
            label: const Text('Add Strike/Wound effect'),
          ),
        ],
      ),
    );
  }

  Widget _accessorySection(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.entry.accessoryData;
    return SectionCard(
      title: 'Accessory details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Inventory tab\'s Accessories catalogue. The stat '
              'effects below apply unconditionally while Equipped (like '
              'Bunny Ears); situational parts stay reference text. Leave '
              'the Craft DC empty for a Special (ARC-granted) Accessory.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: TextFormField(
                  key: const ValueKey('hb-acc-craftdc'),
                  initialValue: a.craftDc,
                  decoration: const InputDecoration(
                    labelText: 'Craft DC Category',
                    hintText: 'e.g. Apprentice',
                  ),
                  onChanged: (v) => a.craftDc = v,
                ),
              ),
              _intField(
                label: 'DR +N(bT)',
                value: a.damageReductionPerBaseTier,
                signed: true,
                width: 120,
                onChanged: (v) => a.damageReductionPerBaseTier = v,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: a.isTech,
                    onChanged: (v) =>
                        setState(() => a.isTech = v ?? false),
                  ),
                  const Text('[Tech]'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Automated stat effects (while Equipped)',
              style: theme.textTheme.labelMedium),
          for (var i = 0; i < a.statEffects.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Effect ${i + 1}',
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => a.statEffects.removeAt(i)),
                        ),
                      ],
                    ),
                    _statChipRow(context, a.statEffects[i].stats),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _intField(
                          label: 'Amount',
                          value: a.statEffects[i].coefficient,
                          signed: true,
                          width: 100,
                          onChanged: (v) =>
                              a.statEffects[i].coefficient = v,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<
                              AccessoryEffectBasis>(
                            isExpanded: true,
                            initialValue: a.statEffects[i].basis,
                            decoration:
                                const InputDecoration(labelText: 'Basis'),
                            items: const [
                              DropdownMenuItem(
                                  value:
                                      AccessoryEffectBasis.perBaseTier,
                                  child: Text('× Base Tier (bT)')),
                              DropdownMenuItem(
                                  value: AccessoryEffectBasis.perTier,
                                  child: Text('× Tier (T)')),
                            ],
                            onChanged: (v) => setState(() =>
                                a.statEffects[i].basis =
                                    v ?? AccessoryEffectBasis.perBaseTier),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => setState(
                () => a.statEffects.add(HomebrewAccessoryEffect())),
            icon: const Icon(Icons.add),
            label: const Text('Add stat effect'),
          ),
        ],
      ),
    );
  }

  Widget _basicItemSection(BuildContext context) {
    final b = widget.entry.basicItemData;
    return SectionCard(
      title: 'Basic Item details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Inventory tab\'s Basic Items catalogue — a '
              'reference entry (Action-triggered, never automated, like '
              'Senzu Beans). Leave the Craft DC empty for a Special Basic '
              'Item.'),
          SizedBox(
            width: 220,
            child: TextFormField(
              key: const ValueKey('hb-bi-craftdc'),
              initialValue: b.craftDc,
              decoration: const InputDecoration(
                labelText: 'Craft DC Category',
                hintText: 'e.g. Apprentice',
              ),
              onChanged: (v) => b.craftDc = v,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in const ['Tech', 'Med', 'Food'])
                FilterChip(
                  label: Text(tag),
                  selected: b.tags.contains(tag),
                  onSelected: (on) => setState(() {
                    if (on) {
                      if (!b.tags.contains(tag)) b.tags.add(tag);
                    } else {
                      b.tags.remove(tag);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sigModifierSection(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.entry.sigModifierData;
    return SectionCard(
      title: 'Signature Advantage / Disadvantage details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Signatures tab\'s pickers. TP per rank is entered '
              'positive — an Advantage costs it, a Disadvantage refunds it '
              '(the sign is applied automatically). Strike/Wound/KP effects '
              'below scale by rank × Tier and show on the Technique card.'),
          Row(
            children: [
              const Text('Advantage'),
              Switch(
                value: m.isDisadvantage,
                onChanged: (v) => setState(() => m.isDisadvantage = v),
              ),
              const Text('Disadvantage'),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('hb-sig-tp'),
            initialValue: m.tpCostsPerRank.join(', '),
            decoration: const InputDecoration(
              labelText: 'TP per rank (comma-separated, e.g. "2, 4, 6")',
              hintText: 'One entry per rank',
            ),
            onChanged: (v) {
              final parsed = [
                for (final part in v.split(','))
                  if (int.tryParse(part.trim()) case final n?) n.abs(),
              ];
              m.tpCostsPerRank
                ..clear()
                ..addAll(parsed.isEmpty ? const [2] : parsed);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-sig-req'),
            initialValue: m.requirement,
            decoration: const InputDecoration(
                labelText: 'Requirement (reference text)'),
            onChanged: (v) => m.requirement = v,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Ultimate Signature Techniques only'),
            value: m.ultimateOnly,
            onChanged: (v) => setState(() => m.ultimateOnly = v ?? false),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _intField(
              label: 'KP Cost ±N(T)/rank',
              value: m.kpPerTierPerRank,
              signed: true,
              width: 160,
              onChanged: (v) => m.kpPerTierPerRank = v,
            ),
          ),
          const SizedBox(height: 8),
          Text('Per-rank Strike/Wound effects',
              style: theme.textTheme.labelMedium),
          for (var i = 0; i < m.statEffects.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SigEffectTarget>(
                        isExpanded: true,
                        initialValue: m.statEffects[i].target,
                        decoration:
                            const InputDecoration(labelText: 'Roll'),
                        items: const [
                          DropdownMenuItem(
                              value: SigEffectTarget.strike,
                              child: Text('Strike')),
                          DropdownMenuItem(
                              value: SigEffectTarget.wound,
                              child: Text('Wound')),
                        ],
                        onChanged: (v) => setState(() => m.statEffects[i]
                            .target = v ?? SigEffectTarget.wound),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _intField(
                      label: '±N / rank',
                      value: m.statEffects[i].coefficientPerRank,
                      signed: true,
                      width: 100,
                      onChanged: (v) =>
                          m.statEffects[i].coefficientPerRank = v,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<SigEffectBasis>(
                        isExpanded: true,
                        initialValue: m.statEffects[i].basis,
                        decoration:
                            const InputDecoration(labelText: 'Basis'),
                        items: const [
                          DropdownMenuItem(
                              value: SigEffectBasis.perTier,
                              child: Text('× Tier (T)')),
                          DropdownMenuItem(
                              value: SigEffectBasis.perBaseTier,
                              child: Text('× Base Tier (bT)')),
                        ],
                        onChanged: (v) => setState(() => m.statEffects[i]
                            .basis = v ?? SigEffectBasis.perTier),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => m.statEffects.removeAt(i)),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => m.statEffects.add(HomebrewSigEffect())),
            icon: const Icon(Icons.add),
            label: const Text('Add Strike/Wound effect'),
          ),
        ],
      ),
    );
  }

  Widget _uniqueAbilitySection(BuildContext context) {
    final theme = Theme.of(context);
    final u = widget.entry.uniqueAbilityData;
    return SectionCard(
      title: 'Unique Ability details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHint(
              context,
              'Joins the Unique Abilities tab\'s catalogue with its TP/KP '
              'cost math (Magic Master\'s discount included for Magical '
              'abilities). Advancements below are bought with TP exactly '
              'like catalogue ones; Restrictions stay reference text. Set '
              'the KP coefficient to 0 for a non-numeric cost (described '
              'in the text field instead).'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in UniqueAbilityType.values)
                FilterChip(
                  label: Text(t.displayName),
                  selected: u.types.contains(t),
                  onSelected: (on) => setState(() {
                    if (on) {
                      u.types.add(t);
                    } else if (u.types.length > 1) {
                      u.types.remove(t);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _intField(
                label: 'TP Cost',
                value: u.baseTpCost,
                width: 100,
                onChanged: (v) => u.baseTpCost = v < 0 ? 0 : v,
              ),
              _intField(
                label: 'KP Cost N (0 = text)',
                value: u.kpPerTier ?? 0,
                width: 150,
                onChanged: (v) => u.kpPerTier = v <= 0 ? null : v,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: u.kpUsesBaseTier,
                    onChanged: (v) =>
                        setState(() => u.kpUsesBaseTier = v ?? false),
                  ),
                  const Text('KP uses (bT)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('hb-ua-kptext'),
            initialValue: u.kpCostText,
            decoration: const InputDecoration(
              labelText: 'KP Cost text (when not N(T)/N(bT))',
              hintText: 'e.g. "Your entire Capacity"',
            ),
            onChanged: (v) => u.kpCostText = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-ua-prereq'),
            initialValue: u.prerequisites,
            decoration: const InputDecoration(
                labelText: 'Prerequisites (reference text)'),
            onChanged: (v) => u.prerequisites = v,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: TextFormField(
                  key: const ValueKey('hb-ua-maneuver'),
                  initialValue: u.maneuverType,
                  decoration: const InputDecoration(
                      labelText: 'Maneuver Type',
                      hintText: 'e.g. Support Maneuver'),
                  onChanged: (v) => u.maneuverType = v,
                ),
              ),
              SizedBox(
                width: 220,
                child: TextFormField(
                  key: const ValueKey('hb-ua-action'),
                  initialValue: u.actionCost,
                  decoration: const InputDecoration(
                      labelText: 'Action Cost',
                      hintText: 'e.g. 1 Action'),
                  onChanged: (v) => u.actionCost = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('hb-ua-passive'),
            initialValue: u.passiveBonus,
            decoration: const InputDecoration(
                labelText: 'Passive Bonus (reference text)'),
            minLines: 1,
            maxLines: 4,
            onChanged: (v) => u.passiveBonus = v,
          ),
          const SizedBox(height: 12),
          Text('Advancements', style: theme.textTheme.labelMedium),
          for (var i = 0; i < u.advancements.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('Advancement ${i + 1}',
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              setState(() => u.advancements.removeAt(i)),
                        ),
                      ],
                    ),
                    TextFormField(
                      key: ValueKey('hb-ua-adv-name-${identityHashCode(u.advancements[i])}'),
                      initialValue: u.advancements[i].name,
                      decoration:
                          const InputDecoration(labelText: 'Name'),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => u.advancements[i].name = v,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _intField(
                          label: 'TP Cost',
                          value: u.advancements[i].tpCost,
                          width: 100,
                          onChanged: (v) =>
                              u.advancements[i].tpCost = v < 0 ? 0 : v,
                        ),
                        _intField(
                          label: 'KP reduction N(T)',
                          value: u.advancements[i].kpReductionPerTier,
                          width: 150,
                          onChanged: (v) => u
                              .advancements[i].kpReductionPerTier =
                              v < 0 ? 0 : v,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: ValueKey('hb-ua-adv-prereq-${identityHashCode(u.advancements[i])}'),
                      initialValue: u.advancements[i].prerequisites,
                      decoration: const InputDecoration(
                          labelText: 'Prerequisites (reference text)'),
                      onChanged: (v) =>
                          u.advancements[i].prerequisites = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: ValueKey('hb-ua-adv-effect-${identityHashCode(u.advancements[i])}'),
                      initialValue: u.advancements[i].effect,
                      decoration:
                          const InputDecoration(labelText: 'Effect text'),
                      minLines: 2,
                      maxLines: 6,
                      onChanged: (v) => u.advancements[i].effect = v,
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => setState(
                () => u.advancements.add(HomebrewUaAdvancementData())),
            icon: const Icon(Icons.add),
            label: const Text('Add Advancement'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Homebrew' : 'Edit Homebrew'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'What are you homebrewing?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<HomebrewCategory>(
                      isExpanded: true,
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in HomebrewCategory.values)
                          DropdownMenuItem(
                            value: c,
                            child: Text(c.displayName),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _flavor,
                      decoration: const InputDecoration(
                        labelText: 'Flavor / lore (optional)',
                      ),
                      minLines: 2,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _effect,
                      decoration: const InputDecoration(
                        labelText: 'Effect text',
                        hintText:
                            'Write the full effect exactly as you want it '
                            'recorded.',
                      ),
                      minLines: 3,
                      maxLines: 12,
                    ),
                  ],
                ),
              ),
              if (_category == HomebrewCategory.talent)
                _talentSection(context),
              if (_category == HomebrewCategory.race) _raceSection(context),
              if (_category == HomebrewCategory.race)
                _raceTraitsSection(context),
              if (_category == HomebrewCategory.condition)
                _conditionSection(context),
              if (_category == HomebrewCategory.state) _stateSection(context),
              if (_isTransformationLike) _transformationSection(context),
              if (_isTransformationLike) _extraTraitsSection(context),
              if (_category == HomebrewCategory.factorTrait)
                _factorSection(context),
              if (_category == HomebrewCategory.apparelQuality)
                _apparelQualitySection(context),
              if (_category == HomebrewCategory.weaponQuality)
                _weaponQualitySection(context),
              if (_category == HomebrewCategory.accessory)
                _accessorySection(context),
              if (_category == HomebrewCategory.basicItem)
                _basicItemSection(context),
              if (_category == HomebrewCategory.signatureModifier)
                _sigModifierSection(context),
              if (_category == HomebrewCategory.uniqueAbility)
                _uniqueAbilitySection(context),
              SectionCard(
                title: 'Automated effects',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add an entry for each numeric effect you want the sheet '
                      'to apply automatically. Leave empty for a reference-only '
                      'entry (text above still shows).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _drafts.length; i++)
                      _AutomationCard(
                        key: ValueKey(_drafts[i].key),
                        draft: _drafts[i],
                        index: i,
                        showTransformationScaling: _isTransformationLike,
                        onChanged: () => setState(() {}),
                        onRemove: () =>
                            setState(() => _drafts.removeAt(i)),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _drafts.add(_AutomationDraft(key: _nextKey++)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add automated effect'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One editable automation entry.
class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    super.key,
    required this.draft,
    required this.index,
    required this.showTransformationScaling,
    required this.onChanged,
    required this.onRemove,
  });

  final _AutomationDraft draft;
  final int index;
  final bool showTransformationScaling;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Effect ${index + 1}',
                    style: theme.textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            // --- Affected stats (multi-select) ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Affects', style: theme.textTheme.labelMedium),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final s in draft.stats)
                  InputChip(
                    label: Text(s.displayName),
                    onDeleted: () {
                      draft.stats.remove(s);
                      onChanged();
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Stat'),
                  onPressed: () async {
                    final picked = await showDialog<Set<AffectedStat>>(
                      context: context,
                      builder: (_) => _StatPickerDialog(selected: draft.stats),
                    );
                    if (picked != null) {
                      draft.stats
                        ..clear()
                        ..addAll(picked);
                      onChanged();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // --- Magnitude ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    initialValue: draft.coefficient.toString(),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true),
                    onChanged: (v) {
                      draft.coefficient = int.tryParse(v.trim()) ?? 0;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TierScaling>(
                    isExpanded: true,
                    initialValue: draft.tierScaling,
                    decoration: const InputDecoration(labelText: 'Scaling'),
                    items: [
                      for (final t in TierScaling.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(_tierScalingLabel(t)),
                        ),
                    ],
                    onChanged: (v) {
                      draft.tierScaling = v ?? draft.tierScaling;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TraitMagnitudeKind>(
              initialValue: draft.kind,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Multiplied by'),
              items: [
                for (final k in TraitMagnitudeKind.values)
                  DropdownMenuItem(value: k, child: Text(_prettify(k.name))),
              ],
              onChanged: (v) {
                draft.kind = v ?? draft.kind;
                onChanged();
              },
            ),
            if (draft.kind == TraitMagnitudeKind.fractionOfAttribute) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DbuAttribute>(
                      isExpanded: true,
                      initialValue: draft.attribute,
                      decoration:
                          const InputDecoration(labelText: 'Attribute'),
                      items: [
                        for (final a in DbuAttribute.values)
                          DropdownMenuItem(
                              value: a, child: Text(a.displayName)),
                      ],
                      onChanged: (v) {
                        draft.attribute = v;
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      initialValue: draft.fractionDenominator.toString(),
                      decoration:
                          const InputDecoration(labelText: 'Divide by'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          draft.fractionDenominator = int.tryParse(v) ?? 1,
                    ),
                  ),
                ],
              ),
            ],
            if (draft._needsResourceName) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: draft.resourceName,
                decoration: InputDecoration(
                  labelText:
                      draft.kind == TraitMagnitudeKind.perNamedTransformationStack
                          ? 'Transformation name'
                          : 'Resource name',
                ),
                onChanged: (v) => draft.resourceName = v,
              ),
            ],
            const SizedBox(height: 12),
            // --- Condition gate ---
            DropdownButtonFormField<TraitCondition?>(
              initialValue: draft.condition,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'Only while… (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Always')),
                for (final c in TraitCondition.values)
                  DropdownMenuItem(value: c, child: Text(_prettify(c.name))),
              ],
              onChanged: (v) {
                draft.condition = v;
                onChanged();
              },
            ),
            ..._conditionFields(context),
            if (showTransformationScaling) ...[
              const Divider(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('× Transformation Stacks (Z)'),
                value: draft.perTransformationStack,
                onChanged: (v) {
                  draft.perTransformationStack = v ?? false;
                  onChanged();
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('× Transformation Grade (G)'),
                value: draft.perTransformationGrade,
                onChanged: (v) {
                  draft.perTransformationGrade = v ?? false;
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _conditionFields(BuildContext context) {
    final c = draft.condition;
    if (c == null) return const [];
    Widget text(String label, String value, void Function(String) set) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            onChanged: set,
          ),
        );
    switch (c) {
      case TraitCondition.whileNamedStateActive:
        return [text('State name', draft.conditionStateName,
            (v) => draft.conditionStateName = v)];
      case TraitCondition.whileNamedConditionActive:
        return [text('Condition name', draft.conditionStateName,
            (v) => draft.conditionStateName = v)];
      case TraitCondition.whileNamedResourceAtLeast:
        return [
          text('Resource name', draft.conditionResourceName,
              (v) => draft.conditionResourceName = v),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 140,
              child: TextFormField(
                initialValue: draft.conditionAmount.toString(),
                decoration: const InputDecoration(labelText: 'At least'),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    draft.conditionAmount = int.tryParse(v) ?? 1,
              ),
            ),
          ),
        ];
      case TraitCondition.whileNamedTransformationActive:
        return [text('Transformation name', draft.conditionTransformationName,
            (v) => draft.conditionTransformationName = v)];
      case TraitCondition.whileFormWithAspectActive:
        return [text('Aspect name', draft.conditionAspectName,
            (v) => draft.conditionAspectName = v)];
      default:
        return const [];
    }
  }
}

/// Picks one Aspect from the catalogue (`kDbuAspects`), with an optional
/// Level/parameter that becomes the bracketed part of the label — exactly
/// the shape `resolveAspect` parses (e.g. "Enhanced Save (Corporeal)",
/// "Graded (3)"). Returns the finished label string.
class _AspectPickerDialog extends StatefulWidget {
  const _AspectPickerDialog();

  @override
  State<_AspectPickerDialog> createState() => _AspectPickerDialogState();
}

class _AspectPickerDialogState extends State<_AspectPickerDialog> {
  AspectDef? _aspect;
  String _parameter = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Add Aspect'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<AspectDef>(
              initialValue: _aspect,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Aspect'),
              items: [
                for (final a in kDbuAspects)
                  DropdownMenuItem(
                    value: a,
                    child: Text(
                      '${a.name}'
                      '${a.polarity == AspectPolarity.negative ? '  (Negative)' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _aspect = v),
            ),
            if (_aspect != null) ...[
              const SizedBox(height: 8),
              Text(_aspect!.summary, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  labelText:
                      _aspect!.parameterLabel ?? 'Level / parameter (optional)',
                  hintText: _aspect!.hasLevels
                      ? 'e.g. 2 — becomes "${_aspect!.name} (2)"'
                      : 'left empty = plain "${_aspect!.name}"',
                ),
                onChanged: (v) => _parameter = v,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _aspect == null
              ? null
              : () => Navigator.pop(
                    context,
                    _parameter.trim().isEmpty
                        ? _aspect!.name
                        : '${_aspect!.name} (${_parameter.trim()})',
                  ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// A searchable multi-select over every [AffectedStat].
class _StatPickerDialog extends StatefulWidget {
  const _StatPickerDialog({required this.selected});

  final Set<AffectedStat> selected;

  @override
  State<_StatPickerDialog> createState() => _StatPickerDialogState();
}

class _StatPickerDialogState extends State<_StatPickerDialog> {
  late final Set<AffectedStat> _chosen = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final matches = [
      for (final s in AffectedStat.values)
        if (q.isEmpty || s.displayName.toLowerCase().contains(q)) s,
    ];
    return AlertDialog(
      title: const Text('Choose stats'),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search stats…',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (_, i) {
                  final s = matches[i];
                  final on = _chosen.contains(s);
                  return CheckboxListTile(
                    dense: true,
                    value: on,
                    title: Text(s.displayName),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _chosen.add(s);
                      } else {
                        _chosen.remove(s);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _chosen),
          child: Text('Use ${_chosen.length}'),
        ),
      ],
    );
  }
}
