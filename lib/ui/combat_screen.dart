/// combat_screen.dart
/// ---------------------------------------------------------------------------
/// The COMBAT TRACKER page — opened via the "Start Combat" button next to
/// Save on the character edit screen. A live combat companion that walks the
/// player through the encounter's phase cycle:
///
///   Start of Combat → Start of Round → Start of Turn → End of Turn →
///   (repeat from Start of Round)
///
/// shown as a top phase bar with a Round counter. Each phase card shows the
/// verbatim rules for that phase (Combat Encounters / Actions & Maneuvers
/// pages) plus **reminders scanned from everything the character possesses**
/// (see `services/combat_reminders.dart`) — active Racial Traits,
/// Talents, Transformations/Aspects, Conditions/States/Resources, gear
/// Qualities, Unique Abilities and homebrew whose text names that timing.
/// Advancing into a phase pops the reminders up as a dialog too.
///
/// Automation on the round boundary (advancing End of Turn → Start of
/// Round): Actions reset to 3 (−1 while Reduced Momentum is marked),
/// Counter Actions to 1, and the Diminishing Offense/Defense trackers are
/// cleared (verbatim: they clear at the end/start of each Combat Round).
/// The Attacking / Being-Attacked cards automate the two Diminishing
/// trackers: "I attacked" counts attacks and adds Diminishing Offense
/// stacks after the third; "I was targeted" adds the base-ToP-scaled
/// Diminishing Defense stacks per hit.
///
/// The screen mutates the SAME working copy the edit screen holds, so
/// Life/Ki/stack changes made here persist when the player taps SAVE (and
/// are discarded together if they back out) — while purely tabletop-session
/// state (phase, Round number, Actions left, Battlefield picks, damage
/// calculator inputs) is ephemeral widget state, like the References tab.
///
/// "Make an Attacking Maneuver" switches to the Attacking Maneuver tab —
/// its own top-level tab hosting the References attack calculator (in combat
/// mode) beside the effects that trigger on an attack / Attacking Maneuver /
/// Signature Technique. Resolving it there with "Attack made" spends the
/// attack's Ki + Capacity (Ki Cost + Ki Wager) and counts it toward
/// Diminishing Offense; the calculator also warns when that Ki exceeds your
/// current Ki or Capacity, or the Wager exceeds its maximum.
///
/// Also on the page: a Status card (pools, Surges), a Custom Buffs card
/// (toggle your buffs/debuffs Active on and off mid-combat — each toggle
/// recomputes the rolls), Resources / Conditions / States trackers (the same
/// catalogue machinery as the Character tab — picking a Condition here
/// immediately feeds the phase reminders), a
/// Battlefield card (Battle Weather + Tier / Battle Environment / Light
/// Level pickers whose verbatim effects feed the phase reminders) and the
/// full Maneuver reference catalogue (`data/combat_flow.dart`) with live
/// (T)/(bT) annotation. Ending combat surfaces the verbatim
/// end-of-encounter rules with a one-tap cleanup (Instant Recovery +
/// Resources lost). Below 1000 logical px the cards stack in one column; at
/// or above they split into two columns under one shared scroll view, same
/// as the Character tab.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/combat_flow.dart';
import '../data/dbu_rules.dart';
import '../data/homebrew_registry.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import '../services/combat_reminders.dart';
import '../services/progression_talent_sync.dart';
import '../services/race_resource_sync.dart';
import '../services/rule_text.dart';
import 'information_screen.dart' show InformationTab;
import 'inventory_screen.dart' show InventoryTab;
import 'references_screen.dart' show ReferencesTab;
import 'signatures_screen.dart' show SignaturesTab;
import 'transformations_screen.dart' show TransformationsTab;
import 'unique_abilities_screen.dart' show UniqueAbilitiesTab;
import 'widgets/sheet_widgets.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key, required this.character});

  /// The SAME working copy the edit screen is editing — mutations made here
  /// show up there and persist via its SAVE button.
  final Character character;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late Character _c;
  late DerivedCharacterStats _stats;

  /// Combat tracker / Attacking Maneuver / Information / Transformations /
  /// Inventory / Signatures / Unique Abilities — all but the first two are
  /// the SAME tab widgets the edit screen uses, on the same working copy, so
  /// the player can transform, check a Trait, or swap gear mid-combat without
  /// leaving the tracker; every change feeds the reminders.
  late final TabController _tabController =
      TabController(length: 7, vsync: this);

  /// Index of the Attacking Maneuver tab (see the [TabBar] below) — the
  /// "Make an Attacking Maneuver" button jumps here.
  static const int _attackTabIndex = 1;

  // --- Ephemeral encounter state (not persisted, like the References tab) ---
  CombatPhase _phase = CombatPhase.startOfCombat;
  int _round = 0;
  int _actions = 3;
  int _counterActions = 1;
  int _attacksThisRound = 0;
  bool _bonusMomentumUsed = false;

  /// Marked when the player reduced their own Life below a Health Threshold
  /// this Round — the next Start of Round then grants 1 less Action.
  bool _reducedMomentumPending = false;
  bool _surgeManeuverUsed = false;

  // Battlefield picks (ephemeral; their effects feed the phase reminders).
  BattleWeatherDef? _weather;
  int _weatherTier = 1;
  BattleEnvironmentDef? _environment;
  LightLevelDef? _light;

  // Damage Calculator inputs (ephemeral, mirrors the Character tab's).
  DamageCategory _dmgCategory = DamageCategory.standard;
  ParryOption _dmgParry = ParryOption.none;
  int _dmgReduction = 0;
  int _dmgWoundRoll = 0;

  final _modifyLifeController = TextEditingController();
  final _modifyKiController = TextEditingController();
  final _healingSurgeRollController = TextEditingController();

  /// Live filter for the Maneuvers Reference card.
  final _maneuverSearchController = TextEditingController();
  String _maneuverQuery = '';

  @override
  void initState() {
    super.initState();
    _c = widget.character;
    _stats = CharacterCalculator.compute(_c);
  }

  @override
  void dispose() {
    _modifyLifeController.dispose();
    _modifyKiController.dispose();
    _healingSurgeRollController.dispose();
    _maneuverSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Applies a mutation to the shared working copy and recomputes — running
  /// the same additive sync helpers as the edit screen's recompute, since
  /// this page hosts the Information/Transformations tabs too (a Trait
  /// picked mid-combat must still auto-add its granted Resources).
  void _update(VoidCallback mutate) {
    setState(() {
      mutate();
      ensureRaceGrantedResources(_c);
      ensureProgressionTalentsInTalentList(_c);
      _stats = CharacterCalculator.compute(_c);
    });
  }

  String _fmt(int n) => n >= 0 ? '+$n' : '$n';

  int get _baseTier => CharacterCalculator.baseTierOfPower(_c);

  /// Live-annotates every N(T)/N(bT) token in verbatim rule text.
  String _annotate(String text) =>
      annotateRuleText(text, tier: _stats.tierOfPower, baseTier: _baseTier);

  // ==========================================================================
  // Reminders (scanned traits/abilities + battlefield picks)
  // ==========================================================================

  /// Reminders from the selected Battle Weather / Environment (their
  /// verbatim effects contain the same timing phrases the scanner reads).
  List<CombatReminder> _battlefieldReminders() {
    final reminders = <CombatReminder>[];
    void add(String source, String title, String text) {
      reminders.addAll(CombatReminderScanner.remindersFromText(
        source: source,
        title: title,
        text: text,
        tier: _stats.tierOfPower,
        baseTier: _baseTier,
      ));
    }

    final weather = _weather;
    if (weather != null) {
      // "Each Tier gains the effects of the earlier Tiers."
      add(
        'Battle Weather',
        '${weather.name} — ${kWeatherTierNames[_weatherTier - 1]}',
        weather.tierEffects.take(_weatherTier).join('\n'),
      );
    }
    final environment = _environment;
    if (environment != null) {
      add('Battle Environment', environment.name, environment.effects);
      for (final quality in kDbuEnvironmentalQualities) {
        if (environment.effects.contains('${quality.title} Environmental')) {
          add('Environmental Quality', quality.title, quality.text);
        }
      }
      if (environment.isHigh) {
        add('Battle Environment', '${environment.name} — Falling',
            kFallingText);
      }
      if (environment.effects.contains('Unbreathable')) {
        add('Battle Environment', '${environment.name} — Unbreathable',
            kUnbreathableText);
      }
    }
    return reminders;
  }

  /// All reminders for the given timings, in display order.
  /// Reminders for [timings], with Round-cadence effects ("at the start of
  /// every even-numbered Combat Round" — Born for Battle etc.) annotated
  /// when the current Round's parity doesn't match. [forRound] overrides the
  /// Round the parity is checked against (the Start of Round popup fires
  /// BEFORE the Round counter increments).
  List<CombatReminder> _remindersFor(List<CombatTiming> timings,
      {int? forRound}) {
    final all = [...CombatReminderScanner.scan(_c), ..._battlefieldReminders()];
    final round = forRound ?? _round;
    final result = <CombatReminder>[];
    for (final timing in timings) {
      for (final r in all) {
        if (r.timing != timing) continue;
        final parity = CombatReminderScanner.roundParity(r.text);
        if (parity == null || round <= 0 || (round.isEven == parity)) {
          result.add(r);
        } else {
          result.add(CombatReminder(
            source: r.source,
            title: r.title,
            timing: r.timing,
            text: '${r.text}\n(Not this Round: fires on '
                '${parity ? 'even' : 'odd'}-numbered Combat Rounds, and '
                'Round $round is ${round.isEven ? 'even' : 'odd'}.)',
          ));
        }
      }
    }
    return result;
  }

  // ==========================================================================
  // Phase flow
  // ==========================================================================

  /// Advances to the next phase, applying the round-boundary automation and
  /// popping up the new phase's reminders.
  void _advancePhase() {
    final next = _phase.next;
    // Gather the popup's reminders BEFORE the automation below mutates
    // anything — entering a new Round clears the Diminishing trackers, and
    // the popup should still tell the player that just happened. (The Round
    // counter hasn't incremented yet, so parity checks look 1 ahead.)
    final popupReminders = _remindersFor(
      CombatReminderScanner.timingsForPhase(next),
      forRound: next == CombatPhase.startOfRound ? _round + 1 : null,
    );
    final messages = <String>[];
    setState(() {
      if (next == CombatPhase.startOfRound) {
        _round += 1;
        final reduced = _reducedMomentumPending ? 1 : 0;
        _actions = 3 - reduced;
        _counterActions = 1;
        messages.add('Round $_round: Actions reset to $_actions'
            '${reduced > 0 ? ' (Reduced Momentum)' : ''}, Counter Actions '
            'to 1.');
        _reducedMomentumPending = false;
        _attacksThisRound = 0;
        _bonusMomentumUsed = false;
        if (_c.capacitySpent > 0) {
          messages.add('Capacity reset to Max.');
        }
        _c.capacitySpent = 0;
        if (_c.diminishingOffenseStacks > 0 ||
            _c.diminishingDefenseStacks > 0) {
          messages.add('Diminishing Offense/Defense stacks cleared.');
        }
        _c.diminishingOffenseStacks = 0;
        _c.diminishingDefenseStacks = 0;
        _stats = CharacterCalculator.compute(_c);
      }
      _phase = next;
    });
    if (messages.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(messages.join(' '))));
    }
    _showPhaseReminderPopup(next, popupReminders);
  }

  /// Jumps straight to a phase (no automation) — for correcting the tracker.
  void _jumpToPhase(CombatPhase phase) {
    if (phase == _phase) return;
    setState(() {
      _phase = phase;
      if (_round == 0 && phase != CombatPhase.startOfCombat) _round = 1;
    });
  }

  /// Pops up the reminders relevant to the phase just entered ([reminders]
  /// are gathered by the caller BEFORE any phase automation runs).
  void _showPhaseReminderPopup(
      CombatPhase phase, List<CombatReminder> reminders) {
    if (reminders.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${phase.displayName} — Reminders'),
        content: SizedBox(
          width: 480,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final r in reminders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _reminderTile(r),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// The End Combat dialog: verbatim end-of-encounter rules, any
  /// end-of-encounter reminders, and a one-tap cleanup.
  void _endCombat() {
    final reminders = _remindersFor(const [CombatTiming.endOfEncounter]);
    final lifeBack = _stats.maxLife ~/ 10;
    final kiBack = _stats.maxKi ~/ 10;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Combat'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final rule in kCombatEndOfEncounterRules) ...[
                Text(rule.title,
                    style: Theme.of(context).textTheme.titleSmall),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 2),
                  child: Text(_annotate(rule.text),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
              if (reminders.isNotEmpty) ...[
                const Divider(),
                Text('Your end-of-combat reminders',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                for (final r in reminders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _reminderTile(r),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep fighting'),
          ),
          FilledButton(
            onPressed: () {
              _update(() {
                // Instant Recovery: +1/10th Max Life and Ki.
                final life = _c.currentLife ?? _stats.maxLife;
                _c.currentLife = (life + lifeBack).clamp(0, _stats.maxLife);
                final ki = _c.currentKi ?? _stats.maxKi;
                _c.currentKi = (ki + kiBack).clamp(0, _stats.maxKi);
                // "All Resources are lost."
                _c.powerStacks = 0;
                _c.superStacks = 0;
                _c.holdingBackStacks = 0;
                _c.diminishingOffenseStacks = 0;
                _c.diminishingDefenseStacks = 0;
                for (final r in _c.resources) {
                  r.stacks = 0;
                }
                // "All effects triggered during that Combat Encounter
                // immediately end" — tracked Conditions/States clear.
                for (final entry in _c.conditions) {
                  entry.stacks = 0;
                }
                for (final entry in _c.states) {
                  entry.stacks = 0;
                }
              });
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(); // combat screen
            },
            child: Text('Apply & leave (+$lifeBack Life, +$kiBack Ki, '
                'Resources/Conditions/States cleared)'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Build
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Combat — ${_c.displayName}'),
        actions: [
          TextButton.icon(
            onPressed: _endCombat,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('End Combat'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Combat', icon: Icon(Icons.timelapse)),
            Tab(
                text: 'Attacking Maneuver',
                icon: Icon(Icons.sports_martial_arts)),
            Tab(text: 'Information', icon: Icon(Icons.info_outline)),
            Tab(text: 'Transformations', icon: Icon(Icons.bolt)),
            Tab(text: 'Inventory', icon: Icon(Icons.backpack_outlined)),
            Tab(text: 'Signatures', icon: Icon(Icons.auto_awesome)),
            Tab(
                text: 'Unique Abilities',
                icon: Icon(Icons.psychology_alt_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // The tracker itself, with the phase bar pinned above its scroll.
          Column(
            children: [
              Material(elevation: 1, child: _phaseBar()),
              Expanded(child: _buildTrackerBody()),
            ],
          ),
          _buildAttackingManeuverTab(),
          InformationTab(character: _c, stats: _stats, onUpdate: _update),
          TransformationsTab(character: _c, stats: _stats, onUpdate: _update),
          InventoryTab(character: _c, stats: _stats, onUpdate: _update),
          SignaturesTab(character: _c, stats: _stats, onUpdate: _update),
          UniqueAbilitiesTab(character: _c, stats: _stats, onUpdate: _update),
        ],
      ),
    );
  }

  Widget _buildTrackerBody() {
    return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _twoColumnBreakpoint) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ..._leftSections(),
                    ..._rightSections(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
          // Wide window: one shared scroll view over two columns, same
          // pattern as the Character tab.
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
                          ..._leftSections(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ..._rightSections(),
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

  /// Minimum width at which the page splits into two columns (same
  /// breakpoint as the Character tab).
  static const double _twoColumnBreakpoint = 1000;

  /// Left column / start of the single-column order: the phase flow and the
  /// two "what's happening right now" cards.
  List<Widget> _leftSections() => [
        _buildPhaseCard(),
        _buildActionEconomy(),
        _buildAttackingCard(),
        _buildDefendingCard(),
      ];

  /// Right column: trackers and reference material.
  List<Widget> _rightSections() => [
        _buildStatusCard(),
        _buildCustomBuffsCard(),
        _buildResourcesCard(),
        _buildConditionsCard(),
        _buildStatesCard(),
        _buildBattlefieldCard(),
        _buildManeuversCard(),
      ];

  // ==========================================================================
  // Phase bar
  // ==========================================================================

  Widget _phaseBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          // The advance button leads so it's always on-screen, even on
          // phone widths where the phase chips scroll.
          FilledButton.icon(
            onPressed: _advancePhase,
            icon: const Icon(Icons.skip_next),
            label: Text('Next: ${_phase.next.displayName}'),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(_round == 0 ? 'Not started' : 'Round $_round'),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          for (final phase in CombatPhase.values) ...[
            if (phase != CombatPhase.startOfCombat)
              const Icon(Icons.arrow_right_alt, size: 18),
            ChoiceChip(
              label: Text(phase.displayName),
              selected: _phase == phase,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => _jumpToPhase(phase),
            ),
          ],
          const Icon(Icons.replay, size: 16),
        ],
      ),
    );
  }

  // ==========================================================================
  // Phase card (verbatim rules + scanned reminders)
  // ==========================================================================

  Widget _buildPhaseCard() {
    final timings = CombatReminderScanner.timingsForPhase(_phase);
    final reminders = _remindersFor(timings);
    return SectionCard(
      title: _round == 0
          ? _phase.displayName
          : '${_phase.displayName} — Round $_round',
      icon: Icons.timelapse,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_phase == CombatPhase.startOfCombat) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DerivedStat(
                  label: 'Initiative Bonus',
                  value: _fmt(_stats.initiative),
                  emphasize: true,
                  tooltip: 'Roll your Base Die (1d10) and increase the Dice '
                      'Score by 1/2 of your Agility Score — no Critical '
                      'Result possible.',
                ),
                DerivedStat(
                    label: 'Speed (Normal)', value: '${_stats.speedNormal}'),
                DerivedStat(
                    label: 'Speed (Boosted)', value: '${_stats.speedBoosted}'),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Reminders first — they're the point of this page.
          Text('Your reminders', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (reminders.isEmpty)
            Text(
              'Nothing you possess names this timing — no reminders.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final r in reminders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _reminderTile(r),
              ),
          const Divider(height: 20),
          Text('Rules for this phase',
              style: Theme.of(context).textTheme.titleSmall),
          for (final rule in kCombatPhaseRules[_phase]!) _ruleTile(rule),
        ],
      ),
    );
  }

  /// One scanned reminder: source + name header, verbatim sentence(s) below.
  Widget _reminderTile(CombatReminder reminder) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '${reminder.source} · ',
                style: theme.textTheme.labelSmall,
              ),
              TextSpan(
                text: reminder.title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(reminder.text, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// One verbatim phase rule as a collapsed expansion row.
  Widget _ruleTile(CombatRuleEntry rule) {
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(rule.title, style: Theme.of(context).textTheme.bodyMedium),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_annotate(rule.text),
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

  // ==========================================================================
  // Action economy
  // ==========================================================================

  Widget _buildActionEconomy() {
    return SectionCard(
      title: 'Actions this Round',
      icon: Icons.flash_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Actions',
                  value: _actions,
                  min: 0,
                  max: 9,
                  onChanged: (v) => setState(() => _actions = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  label: 'Counter Actions',
                  value: _counterActions,
                  min: 0,
                  max: 9,
                  onChanged: (v) => setState(() => _counterActions = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Convert Action → Counter'),
                onPressed: _actions > 0
                    ? () => setState(() {
                          _actions -= 1;
                          _counterActions += 1;
                        })
                    : null,
              ),
              Tooltip(
                message: kBonusMomentumText,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(_bonusMomentumUsed
                      ? 'Bonus Momentum used'
                      : 'Bonus Momentum (+1 Action)'),
                  onPressed: _bonusMomentumUsed
                      ? null
                      : () => setState(() {
                            _actions += 1;
                            _bonusMomentumUsed = true;
                          }),
                ),
              ),
              Tooltip(
                message: kReducedMomentumText,
                child: FilterChip(
                  label: const Text('Reduced Momentum next Round'),
                  selected: _reducedMomentumPending,
                  onSelected: (v) =>
                      setState(() => _reducedMomentumPending = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Status (pools + surges)
  // ==========================================================================

  Widget _buildStatusCard() {
    return SectionCard(
      title: 'Status',
      icon: Icons.favorite_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _numberField(
                  label: 'Life (${_stats.healthStatus})',
                  value: _stats.currentLife,
                  min: 0,
                  max: _stats.maxLife,
                  onChanged: (v) => _update(
                      () => _c.currentLife = v.clamp(0, _stats.maxLife)),
                ),
              ),
              const SizedBox(width: 8),
              DerivedStat(label: 'Max', value: '${_stats.maxLife}'),
            ],
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
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _numberField(
                  label: 'Ki',
                  value: _stats.currentKi,
                  min: 0,
                  max: _stats.maxKi,
                  onChanged: (v) =>
                      _update(() => _c.currentKi = v.clamp(0, _stats.maxKi)),
                ),
              ),
              const SizedBox(width: 8),
              DerivedStat(label: 'Max', value: '${_stats.maxKi}'),
            ],
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
            children: [
              Expanded(
                flex: 3,
                child: _numberField(
                  label: 'Capacity Spent',
                  value: _c.capacitySpent,
                  min: 0,
                  max: _stats.maxCapacity,
                  onChanged: (v) => _update(() => _c.capacitySpent = v),
                ),
              ),
              const SizedBox(width: 8),
              DerivedStat(
                label: 'Left / Max',
                value: '${_stats.currentCapacity} / ${_stats.maxCapacity}',
                emphasize: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Power Stacks',
                  value: _c.powerStacks,
                  min: 0,
                  max: DefaultResourceRules.maxPowerStacks,
                  onChanged: (v) => _update(() => _c.powerStacks = v),
                ),
              ),
              const SizedBox(width: 8),
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
          if (_stats.healthThresholdPenalty > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DerivedStat(
                label: 'Health Threshold Penalty',
                value: _fmt(-_stats.healthThresholdPenalty),
                warn: true,
                tooltip: 'Failed Steadfast Checks — tracked on the Character '
                    'tab.',
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text('Surges', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Surge Maneuver [1/Encounter] (Instant): use either '
                    'a Healing Surge or a Ki Surge.',
                child: FilterChip(
                  label: const Text('Surge Maneuver used'),
                  selected: _surgeManeuverUsed,
                  onSelected: (v) => setState(() => _surgeManeuverUsed = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
              const SizedBox(width: 8),
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
            children: [
              Expanded(
                child: DerivedStat(
                  label: 'Power Surge Ki',
                  value: '+${_stats.powerSurgeKi}',
                ),
              ),
              const SizedBox(width: 8),
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
                  _c.capacitySpent =
                      (_c.capacitySpent - _stats.powerSurgeCapacity)
                          .clamp(0, _stats.maxCapacity);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Custom Buffs & Debuffs (toggle mid-combat; edit on the Character tab)
  // ==========================================================================

  /// The character's Custom Buffs, each with a live Active toggle so the
  /// player can flip situational buffs/debuffs on and off mid-fight — every
  /// toggle recomputes the derived stats (and therefore the rolls on the
  /// Attacking / Being-Attacked cards and the Attacking Maneuver tab). Full
  /// authoring (targets, magnitudes) stays on the Character tab.
  Widget _buildCustomBuffsCard() {
    return SectionCard(
      title: 'Custom Buffs & Debuffs',
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_c.customBuffs.isEmpty)
            Text(
              'No Custom Buffs yet — add them on the Character tab; they show '
              'here so you can toggle them on and off mid-combat.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final buff in _c.customBuffs) _customBuffToggleRow(buff),
        ],
      ),
    );
  }

  Widget _customBuffToggleRow(CustomBuff buff) {
    final theme = Theme.of(context);
    final total = CharacterCalculator.customBuffTotal(_c, buff);
    final name = buff.name.trim().isEmpty ? '(unnamed)' : buff.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Switch(
            value: buff.active,
            onChanged: (v) => _update(() => buff.active = v),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                Text(
                  buff.target.isAutomated
                      ? buff.target.displayName
                      : '${buff.target.displayName} · manual',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DerivedStat(label: 'Total', value: _fmt(total)),
        ],
      ),
    );
  }

  // ==========================================================================
  // Tracked lists: Resources / Conditions / States
  // ==========================================================================

  /// Sentinel shown in the catalogue dropdowns for a freeform entry.
  static const String _customCatalogEntry = 'Custom…';

  Widget _buildResourcesCard() {
    return SectionCard(
      title: 'Resources',
      icon: Icons.bolt_outlined,
      trailing: IconButton(
        tooltip: 'Add Resource row',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _update(() => _c.resources.add(TrackedEntry())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      : '−${CharacterCalculator.holdingBackStacks(_c)} Tier '
                          'of Power, '
                          '+${CharacterCalculator.holdingBackStacks(_c).clamp(0, 3)} '
                          'Concealment',
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (_c.resources.isEmpty)
            Text('No other Resources tracked yet.',
                style: Theme.of(context).textTheme.bodySmall),
          for (var i = 0; i < _c.resources.length; i++)
            _freeformResourceRow(i),
        ],
      ),
    );
  }

  /// One freeform Resource row (name + stacks/max + delete). The name field
  /// is keyed so a middle-row delete never leaves stale text behind.
  Widget _freeformResourceRow(int index) {
    final entry = _c.resources[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              // Keyed by row IDENTITY (not by the name being typed, which
              // would remount — and drop the cursor — on every keystroke):
              // a middle-row delete remounts the survivors correctly.
              key: ValueKey(('combat-res-name', entry)),
              initialValue: entry.name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _update(() => entry.name = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _numberField(
              label: 'Stacks',
              value: entry.stacks,
              min: 0,
              max: entry.maxStacks,
              onChanged: (v) => _update(() => entry.stacks = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _numberField(
              label: 'Max',
              value: entry.maxStacks,
              min: 1,
              max: 999,
              onChanged: (v) => _update(() {
                entry.maxStacks = v;
                if (entry.stacks > v) entry.stacks = v;
              }),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _update(() => _c.resources.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsCard() {
    return _catalogTrackedCard(
      title: 'Conditions',
      icon: Icons.sick_outlined,
      entries: _c.conditions,
      catalog: [...kDbuConditions, ...HomebrewRegistry.conditionDefs()],
      lookupByName: HomebrewRegistry.resolveConditionDef,
      stacksLabel: 'Stacks',
      automatedEffectText: (entry, def) {
        final condition = def as ConditionDef;
        final penalty = CharacterCalculator.conditionPenalty(_c, entry);
        return '${_fmt(-penalty)} '
            '${condition.affectedStats.map((s) => s.displayName).join(', ')}';
      },
    );
  }

  Widget _buildStatesCard() {
    return _catalogTrackedCard(
      title: 'States',
      icon: Icons.local_fire_department_outlined,
      entries: _c.states,
      catalog: [...kDbuStates, ...HomebrewRegistry.stateDefs()],
      lookupByName: HomebrewRegistry.resolveStateDef,
      stacksLabel: 'Level',
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
  }

  /// A compact catalogue-backed tracker (Conditions/States): dropdown pick,
  /// stacks stepper, live automated-effect readout, delete. Same machinery
  /// as the Character tab's tracked lists (adding one here immediately feeds
  /// the phase reminders); full notes editing stays on the Character tab.
  Widget _catalogTrackedCard({
    required String title,
    required IconData icon,
    required List<TrackedEntry> entries,
    required List<CatalogDef> catalog,
    required CatalogDef? Function(String name) lookupByName,
    required String stacksLabel,
    required String Function(TrackedEntry entry, CatalogDef def)
        automatedEffectText,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entries.isEmpty)
            Text('No $title tracked.',
                style: Theme.of(context).textTheme.bodySmall),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          // Row-identity key: without it, deleting a middle
                          // row leaves the next row's dropdown showing the
                          // DELETED row's pick (FormField state is element-
                          // local and initialValue only seeds on mount).
                          key: ObjectKey(entries[i]),
                          initialValue: catalog
                                  .any((d) => d.name == entries[i].name)
                              ? entries[i].name
                              : _customCatalogEntry,
                          decoration: InputDecoration(
                            labelText: title.substring(0, title.length - 1),
                            border: const OutlineInputBorder(),
                            isDense: true,
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
                              entries[i].name = '';
                              entries[i].notes = '';
                              entries[i].maxStacks = 1;
                              return;
                            }
                            final def = lookupByName(v)!;
                            entries[i].name = def.name;
                            entries[i].maxStacks = def.maxStacks;
                            entries[i].notes = def.description;
                            if (entries[i].stacks > def.maxStacks) {
                              entries[i].stacks = def.maxStacks;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _numberField(
                          label: stacksLabel,
                          value: entries[i].stacks,
                          min: 0,
                          max: entries[i].maxStacks,
                          onChanged: (v) =>
                              _update(() => entries[i].stacks = v),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            _update(() => entries.removeAt(i)),
                      ),
                    ],
                  ),
                  if (!catalog.any((d) => d.name == entries[i].name))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextFormField(
                        // Row identity, not the typed name (see above).
                        key: ValueKey(('combat-tracked-name', entries[i])),
                        initialValue: entries[i].name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            _update(() => entries[i].name = v),
                      ),
                    )
                  else if (lookupByName(entries[i].name) case final def?)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: def.isAutomated
                          ? DerivedStat(
                              label: 'Automated effect',
                              value: automatedEffectText(entries[i], def),
                            )
                          : Text(
                              'Not automated — apply it yourself when it '
                              'matters (its timing shows up in the phase '
                              'reminders).',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Attacking
  // ==========================================================================

  /// The Attacking Maneuver tab: the effects that trigger on an attack, then
  /// the full Attack Reference calculator in combat mode (Ki/Capacity/Wager
  /// warnings + a "Attack made" button that spends the Ki and counts the
  /// attack). Its own tab so it stays open beside the tracker.
  Widget _buildAttackingManeuverTab() {
    final reminders = CombatReminderScanner.attackTriggerReminders(_c);
    final remindersCard = SectionCard(
      title: 'Triggers on an Attacking Maneuver',
      icon: Icons.notifications_active_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reminders.isEmpty)
            Text(
              'Nothing you possess names an attack, an Attacking Maneuver, or '
              'a Signature Technique — no reminders.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            for (final r in reminders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _reminderTile(r),
              ),
        ],
      ),
    );
    // The calculator reads live stats, so it always reflects the latest
    // Ki/Capacity after an "Attack made" deduction (the tab rebuilds with
    // fresh `_stats`).
    return ReferencesTab(
      character: _c,
      stats: _stats,
      leadingCard: remindersCard,
      onAttackMade: _onAttackMade,
    );
  }

  /// Resolves an attack from the Attack Reference: spends [kiSpent] (Ki Cost +
  /// Ki Wager) from Current Ki and Capacity, then counts the Attacking
  /// Maneuver for Diminishing Offense.
  void _onAttackMade(int kiSpent) {
    var gainedStack = false;
    _update(() {
      if (kiSpent > 0) {
        final ki = _c.currentKi ?? _stats.maxKi;
        _c.currentKi = (ki - kiSpent).clamp(0, _stats.maxKi);
        _c.capacitySpent =
            (_c.capacitySpent + kiSpent).clamp(0, _stats.maxCapacity);
      }
      gainedStack = _countAttack();
    });
    final parts = <String>[
      if (kiSpent > 0) 'Spent $kiSpent Ki & Capacity',
      'Attack #$_attacksThisRound',
      if (gainedStack)
        '+1 Diminishing Offense (now ${_c.diminishingOffenseStacks}, '
            '${_fmt(-CharacterCalculator.diminishingOffensePenalty(_c))} Strike)',
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(parts.join(' · '))));
  }

  /// Counts one Attacking Maneuver made this Round — "for each Attacking
  /// Maneuver you make after your third during this Combat Round, gain a
  /// stack of Diminishing Offense." Returns whether a stack was gained. Call
  /// inside an [_update].
  bool _countAttack() {
    _attacksThisRound += 1;
    if (_attacksThisRound > 3) {
      _c.diminishingOffenseStacks += 1;
      return true;
    }
    return false;
  }

  /// The "Count an attack" button (attacks resolved without the Reference,
  /// so no Ki is deducted).
  void _recordAttack() {
    var gainedStack = false;
    _update(() => gainedStack = _countAttack());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(gainedStack
            ? 'Attack #$_attacksThisRound — +1 Diminishing Offense stack '
                '(now ${_c.diminishingOffenseStacks}, '
                '${_fmt(-CharacterCalculator.diminishingOffensePenalty(_c))} Strike).'
            : 'Attack #$_attacksThisRound recorded — no Diminishing Offense '
                'until after your third.'),
      ));
  }

  Widget _buildAttackingCard() {
    final offensePenalty = CharacterCalculator.diminishingOffensePenalty(_c);
    return SectionCard(
      title: 'I’m Attacking',
      icon: Icons.sports_mma,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                  label: 'Strike',
                  value: '${_stats.strikeDice}${_stats.strike.label}'),
              DerivedStat(
                  label: 'Wound (Physical)',
                  value: '${_stats.woundDice}${_stats.woundPhysical.label}'),
              DerivedStat(
                  label: 'Wound (Energy)',
                  value: '${_stats.woundDice}${_stats.woundEnergy.label}'),
              DerivedStat(
                  label: 'Wound (Magic)',
                  value: '${_stats.woundDice}${_stats.woundMagic.label}'),
              DerivedStat(
                label: 'Max Ki Wager',
                value: '${_stats.maxCapacity ~/ 2}',
                tooltip: kKiWagerText,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.sports_martial_arts),
                  label: const Text('Make an Attacking Maneuver'),
                  onPressed: () =>
                      _tabController.animateTo(_attackTabIndex),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _recordAttack,
                child: Text('Count an attack '
                    '($_attacksThisRound this Round)'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Diminishing Offense',
                value:
                    '${_c.diminishingOffenseStacks} (${_fmt(-offensePenalty)} '
                    'Strike)',
                warn: offensePenalty > 0,
                tooltip: kDiminishingOffenseText,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '“Make an Attacking Maneuver” switches to the Attacking Maneuver '
            'tab — the full Attack Reference (Profiles, Signatures, Energy '
            'Charges, Ki Costs, copyable roll strings) plus your on-attack '
            'reminders; finishing it there with “Attack made” spends its Ki & '
            'Capacity and counts it for Diminishing Offense. Use “Count an '
            'attack” for attacks resolved without the Reference.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          _referenceExpansion('Ki Wager', kKiWagerText),
          _referenceExpansion('Energy Charges', kEnergyChargesText),
          _referenceExpansion('Long Range', kLongRangeText),
          _referenceExpansion('Bonus Momentum', kBonusMomentumText),
        ],
      ),
    );
  }

  // ==========================================================================
  // Being attacked
  // ==========================================================================

  Widget _buildDefendingCard() {
    final defensePenalty = CharacterCalculator.diminishingDefensePenalty(_c);
    final perHit = CharacterCalculator.diminishingDefenseStacksPerHit(_c);
    final defend = kDbuCounterManeuvers
        .firstWhere((m) => m.name == 'Defend Maneuver');
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
      armoredAspect: _stats.hasArmoredAspect,
      beingBludgeoned: _stats.beingBludgeoned,
    );
    return SectionCard(
      title: 'I’m Being Attacked',
      icon: Icons.shield_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                  label: 'Dodge',
                  value: '${_stats.dodgeDice}${_stats.dodge.label}'),
              DerivedStat(
                  label: 'Defense Value', value: '${_stats.defenseValue}'),
              DerivedStat(label: 'Soak', value: '${_stats.soak}'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.gpp_maybe_outlined),
                  label: Text('I was targeted by an attack '
                      '(+$perHit Diminishing Defense)'),
                  onPressed: () {
                    _update(() => _c.diminishingDefenseStacks += perHit);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('+$perHit Diminishing Defense stack'
                            '${perHit == 1 ? '' : 's'} '
                            '(now ${_c.diminishingDefenseStacks}, '
                            '${_fmt(-CharacterCalculator.diminishingDefensePenalty(_c))} Dodge). '
                            'No stacks if you responded with the Defend '
                            'Maneuver.'),
                      ));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Diminishing Defense',
                value: '${_c.diminishingDefenseStacks} '
                    '(${_fmt(-defensePenalty)} Dodge)',
                warn: defensePenalty > 0,
                tooltip: kDiminishingDefenseText,
              ),
            ],
          ),
          _referenceExpansion(
            'Defend Maneuver (1 Counter — Parry / Direct Hit / Power Flare / '
            'Cross Counter / Guard)',
            defend.effect,
          ),
          const Divider(height: 24),
          Text('Damage Calculator',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
                'Includes +$autoReduction Damage Reduction from your '
                'Inventory/Traits automatically.',
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
              const SizedBox(width: 8),
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
                  _c.currentLife = (current - result.healthReduction)
                      .clamp(0, _stats.maxLife);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Battlefield (Weather / Environment / Light)
  // ==========================================================================

  Widget _buildBattlefieldCard() {
    final environment = _environment;
    final weather = _weather;
    return SectionCard(
      title: 'Battlefield',
      icon: Icons.terrain_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick what the ARC declared — the effects below feed this '
            'page’s phase reminders. Not saved with the character.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<BattleWeatherDef?>(
                  initialValue: weather,
                  decoration: const InputDecoration(
                    labelText: 'Battle Weather',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    for (final w in kDbuBattleWeathers)
                      DropdownMenuItem(value: w, child: Text(w.name)),
                  ],
                  onChanged: (v) => setState(() => _weather = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _numberField(
                  label: 'Weather Tier',
                  value: _weatherTier,
                  min: 1,
                  max: 3,
                  onChanged: (v) => setState(() => _weatherTier = v),
                ),
              ),
            ],
          ),
          if (weather != null) ...[
            const SizedBox(height: 4),
            Text(
              '${kWeatherTierNames[_weatherTier - 1]} · Connected Profile: '
              '${weather.connectedProfile}. Each Tier gains the effects of '
              'the earlier Tiers.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            for (var tier = 0; tier < _weatherTier; tier++)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${kWeatherTierNames[tier]}: '
                  '${_annotate(weather.tierEffects[tier])}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<BattleEnvironmentDef?>(
            initialValue: environment,
            decoration: const InputDecoration(
              labelText: 'Battle Environment',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              for (final e in kDbuBattleEnvironments)
                DropdownMenuItem(
                  value: e,
                  child: Text(e.isHigh ? '${e.name} (High)' : e.name),
                ),
            ],
            onChanged: (v) => setState(() => _environment = v),
          ),
          if (environment != null) ...[
            const SizedBox(height: 4),
            Text('Hardness Rank: ${environment.hardnessRank}',
                style: Theme.of(context).textTheme.labelSmall),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_annotate(environment.effects),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            for (final quality in kDbuEnvironmentalQualities)
              if (environment.effects
                  .contains('${quality.title} Environmental'))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${quality.title}: ${_annotate(quality.text)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<LightLevelDef?>(
            initialValue: _light,
            decoration: const InputDecoration(
              labelText: 'Light Level',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Unset')),
              for (final l in kDbuLightLevels)
                DropdownMenuItem(value: l, child: Text(l.name)),
            ],
            onChanged: (v) => setState(() => _light = v),
          ),
          if (_light != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_annotate(_light!.effect),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          _referenceExpansion(
            'Environmental Qualities (reference)',
            [
              for (final q in kDbuEnvironmentalQualities)
                '${q.title}: ${q.text}',
            ].join('\n'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Maneuver reference catalogue
  // ==========================================================================

  Widget _buildManeuversCard() {
    return SectionCard(
      title: 'Maneuvers Reference',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search maneuvers',
              hintText: 'Name or effect text…',
              border: const OutlineInputBorder(),
              isDense: true,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _maneuverQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _maneuverQuery = '';
                        _maneuverSearchController.clear();
                      }),
                    ),
            ),
            controller: _maneuverSearchController,
            onChanged: (v) => setState(() => _maneuverQuery = v.trim()),
          ),
          const SizedBox(height: 4),
          _maneuverGroup('Standard Maneuvers', kDbuStandardManeuvers),
          _maneuverGroup('Instant Maneuvers', kDbuInstantManeuvers),
          _maneuverGroup('Counter Maneuvers', kDbuCounterManeuvers),
          _maneuverGroup('Modifier Maneuvers', kDbuModifierManeuvers),
          _maneuverGroup(
            'Special Maneuvers',
            kDbuSpecialManeuvers,
            note: 'You cannot use any Special Maneuvers until you have '
                'gained access to them through an effect.',
          ),
          if (_maneuverQuery.isNotEmpty && !_anyManeuverMatches())
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'No maneuver matches "$_maneuverQuery".',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  /// Whether [m] matches the current search query (name first, then the
  /// rest of its printed text).
  bool _maneuverMatches(ManeuverDef m) {
    if (_maneuverQuery.isEmpty) return true;
    final q = _maneuverQuery.toLowerCase();
    return m.name.toLowerCase().contains(q) ||
        m.effect.toLowerCase().contains(q) ||
        m.flavor.toLowerCase().contains(q) ||
        (m.maneuverType?.toLowerCase().contains(q) ?? false);
  }

  bool _anyManeuverMatches() => [
        ...kDbuStandardManeuvers,
        ...kDbuInstantManeuvers,
        ...kDbuCounterManeuvers,
        ...kDbuModifierManeuvers,
        ...kDbuSpecialManeuvers,
      ].any(_maneuverMatches);

  Widget _maneuverGroup(String title, List<ManeuverDef> maneuvers,
      {String? note}) {
    final filtered = [
      for (final m in maneuvers)
        if (_maneuverMatches(m)) m,
    ];
    if (_maneuverQuery.isNotEmpty && filtered.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      // Re-key on the query so groups auto-expand while searching and
      // collapse again when the search is cleared.
      key: ValueKey('$title::${_maneuverQuery.isNotEmpty}'),
      initiallyExpanded: _maneuverQuery.isNotEmpty,
      title: Text(_maneuverQuery.isEmpty
          ? '$title (${maneuvers.length})'
          : '$title (${filtered.length}/${maneuvers.length})'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8),
      children: [
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(note,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ),
        for (final maneuver in filtered) _maneuverTile(maneuver),
      ],
    );
  }

  Widget _maneuverTile(ManeuverDef m) {
    final theme = Theme.of(context);
    final costLine = [
      if (m.maneuverType != null) m.maneuverType!,
      m.actionCost,
      'KP: ${_annotate(m.kpCost)}',
      if (m.limit != null) m.limit!,
      if (m.isSpecialModifier) 'Special Modifier',
    ].join(' · ');
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
      title: Text(m.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(costLine, style: theme.textTheme.labelSmall),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.flavor,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              if (m.minions != null)
                Text('Minions: ${m.minions}',
                    style: theme.textTheme.labelSmall),
              if (m.baseManeuver != null)
                Text('Base Maneuver: ${m.baseManeuver}',
                    style: theme.textTheme.labelSmall),
              if (m.exploitable != null)
                Text('Exploitable: ${m.exploitable}',
                    style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              Text(_annotate(m.effect), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // Shared input helpers (same idiom as the other screens)
  // ==========================================================================

  /// A collapsed verbatim reference block.
  Widget _referenceExpansion(String title, String text) {
    return ExpansionTile(
      dense: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_annotate(text),
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }

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

  Widget _numberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return _IntStepperField(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
    );
  }
}

/// A compact integer input with decrement/increment buttons — same pattern
/// as the Character/Progression tabs' private steppers.
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*$')),
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
                widget.onChanged(parsed.clamp(widget.min, widget.max));
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
