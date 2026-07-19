/// unique_abilities.dart
/// ---------------------------------------------------------------------------
/// Static rules data for UNIQUE ABILITIES (Unique Abilities tab) — the site's
/// TP-purchased Maneuvers (Afterimage, Barrier, Telekinesis, Body Change, …).
///
/// Each [UniqueAbilityDef] carries the ability's structured fields (Type,
/// Prerequisites, TP/KP Cost, Maneuver Type, Action Cost, Minions, Passive
/// Bonus) and a verbatim Effect, plus nested [UaAdvancementDef]s (extra effects
/// bought with TP) and [UaRestrictionDef]s (limits that reduce TP and lock
/// certain Advancements).
///
/// The engine (see `CharacterCalculator`) computes each ability's TP Cost (base
/// + owned Advancements − applied Restrictions, floored at ½ the listed TP) and
/// KP Cost (listed KP minus Advancement reductions, floored at ½ when ≥ 4(T)).
/// Almost every effect is a situational combat rule, so this is mostly a
/// REFERENCE catalogue (like Basic Items) with the cost math on top — nothing
/// here feeds the global derived stats.
///
/// This file is built up in alphabetical chunks; entries are transcribed
/// verbatim from the offline ZIM archive's `/unique-abilities/` article
/// (dbu-rpg.com, 2026-07-03 backup), cross-checked against the live site.
/// ---------------------------------------------------------------------------
library;

/// The two Unique Ability classifications. An ability may permit both
/// (Technical/Magical), in which case the player chooses one when gaining it.
enum UniqueAbilityType {
  technical('Technical'),
  magical('Magical');

  const UniqueAbilityType(this.displayName);
  final String displayName;
}

/// One Advancement of a Unique Ability (bought with TP, on top of the ability).
class UaAdvancementDef {
  const UaAdvancementDef({
    required this.name,
    required this.description,
    required this.prerequisites,
    required this.tpCost,
    required this.effect,
    this.kpReductionPerTier = 0,
  });

  final String name;
  final String description;
  final String prerequisites;
  final int tpCost;
  final String effect;

  /// If this Advancement reduces the ability's KP Cost by `x(T)` (e.g.
  /// Efficient Barrier −2(T)), the `x`; 0 otherwise.
  final int kpReductionPerTier;
}

/// One Restriction of a Unique Ability (reduces TP, locks some Advancements).
class UaRestrictionDef {
  const UaRestrictionDef({
    required this.name,
    required this.description,
    required this.lockedAdvancements,
    required this.tpCostReduction,
    required this.effect,
  });

  final String name;
  final String description;

  /// Names of this ability's Advancements that cannot be taken while this
  /// Restriction is applied.
  final List<String> lockedAdvancements;

  /// The positive magnitude of the TP reduction (site writes it negative, e.g.
  /// "−5" → 5 here).
  final int tpCostReduction;

  final String effect;
}

/// One Unique Ability.
class UniqueAbilityDef {
  const UniqueAbilityDef({
    required this.name,
    required this.description,
    required this.types,
    required this.prerequisites,
    required this.baseTpCost,
    required this.kpCostText,
    required this.maneuverType,
    required this.actionCost,
    required this.minions,
    required this.passiveBonus,
    required this.effect,
    this.kpPerTier,
    this.kpUsesBaseTier = false,
    this.advancements = const [],
    this.restrictions = const [],
  });

  final String name;
  final String description;

  /// Which classifications this ability permits (one or both).
  final Set<UniqueAbilityType> types;

  final String prerequisites;
  final int baseTpCost;

  /// The KP Cost exactly as written ("2(T)", "4(bT)", "N/A", "Your entire
  /// Capacity", …). [kpPerTier] is the numeric coefficient when it's a clean
  /// `x(T)`/`x(bT)`; null for non-numeric costs (shown as reference only).
  final String kpCostText;
  final int? kpPerTier;

  /// Whether [kpPerTier] scales with Base Tier of Power (`bT`) vs Tier (`T`).
  final bool kpUsesBaseTier;

  final String maneuverType;
  final String actionCost;
  final String minions;

  /// The Passive Bonus text ("N/A" when none).
  final String passiveBonus;

  /// The verbatim Effect text.
  final String effect;

  final List<UaAdvancementDef> advancements;
  final List<UaRestrictionDef> restrictions;

  bool get allowsBothTypes => types.length > 1;

  /// A short "T/M", "T", or "M" label for the ability's Type(s).
  String get typeLabel =>
      types.map((t) => t == UniqueAbilityType.technical ? 'T' : 'M').join('/');
}

/// The Unique Abilities catalogue. Built in alphabetical chunks; effects
/// verbatim. (Chunk 1: Afterimage Technique … Energy Gathering.)
const List<UniqueAbilityDef> kDbuUniqueAbilities = [
  UniqueAbilityDef(
    name: 'Afterimage Technique',
    description: 'You possess the ability to move faster than the naked eye can '
        'see, allowing you to create visual illusions of your presence in '
        'locations that you are no longer in or to seemingly vanish when '
        'attacked.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Agility Score 4+',
    baseTpCost: 8,
    kpCostText: '2(T)',
    kpPerTier: 2,
    maneuverType: 'Counter',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus:
        'Increase the bonus to your Strike Roll from Rapid Movement by 1(T).',
    effect: 'When targeted by an Attacking Maneuver, you can increase your '
        'Defense Value by 2(T) for the duration of the Attacking Maneuver. If '
        'you avoid the Attacking Maneuver, you can use the Movement Maneuver as '
        'an Out-of-Sequence Action. This Movement Maneuver does not trigger the '
        'Exploit Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Wild Sense',
        description: 'Your battle instincts are sharp, allowing you to move at '
            'such high speed and attack in the same breath.',
        prerequisites: 'Insight Score 6+',
        tpCost: 6,
        effect: 'If you would use the Movement Maneuver through the effects of '
            'the Afterimage Technique, you may instead use the Basic Attack '
            'Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Afterimage Strike',
        description: 'You are able to use your insane speed to hide from the '
            'enemy, allowing you to surprise them with your next attack.',
        prerequisites: 'Agility Score 8+',
        tpCost: 10,
        effect: 'If you use the Movement Maneuver through the effects of the '
            'Afterimage Technique, make a Clash (Impulsive vs Cognitive) against '
            'the Opponent who targeted you with an Attacking Maneuver. If you '
            'win, the targeted Opponent gains the Oblivious Combat Condition.',
      ),
      UaAdvancementDef(
        name: 'Sonic Sway',
        description: 'Your overwhelming speed makes it difficult for other to '
            'strike you even when they work together.',
        prerequisites: 'Wild Sense',
        tpCost: 6,
        effect: 'You do not gain stacks of Diminishing Defense from an Attacking '
            'Maneuver you used the Afterimage Technique in response to.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Atmospheric Bubble',
    description: 'You create a shield around you that provides fresh air for '
        'you, regardless of the conditions outside.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 10,
    kpCostText: '4(bT)',
    kpPerTier: 4,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Ignore the rules for Unbreathable Environments while this Unique '
        "Ability's effects are applied.\n\nAt the start of each of your turns, "
        'pay the Ki Point Cost for this Unique Ability or stop applying its '
        'effects.',
    advancements: [
      UaAdvancementDef(
        name: 'Big Bubble',
        description: 'You are able to create a larger bubble to protect others '
            'besides yourself.',
        prerequisites: '3+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'When using this Unique Ability, you may apply the effects of '
            'this Unique Ability within a Sphere AoE. For every Skill Rank in '
            'Use Magic you possess past the second, you can increase the Ki '
            'Point Cost of this Unique Ability by 2(T) to increase the Magnitude '
            'of this Sphere AoE by 1 Magnitude.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Barrier',
    description:
        'You create a shield of some sort around you, protecting yourself from '
        'harm.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 4+',
    baseTpCost: 15,
    kpCostText: '10(T)',
    kpPerTier: 10,
    maneuverType: 'Counter',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'When you are hit by an Attacking Maneuver, make a Wound Roll as if '
        'you made an Attacking Maneuver of the Simple Profile (any Foundation). '
        'Reduce the Damage you receive by the Dice Score.',
    advancements: [
      UaAdvancementDef(
        name: 'Efficient Barrier',
        description: 'You control the amount of energy you feed into your '
            'barrier, reducing waste.',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'Reduce the Ki Point Cost of the Barrier Unique Ability by 2(T).',
        kpReductionPerTier: 2,
      ),
      UaAdvancementDef(
        name: 'Massive Barrier',
        description: 'Your barrier can protect your comrades as well.',
        prerequisites: 'Insight Score 6+',
        tpCost: 15,
        effect: 'If you use the Barrier Unique Ability when hit by an Attacking '
            'Maneuver that has an AoE and hit multiple Characters, you may '
            'increase the Ki Point Cost by 4(T) to apply the reduction to Damage '
            'to all Characters hit by that Attacking Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Ally Barrier',
        description: 'You wrap your barrier around another person, shielding '
            'them from harm.',
        prerequisites: 'Insight Score 6+',
        tpCost: 15,
        effect: 'If an Ally who is not at Long Range is hit by an Attacking '
            'Maneuver, you can use the Barrier Unique Ability as if you were the '
            'target of that Attacking Maneuver but apply its effects to that '
            'Character (you still make the Wound Roll for its effects).',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Binding',
    description: 'You possess the ability to entrap a target, preventing them '
        'from moving so long as you maintain your concentration.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 8+',
    baseTpCost: 20,
    kpCostText: '10(T)',
    kpPerTier: 10,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target a Character who is not at Long Range. Make a Clash (Energy '
        'Strike/Magic Strike vs Strike/Dodge). If you win, reduce their Defense '
        'Value by 1(T) until the end of your next turn and make a Might Clash '
        'against that same Character. If you win, that target is Pinned. Upon '
        'the Target becoming Pinned, you may spend 2(T) Ki Points to reduce that '
        "target's Life Points by 1/2 of your Might.\n\nAt the start of each of "
        'your turns, while a Character is Pinned by the effects of your Binding, '
        'you must pay the KP Cost of Binding or they stop being Pinned. If you '
        "do, you may spend 2(T) Ki Points to reduce that target's Life Points by "
        '1/2 of your Might. You can also remove the effects of Binding as an '
        'Instant Maneuver.\n\nFor every Turn that an Opponent ends with the '
        'Pinned Combat Condition through the effects of your Binding, increase '
        'the Dice Score of their Might Clash through the effects of the Pinned '
        'Combat Condition by 1(T) – using their Tier of Power to calculate this '
        'bonus.\n\nYou cannot use this Unique Ability again if an Opponent is '
        'currently Pinned due to the effects of your use of Binding.',
    advancements: [
      UaAdvancementDef(
        name: 'Psychic Grip',
        description: "You are able to move the target you've trapped with the "
            'power of your mind.',
        prerequisites: 'Telekinesis, Force or Magic Score 8+',
        tpCost: 5,
        effect: 'While an Opponent is Pinned due to the effects of Binding, '
            'reduce their Dice Score for the Clash against the effects of '
            'Telekinesis by 2(T).',
      ),
      UaAdvancementDef(
        name: 'Binding Volley',
        description: 'You can trap your target in a stronger form of binding, '
            'causing more damage!',
        prerequisites: 'Force or Magic Score 10+',
        tpCost: 10,
        effect: 'You may double the amount of Ki Points you spend to reduce the '
            "target's Life Points by your full Might value through the effects "
            'of Binding.',
      ),
      UaAdvancementDef(
        name: 'Binding Volleyball',
        description: 'You can use your energy to turn your opponent into a ball '
            'temporarily, allowing you to knock them around the battlefield.',
        prerequisites: 'Binding Volley',
        tpCost: 10,
        effect: 'If you use the effects of Binding Volley, you may move the '
            'targeted Opponent to a Square adjacent to you. If you do, they '
            "become known as the 'Volleyball' and the Combat Encounter pauses "
            'as you begin Volleyball Time!\n\nOnce Volleyball Time! begins, make '
            'a Basic Attack Maneuver of the Launching Profile against the '
            'Volleyball as an Out-of-Sequence Maneuver. If the movement from '
            'this Attacking Maneuver would make them Collide with any of your '
            'Allies (except Minions), instead of undergoing the rules for '
            'Collision, that Ally can use the Basic Attack Maneuver of the '
            'Launching Profile against the Volleyball as an Out-of-Sequence '
            'Maneuver. If the movement from that Attacking Maneuver would cause '
            'Collision with any of their Allies (except Minions), continue to '
            'apply this effect until it can no longer be applied. Each Character '
            'can only use the Basic Attack Maneuver through the effects of '
            'Binding Volleyball once during each Combat Encounter.\n\nIf an '
            "Ally's Attacking Maneuver would cause the Volleyball to Collide "
            'with you, you may use the Signature Technique Maneuver to use the '
            'Spike! Signature Technique as an Out-of-Sequence Maneuver, even if '
            'you do not possess the Spike! Signature Technique. The Spike! '
            'Signature is a Super Signature Technique of the Mega Flare Profile '
            'with no Advantages or Disadvantages, but it gains 1 Energy Charge '
            'for each time the Opponent has been hit by an Attacking Maneuver '
            'from your Allies during Volleyball Time! If you hit the Volleyball '
            'with the Spike! Signature Technique, after concluding that '
            'Attacking Maneuver, Volleyball Time! ends and that Opponent is no '
            'longer Pinned through your use of the Binding Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Energy Web',
        description: 'You can bind your opponent in such a way as to leave them '
            'wide open.',
        prerequisites: 'Insight Score 6+',
        tpCost: 10,
        effect: 'If you inflict the Pinned Combat Condition through the Binding '
            'Unique Ability, while that Opponent remains Pinned through those '
            'effects, they suffer from the Guard Down Combat Condition.',
      ),
      UaAdvancementDef(
        name: 'Psycho Thread',
        description: 'You can use your energy ensnaring an opponent to slowly '
            'sap them of their strength.',
        prerequisites: 'Insight Score 10+',
        tpCost: 10,
        effect: 'When your Opponent loses Life Points through the effects of '
            'your use of the Binding Unique Ability, they lose Ki Points equal '
            'to 1/2 of the amount of Life Points lost.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Gentle Hold',
        description: 'Your binding energy is not strong enough to cause harm.',
        lockedAdvancements: ['Binding Volley', 'Psycho Thread'],
        tpCostReduction: 5,
        effect: 'You cannot spend Ki Points through the effects of Binding to '
            'reduce the Life Points of a Target.',
      ),
      UaRestrictionDef(
        name: 'Weak Hold',
        description:
            'Even while you bind your enemies, they are still able to fight.',
        lockedAdvancements: ['Energy Web', 'Binding Volleyball'],
        tpCostReduction: 5,
        effect: 'Rather than inflict the Pinned Combat Condition, inflict the '
            'Guard Down Combat Condition through the effects of the Binding '
            "Unique Ability. Replace all mentions of 'Pinned' with 'Guard Down' "
            'in the effects of the Binding Unique Ability.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Body Change',
    description: 'With the cry of "Change Now!" you can swap bodies with your '
        'enemy, making their strengths your own.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'N/A',
    baseTpCost: 50,
    kpCostText: 'Your entire Capacity',
    maneuverType: 'Standard',
    actionCost: '3 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target a Character who is not at Long Range and make a Clash '
        '(Cognitive vs Impulsive) against them. If you win, you swap bodies '
        '(including your position on the Battlefield).\n\nFor both Characters '
        'who have swapped bodies, follow the below rules:\n\nSwap Attribute '
        'Scores (AG/TE/FO/MA).\n\nSwap Races for the sake of any Racial '
        'Requirements, Racial Saving Throw Bonus, and Racial Life '
        'Modifiers.\n\nRecalculate your Maximum Life Points and then swap '
        'current Life Point values.\n\nSwap Body Racial Traits. You cannot gain '
        'more than 5 Racial Traits (both Body and Mind) in total. If you would '
        'gain more than 5 Racial Traits, decide which 5 Racial Traits (2 Primary '
        'and up to 3 Secondary) you can use from the list of Body and Mind '
        'Racial Traits you possess. Any Option effects for Body Racial Traits '
        'must be the same as the original owner of the body and any Option '
        'effects for your Mind Racial Traits remain the same as what you decided '
        'in Character Creation.\n\nSwap Awakenings of the Body Awakening Origin '
        'to those of the body. This cannot allow you to exceed the Awakening '
        'Limit. When entering a Body, record the number of Awakenings of the '
        'Body Awakening Origin present. Rather than swap with your Character, '
        'anyone who enters this body due to Body Change refers to the Awakenings '
        'recorded to that body.\n\nSwap Apparel, Weapons, and all Items you have '
        'access to. This includes any Integrated Items.\n\nAfter swapping '
        'bodies, both Characters gain 3 stacks of Unfamiliar. Each stack of '
        'Unfamiliar reduces your Combat Rolls by 1(bT) and your Stress Bonus by '
        '1. While you have 2+ stacks of Unfamiliar, reduce your current Tier of '
        'Power by 1.\n\nAt the end of each Combat Encounter you participate in, '
        'you may remove a stack of Unfamiliar. You lose all previous stacks of '
        'Unfamiliar when you swap to a new body, but you still gain the 3 stacks '
        'for entering a new body. If you are swapped back into your original '
        'body, you do not gain Unfamiliar stacks.',
  ),
  UniqueAbilityDef(
    name: 'Bound Battlefield',
    description:
        'You create a barrier around your foes, preventing them from escaping '
        'your reach.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: '10+ Force or Magic Score',
    baseTpCost: 20,
    kpCostText: '6(bT)',
    kpPerTier: 6,
    kpUsesBaseTier: true,
    maneuverType: 'Standard Maneuver',
    actionCost: '3 Actions',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'All Squares within a Destructive Sphere AoE (centered on you) '
        'become Bound Squares. All Characters who are not on Bound Squares '
        'cannot use movement to enter Bound Squares and all Characters who are '
        'on Bound Squares cannot use movement to leave the Bound Squares. In '
        'both cases, the movement stops on the last Square they could move '
        'through and, if it was inflicted by another Character, they suffer from '
        'Collision as if they had collided with a Feature with a Hardness Rank '
        'of 3.\n\nYou cannot use the Bound Battlefield Unique Ability if the '
        'Battlefield has any Bound Squares. If, at any point, you are not on a '
        'Bound Square - all of the Squares that you had transformed into Bound '
        'Squares stop being Bound Squares.\n\nAt the start of your turn, you '
        'must spend 6(T) Ki Points or all of the Squares that you had '
        'transformed into Bound Squares stop being Bound Squares.\n\nIf you fail '
        'a Steadfast Check or are Defeated, all of the Squares you transformed '
        'into Bound Squares stop being Bound Squares.',
    advancements: [
      UaAdvancementDef(
        name: 'Powerful Barrier',
        description: 'Your barrier defends against attacks as well.',
        prerequisites: '12+ Force or Magic Score',
        tpCost: 12,
        effect: 'If a Character not occupying one of your Bound Squares targets '
            'a Character(s) occupying one of your Bound Squares with an '
            'Attacking Maneuver, or vice-versa, you may make a Might Clash '
            'against the attacking Character but reduce your Dice Score by 1(T) '
            'for every Energy Charge applied to that Attacking Maneuver. If you '
            'win, that Attacking Maneuver cannot target those Character(s) and '
            'if it has no targets as a result, it is cancelled. If it is '
            'cancelled, the attacking Character regains any Actions spent on '
            'that Attacking Maneuver but does not regain any Ki Points spent.',
      ),
      UaAdvancementDef(
        name: 'Variable Battlefield',
        description: 'You can choose the size of your barrier.',
        prerequisites: '8+ Insight Score',
        tpCost: 8,
        effect: 'When using the Bound Battlefield Unique Ability, you may select '
            'the Magnitude for its effect. You may select any Magnitude between '
            'Standard and Destructive.',
      ),
      UaAdvancementDef(
        name: 'Shrinking Battlefield',
        description:
            'You can pull your trapped foes ever closer to their inevitable '
            'demise.',
        prerequisites: 'Variable Battlefield Advancement',
        tpCost: 4,
        effect: 'At the start of your turn, if you pay the Ki Points to maintain '
            'your Bound Squares, you may spend an additional 2(bT) Ki Points to '
            'reduce the AoE of the Bound Squares by 1 Magnitude. Any Characters '
            'who are occupying those Squares are moved 1 Square of their choice '
            'so that they remain on a Bound Square. This movement cannot be '
            'reduced or negated by any means.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Cage of Light',
    description: 'You create a trap for your enemies of pure energy, keeping '
        'some inside, and some outside.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Force or Magic Score 10+, Insight Score 8+',
    baseTpCost: 16,
    kpCostText: '10(T)',
    kpPerTier: 10,
    maneuverType: 'Standard',
    actionCost: 'All of your remaining Actions (Min. 2)',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Target a Square within 8 Squares of you. Create a Large Sphere AoE '
        'centered on your chosen Square, this is known as the Cage. Characters '
        'within the Cage have their Life Points reduced by 1/4 (rounded up) of '
        'your Might whenever they would successfully dodge an Attacking '
        'Maneuver.\n\nCharacters within the Cage cannot move outside of the '
        'Cage, and Characters outside of the Cage cannot move into the Cage, and '
        'will cease movement on a Square adjacent to the perimeter of the Cage. '
        'Any Character that moves onto an adjacent Square to the perimeter of '
        'the Cage has their Life Points reduced by double your Might.\n\n'
        'Characters can attempt to enter or exit the Cage when using the '
        'Movement Maneuver (they still suffer the reduction to Life Points '
        'listed above) by making a Might Clash against you. If they win, they '
        'enter/exit the Cage.\n\nAt the start of each of your turns, you may '
        'spend all of your Actions and pay the KP Cost of Cage of Light to '
        'maintain the Cage. If you choose not to, the Cage will '
        'disappear.\n\nYou cannot use this Unique Ability while a Cage is active '
        'but you can remove the Cage as an Instant Action.',
  ),
  UniqueAbilityDef(
    name: 'Copy Being',
    description: 'You are able to perfectly mimic another person.',
    types: {UniqueAbilityType.magical},
    prerequisites: '4+ Skill Ranks in Use Magic',
    baseTpCost: 50,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '3',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target a Character on the Battlefield. You become an exact Copy of '
        'that Character in every way (Race, Subraces, Factors, Apparel, '
        'Accessories, Weapons, Attribute Scores, Size Category, Talents, Skills, '
        'Signature Techniques, Unique Abilities, Transformations, etc) except '
        'that you do not change your Tier of Power, and your Life Points, Ki '
        'Points ,or Capacity (or their respective Maximums) do not change. Use a '
        'copy of their character sheet instead of your own, but you still use '
        'your Life Points, Ki Points, and Capacity (and their respective '
        'Maximums).\n\nIf the Character you are a Copy of was in a Form and/or '
        'Enhancement when you used this Unique Ability, you automatically enter '
        'those Transformation(s).\n\nYou can only use Copy Being once per Combat '
        'Encounter, and you stop being a Copy if you are Defeated, the Combat '
        'Encounter ends, or if you fail a Steadfast Check. You can also stop '
        'being a Copy as an Instant Maneuver.\n\nAny Apparel, Accessories, '
        'Weapons, or other Items created by being a Copy are destroyed when you '
        'stop being a Copy.\n\nAny theoretical Characters created due to being '
        'part of the Character you copied through the Unified or Absorption '
        'Awakenings (or otherwise) do not exist, and thus cannot be freed from '
        'you or otherwise leave you by any means while you are a Copy.',
  ),
  UniqueAbilityDef(
    name: 'Copy Clone',
    description: 'You are able to create a perfect copy of another being, '
        'commanding that copy at-will.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Copy Being',
    baseTpCost: 20,
    kpCostText: '8(bT)',
    kpPerTier: 8,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Target a Character on the Battlefield who is not at Long Range. You '
        'create a Duplicate Minion, but instead of a Duplicate Minion of '
        'yourself, it is a Duplicate Minion of that Character (you are still '
        'their Master). You cannot target a Character whose Tier of Power is '
        'higher than yours.',
    advancements: [
      UaAdvancementDef(
        name: 'Mirrored Attack',
        description: 'Your copied clones can be used as a shield against harm.',
        prerequisites: 'N/A',
        tpCost: 10,
        effect: 'If you are targeted by an Attacking Maneuver, you may use the '
            'effects of Copy Clone as a Counter Maneuver with an Action Cost of '
            '1 Counter Action, but you must target the attacking Character. The '
            'created Minion becomes the target for that Attacking Maneuver and '
            'must respond with the Duel Maneuver (if possible). After that '
            'Attacking Maneuver is concluded, that Duplicate Minion ceases to '
            'exist.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Cyclone Energy',
    description: 'You are able to regather the energy that you have used to '
        "attack, so long as it isn't expended.",
    types: {UniqueAbilityType.technical},
    prerequisites: 'Insight Score of 8+',
    baseTpCost: 20,
    kpCostText: '2(T)',
    kpPerTier: 2,
    maneuverType: 'Out-of-Sequence',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'If you use an Energy Attack and fail to hit any of your target(s), '
        'you may use this Unique Ability to immediately use the Energy Charge '
        'Maneuver. If you do, your declared Attacking Maneuver gains any Energy '
        'Charges that were applied to your missed Attacking Maneuver.',
  ),
  UniqueAbilityDef(
    name: 'Dead Zone',
    description: 'You create a portal to the Dead Zone, sending whoever passes '
        'through to an eternal prison.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 30,
    kpCostText: '10(bT)',
    kpPerTier: 10,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '3 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'You open the Dead Zone, creating a Minor Sphere AoE centered on an '
        'unoccupied Square within a Sphere AoE (centered on you) that has no '
        'Characters on an adjacent Square. This AoE is a portal into the Dead '
        'Zone, a Dimension (see — Dimensions) that can seal someone away within '
        'perpetual darkness. Any Character that enters a Square within the AoE '
        'created by this Unique Ability is immediately sent to the Dead Zone '
        'Dimension. If you are sent into the Dead Zone Dimension, the portal '
        'immediately closes.\n\nAt the end of each of your turns, make a Might '
        'Clash against all Characters on the Battlefield. If they lose, they '
        'move a number of Squares up to your Might in the most direct path '
        'towards the Dead Zone portal.\n\nTo maintain the existence of the Dead '
        'Zone portal, you must spend 1 Action and 5(T) Ki Points at the start of '
        'each of your turns. If you do not pay this cost, the portal to the Dead '
        'Zone will close.',
  ),
  UniqueAbilityDef(
    name: 'Desperate Dodge',
    description:
        'You twist out of the way of an exploitative attack at the last '
        'possible second.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Agility Score 4+',
    baseTpCost: 8,
    kpCostText: 'N/A',
    maneuverType: 'Counter',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus: 'Reduce your total penalties from Diminishing Defense by 1 '
        '(increasing by 1 every 2 base Tier of Power reached after the first).',
    effect: 'If an Opponent would use the Exploit Maneuver in response to you '
        'triggering it, before any Counter Actions are spent or the Maneuver is '
        'actually used, make a Clash (Impulsive/Corporeal) against that '
        'Opponent. If you win, you do not trigger that Exploit Maneuver (and '
        'therefore they do not use it).',
  ),
  UniqueAbilityDef(
    name: 'Devilmite Beam',
    description: 'With your grand power of justice, you cause the evil in your '
        "target's heart to expand until it explodes, killing the target.",
    types: {UniqueAbilityType.technical},
    prerequisites: 'Insight Score 6+, Personality Score 4+',
    baseTpCost: 50,
    kpCostText: '12(T)',
    kpPerTier: 12,
    maneuverType: 'Standard',
    actionCost: '3 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent and make a Clash (Cognitive vs Impulsive) '
        'against them. If you win, apply the following effects depending on the '
        'alignment of their Z-Soul:\n\nPure Evil: The target is Defeated.\n\n'
        "Evil: Reduce the target's Life Points by 1/5 of their maximum Life "
        "Points.\n\nNeutral: Reduce the target's Life Points by 1/10 of their "
        "maximum Life Points.\n\nGood: Reduce the target's Life Points by 1/20 "
        'of their maximum Life Points.\n\nPure Good: Nothing happens.',
  ),
  UniqueAbilityDef(
    name: 'Dragon Dash',
    description:
        'You zoom straight towards your destination, making up lost ground '
        'instantaneously.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Access to the Soar Maneuver',
    baseTpCost: 5,
    kpCostText: '2(T)',
    kpPerTier: 2,
    maneuverType: 'Out-of-Sequence',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'Increase your Boosted Speed by 1(T).',
    effect: 'If one of your Attacking Maneuvers or effects moves an Opponent out '
        'of your Melee Range, you may use the Movement Maneuver to move in a '
        'straight line towards that Opponent or away from that Opponent as an '
        'Out-of-Sequence Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Deadly Chaser',
        description:
            'You chase down your opponent to keep pummeling them into the '
            'ground.',
        prerequisites: 'N/A',
        tpCost: 10,
        effect: 'If you move to a Square that places the triggering Opponent in '
            'your Melee Range through the effects of the Dragon Dash Unique '
            'Ability, you may use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver. If you do, you may apply the Knockback '
            'Advantage to that Attacking Maneuver if it does not already possess '
            'it.',
      ),
      UaAdvancementDef(
        name: 'Z-Burst Dash',
        description: 'You teleport directly to your Opponent to keep the '
            'pressure up.',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'Instead of moving in a straight line towards an Opponent '
            'through the effects of the Dragon Dash Unique Ability, you can '
            "instead choose to move your Character to any Square within that "
            "Opponent's Melee Range. You cannot move to a Square that is further "
            'away than twice the number of Squares you would be able to move '
            'with your Boosted Speed.',
      ),
      UaAdvancementDef(
        name: 'Spread Shot Retreat',
        description:
            'You cover your retreat with a ranged attack to avoid pursuit by '
            'your foes.',
        prerequisites: 'N/A',
        tpCost: 10,
        effect: 'If you move away from the triggering Opponent through the '
            'effects of the Dragon Dash Advancement, you may use the Basic '
            'Attack Maneuver as an Out-of-Sequence Maneuver. If you do, you '
            'cannot Ki Wager on this Attacking Maneuver, but that Attacking '
            'Maneuver gains 2 ranks of the Long Shot Advantage.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Down Burst',
    description: 'You fire a Ki Blast directly downwards, allowing you to trick '
        'your Opponents.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Force or Magic Score of 4+, 2+ Skill Ranks in Concealment',
    baseTpCost: 10,
    kpCostText: '4(T)',
    kpPerTier: 4,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'Increase your Skill Bonus for your Bluff and Concealment '
        'Skills by 1.',
    effect: 'Make a Clash (Impulsive) against all Opponents within a Minor '
        'Sphere AoE (centered on you). If you win against an Opponent, you '
        'become Hidden from that Opponent until the end of their next turn or '
        'until you hit them with an Attacking Maneuver (whichever occurs first). '
        'If you win against all Opponents in the AoE, you may use the Soar '
        'Maneuver or Movement Maneuver as an Out-of-Sequence Maneuver. The use '
        'of a Maneuver through the effects of Down Burst does not trigger the '
        'Exploit Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Ki Deception',
        description: 'Taking advantage of the confusion, you launch a powerful '
            'attack!',
        prerequisites: '2+ Skill Ranks in Bluff',
        tpCost: 10,
        effect: 'Instead of the Soar Maneuver or Movement Maneuver, you may use '
            'the Basic Attack Maneuver through the effects of Down Burst. If you '
            'do, and the Attacking Maneuver targets only one Opponent, make a '
            'Clash (Bluff vs Perception/Intuition) against that Opponent. If you '
            'win, apply an Energy Charge to that Attacking Maneuver.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Energy Gathering',
    description: 'By reaching out to the world around you, you draw in the '
        'natural energy of your environment.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Clairvoyance',
    baseTpCost: 20,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '1~3 Actions',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'For each Action spent, gain a stack of Lifeforce. If you possess a '
        'Dramatic Finisher with the Genki Super Profile, you may use the Energy '
        'Charge Maneuver as an Out-of-Sequence Maneuver. If you do, instead of '
        'gaining 1 Energy Charge through its effects, gain a number of Energy '
        'Charges equal to 1 less than the amount of Lifeforce stacks you gained '
        'through the effects of the Energy Gathering Unique Ability.\n\nIf you '
        'use a Maneuver other than the Signature Technique Maneuver, Energy '
        'Charge Maneuver, or Energy Gathering Unique Ability, you must spend a '
        'Karma Point or lose all stacks of Lifeforce.',
    advancements: [
      UaAdvancementDef(
        name: 'Combat Gatherer',
        description: "You've learned to hold onto the energy you gather without "
            'such intense focus.',
        prerequisites: '4+ Skill Ranks in Clairvoyance',
        tpCost: 10,
        effect: 'You may use other Maneuvers without losing your stacks of '
            'Lifeforce through the effects of Energy Gathering.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Environment Shift',
    description: 'You alter the world around you to suit your needs.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'N/A',
    baseTpCost: 10,
    kpCostText: '4(bT)',
    kpPerTier: 4,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target all Squares within a Sphere AoE (centered on you). Those '
        'Squares gain one of the following Environmental Qualities until the '
        'start of your next turn: Aflame, Bouncy, Dangerous, Electrified, '
        'Frozen, or Poisonous. You are unaffected by the effects of your chosen '
        'Environmental Quality (except Dangerous) until the start of your next '
        'turn.\n\nAny other Character who is within the Sphere AoE may spend a '
        'Counter Action to use the Movement Maneuver as an Out-of-Sequence '
        'Maneuver in response to this Unique Ability.',
  ),
  UniqueAbilityDef(
    name: 'Explosion Sorcery',
    description:
        'Using your magical prowess, you cause another person to explode.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 20,
    kpCostText: '6(T) for each Action spent',
    maneuverType: 'Standard',
    actionCost: 'Variable (1~3 Actions)',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target a Character for each Action spent on this Maneuver. Make a '
        'Clash (Cognitive vs Cognitive/Impulsive/Corporeal) against that '
        "Character. If you win, reduce that Character's Life Points by your "
        'Magic Modifier. If that Character was a Minion (except a Special '
        'Minion), they are Defeated instead.',
  ),
  UniqueAbilityDef(
    name: 'Explosive Wave',
    description: 'Using your energy, you forcefully push enemies away from you.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 6+',
    baseTpCost: 10,
    kpCostText: '4(T)',
    kpPerTier: 4,
    maneuverType: 'Instant',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Make a Might Clash against all Characters within a Minor Sphere AoE '
        '(centered on you). If you win, that Character is moved a number of '
        'Squares up to your Might in a straight line away from you.\n\nIf you '
        'win the Might Clash for this effect against a Character who is in a '
        'Grapple with you as the Grappled and them as the Grappler, end that '
        'Grapple before applying the movement.',
    advancements: [
      UaAdvancementDef(
        name: 'Mighty Explosive Wave',
        description: 'The force of your energy shoving away your foes also '
            'damages them.',
        prerequisites: 'Force or Magic Score of 8+',
        tpCost: 10,
        effect: 'If you win the Might Clash against a Character for the effects '
            "of Explosive Wave, reduce that Character's Life Points by 1/2 of "
            'your Might.',
      ),
      UaAdvancementDef(
        name: 'Super Explosive Wave',
        description:
            'Expelling even more energy, you shove even more foes away from you.',
        prerequisites: 'Mighty Explosive Wave',
        tpCost: 5,
        effect: 'Instead of a Minor Sphere AoE, use a Large Sphere AoE.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Extra Arms',
    description: 'Be it the magical ability to sprout extra limbs, or the speed '
        'to create the illusion and effect of extra limbs, by some measure, you '
        'are able to fight as though you have more than two arms.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Agility Score 6+, Insight Score 5+',
    baseTpCost: 12,
    kpCostText: '6(T)',
    kpPerTier: 6,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Enter the Multiple Arms Special State or leave it if you are '
        'already in it. While you are in the Multiple Arms Special State through '
        'the effects of this Unique Ability, you must pay half the KP Cost of '
        'this Unique Ability at the start of each of your turns or leave the '
        'Multiple Arms State.',
    advancements: [
      UaAdvancementDef(
        name: '100 Arm Technique',
        description: 'You are able to attack as though you have one hundred '
            'arms!',
        prerequisites: 'Agility Score of 8+',
        tpCost: 4,
        effect: 'While in the Multiple Arms Special State, increase your Strike '
            'Rolls by 1(T).',
      ),
      UaAdvancementDef(
        name: 'Four Witches Grip',
        description:
            'Thanks to your extra arms, you are able to grapple more effectively.',
        prerequisites: 'Insight Score of 6+',
        tpCost: 4,
        effect: 'While in the Multiple Arms Special State, increase all of your '
            'Grapple Checks by 1(T).',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Faked Extra Arms',
        description: 'You move your arms faster than the eye can see, appearing '
            'to have multiple arms because of the afterimage left behind.',
        lockedAdvancements: ['Four Witches Grip'],
        tpCostReduction: 2,
        effect: 'If you enter the Multiple Arms State through the effects of '
            'Extra Arms, while you are in that State, ignore the first effect of '
            'the Multiple Arms State.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Fake Death',
    description: 'Based on the Homebrew by Dunkaccino (_dunkaccino_ in '
        'Discord)\n\nWith a dramatic cry of defeat or a sudden stillness on the '
        'battlefield, you topple over pretending to have died. Those around you '
        'must carefully consider whether or not you have actually fallen in '
        'battle or are waiting for a specific moment in battle to take advantage '
        'of.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Personality Score 4+, 2+ Bluff Skill Ranks',
    baseTpCost: 8,
    kpCostText: '4(bT)',
    kpPerTier: 4,
    kpUsesBaseTier: true,
    maneuverType: 'Out-of-Sequence',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: "After receiving Damage from an Opponent's Attacking Maneuver, you "
        'may choose to be knocked Prone. If you do, make a Clash (Bluff vs '
        'Intuition) against all Opponents. If you win, you become Hidden to '
        'those Opponents.\n\nIf you use the Movement Maneuver while Hidden '
        'through the effect of Fake Death, you stop being Hidden.\n\nYou may '
        'only use this Unique Ability once per Combat Encounter.',
    advancements: [
      UaAdvancementDef(
        name: 'Surprise Strike',
        description: 'Your body lay so still that those fooled by your facade '
            'are perfectly open targets.',
        prerequisites: 'Insight Score 4+, Personality Score 6+',
        tpCost: 7,
        effect: 'If an Oblivious Character ends their turn within your Melee '
            'Range while you are Hidden due to the effects of Fake Death, you '
            'may use the Basic Attack Maneuver against that Opponent as an '
            'Out-of-Sequence Maneuver. After concluding that Attacking Maneuver, '
            'you stop being Hidden.',
      ),
      UaAdvancementDef(
        name: 'Stealth Crawl',
        description: "While everyone thinks you're dead, you can take the "
            'opportunity to secure the perfect position to capitalize on your '
            'ruse.',
        prerequisites: '3+ Bluff Skill Ranks.',
        tpCost: 2,
        effect: 'At the start of your turn while Hidden through the effects of '
            'the Fake Death Unique Ability, you may move a number of Squares up '
            'to your number of Skill Ranks in the Bluff Skill.',
      ),
      UaAdvancementDef(
        name: 'Like the Dead',
        description: 'Your act is so good that even those not initially fooled '
            'start to believe otherwise.',
        prerequisites: 'Tenacity Score 7+',
        tpCost: 4,
        effect: 'When struck by an attack while Hidden from an Opponent(s) '
            'through the effects of Fake Death by an Opponent who you are not '
            'Hidden from, you may spend 4(T) Ki Points to make a Clash (Bluff vs '
            'Intuition) against the attacking Character. Increase your Dice Score '
            'for this Clash by 1d4. If you win, you become Hidden to that '
            'Character.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Fake Moon',
    description: 'You have the ability to create a false full moon in the sky, '
        'allowing anything that relies on the full moon to access its hidden '
        'power.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score 4+',
    baseTpCost: 10,
    kpCostText: '6(bT)',
    kpPerTier: 6,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Create a False Moon. A False Moon acts as a full moon and increases '
        'the Light Level of the Battlefield by 1 Light Level (to a maximum of '
        'Normal). All Characters with access to a Transformation with the Blutz '
        'Wave Aspect may use the Transformation Maneuver as an Out-of-Sequence '
        'Maneuver to enter a Transformation with that Aspect.\n\nA False Moon '
        'lasts for 5 Combat Rounds, after which it will disappear and any Saiyan '
        'in the Oozaru or Golden Oozaru Transformations will suffer from Stress '
        'Exhaustion until the end of their next turn.\n\nA False Moon is a '
        'Feature that can only be made in a High Environment of Rank 2 or higher '
        '(you can only select Deep Space for this option if you are in Deep '
        'Space). The Feature is created on any Square within a Destructive '
        'Sphere AoE (centered on you). The Feature is 4×4, has a Hardness Rank '
        'of 2, and possesses the Burning Feature Quality (see - '
        'Battlefields).\n\nRather than the typical way to destroy a False Moon, '
        'a False Moon takes Damage like a Character would and has a pool of Life '
        'Points equal to 5x the Might of its creator at the time of creation and '
        "Damage Reduction equal to their creator's Might at the time of "
        "creation. If a False Moon's Life Points reach 0, it is destroyed and "
        'you apply the effects as if it disappeared (seen above).\n\nOnly one '
        'False Moon can exist on a Battlefield at a time.',
    advancements: [
      UaAdvancementDef(
        name: 'Lasting Moon',
        description: 'Your false full moon lasts much longer, extending your '
            'access to the hidden powers unlocked by it.',
        prerequisites: 'Force or Magic Score of 8+',
        tpCost: 5,
        effect: 'Your False Moon lasts for the remainder of the Combat Encounter '
            'and double both its Life Points and Damage Reduction.',
      ),
      UaAdvancementDef(
        name: 'Moon Guardian',
        description: "You use your body to shield the full moon you've created.",
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'If your False Moon is targeted by an Attacking Maneuver that '
            'does not possess an AoE, you may spend a Counter Action to move to '
            'an adjacent Square to that False Moon. If you do, shift the target '
            'of that Attacking Maneuver to you.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Flooding Technique',
    description: 'You can magically produce enough water to change the tides of '
        'battle, creating an ocean on the battlefield.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'N/A',
    baseTpCost: 15,
    kpCostText: '6(bT)',
    kpPerTier: 6,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'N/A',
    passiveBonus: 'While in the Underwater Battle Environment, increase your '
        'Combat Rolls by 1(T).',
    effect: 'Within a Large Sphere AoE (centered on you), the Battle '
        'Environment becomes Underwater. If you move to another Square due to '
        'any effect, the AoE containing this Battle Environment moves the exact '
        'same distance and in the same direction.\n\nYou cannot use this Unique '
        'Ability while it is active, and must pay the Ki Point Cost of this '
        'Unique Ability at the start of each of your turns or return the Battle '
        'Environment to what it would normally be. You may return the Battle '
        'Environment to normal as an Instant Action.',
  ),
  UniqueAbilityDef(
    name: 'God Meteor',
    description: 'You are capable of dropping a giant meteor from the heavens '
        'onto your enemies, dealing massive damage.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites:
        'Force or Magic Score 10+, access to the God Ki Special State, Tier of '
        'Power 4+',
    baseTpCost: 40,
    kpCostText: '15(bT)',
    kpPerTier: 15,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '3 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'Increase your Wound Rolls by 1(T) while in the God Ki State, '
        'or against Pinned Characters if you are not in the God Ki State.',
    effect: 'Target a Square on the Battlefield. Every Character (except the '
        'user of this Unique Ability) within a Destructive Sphere AoE centered '
        'on your targeted Square enters the Meteor Phase, wherein a gigantic '
        'meteor falls from the heavens onto those Characters.\n\nOnce the Meteor '
        'Phase starts, all combat stops and every Character within the Meteor '
        'Phase must choose to Defend or Attack:\n\nThose who Defend will reduce '
        'the Damage they take by 1/2.\n\nThose who Attack can use the Basic '
        'Attack Maneuver or Signature Attack Maneuver as an Out-of-Sequence '
        'Action, but they must target the Meteor in order of their place in the '
        'Initiative Order. No Character can miss the Meteor with this Attacking '
        "Maneuver.\n\nThe God Meteor's Life Points are equal to the user's "
        "Maximum Life Points and it possesses Damage Reduction equal to the "
        "user's Might. If the Life Points of the God Meteor reaches 0, it is "
        'destroyed and no Character in the Meteor Phase will receive any '
        'damage.\n\nAfter all decisions and Attacking Maneuvers are made, the '
        'Meteor Phase ends. If the God Meteor is not destroyed by the end of the '
        'Meteor Phase, all Combatants that were within the Meteor Phase have '
        'their Life Points reduced by the remaining Life Points of the God '
        'Meteor. You can only use this Unique Ability while you are in the God '
        'Ki Special State.\n\nThis Unique Ability can only be used once per '
        'Combat Encounter.',
  ),
  UniqueAbilityDef(
    name: 'Healing Hands',
    description: 'You can lay your hands upon your allies, restoring their '
        'vitality in the process.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 10,
    kpCostText: '5(T)',
    kpPerTier: 5,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'Increase your Medicine Skill Checks by 1.',
    effect: 'Target a Character within your Melee Range. That Character regains '
        '1d10(bT) Life Points. Increase the amount of Life Points they regain by '
        'your Magic Modifier.',
    advancements: [
      UaAdvancementDef(
        name: 'Healing Expertise',
        description: 'You can restore even more vitality thanks to your '
            'expertise.',
        prerequisites: 'Magic Score of 8+',
        tpCost: 6,
        effect: 'Increase the amount of Life Points restored by the Healing '
            'Hands Unique Ability by 1d10(bT).',
      ),
      UaAdvancementDef(
        name: 'Overexertion',
        description: 'Healing someone stronger than you requires greater effort, '
            'but the reward is greater as well.',
        prerequisites: 'Personality Score of 4+',
        tpCost: 5,
        effect: 'When you target a Character with Healing Hands, you may spend '
            'an additional 4(T) Ki Points to increase the amount of Life Points '
            "restored by your use of Healing Hands by the target's Might.",
      ),
      UaAdvancementDef(
        name: 'Desperate Heal',
        description: 'You can pour even more energy into healing, allowing you '
            'to restore immense amounts of vitality to your target.',
        prerequisites: 'Overexertion',
        tpCost: 10,
        effect: 'When you target a Character with Healing Hands, you may spend a '
            'number of Ki Points equal to your current Capacity, if you do, '
            'increase the amount of Life Points the target regains by an equal '
            'amount. If you possess the Energy Zone Advancement, this effect can '
            'only apply to ONE of the targets.',
      ),
      UaAdvancementDef(
        name: 'Energy Zone',
        description: 'You can heal all allies near you at once.',
        prerequisites: 'Magic Score of 10+',
        tpCost: 10,
        effect: 'Instead of targeting a Character within your Melee Range, you '
            'may target all Allies within a Large Sphere Aoe (centered on you) '
            'for the effects of Healing Hands.',
      ),
      UaAdvancementDef(
        name: 'Patch-Up',
        description: 'You can repair clothing as well as people.',
        prerequisites: 'Magical Materialization',
        tpCost: 4,
        effect: 'If you would target a Character with the Healing Hands Magical '
            'Ability, you may also repair their Apparel. Restore a damaged or '
            'broken piece of Apparel to have their maximum Break Value.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Natural Healing Hands',
        description: 'Your ability to heal others does not apply to arcane or '
            'artificial beings.',
        lockedAdvancements: ['Patch-Up'],
        tpCostReduction: 2,
        effect: 'You cannot target Unnatural characters with Healing Hands.',
      ),
      UaRestrictionDef(
        name: 'Minimal Healing',
        description: "You aren't able to heal as much damage as most.",
        lockedAdvancements: ['Healing Expertise', 'Overexertion'],
        tpCostReduction: 5,
        effect: 'You do not increase the amount of Life Points regained by your '
            'Magic Modifier.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Holstein Shock',
    description: 'You inflict harm upon yourself in order to gain a '
        'psychological or tactical advantage over your enemies.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'N/A',
    baseTpCost: 5,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Make a Wound Roll as if you made an Attacking Maneuver of the '
        'Simple Profile (any Foundation). Reduce your Life Points by the Dice '
        'Score.',
    advancements: [
      UaAdvancementDef(
        name: 'Controlled Shock',
        description: 'You apply bodily harm in a carefully controlled manner to '
            'avoid undue stress on your body.',
        prerequisites: 'Insight Score of 6+',
        tpCost: 10,
        effect: 'If you knock yourself through a Health Threshold through the '
            'use of the Holstein Shock Unique Ability, do not apply Reduced '
            'Momentum.',
      ),
      UaAdvancementDef(
        name: 'Revitalizing Shock',
        description: 'Through the pain coursing through your body, you feel '
            'alive again.',
        prerequisites: 'Controlled Shock Advancement',
        tpCost: 5,
        effect: 'Regain Ki Points equal to 1/2 of the Dice Score for the effects '
            'of the Holstein Shock Unique Ability.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Illusion',
    description:
        'You are capable of creating a combat illusion, deceiving your enemies.',
    types: {UniqueAbilityType.magical},
    prerequisites:
        'Magic Score of 4+, 2+ Use Magic Skill Ranks, 2+ Bluff Skill Ranks',
    baseTpCost: 14,
    kpCostText: '4(bT)',
    kpPerTier: 4,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'Increase your Bluff Skill Checks by 1.',
    effect: 'Target a Square within 8 Squares of you. Create a Sphere AoE '
        'centered on that Square. Make a Clash (Use Magic/Bluff vs Use '
        'Magic/Intuition/Clairvoyance) against all Opponents within that AoE. If '
        'you win, roll a 1d4. Depending on the result, apply one of the '
        'following Combat Conditions to all losing Opponents until the end of '
        'your next turn:\n\n1) Blinded,\n\n2) Shaken,\n\n3) Impediment,\n\n4) '
        'Compelled (the target must be another Character within the initial AoE '
        'created by this Unique Ability).\n\nRather than roll, your ARC may '
        'choose an effect that seems fitting depending on your description for '
        'the Illusion you created through this Unique Ability. They may allow '
        'you to spend a Karma Point to choose.',
    advancements: [
      UaAdvancementDef(
        name: 'Expanded Illusion',
        description: 'Your illusion grows in size.',
        prerequisites: '4+ Use Magic Skill Ranks',
        tpCost: 10,
        effect: 'Increase the Magnitude of the AoE for the effects of Illusion '
            'to Destructive.',
      ),
      UaAdvancementDef(
        name: 'Combat Illusion',
        description: 'Your illusions are incredibly realistic and your opponent '
            'is easily duped by them making any kind of aggressive motion!',
        prerequisites: '4+ Bluff Skill Ranks',
        tpCost: 6,
        effect: 'Any Opponent who loses the Clash for the effects of Illusion '
            'also gains the Guard Down Combat Condition for the duration of its '
            'effects.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Close Range Illusions',
        description:
            'You can only create convincing illusions if they remain close to '
            'you.',
        lockedAdvancements: [],
        tpCostReduction: 4,
        effect: "You must select yourself for the Target Square of this Unique "
            "Ability's AoE.",
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Illusion Smash',
    description: 'You can attack from a distance as though you were in close '
        'range, utilizing portals or other magical means.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Portal Creation',
    baseTpCost: 10,
    kpCostText: '3(T)',
    kpPerTier: 3,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent, you can make a Basic Attack Maneuver against '
        'that Opponent as an Out-of-Sequence Maneuver. If you do, treat them as '
        'if they were on a Square adjacent to you for this Attacking Maneuver. '
        'Ignore the second effect of Giant Strike for this Attacking Maneuver '
        'and this Attacking Maneuver cannot possess an AoE.',
    advancements: [
      UaAdvancementDef(
        name: 'Combo Portal',
        description: 'When you attack someone and send them flying, you can '
            'continue your assault without further movement.',
        prerequisites: 'Insight Score of 10+',
        tpCost: 6,
        effect: 'If you move an Opponent with an effect, you may use Illusion '
            'Smash as an Instant Maneuver. If you do, you can only target the '
            'Opponent you moved with the Basic Attack Maneuver used through '
            'Illusion Smash. Additionally, this Attacking Maneuver may gain the '
            'Knockback Advantage.',
      ),
      UaAdvancementDef(
        name: 'Portal Control',
        description: 'Your ability to utilize portals grows, allowing you to do '
            'more than just attack.',
        prerequisites: 'N/A',
        tpCost: 8,
        effect: 'Instead of targeting an Opponent, you may target any Character '
            'with the effects of Illusion Smash and, instead of using an '
            'Attacking Maneuver, may use any Maneuver with an Action Cost of 1 '
            'that targets another Character as if that Character was in your '
            'Melee Range.\n\nIf you would use the Grapple Maneuver through this '
            'effect and successfully enter a Grapple as a result, move the '
            'Grappled Character into your Melee Range on an unoccupied Square of '
            'your choice.',
      ),
      UaAdvancementDef(
        name: 'Smash Barrage',
        description: 'You can fight multiple enemies at once with your unique '
            'method.',
        prerequisites: 'Insight Score of 14+',
        tpCost: 10,
        effect: 'When using a Profile that does not possess an AoE through the '
            'Basic Attack Maneuver used through the effects of Illusion Smash, '
            'you may target up to 3 Opponents with that Attacking Maneuver '
            'simultaneously.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Internal Assault',
    description:
        'You use your telekinetic prowess to assail someone from the inside out.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Telekinesis Unique Ability',
    baseTpCost: 15,
    kpCostText: '11(T)',
    kpPerTier: 11,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent and make a Clash (Cognitive vs '
        "Cognitive/Corporeal) against that Opponent. If you win, that Opponent "
        "becomes 'Debilitated'. A Debilitated Opponent loses Life Points equal "
        'to ¼ (rounded up) of your Magic Modifier each time they use a Maneuver, '
        'cannot use the Combat Recovery Maneuver, and suffers from the '
        'Impediment and Staggered Combat Conditions.\n\nIf a Debilitated '
        'Opponent loses the Impediment or Staggered Combat Conditions through '
        'any effect, they stop being Debilitated.\n\nAt the start of each of '
        'your turns, you must spend the Action Cost and Ki Point Cost of '
        'Internal Assault or your Debilitated Opponent stops being Debilitated. '
        'You may also stop an Opponent from being Debilitated through your use '
        'of Internal Assault as an Instant Maneuver.\n\nDuring their turn, as a '
        'Standard Maneuver with an Action Cost of 1 Action, a Debilitated '
        'Opponent may initiate a Clash (Cognitive/Corporeal vs Cognitive) '
        'against you. If they win, they stop being Debilitated.',
  ),
  UniqueAbilityDef(
    name: 'Ki Avatar',
    description: 'You create a much larger version of yourself out of energy.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Insight Score of 8+',
    baseTpCost: 20,
    kpCostText: '8(T)',
    kpPerTier: 8,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Create a Ki Avatar around your body. While you possess a Ki Avatar, '
        'if your Size Category is smaller than Gigantic, your Size Category is '
        'considered Gigantic for calculating the benefits and penalties of Size '
        '(see - the Size Table) and for all rules detailed on the Size page '
        'except Punching Up.\n\nSpend 4(bT) Ki Points at the start of each of '
        'your turns to maintain the Ki Avatar. If you do not, your Ki Avatar '
        'disappears.',
  ),
  UniqueAbilityDef(
    name: 'Lullaby Fist',
    description:
        'You are able to put your opponents to sleep with your hypnotic prowess.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Bluff and Use Magic',
    baseTpCost: 12,
    kpCostText: '8(T)',
    kpPerTier: 8,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target a Character within a Large Sphere AoE (centered on you). '
        'Make a Clash (Cognitive vs Corporeal/Impulsive/Cognitive/Morale) '
        'against that Opponent. If you win, they gain the Sleeping Combat '
        'Condition.\n\nYou can only target a Character once per Combat Encounter '
        'with the effects of Lullaby Fist.',
    advancements: [
      UaAdvancementDef(
        name: 'Multi-Sleep',
        description:
            'Your hypnotic prowess allows you to put many people to sleep.',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'You may target an additional Character.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Magical Enhancement',
    description: 'You are able to share your power with others, increasing their '
        'strength in place of your own.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Magic Score of 6+, 2+ Skill Ranks in Use Magic',
    baseTpCost: 10,
    kpCostText: '2(bT)',
    kpPerTier: 2,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target an Ally within 8 Squares of you. That Character becomes '
        'Magically Enhanced until the end of their turn. A Magically Enhanced '
        'Character increases their Combat Rolls and Soak Value by 1(T).',
    advancements: [
      UaAdvancementDef(
        name: 'Deeper Enhancement',
        description:
            'You enhance your comrades even further by investing more energy.',
        prerequisites: 'Magic Score of 10+, 3+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'When you use Magical Enhancement, you may increase the Action '
            'Cost by up to 2 Actions and increase the Ki Point Cost by 1(T) for '
            'each additional Action. For each additional Action spent, increase '
            "that Ally's Wound and Soak Value by an additional 1(T) through the "
            'effects of Magical Enhancement.',
      ),
      UaAdvancementDef(
        name: 'Unleash Dormant Power',
        description: 'You can reach into others and draw out the power from deep '
            'within them.',
        prerequisites: '5 Skill Ranks in Use Magic',
        tpCost: 20,
        effect: 'When you target a Character with the Magical Enhancement Unique '
            'Ability, you may choose to spend 2 additional Actions and Ki Points '
            'equal to 1/2 of your Maximum Ki Points (this does not affect your '
            'Capacity) to apply one of the following effects to your targeted '
            'Ally:\n\nYour targeted Ally gains a stack of the Unlocked Potential '
            'Awakening as a Level 2 Temporary Awakening.\n\nYour targeted Ally '
            'may use the Transformation Maneuver as an Out-of-Sequence Maneuver. '
            'If they do, increase their Stress Bonus by ½ (rounded up) of your '
            'Tier of Power for the duration of this Transformation Maneuver and '
            "then until they leave that Transformation if they succeed.\n\nWith "
            "your ARC's approval, your targeted Ally gains access to an "
            'Enhancement they meet the Racial Requirements, Prerequisites, and '
            'Tier of Power Requirement of until the end of the Combat '
            "Encounter.\n\nWith your ARC's approval, your targeted Ally gains "
            'access to a Form they meet the Racial Requirements, Prerequisites, '
            'and Tier of Power Requirement of until the end of the Combat '
            'Encounter.\n\nYou can only use the effect of Unleash Dormant Power '
            'twice per Combat Encounter and you cannot apply this effect twice '
            'to the same Ally during a Combat Encounter.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Magical Materialization',
    description: 'You are capable of conjuring objects out of thin air, allowing '
        'you to manifest anything you desire, within a limit.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 10,
    kpCostText: '6(T)',
    kpPerTier: 6,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'You gain access to the Create Maneuver (see — Crafting) and '
        'may use your Use Magic Skill instead of the Craft Skill for its '
        'effects. When using the Create Maneuver to create a Basic Item, Weapon, '
        'or Apparel, you can spend the Ki Point Cost of Magical Materialization '
        'to reduce the Time Cost to 1 Minute, but increase the Difficulty '
        'Category by 1 Category (or reduce your Dice Score by 4 if the '
        'Difficulty Category was Grandmaster) and you do not gain a Blueprint '
        'from that use of the Create Maneuver.',
    effect: 'Select either a Basic Item that does not have the [Tech] or [Food] '
        'tag, a piece of Apparel, or a Weapon. Roll the Craft Skill Check for '
        'your choice, using the Use Magic Skill instead of the relevant Craft '
        'Specialization, but increase the Difficulty Category by 1 (or reduce '
        'your Dice Score by 4 if the Difficulty Category was Grandmaster). If '
        'you fail, you do not create the item, but you still lose the Ki Points. '
        'If you succeed, you create the selected Item.\n\nThe created item is '
        'either made in your hand, or in a Square within your Melee Range. Any '
        'Item made by Magical Materialization is destroyed at the end of a '
        'Combat Encounter, unless you spend a Karma Point to preserve that Item '
        '(if you created multiple Items, each Item requires a Karma Point to be '
        'preserved).\n\nYou cannot Integrate any Items created through Magical '
        'Materialization.',
    advancements: [
      UaAdvancementDef(
        name: 'Weapon Summoner',
        description: 'You can conjure weapons with ease.',
        prerequisites: 'Insight Score 8+',
        tpCost: 5,
        effect: 'You automatically succeed each Use Magic Skill Check to make a '
            'Weapon with a Craftsmanship Grade equal to or lower than your '
            'number of Use Magic Skill Ranks. You can dismiss any Weapon '
            "you've created with Magical Materialization as an Instant Maneuver "
            'OR as part of Magical Materialization in addition to its other '
            'effects.',
      ),
      UaAdvancementDef(
        name: 'Power Builder',
        description: 'You may conjure objects using your prowess in manipulating '
            'your life energy rather than your magic energy.',
        prerequisites: 'Force Score 4+',
        tpCost: 2,
        effect: 'When making a Use Magic Skill Check for the effects of Magical '
            'Materialization, you may use your Force Score instead of your Magic '
            "Score for the Use Magic Skill's Skill Bonus.",
      ),
      UaAdvancementDef(
        name: 'Projectile Materialization',
        description: 'You can materialize items at a short distance, directly in '
            'the hands or on the person of an ally.',
        prerequisites: 'Insight Score 4+',
        tpCost: 2,
        effect: 'Target a willing Ally within a Sphere AoE (centered on you). If '
            'you succeed on the Skill Check for Magical Materialization to '
            'create an Accessory, Apparel, or Weapon, the targeted Ally gains '
            'that item. If it was a piece of Apparel or an Accessory, they may '
            'replace one layer of Apparel or Accessory they are currently '
            'wearing, or equip it as an additional item (they decide).',
      ),
      UaAdvancementDef(
        name: 'Restrictive Weights',
        description: 'You are able to create an item that burdens your '
            'opponents, slowing them in combat.',
        prerequisites: 'Projectile Materialization',
        tpCost: 6,
        effect: 'You may target an Opponent with the effects of Projectile '
            'Materialization, but you may only create Weights. Make a Clash '
            '(Cognitive vs Impulsive) against the targeted Opponent. If they '
            'win, your selected Weights are created on a Square adjacent to that '
            'Opponent. If you win, that opponent automatically equips the '
            'Weights you created as their top layer of Apparel (this can allow '
            'them to wear 4 layers of Apparel).\n\nThese Weights do not give a '
            'Doff Bonus once removed.',
      ),
      UaAdvancementDef(
        name: 'Dematerialize',
        description: 'Just as you can create, so too can you destroy.',
        prerequisites: 'Scholarship or Magic Score 7+',
        tpCost: 6,
        effect: "You may forgo Magical Materialization's effect to target an "
            'item created through Magical Materialization within your Melee '
            'Range and destroy it.',
      ),
      UaAdvancementDef(
        name: 'Magic Crafter',
        description: 'You are skilled at conjuring items with magic.',
        prerequisites: 'Scholarship or Insight Score of 8+',
        tpCost: 5,
        effect: 'Do not increase the Difficulty Category for the Use Magic Skill '
            'Check of Magical Materialization.',
      ),
      UaAdvancementDef(
        name: 'Tech Materialization',
        description: 'You understand technology to such an extent that you are '
            'able to conjure it.',
        prerequisites: '2+ Skill Ranks in Craft (Basic Item)',
        tpCost: 5,
        effect: 'You may create Basic Items with the [Tech] tag through Magical '
            'Materialization. If you have 4+ Skill Ranks in Craft (Basic Item), '
            'you do not increase the Difficulty Category of a Basic Item with '
            'the [Tech] tag that would be created through this effect.',
      ),
      UaAdvancementDef(
        name: 'Food Materialization',
        description: 'Thanks to your skills in the kitchen, you are able to '
            'conjure food from thin air.',
        prerequisites: '2+ Skill Ranks in Cooking',
        tpCost: 5,
        effect: 'You may create Basic Items with the [Food] tag through Magical '
            'Materialization. If you have 4+ Skill Ranks in Cooking, you do not '
            'increase the Difficulty Category of a Basic Item with the [Food] '
            'tag that would be created through this effect.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Limited Creation',
        description: 'You are only able to make one kind of item.',
        lockedAdvancements: ['Weapon Summoner', 'Projectile Materialization'],
        tpCostReduction: 5,
        effect: 'Select either Basic Item, Apparel, or Weapon. You can only '
            'create your selected Item through the effects of Magical '
            'Materialization. (Locked: Weapon Summoner is only locked unless you '
            'choose Weapon for the effects of Limited Creation.)',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Metamoran Fusion Dance',
    description: 'You can perform a special dance which, when performed '
        'perfectly with a compatible partner, allows you to fuse with them.',
    types: {UniqueAbilityType.technical},
    prerequisites: '2+ Skill Ranks in Performance',
    baseTpCost: 15,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '3 Actions',
    minions: 'N/A',
    passiveBonus: 'Increase your Performance Skill Checks by 1.',
    effect: 'Target an Ally within your Melee Range who is of the same Power '
        'Level as you and within 1 Size Category of you until the start of your '
        'next turn. For each stack of Holding Back a Character possesses, treat '
        'their Power Level as if it was 1 lower for this effect. If that Ally '
        'also targets you with the Metamoran Fusion Dance, both Characters make '
        'a Performance Skill Check with a Difficulty Category of Master. If you '
        'are not the same Size Category as your target, increase the Performance '
        "Skill Check's Difficulty Category by 1 for both Characters.\n\nGain the "
        'following benefits depending on the results of both Characters:\n\nBoth '
        'Succeed: Both Characters combine using the Metamorese Fusion '
        'Method.\n\nBoth Fail: Nothing happens.\n\nOne Succeeds, One Fails: Both '
        'Characters combine using the Metamorese Fusion Method but roll a 1d4, '
        'if the result is 2~4 the Fusion becomes Plump, and if your result is a '
        '1, the Fusion becomes Frail. Both Plump and Frail Fusions are in their '
        'Normal State, cannot possess Fusion Modifiers, and cannot use the '
        'Transformation Maneuver, Signature Technique Maneuver or any Unique '
        'Abilities. Additionally, Plump Fusions have their Agility Modifier '
        'halved, and Frail Fusions have their Agility, Tenacity, Force and Magic '
        'Modifiers halved.',
    advancements: [
      UaAdvancementDef(
        name: 'Five-Way Fusion',
        description: 'Combining the full power of 5 different warriors, you fuse '
            'into the ultimate powerhouse.',
        prerequisites: 'N/A',
        tpCost: 30,
        effect: 'Instead of targeting a single Ally through the effects of the '
            'Metamoran Fusion Dance, you may target 4 Allies instead. Those '
            'Allies may be within a Large Sphere AoE (centered on you) instead '
            'of being within your Melee Range.\n\nIf you target 4 Allies with '
            'the Metamoran Fusion Dance, the other Characters do not need to '
            'also target you with the Metamoran Fusion Dance, can have a '
            'different Power Level than you, and all Characters combine using '
            'the Maxi Fusion Fusion Method immediately without making a '
            'Performance Skill Check.',
      ),
      UaAdvancementDef(
        name: 'Skill in Fusion',
        description: "You're so skilled at the art of Fusion that you are able "
            'to fuse with almost anyone.',
        prerequisites: '4+ Skill Ranks in Performance',
        tpCost: 5,
        effect: 'You may target any Character with the Metamoran Fusion Dance, '
            'regardless of their Size Category and Power Level.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Mind Control',
    description: "You take over and suppress an enemy's mind, allowing you to "
        'control their body.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic',
    baseTpCost: 20,
    kpCostText: '12(T)',
    kpPerTier: 12,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent and make a Clash (Cognitive vs Cognitive/Morale) '
        'against them. If you win, they gain the Compelled Combat Condition '
        "against a target of your choice. If you lose, you can't target this "
        'Character again with the Mind Control Unique Ability for the rest of '
        'the Combat Encounter.',
  ),
  UniqueAbilityDef(
    name: 'Mind Reading',
    description: 'You are able to touch a target and read their mind, giving you '
        'a glimpse at their thoughts, and potentially aiding you in defending '
        'against them.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Insight Score of 6+, 2+ Skill Ranks in Clairvoyance',
    baseTpCost: 10,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'Increase the Dice Score of your Skill Checks in any Clashes '
        'against an Opponent within your Melee Range by 1.',
    effect: 'Target a Character who is not at Long Range and make a Clash '
        '(Cognitive) against them. If you win, increase your Dodge Rolls and the '
        'Dice Score of any Strike Roll made through the Parry effect of the '
        'Defend Maneuver against that Opponent by 1(T) until the end of your '
        'next turn. Additionally, you may learn any piece of information they '
        'know that you are searching for. The amount of information you gain is '
        'limited by your ARC, some information may be repressed or Characters '
        'may have some unnatural resistance against this ability.',
    advancements: [
      UaAdvancementDef(
        name: 'Combat Telepath',
        description: 'You can enhance your combat abilities by reading the minds '
            'of your enemies.',
        prerequisites: 'Force or Magic Score of 6+',
        tpCost: 5,
        effect: 'If you win the Clash against an Opponent with Mind Reading, '
            'increase your Combat Rolls by 1(bT) against them until the end of '
            'your next turn.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Limited Range Reading',
        description: 'Your ability to read minds has a limited effective range.',
        lockedAdvancements: [],
        tpCostReduction: 2,
        effect: 'You can only target Characters within your Melee Range for the '
            'effects of Mind Reading.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Multi-Form Technique',
    description: 'You possess the ability to split yourself into multiple '
        'separate entities for a time, allowing you to single-handedly '
        'outnumber an opponent.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'N/A',
    baseTpCost: 10,
    kpCostText: '8(bT)',
    kpPerTier: 8,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Create a Duplicate Minion. While you have a Duplicate Minion '
        'created through the Multi-Form Technique, reduce the Tier of Power of '
        'you and any Duplicate Minions created through the Mutli-Form Technique '
        'by 1 (if already Tier of Power 1, reduce your/their Combat Rolls by 2 '
        'instead).\n\nIf you fail a Steadfast Check while you have Duplicate '
        'Minion(s) created by the Multi-Form Technique, those Minions are '
        'Defeated.\n\nAs an Instant Maneuver during your turn, you can erase all '
        'of your Duplicate Minions created by this Unique Ability.\n\nYou can '
        'only possess 1 Duplicate Minion through the effects of Multi-Form '
        'Technique.',
    advancements: [
      UaAdvancementDef(
        name: 'Mass Multi-Form',
        description: 'You become adept in splitting yourself, allowing you to '
            'split yourself into more pieces at once.',
        prerequisites: 'N/A',
        tpCost: 15,
        effect: 'Instead of a single Duplicate Minion, you can create up to 3 '
            'Duplicate Minions. For each Duplicate Minion added after the first, '
            'pay the Ki Point Cost for Multi-Form Technique an additional '
            'time.\n\nInstead of 1, you can possess up to 3 Duplicate Minions '
            'created through the effects of the Multi-Form Technique. These '
            'Minions do not count towards your maximum number of Minions.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Para Para Dance',
    description: 'Your infectious dance moves act as a form of control, allowing '
        'you to force your opponents to jam out with you while you handily '
        'defeat them.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Performance',
    baseTpCost: 10,
    kpCostText: '4(bT) per Action spent',
    maneuverType: 'Standard',
    actionCost: 'Variable (1~3 Actions)',
    minions: 'Non-Minion',
    passiveBonus: 'Reduce the Critical Target of your Performance Skill Checks '
        'by 1.',
    effect: 'Spend up to 3 Actions. Target a number of Opponents up to the '
        'number of Actions spent within a Large Sphere AoE (centered on you). '
        'Make a Skill Clash (Performance vs Performance/Intuition). If you win, '
        'on their next turn, that Opponent loses an equal number of Actions to '
        'the Actions spent on this Unique Ability at the start of their next '
        'turn, and they cannot convert any Actions into Counter Actions if it '
        'would reduce their Actions to less than the amount they need to reduce '
        'through this effect.\n\nFor each Action an Opponent loses through this '
        'effect, reduce their Dodge Rolls by 1(bT) until the start of their next '
        'turn.\n\nUsing Para Para Dance triggers the Exploit Maneuver form all '
        'Opponents who are not at Long Range. If you are hit by an Attacking '
        'Maneuver made through the Exploit Maneuver when trying to use the Para '
        'Para Dance, the Para Para Dance fails (you do not regain any spent '
        'Actions, but you regain the Ki Points spent on the Para Para Dance).',
  ),
  UniqueAbilityDef(
    name: 'Petrification',
    description: 'You possess the capability of turning your opponents into '
        'inanimate objects, preventing them from fighting.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Magic Score of 8+',
    baseTpCost: 20,
    kpCostText: '10(T)',
    kpPerTier: 10,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent who is not at Long Range. Make a Clash (Strike '
        'vs Strike/Dodge) against that Opponent. If you win, they gain the Guard '
        'Down Combat Condition until the end of the current turn. Then, you may '
        'make a Clash (Cognitive vs Cognitive/Corporeal/Impulsive) against them. '
        'If you win this second Clash, they gain a stack of the Slowed Combat '
        'Condition until the end of the Combat Encounter. They can remove a '
        'stack of this Combat Condition by dropping a carried Weapon or removing '
        'a layer of Apparel. Whatever is dropped crumbles to dust and is '
        'destroyed.\n\nIf the user of this Unique Ability is Defeated, all '
        "Characters suffering from the Slowed Combat Condition due to this "
        "character's uses of Petrification stop suffering from those stack(s) of "
        'this Combat Condition.',
    advancements: [
      UaAdvancementDef(
        name: 'Petrification Barrage',
        description: 'You are capable of petrifying others more quickly.',
        prerequisites: 'Tier of Power 4+',
        tpCost: 10,
        effect: 'You may use this Unique Ability an additional time per each '
            'Combat Round. You can gain this Advancement twice.',
      ),
      UaAdvancementDef(
        name: 'Practiced Petrification',
        description: 'You have gotten extremely efficient with your attempts to '
            'petrify others.',
        prerequisites: 'Tier of Power 4+, Magic Score of 12+',
        tpCost: 10,
        effect: 'Reduce the Ki Point Cost of Petrification by 2(T).',
        kpReductionPerTier: 2,
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Physical Retreat',
    description: 'By manipulating your physical body in unnatural ways, '
        "you're able to pull your limbs, your head, or even your vital organs "
        'out of harm\'s way.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Agility and Insight Score of 8+',
    baseTpCost: 10,
    kpCostText: '2(T)',
    kpPerTier: 2,
    maneuverType: 'Counter',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'If you are targeted by an Attacking Maneuver or the Grapple '
        'Maneuver, increase your Defense Value by 2(T) for the duration of this '
        'Maneuver. Increase this bonus by an additional 1(T) if the Attacking '
        'Maneuver was a Called Shot.',
  ),
  UniqueAbilityDef(
    name: 'Portal Creation',
    description: 'You can link two points in space through the use of a portal, '
        'allowing instant travel between the two locations.',
    types: {UniqueAbilityType.magical},
    prerequisites: '3+ Skill Ranks in Use Magic and Clairvoyance',
    baseTpCost: 20,
    kpCostText: '5(bT)',
    kpPerTier: 5,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus:
        'You gain access to the Long Distance Portal Adventuring Maneuver.',
    effect: 'Create a Portal on an adjacent Square. When you do, select another '
        'Square on the Battlefield. Another Portal is created at that point in '
        'space, connecting the two Squares. Any Movement or Attacking Maneuvers '
        'may treat the Squares occupied by Portals as if they were the same '
        'Square. For example, if you are standing on the Square occupied by a '
        'Portal and have a Melee Range of 1 Square, you can make a Physical '
        'Attacking Maneuver against an Opponent who is adjacent to another '
        'Portal.\n\nYou can only possess 2 Portals at one time and can dismiss '
        'any number of Portals as an Instant Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Warp Zone',
        description: 'You are able to warp space in confusing and unpredictable '
            'ways.',
        prerequisites: '4+ Skill Ranks in Use Magic and Clairvoyance',
        tpCost: 6,
        effect: 'You can possess up to 4 Portals at one time. When you use the '
            'Portal Creation Unique Ability while you already possess Portals, '
            'you may choose which Portals the new Portals are connected '
            'to.\n\nFor example, you could connect them to one another and have '
            'two sets of Portals active, or you could connect them to all of the '
            'other Portals and allow for any Portal to lead to any other Portal, '
            'or you could connect all of the new Portals to the Portal adjacent '
            'to you to effectively allow that Portal to lead to three different '
            'places while the other Portals only lead back to it.',
      ),
      UaAdvancementDef(
        name: 'Dimensional Hole',
        description: 'Using a portal to protect yourself from an attack, you '
            'redirect that attack against an enemy.',
        prerequisites: '4+ Skill Ranks in Use Magic',
        tpCost: 10,
        effect: 'If you are targeted by the Basic Attack Maneuver using an '
            'Energy or Magic Foundation, you may spend 1 Counter Action. If you '
            'do, target an Opponent, they become the target of the Attacking '
            'Maneuver instead of you. The Combat Rolls for that Attacking '
            'Maneuver become Urgent.\n\nYou can only use this effect once per '
            'Combat Encounter.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Position Change',
    description: "By linking your position to your opponent's, you are able to "
        'swap places with them on the battlefield.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks of Use Magic, Insight Score of 4+',
    baseTpCost: 12,
    kpCostText: '5(T)',
    kpPerTier: 5,
    maneuverType: 'Instant',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Target a Character within a Destructive Sphere AoE (centered on '
        'you). Make a Clash (Cognitive) against that Character. If you win, swap '
        'your places in the Battlefield.\n\nIf your target was in a Grapple as '
        'the Grappler, also move the Grappled so they are in the Melee Range of '
        'the Grappler (the exact Square is decided by the Grappler). If your '
        'target was the Grappled in a Grapple, they stop being the Grappled and '
        'you become the Grappled in their place.\n\nYou cannot use this Unique '
        'Ability while in a Grapple or in the Pinned Combat Condition.',
    advancements: [
      UaAdvancementDef(
        name: 'Item Swap',
        description:
            'You may grab an item from the linked space rather than a person.',
        prerequisites: '2+ Skill Ranks of Thievery',
        tpCost: 6,
        effect: 'Instead of swapping places with an Opponent, steal a Basic Item '
            "they possess that you're aware of. This cannot be an Accessory they "
            'have equipped.',
      ),
      UaAdvancementDef(
        name: 'People Swap',
        description:
            'You are able to swap around two combatants on the battlefield.',
        prerequisites: '3+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'Instead of a single target, you may choose two targets within '
            'the AoE for the effects of Position Change. If you win the Clash '
            'against both Characters, you may swap their positions on the '
            'Battlefield instead of changing yours.',
      ),
      UaAdvancementDef(
        name: 'Sacrifice Play',
        description: 'You may take the place of an ally who is under attack, '
            'taking the hit for them instead.',
        prerequisites: 'N/A',
        tpCost: 4,
        effect: 'You may use the Position Change Unique Ability as a Counter '
            'Maneuver at the cost of 1 Counter Action. If you do, you must '
            'target a Character targeted by an Attacking Maneuver while you are '
            'not targeted by that same Attacking Maneuver. If you win the Clash, '
            'swap places with them. You become the target of that Attacking '
            'Maneuver and the targeted Character stops being a target for that '
            'Attacking Maneuver. You cannot use a Counter Maneuver in response '
            'to that Attacking Maneuver, but you may still roll your Dodge as '
            'usual.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Precognition',
    description: 'You can witness the future, allowing you to respond '
        'accordingly.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Insight Score of 7+, 2+ Skill Ranks in Use Magic',
    baseTpCost: 30,
    kpCostText: 'N/A',
    maneuverType: 'Instant',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'Increase your Initiative by 1(T) and gain access to the '
        'Foresight Adventuring Maneuver.',
    effect: "Target an Opponent who hasn't done their turn yet. For this Combat "
        'Round, move their place in the Initiative Order to the next turn after '
        'the current one. If you do, you gain 1 Counter Action to use during '
        'their turn and increase your Strike and Dodge Rolls against that '
        'Opponent by 1(T) for the duration of that turn.',
  ),
  UniqueAbilityDef(
    name: 'Sealing',
    description:
        'You can trap your enemies inside of specialized sealing containers.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 4+ and an Insight Score of 6+',
    baseTpCost: 25,
    kpCostText: '12(T)',
    kpPerTier: 12,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Target an Opponent who is not at Long Range. Make a Clash '
        '(Cognitive vs Impulsive/Corporeal) against them. If you win, they gain '
        'the Shaken Combat Condition until the start of your next turn, and you '
        'may make an additional Might Clash against them. If you win this Clash, '
        'target a Basic Item that can be used for Sealing. They are sealed in '
        'the container until the end of your next turn, unless you apply a '
        'Sealing Talisman (or use the effects of a Sealing Bottle), in which '
        'case they are sealed indefinitely.\n\nA sealed Character is removed '
        'from the Combat Encounter and cannot take any Actions, as they are '
        'sealed away within a container. If the container is opened or '
        'destroyed, they return to the Battlefield on a Square adjacent to the '
        'container they were sealed into. If they would return to the Combat '
        "Encounter, reroll their Initiative and, if they haven't taken a turn "
        'this Combat Round, they may immediately take their turn after the '
        'current turn (regardless of their position in the Initiative '
        'Order).\n\nOnly a single being can be sealed into any single container.',
    advancements: [
      UaAdvancementDef(
        name: 'Weapon Seal',
        description: 'By trapping your target inside a weapon, you make it much '
            'harder for them to break free.',
        prerequisites: '3+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'You may use a Weapon as a container for the Sealing Unique '
            'Ability. If you do, you do not need a Sealing Talisman. The Weapon '
            'gains the Phantom Edge Special Quality if it possesses any number '
            'of empty Quality Slots, depicted below:\n\nPhantom Edge: This '
            'Weapon contains another being inside it, enhancing its '
            'effectiveness.\n–Weapon Type: All\n–Prerequisites: A being sealed '
            'inside this Weapon through the Sealing Unique Ability.\n–Quality '
            'Slots: 1\n–Effects: Increase your Wound Rolls by the Tier of Power '
            'Extra Dice (min. 1d4) of the sealed Character.',
      ),
      UaAdvancementDef(
        name: 'Living Seal',
        description: 'You are able to seal a particularly powerful entity inside '
            'of a living person so that they may exert their will over the '
            'sealed prisoner.',
        prerequisites: '4+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'You may use yourself or a Willing Ally within Melee Range as a '
            'container for the Sealing Unique Ability. If you do, you do not '
            'need a Sealing Talisman. The Character used as a container gains '
            'the Living Vessel Awakening as a Level 2 Temporary Awakening with '
            'the target of the Sealing Unique Ability as the Phantasm.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Mafuba',
        description: 'Your sealing technique drains on your own life force to '
            'use.',
        lockedAdvancements: ['Weapon Seal', 'Living Seal'],
        tpCostReduction: 5,
        effect: 'When you use the Sealing Maneuver, if you succeed or not, '
            'reduce your Life Points by 5x the Might of the target. If you score '
            'a Natural Result of 1 on the Might Clash, destroy the container.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Second Sight',
    description: 'You possess the mystical ability to see at extreme distances, '
        'watching events unfold in far away locations.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks of the Clairvoyance Skill, 2+ Skill Ranks of '
        'the Use Magic Skill',
    baseTpCost: 20,
    kpCostText: 'N/A',
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus:
        'You gain access to the Magical Sight Adventuring Maneuver.',
    effect: 'Target a Character on the Battlefield until the start of your next '
        'turn, increase your Strike Rolls against that Character by 2(T) while '
        'they are targeted. If you are targeting a Character at Long Range, they '
        'are not considered to be at Long Range for your Attacking Maneuvers and '
        'effects.',
  ),
  UniqueAbilityDef(
    name: 'Shapeshift',
    description: 'You possess the ability to change your body in many ways, '
        'allowing you to become someone or something else.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Personality or Scholarship Score of 6+',
    baseTpCost: 20,
    kpCostText: '8(bT)',
    kpPerTier: 8,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: 'Variable (1~3 Actions)',
    minions: 'N/A',
    passiveBonus: 'You gain access to the Morph Adventuring Maneuver.',
    effect: 'When you use this Unique Ability, gain a number of the following '
        'effects for 5 turns based on the number of Actions spent on this '
        'Maneuver (you may select the first effect multiple times):\n\nExchange '
        'one of your Body-Category Secondary Racial Traits for a Bestial Trait '
        'of your choice.\n\nChange your Size Category to any other Size Category '
        'except Colossal (this does not destroy any Apparel you have '
        'equipped).\n\nIf you use the Shapeshift Unique Ability while benefiting '
        'from its effects, you remove those effects and regain 6(T) Ki Points '
        'instead of applying the effects again. You may spend 6(T) Ki Points to '
        'apply the effects of Shapeshift immediately after removing the '
        'effects.\n\nIf you are benefiting from the effects of Shapeshift, you '
        'must pay 1/2 of the KP Cost for Shapeshift at the start of each of your '
        'turns. If you do not, remove the effects of Shapeshift.\n\nIf you are '
        'Defeated or fail a Steadfast Check, immediately stop applying the '
        'effects of the Shapeshift Unique Ability.',
    advancements: [
      UaAdvancementDef(
        name: 'Shapeshift Diploma',
        description: 'You have become exceptionally skilled in Shapeshifting; '
            'enjoy your graduation ceremony!',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'The effects of Shapeshift lose the 5 Combat Round limit. '
            'Additionally, reduce the Ki Point Cost of the Shapeshift Unique '
            'Ability by 2(T).',
        kpReductionPerTier: 2,
      ),
      UaAdvancementDef(
        name: 'Quick Shift',
        description: 'You are able to change your form with a mere thought.',
        prerequisites: 'Personality or Scholarship Score of 14+',
        tpCost: 15,
        effect: 'When using the Shapeshift Maneuver, the Action Cost is always 1 '
            'Standard Action and you treat the effects of the Shapeshift '
            'Maneuver as if you spent up to 3 Actions (you decide how many).',
      ),
      UaAdvancementDef(
        name: 'Vehicle Shift',
        description: 'You are able to turn into a vehicle to ferry others '
            'around.',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'If you spend 2+ Actions through Shapeshifting, instead of '
            'selecting effects, you may transform into a Vehicle. Upon doing so, '
            'create a Vehicle with a Craftsmanship Grade equal to 1/2 (rounded '
            'up) of your Tier of Power. You become that Vehicle, following the '
            'below rules:\n\nYou are considered to be Piloting yourself for any '
            'and all effects if you do not have a Pilot. While you have a Pilot, '
            'you may still act as if you are the Pilot during your turn.\n\nYou '
            'may be Piloted as a Vehicle with your consent.\n\nDo not calculate '
            'Life Points, Ki Points, or Capacity when turning into a Vehicle. '
            'You use your own values. A Pilot will use your Ki Points and '
            'Capacity while Piloting, as they would a normal Vehicle.\n\nIf an '
            'effect would destroy the Vehicle except by inflicting Damage, you '
            'have your Life Points reduced to 1 Life Point below your next '
            'Health Threshold and you forcefully stop benefiting from the '
            'effects of Shapeshift.',
      ),
      UaAdvancementDef(
        name: 'Weapon Shift',
        description: 'You possess the unique capability to transform yourself '
            'into a weapon.',
        prerequisites: 'N/A',
        tpCost: 5,
        effect: 'If you spend 2+ Actions through Shapeshifting, instead of '
            'selecting effects, you may transform into a Weapon. Upon doing so, '
            'create a Weapon with a Craftsmanship Grade equal to 1/2 (rounded '
            'up) of your Tier of Power. You become that Weapon, following the '
            'below rules:\n\nYou cannot use any Maneuver except the Movement '
            'Maneuver or Basic Attack Maneuver, but you can only use the Basic '
            'Attack Maneuver if you use yourself as the Weapon for that '
            'Attacking Maneuver.\n\nYou may be wielded as a Weapon with your '
            'consent, but if you are, then you cannot use the Movement '
            'Maneuver.\n\nAny Damage inflicted to yourself as a Weapon is '
            'instead inflicted directly to your Life Points.\n\nIf an effect '
            'would destroy the Weapon except by inflicting Damage, you have your '
            'Life Points reduced to 1 Life Point below your next Health '
            'Threshold and you forcefully stop benefiting from the effects of '
            'Shapeshift.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Specific Form',
        description: 'You are only able to Shapeshift into a specific form.',
        lockedAdvancements: ['Vehicle Shift', 'Weapon Shift'],
        tpCostReduction: 5,
        effect: 'Select a specific Size Category and 0~2 specific Bestial '
            'Traits. When you use the Shapeshift Unique Ability, you must select '
            'that Size Category and any chosen Bestial Traits. You cannot use '
            'the Shapeshift Unique Ability if you cannot spend enough Actions to '
            'apply all of these chosen effects.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Solar Flare',
    description: 'You create a blinding flash of light, rendering anyone who '
        'sees it temporarily disabled.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Force Score of 4+',
    baseTpCost: 10,
    kpCostText: '5(T)',
    kpPerTier: 5,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Make a Clash (Impulsive) against all Opponents within a Huge Cone '
        'AoE (the direction is decided by you). If you win, they suffer from the '
        'Blinded Combat Condition until the end of their next turn.',
    advancements: [
      UaAdvancementDef(
        name: 'Solar Flare x100',
        description: 'Your blinding flash is larger and brighter.',
        prerequisites: 'Force Score of 10+',
        tpCost: 8,
        effect: "Increase the Magnitude of Solar Flare's AoE by 1 category. "
            'While an Opponent suffers from the Blinded Combat Condition through '
            'the effects of Solar Flare, reduce their Clairvoyance Skill Checks '
            'by 4.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Spirit Sword',
    description: 'Creating a shining sword of energy, you unleash a physical '
        "blow without having to place yourself in your enemy's attack range.",
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 8+',
    baseTpCost: 15,
    kpCostText: '3(T)',
    kpPerTier: 3,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Use the Basic Attack Maneuver as an Out-of-Sequence Maneuver. You '
        'must select the Simple (Physical) Profile for this Attacking Maneuver '
        'and it gains the following effects:\n\nApply the effects of either the '
        'Slashing or Piercing Weapon Category to that Attacking Maneuver '
        '(decided upon making the Attacking Maneuver).\n\nYou may increase your '
        'Melee Range by up to 1(bT) Squares for the duration of this Attacking '
        'Maneuver, OR apply a Cone or Sphere AoE to that Attacking '
        'Maneuver.\n\nIf you knock an Opponent through a Health Threshold with '
        'this Attacking Maneuver, they gain the Staggered Combat Condition until '
        'the start of your next turn.',
    advancements: [
      UaAdvancementDef(
        name: 'Spirit Sword Rush',
        description: 'You unleash a series of deadly attacks in a row.',
        prerequisites: 'Agility Score of 6+',
        tpCost: 5,
        effect: 'You may use the Combination (Physical) Profile instead of the '
            'Simple (Physical) Profile for the effects of Spirit Sword.',
      ),
      UaAdvancementDef(
        name: 'Galaxy Spirit Sword',
        description: 'Charging extra energy into your blade, you strike a '
            'single, devastating blow.',
        prerequisites: 'Force or Magic Score of 10+',
        tpCost: 5,
        effect: 'You may use the Powered Profile instead of the Simple '
            '(Physical) Profile for the effects of Spirit Sword.',
      ),
      UaAdvancementDef(
        name: 'Spirit Excalibur',
        description: 'Supercharging your energy weapon, you use a special '
            'technique to land a decisive blow.',
        prerequisites: 'Insight Score of 6+',
        tpCost: 10,
        effect: 'You may use the Signature Technique Maneuver instead of the '
            'Basic Attack Maneuver for the effects of Spirit Sword. If you do, '
            'you must still use the Profile listed for the effects of Spirit '
            'Sword.',
      ),
      UaAdvancementDef(
        name: 'Super Spirit Sword',
        description: 'Your energy weapon persists after your attack, allowing '
            'you to use it again.',
        prerequisites: 'Force or Magic Score of 12+',
        tpCost: 15,
        effect: 'If you deal Damage to an Opponent with the Attacking Maneuver '
            'through the effects of Spirit Sword during your turn, you may use '
            'the Spirit Sword Unique Ability an additional time during this '
            'turn.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Super Ghost Kamikaze Attack',
    description: 'You create a horde of exploding ghostly replicas of yourself '
        'to assault your enemies.',
    types: {UniqueAbilityType.magical, UniqueAbilityType.technical},
    prerequisites: 'Force or Magic Score 10+',
    baseTpCost: 20,
    kpCostText: 'Variable (3(bT) for each Kamikaze Ghost)',
    maneuverType: 'Standard',
    actionCost: 'Variable (1~3 Actions)',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'For each Action spent, create a Kamikaze Ghost! The Kamikaze Ghosts '
        'are Duplicate Minions with their Life Points reduced by 1/2. If a '
        'Character hits a Kamikaze Ghost with an Attacking Maneuver while in '
        'their Melee Range, is hit by the Physical Attack of a Kamikaze Ghost, '
        'or otherwise touches the Kamikaze Ghost in any way (such as either '
        'attempting to use the Grapple or Thrust Maneuver on the other, and it '
        'not failing due to a successful Dodge roll), the Kamikaze Ghost uses '
        'the Basic Attack Maneuver to use the Clearing Profile (targeting a '
        'Square they occupy) with the Small Scale Blast Disadvantage as an '
        'Out-of-Sequence Maneuver (this use of the Clearing Profile may use the '
        'Magic Modifier as its Damage Attribute). Increase the Wound Roll of '
        'this Attacking Maneuver by the amount of Life Points the Kamikaze Ghost '
        'possesses at that moment. After using this effect, the Kamikaze Ghost '
        'is Defeated.',
    advancements: [
      UaAdvancementDef(
        name: 'Balloon Flash Bomber',
        description: 'You create even more of your ghostly duplicates!',
        prerequisites: 'Force or Magic Score 16+',
        tpCost: 10,
        effect: 'When you use the Super Ghost Kamikaze Attack Unique Ability, '
            'you may double the amount of Kamikaze Ghosts you create.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Technique Block',
    description: 'Petty and vindictive, you have specialized in preventing a '
        'specific technique from working against you.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Insight Score of 8+',
    baseTpCost: 4,
    kpCostText: 'Varies',
    maneuverType: 'Counter',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Upon gaining this Unique Ability, select a Signature Technique you '
        'are aware of. When you are targeted by that Signature Technique, you '
        "may use this Unique Ability to reduce that Signature Technique's Strike "
        'Roll is to 0.\n\nThe Ki Point Cost of this Unique Ability is equal to '
        '1/2 of the Ki Point Cost of your selected Signature Technique.',
  ),
  UniqueAbilityDef(
    name: 'Telekinesis',
    description: 'You possess the ability to lift and throw objects or people '
        'with nothing but your mind.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Force or Magic Score of 4+',
    baseTpCost: 15,
    kpCostText: '6(T)',
    kpPerTier: 6,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'If you use the Terrain Lift Maneuver, you may use Magic '
        'instead of Force and you may lift any Feature regardless of the number '
        'of Squares it occupies. Additionally, when using the Terrain Lift '
        'Maneuver, you may instead target any Feature that is not at Long Range. '
        'Additionally, Elemental (Earth) becomes a Favored Element.',
    effect: 'Target a Feature, Opponent, or an unequipped Item within 8 Squares '
        'of you.\n\nIf you targeted an Item, you may use the Throw Maneuver or '
        'Toss Maneuver as an Out-of-Sequence Maneuver as if you were holding '
        'that Item. Instead of this effect, you may gain that Item and '
        "immediately equip it if it's a Weapon.\n\nIf you targeted a Feature, "
        'you may use the Throw Maneuver as an Out-of-Sequence Maneuver as if you '
        'were holding that Feature.\n\nIf you targeted a Character, you may use '
        'the Launch Maneuver as an Out-of-Sequence Maneuver as if you were '
        'Grappling with that Character as the Grappler.',
    advancements: [
      UaAdvancementDef(
        name: 'Psychic Counter',
        description: "You can contest your opponent's telekinesis with your "
            'own.',
        prerequisites: 'N/A',
        tpCost: 4,
        effect: 'If you are targeted by another Character using the Telekinesis '
            'Unique Ability, you may initiate a Might Clash. If you win, they '
            'fail to target you with Telekinesis and you may spend 1 Counter '
            'Action to use the Telekinesis Unique Ability to target that '
            'Opponent as an Out-of-Sequence Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Weapon Fixer',
        description: 'You are able to telekinetically put Weapons back together.',
        prerequisites: 'Magical Materialization',
        tpCost: 5,
        effect: 'If you equip a Weapon through the effects of the Telekinesis '
            'Unique Ability, that Weapon may regain Life Points equal to twice '
            'your Might.',
      ),
      UaAdvancementDef(
        name: 'Advanced Telekinesis',
        description: 'You can throw multiple targets telekinetically.',
        prerequisites: 'Force or Magic Score of 10+',
        tpCost: 8,
        effect: 'You can select an additional target to use the Throw Maneuver '
            'against through the effects of Telekinesis.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Telekinetic Cushion',
    description: 'You use your telekinetic powers to protect your comrades from '
        'powerful collisions.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Telekinesis Unique Ability',
    baseTpCost: 10,
    kpCostText: '2(T)',
    kpPerTier: 2,
    maneuverType: 'Counter Maneuver',
    actionCost: '1 Counter Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: "If an Ally would be moved by an Opponent's effect, you may use this "
        'Counter Maneuver to reduce the amount of Squares they would be moved by '
        "a number of Squares equal to your Might. If that Ally's movements stops "
        "without causing Collision, with that Ally's permission, you may then "
        'move that Ally any number of Squares up to your Might in a straight '
        'line.',
  ),
  UniqueAbilityDef(
    name: 'Telepathy',
    description: 'You possess the ability to project your thoughts and read the '
        'forethoughts of others, allowing you to communicate without a single '
        'sound.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Clairvoyance',
    baseTpCost: 8,
    kpCostText: 'N/A',
    maneuverType: 'Instant',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'If you are in the Melee Range of a Character you are '
        'telepathically communicating with, increase both of your Defense '
        'Values by 1(bT). This effect does not stack if multiple Characters '
        "with the Telepathy Unique Ability are in each other's Melee Ranges. "
        'While outside of a Combat Encounter, you can communicate with anyone '
        'you can see (this includes if you see them through the Magical Sight '
        'Adventuring Maneuver).',
    effect: 'Target a number of Characters within your Battlefield up to your '
        'number of Clairvoyance Skill Ranks. Until the end of the Combat Round, '
        'you may communicate with those Characters telepathically.',
    advancements: [
      UaAdvancementDef(
        name: 'Wide-Range Telepathy',
        description: 'Your telepathic abilities have limitless range.',
        prerequisites: '4+ Skill Ranks in Clairvoyance',
        tpCost: 4,
        effect: 'You can select any number of targets with Telepathy. '
            'Additionally, you can target Characters outside of your '
            'Battlefield that you cannot see.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Threaded Energy',
    description: 'You can create a minefield of energy, attacking anyone within '
        'the range of energy you created.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Energy Web Advancement',
    baseTpCost: 12,
    kpCostText: '6(T)',
    kpPerTier: 6,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'The Squares within a Large Sphere AoE (centered on you) become your '
        'Explosive Web. If an Opponent moves into or through these Squares, you '
        'may use the Basic Attack Maneuver against them as an Out-of-Sequence '
        'Maneuver, but the Attacking Maneuver must be of the Simple Profile '
        '(Energy Foundation).\n\nYou can only target each Opponent with this '
        'effect once per Combat Round.\n\nYou cannot use this Unique Ability '
        'while you possess an Explosive Web, and must pay the Ki Point Cost of '
        'this Unique Ability at the start of each of your turns or remove your '
        'Explosive Web. You may remove your Explosive Web as an Instant '
        'Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Web Save',
        description: 'You may move your allies freely along your energy web.',
        prerequisites: 'N/A',
        tpCost: 6,
        effect: 'As an Instant Maneuver, if a willing Ally is in the AoE of your '
            'Explosive Web, you may move them to any other Square on your '
            'Explosive Web.',
      ),
      UaAdvancementDef(
        name: 'Casting a Wide Net',
        description: 'Your energy web is even larger than usual.',
        prerequisites: 'Force or Magic Score of 12+',
        tpCost: 7,
        effect: 'Increase the Magnitude of your Explosive Web to Destructive.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Time Freeze',
    description: 'You can momentarily stop time for everyone else, allowing you '
        'to do as you please.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Magic Score 8+, 2+ Skill Ranks in Use Magic',
    baseTpCost: 40,
    kpCostText: '14(bT)',
    kpPerTier: 14,
    kpUsesBaseTier: true,
    maneuverType: 'Instant',
    actionCost: 'N/A',
    minions: 'N/A',
    passiveBonus: 'You are not affected by the usual rules during another '
        "Character's Frozen Turn.",
    effect: 'Immediately begin a Frozen Turn. A Frozen Turn is a unique Turn in '
        'which you have 2 Actions to use during this Turn, and the Turn ends '
        'when both of those Actions are used (you cannot use any other Actions '
        'you possess during a Frozen Turn).\n\nDuring a Frozen Turn you can only '
        'use Standard Maneuvers and cannot Ki Wager, use Instant or '
        'Out-of-Sequence Maneuvers, use Combat Recovery, use the Power Up '
        'Maneuver, the Energy Charge Maneuver, apply Energy Charges to Attacking '
        'Maneuvers through the effects of Traits, use any Special Maneuvers that '
        'target another Character, or use any Unique Abilities.\n\nDuring a '
        'Frozen Turn, other Characters cannot use Counter Maneuvers, Instant '
        'Maneuvers, or Out-of-Sequence Maneuvers (except Surges). Additionally, '
        'their Defense Value is reduced by 2(bT) and their Perception Skill '
        'Bonus is reduced by 2.',
    advancements: [
      UaAdvancementDef(
        name: 'Improved Time Freeze',
        description: 'You are extremely adept at stopping time.',
        prerequisites: '5+ Skill Ranks in Use Magic',
        tpCost: 10,
        effect: 'Reduce the Ki Point Cost of Time Freeze by 2(T).',
        kpReductionPerTier: 2,
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Pained Time',
        description: 'Holding back the flow of time drains your physical '
            'stamina.',
        lockedAdvancements: [],
        tpCostReduction: 10,
        effect: 'When you finish your Frozen Turn, reduce your Life Points by '
            '1/5 of your Maximum Life Points.',
      ),
      UaRestrictionDef(
        name: 'Limited Time Freeze',
        description: 'While time is frozen, you cannot harm the world around '
            'you.',
        lockedAdvancements: [],
        tpCostReduction: 10,
        effect: 'You cannot use any Attacking Maneuvers during your Frozen '
            'Turn.',
      ),
      UaRestrictionDef(
        name: 'Straining Time Freeze',
        description: 'Acting while time is frozen takes more concentration than '
            'usual.',
        lockedAdvancements: ['Improved Time Freeze'],
        tpCostReduction: 5,
        effect: 'Increase the Ki Point Cost of all Maneuvers during your Frozen '
            'Turn by 2(T).',
      ),
      UaRestrictionDef(
        name: 'Difficult Time Freeze',
        description: 'While not impossible, you find it difficult to affect the '
            'world around you while time is frozen.',
        lockedAdvancements: ['Improved Time Freeze'],
        tpCostReduction: 5,
        effect: 'You can only use 1 Attacking Maneuver during a Frozen Turn.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Tornado Attack',
    description: 'You spin in place, generating a cyclone of wind around you.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Agility Score of 6+',
    baseTpCost: 12,
    kpCostText: '4(T)',
    kpPerTier: 4,
    maneuverType: 'Standard',
    actionCost: '2 Actions',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'You begin Spinning until the start of your next turn. While you are '
        'Spinning, increase your Dodge Rolls by 1(T) and reduce all Damage you '
        'take by your Agility Modifier. If an Opponent misses you with an '
        'Attacking Maneuver or deals 0 Damage to you with an Attacking Maneuver, '
        'you may use the Basic Attack Maneuver as an Out-of-Sequence Maneuver. '
        'If you do, you must target that Opponent with that Attacking Maneuver '
        'and you must select either the Launching, Sweeping, or Elemental (Wind) '
        'Profile for that Attacking Maneuver.\n\nIf you start your next turn '
        'while Spinning with an Opponent within your Melee Range, before you '
        'stop Spinning, use the Thrust Maneuver against that Opponent as an '
        'Out-of-Sequence Maneuver.',
    advancements: [
      UaAdvancementDef(
        name: 'Spin to Win',
        description: 'While spinning like a top, you collide with an enemy, '
            'sending them flying.',
        prerequisites: 'N/A',
        tpCost: 4,
        effect: 'While Spinning, if you end your use of the Movement Maneuver '
            'with an adjacent Opponent, you may use the Thrust Maneuver as an '
            'Out-of-Sequence Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Tornado Chaser',
        description: 'When you start spinning, you dart in the direction of your '
            'opponent.',
        prerequisites: 'Spin to Win',
        tpCost: 4,
        effect: 'Once you begin Spinning, you may use the Movement Maneuver as '
            'an Out-of-Sequence Maneuver.',
      ),
      UaAdvancementDef(
        name: 'Massive Tornado',
        description: 'The cyclone surrounding you extends out beyond your '
            'physical reach, striking enemies with the force of the wind alone.',
        prerequisites: 'Insight Score of 6+',
        tpCost: 4,
        effect: 'While you are Spinning, increase your Melee Range by 2 and the '
            'AoE of the Sweeping Profile by 1 Magnitude.',
      ),
      UaAdvancementDef(
        name: 'Hyper Tornado',
        description: 'The force of the winds you generate slams into your '
            'enemies like a slab of concrete.',
        prerequisites: 'Agility Score of 10+',
        tpCost: 6,
        effect: 'While you are Spinning, if you win the Clash for the effects of '
            "the Thrust Maneuver against an Opponent, reduce that Opponent's "
            'Life Points by 1/2 of your Agility Modifier.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Dizziness',
        description: "When you finish spinning around, you're left disoriented.",
        lockedAdvancements: ['Hyper Tornado', 'Tornado Chaser'],
        tpCostReduction: 4,
        effect: 'When you stop Spinning, gain the Prone and Impediment Combat '
            'Conditions until the start of your next turn.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'Trap Attack',
    description: 'Upon using a technique, you can halt it, allowing it to strike '
        'only when you wish it to.',
    types: {UniqueAbilityType.technical},
    prerequisites: 'Insight Score 4+, Force or Magic Score 4+',
    baseTpCost: 15,
    kpCostText: '5(T)',
    kpPerTier: 5,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'Select a Signature Technique of the Energy or Magic Foundation you '
        'possess and a Square within a Large Sphere AoE (centered on you), and '
        'record both the Square and the Signature Technique. That Square becomes '
        'a Trap Square with that Signature Technique stored in it – you cannot '
        'use the Signature Technique Maneuver to select that Signature Technique '
        'while that Trap Square exists. If an Opponent moves into or through '
        'that Square, you may use the Signature Technique Maneuver to use your '
        'selected Signature Technique as an Out-of-Sequence Maneuver.\n\nIf you '
        'possess a Trap Square, you may use the Signature Technique Maneuver to '
        'use the stored Signature Technique as an Instant Maneuver. If you do, '
        'your Attacking Maneuver must target someone within a Sphere AoE '
        '(centered on the Trap Square). If your Signature Technique has an AoE, '
        'instead simply apply that AoE (starting from the Trap Square) and '
        'target all Characters in it.\n\nAfter you use the stored Signature '
        'Technique in the Trap Square, remove the Trap Square. You can only '
        'possess 1 Trap Square at a time.\n\nWhen you use the Signature '
        'Technique Maneuver through the effects of Trap Attack, make a Clash '
        '(Cognitive vs Impulsive) against your Opponent. If you win, that '
        'Opponent suffers from the Guard Down Combat Condition for the duration '
        'of that Attacking Maneuver.',
  ),
  UniqueAbilityDef(
    name: 'Warped Evolution',
    description: 'You twist and warp and contort someone into a monstrous, '
        'grotesque version of themself.',
    types: {UniqueAbilityType.magical},
    prerequisites: '2+ Skill Ranks in Use Magic, Demon Clansmen Factor',
    baseTpCost: 20,
    kpCostText: '8(bT)',
    kpPerTier: 8,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: "Target an Ally. Make a Clash (Cognitive) against that Ally. If you "
        "win, halve that Ally's current Life Points, but they gain the Dark "
        'Evolution Awakening as a Level 2 Temporary Awakening.\n\nYou can only '
        'use the Warped Evolution Unique Ability once per Combat Encounter.',
  ),
  UniqueAbilityDef(
    name: 'Weather Summoning',
    description: 'You summon dangerous and destructive weather to do your '
        'bidding.',
    types: {UniqueAbilityType.technical, UniqueAbilityType.magical},
    prerequisites: 'Tier of Power 2+',
    baseTpCost: 10,
    kpCostText: '5(bT)',
    kpPerTier: 5,
    kpUsesBaseTier: true,
    maneuverType: 'Out-of-Sequence',
    actionCost: 'N/A',
    minions: 'Non-Minion',
    passiveBonus: 'N/A',
    effect: 'When you use the Power Up Maneuver, you may change the Battle '
        'Weather affecting the entire Battlefield to the Storm or Tornado Battle '
        'Weather of the Natural Weather Tier until the end of your next '
        'turn.\n\nYou are not affected by the effects of any Battle Weather that '
        'you create through this effect.',
    advancements: [
      UaAdvancementDef(
        name: 'Magical Weather',
        description: "You are able to materialize environmental effects that "
            "aren't already present.",
        prerequisites: '2+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'You may create any type of Battle Weather through the effects '
            'of Weather Summoning.',
      ),
      UaAdvancementDef(
        name: 'Lasting Weather',
        description:
            'The supernatural storms you create remain until dismissed.',
        prerequisites: '2+ Skill Ranks in Survival',
        tpCost: 10,
        effect: 'Instead of until the end of your next turn, the Battle Weather '
            'remains in effect indefinitely.\n\nAt the start of each of your '
            'turns, you may pay the Ki Point Cost of this Unique Ability to '
            'maintain the Battle Weather. If you do not, the Battle Weather is '
            'removed.',
      ),
      UaAdvancementDef(
        name: 'Empowered Weather',
        description: 'The impact of your summoned storms is greater than '
            'normal.',
        prerequisites: 'Tier of Power 3+',
        tpCost: 10,
        effect: 'You may increase the Ki Point Cost of this Unique Ability by '
            "2(T) upon using it so your Battle Weather's Weather Tier is "
            'Unnatural.',
      ),
      UaAdvancementDef(
        name: 'Destructive Weather',
        description: 'When you create foul weather, the effects are '
            'apocalyptic.',
        prerequisites: 'Tier of Power 4+',
        tpCost: 10,
        effect: 'You may increase the Ki Point Cost of this Unique Ability by '
            "3(T) upon using it so your Battle Weather's Weather Tier is "
            'Cataclysmic.',
      ),
    ],
    restrictions: [
      UaRestrictionDef(
        name: 'Specific Weather Summoning',
        description: 'Your magic can only produce a specific kind of weather.',
        lockedAdvancements: [],
        tpCostReduction: 2,
        effect: 'Select a Battle Weather. You can only apply your chosen Battle '
            'Weather through the effects of Weather Summoning.',
      ),
    ],
  ),
  UniqueAbilityDef(
    name: 'World Forging',
    description: 'You are able to conjure objects into the world around you, '
        'shaping the world as you see fit.',
    types: {UniqueAbilityType.magical},
    prerequisites: 'Magical Materialization',
    baseTpCost: 12,
    kpCostText: '2(bT)',
    kpPerTier: 2,
    kpUsesBaseTier: true,
    maneuverType: 'Standard',
    actionCost: '1 Action',
    minions: 'N/A',
    passiveBonus: 'N/A',
    effect: 'You may create a Feature that occupies a single Square. Make a '
        'Qualified Use Magic Skill Check. On a success, you create the Feature '
        'within a Sphere AoE, centered on yourself. Features created through '
        'World Forging have a default Hardness Rank of 0, and cover a number of '
        'Squares up to twice your ranks in Use Magic, in whatever shape you '
        'designate. For every Difficulty Category you pass after Qualified, '
        'increase the maximum Hardness Rank of that piece of terrain by 1, up to '
        'a maximum Hardness Rank of 3 (you may still decide to create it at a '
        'lower Hardness Rank).',
    advancements: [
      UaAdvancementDef(
        name: 'Mass Construction',
        description: 'You can create multiple pieces of terrain at once.',
        prerequisites: 'Force or Magic Score 8+',
        tpCost: 3,
        effect: 'You can make Features that cover Squares up to 1/2 of your '
            'Might. For each Feature you make after the first, increase the Ki '
            'Point Cost of World Forging by 1(T).',
      ),
      UaAdvancementDef(
        name: 'Advanced Construction',
        description: 'You create the strongest, sturdies objects possible.',
        prerequisites: '4+ Skill Ranks in Use Magic',
        tpCost: 5,
        effect: 'Treat the number of Difficulty Categories beyond Qualified you '
            'exceed as 1 more than you exceeded for the effects of World Forging '
            '(this effect can allow you to exceed Grandmaster). Additionally, '
            'increase the maximum Hardness Rank of your created Features to 4.',
      ),
    ],
  ),
];

/// Looks up a Unique Ability by exact [name], or `null` if unknown.
UniqueAbilityDef? uniqueAbilityByName(String name) {
  for (final a in kDbuUniqueAbilities) {
    if (a.name == name) return a;
  }
  return null;
}
