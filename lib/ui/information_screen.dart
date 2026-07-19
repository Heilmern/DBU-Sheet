/// information_screen.dart
/// ---------------------------------------------------------------------------
/// The INFORMATION TAB — a companion to the Character tab focused on Race,
/// shown side-by-side with it via a `TabBar` (see `character_edit_screen.dart`,
/// which owns the single shared [Character] working copy, [DerivedCharacterStats]
/// and the `_update` mutation pipeline both tabs read from/write through).
///
/// This widget is intentionally STATELESS: it always renders from the
/// `character`/`stats` passed in by the parent and reports mutations back via
/// `onUpdate`, so switching tabs never desyncs from edits made in the other
/// tab (there's only ever one source of truth, owned by the parent).
///
///   1. Race Overview        (Race/Sub-Race/Size/Speeds/RLM, Attribute Score
///                            Increase, Racial Saving Throw(s), Racial Skill
///                            Ranks — editable for Custom Species)
///   2. Racial Traits        (full Primary/Secondary catalogue, automated
///                            effects computed live, swap-for-Factor toggle)
///   2b. Traits from other Races (adopted cross-Race Racial Traits — full
///                            catalogue cards, removable, ARC-approved picks)
///   3. Factor Swap-In Traits (freeform — what a swapped-out Trait was
///                            exchanged for)
///   4. Custom Species Traits (freeform Racial Trait selection, Custom
///                            Species only)
///   5. Talents              (freeform scaffold: Name/Prerequisites/
///                            Description/Notes — no catalogue yet)
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/custom_species_traits.dart';
import '../data/dbu_rules.dart';
import '../data/factor_traits.dart';
import '../data/homebrew_registry.dart';
import '../data/race_traits.dart';
import '../data/talents.dart';
import '../models/character.dart';
import '../models/homebrew.dart';
import '../services/character_calculator.dart';
import '../services/rule_text.dart';
import 'widgets/sheet_widgets.dart';

class InformationTab extends StatelessWidget {
  const InformationTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  /// The SAME working copy the Character tab is editing.
  final Character character;

  /// Freshly recomputed derived stats, owned/refreshed by the parent.
  final DerivedCharacterStats stats;

  /// Applies a mutation to [character] and tells the parent to recompute.
  final void Function(VoidCallback mutate) onUpdate;

  Character get _c => character;
  DerivedCharacterStats get _stats => stats;
  void _update(VoidCallback mutate) => onUpdate(mutate);

  @override
  Widget build(BuildContext context) {
    final isCustom = _c.race == 'Custom Species';
    final race = HomebrewRegistry.resolveRace(_c.race);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildRaceOverview(context, race, isCustom),
            if (isCustom)
              _buildCustomSpeciesTraits(context)
            else
              _buildRacialTraits(context),
            _buildExtraRaceTraits(context),
            _buildFactorTraits(context),
            _buildTalents(context),
            _buildHomebrew(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 1. RACE OVERVIEW
  // ==========================================================================
  Widget _buildRaceOverview(BuildContext context, RaceDef race, bool isCustom) {
    return SectionCard(
      title: 'Race Overview',
      icon: Icons.public,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DerivedStat(label: 'Race', value: _c.race),
              if (_c.subspecies.trim().isNotEmpty)
                DerivedStat(label: 'Sub-Race', value: _c.subspecies),
              DerivedStat(label: 'Size', value: _c.size.displayName),
              const DerivedStat(
                  label: 'Melee Reach', value: RangeRules.meleeReachLabel),
              DerivedStat(
                  label: 'Normal Speed', value: '${_stats.speedNormal}'),
              DerivedStat(
                  label: 'Boosted Speed', value: '${_stats.speedBoosted}'),
              DerivedStat(
                  label: 'Racial Life Modifier',
                  value: '+${CharacterCalculator.racialLifeModifier(_c)}'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Attribute Score Increase',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(race.attributeIncreaseText.isEmpty
              ? '—'
              : race.attributeIncreaseText),
          if (race.attributeIncrease.choices.isNotEmpty)
            Text(
              'Pick which Attributes on the Character tab.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 12),
          Text('Racial Saving Throw Bonus (+1(T), -1 Critical Target)',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (isCustom) ...[
            // Verbatim: "Saving Throw: Choose One (Impulsive, Cognitive,
            // Corporeal or Morale)" — a single pick, so choosing one replaces
            // the previous choice rather than adding to it.
            Text(
              'Choose one.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final sv in DbuSavingThrow.values)
                  ChoiceChip(
                    label: Text(sv.displayName),
                    selected: _c.customSavingThrows.contains(sv),
                    onSelected: (sel) => _update(() {
                      _c.customSavingThrows
                        ..clear()
                        ..addAll(sel ? [sv] : const <DbuSavingThrow>[]);
                    }),
                  ),
              ],
            ),
          ] else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final sv in CharacterCalculator.raceSavingThrows(_c))
                  DerivedStat(
                    label: sv.displayName,
                    value: _stats.savingThrows[sv]!.label,
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Text('Racial Skill Ranks',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final total = CharacterCalculator.raceSkillRanks(_c);
            final fromFlaws = total - race.skillRanks;
            return Text(
              'Freely allocate $total Skill Rank${total == 1 ? '' : 's'} on '
              'the Character page.'
              '${fromFlaws > 0 ? ' (${race.skillRanks} base + $fromFlaws from '
                  'Flaw Trait${fromFlaws == 1 ? '' : 's'})' : ''}',
            );
          }),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. RACIAL TRAITS (fixed Races only — Custom Species uses freeform below)
  // ==========================================================================
  Widget _buildRacialTraits(BuildContext context) {
    final traits = raceTraitsFor(_c.race);
    return SectionCard(
      title: 'Racial Traits',
      icon: Icons.auto_awesome_outlined,
      trailing: Text(
        '${traits.where((t) => t.isAutomated).length} automated / '
        '${traits.length} total',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      child: Column(
        children: [
          if (traits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No Racial Trait catalogue on file for this Race yet.',
              ),
            )
          else
            for (final trait in traits) _traitTile(context, trait),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2b. TRAITS FROM OTHER RACES (adopted cross-Race Racial Traits)
  // ==========================================================================
  /// Racial Traits adopted from OTHER Races' catalogues (an ARC-approved
  /// pick — a story reward, a Transformation grant, a table ruling). Each
  /// adopted Trait is a full catalogue `RaceTraitDef`, so its automation,
  /// `[Option]` pickers and combat reminders apply exactly like a native
  /// Trait (see `CharacterCalculator.extraRaceTraitDefs`).
  Widget _buildExtraRaceTraits(BuildContext context) {
    final refs = _c.extraRaceTraits;
    return SectionCard(
      title: 'Traits from other Races',
      icon: Icons.group_add_outlined,
      trailing: IconButton(
        tooltip: "Add another Race's Racial Trait",
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _showAddExtraTraitDialog(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Racial Traits adopted from another Race (with your '
            'ARC’s approval). They apply exactly like your own — '
            'automation, Options and combat reminders included.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 4),
          if (refs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('None adopted yet — use + to add one.'),
            )
          else
            for (var i = 0; i < refs.length; i++)
              _extraTraitTile(context, i),
        ],
      ),
    );
  }

  /// One adopted Trait row: the full trait card (badged with its source
  /// Race) or an unresolved-reference warning, either way removable.
  Widget _extraTraitTile(BuildContext context, int index) {
    final ref = _c.extraRaceTraits[index];
    final sep = ref.indexOf('::');
    final sourceRace = sep <= 0 ? '' : ref.substring(0, sep);
    final traitName = sep <= 0 ? ref : ref.substring(sep + 2);
    final trait = raceTraitsFor(sourceRace)
        .cast<RaceTraitDef?>()
        .firstWhere((t) => t?.name == traitName, orElse: () => null);
    final removeButton = TextButton.icon(
      onPressed: () =>
          _update(() => _c.extraRaceTraits.removeAt(index)),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: const Text('Remove'),
    );
    if (trait == null) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text(ref),
        subtitle: const Text(
            'Not found in the Racial Trait catalogue (stale reference).'),
        trailing: removeButton,
      );
    }
    return _traitCard(
      context,
      trait,
      badgeText: 'From $sourceRace',
      trailingAction: removeButton,
    );
  }

  /// Two-step picker: Race, then one of that Race's Traits not already
  /// possessed. Adds a `'<Race>::<Trait name>'` ref to
  /// [Character.extraRaceTraits].
  void _showAddExtraTraitDialog(BuildContext context) {
    // Every Race with a Racial Trait catalogue except the character's own
    // (native Traits are already on the sheet above).
    final races = [
      for (final race in kDbuRaces)
        if (race.name != _c.race && raceTraitsFor(race.name).isNotEmpty)
          race.name,
    ];
    final owned =
        CharacterCalculator.activeRaceTraits(_c).map((t) => t.name).toSet();
    String? pickedRace;
    String? pickedTrait;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final traits = pickedRace == null
              ? const <RaceTraitDef>[]
              : [
                  for (final t in raceTraitsFor(pickedRace!))
                    if (!owned.contains(t.name)) t,
                ];
          return AlertDialog(
            title: const Text("Add another Race's Trait"),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: pickedRace,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Race',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final r in races)
                        DropdownMenuItem(value: r, child: Text(r)),
                    ],
                    onChanged: (v) => setDialogState(() {
                      pickedRace = v;
                      pickedTrait = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    // Remount when the Race changes so the stale Trait pick
                    // never lingers in the dropdown's own state.
                    key: ValueKey(pickedRace),
                    initialValue: pickedTrait,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Racial Trait',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final t in traits)
                        DropdownMenuItem(
                          value: t.name,
                          child: Text(
                            '${t.name}  (${t.tier == RaceTraitTier.primary ? 'Primary' : 'Secondary'})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: pickedRace == null
                        ? null
                        : (v) => setDialogState(() => pickedTrait = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: pickedRace == null || pickedTrait == null
                    ? null
                    : () {
                        _update(() => _c.extraRaceTraits
                            .add('$pickedRace::$pickedTrait'));
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text('Add Trait'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Renders one canonical Racial Trait slot. If it's been swapped for a
  /// Factor Trait (see `Character.factorSelections`), the Factor Trait is
  /// shown in its place (converted via `FactorTraitDef.toRaceTraitDef` —
  /// CONFIRMED "Factor Traits are considered Racial Traits", so every
  /// existing option/automation/resource display below works on it
  /// unmodified) with an "Undo Swap" action; otherwise the canonical Trait
  /// is shown, either manually deactivated (`inactiveRaceTraitNames`, a
  /// plain on/off toggle for homebrew cases) or active with a "Swap for
  /// Factor" action that opens the compatible-Factor-Trait picker.
  Widget _traitTile(BuildContext context, RaceTraitDef canonicalTrait) {
    FactorSelection? selection;
    for (final s in _c.factorSelections) {
      if (s.replacedTraitName == canonicalTrait.name) {
        selection = s;
        break;
      }
    }
    final factorTrait =
        selection == null ? null : _resolveFactorTrait(selection);

    if (selection != null && factorTrait != null) {
      final displayTrait = factorTrait.toRaceTraitDef(
        race: _c.race,
        tier: canonicalTrait.tier,
      );
      return _traitCard(
        context,
        displayTrait,
        badgeText: 'Factor Trait — ${selection.factorName}',
        trailingAction: TextButton.icon(
          onPressed: () => _update(() {
            _c.factorSelections
                .removeWhere((s) => s.replacedTraitName == canonicalTrait.name);
          }),
          icon: const Icon(Icons.undo, size: 16),
          label: Text('Undo Swap (restore ${canonicalTrait.name})'),
        ),
      );
    }

    final swappedOut = _c.inactiveRaceTraitNames.contains(canonicalTrait.name);
    if (swappedOut) {
      return _traitCard(
        context,
        canonicalTrait,
        swappedOut: true,
        trailingAction: TextButton.icon(
          onPressed: () =>
              _update(() => _c.inactiveRaceTraitNames.remove(canonicalTrait.name)),
          icon: const Icon(Icons.undo, size: 16),
          label: const Text('Restore'),
        ),
      );
    }

    final compatible =
        CharacterCalculator.compatibleFactorTraitsFor(_c, canonicalTrait);
    return _traitCard(
      context,
      canonicalTrait,
      trailingAction: TextButton.icon(
        onPressed: compatible.isEmpty
            ? null
            : () => _showFactorSwapDialog(context, canonicalTrait, compatible),
        icon: const Icon(Icons.swap_horiz, size: 16),
        label: Text(
          compatible.isEmpty
              ? (canonicalTrait.tier == RaceTraitTier.primary
                  ? 'No compatible Factors (Primary)'
                  : 'No compatible Factors')
              : 'Swap for Factor',
        ),
      ),
    );
  }

  FactorTraitDef? _resolveFactorTrait(FactorSelection selection) {
    final factor = factorByName(selection.factorName) ??
        HomebrewRegistry.factorDefByName(selection.factorName);
    if (factor == null) return null;
    for (final t in factor.traits) {
      if (t.name == selection.factorTraitName) return t;
    }
    return null;
  }

  /// The shared visual shell for a Trait tile — used for both a normal
  /// canonical Racial Trait and a Factor Trait standing in for one.
  /// [tierLabel] overrides the Primary/Secondary chip, for Traits where that
  /// authoring tier isn't what the player sees (a Custom Species Flaw is
  /// authored `secondary` but is neither a Primary nor a Secondary Trait).
  Widget _traitCard(
    BuildContext context,
    RaceTraitDef trait, {
    String? badgeText,
    String? tierLabel,
    bool swappedOut = false,
    required Widget trailingAction,
  }) {
    final theme = Theme.of(context);
    final effect = swappedOut
        ? const <AffectedStat, int>{}
        : CharacterCalculator.raceTraitEffect(
            _c,
            trait,
            currentLife: _stats.currentLife,
            maxLife: _stats.maxLife,
          );
    final automatedText = trait.isAutomated
        ? (effect.isEmpty
            ? 'Automated — currently +0'
            : 'Automated: ${effect.entries.map((e) => '${e.value >= 0 ? '+' : ''}${e.value} ${e.key.displayName}').join(', ')}')
        : 'Not automated — apply manually';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: swappedOut ? theme.colorScheme.surfaceContainerHighest : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trait.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                          swappedOut ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Chip(
                  label: Text(tierLabel ?? trait.tier.displayName),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Chip(
                  label: Text(trait.category.displayName),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (badgeText != null) ...[
              const SizedBox(height: 4),
              Text(
                badgeText,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              // Live-value annotation: every N(T)/N(bT) token shows its
              // resolved value for THIS character's current Tiers.
              annotateRuleText(
                trait.description,
                tier: CharacterCalculator.tierOfPower(_c),
                baseTier: CharacterCalculator.baseTierOfPower(_c),
              ),
              style: theme.textTheme.bodySmall,
            ),
            if (!swappedOut && trait.hasOptions) ...[
              const SizedBox(height: 8),
              for (final group in trait.optionGroups)
                _optionGroupPicker(context, trait, group),
            ],
            if (trait.trailingText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(trait.trailingText, style: theme.textTheme.bodySmall),
            ],
            if (!swappedOut && trait.dependentChoice != null)
              _dependentChoiceBlock(context, trait.dependentChoice!),
            if (!swappedOut && _activeGrantedResources(trait).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Grants Resource'
                '${_activeGrantedResources(trait).length > 1 ? 's' : ''}: '
                '${_activeGrantedResources(trait).map((r) => '${r.name} (max ${r.maxStacks})').join(', ')} '
                '— added to your Resources list on the Character page.',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    automatedText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trait.isAutomated
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontStyle: trait.isAutomated
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                trailingAction,
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a picker listing every compatible (Factor, Factor Trait) pair
  /// for [sourceTrait] (see `CharacterCalculator.compatibleFactorTraitsFor`),
  /// grouped by Factor. Selecting one performs the swap: the Factor Trait
  /// becomes active in place of [sourceTrait] (see `Character.factorSelections`
  /// and `CharacterCalculator.activeRaceTraits`).
  Future<void> _showFactorSwapDialog(
    BuildContext context,
    RaceTraitDef sourceTrait,
    List<({FactorDef factor, FactorTraitDef trait})> compatible,
  ) async {
    final chosen = await showDialog<({FactorDef factor, FactorTraitDef trait})>(
      context: context,
      builder: (dialogContext) => _FactorSwapDialog(
        sourceTrait: sourceTrait,
        compatible: compatible,
        usageCountFor: (factorName) =>
            CharacterCalculator.factorUsageCount(_c, factorName),
      ),
    );

    if (chosen == null) return;
    _update(() {
      _c.factorSelections.add(FactorSelection(
        factorName: chosen.factor.name,
        factorTraitName: chosen.trait.name,
        replacedTraitName: sourceTrait.name,
      ));
    });
  }

  /// Renders a `[Choice]` effect that depends on an Option chosen for a
  /// DIFFERENT Trait (see `DependentChoice`). Only the branch matching the
  /// player's actual pick on the source Trait/group is shown — the other
  /// branches don't apply to this character, so they're hidden rather than
  /// listed-but-highlighted (every branch's full original text still lives
  /// in the data — see `DependentChoice.textByOption` — this is purely a
  /// display-time filter).
  Widget _dependentChoiceBlock(BuildContext context, DependentChoice dep) {
    final theme = Theme.of(context);
    final chosen = _c
            .raceTraitOptionChoices['${dep.sourceTraitName}::${dep.sourceGroupLabel}'] ??
        const <String>{};
    final applicable = dep.textByOption.entries
        .where((entry) => chosen.contains(entry.key));

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (applicable.isEmpty)
            Text(
              "Select an Option on ${dep.sourceTraitName}'s "
              "'${dep.sourceGroupLabel}' choice to see which effect "
              'applies to you.',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final entry in applicable)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurface),
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: entry.value),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// This Trait's own [GrantedResource]s, plus those of any currently
  /// chosen Option within it (see `TraitOption.grantedResources`).
  List<GrantedResource> _activeGrantedResources(RaceTraitDef trait) {
    final result = <GrantedResource>[...trait.grantedResources];
    for (final group in trait.optionGroups) {
      final chosen =
          _c.raceTraitOptionChoices['${trait.name}::${group.label}'] ??
              const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.name)) result.addAll(option.grantedResources);
      }
    }
    return result;
  }

  /// Renders one Character-Creation choice point for a Trait: a dropdown for
  /// a plain `[Option]` (pick 1), or a row of toggleable chips for a
  /// `[Multi-Option/N]` (pick up to N). The chosen name(s) are stored on
  /// `Character.raceTraitOptionChoices`, keyed by Trait+group so a Trait
  /// with more than one choice point (e.g. Android's Technological Being)
  /// doesn't collide.
  Widget _optionGroupPicker(
    BuildContext context,
    RaceTraitDef trait,
    RaceTraitOptionGroup group,
  ) {
    final theme = Theme.of(context);
    final key = '${trait.name}::${group.label}';
    final chosen = _c.raceTraitOptionChoices[key] ?? const <String>{};

    final picker = group.maxChoices <= 1
        ? DropdownButtonFormField<String>(
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
                    final set = _c.raceTraitOptionChoices.putIfAbsent(
                      key,
                      () => <String>{},
                    );
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
      padding: const EdgeInsets.only(bottom: 6),
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

  // ==========================================================================
  // 3. FACTOR SWAP-IN TRAITS (freeform)
  // ==========================================================================
  Widget _buildFactorTraits(BuildContext context) {
    return SectionCard(
      title: 'Factor Swap-In Traits',
      icon: Icons.published_with_changes_outlined,
      trailing: IconButton(
        tooltip: 'Add',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () async {
          final chosen = await showDialog<Object>(
            context: context,
            builder: (dialogContext) => _FactorCataloguePickerDialog(
              race: _c.race,
              allowCustomEntry: true,
            ),
          );
          if (chosen == null) return;
          _update(() {
            if (chosen is ({FactorDef factor, FactorTraitDef trait})) {
              _c.factorTraits.add(TrackedEntry()
                ..name = chosen.trait.name
                ..notes = chosen.trait.description);
            } else {
              _c.factorTraits.add(TrackedEntry());
            }
          });
        },
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Use this for a Factor Trait gained WITHOUT the structured '
              '"Swap Factor" picker above — pick one from the catalogue '
              '(prefilling its verbatim text), or choose Custom Entry for '
              "a homebrew one. Tick 'Replaces Racial Trait' to deactivate "
              'the Trait it stands in for.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (_c.factorTraits.isEmpty)
            const Text('No Factor Traits recorded.')
          else
            for (var i = 0; i < _c.factorTraits.length; i++)
              _factorTraitFreeformRow(
                context: context,
                entry: _c.factorTraits[i],
                onDelete: () =>
                    _update(() => _c.factorTraits.removeAt(i)),
              ),
        ],
      ),
    );
  }

  /// Names of canonical Racial Traits eligible to be marked as "replaced"
  /// by [current]'s freeform Factor Trait — excludes Traits already swapped
  /// via the structured `factorSelections` picker, and Traits already
  /// claimed by a DIFFERENT freeform entry (but still offers [current]'s
  /// own current pick, if any).
  List<String> _replaceableTraitNames(TrackedEntry current) {
    final claimedByOthers = _c.factorTraits
        .where((e) => e != current && e.replacesTraitName.trim().isNotEmpty)
        .map((e) => e.replacesTraitName)
        .toSet();
    final isCustom = _c.race == 'Custom Species';
    final candidates = isCustom
        ? _c.customRaceTraits
            .map((t) => t.name)
            .where((n) => n.trim().isNotEmpty)
        : raceTraitsFor(_c.race)
            .where((t) =>
                !_c.factorSelections.any((s) => s.replacedTraitName == t.name))
            .map((t) => t.name);
    return candidates
        .where((n) =>
            !claimedByOthers.contains(n) || n == current.replacesTraitName)
        .toSet()
        .toList();
  }

  Future<void> _pickFactorTraitFromCatalogue(
    BuildContext context,
    TrackedEntry entry,
  ) async {
    final chosen = await showDialog<({FactorDef factor, FactorTraitDef trait})>(
      context: context,
      builder: (dialogContext) =>
          _FactorCataloguePickerDialog(race: _c.race),
    );
    if (chosen == null) return;
    _update(() {
      entry.name = chosen.trait.name;
      entry.notes = chosen.trait.description;
    });
  }

  /// A Factor Swap-In row: the shared Name/Notes freeform fields, plus a
  /// catalogue-picker button and a "Replaces Racial Trait" checkbox that
  /// keeps `Character.inactiveRaceTraitNames` in sync with this entry.
  Widget _factorTraitFreeformRow({
    required BuildContext context,
    required TrackedEntry entry,
    required VoidCallback onDelete,
  }) {
    final replaces = entry.replacesTraitName.trim();
    final available = _replaceableTraitNames(entry);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _textField(
                    label: 'Name',
                    value: entry.name,
                    onChanged: (v) => _update(() => entry.name = v),
                  ),
                ),
                IconButton(
                  tooltip: 'Pick from Factors catalogue',
                  icon: const Icon(Icons.list_alt_outlined),
                  onPressed: () =>
                      _pickFactorTraitFromCatalogue(context, entry),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            ResizableTextField(
              label: 'Description / Notes',
              value: entry.notes,
              initialLines: 3,
              onChanged: (v) => _update(() => entry.notes = v),
            ),
            Row(
              children: [
                Checkbox(
                  value: replaces.isNotEmpty,
                  onChanged: (checked) => _update(() {
                    if (checked == true) {
                      entry.replacesTraitName =
                          available.isNotEmpty ? available.first : '';
                      if (entry.replacesTraitName.isNotEmpty) {
                        _c.inactiveRaceTraitNames
                            .add(entry.replacesTraitName);
                      }
                    } else {
                      if (replaces.isNotEmpty) {
                        _c.inactiveRaceTraitNames.remove(replaces);
                      }
                      entry.replacesTraitName = '';
                    }
                  }),
                ),
                const Text('Replaces Racial Trait:'),
                const SizedBox(width: 8),
                if (replaces.isNotEmpty)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          available.contains(replaces) ? replaces : null,
                      isDense: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final name in available)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) => _update(() {
                        if (value == null) return;
                        if (replaces.isNotEmpty) {
                          _c.inactiveRaceTraitNames.remove(replaces);
                        }
                        entry.replacesTraitName = value;
                        _c.inactiveRaceTraitNames.add(value);
                      }),
                    ),
                  )
                else
                  const Text(
                    '(none)',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 4. CUSTOM SPECIES RACIAL TRAIT SELECTION (Custom Species only)
  // ==========================================================================
  Widget _buildCustomSpeciesTraits(BuildContext context) {
    final theme = Theme.of(context);
    final primaryCount = _c.customPrimaryTraits.length;
    // Flaws are picked separately from the 5 Racial Traits (Step 4 vs Step 7)
    // and are never Primary, so they're counted apart.
    final flawCount = _c.customRaceTraits
        .where((e) {
          final def = customSpeciesTraitByName(e.name);
          return def != null && isCustomSpeciesFlaw(def);
        })
        .length;
    final traitCount = _c.customRaceTraits.length - flawCount;
    return SectionCard(
      title: 'Custom Species Racial Traits',
      icon: Icons.auto_awesome_outlined,
      trailing: IconButton(
        tooltip: 'Add',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () async {
          final chosen = await _showCustomSpeciesTraitPicker(context);
          if (chosen == null) return;
          _update(() => _c.customRaceTraits.add(TrackedEntry()..name = chosen));
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Pick 5 Racial Traits from the catalogue, then mark 2 as '
              'Primary — those gain their [Twinned] effects (the other 3 are '
              'Secondary, base effects only). Flaw Traits (max. 2) are picked '
              'on top of the 5 and each grants a compensation.',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Racial Traits: $traitCount / 5  ·  Primary: $primaryCount / 2  '
              '·  Flaws: $flawCount / $kMaxCustomSpeciesFlaws',
              style: theme.textTheme.labelSmall?.copyWith(
                color: (traitCount > 5 || flawCount > kMaxCustomSpeciesFlaws)
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
          ),
          if (_c.customRaceTraits.isEmpty)
            const Text('No Racial Traits recorded.')
          else
            for (var i = 0; i < _c.customRaceTraits.length; i++)
              _customSpeciesRow(context, i),
        ],
      ),
    );
  }

  /// One Custom Species Trait row: catalogue-backed Traits render like any
  /// Racial Trait (`_traitCard`) with a **Primary** toggle (max 2 — a Primary
  /// Trait's `[Twinned]` effects are active); a **Flaw** Trait instead gets its
  /// compensation picker (Racial Life Modifier +2 / Skill Ranks +1), since
  /// Flaws carry no `[Twinned]` effects and are never Primary. Unrecognized
  /// names fall back to the freeform editor.
  Widget _customSpeciesRow(BuildContext context, int i) {
    final entry = _c.customRaceTraits[i];
    void onDelete() => _update(() {
          _c.customPrimaryTraits.remove(entry.name);
          _c.customFlawCompensation.remove(entry.name);
          _c.customRaceTraits.removeAt(i);
        });
    final def = customSpeciesTraitByName(entry.name);
    if (def == null) return _freeformRow(entry: entry, onDelete: onDelete);
    if (isCustomSpeciesFlaw(def)) {
      return _customSpeciesFlawRow(context, def, onDelete);
    }

    final isPrimary = _c.customPrimaryTraits.contains(entry.name);
    final canAddPrimary = _c.customPrimaryTraits.length < 2;
    // Show the resolved def: Primary keeps its Twinned content; Secondary is
    // stripped to base-only, so both the "Automated: …" read-out AND the
    // printed effect text hide the [Twinned] effects it doesn't possess.
    final resolved = isPrimary ? def : def.baseOnly();
    final badge = !def.hasTwinnedEffects
        ? null
        : isPrimary
            ? 'Primary — Twinned effects active'
            : 'Secondary — [Twinned] effects hidden (mark Primary to gain them)';
    return _traitCard(
      context,
      resolved,
      badgeText: badge,
      trailingAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            label: const Text('Primary'),
            selected: isPrimary,
            onSelected: (!isPrimary && !canAddPrimary)
                ? null
                : (sel) => _update(() {
                      if (sel) {
                        _c.customPrimaryTraits.add(entry.name);
                      } else {
                        _c.customPrimaryTraits.remove(entry.name);
                      }
                    }),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  /// One **Flaw Trait** row. Verbatim (Custom Species, Step 7): "For each Flaw
  /// Trait you pick, either increase the Racial Life Modifier of your Race by 2
  /// or increase the number of Skill Ranks granted by your Race by 1" — the
  /// pick drives `CharacterCalculator.racialLifeModifier` / `raceSkillRanks`,
  /// so an unset one contributes nothing until chosen.
  Widget _customSpeciesFlawRow(
    BuildContext context,
    RaceTraitDef def,
    VoidCallback onDelete,
  ) {
    final chosen = _c.customFlawCompensation[def.name];
    return _traitCard(
      context,
      def,
      tierLabel: 'Flaw',
      badgeText: chosen == null
          ? 'Flaw — choose its compensation'
          : 'Flaw — ${chosen.displayName}',
      trailingAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 230,
            child: DropdownButtonFormField<FlawCompensation>(
              initialValue: chosen,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Compensation',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final option in FlawCompensation.values)
                  DropdownMenuItem(
                    value: option,
                    child: Text(option.displayName),
                  ),
              ],
              onChanged: (value) => _update(() {
                if (value == null) {
                  _c.customFlawCompensation.remove(def.name);
                } else {
                  _c.customFlawCompensation[def.name] = value;
                }
              }),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  /// Catalogue picker for Custom Species Traits. Returns the chosen Trait's
  /// name, `''` for a freeform entry, or `null` if dismissed.
  Future<String?> _showCustomSpeciesTraitPicker(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add Custom Species Racial Trait'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Custom Entry (freeform)'),
          ),
          const Divider(),
          for (final t in kDbuCustomSpeciesRacialTraits)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.name),
              child: Text('${t.name}  ·  ${t.category.displayName}'),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Flaw Traits (max. $kMaxCustomSpeciesFlaws)',
              style: Theme.of(ctx).textTheme.labelLarge,
            ),
          ),
          for (final t in kDbuCustomSpeciesFlaws)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t.name),
              child: Text('${t.name}  ·  ${t.category.displayName}'),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. TALENTS (freeform scaffold)
  // ==========================================================================
  Widget _buildTalents(BuildContext context) {
    return SectionCard(
      title: 'Talents',
      icon: Icons.military_tech_outlined,
      trailing: IconButton(
        tooltip: 'Add',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () async {
          final chosen = await showDialog<Object>(
            context: context,
            builder: (dialogContext) => const TalentCataloguePickerDialog(
              allowCustomEntry: true,
            ),
          );
          if (chosen == null) return;
          _update(() {
            if (chosen is TalentDef) {
              _c.talents.add(TalentEntry()
                ..name = chosen.name
                ..prerequisites = chosen.prerequisitesText
                ..description = chosen.description);
            } else {
              _c.talents.add(TalentEntry());
            }
          });
        },
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Pick a Talent from the catalogue (prefilling its verbatim '
              'text), or choose Custom Entry for a homebrew one.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (_c.talents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No Talents recorded yet.'),
            )
          else
            for (var i = 0; i < _c.talents.length; i++)
              _talentRow(
                context: context,
                entry: _c.talents[i],
                onDelete: () => _update(() => _c.talents.removeAt(i)),
              ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 5. HOMEBREW (player-authored — definitions live in the Homebrew library)
  // ==========================================================================
  Widget _buildHomebrew(BuildContext context) {
    final theme = Theme.of(context);
    final unresolved = CharacterCalculator.unresolvedHomebrewNames(_c);
    bool alreadyPicked(HomebrewEntry e) => _c.homebrewSelections.any(
        (s) => s.name.trim().toLowerCase() == e.name.trim().toLowerCase());
    // Structured categories are excluded from this generic possession picker:
    // each is chosen via its own system (Race dropdown, Conditions/States
    // trackers, Transformations tab, "Swap for Factor", Inventory pickers,
    // Signatures tab, Unique Abilities tab) — adding them here too would
    // double-apply their effects. Only Talents, Racial Traits and Other stay
    // generic (possession here IS how they apply). Old saves that already
    // reference a structured one keep working; only NEW picks are steered.
    bool structurallyIntegrated(HomebrewEntry e) => switch (e.category) {
          HomebrewCategory.talent ||
          HomebrewCategory.racialTrait ||
          HomebrewCategory.other =>
            false,
          _ => true,
        };
    final available = [
      for (final e in HomebrewRegistry.all)
        if (!alreadyPicked(e) && !structurallyIntegrated(e)) e,
    ];

    return SectionCard(
      title: 'Homebrew',
      icon: Icons.auto_fix_high_outlined,
      trailing: IconButton(
        tooltip: available.isEmpty
            ? 'No unused homebrew in your library'
            : 'Add homebrew',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: available.isEmpty
            ? null
            : () async {
                final chosen = await showDialog<HomebrewEntry>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: const Text('Add homebrew'),
                    children: [
                      for (final e in available)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, e),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.displayName),
                            subtitle: Text(
                              e.automations.isEmpty
                                  ? '${e.category.displayName}  •  Reference only'
                                  : '${e.category.displayName}  •  '
                                      '${e.automations.length} automated effect'
                                      '${e.automations.length == 1 ? '' : 's'}',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                if (chosen == null) return;
                _update(() => _c.homebrewSelections
                    .add(HomebrewSelection(name: chosen.name)));
              },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Custom content from your Homebrew library. Its automated '
              'effects feed this sheet exactly like catalogue content.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          if (unresolved.isNotEmpty)
            Card(
              color: theme.colorScheme.errorContainer,
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Missing from your library: ${unresolved.join(', ')}. '
                        'Import the homebrew to apply its effects.',
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_c.homebrewSelections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                HomebrewRegistry.all.isEmpty
                    ? 'No homebrew yet — create some in the Homebrew tab on the '
                        'home screen.'
                    : 'No homebrew added to this character yet.',
              ),
            )
          else
            for (var i = 0; i < _c.homebrewSelections.length; i++)
              _homebrewRow(
                context: context,
                selection: _c.homebrewSelections[i],
                onDelete: () =>
                    _update(() => _c.homebrewSelections.removeAt(i)),
              ),
        ],
      ),
    );
  }

  Widget _homebrewRow({
    required BuildContext context,
    required HomebrewSelection selection,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final def = HomebrewRegistry.byName(selection.name);
    final effect = (def == null || !selection.active)
        ? const <AffectedStat, int>{}
        : CharacterCalculator.homebrewEffect(
            _c,
            def,
            currentLife: _stats.currentLife,
            maxLife: _stats.maxLife,
          );

    final String status;
    if (def == null) {
      status = 'Not in your library — no effect applied';
    } else if (def.automations.isEmpty) {
      status = 'Reference only — apply manually';
    } else if (!selection.active) {
      status = 'Inactive — no effect applied';
    } else if (effect.isEmpty) {
      status = 'Automated — currently +0';
    } else {
      status =
          'Automated: ${effect.entries.map((e) => '${e.value >= 0 ? '+' : ''}${e.value} ${e.key.displayName}').join(', ')}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    def?.displayName ?? selection.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (def != null)
                  Chip(
                    label: Text(def.category.displayName),
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (def != null && def.flavor.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(def.flavor.trim(),
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            if (def != null && def.effectText.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(annotateRuleText(
                  def.effectText.trim(),
                  tier: CharacterCalculator.tierOfPower(_c),
                  baseTier: CharacterCalculator.baseTierOfPower(_c),
                )),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: def == null
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Lets a Transformation-like homebrew be toggled off when not
                // in use; always-on homebrew simply stays active.
                Switch(
                  value: selection.active,
                  onChanged: (v) => _update(() => selection.active = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _talentRow({
    required BuildContext context,
    required TalentEntry entry,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final talent = talentByName(entry.name);
    final effect = talent == null
        ? const <AffectedStat, int>{}
        : CharacterCalculator.talentEffect(
            _c,
            talent,
            currentLife: _stats.currentLife,
            maxLife: _stats.maxLife,
          );
    final automatedText = talent == null
        ? null
        : (talent.isAutomated
            ? (effect.isEmpty
                ? 'Automated — currently +0'
                : 'Automated: ${effect.entries.map((e) => '${e.value >= 0 ? '+' : ''}${e.value} ${e.key.displayName}').join(', ')}')
            : 'Not automated — apply manually');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _textField(
                    label: 'Talent Name',
                    value: entry.name,
                    onChanged: (v) => _update(() => entry.name = v),
                  ),
                ),
                if (talent != null) ...[
                  const SizedBox(width: 4),
                  Chip(
                    label: Text(talent.category.displayName),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                IconButton(
                  tooltip: 'Pick from Talents catalogue',
                  icon: const Icon(Icons.list_alt_outlined),
                  onPressed: () => _pickTalentFromCatalogueAndUpdate(
                    context,
                    entry,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            _textField(
              label: 'Prerequisites',
              value: entry.prerequisites,
              onChanged: (v) => _update(() => entry.prerequisites = v),
            ),
            ResizableTextField(
              label: 'Description',
              value: entry.description,
              initialLines: 3,
              onChanged: (v) => _update(() => entry.description = v),
            ),
            ResizableTextField(
              label: 'Notes',
              value: entry.notes,
              initialLines: 2,
              onChanged: (v) => _update(() => entry.notes = v),
            ),
            if (automatedText != null) ...[
              const SizedBox(height: 6),
              Text(
                automatedText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: talent!.isAutomated
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontStyle: talent.isAutomated
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTalentFromCatalogueAndUpdate(
    BuildContext context,
    TalentEntry entry,
  ) async {
    final chosen = await showDialog<TalentDef>(
      context: context,
      builder: (dialogContext) => const TalentCataloguePickerDialog(),
    );
    if (chosen == null) return;
    _update(() {
      entry.name = chosen.name;
      entry.prerequisites = chosen.prerequisitesText;
      entry.description = chosen.description;
    });
  }

  /// A simple Name + Notes freeform row, shared by Factor Traits and Custom
  /// Species Trait selection (both reuse [TrackedEntry] purely for its
  /// free-text fields).
  Widget _freeformRow({
    required TrackedEntry entry,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _textField(
                    label: 'Name',
                    value: entry.name,
                    onChanged: (v) => _update(() => entry.name = v),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            ResizableTextField(
              label: 'Description / Notes',
              value: entry.notes,
              initialLines: 3,
              onChanged: (v) => _update(() => entry.notes = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
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

}

/// The "Swap for Factor" picker — a searchable list of every compatible
/// (Factor, Factor Trait) pair, grouped by Factor. Kept as its own
/// StatefulWidget (rather than inline in `showDialog`'s builder) purely to
/// own the search field's local state.
class _FactorSwapDialog extends StatefulWidget {
  const _FactorSwapDialog({
    required this.sourceTrait,
    required this.compatible,
    required this.usageCountFor,
  });

  final RaceTraitDef sourceTrait;
  final List<({FactorDef factor, FactorTraitDef trait})> compatible;
  final int Function(String factorName) usageCountFor;

  @override
  State<_FactorSwapDialog> createState() => _FactorSwapDialogState();
}

class _FactorSwapDialogState extends State<_FactorSwapDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Just the flavour-text lead-in of a Trait's description (everything
  /// before its first numbered effect) — the mechanical "(1)-[Passive]: "
  /// text reads badly as a truncated preview, so previews only ever show
  /// the introductory sentence(s).
  String _flavorText(String description) => description.split('\n').first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.compatible
        : widget.compatible.where((pair) {
            return pair.trait.name.toLowerCase().contains(query) ||
                pair.factor.name.toLowerCase().contains(query) ||
                _flavorText(pair.trait.description)
                    .toLowerCase()
                    .contains(query);
          }).toList();

    final byFactor = <FactorDef, List<FactorTraitDef>>{};
    for (final pair in filtered) {
      byFactor.putIfAbsent(pair.factor, () => []).add(pair.trait);
    }

    return AlertDialog(
      title: Text('Swap "${widget.sourceTrait.name}" for a Factor Trait'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Factors/Factor Traits',
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
              child: byFactor.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final factor in byFactor.keys) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              '${factor.name} (max ${factor.maxFactor}× — '
                              '${widget.usageCountFor(factor.name)} used)',
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final trait in byFactor[factor]!)
                            ListTile(
                              dense: true,
                              title: Text(trait.name),
                              subtitle: Text(
                                _flavorText(trait.description),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context)
                                  .pop((factor: factor, trait: trait)),
                            ),
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
}

/// Browses the FULL Factor/Factor Trait catalogue (not narrowed to a single
/// source Trait's compatible options, unlike `_FactorSwapDialog`) — used by
/// the freeform "Factor Swap-In Traits" section's catalogue-picker button,
/// which just prefills a freeform row's Name/Notes rather than performing a
/// structured swap.
class _FactorCataloguePickerDialog extends StatefulWidget {
  const _FactorCataloguePickerDialog({
    required this.race,
    this.allowCustomEntry = false,
  });

  final String race;

  /// Whether to show a "Custom Entry" action alongside Cancel, for callers
  /// that want catalogue-pick-by-default with a homebrew fallback (see the
  /// Factor Swap-In Traits section's "Add" button). Per-row re-pick dialogs
  /// leave this off, since Cancel already gets you back to the existing
  /// freeform fields.
  final bool allowCustomEntry;

  @override
  State<_FactorCataloguePickerDialog> createState() =>
      _FactorCataloguePickerDialogState();
}

class _FactorCataloguePickerDialogState
    extends State<_FactorCataloguePickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _flavorText(String description) => description.split('\n').first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eligibleFactors = [
      ...kDbuFactors,
      ...HomebrewRegistry.factorDefs(),
    ].where((f) => f.isEligibleForRace(widget.race));
    final query = _query.trim().toLowerCase();

    final byFactor = <FactorDef, List<FactorTraitDef>>{};
    for (final factor in eligibleFactors) {
      final traits = factor.traits
          .where((t) => t.isEligibleForRace(widget.race))
          .where((t) =>
              query.isEmpty ||
              t.name.toLowerCase().contains(query) ||
              factor.name.toLowerCase().contains(query) ||
              _flavorText(t.description).toLowerCase().contains(query))
          .toList();
      if (traits.isNotEmpty) byFactor[factor] = traits;
    }

    return AlertDialog(
      title: const Text('Pick a Factor Trait'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Factors/Factor Traits',
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
              child: byFactor.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final factor in byFactor.keys) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              factor.name,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final trait in byFactor[factor]!)
                            ListTile(
                              dense: true,
                              title: Text(trait.name),
                              subtitle: Text(
                                _flavorText(trait.description),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.of(context)
                                  .pop((factor: factor, trait: trait)),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.allowCustomEntry)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(kCustomCatalogueEntry),
            child: const Text('Custom Entry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Browses the full Talents catalogue (all 33 Talent Categories) — used by
/// the Talents section's "Add from catalogue" button and each row's
/// catalogue-picker icon, same search-and-pick pattern as
/// `_FactorCataloguePickerDialog`.
// `TalentCataloguePickerDialog` now lives in `widgets/sheet_widgets.dart` so
// both this tab and the Progression tab can share it.
