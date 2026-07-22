/// combat_flow.dart
/// ---------------------------------------------------------------------------
/// Static rules data for the COMBAT TRACKER page (see `ui/combat_screen.dart`):
///
///   • [CombatPhase] — the tracker's phase cycle: Start of Combat → Start of
///     Round → Start of Turn → End of Turn → (repeat from Start of Round).
///     The site structures a turn as Effect Phase / Act Phase / End Phase
///     (Combat Encounters page, "Turns"); the tracker's Start of Turn card is
///     the Effect Phase, its End of Turn card the End Phase, and the Act
///     Phase happens between them (the player just plays).
///   • [kCombatPhaseRules] / [kCombatEndOfRoundRules] /
///     [kCombatEndOfEncounterRules] — verbatim rule text shown on each phase
///     card, transcribed from the Combat Encounters, Actions & Maneuvers,
///     Attacking and Damage & Recovery pages (offline ZIM capture of
///     dbu-rpg.com, 2026-07-03). CONFIRMED verbatim.
///   • [ManeuverDef] + [kDbuStandardManeuvers] / [kDbuInstantManeuvers] /
///     [kDbuCounterManeuvers] / [kDbuModifierManeuvers] /
///     [kDbuSpecialManeuvers] — the complete Maneuver catalogue (Actions &
///     Maneuvers + Special Maneuvers pages), effects verbatim. A reference
///     catalogue with no automation, exactly like Basic Items — the (T)/(bT)
///     tokens in Action/KP costs and effects are annotated live in the UI via
///     `services/rule_text.dart`.
///   • [BattleWeatherDef] / [BattleEnvironmentDef] / [LightLevelDef]
///     catalogues (Battle Weather / Battle Environments / Light Levels
///     pages, verbatim) — picked ephemerally on the Combat page so their
///     effects can be surfaced as phase reminders.
///
/// Attack-economy one-liners used by the Combat page's Attacking/Defending
/// cards ([kKiWagerText], [kEnergyChargesText], [kDiminishingOffenseText],
/// [kDiminishingDefenseText], [kLongRangeText], [kBonusMomentumText],
/// [kReducedMomentumText]) are verbatim from the Attacking and Actions &
/// Maneuvers pages.
/// ---------------------------------------------------------------------------
library;

// ============================================================================
// Combat phases
// ============================================================================

/// The tracker's phase cycle. [next] advances Start of Combat → Start of
/// Round → Start of Turn → End of Turn → End of Round → Start of Round → …
/// (the round boundary — "end of the Combat Round" — gets its own phase
/// card, see `kCombatEndOfRoundRules`).
enum CombatPhase {
  startOfCombat('Start of Combat'),
  startOfRound('Start of Round'),
  startOfTurn('Start of Turn'),
  endOfTurn('End of Turn'),
  endOfRound('End of Round');

  const CombatPhase(this.displayName);

  final String displayName;

  /// The phase the tracker advances to next (never returns to Start of
  /// Combat — that only happens once per encounter).
  CombatPhase get next => switch (this) {
        CombatPhase.startOfCombat => CombatPhase.startOfRound,
        CombatPhase.startOfRound => CombatPhase.startOfTurn,
        CombatPhase.startOfTurn => CombatPhase.endOfTurn,
        CombatPhase.endOfTurn => CombatPhase.endOfRound,
        CombatPhase.endOfRound => CombatPhase.startOfRound,
      };
}

/// One titled verbatim rule paragraph shown on a phase card.
class CombatRuleEntry {
  const CombatRuleEntry(this.title, this.text);

  final String title;

  /// Verbatim rule text (site wording, unabridged).
  final String text;
}

/// Verbatim rules shown on each phase card (Combat Encounters + Actions &
/// Maneuvers pages).
const Map<CombatPhase, List<CombatRuleEntry>> kCombatPhaseRules = {
  CombatPhase.startOfCombat: [
    CombatRuleEntry(
      'Combat Structure',
      '1. Establishing Positions. The Architect and players decide and '
          'determine where the characters involved in the encounter are '
          'positioned at the start of the Combat Encounter.\n'
          '2. Rolling Initiative. All characters involved in a Combat '
          'Encounter must roll Initiative, determining the order of turns for '
          'each combatant.\n'
          '3. Taking Turns. In Initiative Order, all characters take their '
          'turns. Once a character has spent all of their Actions, their turn '
          'ends.\n'
          '4. Ending a Round. Once all combatants have taken their turn, the '
          'round ends and the second round begins. This continues until one '
          'side of the Combat Encounter is completely Defeated, or the Combat '
          'Encounter meets an alternative end.',
    ),
    CombatRuleEntry(
      'Initiative Check',
      'To make an Initiative Check, roll your Base Die and increase the Dice '
          'Score by 1/2 of your Agility Score — the Dice Score is your '
          'Initiative Value and decides your place in the Initiative Order '
          '(you cannot score a Critical Result on this). In the case of a tie '
          'among two Characters, the Character with the higher Agility Score '
          'will go first. If both combatants have the same Agility Score, '
          'both will roll a d10 and the highest result wins. If there is a '
          'further tie, the ARC decides which of the two goes first. All '
          'Initiative Checks are Urgent.',
    ),
    CombatRuleEntry(
      'Surprise Round',
      'A Surprise Round is a special version of the first Combat Round of a '
          'Combat Encounter that occurs when your guard is down. During a '
          'Surprise Round, Characters are individually marked as Surprised by '
          'the ARC. Each Surprised Character:\n'
          '• Suffers from the Guard Down and Slowed Combat Conditions for the '
          'duration of the Surprise Round.\n'
          '• Halves the Dice Score of their Initiative Check at the start of '
          'the Combat Encounter.',
    ),
    CombatRuleEntry(
      'Allies & Opponents',
      'When in a Combat Encounter, Characters other than your own are '
          'categorized into ‘Allies’ or ‘Opponents’. An '
          'Ally is a Character definitely on your side, striving towards the '
          'same objective or fighting against the same Opponent. An Opponent '
          'is any Character except your own that is not an Ally. A Character '
          'can become an Ally or an Opponent during a Combat Encounter — this '
          'has to be announced. You are not considered your own Ally or your '
          'own Opponent.',
    ),
  ],
  CombatPhase.startOfRound: [
    CombatRuleEntry(
      'Actions',
      'At the start of each Combat Round, all combatants gain 3 Actions. At '
          'the start of each Combat Round, all combatants gain 1 Counter '
          'Action. You can convert a Standard Action you possess into a '
          'Counter Action at any point during a Combat Round, even during '
          'other Maneuvers.',
    ),
    CombatRuleEntry(
      'Diminishing Defense',
      'At the start of each Combat Round, remove all stacks of Diminishing '
          'Defense.',
    ),
    CombatRuleEntry(
      'Reduced Momentum',
      'If you reduce your Life Points below a Health Threshold through your '
          'own effects, you gain 1 less Standard Action at the start of the '
          'next Combat Round. You can only suffer from Reduced Momentum once '
          'per Combat Round.',
    ),
  ],
  CombatPhase.startOfTurn: [
    CombatRuleEntry(
      'Effect Phase',
      'Before any Actions are spent, there are a few things you must track '
          'and certain effects that occur at the start of your turn. These '
          'things take almost no time in the game world and are simply '
          'mechanical effects.\n'
          '• Mechanical Effects: Deal with any effects that occur at the '
          'start of your turn (such as the Damage Over Time effect). You can '
          'decide the order in which they activate, if multiple occur at the '
          'same time.\n'
          '• Ending Effects: Some effects and mechanics might automatically '
          'end at the start of your turn. You can decide the order in which '
          'they end, if multiple occur at the same time.',
    ),
    CombatRuleEntry(
      'Damage Over Time (DOT)',
      'Some effects apply a stack of DOT to a Character over a period of '
          'time decided by the effect. For each stack of DOT you possess, '
          'reduce your Life Points by 1(bT) at the start of your turn.',
    ),
    CombatRuleEntry(
      'Act Phase',
      'You can spend Actions on a Maneuver to perform complex tasks ranging '
          'from solving a puzzle, transforming into complete badasses or, of '
          'course, rocking the socks off the bad guys. During the Act Phase, '
          'you can typically spend up to 3 Actions in a turn.',
    ),
    CombatRuleEntry(
      'Surrender',
      'At the start of their turn, a Character may attempt to Surrender. If '
          'all of their Opponents accept their Surrender, they are '
          'successful. A Character who successfully Surrenders is considered '
          'to have been Defeated for all of their Opponents’ effects and '
          'is removed from the Combat Encounter (allowing them to immediately '
          'flee the Battlefield).',
    ),
  ],
  CombatPhase.endOfTurn: [
    CombatRuleEntry(
      'End Phase',
      'The End Phase is identical to the Effects Phase but simply takes '
          'place at the end of your turn. You can willingly end your turn at '
          'any point during your turn before you spend your Actions, but '
          'otherwise your turn ends as soon as you run out of Actions. Track '
          'certain effects that occur at the end of your turn.\n'
          '• Mechanical Effects: Deal with any other effects that will occur '
          'during the end of your turn. You can decide the order in which '
          'they activate, if multiple occur at the same time.\n'
          '• Ending Effects: Some effects and mechanics might automatically '
          'stop at the end of your turn. You can decide the order in which '
          'they activate, if multiple occur at the same time.',
    ),
    CombatRuleEntry(
      'Hidden — Being Found',
      'If a Hidden Character ends their turn in the Melee Range of an '
          'Oblivious Character while there are no Features between them, they '
          'stop being Hidden for that Character.',
    ),
  ],
  CombatPhase.endOfRound: kCombatEndOfRoundRules,
};

/// The round boundary — shown on the End of Round phase card.
const List<CombatRuleEntry> kCombatEndOfRoundRules = [
  CombatRuleEntry(
    'Ending a Round',
    'Once all Characters have taken their turn during the Initiative Order, '
        'the Combat Round is over. Repeat the process starting with the '
        'highest Initiative until the Encounter is overcome or has ended.',
  ),
  CombatRuleEntry(
    'Losing Actions',
    'At the end of each Combat Round, you lose all Actions and Counter '
        'Actions you still possess.',
  ),
  CombatRuleEntry(
    'Diminishing Offense',
    'At the end of the Combat Round, lose all stacks of Diminishing Offense.',
  ),
  CombatRuleEntry(
    'Combat Round Effects',
    'Some effects will say that they last for x Combat Rounds (x being the '
        'number of Combat Rounds intended for them to last). When you see '
        'this effect, it means that the effects end at the end of the turn '
        'they started in (in terms of Initiative Order) after that amount of '
        'Combat Rounds have ended.',
  ),
];

/// Shown by the "End Combat" flow.
const List<CombatRuleEntry> kCombatEndOfEncounterRules = [
  CombatRuleEntry(
    'Ending a Combat Encounter',
    'Absolute Victory. The most common way to end a Combat Encounter is '
        'through simply defeating all of your Opponents. If no undefeated '
        'Opponents remain in the Combat Encounter, the Combat Encounter '
        'ends.\n'
        'Ceasefire. A ceasefire ending occurs when all Characters involved '
        'in the Combat Encounter simply agree that there’s no reason to '
        'keep fighting. This can be done at any time, but requires the '
        'complete acceptance of every Character in a Combat Encounter.\n'
        'Escape. It’s possible to simply escape from your Opponents. If '
        'you and all of your Allies are able to escape a Combat Encounter, '
        'then that Combat Encounter ends.',
  ),
  CombatRuleEntry(
    'At the end of a Combat Encounter',
    'When a Combat Encounter ends, all effects triggered during that Combat '
        'Encounter (except effects that choose something upon gaining access '
        'to a Transformation) immediately end and all Resources are lost. '
        'After ending a Combat Encounter, all involved Characters benefit '
        'from Instant Recovery and, at this point, your ARC may say that '
        'you’ve gained a Power Level, representing your growth as a '
        'result of that Combat Encounter.',
  ),
  CombatRuleEntry(
    'Instant Recovery',
    'After you have overcome a Combat Encounter, you will receive an instant '
        'reprieve; regain 1/10th of your Maximum Life Points and Ki Point '
        'Pool.',
  ),
];

// ============================================================================
// Attack-economy texts (Attacking + Actions & Maneuvers pages, verbatim)
// ============================================================================

const String kKiWagerText =
    'When making any form of Attacking Maneuver, you may make a Ki Wager by '
    'spending any amount of Ki Points up to 1/2 of your Max Capacity (you '
    'are still restricted by your current Capacity). Increase the Wound Roll '
    'for that Attacking Maneuver by an amount equal to the amount of Ki '
    'points spent.';

const String kEnergyChargesText =
    'Each Energy Charge gained increases the Wound Roll of an Attacking '
    'Maneuver by 1d6(T), or 1d8(T) if that Attacking Maneuver is a '
    'Signature Technique. The maximum number of Energy Charges an Attacking '
    'Maneuver can possess is 7.';

const String kDiminishingOffenseText =
    'During each Combat Round, for each Attacking Maneuver you make after '
    'your third during this Combat Round, gain a stack of Diminishing '
    'Offense. Each stack of Diminishing Offense reduces the Strike Rolls of '
    'your Attacking Maneuvers by 1(bT). At the end of the Combat Round, lose '
    'all stacks of Diminishing Offense.';

const String kDiminishingDefenseText =
    'After each Attacking Maneuver that has targeted you, gain a stack of '
    'Diminishing Defense - each stack of Diminishing Defense reduces the '
    'Dice Score of your Dodge Rolls by 1. Increase the number of Diminishing '
    'Defense stacks you gain by 1 for every 2 base Tier of Power reached '
    'after Tier of Power 1. At the start of each Combat Round, remove all '
    'stacks of Diminishing Defense.';

const String kLongRangeText =
    'Characters are considered to be at Long Range, from your '
    'Character’s perspective, if they are 9+ Squares away from your '
    'Character. Long Range Penalty: Reduce your Strike Rolls against any '
    'Character at Long Range by 2(bT).';

const String kBonusMomentumText =
    'You gain an additional Standard Action to spend if you knock an '
    'Opponent through a Health Threshold or Defeat a Minion with an '
    'Attacking Maneuver. You can only gain Bonus Momentum once per Combat '
    'Round.';

const String kReducedMomentumText =
    'If you reduce your Life Points below a Health Threshold through your '
    'own effects, you gain 1 less Standard Action at the start of the next '
    'Combat Round. You can only suffer from Reduced Momentum once per Combat '
    'Round.';

// ============================================================================
// Maneuver catalogue (Actions & Maneuvers + Special Maneuvers pages)
// ============================================================================

/// Which list a Maneuver belongs to on the site.
enum ManeuverKind {
  standard('Standard Maneuver'),
  instant('Instant Maneuver'),
  counter('Counter Maneuver'),
  modifier('Modifier Maneuver'),
  special('Special Maneuver');

  const ManeuverKind(this.displayName);

  final String displayName;
}

/// One Maneuver — a pure reference entry (no automation), effect verbatim.
class ManeuverDef {
  const ManeuverDef({
    required this.name,
    required this.kind,
    this.limit,
    this.maneuverType,
    required this.actionCost,
    required this.kpCost,
    this.exploitable,
    this.minions,
    this.baseManeuver,
    this.isSpecialModifier = false,
    this.costLabel = 'KP',
    required this.flavor,
    required this.effect,
  });

  final String name;
  final ManeuverKind kind;

  /// The site's `[x/Round]`/`[x/Encounter]` usage limit, or null (unlimited).
  final String? limit;

  /// For Special Maneuvers: the underlying "–Maneuver Type:" (Standard /
  /// Instant / Counter / Out-of-Sequence Maneuver).
  final String? maneuverType;

  /// Verbatim "–Action Cost:" line.
  final String actionCost;

  /// Verbatim "–KP Cost:" line ((T)/(bT) tokens annotated live in the UI).
  /// For God Maneuvers this holds the "–DKP Cost:" value instead (see
  /// [costLabel]).
  final String kpCost;

  /// Label shown before [kpCost] in the UI — 'KP' for normal Maneuvers,
  /// 'DKP' for God Maneuvers (which spend Divine Ki Points).
  final String costLabel;

  /// Verbatim "–Exploitable:" line, when the site lists one.
  final String? exploitable;

  /// For Special Maneuvers: the "–Minions:" line (Free / Non-Minion / N/A).
  final String? minions;

  /// For Modifier Maneuvers: the "–Base Maneuver:" line.
  final String? baseManeuver;

  /// True for the site's "Special Modifier Maneuvers" (access-gated, like
  /// Special Maneuvers).
  final bool isSpecialModifier;

  /// The italic descriptor after the Maneuver's name.
  final String flavor;

  /// Verbatim "–Effect:" text (including any sub-rules).
  final String effect;
}

/// Standard Maneuvers (everyone can use these). Verbatim.
const List<ManeuverDef> kDbuStandardManeuvers = [
  ManeuverDef(
    name: 'Arrogant Declaration Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Encounter',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Point your thumb at yourself and make a statement about your '
        'own superiority, emboldening you in the process.',
    effect: 'Enter the Superior State until the end of your next turn. Then, '
        'upon leaving the Superior State entered through this effect, reduce '
        'your Combat Rolls, Surgency, and Soak Value by 1(bT) for the '
        'remainder of the Combat Encounter.\n'
        'Only 1 of your Minions may use the Arrogant Declaration Maneuver in '
        'each Combat Encounter.',
  ),
  ManeuverDef(
    name: 'Basic Attack Maneuver',
    kind: ManeuverKind.standard,
    actionCost: '1 Action',
    kpCost: 'Varies (uses the Ki Point Cost of the chosen Profile)',
    exploitable: 'N/A',
    flavor: 'Make a basic, unnamed attack.',
    effect: 'Target an Opponent with an Attacking Maneuver using a Profile '
        'of your choice. If the Profile has an Area of Effect, use that to '
        'select the target(s) instead. You can only use each Profile once '
        'per Combat Round when using a Basic Attack Maneuver, except for the '
        'Simple Profile.',
  ),
  ManeuverDef(
    name: 'Combat Recovery',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: 'Variable (2~3 Actions)',
    kpCost: 'N/A',
    exploitable: 'All Opponents that are not at Long Range.',
    flavor: 'Talk or rest to recover as much stamina as possible.',
    effect: 'You can spend between 2 and 3 Actions on Combat Recovery. For '
        'each Action spent, reduce your Defense Value by 1(T) until the '
        'start of your next turn and regain 1d10(bT) Life and Ki Points. If '
        'you are hit by an Attacking Maneuver used through the Exploit '
        'Maneuver (and receive Damage) in response to this Maneuver, you '
        'lose any Life Points regained due to this use of Combat Recovery.\n'
        'Condition Recovery: When using Combat Recovery, you may forgo '
        'gaining any Life Points to make a Steadfast Check. If you succeed, '
        'you can remove any Damage over Time (DOT) or a stack of a Combat '
        'Condition (except Suffocating, Transfigured, or Pinned) from '
        'yourself (if that Combat Condition does not have stacks, remove the '
        'entire Combat Condition) for each Action spent. If you are hit by '
        'an Attacking Maneuver used through the Exploit Maneuver (and '
        'receive Damage) in response to this Maneuver, you automatically '
        'fail the Steadfast Check.\n'
        'Spectate: After using Combat Recovery, you can choose to spend your '
        'remaining Actions (minimum 1 Action) to enter the Spectator Special '
        'State.',
  ),
  ManeuverDef(
    name: 'Disarm Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'If you fail the clash for the Disarm Maneuver, trigger the '
        'Exploit Maneuver of the target.',
    flavor: 'Take a Weapon away from your foe!',
    effect: 'Target an Opponent wielding a Weapon within your Melee Range. '
        'Make a Clash (Strike vs Strike/Dodge). If you win, the Weapon is '
        'removed from their grip and lands on a Square adjacent to that '
        'Opponent of your choice.',
  ),
  ManeuverDef(
    name: 'Empower',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: 'Variable',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Send your power to an ally!',
    effect: 'You can decide how many Actions you spend on this Maneuver. '
        'Declare an Ally, and for each Action spent on this Maneuver, you '
        'can transfer a number of Ki Points up to twice your Might to the '
        'declared Ally. If the declared Ally is within your Melee Range, '
        'double the amount of Ki Points you can transfer to them. '
        'Transferring Ki Points does not reduce your Capacity.\n'
        'Full Empowerment: Upon using this Maneuver, if you are not a '
        'Minion, you can choose to reduce your Capacity to 0 and gain a '
        'stack of the Fatigued Combat Condition and the Impediment Combat '
        'Condition. If you do, you may transfer any amount of Ki Points '
        'through this use of the Empower Maneuver.\n'
        'Miracle Empowerment: If, during the same Combat Round, a Character '
        'is declared through the Empower Maneuver by 4+ Characters who spent '
        'at least 3 Actions and the maximum amount of Ki Points, or a '
        'Character who had used Full Empowerment to transfer as many Ki '
        'Points as possible (reducing their amount of Ki Points to 0), that '
        'Character enters the Entrusted Special State until the end of their '
        'next turn.\n'
        'You can only enter the Entrusted Special State once per Combat '
        'Encounter through Miracle Empowerment, and you cannot benefit from '
        'Miracle Empowerment if one of your Allies has entered the Entrusted '
        'Special State through its effects during this Combat Encounter.',
  ),
  ManeuverDef(
    name: 'Energy Charge Maneuver',
    kind: ManeuverKind.standard,
    actionCost: '1 Action',
    kpCost: '2(bT)',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Charge up your energy into a single, high-power attack.',
    effect: 'Declare an Attacking Maneuver through either the Basic Attack '
        'Maneuver or Signature Technique Maneuver. That declared Attacking '
        'Maneuver gains an Energy Charge. Each time you would use the Energy '
        'Charge Maneuver after declaring an Attacking Maneuver but before '
        'using the declared Attacking Maneuver, any use of the Energy Charge '
        'Maneuver instead only grants an additional Energy Charge to the '
        'originally declared Attacking Maneuver.\n'
        'Until you use the chosen Attacking Maneuver, you suffer from the '
        'Guard Down Combat Condition and you cannot use any other Attacking '
        'Maneuver or Standard Maneuver.',
  ),
  ManeuverDef(
    name: 'Feature Thrust',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'You throw a Feature on the battlefield towards your enemies.',
    effect: 'Target a Feature on an adjacent Square to you. If that Feature '
        'occupies a number of Squares equal to the amount your Character '
        'occupies or less, you may move that Feature a number of Squares up '
        'to 1/2 of your Might in the opposite direction to you.\n'
        'If that Feature hits another Character, that Character may spend 1 '
        'Counter Action to make a Might Clash against you. If they win, the '
        'Feature stops its movement on the Square adjacent to them. If they '
        'lose or if they choose not to spend a Counter Action, follow the '
        'typical rules for Feature Collision.',
  ),
  ManeuverDef(
    name: 'Grapple Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'If you lose the initial Grapple Check, this triggers the '
        'Exploit Maneuver from the target of that Grapple Check.',
    flavor: 'Beyond just punching people, grabbing an Opponent is a valid '
        'option too.',
    effect: 'Target a Character within your Melee Range and make a Clash '
        '(Strike vs Strike/Dodge) against them – this Clash is known as '
        'a Grapple Check. If you win, you and your target are in a Grapple '
        'but if you lose, you provoke the Exploit Maneuver from your target. '
        'The Initiator of the first Grapple Check for a Grapple is known as '
        'the Grappler, while the Defender of that Grapple Check is the '
        'Grappled.\n'
        'You cannot use the Grapple Maneuver if you are already in a '
        'Grapple. While in a Grapple, there are certain rules in play:\n'
        'Grapple Penalty: While in a Grapple, all Characters suffer from the '
        'Guard Down Combat Condition and cannot remove it while in the '
        'Grapple.\n'
        'Ending a Grapple: The Grappler can end a Grapple as an Instant '
        'Maneuver on their turn.\n'
        'Escaping a Grapple: By spending 1 Action, the Grappled can make a '
        'Grapple Check against the Grappler. If they win, they escape the '
        'Grapple. For each Action spent after the first, increase the Dice '
        'Score of their Grapple Check by 1(T) until the end of their turn.\n'
        'Movement in a Grapple: While in a Grapple, if you would use an '
        'effect to move your Character or another Character within your '
        'Grapple, you must first make a Might Clash against your opposing '
        'Character in a Grapple. If you win, use the effect as intended but '
        'the other Character in the Grapple moves an equal number of Squares '
        'in the same direction. If you lose, you cannot use that effect (you '
        'still pay the Ki Point Cost or Action Cost for any effect or '
        'Maneuver used).\n'
        'Pulled In: If you are the Grappler in a Grapple and the Grappled is '
        'not on a Square adjacent to you, you may make a Might Clash against '
        'the Grappled as an Instant Maneuver. If you win, move them to the '
        'closest unoccupied Square adjacent to you.\n'
        'Moving a Character: If a Character outside of the Grapple attempts '
        'to use an effect that would move a Character within a Grapple, they '
        'must make a Might Clash against the Grappler. If they win, they '
        'move the targeted Character as usual and the Grappled escapes the '
        'Grapple. If they lose, they cannot use that effect.\n'
        'Grappling a Grapple: If a Character outside of the Grapple attempts '
        'to use the Grapple Maneuver against a Character in the Grapple, '
        'they must first make a Might Clash against the Grappler. If they '
        'win, the current Grappled Character escapes the initial Grapple and '
        'they can continue with their Grapple Maneuver as usual. If they '
        'lose, they cannot use that effect (they still pay the Action Cost '
        'for the Grapple Maneuver).\n'
        'Tail Restraint: When using a Grapple Maneuver against a Character '
        'who has access to the Tail Attack Maneuver or is a Saiyan with a '
        'Tail, you can take a penalty of 2(T) to your initial Grapple Check '
        'to attempt and grab their Tail. If you do, they cannot use the Tail '
        'Attack Maneuver while in this Grapple.',
  ),
  ManeuverDef(
    name: 'Launch Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Throw a Character you are holding.',
    effect: 'Make a Grapple Check against an Opponent you are currently in a '
        'Grapple with as the Grappler. If you win, you may end the Grapple '
        'to move that Character a number of Squares up to your Might in any '
        'direction. If you lose, the Grappled Opponent escapes the Grapple.',
  ),
  ManeuverDef(
    name: 'Movement Maneuver',
    kind: ManeuverKind.standard,
    limit: '2/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'If you leave the Melee Range of an Opponent.',
    flavor: 'Getting from point A to point B as fast as possible.',
    effect: 'Move a number of Squares up to your Normal Speed. You may '
        'increase the KP Cost of this Maneuver to 3(T) to instead move up to '
        'your Boosted Speed.\n'
        'Rapid Movement: When using the Movement Maneuver, you can increase '
        'the Ki Point Cost by 2(T) to use Rapid Movement. If you do, '
        'increase your Strike Rolls by 1(T) until the end of your turn and '
        'increase your Dodge Roll against an Exploit Maneuver provoked by '
        'this instance of Movement by 1(T).\n'
        'Exploit on Movement: If you leave the Melee Range of an Opponent '
        'when using this Maneuver, you provoke the Exploit Maneuver from '
        'that Opponent. If an Attacking Maneuver used through the Exploit '
        'Maneuver deals Damage when used in response to this Maneuver, you '
        'do not move any additional Squares (you still move any number of '
        'Squares you would until the Exploit Maneuver was triggered and the '
        'Action Cost is still spent).',
  ),
  ManeuverDef(
    name: 'Pin Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '2 Actions',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Pin your Opponents, preventing escape!',
    effect: 'If you are the Grappler in a Grapple, make a Grapple Check '
        'against the Grappled with your Dice Score reduced by 1(bT). If you '
        'win, make a Might Clash against the Grappled. If you win, they gain '
        'the Pinned Combat Condition while in this Grapple. If you lose '
        'either of these Clashes, they escape the Grapple.\n'
        'You can only use this Maneuver if you are in a Grapple.',
  ),
  ManeuverDef(
    name: 'Power Up Maneuver',
    kind: ManeuverKind.standard,
    limit: '2/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Concentrate your power and push it to its limits!',
    effect: 'Gain a stack of Power until the end of your next turn; if you '
        'already possess a stack of Power, you may remove a stack of Power '
        'before applying this effect. For each stack of Power, increase your '
        'Combat Rolls by 1(T) and your Max Capacity by 1/4 (this increase to '
        'your Max Capacity only applies for the first 2 stacks of Power).\n'
        'Power is a Resource and you cannot possess more than 2 stacks of '
        'Power. If an effect would stop you from losing a stack(s) of Power, '
        'instead lose those stack(s) at the end of your next turn.',
  ),
  ManeuverDef(
    name: 'Revert Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Release a transformed state and return to your base form.',
    effect: 'Exit any number of Forms or Enhancements of your choice.',
  ),
  ManeuverDef(
    name: 'Ride Maneuver',
    kind: ManeuverKind.standard,
    limit: '2/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'If you are in the Melee Range of an Opponent',
    flavor: 'Take control of a vehicle to ride across the battlefield in '
        'style.',
    effect: 'Enter an adjacent Vehicle or Battle Jacket if you are not '
        'already in a Vehicle or Battle Jacket, then you may become the '
        'Pilot if there is no Pilot. If you are already in a Vehicle or '
        'Battle Jacket, upon using this Maneuver, you may either:\n'
        '• Leave that Vehicle/Battle Jacket to move onto an unoccupied '
        'Square adjacent to that Vehicle/Battle Jacket.\n'
        '• Stop Piloting this Vehicle/Battle Jacket and move to an '
        'unoccupied Square within the Vehicle/Battle Jacket.\n'
        '• Attempt to become the Pilot of the Vehicle/Battle Jacket. If the '
        'current Pilot is willing, you become the Pilot in their place and '
        'swap which Squares you are occupying in the Vehicle/Battle Jacket. '
        'If not, make a Clash (Physical Strike vs Physical Strike/Dodge). If '
        'you win, you become the Pilot. The winner of the Clash may choose '
        'to remove the other Character involved in the Clash from the '
        'Vehicle/Battle Jacket, placing them on a Square adjacent to the '
        'Vehicle/Battle Jacket of their choice.',
  ),
  ManeuverDef(
    name: 'Signature Technique Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'Varies (each Signature Technique will have their own KP Cost '
        '– that is the KP Cost you pay for this Maneuver)',
    exploitable: 'N/A',
    flavor: 'Blast an Opponent away with a Signature Technique!',
    effect: 'Make an Attacking Maneuver using a Signature Technique you have '
        'access to.',
  ),
  ManeuverDef(
    name: 'Terrain Lift Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Tear up the ground.',
    effect: 'Target an unoccupied Square or a Feature within your Melee '
        'Range. If your Force Modifier exceeds 3x the Hardness Value of that '
        'Square/Feature, you lift it up and hold onto it as a Feature (if it '
        'was a Square previously, it is now a Feature of the same Hardness '
        'Rank that occupies 1 Square). You cannot lift a Feature if it '
        'occupies a number of Squares equal to or greater than 4x the number '
        'of Squares you occupy, and you can only hold 1 Feature at a time.\n'
        'Shielding. If you are hit by an Attacking Maneuver while carrying a '
        'Feature, apply effects as if you were in Cover with that Feature.\n'
        'Placing. You can put down a Feature you are carrying in any '
        'unoccupied Square within your Melee Range as an Instant Maneuver.',
  ),
  ManeuverDef(
    name: 'Throw Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Throw an object you have on your person or in your hands.',
    effect: 'You may throw whatever you are holding (such as a Basic Item, '
        'Feature, or even a Weapon) any number of Squares in a straight '
        'line. This is considered an Attacking Maneuver of the Simple '
        'Profile, despite its different range. If you hit another Character, '
        'apply Collision Damage as if your thrown Item was a Feature. If it '
        'was already a Feature, use the Hardness Rank of that Feature. If it '
        'was a Weapon, the Hardness Rank is 2. If it was a Basic Item, the '
        'Hardness Rank is 1.\n'
        'If you throw a Weapon, you do not apply any effects from its '
        'Qualities or its Weapon Category unless it possesses the Throwing '
        'Weapon Quality.\n'
        'Anything thrown at an Opponent through this Maneuver lands on a '
        'Square adjacent to them (your choice) if it hit, or it continues '
        'past that Opponent and lands on a Square of your ARC’s '
        'choosing.\n'
        'You cannot Ki Wager more than 1/4 (rounded up) of your Ki Points on '
        'an Attacking Maneuver made through the Throw Maneuver.',
  ),
  ManeuverDef(
    name: 'Thrust Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'You strike an Opponent to knock them off-balance or blow them '
        'away.',
    effect: 'Target an Opponent within your Melee Range and make a Clash '
        '(Strike vs Strike/Dodge) against them. If you win, choose one of '
        'the effects below to apply:\n'
        'Push Back. The target is moved a number of Squares equal to 1/2 of '
        'your Might. The movement is in a straight line and away from you. '
        'Double any Collision Damage they suffer due to this movement.\n'
        'Knock Prone. Make a second Clash (Impulsive/Corporeal). If you win, '
        'they are knocked Prone. If you lose, they suffer from the Guard '
        'Down Combat Condition until the end of your turn.',
  ),
  ManeuverDef(
    name: 'Toss Maneuver',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: 'N/A',
    flavor: 'Give an item to a friend or ally.',
    effect: 'Give a Basic Item, Accessory, Weapon, or piece of Apparel you '
        'possess to another Character. That Character must make an '
        'Apprentice Perception Skill Check. If they succeed, they gain the '
        'item. If they fail, it continues sailing past them and becomes '
        'lost, requiring a Perception Skill Check to find again (with the '
        'Difficulty Category decided by the ARC depending on the terrain).',
  ),
  ManeuverDef(
    name: 'Transformation Maneuver',
    kind: ManeuverKind.standard,
    actionCost: '1 Action',
    kpCost: 'N/A',
    exploitable: 'N/A (Unless that Transformation has the Long '
        'Transformation Aspect).',
    flavor: 'Enter a Transformation!',
    effect: 'Roll the Stress Test for a Form or Enhancement you have access '
        'to and meet the Tier of Power Requirements for. If you match or '
        'exceed the Stress Test Requirement, you enter the Transformation '
        'and apply any effects that occur when entering that Transformation '
        '(such as Legend Realized and Burst Limit). If you fail, you suffer '
        'from Stress Exhaustion as per the rules on Stress Tests.\n'
        'If you are already in a Form, you may attempt to transform into '
        'another Form or Transcended Enhancement. Upon succeeding, before '
        'you apply any effects or properly enter this Transformation, leave '
        'the Form you were in previously.\n'
        'If you are already in an (Non-Transcended) Enhancement, you may '
        'attempt to transform into another (Non-Transcended) Enhancement. If '
        'you do, and have reached the maximum number of Transformations you '
        'can use concurrently, upon succeeding, before you apply any effects '
        'or properly enter this Transformation, leave an Enhancement you '
        'were in previously.',
  ),
];

/// Instant Maneuvers. Verbatim.
const List<ManeuverDef> kDbuInstantManeuvers = [
  ManeuverDef(
    name: 'Command',
    kind: ManeuverKind.instant,
    actionCost: 'Instant',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Control your Minions!',
    effect: 'Target a number of your Minions up to the number of Standard '
        'Actions you possess. You lose those Actions, but those Minions gain '
        'access to their Act Phase and 1 Counter Action.',
  ),
  ManeuverDef(
    name: 'No Effort Maneuver',
    kind: ManeuverKind.instant,
    limit: '1/Round',
    actionCost: 'Instant',
    kpCost: 'N/A',
    flavor: 'Anything incredibly easy to do, taking almost no time.',
    effect: 'This Maneuver covers a lot of different effects which can only '
        'be used during your turn, which are listed below:\n'
        'Dynamic. Anything that’s not covered here, your ARC may '
        'declare requires a No Effort Maneuver.\n'
        'Un/Sheathing a Weapon. Put away or draw a weapon.\n'
        'Replace a Weapon. Replacing a Weapon you are holding with another '
        'Weapon you possess.\n'
        'Drop/Pickup. Dropping or picking up an object.\n'
        'Cancel Energy Charge. Stop suffering from the effects of the Energy '
        'Charge Maneuver, but you lose all gathered Energy Charges from your '
        'chosen Attacking Maneuver.\n'
        'Activate/Deactivate Integrated Items. You may make an Active '
        'Integrated Item you possess become Inactive, and then choose one of '
        'your Inactive Integrated Items to become Active.',
  ),
  ManeuverDef(
    name: 'Surge Maneuver',
    kind: ManeuverKind.instant,
    limit: '1/Encounter',
    actionCost: 'Instant',
    kpCost: 'N/A',
    flavor: 'Gather yourself and recover.',
    effect: 'Use either a Healing Surge or a Ki Surge.',
  ),
  ManeuverDef(
    name: 'United Attack Maneuver',
    kind: ManeuverKind.instant,
    limit: '1/Round',
    actionCost: 'Instant',
    kpCost: 'Varies (equal to the cost of the Profile or Signature '
        'Technique used)',
    flavor: 'A team attack with all you’ve got.',
    effect: 'When an Ally uses an Attacking Maneuver or Duel Maneuver while '
        'you are on an adjacent Square, you may spend 1 Action and the Ki '
        'Points as if making the same Profile of Attacking Maneuver as your '
        'Ally. Apply the following effects to their Attacking Maneuver or '
        'Duel Maneuver:\n'
        'Additional Power. Increase their Wound Roll by 1/2 of your relevant '
        'Attribute Modifier (Force for if they made a Physical or Energy '
        'Attack and Magic for if they made a Magic Attack) or 1/4 if they '
        'are engaging in a Duel Maneuver.\n'
        'Advantages. If you are using a Signature Technique, you may apply '
        'up to 1(bT) ranks of Advantages you possess on your Signature '
        'Technique to their Attacking Maneuver.\n'
        'Wager. You can Ki Wager up to 1/4 of your Max Capacity on this '
        'Attacking Maneuver or up to 1/10th of your Max Capacity on each '
        'roll if they are engaging in a Duel Maneuver.\n'
        'If your Ally would lose the Duel Maneuver when you used the United '
        'Attack Maneuver to join, you are also considered a target for the '
        'Attacking Maneuver.',
  ),
];

/// Counter Maneuvers. Verbatim.
const List<ManeuverDef> kDbuCounterManeuvers = [
  ManeuverDef(
    name: 'Blockade Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: '2(T)',
    flavor: 'Protect your allies by standing in the way.',
    effect: 'If a Character within range of your Normal Speed uses the '
        'Movement Maneuver, you may use this Maneuver to make a Clash '
        '(Impulsive) against that Character. If you win, you may immediately '
        'move to any Square within your Normal Speed that is adjacent to '
        'that Character. That Character stops using the Movement Maneuver '
        'and cannot use the Movement Maneuver for the remainder of their '
        'Turn (they regain any Actions or Ki Points spent). If you lose, '
        'that Character may continue to use their Movement Maneuver and you '
        'trigger their Exploit Maneuver.',
  ),
  ManeuverDef(
    name: 'Defend Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'Varies (depends on chosen effect)',
    flavor: 'Actively defend yourself against dangerous attacks.',
    effect: 'You can use this Maneuver when you are targeted by an Attacking '
        'Maneuver. When you do, select one of the following effects to use '
        '(each one has their KP Cost shown in brackets):\n'
        'Parry [0]: Use your Strike Roll (as if you rolled a Physical '
        'Attack) instead of your Dodge Roll for the Attacking '
        'Maneuver’s Clash. If you win, you avoid that Attacking '
        'Maneuver. Reduce your Dice Score by 1(bT) for each Energy Charge or '
        'rank of Power Shot on the Attacking Maneuver.\n'
        'Direct Hit [0]: You forgo your Dodge Roll for the Attacking '
        'Maneuver’s Clash and are automatically hit by that Attacking '
        'Maneuver. Increase your current Soak Value by 1/2 for this '
        'Attacking Maneuver. If this Attacking Maneuver inflicts no Damage '
        'and has 2+ Energy Charges or a Ki Wager equal to or higher than 1/4 '
        'of their Max Capacity, the attacker suffers from the Shaken Combat '
        'Condition until the end of their next turn.\n'
        'Power Flare [0]: You automatically fail all clashes against the '
        'Strike Roll of the incoming Attacking Maneuver, but do not apply '
        'any effects from being hit by this Attacking Maneuver until after '
        'you receive Damage (except those that increase the Wound Roll). '
        'When your Opponent rolls their Wound Roll, immediately afterwards, '
        'you roll your Wound Roll (as if you made an Energy or Magic Attack, '
        'including any Ki Wager you wish to spend). If the Dice Score of '
        'your Wound Roll exceeds the Dice Score of your Opponent’s '
        'Wound Roll, you receive 0 Damage and any effects that would occur '
        'upon hitting you with this Attacking Maneuver do not apply.\n'
        'Cross Counter [0]: Your Opponent uses their Attacking Maneuver as '
        'usual, but your Defense Value is halved. Immediately after the '
        'Attacking Maneuver’s Clash is resolved, make a Basic Attack '
        'Maneuver as an Out-of-Sequence Maneuver against that same '
        'Opponent.\n'
        'Guard [8(bT)]: You forgo your Dodge Roll for the Attacking '
        'Maneuver’s Clash. When calculating your Damage from this '
        'Attacking Maneuver, the Dice Score of the Wound Roll is halved and '
        'its Damage Category is reduced by 1 Category. Increase the Ki Point '
        'Cost for this Maneuver by 1(bT) for each Energy Charge on your '
        'Opponent’s Attacking Maneuver (max. +4(bT)).\n'
        'If you use the Defend Maneuver in response to an Attacking '
        'Maneuver, you do not gain any stacks of Diminishing Defense from '
        'that Attacking Maneuver.\n'
        'If you use the Parry option of the Defend Maneuver and successfully '
        'defend against the Attacking Maneuver, you may use the Reflect '
        'Modifier Maneuver.',
  ),
  ManeuverDef(
    name: 'Duel Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'N/A',
    flavor: 'Fight back against a serious attack with your full might!',
    effect: 'If you are the target of an Attacking Maneuver that has 2+ '
        'Energy Charges, or has a Ki Wager of 10(bT) or more, you may '
        'initiate the Duel Maneuver by spending the Ki Points to make an '
        'Attacking Maneuver of the same Foundation (Energy and Magic both '
        'count as a single Foundation for a Duel Maneuver) as the incoming '
        'Attacking Maneuver.\n'
        'At the start of a Duel Maneuver, the attacking Character regains Ki '
        'Points and Capacity equal to their initial Ki Wager, losing the Ki '
        'Wager in the process. After this, the Characters in the Duel '
        'Maneuver make 3 Duel Clashes. During each Duel Clash, they can Ki '
        'Wager up to 1/2 of their Max Capacity (ignoring their current '
        'Capacity) to increase their Dice Score by an equal amount. Any '
        'wagered Ki Points do not reduce the Capacity of that Character, but '
        'all Characters involved in a Duel Maneuver have their Capacity '
        'reduced to 0 after completing that Maneuver. Whoever wins at least '
        '2 Duel Clashes wins the Duel Maneuver and rolls their Wound Roll '
        'for their Attacking Maneuver against the opposing Character(s) as '
        'usual, but also applies a Ki Wager equal to the total Ki Wager used '
        'by all Characters involved in the Duel Maneuver.\n'
        'Power Duel. When making a Duel Maneuver, you can decide to forgo '
        'using an Initiating Attack and simply contest the opponent with '
        'pure might. This costs no Ki Points. If you win the Duel Maneuver, '
        'you do not roll Wound but instead apply a Dice Score for a Wound '
        'Roll equal to your Might plus the total Ki Wagers involved in the '
        'Duel Maneuver.\n'
        'Duel Clash Tie. If a Duel Clash results in a tie, refund any Ki '
        'Wagers and redo the Duel Clash if it is not the third Duel Clash. '
        'If it was the third Duel Clash, the Duel Maneuver ends in a tie and '
        'all participating Characters have their Life Points reduced by 1/2 '
        'of the total Ki Wagered by all participating Characters.',
  ),
  ManeuverDef(
    name: 'Duel Escape Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'N/A',
    flavor: 'That’s not a match you’ll win. Better to dip.',
    effect: 'When an Opponent attempts to initiate a Duel Maneuver with you '
        'as the target, you may attempt to escape through the Duel Escape '
        'Maneuver. Make an Impulsive Clash against that Opponent. If you '
        'win, you successfully avoid engaging in the Duel Maneuver but your '
        'Attacking Maneuver is nullified and you regain the Action Cost '
        'spent (you still lose the Ki Point Cost of your Maneuver).',
  ),
  ManeuverDef(
    name: 'Energy Cancel',
    kind: ManeuverKind.counter,
    limit: '1/Round',
    actionCost: '1 Counter',
    kpCost: 'N/A',
    flavor: 'Plans change. Standing around charging an attack didn’t '
        'work, so change strategies immediately, even if you’ll lose '
        'the stamina you dedicated to charging.',
    effect: 'If you are currently suffering from the effects of the Energy '
        'Charge Maneuver when you are targeted by an Attacking Maneuver (or '
        'at the start of your turn), you can use this Maneuver to '
        'immediately lose all Energy Charges gained from the Energy Charge '
        'Maneuver but also stop suffering from the other effects of the '
        'Energy Charge Maneuver.',
  ),
  ManeuverDef(
    name: 'Exploit Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'N/A',
    flavor: 'Punish openings.',
    effect: 'If an effect provokes the Exploit Maneuver, such as using '
        'movement to move outside of your Melee Range, you may use this '
        'Maneuver. If you do, use the Basic Attack Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  ManeuverDef(
    name: 'Intervene Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'Varies (depends on chosen effect)',
    flavor: 'Step in the way of danger to help an ally!',
    effect: 'When an Ally who is not at Long Range is hit by an Attacking '
        'Maneuver (that did not also target you), you may use this Maneuver '
        'to use one of the following effects:\n'
        'Defense Wall [0]. Move yourself to an unoccupied Square that is '
        'within range of your Boosted Speed and is between your Ally and the '
        'Character who used the Attacking Maneuver, then take the Wound Roll '
        'for that Attacking Maneuver instead of your Ally (if you are '
        'Defeated by this Attacking Maneuver, any excess Damage is inflicted '
        'to that Ally). For the duration of this Attacking Maneuver, '
        'increase your Soak Value by 1/2 (rounded up).\n'
        'Deflect [2(bT)]. Move yourself to an unoccupied Square that is '
        'within range of your Boosted Speed and is between your Ally and the '
        'Character who used the Attacking Maneuver or adjacent to that Ally, '
        'then make a Might Clash against the attacking Opponent (reduce your '
        'Dice Score by 1(T) for each Energy Charge or Rank of Power Shot the '
        'Attacking Maneuver possesses). If you win, the Attacking Maneuver '
        'is successfully deflected away from all targets. If you lose, you '
        'take the Wound Roll for that Attacking Maneuver instead of the '
        'chosen Ally and you increase the Damage Category of that Attacking '
        'Maneuver by 1 Category for the sake of calculating your Damage.\n'
        'Distant Deflect [8(bT)]. Make a Might Clash against the attacking '
        'Opponent (reduce your Dice Score by 1(T) for each Energy Charge or '
        'rank of Power Shot the Attacking Maneuver possesses). If you win, '
        'the Attacking Maneuver is successfully deflected away from all '
        'targets.\n'
        'If you use the Intervene Maneuver, no other Character can use the '
        'Intervene Maneuver for your selected Ally against that Attacking '
        'Maneuver.\n'
        'For the Deflect/Distant Deflect options, if the Attacking Maneuver '
        'was of the Energy or Magic Foundation, you may use the Reflect '
        'Modifier Maneuver.',
  ),
  ManeuverDef(
    name: 'Sudden Stop Maneuver',
    kind: ManeuverKind.counter,
    actionCost: '1 Counter',
    kpCost: 'N/A',
    flavor: 'By hitting the ground, stabbing your Ki into the floor, using '
        'your flight to suddenly stop as if you hit an invisible wall, or '
        'any other method, you stop your movement.',
    effect: 'If you are moved by the effect of another Character, you may '
        'use this Maneuver to reduce the number of Squares you move by a '
        'number of Squares up to 1/2 of your Might. Additionally, halve any '
        'Collision damage you take as a result of this movement and you may '
        'choose to ignore the effects of any Feature Qualities or '
        'Environment Qualities that affect you for Feature Collision or '
        'Ground Collision respectively.\n'
        'If you end this movement without Collision, you may use the '
        'Movement Maneuver as an Out-of-Sequence Maneuver.',
  ),
];

/// Modifier Maneuvers (applied onto other Maneuvers). Verbatim. Draining
/// Attack is the site's sole "Special Modifier Maneuver" (access-gated).
const List<ManeuverDef> kDbuModifierManeuvers = [
  ManeuverDef(
    name: 'Called Shot',
    kind: ManeuverKind.modifier,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: '2(T)',
    baseManeuver: 'Any Attacking Maneuver.',
    flavor: 'A unique type of Maneuver that allows you to target specific '
        'weaknesses.',
    effect: 'At Attack Declaration, when making an Attacking Maneuver that '
        'does not have an Area of Effect, you can use this Maneuver to '
        'increase the Damage Category of that Attacking Maneuver by 1 but '
        'decrease the Strike Roll for that Attacking Maneuver by 2(T).\n'
        'State the area you targeted with this Attacking Maneuver. Your ARC '
        'may allow for special effects to occur if you knock that Opponent '
        'through a Health Threshold or deal Damage equal to or exceeding '
        '1/5th of that target’s Maximum Life Points. A few potential '
        'example targets are:\n'
        'Head: That Character gains the Impediment Combat Condition until '
        'the start of your next turn.\n'
        'Eyes: That Character gains the Blinded Combat Condition until the '
        'end of their next turn.\n'
        'Arm: That Character gains the Guard Down Combat Condition until the '
        'start of your next turn.\n'
        'Leg: That Character has their Speeds and Defense Value halved until '
        'the start of your next turn.\n'
        'Gut: That Character is knocked Prone.',
  ),
  ManeuverDef(
    name: 'Reflect Maneuver',
    kind: ManeuverKind.modifier,
    actionCost: 'N/A',
    kpCost: '5(T)',
    baseManeuver: 'Parry option of the Defend Maneuver, Deflect/Distant '
        'Deflect options of the Intervene Maneuver',
    flavor: 'Throw back an attack against an opponent!',
    effect: 'If you avoid an Attacking Maneuver (that did not possess an '
        'AoE) due to using the Parry option of the Defend Maneuver or '
        'succeed at the Might Clash for the Deflect or Distant Deflect '
        'options of the Intervene Maneuver, you may use this Maneuver if the '
        'Attacking Maneuver was of the Energy or Magic Foundation. Roll '
        'Strike against an Opponent of your choice using the Profile of the '
        'initial Attacking Maneuver. If they are hit, the original attacking '
        'Opponent rolls the Wound Roll for their initial Attacking Maneuver '
        'instead as an Urgent Roll, including any Ki Wagers and Energy '
        'Charges included on that Attacking Maneuver. Damage calculation '
        'occurs as usual from this point.',
  ),
  ManeuverDef(
    name: 'Triggered Maneuver',
    kind: ManeuverKind.modifier,
    limit: '1/Round',
    actionCost: 'N/A',
    kpCost: 'N/A',
    baseManeuver: 'Any Maneuver',
    flavor: 'A unique type of Maneuver that allows you to delay your '
        'Maneuvers.',
    effect: 'When making any type of Maneuver, you may use this Maneuver to '
        'delay its use but pay the Action Cost and KP Cost immediately. When '
        'you do, you must select a trigger. If that trigger occurs before '
        'the start of your next turn, you may use that Maneuver without '
        'paying the Action Cost or KP Cost as an Out-of-Sequence Maneuver. '
        'Below is the list of potential triggers:\n'
        'Damage: Select a Character. If that Character receives Damage, use '
        'your chosen Maneuver.\n'
        'Movement: Select a Character. If that Character would use any '
        'effect to move, use your chosen Maneuver before they move.\n'
        'Attack: Select a Character. If that Character uses an Attacking '
        'Maneuver, use your chosen Maneuver before that Attacking Maneuver '
        'is used.\n'
        'Turn End: Select an Ally. Once that Character’s turn ends, use '
        'your chosen Maneuver.\n'
        'Combat Condition: Select an Opponent and a Combat Condition. If the '
        'Opponent gains your selected Combat Condition, immediately use your '
        'chosen Maneuver.\n'
        'When using the Triggered Maneuver to delay a Maneuver, you provoke '
        'the Exploit Maneuver for any Opponent within a Sphere AoE centered '
        'on you. If you take Damage from an Attacking Maneuver used through '
        'the Exploit Maneuver in response to this Maneuver, you do not gain '
        'the effects of the Triggered Maneuver and do not use the selected '
        'Maneuver but you gain a number of Counter Actions equal to the '
        'Action Cost spent.',
  ),
  ManeuverDef(
    name: 'Draining Attack Maneuver',
    kind: ManeuverKind.modifier,
    limit: '1/Round',
    actionCost: '1 Action',
    kpCost: '2(T)',
    baseManeuver:
        'Basic Attack Maneuver (Unarmed Physical Attack, not an AoE, no Ki '
        'Wager).',
    isSpecialModifier: true,
    flavor: 'You are able to absorb life energy through your attacks.',
    effect: 'At Attack Declaration, if you would use the Basic Attack '
        'Maneuver, you can use this Maneuver to increase the Damage Category '
        'of that Attacking Maneuver by 1, regain Life Points equal to the '
        'Damage inflicted to the target of this Attacking Maneuver, and '
        'regain Ki Points equal to 1/2 of the Damage inflicted to the target '
        'of this Attacking Maneuver.',
  ),
];

/// Special Maneuvers (Special Maneuvers page) — "you cannot use any Special
/// Maneuvers until you have gained access to them through an effect."
/// Verbatim.
const List<ManeuverDef> kDbuSpecialManeuvers = [
  ManeuverDef(
    name: 'Absorb Maneuver',
    kind: ManeuverKind.special,
    limit: '2/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    kpCost: 'N/A',
    exploitable: 'If you fail the initial Clash, this triggers the Exploit '
        'Maneuver from the target.',
    flavor: 'You consume, wrap around, or otherwise engulf a target and '
        'make them part of yourself.',
    effect: 'Target a Character within your Melee Range. Make a Clash '
        '(Strike vs Strike/Dodge) against them. If you win, make a second '
        'Clash (Corporeal) against that Character. If you lose this Clash, '
        'that Character suffers from the Shaken Combat Condition until the '
        'end of their next turn. If you win, that Character is removed from '
        'the Combat Encounter and you gain a stack of the Absorption '
        'Awakening as a Level 2 Temporary Awakening with that Character as '
        'the Absorbed Character.',
  ),
  ManeuverDef(
    name: 'Analysis Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Study your opponents and find the perfect vital point to '
        'strike.',
    effect: 'Target an Opponent. They become Analyzed until the end of your '
        'next turn. Increase your Combat Rolls against Analyzed Opponents by '
        '1(T)+1/4 (rounded up) of your Scholarship Modifier.',
  ),
  ManeuverDef(
    name: 'Attack Absorption Maneuver',
    kind: ManeuverKind.special,
    maneuverType: 'Out-of-Sequence Maneuver',
    actionCost: 'N/A',
    minions: 'N/A',
    kpCost: 'N/A',
    flavor: 'You consume an enemy’s attack, taking its energy for your '
        'own.',
    effect: 'If you use the Parry option of the Defend Maneuver to '
        'successfully avoid an Attacking Maneuver of the Energy or Magic '
        'Foundation, you may absorb that Attacking Maneuver (meaning that '
        'Attacking Maneuver does not exist and therefore you cannot use the '
        'Reflect Maneuver in response to the successful Parry). Your '
        'Opponent makes an Urgent Wound Roll for their Attacking Maneuver as '
        'if you were hit, and you regain Ki Points equal to 1/2 of the Dice '
        'Score.\n'
        'If you regain Ki Points that equal or exceed 1/5 of your Maximum Ki '
        'Points through this effect, you may use the Power Up Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  ManeuverDef(
    name: 'Bite Attack',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: '2(T)',
    exploitable: 'N/A',
    flavor: 'Sink your fangs into your opponent!',
    effect: 'Target an Opponent with an Unarmed Attacking Maneuver of the '
        'Simple Profile and Physical Foundation. This Attacking Maneuver is '
        'Direct.',
  ),
  ManeuverDef(
    name: 'Block Maneuver',
    kind: ManeuverKind.special,
    maneuverType: 'Counter Maneuver',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    kpCost: 'N/A',
    flavor: 'You are able to block an incoming attack with your shield.',
    effect: 'When you are hit by an Attacking Maneuver, you may use this '
        'Counter Maneuver. Make a Strike Roll with your Shield-Category '
        'Weapon against the Dice Score Strike Roll rolled for that Attacking '
        'Maneuver. If you win, the Weapon used for this Maneuver is hit '
        'instead of you.',
  ),
  ManeuverDef(
    name: 'Brace Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Prepare yourself to withstand the weather.',
    effect: 'Until the start of your next turn, treat all Battle Weathers as '
        'if they were 1 Weather Tier lower. If this would reduce the Weather '
        'Tier to 0, ignore the effects of that Battle Weather. If you have '
        '4+ Skill Ranks in Survival, you may treat it as 2 Weather Tiers '
        'lower instead.',
  ),
  ManeuverDef(
    name: 'Dirty Trick Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Refusing to accept failure, you’ll cheat, lie, and '
        'connive your way to victory.',
    effect: 'When you use this Special Maneuver, target a Character within a '
        'Sphere AoE (centered on you). Make a Clash (Bluff vs Intuition) '
        'against that Character. If you win, apply one of the following '
        'effects:\n'
        'Pocket Sand: Your target gains the Blinded Combat Condition until '
        'the end of your turn.\n'
        'Made ya look!: Your target gains the Guard Down Combat Condition '
        'until the end of your turn or until they are hit by an Attacking '
        'Maneuver (whichever comes first).\n'
        'It’s Such a Tragedy!: Your target gains the Compelled Combat '
        'Condition until the end of their turn against a target of your '
        'choice. Additionally, if you scored a Critical Result or your '
        'target scored a Botch Result in your Clash, they must either use '
        'the Transformation Maneuver or Power Up Maneuver during their next '
        'turn. You can only use this effect once per Combat Encounter.',
  ),
  ManeuverDef(
    name: 'Eject Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Encounter',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    minions: 'N/A',
    kpCost: 'N/A',
    flavor: 'Escape from your vehicle in a hurry!',
    effect: 'Immediately leave a Vehicle/Battle Jacket and move a number of '
        'Squares away from the Vehicle/Battle Jacket in a straight line '
        'equal to your number of Skill Ranks in Piloting. If that '
        'Vehicle/Battle Jacket was targeted for an Attacking Maneuver when '
        'you used this effect, and you were the Pilot, carry out that '
        'Attacking Maneuver against the Vehicle/Battle Jacket as if you were '
        'still the Pilot.',
  ),
  ManeuverDef(
    name: 'Feint Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    minions: 'N/A',
    kpCost: '2(T)',
    flavor: 'Draw your opponent’s attention away from your true '
        'intentions before you strike!',
    effect: 'Target an Opponent within your Melee Range. Make a Clash (Bluff '
        'vs Intuition/Perception) against that Opponent. If you win, you may '
        'use the Basic Attack Maneuver as an Out-of-Sequence Maneuver. '
        'Increase the Strike and Wound Rolls for this Attacking Maneuver by '
        '1(T) and your Opponent cannot use the Defend Maneuver in response '
        'to this Attacking Maneuver, but this Attacking Maneuver cannot '
        'possess an AoE and you cannot Ki Wager more than 1/4 (rounded up) '
        'of your Maximum Capacity on this Attacking Maneuver.',
  ),
  ManeuverDef(
    name: 'Flip Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Acrobatically maneuver yourself away from your opponent!',
    effect: 'Move a number of Squares up to twice your number of Skill Ranks '
        'in Acrobatics (you may move through Squares occupied by an '
        'Opponent, as long as you do not end your movement on an occupied '
        'Square). This movement does not provoke the Exploit Maneuver, even '
        'if you leave the Melee Range of an Opponent.',
  ),
  ManeuverDef(
    name: 'Hide Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Get out of sight to get the drop on your opponents.',
    effect: 'Make a Skill Clash (Stealth vs Perception) against all of your '
        'Opponents (except those you are in the Melee Range of). If you win '
        'against an Opponent, you become Hidden from that Opponent.',
  ),
  ManeuverDef(
    name: 'Hijack Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'If you fail the Clash, you can be exploited by any '
        'Opponent (if you are within their Melee Range)',
    flavor: 'Take control over a vehicle driven by someone else!',
    effect: 'Target an adjacent Vehicle or Battle Jacket. Make a Clash '
        '(Thievery vs Thievery/Acrobatics/Perception) against the Pilot of '
        'that Vehicle/Battle Jacket. If you win, you become the Pilot of '
        'that Vehicle/Battle Jacket and the former Pilot is moved to an '
        'unoccupied Square of your choice outside of that Vehicle/Battle '
        'Jacket.',
  ),
  ManeuverDef(
    name: 'Holding Back Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    minions: 'Free',
    kpCost: 'N/A',
    flavor: 'Hold back your power to avoid detection or warm up in a fight.',
    effect: 'Gain any number of Holding Back Stacks up to an amount equal to '
        'your base Tier of Power. For each stack of Holding Back, reduce '
        'your Tier of Power by 1. If your number of Holding Back Stacks is '
        'equal to your base Tier of Power, reduce your Combat Rolls by 1(bT) '
        'and set your Tier of Power to 1.\n'
        'For each stack of Holding Back you possess, increase the Skill '
        'Bonus for your Concealment Skill Checks by 1 (max. 3).\n'
        'If you already possess a Holding Back Stack, you can instead choose '
        'to remove any number of them or gain more up to your maximum.',
  ),
  ManeuverDef(
    name: 'Hype Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Hype the crowds, your allies, or yourself with a powerful '
        'performance.',
    effect: 'You become Hyped! While Hyped, increase your Combat Rolls by '
        '1(T)+1/4 (rounded up) of your Personality Modifier until the end of '
        'your next turn.',
  ),
  ManeuverDef(
    name: 'Insult Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'If physical attacks don’t work, emotional ones just '
        'might!',
    effect: 'Target an Opponent and make a Morale Clash against them. If you '
        'win, the target suffers from the Impaired Combat Condition and '
        'gains the Compelled Combat Condition against you until the end of '
        'your next turn.',
  ),
  ManeuverDef(
    name: 'Internal Attack Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    kpCost: '6(T)',
    exploitable: 'N/A',
    flavor: 'You are able to enter a target’s body and attack them '
        'from within!',
    effect: 'Target an Opponent within your Melee Range. Make a Clash '
        '(Impulsive vs Impulsive/Corporeal) against them. If you win, remove '
        'yourself from the Combat Encounter (record your Initiative) and '
        'while you are not a member of the Combat Encounter, reduce their '
        'Soak Value and Defense Value by 2(T). As an Instant Maneuver, '
        'despite not being involved in the Combat Encounter, you can appear '
        'on a Square adjacent to the target of this Maneuver, re-enter the '
        'Combat Encounter (using your recorded Initiative), and reduce their '
        'Life Points by 2x your Might.',
  ),
  ManeuverDef(
    name: 'Intuit Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Following your gut, you predict your opponent’s next '
        'move.',
    effect: 'Target an Opponent, that Opponent becomes ‘Seen’ '
        'until the end of your next turn. Increase the Dice Score of your '
        'Skill Checks and Saving Throws in Clashes against a Seen Opponent '
        'by 2 and 1(T) respectively.',
  ),
  ManeuverDef(
    name: 'Liquid Form Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    minions: 'N/A',
    kpCost: 'N/A',
    flavor: 'You are able to liquefy your body, allowing you to become '
        'amorphous, move as you please, and fit into smaller spaces.',
    effect: 'You enter the Liquid Special State. If you use this Maneuver '
        'while in the Liquid Special State, you exit the Liquid Special '
        'State.',
  ),
  ManeuverDef(
    name: 'Magic Trick Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'If you fail the initial Clash, this triggers the Exploit '
        'Maneuver from the target.',
    flavor: 'You use your mystical prowess to manipulate the battlefield, '
        'moving yourself and your enemies around at-will.',
    effect: 'Apply one of the following effects:\n'
        '• Target an Opponent within your Melee Range. Make a Clash (Use '
        'Magic vs Intuition/Use Magic) against them. If you win, the target '
        'gains the Impaired Combat Condition until the start of your next '
        'turn.\n'
        '• Target a Character within your Melee Range. Make a Clash (Use '
        'Magic vs Intuition/Use Magic) against them. If you win, move that '
        'target by a number of Squares equal to your number of Skill Ranks '
        'in the Use Magic Skill.\n'
        '• Move a number of Squares equal to your number of Skill Ranks in '
        'the Use Magic Skill. This movement does not trigger the Exploit '
        'Maneuver.',
  ),
  ManeuverDef(
    name: 'Possess Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    kpCost: 'N/A',
    exploitable: 'If you fail the initial Clash, this triggers the Exploit '
        'Maneuver from the target.',
    flavor: 'You invade your target’s body, taking them over from '
        'within.',
    effect: 'Target a Character within your Melee Range. Make a Clash '
        '(Strike vs Strike/Dodge) against them. If you win, make a second '
        'Clash (Impulsive) against that Character. If you lose this Clash, '
        'your Opponent suffers from the Guard Down Combat Condition until '
        'the end of the current turn. If you win, your Character is removed '
        'from the Combat Encounter. Give the target of this Maneuver the '
        'Overtaken Awakening as a Level 2 Temporary Awakening and then gain '
        'control of that Character as long as they still possess the '
        'Overtaken Awakening with your Character as the Possessing '
        'Character.',
  ),
  ManeuverDef(
    name: 'Power Drain Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: 'Variable',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Steal life force energy from an opponent.',
    effect: 'You can only use this Maneuver if you are in a Grapple Maneuver '
        'as the Grappler. Target the Grappled and spend up to 3 Actions. For '
        'each Action you spend, reduce their Life and Ki Points by 1/2 '
        '(rounded up) of your Might and regain Ki Points equal to the total '
        'amount of Ki Points lost by the target.',
  ),
  ManeuverDef(
    name: 'Repair Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Encounter',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Take a moment during battle to take care of your gear.',
    effect: 'Make a Craft Skill Check against the Craft DC of a Weapon/piece '
        'of Apparel you possess OR a Vehicle/Battle Jacket you are adjacent '
        'to. If you succeed, depending on the chosen Item: restore the Life '
        'Points of the Weapon/Vehicle/Battle Jacket by 2d10(bT) plus your '
        'Skill Bonus for the relevant Craft Skill Specialization or regain 2 '
        'Break Value for that piece of Apparel.',
  ),
  ManeuverDef(
    name: 'Search Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Look for a hidden opponent!',
    effect: 'Target an Opponent that is Hidden from you. Make a Skill Clash '
        '(Perception vs Stealth) against them. If you win, you are no longer '
        'Oblivious of them.',
  ),
  ManeuverDef(
    name: 'Sense Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Free',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Lock on to the energy of an opponent.',
    effect: 'Target an Opponent. Make a Skill Clash (Clairvoyance vs '
        'Concealment) against them. If you win, you can tell how many stacks '
        'of Holding Back they possess and if they are currently in their '
        'Transformation with the highest Tier of Power Requirement (you do '
        'not know which Transformation they possess – you just have a '
        'general feeling whether or not they are still holding back their '
        'full power).',
  ),
  ManeuverDef(
    name: 'Snatch Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Take something being held by your opponent!',
    effect: 'Target an Opponent within your Melee Range who you know '
        'possesses a certain Basic Item. Make a Skill Clash (Thievery vs '
        'Perception/Thievery). If you win, you take that Basic Item from '
        'that Opponent.',
  ),
  ManeuverDef(
    name: 'Soar Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Soar through the skies like a bird!',
    effect: 'Increase your Defense Value by 1(bT) until the start of your '
        'next turn. Additionally, if not in a High Environment, you can '
        'enter the Low Sky Environment. If in a High Environment, you can '
        'increase your rank of High Environment by +/- 1 Rank, where if it '
        'would become 0 then you enter the normal Battle Environment for the '
        'Square you are occupying.',
  ),
  ManeuverDef(
    name: 'Tail Attack Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    minions: 'Free',
    kpCost: '2(T)',
    flavor: 'Strike out at an opponent using your tail.',
    effect: 'Target an Opponent with an Unarmed Attacking Maneuver using the '
        'Simple Profile. When you first gain access to this Special '
        'Maneuver, you may select one of these additional effects to have '
        'access to while you have access to this Maneuver:\n'
        'Elongated. You may increase the KP Cost of this Maneuver by 2(T) to '
        'instead use the Sweeping Profile.\n'
        'Multiple. You may increase the KP Cost of this Maneuver by 2(T) to '
        'instead use the Combination Profile of the Physical Foundation.\n'
        'Spiked. You may increase the KP Cost of this Maneuver by 4(T) to '
        'instead use the Crushing Profile.\n'
        'Heavy. You may increase the KP Cost of this Maneuver by 6(T) to '
        'instead use the Powered Profile.\n'
        'Attacking Maneuvers made through the Tail Attack Maneuver do not '
        'suffer from, or count towards, the penalty from Diminishing '
        'Offense.',
  ),
  ManeuverDef(
    name: 'Talk Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    kpCost: 'N/A',
    exploitable: 'If you fail the initial Clash, this triggers the Exploit '
        'Maneuver from the target.',
    flavor: 'You verbally approach someone in an attempt to help them '
        'reclaim their own mind.',
    effect: 'Target a Character who is suffering from the Compelled Combat '
        'Condition or is in a Transformation with the Rampaging Aspect, or '
        'has been made an Ally of one of your Opponents through the effects '
        'of Manipulation Sorcery or Mystic Talisman.\n'
        'If the Character is suffering from the Compelled Combat Condition '
        'or is in a Transformation with the Rampaging Aspect, make an Urgent '
        'Clash (Morale) against them. If you win, they may ignore the '
        'effects of the Rampaging Aspect until the end of their next turn '
        'and immediately leave the Compelled Combat Condition.\n'
        'If the Character was turned into an Ally through the effects of '
        'Manipulation Sorcery or Mystic Talisman, make a Clash '
        '(Cognitive/Morale) against the Character that turned them into '
        'their Ally. If you win, they stop being an Ally of that Character. '
        'If you lose, you cannot target that Character with the Talk '
        'Maneuver again during this Combat Encounter.',
  ),
  ManeuverDef(
    name: 'Terrify Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'N/A',
    flavor: 'Intimidate an opponent into submission.',
    effect: 'Target an Opponent within 4 Squares of you. Make a Skill Clash '
        '(Intimidation vs Intuition/Intimidation) against them. If you win, '
        'your target gains the Shaken Combat Condition until the end of your '
        'next turn. If they already possessed the Shaken Combat Condition, '
        'they are additionally knocked Prone.\n'
        'Reduce the Dice Score of your Skill Clash by 2 if your target is of '
        'a higher Tier of Power than you.',
  ),
  ManeuverDef(
    name: 'Transfiguration Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    kpCost: '10(T)',
    exploitable: 'All adjacent Opponents. If you are knocked through a '
        'Health Threshold due to an Attacking Maneuver from the Exploit '
        'Maneuver in response to this Maneuver, you automatically fail the '
        'Strike Roll for this Maneuver’s effects.',
    flavor: 'Transform your target into an object of some kind.',
    effect: 'Make a Clash (Physical Strike vs Strike/Dodge) against an '
        'Opponent within your Melee Range. If you win, choose an Item – '
        'your Opponent becomes that Item until the end of the Combat '
        'Encounter and has their Size Category changed to suit this Item '
        '(your ARC decides). This Opponent is Transfigured.\n'
        'After your Opponent becomes an Item, make a Might Clash against '
        'that Opponent, though if that Opponent’s Tier of Power is '
        'higher than yours, reduce your Dice Score for this Clash by 1(T). '
        'If you win this second Clash, the Transfigured Opponent, for all '
        'intents and purposes, becomes that Item and cannot make any type of '
        'Maneuver until the end of the Combat Encounter (after which, if '
        'they are still alive, they return to normal). If that Item would be '
        'destroyed or used up (such as a Snack), that Character dies. They '
        'must spend a Karma Point to avoid dying and have their body appear '
        'in the closest unoccupied Square. They are still Defeated.\n'
        'If you target a Character turned into an Item with the '
        'Transfiguration Maneuver, turn them back to normal.\n'
        'A Character targeted by this Maneuver may spend 1 Counter Action. '
        'If they do, and they beat the initial Clash for the effects of the '
        'Transfiguration Maneuver, then you must change the target of this '
        'use of the Transfiguration Maneuver to yourself and make the rolls '
        'as if you were targeted by another Character (all rolls involved '
        'become Urgent).',
  ),
  ManeuverDef(
    name: 'Treatment Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Heal an ally’s wounds.',
    effect: 'Target an Ally within your Melee Range. Increase their Life '
        'Points by 2d10(bT) plus your Skill Bonus in Medicine. If an Ally is '
        'suffering from the Poisoned Combat Condition, you can reduce the '
        'amount of Life Points they gain by 1/2 to make a Skill Clash '
        '(Medicine vs Medicine/Craft: Basic Item) against the Character who '
        'gave that character the Poisoned Combat Condition. If you win, '
        'remove the Combat Condition. If they gained the Poisoned Combat '
        'Condition other than through the effects of another Character, '
        'simply make an Medicine Skill Check with the Apprentice Difficulty '
        'to remove the poison.',
  ),
  ManeuverDef(
    name: 'Unify Maneuver',
    kind: ManeuverKind.special,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '3 Actions',
    minions: 'N/A',
    kpCost: 'N/A',
    exploitable: 'All adjacent Opponents.',
    flavor: 'Combine with another willing ally to increase your power even '
        'further!',
    effect: 'Target a willing member of your Race (except a Minion) on an '
        'adjacent Square to Unify with (they may even be Defeated, as long '
        'as they can give consent). That targeted Character is removed from '
        'the Combat Encounter and becomes a part of you. You gain a stack of '
        'the Unified Lesser Awakening as a Level 1 Temporary Awakening with '
        'the targeted Character as the Merged Character (if you '
        'haven’t reached your Awakening Limit for your Lesser '
        'Awakenings, you must permanently take this Awakening at the end of '
        'this Combat Encounter) and recover Life and Ki Points equal to '
        '2d10(bT) plus the target’s Surgency (for this calculation, use '
        'your target’s base Tier of Power).',
  ),
];

/// God Maneuvers (God Ki page, verbatim). Special Maneuvers only available to
/// those with access to Divine Ki Points — they must be gained through a
/// Trait, and spend Divine Ki Points (DKP) to use.
const List<ManeuverDef> kDbuGodManeuvers = [
  ManeuverDef(
    name: 'Divine Attack',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: 'Variable',
    flavor: 'You attack with divine might.',
    effect: 'Make an Attacking Maneuver as if this was the Basic Attack '
        'Maneuver. The DKP Cost is equal to the KP Cost of your chosen '
        'Profile, after applying any reductions from effects, and is paid '
        'instead of it. This Attacking Maneuver has its Damage Category '
        'increased by 1 category.',
  ),
  ManeuverDef(
    name: 'Divine Breathing',
    kind: ManeuverKind.instant,
    limit: '1/Encounter',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    costLabel: 'DKP',
    kpCost: '5(bT)',
    flavor: 'You recover health with your godly energy.',
    effect: 'Regain 5d10(bT) Life Points. This is considered a Healing Surge '
        'for effects, and applies Surgency.',
  ),
  ManeuverDef(
    name: 'Divine Counter',
    kind: ManeuverKind.counter,
    limit: '1/Round',
    maneuverType: 'Counter Maneuver',
    actionCost: '1 Counter Action',
    costLabel: 'DKP',
    kpCost: '2(T)',
    flavor: 'Repel an enemy’s attack with holy power.',
    effect: 'If you are targeted by an Opponent’s Attacking Maneuver, use the '
        'Basic Attack Maneuver against that Opponent as an Out-of-Sequence '
        'Maneuver. If this Attacking Maneuver knocks your Opponent through a '
        'Health Threshold or Defeats them, their Attacking Maneuver is '
        'canceled. They regain any Ki Points and Capacity Rate spent on that '
        'Attacking Maneuver, but still lose the Action Cost.',
  ),
  ManeuverDef(
    name: 'Divine Flame',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: '2(bT)',
    flavor: 'Imbue yourself with divine strength.',
    effect: 'Gain 2 stacks of Power until the end of your next turn and regain '
        'Ki Points equal to the Divine Ki Points spent on this Maneuver. This '
        'Maneuver is considered the Power Up Maneuver for any effects.',
  ),
  ManeuverDef(
    name: 'Divine Flex',
    kind: ManeuverKind.counter,
    limit: '1/Round',
    maneuverType: 'Counter Maneuver',
    actionCost: '1 Counter Action',
    costLabel: 'DKP',
    kpCost: '2(bT)',
    flavor: 'You can shrug off hits with heavenly grace.',
    effect: 'If you are targeted by an Opponent’s Attacking Maneuver, reduce '
        'the Damage Category of that Attacking Maneuver by 1 Category. This '
        'Maneuver is treated as the Direct Hit option of Defend Maneuver for '
        'any effects and gains its effects.\n'
        'If you receive 0 Damage from that Attacking Maneuver, while no other '
        'effect took the Damage (such as the Barrier Bubble Unique Ability or '
        'a Ki Entity/Refractive Dragon), reduce that Opponent’s Life Points '
        'by your Soak Value.',
  ),
  ManeuverDef(
    name: 'Divine Movement',
    kind: ManeuverKind.instant,
    limit: '1/Round, 3/Encounter',
    maneuverType: 'Instant Maneuver',
    actionCost: 'N/A',
    costLabel: 'DKP',
    kpCost: '4(bT)',
    flavor: 'Dart across the battlefield with divine speed.',
    effect: 'Move to any Square within range of your Boosted Speed. This '
        'Movement does not trigger the Exploit Maneuver and is considered the '
        'Movement Maneuver for any of your effects.',
  ),
  ManeuverDef(
    name: 'Divine Pulse',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: 'Variable (1~2 Actions)',
    costLabel: 'DKP',
    kpCost: '1(bT) for each Action Spent',
    flavor: 'Give your Transformations a spark of godly might.',
    effect: 'This Maneuver functions as the Transformation Maneuver and gains '
        'its effects. For each Action spent on this Maneuver, reduce your '
        'Stress Bonus by 1 for the duration of this Maneuver, but increase the '
        'Attribute Modifier Bonus (FO/MA) for the Transformation you are '
        'attempting to enter by 1(T) until you leave that Transformation.',
  ),
  ManeuverDef(
    name: 'Divine Roar',
    kind: ManeuverKind.standard,
    limit: '1/Encounter',
    maneuverType: 'Standard Maneuver',
    actionCost: '2 Actions',
    costLabel: 'DKP',
    kpCost: '4(bT)',
    flavor: 'You let out a holy war cry, bringing mortals to their knees in '
        'awe of your might.',
    effect: 'Make a Might Clash against all Characters within a Destructive '
        'Sphere AoE (centered on you). If you win, the losing Character(s) '
        'gain the Guard Down and Impediment Combat Conditions until the end of '
        'your next turn. If that Opponent is a Minion (except a Special '
        'Minion), they are Defeated.',
  ),
  ManeuverDef(
    name: 'God Bind',
    kind: ManeuverKind.standard,
    limit: '1/Encounter',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: '4(T)',
    flavor: 'Restrain your enemies with divine force.',
    effect: 'Target an Opponent within your Melee Range. Make a Might Clash '
        'against that Opponent. If you win, they gain the Pinned Combat '
        'Condition. You must spend 2 Actions at the start of each of your '
        'turns to maintain the God Bind, if you choose not to, then the '
        'Character Pinned due to the effects of God Bind is freed.\n'
        'If an Opponent targets you with an Attacking Maneuver while inside of '
        'your Melee Range, you may use the God Bind Maneuver, targeting them, '
        'as an Out-of-Sequence Maneuver by spending 1 Counter Action. If they '
        'lose the Might Clash, their Attacking Maneuver is canceled and they '
        'lose any Ki Points and Actions spent on it.',
  ),
  ManeuverDef(
    name: 'God Strike',
    kind: ManeuverKind.standard,
    limit: '1/Round',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: 'Varies',
    flavor: 'Infuse your attacks with extra power thanks to your godly skill.',
    effect: 'Upon gaining access to this God Maneuver, select a Profile. The '
        'DKP Cost of this Maneuver equals 1/4 (rounded up) of the KP Cost of '
        'that Profile. When using this Maneuver, use the Basic Attack Maneuver '
        'as an Out-of-Sequence Maneuver. Apply the selected Profile to that '
        'Attacking Maneuver.',
  ),
  ManeuverDef(
    name: 'God Finisher',
    kind: ManeuverKind.standard,
    limit: '1/Encounter',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: 'Varies',
    flavor: 'Annihilate your enemies with a holy smite.',
    effect: 'Upon gaining access to this God Maneuver, create a Signature '
        'Technique with a total TP Cost of 50 or less (you do not spend any '
        'Technique Points) and the Required State (God Ki) Disadvantage. You '
        'may only use this Signature Technique through the God Finisher '
        'Maneuver, and the God Finisher Maneuver can only use that Signature '
        'Technique. The God Finisher Maneuver, otherwise, acts exactly as the '
        'Signature Technique Maneuver, and is considered the Signature '
        'Technique Maneuver for any effects. The DKP Cost is equal to the KP '
        'Cost of that Signature Technique, and is paid instead of it.',
  ),
  ManeuverDef(
    name: 'Holy Transformation',
    kind: ManeuverKind.standard,
    limit: '1/Encounter',
    maneuverType: 'Standard Maneuver',
    actionCost: '1 Action',
    costLabel: 'DKP',
    kpCost: '2(T)',
    flavor: 'Transform with divine ease.',
    effect: 'Enter a Transformation with the God Ki Aspect. You do not roll a '
        'Stress Test for entering the Transformation, but any subsequent '
        'Stress Tests are rolled as usual. This Maneuver is considered the '
        'Transformation Maneuver for any effects.',
  ),
];

/// Every Maneuver across all six lists.
List<ManeuverDef> get kDbuAllManeuvers => [
      ...kDbuStandardManeuvers,
      ...kDbuInstantManeuvers,
      ...kDbuCounterManeuvers,
      ...kDbuModifierManeuvers,
      ...kDbuSpecialManeuvers,
      ...kDbuGodManeuvers,
    ];

// ============================================================================
// Battle Weather (Battle Weather page, verbatim)
// ============================================================================

class BattleWeatherDef {
  const BattleWeatherDef({
    required this.name,
    required this.connectedProfile,
    required this.flavor,
    required this.tierEffects,
  });

  final String name;

  /// The site's "–Connected Profile:" line.
  final String connectedProfile;

  final String flavor;

  /// Verbatim effect text per Weather Tier (index 0 = Natural (1), 1 =
  /// Unnatural (2), 2 = Cataclysmic (3)). "Each Tier gains the effects of
  /// the earlier Tiers."
  final List<String> tierEffects;
}

/// The three Weather Tier names, indexed by tier − 1.
const List<String> kWeatherTierNames = [
  'Natural (1)',
  'Unnatural (2)',
  'Cataclysmic (3)',
];

const List<BattleWeatherDef> kDbuBattleWeathers = [
  BattleWeatherDef(
    name: 'Hot Weather',
    connectedProfile: 'Elemental (Fire)',
    flavor: 'The extreme heat is enough to make even powerful warriors '
        'sweat!',
    tierEffects: [
      'Reduce the Dice Score of your Steadfast Checks by 1(WT).',
      'Halve your Soak Value.',
      'At the start of each Combat Round, reduce your Life Points by '
          '10(bT).',
    ],
  ),
  BattleWeatherDef(
    name: 'Cold Weather',
    connectedProfile: 'Elemental (Ice)',
    flavor: 'The chilling cold seeps into your bones, freezing you to the '
        'core.',
    tierEffects: [
      'Reduce the Dice Score of your Saving Throws by 1(WT).',
      'Halve your Surgency.',
      'At the start of each Combat Round, reduce your Ki Points by 10(bT).',
    ],
  ),
  BattleWeatherDef(
    name: 'Tornado Weather',
    connectedProfile: 'Elemental (Wind)',
    flavor: 'Strong, cyclical winds lift the terrain and block visibility, '
        'buffering you around the battlefield.',
    tierEffects: [
      'Reduce your Speeds and Defense Value by 2(WT).',
      'Halve your Haste.',
      'Upon the creation of this Battle Weather, the creator (ARC or '
          'otherwise) will select a point within the Battle Weather to be '
          'the epicenter. At the start of each Combat Round, you are moved 3 '
          'Squares towards the epicenter in the most direct path possible '
          '(if any Feature or Character is in the way, then proceed to '
          'follow the typical rules for Collision).',
    ],
  ),
  BattleWeatherDef(
    name: 'Storm Weather',
    connectedProfile: 'Elemental (Lightning)',
    flavor: 'A flash of lightning illuminates the sky as a crash of thunder '
        'shatters the skies overhead, randomly striking down anyone willing '
        'to brave the storm.',
    tierEffects: [
      'At the start of each Combat Round, roll a 1d10. If the result is a '
          '1(WT) or lower, you are struck by Lightning. Reduce your Life '
          'Points by 6(WT).',
      'Halve your Awareness.',
      'If you are struck by Lightning, you suffer from the Impediment '
          'Combat Condition until the end of the Combat Round.',
    ],
  ),
  BattleWeatherDef(
    name: 'Earthquake Weather',
    connectedProfile: 'Elemental (Earth)',
    flavor: 'The ground beneath your feet rumbles, shakes, and splits open, '
        'endangering everyone for miles around.',
    tierEffects: [
      'While you are not in a High Environment, reduce your Might by '
          '1(WT).',
      'While you are not in a High Environment, halve your Defense Value.',
      'At the start of each Combat Round, if you are not in a High '
          'Environment, you are knocked Prone.',
    ],
  ),
  BattleWeatherDef(
    name: 'Vile Weather',
    connectedProfile: 'Elemental (Poison)',
    flavor: 'Poison rains down from the skies or bubbles up from below the '
        'surface, filling the air with deadly toxin.',
    tierEffects: [
      'You score a Botch Result for a Combat Roll on a Natural Result of '
          '2(WT) or lower.',
      'Reduce the Dice Score of your Stress Tests by 1(WT).',
      'Reduce all of your Combat Rolls by 1(bT).',
    ],
  ),
];

// ============================================================================
// Battle Environments (Battle Environments page, verbatim)
// ============================================================================

class BattleEnvironmentDef {
  const BattleEnvironmentDef({
    required this.name,
    required this.hardnessRank,
    required this.flavor,
    required this.effects,
    this.isHigh = false,
  });

  final String name;

  /// Verbatim "–Hardness Rank:" line.
  final String hardnessRank;

  final String flavor;

  /// Verbatim "–Effects:" text ("N/A" when none).
  final String effects;

  /// True for the four High Environments (Low Sky → Deep Space).
  final bool isHigh;
}

const List<BattleEnvironmentDef> kDbuBattleEnvironments = [
  BattleEnvironmentDef(
    name: 'Standard Environment',
    hardnessRank: '1~5 (decided by the ARC)',
    flavor: 'The typical environment that most DBU fights will take place '
        'in, representing a solid floor.',
    effects: 'N/A',
  ),
  BattleEnvironmentDef(
    name: 'Soft Environment',
    hardnessRank: '0',
    flavor: 'An environment where the ground is soft and pliable, making it '
        'difficult to quickly get back up.',
    effects: 'If a Character collides with a Square of this Battle '
        'Environment, they are knocked Prone.',
  ),
  BattleEnvironmentDef(
    name: 'Bog Environment',
    hardnessRank: '0~1 (decided by the ARC)',
    flavor: 'A harsh environment where the ground is a bog, sapping the '
        'strength from anyone who finds themselves caught in it.',
    effects: 'While in this Battle Environment, reduce all of your Combat '
        'Rolls by 1(bT) and halve your Speed.',
  ),
  BattleEnvironmentDef(
    name: 'Lava Environment',
    hardnessRank: '3',
    flavor: 'A harsh environment where the ground is molten and excessively '
        'hot, but not enough to be completely submerged.',
    effects: 'This Environment possesses the Aflame Environmental Quality.\n'
        'If you end your Turn in this Battle Environment, gain a stack of '
        'the Broken Combat Condition until the start of your next turn.',
  ),
  BattleEnvironmentDef(
    name: 'Underwater Environment',
    hardnessRank: '0',
    flavor: 'A harsh environment where the water is deep enough to even '
        'submerge an Oozaru and where holding one’s breath is a '
        'necessity for most.',
    effects: 'This is an Unbreathable Environment.\n'
        'While in this Battle Environment, halve your Normal Speed.',
  ),
  BattleEnvironmentDef(
    name: 'Magma Environment',
    hardnessRank: '4',
    flavor: 'A harsh environment with deep pools of underground molten '
        'rock, where the amount is enough to submerge even a giant.',
    effects: 'This is an Unbreathable Environment.\n'
        'This Environment possesses the Aflame Environmental Quality.\n'
        'If you end your Turn in this Battle Environment, gain 2 stacks of '
        'the Broken Combat Condition until the start of your next turn.',
  ),
  BattleEnvironmentDef(
    name: 'Low Sky Environment',
    hardnessRank: 'N/A',
    isHigh: true,
    flavor: 'High above the landscape, where nothing interferes with the '
        'battle.',
    effects: 'N/A',
  ),
  BattleEnvironmentDef(
    name: 'High Sky Environment',
    hardnessRank: 'N/A',
    isHigh: true,
    flavor: 'Above the clouds, with space hanging above.',
    effects: 'Battle Weather cannot exist in this Battle Environment.',
  ),
  BattleEnvironmentDef(
    name: 'Local Space Environment',
    hardnessRank: 'N/A',
    isHigh: true,
    flavor: 'Battles above a nearby planet.',
    effects: 'This is an Unbreathable Environment.\n'
        'Battle Weather cannot exist in this Battle Environment.\n'
        'All Attacking Maneuvers possess the Knockback Advantage in this '
        'Environment. If an Attacking Maneuver already possesses the '
        'Knockback Advantage, increase your Might by 1(bT) for the Might '
        'Clash initiated by the Knockback Advantage and for calculating the '
        'number of Squares the target(s) of that Attacking Maneuver are '
        'moved.',
  ),
  BattleEnvironmentDef(
    name: 'Deep Space Environment',
    hardnessRank: 'N/A',
    isHigh: true,
    flavor: 'No air. No Battle Weather. Final destination.',
    effects: 'This is an Unbreathable Environment.\n'
        'Battle Weather cannot exist in this Battle Environment.\n'
        'All Attacking Maneuvers possess the Knockback Advantage in this '
        'Environment. If an Attacking Maneuver already possesses the '
        'Knockback Advantage, increase your Might by 2(bT) for the Might '
        'Clash initiated by the Knockback Advantage and for calculating the '
        'number of Squares the target(s) of that Attacking Maneuver are '
        'moved.',
  ),
];

/// Environmental Qualities (Battle Environments page, verbatim) — applied on
/// a Square-by-Square basis by the ARC. Shown as reference on the Combat
/// page's Battlefield card; a selected Environment that names one (e.g.
/// Lava's Aflame) also feeds it into the phase reminders.
const List<CombatRuleEntry> kDbuEnvironmentalQualities = [
  CombatRuleEntry(
    'Aflame',
    'If you start or end your Turn in this Battle Environment, reduce your '
        'Life Points by 2(bT). Increase this reduction by 1(bT) for every '
        'stack of the Broken Combat Condition you’re suffering from.',
  ),
  CombatRuleEntry(
    'Bouncy',
    'If you would Collide with this Square, halve the amount of Collision '
        'Damage you would receive and then you may move a number of Squares '
        'in any direction up to the Hardness Rank of this Square.',
  ),
  CombatRuleEntry(
    'Dangerous',
    'Double any Collision Damage you receive from this Environment.',
  ),
  CombatRuleEntry(
    'Electrified',
    'If you start or end your Turn in this Battle Environment, reduce your '
        'Life Points by 2(bT). If you end your turn in this Battle '
        'Environment, gain the Impediment Combat Condition until the start '
        'of your next turn.',
  ),
  CombatRuleEntry(
    'Frozen',
    'If you start or end your Turn in this Battle Environment, reduce your '
        'Ki Points by 4(bT). If you use the Movement Maneuver, either halve '
        'your Speed for the duration of that Maneuver or make an Acrobatics '
        'Skill Check with a Difficulty of Qualified. If you succeed, nothing '
        'happens. If you fail, you are knocked Prone instead (regain the '
        'Action and any Ki Points spent on this Maneuver).',
  ),
  CombatRuleEntry(
    'Glass',
    'This Square is encased in glass, increasing its Hardness Rank by 1. If '
        'this Environmental Quality is applied through an effect, remove all '
        'other Environmental Qualities on this Feature.',
  ),
  CombatRuleEntry(
    'Metallic',
    'This Square is made of metal. It must have a Hardness Rank of 3+. If '
        'this Environmental Quality is applied through an effect, remove all '
        'other Environmental Qualities on this Feature.',
  ),
  CombatRuleEntry(
    'Obscured',
    'While you occupy this Square, reduce your Strike Rolls, Dodge Rolls, '
        'and Impulsive Saves by 2(bT). This Environmental Quality can be '
        'applied to Squares within High Environments.',
  ),
  CombatRuleEntry(
    'Poisonous',
    'If you end your Turn in this Battle Environment, gain the Poisoned '
        'Combat Condition.',
  ),
];

/// Falling (High Environments): shown as a Start of Round reminder while an
/// airborne Environment is selected. Verbatim.
const String kFallingText =
    'At the start of the Combat Round, if you do not possess at least 1 '
    'Skill Rank in the Flight Skill, descend 1 rank of the High Environment. '
    'If you were in the Low Sky Environment, you must exit the Low Sky '
    'Environment and enter the non-High Battle Environment of the Square '
    'below. If you do, make an Acrobatics Skill Check (Qualified). If you '
    'succeed, nothing happens. If you fail, take Collision Damage from '
    'colliding with the Square you now occupy.';

/// Unbreathable Environments: Held Breath rules (verbatim) — surfaced while
/// an Unbreathable Environment is selected.
const String kUnbreathableText =
    'Upon entering an Unbreathable Environment, make a Survival Skill Check '
    '(unless you are Unnatural or otherwise unable to gain the Suffocating '
    'Combat Condition). For every Difficulty you exceed with this Dice '
    'Score, gain a stack of Held Breath. At the end of each Combat Round and '
    'each time you are knocked through a Health Threshold, you lose a stack '
    'of Held Breath. While you are in an Unbreathable Environment and have '
    'no stacks of Held Breath, you suffer from the Suffocating Combat '
    'Condition.';

// ============================================================================
// Light Levels (Light Levels page, verbatim)
// ============================================================================

class LightLevelDef {
  const LightLevelDef({
    required this.name,
    required this.value,
    required this.effect,
  });

  final String name;

  /// The site's −2..2 scale value.
  final int value;

  /// Verbatim effect ("No effect." for Normal).
  final String effect;
}

const List<LightLevelDef> kDbuLightLevels = [
  LightLevelDef(
    name: 'Pitch Black (-2)',
    value: -2,
    effect: 'Halve your Awareness, Defense Value, and the Skill Bonus for '
        'your Perception Skill.',
  ),
  LightLevelDef(
    name: 'Dark (-1)',
    value: -1,
    effect: 'Reduce your Awareness and Defense Value by 2(bT) and reduce '
        'the Skill Bonus for your Perception Skill by 2.',
  ),
  LightLevelDef(
    name: 'Normal (0)',
    value: 0,
    effect: 'No effect.',
  ),
  LightLevelDef(
    name: 'Bright (1)',
    value: 1,
    effect: 'Reduce your Awareness and Defense Value by 2(bT) and reduce '
        'the Skill Bonus for your Perception Skill by 2.',
  ),
  LightLevelDef(
    name: 'Blinding (2)',
    value: 2,
    effect: 'Halve your Awareness, Defense Value, and the Skill Bonus for '
        'your Perception Skill.',
  ),
];
