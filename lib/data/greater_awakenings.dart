import 'dbu_rules.dart';
import 'race_traits.dart';
import 'transformations.dart';

/// All Greater Awakenings from dbu-rpg.com, transcribed as [TransformationDef]s.
///
/// Greater Awakenings are more powerful than Lesser ones and count against a
/// separate, smaller Awakening Limit (see [kAwakeningLimits]). Large auxiliary
/// sub-systems on a few entries (Commander's Minion Class / Leadership Traits,
/// Class Avatar's Class Mark Quality, etc.) are condensed to short notes,
/// matching the transcription convention used for Lesser Awakenings.
const List<TransformationDef> kDbuGreaterAwakenings = [
  // ============================================================== ANY RACE ===
  TransformationDef(
    name: 'Android Conversion',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any Race (except Android or Robot)',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Life as an Android',
        description: 'Inside a sturdy casing, your brain has been soaked in '
            'a special cocktail of fluids to keep it alive, while replacing '
            'your organic body with a metal replica.\n'
            '(1)-[Passive]: Reduce your Racial Life Modifier by 3 (can '
            'become negative).\n'
            '(2)-[Passive]: Reduce your Soak Value by 1(bT).\n'
            '(3)-[Passive]: Halve your Surgency.\n'
            '(4)-[Passive]: Your Race is also considered Android for any '
            "Transformation's Racial Requirements.\n"
            '(5)-[Passive]: Upon gaining this Awakening, gain the Energy Core '
            'and Technological Being Racial Traits (select Construct for the '
            '2nd effect of Technological Being).',
        automation: [
          // (1) -3 Racial Life Modifier = -3 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: -3,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) -1(bT) Soak Value. ((3) Halve your Surgency is
          // multiplicative — shown as text, not automated.)
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: -1,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'At Peace',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Attained Peace',
        description: '(1)-[Passive]: Halve the penalties to your Combat '
            'Rolls from the Shaken or Guard Down Combat Conditions.\n'
            '(2)-[Passive]: While not suffering from any Combat Conditions, '
            'increase your Combat Rolls, Surgency, and Saving Throws by '
            '1(T).\n'
            '(3)-[Passive]: The Condition Recovery effect of Combat Recovery '
            'only halves the Life regained instead of forgoing it.\n'
            '(4)-[Passive]: While not suffering from any Combat Conditions, '
            'your Combat Recovery does not trigger the Exploit Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you use Combat Recovery, regain '
            'Life or Ki Points equal to 1/2 of your Surgency.\n'
            '(6)-[Triggered, 1/Round]: While free of Combat Conditions, if '
            'you use a Signature Technique, you may use your Surgency as its '
            'Damage Attribute.\n'
            '(7)-[Triggered, 1/Encounter]: If an Opponent would inflict a '
            'Combat Condition on you from losing a Clash, you may choose not '
            'to gain it.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Beatdown Specialist',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Debilitating Fighting Style',
        description: '(1)-[Passive]: Increase your Might by 1(T) for Might '
            'Clashes made through Debilitating Fighting Style.\n'
            '(2)-[Passive]: Increase your Combat Rolls by 1(T) while 1+ '
            'Opponent is below the Bruised Threshold.\n'
            '(3)-[Passive]: While 1+ Opponent is below the Injured '
            'Threshold, increase your Wound Rolls by 1(T).\n'
            '(4)-[Triggered, 1/Round]: If you deal Damage to an Opponent, '
            'make a Might Clash; if you win, they gain a stack of Broken or '
            'Guard Down until the end of your turn.\n'
            '(5)-[Triggered, 1/Round]: If you deal Damage to a Broken '
            'Opponent, make a Might Clash; if you win, they are knocked '
            'Prone.\n'
            '(6)-[Triggered, 1/Round]: If you deal Damage to a Guard Down '
            'Opponent, make a Might Clash; if you win, they gain Staggered '
            'until the start of your next turn.\n'
            '(7)-[Triggered, 1/Encounter]: If you win a Might Clash for any '
            'effect here, use the Basic Attack or Signature Technique '
            'Maneuver Out-of-Sequence.\n'
            '(8)-[Triggered, 1/Encounter]: If you hit a Prone and/or '
            'Staggered Opponent, apply an Energy Charge to that attack.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Body Suit',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Possess Maneuver',
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'My Ideal Body',
        description: 'You have created the host that you prefer to stay in, '
            'and you ensure that its power grows as yours does.\n'
            '(1)-[Passive]: Reduce your Racial Life Modifier by 3.\n'
            '(2)-[Passive]: While not a Possessing Character, reduce all '
            'your Combat Rolls and Soak Value by 1(bT).\n'
            '(3)-[Passive]: While a Possessing Character, the host (with '
            'your Overtaken stack) has its Soak Value increased by 2(T).\n'
            '(4)-[Passive]: Whenever you gain a Power Level or Awakening, so '
            'does your Claimed Body (an Awakening of the same Type, ARC '
            'decides).\n'
            "(5)-[Passive, Ruling]: Upon gaining this Awakening, create a "
            "'Claimed Body' Character (Robot/Creature Minion Race, your "
            'Power Level, equal Lesser Awakenings, 1 fewer Greater '
            'Awakening); uncontrolled until Possessed.\n'
            '(6)-[Passive]: Your Claimed Body ignores the 9th effect of '
            'Overtaken.\n'
            '(7)-[Triggered]: You may spend Karma Points to stop your '
            'Claimed Body from dying.\n'
            '(8)-[Triggered/Start of Combat Encounter]: Use the Possess '
            'Maneuver Out-of-Sequence (only targeting your Claimed Body).\n'
            '(9)-[Automatic]: If your Claimed Body dies, lose this '
            'Awakening.',
        automation: [
          // (1) -3 Racial Life Modifier = -3 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: -3,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Class Avatar',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Path of the Avatar',
        description: 'Your destiny is decided; the path you walk will follow '
            'one of the chosen roads, leading you to specialize in your '
            'destined combat role.\n'
            "(1)-[Ruling]: Upon gaining this Awakening, select your "
            "'Destined Class': Hero, Elite, or Berserker (must match your "
            'Class Up choice if you have it).\n'
            '(2)-[Passive]: Per Destined Class: Hero — +1(T) Dodge and Soak; '
            'Elite — +1(T) Strike and Surgency; Berserker — +1(T) Wound and '
            'Might.\n'
            '(3)-[Passive]: If you have the Class Up Awakening, increase '
            'your Combat Rolls and Soak Value by 1(T).\n'
            '(4)-[Passive]: The Class Up Awakening does not count towards '
            'your Awakening Limit.\n'
            '(5)-[Adventuring]: You may spend an hour outside of a Combat '
            "Encounter to apply the 'Class Mark' Apparel Quality to any of "
            'your pieces of Apparel if they have a Quality Slot free.\n'
            '\n'
            'Class Mark Apparel Quality — This piece of Apparel has the mark '
            'of your destiny emblazoned on it. Effects: Depending on your '
            'Destined Class, apply the following effects:\n'
            'Hero [Passive]: While you have 2+ stacks of Power, increase this '
            "piece of Apparel's Apparel Bonus by 1(bT).\n"
            'Elite [Passive]: Increase your Surgency by 1/2 (rounded up) of '
            'the Apparel Bonus.\n'
            'Berserker [Passive]: Increase the Wound Rolls of your Signature '
            'Techniques by the Apparel Bonus.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Destined Class',
            options: [
              TraitOption(
                name: 'Hero',
                description: '+1(T) Dodge and Soak.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.dodge, AffectedStat.soak],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Elite',
                description: '+1(T) Strike and Surgency.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.strike,
                      AffectedStat.surgency,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Berserker',
                description: '+1(T) Wound and Might.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                      AffectedStat.might,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
            ],
          ),
        ],
        automation: [
          // (3) If you have the Class Up Awakening (Awakenings are always
          // active while owned): +1(T) Combat Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedTransformationActive,
            conditionTransformationName: 'Class Up',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Combat Connoisseur',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Holding Back Maneuver',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Staggered Reveal',
        description: 'Y\n'
            '(1)-[Triggered, Resource]: If you use the Holding Back '
            'Maneuver to remove a stack of Holding Back, gain a stack of '
            "'Revealed'.\n"
            '(2)-[Passive]: While you possess a stack of Revealed, you '
            'cannot use the Holding Back Maneuver to gain stacks of '
            'Holding Back.\n'
            '(3)-[Passive]: While you possess a stack of Revealed, '
            'increase your Combat Rolls and Soak Value by 1(bT).\n'
            '(4)-[Passive]: While you possess no stacks of Revealed and at '
            'least 1 stack of Holding Back, set the Ki Point Cost of your '
            'Attacking Maneuvers made through the Basic Attack Maneuver to '
            'their Minimum Ki Point Cost.\n'
            '(5)-[Triggered]: If you gain a stack of Revealed, regain '
            '3(bT) Life and Ki Points.\n'
            '(6)-[Triggered, 1/Round]: If you gain a stack of Revealed, '
            'you may ignore the effects of your Holding Back stacks and '
            'treat yourself as if you have no stacks of Holding Back until '
            'the start of your next turn.\n'
            '(7)-[Triggered, 1/Round]: If you would pay the Ki Point Cost '
            'for a Maneuver, you may spend stacks of Revealed instead of '
            'Ki Points. Each stack of Revealed is worth 4(bT) Ki Points '
            'for this effect.\n'
            '(8)-[Triggered, 1/Round]: If you lose your final stack of '
            'Revealed, you may use the Holding Back Maneuver as an '
            'Out-of-Sequence Maneuver. This use of the Holding Back '
            "Maneuver can occur even if you've used it previously this "
            'Combat Round.\n'
            '(9)-[Triggered/Power, 1/Round]: Lose a stack of Holding Back '
            'and gain a stack of Revealed. If you did, then you may use '
            'the Basic Attack Maneuver as an Out-of-Sequence Maneuver.',
        automation: [
          // (3) +1(bT) Combat Rolls and Soak Value while possessing a
          // stack of Revealed (track a "Revealed" Resource row).
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Revealed',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Commander',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Master of Minions Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Leadership Methods',
        description: 'No matter what methods you use, no one can deny that '
            'you are an effective leader.\n'
            '(1)-[Passive]: Duplicate Minions are not considered Minions for '
            'Commander Traits.\n'
            '(2)-[Passive]: Reduce your Combat Rolls and Soak Value by '
            '1(bT).\n'
            '(3)-[Passive]: Increase the Combat Rolls and Soak Value of all '
            'your Minions by 1(bT).\n'
            '(4)-[Passive]: All of your Minions gain a Minion Class Trait '
            'while they are your Minion (you choose which; detailed below).\n'
            '(5)-[Passive]: Upon gaining access to this Awakening, select and '
            'gain access to a Leadership Trait while you possess this '
            'Awakening (choose below).\n'
            '(6)-[Passive]: While a Possessing Character, the host gains '
            'Commander as a Level 2 Temporary Awakening (your Leadership '
            'Trait).\n'
            '(7)-[1/Encounter]: As an Instant Maneuver, a selected Minion '
            'uses a Surge of your choice Out-of-Sequence.\n'
            '\n'
            'Minion Class Traits (applied to your Minions):\n'
            'Ascended Minion — (1)-[Prerequisite]: No other Minion belonging '
            'to your Master has the Ascended Minion Trait. (2)-[Passive]: This '
            'Minion is a Special Minion. (3)-[Passive]: Increase your Combat '
            'Rolls and Saving Throws by 1(bT). (4)-[Passive]: Through the Life '
            "Points Rule for Minions, this Minion's Life Points are only "
            'halved, instead of reduced to 1/4.\n'
            'Pretty One — (1)-[Passive]: Increase your Personality Modifier by '
            '1(T). (2)-[Passive]: While Personality is your highest Attribute '
            'Score, increase your Combat Rolls and Initiative Value by 1(bT). '
            '(3)-[Triggered/Start of Turn]: Use the Hype Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            'Weird One with the Freaky Power — (1)-[Passive]: Increase your '
            'Might and Saving Throws by 1(T). (2)-[Passive]: Reduce the Ki '
            'Point Cost of your Unique Abilities by 1(T). (3)-[Passive]: Upon '
            'gaining this Trait, gain access to a Unique Ability with a TP '
            'Cost of 25 or less that you meet the Prerequisites for.\n'
            'Big Tough Stupid One — (1)-[Passive]: Increase your Attribute '
            'Modifiers (FO/TE/MA) by 1(T). (2)-[Passive]: While below the '
            'Injured Health Threshold, increase your Soak Value by 1(T). '
            '(3)-[1/Round]: You may use the Defend Maneuver without spending a '
            'Counter Action; if you do, you must use either the Direct Hit or '
            'Guard options of the Defend Maneuver.\n'
            'Misfit Minions — (1)-[Passive]: While adjacent to another Minion '
            'with this Trait, increase your Combat Rolls by 1(T). '
            '(2)-[Triggered, 1/Round]: If another Minion with this Trait uses '
            'an Attacking Maneuver, you may use the United Attack Maneuver '
            'without spending an Action through its effects. (3)-[Triggered, '
            '1/Encounter]: If another Minion with this Trait is Defeated, you '
            'may halve your Life Points; they regain Life Points equal to your '
            'current Life Points after applying this effect.\n'
            'Comic Relief — (1)-[Passive]: Increase your Soak Value and '
            'Surgency by 1(T). (2)-[Passive]: Increase the Skill Bonus of your '
            'Skills by 1. (3)-[Triggered, 1/Round]: After rolling a Skill for '
            'a Clash and knowing the result, you may reroll (take the second '
            'result). (4)-[Triggered/Defeated]: Place yourself on any '
            'unoccupied Square within the Battlefield and regain Life Points '
            'equal to your Surgency; then you may make a Clash (Stealth vs '
            'Perception/Clairvoyance) against all Opponents — if you win, you '
            'are Hidden from that Opponent.',
        automation: [
          // (2) -1(bT) Combat Rolls and Soak Value (the Minion buffs are
          // manual — Minions aren't modelled).
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: -1,
            tierScaling: TierScaling.base,
          ),
        ],
        // (5) select a Leadership Trait — mostly Minion-directed / situational,
        // so verbatim text (no clean always-on self-buff to automate).
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Leadership Trait',
            options: [
              TraitOption(
                name: 'Battlefield General',
                description: '(1)-[Passive]: Ignore the 2nd effect of '
                    'Leadership Methods. (2)-[Passive]: If you have no Minions, '
                    'increase your Combat Rolls by 1(T). (3)-[Triggered, '
                    '1/Round]: If you deal Damage to an Opponent with an '
                    'Attacking Maneuver, select one of your Minions. That '
                    'Minion may use the Basic Attack Maneuver as an '
                    'Out-of-Sequence Maneuver.',
              ),
              TraitOption(
                name: 'Blitzkrieg Commander',
                description: '(1)-[Passive]: Increase the Strike and Wound '
                    'Rolls of your Minions by 1(bT). (2)-[Passive]: Reduce the '
                    'Defense Value and Soak Value of your Minions by 1(bT). '
                    '(3)-[Triggered/Start of Turn]: Target up to 3 of your '
                    'Minions. They each make the Basic Attack Maneuver as an '
                    'Out-of-Sequence Maneuver (you decide the sequence). Skip '
                    'the next turn of these Minions and they suffer from the '
                    'Guard Down Combat Condition until the start of your next '
                    'turn.',
              ),
              TraitOption(
                name: 'Iron Wall Commander',
                description: '(1)-[Passive]: Increase the Defense Value and '
                    'Soak Value of your Minions by 1(bT). (2)-[Passive]: '
                    'Reduce the Strike and Wound Rolls of your Minions by '
                    '1(bT). (3)-[Triggered, 3/Round]: If you or an Ally are '
                    'targeted by an Attacking Maneuver that does not possess '
                    'an AoE while one of your Minions is adjacent to '
                    "you/them, you may swap your/that Ally's position on the "
                    'Battlefield with that Minion and change the target of the '
                    'Attacking Maneuver to that Minion.',
              ),
              TraitOption(
                name: 'Minion Collector',
                description: '(1)-[Passive]: Your Minions have their Maximum '
                    'Life Points increased by 2 for each Power Level reached '
                    '(after any modifications). (2)-[Adventurous]: You gain '
                    'access to the Recruit Adventure Maneuver. '
                    '(3)-[Adventurous]: Halve the Time Cost of the Recruit '
                    'Adventure Maneuver.',
              ),
              TraitOption(
                name: 'Strong Bond',
                description: '(1)-[Passive]: While you only have 1 Minion and '
                    'that Minion possesses the Ascended Minion Minion Class '
                    'Trait, ignore the 2nd effect of Leadership Methods. '
                    '(2)-[Triggered/Start of Combat Round]: If your only '
                    'Minion possesses the Ascended Minion Minion Class Trait, '
                    'that Minion gains 1 Action. (3)-[Triggered, 1/Round]: If '
                    'your Minion with the Ascended Minion Minion Class Trait '
                    'deals Damage to an Opponent with an Attacking Maneuver, '
                    'you may use the Basic Attack Maneuver as an '
                    'Out-of-Sequence Maneuver. (4)-[Triggered, 1/Encounter]: '
                    'If your Minion with the Ascended Minion Minion Class '
                    'Trait is Defeated, you may halve your Life Points; if you '
                    'do, they regain Life Points equal to your current Life '
                    'Points after halving. (5)-[Triggered/Defeated]: You '
                    'cannot regain Life Points. Take control of your Minion '
                    'with the Ascended Minion Minion Class Trait as if they '
                    'were a typical Character, ignoring all rules for Minions.',
              ),
              TraitOption(
                name: 'Master of Misfits',
                description: '(1)-[Passive]: All of your Minions with the '
                    'Misfit Minions Minion Class Trait have their Soak Value '
                    'and Surgency increased by 1(bT). (2)-[Passive]: You are '
                    'considered a Minion with the Misfit Minions Minion Class '
                    'Trait for the effects of the Misfit Minions Minion Trait. '
                    '(3)-[Triggered, 1/Round]: If you would take Damage from '
                    'an Attacking Maneuver (that did not possess an AoE) while '
                    'you have a Minion with the Misfit Minions Minion Class '
                    'Trait adjacent to you, you may spend a Counter Action for '
                    'them to take the Damage of that Attacking Maneuver '
                    'instead. (4)-[1/Encounter]: As an Instant Maneuver, '
                    'target a Minion with the Misfit Minions Minion Class '
                    'Trait that is not at Long Range. Swap your placements on '
                    'the Battlefield with them (as long as you both can fit in '
                    'the spaces you exchanged).',
              ),
              TraitOption(
                name: 'Stand Back and Observe',
                description: '(1)-[Passive]: Instead of targeting an Ally '
                    'through the 1st effect of the Spectator State, you may '
                    'target all of your Minions. (2)-[Triggered, 1/Round]: If '
                    'you are hit by an Attacking Maneuver while in the '
                    'Spectator State, you may target one of your Minions. They '
                    'may use the Intervene Maneuver without spending a Counter '
                    'Action. (3)-[Triggered/Spectator, 1/Encounter]: Target a '
                    'Minion. That Minion may use the Power Up Maneuver as an '
                    'Out-of-Sequence Maneuver. (4)-[Triggered, 1/Encounter]: '
                    'Upon leaving the Spectator State, you may use the Power '
                    'Up Maneuver or Transformation Maneuver as an '
                    'Out-of-Sequence Maneuver.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Cultivation of the Self',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Enhancement of the Self',
        description: 'You wield your mastery of yourself like a weapon, '
            'becoming the best version of yourself that you can be.\n'
            '(1)-[Passive]: Upon gaining this Transformation, select two '
            'Attributes (except FO/MA); increase this Transformation\'s AMB '
            'for them by 2.\n'
            '(2)-[Passive]: While not in a Form, increase your Combat Rolls '
            'and Soak Value by 1(bT).\n'
            '(3)-[Triggered/Start of Turn]: If not in a Form, regain 3(bT) '
            'Ki Points.\n'
            '(4)-[Option]: Select Pure Resolve (Ki Multiplier while in a '
            'Transcended Enhancement) or Built Different (Ki Multiplier + '
            'Gravity/Power Threshold bonuses while in no Form/Enhancement).\n'
            '(5-6)-[Choice]: Grants further effects per your Option — Pure '
            'Resolve: enter the Unlimited State and stack an extra '
            'Enhancement; Built Different: large Attribute Modifier bonuses '
            "and 'Surplus Awakenings' (extra Greater Awakenings off-limit). "
            'See the site.',
        automation: [
          // (2) While not in a Form: +1(bT) Combat Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNotInForm,
          ),
        ],
        optionGroups: [
          // (1) select TWO Attributes (except FO/MA) → +2 flat AMB each.
          RaceTraitOptionGroup(
            label: 'Enhanced Attributes',
            maxChoices: 2,
            options: [
              TraitOption(
                name: 'Agility',
                description: '+2 Attribute Modifier Bonus (AG).',
                ambFlatBonus: {DbuAttribute.agility: 2},
              ),
              TraitOption(
                name: 'Tenacity',
                description: '+2 Attribute Modifier Bonus (TE).',
                ambFlatBonus: {DbuAttribute.tenacity: 2},
              ),
              TraitOption(
                name: 'Insight',
                description: '+2 Attribute Modifier Bonus (IN).',
                ambFlatBonus: {DbuAttribute.insight: 2},
              ),
            ],
          ),
          // (4) Pure Resolve vs Built Different — Ki-Multiplier / situational
          // sub-systems gated on Enhancement/Form state, so text-only. Each
          // option carries its full (4)/(5)/(6) Choice effects verbatim.
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Pure Resolve',
                description: '(4)-[Passive]: While you are in a Transcended '
                    'Enhancement, you benefit from Ki Multiplier (see — '
                    'Transformation Rules).\n'
                    '(5)-[Triggered/Power]: If you are in a Transcended '
                    'Enhancement, you may enter the Unlimited State.\n'
                    '(6)-[Passive]: While in a Transcended Enhancement that '
                    'you possess the Transcendent Trait for, you may use an '
                    'additional Enhancement in conjunction with it.',
              ),
              TraitOption(
                name: 'Built Different',
                description: '(4)-[Passive]: While you are not using any Form '
                    'or Enhancement, you benefit from Ki Multiplier (see — '
                    'Transformation Rules) and have both your Gravity '
                    'Acclimation (see — Gravity) and Power Threshold (see — '
                    'Dimensions) increased by 1/2 (rounded up) of your Tier of '
                    'Power.\n'
                    '(5)-[Passive]: While you are not in a Form or '
                    'Enhancement, increase your Attribute Modifiers '
                    '(AG/FO/TE/SC/MA/PE) by x(bT), where x is equal to your '
                    'base Tier of Power. Increase your Attribute Modifier (IN) '
                    'by 1/2 of x(bT), where x is equal to your base Tier of '
                    'Power.\n'
                    '(6)-[Passive, Ruling]: Upon gaining this effect and again '
                    'upon reaching Power Level 20 (or upon gaining this effect '
                    'if your Power Level is already 20 or higher), you may '
                    'gain access to an additional Greater Awakening that you '
                    'meet the Racial Requirements and Prerequisites for. These '
                    "Greater Awakenings are known as your 'Surplus Awakenings' "
                    'and do not count towards your Awakening Limit. If you '
                    'enter a Form or Enhancement, you lose access to your '
                    'Surplus Awakenings while in that Transformation.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Dark Evolution',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Monstrous Evolution',
        description: 'You have been transformed, growing into a true '
            'monster.\n'
            '(1)-[Passive]: Reduce your Racial Life Modifier by 3.\n'
            '(2)-[Passive]: Increase your Wound Rolls, Soak Value, and '
            'Damage Reduction by 1(T).\n'
            '(3)-[Passive]: Increase your Size Category by 1 Category after '
            'all other calculations.\n'
            '(4)-[Passive]: Upon gaining this Awakening, select and gain 1 '
            'Bestial Trait and 1 Monstrous Trait while you possess it.\n'
            '(5)-[Triggered, 1/Encounter]: If you would receive Damage less '
            'than 1/4 (rounded up) of your Maximum Life Points, you do not '
            'receive it.\n'
            '(6)-[Triggered, 1/Encounter]: If you hit only 1 Opponent, apply '
            'your Damage Attribute an additional time to that attack.',
        automation: [
          // (1) -3 Racial Life Modifier = -3 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: -3,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +1(T) Wound Rolls, Soak Value and Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
              AffectedStat.damageReduction,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Divine Candidate',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Divine Training',
        description: 'You have been given a role as an apprentice to a '
            'divine being of some variety, allowing you to train in earnest '
            'to take that position.\n'
            '(1)-[Passive]: All your Transformations with the God Ki Aspect '
            'gain the Perfect Ki Control Aspect.\n'
            '(2)-[Passive]: Upon gaining this Transformation, select and '
            'gain a God Maneuver of your choice.\n'
            '(3)-[Passive]: While in the God Ki State, reduce the Ki Point '
            'Cost of all Attacking Maneuvers by 1(T).\n'
            '(4)-[Passive]: While in the God Ki State, increase your '
            'Surgency by 2(T).\n'
            '(5)-[Triggered/Power, 1/Round]: You may enter the God Ki State '
            'until the end of your turn.\n'
            '(6)-[Triggered/God Ki, 1/Encounter]: Use a Ki Surge; if you do, '
            'regain Divine Ki Points equal to your Surgency.',
        automation: [
          // (4) While in the God Ki State (tracked in the States list):
          // +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'God Ki',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Effortless',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Stamina Battle',
        description: 'Only those with overwhelming power can match your '
            'efforts, as you wear your opponents out with a prolonged '
            'battle.\n'
            '(1)-[Passive]: While your Life is >= 1/2 Max and you have no '
            'Power stacks: +1(T) Dodge/Soak/Surgency; −1(T) Ki Cost of your '
            'attacks; +2(T) Ki Cost of attacks targeting you.\n'
            '(2)-[Passive]: While your Life is < 1/2 Max and/or you have '
            'Power stacks: +1(T) Combat Rolls; +2(T) Wound Rolls of '
            'Signature Techniques; on an Opponent Counter, −2(bT) their Ki '
            'and Capacity.\n'
            '(3)-[Triggered/Start of Turn]: Above Bruised — regain 3(bT) Ki; '
            'below Bruised — regain 3(bT) Life.\n'
            '(4)-[1/Encounter]: Below Bruised, use a Healing Surge as an '
            'Instant Maneuver.\n'
            '(5)-[1/Encounter]: Above Bruised, use the Power Up Maneuver as '
            'an Instant Maneuver.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Elemental Preference',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to a Favored Element',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Single-Minded Elemental Focus',
        description: "(1)-[Ruling]: Upon gaining this Awakening, select one "
            "of your Favored Elements as your 'Chosen Element'.\n"
            '(2)-[Passive]: All Favored Elements except your Chosen Element '
            'have −1(T) Strike and Wound Rolls.\n'
            '(3)-[Passive]: Reduce the Critical Target of your Strike and '
            'Wound Rolls by 1 for attacks using your Chosen Element.\n'
            '(4)-[Passive]: Reduce the Ki Point Cost of your Chosen Element '
            'by 2(T).\n'
            '(5)-[Passive]: You take no Damage from attacks of your Chosen '
            'Element.\n'
            '(6)-[Triggered]: On a Critical Strike/Wound Roll for a Chosen '
            'Element attack, increase that roll\'s Dice Score by 1(T).\n'
            '(7)-[Triggered, 1/Round]: On an Energy Charge declaring a '
            'Chosen Element attack, gain an extra Energy Charge (counts as 2 '
            'for Mandatory Charge). Also: a Chosen Element Signature '
            'Technique may add an Advantage costing up to 10 TP.\n'
            '(9)-[Triggered, 1/Encounter]: If you deal Damage with a Chosen '
            'Element attack, +1(T) Combat Rolls and Soak Value for the rest '
            'of the Encounter.\n'
            '(10)-[Triggered/Start of Combat Encounter, 1/Encounter]: Use '
            'the Basic Attack Maneuver Out-of-Sequence with your Chosen '
            'Element.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Energy Poacher',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Skill Ranks in Use Magic',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Energy Siphon',
        description: 'You absorb the energy others would wield against you, '
            'tiring them out while empowering yourself in the process.\n'
            '(1)-[Passive]: You gain access to the Energy Drain Unique '
            'Ability (detailed below).\n'
            '(2)-[Passive]: Increase your Surgency by 2(T) if you won the '
            'Energy Drain Clash this Combat Round.\n'
            '(3)-[Passive]: While above the Injured Threshold, increase your '
            'Soak Value by 1(T).\n'
            '(4)-[Passive]: While your Ki > 1/2 Max, increase your Combat '
            'Rolls by 1(T).\n'
            '(5)-[Triggered, 1/Encounter]: If you win the Energy Drain '
            'Clash, use the Basic Attack or Signature Technique Maneuver '
            'Out-of-Sequence.\n'
            '(6)-[Triggered, 1/Encounter]: Below the Injured Threshold, if '
            'you win the Energy Drain Clash, use a Surge of your choice '
            'Out-of-Sequence.\n'
            '\n'
            'Energy Drain Unique Ability — You are capable of stealing the '
            'life energy of others, using it to revitalize yourself, or '
            'otherwise to restore your own reserves of energy. Ability Type: '
            'Magical; Prerequisites: Energy Poacher Awakening; TP Cost: N/A; '
            'KP Cost: 6(T); Maneuver Type: Standard; Action Cost: 1 Action; '
            'Passive Bonus: You gain access to the Power Drain Special '
            'Maneuver. Effect: Target a Character who is not at Long Range. '
            'Make a Clash (Cognitive vs Impulsive/Cognitive/Corporeal) against '
            'that targeted Character. If you win, make a Magical Wound Roll '
            '(which is not applied to the Opponent for Damage Calculation), '
            "then reduce your Dice Score by 1/2 of the target's Might. The "
            'target loses Ki Points equal to the Dice Score of this Magical '
            'Wound Roll. Then, you may regain Life and Ki Points equal to 1/2 '
            'of the total amount of Ki Points lost by the target.\n'
            'Energy Drain Advancements:\n'
            '• Deep Drain — Prerequisites: 3+ Skill Ranks in Use Magic; TP '
            'Cost: 10. Effect: When calculating the amount of Ki Points lost '
            'by a target of Energy Drain, only reduce your Dice Score by 1/4 '
            "(rounded up) of the target's Might instead of 1/2.\n"
            '• Multi-Drain — Prerequisites: 3+ Skill Ranks in Use Magic; TP '
            'Cost: 10. Effect: When you use the Energy Drain Unique Ability, '
            'you may target an additional Character for every 2 Skill Ranks '
            'you possess in Use Magic after the first. Calculate the Life and '
            'Ki Points you regain based on the largest reduction amongst those '
            'targets.\n'
            '• Defensive Drain — Prerequisites: 3+ Skill Ranks in Use Magic; '
            'TP Cost: 10. Effect: Gain access to the Attack Absorption Special '
            'Maneuver.\n'
            '• Stress Eater — Prerequisites: 3+ Skill Ranks in Use Magic; TP '
            'Cost: 10. Effect: If you win the Clash for the effects of Energy '
            'Drain, your target must make a Stress Test. Reduce their Dice '
            'Score for this Stress Test by 1 for every 2 Skill Ranks you '
            'possess in Use Magic after the first.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Gravity Controller',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Weight of Power',
        description: 'The density of your raw strength pressed down on all '
            'who oppose you.\n'
            '(1)-[Passive]: Increase your Might, Soak Value, and Wound Rolls '
            'by 1(T).\n'
            '(2)-[Passive]: You do not suffer any penalties from the rules '
            'of Gravity.\n'
            '(3)-[Passive]: Gain the Gravity Manipulation Unique Ability and '
            'the Gravity Cage Profile.\n'
            '(4)-[Passive]: You may spend Technique Points to obtain the '
            'Gravity Unique Abilities and Advancements (Gravity Crush, '
            'Gravity Restraint, Gravity Burst, Precise Gravity — see the '
            'site).\n'
            '(5)-[Triggered]: If you win a Might Clash via the Gravity Cage '
            'Profile or a Gravity Unique Ability, reduce that Opponent\'s '
            'Life by 1/4 (rounded up) of your Might.\n'
            '(6)-[Triggered, 1/Round]: On a Signature Technique, apply the '
            'Multi-Profile Super Profile with the Gravity Cage Profile.\n'
            '(7)-[Triggered, 1/Encounter]: If an Ally (not at Long Range) '
            'uses a Signature Technique, apply Multi-Profile (Gravity Cage) '
            'to it.\n'
            '(8)-[Triggered, 1/Encounter]: If an Opponent stops being Prone, '
            'make a Might Clash; if you win, −1/4 Might to their Life and '
            'knock them Prone.',
        automation: [
          // (1) +1(T) Might, Soak Value and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.might,
              AffectedStat.soak,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Greater Mutation',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Mutation Factor',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Evolutionary Peak',
        description: 'Adapted to survive even more efficiently than your '
            'peers, you are the apex of your kind.\n'
            '(1)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Points by 2 for each Power Level reached.\n'
            '(2)-[Passive]: Increase your Wound Rolls and Soak Value by '
            '1(bT).\n'
            '(3)-[Passive]: Upon gaining this Transformation, regain the '
            'Racial Trait you replaced with the Mutation Factor Trait.\n'
            '(4)-[Triggered, 1/Encounter]: If you use the Surge Maneuver, '
            'double the Life or Ki regained through your selected Surge.',
        automation: [
          // (1) +2 Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +1(bT) Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Greatest Warrior?',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.personality: TransformationAmb(coefficient: 4),
    },
    traits: [
      TransformationTrait(
        name: 'Savior(?) of Worlds',
        description: 'Through some combination of showmanship, performances, '
            'special effects, and even outright lies, you have somehow '
            'convinced others that you are a true hero.\n'
            '(1)-[Passive]: Halve your Maximum Life Points and Soak Value '
            'after all other calculations.\n'
            '(2)-[Passive]: Reduce all your Combat Rolls by 2(bT).\n'
            '(3)-[Passive]: Increase all Skill Checks using your Personality '
            'Modifier by 1d4.\n'
            '(4)-[Passive]: Your Life cannot be reduced below 1 above its '
            'minimum, except by an attack dealing >= 1/2 of your Maximum '
            'Life Points.\n'
            "(5)-[1/Encounter]: As an Instant Maneuver on an Ally's turn, "
            'transfer all your Actions and Counter Actions to that Ally.\n'
            '(6)-[Triggered, 1/Round]: If an Ally attacks, spend 1 Action to '
            "increase that attack's Wound Roll by your Personality "
            'Modifier.\n'
            '(7)-[Triggered, 1/Round]: If an Ally is targeted by an attack, '
            'spend 1 Counter Action to increase their Strike and Dodge by '
            '1/2 of your Personality Modifier for that attack.\n'
            '(8)-[Triggered, 1/Encounter]: You may use the 6th or 7th effect '
            'ignoring its [1/Round] Keyword.',
        automation: [
          // (2) -2(bT) Combat Rolls. ((1) halving Max Life/Soak is
          // multiplicative — shown as text, not automated.)
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: -2,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Heroic Melodies',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Skill Ranks in Performance',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Songs of Heroism',
        description: 'Your instrument unleashes powerful magic through song, '
            'allowing you to defend against injustice, tyranny, and evil.\n'
            '(1)-[Passive]: Increase the Skill Bonus for your Performance '
            'Skill by 2.\n'
            '(2)-[Passive]: Increase your Morale Saving Throw by 1(bT).\n'
            '(3)-[Passive]: If Personality is your highest Attribute Score, '
            '+1(T) Combat Rolls and Soak Value.\n'
            '(4)-[Passive]: Gain access to the Melody Special Maneuvers '
            '(detailed below).\n'
            '(5-7)-[Automatic]: Rules for a Sealed Opponent (Song of '
            'Sealing): if you die, they die; if you lose this Awakening or '
            'fail the start-of-turn Morale Clash, they are freed near you.\n'
            '(8)-[Triggered, 1/Encounter]: If you win the Song of Fury '
            'Clash, that Opponent loses Life = your Personality Modifier and '
            'gains Broken until the start of your next turn.\n'
            '(9)-[Triggered, 1/Encounter]: Use the Song of Healing as an '
            'Instant Maneuver.\n'
            '(10)-[Triggered/Start of Turn, 1/Encounter]: Use the Copy Being '
            'Unique Ability Out-of-Sequence targeting your Sealed Opponent '
            '(even without access to it).\n'
            '\n'
            'Melody Special Maneuvers:\n'
            'Song of Fury [1/Round] — Maneuver Type: Standard; Action Cost: 1 '
            'Action; KP Cost: 4(T); Exploitable: All adjacent Opponents. '
            'Effect: Target an Opponent that is not at Long Range. Make a '
            'Clash (Performance vs Performance/Intimidation/Intuition) against '
            'that Opponent. If you win, that Opponent gains the Compelled '
            'Combat Condition with you as the target until the start of your '
            'next turn.\n'
            'Song of Healing [1/Round] — Maneuver Type: Standard; Action Cost: '
            '1 Action; KP Cost: 5(T); Exploitable: All adjacent Opponents. '
            'Effect: All Allies within a Destructive Sphere AoE (centered on '
            'you) regain Life Points equal to your Personality Modifier. '
            'Additionally, you may remove one Combat Condition from each of '
            'those Allies (except Pinned, Suffocating, Poisoned, or '
            'Transfigured).\n'
            'Song of Guarding [1/Round] — Maneuver Type: Counter; Action Cost: '
            '1 Counter Action; KP Cost: 5(T). Effect: If you are hit by an '
            'Attacking Maneuver, increase your Damage Reduction by your '
            'Personality Modifier. If the Attacking Maneuver was an AoE and '
            'hit multiple Characters, all other Characters hit by that '
            'Attacking Maneuver may increase their Damage Reduction by 1/2 of '
            'your Personality Modifier.\n'
            'Song of Sealing [1/Encounter] — Maneuver Type: Standard; Action '
            'Cost: 3 Actions; Minions: Non-Minion; KP Cost: 10(T); '
            'Exploitable: All adjacent Opponents. Effect: Target an Opponent '
            'that is not at Long Range. Make a Clash (Performance vs '
            'Performance/Intimidation/Intuition/Stealth/Concealment) against '
            'that Opponent. If you win, that Opponent leaves the Combat '
            'Encounter and becomes Sealed within you. You can only possess a '
            'single Sealed Opponent.',
        automation: [
          // (2) +1(bT) Morale Saving Throw.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.moraleSave],
            coefficient: 1,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Inherited Life',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Reincarnated Factor',
    // AMB is defined by trait effect (2): +2 to the three highest Attributes
    // among your Past Life's Attributes — not a flat table, so left empty.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Mastered Reincarnated',
        description: "You've completely mastered the powers you inherited "
            'from your past self, making them truly your own.\n'
            '(1)-[Passive]: Upon gaining this Transformation, regain the '
            'Racial Trait you replaced with the Reincarnated Factor Trait.\n'
            "(2)-[Passive]: This Transformation's Attribute Modifier Bonus is "
            "+2 in the three Attributes with the highest Attribute Scores "
            "among your Past Life's Attributes.\n"
            '(3)-[Passive]: While benefiting from the 5th effect of '
            'Lingering Power, increase your Damage Reduction by 2(bT).\n'
            '(4)-[Passive]: The 5th effect of Lingering Power loses '
            '[1/Encounter] and gains [1/Round, 2/Encounter].\n'
            '(5)-[Triggered, 1/Encounter]: When you use the Signature '
            "Technique Maneuver, you may use one of your Past Life's "
            'Signature Techniques.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Jacket Specialist',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Expert Pilot Talent',
    // Listed on the site as Transformation Type: Manifested Power.
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Dedicated Pilot',
        description: 'While you may be unable to keep up with other fighters '
            'on your own, thanks to a bit of ingenuity and a lot of hard '
            "work, you've found a way to keep up thanks to your Battle "
            'Jacket.\n'
            '-[Passive]: Halve your Maximum Life Points and reduce your Soak '
            'Value by 2(bT).\n'
            '-[Passive]: Reduce your Combat Rolls by 2(bT) while not Piloting '
            'a Vehicle or Battle Jacket.\n'
            "-[Passive]: You benefit from and may trigger this Manifested "
            "Power's Transformation Traits while Piloting a Battle Jacket.\n"
            '-[Passive]: For every 2 Skill Ranks in Piloting, increase your '
            "Battle Jacket's Combat Rolls by 1(bT).\n"
            '-[Passive]: Your Hype Maneuver can use your Personality Modifier '
            'instead of the Score.\n'
            '-[Triggered, 1/Encounter]: If your Battle Jacket is destroyed '
            'without the Escape Function Module, halve the Life Point '
            'reduction; with it, take none.',
      ),
      TransformationTrait(
        name: 'Jacket Crafter',
        description: 'Due to your innate understanding of your Battle '
            'Jacket, you are capable of improving its abilities in ways '
            'others cannot.\n'
            '-[Automatic/Start of Combat Encounter]: If you have a single '
            'Battle Jacket, double its Max Life Points, then it regains 1/2 '
            'of its Max Life.\n'
            '-[1/Encounter]: Spend 3 Actions to Repair your Battle Jacket.\n'
            '-[Passive]: Your Analysis Maneuver can use your Scholarship '
            'Modifier instead of the Score.\n'
            '-[Passive]: Battle Jackets you created gain +5 Max Life and +2 '
            'Max Ki per Power Level reached.\n'
            '-[Passive]: Depending on your ranks in the Craft (Vehicles) '
            'Skill, apply the following effects:\n'
            '2+: When you Repair a Battle Jacket, it regains Ki Points equal '
            'to 1/2 of the Life Points it regained.\n'
            '3+: Increase the amount of Life and Ki Points your Battle Jacket '
            'regains by being Repaired by your Scholarship Modifier.\n'
            '4+: Reduce the Action Cost for the second effect of Jacket '
            'Crafter to 2 Actions and change the Keywords for its effects to '
            '[1/Round, 3/Encounter].\n'
            '5: Increase the Awareness, Defense Value, Soak Value, and Might '
            'of your created Battle Jackets by 1(bT).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Last Hope',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Lone Warrior',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Light of Willpower',
        description: 'Y\n'
            '(1)-[Passive]: Increase your Maximum Life Points by 2 for '
            'each Power Level reached.\n'
            '(2)-[Passive]: While in a Desperate Battle, increase your '
            'Combat Rolls and Soak Value by 1(T).\n'
            '(3)-[Passive]: While in a Desperate Battle, you cannot lose a '
            'Clash initiated by an Opponent that uses your Morale Saving '
            'Throw.\n'
            '(4)-[Passive]: While in a Desperate Battle, ignore the '
            'effects of the Broken and Shaken Combat Conditions.\n'
            '(5)-[Triggered/Power, 1/Round]: If you are below the Injured '
            'Health Threshold, you may treat this Combat Encounter as a '
            'Desperate Battle until the start of your next turn.\n'
            '(6)-[Triggered/Surging, 1/Encounter]: You may use the '
            'Transformation Maneuver or Power Up Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            '(7)-[Triggered/Start of Turn, 1/Encounter]: Enter the Surging '
            'State until the end of your next turn.',
        automation: [
          // (1) +2 Max Life per Power Level. (The Desperate Battle
          // effects are encounter-level judgements — reference text, same
          // as Lone Warrior's.)
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Marvelous Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'You are not a Minion',
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 2),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'A Powerful Servant',
        description: 'You have a powerful attendant that battles on your '
            'behalf, though this subordinate may not always remain under '
            'your control.\n'
            "(1)-[Ruling, Addendum]: Upon gaining this Trait, create a "
            "'Marvelous Servant'. For more information, see the 'A Marvelous "
            "Servant' text box below.\n"
            '(2)-[Passive]: Halve your Maximum Life Points and Soak Value '
            'after all other calculations.\n'
            '(3)-[Passive]: While you have a Marvelous Servant, reduce all of '
            'your Combat Rolls by 2(bT).\n'
            '(4)-[Passive]: While you are controlling your Marvelous Servant, '
            'increase their Tier of Power by 1 (see - Breakthrough).\n'
            '(5)-[Triggered/Start of Combat Round]: Spend all of your Actions '
            'to make a Clash (Cognitive/Morale) against your Marvelous '
            'Servant. If you win, you enter the Spectator State and gain '
            'control of your Marvelous Servant until the end of this Combat '
            'Round. You must select your Marvelous Servant for the first '
            'effect of the Spectator State if you enter it through this '
            'effect.\n'
            '\n'
            'A Marvelous Servant — A Marvelous Servant is a Character that is '
            'controlled by the ARC. While they are generally assumed to be an '
            'Ally, they can become an Opponent if prompted, led astray, or '
            'possessed (see - Possess Maneuver and Overtaken Awakening). You '
            'cannot use the 5th effect of A Powerful Servant if your Marvelous '
            'Servant is possessed. Upon gaining this Awakening, work with your '
            'ARC to create a Marvelous Servant. Your Marvelous Servant should '
            'be of the same Power Level as you and with an equal number of '
            'Awakenings. When deciding other Transformations, discuss what '
            'seems appropriate to maintain a similar degree of strength with '
            'the rest of the party — treat the Marvelous Servant as another '
            'member of the party for deciding their Transformations. Whenever '
            'you gain a Power Level or an Awakening, the Marvelous Servant '
            'should as well.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Master Class',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Initial Class Awakening',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Advanced Class',
        description: 'Your chosen path branches out, and your path becomes '
            'more specialized and unique to you.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select and gain a '
            'Greater Class matching your Initial Class (Fighter, Slayer, '
            'Turtle/Crane Hermit, Dark Warrior, Shadow Knight, Healing/'
            'Summoning Bishop, Ultimate, Grand Chef, Plasma, Karma — each '
            'adds +2 AMB to two Attributes and a suite of effects; see the '
            'site).\n'
            '(2)-[Passive]: Increase your Maximum Ki Points by 2 for each '
            'Power Level reached.\n'
            '(3)-[Passive]: Gain a Talent from the Physical Attack, Energy '
            'Attack, Magic Attack, Durability, Skill, or Weapon '
            'Categories.\n'
            '(4)-[Passive]: Gain access to the Hyper Tension Blow!! Special '
            'Maneuver.',
        automation: [
          // (2) +2 Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Overtaken',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Can only be obtained through the Possession Maneuver',
    // AMB is +2 to the three highest Attributes of the Possessing Character
    // (trait effect 6) — not a flat table, so left empty.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'I BECOME YOU',
        description: 'You are no longer in control of your body, having been '
            'taken over by another.\n'
            "(1)-[Ruling]: Upon gaining Overtaken, a 'Possessing Character' "
            'is assigned.\n'
            '(3)-[Passive]: Gain access to all Signature Techniques, Unique '
            'Abilities, Forms, and Enhancements of your Possessing Character '
            '(meet Prerequisites).\n'
            '(4)-[Passive]: Replace your Scholarship and Personality Scores '
            'with the higher between you and the Possessing Character.\n'
            '(5)-[Passive]: For Skill Checks, use the higher Skill Bonus '
            'between you and the Possessing Character.\n'
            "(6)-[Passive]: This Transformation's AMB is +2 in the three "
            'Attributes with the highest Scores among the Possessing '
            "Character's Attributes.\n"
            '(7)-[Passive]: Gain a Primary Racial Trait and up to 2 Talents '
            'from your Possessing Character (meet prerequisites).\n'
            '(8)-[Passive]: Ignore the Rampaging Aspect.\n'
            '(9)-[Automatic/Start of Turn]: If this Awakening is a Temporary '
            'Awakening, make an Urgent Clash (Cognitive) against the '
            'Possessing Character. If you win, you lose this Awakening. If you '
            'lose, nothing happens.\n'
            '(10)-[Automatic]: If you take any Damage from Attacking '
            'Maneuvers, the Possessing Character has their Life Points reduced '
            'by 1/2 of the amount of Damage you receive.\n'
            '(11)-[Automatic/Start of Turn]: If you or your Possessing '
            'Character are Defeated, lose this Awakening.\n'
            '(12)-[Automatic]: If you lose access to this Awakening, stop '
            'being controlled by the Possessing Character, remove the '
            'Possessing Character from your body, and if you are in a Combat '
            'Encounter, the Possessing Character enters that Combat Encounter '
            'on a Square adjacent to you of your choice.\n'
            '(13)-[Automatic]: At the end of a Combat Encounter, if you have '
            'not reached your Awakening Limit for Greater Awakenings, make an '
            'Urgent Clash (Cognitive) against the Possessing Character (this '
            'Clash is not Urgent for the Possessing Character). If the '
            'Possessing Character wins, this Transformation stops being a '
            'Temporary Awakening.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Performer',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Skill Ranks in Performance',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Just Perform',
        description: 'You focus on your performance, and anything that pulls '
            'you out of that rhythm leaves you disoriented.\n'
            '(1)-[Passive]: While Hyped, increase your Dodge Rolls by 1/4 '
            '(rounded up) of your Personality Modifier and the Performance '
            'Skill Bonus by 2.\n'
            '(2)-[Passive]: While Hyped, your Movement Maneuver does not '
            'trigger the Exploit Maneuver.\n'
            '(3)-[Triggered, Resource]: Gain 1 Rhythm (max 4) when you Hype, '
            'Dodge an Opponent attack, or win a Performance Clash.\n'
            '(4)-[Automatic]: If hit by an attack, lose a stack of '
            'Rhythm.\n'
            '(5)-[Automatic/Threshold]: If you fail a Steadfast Check for '
            'this Threshold, lose all Rhythm.\n'
            '(6)-[1/Round]: Spend 2 Rhythm to use the Hype Maneuver as an '
            'Instant Maneuver.\n'
            '(7)-[Triggered, 1/Round]: If you Dodge, spend 1 Rhythm for a '
            'Basic Attack or Movement Maneuver Out-of-Sequence.\n'
            '(8)-[Triggered, 1/Round]: If you attack, spend a Rhythm to use '
            'your Personality Modifier as the Damage Attribute.\n'
            '(9)-[Triggered/Start of Turn, 1/Encounter]: While Hyped, spend '
            '4 Rhythm to gain an Action.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Pure Progress',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Combat Imprinting',
        description: 'Adapting instantly as you study your opponents, you '
            'learn to grasp the principles of greater power and soar to '
            'greater heights even as you continue to fight.\n'
            '(1)-[Triggered/Start of Turn, Resource]: If an Opponent of '
            'equal/higher Power Level attacked last Round, gain 1 Progress '
            '(apply to Strike, Dodge, or Wound; max 2 per Combat Roll, '
            '+1(T) each).\n'
            '(2)-[Passive]: While you have 2+ Progress, increase your Soak '
            'Value by 1(T).\n'
            '(3)-[Passive]: While you have 3+ Progress, +1(T) Dice Score for '
            'Opponent-initiated Clashes using your Might/Saving Throws.\n'
            '(4)-[Passive]: While you have 4+ Progress, increase your Stress '
            'Bonus by 1.\n'
            '(5)-[Triggered, 1/Round]: If you are knocked through / knock an '
            'Opponent through a Health Threshold, gain a Progress stack.\n'
            '(6)-[Triggered/Start of Turn, 1/Encounter]: With 6 Progress, '
            'spend an Action to enter the Flow State for the rest of the '
            'Encounter.',
        automation: [
          // (2) While 2+ tracked 'Progress' Resource stacks: +1(T) Soak.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Progress',
            conditionAmount: 2,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Rebellious Spirit',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Diehard Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'This Will Change Everything',
        description: '(1)-[Passive]: Increase your Maximum Life Points by x '
            'for each Power Level reached, where x = the number of Diehard, '
            'Fortitude, and Steadfast Warrior Talents you possess.\n'
            '(2)-[Passive]: While below the Injured Threshold, increase your '
            'Combat Rolls and Soak Value by 1(T).\n'
            '(3)-[Passive]: Gain access to the Guerilla Combat Special '
            'Maneuver.\n'
            '(4)-[Triggered, Resource]: If you take Damage or lose an '
            'Opponent-initiated Special Maneuver/Unique Ability Clash, gain '
            'a stack of Rebellion (max 3).\n'
            '(5)-[Automatic]: At the end of your turn, lose all Rebellion.\n'
            '(6-9)-[Triggered, 1/Round]: Spend Rebellion stacks to boost '
            'Wound Rolls, Steadfast Checks, Clash Dice Scores, and Guerilla '
            'Combat Clashes.\n'
            '(10)-[Triggered, 1/Encounter]: If you spend 3 Rebellion via the '
            '6th effect, apply an Energy Charge to that attack.',
        automation: [
          // (2) While below the Injured Threshold: +1(T) Combat Rolls and
          // Soak Value. ((1)'s Talent-count-scaled Max Life stays manual.)
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Reborn Potential',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Unified Awakening with your Split Life as the Merged '
        'Character',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Together Again',
        description: 'By fusing together with your other half, you\'ve '
            'become unfathomably stronger.\n'
            '(1)-[Passive]: Increase your Might by 1(T).\n'
            '(2)-[Passive]: Increase your Wound Rolls and Soak Value by '
            '2(bT).\n'
            '(3)-[Triggered, 1/Round]: If you or an Ally take Damage from an '
            "Opponent's attack, reduce it by 1/2 of your Might.\n"
            '(4)-[Triggered, 1/Round]: If an Opponent takes Damage from you '
            'or an Ally, increase it by 1/2 of your Might.',
        automation: [
          // (1) +1(T) Might.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (2) +2(bT) Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 2,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Results of Intense Training',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 4,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Sudden Leap in Strength',
        description: 'Your power has evolved by leaps and bounds.\n'
            '(1)-[Passive]: Increase your Combat Rolls by Z(T).\n'
            '(2)-[Passive]: Upon gaining a stack of this Awakening, gain 2 '
            'Character Perks to spend immediately.\n'
            '(3)-[Passive]: Increase your Maximum Life Points by Z for each '
            'Power Level reached.',
        automation: [
          // (1) +Z(T) Combat Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
          // (3) +Z Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
            perTransformationStack: true,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Rushdown Fighter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Archetype Focus (Physical)',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Physical Focus',
        description: "You've perfected your physical strikes at the expense "
            'of all others.\n'
            '(1)-[Passive]: You can only use Physical Attacks.\n'
            '(2)-[Passive]: Increase the Strike and Wound Rolls of your '
            'Physical Attacks by 1(T) and 2(T) respectively.\n'
            '(3)-[Passive]: Your Signature Techniques gain an Energy Charge '
            'if the target(s) are within your Melee Range.\n'
            '(4)-[Triggered, 1/Round]: If you attack via the Exploit '
            'Maneuver, double the 2nd-effect bonus for that attack.\n'
            '(5)-[Triggered, 1/Round]: If you use the Basic Attack Maneuver, '
            'apply the Charging Assault Advantage.\n'
            '(6)-[Triggered, 1/Round]: If you use the Basic Attack Maneuver, '
            'you may target an Opponent outside Melee Range, ignoring the '
            'Long Range Penalty (Movement Out-of-Sequence on Damage).\n'
            '(7)-[Triggered, 1/Encounter]: If you deal Damage, use the '
            'Signature Technique Maneuver Out-of-Sequence targeting that '
            'Opponent.',
        automation: [
          // (2) +1(T) Strike / +2(T) Physical Wound Rolls — global, because
          // the 1st effect restricts you to Physical Attacks only.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          RaceTraitAutomation(
            affectedStats: [AffectedStat.woundPhysical],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Scholar',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Skill Ranks in Investigation',
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 2),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Unmitigated Genius',
        description: 'You are a true marvel of intellectual prowess, '
            'recognized by all.\n'
            '(1)-[Passive]: Increase your Combat Rolls against an Analyzed '
            'Opponent by 1/4 (rounded up) of your Scholarship Modifier.\n'
            '(2)-[Passive]: +1(T) Dice Score for Analyzed-Opponent-initiated '
            'Clashes using your Might or a Saving Throw.\n'
            '(3)-[Passive]: +2 Dice Score for such Clashes that use a '
            'Skill.\n'
            '(4)-[Triggered, 1/Round]: If your attack targets only Analyzed '
            'Opponents, use your Scholarship Modifier as the Damage '
            'Attribute (or +2(T) Wound if already doing so).\n'
            '(5)-[Triggered, 1/Round]: If an Opponent becomes Analyzed, make '
            'a Clash (Investigation vs Bluff/Investigation/Stealth); if you '
            'win, they gain Broken until the start of your next turn.\n'
            '(6)-[Triggered, 1/Encounter]: When using the Analysis Maneuver, '
            'you may target all Opponents.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Seeking Skill',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Chance for Improvement',
        description: 'You respect skill and technique above all else, and '
            "each fight you're in is just another chance to improve even "
            'further.\n'
            "(1)-[Ruling]: If you have exchanged all Power-Level Character "
            "Perks into Skill Improvements, you are 'Still Learning'.\n"
            '(2)-[Passive]: When you gain a Skill Improvement, exchange any '
            'of its Skill Ranks for 2 Technique Points each.\n'
            '(3)-[Passive]: Upon gaining this Awakening, select IN/SC/PE; '
            'while Still Learning, +1(T) that Attribute Modifier.\n'
            '(4)-[Passive]: While Still Learning, +1(bT) Combat Rolls, '
            'Might, and Saving Throws.\n'
            "(5)-[Ruling]: 'SKI' = the number of Power-Level Character Perks "
            'exchanged into Skill Improvements.\n'
            '(6)-[Passive]: Treat your Attribute Scores as 1/2 (rounded up) '
            'of SKI higher for Prerequisites; and [1/Round] reduce a '
            'Signature Technique\'s Ki Cost by SKI.\n'
            '(7)-[Triggered, 1/Round]: If targeted by an attack, +SKI Strike '
            'and Dodge for that attack.\n'
            '(8)-[Triggered, 1/Encounter]: In a Might/Saving-Throw Clash, '
            '+SKI Dice Score.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Seeking Strength',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Strength is Everything',
        description: 'You have given up on gaining any skill in the pursuit '
            'of raw power.\n'
            '(1)-[Ruling]: If you have exchanged all Power-Level Character '
            "Perks into Attribute Additions, you are 'On the Path'.\n"
            '(2)-[Passive]: Increase the Attribute Score Limit by 1(bT).\n'
            '(3)-[Passive]: Upon gaining this Awakening, select AG/FO/TE/MA; '
            'while On the Path, +1(T) that Attribute Modifier.\n'
            '(4)-[Passive]: While On the Path, +1(bT) Combat Rolls and Soak '
            'Value.\n'
            "(5)-[Ruling]: 'STR' = the number of Power-Level Character Perks "
            'exchanged into Attribute Additions.\n'
            '(6)-[Triggered, 1/Round]: When attacking, +STR Wound Roll.\n'
            '(7)-[Triggered, 1/Round]: When targeted by an attack, +STR '
            'Damage Reduction for that attack.\n'
            '(8)-[Triggered, 1/Encounter]: If you attack while On the Path, '
            'apply 2 Energy Charges to that attack.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Spark of Divinity',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Awoken Embers',
        description: 'The smoldering coals of divine power slumbering within '
            'you have blazed to life, igniting a godly blaze inside you.\n'
            '(1)-[Passive]: Upon gaining this Awakening, gain a '
            'Transformation with the God Ki Aspect you qualify for.\n'
            '(2)-[Passive]: While in the God Ki State, increase your Stress '
            'Bonus by 1.\n'
            '(3)-[Passive]: While in the God Ki State, increase your Combat '
            'Rolls by 1(T).\n'
            '(4)-[Triggered/Start of Turn]: If in a God Ki Aspect '
            'Transformation, regain 2(bT) Divine Ki Points.\n'
            '(5)-[Triggered/Power, 1/Encounter]: If in a God Ki Aspect '
            'Transformation, enter the Blazing God Special State until the '
            'start of your next turn (doubles the God Ki State Combat bonus, '
            'adds Ki Wagers on Divine-Ki attacks).',
        automation: [
          // (3) While in the God Ki State (tracked in the States list):
          // +1(T) Combat Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'God Ki',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Superior Fission',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'You have a Fission Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Uneven Split of Power',
        description: '(1)-[Passive]: Upon gaining this Awakening, select 2 '
            "Attributes (except FO/MA); increase this Transformation's "
            'Attribute Modifier for them by 1.\n'
            '(2)-[Passive]: Ignore the 1st effect of your Fission Trait.\n'
            '(3)-[Passive]: Increase your maximum Life and Ki Points by 2 '
            'for each Power Level reached.\n'
            '(4)-[Passive]: While in a Combat Encounter with an '
            'opposite-Alignment Opponent, +1(T) Combat Rolls.\n'
            '(5)-[Passive]: Per Fission Trait: Paragon — +2(T) Surgency; '
            'Renegade — +1(T) Strike Rolls.\n'
            '(6)-[Passive]: Per Fission Trait: Paragon — [1/Round] on taking '
            'Damage, Basic Attack Out-of-Sequence at the attacker; Renegade '
            '— [1/Round] apply an Energy Charge when you hit an Opponent.',
        automation: [
          // (3) +2 Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Team Dynamic',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '1+ Teamwork Talents',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Squad Combat',
        description: "(1)-[Ruling]: Allies with the Team Dynamic Awakening "
            "are 'Teammates'.\n"
            "(2)-[Passive]: For Team Dynamic's Traits, Minions are not "
            'considered Allies.\n'
            '(3)-[Passive]: While a non-Defeated Ally has Team Dynamic, +1(T) '
            'Combat Rolls and Surgency.\n'
            '(4)-[Passive]: +1(T) Wound Rolls of any attack you United '
            'Attack in response to.\n'
            '(5)-[Passive]: Upon gaining access to the Team Dynamic Awakening, '
            'select and gain access to a Team Role Trait (choose below).',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Team Role',
            options: [
              TraitOption(
                name: 'Team Captain',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    "Trait. (2)-[Passive]: Increase the AMB (AG/TE/SC/IN/PE) of "
                    'Team Dynamic by 1. (3)-[Passive]: While an Ally (that is '
                    'not Defeated) possesses the Team Dynamic Awakening, '
                    'increase your Combat Rolls by 1(T). (4)-[Triggered, '
                    '1/Round]: If your Attacking Maneuver is targeted by the '
                    'United Attack Maneuver by a Teammate, apply an Energy '
                    'Charge to that Attacking Maneuver for each Ally that is '
                    'using the United Attack Maneuver (max. 3 Energy Charges). '
                    '(5)-[Triggered, 1/Encounter]: If a Teammate is Defeated, '
                    'you may spend 8(bT) Ki Points. If you do, that Character '
                    'may use a Healing Surge as an Out-of-Sequence Maneuver.',
                ambFlatBonus: {
                  DbuAttribute.agility: 1,
                  DbuAttribute.tenacity: 1,
                  DbuAttribute.scholarship: 1,
                  DbuAttribute.insight: 1,
                  DbuAttribute.personality: 1,
                },
              ),
              TraitOption(
                name: 'Team Powerhouse',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    'Trait. (2)-[Passive]: Increase the AMB (FO/TE/MA) of Team '
                    'Dynamic by 2. (3)-[Passive]: Increase your Wound Rolls and '
                    'Soak Value by 1(T). (4)-[Triggered, 1/Round]: If a '
                    'Teammate is hit by an Attacking Maneuver, you may use the '
                    'Intervene Maneuver without spending a Counter Action (but '
                    'you must target that Ally). (5)-[Triggered, 1/Round]: If '
                    'you hit an Opponent with an Attacking Maneuver and that '
                    'Opponent is adjacent to a Teammate, you may apply an '
                    'Energy Charge to that Attacking Maneuver.',
                ambFlatBonus: {
                  DbuAttribute.force: 2,
                  DbuAttribute.tenacity: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                      AffectedStat.soak,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Team Speedster',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    'Trait. (2)-[Passive]: Increase the AMB (AG) of Team '
                    'Dynamic by 2 and the AMB (FO/IN/MA) of Team Dynamic by 1. '
                    '(3)-[Passive]: Increase your Defense Value and Speeds by '
                    '1(T). (4)-[Triggered, 1/Round]: If you use the Movement '
                    'Maneuver with a willing, adjacent Teammate of the same or '
                    'smaller Size Category than you, you may move that Ally '
                    'along the path of your Movement Maneuver, so that at the '
                    'end of the Movement Maneuver, they end their movement on '
                    'a Square adjacent to you. (5)-[Triggered, 1/Round]: If you '
                    'and/or an adjacent Teammate are targeted by an Attacking '
                    'Maneuver, you may use the Basic Attack Maneuver as an '
                    'Out-of-Sequence Maneuver. If you do, it must target the '
                    'attacking Character. If you deal Damage with this '
                    "Attacking Maneuver, reduce that Opponent's Strike Roll by "
                    '1(bT) for the duration of their Attacking Maneuver.',
                ambFlatBonus: {
                  DbuAttribute.agility: 2,
                  DbuAttribute.force: 1,
                  DbuAttribute.insight: 1,
                  DbuAttribute.magic: 1,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.defenseValue,
                      AffectedStat.speedNormal,
                      AffectedStat.speedBoosted,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Team Striker',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    'Trait. (2)-[Passive]: Increase the AMB (IN) of Team '
                    'Dynamic by 2 and the AMB (FO/MA) of Team Dynamic by 1. '
                    '(3)-[Passive]: Increase your Strike Rolls by 1(T). '
                    '(4)-[Triggered, 1/Round]: If you use the Signature '
                    'Technique Maneuver to target an Opponent with an Attacking '
                    'Maneuver while they are adjacent to a Teammate, you may '
                    'make that Attacking Maneuver a Called Shot. (5)-[Triggered, '
                    '1/Round]: If a Teammate hits an Opponent with an Attacking '
                    'Maneuver, you may use the Basic Attack Maneuver or '
                    'Signature Technique Maneuver as an Out-of-Sequence '
                    'Maneuver.',
                ambFlatBonus: {
                  DbuAttribute.insight: 2,
                  DbuAttribute.force: 1,
                  DbuAttribute.magic: 1,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.strike],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Team Mystic',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    'Trait. (2)-[Passive]: Increase the AMB (IN) of Team '
                    'Dynamic by 2 and the AMB (FO/MA) of Team Dynamic by 1. '
                    '(3)-[Passive]: Increase your Wound Rolls and Surgency by '
                    '1(T). (4)-[Triggered, 1/Round]: If you use a Unique '
                    'Ability to target a Teammate, you may reduce the Ki Point '
                    'Cost by 2(T). (5)-[Triggered, 1/Round]: If you use a '
                    'Unique Ability to target an Opponent adjacent to a '
                    'Teammate, you may increase the Dice Score for any Clash '
                    'that uses your Might or Saving Throws through its effects '
                    'by 1(T). If that Clash uses a Skill, you may instead '
                    'increase its Dice Score by 2.',
                ambFlatBonus: {
                  DbuAttribute.insight: 2,
                  DbuAttribute.force: 1,
                  DbuAttribute.magic: 1,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                      AffectedStat.surgency,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Team Mascot/Strategist',
                description: '(1)-[Passive]: If any of your Allies possess this '
                    'Trait, lose access to the 4th and 5th effects of this '
                    'Trait. (2)-[Passive]: Increase the AMB (SC/PE) of Team '
                    'Dynamic by 2 and the AMB (AG/TE) of Team Dynamic by 1. '
                    '(3)-[Passive]: Increase your Personality and Scholarship '
                    'Modifiers by 1(T). (4)-[Triggered, 1/Round]: If a Teammate '
                    'makes a Combat Roll, you may increase the Dice Score of '
                    'that Combat Roll by 1/4 (rounded up) of your Personality '
                    'or Scholarship Modifier. (5)-[Triggered, 1/Round]: If a '
                    "Teammate is hit by an Opponent's Attacking Maneuver, you "
                    'may reduce the Damage they receive by 1/2 of your '
                    'Personality or Scholarship Modifier.',
                ambFlatBonus: {
                  DbuAttribute.scholarship: 2,
                  DbuAttribute.personality: 2,
                  DbuAttribute.agility: 1,
                  DbuAttribute.tenacity: 1,
                },
                // (3) +1(T) Personality & Scholarship Modifiers.
                ambPerTierBonus: {
                  DbuAttribute.personality: 1,
                  DbuAttribute.scholarship: 1,
                },
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Time-Skipper',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Beyond the Time',
        description: "You've trained in esoteric skills which allow you to "
            'exist beyond the normal bounds of time itself; able to skip '
            'ahead through it and take your enemies by surprise.\n'
            "(1)-[Passive]: During Opponents' turns, +1(bT) Dodge and "
            'Defend-Maneuver Strike Rolls.\n'
            '(2)-[Passive]: During your or an Ally\'s turn, +1(bT) Strike '
            'Rolls.\n'
            '(3)-[Passive]: Gain access to the Time-Skip Unique Ability '
            '(detailed below).\n'
            '(4)-[Triggered]: If you Time-Skip attack an Opponent of '
            'equal/lower Power Level, do not pay the Ki Cost.\n'
            '(5)-[Triggered, 1/Encounter]: Via Time-Skip Movement, move '
            'anywhere; if adjacent to an Opponent, an auto-hitting Simple '
            'Basic Attack Out-of-Sequence.\n'
            '(6)-[Triggered, 1/Encounter]: A Time-Skip attack may be set to '
            'Lethal (irreducible).\n'
            '\n'
            'Time-Skip Unique Ability — You can force your way past a point in '
            'time, effectively acting outside of that point in time to perform '
            'your task immediately. Ability Type: Technical; Prerequisites: '
            'Time Skipper Awakening; TP Cost: N/A; KP Cost: 4(T); Maneuver '
            'Type: Instant. Effect: You may either use the Movement Maneuver '
            'as an Out-of-Sequence Maneuver, or use the Basic Attack Maneuver '
            'as an Out-of-Sequence Maneuver.\n'
            'Time-Skip Advancements:\n'
            '• Imperceptible Strike (TP 10): Your Attacking Maneuvers made '
            'through the Time-Skip Unique Ability do not suffer from, or count '
            'towards, the penalty from Diminishing Offense.\n'
            '• Barrage from Time (TP 5): You can use the Time-Skip Unique '
            'Ability an additional time per Combat Round.\n'
            '• Time to Make the Donuts (TP 5): You can use the Signature '
            'Technique Maneuver through the effects of Time-Skip instead of '
            'the Basic Attack Maneuver. That Signature Technique Maneuver must '
            'have the Time-Skipped Disadvantage.\n'
            '• Walk through Time (TP 15): Gain access to the Tides of Time '
            'Special Maneuver.\n'
            '• Time Shift (TP 15): Gain access to the Time Lag Special '
            'Maneuver.\n'
            '• Time Restraint (TP 15): Gain access to the Time Prison Special '
            'Maneuver.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Transformation Reliant',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to a Form',
    // Base AMB is negative outside a Form; the 6th trait effect makes the
    // AG/FO/TE/IN/MA values positive while in a Form.
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: -1),
      DbuAttribute.force: TransformationAmb(coefficient: -1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: -1),
      DbuAttribute.insight: TransformationAmb(coefficient: -1),
      DbuAttribute.magic: TransformationAmb(coefficient: -1),
      DbuAttribute.personality: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Awoken by Transformation',
        description: 'Outside of your transformation, you are no different '
            'from any other ordinary citizen. Once you transform, however, '
            'your power is enough to completely eradicate the '
            'competition.\n'
            '(1)-[Passive]: While not in a Form, halve your Maximum Life '
            'Points (auto-succeed Steadfast Checks for Thresholds crossed by '
            'entering a Form).\n'
            '(2)-[Passive]: Reduce your Combat Rolls and Soak Value by '
            '1(bT).\n'
            '(3)-[Triggered/Start of Turn]: While not in a Form, gain a '
            'stack of Anticipation (max 3).\n'
            '(4)-[Passive]: With 2+ Anticipation, +1 Stress Bonus.\n'
            '(5)-[Passive]: While in a Form, +1(T) Combat Rolls and Soak '
            'Value per Anticipation stack.\n'
            '(6)-[Passive]: While in a Form, this Awakening\'s AG/FO/TE/IN/MA '
            'Attribute Modifier Bonuses become positive values.\n'
            '(7)-[Triggered, 1/Encounter]: If you enter a Form, regain 1/2 '
            'of your Maximum Life Points.\n'
            '(8)-[Triggered, 1/Encounter]: If you enter a Form with 3 '
            'Anticipation, +1 Tier of Power until the end of your turn.',
        automation: [
          // (2) -1(bT) Combat Rolls and Soak Value. ((1)'s Max Life halving
          // is multiplicative — text only.)
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: -1,
            tierScaling: TierScaling.base,
          ),
          // (5) While in a Form: +1(T) Combat Rolls and Soak Value per
          // tracked 'Anticipation' Resource stack.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perNamedResourceStack,
            resourceName: 'Anticipation',
            condition: TraitCondition.whileInForm,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Unlocked Potential',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Potential',
        description: 'Hidden within you lies a dormant power that was '
            'previously untapped, now brought to the surface.\n'
            '(1)-[Passive]: While you have a Power stack, +Z(bT) Combat '
            'Rolls and Soak Value.\n'
            '(2)-[Passive]: Reduce the penalty from a Botch Result by Z(bT) '
            'on Combat Rolls.\n'
            '(3)-[Passive]: For each Power Level reached, +Z Maximum Life '
            'and Ki Points.\n'
            '(4)-[Passive]: Increase the Dice Category of your Critical '
            'Result Extra Die by Z Categories.\n'
            '(5)-[Triggered, Z/Round]: After a Combat Roll, +1 Natural '
            'Result (can score a Critical or avoid a Botch).\n'
            '(6)-[Triggered/Power, 1/Encounter]: Enter the Surging State '
            'until the end of your turn.',
        automation: [
          // (1) While you have a Power stack: +Z(bT) Combat Rolls and Soak.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileAnyPowerStack,
            perTransformationStack: true,
          ),
          // (3) +Z Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Deeper Potential',
        minStacks: 2,
        description: 'Even deeper inside you, another wellspring of your '
            'potential bubbles to the surface, granting you immeasurable '
            'power.\n'
            '(1)-[Passive]: While in the Surging State, +2(T) Wound Rolls.\n'
            '(2)-[1/Encounter]: Use the Power Up Maneuver as an Instant '
            'Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: After a Combat Roll, set its '
            'Natural Result to 10.',
        automation: [
          // (1) While in the Surging State (tracked in the States list):
          // +2(T) Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Surging',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Witchcraft',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any Race',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Skill Ranks in Use Magic',
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Mystic Talisman',
        description: 'You are able to warp reality with the mystical '
            'talismans you use, unleashing powerful magic to conquer your '
            'enemies.\n'
            '(1)-[Triggered/Start of Combat Encounter, Resource]: Gain 2 '
            'Talismans per Use Magic Skill Rank (your maximum).\n'
            '(2)-[Passive]: While you have 2+ Talismans, +1(T) Cognitive '
            'Save.\n'
            '(3)-[Passive]: While you have a Talisman, gain access to the '
            'Illusion Unique Ability (and its Advancements).\n'
            '(4-5)-[Triggered]: Spend a Talisman to reduce a Magic '
            "Attack's/Magical Unique Ability's Ki Cost by 4(T).\n"
            '(6)-[1/Round]: Spend a Talisman to turn a non-Special Minion '
            'into your Minion (Jiang Shi Talisman as Lv1 Temp Awakening).\n'
            '(7)-[1/Encounter]: Spend 2 Talismans to turn a Character into '
            'your Ally (Jiang Shi Talisman as Lv2 Temp Awakening).\n'
            '(8-9)-[Triggered/Start of Turn]: Spend a Talisman for a Favored '
            'Element or the Invisible State.\n'
            '(10)-[Triggered, 1/Encounter]: On a Ki Surge, gain Talismans = '
            'your Use Magic Skill Ranks.',
      ),
    ],
  ),
  // Added post-ZIM (2026-07-12) from the live site (Transformation pages
  // published after the offline archive was captured).
  TransformationDef(
    name: 'Limitless Ki',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Rising, Overflowing Ki',
        description: '(1)-[Passive]: Increase your Maximum Ki Points by 2 '
            'for each Power Level reached.\n'
            '(2)-[Passive]: Increase your Max Capacity by 1 for each Power '
            'Level reached.\n'
            '(3)-[Passive]: Increase the Ki Point Cost of all your Attacking '
            'Maneuvers by 2(T).\n'
            '(4)-[Passive]: Increase the Wound Rolls of all your Attacking '
            'Maneuvers by 3(T).\n'
            '(5)-[Passive]: While your Ki Points exceed your Max Capacity, '
            'increase your Combat Rolls and Soak Value by 1(bT).\n'
            '(6)-[Passive]: Halve your Surgency for Healing Surges; increase '
            'it by 1/2 for Ki Surges.\n'
            '(7)-[1/Encounter]: While your Ki Points are below your Max '
            'Capacity, use a Ki Surge as an Instant Maneuver.',
        automation: [
          // (1) +2 Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +1 Max Capacity per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxCapacity],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (4) +3(T) Wound Rolls on all Attacking Maneuvers.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 3,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  // ============================================================= ANDROID ===
  TransformationDef(
    name: 'Improved Core',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Improved Schematics Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Unlocked Energy',
        description: 'Your power core surges with unlimited potential, '
            'improving your stamina and efficiency.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: While in the Healthy Health Threshold, increase '
            'your Combat Rolls by 1(T).\n'
            '(3)-[Triggered/Start of Turn, 1/Encounter]: Use a Ki Surge as '
            'an Out-of-Sequence Maneuver.\n'
            "(4)-[Ruling]: Upon gaining this Awakening, gain a 'Core Trait' "
            'per your Energy Core / Mutant Core choice (detailed below).\n'
            '\n'
            'Truly Infinite — (1)-[Prerequisite]: You selected Infinite Energy '
            'for the Option effect of Energy Core. (2)-[Passive]: Your Ki '
            'Points can enter negative values. (3)-[Passive]: While in your '
            'Healthy Health Threshold, increase your Max Capacity by 1/4.\n'
            'Fully Powered — (1)-[Prerequisite]: You selected Power Battery for '
            'the Option effect of Energy Core. (2)-[Passive]: While your Ki '
            'Points exceed your Max Capacity, you are considered to be in the '
            'Healthy Health Threshold (in addition to whatever Health '
            'Threshold you are in). (3)-[Passive]: While your Ki Points exceed '
            'your Max Capacity, increase your Damage Reduction and Wound Rolls '
            'by 2(T).\n'
            'Mighty Machine Mutant — (1)-[Prerequisite]: You possess the '
            'Mutant Core Factor Trait. (2)-[Passive]: Increase your Might and '
            'Surgency by 1(T). (3)-[Triggered]: When any of your Integrated '
            'Items are destroyed, regain Life and Ki Points equal to 1/2 of '
            'your Might. (4)-[Triggered, 1/Round]: When you are hit by an '
            'Attacking Maneuver, you can destroy a piece of Integrated Apparel '
            'to reduce the Damage you take by 1/2 of your Might. (5)-[Triggered, '
            '1/Round]: When making an Attacking Maneuver, you can destroy an '
            'Integrated Weapon to increase the Wound Roll of that Attacking '
            'Maneuver by 1/2 of your Might.',
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (2) While in the Healthy Health Threshold: +1(T) Combat Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Super Android',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Super Weapon',
        description: 'Your upgrades have transformed you into a walking '
            'weapon of mass destruction.\n'
            '(1)-[Passive]: While at the Healthy Threshold, +1(T) Combat '
            'Rolls and Damage Reduction.\n'
            '(2)-[Passive]: While your Ki < 1/4 (rounded up) of Max, +2(T) '
            'Surgency.\n'
            '(3)-[Passive]: Upon gaining this Transformation, gain an '
            'additional effect from the 3rd effect of Technological Being.\n'
            '(4)-[Triggered, Resource]: On an Energy Charge, gain a stack of '
            'Reserved Energy (max 6).\n'
            '(5)-[Triggered, 1/Round]: On a Signature Technique, spend '
            'Reserved Energy for +1(T) Wound each.\n'
            '(6)-[Triggered/Power, 1/Round]: Spend Reserved Energy to regain '
            '1(bT) Ki each.\n'
            '(7)-[Triggered, 1/Encounter]: If you spend 3+ Reserved Energy '
            'via the 5th effect, apply an Energy Charge per 3 spent.\n'
            '(8)-[Triggered, 1/Encounter]: If you spend 3+ Reserved Energy '
            'via the 6th effect, use a Healing Surge Out-of-Sequence.',
        automation: [
          // (1) While at the Healthy Threshold: +1(T) Combat Rolls and
          // Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.damageReduction,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
        ],
      ),
    ],
  ),

  // =============================================================== ANGEL ===
  TransformationDef(
    name: 'Mortal Mentality',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Learning from Mortals',
        description: 'You have internalized the lessons you have learned '
            'while mimicking the mortal races, thinking and fighting more '
            'like they do.\n'
            "(1)-[Addendum]: 'Mortal Grit' — while you possess this "
            'Awakening, your Healthy/above-Bruised effects instead apply '
            'below Injured, above-Injured/Critical effects apply below '
            "Bruised, and 'each Threshold above' becomes 'each Threshold "
            "below'.\n"
            '(2)-[Passive]: While below the Injured Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(3)-[Passive]: For each Health Threshold you are below, +1(T) '
            'Surgency.\n'
            '(4)-[Triggered, 1/Round]: If hit by an attack, spend a Counter '
            'Action to reroll Strike/Dodge +1(T), or +3(T) Soak for that '
            'attack.\n'
            '(5)-[1/Encounter]: Below the Bruised Threshold, spend a Counter '
            'Action to use a 1-Action Standard Maneuver as an Instant '
            'Maneuver.\n'
            '(6)-[Triggered/Defeated]: Set Life to 1, turn failed Steadfast '
            'Checks into successes, then Power Up Out-of-Sequence.',
        automation: [
          // (2) While below the Injured Threshold: +1(T) Combat Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
          // (3) +1(T) Surgency per Health Threshold below.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perHealthThresholdBelow,
          ),
        ],
      ),
    ],
  ),

  // ============================================================ ARCOSIAN ===
  TransformationDef(
    name: 'Cybernetic Reconfiguration',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Metalize',
        description: 'You have been beaten, scorched, bisected, blasted, and '
            'set adrift to fend for yourself. Now, thanks to the advances of '
            'medical science, you have cheated death itself.\n'
            '(1)-[Passive]: Reduce your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: While you possess 2+ Cybernetic Enhancement '
            'Factor Traits, +1(T) Damage Reduction.\n'
            "(3)-[Addendum]: 'Cosmic Suit: Equip' — equipping selects and "
            'permanently grants 2 Cybernetic Enhancement Factor Traits.\n'
            '(4)-[Triggered, 1/Round]: On a Signature Technique with 2+ '
            'Cybernetic Factor Traits, apply an Energy Charge (no Overwhelm '
            'stack).\n'
            '(5)-[Triggered/Defeated, 1/Character]: Use the Spontaneous '
            'Reconstruction Special Maneuver Out-of-Sequence (only if you '
            'have no Cybernetic Enhancement Factor Traits).',
        automation: [
          // (1) -2 Racial Life Modifier = -2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: -2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Earned Evolution',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Instant Overwhelm',
        description: 'You have learned to gather greater power and can '
            'channel that energy more effectively.\n'
            '(1)-[Passive]: While below the Injured Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(2)-[Passive]: While below the Critical Threshold, +1 Dice '
            'Category to your Energy Charges.\n'
            '(3)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(4)-[Passive]: For attacks with 3+ Energy Charges, double the '
            'Wound bonus from your Overwhelm stacks.\n'
            '(5)-[1/Round]: If you have not used the Tail Attack Maneuver '
            'this Round, use the Energy Charge Maneuver as an Instant '
            'Maneuver (no Tail Attack this Round).\n'
            '(6)-[Triggered, 1/Round]: On a Signature Technique, spend an '
            'Overwhelm stack to apply an Energy Charge.\n'
            '(7)-[Triggered, 1/Encounter]: Below Injured, a 3+ Energy Charge '
            'Signature Technique becomes Lethal (irreducible).',
        automation: [
          // (1) While below the Injured Threshold: +1(T) Combat Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),

  // ========================================================== BIO-ANDROID ===
  TransformationDef(
    name: 'Perfection',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Bio-Android',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'A Semi-Perfect Step Forward',
        description: 'Your body has evolved, bringing you ever closer to the '
            'sublime image of perfection you were created to be.\n'
            '(1)-[Passive]: Increase your maximum Adaptation Points by Z.\n'
            '(2)-[Passive]: Each time you gain a stack of Perfection, gain a '
            'Perfection Trait (Critical Perfection, Genetic Zenkai, Karyon '
            'Core, Junior Creation, Perfect Defense/Guard/Offense — see the '
            'site).\n'
            '(3-4)-[Choice]: Per your Artificial Warrior 4th-effect choice '
            '(Genetic Survivor/Aggressor/Agility, Pursuit of Perfection), '
            'gain scaling Combat Roll / Surgency / Adaptation Point effects.',
      ),
      TransformationTrait(
        name: 'Long-Awaited Perfection',
        minStacks: 2,
        description: 'You have become a being of resplendent perfection.\n'
            '(1)-[Passive]: Increase your Maximum Life and Ki Points by 2 '
            'for each Power Level reached.\n'
            '(2)-[Passive]: Reduce the Critical Target of your Combat Rolls '
            'by 1.\n'
            '(3)-[Triggered/Start of Turn]: Gain 1 Adaptation Point.\n'
            '(4)-[Triggered/Start of Turn, 1/Encounter]: Spend 3 Adaptation '
            'Points to gain 1 Action.',
        automation: [
          // (1) +2 Max Life and Max Ki per Power Level. ((2)'s Critical
          // Target reduction has no automation channel yet — text only.)
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),

  // =========================================================== CEREALIAN ===
  TransformationDef(
    name: 'Dangerous Glare',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Pressure Point Punisher',
        description: "You've learned how to use your enhanced right eye to "
            'read the body of your enemies to find their pressure points, '
            'and then capitalize on them with ruthless efficiency.\n'
            '(1)-[Passive]: Ignore the Called Shot penalty while free of '
            'Combat Conditions.\n'
            '(2)-[Passive]: Increase the Wound Rolls of your Called Shots by '
            '2(T).\n'
            '(3)-[Passive]: +1(T) Combat Rolls against an Impediment '
            'Opponent.\n'
            "(4)-[Triggered]: If a Called Shot knocks an Opponent through a "
            'Threshold or deals >= 1/5 of their Max Life, their Surgency '
            'becomes 0 until the start of your next turn.\n'
            '(5)-[Triggered, 1/Round]: If you knock an Opponent through a '
            'Threshold, they gain Impediment until the start of your next '
            'turn.\n'
            '(6)-[Triggered/Start of Combat Round]: If below the Injured '
            'Threshold, gain 1 Counter Action.\n'
            '(7)-[Triggered, 1/Encounter]: If you Exploit an Opponent, that '
            'attack becomes a Called Shot.',
      ),
    ],
  ),

  // =========================================================== KONATSIAN ===
  TransformationDef(
    name: 'Advanced Vocation',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Konatsian Race or Konatsian-Raised Factor Trait',
    // AMB is granted by the chosen High Vocation (each adds a large AMB
    // spread to Advanced Vocation); no flat table here.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Vocation Training II',
        description: "You've specialized further into your combat role, "
            'becoming one of the elite.\n'
            "(1)-[Passive, Ruling]: Upon gaining this Awakening, gain a "
            "'High Vocation' (choose below).\n"
            '(2)-[Passive]: Upon gaining this Awakening, gain a Talent of '
            'your choice (meet prerequisites).\n'
            '(3)-[1/Encounter]: As an Instant Maneuver, spend 1 Tension to '
            'use the Surge Maneuver (does not count towards its [1/Encounter] '
            'Keyword).\n'
            '(4)-[Triggered/Start of Turn]: Regain 1(bT) Life Points for '
            'every Health Threshold you are below.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'High Vocation',
            options: [
              TraitOption(
                name: 'Magic Knight',
                description: 'Infusing magical might into your physical '
                    'strikes, you favor close combat with a secondary emphasis '
                    'on battlefield manipulation. (1)-[Prerequisite]: You must '
                    'have access to either the Warrior or Mage Vocation. '
                    '(2)-[Passive]: Increase the AMB (FO/TE/MA) of Advanced '
                    'Vocation by 2. (3)-[Passive]: Increase your Might and '
                    'Damage Reduction by 1(T). (4)-[Passive]: Gain access to '
                    'the Magical Reflect Special Maneuver. (5)-[Triggered, '
                    '1/Round]: If you use a Physical Attack or an Energy '
                    "Attack, you may apply the first effect of a Profile with "
                    "'Elemental' in the name to that Attacking Maneuver. "
                    '(6)-[Triggered, 1/Round]: If you use a Magic Attack, you '
                    'may spend any number of Tension stacks; for each spent, '
                    'apply an Energy Charge to that Attacking Maneuver (you do '
                    'not lose these stacks until after you complete that '
                    'Attacking Maneuver).',
                ambFlatBonus: {
                  DbuAttribute.force: 2,
                  DbuAttribute.tenacity: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.might,
                      AffectedStat.damageReduction,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Gladiator',
                description: "You've fought countless enemies, and have "
                    "learned to exploit the weaknesses of a creature's "
                    'biology. (1)-[Prerequisite]: You must have access to '
                    'either the Warrior, Martial Artist, or Ranger Vocation. '
                    '(2)-[Passive]: Increase the AMB (AG/FO/MA) of Advanced '
                    'Vocation by 2. (3)-[Passive]: Increase your Strike and '
                    'Dodge Rolls by 1(T). (4)-[Triggered/Power, Ruling, '
                    "1/Round]: Select a Race. That Race becomes your 'Undone' "
                    'until the start of your next turn. (5)-[Passive]: '
                    'Increase your Wound Rolls by 1(T) for each stack of '
                    'Tension you possess against Characters of your Undone '
                    'Race. (6)-[Triggered, 1/Round]: If you use a Physical or '
                    'Energy Attack that only targets Character(s) of the '
                    'Undone Race, increase the Damage Category of that '
                    'Attacking Maneuver by 1 Category.',
                ambFlatBonus: {
                  DbuAttribute.agility: 2,
                  DbuAttribute.force: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.strike, AffectedStat.dodge],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Paladin',
                description: 'As a holy warrior dedicated to banishing evil '
                    'wherever it may roam, you focus on keeping your friends '
                    'alive... and your enemies disposed-of. (1)-[Prerequisite]: '
                    'You must have access to either the Warrior, Martial '
                    'Artist, or Priest Vocation. (2)-[Passive]: Increase the '
                    'AMB (FO/TE/MA) of Advanced Vocation by 2. (3)-[Passive]: '
                    'Increase your Damage Reduction and Wound Rolls by 1(T) '
                    'and 2(T) respectively. (4)-[Passive]: Increase the '
                    'Surgency of yourself and all Allies by 2(T). '
                    '(5)-[Passive]: Gain access to the Grand Cross Special '
                    'Maneuver. (6)-[Triggered, 1/Encounter]: If you knock an '
                    'Opponent through the Injured or Critical Health Threshold '
                    'with an Attacking Maneuver, you may roll a 1d10. On a '
                    "result of 10, that Opponent's Life Points are reduced to "
                    'their lowest possible value and they are Defeated.',
                ambFlatBonus: {
                  DbuAttribute.force: 2,
                  DbuAttribute.tenacity: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.damageReduction],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                      AffectedStat.surgency,
                    ],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Sage',
                description: 'A true scholar of magic, you have achieved the '
                    'pinnacle of mystical prowess, allowing you to command the '
                    'battlefield as if it were your very own. '
                    '(1)-[Prerequisite]: You must have access to either the '
                    'Mage, Priest, or Gadabout Vocation. (2)-[Passive]: '
                    'Increase the AMB (IN/MA) of Advanced Vocation by 2. '
                    '(3)-[Passive]: Increase your Wound Rolls and Surgency by '
                    '2(T). (4)-[Passive]: Increase your Maximum Ki Points by 2 '
                    'for each Power Level reached. (5)-[Passive]: You may use '
                    'the Profiles of the Energy Profile, even if you do not '
                    'meet the Force Score requirement; additionally, you may '
                    'use your Magic Modifier as the Damage Attribute. '
                    '(6)-[Passive]: Gain access to the Boom, Zoom, Whack, and '
                    'Hocus Pocus Special Maneuvers (see - Konatsians). '
                    '(7)-[Triggered, 1/Encounter]: If you use an Energy Attack '
                    'or Magic Attack, you may spend 1 Tension to spend Life '
                    'Points up to 1/4 (rounded up) of your Maximum Life Points; '
                    'increase the Wound Roll of that Attacking Maneuver by an '
                    'equal amount.',
                ambFlatBonus: {
                  DbuAttribute.insight: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                      AffectedStat.surgency,
                    ],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                  ),
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.maxKi],
                    coefficient: 2,
                    tierScaling: TierScaling.none,
                    kind: TraitMagnitudeKind.perPowerLevel,
                  ),
                ],
              ),
              TraitOption(
                name: 'Pirate',
                description: 'Swashbuckling and suave, you are skilled at '
                    'locking down your opponents and escaping their wrath '
                    'before they can strike back. (1)-[Prerequisite]: You must '
                    'have access to either the Thief or Ranger Vocation. '
                    '(2)-[Passive]: Increase the AMB (AG/SC/IN/PE) of Advanced '
                    'Vocation by 2. (3)-[Passive]: Increase your Speeds and '
                    'Dodge Rolls by 1(T) and the Skill Bonus of your Skills by '
                    '1. (4)-[Passive]: Gain access to the Coral Rain Special '
                    'Maneuver. (5)-[Triggered, 1/Round]: If you succeed at a '
                    'Clash against an Opponent for the effects of a Thief '
                    'Skill or if you deal Damage through an Attacking Maneuver '
                    'made through the 3rd effect of the Ranger Vocation, you '
                    "may reduce that Character's Ki Points by an amount equal "
                    'to your highest Attribute Modifier. (6)-[Triggered, '
                    '1/Round]: If you inflict a Combat Condition on an '
                    'Opponent, you may spend 1 Tension to use a Standard '
                    'Maneuver with an Action Cost of 1 Action as an '
                    'Out-of-Sequence Maneuver.',
                ambFlatBonus: {
                  DbuAttribute.agility: 2,
                  DbuAttribute.scholarship: 2,
                  DbuAttribute.insight: 2,
                  DbuAttribute.personality: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.dodge,
                      AffectedStat.speedNormal,
                      AffectedStat.speedBoosted,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Monster Master',
                description: 'Specializing in controlling bestial companions, '
                    'you bring a wide variety of unique options for '
                    'problem-solving to the team. (1)-[Prerequisite]: You must '
                    'have access to either the Thief, Ranger, or Dancer '
                    'Vocation. (2)-[Passive]: Increase the AMB (FO/IN/MA) of '
                    'Advanced Vocation by 2. (3)-[Passive]: Increase your Soak '
                    'Value by 2(T) and the Skill Bonus of your Skills by 1. '
                    '(4)-[Passive]: Increase the Wound Rolls of your Allies by '
                    '1(T). (5)-[Passive]: Increase the Combat Rolls and Soak '
                    'Value of your Minions of the Animal or Creature Minion '
                    'Race by 1(T). (6)-[Passive]: Gain access to the War Cry '
                    'Special Maneuver. (7)-[Passive]: Gain access to the '
                    'Elemental Breath Signature Technique (usable only via the '
                    '8th effect of Monster Master; use Force or Magic Modifier '
                    'as the Damage Attribute). (8)-[Triggered, 1/Round]: Apply '
                    "a Profile with 'Elemental' in the name to the Elemental "
                    'Breath Signature Technique; you may also apply the '
                    'Compressed Element Disadvantage to apply a rank of the '
                    'Power Shot Advantage. (9)-[Triggered, 1/Round]: If you '
                    'inflict the Shaken Combat Condition on an Opponent, you '
                    'may spend up to 2 Tension to inflict an equal number of '
                    'stacks of the Broken Combat Condition.',
                ambFlatBonus: {
                  DbuAttribute.force: 2,
                  DbuAttribute.insight: 2,
                  DbuAttribute.magic: 2,
                },
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Luminary',
                description: 'A performer in the truest sense, you direct the '
                    'battlefield like a conductor over an orchestra, ensuring '
                    'that your comrades never fall, and your enemies never '
                    'rise. (1)-[Prerequisite]: You must have access to either '
                    'the Dancer or Gadabout Vocation. (2)-[Passive]: Increase '
                    'the AMB (PE) of Advanced Vocation by 4. (3)-[Passive]: '
                    'Increase your Maximum Life Points by 2 for each Power '
                    'Level reached. (4)-[Passive]: Increase your Morale Save '
                    'by 1(T). (5)-[Passive]: Gain access to the Song of '
                    'Salvation Special Maneuver. (6)-[Passive]: Gain access to '
                    'the Dance and Goof Special Maneuvers (see - Konatsians). '
                    '(7)-[Triggered, 1/Round]: If an Ally who is not at Long '
                    'Range takes Damage from an Attacking Maneuver, you may '
                    'reduce that Damage by your Personality Modifier. '
                    '(8)-[Triggered, 1/Round]: If an Ally who is not at Long '
                    'Range hits an Opponent with an Attacking Maneuver, you '
                    'may increase their Wound Roll by your Personality '
                    'Modifier.',
                ambFlatBonus: {DbuAttribute.personality: 4},
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.maxLife],
                    coefficient: 2,
                    tierScaling: TierScaling.none,
                    kind: TraitMagnitudeKind.perPowerLevel,
                  ),
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.moraleSave],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'The Hero',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Konatsian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Chosen Hero',
        description: 'Your destiny to fight against the darkness grants you '
            'the strength to succeed.\n'
            '(1)-[Passive]: Gain access to the Hero Vocation (detailed '
            'below).\n'
            '(2)-[Passive]: Ignore all Health Threshold Penalties while in '
            'the Entrusted Special State.\n'
            '(3)-[Triggered/Entrusted]: Remove all Combat Conditions you are '
            'currently suffering from (except Pinned, Suffocating, or '
            'Transfigured).\n'
            '(4)-[Triggered, 1/Encounter]: If you would have your Life Points '
            'reduced to 0, spend 1 Tension to set your Life Points to 1.\n'
            '(5)-[Triggered/Power, 1/Encounter]: If you have 3+ Tension, enter '
            'the Entrusted State until the start of your next turn. If you do, '
            'ignore the 3rd and 4th effects of the Entrusted State while you '
            'are in it due to this effect.\n'
            '\n'
            'Hero Vocation: You specialize in bringing targets down to your '
            'level, opening them up for a final strike, or in delivering the '
            'devastating finishing blow with your own two hands.\n'
            '(1)-[Passive]: Increase your Maximum Life and Ki Points by 2 for '
            'each Power Level reached.\n'
            '(2)-[Passive]: Increase your Combat Rolls and Damage Reduction by '
            '1(T) while in the Entrusted State.\n'
            '(3)-[Passive]: Gain access to the Disruptive Wave Special '
            'Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you are involved in a Clash that '
            'uses your Might, you may spend up to 2 stacks of Tension. For '
            'each stack of Tension spent, increase your Dice Score for that '
            'Clash by 1(T).\n'
            '(5)-[Triggered, 1/Encounter]: If you use an Ultimate Signature '
            'Technique, you may spend 1 Tension to apply the Complete '
            'Annihilation Super Profile to that Attacking Maneuver.\n'
            '(6)-[Triggered/Start of Combat Round]: Regain x(bT) Life and Ki '
            'Points, where x is equal to how many stacks of Tension you '
            'possess (max. 3(bT)).\n'
            'Disruptive Wave [1/Round] — Maneuver Type: Standard; Action Cost: '
            '1 Action; KP Cost: 4(T); Exploitable: All adjacent Opponents. '
            'Effect: Target an Opponent that is not at Long Range and is in '
            'the Superior and/or Surging State. Make a Clash (Might) against '
            'that Opponent. If you win, they leave the Superior and/or Surging '
            'State(s) immediately.',
      ),
    ],
  ),

  // ============================================================= ABSORBER ===
  TransformationDef(
    name: 'Eternally Entwined',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '1+ stack of the Absorption Awakening',
    // AMB comes from tripling your Eternal Connection's Absorption AMB
    // (trait effect 4) — not a flat table.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Permanent Connection',
        description: "One of the many entities you've absorbed has become a "
            'core part of your being.\n'
            '(1)-[Ruling]: Upon gaining this Awakening, select a '
            'non-Temporary Absorption stack as your Eternal Connection.\n'
            '(2)-[Passive]: You cannot lose your Eternal Connection.\n'
            '(3)-[Passive]: Gain a Primary Racial Trait of the Eternal '
            "Connection's Absorbed Character (or a Secondary if you have all "
            'Primaries).\n'
            '(4)-[Passive]: Triple your Attribute Modifier Bonus from your '
            'Eternal Connection (Absorption AMB).\n'
            '(5-6)-[Passive]: Each Power Level / Awakening you gain, the '
            'Absorbed Character gains one too (ARC decides).\n'
            "(7)-[Triggered, 1/Round]: If you use the Absorbed Character's "
            'Signature Technique, +1/2 their Might to its Wound Roll.\n'
            '(8)-[Triggered/Start of Turn, 1/Encounter]: Use the Copy Being '
            'Unique Ability Out-of-Sequence targeting the Absorbed Character '
            '(even without access to it).',
      ),
    ],
  ),

  // =============================================================== MAJIN ===
  TransformationDef(
    name: 'Super Majin',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Majin Mania',
        description: 'You become a veritable juggernaut, allowing you to '
            'shake off damage and continue fighting long past when most '
            'would go down.\n'
            '(1)-[Passive]: While at the Healthy Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(2)-[Passive]: While below the Injured Threshold, +2(T) '
            'Surgency.\n'
            '(3)-[Passive]: Ignore the 6th effect of Rubbery Body.\n'
            '(4)-[Passive]: On gaining this Awakening, you may change your '
            'base Size Category, gain Factors, swap Majin Secondary Racial '
            'Traits, or refund Signature Techniques.\n'
            '(5)-[Passive]: Upon gaining this Awakening, gain an additional '
            'Majin Secondary Racial Trait.\n'
            '(6)-[Triggered, 1/Round]: If hit by an attack, regain Life = '
            'your Surgency before Damage calculation.\n'
            '(7)-[Triggered/Start of Turn]: Regain Life = 1/4 (rounded up) '
            'of your Surgency.\n'
            '(8)-[Triggered/Defeat]: Use a Healing Surge Out-of-Sequence '
            'with doubled Surgency.',
        automation: [
          // (1) While at the Healthy Threshold: +1(T) Combat Rolls and Soak.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
          // (2) While below the Injured Threshold: +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),
  // ============================================================ NAMEKIAN ===
  TransformationDef(
    name: 'Super Namekian',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Enhanced Namekian',
        description: 'Granted new strength by your enhanced biology, your '
            'ability to regenerate and your options in combat grow '
            'considerably.\n'
            '(1)-[Passive]: While at the Healthy Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(2)-[Passive]: While below the Injured Threshold, +2(T) '
            'Surgency.\n'
            '(3)-[Passive]: +1(T) Wound Rolls against Studied Opponents.\n'
            '(4)-[Passive]: While you have a Studied Ally, +1(T) their Wound '
            'Rolls.\n'
            '(5)-[Passive]: Do not increase the Ki Cost of Namekian '
            "Biology's 3rd effect through its own effect.\n"
            '(6)-[Passive]: Per Subrace: Warrior Clan — an extra Refined '
            'Combat 3rd-effect option; Dragon Clan — an extra Spirit of '
            'Namek 4th-effect option.\n'
            '(7)-[Triggered, 1/Encounter]: If you fail a Steadfast Check, '
            'spend up to 6(bT) Life for +1 Dice Score per 2(bT) (can '
            'retroactively succeed).\n'
            '(8)-[Triggered, 1/Encounter]: If your Life rises above a '
            'Threshold, use the Power Up Maneuver Out-of-Sequence.',
        automation: [
          // (1) While at the Healthy Threshold: +1(T) Combat Rolls and Soak.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
          // (2) While below the Injured Threshold: +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),

  // =========================================================== NEKO MAJIN ===
  TransformationDef(
    name: 'Copy Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Neko Majin',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Transformative Mimicry',
        description: "Instead of using your own transformation, you mimic "
            "what you've seen.\n"
            '(1)-[Triggered/Start of Turn, Ruling, 1/Encounter]: While in '
            'your Normal State, spend Ki equal to 1/2 of Max Capacity to '
            "make a Character your 'Template' until the end of the "
            'Encounter.\n'
            '(2)-[Automatic]: If you fail a Steadfast Check or Stress Test, '
            'they stop being your Template.\n'
            '(3)-[Passive]: Gain access to the Primary Racial Traits of your '
            'Template (make the same choices as them).\n'
            '(4)-[Passive]: Gain access to any Forms or Enhancements of your '
            'Template (ignore Racial Requirements; meet other Prerequisites '
            'and ToP; same choices as them).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Feline Originality',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Neko Majin',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Paws Off',
        description: '(1)-[Passive]: All your Signature Techniques are '
            'considered Copied Techniques for your Neko Majin Racial Traits '
            'and Transformation Traits.\n'
            '(2)-[Passive]: Reduce the Ki Cost of Signature Techniques not '
            'gained via Quick Learner by 2(T).\n'
            "(3)-[Passive]: While you haven't used Quick Learner's 1st "
            'effect this Encounter, +1(T) Combat Rolls and Soak Value.\n'
            '(4)-[Passive]: Upon gaining this Awakening, gain a Skill '
            'Improvement.\n'
            '(5)-[Triggered, 1/Round]: On a Signature Technique, trigger the '
            '5th effect of Neko Mimicry as if another Character possessed it '
            '(choose Ally or Opponent).\n'
            '(6)-[Triggered, 1/Round]: On a Signature Technique, if you '
            "haven't used Quick Learner's 1st effect this Encounter, spend "
            '3(bT) Ki to apply an Energy Charge.\n'
            '(7)-[Triggered/Start of Combat Encounter, 1/Encounter]: Create '
            'a Signature Technique (max TP for your base ToP) until the end '
            'of the Encounter.',
      ),
    ],
  ),

  // ============================================================ SAIBAMAN ===
  TransformationDef(
    name: 'Saibaking',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saibaman',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Minion No More Factor',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Saibaruler',
        description: 'Standing at the pinnacle of your kind, you embolden '
            'your underlings with your mere presence on the battlefield.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 1.\n'
            '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
            '1(T).\n'
            '(3-4)-[Passive]: Your Saibaman Minions gain +1(T) Combat Rolls '
            'and Soak Value and +1 Racial Life Modifier.\n'
            '(5)-[Passive]: Gain access to the Saibacall Special Maneuver '
            '(summons Saiba Minions).\n'
            "(6)-[Passive, Ruling]: Design a 'Saiba Minion' blueprint that "
            'levels with you (gains a Lesser Awakening each new base ToP).\n'
            '(7)-[Passive]: Use the Signature Technique Maneuver instead of '
            "Basic Attack through Savagery's 2nd effect.\n"
            '(8)-[Triggered, 1/Round]: If you increase your Racial Life '
            'Modifier, use a Healing Surge Out-of-Sequence.\n'
            '(9)-[Triggered/Power, 1/Encounter]: Below the Bruised '
            'Threshold, +1 Racial Life Modifier for the rest of the '
            'Encounter.\n'
            '(10)-[Triggered/Start of Turn, 1/Encounter]: Enter the Surging '
            'State until the end of your turn.',
        automation: [
          // (1) +1 Racial Life Modifier = +1 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +1(T) Combat Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),

  // ============================================================== SAIYAN ===
  TransformationDef(
    name: 'Half-Saiyan Heritage',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Half-Saiyan Factor Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Saiyan Inheritance',
        description: 'Despite the outside influence in your genes, your '
            'Saiyan blood awakens further, unleashing potential that has, '
            'thus far, lain dormant.\n'
            '(1)-[Triggered/Power, 1/Encounter]: Below the Injured '
            'Threshold, gain a stack of Battle Born.\n'
            '(2)-[Passive]: While you possess 4+ Battle Born, +2(T) '
            'Surgency.\n'
            '(3)-[Passive]: Upon gaining this Transformation, regain the '
            'Racial Trait you replaced with the Half-Saiyan Factor Trait.\n'
            '(4)-[Choice]: Per your Warrior of Two Worlds Option — Inherited '
            'Fury (+2(T) Soak while Raging), Aggression, Creativity (−3 TP / '
            '−1(T) Ki on Unique Abilities), Freedom, or Resolve (+1(T) '
            'Strike/Wound per Threshold below when attacking).',
        automation: [
          // (2) While 4+ tracked 'Battle Born' Resource stacks: +2(T)
          // Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Battle Born',
            conditionAmount: 4,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Saiyan Elite',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Saiyans Are a True Warrior Race',
        description: 'The pounding pulse of your blood thrumming through '
            'your veins calls you into battle, where you reign supreme as '
            'one of the strongest warriors you know.\n'
            '(1)-[Passive]: For each Health Threshold you are below, +1 '
            'maximum Energy Charges.\n'
            '(2)-[Passive]: While at the Healthy Threshold, +3(T) Wound '
            'Rolls.\n'
            '(3)-[Passive]: While below the Bruised Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(4)-[Passive]: While below the Injured Threshold, +1 Stress '
            'Bonus (doubled below Critical).\n'
            '(5)-[Passive]: Halve the Ki Cost of the Energy Charge '
            'Maneuver.\n'
            '(6)-[Triggered, 1/Round]: If you succeed a Steadfast Check, '
            'regain 2(bT) Life per 3 Battle Born (max 6(bT)).\n'
            '(7)-[Triggered, 1/Encounter]: On a Signature Technique, apply '
            'an Energy Charge per 2 Battle Born (max 3), then lose 2 Battle '
            'Born per Charge.\n'
            '(8)-[Triggered/Undying, 1/Encounter]: If you entered the '
            'Undying State via Saiyan Heritage, enter the Surging State '
            'until the end of your turn.',
        automation: [
          // (2) While at the Healthy Threshold: +3(T) Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 3,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
          // (3) While below the Bruised Threshold: +1(T) Combat Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
        ],
      ),
    ],
  ),

  // ======================================================== SHADOW DRAGON ===
  TransformationDef(
    name: 'Solitary Dragon',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Solo Dragon',
        description: 'Used to fighting alone, you have learned to rely '
            'solely on your own power, eschewing all else.\n'
            '(1)-[Passive]: You lose access to the Unify Maneuver.\n'
            '(2)-[Passive]: Ignore Reduced Momentum.\n'
            '(3)-[Passive]: For a Morale Clash, you may use your highest '
            'Attribute Score instead of Personality (or +1(T) Morale Clash '
            'if Personality is highest).\n'
            '(4)-[Passive]: +1(T) Dice Score for Might Clashes against '
            'Impaired Characters.\n'
            '(5)-[Passive]: Increase your Maximum Life Points by 2 for each '
            'Power Level reached.\n'
            '(6)-[Passive]: For each Health Threshold you are below, +1(T) '
            'Damage Reduction.\n'
            '(7)-[Triggered, 1/Round]: If you gain 4+ Negative Energy, Power '
            'Up Out-of-Sequence and +1(T) Combat Rolls/Soak for the '
            'Round.\n'
            '(8)-[Triggered/Power, 1/Round]: Spend up to 2 Negative Energy '
            'for a Morale Clash vs Opponents in a Large Sphere AoE '
            '(Impaired on a win).\n'
            '(9)-[Triggered, 1/Encounter]: On a no-AoE attack vs an Impaired '
            'Character, spend 3 Negative Energy to enter the Determined '
            'State for it.',
        automation: [
          // (5) +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (6) +1(T) Damage Reduction per Health Threshold below.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perHealthThresholdBelow,
          ),
        ],
      ),
    ],
  ),

  // ============================================================= SHINJIN ===
  TransformationDef(
    name: 'Ascension',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Celestial Perfection',
        description: 'Your spark of divinity has grown stronger, allowing '
            'you to apply your divine nature to combat.\n'
            '(1)-[Passive]: While at the Healthy Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(2)-[Passive]: While below the Injured Threshold, +2(T) '
            'Surgency.\n'
            '(3)-[Passive]: While in the God Ki State, reduce the Ki Cost of '
            'your attacks by 1(T).\n'
            '(4)-[Passive]: Upon gaining this Awakening, select 2 God '
            'Maneuvers, accessible while in the God Ki State.\n'
            '(5)-[Triggered]: If you regain Ki via Skill of the Watcher\'s '
            '4th effect while in God Ki, regain equal Divine Ki Points.\n'
            '(6)-[Triggered/Start of Turn]: Spend 1 Counter Action to enter '
            'the God Ki State until the start of your next turn.\n'
            '(7)-[1/Encounter]: As an Instant Maneuver, gain 1 Counter '
            'Action.\n'
            '(8)-[Triggered, 1/Encounter]: On an attack while in God Ki, '
            'spend up to 2 Counter Actions for an equal number of Energy '
            'Charges.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Vengeful God',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Spited Divinity',
        description: '(1)-[Passive]: +1(T) Wound Rolls of Exploit-Maneuver '
            'attacks.\n'
            '(2)-[Passive]: While below the Bruised Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(3)-[Passive]: +1(T) Strike and Dodge while at the Healthy '
            'Threshold; +2(T) Wound Rolls while below the Bruised '
            'Threshold.\n'
            '(4)-[Passive]: While below the Injured Threshold, +1 Dice '
            'Category to your Energy Charges.\n'
            '(5)-[1/Round]: If not in the Multiple Arms State, spend 2 '
            'Counter Actions for a Basic Attack as an Instant Maneuver.\n'
            "(6)-[Triggered]: Forgo Life from Skill of the Watcher's 4th "
            'effect to double the Ki regained.\n'
            '(7)-[Triggered, 2/Round]: If targeted by an Opponent attack, '
            'this triggers your Exploit Maneuver.\n'
            '(8)-[Triggered/Start of Turn, 1/Encounter]: Target an Opponent; '
            'until the start of your next turn, any Maneuver they use '
            'triggers your Exploit Maneuver.',
        automation: [
          // (2) While below the Bruised Threshold: +1(T) Combat Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.dodge,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
          // (3) +1(T) Strike and Dodge while at the Healthy Threshold…
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike, AffectedStat.dodge],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
          // …and +2(T) Wound Rolls while below the Bruised Threshold.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
        ],
      ),
    ],
  ),

  // ============================================================= YARDRAT ===
  TransformationDef(
    name: 'Battle Yardrat',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.body,
    racialRequirement: 'Yardrat',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Spirit of Battle',
        description: '(1)-[Passive]: Ignore the 1st effect of Power of the '
            'Weak.\n'
            '(2)-[Passive]: While not Bonded, +1(T) Combat Rolls, Surgency, '
            'and Soak Value.\n'
            '(3)-[Passive]: While not Bonded, you only spend 1/2 of the Ki '
            'Cost for an attack (does not reduce the Ki Cost).\n'
            '(4)-[Passive]: Per Subrace: Tall Yardrat — count as your own '
            'Bonded Ally for Spiritual Warrior; Bulbous Yardrat — all Allies '
            'count as Bonded for Spiritual Pacifist.\n'
            '(5)-[Triggered/Start of Turn]: Use the Power Up Maneuver '
            'Out-of-Sequence (no Empower until your next turn).\n'
            '(6)-[Triggered, 1/Round]: On a Signature Technique during a '
            '5th-effect turn, apply an Energy Charge.\n'
            '(7)-[Triggered, 1/Encounter]: If you become Bonded to an Ally, '
            'they may transfer up to 3 Actions to you (then you may unbond).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Wise Yardrat',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.greater,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Yardrat',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ stacks of Spirit Control',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Whiskers of Wisdom',
        description: '(1)-[Passive]: Increase the Technique Points gained '
            'from Skill Improvements by 2 (retroactive).\n'
            '(2)-[Passive]: Increase Z by 1 for the effects of the Spirit '
            'Control Awakening.\n'
            '(3)-[Passive]: Reduce the Ki Cost of your Spiritual Unique '
            'Abilities by 1(T).\n'
            '(4)-[Passive]: Increase the Combat Rolls and Soak Value of your '
            'Bonded Ally by 1(T).\n'
            '(5)-[Passive]: Use the Surge Maneuver an additional time per '
            'Combat Encounter.\n'
            '(6)-[Triggered, 1/Round]: On a Spiritual Unique Ability, your '
            'Bonded Ally regains Life and Ki = 1/4 (rounded up) of your '
            'Surgency.\n'
            '(7)-[Triggered, 1/Encounter]: If your Bonded Ally Surges, '
            'increase their Surgency by your Surgency for that Maneuver.',
      ),
    ],
  ),
];

/// Looks up a Greater Awakening by name, or `null` if unrecognized.
TransformationDef? greaterAwakeningByName(String name) {
  for (final a in kDbuGreaterAwakenings) {
    if (a.name == name) return a;
  }
  return null;
}
