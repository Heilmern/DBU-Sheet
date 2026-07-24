/// transformations_screen.dart
/// ---------------------------------------------------------------------------
/// The TRANSFORMATIONS TAB — a companion to the Character/Information/
/// Progression tabs, for managing the character's Transformations
/// (Awakenings, Enhancements, Alternate Forms — see `data/transformations.dart`).
///
/// Stateless, same `character`/`stats`/`onUpdate` contract as `InformationTab`:
/// the player adds Transformations from the catalogue, sets their state
/// (Awakening Stacks, Enhancement/Form Active toggle + Grade + Mastery, Trait
/// Options), and the calculator automates the Attribute Modifier Bonus and Ki
/// Multiplier. Everything else (verbatim Trait text, Aspects, Grade tables)
/// is shown for the player to apply. Each card also offers a per-attribute
/// "Customise attribute" editor (`TransformationSelection.customAmb`) so a
/// player can pick which Attribute(s) a bonus lands on and enter its value —
/// for Awakenings whose bonus is "to an Attribute of your choice" and for the
/// Grade-set (`*`) tables the app can't auto-derive.
///
///   1. Awakenings   (Lesser/Greater/Super; always-on; Stacks; Limit chip)
///   2. Enhancements (Standard + Transcendent; Active toggle, Grade, Mastery)
///   3. Forms        (Alternate / Evolved Stage / Legendary; Active, Mastery)
/// Enhancements and Forms mirror the Transformation Catalog's separate menus:
/// the add-button is a popup that opens a filtered picker per sub-catalogue,
/// and owned entries are grouped under the matching sub-headers.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/aspects.dart';
import '../data/awakenings.dart';
import '../data/beast_traits.dart';
import '../data/dbu_rules.dart';
import '../data/enhancements.dart';
import '../data/forms.dart';
import '../data/greater_awakenings.dart';
import '../data/homebrew_registry.dart';
import '../data/super_awakenings.dart';
import '../data/race_traits.dart';
import '../data/transformations.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import '../services/rule_text.dart';
import 'widgets/sheet_widgets.dart';

class TransformationsTab extends StatelessWidget {
  const TransformationsTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  final Character character;
  final DerivedCharacterStats stats;
  final void Function(VoidCallback mutate) onUpdate;

  Character get _c => character;
  void _update(VoidCallback mutate) => onUpdate(mutate);

  /// Whether this transformation's Racial Requirement admits the character.
  bool _eligible(TransformationDef def) =>
      def.racialRequirement == 'Any' || def.racialRequirement == _c.race;

  @override
  Widget build(BuildContext context) {
    // Responsive, in three tiers under one shared scroll view:
    //   • narrow (<1000): a single stacked column;
    //   • medium (1000–1399): two columns — Stress + Awakenings on the left,
    //     Enhancements + Forms on the right;
    //   • wide (≥1400): three columns — Stress + Awakenings, then Enhancements,
    //     then Forms in its own third column (Forms are the densest section, so
    //     they get the full-height slot to themselves).
    Widget column(List<Widget> children) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...children, const SizedBox(height: 24)],
          ),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 1000) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildStressBonus(context),
                  _buildAwakenings(context),
                  _buildEnhancements(context),
                  _buildForms(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }

        final threeColumns = width >= 1400;
        return Align(
          // Top-align so the columns start at the top of the tab rather than
          // floating in the vertical centre when their content is short.
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: threeColumns ? 1900 : 1500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: threeColumns
                    ? [
                        column([
                          _buildStressBonus(context),
                          _buildAwakenings(context),
                        ]),
                        column([_buildEnhancements(context)]),
                        column([_buildForms(context)]),
                      ]
                    : [
                        column([
                          _buildStressBonus(context),
                          _buildAwakenings(context),
                        ]),
                        column([
                          _buildEnhancements(context),
                          _buildForms(context),
                        ]),
                      ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 0. STRESS TEST
  // ==========================================================================
  Widget _buildStressBonus(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Stress Test',
      icon: Icons.bolt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'To enter or hold a Transformation, roll a Stress Test (1d10+1 + '
            'Stress Bonus) against the Transformation\'s Stress Test '
            'Requirement. Stress Bonus = Power Level + Determination (Personality '
            'Score ≥4 → +1, ≥8 → +2), plus Trait/Buff bonuses.',
            style:
                theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Stress Bonus',
                value: '${stats.stressBonus}',
                emphasize: true,
                tooltip: 'Added to your 1d10+1 Stress Test roll',
              ),
              DerivedStat(
                label: 'Stress Test',
                // The roll is 1d10 + 1 + Stress Bonus — shown with the flat
                // parts merged (e.g. Bonus 1 → "1d10+2").
                value: '1d10+${1 + stats.stressBonus}',
                tooltip: 'The full roll for a Stress Test (1d10 + 1 + '
                    'Stress Bonus)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 1. AWAKENINGS
  // ==========================================================================
  Widget _buildAwakenings(BuildContext context) {
    final theme = Theme.of(context);
    final limits = CharacterCalculator.awakeningLimits(_c);
    final lesserCount =
        CharacterCalculator.awakeningCount(_c, AwakeningType.lesser);
    final greaterCount =
        CharacterCalculator.awakeningCount(_c, AwakeningType.greater);
    final superCount =
        CharacterCalculator.awakeningCount(_c, AwakeningType.superAwakening);

    // Owned Awakenings resolved against all three catalogues, in tier order.
    final owned = [
      for (final s in _c.transformations)
        if (_awakeningDef(s.name) case final def?) (s, def),
    ]..sort((a, b) => a.$2.awakeningType!.index
        .compareTo(b.$2.awakeningType!.index));

    Chip limitChip(String label, int count, int? limit) => Chip(
          label: Text(limit == null ? '$label $count' : '$label $count / $limit'),
          visualDensity: VisualDensity.compact,
          backgroundColor: (limit != null && count > limit)
              ? theme.colorScheme.errorContainer
              : null,
        );

    return SectionCard(
      title: 'Awakenings',
      icon: Icons.auto_awesome,
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          limitChip('Lesser', lesserCount, limits.lesser),
          limitChip('Greater', greaterCount, limits.greater),
          limitChip('Super', superCount, kMaxSuperAwakenings),
          PopupMenuButton<int>(
            tooltip: 'Add Awakening',
            icon: const Icon(Icons.add_circle_outline),
            onSelected: (v) {
              bool ofType(TransformationDef d, AwakeningType t) =>
                  d.type == TransformationType.awakening &&
                  d.awakeningType == t;
              switch (v) {
                case 0:
                  _addFrom(
                      context,
                      [
                        ...kDbuLesserAwakenings,
                        ..._homebrewCatalogue(
                            (d) => ofType(d, AwakeningType.lesser)),
                      ],
                      'Pick a Lesser Awakening');
                case 1:
                  _addFrom(
                      context,
                      [
                        ...kDbuGreaterAwakenings,
                        ..._homebrewCatalogue(
                            (d) => ofType(d, AwakeningType.greater)),
                      ],
                      'Pick a Greater Awakening');
                default:
                  _addFrom(
                      context,
                      [
                        ...kDbuSuperAwakenings,
                        ..._homebrewCatalogue(
                            (d) => ofType(d, AwakeningType.superAwakening)),
                      ],
                      'Pick a Super Awakening');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('Add Lesser Awakening')),
              PopupMenuItem(value: 1, child: Text('Add Greater Awakening')),
              PopupMenuItem(value: 2, child: Text('Add Super Awakening')),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Awakenings are permanent — always active. Their Attribute '
              'Modifier Bonus (× Stacks) applies at all times '
              '. A Super Awakening also carries a '
              'Grand Awakening (activated via the Full Awakening Maneuver); '
              'you may possess only one Super Awakening.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (owned.isEmpty)
            const Text('No Awakenings gained.')
          else
            for (final (sel, def) in owned)
              _transformationCard(context, sel, def),
        ],
      ),
    );
  }

  /// Resolves an Awakening name across the Lesser/Greater/Super catalogues,
  /// then homebrew Awakenings (official wins a name clash).
  TransformationDef? _awakeningDef(String name) =>
      lesserAwakeningByName(name) ??
      greaterAwakeningByName(name) ??
      superAwakeningByName(name) ??
      _homebrewDef(name, (d) => d.type == TransformationType.awakening);

  /// The homebrew Transformation of [name] matching [test], or null.
  TransformationDef? _homebrewDef(
      String name, bool Function(TransformationDef) test) {
    final def = HomebrewRegistry.transformationDefByName(name);
    return def != null && test(def) ? def : null;
  }

  /// Homebrew defs of a kind, for appending to an add-picker's catalogue.
  List<TransformationDef> _homebrewCatalogue(
          bool Function(TransformationDef) test) =>
      HomebrewRegistry.transformationDefs(test);

  // ==========================================================================
  // 2. ENHANCEMENTS
  // ==========================================================================
  /// Resolves an Enhancement name across the catalogue, then homebrew.
  TransformationDef? _enhancementDef(String name) =>
      enhancementByName(name) ??
      _homebrewDef(name, (d) => d.type == TransformationType.enhancement);

  Widget _buildEnhancements(BuildContext context) {
    final theme = Theme.of(context);
    final owned = _c.transformations
        .where((s) => _enhancementDef(s.name) != null)
        .map((s) => (s, _enhancementDef(s.name)!))
        .toList();

    Widget group(String label, bool Function(TransformationDef) test) {
      final rows = owned.where((e) => test(e.$2)).toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final (sel, def) in rows) _transformationCard(context, sel, def),
        ],
      );
    }

    return SectionCard(
      title: 'Enhancements',
      icon: Icons.flash_on_outlined,
      trailing: PopupMenuButton<int>(
        tooltip: 'Add Enhancement',
        icon: const Icon(Icons.add_circle_outline),
        onSelected: (v) => switch (v) {
          0 => _addFrom(
              context,
              [
                ...kDbuEnhancements.where((d) => !d.isTranscendent),
                ..._homebrewCatalogue((d) =>
                    d.type == TransformationType.enhancement &&
                    !d.isTranscendent),
              ],
              'Pick an Enhancement'),
          _ => _addFrom(
              context,
              kDbuEnhancements.where((d) => d.isTranscendent).toList(),
              'Pick a Transcendent Enhancement'),
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 0, child: Text('Add Standard Enhancement')),
          PopupMenuItem(value: 1, child: Text('Add Transcendent Enhancement')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Enter one Enhancement at a time via the Transformation '
              "Maneuver. Toggle 'Active' to apply its Attribute Modifier "
              'Bonus. A Transcended Enhancement counts as a Form for '
              'Transformation Stacking (so it cannot be used with a Form).',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (owned.isEmpty)
            const Text('No Enhancements gained.')
          else ...[
            group('Enhancements', (d) => !d.isTranscendent),
            group('Transcendent Enhancements', (d) => d.isTranscendent),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. FORMS — Alternate Forms / Evolved Stages / Legendary Forms
  //
  // The Transformation Catalog splits Forms across three menus; we mirror that
  // here. A Form's bucket: Evolved Stage first (`def.isEvolvedStage`), then by
  // `formType` (Legendary vs Alternate). Null Stages stay in their formType
  // bucket. The add-button is a 3-way popup, one filtered picker each.
  // ==========================================================================
  // The top-level "Add Form" popup offers only base Forms — Alternate and
  // Legendary. Evolved Stages are NOT added here; they're added onto a specific
  // owned Form via that Form's "Add Evolved Stage" button (see `_buildForms`).
  static const _formCatalogues =
      <(String, String, bool Function(TransformationDef))>[
    ('Alternate Forms', 'Pick an Alternate Form', _isAlternateForm),
    ('Legendary Forms', 'Pick a Legendary Form', _isLegendaryForm),
  ];

  static bool _isAlternateForm(TransformationDef d) =>
      !d.isEvolvedStage && d.formType == FormType.alternate;
  static bool _isLegendaryForm(TransformationDef d) =>
      !d.isEvolvedStage && d.formType == FormType.legendary;

  /// Resolves a Form name across the catalogue, then homebrew.
  TransformationDef? _formDef(String name) =>
      alternateFormByName(name) ??
      _homebrewDef(name, (d) => d.type == TransformationType.form);

  /// Whether Evolved Stage [stage] can be applied onto base Form [form]: a
  /// UNIQUE Evolved Stage must name [form] as its Original Form; a GENERIC
  /// Evolved Stage applies to any Form (its finer prerequisites — Race,
  /// Talents, Aspects, Mastery — stay as reference text for the player to
  /// confirm), so it's offered on every Form.
  bool _evolvedStageAppliesTo(
      TransformationDef stage, TransformationDef form) {
    final original = stage.evolvedStageOriginalForm;
    return original == null || original == form.name;
  }

  /// Opens the Evolved-Stage picker filtered to those that apply to [form],
  /// and attaches the chosen Stage to it (`TransformationSelection.parentForm`).
  Future<void> _addEvolvedStage(
      BuildContext context, TransformationDef form) async {
    // An Evolved Stage may be attached once PER Form — so exclude the ones
    // already on THIS Form, but a Generic Stage can still be applied to a
    // different Form separately.
    final attachedHere = {
      for (final s in _c.transformations)
        if (s.parentForm == form.name) s.name,
    };
    bool available(TransformationDef d) =>
        d.isEvolvedStage &&
        _evolvedStageAppliesTo(d, form) &&
        !attachedHere.contains(d.name);
    final catalogue = [
      ...kDbuAlternateForms.where(available),
      ..._homebrewCatalogue(
          (d) => d.type == TransformationType.form && available(d)),
    ];
    final chosen = await showDialog<TransformationDef>(
      context: context,
      builder: (dialogContext) => _TransformationPickerDialog(
        catalogue: catalogue.where(_eligible).toList(),
        title: 'Add Evolved Stage to ${form.name}',
      ),
    );
    if (chosen == null) return;
    // Once per Form (the same Stage may still live on another Form).
    if (_c.transformations
        .any((s) => s.name == chosen.name && s.parentForm == form.name)) {
      return;
    }
    _update(() => _c.transformations.add(TransformationSelection(
          name: chosen.name,
          parentForm: form.name,
          stacks: 1,
        )));
  }

  Widget _buildForms(BuildContext context) {
    final theme = Theme.of(context);
    final owned = _c.transformations
        .where((s) => _formDef(s.name) != null)
        .map((s) => (s, _formDef(s.name)!))
        .toList();

    // The base (non-Evolved) Forms actually owned — the valid parents.
    final ownedBaseNames = {
      for (final (_, def) in owned)
        if (!def.isEvolvedStage) def.name,
    };

    // Evolved Stages attached to a given base Form.
    List<(TransformationSelection, TransformationDef)> childrenOf(String name) =>
        owned
            .where((e) => e.$2.isEvolvedStage && e.$1.parentForm == name)
            .toList();

    // A base Form, then its attached Evolved Stages (indented), then the
    // "Add Evolved Stage" button. Forms render with `readable: true` — larger
    // text and a clearer outline, since they carry the densest rules text.
    Widget baseForm(TransformationSelection sel, TransformationDef def) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _readableFormCard(context, sel, def),
          for (final (childSel, childDef) in childrenOf(def.name))
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _readableFormCard(context, childSel, childDef),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Evolved Stage'),
                onPressed: () => _addEvolvedStage(context, def),
              ),
            ),
          ),
        ],
      );
    }

    Widget group(String label, bool Function(TransformationDef) test) {
      final rows = owned.where((e) => test(e.$2)).toList();
      if (rows.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          for (final (sel, def) in rows) baseForm(sel, def),
        ],
      );
    }

    // Evolved Stages whose parent Form isn't owned (added before this version,
    // or after their base Form was removed) — surfaced in a fallback group so
    // they're never silently lost.
    final orphans = owned
        .where((e) =>
            e.$2.isEvolvedStage &&
            (e.$1.parentForm.isEmpty ||
                !ownedBaseNames.contains(e.$1.parentForm)))
        .toList();

    return SectionCard(
      title: 'Forms',
      icon: Icons.change_circle_outlined,
      trailing: PopupMenuButton<int>(
        tooltip: 'Add Form',
        icon: const Icon(Icons.add_circle_outline),
        onSelected: (v) => _addFrom(
          context,
          [
            ...kDbuAlternateForms.where(_formCatalogues[v].$3),
            ..._homebrewCatalogue((d) =>
                d.type == TransformationType.form && _formCatalogues[v].$3(d)),
          ],
          _formCatalogues[v].$2,
        ),
        itemBuilder: (_) => [
          for (var i = 0; i < _formCatalogues.length; i++)
            PopupMenuItem(value: i, child: Text('Add ${_formCatalogues[i].$1}')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Enter one Form at a time via the Transformation Maneuver. An '
              'active Form applies its Attribute Modifier Bonus AND the Ki '
              'Multiplier (double Max Ki, +1/2 Max Capacity) — except a Null '
              'Stage (Stage 0), which counts as your Normal State. Add an '
              'Evolved Stage onto the Form it evolves using the button under '
              "that Form; an Evolved Stage also adds its Original Form's AMB "
              'and Aspects (shown in its prerequisite text). Toggle a Stage '
              'Active to enter it.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (owned.isEmpty)
            const Text('No Forms gained.')
          else ...[
            group('Alternate Forms', _isAlternateForm),
            group('Legendary Forms', _isLegendaryForm),
            if (orphans.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text('Other Evolved Stages',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              for (final (sel, def) in orphans)
                _readableFormCard(context, sel, def),
            ],
          ],
        ],
      ),
    );
  }

  /// A Form card rendered for readability: an ambient [Theme] override
  /// (resolved by the [Builder] BELOW it, so every descendant — Traits,
  /// Aspects, automation lines — scales up without per-widget edits) enlarges
  /// the dense verbatim text, and `readable: true` gives the card a clearer
  /// outline and more separation from its neighbours.
  Widget _readableFormCard(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    return Theme(
      data: _readableTheme(context),
      child: Builder(
        builder: (ctx) => _transformationCard(ctx, sel, def, readable: true),
      ),
    );
  }

  ThemeData _readableTheme(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    TextStyle? grow(TextStyle? s, double delta) =>
        s?.copyWith(fontSize: (s.fontSize ?? 14) + delta, height: 1.35);
    return theme.copyWith(
      textTheme: tt.copyWith(
        bodySmall: grow(tt.bodySmall, 2),
        bodyMedium: grow(tt.bodyMedium, 1),
        labelSmall: grow(tt.labelSmall, 1.5),
        labelLarge: grow(tt.labelLarge, 1),
      ),
    );
  }

  // ==========================================================================
  // Shared: add-from-catalogue + one owned-transformation card
  // ==========================================================================
  Future<void> _addFrom(
    BuildContext context,
    List<TransformationDef> catalogue,
    String title,
  ) async {
    final chosen = await showDialog<TransformationDef>(
      context: context,
      builder: (dialogContext) => _TransformationPickerDialog(
        catalogue: catalogue.where(_eligible).toList(),
        title: title,
      ),
    );
    if (chosen == null) return;
    if (_c.transformations.any((s) => s.name == chosen.name)) return;
    _update(() => _c.transformations.add(TransformationSelection(
          name: chosen.name,
          stacks: 1,
        )));
  }

  Widget _transformationCard(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def, {
    bool readable = false,
  }) {
    final theme = Theme.of(context);
    final ambText = _ambText(def);

    return Card(
      margin: EdgeInsets.symmetric(vertical: readable ? 8 : 4),
      elevation: readable ? 2 : null,
      shape: readable
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(readable ? 14 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + metadata chips + delete.
            Row(
              children: [
                Expanded(
                  child: Text(
                    def.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _metaChip(context, def),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  // Removing a base Form also removes any Evolved Stages
                  // attached to it, so they don't linger as orphans.
                  onPressed: () => _update(() =>
                      _c.transformations.removeWhere((s) =>
                          identical(s, sel) ||
                          (sel.name.isNotEmpty &&
                              s.parentForm == sel.name))),
                ),
              ],
            ),
            // Requirement line.
            Text(
              'Race: ${def.racialRequirement}  ·  ToP '
              '${def.tierOfPowerRequirement}+'
              '${def.stressTestRequirement != null ? '  ·  Stress ${def.stressTestRequirement}' : ''}'
              '${def.transformationLine != null ? '  ·  ${def.transformationLine} Stage ${def.stage}' : ''}',
              style: theme.textTheme.labelSmall,
            ),
            if (def.prerequisiteText.trim().isNotEmpty &&
                def.prerequisiteText != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Prerequisite: ${def.prerequisiteText}',
                    style: theme.textTheme.labelSmall),
              ),

            // --- State controls ---
            const SizedBox(height: 8),
            _stateControls(context, sel, def),

            // --- Aspects (catalogue + player-added) ---
            if (def.aspects.isNotEmpty || sel.customAspects.isNotEmpty)
              _aspectsBlock(context, sel, def),

            // --- Attribute Modifier Bonus (summary) ---
            const SizedBox(height: 8),
            Text(
              'Attribute Modifier Bonus: $ambText',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),

            // --- Customise (Attributes & Aspects) ---
            _customisePanel(context, sel, def),

            // --- Traits (situational; applied while this Form/Enhancement
            //     is active) ---
            const SizedBox(height: 6),
            for (final trait in def.situationalTraits)
              _traitBlock(context, sel, def, trait),

            // --- Legendary Trait (Legendary Forms — possessed at ALL times
            //     after gaining access, even outside this Form) ---
            if (def.legendaryTrait != null)
              _labelledTrait(
                context,
                'Legendary Trait — always active (even outside this Form)',
                def.legendaryTrait!,
                sel: sel,
                def: def,
              ),

            // --- Exceed Trait (active while in the Exceed State) ---
            if (def.exceedTrait != null)
              _labelledTrait(
                context,
                'Exceed Trait — while in the Exceed State',
                def.exceedTrait!,
                sel: sel,
                def: def,
                inEffect: sel.active,
              ),

            // --- Burst Limit (Enhancements) ---
            if (def.burstLimit != null)
              _labelledTrait(context, 'Burst Limit', def.burstLimit!),

            // --- Transcendent Trait (Enhancements with the Transcendent
            //     Aspect, once Fully Mastered + 1 more Mastery) ---
            if (def.transcendentTrait != null)
              _labelledTrait(
                context,
                'Transcendent Trait — while Transcended (Fully Mastered + 1)',
                def.transcendentTrait!,
                sel: sel,
                def: def,
                inEffect: sel.active && sel.transcended,
                toggle: _traitToggle(
                  context,
                  'Transcended',
                  sel.transcended,
                  (v) => _update(() => sel.transcended = v),
                ),
              ),

            // --- Unlimited Trait (Enhancement Powers) ---
            if (def.unlimitedTrait != null)
              _labelledTrait(context, 'Unlimited Trait', def.unlimitedTrait!),

            // --- Mastery ---
            if (def.canBeMastered) _masteryBlock(context, sel, def),

            // --- Grand Awakening (Super Awakenings) ---
            if (def.grandAwakening != null)
              _labelledTrait(
                context,
                'Grand Awakening — activated via the Full Awakening Maneuver',
                def.grandAwakening!,
                sel: sel,
                def: def,
                inEffect: sel.grandAwakeningActive,
                toggle: _traitToggle(
                  context,
                  'Active',
                  sel.grandAwakeningActive,
                  (v) => _update(() => sel.grandAwakeningActive = v),
                ),
              ),

            // --- Notes ---
            const SizedBox(height: 6),
            ResizableTextField(
              label: 'Notes',
              value: sel.notes,
              initialLines: 2,
              onChanged: (v) => _update(() => sel.notes = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context, TransformationDef def) {
    final label = switch (def.type) {
      TransformationType.awakening =>
        '${def.awakeningType?.displayName ?? ''} · ${def.origin?.displayName ?? ''}',
      TransformationType.enhancement =>
        def.enhancementType?.displayName ?? 'Enhancement',
      TransformationType.form => def.formType?.displayName ?? 'Form',
    };
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _stateControls(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    switch (def.type) {
      case TransformationType.awakening:
        if (def.maxStacks <= 1) {
          return Text('Always active.',
              style: Theme.of(context).textTheme.labelSmall);
        }
        return Row(
          children: [
            const Text('Stacks: '),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: sel.stacks > 1
                  ? () => _update(() => sel.stacks--)
                  : null,
            ),
            Text('${sel.stacks} / ${def.maxStacks}'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: sel.stacks < def.maxStacks
                  ? () => _update(() => sel.stacks++)
                  : null,
            ),
          ],
        );
      case TransformationType.enhancement:
      case TransformationType.form:
        final graded = def.aspects.any((a) => a.startsWith('Graded'));
        return Wrap(
          spacing: 16,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Active'),
                Switch(
                  value: sel.active,
                  onChanged: (v) => _update(() => sel.active = v),
                ),
              ],
            ),
            if (graded)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Grade: '),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: sel.grade > 1
                        ? () => _update(() => sel.grade--)
                        : null,
                  ),
                  Text('${sel.grade}'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _update(() => sel.grade++),
                  ),
                ],
              ),
          ],
        );
    }
  }

  /// Live-value annotation for verbatim rule text: appends the resolved
  /// value after every `N(T)`/`N(bT)` (Tier), `Z` (this Awakening's current
  /// Stacks) and `G` (this Transformation's current Grade) token, so the
  /// text tracks the character's real numbers as they change.
  String _annotate(
    String text, {
    TransformationSelection? sel,
    TransformationDef? def,
  }) {
    final graded =
        def?.aspects.any((a) => a.startsWith('Graded')) ?? false;
    return annotateRuleText(
      text,
      tier: CharacterCalculator.tierOfPower(_c),
      baseTier: CharacterCalculator.baseTierOfPower(_c),
      stacks: def?.type == TransformationType.awakening ? sel?.stacks : null,
      grade: graded ? sel?.grade : null,
    );
  }

  Widget _traitBlock(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
    TransformationTrait trait,
  ) {
    final theme = Theme.of(context);
    // Awakening Traits gated behind a Stack count.
    final locked = def.type == TransformationType.awakening &&
        sel.stacks < trait.minStacks;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trait.name +
                      (trait.minStacks > 1 ? ' (${trait.minStacks})' : ''),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: locked ? theme.disabledColor : null,
                  ),
                ),
              ),
              if (locked)
                Text('needs ${trait.minStacks} Stacks',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.disabledColor)),
            ],
          ),
          Text(
            _annotate(trait.description, sel: sel, def: def),
            style: theme.textTheme.bodySmall?.copyWith(
              color: locked ? theme.disabledColor : null,
            ),
          ),
          if (trait.isAutomated && !locked)
            _automatedLine(
              context,
              sel,
              def,
              trait,
              // Enhancement/Form Traits only apply while ACTIVE (Awakenings
              // are always on).
              inEffect:
                  def.type == TransformationType.awakening || sel.active,
            ),
          for (final group in trait.optionGroups)
            _optionPicker(context, sel, trait.name, group),
          if (!locked) ..._beastGrantPickers(context, sel, def, trait),
          if (trait.distributableAmb.isNotEmpty && !locked)
            _distributableAmbEditor(context, sel, trait),
        ],
      ),
    );
  }

  // --- Bestial / Monstrous Trait grants (Transformation-gated) --------------

  /// Inline pickers for every Bestial/Monstrous Trait this Transformation Trait
  /// grants — its own `beastGrants` plus those of any currently-chosen Option.
  /// Picks live in `TransformationSelection.beastTraitChoices`, so they apply
  /// only while this Transformation is in effect.
  List<Widget> _beastGrantPickers(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
    TransformationTrait trait,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < trait.beastGrants.length; i++) {
      widgets.add(_beastGrantPicker(
          context, sel, def, trait.name, '', i, trait.beastGrants[i]));
    }
    for (final option
        in CharacterCalculator.chosenTraitOptions(trait, sel.optionChoices)) {
      for (var i = 0; i < option.beastGrants.length; i++) {
        widgets.add(_beastGrantPicker(context, sel, def, trait.name,
            option.name, i, option.beastGrants[i]));
      }
    }
    return widgets;
  }

  Widget _beastGrantPicker(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
    String traitName,
    String optionName,
    int index,
    BeastTraitGrant grant,
  ) {
    final theme = Theme.of(context);
    final key = CharacterCalculator.beastTraitGrantKey(
        traitName, optionName, index, grant.kind);
    // A cross-Trait-restricted grant (e.g. "select one you picked for True
    // Power of a Demon God") draws its catalogue from those live picks.
    final dependentPicks = grant.restrictedToTraitPicks != null
        ? CharacterCalculator.beastPicksForTrait(
            _c, grant.restrictedToTraitPicks!)
        : null;
    final catalogue = dependentPicks ??
        (grant.restrictedTo.isNotEmpty
            ? grant.restrictedTo
            : beastTraitsFor(grant.kind).map((t) => t.name).toList());
    final picks = List<String>.from(sel.beastTraitChoices[key] ?? const []);
    final heading = grant.label ??
        (grant.isFixed
            ? 'Grants ${grant.kind.displayName}'
            : 'Gain ${grant.count} ${grant.kind.displayName}'
                '${grant.count == 1 ? '' : 's'}');

    Widget slot(int i) {
      final current = i < picks.length ? picks[i] : null;
      final taken = <String>{
        for (var j = 0; j < picks.length; j++)
          if (j != i && picks[j].isNotEmpty) picks[j],
      };
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: DropdownButtonFormField<String>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: grant.count > 1
                ? '${grant.kind.displayName} ${i + 1}'
                : grant.kind.displayName,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('— None —')),
            for (final name in catalogue)
              if (name == current || !taken.contains(name))
                DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: (value) => _update(() {
            final list =
                List<String>.from(sel.beastTraitChoices[key] ?? const []);
            while (list.length <= i) {
              list.add('');
            }
            list[i] = value ?? '';
            list.removeWhere((e) => e.isEmpty);
            if (list.isEmpty) {
              sel.beastTraitChoices.remove(key);
            } else {
              sel.beastTraitChoices[key] = list;
            }
          }),
        ),
      );
    }

    final selectedNames = <String>[
      ...grant.fixed,
      ...picks.where((p) => p.isNotEmpty),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(heading,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text(
            'Applies only while this Transformation is in effect.',
            style:
                theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (dependentPicks != null && dependentPicks.isEmpty)
            Text(
              'Select your ${grant.restrictedToTraitPicks} Bestial Trait(s) '
              'first — this choice is limited to those.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          if (grant.kind == BeastTraitKind.bestial)
            Text(
              'Bestial Limit: no more than $kBestialTraitLimit Bestial Traits '
              'at once.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          if (grant.fixed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Granted: ${grant.fixed.join(', ')}',
                  style: theme.textTheme.labelSmall),
            ),
          if (!grant.isFixed)
            for (var i = 0; i < grant.count; i++) slot(i),
          for (final name in selectedNames)
            if (beastTraitByName(grant.kind, name) != null)
              _beastTraitCard(
                  context, def, beastTraitByName(grant.kind, name)!),
        ],
      ),
    );
  }

  /// A compact card for a selected Bestial/Monstrous Trait: its verbatim text,
  /// its live automated effect, and its own sub-Option picker (Thick Hide /
  /// Savage / …) — which writes to the GLOBAL `Character.raceTraitOptionChoices`
  /// (keyed by the beast Trait's name) so the calculator applies it.
  Widget _beastTraitCard(
    BuildContext context,
    TransformationDef def,
    RaceTraitDef beast,
  ) {
    final theme = Theme.of(context);
    final effect = CharacterCalculator.raceTraitEffect(
      _c,
      beast,
      currentLife: CharacterCalculator.maxLife(_c),
      maxLife: CharacterCalculator.maxLife(_c),
    );
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(beast.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Chip(
                  label: Text(beast.race),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              annotateRuleText(
                beast.description,
                tier: CharacterCalculator.tierOfPower(_c),
                baseTier: CharacterCalculator.baseTierOfPower(_c),
              ),
              style: theme.textTheme.bodySmall,
            ),
            for (final group in beast.optionGroups)
              _beastSubOptionPicker(context, beast, group),
            if (beast.trailingText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(beast.trailingText, style: theme.textTheme.bodySmall),
            ],
            if (beast.isAutomated) ...[
              const SizedBox(height: 4),
              Text(
                effect.isEmpty
                    ? 'Automated — currently +0'
                    : 'Automated: ${effect.entries.map((e) => '${e.value >= 0 ? '+' : ''}${e.value} ${e.key.displayName}').join(', ')}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A beast Trait's own `[Option]`/`[Multi-Option]` picker, written to the
  /// global `Character.raceTraitOptionChoices` keyed by the beast Trait's name.
  Widget _beastSubOptionPicker(
    BuildContext context,
    RaceTraitDef beast,
    RaceTraitOptionGroup group,
  ) {
    final theme = Theme.of(context);
    final key = '${beast.name}::${group.label}';
    final chosen = _c.raceTraitOptionChoices[key] ?? const <String>{};
    final picker = group.maxChoices <= 1
        ? DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: chosen.isEmpty ? null : chosen.first,
            decoration: InputDecoration(
              labelText: group.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in group.options)
                DropdownMenuItem(value: option.name, child: Text(option.name)),
            ],
            onChanged: (value) => _update(() {
              if (value == null) return;
              _c.raceTraitOptionChoices[key] = {value};
            }),
          )
        : Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in group.options)
                FilterChip(
                  label: Text(option.name),
                  selected: chosen.contains(option.name),
                  onSelected: (selected) => _update(() {
                    final set = _c.raceTraitOptionChoices
                        .putIfAbsent(key, () => <String>{});
                    if (selected) {
                      if (set.length < group.maxChoices) set.add(option.name);
                    } else {
                      set.remove(option.name);
                    }
                  }),
                ),
            ],
          );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          picker,
          for (final option in group.options)
            if (chosen.contains(option.name))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${option.name}: ${option.description}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
        ],
      ),
    );
  }

  /// Steppers for a per-Stack "distribute a flat +1 AMB" Trait (Steady
  /// Progress): one stepper per listed Attribute, writing to
  /// `TransformationSelection.flatAmb`. Shows the running total vs the Stack
  /// count so the player can see when they've allocated all their points.
  Widget _distributableAmbEditor(
    BuildContext context,
    TransformationSelection sel,
    TransformationTrait trait,
  ) {
    final theme = Theme.of(context);
    final allocated =
        trait.distributableAmb.fold<int>(0, (s, a) => s + (sel.flatAmb[a] ?? 0));
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attribute Modifier Bonus — distribute $allocated / ${sel.stacks} '
            '(1 per Stack)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: allocated > sel.stacks ? theme.colorScheme.error : null,
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final attr in trait.distributableAmb)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(attr.abbreviation),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: (sel.flatAmb[attr] ?? 0) > 0
                          ? () => _update(() {
                                final v = (sel.flatAmb[attr] ?? 0) - 1;
                                if (v <= 0) {
                                  sel.flatAmb.remove(attr);
                                } else {
                                  sel.flatAmb[attr] = v;
                                }
                              })
                          : null,
                    ),
                    Text('+${sel.flatAmb[attr] ?? 0}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _update(
                          () => sel.flatAmb[attr] = (sel.flatAmb[attr] ?? 0) + 1),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// A compact labelled Switch used on togglable Trait subsections (Grand
  /// Awakening active, Enhancement Transcended).
  Widget _traitToggle(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  /// The "Automated: +X Stat, …" read-out under an automated Trait —
  /// mirrors the Information page's Racial Trait tiles. Shows the Trait's
  /// current computed contribution (0s can legitimately appear while a
  /// computable condition is unmet).
  Widget _automatedLine(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
    TransformationTrait trait, {
    bool inEffect = true,
  }) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (inEffect) {
      final effect = CharacterCalculator.transformationTraitEffect(
        _c,
        sel,
        def,
        trait,
        currentLife: stats.currentLife,
        maxLife: stats.maxLife,
      );
      parts.addAll(effect.entries.map((e) =>
          '${e.value >= 0 ? '+' : ''}${e.value} ${e.key.displayName}'));
      final top = stats.tierOfPower;
      trait.ambBonus.forEach((attr, amb) {
        if (amb.graded) return;
        final v = amb.coefficient * (amb.tierScaled ? top : 1);
        parts.add('${v >= 0 ? '+' : ''}$v ${attr.abbreviation} Modifier');
      });
      // A chosen Trait Option's AMB (e.g. Burst Aura's FO/MA).
      for (final option
          in CharacterCalculator.chosenTraitOptions(trait, sel.optionChoices)) {
        option.ambPerTierBonus.forEach((attr, coeff) {
          parts.add('+${coeff * top} ${attr.abbreviation} Modifier');
        });
      }
    }
    final text = !inEffect
        ? 'Automated while in effect — currently inactive'
        : (parts.isEmpty
            ? 'Automated — currently +0'
            : 'Automated: ${parts.join(', ')}');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: inEffect
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontStyle: inEffect ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }

  Widget _optionPicker(
    BuildContext context,
    TransformationSelection sel,
    String keyPrefix,
    RaceTraitOptionGroup group,
  ) {
    final theme = Theme.of(context);
    final key = '$keyPrefix::${group.label}';
    final chosen = sel.optionChoices[key] ?? const <String>{};
    // A plain `[Option]` (pick 1) is a dropdown; a `[Multi-Option/N]` (pick up
    // to N, e.g. Metamorphosis's "select S Evolution Traits") is a chip row.
    final picker = group.maxChoices <= 1
        ? DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: chosen.isEmpty ? null : chosen.first,
            decoration: InputDecoration(
              labelText: group.label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in group.options)
                DropdownMenuItem(value: option.name, child: Text(option.name)),
            ],
            onChanged: (value) => _update(() {
              if (value == null) return;
              sel.optionChoices[key] = {value};
            }),
          )
        : Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in group.options)
                FilterChip(
                  label: Text(option.name),
                  selected: chosen.contains(option.name),
                  onSelected: (selected) => _update(() {
                    final set =
                        sel.optionChoices.putIfAbsent(key, () => <String>{});
                    if (selected) {
                      if (set.length < group.maxChoices) set.add(option.name);
                    } else {
                      set.remove(option.name);
                    }
                  }),
                ),
            ],
          );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.maxChoices > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${group.label} (choose up to ${group.maxChoices}, '
                '${chosen.length}/${group.maxChoices} picked)',
                style: theme.textTheme.labelSmall,
              ),
            ),
          picker,
          for (final option in group.options)
            if (chosen.contains(option.name)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${option.name}: ${option.description}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              // Nested "select one" choices that appear once this Option is
              // chosen (e.g. Boosting Aura's AG/TE Attribute pick).
              for (final nested in option.optionGroups)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _optionPicker(
                      context, sel, '$key::${option.name}', nested),
                ),
            ],
        ],
      ),
    );
  }

  Widget _masteryBlock(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    final theme = Theme.of(context);
    final levels = def.masteryLevels;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Mastery: ',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: sel.masteryLevel > 0
                    ? () => _update(() => sel.masteryLevel--)
                    : null,
              ),
              // Flexible so "(Fully Mastered)" can wrap instead of overflowing
              // the row on a phone.
              Flexible(
                child: Text('${sel.masteryLevel} / $levels'
                    '${sel.masteryLevel >= levels ? '  (Fully Mastered)' : ''}'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline),
                onPressed: sel.masteryLevel < levels
                    ? () => _update(() => sel.masteryLevel++)
                    : null,
              ),
            ],
          ),
          // Single Mastery Trait — shown once mastered.
          if (def.masteryTrait != null && sel.masteryLevel >= 1)
            _labelledTrait(context, 'Mastery Trait', def.masteryTrait!,
                sel: sel,
                def: def,
                inEffect: def.type == TransformationType.awakening ||
                    sel.active),
          // Difficult Aspect: one Mastery Trait unlocks per Mastery level.
          for (var i = 0; i < def.masteryTraits.length; i++)
            if (sel.masteryLevel > i)
              _labelledTrait(
                  context, 'Mastery Trait ${i + 1}', def.masteryTraits[i],
                  sel: sel,
                  def: def,
                  inEffect: def.type == TransformationType.awakening ||
                      sel.active),
        ],
      ),
    );
  }

  Widget _labelledTrait(
    BuildContext context,
    String label,
    TransformationTrait trait, {
    TransformationSelection? sel,
    TransformationDef? def,
    bool inEffect = true,
    Widget? toggle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    )),
              ),
              ?toggle,
            ],
          ),
          Text(
              '${trait.name}: '
              '${_annotate(trait.description, sel: sel, def: def)}',
              style: theme.textTheme.bodySmall),
          if (trait.isAutomated && sel != null && def != null)
            _automatedLine(context, sel, def, trait, inEffect: inEffect),
          if (sel != null)
            for (final group in trait.optionGroups)
              _optionPicker(context, sel, trait.name, group),
          if (sel != null && trait.distributableAmb.isNotEmpty)
            _distributableAmbEditor(context, sel, trait),
        ],
      ),
    );
  }

  /// Renders a Transformation's Aspects: colour-coded chips (Positive vs
  /// Negative) carrying the level/parameter the site printed, plus a
  /// collapsible list of each Aspect's verbatim Effect. The clean numeric
  /// subset (Enhanced Save / Raging / Mindful / High Speed / Super Saiyan
  /// Form / Perfect Ki Control / Armored) is auto-applied while the
  /// Transformation is in effect — see `CharacterCalculator.aspectTotals`;
  /// the rest is for the player to apply (see `data/aspects.dart`).
  Widget _aspectsBlock(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    final theme = Theme.of(context);
    final resolved = [
      for (final a in CharacterCalculator.effectiveAspectLabels(def, sel))
        resolveAspect(a),
    ];

    Color chipColor(ResolvedAspect r) {
      if (r.def == null) return theme.colorScheme.surfaceContainerHighest;
      return r.def!.polarity == AspectPolarity.positive
          ? theme.colorScheme.secondaryContainer
          : theme.colorScheme.errorContainer;
    }

    Color textColor(ResolvedAspect r) {
      if (r.def == null) return theme.colorScheme.onSurfaceVariant;
      return r.def!.polarity == AspectPolarity.positive
          ? theme.colorScheme.onSecondaryContainer
          : theme.colorScheme.onErrorContainer;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final r in resolved)
                Tooltip(
                  message: r.def?.summary.isNotEmpty == true
                      ? r.def!.summary
                      : r.label,
                  child: Chip(
                    label: Text(r.label),
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall
                        ?.copyWith(color: textColor(r)),
                    backgroundColor: chipColor(r),
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              dense: true,
              title: Text('Aspect effects',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
              children: [
                for (final r in resolved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: r.def?.name ?? r.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: textColor(r),
                              ),
                            ),
                            if (r.level != null)
                              TextSpan(
                                text: '  (Level ${r.level})',
                                style: theme.textTheme.labelSmall,
                              ),
                            if (r.parameter != null)
                              TextSpan(
                                text:
                                    '  (${r.def?.parameterLabel ?? 'Option'}: ${r.parameter})',
                                style: theme.textTheme.labelSmall,
                              ),
                          ]),
                        ),
                        if (r.def == null)
                          Text('Unrecognized Aspect — see the site.',
                              style: theme.textTheme.bodySmall)
                        else if (r.def!.isClassificationOnly)
                          Text(
                            'Classification only — no mechanical effect.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(_annotate(r.def!.effect),
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A collapsible "Customise" panel gathering the player-authored overrides
  /// for one Transformation — its custom Attribute Modifier Bonus and its
  /// custom Aspects. Both feed the calculator exactly like the catalogue data.
  Widget _customisePanel(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    final theme = Theme.of(context);
    final count = sel.customAmb.length +
        sel.customAspects.length +
        sel.removedAspects.length;
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 4, bottom: 8),
        dense: true,
        initiallyExpanded: count > 0,
        leading: Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
        title: Text(
          count > 0 ? 'Customise ($count)' : 'Customise',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        subtitle:
            Text('Attributes & Aspects', style: theme.textTheme.labelSmall),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Attribute Modifier Bonus',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          _customAmbEditor(context, sel, def),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Aspects',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          _customAspectEditor(context, sel, def),
        ],
      ),
    );
  }

  /// Player-authored Aspect editor. Lets the player add an Aspect a Trait or
  /// GM ruling grants that the app can't auto-detect (or an "Aspect of your
  /// choice") — the added Aspects merge into the effective Aspects and drive
  /// the same automation as the catalogue ones (Enhanced Save, Raging/Mindful,
  /// High Speed, Super Saiyan Form Ki multiplier, Armored DR, etc.).
  Widget _customAspectEditor(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catalogue Aspects — toggle any off to drop its automation.
          if (def.aspects.isNotEmpty) ...[
            Text('Catalogue Aspects (tap to disable / enable)',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final a in def.aspects)
                  _catalogueAspectChip(context, sel, a),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Player-added Aspects.
          if (sel.customAspects.isNotEmpty) ...[
            Text('Added Aspects',
                style: theme.textTheme.labelSmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final label in List<String>.from(sel.customAspects))
                  InputChip(
                    label: Text(label),
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall,
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    onDeleted: () =>
                        _update(() => sel.customAspects.remove(label)),
                  ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Aspect'),
              onPressed: () => _addCustomAspect(context, sel, def),
            ),
          ),
          if (def.type != TransformationType.awakening && !sel.active)
            Text(
              'Applies only while this Transformation is Active.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  /// A toggle chip for a catalogue Aspect: selected = active, unselected =
  /// disabled (added to [TransformationSelection.removedAspects], its label
  /// struck through and its automation dropped).
  Widget _catalogueAspectChip(
    BuildContext context,
    TransformationSelection sel,
    String aspect,
  ) {
    final theme = Theme.of(context);
    final disabled = sel.removedAspects.contains(aspect);
    return FilterChip(
      selected: !disabled,
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      label: Text(
        aspect,
        style: theme.textTheme.labelSmall?.copyWith(
          decoration: disabled ? TextDecoration.lineThrough : null,
          color: disabled ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      onSelected: (on) => _update(() {
        if (on) {
          sel.removedAspects.remove(aspect);
        } else if (!sel.removedAspects.contains(aspect)) {
          sel.removedAspects.add(aspect);
        }
      }),
    );
  }

  /// Opens the Aspect picker and appends the chosen Aspect label to this
  /// Transformation's [TransformationSelection.customAspects] (deduped against
  /// the catalogue and already-added Aspects, case-insensitively).
  Future<void> _addCustomAspect(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) async {
    final existing = {...def.aspects, ...sel.customAspects}
        .map((s) => s.toLowerCase())
        .toSet();
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => _AspectPickerDialog(exclude: existing),
    );
    final label = chosen?.trim() ?? '';
    if (label.isEmpty || existing.contains(label.toLowerCase())) return;
    _update(() => sel.customAspects.add(label));
  }

  /// Player-authored Attribute Modifier Bonus editor. Lets the player pick
  /// which Attribute(s) a bonus applies to and enter its value — used for
  /// Awakenings whose bonus is "to an Attribute of your choice" and for
  /// Grade-set (`*`) tables the app can't auto-derive. These add on top of the
  /// catalogue AMB and are automated identically (always-on × Stacks for
  /// Awakenings, active-only for Enhancements/Forms).
  Widget _customAmbEditor(
    BuildContext context,
    TransformationSelection sel,
    TransformationDef def,
  ) {
    final theme = Theme.of(context);
    final entries = [
      for (final attr in DbuAttribute.values)
        if (sel.customAmb.containsKey(attr)) attr,
    ];
    final used = sel.customAmb.keys.toSet();
    final firstUnused = DbuAttribute.values
        .cast<DbuAttribute?>()
        .firstWhere((a) => !used.contains(a), orElse: () => null);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final attr in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<DbuAttribute>(
                      isExpanded: true,
                      initialValue: attr,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Attribute',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final a in DbuAttribute.values)
                          if (a == attr || !used.contains(a))
                            DropdownMenuItem(
                                value: a, child: Text(a.displayName)),
                      ],
                      onChanged: (newAttr) {
                        if (newAttr == null || newAttr == attr) return;
                        _update(() {
                          final v = sel.customAmb.remove(attr) ?? 0;
                          sel.customAmb[newAttr] = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 84,
                    child: _AmbValueField(
                      value: sel.customAmb[attr] ?? 0,
                      onChanged: (v) =>
                          _update(() => sel.customAmb[attr] = v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        _update(() => sel.customAmb.remove(attr)),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Customise attribute'),
              onPressed: firstUnused == null
                  ? null
                  : () => _update(() => sel.customAmb[firstUnused] = 1),
            ),
          ),
          if (entries.isNotEmpty &&
              def.type != TransformationType.awakening &&
              !sel.active)
            Text(
              'Applies only while this Transformation is Active.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  /// A short human-readable summary of a Transformation's AMB table.
  String _ambText(TransformationDef def) {
    if (def.amb.isEmpty) return 'set by Grade (see Trait text)';
    final parts = <String>[];
    for (final attr in DbuAttribute.values) {
      final amb = def.amb[attr];
      if (amb == null) continue;
      if (amb.graded) {
        // A Grade table (e.g. Kaioken) shows its range; a bare `*` stays text.
        String s(int v) => v >= 0 ? '+$v' : '$v';
        parts.add(amb.gradePerTier.isEmpty
            ? '${attr.abbreviation} *'
            : '${attr.abbreviation} ${s(amb.gradePerTier.first)}→'
                '${s(amb.gradePerTier.last)}(T) by Grade');
      } else {
        parts.add(
            '${attr.abbreviation} +${amb.coefficient}${amb.tierScaled ? '(T)' : ''}');
      }
    }
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

/// Search-and-pick dialog over a Transformation catalogue (already filtered
/// to the character's eligible entries by the caller).
class _TransformationPickerDialog extends StatefulWidget {
  const _TransformationPickerDialog({
    required this.catalogue,
    required this.title,
  });

  final List<TransformationDef> catalogue;
  final String title;

  @override
  State<_TransformationPickerDialog> createState() =>
      _TransformationPickerDialogState();
}

class _TransformationPickerDialogState
    extends State<_TransformationPickerDialog> {
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
    final filtered = widget.catalogue
        .where((d) =>
            query.isEmpty ||
            d.name.toLowerCase().contains(query) ||
            d.racialRequirement.toLowerCase().contains(query) ||
            (d.transformationLine?.toLowerCase().contains(query) ?? false))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        height: 480,
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
              child: filtered.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final def in filtered)
                          ListTile(
                            dense: true,
                            title: Text(def.name),
                            subtitle: Text(
                              'Race: ${def.racialRequirement} · ToP '
                              '${def.tierOfPowerRequirement}+'
                              '${def.transformationLine != null ? ' · ${def.transformationLine} Stage ${def.stage}' : ''}',
                              style: theme.textTheme.labelSmall,
                            ),
                            onTap: () => Navigator.of(context).pop(def),
                          ),
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

/// Picks an Aspect to add to a Transformation. Searches the Aspects catalogue
/// (name + summary) and also allows any free-text label (for parameterized
/// Aspects like "Enhanced Save (Morale)"). Pops the chosen label, or null on
/// cancel. Already-present Aspects (via [exclude]) are hidden from the list.
class _AspectPickerDialog extends StatefulWidget {
  const _AspectPickerDialog({required this.exclude});

  /// Lower-cased labels already on the Transformation (catalogue + custom).
  final Set<String> exclude;

  @override
  State<_AspectPickerDialog> createState() => _AspectPickerDialogState();
}

class _AspectPickerDialogState extends State<_AspectPickerDialog> {
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
    final query = _query.trim();
    final q = query.toLowerCase();
    final matches = [
      for (final a in kDbuAspects)
        if (!widget.exclude.contains(a.name.toLowerCase()) &&
            (q.isEmpty ||
                a.name.toLowerCase().contains(q) ||
                a.summary.toLowerCase().contains(q)))
          a,
    ];
    final canUseRaw = query.isNotEmpty &&
        !widget.exclude.contains(q) &&
        !kDbuAspects.any((a) => a.name.toLowerCase() == q);

    return AlertDialog(
      title: const Text('Add an Aspect'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search or type a label',
                hintText: 'e.g. Armored, Enhanced Save (Morale)',
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
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) Navigator.of(context).pop(v.trim());
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (canUseRaw)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add),
                      title: Text('Use "$query"'),
                      subtitle: Text('Add as a custom Aspect label',
                          style: theme.textTheme.labelSmall),
                      onTap: () => Navigator.of(context).pop(query),
                    ),
                  for (final a in matches)
                    ListTile(
                      dense: true,
                      title: Text(a.name),
                      subtitle: Text(
                        a.summary,
                        style: theme.textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(a.name),
                    ),
                  if (matches.isEmpty && !canUseRaw)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No matching Aspects.')),
                    ),
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

/// A compact signed-integer field for a custom Attribute Modifier Bonus
/// (bonuses can be negative). Keeps its own controller so typing isn't
/// interrupted when the parent rebuilds, syncing back only on external change.
class _AmbValueField extends StatefulWidget {
  const _AmbValueField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_AmbValueField> createState() => _AmbValueFieldState();
}

class _AmbValueFieldState extends State<_AmbValueField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(covariant _AmbValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*$')),
      ],
      decoration: const InputDecoration(
        labelText: 'Bonus',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (text) {
        final parsed = int.tryParse(text);
        if (parsed != null) widget.onChanged(parsed.clamp(-99, 99));
      },
    );
  }
}
