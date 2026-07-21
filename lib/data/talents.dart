/// talents.dart
/// ---------------------------------------------------------------------------
/// Talents catalogue (Player → Talents page), verbatim from the site
/// (confirmed 05 July 2026). Mirrors the shape of `race_traits.dart`/
/// `factor_traits.dart` deliberately, reusing their automation/option
/// machinery (`RaceTraitAutomation`, `RaceTraitOptionGroup`) so the
/// Information page's existing rendering/automation pipeline works on
/// Talents unmodified.
///
/// FRAMEWORK (talents page, verbatim): "Talents are a special feature that
/// gives your character a new capability or improves one that you already
/// have." / "At Character Creation you gain 4 free Talents of your choice,
/// each from a different Talent Category, and you gain a free Talent at
/// each Tier of Power reached starting from Tier of Power 2 ... You can take
/// each Talent only once, unless the Talent's description says otherwise."
/// / "Some Talents have prerequisites. Your character must have the
/// indicated Attribute Score, additional Talent, or other Aptitude
/// designated to take that Talent ... if you ever lose a Talent's
/// prerequisite, you can't use the Talent again until you regain it."
/// Prerequisites are shown as reference text, same as Factors'
/// `prerequisiteText` — not programmatically enforced.
///
/// AUTOMATION: like `race_traits.dart`, only Talents with a clean,
/// unconditional (or simply-conditioned, e.g. per-Health-Threshold-below)
/// additive bonus to a stat this app already tracks via `AffectedStat` are
/// auto-applied. The overwhelming majority of Talents rely on mechanics this
/// app doesn't simulate (per-Maneuver choices, Clashes, opponent-state
/// conditions, un-tracked resources, dice-category shifts, ally-targeted
/// buffs) and are recorded as verbatim text only — the player applies them
/// manually.
library;

import 'dbu_rules.dart';
import 'race_traits.dart';

/// The 33 Talent Category headings from the Talents page (used to group the
/// catalogue and to satisfy "gain 4 free Talents, each from a different
/// Talent Category").
enum TalentCategory {
  attacking('Attacking'),
  balance('Balance'),
  buddy('Buddy'),
  condition('Condition'),
  counter('Counter'),
  damaging('Damaging'),
  dodging('Dodging'),
  durability('Durability'),
  energyAttack('Energy Attack'),
  grappling('Grappling'),
  initiative('Initiative'),
  insightful('Insightful'),
  magicAttack('Magic Attack'),
  mindful('Mindful'),
  minion('Minion'),
  mobility('Mobility'),
  multiType('Multi-Type'),
  physicalAttack('Physical Attack'),
  racial('Racial'),
  raging('Raging'),
  size('Size'),
  skill('Skill'),
  specialization('Specialization'),
  starter('Starter'),
  superStack('Super Stack'),
  surge('Surge'),
  taunt('Taunt'),
  teamwork('Teamwork'),
  technique('Technique'),
  threshold('Threshold'),
  transformation('Transformation'),
  weapon('Weapon'),
  miscellaneous('Miscellaneous');

  const TalentCategory(this.displayName);
  final String displayName;
}

/// A single Talent. Structurally similar to `RaceTraitDef`/`FactorTraitDef`
/// — see [isAutomated]/[automation].
class TalentDef {
  const TalentDef({
    required this.name,
    required this.category,
    required this.prerequisitesText,
    required this.description,
    this.automation = const [],
    this.optionGroups = const [],
    this.raceRestriction,
  });

  final String name;
  final TalentCategory category;

  /// Verbatim "–Prerequisites:" line — reference text, not programmatically
  /// enforced (matches `FactorDef.prerequisiteText`'s convention).
  final String prerequisitesText;

  /// Verbatim flavour text + numbered effects.
  final String description;

  final List<RaceTraitAutomation> automation;

  /// Character-Creation choice(s) offered by this Talent (rare — most
  /// Talents have no `[Option]` tag).
  final List<RaceTraitOptionGroup> optionGroups;

  /// For Racial Talents only: which Race this Talent requires (matches
  /// `RaceTraitDef.race` naming). Reference only, same as Factors'
  /// `raceRestriction` — not programmatically enforced beyond display.
  final String? raceRestriction;

  bool get isAutomated => automation.isNotEmpty;
  bool get hasOptions => optionGroups.isNotEmpty;
}

/// The full Talents catalogue — all 275 Talents from the Player → Talents
/// page, grouped by their on-site Talent Category headings.
const List<TalentDef> kDbuTalents = [
  // ========================================================== Attacking ===
  TalentDef(
    name: 'Artful Strike',
    category: TalentCategory.attacking,
    prerequisitesText: 'Insight Score of 4+',
    description: 'Masterfully able to weave through an opponent’s defense, '
        'you catch them unaware.\n'
        '(1)-[Passive]: Increase the Dice Category of your Critical Result '
        'Extra Dice by 1 Category for your Strike Rolls.\n'
        '(2)-[Triggered, 1/Round]: If your Strike Roll’s Natural Result is '
        '1 below the Critical Target, score a Critical Result on that '
        'Strike Roll.',
  ),
  TalentDef(
    name: 'Focused Strike',
    category: TalentCategory.attacking,
    prerequisitesText: 'Artful Strike, Insight Score of 6+',
    description: 'Able to pinpoint weak points in a target’s defense, your '
        'attacks hone in on the least guarded parts of the opponent’s body '
        'to land strikes consistently.\n'
        '(1)-[Passive]: Reduce the Critical Target of your Strike Rolls by '
        '1.\n'
        '(2)-[Triggered, 1/Round]: If you fail to hit an Opponent with an '
        'Attacking Maneuver, reroll your Strike Roll and apply it against '
        'the same roll you lost against.',
  ),
  TalentDef(
    name: 'Masterful Strike',
    category: TalentCategory.attacking,
    prerequisitesText: 'Focused Strike, Insight Score of 10+, Tier of Power '
        '3+',
    description: 'You are able to recover your momentum even when you '
        'miss, surprising your opponent with a strike that lands.\n'
        '(1)-[Passive]: Roll your Base Die twice for any Strike Roll and '
        'use the highest result.\n'
        '(2)-[Triggered/Start of Turn, 1/Encounter]: Until the end of your '
        'turn, ignore all penalties to your Strike Rolls.',
  ),

  // ============================================================ Balance ===
  TalentDef(
    name: 'Balanced Warrior',
    category: TalentCategory.balance,
    prerequisitesText: 'Force and Magic Scores of 4+',
    description: 'Proficient in combat and magic, you train to use both '
        'equally.\n'
        '(1)-[Passive]: While your Force and Magic Scores are equal to '
        'one another, increase the Attribute Modifiers for each Attribute '
        'by the Attribute Score of the other (this bonus plus the '
        'Attribute Score for each Attribute cannot exceed the Attribute '
        'Score Limit).\n'
        '(2)-[Passive]: Reduce the Ki Point Cost of all Attacking '
        'Maneuvers by 1(T).',
  ),
  TalentDef(
    name: 'Balanced Defender',
    category: TalentCategory.balance,
    prerequisitesText: 'Agility and Tenacity Scores of 4+',
    description: 'Focused on both the ability to avoid damage and the '
        'ability to withstand it, you are able to shift stances to do '
        'either effectively.\n'
        '(1)-[Passive]: While your Agility and Tenacity Scores are equal '
        'to one another, increase your Defense Value and Soak Value by '
        '1(T).\n'
        '(2)-[Triggered, 1/Round]: When targeted by an Attacking '
        'Maneuver, spend 2(bT) Ki Points to increase your Defense Value '
        'and Soak Value by 1(T) for the duration of that Maneuver.',
  ),
  TalentDef(
    name: 'Balanced Mind',
    category: TalentCategory.balance,
    prerequisitesText: 'Personality and Scholarship Scores of 4+, 2+ Skill '
        'Ranks in Performance and Investigation',
    description: 'Focusing on both social and intellectual pursuits has '
        'taught you how to effectively blend the two.\n'
        '(1)-[Passive]: While your Personality and Scholarship Scores are '
        'equal to each other, increase your Attribute Modifiers (SC/PE) '
        'by 1(T).\n'
        '(2)-[Passive]: While your Personality and Scholarship Scores are '
        'equal to each other and higher than the Attribute Score of your '
        'other Attributes, increase your Combat Rolls by 1(bT).\n'
        '(3)-[Triggered, 1/Encounter]: If you use the Hype Maneuver or '
        'the Analysis Maneuver, use the other Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Balanced in Yin and Yang',
    category: TalentCategory.balance,
    prerequisitesText: 'Balanced Warrior',
    description: 'Seeking enlightenment, you strive for inner balance and '
        'total control over your body.\n'
        '(1)-[Passive]: While your Force and Magic Attribute Scores are '
        'equal to one another, but at least 4 lower than your Insight '
        'Attribute Score, increase your Insight Modifier by 1(T).\n'
        '(2)-[Passive]: Reduce the Ki Point Cost of all Attacking '
        'Maneuvers by 1(T).',
  ),
  TalentDef(
    name: 'Jack of All Styles',
    category: TalentCategory.balance,
    prerequisitesText: 'Balanced Warrior or Balanced Defender',
    description: 'You are able to utilize a wide variety of techniques, '
        'but your diversity prevents you from truly specializing in any '
        'one style.\n'
        '(1)-[Passive]: Treat your Attribute Scores (AG/FO/TE/MA) as if '
        'they were 2(bT) higher for the Attribute Score Requirements of '
        'all Unique Abilities.\n'
        '(2)-[Triggered, 1/Round]: If you use a Unique Ability, increase '
        'your Wound Rolls by 2(T) until the end of your turn.',
  ),
  TalentDef(
    name: 'Lord of Balance',
    category: TalentCategory.balance,
    prerequisitesText: 'Balanced Warrior, Balanced Defender',
    description: 'The epitome of the balanced combat style, you are able '
        'to adapt offensively and defensively in equal measure.\n'
        '(1)-[Passive]: If you are benefiting from the first effects of '
        'Balanced Warrior and Balanced Defender, increase your Combat '
        'Rolls by 1(T).\n'
        '(2)-[Triggered/Start of Combat Round]: Regain 3(bT) Life and Ki '
        'Points.',
  ),
  TalentDef(
    name: 'Power of the Z-Warrior',
    category: TalentCategory.balance,
    prerequisitesText: 'Agility, Force or Magic, Tenacity, Insight, '
        'Scholarship, and Personality Scores of 4+',
    description: 'With a well-rounded approach to battle, you are a jack '
        'of all trades, but master of none.\n'
        '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
        '(2)-[Triggered, 1/Round, 2/Encounter]: When making any Combat '
        'Roll, instead of rolling your Base Die, set the Natural Result '
        'to 10. This will cause you to score a Critical Result.',
  ),

  // ============================================================== Buddy ===
  TalentDef(
    name: 'Buddy Collector',
    category: TalentCategory.buddy,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You have a lot of friends who will come to your aid '
        'when you need them.\n'
        '(1)-[Passive]: You may have 2 Buddies active at the same time.\n'
        '(2)-[Triggered, 1/Encounter]: If one of your Buddies is '
        'destroyed, you may call another Buddy as an Out-of-Sequence '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Buddy to Buddies',
    category: TalentCategory.buddy,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You are renowned for your kindness, and your reputation '
        'as “everyone’s friend” precedes you.\n'
        '(1)-[Passive]: While you have an active Buddy, increase your '
        'Morale Saves and Soak Value by 1(bT).\n'
        '(2)-[Triggered, 1/Encounter]: If your Buddy would be destroyed, '
        'you can dismiss them instead.',
  ),
  TalentDef(
    name: 'Buddy System',
    category: TalentCategory.buddy,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You know better than anyone not to go anywhere alone.\n'
        '(1)-[Passive]: While you have an active Buddy, increase the '
        'Dice Score of your Steadfast Checks by 1.\n'
        '(2)-[Triggered/Start of Combat Encounter]: You may spend 1 '
        'Karma Point to gain a Buddy of your choice (you cannot choose a '
        'Special Buddy).',
  ),

  // =========================================================== Condition ===
  TalentDef(
    name: 'Combat Tactician',
    category: TalentCategory.condition,
    prerequisitesText: 'N/A',
    description: 'You have learned to take advantage of your weakened '
        'opponents.\n'
        '(1)-[Passive]: Increase your Combat Rolls by 1(T) against any '
        'Opponent(s) that are suffering from a Combat Condition.',
  ),
  TalentDef(
    name: 'Perfected Tactics',
    category: TalentCategory.condition,
    prerequisitesText: 'Combat Tactician',
    description: 'Your brilliant tactics allow you to make the most of '
        'your opponents missteps.\n'
        '(1)-[Passive]: Increase your Wound Rolls by 1(T) against any '
        'Opponent(s) that are suffering from a Combat Condition.\n'
        '(2)-[Triggered, 1/Round]: If an Opponent within 4 Squares of you '
        'gains a Combat Condition, this provokes your Exploit Maneuver.',
  ),
  TalentDef(
    name: 'Beat-down Tactics',
    category: TalentCategory.condition,
    prerequisitesText: 'Combat Tactician, Tier of Power 2+',
    description: 'Your ability to capitalize on your opponent’s weak '
        'points is second to none.\n'
        '(1)-[Passive]: Increase your Might Clashes against an Opponent '
        'with a Combat Condition by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you knock an Opponent through a '
        'Health Threshold, they gain a stack of the Broken Combat '
        'Condition until the end of your next turn.',
  ),

  // ============================================================= Counter ===
  TalentDef(
    name: 'Wild Counter',
    category: TalentCategory.counter,
    prerequisitesText: 'N/A',
    description: 'Able to defend and attack in the same motion, you '
        'respond to being attacked with an attack of your own!\n'
        '(1)-[Triggered, 1/Round]: When you successfully avoid an '
        'Attacking Maneuver through the Parry effect of the Defend '
        'Maneuver, you can use the Basic Attack Maneuver against the '
        'attacking Opponent as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Fierce Counter',
    category: TalentCategory.counter,
    prerequisitesText: 'Wild Counter',
    description: 'Your counterattacks are stronger than most, striking '
        'with brutal efficiency.\n'
        '(1)-[Passive]: Increase your Strike Roll when using the Parry '
        'effect of the Defend Maneuver by 1(T).\n'
        '(2)-[Triggered, 1/Round]: When you use the Basic Attack Maneuver '
        'through the effects of Wild Counter, increase the Wound Roll '
        'for that Attacking Maneuver by 1(T).',
  ),
  TalentDef(
    name: 'Perfect Counter',
    category: TalentCategory.counter,
    prerequisitesText: 'Fierce Counter, Tier of Power 2+',
    description: 'Able to defend even without preparations, your ability '
        'to counterattack is peerless.\n'
        '(1)-[Passive]: The 1/Round Keyword on the first effect of Wild '
        'Counter becomes 3/Round.\n'
        '(2)-[Triggered, 1/Round]: When you are targeted by an Attacking '
        'Maneuver, use the Parry option of the Defend Maneuver without '
        'spending a Counter Action.',
  ),
  TalentDef(
    name: 'Jolt Counter',
    category: TalentCategory.counter,
    prerequisitesText: 'Tenacity or Personality Score of 6+',
    description: 'With the ability to dish it out as well as take it, '
        'you are skilled at turning the momentum of an attack against '
        'you into a more powerful blow against your attacker.\n'
        '(1)-[Passive]: Increase your Wound Roll when using the Cross '
        'Counter option of the Defend Maneuver by 2(T).\n'
        '(2)-[Triggered, 1/Encounter]: When using the Cross Counter '
        'option of the Defend Maneuver against an Attacking Maneuver '
        'that has at least 1 Energy Charge and/or a Ki Wager equal or '
        'higher than 1/4 of that character’s Max Capacity, you may Jolt '
        'Counter. If you do, you may choose to reduce the Dice Score of '
        'your Dodge Roll against your opponents’ Attacking Maneuver to '
        '0. If you do, increase your Strike Roll for your Attacking '
        'Maneuver by your Defense Value and increase the Damage Category '
        'of both your and your Opponent’s Attacking Maneuver by 1 '
        'Category.',
  ),
  TalentDef(
    name: 'Full Counter',
    category: TalentCategory.counter,
    prerequisitesText: 'Jolt Counter',
    description: 'Turning every ounce of pain you receive back against '
        'your opponent, you open yourself up to powerful hits from your '
        'foes to unleash devastating counterblows.\n'
        '(1)-[Passive]: Increase your Damage Reduction when using the '
        'Cross Counter option of the Defend Maneuver by 2(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you apply the second effect of '
        'Jolt Counter to an Attacking Maneuver, increase the Wound Roll '
        'of both your Attacking Maneuver and your Opponent’s Attacking '
        'Maneuver by your Might.',
  ),
  TalentDef(
    name: 'Exploit Expert',
    category: TalentCategory.counter,
    prerequisitesText: 'N/A',
    description: 'You are especially skilled at taking advantage of '
        'openings in the enemy’s guard.\n'
        '(1)-[Passive]: Increase your Wound Rolls for Attacking '
        'Maneuvers made through the Exploit Maneuver by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If an Opponent makes an Attacking '
        'Maneuver while they are within the Melee Range of 2+ Allies '
        '(including yourself, for this effect), this triggers your '
        'Exploit Maneuver.',
  ),
  TalentDef(
    name: 'Master of Openings',
    category: TalentCategory.counter,
    prerequisitesText: 'Exploit Expert',
    description: 'You are so skilled at taking advantage of openings in '
        'your enemy’s guard that you create openings where none were '
        'before.\n'
        '(1)-[Passive]: Increase your Strike Rolls for Attacking '
        'Maneuvers made through the Exploit Maneuver by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If an Opponent uses the Power Up '
        'Maneuver or Transformation Maneuver while not at Long Range, '
        'this triggers your Exploit Maneuver.',
  ),
  // Replaced "Aikido Apprentice" on the site (rewritten, fetched live
  // 20 Jul 2026).
  TalentDef(
    name: 'Shock Tornado',
    category: TalentCategory.counter,
    prerequisitesText: 'N/A',
    description: "As you redirect your enemy's attack, you are able to "
        'turn that momentum against them, creating space between you and '
        'your assailant.\n'
        '(1)-[Triggered, 1/Round]: When you successfully avoid an '
        'Opponent’s Attacking Maneuver through the Parry effect of the '
        'Defend Maneuver, if that Opponent is within your Melee Range, you '
        'may target that Opponent with the Thrust Maneuver as an '
        'Out-of-Sequence Maneuver. If you succeed the Clash for the Thrust '
        'Maneuver, reduce that Opponent’s Life Points by 1/2 of your '
        'Might.',
  ),

  // ============================================================ Damaging ===
  TalentDef(
    name: 'Bruising Wound',
    category: TalentCategory.damaging,
    prerequisitesText: 'Force and/or Magic Score of 4+',
    description: 'The power behind your strikes leaves a lasting mark on '
        'your opponents.\n'
        '(1)-[Passive]: Increase the Dice Category of your Critical '
        'Result Extra Dice by 1 Category for your Wound Rolls.\n'
        '(2)-[Triggered, 1/Round]: If your Wound Roll’s Natural Result is '
        '1 below the Critical Target, score a Critical Result on that '
        'Wound Roll.',
  ),
  TalentDef(
    name: 'Injuring Wound',
    category: TalentCategory.damaging,
    prerequisitesText: 'Bruising Wound, Force and/or Magic Score of 6+',
    description: 'Trading precision for power, you land debilitating '
        'blows on your enemies.\n'
        '(1)-[Passive]: Reduce the Critical Target of your Wound Rolls '
        'by 1.\n'
        '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, '
        'you can reduce your Strike Roll by 1(bT) to increase your Wound '
        'Roll by 2(bT).',
  ),
  TalentDef(
    name: 'Critical Wound',
    category: TalentCategory.damaging,
    prerequisitesText: 'Injuring Wound, Force and/or Magic Score of 10+, '
        'Tier of Power 3+',
    description: 'Your attacks land with such devastating force that '
        'it’s difficult for your foes to recover.\n'
        '(1)-[Passive]: Roll your Base Die twice for any Wound Roll and '
        'use the highest result.\n'
        '(2)-[Triggered, 1/Encounter]: If you knock an Opponent through '
        'a Health Threshold with an Attacking Maneuver in which you '
        'scored a Critical Result on the Wound Roll, they automatically '
        'fail their Steadfast Check for that Health Threshold.',
  ),

  // ============================================================= Dodging ===
  TalentDef(
    name: 'Cunning Dodge',
    category: TalentCategory.dodging,
    prerequisitesText: 'Agility Score of 4+',
    description: 'Masterfully skilled at evading attacks, you duck and '
        'weave out of the way of any incoming assault.\n'
        '(1)-[Passive]: Increase the Dice Category of your Critical '
        'Result Extra Dice by 1 Category for your Dodge Rolls.\n'
        '(2)-[Triggered, 1/Round]: If your Dodge Roll’s Natural Result is '
        '1 below the Critical Target, score a Critical Result on that '
        'Dodge Roll.',
  ),
  TalentDef(
    name: 'Instinctual Dodge',
    category: TalentCategory.dodging,
    prerequisitesText: 'Cunning Dodge, Agility Score of 6+',
    description: 'Your ability to dodge is second-nature, to the point '
        'where you don’t even have to think about it anymore.\n'
        '(1)-[Passive]: Reduce the Critical Target of your Dodge Rolls '
        'by 1.\n'
        '(2)-[Triggered, 1/Round]: If you are hit by an Attacking '
        'Maneuver, reroll your Dodge Roll and apply it against the same '
        'roll you lost against.',
  ),
  TalentDef(
    name: 'Masterful Dodge',
    category: TalentCategory.dodging,
    prerequisitesText: 'Instinctual Dodge, Agility Score of 10+, Tier of '
        'Power 3+',
    description: 'Having mastered the elusive technique of dodging '
        'without intent, your evasive skills are without equal.\n'
        '(1)-[Passive]: Roll your Base Die twice for any Dodge Roll and '
        'use the highest result.\n'
        '(2)-[Triggered/Start of Turn, 1/Encounter]: Until the start of '
        'your next turn, ignore all penalties to your Dodge Rolls.',
  ),
  TalentDef(
    name: 'Free Flowing Stance',
    category: TalentCategory.dodging,
    prerequisitesText: 'Agility Score of 6+',
    description: 'You can take a defensive posture that allows you to '
        'dodge and weave around all attacks.\n'
        '(1)-[1/Round, Ruling]: If you have not used an Attacking '
        'Maneuver this Combat Round, you can, as a Standard Maneuver '
        'that costs all of your remaining Actions, enter the ‘Free '
        'Flowing Stance’ until the start of your next turn.\n'
        '(2)-[Passive]: While you are in the Free Flowing Stance: you '
        'cannot use any Attacking Maneuvers; increase your Defense Value '
        'by 1(T) for each Action spent; increase the Ki Point Cost of '
        'Attacking Maneuvers that target you by 1(T) for each Action '
        'spent.',
  ),
  TalentDef(
    name: 'Agile Warrior',
    category: TalentCategory.dodging,
    prerequisitesText: 'Agility Score of 6+',
    description: 'You are nimble enough to avoid almost any attack.\n'
        '(1)-[Passive]: Increase your Defense Value by 1(T).\n'
        '(2)-[Automatic]: You do not gain Diminishing Defense stack(s) '
        'from the first Attacking Maneuver made with you as a target '
        'each Combat Round. Do not count Attacking Maneuvers you already '
        'would not obtain Diminishing Defense stack(s) from for this '
        'effect.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),

  // =========================================================== Durability ===
  TalentDef(
    name: 'Effective Defenses',
    category: TalentCategory.durability,
    prerequisitesText: 'N/A',
    description: 'Able to withstand damage more efficiently than most, '
        'you are nearly indestructible.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost for the Guard option of '
        'the Defend Maneuver by 2(T).\n'
        '(2)-[Passive]: Increase your Soak Value by 2(T) (before any '
        'calculations) for the duration of an Attacking Maneuver that '
        'targets you if you use the Defend Maneuver in response to it.',
  ),
  TalentDef(
    name: 'Resilience',
    category: TalentCategory.durability,
    prerequisitesText: 'Tenacity Score 6+',
    description: 'Able to bounce back from damage more easily than most, '
        'you are exceptionally good at ignoring injuries.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(bT).\n'
        '(2)-[Passive]: Increase the amount of Life Points regained '
        'through a Healing Surge by 1d10(T).',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  TalentDef(
    name: 'Tough Warrior',
    category: TalentCategory.durability,
    prerequisitesText: 'Resilience',
    description: 'Your ability to protect yourself from damage is far '
        'greater than average, allowing you to shrug off massive '
        'blows.\n'
        '(1)-[Passive]: Halve any Collision Damage you would suffer.\n'
        '(2)-[Triggered, 1/Round]: If you are hit by an Attacking '
        'Maneuver, spend up to 4(bT) Ki Points. Increase your Damage '
        'Reduction by an equal amount for the duration of that Attacking '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Risky Bet',
    category: TalentCategory.durability,
    prerequisitesText: 'Resilience, Tenacity Score of 8+',
    description: 'You can throw more power into your attacks at the '
        'cost of opening your guard.\n'
        '(1)-[Passive]: While you are below the Injured Health '
        'Threshold, increase your Soak Value by 1(bT).\n'
        '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, '
        'reduce your Soak Value by up to 4(bT) until the start of your '
        'next turn to increase your Wound Rolls for that Attacking '
        'Maneuver by twice the reduction.',
  ),
  TalentDef(
    name: 'Superior Durability',
    category: TalentCategory.durability,
    prerequisitesText: 'Tough Warrior, ToP3+',
    description: 'Unmatched in your ability to take a hit, even the most '
        'lethal of blows barely scratches you.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(bT).\n'
        '(2)-[Passive]: Halve the amount of Life Points you would lose '
        'from the effects of a Combat Condition, Environmental '
        'Qualities, or Damage Over Time.\n'
        '(3)-[Triggered, 1/Round]: If you use the second effect of '
        'Tough Warrior and spend the maximum amount of Ki Points through '
        'its second effect, you can reduce the Damage Category of that '
        'Attacking Maneuver by 1 Category.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),

  // ======================================================= Energy Attack ===
  TalentDef(
    name: 'Enhanced Shot',
    category: TalentCategory.energyAttack,
    prerequisitesText: 'N/A',
    description: 'You have become particularly adept at funneling energy '
        'into your ranged blasts with minimal effort.\n'
        '(1)-[Passive]: Increase the Wound Rolls for your Energy Attacks '
        'by 1(T).\n'
        '(2)-[Passive]: Increase the Strike Roll of Energy Attacks made '
        'against adjacent Opponents by 1(T).\n'
        '(3)-[Passive]: Increase the Wound Rolls for your Energy Attacks '
        'against Opponents who are outside of your Melee Range by 1(T).',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundEnergy],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Point Blank Shot',
    category: TalentCategory.energyAttack,
    prerequisitesText: 'Enhanced Shot',
    description: 'Knowing where to place your energy blasts for maximum '
        'effectiveness, the close range nature of your attacks makes '
        'them especially deadly.\n'
        '(1)-[Passive]: Increase the Wound Rolls of Energy Attacks made '
        'against adjacent Opponents by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you use the Energy Charge '
        'Maneuver within the Melee Range of an Opponent, use the '
        'declared Attacking Maneuver as an Out-of-Sequence Maneuver if '
        'it was an Energy Attack.',
  ),
  TalentDef(
    name: 'Artillery Shot',
    category: TalentCategory.energyAttack,
    prerequisitesText: 'Enhanced Shot',
    description: 'Like a grenadier, your ability to lob energy blasts '
        'that cover a wide area makes your attacks even more likely to '
        'hit, despite the range.\n'
        '(1)-[Passive]: Increase the Strike Roll of Energy Attacks made '
        'against Opponents outside of your Melee Range by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you make an Energy Attack that '
        'does not possess an AoE, you may apply an AoE of your choice to '
        'that Attacking Maneuver. The Target Square of that AoE can be '
        'any Square that is outside of your Melee Range. The Magnitude '
        'of that AoE starts at Large, but you may spend up to 4(bT) Ki '
        'Points to increase the Magnitude of that AoE by 1 for every '
        '2(bT) Ki Points spent.',
  ),
  TalentDef(
    name: 'Blaster Master',
    category: TalentCategory.energyAttack,
    prerequisitesText: 'Point Blank Shot and/or Artillery Shot, ToP2+',
    description: 'Your unparalleled skill with energy blasts allows you '
        'to obliterate your enemies.\n'
        '(1)-[Triggered]: If you hit an Opponent with an Energy Attack, '
        'spend up to 5(bT) Ki Points. If you do, increase the Wound Roll '
        'by an equal amount.\n'
        '(2)-[Triggered, 1/Round]: If you use an Energy Attack with an '
        'AoE and at least 1 Energy Charge applied to it, you may either: '
        'increase the Dice Category of the Energy Charge Extra Dice '
        'applied to this Attacking Maneuver by 1 Category, or increase '
        'the Magnitude of this Attacking Maneuver’s AoE by 1.\n'
        '(3)-[Triggered, 1/Encounter]: If you make an Energy Attack, '
        'increase the Damage Category of that Attacking Maneuver by 1 '
        'Category.',
  ),

  // ========================================================== Grappling ===
  TalentDef(
    name: 'Brawler',
    category: TalentCategory.grappling,
    prerequisitesText: 'N/A',
    description: 'Particularly adept at submission holds and wrestling, '
        'you are more accustomed to fighting in a grapple than most.\n'
        '(1)-[Passive]: Gain an additional Action each Combat Round '
        'while Pinned.\n'
        '(2)-[Triggered, 1/Round]: When you hit an Opponent with an '
        'Unarmed Physical Attack, you may use the Grapple Maneuver as an '
        'Out-of-Sequence Maneuver. You cannot trigger this effect if: '
        'that Opponent used the Guard or Direct Hit option of the '
        'Defend Maneuver; or an Ally to that Opponent used the '
        'Intervene Maneuver in response to you hitting that Opponent '
        'with this Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Wrestler',
    category: TalentCategory.grappling,
    prerequisitesText: 'Brawler',
    description: 'You know how to best make use of your might, crushing '
        'your opponent in an iron grip.\n'
        '(1)-[Passive]: Treat your Size Category as if it was 1 larger '
        'for the effects of Gigantic Grip.\n'
        '(2)-[Passive]: When you make a Grapple Check to maintain a '
        'Grapple, you may use your Force Modifier instead of the sum of '
        'your Haste and Awareness to calculate your Strike Roll.',
  ),
  TalentDef(
    name: 'Judo Training',
    category: TalentCategory.grappling,
    prerequisitesText: 'Brawler',
    description: 'Expanding your training in the art of submission '
        'holds, you are able to use your grip on a target to deal '
        'damage or reposition them as you please.\n'
        '(1)-[Passive]: Increase your Grapple Checks when already in a '
        'Grapple by 1(T).\n'
        '(2)-[Triggered/Start of Turn]: If you are in a Grapple as the '
        'Grappler, you may use the Basic Attack Maneuver or the Launch '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Heel',
    category: TalentCategory.grappling,
    prerequisitesText: 'Brawler',
    description: 'Unabashed by dishonorable tactics, you are more than '
        'willing to choke the life out of your target.\n'
        '(1)-[Passive]: Increase the Wound Roll of your Attacking '
        'Maneuvers made against Opponents in a Grapple by 1(T).\n'
        '(2)-[1/Round]: While you are the Grappler in a Grapple, as a '
        'Standard Maneuver with an Action Cost of 1 Action, target a '
        'Grappled Character in your Grapple and make a Grapple Check '
        'against them. If you win, they gain the Suffocating Combat '
        'Condition until they escape the Grapple.',
  ),
  TalentDef(
    name: 'Suplex',
    category: TalentCategory.grappling,
    prerequisitesText: 'Brawler',
    description: 'Able to use the terrain to your advantage while '
        'grappling an opponent, you can smash them into the ground or '
        'drag them through a wall to inflict massive damage.\n'
        '(1)-[1/Round]: While you are the Grappler in a Grapple in a '
        'High Environment, as a Standard Maneuver with an Action Cost of '
        '1 Action, you can make a Might Clash against the Grappled. If '
        'you win, move to the Battle Environment of the Square below '
        'and deal Ground Collision to your Opponent. Double the amount '
        'of Collision Damage they receive from this effect.\n'
        '(2)-[Triggered, 1/Round]: If you use an Attacking Maneuver of '
        'the Powered or Crushing Profile while in a Grapple that is not '
        'in a High Environment, if your target is a Grappled Character '
        'in that Grapple, apply Ground Collision for the Square that the '
        'Grappled Character is in.',
  ),
  TalentDef(
    name: 'Human Shield',
    category: TalentCategory.grappling,
    prerequisitesText: 'Brawler',
    description: 'You can protect yourself by directing incoming attacks '
        'at the opponent currently in your grasp.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(T) while you are '
        'in a Grapple.\n'
        '(2)-[Triggered, 1/Round]: If you are targeted for an Attacking '
        'Maneuver (that does not possess an AoE and is not from a '
        'Character in the Grapple) while in a Grapple as the Grappler, '
        'you can make a Grapple Check against a Grappled Character. If '
        'you win, that Opponent becomes the target of that Attacking '
        'Maneuver instead and the Strike and Wound Rolls for that '
        'Attacking Maneuver become Urgent Rolls.',
  ),
  TalentDef(
    name: 'Personal Space',
    category: TalentCategory.grappling,
    prerequisitesText: 'N/A',
    description: 'You are adept at keeping others from grabbing hold of '
        'you.\n'
        '(1)-[Passive]: Increase the Dice Score of your Grapple Checks '
        'by 1(T) if they are initiated by another Character or while you '
        'are in a Grapple as the Grappled.\n'
        '(2)-[Triggered/Start of Turn]: Make a Grapple Check to escape a '
        'Grapple you are in as the Grappled. This counts as spending 1 '
        'Action for the effects of Escaping a Grapple.\n'
        '(3)-[Triggered, 1/Round]: If you escape a Grapple or an '
        'Opponent ends their turn within your Melee Range, you may use '
        'the Movement Maneuver as an Out-of-Sequence Maneuver.',
  ),

  // ========================================================= Initiative ===
  TalentDef(
    name: 'Improved Initiative',
    category: TalentCategory.initiative,
    prerequisitesText: 'Insight or Agility Score of 4+',
    description: 'Due to your great speed, you dominate the '
        'competition.\n'
        '(1)-[Passive]: When rolling Initiative, roll your Base Die '
        'twice. You may choose which result becomes the Natural '
        'Result.\n'
        '(2)-[Passive, Ruling]: If your Initiative Value is higher than '
        'that of all Opponents, you have ‘Initiative Advantage’. While '
        'you possess Initiative Advantage, increase your Combat Rolls by '
        '1(T).',
  ),
  TalentDef(
    name: 'Alert',
    category: TalentCategory.initiative,
    prerequisitesText: 'Improved Initiative, Insight Score of 8+',
    description: 'Constantly on the lookout for danger, your awareness '
        'of your surroundings is unparalleled.\n'
        '(1)-[Passive]: Increase your Initiative Value by 1(bT).\n'
        '(2)-[Passive]: You ignore the effects of Surprise Rounds.\n'
        '(3)-[Passive]: While you have Initiative Advantage, increase '
        'your Wound Rolls by 1(T).\n'
        '(4)-[Triggered/Start of Combat Round, 1/Encounter]: If you have '
        'Initiative Advantage, gain 1 Counter Action.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.initiative],
        coefficient: 1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  TalentDef(
    name: 'Attentive Warrior',
    category: TalentCategory.initiative,
    prerequisitesText: 'Alert, Insight Score of 10+',
    description: 'Your keen battlefield awareness allows you to '
        'manipulate the battlefield to your advantage.\n'
        '(1)-[Passive]: While you have Initiative Advantage, increase '
        'the Dice Score of your Clashes initiated by an Opponent that '
        'uses your Saving Throws by 1(T).\n'
        '(2)-[Passive]: While you have Initiative Advantage, increase '
        'your Strike Rolls by 1(T).\n'
        '(3)-[Triggered, 1/Encounter]: If you have Initiative Advantage, '
        'when making an Attacking Maneuver, you may apply the Called '
        'Shot Modifier Maneuver to that Attacking Maneuver without '
        'spending an Action.',
  ),
  TalentDef(
    name: 'Speedblitz',
    category: TalentCategory.initiative,
    prerequisitesText: 'Improved Initiative, Agility Score of 8+',
    description: 'You jump into action, moving quicker than your foes '
        'can react.\n'
        '(1)-[Passive]: Increase your Initiative Value by 1(bT).\n'
        '(2)-[Passive]: While you have Initiative Advantage, increase '
        'your Speeds and Wound Rolls by 1(T).\n'
        '(3)-[Triggered/Start of Turn, 1/Encounter]: If you have '
        'Initiative Advantage, you may use the Movement Maneuver or '
        'Basic Attack Maneuver as an Out-of-Sequence Maneuver.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.initiative],
        coefficient: 1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  TalentDef(
    name: 'Lightning Initiative',
    category: TalentCategory.initiative,
    prerequisitesText: 'Speedblitz, Agility Score of 10+',
    description: 'Lightning-quick and ready to rumble, you dash into '
        'combat without thinking.\n'
        '(1)-[Passive]: While you have Initiative Advantage, increase '
        'your Dodge Rolls by 1(T).\n'
        '(2)-[Passive]: Your use of the Movement Maneuver does not '
        'trigger the Exploit Maneuver from Opponents with a lower '
        'Initiative Value than you.\n'
        '(3)-[Triggered/Start of Turn, 1/Encounter]: If you have '
        'Initiative Advantage, gain an additional Action to spend during '
        'your turn this Combat Round.',
  ),
  TalentDef(
    name: 'Patient Fighter',
    category: TalentCategory.initiative,
    prerequisitesText: 'Scholarship or Insight Score of 6+',
    description: 'You know the value of patience in battle, choosing to '
        'study your opponents to react perfectly to their attacks, '
        'rather than rush headlong into a fight.\n'
        '(1)-[Triggered]: When you roll your Initiative Check at the '
        'start of a Combat Encounter, you may reduce the Dice Score by '
        '1(bT). If you do, you may increase the Initiative of a willing '
        'Ally by an equal amount.\n'
        '(2)-[1/Round, 3/Encounter]: If your Initiative Value is lower '
        'than all of your Opponents, you may use the Defend Maneuver '
        'without spending a Counter Action.',
  ),

  // ========================================================= Insightful ===
  TalentDef(
    name: 'Insightful Warrior',
    category: TalentCategory.insightful,
    prerequisitesText: 'Insight Score of 8+',
    description: 'You realize that reading your opponent and reacting '
        'accordingly is more effective than brute strength.\n'
        '(1)-[Passive]: While your Force and Magic Attribute Scores are '
        'at least 4 lower than your Insight Attribute Score and you are '
        'not benefiting from the effect of Balanced Warrior, increase '
        'your Wound Rolls and Might by 2(T).',
  ),
  TalentDef(
    name: 'Combat Wisdom',
    category: TalentCategory.insightful,
    prerequisitesText: 'Insight Score of 10+, Insightful Warrior',
    description: 'You are able to substitute your skill and experience '
        'in battle for raw, unbridled power.\n'
        '(1)-[Passive]: While benefiting from the effect of Insightful '
        'Warrior, increase your Insight Modifier by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use the Signature Technique '
        'Maneuver while benefiting from the effect of Insightful '
        'Warrior, increase your Wound Rolls and Might by 1(T) for the '
        'duration of that Maneuver.\n'
        '(3)-[Triggered, 1/Round]: If you would use the Defend Maneuver '
        'while benefiting from the effect of Insightful Warrior, '
        'increase your Damage Reduction by 2(T) for the duration of that '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Tai Chi Practitioner',
    category: TalentCategory.insightful,
    prerequisitesText: 'Insightful Warrior or Balanced in Yin and Yang',
    description: 'Your fluid movements and reactive combat style allow '
        'you to turn your opponents’ power against them.\n'
        '(1)-[Triggered/Start of Turn]: Regain Ki Points equal to 1/2 of '
        'your Insight Modifier.\n'
        '(2)-[Triggered, 1/Round]: If you are hit by an Opponent’s '
        'Attacking Maneuver, increase your Damage Reduction by 1/4 '
        '(rounded up) of that Opponent’s Might for the duration of that '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Tai Chi Expert',
    category: TalentCategory.insightful,
    prerequisitesText: 'Tai Chi Practitioner, ToP 3+',
    description: 'In the ebb and flow of battle, you ride the tides '
        'with expert prowess, transforming the enemies’ strengths into '
        'you own.\n'
        '(1)-[Passive]: The second effect of Tai Chi Practitioner loses '
        'its 1/Round Keyword.\n'
        '(2)-[Triggered, 1/Round]: If you hit an Opponent with an '
        'Attacking Maneuver that did not possess an AoE, increase the '
        'Wound Roll of that Attacking Maneuver by 1/4 (rounded up) of '
        'that Opponent’s Might.\n'
        '(3)-[Triggered, 1/Round, 2/Encounter]: When making a Might '
        'Clash that was initiated by an Opponent, you may use that '
        'Opponent’s Might for this Might Clash.',
  ),
  TalentDef(
    name: 'Tai Chi Master',
    category: TalentCategory.insightful,
    prerequisitesText: 'Tai Chi Expert, ToP 4+',
    description: 'As a master in turning an enemy’s own movements '
        'against them, you waste no effort and expend minimal energy.\n'
        '(1)-[Passive]: The second effect of Tai Chi Expert loses its '
        '1/Round Keyword.\n'
        '(2)-[Passive]: The first effect of Tai Chi Practitioner regains '
        'an equal amount of Life Points to the amount of Ki Points '
        'regained.\n'
        '(3)-[Triggered, 1/Round, 2/Encounter]: If you lose a Might '
        'Clash initiated by an Opponent, you may reroll that Might '
        'Clash. If you haven’t already applied the 3rd effect of Tai '
        'Chi Expert to this Might Clash, you may apply that effect now.',
  ),

  // ======================================================= Magic Attack ===
  TalentDef(
    name: 'Magic Blaster',
    category: TalentCategory.magicAttack,
    prerequisitesText: '2+ Skill Ranks in Use Magic',
    description: 'Choosing to focus solely on your magical skills, you '
        'eschew other forms of combat to fire spell after spell at the '
        'enemy.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Magic Attacks '
        'by 1(T).\n'
        '(2)-[Triggered, 1/Round]: After using a Magical Unique Ability '
        'or the Magic Trick Special Maneuver, you may use the Energy '
        'Charge Maneuver as an Out-of-Sequence Maneuver. Your declared '
        'Attacking Maneuver must be a Magic Attack.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundMagic],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Magic Caster',
    category: TalentCategory.magicAttack,
    prerequisitesText: 'Magic Blaster',
    description: 'Your magical prowess allows you to infuse intense '
        'power into your attacks.\n'
        '(1)-[Passive]: Increase the Strike Rolls of your Magic Attacks '
        'that are not using an ‘Elemental’ Profile by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you declare a Magic Attack for '
        'the Energy Charge Maneuver, you may gain an additional Energy '
        'Charge through the effects of that Maneuver.',
  ),
  TalentDef(
    name: 'Elementalist',
    category: TalentCategory.magicAttack,
    prerequisitesText: 'Magic Blaster',
    description: 'Your intense focus on a specific element allows you '
        'to use it in unconventional ways.\n'
        '(1)-[Passive]: Select a Profile with ‘Elemental’ in the name. '
        'That Profile becomes a Favored Element.\n'
        '(2)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
        'with a Profile that is your Favored Element, you may apply a '
        'Line or Cone AoE to that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Magic Master',
    category: TalentCategory.magicAttack,
    prerequisitesText: 'Magic Caster and/or Elementalist, ToP2+',
    description: 'Your ability to empower your attacks with magical '
        'energy is unsurpassed, allowing you to hit harder and more '
        'accurately.\n'
        '(1)-[Passive]: Reduce the TP Cost of all Magical Unique '
        'Abilities by your number of Use Magic Skill Ranks. This effect '
        'applies retroactively.\n'
        '(2)-[Triggered]: If you hit an Opponent with a Magic Attack, '
        'spend up to 5(bT) Ki Points. If you do, increase the Wound Roll '
        'by an equal amount.\n'
        '(3)-[Triggered, 1/Encounter]: If you make a Magic Attack, '
        'increase the Damage Category of that Attacking Maneuver by 1 '
        'Category.',
  ),
  TalentDef(
    name: 'Magic Warrior',
    category: TalentCategory.magicAttack,
    prerequisitesText: 'Magic Score of 6+',
    description: 'Able to use magical power to supplement your physical '
        'might or ki blasts, your magical prowess is more than enough to '
        'stand up to others in combat.\n'
        '(1)-[Passive]: You gain access to all Energy Profiles.\n'
        '(2)-[Passive]: You may use your Magic Modifier as the Damage '
        'Attribute for all Physical and Energy Attacks.',
  ),

  // ============================================================ Mindful ===
  TalentDef(
    name: 'Calm Mind',
    category: TalentCategory.mindful,
    prerequisitesText: 'N/A',
    description: 'Your meditations have led to the ability to clear your '
        'mind of all thoughts but the ones that are necessary to '
        'continue the fight.\n'
        '(1)-[Passive]: The L listed on any Mindful Talent refers to '
        'your current Level of your use of the Mindful State.\n'
        '(2)-[Triggered]: Whenever you score a Critical Result on a '
        'Combat Roll while in the Mindful State, increase the Dice '
        'Score by an additional L(T).\n'
        '(3)-[Triggered/Power, 2/Encounter]: Enter the Mindful State '
        'until the end of your next turn.',
  ),
  TalentDef(
    name: 'Combat Zen',
    category: TalentCategory.mindful,
    prerequisitesText: 'Calm Mind',
    description: 'Able to fully cleanse your mind of all thought, your '
        'body has become able to act on its own to some extent.\n'
        '(1)-[Passive]: While in the Mindful State, reduce the Ki Point '
        'Cost of all Attacking Maneuvers by L(T).\n'
        '(2)-[Triggered]: If you use a Counter Maneuver while in the '
        'Mindful State, increase your Damage Reduction by 1(T) for the '
        'duration of the Maneuver it was used in response to.',
  ),
  TalentDef(
    name: 'Zen Counter',
    category: TalentCategory.mindful,
    prerequisitesText: 'Calm Mind',
    description: 'Your patience and tranquility allow you to see past '
        'the emotional responses of others and quickly find the most '
        'efficient way to counter an attack.\n'
        '(1)-[Passive]: While in the Mindful State, increase the '
        'Natural Result of your Strike Rolls when using the Parry '
        'effect of the Defend Maneuver by 1.\n'
        '(2)-[Triggered, L/Round]: If you are targeted by an Attacking '
        'Maneuver while in the Mindful State, increase your Combat '
        'Rolls by 1(T) for the duration of that Maneuver.',
  ),
  TalentDef(
    name: 'Tranquil Warrior',
    category: TalentCategory.mindful,
    prerequisitesText: 'Combat Zen and/or Zen Counter, ToP3+',
    description: 'Filling your mind with pure serenity, you completely '
        'avoid the stress of combat.\n'
        '(1)-[Passive]: While in the Mindful State, increase your '
        'Surgency by L(T).\n'
        '(2)-[Triggered, 2/Round]: When you use an Attacking Maneuver or '
        'Counter Maneuver, you may enter the Mindful State for the '
        'duration of that Maneuver.',
    automation: [
      // (1) +L(T) Surgency while in the Mindful State (L = the number of
      // times the Talent is taken; each recorded copy contributes 1(T)).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        tierScaling: TierScaling.current,
        condition: TraitCondition.whileNamedStateActive,
        conditionStateName: 'Mindful',
      ),
    ],
  ),

  // ============================================================= Minion ===
  TalentDef(
    name: 'Master of Minions',
    category: TalentCategory.minion,
    prerequisitesText: 'N/A',
    description: 'You are accustomed to command, and rule over your '
        'Minions with great ease.\n'
        '(1)-[Passive]: Increase your maximum number of Minions by 2.\n'
        '(2)-[Passive]: Increase the Wound Rolls of your Minions by 1/4 '
        '(rounded up) of your Personality or Scholarship Modifier '
        '(whichever is higher).\n'
        '(3)-[Triggered, 1/Round]: After using the Command Maneuver in '
        'which you targeted at least 1 Minion, regain 1 Action.',
  ),
  TalentDef(
    name: 'Minion Coordinator',
    category: TalentCategory.minion,
    prerequisitesText: 'Master of Minions',
    description: 'You are a master tactician, able to give extremely '
        'efficient orders to your subordinates.\n'
        '(1)-[Passive]: Increase the amount of Life and Ki Points '
        'regained through the Recovery Period rule for Minions by '
        '1d8(T).\n'
        '(2)-[1/Round]: As an Instant Maneuver, select one of your '
        'Minions. That Minion enters the Superior State until the end '
        'of their turn.\n'
        '(3)-[Passive]: Increase your maximum number of Minions by 2.',
  ),
  TalentDef(
    name: 'Minion Mark',
    category: TalentCategory.minion,
    prerequisitesText: 'Master of Minions',
    description: 'You have the ability to turn your subordinates’ very '
        'life essence into greater power, and they know to defend you '
        'in battle.\n'
        '(1)-[1/Round]: As an Instant Maneuver, select one of your '
        'Minions that is not a Special Minion. That Minion becomes '
        'Marked. A Marked Minion loses 4(bT) Life Points at the start of '
        'each Combat Round, but their Combat Rolls are increased by '
        '1(bT) – both use your Tier of Power for calculation.\n'
        '(2)-[Passive]: Minions (except Special Minions) without any '
        'Counter Actions can use the Defense Wall option of the '
        'Intervene Maneuver if you are targeted by an Attacking Maneuver '
        'by spending 1/2 of their Life Points.\n'
        '(3)-[Passive]: Increase your maximum number of Minions by 2.',
  ),
  TalentDef(
    name: 'Sacrificial Minion',
    category: TalentCategory.minion,
    prerequisitesText: 'Minion Mark',
    description: 'You are able to draw power from killing your Minions, '
        'either by draining their life essence, terrifying your '
        'opponents, or just generally making yourself feel big.\n'
        '(1)-[Passive]: If one of your Attacking Maneuvers includes one '
        'of your Minions in the list of targets, increase the Strike '
        'and Wound Rolls for that Attacking Maneuver by 1(T).\n'
        '(2)-[1/Round]: As an Instant Maneuver, target one of your '
        'Minions (except Special Minions). That Minion has their Life '
        'Points reduced to 0 and they are Defeated. Apply an effect of '
        'your choice from the list below: make a Morale Clash against '
        'all of your Opponents (if you win, they gain the Shaken Combat '
        'Condition); regain Life Points equal to 1/2 of that Minion’s '
        'Life Points immediately before you applied this effect; '
        'increase your Combat Rolls by 2(T) until the end of your turn '
        '(this effect cannot stack).',
  ),
  TalentDef(
    name: 'Minion Army',
    category: TalentCategory.minion,
    prerequisitesText: 'Minion Coordinator or Minion Mark Talents',
    description: 'You lead an entire army of Minions, able to call upon '
        'them at any time.\n'
        '(1)-[Passive]: There is no limit to the number of Minions you '
        'may possess, but only up to 10 of your Minions may be in a '
        'Combat Encounter at any one time (Defeated Minions do not count '
        'towards this limit).\n'
        '(2)-[Triggered, 1/Round]: If one of your Minions makes an '
        'Attacking Maneuver, increase the Wound Roll for that Attacking '
        'Maneuver by 1(T) for every one of your Minions in the Combat '
        'Encounter who has not yet made an Attacking Maneuver this '
        'Combat Round (max. 4(T)).\n'
        '(3)-[Triggered]: If any number of your Minions are Defeated, '
        'you may have any number of Minions that are not currently in '
        'the Combat Encounter immediately join the Combat Encounter. '
        'This cannot allow your total number of Minions in the Combat '
        'Encounter to exceed 10.',
  ),
  TalentDef(
    name: 'Minion Supporter',
    category: TalentCategory.minion,
    prerequisitesText: 'Minion Coordinator, ToP 2+',
    description: 'You are content to stand in the back, giving orders '
        'to your Minions.\n'
        '(1)-[Passive]: If you target a Minion with the effects of the '
        'Spectator State, apply your Tier of Power Extra Dice as Extra '
        'Dice to your Minion’s Combat Rolls.\n'
        '(2)-[1/Round]: You can use the Empower Maneuver (as if you '
        'spent 1 Action) as an Instant Maneuver. If you do, you must '
        'target one of your Minions and that Minion has its Combat '
        'Rolls increased by 1(T) until the start of your next turn.',
  ),

  // ============================================================ Mobility ===
  TalentDef(
    name: 'Footwork',
    category: TalentCategory.mobility,
    prerequisitesText: 'Agility Score of 4+',
    description: 'Your deft footwork allows you to close the gap '
        'between you and your target, even as they try to flee.\n'
        '(1)-[1/Round]: As an Instant Maneuver, you may move up to '
        '1(bT) Squares in any direction.\n'
        '(2)-[Triggered, 1/Round]: If you use the Rapid Movement effect '
        'of the Movement Maneuver, increase your Defense Value by 1(T) '
        'until the start of your next turn.\n'
        '(3)-[Triggered, 1/Round]: When a Character within your Melee '
        'Range uses the Movement Maneuver to leave your Melee Range, '
        'you may use the Movement Maneuver as an Out-of-Sequence '
        'Maneuver. If you do, their Movement does not trigger your '
        'Exploit Maneuver.',
  ),
  TalentDef(
    name: 'Power of Movement',
    category: TalentCategory.mobility,
    prerequisitesText: 'Footwork',
    description: 'Having mastered the ability to stay mobile while '
        'charging your energy, you are a real force to be reckoned with '
        'on the battlefield.\n'
        '(1)-[Passive]: You can use the Movement Maneuver after using '
        'the Energy Charge Maneuver, even if you have not yet used '
        'whatever attack you have declared. You do not suffer from the '
        'Guard Down Combat Condition through the effects of the Energy '
        'Charge Maneuver.\n'
        '(2)-[Triggered, 1/Round]: When using any type of applicable '
        'Signature Technique that has gained at least 2 Energy Charges '
        'from the Energy Charge Maneuver, you may spend 2(T) Ki Points '
        'to add the Charging Assault Advantage to that Signature '
        'Technique for the duration of that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Fleet of Foot',
    category: TalentCategory.mobility,
    prerequisitesText: 'Footwork',
    description: 'Your ability to gather momentum while moving is '
        'unmatched, allowing you to land blows before your opponent '
        'even realizes you’re attacking.\n'
        '(1)-[Passive]: Increase the bonus to your Defense Value from '
        'Footwork’s second effect by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you enter the Melee Range of an '
        'Opponent when using the Movement Maneuver, increase the Strike '
        'Roll of your next Attacking Maneuver that targets them by 1(T) '
        'until the end of your turn.',
  ),
  TalentDef(
    name: 'High Speed Ace',
    category: TalentCategory.mobility,
    prerequisitesText: 'Agility Score of 6+',
    description: 'Focused on zipping around the battlefield, you build '
        'up momentum and combine it with your fighting style.\n'
        '(1)-[Passive]: Increase your Defense Value and Speed by 1(T).\n'
        '(2)-[Passive]: During this Combat Round, if you have moved a '
        'total number of Squares that matches or exceeds your Normal '
        'Speed through your own effects or Maneuvers, increase your '
        'Wound Rolls by 1(T) until the end of this Combat Round.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue, AffectedStat.speedNormal],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),

  // ========================================================= Multi-Type ===
  TalentDef(
    name: 'Multi-Type Attacker',
    category: TalentCategory.multiType,
    prerequisitesText: '2+ of Enhanced Fist, Enhanced Shot, or Magic '
        'Blaster',
    description: 'Skilled in the art of switching between different '
        'attack styles at the drop of a hat, your ability to catch '
        'enemies off-guard enhances your effectiveness in combat.\n'
        '(1)-[Triggered, 2/Round]: After concluding an Attacking '
        'Maneuver during your turn, select a Foundation different to '
        'the one used in that Attacking Maneuver. Increase your Wound '
        'Rolls with Attacking Maneuvers of that Foundation by 1(T) for '
        'the remainder of your turn. This effect can stack.',
  ),
  TalentDef(
    name: 'Multi-Type Specialist',
    category: TalentCategory.multiType,
    prerequisitesText: 'Multi-Type Attacker, ToP2+',
    description: 'You excel in using multiple different combat styles '
        'at the same time.\n'
        '(1)-[Passive]: Increase your Surgency by 1(bT) for every '
        'Talent you possess that is listed as a potential prerequisite '
        'for Multi-Type Attacker.\n'
        '(2)-[Triggered/Start of Turn]: Trigger the effect of '
        'Multi-Type Attacker. This does not count to its 2/Round '
        'limit.',
  ),
  TalentDef(
    name: 'Multi-Type Gambit',
    category: TalentCategory.multiType,
    prerequisitesText: 'Multi-Type Attacker, ToP2+',
    description: 'You’re an expert at utilizing a variety of fighting '
        'styles to pull off a bigger attack afterward.\n'
        '(1)-[Passive]: If you have triggered the effect of Multi-Type '
        'Attacker twice during this turn, increase the Dice Category of '
        'your Energy Charges by 1 Category.\n'
        '(2)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
        'of a Foundation that has been selected 2+ times by the effect '
        'of Multi-Type Attacker, you may apply 2 Energy Charges to that '
        'Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Multi-Type Master',
    category: TalentCategory.multiType,
    prerequisitesText: 'Multi-Type Specialist and/or Multi-Type Gambit, '
        'ToP3+',
    description: 'Your ability to combine combat styles is so great '
        'that you can use two different ones at the same time.\n'
        '(1)-[Triggered, 1/Round]: After concluding an Attacking '
        'Maneuver during your turn, you may use the Basic Attack '
        'Maneuver or Signature Technique Maneuver as an Out-of-Sequence '
        'Maneuver. If you do, reduce the Ki Point Cost of that Maneuver '
        'by 1(T) for each time the first effect of Multi-Type Attacker '
        'has been applied to the Foundation of that Attacking Maneuver.',
  ),

  // ==================================================== Physical Attack ===
  TalentDef(
    name: 'Enhanced Fist',
    category: TalentCategory.physicalAttack,
    prerequisitesText: 'N/A',
    description: 'Enhancing your attacks with your energy, you deal '
        'devastating physical blows.\n'
        '(1)-[Passive]: Increase the Wound Rolls for your Physical '
        'Attacks by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use a Signature Technique '
        'that is a Physical Attack, you may apply a rank of Power Shot '
        'to that Attacking Maneuver.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundPhysical],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Iron Fist',
    category: TalentCategory.physicalAttack,
    prerequisitesText: 'Enhanced Fist',
    description: 'Unleashing a powerful blow, you strike hard and fast, '
        'landing a brutal attack.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Physical '
        'Attacks by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you use the Energy Charge '
        'Maneuver for a Physical Attack that does not possess an AoE, '
        'use the declared Attacking Maneuver as an Out-of-Sequence '
        'Maneuver.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundPhysical],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Rapid Fist',
    category: TalentCategory.physicalAttack,
    prerequisitesText: 'Enhanced Fist',
    description: 'Attacking faster than the eye can see, you leave '
        'enemies reeling from your sheer speed and precision.\n'
        '(1)-[Passive]: Increase the Strike Roll of your Physical '
        'Attacks by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you use a Signature Technique '
        'that is a Physical Attack, you may double the Diminishing '
        'Defense penalty currently suffered by the target(s) of that '
        'Attacking Maneuver for the duration of that Attacking '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Supreme Fist',
    category: TalentCategory.physicalAttack,
    prerequisitesText: 'Iron Fist and/or Rapid Fist, ToP2+',
    description: 'A master of hitting your enemies where it hurts most, '
        'you land physical strikes with immense and devastating power.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of your Physical '
        'Signature Techniques by 2(T).\n'
        '(2)-[Triggered]: If you hit an Opponent with a Physical Attack, '
        'spend up to 5(bT) Ki Points. If you do, increase the Wound Roll '
        'by an equal amount.\n'
        '(3)-[Triggered, 1/Encounter]: If you make a Physical Attack, '
        'increase the Damage Category of that Attacking Maneuver by 1 '
        'Category.',
  ),

  // ============================================================= Racial ===
  // ------------------------------------------------------------ Android ---
  TalentDef(
    name: 'Unflinching Resilience',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race, Damage Inhibitor Racial Trait',
    description: 'When the smoke clears and the dust settles, you stand '
        'tall, boasting nary a scratch, even in the face of the '
        'strongest foes.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(T).\n'
        '(2)-[Triggered]: If you get hit by an Armed Attack with a '
        'Physical Weapon and take no Damage from that Attacking '
        'Maneuver, reduce its Life Points by your Soak Value.\n'
        '(3)-[Triggered, 1/Encounter]: If you inflict the Shaken Combat '
        'Condition to an Opponent through the effects of the Direct Hit '
        'option of the Defend Maneuver, enter the Superior State until '
        'the end of your next turn.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Android Fusion',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race',
    description: 'Integrating the technological components of other '
        'Androids, you obtain their abilities for yourself.\n'
        '(1)-[Passive]: You gain access to the Unify Maneuver.\n'
        '(2)-[Passive]: Increase your Racial Life Modifier by 1 for '
        'each stack of the Unified Awakening you possess.\n'
        '(3)-[Passive]: When using the Unify Maneuver, you may target '
        'up to 2 Androids that are up to 8 Squares away from you if '
        'they also possess this option effect, instead of only '
        'targeting 1 Android and requiring them to be on an adjacent '
        'Square.',
  ),
  TalentDef(
    name: 'Honorbound',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race, Tamagami Factor',
    description: 'You have sworn to uphold your duty to defend your '
        'Dragon Ball, regardless of the cost.\n'
        '(1)-[Passive]: Increase your Surgency by 1(T).\n'
        '(2)-[Passive]: While Defeated, the first Desperate Effect you '
        'use has its Karma Point Cost reduced by 1 (this can reduce it '
        'to 0).\n'
        '(3)-[Triggered]: If you are Defeated by an Opponent’s Attacking '
        'Maneuver, instead of triggering the 9th effect of Protector of '
        'the Dragon Ball, you may make a Skill Clash (using any Skill of '
        'your choice) against that Opponent. If you win, you do not '
        'trigger the 9th effect of Protector of the Dragon Ball.',
    automation: [
      // (1) +1(T) Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: '3D Scan Mode',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race, Lock On Racial Trait',
    description: 'Your integrated cybernetics track potential threats in '
        'all directions.\n'
        '(1)-[Passive]: Increase your Clairvoyance Skill Checks by 2.\n'
        '(2)-[Passive]: You cannot suffer from the Long Range Penalty, '
        'but none of your Signature Techniques may possess the Short '
        'Range Disadvantage. If you already possessed a Signature '
        'Technique with the Short Range Disadvantage, it loses it upon '
        'gaining this Talent (you must pay the additional TP Cost or '
        'lose access to that Signature Technique and have all TP spent '
        'on it refunded).\n'
        '(3)-[Passive]: Gain an Integrated Scouter of the Grandmaster '
        'Craft DC.\n'
        '(4)-[Passive]: Increase the Strike Rolls of your Signature '
        'Techniques by 1(T).',
  ),
  TalentDef(
    name: 'Masterful Integration',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race, Machine Mutant Factor',
    description: 'You are able to make the most of the items you’ve '
        'Integrated.\n'
        '(1)-[Triggered, 1/Round]: When making an Attacking Maneuver, '
        'you may destroy an Integrated Item to apply an Energy Charge '
        'to that Attacking Maneuver.\n'
        '(2)-[Triggered, 1/Encounter]: When you destroy an Integrated '
        'Apparel through your own effects, you may apply one of its '
        'Apparel Qualities to another applicable Apparel you have '
        'Integrated.\n'
        '(3)-[Triggered, 1/Encounter]: When you destroy an Integrated '
        'Weapon through your own effects, you may apply one of its '
        'Weapon Qualities to another applicable Weapon you have '
        'Integrated.',
  ),
  TalentDef(
    name: 'Metallic Movement',
    category: TalentCategory.racial,
    raceRestriction: 'Android',
    prerequisitesText: 'Android Race, Machine Mutant Factor',
    description: 'Able to pass through metal as if it were part of you, '
        'you move around the battlefield in chaotic, unpredictable '
        'ways.\n'
        '(1)-[Passive]: While occupying a Square with the Metallic '
        'Environmental Quality or while adjacent to a Feature with the '
        'Metallic Feature Quality, increase your Defense Value and Soak '
        'Values by 1(T).\n'
        '(2)-[Passive]: You may move through Features with the Metallic '
        'Feature Quality as if they were not present.\n'
        '(3)-[1/Round]: If you are on a Square with the Metallic '
        'Environmental Quality, you may move to any other Square with '
        'the Metallic Environmental Quality on the Battlefield.',
  ),

  // -------------------------------------------------------------- Angel ---
  TalentDef(
    name: 'Angelic Technique',
    category: TalentCategory.racial,
    raceRestriction: 'Angel',
    prerequisitesText: 'Angel Race',
    description: 'You have honed your combat techniques to angelic '
        'perfection.\n'
        '(1)-[Passive]: Increase the amount of Technique Points you '
        'gain from Skill Improvements by 2. This effect applies '
        'retroactively.\n'
        '(2)-[Triggered, 1/Round]: If you use the Basic Attack Maneuver '
        'while in the Healthy Health Threshold, you may apply an '
        'Advantage with a TP Cost of 10 or less to that Attacking '
        'Maneuver.\n'
        '(3)-[Triggered, 1/Encounter]: If the current Combat Round is '
        'the 3rd or later Combat Round in this Combat Encounter and you '
        'use an Ultimate Signature Technique, instead of gaining Energy '
        'Charges for each Health Threshold you are below, gain Energy '
        'Charges for each Health Threshold you are above.',
  ),
  TalentDef(
    name: 'Angelic Guidance',
    category: TalentCategory.racial,
    raceRestriction: 'Angel',
    prerequisitesText: 'Angel Race',
    description: 'With your seraphic grace and wisdom, you help others '
        'reach their greatest potential.\n'
        '(1)-[Passive]: While you are adjacent to an Ally, increase '
        'that Ally’s Dodge Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If an adjacent Ally makes a Combat '
        'Roll, you may spend a Counter Action to increase that Combat '
        'Roll by 2(T).\n'
        '(3)-[Triggered, 1/Round]: If an adjacent Ally moves, you may '
        'use the Movement Maneuver as an Out-of-Sequence Maneuver after '
        'that movement ends.',
  ),
  TalentDef(
    name: 'Watchful Gaze',
    category: TalentCategory.racial,
    raceRestriction: 'Angel',
    prerequisitesText: 'Angelic Guidance',
    description: 'Your intense focus and unwavering attention allow you '
        'to instruct your comrades, even at a distance.\n'
        '(1)-[Ruling]: All Squares within a Sphere AoE (centered on '
        'you) are within your ‘Guidance Range’.\n'
        '(2)-[Passive]: For the effects of Angelic Guidance, rather '
        'than adjacent, that Ally can be on any Square within your '
        'Guidance Range.\n'
        '(3)-[1/Round]: As an Instant Maneuver during your turn or an '
        'Ally’s turn, you may move to any Square adjacent to an Ally '
        'within your Guidance Range.\n'
        '(4)-[Triggered, 1/Round]: If an Ally within your Guidance '
        'Range successfully Dodges an Opponent’s Attacking Maneuver, '
        'you may spend 1 Counter Action. If you do, that Ally may use '
        'the Basic Attack Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Attendant’s Focus',
    category: TalentCategory.racial,
    raceRestriction: 'Angel',
    prerequisitesText: 'Watchful Gaze',
    description: 'With a keen eye and a keener mind, your graceful '
        'reminders and direct instructions ensure your partners emerge '
        'victorious.\n'
        '(1)-[Passive]: Increase the Magnitude of your Guidance Range '
        'to Huge.\n'
        '(2)-[Passive]: All Allies within your Guidance Range have '
        'their Surgency increased by 2(T).\n'
        '(3)-[Passive]: For any effects or Maneuvers that would target '
        'an Ally, your Melee Range is considered to be your Guidance '
        'Range.\n'
        '(4)-[1/Encounter]: As a Standard Maneuver with an Action Cost '
        'of 1 Action, you may spend any number of Counter Actions. '
        'Then, for each Action spent, you may target an Ally within '
        'your Guidance Range. Those targeted Allies may use a Healing '
        'Surge as an Out-of-Sequence Maneuver.',
  ),

  // ---------------------------------------------------------- Arcosian ---
  TalentDef(
    name: 'Reserved Tail',
    category: TalentCategory.racial,
    raceRestriction: 'Arcosian',
    prerequisitesText: 'Arcosian Race',
    description: 'You often hold back your full might, building up '
        'battle momentum in order to unleash a brutal assault.\n'
        '(1)-[Triggered, Resource]: At the end of a Combat Round, if '
        'you are not in the Spectator State and did not use the Tail '
        'Attack Maneuver, gain a stack of Reserved Force (max. 4).\n'
        '(2)-[Passive]: While you have 1+ stack of Reserved Force, '
        'reduce the Ki Point Cost of your Attacking Maneuvers by 1(T).\n'
        '(3)-[Passive]: For every stack of Reserved Force you possess, '
        'increase your Soak Value and Surgency by 1(T) (max. 2(T)).\n'
        '(4)-[Triggered, 1/Round]: If you use the Tail Attack Maneuver, '
        'you may spend all of your stacks of Reserved Force to increase '
        'the Strike Roll by 1(T) and increase the Wound Roll by x(T), '
        'where x is equal to the number of Reserved Force stacks spent '
        'on this Attacking Maneuver.',
  ),

  // ------------------------------------------------------- Bio Android ---
  TalentDef(
    name: 'Genetic Catalogue',
    category: TalentCategory.racial,
    raceRestriction: 'Bio Android',
    prerequisitesText: 'Bio-Android Race, Genetic Splicing Factor',
    description: 'Your genetic memory includes the techniques of your '
        'forebears.\n'
        "(1)-[Ruling]: Upon gaining this Talent, and if you gain any "
        "Factor Traits for the Genetic Splicing Factor afterwards, with "
        "the help of your ARC, create a Character for each of your "
        "Factor Traits from Genetic Splicing. These Characters are "
        "known as your 'Genetic Donors' and represent the Characters "
        "whose DNA went into your creation. If you were using existing "
        "Characters for the sources of your DNA, then you may use those "
        "instead.\n"
        '(2)-[1/Round]: You may use a Unique Ability possessed by your '
        'Genetic Donors if you meet the Prerequisites.\n'
        '(3)-[Triggered, 1/Round]: If you use the Signature Technique '
        'Maneuver, you may use a Signature Technique possessed by one '
        'of your Genetic Donors.',
  ),

  // --------------------------------------------------------- Cerealian ---
  TalentDef(
    name: 'Mystical Gaze',
    category: TalentCategory.racial,
    raceRestriction: 'Cerealian',
    prerequisitesText: 'Cerealian Race',
    description: 'Your unerring gaze allows you to use your potent '
        'magical abilities as easily as others of your kin exploit '
        'openings to attack.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of your Unique '
        'Abilities by 1(T).\n'
        '(2)-[Triggered]: If an Opponent triggers your Exploit '
        'Maneuver, instead of using the Exploit Maneuver, you may use a '
        'Unique Ability that is a Standard Maneuver as an '
        'Out-of-Sequence Maneuver. You must still pay the Action Cost '
        'for that Maneuver.\n'
        '(3)-[Triggered, 1/Encounter]: If you use the 2nd effect of '
        'Mystical Gaze, you may spend your stacks of Critical Eye as if '
        'they were Actions for the use of that Unique Ability.',
  ),
  TalentDef(
    name: 'Dedicated Spotter',
    category: TalentCategory.racial,
    raceRestriction: 'Cerealian',
    prerequisitesText: 'Cerealian Race',
    description: 'You serve a vital role in your team, calling out enemy '
        'weak points and coordinating the team’s offensive.\n'
        '(1)-[Passive]: While in the Spectator State, increase the '
        'Strike Rolls of your Allies by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If an Ally scores a Critical Result '
        'on a Strike or Wound Roll while you are in the Spectator '
        'State, increase the Damage Category of that Attacking Maneuver '
        'by 1 Category.\n'
        '(3)-[Triggered, 1/Encounter]: If an Ally uses an Attacking '
        'Maneuver while you are in the Spectator State, you may make '
        'that Attacking Maneuver a Called Shot.',
  ),

  // ------------------------------------------------------------ Demon ---
  TalentDef(
    name: 'Hedge Your Bets',
    category: TalentCategory.racial,
    raceRestriction: 'Demon',
    prerequisitesText: 'Demon Race',
    description: 'You don’t like to let the odds define you- by '
        'stacking the deck, you always know which card is about to be '
        'played.\n'
        '(1)-[Triggered, Resource]: If you succeed at a Pressure Check, '
        'you may choose to fail instead. If you do, gain a stack of '
        '‘Risk Aversion’ (max. 2).\n'
        '(2)-[Triggered]: If you gain a stack of Risk Aversion, regain '
        '2(bT) Life and Ki Points.\n'
        '(3)-[Triggered]: If you fail a Pressure Check, you may spend a '
        'stack of Risk Aversion to increase the Dice Score of that '
        'Pressure Check by 2. This may cause your Pressure Check to '
        'succeed.',
  ),
  TalentDef(
    name: 'Honorable Demon',
    category: TalentCategory.racial,
    raceRestriction: 'Demon',
    prerequisitesText: 'Demon Race',
    description: 'Whenever you fight, you avoid the dirty tricks your '
        'demonic brethren often resort to, ensuring that every fight is '
        'won with honor and dignity.\n'
        '(1)-[Passive]: If you have not inflicted a Combat Condition on '
        'an Opponent during this Combat Encounter, increase your Combat '
        'Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you win the Clash for the 3rd '
        'effect of Demonic Combat, instead of knocking that Opponent '
        'Prone, you may enter the Superior State until the start of '
        'your next turn.\n'
        '(3)-[Triggered, 1/Round]: If you win the Clash for the 4th '
        'effect of Demonic Combat, instead of inflicting the Impediment '
        'Combat Condition to that Opponent, you may use the Power Up '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Versatile Demon',
    category: TalentCategory.racial,
    raceRestriction: 'Demon',
    prerequisitesText: 'Demon Race, Demon Person Subrace',
    description: 'Your width and breadth of experience makes it hard to '
        'define you in any one category.\n'
        '(1)-[Passive]: Upon gaining this Talent, select and gain '
        'access to an additional option for the 3rd effect of Denizen '
        'of the Demon Realm.',
  ),

  // --------------------------------------------------------- Earthling ---
  TalentDef(
    name: 'Iron Guard',
    category: TalentCategory.racial,
    raceRestriction: 'Earthling',
    prerequisitesText: 'Earthling, Experienced Fighter Racial Trait',
    description: 'You quickly brace yourself for incoming damage.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(T).\n'
        '(2)-[Triggered]: If you trigger the 2nd effect of Experienced '
        'Fighter, instead of applying its usual effects, increase your '
        'Soak Value by 2(T) against the next Attacking Maneuver that '
        'hits you during this Combat Round. Reduce the Damage Category '
        'of that Attacking Maneuver by 1 Category for the sake of your '
        'Damage Calculation.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Mystic Power',
    category: TalentCategory.racial,
    raceRestriction: 'Earthling',
    prerequisitesText: 'Earthling, Experienced Fighter Racial Trait',
    description: 'Your combat experience encompasses strange and '
        'unusual abilities.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of your Unique '
        'Abilities by 1(T).\n'
        '(2)-[Triggered]: If you trigger the 2nd effect of Experienced '
        'Fighter, instead of applying its usual effects, increase your '
        'Might and Saving Throws by 1(T) for the duration of the next '
        'Unique Ability you use during this Combat Round.',
  ),
  TalentDef(
    name: 'Way of the Champion',
    category: TalentCategory.racial,
    raceRestriction: 'Earthling',
    prerequisitesText: 'Earthling, Experienced Fighter Racial Trait',
    description: 'As a champion of the people, you empower others to '
        'become great in their own right!\n'
        '(1)-[Passive]: Increase the Wound Rolls and Soak Value of your '
        'Allies by 1(T) while you are in the Spectator State.\n'
        '(2)-[Triggered, 1/Round]: If you use Experienced Fighter, '
        'rather than applying its effects to you, you may apply them '
        'to an Ally of your choice.',
  ),
  TalentDef(
    name: 'Zooming Third Eye',
    category: TalentCategory.racial,
    raceRestriction: 'Earthling',
    prerequisitesText: 'Earthling, Triclops Factor',
    description: 'Thanks to the uncanny vision granted by your third '
        'eye, none can escape your sight.\n'
        '(1)-[Passive]: Increase your Perception Skill Bonus by 2.\n'
        '(2)-[Passive]: You cannot suffer from the Long Range Penalty, '
        'but none of your Signature Techniques may possess the Short '
        'Range Disadvantage. If you already possessed a Signature '
        'Technique with the Short Range Disadvantage, it loses it upon '
        'gaining this Talent (you must pay the additional TP Cost or '
        'lose access to that Signature Technique and have all TP spent '
        'on it refunded).\n'
        '(3)-[Passive]: Increase the Strike Rolls of your Signature '
        'Techniques by 1(T).',
  ),

  // ------------------------------------------------------- Glass Tribe ---
  TalentDef(
    name: 'Autonomous Glass Soldiers',
    category: TalentCategory.racial,
    raceRestriction: 'Glass Tribe',
    prerequisitesText: 'Glass Tribe, Master of Minions Talent, Warriors '
        'of Glass Racial Trait',
    description: 'You can imbue some of your Glass Soldiers with a '
        'semblance of life.\n'
        "(1)-[1/Round, Ruling]: As a Standard Maneuver with an Action "
        "Cost of 1 Action, spend up to 8(bT) Ki Points. For every 4(bT) "
        "Ki Points spent, select an unoccupied square with the Glass "
        "Environmental Quality and create a 'Glass Knight' (that square "
        "loses the Glass Environmental Quality after the Glass Knight "
        "is created). A Glass Knight is a Minion of the Custom Species "
        "Race with the following Racial Traits and Flaws: Abnormal "
        "Anatomy (Primary), Armored Exoskeleton (Primary), Combative "
        "Organism, Squadron Species, Minion Species.\n"
        '(2)-[Passive]: Glass Knights count as Glass Soldiers for your '
        'effects (except the 5th effect of Warriors of Glass).\n'
        '(3)-[Passive]: Glass Knights have their Combat Rolls increased '
        'by 1(T) while occupying a square with the Glass Environmental '
        'Quality.',
  ),
  TalentDef(
    name: 'Copy in the Mirror',
    category: TalentCategory.racial,
    raceRestriction: 'Glass Tribe',
    prerequisitesText: 'Glass Tribe, Autonomous Glass Soldiers Talent',
    description: 'Taking direct control over one of your Glass '
        'Soldiers, you create a second self.\n'
        "(1)-[Triggered, Ruling]: If you would create a Glass Knight, "
        "you may spend 4(bT) Ki Points to instead create a Duplicate "
        "Minion of yourself known as a 'Glass Copy'.\n"
        '(2)-[Passive]: Your Glass Copies are treated as Glass Knights '
        'for all of your effects.',
  ),
  TalentDef(
    name: 'Glass Decorations',
    category: TalentCategory.racial,
    raceRestriction: 'Glass Tribe',
    prerequisitesText: 'Glass Tribe',
    description: 'You form beautiful sculptures out of glass, placed '
        'directly onto the battlefield.\n'
        '(1)-[Passive]: Increase the Strike and Wound Rolls of your '
        'Attacking Maneuvers of the Glass Profile by 1(T) if they '
        'target an Opponent adjacent to a Feature with the Glass '
        'Feature Quality.\n'
        '(2)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 '
        'Action, you may spend up to 8(bT) Ki Points. For every 2(bT) '
        'Ki Points, you may select a Square that is not at Long Range. '
        'Create a Feature with a Hardness Rank of 2 and the Glass '
        'Feature Quality.\n'
        '(3)-[Triggered, 1/Round]: If you create a Feature(s) with the '
        'Glass Feature Quality, you may apply either the Sharp or '
        'Reflective Feature Quality to those Feature(s).',
  ),

  // ------------------------------------------------------------- Heran ---
  TalentDef(
    name: 'Marauding Captain',
    category: TalentCategory.racial,
    raceRestriction: 'Heran',
    prerequisitesText: 'Herans, Cutthroat Teamwork',
    description: 'You treat all those who work under your command as '
        'expendable.\n'
        '(1)-[Passive]: For Cutthroat Teamwork, ignore the ‘(that is '
        'not a Minion)’ parts of that Trait’s effects.\n'
        '(2)-[Passive]: All of your Minions have their Soak Value '
        'increased by 1(T).',
  ),
  TalentDef(
    name: 'Sorcering Corsair',
    category: TalentCategory.racial,
    raceRestriction: 'Heran',
    prerequisitesText: 'Herans',
    description: 'With the mystical might at your disposal, no one is '
        'safe from being plundered by your hand.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of your Unique '
        'Abilities by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use a Unique Ability that '
        'initiates a Clash against an Opponent with one of its effects, '
        'and that Opponent is adjacent to one of your Allies, apply the '
        'following effect depending on the type of Clash: '
        'Might/Saving Throw/Combat Roll: Increase your Dice Score for '
        'this Clash by 1(T). Skill: Increase your Dice Score for this '
        'Clash by 2.',
  ),
  TalentDef(
    name: 'Style and Greed',
    category: TalentCategory.racial,
    raceRestriction: 'Heran',
    prerequisitesText: 'Herans',
    description: 'You take everything you can get your greedy hands '
        'on, and you make sure you look good doing it.\n'
        '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
        '(2)-[Triggered]: If you hit an Opponent with an Attacking '
        'Maneuver, you may reduce the Break Value of your Top Layer of '
        'Apparel by 1 to gain a stack of Greed.\n'
        '(3)-[Triggered, 1/Encounter]: If any piece of your Apparel is '
        'destroyed, regain Life and Ki Points equal to 1/2 of your '
        'Surgency.',
  ),

  // -------------------------------------------------------- Konatsian ---
  TalentDef(
    name: 'Party Tactics',
    category: TalentCategory.racial,
    raceRestriction: 'Konatsian',
    prerequisitesText: 'Konatsian, 2+ Teamwork Talents',
    description: 'Supporting other members of your group is one of your '
        'most important roles.\n'
        '(1)-[Passive]: Increase the Combat Rolls of all Allies within '
        'a Minor Sphere AoE (centered on you) by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If an Ally uses an Attacking '
        'Maneuver, you may spend a stack of Tension to apply an Energy '
        'Charge to that Attacking Maneuver.\n'
        '(3)-[Triggered, 1/Round]: If an Ally is targeted by an '
        'Attacking Maneuver, you may spend a stack of Tension to '
        'increase that Ally’s Damage Reduction by 3(T) for the duration '
        'of that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Weapon Arts',
    category: TalentCategory.racial,
    raceRestriction: 'Konatsian',
    prerequisitesText: 'Konatsian, 2+ Weapon Talents',
    description: 'The ancient arts of combat have been passed down to '
        'you, leaving you to carry on the legacy of your people.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Armed Attacks '
        'by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use a Signature Technique of '
        'the Energy or Magic Foundation while wielding a Physical '
        'Weapon (except a Shield), you may apply the effects of that '
        'Weapon’s Weapon Category to that Attacking Maneuver.',
  ),

  // ------------------------------------------------------------- Majin ---
  TalentDef(
    name: 'Goop Throw',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin, Primordial Majin Factor',
    description: 'Throw your Goop at an Opponent!\n'
        '(1)-[Passive]: Your Goop can use the Grapple Maneuver.\n'
        '(2)-[Passive]: Increase the Magnitude for the 4th effect of '
        'From Goop by 1.\n'
        '(3)-[Triggered, 1/Encounter]: If a Goop is created on a Square '
        'adjacent to an Opponent, that Goop may use the Grapple '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Battle Goo',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin, Primordial Majin Factor',
    description: 'Your Goops are now combat-ready!\n'
        '(1)-[Passive]: Increase your maximum number of Minions by 2.\n'
        '(2)-[Passive]: Increase the Life Points of your Goops by 2 for '
        'each Power Level reached (after all other calculations).\n'
        '(3)-[Passive]: Your Goops gain access to (and can use) the '
        'Basic Attack Maneuver and Intervene Maneuver.',
  ),
  TalentDef(
    name: 'Detached Limbs',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin, Primordial Majin Factor',
    description: 'You morph your Goop into a limb to attack an '
        'Opponent.\n'
        '(1)-[Passive]: Increase your Goop’s Soak Value by 1(bT).\n'
        '(2)-[Triggered]: When making an Attacking Maneuver, you may '
        'have that Attacking Maneuver originate from one of your Goops '
        'as if you were occupying that Square, instead of the Square '
        'you currently occupy.\n'
        '(3)-[Triggered, 1/Round]: If you use the 2nd effect of '
        'Detached Limbs, you may make a Clash (Impulsive) against a '
        'target of that Attacking Maneuver. If you win, they suffer '
        'from the Guard Down Combat Condition for the duration of that '
        'Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Mini Majin',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin, Master of Minions Talent',
    description: 'You transform one of your Goops, creating a '
        'miniature version of yourself.\n'
        '(1)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 '
        'Action, you can spend 8(bT) Ki Points to create a Duplicate '
        'Minion. If you do, that Duplicate Minion’s base Size Category '
        'is a Size Category smaller than yours.\n'
        '(2)-[Triggered/Threshold, 1/Encounter]: Create a Duplicate '
        'Minion. If you do, that Duplicate Minion’s base Size Category '
        'is a Size Category smaller than yours.',
  ),
  TalentDef(
    name: 'AIIIEEEEEEE',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin, 2+ Skill Ranks in Bluff',
    description: 'You explode violently upon defeat. That would surely '
        'kill anyone.\n'
        '(1)-[Passive]: Increase your Skill Bonus for the Bluff Skill '
        'by 1.\n'
        '(2)-[Passive]: Increase your Racial Life Modifier by 2.\n'
        '(3)-[Triggered/Defeated]: Set your Life Points to 1, then make '
        'a Clash (Bluff vs Perception/Intuition) against all Opponents. '
        'If you win, you become Hidden to those Opponents.',
  ),
  TalentDef(
    name: 'Roomy Biology',
    category: TalentCategory.racial,
    raceRestriction: 'Majin',
    prerequisitesText: 'Majin',
    description: 'Learning to make the best use of your supernatural '
        'anatomy, you’ve discovered that the interior of your body is '
        'an extra-dimensional space that you can control at-will.\n'
        '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
        '(2)-[Passive]: You cannot lose the second Clash for the '
        'Possess maneuver.\n'
        '(3)-[Addendum]: You may store Items and willing or Defeated '
        'Characters within your body (‘Inner Room’). To do so costs 1 '
        'Action while holding or adjacent to the Item/Character. You '
        'may also remove any Item/Character at the cost of 1 Action, '
        'with any Character entering the Battlefield on a Square '
        'adjacent to you of your choice. The space inside of you is '
        'vast and may function as its own Battlefield. If a Combat '
        'Encounter is initiated within this space, you may create a '
        'Duplicate Minion to enter that Combat Encounter. This '
        'Duplicate Minion is of any Size Category of your choice and, '
        'if they die or are Defeated, you may create another at the '
        'start of a Combat Round (if you do, the former Duplicate '
        'Minion dies). If a Character stops being Defeated within you '
        'and does not wish to remain there, or simply wish to leave at '
        'the start of their turn, they can make a Might Clash against '
        'you. If they succeed, they can exit your body and re-enter the '
        'Battlefield on a Square adjacent to you of their choice. Any '
        'Absorbed Characters from your stacks of Absorption are stored '
        'within your body, but suffer the effects of the Sleeping '
        'Combat Condition. This Combat Condition cannot be removed '
        'while an Absorbed Character is inside of your body and they '
        'cannot be moved from the Square they occupy. A Character '
        'adjacent to an Absorbed Character can make a Standard Maneuver '
        'with an Action Cost of 2 Actions to make a Might Clash against '
        'you. If they win, you lose that stack of Absorption and that '
        'Absorbed Character can be moved. While Adventuring, you can '
        'freely store or remove Items/Characters from within your body '
        'without spending any time. Any Character must be Willing or '
        'Defeated at the time, however. An Absorbed Character can be '
        'removed by making a Might Clash through an Adventuring '
        'Maneuver with a Time Cost of 1 Minute and a Session Limit of '
        '2.',
  ),

  // --------------------------------------------------------- Namekian ---
  TalentDef(
    name: 'Namekian Progenitor',
    category: TalentCategory.racial,
    raceRestriction: 'Namekian',
    prerequisitesText: 'Namekian',
    description: 'In the moment of your death, you are prepared to '
        'reincarnate yourself through biological means.\n'
        '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
        '(2)-[Triggered/Defeated]: Die and leave the Combat Encounter. '
        'After the Combat Encounter ends, create a new Character of the '
        'Namekian Race to be your Character going forward (they do not '
        'gain a Gear Kit at Character Creation). This Character is of '
        'the same Power Level as you, and can inherit any number of '
        'your Transformations after Character Creation (if they meet '
        'the Prerequisites). This new Character also gains the '
        'Reincarnated Factor with you as the Past Life and may also '
        'gain the Inherited Life Awakening if that would not exceed '
        'their Awakening Limit.',
  ),
  TalentDef(
    name: 'Telepathic Teamwork',
    category: TalentCategory.racial,
    raceRestriction: 'Namekian',
    prerequisitesText: 'Namekian, Telepathic Warning, 2+ Teamwork '
        'Talents',
    description: 'Your inherent telepathy makes coordinating with '
        'others both silent and deadly.\n'
        '(1)-[Passive]: If you are in the Melee Range of a Character '
        'you are telepathically communicating with (see — Telepathy '
        'Unique Ability), increase both of your Wound Rolls by 1(T). '
        'This effect cannot stack.\n'
        '(2)-[Triggered, 2/Round]: If an Ally makes an Attacking '
        'Maneuver, you may increase the Strike Roll of that Attacking '
        'Maneuver by 1(T). If a target of that Attacking Maneuver is '
        'Studied, increase the Wound Roll of that Attacking Maneuver by '
        '1(T) as well.',
  ),
  TalentDef(
    name: 'Namekian Finger',
    category: TalentCategory.racial,
    raceRestriction: 'Namekian',
    prerequisitesText: 'Namekian',
    description: 'Your elastic biology ensures that ensnaring foes in '
        'your grasp is a simple feat.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Physical '
        'Attacks by 1(T).\n'
        '(2)-[Passive]: Increase your Grapple Checks by 1(T).\n'
        '(3)-[Passive]: Increase the number of Squares your Melee Range '
        'is increased through the 4th effect of Namekian Biology to 5 '
        'Squares.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundPhysical],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),

  // ------------------------------------------------------- Neko Majin ---
  TalentDef(
    name: 'Cat’s Paw',
    category: TalentCategory.racial,
    raceRestriction: 'Neko Majin',
    prerequisitesText: 'Neko Majin Race',
    description: 'Like a mischievous cat, you take your enemies’ energy '
        'and use it against them.\n'
        '(1)-[Triggered, 1/Round]: If an Opponent within your Melee '
        'Range uses an Attacking Maneuver, make a Clash (Cognitive/'
        'Morale vs Any Saving Throw of their choice) against them. If '
        'you win, increase the Ki Point Cost of that Attacking Maneuver '
        'by 1/2 of its Profile’s Ki Point Cost (before any '
        'modifications). Then regain Ki Points equal to the increase '
        'in Ki Point Cost.\n'
        '(2)-[Triggered, 1/Round]: If an Opponent within your Melee '
        'Range uses the Energy Charge Maneuver, make a Clash '
        '(Cognitive/Morale vs Any Saving Throw of their choice) against '
        'them. If you win, cancel their use of the Energy Charge '
        'Maneuver (they regain the Ki Point Cost, but not the Action '
        'Cost).\n'
        '(3)-[Triggered, 1/Encounter]: If you win the Clash for the 1st '
        'or 2nd effects of Cat’s Paw, you may use the Signature '
        'Technique Maneuver as an Out-of-Sequence Maneuver. If you do, '
        'this Attacking Maneuver must be a Copied Technique.',
  ),
  TalentDef(
    name: 'Feline Rally',
    category: TalentCategory.racial,
    raceRestriction: 'Neko Majin',
    prerequisitesText: 'Neko Majin Race',
    description: 'You broadcast your energy to your allies, giving them '
        'a portion of your power.\n'
        '(1)-[Passive]: Increase the Surgency of all your Allies by '
        '1(T).\n'
        '(2)-[Triggered/Start of Turn]: While you have an Integrated '
        'Majin-Dama, all of your Allies regain 3(bT) Ki Points.\n'
        '(3)-[Triggered, 1/Encounter]: If you use a Surge, all of your '
        'Allies may regain Ki Points equal to 1/2 of your Surgency.',
  ),
  TalentDef(
    name: 'Will of Nine Lives',
    category: TalentCategory.racial,
    raceRestriction: 'Neko Majin',
    prerequisitesText: 'Neko Majin Race',
    description: 'Like a wily tomcat on the run, you are incredibly '
        'difficult to put down for good.\n'
        '(1)-[Passive]: While you have an Integrated Majin-Dama, '
        'increase the Dice Score of your Steadfast Checks by 1.\n'
        '(2)-[Triggered]: If you use a Healing Surge during your turn, '
        'you may stop benefiting from the effects of any Integrated '
        'Majin-Dama until the start of your next turn. If you do, '
        'increase the amount of Life Points regained by your Surgency.\n'
        '(3)-[Triggered/Threshold, 1/Encounter]: If you have an '
        'Integrated Majin-Dama, use a Healing Surge as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Cat Burglar',
    category: TalentCategory.racial,
    raceRestriction: 'Neko Majin',
    prerequisitesText: 'Neko Majin Race, 2+ Skill Ranks in Thievery',
    description: 'With feline grace and incredible reflexes, your '
        'nimble-fingered antics go more easily unnoticed.\n'
        '(1)-[Passive]: Increase the Skill Bonus of your Thievery by '
        '1.\n'
        '(2)-[Passive]: Your Majin-Dama cannot be stolen unless you are '
        'Defeated.\n'
        '(3)-[Triggered, 1/Round]: If you have to use another Skill for '
        'a Clash initiated by an Opponent, you may use your Thievery '
        'Skill instead.\n'
        '(4)-[Triggered, 1/Encounter]: If you win the Clash for the '
        'Snatch Special Maneuver against an Opponent, you may select a '
        'Signature Technique they know. It becomes a Copied Technique '
        'as if obtained through the 1st effect of Quick Learner.',
  ),

  // ------------------------------------------------------- Neo-Tuffle ---
  TalentDef(
    name: 'Tuffle Fusion',
    category: TalentCategory.racial,
    raceRestriction: 'Neo-Tuffle',
    prerequisitesText: 'Neo-Tuffle, Parasite Subrace',
    description: 'You absorb another of your kin into yourself, '
        'becoming something greater than the sum of your respective '
        'parts.\n'
        '(1)-[Passive]: Select either the Corporeal Save or the '
        'Impulsive Save. Apply your Racial Saving Throw Bonus to your '
        'selected Save in addition to the Cognitive Save.\n'
        '(2)-[1/Encounter]: As a Standard Maneuver with an Action Cost '
        'of 2 Actions, target another Character of the Neo-Tuffle Race '
        'and Parasite Subrace within your Melee Range. Make a Clash '
        '(Impulsive/Corporeal) against them. If you win, make a Clash '
        '(Cognitive) against them. If you win both Clashes, enter a '
        'Fusion with the Parasitic Fusion Method using yourself and '
        'that Character as the Fused Characters. If the target applied '
        'the effects of Willing Failure to both Clashes, the control of '
        'the Fusion follows the usual rules, but if not and you won '
        'both Clashes, the Fusion is controlled solely by you.',
  ),
  TalentDef(
    name: 'Mutualism',
    category: TalentCategory.racial,
    raceRestriction: 'Neo-Tuffle',
    prerequisitesText: 'Neo-Tuffle, Parasite Subrace',
    description: 'While you may use your host’s body for safety and '
        'strength, you are willing to give, not just take, ensuring '
        'that your host benefits too.\n'
        '(1)-[Ruling]: While you are a Possessing Character of a '
        'Character that is not being controlled by you, you are in '
        '‘Symbiosis’ and the Character that has you as a Possessing '
        'Character is your ‘Host Ally’.\n'
        '(2)-[Passive]: While in Symbiosis, your Host Ally has their '
        'Combat Rolls and Surgency increased by 1(T).\n'
        '(3)-[Passive]: While in Symbiosis, the 9th effect of Overtaken '
        'loses the [Automatic/Start of Turn] Keyword and gains the '
        '[Triggered/Start of Turn] Keyword.\n'
        '(4)-[1/Round]: While in Symbiosis, you may use a Standard '
        'Maneuver with an Action Cost of 1 Action as an Instant '
        'Maneuver during your Host Ally’s turn. If you do, it '
        'originates from the Square your Host Ally is occupying, and '
        'they are considered the Character who used it for the effects '
        'of any of your Opponents/Allies.\n'
        '(5)-[1/Round]: If you are in Symbiosis, you may remove the '
        'Overtaken Awakening from your Host Ally as an Instant '
        'Maneuver.\n'
        '(6)-[Triggered, 1/Round]: If you win both Clashes for the '
        'effects of the Possess Maneuver, you can choose not to take '
        'control of the targeted Character.\n'
        '(7)-[Triggered/Start of Combat Round]: If you are a Possessing '
        'Character of a Character that is not being controlled by you, '
        'that Character may regain Life or Ki Points (you decide) '
        'equal to 1/2 of your Surgency.',
  ),
  TalentDef(
    name: 'Tuffle Parasite',
    category: TalentCategory.racial,
    raceRestriction: 'Neo-Tuffle',
    prerequisitesText: 'Neo-Tuffle, Parasite Subrace',
    description: 'You are able to leave behind a piece of yourself in '
        'the people you’ve possessed.\n'
        '(1)-[Passive]: Increase your maximum number of Minions by 2.\n'
        '(2)-[Triggered]: If you make a Cognitive Clash against a '
        'Character you were previously the Possessing Character of '
        'during this Combat Encounter, increase your Dice Score of '
        'that Clash by 1(T).\n'
        '(3)-[Triggered]: If you win both Clashes for the effects of '
        'the Possess Maneuver against a Minion, they become your '
        'Minion. This effect does not apply if that Minion is a '
        'Special Minion.\n'
        '(4)-[1/Encounter]: As an Instant Maneuver while you are a '
        'Possessing Character, you may remove the Overtaken Awakening '
        'from the Character you are a Possessing Character of. If you '
        'do, make a Clash (Cognitive) against them. If you win, that '
        'Character becomes your Minion for the remainder of the Combat '
        'Encounter (depending on circumstances, your ARC may allow them '
        'to remain as your Minion indefinitely).',
  ),
  TalentDef(
    name: 'Scholar’s Intellect',
    category: TalentCategory.racial,
    raceRestriction: 'Neo-Tuffle',
    prerequisitesText: 'Neo-Tuffle',
    description: 'Thanks to the mighty intellect instilled in you by '
        'your forebears, you display superior knowledge and skills.\n'
        '(1)-[Passive]: Increase the Dice Score of any Skill Clash '
        'made against your Inferior by 1.\n'
        '(2)-[Triggered, 1/Round]: When rolling for a Skill Clash, you '
        'may spend up to 2 Revenge Points to increase the Dice Score of '
        'that Skill Clash by 1.',
  ),

  // ------------------------------------------------------------ Saiyan ---
  TalentDef(
    name: 'Saiyan Tail Resistance',
    category: TalentCategory.racial,
    raceRestriction: 'Saiyan',
    prerequisitesText: 'Saiyan, Tailed chosen for the 5th effect of '
        'Saiyan Heritage',
    description: 'You have overcome the inherent weakness of your '
        'tail.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(bT).\n'
        '(2)-[Passive]: Ignore the 4th effect of Saiyan Heritage.\n'
        '(3)-[Automatic]: If your effect for the Option effect of '
        'Saiyan Heritage becomes Tailless, lose this Talent and gain '
        'another Talent that you meet the Prerequisites for.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  TalentDef(
    name: 'Tail Proficiency',
    category: TalentCategory.racial,
    raceRestriction: 'Saiyan',
    prerequisitesText: 'Saiyan, Tailed chosen for the 5th effect of '
        'Saiyan Heritage',
    description: 'With training, you are able to use your tail for '
        'combat purposes.\n'
        '(1)-[Passive]: Increase your Wound Rolls by 1(T).\n'
        '(2)-[Passive]: While in the Oozaru Transformation, increase '
        'your Strike Rolls by 1(T).\n'
        '(3)-[1/Encounter]: You may use the Tail Attack Maneuver, but '
        'your Profile for that Attacking Maneuver is Simple.\n'
        '(4)-[Automatic]: If your effect for the Option effect of '
        'Saiyan Heritage becomes Tailless, lose this Talent and gain '
        'another Talent that you meet the Prerequisites for.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Kindhearted Saiyan',
    category: TalentCategory.racial,
    raceRestriction: 'Saiyan',
    prerequisitesText: 'Saiyan',
    description: 'Thanks to your benevolent nature, your comrades '
        'benefit from your thirst for battle.\n'
        '(1)-[Passive]: All Allies within your Melee Range have their '
        'Soak Value increased by 1(T).\n'
        '(2)-[1/Round]: As an Instant Maneuver during an Ally’s turn, '
        'you may spend a stack of Battle Born to target that Ally. '
        'That Ally has their Combat Rolls increased by 1(T) until the '
        'start of your next turn.',
  ),
  TalentDef(
    name: 'Primal Rage',
    category: TalentCategory.racial,
    raceRestriction: 'Saiyan',
    prerequisitesText: 'Saiyan, 2+ Raging Talents',
    description: 'Your unrelenting ire burns deep within the depths of '
        'your soul, igniting in a fiery blaze of fury when you’ve been '
        'hurt.\n'
        '(1)-[Passive]: While in the Raging State, increase your Tier '
        'of Power Extra Dice by 1 Dice Category.\n'
        '(2)-[Triggered/Raging, 1/Encounter]: If you are below the '
        'Bruised Health Threshold, gain a stack of Battle Born.',
  ),
  TalentDef(
    name: 'Saiyan Soul',
    category: TalentCategory.racial,
    raceRestriction: 'Saiyan',
    prerequisitesText: 'Saiyan',
    description: 'As the battle wages ever onward, you adapt to the '
        'ever-changing tides of war.\n'
        '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
        '(2)-[Passive]: While you have your maximum number of Battle '
        'Born stacks, increase your Wound Rolls by 1(T).\n'
        '(3)-[2/Round]: As an Instant Maneuver, move up to 2 of your '
        'Battle Born stacks applied to a Combat Roll to another Combat '
        'Roll of your choice.',
  ),

  // ------------------------------------------------------------ Shinjin ---
  TalentDef(
    name: 'Combat Observation',
    category: TalentCategory.racial,
    raceRestriction: 'Shinjin',
    prerequisitesText: 'Shinjin',
    description: 'By carefully studying your opponents, you are able to '
        'accurately predict how they will fight, and adjust your own '
        'tactics accordingly.\n'
        '(1)-[Triggered]: If you are targeted by an Attacking Maneuver, '
        'you may spend a Counter Action to increase your Defense Value '
        'and Soak Value by 1(T) for the duration of that Attacking '
        'Maneuver.\n'
        '(2)-[Triggered]: When making an Attacking Maneuver, you may '
        'spend a Counter Action to increase your Strike and Wound '
        'Rolls by 1(T) for the duration of that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Dedicated Watcher',
    category: TalentCategory.racial,
    raceRestriction: 'Shinjin',
    prerequisitesText: 'Shinjin',
    description: 'As a non-combatant yourself, you find the greatest '
        'success in helping others reach their fullest potential.\n'
        '(1)-[Passive]: For the 1st effect of the Spectator State, you '
        'may target an additional Ally.\n'
        '(2)-[Triggered]: While you are in the Spectator State, if an '
        'Ally makes an Attacking Maneuver, you may spend a Counter '
        'Action to increase their Strike and Wound Rolls by 1(T) for '
        'the duration of that Attacking Maneuver.\n'
        '(3)-[Triggered]: While you are in the Spectator State, if an '
        'Ally is targeted by an Attacking Maneuver, you may spend a '
        'Counter Action to increase their Defense Value and Soak Value '
        'by 1(T) for the duration of that Attacking Maneuver.',
  ),

  // ------------------------------------------------------------ Yardrat ---
  TalentDef(
    name: 'Spiritual Leadership',
    category: TalentCategory.racial,
    raceRestriction: 'Yardrat',
    prerequisitesText: 'Yardrat, Master of Minions Talent',
    description: 'Though you may take command, you still offer support '
        'to those who follow you.\n'
        '(1)-[Passive]: You may apply the 4th effect of Power of the '
        'Weak if you give Ki Points to a Minion through the Empower '
        'Maneuver.\n'
        '(2)-[Passive]: While you are Bonded to one of your Minions, '
        'they do not skip their Act Phase.\n'
        '(3)-[Passive]: All of your Minions have their Maximum Life '
        'Points increased by 2 for each Power Level reached (after all '
        'calculations).',
  ),
  TalentDef(
    name: 'Twinned Spirits',
    category: TalentCategory.racial,
    raceRestriction: 'Yardrat',
    prerequisitesText: 'Yardrat, Synchronized Combatants Talent',
    description: 'Through extreme synchronization, your battle partner '
        'has effectively become an extension of your own soul.\n'
        '(1)-[Passive]: You are always Bonded to your Partner, but you '
        'cannot become Bonded with any other Character.\n'
        '(2)-[Passive]: Your Partner has their Combat Rolls increased '
        'by 1(T).',
  ),
  TalentDef(
    name: 'Yaki Swarm',
    category: TalentCategory.racial,
    raceRestriction: 'Yardrat',
    prerequisitesText: 'Yardrat, Master of Minions Talent',
    description: 'You have bonded with creatures found on your '
        'homeworld, and can bring them into battle alongside you '
        'at-will.\n'
        "(1)-[1/Round, Ruling]: As a Standard Maneuver with an Action "
        "Cost of 1 Action, spend up to 8(bT) Ki Points. For every 4(bT) "
        "Ki Points spent, select an unoccupied Square within a Large "
        "Sphere AoE and create a 'Yaki' on that Square. A Yaki is a "
        "Minion of the Custom Species Race with the following Racial "
        "Traits, Inherent Factors, and Flaws: Squadron Species "
        "(Primary), Combative Organism (Primary), Blazing Speed, "
        "Beast-Man Factor (Part Beast – Claws and Burrowing Beast "
        "Bestial Traits), Minion Species.\n"
        '(2)-[Passive]: Yaki can become Bonded through the 4th effect '
        'of Power of the Weak despite being Minions.\n'
        '(3)-[Passive]: While a Yaki is a Bonded Ally, they have their '
        'Combat Rolls increased by 1(T).',
  ),
  TalentDef(
    name: 'Yaki Master',
    category: TalentCategory.racial,
    raceRestriction: 'Yardrat',
    prerequisitesText: 'Yaki Swarm Talent, Battle Yardrat Awakening',
    description: 'Your swarm of bonded Yaki fight together as one, '
        'anticipating your needs.\n'
        '(1)-[Passive]: While you are not Bonded, all of your Yaki are '
        'considered Bonded for the 3rd effect of Yaki Swarm.\n'
        '(2)-[Triggered/Start of Combat Round]: If you are not Bonded, '
        'target one of your Yaki Minions. That Yaki gains access to its '
        'Act Phase this Combat Round and gains 1 Counter Action.',
  ),

  // ============================================================= Raging ===
  TalentDef(
    name: 'Angry Warrior',
    category: TalentCategory.raging,
    prerequisitesText: 'N/A',
    description: 'Your rage pushes you to greater heights, allowing you '
        'to hit harder and more often.\n'
        '(1)-[Passive]: The L listed on any Raging Talent refers to '
        'your current Level of your use of the Raging State.\n'
        '(2)-[Triggered]: When you make an Attacking Maneuver while in '
        'the Raging State, you may choose to reduce the Natural Result '
        'of your Strike Roll by up to L. If you do, increase your Wound '
        'Roll for that Attacking Maneuver by 1(T) for each reduction to '
        'your Natural Result.\n'
        '(3)-[Triggered/Power, 2/Encounter]: Enter the Raging State '
        'until the end of your next turn.',
  ),
  TalentDef(
    name: 'Burning Fury',
    category: TalentCategory.raging,
    prerequisitesText: 'Angry Warrior',
    description: 'The flames of rage blazing inside you drive you '
        'forward, causing you to fight with reckless abandon.\n'
        '(1)-[Passive]: Halve the penalties from your Botch Results '
        'while in the Raging State.\n'
        '(2)-[Triggered, 1/Round]: If you hit an Opponent with an '
        'Attacking Maneuver while in the Raging State, reduce your Life '
        'Points by 4(bT) to inflict the Broken Combat Condition on that '
        'Opponent until the end of your turn.',
  ),
  TalentDef(
    name: 'Furious Berserker',
    category: TalentCategory.raging,
    prerequisitesText: 'Angry Warrior',
    description: 'Your rage is so powerful, it protects you from '
        'damage.\n'
        '(1)-[Passive]: While you are in the Raging State, increase '
        'your Damage Reduction by 1/2 (rounded up) of L(T).\n'
        '(2)-[Triggered/Threshold]: Regain Life Points equal to 2L(T).',
  ),
  TalentDef(
    name: 'Apoplectic Beast',
    category: TalentCategory.raging,
    prerequisitesText: 'Burning Fury and/or Furious Berserker, Tier of '
        'Power 3+',
    description: 'Charging forward in an unrelenting eruption of wrath, '
        'your instincts take over as your conscious mind disappears '
        'beneath the storm of rage inside you.\n'
        '(1)-[Passive]: While in the 2nd or higher Levels of the Raging '
        'State, you ignore the rules of Reduced Momentum.\n'
        '(2)-[Triggered]: When you make an Attacking Maneuver while in '
        'the Raging State, you may reduce your Life Points by L(T) to '
        'increase your Wound Roll for that Attacking Maneuver by an '
        'equal amount.',
  ),

  // =============================================================== Size ===
  TalentDef(
    name: 'Tremendous Warrior',
    category: TalentCategory.size,
    prerequisitesText: 'N/A',
    description: 'Towering over your enemies, you have long grown '
        'accustomed to fighting smaller opponents.\n'
        '(1)-[Passive]: Increase your Strike Rolls against an Opponent '
        'with a smaller Size Category than you by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you fail to hit an Opponent with '
        'an Attacking Maneuver that would benefit from the Punching '
        'Down rules, roll the Extra Dice from Punching Down regardless. '
        'Reduce that Opponent’s Life Points by that amount.',
  ),
  TalentDef(
    name: 'Size Matters',
    category: TalentCategory.size,
    prerequisitesText: 'Tremendous Warrior',
    description: 'Now you’re really getting huge!\n'
        '(1)-[Passive]: If your Size Category is Enormous or larger, '
        'increase your Damage Reduction by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you would make an Attacking '
        'Maneuver where you would apply the Punching Down rules to all '
        'targets of that Attacking Maneuver, that Attacking Maneuver '
        'becomes an Absolute Attack.',
  ),
  TalentDef(
    name: 'Miniature Warrior',
    category: TalentCategory.size,
    prerequisitesText: 'N/A',
    description: 'When someone is as small as you, all enemies are '
        'giants. You’ve learned to navigate in that world of giants '
        'with ease and efficiency.\n'
        '(1)-[Passive]: Increase your Wound Rolls against an Opponent '
        'with a larger Size Category than you by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you are hit by an Opponent’s '
        'Attacking Maneuver that benefits from the Punching Down rules, '
        'do not apply that bonus to this Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Size Doesn’t Matter',
    category: TalentCategory.size,
    prerequisitesText: 'Miniature Warrior',
    description: 'You’ve long since learned that it’s not the size of '
        'the dog in the fight that’s important, but the size of the '
        'fight in the dog.\n'
        '(1)-[Passive]: If your Size Category is Tiny or smaller, '
        'increase your Damage Reduction by 1(T).\n'
        '(2)-[Passive]: If your Size Category is Small or smaller, and '
        'you would receive Damage from an Absolute Attack that missed '
        'you, reduce that Damage by 2(bT).',
  ),
  TalentDef(
    name: 'All Sizes Fit Me',
    category: TalentCategory.size,
    prerequisitesText: '1+ Size Talent',
    description: 'You change sizes like changing your hat.\n'
        '(1)-[Passive]: While your Size Category is not your base Size '
        'Category, increase your Surgency by 2(T).\n'
        '(2)-[Triggered, 1/Round]: If you change your Size Category, '
        'you may use the Power Up Maneuver as an Out-of-Sequence '
        'Maneuver.',
  ),

  // ============================================================== Skill ===
  TalentDef(
    name: 'Practiced',
    category: TalentCategory.skill,
    prerequisitesText: 'N/A',
    description: 'You are especially adept in a variety of skills.\n'
        '(1)-[Passive]: If your Natural Result on a Skill Check is '
        'below 4, increase it to a 4.\n'
        '(2)-[Passive]: Gain a Skill Rank in 2 different Skills of your '
        'choice.',
  ),
  TalentDef(
    name: 'Show Stopping Performance',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Performance',
    description: 'You perform for everyone on the battlefield, '
        'inspiring awe in your allies, confidence in yourself, or '
        'terror in your enemies.\n'
        '(1)-[Option]: Upon gaining this Talent, select an effect from '
        'the list below.',
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Aggressive Performance',
            description: '[Passive]: While you are Hyped, increase your '
                'Wound Rolls by 2(T).',
          ),
          TraitOption(
            name: 'Flexible Performance',
            description: '[Passive]: While you are Hyped, increase your '
                'Dodge Rolls by 1(T).',
          ),
          TraitOption(
            name: 'Precision Performance',
            description: '[Passive]: While you are Hyped, increase your '
                'Strike Rolls by 1(T).',
          ),
          TraitOption(
            name: 'Resilient Performance',
            description: '[Passive]: While you are Hyped, increase your '
                'Soak Value by 2(T).',
          ),
          TraitOption(
            name: 'Invigorating Performance',
            description: '[Triggered, 1/Round]: When using the Hype '
                'Maneuver, regain 5(bT) Life and Ki Points.',
          ),
          TraitOption(
            name: 'Motivating Performance',
            description: '[Triggered, 1/Round]: When using the Hype '
                'Maneuver, all Allies within a Sphere AoE centered on '
                'you have their Combat Rolls increased by 1/4 (rounded '
                'up) of your Personality Modifier while you are Hyped.',
          ),
          TraitOption(
            name: 'Explosive Performance',
            description: '[Triggered, 1/Round]: When using the Hype '
                'Maneuver, if your last Maneuver was an Attacking '
                'Maneuver, reduce the Life Points of the Opponent(s) '
                'hit by that Attacking Maneuver by your Personality '
                'Modifier and 1/2 (rounded up) of your Might.',
          ),
        ],
      ),
    ],
  ),
  TalentDef(
    name: 'Dynamic Hype',
    category: TalentCategory.skill,
    prerequisitesText: '3+ Skill Ranks in Performance, Show Stopping '
        'Performance',
    description: 'With a variety of performances in your arsenal, your '
        'shows are unparalleled!\n'
        '(1)-[Passive]: Upon gaining this Talent, select 2 additional '
        'effects through the Option effect of Show Stopping Performance. '
        'You can only use and benefit from one of these effects at any '
        'one time.\n'
        '(2)-[Triggered, 1/Encounter]: When using the Hype Maneuver, '
        'you may benefit from two of your Option effects for Show '
        'Stopping Performance at once.',
  ),
  TalentDef(
    name: 'Team Pose',
    category: TalentCategory.skill,
    prerequisitesText: 'Show Stopping Performance',
    description: 'With the others in your group, your group performance '
        'grows stronger as everyone performs together.\n'
        '(1)-[Triggered]: If an Ally uses the Hype Maneuver within a '
        'Sphere AoE centered on you, regain 2(bT) Ki Points.\n'
        '(2)-[Triggered, 1/Encounter]: If you use the Hype Maneuver, '
        'any Allies within a Sphere AoE centered on you that have the '
        'Show Stopping Performance Talent may use the Hype Maneuver as '
        'an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Analytic Fighter',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Investigation',
    description: 'Studious and perceptive, you take the time to pick '
        'apart an enemy’s strengths and weaknesses.\n'
        '(1)-[Option]: Upon gaining this Talent, select an effect from '
        'the list below.',
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Damage Analysis',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, make a Clash (Investigation vs '
                'Intuition/Bluff/Stealth) against the targeted '
                'Character. Regardless of if you win or lose, increase '
                'your Wound Rolls against that target by 1(T) until '
                'the end of your next turn. If you won the Clash for '
                'this effect, that target gains the Broken Combat '
                'Condition until the start of your next turn.',
          ),
          TraitOption(
            name: 'Weak Point Analysis',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, make a Clash (Investigation vs '
                'Intuition/Bluff/Stealth) against the targeted '
                'Character. Regardless of if you win or lose, your '
                'Combat Rolls for the next Attacking Maneuver made '
                'against the targeted Character during this Combat '
                'Round have their Natural Result increased by 2. If '
                'you won the Clash for this effect, you may make that '
                'Maneuver a Called Shot.',
          ),
          TraitOption(
            name: 'Offensive Analysis',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, make a Clash (Investigation vs '
                'Intuition/Bluff/Stealth) against the targeted '
                'Character. Regardless of if you win or lose, increase '
                'your Strike Rolls against that target by 1(T) until '
                'the end of your next turn. If you won the Clash for '
                'this effect, increase the Strike Rolls of all Allies '
                'against that Opponent by an equal amount.',
          ),
          TraitOption(
            name: 'Defensive Analysis',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, make a Clash (Investigation vs '
                'Intuition/Bluff/Stealth) against the targeted '
                'Character. Regardless of if you win or lose, increase '
                'your Dodge Rolls against that target by 1(T) until the '
                'end of your next turn. If you won the Clash for this '
                'effect, increase the Dodge Rolls of all Allies against '
                'that Opponent by an equal amount.',
          ),
          TraitOption(
            name: 'Critical Tactics',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, reduce the Critical Target of all Strike and '
                'Wound Rolls made against the target by 1 until the end '
                'of your next turn.',
          ),
          TraitOption(
            name: 'Teamwork Tactics',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, increase the Combat Rolls of all Allies '
                'against that Opponent by 1/4 (rounded up) of your '
                'Scholarship Modifier (this effect cannot stack – if '
                'multiple Characters use this effect, only gain the '
                'highest bonus) until the end of your next turn.',
          ),
          TraitOption(
            name: 'Counter Tactics',
            description: '[Triggered, 1/Round]: If you use the Analysis '
                'Maneuver, gain an additional Counter Action. You may '
                'allow Allies to use this Counter Action if it is in '
                'response to the Attacking Maneuver of the targeted '
                'Character.',
          ),
        ],
      ),
    ],
  ),
  TalentDef(
    name: 'Flexible Planning',
    category: TalentCategory.skill,
    prerequisitesText: '3+ Skill Ranks in Investigation, Analytic '
        'Fighter',
    description: 'You are able to adapt to changes in the battlefield '
        'and adjust your strategies accordingly.\n'
        '(1)-[Passive]: Upon gaining this Talent, select 2 additional '
        'effects through the Option effect of Analytic Fighter. You can '
        'only use and benefit from one of these effects at any one '
        'time.\n'
        '(2)-[Triggered, 1/Round]: When using the Analysis Maneuver, '
        'you may target an additional Opponent to apply its effects '
        'to.\n'
        '(3)-[Triggered, 1/Encounter]: If there is only one Opponent, '
        'when you use the Analysis Maneuver against that Opponent, you '
        'may use two effects from the Option effect of Analytic Fighter '
        'and benefit from both of them.',
  ),
  TalentDef(
    name: 'Counter Jury-rigging',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Investigation and Craft '
        '(Weapon), Weapon Specialist',
    description: 'You are able to modify your weapons to suit the '
        'situation at hand, though such modifications don’t last.\n'
        '(1)-[Triggered, 1/Round]: While you are benefiting from the '
        'effects of the Analysis Maneuver, increase your Wound Rolls '
        'with Armed Attacks by an additional 2(T).\n'
        '(2)-[Triggered/Start of Combat Round]: Select a Weapon you '
        'possess and apply an applicable Weapon Quality that takes up 1 '
        'Weapon Slot to that Weapon until the end of the Combat Round '
        '(this can exceed the Weapon’s number of Weapon Slots).',
  ),
  TalentDef(
    name: 'Silent Footsteps',
    category: TalentCategory.skill,
    prerequisitesText: 'Footwork, 2+ Skill Ranks in the Stealth Skill',
    description: 'You are able to dampen the sounds of your movement, '
        'allowing you to pass unnoticed.\n'
        '(1)-[Triggered]: When you use the Rapid Movement effect of the '
        'Movement Maneuver, make a Skill Clash (Stealth vs Perception) '
        'against all of your Opponents. If you win against an Opponent, '
        'you become Hidden to them until the end of your next turn or '
        'until after you make an Attacking Maneuver against them.\n'
        '(2)-[Passive]: When making a Concealment Skill Check, you may '
        'use your Stealth Skill Bonus instead. If you do, reduce your '
        'Dice Score by 2.',
  ),
  TalentDef(
    name: 'Stealth Strike',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Stealth Skill',
    description: 'Slipping through the shadows, your strikes are '
        'deadly when you attack from hiding.\n'
        '(1)-[Passive]: Increase your Strike Rolls against your '
        'Oblivious Characters by 1(T).\n'
        '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver '
        'against an Opponent, make a Skill Clash (Stealth vs '
        'Perception). If you win, you become Hidden to them for the '
        'duration of this Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Assassinate',
    category: TalentCategory.skill,
    prerequisitesText: 'Stealth Strike, 3+ Skill Ranks in the Stealth '
        'Skill',
    description: 'When you attack from hiding, your strikes become '
        'even more lethal.\n'
        '(1)-[Passive]: Increase your Wound Rolls against your '
        'Oblivious Characters by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you hit an Oblivious Character '
        'with an Attacking Maneuver, you may spend 5(bT) Ki Points to '
        'increase the Damage Category of that Attacking Maneuver by 1 '
        'Category.',
  ),
  TalentDef(
    name: 'Master Assassin',
    category: TalentCategory.skill,
    prerequisitesText: 'Assassinate, 5+ Skill Ranks in the Stealth '
        'Skill',
    description: 'You are peerless in the realm of dealing death from '
        'the shadows.\n'
        '(1)-[Passive]: Increase your Wound Rolls against your '
        'Oblivious Characters by 1(T).\n'
        '(2)-[Passive]: You may use the 1/Round effect of Stealth '
        'Strike an additional time each Combat Round.',
  ),
  TalentDef(
    name: 'Acrobat Star',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Acrobatics Skill',
    description: 'You are extremely skilled at gymnastics and '
        'acrobatics.\n'
        '(1)-[Passive]: You may use the Flip Maneuver as an Instant '
        'Maneuver.\n'
        '(2)-[Passive]: For the effects of the Flip Maneuver, treat '
        'yourself as if you have +1 Skill Ranks in Acrobatics. This can '
        'allow you to exceed your maximum for the effects of the Flip '
        'Maneuver.\n'
        '(3)-[Triggered, 1/Round, 2/Encounter]: When you use the Flip '
        'Maneuver, instead of moving any number of Squares, you can '
        'stop being Prone.',
  ),
  TalentDef(
    name: 'Expert Pilot',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Pilot Skill',
    description: 'You are a trained pilot, skilled in the use of '
        'Vehicles and Battle Jackets.\n'
        '(1)-[Passive]: For the effects of this Talent, the 5th Skill '
        'Rank in Piloting is treated as 2 Skill Ranks.\n'
        '(2)-[Passive]: Increase all of your Dodge Rolls made with a '
        'Vehicle by 1(T) for every 2 Skill Ranks of Piloting gained.\n'
        '(3)-[Passive]: Ignore the Battle Jacket Penalty.\n'
        '(4)-[1/Round]: Use the Ride Maneuver as an Instant Maneuver.\n'
        '(5)-[Triggered, 1/Round]: If you would make a Combat Roll '
        'while Piloting a Battle Jacket, you may increase the Dice '
        'Score by 1(T) for every 2 Skill Ranks of Piloting you '
        'possess.',
  ),
  TalentDef(
    name: 'Yoink',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Thievery Skill',
    description: 'You know how to slyly take anything unattended, '
        'startling foes.\n'
        '(1)-[Passive]: When using the Snatch Maneuver, you can also '
        'take Weapons possessed by another Character that they have '
        'not currently equipped.\n'
        '(2)-[Triggered, 1/Round]: If you successfully use the Snatch '
        'Maneuver to take an Item from another Character, you can give '
        'them a Grenade you possess. That Grenade will explode at the '
        'start of their next turn, as if you threw it at them through '
        'the Throw Maneuver.\n'
        '(3)-[Triggered, 1/Round]: If you successfully use the Snatch '
        'Maneuver to take an Item from another Character, they gain '
        'the Guard Down Combat Condition against your next Attacking '
        'Maneuver against them during this turn.',
  ),
  TalentDef(
    name: 'Battlefield Doctor',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Medicine Skill',
    description: 'You are adept in medicine, allowing you to easily '
        'treat any maladies.\n'
        '(1)-[Triggered]: Upon using the Treatment Maneuver, you can '
        'target yourself instead of an Ally within your Melee Range.\n'
        '(2)-[Triggered, 1/Round]: When you use the Treatment Maneuver, '
        'you may remove a Combat Condition from the target (except '
        'Suffocating, Pinned, or Transfigured).',
  ),
  TalentDef(
    name: 'Enhanced Search',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Clairvoyance Skill and/or '
        'Perception Skill',
    description: 'Whether through advanced ki sensory techniques or '
        'highly refined senses, nothing escapes your notice.\n'
        '(1)-[Passive]: When making a Clairvoyance or Perception Skill '
        'Check/Clash, you may use the higher Skill Bonus between the '
        'two Skills.\n'
        '(2)-[Triggered]: If you win the Skill Clash for the Sense '
        'Maneuver, you become aware of their Alignment.\n'
        '(3)-[Passive]: Your Perception Skill Checks are unaffected by '
        'the Light Level.\n'
        '(4)-[Passive]: You may ignore the effects of the Blinded '
        'Combat Condition and the Obscured Environmental Quality.\n'
        '(5)-[Triggered/Start of Turn, Ruling, 1/Round]: Target a '
        'Character. Make a Clash (Perception/Clairvoyance vs '
        'Stealth/Concealment) against that Character. If you win, that '
        'Character becomes ‘Marked’ until the start of your next turn. '
        'Increase your Strike and Dodge Rolls against a ‘Marked’ '
        'Character by 1(T) and a ‘Marked’ Character cannot become '
        'Hidden from you.',
  ),
  TalentDef(
    name: 'Terrifying Presence',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in the Intimidation Skill',
    description: 'Your ability to inspire fear in your enemies is truly '
        'astounding.\n'
        '(1)-[Passive]: When you use the Terrify Maneuver, you can '
        'target all Opponents within a Sphere AoE centered on you, or '
        'target a single Opponent up to 8 Squares away from you.\n'
        '(2)-[Triggered, 1/Round]: If you knock an Opponent through a '
        'Health Threshold, you may use the Terrify Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Terrifying Speed',
    category: TalentCategory.skill,
    prerequisitesText: 'Agility Score of 6+, 2+ Skill Ranks in '
        'Intimidate',
    description: 'You move so fast that lesser warriors cower in your '
        'presence.\n'
        '(1)-[Passive]: Increase the Dice Score of your Intimidation '
        'Checks by 2 if you have used the Movement Maneuver during '
        'this Combat Round.\n'
        '(2)-[Triggered, 1/Round]: If you use the Rapid Movement effect '
        'of the Movement Maneuver and end your Movement on an adjacent '
        'Square to an Opponent, you may use the Terrify Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Desperate Distraction',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Bluff and 2+ Skill Ranks in '
        'Intuition',
    description: 'You can read your opponents and skillfully deceive '
        'them into creating an opening for you to fight back!\n'
        '(1)-[Passive]: You gain access to the Dirty Trick Maneuver.\n'
        '(2)-[1/Round]: If you are below the Injured Health Threshold, '
        'you may use the Dirty Trick Maneuver as an Instant Maneuver.',
  ),
  TalentDef(
    name: 'Last Ditch Effort',
    category: TalentCategory.skill,
    prerequisitesText: 'Desperate Distraction',
    description: 'You have one last trick up your sleeve for '
        'emergencies, allowing you to stand tall even when your back '
        'is against the wall.\n'
        '(1)-[Passive]: Increase the Natural Result of your Bluff '
        'Skill Checks by 1.\n'
        '(2)-[Triggered, 1/Encounter]: If you win the Clash for the '
        'Dirty Trick Maneuver, after completing that Maneuver, you may '
        'use the Basic Attack Maneuver or Signature Technique Maneuver '
        'as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Survivalist',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Survival',
    description: 'You are skilled at adapting to extreme environmental '
        'conditions.\n'
        '(1)-[Passive]: Reduce the Critical Target for your Survival '
        'Skill Checks by 1.\n'
        '(2)-[Passive]: While you are in a Battle Weather that you are '
        'not suffering the effects of, increase your Defense Value and '
        'Soak Value by 1(T).',
  ),
  TalentDef(
    name: 'Team Survivalist',
    category: TalentCategory.skill,
    prerequisitesText: 'Survivalist',
    description: 'You are skilled enough to protect others from the '
        'effects of harsh environments.\n'
        '(1)-[Passive]: You do not trigger the Exploit Maneuver when '
        'you use the Brace Maneuver.\n'
        '(2)-[Passive]: Your Allies are unaffected by the effects of '
        'any Battle Weather created by you.\n'
        '(3)-[Triggered]: If you use the Brace Maneuver, apply its '
        'effects to all Allies within your Melee Range.',
  ),
  TalentDef(
    name: 'Feint Master',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Bluff',
    description: 'You are most effective when tricking your opponents '
        'into opening their guard for your attacks.\n'
        '(1)-[Passive]: Increase the Strike and Wound Rolls of '
        'Attacking Maneuvers made through the effects of the Feint '
        'Maneuver by 1(T).\n'
        '(2)-[Passive]: You can Ki Wager up to 1/2 of your Maximum '
        'Capacity on Attacking Maneuvers made through the effects of '
        'the Feint Maneuver.\n'
        '(3)-[Triggered, 1/Encounter]: If you target an Opponent with '
        'the Feint Maneuver for the first time in this Combat '
        'Encounter, you may automatically win the initial Clash for the '
        'effects of the Feint Maneuver.',
  ),
  TalentDef(
    name: 'Trickster Magician',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Use Magic',
    description: 'Your expertise with magic allows you to perform '
        'flashy tricks that leave your enemies mystified.\n'
        '(1)-[Triggered]: If you move an Opponent using the Magic '
        'Trick Maneuver to a Square adjacent to an Ally, that Ally may '
        'use the Basic Attack Maneuver as an Out-of-Sequence Maneuver. '
        'If they do, they must target an Opponent you moved through '
        'the effects of the Magic Trick Maneuver this Combat Round.\n'
        '(2)-[Triggered, 1/Encounter]: When using the Magic Trick '
        'maneuver, you may apply up to 3 of its effects at once. For '
        'the first two effects, you only apply the listed Clash once '
        'and use the results of that Clash for both effects.',
  ),
  TalentDef(
    name: 'Frequent Flyer',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Flight',
    description: 'You’ve become extremely accustomed to fighting in '
        'the sky.\n'
        '(1)-[1/Round]: You may use the Soar Maneuver as an Instant '
        'Maneuver.\n'
        '(2)-[Passive]: Double the bonus to your Defense Value from '
        'using the Soar Maneuver.\n'
        '(3)-[1/Encounter]: As an Instant Maneuver, you can stop being '
        'Prone.\n'
        '(4)-[Triggered, 1/Round]: When a Character within your Melee '
        'Range enters a High Environment, you can use the Soar '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Instant Craft',
    category: TalentCategory.skill,
    prerequisitesText: '2+ Skill Ranks in Craft',
    description: 'You can create anything you need with just some duct '
        'tape, chewing gum, and the paper clip in your pocket.\n'
        '(1)-[Passive]: Increase your Scholarship Modifier by 2(T) for '
        'the sake of any Items you crafted.\n'
        '(2)-[1/Round]: Select a Basic Item. Make a Craft Skill Check '
        'against the DC for that Basic Item. If you succeed, create '
        'that Basic Item. It is destroyed at the end of the Combat '
        'Encounter.',
  ),

  // ==================================================== Specialization ===
  TalentDef(
    name: 'Archetype Focus',
    category: TalentCategory.specialization,
    prerequisitesText: 'N/A',
    description: 'You have specialized in a specific type of attack.\n'
        '(1)-[Passive, Ruling]: Upon gaining this Talent, select a '
        'Foundation. This Foundation becomes your ‘Focused '
        'Foundation’. Increase the Wound Roll of all Attacking '
        'Maneuvers made of your Focused Foundation by 1(T).\n'
        '(2)-[Triggered]: If you score a Critical Result on the Strike '
        'Roll or the Wound Roll for an Attacking Maneuver of your '
        'Focused Foundation, regain 2(bT) Ki Points.',
  ),
  TalentDef(
    name: 'Archetype Defense',
    category: TalentCategory.specialization,
    prerequisitesText: 'Archetype Focus',
    description: 'You have turned your offensive specialization towards '
        'defense.\n'
        '(1)-[Passive]: Increase the Strike Rolls of your Focused '
        'Foundation by 1(T).\n'
        '(2)-[Passive]: If your Focused Foundation is not Physical, you '
        'may use it instead of Physical for calculating your Strike '
        'Roll for the Parry option of the Defend Maneuver.\n'
        '(3)-[Passive]: If your Focused Foundation is Physical, you '
        'may use it instead of Energy/Magic for calculating your Wound '
        'Roll for the Power Flare option of the Defend Maneuver.\n'
        '(4)-[1/Encounter]: You may use the Defend Maneuver without '
        'spending a Counter Action.',
  ),
  TalentDef(
    name: 'Precision Kata',
    category: TalentCategory.specialization,
    prerequisitesText: 'Archetype Focus, Insight Score of 5+',
    description: 'Trained to increase your accuracy in your chosen '
        'type of attack, your blows land precisely where you mean for '
        'them to.\n'
        '(1)-[Passive]: Reduce the Critical Target by 1 for your '
        'Strike Rolls for an Attacking Maneuver of your Focused '
        'Foundation.\n'
        '(2)-[Triggered]: If you score a Critical Result on your '
        'Strike Roll for an Attacking Maneuver made with your Focused '
        'Foundation, increase your Wound Roll for that Attacking '
        'Maneuver by 2(T).',
  ),
  TalentDef(
    name: 'Brutal Kata',
    category: TalentCategory.specialization,
    prerequisitesText: 'Archetype Focus, Force or Magic Score of 5+',
    description: 'Your attacks of your chosen type are more powerful.\n'
        '(1)-[Passive]: Reduce the Critical Target by 1 for your Wound '
        'Rolls for an Attacking Maneuver of your Focused Foundation.\n'
        '(2)-[Triggered]: If you score a Critical Result on your Wound '
        'Roll for an Attacking Maneuver made with your Focused '
        'Foundation, increase your Wound Roll for that Attacking '
        'Maneuver by 2(T).',
  ),
  TalentDef(
    name: 'Profile Focus',
    category: TalentCategory.specialization,
    prerequisitesText: 'Precision Kata and/or Brutal Kata',
    description: 'You are especially adept at using a specific type of '
        'attack.\n'
        '(1)-[Passive]: Upon gaining this Talent, select a Profile from '
        'your Focused Foundation. Reduce the Ki Point Cost for '
        'Attacking Maneuvers of the selected Profile by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: When making an Attacking '
        'Maneuver of your chosen Profile, at Attack Declaration, you '
        'may declare that you will score a Critical Result on your '
        'Strike Roll and Wound Roll for that Attacking Maneuver. If you '
        'do, you score a Critical Result on both Combat Rolls '
        'regardless of your Natural Result.',
  ),

  // ============================================================ Starter ===
  TalentDef(
    name: 'Slow Starter',
    category: TalentCategory.starter,
    prerequisitesText: '2+ Skill Ranks in Concealment',
    description: 'You are partial to holding back your true power '
        'until a foe has proven worthy.\n'
        '(1)-[Passive]: Increase the Dice Score of your Clairvoyance '
        'and Concealment Skill Checks by 2.\n'
        '(2)-[Passive]: While you have a stack of Holding Back, reduce '
        'the Ki Point Cost of all Maneuvers by 1(T).\n'
        '(3)-[Triggered/Start of Combat Encounter]: Use the Holding '
        'Back Maneuver as an Out-of-Sequence Maneuver.\n'
        '(4)-[Triggered, 1/Encounter]: If you lose all stacks of '
        'Holding Back, you may apply the effects of Legend Realized '
        'even if you are not in a Transformation.',
  ),
  TalentDef(
    name: 'Warm Up',
    category: TalentCategory.starter,
    prerequisitesText: 'Slow Starter',
    description: 'You are able to slowly limber up and ready yourself '
        'for battle, even as that battle wages on.\n'
        '(1)-[1/Encounter]: While you are Holding Back, as a Standard '
        'Maneuver with an Action Cost of 1 Action, you can ignore the '
        'effects of your Holding Back stacks until the end of your next '
        'turn.\n'
        '(2)-[Triggered, 1/Encounter]: If you lose all stacks of '
        'Holding Back, you may use the Power Up or Transformation '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Reserved Combatant',
    category: TalentCategory.starter,
    prerequisitesText: 'Slow Starter',
    description: 'Your patience in battle is rewarded, and you are '
        'always ready to unleash your full power in an emergency.\n'
        '(1)-[Triggered/Start of Combat Round, Resource]: If you are '
        'Holding Back, gain a stack of Patience (up to 10).\n'
        '(2)-[Automatic, 1/Encounter]: When you lose all stacks of '
        'Holding Back, lose all Patience Stacks and regain x(bT) Ki '
        'Points, where x is equal to 2x the amount of Patience stacks '
        'you lost.\n'
        '(3)-[Triggered, 3/Round]: When you use an Attacking Maneuver, '
        'a Unique Ability, or are targeted by an Attacking '
        'Maneuver/Unique Ability, you can ignore your stacks of Holding '
        'Back for the duration of that Maneuver.',
  ),
  TalentDef(
    name: 'Conserving Strength',
    category: TalentCategory.starter,
    prerequisitesText: 'Reserved Combatant, Tier of Power 4+, access to '
        'a Transformation with a Tier of Power Requirement of 4+',
    description: 'As you patiently raise your power, you can store up '
        'the energy you don’t use to unleash the moment you go all '
        'out.\n'
        '(1)-[Passive]: Increase your maximum number of Patience '
        'Stacks to 15.\n'
        '(2)-[Passive]: The second effect of Reserved Combatant loses '
        'the Automatic Keyword and gains the Triggered Keyword.\n'
        '(3)-[Passive]: You do not need to be Holding Back to gain '
        'Patience Stacks through the first effect of Reserved '
        'Combatant, as long as you are not in a Transformation with a '
        'Tier of Power Requirement of 4+.\n'
        '(4)-[Triggered, 1/Encounter]: When you enter a Transformation '
        'with a Tier of Power Requirement of 4+, lose all Patience '
        'Stacks and regain x(bT) Ki Points, where x is equal to 2x the '
        'amount of Patience stacks you lost.',
  ),
  TalentDef(
    name: 'Jump Start',
    category: TalentCategory.starter,
    prerequisitesText: 'N/A',
    description: 'You seize the initiative in battle, allowing you to '
        'get the jump on your enemies.\n'
        '(1)-[Triggered/Start of Turn, 1/Encounter]: Use the Power Up '
        'Maneuver as an Out-of-Sequence Maneuver.\n'
        '(2)-[Triggered/Start of Combat Round, 1/Encounter]: Take your '
        'Turn immediately, ignoring the current Initiative Order. If '
        'multiple characters apply this effect, they take their turns '
        'in order of highest to lowest Initiative Value.',
  ),
  TalentDef(
    name: 'All-Out Start',
    category: TalentCategory.starter,
    prerequisitesText: 'Jump Start',
    description: 'As soon as you decide to take the fight seriously, '
        'you unleash your full power, holding nothing back.\n'
        '(1)-[Triggered/Start of Turn, 1/Encounter]: Use the '
        'Transformation Maneuver immediately as an Out-of-Sequence '
        'Maneuver.\n'
        '(2)-[Triggered/Start of Combat Encounter]: Increase your Soak '
        'Value and Combat Rolls by 1(bT) for 2 Combat Rounds.',
  ),

  // ======================================================= Super Stack ===
  TalentDef(
    name: 'Muscular Warrior',
    category: TalentCategory.superStack,
    prerequisitesText: 'Force Score of 6+',
    description: 'Your intense training has paid off, allowing you to '
        'effectively wield the massive strength you bear.\n'
        '(1)-[Passive]: Gain 1 Super Stack.\n'
        '(2)-[Passive]: While you are not suffering from any Health '
        'Threshold Penalties, reduce your Muscle Penalty by 1(bT).',
  ),
  TalentDef(
    name: 'Hefty Muscle',
    category: TalentCategory.superStack,
    prerequisitesText: 'Muscular Warrior, Force Score of 8+',
    description: 'Thanks to the incredible bulk you’ve achieved, you '
        'can deal damage to your opponent even when your attacks miss '
        'their mark.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Physical and '
        'Energy Attacks by 1(T). Double this bonus if you possess 3 '
        'Super Stacks.\n'
        '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, '
        'you may declare that it is an Absolute Attack (see — '
        'Attacking).',
  ),
  TalentDef(
    name: 'Herculean Power',
    category: TalentCategory.superStack,
    prerequisitesText: 'Hefty Muscle, Force Score of 12+',
    description: 'Your godly might calls forth a wellspring of power in '
        'your strongest attacks.\n'
        '(1)-[Passive]: If you would use a Signature Technique, apply '
        'the bonus from the first effect of Hefty Muscle twice to that '
        'Attacking Maneuver.\n'
        '(2)-[Passive]: All of your Ultimate Signature Techniques are '
        'Absolute Attacks.',
  ),
  TalentDef(
    name: 'Steel Muscle',
    category: TalentCategory.superStack,
    prerequisitesText: 'Muscular Warrior, Tenacity Score of 8+',
    description: 'Your muscular build serves almost as a layer of '
        'armor, protecting you from attacks.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(T). Double this '
        'bonus if you possess 3 Super Stacks.\n'
        '(2)-[Passive]: While you possess 2+ Super Stacks, increase '
        'your Damage Reduction by 1(T).',
  ),
  TalentDef(
    name: 'Adamantine Muscle',
    category: TalentCategory.superStack,
    prerequisitesText: 'Steel Muscle, Tenacity Score of 12+',
    description: 'Your thick musculature is as solid as steel, '
        'providing additional defense.\n'
        '(1)-[Passive]: Double the increase to your Soak Value from '
        'your Super Stacks while you are below the Injured Health '
        'Threshold.\n'
        '(2)-[Triggered/Defeated]: Use the Basic Attack Maneuver as an '
        'Out-of-Sequence Maneuver. If you do, you can only select a '
        'Profile of the Physical or Energy Foundations. If that '
        'Attacking Maneuver deals Damage to an Opponent, regain Life '
        'Points equal to 1/4 (rounded up) of the Dice Score for that '
        'Attacking Maneuver’s Wound Roll.',
  ),
  TalentDef(
    name: 'Compact Muscle',
    category: TalentCategory.superStack,
    prerequisitesText: 'Muscular Warrior, Agility Score of 8+',
    description: 'Your lean but powerful muscles allow you to benefit '
        'from both high speed and great strength.\n'
        '(1)-[Passive]: While you only possess 1 Super Stack, increase '
        'your Defense Value by 1(T).\n'
        '(2)-[Passive]: While you only possess 1 Super Stack, increase '
        'the Dice Score of your Steadfast Checks by 1.',
  ),
  TalentDef(
    name: 'Flexible Muscle',
    category: TalentCategory.superStack,
    prerequisitesText: 'Compact Muscle, Agility Score of 12+',
    description: 'Dodging, evading, and striking evasive enemies is '
        'easy for you, even with your enhanced musculature.\n'
        '(1)-[Passive]: While you only possess 1 Super Stack, increase '
        'your Strike Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: While you only possess 1 Super '
        'Stack, if you would make a Steadfast Check, you may choose to '
        'automatically succeed at that Steadfast Check.',
  ),

  // ============================================================= Surge ===
  TalentDef(
    name: 'Second Wind',
    category: TalentCategory.surge,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You are able to recover your stamina more quickly '
        'than most.\n'
        '(1)-[Passive]: Increase your Surgency by 1(T).\n'
        '(2)-[Passive]: You may use the Surge Maneuver an additional '
        'time per Combat Encounter.',
    automation: [
      // (1) +1(T) Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Never Surrender',
    category: TalentCategory.surge,
    prerequisitesText: 'Second Wind',
    description: 'Your raw determination keeps you going even on the '
        'brink of death.\n'
        '(1)-[Passive]: Increase your Surgency by 2(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you use a Ki Surge through '
        'the Surge Maneuver while below the Injured Health Threshold, '
        'enter the Superior State until the end of your next turn.',
    automation: [
      // (1) +2(T) Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 2,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TalentDef(
    name: 'Lion’s Heart',
    category: TalentCategory.surge,
    prerequisitesText: 'Never Surrender',
    description: 'You do not give up the fight until your final breath '
        'is drawn.\n'
        '(1)-[Passive]: You may use the Surge Maneuver an additional '
        'time per Combat Encounter.\n'
        '(2)-[Triggered, 1/Encounter]: When you take an amount of '
        'Damage that would reduce your Life Points to 0 or below, you '
        'may use the Surge Maneuver as an Out-of-Sequence Maneuver. If '
        'you do, you must use a Healing Surge.',
  ),
  TalentDef(
    name: 'Lightning Surge',
    category: TalentCategory.surge,
    prerequisitesText: 'Never Surrender, Resilience',
    description: 'When you recover your stamina, your combat '
        'effectiveness rises.\n'
        '(1)-[Triggered, 1/Encounter]: If you use a Healing Surge, you '
        'may increase your Soak Value by 1(T) for the remainder of the '
        'Combat Encounter.\n'
        '(2)-[Triggered, 1/Encounter]: If you use a Ki Surge, you may '
        'increase your Wound Rolls by 1(T) for the remainder of the '
        'Combat Encounter.\n'
        '(3)-[Triggered, 1/Encounter]: If your Life Points would be '
        'increased beyond a Health Threshold you are currently under '
        'after using the effects of a Healing Surge, you may use the '
        'Power Up Maneuver or Transformation Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),

  // ============================================================= Taunt ===
  TalentDef(
    name: 'Mental Warfare',
    category: TalentCategory.taunt,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You are not above breaking a target’s spirit to win a '
        'fight.\n'
        '(1)-[Passive]: Gain access to the Insult Special Maneuver.\n'
        '(2)-[Triggered, 1/Round]: If an Opponent is knocked through a '
        'Health Threshold by an Attacking Maneuver, you may use the '
        'Insult Maneuver (targeting that Opponent) as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Taunt',
    category: TalentCategory.taunt,
    prerequisitesText: 'Mental Warfare, Personality Score of 6+',
    description: 'You are skilled at convincing an opponent to focus '
        'their assault on you.\n'
        '(1)-[Passive]: Gain 1(bT) Damage Reduction against all '
        'Attacking Maneuvers made by Characters with the Compelled '
        'Combat Condition.\n'
        '(2)-[Triggered, 1/Round]: If you win the Morale Clash for the '
        'Insult Maneuver, reduce that target’s Life Points by your '
        'Personality Modifier.',
  ),
  TalentDef(
    name: 'Improved Taunt',
    category: TalentCategory.taunt,
    prerequisitesText: 'Taunt, Personality Score of 8+',
    description: 'Even more skilled, you are capable of drawing all of '
        'your enemies’ attention.\n'
        '(1)-[Passive]: Increase your Dice Score for any Morale Clash '
        'by 1(T).\n'
        '(2)-[Triggered]: When you use the Insult Maneuver, you can '
        'target all Opponents within a Sphere AoE centered on you.',
  ),

  // ========================================================== Teamwork ===
  TalentDef(
    name: 'Flexible Flanker',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You are skilled in surrounding an opponent and '
        'taking them down with your allies.\n'
        '(1)-[Passive]: If an Ally is on a Square adjacent to an '
        'Opponent, increase all of your Strike and Wound Rolls made '
        'against that Opponent by 1(T).',
  ),
  TalentDef(
    name: 'Supporting Defender',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'Able to create openings in your opponents’ attacks, '
        'you provide perfect defensive support for your allies.\n'
        '(1)-[Passive]: If you are on a Square adjacent to an '
        'Opponent, increase all of your Allies’ Dodge Rolls, or Strike '
        'Rolls when using the Parry effect of the Defend Maneuver, '
        'made against that Opponent by 1(T).',
  ),
  TalentDef(
    name: 'Opportunist',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You leap to the ready anytime an opportunity to '
        'injure an enemy presents itself.\n'
        '(1)-[Triggered, 1/Round]: If an Ally knocks an Opponent '
        'through a Health Threshold, you may use the Exploit Maneuver '
        'against that Opponent.\n'
        '(2)-[1/Encounter]: If you would use the Exploit Maneuver due '
        'to the first effect of this Trait, you may do so without '
        'spending a Counter Action.',
  ),
  TalentDef(
    name: 'Power Gifter',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You are adept in sharing your energy with others '
        'with minimal loss of efficiency.\n'
        '(1)-[Passive]: Halve the consumption of your Capacity Rate '
        'through the effects of the Empower Maneuver.\n'
        '(2)-[Triggered, 1/Round]: If you spend 3 Actions on the '
        'Empower Maneuver, your targeted Ally may use the Power Up '
        'Maneuver or Transformation Maneuver as an Out-of-Sequence '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Teamwork',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You are especially skilled in providing tactical '
        'support for your allies in combat.\n'
        '(1)-[Passive]: Double the maximum amount you can Ki Wager '
        'when using the United Attack Maneuver.\n'
        '(2)-[Triggered, 1/Round]: When using the United Attack '
        'Maneuver, increase your targeted Ally’s Strike and Wound '
        'Rolls by 1(T) for that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Synchronized Combatants',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You are truly in sync with another person, allowing '
        'you two to act efficiently as a single unit.\n'
        '(1)-[Ruling]: Choose a Character. If that Character has also '
        'chosen you through this effect, that Character is your '
        'Partner.\n'
        '(2)-[Passive]: While you are on an adjacent Square to your '
        'Partner, and your Partner is your Ally, increase your Combat '
        'Rolls by 1(T).\n'
        '(3)-[1/Encounter]: You may use the Intervene Maneuver without '
        'spending a Counter Action. You can only use this effect if '
        'the targeted Ally is your Partner.',
  ),
  TalentDef(
    name: 'Superior Synchronization',
    category: TalentCategory.teamwork,
    prerequisitesText: 'Synchronized Combatants, Tier of Power 3+',
    description: 'Your synchronicity with your partner is uncanny, to '
        'the point that it almost seems like you can communicate '
        'telepathically.\n'
        '(1)-[Passive]: Reduce the Performance Skill Check for the '
        'Metamoran Fusion Dance to the Expert DC, if the Character you '
        'are attempting to fuse with is your Partner.\n'
        '(2)-[1/Encounter]: If your Partner would use the Power Up or '
        'Transformation Maneuver while within your Melee Range, you '
        'may immediately use the same Maneuver as an Out-of-Sequence '
        'Maneuver.\n'
        '(3)-[1/Encounter]: You may use the United Attack Maneuver '
        'without spending an Action, if your targeted Ally is your '
        'Partner.',
  ),
  TalentDef(
    name: 'Chosen Rival',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'There’s one person in your life you strive to '
        'surpass more than anyone else, and this drive pushes you to '
        'greater heights!\n'
        '(1)-[Ruling]: Choose a Character (except a Minion). If that '
        'Character has also chosen you through this effect, that '
        'Character is your Rival.\n'
        '(2)-[Passive]: If your Rival is an Opponent, increase your '
        'Wound Rolls by 1(T).\n'
        '(3)-[Passive]: If your Rival is an Ally, increase your Soak '
        'Value by 1(T).\n'
        '(4)-[Passive]: While your Rival is your only non-Defeated '
        'Ally in a Combat Encounter, increase your Combat Rolls by '
        '1(T).\n'
        '(5)-[1/Encounter]: If your Rival uses the Power Up or '
        'Transformation Maneuver, you may immediately use the same '
        'Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Eternal Rival',
    category: TalentCategory.teamwork,
    prerequisitesText: 'Chosen Rival, Tier of Power 3+',
    description: 'Your competition with your rival is everlasting, '
        'both of you striving to surpass each other, and only reaching '
        'further and further heights!\n'
        '(1)-[Passive]: While your Rival is in a Combat Encounter, '
        'increase your Stress Bonus by 1.\n'
        '(2)-[Passive]: Double the bonus from the 4th effect of Chosen '
        'Rival.\n'
        '(3)-[Triggered/Start of Combat Round, 1/Encounter]: If you '
        'are adjacent to your Rival, you may request that they also '
        'trigger this effect. If both you and your Rival trigger this '
        'effect, both of you enter the Surging State until the end of '
        'the Combat Round. If you do, you must both select the same '
        'target for the first effect of the Surging State.',
  ),
  TalentDef(
    name: 'Desperate Support',
    category: TalentCategory.teamwork,
    prerequisitesText: 'N/A',
    description: 'You are able to offer assistance to your friends '
        'even when you cannot fight by their side.\n'
        '(1)-[1/Encounter]: While you are Defeated, you may use the '
        'Empower Maneuver (as if you spent 2 Actions), or apply one of '
        'the listed effects of the third effect of Desperate Support '
        'as an Instant Maneuver.\n'
        '(2)-[Triggered/Defeated]: Increase all of your Allies’ Combat '
        'Rolls by 1(bT) until the end of the next Combat Round.\n'
        '(3)-[Triggered, 1/Round]: When you trigger the third effect '
        'of the Spectator State, you can choose to forgo regaining '
        'Life and Ki Points to instead apply one of the following '
        'effects: Go all out! (the targeted Ally may use the Power Up '
        'Maneuver or Transformation Maneuver as an Out-of-Sequence '
        'Maneuver); Hang in there! (the targeted Ally may ignore any '
        'Health Threshold Penalties until the start of your next '
        'turn); Stand strong! (the targeted Ally has their Soak Value '
        'and Damage Reduction increased by 1(bT) until the start of '
        'your next turn); Dance for us. (the targeted Ally has their '
        'Strike and Dodge Rolls increased by 1(bT) until the start of '
        'your next turn); You can do it! (the targeted Ally has their '
        'Stress Bonus increased by 2 until the start of your next '
        'turn).',
  ),

  // ========================================================= Technique ===
  TalentDef(
    name: 'Bag of Tricks',
    category: TalentCategory.technique,
    prerequisitesText: '2+ Skill Ranks in 6+ Skills, access to 4+ '
        'Unique Abilities',
    description: 'You have an arsenal of different techniques at your '
        'disposal, allowing you to rapidly switch between them to '
        'baffle or overwhelm your opponents.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of all Unique '
        'Abilities by 1(T).\n'
        '(2)-[Passive]: If you make a Clash against an Opponent through '
        'the effects of a Unique Ability (this does not apply to '
        'Clashes for any Maneuvers used through a Unique Ability), '
        'increase your Dice Score for that Clash by 1(T). If the Clash '
        'is a Skill Clash, increase your Natural Result by 1 for that '
        'Clash instead.\n'
        '(3)-[Triggered, 1/Round]: If you target an Opponent with a '
        'Unique Ability and win a Clash against them through its '
        'effects (this does not include any Maneuvers used through a '
        'Unique Ability), you may use a Unique Ability that requires '
        'Standard Actions immediately as an Out-of-Sequence Maneuver. '
        'If you do, you still have to pay the Action Cost but the '
        'Action Cost is reduced by 1 (if this reduces it to 0, you do '
        'not have to pay any Actions).',
  ),
  TalentDef(
    name: 'Energy Control',
    category: TalentCategory.technique,
    prerequisitesText: 'Scholarship or Insight Score of 5+',
    description: 'You’ve learned to rein in your ki, fine-tuning your '
        'control.\n'
        '(1)-[Triggered, 1/Round]: When using a Signature Technique or '
        'a Technical Unique Ability, reduce the Ki Point Cost by '
        '2(T).\n'
        '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver '
        'with a qualifying Signature Technique, you may spend 2(T) Ki '
        'Points to apply a rank of the Homing Advantage to that '
        'Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Technique Master',
    category: TalentCategory.technique,
    prerequisitesText: 'Energy Control',
    description: 'Your control of ki has grown stronger, allowing you '
        'to perform amazing feats.\n'
        '(1)-[Passive]: You can use the Signature Technique Maneuver an '
        'additional time per Combat Round, but you cannot use the same '
        'Signature Technique more than once per Combat Round.\n'
        '(2)-[Passive]: The first effect of Energy Control loses its '
        '[1/Round] Keyword.',
  ),
  TalentDef(
    name: 'Favored Technique',
    category: TalentCategory.technique,
    prerequisitesText: 'N/A',
    description: 'You have specialized in a single technique, to the '
        'point that it is associated with your presence on the '
        'battlefield.\n'
        '(1)-[Passive]: When you gain this Talent, select one of your '
        'Signature Techniques. This becomes your Favored Technique. '
        'When you use your Favored Technique through the Signature '
        'Technique Maneuver, it gains an Energy Charge.\n'
        '(2)-[Passive]: When you gain this Talent, select an Advantage '
        'with a Technique Point Cost of 10 or less. Apply that '
        'Advantage to your Favored Technique. If this Signature '
        'Technique is gained by another Character through any effect, '
        'their version of this Signature Technique does not gain this '
        'Advantage.',
  ),
  TalentDef(
    name: 'Flexible Technique',
    category: TalentCategory.technique,
    prerequisitesText: 'Favored Technique',
    description: 'Your ability to manipulate your Favored Technique is '
        'beyond compare.\n'
        '(1)-[Triggered]: When using your Favored Technique, you may '
        'exchange any number of ranks in the Accurate Advantage for '
        'any number of ranks in the Power Shot Advantage, or vice '
        'versa. If your Favored Technique has neither of these '
        'Advantages, you may apply a rank of the Efficiency Advantage '
        'to it instead.\n'
        '(2)-[Triggered, 1/Encounter]: When using your Favored '
        'Technique, you may change its Profile to another Profile '
        'within the same Foundation. If you do, it loses access to any '
        'Advantages or Disadvantages that it no longer qualifies for '
        'and you must recalculate the Ki Point Cost for that Signature '
        'Technique. This Attacking Maneuver is considered a different '
        'Signature Technique for all effects.',
  ),
  TalentDef(
    name: 'Powerful Technique',
    category: TalentCategory.technique,
    prerequisitesText: 'Favored Technique',
    description: 'Your Favored Technique has become truly powerful, '
        'leaving others in awe of its might.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Favored '
        'Technique by 1(T) for each Health Threshold you are below.\n'
        '(2)-[Passive]: If your Favored Technique is an Ultimate '
        'Signature, increase your Wound Roll for that Attacking '
        'Maneuver by 1(T).\n'
        '(3)-[Passive]: Your Favored Technique gains an Advantage '
        'depending on if they are a Super or Ultimate Signature (if '
        'your Favored Technique already possesses that Advantage, '
        'refund any Technique Points spent and reduce the TP Cost of '
        'your Favored Technique accordingly): Super Signature (gains '
        'the Ascended Signature Advantage); Ultimate Signature (gains '
        'the Maximum Charge Advantage).',
  ),
  TalentDef(
    name: 'Unique Technique',
    category: TalentCategory.technique,
    prerequisitesText: 'Favored Technique',
    description: 'You’ve managed to make your special technique even '
        'more unique, creating something truly your own.\n'
        '(1)-[Ruling]: Upon gaining this Talent, select a Profile of '
        'the same Foundation as your Favored Technique. This becomes '
        'known as your ‘Unique Profile’.\n'
        '(2)-[Triggered, 1/Round]: When using your Favored Technique, '
        'you may apply the Multi-Profile Super Profile onto your '
        'Favored Technique. If you do, you must select your Unique '
        'Profile for its effects.',
  ),
  TalentDef(
    name: 'Terrifying Technique',
    category: TalentCategory.technique,
    prerequisitesText: 'Terrifying Presence, Favored Technique',
    description: 'Your terrifying demeanor is displayed even in your '
        'attacks, shaking others to their core when you use your '
        'Favored Technique.\n'
        '(1)-[Passive]: Increase the Wound Rolls of your Signature '
        'Techniques against Characters with the Shaken Combat Condition '
        'by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use the Energy Charge '
        'Maneuver and select your Favored Technique as its declared '
        'Attacking Maneuver, you may use the Terrify Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Quick Learner',
    category: TalentCategory.technique,
    prerequisitesText: 'Scholarship or Personality Score of 4+',
    description: 'You are able to pick up the techniques of others, '
        'just by seeing them in action.\n'
        '(1)-[Triggered, 1/Round, Ruling]: When any Character uses a '
        'Signature Technique, you can declare that it is a ‘Copied '
        'Technique’. You gain access to that Copied Technique for the '
        'duration of this Combat Encounter.\n'
        '(2)-[Automatic]: You can only possess 1 Copied Technique at '
        'any one time, if you attempt to gain an additional Copied '
        'Technique beyond the maximum you can possess, you must choose '
        'to lose access to another Copied Technique you possess.\n'
        '(3)-[Passive]: If a Signature Technique is a Copied Technique, '
        'reduce your Wound Rolls by 2(T) when using that Signature '
        'Technique.\n'
        '(4)-[Triggered]: At the end of the Combat Encounter, you can '
        'pay the TP Cost of any Copied Technique to gain access to it '
        'permanently. If you do, it stops being a Copied Technique.',
  ),
  TalentDef(
    name: 'Perfect Mimicry',
    category: TalentCategory.technique,
    prerequisitesText: 'Quick Learner',
    description: 'Not only can you pick up the principles behind '
        'others’ techniques on the fly, but you can perfectly recreate '
        'them, as if you’d always known them.\n'
        '(1)-[Passive]: Ignore the 3rd effect of Quick Learner.\n'
        '(2)-[Triggered, 1/Encounter]: When you declare a Copied '
        'Technique, you may use the required Maneuver to use that '
        'Copied Technique (as long as it is a Standard Maneuver) as an '
        'Out-of-Sequence Maneuver, but you must use the Copied '
        'Technique you declared. You must still meet any prerequisites '
        'for its use (such as the requisite number of Energy Charge '
        'Maneuvers if your Copied Technique has the Mandatory Charge '
        'Disadvantage).',
  ),
  TalentDef(
    name: 'Copy Index',
    category: TalentCategory.technique,
    prerequisitesText: 'Quick Learner',
    description: 'You are able to quickly learn multiple techniques at '
        'once, and use the techniques copied from one opponent on '
        'another.\n'
        '(1)-[Passive]: You can possess 2 Copied Techniques at any one '
        'time.\n'
        '(2)-[Triggered]: At the end of each Combat Encounter, you may '
        'select one Copied Technique to retain access to until the end '
        'of your next Combat Encounter.',
  ),
  TalentDef(
    name: 'Advanced Learner',
    category: TalentCategory.technique,
    prerequisitesText: 'Quick Learner',
    description: 'Your ability to quickly grasp techniques is '
        'exceptionally versatile, allowing you to learn more types of '
        'techniques.\n'
        '(1)-[Passive]: Reduce the Technique Point Cost of any Copied '
        'Technique that would be gained at the end of a Combat '
        'Encounter by 3.\n'
        '(2)-[Triggered, 1/Encounter]: If a Character uses a Unique '
        'Ability that you meet the Prerequisites of, you may declare '
        'that Unique Ability is a Copied Technique. Gain access to it '
        'until the end of the Combat Encounter.',
  ),
  TalentDef(
    name: 'Technique Armory',
    category: TalentCategory.technique,
    prerequisitesText: 'You have access to 3+ Signature Techniques',
    description: 'Your arsenal of combat techniques is vast and '
        'powerful, granting you a broad array of options for '
        'overcoming any obstacle.\n'
        '(1)-[Passive]: Reduce the initial Technique Point Cost of '
        'Signature Techniques by 4. This effect applies retroactively, '
        'meaning you regain 4 Technique Points for each Signature '
        'Technique you had previously obtained with Technique Points.\n'
        '(2)-[Triggered, Resource]: Each time you use a Super Signature '
        'Technique for the first time in a Combat Encounter, gain 1 '
        'Armory Point. When using an Ultimate Signature Technique, you '
        'may spend any number of Armory Points to increase the Wound '
        'Roll of that Signature Technique by 2(T) for each Armory Point '
        'spent (max. 10(T)).',
  ),

  // ========================================================= Threshold ===
  TalentDef(
    name: 'Vigor',
    category: TalentCategory.threshold,
    prerequisitesText: 'N/A',
    description: 'Your body is conditioned for the harsh realities of '
        'battle.\n'
        '(1)-[Passive]: For each Health Threshold you are below, '
        'increase your Soak Value by 1(bT).\n'
        '(2)-[Passive]: While you are below the Injured Health '
        'Threshold, increase your Strike and Dodge Rolls by 1(bT).',
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.base,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  TalentDef(
    name: 'High Risk Battler',
    category: TalentCategory.threshold,
    prerequisitesText: 'Vigor',
    description: 'Risking life and limb for greater power, you '
        'intentionally throw yourself in harm’s way.\n'
        '(1)-[Passive]: For each Health Threshold you are below, '
        'increase your Wound Rolls by 1(bT).\n'
        '(2)-[Triggered, 1/Round]: If you would regain Life Points '
        'while below the Injured Health Threshold, you may choose to '
        'forgo gaining any Life Points. If you do, regain Ki Points '
        'equal to 1/2 of the amount of Life Points you would have '
        'gained.',
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.base,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  TalentDef(
    name: 'Battle at the Edge',
    category: TalentCategory.threshold,
    prerequisitesText: 'High Risk Battler',
    description: 'Living dangerously is your motto; you are at your '
        'fiercest when you are close to death.\n'
        '(1)-[Passive]: While you are below the Critical Health '
        'Threshold, increase your Combat Rolls and Soak Value by '
        '1(bT).\n'
        '(2)-[Triggered/Defeated]: Roll a 1d10. If you score a result '
        'of 7 or higher, set your Life Points to 1 lower than the '
        'Critical Health Threshold.',
  ),
  TalentDef(
    name: 'Diehard',
    category: TalentCategory.threshold,
    prerequisitesText: 'N/A',
    description: 'Your ability to shrug off injury is remarkable.\n'
        '(1)-[Passive]: Increase your Maximum Life Points by 2 for '
        'each of your Power Levels.\n'
        '(2)-[Passive]: Increase the Dice Score of your Steadfast '
        'Checks by 1.',
  ),
  TalentDef(
    name: 'Fortitude',
    category: TalentCategory.threshold,
    prerequisitesText: 'Diehard',
    description: 'You are nearly unstoppable, continuing to fight well '
        'past when others would have dropped.\n'
        '(1)-[Passive]: Increase your Maximum Life Points by 2 for '
        'each of your Power Levels.\n'
        '(2)-[Triggered, 1/Encounter]: If you fail a Steadfast Check, '
        'you may reroll that Steadfast Check, but you must take the '
        'second result.',
  ),
  TalentDef(
    name: 'Steadfast Warrior',
    category: TalentCategory.threshold,
    prerequisitesText: 'Fortitude, ToP3+',
    description: 'You are an absolute unit, an unstoppable force that '
        'keeps barreling towards your enemies regardless of the damage '
        'they deal to you.\n'
        '(1)-[Passive]: Increase your Maximum Life Points by 2 for '
        'each of your Power Levels.\n'
        '(2)-[Passive]: When rolling a Steadfast Check, roll your Base '
        'Die twice and take the highest result.',
  ),
  TalentDef(
    name: 'Undying Determination',
    category: TalentCategory.threshold,
    prerequisitesText: 'Tier of Power 4+, 3+ Threshold Talents',
    description: 'Refusing to go down without a fight, you exhibit a '
        'final burst of power when you reach the end of your rope.\n'
        '(1)-[Triggered, 1/Encounter]: While below the Injured Health '
        'Threshold, if you receive Damage from an Attacking Maneuver '
        'that exceeds your remaining Life Points, halve that Damage.\n'
        '(2)-[Triggered/Defeated]: Set your Life Points to 1 higher '
        'than their minimum value. Then, until the end of your next '
        'turn, your Life Points cannot be reduced below that value and '
        'you may ignore all Health Threshold penalties.\n'
        '(3)-[Automatic]: If you trigger the second effect of Undying '
        'Determination, at the end of your next turn, your Life Points '
        'are reduced to their lowest possible value and you are '
        'Defeated.',
  ),
  TalentDef(
    name: 'Pain Resistant',
    category: TalentCategory.threshold,
    prerequisitesText: '2+ Threshold Talents',
    description: 'You are well-accustomed to pain, and you show no '
        'visible signs of your discomfort.\n'
        '(1)-[Triggered, 1/Round]: If you receive Damage from an '
        'Opponent’s Attacking Maneuver, increase your Soak Value and '
        'Damage Reduction by 1(bT) until the end of the Combat Round.\n'
        '(2)-[Triggered, 1/Round, 2/Encounter]: If an Opponent knocks '
        'you through a Health Threshold, that Opponent does not gain '
        'Bonus Momentum, and they cannot trigger any of their effects '
        'that trigger when you are knocked through a Health Threshold.',
  ),
  TalentDef(
    name: 'Steady Momentum',
    category: TalentCategory.threshold,
    prerequisitesText: '3+ Threshold Talents',
    description: 'You thrive on the give and take of battle- so much '
        'so that taking damage actually fuels your drive to win.\n'
        '(1)-[Passive]: Increase your Wound Rolls and Soak Value by '
        '1(bT) while your Life Points are below the Bruised Health '
        'Threshold and you are not suffering from any Health Threshold '
        'Penalties.\n'
        '(2)-[Triggered/Threshold]: If you succeed at the Steadfast '
        'Check for this Health Threshold, gain 1 Action. Any Actions '
        'gained by this effect remain until the end of your turn or '
        'the end of the Combat Round (whichever happens last).',
  ),

  // ===================================================== Transformation ===
  TalentDef(
    name: 'Blinding Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 8+, Tier of Power 3+',
    description: 'You’ve learned to transform in a way that can leave '
        'those witnessing it blinded.\n'
        '(1)-[Triggered, 1/Round]: If you enter a Transformation '
        'through the Transformation Maneuver, you may immediately use '
        'the Power Up Maneuver as an Out-of-Sequence Maneuver.\n'
        '(2)-[Triggered, 1/Encounter]: When you use the Transformation '
        'Maneuver to enter a Form or Enhancement, you may spend 1 '
        'Action. If you do, make a Clash (Impulsive) against all '
        'Opponents within a Destructive Sphere AoE (centered on you). '
        'If you win, they suffer from the Blinded Combat Condition '
        'until the end of their next turn. If that Opponent would be '
        'in Cover if this was an Attacking Maneuver, that Opponent '
        'automatically wins this Clash.',
  ),
  TalentDef(
    name: 'Bursting Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score 4+',
    description: 'The sheer force expelled when you transform destroys '
        'your clothing.\n'
        '(1)-[Passive]: While in a Form and/or Enhancement while '
        'wearing no pieces of Apparel, increase your Dodge Rolls and '
        'Soak Value by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you destroy a piece of Apparel '
        'through the effects of the Bursting Aspect, you may use the '
        'Power Up Maneuver as an Out-of-Sequence Maneuver then regain '
        'Life and Ki Points equal to your Power Level.\n'
        '(3)-[Triggered, 1/Encounter]: When entering a Transformation '
        'through the Transformation Maneuver, you may give that '
        'Transformation the Bursting Aspect until you leave it.',
  ),
  TalentDef(
    name: 'Desperate Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score 4+',
    description: 'You are capable of maintaining a Transformation, no '
        'matter the cost.\n'
        '(1)-[Passive]: While below the Injured Health Threshold, '
        'increase your Stress Bonus by 1.\n'
        '(2)-[Triggered, 1/Encounter]: After rolling for your Stress '
        'Test, if you’ve failed, you can halve your Life Points. If '
        'you do, increase your Dice Score by 1 for every Health '
        'Threshold you are below after halving your Life Points – this '
        'can retroactively allow you to succeed a failed Stress Test. '
        'If you would fall through a Health Threshold through the '
        'effects of Desperate Transformation, you automatically '
        'succeed the Steadfast Check for that Health Threshold and you '
        'may ignore the effects of Reduced Momentum.',
  ),
  TalentDef(
    name: 'Enhanced Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 8+, Tier of Power 3+',
    description: 'By concentrating your energy, you are able to push '
        'more power into your transformation.\n'
        '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
        '(2)-[Triggered, 1/Encounter]: If you would use the '
        'Transformation Maneuver to try and enter a Form, you may '
        'spend an additional 2 Actions. If you do, increase the Stress '
        'Test Requirement and Attribute Modifier Bonus (FO/MA) for '
        'that Form by 2 and 2(T) respectively until you fail to enter '
        'that Transformation or leave that Transformation.',
  ),
  TalentDef(
    name: 'Forceful Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 4+',
    description: 'When you transform, your powerful aura knocks '
        'opponents away from you.\n'
        '(1)-[Passive]: While in an Enhancement or Form, increase your '
        'Might by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you enter a Transformation '
        'through the Transformation Maneuver, you may make a Might '
        'Clash against all Opponents within a Large Sphere AoE '
        '(centered on you). If you win, reduce their Life Points by '
        'your Might and move the target(s) a number of Squares in a '
        'straight line away from you equal to your Might.',
  ),
  TalentDef(
    name: 'Under Pressure',
    category: TalentCategory.transformation,
    prerequisitesText: 'Desperate Transformation',
    description: 'Even transforming while injured doesn’t hold you '
        'back.\n'
        '(1)-[Passive]: Do not reduce your Stress Bonus from any '
        'Health Threshold Penalties.\n'
        '(2)-[Triggered, 1/Encounter]: When you enter a Transformation '
        'through the Transformation Maneuver while you’re below the '
        'Injured Health Threshold, you may either: if this '
        'Transformation is a Form, double the Life/Ki Points regained '
        'through this instance of Legend Realized; if this '
        'Transformation is an Enhancement, apply Legend Realized; or '
        'use the Power Up Maneuver as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Specialized Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 8+, Tier of Power 3+',
    description: 'You have adapted especially to maintaining a '
        'specific Transformation.\n'
        '(1)-[Ruling]: When you gain this Talent, select one '
        'Transformation or Transformation Line to be your ‘Specialized '
        'Transformation’.\n'
        '(2)-[Passive]: When making a Stress Test to enter your '
        'Specialized Transformation, or while in your Specialized '
        'Transformation, roll twice and take the highest result.\n'
        '(3)-[Triggered, 1/Encounter]: When you use the Transformation '
        'Maneuver to enter a Transformation that can be used in '
        'conjunction with your Specialized Transformation, you can use '
        'the Transformation Maneuver again as an Out-of-Sequence '
        'Maneuver to enter your Specialized Transformation (if it does '
        'not have any levels of Long Transformation).',
  ),
  TalentDef(
    name: 'Inspiring Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 4+, access to a Form',
    description: 'The sight of your Transformation fills your Allies '
        'with confidence.\n'
        '(1)-[Passive]: While you are in a Form, adjacent Allies have '
        'their Wound Rolls increased by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: When you Transform into a Form '
        'through the Transformation Maneuver, roll your Legend '
        'Realized, but you do not gain any Life or Ki Points. Instead, '
        'all of your Allies within a Sphere AoE (centered on you) '
        'regain Life and Ki Points equal to 1/2 of your Legend '
        'Realized Dice Score.',
  ),
  TalentDef(
    name: 'Overwhelming Transformation',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 4+, access to a Form',
    description: 'The menacing presence of your Transformation fills '
        'your enemies with dread.\n'
        '(1)-[Passive]: While you are in a Form, adjacent Opponents '
        'have their Soak Value reduced by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: When you Transform into a Form '
        'through the Transformation Maneuver, roll your Legend '
        'Realized, but you do not gain any Life or Ki Points. Instead, '
        'all of your Opponents within a Sphere AoE centered on you '
        'reduce their Life Points by an amount equal to 1/2 of your '
        'Legend Realized Dice Score.',
  ),
  TalentDef(
    name: 'Powerful Heartbeat',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 4+, access to a Form with '
        '2+ Stages',
    description: 'You are more capable than others of quickly tapping '
        'into the power of your stronger forms.\n'
        '(1)-[Passive]: While in a Form with higher Stages (including '
        'Evolved Stages), you may treat those Stages as if they have +1 '
        'level of the Heartbeat Aspect.\n'
        '(2)-[Passive]: Treat your Stress Bonus as if it was 1 higher '
        'for calculating if you can use the effects of the Heartbeat '
        'Aspect.\n'
        '(3)-[Triggered, 1/Encounter]: If you enter a Transformation '
        'through the Heartbeat Aspect during one of your Attacking '
        'Maneuvers, you may apply an Energy Charge to that Attacking '
        'Maneuver.',
  ),
  TalentDef(
    name: 'Relax to Recover',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score of 4+',
    description: 'You specialize in the maximization of your base '
        'capabilities, rather than your transformed state.\n'
        '(1)-[Passive]: While in your Normal State, increase your '
        'Surgency by 1(T).\n'
        '(2)-[1/Round]: You may use the Revert Maneuver as an Instant '
        'Maneuver.\n'
        '(3)-[Triggered, 1/Encounter]: If you use the Revert Maneuver '
        'to leave all of your active Forms/Enhancements, you may use a '
        'Surge of your choice as an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Self Control',
    category: TalentCategory.transformation,
    prerequisitesText: 'Personality Score 4+',
    description: 'You have the ability to maintain some presence of '
        'mind, even under the intense pressure of your Transformation.\n'
        '(1)-[Passive]: While in a Transformation that has lost the '
        'Rampaging Aspect due to Mastery or an Acclimated effect, '
        'increase your Soak Value and Wound Rolls by 1(T).\n'
        '(2)-[Triggered/Start of Turn]: If you are in a Transformation '
        'with the Rampaging Aspect, roll a 1d10 and reduce the Dice '
        'Score by the level of the Rampaging Aspect. If your Dice '
        'Score is 7+, ignore the effects of Rampaging until the start '
        'of your next turn.',
  ),

  // ============================================================ Weapon ===
  TalentDef(
    name: 'Weapon Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'N/A',
    description: 'You are especially skilled with a Weapon.\n'
        '(1)-[Passive]: Ignore the Weapon Penalty.\n'
        '(2)-[Passive]: Increase your Dice Score for a Clash made '
        'through the Disarm Maneuver by 1(bT).',
  ),
  TalentDef(
    name: 'Category Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: '2+ Weapon Talents',
    description: 'You are extraordinarily adept in the use of a '
        'particular type of weapon.\n'
        '(1)-[Ruling]: Select a Weapon Category. That Weapon Category '
        'becomes known as your Preferred Category.\n'
        '(2)-[Passive]: Increase your Strike Rolls with your Preferred '
        'Category by 1(T).\n'
        '(3)-[Triggered, 1/Round]: When making an Attacking Maneuver '
        'with a Weapon of your Preferred Category, you may increase '
        'your Wound Roll for that Attacking Maneuver by 1(T) for each '
        'Weapon Talent you possess (maximum 4(T)).',
  ),
  TalentDef(
    name: 'Dueling Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'You are proficient with using a Weapon for defense '
        'as well as offense.\n'
        '(1)-[Passive]: While you are only wielding a single Weapon of '
        'the Standard Size, increase your Wound Rolls with Armed '
        'Attacks made with it by 1(T).\n'
        '(2)-[Triggered, 1/Round]: While the only Weapon you have '
        'equipped is a Standard Size Weapon and you make an Attacking '
        'Maneuver or use the Parry effect of the Defend Maneuver, you '
        'can increase your Strike Rolls by 2(T) for the duration of '
        'that Maneuver.',
  ),
  TalentDef(
    name: 'Light Weapons Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'You are extremely skilled at wielding lighter '
        'weapons to their fullest.\n'
        '(1)-[Passive]: While you are only wielding a single Weapon of '
        'the Small Size, increase your Wound Rolls by 2(T).\n'
        '(2)-[Triggered, 1/Round]: When you use the Basic Attack '
        'Maneuver to make an Armed Attack with a Small Size Weapon, '
        'spend 4(bT) Ki Points to make that Attacking Maneuver a '
        'Called Shot without spending an Action.',
  ),
  TalentDef(
    name: 'Heavy Weapons Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'You are especially adept in wielding large Weapons '
        'to great effect.\n'
        '(1)-[Passive]: While you are only wielding a single Weapon of '
        'the Big Size, increase your Strike Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Round]: When you make an Attacking Maneuver '
        'with a Big Size Weapon, reduce the Weapon’s Life Points by '
        '1/10 their Maximum to increase the Wound Roll by the '
        'reduction.',
  ),
  TalentDef(
    name: 'Iaijutsu Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'Trained in a particular style of combat, you keep '
        'your Weapon in its sheathe until the exact moment you want to '
        'strike.\n'
        '(1)-[Passive]: While you are not wielding any Weapon, '
        'increase your Dodge Rolls by 1(T).\n'
        '(2)-[Triggered]: After making an Armed Attack, you may '
        'sheathe the Weapon used as an Out-of-Sequence Maneuver.\n'
        '(3)-[Triggered, 1/Round, 3/Encounter]: If you Unsheathe a '
        'Standard Size Weapon, making it the only Weapon you have '
        'equipped, you can make a Basic Attack Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Dual Wielding Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'Adapted to wielding two Weapons simultaneously, you '
        'can press the advantage more easily while using one Weapon to '
        'defend.\n'
        '(1)-[Passive]: While you are wielding 2+ Weapons, increase '
        'your Strike Rolls by 1(T).\n'
        '(2)-[1/Round]: While you are wielding 2+ Weapons, you can '
        'either: use the Parry effect of the Defend Maneuver without '
        'spending a Counter Action; or, when making an Armed Attack, '
        'increase the Wound Roll by 1/2 of your Might.',
  ),
  TalentDef(
    name: 'Twin Weapon Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Dual Wielding Specialist',
    description: 'Wielding matching Weapons together with terrifying '
        'precision, you maximize your offensive ability.\n'
        '(1)-[Passive]: While you are wielding 2+ Weapons of the same '
        'Weapon Category, increase your Wound Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you make an Attacking Maneuver '
        'after having made 2+ Attacking Maneuvers with 2+ different '
        'Weapons of the same Weapon Category during this Combat Round, '
        'increase the Wound Roll of that Attacking Maneuver by 2(T).\n'
        '(3)-[Triggered, 1/Encounter]: If you trigger the second '
        'effect of Twin Weapon Specialist, or use an Ultimate '
        'Signature Technique that has the Weapon Assisted Advantage '
        'while wielding 2+ Weapons of the same Weapon Category, you '
        'may apply an Energy Charge to that Attacking Maneuver.',
  ),
  TalentDef(
    name: 'Critical Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'Focusing on targeting an opponent’s vitals, you '
        'attempt to finish your opponents swiftly.\n'
        '(1)-[Passive]: Decrease the Critical Target of your Strike '
        'Rolls when making an Armed Attack by 1.\n'
        '(2)-[Triggered, 1/Round]: If you score a Critical Result on '
        'your Strike Roll for an Armed Attack, increase the Wound Roll '
        'of that Attacking Maneuver by 2(T).\n'
        '(3)-[Triggered, 1/Encounter]: If you score a Critical Result '
        'on the Strike Roll for an Armed Attack, increase the Damage '
        'Category of that Attacking Maneuver by 1 Category.',
  ),
  TalentDef(
    name: 'Variety Specialist',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'Constantly switching your Weapon, your tactics leave '
        'your enemies guessing.\n'
        '(1)-[Passive]: All of your Weapons gain 1 additional Quality '
        'Slot.\n'
        '(2)-[Triggered, 1/Encounter]: If you use the Disarm Maneuver '
        'and win the Clash for its effects, you may equip the removed '
        'Weapon as an Out-of-Sequence Maneuver.\n'
        '(3)-[Triggered, 1/Round, 3/Encounter]: If you equip a Weapon, '
        'you may use the Basic Attack Maneuver as an Out-of-Sequence '
        'Maneuver. You can only apply this effect to each Weapon once '
        'per Combat Encounter.',
  ),
  TalentDef(
    name: 'Weapon Fixer',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'You are able to repair your weapon mid-fight, using '
        'your ki.\n'
        '(1)-[Triggered/Start of Turn]: If you have a Weapon, you can '
        'spend any number of Ki Points to have that Weapon regain Life '
        'Points equal to 2x the amount of Ki Points spent. If that '
        'Weapon was destroyed, it stops being destroyed until the end '
        'of the Combat Encounter.\n'
        '(2)-[Triggered, 1/Encounter]: If you use the first effect of '
        'Weapon Fixer to fix a destroyed Weapon, increase your Wound '
        'Rolls with that Weapon by 2(T) for the remainder of the '
        'Combat Encounter.',
  ),
  TalentDef(
    name: 'Weapon Master',
    category: TalentCategory.weapon,
    prerequisitesText: '2+ Weapon Talents',
    description: 'Your Weapon Attacks are able to conduct your ki, '
        'dealing more damage when you land them successfully.\n'
        '(1)-[Passive]: Increase the Dice Category of your Energy '
        'Charges by 1 Category for your Armed Attacks.\n'
        '(2)-[Triggered, 1/Round, 3/Encounter]: If you deal Damage to '
        'an Opponent with an Armed Attack, you may use the Basic '
        'Attack Maneuver as an Out-of-Sequence Maneuver. If you do, '
        'that Attacking Maneuver must be an Armed Attack.',
  ),
  TalentDef(
    name: 'Variable Fighter',
    category: TalentCategory.weapon,
    prerequisitesText: 'Weapon Specialist',
    description: 'You are skilled in the use of both Weapons and your '
        'fists or ki, and employ a style which utilizes both.\n'
        '(1)-[Passive]: While you are wielding a Weapon, increase the '
        'Strike Rolls of your Unarmed Attacks by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you hit an Opponent with an '
        'Unarmed Attack or an Armed Attack, increase the Wound Rolls '
        'of the other by 1(T) until the start of your next turn.',
  ),
  TalentDef(
    name: 'Variable Champion',
    category: TalentCategory.weapon,
    prerequisitesText: 'Variable Fighter, ToP3+',
    description: 'Your fighting style has evolved, allowing you to '
        'seamlessly combine your Armed and Unarmed Attacks.\n'
        '(1)-[Passive]: While you are only wielding 1 Weapon, increase '
        'the Strike Rolls of your Armed Attacks by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you hit the Opponent with an '
        'Armed Attack or an Unarmed Attack, use the Basic Attack '
        'Maneuver or Signature Technique Maneuver as an '
        'Out-of-Sequence Maneuver. If you do, that Attacking Maneuver '
        'must be Armed (if you used an Unarmed Attack) or Unarmed (if '
        'you used an Armed Attack) and it gains an Energy Charge.',
  ),

  // ===================================================== Miscellaneous ===
  TalentDef(
    name: 'Concentrated Energy',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Force or Magic Score of 6+',
    description: 'You are able to focus your energy more precisely, '
        'wasting less of it when you attack.\n'
        '(1)-[Triggered, Resource]: If you use the Energy Charge '
        'Maneuver, gain a stack of Concentrated Ki (max. 10).\n'
        '(2)-[Passive]: Increase your Wound Rolls by 1(bT) for every 2 '
        'stacks of Concentrated Ki you possess.\n'
        '(3)-[Triggered]: If you would use the Power Flare option of '
        'the Defend Maneuver, double the bonus from the second effect '
        'of Concentrated Energy for the duration of that Maneuver.\n'
        '(4)-[Automatic]: Lose all stacks of Concentrated Ki after '
        'concluding the Attacking Maneuver declared by the Energy '
        'Charge Maneuver, or if you use either the Cancel Energy '
        'Charge effect of the No Effort Maneuver or Energy Cancel '
        'Counter Maneuver.',
  ),
  TalentDef(
    name: 'Experienced Drunk',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Insight Score of 6+',
    description: 'Your body is used to the drunken stupor you spend '
        'most of your time in, allowing you to function almost '
        'normally even while inebriated.\n'
        '(1)-[Passive]: While in the Drunk State, increase the Dice '
        'Category of your Extra Dice gained from scoring a Critical '
        'Result by 1 Category. Double this bonus if your base Tier of '
        'Power is 4+.\n'
        '(2)-[Triggered, 2/Round]: When making a Dodge Roll while in '
        'the Drunk State, you may increase or reduce the Natural '
        'Result by 1 after seeing the result. This can allow you to '
        'score a Critical Result or a Botch Result.\n'
        '(3)-[Triggered/Start of Turn]: You may use the Sake Bottle as '
        'an Out-of-Sequence Maneuver.\n'
        '(4)-[Triggered/Start of Combat Encounter]: If you are not a '
        'Minion, gain a Sake Bottle, or if you already possess one, '
        'you may instead completely refill that Sake Bottle.',
  ),
  TalentDef(
    name: 'Ferocious Fighter',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Insight Score of 6+',
    description: 'Your animal instincts take over, turning you into a '
        'wild animal on the battlefield.\n'
        '(1)-[Passive]: While in the Feral State, increase the Dice '
        'Category of your Extra Dice gained from scoring a Critical '
        'Result by 1 Category. Double this bonus if your base Tier of '
        'Power is 4+.\n'
        '(2)-[Triggered, 2/Round]: When making a Wound Roll while in '
        'the Feral State, you may increase or reduce the Natural '
        'Result by 1 after seeing the result. This can allow you to '
        'score a Critical Result or a Botch Result.\n'
        '(3)-[Triggered/Start of Turn]: Enter the Feral State until the '
        'start of your next turn.\n'
        '(4)-[1/Encounter]: While in the Feral State, you may use the '
        'Signature Technique Maneuver, ignoring the 1st effect of the '
        'Wild level of the Feral State.',
  ),
  TalentDef(
    name: 'Furious Flex',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You are able to push your body to the limits to '
        'increase your damage, at the cost of destroying your outfit '
        'over time.\n'
        '(1)-[Passive]: If you are not wearing any pieces of Apparel '
        'and at least 1 of your pieces of Apparel have been destroyed '
        'this Combat Encounter, increase your Combat Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Encounter]: If you hit an Opponent with an '
        'Attacking Maneuver, you may destroy your Top Layer of Apparel '
        'to increase the Wound Roll by 2x the Apparel Bonus of that '
        'piece of Apparel.',
  ),
  TalentDef(
    name: 'Lucky',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You are able to succeed even when the odds are not '
        'in your favor.\n'
        '(1)-[1/Round]: You can re-roll any d10 rolled by you after '
        'seeing the result.\n'
        '(2)-[Passive]: If you are not a Minion, you may also re-roll '
        'any d10 rolled by an Ally through the 1st effect of Lucky.\n'
        '(3)-[Triggered, 1/Encounter]: If you score a Botch Result, '
        'score a Critical Result instead and increase the Natural '
        'Result by 3.',
  ),
  TalentDef(
    name: 'Naturist',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You are most often fighting in as little clothing as '
        'possible, while preserving your modesty.\n'
        '(1)-[Passive]: While you are not wearing any pieces of '
        'Apparel, increase your Defense Value and Soak Value by '
        '1(bT).\n'
        '(2)-[Passive]: You cannot willingly equip any piece of '
        'Apparel during a Combat Encounter.',
  ),
  TalentDef(
    name: 'Au Naturel',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Naturist, Tier of Power 3+',
    description: 'You prefer to let your natural form show, using your '
        'toughened skin for defense.\n'
        '(1)-[Passive]: Double the benefits from the first effect of '
        'Naturist.\n'
        '(2)-[Passive]: While you are not wearing any pieces of '
        'Apparel, increase your Wound Rolls by 1(bT).',
  ),
  TalentDef(
    name: 'Superhuman Physique',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Au Naturel, Tier of Power 4+',
    description: 'Your musclebound form renders defensive gear '
        'superfluous.\n'
        '(1)-[Passive]: While you are not wearing any piece of '
        'Apparel, increase your Stress Bonus by 1 and your Damage '
        'Reduction by 2(bT).',
  ),
  TalentDef(
    name: 'God-like Physique',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Superhuman Physique, Tier of Power 5+',
    description: 'So powerful is your natural form that it rivals '
        'divine artifacts in defensive capacity.\n'
        '(1)-[Passive]: Increase your Maximum Life Points by 2 for '
        'each Power Level reached.\n'
        '(2)-[Passive]: While you are not wearing any piece of '
        'Apparel, increase your Combat Rolls by 1(bT).',
  ),
  TalentDef(
    name: 'Snack Fiend',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You always have a snack on you, hidden away. No one, '
        'sometimes not even you, knows it’s there before you need it.\n'
        '(1)-[Triggered/Start of Combat Encounter]: If you are not a '
        'Minion, gain a Snack Basic Item.\n'
        '(2)-[Triggered, 1/Encounter]: After using the Snack Basic '
        'Item, enter the Superior State until the end of your turn.',
  ),
  TalentDef(
    name: 'Swaggering Wager',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'Personality Score of 4+',
    description: 'Your overwhelming power is more than enough to win, '
        'so why not prove your superiority? That’s your philosophy.\n'
        '(1)-[Triggered/Start of Turn]: Select up to 3 of the effects '
        'below, they apply until the start of your next turn: Limb '
        'Restriction (reduce all of your Combat Rolls by 2(bT)); Lazy '
        'Fighting (gain the Slowed Combat Condition); Zero Effort (you '
        'cannot Ki Wager or use any Signature Techniques).\n'
        '(2)-[Triggered, Resource]: When any number of effects chosen '
        'through the first effect of Swaggering Wager end, if you have '
        'used at least 1 Attacking Maneuver since the start of your '
        'previous turn, gain a number of Swagger Stacks equal to the '
        'number of effects that ended.\n'
        '(3)-[1/Round]: As an Instant Maneuver, you can spend a number '
        'of Swagger Stacks to gain the effects listed below: 1-3 '
        'Swagger (for each Swagger spent, increase one Combat Roll of '
        'your choice by 1(T) until the start of your next turn – this '
        'effect cannot stack, but you can apply it multiple times to '
        'increase multiple Combat Rolls); 2 Swagger (gain 1 Counter '
        'Action); 3 Swagger (use the Basic Attack Maneuver as an '
        'Out-of-Sequence Maneuver); 4 Swagger (if you are not a '
        'Minion, gain 1 Action).',
  ),
  TalentDef(
    name: 'Willpower',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'Through sheer determination, you are able to power '
        'through events that would otherwise have an adverse effect on '
        'you.\n'
        '(1)-[Passive]: Choose a Saving Throw, increase the Dice Score '
        'for any Clashes involving that Saving Throw by 1(T).\n'
        '(2)-[Passive]: Roll your Base Die twice for any Saving Throw '
        'and use the highest result.',
  ),
  TalentDef(
    name: 'Practiced Charger',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You have become extremely skilled at gathering '
        'energy into your attacks.\n'
        '(1)-[Passive]: Reduce the Ki Point Cost of the Energy Charge '
        'Maneuver to 1(bT).\n'
        '(2)-[Triggered, 1/Round]: At the end of your turn, if all of '
        'your Actions (minimum 3) were spent using the Energy Charge '
        'Maneuver this turn, you may use the Energy Charge Maneuver as '
        'an Out-of-Sequence Maneuver.',
  ),
  TalentDef(
    name: 'Arrogance',
    category: TalentCategory.miscellaneous,
    prerequisitesText: 'N/A',
    description: 'You are so consumed by your own hype that you '
        'believe no one is greater than you.\n'
        '(1)-[Passive]: Increase the Dice Category of your Greater '
        'Dice by 1 Category.\n'
        '(2)-[Passive]: While in the Superior State, increase the '
        'Wound Rolls of your Signature Techniques by 1(T).\n'
        '(3)-[Triggered, 1/Encounter]: If you use the Arrogant '
        'Declaration Maneuver, you may increase your Combat Rolls by '
        '1(T) until the end of your next turn. If you do, reduce your '
        'Combat Rolls by 1(T) for the remainder of the Combat '
        'Encounter after ending this effect.',
  ),
];

/// Looks up a Talent by name, or `null` if unrecognized.
TalentDef? talentByName(String name) {
  for (final t in kDbuTalents) {
    if (t.name == name) return t;
  }
  return null;
}

/// All Talents matching a given [category], in catalogue order.
List<TalentDef> talentsByCategory(TalentCategory category) =>
    kDbuTalents.where((t) => t.category == category).toList();
