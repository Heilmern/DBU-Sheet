/// awakenings.dart
/// ---------------------------------------------------------------------------
/// Lesser Awakenings catalogue (Transformation Catalog → Lesser Awakenings),
/// verbatim from the site. Awakenings are permanent Transformations that are
/// constantly active once gained, so their Attribute Modifier Bonus applies
/// at all times (see `CharacterCalculator.transformationModifierBonus`).
///
/// Grouped Any-Race first (alphabetical), then per-race (in the site's nav
/// order). Large auxiliary text boxes on some pages (full Unique Ability
/// definitions, Profiles, special AMB rules) are condensed to a short note in
/// the Trait text — same convention `race_traits.dart` uses for references to
/// un-modelled sub-systems. `Z` in a Trait's text = the Awakening's current
/// number of Stacks. A `(2)`/`(3)` after a Trait name = it activates only at
/// that many Stacks (`minStacks`).
library;

import 'dbu_rules.dart';
import 'race_traits.dart';
import 'transformations.dart';

/// The three non-FO/MA Attributes (AG/TE/IN), each granting a **flat +1** AMB —
/// the "select an Attribute (except FO/MA); increase this Transformation's
/// Attribute Modifier Bonus for it by +1" choice shared by several Awakenings
/// (Swapping Expert, Custom Evolution). Uses [TraitOption.ambFlatBonus] because
/// these Awakenings' AMB is flat, not `(T)`.
const List<TraitOption> kAmbPickNonPhysicalFlat1 = [
  TraitOption(
    name: 'Agility',
    description: '+1 Attribute Modifier Bonus (AG).',
    ambFlatBonus: {DbuAttribute.agility: 1},
  ),
  TraitOption(
    name: 'Tenacity',
    description: '+1 Attribute Modifier Bonus (TE).',
    ambFlatBonus: {DbuAttribute.tenacity: 1},
  ),
  TraitOption(
    name: 'Insight',
    description: '+1 Attribute Modifier Bonus (IN).',
    ambFlatBonus: {DbuAttribute.insight: 1},
  ),
];

/// Agility or Tenacity, each granting a **flat +1** AMB — the narrower "select
/// Agility or Tenacity; increase this Awakening's AMB for it by 1" choice
/// (Upgraded Features).
const List<TraitOption> kAmbPickAgTeFlat1 = [
  TraitOption(
    name: 'Agility',
    description: '+1 Attribute Modifier Bonus (AG).',
    ambFlatBonus: {DbuAttribute.agility: 1},
  ),
  TraitOption(
    name: 'Tenacity',
    description: '+1 Attribute Modifier Bonus (TE).',
    ambFlatBonus: {DbuAttribute.tenacity: 1},
  ),
];

const List<TransformationDef> kDbuLesserAwakenings = [
  // ============================================================= ANY RACE ===
  TransformationDef(
    name: 'Absorption',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: 'Can only be obtained through the Absorb Maneuver or '
        'Out-of-Combat Absorption',
    // Special AMB (per-stack, +1 to the Absorbed Character's top 3
    // Attributes) — depends on the absorbed character, so it is NOT
    // auto-applied; see the Trait note.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Assimilated Power',
        description: "You have taken another's power into yourself, making "
            'it your own, at least for the time being.\n'
            "(1)-[Ruling]: Upon gaining a stack of Absorption, a Character "
            "will be assigned to that stack as the 'Absorbed Character'.\n"
            "(2)-[Addendum]: See the site's 'Absorption AMB', 'Temporary "
            "Absorption Limit', 'Absorbing Fusions', and 'Out-of-Combat "
            "Absorption' text boxes.\n"
            '(3)-[Passive]: You gain access to all of the Signature '
            'Techniques, Unique Abilities, Forms (incl. Masteries/Evolved '
            'Stages), and Enhancements (incl. Masteries) possessed by your '
            'Absorbed Characters (except Minions), provided you meet their '
            'Prerequisites.\n'
            '(4)-[Passive, Addendum]: Upon gaining a stack of Absorption, '
            'select and gain access to a Primary Racial Trait possessed by '
            'that Absorbed Character. You cannot possess more than 2 Primary '
            'Racial Traits through this effect at any one time.\n'
            '(5)-[Automatic/Start of Turn]: If a stack of Absorption is a '
            'Temporary Awakening, make a Clash (Cognitive) against the '
            'Absorbed Character (reduce your Dice Score by 1(bT) per Health '
            'Threshold Penalty). If you lose, reduce your Life Points by 1/4 '
            'of your Maximum and lose that stack.\n'
            '(6)-[Automatic/Start of Turn]: If you are Defeated, lose all '
            'stacks of Absorption.\n'
            '(7)-[Automatic]: Upon losing a stack of Absorption, the Absorbed '
            'Character is freed and (if still in a Combat Encounter) enters '
            'on a square adjacent to you of their choice.\n'
            '(8)-[Triggered]: At the end of a Combat Encounter, if below your '
            'Lesser Awakening Limit, you may make a Clash (Cognitive) against '
            'the Absorbed Characters of any Temporary-Awakening stacks; if '
            'you win, that stack stops being Temporary (if it would not '
            'exceed your Awakening Limit).\n'
            "Note: Absorption's AMB is special — each stack applies +1 to the "
            "three highest Attributes of that stack's Absorbed Character (not "
            'auto-computed here).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Adjusted Armor',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'You have access to Natural Armor through the effects '
        'of a Racial Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Natural Apparel',
        description: 'Through training and craftsmanship, you enhance your '
            'armor beyond the standards of your kind.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 1.\n'
            '(2)-[Passive]: Increase the Apparel Bonus of your Natural Armor '
            'by 1(bT).\n'
            '(3)-[Passive]: Upon gaining access to this Awakening, select an '
            'Apparel Quality that applies to your Natural Armor and that it '
            'has enough Quality Slots for. Your Natural Armor gains that '
            'Apparel Quality.\n'
            '(4)-[Adventurous]: While Adventuring, you or an Ally may spend a '
            'day refining your armor with a Craft (Apparel) Skill Check '
            'against your Natural Armor\'s Craft DC to add/exchange/remove '
            'Apparel Qualities (meeting Prerequisites and Quality Slots).',
        automation: [
          // (1) +1 Racial Life Modifier — the Max Life formula multiplies the
          // RLM by Power Level, so this is +1 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Artificial Demon',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'You can only obtain this Awakening through being '
        'infected with the Black Water Mist while not possessing the Demon '
        'Clansmen Factor.',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Temporary Demon',
        description: 'You have temporarily been transformed into a '
            'demon-like creature devoid of your own will, subsumed by the '
            'Black Water Mist.\n'
            '(1)-[Passive]: Gain the Heart of Evil Factor Trait (see — Demon '
            'Clansman).\n'
            '(2)-[Passive]: Gain access to the Bite Attack Maneuver (see — '
            'Special Maneuvers).\n'
            '(3)-[Passive]: Reduce your Cognitive Save by 2(T), but increase '
            'your Corporeal Save by 1(T).\n'
            '(4)-[Triggered]: If you deal Damage to a Character with the Bite '
            'Attack Maneuver, make a Clash (Corporeal) against them. If you '
            'win, they become infected by the Black Water Mist.',
        automation: [
          // (3) -2(T) Cognitive Save / +1(T) Corporeal Save.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.cognitiveSave],
            coefficient: -2,
            tierScaling: TierScaling.current,
          ),
          RaceTraitAutomation(
            affectedStats: [AffectedStat.corporealSave],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Barrier Focus',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Barrier Unique Ability',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'You Think a Barrier Will Work?',
        description: 'Despite opinions to the contrary, your sturdy energy '
            'barriers are more than just shields against damage.\n'
            '(1)-[Passive]: You gain access to the Barrier Bubble Unique '
            'Ability and may spend Technique Points to obtain its '
            'Advancements (detailed below).\n'
            '(2)-[Passive]: You gain access to the Barrier Blow '
            'Multi-Foundation Profile (detailed below).\n'
            '(3)-[Passive]: Increase the Dice Score of your Wound Roll for '
            'the effects of the Barrier Unique Ability by 1(T).\n'
            '(4)-[Passive]: While you are below the Injured Health Threshold, '
            'reduce the Critical Target of your Wound Rolls by 1.\n'
            '(5)-[Triggered, 1/Encounter]: When you use the Barrier Unique '
            'Ability, you do not have to pay the Ki Point Cost.\n'
            '(6)-[Triggered, 1/Encounter]: When using a Signature Technique, '
            'you may apply the Multi-Profile Super Profile to that Attacking '
            'Maneuver, selecting the Barrier Blow Profile for its effects.\n'
            '\n'
            'Barrier Blow Profile — Foundations: All; Damage Category: '
            'Standard; KP Cost: 4(T). Effect: Apply your Base Die an additional '
            'time to the Wound Roll of this Attacking Maneuver (you cannot '
            'score a Botch Result on this additional Base Die, but you can '
            'score a Critical Result — if you score a Critical Result on both '
            'Base Dice for this Attacking Maneuver, apply the Critical Result '
            'Extra Dice an extra time (for a total of being applied twice) but '
            'this only counts as scoring a single Critical Result for your '
            'effects), and increase the Wound Roll by 1/4 (rounded up) of your '
            'Might.\n'
            '\n'
            'Barrier Bubble Unique Ability — Effect: All Squares you occupy '
            'are covered by a Protective Bubble that possesses BLP (Barrier '
            'Life Points) equal to 5x your Might. If any Character within a '
            'Protective Bubble would take Collision Damage or Damage from an '
            'Attacking Maneuver made by a Character outside of the Protective '
            'Bubble, the Protective Bubble receives that Damage instead — '
            'reducing its Barrier Life Points as if they were Life Points. A '
            'Protective Bubble is destroyed when its BLP reaches 0. Any excess '
            'Damage is dealt to all Characters targeted by the Attacking '
            'Maneuver within the Protective Bubble. If you use this Unique '
            'Ability while you are already in a Protective Bubble, it gains BLP '
            'equal to 5x your Might. The BLP of your Protective Bubble cannot '
            'exceed a value equal to 5x your Might.\n'
            'Barrier Bubble Advancements:\n'
            '• Airtight Bubble — Effect: All Characters within your Protective '
            'Bubble ignore the effects of any Battle Environments and '
            'Environmental Qualities.\n'
            '• Massive Bubble — Effect: When creating a Protective Bubble, '
            'rather than it covering any Square you occupy, you may spend '
            'between 2(bT) and 6(bT) Ki Points to have it instead occupy all '
            'Squares within a Sphere AoE (centered on you) — the Magnitude for '
            'this AoE begins at Large and is increased by 1 Magnitude for every '
            'additional 2(bT) Ki Points spent above the minimum. If you undergo '
            'movement, the Protective Bubble moves the same number of Squares '
            'in the same direction.\n'
            '• Solid Bubble — Prerequisites: Massive Bubble. Effect: All '
            'Squares within the Protective Bubble are considered occupied for '
            'your Opponents. An Opponent can attempt to move onto a Square '
            'occupied by your Protective Bubble by making a Might Clash against '
            'you. If you win, their movement ends at the Square adjacent to the '
            'edge of your Protective Bubble\'s AoE. If you lose, the Opponent '
            'may enter that space as if it was unoccupied and stop treating '
            'your Protective Bubble as if it was occupied until they leave its '
            'AoE or the Protective Bubble is destroyed. If an Opponent is moved '
            'into a Square occupied by your Protective Bubble, follow the '
            'typical rules for Feature Collision as if that Square had a '
            'Feature with a Hardness Rank equal to 1/2 of your Tier of Power '
            '(rounded up). Once per movement per Character, if you use the '
            'Movement Maneuver while possessing a Protective Bubble with an '
            'AoE, you may make a Might Clash against any Opponent(s) who would '
            'enter the Squares of the Protective Bubble due to your movement. '
            'If you win, they are moved in the same direction as you are moving '
            'a number of Squares equal to your remaining movement. If you lose, '
            'that Opponent may enter that space as if it was unoccupied and '
            'stop treating your Protective Bubble as if it was occupied until '
            'they leave its AoE or the Protective Bubble is destroyed.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Bestial Transfiguration',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 3,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Reawakened Beast',
        description: '(1)-[Passive]: Upon gaining access to a stack of this '
            'Awakening, select a Bestial Trait. While you are in a Form or '
            'Enhancement, you have access to that Bestial Trait.\n'
            '(2)-[Passive]: While in a Form or Enhancement, increase your '
            'Perception Skill Bonus by Z.\n'
            '(3)-[Passive]: While in a Form or Enhancement, increase your '
            'Boosted Speed by Z(bT).\n'
            '(4)-[Passive]: While in a Form or Enhancement, increase the '
            'Wound Rolls of your Signature Techniques by Z(bT).',
        automation: [
          // (3) +Z(bT) Boosted Speed while in a Form or Enhancement.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.speedBoosted],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileInFormOrEnhancement,
            perTransformationStack: true,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Blessed by Fate',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Lucky Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Extremely Lucky',
        description: 'You are often the center of the most improbable events '
            'known to man, allowing you to succeed despite all odds being '
            'stacked against you.\n'
            '(1)-[Triggered, Ruling]: Each time you reroll a d10 through the '
            '1st effect of Lucky and the second result is higher, gain a '
            'stack of Chance (max. 3).\n'
            '(2)-[Passive]: You may use the 1st effect of Lucky to reroll any '
            'number of d10s rolled through Combat Recovery or a Surge, but '
            'you gain no Chance stacks if you reroll more than 1 d10 this '
            'way.\n'
            '(3)-[1/Round]: You may spend 2 stacks of Chance to trigger the '
            '1st effect of Lucky, ignoring its [1/Round] Keyword (gaining no '
            'Chance from that reroll).\n'
            "(4)-[Triggered]: If you are hit by an Opponent's Attacking "
            'Maneuver, spend a stack of Chance to force that Opponent to roll '
            'their Wound Roll twice and take the lower result.\n'
            '(5)-[Triggered]: If you reroll the Base Die of a Combat Roll '
            'through Lucky, spend any number of Chance stacks to increase the '
            'Natural Result by 1 each (gaining no Chance from that reroll).\n'
            '(6)-[Triggered/Start of Turn]: Roll a 1d10. On a 10, gain 1 '
            'Action.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Body Swapper',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Body Change Unique Ability',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Swapping Expert',
        description: '(1)-[Passive]: Upon gaining access to this Awakening, '
            'select an Attribute (except FO/MA). Increase the Attribute '
            'Modifier Bonus of this Transformation for that Attribute by '
            '+1.\n'
            '(2)-[Passive]: Gain access to the Holstein Shock Unique '
            'Ability.\n'
            '(3)-[Passive]: Upon gaining access to this Awakening, select a '
            "Combat Roll. While in a body that didn't originally belong to "
            'you and having no stacks of Unfamiliar, increase that Combat '
            'Roll by 1(T), or 2(T) if you chose Wound Rolls.\n'
            '(4)-[Passive]: You only gain 1 stack of Unfamiliar, rather than '
            '3, through the Body Change Unique Ability.\n'
            '(5)-[Triggered, 1/Round]: If you use the Body Change Unique '
            'Ability, you may use the Holstein Shock Unique Ability as an '
            'Instant Maneuver first.\n'
            '(6)-[Triggered, 1/Encounter]: If you use the Body Change Unique '
            'Ability, increase your Cognitive Save by 1(bT) for its '
            'effects.\n'
            '(7)-[Triggered/Power, 1/Encounter]: If you have been in a new '
            'body for 3+ Combat Rounds, remove a stack of Unfamiliar.',
        // (1) select an Attribute (except FO/MA) → +1 flat AMB of it.
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'AMB Attribute',
            options: kAmbPickNonPhysicalFlat1,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Bonded by Battle',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Synchronized Combatants and/or Chosen Rival Talents',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: "Warrior's Alliance",
        description: 'Whether you are uniting with your rival against a '
            'shared enemy, or standing tall beside your long-time partner, '
            'no one can deny that your teamwork is unmatched.\n'
            '(1)-[Passive]: While your Partner and/or Rival is adjacent to an '
            'Opponent, increase your Wound Rolls against that Opponent by '
            '1(T).\n'
            '(2)-[Passive]: While your Partner and/or Rival is adjacent to '
            'you, increase your Soak Value by 1(T).\n'
            '(3)-[Passive]: Any Attacking Maneuvers targeting your Partner '
            'and/or Rival made by an Opponent adjacent to you trigger your '
            'Exploit Maneuver.\n'
            '(4)-[Triggered/Start of Turn]: Target your Partner and/or Rival '
            'within a Large Sphere AoE (centered on you); move to a Square '
            'adjacent to them. If they also have Bonded by Battle, you may '
            'spend 4(bT) Ki Points to remove a Combat Condition they suffer '
            '(except Blinded, Poisoned, Pinned, Stress Exhaustion, '
            'Suffocating, or Transfigured).\n'
            '(5)-[1/Encounter]: As an Instant Maneuver, transfer 1 of your '
            'Actions to a Character who is your Partner and/or Rival.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Built for Bulk',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Muscular Warrior Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Massive Flex',
        description: '(1)-[Passive]: Gain 1 Super Stack.\n'
            '(2)-[Passive]: Increase your Surgency by 1(T) for each Super '
            'Stack you possess after the first.\n'
            '(3)-[Passive]: Do not increase your Muscle Penalty by an '
            'additional 1(bT) while you possess 3 Super Stacks.\n'
            '(4)-[Passive]: While you possess 3 Super Stacks, increase your '
            'Soak Value and Wound Rolls by 1(T).\n'
            '(5)-[1/Round]: If you use the Defend Maneuver, increase your '
            'Damage Reduction by 1(bT) for its duration for each Super Stack '
            'you possess after the first.\n'
            '(6)-[Triggered/Transform]: Upon entering a Form or Enhancement, '
            'you may apply the Bulky Aspect to it until you leave it.\n'
            '(7)-[Triggered/Power, 1/Encounter]: If you are in a '
            'Transformation with the Bulky Aspect, use a Healing Surge as an '
            'Out-of-Sequence Maneuver.',
        automation: [
          // (4) While at 3 Super Stacks: +1(T) Soak Value and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.soak,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileMaxSuperStacks,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Charge Expert',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Concentrated Energy Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Energy Concentration',
        description: "You've learned to make use of the energy you "
            'accumulate to defend yourself, as well as powering your attacks '
            'even further.\n'
            '(1)-[Passive]: Increase your Soak Value by 1(bT) for every 2 '
            'stacks of Concentrated Ki you possess.\n'
            '(2)-[Triggered, 1/Round]: If targeted by an Attacking Maneuver '
            'while you possess 2+ stacks of Concentrated Energy, spend 2 '
            'stacks to ignore Guard Down and increase your Dodge Rolls by '
            '2(T) for that Attacking Maneuver.\n'
            '(3)-[Triggered/Start of Turn]: If you have 1+ stacks of '
            'Concentrated Energy, use the Energy Charge Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Signature Technique, '
            'for every 5 stacks of Concentrated Ki you possess, apply an '
            'Energy Charge to it (may exceed your maximum Energy Charges).',
        automation: [
          // (1) +1(bT) Soak per 2 tracked 'Concentrated Ki' Resource stacks.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.base,
            kind: TraitMagnitudeKind.perNamedResourceStack,
            resourceName: 'Concentrated Ki',
            fractionDenominator: 2,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Combat Enthusiast',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Slow Starter Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Excited for Battle',
        description: 'Your love of a good fight shows in how you hold '
            "yourself back to really draw out your enemies' full power.\n"
            '(1)-[Passive]: While you have at least 1 stack of Holding Back, '
            'increase your Damage Reduction by 1(bT) and your Surgency by '
            '2(bT).\n'
            '(2)-[Passive]: While you have no stacks of Holding Back and are '
            'below the Injured Health Threshold, increase your Combat Rolls '
            'by 1(T).\n'
            '(3)-[Triggered/Injured]: You may remove all Holding Back stacks. '
            'If you remove at least 1, you cannot fail a Stress Test until '
            'the end of your next turn.\n'
            '(4)-[Triggered/Start of Turn]: If you have any Holding Back '
            'stacks, regain 2(bT) Ki Points.\n'
            '(5)-[Triggered/Power, 1/Encounter]: If you have no Holding Back '
            'stacks, gain an additional stack of Power from this use of the '
            'Power Up Maneuver.',
        automation: [
          // (1) While 1+ tracked 'Holding Back' Resource stacks: +1(bT)
          // Damage Reduction and +2(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Holding Back',
          ),
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Holding Back',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Culture Fluid Corruption',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    prerequisiteText: 'Unstable Clone Factor',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Syrupy Covering',
        description: 'Your body begins to break down at the cellular level, '
            'turning into a goopy mess.\n'
            '(1)-[Automatic/Start of Turn]: Reduce your Life Points by 1/20th '
            'of your Maximum Life Points.\n'
            '(2)-[Automatic/Start of Turn]: If occupying an Underwater '
            'Environment Square, gain a stack of Slowed and Broken until the '
            'start of your next turn.\n'
            '(3)-[Automatic]: If hit by an Attacking Maneuver of the '
            'Elemental (Water) Profile, gain a stack of Broken until the '
            'start of your next turn.\n'
            '(4)-[Passive]: Increase your Corporeal and Impulsive Saves by '
            'Z(T).\n'
            '(5)-[Passive]: Increase your Wound Rolls and Soak Value by '
            'Z(T).\n'
            '(6)-[Passive]: Increase your Surgency by 2Z(T).\n'
            '(7)-[Triggered, 1/Encounter]: If hit by an Attacking Maneuver, '
            'use a Healing Surge as an Out-of-Sequence Maneuver.',
        automation: [
          // (4) +Z(T) Corporeal and Impulsive Saves.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.corporealSave,
              AffectedStat.impulsiveSave,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
          // (5) +Z(T) Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
          // (6) +2Z(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Syrup Overload',
        minStacks: 2,
        description: 'Absorbing enough culture fluid in your melting state '
            'allows you to grow to massive proportions.\n'
            '(1)-[Passive]: You gain access to the Giant Form Enhancement.\n'
            '(2)-[Passive]: Double the bonus to your Wound Roll and Soak '
            'Value from the 5th effect of Syrupy Covering while you have no '
            'Broken stacks and are in the Giant Form Enhancement.\n'
            '(3)-[Triggered/Defeat, 1/Encounter]: Enter the Undying State. '
            'You leave it if you trigger the 2nd effect of Syrupy Covering or '
            'if your Life Points reach a negative value equal to 1/2 of your '
            'Maximum.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Cybernetic Upgrade',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 3,
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Installed Cybernetics',
        description: 'The cybernetic prosthetics that replace your missing '
            'body parts also make you more than you were before.\n'
            '(1)-[Passive]: Upon gaining a stack of this Awakening, either: '
            'regain a Secondary Racial Trait exchanged for a Cybernetic '
            'Enhancement Factor Trait; or select and gain access to a Factor '
            'Trait from the Cybernetic Enhancement Factor.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Dark Infusion',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Dragon Ball Rampage',
        description: 'The power emanating from the Dark Dragon Balls infuses '
            'you with destructive might.\n'
            '(1)-[Passive]: You gain access to the Dark Enhancement '
            'Transformation.\n'
            '(2)-[Passive]: Increase your Wound Rolls, Surgency, and Soak '
            'Value by Z(bT).\n'
            '(3)-[Passive]: While in Evil Aura, increase your maximum Evil '
            'Points by 1(bT); for every 2 stacks of Dark Infusion after the '
            'first, increase it by an additional 1(bT).\n'
            '(4)-[Triggered, 1/Round]: If you hit an Opponent you are '
            'targeting through the Compelled Combat Condition with an '
            'Attacking Maneuver, apply an Energy Charge to it.\n'
            '(5)-[Triggered/Start of Turn]: Gain the Compelled Combat '
            'Condition, selecting whoever you desire as your target.\n'
            '(6)-[Triggered/Power, 1/Encounter]: Use the Transformation '
            'Maneuver to enter Evil Aura as an Out-of-Sequence Maneuver.',
        automation: [
          // (2) +Z(bT) Wound Rolls, Surgency and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.surgency,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            perTransformationStack: true,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Peak Condition',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
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
        name: 'Ideal Condition',
        description: 'Your body has reached (or returned to) its prime, '
            'leaving you in your best physical shape ever.\n'
            '(1)-[Passive]: Increase your Surgency by 2(bT).\n'
            '(2)-[Passive]: While you are in the Healthy Health Threshold, '
            'increase your Soak Value and Defense Value by 1(T).\n'
            '(3)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Points by 2 for each Power Level reached.\n'
            '(4)-[1/Encounter]: Use a Surge of your choice as an Instant '
            'Maneuver.',
        automation: [
          // (1) +2(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.base,
          ),
          // (2) While in the Healthy Health Threshold: +1(T) Soak and
          // Defense Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
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
    name: 'Steel Frame',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Hard as Steel',
        description: 'Your rock-solid muscles make striking you akin to '
            'punching solid steel.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(T).\n'
            '(3)-[Passive]: While you are below the Injured Health Threshold, '
            'increase your Soak Value by 1(T).\n'
            '(4)-[Passive]: If you would use your Cognitive Save for a Clash '
            'initiated by an Opponent, you may use your Corporeal Save '
            'instead.\n'
            '(5)-[Triggered, 1/Round]: If you use the Direct Hit option of '
            'the Defend Maneuver, reduce the Damage Category of the Attacking '
            'Maneuver which targets you by 1 Category for the sake of your '
            'Damage Calculation.',
        automation: [
          // (1) +2 Racial Life Modifier = +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +1(T) Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (3) While below the Injured Health Threshold: +1(T) Soak Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),

  TransformationDef(
    name: 'Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Class Selection',
        description: "You've chosen a mantle for yourself, an identity to "
            'adhere to.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Option]: Upon gaining this Transformation, choose one of '
            'the effects below.\n'
            '(3)-[Choice]: Depending on your Class Selection choice, gain '
            'the matching 1/Encounter effect below.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Class',
            options: [
              TraitOption(
                name: 'Hero',
                description: '[Passive]: Increase your Dodge Rolls and Soak '
                    'Value by 1(T). [1/Encounter]: Use the Power Up Maneuver '
                    'as an Instant Maneuver, gaining an additional stack of '
                    'Power from it.',
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
                description: '[Passive]: Increase your Strike Rolls and '
                    'Surgency by 1(T). [1/Encounter]: Use the Surge Maneuver '
                    'as an Instant Maneuver; it does not count towards the '
                    "Surge Maneuver's [1/Encounter] Keyword.",
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
                description: '[Passive]: Increase your Wound Rolls and Might '
                    'by 1(T). [1/Encounter]: Use the Basic Attack Maneuver or '
                    'Signature Technique Maneuver as an Instant Maneuver, '
                    'applying an Energy Charge to that Attacking Maneuver.',
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
      ),
    ],
  ),
  TransformationDef(
    name: 'God Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Divine Class',
        description: "So devoted are you to your chosen path, you've gone a "
            'step beyond and now walk grounds where no mortal treads.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select a God '
            'Maneuver. You have access to it while in the God Ki Special '
            'State.\n'
            '(2)-[Choice]: Depending on your Class Selection choice: '
            'Hero [1/Round] — while in the God Ki Special State, reduce the '
            'Ki Point Cost of any Maneuver by 1(T) per Power Stack (only if '
            'paid with Divine Ki Points); Elite [Passive] — while in the God '
            'Ki Special State, if you regain Ki Points through a Ki Surge, '
            'regain Divine Ki Points equal to 1/2 of that amount; Berserker '
            '[Triggered] — while in the God Ki Special State, if you spend '
            'Divine Ki Points to use the Energy Charge Maneuver, gain an '
            'additional Energy Charge (that use counts as 2 for Mandatory '
            'Charge).\n'
            '(3)-[Triggered/Start of Turn, 1/Encounter]: Enter the God Ki '
            'Special State until the end of your next turn. If you were '
            'already in it, regain Divine Ki Points equal to 1/4 of your '
            'maximum (can exceed your maximum).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Super Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Super Class',
        description: '(1)-[Passive]: Upon gaining this Awakening, gain access '
            'to the Super Maneuver matching your Class Selection choice '
            '(Super Power Up / Super Surge / Super Assault — see the '
            'site).\n'
            '(2)-[Choice]: Depending on your Class Selection choice: '
            'Hero [Passive] — increase your Soak Value and Wound Rolls by '
            '1(T); Elite [Passive] — increase your Surgency and Wound Rolls '
            'by 1(T); Berserker [Passive] — increase your Wound Rolls by '
            '2(T).\n'
            '(3)-[Choice]: Depending on your Class Selection choice: '
            'Hero [Triggered/Power, 1/Encounter] — use a Healing Surge as an '
            'Out-of-Sequence Maneuver; Elite [Triggered/Start of Turn, '
            '1/Encounter] — use a Ki Surge as an Out-of-Sequence Maneuver; '
            'Berserker [Triggered, 1/Encounter] — if you use an Attacking '
            'Maneuver, apply an Energy Charge to it.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Ultimate Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 6,
    maxStacks: 1,
    prerequisiteText:
        'God Class Up Awakening, access to Autonomous Ultra Instinct',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Ultimate Class',
        description: 'Through zealous pursuit of your chosen path, you have '
            "honed your abilities to a razor's edge, one that can cut "
            'through even the gods themselves.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select a God '
            'Maneuver. You have access to it while in the Autonomous Ultra '
            'Instinct Enhancement.\n'
            '(2)-[Passive]: Gain access to Ultra Instinct "Sign".\n'
            '(3)-[Passive]: While in Autonomous Ultra Instinct, apply the '
            'bonus from the 2nd effect of Class Selection an additional '
            'time.\n'
            '(4)-[Choice]: Depending on your Class Selection choice: '
            'Hero [1/Encounter] — while in Autonomous Ultra Instinct, if you '
            'would lose any Power stacks, retain them until the end of your '
            'next turn; Elite [1/Encounter] — while in Autonomous Ultra '
            'Instinct, if you use a Surge, double your Surgency for its '
            'duration; Berserker [1/Encounter] — while in Autonomous Ultra '
            'Instinct, if you use an Attacking Maneuver with 3+ Energy '
            'Charges, enter the Determined State for its duration.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Dedicated Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    prerequisiteText: 'Cultivation of the Self Awakening',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Dedication to the Path',
        description: 'Your single-minded focus allows you to push your '
            'fighting style beyond mere mastery.\n'
            '(1)-[Passive]: While you are not in a Form, increase your '
            'Saving Throws by 1(bT).\n'
            '(2)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Point Pool by 2 for each Power Level reached.\n'
            '(3)-[Choice]: Depending on your choice for the Option effect of '
            'Enhancement of the Self: Pure Resolve [Passive] — increase the '
            'Attribute Modifier Bonuses (AG/FO/TE/MA) of your Transcended '
            'Enhancements by 1(T); Built Different [Passive] — you may use an '
            'Enhancement (except Transcended) without losing the Option/'
            'Choice benefits of Enhancement of the Self, but reduce your '
            'Stress Bonus by 1(bT)+4 (can go negative).',
        automation: [
          // (1) While not in a Form: +1(bT) Saving Throws.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.impulsiveSave,
              AffectedStat.cognitiveSave,
              AffectedStat.corporealSave,
              AffectedStat.moraleSave,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNotInForm,
          ),
          // (2) +2 Max Life and Max Ki per Power Level.
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
    name: 'Dirty Fighter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Desperate Distraction Talent',
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Anything to Win',
        description: "You don't care what it takes to win; survival is more "
            'important than honor.\n'
            '(1)-[Passive]: If you have won the Clash for the Dirty Trick '
            'Maneuver this Combat Round, increase your Combat Rolls by '
            '1(T).\n'
            '(2)-[Passive, Ruling]: You gain additional Dirty Trick options '
            '("Hey, look over there!" — target gains Compelled against an '
            'Ally you pick; "Hey, let\'s team up!" — you\'re considered an '
            'Ally by your target until you target them offensively; "Would '
            'you like to hear the truth?" — target gains Impediment until '
            'end of turn).\n'
            "(3)-[Triggered, 1/Round]: If targeted by an Opponent's Attacking "
            'Maneuver, target an adjacent Ally not targeted by it and make a '
            'Clash (Bluff vs Intuition/Persuasion). If you win, swap '
            'positions and that Ally becomes the target instead.\n'
            '(4)-[Triggered/Start of Turn]: If an Opponent is adjacent, use '
            'the Dirty Trick Maneuver as an Out-of-Sequence Maneuver against '
            'an adjacent Opponent.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Diverse Leader',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 3,
    prerequisiteText: 'Commander Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Leadership Training',
        description: '(1)-[Passive]: Increase your maximum number of Minions '
            'by Z.\n'
            '(2)-[Passive]: Increase the Maximum Life Points of your Minions '
            'by Z for each Power Level reached (after all other '
            'calculations).\n'
            '(3)-[Passive]: Each time you gain a stack of this Awakening, '
            'gain a Leadership Trait.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Elemental Force',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Flash of the Elements',
        description: 'By igniting your destructive energy in a specific way, '
            'you trigger a flashpoint, recreating the mystical might of '
            'elemental powers.\n'
            "(1)-[Passive]: Each time you gain a stack, select a Profile "
            "with 'Elemental' in the name. That Profile becomes a Favored "
            'Element.\n'
            '(2)-[Triggered]: If you use an Attacking Maneuver of your '
            'Favored Element, you may apply the Compressed Element '
            'Disadvantage to it to increase its Wound Roll by Z(T).\n'
            '(3)-[Triggered, Z/Round]: If you use an Attacking Maneuver of '
            'the Physical or Energy Foundations, you may apply the '
            'Multi-Profile Super Profile, choosing a Favored Element.\n'
            '(4)-[Triggered, 1/Encounter]: If you spend all Actions on a '
            'turn using the Energy Charge Maneuver with a declared Physical/'
            'Energy Attacking Maneuver, at the end of your turn use the '
            'required Maneuver as an Out-of-Sequence Maneuver, applying the '
            '3rd effect.',
      ),
      TransformationTrait(
        name: 'Hyper Elemental',
        minStacks: 2,
        description: 'Your mastery over the primal forces of nature allows '
            'you to combine them together, creating a cascade of elemental '
            'fury.\n'
            '(1)-[Passive]: Halve the Ki Point Cost of the Energy Charge '
            'Maneuver.\n'
            '(2)-[Triggered, 1/Round]: If you use a Signature Technique with '
            'a Favored Element applied via the 3rd effect of Flash of the '
            'Elements, apply a Line or Cone AoE; for every 2 Energy Charges, '
            'increase its Magnitude by 1.\n'
            '(3)-[Triggered, 1/Encounter]: If you use a Signature Technique '
            'with 3+ Energy Charges and a Favored Element applied via the '
            '3rd effect, apply an additional Favored Element (no extra KP '
            'Cost).',
      ),
    ],
  ),

  TransformationDef(
    name: 'Final Trump Card',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to a Signature Technique with the Genki Super '
        'Profile and the Energy Gathering Unique Ability',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: "The Genki's Fading…!",
        description: 'Entrusted with the energy of life surrounding you, you '
            'have absorbed this power, wielding it while it still remains at '
            'your fingertips.\n'
            '(1)-[Passive]: Increase the Damage Category of your Attacking '
            'Maneuvers with the Genki Super Profile by 1 Category.\n'
            '(2)-[Passive]: You may use the 4th effect of the Entrusted '
            'Special State when you use the Signature Technique Maneuver '
            'instead of a Basic Attack Maneuver.\n'
            '(3)-[Triggered]: If you spend 3 Actions on the Energy Gathering '
            'Unique Ability, gain an additional stack of Lifeforce.\n'
            "(4)-[Triggered/Entrusted]: If you enter the Entrusted State "
            "through the 5th effect of The Genki's Fading…!, increase your "
            'Wound Rolls by 1(T) for every stack of Lifeforce you lose '
            'through that effect until you leave the Entrusted State.\n'
            '(5)-[Triggered/Start of Turn, 1/Encounter]: If below the '
            'Injured Health Threshold with 3+ stacks of Lifeforce, remove '
            'all Lifeforce (and stop suffering Energy Charge effects, losing '
            'gathered Energy Charges) and enter the Entrusted State until '
            'the end of your turn.',
      ),
    ],
  ),
  TransformationDef(
    name: "Fruit's Might",
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    prerequisiteText: 'Must be obtained through consuming a Fruit from the '
        'Tree of Might',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: "Fruit of the World's Energy",
        description: 'By consuming a fruit from the Tree of Might, you '
            "absorb a portion of an entire planet's life energy.\n"
            '(1)-[Passive]: Increase the Dice Category of your Greater Dice '
            'by Z Dice Categories.\n'
            '(2)-[Passive]: Increase your Boosted Speed, Wound Rolls, and '
            'Soak Value by Z(T).\n'
            '(3)-[Triggered]: Upon gaining a stack of this Awakening during '
            'a Combat Encounter, use the Power Up Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you deal Damage to an Opponent '
            'with an Attacking Maneuver, make a Might Clash against them; if '
            'you win, they are knocked Prone.\n'
            '(5)-[Triggered/Power, Z/Encounter]: Enter the Superior State '
            'until the start of your next turn.',
        automation: [
          // (2) +Z(T) Boosted Speed, Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.speedBoosted,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Planetary Diet',
        minStacks: 2,
        description: "Each fruit you consume is a portion of a planet's "
            'energy, and your increasing might reflects the number of these '
            "fruits you've supped upon.\n"
            '(1)-[Passive]: While in the Superior State, increase your Might '
            'by 1(T).\n'
            "(2)-[Passive]: If this stack of Fruit's Might is not a "
            'Temporary Awakening, increase your Maximum Ki Points by 2 for '
            'each Power Level reached.\n'
            '(3)-[Triggered, 1/Round]: If you target a Prone Opponent (and '
            'no other Characters) with an Attacking Maneuver, apply an '
            'Energy Charge to that Attacking Maneuver.',
        automation: [
          // (1) While in the Superior State (tracked in the States list):
          // +1(T) Might.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Superior',
          ),
          // (2) +2 Max Ki per Power Level (this app doesn't model Temporary
          // Awakenings, so an owned stack is treated as permanent).
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
    name: 'Grappler',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Brawler Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Dangerous Grab',
        description: '(1)-[Passive]: Increase your Grapple Checks by 1(T).\n'
            '(2)-[Passive]: While in a Grapple, increase your Soak Value and '
            'Wound Rolls by 1(T).\n'
            '(3)-[Passive]: Your use of the Grapple Maneuver through the 2nd '
            "effect of Brawler ignores the Maneuver's [1/Round] "
            'limitation.\n'
            '(4)-[Passive]: You may use the Grapple Maneuver instead of the '
            'Basic Attack Maneuver through the effects of the Exploit '
            'Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you successfully enter a Grapple '
            'as the Grappler, you may either: use the Basic Attack Maneuver '
            'as an Out-of-Sequence Maneuver against a Grappled Character; '
            'use the Launch Maneuver as an Out-of-Sequence Maneuver; or make '
            'a Might Clash against the Grappled Character(s) (if you win, '
            'they gain Broken and Impaired until the start of your next '
            'turn).\n'
            '(6)-[Triggered, 1/Encounter]: While the Grappler in a Grapple, '
            'if you use a Signature Technique with the Powerbomb Advantage, '
            'double your Might for that Advantage.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Heavyweight',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Supersized Soak',
        description: 'The extra padding on your frame helps to soften '
            'incoming blows.\n'
            '(1)-[Passive]: Increase your Soak Value by 1(T), but reduce '
            'your Defense Value by 1(T).\n'
            '(2)-[Passive]: Increase your Soak Value by 1(T) for the '
            'duration of your Defend Maneuvers.\n'
            '(3)-[Passive]: Your Size Category is treated as 1 larger for '
            "your Opponents' Punching Down and Gigantic Grip.\n"
            '(4)-[Triggered, 1/Round]: If you take no Damage from an '
            'Attacking Maneuver that hits you, gain 1 Counter Action.\n'
            '(5)-[Triggered, 1/Round]: If you use the Movement Maneuver or '
            'an Attacking Maneuver with Charging Assault, treat your Boosted '
            'Speed as equal to your Tenacity Modifier for its duration.\n'
            '(6)-[Triggered, 1/Encounter]: If you use the Direct Hit or '
            'Guard options of the Defend Maneuver, set the Damage Category '
            'of that Attacking Maneuver to Standard for your Damage '
            'Calculation.',
        automation: [
          // (1) +1(T) Soak Value, -1(T) Defense Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          RaceTraitAutomation(
            affectedStats: [AffectedStat.defenseValue],
            coefficient: -1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Impulse',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Mach Dash',
        description: 'Your incredible speed allows you to avoid even the '
            'most opportune of attacks.\n'
            '(1)-[Passive]: Increase your Defense Value by 1(T).\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of the Movement '
            'Maneuver when you use your Boosted Speed by 1(T).\n'
            '(3)-[Passive]: Increase your Boosted Speed by 2(T).\n'
            '(4)-[Passive]: If you would use your Cognitive Save for a Clash '
            'initiated by an Opponent, you may use your Impulsive Save '
            'instead.\n'
            "(5)-[Triggered, 1/Round]: If you successfully dodge an "
            "Opponent's Attacking Maneuver, use the Movement Maneuver as an "
            'Out-of-Sequence Maneuver (may move through occupied Squares, '
            'but cannot end there).\n'
            '(6)-[Triggered, 1/Round]: If you use an Attacking Maneuver of '
            'the Combination Profile or with Charging Assault, and your '
            'Boosted Speed exceeds that of all targets, spend 2(bT) Ki '
            'Points to apply an Energy Charge to it.',
        automation: [
          // (1) +1(T) Defense Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (3) +2(T) Boosted Speed.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.speedBoosted],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Initial Class',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Starting Class',
        description: 'The initial path you choose will shape the rest of '
            'your destiny.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select and gain '
            'access to a Class of your choice — each Class boosts one of '
            "this Transformation's Attribute Modifier Bonuses by +1 and "
            'grants a Special Maneuver: Martial Artist (AG; Roar), '
            'Spiritualist (IN; Curse), Warrior (FO/MA; Draconic Infusion), '
            'Cleric (FO/MA; Divine Blessing), Mighty (TE; Mighty Breeze), '
            'Wonder (FO/MA; Dark Beam). See the site for each Class\'s full '
            'effects.\n'
            '(2)-[Passive]: Increase your Maximum Life Points by 2 for each '
            'Power Level reached.',
        automation: [
          // (2) +2 Max Life per Power Level.
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
    name: 'Intuitive Fighter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Intuit Maneuver',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Every Conceivable Advantage',
        description: 'Your ability to read your opponents is unparalleled, '
            'allowing you to react as quickly as they act.\n'
            '(1)-[Passive]: Increase your Strike and Dodge Rolls against '
            'Seen Opponents by 1(T).\n'
            '(2)-[Triggered, 1/Round]: Do not gain stacks of Diminishing '
            'Defense from the Attacking Maneuver of a Seen Opponent.\n'
            '(3)-[Triggered, 1/Round]: If targeted by an Attacking Maneuver '
            'from a Seen Opponent, make a Clash (Intuition vs '
            'Bluff/Intimidate/Stealth); if you win, use the Defend Maneuver '
            'in response without spending a Counter Action.\n'
            '(4)-[Triggered, 1/Round]: If you target a Character with the '
            'Intuit Maneuver, make a Clash (Intuition vs '
            'Bluff/Intimidate/Stealth) against them; if you win, use the '
            'Basic Attack Maneuver as an Out-of-Sequence Maneuver against '
            'them.\n'
            '(5)-[Triggered/Start of Turn, 1/Encounter]: Use the Intuit '
            'Maneuver as an Out-of-Sequence Maneuver.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Insatiable',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Transfiguration Beam Racial Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Ceaseless Hunger',
        description: 'Your boundless appetite leaves you constantly feeling '
            'starved.\n'
            '(1)-[Passive]: If you do not have access to the Absorb '
            'Maneuver, gain access to it (but you can only target '
            'Transfigured Characters with it when gained this way).\n'
            '(2)-[Passive]: For each stack of the Absorption Awakening you '
            'possess, increase your Wound Rolls and Soak Value by 1(T).\n'
            '(3)-[1/Round]: If you have a stack of the Absorption Awakening '
            'as a Temporary Awakening, use the Power Up Maneuver as an '
            'Instant Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: Instead of killing a Character '
            'who was a Snack Basic Item you used, target them with the '
            'Absorb Special Maneuver as an Out-of-Sequence Maneuver (they '
            'auto-lose every Clash for it).\n'
            '(5)-[Triggered, 1/Encounter]: If you win a Clash against an '
            'Opponent through the Transfiguration Maneuver, gain 1 Action.',
      ),
    ],
  ),

  TransformationDef(
    name: 'Jiang Shi Talisman',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Can only be obtained through the effects of the '
        'Witchcraft Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Dangerous Empowerment',
        description: 'The power of whosoever bewitched you flows through you, '
            'empowering you even as it brings you closer to death.\n'
            '(1)-[Passive]: Ignore the effects of Reduced Momentum.\n'
            '(2)-[Passive]: Increase your Soak Value, Wound Rolls, and Might '
            'by 1(T).\n'
            '(3)-[Automatic]: If you use an Attacking Maneuver, reduce your '
            'Life Points by 1/2 of its Ki Point Cost, increasing its Wound '
            'Roll by an equal amount.\n'
            '(4)-[Automatic/Start of Turn]: Reduce your Life Points by your '
            'Might.\n'
            '(5)-[Automatic/Start of Turn]: If the character who gave you '
            'this Awakening through Mystic Talisman is Defeated, lose this '
            'Awakening.',
        automation: [
          // (2) +1(T) Soak Value, Wound Rolls and Might.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.soak,
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
  TransformationDef(
    name: 'Karmic Empowerment',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
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
        name: 'Dark Power',
        description: "This power you're using isn't good — it's dark, almost "
            'darkness incarnate — and the darkness gnaws at your mind, though '
            'sometimes darkness can snuff out light.\n'
            '(1)-[Passive]: Reduce your Cognitive Save by 1(T).\n'
            '(2)-[Passive]: Upon gaining this Awakening, gain access to the '
            'Evil Aura Enhancement or any of its variants you meet the '
            'prerequisites for.\n'
            '(3)-[Passive]: Increase your Stress Bonus by 1 while using the '
            'Evil Aura Enhancement.\n'
            '(4)-[Passive]: While suffering from the Compelled Combat '
            'Condition, increase your Soak Value and Wound Rolls by 2(T).\n'
            '(5)-[Triggered/Start of Turn]: If you are not in a '
            'Transformation with the Rampaging Aspect, select an Opponent; '
            'you gain the Compelled Combat Condition with them as the target '
            'until the start of your next turn.',
        automation: [
          // (1) -1(T) Cognitive Save.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.cognitiveSave],
            coefficient: -1,
            tierScaling: TierScaling.current,
          ),
          // (4) While suffering the Compelled Combat Condition (tracked in
          // the Conditions list): +2(T) Soak Value and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.soak,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedConditionActive,
            conditionStateName: 'Compelled',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Learned Path',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Seeking Strength and/or Seeking Skill Awakening(s)',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Sought-After Capabilities',
        description: '(1)-[Triggered/Start of Combat Encounter, Resource]: '
            "Gain 'Sought Points' equal to your SKI plus STR.\n"
            '(2)-[Passive]: If you are On the Path, increase the Attribute '
            'Modifier Bonus (TE/FO/MA) of Learned Path by 1 and your Wound '
            'Rolls and Soak Value by 1(T).\n'
            '(3)-[Passive]: If you are Still Learning, increase the Attribute '
            'Modifier Bonus (AG/IN) of Learned Path by 1 and your Strike '
            'Rolls and Surgency by 1(T).\n'
            '(4)-[Triggered]: When making a Combat Roll for (or in response '
            'to) an Attacking Maneuver, spend up to 1(bT) Sought Points; '
            'increase that Combat Roll by triple the amount spent.\n'
            '(5)-[Triggered]: When making a Might/Saving Throw Clash, spend '
            'up to 1(bT) Sought Points to increase its Dice Score by the '
            'amount spent (doubled if the Clash was initiated by an '
            'Opponent).\n'
            '(6)-[Triggered]: If hit by an Attacking Maneuver, spend up to '
            '1(bT) Sought Points to increase your Damage Reduction by double '
            'the amount spent for its duration.\n'
            '(7)-[1/Round]: Spend 1(bT) Sought Points to use the Power Up '
            'Maneuver or Energy Charge Maneuver as an Instant Maneuver.\n'
            '(8)-[Triggered/Power, 1/Encounter]: If you have 0 Sought Points, '
            'gain Sought Points equal to your SKI plus STR.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Lesser Mutation',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Mutation Factor',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Multi-Faceted Mutation',
        description: '(1)-[Passive]: Upon gaining this Awakening, select an '
            'Attribute (except FO/MA) and increase the Attribute Modifier '
            'Bonus of this Awakening by 1 for that Attribute.\n'
            '(2)-[Passive]: Select and gain access to a Mutation Factor '
            'Trait (except one with a specific Racial Requirement).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Lockdown Fighter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Exploit Expert Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Forcing an Opening',
        description: "You manipulate your foes' movements, ensuring they "
            'react in accordance with your plans. When they inevitably fall '
            'into your trap, you strike.\n'
            '(1)-[Triggered/Start of Combat Round, Ruling]: Target an '
            "Opponent. That Opponent becomes 'Locked' until the end of the "
            'Combat Round.\n'
            '(2)-[Passive]: Any Maneuver (except an Out-of-Sequence '
            'Maneuver) made by a Locked Opponent within your Melee Range '
            'triggers your Exploit Maneuver.\n'
            '(3)-[Passive]: If a Locked Opponent would move through their own '
            'effects/Maneuvers while within your Melee Range, halve the '
            'Squares they can move.\n'
            '(4)-[Triggered]: If a Locked Opponent triggers your Exploit '
            'Maneuver and you choose not to use it, regain 1(bT) Ki '
            'Points.\n'
            '(5)-[Triggered, 1/Encounter]: If you regain Ki Points through '
            'the 4th effect, use the Power Up or Transformation Maneuver as '
            'an Out-of-Sequence Maneuver.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Lone Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Mind Power ~ Ki',
        description: 'By focusing your mind, you stand up to even the '
            'toughest foes.\n'
            "(1)-[Passive, Ruling]: While you meet at least one condition "
            "below, treat the Combat Encounter as a 'Desperate Battle': your "
            'non-Defeated Opponents exceed your non-Defeated Allies plus '
            "you; or you face an Opponent whose base Tier of Power exceeds "
            'yours.\n'
            '(2)-[Passive]: While in a Desperate Battle, increase your Combat '
            'Rolls by 1(T) and the Dice Score of your Steadfast Checks by '
            '1.\n'
            '(3)-[Passive]: While in a Desperate Battle and at least 1 Ally '
            '(except a Minion) is Defeated, increase your Stress Bonus by '
            '2.\n'
            '(4)-[Triggered, 1/Encounter]: If an Ally (except a Minion) is '
            'Defeated or you stop being Defeated, use the Power Up or '
            'Transformation Maneuver as an Out-of-Sequence Maneuver.\n'
            '(5)-[Triggered/Start of Combat Round, 1/Encounter]: If you are '
            'Defeated and the Combat Encounter is a Desperate Battle, set '
            'your Life Points to 1 below the Critical Health Threshold and '
            'take your turn immediately, ignoring the Initiative Order.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Majin Mark',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Prince of Destruction',
        description: 'Bringing out the power given to you by the darkness '
            'inside, you manifest greater strength.\n'
            '(1)-[Passive]: Reduce your Cognitive Save by 1(T).\n'
            '(2)-[Passive]: Ignore Reduced Momentum.\n'
            '(3)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(4)-[Triggered/Start of Turn]: Reduce your Life Points by 4(bT) '
            'to increase your Combat Rolls by 1(T) until the start of your '
            'next turn.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Reduce your Life Points by '
            '1/4 of your Maximum to increase your Tier of Power by 1 (see — '
            'Breakthrough) until the end of your next turn.',
        automation: [
          // (1) -1(T) Cognitive Save.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.cognitiveSave],
            coefficient: -1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),

  TransformationDef(
    name: 'Martial Skill',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Martial Arts Practitioner',
        description: 'With the foundations of combat and mental discipline, '
            'you are on the road to becoming a true warrior.\n'
            '(1)-[Passive]: Gain access to the Stance Special Maneuver — '
            'enter one of 4 Stances (Flame: +Wound/Might, -Awareness; Wind: '
            '+Defense/Speeds, -Soak; Wave: +Awareness/Saves, -Wound; Stone: '
            '+Soak/Surgency, -Defense), all 1(T).\n'
            '(2)-[Passive]: While below the Bruised Health Threshold, '
            'increase your Surgency by 1(T).\n'
            '(3)-[Option]: Upon gaining access, select one of the effects '
            'below.\n'
            '(4)-[Triggered, 1/Encounter]: Upon entering a Stance, apply the '
            'matching effect: Flame — use the Energy Charge Maneuver '
            'Out-of-Sequence; Wind — use the Movement Maneuver Out-of-'
            'Sequence (no Rapid Movement KP increase); Wave — use the Basic '
            'Attack Maneuver Out-of-Sequence; Stone — gain 1 Counter '
            'Action.\n'
            '(5)-[Triggered/Start of Combat Encounter]: Use the Stance '
            'Maneuver as an Out-of-Sequence Maneuver.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Style',
            options: [
              TraitOption(
                name: 'Offensive Style',
                description: '[Passive]: Increase your Strike Rolls by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.strike],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Defensive Style',
                description: '[Passive]: Increase your Dodge Rolls by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.dodge],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
            ],
          ),
        ],
        automation: [
          // (2) While below the Bruised Health Threshold: +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Control Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Teachings of Energy',
        description: '(1)-[Passive]: When using a Signature Technique with '
            'the Counter or Exploiting Technique Advantage, apply a rank of '
            'Power Shot (may exceed the maximum).\n'
            '(2)-[Passive]: Upon gaining access, gain a Talent from the '
            'Attacking, Counter, Technique, or Weapon Talent Category.\n'
            '(3)-[Passive]: Gain access to the Counter Stance (treated as '
            'the Wave Stance; doubles the 4th-effect bonuses while in it).\n'
            '(4)-[Passive]: Increase your Strike Rolls and Soak Value by '
            '1(T).\n'
            '(5)-[Passive]: While in the Counter Stance, increase the Wound '
            'Rolls of Attacking Maneuvers made through the Defend or Exploit '
            'Maneuver by 1(T).\n'
            '(6)-[1/Encounter]: If in the Counter Stance, use the Defend or '
            'Exploit Maneuver without paying a Counter Action.\n'
            '(7)-[1/Encounter]: As an Instant Maneuver while in the Counter '
            'Stance, gain a Counter Action.',
        automation: [
          // (4) +1(T) Strike Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike, AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Crane School Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening, access to the Dodonpa '
        'Signature Technique',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Style of the Crane School',
        description: 'Like a crane in flight, you were taught to fight with '
            'graceful precision and to remain constantly on the move.\n'
            '(1)-[Passive]: Your Dodonpa Signature Technique gains a rank of '
            'Power Shot and the Ascended Signature Advantage for free '
            '(refunding TP if already at maximum).\n'
            '(2)-[Passive]: Upon gaining access, gain a Skill Improvement.\n'
            '(3)-[Passive]: Gain access to the Crane Stance (treated as the '
            'Wind Stance; doubles the 4th-effect bonuses while in it).\n'
            '(4)-[Passive]: Increase your Dodge and Wound Rolls by 1(T).\n'
            '(5)-[Passive]: While in the Crane Stance, increase the Strike '
            'Rolls of your Signature Techniques by 1(T).\n'
            '(6)-[Triggered, 1/Encounter]: If you use the Dodonpa while in '
            'the Crane Stance, increase its Damage Category by 1 Category.\n'
            '(7)-[Triggered, 1/Encounter]: If you gain Bonus Momentum, use '
            'the Basic Attack or Signature Technique Maneuver Out-of-'
            'Sequence.',
        automation: [
          // (4) +1(T) Dodge and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.dodge,
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
    name: 'Dragon Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening, access to a Super Signature '
        'with the Ascended Signature Advantage',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Style of the Dragon',
        description: '(1)-[Passive]: When using a Signature Technique with '
            'the Ascended Signature Advantage, apply a rank of Power Shot '
            '(may exceed the maximum).\n'
            '(2)-[Passive]: Upon gaining access, gain an Attribute '
            'Addition.\n'
            '(3)-[Passive]: Gain access to the Dragon Stance (treated as the '
            'Flame Stance; doubles the 4th-effect bonuses while in it).\n'
            '(4)-[Passive]: Increase your Wound Rolls and Soak Value by '
            '1(T).\n'
            '(5)-[Passive]: While in the Dragon Stance, reduce the Ki Point '
            'Cost of the Guard option of the Defend Maneuver by 2(T) and of '
            'your Signature Techniques by 1(T).\n'
            '(6)-[Triggered, 1/Encounter]: While in the Dragon Stance, if '
            'you use an Ultimate Signature Technique, halve your Soak Value '
            'until the start of your next turn to increase its Wound Roll by '
            'your Soak Value.\n'
            '(7)-[Triggered/Power, 1/Encounter]: While in the Dragon Stance, '
            'use the Energy Charge Maneuver Out-of-Sequence.',
        automation: [
          // (4) +1(T) Wound Rolls and Soak Value.
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
    ],
  ),
  TransformationDef(
    name: 'Martial Prowess',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Martial Arts Expert',
        description: 'Becoming a true master of the art of combat, you have '
            'learned to react more effectively in response to danger.\n'
            '(1)-[Passive]: While below the Bruised Health Threshold, '
            'increase your Wound Rolls by 1(T).\n'
            '(2)-[Passive]: While below the Injured Health Threshold, '
            'increase your Defense Value and Soak Value by 1(T).\n'
            '(3)-[Passive]: The Stance Maneuver becomes an Instant '
            'Maneuver.\n'
            '(4)-[Passive]: The 4th effect of Martial Arts Practitioner '
            'loses [1/Encounter] and gains [2/Encounter].\n'
            '(5)-[Triggered, 1/Round, 2/Encounter]: If you use the Stance '
            'Maneuver, use the Power Up Maneuver Out-of-Sequence.',
        automation: [
          // (1) While below the Bruised Health Threshold: +1(T) Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
          // (2) While below the Injured Health Threshold: +1(T) Defense
          // Value and Soak Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.defenseValue, AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Master of Many Hands',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening, access to the Extra Arms '
        'Unique Ability',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Style of Many Fists',
        description: '(1)-[Passive]: When using a Signature Technique with '
            'the Restriction – State Disadvantage (Extra Arms Special State '
            'selected), apply a rank of Power Shot (may exceed the '
            'maximum).\n'
            '(2)-[Passive]: Upon gaining access, gain a Skill Improvement.\n'
            '(3)-[Passive]: Gain access to the Flurry Fist Stance (treated '
            'as the Wave Stance; while in it, +1(T) Strike Rolls and doubles '
            'the 4th-effect bonuses).\n'
            '(4)-[Passive]: Increase your Wound Rolls by 1(T).\n'
            '(5)-[Passive]: While in the Flurry Fist Stance, reduce the Ki '
            'Point Cost of the Extra Arms Unique Ability by 2(T).\n'
            '(6)-[Triggered, 1/Encounter]: Upon entering the Flurry Fist '
            'Stance, use the Extra Arms Unique Ability Out-of-Sequence.\n'
            '(7)-[Triggered/Extra Arms, 1/Encounter]: Use the Basic Attack '
            'Maneuver Out-of-Sequence.',
        automation: [
          // (4) +1(T) Wound Rolls.
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
    ],
  ),
  TransformationDef(
    name: 'Turtle School Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening, access to the Kamehameha '
        'Signature Technique',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Style of the Turtle School',
        description: 'Trained to survive no matter what, your tenacious '
            'fighting style is reminiscent of a turtle retreating into its '
            'shell.\n'
            '(1)-[Passive]: Your Kamehameha Signature Technique gains a rank '
            'of Power Shot and the Ascended Signature Advantage for free '
            '(refunding TP if already at maximum).\n'
            '(2)-[Passive]: Upon gaining access, gain an Attribute '
            'Addition.\n'
            '(3)-[Passive]: Gain access to the Turtle Stance (treated as the '
            'Stone Stance; doubles the 4th-effect bonuses while in it).\n'
            '(4)-[Passive]: Increase your Soak Value and Surgency by 1(T).\n'
            '(5)-[Passive]: While in the Turtle Stance, increase the Wound '
            'Rolls of your Signature Techniques by 1(T).\n'
            '(6)-[Triggered, 1/Encounter]: If you use the Kamehameha while '
            'in the Turtle Stance, apply an Energy Charge to it.\n'
            '(7)-[Triggered/Threshold, 1/Encounter]: Gain 1 Counter Action, '
            'then regain Life and Ki Points equal to your Surgency.',
        automation: [
          // (4) +1(T) Soak Value and Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),

  TransformationDef(
    name: 'Masked Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'You cannot gain this Awakening except through the '
        'effects of the Time Breaker Mask Accessory',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Power of the Mask',
        description: 'Empowered by the Time Breaker Mask hiding your '
            'identity, you now answer to the dark powers in charge of the '
            'Time Breakers.\n'
            '(1)-[Passive]: Reduce the Dice Score of your Cognitive Saves by '
            '2(bT).\n'
            '(2)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(3)-[Passive]: For each Health Threshold you are below, increase '
            'your Stress Bonus by 1.\n'
            '(4)-[Passive]: For each Health Threshold you are below, increase '
            'your Soak Value and Wound Rolls by 1(T).\n'
            '(5)-[Triggered, 1/Encounter]: If you use the Transformation '
            'Maneuver while in the Healthy Health Threshold, reduce your Life '
            'Points to 1 below the Bruised Health Threshold (no Reduced '
            'Momentum; auto-succeed the Steadfast Check for it).',
        automation: [
          // (1) -2(bT) to the Dice Score of Cognitive Saves.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.cognitiveSave],
            coefficient: -2,
            tierScaling: TierScaling.base,
          ),
          // (4) +1(T) Soak Value and Wound Rolls per Health Threshold below.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.soak,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perHealthThresholdBelow,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Mass Consumption',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Draining Attack Modifier Maneuver',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Consumed Masses',
        description: 'Your energy reserves skyrocket thanks to the massive '
            'amounts of energy you have consumed.\n'
            '(1)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Points by 1 for each Power Level reached.\n'
            '(2)-[Passive]: While in the Healthy Health Threshold, increase '
            'your Soak Value by 1(T).\n'
            '(3)-[Passive]: Increase the Wound Rolls of Attacking Maneuvers '
            'with the Draining Attack Modifier applied by 2(T).\n'
            '(4)-[Triggered, 1/Round]: If Draining brings your Life Points '
            'above a Health Threshold, either remove a Combat Condition '
            '(except Pinned, Suffocating, Stress Exhaustion, or '
            'Transfigured) or use the Power Up Maneuver Out-of-Sequence.\n'
            '(5)-[Triggered, 1/Encounter]: If you Defeat or knock an '
            'Opponent through a Health Threshold with a Draining Attacking '
            'Maneuver, enter the Superior State until the end of your next '
            'turn.',
        automation: [
          // (1) +1 Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 1,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) While in the Healthy Health Threshold: +1(T) Soak Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Mastery of the Self',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Calm Mind Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Internal and External Control',
        description: 'Through mastery over your mind, you have mastered your '
            'body, allowing you to achieve equilibrium and inner peace.\n'
            '(1)-[Passive]: While in the Mindful State, increase your Strike '
            'and Dodge Rolls by 1(T).\n'
            '(2)-[Passive]: Treat L as if it was 1 higher for the effects of '
            'your Mindful Talents.\n'
            '(3)-[Triggered, 1/Round]: While in the Mindful State, upon '
            'rolling a Combat Roll, increase its Natural Result by 1.\n'
            '(4)-[1/Encounter]: If you are in the Mindful State, use the '
            'Parry option of the Defend Maneuver without paying the Action '
            'Cost.\n'
            '(5)-[Triggered/Mindful, 1/Encounter]: Remove all Combat '
            'Conditions you are suffering from (except Pinned, Suffocating, '
            'or Transfigured).',
        automation: [
          // (1) While in the Mindful State (tracked in the States list):
          // +1(T) Strike and Dodge Rolls.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike, AffectedStat.dodge],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Mindful',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Mystical Might',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Magic Warrior Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Witch and Warrior',
        description: 'Combining martial prowess and magical power, you wield '
            'your mystical powers like an ordinary warrior wields their '
            'spiritual energy.\n'
            '(1)-[Triggered, 1/Round, Ruling]: If you deal Damage to an '
            "Opponent with a Physical Attack, they become 'Hexed' until the "
            'end of your turn.\n'
            '(2)-[Passive]: Increase the Strike Rolls of your Physical '
            'Attacks by 1(T).\n'
            '(3)-[Passive]: Increase the Wound Rolls of your Energy or Magic '
            'Attacks against Hexed Opponents by 2(T).\n'
            '(4)-[Triggered, 1/Round]: If you target a Hexed Opponent with '
            'an Energy or Magic Attack, apply an Energy Charge (they stop '
            'being Hexed afterwards).\n'
            '(5)-[Triggered, Addendum, 1/Encounter]: If you use an Energy or '
            'Magic Attack, apply a unique AoE of your choosing. The unique AoE '
            'is created as it is applied. That AoE is decided by you, starts '
            'with you as the Target Square, and occupies 10 Squares, which you '
            'can choose: starting from a Square adjacent to you, and picking '
            'adjacent Squares from that last Square until you have chosen 10 '
            'Squares. This is the shape of that AoE. If the Magnitude of this '
            'AoE is increased, you may add an additional 5 Squares for each '
            'increase to Magnitude.',
      ),
    ],
  ),
  TransformationDef(
    name: 'One with Nature',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Naturist Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Style in the Style-less',
        description: '(1)-[Passive]: While not wearing any Apparel and not '
            'possessing Natural Armor, increase your Surgency, Impulsive '
            'Save, Defense Value and Soak Value by 1(bT).\n'
            '(2)-[Passive]: All of your Transformations gain the Bursting '
            'Aspect.\n'
            '(3)-[1/Round]: During your turn, use the Movement Maneuver as '
            'an Instant Maneuver (reduce your Speeds by the Apparel Bonus of '
            'any Apparel equipped or Integrated).\n'
            '(4)-[Triggered, 1/Encounter]: If targeted by an Attacking '
            'Maneuver, use the Guard option of the Defend Maneuver without '
            'spending the Action Cost or Ki Point Cost.',
        automation: [
          // (1) While not wearing any Apparel (Natural Armor isn't modelled):
          // +1(bT) Surgency, Impulsive Save, Defense Value and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.surgency,
              AffectedStat.impulsiveSave,
              AffectedStat.defenseValue,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNoApparelWorn,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Perfect Positioning',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Controlling the Battlefield',
        description: 'True mastery over battle comes not just from mastering '
            "oneself, but mastering one's foes as well.\n"
            '(1)-[Passive]: Increase the Dice Score of your Might Clashes '
            'through the Knockback Advantage by 1(T).\n'
            '(2)-[Passive]: If you would use an Attacking Maneuver with a '
            'Minor Sphere AoE (centered on you), you may increase the '
            'Magnitude to Standard.\n'
            '(3)-[Triggered]: If you hit an Opponent who is not adjacent to '
            'you or at Long Range with an Attacking Maneuver, increase its '
            'Wound Roll by 2(T).\n'
            '(4)-[Triggered]: If you use a Physical Attack without an AoE, '
            'you may target any Character who is not at Long Range instead '
            'of one in your Melee Range.\n'
            '(5)-[Triggered/Start of Turn]: If no Opponents are adjacent to '
            'you and none are at Long Range, increase your Combat Rolls by '
            '1(T) until the start of your next turn.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Perfected Technique',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Favored Technique Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Sign of Mastery',
        description: '(1)-[Passive]: Increase the Strike and Wound Rolls of '
            'your Favored Technique by 1(T).\n'
            '(2)-[Passive]: While below the Injured Health Threshold, '
            'increase the Dice Category of any Energy Charges applied to '
            'your Favored Technique by 1 Category.\n'
            '(3)-[Passive]: Upon gaining this Awakening, select an Advantage '
            'with a TP Cost of 10 or less applicable to your Favored '
            'Technique; apply it.\n'
            '(4)-[Triggered, 1/Round]: If you use your Favored Technique, '
            'choose one of its Disadvantages to ignore for the duration '
            '(not for Signature Techniques treated as Favored via Technique '
            'Variant).\n'
            '(5)-[Triggered, 1/Encounter]: If you end your turn having used '
            'the Energy Charge Maneuver 3+ times with your Favored Technique '
            'declared, use the Signature Technique Maneuver Out-of-Sequence '
            'to use it.\n'
            '(6)-[Triggered, 1/Encounter]: If you use your Favored Technique '
            'below the Injured Health Threshold, apply the All Out or '
            'Complete Annihilation Super Profiles to it.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Reclaimed Heritage',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Alternate Upbringing Factor',
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Acceptance of Self',
        description: 'By coming to terms with the race from which you '
            'descend, you become a paragon of both your biological race and '
            'your adoptive race.\n'
            '(1)-[Passive]: Gain access to the Secondary Racial Trait you '
            'traded out to obtain a Factor Trait from the Alternate '
            'Upbringing Factor.',
      ),
    ],
  ),

  TransformationDef(
    name: 'Restrained Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Choosing your Moment',
        description: 'You stand on the sidelines of battle, studying your '
            'opponents and waiting for the right time to join the fray.\n'
            '(1)-[Passive]: While in the Spectator Special State, increase '
            'your Soak Value and Defense Value by 1(bT).\n'
            '(2)-[Passive]: While not in the Spectator Special State, '
            'increase your Wound Rolls and Surgency by 1(T).\n'
            '(3)-[Triggered/Start of Turn, Resource]: If in the Spectator '
            'State via the 6th effect and you did not use the 2nd effect of '
            'the Spectator State this turn, gain a stack of Stoicism (max. '
            '3).\n'
            '(4)-[Triggered, 1/Encounter]: If you exit the Spectator State '
            'while your Top Layer of Apparel is Weights, doff those Weights '
            'as an Out-of-Sequence Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you exit the Spectator State, '
            'lose all Stoicism. With 2+ stacks, enter the Superior State '
            'until the end of your next turn; with 3, then use the Power Up '
            'Maneuver Out-of-Sequence.\n'
            '(6)-[Triggered/Start of Combat Encounter]: Enter the Spectator '
            'Special State.',
        automation: [
          // (1) While in the Spectator Special State (tracked in the States
          // list): +1(bT) Soak Value and Defense Value. The complementary
          // 2nd effect (while NOT in it) stays manual — negated State
          // conditions aren't automated.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.base,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Spectator',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Results of Training',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Steady Progress',
        description: 'Sometimes, taking it slow and putting in the effort to '
            "succeed pays off in ways shortcuts to power can't.\n"
            '(1)-[Passive]: Upon gaining a stack, select Agility or '
            'Tenacity; increase this Awakening\'s Attribute Modifier Bonus '
            '(after stacks) for it by 1.\n'
            '(2)-[Passive]: Upon gaining a stack, gain a Character Perk to '
            'spend immediately.\n'
            '(3)-[Passive]: Increase your Life Points by 1/2 (rounded up) of '
            'Z for each Power Level reached.\n'
            '(4)-[Passive]: Upon gaining a stack, select a Combat Roll and '
            'increase it by 1(T) (you cannot pick the same Combat Roll as '
            'the previous stack).',
        // (1) Per Stack, distribute a flat +1 AMB between AG and TE (total
        // should equal the current Stack count) — driven by two steppers.
        distributableAmb: [DbuAttribute.agility, DbuAttribute.tenacity],
      ),
    ],
  ),
  TransformationDef(
    name: 'Seeking Balance',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    prerequisiteText: 'Seeking Strength and Seeking Skill Awakenings',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Balance between the Extremes',
        description: '(1)-[Passive]: Upon gaining this Awakening, gain a '
            'Character Perk.\n'
            '(2)-[Passive]: Your Attribute Additions are considered Skill '
            'Improvements for the 1st effect of Chance for Improvement.\n'
            '(3)-[Passive]: Your Skill Improvements are considered Attribute '
            'Additions for the 1st effect of Strength is Everything.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Shapeshifting Focus',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Shapeshift Unique Ability',
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Combat Shifter',
        description: 'As you shift between forms, altering your shape '
            'at-will, you optimize your body instantly for the '
            'ever-changing state of the battlefield.\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of the Shapeshift '
            'Unique Ability by 2(T).\n'
            '(2)-[Passive]: You do not have to spend Ki Points to maintain '
            'Shapeshift.\n'
            '(3)-[Triggered/Start of Turn]: Spend 2(bT) Ki Points to '
            'exchange the Attribute Score of two of your Attributes '
            '(AG/FO/TE/MA) until the start of your next turn.\n'
            '(4)-[Triggered/Start of Turn]: Spend 2(bT) Ki Points to declare '
            "a Profile with 'Elemental' in the name as a Favored Element "
            'until the start of your next turn.\n'
            '(5)-[Triggered/Start of Turn]: Spend 2(bT) Ki Points to create '
            'and Integrate a Weapon (Craftsmanship Grade = your base Tier of '
            'Power) until the start of your next turn.\n'
            '(6)-[Triggered/Start of Combat Round]: Select 2 Attributes '
            '(except SC/PE); increase this Awakening\'s Attribute Modifier '
            'Bonus by 1 for them until the end of the Combat Round.\n'
            '(7)-[Triggered/Start of Combat Round, 1/Encounter]: The 6th '
            "effect's increase becomes 1(bT) for this Combat Round.",
      ),
    ],
  ),
  TransformationDef(
    name: 'Spirit Control',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 3,
    prerequisiteText: '2+ Skill Ranks in the Clairvoyance Skill',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Spiritual Apprentice',
        description: 'You have been trained to finely control your energy.\n'
            '(1)-[Passive]: You may spend Technique Points to obtain the '
            'Spiritual Unique Abilities and their Advancements (Instant '
            'Transmission and its variants, Gigantification, Spiritual '
            'Healing, Spiritual Cloning, Forced Spirit Fission — see the '
            'site).\n'
            '(2)-[Passive]: When you gain a stack, gain access to one '
            'Spiritual Unique Ability without paying the TP Cost.\n'
            '(3)-[Passive]: Increase the Dice Score of your Clairvoyance '
            'Skill Checks by 2.\n'
            '(4)-[Passive]: Increase your Maximum Ki Points by 2 for every '
            'Power Level.\n'
            '(5)-[Passive]: Reduce the Ki Point Cost of all your Attacking '
            'Maneuvers by 1(T).\n'
            '(6)-[Passive]: Increase your Surgency by Z(bT).\n'
            '(7)-[Triggered, 1/Encounter]: When using an Attacking Maneuver, '
            'you do not have to pay its Ki Point Cost.',
        automation: [
          // (4) +2 Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (6) +Z(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.base,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Spiritual Elite',
        minStacks: 2,
        description: "With your newfound expertise, you've grown more "
            'efficient at manipulating your energy.\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of your Spiritual '
            'Unique Abilities by 2(T).\n'
            '(2)-[Passive]: Increase the Wound Rolls of your Attacking '
            'Maneuvers by 1/4 of their Ki Point Cost (before reductions).\n'
            '(3)-[Triggered/Start of Turn]: Regain Z(bT) Ki Points.',
      ),
      TransformationTrait(
        name: 'Spiritual Master',
        minStacks: 3,
        description: 'Through intense training and complete mastery, you '
            'have learned to revitalize yourself more effectively.\n'
            '(1)-[1/Encounter]: Use a Ki Surge as an Instant Maneuver.\n'
            '(2)-[Triggered, 2/Round]: Each time you regain Ki Points, '
            'regain 3(bT) Life Points.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Supporter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Fervent Support',
        description: 'Your constant, unwavering cheers of support help your '
            'Allies stay in the fight longer.\n'
            '(1)-[Passive]: Reduce your Racial Life Modifier by 4 (can '
            'become negative).\n'
            '(2)-[Passive]: While targeting an Ally through the 1st effect '
            'of the Spectator State, that Ally also has their Soak Value '
            'increased by 1(bT).\n'
            '(3)-[1/Round]: While in the Spectator State, use the Empower '
            'Maneuver (as if you spent 1 Action) as an Instant Maneuver.\n'
            '(4)-[1/Round]: While in the Spectator State, use a Unique '
            'Ability or Special Maneuver (Standard, Action Cost 1, not '
            'targeting an Opponent) as an Instant Maneuver.\n'
            "(5)-[Triggered, 1/Round]: If hit by an Opponent's Attacking "
            'Maneuver, an Ally may use the Intervene Maneuver to defend you '
            'without spending a Counter Action.\n'
            '(6)-[Triggered, 1/Round]: When you would regain Life or Ki '
            'Points through the Spectator State, halve the amount to let the '
            'Ally you targeted regain Life and Ki Points equal to it.',
        automation: [
          // (1) -4 Racial Life Modifier = -4 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: -4,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),

  TransformationDef(
    name: 'Technique Dedication',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Favored Technique Talent',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'History of a Technique',
        description: 'Despite the many ways you have altered it, your '
            'Favored Technique remains, fundamentally, the same.\n'
            '(1)-[Passive]: Increase the Strike and Wound Rolls of your '
            'Favored Technique by 1(T).\n'
            '(2)-[Passive]: You gain access to the Technique Variant '
            'Advantage (TP Cost 7; makes another Signature Technique of the '
            'same Foundation count as your Favored Technique).\n'
            '(3)-[Passive]: Upon gaining this Awakening, gain Technique '
            'Points equal to the TP Cost of your Favored Technique; you do '
            'not spend TP applying Advantages/removing Disadvantages from '
            'it.\n'
            '(4)-[Triggered, 1/Encounter]: When using your Favored Technique '
            'with 3+ Energy Charges, apply the Complete Annihilation Super '
            'Profile to it.\n'
            '(5)-[Triggered/Start of Turn, 1/Encounter]: Create a Signature '
            'Technique of the same Foundation and TP Cost ≤ your Favored '
            "Technique's, usable until the end of your turn.",
      ),
    ],
  ),
  TransformationDef(
    name: 'Telekinetic Focus',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Access to the Telekinesis Unique Ability',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'World Shifting Force',
        description: 'With the unmatched might of your powerful mind, you '
            'manipulate objects through forces unseen, changing the '
            'battlefield as you please.\n'
            '(1)-[Passive]: Increase your Might and Grapple Checks by '
            '1(T).\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of the Telekinesis '
            'Unique Ability by 1(T).\n'
            '(3)-[Passive]: Use the Telekinesis Unique Ability an additional '
            'time per Combat Round.\n'
            '(4)-[Passive]: Increase Collision Damage suffered by an '
            'Opponent via your Telekinesis by 1/4 (rounded up) of your '
            'Might.\n'
            '(5)-[Triggered, 1/Round]: If you use Telekinesis, double the '
            '4th effect for the duration of any Maneuver used through it.\n'
            '(6)-[Triggered, 1/Encounter]: If you deal Collision Damage to '
            'an Opponent via Telekinesis, use the Basic Attack or Signature '
            'Technique Maneuver Out-of-Sequence targeting that Opponent.',
        automation: [
          // (1) +1(T) Might (Grapple Checks aren't modelled).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Tempered Fury',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Angry Warrior',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Necessary Anger',
        description: 'Your tremendous rage empowers you, but without it, '
            'your offensive might seems lackluster by comparison.\n'
            '(1)-[Passive]: While in the Raging State, increase your Wound '
            'Rolls and Soak Value by 1(T).\n'
            '(2)-[Passive]: Treat L as if it was 1 higher for your Raging '
            'Talents.\n'
            '(3)-[Triggered, 1/Round]: If you score a Botch Result on an '
            "Attacking Maneuver's Strike Roll, turn it into an Absolute "
            'Attack.\n'
            '(4)-[1/Encounter]: While in the Raging State, use the Direct '
            'Hit option of the Defend Maneuver without paying the Action '
            'Cost.\n'
            '(5)-[Triggered/Raging, 1/Encounter]: Use the Energy Charge, '
            'Signature Technique, or Basic Attack Maneuver Out-of-Sequence.',
        automation: [
          // (1) While in the Raging State (tracked in the States list):
          // +1(T) Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Raging',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Unified',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: 'Can only be obtained through the Unify Maneuver',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Entrusted Everything',
        description: 'You have been entrusted with carrying on the legacy of '
            'another person. Their will, their power, their very essence, '
            'have been left in your hands.\n'
            "(1)-[Ruling]: Upon gaining a stack, a 'Merged Character' is "
            'assigned to it. Each stack has a Merged Character.\n'
            '(2)-[Automatic]: Upon losing a stack, the Merged Character is '
            'freed (entering combat adjacent to you if applicable).\n'
            '(3)-[Passive]: Gain access to all Signature Techniques, Unique '
            'Abilities, Forms, and Enhancements of your Merged Characters '
            '(you must meet Prerequisites).\n'
            '(4)-[Passive]: For a Skill Clash/Check, you may use a Merged '
            "Character's Skill Ranks instead of your own.\n"
            '(5)-[Passive]: Increase your Surgency by Z(bT).\n'
            '(6)-[Triggered/Power, 1/Encounter]: Increase your Combat Rolls '
            'by Z(bT) until the start of your next turn.',
        automation: [
          // (5) +Z(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.base,
            perTransformationStack: true,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Vanguard',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Jump Start Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Frontline Fighter',
        description: 'You rush headlong into battle, always leading the '
            'charge.\n'
            '(1)-[Passive]: Increase your Initiative by 1(bT).\n'
            '(2)-[Passive]: While you have at least 1 adjacent Opponent, '
            'increase your Defense Value and Soak Value by 1(T).\n'
            '(3)-[Passive]: If an adjacent Opponent uses an Attacking '
            'Maneuver that does not target you, this triggers your Exploit '
            'Maneuver.\n'
            '(4)-[Triggered/Start of Turn]: If this triggers before any '
            'other Character has taken a turn this Round, increase your '
            'Strike and Wound Rolls by 1(T) and 2(T) until the start of your '
            'next turn.\n'
            '(5)-[Triggered/Start of Combat Encounter]: If you trigger the '
            '2nd effect of Jump Start, it does not count for its '
            '[1/Encounter] Keyword.',
        automation: [
          // (1) +1(bT) Initiative.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.initiative],
            coefficient: 1,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Warlock',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: '2+ Skill Ranks in Use Magic',
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Master of Magic',
        description: 'A scholar of the arcane, your magical know-how is '
            'second to none.\n'
            '(1)-[Passive]: You may use your Magic Modifier instead of your '
            'Force Modifier when calculating Surgency.\n'
            '(2)-[Passive]: Each time you gain a stack of Warlock, gain '
            'access to a Wizarding Trait of your choice (Baneful Black '
            'Magic, Elemental Expert, Magic Touch, Magical Manipulation, '
            'Marvelous Magic, Mighty Magic, Wondrous White Magic — see the '
            'site).\n'
            '(3)-[Triggered/Start of Turn, 1/Encounter]: Use a Ki Surge; if '
            'you do, increase your Surgency by Z(bT) for the duration of '
            'this Surge.',
      ),
    ],
  ),
  // Added post-ZIM (2026-07-12) from the live site (Transformation pages
  // published after the offline archive was captured).
  TransformationDef(
    name: 'Ki Technician',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: '2+ Skill Ranks in Clairvoyance',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Master of Energy',
        description: '(1)-[Passive]: You may use your Clairvoyance Skill '
            'instead of your Use Magic Skill for any Prerequisites and for '
            'any Clashes.\n'
            '(2)-[Passive]: Each time you gain a stack of Ki Technician, '
            'gain access to a Technical Trait of your choice.\n'
            '(3)-[Triggered/Start of Turn, 1/Encounter]: Use a Ki Surge. If '
            'you do, increase your Surgency by Z(bT) for the duration of '
            'this Surge.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Technical Trait',
            // One per stack, up to the max of 7 (the full set of Technical
            // Traits).
            maxChoices: 7,
            options: [
              TraitOption(
                name: 'Adjustment of Technique',
                description: '(1)-[Passive, Ruling]: Upon gaining this '
                    'Technical Trait, select 3 Advantages with a Technique '
                    'Point Cost of 10 or less (except Efficiency). These '
                    'Advantages become known as your Technical '
                    'Adjustments.\n'
                    '(2)-[Passive]: Reduce the Ki Point Cost of Physical and '
                    'Energy Attacks made through the Basic Attack Maneuver '
                    'by 1(T).\n'
                    '(3)-[Triggered, 2/Round]: If you use an Attacking '
                    'Maneuver of the Physical or Energy Foundation through '
                    'the Basic Attack Maneuver, you may apply a qualifying '
                    'Technical Adjustment to that Attacking Maneuver.\n'
                    '(4)-[Triggered, 1/Encounter]: If you use a Signature '
                    'Technique of the Physical or Energy Foundation, you may '
                    'apply any number of your qualifying Technical '
                    'Adjustments to that Attacking Maneuver.',
              ),
              TraitOption(
                name: 'Focused Blaster',
                description: '(1)-[Passive]: Increase the Wound Rolls of '
                    'your Energy Attacks by 2(T).\n'
                    '(2)-[Triggered, 1/Round]: If you hit an Opponent with '
                    'an Energy Attack, you may spend 4(bT) Ki Points to '
                    'apply an Energy Charge to that Attacking Maneuver.\n'
                    '(3)-[Triggered, 1/Encounter]: If you use the Energy '
                    'Charge Maneuver, if the declared Attacking Maneuver is '
                    'an Energy Attack, you may use the appropriate Maneuver '
                    'for that Attacking Maneuver (Basic Attack Maneuver or '
                    'Signature Technique Maneuver) as an Out-of-Sequence '
                    'Maneuver.',
                automation: [
                  // (1) +2(T) Energy Wound Rolls.
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.woundEnergy],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Ki-Infused Punch',
                description: '(1)-[Passive]: Increase the Wound Rolls of '
                    'your Physical Attacks by 2(T).\n'
                    '(2)-[Triggered, 1/Round]: If you hit an Opponent with '
                    'a Physical Attack, you may spend 4(bT) Ki Points to '
                    'apply an Energy Charge to that Attacking Maneuver.\n'
                    '(3)-[1/Encounter]: As an Instant Maneuver, you may use '
                    'the Movement Maneuver. Then, you may use the Basic '
                    'Attack Maneuver or Signature Technique Maneuver as an '
                    'Out-of-Sequence Maneuver. If you do, that Attacking '
                    'Maneuver must be a Physical Attack.',
                automation: [
                  // (1) +2(T) Physical Wound Rolls.
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.woundPhysical],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Power-Type',
                description: '(1)-[Passive]: Increase the Strike Rolls for '
                    'your Physical and Energy Attacks of the Simple and '
                    'Combination Profiles by 1(T).\n'
                    '(2)-[Triggered, 1/Round]: When making an Attacking '
                    'Maneuver of the Simple, Combination, or Mega Flare '
                    'Profile as a Physical or Energy Attack, you may apply a '
                    'Line or Cone AoE to that Attacking Maneuver.\n'
                    '(3)-[Triggered, 1/Encounter]: If you use an Attacking '
                    'Maneuver of the Physical or Energy Foundation that '
                    'possesses an AoE, you may apply the Cataclysmic Super '
                    'Profile to that Attacking Maneuver.\n'
                    '(4)-[Triggered, 1/Encounter]: If you use an Attacking '
                    'Maneuver of the Mega Flare Profile (Physical/Energy) '
                    'with a Ki Wager of at least 1/2 of your Max Capacity, '
                    'you may apply the Complete Annihilation Super Profile '
                    'to that Attacking Maneuver.',
              ),
              TraitOption(
                name: 'Precision Ki Control',
                description: '(1)-[Passive]: Reduce the Critical Target of '
                    'your Strike Rolls for your Physical and Energy Attacks '
                    'by 1.\n'
                    '(2)-[Triggered, 1/Round]: If you use a Physical or '
                    'Energy Attack that possesses an AoE, you do not target '
                    'any Allies that are within that AoE with that Attacking '
                    'Maneuver.\n'
                    '(3)-[Triggered, 1/Round]: If you score a Critical Hit '
                    'on the Strike Roll for a Signature Technique of the '
                    'Physical or Energy Foundation, apply an Energy Charge '
                    'to that Attacking Maneuver.\n'
                    '(4)-[Triggered, 1/Encounter]: If you use a Physical or '
                    'Energy Attack that possesses an AoE, but targets only 1 '
                    'Opponent, you may score a Critical Result on the Strike '
                    'Roll of that Attacking Maneuver regardless of the '
                    'Natural Result.',
              ),
              TraitOption(
                name: 'Technical Skill',
                description: '(1)-[Passive]: Reduce the Technique Point Cost '
                    'for all Technical Unique Abilities by 2 (retroactive: '
                    'gain the TP back if not applied previously; not for '
                    'free Unique Abilities).\n'
                    '(2)-[Passive]: Reduce the Technique Point Cost of all '
                    'Advancements for Technical Unique Abilities by 1 '
                    '(retroactive, as above).\n'
                    '(3)-[Passive]: Upon gaining this Technical Trait, '
                    'select a Technical Unique Ability with a TP Cost of 25 '
                    'or less that you meet the Prerequisites of. Gain access '
                    'to it; spend any remaining Technique Points on its '
                    'Advancements.\n'
                    '(4)-[1/Round]: You may use a Technical Unique Ability '
                    'that is a Standard Maneuver with an Action Cost of 1 '
                    'Action as an Instant Maneuver.',
              ),
              TraitOption(
                name: 'Trick up the Sleeve',
                description: '(1)-[Passive]: Reduce the Ki Point Cost of '
                    'your Technical Unique Abilities by 1(T).\n'
                    '(2)-[1/Round]: If you make a Clash that uses your '
                    'Saving Throws through the effects of a Unique Ability, '
                    'increase your Dice Score for that Clash by 1(T).\n'
                    '(3)-[1/Encounter]: You may use a Technical Unique '
                    'Ability with a TP Cost of 20 or less that you meet the '
                    'Prerequisites for, even if you do not have access to '
                    'that Unique Ability.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Different Path',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Cultivation of the Self Awakening, with Pure Resolve '
        'chosen for the Option effect of Enhancement of the Self',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Hard-Earned Transformation',
        description: '(1)-[Passive]: Legendary Forms are not considered '
            'Forms for the effects of Cultivation of the Self, Dedicated '
            'Warrior, or Awoken.\n'
            '(2)-[Passive]: While in a Fully Mastered Legendary Form, you '
            'may use an additional Enhancement in conjunction with it.\n'
            '(3)-[1/Encounter]: Increase the amount of Life and Ki Points '
            'regained from Legend Realized by your Surgency.',
      ),
    ],
  ),

  // ============================================================== SAIYAN ===
  TransformationDef(
    name: 'Zenkai',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    maxStacks: 3,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Saiyan Spirit',
        description: 'Your burning warrior spirit blazes brighter after '
            "you've been close to death.\n"
            '(1)-[Passive]: While you have 6+ stacks of Battle Born, '
            'increase your Combat Rolls by 1(T).\n'
            '(2)-[Passive]: Increase the Dice Score of your Steadfast '
            'Checks by 1 for each Health Threshold you are below (max. '
            'Z).\n'
            '(3)-[Triggered/Undying]: If you enter the Undying State '
            'through the 2nd effect of Saiyan Heritage, increase your '
            'Soak Value and Wound Rolls by Z(bT) until you leave the '
            'Undying State.\n'
            '(4)-[Triggered, Z/Encounter]: If you succeed at a Steadfast '
            'Check, gain a stack of Battle Born. If you trigger this '
            'effect and are already at your maximum number of Battle '
            'Born stacks, you may use the Power Up Maneuver or '
            'Transformation Maneuver as an Out-of-Sequence Maneuver '
            'instead.',
        automation: [
          // (1) While 6+ tracked 'Battle Born' Resource stacks: +1(T)
          // Combat Rolls.
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
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Battle Born',
            conditionAmount: 6,
          ),
        ],
      ),
      TransformationTrait(
        name: "Warrior's Determination",
        minStacks: 2,
        description: 'Your fierce determination keeps you in the fight '
            'long past when others would fall.\n'
            '(1)-[Passive]: While you possess 4+ stacks of Battle Born, '
            'increase your Surgency by Z(T).\n'
            '(2)-[Triggered, 1/Encounter]: If you use an Ultimate '
            'Signature Technique while in the Undying State, apply Z '
            'Energy Charges to that Attacking Maneuver.',
        automation: [
          // (1) While 4+ tracked 'Battle Born' Resource stacks: +Z(T)
          // Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Battle Born',
            conditionAmount: 4,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'On the Brink',
        minStacks: 3,
        description: "You've spent so much time on the edge of death, "
            "you've learned to leverage it against your enemies.\n"
            '(1)-[Passive]: While you are below the Injured Health '
            'Threshold and have 6+ stacks of Battle Born, increase your '
            'Strike and Dodge Rolls by 1(T).\n'
            '(2)-[1/Encounter]: Use a Healing Surge as an Instant '
            'Maneuver.\n'
            '(3)-[Automatic]: If you trigger the 4th effect of Born for '
            'Battle, instead of gaining a stack of Zenkai as a Temporary '
            'Awakening, enter the Surging State until the end of your '
            'next turn. If you do, ignore the 2nd effect of the Surging '
            'State.',
      ),
    ],
  ),

  // ============================================================= ANDROID ===
  TransformationDef(
    name: 'Artificial Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Android Race or Android Cybernetics Factor Trait, '
        'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Enhanced Class',
        description: 'Your cybernetic enhancements are geared towards your '
            'chosen specialization, making you exceptionally good at your '
            'designated combat role.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: While below the Injured Health Threshold, '
            'increase your Surgency by 2(T).\n'
            '(3)-[Choice]: Per your Class Selection Option: Hero — while Ki '
            '> 1/2 Max, +1(bT) Damage Reduction; Elite — [Start of Combat '
            'Round] while Ki > 1/2 Max, regain 2(bT) Ki; Berserker — while '
            'Ki > 1/2 Max, +2(bT) Wound Rolls.\n'
            '(4)-[Choice]: Per your Class Selection Option: Hero — [Power, '
            '1/Encounter] use a Ki Surge Out-of-Sequence; Elite — '
            '[1/Encounter] if you Ki Surge, apply Surgency again and regain '
            'Life = Surgency; Berserker — [1/Encounter] if you attack via '
            'the Berserker Choice, apply an additional Energy Charge.',
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (2) While below the Injured Health Threshold: +2(T) Surgency.
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
  TransformationDef(
    name: 'Data Input',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Lock On Racial Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Predictive Scan',
        description: 'Your on-board targeting system alerts you of incoming '
            'attacks and how best to avoid them.\n'
            '(1)-[Passive]: Increase your Dodge Rolls against your Target by '
            '2(T).\n'
            '(2)-[Passive]: You do not provoke Exploit Maneuvers from your '
            'Target.\n'
            '(3)-[Triggered, 1/Round]: If you avoid an Attacking Maneuver '
            'made by your Target that targeted you, this triggers your '
            'Exploit Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you receive Damage from an '
            "Attacking Maneuver made by your Target, reduce the Damage by "
            'your Defense Value.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Designated Target',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Lock On Racial Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Merciless Targeting',
        description: 'Your on-board targeting system locks onto a target and '
            'ensures your blows land with devastating accuracy.\n'
            '(1)-[Passive]: Attacking Maneuvers that only include your '
            'Target do not count towards Diminishing Offense.\n'
            '(2)-[Passive]: Increase the Dice Category of your Energy '
            'Charges applied to an Attacking Maneuver that targets your '
            'Target by 1 Category.\n'
            '(3)-[Triggered, 1/Round]: When attacking your Target, apply an '
            'Energy Charge to that Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Round]: When you select a Target via Lock On, '
            'choose until the start of your next turn: Locked In — +1(T) '
            'Strike/Wound vs Target, −1(T) Dodge; or Spatial Awareness — '
            'ignore the Dodge reduction from Lock On.\n'
            '(5)-[Triggered, 1/Encounter]: If you hit your Target with an '
            'Ultimate Signature Technique, increase the Dice Category of its '
            'Energy Charges by 1 Category.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Hell Fighter',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Machine Mutant Factor',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Unique Configuration',
        description: 'Despite your nearly-organic nature, you possess a '
            'standard power core in addition to the mutant core that makes '
            'up your being.\n'
            '(1)-[Passive]: Gain access to the Energy Core Racial Trait.\n'
            '(2)-[Passive]: Gain access to the Absorb Maneuver, but you can '
            'only target Androids or Bio-Androids with it.\n'
            '(3)-[Passive]: Gain access to the Unify Maneuver, but you can '
            'only gain 1 stack of Unified unless you have Android Fusion. '
            'Upon your first Unified stack, you may increase your base Size '
            'Category by 1 Category.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Improved Schematics',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Upgraded Features',
        description: "With upgraded power systems and specialized "
            "subsystems, you're able to squeeze more power and utility out "
            'of your mechanical parts.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select Agility or '
            "Tenacity; increase this Awakening's Attribute Modifier Bonus "
            'for it by 1.\n'
            '(2)-[Passive]: Upon gaining this Awakening, you may swap any '
            'number of your chosen effects from the 3rd effect of '
            'Technological Being for different ones.\n'
            '(3)-[Choice]: Per your Energy Core choice: Infinite Energy — '
            '+2(bT) to Ki regained through it; Power Battery — you may '
            'regain Ki through Ki Surges or Combat Recovery.\n'
            '(4)-[Passive]: With the Mutant Core Factor Trait, +2(T) '
            'Surgency and apply 1/2 Surgency to Ki regained through Mutant '
            "Core's 3rd effect.\n"
            '(5)-[Choice]: Depending on which effects you have access to from '
            'the 3rd effect of Technological Being, gain the following '
            'effects:\n'
            'Surging Power [Passive]: You do not have to spend Ki Points to use '
            'the effect of Surging Power.\n'
            'Weapon Ports [Passive]: Increase the Craftsmanship Grade of your '
            'Installed Weapons to 4. The Artisan Quality applied to your '
            'Installed Weapons now occupies 2 Quality Slots. Upon gaining this '
            'effect, select an additional qualifying Weapon Quality that '
            'occupies 1 Quality Slot for each Installed Weapon and apply it to '
            'that Weapon.\n'
            'Power Absorption [Triggered]: If you hit an Opponent with an '
            'Attacking Maneuver of the Physical Foundation, they lose 1(bT) Ki '
            'Points and you regain Ki Points equal to the amount they lost.\n'
            'Hyper Resilience [Passive]: Increase your Soak Value by 2(T) while '
            'you are in the Healthy Health Threshold.\n'
            'Enhanced Reflexes [Passive]: Increase your Defense Value by 1(T) '
            'while you are in the Healthy Health Threshold.\n'
            'Weapon Style [Passive]: Increase the Strike and Wound Rolls of '
            'your Armed Attacks by 1(T).\n'
            'Heroic Style [Passive]: While you are Hyped, increase your Damage '
            'Reduction by 1(T).\n'
            'Calculating Style [Passive]: While you possess at least 1 '
            'Analyzed Opponent, increase your Damage Reduction by 1(T).\n'
            'Alternate Scale Structure [Passive]: If you selected the Tiny Size '
            'Category through Alternate Scale Structure, increase your Defense '
            'Value by 1(bT). If you selected the Enormous Size Category through '
            'Alternate Scale Structure, increase your Soak Value by 1(bT).\n'
            'Extension Feature [Passive]: Increase the Strike Rolls of your '
            'Physical Attacks by 1(T).\n'
            'Magical Machine [Passive]: Reduce the Ki Point Cost of your Magic '
            'Attacks and Magical Unique Abilities by 1(T).',
        // (1) select Agility or Tenacity → +1 flat AMB of it.
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'AMB Attribute',
            options: kAmbPickAgTeFlat1,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Inner Purpose',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Functional Purpose Racial Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: "Android's Journey",
        description: 'You have discovered, in addition to the purpose you '
            'were created for, a purpose all your own.\n'
            '(1)-[Passive]: Increase your Maximum Ki Points by 2 for each '
            'Power Level reached.\n'
            '(2)-[Passive]: Choose and gain an additional effect from the '
            'Option effect of Functional Purpose.\n'
            '(3)-[Choice]: Per your Functional Purpose choice(s): Destroyer '
            '— +1(T) Wound Rolls; Protector — +1(T) Soak Value; Companion — '
            '+1(T) Personality Modifier; Researcher — +1(T) Scholarship '
            "Modifier; Leader — +1(T) Wound Rolls and Soak Value to your "
            'Minions.',
        automation: [
          // (1) +2 Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),

  // =============================================================== ANGEL ===
  TransformationDef(
    name: 'Angelic Tutor',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Watchful Gaze Talent',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'We Were Angels',
        description: 'You continue to help your peers reach the heights of '
            'skill and power through your unending tutelage.\n'
            '(1)-[Triggered, 1/Round, Resource]: If you spend a Counter '
            'Action (except a Defend Maneuver), gain a stack of Proud '
            'Guidance (max 3).\n'
            '(2)-[Passive]: Increase the AoE of your Guidance Range by 1 '
            'Magnitude.\n'
            '(3)-[Passive]: Increase the Strike and Wound Rolls of all '
            'Allies within your Guidance Range by 1(T).\n'
            '(4)-[Passive]: The 2nd effect of Angelic Guidance loses the '
            '[1/Round] Keyword.\n'
            '(5)-[Triggered]: If you would spend Counter Action(s), you may '
            'spend Proud Guidance stack(s) instead.\n'
            '(6)-[Triggered, 1/Round]: If an Ally within your Guidance Range '
            'takes Damage from an Attacking Maneuver, spend any number of '
            'Counter Actions; each reduces the Damage by 2(T).\n'
            '(7)-[1/Encounter]: As an Instant Maneuver, target an Ally '
            'within Guidance Range; they use a Surge of their choice '
            'Out-of-Sequence (counts as your Surge Maneuver).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Divine Attendant',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
    },
    traits: [
      TransformationTrait(
        name: 'Observe and Support',
        description: 'Standing on the sidelines, you assist your friends not '
            'by fighting, but with tips, warnings, and strategies provided '
            'at crucial junctures.\n'
            '(1)-[Passive]: Double the bonuses from the 6th effect of '
            'Discarded Divinity.\n'
            '(2)-[Passive]: Increase the Natural Results of any Combat Rolls '
            'made by the Character you targeted for the 1st effect of the '
            'Spectator State.\n'
            '(3)-[Triggered]: If an Ally uses a Counter Maneuver, they may '
            'spend your Counter Actions instead of their own.\n'
            '(4)-[Triggered, 1/Round]: If an Ally must use Saving Throws or '
            'a Skill for a Clash initiated by an Opponent, spend a Counter '
            'Action to roll your relevant Save/Skill in their stead (if '
            'willing); they remain the target and suffer effects if you '
            'fail.\n'
            '(5)-[Triggered/Spectator]: Gain 1 Counter Action.\n'
            '(6)-[Triggered/Start of Combat Round]: If in the Spectator '
            'State, gain 1 Counter Action.\n'
            '(7)-[Triggered, 1/Encounter]: If an Ally receives Damage that '
            'would reduce their Life to its lowest value, spend any number '
            'of Counter Actions; each reduces that Damage by your Insight '
            'Modifier.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Untouched Angel',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Perfectionist Combat',
        description: "You don't just intend to win, you intend to win "
            'PERFECTLY, without a scratch on you.\n'
            '(1)-[Passive]: While your Life Points equal your Maximum, '
            'increase your Awareness and Defense Value by 1(T).\n'
            '(2)-[Passive]: While at Maximum Life, you are treated as having '
            'no Counter Actions for your effects when you possess no more '
            'than 1 Counter Action.\n'
            '(3)-[Passive]: While at Maximum Life, increase your Might and '
            'Saving Throws by 1(T) for Clashes using them initiated by an '
            'Opponent.\n'
            '(4)-[Triggered, 1/Round]: If targeted by an Attacking Maneuver '
            'while your Life has not been reduced this Combat Round, gain no '
            'Diminishing Defence stacks from it.\n'
            '(5)-[Triggered, 1/Encounter]: If your Life is below the Injured '
            'Threshold and you use a Healing Surge, double the Life '
            'regained.',
      ),
    ],
  ),

  // ============================================================ ARCOSIAN ===
  TransformationDef(
    name: 'Evolving Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Evolving Class',
        description: 'Your specialized fighting style has shown you a new '
            'kind of evolution to unlock.\n'
            '(1)-[Passive]: While your Life Points are below 0, increase '
            'your Surgency by 2(T).\n'
            '(2)-[Triggered, 1/Round]: If you use a Signature Technique with '
            '2+ stacks of Overwhelm, apply an Energy Charge to it.\n'
            '(3)-[Choice]: Per your Class Selection Option, your Plating '
            'gains a Class Scales Quality: Hero — Heroic Scales (+1(T) '
            'Strike/Dodge with 2+ Overwhelm); Elite — Noble Scales (+3(T) '
            'Surgency with 2+ Overwhelm); Berserker — Destructive Scales '
            '(+2(T) Wound Rolls with 2+ Overwhelm).\n'
            '(4)-[Choice]: Per your Class Selection Option: Hero — [Power, '
            '1/Encounter] maximize Overwhelm stacks; Elite — [1/Encounter] '
            'if you Surge, spend Overwhelm stacks to regain 2(bT) Life+Ki '
            'each; Berserker — [1/Encounter] if you attack via the Berserker '
            'Choice, double the Wound bonus from Overwhelm for that attack.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Natural Evolution',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Growth and Evolution',
        description: "You've adapted to overcome a significant challenge, "
            'increasing your effectiveness.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select an Evolution '
            'Trait; you gain access to it.\n'
            "(2)-[Passive]: Increase your Surgency by 1/2 (rounded up) of "
            "your Plating's Apparel Bonus.\n"
            '(3)-[Passive]: Increase the Life and Ki regained from Legend '
            'Realized by 1/2 of your Surgency.\n'
            '(4)-[1/Encounter]: As an Instant Maneuver, apply the effects of '
            'Legend Realized.\n'
            '(5)-[Triggered, 1/Round]: If you use Legend Realized, use the '
            'Power Up Maneuver as an Out-of-Sequence Maneuver.',
      ),
    ],
  ),

  // ========================================================== BIO-ANDROID ===
  TransformationDef(
    name: 'Bio-Diversity',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Bio-Android',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: '2+ Factor Traits from Genetic Splicing',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Genetic Smoothie',
        description: 'The slurry of genetic codes that comprises your being '
            'grants you a myriad of different abilities.\n'
            '(1)-[Passive]: Each time you gain a stack of this Awakening, '
            'select and gain access to a Factor Trait from the Genetic '
            'Splicing Factor.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Understanding of Perfection',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Bio-Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '1+ stack of Perfection that is not a Temporary '
        'Awakening',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Perfect Reflection',
        description: '(1)-[Passive]: Upon gaining this Awakening, select and '
            'gain access to 2 Perfect Traits.\n'
            '(2)-[Choice]: Per your Artificial Warrior 4th-effect choice: '
            'Genetic Survivor — +1(T) Soak/Surgency, +1 AMB (TE); Genetic '
            'Aggressor — +1(T) Strike, +1 AMB (FO/MA); Genetic Agility — '
            '+1(T) Dodge, +1 AMB (AG); Pursuit of Perfection — select a '
            'Combat Roll and an Attribute (except FO/MA): +1(T) to it and '
            '+1 AMB to that Attribute (if Wound Rolls, also +1(T) Corporeal '
            'Save).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Stable Clone',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Bio-Android',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Unstable Clone Factor',
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Perfect Clone',
        description: '(1)-[Passive]: Increase your Racial Life Modifier by '
            '2.\n'
            '(2)-[Passive]: Regain the Racial Trait you traded out for the '
            'Bio-Berserker Factor.',
        automation: [
          // (1) +2 Racial Life Modifier = +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
  ),

  // =========================================================== CEREALIAN ===
  TransformationDef(
    name: 'Ocular Acclimation',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Precision Charge',
        description: 'As you take the time to build your power and patiently '
            'ensure the best shot, you build your energy, making the shot '
            'both accurate and deadly.\n'
            '(1)-[Passive]: Ignore the Strike Roll reduction from Called '
            'Shot if that Attacking Maneuver has 3+ Energy Charges applied '
            'via the Energy Charge Maneuver.\n'
            '(2)-[Triggered, 1/Round]: If you target a Character with a '
            'Called Shot, make a Skill Clash (Perception vs '
            'Bluff/Stealth/Perception); if you win, +1(T) Strike and +2(T) '
            'Wound for that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If targeted by an Attacking Maneuver, '
            'make a Skill Clash (Perception vs Bluff/Stealth/Perception) vs '
            'the attacker; if you win, +1(T) Defense and +2(T) Soak vs it.\n'
            '(4)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
            'with 3+ Energy Charges, apply the Called Shot Modifier Maneuver '
            'to it without the Action Cost; if it deals Damage, gain a stack '
            'of Critical Eye.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of Cereal',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Cerealian Race or Cerealian-Raised Factor Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Sharp Sight of Cereal',
        description: 'Trained by the sharpshooter Cerealians, your keen eye '
            'ensures no one escapes your attacks.\n'
            '(1)-[Passive]: While it is not your turn, increase your Strike '
            'Rolls by 1(T).\n'
            '(2)-[Passive]: While it is not your turn, reduce the Ki Point '
            'Cost of all your Attacking Maneuvers by 1(T).\n'
            '(3)-[Passive]: The Power Up Maneuver triggers an Exploit from '
            'you if you or an Ally is next to the Character who used it.\n'
            '(4)-[Triggered, 1/Round]: If you knock an Opponent through a '
            'Health Threshold on their turn, instead of gaining an Action '
            'via Bonus Momentum, you may remove an Action from that '
            'Opponent.\n'
            '(5)-[Triggered, 1/Encounter]: If you attack through the Exploit '
            'Maneuver, apply the Called Shot Modifier Maneuver without its '
            'Action Cost.',
      ),
    ],
  ),

  // ============================================================== DEMON ===
  TransformationDef(
    name: 'Demonic Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening, Demon Clansman Factor',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Demonic Class',
        description: 'Like the shrewd, cunning demon you are, you '
            'incorporate underhanded tactics into your chosen '
            'specialization.\n'
            '(1)-[Passive]: Increase Combat Rolls made against Characters '
            'suffering from a Combat Condition by 1(T).\n'
            '(2)-[Triggered, 1/Round]: If you deal Damage to an Opponent, '
            'make a Might Clash; if you win, they gain the Drained Combat '
            'Condition until the start of your next turn.\n'
            '(3)-[Choice]: Per your Class Selection Option, while an Opponent '
            'has a Combat Condition: Hero — +1(T) Soak; Elite — +1(T) '
            'Surgency; Berserker — +1(T) Wound Rolls.\n'
            '(4)-[Choice]: Per your Class Selection Option, powerful '
            'Combat-Condition effects (Hero — mass Impaired; Elite — pass a '
            "Condition to an adjacent Opponent on Surge; Berserker — Drained "
            'on Damage). See the site for full text.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Demonic Wager',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Demon',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Life or Death Gamble',
        description: 'The stakes have never been higher; which makes your '
            'gamble for power all the sweeter.\n'
            '(1)-[Passive]: While you possess 2+ stacks of Demonic Power, '
            'increase your Soak Value and Surgency by 1(T).\n'
            '(2)-[Passive]: While you possess 2+ stacks of Demonic Fatigue, '
            'reduce the Dice Score of your Steadfast Checks by 1.\n'
            '(3)-[Triggered/Defeated]: Make a Pressure Check. If you '
            'succeed, regain Life up to 1/4 (rounded up) of Max and enter '
            'the Superior State until the end of your next turn. If you '
            'fail, die.\n'
            '(4)-[Triggered/Power, 1/Round]: If you possess 2+ stacks of '
            'Demonic Power, make a Pressure Check; if you succeed, gain an '
            'additional Power stack from this Power Up.\n'
            "(5)-[Triggered/Start of Turn, Ruling, 1/Encounter]: Declare "
            "you're 'Feeling Lucky' until the start of your next turn; while "
            'Feeling Lucky, you may reroll any Pressure Check (accept the '
            'second result).',
        automation: [
          // (1) While 2+ tracked 'Demonic Power' Resource stacks: +1(T)
          // Soak Value and Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Demonic Power',
            conditionAmount: 2,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Makyo Star',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Demon',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Makyo Subrace',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Power of the Homeworld',
        description: 'The Makyo Star approaches, heralding an auspicious '
            'moment for you in your fight.\n'
            '(1)-[Passive]: Increase your Might by 1(T).\n'
            '(2)-[Passive]: While you possess 3+ stacks of Demonic Power, '
            'increase your Tier of Power by 1 (see Breakthrough).\n'
            '(3)-[Passive]: While you possess 3+ stacks of Demonic Fatigue, '
            'increase the Damage Category of all Attacking Maneuvers that '
            'target you by 1 Category for your damage calculation.\n'
            '(4)-[Triggered/Power, 1/Round]: Make a Pressure Check; if you '
            'succeed, make a Might Clash vs all Opponents in a Sphere AoE '
            '(centered on you); if you win, they gain a stack of Shaken and '
            'Broken until the start of your next turn.',
        automation: [
          // (1) +1(T) Might.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of the Demon Realm',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Demon Race or Demon-Raised Factor Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Brutality of the Demon Realm',
        description: 'Your cruel cunning has been honed under the tutelage '
            "of the Demon Realm's greatest minds.\n"
            '(1)-[Passive]: Increase your Soak and Defense Value by 1(T) for '
            'the duration of Attacking Maneuvers made by Characters '
            'suffering from a Combat Condition.\n'
            '(2)-[Passive]: Combat Conditions you inflict via Racial/Factor '
            'Traits that would end at the end of your turn instead last '
            'until the start of your next turn.\n'
            '(3)-[Triggered, 1/Round]: If you inflict the Impediment Combat '
            'Condition on an Opponent, reduce their Life Points by 1/2 of '
            'your Might.\n'
            '(4)-[Triggered/Power, 1/Encounter]: Increase your Might and '
            'Cognitive Save by 2(T) until the end of your turn.',
      ),
    ],
  ),

  // ============================================================ EARTHLING ===
  TransformationDef(
    name: 'Desperate Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Last Resort Racial Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Secret Reserve',
        description: 'When the stakes are high and the chips are down, you '
            'manage to pull out a wellspring of power born of sheer audacity '
            'and the stubborn refusal to die.\n'
            '(1)-[Passive]: While below the Injured Health Threshold, '
            'increase the Wound Roll bonus from the 1st effect of Earthling '
            'Resolve by 1(T).\n'
            '(2)-[Triggered]: Any Signature Technique used through the 2nd '
            'effect of Last Resort gains the Full Wager Advantage and the '
            'All Out Super Profile.\n'
            '(3)-[Triggered/Injured]: Use a Ki Surge as an Out-of-Sequence '
            'Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If hit by an Attacking Maneuver '
            'while above the Injured Threshold, the Damage is instead set to '
            'the amount that would reduce your Life to 1; you automatically '
            'succeed any resulting Steadfast Check.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Dragon Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Eye of the Dragon Racial Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Path of the Dragon',
        description: "Through constant hard work, you've sharpened your "
            'skills and become the epitome of technical mastery.\n'
            '(1)-[Passive]: Upon gaining this Awakening, select and gain an '
            'additional effect from the 3rd effect of Quick to Master.\n'
            '(2)-[Passive]: Increase the Technique Points gained from Skill '
            'Improvement by 2 (retroactive: +2 TP per Skill Improvement you '
            'have).\n'
            '(3)-[Triggered]: The first time each Combat Encounter you use '
            'each Signature Technique, you do not pay its Ki Point Cost '
            '(Capacity still reduces as if paid).\n'
            '(4)-[Triggered, 1/Encounter]: When you Energy Charge below the '
            'Injured Threshold, gain an additional Energy Charge.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Seasoned Warrior',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Experienced Fighter Racial Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Gathered Experience',
        description: 'You possess a vast wealth of combat knowledge and '
            'experience, allowing you to predict opponents and punish their '
            'mistakes, overcoming otherwise insurmountable foes.\n'
            '(1)-[Passive]: Increase Life and Ki regained through Combat '
            'Recovery by 1d6(bT).\n'
            '(2)-[Passive]: Reduce the Ki Points spent through the 2nd '
            'effect of Experienced Fighter by 1(T).\n'
            '(3)-[Passive]: Per your Experienced Fighter 2nd-effect choice: '
            'Exploitation Strike — +1(T) Strike bonus; Instinct-Driven Dodge '
            '— +1(T) Dodge bonus; Punishing Blow — +2(T) Wound bonus.\n'
            '(4)-[Triggered, 1/Encounter]: When you target an Opponent via '
            'Experienced Fighter below the Injured Threshold, apply all '
            'listed effects instead of one.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of Earth',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Earthling Race or Earthling-Raised Factor Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Techniques of Earth',
        description: 'Your versatile techniques and instant adaptations make '
            'you a powerful fighter, despite others constantly '
            'underestimating you.\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of your Signature '
            'Techniques by 1(T).\n'
            '(2)-[Passive]: Increase the Wound Rolls of your Signature '
            'Techniques that gained 1+ Advantage via your Traits by 2(T).\n'
            '(3)-[Passive]: Increase the Strike Rolls of your Signature '
            'Techniques that gained 1+ Energy Charge via your Traits by '
            '1(T).\n'
            '(4)-[Triggered/Defeated]: Use the Signature Technique Maneuver '
            'Out-of-Sequence; it becomes an Ultimate Signature Technique '
            'and gains the Last Legs Advantage and All Out Super Profile.',
      ),
    ],
  ),

  // ========================================================= GLASS TRIBE ===
  TransformationDef(
    name: 'Stained Heart',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Glass Tribe',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Beautiful Reflection',
        description: 'You are always at your beloved partner\'s side, even '
            'when you are far away.\n'
            '(1)-[Passive, Ruling]: Upon gaining this Transformation, select '
            "a Character; they become your 'Beloved Reflection'.\n"
            '(2)-[Passive]: Increase your Morale Saves by 1(T) while in a '
            'Combat Encounter with your Beloved Reflection as an Ally.\n'
            "(3)-[Passive]: Increase you and your Beloved Reflection's Wound "
            'Rolls and Soak Value by 1(T) while both occupy a Square with '
            'the Glass Environmental Quality.\n'
            '(4)-[1/Round]: As an Instant Maneuver (your turn or your '
            "Beloved Reflection's), move to any Glass Square adjacent to "
            'your Beloved Reflection.\n'
            '(5)-[Triggered, 1/Encounter]: If your Beloved Reflection is '
            'Defeated or knocked through the Critical Threshold by an '
            'Opponent, enter the Surging State until the end of your next '
            'turn (target that Opponent).\n'
            '(6)-[Triggered/Start of Combat Round]: If your Beloved '
            'Reflection is on a non-Glass Square, apply the Glass '
            'Environmental Quality to all Squares within a Minor Sphere AoE '
            'centered on them.',
      ),
    ],
  ),

  // =============================================================== HERAN ===
  TransformationDef(
    name: 'Battle Brigand',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Heran',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: '2+ Teamwork Talents',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Pirate Gang',
        description: "You and your merry band of ne'er-do-wells are "
            'extremely adept at working together.\n'
            '(1)-[Passive]: Increase your Combat Rolls by 1(T) against '
            'Opponents adjacent to at least one of your Allies.\n'
            '(2)-[Passive]: Increase the Wound Rolls of adjacent Allies by '
            '1(T).\n'
            '(3)-[Triggered]: If an Ally (not at Long Range) is hit by an '
            'Opponent, this triggers your Exploit Maneuver against that '
            'Opponent.\n'
            '(4)-[Triggered, 1/Round]: If you trigger the 2nd effect of '
            'Brigand Combat, gain a stack of Greed.\n'
            '(5)-[Triggered, 1/Round]: If you use an Attacking Maneuver with '
            'an AoE, you may choose not to target Allies inside it.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Heran Style',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Heran',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Techniques of Hera',
        description: 'Your cutthroat tactics and underhanded shenanigans '
            'have been passed down directly from your forebears.\n'
            '(1)-[Passive]: Increase Technique Points gained from Skill '
            'Improvement by 3 (retroactive: +3 TP per Skill Improvement you '
            'have).\n'
            '(2-5)-[Choice]: Per your Brigand Combat 3rd-effect choice — '
            'Riches of Might: +1 AMB (TE), +1(T) Wound Rolls, −1(T) Ki Cost '
            'of Signature Techniques, [1/Encounter] spend up to 2 Greed for '
            'Energy Charges. Riches of Mysticism: +1 AMB (IN), +1(T) Might, '
            '−2(T) Ki Cost of Unique Abilities, [1/Encounter] spend 2 Greed '
            'to reduce a Unique Ability\'s Action Cost.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Lone Buccaneer',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Heran',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Lone Warrior Awakening',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Alone at Last',
        description: 'Just how you like it.\n'
            '(1)-[Passive]: While in a Desperate Battle: +1(T) Soak and '
            'Wound Rolls; your Opponents are always considered adjacent to '
            'an Ally for the 1st effect of Brigand Combat; for the 2nd '
            'effect of Brigand Combat, if you have no Allies (or all are '
            'Defeated) you may select yourself as if targeted.\n'
            '(2)-[Triggered/Power, 1/Round]: If below the Injured Threshold, '
            'you are considered in a Desperate Battle until the start of '
            'your next turn.\n'
            '(3)-[Triggered, 1/Encounter]: If you trigger the 4th effect of '
            'Mind Power ~ Ki, use the Basic Attack or Signature Technique '
            'Maneuver Out-of-Sequence immediately after.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of Hera',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Heran Race or Heran-Raised Factor Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Camaraderie of Hera',
        description: "Thanks to your studies of tactics with Hera's greatest "
            'warriors, you understand that the most effective means of '
            "winning a battle isn't always the friendliest. What are "
            'Allies, if not pawns, after all?\n'
            '(1)-[Passive]: Increase the Wound Rolls of Attacking Maneuvers '
            'that target an Opponent adjacent to at least 1 of your Allies '
            'by 1(T).\n'
            '(2)-[Passive]: Increase your Dodge Rolls against Opponents '
            'adjacent to at least 1 of your Allies by 1(T).\n'
            '(3)-[Triggered, 1/Round]: If you deal Damage to an Opponent, '
            'move them to any unoccupied Square within a Huge Sphere AoE '
            '(no blocking, no Collision Damage).\n'
            '(4)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
            'with an AoE, you may choose not to target Allies caught in it.',
      ),
    ],
  ),

  // =========================================================== KONATSIAN ===
  TransformationDef(
    name: 'Sworn Comrades',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Konatsian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Shared Tension',
        description: 'Thanks to your bond with your team, you know when the '
            "stakes are high and the chips are down, they'll have your "
            'back.\n'
            '(1)-[Passive]: While you have 3+ stacks of Tension, increase '
            'your Soak Value by 1(T).\n'
            '(2)-[Passive]: While you have 3+ stacks of Tension, increase '
            'the Defense Value of you and Allies within a Large Sphere AoE '
            'by 1(T).\n'
            '(3)-[1/Round]: Use the Intervene Maneuver without spending a '
            'Counter Action.\n'
            '(4)-[Triggered/Threshold]: If knocked through this Health '
            'Threshold by an Attacking Maneuver you Intervened against, gain '
            'an additional stack of Tension.\n'
            '(5)-[Triggered, 1/Encounter]: If an Ally is Defeated, spend up '
            'to 3 Tension; that Ally uses a Healing Surge and applies their '
            'Surgency an additional time per Tension spent.',
        automation: [
          // (1) While 3+ tracked 'Tension' Resource stacks: +1(T) Soak.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Tension',
            conditionAmount: 3,
          ),
          // (2) While 3+ Tension: +1(T) own Defense Value (the Ally share is
          // manual).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Tension',
            conditionAmount: 3,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Vocation Gain',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: 'Konatsian Race or Konatsian-Raised Factor Trait',
    // Special: each stack applies its own AMB based on the Vocation chosen
    // for it (see the Additional Vocation trait note), so no flat AMB here.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Additional Vocation',
        description: "You've taken on additional training, learning to wield "
            'the skills of another role besides your original training.\n'
            '(1)-[Passive, Ruling]: Each time you gain a stack, select a '
            "Vocation you do not possess (your 'Extra Vocations'); outside a "
            'Combat Encounter you have access to all of them.\n'
            '(2)-[Addendum]: Vocation AMB — each stack applies its own AMB '
            'by chosen Vocation: Warrior +1 FO/TE/MA; Mage +1 IN/MA; Martial '
            'Artist +1 AG/FO; Priest +1 IN/MA; Thief +1 AG/IN; Ranger +2 AG; '
            'Dancer +2 PE; Gadabout +1 to a chosen Attribute and +1 to a '
            'random one.\n'
            '(3)-[Passive]: Each time you gain a stack, gain 1 Attribute '
            'Point (spend immediately) and 5 Technique Points.\n'
            '(4)-[Passive]: Increase your Maximum Life Points by 1/2 of Z '
            '(rounded up) for each Power Level reached.\n'
            '(5)-[Triggered/Start of Turn]: Select and gain access to one of '
            'your Extra Vocations (max 1 accessible at a time in combat; may '
            'swap).',
      ),
    ],
  ),

  // =============================================================== MAJIN ===
  TransformationDef(
    name: 'Super Regeneration',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 1,
    maxStacks: 2,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Untiring',
        description: 'You cannot be defeated by ordinary means; your '
            'existence is eternal.\n'
            '(1)-[Passive]: Traits, Maneuvers or effects used by other '
            'Characters cannot reduce or spend your Ki Points.\n'
            '(2)-[Passive]: Increase your Surgency by Z(T).\n'
            '(3)-[Triggered, 1/Round]: If you use a Healing Surge, regain Ki '
            'Points equal to 1/2 of your Surgency.\n'
            '(4)-[Triggered/Start of Turn]: Regain Z(bT) Life and Ki '
            'Points.',
        automation: [
          // (2) +Z(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationStack: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Unending',
        minStacks: 2,
        description: 'You are impossible to destroy, and similarly '
            'impossible to exhaust.\n'
            '(1)-[Passive]: You may use a [Triggered/Defeated] effect an '
            'additional time per Combat Encounter (still 1/Encounter per '
            'specific effect).\n'
            '(2)-[Passive]: While in the Healthy Health Threshold, double '
            'the bonuses from the 2nd effect of Rubbery Body.\n'
            '(3)-[Triggered, 1/Encounter]: If you receive Damage from an '
            'Attacking Maneuver, you may reduce the Damage by your '
            'Surgency.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Whimsical Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Whimsical Class',
        description: 'Taking conscious control over your regenerative '
            'abilities, you link them with your chosen specialization, '
            'fundamentally altering your combat style to take advantage of '
            'that regeneration.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Increase your Soak and Defense Value by 1(T) '
            'while below the Injured Health Threshold.\n'
            '(3)-[Choice]: Per your Class Selection Option: Hero — +1(T) '
            'Surgency per Power stack (max 3(T)); Elite — +1(T) Surgency; '
            'Berserker — +1/4 Surgency to Wound Rolls of Class Up attacks.\n'
            '(4)-[Choice]: Per your Class Selection Option, on a Healing '
            'Surge: Hero — Power Up Out-of-Sequence; Elite — regain Ki = '
            "Surge Dice Score; Berserker — Basic Attack Out-of-Sequence.",
        automation: [
          // (1) +2 Racial Life Modifier = +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) While below the Injured Health Threshold: +1(T) Soak and
          // Defense Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
  ),

  // ============================================================ NAMEKIAN ===
  TransformationDef(
    name: 'Dragon Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Draconic Class',
        description: 'Your keen strategic mind, when combined with your '
            'specialization, makes you a formidable opponent.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: Increase your Wound Rolls by 1(T) while you have '
            'a Studied Opponent.\n'
            '(3)-[Passive]: Increase your Soak Value by 1(T) while you have '
            'a Studied Ally.\n'
            '(4)-[Choice]: Per your Class Selection Option, your Studied '
            'Allies gain: Hero — +1(T) Soak; Elite — +2(T) Surgency; '
            'Berserker — +1(T) Wound Rolls.\n'
            '(5)-[Choice]: Per your Class Selection Option: Hero — '
            '[Power, 1/Encounter] +1/4 Surgency to Combat Rolls; Elite — '
            '[1/Encounter] apply Surgency again on a Surge; Berserker — '
            '[1/Encounter] +1/2 Surgency to Wound of a Berserker-Choice '
            'attack.',
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Namekian Prodigy',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Super Namekian Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Beyond the Clan',
        description: 'You have grown beyond the definition of the '
            'traditional clan structure of your people.\n'
            '(1)-[Passive]: While below the Bruised Health Threshold, '
            'increase your Surgency by 1(T).\n'
            '(2)-[Passive]: Per Subrace: Warrior Clan — +1(T) Soak and Wound '
            'Rolls to Studied Allies; Dragon Clan — +1(T) Soak and Wound '
            'Rolls vs Studied Opponents.\n'
            '(3)-[Passive]: Upon gaining this Transformation, per Subrace: '
            'Warrior Clan — gain an effect from Spirit of Namek 4th effect; '
            'Dragon Clan — gain an effect from Refined Combat 3rd effect.\n'
            '(4)-[Triggered, 1/Encounter]: If you succeed at a Steadfast '
            'Check, use a Ki Surge as an Out-of-Sequence Maneuver.',
        automation: [
          // (1) While below the Bruised Health Threshold: +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowBruisedThreshold,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Son of Namek',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Namekian Techniques Racial Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Honored Training',
        description: 'You respect yourself both in mind and body, striving '
            'to keep yourself in tip-top shape. While you are in control of '
            'the battlefield, you are powerful.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: Increase your Strike Rolls against Studied '
            'Opponents by 1(T).\n'
            '(3)-[Passive]: Increase the TP gained from the 3rd effect of '
            'Namekian Techniques from 3 to 5 (retroactive).\n'
            '(4)-[Triggered]: If you attack through the 4th effect of '
            'Namekian Techniques, +2(T) Wound Roll to that attack.\n'
            '(5)-[Triggered]: If an Opponent becomes Studied via Namekian '
            'Techniques 4th effect, select an additional Opponent to become '
            'Studied until the end of the Combat Round.\n'
            '(6)-[Triggered/Start of Combat Round, 1/Encounter]: Use the '
            'Power Up Maneuver as an Out-of-Sequence Maneuver.',
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of Namek',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Namekian Race or Namekian-Raised Factor Trait',
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Wisdom of Namek',
        description: "With the training of Namek's greatest sages, you have "
            'become a force to be reckoned with.\n'
            '(1)-[Passive]: Increase your Surgency by 2(T).\n'
            '(2)-[Triggered, 1/Round]: If you and/or an Ally are targeted by '
            'an Opponent, make a Clash (Perception/Clairvoyance vs '
            'Stealth/Concealment) vs the attacker; if you win, −2(T) Strike '
            'and Wound for that attack.\n'
            '(3)-[Triggered, 1/Round]: If you target an Opponent with a '
            'Racial/Factor Trait effect at the start/end of the Combat '
            'Round, use the Basic Attack Maneuver Out-of-Sequence targeting '
            'them.\n'
            '(4)-[Triggered/Defeated]: Use a Healing Surge with doubled '
            'Surgency for its duration.',
        automation: [
          // (1) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),

  // =========================================================== NEKO MAJIN ===
  TransformationDef(
    name: 'Rabbit Hoard',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Neko Majin',
    tierOfPowerRequirement: 1,
    maxStacks: 7,
    prerequisiteText: 'Usagi Majin Factor',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Dama Collection',
        description: '(1)-[Passive]: Increase the maximum number of Active '
            'Majin Dama you may possess through the 4th effect of Greedy '
            'Rabbit by Z.\n'
            '(2)-[Passive]: Increase your Surgency by Z(bT).\n'
            '(3)-[Triggered, 1/Round]: If you use a Copied Technique, '
            'increase the Wound Roll by x(bT), where x = your Active '
            'Integrated Majin-Damas.\n'
            '(4)-[Triggered, 1/Encounter]: If you target a Sleeping Opponent '
            'with a Copied Technique, apply 1/2 of Z (min 1) Energy Charges '
            'to that attack.',
        automation: [
          // (2) +Z(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.base,
            perTransformationStack: true,
          ),
        ],
      ),
    ],
  ),

  // =========================================================== NEO-TUFFLE ===
  TransformationDef(
    name: 'Revenger Charge',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Neo-Tuffle',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Hatred Embodiment Subrace',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Endless Pool of Revenge',
        description: "The Tuffles' desires for vengeance burn brightly "
            'within you, offering you near-limitless power.\n'
            '(1)-[Passive]: Increase your Wound Rolls by 1(T).\n'
            '(2)-[Passive]: If you have used your Energy Charge Maneuver but '
            'not yet the declared Attacking Maneuver, increase your Soak '
            'Value by 2(T).\n'
            '(3)-[Triggered, 1/Round]: If you gain a Revenge Point via the '
            '3rd effect of Hate Empowerment, gain a Revenge Point.\n'
            '(4)-[Triggered, 1/Round]: If you gain a Revenge Point via the '
            '1st effect of Energy of Revenge, use the Energy Charge Maneuver '
            'Out-of-Sequence.\n'
            '(5)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
            'with your maximum Energy Charges, increase its Damage Category '
            'by 1 Category.',
        automation: [
          // (1) +1(T) Wound Rolls.
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
    ],
  ),
  TransformationDef(
    name: 'Strongest Form',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Neo-Tuffle',
    tierOfPowerRequirement: 2,
    maxStacks: 2,
    prerequisiteText: 'Parasite Subrace (3+ Tier of Power for the 2nd stack)',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Apex Adornment',
        description: "You've become the strongest life form, and your thirst "
            'for vengeance only grows.\n'
            "(1)-[Passive, Ruling]: Gain Integrated Armor (Craftsmanship 4) "
            "called the 'Golden Adornment' with the Durable, Unbreakable, "
            'Sleek, and Combat Ready Qualities.\n'
            '(2)-[Passive]: While a Possessing Character, the host (with your '
            'Overtaken instance) has an Integrated copy of your Golden '
            'Adornment (lost when you stop possessing).\n'
            '(3)-[Passive]: While a Possessing Character, increase the '
            "host's Attribute Modifiers by this Awakening's total AMB.\n"
            "(4)-[Passive]: While a Possessing Character, +Z(bT) Wound Rolls "
            "to the host's Signature Techniques.\n"
            '(5)-[Passive]: Increase Ki lost by an Opponent via Parasitic '
            'Biology 3rd effect by Z(bT).\n'
            '(6)-[Triggered]: If you reduce an Opponent\'s Ki via Parasitic '
            'Biology 3rd effect, regain Z(bT) Ki Points.',
      ),
      TransformationTrait(
        name: 'Precipice of Power',
        minStacks: 2,
        description: "With the ultimate power you've unlocked, the targets "
            'of your righteous fury will be laid to bloody rest once and for '
            'all.\n'
            '(1)-[Passive]: Increase the Craftsmanship Grade of your Golden '
            'Adornment to 5.\n'
            '(2)-[1/Round]: You (or your host if Possessing) may use the '
            'Energy Charge Maneuver as an Instant Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: If targeted by the Empower '
            'Maneuver, use a Surge of your choice Out-of-Sequence.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Tuffleization',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Neo-Tuffle',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Parasite Subrace',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Tuffle Hybrid',
        description: 'Combining your Neo-Tuffle nature with your host, you '
            'draw out more of their power.\n'
            '(1)-[Triggered, 1/Round]: If you target your Inferior with a '
            'Signature Technique, apply an Energy Charge to that attack.\n'
            '(2)-[Passive]: Increase your Wound Rolls against your Inferior '
            'by 1(T).\n'
            '(3)-[Passive]: While a Possessing Character, the host (with the '
            'Overtaken Awakening) has access to Tuffleization (ignoring '
            'Racial Requirement) as a Level 2 Temporary Awakening.\n'
            '(4)-[Passive]: With a stack of Overtaken, upon gaining this '
            'Awakening, select and gain another Primary Racial Trait from '
            'your Possessing Character (must be Tuffle Superiority if not '
            'already had).\n'
            '(5)-[Passive]: With a stack of Overtaken, gain access to the '
            'Tuffleized Form Evolved Stage for all your Forms.',
      ),
    ],
  ),

  // ============================================================== SAIYAN ===
  // (Zenkai, above, is also a Saiyan Lesser Awakening.)
  TransformationDef(
    name: 'Abundant S-Cells',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Super Saiyan Bargain Sale',
        description: 'Your ability to instantly achieve this once-legendary '
            'transformation is nothing short of miraculous, even if it seems '
            'way too easy compared to those who had to work for it.\n'
            '(1)-[Passive]: Upon gaining this Transformation, gain access to '
            'the Super Saiyan 1 Transformation.\n'
            '(2)-[Passive]: Super Saiyan 1 gains the Prelude Aspect.\n'
            '(3)-[Passive]: Increase the Dice Score of your Stress Tests to '
            'enter a Transformation with the Super Saiyan Form Aspect by '
            '1.\n'
            '(4)-[Passive]: While in a Form with the Super Saiyan Form '
            'Aspect, increase your Wound Rolls and Soak Value by 1(T).\n'
            '(5)-[Triggered, 1/Encounter]: If you Transform into a Form with '
            'the Super Saiyan Form Aspect, gain 1 Action.',
        automation: [
          // (4) While in a Form with the Super Saiyan Form Aspect: +1(T)
          // Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileFormWithAspectActive,
            conditionAspectName: 'Super Saiyan Form',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Immensely Wrathful',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Access to Wrathful Enhancement',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Concentrated Power of the Great Ape',
        description: 'You condense the power- and fury- of your inner beast '
            'into your normal form.\n'
            '(1)-[Passive]: Reduce the Stress Test Requirement of Wrathful '
            'by 2.\n'
            '(2)-[Passive]: While in Wrathful, increase your Wound Rolls and '
            'Soak Value by 1(T).\n'
            '(3)-[Triggered, 1/Round]: While in Wrathful, if you use the '
            'Direct Hit option of the Defend Maneuver, reduce the Damage '
            'Category of the attack by 1 Category for your damage '
            'calculation.\n'
            '(4)-[Triggered]: Upon attempting to enter Wrathful, it gains '
            'the Transcendent Aspect (becoming a Transcended Enhancement) '
            'and you gain its Directed Wrath Transcendent Trait (+2 Scaling '
            'Aspect levels, +1(T) AMB IN, ignore Rampaging, free Direct Hit '
            '1/Round, and a counter-attack option) until you leave/fail '
            'Wrathful.\n'
            '(5)-[Triggered, 1/Encounter]: If knocked through a Health '
            'Threshold by an attack, regain Life to 1 below that Threshold, '
            'then Transform into Wrathful Out-of-Sequence.',
        automation: [
          // (2) While in the Wrathful Enhancement: +1(T) Wound Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedTransformationActive,
            conditionTransformationName: 'Wrathful',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Ominous Saiyan',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    prerequisiteText: 'Access to Evil Saiyan Enhancement',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Evil Oppression',
        description: '(1)-[Passive]: While Evil Saiyan is Transcended and '
            'your Tier of Power is 4+, increase the Attribute Modifier Bonus '
            '(AG/TE/IN) of Evil Saiyan by 1(T).\n'
            '(2)-[Passive]: While in Evil Saiyan, increase your Wound Rolls '
            'and Soak Value by 1(T).\n'
            '(3)-[Triggered, 1/Round]: While in Evil Saiyan, if you take '
            'Damage from an Opponent, gain 2(bT) Evil Points, then spend '
            '2(bT) Evil Points to use the Basic Attack Maneuver '
            'Out-of-Sequence.\n'
            '(4)-[Triggered/Power, 1/Round]: While in Evil Saiyan, gain '
            '1(bT) Evil Points per Battle Born stack.\n'
            '(5)-[Triggered/Power, 1/Encounter]: While in Evil Saiyan with '
            '6+ Battle Born, spend 10(bT) Evil Points to enter the Surging '
            'State until the start of your next turn (ignore its 2nd '
            'effect).',
        automation: [
          // (2) While in the Evil Saiyan Enhancement: +1(T) Wound Rolls and
          // Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedTransformationActive,
            conditionTransformationName: 'Evil Saiyan',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Primal Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Primal Class',
        description: 'You direct the ferocious power of the beast within '
            'towards your chosen area of expertise.\n'
            '(1)-[Passive]: While you possess 6+ stacks of Battle Born, '
            'ignore any Health Threshold Penalties.\n'
            '(2)-[Passive]: Ignore the 3rd effect of the Undying State if '
            'you entered it via the 2nd effect of Saiyan Heritage.\n'
            '(3)-[Choice]: Per your Class Selection Option, increase the max '
            'Battle Born stacks for: Hero — Dodge Rolls; Elite — Strike '
            'Rolls; Berserker — Wound Rolls (by 1).\n'
            '(4)-[Choice]: Per your Class Selection Option: Hero — '
            '[Power, 1/Encounter] gain a Battle Born stack and enter '
            'Superior State; Elite — +1(T) Surgency per 3 Battle Born (max '
            '3(T)); Berserker — [1/Encounter] enter the Determined State for '
            'a Berserker-Choice attack.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Primal Connection',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Tailed effect chosen for the Option effect of Saiyan '
        'Heritage',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Oozaru Focus',
        description: 'You place a heavy emphasis on using your Great Ape '
            'form in combat.\n'
            '(1)-[Automatic]: If your Saiyan Heritage Option becomes '
            'Tailless, lose this Awakening; then you may gain a stack of '
            'Zenkai.\n'
            '(2)-[Passive]: Increase your Wound Rolls and Soak Value by 1(T) '
            'while in a Transformation with the Blutz Wave Aspect.\n'
            '(3)-[Passive]: Increase your Damage Reduction by 2(bT) against '
            'Called Shots targeting your Tail.\n'
            '(4)-[Passive]: If your Tier of Power is 2+: Oozaru\'s ToP '
            'Requirement becomes 2+; Oozaru gains Scaling (LV2) (except in '
            'Golden Oozaru Evolved Stage); Golden Oozaru gains Scaling '
            '(LV2).\n'
            '(5)-[Triggered]: If you enter the Golden Oozaru Evolved Stage, '
            'apply the Pinnacle Aspect to it until you leave.\n'
            '(6)-[Triggered, 1/Encounter]: If hit by an attack while in a '
            'Blutz Wave Transformation, increase your Soak Value by 1/2 of '
            'your Force Modifier for that attack.',
        automation: [
          // (2) While in a Transformation with the Blutz Wave Aspect: +1(T)
          // Wound Rolls and Soak Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileFormWithAspectActive,
            conditionAspectName: 'Blutz Wave',
          ),
        ],
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of Sadala',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: "Warrior's Pride Racial Trait or Saiyan-Raised Factor "
        'Trait',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Pride of Sadala',
        description: 'Your immense pride as a warrior prevents enemies from '
            'manipulating your mind and keeps you fighting longer and '
            'harder.\n'
            '(1)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(2)-[Passive]: Increase your Cognitive Save by 1(T) for Clashes '
            'using it initiated by another Character.\n'
            '(3)-[Passive]: While in the Superior State, if targeted by an '
            'effect with a Clash using one of your Saving Throws, you may '
            'use your Cognitive Save instead.\n'
            '(4)-[Triggered, 1/Round]: After taking Damage, if your Life is '
            'within 5(bT) of the next Health Threshold, reduce your Life to '
            '1 below it (trigger Threshold effects, ignore Reduced '
            'Momentum).\n'
            '(5)-[Triggered, 1/Encounter]: If you would leave the Superior '
            'State at the end of your turn, remain until the end of your '
            'next turn instead.\n'
            '(6)-[Triggered, 1/Encounter]: While in the Superior State, if '
            'you lose a Cognitive-Save Clash initiated by another Character, '
            'you may instead win it.',
      ),
    ],
  ),

  // ======================================================== SHADOW DRAGON ===
  TransformationDef(
    name: 'Extra Minus Energy',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Supernatural Powers',
        description: 'Your strange powers allow you to manipulate reality to '
            'even greater extremes.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Increase the maximum reduction to your Life '
            'Points from the 1st effect of Negative Ki to 10(bT).\n'
            '(3)-[Passive]: Gain an additional Option effect for Personified '
            'Dragon Ball.\n'
            '(4)-[Triggered, 1/Encounter]: If you would reduce your Life '
            'Points below a Health Threshold with one of your effects, do '
            'not suffer Reduced Momentum and use a Healing Surge '
            'Out-of-Sequence.',
        automation: [
          // (1) +2 Racial Life Modifier = +2 Max Life per Power Level.
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
    name: 'Purified Dragon',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Karmic Purification',
        description: 'Due to powerful forces of good, the darkness has been '
            'cleansed from your soul.\n'
            '(1)-[Passive]: Upon gaining this Awakening, per whether you had '
            'the Inverted Shadow Factor: If you did — gain the Secondary '
            'Racial Trait you traded to obtain the Dragon of Light Factor '
            'Trait; If you did not — gain the Inverted Shadow Factor and its '
            'Factor Trait without exchanging a Racial Trait.',
      ),
    ],
  ),

  // ============================================================= SHINJIN ===
  TransformationDef(
    name: 'Divine Overseer',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 2,
    maxStacks: 1,
    amb: {
      DbuAttribute.scholarship: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
      DbuAttribute.personality: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Watcher of Millenia',
        description: 'Patiently, you spend your eons watching over the '
            'mortal realm.\n'
            '(1)-[Triggered, 1/Encounter]: If you spend only 1 Action to use '
            'Combat Recovery, it does not trigger the Exploit Maneuver.\n'
            '(2)-[Passive]: Increase Life and Ki regained through Combat '
            'Recovery by 1d10(bT).\n'
            '(3)-[Passive]: Increase the Skill Bonus for all your Skills by '
            '1.\n'
            '(4)-[Choice]: Depending on your choice for the Option effect of '
            'Divine Magic, gain the following effect:\n'
            'God of Peace [Passive]: Increase your Strike Rolls by 1(T) while '
            'in the Mindful State.\n'
            'God of Judgment [Passive]: Increase the Strike Rolls of your '
            'Attacking Maneuvers with 1+ Energy Charges by 1(T).\n'
            'God of Power [Passive]: Increase your Strike Rolls by 1(T) when '
            'using an Attacking Maneuver that uses Force as your Damage '
            'Attribute.\n'
            'God of Survival [Passive]: You may use the Surge Maneuver an '
            'additional time per Combat Encounter.\n'
            'God of Wisdom [Passive]: Increase your Soak Value and Surgency by '
            '1/4 (rounded up) of your Scholarship or Personality Modifier '
            '(whichever is higher).\n'
            'God of War [Passive]: Increase the Wound Rolls of your Armed '
            'Attacks by 2(T).\n'
            'God of Magic [Passive]: Increase the Wound Rolls of your Magic '
            'Attacks by 2(T).\n'
            'God of Many [Triggered, 1/Encounter]: If your Minion(s) would be '
            'Defeated by an Attacking Maneuver or Special Maneuver, they are '
            'not Defeated. Instead, set their Life Points to 1.\n'
            'God of Time [Triggered, 1/Encounter]: If you use the Time Freeze '
            'Unique Ability, gain an additional Action through the effects of '
            'the Time Freeze Unique Ability.\n'
            'God of an Element [Triggered, 1/Round]: If you use an Attacking '
            'Maneuver that possesses the Profile you selected to be a Favored '
            'Element through the effect of God of an Element, increase the '
            'Damage Category of that Attacking Maneuver by 1 Category. If that '
            'Attacking Maneuver was already Lethal, increase the Wound Roll by '
            '2(T) instead.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Katchin Combat',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 3,
    maxStacks: 1,
    prerequisiteText: 'World Forging Unique Ability and its Advanced Creation '
        'Advancement',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 2),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'God of Creation',
        description: '(1)-[Passive]: Treat the number of Difficulty '
            'Categories beyond Qualified you exceed as 1 more for World '
            'Forging (can exceed Grandmaster).\n'
            '(2)-[Passive]: While at your base Tier of Power or higher, '
            'increase the maximum Hardness Rank of your created Features to '
            '5. Also increase the Skill Bonus of your Use Magic Skill by '
            '1.\n'
            '(3)-[Passive]: Reduce the Ki Point Cost of the Telekinesis, '
            'Magical Materialization, and World Forging Unique Abilities by '
            '1(T).\n'
            '(4)-[Triggered]: If you create a Feature via World Forging, '
            'spend a Counter Action to increase its Life Points by 1/2 of '
            'your base Tier of Power.\n'
            '(5)-[Triggered, 1/Round]: If you create a Feature via World '
            'Forging, spend a Counter Action to use the Telekinesis Unique '
            'Ability as an Instant Maneuver targeting that Feature.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Otherworldly Class Up',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Class Up Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Class of the Watcher',
        description: 'Thanks to your observant nature, you have honed your '
            "chosen specialization to a razor's edge.\n"
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: Increase Life and Ki regained from Combat '
            'Recovery by 2(bT).\n'
            '(3)-[Choice]: Per your Class Selection Option: Hero — +1(T) '
            'Soak during any Maneuver you Counter; Elite — regain 2(bT) Ki '
            'on a Counter Maneuver; Berserker — +2(T) Wound Rolls during '
            'your Counter Maneuvers.\n'
            '(4)-[Choice]: Per your Class Selection Option: Hero — '
            '[Power, 1/Encounter] gain 1 Counter Action; Elite — '
            '[1/Encounter] gain 1 Counter Action on a Surge; Berserker — '
            '[1/Encounter] spend 1 Counter Action for a Basic Attack as an '
            'Instant Maneuver (counts as a Counter Maneuver).',
      ),
    ],
  ),
  TransformationDef(
    name: 'Warrior of the Core World',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Shinjin Race or Shinjin-Raised Factor Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Reactionary Warrior',
        description: 'In combat, you patiently wait for openings while your '
            'enemies tire themselves out.\n'
            '(1)-[Passive]: While you possess 3+ Counter Actions, increase '
            'all your Combat Rolls and Soak Value by 1(T).\n'
            '(2)-[Passive]: While you possess 3+ Counter Actions, increase '
            'your Saving Throws by 1(T).\n'
            '(3)-[Triggered/Start of Turn]: If you only possess 1 Action, '
            'spend it to use a Surge of your choice Out-of-Sequence.\n'
            '(4)-[Triggered/Start of Turn]: If you possess no Actions, '
            'target an Opponent within Melee Range and make a Clash '
            '(Cognitive/Morale); if you win, they gain the Impediment '
            'Combat Condition until the start of your next turn.',
      ),
    ],
  ),

  // ============================================================= YARDRAT ===
  TransformationDef(
    name: 'Warrior of Yardrat',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Yardrat Race or Yardrat-Raised Factor Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1),
      DbuAttribute.insight: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Spirit of Yardrat',
        description: "You've meditated with the spiritual masters of "
            'Yardrat, learning to manipulate your energy with even more '
            'fine-tuned control than before.\n'
            '(1)-[Passive]: Reduce the TP Cost of your Spiritual Unique '
            'Abilities by 3 and their Advancements by 2 (retroactive).\n'
            '(2)-[Passive]: While your Top Layer of Apparel has the Yardrat '
            'Material Quality, per Category: Armor — +1(bT) Defense; Weights '
            '— halve their Combat Roll reduction; Combat Clothing — +1(bT) '
            'Damage Reduction; Standard Clothing — +1(bT) Combat Rolls.\n'
            '(3)-[Passive]: When a Character regains Ki via your Empower '
            'Maneuver, they regain additional Ki = 1/4 (rounded up) of your '
            'Surgency.\n'
            '(4)-[Triggered, 1/Encounter]: When you use the Empower '
            'Maneuver, select up to 4 targets and divide the Ki they gain '
            'among the number of Characters targeted.',
      ),
    ],
  ),

  // ====================================================== CUSTOM SPECIES ===
  TransformationDef(
    name: 'Custom Ascension',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.lesser,
    origin: TransformationOrigin.body,
    racialRequirement: 'Custom Species',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'This Awakening cannot be selected through Inherent '
        'Transformation',
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1),
      DbuAttribute.magic: TransformationAmb(coefficient: 1),
    },
    traits: [
      TransformationTrait(
        name: 'Custom Evolution',
        description: '(1)-[Passive]: Select an Attribute (except FO/MA) and '
            "increase this Transformation's Attribute Modifier Bonus by 1 in "
            'it.\n'
            '(2)-[Passive]: Upon gaining this Transformation, select a '
            'Custom Species Racial Trait you lack and gain access to it; '
            "this Awakening's Origin (Mind/Body) becomes that Trait's "
            'Category.',
        // (1) select an Attribute (except FO/MA) → +1 flat AMB of it.
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'AMB Attribute',
            options: kAmbPickNonPhysicalFlat1,
          ),
        ],
      ),
    ],
  ),
];

/// Looks up a Lesser Awakening by name, or `null` if unrecognized.
TransformationDef? lesserAwakeningByName(String name) {
  for (final a in kDbuLesserAwakenings) {
    if (a.name == name) return a;
  }
  return null;
}
