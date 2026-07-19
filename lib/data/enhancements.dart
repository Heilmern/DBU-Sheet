/// enhancements.dart
/// ---------------------------------------------------------------------------
/// Enhancements catalogue (Transformation Catalog → Standard / Transcendent
/// Enhancements), verbatim from the site (confirmed 07 July 2026). Enhancements
/// are entered through the Transformation Maneuver (max 1 active at a time,
/// alongside up to 1 Form), so their Attribute Modifier Bonus applies only
/// while ACTIVE.
///
/// CLASSIFICATION (see `EnhancementType`): Standard is the typical case;
/// Special is "an evolution or rediscovery" of an `initialEnhancement` (you
/// must have Mastered that first, and can't use the two together); Power is an
/// "Enhancement Power" (the Greater-Enhancement tier) carrying an
/// `unlimitedTrait`. Any Enhancement with the Transcendent Aspect can become a
/// Transcended Enhancement (counts as a Form for Transformation Stacking) and,
/// once Fully Mastered + 1 more Mastery, unlocks its `transcendentTrait`.
///
/// SCOPE (this pass): every "Any Race" Standard and Transcendent Enhancement,
/// transcribed verbatim on the shared `TransformationDef` structure (see
/// `transformations.dart`). Race-specific Enhancements (Saiyan/Android/… only)
/// are a follow-up pass, matching the catalogue's transcribe-in-passes
/// convention. Aspects are modelled in `data/aspects.dart` (rendered with
/// their effects); Grade-set (`*`) AMB tables are shown as text (a player can
/// enter live values via the per-Transformation custom AMB editor).
library;

import 'dbu_rules.dart';
import 'race_traits.dart';
import 'transformations.dart';

/// The 14 selectable "Aura Traits" for Sparking Aura's Strong Aura / Powerful
/// Aura Traits (both let you "select and gain access to an Aura Trait").
/// Effects are verbatim from the site; the numeric always-on passives are
/// automated (Mastery-gated / nested-choice / situational effects stay text —
/// Mastery effects only apply once Sparking Aura is Mastered).
const List<TraitOption> kSparkingAuraTraits = [
  TraitOption(
    name: 'Boosting Aura',
    description: 'This aura focuses your energy and allows you to reinforce '
        'your combat capabilities.\n'
        '(1)-[Permanent, Passive]: Select an Attribute (AG or TE). Increase '
        'the Attribute Modifier Bonus of that Attribute for this '
        'Transformation by 1(T).\n'
        '(2)-[Passive]: For each stack of Power you possess, increase your '
        'Wound Rolls by 1(T).\n'
        '(3)-[Passive]: For each stack of Power you possess, increase the Dice '
        'Category of your Tier of Power Extra Dice by 1 (max. +2).\n'
        '(4)-[Mastery, Passive]: Increase the Attribute Modifier Bonus (IN) of '
        'this Transformation by 1(T).\n'
        '(5)-[Mastery, Passive]: Increase the amount of Power stacks you gain '
        'from your uses of the Power Up Maneuver by 1.\n'
        '(6)-[Mastery, Triggered/Power, 1/Encounter]: Enter the Surging State '
        'until the end of your turn (ignore the Surging State\'s 2nd effect).',
    automation: [
      // (2) +1(T) Wound Rolls per Power stack.
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perPowerStack,
      ),
    ],
    // (1) select an Attribute (AG or TE) → +1(T) AMB of that Attribute.
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Boosting Attribute',
        options: [
          TraitOption(
            name: 'Agility',
            description: '+1(T) Attribute Modifier Bonus (AG).',
            ambPerTierBonus: {DbuAttribute.agility: 1},
          ),
          TraitOption(
            name: 'Tenacity',
            description: '+1(T) Attribute Modifier Bonus (TE).',
            ambPerTierBonus: {DbuAttribute.tenacity: 1},
          ),
        ],
      ),
    ],
  ),
  TraitOption(
    name: 'Bulking Aura',
    description: 'Your aura comes with a bulkier physique, allowing you to '
        'achieve new levels of combat strength.\n'
        '(1)-[Permanent]: Sparking Aura gains the Bulky Aspect.\n'
        '(2)-[Passive]: Increase your Wound Rolls by 1(T) for each Super Stack '
        'you possess.\n'
        '(3)-[Passive]: Increase your Soak Value by 1(T).\n'
        '(4)-[Triggered, 1/Round]: If you are hit by an Attacking Maneuver, '
        'increase your Soak Value by 1(T) for each Super Stack you possess.\n'
        '(5)-[Triggered/Power, 1/Round]: Gain a stack of Super Stack until the '
        'start of your next turn.\n'
        '(6-8)-[Mastery]: Treat your Super Stacks as 1 higher for the 2nd/4th '
        'effects; the 5th effect becomes [2/Round]; Signature Techniques may '
        'gain Energy Charges equal to your Super Stacks after the first.',
    automation: [
      // (3) +1(T) Soak Value.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TraitOption(
    name: 'Burning Aura',
    description: 'Your aura violently assaults everything around you.\n'
        '(1)-[Passive]: Increase your Wound Rolls by 1(T).\n'
        '(2)-[Ruling]: All Squares within a Sphere AoE (centered on you) are '
        'your \'Burning Zone\'.\n'
        '(3)-[Ruling]: \'Burn Attribute\' = 1/4 of your Force or Magic '
        'Modifier (whichever is higher).\n'
        '(4)-[Triggered]: If another Character uses an Attacking Maneuver while '
        'within your Burning Zone, reduce their Life Points by your Burn '
        'Attribute.\n'
        '(5)-[Triggered/Start of Turn]: All other Characters within your '
        'Burning Zone lose Life Points equal to twice your Burn Attribute.\n'
        '(6)-[Triggered/Power, 1/Round]: Reduce your Life Points by your Burn '
        'Attribute to gain an additional stack of Power.\n'
        '(7-9)-[Mastery]: +1 Magnitude Burning Zone; 4th/5th effects only hit '
        'Opponents; +1(T) Burn Attribute.',
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
  TraitOption(
    name: 'Burst Aura',
    description: 'This aura allows you to gather energy much faster than '
        'normal, providing extra fuel for your attacks.\n'
        '(1)-[Passive]: Increase the Attribute Modifier Bonus (FO/MA) of '
        'Sparking Aura by 1(T).\n'
        '(2)-[Passive]: Increase the Dice Category of your Energy Charges by 1 '
        'Category.\n'
        '(3)-[1/Round]: Use the Energy Charge Maneuver as an Instant '
        'Maneuver.\n'
        '(4)-[Triggered, 1/Encounter]: If you use the Energy Charge Maneuver, '
        'gain an additional Energy Charge from that use.\n'
        '(5)-[Triggered, 1/Encounter]: If you hit an Opponent with an Attacking '
        'Maneuver, apply an Energy Charge to it, then leave this '
        'Transformation.\n'
        '(6-8)-[Mastery]: +1(T) Signature Wound Rolls with 2+ Energy Charges; '
        'no longer leave on the 5th effect; 4th effect becomes [1/Round, '
        '3/Encounter].',
    // (1) +1(T) AMB (FO/MA).
    ambPerTierBonus: {DbuAttribute.force: 1, DbuAttribute.magic: 1},
  ),
  TraitOption(
    name: 'Corrupting Aura',
    description: 'You cover yourself in corrupting energy that weakens and '
        'harms your foes.\n'
        '(1)-[Passive]: Increase your Wound Rolls by 1(T).\n'
        '(2)-[Triggered]: Each time you deal Damage to an Opponent with an '
        'Attacking Maneuver, reduce their Life and Ki Points by 2(bT).\n'
        '(3)-[Triggered, 1/Round]: If you knock an Opponent through a Health '
        'Threshold, apply Blinded and Poisoned until the end of their turn.\n'
        '(4)-[Triggered, 1/Round]: On the 2nd effect, spend a Power stack and '
        '5(bT) Ki to apply Blinded or Poisoned.\n'
        '(5-7)-[Mastery]: +1(bT) to the 2nd effect; −2(bT) Ki on the 4th; '
        'Energy Charge attacks vs Blinded/Poisoned Opponents.',
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
  TraitOption(
    name: 'Defiant Aura',
    description: 'Your aura increases in strength when you\'re hurt, allowing '
        'you to defy the odds.\n'
        '(1)-[Passive]: For each Health Threshold you are below, increase your '
        'Combat Rolls by 1(T).\n'
        '(2)-[Passive]: While below the Injured Health Threshold, increase your '
        'Soak Value and Surgency by 1(T) and 2(T) respectively.\n'
        '(3)-[Triggered/Threshold]: Regain Life and Ki Points equal to your '
        'Surgency.\n'
        '(4-6)-[Mastery]: +1 Steadfast while below Bruised; +1(T) Might while '
        'below Injured; reduce Damage by your Might once/Encounter while below '
        'Injured.',
    automation: [
      // (1) +1(T) Combat Rolls per Health Threshold below.
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
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
      // (2) While below Injured: +1(T) Soak.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
        condition: TraitCondition.whileBelowInjuredThreshold,
      ),
      // (2) While below Injured: +2(T) Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 2,
        tierScaling: TierScaling.current,
        condition: TraitCondition.whileBelowInjuredThreshold,
      ),
    ],
  ),
  TraitOption(
    name: 'Efficient Aura',
    description: 'This aura is surprisingly efficient with energy expenditure, '
        'allowing you less strenuous access to its effects.\n'
        '(1)-[Permanent]: Sparking Aura gains the Perfect Ki Control Aspect.\n'
        '(2)-[Passive]: Increase your Surgency by 1(T).\n'
        '(3)-[Passive]: Increase your Combat Rolls by 1(T) while your Ki Points '
        'exceed your Max Capacity.\n'
        '(4)-[Triggered, 1/Round]: When making an Attacking Maneuver, you may '
        'use your Surgency as the Damage Attribute.\n'
        '(5)-[Triggered/Transform, 1/Encounter]: Use a Ki Surge as an '
        'Out-of-Sequence Maneuver.\n'
        '(6-8)-[Mastery]: −1 Draining level; +1(T) Surgency; regain 1/4 '
        'Surgency Ki at Start of Turn.',
    automation: [
      // (2) +1(T) Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TraitOption(
    name: 'Elemental Aura',
    description: 'The power of an element infuses this aura, imbuing your '
        'attacks with the fury of that element.\n'
        '(1)-[Permanent, Passive]: Select a Profile with \'Elemental\' in the '
        'name. That Element becomes your Favored Element while in this '
        'Transformation.\n'
        '(2)-[Passive]: Reduce the Ki Point Cost of your Favored Elements by '
        '1(T).\n'
        '(3)-[Triggered/Transform]: If you possess more than 1 Favored Element, '
        'you may stop treating all but the selected Element as Favored '
        'Elements; if you do, increase your Wound Rolls by x(bT) (x = Profiles '
        'that stopped being Favored, max 3).\n'
        '(4)-[Triggered, 1/Round]: When making an Attacking Maneuver, you may '
        'apply the Multi-Profile Super Profile using a Favored Element.\n'
        '(5-6)-[Mastery]: The 4th effect loses [1/Round]; double the 2nd '
        'effect\'s reduction.',
  ),
  TraitOption(
    name: 'Focused Aura',
    description: 'This aura is designed to work in short bursts, granting you '
        'great power at a cost.\n'
        '(1)-[Permanent]: Sparking Aura gains the Heartbeat (LV3) Aspect.\n'
        '(2)-[Passive]: Upon entering this Transformation through the Heartbeat '
        'Aspect, gain a stack of Power for the duration of that Maneuver.\n'
        '(3)-[Passive]: Increase your Combat Rolls and Soak Value by 1(T).\n'
        '(4)-[Passive]: Apply an Energy Charge to your Signature Techniques.\n'
        '(5)-[Automatic]: At the end of your turn, ignore the 3rd and 4th '
        'effects of Focused Aura until you leave this Transformation.\n'
        '(6)-[Mastery, Passive]: Ignore the 5th effect of Focused Aura.',
  ),
  TraitOption(
    name: 'Hazardous Aura',
    description: 'The area around you becomes engulfed by weather.\n'
        '(1)-[Ruling]: All Squares within a Sphere AoE (centered on you) are '
        'your \'Hazardous Zone\'.\n'
        '(2)-[Permanent, Ruling, Passive]: Select a Battle Weather — your '
        '\'Aura Weather\'.\n'
        '(3)-[Triggered/Transform, Triggered/Start of Turn]: Until the start of '
        'your next turn, all Squares in your Hazardous Zone suffer the '
        'Unnatural Weather Tier of your Aura Weather (you ignore its '
        'effects).\n'
        '(4)-[Passive]: While in your Aura Weather, increase your Soak Value '
        'and Wound Rolls by 1(T).\n'
        '(5-7)-[Mastery]: Aura Weather only affects Opponents; +1 Magnitude '
        'Hazardous Zone; +1 Weather Tier.',
  ),
  TraitOption(
    name: 'High Speed Aura',
    description: 'When in this aura, you move at an accelerated pace.\n'
        '(1)-[Permanent]: Sparking Aura gains the Enhanced Save (Impulsive) '
        'and High Speed Aspects.\n'
        '(2)-[Passive]: Increase the Attribute Modifier Bonus (AG) of Sparking '
        'Aura by 1(T).\n'
        '(3)-[Passive]: Using Rapid Movement does not increase the Ki Point '
        'Cost of the Movement Maneuver.\n'
        '(4)-[Passive]: Successfully dodging an Attacking Maneuver triggers '
        'your Exploit Maneuver against the attacker.\n'
        '(5)-[Passive]: If you take Damage from an Absolute Attack that missed '
        'you, reduce that Damage by 2(bT).\n'
        '(6)-[Triggered, 1/Round]: When targeting an Opponent, you may use '
        'your Agility Modifier as the Damage Attribute.\n'
        '(7-8)-[Mastery]: +1(T) Dodge Rolls; free Movement on dealing Damage.',
    // (2) +1(T) AMB (AG).
    ambPerTierBonus: {DbuAttribute.agility: 1},
  ),
  TraitOption(
    name: 'Mental Aura',
    description: 'When in this aura, you enter a state of altered '
        'consciousness, tapping into your mind for extra power.\n'
        '(1)-[Permanent, Option]: Select Raging Aura (Innate State [Raging] + '
        'Raging Aspects) or Mindful Aura (Innate State [Mindful] + Mindful '
        'Aspects).\n'
        '(2)-[Choice]: Raging Aura → +L(T) Soak and Wound Rolls (L = Raging '
        'Level); Mindful Aura → +L(T) Strike and Dodge Rolls (L = Mindful '
        'Level).\n'
        '(3)-[Triggered/Power, 1/Encounter]: Increase the Level of the Innate '
        'State to its highest possible Level until the start of your next '
        'turn.\n'
        '(4-6)-[Mastery]: 3rd effect becomes [1/Round, 2/Encounter]; extra '
        'Raging/Mindful maneuver options; bonus Power stack.',
  ),
  TraitOption(
    name: 'Reinforced Aura',
    description: 'This aura reduces the damage you take from your enemies\' '
        'attacks.\n'
        '(1)-[Permanent]: Sparking Aura gains the Enhanced Save (Corporeal) '
        'Aspect.\n'
        '(2)-[Passive]: For each stack of Power you possess, increase your '
        'Damage Reduction by 1(T) (max. 3(T)).\n'
        '(3)-[1/Round]: Use the Defend Maneuver without spending a Counter '
        'Action.\n'
        '(4)-[Triggered, 1/Round]: On Power Flare, +1(T) Dice Score per Power '
        'stack (max 3(T)).\n'
        '(5)-[Triggered, 1/Round]: On Direct Hit, +2(T) Soak before '
        'calculations.\n'
        '(6)-[Triggered, 1/Round]: On Guard, −2(T) Ki Point Cost.\n'
        '(7-9)-[Mastery]: Gains Armored Aspect; +1(T) Soak; once/Encounter set '
        'an incoming Damage Category to Standard.',
    automation: [
      // (2) +1(T) Damage Reduction per Power stack.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perPowerStack,
      ),
    ],
  ),
  TraitOption(
    name: 'Scaling Aura',
    description: 'This aura\'s strength grows as the user powers up.\n'
        '(1)-[Permanent, Passive]: Sparking Aura gains the Graded Aspect.\n'
        '(2)-[Permanent]: You cannot enter any Grade of Sparking Aura beyond '
        'the 1st while applying the Prelude Aspect.\n'
        '(3)-[Permanent]: Every Grade after the 2nd sets Sparking Aura\'s Tier '
        'of Power Requirement to G.\n'
        '(4)-[Graded]: Sparking Aura has 3 Grades. Each Grade after the first: '
        '+2 Stress Test Requirement; +1 Draining level; +1(T) AMB '
        '(AG/FO/TE/MA).\n'
        '(5)-[Passive]: Increase your Tier of Power Extra Dice by 1/2 of G '
        'Dice Categories.\n'
        '(6)-[Passive]: Increase the Wound Rolls of your Signature Techniques '
        'by 1/2 (rounded up) of G(T).',
  ),
];

const List<TransformationDef> kDbuEnhancements = [
  // ========================================================= Absorbed Power ===
  TransformationDef(
    name: 'Absorbed Power',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'Access to the Absorb Maneuver',
    aspects: ['Enhanced Save (Corporeal)'],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Power Made Mine',
        description: "Those you've absorbed lend their strength to your own, "
            'granting you nearly limitless might.\n'
            '(1)-[Permanent]: You can only enter this Transformation if you '
            'possess a stack of the Absorption Awakening.\n'
            '(2)-[Constant]: If you gain a stack of the Absorption Awakening, '
            'you may use the Transformation Maneuver as an Out-of-Sequence '
            'Maneuver to enter Absorbed Power.\n'
            '(3)-[Automatic/Transform]: Select an Absorbed Character. Increase '
            'the Attribute Modifier Bonuses (specifically the two Attributes '
            'with the highest Attribute Scores possessed by your selected '
            "Absorbed Character except FO or MA - if there's a tie, you may "
            'choose) of this Transformation by 1(T) until you leave this '
            'Transformation.\n'
            '(4)-[Passive]: Apply the highest Dice Category of Tier of Power '
            'Extra Dice from among your Absorbed Characters to your Combat '
            'Rolls. This still counts as Tier of Power Extra Dice for Tier of '
            'Power Limit (see - Core Rules).\n'
            '(5)-[Passive]: Increase your Surgency by 1(T) for every stack of '
            'Absorption you possess.',
        automation: [
          // (5) +1(T) Surgency per owned Absorption Awakening stack.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perNamedTransformationStack,
            resourceName: 'Absorption',
          ),
        ],
      ),
      TransformationTrait(
        name: 'Stolen Talents',
        description: "With the minds of the lives you've absorbed at your "
            'disposal, you gain access to a wider array of skills and talents '
            "poached from those you've absorbed.\n"
            '(1)-[Passive]: Reduce the Ki Point Cost of all Signature '
            'Techniques and Unique Abilities possessed by your Absorbed '
            'Characters by 1(T).\n'
            '(2)-[Triggered, 1/Round]: If you would use a Signature Technique '
            'that is not possessed by any of your Absorbed Characters, you may '
            "apply a qualifying Advantage from one of your Absorbed Character's "
            'Signature Techniques to that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If you would use a Signature Technique '
            'of one of your Absorbed Characters, apply an Energy Charge to that '
            'Attacking Maneuver.\n'
            '(4)-[Triggered/Power, 1/Encounter]: Select one of your Absorbed '
            'Characters. Regain Ki Points equal to their Surgency, then reduce '
            'their Ki Points by the amount of Ki Points you regained.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Internal Control',
      description: 'With all this stolen power at your disposal, your control '
          "over those you've absorbed is at an all-time high.\n"
          '(1)-[Triggered/Transform]: Double the Attribute Modifier Bonuses of '
          'this Transformation until the end of your next turn. Additionally, '
          'ignore the 5th effect of Assimilated Power until the end of your '
          'next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Grand Theft You',
      description: "You've grown comfortable using the stolen abilities of "
          'others, and have learned to make them your own.\n'
          '(1)-[Passive]: Absorbed Power gains the Perfect Ki Control Aspect.\n'
          '(2)-[Passive]: Reduce the Stress Test Requirement of any '
          "Transformations you've obtained from your Absorbed Characters by "
          '1.\n'
          '(3)-[Passive]: Increase your Wound Rolls by 1(T) for every 2 stacks '
          'of Absorption you possess.\n'
          '(4)-[Triggered, 1/Encounter]: If you use the 4th effect of Stolen '
          'Talents, regain Life Points equal to the amount of Ki Points '
          'regained.',
      automation: [
        // (3) +1(T) Wound Rolls per 2 owned Absorption Awakening stacks.
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
          ],
          coefficient: 1,
          tierScaling: TierScaling.current,
          kind: TraitMagnitudeKind.perNamedTransformationStack,
          resourceName: 'Absorption',
          fractionDenominator: 2,
        ),
      ],
    ),
  ),
  // ============================================================= Agile Style ===
  TransformationDef(
    name: 'Agile Style',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Impulsive)',
      'High Speed',
      'Peaked',
      'Fading (LV1)',
      'Limited (LV3)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Weightless',
        description: 'Without your weights, you feel light as a feather.\n'
            '(1)-[Constant]: If you doff Weights, you may use the '
            'Transformation Maneuver as an Out-of-Sequence Maneuver to enter '
            'this Transformation.\n'
            '(2)-[Permanent]: You cannot enter this Transformation while you '
            'are wearing Apparel of the Weights Apparel Category.\n'
            '(3)-[Permanent]: You can only enter this Transformation through '
            'the 1st effect of Weightless.\n'
            '(4)-[Automatic]: If you are no longer benefiting from the Doff '
            'Bonus from Weights, leave this Transformation.\n'
            '(5)-[Passive]: Increase your Surgency by 1/2 (rounded up) of your '
            'Doff Bonus.\n'
            '(6)-[Passive]: Increase your Max Capacity by 1/4.',
      ),
      TransformationTrait(
        name: 'Free and Fast',
        description: 'You hit hard and fast thanks to your increased speed and '
            "the momentum that it carries, and you're able to dodge with skill "
            'and grace.\n'
            '(1)-[Passive]: Increase your Greater Dice by x Dice Categories, '
            'where x is equal to 1/2 (rounded up) of the Craftsmanship Grade '
            'of the Weights you are benefitting from the Doff Bonus of.\n'
            '(2)-[Passive]: Ignore the 2nd effect of the Superior State.\n'
            '(3)-[Triggered, 1/Round]: If you target an Opponent with an '
            'Attacking Maneuver, enter the Superior State for the duration of '
            'that Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you are targeted by an Attacking '
            'Maneuver, enter the Superior State for the duration of that '
            'Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Burst Assault',
      description: 'Freed from the burden of the weights holding you down, you '
          'move unusually quickly for a few precious moments, granting you '
          'total battlefield superiority.\n'
          '(1)-[Triggered/Transform]: The 3rd and 4th effects of Free and Fast '
          'lose their [1/Round] Keywords until the start of your next turn.',
    ),
  ),
  // ============================================================== Unburdened ===
  TransformationDef(
    name: 'Unburdened',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Agile Style',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    aspects: [
      'Enhanced Save (Impulsive)',
      'High Speed',
      'Peaked',
    ],
    // Stress Test Requirement is `*` (set by the doffed Weights' Craftsmanship
    // Grade — see Burden of Training). AMB (AG/FO/MA) is `*` (Grade-set); IN is
    // a flat +1(T).
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true),
      DbuAttribute.force: TransformationAmb(graded: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(graded: true),
    },
    traits: [
      TransformationTrait(
        name: 'Burden of Training',
        description: 'The weights you regularly wear may slow you down and '
            "lessen the impact of your blows, but once they're removed, your "
            'freedom of movement is greater than it ever was.\n'
            '(1)-[Constant]: If you doff Weights, you may use the '
            'Transformation Maneuver as an Out-of-Sequence Maneuver to enter '
            'this Transformation.\n'
            '(2)-[Permanent]: You cannot enter this Transformation while you '
            'are wearing Apparel of the Weights Apparel Category.\n'
            '(3)-[Permanent]: You can only enter this Transformation through '
            'the 1st effect of Burden of Training.\n'
            '(4)-[Permanent]: The Stress Test Requirement for this '
            'Transformation is 5x the Craftsmanship Grade of the Weights you '
            'doffed to trigger the 1st effect of Burden of Training.\n'
            '(5)-[Passive]: The Attribute Modifier Bonuses (AG/FO/MA) of this '
            'Transformation are x(T), where x is equal to the Craftsmanship '
            'Grade of the Weights you doffed to trigger the 1st effect of '
            'Burden of Training.\n'
            '(6)-[Passive]: While in this Transformation, you cannot lose your '
            'Doff Bonus. You do not gain a Doff Bonus for doffing Apparel '
            'while in this Transformation.\n'
            '(7)-[Automatic]: Upon leaving this Transformation, lose your Doff '
            'Bonus.',
      ),
      TransformationTrait(
        name: 'Proof of Effort',
        description: 'Wearing weights so often has paid dividends, making you '
            'stronger, faster, and more resilient.\n'
            '(1)-[Passive]: Increase your Surgency by 1/2 of your Doff Bonus.\n'
            '(2)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(3)-[Passive]: Increase the Dice Score of your Might Clashes '
            'initiated through the Pinned Combat Condition or an Opponent by '
            '1(T).\n'
            '(4)-[Passive]: Increase the Wound Rolls of your Signature '
            'Techniques by 1/2 of your Doff Bonus.\n'
            '(5)-[Passive]: Increase your Soak Value by 1/2 of your Doff Bonus '
            '(after all calculations) for the duration of Attacking Maneuvers '
            'that you used the Direct Hit or Guard option of the Defend '
            'Maneuver in response to.\n'
            '(6)-[Triggered, 1/Encounter]: If you succeed at the Steadfast '
            'Check for a Health Threshold, you may use a Healing Surge as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Round 2 Starts Now!',
      description: "Until your weights come off, you don't go all out, instead "
          'testing the waters against your foes.\n'
          '(1)-[Triggered/Transform]: Use a Healing Surge as an '
          'Out-of-Sequence Maneuver. If this brings your Life Points above a '
          'Health Threshold, you may enter the Superior State until the start '
          'of your next turn.',
    ),
  ),
  // =============================================== Autonomous Ultra Instinct ===
  TransformationDef(
    name: 'Autonomous Ultra Instinct',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 6,
    stressTestRequirement: 12,
    prerequisiteText:
        'Access to the God Ki Special State through an effect or an Aspect',
    aspects: [
      'Enhanced Save (All)',
      'God Ki',
      'Mindful',
      'Innate State (Mindful)',
      'Straining',
      'Difficult (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Angelic Technique',
        description: 'You have learned to use a technique reserved for the '
            'divine beings known as Angels.\n'
            '(1)-[Permanent]: Reduce the Stress Test Requirement of this '
            'Transformation by x, where x is equal to double the Tier of Power '
            'Requirement of the Transformation with the highest Tier of Power '
            'Requirement that is/would be used in conjunction with this '
            "Transformation. However, this Transformation's Stress Test "
            'Requirement is added completely onto any Transformation used in '
            'conjunction with it, rather than being halved, even when it has '
            'the lower Stress Test Requirement.\n'
            '(2)-[Passive]: Increase your Combat Rolls by x(bT), where x is '
            'equal to 1 or 1/2 of the highest Tier of Power Requirement of any '
            'Transformation used in conjunction with this Transformation '
            '(min. 1) if you are using this Transformation in conjunction with '
            'another Transformation.\n'
            '(3)-[Passive]: The minimum Natural Result of your Strike and '
            'Dodge Rolls is 2. If this Transformation is used in conjunction '
            'with another Transformation, increase the minimum Natural Result '
            "by 1/2 of that Transformation's Tier of Power Requirement.\n"
            '(4)-[Triggered, 1/Round]: If you succeed in dodging an Attacking '
            'Maneuver, you may use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver. If you do, you do not pay any Ki Points '
            'for this Attacking Maneuver.',
      ),
      TransformationTrait(
        name: 'In the Realm of Angels',
        description: 'You have ascended beyond the mortal nature of your birth '
            'and achieved divine skill previously unknown to the universe at '
            'large.\n'
            '(1)-[Passive]: You do not trigger the Exploit Maneuver unless you '
            'are suffering from the Guard Down or Impediment Combat '
            'Conditions.\n'
            '(2)-[Triggered/Start of Turn]: You may spend 3(bT) Divine Ki '
            'Points to remove a Combat Condition you are suffering from '
            '(except Pinned, Suffocating, Transfigured, or Poisoned). You may '
            'repeat this effect any number of times.\n'
            '(3)-[Triggered/Power, 1/Round]: Enter the Zen level of the '
            'Mindful State until the start of your next turn.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Angelic Trumpets',
      description: 'You move with fluid grace and precision, exerting only the '
          'necessary energy to avoid attacks and land your own.\n'
          '(1)-[Triggered/Transform]: You successfully Dodge all Attacking '
          'Maneuvers that target you (except by characters in the Determined '
          'State) regardless of the Dice Score of your Dodge Roll until the '
          'start of your next turn.',
    ),
    masteryTraits: [
      TransformationTrait(
        name: 'Sharpened Instinct (1)',
        description: 'You learn to rely more on your instincts, honing them to '
            'a perfect edge.\n'
            '(1)-[Permanent]: Autonomous Ultra Instinct loses the Straining '
            'Aspect.\n'
            '(2)-[Passive]: You may enter the Tranquil level of the Mindful '
            'State instead of the Zen level through the 3rd effect of In the '
            'Realm of Angels.\n'
            '(3)-[Passive]: Increase the minimum Natural Result for the 3rd '
            'effect of Angelic Techniques by 1.',
      ),
      TransformationTrait(
        name: 'Angelic Instinct (2)',
        description: 'Your body moves without an ounce of input from your '
            'conscious mind, reacting to your surroundings.\n'
            '(1)-[Permanent]: Autonomous Ultra Instinct gains the Natural '
            '(LV1) Aspect.\n'
            '(2)-[Triggered]: If you are not hit by an Opponent’s '
            'Attacking Maneuver that targets you, regain 2(bT) Ki Points.',
      ),
    ],
  ),
  // =================================================================== Awoken ===
  TransformationDef(
    name: 'Awoken',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 24,
    prerequisiteText: 'No access to Alternate Forms/Legendary Forms',
    aspects: [
      'Transcendent',
      'Enhanced Save (All)',
      'High Speed (Level 3)',
      'Dedicated',
      'Exhausting',
      'Draining (Level 2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'A Welcome Challenge',
        description: 'You are strong enough to compete without transforming '
            'like some warriors, and you relish the chance to show them up.\n'
            '-[Triggered/Start of Turn]: Target an Opponent - they become the '
            'Challenger until the start of your next turn. Apply your Tier of '
            'Power Extra Dice an additional time for all Combat Rolls against '
            'the Challenger.\n'
            '-[Triggered, 1/Encounter]: If you Defeat the Challenger or knock '
            'the Challenger through the Injured/Critical Health Threshold, '
            'enter the Superior State until the end of your next turn.',
      ),
      TransformationTrait(
        name: 'A Show of Skill',
        description: 'Your techniques alone make you a formidable opponent, '
            'and with them, you are ready to take on any fight, any '
            'opponent.\n'
            "-[Permanent]: Awoken's Racial Requirement is also considered to "
            'be your Race for the sake of any effects.\n'
            '-[Triggered, 1/Round]: When you target the Challenger with a '
            'Signature Technique, that Attacking Maneuver gains an Energy '
            'Charge.\n'
            '-[Triggered, 1/Round]: When you target the Challenger with a '
            'Basic Attack, you may apply an Advantage to that Attacking '
            'Maneuver that it qualifies for.\n'
            '-[Triggered, 1/Round]: When you make a Might Clash or a Clash '
            'that uses one of your Saving Throws against your Challenger, '
            'increase the Dice Score by 1(T).\n'
            '-[Triggered, 1/Round]: When you make a Skill Clash against your '
            'Challenger, increase the Natural Result of that roll by 1.',
      ),
      TransformationTrait(
        name: 'A Great Determination',
        description: 'You refuse to be put down by those who you deem weaker '
            'than yourself.\n'
            '-[Permanent]: If you apply Power Improvement: Surpass to this '
            'Transformation, apply Power Improvement: Control to it as well '
            '(even if this Transformation is still a Transcendent '
            'Enhancement).\n'
            '-[Passive]: Increase the amount of Life and Ki Points you regain '
            'through a Surge or Combat Recovery by 1d4(bT). Increase the Dice '
            'Category of this bonus by 1 Category for each Health Threshold you '
            'are below.\n'
            '-[Triggered/Defeated]: If the Challenger is below the Bruised '
            'Health Threshold, immediately use a Healing Surge as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'An Uphill Battle',
      description: "You're prepared against even terrible odds.\n"
          '-[Triggered/Transform]: Until the end of your next turn, all of '
          'your Opponents are treated as Challengers for your effects. If you '
          'target an Opponent that is being treated as a Challenger through '
          'this effect with the first effect of A Welcome Challenge, increase '
          'your Strike and Wound Rolls against that target by 1(T) and 3(T) '
          'respectively until the start of your next turn.',
    ),
    unlimitedTrait: TransformationTrait(
      name: 'Awaken the Instinct',
      description: 'Your combat instincts come alive when faced with a strong '
          'enough challenge.\n'
          '-[Passive]: Increase your Strike and Wound Rolls against the '
          'Challenger by 1(T) and 2(T) respectively.\n'
          '-[Passive]: Increase your Tier of Power Extra Dice and Greater Dice '
          'by 1 Category. Increase this by 1 Category for every Health '
          'Threshold you are below.\n'
          '-[Passive]: You may use an additional Enhancement Power in '
          'conjunction with this Transformation.\n'
          '-[1/Round]: Use a Surge as an Instant Maneuver.',
    ),
  ),
  // ============================================================= Boiling Rage ===
  TransformationDef(
    name: 'Boiling Rage',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Steaming Fury Racial Trait',
    aspects: [
      'Variant (Enraged)',
      'Innate State (Raging)',
      'Raging',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Scalding Assault (Frenzied Assault)',
        description: 'Your erratic and unpredictable behavior combined with '
            'your intense anger allows you to strike your opponent with '
            'greater power when they least expect it.\n'
            '(1)-[Constant]: If you trigger the 3rd effect of Steaming Fury, '
            'you may instead use the Transformation Maneuver to enter this '
            'Transformation as an Out-of-Sequence Maneuver (this still counts '
            'towards its [3/Encounter] Keyword).\n'
            '(2)-[Passive]: Increase the AoE for the 2nd effect of Steaming '
            'Fury by 1 Magnitude.\n'
            '(3)-[Passive]: Increase the Wound Rolls of your Attacking '
            'Maneuvers that target Characters suffering from the effects of '
            'the Obscured Environmental Quality by 2(T).\n'
            '(4)-[Passive]: Increase your Surgency by x(T), where x is equal '
            'to your current level of the Raging State.\n'
            '(5)-[Triggered, 1/Round]: If you increase your level of the '
            'Raging State, you may regain Life Points equal to your Surgency.\n'
            '(6)-[Triggered, 1/Round]: If you target an Opponent with an '
            'Attacking Maneuver while in the 2nd or higher Level of the Raging '
            'State, you may spend Life Points up to your Surgency to increase '
            'the Wound Roll of that Attacking Maneuver by an equal amount.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Vigorous Boil',
      description: "It doesn't matter why you're angry, your full wrath has "
          'been unleashed no matter how minor the slight, and you are ready to '
          'annihilate the target of your fury.\n'
          '(1)-[Triggered/Transform]: Enter the Apoplectic level of the Raging '
          'State until the end of your next turn (ignoring the 5th effect of '
          'Explosive Fury). Then, trigger the 2nd effect of Steaming Fury, but '
          'increase the Magnitude of the AoE to Destructive.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Simmering Temper',
      description: 'Your body may take damage, but all you feel is the endless '
          'wellspring of rage bubbling inside you as you pummel your enemies '
          'into oblivion.\n'
          '(1)-[Passive]: While you possess the Guard Down Combat Condition, '
          'it does not count as a Combat Condition for the effects of your '
          'Opponents.\n'
          '(2)-[Passive]: Ignore the second effect of the Angry level of the '
          'Raging State.\n'
          '(3)-[Passive]: While you are in the Apoplectic Level of the Raging '
          'State, this Transformation possesses the Armored Aspect.\n'
          '(4)-[Passive]: You may spend your Life Points as if they were Ki '
          'Points for any Ki Wagers you make. Any Life Points spent through '
          'this effect reduce your Capacity as if they were Ki Points being '
          'spent.\n'
          '(5)-[1/Round]: If you are occupying a Square that has the Obscured '
          'Environmental Quality, you may move to any other Square that has '
          'the Obscured Environmental Quality as an Instant Maneuver.',
    ),
  ),
  // =========================================================== Breaking Point ===
  TransformationDef(
    name: 'Breaking Point',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Morale)',
      'Limited (LV3)',
      'Draining (LV1)',
      'Exhausting',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Power for a Price',
        description: 'You expend your own life force in order to empower your '
            'attacks.\n'
            '(1)-[Passive]: Reduce the Dice Score of your Steadfast Checks by '
            '1.\n'
            '(2)-[Passive]: For each Health Threshold you are below, increase '
            'your Wound Rolls by 1(T).\n'
            '(3)-[Passive]: While you are below the Injured Health Threshold, '
            'increase the Strike Rolls of your Signature Techniques by 1(T).\n'
            '(4)-[Passive]: While you are below the Critical Health Threshold, '
            'apply an Energy Charge to your Ultimate Signature Techniques.\n'
            '(5)-[Triggered]: When making an Attacking Maneuver during your '
            'turn, you may reduce your Soak Value by 1(bT) until the start of '
            'your next turn to increase the Wound Roll of that Attacking '
            'Maneuver by 2(T). You can only use this effect if it would not '
            'reduce your Soak Value to 0 and while your Soak Value is above '
            '0.\n'
            '(6)-[Triggered/Start of Turn, 1/Encounter]: If you are below the '
            'Injured Health Threshold, you may reduce your Life Points to be 1 '
            'below the Critical Health Threshold, ignoring the effects of '
            'Reduced Momentum. If you do, you may use the Power Up Maneuver, '
            'Energy Charge Maneuver, or Transformation Maneuver as an '
            'Out-of-Sequence Maneuver.',
        automation: [
          // (2) +1(T) Wound Rolls per Health Threshold below.
          RaceTraitAutomation(
            affectedStats: [
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
      TransformationTrait(
        name: 'High Risk',
        description: 'Knowingly endangering your own life, you empower your '
            'body beyond its limits.\n'
            '(1)-[Passive]: You cannot regain Life Points.\n'
            '(2)-[Passive]: Increase the Strike Rolls of Attacking Maneuvers '
            'with the Backlash Disadvantage by 1(T).\n'
            '(3)-[Triggered, 1/Round]: If you use a Signature Technique, you '
            'may apply up to 3 ranks of the Backlash Disadvantage to that '
            'Attacking Maneuver. If you do, for each rank of Backlash applied '
            'to that Attacking Maneuver, apply a rank of Power Shot. These '
            'ranks of Power Shot may exceed the limit.\n'
            '(4)-[Triggered/Start of Turn]: Reduce your Life Points by up to '
            '10(bT). Regain Ki Points equal to the reduction.\n'
            '(5)-[Triggered, 1/Encounter]: If you reduce your Life Points '
            'through your own effects, you may use a Ki Surge as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Bet it All',
      description: 'Despite the risk, your extreme power up pays tenfold in '
          'damage inflicted to your enemy.\n'
          '(1)-[Triggered/Transform]: Reduce your Life Points by 1/5 of your '
          'Maximum Life Points. If you do, enter the Surging State until the '
          'end of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Right at the Limit',
      description: 'You manage to keep yourself right on the edge of breaking, '
          'pushing yourself to the edge of your limits but not beyond.\n'
          '(1)-[Permanent]: Breaking Point loses the Limited and Draining '
          'Aspects.\n'
          '(2)-[Passive]: Ignore the 1st effect of Power for a Price.\n'
          '(3)-[Passive]: Increase the amount of Ki Points regained through '
          'the 4th effect of High Risk by 1/2.\n'
          '(4)-[Triggered]: If you leave the Breaking Point Enhancement while '
          'above the Injured Health Threshold, ignore the effects of the '
          'Exhausting Aspect.',
    ),
  ),
  // ============================================================= Burst Attack ===
  TransformationDef(
    name: 'Burst Attack',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'High-Stake Gamble',
        description: 'You put everything you have into the fight, using up '
            'every ounce of power you have in reserve.\n'
            '(1)-[Permanent]: You cannot enter this Transformation if you '
            'cannot trigger the Burst Limit and, upon entering this '
            'Transformation, you must activate the Burst Limit.\n'
            '(2)-[Automatic]: Upon leaving this Transformation, gain the '
            'Stress Exhaustion, Guard Down, and Impediment Combat Conditions '
            'for 2 Combat Rounds.\n'
            '(3)-[Passive]: Ignore all Health Threshold Penalties.\n'
            '(4)-[Passive]: Increase your Maximum Capacity by 1/4.\n'
            '(5)-[Triggered/Transform, 1/Encounter]: Use the Basic Attack '
            'Maneuver as an Out-of-Sequence Maneuver.',
      ),
      TransformationTrait(
        name: 'Burst Through the Limit',
        description: "Your desperation pushes you past your limits, unleashing "
            "energy reserves you didn't even know you had.\n"
            '(1)-[Passive]: Increase the Dice Category of any Energy Charges '
            'applied to your Attacking Maneuvers by 1 Dice Category.\n'
            '(2)-[Triggered]: If you hit your Focus with an Attacking '
            'Maneuver, you may spend a stack of Energy Burst to apply an '
            'Energy Charge to that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: If you use a Signature Technique '
            'during a turn in which you have spent 2+ stacks of Energy Burst, '
            'you may apply an Energy Charge to that Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Power Eruption',
      description: 'Your power explodes, granting you enhanced might for a '
          'limited time.\n'
          '(1)-[Automatic/Transform, Resource]: For each Health Threshold you '
          'were below when you entered this Transformation, gain a stack of '
          'Energy Burst.',
    ),
  ),
  // ============================================================= Crusher Form ===
  TransformationDef(
    name: 'Crusher Form',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    prerequisiteText: 'Beast-Man Factor or Animal Race',
    aspects: [
      'Graded',
      'Enhanced Save (Corporeal)',
    ],
    // AMB (FO/TE/MA) is +G(T) — set by Crusher Form's Grade (4 Grades).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
      DbuAttribute.tenacity:
          TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
    },
    traits: [
      TransformationTrait(
        name: 'Bestial Vengeance',
        description: 'When you take damage, your body grows stronger, allowing '
            'you to grow to great heights.\n'
            '(1)-[Passive]: While you are below the Injured Health Threshold, '
            'increase your Soak Value by 1(T).\n'
            '(2)-[1/Round]: You may use the Direct Hit option of the Defend '
            'Maneuver without spending a Counter Action.\n'
            '(3)-[Triggered, Resource, 1/Round]: If you receive Damage from an '
            "Opponent's Attacking Maneuver, reduce the Damage you would have "
            'received after all calculations by 1/2 of your Might and then, if '
            'you still take Damage, gain a Crusher Point (max. G+3).\n'
            '(4)-[Graded]: Crusher Form has 4 Grades. Each Crusher Form Grade: '
            'Increases the Stress Test Requirement by 3. Each Grade after the '
            'first adds a level of the Growth Aspect (i.e. Grade 3 has Growth '
            'LV2, Grade 4 has Growth LV3). Requires a certain number of '
            'Crusher Points to enter it. Each Grade after the first requires 2 '
            'more Crusher Points than the last Grade (Grade 1 requires 0, '
            'Grade 2 requires 2, Grade 3 requires 4 and Grade 4 requires 6). '
            'Sets your Attribute Modifier Bonuses as shown on the table above.',
      ),
      TransformationTrait(
        name: 'Bestial Evolution',
        description: 'Due to your increased strength and size from the damage '
            'you take, your counterattacks are brutal.\n'
            '(1)-[Passive]: While you possess 4+ Crusher Points, increase the '
            'Dice Category of your Punching Down Extra Dice by 1 Dice '
            'Category.\n'
            '(2)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver who is a smaller Size Category than you, '
            'increase the Wound Roll of that Attacking Maneuver by 1(T) for '
            'every 2 Crusher Points you possess.\n'
            '(3)-[Triggered, 1/Round]: If you are hit by the Attacking '
            'Maneuver of an Opponent who is a smaller Size Category than you, '
            'increase your Damage Reduction by 1(T) for every 2 Crusher Points '
            'you possess for the duration of that Attacking Maneuver.\n'
            '(4)-[Passive]: Gain effects depending on which Bestial Traits you '
            'have access to (Alternate Sight, Arboreal, Bestial Build, Blood '
            'in the Water, Burrowing Beast, Camouflage, Claws, Elemental '
            'Adaptation, Extra Limbs, Fangs, Grippy Grabbers, Impaling Horns, '
            'Land-Based Beast, Regenerating Beast, Retractable Limbs, Return '
            'to Heritage, Silk Production, Sturdy Shell, Tail, Treacherous '
            'Spikes, Underwater Beast, Weather Resilient, Winged Beast) — see '
            'the site for each Bestial Trait effect.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Warrior the Crusher',
      description: 'You force your body to grow in size and strength, '
          'displaying your crushing superiority.\n'
          '(1)-[Triggered/Transform]: Gain 2 Crusher Points.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Dangerous Crusher',
      description: 'You have grown to titanic size and strength, making '
          'yourself the most dangerous opponent on the battlefield.\n'
          '(1)-[Passive]: For calculating the bonus/penalty to your Defense '
          'Value from your Size Category, and for the effects of Punching Up, '
          'you are considered to be of the Large Size Category if your Size '
          'Category is Enormous or larger.\n'
          '(2)-[Passive]: While you have 6+ Crusher Points, Crusher Form gains '
          'the Armored Aspect.\n'
          '(3)-[Passive]: The 3rd effect of Bestial Vengeance loses the '
          '[1/Round] Keyword and gains the [2/Round] Keyword.\n'
          '(4)-[Passive]: Increase your maximum number of Crusher Points for '
          'the 4th Grade of Crusher Form by 2.\n'
          '(5)-[Passive]: Double the amount of Crusher Points you gain from '
          'the effects of Warrior the Crusher.\n'
          '(6)-[Passive]: The 9th Crusher Point counts as 2 Crusher Points for '
          'your effects.\n'
          '(7)-[1/Round]: If you are at your maximum number of Crusher Points '
          'for your current Grade of Crusher Form, you may use the '
          'Transformation Maneuver as an Instant Maneuver. If you do, you must '
          'enter a higher Grade of Crusher Form.\n'
          '(8)-[Triggered/Power, 1/Encounter]: Gain 2 Crusher Points.',
    ),
  ),
  // ======================================================== Dark Enhancement ===
  TransformationDef(
    name: 'Dark Enhancement',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 13,
    aspects: [
      'Variant (Evil Aura)',
      'Enhanced Save (Corporeal/Cognitive)',
      'Raging',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Dark Dragon Ball Power (Villainous Form)',
        description: "Your dark energy swells, letting you overpower anyone "
            "who'd try to stop you.\n"
            '(1)-[Passive]: Your maximum number of Evil Points is 13(bT).\n'
            '(2)-[Passive]: Increase your Tier of Power Extra Dice by 1 Dice '
            'Category.\n'
            '(3)-[Passive]: Increase the Dice Score of your Duel Clashes by '
            '1(T).\n'
            '(3)-[Triggered, 1/Round]: If you make a Might Clash, you may '
            'spend 3(bT) Evil Points to increase your Dice Score by 1(T).\n'
            '(4)-[Triggered, 1/Round]: If you spend 3(bT) or more Evil Points '
            'on the Wound Roll of a Signature Technique, you may apply an '
            'Energy Charge to that Attacking Maneuver.\n'
            '(5)-[Triggered/Power, 1/Round]: You may spend 3(bT) Evil Points '
            'to enter the Raging State until the start of your next turn.\n'
            '(6)-[Triggered/Raging, 1/Encounter]: Enter the Surging State '
            'until the start of your next turn.',
      ),
    ],
  ),
  // ================================================================== Dark Ki ===
  TransformationDef(
    name: 'Dark Ki',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 13,
    aspects: [
      'Variant (Evil Aura)',
      'Enhanced Save (Corporeal)',
      'Raging',
      'Difficult (LV1)',
      'Rampaging (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Disorientating Darkness (Villainous Form)',
        description: 'Lost in darkness enveloping your heart, you become wild '
            'and savage, aggressively lashing out at everyone around you.\n'
            '(1)-[Passive]: Your maximum number of Evil Points is 9(bT).\n'
            '(2)-[Passive]: Increase the Strike and Wound Rolls of your '
            'Attacking Maneuvers that have at least 1 targeted Opponent below '
            'the Bruised Health Threshold by 1(T) and 2(T) respectively.\n'
            '(3)-[Automatic, 1/Round]: If an Opponent triggers your Exploit '
            'Maneuver, spend 3(bT) Evil Points to use the Exploit Maneuver '
            'without spending a Counter Action.\n'
            '(4)-[Triggered, 1/Round]: If you Defeat an Opponent or knock them '
            'through a Health Threshold with an Attacking Maneuver, regain '
            '6(bT) Evil Points.\n'
            '(5)-[Triggered/Start of Turn]: You may spend up to 3(bT) Life '
            'Points to regain an equal amount of Evil Points.\n'
            '(6)-[Triggered/Power, 1/Encounter]: Spend 3(bT) Evil Points to '
            'enter the Raging State until you leave this Transformation. At the '
            'start of each Combat Round, you must spend 3(bT) Evil Points, or '
            'you leave the Raging State.',
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: 'The Scary Second Level (1)',
        description: 'Y\n'
            '(1)-[Permanent]: Dark Ki gains the Graded Aspect.\n'
            '(2)-[Passive]: Ignore the 1st effect of Disorientating '
            'Darkness.\n'
            '(3)-[Passive]: Reduce the amount of Evil Points you must spend to '
            'not leave the Raging State through the 6th effect of '
            'Disorientating Darkness by G(bT).\n'
            '(4)-[Triggered, 1/Round]: While in the 2nd (or higher) Grade of '
            'Dark Ki, if you target an Opponent below the Injured Health '
            'Threshold with a Signature Technique, you may apply an Energy '
            'Charge to that Attacking Maneuver.\n'
            '(5)-[Graded]: Dark Ki has 2 Grades. Each Evil Aura Grade sets the '
            'AMB of Evil Aura for the listed Attribute, the Stress Test '
            'Requirement, and your maximum Evil Points — Grade (AMB FO/MA | '
            'Stress Test | Evil Point Maximum): 1 (1(T) | 13 | 10(bT)); '
            '2 (2(T) | 15 | 12(bT)).',
      ),
      TransformationTrait(
        name: 'The Terrifying Third Level (2)',
        description: 'Y\n'
            '(1)-[Permanent]: You gain access to the 3rd Grade of Dark Ki.\n'
            '(2)-[Permanent]: Increase the Attribute Modifier Bonus (IN) of '
            'Dark Ki by 1(T).\n'
            '(3)-[Passive]: The 3rd effect of Disorientating Darkness loses '
            'the [Automatic] Keyword and gains the [Triggered] Keyword.\n'
            'Grade 3 (AMB FO/MA 3(T) | Stress Test 18 | Evil Point Maximum '
            '15(bT)).',
      ),
    ],
  ),
  // ============================================================= Deep Sleeper ===
  TransformationDef(
    name: 'Deep Sleeper',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Impulsive/Cognitive)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Zzz',
        description: 'T\n'
            '(1)-[Permanent]: You gain access to the Sleepy Time Special '
            'Maneuver.\n'
            '(2)-[Constant]: If you gain the Sleeping Combat Condition, you '
            'may use the Transformation Maneuver as an Out-of-Sequence Maneuver '
            'to enter this Transformation (ignoring the effects of the '
            'Sleeping Combat Condition).\n'
            '(3)-[Automatic]: If you stop suffering from the Sleeping Combat '
            'Condition, you immediately leave this Transformation.\n'
            '(4)-[Passive]: While you are suffering from the Sleeping Combat '
            'Condition, you are not automatically hit by Attacking Maneuvers '
            'and may use Attacking Maneuvers, the Movement Maneuver, and '
            'Counter Maneuvers.\n'
            '(5)-[Passive]: While you are suffering from the Sleeping Combat '
            'Condition, increase your Combat Rolls by 1(T).\n'
            '(6)-[Triggered/Start of Turn]: You cannot stop suffering from the '
            'Sleeping Combat Condition except by the effects of the Sleeping '
            'Combat Condition until the start of your next turn.\n'
            'Sleepy Time Maneuver [1/Round] — Standard Maneuver, 2 Actions, '
            'Minions Free, KP Cost N/A, Exploitable by all adjacent Opponents: '
            'Gain the Sleeping Combat Condition. Then, you may regain '
            '2d10(bT) Life and Ki Points.',
      ),
      TransformationTrait(
        name: 'Dangerous Sleeper',
        description: 'T\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of your Attacking '
            'Maneuvers by 1(T).\n'
            '(2)-[Passive]: Any Attacking Maneuver that targets you triggers '
            'your Exploit Maneuver against the attacking Character.\n'
            '(3)-[Passive]: If a Character ends their movement on a Square '
            'adjacent to you, this triggers your Exploit Maneuver against that '
            'Character.\n'
            '(4)-[Automatic]: If a Character triggers your Exploit Maneuver, '
            'you must use the Exploit Maneuver if you are able, even if you '
            'must convert an Action into a Counter Action to do so.\n'
            '(5)-[Automatic, 1/Encounter]: If you take Damage from an '
            'Attacking Maneuver, before you leave the Sleeping Combat '
            'Condition through its effects, you may use the Basic Attack '
            'Maneuver or Signature Technique Maneuver as an Out-of-Sequence '
            'Maneuver. If you do, apply an Energy Charge to that Attacking '
            'Maneuver, but you must target the Character that used the '
            'Attacking Maneuver that triggered this effect.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Relaxing Nap',
      description: 'T\n'
          '(1)-[Triggered/Transform]: If you entered this Transformation '
          'through the 2nd effect of Zzz triggered in response to your use of '
          'the Sleepy Time Special Maneuver, you may double the amount of Life '
          'and Ki Points you regain through the effects of the Sleepy Time '
          'Maneuver. Then, gain 2 stacks of Power until the start of your next '
          'turn.',
    ),
  ),
  // =================================================================== Doping ===
  TransformationDef(
    name: 'Doping',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 6,
    prerequisiteText:
        'To enter, you must first consume some kind of performance enhancing '
        'material such as a drug, an injection or a Fruit from the Tree of '
        'Might — discuss with your ARC what options are available.',
    aspects: [
      'Enhanced Save (Impulsive)',
      'Bulky',
      'Raging',
      'Peaked',
      'Exhausting',
      'Limited (LV3)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Body at the Brink',
        description: 'The chemicals coursing through your veins have pushed '
            'your body to its limits, giving you a strong edge against the '
            'competition.\n'
            '(1)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n'
            '(2)-[Passive]: Increase your Wound Rolls by 1(T) for each Health '
            'Threshold you are below.\n'
            '(3)-[Passive]: Increase your Strike Rolls, Dodge Rolls, and Soak '
            'Value by 1(T) while below the Injured Health Threshold.\n'
            '(4)-[Triggered/Power, 1/Encounter]: Gain 1 Action.',
      ),
      TransformationTrait(
        name: 'Dangerous Amplification',
        description: 'Thanks to the chemicals soaking your brain, your '
            'adrenaline is in overdrive, amping up your aggression and driving '
            'you to action, regardless of the cost to your body.\n'
            '(1)-[Passive]: Halve your Surgency.\n'
            '(2)-[Triggered]: When you use an Attacking Maneuver, you may '
            'spend Life Points up to the Ki Point Cost of that Attacking '
            'Maneuver. If you do, increase the Wound Roll by an equal amount.\n'
            '(3)-[1/Round]: You may spend 4(bT) Life Points to use the Power '
            'Up Maneuver as an Instant Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you spend more than 8(bT) Life '
            'Points through the 2nd effect of Dangerous Amplification, you may '
            'apply an Energy Charge to that Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Power and Payment',
      description: 'The burst of adrenaline pumping through you grants you '
          'unimaginable power, damaging your body in the aftermath.\n'
          '(1)-[Triggered/Transform]: Gain 2 Actions. After leaving this '
          'Transformation, gain the Drained Combat Condition and reduce your '
          'Life Points by 1/4 (rounded up) of your Maximum Life Points.',
    ),
  ),
  // ============================================================== Drunken Fist ===
  TransformationDef(
    name: 'Drunken Fist',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Innate State (Drunk)',
      'Enhanced Save (Impulsive/Morale)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Power of the Bottle',
        description: 'Whether through imitation or through actually imbibing, '
            'your movement is like that of a drunkard, but with combat skills '
            'woven in.\n'
            '(1)-[Constant]: If you drink from a Sake Bottle, instead of '
            'entering the Drunk State, you may use the Transformation Maneuver '
            'to enter this Transformation as an Out-of-Sequence Maneuver.\n'
            '(2)-[Passive]: The first effect of the Tipsy Level of the Drunk '
            'Special State increases your Saving Throws and Combat Rolls '
            'instead of reducing them.\n'
            '(3)-[Triggered, Resource]: If you successfully dodge an '
            "Opponent's Attacking Maneuver, gain a stack of Toppling "
            '(max. 3).\n'
            '(4)-[Triggered]: If you target an Opponent with an Attacking '
            'Maneuver, you may spend any number of Toppling stacks to increase '
            'the Strike and Wound Rolls of that Attacking Maneuver by 1(T) for '
            'each Toppling stack spent.',
      ),
      TransformationTrait(
        name: 'Unpredictable Combat',
        description: 'The way you move, it becomes impossible to identify your '
            'next move, making defending against you or even striking you '
            'difficult beyond measure.\n'
            '(1)-[Passive]: Do not reduce your Defense Value through the '
            'effects of the Cross Counter option of the Defend Maneuver.\n'
            '(2)-[Passive]: If you score a Critical Result on a Combat Roll, '
            'increase the Dice Score of that Combat Roll by 1(T).\n'
            '(3)-[Triggered]: If you score a Botch Result on a Dodge Roll, it '
            'becomes a Critical Result instead (this does not change the '
            'Natural Result).\n'
            '(4)-[Triggered, 1/Round]: If you successfully dodge an Attacking '
            'Maneuver, you may use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver after that Attacking Maneuver concludes. '
            'If you do, you must target the Character whose Attacking Maneuver '
            'you dodged with this Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you are targeted by an Attacking '
            'Maneuver, you may use the Cross Counter option of the Defend '
            'Maneuver without spending a Counter Action.\n'
            '(6)-[Triggered, 1/Round]: If you would trigger the Exploit '
            'Maneuver, you can choose not to.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Calculated Stumbling',
      description: 'You may be staggering and bumbling around the '
          'battlefield, but every movement is purposeful and meaningful.\n'
          '(1)-[Triggered/Transform]: Enter the Plastered Level of the Drunk '
          'State until the end of your next turn and gain 3 stacks of '
          'Toppling. The 4th, 5th, and 6th effects of Unpredictable Combat '
          'lose the [1/Round] keyword until the end of your next turn.',
    ),
  ),
  // ======================================================= Elemental Supremacy ===
  TransformationDef(
    name: 'Elemental Supremacy',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'Access to a Favored Element',
    aspects: [
      'Glowing',
      'Light Dependent',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Elemental Aptitude',
        description: 'You choose to specialize in a given elemental power, '
            'taking it farther than anyone else.\n'
            '(1)-[Automatic/Transform]: Select and gain access to an Elemental '
            'Trait until you leave this Transformation.\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of your Attacking '
            'Maneuvers using your Favored Element by 1(T).\n'
            '(3)-[Passive]: Reduce the Critical Target of your Strike and '
            'Wound Rolls by 1 if they are rolled for an Attacking Maneuver '
            'that uses your Favored Element.\n'
            '(4)-[Triggered, 1/Round]: If you score a Critical Result on the '
            'Strike Roll of an Attacking Maneuver that uses your Favored '
            'Element, you may score a Critical Result on the Wound Roll of '
            'that Attacking Maneuver regardless of the Natural Result.\n'
            'Select your Elemental Trait below (chosen at effect (1)).',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Elemental Trait',
            options: [
              TraitOption(
                name: 'Dark Master',
                description: 'You have mastered the darkness, allowing you to '
                    'see your opponents, but not allowing them to see you. '
                    '(1)-[Prerequisite]: Elemental (Dark) is your Favored '
                    "Element. (2)-[Passive]: This Transformation's Glowing "
                    'Aspect reduces the Light Level, instead of increasing it. '
                    '(3)-[Passive]: Ignore any penalties from Light Levels. '
                    '(4)-[Passive]: Increase the Strike and Wound Rolls of '
                    'your Attacking Maneuvers that target Characters within a '
                    'negative Light Level by 1(T). (5)-[1/Round]: You may '
                    'spend 4(bT) Life Points to use the Power Up Maneuver as '
                    'an Instant Maneuver. (6)-[Triggered/Power, 1/Encounter]: '
                    'Reduce the Light Levels of the Battlefield to Pitch Black '
                    'until the start of your next turn.',
              ),
              TraitOption(
                name: 'Flame Master',
                description: 'You have mastered the sizzling flames, scorching '
                    'all enemies in your reach. (1)-[Prerequisite]: Elemental '
                    '(Fire) is your Favored Element. (2)-[Passive]: Ignore the '
                    'effects of the Aflame Environmental Quality and the '
                    'Burning Feature Quality. (3)-[Passive]: Increase your '
                    'Wound Rolls of Attacking Maneuvers that target Opponents '
                    'suffering from the Broken Combat Condition by 1(T). '
                    '(4)-[Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver of the Elemental (Fire) Profile, apply a rank of '
                    'the Sustained Advantage to that Attacking Maneuver. '
                    '(5)-[Triggered, 1/Encounter]: If you deal Damage to an '
                    'Opponent with a Signature Technique that uses the '
                    'Elemental (Fire) Profile but do not knock them through a '
                    'Health Threshold, treat it as if you did.',
              ),
              TraitOption(
                name: 'Flora Master',
                description: 'You have mastered the wild bloom, ensnaring '
                    'enemies in your tangled roots. (1)-[Prerequisite]: '
                    'Elemental (Plantlife) is your Favored Element. '
                    '(2)-[Passive]: Ignore the effects of the Staggered Combat '
                    'Condition. (3)-[Passive]: Increase your Wound Rolls of '
                    'Attacking Maneuvers that target Opponents suffering from '
                    'the Staggered Combat Condition by 1(T). (4)-[Triggered, '
                    '1/Round]: If you use an Attacking Maneuver of the '
                    'Elemental (Plantlife) Profile, apply the Condition (Guard '
                    'Down) Advantage to that Attacking Maneuver. '
                    '(5)-[Triggered, 1/Encounter]: If you hit an Opponent with '
                    'an Attacking Maneuver of the Elemental (Plantlife) '
                    'Profile, you may move that Opponent any number of Squares '
                    'up to your Might in any direction.',
              ),
              TraitOption(
                name: 'Frost Master',
                description: 'You have mastered the freezing cold. '
                    '(1)-[Prerequisite]: Elemental (Ice) is your Favored '
                    'Element. (2)-[Passive]: Ignore the effects of the Frozen '
                    'Environmental Quality. (3)-[Passive]: Increase your Wound '
                    'Rolls of Attacking Maneuvers that target Opponents '
                    'suffering from the Slowed Combat Condition by 1(T). '
                    '(4)-[Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver of the Elemental (Ice) Profile, apply the '
                    'Condition (Drained) Advantage to that Attacking Maneuver. '
                    '(5)-[Triggered, 1/Encounter]: If you deal Damage to an '
                    'Opponent with a Signature Technique that uses the '
                    'Elemental (Ice) Profile but do not knock them through a '
                    'Health Threshold, treat it as if you did.',
              ),
              TraitOption(
                name: 'Light Master',
                description: 'You have mastered the light. (1)-[Prerequisite]: '
                    'Elemental (Light) is your Favored Element. (2)-[Passive]: '
                    'Ignore any penalties from Light Levels. (3)-[Passive]: '
                    'Increase the Strike and Wound Rolls of your Attacking '
                    'Maneuvers that target Characters within a Light Level of '
                    '1 or higher by 1(T). (4)-[Triggered, 1/Round]: If you use '
                    'a Signature Technique of the Elemental (Light) Profile, '
                    'increase its Wound Roll by 1/2 of the Ki Points you Ki '
                    'Wagered on that Attacking Maneuver. (5)-[Triggered/Power, '
                    '1/Encounter]: Increase the Light Levels of the '
                    'Battlefield to Blinding until the start of your next '
                    'turn.',
              ),
              TraitOption(
                name: 'Metal Master',
                description: 'You have mastered metal. (1)-[Prerequisite]: '
                    'Elemental (Metal) is your Favored Element. (2)-[Passive]: '
                    'Ignore all Collision Damage. (3)-[Triggered]: If you hit '
                    'an Opponent with an Attacking Maneuver who is occupying a '
                    'Square with the Metallic Environmental Quality or is '
                    'adjacent to a Feature with the Metallic Feature Quality, '
                    "increase the Wound Roll by 1/2 of that Square/Feature's "
                    'Hardness Value. (4)-[Triggered, 1/Encounter]: If you '
                    'apply the Metallic Environmental Quality or the Metallic '
                    'Feature Quality to a Square/Feature that an Opponent is '
                    'occupying or adjacent to through the Elemental (Metal) '
                    'Profile, make a Clash (Might) against that Opponent; if '
                    'you win, they collide with that Square/Feature.',
              ),
              TraitOption(
                name: 'Rot Master',
                description: 'You have mastered the deadly venom. '
                    '(1)-[Prerequisite]: Elemental (Poison) is your Favored '
                    'Element. (2)-[Passive]: Ignore the effects of the '
                    'Poisoned Combat Condition and the Poisonous Environmental '
                    'Quality. (3)-[Passive]: Increase your Wound Rolls of '
                    'Attacking Maneuvers that target Opponents suffering from '
                    'the Poisoned Combat Condition by 1(T). (4)-[Triggered, '
                    '1/Round]: If you use an Attacking Maneuver of the '
                    'Elemental (Poison) Profile, apply the Condition (Drained) '
                    'Advantage to that Attacking Maneuver. (5)-[Triggered, '
                    '1/Encounter]: If you deal Damage to an Opponent with a '
                    'Signature Technique that uses the Elemental (Poison) '
                    'Profile but do not knock them through a Health Threshold, '
                    'treat it as if you did.',
              ),
              TraitOption(
                name: 'Stone Master',
                description: 'You have mastered the very ground beneath your '
                    'feet. (1)-[Prerequisite]: Elemental (Earth) is your '
                    'Favored Element. (2)-[Passive]: Increase your Soak Value '
                    'by 1(T). (3)-[Passive]: Increase the Wound Rolls of your '
                    'Signature Techniques of the Elemental (Earth) Profile by '
                    '1(T). (4)-[Triggered, 1/Encounter]: If you hit an '
                    'Opponent with an Attacking Maneuver that is benefiting '
                    'from the effects of the Bludgeoning Weapon Category, '
                    'instead of half, you may ignore all of their Damage '
                    'Reduction.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Volt Master',
                description: 'You have mastered the striking lightning. '
                    '(1)-[Prerequisite]: Elemental (Lightning) is your Favored '
                    'Element. (2)-[Passive]: Ignore the effects of the '
                    'Electrified Environmental Quality and the Shocking '
                    'Feature Quality. (3)-[Passive]: Increase your Wound Rolls '
                    'of Attacking Maneuvers that target Opponents suffering '
                    'from the Impediment Combat Condition by 1(T). '
                    '(4)-[Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver of the Elemental (Lightning) Profile, apply the '
                    'Condition (Guard Down) Advantage to that Attacking '
                    'Maneuver. (5)-[Triggered, 1/Encounter]: If you deal '
                    'Damage to an Opponent with a Signature Technique that '
                    'uses the Elemental (Lightning) Profile but do not knock '
                    'them through a Health Threshold, treat it as if you did.',
              ),
              TraitOption(
                name: 'Wave Master',
                description: 'You have mastered the very waters of the rivers '
                    'and oceans. (1)-[Prerequisite]: Elemental (Water) is your '
                    'Favored Element. (2)-[Passive]: Ignore the effects of the '
                    'Bog Environment. (3)-[Passive]: Increase your Wound Rolls '
                    'of Attacking Maneuvers that target Opponents suffering '
                    'from the Prone Combat Condition by 1(T). (4)-[Triggered, '
                    '1/Round]: If you use an Attacking Maneuver of the '
                    'Elemental (Water) Profile, apply the Condition (Shaken) '
                    'Advantage to that Attacking Maneuver. (5)-[Triggered, '
                    '1/Encounter]: If you deal Damage to an Opponent with a '
                    'Signature Technique that uses the Elemental (Water) '
                    'Profile but do not knock them through a Health Threshold, '
                    'treat it as if you did.',
              ),
              TraitOption(
                name: 'Wind Master',
                description: 'You have mastered the air around you. '
                    '(1)-[Prerequisite]: Elemental (Wind) is your Favored '
                    'Element. (2)-[Passive]: Increase your Defense Value by '
                    '1(T). (3)-[Passive]: Increase the Wound Rolls of your '
                    'Signature Techniques of the Elemental (Wind) Profile by '
                    '1(T). (4)-[Triggered, 1/Encounter]: If you hit an '
                    'Opponent with an Attacking Maneuver that is benefiting '
                    'from the effects of the Slashing Weapon Category, apply '
                    'your Damage Attribute an additional time to that '
                    'Attacking Maneuver.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.defenseValue],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: 'Element Unleashed',
        description: 'You can freely manipulate your chosen element, and your '
            'skill with it allows you to hit harder and faster.\n'
            '(1)-[Passive]: Increase the Dice Category of any of your Energy '
            'Charges applied to an Attacking Maneuver that uses your Favored '
            'Element by 1 Category.\n'
            '(2)-[Triggered, 1/Round]: If you use a Super Signature Technique '
            'that uses your Favored Element and does not possess an AoE, you '
            'may apply a Line or Cone AoE to that Attacking Maneuver.\n'
            '(3)-[Triggered/Power, 1/Round]: You may use the Energy Charge '
            'Maneuver as an Out-of-Sequence Maneuver. If you do, you must '
            'declare an Attacking Maneuver of your Favored Element for the '
            'effects of the Energy Charge Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Super Signature '
            'Technique that uses your Favored Element, you may apply the '
            'Ascended Signature Advantage to that Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Elemental Burst',
      description: 'You call a massive burst of your specialized element, '
          'striking a huge blow and leaving your mark on the battlefield.\n'
          '(1)-[Triggered/Transform]: Use the Basic Attack Maneuver or '
          'Signature Technique Maneuver as an Out-of-Sequence Maneuver. This '
          'Attacking Maneuver must be of a Profile that is your Favored '
          'Element. When using this Attacking Maneuver, you may apply one of '
          'the following Super Profiles (as long as you/the Attacking Maneuver '
          'meet the Prerequisites): All Out, Cataclysmic Attack, Complete '
          'Annihilation, or Weather Maximizer.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Mastery over the Elements',
      description: 'Your devotion to controlling your chosen element has '
          'finally paid off.\n'
          '(1)-[Permanent]: Elemental Supremacy loses the Draining Aspect.\n'
          '(2)-[Permanent, Passive]: Upon gaining this Mastery Trait, select '
          'either Tenacity or Agility. Increase the Attribute Modifier Bonus '
          'of Elemental Supremacy for your chosen Attribute by 1(T).\n'
          '(3)-[Passive]: Ignore the Ki Point Cost of the Energy Charge '
          'Maneuver if your declared Attacking Maneuver is your Favored '
          'Element.\n'
          '(4)-[Triggered]: If you score a Critical Result on the Strike or '
          'Wound Roll of an Attacking Maneuver that uses your Favored Element, '
          'increase the Dice Score by 1(T).\n'
          '(5)-[Triggered]: You may increase the Magnitude of any AoE applied '
          'through the 2nd effect of Element Unleashed to Large.',
    ),
  ),
  // ============================================================= Enhanced Aura ===
  TransformationDef(
    name: 'Enhanced Aura',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Access to an Aura',
    aspects: [
      'Transcendent',
      'Glowing',
      'Light Dependent',
      'Dedicated',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Aura beyond Limits',
        description: 'You have learned to empower your technique to the point '
            'that it has evolved and become something new, something '
            'stronger.\n'
            '-[Permanent, Passive]: Upon gaining access to this Enhancement '
            'Power, select an Aura you have access to that lacks the Infusion '
            'Advantage. That becomes your Ascended Aura. You cannot apply the '
            'Infusion Aura Advantage to your Ascended Aura through any means.\n'
            '-[Automatic]: If you would leave your Ascended Aura for any '
            'reason, you leave this Transformation immediately and suffer from '
            'Stress Exhaustion until the end of your next turn.\n'
            '-[Automatic/Transform]: Unless you are already in your Ascended '
            'Aura, use the Aura Maneuver to enter your Ascended Aura as an '
            'Out-of-Sequence Maneuver.\n'
            '-[Triggered, 1/Round]: When making an Attacking Maneuver, you may '
            'gain a free Ki Wager equal to the Ki Point Cost of your Ascended '
            'Aura.\n'
            '-[Triggered, 1/Round]: When making an Attacking Maneuver, if your '
            'Aura is a Shield Aura, you may spend your Shield Durability as a '
            'Ki Wager.',
      ),
      TransformationTrait(
        name: 'Aura Breakthrough',
        description: 'The unique properties of your aura technique have grown '
            'in power.\n'
            "-[Passive]: Gain the effect that shares a name with your Ascended "
            "Aura's Aura Type:\n"
            'Sparking [Passive]: While in this Transformation, you possess a '
            'stack of Power. This stack of Power cannot be removed by any '
            'means while you are in this Transformation.\n'
            'Burning [Triggered]: If you reduce the Life Points of a Character '
            'through the effects of your Burning Aura, make a Might Clash '
            'against them. If you win, they reduce their Life Points by an '
            'additional 1/2 of the reduction that triggered this effect, and '
            'they are knocked Prone.\n'
            'Hazardous [Passive]: The Battle Weather created by your Aura '
            'affects the entire Battlefield and, while in that Battle Weather, '
            'all of your Opponents have their Combat Rolls reduced by 1(T) — '
            'using the higher between your and their Tier of Power.\n'
            'Avatar [Triggered, 2/Round]: When making an Attacking Maneuver, '
            'you can declare that all targets for that Attacking Maneuver are '
            '2+ Size Categories smaller than you for the effects of Punching '
            'Down. If you already were 2+ Size Categories larger than all of '
            'the targets, apply the Punching Down Extra Dice an additional '
            'time to that Wound Roll.\n'
            'Energy Focus [Triggered, 1/Round]: When making an Attacking '
            'Maneuver, spend 3(bT) Ki Points to increase the Damage Category '
            'of that Attacking Maneuver by 1.\n'
            'Shield [1/Round]: Spend 1 Action and up to 10(T) Ki Points to '
            "make a Might Check. Increase the Might Check's Dice Score by the "
            'spent Ki Points, and then add the total to your Shield '
            'Durability.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Aura Burst',
      description: 'Your powerful aura flares to life around you, giving you '
          'an unprecedented burst of energy.\n'
          '-[Triggered/Transform]: You do not need to pay the Ki Point Cost to '
          'enter your Ascended Aura. Additionally, for the next 2 Combat '
          'Rounds, you do not need to pay Ki Points at the start of your turn '
          'to keep your Ascended Aura active.',
    ),
    unlimitedTrait: TransformationTrait(
      name: 'Perfected Aura',
      description: 'You have achieved the most powerful form of your aura '
          'technique.\n'
          '-[Passive]: This Transformation gains the Perfect Ki Control '
          'Aspect.\n'
          "-[Passive]: Gain the enhanced effect that shares a name with your "
          "Ascended Aura's Aura Type:\n"
          'Sparking [Passive]: Double the bonus to your Combat Rolls from your '
          'stacks of Power.\n'
          'Burning [Triggered/Unlimited, Triggered/Start of Combat Round]: '
          'Apply the effects of the Burning Aura immediately.\n'
          'Hazardous [Passive]: Your Opponents score Botch Results on their '
          'Clashes against you through the Brace Maneuver or the effects of '
          "your Ascended Aura's chosen Battle Weather, regardless of their "
          'Natural Result. If the effects of your chosen Battle Weather does '
          'not induce a Clash, instead increase your Wound Rolls by 2(T).\n'
          'Avatar [Passive]: Increase your Punching Down Extra Dice by 3 Dice '
          'Categories.\n'
          'Energy Focus [Passive]: Your Attacking Maneuvers ignore the '
          "effects of your Opponent's Armored Aspect and have their Wound Roll "
          'increased by 2(T). Double this bonus to your Wound Roll if your '
          'Attacking Maneuver that targeted an Opponent did not have its '
          "Damage Category reduced by that Opponent's effects.\n"
          'Shield [Passive]: Reduce the Damage your Shield receives from your '
          "Opponent's Attacking Maneuvers by 1/2 of your Might.",
    ),
  ),
  // ================================================================== Enraged ===
  TransformationDef(
    name: 'Enraged',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Innate State (Raging)',
      'Raging',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Explosive Fury',
        description: "You've gone straight past frustrated, mad, and angry; "
            'you are absolutely livid.\n'
            '(1)-[Triggered/Transform, Triggered/Start of Turn]: Gain the '
            'Guard Down Combat Condition until the start of your next turn. If '
            'you do, enter the next level of the Raging State until you leave '
            'this Transformation.\n'
            '(2)-[Passive]: Ignore all Health Threshold Penalties while in the '
            'Furious level of the Raging State.\n'
            '(3)-[Passive]: Increase your Soak Value and Wound Rolls by 1(T) '
            'while you are not suffering from any Health Threshold Penalties.\n'
            '(4)-[Automatic]: If you fail a Steadfast Check, return to the '
            'Angry level of the Raging State - exiting any higher levels.\n'
            '(5)-[Automatic/Start of Turn]: If you do not trigger the 1st '
            'effect of Explosive Fury, return to the Angry level of the Raging '
            'State - exiting any higher levels.\n'
            '(6)-[Triggered, 1/Encounter]: If you target only 1 Character with '
            'an Attacking Maneuver while below the Injured Health Threshold, '
            'enter the Determined State for the duration of that Attacking '
            'Maneuver.',
      ),
      TransformationTrait(
        name: 'Frenzied Assault',
        description: 'The force of your fury pushes you to continue attacking '
            'your enemies until they stop moving.\n'
            '(1)-[Passive]: While in the Determined State, increase the '
            'Attribute Modifier Bonus (FO/MA) of this Transformation by 1(T).\n'
            '(2)-[Passive]: While in the 3rd or higher Level of the Raging '
            'State, you automatically win all Clashes initiated by another '
            'Character that uses your Cognitive or Morale Saving Throw.\n'
            '(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver while '
            'in the 2nd or higher Level of the Raging State, increase the '
            'Damage Category of that Attacking Maneuver by 1 Category.\n'
            '(4)-[Triggered, 1/Round]: If you are targeted by an Attacking '
            'Maneuver, you may use the Defend Maneuver without spending a '
            'Counter Action. If you do, you must select the Cross Counter '
            'option of the Defend maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Unleashed Rage',
      description: "Your anger explodes, making you stronger than you've ever "
          'been.\n'
          '(1)-[Triggered/Transform]: Enter the Apoplectic Level of the '
          'Raging State until the end of your next turn (ignoring the 5th '
          'effect of Explosive Fury). If you do, use the Basic Attack Maneuver '
          'as an Out-of-Sequence Maneuver. Enter the Determined State for the '
          'duration of that Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Directed Anger',
      description: 'Channeling your titanic rage, you take control of your '
          'anger and use it as a weapon against your foes.\n'
          '(1)-[Passive]: While you possess the Guard Down Combat Condition, '
          'it does not count as a Combat Condition for the effects of your '
          'Opponents.\n'
          '(2)-[Passive]: Ignore the second effect of the Angry level of the '
          'Raging State.\n'
          '(3)-[Passive]: While you are in the Apoplectic Level of the Raging '
          'State, this Transformation possesses the Armored Aspect.\n'
          '(4)-[Triggered, 1/Round]: If you use the Cross Counter option of '
          'the Defend Maneuver, you may spend 5(bT) Ki Points to enter the '
          'Determined State for the duration of that Maneuver.',
    ),
  ),
  // ================================================================= Evil Aura ===
  TransformationDef(
    name: 'Evil Aura',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    aspects: [
      'Graded',
      'Enhanced Save (Corporeal)',
      'Raging',
      'Rampaging (LV G)',
    ],
    // AMB (FO/MA) is Grade-set: Grade 1→1(T), 2→3(T) (Evil Aura, 2 Grades);
    // TE and IN are flat +1(T).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 3]),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Villainous Form',
        description: "Whether it's something you chose for yourself or "
            'something placed upon you, this upgrade to your power compels you '
            "to act like the villain you've become.\n"
            '(1)-[Passive]: Gain access to the Evil Techniques (detailed on '
            'the site). You may use either your Force or Magic Modifier for '
            'the Damage Attribute of your Evil Techniques.\n'
            '(2)-[Passive]: Gain access to the Darkness Mixer Modifier '
            'Maneuver.\n'
            '(3)-[Passive]: When using an Evil Technique, you may spend Evil '
            'Points equal to 1/2 of the Ki Point Cost for that Attacking '
            'Maneuver instead of paying the Ki Point Cost.\n'
            '(4)-[Triggered]: If you Ki Wager a number of Ki Points equal to '
            '(or exceeding) 1/10th of your Max Capacity on an Attacking '
            'Maneuver, increase your Wound Roll for that Attacking Maneuver by '
            'G(T).\n'
            '(5)-[Graded]: Evil Aura has 2 Grades. Each Grade sets the AMB '
            '(FO/MA), the Stress Test Requirement, and your maximum Evil '
            'Points — Grade (AMB FO/MA | Stress Test | Evil Point Maximum): '
            '1 Villainous (1(T) | 13 | 10(bT)); 2 Supervillain (3(T) | 18 | '
            '15(bT)).\n'
            'Evil Techniques (pre-built Signature Techniques):\n'
            'Baked Sphere (Ultimate Signature) — Foundation: Energy '
            '(Clearing); Advantages: Twin-Linked (Wound), Power Shot (2), '
            'Sudden Blast; Disadvantages: Lead-Up (Clearing), Restriction - '
            'Transformation (2, Evil Aura), Self-Explosion; Ki Point Cost: '
            '10(T).\n'
            'Gigantic Ki Blast (Ultimate Signature) — Foundation: Energy (Mega '
            'Flare); Advantages: Widespread Assault (Sphere), Terrain '
            'Destruction (3), Intense Blast, Maximum Charge, Full Wager; '
            'Disadvantages: Mandatory Charge (3), Concentration, Restricted - '
            'Transformation (2, Evil Aura), All or Nothing, Exhaustive; Ki '
            'Point Cost: 9(T).\n'
            'Marbling Drop (Super Signature) — Foundation: Energy '
            '(Combination); Advantages: Widespread Assault (Sphere), '
            'Knockback, Power Shot (2); Disadvantages: Restriction - '
            'Transformation (2, Evil Aura), Self-Explosion; Ki Point Cost: '
            '10(T).\n'
            'Peeler Storm (Super Signature) — Foundation: Physical (Sweeping); '
            'Advantages: Hurricane Assault, Terrain Destruction (3), '
            'Staggering Attack; Disadvantages: Restriction - Transformation '
            '(2, Evil Aura), All or Nothing; Ki Point Cost: 8(T).\n'
            'Rage Saucer (Super Signature) — Foundation: Physical '
            '(Combination); Advantages: Widespread Assault (Sphere), Alotta '
            'Lotta Attacks (3); Disadvantages: Restriction - Transformation '
            '(2, Evil Aura); Ki Point Cost: 8(T).\n'
            'Darkness Mixer [1/Round] (1 Action, Base Maneuver: Power Up): '
            'Regain 3(bT) Evil Points and Ki Points. Then, make a Might Clash '
            'against all Opponents within a Sphere AoE (centered on you). If '
            'you win against an Opponent, reduce their Life Points by 1/2 of '
            'your Might.',
      ),
      TransformationTrait(
        name: 'Power of Evil',
        description: 'The evil energy welling up inside you empowers your '
            'attacks and protects you from harm.\n'
            '(1)-[Triggered/Start of Combat Round, Resource]: Gain 5(bT) Evil '
            'Points.\n'
            '(2)-[Triggered]: When you make an Attacking Maneuver, you may '
            'spend up to 5(bT) Evil Points to increase the Wound Roll of that '
            'Attacking Maneuver by an equal amount.\n'
            '(3)-[Triggered]: When you are targeted by an Attacking Maneuver, '
            'you may spend up to 5(bT) Evil Points to gain an equal amount of '
            'Damage Reduction for the duration of that Attacking Maneuver.\n'
            '(4)-[Triggered]: When you spend any number of Evil Points, regain '
            'an equal amount of Ki Points.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Dark Power Rising',
      description: 'The culmination of evil energy inside you reaches a '
          'bursting point!\n'
          '-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. If you do, maximize your Evil Points.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Controlled Darkness',
      description: 'The evil urges within you now answer to your beck and '
          'call.\n'
          '(1)-[Passive]: Reduce the level of the Rampaging Aspect by 1 '
          'level.\n'
          "(2)-[Passive]: Increase this Transformation's Attribute Modifier "
          'Bonus (AG) by 1(T).\n'
          '(3)-[Triggered/Power, 1/Round]: You may spend 5(bT) Evil Points to '
          'gain an additional stack of Power.',
    ),
  ),
  // ================================================================ Feral Fist ===
  TransformationDef(
    name: 'Feral Fist',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Variant (Drunken Fist)',
      'Innate State (Feral)',
      'Enhanced Save (Impulsive)',
      'High Speed',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Mad Dog Attack (Power of the Bottle)',
        description: 'As the line between instinct and conscious thought fades '
            'into obscurity, you launch yourself into battle like a wild '
            'animal.\n'
            '(1)-[Constant]: If you would use an effect that would let you '
            'enter the Feral Special State, you may instead use the '
            'Transformation Maneuver to enter this Transformation as an '
            'Out-of-Sequence Maneuver.\n'
            '(2)-[Passive]: You can use Unique Abilities that are Counter '
            'Maneuvers or Out-of-Sequence Maneuvers, even while in the Feral '
            'State.\n'
            '(3)-[Passive]: While in the Unhinged level of the Feral State, '
            'reduce the Critical Target for your Wound Rolls by 2.\n'
            '(4)-[1/Round]: During your turn, you may use the Movement '
            'Maneuver as an Instant Maneuver.\n'
            '(5)-[Triggered, Resource]: If you use the Movement Maneuver or '
            'score a Critical Result on the Wound Roll of an Attacking '
            'Maneuver, gain a stack of Ferocity (max. 3).\n'
            "(6)-[Triggered]: If you are targeted by an Opponent's Attacking "
            'Maneuver, you may spend any number of Ferocity stacks to increase '
            'your Dodge Rolls by 1(T) for each Ferocity stack spent.\n'
            '(7)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver, you may spend any number of Ferocity stacks '
            'to increase your Wound Roll for that Attacking Maneuver by 1(T) '
            'for each stack of Ferocity stack spent.\n'
            '(8)-[Triggered, 1/Round]: If you end your movement from the '
            'Movement Maneuver with an Opponent in your Melee Range, you may '
            'spend 2 stacks of Ferocity to use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver. If you do, you must target that '
            'Opponent with this Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Unforeseen Ferocity',
      description: 'Your feral nature overwhelms and subdues not only your '
          'conscious mind, but also your enemies.\n'
          '(1)-[Triggered/Transform]: Gain 3 stacks of Ferocity. '
          'Additionally, enter the Unhinged level of the Feral State until the '
          'end of your next turn.',
    ),
  ),
  // =========================================================== Focused Tracking ===
  TransformationDef(
    name: 'Focused Tracking',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: 'Enhanced Search Talent',
    aspects: [
      'Enhanced Save (Impulsive/Cognitive)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'I Can See Right through You!',
        description: 'T\n'
            '(1)-[Passive]: Increase the Skill Bonus for your Perception and '
            'Clairvoyance Skills by 1.\n'
            "(2)-[Passive]: Increase your Combat Rolls against your 'Marked' "
            'Opponent by 1(T).\n'
            '(3)-[1/Round]: If you are targeted by an Attacking Maneuver used '
            "by your 'Marked' Opponent, do not gain any Diminishing Defense "
            'from that Attacking Maneuver.\n'
            "(4)-[1/Round]: If your 'Marked' Opponent uses the Movement "
            'Maneuver, you may use the Movement Maneuver as an Out-of-Sequence '
            'Maneuver.\n'
            "(5)-[Triggered, 1/Encounter]: If your 'Marked' Opponent would use "
            'the Exploit Maneuver to target you with an Attacking Maneuver, '
            'you may automatically dodge this Attacking Maneuver regardless of '
            'the Dice Score of your Dodge Roll.\n'
            "(6)-[Triggered, 1/Encounter]: If you target a 'Marked' Opponent "
            'and no other Characters with an Attacking Maneuver made through '
            'the Basic Attack Maneuver, you may enter the Determined State for '
            'the duration of that Attacking Maneuver.',
      ),
      TransformationTrait(
        name: "I'm Going Full Force, Don't Die on Me, Okay?!",
        description: 'W\n'
            '(1)-[Passive]: While you possess 2+ stacks of Power, increase '
            'your Wound Rolls by 1(T). Double this bonus for the duration of '
            'your Signature Techniques.\n'
            '(2)-[Passive]: For every stack of Power you possess, increase '
            'your Surgency by 1(T) (max. 2(T)).\n'
            '(3)-[1/Round]: While you possess 2+ stacks of Power and you are '
            "targeted by an Attacking Maneuver used by your 'Marked' Opponent, "
            'you may use the Defend Maneuver without spending a Counter '
            'Action.\n'
            '(4)-[Triggered, 1/Round]: While you possess 2+ stacks of Power '
            "and your 'Marked' Opponent triggers your Exploit Maneuver, you "
            'may use your Exploit Maneuver without spending a Counter '
            'Action.\n'
            '(5)-[Triggered, 1/Encounter]: If you win the Clash for the 5th '
            'effect of Enhanced Search, you may use the Power Up Maneuver as '
            'an Out-of-Sequence Maneuver.',
        automation: [
          // (1) While 2+ Power stacks: +1(T) Wound Rolls (the Signature
          // doubling is per-attack, manual).
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 2,
          ),
          // (2) +1(T) Surgency per Power stack (max 2(T) — Power caps at 2
          // stacks anyway).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perPowerStack,
          ),
        ],
      ),
    ],
    burstLimit: TransformationTrait(
      name: "Let's Do This!",
      description: 'T\n'
          '(1)-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. You gain an additional stack of Power '
          'from this use of the Power Up Maneuver. You may then use the Basic '
          "Attack Maneuver, but if you do, you must target your 'Marked' "
          'Opponent with that Attacking Maneuver.',
    ),
  ),
  // ================================================================ Giant Form ===
  TransformationDef(
    name: 'Giant Form',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    aspects: [
      'Graded',
      'Growth (Level G)',
    ],
    // AMB (FO/TE) is G(T) — set by Giant Form's Grade (3 Grades).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.tenacity:
          TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Accelerated Growth',
        description: 'You have the ability to increase in size at will, or '
            'return to your original size.\n'
            '(1)-[Passive]: Increase the Dice Category of your Punching Down '
            'Extra Dice by 1 Dice Category.\n'
            '(2)-[Passive]: This Transformation gains the Armored Aspect if '
            'your Size Category is Gigantic or higher.\n'
            '(3)-[1/Round]: If your Size Category is Enormous or higher, you '
            'may use the Sudden Stop Maneuver without spending a Counter '
            'Action.\n'
            '(4)-[Graded]: This Transformation has 3 Grades. Each Grade '
            'increases the Stress Test Requirement by 3, increases your Growth '
            'Aspect by 1 level, and sets your Attribute Modifier Bonuses as '
            'shown on the table above.',
      ),
      TransformationTrait(
        name: 'Battlefield Titan',
        description: 'You aim to be the biggest problem on the battlefield, '
            'literally and figuratively.\n'
            '(1)-[Triggered, 1/Round]: If you are targeted by an Attacking '
            'Maneuver and do not use any Counter Maneuvers in response to that '
            'Attacking Maneuver, increase your Soak Value by G(T) for the '
            'duration of that Attacking Maneuver.\n'
            '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver '
            'against an Opponent(s), they qualify for Punching Down on this '
            'Attacking Maneuver regardless of their Size Category. If they '
            'would already qualify for Punching Down, increase the Wound Roll '
            "for calculating that Opponent's Damage Calculation by G(T).",
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Giant Assault',
      description: 'Your massive bulk allows you to withstand blows and dish '
          'them out with great force.\n'
          '(1)-[Triggered/Transform]: Increase your Wound Rolls and Soak '
          'Value by G(T) until the start of your next turn. Additionally, '
          'until the end of your turn, all of your qualifying Signature '
          'Techniques gain the Intense Blast Advantage.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Super Giant Form',
      description: 'You are extremely adept at manipulating your size and '
          'making use of that increased bulk in combat.\n'
          '(1)-[Permanent]: You gain access to the 4th Grade of Giant Form.\n'
          '(2)-[Passive]: The Growth Aspect for Giant Form can reach up to 4 '
          'levels.\n'
          '(3)-[Passive]: Increase your Damage Reduction by 1/2 (rounded up) '
          'of G(T).\n'
          '(4)-[Passive]: Double the bonus from the 1st effect of Accelerated '
          'Growth.\n'
          '(5)-[Passive]: The 1st effect of Battlefield Titan loses its '
          '[1/Round] Keyword.',
      automation: [
        // (3) +ceil(G/2)(T) Damage Reduction.
        RaceTraitAutomation(
          affectedStats: [AffectedStat.damageReduction],
          coefficient: 1,
          tierScaling: TierScaling.current,
          perTransformationGrade: true,
          fractionDenominator: 2,
          roundUp: true,
        ),
      ],
    ),
  ),
  // ================================================================= Juggernaut ===
  TransformationDef(
    name: 'Juggernaut',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 14,
    aspects: [
      'Armored',
      'Power High (LV2)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Unstoppable Force',
        description: 'Whenever you charge into battle, nothing can keep you '
            'from your target.\n'
            '(1)-[Triggered/Transform, Triggered/Start of Turn]: Target an '
            'Opponent. You gain the Compelled Combat Condition with that '
            'Opponent as your target until the end of your turn.\n'
            "(2)-[Passive]: While you're suffering from the Compelled Combat "
            'Condition, increase your Strike Rolls and Might by 1(T).\n'
            "(3)-[Passive]: While you're suffering from the Compelled Combat "
            'Condition, increase your Wound Rolls by 1/4 (rounded up) of your '
            'Soak Value.',
        automation: [
          // (2) While suffering the Compelled Combat Condition (tracked in
          // the Conditions list): +1(T) Strike Rolls and Might.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike, AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedConditionActive,
            conditionStateName: 'Compelled',
          ),
        ],
      ),
      TransformationTrait(
        name: 'Immovable Object',
        description: 'When you stand your ground, you are impossible to '
            'move.\n'
            "(1)-[Passive]: If an Opponent's effect would move you, halve the "
            'amount of Squares you would move.\n'
            '(2)-[Triggered]: If you use the Defend Maneuver in response to an '
            'Attacking Maneuver, increase your Soak Value by 2(bT) for the '
            'duration of that Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: If you are hit by an Attacking '
            'Maneuver that deals Damage less than 1/4 of your Maximum Life '
            'Points, reduce the amount of Damage you receive to 0.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Unending Vigor',
      description: 'You are able to take hit after hit without taking any '
          'damage.\n'
          '(1)-[Triggered/Transform]: Halve all Damage you take and increase '
          'your Wound Rolls by 2(T) until the end of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Walking Tank',
      description: 'You are impossible to ignore and even more impossible to '
          'stop.\n'
          '(1)-[Permanent]: This Transformation loses the Power High Aspect.\n'
          '(2)-[Passive]: You do not need to Ki Wager, nor do you lose Life '
          'Points through the effects of the Compelled Combat Condition.\n'
          '(3)-[Passive]: Increase your Soak Value by 2(bT) against the '
          'Attacking Maneuvers made by Characters who are Compelled with you '
          'as their target.\n'
          '(4)-[Passive]: Increase your Wound Rolls by 2(T) if the only '
          'target for that Attacking Maneuver is a Compelled Opponent with '
          'you as their target.\n'
          '(5)-[Triggered]: When you target an Opponent through the first '
          'effect of Unstoppable Force, make a Clash (Corporeal vs '
          'Corporeal/Morale) against that Opponent. If you win, they gain the '
          'Compelled Combat Condition with you as their target until the end '
          'of their next turn.',
      // (3)/(4) are Opponent-Compelled-dependent — reference text only.
    ),
  ),
  // ================================================================== Kaioken ===
  TransformationDef(
    name: 'Kaioken',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 6,
    aspects: [
      'Graded',
      'Heartbeat (LV3)',
      'High Speed',
      'Enhanced Save (Impulsive)',
      'Glowing',
      'Straining',
    ],
    // AMB (AG/FO/MA) is `*` (Grade-set — Kaioken Grades table, Exponential
    // Power): Grade 1→1(T), 2→1(T), 3→2(T). Auto-applied by the current Grade.
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [1, 1, 2]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 1, 2]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 1, 2]),
    },
    traits: [
      TransformationTrait(
        name: 'Exponential Power',
        description: 'You possess the ability to greatly increase your power, '
            'but for great power, there is always a great cost.\n'
            '(1)-[1/Round]: During your turn, you may use the Movement '
            'Maneuver as an Instant Maneuver.\n'
            '(2)-[Passive]: Increase your Wound Rolls by 1/2 (rounded up) of '
            'G(T).\n'
            "(3)-[Passive, Ruling]: Increase your Combat Rolls by the 'Kaioken "
            "Dice'. Your Kaioken Dice is decided by the Grade of Kaioken, "
            'detailed in the Kaioken Grades table below.\n'
            '(4)-[Graded]: Kaioken has 3 Grades. Each Grade after the first '
            'increases the Stress Test Requirement by 2; sets the Kaioken '
            'Dice; sets the AMB (AG/FO/MA) to the amount listed; and has a '
            'Life Point Cost you must pay to use any Attacking Maneuver. Grade '
            '(multiplier | Kaioken Dice | AMB AG/FO/MA | Life Point Cost): '
            '1 (x2 | N/A | 1(T) | 2(bT)); 2 (x3 | 1d4 | 1(T) | 3(bT)); '
            '3 (x4 | 1d4 | 2(T) | 4(bT)).',
        automation: [
          // (2) +ceil(G/2)(T) Wound Rolls (G = the card's Grade stepper).
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationGrade: true,
            fractionDenominator: 2,
            roundUp: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Crimson Sacrifice',
        description: 'By burning away your life force, you turn that energy '
            'into pure power.\n'
            '(1)-[Passive]: You cannot regain Life Points.\n'
            '(2)-[Passive]: You do not suffer from Reduced Momentum if you are '
            'knocked through a Health Threshold due to paying the Life Point '
            'Cost of Kaioken.\n'
            '(3)-[Passive]: If you are using Kaioken in conjunction with a '
            'Form or Transcended Enhancement that does not possess the Perfect '
            'Ki Control Aspect, increase the Life Point Cost by 2(bT).\n'
            "(4)-[Triggered]: If you lose Life Points due to paying Kaioken's "
            'Life Point Cost, regain G(bT) Ki Points.\n'
            '(5)-[Triggered, 1/Encounter]: If you use an Ultimate Signature '
            'Technique, apply your Kaioken Dice an additional time to the '
            'Strike and Wound Roll of that Attacking Maneuver. Additionally, '
            'increase the Wound Roll of that Attacking Maneuver by G(T).',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Scarlet Multiplier',
      description: 'The instantaneous burst of strength you get when '
          'activating this power is enough to overwhelm most opponents.\n'
          '(1)-[Triggered/Transform]: You may use the Power Up Maneuver, '
          'Movement Maneuver, or Basic Attack Maneuver as an Out-of-Sequence '
          'Maneuver. If you do, regain Life and Ki Points equal to 5x the Life '
          'Point Cost for this Grade of Kaioken (before any reductions) - '
          'ignoring the first effect of Crimson Sacrifice.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Deep Red',
      description: 'The brilliant scarlet flames that encompass you now answer '
          'to your whims.\n'
          '(1)-[Permanent]: You gain access to the 4th and 5th Grades of '
          'Kaioken.\n'
          '(2)-[Permanent]: If you are in the Entrusted State, you gain access '
          'to the 6th Grade of Kaioken.\n'
          '(3)-[Passive]: While in the 4th Grade or higher of Kaioken, '
          'Kaioken has its Attribute Modifier Bonus (IN) increased by 1(T).\n'
          '(4)-[Passive]: Reduce the Life Point Cost of all Kaioken Grades by '
          '1(bT).\n'
          '(5)-[Automatic]: If you end your turn in the 6th Grade of Kaioken, '
          'you must use the Transformation Maneuver to enter a lower Grade of '
          'Kaioken as an Out-of-Sequence Maneuver.\n'
          '(6)-[Triggered/Entrusted]: Use the Transformation Maneuver as an '
          'Out-of-Sequence Maneuver to enter the 6th Grade of Kaioken.\n'
          '(7)-[Triggered, 1/Encounter]: Upon being knocked through a Health '
          'Threshold by paying the Life Point Cost, you may trigger any '
          'effects that would normally be triggered as if it was the result '
          "of an Opponent's Attacking Maneuver.\n"
          'Mastered Kaioken Grades (multiplier | Kaioken Dice | AMB AG/FO/MA | '
          'Life Point Cost): 4 (x10 | 1d6 | 2(T) | 5(bT)); 5 (x20 | 1d8 | '
          '3(T) | 6(bT)); 6 (x100 | 1d10 | 4(T) | 7(bT)).',
    ),
  ),
  // ============================================================= Super Kaioken ===
  TransformationDef(
    name: 'Super Kaioken',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Kaioken',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 4,
    aspects: [
      'Graded',
      'Heartbeat (LV3)',
      'Glowing',
      'High Speed',
      'Enhanced Save (Impulsive/Cognitive)',
      'Peaked',
    ],
    // AMB (AG/FO/MA) is Grade-set: Grade 1→1(T), 2→2(T), 3→3(T).
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Multiplied Power',
        description: 'A blazing aura surrounds you, vastly multiplying your '
            'power and agility.\n'
            '(1)-[Passive]: If used in conjunction with a Transformation with '
            'the Perfect Ki Control Aspect, halve the Life Point Cost.\n'
            '(2)-[Permanent]: You can only enter this Transformation if it '
            'would be used in conjunction with another Transformation.\n'
            '(3)-[Automatic]: If you would leave a Transformation used in '
            'conjunction with this Transformation, leave this Transformation '
            'too.\n'
            '(4)-[Graded]: Super Kaioken has 3 Grades. Each Grade after the '
            'first increases the Stress Test Requirement by 2; increases the '
            'Tier of Power Extra Dice by the Categories listed; sets the AMB '
            '(AG/FO/MA); and has a Life Point Cost to use any Attacking '
            'Maneuver. Grade (multiplier | ToP Extra Dice | AMB AG/FO/MA | '
            'Life Point Cost): 1 (x2 | N/A | 1(T) | 2(bT)); 2 (x10 | +1 Dice '
            'Category | 2(T) | 4(bT)); 3 (x20 | +2 Dice Categories | 3(T) | '
            '6(bT)).',
      ),
      TransformationTrait(
        name: 'Power of a Heartbeat',
        description: 'Pushing your body to its limits, you increase both '
            'strength and speed at the cost of your own vitality.\n'
            '(1)-[Passive]: You cannot regain Life Points.\n'
            '(2)-[Passive]: You do not suffer from Reduced Momentum if you are '
            'knocked through a Health Threshold due to paying the Life Point '
            'Cost of Kaioken.\n'
            '(3)-[Passive]: Increase the Wound Rolls of your Signature '
            'Techniques by G(T).\n'
            "(4)-[Triggered, 1/Round]: If you are targeted by an Opponent's "
            'Attacking Maneuver, increase your Dodge Rolls by G(T) for the '
            'duration of that Attacking Maneuver.\n'
            '(5)-[Triggered/Power, 1/Encounter]: If you are below the Injured '
            'Health Threshold, use a Ki Surge.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Vermilion Explosion',
      description: 'In a brilliant burst of scarlet, your power explodes, '
          'multiplying rapidly in power.\n'
          '(1)-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. If you do, reduce the Life Point Cost for '
          'each Grade of Super Kaioken to 0 until the end of your turn.',
    ),
  ),
  // ================================================================== Ki Blade ===
  TransformationDef(
    name: 'Ki Blade',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Glowing',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Energy Weapon',
        description: 'The energy at your fingertips reforms into a weapon of '
            'your choosing.\n'
            '(1)-[Permanent, Ruling, Passive]: Upon gaining access to this '
            'Transformation, design a Physical Weapon with a Craftsmanship '
            'Grade of 5. This Weapon cannot be of the Shield Weapon Category, '
            'cannot gain the Transforming Weapon Weapon Quality, and it is '
            "known as your 'Ki Weapon'.\n"
            '(2)-[Passive]: While in this Transformation, your Ki Weapon is '
            'Integrated.\n'
            '(3)-[Automatic]: If your Ki Weapon is destroyed, leave this '
            'Transformation.\n'
            '(4)-[Passive]: Increase the Strike and Wound Rolls of Attacking '
            'Maneuvers made with your Ki Weapon by 1(T).\n'
            '(5)-[Passive]: All of your Physical Signature Techniques gain the '
            'Weapon Assisted Advantage.\n'
            '(6)-[Triggered, 1/Round]: If you deal Damage to an Opponent with '
            'an Attacking Maneuver, you may use the Basic Attack Maneuver as '
            'an Out-of-Sequence Maneuver. This Attacking Maneuver must be made '
            'with your Ki Weapon.\n'
            '(7)-[Triggered, 1/Encounter]: If you use a Signature Technique '
            'with your Ki Weapon, increase the Damage Category of that '
            'Attacking Maneuver by 1 Category.',
      ),
      TransformationTrait(
        name: 'Aura Slide',
        description: "You easily slip past your enemies' defenses, striking "
            "where they're most vulnerable.\n"
            '(1)-[Passive]: Reduce the Critical Target of the Strike and Wound '
            'Rolls made as part of an Attacking Maneuver that uses your Ki '
            'Weapon by 1.\n'
            '(2)-[Passive]: Increase the Wound Rolls of an Attacking Maneuver '
            'that you scored a Critical Result on the Strike and/or Wound Roll '
            'by 2(T).\n'
            '(3)-[Triggered, 1/Round]: If you use a Physical Attack, you may '
            'apply the Charging Assault Advantage to that Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you score a Critical Result on '
            'the Strike or Wound Roll of an Attacking Maneuver that uses your '
            'Ki Weapon, you may apply an Energy Charge to that Attacking '
            'Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Instant Severance',
      description: 'As your energy takes the shape of a weapon, you attack '
          'without wasted time, slicing through your enemies with aggressive '
          'momentum.\n'
          '(1)-[Triggered/Transform]: Use the Movement Maneuver as an '
          'Out-of-Sequence Maneuver. If you end this movement on a Square '
          'adjacent to an Opponent, you may then use the Basic Attack Maneuver '
          'as an Out-of-Sequence Maneuver, but you must target that Opponent '
          'with this Attacking Maneuver and it must be an Attacking Maneuver '
          'that uses your Ki Weapon. On this Attacking Maneuver, score a '
          'Critical Result on both the Strike and Wound Roll - regardless of '
          'the Natural Result.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Focused Blade',
      description: 'By creating your own weapon, you have achieved the '
          'ultimate goal of any swordsman: treating your weapon as an '
          'extension of yourself.\n'
          '(1)-[Permanent]: Ki Blade gains the Heartbeat (LV2) Aspect.\n'
          '(2)-[Passive]: Increase the Natural Result of your Strike Rolls '
          'made with your Ki Weapon by 1.\n'
          '(3)-[Triggered, 1/Round]: If you score a Critical Result on the '
          'Wound Roll of an Attacking Maneuver made with your Ki Weapon, apply '
          'your Extra Dice from scoring a Critical Result twice to that Wound '
          'Roll.\n'
          '(4)-[Triggered/Transform]: You may apply the Dimension Blade Weapon '
          'Quality to your Ki Weapon without taking up a Quality Slot.',
    ),
  ),
  // ======================================================= Magic Manifestation ===
  TransformationDef(
    name: 'Magic Manifestation',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'Access to the Magic Trick Special Maneuver',
    aspects: [
      'Enhanced Save (Cognitive)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Hocus Pocus',
        description: 'You are able to twist and shape your magical energy, '
            'using it in unique ways.\n'
            '(1)-[Passive]: The Magic Trick Maneuver becomes an Instant '
            'Maneuver.\n'
            '(2)-[Passive]: Increase the Skill Bonus of your Use Magic Skill '
            'by 2.\n'
            '(3)-[Passive]: Increase the Strike and Wound Rolls of your Magic '
            'Attacks by 1(T).\n'
            '(4)-[Passive]: Reduce the Ki Point Cost of your Magical Unique '
            'Abilities by 1(T).\n'
            '(5)-[Triggered]: If you win a Clash against an Opponent through '
            'the effects of the Magic Trick Maneuver, reduce the Life Points '
            'of that Opponent by 1/2 of your Magic Modifier.\n'
            '(6)-[Triggered, 1/Encounter]: If you win a Clash against an '
            'Opponent through the effects of the Magic Trick Maneuver, '
            'maximize your stacks of Alakazam.',
      ),
      TransformationTrait(
        name: 'Abracadabra',
        description: 'You are able to mix various kinds of magic together or '
            'wield your magic in unorthodox ways.\n'
            '(1)-[Triggered, Resource]: If you use the Magic Trick Maneuver, '
            'gain a stack of Alakazam (max. 3).\n'
            '(2)-[Triggered, 1/Round]: When you use a Magic Attack, spend an '
            'Alakazam Point to add a single Advantage with a TP cost of up to '
            '10 TP to that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Round]: When you use a Magic Attack, spend an '
            'Alakazam Point to apply an Energy Charge to that Maneuver.\n'
            '(4)-[Triggered, 1/Round]: When you engage in a Clash that uses '
            'your Might or Saving Throws, you may spend a stack of Alakazam to '
            'increase your Dice Score for that Clash by 1(T).\n'
            '(5)-[Triggered, 1/Round]: When you engage in a Clash that uses '
            'your Use Magic Skill, you may spend a stack of Alakazam to roll '
            'for that Clash twice and take the highest result.\n'
            '(6)-[Triggered, 1/Encounter]: When you use a Magical Unique '
            'Ability, you can spend any number of Alakazam stacks. For each '
            'Alakazam stack spent, reduce the Ki Point Cost of that Unique '
            'Ability by 4(T).\n'
            '(7)-[Triggered, 1/Encounter]: When you use the 3rd effect of '
            'Abracadabra, you may spend any number of Alakazam stacks to gain '
            'an equal number of Energy Charges, instead of its usual effects.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Presto Change-o',
      description: 'Your magical energy leaps to your fingertips, ready to use '
          'instantly.\n'
          '(1)-[Triggered/Transform]: Maximize your stacks of Alakazam. Until '
          'the start of your next turn, increase the Dice Score of your use '
          'Magic Checks by 1d4.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Salagadoola Mechicka Boola',
      description: 'Manifesting your full magical potential now requires nary '
          'a thought.\n'
          "(1)-[Permanent]: Magic Manifestation's Attribute Modifier Bonus "
          '(AG/MA) is increased by 1(T).\n'
          '(2)-[Passive]: The Magic Trick Maneuver becomes [2/Round].\n'
          '(3)-[Passive]: You may use the Magic Trick Maneuver to target '
          'Characters outside of your Melee Range with its effects. Those '
          'Characters must not be at Long Range.\n'
          '(4)-[Triggered]: If you target an Ally with the 2nd effect of the '
          'Magic Trick Maneuver and they lose the Clash, you may apply the 3rd '
          'effect of the Magic Trick Maneuver as well.\n'
          '(5)-[Triggered]: If you inflict the Impaired Combat Condition to an '
          'Opponent through the effects of the Magic Trick Special Maneuver, '
          'you may use the Basic Attack Maneuver as an Out-of-Sequence '
          'Maneuver. This Attacking Maneuver must target that Opponent.',
    ),
  ),
  // ==================================================================== Mushin ===
  TransformationDef(
    name: 'Mushin',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Innate State (Mindful)',
      'Mindful',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Serene Heart',
        description: "Your mind is crystal clear, and doesn't interfere with "
            'the movement of your body.\n'
            '(1)-[Passive]: Ignore all Health Threshold Penalties while in the '
            'Zen or Tranquil levels of the Mindful State.\n'
            '(2)-[Passive]: Increase your Strike and Dodge Rolls by 1(T) while '
            'you are not suffering from any Health Threshold Penalties.\n'
            '(3)-[Automatic]: If you are hit and take Damage from an Attacking '
            'Maneuver, return to the Calm level of the Mindful State - exiting '
            'any higher levels.\n'
            '(4)-[Triggered/Start of Turn]: If you have not taken Damage from '
            'an Attacking Maneuver since the end of your last turn, enter the '
            'next level of the Mindful State until you leave this '
            'Transformation.\n'
            '(5)-[Triggered, 1/Encounter]: If you are targeted by an Attacking '
            'Maneuver while below the Injured Health Threshold, and the '
            'attacking Character is not in the Determined State, you may '
            'automatically succeed at your Dodge Roll for that Attacking '
            'Maneuver.',
        automation: [
          // (2) While suffering no Health Threshold Penalties: +1(T) Strike
          // and Dodge Rolls.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike, AffectedStat.dodge],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNoHealthThresholdPenalties,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Calm Counter',
        description: 'Thanks to muscle memory, your body uses your martial '
            'arts techniques on its own, allowing you to effortlessly move '
            'with unmatched grace.\n'
            '(1)-[Passive]: Increase the Natural Result of your Strike and '
            'Dodge Rolls by 1 if it is not your turn.\n'
            '(2)-[Passive]: While in the Tranquil level of the Mindful State, '
            'you automatically win all Clashes initiated by another character '
            'that uses your Cognitive or Morale Saving Throw.\n'
            '(3)-[Passive]: Increase your Strike and Dodge Rolls by 1(T) for '
            'the duration of any Attacking Maneuver made through the Exploit '
            'Maneuver that targets you.\n'
            '(4)-[Triggered]: If you spend a Counter Action, regain 2(bT) Ki '
            'Points.\n'
            '(5)-[Triggered/Transform, Triggered/Start of Combat Round]: Gain '
            '1 Counter Action.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Deep Breath',
      description: 'With serenity and peace in your heart, you bar emotion '
          'from controlling you, allowing you to take the necessary actions to '
          'survive and win.\n'
          '(1)-[Triggered/Transform]: Use Combat Recovery as an Out-of-'
          'Sequence Maneuver as if you spent 3 Actions. If you are not hit by '
          'an Attacking Maneuver made through the Exploit Maneuver in response '
          'to this use of Combat Recovery, enter the Tranquil level of the '
          'Mindful State until the end of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Self-Mastery',
      description: 'Your absolute calm increases your speed and accuracy, '
          'giving you unparalleled fluidity in combat.\n'
          '(1)-[Passive]: Ignore the 3rd effect of Serene Heart.\n'
          '(2)-[Passive]: Ignore the second effect of the Calm level of the '
          'Mindful State.\n'
          '(3)-[Triggered, 1/Round]: If you use the Combat Recovery Maneuver '
          'and are not hit by an Attacking Maneuver made through the Exploit '
          'Maneuver in response to that Maneuver, enter the next level of the '
          'Mindful State.\n'
          '(4)-[Automatic]: If you are knocked through a Health Threshold and '
          'fail the Steadfast Check, return to the Calm level of the Mindful '
          'State - exiting any higher levels.',
    ),
  ),
  // ================================================================ Nimbus Pro ===
  TransformationDef(
    name: 'Nimbus Pro',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: 'Nimbus Pro can only be obtained through the effects of '
        'the Nimbus Buddy',
    aspects: [
      'Enhanced Save (Impulsive)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Cloud Combat',
        description: 'The extreme speed of the Flying Nimbus Cloud allows you '
            'to dominate the battlefield.\n'
            '(1)-[Constant]: Upon your Nimbus Buddy becoming Active, you may '
            'use the Transformation Maneuver as an Out-of-Sequence Maneuver to '
            'enter this Transformation.\n'
            '(2)-[Automatic]: If you fail a Steadfast Check, immediately leave '
            'this Transformation and dismiss the Nimbus Buddy.\n'
            '(3)-[Passive]: You cannot dismiss the Nimbus Buddy.\n'
            '(4)-[Passive]: Your Opponent cannot target your Nimbus Buddy with '
            'Called Shots.\n'
            '(5)-[Passive]: Increase the Strike and Wound Rolls of your '
            'Attacking Maneuvers by 1(T).\n'
            '(6)-[Triggered, 1/Round]: If you move to a Square adjacent to an '
            'Opponent through the Nimbus Buddy, you may use the Basic Attack '
            'Maneuver as an Out-of-Sequence Maneuver. If you do, you must '
            'target that Opponent with that Attacking Maneuver.',
        automation: [
          // (5) +1(T) Strike and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Nimbus Glide',
        description: 'You are able to zoom around the battlefield on your '
            'Flying Nimbus Cloud as you attack!\n'
            '(1)-[Passive]: If you have moved through the effects of the '
            'Nimbus Buddy this Combat Round, increase your Dodge Rolls by '
            '1(T).\n'
            '(2)-[Passive]: Your movement does not provoke the Exploit '
            'Maneuver.\n'
            '(3)-[1/Round]: You may use the Buddy Effect of the Nimbus Buddy '
            '(obtained from the Ride Buddy) as an Instant Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you use a Signature Technique during '
            "a Combat Round in which you've used the Buddy Effect of the "
            'Nimbus Buddy (obtained from the Ride Buddy), apply a rank of '
            'Power Shot to that Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you would be hit by an Attacking '
            'Maneuver, you may instead destroy your Nimbus Buddy and '
            'immediately exit this Transformation.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Pure of Heart Driveby',
      description: 'You surge forward on the Flying Nimbus, taking full '
          'advantage of its incredible speed to strike anywhere on the '
          'battlefield.\n'
          '(1)-[Triggered/Transform]: Move to any Square on the Battlefield. '
          'If you end this movement adjacent to an Opponent, you may use the '
          'Basic Attack Maneuver or Signature Technique Maneuver as an '
          'Out-of-Sequence Maneuver. This Attacking Maneuver must target that '
          'Opponent, but has its Ki Point Cost reduced to 0.',
    ),
  ),
  // ================================================================== Poisoner ===
  TransformationDef(
    name: 'Poisoner',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Cognitive)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Poisoning Strike',
        description: 'W\n'
            '(1)-[Passive]: Increase the Wound Rolls of Poisoned Weapons by '
            '1(T).\n'
            '(2)-[Passive]: Increase your Combat Rolls by 1(T) against targets '
            'with the Poisoned Combat Condition.\n'
            "(3)-[Passive]: Reduce the Critical Target of your Attacking "
            "Maneuver's Strike and Wound Rolls by 1 if all the targets of that "
            'Attacking Maneuver are suffering from the Poisoned Combat '
            'Condition.\n'
            '(4)-[Triggered, Ruling, 1/Round]: If you use an Attacking '
            "Maneuver, you may declare it is 'Venomous'. If a Venomous "
            'Attacking Maneuver deals Damage to an Opponent, it inflicts the '
            'Poisoned Combat Condition until the start of your next turn.\n'
            '(5)-[Triggered, 1/Encounter]: If you use a Venomous Attacking '
            'Maneuver, you may make a Clash (Stealth/Bluff vs '
            'Intuition/Perception) against the target(s) of that Attacking '
            'Maneuver. If you win this Clash against an Opponent, they have '
            'the Impediment Combat Condition for the duration of this '
            'Attacking Maneuver.',
      ),
      TransformationTrait(
        name: 'Strong Poison',
        description: 'W\n'
            '(1)-[Passive]: Increase the amount of Life Points your Opponents '
            'lose from the Poisoned Combat Condition (that you inflicted) by '
            '1/2 of your Might.\n'
            '(2)-[Triggered]: If an Opponent has their Life Points reduced by '
            'the Poisoned Combat Condition, you may use the Basic Attack '
            'Maneuver as an Out-of-Sequence Maneuver. If you do, you must '
            'target that Opponent with that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: If an Opponent has their Life '
            'Points reduced below a Health Threshold by the effects of the '
            'Poisoned Combat Condition (that you inflicted), they are knocked '
            'Prone.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Surprise Poisoning',
      description: 'W\n'
          '(1)-[Triggered/Transform]: Use the Basic Attack Maneuver as an '
          'Out-of-Sequence Maneuver. This Attacking Maneuver cannot possess '
          'an AoE, but is Venomous. When you do, make a Clash (Stealth/Bluff '
          'vs Intuition/Perception) against the target of that Attacking '
          'Maneuver. If you win, you enter the Determined State for the '
          'duration of that Attacking Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Lethal Dose',
      description: 'W\n'
          '(1)-[Passive]: Increase the Wound Rolls of your Venomous Attacking '
          'Maneuvers by 1(T).\n'
          '(2)-[Passive]: You cannot gain the Poisoned Combat Condition.\n'
          '(3)-[Passive]: The 4th effect of Poisoning Strike loses the '
          '[1/Round] Keyword and gains the [2/Round] Keyword.\n'
          '(4)-[Triggered, 1/Round]: If you use a Signature Technique as a '
          'Venomous Attacking Maneuver, apply an Energy Charge to that '
          'Attacking Maneuver.\n'
          '(5)-[Triggered, 1/Encounter]: If you inflict the Poisoned Combat '
          'Condition on an Opponent, they gain the Impediment Combat Condition '
          'until the start of your next turn.',
    ),
  ),
  // ======================================================= Power of Destruction ===
  TransformationDef(
    name: 'Power of Destruction',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 6,
    stressTestRequirement: 18,
    prerequisiteText: 'Access to the God Ki Special State',
    aspects: [
      'God Ki',
      'Raging (LV2)',
      'Strainless',
      'Weakening',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Destroyer's Technique",
        description: 'You have learned a technique reserved for the Gods of '
            'Destruction.\n'
            '-[Permanent]: Reduce the Stress Test Requirement of this '
            'Transformation by x, where x is equal to triple the Tier of '
            'Power Requirement of the Transformation with the highest Tier of '
            'Power Requirement that is/would be used in conjunction with this '
            "Transformation. However, this Transformation's Stress Test "
            'Requirement is added completely onto any Transformation used in '
            'conjunction with it, rather than being halved, even when it has '
            'the lower Stress Test Requirement.\n'
            '-[Triggered]: After making your Wound Roll, you may set the '
            'Natural Result to 6. If this Transformation is used in '
            'conjunction with another Transformation, increase the value the '
            'Natural Result would be set to by x, where x is equal to 1/2 of '
            'the highest Tier of Power Requirement among the Transformation(s) '
            'used in conjunction with Power of Destruction.\n'
            '-[Triggered, 1/Round]: When making a Wound Roll, maximize the '
            'result of all Extra Dice rolled for that Wound Roll.\n'
            '-[Triggered, 1/Round]: When making a Strike Roll, score a '
            'Critical Result regardless of the Natural Result.\n'
            '-[Triggered/Threshold]: Enter the Raging State until the end of '
            'your next turn.\n'
            '-[Triggered]: When making an Attacking Maneuver, you may spend a '
            "number of Divine Ki Points equal to 1/2 of that Attacking "
            "Maneuver's Ki Point Cost to apply the Destruction Profile to that "
            'Attacking Maneuver.\n'
            'Destruction Profile (KP Cost 0): Any Damage inflicted by this '
            'Attacking Maneuver also reduces the Maximum Life Points of the '
            'Character who received that Damage by an equal amount until the '
            'end of the Combat Encounter. Additionally, this Attacking '
            'Maneuver gains 1 Energy Charge.',
      ),
      TransformationTrait(
        name: 'In the Realm of Destroyers',
        description: 'You have risen above your mundane station and achieved '
            'godly power previously unattainable by mortals.\n'
            '-[Passive]: Increase the Tier of Power Extra Dice for your Strike '
            'and Wound Rolls by 2 Dice Categories.\n'
            '-[Passive]: Your Soak Value cannot be reduced while your Divine '
            'Ki Points exceed 1/2 of the amount of Divine Ki Points you '
            "possessed at the start of the Combat Encounter. This effect "
            "doesn't apply to reductions from Damage Categories or the effects "
            'of Exceed Traits.\n'
            '-[Passive]: Depending on the amount of Divine Ki Points you '
            'possess in comparison to the amount you possessed at the start of '
            'the Combat Encounter: Between 3/4 and 1/2 - reduce the value the '
            'Natural Result of your Wound Roll would be set to through the '
            "second effect of Destroyer's Technique by 1; Between 1/2 and 1/4 "
            '- reduce it by 2; 1/4 or less - reduce it by 3 and ignore the '
            'first effect of In the Realm of Destroyers.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Destructive Cacophony',
      description: 'You force your body to move as you please, wielding the '
          'powerful energy of destruction to overwhelm your foes.\n'
          '-[Triggered/Transform]: Enter the Superior and Egotistical States '
          'until the end of your next turn. Ignore the third effect from '
          'Egotistical upon leaving the State through this effect.',
    ),
  ),
  // ================================================================ Powerhouse ===
  TransformationDef(
    name: 'Powerhouse',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    aspects: [
      'Graded',
      'Enhanced Save (Corporeal)',
    ],
    // AMB (FO) is Grade-set: Grade 1→1(T), 2→2(T), 3→3(T) (Powerhouse).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Muscular Proportions',
        description: 'You have total control over the musculature of your '
            'body, allowing you to increase and decrease it at will.\n'
            "(1)-[Ruling]: Your 'Muscle Power' is equal to 1(T) for every "
            'stack of Super Stack you possess.\n'
            '(2)-[Passive]: Increase your Soak Value by 1/2 (rounded up) of '
            'your Muscle Power.\n'
            '(3)-[Graded]: Powerhouse has 3 Grades. Each Grade increases the '
            'Stress Test Requirement by 2; sets your amount of Super Stack '
            '(you cannot exceed that number when in this Grade except through '
            'Power Burst); sets the AMB (FO); and applies additional Aspects '
            '(including all Aspects from lower Grades). Grade (Super Stacks | '
            'AMB FO | Aspects): 1 (1 | 1(T) | N/A); 2 (2 | 2(T) | Growth '
            '(LV1)); 3 (3 | 3(T) | Armored).',
      ),
      TransformationTrait(
        name: 'Uninhibited Strength',
        description: 'Your raw power overflows while using this technique, '
            'seeping into your attacks.\n'
            '(1)-[Passive]: Increase the Wound Rolls of your Signature '
            'Techniques by your Muscle Power.\n'
            '(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, you '
            'may ignore your Muscle Penalty for the duration of that Attacking '
            'Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: When using a Signature Technique, '
            'you may apply 3 ranks of the Power Burst Advantage to that '
            'Attacking Maneuver, ignoring the Prerequisites.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Power Bursting Beyond the Limit',
      description: 'With your overwhelming energy, you cannot help but to put '
          'your all into your first attack.\n'
          '(1)-[Triggered/Transform]: Use the Signature Technique Maneuver as '
          'an Out-of-Sequence Maneuver. If you do, you may apply 3 ranks of '
          'the Power Burst Advantage to that Attacking Maneuver, ignoring any '
          'Prerequisites.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Thick Muscle',
      description: "You've become the unequivocal master of pumping iron, the "
          "strongest man in the universe. It's time to Pump It Up.\n"
          '(1)-[Permanent]: This Transformation gains the Heartbeat (LV2) '
          'Aspect.\n'
          '(2)-[Passive]: While you have 1 stack of Super Stack, ignore your '
          'Muscle Penalty.\n'
          '(3)-[Passive]: While you are in the 3rd Grade of Powerhouse, apply '
          '1/4 of your Damage Attribute an additional time to the Wound Rolls '
          'of your Physical and Energy Attacks.\n'
          '(4)-[Triggered, 1/Round]: If you are targeted by an Attacking '
          'Maneuver, increase your Damage Reduction by your Muscle Power for '
          'the duration of that Attacking Maneuver.',
    ),
  ),
  // ========================================================== Super Powerhouse ===
  TransformationDef(
    name: 'Super Powerhouse',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Powerhouse',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Corporeal)',
      'Armored',
      'Growth (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Combat Powerhouse',
        description: 'You become so accustomed to your muscular bulk that you '
            'move as lithely as a slimmer, more agile warrior.\n'
            '(1)-[Passive]: Set your number of Super Stacks to 2. You cannot '
            'gain more than 2 stacks of Super Stack while in this '
            'Transformation, except through the effects of the Power Burst '
            'Advantage.\n'
            '(2)-[Passive]: For calculating your Muscle Penalty, and for all '
            'of your effects, you only count as possessing a single Super '
            'Stack.\n'
            '(3)-[Passive]: When calculating your Speed, use the higher of '
            'your Force and Agility Modifiers.\n'
            '(4)-[Triggered, 1/Round]: If you make an Attacking Maneuver of '
            'the Physical or Energy Foundation, you can apply the Charging '
            'Assault Advantage to that Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver that possesses the Charging Assault Advantage, '
            'apply the bonus to your Wound Roll from Charging Assault an '
            'additional time.',
      ),
      TransformationTrait(
        name: 'Pain Train',
        description: 'Your glorious muscles make you even more deadly when the '
            'enemy is in close proximity.\n'
            '(1)-[Passive]: While you are within the Melee Range of an '
            'Opponent, increase your Might, Wound Rolls, and Soak Value by '
            '1(T).\n'
            '(2)-[Passive]: If an Opponent within your Melee Range initiates a '
            'Skill Clash against you, increase your Skill Bonuses by 1 for the '
            'duration of that Clash.\n'
            '(3)-[Passive]: If an Opponent within your Melee Range initiates a '
            'Clash that uses your Saving Throws against you, increase your '
            'Saving Throws by 1(T) for the duration of that Clash.\n'
            '(4)-[1/Round]: If an Opponent within your Melee Range targets you '
            'with an Attacking Maneuver, you may use the Direct Hit option of '
            'the Defend Maneuver as an Out-of-Sequence Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Surprising Speed',
      description: 'Despite your heavily-inflated musculature, you move faster '
          'than the eye can see.\n'
          '(1)-[Triggered/Transform]: You may use the Basic Attack Maneuver or '
          'Signature Technique Maneuver to use an Attacking Maneuver of the '
          'Blitz Profile as an Out-of-Sequence Maneuver. If you do, you are in '
          'the Determined State for the duration of that Attacking Maneuver '
          'and if you deal Damage to an Opponent with that Attacking Maneuver, '
          'that Opponent gains the Guard Down Combat Condition until the end '
          'of your turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Bigger and Badder',
      description: 'Your massive muscles grow even bulkier, but with your '
          'refined control, you see no change in mobility.\n'
          '(1)-[Passive]: Treat your Size Category as if it is 1 smaller for '
          'calculating your Defense Value from your Size Category and for the '
          'effects of Punching Up.\n'
          '(2)-[Triggered/Power, 1/Round]: Make a Stress Test, but reduce the '
          'Dice Score of your Stress Test by 2. If you succeed, you enter the '
          'Power Flex Special State until you leave this Transformation. If '
          'you fail, you do not suffer from Stress Exhaustion, but gain the '
          'Fatigued Combat Condition until the start of your next turn.\n'
          'Power Flex Special State: (1) Set your number of Super Stacks to 3. '
          '(2) If you use the Direct Hit option of the Defend Maneuver, double '
          'the bonus to your Soak Value from your Super Stacks for the '
          'duration of that Maneuver. (3) Apply 1/4 of your Damage Attribute '
          'an additional time to the Wound Rolls of your Physical and Energy '
          'Attacks. (4) Super Powerhouse gains the Straining Aspect and has '
          'its Stress Test Requirement increased by 2. (5) [Triggered/Start of '
          'Turn] You may exit the Power Flex State.',
    ),
  ),
  // =========================================================== Prescient Sight ===
  TransformationDef(
    name: 'Prescient Sight',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'Access to the Precognition Unique Ability.',
    aspects: [
      'Enhanced Save (Cognitive/Impulsive)',
      'Exhausting',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Focusing of Abilities',
        description: 'You focus your mind on thoughts of what has yet to come, '
            'eschewing all else.\n'
            '(1)-[Passive]: Increase your Initiative by 2(T).\n'
            '(2)-[Passive]: You cannot use any Magical Unique Abilities except '
            'Precognition.\n'
            "(3)-[Passive]: Increase your Combat Rolls during other "
            "Character's turns by 1(T).\n"
            '(4)-[1/Round]: You may use a Counter Maneuver with an Action Cost '
            'of 1 Counter Action without spending that Counter Action.\n'
            '(5)-[Automatic/Start of Combat Round]: Use the Precognition '
            'Unique Ability as an Out-of-Sequence Maneuver.',
        automation: [
          // (1) +2(T) Initiative.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.initiative],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Battle Beyond Time',
        description: 'Focusing your foresight on a single target, you hone in '
            'on the immediate future to predict every move they will make '
            'against you.\n'
            '(1)-[Ruling]: A Character you have targeted with Precognition this '
            "Combat Round is known as your 'Foreseen Character'.\n"
            '(2)-[Passive]: All Maneuvers made by your Foreseen Character '
            'trigger your Exploit Maneuver.\n'
            '(3)-[Passive]: You do not suffer Diminishing Defense from '
            'Attacking Maneuvers made from your Foreseen Character.\n'
            '(4)-[Passive]: During the turn of your Foreseen Character, you '
            'may use any Standard Maneuver with an Action Cost of 1 Action as '
            'an Instant Maneuver. To use a Maneuver through this effect, you '
            'must still spend 1 Action.\n'
            '(5)-[Triggered, 1/Encounter]: If you are targeted by an Attacking '
            'Maneuver (that is not an Ultimate Signature) made by your '
            'Foreseen Character, you may automatically succeed at any Dodge '
            'Rolls made against this Attacking Maneuver. This effect cannot be '
            'triggered if the attacking Character is in the Determined State.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Certain Outcome',
      description: "Because you know what's going to happen next, your victory "
          'is already all but decided.\n'
          '(1)-[Triggered/Transform]: Use the Precognition Unique Ability if '
          "you haven't already. Then, enter the Determined State.",
    ),
    masteryTrait: TransformationTrait(
      name: 'Absolute Sight',
      description: 'As you hone your power of foresight, your prescience '
          'expands, protecting you from additional threats.\n'
          '(1)-[Permanent]: Prescient Sight loses the Exhausting and Draining '
          'Aspects.\n'
          '(2)-[Passive]: Double the bonus from the 3rd effect of Focusing of '
          'Abilities.\n'
          '(3)-[Passive]: You cannot gain the Guard Down Combat Condition.\n'
          '(4)-[Triggered, 1/Encounter]: When you use the Burst Limit for '
          'Prescient Sight, enter the Surging State until the start of your '
          'next turn. Your Focus is your Foreseen Character.',
    ),
  ),
  // ============================================================= Sparking Aura ===
  TransformationDef(
    name: 'Sparking Aura',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Prelude',
      'Glowing',
      'Draining (LV2)',
      'Light Dependent',
      'Straining',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Strong Aura',
        description: 'The sheer strength of the energy flowing from your body '
            'is enough to overwhelm lesser fighters.\n'
            '(1)-[Permanent, Ruling, Passive]: Upon gaining access to this '
            "Transformation, select and gain access to an 'Aura Trait' while "
            'in this Transformation.\n'
            '(2)-[Ruling]: Every Aura Trait has at least 1 effect with a '
            "'Mastery' Keyword. That effect is not gained until Sparking Aura "
            'is Mastered.\n'
            '(3)-[Passive]: While you have 2+ stacks of Power, increase your '
            'Combat Rolls by 1(T).\n'
            'Select your Aura Trait below (each verbatim in the picker).',
        automation: [
          // (3) While 2+ Power stacks: +1(T) Combat Rolls.
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
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 2,
          ),
        ],
        optionGroups: [
          RaceTraitOptionGroup(label: 'Aura Trait', options: kSparkingAuraTraits),
        ],
      ),
      TransformationTrait(
        name: 'Powerful Aura',
        description: 'Your power surges, boosting all of your combat '
            'capabilities.\n'
            '(1)-[Permanent, Passive]: Upon gaining access to this '
            "Transformation, select and gain access to an 'Aura Trait' while "
            'you are in this Transformation and have access to this Trait.\n'
            '(2)-[Passive]: While you have 2+ stacks of Power, increase your '
            'Soak Value and Surgency by 1(T).\n'
            '(3)-[Triggered/Start of Turn]: Use the Power Up Maneuver as an '
            'Out-of-Sequence Maneuver.',
        automation: [
          // (2) While 2+ Power stacks: +1(T) Soak Value and Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 2,
          ),
        ],
        optionGroups: [
          RaceTraitOptionGroup(label: 'Aura Trait', options: kSparkingAuraTraits),
        ],
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Awakening Aura',
      description: 'As your burning flame of power ignites, the surge in your '
          'strength allows you to quickly overcome any obstacle in your '
          'path.\n'
          '(1)-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. Then, enter the Superior State until the '
          'start of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Perfected Aura',
      description: "With newfound control over your aura, you've minimized the "
          'wastefulness of your exuded energy.\n'
          '(1)-[Permanent]: Sparking Aura loses 1 level of the Draining Aspect '
          'and the Straining Aspect.',
    ),
  ),
  // ================================================================= Tactician ===
  TransformationDef(
    name: 'Tactician',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: 'You are not a Minion',
    aspects: [
      'Enhanced Save (Cognitive/Morale)',
    ],
    amb: {
      DbuAttribute.scholarship:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.personality:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Man with a Plan',
        description: 'Through genius strategy and quick wit, you deftly '
            'maneuver your Allies into key positions on the battlefield.\n'
            '(1)-[Passive]: Gain access to the Order Special Maneuver.\n'
            '(2)-[Passive]: Reduce your Combat Rolls and Soak Value by '
            '1(bT).\n'
            '(3)-[Passive]: Any Attacking Maneuver an Ally makes through your '
            'use of the Order Maneuver has its Strike and Wound Roll increased '
            'by 1/4 (rounded up) of your Scholarship or Personality Modifier '
            '(whichever is higher).\n'
            '(4)-[Passive]: All Allies within a Large Sphere AoE (centered on '
            'you) have their Defense Value increased by 1/4 (rounded up) of '
            'your Scholarship or Personality Modifier (whichever is higher).\n'
            '(5)-[Triggered]: If an Ally uses the Transformation Maneuver as a '
            'result of your Order Maneuver, increase their Stress Bonus by 2 '
            'for the duration of that Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If any Ally uses the Power Up '
            'Maneuver or Transformation Maneuver through your use of the Order '
            'Maneuver, they may enter the Superior State until the end of '
            'their turn.\n'
            'Order Maneuver [3/Round] (Instant Maneuver): Lose 1 Action, '
            'declare a Maneuver then target an Ally. At the start of that '
            "Ally's turn, for each time they were targeted by the Order "
            'Maneuver, they may agree to the Order (immediately undergoing the '
            'declared Action as an Out-of-Sequence Maneuver) or gain a Counter '
            'Action.',
        automation: [
          // (2) -1(bT) Combat Rolls and Soak Value (the Ally buffs are
          // manual).
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
      ),
      TransformationTrait(
        name: 'Power Sharing',
        description: 'You gather energy, not for yourself, but for your '
            'comrades to use on your behalf.\n'
            '(1)-[Passive]: You may treat your number of Actions spent on the '
            'Empower as if they were 1 higher for calculating its effects.\n'
            '(2)-[1/Round]: When an Ally uses the Signature Technique '
            'Maneuver, you may spend 1 Action to apply an Energy Charge to '
            'that Attacking Maneuver.\n'
            '(3)-[Triggered]: When an Ally uses the Power Up Maneuver, you may '
            'spend 1 Action to let them gain an additional stack of Power from '
            'that use of the Power Up Maneuver.\n'
            "(4)-[Triggered, 1/Round]: If you target an Ally with a Maneuver "
            "that's not an Attacking Maneuver, you may use the Empower "
            'Maneuver (as if you spent 1 Action) as an Out-of-Sequence '
            'Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'New Tactics',
      description: 'Through a surge of brilliance, you share a genius plan '
          'with your companions as they all move in synchronicity.\n'
          '(1)-[Triggered/Transform]: You may use the Order Maneuver as an '
          'Out-of-Sequence Maneuver twice in sequence. You do not lose an '
          'Action from this use of the Order Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Tactical Intrigue',
      description: 'You stand tall behind your comrades as the one directing '
          'the battlefield, ensuring that all goes according to plan.\n'
          '(1)-[Passive]: Ignore the 2nd effect of Man with a Plan.\n'
          '(2)-[Passive]: Increase the Wound Rolls of your Allies by 1(T).\n'
          '(3)-[1/Round]: While in the Spectator State, you may use the Order '
          'Maneuver without losing an Action.\n'
          '(4)-[Triggered/Transform]: Enter the Spectator State.\n'
          '(5)-[Triggered, 1/Encounter]: If you target an Ally with the Order '
          'Maneuver, that Ally enters the Superior State until the start of '
          'your next turn.',
    ),
  ),
  // ================================================================ Time Power ===
  TransformationDef(
    name: 'Time Power',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'Access to the Time Freeze Unique Ability',
    aspects: [
      'Enhanced Save (Cognitive)',
      'Exhausting',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Time Control',
        description: 'You possess true mastery over time, allowing you to '
            'manipulate the very flow of time around your enemies.\n'
            '(1)-[Permanent]: You gain access to the Time Profile.\n'
            '(2)-[Passive]: You gain access to the Time Seal and Time '
            'Reversion Unique Abilities.\n'
            '(3)-[Triggered, 1/Encounter]: When using a Signature Technique, '
            'you may add the Multi-Profile Super Profile to that Attacking '
            'Maneuver, but you must select the Time Profile for the effects of '
            'Multi-Profile.\n'
            '(4)-[Automatic/Start of Turn]: If you are not in the God Ki '
            'Special State, reduce your Life Points by 1/10th of your Maximum '
            'Life Points.\n'
            'Time Profile (All Foundations, Standard, KP 10(T)): If you deal '
            'Damage to an Opponent with this Attacking Maneuver, they gain a '
            'stack of the Slowed Combat Condition until the end of your next '
            'turn and the Guard Down Combat Condition until the end of this '
            'turn.\n'
            'Time Seal Unique Ability — Ability Type: Magical; KP Cost: 12(T); '
            'Maneuver Type: Standard. Effect: Target an Opponent within your '
            'Melee Range. Make 3 Clashes (Cognitive vs '
            'Impulsive/Corporeal/Cognitive/Morale) against that Opponent. For '
            'each Clash you win, that Opponent gains a stack of the Slowed '
            'Combat Condition until the end of your next turn. If you win all '
            'three Clashes, your Opponent does not lose these stacks until the '
            'end of the Combat Encounter.\n'
            'Time Reversion Unique Ability — Ability Type: Magical; KP Cost: '
            '12(T); Maneuver Type: Counter. Effect: When a Character uses an '
            'Instant Maneuver or a Standard Maneuver with an Action Cost of 1 '
            'Action, you may use this Maneuver in response to it. Make a Clash '
            '(Cognitive vs Impulsive/Corporeal/Cognitive/Morale) against that '
            'character. If you win, their Maneuver is cancelled. Any Ki '
            'Points, Divine Ki Points, or Resources spent on that Maneuver are '
            'regained, but the Action Cost is still spent and this use counts '
            'to any limitations on how many times that Maneuver can be used in '
            'a Combat Round (but not per Combat Encounter).',
      ),
      TransformationTrait(
        name: 'The Frozen Time',
        description: 'You can halt time more effectively than anyone else, '
            'allowing you to dominate your opponents while they cannot fight '
            'back.\n'
            '(1)-[Passive]: Increase your Combat Rolls against Opponents with '
            'the Slowed Combat Condition by 1(T).\n'
            '(2)-[Passive]: Increase your Wound Rolls by 2(T) during a Frozen '
            'Turn.\n'
            '(3)-[Passive]: Gain an additional Action for your Frozen Turn '
            'through the effects of the Time Freeze Unique Ability.\n'
            '(4)-[Triggered, 1/Encounter]: During your Frozen Turn, if you '
            'knock an Opponent through a Health Threshold with an Attacking '
            'Maneuver, that Opponent automatically fails their Steadfast '
            'Check.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Time Has Stopped',
      description: 'You instantly halt the flow of time all around you, '
          'allowing you to act as you please.\n'
          '(1)-[Triggered/Transform]: Use the Time Freeze Unique Ability '
          'without paying the Ki Point Cost.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Dominion Over Time',
      description: 'Your mastery over the flow of time is so great that you '
          'can command it with merely a thought.\n'
          '(1)-[Permanent]: Time Power loses the Exhausting and Draining '
          'Aspects.\n'
          "(2)-[Passive]: Reduce the Ki Point Cost of any Unique Ability with "
          "'Time' in their name by 2(T).\n"
          '(3)-[Passive]: The 3rd effect of Time Control loses the '
          '[1/Encounter] Keyword and gains the [1/Round, 2/Encounter] '
          'Keywords.\n'
          '(4)-[Passive]: Ignore the 4th effect of Time Control.',
    ),
  ),
  // ========================================================= Ultra Supervillain ===
  TransformationDef(
    name: 'Ultra Supervillain',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 20,
    aspects: [
      'Variant (Evil Aura)',
      'Enhanced Save (Corporeal)',
      'Raging',
      'Rampaging (LV1)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Ultra Villainous (Villainous Form)',
        description: 'The intensely evil energy that courses through you '
            "grants you power unlike any you've ever felt before.\n"
            '(1)-[Passive]: If this Transformation is used in conjunction with '
            'a Form or Transcended Enhancement, halve its Attribute Modifier '
            'Bonuses.\n'
            '(2)-[Passive]: Your maximum amount of Evil Points is 20(bT).\n'
            '(3)-[Triggered, 1/Round]: If you spend 5(bT) Evil Points through '
            'the 2nd effect of Power of Evil, you may use the Energy Charge '
            'Maneuver as an Out-of-Sequence Maneuver after concluding that '
            'Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you spend 5(bT) Evil Points through '
            'the 3rd effect of Power of Evil, you may use a Healing Surge as '
            'an Out-of-Sequence Maneuver.\n'
            '(5)-[1/Encounter]: As an Instant Maneuver, you may spend 10(bT) '
            'Evil Points to use the Power Up Maneuver as an Out-of-Sequence '
            'Maneuver and then enter the Superior State until the end of your '
            'next turn.\n'
            '(6)-[Triggered, 1/Encounter]: If you trigger the 5th effect of '
            'Ultra Villainous, you may exit this Transformation, and if you '
            'do, you may then use the Transformation Maneuver as an '
            'Out-of-Sequence Maneuver.',
      ),
      TransformationTrait(
        name: 'Crystalline Evil',
        description: 'Darkness overwhelms your heart, clouding your mind and '
            'strengthening your body.\n'
            '(1)-[Triggered/Transform, Resource]: Gain 1 stack of Dark Crystal '
            '(max. 3).\n'
            '(2)-[Triggered/Power, 2/Encounter]: Spend 15(bT) Evil Points to '
            'gain a stack of Dark Crystal.\n'
            '(3)-[Passive]: For each stack of Dark Crystal you possess, '
            'increase your Stress Bonus by 1.\n'
            '(4)-[Passive]: For each stack of Dark Crystal you possess, '
            'increase your Wound Rolls, Damage Reduction, and Surgency by '
            '1(T).',
      ),
    ],
  ),
  // ====================================================== Unlimited Construction ===
  TransformationDef(
    name: 'Unlimited Construction',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: 'World Forging and Telekinesis Unique Abilities',
    aspects: [
      'Draining (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Instant Builder',
        description: 'You are skilled in the quick creation of weapons and '
            'other objects while in combat.\n'
            '(1)-[Passive]: You can use the Magical Materialization and World '
            'Forging Unique Abilities up to 3 times in each Combat Round.\n'
            '(2)-[1/Round]: You may use Magical Materialization or World '
            'Forging as an Instant Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If you create a Feature through the '
            'World Forging Unique Ability, you may apply any Feature Quality '
            'to that Feature.\n'
            '(4)-[Triggered, 1/Encounter]: If you trigger the 2nd effect of '
            'Instant Builder, you do not have to pay the Ki Point Cost of your '
            'chosen Unique Ability.',
      ),
      TransformationTrait(
        name: 'Craft Combat',
        description: 'With your ability to create new weapons at will, you '
            'make the most of each weapon with your attacks, breaking those '
            'weapons in the process.\n'
            '(1)-[Passive]: Increase the amount of Collision Damage you '
            'inflict by 1/2 of your Force or Magic Modifier (whichever is '
            'higher).\n'
            '(2)-[Passive]: If you move an Opponent through the effects of the '
            'Telekinesis Unique Ability, make a Clash (Cognitive vs '
            'Cognitive/Impulsive/Corporeal) against them. If you win, they '
            'gain the Guard Down Combat Condition until the end of this '
            'turn.\n'
            '(3)-[Triggered, 1/Round]: If you create a Weapon through Magical '
            'Materialization, you may make an Armed Attack through the Basic '
            'Attack Maneuver using that Weapon as an Out-of-Sequence '
            'Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you make an Armed Attack with a '
            'Weapon created through the Magical Materialization Unique Ability, '
            'you may choose to destroy that Weapon after the Attacking '
            'Maneuver has concluded. If you do, apply an Energy Charge to that '
            'Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you create a Feature through the '
            'World Forging Unique Ability, you may immediately use the '
            'Telekinesis Unique Ability as an Out-of-Sequence Maneuver (but '
            'you must target that Feature with this use of Telekinesis). This '
            'use of Telekinesis does not count towards its usual limited uses '
            'per Combat Round.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Creation Burst',
      description: 'Your magic bursts forward, instantly providing you the '
          'necessary tools for battle.\n'
          '(1)-[Triggered/Transform]: Use the Magical Materialization or World '
          'Forging Unique Ability as an Out-of-Sequence Maneuver three times '
          'in sequence. You do not pay Ki Points for any uses of the Magical '
          'Materialization or World Forging Unique Ability through this '
          'effect.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Infinite Assembly',
      description: 'Your continuous creation of new combat tools grows more '
          'efficient and less draining.\n'
          '(1)-[Permanent]: Unlimited Construction loses the Draining Aspect '
          'and gains the Perfect Ki Control Aspect.\n'
          '(2)-[Passive]: Reduce the Ki Point Cost of Magical Materialization '
          'and World Forging by 2(T).\n'
          '(3)-[Passive]: You can use Telekinesis up to 2 times per Combat '
          'Round.\n'
          '(4)-[Triggered, 1/Round]: When making an Attacking Maneuver, you '
          'may treat your Size Category as Gigantic for calculating Punching '
          'Down during that Attacking Maneuver.\n'
          '(5)-[Triggered, 1/Encounter]: If you would be hit by an Attacking '
          'Maneuver made through the Basic Attack Maneuver and that does not '
          'possess an AoE while you are adjacent to a Feature, you may shift '
          'the target of that Attacking Maneuver to that Feature.',
    ),
  ),
  // ============================================================= Weapon of Hope ===
  TransformationDef(
    name: 'Weapon of Hope',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 10,
    prerequisiteText: 'Weapon Master',
    aspects: [
      'Perfect Ki Control',
      'Dedicated',
      'Temporary (Level 3)',
      'Peaked',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Shining Beacon',
        description: 'The hopes, dreams, and fates of everyone rest on your '
            'shoulders.\n'
            '-[Automatic/Transform]: Select a Weapon you are wielding. That '
            'Weapon becomes Hope. If you would lose that Weapon or that Weapon '
            "would be Destroyed while you're in this Enhancement Power, you "
            'leave this Enhancement Power immediately.\n'
            '-[Passive]: All of your Armed Attacks made with Hope have their '
            'Damage Category increased by 1.\n'
            '-[Triggered]: If you are knocked through a Health Threshold, or '
            'knock an Opponent through a Health Threshold, an Ally can target '
            'you with the Empower Maneuver as an Out-of-Sequence Maneuver. '
            'Only one Ally can benefit from this effect at a time - go down '
            'the list of your allies in order of their Initiative and ask if '
            'they will use this effect or not each time this effect triggers.',
      ),
      TransformationTrait(
        name: "Everyone's Hope",
        description: 'With the energy entrusted to you by the people you '
            'represent, you become a powerful force to annihilate evil.\n'
            '-[Passive]: You can use Spirit Empowerment in conjunction with '
            'this Enhancement Power, even if you are already using this '
            'Enhancement Power in conjunction with another Transformation. '
            'Additionally, reduce the Stress Test Requirement for Spirit '
            'Empowerment by 2.\n'
            '-[1/Encounter, Resource]: When you use the Transformation '
            'Maneuver, you may attempt to enter Spirit Empowerment even if you '
            'lack the required amount of Lifeforce. If you attempt to, you '
            'must reduce your Ki Points (this does not count as spending for '
            'the sake of Capacity) by up to 30(bT) - min. 20(bT). Every 5(bT) '
            'Ki Points lost allows you to gain a stack of Lifeforce until you '
            'leave the Spirit Empowerment Enhancement Power.\n'
            '-[Automatic]: If you leave this Transformation, you also leave '
            'Spirit Empowerment if you are using it in conjunction with this '
            'Transformation.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'For the Future',
      description: 'In order to secure a future for yourself and everyone '
          'around you, you turn your own life force energy into power.\n'
          '-[Triggered/Transform]: Reduce your Life Points until you are '
          'knocked through the next Health Threshold (you do not suffer a '
          'Health Threshold Penalty for this effect and all of your effects '
          'that trigger on you passing that Health Threshold trigger as '
          'usual), then gain 3 Lifeforce.',
    ),
  ),
  // ============================================================ Explosive Power ===
  TransformationDef(
    name: 'Explosive Power',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Access to the Holding Back Maneuver',
    aspects: [
      'Transcendent',
      'Perfect Ki Control',
    ],
    // AMB is +1(bT) (base Tier of Power) — this app's base ToP equals current
    // ToP, so it is modelled as tierScaled.
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Efficiency is Power',
        description: 'By using less energy to make your attacks, you can '
            'funnel more energy into dealing damage with them.\n'
            '(1)-[Passive]: You may use your base Tier of Power instead of '
            'your current Tier of Power for the sake of Tier of Power '
            'Requirements for any Transformation used in conjunction with '
            'Explosive Power.\n'
            '(2)-[Passive]: When you apply Legend Realized, you may use your '
            'base Tier of Power instead of your current Tier of Power.\n'
            '(3)-[Passive]: While you have any number of Holding Back stacks, '
            'double the reduction to Ki Point Costs from Perfect Ki Control.\n'
            '(4)-[Passive]: While you possess a stack of Holding Back, '
            'increase your Surgency by 1(T).\n'
            '(5)-[Constant]: If you use the Holding Back Maneuver, you may use '
            'the Transformation Maneuver as an Out-of-Sequence Maneuver to '
            'enter this Transformation.\n'
            '(6)-[Triggered/Start of Turn]: While you possess a stack of '
            'Holding Back, regain 3(bT) Ki Points.\n'
            '(7)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you '
            'may apply a number of Energy Charges equal to 1/2 of your number '
            'of Holding Back stacks (min. 1) to that Attacking Maneuver.\n'
            '(8)-[Triggered, 1/Encounter]: If you lose all stacks of Holding '
            'Back, you may leave this Transformation and then use the '
            'Transformation Maneuver as an Out-of-Sequence Maneuver. If you '
            'do, increase the Dice Score of your Stress Test for this use of '
            'the Transformation Maneuver by 1/2 of the number of Holding Back '
            'stacks you lost (min. 1).',
        automation: [
          // (4) While 1+ tracked 'Holding Back' Resource stacks: +1(T)
          // Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Holding Back',
          ),
        ],
      ),
      TransformationTrait(
        name: 'Sudden Strength',
        description: 'You release your full power for a mere instant, giving '
            'your opponent no reaction time.\n'
            '(1)-[Triggered/Transform, Triggered/Start of Turn]: Gain 3 stacks '
            'of Power Explosion for each stack of Holding Back you possess.\n'
            '(2)-[Automatic/Start of Turn]: Before you apply any other effects '
            'that trigger at the start of your turn, lose all stacks of Power '
            'Explosion.\n'
            '(3)-[Triggered]: When you are targeted by an Attacking Maneuver, '
            'you may spend any number of Power Explosion stacks to ignore the '
            'effects of an equal number of Holding Back stacks for the '
            'duration of that Attacking Maneuver.\n'
            '(4)-[Triggered]: When you use an Attacking Maneuver, before you '
            'pay the Ki Point Cost for that Attacking Maneuver, you may spend '
            'any number of Power Explosion stacks to ignore the effects of an '
            'equal number of Holding Back stacks for the duration of that '
            'Attacking Maneuver.\n'
            '(5)-[Triggered]: If you are targeted by a Special Maneuver, a '
            'Unique Ability, the Grapple Maneuver, or must make a Grapple '
            'Check as the Grappled, you spend any number of Power Explosion '
            'stacks to ignore the effects of an equal number of Holding Back '
            'stacks for the duration of that Grapple Check or Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If you spend a number of Power '
            'Explosion stacks equal to your number of Holding Back stacks on '
            'the 3rd effect of Sudden Strength, increase your Soak Value by '
            '1(T) for each stack of Power Explosion spent for the duration of '
            'that Attacking Maneuver.\n'
            '(7)-[Triggered, 1/Encounter]: If you spend a number of Power '
            'Explosion stacks equal to your number of Holding Back stacks on '
            'the 4th effect of Sudden Strength, increase the Wound Roll of '
            'that Attacking Maneuver by 1(T) for each stack of Power Explosion '
            'spent.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Burst of Power',
      description: 'You can unleash your full power to move faster than the '
          'eye can see and pummel the opponent before they get a chance to '
          'react.\n'
          '(1)-[Triggered/Transform]: Trigger the 1st effect of Sudden '
          'Strength an additional time. Additionally, you may use the Basic '
          'Attack Maneuver as an Out-of-Sequence Maneuver. If you do, you may '
          'use your base Tier of Power (instead of your current Tier of Power) '
          'for the Strike and Wound Rolls of that Attacking Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Flash of Power',
      description: 'Like a flash of lightning, you unleash your full power and '
          'tamp it back down again in the same breath, using it only for the '
          'exact moment you need it.\n'
          '(1)-[Permanent]: Explosive Power gains the Heartbeat (LV2) '
          'Aspect.\n'
          '(2)-[Triggered]: If you enter this Transformation through the '
          'effects of the Heartbeat Aspect, you may ignore your stacks of '
          'Holding Back until you leave this Transformation.\n'
          '(3)-[Passive]: For the 1st effect of Sudden Strength, gain an '
          'additional stack of Power Explosion for each stack of Holding Back '
          'you possess.\n'
          '(4)-[Passive]: The 6th and 7th effects of Sudden Strength lose the '
          '[1/Encounter] Keyword and gain the [1/Round] Keyword.\n'
          '(5)-[Triggered/Power, 1/Encounter]: Gain 2 stacks of Power '
          'Explosion for each stack of Holding Back you possess.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Eruption of Power',
      description: 'Your power is even more explosive, making you seem like an '
          'ordinary person until you attack.\n'
          '(1)-[Permanent]: Explosive Power has its Attribute Modifier Bonus '
          '(AG/TE) increased by 1(bT).\n'
          '(2)-[Passive]: For the 1st effect of Sudden Strength, gain an '
          'additional stack of Power Explosion for each stack of Holding Back '
          'you possess.\n'
          '(3)-[Passive]: When using the 5th effect of Sudden Strength, '
          'instead of spending Power Explosion Stacks, treat it as if you '
          'spent your maximum number of Power Explosion stacks for its '
          'effects.\n'
          '(4)-[Passive]: You may spend stacks of Power as if they were 1 '
          'stack of Power Explosion for each stack of Holding Back you '
          'possess.\n'
          '(5)-[1/Round]: During your turn, you may use the Power Up Maneuver '
          'as an Instant Maneuver.',
    ),
  ),
  // ============================================================ Relaxed Warrior ===
  TransformationDef(
    name: 'Relaxed Warrior',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Explosive Power',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 20,
    prerequisiteText: 'You are not a Minion',
    aspects: [
      'Enhanced Save (All)',
      'Perfect Ki Control',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Constant 100%',
        description: 'When you stop holding yourself back, you have no trouble '
            'maintaining your full power efficiently.\n'
            '(1)-[Permanent]: You cannot enter this Transformation if you have '
            'any stacks of Holding Back.\n'
            '(2)-[Constant]: If you lose all of your Holding Back stacks, you '
            'may use the Transformation Maneuver to enter this Transformation '
            'as an Out-of-Sequence Maneuver.\n'
            '(3)-[Automatic]: If you use the Holding Back Maneuver, leave this '
            'Transformation. If you do, you may immediately enter the '
            'Explosive Power Enhancement.\n'
            '(4)-[Passive]: If this Transformation is not used in conjunction '
            'with another Transformation, increase its Attribute Modifier '
            'Bonuses (AG/FO/TE/MA) by 2(T) and its Attribute Modifier Bonus '
            '(IN) by 1(T).\n'
            '(5)-[Passive]: Increase the Natural Result of your Combat Rolls '
            'by 1.\n'
            '(6)-[Triggered/Start of Combat Round]: Gain an additional '
            'Standard Action and Counter Action.',
      ),
      TransformationTrait(
        name: 'Absolute Ki Control',
        description: "You don't expend energy until the last second, allowing "
            'you to utilize your power far more efficiently.\n'
            '(1)-[Passive]: Increase your Surgency by 2(T).\n'
            '(2)-[Passive]: Double the reduction to Ki Point Costs from the '
            'Perfect Ki Control Aspect.\n'
            '(3)-[Passive]: Increase the Wound Roll of any Attacking Maneuver '
            'you make with a Ki Wager by 1/4 of the amount of Ki Points spent '
            'on the Ki Wager.\n'
            '(4)-[Passive]: When making an Attacking Maneuver, you do not have '
            'to Ki Wager until you have seen the Dice Score of your Strike '
            'Roll for that Attacking Maneuver. You must still Ki Wager before '
            'the target(s) of your Attacking Maneuver make a Dodge Roll or any '
            'roll made through a Counter Maneuver in response to your '
            'Attacking Maneuver.\n'
            '(5)-[1/Encounter]: As a Standard Maneuver with an Action Cost of '
            '1 Action, use a Ki Surge.',
        automation: [
          // (1) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
        // (3): Wound +¼ of the Ki Points wagered.
        wagerWoundEffect: WagerWoundEffect(fractionOfWagerDen: 4),
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Nothing Wasted',
      description: 'By tightly controlling your movements, you ensure that not '
          'a single ounce of energy goes to waste.\n'
          '(1)-[Triggered/Transform]: Gain 2 Actions. Until the start of your '
          'next turn, all of your Attacking Maneuvers and Counter Maneuvers '
          'have their Ki Point Cost set to 0.',
    ),
  ),
  // ================================================================== God Aura ===
  TransformationDef(
    name: 'God Aura',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 20,
    aspects: [
      'Transcendent',
      'Enhanced Save (All)',
      'God Ki',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Godly Warrior',
        description: 'You expend your divine energy to empower yourself.\n'
            '(1)-[Permanent, Passive]: Upon gaining access to this '
            'Transformation, select a God Maneuver. You gain access to your '
            'selected God Maneuver while in this Transformation.\n'
            '(2)-[Passive]: If this Transformation is used in conjunction with '
            'a Form or Transcended Enhancement, halve its Attribute Modifier '
            'Bonuses.\n'
            '(3)-[Passive]: While in the Superior State, increase your Combat '
            'Rolls by 1(T).\n'
            '(4)-[Passive]: While in the Superior State, each Divine Ki Point '
            'counts as 2 for paying the Ki Point Costs of Attacking '
            'Maneuvers.\n'
            '(5)-[1/Round]: While in the Superior State, you may use the '
            'Defend Maneuver without spending a Counter Action.\n'
            '(6)-[Triggered/Threshold]: Regain 1/4 of your Maximum Divine Ki '
            'Points.\n'
            '(7)-[Triggered/Power, 1/Round]: Enter the Superior State until '
            'the start of your next turn.',
      ),
      TransformationTrait(
        name: 'Divine Assault',
        description: 'The godly power in your attacks gives you complete '
            'control over your energy, making every ounce of energy count.\n'
            '(1)-[Passive]: For any Attacking Maneuver that you have paid the '
            'Ki Point Cost of with Divine Ki Points, increase the Strike and '
            'Wound Rolls by 1(T) and 2(T) respectively.\n'
            '(2)-[Passive]: For any Signature Technique that you have paid the '
            'Ki Point Cost of with Divine Ki Points, apply an Energy Charge to '
            'that Attacking Maneuver.\n'
            '(3)-[Passive]: Increase the Wound Roll of any Attacking Maneuver '
            'you make with a Ki Wager made with Divine Ki Points by 1/2 of the '
            'amount of Divine Ki Points spent on the Ki Wager.\n'
            '(4)-[Triggered, 1/Round]: If you fail to hit an Opponent with an '
            'Attacking Maneuver in which you used Divine Ki Points to make a '
            'Ki Wager, regain those Divine Ki Points.\n'
            '(5)-[Triggered, 1/Encounter]: If you paid the Ki Point Cost for '
            'an Ultimate Signature Technique using your Divine Ki Points, you '
            'may treat your Health Threshold as if it was Critical for '
            'calculating the number of Energy Charges from your Ultimate '
            'Signatures.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Godly Confidence',
      description: 'Your supreme confidence is turned up to eleven as you '
          'unleash your divine might, showing up even other gods.\n'
          '(1)-[Triggered/Transform]: Enter the Superior State until the start '
          'of your next turn. If you do, regain 1/4 of your Maximum Divine Ki '
          'Points at the start of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Adjustment to Divine Power',
      description: 'You have acclimated to your overwhelming divine might.\n'
          '(1)-[Permanent]: God Aura loses the Draining Aspect.\n'
          '(2)-[Passive]: Ignore the 2nd effect of the Superior State.\n'
          '(3)-[Passive]: Increase the Dice Category of your Greater Dice by 1 '
          'Category.\n'
          '(4)-[Triggered/Start of Turn]: Regain 3(bT) Divine Ki Points.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Transcending Godhood',
      description: 'You have ascended to godly supremacy, becoming the '
          'greatest of the gods.\n'
          '(1)-[Permanent]: God Aura gains the Scaling (LV2) Aspect.\n'
          '(2)-[Permanent, Passive]: Upon gaining access to this Transcendent '
          'Trait, select a God Maneuver. You gain access to your selected God '
          'Maneuver while in this Transformation.\n'
          '(3)-[Passive]: Increase the Dice Category of your Greater Dice by 1 '
          'Category.\n'
          '(4)-[Passive]: While you are in the Surging State, increase the '
          'Dice Category of your Energy Charges by 1 Category.\n'
          '(5)-[Passive]: God Aura gains the Innate State (Superior) Aspect.\n'
          '(6)-[Passive]: The 7th effect of Godly Warrior and the effect of '
          'Godly Confidence may allow you to enter the Surging State instead '
          'of the Superior State.\n'
          '(7)-[Passive]: Reduce the Divine Ki Point Cost of your God '
          'Maneuvers by 1(T).',
    ),
  ),
  // ====================================================================== Hero ===
  TransformationDef(
    name: 'Hero',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Transcendent',
      'Enhanced Save (Morale)',
      'Battle Uniform',
      'Natural (LV1)',
    ],
    amb: {
      DbuAttribute.personality:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Unmitigated Champion of Justice',
        description: 'You are indisputably a hero, working in the name of the '
            'greater good.\n'
            '(1)-[Passive]: You gain access to the Hype Maneuver.\n'
            '(2)-[Passive]: While you are Hyped, increase your Combat Rolls '
            'and Soak Value by 1(T).\n'
            '(3)-[Passive]: While you have an Ally who is below the Injured '
            'Health Threshold, increase the Attribute Modifier Bonus '
            '(AG/FO/TE/MA/PE) of Hero by 1(T).\n'
            '(4)-[Triggered, 1/Encounter]: If you use the Hype Maneuver, after '
            'concluding that Maneuver, you may use the Basic Attack or '
            'Signature Technique Maneuver as an Out-of-Sequence Maneuver. If '
            'you do, you may use your Personality Modifier as the Damage '
            'Attribute for that Attacking Maneuver.\n'
            'Battle Uniform: Combat Clothing, Craftsmanship Grade 4 — see the '
            'site for its full apparel profile.',
        automation: [
          // (2) While Hyped (tracked as a 'Hyped' State): +1(T) Combat Rolls
          // and Soak Value.
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
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Hyped',
          ),
        ],
      ),
      TransformationTrait(
        name: 'Zero Tolerance for Evil',
        description: 'Your mission to protect the innocent means that you must '
            'stamp out villains wherever you find them.\n'
            '(1)-[Triggered, Resource]: When you use the Hype Maneuver, gain a '
            'Justice Point (max. 3).\n'
            '(2)-[Passive]: For each Justice Point you possess, gain 1(T) '
            'Damage Reduction.\n'
            '(3)-[Triggered, 1/Round]: When using the Signature Technique '
            'Maneuver, you may spend up to 3 Justice Points to shout its name '
            'heroically! If you do, apply an Energy Charge to that Attacking '
            'Maneuver for each Justice Point spent.\n'
            '(4)-[Triggered/Power, 1/Round]: Spend a Justice Point to gain an '
            'additional stack of Power through this use of the Power Up '
            'Maneuver.',
        automation: [
          // (2) +1(T) Damage Reduction per tracked 'Justice Point' Resource
          // stack.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perNamedResourceStack,
            resourceName: 'Justice Point',
          ),
        ],
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Transformation Pose',
      description: 'Your transformation sequence ends with a pose, role call, '
          "maybe sparks or explosions... It's just really cool.\n"
          '(1)-[Triggered/Transform]: Use the Hype Maneuver as an '
          'Out-of-Sequence Maneuver. If you do, maximize your Justice Points.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Defender of Truth, Protector of the Innocent!',
      description: 'With true heroic spirit and a charismatic smile, you '
          'defend the innocent with the power of truth and justice!!!\n'
          '(1)-[Passive]: While you are Hyped, increase the Dice Score of your '
          'Steadfast Checks by 1.\n'
          '(2)-[Passive]: While you are Hyped, increase the Wound Rolls of '
          'your Signature Techniques by 1(T).\n'
          '(3)-[1/Round]: You may convert 2 Justice Points into a Counter '
          'Action. This can be done at any point during the Combat Round, '
          'even during other Maneuvers.\n'
          '(4)-[Triggered/Start of Turn]: Regain x(bT) Ki Points for each '
          'Justice Point you possess.\n'
          '(5)-[Triggered/Defeated]: Spend any number of Justice Points. If '
          'you do, regain Life Points equal to your Personality Modifier for '
          'each Justice Point spent, and then you may use the Power Up '
          'Maneuver or Transformation Maneuver as an Out-of-Sequence Maneuver.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'The Great Hero!',
      description: 'You have become the greatest hero alive, saving countless '
          'lives.\n'
          "(1)-[Passive]: Increase Hero's Attribute Modifier Bonus (PE) by "
          '1(T).\n'
          '(2)-[Passive]: Increase your maximum number of Justice Points to '
          '6.\n'
          '(3)-[Passive]: Double the amount of Justice Points you gain through '
          'the 1st effect of Zero Tolerance for Evil.\n'
          '(4)-[Triggered/Power, 1/Round]: Make a Stress Test, ignoring the '
          'Natural Aspect, but reduce the Dice Score of your Stress Test by 4. '
          'If you succeed, you enter the Heroic Mindset Special State until '
          'you leave this Transformation. If you fail, you do not suffer from '
          'Stress Exhaustion, but gain the Impediment Combat Condition until '
          'the start of your next turn.\n'
          'Heroic Mindset Special State:\n'
          '(1)-[Passive]: Increase the Attribute Modifier Bonus (AG/FO/TE/MA) '
          'of Hero by 1(T).\n'
          "(2)-[Passive]: Increase Hero's Stress Test by 4 and Hero loses the "
          'Natural (LV1) Aspect.\n'
          "(3)-[Passive]: Hero's Battle Uniform has its Craftsmanship Grade "
          'become 5.\n'
          '(4)-[Triggered, 1/Round]: If you use the Hype Maneuver, all '
          'Opponents within a Huge Sphere AoE (centered on you) lose Life '
          'Points equal to your Personality Modifier.\n'
          '(5)-[Triggered, 1/Round]: If you use the Hype Maneuver, all Allies '
          'within a Huge Sphere AoE (centered on you) regain Ki Points equal '
          'to your Personality Modifier.\n'
          '(6)-[Triggered, 1/Encounter]: If you apply 3 Justice Points to an '
          'Ultimate Signature Technique through the 3rd effect of Zero '
          'Tolerance For Evil, you may apply the Complete Annihilation Super '
          'Profile to that Attacking Maneuver.',
    ),
  ),
  // =============================================================== Future Hero ===
  TransformationDef(
    name: 'Future Hero',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Hero',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Transcendent',
      'Enhanced Save (Morale)',
      'Battle Uniform',
      'Natural (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.personality:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Style of Justice',
        description: 'Whether you wield a powerful weapon that appears in your '
            'hands when you transform into your heroic state, or you pummel '
            'evil into submission with just your fists, you bring justice to '
            'all.\n'
            '(1)-[Passive]: You may use your Personality Modifier as the '
            'Damage Attribute for Attacking Maneuvers.\n'
            '(2)-[Passive]: You cannot use the Hype Maneuver, and ignore the '
            'effects of being Hyped.\n'
            '(3)-[Triggered, 1/Round]: If you use a Signature Technique that '
            'has 3+ Energy Charges applied to it, you may increase the Wound '
            'Roll of that Attacking Maneuver by 1/2 of your Personality '
            'Modifier.\n'
            '(4)-[Permanent, Option]: Upon gaining access to this '
            'Transformation, choose Weapon of Justice or Fists of Justice '
            '(below). Later traits of this Enhancement grant further Choice '
            'effects keyed to this pick (also listed on each option).',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Weapon of Justice',
                description: '[Permanent, Ruling]: Upon gaining access to this '
                    'effect, design a Weapon with a Craftsmanship Grade of 5. '
                    'This Weapon also gains the Justice Edge Special Weapon '
                    'Quality without taking up any Quality Slots. This Weapon '
                    "is known as your 'Heroic Weapon'.\n"
                    'Further Choice effects: [Triggered/Transform]: Create a '
                    'copy of your Heroic Weapon that is destroyed upon leaving '
                    'this Transformation, or apply the Justice Edge Special '
                    'Weapon Quality to a Weapon you possess without taking up '
                    'any Quality Slots until you leave this Transformation. '
                    '[Passive]: Increase your Combat Rolls by 1/4 (rounded up) '
                    'of your Personality Modifier.\n'
                    'Justice Edge Special Weapon Quality — Weapon Type: All; '
                    'Prerequisites: Currently in Future Hero Enhancement; '
                    'Quality Slots: 1. Effects: For each Energy Charge applied '
                    'to an Attacking Maneuver made with this Weapon, apply 1/4 '
                    'of your Personality Modifier to the Wound Roll of that '
                    'Attacking Maneuver (this increase cannot exceed your full '
                    'Personality Modifier).',
              ),
              TraitOption(
                name: 'Fists of Justice',
                description: '[Passive]: While you are not wielding a Weapon, '
                    'increase your Combat Rolls by 1/4 (rounded up) of your '
                    'Personality Modifier.\n'
                    'Further Choice effects: [Triggered/Power, 1/Round]: If '
                    'you are not wielding a Weapon, you may use the Energy '
                    'Charge Maneuver as an Out-of-Sequence Maneuver. '
                    '[Passive]: Reduce the amount of Ki Points that must be '
                    'spent to gain a stack of Justice Charge through the 1st '
                    'effect of End Justifies the Means by 1(bT).',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: 'End Justifies the Means',
        description: 'You are willing to do almost anything to ensure that '
            'justice is served and the innocent are safe.\n'
            '(1)-[Triggered/Transform, Triggered/Start of Turn, Resource]: You '
            'may spend up to 9(bT) Ki Points to gain a stack of Justice Charge '
            'for every 3(bT) Ki points spent. You can only possess up to 3 '
            'stacks of Justice Charge, and any Ki Points spent through this '
            'effect do not reduce your Capacity.\n'
            '(2)-[1/Round]: During your turn, you may spend a Justice Charge '
            'to use the Power Up Maneuver, Movement Maneuver, or Energy Charge '
            'Maneuver as an Out-of-Sequence Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver, you may spend any number of Justice Charges to reduce '
            'the Damage you received by 1/2 of your Personality Modifier for '
            'each Justice Charge spent.\n'
            '(4)-[Triggered, 1/Round]: If you use the Signature Technique '
            'Maneuver, you can spend a Justice Charge to apply an Energy '
            'Charge to that Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you do not trigger the 4th '
            'effect of End Justifies the Means in response to using an '
            'Ultimate Signature Technique, you may use this effect to spend up '
            'to 2 Justice Charges to apply an Energy Charge to that Attacking '
            'Maneuver for each Justice Charge spent.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Hero with No Name',
      description: 'When you arrive on the scene to deliver justice, your '
          'superb willpower overwhelms evildoers, letting you strike them down '
          'with ease.\n'
          '(1)-[Triggered/Transform]: Gain 3 Justice Charges. Additionally, '
          'enter the Surging State until the end of your next turn. If you do, '
          'ignore the 2nd effect of the Surging State.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Believe Yourself',
      description: 'You are an everlasting wellspring of hope for others, all '
          'because of your steadfast belief in your ability to protect them.\n'
          '(1)-[Passive]: While you are below the Injured Health Threshold, '
          'increase the Dice Category of your Energy Charges by 1 Category.\n'
          '(2)-[Passive]: The 3rd and 4th effects of End Justifies the Means '
          'lose their [1/Round] Keywords.\n'
          '(3)-[Triggered/Injured]: Use a Ki Surge as an Out-of-Sequence '
          'Maneuver.\n'
          '(4)-[Triggered/Power, 1/Round]: You may spend a Justice Charge to '
          'stop suffering from a Combat Condition of your choice (except '
          'Pinned, Stress Exhaustion, Suffocating, or Transfigured).\n'
          '(5)-[Choice]: Per your Style of Justice Option — Weapon of Justice: '
          'increase Combat Rolls by 1/4 of your Personality Modifier; Fists of '
          'Justice: reduce the Ki Points needed to gain a Justice Charge by '
          '1(bT).',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Hero Revolution',
      description: 'You awaken your heroic spirit, soaring to new heights of '
          'power in the pursuit of justice and peace.\n'
          '(1)-[Permanent]: Future Hero gains the Scaling (LV2) Aspect.\n'
          '(2)-[Passive]: Increase your maximum number of Justice Charges to 5 '
          'and increase the amount of Ki Points you can spend through the 1st '
          'effect of End Justifies the Means to 15(bT).\n'
          '(3)-[Passive]: Increase the number of Justice Charges you can spend '
          'through the 5th effect of End Justifies the Means by 1.\n'
          '(4)-[Triggered]: If you would gain any number of stacks for the '
          'Fatigued Combat Condition, you may spend an equal number of Justice '
          'Charges to not gain those stacks of Fatigued and instead gain an '
          'equal number of Power stacks.\n'
          '(5)-[Triggered/Start of Turn]: You may spend 2 Justice Charges to '
          'enter the Surging State until the end of your turn.',
    ),
  ),
  // ============================================================ Lightspeed Mode ===
  TransformationDef(
    name: 'Lightspeed Mode',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    aspects: [
      'Graded',
      'Transcendent',
      'Enhanced Save (Impulsive)',
      'High Speed',
    ],
    // AMB Grade-set: AG table 1→1(T), 2→3(T), 3→4(T), 4→6(T) (Grades 3-4 when
    // Mastered); FO/MA +G(T).
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [1, 3, 4, 6]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
    },
    traits: [
      TransformationTrait(
        name: 'Gear Shift',
        description: 'You are able to ramp up your speed at-will, allowing you '
            'to move faster than anyone else.\n'
            '(1)-[Passive]: Increase your Initiative Value by G(T).\n'
            '(2)-[Passive]: Increase the Tier of Power Extra Dice applied to '
            'your Strike and Dodge Rolls by G Dice Categories (min. 1d4).\n'
            '(3)-[Graded]: Lightspeed Mode has 2 Grades. Each Grade has its '
            'own Stress Test Requirement, sets the AMB (AG), increases the '
            'Damage you suffer from Collision and Attacking Maneuvers, and '
            'applies additional Aspects. Grade (Stress Test | AMB AG | Damage '
            '| Aspects): 1 (6 | 1(T) | 2(bT) | N/A); 2 (10 | 3(T) | 5(bT) | '
            'N/A).',
        automation: [
          // (1) +G(T) Initiative (G = the card's Grade stepper).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.initiative],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationGrade: true,
          ),
        ],
      ),
      TransformationTrait(
        name: 'Speed Star',
        description: 'You are at your absolute best when moving at maximum '
            'speed around the battlefield, gathering momentum to dodge and '
            'strike with.\n'
            '(1)-[1/Round]: You may use the Movement Maneuver or Basic Attack '
            'Maneuver as an Instant Maneuver.\n'
            '(2)-[Triggered/Start of Turn]: If you have not been hit by an '
            'Attacking Maneuver since the end of your last turn, increase your '
            'Strike and Dodge Rolls by 1/2 (rounded up) of G(T) until the '
            'start of your next turn.\n'
            '(3)-[Triggered, 1/Round]: If you use the Movement Maneuver during '
            'your turn to leave the Melee Range of another character, make a '
            'Clash (Impulsive vs Impulsive/Cognitive) against that character. '
            'Whoever loses the Clash has the Guard Down Combat Condition until '
            'the end of this turn.\n'
            '(4)-[Triggered, 1/Round]: If you have used the Movement Maneuver '
            'this Combat Round and use an Attacking Maneuver, you may use your '
            'Agility Modifier as the Damage Attribute.\n'
            '(5)-[Triggered, 1/Round]: When you use the Movement Maneuver, you '
            'may move through any Squares occupied by Opponents (you cannot '
            'end your movement on that Square). If you do, make a Clash '
            '(Impulsive vs Impulsive/Corporeal) against those Opponent(s) '
            'whose Squares you have moved through. If you win, reduce their '
            'Life Points by 1/2 of your Boosted Speed.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Lightspeed Assault',
      description: 'In a blur of motion, you close the distance between you '
          'and your target.\n'
          '(1)-[Triggered/Transform]: Use the Movement Maneuver as an '
          'Out-of-Sequence Maneuver. If you do, increase your Speeds and '
          'Combat Rolls by G(T) until the start of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'FTL',
      description: 'You rocket forward faster than light itself, streaking '
          'past friend and foe alike to strike at your desired target.\n'
          '(1)-[Permanent]: The second and higher Grades of Lightspeed Mode '
          'gain the Heartbeat (LV2) Aspect.\n'
          '(2)-[Passive]: Increase your Wound Rolls of your Signature '
          'Techniques by 1/2 (rounded up) of G(T).\n'
          '(3)-[Passive]: Reduce the extra Damage you receive from your Grade '
          'of Lightspeed Mode by 2(bT).\n'
          '(4)-[Passive]: Your use of the Movement Maneuver while in the '
          'second or higher Grades of Lightspeed Mode does not trigger the '
          'Exploit Maneuver.\n'
          '(5)-[Triggered/Start of Turn]: If you are in the first Grade of '
          'Lightspeed Mode, regain 3(bT) Ki Points.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Super Maximum Lightspeed Mode',
      description: 'Your extreme speed increases beyond the scale of '
          'imagination as you accelerate to a velocity that dwarfs the speed '
          'of light by comparison.\n'
          '(1)-[Permanent]: Gain access to the 3rd and 4th Grades of '
          'Lightspeed Mode.\n'
          '(2)-[Passive]: Halve the reduction to your Dodge Rolls from the '
          'Guard Down Combat Condition.\n'
          '(3)-[Passive]: While in the 3rd or 4th grades of Lightspeed Mode, '
          'halve the penalty from your Diminishing Defense.\n'
          '(4)-[Triggered, 1/Encounter]: If you apply the 4th effect of Speed '
          'Star to an Attacking Maneuver, you may apply a number of Energy '
          'Charges to that Attacking Maneuver equal to 1/2 (rounded up) of G.\n'
          'Grade (Stress Test | AMB AG | Damage | Aspects): 3 (14 | 4(T) | '
          '6(bT) | Straining); 4 (22 | 6(T) | 8(bT) | Straining, Exhausting).',
    ),
  ),
  // ============================================================= Martial Focus ===
  TransformationDef(
    name: 'Martial Focus',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 10,
    prerequisiteText: 'Martial Skill Awakening',
    aspects: [
      'Transcendent',
      'Enhanced Save (Morale)',
      'Prelude',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Honed Skill',
        description: 'You have honed your skills and become a master of your '
            'chosen combat style.\n'
            '(1)-[Permanent, Ruling]: Upon gaining access to this '
            'Transformation, select a Stance from the Stance Maneuver (see - '
            "Martial Skill). This becomes your 'Focused Stance'.\n"
            '(2)-[Permanent]: You can only enter this Transformation if you '
            'are in a Focused Stance.\n'
            '(3)-[Automatic]: If you leave your Focused Stance (except to '
            'enter another Focused Stance), leave this Transformation. You do '
            'not suffer from Stress Exhaustion.\n'
            '(4)-[Passive]: Ignore the reduction from your Focused Stance(s).\n'
            '(5)-[Choice]: Per your Martial Arts Practitioner style - '
            'Offensive Style: +1(T) Wound Rolls; Defensive Style: +1(T) Soak '
            'Value.\n'
            '(6)-[Passive]: Depending on your current Stance, increase a '
            'related AMB by 1(T) (Flame → FO/MA, Wind → AG, Wave → IN, Stone → '
            'TE).',
      ),
      TransformationTrait(
        name: 'Blood, Sweat and Tears',
        description: 'You have worked yourself to the bone to reach your '
            'current level of martial skill, and that effort has paid '
            'dividends.\n'
            '(1)-[Triggered/Start of Turn, 1/Encounter]: If you are below the '
            'Bruised Health Threshold, you may use a Surge of your choice as '
            'an Out-of-Sequence Maneuver.\n'
            '(2)-[Passive]: While below the Injured Health Threshold, increase '
            'your Combat Rolls and Soak Value by 1(T).\n'
            '(3)-[Passive]: While below the Injured Health Threshold, apply an '
            'Energy Charge to your Signature Techniques.\n'
            '(4)-[Passive]: Depending on the Stance you are currently in, gain '
            'access to the following effect(s):\n'
            'Flame Stance [Triggered, 1/Round]: If you target an Opponent with '
            'an Attacking Maneuver, increase your Wound Rolls by 3(T) for the '
            'duration of that Attacking Maneuver; additionally, increase the '
            'Damage Category of that Attacking Maneuver by 1 Category.\n'
            'Wind Stance [Triggered, 1/Round]: If you are targeted by an '
            'Attacking Maneuver, increase your Dodge Rolls by 2(T) for the '
            'duration of that Attacking Maneuver; additionally, you do not '
            'gain any Diminishing Defense from that Attacking Maneuver.\n'
            'Wave Stance [Triggered, 1/Round]: If you target an Opponent with '
            'an Attacking Maneuver, increase your Strike Rolls by 2(T) for the '
            'duration of that Attacking Maneuver; additionally, double the '
            'amount of Diminishing Defense dealt by that Attacking Maneuver.\n'
            'Stone Stance [Triggered, 1/Round]: If you are targeted by an '
            'Attacking Maneuver, increase your Soak Value by 3(T) for the '
            'duration of that Attacking Maneuver; additionally, reduce the '
            'Damage Category of that Attacking Maneuver by 1 Category.\n'
            '(5)-[Passive]: Depending on the Stance you are currently in, gain '
            'access to the following effect(s):\n'
            'Flame Stance [Passive]: Increase your Might by 1(T) for the '
            'duration of any Clash initiated by an Opponent.\n'
            'Wind Stance [1/Round]: During your turn, you may use the Movement '
            'Maneuver as an Instant Maneuver.\n'
            'Wave Stance [Passive]: Increase your Saving Throws by 1(T) for the '
            'duration of any Clash initiated by an Opponent.\n'
            'Stone Stance [1/Round]: As an Instant Maneuver, regain Life '
            'Points equal to 1/2 of your Surgency.',
        automation: [
          // (2) While below the Injured Health Threshold: +1(T) Combat
          // Rolls and Soak Value.
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
    burstLimit: TransformationTrait(
      name: 'Prepared Stance',
      description: 'Your dedication to your chosen style and strong focus on '
          'technique bring you closer to perfect mastery.\n'
          '(1)-[Triggered/Transform]: Halve the Ki Point Cost of all your '
          'Attacking Maneuvers until the end of your turn and double the '
          'bonuses from your Focused Stance until the end of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Deeper Understanding',
      description: 'As you grow with your combat style, using it becomes '
          'instinctual, allowing you to incorporate additional elements.\n'
          '(1)-[Permanent]: Martial Focus gains the Natural (LV1) Aspect.\n'
          '(2)-[Permanent]: Upon gaining this Trait, select an additional '
          'Focused Stance.\n'
          '(3)-[Permanent]: Martial Focus has its Stress Test Requirement '
          'increased by 2 and the Attribute Modifier Bonus (IN) increased by '
          '1(T).\n'
          '(4)-[Passive]: Depending on your Stance, gain a bonus (Flame → +2(T) '
          'Wound, Wind → +1(T) Dodge, Wave → +1(T) Strike, Stone → +2(T) Soak).'
          '\n'
          '(5)-[Passive]: The 1st effect of Blood, Sweat and Tears loses the '
          '[1/Encounter] Keyword and gains the [3/Encounter] Keyword.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Martial Mastery',
      description: 'Reaching the pinnacle of martial arts, you have become a '
          'master of many styles.\n'
          '(1)-[Permanent]: Martial Focus gains the Scaling (LV2) Aspect and '
          'the Perfect Ki Control Aspect.\n'
          '(2)-[Permanent]: Upon gaining this Trait, all Stances are treated '
          'as your Focused Stance.\n'
          '(3)-[Passive]: The Stance Maneuver loses the [1/Round] Keyword.\n'
          '(4)-[Passive]: The 2nd and 3rd effects of Blood, Sweat and Tears '
          'apply while you are below the Bruised Health Threshold, instead of '
          'the Injured Health Threshold.',
    ),
  ),
  // ====================================================== Master of Martial Arts ===
  TransformationDef(
    name: 'Master of Martial Arts',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 20,
    prerequisiteText: 'Access to 2+ Transformations that include Martial Skill '
        'as a Prerequisite',
    aspects: [
      'Transcendent',
      'Enhanced Save (All)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Wizened Warrior',
        description: 'Your experience and skill allow you to achieve maximum '
            'efficiency with minimal effort.\n'
            '(1)-[Passive]: If this Transformation is used in conjunction with '
            'a Form or Transcended Enhancement, halve its Attribute Modifier '
            'Bonuses.\n'
            '(2)-[1/Round]: You may use the Stance Maneuver as an Instant '
            'Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If you use the Stance Maneuver, you may '
            'use the Basic Attack Maneuver as an Out-of-Sequence Maneuver.\n'
            '(4)-[Triggered, 1/Round]: At the end of your turn, you may use '
            'the Stance Maneuver as an Out-of-Sequence Maneuver. This use of '
            'the Stance Maneuver does not count towards its [1/Round] limit.\n'
            '(5)-[Choice]: Per your Martial Arts Practitioner style - '
            'Offensive Style: +1(T) Wound Rolls; Defensive Style: +1(T) Soak '
            'Value.\n'
            '(6)-[Passive]: Depending on which Stance you are currently in, '
            'apply one of the following effects:\n'
            'Flame Stance [Passive]: Apply an Energy Charge to all of your '
            'Signature Techniques.\n'
            'Wind Stance [Passive]: Increase your Dodge Rolls by 1(T) and '
            'halve your penalties from Diminishing Defense (after all '
            'calculations).\n'
            'Wave Stance [1/Round]: You may use the Defend Maneuver without '
            'spending a Counter Action.\n'
            'Stone Stance [Passive]: Increase your Damage Reduction by 1(T) '
            'and this Transformation gains the Armored Aspect.',
      ),
      TransformationTrait(
        name: 'Master of Techniques',
        description: 'You have achieved mastery of the body, allowing you to '
            'overcome all obstacles with your combat prowess.\n'
            '(1)-[Passive]: While above the Bruised Health Threshold, reduce '
            'the Ki Point Cost of your Attacking Maneuvers by 1(T).\n'
            '(2)-[Passive]: For each Health Threshold you are below, increase '
            'the Dice Category of your Greater Dice by 1 Category.\n'
            '(3)-[Passive]: While below the Injured Health Threshold, increase '
            'your Combat Rolls and Soak Value by 1(T).\n'
            '(4)-[Triggered, Resource]: Each time you hit an Opponent with an '
            'Attacking Maneuver made through the Basic Attack Maneuver, gain a '
            'stack of Upper Hand (max. 10) until you leave this '
            'Transformation.\n'
            '(5)-[Triggered]: Each time you gain a stack of Upper Hand, regain '
            '1(bT) Ki Points.\n'
            '(6)-[Triggered]: If you use the Signature Technique Maneuver, you '
            'may spend any number of Upper Hand stacks to increase the Wound '
            'Roll of that Attacking Maneuver by 1(T) for each stack of Upper '
            'Hand spent.\n'
            '(7)-[Triggered, 1/Round]: For every 5 stacks of Upper Hand you '
            'spend on a Signature Technique, you may apply an Energy Charge to '
            'that Attacking Maneuver.\n'
            '(8)-[Triggered/Start of Turn]: Spend 5 stacks of Upper Hand to '
            'enter the Superior State until the start of your next turn.',
        automation: [
          // (3) While below the Injured Health Threshold: +1(T) Combat
          // Rolls and Soak Value.
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
    burstLimit: TransformationTrait(
      name: 'Master of Battle',
      description: 'Your martial mastery grants you a decisive edge over the '
          'competition.\n'
          '(1)-[Triggered/Transform]: Use the Stance Maneuver as an '
          'Out-of-Sequence Maneuver, then gain 8 stacks of Upper Hand.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Further Refinement',
      description: 'You have achieved mastery of your mind, allowing you to '
          'release your self-imposed restraints and attain true power.\n'
          '(1)-[Permanent]: Master of Martial Arts gains the Perfect Ki '
          'Control Aspect.\n'
          '(2)-[Passive]: Ignore the 2nd effect of the Superior State and any '
          'penalties from your Stance(s).\n'
          '(3)-[Passive]: Reduce the number of Upper Hand stacks you need to '
          'spend for the 8th effect of Master of Techniques by 1.\n'
          '(4)-[Triggered, 1/Round]: If you use the Power Up Maneuver, Energy '
          'Charge Maneuver, or Movement Maneuver, you may spend 3(bT) Ki '
          'Points to gain a stack of Upper Hand.\n'
          '(5)-[Triggered/Threshold, 1/Encounter]: Automatically succeed at '
          'the Steadfast Check for this Health Threshold. Then, you may use '
          'the Stance Maneuver as an Out-of-Sequence Maneuver. This use of the '
          'Stance Maneuver does not count towards its [1/Round] limit.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Transcending Martial Arts',
      description: 'You have achieved a tranquil state of absolute mastery, '
          'allowing your display of pure skill to shine brightly.\n'
          '(1)-[Permanent]: Master of Martial Arts gains the Scaling (LV2) '
          'Aspect.\n'
          '(2)-[Passive]: Double the amount of Upper Hand stacks you gain '
          'through the 4th effect of Master of Techniques.\n'
          '(3)-[Passive]: Increase your maximum number of concurrent Stances '
          'to 2.\n'
          '(4)-[Passive]: You do not have to spend Ki Points for the 4th '
          'effect of Further Refinement.\n'
          '(5)-[Triggered/Superior, 1/Encounter]: Use a Ki Surge as an '
          'Out-of-Sequence Maneuver.',
    ),
  ),
  // ========================================================== Spirit Absorption ===
  TransformationDef(
    name: 'Spirit Absorption',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 14,
    prerequisiteText: '4+ stacks of Energy Consumption',
    aspects: [
      'Transcendent',
      'Enhanced Save (Impulsive/Cognitive)',
      'High Speed (Level 3)',
      'Strainless',
      'Dedicated',
    ],
    // AMB (AG/FO/TE/MA) is `*` (set by Lifeforce — see Consuming Life); IN is a
    // flat +2(T).
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true),
      DbuAttribute.force: TransformationAmb(graded: true),
      DbuAttribute.tenacity: TransformationAmb(graded: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(graded: true),
    },
    traits: [
      TransformationTrait(
        name: 'Consuming Life',
        description: 'You have drawn the energy of others into yourself, '
            'shamelessly making it your own.\n'
            '-[Passive]: When you use the Energy Drain Unique Ability, you may '
            'target up to x Opponents instead of a single target, where x is '
            'equal to 1/2 (rounded up) of your Energy Consumption stacks. If '
            'you target more than 1 Character with the Energy Drain Unique '
            'Ability, reduce the amount of Ki Points you restore by 1/2.\n'
            '-[Passive]: For every Lifeforce you possess, increase the '
            'Attribute Modifier Bonus (AG/FO/TE/MA) of this Enhancement Power '
            'by 1(T) and its Stress Test Requirement by 2.\n'
            '-[Automatic]: If your Lifeforce reaches 0, exit this '
            'Transformation.\n'
            '-[Triggered, Resource]: Upon gaining Lifeforce (even if that '
            'Lifeforce would exceed your maximum), you may convert that '
            'Lifeforce into Consumed Lifeforce. Consumed Lifeforce is not '
            'counted as Lifeforce, but can be spent instead of Lifeforce to '
            'trigger your effects that require spending Lifeforce. Your '
            'maximum amount of Consumed Lifeforce is equal to 1/2 (rounded up) '
            'of the number of Energy Consumption stacks.\n'
            '-[Triggered/Transform, Triggered/Start of Turn]: Use the '
            'Planetary Consumption Unique Ability as an Out-of-Sequence '
            'Maneuver.',
      ),
      TransformationTrait(
        name: 'Lifeforce Feasting',
        description: 'By expending the energy you have taken from others, you '
            'can empower yourself, bolstering your attacks as well as your '
            'stamina reserves.\n'
            '-[Passive]: If you have your maximum amount of Lifeforce, '
            'increase your Tier of Power Extra Dice by x Dice Categories, '
            'where x is equal to 1/2 (rounded up) of your Energy Consumption '
            'stacks.\n'
            '-[Passive]: Increase the amount of Life and Ki Points you regain '
            'from Surges by 1(T) for each Lifeforce you possess.\n'
            '-[1/Round]: As an Instant Maneuver, you may spend 2 Lifeforce to '
            'use a Healing or Power Surge.\n'
            '-[Triggered, 1/Round]: When using the Signature Technique '
            'Maneuver, you may spend any amount of Lifeforce. For each '
            'Lifeforce spent, you may remove a Disadvantage from that '
            'Signature Technique (if the Disadvantage has multiple ranks, each '
            'Lifeforce spent only removes a single rank) for that use of the '
            'Attacking Maneuver.\n'
            "-[Triggered, 1/Round]: If you reduce an Opponent's Ki Points "
            'through the effects of the Energy Drain Unique Ability, they gain '
            'the Impediment Combat Condition until the end of your turn.\n'
            '-[Triggered/Power, 1/Round, x/Encounter]: Apply one of - spend 1 '
            'Lifeforce for an extra Power stack (retained until your third '
            'end-of-turn); spend 1-2 Lifeforce to enter the Superior State; '
            'spend 2-3 Lifeforce to enter the Surging State — x = 1/2 (rounded '
            'up) of your Energy Consumption stacks.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'World Eater',
      description: 'For a brief moment, you are able to absorb the energy of '
          'everyone and everything around you, allowing you to become even '
          'stronger than ever before.\n'
          '-[Triggered/Transform]: Use the Energy Drain Unique Ability as an '
          'Out-of-Sequence Maneuver without spending the Ki Point Cost. '
          'Additionally, double the amount of Lifeforce you gain from any '
          'means until the end of your next turn.',
    ),
    unlimitedTrait: TransformationTrait(
      name: 'Endless Hunger',
      description: 'You crave more and more stolen power, turning that power '
          'against those who oppose you.\n'
          '-[Triggered/Unlimited]: Regain 3(bT) Life and Ki Points for each '
          'Lifeforce you possess.\n'
          '-[Passive]: You may use an additional Enhancement Power in '
          'conjunction with this Transformation.\n'
          '-[Passive]: Treat your Energy Consumption Manifested Power as if it '
          'had 2 more stacks for all of your effects (this may exceed its '
          'maximum).',
    ),
  ),
  // ================================================================ Core Burst ===
  // (Race-specific Enhancements below — Standard then Transcendent.)
  TransformationDef(
    name: 'Core Burst',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Core Breaker (Burst Through the Limit)',
        description: 'Your systems have been fine-tuned to produce beyond '
            'their normal capacity, giving you greater strength than usual.\n'
            '(1)-[Passive]: Ignore the effects of Reduced Momentum.\n'
            '(2)-[Passive]: Increase your maximum number of Energy Charges by '
            '1 for each Health Threshold you are below.\n'
            '(3)-[Passive]: You may use the Energy Charge Maneuver instead of '
            'the Basic Attack Maneuver through the 5th effect of High Stake '
            'Gamble.\n'
            '(4)-[Triggered]: If you use the Energy Charge Maneuver, you may '
            'spend Life Points equal to 1/10th of your Maximum Life Points to '
            'gain a stack of Energy Burst.\n'
            '(5)-[Triggered]: If you hit your Focus with an Attacking '
            'Maneuver, you may spend a stack of Energy Burst to apply an '
            'Energy Charge to that Attacking Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If you use an Ultimate Signature '
            'Technique, you may spend all of your stacks of Energy Burst. For '
            'each one spent, apply an Energy Charge to that Attacking Maneuver '
            'and, after concluding the Attacking Maneuver, reduce your Life '
            'Points by 5(bT).\n'
            '(7)-[Triggered, 1/Character]: If you trigger the 6th effect of '
            'Core Breaker, apply 3 additional Energy Charges to that Attacking '
            'Maneuver that do not count towards your Energy Charge Limit. '
            'After concluding that Attacking Maneuver, die.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Life-Consuming Assault',
      description: 'You immediately damage yourself in order to gain more '
          'immediate benefits from the overclocking of your systems.\n'
          '(1)-[Automatic/Transform, Resource]: You may reduce your Life '
          'Points by any number of instances of 1/4 of your Maximum Life '
          'Points. Then, for each Health Threshold you are below when you '
          'enter this Transformation, gain a stack of Energy Burst.',
    ),
  ),
  // ================================================================ True Angel ===
  TransformationDef(
    name: 'True Angel',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 12,
    prerequisiteText: 'You are not a Minion',
    aspects: [
      'Enhanced Save (All)',
      'Natural (LV1)',
      'Scaling (LV4)',
      'Innate State (Superior)',
      'Peaked',
      'Limited (LV3)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Law-Defying Battle',
        description: 'Even knowing that you are forbidden from using your full '
            'power against a mortal, you unleash it anyways, deciding the cost '
            'of erasure is worth it to sway the outcome of this battle.\n'
            '(1)-[Permanent]: True Angel can be used as either a Form or an '
            'Enhancement for Transformation Stacking (see - Transformation '
            'Rules).\n'
            '(2)-[Passive]: Your base Tier of Power becomes 8.\n'
            '(3)-[Passive]: You are treated as having no Counter Actions for '
            'your effects regardless of your current number of Counter '
            'Actions.\n'
            '(4)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver, you are instead not hit by that Attacking Maneuver. If '
            'that Attacking Maneuver was an Absolute Attack, the usual effects '
            'of Absolute Attacks do not apply to that Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you '
            'may enter the Determined State for the duration of that Attacking '
            'Maneuver.\n'
            '(6)-[Triggered, 1/Round]: If you knock an Opponent through a '
            'Health Threshold with an Attacking Maneuver, they automatically '
            'fail the Steadfast Check for that Health Threshold.\n'
            '(7)-[Triggered, 1/Round]: If you use a Signature Technique, you '
            'may apply the Absolute Annihilation Super Profile to that '
            'Attacking Maneuver.\n'
            '(8)-[Automatic]: Upon leaving this Transformation, you are erased '
            'from existence. This effect does not trigger if there is an Angel '
            'or a Character with a Divine Role (see - Roles) among your '
            'Opponents.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Unsealed Instinct',
      description: 'No longer holding back, you tap into the angelic power of '
          'Autonomous Ultra Instinct.\n'
          '(1)-[Triggered/Transform]: True Angel gains the Linked (Autonomous '
          'Ultra Instinct) Aspect and triggers its effects. Additionally, you '
          'have access to Autonomous Ultra Instinct while in the True Angel '
          'Transformation.',
    ),
  ),
  // ======================================================= Ice-Cold Combatant ===
  TransformationDef(
    name: 'Ice-Cold Combatant',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Exploit Expert Talent',
    aspects: [
      'Enhanced Save (Cognitive)',
      'Draining (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Calculated Brutality',
        description: 'Your cold, observant nature makes it easy to strike '
            'efficiently, dishing out maximum harm.\n'
            '(1)-[Passive]: For every 2 stacks of Overwhelm you possess, '
            'increase your Strike Rolls by 1(T).\n'
            '(2)-[Passive]: Increase the Wound Rolls of Attacking Maneuvers '
            'made through the effects of a Counter Maneuver by 1(T) for every '
            '2 stacks of Overwhelm.\n'
            '(3)-[Passive]: If an Opponent takes Damage from an Attacking '
            'Maneuver you make, that triggers your Exploit Maneuver against '
            'that Opponent.\n'
            '(4)-[Passive]: If an Opponent enters your Melee Range, that '
            'triggers your Exploit Maneuver against that Opponent.\n'
            '(5)-[Triggered/Transform, Triggered/Start of Combat Round]: Gain '
            '1 Counter Action.',
      ),
      TransformationTrait(
        name: 'Overwhelming Pace',
        description: 'You control the flow of combat, ensuring that no one '
            'else has time to adjust before you overpower them.\n'
            '(1)-[Passive]: Use the higher of your Might or Agility Modifier '
            'to calculate your Speeds.\n'
            '(2)-[1/Round]: If you hit an Opponent with an Attacking Maneuver '
            'made through the Exploit Maneuver, you may use the Movement '
            'Maneuver as an Out-of-Sequence Maneuver.\n'
            '(3)-[Triggered]: Each time you exchange an Action for a Counter '
            'Action, regain 2(bT) Ki Points.\n'
            '(4)-[Triggered]: If an Opponent triggers your Exploit Maneuver, '
            'you may instead spend a Counter Action to use the Energy Charge '
            'Maneuver as an Out-of-Sequence Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you end your turn without having '
            'left the Square that you were occupying at the start of your '
            'turn, you may use the Basic Attack Maneuver or Energy Charge '
            'Maneuver as an Out-of-Sequence Maneuver.\n'
            '(6)-[Triggered, 1/Round]: If an Opponent starts their turn within '
            'your Melee Range, make a Clash (Cognitive) against that Opponent. '
            'If you win, they gain the Compelled Combat Condition with you as '
            'their target until the start of their next turn.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Keeping it Cool',
      description: 'Your keen eye and tactical mind make for a stunning '
          'combination that will freeze out any opponent from the ability to '
          'fight back.\n'
          '(1)-[Triggered/Transform]: Maximize your Overwhelm stacks, then '
          'gain a number of Counter Actions equal to the number of Overwhelm '
          'stacks you already possessed when you used this effect. '
          'Additionally, you cannot lose Counter Actions except through '
          'spending them until the end of the next Combat Round.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Cold as Ice',
      description: 'Experience with calculating the optimal combat scenario '
          'has given you the means to ice all competition.\n'
          '(1)-[Permanent]: This Transformation loses the Draining Aspect and '
          'gains the Heartbeat (LV2) Aspect.\n'
          '(2)-[Passive]: If an Opponent dodges an Attacking Maneuver you '
          'make, that triggers your Exploit Maneuver against that Opponent.\n'
          '(3)-[Passive]: You do not suffer from the Guard Down Combat '
          'Condition due to the effects of the Energy Charge Maneuver.\n'
          "(4)-[Passive]: During an Opponent's turn, if that Opponent has the "
          'Compelled Combat Condition with you as their target, increase your '
          'Combat Rolls by 1(T).\n'
          '(5)-[Triggered, 1/Round]: If an Opponent who is suffering from the '
          'Compelled Combat Condition with you as their target triggers your '
          'Exploit Maneuver, you may use the Exploit Maneuver without spending '
          'a Counter Action.',
    ),
  ),
  // ============================================================= Seething Fury ===
  TransformationDef(
    name: 'Seething Fury',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Variant (Enraged)',
      'Innate State (Raging)',
      'Raging',
      'Exhausting',
      'Peaked',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'That Actually Hurt! (Frenzied Assault)',
        description: "You've been pushed to your absolute limit, and now your "
            'furious vengeance will tear anyone who stands before you to '
            'shreds.\n'
            '(1)-[Passive]: Increase your Wound Rolls by 1(T) for each Health '
            'Threshold you are below.\n'
            '(2)-[Passive]: While your Life Points are below 0, increase the '
            'Attribute Modifier Bonus (FO/MA) of this Transformation by '
            '1(T).\n'
            '(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver while '
            'in the 2nd or higher Level of the Raging State, increase the '
            'Damage Category of that Attacking Maneuver by 1 Category.\n'
            '(4)-[Triggered, 1/Encounter]: If you would use an Attacking '
            'Maneuver while below the Critical Health Threshold, you may apply '
            'either the All Out or Complete Annihilation Super Profile to that '
            'Attacking Maneuver.\n'
            '(5)-[Constant, Triggered/Threshold, 1/Encounter]: Use the '
            'Transformation Maneuver to enter this Transformation as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'You Must Die by My Hand!',
      description: 'Your burning rage has no limits, and you will make sure '
          "that anyone who opposes you doesn't live to regret it.\n"
          '(1)-[Triggered/Transform]: Maximize your stacks of Overwhelm. If '
          'you do, you may use the Basic Attack Maneuver or Signature '
          'Technique Maneuver as an Out-of-Sequence Maneuver. Apply the bonus '
          'to Wound Rolls from your stacks of Overwhelm an additional time to '
          'this Attacking Maneuver.',
    ),
  ),
  // ========================================================== All-Range Combat ===
  TransformationDef(
    name: 'All-Range Combat',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Impulsive/Cognitive)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Close-Range Attacks',
        description: 'You know precisely how to utilize your enhanced eyesight '
            'and skills as a sniper to target your opponent with pinpoint '
            'precision and forceful strikes turning you into a fearsome '
            'fighter.\n'
            '(1)-[Passive]: While an Opponent is inside of your Melee Range, '
            'increase your Wound Rolls by 2(T).\n'
            '(2)-[Passive]: While an Opponent is inside of your Melee Range, '
            'increase the Dice Category of your Energy Charges by 1 Category.\n'
            '(3)-[Passive]: While an Opponent is inside of your Melee Range, '
            'all of your Signature Techniques that only target Opponents '
            'within your Melee Range gain an Energy Charge.\n'
            '(4)-[Triggered, 1/Encounter]: If you target an Opponent within '
            'your Melee Range with a Signature Technique, increase the Damage '
            'Category of that Attacking Maneuver by 1 Category for the sake of '
            "that Opponent's Damage calculation.",
      ),
      TransformationTrait(
        name: 'Long-Range Attacks',
        description: 'Your training as a sniper and your enhanced eyesight '
            "make you a menace at long-distance attacks, able to strike from "
            "far enough away that your enemies won't even know what's hit them "
            'until it\'s too late.\n'
            '(1)-[Ruling]: All Squares within a Destructive AoE (centered on '
            "you) are known as your 'Area of Control'.\n"
            '(2)-[Passive]: While no Opponents are within your Melee Range, '
            'increase your Strike Rolls by 1(T).\n'
            '(3)-[Passive]: While no Opponents are within your Melee Range, '
            'reduce the Critical Target of your Strike Rolls by 1.\n'
            '(4)-[Passive]: If an Opponent uses the Movement Maneuver within '
            'your Area of Control, this triggers your Exploit Maneuver.\n'
            '(5)-[Passive]: If an Opponent uses any Standard Maneuver while '
            'within your Area of Control, you are considered to be on an '
            'adjacent Square to them for deciding if they trigger your Exploit '
            'Maneuver.\n'
            '(6)-[Triggered]: While no Opponents are within your Melee Range '
            'and you use the Signature Technique Maneuver, you may spend a '
            'stack of Critical Eye to add a single Advantage with a TP cost of '
            'up to 10 TP to your chosen Signature Technique.\n'
            '(7)-[1/Encounter]: While no Opponents are within your Melee '
            'Range, you may use the Exploit Maneuver without spending a '
            'Counter Action.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'All-Seeing Red Eye',
      description: "Your red eye's visual prowess is unmatched by any race in "
          'the Universe. With it, you can see more of the battlefield than '
          'most, regardless of how far or close you might be.\n'
          '(1)-[Triggered/Transform]: Until the end of your next turn, your '
          'Area of Control covers the entire Battlefield and all Opponents '
          'are considered to be within your Melee Range regardless of their '
          'position in the Battlefield, while you also qualify for all effects '
          "that start with 'While no Opponents are within your Melee Range'.",
    ),
    masteryTrait: TransformationTrait(
      name: 'Adapted for All Combat',
      description: "You've proven that you can utilize the talents of your "
          'race to best others regardless of the distance between you and '
          'your foes.\n'
          '(1)-[Permanent]: All-Range Combat gains the Heartbeat (LV3) '
          'Aspect.\n'
          '(2)-[Permanent]: Increase the Attribute Modifier Bonus (AG/TE) of '
          'this Transformation by 1(T).\n'
          '(3)-[Passive]: While an Opponent is inside of your Melee Range, '
          'increase your Soak Value by 2(T).\n'
          '(4)-[Passive]: While no Opponents are within your Melee Range, '
          'increase your Dodge Rolls by 1(T).\n'
          '(5)-[1/Encounter]: Use the Movement Maneuver as an Instant '
          'Maneuver. This use of the Movement Maneuver does not trigger the '
          'Exploit Maneuver from any Opponents.',
    ),
  ),
  // ============================================================= Sniper's Burst ===
  TransformationDef(
    name: "Sniper's Burst",
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Crimson Lock On (Burst Through the Limit)',
        description: 'You focus your enhanced gaze on your next target, and '
            "you don't let them leave your sights, burning through your "
            'concentration just to make sure you take them down.\n'
            '(1)-[Automatic]: Upon leaving this Transformation, lose all of '
            'your Critical Eye stacks and halve your Life Points. If this '
            'results in your Life Points falling below the Critical Health '
            'Threshold, you are Defeated. If you are Defeated through this '
            'effect, ignore the rules of Will to Survive for this Combat '
            'Encounter.\n'
            '(2)-[Automatic]: If your number of Critical Eye stacks reaches 0, '
            'leave this Transformation. If this effect triggers during a '
            'Maneuver, complete that Maneuver then apply this effect.\n'
            '(3)-[Passive]: You must spend at least 1 stack of Critical Eye on '
            'each Attacking Maneuver you make.\n'
            '(4)-[Passive]: All of your Wound Rolls are Critical Results, '
            'regardless of the Natural Result.\n'
            '(5)-[Passive]: Set your maximum number of Critical Eye stacks to '
            '7.\n'
            '(6)-[Triggered, 1/Encounter]: If you use a Signature Technique, '
            'spend all of your remaining stacks of Critical Eye on this '
            'Attacking Maneuver. Then, for each stack of Energy Burst you '
            'possess, apply an Energy Charge to this Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Self-Sacrificing Strike',
      description: 'They say "the bigger they are, the harder they fall", so '
          "you'll show them that no matter how worn down you get, you'll be "
          'there to make sure they crumble to nothing.\n'
          '(1)-[Automatic/Transform, Resource]: For each Health Threshold you '
          'were below when you entered this Transformation, gain a stack of '
          'Energy Burst. Additionally, gain an equal number of Critical Eye '
          'stacks.',
    ),
  ),
  // =========================================================== Resolute Burst ===
  TransformationDef(
    name: 'Resolute Burst',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Last Resort Racial Trait',
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Resolution of Combat (Burst Through the Limit)',
        description: 'You know how to make the most of the life force '
            "you've funneled into your attacks.\n"
            '(1)-[Passive]: Double the bonus from the 1st effect of Last '
            'Resort.\n'
            '(2)-[Passive]: While you are below the Injured Health Threshold, '
            'increase the Dice Category of any Energy Charges applied to your '
            'Attacking Maneuvers by 1 Category. Double this bonus if you are '
            'below the Critical Health Threshold.\n'
            '(3)-[Triggered, 1/Round]: If you deal Damage to an Opponent with '
            'a Signature Technique, you may regain Capacity equal to the Ki '
            'Point Cost of that Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you trigger the 2nd effect of '
            'Last Resort, you may spend any number of Energy Burst stacks to '
            'apply an equal number of Energy Charges to that Attacking '
            'Maneuver.',
      ),
    ],
  ),
  // ================================================================ Glass Burst ===
  TransformationDef(
    name: 'Glass Burst',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Glass Tribe',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Glass Assault (Burst Through the Limit)',
        description: 'Your dire circumstance pushes you to the limit, and '
            "though you may crack under the pressure, you're going to ensure "
            "it's your enemies who shatter like broken glass.\n"
            '(1)-[Passive]: For every 2 Energy Charges applied to an Attacking '
            'Maneuver, increase the Wound Roll of that Attacking Maneuver by '
            '1(T).\n'
            '(2)-[Passive]: Increase the Dice Category of any Energy Charges '
            'applied to your Attacking Maneuvers of the Glass Profile by 1 '
            'Dice Category.\n'
            '(3)-[Triggered]: When using an Attacking Maneuver, you may remove '
            'the Glass Environmental Quality from 9 squares on the '
            'Battlefield. If you do, gain a stack of Energy Burst.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Signature Technique, '
            'for every 2 stacks of Energy Burst you possess, apply an Energy '
            'Charge to that Attacking Maneuver.',
      ),
    ],
  ),
  // =============================================================== Glass Dragon ===
  TransformationDef(
    name: 'Glass Dragon',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Glass Tribe',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Corporeal)',
      'Draining (LV2)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Great Beast of Glass',
        description: 'You conjure a massive crystal beast to aid you in '
            'battle.\n'
            "(1)-[Addendum]: Please refer to the 'Dragon of Glass' text.\n"
            '(2)-[Automatic]: If your Refractive Dragon is destroyed, leave '
            'this Transformation.\n'
            '(3)-[Passive]: Treat your Size Category as Gigantic for the sake '
            'of Punching Down.\n'
            '(4)-[Triggered]: If you take Damage from an Attacking Maneuver, '
            'you may have the Refractive Dragon take that Damage instead of '
            'you.\n'
            '(5)-[Triggered]: When making an Attacking Maneuver of the Glass '
            "Profile, you may spend the Refractive Dragon's Life Points as if "
            'they were Ki Points for the Ki Wager of that Attacking Maneuver '
            '(you still reduce your Capacity by any Life Points spent through '
            'this effect).\n'
            '(6)-[1/Round]: As an Instant Maneuver, you may remove the Glass '
            'Environmental Quality from up to 7 Squares. For every Square that '
            'loses the Glass Environmental Quality through this effect, the '
            'Refractive Dragon regains 1(bT) Life Points and you regain 1(bT) '
            'Ki Points.\n'
            '(7)-[Triggered, 1/Encounter]: If you use a Signature Technique '
            'and trigger the 5th effect of Great Beast of Glass, increase '
            'your Wound Roll for that Attacking Maneuver by 1/2 of the amount '
            "of your Refractive Dragon's Life Points spent.\n"
            'Dragon of Glass: Upon entering the Glass Dragon Transformation, '
            "you create a 'Refractive Dragon' that exists until you leave this "
            'Transformation, end the Combat Encounter, or it is destroyed. The '
            'Refractive Dragon is an extension of your Character and therefore '
            'any roll made for it is made by your Character. The Refractive '
            'Dragon does not take Damage from an Attacking Maneuver unless it '
            'is a Called Shot that targets the Refractive Dragon. The '
            'Refractive Dragon has an amount of Life Points equal to 1/2 of '
            'your Maximum Life Points and when those Life Points reach 0, the '
            "Refractive Dragon is destroyed. The Refractive Dragon's Life "
            'Points cannot exceed 1/2 of your Maximum Life Points.',
      ),
      TransformationTrait(
        name: 'Glass Annihilation',
        description: 'W\n'
            '(1)-[Passive]: Increase the Wound Rolls of your Attacking '
            'Maneuvers of the Glass Profile by 2(T).\n'
            '(2)-[Passive]: While in the Surging State, increase your Strike '
            'Rolls and the Dice Score of your Duel Clashes by 1(T).\n'
            '(3)-[Triggered]: If an effect triggers that would allow you to '
            'enter the Surging State while you are already in the Surging '
            'State, you may use the Energy Charge Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            '(4)-[Triggered/Start of Turn]: You may reduce the Life Points of '
            'your Refractive Dragon by 1/10th of your Maximum Life Points to '
            'enter the Surging State until the end of your turn.\n'
            '(5)-[Triggered, 1/Encounter]: If you use a Signature Technique, '
            'you may destroy up to 4 Features with the Glass Feature Quality. '
            'For every 2 Features destroyed for this effect, apply an Energy '
            'Charge to that Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: "Glass Dragon's Domain",
      description: 'W\n'
          '(1)-[Triggered/Transform]: All Squares within a Destructive Sphere '
          'AoE (centered on you) gain the Glass Environmental Quality and all '
          'Features within that AoE gain the Glass Feature Quality, then enter '
          'the Surging State until the end of your turn. If you do, ignore the '
          '2nd effect of the Surging State.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Glass Serpent of Destruction',
      description: 'W\n'
          '(1)-[Permanent]: Glass Dragon loses the Draining Aspect.\n'
          '(2)-[Passive]: Increase your Damage Reduction by 1(T).\n'
          '(3)-[Passive]: If you enter the Surging State through the 4th '
          'effect of Glass Annihilation, you may ignore the 2nd effect of the '
          'Surging State.\n'
          '(4)-[Passive]: All of your Signature Techniques that are not of the '
          'Glass Profile gain the Multi-Profile Super Profile. You must select '
          'the Glass Profile for the effects of Multi-Profile through this '
          'effect.',
    ),
  ),
  // ========================================================= Super High Tension ===
  TransformationDef(
    name: 'Super High Tension',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Konatsian',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Corporeal/Impulsive)',
      'Glowing',
      'Straining',
      'Exhausting',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Tension at its Peak',
        description: 'In the heat of battle, when the stakes are high and the '
            'chips are down, you know how to turn a bad situation to your '
            'advantage.\n'
            '(1)-[Permanent]: You cannot enter this Transformation unless you '
            'have 5+ Tension.\n'
            '(2)-[Automatic]: If you have no stacks of Tension, immediately '
            'leave this Transformation.\n'
            '(3)-[Constant/Start of Turn]: If you possess 5+ Tension, you may '
            'use the Transformation Maneuver as an Out-of-Sequence Maneuver to '
            'enter Super High Tension.\n'
            '(4)-[Triggered, 1/Round]: If you spend a stack of Tension, regain '
            'Ki Points equal to 1/2 of your Surgency.\n'
            '(5)-[Triggered/Transform, Triggered/Start of Turn]: Gain a stack '
            'of Tension.',
      ),
      TransformationTrait(
        name: 'Facing Adversity',
        description: 'Combat is all about challenges, and you are no stranger '
            "to being challenged. You don't back down, even in the face of a "
            'superior foe.\n'
            '(1)-[Passive]: For each Health Threshold you are below, increase '
            'your Strike and Wound Rolls by 1(T).\n'
            '(2)-[Passive]: While you are below the Injured Health Threshold, '
            'increase your Defense Value and Damage Reduction by 1(T).\n'
            '(3)-[Passive]: While you are below the Injured Health Threshold, '
            'ignore the effects of all Combat Conditions (except Prone, '
            'Pinned, Suffocating, Stress Exhaustion, or Transfigured).\n'
            '(4)-[Passive]: While you are in the Entrusted State, increase the '
            'Dice Category of your Energy Charges by 1 Category.\n'
            '(5)-[Passive]: While you are in the Entrusted State, increase the '
            'Damage Category of all of your Attacking Maneuvers by 1 '
            'Category.\n'
            '(6)-[Triggered/Threshold]: Use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver. If you do, you may spend up to 2 stacks '
            'of Tension to apply an equal number of Energy Charges to that '
            'Attacking Maneuver. You do not lose these stacks of Tension until '
            'this Maneuver is concluded.\n'
            '(7)-[Triggered/Power, 1/Encounter]: Spend 2 stacks of Tension to '
            'enter the Entrusted State until the end of your turn.',
        automation: [
          // (1) +1(T) Strike and Wound Rolls per Health Threshold below.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.strike,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perHealthThresholdBelow,
          ),
          // (2) While below the Injured Health Threshold: +1(T) Defense
          // Value and Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.defenseValue,
              AffectedStat.damageReduction,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Peaked Tension',
      description: 'When you enter battle, you come to life, feeling more '
          'powerful than ever.\n'
          '(1)-[Triggered/Transform]: Enter the Entrusted State until the '
          'start of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Tension Control',
      description: 'You turn the tides of battle almost instinctively now, '
          'capitalizing on the chaos of the battlefield like a fish swims '
          'through water.\n'
          '(1)-[Permanent]: Super High Tension loses the Draining and '
          'Exhausting Aspects.\n'
          '(2)-[Permanent]: Reduce the amount of Tension required for the 1st '
          'and 3rd effects of Tension at its Peak by 2.\n'
          '(3)-[Permanent]: Reduce the Stress Test Requirement for Super High '
          'Tension by 1 for each stack of Tension you possess.\n'
          '(4)-[Passive]: Double the bonus from the 2nd effect of Facing '
          'Adversity while you are below the Critical Health Threshold.\n'
          '(5)-[Passive]: Your Life Points cannot fall below 1 while you '
          'possess 5+ stacks of Tension.\n'
          '(6)-[Automatic]: If you are hit by an Attacking Maneuver while at 1 '
          'Life Point, lose 1 stack of Tension.',
    ),
  ),
  // ========================================================== Vocational Burst ===
  TransformationDef(
    name: 'Vocational Burst',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Konatsian',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Let Loose (Burst Through the Limit)',
        description: 'You unleash a powerful attack, carrying the secret arts '
            'of your combat specialty.\n'
            '(1)-[Passive]: You may spend stacks of Energy Burst as if they '
            'were stacks of Tension for your effects.\n'
            '(2)-[Triggered]: If you hit your Focus with an Attacking '
            'Maneuver, you may spend a stack of Tension to apply an Energy '
            'Charge to that Attacking Maneuver. You do not lose this stack of '
            'Tension until you complete that Attacking Maneuver.\n'
            '(3)-[Triggered, 1/Encounter]: If you use an Ultimate Signature '
            'Technique, you may apply the effect below matching a Vocation you '
            'have access to:\n'
            'Art of Chivalry (Warrior): You may use your Tenacity Modifier for '
            'the Damage Attribute of your Attacking Maneuver, and increase the '
            'Wound Roll of this Maneuver by 1/2 of your Damage Reduction.\n'
            "Mage's Rage (Mage): For each stack of Tension you possess, "
            'increase the Wound Roll of this Attacking Maneuver by 2(T).\n'
            'Critical Stance (Martial Artist): For each stack of Tension you '
            'possess, increase the Natural Result of your Strike and Wound '
            'Rolls for this Attacking Maneuver by 1.\n'
            'Born Again (Priest): After concluding this Attacking Maneuver, '
            'all Allies within a Destructive Sphere AoE (centered on you) '
            'regain Life Points equal to 1/4 (rounded up) of the Dice Score '
            'of your Wound Roll.\n'
            'Repeat Offender (Thief): If you hit an Opponent with this '
            'Attacking Maneuver, use a Thief Maneuver as an Out-of-Sequence '
            'Maneuver.\n'
            'Born to be Wild (Ranger): You may use your Agility Modifier for '
            'the Damage Attribute of your Attacking Maneuver, and increase the '
            'Wound Roll of this Attacking Maneuver by 1/2 of your Boosted '
            'Speed.\n'
            'Tender Twostep (Dancer): You may use your Personality Modifier '
            'for the Damage Attribute of your Attacking Maneuver, and after '
            'concluding that Maneuver, all of your Allies gain a stack of '
            'Power until the start of your next turn.\n'
            'Play the Fool (Gadabout): If you deal Damage to an Opponent with '
            'this Attacking Maneuver, use the Goof Maneuver as an '
            'Out-of-Sequence Maneuver (target an Opponent that suffered Damage '
            'from this Attacking Maneuver).\n'
            "Cosmo Force (Magic Knight): Choose up to 3 Profiles with "
            "'Elemental' in the name. Apply the first effects from all of "
            'those Profiles to this Attacking Maneuver.\n'
            'Flashback (Gladiator): If this Attacking Maneuver includes a '
            'Character of your Undone Race as a target, double the increase to '
            'your Wound Roll from the 5th effect of Gladiator for the duration '
            'of this Attacking Maneuver.\n'
            'Knight Watch (Paladin): If you deal Damage to an Opponent with '
            'this Attacking Maneuver, they gain the Compelled Combat Condition '
            'with you as their target until the start of your next turn. Then, '
            'the Grand Cross Special Maneuver becomes an Instant Maneuver until '
            'the start of your next turn, but the Square you choose for its '
            'effect must be a Square you occupy.\n'
            'Twocus Pocus (Sage): You may target an additional Character with '
            'this Attacking Maneuver. If it has an AoE, you may place an '
            'additional AoE that can face a different direction, but '
            'Characters can only be targeted by this Attacking Maneuver '
            'once.\n'
            'Sea Cannon (Pirate): Increase the Wound Roll of this Attacking '
            'Maneuver by 1(T) for each stack of Tension you possess, then '
            'regain Life Points equal to 1/4 (rounded up) of the Dice Score '
            "of this Attacking Maneuver's Wound Roll.\n"
            'Positive Reinforcement (Monster Master): After concluding this '
            'Attacking Maneuver, select an Ally. They may use the Basic Attack '
            'Maneuver or Signature Technique Maneuver as an Out-of-Sequence '
            'Maneuver, but they must target a Character who was targeted by '
            'this Attacking Maneuver; that Attacking Maneuver has its Ki Point '
            'Cost reduced to 0.\n'
            'Showtime! (Luminary): After concluding this Attacking Maneuver, '
            'Allies of the Konatsian Race gain 1 Tension and Allies not of the '
            'Konatsian Race gain a stack of Power until the start of your next '
            'turn; additionally, all Allies regain Ki Points equal to 1/2 of '
            'your Personality Modifier.\n'
            'Mark of the Hero (Hero): If this Attacking Maneuver has the '
            'Complete Annihilation Super Profile applied to it, apply 2 Energy '
            'Charges to this Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Tension Burst',
      description: 'The longer the fight drags on, the harder it becomes to '
          'win- and the stronger your drive to defeat your foes.\n'
          '(1)-[Automatic/Transform, Resource]: For each stack of Tension you '
          'possess, gain a stack of Energy Burst (max. 3).',
    ),
  ),
  // ============================================================ Whimsical Majin ===
  TransformationDef(
    name: 'Whimsical Majin',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Impulsive/Corporeal/Morale)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Wild and Wondrous',
        description: 'Your whimsical, ever-shifting nature allows you to '
            'constantly change your abilities and fighting style, letting you '
            'confuse and mystify your enemies and amaze your allies.\n'
            '(1)-[Permanent, Passive]: Upon gaining access to this '
            'Enhancement, select 3 Majin Secondary Racial Traits that you do '
            'not possess. These become known as your Wild Cards. If the 4th '
            'effect of Majin Mania would change which Majin Secondary Racial '
            'Traits you have access to, immediately pick 3 different Wild '
            'Cards to replace those you had previously.\n'
            '(2)-[Triggered/Transform]: Select a Wild Card and gain access to '
            'that Wild Card until you leave this Transformation.\n'
            '(3)-[1/Encounter]: As an Instant Maneuver, you can lose access to '
            'a Wild Card you possess to gain access to another Wild Card until '
            'you leave this Transformation.',
      ),
      TransformationTrait(
        name: 'Majin Mishaps',
        description: 'Your malleable, gooey body shifts in unpredictable '
            'ways, giving you combat advantages no one can see coming.\n'
            '(1)-[Passive]: Increase your Soak Value and Defense Value by 1(T) '
            'for the duration of any Counter Maneuvers you use.\n'
            '(2)-[Triggered, 1/Round]: If you make a Strike or Dodge Roll '
            'against an Opponent and lose the Clash, you may reroll that '
            'Combat Roll and increase the Dice Score by 2(T).\n'
            "(3)-[Triggered, 1/Round]: If you take no Damage from an "
            "Opponent's Attacking Maneuver that targets you, you may use the "
            'Basic Attack Maneuver as an Out-of-Sequence Maneuver. If you do, '
            'you must target the Opponent whose Attacking Maneuver triggered '
            'this effect for that Attacking Maneuver.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Healing Surge, you may '
            'use a Standard Maneuver with an Action Cost of 1 Action as an '
            'Instant Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Wild Round',
      description: 'You can temporarily confound and stupefy your enemies '
          'with even more tricks than normal.\n'
          '(1)-[Triggered/Transform]: Gain access to all of your Wild Cards. '
          'At the end of your next turn, lose access to 2 of these Wild Cards '
          '(you decide). Additionally, until the start of your next turn, you '
          'can use any Standard Maneuver as an Instant Maneuver (you must '
          'still pay the Action Cost).',
    ),
    masteryTrait: TransformationTrait(
      name: 'Wild Side Awakened',
      description: 'You become even more unpredictable and chaotic, embodying '
          'pure chaos incarnate.\n'
          '(1)-[Passive]: The 3rd effect of Wild and Wondrous loses the '
          '[1/Encounter] Keyword and gains the [1/Round] Keyword.\n'
          '(2)-[Passive]: The 4th effect of Majin Mishaps loses the '
          '[1/Encounter] Keyword and gains the [1/Round, 3/Encounter] '
          'Keywords.\n'
          '(3)-[Passive]: Increase your Surgency by 2(T).\n'
          '(4)-[Passive]: Increase the Wound Rolls of any of your Attacking '
          'Maneuvers made as an Instant Maneuver or Out-of-Sequence Maneuver '
          'by 2(T).',
    ),
  ),
  // ============================================================ Great Namekian ===
  TransformationDef(
    name: 'Great Namekian',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    aspects: [
      'Variant (Giant Form)',
      'Graded',
      'Growth (Level G)',
    ],
    // AMB (FO/TE/MA) is G(T) — set by Great Namekian's Grade (4 Grades).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
      DbuAttribute.tenacity:
          TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2, 3, 4]),
    },
    traits: [
      TransformationTrait(
        name: 'Namekian Titan (Battlefield Titan)',
        description: 'Your large size allows you to deal even more punishment '
            'to the enemies you have identified the weaknesses of.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T) for each Size '
            'Category you are larger than Large.\n'
            '(2)-[Passive]: The increase to your Melee Range from the 4th '
            'effect of Namekian Biology is increased by G.\n'
            '(3)-[Passive]: If a Studied Ally of a smaller Size Category is '
            'occupying a Square that you are also occupying, they cannot be '
            'targeted by Attacking Maneuvers unless that Attacking Maneuver '
            'possesses an AoE.\n'
            '(4)-[Triggered, 1/Round]: When making a Physical Attack, you may '
            'apply a Line or Cone AoE to that Attacking Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you receive Damage from a Studied '
            "Opponent's Attacking Maneuver, regain Life Points equal to 1/2 "
            'of your Surgency.\n'
            '(6)-[Triggered, 1/Round]: If you target a Studied Opponent (and '
            'no other Characters) with an Attacking Maneuver, apply Punching '
            "Down regardless of that Character's Size Category. If you would "
            'already apply Punching Down against that Opponent, increase the '
            'Wound Roll of that Attacking Maneuver by 1/2 of your Surgency.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: "Giant's Vantage",
      description: 'From your new height in the clouds, you can clearly see '
          'the battlefield, making everyone- and their attacks- seem like '
          'tiny ants.\n'
          '(1)-[Triggered/Transform]: Until the end of your next turn: All '
          'other Characters are Studied. Increase your Damage Reduction by '
          '1/2 (rounded up) of G(T).',
    ),
    masteryTrait: TransformationTrait(
      name: 'Dragon-Sized',
      description: 'You have grown to such proportions that you dwarf even the '
          'greatest of titans.\n'
          '(1)-[Permanent]: You gain access to the 4th Grade of Great '
          'Namekian.\n'
          '(2)-[Passive]: The Growth Aspect for Great Namekian can reach up to '
          '4 levels.\n'
          '(3)-[Passive]: Double the bonus from the 1st effect of Accelerated '
          'Growth.\n'
          '(4)-[Passive]: Increase the amount of Life Points you gain from the '
          '6th effect of Namekian Biology by G(bT).',
    ),
  ),
  // =========================================================== Mighty Namekian ===
  TransformationDef(
    name: 'Mighty Namekian',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Great Namekian',
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    aspects: [
      'Variant (Powerhouse)',
      'Enhanced Save (Corporeal)',
      'Graded',
      'Peaked',
    ],
    // AMB (FO) is Grade-set: Grade 1→1(T), 2→2(T), 3→3(T) (Variant of
    // Powerhouse — Muscular Proportions table).
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Greater Muscle (Uninhibited Strength)',
        description: 'Using the malleable nature of your elastic body, you '
            'bulk up, becoming physically stronger.\n'
            '(1)-[Passive]: While you have 1 stack of Super Stack, ignore your '
            'Muscle Penalty.\n'
            '(2)-[Passive]: Increase your Soak Value, Surgency, and Speeds by '
            '1/2 of your Muscle Power.\n'
            '(3)-[Triggered]: If you target a Studied Opponent with an '
            'Attacking Maneuver, increase the Wound Roll of that Attacking '
            'Maneuver by your Muscle Power.\n'
            '(4)-[Triggered, 1/Round]: If you receive Damage from a Studied '
            "Opponent's Attacking Maneuver, regain Life Points equal to 1/2 "
            'of your Surgency.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Target all Studied Opponents. '
            'They gain the Compelled Combat Condition with you as the target '
            'until the start of your next turn.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Might of Namek',
      description: 'Your increased power combined with your perceptive nature '
          'grants you a unique advantage over lesser fighters.\n'
          '(1)-[Triggered/Transform]: Until the end of your next turn, all of '
          'your Opponents are Studied and your Muscle Power is increased by '
          '2(T).',
    ),
  ),
  // ============================================================== Oozaru Burst ===
  TransformationDef(
    name: 'Oozaru Burst',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: 'Access to the Oozaru Transformation',
    aspects: [
      'Variant (Burst Attack)',
      'Innate State (Surging)',
      'Raging',
      'Exhausting',
      'Peaked',
      'Limited (LV1)',
      'Fading (LV1)',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Ape Awakening (Burst Through the Limit)',
        description: 'You tap into the power of the beast inside you, '
            'unleashing its rage in an all-out attack that decimates your '
            'foes.\n'
            '(1)-[Permanent]: You cannot use this Transformation in '
            'conjunction with a Transformation that possesses the Blutz Wave '
            'Aspect.\n'
            '(2)-[Automatic/Transform]: Gain a number of Battle Born stacks '
            'equal to your number of Energy Burst stacks. These Battle Born '
            'stacks must be applied to your Wound Rolls, but may exceed the '
            'maximum number of Battle Born stacks you may apply to your Wound '
            'Rolls.\n'
            '(3)-[Automatic]: Upon leaving this Transformation, lose a number '
            'of Battle Born stacks equal to the number gained through the 2nd '
            'effect of Ape Awakening.\n'
            '(4)-[Passive]: Treat your Size Category as Gigantic for the sake '
            'of Punching Down.\n'
            '(5)-[Triggered, 1/Encounter]: If you use a Signature Technique, '
            'you may spend any number of Energy Burst stacks to apply an equal '
            'number of Energy Charges to that Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'This Will Be a Massacre!',
      description: 'Unleashing the rage of the Great Ape within, you know '
          'beyond a shadow of a doubt that no one will survive your '
          'onslaught.\n'
          '(1)-[Automatic/Transform, Resource]: For each Health Threshold you '
          'were below when you entered this Transformation, gain a stack of '
          'Energy Burst. Additionally, enter a level of the Raging State equal '
          'to the number of Health Thresholds you are below while in this '
          'Transformation.',
    ),
  ),
  // =============================================================== Saiyan Pride ===
  TransformationDef(
    name: 'Saiyan Pride',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: "Warrior's Pride Racial Trait",
    aspects: [
      'Enhanced Save (Morale)',
      'Raging',
      'Draining (Level 1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Saiyan Superiority',
        description: 'Your warrior blood blazes in your veins, calling you to '
            'battle and demanding nothing but your best.\n'
            '(1)-[Passive]: While in the Superior State, increase your Tier of '
            'Power Extra Dice by 1 Dice Category.\n'
            '(2)-[Passive]: While in the Superior State, increase your Wound '
            'Rolls and Soak Value by 1(T).\n'
            '(3)-[Triggered/Power, 1/Round]: Target all Opponents within a '
            'Large Sphere AoE (centered on you). Make a Clash (Cognitive vs '
            'Cognitive/Morale) against all of those targets. If you win '
            'against an Opponent, that Opponent gains the Shaken and Broken '
            'Combat Conditions until the end of your turn.\n'
            '(4)-[Triggered, 1/Encounter]: If you target all the Opponents in '
            'your Combat Encounter with the 3rd effect of Saiyan Superiority '
            'and win the Clash against all of those Opponents, enter the '
            'Superior State until the end of your next turn.',
      ),
      TransformationTrait(
        name: 'Will of the Warrior',
        description: 'Your pride overpowers logic and reason, allowing you to '
            'perform nearly impossible feats in defiance against all odds.\n'
            '(1)-[Passive]: You automatically succeed at any Clashes initiated '
            'by an Opponent that uses your Cognitive Save.\n'
            '(2)-[Passive]: While you possess 4+ stacks of Battle Born, this '
            'Transformation gains the Enhanced Save (Cognitive) Aspect.\n'
            '(3)-[Passive]: While you possess 6+ stacks of Battle Born, '
            'increase the Dice Score of your Steadfast Checks by 1.\n'
            '(4)-[Triggered/Power, 1/Round]: Spend 4(bT) Ki Points to enter '
            'the Raging State until the end of your turn.\n'
            '(5)-[Constant, Triggered/Injured]: Use the Transformation '
            'Maneuver as an Out-of-Sequence Maneuver. If you do, you must '
            'attempt to enter the Saiyan Pride Enhancement.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Pride on the Line',
      description: 'You refuse to be seen as weak, and when the chips are '
          'down, you show just how powerful a Saiyan can really be.\n'
          '(1)-[Triggered/Transform]: Use a Healing Surge as an '
          'Out-of-Sequence Maneuver. If you do, and this brings your Life '
          'Points above a Health Threshold you were previously below, you may '
          'use the Power Up Maneuver as an Out-of-Sequence Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Proud Heritage',
      description: 'As a proud representative of your race, you make it your '
          'mission to teach the whole universe what a true Saiyan warrior is '
          'capable of.\n'
          '(1)-[Permanent]: Saiyan Pride loses the Draining Aspect.\n'
          '(2)-[Passive]: Ignore the 2nd effect of the Superior State.\n'
          '(3)-[Passive]: Double the bonus from the 1st effect of Saiyan '
          'Superiority.\n'
          '(4)-[Passive]: You may enter the Superior State instead of the '
          'Raging State for the 4th effect of Will of the Warrior.\n'
          '(5)-[Passive]: Treat the Superior State as the Raging State for the '
          'effects of the Raging Aspect.',
    ),
  ),
  // ========================================================= Super Saiyan Power ===
  TransformationDef(
    name: 'Super Saiyan Power',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 10,
    prerequisiteText: 'Mastered Super Saiyan 1',
    aspects: [
      'Enhanced Save (Impulsive/Corporeal)',
      'Heartbeat (LV3)',
      'Super Saiyan Form',
      'Glowing',
      'Light Dependent',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Golden Sparks',
        description: 'Your Super Saiyan power is at the tips of your fingers, '
            "allowing you to tap into that potential at a moment's notice.\n"
            '(1)-[Permanent]: Super Saiyan Power cannot be used in conjunction '
            'with another Transformation that possesses the Super Saiyan Form '
            'Aspect.\n'
            '(2)-[Passive]: While you have 2+ stacks of Battle Born, increase '
            'your Wound Rolls by 1(T).\n'
            '(3)-[Passive]: While you have 4+ stacks of Battle Born, increase '
            'the Tier of Power Extra Dice by 1 Dice Category and increase your '
            'Soak Value by 1(T).\n'
            '(4)-[Passive]: While you have 6+ stacks of Battle Born, increase '
            'the Attribute Modifier Bonus (IN) of this Transformation by '
            '1(T).',
      ),
      TransformationTrait(
        name: 'Flash of Gold',
        description: 'Your potent golden aura surrounds you, granting you the '
            'might of a Super Saiyan.\n'
            '(1)-[Triggered]: If you enter this Transformation through the '
            'effects of the Heartbeat Aspect, increase your Wound Rolls and '
            'Soak Value by 2(T) until you leave this Transformation.\n'
            '(2)-[Triggered/Power, 1/Round]: You may ignore all of your Health '
            'Threshold Penalties until the end of your turn.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Golden Surge',
      description: 'Your full Super Saiyan power leaps forth at your call!\n'
          '(1)-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. Then, you may gain a stack of Battle '
          'Born.',
    ),
  ),
  // ================================================================= Wrathful ===
  TransformationDef(
    name: 'Wrathful',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    aspects: [
      'Graded',
      'Raging',
      'Innate State (Feral/Raging)',
      'Rampaging (LVG)',
    ],
    // AMB (AG/FO/TE) Grade-set: Grade 1→2(T), 2→3(T) (Wrathful, 2 Grades).
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [2, 3]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [2, 3]),
      DbuAttribute.tenacity: TransformationAmb(graded: true, gradePerTier: [2, 3]),
    },
    traits: [
      TransformationTrait(
        name: 'Compressed Oozaru',
        description: 'All the raw, explosive power of the mighty Oozaru, '
            'packed into your decidedly smaller form, has left you as quite '
            'the powerhouse.\n'
            '(1)-[Permanent]: This Transformation cannot be used in '
            'conjunction with any Transformation that has the Blutz Wave '
            'Aspect.\n'
            '(2)-[Passive]: Treat your Size Category as if it was G Size '
            'Categories larger for the sake of Punching Down.\n'
            '(3)-[1/Round]: You may spend 1 stack of Battle Born to use the '
            'Signature Technique Maneuver while in the Feral State. If that '
            'Signature Technique was a Super Signature, you may apply the '
            'Ascended Signature Advantage to it.\n'
            '(4)-[Graded]: Wrathful has 2 Grades. Each Grade has its own '
            'Stress Test Requirement, sets the AMB (AG/FO/TE), and applies '
            'additional Aspects. Grade (Stress Test | AMB AG/FO/TE | Aspects): '
            '1 Initial (14 | 2(T) | -); 2 Maximum (18 | 3(T) | Armored, Bulky, '
            'Growth (LV1)).',
      ),
      TransformationTrait(
        name: 'Empowering Fury',
        description: 'Your burning rage fuels you, driving you to new heights '
            'of power.\n'
            '(1)-[Passive]: While you are below the Injured Health Threshold, '
            'increase your Tier of Power Extra Dice by G Dice Categories.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(T) for each '
            'Health Threshold you are below.\n'
            '(3)-[Triggered, 1/Encounter]: When you trigger the second effect '
            'of Born for Battle, apply your Surgency twice for the Ki Surge '
            'used through this effect.\n'
            '(4)-[Triggered, 1/Encounter]: If you enter the 2nd Grade for this '
            'Transformation, gain a stack of Battle Born.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Saiyan Ferocity',
      description: 'Your fierce, bestial nature takes over completely, making '
          'you impossible to stop for a short time.\n'
          '(1)-[Triggered/Transform]: Gain 2 stacks of Battle Born (these '
          'stacks of Battle Born must be applied to your Wound Rolls). Then, '
          'increase your Soak Value by 1(T) for each stack of Battle Born you '
          'currently possess until the start of your next turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Mind over Monkey',
      description: 'Your conscious mind emerges over the beast inside, taking '
          'control to direct your wrath.\n'
          '(1)-[Permanent]: Reduce the Rampaging Aspect for this '
          'Transformation by 1 level.\n'
          '(2)-[Permanent]: Wrathful loses the Innate State (Feral) Aspect.\n'
          '(3)-[1/Round]: You may use the Direct Hit option of the Defend '
          'Maneuver without spending a Counter Action.\n'
          '(4)-[Triggered, 1/Encounter]: If you would use the Direct Hit '
          'option of the Defend Maneuver, instead of increasing your Soak '
          'Value by 1/2 - double it.',
    ),
  ),
  // ======================================================= Controlled Wrathful ===
  TransformationDef(
    name: 'Controlled Wrathful',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.special,
    initialEnhancement: 'Wrathful',
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 3,
    stressTestRequirement: 20,
    aspects: [
      'Innate State (Raging/Mindful)',
      'Raging',
      'Mindful',
      'Peaked',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Oozaru Power',
        description: 'The untapped strength of the mighty Great Ape surges '
            'through you at your command.\n'
            '(1)-[Permanent]: This Transformation cannot be used in '
            'conjunction with any Transformation that has the Blutz Wave '
            'Aspect.\n'
            '(2)-[Passive]: Treat your Size Category as if it was Gigantic for '
            'the sake of Punching Down.\n'
            '(3)-[Passive]: Increase the Dice Category of your Tier of Power '
            'Extra Dice by 1 Category.\n'
            '(4)-[Passive]: Increase the maximum number of Battle Born stacks '
            'for each of your Combat Rolls by 1.\n'
            '(5)-[Triggered, 1/Round]: If you use a Super Signature, you may '
            'apply the Ascended Signature Advantage to that Attacking '
            'Maneuver.\n'
            '(6)-[Triggered/Start of Turn]: Gain a stack of Battle Born.',
      ),
      TransformationTrait(
        name: 'Balanced Wrath',
        description: 'Despite the intense rage of the Great Ape coursing '
            'through your veins, you bring your mind to a quiet calm, allowing '
            'you to direct that anger how you see fit.\n'
            "(1)-[Ruling]: 'ML' refers to the current level of your Mindful "
            "State, and 'RL' refers to the current level of your Raging "
            'State.\n'
            '(2)-[Passive]: While ML is equal to RL, this Transformation '
            'possesses the Armored and Perfect Ki Control Aspects.\n'
            '(3)-[Passive]: Increase your Surgency by ML(bT).\n'
            '(4)-[Passive]: Increase your Wound Rolls by RL(T).\n'
            '(5)-[Triggered/Start of Turn]: Regain ML(bT) Ki Points.\n'
            '(6)-[Triggered, 1/Round]: If you use a Signature Technique, it '
            'gains 1/2 (rounded up) of RL Energy Charges.\n'
            '(7)-[Triggered/Power, 1/Round]: Enter the next level in the '
            'Raging or Mindful State until the start of your next turn. You '
            'may spend any number of Battle Born stacks to apply this effect '
            'an additional time for each stack of Battle Born spent.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Warrior and the Beast',
      description: 'Your intense focus allows you to unleash the full power of '
          'your inner Great Ape without losing yourself to its primal fury.\n'
          '(1)-[Triggered/Transform]: Gain a stack of Battle Born. Then, '
          'enter the Tranquil level of Mindful and the Apoplectic level of '
          'Raging until the start of your next turn.',
    ),
  ),
  // ============================================================= Negative Aura ===
  TransformationDef(
    name: 'Negative Aura',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Morale)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Negative Influence',
        description: 'Those who stand opposed to you find that the laws of '
            'physics seem inverted somehow.\n'
            '(1)-[Ruling]: All Squares within a Large Sphere AoE (centered on '
            "you) are known as your 'Negativity Zone'.\n"
            '(2)-[Passive]: All Opponents within your Negativity Zone have the '
            'Natural Result of their Combat Rolls reduced by 1.\n'
            '(3)-[Passive]: All Opponents within your Negativity Zone have '
            'their Surgency increased by 2(T).\n'
            '(4)-[Passive]: All Opponents within your Negativity Zone reduce '
            'the Dice Score of their Surges by their Surgency, instead of '
            'adding it on. This can cause a Surge to reach a negative value, '
            "in which case it would actually reduce that Character's Life/Ki "
            'Points instead of increasing them.\n'
            '(5)-[1/Round]: As an Instant Maneuver, target an Opponent. They '
            'may choose to use a Healing Surge as an Out-of-Sequence Maneuver. '
            'If they do, you may use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver.\n'
            '(6)-[Triggered, 1/Round]: If you deal Damage to an Opponent with '
            'an Attacking Maneuver, that Opponent may choose to use a Healing '
            'Surge as an Out-of-Sequence Maneuver. If they do, you may '
            'immediately afterwards use the Power Up Maneuver.\n'
            '(7)-[Triggered, 1/Encounter]: If you give an Opponent the chance '
            'to use a Healing Surge through your effects, they cannot '
            'decline.',
      ),
      TransformationTrait(
        name: 'Fear the Negative Energy',
        description: 'Your ability to warp reality to suit your whims is '
            'stronger in the area closest to you.\n'
            '(1)-[Passive]: Opponents within your Negativity Zone cannot '
            'remove the Impaired Combat Condition through their effects (it '
            'can still be removed through Combat Recovery).\n'
            '(2)-[Passive]: Increase the Wound Rolls of your Attacking '
            'Maneuvers by x(T), where x is equal to the highest number of '
            'Impaired stacks applied amongst the target(s) of that Attacking '
            'Maneuver.\n'
            '(3)-[Triggered/Start of Turn]: Make a Clash (Morale vs '
            'Impulsive/Corporeal/Cognitive/Morale) against all Opponents '
            'within your Negativity Zone. If you win, they gain a stack of the '
            'Impaired Combat Condition until the start of your next turn.\n'
            '(4)-[Triggered, 1/Encounter]: When you use a Signature Technique, '
            'you may remove up to 3 stacks of the Impaired Combat Condition '
            'from Opponents within your Negativity Zone. For each stack of the '
            'Impaired Combat Condition removed, apply an Energy Charge to that '
            'Attacking Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Plague of the Negative Energy',
      description: 'As reality shifts and bends to your whims, your foes '
          'slowly lose the will to fight.\n'
          '(1)-[Triggered/Transform]: All Opponents within your Negativity '
          'Zone have their Life Points reduced by your Might and gain a stack '
          'of the Impaired Combat Condition until the start of your next '
          'turn.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Unavoidable Negative Energy',
      description: 'The zone of warped reality that surrounds you has grown '
          'even stronger, plunging all who dare to fight against you into the '
          'darkest depths of despair.\n'
          '(1)-[Passive]: Increase the Magnitude of your Negativity Zone by '
          '1.\n'
          '(2)-[Passive]: Opponents within your Negativity Zone ignore all '
          'effects that would prevent them from gaining the Impaired Combat '
          'Condition.\n'
          '(3)-[Passive]: The 4th effect of Fear the Negative Energy may '
          'remove stacks of the Impaired Combat Condition from all other '
          'Characters, not just Opponents.\n'
          '(4)-[Passive]: All Opponents within your Negativity Zone that are '
          'suffering from the Impaired Combat Condition have their Combat '
          'Rolls reduced by 1(T).\n'
          '(5)-[Passive]: Double the bonus to Surgency through the 3rd effect '
          'of Negative Influence.\n'
          '(6)-[1/Round]: As an Instant Maneuver, target an Opponent. That '
          'Opponent may use a Healing Surge as an Out-of-Sequence Maneuver. If '
          'they do, they gain a stack of the Impaired Combat Condition until '
          'the start of your next turn.',
    ),
  ),
  // =============================================================== Divine Halo ===
  TransformationDef(
    name: 'Divine Halo',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Cognitive)',
      'Glowing',
      'Light Dependent',
      'Difficult (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Circle of Light',
        description: 'Your divine energy manifests as a halo of light, '
            'granting you new powers.\n'
            '(1)-[Triggered, 1/Round]: When using an Attacking Maneuver that '
            'does not possess an AoE, you may target an additional Character '
            'with that Attacking Maneuver or apply an AoE of your choice to '
            'that Attacking Maneuver.\n'
            '(2)-[Triggered, 1/Round]: When using an Attacking Maneuver that '
            'possesses an AoE (except one gained through the 1st effect of '
            'Circle of Light), you may apply that AoE an additional time but '
            'targeting different Squares.\n'
            '(3)-[1/Encounter]: Use a Unique Ability that is a Standard '
            'Maneuver with its Action Cost reduced by 1 Action. If this would '
            'reduce its Action Cost to 0, you may use that Unique Ability as '
            'an Instant Maneuver.',
      ),
      TransformationTrait(
        name: 'Holy Light',
        description: 'The blinding light of your divine radiance allows you to '
            'harm your foes or heal your allies.\n'
            '(1)-[Permanent]: Upon gaining access to this Transformation, '
            'design and gain access to a Signature Technique with a TP Cost of '
            'up to 30. This Signature Technique must possess 2 Ranks of the '
            'Restriction - Transformation Disadvantage, with Divine Halo '
            'selected as the Transformation, which cannot be removed by any '
            'means.\n'
            '(2)-[Passive]: Increase your Surgency by 1(T) for each Health '
            'Threshold you are below.\n'
            '(3)-[Passive]: Increase the amount of Life and Ki Points regained '
            'through Combat Recovery by 1/4 (rounded up) of your Surgency.\n'
            '(4)-[Triggered, 1/Round]: If you use Combat Recovery, and are not '
            'hit by an Attacking Maneuver made by the Exploit Maneuver in '
            'response to it, all Allies within a Large Sphere AoE (centered on '
            'you) regain Life and Ki Points equal to 1/2 of your Surgency.\n'
            '(5)-[Triggered, 1/Round]: If you use the Signature Technique '
            'Maneuver, you may spend 4(bT) Ki Points to apply an Energy Charge '
            'to that Attacking Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: As an Instant Maneuver, you may use '
            'Combat Recovery as if you spent 3 Actions.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Brilliant Light',
      description: 'As your divine light builds and grows, your energy builds '
          'with it.\n'
          '(1)-[Triggered/Transform]: Use Combat Recovery as an '
          'Out-of-Sequence Maneuver as if you spent 3 Actions. This use of '
          'Combat Recovery does not trigger the Exploit Maneuver.',
    ),
    masteryTraits: [
      TransformationTrait(
        name: 'Pristine Halo (1)',
        description: 'The pure, untainted essence of your divine nature shines '
            'even brighter, casting out darkness.\n'
            '(1)-[Permanent]: Divine Halo gains the Perfect Ki Control '
            'Aspect.\n'
            '(2)-[Permanent]: Upon gaining access to this Mastery Trait, '
            'design and gain access to a Signature Technique with a TP Cost of '
            'up to 30. This Signature Technique must possess 2 Ranks of the '
            'Restriction - Transformation Disadvantage, with Divine Halo '
            'selected as the Transformation, which cannot be removed by any '
            'means.\n'
            '(3)-[Passive]: Increase the AoE of the 4th effect of Holy Light '
            'by M Magnitudes.\n'
            '(4)-[Ruling]: All Signature Techniques with 2 Ranks of the '
            'Restriction - Transformation Disadvantage, with Divine Halo '
            "selected the Transformation, are known as 'Holy Techniques'.\n"
            '(5)-[Triggered, 1/Encounter]: If you use a Holy Technique, you '
            'may apply your Damage Attribute an additional time for that '
            'Attacking Maneuver.',
      ),
      TransformationTrait(
        name: 'Manifestation of Divine Might (2)',
        description: 'Every light must cast a shadow, and the shadows cast by '
            'your divine light answer to your divine authority.\n'
            "(1)-[Permanent]: Divine Halo's Stress Test Requirement is "
            'increased by 4, and its Attribute Modifier Bonuses (AG/FO/MA) are '
            'increased by 1(T).\n'
            '(2)-[Passive]: You gain access to the Divine Shadow Special '
            'Maneuver.\n'
            '(3)-[Passive]: The 3rd effect of Holy Light uses 1/2 of your '
            'Surgency, instead of 1/4 (rounded up).\n'
            '(4)-[Passive]: If an Opponent enters your Melee Range due to any '
            'movement initiated by that Opponent, this triggers your Exploit '
            'Maneuver.\n'
            'Divine Shadow [1/Encounter] (Standard, 2 Actions, KP 10(bT)) — '
            "Effect: Create a 'Ki Entity' that exists until you leave this "
            'Transformation, end the Combat Encounter, or it is destroyed. '
            'While the Ki Entity exists, your Size Category is treated as '
            'Gigantic for the sake of Punching Down, for calculating your '
            'Melee Range, and for calculating your Soak Value. When you use '
            'the Exploit Maneuver while you possess a Ki Entity, you may use '
            'the Signature Technique Maneuver to use a Holy Technique instead '
            'of the Basic Attack Maneuver through the Exploit Maneuver. While '
            'the Ki Entity exists, you do not take Damage from Attacking '
            'Maneuvers; instead, reduce the Life Points of the Ki Entity equal '
            'to the Damage you would have received. The Ki Entity has Life '
            'Points equal to 1/4 of your Maximum Life Points. When the Ki '
            'Entity is destroyed, gain the Guard Down Combat Condition until '
            'the start of your next turn.',
      ),
    ],
  ),
  // ================================================================= Overdrive ===
  TransformationDef(
    name: 'Overdrive',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Transcendent',
      'Armored',
      'Enhanced Save (Cognitive/Impulsive)',
      'Draining (LV2)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Heated Combat',
        description: 'Your mechanical parts heat up as you overclock your '
            "systems, reaching output levels you'd previously never dreamed "
            'of.\n'
            '(1)-[Passive]: Ignore the effects of Reduced Momentum.\n'
            '(2)-[Passive]: For each Health Threshold you are below, increase '
            'your Surgency, Soak Value, and Wound Rolls by 1(T).\n'
            '(3)-[1/Round]: During your turn, you may spend 4(bT) Life Points '
            'to use the Movement Maneuver or Energy Charge Maneuver as an '
            'Instant Maneuver.\n'
            '(4)-[Triggered]: If you make an Attacking Maneuver, you may spend '
            '4(bT) Life Points to apply an Energy Charge to that Attacking '
            'Maneuver.\n'
            '(5)-[Triggered/Power, 1/Round, 2/Encounter]: Spend 8(bT) Life '
            'Points to enter the Superior State until the start of your next '
            'turn.',
        automation: [
          // (2) +1(T) Surgency, Soak Value and Wound Rolls per Health
          // Threshold below.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.surgency,
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
      TransformationTrait(
        name: 'Beyond Schematics',
        description: 'Operating beyond standard specifications, your '
            'cybernetics are functioning at a peak beyond what they were '
            'designed for.\n'
            '(1)-[Passive]: You are always considered to be in the Healthy '
            'Health Threshold for the 1st effect of Technological Being.\n'
            '(2)-[Passive]: While in the Superior State, increase your Damage '
            'Reduction and Wound Rolls by 1(T).\n'
            '(3)-[Triggered, 1/Round]: If you use the Direct Hit or Guard '
            'options of the Defend Maneuver, you may increase your Damage '
            'Reduction by 1/2 for the duration of that Attacking Maneuver.\n'
            '(4)-[1/Encounter]: If you are below the Critical Health '
            'Threshold, you may use a Healing Surge as an Instant Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver '
            'with 3+ Energy Charges, you may increase the Damage Category of '
            'that Attacking Maneuver by 1 Category.',
        automation: [
          // (2) While in the Superior State (tracked in the States list):
          // +1(T) Damage Reduction and Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.damageReduction,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Superior',
          ),
        ],
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Scalding Power',
      description: 'The heat building in your cybernetic components can be '
          'channeled into your offensive maneuvers.\n'
          '(1)-[Triggered/Transform]: Use the Power Up Maneuver as an '
          'Out-of-Sequence Maneuver. Then, you may use the Energy Charge '
          'Maneuver, Movement Maneuver, or Basic Attack Maneuver as an '
          'Out-of-Sequence Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Maintained Heat',
      description: 'As you become accustomed to overclocking your mechanical '
          'parts, the heat it generates becomes a constant companion.\n'
          '(1)-[Permanent]: Overdrive loses the Draining Aspect.\n'
          '(2)-[Passive]: Halve the amount of Life Points you spend through '
          'the effects of Heated Combat.\n'
          '(3)-[Passive]: While in the Superior State, ignore the 2nd effect '
          'of the Superior State.\n'
          '(4)-[Passive]: The 5th effect of Heated Combat becomes '
          '[3/Encounter].',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Maximum Overdrive',
      description: 'Reaching a level beyond even the overclocked state '
          "you're used to, you push your cybernetics to their absolute limits "
          "and draw power out of them that even you didn't know you had.\n"
          '(1)-[Permanent]: Overdrive gains the Scaling (LV2) Aspect.\n'
          '(2)-[Passive]: Apply your Tier of Power Extra Dice an additional '
          'time.\n'
          '(3)-[Passive]: While you possess 1+ stacks of Power, increase your '
          'Damage Reduction by 1(T).\n'
          '(4)-[Triggered]: If you spend Life Points through the effects of '
          'Heated Combat, regain Ki Points equal to the amount of Life Points '
          'lost.\n'
          '(5)-[1/Encounter]: As an Instant Maneuver, regain Life Points equal '
          'to your Surgency.',
    ),
  ),
  // =========================================================== Ocular Awakening ===
  TransformationDef(
    name: 'Ocular Awakening',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.power,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 4,
    stressTestRequirement: 24,
    aspects: [
      'Transcendent',
      'Enhanced Save (Impulsive)',
      'Perfect Ki Control',
      'Strainless',
      'High Speed (Level 3)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Evolved Left Eye',
        description: 'Your left eye is now just as powerful as the right, '
            'allowing you to benefit from its enhanced visual acuity and your '
            'prowess utilizing it. This makes you a far greater fighter- and '
            "a greater danger to those you're fighting.\n"
            '-[Passive]: If this Transformation is not used in conjunction '
            'with a Core Transformation, increase its Attribute Modifier '
            'Bonuses (AG/FO/TE/MA) by 2(T).\n'
            '-[Passive]: You may place 2 stacks of Observation through the '
            'second effect of Crimson Glare (you can place both on a single '
            'Character or place one each on two different Opponents).\n'
            '-[Passive]: Double the maximum amount of Observation stacks an '
            'Opponent can possess.\n'
            '-[Triggered]: If you score a Critical Result on a Combat Roll, '
            'apply your Tier of Power Extra Dice an additional time to that '
            'Combat Roll.\n'
            '-[Triggered, 1/Round]: If you remove 2+ stacks of Observation '
            'from an Opponent when making an Attacking Maneuver through the '
            'second effect of Crimson Glare, you score a Critical Result on '
            'the Strike Roll for that Attacking Maneuver, regardless of the '
            'Natural Result.',
      ),
      TransformationTrait(
        name: 'Dangerous Exploitation',
        description: 'The greater vision from having both eyes be equally '
            'powerful allows you to exploit any openings in an enemy\'s guard '
            'much more deftly- and with much more power as well.\n'
            '-[Passive]: The Power Up, Energy Charge, and Transformation '
            'Maneuvers made by your Opponents trigger the Exploit Maneuver.\n'
            '-[Triggered]: If you would use the Exploit Maneuver, you may '
            'remove a stack of Observation on the target of that Attacking '
            'Maneuver to increase the Damage Category of that Attacking '
            'Maneuver by 1 Category.\n'
            '-[Triggered, 1/Round]: If an Opponent triggers the Exploit '
            'Maneuver, you may remove a stack of Observation from that '
            'Opponent to use the Exploit Maneuver without spending a Counter '
            'Action.',
      ),
      TransformationTrait(
        name: 'One Shot Kill',
        description: 'Your incredible visual acuity has granted you a much '
            'more effective way of targeting vital points on your enemies, '
            "practically ensuring that not only do you win, but they're not "
            'likely to be getting back up any time soon.\n'
            '-[Triggered, Resource]: If you score a Critical Result on a '
            'Combat Roll, gain a stack of Bullseye (max. 1(bT)).\n'
            '-[Triggered]: When rolling a Combat Roll, you may spend up to 2 '
            'stacks of Bullseye after seeing the Natural Result to increase '
            'the Natural Result by 1 for each stack spent. If you score a '
            'Critical Result after using this effect, you do not gain a stack '
            'of Bullseye through the first effect of One Shot Kill.\n'
            '-[Triggered]: If you use the Energy Charge Maneuver, gain a stack '
            'of Bullseye.\n'
            '-[Triggered]: If you score a Critical Result on the Strike Roll '
            'of an Attacking Maneuver that has any number of Energy Charges, '
            'increase the Dice Category of those Energy Charge Extra Dice by 2 '
            'categories.\n'
            '-[Triggered, 1/Encounter]: When you make an Attacking Maneuver '
            'that has gained at least 2+ Energy Charges from the Energy Charge '
            'Maneuver, you may spend 1(bT) stacks of Bullseye to apply 2 '
            'additional Energy Charges to that Attacking Maneuver. If you do, '
            'you score a Critical Result on the Strike Roll of that Attacking '
            'Maneuver regardless of the Natural Result. You do not gain a '
            'stack of Bullseye through scoring a Critical Result through this '
            'effect.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'World in Red',
      description: 'As your vision shifts, so too does your ability to '
          "interact with it. Though only for a limited time, you're better "
          "able to exploit the tiniest openings in your opponent's guard.\n"
          '-[Triggered/Transform]: Maximize your stacks of Bullseye. '
          'Additionally, until the end of your next turn, you may use the '
          'Exploit Maneuver any number of times without spending a Counter '
          'Action.',
    ),
    unlimitedTrait: TransformationTrait(
      name: 'Pressure Point Sniper',
      description: "You've become skilled enough to hit the exact nerve you "
          'aim for with no effort.\n'
          '-[Passive]: Increase the Natural Result of your Strike and Wound '
          'Rolls by 1.\n'
          '-[Triggered]: If you score a Critical Result on a Combat Roll, '
          'increase that Combat Roll by 2(T).\n'
          '-[Triggered, 1/Round]: If you make an Attacking Maneuver, you may '
          'spend 2 stacks of Bullseye to use the Called Shot Maneuver without '
          'spending an Action through its effects.\n'
          '-[Triggered, 1/Round]: If you hit an Opponent with a Called Shot, '
          'inflict the Impediment Combat Condition on them until the end of '
          'their next turn.\n'
          '-[Triggered, 1/Round]: When using the Signature Technique Maneuver, '
          'spend 3 stacks of Bullseye to set the Natural Result of your Strike '
          'and Wound Rolls for that Attacking Maneuver to 10. You do not gain '
          'stacks of Bullseye through the first effect of One Shot Kill from '
          'using this effect.',
    ),
  ),
  // ============================================================== Demonic Will ===
  TransformationDef(
    name: 'Demonic Will',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Demon',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Transcendent',
      'Enhanced Save (Cognitive/Impulsive)',
      'Draining (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Demonic Pride',
        description: 'Many species wear their pride as a badge of honor, but '
            'unlike most, you use it to draw forth reserves of untold power.\n'
            '(1)-[Passive]: While you possess 2+ stacks of Demonic Power, '
            'increase your Combat Rolls and Soak Value by 1(T).\n'
            '(2)-[Passive]: While you possess 3+ stacks of Demonic Power, all '
            'of your Signature Techniques gain an Energy Charge.\n'
            '(3)-[Triggered/Start of Turn]: Make a Pressure Check.\n'
            '(4)-[Triggered, 1/Encounter]: If you succeed on 3 Pressure Checks '
            'during a single Combat Round, you may enter the Superior State '
            'until the end of your next turn.',
      ),
      TransformationTrait(
        name: 'Demonic Cheat',
        description: "Unlike others, you don't always play by the rules. "
            "You've learned them very well, and found it's more effective to "
            'break them.\n'
            '(1)-[Triggered, 1/Encounter]: If you fail a Pressure Check, you '
            'may succeed instead.\n'
            '(2)-[Triggered, Resource]: If you would end your turn with 2+ '
            'stacks of Demonic Power, you may spend a stack of Demonic Power '
            'to gain a stack of Banked Power (max. 3).\n'
            '(3)-[Triggered/Start of Turn]: You may spend a stack of Banked '
            'Power to gain a stack of Demonic Power.\n'
            '(4)-[Triggered, 1/Round]: When making an Attacking Maneuver, you '
            'may spend any number of Banked Power stacks to reduce the Ki '
            'Point Cost of that Maneuver by 4(T) for each stack of Banked '
            'Power spent. This can reduce the Ki Point Cost of an Attacking '
            'Maneuver to 0.\n'
            '(5)-[Triggered/Power, 1/Round]: Spend a stack of Banked Power to '
            'gain an additional stack of Power from this use of the Power Up '
            'Maneuver.\n'
            '(6)-[1/Encounter]: You may spend a stack of Banked Power to use a '
            'Surge as an Instant Maneuver.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Hidden Reserves of Demonic Might',
      description: "You've learned to tap into deep wells of power and bring "
          'it forth whenever you need it.\n'
          '(1)-[Triggered/Transform]: Maximize your number of Banked Power '
          'stacks and then use the Power Up Maneuver as an Out-of-Sequence '
          'Maneuver.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Power of a Determined Demon',
      description: "Through willpower alone, you're able to push yourself "
          'further and further, plumbing the reserves of your power and '
          'growing stronger.\n'
          '(1)-[Permanent]: Demonic Will loses the Draining Aspect.\n'
          '(2)-[Passive]: The 4th effect of Demonic Pride loses the '
          '[1/Encounter] Keyword and gains the [1/Round, 3/Encounter] '
          'Keywords.\n'
          '(3)-[Passive]: Ignore the 2nd effect of the Superior State.\n'
          '(4)-[Passive]: If you have 2+ stacks of Demonic Fatigue, you '
          'automatically succeed all Pressure Checks.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Will of a Demon Lord',
      description: 'The sheer force of your willpower is so refined and '
          'potent, it allows you to draw out even greater strength.\n'
          '(1)-[Permanent]: Demonic Will gains the Perfect Ki Control '
          'Aspect.\n'
          '(2)-[Passive]: Apply your Tier of Power Extra Dice an additional '
          'time.\n'
          '(3)-[Passive]: While you possess 2+ stacks of Demonic Fatigue, '
          'increase the Dice Category of your Tier of Power Extra Dice by 1 '
          'Category.\n'
          '(4)-[Passive]: The 6th effect of Demonic Cheat loses the '
          '[1/Encounter] Keyword and gains the [1/Round, 3/Encounter] '
          'Keywords.\n'
          '(5)-[Triggered/Start of Turn]: Gain 2 stacks of Demonic Fatigue.',
    ),
  ),
  // ================================================================ Hi-Tension ===
  TransformationDef(
    name: 'Hi-Tension',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    aspects: [
      'Enhanced Save (Impulsive/Cognitive)',
      'Transcendent',
      'Straining',
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Earthling Pride',
        description: 'Your pride as a warrior of Earth will never be deterred, '
            'allowing you to keep fighting no matter what comes your way.\n'
            '(1)-[Passive]: Increase the Dice Score of your Steadfast Checks '
            'by 1.\n'
            '(2)-[Passive]: While you are below the Injured Health Threshold, '
            'increase your Soak Value and Surgency by 2(T).\n'
            '(3)-[Triggered/Threshold]: Gain a Counter Action.\n'
            '(4)-[Triggered/Power, 1/Encounter]: Treat yourself as being below '
            'the Critical Health Threshold for all of your effects (instead of '
            'whatever Health Threshold you are currently in) until the end of '
            'your next turn.',
      ),
      TransformationTrait(
        name: 'Earthling Combat',
        description: 'Centering yourself, you create a rush of adrenaline that '
            'pushes you to greater and flashier feats of strength\n'
            '(1)-[Passive]: You can use the Signature Technique Maneuver an '
            'additional time each Combat Round, but you cannot use the same '
            'Signature Technique more than once per Combat Round.\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of your Signature '
            'Techniques by 1(T).\n'
            '(3)-[1/Round]: You may use the Basic Attack Maneuver or Signature '
            'Technique Maneuver as an Instant Maneuver during your turn.\n'
            '(4)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver, you may choose to halve the Dice Score of '
            'your Wound Roll. If you do, you may use Combat Recovery as if you '
            'spent 1 Action on Combat Recovery as an Out-of-Sequence Maneuver. '
            "This use of Combat Recovery does not trigger your Opponents' "
            'Exploit Maneuvers, and you do not suffer from the penalty to your '
            'Defense Value through its effects.\n'
            '(5)-[Triggered, 1/Encounter]: If you use Combat Recovery while '
            'there is an Opponent in your Melee Range, you may choose to forgo '
            'regaining any Life or Ki Points from that Combat Recovery (you '
            'still roll as normal) to use the Basic Attack Maneuver or '
            'Signature Technique Maneuver as an Out-of-Sequence Maneuver. '
            'Increase the Wound Roll of that Attacking Maneuver by the Dice '
            'Score of your roll for Combat Recovery.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Maximum Tension',
      description: 'The initial rush of adrenaline that kicks you into action '
          'is always the strongest.\n'
          '(1)-[Triggered/Transform]: Use Combat Recovery as an '
          'Out-of-Sequence Maneuver as if you spent 2 Actions. This use of '
          "Combat Recovery does not trigger your Opponents' Exploit Maneuvers, "
          'and you do not suffer from the penalty to your Defense Value '
          'through its effects. If you use this effect, you may trigger the '
          '5th effect of Earthling Combat without using up its [1/Encounter] '
          'Keyword.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Full Tension',
      description: 'Your adrenaline courses through every inch of your body, '
          'filling you to the brim with power.\n'
          '(1)-[Permanent]: Hi-Tension loses the Straining Aspect and gains '
          'the Perfect Ki Control Aspect.\n'
          '(2)-[Passive]: Increase the amount of Life and Ki Points you regain '
          'from Combat Recovery by 1d4(T).\n'
          '(3)-[Passive]: While you are below the Critical Health Threshold, '
          'increase your Combat Rolls by 1(T).',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Super Full Tension',
      description: 'The rush of pure adrenaline pushes you past your inherent '
          'limiters and awakens strength in your body that has always lain '
          'dormant.\n'
          '(1)-[Permanent]: Increase the Stress Test Requirement of Hi-Tension '
          'by 4 and increase the Attribute Modifier Bonus (AG/TE) of '
          'Hi-Tension by 1(T).\n'
          '(2)-[Passive]: Increase the Dice Category of the bonus for the 2nd '
          'effect of Full Tension by 1 Category.\n'
          '(3)-[Passive]: While you are below the Critical Health Threshold, '
          'increase your Damage Reduction by 1(T).\n'
          '(4)-[Triggered, 1/Round]: If you hit an Opponent with an Attacking '
          'Maneuver and deal no Damage to that Opponent, you may use the '
          'Basic Attack Maneuver as an Out-of-Sequence Maneuver.\n'
          '(5)-[Triggered, 1/Encounter]: If you trigger the 4th effect of '
          'Earthling Combat, you do not have to halve the Dice Score of your '
          'Wound Roll to apply its effects.',
    ),
  ),
  // ========================================================= Red-Eyed Namekian ===
  TransformationDef(
    name: 'Red-Eyed Namekian',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      'Transcendent',
      'Enhanced Save (Cognitive/Impulsive)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Tri-Solar Energy',
        description: 'The power that wells up inside you allows you to recover '
            'stamina and energy as easily as you regenerate your body.\n'
            '(1)-[Passive]: For each Health Threshold you are below, increase '
            'the amount of Life Points you regain through the 6th effect of '
            'Namekian Biology by 1(bT).\n'
            '(2)-[Triggered]: When you regain Life Points through the 6th '
            'effect of Namekian Biology, regain Ki Points equal to 1/2 of the '
            'Life Points regained.\n'
            '(3)-[Triggered, 1/Round]: If an effect would allow you to use a '
            'Healing Surge, you may use a Ki Surge instead.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Ki Surge, you may use '
            'either the Power Up Maneuver, Energy Charge Maneuver, or Empower '
            'Maneuver (as if you spent 1 Action) as an Out-of-Sequence '
            'Maneuver.',
      ),
      TransformationTrait(
        name: 'Red-Eyed Style',
        description: 'Your scarlet gaze sweeps the battlefield relentlessly '
            'without missing a detail, empowering your friends and granting '
            'you the insight to exploit the weaknesses of your foes.\n'
            "(1)-[Triggered/Start of Combat Round, 1/Encounter]: Select either "
            "'Opponents' or 'Allies', all Characters classified as your "
            'selection become Studied until the end of the Combat Round.\n'
            '(2)-[Triggered/Power, 1/Round]: Either you or a willing Studied '
            'Ally of your choice enters the Surging State until the end of '
            'your/their turn. A Character suffering from the Fatigued Combat '
            'Condition cannot enter the Surging State through this effect.\n'
            '(3)-[Ruling]: If you had selected an Opponent to become Studied '
            "at the end of the last Combat Round, you have a 'Warrior's Gaze' "
            'this Combat Round; if an Ally, you have a \'Draconic Gaze\'.\n'
            "(4)-[Passive]: Warrior's Gaze: while in the Surging State, "
            'increase your Wound Rolls by 1/2 of your Surgency. Draconic Gaze: '
            'increase the Wound Rolls of your Studied Allies by 1/4 (rounded '
            'up) of your Surgency.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Flash of the Red Eyes',
      description: 'You can surge into a burst of immediate strength to '
          'instantly mow down the enemy, or restore the stamina and vitality '
          'of your comrades.\n'
          '(1)-[Triggered/Transform]: Double your Surgency until the end of '
          "your turn. Then, Warrior's Gaze: you may use the Power Up Maneuver "
          'as an Out-of-Sequence Maneuver. Draconic Gaze: all of your Studied '
          'Allies regain Life and Ki Points equal to your Surgency.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Namekian Diligence',
      description: 'Your keen senses and sharp mind leave no metaphorical '
          'stone unturned, ensuring that all weaknesses are laid bare before '
          'your crimson stare.\n'
          '(1)-[Passive]: Increase your Surgency by 1(T).\n'
          '(2)-[Passive]: If a Character enters the Surging State through an '
          'effect of Red-Eyed Namekian, they ignore the 2nd effect of the '
          'Surging State upon leaving the State entered through this means.\n'
          "(3)-[Passive]: Warrior's Gaze: increase the Dice Category of your "
          'Energy Charges by 1 Category while below the Bruised Health '
          'Threshold. Draconic Gaze: increase the Dice Category of any Energy '
          "Charges applied to a Studied Ally's Attacking Maneuver by 1 "
          'Category.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Red-Eyed Super Namekian',
      description: 'Fully awakened by the burning flames of your resolve, your '
          'ruby glare glows brighter in the face of adversity.\n'
          '(1)-[Permanent]: Red-Eyed Namekian gains the Scaling (LV2) '
          'Aspect.\n'
          '(2)-[1/Encounter]: As an Instant Maneuver, you may use a Healing '
          'Surge.\n'
          '(3)-[Passive]: Apply your Tier of Power Extra Dice an additional '
          'time.\n'
          "(4)-[Passive]: Warrior's Gaze [Triggered/Power, 1/Round]: Gain an "
          'additional stack of Power. Draconic Gaze [Triggered/Power, '
          '1/Round]: Select a willing Studied Ally, they gain a stack of Power '
          'until the end of their turn.',
    ),
  ),
  // =============================================================== Evil Saiyan ===
  TransformationDef(
    name: 'Evil Saiyan',
    type: TransformationType.enhancement,
    enhancementType: EnhancementType.standard,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    stressTestRequirement: 13,
    aspects: [
      'Transcendent',
      'Variant (Evil Aura)',
      'Enhanced Save (Cognitive)',
      'Prelude',
      'Raging',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Dark Saiya Power (Villainous Form)',
        description: 'Your bloodlust scorches your blackened heart, driving '
            'you to battle.\n'
            '(1)-[Passive]: Your maximum number of Evil Points is 10(bT).\n'
            '(2)-[Passive]: While this Transformation is used in conjunction '
            "with a Transformation with the 'Saiyan' Racial Requirement: "
            'increase your Tier of Power Extra Dice by 1 Dice Category; reduce '
            'the Stress Test Requirement of Evil Saiyan by 3; gain an '
            'additional 2(bT) Evil Points at the start of each Combat Round '
            'through the first effect of Power of Evil.\n'
            '(3)-[1/Round]: As an Instant Maneuver, spend a stack of Battle '
            'Born to regain 5(bT) Evil Points.\n'
            '(4)-[Triggered, 1/Round]: If a Saiyan hits you with a Physical '
            'Attack that does not possess an AoE, make a Clash (Cognitive) '
            'against them. If you win, they gain the Compelled Combat '
            'Condition with the Character that is closest to them as the '
            'target (if tied, you decide). This effect does not trigger if '
            'that Saiyan is in the Mindful State or has an active Shield '
            'Aura.',
      ),
      TransformationTrait(
        name: 'Aura Expansion',
        description: 'Your aura of evil energy supplements your anatomy, '
            'extending your reach and empowering your Saiyan tail.\n'
            '(1)-[Passive]: You gain access to the Aura Tail Special '
            'Maneuver.\n'
            '(2)-[Passive]: While you have an Aura Tail, you gain access to '
            'the Tail Attack Maneuver. You do not select an option, but '
            'instead have access to the Elongated or Heavy options (you can '
            'only use one option at a time).\n'
            '(3)-[Triggered]: If you use a Physical Attacking Maneuver, spend '
            '2(bT) Evil Point(s) to apply either a Cone or Line AoE to that '
            'Attacking Maneuver or treat your Size Category as if it was 1 '
            'larger for the effects of Punching Down for the duration of that '
            'Attacking Maneuver.\n'
            'Aura Tail [1/Round] (Standard, 1 Action, KP 4(T)): You gain an '
            'Aura Tail; while you have it, per your Saiyan Heritage Option — '
            'Tailed: your Tail cannot be lost (regrown if lost), ignore the '
            '4th effect of Saiyan Heritage, +1(T) Damage Reduction; Tailless: '
            'you benefit from both the Tailless and Tailed options — see the '
            'site.',
      ),
    ],
    burstLimit: TransformationTrait(
      name: 'Overwhelming Evil Power',
      description: 'The insatiable evil urges mixes with your Saiyan battle '
          'lust to drive you into a frenzy.\n'
          '(1)-[Triggered/Transform]: Enter the Surging State until the end of '
          'your turn. If you do, maximize your Evil Points.',
    ),
    masteryTrait: TransformationTrait(
      name: 'Focused Evil',
      description: 'By directing the darkness inside you, you take control '
          'over your battle lust and become a fine-tuned weapon of '
          'destruction.\n'
          '(1)-[Passive]: Your maximum number of Evil Points is 15(bT).\n'
          '(2)-[Passive]: Ignore the second effect of the Surging State.\n'
          '(3)-[Passive]: While this Transformation is used in conjunction '
          "with another Transformation that has the 'Saiyan' Racial "
          'Requirement, increase the Dice Score of your Steadfast Checks by '
          '1.\n'
          '(4)-[Triggered, 1/Round]: If you knock an Opponent with a Combat '
          'Condition through a Health Threshold, gain 5(bT) Evil Points.\n'
          '(5)-[Triggered/Power, 1/Round]: Target all Opponents within a '
          'Sphere AoE (centered on you). Make a Clash (Cognitive vs '
          'Cognitive/Morale) against those Opponents. If you win, they gain '
          'the Shaken Combat Condition until the start of your next turn.',
    ),
    transcendentTrait: TransformationTrait(
      name: 'Evil of Legend',
      description: 'You have unleashed the ultimate potential of your '
          'battle-hungry Saiyan blood.\n'
          '(1)-[Passive]: Evil Saiyan gains the Armored and Scaling (LV2) '
          'Aspects.\n'
          '(2)-[Passive]: Increase the Attribute Modifier Bonus (IN) of Evil '
          'Saiyan by 1(T).\n'
          '(3)-[Passive]: Your maximum number of Evil Points is 20(bT).\n'
          '(4)-[Triggered/Start of Turn]: Evil Saiyan stops being '
          'Transcended.\n'
          '(5)-[Triggered/Transform, 1/Encounter]: If you use the Burst Limit '
          'for this Transformation, gain a stack of Battle Born.',
    ),
  ),
];

/// Looks up an Enhancement by name, or `null` if unrecognized.
TransformationDef? enhancementByName(String name) {
  for (final e in kDbuEnhancements) {
    if (e.name == name) return e;
  }
  return null;
}
