/// forms.dart
/// ---------------------------------------------------------------------------
/// Alternate Forms catalogue (Transformation Catalog → Alternate Forms),
/// verbatim from the site. Forms are entered through the Transformation
/// Maneuver (max 1 active at a time, alongside up to 1 Enhancement), so their
/// Attribute Modifier Bonus applies only while ACTIVE, and an active Form
/// grants the Ki Multiplier (double Max Ki, +1/2 Max Capacity).
///
/// Each Form STAGE is its own `TransformationDef` (sharing a
/// `transformationLine`), mirroring the rules: "A Stage ... each being their
/// own Transformation." Higher Stages inherit lower Stages' Traits (shown as
/// reference text, not duplicated here).
///
/// COMPLETE: every Form of the Transformation Catalog is transcribed here —
/// 147 `TransformationDef`s spanning the site's three separate menus: Alternate
/// Forms, Legendary Forms, and Evolved Stages (several pages hold multiple Stage
/// defs, e.g. Super Saiyan 1–3, Metamorphosis 0–3, the Ultra Instinct / Beyond
/// God / Self-Restraint / Meta Form / Grudge Amplifier / Dragon Shell / Awoken
/// Genetics / Full Power Boost / Universal Power / Janemba / Demon God / Divine
/// Saiyan / Appointed God lines). Both Alternate and Legendary `FormType`s
/// appear; Evolved Stages (`isEvolvedStage`) and Null Stages (`isNullStage`) are
/// derived, not stored as separate lists — the UI splits Forms into the three
/// menus using those getters + `formType`.
///
/// CONVENTIONS used here (same as the rest of `lib/data/`):
///   • A page's numbered Trait effects are copied verbatim into one
///     `TransformationTrait.description`. Large auxiliary sub-catalogues
///     (Super Form's ~25 Form Traits, Genetic/Super-Genetic Traits, Brilliant
///     Evolution Traits, Battle Uniforms, Special States/Maneuvers, per-Race
///     option lists, etc.) are being transcribed **verbatim inline** (the old
///     condensed-pointer shorthand is being swept out — grep for remnants).
///   • A Legendary Form's Legendary/Exceed Trait is carried as an extra entry
///     in `traits` named "... (Legendary Trait)" / "... (Exceed Trait)". Those
///     markers are what `TransformationDef.legendaryTrait` / `.exceedTrait` /
///     `.situationalTraits` read: a Legendary Trait is ALWAYS active (rules),
///     so the UI renders it in its own always-on subsection rather than in the
///     active-only Trait list.
///   • `Evolved Stage Type: Unique (X)` pages have no site Transformation
///     Line; the relationship is recorded in `prerequisiteText`.
///   • Graded AMB cells (`*`, `-G`, `+G(T)`) map to
///     `TransformationAmb(graded: true)` (shown as text, not auto-applied);
///     Janemba's zalgo-corrupted flavour is rendered as readable stand-ins.
///   • Race names are normalized to the `kDbuRaces` catalogue spelling so the
///     eligibility filter matches (e.g. site "Neko"/"Bio-Android" ->
///     "Neko Majin"/"Bio Android"). "Animal" and "Janemba" are kept verbatim
///     even though they are not base playable Races (faithful to the site).
library;

import 'dbu_rules.dart';
import 'race_traits.dart';
import 'transformations.dart';
import 'apparel.dart' show ApparelCategory;

/// Shared Attribute Modifier Bonus for the racial "Power" Forms and other
/// `Variant (Power Boost)` Forms — AG/FO/TE/IN/MA +1(T), no SC/PE.
const Map<DbuAttribute, TransformationAmb> _powerBoostAmb = {
  DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
  DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
  DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
  DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
  DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
};

/// Common high-tier Legendary-Form AMB — AG/FO/TE/MA +4(T), IN +2(T).
const Map<DbuAttribute, TransformationAmb> _legendary4Amb = {
  DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
  DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
  DbuAttribute.tenacity: TransformationAmb(coefficient: 4, tierScaled: true),
  DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
  DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
};

/// Higher Legendary-Form AMB (ToP 5+ forms) — AG/FO/TE/MA +6(T), IN +2(T).
const Map<DbuAttribute, TransformationAmb> _legendary6Amb = {
  DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
  DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
  DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
  DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
  DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
};

/// The **Tail Attack** Maneuver's optional effect (Special Maneuvers page):
/// picked when you first gain the Maneuver, and re-choosable per Stage of
/// Metamorphosis. Each swaps the Maneuver's Profile at an added per-use KP Cost,
/// so all four are situational (per-Attack) and surfaced as verbatim text.
const List<TraitOption> kTailAttackOptions = [
  TraitOption(
    name: 'Elongated',
    description: '(+2(T) Ki Point Cost): The Tail Attack uses the Sweeping '
        'Profile instead of the Unarmed Simple Profile.',
  ),
  TraitOption(
    name: 'Multiple',
    description: '(+2(T) Ki Point Cost): The Tail Attack uses the Combination '
        'Profile of your Physical Foundation instead of the Unarmed Simple '
        'Profile.',
  ),
  TraitOption(
    name: 'Spiked',
    description: '(+4(T) Ki Point Cost): The Tail Attack uses the Crushing '
        'Profile instead of the Unarmed Simple Profile.',
  ),
  TraitOption(
    name: 'Heavy',
    description: '(+6(T) Ki Point Cost): The Tail Attack uses the Powered '
        'Profile instead of the Unarmed Simple Profile.',
  ),
];

/// Per-Stage customization choices shared by the Metamorphosis line (Arcosian
/// Emperor). Per the rules, the ONLY per-Stage choices are: a **Size Category**
/// (Small/Large — auto-shifts the effective Size), *S* **Evolution Traits** (the
/// Arcosian list, whose numeric picks automate — multi-select), the **Tail
/// Attack** effect, and the **Survivor** Option. (Evolved Stages applied to a
/// Stage inherit the Original Form's choices, so they carry no groups of their
/// own.) The Tail Attack and Survivor picks are situational/apparel-dependent, so
/// they're surfaced as verbatim text rather than auto-applied.
const List<RaceTraitOptionGroup> kMetamorphosisOptionGroups = [
  RaceTraitOptionGroup(
    label: 'Size Category',
    options: [
      TraitOption(
        name: 'Small',
        description: 'Your base Size Category becomes Small while in this Stage.',
        // Small is one Category below Medium (the Arcosian default).
        automation: [
          RaceTraitAutomation(
            affectedStats: [AffectedStat.sizeCategory],
            coefficient: -1,
            tierScaling: TierScaling.none,
          ),
        ],
      ),
      TraitOption(
        name: 'Large',
        description: 'Your base Size Category becomes Large while in this Stage.',
        automation: [
          RaceTraitAutomation(
            affectedStats: [AffectedStat.sizeCategory],
            coefficient: 1,
            tierScaling: TierScaling.none,
          ),
        ],
      ),
    ],
  ),
  // Choose *S* Evolution Traits per Stage (S is the character's Metamorphosis
  // value, tracked by the player). The cap is the full list so a legitimate
  // pick is never blocked; each chosen Trait's automation applies while active.
  RaceTraitOptionGroup(
    label: 'Evolution Trait',
    options: kArcosianEvolutionTraits,
    maxChoices: 19,
  ),
  RaceTraitOptionGroup(
    label: 'Tail Attack',
    options: kTailAttackOptions,
  ),
  RaceTraitOptionGroup(
    label: 'Survivor Option',
    options: kArcosianSurvivorOptions,
  ),
];

/// True Form's per-Stage picks — the same as [kMetamorphosisOptionGroups] but
/// without a Size choice (True Form cannot change its Size Category).
const List<RaceTraitOptionGroup> kMetamorphosisTrueFormOptionGroups = [
  RaceTraitOptionGroup(
    label: 'Evolution Trait',
    options: kArcosianEvolutionTraits,
    maxChoices: 19,
  ),
  RaceTraitOptionGroup(
    label: 'Tail Attack',
    options: kTailAttackOptions,
  ),
  RaceTraitOptionGroup(
    label: 'Survivor Option',
    options: kArcosianSurvivorOptions,
  ),
];

const List<TransformationDef> kDbuAlternateForms = [
  // ========================================================= Super Saiyan 1 ===
  TransformationDef(
    name: 'Super Saiyan',
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 2,
    transformationLine: 'Super Saiyan',
    stage: 1,
    stressTestRequirement: 12,
    aspects: [
      'Enhanced Save (Impulsive/Corporeal)',
      'Super Saiyan Form',
      'Raging',
      'Glowing',
      'Light Dependent',
      'Draining (LV1)',
      'Power High (LV1)',
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
        name: 'S-Cells',
        description: 'The latent power in your blood awakens, granting '
            'you increased might.\n'
            '(1)-[Passive]: While you have 4+ stacks of Battle Born, '
            'increase the Tier of Power Extra Dice for your Combat Rolls '
            'by 1 Category and increase your Damage Reduction by 1(T).\n'
            '(2)-[1/Round]: While you have 6+ stacks of Battle Born, you '
            'may use the Power Up Maneuver as an Instant Maneuver.\n'
            '(3)-[Permanent, Option]: Upon gaining access to this '
            'Transformation, select one of the following effects:',
        automation: [
          // (1) While 4+ tracked 'Battle Born' Resource stacks: +1(T)
          // Damage Reduction (the Extra-Dice Category bump stays manual).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedResourceAtLeast,
            conditionResourceName: 'Battle Born',
            conditionAmount: 4,
          ),
        ],
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Super Surger',
                description: '[Passive]: While you have 2+ stacks of '
                    'Power, increase your Combat Rolls and Surgency by '
                    '1(T) and 2(T) respectively.',
                automation: [
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
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.surgency],
                    coefficient: 2,
                    tierScaling: TierScaling.current,
                    condition: TraitCondition.whileAnyPowerStack,
                    conditionAmount: 2,
                  ),
                ],
              ),
              TraitOption(
                name: 'Super Speed',
                description: '[Passive]: While you have 2+ stacks of '
                    'Battle Born applied to your Dodge Rolls, increase '
                    'your Speeds and Defense Value by 1(T).',
              ),
              TraitOption(
                name: 'Super Sturdy',
                description: '[Passive]: While you have 2+ stacks of '
                    'Battle Born applied to your Wound Rolls, increase '
                    'your Soak Value by 2(T).',
              ),
              TraitOption(
                name: 'Super Specialist',
                description: '[Permanent, Passive]: Upon gaining this '
                    'effect, select a Foundation. Increase your Strike '
                    'Rolls and Wound Rolls for that Foundation by 1(T) '
                    'and 2(T) respectively while you have a Battle Born '
                    'stack in their respective Combat Rolls.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: 'Golden Power',
        description: 'Your energy spikes and flows off of you in waves, '
            'shining gold with power.\n'
            '(1)-[Passive]: Increase the Dice Score for your Duel '
            'Clashes by 1(T).\n'
            '(2)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver while below the Bruised Health Threshold, reduce '
            'the Damage Category of that Attacking Maneuver (for your '
            'Damage Calculation) by 1 Category.\n'
            '(3)-[Triggered/Transform]: Enter the Raging State until the '
            'end of your turn.\n'
            '(4)-[Triggered/Transform, 1/Encounter]: Use a Ki Surge.',
      ),
    ],
    masteryTrait: TransformationTrait(
      name: 'This is a Super Saiyan',
      description: 'Your comfort in this form allows you to draw out '
          'even greater power, overwhelming your enemies.\n'
          '(1)-[Permanent]: Super Saiyan 1 loses both the Draining and '
          'Power High Aspects and gains the Natural (LV1) and Heartbeat '
          '(LV1) Aspects.\n'
          '(2)-[Permanent]: Gain access to the Full Power Evolved Stage '
          'for Super Saiyan 1.\n'
          '(3)-[Passive]: Treat the Superior State as the Raging State '
          'for the effects of the Raging Aspect.\n'
          '(4)-[Triggered]: When you use the 3rd effect of Golden Power, '
          'you may enter the Superior State instead of the Raging State. '
          'If you do, the effect lasts until the start of your next '
          'turn.',
    ),
  ),

  // ========================================================= Super Saiyan 2 ===
  TransformationDef(
    name: 'Super Saiyan 2',
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 3,
    transformationLine: 'Super Saiyan',
    stage: 2,
    stressTestRequirement: 17,
    aspects: [
      'Enhanced Save (Impulsive/Corporeal)',
      'Super Saiyan Form',
      'Raging',
      'Glowing',
      'Light Dependent',
      'Draining (LV2)',
      'Power High (LV2)',
      'Difficult (LV1)',
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
        name: 'Sparking Momentum',
        description: 'Your energy is too great to contain, taking the '
            'form of lightning coursing around your aura.\n'
            '(1)-[Passive]: Increase your Initiative Value by S(T).\n'
            '(2)-[Passive]: While you are in the Raging or Superior '
            'State, increase your Strike and Dodge Rolls by 1(T).\n'
            '(3)-[Passive]: Your Attacking Maneuvers that possess a Ki '
            'Wager equal to or exceeding 1/4 of your Max Capacity have '
            'their Damage Category increased by 1 Category.\n'
            '(4)-[Triggered, 1/Encounter]: If you knock an Opponent '
            'through a Health Threshold, that Opponent gains a stack of '
            'the Broken Combat Condition until the start of your next '
            'turn. Additionally, gain an additional Action from Bonus '
            'Momentum.',
        automation: [
          // (1) +S(T) Initiative — S = this Form's Stage (2).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.initiative],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    // Difficult (LV1) → 2 Mastery levels, one Mastery Trait each.
    masteryTraits: [
      TransformationTrait(
        name: 'Ascended Past a Super Saiyan',
        description: 'You have reined in the rampant power of this form, '
            'making it your own.\n'
            '(1)-[Permanent]: Super Saiyan 2 loses both the Power High '
            'Aspect and 1 level of the Draining Aspect.\n'
            '(2)-[Passive]: Increase the Dice Score of your Steadfast '
            'Checks by 1.\n'
            '(3)-[Triggered, 1/Round]: If you succeed at a Steadfast '
            'Check, regain Ki Points equal to your Surgency.',
      ),
      TransformationTrait(
        name: 'Sparking Ascension',
        description: 'Your fine control of this form allows you to '
            'access its full power without restraint.\n'
            '(1)-[Permanent]: Super Saiyan 2 loses the Draining '
            'Aspect.\n'
            '(2)-[Passive]: Gain access to the Full Force Super Saiyan 2 '
            'Evolved Stage.',
      ),
    ],
  ),

  // ========================================================= Super Saiyan 3 ===
  TransformationDef(
    name: 'Super Saiyan 3',
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 4,
    transformationLine: 'Super Saiyan',
    stage: 3,
    stressTestRequirement: 22,
    aspects: [
      'Enhanced Save (Impulsive/Corporeal)',
      'Super Saiyan Form',
      'Raging',
      'Glowing',
      'Light Dependent',
      'Draining (LV4)',
      'Power High (LV2)',
      'Long Transformation (LV2)',
      'Exhausting',
      'Difficult (LV1)',
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Limitless',
        description: 'Your energy has surpassed all reason and '
            'restraint, straining your body to the limit.\n'
            '(1)-[Passive]: All of your Attacking Maneuvers gain the '
            'Full Wager Advantage.\n'
            '(2)-[Passive]: Increase the Wound Roll of any Attacking '
            'Maneuver you make with a Ki Wager by 1/2 of the amount of '
            'Ki Points spent on the Ki Wager.\n'
            '(3)-[Passive]: Halve the Ki Points you regain through Ki '
            'Surges and Combat Recovery.\n'
            '(4)-[Passive]: While you are in the Raging or Superior '
            'State, increase your Wound Rolls and Soak Value by 1(T).\n'
            '(5)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver that has a Ki Wager equal to or '
            'exceeding 1/4 of your Max Capacity, apply an Energy Charge '
            'to that Attacking Maneuver.',
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: 'Even Further Beyond',
        description: 'You have pushed past the limits of your power, '
            'becoming even stronger.\n'
            '(1)-[Permanent]: Super Saiyan 3 loses the Power High, Long '
            'Transformation, and the Exhausting Aspects, and 2 levels of '
            'the Draining Aspect.\n'
            '(2)-[Passive]: Ignore the 3rd effect of Limitless.',
      ),
      TransformationTrait(
        name: 'The Peak of Super Saiyan',
        description: 'You have managed, somehow, to rein in your massive '
            'pool of energy, allowing you to fight at full strength.\n'
            '(1)-[Permanent]: Super Saiyan 3 loses the Draining Aspect.',
      ),
    ],
  ),

  // ============================================ Racial "Power" Forms (Variant of
  // Power Boost) — Any-race Power Boost is an Enhancement; each Race gets its own
  // Alternate-Form Variant with Difficult (LV2) → three Mastery Traits.
  // ============================================================= Android Power ===
  TransformationDef(
    name: "Android Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Android",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Artificial Power (Overflowing Power)",
        description: "Your immense strength comes from the mechanical parts "
            "that comprise your artificial existence.\n"
            "(1)-[Passive]: Increase your maximum amount of Energy Charges by "
            "your number of Power Stacks.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Defense Value and Damage Reduction by 1(T).\n"
            "(3)-[Triggered/Power, 1/Round]: You may use the Energy Charge "
            "Maneuver as an Out-of-Sequence Maneuver.\n"
            "(4)-[Triggered/Power, 1/Encounter]: If you did not trigger the "
            "3rd effect of Artificial Power, enter the Superior State until the "
            "start of your next turn. After using this effect, you cannot "
            "trigger the 3rd effect of Artificial Power until the start of your "
            "next turn.\n"
            "(5)-[Triggered/Transform, 1/Encounter]: Use a Ki Surge as an "
            "Out-of-Sequence Maneuver. Ignore the effects of Power Battery for "
            "the sake of regaining Ki Points from this Maneuver.",
        automation: [
          // (2) While 2+ Power stacks: +1(T) Defense Value and Damage
          // Reduction.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.defenseValue,
              AffectedStat.damageReduction,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 2,
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Android Power",
        description: "You overclock your internal systems, squeezing more "
            "power out of them.\n"
            "(1)-[Permanent]: Android Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Android Power gains the Realization Aspect and "
            "M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Triggered/Power]: Regain 2(bT) Ki Points.\n"
            "(4)-[Triggered, 1/Encounter]: If you use the Energy Charge "
            "Maneuver, gain an additional stack of Energy Charge from that use "
            "of the Energy Charge Maneuver.",
      ),
      TransformationTrait(
        name: "High Android Power",
        description: "The power at your fingertips answers more easily to your "
            "call, allowing you greater efficiency.\n"
            "(1)-[Passive]: While you possess 3+ stacks of Power, increase "
            "your Wound Rolls by 1(T).\n"
            "(2)-[Passive]: Replace the [1/Encounter] Keyword for the 4th "
            "effect of Artificial Power with the [1/Round] Keyword.",
        automation: [
          // (1) While 3+ Power stacks: +1(T) Wound Rolls.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 3,
          ),
        ],
      ),
      TransformationTrait(
        name: "Maximum Android Power",
        description: "You have truly surpassed even the most notable forms of "
            "organic life, becoming virtually unstoppable.\n"
            "(1)-[Permanent]: Android Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: While you possess 3+ stacks of Power, you are "
            "considered to be in the Healthy Health Threshold (in addition to "
            "whatever Health Threshold you are in).",
      ),
    ],
  ),

  // =========================================================== Cerealian Power ===
  TransformationDef(
    name: "Cerealian Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Cerealian",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Ocular Power (Overflowing Power)",
        description: "Channeling your awakened strength into your evolved "
            "right eye grants you new and unusual abilities.\n"
            "(1)-[Passive]: Increase your maximum number of Critical Eye "
            "stacks by your number of Power stacks.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Natural Result of your Combat Rolls by 1.\n"
            "(3)-[1/Round]: You may spend 2 stacks of Critical Eye to use the "
            "Power Up Maneuver as an Instant Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you use the Power Up Maneuver, "
            "gain a Counter Action.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Maximize your stacks of "
            "Critical Eye.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Cerealian Power",
        description: "Your evolved right eye thrums with the power that fills "
            "every inch of your body.\n"
            "(1)-[Permanent]: Cerealian Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Cerealian Power gains the Realization Aspect "
            "and M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Triggered, 1/Round]: If you score a Critical Result on a "
            "Combat Roll, increase the Dice Score of that Combat Roll by 1(T)",
      ),
      TransformationTrait(
        name: "High Cerealian Power",
        description: "The power that churns inside you, enhancing your evolved "
            "right eye, now heeds your every command, granting you increased "
            "combat efficacy.\n"
            "(1)-[Passive]: If you possess 2+ stacks of Power, you may use "
            "Standard Maneuvers that are not Attacking Maneuvers and do not "
            "initiate Attacking Maneuvers through their effects after you have "
            "used the Energy Charge Maneuver but before having used the "
            "declared Attacking Maneuver.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Ocular Power.",
      ),
      TransformationTrait(
        name: "Maximum Cerealian Power",
        description: "You've become fully accustomed to the power at your "
            "fingertips, utilizing it as naturally as breathing.\n"
            "(1)-[Permanent]: Cerealian Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: If you possess 2+ stacks of Power and an Opponent "
            "enters your Melee Range, that triggers the Exploit Maneuver.",
      ),
    ],
  ),

  // ============================================================ Earthling Power ===
  TransformationDef(
    name: "Earthling Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Earthling",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Resolute Power (Overflowing Power)",
        description: "Your determination to win, despite the odds, fuels your "
            "newfound strength.\n"
            "(1)-[Passive]: Increase the Wound Rolls of your Signature "
            "Techniques by 1(T) for each stack of Power you possess.\n"
            "(2)-[1/Round]: While you are below the Injured Health Threshold, "
            "you may use the Power Up Maneuver as an Instant Maneuver.\n"
            "(3)-[Triggered/Power, 1/Round]: You may use the Energy Charge "
            "Maneuver as an Out-of-Sequence Maneuver. If you do, you must "
            "declare one of your Signature Techniques for that use of the "
            "Energy Charge Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you trigger the 2nd effect of "
            "Earthling Resolve, you may spend a stack of Power to set the "
            "Natural Result of your reroll to 10.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Earthling Power",
        description: "The weaker you feel, the stronger your determination "
            "becomes, and the deeper your reserve of power seems to grow.\n"
            "(1)-[Permanent]: Earthling Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Earthling Power gains the Realization Aspect "
            "and M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: While you have 2+ stacks of Power, increase the "
            "Dice Score of your Steadfast Checks by 1.\n"
            "(4)-[Triggered/Threshold]: Gain a stack of Power until the end of "
            "your next turn.",
      ),
      TransformationTrait(
        name: "High Earthling Power",
        description: "Your sheer willpower in the face of unbeatable odds "
            "allows you to create openings that weren't possible before.\n"
            "(1)-[Triggered]: If you use the 4th effect of Resolute Power, you "
            "may choose to reduce your Life Points by 4(bT) instead of losing "
            "your stack of Power.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Resolute Power.",
      ),
      TransformationTrait(
        name: "Maximum Earthling Power",
        description: "You have learned to dig even deeper into your soul in "
            "search of the strength you need, tapping reserves of power no one "
            "could have foreseen, not even you.\n"
            "(1)-[Permanent]: Earthling Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: While you have 3+ stacks of Power, treat yourself "
            "as if you were also in the Health Threshold below your current "
            "Health Threshold for your effects.",
      ),
    ],
  ),

  // ============================================================== Genetic Power ===
  TransformationDef(
    name: "Genetic Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Scaling (LV2)",
      "High Speed (LV1)",
      "Realization",
      "Dedicated",
      "Draining (LV2)",
      "Difficult (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Genetic Transformation",
        description: "Each of your unique genetic contributors offers a new "
            "source of power to your new transformation, creating something "
            "wholly unique to you.\n"
            "-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select and gain a Genetic Trait. For each base "
            "Tier of Power gained after Tier of Power 2, gain an additional "
            "Genetic Trait (max. +2). You can only select a Genetic Trait that "
            "has a Race specified in brackets that you selected through the "
            "Multi-Option effect of Genetic Splicing.\n"
            "-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, choose up to 3 of the following Aspects for this "
            "Transformation to gain (you can choose each one multiple times if "
            "it has levels, with each choice counting as a single level of "
            "that Aspect): Enhanced Save (Any) - this can be chosen multiple "
            "times, select a different Saving Throw each time; Growth; Raging "
            "(you cannot select this Aspect if you also select Mindful); "
            "Mindful (you cannot select this Aspect if you also select "
            "Raging); Bulky.\n"
            "Select your Genetic Trait(s) below (Race-keyed; you may only "
            "pick ones whose bracketed Race you chose through Genetic "
            "Splicing).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Genetic Trait',
            maxChoices: 3,
            options: [
              TraitOption(
                name: 'Overcharge (Android)',
                description: 'You are able to charge your cells and your '
                    'implants with even more energy from your power core. '
                    '-[Passive]: Increase the amount of Ki Points regained '
                    'through effects by 2(bT). -[Triggered/Start of Combat '
                    'Round]: Reduce your Ki Points by 6(bT) to increase your '
                    'Damage Reduction by 2(bT) until the end of the Combat '
                    'Round. -[Triggered, 1/Round]: If you would regain 4(bT) '
                    'or more Ki Points, reduce your Ki Points by 2(bT) to use '
                    'the Energy Charge Maneuver as an Out-of-Sequence '
                    'Maneuver.',
              ),
              TraitOption(
                name: 'Stroke of Death (Arcosian)',
                description: 'Your power is surpassed only by your cruelty. '
                    '-[Passive]: Increase the amount of Life Points you regain '
                    'through the effects of Legend Realized by 1d10(bT). '
                    '-[1/Round]: Use the Basic Attack Maneuver as an Instant '
                    'Maneuver.',
              ),
              TraitOption(
                name: 'Evolved Sniper (Cerealian)',
                description: 'Your red eye has evolved, allowing you to target '
                    'weak points in your enemies with maximum efficiency. '
                    '-[Permanent, Passive]: Upon gaining this Genetic Trait, '
                    "select and gain one of the Option effects for Sniper's "
                    'Art. -[Triggered]: If you score a Critical Result on the '
                    'Strike Roll of a Signature Technique, that Attacking '
                    'Maneuver gains an Energy Charge.',
              ),
              TraitOption(
                name: 'Super Battle for the Whole Planet (Custom Species)',
                description: 'You have reached your peak. -[Passive]: Your '
                    'Custom Species Secondary Trait(s) gain their Flaw '
                    'effects. If none of those Traits possess Flaw effects or '
                    'already have access to them due to Better Trait, this '
                    'Transformation instead gains the Perfect Ki Control '
                    'Aspect and has its AMB (FO/MA) increased by 1(T). '
                    '-[Passive]: While your Life Points are below the Bruised '
                    'Health Threshold, your Max Capacity is increased by 1/4. '
                    '-[Permanent, Option]: Select and gain one of: Powerful '
                    'Genes [Passive]: Gain the Bio-Android Option effect of '
                    'Natural Power. Heroic Finish [Triggered, 1/Round]: If you '
                    'use a Signature Technique that does not possess an AoE, '
                    'apply your highest Attribute Modifier to the Wound Roll of '
                    'that Attacking Maneuver. Lovely Fixation [Triggered/Start '
                    'of Combat Round]: Choose an Opponent; you can only target '
                    'that Opponent with Attacking Maneuvers this Combat Round, '
                    'but you may move towards them or Basic Attack them '
                    'Out-of-Sequence. Evolving Monster [Permanent, Passive]: '
                    'Gain a Monster Trait and treat this Transformation as '
                    'Monster Form for any effects.',
              ),
              TraitOption(
                name: 'Bio-Tension (Earthling)',
                description: 'The adrenaline surging through your body causes '
                    'your muscles to tense. -[Passive]: You can use the '
                    'Signature Technique Maneuver an additional time each '
                    'Combat Round. -[Triggered, 2/Round]: If you would use the '
                    'Signature Technique Maneuver, you can spend your Life '
                    "Points as if they were Ki Points to pay for that "
                    "Signature Technique's Ki Point Cost (up to 1/2 of that "
                    "cost).",
              ),
              TraitOption(
                name: 'Spellbound (Majin)',
                description: 'Your strange mystical powers grow. -[Permanent, '
                    'Passive]: Upon gaining this Genetic Trait, select another '
                    'Majin Secondary Trait to gain while in this '
                    'Transformation. -[Triggered/Threshold]: Regain 1d6(T) '
                    'Life and Ki Points.',
              ),
              TraitOption(
                name: 'Perfect Cells (Namekian)',
                description: 'You have become nearly unkillable. '
                    '-[Triggered/Power, 1/Round]: If you have 2+ Power stacks, '
                    'target an Opponent; increase your Wound Rolls against '
                    'that Opponent by 1d4(T) until the start of your next '
                    'turn. -[Passive]: Increase your Tier of Power Extra Dice '
                    'for any Combat Rolls against an Opponent by 1 Dice '
                    'Category while you are above the Bruised Health '
                    'Threshold. -[Triggered, 1/Encounter]: If you use a '
                    'Healing Surge, enter the Surging State until the end of '
                    'your next turn.',
              ),
              TraitOption(
                name: 'Spiteful Annihilation (Neo-Tuffle)',
                description: 'You are prepared to completely wipe the targets '
                    'of your hatred from existence. -[Passive]: While you have '
                    '2+ stacks of Power, increase your Tier of Power Extra '
                    'Dice by 2 Dice Categories. -[Triggered, 1/Round]: If you '
                    'hit an Opponent with an Attacking Maneuver that has any '
                    'number of Energy Charges, increase the Wound Roll by 1(T) '
                    'for every Energy Charge applied to that Attacking '
                    'Maneuver.',
              ),
              TraitOption(
                name: 'Gleaming Might (Saiyans)',
                description: 'Your thirst for battle ignites into a golden '
                    'aura. -[Passive]: This Transformation gains the Glowing '
                    'and Light Dependent Aspects. -[Passive]: Apply your base '
                    'Tier of Power Extra Dice to your Combat Rolls. '
                    '-[Passive]: Increase your Initiative Value by 1(T). '
                    '-[Triggered/Transform]: Regain Ki Points equal to 1/4 of '
                    'your Max Capacity.',
              ),
              TraitOption(
                name: 'Draconic Perfection (Shadow Dragon)',
                description: 'You have shed your skin and emerged anew. '
                    '-[Triggered, 1/Round]: If you lose at least 8(bT) Life '
                    'Points or more as a result of a single effect or '
                    'Attacking Maneuver, gain a stack of Power until the end '
                    'of the Combat Round. -[Triggered/Start of Combat Round]: '
                    'For each stack of Power you possess, Opponents within a '
                    'Sphere AoE (centered on you) have their Life Points '
                    'reduced by 3(bT). -[Triggered/Transform]: Use the Power '
                    'Up Maneuver as an Out-of-Sequence Maneuver.',
              ),
              TraitOption(
                name: 'Cosmic Energy (Shinjin)',
                description: 'Your god-like speed and efficiency increases. '
                    '-[Passive]: Each time you spend a Counter Action, regain '
                    '2(bT) Ki Points. -[Triggered/Start of Combat Round, '
                    '2/Encounter]: Gain an additional Counter Action to use '
                    'during this Combat Round. -[Permanent, Option]: Select '
                    'and gain one of: Bio-Malice [Triggered, 1/Round]: If you '
                    'would use the Signature Technique Maneuver, you may spend '
                    'the Ki Points of an Opponent or Ally within your Melee '
                    'Range for the Ki Point Cost instead (up to 1/2 of that '
                    'cost). Bio-Radiance [Triggered, 1/Round]: If you deal '
                    'Damage to an Opponent with an Attacking Maneuver, target '
                    'all Allies and Opponents within a Sphere AoE (centered on '
                    'that Opponent); your Allies regain Life Points equal to '
                    'your Might, while your Opponents lose an equal amount.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Cellular Power",
        description: "Your bio-engineered cells are practically exploding with "
            "power that grows alongside you.\n"
            "-[Passive]: For each base Tier of Power you have reached after "
            "Tier of Power 2, increase the High Speed Aspect for Genetic Power "
            "by 1 level.\n"
            "-[Passive]: For each stack of Power you possess, increase your "
            "Tier of Power Extra Dice by 1 Dice Category.\n"
            "-[Triggered/Power, 1/Encounter]: Enter the Power Stressed Special "
            "State until you are Defeated or leave this Transformation.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Further Perfection",
      description: "You have truly perfected this unique power of yours, "
          "making it effortless for you.\n"
          "-[Permanent]: Genetic Power loses the Draining Aspect.\n"
          "-[1/Encounter]: You may exit the Power Stressed Special State as an "
          "Instant Maneuver.\n"
          "-[Permanent, Passive]: Upon gaining this Mastery, select an "
          "additional 2 Aspects as per the rules of the second effect of "
          "Genetic Transformation.\n"
          "-[Permanent]: Genetic Power gains the Natural Aspect.",
    ),
  ),

  // ================================================================ Glass Power ===
  TransformationDef(
    name: "Glass Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Glass Tribe",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Reflective Power (Overflowing Power)",
        description: "With your control over glass, you redirect your newfound "
            "power into controlling the battlefield and making your enemies "
            "suffer.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Soak Value by 2(T).\n"
            "(2)-[Passive]: Reduce the Ki Point Cost of your Attacking "
            "Maneuvers of the Glass Profile by 1(T) for each stack of Power "
            "you possess. If that Attacking Maneuver only possesses the Glass "
            "Profile, this can allow it to reduce the Ki Point Cost of that "
            "Attacking Maneuver to 0.\n"
            "(3)-[Triggered]: Upon gaining a stack of Power, you may apply the "
            "Glass Environmental Quality to a Square you are occupying or any "
            "adjacent Square of your choice.\n"
            "(4)-[Triggered/Start of Turn]: Remove the Glass Environmental "
            "Quality from all Squares within a Minor Sphere AoE (centered on "
            "you). If you removed the Environmental Quality from at least 7 "
            "Squares using this effect, you may use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(5)-[Triggered, 1/Encounter]: If you hit an Opponent with an "
            "Attacking Maneuver while in the Surging State, you may apply a "
            "number of Energy Charges to that Attacking Maneuver equal to your "
            "number of Power stacks. After using this effect, lose all stacks "
            "of Power you possess.",
        automation: [
          // (1) While 2+ Power stacks: +2(T) Soak Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
            conditionAmount: 2,
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Glass Power",
        description: "The glass you create is infused with your new power, "
            "too, becoming deadlier.\n"
            "(1)-[Permanent]: Glass Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Glass Power gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Triggered, 1/Round]: If you win the Clash for the effects of "
            "Glassification against an Opponent, reduce their Life Points by "
            "x(T), where x is equal to the sum of the number of times that "
            "Opponent was targeted by the effects of Glassification and your "
            "number of Power Stacks.",
      ),
      TransformationTrait(
        name: "High Glass Power",
        description: "You draw in power from the glass on the battlefield, "
            "using it against your enemies.\n"
            "(1)-[Passive]: Gain an additional stack of Power from the Power "
            "Up Maneuver used through the 4th effect of Reflective Power.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 5th effect of Reflective Power.",
      ),
      TransformationTrait(
        name: "Maximum Glass Power",
        description: "The glass that makes up your body seems to never crack, "
            "much less shatter; to a lesser fighter, you appear nigh "
            "invincible.\n"
            "(1)-[Permanent]: Glass Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: While you are above the Injured Health Threshold "
            "but below the Bruised Health Threshold and have 2+ stacks of "
            "Power, treat yourself as if you are in the Healthy Health "
            "Threshold for all of your effects.",
      ),
    ],
  ),

  // ============================================================ Konatsian Power ===
  TransformationDef(
    name: "Konatsian Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Konatsian",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Corporeal/Morale)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Tension Power (Overflowing Power)",
        description: "As the stakes grow ever higher, so too does the power "
            "you draw from within.\n"
            "(1)-[Passive]: For each stack of Power you possess, increase your "
            "Damage Reduction by 1(T).\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, treat your "
            "number of Tension stacks as if they were 1 higher for your "
            "effects.\n"
            "(3)-[1/Round]: While you are below the Injured Health Threshold, "
            "you may use the Power Up Maneuver as an Instant Maneuver.\n"
            "(4)-[Triggered/Power, 1/Encounter]: You may spend any number of "
            "Tension stacks. For each Tension stack spent, you gain an "
            "additional stack of Power through this use of the Power Up "
            "Maneuver.",
        automation: [
          // (1) +1(T) Damage Reduction per Power stack.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perPowerStack,
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Konatsian Power",
        description: "You take control of the flow of battle, turning power "
            "into technique.\n"
            "(1)-[Permanent]: Konatsian Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Konatsian Power gains the Realization Aspect "
            "and M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: Increase your Wound Rolls by 1/4 (rounded up) of "
            "your Damage Reduction.\n"
            "(4)-[Passive]: You may spend your stacks of Power as if they were "
            "stacks of Tension for the effects of your Vocation(s).",
      ),
      TransformationTrait(
        name: "High Konatsian Power",
        description: "As you master your immense power, you learn that the "
            "stakes are always higher than they appear.\n"
            "(1)-[Passive]: While you possess 3+ stacks of Power, treat your "
            "number of Tension stacks as if they were 1 higher for your "
            "effects.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Tension Power.",
      ),
      TransformationTrait(
        name: "Maximum Konatsian Power",
        description: "Your power carries with it the hopes and wishes of your "
            "people.\n"
            "(1)-[Passive]: Increase your maximum number of Power Stacks by "
            "1.\n"
            "(2)-[Triggered/Start of Turn, 1/Encounter]: You may spend 2 "
            "stacks of Power to enter the Entrusted State until the end of "
            "your turn.",
      ),
    ],
  ),

  // ================================================================ Majin Power ===
  TransformationDef(
    name: "Majin Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Majin",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Paranormal Power (Overflowing Power)",
        description: "You are insanely tenacious and impossibly difficult to "
            "put down for very long- comrades hail your resilience, while foes "
            "fear the force of your undying power.\n"
            "(1)-[Passive]: For each stack of Power you possess after the "
            "first, increase your Soak Value by 1(T).\n"
            "(2)-[1/Round]: If you have 2+ stacks of Power, you may use the "
            "Deflect option of the Intervene Maneuver or the Parry option of "
            "the Defend Maneuver without spending a Counter Action.\n"
            "(3)-[Triggered]: If you use a Healing Surge, you may spend any "
            "number of Power Stacks. For each Power Stack spent, increase the "
            "amount of Life Points you regain by 3(bT).\n"
            "(4)-[Triggered, 1/Encounter]: If you are below the Injured Health "
            "Threshold, you may use a Healing Surge as an Instant Maneuver.\n"
            "(5)-[Triggered, 1/Encounter]: If you use a Healing Surge, you may "
            "use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Majin Power",
        description: "No matter how much damage you take, you never seem to be "
            "hurt for long.\n"
            "(1)-[Permanent]: Majin Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Majin Power gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Triggered/Threshold]: Gain a stack of Power until the end of "
            "your next turn.\n"
            "(4)-[Triggered, 1/Round]: If you spend 2+ stacks of Power on a "
            "Healing Surge through the 3rd effect of Paranormal Power, you may "
            "increase the Healing Surge by 1 Dice Category.",
      ),
      TransformationTrait(
        name: "High Majin Power",
        description: "Your wellspring of power seems to never run dry.\n"
            "(1)-[Triggered/Start of Turn]: If you are in the Healthy Health "
            "Threshold and have no stacks of Power, you may reduce your Life "
            "Points by 4(bT) to use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 5th effect of Paranormal Power.",
      ),
      TransformationTrait(
        name: "Maximum Majin Power",
        description: "Even as you regenerate from yet another superficial "
            "scratch, you use your strange, goo-like anatomy to launch "
            "surprise attacks.\n"
            "(1)-[Permanent]: Majin Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Triggered]: If you spend at least 1 stack of Power on a "
            "Healing Surge through the 3rd effect of Paranormal Power, you may "
            "use the Basic Attack Maneuver or Signature Technique Maneuver as "
            "an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ============================================================= Namekian Power ===
  TransformationDef(
    name: "Namekian Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Namekian",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Corporeal/Morale)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Emerald Power (Overflowing Power)",
        description: "Your Namekian biology responds to your increased power "
            "as your regeneration speeds up and your senses sharpen.\n"
            "(1)-[Passive]: Increase your Surgency by 1(T) for each stack of "
            "Power you possess.\n"
            "(2)-[Passive]: Increase the amount of Life Points regained due to "
            "the 6th effect of Namekian Biology by 1(bT) for each stack of "
            "Power you possess.\n"
            "(3)-[Triggered, 1/Round]: If you succeed at a Steadfast Check, "
            "trigger the 6th effect of Namekian Biology.\n"
            "(4)-[Triggered, 1/Encounter]: If you use a Healing Surge, you may "
            "spend 2(bT) Ki Points to use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Select a Character. They "
            "become Studied until the start of your next turn.",
        automation: [
          // (1) +1(T) Surgency per Power stack.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perPowerStack,
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Namekian Power",
        description: "You bring out the latent potential of your Namekian "
            "blood, becoming significantly stronger.\n"
            "(1)-[Permanent]: Namekian Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Namekian Power gains the Realization Aspect and "
            "M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Dice Score of your Steadfast Checks by 1.\n"
            "(4)-[Triggered, 1/Round]: If your Opponent would stop being "
            "studied by any effect, except due to the 2nd effect of "
            "Intelligent Fighter, you may choose to instead lose a stack of "
            "Power.",
      ),
      TransformationTrait(
        name: "High Namekian Power",
        description: "The power you unleash further strengthens your "
            "regeneration and your keen senses, making you nearly "
            "unstoppable.\n"
            "(1)-[Passive]: The 1/Encounter Keyword becomes 1/Round for the "
            "4th effect of Emerald Power.\n"
            "(2)-[Passive]: The 1/Encounter Keyword becomes M/Encounter for "
            "the 5th effect of Emerald Power.",
      ),
      TransformationTrait(
        name: "Maximum Namekian Power",
        description: "You have meticulously gathered and refined your strength "
            "to achieve results few others could even dream of.\n"
            "(1)-[Permanent]: Namekian Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Triggered/Power, 1/Round]: Regain Life Points equal to 1/2 "
            "of your Surgency.",
      ),
    ],
  ),

  // =============================================================== Mortal Power ===
  TransformationDef(
    name: "Mortal Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Angel",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Worldly Power (Overflowing Power)",
        description: "Restraining yourself from using the power of the gods, "
            "you turn the power of mortals into a fine-edged scalpel, instead "
            "of the hammer most mortals use it as.\n"
            "(1)-[Passive]: Increase your Soak Value by 1(T) for each stack of "
            "Power you possess. The maximum bonus for this effect is equal to "
            "x(T), where x is equal to how many Health Thresholds you are "
            "above.\n"
            "(2)-[1/Round]: If you have no Counter Actions, you may use the "
            "Power Up Maneuver as an Instant Maneuver during your turn.\n"
            "(3)-[Triggered, 1/Round]: If you use the 2nd effect of Lingering "
            "Instincts, increase that Combat Roll by 1(T) for the duration of "
            "that Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you take no Damage from an "
            "Attacking Maneuver that targeted you, you may use a Standard "
            "Maneuver with an Action Cost of 1 Action as an Out-of-Sequence "
            "Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Mortal Power",
        description: "Your instincts guide your attacks, emboldened by the "
            "power you are now wielding.\n"
            "(1)-[Permanent]: Mortal Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Mortal Power gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: If you possess 2+ stacks of Power, you may double "
            "the bonus from the 3rd effect of Worldly Power.",
      ),
      TransformationTrait(
        name: "High Mortal Power",
        description: "Your body moves with fluid grace that seems almost "
            "unnatural in the realm of mortals.\n"
            "(1)-[Passive]: While you are in the Healthy Health Threshold and "
            "possess 2+ stacks of Power, increase your Awareness and Defense "
            "Value by 1(T).\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Worldly Power.",
      ),
      TransformationTrait(
        name: "Maximum Mortal Power",
        description: "You shrug off your wounds as though they aren't even "
            "there thanks to the intense power you've learned to wield.\n"
            "(1)-[Permanent]: Mortal Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: While you have 3+ stacks of Power, treat yourself "
            "as if you were also in the Health Threshold above your current "
            "Health Threshold for your effects.",
      ),
    ],
  ),

  // ============================================================== Shinjin Power ===
  TransformationDef(
    name: "Shinjin Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Shinjin",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Centred Power (Overflowing Power)",
        description: "Your mastery over your self allows you to wield your "
            "unparalleled might with surgical precision.\n"
            "(1)-[Passive]: Increase the amount of Life and Ki Points you "
            "recover from Combat Recovery by 2(T) for each stack of Power you "
            "possess.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, double the "
            "bonus from the 3rd effect of Skill of the Watcher.\n"
            "(3)-[Triggered/Power, 1/Round]: Gain 1 Counter Action.\n"
            "(4)-[Triggered, 1/Encounter]: If you use the Power Up Maneuver "
            "through the 5th effect of Skill of the Watcher, gain an "
            "additional stack of Power from that Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Shinjin Power",
        description: "The power you wield settles into your soul, becoming "
            "familiar and easily accessible.\n"
            "(1)-[Permanent]: Shinjin Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Shinjin Power gains the Realization Aspect and "
            "M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Dice Score of your Skill Checks by 1.\n"
            "(4)-[Passive]: While you possess 2+ stacks of Power, you cannot "
            "gain the Compelled Combat Condition (except through the Rampaging "
            "Aspect).",
      ),
      TransformationTrait(
        name: "High Shinjin Power",
        description: "With the skill of one who oversees the universe, you can "
            "transform your power into whatever you need it for at the drop of "
            "a hat.\n"
            "(1)-[1/Round]: You may use a Counter Maneuver with an Action Cost "
            "of 1 Counter Action without spending a Counter Action by spending "
            "a stack of Power.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Centred Power.",
      ),
      TransformationTrait(
        name: "Maximum Shinjin Power",
        description: "The power you have obtained resonates within you, "
            "serving you as naturally as you serve others.\n"
            "(1)-[Permanent]: Shinjin Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain through the 4th effect of Skill of the Watcher by 1(bT) "
            "for each Counter Action.",
      ),
    ],
  ),

  // =============================================================== Negative Power ===
  TransformationDef(
    name: "Negative Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Shadow Dragon",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal/Morale)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Shadow Power (Overflowing Power)",
        description: "The area around you becomes warped, tainted by the "
            "reality-corrupting negative energy that flows from you like an "
            "unstoppable tide.\n"
            "(1)-[Ruling]: All Squares within a Large Sphere AoE (centered on "
            "you) are in the 'Shadow Zone'. Any penalties granted by effects "
            "that reference the Shadow Zone do not stack from multiple "
            "Characters, but instead take the largest bonus from among the "
            "Characters who are currently in the Negative Power "
            "Transformation.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, reduce the "
            "Combat Rolls of all Opponents in the Shadow Zone by 1(T).\n"
            "(3)-[Passive]: All Opponents in the Shadow Zone have their "
            "Surgency reduced by 2(bT) for each stack of Power you possess.\n"
            "(4)-[Triggered/Power, 1/Round]: Make a Morale Clash against all "
            "Opponents within the Shadow Zone. If you win against an Opponent, "
            "that Opponent gains a stack of the Impaired Combat Condition until "
            "the start of your next turn.\n"
            "(5)-[Triggered, 1/Encounter]: If you inflict the Impaired Combat "
            "Condition on an Opponent(s), you may use the Power Up Maneuver as "
            "an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Negative Power",
        description: "You warp your reality-defying presence further, turning "
            "competent foes into simpering buffoons.\n"
            "(1)-[Permanent]: Negative Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Negative Power gains the Realization Aspect and "
            "M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: Increase the Magnitude for the Shadow Zone's AoE "
            "by 1.\n"
            "(4)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Botch Range of all Combat Rolls made by Opponents in the Shadow "
            "Zone by 1.",
      ),
      TransformationTrait(
        name: "High Negative Power",
        description: "The effects of your corruptive energy further reshape "
            "reality, making those who you've affected vulnerable.\n"
            "(1)-[Passive]: All Opponents with the Impaired Combat Condition "
            "in the Shadow Zone have their Soak Value reduced by 1(bT) for "
            "each stack of Power you possess.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 5th effect of Shadow Power.",
      ),
      TransformationTrait(
        name: "Maximum Negative Power",
        description: "The negative energy you wield has become like air, "
            "allowing you to breathe it in and exhale it with but a mere "
            "gesture.\n"
            "(1)-[Permanent]: Negative Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: Increase the Magnitude for the Shadow Zone's AoE "
            "by 1.\n"
            "(4)-[Triggered/Power]: Gain 1 Negative Energy.",
      ),
    ],
  ),

  // ================================================================= Super Demon ===
  TransformationDef(
    name: "Super Demon",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Demon",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Enhanced Save (Corporeal/Cognitive/Morale)",
      "Difficult (LV1)",
      "Power High (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Fiendish Power",
        description: "Unleashing the power deep within your demonic blood, you "
            "tap into a massive burst of strength.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select and gain access to a Demonic Trait while "
            "you are in this Transformation.\n"
            "(2)-[Passive]: For each stack of Demonic Power you possess, "
            "increase your Strike and Dodge Rolls by 1(T).\n"
            "(2)-[Passive]: For each stack of Demonic Power you possess, "
            "increase your Tier of Power Extra Dice by 1 Dice Category.\n"
            "(4)-[Passive]: For each stack of Demonic Fatigue you possess, "
            "increase the Ki Point Cost of your Attacking Maneuvers by 1(T).\n"
            "(5)-[Triggered, 1/Round]: If you use Legend Realized, make a "
            "Pressure Check.\n"
            "(6)-[Triggered, 1/Encounter]: If you succeed at a Pressure Check "
            "while already having 2+ stacks of Demonic Power, all Opponents "
            "within a Huge Sphere AoE (centered on you) have their Life Points "
            "reduced by your Might.\n"
            "Select your Demonic Trait below (subrace-gated as noted).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Demonic Trait',
            options: [
              TraitOption(
                name: 'Demonic Battle',
                description: 'Your back-handed strategies and cutthroat '
                    'tactics leave your enemies reeling. (1)-[Passive]: '
                    'Increase your Combat Rolls made against Opponents who are '
                    'suffering from a Combat Condition by 1(T). (2)-[Passive]: '
                    'Increase your Might by 1(T). (3)-[Passive]: Apply an '
                    'Energy Charge to your Signature Techniques that target at '
                    'least 1 Opponent suffering from a Combat Condition. '
                    '(4)-[1/Round]: If you are adjacent to an Opponent '
                    'suffering from a Combat Condition, you may use the Basic '
                    'Attack Maneuver as an Instant Maneuver (target that '
                    'Opponent). (5)-[Triggered, 1/Round]: If you inflict a '
                    'Combat Condition on an Opponent, you may use the Power Up '
                    'Maneuver as an Out-of-Sequence Maneuver.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.might],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Demon Realm Elite (Demon Person Subrace)',
                description: 'As one of the strongest in the Demon Realm, '
                    'entire worlds tremble in fear. (1)-[Prerequisite]: You '
                    'are of the Demon Person Subrace. (2)-[Passive]: Increase '
                    'your Combat Rolls and Soak Value by 1(T) while an '
                    'Opponent is suffering from a Combat Condition that you '
                    'inflicted. (3)-[1/Round]: You may spend stacks of Demonic '
                    'Power as if they were Actions/Counter Actions for the '
                    'Action Cost of your Magical Unique Abilities that have an '
                    'Action Cost of 1 Action/Counter Action. (4)-[Choice]: '
                    'Depending on your choice for the 3rd effect of Denizen of '
                    'the Demon Realm, apply the following: Demon Warrior '
                    '[Passive]: +1(T) Strike and Wound of Armed Attacks. Demon '
                    'Mage [Passive]: +1(T) Strike and Wound of Magic Attacks. '
                    'Demon Face [Passive]: Super Demon gains an AMB (SC/PE) '
                    'equal to its AMB (MA). Elemental Demon [Passive]: Reduce '
                    'the Ki Point Cost of your Favored Elements by 2(T). '
                    'Gigantic Demon [Passive]: Increase the Dice Category of '
                    'your Punching Down Extra Dice by 1. Transforming Demon '
                    '[Passive]: Increase the AMB (FO/MA) of Super Demon by '
                    '1(T).',
              ),
              TraitOption(
                name: 'Makyan Might (Makyan Subrace)',
                description: 'Empowered by the might of the Makyo Star, you '
                    'grow to massive proportions. (1)-[Prerequisite]: You are '
                    'of the Makyan Subrace. (2)-[Passive]: Super Demon gains '
                    'the Growth (LV1) and Bulky Aspects. (3)-[Passive]: While '
                    'you possess a stack of Demonic Power, reduce your Muscle '
                    'Penalty by 1(bT). (4)-[Passive]: While you possess 3+ '
                    'stacks of Demonic Power, increase your Wound Rolls, Soak '
                    'Value and Might by 1(T). (5)-[Triggered, 1/Round]: If you '
                    'apply the 4th effect of Demons of the Makyo Star to a '
                    'Pressure Check, you may reduce the Dice Score of that '
                    'Pressure Check by 2; if you succeed, gain 1 Action.',
              ),
              TraitOption(
                name: "Fallen Idol's Superiority (Phantom Subrace)",
                description: 'Unbreakable and unfathomable, your monstrous '
                    'intensity shatters the battlefield. (1)-[Prerequisite]: '
                    'You are of the Phantom Subrace. (2)-[Permanent, Passive]: '
                    'Upon gaining access to this Demonic Trait, select and '
                    'gain access to up to 2 Bestial Traits while in this '
                    'Transformation. (3)-[Passive]: Increase the Dice Score of '
                    'your Pressure Checks by 2; reduce this bonus by 1 for '
                    'every Bestial Trait you possess from the 2nd effect. '
                    '(4)-[Passive]: While you possess 2+ stacks of Demonic '
                    'Power, increase your Combat Rolls by 1(T). (5)-[Triggered, '
                    '1/Encounter]: If an Opponent gains a Combat Condition due '
                    'to your use of the 4th effect of Fallen Idol, enter the '
                    'Superior State until the start of your next turn.',
              ),
            ],
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Fiendish Mastery",
        description: "Your demonic nature awakens further, unleashing deeper "
            "reserves of power.\n"
            "(1)-[Permanent]: Super Demon loses M levels of the Power High "
            "Aspect.\n"
            "(2)-[Permanent]: Super Demon gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Passive]: The 6th effect Fiendish Power loses the "
            "[1/Encounter] Keyword and gains the [M/Round, 3/Encounter] "
            "Keywords.\n"
            "(4)-[Triggered]: If you succeed at a Pressure Check, regain M(bT) "
            "Life and Ki Points.\n"
            "(5)-[Triggered/Power, M/Encounter]: Make a Pressure Check.",
      ),
      TransformationTrait(
        name: "Fiendish Evolution",
        description: "Pushing your power to its functional limit, you evolve "
            "into something even greater than a mere demon.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Demonic Power, "
            "Super Demon gains the Armored Aspect.\n"
            "(2)-[Triggered/Start of Turn, 1/Encounter]: Ignore the 3rd effect "
            "of Demonic Pressure.",
      ),
    ],
  ),

  // ================================================================= Neko Power ===
  TransformationDef(
    name: "Neko Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Neko Majin",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Copycat Power (Overflowing Power)",
        description: "Channeling your newfound strength into your copied "
            "techniques and abilities, you are able to overwhelm enemies with "
            "the sheer force and diversity of your arsenal.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power and an "
            "Integrated Majin Dama, increase the Wound Rolls of your Signature "
            "Techniques by 1(T) and increase your Might by 1(T) for any "
            "Clashes initiated by an Opponent.\n"
            "(2)-[Passive]: Reduce the Ki Point Cost of all your Copied "
            "Techniques by 1(T) for each stack of Power you possess.\n"
            "(3)-[Triggered/Power, 1/Round]: Select one of your Copied "
            "Techniques. If you use that Signature Technique during this turn, "
            "you may apply an Energy Charge to that Attacking Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you gain a Copied Technique, you "
            "may use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Neko Power",
        description: "You learn to mimic even more new abilities at a time.\n"
            "(1)-[Permanent]: Neko Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Neko Power gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, you cannot "
            "gain the Sleeping Combat Condition.\n"
            "(4)-[Triggered, 1/Round]: If you gain a Copied Technique, you may "
            "spend a stack of Power to not have that Copied Technique count "
            "towards your maximum number of Copied Techniques for the "
            "remainder of the Combat Encounter.",
      ),
      TransformationTrait(
        name: "High Neko Power",
        description: "You no longer answer to the whims of fate; you take "
            "control of them, copying even Lady Luck, if you must.\n"
            "(1)-[1/Encounter]: If you possess 2+ stacks of Power, you may use "
            "the 6th effect of Neko Majin-Dama without it counting towards its "
            "[x/Encounter] limit.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 4th effect of Copycat Power.",
      ),
      TransformationTrait(
        name: "Maximum Neko Power",
        description: "Your mimicry becomes unparalleled, thanks to the unique "
            "way you channel your raw power into your mimicked techniques.\n"
            "(1)-[Permanent]: Neko Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Triggered, 1/Encounter]: If you use a Copied Technique, you "
            "may double the bonus to your Strike and Wound Rolls from your "
            "Power Stacks for the duration of that Attacking Maneuver.",
      ),
    ],
  ),

  // ================================================================== Neo Power ===
  TransformationDef(
    name: "Neo Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Neo-Tuffle",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Corporeal/Impulsive/Cognitive)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Tuffle Power (Overflowing Power)",
        description: "With the power at your command, revenge has never tasted "
            "so sweet.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power, all of your "
            "Opponents are considered to be your Inferior (you still declare "
            "an Inferior through the 1st effect of Tuffle Superiority).\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Damage Reduction by 1(T).\n"
            "(3)-[Passive]: Depending on your Subrace, gain one of the "
            "following effects: Hatred Embodiment [Triggered/Power, 1/Round]: "
            "Use the Energy Charge Maneuver as an Out-of-Sequence Maneuver; "
            "Parasite [Triggered/Power]: Gain 1 Revenge Point.\n"
            "(4)-[Triggered/Start of Turn]: If you possess 2+ stacks of Power, "
            "gain 1 Revenge Point.\n"
            "(5)-[1/Encounter]: Spend 2 Revenge Points to use the Power Up "
            "Maneuver as an Instant Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Neo Power",
        description: "Soon, the power to achieve your revenge will be at hand, "
            "and all will celebrate the day those vermin died.\n"
            "(1)-[Permanent]: Neo Power loses the Exhausting and Draining "
            "Aspects.\n"
            "(2)-[Permanent]: Neo Power gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: Increase the amount of Revenge Points gained "
            "through the 4th effect of Tuffle Power by 1.\n"
            "(4)-[Triggered, M/Encounter]: When making an Attacking Maneuver, "
            "gain a number of Revenge Points equal to your number of Power "
            "Stacks and then immediately spend them on that Attacking "
            "Maneuver.",
      ),
      TransformationTrait(
        name: "High Neo Power",
        description: "With the power to finally enact your vengeful mandate, "
            "you crush all who ever opposed your fallen race.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Dice Category of your Energy Charges by 1 Category.\n"
            "(2)-[Passive]: The 5th effect of Tuffle Power loses the "
            "[1/Encounter] Keyword and gains the [M/Encounter] Keyword.",
      ),
      TransformationTrait(
        name: "Maximum Neo Power",
        description: "At the true heights of power, the only thing that "
            "remains is for you to execute your grudge and avenge your "
            "people.\n"
            "(1)-[Permanent]: Neo Power gains 1 level of the Natural Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: Increase the amount of Revenge Points gained "
            "through the 4th effect of Tuffle Power by 1.\n"
            "(4)-[Triggered, 1/Encounter]: If you use an Ultimate Signature, "
            "you may spend stacks of Power as if they were Revenge Points on "
            "that Attacking Maneuver. You do not lose any stacks of Power spent "
            "this way until after you complete the Maneuver.",
      ),
    ],
  ),

  // ==================================================================== Unbound ===
  TransformationDef(
    name: "Unbound",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Heran",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Enhanced Save (Impulsive/Corporeal)",
      "Bursting",
      "Draining (LV1)",
      "Power High (LV1)",
      "Difficult (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Full Power Heran",
        description: "You unleash the unrivaled might of a true conqueror, "
            "showing your warrior origins.\n"
            "(1)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(2)-[Passive]: For every 2 stacks of Power you possess, increase "
            "your Tier of Power Extra Dice by 1 Dice Category.\n"
            "(3)-[Passive]: Increase your Combat Rolls by 1/2 (rounded up) of "
            "the Apparel Bonus for the piece of Apparel destroyed through the "
            "Bursting Aspect upon entering this Transformation.\n"
            "(4)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Wound Rolls by 2(T).\n"
            "(5)-[Passive]: While you are below the Bruised Health Threshold, "
            "increase your maximum number of Power stacks by 1.",
      ),
      TransformationTrait(
        name: "Destructive Greed",
        description: "Your greedy desires are so strong that, if you can't "
            "have what you want, you won't let anyone else have it, either.\n"
            "(1)-[Passive]: You do not have to spend Ki Points to apply the "
            "3rd effect of Greed of Hera.\n"
            "(2)-[Passive]: Halve the listed amount of Ki Points for the 4th "
            "effect of Greed of Hera.\n"
            "(3)-[Triggered]: If you use an Attacking Maneuver, you may spend "
            "any number of Greed stacks to increase the Wound Roll of that "
            "Attacking Maneuver by 2(T) for each Greed stack spent.\n"
            "(4)-[Triggered, 1/Round]: If you knock a Character through a "
            "Health Threshold or Defeat them with an Attacking Maneuver, gain "
            "2 stacks of Greed.\n"
            "(5)-[Triggered, 1/Round]: If you use an Attacking Maneuver that "
            "possesses an AoE, you may remove the AoE from that Attacking "
            "Maneuver. If you do, apply an Energy Charge to that Attacking "
            "Maneuver. For every Magnitude that AoE was higher than Standard, "
            "increase the Wound Roll of this Attacking Maneuver by 2(T).",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Galactic Power",
        description: "As a conqueror, your strength is so great that the "
            "entire galaxy trembles in fear of you.\n"
            "(1)-[Permanent]: Unbound loses the Draining and Power High "
            "Aspects.\n"
            "(2)-[Permanent]: Unbound gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Triggered/Power]: Regain M(bT) Ki Points.\n"
            "(4)-[M/Encounter]: As an Instant Maneuver, use the Power Up "
            "Maneuver.",
      ),
      TransformationTrait(
        name: "Unbound and Unchained",
        description: "Only when you unleash your full power do you feel truly "
            "alive.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Dice Category of your Energy Charges by 1 Category.\n"
            "(2)-[1/Round]: If you possess 2+ stacks of Power, you may use the "
            "Energy Charge Maneuver as an Instant Maneuver.\n"
            "(3)-[Triggered/Transform, Triggered/Start of Turn]: Gain a stack "
            "of Greed.",
      ),
    ],
  ),

  // ================================================================== Pure Form ===
  TransformationDef(
    name: "Pure Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Majin",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive/Morale)",
      "Raging",
      "Scaling (LV2)",
      "Power High (LV2)",
      "Rampaging (LV1)",
      "Difficult (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Erratic Majin",
        description: "Your irrational and ever-changing nature makes it "
            "impossible to gauge what you will do at any given time.\n"
            "(1)-[Automatic/Transform]: Lose all stacks of Absorption.\n"
            "(2)-[Automatic]: If you gain a stack of Absorption, leave this "
            "Transformation.\n"
            "(3)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select a Majin Secondary Racial Trait. You gain "
            "access to that Racial Trait while you are in this "
            "Transformation.\n"
            "(4)-[Passive]: Your base Size Category becomes Small, but for the "
            "sake of calculating your Soak Value and for the effects of "
            "Punching Down, your base Size Category is considered to be "
            "Medium.\n"
            "(5)-[Passive]: You may use the Basic Attack Maneuver as an "
            "Instant Maneuver, instead of a Standard Maneuver, but you must "
            "still spend 1 Action to use the Basic Attack Maneuver.\n"
            "(6)-[Triggered/Start of Combat Round]: Reroll your Initiative.\n"
            "(7)-[Automatic/Start of Combat Round, Ruling]: Roll a 1d6 - this "
            "d6 is known as your 'Chaos Die'. Then, until the end of the Combat "
            "Round, gain the following effects depending on the result for "
            "your Chaos Die: 1 [Passive]: Reduce your Defense Value and Soak "
            "Value by 1(bT); 2 [Passive]: Reduce your Strike Rolls and Wound "
            "Rolls by 1(bT); 3 [Passive]: Increase your Surgency by 2(T); 4 "
            "[Passive]: Increase your Attribute Modifiers (FO/MA) by 1(T); 5 "
            "[Passive]: Increase your Attribute Modifiers (AG/TE) by 1(T); 6 "
            "[Passive]: Increase your Combat Rolls and Soak Value by 1(T).",
      ),
      TransformationTrait(
        name: "Unpredictable",
        description: "Your wild and unstable power is chaos incarnate, and "
            "even you don't know what will happen next!\n"
            "(1)-[Triggered, 1/Round]: If you roll a 6 on your Chaos Die, "
            "enter the Superior State until the start of your next turn.\n"
            "(2)-[Triggered, 1/Round]: If you use a Healing Surge, roll your "
            "Chaos Die.\n"
            "(3)-[Triggered, Resource]: If you roll a 6 on your Chaos Die, "
            "gain a stack of Channeled Chaos.\n"
            "(4)-[Triggered]: After seeing the result of your Chaos Die, you "
            "may spend a stack of Channeled Chaos to increase or reduce the "
            "result by 1.\n"
            "(5)-[Triggered/Start of Combat Round]: Spend 2 stacks of "
            "Channeled Chaos. Until the end of this Combat Round, the Ki Point "
            "Cost of your Attacking Maneuvers is reduced to 0.\n"
            "(6)-[Triggered/Start of Combat Round]: Spend 3 stacks of "
            "Channeled Chaos. Until the end of this Combat Round, apply your "
            "Damage Attribute an additional time for all of your Attacking "
            "Maneuvers.\n"
            "(7)-[Triggered/Start of Combat Round]: If you are in the Superior "
            "State, instead of gaining a Counter Action, you may gain an "
            "additional Action.",
      ),
      TransformationTrait(
        name: "Sensation of Purity (Legendary Trait)",
        description: "Unlocked when Pure Form becomes a Legendary Form via its "
            "3rd Mastery. You are most free when you do not make use of your "
            "ability to absorb others, making it easier for you to move "
            "around.\n"
            "(1)-[Passive]: You gain access to the 7th effect of Erratic Majin "
            "and the 3rd and 4th effects of Unpredictable even while not in "
            "the Pure Form Transformation.\n"
            "(2)-[Passive]: While in the Superior State, increase your "
            "Surgency by 2(T).\n"
            "(3)-[Triggered]: If you roll a 6 on your Chaos Die, regain Life "
            "and Ki Points equal to 1/2 of your Surgency.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Directed Chaos",
        description: "You've mastered the ability to manipulate the chaotic "
            "nature of your Transformation.\n"
            "(1)-[Permanent]: Pure Form loses the Rampaging and Power High "
            "Aspects.\n"
            "(2)-[Passive]: While in the Superior State, increase your Wound "
            "Rolls and Soak Value by 1(T).\n"
            "(3)-[Triggered]: If you reroll your Initiative through the 6th "
            "effect of Erratic Majin after rolling your Chaos Die for the 7th "
            "effect of Erratic Majin, you may increase or reduce the Dice "
            "Score of your Initiative roll by x(bT), where x is equal to 1/2 "
            "(rounded up) of your result on that roll of the Chaos Die.\n"
            "(4)-[Triggered, 1/Round]: If you roll a 6 on your Chaos Die, you "
            "may use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Controlled Chaos",
        description: "You capitalize on your chaotic nature, turning it into "
            "your greatest weapon.\n"
            "(1)-[Permanent]: You cannot master Pure Form for the 3rd time "
            "unless your base Tier of Power is 4+.\n"
            "(2)-[Passive]: Ignore the 2nd effect of Erratic Majin.\n"
            "(3)-[Passive]: Ignore the 2nd effect of the Superior State.\n"
            "(4)-[Triggered]: If you use the Transformation Maneuver to enter "
            "an Evolved Stage of Pure Form while in the Pure Form "
            "Transformation, you may ignore the 1st effect of Erratic Majin.\n"
            "(5)-[Triggered/Power, 1/Round]: Roll your Chaos Die.",
      ),
      TransformationTrait(
        name: "Pure Chaos",
        description: "The destructive energy gathering inside you boils to the "
            "surface, making you an extremely deadly foe.\n"
            "(1)-[Permanent]: Pure Form becomes a Legendary Form. Increase the "
            "Stress Test Requirement of this Transformation by 9 and its "
            "Attribute Modifier Bonus (AG/FO/TE/IN/MA) by 1(T).\n"
            "(2)-[Permanent]: Pure Form gains the Perfect Ki Control Aspect and "
            "2 more levels of the Scaling Aspect.\n"
            "(3)-[Passive]: While in the Superior State, apply an Energy Charge "
            "to all of your Attacking Maneuvers.\n"
            "(4)-[Passive]: Double the reductions and increases from the 7th "
            "effect of Erratic Majin.\n"
            "(5)-[Triggered]: If you take Damage from an Attacking Maneuver, "
            "you may spend a stack of Channeled Chaos to halve the amount of "
            "Damage you take.",
      ),
    ],
  ),

  // ===================================================================== Oozaru ===
  TransformationDef(
    name: "Oozaru",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 10,
    prerequisiteText: "While in the Oozaru Alternate Form, you cannot exit "
        "this Transformation unless you lose your tail, you are defeated or "
        "the source of your Transformation (the full moon, typically) is "
        "destroyed. This includes transforming into any other Alternate Form "
        "or Legendary Form Transformations (except the Great Ape and Empowered "
        "Form Lines).",
    aspects: [
      "Enhanced Save (Corporeal)",
      "Raging",
      "Growth (LV3)",
      "Rampaging (LV2)",
      "Innate State (Feral/Raging)",
      "Natural (LV1)",
      "Bulky",
      "Difficult (LV1)",
      "Blutz Wave",
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Furious Beast",
        description: "The beast within overwhelms most Saiyans' minds, taking "
            "over and sending them into a berserk rage.\n"
            "(1)-[Permanent]: You cannot enter this Transformation unless there "
            "is a full moon or False Moon, and you can't gain access to Oozaru "
            "except through the 5th effect of Saiyan Heritage.\n"
            "(2)-[Passive]: Increase your Damage Reduction by 1(T) for each "
            "Health Threshold you are below.\n"
            "(3)-[Passive]: You may apply an unlimited number of Battle Born "
            "stacks to your Wound Rolls.\n"
            "(4)-[Automatic]: If you would gain a stack of Battle Born, you "
            "must apply it to your Wound Rolls.",
      ),
      TransformationTrait(
        name: "Rampaging Assault",
        description: "Your bestial mind takes over, allowing you to deal "
            "massive damage, but denying you fine control over your power.\n"
            "(1)-[Permanent]: You cannot enter this Transformation while using "
            "an Enhancement.\n"
            "(2)-[Passive]: You cannot use an Enhancement in conjunction with "
            "this Transformation.\n"
            "(3)-[Passive]: Reduce the Ki Point Cost of the Beam Profile by "
            "2(T).\n"
            "(4)-[Passive]: Gain access to the Tail Attack Special Maneuver. "
            "You must select the Heavy effect of Tail Attack, and the Tail "
            "Attack Special Maneuver gains the 1/Encounter keyword.\n"
            "(5)-[Triggered, 1/Round]: If you use the Terrain Lift Maneuver, "
            "you may use the Throw Maneuver as an Out-of-Sequence Action. If "
            "you do, you must throw the Feature.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Monkey Mayhem",
        description: "Your conscious mind melds with that of the beast within, "
            "giving you some measure of control over your actions.\n"
            "(1)-[Permanent]: Oozaru loses M levels of the Rampaging Aspect "
            "and gains an Attribute Modifier Bonus (IN) of +1(T).\n"
            "(2)-[Passive]: Ignore the 4th effect of Furious Beast and the 1st "
            "and 2nd effects of Rampaging Assault.",
      ),
      TransformationTrait(
        name: "Monkey Mastery",
        description: "You have gained the ability to contain your inner beast, "
            "allowing you true control over your beast form.\n"
            "(1)-[Permanent]: Oozaru loses the Innate State (Feral/Raging) "
            "Aspect, and gains an Attribute Modifier Bonus (AG) of +1(T).\n"
            "(2)-[Passive]: For calculating the bonus/penalty to your Defense "
            "Value from your Size Category, and for the effects of Punching "
            "Up, you are considered to be of the Large Size Category.\n"
            "(3)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n"
            "(4)-[Triggered/Transform, Triggered/Start of Turn]: Enter the "
            "Raging and/or Feral State(s) until the end of your turn.",
      ),
    ],
  ),

  // ======================================================== Pseudo Super Saiyan ===
  TransformationDef(
    name: "Pseudo Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: "You do not possess Super Saiyan 1 (or any of its "
        "Variants)",
    aspects: [
      "Enhanced Save (Impulsive/Corporeal/Morale)",
      "Innate State (Raging)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Peaked",
      "Limited (LV2)",
      "Fading (LV2)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Spark of a Legend",
        description: "You have not fully awakened the dormant power in your "
            "blood, but it has responded to your desperate need nonetheless.\n"
            "(1)-[Passive]: Increase your Tier of Power Extra Dice by 1 "
            "Category (min. 1d4).\n"
            "(2)-[Passive]: For every 2 stacks of Battle Born you possess, "
            "increase your Wound Rolls by 1(T) (max. 3(T)).\n"
            "(3)-[Triggered/Transform, 1/Encounter]: Use a Ki Surge as an "
            "Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ======================================================= Super Incredible Guy ===
  TransformationDef(
    name: "Super Incredible Guy",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Custom Species",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Difficult (LV1)",
      "Draining (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "The World's Strongest Guy",
        description: "Possessing of the greatest strengths known to your kind, "
            "you are a paragon of your species, allowing you to unlock "
            "abilities few of your kind have.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Super Incredible "
            "Guy, choose a Saving Throw. Super Incredible Guy gains the "
            "Enhanced Save Aspect for that chosen Saving Throw.\n"
            "(2)-[Permanent]: Upon gaining access to this Transformation, "
            "select and apply one of any of the following Aspects to Super "
            "Incredible Guy: Enhanced Save (you may choose any Saving Throw "
            "except the one chosen for the 1st effect of this Trait), Absorbed "
            "Apparel, Bulky, High Speed, Raging, Mindful, or Growth (you can "
            "decide the level).\n"
            "(3)-[Permanent]: Upon gaining access to this Transformation, "
            "create a Signature Technique with a TP Cost of up to 25. This "
            "Signature Technique must have 2 ranks of the Restricted - "
            "Transformation Disadvantage, with Super Incredible Guy selected "
            "for its effect.\n"
            "(4)-[Permanent, Option]: Upon gaining access to Super Incredible "
            "Guy, choose one of the following effects: Diversify [Permanent, "
            "Passive]: select a Custom Species Racial Trait you do not have "
            "access to; while in this Transformation, you gain the chosen "
            "Racial Trait; OR Focus [Permanent, Passive]: select a Custom "
            "Species Racial Trait you possess that does not have access to its "
            "Twinned effects; gain access to its Twinned effects while in this "
            "Transformation.",
      ),
      TransformationTrait(
        name: "A Red-Hot, Raging, Super-Fierce Fight",
        description: "You have become the ultimate warrior, allowing you to "
            "fight harder and longer than any other.\n"
            "(1)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(2)-[Passive]: While in the Superior State, increase your Combat "
            "Rolls by 1(T).\n"
            "(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver, or "
            "are targeted by an Attacking Maneuver, you may enter the Superior "
            "State for the duration of that Attacking Maneuver.\n"
            "(4)-[1/Encounter]: As an Instant Maneuver, use a Surge of your "
            "choice. This Surge is considered to be a use of Legend Realized "
            "for the 5th effect of this Trait.\n"
            "(5)-[Triggered, 1/Encounter]: If you use Legend Realized, you may "
            "enter the Superior State until the start of your next turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Super Warriors Can't Rest",
        description: "Your undeniable strength has surpassed all limits, "
            "allowing you to unlock all the hidden powers of your race.\n"
            "(1)-[Permanent]: Super Incredible Guy loses the Draining "
            "Aspect.\n"
            "(2)-[Permanent]: Super Incredible Guy gains the Realization "
            "Aspect and M levels of the Scaling Aspect.\n"
            "(3)-[Passive]: Ignore the 2nd effect of the Superior State.\n"
            "(4)-[Passive]: The 5th effect of A Red-Hot, Raging, Super-Fierce "
            "Fight applies until the end of your next turn instead of the "
            "start.\n"
            "(5)-[Permanent, Option]: Upon gaining this Mastery Trait, select "
            "and gain access to one of the following effects while in this "
            "Transformation: Adjust [Permanent, Passive]: select an additional "
            "Aspect through the 2nd effect of World's Strongest Guy to apply "
            "to this Transformation; OR Strengthen [Permanent, Passive]: "
            "select an Attribute (if you select either Force or Magic, then "
            "both are selected); increase the Attribute Modifier Bonus of "
            "Super Incredible Guy for that Attribute by 1(T).",
        // (4) Adjust (extra Aspect — text) OR Strengthen (a nested Attribute
        // pick granting +1(T) AMB; Force/Magic are coupled). Gated live by
        // Mastery (this is a Mastery Trait), so the AMB applies once mastered.
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Effect',
            options: [
              TraitOption(
                name: 'Adjust',
                description: '[Permanent, Passive]: Select an additional Aspect '
                    "through the 2nd effect of World's Strongest Guy to apply "
                    'to this Transformation.',
              ),
              TraitOption(
                name: 'Strengthen',
                description: '[Permanent, Passive]: Select an Attribute (Force '
                    'or Magic selects both); increase this Transformation\'s '
                    'AMB for that Attribute by 1(T).',
                optionGroups: [
                  RaceTraitOptionGroup(
                    label: 'Strengthen Attribute',
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
                      TraitOption(
                        name: 'Insight',
                        description: '+1(T) Attribute Modifier Bonus (IN).',
                        ambPerTierBonus: {DbuAttribute.insight: 1},
                      ),
                      TraitOption(
                        name: 'Force / Magic',
                        description: '+1(T) Attribute Modifier Bonus to BOTH '
                            'Force and Magic (selecting either selects both).',
                        ambPerTierBonus: {
                          DbuAttribute.force: 1,
                          DbuAttribute.magic: 1,
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Super Battle for the Whole World",
        description: "You have reached the supreme peak of power for your "
            "species, becoming an absolute paragon of your race.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this Mastery "
            "Trait, choose one of the following Aspects to apply to Super "
            "Incredible Guy: Armored or Perfect Ki Control.\n"
            "(2)-[Permanent, Passive]: Select a Custom Species Racial Trait "
            "you possess that does not have access to its Twinned effects. "
            "Gain access to its Twinned effects while in this Transformation.\n"
            "(3)-[Passive]: The 3rd effect of A Red-Hot, Raging, Super-Fierce "
            "Fight loses the [1/Round] Keyword and gains the [2/Round] "
            "Keyword.",
      ),
    ],
  ),

  // ========================================================== Snack Empowerment ===
  TransformationDef(
    name: "Snack Empowerment",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Snack Motivated Racial Trait",
    aspects: [
      "Enhanced Save (Impulsive/Corporeal/Morale)",
      "Exhausting",
      "Difficult (LV1)",
      "Draining (LV2)",
      "Limited (LV3)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Snack-Fueled Warrior",
        description: "Until you get some food on your stomach, you can't truly "
            "begin to fight.\n"
            "(1)-[Permanent]: You can only enter this Transformation if you "
            "have used a Snack Basic Item during this Combat Round.\n"
            "(2)-[Constant]: If you use a Snack Basic Item, you may use the "
            "Transformation Maneuver as an Out-of-Sequence Maneuver to enter "
            "this Transformation.\n"
            "(3)-[Passive]: Treat your Legend Realized gained from this "
            "Transformation as if it was Life and Ki Points regained through "
            "the Snack Basic Item.\n"
            "(4)-[Triggered]: If you trigger the 2nd effect of Snack-Fueled "
            "Warrior and the 2nd effect of Snack Fiend in response to using "
            "the same Snack Basic Item, instead of leaving the Superior State "
            "at the end of your turn, you may remain in the Superior State "
            "until you leave this Transformation.\n"
            "(5)-[Triggered, 1/Round]: If you use a Snack Basic Item, reset the "
            "count for the number of Combat Rounds you have been in this "
            "Transformation for the sake of the Limited Aspect.",
      ),
      TransformationTrait(
        name: "Power of Snacks",
        description: "Sustained by the constant consumption of food, you are a "
            "force of nature in battle.\n"
            "(1)-[Passive]: While you have 2+ stacks of Power, increase your "
            "Combat Rolls, Soak Value, and Surgency by 1(T), 1(T), and 2(T) "
            "respectively.\n"
            "(2)-[Passive]: Apply 1/2 of your Surgency to the amount of Life "
            "and Ki Points regained through a Snack Basic Item.\n"
            "(3)-[Triggered, 1/Round]: If you are hit by an Attacking "
            "Maneuver, and have used a Snack Basic Item during this Combat "
            "Round, you may reduce the Damage Category of that Attacking "
            "Maneuver by 1 Category.\n"
            "(4)-[Triggered, 1/Round]: If you use a Signature Technique, and "
            "have used a Snack Basic Item during this Combat Round, you may "
            "apply an Energy Charge to that Attacking Maneuver.\n"
            "(5)-[Triggered, 1/Encounter]: If you use a Healing Surge, you may "
            "instead regain Life and Ki Points as if you consumed a Snack "
            "Basic Item. This is also considered to be using the Snack Basic "
            "Item for all of your effects.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Hungry for More",
        description: "Your inexhaustible appetite is matched only by your "
            "incredible strength during those rare, short-lived moments when "
            "you're truly sated.\n"
            "(1)-[Permanent]: For this Transformation, the Limited Aspect "
            "gains M Levels, and the Draining Aspect loses M levels.\n"
            "(2)-[Permanent]: Snack Empowerment gains M levels of the Scaling "
            "Aspect.\n"
            "(3)-[Passive]: During a Combat Round in which you have consumed a "
            "Snack Basic Item, increase the Dice Category of your Tier of "
            "Power Extra Dice and Greater Dice by M Categories.\n"
            "(4)-[Triggered, 1/Round]: If you use a Snack Basic Item, you may "
            "use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Managed Hunger",
        description: "You've learned to live with your hunger, able to draw "
            "out more of your power without eating quite as much.\n"
            "(1)-[Permanent]: This Transformation loses the Exhausting "
            "Aspect.\n"
            "(2)-[Passive]: Use your full Surgency, rather than half, for the "
            "2nd effect of Power of Snacks.\n"
            "(3)-[Passive]: The 5th effect of Power of Snacks loses the "
            "[1/Encounter] Keyword and gains the [2/Encounter] Keyword.",
      ),
    ],
  ),

  // ================================================================= Power Boost ===
  // The base Any-race Power Boost Form; every racial "X Power" Form above is a
  // Variant of this.
  TransformationDef(
    name: "Power Boost",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Enhanced Save (Impulsive/Morale)",
      "Draining (LV*)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Improved Power",
        description: "Fine control of your ki allows you to move in "
            "unpredictable ways or increase your strength temporarily.\n"
            "(1)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(2)-[Passive]: For each stack of Power you possess, increase your "
            "Wound Rolls by 1(T).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Strike Rolls, Dodge Rolls and Soak Value by 1(T).\n"
            "(4)-[Passive]: While you possess 3+ stacks of Power, increase "
            "your Might and Damage Reduction by 1(T).\n"
            "(5)-[Passive]: For each stack of Power you possess, increase the "
            "Dice Category for your Tier of Power Extra Dice (max. +2 "
            "Categories).\n"
            "(6)-[Triggered/Power, 1/Encounter]: Instead of gaining a stack of "
            "Power through this use of the Power Up Maneuver, maximize your "
            "Power stacks.",
      ),
      TransformationTrait(
        name: "Overflowing Power",
        description: "Your extreme and overwhelming strength cannot be "
            "contained and exude powerful shock waves from your body.\n"
            "(1)-[Passive]: Your level of the Draining Aspect is equal to your "
            "number of Power stacks.\n"
            "(2)-[Triggered]: If your Opponent initiates a Clash against you "
            "that uses your Saving Throws, you may spend up to 2 stacks of "
            "Power to increase your Dice Score for that Clash by 1(T) for each "
            "stack spent.\n"
            "(3)-[Triggered/Power, 1/Round]: Make a Might Clash against all "
            "Opponents within a Sphere AoE. If you win, they lose Life Points "
            "equal to 1/2 of your Might. Increase the Magnitude of this AoE by "
            "1 Magnitude for every 2 stacks of Power you possess.\n"
            "(4)-[Triggered/Start of Turn, 1/Encounter]: If you have your "
            "maximum number of Power stacks, you may enter the Superior State "
            "or Surging State until the end of your turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Power",
        description: "You have incorporated this increased power into "
            "yourself, taking away the downsides.\n"
            "(1)-[Permanent]: This Transformation loses the Exhausting "
            "Aspect.\n"
            "(2)-[Permanent]: Power Boost gains the Realization Aspect and M "
            "levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Triggered/Power]: Regain 2(bT) Ki Points.\n"
            "(4)-[Triggered, M/Encounter]: If you would lose any Power stacks, "
            "except through the 2nd effect of Overflowing Power, you may "
            "choose to delay losing those Power stacks for 1 Combat Round.",
      ),
      TransformationTrait(
        name: "High Power",
        description: "You have incorporated much more power into yourself, "
            "allowing you to handle this Transformation's power increase with "
            "greater ease.\n"
            "(1)-[Passive]: Halve the amount of Ki Points you lose from this "
            "Transformation's Draining Aspect.\n"
            "(2)-[1/Round]: Use the Power Up Maneuver as an Instant Maneuver.",
      ),
      TransformationTrait(
        name: "Maximum Power",
        description: "You have incorporated as much power into your body as "
            "you can, allowing you to maintain this power increase with "
            "relative simplicity.\n"
            "(1)-[Passive]: Increase your maximum number of Power Stacks by "
            "1.\n"
            "(2)-[Triggered/Transform]: Use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ============================================================= Spiritual Power ===
  TransformationDef(
    name: "Spiritual Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Spirit Control Awakening",
    aspects: [
      "Variant (Power Boost)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Draining (LV1)",
      "Glowing",
      "Difficult (LV2)",
      "Light Dependent",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Balanced Power (Overflowing Power)",
        description: "Your increased energy flows freely like water in a pond, "
            "allowing you to share it with others, if you wish.\n"
            "(1)-[Ruling]: All Squares within a Large Sphere AoE (centered on "
            "you) are in the 'Transference Zone'. Any bonuses granted by "
            "effects that reference the Transference Zone do not stack from "
            "multiple Characters, but instead take the largest bonus from "
            "among the Characters who are currently in the Spiritual Power "
            "Transformation.\n"
            "(2)-[Passive]: All Allies within the Transference Zone may (with "
            "your permission) spend your Ki Points to pay the Ki Point Cost of "
            "Attacking Maneuvers or Unique Abilities instead of their own - "
            "they still reduce their Capacity as usual (your Capacity is not "
            "reduced).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, increase the "
            "Combat Rolls of all Allies within the Transference Zone by 1(T). "
            "This bonus does not stack.\n"
            "(4)-[Triggered]: When making an Attacking Maneuver or using a "
            "Unique Ability, you may spend any number of stacks of Power. For "
            "each stack of Power spent, it counts as having spent 5(bT) Ki "
            "Points towards the Ki Point Cost of that Maneuver.\n"
            "(5)-[Triggered/Power, 1/Round]: Regain Ki Points equal to 1/2 of "
            "your Surgency.\n"
            "(6)-[Triggered, 1/Encounter]: If you transfer the maximum amount "
            "of Ki Points to an Ally through the Empower Maneuver for the "
            "Action Cost, either you or that Ally may use the Power Up Maneuver "
            "as an Out-of-Sequence Maneuver (you decide).",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Initial Spiritual Power",
        description: "You have learned to mold your newfound power to fit the "
            "vessel that wields it- your body.\n"
            "(1)-[Permanent]: Spiritual Power loses the Exhausting and "
            "Draining Aspects.\n"
            "(2)-[Permanent]: Spiritual Power gains the Realization Aspect "
            "and M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Soak Value and Surgency by 1(T).\n"
            "(4)-[Passive]: Increase the Magnitude for the Transference Zone's "
            "AoE by 1.\n"
            "(5)-[1/Encounter]: You may trigger the 7th effect of Spiritual "
            "Apprentice without counting towards its [1/Encounter] limit.",
      ),
      TransformationTrait(
        name: "High Spiritual Power",
        description: "You have learned to recognize that there is also power "
            "in knowing when to let go of excess power.\n"
            "(1)-[Triggered]: If you spend a stack(s) of Power through the 4th "
            "effect of Balanced Power, regain 3(bT) Life Points for each stack "
            "of Power spent.\n"
            "(2)-[Passive]: The [1/Encounter] Keyword becomes [M/Encounter] "
            "for the 6th effect of Balanced Power.",
      ),
      TransformationTrait(
        name: "Maximum Spiritual Power",
        description: "You have mastered the art of manipulating your strength "
            "the same way you do your energy.\n"
            "(1)-[Permanent]: Spiritual Power gains 1 level of the Natural "
            "Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "1.\n"
            "(3)-[Passive]: Increase the Magnitude for the Transference Zone's "
            "AoE by 1.\n"
            "(4)-[Passive]: Double the amount of Ki Points regained through "
            "the 5th effect of Balanced Power.",
      ),
    ],
  ),

  // ================================================================ Mode Change ===
  TransformationDef(
    name: "Mode Change",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Battle Uniform",
      "Prelude",
      "Difficult (LV1)",
      "Long Transformation (LV1)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.armor,
      craftsmanshipGrade: 4,
      qualityNames: ['Durable'],
    ),
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
        name: "Transformation!",
        description: "You are capable of changing your gear, your body, or "
            "some aspect of your abilities while in this Transformation, "
            "allowing you to switch between different sets of abilities.\n"
            "(1)-[Passive, Ruling]: You have access to the Speed, Battle, "
            "Focus, and Hero 'Mode's. You can only be in one Mode at a time, "
            "and upon leaving any Transformation that grants access to a Mode, "
            "you leave that Mode. If you enter another Mode, leave the Mode you "
            "are currently in.\n"
            "(2)-[Passive, Ruling]: Each Mode has a 'Connected Attribute', "
            "which is listed in brackets after the name of that Mode. While "
            "you are in a Mode, the Connected Attribute and the Attribute you "
            "have the highest Attribute Score in have their Attribute "
            "Modifiers (before applying any Attribute Modifier Bonuses from "
            "Transformations) swapped - if there's a tie, you may choose which "
            "of the highest Attribute Scores is swapped with your Connected "
            "Attribute.\n"
            "(3)-[Triggered, 1/Round]: If you use the Power Up Maneuver or the "
            "Hype Maneuver, you may enter a Mode that you have access to.\n"
            "(4)-[Automatic/Transform]: Enter the Hero Mode.\n"
            "Select the Mode you are currently in below (its AMB applies).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Active Mode',
            options: [
              TraitOption(
                name: 'Speed Mode (Agility)',
                description: 'Adapted for high mobility and agility. '
                    '(1)-[Passive]: While in this Mode, increase the AMB (AG) '
                    'of Mode Change by 1(T). (2)-[Passive]: While in this '
                    'Mode, Mode Change gains the Enhanced Save (Impulsive) and '
                    'the High Speed Aspects. (3)-[1/Round]: During your turn, '
                    'you may use the Movement Maneuver as an Instant Maneuver. '
                    '(4)-[Triggered, 1/Round]: If you end your movement on a '
                    'Square adjacent to an Opponent, you may use the Basic '
                    'Attack Maneuver as an Out-of-Sequence Maneuver (target an '
                    'adjacent Opponent).',
                ambPerTierBonus: {DbuAttribute.agility: 1},
              ),
              TraitOption(
                name: 'Battle Mode (Tenacity)',
                description: 'Optimized for combat. (1)-[Passive]: While in '
                    'this Mode, increase the AMB (FO/TE/MA) of Mode Change by '
                    '1(T). (2)-[Passive]: While in this Mode, Mode Change '
                    'gains the Enhanced Save (Corporeal) and the Armored '
                    'Aspects. (3)-[1/Round]: You may use the Defend Maneuver '
                    'without spending a Counter Action (use the Direct Hit or '
                    'Guard option). (4)-[Triggered, 1/Round]: If you are hit '
                    'by an Attacking Maneuver and the Damage you take is below '
                    'the sum of your Soak Value and Damage Reduction, you may '
                    'use the Basic Attack Maneuver as an Out-of-Sequence '
                    'Maneuver (target the attacking Character).',
                ambPerTierBonus: {
                  DbuAttribute.force: 1,
                  DbuAttribute.tenacity: 1,
                  DbuAttribute.magic: 1,
                },
              ),
              TraitOption(
                name: 'Focus Mode (Insight)',
                description: 'Modified for accuracy and control. '
                    '(1)-[Passive]: While in this Mode, increase the AMB (IN) '
                    'of Mode Change by 1(T). (2)-[Passive]: While in this '
                    'Mode, Mode Change gains the Enhanced Save (Cognitive) and '
                    'the Perfect Ki Control Aspects. (3)-[Passive]: Ignore the '
                    'penalty from Long Range. (4)-[Triggered, 1/Round]: If you '
                    'apply the Called Shot Modifier Maneuver to an Attacking '
                    'Maneuver, do not pay the Action Cost.',
                ambPerTierBonus: {DbuAttribute.insight: 1},
              ),
              TraitOption(
                name: 'Hero Mode (Personality)',
                description: 'Carrying the flame of justice in your heart. '
                    '(1)-[Passive]: While in this Mode, increase the AMB (PE) '
                    'of Mode Change by 1(T). (2)-[Passive]: While in this '
                    'Mode, Mode Change gains the Enhanced Save (Morale) and '
                    'the Natural (LV1) Aspects. (3)-[1/Round]: During your '
                    'turn, you may use the Hype Maneuver as an Instant '
                    'Maneuver (even without access to it). (4)-[Triggered, '
                    '1/Round]: If you use the Signature Technique Maneuver '
                    'while Hyped, you may apply an Energy Charge to that '
                    'Signature Technique.',
                ambPerTierBonus: {DbuAttribute.personality: 1},
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "The Final Mission",
        description: "As a hero, your goal is to shine light on the darkness, "
            "eradicating evil wherever it rears its ugly head.\n"
            "(1)-[Passive]: While you are below the Injured Health Threshold, "
            "increase all of your Combat Rolls and Soak Value by 1(T).\n"
            "(2)-[Triggered, 1/Round]: When using an Attacking Maneuver, you "
            "may change the Damage Attribute of that Attacking Maneuver to the "
            "Connected Attribute for the Mode you are currently in.\n"
            "(3)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique while below the Injured Health Threshold and change the "
            "Damage Attribute of that Attacking Maneuver through the 2nd effect "
            "of The Final Mission, you may apply the Damage Attribute an "
            "additional time to that Attacking Maneuver.\n"
            "Battle Uniform — Category: Armor; Craftsmanship Grade: 4; "
            "Accessories: Helmet.\n"
            "Durable (Quality Slots 1): Increase the maximum Break Value for "
            "this piece of Apparel by 3.\n"
            "Modular Apparel (Quality Slots 1): Depending on your current "
            "Mode, apply one of: Speed Mode — increase your Dodge Rolls by "
            "1(T); Battle Mode — increase your Damage Reduction and Wound "
            "Rolls by 1(T); Focus Mode — increase your Strike Rolls by 1(T); "
            "Hero Mode — increase your Combat Rolls by 1/4 of your Personality "
            "Modifier.\n"
            "Combat Ready (Quality Slots 1): Increase your Strike and Dodge "
            "Rolls by 1/2 (rounded up) of your Apparel Bonus.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Preserving the Peace",
        description: "Hold on to peace and preserve it in the world.\n"
            "(1)-[Permanent]: This Transformation loses the Long "
            "Transformation Aspect.\n"
            "(2)-[Permanent]: Mode Change gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Passive]: The 3rd effect of Transformation! gains the "
            "[2/Round] Keyword instead of the [1/Round] Keyword.\n"
            "(4)-[1/Round]: If you are facing an Opponent who has a higher "
            "base Tier of Power than you, you may use the Power Up Maneuver as "
            "an Instant Maneuver.",
      ),
      TransformationTrait(
        name: "Ignited Soul",
        description: "Justice is your compass.\n"
            "(1)-[Permanent]: The Craftsmanship Grade for this "
            "Transformation's Battle Uniform becomes 5 and it gains the "
            "Resolute Belief Apparel Quality.\n"
            "(2)-[Triggered, 1/Round]: If you enter a Mode during your turn, "
            "increase your Combat Rolls by 1(T) until the end of your turn.",
      ),
    ],
  ),

  // ================================================================= Dark Demon ===
  TransformationDef(
    name: "Dark Demon",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Demon Race or Demon Clansman Factor, Energy Poacher "
        "Awakening",
    aspects: [
      "Enhanced Save (Cognitive/Morale)",
      "Scaling (LV2)",
      "Realization",
      "Draining (LV1)",
      "Difficult (LV1)",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Dark Energy",
        description: "You can gather and manipulate the corrupting and "
            "destructive energy of darkness and evil.\n"
            "(1)-[Triggered, Resource]: If you win a Clash for the effects of "
            "the Energy Drain Unique Ability, gain a stack of Darkness (max. "
            "2).\n"
            "(2)-[Triggered, 2/Round]: If you gain a stack of Darkness during "
            "your turn, increase your Combat Rolls by 1(T) until the start of "
            "your next turn.\n"
            "(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you "
            "may spend a stack of Darkness to apply the Condition Advantage to "
            "that Attacking Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you "
            "may spend a stack of Darkness to apply a Large AoE of your choice "
            "to that Attacking Maneuver.\n"
            "(5)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you "
            "may spend any number of Darkness stacks to apply Energy Charges to "
            "that Attacking Maneuver equal to the amount of Darkness stacks "
            "spent.\n"
            "(6)-[Triggered]: If you would spend Ki Points through an effect, "
            "you can spend a stack of Darkness as if it was 6(bT) Ki Points. If "
            "this amount of Ki Points exceeds the Ki Point Cost of that effect, "
            "gain Ki Points equal to the excess.\n"
            "(7)-[Triggered]: If you win the Clash for the effects of the "
            "Energy Drain Unique Ability against an Opponent with a Combat "
            "Condition, do not reduce the Dice Score of your Magical Wound Roll "
            "by their Might through the effects of Energy Drain.",
      ),
      TransformationTrait(
        name: "Consuming Darkness",
        description: "Your demonic power lets you harness the darkness in the "
            "hearts of men; sometimes yours, and sometimes your opponents, "
            "allowing you to grow stronger through your dark magic "
            "specialty.\n"
            "(1)-[Passive]: You may use the Energy Drain Unique Ability an "
            "additional time per Combat Round.\n"
            "(2)-[Passive]: Increase your Strike Rolls against Opponents "
            "suffering from a Combat Condition by 1(T).\n"
            "(3)-[Passive]: If you have gained 2+ stacks of Darkness during "
            "this Combat Round, increase your Might by 1(T).\n"
            "(4)-[Triggered, 1/Round]: If you use a Signature Technique, "
            "increase the Damage Category of that Attacking Maneuver by 1 "
            "Category for the Damage calculation of all the targets of that "
            "Attacking Maneuver that are suffering from a Combat Condition.\n"
            "(5)-[Triggered, 1/Encounter]: If you use a Healing Surge through "
            "the 6th effect of Energy Siphon, you may regain Ki Points equal "
            "to the amount of Life Points regained from that Healing Surge.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Darkest Demon",
        description: "You've immersed yourself into the heart of the darkness, "
            "granting you the ever-growing strength of the deepest forms of "
            "vile corruption.\n"
            "(1)-[Permanent]: Dark Demon loses the Draining and Exhausting "
            "Aspects.\n"
            "(2)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Surgency by 2(T).\n"
            "(3)-[Passive]: Increase your maximum number of Darkness stacks by "
            "M.",
      ),
      TransformationTrait(
        name: "Deepest Dark Energy",
        description: "The dark energies at your disposal can be weaved into "
            "your offensive techniques, allowing you to manipulate your foes "
            "in ways they can't foresee.\n"
            "(1)-[Passive]: Increase your Cognitive Save by 1(T) for Clashes "
            "made against Characters suffering from a Combat Condition. If you "
            "make this Clash against multiple Characters, this only applies if "
            "all of those Characters are suffering from a Combat Condition.\n"
            "(2)-[Triggered]: If you spend a stack of Darkness through the 3rd "
            "or 4th effect of Dark Energy, you may increase the Wound Roll of "
            "that Attacking Maneuver by 3(T).\n"
            "(3)-[Triggered/Power, 1/Round]: Gain a stack of Darkness.",
      ),
    ],
  ),

  // ==================================== Super Saiyan Variants (Stage 1 of the
  // Super Saiyan line, one main S-Cells Variant trait + one Mastery Trait each).
  // ========================================================= Xeno Super Saiyan ===
  TransformationDef(
    name: "Xeno Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Class Up Awakening",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal/Morale)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
      "Power High (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Super Saiyan Class (S-Cells)",
        description: "Your gleaming golden grandeur strengthens your "
            "specializations as you achieve new heights of power.\n"
            "(1)-[Passive]: For every Awakening you possess with 'Class Up' in "
            "the name, increase your Max Capacity by 3(bT).\n"
            "(2)-[Passive]: While you have 4+ stacks of Battle Born, increase "
            "the Tier of Power Extra Dice for your Combat Rolls by 1 Dice "
            "Category and increase your Surgency by 2(T).\n"
            "(3)-[1/Encounter]: If you have 6+ stacks of Battle Born, use your "
            "Choice effect for the 3rd effect of Class Selection. This does "
            "not count towards that effect's [1/Encounter] Keyword.\n"
            "(4)-[Choice]: Depending on your choice for the Option effect of "
            "Class Selection, gain the following effects: Hero [Passive]: While "
            "you possess 2+ stacks of Power, increase your Combat Rolls and "
            "Soak Value by 1(T); Elite [Triggered, 1/Round]: If you use a Ki "
            "Surge, roll your Tier of Power Extra Dice and then increase the "
            "Dice Score by 1/2 of your Surgency; regain Life Points equal to "
            "the Dice Score of that roll; Berserker [Passive]: While you have "
            "2+ stacks of Battle Born applied to your Wound Rolls, increase "
            "your Tier of Power Extra Dice for your Wound Rolls by 1 Dice "
            "Category and your Wound Rolls by 2(T).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Golden Class",
      description: "The golden flames of power that surround you now answer to "
          "your every whim.\n"
          "(1)-[Permanent]: Xeno Super Saiyan loses the Draining and Power "
          "High Aspects.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(4)-[Choice]: Depending on your choice for the Option effect of "
          "Class Selection, gain the following effects: Hero [Passive]: While "
          "you possess 2+ stacks of Power, increase your Tier of Power Extra "
          "Dice by 1 Category; Elite [Passive]: You may apply your full "
          "Surgency for the Choice effect from the 4th effect of Super Saiyan "
          "Class; Berserker [Passive]: Increase your Tier of Power Extra Dice "
          "by 1 Category for your Wound Rolls and increase your Soak Value by "
          "1(bT).",
    ),
  ),

  // ===================================================== Ancestral Super Saiyan ===
  TransformationDef(
    name: "Ancestral Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Ancient Saiyan Factor",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Origin of the Warrior Race (S-Cells)",
        description: "Your tenacious nature and primal need to survive against "
            "all odds transform you, under the golden glow of your blazing "
            "aura, into a nearly-immortal warrior.\n"
            "(1)-[Passive]: While you have 4+ stacks of Battle Born, increase "
            "the Tier of Power Extra Dice for your Combat Rolls by 1 Category "
            "and increase your Surgency by 1(T).\n"
            "(2)-[Passive]: While you are in the Undying State, increase your "
            "Soak Value and Wound Rolls by 2(T). Additionally, this "
            "Transformation gains the Armored Aspect.\n"
            "(3)-[1/Round]: As an Instant Maneuver, you may spend a stack of "
            "Battle Born to use the Power Up Maneuver.\n"
            "(4)-[Triggered/Threshold]: If you succeed at the Steadfast Check, "
            "enter the Undying State until the end of your next turn.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Enter the Undying State until "
            "the start of your next turn.\n"
            "(6)-[Triggered, 1/Round, 3/Encounter]: If you succeed at a "
            "Steadfast Check, gain a stack of Battle Born.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Ancient Secrets of the Super Saiyan",
      description: "By recalling the secrets of the ancients and dedicated "
          "training, you have eliminated the downsides of this "
          "Transformation.\n"
          "(1)-[Permanent]: Ancestral Super Saiyan loses the Draining "
          "Aspect.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Passive]: Ignore the 3rd effect of the Undying State.\n"
          "(4)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(5)-[Triggered, 1/Encounter]: While your Life Points exceed 0 while "
          "in the Undying State, if you receive Damage that exceeds your Life "
          "Points, you may reduce that Damage so that you are left with 1 Life "
          "Point. If you do, you may use the Basic Attack Maneuver as an "
          "Out-of-Sequence Maneuver.",
    ),
  ),

  // =========================================================== Bio Super Saiyan ===
  TransformationDef(
    name: "Bio Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Saiyan Genes Factor Trait",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
      "Power High (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Mixed S-Cells (S-Cells)",
        description: "T\n"
            "(1)-[Passive]: For each stack of Battle Creation, increase your "
            "Surgency by 1(T).\n"
            "(2)-[Passive]: While you possess 2+ stacks of Battle Creation, "
            "increase your Tier of Power Extra Dice by 1 Dice Category and "
            "increase your Combat Rolls by 1(T).\n"
            "(3)-[1/Round]: If you have 2+ stacks of Battle Creation, you may "
            "spend 3 Adaptation Points to use the Power Up Maneuver as an "
            "Instant Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you spend 2+ Adaptation Points on "
            "the Strike or Wound Roll of an Attacking Maneuver, increase the "
            "Tier of Power Extra Dice applied to the Wound Roll of that "
            "Attacking Maneuver by 1 Dice Category.\n"
            "(5)-[Triggered, 1/Encounter]: If you succeed at the Steadfast "
            "Check for the 4th effect of Saiyan Genes, enter the Superior "
            "State until the end of your next turn.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mastered Saiyan Cells",
      description: "Y\n"
          "(1)-[Permanent]: Bio Super Saiyan loses both the Draining and "
          "Power High Aspects.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(4)-[Triggered/Superior, 1/Encounter]: Maximize your Adaptation "
          "Points.",
    ),
  ),

  // ===================================================== Descended Super Saiyan ===
  TransformationDef(
    name: "Descended Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Earthling",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Saiyan Ancestry Factor",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Awoken Saiya Power (S-Cells)",
        description: "The power of your ancestor's blood awakens in you, "
            "granting you the increased might of a Super Saiyan.\n"
            "(1)-[Passive]: For every stack of Warrior Blood, increase your "
            "Surgency by 1(T).\n"
            "(2)-[Passive]: While you possess 2+ stacks of Warrior Blood, "
            "increase your Tier of Power Extra Dice by 1 Dice Category and "
            "increase your Damage Reduction by 1(T).\n"
            "(3)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Combat Rolls and Soak Value by 1(T).\n"
            "(4)-[Constant]: If you succeed at the Steadfast Check for the "
            "second effect of Dormant Saiya Power, use a Healing Surge as an "
            "Out-of-Sequence Maneuver. Then, if you are not already in this "
            "Transformation, you may use the Transformation Maneuver as an "
            "Out-of-Sequence Maneuver to enter this Transformation.\n"
            "(5)-[Triggered, 1/Round]: If you use a Signature Technique and "
            "apply an Energy Charge to that Signature Technique through the "
            "second effect of Quick to Master, increase its Wound Roll by 1(T) "
            "for every stack of Warrior Blood you possess.\n"
            "(6)-[Triggered, 1/Encounter]: Upon succeeding at a Steadfast "
            "Check, you may enter the Surging State until the end of your "
            "turn.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "One with Saiya Power",
      description: "You have made the dormant power in your blood your own, "
          "awakening deeper levels of hidden strength.\n"
          "(1)-[Permanent]: Descended Super Saiyan loses the Draining and "
          "Exhausting Aspects.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Passive]: Ignore the 2nd effect of the Surging State if you "
          "enter it through the 6th effect of Awoken Saiya Power.\n"
          "(4)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(5)-[Triggered/Threshold]: Use a Ki Surge as an Out-of-Sequence "
          "Maneuver. If you do, regain Life Points equal to 1/2 of your "
          "Surgency.",
    ),
  ),

  // ====================================================== Superior Super Saiyan ===
  TransformationDef(
    name: "Superior Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "You possess 2+ stacks of the Zenkai Awakening",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
      "Power High (LV3)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Crazed Battle Lust (S-Cells)",
        description: "Your warrior instincts turn up to 11, driving you nearly "
            "berserk with battle lust.\n"
            "(1)-[Passive]: While you have 4+ stacks of Battle Born, increase "
            "the Tier of Power Extra Dice for your Combat Rolls by 1 Category "
            "and increase your Damage Reduction by 1(T).\n"
            "(2)-[Passive]: For every 3 stacks of Battle Born you possess, "
            "increase the Dice Score of your Steadfast Checks by 1 (max. "
            "+2).\n"
            "(3)-[Passive]: For every 3 stacks of Battle Born you possess, "
            "increase your Surgency by 1(T) (max. 2(T)).\n"
            "(4)-[Triggered]: If you are hit by an Attacking Maneuver, regain "
            "Ki Points equal to 1/4 (rounded up) of your Surgency.\n"
            "(5)-[Triggered, 1/Round]: If you use a Signature Technique while "
            "in the Superior State, increase its Wound Roll by 1/2 of your "
            "Surgency.\n"
            "(6)-[Triggered/Threshold]: If you succeed at the Steadfast Check, "
            "regain Life Points equal to your Surgency and then enter the "
            "Superior State until the end of your turn.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Realized Superiority",
      description: "Through constant training and mastery over the self, "
          "you've eliminated the weaknesses inherent to the Super Saiyan "
          "form.\n"
          "(1)-[Permanent]: Superior Super Saiyan loses the Draining and Power "
          "High Aspects.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(4)-[Triggered/Power, 1/Encounter]: Reduce your Life Points until "
          "they are 1 below your next Health Threshold to regain Ki Points "
          "equal to the reduction (max. 7(bT)). You do not suffer from Reduced "
          "Momentum due to this effect.",
    ),
  ),

  // =========================================================== Super Neko Majin ===
  TransformationDef(
    name: "Super Neko Majin",
    type: TransformationType.form,
    formType: FormType.alternate,
    // Site writes "Neko" here — normalized to the catalogue race "Neko Majin".
    racialRequirement: "Neko Majin",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "You have been in a Combat Encounter in which a character "
        "has entered the Super Saiyan 1 Transformation (or any of its "
        "Variants)",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
      "Power High (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "I'm Shining!! (S-Cells)",
        description: "You've copied the golden power of the Super Saiyan, and "
            "the flame of power surrounding you shines with that golden "
            "gleam.\n"
            "(1)-[Triggered/Transform, Triggered/Start of Combat Round, "
            "Resource]: Gain a stack of Dama Charge (max. S+1).\n"
            "(2)-[Passive]: For each stack of Power you possess, increase the "
            "Wound Rolls of your Copied Techniques by 1(T).\n"
            "(3)-[Passive]: While you have 2+ stacks of Power, increase the "
            "Tier of Power Extra Dice by 1 Category and increase your Soak "
            "Value by 1(T).\n"
            "(4)-[Passive]: When you trigger the 6th or 7th effect of Neko "
            "Majin-Dama, you may spend 2 Dama Charges (for the 6th effect) or "
            "a Dama Charge (for the 7th effect) to apply that effect without "
            "counting towards its [x/Encounter] Keyword.\n"
            "(5)-[1/Round]: You may spend a stack of Dama Charge to use the "
            "Power Up Maneuver as an Instant Maneuver.\n"
            "(6)-[1/Round]: You may spend a stack of Dama Charge to use the "
            "Defend Maneuver without spending a Counter Action.\n"
            "(7)-[Triggered, 1/Round]: If you use a Copied Technique, you may "
            "spend up to 2 stacks of Dama Charge to apply an equal amount of "
            "Energy Charges.\n"
            "(8)-[Triggered/Power, 1/Encounter]: Set your amount of Dama "
            "Charges to their maximum.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mastered Mimicry",
      description: "Y\n"
          "(1)-[Permanent]: Super Neko Majin loses the Draining Aspect.\n"
          "(2)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(3)-[Passive]: Increase your Surgency by S(T).\n"
          "(4)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.\n"
          "(5)-[Triggered]: Each time you gain a stack of Dama Charge, regain "
          "Life and Ki Points equal to 1/4 (rounded up) of your Surgency.\n"
          "(6)-[Triggered/Threshold]: Gain a stack of Dama Charge. Upon "
          "gaining a stack of Dama Charge through this effect, double the "
          "amount of Life and Ki Points regained through the 5th effect of "
          "Mastered Mimicry.",
    ),
  ),

  // ========================================================= Future Super Saiyan ===
  TransformationDef(
    name: "Future Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Lone Warrior Awakening",
    transformationLine: "Super Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan 1)",
      "Enhanced Save (Impulsive/Corporeal/Morale)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Draining (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Stand Against Evil (S-Cells)",
        description: "You're ready to make your last stand at any moment, in "
            "order to protect everything you hold dear.\n"
            "(1)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Tier of Power Extra Dice by 1 Dice Category and "
            "increase your Damage Reduction by 1(T).\n"
            "(2)-[1/Round]: While you are below the Injured Health Threshold, "
            "you may use the Energy Charge Maneuver as an Instant Maneuver.\n"
            "(3)-[Triggered/Power, 1/Round]: Reduce your Life Points by an "
            "amount up to 1/2 of your Surgency to regain an equal number of Ki "
            "Points. If this effect knocks you through a Health Threshold, you "
            "automatically succeed at the Steadfast Check for that Health "
            "Threshold and do not suffer from Reduced Momentum.\n"
            "(4)-[Triggered/Start of Turn, Triggered/Transform]: If you are in "
            "a Desperate Battle, enter the Desperate Hero Special State until "
            "the Combat Encounter stops being treated as a Desperate Battle or "
            "you leave this Transformation.",
      ),
      TransformationTrait(
        name: "Desperate Hero (Special State)",
        description: "(1)-[Passive]: Increase your Wound Rolls and Surgency by "
            "S(T).\n"
            "(2)-[Triggered]: If you use a Ki Surge, regain Life Points equal "
            "to your Surgency.\n"
            "(3)-[Triggered, 1/Round]: If you take Damage from an Opponent's "
            "Attacking Maneuver, you may use the Basic Attack Maneuver as an "
            "Out-of-Sequence Maneuver. If you do, you must target the Opponent "
            "that used that Attacking Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If an Attacking Maneuver would knock "
            "you through a Health Threshold after calculating the Damage, "
            "reduce the Damage until the amount you receive puts you exactly 1 "
            "Life Point below the lowest Health Threshold you would have passed "
            "through as a result of that Attacking Maneuver.\n"
            "(5)-[Triggered/Desperate Hero, 1/Encounter]: Gain a Battle Born "
            "stack.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Change the Future",
      description: "You refuse to back down, against all odds, in order to "
          "ensure that evil is stopped, justice is served, and you never have "
          "to lose anyone, ever again.\n"
          "(1)-[Permanent]: Future Super Saiyan loses the Draining Aspect.\n"
          "(2)-[Passive]: While in a Desperate Battle, you may use a second "
          "Triggered/Defeated effect during this Combat Encounter if you have "
          "no non-Defeated Allies.\n"
          "(3)-[Passive]: Treat the Superior State as the Raging State for the "
          "effects of the Raging Aspect.\n"
          "(4)-[Triggered]: When you use the 3rd effect of Golden Power, you "
          "may enter the Superior State instead of the Raging State. If you "
          "do, the effect lasts until the start of your next turn.",
    ),
  ),

  // ========================================= Evolved Stages of the Super Saiyan
  // line (own pages; grouped by transformationLine "Super Saiyan"; each is a
  // Unique Evolved Stage of the named Original Form).
  // ====================================================== Ascended Super Saiyan ===
  TransformationDef(
    name: "Ascended Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 3,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 1). Stress Test "
        "Requirement: +G.",
    transformationLine: "Super Saiyan",
    aspects: ["Graded"],
    amb: {
      DbuAttribute.force: TransformationAmb(graded: true),
    },
    traits: [
      TransformationTrait(
        name: "The Super Saiyan Barrier",
        description: "You're at the edge of awakening, pushing against the "
            "limits of a typical Super Saiyan.\n"
            "(1)-[Passive]: Gain 1(T) Damage Reduction while you are above the "
            "Injured Health Threshold.\n"
            "(2)-[Passive]: Increase the Dice Category of your Tier of Power "
            "Extra Dice by G Dice Categories for all of your Wound Rolls.\n"
            "(3)-[Passive]: While you possess only 1 stack of Super Stack, "
            "reduce your Muscle Penalty by 1(bT).\n"
            "(4)-[Triggered, 1/Encounter]: When using an Ultimate Signature "
            "Technique, you may increase the Extra Dice gained from Energy "
            "Charges for that Attacking Maneuver by G Dice Categories.\n"
            "(5)-[Graded]: Ascended Super Saiyan has 2 Grades. Each Ascended "
            "Super Saiyan Grade decides the amount of Super Stacks you gain "
            "while in this Transformation (Grade 1 -> 1 Super Stack; Grade 2 -> "
            "3 Super Stacks).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Tactical Muscle",
      description: "You become more adept at manipulating the increased power "
          "and bulk of this form, allowing you to move more freely.\n"
          "(1)-[Permanent]: Ascended Super Saiyan gains the Heartbeat (LV1) "
          "Aspect.\n"
          "(2)-[Passive]: The 3rd effect of The Super Saiyan Barrier applies "
          "regardless of how many stacks of Super Stack you possess.\n"
          "(3)-[Triggered]: If you use an Attacking Maneuver or are targeted "
          "by an Attacking Maneuver while in this Transformation you entered "
          "through the Transformation Maneuver, you may use the Transformation "
          "Maneuver as an Out-of-Sequence Maneuver to try and enter a "
          "different Transformation in the Super Saiyan Transformation Line "
          "with an equal or higher Tier of Power Requirement. If you do, "
          "increase your Stress Bonus by 2 for the duration of that "
          "Transformation Maneuver.",
    ),
  ),

  // =================================================== Full Force Super Saiyan 2 ===
  TransformationDef(
    name: "Full Force Super Saiyan 2",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 2). Fully Mastered "
        "Super Saiyan 2. Stress Test Requirement: +5.",
    transformationLine: "Super Saiyan",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Sparking Limit Break",
        description: "Pushing past the limits of Super Saiyan 2, clad in arcs "
            "of lightning, your power skyrockets even further beyond.\n"
            "(1)-[Passive]: Increase the Strike Rolls of your Attacking "
            "Maneuvers that include a Character with a lower Initiative Value "
            "than you as a target by 1(T).\n"
            "(2)-[Passive]: Your Attacking Maneuvers that possess a Ki Wager "
            "equal to or exceeding 1/4 of your Max Capacity have their Wound "
            "Rolls increased by 4(T).\n"
            "(3)-[Triggered/Power, 1/Round]: Spend 4(bT) Ki Points to enter "
            "the Surging State until the end of your turn.\n"
            "(4)-[Triggered, 1/Encounter]: If you would gain any number of "
            "stacks of the Fatigued Combat Condition, you may instead regain "
            "Ki Points equal to 1/2 of your Surgency.",
        // (2): Ki Wager ≥ ¼ Max Capacity → +4(T) Wound.
        wagerWoundEffect:
            WagerWoundEffect(thresholdMaxCapacityDen: 4, bonusPerTier: 4),
      ),
    ],
  ),

  // ===================================================== Perfected Super Saiyan ===
  TransformationDef(
    name: "Perfected Super Saiyan",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 3,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 1). Mastered Super "
        "Saiyan 1. Stress Test Requirement: +4.",
    transformationLine: "Super Saiyan",
    aspects: ["Scaling (LV1)", "Realization", "Pinnacle (LV1)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Greater Golden Power",
        description: "You have no need for those inefficient evolutions of the "
            "Super Saiyan form; when properly mastered, the basic Super Saiyan "
            "far outclasses them.\n"
            "(1)-[Permanent]: You can only master Perfected Super Saiyan if "
            "your base Tier of Power is 4+.\n"
            "(2)-[Passive]: Increase your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(3)-[Passive]: While you are in the Raging and/or Superior State, "
            "increase your Combat Rolls by 1(T).\n"
            "(4)-[Passive]: Your Signature Techniques that possess a Ki Wager "
            "equal to or exceeding 1/4 of your Max Capacity gain an Energy "
            "Charge.\n"
            "(5)-[Passive]: Depending on the Original Form for this Evolved "
            "Stage, apply one of the following effects — Super Saiyan 1: while "
            "you have 6+ stacks of Battle Born, double the bonuses from the "
            "1st effect of S-Cells; Future Super Saiyan: while below the "
            "Injured Health Threshold, increase your Defense Value and Soak "
            "Value by 1(T); Superior Super Saiyan: apply your full Surgency "
            "through the 5th effect of Crazed Battle Lust instead of 1/2; Xeno "
            "Super Saiyan: while you have 6+ stacks of Battle Born, double the "
            "bonuses from the 2nd effect of Class Selection; Ancestral Super "
            "Saiyan: while you have 6+ stacks of Battle Born and are in the "
            "Undying State, increase your Combat Rolls by 1(T); Descended "
            "Super Saiyan: while you have 2+ stacks of Warrior's Blood and are "
            "below the Injured Health Threshold, double the bonuses from the "
            "3rd effect of Awoken Saiya Power; Bio Super Saiyan: while you have "
            "2+ stacks of Battle Creation, gain an additional Adaptation Point "
            "from the 1st effect of Artificial Warrior and increase your "
            "maximum number of Adaptation Points by 1; Super Neko Majin: "
            "double the amount of Dama Charges you obtain through the 1st "
            "effect of I'm Shining!!",
      ),
      TransformationTrait(
        name: "Complete Understanding of the Super Saiyan (Legendary Trait)",
        description: "Unlocked when Perfected Super Saiyan becomes a Legendary "
            "Form via its Mastery. You have unlocked the hidden secrets deep "
            "within your Super Saiyan power.\n"
            "(1)-[Passive]: While in a Transformation with the Super Saiyan "
            "Form Aspect, increase your Stress Bonus by 1.\n"
            "(2)-[Passive]: While below the Injured Health Threshold, increase "
            "your Tier of Power Extra Dice by 1 Dice Category.\n"
            "(3)-[Triggered, 1/Round]: While in a Transformation with the "
            "Super Saiyan Form Aspect, if you use a Signature Technique with a "
            "Ki Wager equal to or exceeding 1/4 of your Maximum Ki Points, "
            "regain Ki Points equal to 1/2 of that Signature Technique's Ki "
            "Point Cost.\n"
            "(4)-[Triggered, 1/Encounter]: While in a Transformation with the "
            "Super Saiyan Form Aspect, if you use an Ultimate Signature "
            "Technique, you may apply your Tier of Power Extra Dice an "
            "additional time to the Strike and Wound Rolls of this Attacking "
            "Maneuver. This effect ignores the usual limit to the amount of "
            "times you can apply your Tier of Power Extra Dice.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Greatest Golden Power",
      description: "You have unleashed the full, unmitigated power of the "
          "Super Saiyan form, without anything to hold you back any longer.\n"
          "(1)-[Permanent]: Perfected Super Saiyan gains a level of the "
          "Scaling Aspect, but has its Tier of Power Requirement increased to "
          "4+ and its Form Type changed to Legendary.\n"
          "(2)-[Permanent]: Perfected Super Saiyan has its Attribute Modifier "
          "Bonus (AG/FO/TE/MA) increased by 2(T) and its Attribute Modifier "
          "Bonus (IN) increased by 1(T), but increase its Stress Test "
          "Requirement by +9.\n"
          "(3)-[Passive]: While below the Injured Health Threshold, increase "
          "your Combat Rolls by 1(T).\n"
          "(4)-[Passive]: Depending on the Original Form for this Evolved "
          "Stage, apply one of the following effects — Super Saiyan 1: select "
          "and gain access to an additional effect from the 3rd effect of "
          "S-Cells; Future Super Saiyan: while below the Injured Health "
          "Threshold, you are in a Desperate Battle and have both Soak Value "
          "and Wound Rolls increased by 1(T); Superior Super Saiyan: if hit by "
          "an Attacking Maneuver, regain Life Points equal to 1/5 of your "
          "Surgency; Xeno Super Saiyan: for every 'Class Up' Awakening, "
          "increase Max Capacity by 2(bT); Ancestral Super Saiyan: while 4+ "
          "Battle Born and in the Undying State, increase Soak Value and Wound "
          "Rolls by 1(T); Descended Super Saiyan: while 2+ Warrior's Blood, "
          "treat the Health Threshold you are below as 1 lower; Bio Super "
          "Saiyan [Triggered/Transform, 1/Encounter]: gain a Battle Creation "
          "stack, then use a Healing Surge as an Out-of-Sequence Maneuver; "
          "Super Neko Majin [Triggered, 1/Round]: if you spend 2 Dama Charge "
          "through the 7th effect of I'm Shining!!, increase Energy Charge "
          "Extra Dice by 2 Categories for that Attacking Maneuver.",
    ),
  ),

  // ============================================================== Golden Oozaru ===
  TransformationDef(
    name: "Golden Oozaru",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 3,
    prerequisiteText: "Evolved Stage: Unique (Oozaru). Access to Super Saiyan "
        "1. Stress Test Requirement: +12.",
    aspects: ["Armored", "Super Saiyan Form", "Peaked"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Golden Beast",
        description: "Wielding the golden power of your Super Saiyan "
            "Transformation, your inner beast awakens, becoming a shining "
            "beacon of power and fury.\n"
            "(1)-[Constant]: If you fail to enter this Transformation or leave "
            "this Transformation due to failing a Stress Test, enter the "
            "Oozaru Alternate Form.\n"
            "(2)-[Passive]: While in the Raging or Superior State, treat your "
            "Size Category as Colossal for your effects and the effects of "
            "Punching Down.\n"
            "(3)-[Passive]: While you have 4+ stacks of Battle Born, increase "
            "the Tier of Power Extra Dice for your Combat Rolls by 1 Category "
            "and increase your Soak Value by 1(T).\n"
            "(4)-[Passive]: Gain access to the Fire Breath Signature Technique "
            "(Super Signature) — Foundation: Magic (Elemental: Fire); "
            "Advantages: Terrain Destruction (2), Widespread Assault (Cone), "
            "Concentrated Strike; Disadvantages: Restricted - Transformation "
            "(2, Golden Oozaru); Ki Point Cost: 13(T).\n"
            "(5)-[Triggered]: While you have 6+ stacks of Battle Born, if you "
            "make an Attacking Maneuver in which all of the targets qualify "
            "for the effects of Punching Down, increase the Wound Roll by 1(T) "
            "for each Size Category you are larger than the largest Character "
            "among those targets.\n"
            "(6)-[Triggered, 1/Round]: If you knock an Opponent through a "
            "Health Threshold, they gain a stack of the Broken Combat "
            "Condition until the start of your next turn.\n"
            "(7)-[Triggered/Transform, 1/Encounter]: Use a Ki Surge.",
      ),
      TransformationTrait(
        name: "Primal Spark (Legendary Trait)",
        description: "The untamed roar of the Great Ape within, sparking with "
            "golden power, has awakened the primal energy deep inside you.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Battle Born applied "
            "to your Wound Rolls, increase your Surgency by 1(T).\n"
            "(2)-[Triggered, 1/Encounter]: If you use a Surge during your "
            "turn, you may enter the Superior State until the end of that "
            "turn.\n"
            "(3)-[Triggered/Power, 1/Encounter]: If you have 2+ stacks of "
            "Battle Born applied to your Wound Rolls, you may use a Ki Surge "
            "as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ==================================================== Maximum Super Saiyan 3 ===
  TransformationDef(
    name: "Maximum Super Saiyan 3",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 3). Fully Mastered "
        "Super Saiyan 3. Stress Test Requirement: +3.",
    transformationLine: "Super Saiyan",
    aspects: ["Scaling (LV2)", "Draining (LV2)", "Peaked", "Pinnacle (LV1)"],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Beyond Limitless",
        description: "Your sheer power eclipses all logic, bordering on "
            "nonsensical, and even physics can no longer restrain it as you "
            "push ever further beyond what's possible into the unknown.\n"
            "(1)-[Passive]: For each base Tier of Power you possess beyond 4, "
            "reduce the Draining Aspect for Maximum Super Saiyan 3 by 1 "
            "level.\n"
            "(2)-[Passive]: Increase your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(3)-[Triggered, 1/Round]: If you hit an Opponent with an "
            "Attacking Maneuver that has a Ki Wager equal to or exceeding 1/4 "
            "of your Max Capacity, apply an Energy Charge to that Attacking "
            "Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique, you may apply the All Out Super Profile to that "
            "Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Super Saiyan Specialist (Legendary Trait)",
        description: "You have become so adept at wielding the Super Saiyan "
            "form that it comes as easily to you as breathing.\n"
            "(1)-[Passive]: While you are in a Transformation with the Super "
            "Saiyan Form Aspect, increase your Force and Magic Modifiers by "
            "1(T).\n"
            "(2)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain from Legend Realized upon entering a Transformation with "
            "the Super Saiyan Form Aspect by 1/2 of your Surgency.\n"
            "(3)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver "
            "that has a Ki Wager equal to or exceeding 1/4 of your Max "
            "Capacity, after concluding that Maneuver, you may use a Ki Surge "
            "as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ========================================================== Super Saiyan Rage ===
  TransformationDef(
    name: "Super Saiyan Rage",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 2). Fully Mastered "
        "Super Saiyan 2. Stress Test Requirement: +8.",
    transformationLine: "Super Saiyan",
    aspects: ["Innate State (Raging)", "Pinnacle (LV1)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Azure Rage",
        description: "Your pure rage emits a blue glow emulating that of the "
            "god-like powers of Super Saiyan Blue, showcasing just how strong "
            "you've truly become.\n"
            "(1)-[Triggered/Transform]: You may gain any number of Super "
            "Stacks up to your maximum until you leave this Transformation. For "
            "each Super Stack gained through this effect, Super Saiyan Rage "
            "gains a level of the Draining Aspect until you leave it.\n"
            "(2)-[Passive]: For calculating your Muscle Penalty, and for all of "
            "your effects, you only count as possessing a single Super Stack.\n"
            "(3)-[Passive]: While you are in the Furious or Apoplectic level of "
            "the Raging State, Super Saiyan Rage gains the Armored Aspect.\n"
            "(4)-[Passive]: Double the penalty from the 3rd effect of Fury "
            "Becomes Hope if the Attacking Maneuver includes an Ally that is "
            "below the Injured Health Threshold as a target.\n"
            "(7)-[Triggered/Threshold]: Enter the next level of the Raging "
            "State until the end of your next turn.\n"
            "(8)-[Triggered, 1/Encounter]: If you knock an Opponent through a "
            "Health Threshold with an Attacking Maneuver, that Opponent gains "
            "the Compelled Combat Condition with you as the target.\n"
            "(9)-[Triggered/Start of Turn, 1/Encounter]: If you are in the "
            "Apoplectic level of the Raging State, you may enter the Surging "
            "State until the end of your turn. If you do, ignore the 2nd "
            "effect of the Surging State.",
      ),
      TransformationTrait(
        name: "Fury Becomes Hope (Legendary Trait)",
        description: "Your pure rage grows stronger, but your resolve and "
            "control grow stronger as well.\n"
            "(1)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Surgency by 2(T).\n"
            "(2)-[Passive]: While you are in the Raging State, increase your "
            "Soak Value and Wound Rolls by 1(T).\n"
            "(3)-[Passive]: While you are in the Raging State, reduce the Dice "
            "Score of your Opponents' Attacking Maneuvers Strike and Wound "
            "Rolls by 1(bT) and 2(bT) respectively if they do not include you "
            "as a target.\n"
            "(4)-[Triggered/Power, 1/Round]: Enter the Raging State until the "
            "start of your next turn.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Compressed Azure",
      description: "You've managed to contain the massive bulk of energy "
          "flowing through you, wielding it more efficiently.\n"
          "(1)-[Permanent]: Super Saiyan Rage gains the Scaling (LV2) "
          "Aspect.\n"
          "(2)-[Passive]: Increase your Combat Rolls by 1(T).\n"
          "(3)-[Passive]: Halve the amount of Ki Points you lose through the "
          "Draining Aspect.",
    ),
  ),

  // ===================================== Self-Restraint line (Base/Null Stage +
  // Restrained Form on one page; All-Out Form and Variants branch off it).
  // ============================================== Self-Restraint (Base Form) ===
  TransformationDef(
    name: "Self-Restraint",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: "Base Form (Null Stage). Access to the Holding Back "
        "Special Maneuver.",
    transformationLine: "Self-Restraint",
    stage: 0,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Natural Power",
        description: "The sheer power of your natural form is greater than "
            "most.\n"
            "(1)-[Passive]: Increase your Saving Throws and Might by 1(T) for "
            "the duration of any Clashes initiated by an Opponent.\n"
            "(2)-[Passive]: If you have no stacks of Holding Back, increase "
            "your Combat Rolls by 1(T).\n"
            "(3)-[Triggered/Power, 1/Round]: If you have no stacks of Holding "
            "Back, gain an additional stack of Power.",
      ),
    ],
  ),

  // ============================================================= Restrained Form ===
  TransformationDef(
    name: "Restrained Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 2,
    prerequisiteText: "Access to the Holding Back Special Maneuver.",
    transformationLine: "Self-Restraint",
    stage: 1,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true),
      DbuAttribute.force: TransformationAmb(graded: true),
      DbuAttribute.tenacity: TransformationAmb(graded: true),
      DbuAttribute.magic: TransformationAmb(graded: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Percentage of Power",
        description: "You wield only a fraction of your power in combat, "
            "assured of your superiority. (AG/FO/TE/MA AMB is set by your "
            "Holding Back stacks; IN is +1(bT).)\n"
            "(1)-[Permanent]: You cannot enter this Transformation unless you "
            "have at least 1 stack of Holding Back.\n"
            "(2)-[Passive]: For each stack of Holding Back you possess, reduce "
            "the Attribute Modifier Bonuses (AG/FO/TE/MA) of this "
            "Transformation by 1.\n"
            "(3)-[Passive]: Double the amount of Life and Ki Points you regain "
            "from Legend Realized.\n"
            "(4)-[Passive]: For each stack of Holding Back you possess, reduce "
            "the Ki Point Cost of your Attacking Maneuvers by 1(T).\n"
            "(5)-[Triggered/Start of Turn]: Regain 2(bT) Ki Points for each "
            "stack of Holding Back you possess.",
      ),
      TransformationTrait(
        name: "Unleash Your Power",
        description: "When you finally decide to get serious, your power "
            "skyrockets dramatically.\n"
            "(1)-[Automatic]: If you lose all stacks of Holding Back, leave "
            "this Transformation. You do not suffer from Stress Exhaustion and "
            "may use the Power Up Maneuver or Transformation Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(2)-[Constant, 1/Encounter]: If you enter a different Form through "
            "the Transformation Maneuver used through 1st effect of Unleash "
            "Your Power, apply any [Passive] effects that increase/multiply the "
            "Legend Realized from this Transformation's Traits for any Legend "
            "Realized gained due to entering that new Form.\n"
            "(3)-[Triggered/Power, 1/Encounter]: You can remove all stacks of "
            "Holding Back you possess. If you do, for each stack of Holding "
            "Back you lost, regain 2(bT) Life Points.",
      ),
    ],
  ),

  // ================================================================ All-Out Form ===
  TransformationDef(
    name: "All-Out Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Access to the Restrained Form Transformation.",
    transformationLine: "Self-Restraint",
    stage: 1,
    aspects: [
      "Enhanced Save (All)",
      "Draining (LV1)",
      "Difficult (LV1)",
      "Straining",
      "Exhausting",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Unleash It All",
        description: "By releasing your suppressed power, you are able to "
            "surpass all expectations and overcome any obstacle placed in "
            "front of you.\n"
            "(1)-[Permanent]: You cannot enter this Transformation if you have "
            "any stacks of Holding Back.\n"
            "(2)-[Passive]: You cannot gain stacks of Holding Back while in "
            "this Transformation.\n"
            "(3)-[Passive]: Halve the amount of Ki Points you regain from "
            "Legend Realized.\n"
            "(4)-[Passive]: While you are in the Superior State, double the "
            "bonus from the 2nd effect of Natural Power.\n"
            "(5)-[Passive]: While you are in the Superior State, increase your "
            "Damage Reduction and Might by 1(T).\n"
            "(6)-[Triggered/Transform]: If you entered this Transformation "
            "through a Transformation Maneuver used through the 1st effect of "
            "Unleash your Power, use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver. If you do, you may trigger the 1st "
            "effect of All-Out Power twice - ignoring its [1/Round] Keyword.",
      ),
      TransformationTrait(
        name: "All-Out Power",
        description: "Your natural power is so great that none can stand "
            "before you.\n"
            "(1)-[Triggered/Power, Resource, 1/Round]: Gain a stack of "
            "'Focused Power' (max. 2).\n"
            "(2)-[Passive]: Increase the Dice Category of your Tier of Power "
            "Extra Dice and Greater Dice by 1 Category for each stack of "
            "Focused Power you possess.\n"
            "(3)-[Passive]: Increase your Wound Rolls by 1(T) for each stack "
            "of Focused Power you possess.\n"
            "(4)-[Passive]: All-Out Form gains 1 level of the Draining Aspect "
            "for each stack of Focused Power you possess.\n"
            "(5)-[1/Round]: If you would spend a Counter Action for any reason, "
            "you may spend a stack of Focused Power instead.\n"
            "(6)-[Triggered, 1/Round]: When making an Attacking Maneuver, you "
            "may spend any number of Focused Power stacks to apply an Energy "
            "Charge for each stack spent. You do not lose these stacks of "
            "Focused Power until concluding that Attacking Maneuver.\n"
            "(7)-[Triggered/Power, 1/Round]: Spend a stack of Focused Power to "
            "enter the Superior State until the start of your next turn. Upon "
            "leaving the Superior State entered through this effect, gain the "
            "Fatigued and Drained Combat Conditions until the start of your "
            "next turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "All-Out Acclimation",
        description: "You become fully acclimated to unleashing your full "
            "innate strength.\n"
            "(1)-[Permanent]: All-Out Form loses 1 level of the Draining "
            "Aspect and the Straining Aspect.\n"
            "(2)-[Permanent]: All-Out Form gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Passive]: Ignore the 3rd effect of Unleash it All.\n"
            "(4)-[Passive]: You do not gain the Fatigued Combat Condition "
            "through the 7th effect of All-Out Power.",
      ),
      TransformationTrait(
        name: "Truth of Power",
        description: "You measure how strong your enemies are by how much or "
            "how little of your power you need to use in order to defeat "
            "them.\n"
            "(1)-[Permanent]: All-Out Form loses the Exhausting Aspect.\n"
            "(2)-[Permanent]: All-Out Form may replace any Alternate Form in "
            "the Prerequisites of a Legendary Form.\n"
            "(3)-[Passive]: Ignore the 2nd effect of the Superior State.\n"
            "(4)-[Passive]: You do not gain the Drained Combat Condition "
            "through the 7th effect of All-Out Power.",
      ),
    ],
  ),

  // ================================================================ Hidden Beast ===
  TransformationDef(
    name: "Hidden Beast",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Animal",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 2,
    prerequisiteText: "Access to the Holding Back Special Maneuver.",
    transformationLine: "Self-Restraint",
    stage: 1,
    aspects: ["Variant (Restrained Form)", "Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true),
      DbuAttribute.force: TransformationAmb(graded: true),
      DbuAttribute.tenacity: TransformationAmb(graded: true),
      DbuAttribute.magic: TransformationAmb(graded: true),
      DbuAttribute.insight:
          TransformationAmb(coefficient: -1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Amicable Appearance (Percentage of Power)",
        description: "A (AG/FO/TE/MA AMB is set by your Holding Back stacks; "
            "IN is -1(T).)\n"
            "(1)-[Permanent]: You cannot enter this Transformation unless you "
            "have at least 1 stack of Holding Back.\n"
            "(2)-[Passive]: Lose access to all of your Bestial Traits while in "
            "this Transformation.\n"
            "(3)-[Passive]: For each stack of Holding Back you possess, reduce "
            "the Attribute Modifier Bonuses (AG/FO/TE/MA) of this "
            "Transformation by 1.\n"
            "(4)-[Passive]: Double the amount of Life and Ki Points you regain "
            "from Legend Realized.\n"
            "(5)-[Passive]: For each Bestial Trait you lost access to through "
            "the 2nd effect of Amicable Appearance, increase your Surgency by "
            "1(bT).\n"
            "(6)-[Passive]: For each Bestial Trait you lost access to through "
            "the 2nd effect of Amicable Appearance, increase the Dice Score of "
            "your Skill Checks by 1 (max. 3).\n"
            "(7)-[Triggered/Start of Turn]: Regain Ki Points equal to 1/2 of "
            "your Surgency.\n"
            "(8)-[Triggered/Injured, 1/Encounter]: Use a Healing Surge as an "
            "Out-of-Sequence Maneuver. If you do, you may then use a Power Up "
            "Maneuver as an Out-of-Sequence Maneuver, but you must trigger the "
            "3rd effect of Unleash your Power if you do.",
      ),
    ],
  ),

  // ======================================================== Suppressed Evolution ===
  TransformationDef(
    name: "Suppressed Evolution",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 0,
    prerequisiteText: "Access to the Holding Back Special Maneuver.",
    transformationLine: "Self-Restraint",
    stage: 1,
    aspects: [
      "Variant (Restrained Form)",
      "Enhanced Save (Morale)",
      "Natural (LV2)",
      "Graded",
      "Peaked",
    ],
    // AG/FO/TE/MA AMB is −G (a Grade-set malus): Grade 1→−1(T) … 3→−3(T);
    // IN is +1(bT) (a flat gain). Suppressed Evolution has 3 Grades.
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [-1, -2, -3]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [-1, -2, -3]),
      DbuAttribute.tenacity:
          TransformationAmb(graded: true, gradePerTier: [-1, -2, -3]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [-1, -2, -3]),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Underwhelming Evolution (Percentage of Power)",
        description: "You have regressed into a weaker form, suppressing your "
            "true strength under layers of bio-armor, much like your mutant "
            "kin. (AG/FO/TE/MA AMB is -G, set by Grade; IN is +1(bT).)\n"
            "(1)-[Permanent]: You cannot enter a Grade of Suppressed Evolution "
            "unless you have a number of Holding Back stacks equal to or "
            "exceeding the Grade.\n"
            "(2)-[Automatic]: If your number of Holding Back stacks falls "
            "underneath the number of a Grade you are currently in, you leave "
            "that Grade and enter a lower Grade of your choice (you are still "
            "limited by the 1st effect of Underwhelming Evolution).\n"
            "(3)-[Triggered, Ruling]: At the end of your turn, you may spend a "
            "stack of Overwhelm to gain a stack of 'Underwhelm' (max. 1+G). "
            "Upon leaving this Transformation, convert all of your stacks of "
            "Underwhelm into stacks of Overwhelm (this may allow you to exceed "
            "your limit).\n"
            "(4)-[Triggered, 1/Round]: When using the Signature Technique "
            "Maneuver, you may ignore the Attribute Modifier Bonus (AG/FO/MA) "
            "of this Transformation for the duration of that Attacking "
            "Maneuver.\n"
            "(5)-[Passive]: Increase your Stress Bonus by G.\n"
            "(6)-[Passive]: Increase the amount Life and Ki Points you regain "
            "from Legend Realized by 2G(bT).\n"
            "(7)-[Passive]: Reduce the Ki Point Cost of your Attacking "
            "Maneuvers by G(T).\n"
            "(8)-[Graded]: Suppressed Evolution has 3 Grades.",
      ),
    ],
  ),

  // ================================================================= Larva Form ===
  TransformationDef(
    name: "Larva Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 2,
    prerequisiteText: "Access to the Holding Back Special Maneuver, Uncanny "
        "Monster Racial Trait.",
    transformationLine: "Self-Restraint",
    stage: 1,
    aspects: ["Variant (Restrained Form)", "Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true),
      DbuAttribute.force: TransformationAmb(graded: true),
      DbuAttribute.tenacity: TransformationAmb(graded: true),
      DbuAttribute.magic: TransformationAmb(graded: true),
      DbuAttribute.insight:
          TransformationAmb(coefficient: -1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Buried for 3 Years (Percentage of Power)",
        description: "After reverting to a larval form, you must go "
            "underground. There, your form matures. (AG/FO/TE/MA AMB is set by "
            "your Holding Back stacks; IN is -1(T).)\n"
            "(1)-[Permanent]: You cannot enter this Transformation unless you "
            "have at least 1 stack of Holding Back.\n"
            "(2)-[Adventuring]: You may bury yourself underground for any "
            "length of time. While buried underground, you cannot be sensed. "
            "If you spend a large amount of time underground, your ARC may "
            "allow you to gain Power Levels or Awakenings, representing your "
            "body and mind maturing.\n"
            "(3)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, you may select 2 Bestial Traits or 1 Monstrous "
            "Trait. While in this Transformation, you have your selection "
            "instead of those selected for the 2nd effect of Uncanny "
            "Monster.\n"
            "(4)-[Passive]: You are Small, but treat your Size Category as if "
            "it was Enormous for calculating your Speeds. If your base Size "
            "Category is already Small or less, your Size Category is instead 1 "
            "lower than your base Size Category.\n"
            "(5)-[Passive]: For each stack of Holding Back you possess, reduce "
            "the Attribute Modifier Bonuses (AG/FO/TE/MA) of this "
            "Transformation by 1 and increase the Dice Score of your Stealth "
            "Skill Checks by 1 (max. 3).\n"
            "(6)-[Passive]: Increase the amount of Life and Ki Points regained "
            "through Legend Realized by 3(bT).\n"
            "(7)-[Triggered, 1/Round]: When using the Signature Technique "
            "Maneuver, you may ignore the Attribute Modifier Bonus (AG/FO/MA) "
            "of this Transformation for the duration of that Attacking "
            "Maneuver.\n"
            "(8)-[Triggered, Resource]: Each time you would gain an Adaptation "
            "Point, you may instead gain a Maturation Point. Your maximum "
            "number of Maturation Points is equal to your maximum number of "
            "Adaptation Points.\n"
            "(9)-[Triggered/Start of Turn]: For each Maturation Point you "
            "possess, regain 1(bT) Life and Ki Points (max. 5(bT)).\n"
            "(10)-[Triggered, 1/Encounter]: If you leave this Transformation, "
            "convert all Maturation Points you possess into Adaptation Points.",
      ),
    ],
  ),

  // ============================================================ Super Evolution ===
  TransformationDef(
    name: "Super Evolution",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Growth (LV1)",
      "Scaling (LV2)",
      "Draining (LV2)",
      "Power High (LV2)",
      "Difficult (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Apex Evolution",
        description: "You've managed to create a Transformation that, unlike "
            "most mutants of your kind, increases your power rather than "
            "suppressing it.\n"
            "(1)-[Permanent]: You cannot enter this Transformation if you "
            "possess the Emperor Factor Trait and your base Tier of Power is "
            "less than 4. Upon gaining access to this Transformation, if you "
            "possess the Emperor Factor Trait, this Transformation is Fully "
            "Mastered.\n"
            "(2)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select 2 Evolution Traits. You have access to "
            "those Evolution Traits while you are in this Transformation.\n"
            "(3)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select an additional effect for the 2nd effect of "
            "Survivor. You gain access to that effect while you are in this "
            "Transformation.\n"
            "(4)-[1/Round]: As a Standard Action with an Action Cost of 1 "
            "Action, you may enter the Overwhelming Focus Special State.\n"
            "(5)-[Passive]: Gain access to the Apex Challenge Special "
            "Maneuver.\n"
            "Overwhelming Focus Special State — (1)-[Passive]: While you are "
            "in this State, your Plating gains the Mask of the Strongest "
            "Special Apparel Quality. (2)-[Automatic]: If you leave this "
            "Transformation (except to enter an Evolved Stage for Super "
            "Evolution), you leave this State. (3)-[Automatic/Start of Turn]: "
            "Spend 2 stacks of Overwhelm; if you cannot, leave this State.\n"
            "Mask of the Strongest Special Apparel Quality — Apparel Category: "
            "Armor; Prerequisites: Access to the Super Evolution "
            "Transformation; Quality Slots: 1. Effects: Increase your Combat "
            "Rolls and Damage Reduction by 1/2 (rounded up) of the Apparel "
            "Bonus.\n"
            "Apex Challenge Special Maneuver [1/Round] — Maneuver Type: "
            "Counter; Action Cost: 1 Counter Action; KP Cost: 4(T). Effect: "
            "When you are targeted by an Opponent's Attacking Maneuver, you "
            "may forgo your Dodge Roll to use this Maneuver. Before your "
            "Opponent rolls their Wound Roll, make a Wound Roll as if you made "
            "an Attacking Maneuver of the Simple Profile (any Foundation). You "
            "may spend any amount of Ki Points to increase the Dice Score of "
            "this Wound Roll by an equal amount. If your Dice Score exceeds "
            "the Opponent's, you take no Damage and enter the Superior State "
            "until the end of your next turn. If you enter the Superior State "
            "through this effect, you may then use the Basic Attack Maneuver "
            "as an Out-of-Sequence Maneuver and may apply the Charging Assault "
            "Advantage (you must include the attacking Opponent as a target).",
      ),
      TransformationTrait(
        name: "Unstoppable Brutality",
        description: "The overpowering fighting style you've developed grows "
            "even more brutal as you become a violent monster on the "
            "battlefield.\n"
            "(1)-[Passive]: Increase your maximum number of Overwhelm stacks "
            "to 6.\n"
            "(2)-[Passive]: Instead of losing all stacks of Overwhelm through "
            "the 2nd effect of Overwhelming Fighter, you only lose 2 stacks of "
            "Overwhelm.\n"
            "(3)-[Passive]: For every 2 stacks of Overwhelm you possess, "
            "increase your Damage Reduction by 1(T).\n"
            "(4)-[1/Round]: As an Instant Maneuver, you may spend 2 stacks of "
            "Overwhelm to use the Basic Attack Maneuver, Signature Technique "
            "Maneuver, or Energy Charge Maneuver as an Out-of-Sequence "
            "Maneuver.\n"
            "(5)-[Triggered]: If an effect would make you enter the Superior "
            "State while you are already in the Superior State, that effect "
            "instead gives you a stack of Overwhelm.\n"
            "(6)-[Triggered, 1/Encounter]: If you use the Energy Charge "
            "Maneuver, you may maximize your stacks of Overwhelm.",
      ),
      TransformationTrait(
        name: "Apex Domination (Legendary Trait)",
        description: "Unlocked when Super Evolution becomes a Legendary Form "
            "via its 3rd Mastery. Your aggressive nature manifests most "
            "clearly in your strongest techniques, allowing you to destroy the "
            "opposition with brutal efficiency.\n"
            "(1)-[Passive]: Increase your maximum number of Overwhelm stacks "
            "by 1.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Overwhelm, increase "
            "your Might by 1(T).\n"
            "(3)-[Passive]: Double the amount of Overwhelm stacks you gain "
            "through the 5th effect of Unstoppable Brutality.\n"
            "(4)-[Triggered, 1/Round]: At the start of an Opponent's turn who "
            "is not at Long Range, you may make a Might Clash against an "
            "Opponent. If you win, they gain the Compelled Combat Condition "
            "with you as the target.\n"
            "(5)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique, you may apply either the All Out or Complete "
            "Annihilation Super Profile to that Attacking Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Powerful Evolution",
        description: "The increased might of your new form comes more easily "
            "to you.\n"
            "(1)-[Permanent]: Super Evolution loses M levels of the Draining "
            "and Power High Aspects.\n"
            "(2)-[Passive]: While you are in the Superior State, double the "
            "amount of Overwhelm Stacks you gain through the 1st effect of "
            "Overwhelming Fighter.\n"
            "(3)-[Triggered/Superior, M/Encounter]: Gain 2 stacks of "
            "Overwhelm.\n"
            "(4)-[Triggered/Start of Turn, M/Encounter]: Apply the effects of "
            "Legend Realized if you do not have access to the Emperor Mutation "
            "Trait.",
      ),
      TransformationTrait(
        name: "Mighty Evolution",
        description: "The superiority of your Transformation becomes painfully "
            "obvious to all who witness your power.\n"
            "(1)-[Permanent]: You cannot master Super Evolution for the 3rd "
            "time unless your base Tier of Power is 4+.\n"
            "(2)-[Passive]: Ignore the 2nd effect of the Superior State.\n"
            "(3)-[Triggered/Power, 1/Round]: You may spend 2 stacks of "
            "Overwhelm to enter the Superior State until the start of your next "
            "turn.",
      ),
      TransformationTrait(
        name: "Superior Evolution",
        description: "By pushing your power to its absolute maximum and "
            "beyond, you shatter the barrier of limitation and unleash power "
            "enough to create a new legend.\n"
            "(1)-[Triggered/Overwhelming Focus]: Super Evolution becomes a "
            "Legendary Form until you leave the Overwhelming Focus State.\n"
            "(2)-[Constant]: If you use the Transformation Maneuver to enter "
            "Super Evolution, you may increase its Stress Test Requirement by 9 "
            "for the duration of that Transformation Maneuver. If you succeed "
            "at the Stress Test and successfully enter the Transformation, you "
            "may enter the Overwhelming Focus State.\n"
            "(3)-[Passive]: While this Transformation is a Legendary Form, "
            "increase the Stress Test Requirement of this Transformation by 9 "
            "and its Attribute Modifier Bonus (AG/FO/TE/IN/MA) by 1(T).\n"
            "(4)-[Passive]: While this Transformation is a Legendary Form, it "
            "gains the Armored Aspect and 2 more levels of the Scaling Aspect.",
      ),
    ],
  ),

  // ========================================================= Brilliant Evolution ===
  TransformationDef(
    name: "Brilliant Evolution",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Glowing",
      "Armored",
      "Prelude",
      "Weakening",
      "Exhausting",
      "Difficult (LV1)",
      "Draining (LV2)",
      "Power High (LV2)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Brilliant Plating",
        description: "The golden gleam of your shiny new plating shows the "
            "world that all should kneel before your majesty.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select 3 Evolution Traits. You have access to "
            "those Evolution Traits while you are in this Transformation.\n"
            "(2)-[Passive]: Gain access to a Brilliant Evolution Trait. The "
            "Trait you gain must have the name of the Evolution Trait you "
            "selected for the 3rd effect of Overwhelming Fighter in brackets "
            "after the name.\n"
            "(3)-[Passive]: Increase the Apparel Bonus of your Plating by "
            "1(T).\n"
            "(4)-[Choice]: Depending on your choice for the Option effect of "
            "Survivor, gain one of: Dense Plating (Soak +2(T) at 2 "
            "Over-Maximum); Sleek Plating (Defense +1(T)); Power Plating "
            "(Wound Rolls & Might +1(T)); Combat Plating (Strike +1(T)).\n"
            "Select your Brilliant Evolution Trait below (it must match, in "
            "brackets, the Evolution Trait you chose for Overwhelming "
            "Fighter).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Brilliant Evolution Trait',
            options: [
              TraitOption(
                name: 'Astounding Speed (Aerodynamic)',
                description: '(1)-[Passive]: Increase your Defense Value and '
                    'Speeds by 1(T) while in the Superior State. '
                    '(2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 3rd effect of Aerodynamic.',
              ),
              TraitOption(
                name: 'Balanced Evolution (Balance of Magic and Might)',
                description: '(1)-[Passive]: While your Attribute Score for '
                    'your Force and Magic Attributes is equal to one another, '
                    'increase your Soak Value by 1(T). (2)-[Triggered/Power, '
                    '1/Round]: If your Force and Magic Attribute Scores are '
                    'equal, gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: 'Bestial Brilliance (Bestial Evolution)',
                description: '(1)-[Passive]: While you possess 2 stacks of '
                    'Over-Maximum, increase your Strike Rolls, Dodge Rolls, '
                    'and Soak Value by 1(T).',
              ),
              TraitOption(
                name: 'Brilliant Suit (Bio-Suit)',
                description: '(1)-[Passive]: Increase your Damage Reduction by '
                    '1(T). (2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 2nd effect of Bio-Suit.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.damageReduction],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Burning Brilliantly (Burning Hatred)',
                description: '(1)-[Passive]: Increase your Strike Rolls '
                    'against your Enemy by 1(T). (2)-[Triggered]: If you '
                    'Defeat your Enemy or knock them through a Health '
                    'Threshold with your Attacking Maneuver, gain a stack of '
                    'Over-Maximum.',
              ),
              TraitOption(
                name: 'Comfort in Brilliance (Comfortable Count)',
                description: '(1)-[Passive]: While in the Spectator State, '
                    'increase your Defense Value, Soak Value, and Damage '
                    'Reduction by 1(T). (2)-[Triggered, 1/Round]: If you gain '
                    '2+ stacks of Overwhelm from the 3rd effect of Comfortable '
                    'Count, gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: 'Empowered Tail (Elongated Tail)',
                description: '(1)-[Passive]: Double the amount of Overwhelm '
                    'stacks you gain from the Tail Attack Maneuver. '
                    '(2)-[Triggered, 1/Round]: If you Defeat an Opponent or '
                    'knock them through a Health Threshold with your Tail '
                    'Attack Maneuver, gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: 'Freezing Tactics (Frigid Tricks)',
                description: '(1)-[1/Round]: You may use a Unique Ability that '
                    'is a Standard Maneuver with an Action Cost of 1 Action as '
                    'an Instant Maneuver. (2)-[Triggered, 1/Round]: If you win '
                    'a Clash against an Opponent through the effects of your '
                    'Unique Abilities, gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: 'Fury Incarnate (Furious Onslaught)',
                description: '(1)-[Permanent]: Brilliant Evolution gains the '
                    'Raging and Innate State (Raging) Aspects. (2)-[Triggered, '
                    '1/Round]: If you Defeat an Opponent with an Attacking '
                    'Maneuver, gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: "King's Standing (King's Stature)",
                description: '(1)-[Passive]: Apply Punching Down to all '
                    'Characters that are your Size Category or lower. '
                    '(2)-[Triggered, 1/Round]: If you knock an Opponent '
                    'through a Health Threshold with an Attacking Maneuver '
                    'that was benefiting from Punching Down, gain a stack of '
                    'Over-Maximum.',
              ),
              TraitOption(
                name: 'Last Brilliance (Last Resource)',
                description: '(1)-[Passive]: Increase your Strike Rolls by '
                    '1(T) for each Health Threshold you are below. '
                    '(2)-[Triggered/Threshold]: Gain a stack of Over-Maximum.',
              ),
              TraitOption(
                name: 'Majestic Brilliance (Majestic Grace)',
                description: '(1)-[Passive]: Increase the Attribute Modifier '
                    'Bonus (PE) for this Transformation by 4(T). '
                    '(2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 2nd effect of Majestic Grace.',
                ambPerTierBonus: {DbuAttribute.personality: 4},
              ),
              TraitOption(
                name: 'Perfectly Brilliant (Perfect Warrior)',
                description: '(1)-[Passive]: While you are in the Healthy '
                    'Health Threshold, increase your Strike Rolls and Wound '
                    'Rolls by 1(T). (2)-[Triggered/Start of Turn]: Instead of '
                    'a stack of Overwhelm, you may gain a stack of Over-Maximum '
                    'through the 2nd effect of Perfect Warrior.',
              ),
              TraitOption(
                name: 'Resplendent Energy (Redirected Energy)',
                description: '(1)-[Triggered]: Upon gaining a stack of '
                    'Overwhelm, regain 2(bT) Life Points. (2)-[1/Round]: You '
                    'may spend 2 stacks of Overwhelm to roll 2d10(T); regain '
                    'that amount of Ki Points (this roll is considered a Legend '
                    'Realized for all of your effects).',
              ),
              TraitOption(
                name: 'Ruling Lord (Ruler)',
                description: '(1)-[Passive]: Increase the Combat Rolls and '
                    'Soak Value of your Minions by 1(T). (2)-[Triggered, '
                    '1/Round]: Instead of a stack of Overwhelm, you may gain a '
                    'stack of Over-Maximum through the 2nd effect of Ruler.',
              ),
              TraitOption(
                name: 'Star-Searing Fury (Searing Anger)',
                description: '(1)-[Triggered/Power, 1/Round]: If you are in '
                    'the Raging State, enter the Surging State until the end '
                    'of your turn. (2)-[Triggered/Surging]: Gain a stack of '
                    'Over-Maximum.',
              ),
              TraitOption(
                name: 'Stealth in Sparkles (Stealthy Trick)',
                description: '(1)-[Passive]: Apply an Energy Charge to all '
                    'Attacking Maneuvers that target only Oblivious Opponents. '
                    '(2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 2nd effect of Stealthy Trick.',
              ),
              TraitOption(
                name: 'Studious Overlord (Studied Lord)',
                description: '(1)-[Passive]: Increase the Attribute Modifier '
                    'Bonus (SC) for this Transformation by 4(T). '
                    '(2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 2nd effect of Studied Lord.',
                ambPerTierBonus: {DbuAttribute.scholarship: 4},
              ),
              TraitOption(
                name: 'Terrifying Brilliance (Terrifying Pressure)',
                description: '(1)-[Passive]: Increase your Wound Rolls against '
                    'characters with the Shaken Combat Condition by 2(T). '
                    '(2)-[Triggered, 1/Round]: Instead of a stack of '
                    'Overwhelm, you may gain a stack of Over-Maximum through '
                    'the 2nd effect of Terrifying Pressure.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Shining Evolution",
        description: "Your masterpiece of a Transformation has increased your "
            "power greatly, allowing you to annihilate all who would oppose "
            "your grand design.\n"
            "(1)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(2)-[Passive]: While you are in the Superior State, increase your "
            "Wound Rolls and Soak Value by 2(T).\n"
            "(3)-[Automatic]: If you are hit by an Attacking Maneuver, reduce "
            "your Ki Points by 1(bT) for each stack of Over-Maximum you "
            "possess to increase your Soak Value by an equal amount for the "
            "duration of that Attacking Maneuver. If you can't pay the Ki Point "
            "Cost for this effect, this Transformation loses the Armored Aspect "
            "for the duration of that Attacking Maneuver.\n"
            "(4)-[Automatic]: If you use an Attacking Maneuver, reduce your Ki "
            "Points by 1(bT) for each stack of Over-Maximum you possess to "
            "increase your Wound Rolls by an equal amount for the duration of "
            "that Attacking Maneuver. If you can't pay the Ki Point Cost for "
            "this effect, halve the Damage Attribute for that Attacking "
            "Maneuver.\n"
            "(5)-[Automatic, 1/Round]: If you use a Signature Technique, spend "
            "2 stacks of Overwhelm to apply 2 Energy Charges to that Attacking "
            "Maneuver. If you cannot spend 2 stacks of Overwhelm, instead apply "
            "the reduction to your Ki Points from the effects of Draining.\n"
            "(6)-[Automatic/Power, 1/Round]: Spend 2 stacks of Overwhelm to "
            "enter the Superior State until the end of your turn. If you cannot "
            "spend 2 stacks of Overwhelm, instead apply the reduction to your "
            "Ki Points from the effects of Draining.",
      ),
      TransformationTrait(
        name: "Maximum the Overwhelm (Legendary Trait)",
        description: "Your overwhelming power permeates the battlefield, and "
            "you become truly unstoppable.\n"
            "(1)-[Triggered, 1/Round, Resource]: If you would gain a stack of "
            "Overwhelm through the 1st effect of Overwhelming Fighter, gain a "
            "stack of 'Over-Maximum' (max. 2) instead. Each stack of "
            "Over-Maximum increases your Wound Rolls by 1(T) and can be spent "
            "through your effects as if they were 2 stacks of Overwhelm.\n"
            "(2)-[Passive]: Increase the amount of Life and Ki Points regained "
            "from Legend Realized by 2(bT) for each stack of Over-Maximum you "
            "possess.\n"
            "(3)-[Triggered, 1/Encounter]: If you use the Transformation "
            "Maneuver to enter Brilliant Evolution, you may spend 2 stacks of "
            "Overwhelm to enter the Superior State until the end of your next "
            "turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Burning Brilliance",
        description: "You have reined in the massive energy you obtained with "
            "this new evolution, allowing you to reach even greater heights of "
            "power.\n"
            "(1)-[Permanent]: Brilliant Evolution loses the Power High "
            "Aspect.\n"
            "(2)-[Passive]: The 3rd and 4th effects of Shining Evolution "
            "change their [Automatic] Keywords for the [Triggered] Keyword. "
            "Additionally, ignore the portions of the effects that begin with "
            "'If you can't pay the Ki Point Cost for this effect'.\n"
            "(3)-[Passive]: The 5th and 6th effects of Shining Evolution "
            "change their [Automatic] Keywords for the [Triggered] Keyword. "
            "Additionally, ignore the portions of the effects that begin with "
            "'If you cannot spend 2 stacks of Overwhelm'.",
      ),
      TransformationTrait(
        name: "True Brilliance",
        description: "Shining brightly over the battlefield, you radiate "
            "unmatched glory.\n"
            "(1)-[Permanent]: Brilliant Evolution loses the Weakening, "
            "Exhausting, and Draining Aspects and gains the Perfect Ki Control "
            "Aspect.\n"
            "(2)-[Permanent]: You gain access to the True Brilliant Evolution "
            "Evolved Stage for Brilliant Evolution.",
      ),
    ],
  ),

  // ================================== Metamorphosis line (Arcosian Emperor
  // Mutation; Full Suppression Null Stage + Heavy/Partial/True Form Stages 1-3).
  // ========================================= Metamorphosis: Full Suppression (0) ===
  TransformationDef(
    name: "Full Suppression",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 2,
    prerequisiteText: "Metamorphosis line, Null Stage. Emperor Mutation Trait.",
    transformationLine: "Metamorphosis",
    stage: 0,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {},
    traits: [
      TransformationTrait(
        name: "Suppression of Power",
        description: "You've built enough layers around your power that you "
            "can easily control it.\n"
            "(1)-[Addendum]: Please refer to the Metamorphosis Forms text box "
            "below.\n"
            "(2)-[Permanent]: For the sake of entering and remaining in this "
            "Transformation, ignore its Tier of Power Requirement.\n"
            "(3)-[Permanent]: You cannot enter a Transcended Enhancement, "
            "cannot enter another Alternate Form unless it is part of the "
            "Metamorphosis Transformation Line, and cannot leave any "
            "Transformation of this Transformation Line through the Revert "
            "Maneuver (unless you use it to enter a Transformation of this "
            "Transformation Line with 2 levels of the Natural Aspect).\n"
            "(4)-[Passive]: While in the Full Suppression Stage of "
            "Metamorphosis, reduce the Ki Point Cost of your Attacking "
            "Maneuvers and Unique Abilities by 1(T).\n"
            "(5)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain from Legend Realized by 1d6(T).\n"
            "(6)-[Triggered]: If you spend a stack(s) of Overwhelm, regain "
            "2(bT) Life Points for each stack of Overwhelm spent. You cannot "
            "regain more than 8(bT) Life Points during a single Combat Round "
            "with this effect.\n"
            "(7)-[Triggered/Start of Combat Round, 1/Encounter]: You may "
            "immediately take your Turn for this Combat Round, ignoring the "
            "Initiative Order.\n"
            "Metamorphosis is customizable per Stage: choose a Size Category "
            "(Small/Large), your Evolution Traits, the Tail Attack effect, and "
            "the Survivor Option below.",
        optionGroups: kMetamorphosisOptionGroups,
      ),
    ],
  ),

  // ======================================= Metamorphosis: Heavy Suppression (1) ===
  TransformationDef(
    name: "Heavy Suppression",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Emperor Mutation Trait.",
    transformationLine: "Metamorphosis",
    stage: 1,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Draining (LV1)",
      "Power High (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Overwhelming Strike",
        description: "Any worm that dares to raise a hand against you will find "
            "that your brutality and power can pierce even the toughest "
            "hides.\n"
            "(1)-[Passive]: While you are in the Healthy Health Threshold, "
            "increase the Damage Category of all of your Signature Techniques "
            "by 1 Category.\n"
            "(2)-[Passive]: If you are above the Injured Health Threshold, "
            "increase the Wound Rolls of your Signature Techniques by x(T), "
            "where x is equal to their Damage Category.\n"
            "(3)-[Triggered/Transform, 1/Round]: Enter the Superior State until "
            "the start of your next turn.",
        optionGroups: kMetamorphosisOptionGroups,
      ),
      TransformationTrait(
        name: "Overwhelming Mutant",
        description: "As you shed layers of suppression like dead scales, your "
            "peerless power shines brighter, overwhelming any foe.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Power, increase "
            "your Wound Rolls and Soak Value by 1/2 of S(T).\n"
            "(2)-[Triggered/Power]: You may spend 2 stacks of Overwhelm to "
            "gain an additional stack of Power from this use of the Power Up "
            "Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: At the end of your turn, spend all "
            "stacks of Overwhelm to regain 3(bT) Life Points for each stack "
            "spent.\n"
            "(4)-[Triggered, 1/Encounter]: At the end of your turn, do not "
            "trigger the 2nd effect of Overwhelming Fighter.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Overwhelming Transformation",
      description: "Even shedding a single layer of your suppression is enough "
          "to overwhelm most enemies.\n"
          "(1)-[Permanent]: This Transformation loses the Draining and Power "
          "High Aspects and gains the Natural (LV2) Aspect.\n"
          "(2)-[Passive]: Increase the Apparel Bonus of your Plating by 1(T).\n"
          "(3)-[Triggered/Transform, Triggered/Start of Turn]: Gain a stack of "
          "Overwhelm.",
    ),
  ),

  // ===================================== Metamorphosis: Partial Suppression (2) ===
  TransformationDef(
    name: "Partial Suppression",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 3,
    stressTestRequirement: 17,
    prerequisiteText: "Emperor Mutation Trait.",
    transformationLine: "Metamorphosis",
    stage: 2,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Draining (LV1)",
      "Power High (LV1)",
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
        name: "Coup de Grace",
        description: "The way you overpower your prey in combat, many forget "
            "just how quickly you're capable of delivering the final blow.\n"
            "(1)-[Passive]: While you are above the Injured Health Threshold, "
            "increase your Wound Rolls and Speeds by 1(T).\n"
            "(2)-[1/Round]: As an Instant Maneuver, you may spend 2 stacks of "
            "Overwhelm to use the Basic Attack Maneuver as an Out-of-Sequence "
            "Maneuver.\n"
            "(3)-[Triggered/Superior]: Choose a Combat Roll. Until you leave "
            "the Superior State, increase that Combat Roll by 1(T).\n"
            "(4)-[Triggered, 1/Encounter]: If you make an Attacking Maneuver "
            "whose Damage Category would be increased beyond Lethal, that "
            "Attacking Maneuver may also ignore the Damage Reduction for all "
            "target(s) of that Attacking Maneuver.",
        optionGroups: kMetamorphosisOptionGroups,
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mutant's Resilience",
      description: "Because of your overflowing power, you never seem to run "
          "out of stamina.\n"
          "(1)-[Passive]: When you regain Life Points through the 6th effect "
          "of Suppression of Power, regain Ki Points equal to 1/2 of the Life "
          "Points gained.\n"
          "(2)-[1/Round]: As an Instant Maneuver, you may spend 2 stacks of "
          "Overwhelm to gain a Counter Action.\n"
          "(3)-[Triggered, 1/Round]: If you trigger the 3rd effect of the "
          "Emperor Mutation Trait, enter the Superior State until the start of "
          "your next turn.\n"
          "(4)-[Triggered/Power, 1/Round]: If you haven't applied Legend "
          "Realized to a lower Stage of Metamorphosis, you may apply Legend "
          "Realized as if you were entering that Transformation.",
    ),
  ),

  // ============================================= Metamorphosis: True Form (3) ===
  TransformationDef(
    name: "True Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 22,
    prerequisiteText: "Emperor Mutation Trait.",
    transformationLine: "Metamorphosis",
    stage: 3,
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Draining (LV2)",
      "Power High (LV1)",
      "Long Transformation (LV2)",
      "Exhausting",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Unending Pressure",
        description: "Your sheer, overwhelming power enables you to tear "
            "through your prey like tissue paper.\n"
            "(1)-[Passive]: While you are above the Injured Health Threshold, "
            "increase your Strike and Dodge Rolls by 1(T).\n"
            "(2)-[Passive]: While in the Superior State, you are treated as if "
            "you are in the Healthy Health Threshold for all of your "
            "effects.\n"
            "(3)-[Triggered, 1/Round]: If you deal Damage to an Opponent with "
            "an Attacking Maneuver made through the 2nd effect of Coup de "
            "Grace, gain an additional stack of Overwhelm.\n"
            "(4)-[Triggered, 1/Encounter]: If you maximize your stacks of "
            "Overwhelm, enter the Superior State until the start of your next "
            "turn. If you were already in the Superior State, enter the "
            "Surging State instead.",
        optionGroups: kMetamorphosisTrueFormOptionGroups,
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Conquered Mutation",
      description: "You have finally, at long last, mastered the power you "
          "were born with, and this power is now wholly yours to command.\n"
          "(1)-[Permanent]: True Form loses the Long Transformation and "
          "Exhausting Aspects.\n"
          "(2)-[Permanent]: All Stages of Metamorphosis gain the Perfect Ki "
          "Control Aspect.\n"
          "(3)-[Passive]: Ignore the 3rd effect of Suppression of Power.",
    ),
  ),

  // ==================================================== True Brilliant Evolution ===
  TransformationDef(
    name: "True Brilliant Evolution",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Brilliant Evolution). Fully "
        "Mastered Brilliant Evolution. Stress Test Requirement: +5.",
    aspects: ["Draining (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Perfect Evolution",
        description: "You have achieved a level of perfection in your radiance "
            "that is truly without equal.\n"
            "(1)-[Passive]: Increase your Combat Rolls by 1(T) while you "
            "possess at least 1 stack of Over-Maximum.\n"
            "(2)-[Passive]: Double the reduction to your Ki Point Costs from "
            "the Perfect Ki Control Aspect when applied to your Signature "
            "Techniques.\n"
            "(3)-[Triggered/Power, 1/Round]: Gain a stack of Over-Maximum.\n"
            "(4)-[Triggered/Start of Turn, 1/Encounter]: Until the start of "
            "your next turn, you have no limit to your number of Overwhelm or "
            "Over-Maximum stacks.",
      ),
      TransformationTrait(
        name: "Over-the-Over (Legendary Trait)",
        description: "The staggering difference in strength between you and "
            "your enemies leaves even your most hated foes in awe of your "
            "power.\n"
            "(1)-[Passive]: Increase your maximum number of Over-Maximum "
            "stacks by 1.\n"
            "(2)-[Passive]: While in the Superior State, you can possess 1 "
            "stack of Over-Maximum beyond your maximum.",
      ),
    ],
  ),

  // ============================================================ Adaptive Monster ===
  TransformationDef(
    name: "Adaptive Monster",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Unique (Monster Form). Pure Progress "
        "Greater Awakening. Tier of Power Requirement: Same as Original Form. "
        "Stress Test Requirement: +9.",
    aspects: ["Scaling (LV2)", "Pinnacle (LV1)", "Peaked"],
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
        name: "Monster of Progress",
        description: "As the battle drags on, your monstrous shape shifts and "
            "adapts to your opponents, making you a far more terrifying "
            "threat.\n"
            "(1)-[Passive]: Increase the Wound Rolls of your Vile Technique by "
            "1(T) for every 2 stacks of Progress you possess.\n"
            "(2)-[Passive]: Double the bonus from the 2nd effect of Combat "
            "Imprinting.\n"
            "(3)-[Passive]: While in the Flow State, increase the Attribute "
            "Modifier Bonus of the Attribute(s) you selected for the 1st "
            "effect of Monstrous Ascension by 1(T).\n"
            "(4)-[Triggered/Transform]: If you are below the Injured Health "
            "Threshold, gain 2 stacks of Progress.\n"
            "(5)-[Triggered, 1/Encounter]: If you gain a stack of Progress "
            "through the 5th effect of Combat Imprinting, you may use the "
            "Basic Attack Maneuver or Signature Technique Maneuver as an "
            "Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Honed Monster (Legendary Trait)",
        description: "Your monstrous tenacity has been sharpened to the "
            "razor's edge, making you nearly unkillable and unstoppable.\n"
            "(1)-[Passive]: For every 2 stacks of Progress you possess, "
            "increase your Surgency by 1(T).\n"
            "(2)-[Passive]: Increase any Legend Realized triggered while in "
            "Monster Form by 1/4 (rounded up) of your Surgency.\n"
            "(3)-[Triggered/Start of Turn]: If you are in Monster Form and "
            "below the Bruised Health Threshold, gain a stack of Progress.",
      ),
    ],
  ),

  // =============================================================== Monster Form ===
  TransformationDef(
    name: "Monster Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: ["Prelude", "Difficult (LV1)"],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Monstrous Ascension",
        description: "Your transformation into your monstrous persona has many "
            "benefits, allowing your strength to grow in many unexpected "
            "ways.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation: choose an Attribute (AG/TE or FO+MA) and increase "
            "its AMB by 1(T); choose an Aspect (High Speed, Bulky, or Raging) "
            "for this Transformation to gain; choose 2 Saving Throws to gain "
            "Enhanced Save for; choose a Monstrous Trait and a Bestial Trait "
            "to gain access to; choose 0~3 levels of Growth; choose 0~2 levels "
            "of Rampaging.\n"
            "(2)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain through Legend Realized by 1/2 of the Attribute Modifier "
            "for the Attribute you chose through the first effect of Monstrous "
            "Ascension.\n"
            "(3)-[Passive]: For each level of the Rampaging Aspect this "
            "Transformation possesses, increase your Soak Value and Wound "
            "Rolls by 1(T).\n"
            "(4)-[Passive]: Depending on the Aspect you chose, gain one of: "
            "High Speed [Triggered, 1/Round]: if you use an Attacking Maneuver "
            "having moved your full Boosted Speed, increase its Wound Roll by "
            "1/2 of your Boosted Speed; Bulky [Passive]: while up to 2 Super "
            "Stack, increase Strike Rolls by 1(T); Raging [Passive]: gains the "
            "Innate State (Raging) Aspect.",
      ),
      TransformationTrait(
        name: "Violent Monster",
        description: "Your monstrous state leaves you prone to fits of rage, "
            "increasing your strength.\n"
            "(1)-[Permanent, Ruling]: Upon gaining access to this "
            "Transformation, design a Super Signature Technique with a TP Cost "
            "of up to 25. This Signature Technique is known as your 'Vile "
            "Technique'. You only have access to your Vile Technique while you "
            "are in Monster Form and have access to the Violent Monster "
            "Trait.\n"
            "(2)-[Passive]: Increase the Strike Rolls of your Attacking "
            "Maneuvers by 1(T) if all of the target(s) of that Attacking "
            "Maneuver are below a lower Health Threshold than you.\n"
            "(3)-[Passive]: Increase the Wound Rolls of your Attacking "
            "Maneuvers by 1(T) for each Health Threshold the target(s) are "
            "below. If there are multiple targets, this increase to Wound "
            "Rolls is based on the target above the highest Health "
            "Threshold.\n"
            "(4)-[Passive]: Double the bonus to your Wound Rolls for the 3rd "
            "effect of Violent Monster if the Attacking Maneuver is your Vile "
            "Technique.\n"
            "(5)-[Triggered, 1/Round]: If you or an Ally knock an Opponent "
            "through a Health Threshold with an Attacking Maneuver, you may "
            "use the Basic Attack Maneuver as an Out-of-Sequence Maneuver. If "
            "you do, you must target the Opponent knocked through a Health "
            "Threshold with that Attacking Maneuver.\n"
            "(6)-[Triggered, 1/Round]: If you Defeat an Opponent or knock them "
            "through a Health Threshold with an Attacking Maneuver, regain "
            "Life and Ki Points equal to 1/2 of the Attribute Modifier for the "
            "Attribute you chose through the first effect of Monstrous "
            "Ascension.\n"
            "(7)-[Triggered, 1/Encounter]: If you use your Vile Technique, you "
            "may apply the Ascended Signature Advantage to that Attacking "
            "Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Controlled Monster",
        description: "With your mastery of your monstrous form, you have "
            "managed to rein in its vicious nature and take full control of "
            "your mind and body.\n"
            "(1)-[Permanent]: Your level for the Rampaging Aspect is set to "
            "2.\n"
            "(2)-[Permanent]: Monster Form gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Passive]: Ignore the effects of the Rampaging Aspect.\n"
            "(4)-[Passive]: Increase your Combat Rolls by 1(T) while all of "
            "your Opponents are below the Bruised Health Threshold.",
      ),
      TransformationTrait(
        name: "Unstoppable Monster",
        description: "Thanks to your total mastery over your monstrous self, "
            "you've become impossible to defeat.\n"
            "(1)-[Permanent]: Monster Form gains the Armored Aspect.\n"
            "(2)-[Permanent, Passive]: Upon gaining access to this Mastery "
            "Trait, select and gain access to a Monstrous Trait while in this "
            "Transformation.\n"
            "(3)-[Triggered, 1/Encounter]: If you are knocked through a Health "
            "Threshold and succeed at the Steadfast Check, apply Legend "
            "Realized. This use of Legend Realized does not count towards the "
            "amount of uses you gain through the Realization Aspect.",
      ),
    ],
  ),

  // ======================================================= All-Consuming Appetite ===
  TransformationDef(
    name: "All-Consuming Appetite",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    prerequisiteText: "Evolved Stage: Unique (True Genetics). Access to "
        "Transfiguration Beam while in the True Genetics Transformation. Tier "
        "of Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Rampaging (LV2)"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Rampaging Hunger",
        description: "Y\n"
            "(1)-[Assimilated]: If the Original Form is Mastered: reduce the "
            "level of the Rampaging Aspect of this Transformation by 1 Level; "
            "you are not required to Ki Wager through the effects of the "
            "Compelled Combat Condition; the Compelled Combat Condition does "
            "not count as a Combat Condition you are suffering from for the "
            "effects of your Opponents; you may ignore the 2nd effect of "
            "Rampaging Hunger; the 4th effect loses [Automatic/Start of Turn] "
            "and gains [Triggered/Start of Turn] (rolls stop being Urgent); "
            "this Evolved Stage gains M levels of the Natural Aspect.\n"
            "(2)-[Permanent]: If you would enter the True Genetics "
            "Transformation, you must instead enter this Evolved Stage.\n"
            "(3)-[Passive]: Gain access to the Insatiable Awakening as a Level "
            "2 Temporary Awakening while in this Transformation.\n"
            "(4)-[Automatic/Start of Turn]: Make an Urgent Clash (Morale) "
            "against yourself (roll 2 times and compare the results). If the "
            "1st result exceeds the 2nd, then you ignore the effects of the "
            "Rampaging Aspect until the start of your next turn. This effect "
            "does not trigger if you are using this Transformation in "
            "conjunction with another Transformation that possesses the "
            "Rampaging Aspect.\n"
            "(5)-[Passive]: While suffering from the Compelled Combat "
            "Condition, increase your Strike and Wound Rolls by 1(T).\n"
            "(6)-[Passive]: While suffering from the Compelled Combat "
            "Condition, reduce your Dodge Rolls and Soak Value by 1(T).\n"
            "(7)-[1/Round]: If you are suffering from the Compelled Combat "
            "Condition, you may spend 2 stacks of Genetic Tasting to use the "
            "Transfiguration Maneuver as an Instant Maneuver.\n"
            "(8)-[Triggered/Power, 1/Round]: If you are not suffering from the "
            "Compelled Combat Condition, you may spend a stack of Genetic "
            "Tasting to treat yourself as if you're suffering from the "
            "Compelled Combat Condition for the effects of Rampaging Hunger "
            "until the start of your next turn.\n"
            "(9)-[Permanent, Multi-Option/2]: Select 2 of the following:",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Rampage Design',
            maxChoices: 2,
            options: [
              TraitOption(
                name: 'Combat Hunger (Combat Blueprint)',
                description: '[Passive]: While you are not suffering from the '
                    'Compelled Combat Condition, increase the amount of Life '
                    'and Ki Points regained through the 1st effect of Combat '
                    'Blueprint by 1(bT) for each Power stack spent. While you '
                    'are suffering from the Compelled Combat Condition and '
                    'have 1+ stacks of Power, increase your Wound Rolls by '
                    '1(T).',
              ),
              TraitOption(
                name: 'Offensive Rampage (Offensive Design)',
                description: '[Passive]: While suffering from the Compelled '
                    'Combat Condition, reduce the Critical Target of your '
                    'Strike and Wound Rolls by 1.',
              ),
              TraitOption(
                name: 'Defensive Rampage (Defensive Design)',
                description: '[Passive]: Ignore the reduction to your Dodge '
                    'Rolls through the 6th effect of Rampaging Hunger and, '
                    'while suffering from the Compelled Combat Condition, '
                    'reduce the Critical Target of your Dodge Rolls by 1.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ================================== Awoken Genetics line (Bio-Android; "So-
  // Called Normal Form" Null Stage + True Genetics Stage 1).
  // ================================ Awoken Genetics: Suppressed Genetics (0) ===
  TransformationDef(
    name: "Suppressed Genetics",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: "Awoken Genetics line, Null Stage. Access to 2+ of "
        "Combat Blueprint, Offensive Design, Defensive Design.",
    transformationLine: "Awoken Genetics",
    stage: 0,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "So-Called Normal Form",
        description: "T\n"
            "(1)-[Passive]: Increase your maximum number of Adaptation Points "
            "by 1.\n"
            "(2)-[Triggered]: If you spend 2+ Adaptation Points on a Combat "
            "Roll, increase the Combat Roll by 1(T).\n"
            "(3)-[Triggered/Threshold, 1/Encounter]: Spend 3 Adaptation "
            "Points. You may automatically succeed at the Steadfast Check for "
            "this Health Threshold, regain Life Points equal to 1/10th of your "
            "Maximum Life Points, then you may use the Transformation Maneuver "
            "as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ===================================== Awoken Genetics: True Genetics (1) ===
  TransformationDef(
    name: "True Genetics",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Access to 2+ of Combat Blueprint, Offensive Design, "
        "Defensive Design.",
    transformationLine: "Awoken Genetics",
    stage: 1,
    aspects: [
      "Enhanced Save (Morale)",
      "Prelude",
      "Difficult (LV1)",
      "Power High (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Unleashed Genetics",
        description: "T\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select 2 Factor Traits from the Genetic Splicing "
            "Factor. You gain access to those Factor Traits while in this "
            "Transformation. Any choices made are retained between uses.\n"
            "(2)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, if you have the Bio-Focus Factor, you may select "
            "a different Factor Trait (that you meet the Prerequisite for) for "
            "Bio-Focus. If you do, you exchange it while in this "
            "Transformation.\n"
            "(3)-[Permanent, Passive]: Upon gaining access to True Genetics, "
            "choose a Saving Throw. True Genetics gains the Enhanced Save "
            "Aspect for that chosen Saving Throw.\n"
            "(4)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select a Bestial Trait. You gain access to that "
            "Bestial Trait while in this Transformation.",
      ),
      TransformationTrait(
        name: "Genetic Gathering",
        description: "T\n"
            "(1)-[Passive]: You gain access to the Connoisseur Cut Modifier "
            "Maneuver (1/Round; 2(bT); applies an Energy Charge + Piercing, "
            "and lets you copy a target's Signature/Unique Ability — see the "
            "site).\n"
            "(2)-[Triggered, 1/Round, Resource]: If you deal Damage to an "
            "Opponent with an Attacking Maneuver that applies the Connoisseur "
            "Cut Modifier Maneuver, you may gain a stack of Genetic Tasting "
            "(max 3).\n"
            "(3)-[Passive]: During a Combat Round in which you have gained a "
            "stack of Genetic Tasting, increase your Combat Rolls by 1(T).\n"
            "(4)-[1/Round]: As an Instant Maneuver, you may spend any number "
            "of Genetic Tasting stacks to gain an equal number of Adaptation "
            "Points.\n"
            "(5)-[1/Round]: You may spend 2 stacks of Genetic Tasting to use "
            "the Energy Charge Maneuver as an Instant Maneuver.\n"
            "(6)-[Triggered, 1/Round]: If you use a Signature Technique that "
            "has 3+ Energy Charges applied to it, after rolling the Strike "
            "Roll for that Attacking Maneuver, gain 2 Adaptation Points. Then, "
            "if that Attacking Maneuver hits an Opponent, you must spend 2+ "
            "Adaptation Points on the Wound Roll through the 1st effect of "
            "Artificial Warrior.\n"
            "(7)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver, "
            "you may spend an Adaptation Point to apply the Connoisseur Cut "
            "Modifier Maneuver without paying the Action Cost.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Hors d'Oeuvre",
        description: "T\n"
            "(1)-[Permanent]: True Genetics loses the Power High Aspect, and "
            "gains M levels of the Natural Aspect.\n"
            "(2)-[Permanent]: True Genetics gains the Realization Aspect and "
            "M levels of the Scaling Aspect.\n"
            "(3)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(4)-[Triggered, 1/Round]: If you select a Signature Technique or "
            "a Unique Ability through the effects of Connoisseur Cut, you can "
            "choose not to gain your selection to instead gain an Adaptation "
            "Point and regain Ki Points equal to your Surgency.",
      ),
      TransformationTrait(
        name: "Main Course of Genetics",
        description: "T\n"
            "(1)-[Passive]: During a Combat Round in which you have gained a "
            "stack of Genetic Tasting, increase your Soak Value by 1(T).\n"
            "(2)-[Passive]: Increase the Strike Rolls of your Attacking "
            "Maneuvers that have the Connoisseur Cut Modifier Maneuver applied "
            "to them by 1(T).\n"
            "(3)-[Triggered/Power, 1/Encounter]: Lose access to a Signature "
            "Technique or Unique Ability gained through Connoisseur Cut, then "
            "maximize your Adaptation Points. You may then use the Signature "
            "Technique Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // =========================================================== Super Perfect Form ===
  TransformationDef(
    name: "Super Perfect Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Bio Android",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Fully Mastered Genetic Power, 2 stacks of Perfection.",
    aspects: [
      "Enhanced Save (All)",
      "High Speed (LV3)",
      "Draining (LV2)",
      "Power High (LV2)",
      "Difficult (LV2)",
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
        name: "Super Genetic Transformation",
        description: "You have reached a power beyond power itself, becoming "
            "the most perfect amalgamation of your many disparate parts.\n"
            "-[Permanent]: This Transformation is also considered to be "
            "Genetic Power for all of your effects.\n"
            "-[Passive]: This Transformation gains the Genetic Traits you "
            "selected for the first effect of Genetic Transformation.\n"
            "-[Passive]: For each stack of Power you possess, increase the "
            "Tier of Power Extra Dice for your Combat Rolls by 1 Dice "
            "Category.\n"
            "-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select and gain a Super Genetic Trait while in "
            "this Transformation (must match a Race listed among your Genetic "
            "Traits).\n"
            "-[Permanent, Passive]: Choose up to 2 of the following Aspects "
            "for this Transformation to gain: Growth, Raging (not with "
            "Mindful), Mindful (not with Raging), Bulky.\n"
            "-[Ruling]: Aspects gained this way are 'Chosen Aspects'; a "
            "duplicate from a Genetic/Super Genetic Trait is a 'Repeated "
            "Aspect'.\n"
            "-[Triggered/Start of Combat Round]: Regain 2(bT) Life and Ki "
            "Points for every Repeated Aspect you possess.\n"
            "-[Passive]: If you are in the God Ki Special State, halve the "
            "amount of Divine Ki Points you would lose through the Draining "
            "Aspect.\n"
            "Select your Super Genetic Trait(s) below (Race-keyed).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Super Genetic Trait',
            maxChoices: 3,
            options: [
              TraitOption(
                name: 'Release Limiters (Android)',
                description: 'You have surpassed the need for power limiters. '
                    '-[Passive]: Increase the amount of Ki Points you regain '
                    'through the third effect of Power Core by 2(bT). '
                    '-[Permanent, Passive]: Select and gain one of: Hyper Mega '
                    'Bio-Droid [Permanent, Passive]: This Transformation gains '
                    'the Armored Aspect and you may make a Weapon with 3 '
                    'Qualities and a Special Weapon Quality (Integrated while '
                    'in this Transformation). Ultimate Bio-Droid [Passive]: '
                    'This Transformation gains the Perfect Ki Control Aspect '
                    'and you increase the Dice Category of all your Energy '
                    'Charges by 1 Dice Category.',
              ),
              TraitOption(
                name: 'Brilliant Shell (Arcosian)',
                description: 'Your radiant gleam displays your magnificent '
                    'superiority. -[Passive]: Increase your Damage Reduction '
                    'by 1(T). -[Trigger/Transform]: Increase the amount of Ki '
                    'Points you regain through the effects of Legend Realized '
                    'by 1d10(bT). -[Triggered, 2/Round]: If you hit an Opponent '
                    'with an Attacking Maneuver, increase your Wound Rolls by '
                    '2(T) until the end of your turn.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.damageReduction],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Crimson Awakening (Cerealian)',
                description: 'Your other eye awakens. -[Passive]: Increase the '
                    'Dice Category of the Extra Dice gained through scoring a '
                    'Critical Result by 2 Dice Categories. -[Passive]: If you '
                    'score a Critical Result on the Strike or Wound Roll for '
                    'an Attacking Maneuver, increase the Wound Roll by 2(T). '
                    '-[Triggered, 1/Round]: If you would use the Called Shot '
                    'Maneuver, at Attack Declaration you may declare either the '
                    'Strike or Wound Roll; you automatically score a Critical '
                    'Result on your declared Combat Roll regardless of the '
                    'Natural Result for that Attacking Maneuver.',
              ),
              TraitOption(
                name: "If You Don't, Who Will? (Custom Species)",
                description: 'Your unique anatomy awakens an inner strength. '
                    '-[Passive]: While you are below the Bruised Health '
                    'Threshold, apply your Tier of Power Extra Dice an '
                    'additional time. -[Triggered, 1/Round]: If you hit an '
                    'Opponent with an Attacking Maneuver that has a Ki Wager '
                    'equal to 1/4 or more of your Max Capacity, increase the '
                    'Damage Category by 1. -[Permanent, Option]: Select one '
                    'of: Genetic Potential [Passive]: You cannot lose stacks '
                    'of Power while in this Transformation (you may choose to '
                    'lose any number as an Instant Maneuver). Superior Genetics '
                    '[Triggered/Transform, Start of Turn]: Select a Combat '
                    'Roll; apply your Tier of Power Extra Dice an additional '
                    'time to it until the start of your next turn. Godly Genes '
                    '[Permanent, Passive]: This Transformation gains the God Ki '
                    'Aspect and you may select a God Maneuver to have access '
                    'to. Super Powerful Genes [Passive]: For each stack of '
                    'Power you possess, increase your Might and Wound Rolls by '
                    '1(T) and increase your Tier of Power Extra Dice by 1 Dice '
                    'Category.',
              ),
              TraitOption(
                name: 'Genetic Zone (Earthling)',
                description: 'You feel the flow of the world around you. '
                    '-[Passive]: Reduce the Ki Point Cost of all Attacking '
                    'Maneuvers by 2(T) (this can go below their typical '
                    'minimums). -[Triggered/Transform]: Enter the Mindful '
                    'State until you leave this Transformation. -[1/Encounter]: '
                    'Leave the Mindful State as an Instant Maneuver; if you do, '
                    'enter the Surging State until the end of your next turn '
                    '(no Fatigued stacks afterwards, and you re-enter the '
                    'Mindful State).',
              ),
              TraitOption(
                name: 'Chaotic Genes (Majin)',
                description: 'Chaos incarnate flows through you. '
                    '-[Triggered/Start of Combat Round]: Roll the Chaos Dice '
                    'and gain its effects. -[Triggered]: If you roll a 6 on '
                    'the Chaos Dice, regain 1d8(T) Life and Ki Points. '
                    '-[Triggered, 1/Encounter]: If you roll a 6 on the Chaos '
                    'Dice, roll the Chaos Dice.',
              ),
              TraitOption(
                name: 'Orange Hide (Namekian)',
                description: 'The mark of the Ajisa Tree empowers you. '
                    '-[Passive]: Increase your Soak Value by 1(T); for every '
                    'stack of Power you possess, increase your Soak Value by '
                    'an additional 1(T). -[Passive]: While you are above the '
                    'Injured Health Threshold, increase your Tier of Power '
                    'Extra Dice by 2 Dice Categories. -[Triggered/Defeated]: '
                    'Enter the Undying State for 2 Combat Rounds.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Genetic Grudge (Neo-Tuffle)',
                description: 'Your drive for vengeance awakens a deep rage. '
                    '-[Passive]: For every 2 Energy Charges applied to one of '
                    'your Attacking Maneuvers, increase the Extra Dice gained '
                    'from the Raging State by 1 Dice Category for the duration '
                    'of that Attacking Maneuver (max. +4). -[Triggered/'
                    'Transform]: Enter the Raging State until you leave this '
                    'Transformation. -[Triggered, 1/Encounter]: If you hit an '
                    'Opponent with an Attacking Maneuver, you may add 2 Energy '
                    'Charges to that Attacking Maneuver.',
              ),
              TraitOption(
                name: 'Gleaming Legend (Saiyan)',
                description: 'The golden power that courses through you has '
                    'achieved a new peak. -[Passive]: Increase your Maximum Ki '
                    'Points and Max Capacity by 1/4. -[Permanent, Passive]: '
                    'Select one of: Legendary Bio-Droid [Triggered/Start of '
                    'Combat Round, 4/Encounter]: Regain 1/5 of your Maximum Ki '
                    'Points and lose 1/10th of your Maximum Life Points; '
                    'increase your Wound Rolls by 1(T) until you leave this '
                    'Transformation. Primal Bio-Droid [1/Encounter]: Regain '
                    '2d8(T) Life and Ki Points as an Instant Maneuver; if you '
                    'do, increase your Combat Rolls by 1(T) until you leave '
                    'this Transformation. Divine Bio-Droid [Passive]: This '
                    'Transformation gains the God Ki Aspect and you increase '
                    'your Strike and Dodge Rolls by 1(T).',
              ),
              TraitOption(
                name: 'Karmic Perfection (Shadow Dragon)',
                description: 'You are able to turn the tables of reality '
                    'against those who oppose you. -[Triggered, 1/Round]: If a '
                    'Character would score a Botch Result within a Huge Sphere '
                    'AoE (centered on you), you may use the Basic Attack or '
                    'Signature Technique Maneuver against them or another '
                    'Character within their Melee Range as an Out-of-Sequence '
                    'Maneuver. -[Triggered, 1/Round]: If you have 2+ stacks of '
                    'Power when an Opponent within a Huge Sphere AoE (centered '
                    'on you) rolls a Combat Roll, you may spend 3(bT) Ki Points '
                    'to make them score a Botch Result regardless of their '
                    'Natural Result.',
              ),
              TraitOption(
                name: 'Genetic God (Shinjin)',
                description: 'Your divine nature awakens. -[Passive]: This '
                    'Transformation gains the God Ki Aspect. -[Passive]: '
                    'Increase your Wound Rolls by 2(T) against Opponents who '
                    'are suffering from a Combat Condition. -[Permanent, '
                    'Passive]: Select one of: Demonic Cells [1/Round]: As an '
                    'Instant Maneuver, spend 3(bT) Divine Ki Points to target '
                    'an Opponent and make a Clash (Cognitive); if you win, '
                    'they suffer Guard Down until the end of your turn (only '
                    'if you chose Bio-Malice for Cosmic Energy). Divine Cells '
                    '[1/Round]: As an Instant Maneuver, spend 3(bT) Divine Ki '
                    'Points to target an Opponent and make a Clash (Cognitive); '
                    'if you win, they suffer Impediment until the end of their '
                    'turn (only if you chose Bio-Radiance for Cosmic Energy).',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Perfect Power (Legendary Trait)",
        description: "Your might is beyond compare, allowing you to gather "
            "energy quickly and efficiently.\n"
            "-[1/Round]: You may spend 2 Perfect Points to use the Power Up "
            "Maneuver or Energy Charge Maneuver as an Instant Maneuver.",
      ),
      TransformationTrait(
        name: "You May Not Like It, But This is What Peak Perfection Looks "
            "Like (Exceed Trait)",
        description: "You have drawn out the maximum power of your combined "
            "genetics, allowing you to become the zenith of all creation.\n"
            "-[Passive]: Double the bonus from the second effect of Perfected "
            "Being.\n"
            "-[Permanent, Passive]: Upon gaining access to this Exceed Trait, "
            "select a Super Genetic Trait (must match a Race among your "
            "Genetic Traits). You gain its effects while in the Exceed State.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Far Beyond Perfection",
      description: "You have surpassed even the state in which you surpassed "
          "perfection itself, awakening deeper power within yourself.\n"
          "-[Permanent]: This Transformation loses the Power High Aspect and "
          "gains the Strainless and Scaling (LV2) Aspects.\n"
          "-[Permanent]: This Transformation loses the Draining Aspect.\n"
          "-[Permanent, Passive]: Upon gaining this Mastery, select an "
          "additional Super Genetic Trait that matches a Race among your "
          "Genetic Traits. You gain its effects while in this Transformation.",
    ),
  ),

  // ============================================================= United Android ===
  TransformationDef(
    name: "United Android",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Android",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "1+ stacks of Unified, Android Fusion Talent.",
    aspects: [
      "Enhanced Save (Corporeal/Cognitive)",
      "Growth (LV1)",
      "Armored",
      "Bulky",
      "Rampaging (LV1)",
      "Power High (LV2)",
      "Difficult (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Reinforced Frame",
        description: "Your body is made more durable by the absorbed parts of "
            "your fellow Androids.\n"
            "(1)-[Constant]: If you gain a stack of the Unified Awakening, you "
            "may use the Transformation Maneuver as an Out-of-Sequence "
            "Maneuver to enter United Android.\n"
            "(2)-[Ruling]: For the effects of United Android, 'Z' refers to "
            "your number of Unified stacks.\n"
            "(3)-[Passive]: Increase your Soak Value by Z(T).\n"
            "(4)-[Passive]: Opponents' effects cannot trigger in response to "
            "you being knocked through the Bruised Health Threshold.\n"
            "(5)-[Triggered]: If you are hit by an Attacking Maneuver, you may "
            "spend up to Z(bT) Ki Points to reduce the amount of Damage you "
            "suffer by an equal amount.\n"
            "(6)-[1/Encounter]: Use a Ki Surge as an Instant Maneuver. You may "
            "use this effect ignoring the effects of Power Battery.",
      ),
      TransformationTrait(
        name: "Murder Machine",
        description: "Your onboard computer is sped up to provide optimal "
            "targeting assistance and combat advice to ensure you deal the "
            "most damage possible to your target.\n"
            "(1)-[Passive]: Increase your Strike Rolls by 1/2 of Z(T) and your "
            "Wound Rolls by Z(T).\n"
            "(2)-[Passive]: While you are in the Surging State, increase the "
            "Dice Category of your Energy Charges by 1 Category.\n"
            "(3)-[Triggered]: If you hit an Opponent with an Attacking "
            "Maneuver, you may spend up to Z(bT) Ki Points to increase the "
            "Wound Roll of that Attacking Maneuver by an equal amount.\n"
            "(4)-[Triggered, 1/Encounter]: If you use a Ki Surge during your "
            "turn, enter the Surging State until the end of your turn.",
      ),
      TransformationTrait(
        name: "Android Perfection (Legendary Trait)",
        description: "Unlocked via the United Power Special State (3rd Mastery "
            "makes United Android a Legendary Form). Your combined state, "
            "utilizing the best features of your fallen fellows, is far "
            "stronger and faster than any of you were before.\n"
            "(1)-[Passive]: Increase Z for the effects of United Android and "
            "Unified by 1.\n"
            "(2)-[Passive]: Increase your Might by 1(T).\n"
            "(3)-[Triggered, 1/Round]: At the start of an Opponent's turn who "
            "is not at Long Range, you may make a Might Clash against an "
            "Opponent. If you win, they gain the Compelled Combat Condition "
            "with you as the target.\n"
            "(4)-[Triggered/Power, 1/Round]: Enter the Surging State until the "
            "end of your turn.\n"
            "(5)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique, you may apply either the All Out or Complete "
            "Annihilation Super Profile to that Attacking Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Stabilized Unification",
        description: "You have grown fully accustomed to the power gained from "
            "combining with your compatriots, allowing you access to all of "
            "that strength with none of the flaws.\n"
            "(1)-[Permanent]: United Android loses the Rampaging Aspect and M "
            "levels of Power High.\n"
            "(2)-[Permanent]: United Android gains the Realization Aspect and "
            "M levels of the Scaling Aspect (max. 2).\n"
            "(3)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n"
            "(4)-[Passive]: Ignore the 2nd effect of the Surging State if you "
            "entered it through the 4th effect of Murder Machine.",
      ),
      TransformationTrait(
        name: "Advanced Unification",
        description: "The parts you've absorbed from other Androids make you "
            "more durable and grant you enhanced stamina.\n"
            "(1)-[Permanent]: You cannot master United Android for the 3rd "
            "time unless your base Tier of Power is 4+.\n"
            "(2)-[Passive]: Opponents' effects cannot trigger in response to "
            "you being knocked through the Injured Health Threshold.\n"
            "(3)-[Passive]: The 4th effect of Murder Machine loses the "
            "[1/Encounter] Keyword and gains the [M/Encounter] Keyword.",
      ),
      TransformationTrait(
        name: "Mighty Merger",
        description: "The full power of those you've absorbed finally awakens, "
            "allowing you to unleash a force greater than even the sum of your "
            "combined output as individuals.\n"
            "(1)-[1/Round]: As a Standard Maneuver, you may spend 1 Action to "
            "enter the United Power Special State.\n"
            "(2)-[Constant]: If you use the Transformation Maneuver to enter "
            "United Android, you may increase its Stress Test Requirement by 9 "
            "for the duration of that Transformation Maneuver. If you succeed "
            "at the Stress Test and successfully enter the Transformation, you "
            "may enter the United Power Special State.\n"
            "United Power Special State — (1)-[Passive]: While in this State, "
            "United Android becomes a Legendary Form. (2)-[Passive]: Increase "
            "the Stress Test Requirement of this Transformation by 9 and its "
            "Attribute Modifier Bonus (AG/FO/TE/IN/MA) by 1(T). (3)-[Passive]: "
            "United Android gains 2 levels of the Scaling Aspect.",
      ),
    ],
  ),

  // ============================================================ Ultimate Android ===
  TransformationDef(
    name: "Ultimate Android",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Android",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Super Android, Energy Core Racial Trait.",
    aspects: [
      "Enhanced Save (All)",
      "Innate State (Superior)",
      "Natural (LV1)",
      "Difficult (LV1)",
      "Power High (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Superior Android",
        description: "You have become the ultimate cybernetic life form.\n"
            "(1)-[Passive]: While you are at the Healthy Health Threshold, "
            "increase your Combat Rolls and Damage Reduction by 1(T).\n"
            "(2)-[Passive]: While you are at the Healthy Health Threshold, "
            "increase the Dice Category of your Greater Dice by 1 Dice "
            "Category.\n"
            "(3)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Surgency by 4(T).\n"
            "(4)-[Triggered, 1/Round]: If you use a Ki Surge, regain Life "
            "Points equal to 1/2 of your Surgency.\n"
            "(5)-[Triggered/Transform, 1/Encounter]: Regain Life Points equal "
            "to 1/4 of your Maximum Life Points.",
      ),
      TransformationTrait(
        name: "Superior Charge",
        description: "The superior power coursing through you was created "
            "specifically to drive your strength to greater heights.\n"
            "(1)-[Passive]: The Energy Charge Maneuver does not cost Ki "
            "Points.\n"
            "(2)-[Passive]: The 7th effect of Super Weapon loses the "
            "[1/Encounter] Keyword and gains the [1/Round] Keyword.\n"
            "(3)-[Passive]: Apply your Greater Dice an additional time to the "
            "Wound Rolls of your Signature Techniques that have at least 3+ "
            "Energy Charges.\n"
            "(4)-[Triggered, 1/Round]: If you Defeat an Opponent or knock them "
            "through a Health Threshold with an Attacking Maneuver, gain 2 "
            "stacks of Reserved Energy.\n"
            "(5)-[Triggered/Start of Turn]: Gain a stack of Reserved Energy.\n"
            "(6)-[Triggered, 1/Encounter]: If you would spend Reserved Energy "
            "through an effect, instead of spending Reserved Energy, you may "
            "spend up to 12(bT) Ki Points. Every 2(bT) Ki Points spent counts "
            "as 1 Reserved Energy for that effect.",
      ),
      TransformationTrait(
        name: "Pinnacle of Technology (Legendary Trait)",
        description: "You sit at the apex of the technological hierarchy, "
            "possessing the most advanced technology in the universe.\n"
            "(1)-[Passive]: Upon gaining access to this Legendary Trait, "
            "select and gain access to an additional effect from the 3rd "
            "effect of Technological Being.\n"
            "(2)-[Passive]: You gain access to the option you didn't choose "
            "for the 4th effect of Energy Core. You may still regain Ki Points "
            "through Ki Surges, ignoring the effects of Power Battery.\n"
            "(3)-[Passive]: While you are in the Superior State, increase the "
            "Skill Bonus of your Perception and Clairvoyance Skills by 1.\n"
            "(4)-[Passive]: While you are in the Superior State, increase your "
            "Strike and Dodge Rolls by 1(T).\n"
            "(5)-[Passive]: You gain access to the Drain Field Special "
            "Maneuver (Counter; nullify an Energy/Magic Attack's Damage at the "
            "cost of your defenses, then Ki Surge + 3 Reserved Energy) — see "
            "the site.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Strongest Android",
        description: "The pinnacle of man-made creation, you were designed to "
            "be the best, and you have finally achieved that state.\n"
            "(1)-[Permanent]: Ultimate Android loses the Power High Aspect and "
            "gains M levels of the Scaling Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Reserved Energy "
            "stacks by M.\n"
            "(3)-[Passive]: The 6th effect of Superior Charge increases the "
            "amount of Ki Points you can spend by 2M(bT).\n"
            "(4)-[Passive]: Ignore the 2nd effect of the Superior State.",
      ),
      TransformationTrait(
        name: "Nobody Can Beat Me!",
        description: "When you're in this form, you're so strong that nobody "
            "can defeat you.\n"
            "(1)-[Permanent]: Ultimate Android gains the Perfect Ki Control "
            "Aspect and an additional level of the Natural Aspect.\n"
            "(2)-[Passive]: Double the bonuses from the 1st effect of Superior "
            "Android.\n"
            "(3)-[1/Round]: If you spend 3+ stacks of Reserved Energy, you may "
            "use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ================================================================ Liquid Metal ===
  TransformationDef(
    name: "Liquid Metal",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Android",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Machine Mutant Factor.",
    aspects: [
      "Enhanced Save (Corporeal/Impulsive)",
      "Growth (LV2)",
      "Absorbed Apparel",
      "Bulky",
      "Draining (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Body of Metal",
        description: "You are made of a liquid, organic metal, enabling you "
            "to mold yourself as you see fit and move through any metal "
            "objects.\n"
            "(1)-[Passive]: The Elemental (Metal) Profile becomes a Favored "
            "Element.\n"
            "(2)-[Passive]: Double the bonuses from the 2nd effect of Metal "
            "Takeover.\n"
            "(3)-[Passive]: While you are occupying a Square with the Metallic "
            "Environmental Quality, increase your Soak Value, Might, and "
            "Surgency by 1(T), 1(T), and 2(T) respectively.\n"
            "(4)-[Passive]: Gain access to the Metal Shield and Metal Wave "
            "Special Maneuvers (detailed below).\n"
            "(5)-[Passive]: If you would use the 4th effect of Mutant Core, "
            "you may destroy a Feature with the Metallic Feature Quality "
            "instead of one of your Integrated Items.\n"
            "(6)-[Passive]: You gain access to the Liquid Form Maneuver.\n"
            "(7)-[1/Round]: As an Instant Maneuver, you may move any number of "
            "Features with the Metallic Feature Qualities by a number of "
            "Squares up to 1/2 of your Force or Magic Score (whichever is "
            "higher). You cannot cause Collision with this movement.\n"
            "\n"
            "Metal Shield Special Maneuver — Maneuver Type: Counter; Action "
            "Cost: 1 Counter Action. Effect: If you or an Ally are targeted by "
            "an Attacking Maneuver, you may destroy a Feature with the "
            "Metallic Feature Quality or remove the Metallic Environmental "
            "Quality from 6 Squares to use this Maneuver. Increase the Damage "
            "Reduction of the target(s) of that Attacking Maneuver by your "
            "Might (this increase ignores all effects that would remove all "
            "Damage Reduction).\n"
            "Metal Wave Special Maneuver [1/Encounter] — Maneuver Type: "
            "Instant; KP Cost: 12(T). Effect: Target an Opponent that has at "
            "least 4 Features with the Metallic Feature Quality on adjacent "
            "Squares to them. Make a Clash (Corporeal) against that Opponent; "
            "if you win, they gain 2 stacks of the Slowed Combat Condition "
            "until the end of their turn. Then, you may make a Might Clash "
            "against that Opponent; if you win, they gain an additional stack "
            "of the Slowed Combat Condition.",
      ),
      TransformationTrait(
        name: "Planet of Metal",
        description: "You become one with the metal that surrounds you, "
            "allowing you to fuse with the very ground under your feet.\n"
            "(1)-[Passive]: All Characters occupying a Square with the "
            "Metallic Environmental Quality are considered to be in your Melee "
            "Range.\n"
            "(2)-[Passive]: If an Opponent leaves a Square with the Metallic "
            "Environmental Quality, this triggers your Exploit Maneuver.\n"
            "(3)-[Passive]: If an Opponent is occupying a Square with the "
            "Metallic Environmental Quality, reduce their Combat Rolls by "
            "1(T).\n"
            "(4)-[1/Round]: As an Instant Maneuver during your turn, if you "
            "are occupying a Square with the Metallic Environmental Quality, "
            "you may move to any other Square with the Metallic Environmental "
            "Quality on the Battlefield.\n"
            "(5)-[Triggered]: If a Feature is occupying a Square that gains "
            "the Metallic Environmental Quality through the effects of Liquid "
            "Metal, that Feature gains the Metallic Feature Quality.\n"
            "(6)-[1/Encounter]: As an Instant Maneuver, use the Metal Breath "
            "Special Maneuver as if you spent 2 Actions.\n"
            "(7)-[Triggered/Transform]: All Squares within a Destructive "
            "Sphere AoE (centered on you) gain the Metallic Environmental "
            "Quality.\n"
            "(8)-[Triggered/Start of Turn]: If you are occupying a Square that "
            "does not possess the Metallic Environmental Quality, it gains the "
            "Metallic Environmental Quality.\n"
            "(9)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you "
            "may remove the Metallic Environmental Quality from all Squares "
            "within a Minor Sphere AoE (centered on you). For every 4 Squares "
            "that you removed the Metallic Environmental Quality from, apply "
            "an Energy Charge to that Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Metal Takeover (Legendary Trait)",
        description: "You can turn the world around you into a paradise made "
            "of pure metal.\n"
            "(1)-[Passive]: Gain access to the Metal Breath Special Maneuver — "
            "Metal Breath [1/Round]; Maneuver Type: Standard; Action Cost: "
            "Variable (1~3 Actions); KP Cost: 3(T) for each Action spent. "
            "Effect: For each Action spent, target a Square or Character within "
            "your Melee Range (you may target the same target multiple times). "
            "Square: All Squares and Features within a Sphere AoE (centered on "
            "that Square) gain the Metallic Environmental Quality or Metallic "
            "Feature Qualities respectively; for each time that Square was "
            "targeted after the first, increase the Magnitude of that AoE by "
            "1. Character: Make a Clash (Corporeal vs Any Saving Throw); if "
            "you win, they gain a stack of Slowed for each time they were "
            "targeted until the start of your next turn.\n"
            "(2)-[Passive]: While you are occupying a Square with the Metallic "
            "Environmental Quality, increase your Combat Rolls and Damage "
            "Reduction by 1(T).\n"
            "(3)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 "
            "Action, remove the Metallic Environmental Quality from all "
            "Squares within a Minor Sphere AoE (centered on you). If you "
            "removed the Metallic Environmental Quality from 5+ Squares, you "
            "may use a Healing Surge as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Metal Dominion",
      description: "You have truly mastered the art of controlling metal, "
          "making it easier for you to maintain this power.\n"
          "(1)-[Permanent]: Liquid Metal loses the Draining Aspect and gains "
          "the Scaling (LV2) Aspect.\n"
          "(2)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n"
          "(3)-[Passive]: While you are occupying a Square with the Metallic "
          "Environmental Quality, increase your Soak Value and Surgency by "
          "1(T).\n"
          "(4)-[Triggered/Start of Turn]: If you cannot trigger the 8th "
          "effect of Planet of Metal because you are already occupying a "
          "Square that possesses the Metallic Environmental Quality, regain "
          "3(bT) Life and Ki Points.",
    ),
  ),

  // ============================================================= Hyper Mega Form ===
  TransformationDef(
    name: "Hyper Mega Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Android",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    aspects: ["Enhanced Save (Corporeal/Impulsive)", "Armored"],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Mechanical Combination",
        description: "You have designated teammates that you can combine with "
            "at will, and separate from just as easily.\n"
            "(1)-[Permanent]: You cannot enter this Transformation except "
            "through the 3rd effect of Support Units.\n"
            "(2)-[Automatic]: If you leave this Transformation, lose all of "
            "your Unified stacks gained through the 3rd effect of Support "
            "Units.\n"
            "(3)-[Passive]: All the Integrated Items possessed by your "
            "Supports (that are Merged Characters) are also Integrated by you. "
            "If one of these Integrated Items is destroyed for any reason, "
            "it's also destroyed for that Support.\n"
            "(4)-[Passive]: If you must roll your Saving Throw for a Clash "
            "initiated by another Character, you may use the Saving Throw of "
            "your Supports (that are Merged Characters) instead of your own.\n"
            "(5)-[Passive]: The 6th effect of Entrusted Everything loses the "
            "[1/Encounter] Keyword and gains the [1/Round] Keyword instead.\n"
            "(6)-[Passive]: While you possess 1+ stack of Power, increase your "
            "Wound Rolls and Damage Reduction by 1(T).\n"
            "(7)-[Triggered/Power, 1/Round]: You may use the Movement "
            "Maneuver, Energy Charge Maneuver, or Basic Attack Maneuver as an "
            "Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Uninhibited Processor",
        description: "You have access to the unique strengths of your combined "
            "teammates.\n"
            "(1)-[Passive, Permanent]: Select an effect from the 3rd effect of "
            "Technological Being. You gain access to that effect while in this "
            "Transformation.\n"
            "(2)-[Automatic/Transform, Resource]: For each stack of Unified "
            "you gain through the 3rd effect of Support Units, you gain a "
            "stack of Unified Core.\n"
            "(3)-[1/Round]: As an Instant Maneuver during your turn, you may "
            "spend a stack of Unified Core to either (you cannot use the same "
            "effect more than once per Combat Encounter): enter the Determined "
            "State until the end of your turn; gain 2 Actions; use the Energy "
            "Charge Maneuver as an Out-of-Sequence Maneuver gaining 3 Energy "
            "Charges; or regain Life and Ki Points equal to 1/4 (rounded up) "
            "of their respective maximums (increased by your Surgency).",
      ),
      TransformationTrait(
        name: "Support Units (Legendary Trait)",
        description: "You have a mechanical squad of soldiers that are "
            "designed to temporarily augment your abilities.\n"
            "(1)-[Passive, Ruling]: Upon gaining access to this "
            "Transformation, select Android Minions you are the Master of or "
            "create Android Minions (so that the total is 3); they become your "
            "'Supports' (Special Minions).\n"
            "(2)-[Passive]: Supports ignore the Follower rule for Minions and "
            "are treated as additional Characters you control, but they only "
            "gain 2 Actions at the start of each Combat Round. Supports cannot "
            "enter or gain access to Legendary Forms.\n"
            "(3)-[1/Round]: As a Standard Maneuver with an Action Cost of 2 "
            "Actions, combine with as many of your Supports as possible. For "
            "each Support you combine with, gain a stack of Unified (with that "
            "Support as the Merged Character) as a Level 2 Temporary "
            "Awakening. Then, if you gained at least 1 stack of Unified, you "
            "may use the Transformation Maneuver as an Out-of-Sequence "
            "Maneuver to enter Hyper Mega Form.\n"
            "(4)-[Adventuring]: You can spend a day and 4 Scrap to revive a "
            "dead Support.\n"
            "(5)-[Addendum]: Disposed Supports — Supports can be combined with "
            "through the 3rd effect of Support Units even if: they are dead; "
            "they are a Merged Character (that Character loses their Unified "
            "stack); they are an Absorbed Character (that Character loses their "
            "Absorption stack); they have a Possessing Character (they lose "
            "that Overtaken stack); they are part of a Fusion (that Fusion "
            "ends). A Support cannot be combined with if: they were destroyed "
            "(see - Hakai); they are sealed away (see - Sealing); they are not "
            "on the Battlefield (if part of another Character through Unified, "
            "Absorption, or Fusion, they are still considered on the "
            "Battlefield as long as that Character is).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Steel General",
      description: "You have become a master strategist, giving you greater "
          "control over this Transformation.\n"
          "(1)-[Permanent]: Increase the Attribute Modifiers (AG/FO/TE/IN/MA) "
          "of your Supports by 1(T).\n"
          "(2)-[Permanent]: Hyper Mega Form gains the Scaling (LV2) Aspect.\n"
          "(3)-[Passive]: Double the bonus from the 6th effect of Mechanical "
          "Combination.\n"
          "(4)-[Triggered/Power, 1/Encounter]: Gain a stack of Unified Core.",
    ),
  ),

  // ============================================================ Demon God line ===
  TransformationDef(
    name: "Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Demon Race and/or Demon Clansmen Factor.",
    aspects: [
      "Enhanced Save (Impulsive/Cognitive/Morale)",
      "God Ki",
      "Battle Uniform",
      "Draining (LV2)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.combatClothing,
      craftsmanshipGrade: 5,
      qualityNames: ['Divine Apparel', 'Enchanted'],
    ),
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Terror of the Demon God",
        description: "You mark a foe with your unholy power, rendering them "
            "more susceptible to your attacks.\n"
            "(1)-[Ruling]: Opponents that are suffering from the Branded "
            "Combat Condition are known as 'Branded Opponents'.\n"
            "(2)-[Passive]: The Branded Combat Condition cannot be removed by "
            "the effects of your Opponents.\n"
            "(3)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time against Branded Opponents.\n"
            "(4)-[Passive]: Increase your Tier of Power Extra Dice by 2 Dice "
            "Categories while there is a Branded Opponent.\n"
            "(5)-[Passive]: Increase the Damage Category of your Signature "
            "Techniques that target a Branded Opponent by 1 Category.\n"
            "(6)-[Triggered/Power, 1/Round]: Target an Opponent who is not at "
            "Long Range and make a Clash (Cognitive) against them. If you win, "
            "that Opponent gains the Branded Combat Condition until the start "
            "of your next turn. If they already had the Branded Combat "
            "Condition, they gain the Broken Combat Condition instead for this "
            "effect.\n"
            "(7)-[Triggered/Start of Turn, 1/Encounter]: When you trigger the "
            "1st effect of Danger of the Demon God, you may target all "
            "Opponents.\n"
            "(Branded Combat Condition: reduce Combat Rolls and Soak Value by "
            "1(bT).)",
      ),
      TransformationTrait(
        name: "Devilish Divinity",
        description: "Your unholy powers grow stronger with your newfound "
            "divine might.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Demon God, "
            "select and gain access to 2 God Maneuvers while you are in this "
            "Transformation.\n"
            "(2)-[Passive]: Your Divine Tool gains the Demon Edge Special "
            "Quality (Critical Target becomes 6 vs Branded Opponents) without "
            "taking up any Quality Slots.\n"
            "(3)-[Passive]: If you pay the Ki Point Cost for an Attacking "
            "Maneuver with Divine Ki Points, increase the Natural Result of "
            "its Strike and Wound Rolls by 1.\n"
            "(4)-[Triggered]: If you score a Critical Result on the Strike or "
            "Wound Roll of an Attacking Maneuver, apply an Energy Charge to "
            "that Attacking Maneuver. You cannot apply more than 1 Energy "
            "Charge to an Attacking Maneuver with this effect.\n"
            "(5)-[Triggered, 1/Round]: If you Defeat an Opponent or knock them "
            "through a Health Threshold with an Attacking Maneuver, regain "
            "Divine Ki points equal to 1/4 (rounded up) of their maximum.\n"
            "(6)-[Triggered/Start of Turn, 1/Encounter]: You may spend 6(bT) "
            "Divine Ki Points to enter the Surging State until the start of "
            "your next turn. Ignore the 2nd effect of the Surging State if you "
            "enter it through this effect.",
      ),
      TransformationTrait(
        name: "Danger of the Demon God (Legendary Trait)",
        description: "Your demonic magic grants you a unique weapon to wield, "
            "representing your fiendish power.\n"
            "(1)-[Triggered/Start of Turn]: Target an Opponent who is not at "
            "Long Range and make a Clash (Cognitive) against them. If you win, "
            "that Opponent gains the Branded Combat Condition until the start "
            "of your next turn.\n"
            "(2)-[Passive]: Increase the Wound Rolls that target Opponents "
            "suffering from a Combat Condition by 1(T).\n"
            "(3)-[Ruling]: Upon gaining access to this Legendary Trait, design "
            "a Weapon with a Craftsmanship Grade of 5. This Weapon also gains "
            "the Spiritual Weapon and Warding Weapon Weapon Qualities. This "
            "Weapon is known as your 'Divine Tool'.\n"
            "(4)-[Passive]: Ignore the Weapon Penalty for wielding your Divine "
            "Tool.\n"
            "(5)-[1/Round]: If you aren't already wielding your Divine Tool, "
            "you can create a copy of your Divine Tool and equip it as an "
            "Instant Maneuver. If you use this effect, destroy all other "
            "copies of your Divine Tool except the one you're wielding.\n"
            "Battle Uniform — Combat Clothing, Craftsmanship Grade 5. "
            "Divine Apparel: Increase your Apparel Bonus by 1(bT). Enchanted: "
            "Increase your Soak Value by the Apparel Bonus. Dressed for "
            "Violence: Increase your Strike Rolls by 1/2 (rounded up) of your "
            "Apparel Bonus, and increase your Wound Rolls by your Apparel "
            "Bonus. Demonic Violence: If at least 1 Opponent is suffering from "
            "the Branded Combat Condition, increase your Apparel Bonus by "
            "1(bT).",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Stabilized Demon God",
        description: "Your divine might has fused with your demonic nature, "
            "empowering this Transformation greatly.\n"
            "(1)-[Permanent]: Demon God loses the Draining Aspect.\n"
            "(2)-[Passive]: Increase the Dice Category of your Energy Charges "
            "by M Categories while there is a Branded Opponent.\n"
            "(3)-[Passive]: Reduce the amount of Ki Points spent through the "
            "6th effect of Devilish Divinity by M(bT).\n"
            "(4)-[Passive]: Increase the [x/Encounter] Keyword by M for the "
            "6th effect of Devilish Divinity.",
      ),
      TransformationTrait(
        name: "Demon God Redux",
        description: "You have unleashed your inner demon and become a truly "
            "divine powerhouse of dark magic.\n"
            "(1)-[Permanent]: Gain access to the Superior Demon God Evolved "
            "Stage.\n"
            "(2)-[Permanent]: Demon God gains the Natural (LV1) Aspect.",
      ),
    ],
  ),

  // ========================================================= Superior Demon God ===
  TransformationDef(
    name: "Superior Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    prerequisiteText: "Evolved Stage: Unique (Demon God). Fully Mastered Demon "
        "God. Stress Test Requirement: +3.",
    aspects: ["Scaling (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Ascension of a Demon God",
        description: "Your dark, godly might can lay waste to any challenger "
            "who opposes you.\n"
            "(1)-[Passive]: Increase the Dice Score of your Cognitive Clashes "
            "through the 1st effect of Danger of the Demon God by 1(T).\n"
            "(2)-[Passive]: Increase your Damage Reduction by 1(T) while there "
            "is a Branded Opponent.\n"
            "(3)-[Passive]: Increase your Greater Dice by 1 Dice Category "
            "while there is a Branded Opponent.\n"
            "(4)-[Passive]: Your Armed Attacks made with your Divine Tool have "
            "the Natural Result of their Strike and Wound Rolls increased by "
            "1.\n"
            "(5)-[Triggered/Surging]: Enter the Superior State until the start "
            "of your next turn.",
      ),
    ],
  ),

  // ============================================================= True Demon God ===
  TransformationDef(
    name: "True Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    prerequisiteText: "Evolved Stage: Unique (Demon God). Stress Test "
        "Requirement: +5.",
    aspects: [
      "Enhanced Save (Corporeal)",
      "Armored",
      "Absorbed Apparel",
      "Raging",
      "Peaked",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "True Power of a Demon God",
        description: "Your divinely demonic power manifests your true inner "
            "self.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this Evolved "
            "Stage, select 2 Bestial Traits. You have access to those Bestial "
            "Traits while in this Transformation.\n"
            "(2)-[Permanent, Option]: Choose one of: Beast Within [Passive]: "
            "True Demon God gains the Growth (LV2) Aspect; Price of Demonic "
            "Power [Automatic/Defeat]: Die.\n"
            "(3)-[Choice]: Depending on your choice for the 2nd effect: Beast "
            "Within [Passive]: increase your Wound Rolls and Soak Value by "
            "1(T); Price of Demonic Power [Passive]: increase your Combat "
            "Rolls by 2(T) and you may spend your Life Points as if they were "
            "Ki Points (spent Life Points still reduce your Capacity).\n"
            "(4)-[Passive]: Apply an Energy Charge to all of your Attacking "
            "Maneuvers that target a Branded Opponent.\n"
            "(5)-[Triggered/Transform]: Integrate your Divine Tool while you "
            "are in this Transformation.\n"
            "(6)-[Triggered/Transform]: If you entered this Transformation due "
            "to using the Transformation Maneuver while in the Demon God "
            "Transformation, regain Divine Ki Points equal to 1/2 of your "
            "maximum.",
      ),
    ],
  ),

  // ======================================================= Transcended Demon God ===
  TransformationDef(
    name: "Transcended Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Demon God). Access to the True "
        "Demon God Evolved Stage. Stress Test Requirement: +9.",
    aspects: [
      "Enhanced Save (Corporeal)",
      "Armored",
      "Absorbed Apparel",
      "Raging",
      "Peaked",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Beyond a Demon God",
        description: "You have ascended beyond even your true demonic "
            "strength, becoming an unholy abomination of pure power.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this Evolved "
            "Stage, select a Bestial Trait you selected for the 1st effect of "
            "True Power of a Demon God. You gain access to that Bestial Trait "
            "while in this Transformation.\n"
            "(2)-[Passive]: Increase your Maximum Divine Ki Points by 1/2.\n"
            "(3)-[Passive]: The 7th effect of Terror of a Demon God loses its "
            "[1/Encounter] Keyword.\n"
            "(4)-[Passive]: Apply an Energy Charge to all of your Attacking "
            "Maneuvers that target a Branded Opponent.\n"
            "(5)-[Passive]: Increase your Combat Rolls and Soak Value by 1(T) "
            "while there is a Branded Opponent.\n"
            "(6)-[Choice]: Depending on your choice for 2nd effect of True "
            "Power of a Demon God: Beast Within [Passive]: your Size Category "
            "is treated as Gigantic for calculating your Soak Value and for "
            "Punching Down; Price of Demonic Power [Passive]: increase your "
            "Combat Rolls by 1(T) and you may spend Life Points as if they "
            "were Ki Points.\n"
            "(7)-[Triggered/Transform]: Integrate your Divine Tool while you "
            "are in this Transformation.\n"
            "(8)-[Triggered, 1/Encounter]: If you use the 1st effect of Danger "
            "of a Demon God, you automatically succeed at the Clash(es) for "
            "its effect.\n"
            "(9)-[Triggered/Transform, 1/Encounter]: Set your Divine Ki Points "
            "to their maximum.",
      ),
    ],
  ),

  // ================================== Ultra Instinct line (Sign Stage 1 + Complete
  // Stage 2; the pinnacle Legendary Forms).
  // ======================================================= Ultra Instinct "Sign" ===
  TransformationDef(
    name: 'Ultra Instinct "Sign"',
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    stressTestRequirement: 35,
    prerequisiteText: "Fully Mastered a Transformation with the God Ki Aspect, "
        "or have access to the God Class Up Awakening.",
    transformationLine: "Ultra Instinct",
    stage: 1,
    aspects: [
      "Linked (Autonomous Ultra Instinct)",
      "Perfect Ki Control",
      "High Speed",
      "Glowing",
      "Light Dependent",
      "Exhausting",
      "Weakening",
      "Difficult (LV1)",
      "Draining (LV2)",
      "Limited (LV5)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 7, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Secret of the Self-Centered",
        description: "Your sense of peace has progressed into true "
            "enlightenment, allowing you to accomplish what none before you "
            "could: awaken your body's true instincts.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Ultra Instinct "
            "\"Sign\", select 4 God Maneuvers. You have access to those God "
            "Maneuvers while in Ultra Instinct \"Sign\".\n"
            "(2)-[Permanent]: To gain mastery of Ultra Instinct \"Sign\", you "
            "must have mastered Autonomous Ultra Instinct.\n"
            "(3)-[Permanent]: You cannot gain access to or enter an Evolved "
            "Stage with this Transformation as the Original Form.\n"
            "(4)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(5)-[Passive]: You do not suffer from Diminishing Defense.\n"
            "(6)-[Passive]: Ignore all penalties to your Combat Rolls while "
            "you are not suffering from the effects of the Weakening Aspect.\n"
            "(7)-[Passive]: For each Health Threshold you are above, increase "
            "your Combat Rolls and Soak Value by 1(T).\n"
            "(8)-[Passive]: Increase the Dice Score of your Legend Realized by "
            "your Surgency.\n"
            "(9)-[Passive]: Your Physical Attacks that do not possess an AoE "
            "can target Opponents outside of your Melee Range.\n"
            "(10)-[Triggered/Transform, Triggered/Start of Turn]: Gain 2 "
            "Counter Actions.",
      ),
      TransformationTrait(
        name: "Reaching a Deeper Instinct",
        description: "You have broken past your inherent skill to grasp at "
            "something beyond, incorporating it into your movements.\n"
            "(1)-[Triggered, Resource]: At the end of the Combat Round, gain a "
            "stack of Instinct (max. 4).\n"
            "(2)-[Passive]: For every stack of Instinct you possess, increase "
            "your Tier of Power Extra Dice by 1 Category.\n"
            "(3)-[Passive]: For every 2 stacks of Instinct you possess, "
            "increase the Dice Score of your Steadfast Checks by 1.\n"
            "(4)-[Passive]: You cannot gain stacks of Instinct while you are "
            "suffering from the effects of the Weakening Aspect.\n"
            "(5)-[Triggered/Start of Turn]: If you have 2+ stacks of Instinct, "
            "enter the first level of the Instinctual Special State until the "
            "start of your next turn. If you have 4+ stacks of Instinct, "
            "instead enter the second level of the Instinctual State.\n"
            "Instinctual Special State (2 Levels):\n"
            "Diving into Instinct (Level 1) — (1)-[Passive]: Treat your Health "
            "Threshold as if it was L higher for the 7th effect of Secrets of "
            "the Self-Centered. (2)-[Passive]: Increase the minimum Natural "
            "Result for the 3rd effect of Angelic Techniques by L. "
            "(3)-[Passive]: Reduce the Divine Ki Point Cost of all God "
            "Maneuvers by L(bT). (4)-[Passive]: Increase your Saving Throws "
            "and Might by L(bT) for the duration of Clashes initiated by "
            "another Character.\n"
            "Deeper than Instinct (Level 2) — (1)-[Passive]: You cannot gain "
            "Combat Conditions (except Suffocating, Stress Exhaustion, or "
            "Pinned). (2)-[Triggered/Start of Turn, 1/Encounter]: Use the "
            'Transformation Maneuver to enter Ultra Instinct "Complete", even '
            "if you do not have access to it and ignore all Prerequisites "
            "(you automatically succeed at the Stress Test).",
      ),
      TransformationTrait(
        name: "Instinctual Movement (Legendary Trait)",
        description: "Your body moves without instructions, allowing you to "
            "react faster to threats.\n"
            "(1)-[Passive]: Gain access to the Autonomous Ultra Instinct "
            "Enhancement.\n"
            "(2)-[Passive]: While you are not suffering from any Health "
            "Threshold Penalties, increase your Defense Value and Soak Value "
            "by 1(T).\n"
            "(3)-[Passive]: While you are not suffering from any Health "
            "Threshold Penalties, increase your Stress Bonus by 1.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Understanding of Ultra Instinct",
        description: "You've learned how your body moves when it acts on its "
            "own, allowing you to accommodate for the changes in your fighting "
            "style.\n"
            "(1)-[Permanent]: This Transformation loses the Limited, "
            "Exhausting, Weakening, and the Draining Aspect.\n"
            "(2)-[Passive]: Double the amount of Instinct you gain through the "
            "1st effect of Reaching a Deeper Instinct.\n"
            "(3)-[Passive]: You may use an Evolved Stage that does not have "
            "the Pinnacle Aspect with Ultra Instinct \"Sign\" as the Original "
            "Form, ignoring the 3rd effect of Secrets of the Self-Centered.\n"
            "(4)-[Triggered/Threshold]: If you succeed at the Steadfast Check "
            "for this Health Threshold, set your Life Points to the highest "
            "value for that Health Threshold.",
      ),
      TransformationTrait(
        name: "The Truth of Ultra Instinct",
        description: "You have learned to tap into your preferred fighting "
            "style while using Ultra Instinct.\n"
            "(1)-[Permanent]: Gain access to the True Ultra Instinct Evolved "
            "Stage and you may use it, ignoring the 3rd effect of Secrets of "
            "the Self-Centered.",
      ),
    ],
  ),

  // =================================================== Ultra Instinct "Complete" ===
  TransformationDef(
    name: 'Ultra Instinct "Complete"',
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    stressTestRequirement: 40,
    prerequisiteText: "Mastered Ultra Instinct \"Sign\".",
    transformationLine: "Ultra Instinct",
    stage: 2,
    aspects: [
      "Linked (Autonomous Ultra Instinct)",
      "Innate State (Instinctual)",
      "Perfect Ki Control",
      "High Speed",
      "Glowing",
      "Light Dependent",
      "Exhausting",
      "Weakening",
      "Difficult (LV1)",
      "Draining (LV2)",
      "Limited (LV5)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 8, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Completion of Ultra Instinct",
        description: "Your mastery of combat is reflected in your movements, "
            "allowing you to evade without fatigue and attack without holding "
            "anything back.\n"
            "(1)-[Automatic/Start of Turn]: If you are in the Raging State, "
            "leave this Transformation and suffer from Stress Exhaustion until "
            "the end of your next turn.\n"
            "(2)-[Automatic]: Upon leaving this Transformation, reduce your "
            "Life Points and Ki Points by 1/4 of their respective maximums. "
            "This cannot reduce your Life or Ki Points to their minimum "
            "value.\n"
            "(3)-[Permanent]: To gain mastery for Ultra Instinct \"Complete\", "
            "you must have fully mastered Autonomous Ultra Instinct.\n"
            "(4)-[Permanent]: You have access to all God Maneuvers while in "
            "the Ultra Instinct \"Complete\" Transformation. Any decisions "
            "made for the effects of those God Maneuvers are made upon gaining "
            "access to Ultra Instinct \"Complete\".\n"
            "(5)-[Passive]: Double the bonuses from the 2nd effect of "
            "Instinctual Movement and the 1st effect of Instinctual Combat.\n"
            "(6)-[Passive]: Increase your maximum number of Instinct stacks by "
            "2.\n"
            "(7)-[Passive]: You do not suffer from Diminishing Offense.\n"
            "(8)-[Triggered, 1/Round]: If you use an Attacking Maneuver, apply "
            "a number of Energy Charges equal to 1/2 of your Instinct "
            "stacks.\n"
            "(9)-[Triggered/Transform]: Set your number of Instinct stacks to "
            "2 (this cannot reduce your number of Instinct stacks).\n"
            "(10)-[Triggered/Start of Turn, 1/Encounter]: If you have 6 stacks "
            "of Instinct, trigger the Burst Limit of Autonomous Ultra Instinct "
            "(even if you have triggered a Burst Limit previously this Combat "
            "Encounter).",
      ),
      TransformationTrait(
        name: "Instinctual Combat (Legendary Trait)",
        description: "Your body attacks without instructions, eliminating "
            "threats even while you remain unaware of them.\n"
            "(1)-[Passive]: While you are not suffering from any Health "
            "Threshold Penalties, increase your Strike and Wound Rolls by "
            "1(T).\n"
            "(2)-[Triggered/Power, 1/Encounter]: Ignore all Health Threshold "
            "Penalties until the start of your next turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Surpassing the Gods",
        description: "You have rid yourself of all thought and emotion, moving "
            "purely on instinct alone.\n"
            "(1)-[Passive]: Double the amount of Instinct stacks for the 9th "
            "effect of Completion of Ultra Instinct.\n"
            "(2)-[Passive]: Double the reduction to Ki Point Costs from the "
            "Perfect Ki Control Aspect.\n"
            "(3)-[Triggered/Start of Turn, 1/Encounter]: If you have 6 stacks "
            "of Instinct, enter the Determined State until the end of your "
            "turn.",
      ),
      TransformationTrait(
        name: "Reaching the Angels",
        description: "You've become just as powerful as the divine beings who "
            "first utilized Ultra Instinct.\n"
            "(1)-[Permanent]: Ultra Instinct \"Complete\" gains the Natural "
            "(LV1) Aspect.\n"
            "(2)-[Passive]: Increase the Dice Score of your Combat Rolls that "
            "score a Critical Result by 1(T).",
      ),
    ],
  ),

  // ========================================================== True Ultra Instinct ===
  TransformationDef(
    name: "True Ultra Instinct",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Ultra Instinct \"Sign\"). Fully "
        "Mastered Ultra Instinct \"Sign\". Stress Test Requirement: +2.",
    aspects: ["Pinnacle (LV1)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "My Ultra Instinct",
        description: "You have learned to apply your own unique spin to your "
            "Ultra Instinct.\n"
            "(1)-[Passive]: If you do not have access to the Instinctual "
            "Combat Legendary Trait, gain access to it while you are in this "
            "Transformation.\n"
            "(2)-[Passive]: You may use an additional Enhancement in "
            "conjunction to this Transformation in addition to Autonomous "
            "Ultra Instinct.\n"
            "(3)-[Passive]: You do not suffer from Diminishing Offense.\n"
            "(4)-[Passive]: Increase your maximum number of Instinct stacks by "
            "2.\n"
            "(5)-[Automatic]: If you leave this Transformation, leave all "
            "Enhancements you are currently in.",
      ),
    ],
  ),

  // ========================================================== Potential Unleashed ===
  TransformationDef(
    name: "Potential Unleashed",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "1+ stacks of the Unlocked Potential Awakening.",
    aspects: ["Enhanced Save (All)", "Natural (LV1)", "Difficult (LV1)"],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Latent Power",
        description: "With so much of your potential brought to the surface, "
            "you no longer have need of raising your power even further.\n"
            "(1)-[Passive]: While you possess no stacks of Power, you "
            "automatically succeed at all Steadfast Checks.\n"
            "(2)-[Passive]: While you possess no stacks of Power, reduce the "
            "Ki Point Cost for all Attacking Maneuvers by 2(T).\n"
            "(3)-[1/Round]: If you possess no stacks of Power, you may use the "
            "Defend Maneuver without spending a Counter Action.\n"
            "(4)-[Triggered]: If you possess no stacks of Power and an "
            "Opponent initiates a Clash against you that uses your Might or a "
            "Saving Throw, increase your Dice Score for that Clash by 2(bT).\n"
            "(5)-[Triggered]: If you make an Attacking Maneuver, use the "
            "Defend Maneuver, or are targeted by an Attacking Maneuver while "
            "you possess no stacks of Power, you may gain 2 stacks of Power "
            "for the duration of that Maneuver (after paying the Ki Point "
            "Cost).\n"
            "(6)-[Triggered]: If you end your turn while possessing no stacks "
            "of Power, regain 6(bT) Ki Points.",
      ),
      TransformationTrait(
        name: "Depth of Potential",
        description: "When your awakened power isn't enough, you have reserved "
            "potential enough to tap into a wellspring your enemies will never "
            "recover from seeing.\n"
            "(1)-[Passive]: While you possess 4+ stacks of Power, increase "
            "your Tier of Power by 1 (see — Breakthrough).\n"
            "(2)-[Triggered/Power, 1/Round]: Instead of applying the usual "
            "effects of the Power Up Maneuver, set your stacks of Power to 4 "
            "(5 if you possess 2 stacks of Unlocked Potential) until the start "
            "of your next turn.\n"
            "(3)-[Triggered, 1/Encounter]: If you use the 2nd effect of Depth "
            "of Potential, you may use the Basic Attack Maneuver as an "
            "Out-of-Sequence Maneuver, but this Attacking Maneuver cannot "
            "possess an AoE. If you deal Damage to an Opponent with that "
            "Attacking Maneuver, you may use another Basic Attack Maneuver as "
            "an Out-of-Sequence Maneuver, but it must include the Opponent "
            "that received Damage as a target.\n"
            "(4)-[Automatic/Start of Turn]: If you lose stacks of Power at the "
            "start of this turn, you cannot gain Power Stacks, and you suffer "
            "from the Impediment and Fatigued Combat Conditions for the "
            "duration of this turn.",
      ),
      TransformationTrait(
        name: "Slumbering Potential (Legendary Trait)",
        description: "The layers of power buried deep within your soul lie "
            "dormant, waiting for you to call on them.\n"
            "(1)-[Passive]: While you have 2+ stacks of Power, double the "
            "Attribute Modifier Bonus of Unlocked Potential.\n"
            "(2)-[Passive]: While you possess no stacks of Power, increase "
            "your Surgency by 2(T).\n"
            "(3)-[Triggered/Start of Turn, 1/Encounter]: If you possess no "
            "stacks of Power, you may use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Learned Potential",
        description: "You have mastered the power at your fingertips, allowing "
            "you to uncover yet another layer of the potential slumbering "
            "within you.\n"
            "(1)-[Passive]: You do not gain the Impediment Combat Condition "
            "from the 4th effect of Depth of Potential.\n"
            "(2)-[Passive]: While you have no stacks of Power, you cannot gain "
            "the Impaired or Shaken Combat Conditions.",
      ),
      TransformationTrait(
        name: "Achieved Potential",
        description: "Now you have awakened all of your potential, mastering "
            "it and making it your own power.\n"
            "(1)-[Permanent]: Increase the level of the Natural Aspect for "
            "Potential Unleashed by 1.\n"
            "(2)-[Passive]: Ignore the 4th effect of Depth of Potential.",
      ),
    ],
  ),

  // ===================================================================== Ultimate ===
  TransformationDef(
    name: "Ultimate",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    prerequisiteText: "Evolved Stage: Unique (Potential Unleashed). Mastered "
        "Potential Unleashed. Stress Test Requirement: +5.",
    aspects: ["Scaling (LV2)", "Perfect Ki Control", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Fathomless Potential",
        description: "The amount of power you've drawn from deep within is so "
            "enormous that even the gods cannot fully comprehend it.\n"
            "(1)-[Passive]: If your current Tier of Power is 6+, increase the "
            "Attribute Modifier Bonus (IN) of this Transformation by 1(T).\n"
            "(2)-[Passive]: While you have no stacks of Power, you do not "
            "suffer from Diminishing Defense.\n"
            "(3)-[Passive]: While you have 4+ stacks of Power, you do not "
            "suffer from Diminishing Offense.\n"
            "(4)-[Triggered/Power, 1/Round]: Enter the Surging State until the "
            "start of your next turn.",
      ),
    ],
  ),

  // ============================== Beyond God line (Divine Acclimation Null Stage +
  // God-Like State Stage 1; an intermediate God-Ki Form).
  // =================================== Beyond God: Divine Acclimation (0) ===
  TransformationDef(
    name: "Divine Acclimation",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 6,
    prerequisiteText: "Beyond God line, Null Stage. Transformation with the "
        "God Ki Aspect.",
    transformationLine: "Beyond God",
    stage: 0,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {},
    traits: [
      TransformationTrait(
        name: "Touch of Divinity",
        description: "You have incorporated god-like power into yourself, "
            "allowing you to tap into it at will.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Divine "
            "Acclimation, select 2 God Maneuvers. You have access to those God "
            "Maneuvers while in any Transformation of the Beyond God "
            "Transformation Line.\n"
            "(2)-[Passive]: While you have 2+ stacks of Power, increase the "
            "Attribute Modifier Bonus (AG/FO/TE/MA) of this Transformation by "
            "1(T).\n"
            "(3)-[Triggered/Power]: Gain access to your Divine Ki Points until "
            "the start of your next turn. If you are already in the God Ki "
            "Special State, instead enter the Superior State until the end of "
            "your turn.",
      ),
    ],
  ),

  // ========================================= Beyond God: God-Like State (1) ===
  TransformationDef(
    name: "God-Like State",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 22,
    prerequisiteText: "Transformation with the God Ki Aspect.",
    transformationLine: "Beyond God",
    stage: 1,
    aspects: ["Enhanced Save (All)", "God Ki", "Natural (LV1)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Divine Aura",
        description: "Your divine powers allow you to surpass your mortal "
            "state without fully tapping into your divine power.\n"
            "(1)-[Permanent]: All Forms with the God Ki Aspect are considered "
            "to be a part of the Beyond God Transformation Line for the "
            "effects of Step-by-Step Transformation.\n"
            "(2)-[Passive]: If you would use Divine Ki Points to pay the Ki "
            "Point Cost of an Attacking Maneuver, reduce the Ki Point Cost by "
            "2(T).\n"
            "(3)-[Passive]: If you would use Divine Ki Points to apply a Ki "
            "Wager of 2(T) or more onto an Attacking Maneuver, increase the "
            "Wound Roll of that Attacking Maneuver by 2(T).\n"
            "(4)-[Triggered/Start of Turn]: Spend 2(bT) Divine Ki Points to "
            "use the Power Up Maneuver as an Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Godly Combat",
        description: "You move like a force of nature, your awakened divine "
            "status allowing you to easily outmaneuver mere mortals.\n"
            "(1)-[Passive]: Increase your Combat Rolls by 1(T) while in the "
            "Healthy Health Threshold.\n"
            "(2)-[Passive]: Ignore the second effect of the Superior State.\n"
            "(3)-[Passive]: While in the Superior State, increase your Wound "
            "Rolls and Soak Value by 1(bT).\n"
            "(4)-[Triggered, 1/Round]: If you are targeted by an Attacking "
            "Maneuver, you may spend 2(bT) Divine Ki Points to use the Defend "
            "Maneuver without spending a Counter Action.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Divine Stepping Stone",
      description: "Using this intermediate state, you are able to more easily "
          "wield your full divine might.\n"
          "(1)-[Passive]: While in the Superior State, you cannot gain the "
          "Impaired or Impediment Combat Condition.\n"
          "(2)-[Triggered/Superior]: You may use the Transformation Maneuver. "
          "If you do, you must use it to transform into a Form with the God Ki "
          "Aspect and an equal or higher Tier of Power Requirement to this "
          "Transformation. Upon entering that Transformation, gain Divine Ki "
          "Points equal to the Dice Score of your Legend Realized roll for "
          "entering that Transformation.",
    ),
  ),

  // =============================================================== Godly Powers ===
  TransformationDef(
    name: "Godly Powers",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    aspects: [
      "Enhanced Save (All)",
      "God Ki",
      "Glowing",
      "Draining (LV2)",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Godly Training",
        description: "You have been trained in the use of Divine Ki, allowing "
            "you to display godly might in battle.\n"
            "(1)-[Permanent]: Upon gaining access to this Transformation, "
            "select 3 God Maneuvers. You gain access to these God Maneuvers.\n"
            "(2)-[Triggered]: If you spend Divine Ki Points on an Attacking "
            "Maneuver either due to the Ki Point Cost or the second effect of "
            "Divine Energy, increase the Wound Roll of that Attacking Maneuver "
            "by the amount of Divine Ki Points spent.\n"
            "(3)-[Triggered]: When you spend Divine Ki Points, regain Ki "
            "Points equal to 1/2 of the Divine Ki Points spent.\n"
            "(4)-[Triggered]: If you use a Ki Surge, halve the amount of Ki "
            "Points you regain to regain an equal amount of Divine Ki "
            "Points.\n"
            "(5)-[Triggered/Power, 1/Encounter]: You may use a God Maneuver "
            "that is a Standard Maneuver with an Action Cost of up to 2 "
            "Actions as an Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Realm of the Gods",
        description: "Your power has skyrocketed, boosting you beyond mortal "
            "power into territories reserved for the divine.\n"
            "(1)-[Passive]: Double the bonus to your Wound Roll from a Ki "
            "Wager that uses Divine Ki Points.\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, double the "
            "bonus from the 3rd effect of the God Ki Special State.\n"
            "(3)-[Triggered/Start of Turn]: Apply one of the following "
            "effects: Regain 4(bT) Divine Ki Points; or spend 2(bT) Divine Ki "
            "Points to enter the Superior State until the start of your next "
            "turn.",
      ),
      TransformationTrait(
        name: "Divine Energy (Legendary Trait)",
        description: "You have gained access to Divine Ki, allowing you to use "
            "a small portion of it, even in your mortal state.\n"
            "(1)-[Triggered/Start of Turn, 1/Encounter]: If you are not in the "
            "God Ki Special State, you gain access to your Divine Ki Points "
            "until the start of your next turn.\n"
            "(2)-[Triggered]: When making a Strike or Dodge Roll, you may "
            "spend up to 4(bT) Divine Ki Points to increase the Dice Score by "
            "an equal amount.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Among Gods",
        description: "You have mastered the use of Divine Ki, securing your "
            "place in the realm of the gods.\n"
            "(1)-[Permanent]: Godly Powers loses M levels of the Draining "
            "Aspect and gains the Scaling (LV2) Aspect.\n"
            "(2)-[Triggered, 1/Round, M/Encounter]: If an Opponent who is not "
            "in the God Ki Special State initiates a Clash against you that "
            "uses your Might or Saving Throw, you may automatically succeed at "
            "that Clash.",
      ),
      TransformationTrait(
        name: "Attained Godhood",
        description: "Truly one of the gods now, you simply always have your "
            "full divine power at your fingertips.\n"
            "(1)-[Permanent]: Godly Powers gains the Natural (LV2) Aspect.\n"
            "(2)-[Triggered, 1/Round]: When making a Might Clash, you may "
            "spend up to 2(bT) Divine Ki Points to increase the Dice Score by "
            "an equal amount.",
      ),
    ],
  ),

  // ============================================================= Destroyer Form ===
  TransformationDef(
    name: "Destroyer Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    stressTestRequirement: 35,
    prerequisiteText: "Access to Power of Destruction, fully Mastered a "
        "Transformation with the God Ki Aspect.",
    aspects: [
      "Enhanced Save (All)",
      "God Ki",
      "Bulky",
      "Growth (LV1)",
      "High Speed (LV3)",
      "Strainless",
      "Difficult (LV1)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 7, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 7, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Successor of Destruction",
        description: "You are the inheritor of the Power of Destruction, and "
            "can wield that power against your foes.\n"
            "-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select 3 God Maneuvers. You have access to those "
            "God Maneuvers while in this Transformation.\n"
            "-[Automatic/Transform]: Use the Transformation Maneuver as an "
            "Out-of-Sequence Maneuver to enter the Power of Destruction "
            "Enhancement Power. You cannot leave Power of Destruction while in "
            "this Transformation.\n"
            "-[Passive]: Your Critical Target for your Wound Rolls is set to "
            "7.\n"
            "-[Passive]: Ignore all effects that reduce your Soak Value aside "
            "from Damage Categories and the effects of Exceed Traits.\n"
            "-[Passive]: If your Attacking Maneuver possesses the Destruction "
            "Profile, increase its Strike Rolls by 1(T) and it gains an Energy "
            "Charge.\n"
            "-[Passive]: You have access to the Hakai Unique Ability while in "
            "this Transformation.\n"
            "-[Passive]: Double the reduction to Life Points your Opponents "
            "suffer through the effects of the Hakai Unique Ability.\n"
            "-[Passive]: This Transformation gains the Realm of the Gods "
            "trait.",
      ),
      TransformationTrait(
        name: "Armor of Destruction",
        description: "You surround yourself with destruction energy, providing "
            "a barrier against attacks.\n"
            "-[Triggered/Start of Combat Round]: Spend 6(bT) Divine Ki Points. "
            "Roll a Wound Roll as if making an Energy or Magic Attack. Reduce "
            "all Damage you would receive by 1/4 (rounded up) of that Wound "
            "Roll's Dice Score until the end of the Combat Round.\n"
            "-[Triggered, 1/Round]: If you are hit by an Attacking Maneuver, "
            "spend 4(bT) Divine Ki Points to roll a Wound Roll as if making an "
            "Energy or Magic Attack. Reduce the Damage you would receive by "
            "1/2 of that Wound Roll's Dice Score.",
      ),
      TransformationTrait(
        name: "Before Creation Comes Destruction (Legendary Trait)",
        description: "You destroy so that something new and wonderful can "
            "replace the old, as the cycle intends.\n"
            "-[Passive]: If an Attacking Maneuver has had Divine Ki Points "
            "spent on its Ki Point Cost or Ki Wager, increase the Wound Roll "
            "by 1/4 (rounded up) of your Soak Value.\n"
            "-[Triggered/Transform, 1/Encounter]: Upon entering the Power of "
            "Destruction Enhancement Power, regain Divine Ki Points equal to "
            "triple your Power Level.",
      ),
      TransformationTrait(
        name: "Only Destruction (Exceed Trait)",
        description: "You think only of what you can destroy.\n"
            "-[Passive]: Apply your Might to the Wound Rolls of your Attacking "
            "Maneuvers with the Destruction Profile.\n"
            "-[Passive]: Reduce the amount of Divine Ki Points spent through "
            "the effects of Armor of Destruction by 2(bT).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "God of Destruction",
      description: "You have ascended beyond your former station and become a "
          "true God of Destruction.\n"
          "-[Passive]: Ignore the penalties for 1 stack of Super Stack.\n"
          "-[Triggered/Transform]: You may choose to remove the Growth and "
          "Bulky Aspects from this Transformation. If you do, increase your "
          "Strike and Dodge Rolls by 1(T) until you leave this "
          "Transformation.\n"
          "-[Triggered, 1/Round]: For every Energy Charge a Signature "
          "Technique with the Destruction Profile possesses, increase its "
          "Wound Roll by 1(T).\n"
          "-[Permanent]: This Transformation gains the Armored and Natural "
          "Aspects.",
    ),
  ),

  // ================================================================== Super Form ===
  TransformationDef(
    name: "Super Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    aspects: [
      "Prelude",
      "Draining (LV1)",
      "Power High (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Your Transformation",
        description: "Transforming your body of your own accord, you manage to "
            "shape your newfound power to match your own desires.\n"
            "(1)-[Permanent, Ruling, Passive]: Upon gaining access to this "
            "Transformation, select and gain access to 2 'Form Traits' while "
            "in this Transformation.\n"
            "(2)-[Ruling]: Every Form Trait has at least 1 effect with a "
            "'Mastery' Keyword. That effect is not gained until Super Form is "
            "Mastered.\n"
            "Select 2 Form Traits below.",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Form Trait',
            maxChoices: 2,
            options: [
              TraitOption(
                name: 'Armed Form',
                description: '(1)-[Prerequisite]: Weapon Specialist Talent. '
                    '(2)-[Passive]: Increase the Wound Rolls of your Armed '
                    'Attacks by 2(T). (3)-[Triggered/Start of Turn]: Select a '
                    'Weapon you possess and a qualifying Weapon Quality (except '
                    'a Special one) with 1 Quality Slot; it gains that Quality '
                    'until the start of your next turn. (4)-[Mastery, Passive]: '
                    'Increase the Strike Rolls of your Armed Attacks by 1(T). '
                    '(5)-[Mastery, Triggered, 1/Round]: If you deal Damage to '
                    'an Opponent with an Armed Attack during your turn, that '
                    'Opponent gains a stack of Broken until the end of your '
                    'turn.',
              ),
              TraitOption(
                name: 'Aura Form',
                description: '(1)-[Prerequisite]: You have access to the '
                    'Sparking Aura Enhancement. (2)-[Permanent]: Super Form '
                    'gains the Linked (Sparking Aura) Aspect. (3)-[Mastery, '
                    'Passive]: Reduce the Stress Test Requirement for the '
                    'Sparking Aura by 2. (4)-[Mastery, Passive]: While you have '
                    '2+ stacks of Power, increase your Combat Rolls and Soak '
                    'Value by 1(T).',
              ),
              TraitOption(
                name: 'Awakening Form',
                description: '(1)-[Permanent, Passive]: Select a Lesser '
                    'Awakening you meet the requirements for; gain access to '
                    'it while in this Transformation as a Temporary Awakening '
                    '(choices for its Option/Passive effects are retained; you '
                    'do NOT gain its AMB). (2)-[Mastery, Passive]: While in '
                    'this Transformation, you gain the AMB of the selected '
                    'Awakening. (3)-[Mastery, Passive]: Increase your Wound '
                    'Rolls and Surgency by 1(T).',
              ),
              TraitOption(
                name: 'Balanced Form',
                description: '(1)-[Permanent]: Super Form gains the Perfect Ki '
                    'Control Aspect. (2)-[Passive]: Increase the AMB (FO/MA) '
                    "for Super Form by 1(T). (3)-[Triggered]: If you use an "
                    "Attacking Maneuver from a Foundation you haven't used "
                    'this Combat Round, increase your Wound Rolls by 1(T) '
                    'until the start of the next Combat Round. (4)-[Triggered, '
                    '1/Round]: If you hit an Opponent and deal Damage, you may '
                    'Basic Attack Out-of-Sequence using a Foundation you have '
                    'not used this Combat Round. (5)-[Mastery, Passive]: '
                    'During a Combat Round you triggered the 3rd effect 3 '
                    'times, increase your Combat Rolls by 1(T). (6)-[Mastery, '
                    '1/Encounter]: Use the Basic Attack Maneuver as an Instant '
                    'Maneuver.',
                ambPerTierBonus: {DbuAttribute.force: 1, DbuAttribute.magic: 1},
              ),
              TraitOption(
                name: 'Big Form',
                description: '(1)-[Permanent, Passive]: Super Form gains the '
                    'Growth (LV1) Aspect. (2)-[Passive]: Increase your Soak '
                    'Value by 1(T). (3)-[Passive]: Increase your Wound Rolls '
                    'by 1(T) for each level of the Growth Aspect. '
                    '(4)-[Triggered/Power, 1/Round]: Gain a Counter Action, or '
                    'increase the level of the Growth Aspect by 1 until you '
                    'leave. (5)-[Mastery, Passive]: Increase your Defense '
                    'Value by 1(T). (6)-[Mastery, Passive]: Increase the Dice '
                    'Category of your Punching Down Extra Dice by 1. '
                    '(7)-[Mastery, Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver, increase your Size Category to Colossal for its '
                    'duration.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Clever Form',
                description: '(1)-[Passive]: Set the AMB (SC) of this '
                    'Transformation (not Evolved Stages) equal to the highest '
                    'AMB applied to the other Attributes (after all '
                    'calculations). (2)-[Passive]: Increase your Wound Rolls '
                    'by 1/4 (rounded up) of your Scholarship Modifier. '
                    '(3)-[Triggered, 1/Round]: If an Ally targets an Analyzed '
                    'Opponent with an Attacking Maneuver, you may increase its '
                    'Strike and Wound Rolls by 1/4 of your Scholarship '
                    'Modifier. (4)-[Triggered, 1/Round]: If you Analyze an '
                    'Opponent adjacent to an Ally, that Ally may Basic Attack '
                    'Out-of-Sequence. (5)-[Mastery, Passive]: Increase your '
                    'Strike and Dodge Rolls by 1/4 of your Scholarship '
                    'Modifier.',
              ),
              TraitOption(
                name: 'Custom Form',
                description: '(1)-[Permanent, Passive]: Gain access to a '
                    'Mind-Category Custom Species Racial Trait while in Super '
                    'Form. (2)-[Mastery, Passive]: You gain access to the '
                    'Twinned Effect of the Custom Species Racial Trait you '
                    'selected for the first effect of Custom Form.',
              ),
              TraitOption(
                name: 'Damage Form',
                description: '(1)-[Passive]: Increase your Might and Wound '
                    'Rolls by 1(T). (2)-[Passive]: While in the Surging State, '
                    'increase your Strike Rolls by 1(T) but reduce your Dodge '
                    'Rolls by an equal amount. (3)-[Triggered/Start of Turn]: '
                    'Enter the Surging State until the start of your next '
                    'turn. (4)-[Triggered, 1/Round]: If you knock an Opponent '
                    'through a Health Threshold, roll 1d8(T); reduce that '
                    "Opponent's Life Points by the Dice Score. (5)-[Mastery, "
                    'Passive]: Double the bonus to your Strike Rolls through '
                    'the second effect. (6)-[Mastery, Passive]: While in the '
                    'Surging State, increase your Soak Value by 2(T). '
                    '(7)-[Mastery, Triggered, 1/Round]: If you make an '
                    'Attacking Maneuver with 2+ Energy Charges, you may apply '
                    'an additional Energy Charge (you suffer Guard Down until '
                    'the start of your next turn).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.might,
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
                name: 'Demonic Form',
                description: '(1)-[Prerequisite]: You do not possess the Demon '
                    'Clansmen Factor. (2)-[Passive]: While in this '
                    'Transformation, you gain access to the Heart of Evil '
                    'Factor Trait; for its Option effect you must choose the '
                    'Resilient Demon Lord effect. (3)-[Mastery, Passive]: '
                    'Increase the Strike Rolls of your Attacking Maneuvers '
                    'that target only Characters suffering from a Combat '
                    'Condition by 1(T). (4)-[Mastery, Triggered]: If you '
                    'trigger the 3rd effect of Heart of Evil, you may apply '
                    'two of its effects instead of one.',
              ),
              TraitOption(
                name: 'Fast Form',
                description: '(1)-[Permanent]: Super Form gains the High Speed '
                    'and Enhanced Save (Impulsive) Aspects. (2)-[Passive]: '
                    'Increase the AMB (AG) of Super Form by 1(T). '
                    '(3)-[Triggered]: If you dodge an Attacking Maneuver, this '
                    'triggers your Exploit Maneuver against the attacking '
                    'Character. (4)-[1/Round]: You may use the Exploit '
                    'Maneuver without spending a Counter Action. (5)-[Mastery, '
                    'Triggered, 1/Round]: If you target an Opponent with an '
                    'Attacking Maneuver made through the Exploit Maneuver, you '
                    'may use your Agility Modifier as the Damage Attribute.',
                ambPerTierBonus: {DbuAttribute.agility: 1},
              ),
              TraitOption(
                name: 'Gripper Form',
                description: '(1)-[Passive]: Gain the Grippy Grabbers Bestial '
                    'Trait. (2)-[Passive]: If you win the Clash for the 3rd '
                    "effect of Grippy Grabbers, you may reduce the target's "
                    'Life Points and use the Launch Maneuver through that '
                    'effect. (3)-[Triggered, 1/Round]: If you move an Opponent '
                    'through the Launch Maneuver, they gain Impaired until the '
                    'start of your next turn. (4)-[Mastery, Passive]: While in '
                    'a Grapple as the Grappler, increase your Soak Value and '
                    'Wound Rolls by 1(T). (5)-[Mastery, Triggered, 1/Round]: '
                    'If you win a Grapple Check, you may use the Power Up '
                    'Maneuver as an Out-of-Sequence Maneuver.',
              ),
              TraitOption(
                name: 'Magic Form',
                description: '(1)-[Permanent, Passive]: Select a Wizarding '
                    'Trait (see - Warlock); gain access to it while in this '
                    'Transformation. (2)-[Passive]: You may use your Magic '
                    'Modifier instead of your Force Modifier when calculating '
                    'Surgency. (3)-[Mastery, Passive]: Increase the Wound '
                    'Rolls of your Magic Attacks by 1(T). (4)-[Mastery, '
                    'Passive]: Reduce the Ki Point Cost of your Magical Unique '
                    'Abilities by 1(T).',
              ),
              TraitOption(
                name: 'Mindful Form',
                description: '(1)-[Permanent]: Super Form gains the Innate '
                    'State (Mindful) Aspect. (2)-[Passive]: Increase your '
                    'Dodge Rolls by 1(T). (3)-[Passive]: Increase the Dice '
                    'Category of your Critical Result Extra Dice by 1. '
                    '(4)-[Triggered, 1/Round]: If you are targeted by an '
                    'Attacking Maneuver, you may increase your Combat Rolls by '
                    '2(T) for its duration. (5)-[Triggered/Start of Turn]: If '
                    'below the Injured Health Threshold, enter the next level '
                    'of the Mindful State until the start of your next turn. '
                    '(6)-[Mastery, Permanent]: Super Form gains the Mindful '
                    'Aspect. (7)-[Mastery, Passive]: Increase the bonus '
                    'through the 4th effect by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.dodge],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Muscle Form',
                description: '(1)-[Permanent]: Super Form gains the Bulky '
                    'Aspect. (2)-[Passive]: Increase your Soak Value by 1(T) '
                    'while you possess 2+ Super Stacks. (3)-[Passive]: '
                    'Increase your Surgency by 1(T) for each Super Stack you '
                    'possess. (4)-[Passive]: While at the Healthy Health '
                    'Threshold, double the bonus from the 2nd effect. '
                    '(5)-[Triggered, 1/Round]: If you receive Damage from an '
                    "Opponent's Attacking Maneuver, you may regain Life Points "
                    'equal to your Surgency (halved if suffering the Muscle '
                    'Penalty). (6)-[Mastery, Passive]: If you possess exactly '
                    '2 Super Stacks, ignore the Muscle Penalty while in the '
                    'Healthy Health Threshold.',
              ),
              TraitOption(
                name: 'Raging Form',
                description: '(1)-[Permanent]: Super Form gains the Innate '
                    'State (Raging) Aspect. (2)-[Passive]: Increase your Soak '
                    'Value and Wound Rolls by 1(T). (3)-[Passive]: Halve the '
                    'penalty from scoring a Botch Result. (4)-[Triggered, '
                    '1/Round]: If you are hit by an Attacking Maneuver, you '
                    'may increase its Damage Category by 1 to Basic Attack the '
                    'attacking Character Out-of-Sequence. (5)-[Triggered/Start '
                    'of Turn]: If below the Injured Health Threshold, enter '
                    'the next level of the Raging State until the start of '
                    'your next turn. (6)-[Mastery, Permanent]: Super Form '
                    'gains the Raging Aspect. (7)-[Mastery, Passive]: Your '
                    'Attacking Maneuvers used through the 4th effect gain an '
                    'Energy Charge.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
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
              TraitOption(
                name: 'Small Form',
                description: '(1)-[Automatic/Transform]: Your Size Category '
                    'becomes Small. (2)-[Passive]: Increase your Defense Value '
                    'by 1(T). (3)-[Passive]: Increase your Wound Rolls by 1(T) '
                    'for each Size Category you are below Medium. '
                    '(4)-[Triggered/Power, 1/Round]: Gain a Counter Action, or '
                    'reduce your Size Category by 1 until you leave. '
                    '(5)-[Mastery, Passive]: Increase your Soak Value by 1(T). '
                    '(6)-[Mastery, Passive]: Increase your Strike Rolls by '
                    '1(T) against characters 2+ Size Categories larger than '
                    'you. (7)-[Mastery, Triggered, 1/Round]: If you use a '
                    'Called Shot, increase the Wound Roll by 2(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.defenseValue],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Stylish Form',
                description: '(1)-[Passive]: Set the AMB (PE) of this '
                    'Transformation (not Evolved Stages) equal to the highest '
                    'AMB applied to the other Attributes (after all '
                    'calculations). (2)-[Passive]: Increase your Wound Rolls '
                    'by 1/4 (rounded up) of your Personality Modifier. '
                    '(3)-[Triggered, 1/Round]: While Hyped, if an Ally within '
                    'a Large Sphere AoE targets an Opponent, you may increase '
                    'its Strike and Wound Rolls by 1/4 of your Personality '
                    'Modifier. (4)-[Triggered, 1/Round]: If you use the Hype '
                    'Maneuver, target an Ally within a Large Sphere AoE; that '
                    'Ally may Basic Attack Out-of-Sequence. (5)-[Mastery, '
                    'Passive]: Increase your Strike and Dodge Rolls by 1/4 of '
                    'your Personality Modifier.',
              ),
              TraitOption(
                name: 'Super Saiyan Wannabe',
                description: '(1)-[Permanent]: Super Form gains the Super '
                    'Saiyan Form, Glowing, and Light Dependent Aspects. '
                    '(2)-[Mastery, Passive]: Increase the Dice Score for your '
                    'Duel Clashes by 1(T). (3)-[Mastery, Triggered/Transform, '
                    '1/Encounter]: Use a Ki Surge as an Out-of-Sequence '
                    'Maneuver.',
              ),
              TraitOption(
                name: 'Survival Form',
                description: '(1)-[Permanent]: Super Form gains the Enhanced '
                    'Save (Morale) Aspect. (2)-[Passive]: For each Health '
                    'Threshold you are below, increase your Wound Rolls and '
                    'Surgency by 1(T). (3)-[Passive]: While below the Injured '
                    'Health Threshold, increase your Strike and Dodge Rolls by '
                    '1(T). (4)-[Passive]: Increase the Dice Score of your '
                    'Steadfast Checks by 1. (5)-[1/Encounter]: Use the Surge '
                    'Maneuver (does not count towards its 1/Encounter limit). '
                    '(6)-[Mastery, Passive]: For each Health Threshold you are '
                    'below, increase your Soak Value by 1(T). (7)-[Mastery, '
                    '1/Round, 2/Encounter]: If below the Injured Health '
                    'Threshold, use the Signature Technique Maneuver as an '
                    'Instant Maneuver.',
              ),
              TraitOption(
                name: 'Tank Form',
                description: '(1)-[Permanent]: Super Form gains the Armored '
                    'and Enhanced Save (Corporeal) Aspects. (2)-[Passive]: '
                    'Increase the AMB (TE) of Super Form by 1(T). '
                    "(3)-[Passive]: Increase your Soak Value by 1(T) for each "
                    "Health Threshold you're below. (4)-[Triggered, 1/Round]: "
                    'If you are hit by an Attacking Maneuver you did not '
                    'Counter, increase your Damage Reduction by 1/2 of your '
                    'Soak Value for its duration. (5)-[Mastery, Triggered, '
                    '1/Round]: If you are hit by an Attacking Maneuver you did '
                    'not Counter, make a Clash (Corporeal) against the '
                    'attacking Character; if you win, reduce their Life Points '
                    'by 1/2 of your Soak Value.',
                ambPerTierBonus: {DbuAttribute.tenacity: 1},
              ),
              TraitOption(
                name: 'Unique Form',
                description: '(1)-[Permanent]: Super Form gains the Perfect Ki '
                    'Control and Enhanced Save (Cognitive) Aspects. '
                    '(2)-[Passive]: Apply the effects of the Perfect Ki '
                    'Control Aspect to your Unique Abilities. (3)-[Passive]: '
                    'Increase your Might by 1(T) for any Clashes made through '
                    'the effects of your Unique Abilities. (4)-[Triggered, '
                    '1/Round]: If you win a Clash against an Opponent through '
                    'a Unique Ability, you may Basic Attack that Character '
                    'Out-of-Sequence. (5)-[Triggered, 1/Round]: If you win '
                    'such a Clash and did not trigger the 4th effect, apply a '
                    'stack of Impaired to that Opponent until the start of '
                    'your next turn. (6)-[Mastery, Permanent, Passive]: Select '
                    'a Unique Ability with a TP Cost of 25 or lower to gain '
                    'access to. (7)-[Mastery, Triggered, 1/Encounter]: When '
                    'using a Unique Ability, you may not pay its Ki Point '
                    'Cost.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Your Legend",
        description: "Awakening the dormant strength inherent in your body, "
            "you have gained power once thought unattainable.\n"
            "(1)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain through Legend Realized by 1/4 (rounded up) of your "
            "highest Attribute Modifier.\n"
            "(2)-[Triggered, 1/Round]: If you regain Life and Ki Points "
            "through Legend Realized, you may use a Standard Maneuver with an "
            "Action Cost of 1 Action as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mastered Desire",
      description: "You have incorporated this newfound power into yourself, "
          "making it your own.\n"
          "(1)-[Permanent]: Super Form loses the Draining and Power High "
          "Aspects.\n"
          "(2)-[Permanent]: Super Form gains the Realization and Scaling "
          "(LV2) Aspects.",
    ),
  ),

  // =================================================================== Formation ===
  TransformationDef(
    name: "Formation",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Access to the Hype Maneuver.",
    aspects: [
      "Enhanced Save (Morale)",
      "Battle Uniform",
      "Difficult (LV1)",
      "Long Transformation (LV2)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.standardClothing,
      craftsmanshipGrade: 4,
      qualityNames: ['Durable'],
    ),
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
        name: "Power of Love",
        description: "It's a curious thing; it can make one man weep and "
            "another man sing. It's more than a feeling- it's the power of "
            "love.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select and gain access to a Form of Love while in "
            "this Transformation (choose below).\n"
            "(2)-[Passive]: You may use your Personality Modifier as the Damage "
            "Attribute for Attacking Maneuvers.\n"
            "(3)-[Passive]: Increase your Surgency by 1/4 (rounded up) of your "
            "Personality Modifier.\n"
            "(4)-[Passive]: While you are Hyped, increase your Damage Reduction "
            "and Combat Rolls by 1(T).\n"
            "(5)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 "
            "Action, target a willing Ally. That Ally may use the Empower "
            "Maneuver as an Out-of-Sequence Maneuver as if they spent 2 "
            "Actions, but they must target you.\n"
            "(6)-[Triggered]: If an Ally gives an amount of Ki Points that "
            "matches or exceeds your Personality Modifier through the Empower "
            "Maneuver, increase that Ally's Combat Rolls by 1/4 (rounded up) "
            "of your Personality Modifier until the end of their turn or start "
            "of their next turn.\n"
            "(7)-[Triggered, 1/Round]: If you are given a number of Ki Points "
            "that match or exceed your Personality Modifier through the "
            "Empower Maneuver, you may use the Hype Maneuver or Power Up "
            "Maneuver as an Out-of-Sequence Maneuver.",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Form of Love',
            options: [
              TraitOption(
                name: 'Powerful Love',
                description: 'Your love is resilient and endures every trial. '
                    '(1)-[Passive]: Formation gains the Armored and Enhanced '
                    'Save (Corporeal) Aspects. (2)-[Passive]: While Hyped, '
                    'increase your Wound Rolls and Soak Value by 1(T). '
                    '(3)-[Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver, you may spend up to 3 Love stacks to apply an '
                    'equal number of Energy Charges. (4)-[Triggered, 1/Round]: '
                    'If you take Damage from an Attacking Maneuver you did not '
                    'Counter, you may spend a stack of Love to reduce the '
                    'Damage by your Personality Modifier.',
              ),
              TraitOption(
                name: 'Wild Love',
                description: 'Flexible and savage, your love knows no '
                    'restraint. (1)-[Passive]: Formation gains the High Speed '
                    'and Enhanced Save (Impulsive) Aspects. (2)-[Passive]: '
                    'While Hyped, increase your Defense Value by 1(T). '
                    '(3)-[Triggered, 1/Round]: If an Opponent uses the Exploit '
                    'Maneuver, you may spend a stack of Love to have '
                    'pre-emptively not triggered it (they regain any Counter '
                    'Actions or Ki Points spent). (4)-[Triggered, 1/Round]: If '
                    'you are hit by an Attacking Maneuver you did not Counter, '
                    'before their Wound Roll you may spend a stack of Love to '
                    'reroll your Dodge Roll.',
              ),
              TraitOption(
                name: 'Striking Love',
                description: 'Methodical and efficient — your love is '
                    'inescapable. (1)-[Passive]: Formation gains the Perfect '
                    'Ki Control and Enhanced Save (Cognitive) Aspects. '
                    '(2)-[Passive]: While Hyped, increase your Awareness by '
                    '1(T). (3)-[Triggered, 1/Round]: If you use an Attacking '
                    'Maneuver, you may spend a stack of Love to make it a '
                    'Called Shot. (4)-[Triggered, 1/Round]: If you miss an '
                    'Opponent with an Attacking Maneuver, you may spend a '
                    'stack of Love to reroll your Strike Roll (AoE: only for '
                    'hitting that one Opponent).',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Storm of Love",
        description: "You are able to gather pure love within you, much like "
            "others do with energy, allowing you to turn it into fighting "
            "power.\n"
            "(1)-[Triggered, Resource]: If you are given Ki Points through the "
            "Empower Maneuver (except from a Minion), gain stacks of Love "
            "based on the amount of Actions spent (max. 3). Your maximum "
            "number of Love stacks is 3.\n"
            "(2)-[1/Round, Ruling]: As an Instant Maneuver during your turn, "
            "spend a stack of Love to target an Opponent. Make a Clash "
            "(Morale) against that Opponent. If you win, that Opponent becomes "
            "'Love-Struck' until the start of your next turn.\n"
            "(3)-[Passive]: Love-Struck Opponents have their Combat Rolls "
            "reduced by 1/4 (rounded up) of your Personality Modifier.\n"
            "(4)-[1/Round]: If you would spend a Counter Action for any "
            "reason, you may spend a stack of Love instead.\n"
            "(5)-[Triggered/Defeat]: Spend 3 stacks of Love to use a Healing "
            "Surge. Increase the amount of Life Points you gain from this "
            "Healing Surge by your Personality Modifier.\n"
            "(6)-[Triggered/Power, 1/Encounter]: Increase your Personality "
            "Modifier by 1(T) for each stack of Love you possess until the "
            "start of your next turn. This increase cannot be larger than the "
            "Attribute Modifier Bonus of this Transformation.\n"
            "Battle Uniform — Standard Clothing, Craftsmanship Grade 4. "
            "Lovely Clothes: Increase your Soak Value and Wound Rolls by 1/2 "
            "(rounded up) of your Apparel Bonus. Durable: Increase the maximum "
            "Break Value for this piece of Apparel by 3. Combat Ready: "
            "Increase your Strike and Dodge Rolls by 1/2 (rounded up) of your "
            "Apparel Bonus.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Source of Love",
        description: "Your love grows stronger, allowing you to tap into more "
            "of its power.\n"
            "(1)-[Permanent]: Formation loses M Levels of the Long "
            "Transformation Aspect.\n"
            "(2)-[Permanent]: Formation gains the Realization Aspect and M "
            "levels of the Scaling Aspect.\n"
            "(3)-[Constant]: When you use the Transformation Maneuver to enter "
            "this Transformation, this Transformation may gain up to M levels "
            "of the Long Transformation Aspect for the duration of that "
            "Maneuver. For each level added, upon successfully entering this "
            "Transformation, gain an equal amount of Love stacks.\n"
            "(4)-[Triggered/Start of Turn]: Gain a stack of Love.",
      ),
      TransformationTrait(
        name: "Faith in Love",
        description: "The depths of your love are boundless, allowing you to "
            "draw forth the greatest strength of all.\n"
            "(1)-[Permanent]: The Craftsmanship Grade for this "
            "Transformation's Battle Uniform becomes 5 and it gains the "
            "Resolute Belief Apparel Quality.\n"
            "(2)-[Triggered, 1/Round]: If an Ally gives an amount of Ki Points "
            "that matches or exceeds your Personality Modifier through the "
            "Empower Maneuver, regain Life Points equal to your Personality "
            "Modifier.\n"
            "(3)-[Triggered, 1/Encounter]: If an Ally gives an amount of Ki "
            "Points that matches or exceeds your Personality Modifier through "
            "the Empower Maneuver, gain an Action.",
      ),
    ],
  ),

  // ============================================================= Lovely Formation ===
  TransformationDef(
    name: "Lovely Formation",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Formation). Stress Test "
        "Requirement: +9.",
    aspects: ["Growth (LV3)", "Scaling (LV2)", "Pinnacle (LV1)", "Peaked"],
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
        name: "Lovely Love",
        description: "The depths of your love are boundless, allowing you to "
            "draw forth the greatest strength of all.\n"
            "(1)-[Acclimated]: If the Original Form is fully Mastered, treat "
            "your Size Category as Large for the effects of Punching Up and "
            "for calculating your Defense Value.\n"
            "(2)-[Constant]: If you gain 3 stacks of Love in one Combat Round, "
            "you may use the Transformation Maneuver to enter Lovely Formation "
            "as an Out-of-Sequence Maneuver upon obtaining the third stack of "
            "Love.\n"
            "(3)-[Passive]: Your maximum number of Love stacks becomes 9001.\n"
            "(4)-[Passive]: Instead of targeting a single Ally with the 5th "
            "effect of Power of Love, you may target all Allies (that are not "
            "Minions).\n"
            "(5)-[Passive]: If you have 3+ stacks of Love, increase the Dice "
            "Category of your Energy Charges by 1 Category.\n"
            "(6)-[Automatic]: At the end of your turn, if you possess more "
            "than 3 stacks of Love, set your number of Love stacks to 3.\n"
            "(7)-[Triggered/Power, 1/Round]: If you have 3+ stacks of Love, "
            "enter the Surging State until the end of your turn. If you do, "
            "ignore the 2nd effect of the Surging State.",
      ),
      TransformationTrait(
        name: "Massive Love (Legendary Trait)",
        description: "Your love has grown to encompass all living things, "
            "granting you greater power.\n"
            "(1)-[Passive]: During a turn in which you've gained Ki Points "
            "from an Ally using the Empower Maneuver with you as the target, "
            "increase your Wound Rolls by 1(T).\n"
            "(2)-[Triggered]: If you regain Ki Points through the effects of "
            "the Empower Maneuver used by an Ally, you may use the Energy "
            "Charge Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ============================================================= Super Formation ===
  TransformationDef(
    name: "Super Formation",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Unique (Formation). Mastered Formation. "
        "Tier of Power Requirement: Same as Original Form. Stress Test "
        "Requirement: +5.",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.personality:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Super Love",
        description: "Your pure love has granted you the ability to fly, "
            "ascending to the heavens.\n"
            "(1)-[Passive]: Gain access to the Winged Beast Bestial Trait "
            "while you are in this Transformation.\n"
            "(2)-[Passive]: While Hyped, increase your Combat Rolls by 1/4 "
            "(rounded up) of your Personality Modifier.\n"
            "(3)-[Passive]: Increase your maximum number of Love Stacks by "
            "1.\n"
            "(4)-[Passive]: Depending on your Form of Love, gain one of the "
            "following effects: Powerful Love [Triggered, 1/Round]: if you "
            "apply an Energy Charge through the 3rd effect of Powerful Love, "
            "increase that Attacking Maneuver's Damage Category by 1; Wild "
            "Love [Triggered, 1/Round]: if you successfully dodge an Attacking "
            "Maneuver, gain a stack of Love; Striking Love [Triggered, "
            "1/Round]: if you hit an Opponent with a Called Shot, gain a stack "
            "of Love.",
      ),
    ],
  ),

  // ============================================================ Final Mode Change ===
  TransformationDef(
    name: "Final Mode Change",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Mode Change). Fully Mastered "
        "Mode Change. Stress Test Requirement: +9.",
    aspects: ["Pinnacle (LV1)"],
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
        name: "Ultimate Defender",
        description: "You are the champion of the people, standing between the "
            "innocent and all who seek to harm them.\n"
            "(1)-[Automatic]: Upon entering this Transformation, enter the "
            "Ultimate Mode, ignoring the 4th effect of Transformation!\n"
            "(2)-[Passive]: You cannot leave the Ultimate Mode while in this "
            "Transformation.\n"
            "(3)-[Passive]: The Attribute Modifiers (before applying any "
            "Attribute Modifier Bonuses from Transformations) of your "
            "AG/FO/TE/IN/MA become equal to the Attribute Modifier of your "
            "Personality Attribute.\n"
            "(4)-[Triggered/Start of Combat Round]: Trigger effects as if you "
            "entered a Mode.\n"
            "(5)-[Triggered/Defeated]: Regain Life Points equal to triple your "
            "Personality Modifier.\n"
            "Ultimate Mode (Personality) — As your final trump card, this "
            "mode combines the best of all your other modes' abilities. "
            "(1)-[Passive]: Final Mode Change gains the Enhanced Save (All), "
            "High Speed, Armored, and Perfect Ki Control Aspects. "
            "(2)-[Passive]: All of your Signature Techniques gain 1 Energy "
            "Charge. (3)-[Passive]: Ignore the penalty from Long Range. "
            "(4)-[Passive]: You are considered to be in every Mode for the "
            "effects of Modular Apparel. (5)-[1/Round]: You may use any "
            "Standard Maneuver with an Action Cost of 1 Action as an Instant "
            "Maneuver. (6)-[1/Round]: You may use the Defend Maneuver without "
            "spending a Counter Action.",
      ),
      TransformationTrait(
        name: "Change Recovery (Legendary Trait)",
        description: "Shifting between the various modes of your Transformation "
            "not only allows you to take a momentary breather, but also allows "
            "you to adapt your tactics to fit the situation before you.\n"
            "(1)-[Passive]: Increase your Surgency by 1(T).\n"
            "(2)-[Triggered, 1/Round]: Upon entering a Mode, regain 3(bT) Life "
            "and Ki Points.\n"
            "(3)-[Triggered, 1/Round]: Upon entering a Mode, you may remove a "
            "Combat Condition you are suffering from (except Pinned, "
            "Suffocating, Stress Exhaustion, or Transfigured).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Super Ultimate Mode",
      description: "You have surpassed even the greatest heroes, backed by the "
          "hopes and dreams of all those you stand to protect.\n"
          "(1)-[Permanent]: Final Mode Change gains the Scaling (LV2) "
          "Aspect.\n"
          "(2)-[Passive]: While you are below the Critical Health Threshold, "
          "increase all of your Combat Rolls and Soak Value by 1(T).\n"
          "(3)-[Triggered, 1/Round]: Upon entering a Mode, you may choose to "
          "use one of the following effects: use the Movement Maneuver as an "
          "Out-of-Sequence Maneuver; use the Basic Attack Maneuver as an "
          "Out-of-Sequence Maneuver; gain 1 Counter Action; or use the Hype "
          "Maneuver as an Out-of-Sequence Maneuver.\n"
          "(4)-[Triggered/Defeated, 1/Encounter]: Regain Life Points equal to "
          "twice your Personality Modifier. Then, you may trigger any effects "
          "that occur when you enter a Mode (ignoring any [1/Round] "
          "limitations).",
    ),
  ),

  // ======================================================================= Beast ===
  TransformationDef(
    name: "Beast",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Apoplectic Beast Talent.",
    aspects: [
      "Enhanced Save (All)",
      "Innate State (Raging)",
      "Raging",
      "Glowing",
      "Power High (LV3)",
      "Difficult (LV1)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Snapping Fury",
        description: "Amplified by a burning rage you can't completely "
            "control, your power awakens like a savage, feral monster.\n"
            "(1)-[Passive]: Increase the level of your Raging State by your "
            "number of Power stacks.\n"
            "(2)-[Passive]: For every level of the Raging State you are in "
            "after the second, increase the Dice Category of your Energy "
            "Charges by 1 Category.\n"
            "(3)-[Passive]: For every level of the Raging State you are in "
            "after the first, increase your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(4)-[Passive]: For every level of the Raging State you are in "
            "after the first, increase your Strike and Dodge Rolls by 1(T)\n"
            "(5)-[Passive]: For every level of the Raging State you are in "
            "after the first, increase the Natural Result of your Wound Rolls "
            "by 1.\n"
            "(6)-[Triggered/Power]: Regain 2L(T) Ki Points, where L is equal "
            "to your current level of the Raging State.\n"
            "(7)-[Automatic/Start of Turn]: You lose all stacks of Power.",
      ),
      TransformationTrait(
        name: "Power Awoken by Rage",
        description: "Your all-consuming fury takes over, pushing you to "
            "greater and greater heights as you spiral further and further out "
            "of control.\n"
            "(1)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(2)-[Passive]: Double the maximum reduction of Life Points "
            "through the 2nd effect of the Apoplectic Beast Talent.\n"
            "(3)-[Passive]: While you are in the 3rd or higher level of the "
            "Raging State, Beast gains the Armored Aspect.\n"
            "(4)-[Passive]: Increase the Strike Rolls of your Attacking "
            "Maneuvers by 1(T) if they possess at least 1 Energy Charge.\n"
            "(5)-[Triggered, 1/Round]: If you are hit by an Attacking "
            "Maneuver, gain 2L(T) Damage Reduction for the duration of that "
            "Attacking Maneuver, where L is equal to your current level of the "
            "Raging State.\n"
            "(6)-[Triggered, 1/Encounter]: If you trigger the 3rd effect of "
            "Caged Beast, enter the Surging State until you leave this "
            "Transformation.",
      ),
      TransformationTrait(
        name: "Caged Beast (Legendary Trait)",
        description: "Despite your calm outer appearance, the fury and turmoil "
            "within you never seems to cease, and can be brought to bear at a "
            "moment's notice.\n"
            "(1)-[Passive]: Double the bonus from the 1st effect of the Angry "
            "level of the Raging State.\n"
            "(2)-[Triggered, 1/Round]: If you are in the Raging State and you "
            "use the Energy Charge Maneuver, after concluding that Maneuver, "
            "you may use the Energy Charge Maneuver again as an Out-of-Sequence "
            "Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: If an Ally (except a Minion) is "
            "Defeated by an Opponent's Attacking Maneuver: if Not in Beast, "
            "use the Transformation Maneuver as an Out-of-Sequence Maneuver to "
            "enter Beast, then increase your Tier of Power by 1 until the end "
            "of your turn; if In Beast, use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver, then increase your Tier of Power by 1 "
            "until the end of your turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Ready to Snap",
        description: "Your rage grows even stronger, but so too does your "
            "ability to control it.\n"
            "(1)-[Permanent]: Beast loses the Power High Aspect and gains M "
            "levels of the Scaling Aspect.\n"
            "(2)-[Passive]: You gain an additional stack of Power for your "
            "uses of the Power Up Maneuver.\n"
            "(3)-[Passive]: Increase your maximum number of Power stacks by "
            "1.",
      ),
      TransformationTrait(
        name: "Uncaged Beast",
        description: "Your overpowering rage grants you such intense strength "
            "that you overwhelm all opponents.\n"
            "(1)-[Permanent]: If your base Tier of Power is 6+, Beast has its "
            "Attribute Modifier Bonus (IN) increased by 1(T).\n"
            "(2)-[Passive]: You gain access to the Uncaged Rage level of the "
            "Raging State (Level 4): all Attacking Maneuvers have their Damage "
            "Category increased by 1; 1/Round you may use the Energy Charge "
            "Maneuver as an Instant Maneuver.",
      ),
    ],
  ),

  // ==================================== Dragon Shell line (Shadow Dragon; Reinforced
  // Shell Null Stage + Shattered Shell Stage 1).
  // ============================================ Dragon Shell: Reinforced Shell (0) ===
  TransformationDef(
    name: "Reinforced Shell",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Shadow Dragon",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: "Dragon Shell line, Null Stage. Draconic Physique Racial "
        "Trait.",
    transformationLine: "Dragon Shell",
    stage: 0,
    aspects: ["Enhanced Save (Corporeal)", "Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Protective Shell",
        description: "The hardened scales that cover your body serve as "
            "effective safeguards against injury.\n"
            "(1)-[Passive]: Increase the Apparel Bonus of your Dragon Scales "
            "by 1(bT).\n"
            "(2)-[Triggered, 1/Round]: If you are hit by an Attacking "
            "Maneuver, you may spend up to 3 stacks of Negative Energy to "
            "increase your Damage Reduction by 1(T) for each stack spent for "
            "the duration of that Attacking Maneuver.\n"
            "(3)-[Triggered/Defeated]: You may use the Transformation Maneuver "
            "as an Out-of-Sequence Maneuver to attempt and enter Shattered "
            "Shell. Apply the effects of Legend Realized from entering "
            "Shattered Shell before you are defeated.",
      ),
    ],
  ),

  // ============================================= Dragon Shell: Shattered Shell (1) ===
  TransformationDef(
    name: "Shattered Shell",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Shadow Dragon",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Draconic Physique Racial Trait.",
    transformationLine: "Dragon Shell",
    stage: 1,
    aspects: [
      "Enhanced Save (Impulsive/Morale)",
      "Prelude",
      "Difficult (LV1)",
      "Draining (LV2)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Unleashed Dragon",
        description: "Giving up the protection of your draconic hide, you "
            "transform that lost defense into speed and power.\n"
            "(1)-[Passive]: Halve the bonus to your Damage Reduction from your "
            "Dragon Scales.\n"
            "(2)-[Passive]: Your Dragon Scales gain the Combat Ready and "
            "Enchanted Apparel Qualities without occupying any Quality "
            "Slots.\n"
            "(3)-[Passive]: Increase your Speeds by 1/2 of the Apparel Bonus "
            "of your Dragon Scales.\n"
            "(4)-[Passive]: Increase the Natural Result of your Strike and "
            "Wound Rolls by 1 for any Attacking Maneuver that targets an "
            "Opponent suffering from the Impaired Combat Condition.\n"
            "(5)-[Triggered, 1/Round]: If you deal Damage to an Opponent with "
            "an Attacking Maneuver, make a Clash (Morale) against that "
            "Opponent. If you win, they gain a stack of the Impaired Combat "
            "Condition until the start of your next turn.\n"
            "(6)-[Triggered, 1/Encounter]: If you inflict the Impaired Combat "
            "Condition to an Opponent, they also gain a stack of the Broken "
            "Combat Condition until the start of your next turn.",
      ),
      TransformationTrait(
        name: "Karmic Pulse",
        description: "Your overwhelming strength effortlessly affects the "
            "world around you, bending reality in your favor.\n"
            "(1)-[Automatic/Transform, Ruling]: Select an Attribute. That "
            "Attribute becomes your 'Karmic Attribute' until you leave this "
            "Transformation.\n"
            "(2)-[Ruling]: A 'Karmic Clash' is a Clash that uses your Karmic "
            "Attribute against the highest Attribute Modifier of any other "
            "character involved.\n"
            "(3)-[Passive]: While you have 2+ stacks of Power, increase your "
            "Karmic Attribute by 1(T).\n"
            "(4)-[Passive]: An Opponent suffering from the Broken Combat "
            "Condition is also considered to be suffering from the Impaired "
            "Combat Condition for your effects.\n"
            "(5)-[Triggered]: If you gain 4+ stacks of Negative Energy through "
            "the 1st effect of Negative Ki, make a Karmic Clash against all "
            "Opponents within a Large Sphere AoE. If you win against an "
            "Opponent, reduce their Life Points by your Karmic Attribute.\n"
            "(6)-[Triggered]: If you inflict the Impaired Combat Condition to "
            "an Opponent, make a Karmic Clash against that Opponent. If you "
            "win, reduce their Life Points by your Karmic Attribute.\n"
            "(7)-[Triggered/Power, 1/Encounter]: Gain a stack of Negative "
            "Energy, then trigger the 5th effect of Karmic Pulse as if you "
            "gained 4 stacks of Negative Energy through the 1st effect of "
            "Negative Ki.",
        // (1) Select the Attribute that becomes your 'Karmic Attribute'. It is
        // used only in Karmic Clashes (situational), so this records the choice
        // rather than feeding the general sheet.
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Karmic Attribute',
            options: [
              TraitOption(
                name: 'Agility',
                description: 'Agility becomes your Karmic Attribute.',
              ),
              TraitOption(
                name: 'Force',
                description: 'Force becomes your Karmic Attribute.',
              ),
              TraitOption(
                name: 'Tenacity',
                description: 'Tenacity becomes your Karmic Attribute.',
              ),
              TraitOption(
                name: 'Insight',
                description: 'Insight becomes your Karmic Attribute.',
              ),
              TraitOption(
                name: 'Magic',
                description: 'Magic becomes your Karmic Attribute.',
              ),
            ],
          ),
        ],
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Draconic Ascension",
        description: "Your draconic growth gives you newfound control over "
            "your energy, sending your overall combat strength soaring to new "
            "heights.\n"
            "(1)-[Permanent]: Shattered Shell loses M levels of the Draining "
            "Aspect and gains the High Speed Aspect.\n"
            "(2)-[Permanent]: Shattered Shell gains the Realization Aspect "
            "and M levels of the Scaling Aspect.\n"
            "(3)-[Passive]: Increase your Combat Rolls against an Opponent "
            "suffering from the Impaired Combat Condition by 1(T).\n"
            "(4)-[Triggered, 1/Round]: If you would inflict the Impaired "
            "Combat Condition to an Opponent, you may inflict the Broken "
            "Combat Condition instead (for the same duration as the Impaired "
            "Combat Condition).",
      ),
      TransformationTrait(
        name: "Accustomed to a Shell-less Life",
        description: "You've learned to tap into the speed and power you need "
            "without sacrificing defense, making you a formidable enemy.\n"
            "(1)-[Permanent]: Shattered Shell gains the Natural (LV1) "
            "Aspect.\n"
            "(2)-[Passive]: Ignore the 1st effect of Unleashed Dragon.\n"
            "(3)-[1/Round]: You may use the Power Up Maneuver as an Instant "
            "Maneuver.",
      ),
    ],
  ),

  // =============================== Full Power Boost line (upgrades Power Boost to a
  // Legendary Line; Powerful Null Stage + Super Full Power Boost Stage 2).
  // ================================================ Full Power Boost: Powerful (0) ===
  TransformationDef(
    name: "Powerful",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 14,
    prerequisiteText: "Full Power Boost line, Null Stage. Fully Mastered Power "
        "Boost (this Prerequisite cannot be replaced).",
    transformationLine: "Full Power Boost",
    stage: 0,
    aspects: ["Enhanced Save (Corporeal)", "Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Greatest Power",
        description: "Your strength is unrivaled, allowing you to constantly "
            "raise your power even further.\n"
            "(1)-[Permanent]: Power Boost (or any of its Variants) becomes the "
            "first Stage of the Full Power Boost Transformation Line, becomes "
            "a Legendary Form (with the Legendary Trait below), has its Stress "
            "Test Requirement increased by 9 and has its Attribute Modifier "
            "Bonuses (AG/FO/TE/IN/MA) increased by 1(T).\n"
            "(2)-[Passive]: While you have no stacks of Power, this "
            "Transformation gains the Perfect Ki Control Aspect.\n"
            "(3)-[Passive]: While you have 1+ stacks of Power, increase your "
            "Soak Value and Defense Value by 1(T).\n"
            "(4)-[Passive]: While you have 2+ stacks of Power, increase your "
            "Wound Rolls and Might by 1(T).",
      ),
      TransformationTrait(
        name: "Building Power (Power Boost Legendary Trait)",
        description: "Your pure strength continues to grow as you ignore all "
            "shortcuts to become the strongest.\n"
            "(1)-[Passive]: While you have 3+ stacks of Power, increase your "
            "Combat Rolls by 1(T).\n"
            "(2)-[Triggered/Power]: Regain 5(bT) Capacity.\n"
            "(3)-[Triggered/Start of Turn]: If you have no stacks of Power, "
            "regain 2(bT) Ki Points.",
      ),
    ],
  ),

  // ======================================= Full Power Boost: Super Full Power (2) ===
  TransformationDef(
    name: "Super Full Power Boost",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Fully Mastered Power Boost (this Prerequisite cannot be "
        "replaced).",
    transformationLine: "Full Power Boost",
    stage: 2,
    aspects: [
      "Enhanced Save (All)",
      "Glowing",
      "Bursting",
      "Straining",
      "Exhausting",
      "Draining (LV*)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Power Surpassing Limits",
        description: "Your strength surpasses all comers, proving once and for "
            "all that you are unrivaled.\n"
            "(1)-[Passive]: While you are Power Spiked, increase your Tier of "
            "Power by 1 (see — Breakthrough).\n"
            "(2)-[Passive]: While you are Power Spiked, this Transformation has "
            "the Armored Aspect.\n"
            "(3)-[Passive]: This Transformation's level of the Draining Aspect "
            "is equal to your number of Power stacks.\n"
            "(4)-[Passive]: Remove the maximum from the 5th effect of Improved "
            "Power.\n"
            "(5)-[Passive]: Increase the amount of Power stacks you gain from "
            "the Power Up Maneuver by 1.\n"
            "(6)-[Passive]: Depending on which Transformation is the 1st Stage "
            "of this Transformation, gain one of the following:\n"
            "Power Boost [Passive]: You may enter both the Superior and "
            "Surging State through the 4th effect of Overflowing Power instead "
            "of having to pick one.\n"
            "Android Power [Passive]: Increase the Dice Category of your "
            "Energy Charges by 1 Category.\n"
            "Mortal Power [Passive]: While you are in the Healthy Health "
            "Threshold, halve the amount of Ki Points lost from the Draining "
            "Aspect.\n"
            "Cerealian Power [Passive]: The 2nd effect of Initial Cerealian "
            "Power loses its [1/Round] Keyword.\n"
            "Earthling Power [Passive]: While you are below the Bruised Health "
            "Threshold, halve the amount of Ki Points lost from the Draining "
            "Aspect.\n"
            "Glass Power [Passive]: Increase the Dice Category of your Energy "
            "Charges by 1 Category.\n"
            "Konatsian Power [Triggered/Power, 1/Round]: If you are below the "
            "Injured Health Threshold, gain 1 Tension.\n"
            "Majin Power [Passive]: Any stack of Power spent through the 3rd "
            "effect of Paranormal Power is not lost until the start of your "
            "next turn.\n"
            "Namekian Power [Passive]: Increase the amount of Life Points "
            "regained from a Healing Surge by 1d10(T).\n"
            "Neko Power [Passive]: Apply an additional Energy Charge through "
            "the 3rd effect of Copycat Power.\n"
            "Negative Power [Triggered/Power, 1/Round]: Make a Morale Clash "
            "against all Opponents within your Negative Zone; if you win, they "
            "gain the Drained Combat Condition until the start of your next "
            "turn.\n"
            "Neo Power [Triggered/Power]: Gain 1 Revenge Point.\n"
            "Shinjin Power [Passive]: Increase the amount of Life and Ki "
            "Points you regain through Combat Recovery by 1d6(T).\n"
            "Spiritual Power [Passive]: Increase the Combat Rolls of all "
            "Allies within your Transference Zone by 1(T) while you are Power "
            "Spiked.",
      ),
      TransformationTrait(
        name: "Power Spike (Legendary Trait)",
        description: "No matter how strong your opponent is, you are stronger, "
            "and you will prove it, no matter what.\n"
            "(1)-[Ruling]: If you possess your maximum number of Power stacks, "
            "you are 'Power Spiked'.\n"
            "(2)-[Passive]: While you are Power Spiked, increase your Combat "
            "Rolls and Soak Value by 1(T).\n"
            "(3)-[Triggered, 1/Round]: If you are Power Spiked and you deal "
            "Damage to an Opponent with an Attacking Maneuver, that Opponent "
            "gains a stack of the Broken Combat Condition until the start of "
            "your next turn.\n"
            "(4)-[Triggered, 1/Round]: If you are Power Spiked and you receive "
            "Damage from an Opponent's Attacking Maneuver, you may reduce that "
            "Damage (after all calculations) by 1(T) for each stack of Power "
            "you possess.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Instead of gaining a stack of "
            "Power through this use of the Power Up Maneuver, maximize your "
            "Power stacks.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mastery of Pure Power",
      description: "Any who cannot offer you a proper challenge do not deserve "
          "to stand before you; you will crush them before they can offer any "
          "futile resistance.\n"
          "(1)-[Permanent]: Super Full Power Boost loses the Straining and "
          "Exhausting Aspects. Additionally, you can choose if you apply the "
          "effects of the Bursting Aspect or not upon entering this "
          "Transformation.\n"
          "(2)-[Passive]: Increase your Combat Rolls by 1/2 (rounded up) of "
          "the Apparel Bonus for the piece of Apparel destroyed through the "
          "Bursting Aspect upon entering this Transformation.\n"
          "(3)-[Passive]: Increase your maximum number of Power stacks by 1.\n"
          "(4)-[Passive]: Halve the amount of Draining levels gained through "
          "the 3rd effect of Power surpassing Limits.\n"
          "(5)-[Triggered, 1/Encounter]: If you are Power Spiked and would "
          "lose any number of Power stacks, you may spend 2(bT) Ki Points for "
          "each stack of Power you would lose to not lose those stacks.\n"
          "(6)-[Triggered/Power, 1/Encounter]: If you are Power Spiked, "
          "increase your Tier of Power by 1 until the end of your turn.",
    ),
  ),

  // ==================================== Meta Form line (Mechanized Body Null Stage +
  // Gleaming Metal Stage 1).
  // ================================================ Meta Form: Mechanized Body (0) ===
  TransformationDef(
    name: "Mechanized Body",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 8,
    prerequisiteText: "Meta Form line, Null Stage. You do not possess any "
        "Factor Traits from Cybernetic Enhancement (except through a "
        "Transformation in the Meta Form line).",
    transformationLine: "Meta Form",
    stage: 0,
    aspects: ["Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Mechanical Body",
        description: "Your body has been reconstructed from the ground up, "
            "transformed into metal and cybernetics, even though you remain "
            "fundamentally yourself.\n"
            "(1)-[Passive]: Gain access to the Life Support and Nanomachine "
            "Repair Factor Traits of Cybernetic Enhancement.\n"
            "(2)-[Permanent]: You cannot leave this Transformation except to "
            "enter a different Stage of this Transformation Line.\n"
            "(3)-[Triggered, 1/Encounter]: If you stop being Defeated for any "
            "reason, you may use a Surge of your choice as an Out-of-Sequence "
            "Maneuver.",
      ),
    ],
  ),

  // ================================================= Meta Form: Gleaming Metal (1) ===
  TransformationDef(
    name: "Gleaming Metal",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "You do not possess the Cybernetic Enhancement Factor or "
        "Cybernetic Upgrade Awakening.",
    transformationLine: "Meta Form",
    stage: 1,
    aspects: ["Enhanced Save (Cognitive/Corporeal)", "Natural (LV1)"],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Inexhaustible Machine",
        description: "Your new cybernetic body possesses limitless energy and "
            "stamina, allowing you to keep fighting indefinitely.\n"
            "(1)-[Passive]: Gain access to the Emergency Energy Supplies "
            "Factor Trait of Cybernetic Enhancement.\n"
            "(2)-[Passive]: While in the Healthy Health Threshold, increase "
            "your Damage Reduction by 2(T).\n"
            "(3)-[Passive]: While in the Healthy Health Threshold, this "
            "Transformation has the Armored Aspect.\n"
            "(4)-[1/Round]: If you are in the Healthy Health Threshold, you "
            "may use a Counter Maneuver without spending a Counter Action.\n"
            "(5)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 "
            "Action, use a Surge (Ki Surge if >50% Life, Healing Surge if "
            "<=50%).\n"
            "(6)-[Triggered, 1/Round]: If you use the Direct Hit or Guard "
            "Option of the Defend Maneuver while in the Healthy Health "
            "Threshold, double the bonus from the second effect of "
            "Inexhaustible Machine for the duration of that Attacking "
            "Maneuver.",
      ),
      TransformationTrait(
        name: "Overloading Circuits",
        description: "As your mechanical body grows closer and closer to "
            "defeat, more and more of your destructive power is unleashed.\n"
            "(1)-[Passive]: For each Health Threshold you are below, increase "
            "the Dice Category of your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(2)-[Passive]: While below the Bruised Health Threshold, you have "
            "access to the Signature Amplifier Factor Trait of Cybernetic "
            "Enhancement.\n"
            "(3)-[Passive]: While below the Bruised Health Threshold, increase "
            "your Strike Rolls and Wound Rolls by 1(T) and 2(T) "
            "respectively.\n"
            "(4)-[1/Round]: If you are below the Injured Health Threshold, you "
            "may use the Energy Charge Maneuver as an Instant Maneuver.\n"
            "(5)-[Triggered, 1/Encounter]: If you use the Energy Charge "
            "Maneuver while below the Critical Health Threshold, you may use "
            "the Energy Charge Maneuver again as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Mechanical Acclimation",
      description: "You have taken full control over your new mechanical body, "
          "fully accepting it as your own now.\n"
          "(1)-[Permanent]: Gleaming Metal gains the Scaling (LV2) and "
          "Realization Aspects.\n"
          "(2)-[Constant]: If you are targeted by an Attacking Maneuver while "
          "in the Mechanized Body Stage of Meta Form, you may use the "
          "Transformation Maneuver as an Out-of-Sequence Maneuver to enter the "
          "Gleaming Metal Transformation.\n"
          "(3)-[Triggered, 1/Round]: When using the Signature Technique "
          "Maneuver, you may spend any number of Life Points up to 1/4 of your "
          "Max Capacity to increase the Ki Wager of that Attacking Maneuver by "
          "an equal amount. If this reduction knocks you through a Health "
          "Threshold, you do not suffer from Reduced Momentum and "
          "automatically succeed at your Steadfast Check.",
    ),
  ),

  // ================================ Grudge Amplifier line (Neo-Tuffle; Computer Form
  // Null Stage + Humanoid Battle Form Stage 1).
  // ========================================= Grudge Amplifier: Computer Form (0) ===
  TransformationDef(
    name: "Computer Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Neo-Tuffle",
    tierOfPowerRequirement: 1,
    stressTestRequirement: 4,
    prerequisiteText: "Grudge Amplifier line, Null Stage. Hatred Embodiment "
        "Subrace.",
    transformationLine: "Grudge Amplifier",
    stage: 0,
    aspects: [
      "Natural (LV2)",
      "Growth (LV2)",
      "Absorbed Apparel",
      "Peaked",
    ],
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Processed Grudge",
        description: "Grudge Data recorded. Verifying. Producing Ghost "
            "Warrior. Exterminate. Exterminate!\n"
            "(1)-[Passive]: While in the Computer Form Transformation, you "
            "cannot use the Movement Maneuver. Additionally, you cannot move "
            "through any of your own effects.\n"
            "(2)-[Passive]: While in the Computer Form Transformation, reduce "
            "the Damage Category of all Attacking Maneuvers that target you to "
            "Standard for the sake of your Damage Calculation.\n"
            "(3)-[Passive]: While in the Computer Form Transformation, you "
            "cannot use the Grapple Maneuver, Terrain Lift Maneuver, or Throw "
            "Maneuver, and you cannot equip any Apparel, Accessories, Weapons, "
            "or use Armed Attacking Maneuvers.\n"
            "(4)-[Passive]: While in the Computer Form Transformation, you are "
            "Unnatural.\n"
            "(5)-[Addendum]: Ghost Warriors are Special Minions created from "
            "the recordings of other Characters at their time of death. To "
            "create one you need Ghost Warrior Data — a record of everything a "
            "Character is (Race, Subrace, Factors, Talents, Transformations, "
            "Apparel, Weapons, Signature Techniques, Unique Abilities, etc.) "
            "at the time it was recorded. Each Ghost Warrior's Power Level "
            "equals yours, gaining/losing Character Perks accordingly (your "
            "ARC chooses gained Perks; lost ones return upon reaching that "
            "Power Level). When you gain a Power Level, update all Ghost "
            "Warrior Datas to match. When a (non-Minion) Character you are "
            "aware of dies while holding a powerful grudge (even outside "
            "Computer Form), you gain their Ghost Warrior Data. You cannot "
            "have 2 Ghost Warriors based on the same Character; new Data "
            "replaces the old record.\n"
            "(6)-[Triggered/Start of Turn]: While in Computer Form, you may "
            "spend up to 12(bT) Ki Points. For every 4(bT) Ki Points spent, "
            "create a Ghost Warrior Minion on an unoccupied Square within a "
            "Huge Sphere AoE (centered on you). All Ghost Warriors created "
            "cease to exist at the end of the Combat Encounter.\n"
            "(7)-[Triggered]: If you gain Ghost Warrior Data, gain 1 Revenge "
            "Point and regain Ki Points equal to your Surgency.\n"
            "(8)-[1/Encounter]: You may delete one of your Ghost Warrior Datas "
            "to use the Transformation Maneuver as an Instant Maneuver.",
      ),
    ],
  ),

  // ==================================== Grudge Amplifier: Humanoid Battle Form (1) ===
  TransformationDef(
    name: "Humanoid Battle Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Neo-Tuffle",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 12,
    prerequisiteText: "Hatred Embodiment Subrace.",
    transformationLine: "Grudge Amplifier",
    stage: 1,
    aspects: [
      "Enhanced Save (Impulsive/Corporeal)",
      "Scaling (LV2)",
      "Realization",
      "Prelude",
      "Difficult (LV1)",
    ],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Warrior Bearing Grudges",
        description: "Taking humanoid shape has imbued the hatred you've "
            "gathered into your circuits, filling you with unfathomable "
            "rage.\n"
            "(1)-[Passive]: Increase your Combat Rolls by 1(T) against your "
            "Inferior.\n"
            "(2)-[Passive]: Increase your Soak Value by 1(T) against Attacking "
            "Maneuvers from your Inferior.\n"
            "(3)-[Passive]: Increase your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(4)-[Passive]: For the duration of any Attacking Maneuver that "
            "targets your Inferior and possesses 1+ Energy Charges, increase "
            "the Dice Category of your Energy Charges by 1 Category.\n"
            "(5)-[Triggered]: When making an Attacking Maneuver, you may erase "
            "1 Ghost Warrior Data you possess to gain 2 Revenge Points and "
            "apply an Energy Charge to that Attacking Maneuver. If you have a "
            "Ghost Warrior connected to the erased Data, they cease to "
            "exist.\n"
            "(6)-[Triggered/Start of Combat Round]: If you have at least 1 "
            "Ghost Warrior Data, gain a Revenge Point.",
      ),
      TransformationTrait(
        name: "Power of a Grudge",
        description: "Just like the burning hatred that sears through your "
            "being, you are inextinguishable.\n"
            "(1)-[Passive]: Apply an Energy Charge to your Ultimate Signature "
            "Techniques.\n"
            "(2)-[1/Round]: You may spend a Revenge Point as if it was a "
            "Counter Action for the Action Cost of the Defend Maneuver.\n"
            "(3)-[Triggered]: If you gain a stack(s) of Revenge Points, regain "
            "1(bT) Ki Point for every Revenge Point gained.\n"
            "(4)-[Triggered]: Each time you spend Revenge Points, for every 2 "
            "Revenge Points spent, increase your Wound Rolls by 1(T) until the "
            "start of your next turn (max. 4(T)).\n"
            "(5)-[Triggered/Power, 1/Round]: You may use the Energy Charge "
            "Maneuver as an Out-of-Sequence Maneuver.\n"
            "(6)-[Triggered, 1/Encounter]: If you use a Super Signature "
            "Technique that has 3+ Energy Charges from the Energy Charge "
            "Maneuver, you may apply the Ascended Signature Advantage to that "
            "Attacking Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Control over Grudges",
        description: "Your logic-core has altered to accommodate the vengeful "
            "desires that course through you.\n"
            "(1)-[Permanent]: Humanoid Battle Form gains M levels of the "
            "Natural Aspect.\n"
            "(2)-[Passive]: Increase the Dice Category increase from the 3rd "
            "effect of Warrior bearing Grudges by M.\n"
            "(3)-[Passive]: Increase the amount of Revenge Points gained "
            "through the 6th effect of Warrior bearing Grudges by M.",
      ),
      TransformationTrait(
        name: "Unstoppable Grudge",
        description: "Nothing but the total annihilation of your targets can "
            "slake your thirst for vengeance.\n"
            "(1)-[Passive]: Increase your Strike and Dodge Rolls by 1(T).\n"
            "(2)-[Triggered]: If you gain a stack(s) of Revenge Points, regain "
            "1(bT) Life Point for every Revenge Point gained.\n"
            "(3)-[1/Round]: Use the Energy Charge Maneuver as an Instant "
            "Maneuver.\n"
            "(4)-[Triggered, 1/Encounter]: If you end your turn after using "
            "the Energy Charge Maneuver 3+ times during that turn, you may use "
            "the Signature Technique Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ==================================== Janemba line (pure-evil Legendary Forms;
  // Janemba Manifest Null Stage + Super Janemba Stage 1). Site flavour text is
  // heavily zalgo-corrupted; rendered here as readable stand-ins.
  // ============================================= Janemba: Janemba Manifest (0) ===
  TransformationDef(
    name: "Janemba Manifest",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 2,
    stressTestRequirement: 10,
    prerequisiteText: "Janemba line, Null Stage. You are not a Minion (except "
        "Duplicate Minions).",
    transformationLine: "Janemba",
    stage: 0,
    aspects: [
      "Scaling (LV2)",
      "Growth (LV3)",
      "Natural (LV2)",
      "Rampaging (LV2)",
      "Peaked",
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
        name: "Janemba! Janemba!",
        description: "[Janemba is not restricted by your puny Tier of Power "
            "Requirement.]\n"
            "(1)-[Permanent]: For the sake of entering and remaining in this "
            "Transformation, ignore its Tier of Power Requirement.\n"
            "(2)-[Permanent]: You cannot leave this Transformation except to "
            "enter a different Stage of this Transformation Line.\n"
            "(3)-[Passive]: Your Race becomes 'Janemba'. Your Race's Racial "
            "Life Modifier (before any modifications) becomes 10 and your "
            "Racial Saving Throw Bonus applies to the Corporeal, Cognitive, "
            "and Impulsive Saves. If this Character is a Fusion, this only "
            "applies to the Race of the Fused Character that possessed the "
            "Janemba Manifest Transformation.\n"
            "(4)-[Passive]: If you are not a Fusion, lose access to your Racial "
            "Traits. You maintain any Technique Points, Signature Techniques, "
            "or Unique Abilities gained from those lost Racial Traits.\n"
            "(5)-[Passive]: Gain access to the Reality Warping Traits.\n"
            "(6)-[Passive]: The Alignment of your Z-Soul is Pure Evil, and "
            "your Z-Soul becomes 'Janemba!'.\n"
            "(7)-[Passive]: You cannot be targeted by or use the Body Change "
            "Unique Ability.\n"
            "(8)-[Passive]: Reduce your Morale Saving Throw by 2(bT).\n"
            "(9)-[Automatic]: If you are targeted by the Insult Special "
            "Maneuver and lose the Clash, gain 2 stacks of the Broken Combat "
            "Condition for 1 Combat Round.\n"
            "(10)-[Automatic]: If you would die due to an Attacking Maneuver "
            "that possesses the Karmic Super Profile from an Opponent who has "
            "an opposing Z-Soul, your Life Points are set to 1 and you lose "
            "access to this Transformation instead of dying (ignored if your "
            "Z-Soul without the 6th effect is Pure Evil or Evil).\n"
            "While in Janemba, your Race becomes 'Janemba' and your Racial "
            "Traits are replaced by the five Reality Warping Traits (Evil "
            "Incarnate, Evil Magic, Jellybean Junction, Paranormal Perception, "
            "Paranormal Assault) — shown/automated as your active Racial "
            "Traits on the Information tab while this Form is active.",
      ),
    ],
  ),

  // ================================================= Janemba: Super Janemba (1) ===
  TransformationDef(
    name: "Super Janemba",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Janemba",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "You are not a Minion (except Duplicate Minions).",
    transformationLine: "Janemba",
    stage: 1,
    aspects: [
      "Enhanced Save (Cognitive/Impulsive/Corporeal)",
      "Scaling (LV2)",
      "Growth (LV1)",
      "Natural (LV1)",
      "Raging",
      "Rampaging (LV2)",
      "Peaked",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.personality:
          TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Evil Concentrate",
        description: "[Kekekekeke... Janemba will rule over all!!!]\n"
            "(1)-[Passive]: Halve your Health Thresholds "
            "(Bruised/Injured/Critical).\n"
            "(2)-[Passive]: Ignore the effects of the Fatigued Combat "
            "Condition.\n"
            "(3)-[Passive]: You cannot lose Life Points through the effects of "
            "the Compelled Combat Condition.\n"
            "(4)-[Passive]: You do not have to Ki Wager through the effects of "
            "the Compelled Combat Condition.\n"
            "(5)-[Passive]: While you are above the Bruised Health Threshold, "
            "this Transformation has the Armored Aspect.\n"
            "(6)-[Passive]: While you are above the Injured Health Threshold, "
            "treat your Size Category as Colossal for the effects of Punching "
            "Down.\n"
            "(7)-[Passive]: While you are above the Critical Health Threshold, "
            "you automatically win any Clashes initiated by your Opponent if "
            "that Clash uses your Cognitive Save.\n"
            "(8)-[Triggered/Transform, Triggered/Start of Turn]: If you are in "
            "the Healthy Health Threshold, enter either the Superior State or "
            "the Surging State until the start of your turn.\n"
            "(9)-[Triggered/Transform, 1/Encounter]: Use a Healing Surge as an "
            "Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Unholy Magic",
        description: "[Janemba is the closest thing to a god you puny mortals "
            "will ever meet.]\n"
            "(1)-[Passive]: Increase your Wound Rolls by 1(T) for each Health "
            "Threshold you are above.\n"
            "(2)-[Passive]: You gain access to the Bunkai Teleport Special "
            "Maneuver — Maneuver Type: Counter; Action Cost: 1 Counter "
            "Action. Effect: If you are targeted by an Attacking Maneuver, you "
            "may use this Maneuver to increase your Defense Value for that "
            "Attacking Maneuver by 3(T). Place yourself on any unoccupied "
            "Square in the Battlefield. Either use the Basic Attack Maneuver "
            "as an Out-of-Sequence Maneuver or apply the third effect of "
            "Endless Wickedness.\n"
            "(3)-[1/Round]: As an Instant Maneuver, target an unoccupied Square "
            "on the Battlefield. Leave your current Square and place yourself "
            "on that Square. If another Character is adjacent to that Square, "
            "you may use the Basic Attack Maneuver as an Out-of-Sequence "
            "Maneuver (targeting an adjacent Character).\n"
            "(4)-[Triggered]: If you use the Rapid Movement option of the "
            "Movement Maneuver, ignore your Speed. Move to any Square on the "
            "Battlefield. This movement does not trigger the Exploit "
            "Maneuver.\n"
            "(5)-[Triggered, 1/Round]: If you create a Physical Weapon through "
            "the effects of World Transfiguration, that Weapon gains the "
            "Dimension Blade Weapon Quality.\n"
            "(6)-[Triggered/Power, 1/Encounter]: Make a Clash (Cognitive) "
            "against all Opponents within a Destructive Sphere AoE (centered "
            "on you). If you win, those Opponents lose all stacks of Power.",
      ),
      TransformationTrait(
        name: "Endless Wickedness (Legendary Trait)",
        description: "[Janemba is forever. Janemba is eternal. Janemba is your "
            "future.]\n"
            "(1)-[Passive]: For each Health Threshold you are above, increase "
            "your Soak Value by 1(T).\n"
            "(2)-[Passive]: For each Health Threshold you are below, increase "
            "your Surgency by 2(T).\n"
            "(3)-[Triggered/Start of Turn]: Regain Life and Ki Points equal to "
            "1/2 of your Surgency.",
      ),
    ],
  ),

  // ================================= Universal Power line (Universe Seed; Ultimate
  // Form Stage 1 + Godslayer Stage 2).
  // ============================================ Universal Power: Ultimate Form (1) ===
  TransformationDef(
    name: "Ultimate Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "40+ Universal Power in your Universe Seed.",
    transformationLine: "Universal Power",
    stage: 1,
    aspects: [
      "Enhanced Save (All)",
      "High Speed (LV3)",
      "Growth (LV2)",
      "Scaling (LV2)",
      "Armored",
      "Dedicated",
      "Peaked",
      "Rampaging (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Universe-Shaking Might",
        description: "By gathering Universal Power, you can trample over even "
            "the gods.\n"
            "-[Automatic/Transform]: The Universe Seed becomes Integrated "
            "until you leave this Transformation.\n"
            "-[Passive]: Your Integrated Universal Seed gains the Universal "
            "Power from Defeated Characters as soon as they are Defeated, "
            "rather than at the end of the Combat Encounter.\n"
            "-[Passive]: Increase your Combat Rolls by x(T), where x (max. 4) "
            "is equal to 1/20th (rounded up) your amount of Universal Power in "
            "your Integrated Universe Seed.\n"
            "-[1/Round]: Spend 10 Universal Power to use either the Basic "
            "Attack Maneuver or Signature Technique Maneuver as an Instant "
            "Maneuver. If you do, that Attacking Maneuver gains 2 Energy "
            "Charges.\n"
            "-[Triggered, 1/Round]: If you would use a Unique Ability, spend 5 "
            "Universal Power to not pay the Ki Point Cost.\n"
            "-[Triggered, 1/Round]: If you are targeted by an Attacking "
            "Maneuver, spend 5 Universal Power to use the Defend Maneuver "
            "against that Attacking Maneuver without spending a Counter "
            "Action.\n"
            "-[Automatic]: If the Universal Power in your integrated Universe "
            "Seed becomes 0, leave this Transformation immediately.",
      ),
      TransformationTrait(
        name: "Universe-Crushing Titan",
        description: "The power you've gathered is enough to demolish all of "
            "creation.\n"
            "-[Passive]: Double the number of Extra Dice your Attacking "
            "Maneuvers gain through the Punching Down rules.\n"
            "-[Passive]: Increase your Soak Value by x(T), where x (max. 4) is "
            "equal to 1/20th (rounded up) your amount of Universal Power in "
            "your Integrated Universe Seed.\n"
            "-[Automatic]: When making an Attacking Maneuver, target one of "
            "the targets for that Attacking Maneuver. Apply the rules of "
            "Punching Down against that target for the duration of that "
            "Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Power of a Universe I (Legendary Trait)",
        description: "You can draw on the stored energy in the Universe "
            "Seed.\n"
            "-[Passive]: While you possess the Universe Seed, increase your "
            "Maximum Ki Points (before any modifications) by an amount equal "
            "to twice that Universe Seed's Universal Power.",
      ),
    ],
  ),

  // ================================================= Universal Power: Godslayer (2) ===
  TransformationDef(
    name: "Godslayer",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "60+ Universal Power in your Universe Seed.",
    transformationLine: "Universal Power",
    stage: 2,
    aspects: [
      "Enhanced Save (All)",
      "High Speed (LV3)",
      "Scaling (LV2)",
      "Armored",
      "Dedicated",
      "Peaked",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Universe-Shaping God (Universe-Crushing Titan)",
        description: "You have become a god amongst men, despite lacking the "
            "power of the gods.\n"
            "-[Passive]: Increase your Wound Rolls by 1d8(T).\n"
            "-[Passive]: Increase your Damage Reduction by x(T), where x (max. "
            "4) is equal to 1/20th (rounded up) your amount of Universal Power "
            "in your Integrated Universe Seed.\n"
            "-[Triggered]: If you Defeat an Opponent or knock an Opponent "
            "through a Health Threshold, you may use a Power Surge as an "
            "Out-of-Sequence Maneuver.\n"
            "-[1/Encounter]: As a Standard Maneuver with an Action Cost of 2 "
            "Actions, spend 20 Universal Power to target a Character within "
            "your Melee Range who has a lower base and current Tier of Power "
            "than you. Erase that target from existence.",
      ),
      TransformationTrait(
        name: "God-Slaying Spheres",
        description: "You produce a unique weapon designed to topple the "
            "divine.\n"
            "-[Passive]: Increase your Wound Rolls against Characters in the "
            "God Ki Special State with 2(T).\n"
            "-[Triggered/Transform, Resource]: Gain 1 God Sphere for every 10 "
            "Universal Power your Integrated Universe Seed possesses.\n"
            "-[1/Round]: You may spend 1 God Sphere to use the Basic Attack "
            "Maneuver as an Instant Maneuver. If you do, the Attacking Maneuver "
            "must be of the Sphere or Spell Profile but gains an Energy Charge, "
            "3 ranks of the Homing Advantage, and the Splitting Advantage. Its "
            "Wound Roll is not decreased through Splitting.",
      ),
      TransformationTrait(
        name: "Unmatched in Creation",
        description: "Throughout all the universe, none can match the power "
            "you've gathered, and you are not afraid to demonstrate that "
            "superiority.\n"
            "-[Passive]: Increase the Dice Score of any Clashes you make "
            "through the effects of a Unique Ability or when using a Saving "
            "Throw through an Opponent's effects by 1(T).\n"
            "-[Passive]: You are considered to have God Ki for the effects of "
            "other Character's God Ki State.\n"
            "-[Triggered]: When making an Attacking Maneuver, you may spend 5 "
            "Universal Power to increase the Damage Category of that Attacking "
            "Maneuver by 1 Damage Category.\n"
            "-[Triggered, 2/Round]: When targeted by an Attacking Maneuver, "
            "you may spend 5 Universal Power and Ki Points equal to twice the "
            "KP Cost of that Maneuver to cancel that Attacking Maneuver. The "
            "attacking Character regains any Ki Points spent (but not "
            "Actions). The Attacking Maneuver is considered to not have been "
            "used at all.\n"
            "-[Triggered, 1/Round]: If you cancel an Attacking Maneuver "
            "through the 4th effect of Unmatched in Creation, you may make a "
            "Clash (Any vs Any Saving Throw). If you win, you may use the "
            "Basic Attack Maneuver against that Opponent as an Out-of-Sequence "
            "Maneuver; if they win, they may reuse their canceled Attacking "
            "Maneuver as an Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Power of a Universe II (Legendary Trait)",
        description: "You are able to use the energy granted to you by the "
            "Universe Seed more quickly and efficiently.\n"
            "-[Passive]: While you possess the Universe Seed, increase your "
            "Max Capacity (before any modifications) by an amount equal to "
            "that Universe Seed's Universal Power. This cannot cause your Max "
            "Capacity to increase by more than 1/2.",
      ),
    ],
  ),

  // =============================================== Greatest Warrior? in the Universe ===
  TransformationDef(
    name: "Greatest Warrior? in the Universe",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Greatest Warrior? Awakening.",
    aspects: [
      "Enhanced Save (Cognitive/Morale)",
      "Scaling (LV2)",
      "Realization",
      "Innate State (Superior)",
      "Fading (LV1)",
    ],
    amb: {
      DbuAttribute.personality:
          TransformationAmb(coefficient: 4, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Champion(!) of the Universe",
        description: "You are the champion, my friend, and you must keep "
            "fighting 'til the end… for your adoring audience.\n"
            "(1)-[Passive]: Ignore the second effect of Greatest Warrior(?).\n"
            "(2)-[Passive]: Increase your Damage Reduction and Combat Rolls by "
            "1/2 of your Personality Modifier.\n"
            "(3)-[Passive]: You may use your Personality Modifier as the "
            "Damage Attribute for all of your Attacking Maneuvers.\n"
            "(4)-[Automatic/Transform, Automatic/Start of Combat Round]: Make "
            "a Clash (Bluff/Persuasion vs Intuition) against all Characters in "
            "the Combat Encounter. If you lose this Clash against any "
            "Character, enter the Exposed Special State until the start of the "
            "next Combat Round.\n"
            "Exposed Special State — (1)-[Passive]: Ignore the first 3 "
            "effects of Champion(!) of the Universe. (2)-[Passive]: Increase "
            "the Combat Rolls of all of your Allies by 1/4 of your Personality "
            "Modifier. (3)-[Triggered/Exposed]: Use the Combat Recovery "
            "Maneuver as an Out-of-Sequence Maneuver as if you spent 2 "
            "Actions.",
      ),
      TransformationTrait(
        name: "Wrestling Rock with Lead",
        description: "As you appear on the scene to \"save the day\", the "
            "riffs of your theme music fill the air, driving away despair.\n"
            "(1)-[Passive]: You are considered your own Ally for the 6th and "
            "7th effects of Greatest Warrior? while not in the Exposed "
            "State.\n"
            "(2)-[Triggered/Power, 1/Round]: If you are not in the Exposed "
            "State, you may use the Basic Attack Maneuver as an Out-of-Sequence "
            "Maneuver. If you do, enter the Determined State for the duration "
            "of that Attacking Maneuver.\n"
            "(3)-[Triggered/Defeated]: Make a Clash (Bluff/Persuasion vs "
            "Intuition) against all Characters in the Combat Encounter. If you "
            "win against all of them, regain Life Points equal to your Maximum "
            "Life Points. Then, all Opponents gain the Shaken Combat "
            "Condition.",
      ),
      TransformationTrait(
        name: "World-Shaking Charisma (Legendary Trait)",
        description: "Your magnetic personality carries such massive weight "
            "that others can't help but to be drawn into your orbit.\n"
            "(1)-[Passive]: While your amount of Ki Points exceeds your amount "
            "of Life Points, increase the Skill Bonus for the Bluff and "
            "Persuasion Skills by 1.\n"
            "(2)-[Triggered, 1/Round]: If you win a Clash that uses your Bluff "
            "or Persuasion Skill, regain Ki Points equal to your Personality "
            "Modifier.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Undisputed Champion(!)",
      description: "No one can question the veracity of your claims to power "
          "and fame… you've made sure of it.\n"
          "(1)-[Permanent]: This Transformation loses the Fading Aspect.\n"
          "(2)-[Passive]: Increase the Dice Category of your Greater Dice by x "
          "Categories, where x is equal to 1/2 of your base Tier of Power "
          "(rounded up).\n"
          "(3)-[Passive]: Increase the Attribute Modifier Bonus "
          "(AG/FO/TE/IN/MA) of this Transformation by 1(T), after all other "
          "calculations.\n"
          "(4)-[Passive]: You may use your Personality Modifier to calculate "
          "your Might.",
    ),
  ),

  // ==================================================== Descended Super Saiyan Blue ===
  TransformationDef(
    name: "Descended Super Saiyan Blue",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Earthling",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Mastered Descended Super Saiyan, Saiyan Ancestry "
        "Factor.",
    aspects: [
      "Enhanced Save (Cognitive/Impulsive/Corporeal)",
      "God Ki",
      "Perfect Ki Control",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Exhausting",
      "Draining (LV2)",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Ignited Saiyan Blood",
        description: "The fire in your soul burns bright with the fury of your "
            "divine might.\n"
            "(1)-[Passive]: While you possess 1+ stacks of Divine Warrior "
            "Blood, increase the Dice Score of your Duel Clashes by 1(T).\n"
            "(2)-[Passive]: While you possess 1+ stacks of Divine Warrior "
            "Blood, you have access to the Divine Flame God Maneuver.\n"
            "(3)-[Passive]: While you possess 2+ stacks of Divine Warrior "
            "Blood, increase the Dice Category of your Tier of Power Extra "
            "Dice by 1 Category and your Damage Reduction by 1(T).\n"
            "(4)-[Passive]: While you possess 2+ stacks of Divine Warrior "
            "Blood, you have access to the Divine Attack God Maneuver.\n"
            "(5)-[Passive]: While you possess 3+ stacks of Divine Warrior "
            "Blood, increase the Dice Category of your Energy Charges by 1 "
            "Category.\n"
            "(6)-[Passive]: For every stack of Divine Warrior Blood you "
            "possess, increase your Surgency by 1(T).\n"
            "(7)-[Triggered, 1/Round]: If you use a Signature Technique and "
            "apply an Energy Charge to it through the second effect of Quick "
            "to Master, apply an additional Energy Charge to that Attacking "
            "Maneuver.\n"
            "(8)-[Triggered, 1/Encounter]: If you would trigger an effect to "
            "enter the Surging State while already in the Surging State and "
            "below the Injured Health Threshold, you may instead enter the "
            "Entrusted State until the end of your next turn.",
      ),
      TransformationTrait(
        name: "Blue Blaze of Resolve",
        description: "The sapphire glow that surrounds you is a testament to "
            "your godly strength.\n"
            "(1)-[Passive]: Increase your maximum number of Energy Charges by "
            "1 for every stack of Divine Warrior Blood you possess.\n"
            "(2)-[1/Round]: If you have 2+ stacks of Divine Warrior Blood, you "
            "may use the Power Up Maneuver as an Instant Maneuver.\n"
            "(3)-[Passive]: If you pay the Ki Point Cost of the Signature "
            "Technique Maneuver with Divine Ki Points, increase the Wound Roll "
            "of that Attacking Maneuver by 1(T) for each stack of Divine "
            "Warrior Blood you possess.\n"
            "(4)-[Triggered/Start of Turn]: If you have 3+ stacks of Divine "
            "Warrior Blood, you may use the Combat Recovery Maneuver as an "
            "Out-of-Sequence Maneuver as if you spent 1 Action (no Defense "
            "Value penalty).\n"
            "(5)-[Triggered/Start of Turn, 1/Encounter]: If you are below the "
            "Injured Health Threshold, you may enter the Surging State until "
            "you leave this Transformation.",
      ),
      TransformationTrait(
        name: "Divine Saiya Power (Legendary Trait)",
        description: "Through your Saiyan ancestry, you have received a "
            "fraction of the legendary might of the Super Saiyan God, awakened "
            "through the power of your own Super Saiyan Transformation.\n"
            "(1)-[Triggered/Power, Resource]: You may exchange a stack of "
            "Warrior Blood for a stack of Divine Warrior Blood. Divine Warrior "
            "Blood is treated as Warrior Blood for all of your effects, except "
            "the 3rd effect of Dormant Saiya Power.\n"
            "(2)-[Passive]: Each stack of Divine Warrior Blood increases your "
            "Wound Rolls and Soak Value by 1(T). If you possess 2+ stacks, "
            "increase your Combat Rolls by 1(T), or 2(T) if you are in a "
            "Transformation with the God Ki Aspect.\n"
            "(3)-[Triggered/Entrusted, 1/Encounter]: Use a Healing Surge as an "
            "Out-of-Sequence Maneuver.\n"
            "(4)-[Triggered/Power, 1/Encounter]: If you possess 2+ stacks of "
            "Divine Warrior Blood, you may enter the Surging State until the "
            "end of your turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Blue Spirit",
        description: "The unwavering determination of the Earthling race flows "
            "through your smoldering cerulean aura.\n"
            "(1)-[Permanent]: This Transformation loses the Exhausting Aspect, "
            "M levels of the Draining Aspect, and gains M levels of the "
            "Scaling Aspect.\n"
            "(2)-[Permanent, Passive]: Upon gaining this Mastery Trait, select "
            "a God Maneuver. Gain access to that God Maneuver while in the "
            "Descended Super Saiyan Blue Transformation.\n"
            "(3)-[Passive]: Ignore the 3rd effect of the Surging State.\n"
            "(4)-[Passive]: Double the bonuses from the 3rd effect of Ignited "
            "Saiyan Blood.\n"
            "(5)-[Triggered]: If you use the Surge Maneuver, regain Divine Ki "
            "Points equal to your Surgency.",
      ),
      TransformationTrait(
        name: "Heroic Spirit of the Blue Blaze",
        description: "Your steadfast resolve, now clad in azure, awakens the "
            "true deific power within you.\n"
            "(1)-[Passive]: While you possess 3 stacks of Divine Warrior "
            "Blood, increase your Strike and Dodge Rolls by 1(T).\n"
            "(2)-[Triggered]: If you spend Divine Ki Points to pay the Ki "
            "Point Cost of an Attacking Maneuver, apply an Energy Charge to "
            "that Attacking Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique while in the Entrusted State, you may apply the All Out "
            "Super Profile to that Attacking Maneuver.",
      ),
    ],
  ),

  // ======================================================= Limit-Shattering Blaze ===
  TransformationDef(
    name: "Limit-Shattering Blaze",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Super Full Power Boost). Mortal "
        "Flames Super Awakening. Stress Test Requirement: +4.",
    aspects: ["Peaked"],
    amb: _powerBoostAmb,
    traits: [
      TransformationTrait(
        name: "Roaring Flames that Scorches Creation",
        description: "The burning aura that radiates off of you in waves "
            "ignites, setting the battlefield ablaze with your fighting "
            "spirit.\n"
            "(1)-[Passive]: Increase your Might by 1(T) while you are Power "
            "Spiked.\n"
            "(2)-[Passive]: While you are Fired Up, you are Power Spiked.\n"
            "(3)-[Passive]: Your current Tier of Power can be up to 3 Tiers of "
            "Power higher than your base Tier of Power, ignoring the Tier of "
            "Power Limit.\n"
            "(4)-[Triggered/Start of Turn, 1/Encounter]: If you are Power "
            "Spiked and below the Injured Health Threshold, you may enter the "
            "Determined State until the end of your turn.\n"
            "(5)-[Triggered/Power, 1/Encounter]: You may apply the Flames of "
            "Power Modifier Maneuver to this use of the Power Up Maneuver "
            "without paying its Action Cost.",
      ),
    ],
  ),

  // ================================================================== No Ego Zone ===
  TransformationDef(
    name: "No Ego Zone",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Earthling",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    aspects: [
      "Enhanced Save (All)",
      "Innate State (Mindful)",
      "Perfect Ki Control",
      "Straining",
      "Weakening",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Serene Heart, Raging Fist",
        description: "Due to your inner calm and absolute self-control, your "
            "power explodes as you display a level of ability beyond what "
            "anyone thought you capable of.\n"
            "(1)-[Passive]: Your use of the Combat Recovery Maneuver does not "
            "trigger the Exploit Maneuver, and you do not suffer from a "
            "reduction to your Defense Value through the effects of Combat "
            "Recovery.\n"
            "(2)-[Passive]: Increase the Dice Score of your Combat Recovery by "
            "your Surgency.\n"
            "(3)-[Passive]: You may spend Counter Actions as if they were "
            "Actions for the Action Cost of the Combat Recovery Maneuver.\n"
            "(4)-[Passive]: For each level of the Mindful State you are in, "
            "increase your Combat Rolls by 1(T) and the Dice Category of your "
            "Tier of Power Extra Dice by 1 Category.\n"
            "(5)-[Passive]: For each level of the Mindful State you are "
            "currently in, increase the required Natural Result to trigger the "
            "2nd effect of Earthling Resolve by 1 (3 or less at Calm, 4 or "
            "less at Zen, etc).\n"
            "(6)-[Triggered, 1/Round]: If you use the Combat Recovery "
            "Maneuver, for each stack of Distilled Ki gained, increase your "
            "level in the Mindful State by 1 until the start of your next "
            "turn.\n"
            "(7)-[Triggered, 1/Round]: If you use the Combat Recovery "
            "Maneuver, you may forgo gaining any Life Points to enter the "
            "Surging State until the end of your turn.",
      ),
      TransformationTrait(
        name: "Resolve at the Limit",
        description: "You take full control over your body through extreme "
            "calm, allowing you to overcome your weaknesses.\n"
            "(1)-[Passive]: For each Health Threshold you are below, increase "
            "your Surgency by 1(T).\n"
            "(2)-[Passive]: Increase the Dice Score of your Combat Rolls that "
            "score a Critical Result by 1(T).\n"
            "(3)-[Passive]: While you are below the Injured Health Threshold, "
            "increase your Strike Rolls and Wound Rolls by 1(T) and 2(T) "
            "respectively.\n"
            "(4)-[Passive]: The 2nd effect of Earthling Resolve loses its "
            "[1/Round] Keyword and gains the [2/Round] Keyword.\n"
            "(5)-[Passive]: Increase the amount of Power stacks gained through "
            "the Power Up Maneuver by 1.\n"
            "(6)-[Triggered/Defeated]: Set your Life Points to 1, then turn "
            "any previously failed Steadfast Checks for your Health Thresholds "
            "into successes. If no checks were turned into successes, you may "
            "enter the Superior State until the end of your next turn.\n"
            "(7)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique while below the Injured Health Threshold, you may apply "
            "the All-Out Super Profile to that Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Untold Mastery of Ki (Legendary Trait)",
        description: "Your absolute mastery of your energy is enough to make "
            "even gods jealous.\n"
            "(1)-[Triggered, Resource]: Each time you use the Combat Recovery "
            "Maneuver, gain a stack of 'Distilled Ki' for each Action spent "
            "(max. 3).\n"
            "(2)-[1/Round]: As an Instant maneuver, you may spend a stack of "
            "Distilled Ki to regain Ki Points equal to your Surgency.\n"
            "(3)-[Triggered, 1/Round]: If you use a Signature Technique, you "
            "may spend a stack of Distilled Ki to apply an Energy Charge to "
            "that Attacking Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you are targeted by an Attacking "
            "Maneuver, you may spend a stack of Distilled Ki instead of a "
            "Counter Action to use the Defend Maneuver.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Deep within the Self",
        description: "Your utter control of your mind allows you to quiet your "
            "thoughts and become one with the fight, moving with greater ease "
            "and precision.\n"
            "(1)-[Permanent]: No Ego Zone loses the Straining Aspect and gains "
            "M levels of the Scaling Aspect.\n"
            "(2)-[Passive]: Reduce the Ki Point Cost of your Signature "
            "Techniques by 1(T).\n"
            "(3)-[Passive]: Ignore the 2nd effect of the Surging State.\n"
            "(4)-[Triggered/Transform, Triggered/Start of Turn]: Gain 1 "
            "Counter Action.",
      ),
      TransformationTrait(
        name: "Core of Identity",
        description: "You have reached a point of complete control over your "
            "mind, body, and soul; you have achieved the peak of ability for "
            "your kind.\n"
            "(1)-[Permanent]: No Ego Zone loses the Weakening Aspect.\n"
            "(2)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(3)-[Passive]: Ignore the 2nd effect of the Calm Level of the "
            "Mindful State.\n"
            "(4)-[Triggered, 1/Round]: If an Opponent initiates a Clash "
            "against you that uses your Saving Throws or Might, you may spend "
            "Ki Points equal to 1/4 of your Max Capacity to automatically win "
            "that Clash.",
      ),
    ],
  ),

  // ================================================================= Supreme Form ===
  TransformationDef(
    name: "Supreme Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 7,
    stressTestRequirement: 40,
    prerequisiteText: "Access to a Fully Mastered Legendary Form (except any "
        "stage of the Empowered or Universal Power Lines); you do not have "
        "access to Ultra Ego, Destroyer Form, or a Transformation of the Ultra "
        "Instinct Line.",
    aspects: [
      "Enhanced Save (All)",
      "Perfect Ki Control",
      "Armored",
      "High Speed (LV3)",
      "Peaked",
      "Heartbeat",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 8, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 8, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Supreme Power",
        description: "You've reached the absolute peak of power; none can "
            "surpass your newfound might.\n"
            "-[Passive]: Apply your Greater Dice to all of your Combat "
            "Rolls.\n"
            "-[Passive]: For each stack of Power you possess, increase the "
            "Attribute Modifier Bonus (AG/FO/TE/MA) of this Transformation by "
            "1(T), but for every stack of Power after the first, this "
            "Transformation gains a level of the Draining Aspect.\n"
            "-[Passive]: You can possess 1 stack of Power beyond the "
            "maximum.\n"
            "-[Triggered, 1/Round]: If you enter Supreme Form through the "
            "Surging Strength rules while you are making an Attacking Maneuver, "
            "for each stack of Power you possess, apply an Energy Charge to "
            "that Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Supreme Presence",
        description: "Your overwhelming aura radiates a foreboding sense of "
            "danger for all who oppose you.\n"
            "-[Passive]: Increase your Maximum Life Points by 1/2.\n"
            "-[Passive]: Reduce the Damage Category of all Attacking Maneuvers "
            "that target you from Opponents who are not in a Transformation "
            "with a Tier of Power Requirement of 7 by 1 Damage Category.\n"
            "-[Triggered]: If you hit an Opponent, increase your Wound Roll by "
            "x(T), where x is the difference in Tier of Power Requirement "
            "between Supreme Form and their highest active Transformation (x = "
            "10 if not in a Core Transformation).\n"
            "-[Triggered]: If you are hit, increase your Damage Reduction by "
            "x(T) on the same basis (x = 10 if not in a Core Transformation).\n"
            "-[Triggered/Transform, Triggered/Power, 1/Round]: Enter the "
            "Surging State until the end of your turn (ignore its 2nd and 3rd "
            "effects if entered this way).\n"
            "-[Triggered/Transform, 1/Encounter]: Regain Life Points equal to "
            "1/2 of your Maximum Life Points prior to entering this "
            "Transformation.",
      ),
      TransformationTrait(
        name: "Supreme Transformation",
        description: "This Transformation is the supreme culmination of your "
            "legendary power.\n"
            "-[Passive]: Double the Attribute Modifier Bonus increase from the "
            "first effect of the Full Power Special State.\n"
            "-[Permanent]: You cannot use this Transformation in conjunction "
            "with any other Transformation.\n"
            "-[Permanent]: This Transformation's Racial Requirement is also "
            "considered to be your Race for the sake of any effects.\n"
            "-[Permanent, Passive]: Upon gaining access to this Transformation, "
            "select a Supreme Trait keyed to a Legendary Form you have fully "
            "mastered.\n"
            "Supreme Traits: ~20 Legendary-Form-keyed options (Supreme Power "
            "Boost, Supreme Potential, Supreme God, Supreme Android, Supreme "
            "Adaptoid, Supreme Evolution, Supreme Perfection, Supreme Majin, "
            "Supreme Chaos, Supreme Namekian, Supreme Hatred, Supreme Legend, "
            "Supreme Super Saiyan, Supreme Saiyan God, Supreme Dragon, Supreme "
            "Demon King, Supreme World King, Supreme Martial Artist, …) — see "
            "the site.",
      ),
      TransformationTrait(
        name: "Supreme Energy (Legendary Trait)",
        description: "With your overwhelming strength and your endless "
            "stamina, you have surpassed mortal nature and become a natural "
            "calamity.\n"
            "-[Passive]: For each stack of Power you possess, increase the "
            "Dice Category of your Tier of Power Extra Dice and your Greater "
            "Dice by 1 Dice Category.\n"
            "-[Triggered/Power, 1/Round]: Gain an additional stack of Power.",
      ),
    ],
  ),

  // ==================================================================== Ultra Ego ===
  TransformationDef(
    name: "Ultra Ego",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 6,
    stressTestRequirement: 33,
    prerequisiteText: "Fully Mastered a Legendary Form with the God Ki Aspect, "
        "OR access to an Enhancement Power with the God Ki Aspect, OR 2 stacks "
        "of the God Class Up Manifested Power.",
    aspects: [
      "Enhanced Save (All)",
      "Perfect Ki Control",
      "God Ki",
      "High Speed (LV3)",
      "Scaling (LV1)",
      "Exhausting",
      "Power High (LV3)",
      "Draining (LV2)",
      "Difficult (LV2)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 6, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 6, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Secret of the Self-Indulgent",
        description: "Your sense of superiority has evolved into true egotism, "
            "allowing you to accomplish what none before you could: truly "
            "master the power of Destruction.\n"
            "-[Permanent, Passive]: Upon gaining access to Ultra Ego, select 3 "
            "God Maneuvers. You have access to those God Maneuvers while in "
            "this Transformation.\n"
            "-[Automatic/Transform]: Use the Transformation Maneuver as an "
            "Out-of-Sequence Maneuver to enter the Power of Destruction "
            "Enhancement Power, without rolling a Stress Test. You cannot "
            "leave Power of Destruction while in this Transformation.\n"
            "-[Automatic/Transform]: Enter the Superior State until you leave "
            "Ultra Ego.\n"
            "-[1/Round]: You may use the Power Flare effect of the Defend "
            "Maneuver without spending a Counter Action.\n"
            "-[Passive]: While in this Transformation, you have access to "
            "Power of Destruction.\n"
            "-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time to your Wound Rolls.\n"
            "-[Passive]: Ignore all penalties to your Combat Rolls while you "
            "are above the Injured Health Threshold.\n"
            "-[Passive]: If your Attacking Maneuver possesses the Destruction "
            "Profile, increase its Wound Roll by 6(T).",
      ),
      TransformationTrait(
        name: "Thoughts of Destruction",
        description: "Your mind is consumed by the burning desire to destroy "
            "your opponents, allowing you to move exactly as you wish.\n"
            "-[Triggered, 2/Round, Resource]: If you are hit by an Opponent's "
            "Attacking Maneuver, gain a stack of Ego (max. 6). For each stack "
            "of Ego, increase your Tier of Power Extra Dice for your Wound "
            "Rolls by 1 Dice Category. For every 2 stacks of Ego, increase "
            "your Greater Dice by 1 Dice Category.\n"
            "-[1/Encounter]: If you possess 6 stacks of Ego, you may enter the "
            "Egotistical State until the end of your turn as an Instant "
            "Maneuver.\n"
            "-[Triggered]: If you receive Damage from an Opponent's Attacking "
            "Maneuver, regain Ki Points equal to 1/2 (rounded up) the Damage "
            "you received.\n"
            "-[Triggered]: If you receive Damage from an Opponent's Attacking "
            "Maneuver, you may spend 4(bT) Divine Ki Points to reduce the "
            "Damage you received by your Might.\n"
            "-[Triggered/Threshold]: Use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver and regain Divine Ki Points equal to "
            "twice your Power Level.\n"
            "-[Passive]: While you are above the Injured Health Threshold, you "
            "cannot gain Combat Conditions.",
      ),
      TransformationTrait(
        name: "Beyond the Self",
        description: "You have reached beyond your inherent power to grasp at "
            "something beyond, incorporating it into your being.\n"
            "-[Permanent]: This Transformation's Racial Requirement is also "
            "considered to be your Race for the sake of any effects.\n"
            "-[Permanent, Option]: When you first gain access to this "
            "Transformation, select one of the effects below to gain access "
            "to while in this Transformation. You can only select an Option "
            "named after your Race or Any Race.",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Race Option',
            options: [
              TraitOption(
                name: 'Any Race',
                description: '[Triggered, 1/Round, 2/Encounter]: When you are '
                    'targeted by an Attacking Maneuver (not an Ultimate '
                    'Signature Technique) while you have 6 stacks of Ego, you '
                    'may take no Damage from it regardless of the Wound Roll '
                    "(none of your Opponents' effects activate from you being "
                    'hit).',
              ),
              TraitOption(
                name: 'Android',
                description: '[Passive]: All Opponents have a stack of Lock On '
                    'and you have no penalties to Dodge Rolls from them. When '
                    'you regain Ki Points through a Surge or a Racial Trait, '
                    'you also regain 2(bT) Divine Ki Points.',
              ),
              TraitOption(
                name: 'Arcosian',
                description: '[Triggered/Transform, Start of Combat Round]: If '
                    'above the Injured Health Threshold and not suffering the '
                    'Weakening Aspect, maximize your Cruelty; if you do, you '
                    'may use the Power Up Maneuver Out-of-Sequence.',
              ),
              TraitOption(
                name: 'Bio-Android',
                description: '[Permanent, Passive]: Upon gaining access to '
                    'Ultra Ego, select a Super Genetic Trait whose bracketed '
                    'Race matches a Race among your Genetic Traits; gain '
                    'access to it while in this Transformation.',
              ),
              TraitOption(
                name: 'Cerealian',
                description: '[Triggered/Transform, Start of Combat Round]: '
                    'Either place 1 stack of Observation on all Opponents, or '
                    '2 on a single Opponent; if you do, double the maximum '
                    'Observation stacks until end of turn (excess lost), and '
                    'until end of turn all your Attacking Maneuvers are '
                    'treated as Called Shots.',
              ),
              TraitOption(
                name: 'Earthling',
                description: '[Passive]: You are treated as above the Injured '
                    "Health Threshold for all of this Transformation's "
                    'effects regardless of Life Points, but below an '
                    'additional Health Threshold for all your other effects.',
              ),
              TraitOption(
                name: 'Majin',
                description: '[Triggered]: Each time you are targeted by an '
                    "Opponent's Attacking Maneuver, immediately regain Life "
                    'Points equal to 1/4 (rounded up) of your Might. If you '
                    'regain Life through a Surge or a Racial Trait, regain '
                    '2(bT) Divine Ki Points.',
              ),
              TraitOption(
                name: 'Namekian',
                description: '[Triggered/Transform, Start of Combat Round]: '
                    'Either place 1 stack of Studied on all Opponents, or 2 '
                    'on a single Opponent; if you do, increase your Tier of '
                    'Power Extra Dice on all Combat Rolls against Opponents '
                    'with 2+ Studied stacks by 2 Dice Categories.',
              ),
              TraitOption(
                name: 'Neo-Tuffle',
                description: '[Triggered/Transform, Start of Combat Round]: If '
                    'above the Injured Health Threshold and not suffering the '
                    'Weakening Aspect, maximize your Revenge Points; if you '
                    'do, you may use the Power Up Maneuver Out-of-Sequence.',
              ),
              TraitOption(
                name: 'Saiyan',
                description: '[Passive]: If you hit an Opponent with an '
                    'Attacking Maneuver whose Ki Point Cost you paid with '
                    'Divine Ki Points, increase the Damage Category of that '
                    'Attacking Maneuver by 1 category.',
              ),
              TraitOption(
                name: 'Shadow Dragon',
                description: '[Passive]: This Transformation gains the '
                    'Supernatural Calamity Trait (see - Super Star Dragon).',
              ),
              TraitOption(
                name: 'Shinjin',
                description: '[Passive]: If you make an Attacking Maneuver '
                    'whose Ki Point Cost is 5(T) or less after all '
                    'calculations, you may spend 1 DKP to pay it. '
                    'Additionally, treat all Opponents as if they have a '
                    'Combat Condition for your effects.',
              ),
              TraitOption(
                name: 'Custom Species',
                description: '[Passive]: If you are above the Injured Health '
                    'Threshold and not suffering the Weakening Aspect, you '
                    'possess Greater Dice.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Rampant Ego (Legendary Trait)",
        description: "Your extreme ego runs wild, granting you supreme "
            "confidence in your abilities.\n"
            "-[Triggered/Power, 1/Round]: Increase your Tier of Power Extra "
            "Dice for your Strike and Wound Rolls by 1 Dice Category until the "
            "start of your next turn.\n"
            "-[1/Round]: Use the Power Up Maneuver or Energy Charge Maneuver "
            "as an Instant Maneuver.\n"
            "-[Passive]: Increase the Dice Score of your Steadfast Checks by "
            "1.",
      ),
      TransformationTrait(
        name: "Destructive Egoist (Exceed Trait)",
        description: "Your sense of self becomes even more inflated as your "
            "energy becomes even more destructive.\n"
            "-[Passive]: While you have 6+ stacks of Ego, increase the Damage "
            "Category of your Attacking Maneuvers with the Destruction Profile "
            "by 1 category and their Damage Category cannot be reduced below "
            "Direct.\n"
            "-[Triggered/Exceed, Triggered/Power]: Gain a stack of Ego.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Overcoming the Self",
      description: "Your self-importance becomes less noticeable and your "
          "power is easier to control.\n"
          "-[Permanent]: Ultra Ego loses the Power High and Exhausting "
          "Aspects and gains the Strainless Aspect.\n"
          "-[Passive]: Ignore the second effect of the Superior State.\n"
          "-[Passive]: While you possess 2+ stacks of Power, this "
          "Transformation gains the Armored Aspect.\n"
          "-[Triggered, 1/Round]: For every Energy Charge a Signature "
          "Technique with the Destruction Profile possesses, increase its "
          "Wound Roll by 1(T).\n"
          "-[Permanent]: Ultra Ego loses the Draining Aspect and gains the "
          "Natural Aspect. Power of Destruction does not count as an "
          "additional Transformation for the effects of the Natural Aspect.",
    ),
  ),

  // ============================================================== Ultimate Majin ===
  TransformationDef(
    name: "Ultimate Majin",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Majin",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Android Majin.",
    aspects: [
      "Enhanced Save (All)",
      "Growth (LV1)",
      "Armored",
      "Exhausting",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Ultimate Assimilation",
        description: "With an explosion of power, you awaken the dormant "
            "pieces of those you've absorbed in the past, unleashing the "
            "powers you've stolen once more.\n"
            "(1)-[Automatic/Transform]: Upon entering this Transformation, gain "
            "Level 2 Temporary stacks of the Absorption Awakening using your "
            "choice of your DNA Copies until you have up to 3 in total "
            "(including any gained from 2nd effect of DNA Absorption). If you "
            "have less than 3 DNA Copies, then instead this effect applies "
            "until you have as many as you can have.\n"
            "(2)-[Automatic]: If, at any point, you have no DNA Copies or "
            "stacks of Absorption with DNA Copies as the Absorbed "
            "Character(s), immediately leave this Transformation.\n"
            "(3)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select a Bestial Trait. You have access to that "
            "Bestial Trait while in this Transformation.\n"
            "(4)-[Triggered, 1/Encounter]: If you use the 3rd effect of DNA "
            "Library, apply your Surgency an additional time to the Healing "
            "Surge used through its effects.",
      ),
      TransformationTrait(
        name: "Fountain of Recorded Power",
        description: "The powers you've stolen and re-awakened radiate off of "
            "you in waves, increasing your combat strength tremendously.\n"
            "(1)-[Passive]: For each stack of Absorption you possess with a "
            "DNA Copy as the Absorbed Character, increase your Surgency by "
            "1(T).\n"
            "(2)-[Passive]: While you possess 2+ stacks of Power, double the "
            "bonus from the 2nd effect of DNA Library.\n"
            "(3)-[Triggered, 1/Round]: If you use a Healing Surge, regain "
            "2(bT) Ki Points for each stack of Absorption you possess with a "
            "DNA Copy as the Absorbed Character.\n"
            "(4)-[Triggered, 1/Round]: If you use a Signature Technique that "
            "belongs to one of your DNA Copies, apply an Energy Charge to that "
            "Attacking Maneuver.\n"
            "(5)-[Triggered, 1/Encounter]: If you trigger the 3rd effect of "
            "DNA Library, enter the Surging State until the end of your turn. "
            "Ignore the 2nd effect of the Surging State if you enter it "
            "through this effect.",
      ),
      TransformationTrait(
        name: "DNA Library (Legendary Trait)",
        description: "You keep an internal record of everyone you've ever "
            "absorbed.\n"
            "(1)-[Passive]: Increase your maximum number of DNA Copies to 4. "
            "This amount is increased to 5 if Ultimate Majin is Fully "
            "Mastered.\n"
            "(2)-[Passive]: While you have a stack(s) of Absorption that have "
            "a DNA Copy as the Absorbed Character(s), increase your Combat "
            "Rolls and Soak Value by 1(T).\n"
            "(3)-[1/Round]: As an Instant Maneuver, you may erase one of your "
            "DNA Copies to use a Healing Surge as an Out-of-Sequence Maneuver "
            "and then gain 2 stacks of Power until the end of your next turn.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Adjustment to Ultimate Power",
        description: "Tapping into the stolen powers you possess repeatedly, "
            "you've grown accustomed to the unrivaled strength you've "
            "achieved.\n"
            "(1)-[Permanent]: Ultimate Majin loses the Exhausting Aspect and "
            "gains M levels of the Scaling Aspect.\n"
            "(2)-[Passive]: Treat your Size Category as Small for calculating "
            "your Defense Value from your Size and for your Opponent's Punching "
            "Up.",
      ),
      TransformationTrait(
        name: "Mastery of Ultimate Power",
        description: "You are the pinnacle of true power, unrivaled by any "
            "other, thanks to the fully unlocked power you've stolen from "
            "others.\n"
            "(1)-[Passive]: Your maximum number of Primary Racial Traits "
            "gained from the Absorption Awakening is increased to 3.",
      ),
    ],
  ),

  // ========================================================== Namekian Potential ===
  TransformationDef(
    name: "Namekian Potential",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Namekian",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "1+ stacks of the Unlocked Potential Awakening.",
    aspects: [
      "Enhanced Save (All)",
      "Variant (Potential Unleashed)",
      "Natural (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Power Awakening (Depth of Potential)",
        description: "Your true power bursts to the surface in a blaze of "
            "golden splendor.\n"
            "(1)-[Passive]: Increase your maximum number of Power stacks by "
            "your number of stacks for the Unlocked Potential Awakening.\n"
            "(2)-[Passive]: While you possess your maximum number of Power "
            "stacks, increase the Wound Rolls of all of your Signature "
            "Techniques by 1/2 of your Surgency.\n"
            "(3)-[Passive]: While you possess your maximum number of Power "
            "stacks, all Studied Allies have their Combat Rolls increased by "
            "1(T).\n"
            "(4)-[Triggered]: If you possess no stacks of Power when you "
            "trigger the 2nd effect of Intelligent Fighter, you may target an "
            "additional Character through its effects.\n"
            "(5)-[Triggered/Power, 1/Round]: Instead of applying the usual "
            "effects of the Power Up Maneuver, gain your maximum number of "
            "Power stacks until the start of your next turn.\n"
            "(6)-[Automatic/Start of Turn]: If you lose stacks of Power at the "
            "start of this turn, you cannot gain Power Stacks, and you suffer "
            "from the Drained and Fatigued Combat Conditions for the duration "
            "of this turn.",
      ),
      TransformationTrait(
        name: "Awakened Potential (Slumbering Potential) (Legendary Trait)",
        description: "Once it has been brought to the surface, your "
            "once-dormant power refuses to return to its slumber, coming to "
            "your aid in your times of need.\n"
            "(1)-[Passive]: While you have your maximum number of Power "
            "stacks, double the Attribute Modifier Bonus of Unlocked "
            "Potential.\n"
            "(2)-[Passive]: Increase your Surgency by 1(T) for each stack of "
            "the Unlocked Potential Awakening you possess.\n"
            "(3)-[Triggered/Start of Turn, 1/Encounter]: If you possess no "
            "stacks of Power, you may use the Power Up Maneuver or a Healing "
            "Surge as an Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Long Awaited Awakening",
      description: "You have invested countless hours into training, preparing "
          "yourself for this moment.\n"
          "(1)-[Permanent]: Namekian Potential gains the Perfect Ki Control "
          "Aspect.\n"
          "(2)-[Passive]: Ignore the 6th effect of Power Awakening.\n"
          "(3)-[Passive]: While you have no stacks of Power, you cannot gain "
          "the Impaired or Shaken Combat Conditions.\n"
          "(4)-[Passive]: You do not remove Studied from Characters through "
          "your effects, except the 2nd effect of Intelligent Fighter. These "
          "effects still occur as if you removed Studied through their "
          "effects.",
    ),
  ),

  // ===================================================== Crimson Super Saiyan 4 ===
  TransformationDef(
    name: "Crimson Super Saiyan 4",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Access to Super Saiyan 3.",
    aspects: [
      "Variant (Super Saiyan 4)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Bulky",
      "Glowing",
      "Bursting",
      "Power High (LV2)",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Primal Power (Primal Resilience)",
        description: "The power flowing through you awakens your inner beast, "
            "granting you a semblance of its visage.\n"
            "(1)-[Passive]: Increase your base Size Category by 1 Category.\n"
            "(2)-[Passive]: Gain access to the Grippy Grabbers Bestial "
            "Trait.\n"
            "(3)-[Passive]: Your Multiplicative Technique is a Primal "
            "Attack.\n"
            "(4)-[Passive]: For every 4 stacks of Battle Born you possess, "
            "increase your Soak Value, Wound Rolls and Might by 1(T).\n"
            "(5)-[Passive]: While you possess 6+ stacks of Battle Born, reduce "
            "your Muscle Penalty by 1(bT).\n"
            "(6)-[Triggered]: If you use a Primal Attack, increase the Wound "
            "Roll of that Attacking Maneuver by 1(T) for each Energy Charge "
            "that Attacking Maneuver gained through the 3rd effect of Primal "
            "Beating.\n"
            "(7)-[Triggered/Power, 1/Encounter]: Gain a stack of Battle Born, "
            "but reduce your Life Points to be 1 below the next Health "
            "Threshold. You automatically succeed at the Steadfast Check for "
            "this Health Threshold and do not suffer from the effects of "
            "Reduced Momentum.",
      ),
      TransformationTrait(
        name: "Primal Beating (Legendary Trait)",
        description: "Unleashing the full might of your ferocious power, you "
            "smack down anyone who gets in your way.\n"
            "(1)-[Triggered, 1/Encounter]: If you hit an Opponent with a "
            "Primal Attack during your turn, apply a stack of the Broken "
            "Combat Condition to that Opponent until the end of your turn.\n"
            "(2)-[Triggered, 1/Round, Ruling]: If you make an Attacking "
            "Maneuver while in a Transformation with the Super Saiyan Form "
            "Aspect, you can declare that Attacking Maneuver is a 'Primal "
            "Attack'.\n"
            "(3)-[Passive]: For each Health Threshold an Opponent is above "
            "that you are not, apply an Energy Charge to your Primal Attacks. "
            "If there are multiple targets, use the target at the lowest "
            "Health Threshold to calculate the number of Energy Charges "
            "gained.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Scarlet Beast",
        description: "You have reined in the reckless power of this form, "
            "raising it to new heights in the process.\n"
            "(1)-[Permanent]: Crimson Super Saiyan 4 loses the Power High "
            "Aspect and gains M levels of the Scaling Aspect.\n"
            "(2)-[Passive]: Increase the Dice Score of your Steadfast Checks "
            "by 1.",
      ),
      TransformationTrait(
        name: "Primal Crimson",
        description: "The pure force of your attacks overwhelms even the "
            "toughest of enemies.\n"
            "(1)-[Triggered, 1/Encounter]: If you use your Multiplicative "
            "Technique while you possess 9+ stacks of Battle Born and are "
            "below the Injured Health Threshold, set your Damage Category to "
            "Lethal. The Damage Category of this Attacking Maneuver cannot be "
            "lowered by any means.",
      ),
    ],
  ),

  // ================================================== Super Grudge Amplification ===
  TransformationDef(
    name: "Super Grudge Amplification",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Neo-Tuffle",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    aspects: [
      "Enhanced Save (Corporeal/Morale)",
      "Raging (LV2)",
      "High Speed (LV3)",
      "Strainless",
      "Difficult (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "All-Consuming Grievance",
        description: "Your drive for revenge consumes your mind.\n"
            "-[Passive]: This Transformation is also considered to be Super "
            "Tuffle for all of your effects.\n"
            "-[Passive]: This Transformation has access to the Revenge "
            "Amplification trait (see - Super Tuffle).\n"
            "-[Passive]: For every stack of Disdain you possess, increase your "
            "Tier of Power Extra Dice by 1 Dice Category.\n"
            "-[1/Encounter]: If you are below the Injured Health Threshold, "
            "you may use an Ultimate Signature Technique that you have already "
            "used an additional time in this Combat Encounter.\n"
            "-[Triggered, 1/Round]: If you hit an Opponent with an Attacking "
            "Maneuver while in the Raging or Surging State, increase the bonus "
            "to the Wound Roll of that Attacking Maneuver by 1(T) for every 2 "
            "Revenge Points spent on it.\n"
            "-[Triggered/Power, 1/Round]: Enter the Raging or Surging State "
            "until the end of your turn.",
      ),
      TransformationTrait(
        name: "Endless Hate",
        description: "Your loathing for those who destroyed your predecessors "
            "knows no bounds.\n"
            "-[Ruling]: Any Attacking Maneuver that has 2+ Revenge Points "
            "spent on it becomes a \"Hatred Attack\". If an Opponent is hit by "
            "a \"Hatred Attack\", they gain a stack of the Broken Combat "
            "Condition until the end of your turn.\n"
            "-[Passive]: If your Hatred Attack is an Ultimate Signature "
            "Technique or an Attacking Maneuver made through the second effect "
            "of Violent Rebuke, it gains an additional Energy Charge.\n"
            "-[Triggered, 1/Round]: If you hit an Opponent with a Hatred "
            "Attack, you may apply your Tier of Power Extra Dice an additional "
            "time to the Wound Roll.\n"
            "-[Triggered, 1/Round]: If you hit an Opponent with a Hatred "
            "Attack, you may spend 2 Revenge Points to reduce all of their "
            "Resources by 1 (if that Resource is assigned to Combat Rolls or "
            "Opponents, they choose which is affected).",
      ),
      TransformationTrait(
        name: "Terrifying Vengeance (Legendary Trait)",
        description: "Your awakened wrath is a terrifying sight to witness, "
            "leaving all who end up on the receiving end battered and "
            "broken.\n"
            "-[Triggered, 1/Round]: If you hit an Opponent with an Attacking "
            "Maneuver that you spent 2+ Revenge Points on, make a Clash "
            "(Morale) against that Opponent. If you win, that Opponent gains a "
            "stack of the Broken Combat Condition until the end of your turn.",
      ),
      TransformationTrait(
        name: "Purge the Inferior (Exceed Trait)",
        description: "Your seething disgust for the destroyers of your race "
            "expands to cover all other life forms, as you have become "
            "superior to all of them, bar none.\n"
            "-[Triggered, 1/Round]: If your Attacking Maneuver is a Hatred "
            "Attack, you may treat it as an Ultimate Signature Technique for "
            "all of your effects.\n"
            "-[Triggered, 1/Round, 2/Encounter]: If you use an Ultimate "
            "Signature Technique, for every Revenge Point spent on that "
            "Attacking Maneuver, it gains an Energy Charge.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "An Unending Grudge",
      description: "Your hatred grows even deeper, granting you further "
          "strength.\n"
          "-[Permanent]: This Transformation gains the Scaling (LV2) "
          "Aspect.\n"
          "-[Triggered/Transform]: Maximize your Revenge Points. Set your "
          "Revenge Points to 0 at the end of this turn.\n"
          "-[Triggered, 1/Encounter]: If you or an Ally within a Destructive "
          "Sphere AoE (centered on you) is hit by an Opponent's Signature "
          "Technique while you have 2+ Revenge Points, you may use the Basic "
          "Attack Maneuver or the Signature Technique Maneuver as an "
          "Out-of-Sequence Maneuver against that Opponent, but you must spend "
          "at least 2 Revenge Points on that Attacking Maneuver.",
    ),
  ),

  // ============================================================== Super Saiyan 4 ===
  TransformationDef(
    name: "Super Saiyan 4",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Access to Golden Oozaru.",
    aspects: [
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Growth (LV1)",
      "Glowing",
      "Bursting",
      "Blutz Wave",
      "Power High (LV3)",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Utmost Saiyan Power",
        description: "Your Saiyan potential is raised to the absolute maximum, "
            "granting you immense combat power.\n"
            "(1)-[Passive]: Increase the Dice Score of your Duel Clashes by "
            "1(T) for every 4 stacks of Battle Born you possess (max. 2(T)).\n"
            "(2)-[Passive]: Increase the maximum amount of Battle Born stacks "
            "you may possess on each Combat Roll by 1.\n"
            "(3)-[Passive]: For each stack of Battle Born applied to a Combat "
            "Roll, increase the Tier of Power Extra Dice for that Combat Roll "
            "by 1 Dice Category (max. +3 Categories).\n"
            "(4)-[Passive]: Increase your Combat Rolls by 1/2 (rounded up) of "
            "the Apparel Bonus for the piece of Apparel destroyed through the "
            "Bursting Aspect upon entering this Transformation.\n"
            "(5)-[Constant]: Upon leaving this Transformation, regain the "
            "destroyed piece of Apparel from the Bursting Aspect at the same "
            "Break Value it was when destroyed. This piece of Apparel is "
            "already equipped as the Top Layer of Apparel.\n"
            "(6)-[Triggered/Start of Combat Round]: Gain a stack of Battle "
            "Born.\n"
            "(7)-[Triggered/Transform, 1/Encounter]: For each of your Combat "
            "Rolls with 2+ stacks of Battle Born applied to it, gain a stack "
            "of Battle Born.\n"
            "(8)-[Triggered/Transform, Ruling]: Select a Signature Technique "
            "you possess. Until you leave this Transformation, this is your "
            "'Multiplicative Technique': increase its Ki Point Cost by 5(T); "
            "increase its Damage Category by 1; increase its Wound Roll by 1/2 "
            "of the Ki Points spent on its Ki Wager; double the bonus to your "
            "Wound Roll from your Battle Born stacks for that Attacking "
            "Maneuver.",
      ),
      TransformationTrait(
        name: "Primal Resilience",
        description: "Empowered by the bestial might of the mighty Oozaru, you "
            "are far more resistant to damage than before.\n"
            "(1)-[Passive]: Your Size Category is treated as Gigantic for the "
            "sake of your Opponents calculating Punching Down.\n"
            "(2)-[Passive]: For every 4 stacks of Battle Born you possess, "
            "increase your Soak Value, Wound Rolls, and Surgency by 1(T).\n"
            "(3)-[Passive]: While you possess 6+ stacks of Battle Born, "
            "increase the Dice Score of your Steadfast Checks by 1. Double "
            "this bonus if you possess 9+ stacks of Battle Born.\n"
            "(4)-[Passive]: Ignore the second effect of the Superior State.\n"
            "(5)-[Triggered]: If an Opponent initiates a Clash against you "
            "that uses your Might or a Saving Throw, increase the Dice Score "
            "of that Clash by 1(T) for every 3 stacks of Battle Born you "
            "possess (max. +3(T)).\n"
            "(6)-[Triggered]: If you enter the Superior State through the "
            "second effect of Primal Spark, its effects last until the end of "
            "your next turn.\n"
            "(7)-[Triggered/Undying]: If you enter the Undying State through "
            "the 2nd effect of Saiyan Heritage, use a Primal Surge as an "
            "Out-of-Sequence Maneuver.\n"
            "(8)-[Triggered/Entrusted, 1/Encounter]: Use the Transformation "
            "Maneuver as an Out-of-Sequence Maneuver to enter the Super Full "
            "Power Saiyan 4 Evolved Stage (even if you do not have access to "
            "it).",
      ),
      TransformationTrait(
        name: "Primal Saiyan Legacy (Legendary Trait)",
        description: "You're able to draw strength and recover vitality at the "
            "same time by tapping into the primal power you've unlocked.\n"
            "(1)-[Triggered, 1/Encounter]: If you use a Healing Surge, you may "
            "remove a Combat Condition that you are suffering from (except "
            "Pinned, Suffocating, or Transfigured).\n"
            "(2)-[Triggered, Ruling]: If you would use any type of Surge, you "
            "may choose to use a 'Primal Surge' instead: regain 2d10(T) Life "
            "Points and Ki Points. Primal Surges are considered to be both a "
            "Healing Surge and a Ki Surge for the effects of any Traits.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Primal Heart",
        description: "You become one with the Great Ape inside you.\n"
            "(1)-[Permanent]: Super Saiyan 4 loses the Power High Aspect and "
            "gains M levels of the Scaling Aspect.\n"
            "(2)-[Passive]: The 3rd effect of Saiyan Heritage sets your number "
            "of Battle Born stacks on each Combat Roll to 4 instead of 3.\n"
            "(3)-[Triggered, 1/Encounter]: Upon losing a piece of Apparel "
            "through the effects of the Bursting Aspect, gain a stack of "
            "Battle Born.",
      ),
      TransformationTrait(
        name: "Primal Soul",
        description: "You learn to tap into your inner Oozaru's stamina "
            "reserves for a significant boost in power.\n"
            "(1)-[Permanent]: Super Saiyan 4 gains the Natural (LV1) Aspect.\n"
            "(2)-[Passive]: Increase your Damage Reduction by 1(T) for every 4 "
            "stacks of Battle Born you possess (max. 3(T)).\n"
            "(3)-[Triggered/Power, 1/Encounter]: You may use a Primal Surge as "
            "an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ========================================================= Xeno Super Saiyan 4 ===
  TransformationDef(
    name: "Xeno Super Saiyan 4",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Mastered Super Saiyan 1, Primal Class Up Awakening.",
    aspects: [
      "Variant (Super Saiyan 4)",
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Bursting",
      "Power High (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Primal Battle (Primal Resilience)",
        description: "You channel your bestial power into your chosen area of "
            "expertise, becoming even more skilled at your specialization.\n"
            "(1)-[Passive]: While you possess 4+ stacks of Battle Born, "
            "increase your Soak Value, Wound Rolls, and Surgency by 1(T).\n"
            "(2)-[Passive]: While you possess 7+ stacks of Battle Born, "
            "increase your Max Capacity by 12(bT).\n"
            "(3)-[Choice]: Depending on your choice for the Option effect of "
            "Class Selection: Hero [Passive]: while at your Primal Peak, "
            "increase your Combat Rolls by 1(T) while you possess 2+ stacks of "
            "Power; Elite [1/Round]: while at your Primal Peak, as an Instant "
            "Maneuver, regain Life and Ki Points equal to your Surgency; "
            "Berserker [Passive]: while at your Primal Peak, apply an Energy "
            "Charge to your Multiplicative Technique.\n"
            "(4)-[Triggered/Start of Turn]: If you are at your Primal Peak, "
            "enter the Surging State until the end of your turn. Ignore the "
            "2nd effect of the Surging State if you enter it through this "
            "effect.\n"
            "(5)-[Triggered/Transform, 1/Encounter]: If you have 2+ stacks of "
            "Battle Born in your Combat Roll listed for your Option effect of "
            "Class Selection in the 1st effect of Primal Style, gain a stack "
            "of Battle Born in that Combat Roll.",
      ),
      TransformationTrait(
        name: "Primal Style (Legendary Trait)",
        description: "You enhance your chosen combat style with the bestial "
            "ferocity of the Great Ape within you.\n"
            "(1)-[Ruling]: While you have the maximum number of Battle Born "
            "stacks applied to a Combat Roll depending on your choice for the "
            "Option effect of Class Selection, you are at your 'Primal Peak'. "
            "The Combat Rolls in question: Hero: Dodge Roll; Elite: Strike "
            "Roll; Berserker: Wound Roll.\n"
            "(2)-[Passive]: While at your Primal Peak, double the effect of "
            "your choice for the Option effect of Class Selection.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Bestial Class",
      description: "You've taken full control over the savage beast in your "
          "subconscious, claiming all of its might for yourself.\n"
          "(1)-[Permanent]: Xeno Super Saiyan 4 loses the Power High Aspect "
          "and gains 2 levels of the Scaling Aspect.\n"
          "(2)-[Passive]: While at your Primal Peak, increase your Stress "
          "Bonus by 1.\n"
          "(3)-[Triggered/Power, 1/Encounter]: While you possess 7+ stacks of "
          "Battle Born and you are at your Primal Peak, gain a stack of Battle "
          "Born in the Combat Roll listed for your Option effect of Class "
          "Selection in the 1st effect of Primal Style. This stack of Battle "
          "Born can exceed your limit.",
    ),
  ),

  // ============================================================= Super Star Dragon ===
  TransformationDef(
    name: "Super Star Dragon",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Shadow Dragon",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    aspects: [
      "Enhanced Save (Corporeal/Morale)",
      "Strainless",
      "High Speed (LV3)",
      "Dedicated",
      "Power High (LV3)",
      "Difficult (LV2)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Superior Negative Energy",
        description: "Your Negative Energy is more potent than ever before.\n"
            "-[Passive]: For each stack of Negative Energy you possess, "
            "increase your Tier of Power Extra Dice by 1 Dice Category.\n"
            "-[Triggered, 1/Round]: When you gain stacks of the Negative "
            "Energy resource through the first effect of the Negative Energy "
            "trait, you may use the Power Up Maneuver as an Out-of-Sequence "
            "Maneuver.\n"
            "-[Triggered/Power, 1/Encounter]: Trigger the first effect of the "
            "Negative Energy trait.\n"
            "-[Triggered/Power, 1/Encounter]: Reduce your Life Points by 1/5 "
            "of your Maximum Life Points and enter the Superior State until "
            "the end of your next turn.",
      ),
      TransformationTrait(
        name: "Eternal Karma",
        description: "You can tip the karmic balance to work in your favor, "
            "and against your enemies.\n"
            "-[Triggered, Resource]: When you, an Ally within a Destructive "
            "Sphere AoE (centered on you), or an Opponent within your Melee "
            "Range scores a Botch Result, you may reduce your Life Points by "
            "2(bT) to gain 1 stack of Negative Karma (max. 4). Negative Karma "
            "can be spent as if it was Negative Energy for the sake of your "
            "effects.\n"
            "-[Triggered, 1/Round]: If you or an Ally within a Destructive "
            "Sphere AoE (centered on you) scores a Botch Result, you may spend "
            "2 Negative Karma to instead score a Critical Result regardless of "
            "the Natural Result.\n"
            "-[Triggered, 1/Round]: If you hit an Opponent with an Attacking "
            "Maneuver in which you scored a Critical Result on the Wound Roll, "
            "you may spend 1 Negative Karma to apply the Extra Dice gained "
            "from scoring a Critical Result an additional time.\n"
            "-[Triggered, 1/Encounter]: When making an Attacking Maneuver, you "
            "may spend 1 Negative Karma to spend all of your Negative Energy. "
            "For every Negative Energy spent, gain an Energy Charge on that "
            "Attacking Maneuver.",
      ),
      TransformationTrait(
        name: "Supernatural Calamity",
        description: "You are a walking disaster for all those around you, and "
            "you bring misfortune to all who cross you.\n"
            "-[Choice]: Depending on the Option effect(s) of Supernatural "
            "Powers you have access to, gain one of: Sinister Dragon "
            "[Triggered/Power, 1/Round]: reduce your Life Points by up to "
            "4(bT), increase your Wound Rolls by an equal amount until the end "
            "of your turn; Hazy Dragon [Passive]: while in your selected "
            "Battle Weather, increase Damage Reduction by 2(T); Elemental "
            "Dragon [Triggered, 1/Round]: If you knock an Opponent through a "
            "Health Threshold with an Attacking Maneuver of your Favored "
            "Element's Profile, they gain a stack of Impaired until the start "
            "of your next turn; Noble Dragon [Triggered]: If you inflict the "
            "Compelled Combat Condition upon an Opponent through Noble "
            "Dragon's effects, they gain a stack of Impaired until the start "
            "of your next turn; Regenerative Dragon [Triggered/Defeat]: You "
            "are not Defeated and lose all of your Dragon Slimes; for every "
            "Dragon Slime lost, regain Life Points equal to 1/10th of your "
            "Maximum Life Points; Ominous Dragon [Passive]: Gain access to the "
            "Terrify Maneuver, and if you inflict a Combat Condition to an "
            "Opponent through it, that Opponent also suffers Impaired until "
            "the start of your turn; Natural Dragon [Triggered]: Upon gaining "
            "a stack of Absorption, you may increase your Size Category to "
            "Gigantic while you possess that stack, and increase your Soak "
            "Value and Wound Rolls by 1(T) while you possess at least 1 stack "
            "of Absorption.",
      ),
      TransformationTrait(
        name: "Negative Spiral (Legendary Trait)",
        description: "You can turn reality itself against your opponents, "
            "making their goals impossible to reach.\n"
            "-[Triggered, 1/Round]: When you or an Ally within a Destructive "
            "Sphere AoE (centered on you) makes a Combat Roll, you may force "
            "them to score a Botch Result regardless of their Natural Result "
            "and any effects that may prohibit the scoring of a Botch Result. "
            "Then, regain 1d8(T) Ki Points. You may use this effect even when "
            "the Combat Roll would be a Botch Result already due to another "
            "effect.",
      ),
      TransformationTrait(
        name: "Dragon Ascension (Exceed Trait)",
        description: "You have become a god amongst dragons, unparalleled and "
            "unkillable.\n"
            "-[Triggered/Defeated]: Enter the Undying State until the end of "
            "your next turn.\n"
            "-[Triggered, 1/Round]: When you gain a stack of Negative Karma, "
            "you may use the Power Up Maneuver or Energy Charge Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "-[Triggered, 1/Round]: When using a Signature Technique, you may "
            "spend your Life Points instead of your Ki Points for the Ki "
            "Wager. Reduce your Capacity Rate by 1/2 of the Life Points "
            "spent.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Greatest Dragon",
      description: "You have surpassed all other Shadow Dragons, becoming the "
          "strongest of your kind.\n"
          "-[Permanent]: This Transformation gains the Scaling (LV2) "
          "Aspect.\n"
          "-[Triggered, Resource]: Whenever you lose Life Points through one "
          "of your effects, gain an amount of Karmic Ki equal to 1/2 (rounded "
          "up) the amount lost. You may spend your Karmic Ki when making an "
          "Attacking Maneuver to increase your Ki Wager by the amount spent "
          "(max. 1/2 of your Max Capacity on one Attacking Maneuver).\n"
          "-[Permanent]: This Transformation loses the Power High Aspect and "
          "gains the Natural Aspect.",
    ),
  ),

  // ============================================================= Ajisa Namekian ===
  TransformationDef(
    name: "Ajisa Namekian",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Namekian",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Dragon's Blessing Awakening.",
    aspects: ["Enhanced Save (All)", "Growth (LV1)", "Bulky"],
    amb: _legendary6Amb,
    traits: [
      TransformationTrait(
        name: "Orange Guardian",
        description: "Thanks to your pride as a Namekian, you are able to "
            "outlast your opponents and maintain otherwise temporary power "
            "boosts.\n"
            "(1)-[Passive]: While you are Studied through your own effects, "
            "this Transformation gains the Armored Aspect.\n"
            "(2)-[Passive]: Increase your Wound Rolls and Soak Value by 1(T) "
            "while you have both a Studied Opponent and you are Studied "
            "through your own effects.\n"
            "(3)-[Passive]: Increase the Dice Score of your Steadfast Checks "
            "by 1.\n"
            "(4)-[Passive]: Increase your Damage Reduction by 1(T) against the "
            "Attacking Maneuvers of Studied Opponents.\n"
            "(5)-[Passive]: Increase the Damage Category of all your Attacking "
            "Maneuvers that target only Studied Opponents by 1 Category.\n"
            "(6)-[Passive]: The 6th effect of Unleash the Dragon has its "
            "[1/Encounter] Keyword changed to a [1/Round] Keyword.\n"
            "(7)-[Triggered, 1/Round]: If you score a Critical Result on the "
            "Wound Roll of an Attacking Maneuver, apply an Energy Charge to "
            "that Attacking Maneuver.\n"
            "(8)-[Triggered, 1/Encounter]: If you are targeted by the "
            "Attacking Maneuver of a Studied Opponent, you may use the Defend "
            "Maneuver without spending a Counter Action.\n"
            "(9)-[Triggered, 1/Encounter]: If you hit a Studied Opponent with "
            "an Attacking Maneuver, you may score a Critical Result on the "
            "Wound Roll of that Attacking Maneuver regardless of the Natural "
            "Result.",
      ),
      TransformationTrait(
        name: "Mark of Ajisa",
        description: "The Ajisa tree, the symbol of your people which "
            "Namekians have cultivated for generations, marks your newfound "
            "power as the pinnacle of Namekian might.\n"
            "(1)-[Automatic/Transform]: Your top layer of Apparel gains the "
            "Ajisa Mark Special Apparel Quality (without spending any Quality "
            "Slots) until you leave this Transformation. If you are not "
            "wearing any Apparel, instead trigger the 2nd effect of Mark of "
            "Ajisa as if you were wearing Apparel with a High Apparel Grade.\n"
            "(2)-[Triggered, 1/Encounter]: If a piece of Apparel with the "
            "Ajisa Mark Quality is destroyed or Doffed, apply the effects of "
            "Legend Realized, and then maintain the Doff Bonus (ignoring the "
            "bonus from Weights) until you leave this Transformation.\n"
            "(3)-[Triggered/Threshold, 1/Encounter]: Destroy a piece of "
            "Apparel you possess that has the Ajisa Mark Quality. Set your "
            "Life Points to the highest possible amount for your Character "
            "within this Health Threshold.\n"
            "(4)-[Triggered/Power]: You may select a Character that is Studied. "
            "They stop being Studied, and then you may select another "
            "Character to become Studied until the end of the Combat Round.\n"
            "Ajisa Mark Special Apparel Quality — Apparel Category: All; "
            "Quality Slots: N/A. Effects: Double the bonus from the 2nd effect "
            "of Undying Namekian and increase the Dice Score of your Healing "
            "Surges by the Apparel Bonus.",
      ),
      TransformationTrait(
        name: "Undying Namekian (Legendary Trait)",
        description: "Your pride won't let you die easily, and your natural "
            "regenerative abilities make it possible to stay on your feet as "
            "long as it takes to win.\n"
            "(1)-[Passive]: You may target yourself through the 2nd effect of "
            "Intelligent Fighter.\n"
            "(2)-[Passive]: While you are 'Studied' by your own effect, "
            "increase your Combat Rolls and Soak Value by 1(T).\n"
            "(3)-[Passive]: While you are 'Studied' by your own effect, "
            "increase the amount of Life and Ki Points you regain from Legend "
            "Realized by 1/2 of your Surgency.\n"
            "(4)-[Passive]: Ignore the 3rd effect of the Undying State.\n"
            "(5)-[Triggered/Defeated]: Enter the Undying State until the end "
            "of your next turn. If you do, you may use a Healing Surge as an "
            "Out-of-Sequence Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Resilient Potential",
      description: "Your defenses grow even stronger as you become harder and "
          "harder to kill.\n"
          "(1)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n"
          "(2)-[Passive]: Ignore the 2nd effect of the Surging State.\n"
          "(3)-[Passive]: Double the bonus from the 3rd effect of Orange "
          "Guardian.\n"
          "(4)-[Passive]: You may target an additional character through the "
          "2nd effect of Intelligent Fighter.\n"
          "(5)-[1/Round]: If you are below the Injured Health Threshold, you "
          "may use the Power Up Maneuver as an Instant Maneuver.",
    ),
  ),

  // ======================================================= Full Power Super Saiyan ===
  TransformationDef(
    name: "Full Power Super Saiyan",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Fully Mastered Super Saiyan 1.",
    aspects: [
      "Enhanced Save (Impulsive/Corporeal)",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Bursting",
      "Draining (LV2)",
      "Difficult (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Style of Super Saiyan",
        description: "You've grown comfortable enough with your Super Saiyan "
            "power to customize it to meet your needs.\n"
            "(1)-[Permanent, Ruling]: Upon gaining access to this "
            "Transformation, select and gain access to a 'Super Saiyan Style' "
            "Trait while you are in this Transformation.\n"
            "(2)-[Passive]: For each stack of Power you possess, increase your "
            "Soak Value by 1(T).\n"
            "(3)-[Passive]: Gain an additional stack of Power from the Power "
            "Up Maneuver.\n"
            "(4)-[Passive]: Increase your Combat Rolls by 1/2 (rounded up) of "
            "the Apparel Bonus for the piece of Apparel destroyed through the "
            "Bursting Aspect upon entering this Transformation.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Gain a stack of Battle "
            "Born.\n"
            "Select your Super Saiyan Style Trait below "
            "(prerequisite-gated).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Super Saiyan Style Trait',
            options: [
              TraitOption(
                name: 'Legendary Super Saiyan',
                description: '(1)-[Prerequisite]: Legendary Saiyan Factor '
                    'Trait. (2)-[Permanent]: Reduce the Stress Test '
                    'Requirement of the Legendary Evolved Stage with this '
                    'Transformation as its Original Form by 3. (3)-[Passive]: '
                    'Increase your Might by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.might],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: 'Back to Basics',
                description: '(1)-[Prerequisite]: Access to Super Saiyan 1 '
                    '(Variants do not count). (2)-[Passive]: You gain access '
                    'to the Option effect you chose for the 3rd effect of '
                    'S-Cells. (3)-[1/Round]: While you have 4+ stacks of '
                    'Battle Born, you may use the Power Up Maneuver as an '
                    'Instant Maneuver. (4)-[Passive]: Depending on your number '
                    'of Power stacks: 2+ Power Stacks [Triggered, 1/Round]: '
                    'When making an Attacking Maneuver, add up to 2 Energy '
                    'Charges (after concluding, lose Battle Born stacks equal '
                    'to Energy Charges added). 4+ Power Stacks [Passive]: '
                    'Increase the Wound Roll of any Signature Technique with a '
                    'Ki Wager by 1/2 of the amount of Ki Points wagered.',
              ),
              TraitOption(
                name: "You Can't Destroy What I Am! (Future SS)",
                description: '(1)-[Prerequisite]: Access to Future Super '
                    'Saiyan. (2)-[Passive]: Increase S for the 1st effect of '
                    'Desperate Hero by 1 for every 4 stacks of Battle Born '
                    '(max. +3). (3)-[1/Round]: While below the Injured Health '
                    'Threshold, you may use the Power Up Maneuver as an '
                    'Instant Maneuver.',
              ),
              TraitOption(
                name: 'Superior Pain, Superior Power (Superior SS)',
                description: '(1)-[Prerequisite]: Access to Superior Super '
                    'Saiyan. (2)-[Passive]: For every 4 stacks of Battle Born, '
                    'increase your Surgency by 1(T) (max. 3(T)). '
                    '(3)-[Triggered]: If you are hit by an Attacking Maneuver, '
                    'regain Ki Points equal to 1/4 (rounded up) of your '
                    'Surgency. (4)-[Triggered/Power, 1/Round]: Spend a stack '
                    'of Battle Born to regain Life Points equal to 1/2 of your '
                    'Surgency and enter the Superior State until the end of '
                    'your turn.',
              ),
              TraitOption(
                name: 'Greater Super Class (Xeno SS)',
                description: '(1)-[Prerequisite]: Access to Xeno Super Saiyan. '
                    '(2)-[Passive]: You gain access to the 4th effect of Super '
                    'Saiyan Class. (3)-[1/Encounter]: If you have 6+ stacks of '
                    'Battle Born, use your Choice effect for the 3rd effect of '
                    'Class Selection (does not count towards its 1/Encounter '
                    'Keyword).',
              ),
              TraitOption(
                name: 'Pinnacle of Legacy (Ancestral SS)',
                description: '(1)-[Prerequisite]: Access to Ancestral Super '
                    'Saiyan. (2)-[Passive]: While in the Undying State, '
                    'increase your Soak Value and Wound Rolls by 2(T), and '
                    'this Transformation gains the Armored Aspect. '
                    '(3)-[1/Round]: As an Instant Maneuver, spend a stack of '
                    'Battle Born to use the Power Up Maneuver. '
                    '(4)-[Triggered/Power, 1/Encounter]: Enter the Undying '
                    'State until the start of your next turn.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Full Power of the Super Saiyan",
        description: "Unleashing the unlimited potential of the Super Saiyan "
            "Transformation, you draw out even more raw power.\n"
            "(1)-[Passive]: Increase the Dice Score of your Duel Clashes by "
            "1(T) for every 4 stacks of Battle Born you possess (max. 3(T)).\n"
            "(2)-[Passive]: For every 4 stacks of Battle Born you possess, "
            "increase your Tier of Power Extra Dice by 1 Category (max. +3 "
            "Categories).\n"
            "(3)-[Triggered]: If you are hit by an Attacking Maneuver, you may "
            "increase your Damage Reduction by 1(T) for every 2 stacks of "
            "Battle Born you possess for the duration of that Attacking "
            "Maneuver. After concluding that Maneuver, lose 1 stack of Battle "
            "Born.\n"
            "(4)-[Triggered]: If you hit an Opponent with an Attacking "
            "Maneuver, you may increase your Wound Rolls by 1(T) for every 2 "
            "stacks of Battle Born you possess for the duration of that "
            "Attacking Maneuver. After concluding that Maneuver, lose 1 stack "
            "of Battle Born.\n"
            "(5)-[Triggered/Transform, 1/Encounter]: Enter the Raging State "
            "until the end of your turn.",
      ),
      TransformationTrait(
        name: "True Power of the Saiyan Race (Legendary Trait)",
        description: "You know beyond a shadow of a doubt that the classics "
            "are the best, and you rock those golden flames and green eyes "
            "with effortless swagger.\n"
            "(1)-[Passive]: Your stacks of Power are treated as if they are "
            "Battle Born stacks applied to your Wound Rolls for your effects "
            "(they do not count towards your maximum number of Battle Born).\n"
            "(2)-[Passive]: For each stack of Power you possess, increase your "
            "Wound Rolls by 1(T).\n"
            "(3)-[Passive]: While in a Transformation with the Super Saiyan "
            "Form Aspect, double the increase to your Capacity from that "
            "Aspect.\n"
            "(4)-[Triggered, 1/Encounter]: If you succeed at the Steadfast "
            "Check for a Health Threshold, you may use the Transformation "
            "Maneuver as an Out-of-Sequence Maneuver to attempt to enter a "
            "Transformation with the Super Saiyan Form Aspect.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Deeper into the Depths",
        description: "You dig deep, pulling out even more power from the "
            "classic Super Saiyan Transformation, utilizing it in a superior "
            "manner.\n"
            "(1)-[Permanent]: Full Power Super Saiyan gains M levels of the "
            "Scaling Aspect and loses M levels of the Draining Aspect.\n"
            "(2)-[Passive]: Increase your maximum number of Power stacks by "
            "M.\n"
            "(3)-[Passive]: Treat the Superior State as the Raging State for "
            "the effects of the Raging Aspect.\n"
            "(4)-[Triggered]: When you use the 5th effect of Full Power of the "
            "Super Saiyan, you may enter the Superior State instead of the "
            "Raging State. If you do, the effect lasts until the start of your "
            "next turn.",
      ),
      TransformationTrait(
        name: "Limit of the Super Saiyan",
        description: "You aren't just a living legend anymore, you've "
            "transformed your power into one that surpasses even the original "
            "legend themself.\n"
            "(1)-[Permanent]: Full Power Super Saiyan gains the Perfect Ki "
            "Control Aspect.\n"
            "(2)-[1/Round]: As an Instant Maneuver, you can spend a stack of "
            "Battle Born to regain Ki Points and Capacity equal to 1/4 of your "
            "Max Capacity.\n"
            "(3)-[1/Encounter]: As an Instant Maneuver, you may spend a stack "
            "of Battle Born to use a Healing Surge as an Out-of-Sequence "
            "Maneuver.",
      ),
    ],
  ),

  // ================================================================== Dark King ===
  TransformationDef(
    name: "Dark King",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Shinjin",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Mastered Initial Demon God.",
    aspects: [
      "Enhanced Save (Cognitive/Morale)",
      "Battle Uniform",
      "God Ki",
      "Perfect Ki Control",
      "Strainless",
      "High Speed (LV3)",
      "Dedicated",
      "Difficult (LV1)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.combatClothing,
      craftsmanshipGrade: 5,
    ),
    amb: _legendary6Amb,
    traits: [
      TransformationTrait(
        name: "Dark Lineage",
        description: "You have awakened the royal blood of demonic divinity, "
            "granting you unassailable power.\n"
            "-[Passive]: While your Divine Ki Points exceed 1/2 of the Divine "
            "Ki Points you possessed at the start of the Combat Encounter, you "
            "possess Greater Dice.\n"
            "-[Passive]: When using Divine Ki Points to pay the Ki Point Cost "
            "of any Attacking Maneuver, reduce the Ki Point Cost by 2(T). This "
            "reduction can cause the Ki Point Cost to be reduced below its "
            "minimum. If the Ki Point Cost of a Maneuver is 2(T) or less, you "
            "can spend 1 Divine Ki Point for that Attacking Maneuver's Ki "
            "Point Cost.\n"
            "-[Passive]: This Trait gains the 4th effect of Divine Dark Magic "
            "(see — Initial Demon God).\n"
            "-[Triggered, 1/Round]: If you would use an Attacking Maneuver that "
            "you paid the Ki Point Cost of with Divine Ki Points, increase the "
            "Damage Category of that Attacking Maneuver by 1 Category.",
      ),
      TransformationTrait(
        name: "Dark Factor",
        description: "You possess a unique life force that grants you your "
            "supreme might over all creation.\n"
            "-[Passive]: All Opponents who are below the Injured Health "
            "Threshold are treated as having a Combat Condition for the sake "
            "of your effects.\n"
            "-[Passive]: Reduce the Ki Point Cost of the second effect of "
            "Skill of the Watcher by 2(T) and increase your Dice Score for the "
            "Clash initiated through its effect by 1(T).\n"
            "-[Permanent, Multi-Option/2]: Select 2 of the following:",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Dark King Options',
            maxChoices: 2,
            options: [
              TraitOption(
                name: "King's Gauntlets",
                description: '[Passive]: Increase your Damage Reduction by '
                    '1(T) and your Wound Rolls by 1d4(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.damageReduction],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: "King's Finisher",
                description: '[Triggered/Transform]: Select one of your '
                    'Signature Techniques; until you leave this '
                    'Transformation, whenever you use it, it gains an Energy '
                    'Charge and has its Wound Roll increased by 1/2 of any Ki '
                    'Wager applied to it (but it can only be used if you spend '
                    'Divine Ki Points to pay its Ki Point Cost).',
              ),
              TraitOption(
                name: "King's Wild Side",
                description: '[Permanent, Passive]: Upon gaining access to '
                    'this effect, select a Bestial Trait and gain access to '
                    'it while you have this effect. Additionally, increase '
                    'your Soak Value by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                  ),
                ],
              ),
              TraitOption(
                name: "King's Cloak",
                description: '[Permanent, Passive]: Upon gaining access to '
                    'this effect, create an Aura with a TP Cost of 50 that '
                    'possesses the Restricted Aura Disadvantage with Dark King '
                    'selected for its effects. You do not need to pay Ki '
                    'Points to enter that Aura, but you must possess this '
                    'effect to enter it.',
              ),
              TraitOption(
                name: "King's Shadow",
                description: '[1/Encounter]: Create a Duplicate Minion of the '
                    'Gigantic Size Category (it does not benefit from the 3rd '
                    'effect of the Dark Factor Trait while in the Dark King '
                    'Transformation).',
              ),
              TraitOption(
                name: 'Dark Factor: Liberation',
                description: '[Triggered, 1/Round]: When you are targeted by '
                    'an Attacking Maneuver, spend 2(bT) Divine Ki Points to '
                    'use the Defend Maneuver in response without spending a '
                    'Counter Action.',
              ),
              TraitOption(
                name: 'Dark Factor: Empower',
                description: '[Triggered]: When you use an Attacking Maneuver, '
                    'spend up to 4(bT) Divine Ki Points to increase your Wound '
                    'Roll for that Attacking Maneuver by triple the amount of '
                    'Divine Ki Points spent.',
              ),
              TraitOption(
                name: 'Dark Factor: Enhance',
                description: '[Triggered]: When you are targeted by an '
                    'Attacking Maneuver, spend up to 4(bT) Divine Ki Points to '
                    'increase your Damage Reduction by twice the amount of '
                    'Divine Ki Points spent for the duration of that Attacking '
                    'Maneuver.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Bow to the King (Legendary Trait)",
        description: "All those who oppose you feel the weight of your "
            "crushing power.\n"
            "-[Passive]: Increase your Combat Rolls by 1(T) against Opponents "
            "who are suffering from a Combat Condition.\n"
            "Battle Uniform — Combat Clothing, High Grade. Demon King: Reduce "
            "the Combat Rolls of all Opponents suffering from a Combat "
            "Condition within a Sphere AoE (centered on you) by 1(T). Royal "
            "Gown: This piece of Apparel also benefits from the effects of the "
            "Armor Apparel Category and increases your Wound Rolls by your "
            "Apparel Bonus.",
      ),
      TransformationTrait(
        name: "Winged King (Exceed Trait)",
        description: "You have not even begun to show your true strength yet, "
            "but soon all will see your divine demonic might.\n"
            "-[Passive]: This Transformation gains the Graded Aspect.\n"
            "-[Passive]: Increase the Wound Rolls of your Attacking Maneuvers "
            "by G(T) that target Opponents with a Combat Condition.\n"
            "-[Graded]: Dark King has 3 Grades (Grade: ToP Extra Dice | AMB "
            "(FO/MA) | Effect):\n"
            "No Wings (1): 1 Category | N/A | [Passive]: Gain the third effect "
            "of Demonic Fury.\n"
            "One Wing (2): 2 Categories | +1(T) | [Passive]: You possess the "
            "Bestial Movement Trait with the Wings effect chosen for the "
            "Option effect.\n"
            "Two Wings (3): 3 Categories | +2(T) | [Triggered/Start of Combat "
            "Round]: Regain 3(bT) Divine Ki Points.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Lord of Demons",
      description: "You rule over all other demons through your sheer might "
          "and terrifying willpower.\n"
          "-[Permanent]: This Transformation loses the Strainless Aspect and "
          "gains the Natural Aspect.\n"
          "-[Passive]: While your Divine Ki Points are below 1/2 of the Divine "
          "Ki Points you possessed at the start of the Combat Encounter, "
          "increase your Wound Rolls by your Insight Modifier.\n"
          "-[Permanent, Passive]: Upon gaining this Mastery, select two "
          "additional effects through the third effect of Dark Factor. You "
          "gain access to those effects while you are in the Full Power "
          "State.",
    ),
  ),

  // ============================================================= Dark Demon God ===
  TransformationDef(
    name: "Dark Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Shinjin",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Fully Mastered Dark Demon.",
    transformationLine: "Demon God",
    stage: 2,
    aspects: [
      "Enhanced Save (Cognitive/Morale)",
      "High Speed (LV3)",
      "Variant (True Demon God)",
      "God Ki",
      "Battle Uniform",
      "Dedicated",
      "Exhausting",
      "Draining (LV2)",
      "Difficult (LV1)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.combatClothing,
      craftsmanshipGrade: 5,
    ),
    amb: _legendary6Amb,
    traits: [
      TransformationTrait(
        name: "Fraction of the Dark Factor (Demonic Fury)",
        description: "You have absorbed a small piece of Dark Factor, granting "
            "you a surge of strength.\n"
            "-[Triggered, 1/Round]: If you deal Damage to an Opponent with a "
            "Signature Technique, you may spend 3(bT) Divine Ki Points to "
            "apply the Guard Down Combat Condition to that Opponent until the "
            "start of their turn, or until the end of your next Ally's turn "
            "(whichever comes first).\n"
            "-[Triggered, 1/Round]: If you pay Ki Points to enter an Aura, or "
            "to maintain an existing Aura while an Opponent is within your "
            "Melee Range, you may spend 2(bT) Divine Ki Points to spend the Ki "
            "Points of that Opponent instead for that Aura's Ki Point Cost.\n"
            "-[Triggered, 1/Round]: If you use a Magical Unique Ability, you "
            "may spend 2(bT) Divine Ki Points. If you do, all Opponents within "
            "your Melee Range have their Life Points reduced by 1/2 of your "
            "Might.\n"
            "-[Triggered, 1/Encounter]: When you use an Attacking Maneuver, "
            "gain 2 Energy Charges on that Attacking Maneuver.\n"
            "-[Triggered/Power, 1/Encounter]: Regain a number of Divine Ki "
            "Points equal to twice your Power Level.\n"
            "-[Permanent, Option]: Select one of the following:",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Dark Factor',
            options: [
              TraitOption(
                name: 'Dark Factor: Liberation',
                description: '[Triggered, 1/Round]: When you are targeted by '
                    'an Attacking Maneuver, spend 2(bT) Divine Ki Points to '
                    'use the Defend Maneuver in response without spending a '
                    'Counter Action.',
              ),
              TraitOption(
                name: 'Dark Factor: Empower',
                description: '[Triggered]: When you use an Attacking Maneuver, '
                    'spend up to 4(bT) Divine Ki Points to increase your Wound '
                    'Roll for that Attacking Maneuver by triple the amount of '
                    'Divine Ki Points spent.',
              ),
              TraitOption(
                name: 'Dark Factor: Enhance',
                description: '[Triggered]: When you are targeted by an '
                    'Attacking Maneuver, spend up to 4(bT) Divine Ki Points to '
                    'increase your Damage Reduction by twice the amount of '
                    'Divine Ki Points spent for the duration of that Attacking '
                    'Maneuver.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Limitless Darkness (Exceed Trait)",
        description: "You have gazed so long into the abyss that the abyss now "
            "gazes at all creation through you.\n"
            "-[Passive]: You may spend Ki Points to use the effects of the 6th "
            "effect of Fraction of the Dark Factor, instead of Divine Ki "
            "Points.\n"
            "-[Triggered]: If you would use a Standard Maneuver that has an "
            "Action Cost of 1 Action, gain 1(bT) Divine Ki Points.\n"
            "-[Triggered]: If you spend Divine Ki Points, regain Ki Points "
            "equal to 1/2 of the Divine Ki Points spent.\n"
            "Battle Uniform — Combat Clothing, High Grade. Divine Darkness: "
            "Reduce the Defense Value of all Opponents within a Sphere AoE "
            "(centered on you) by 1(T). Soaked in Darkness: Regain 1(bT) "
            "Divine Ki Points each time you inflict a Combat Condition to an "
            "Opponent.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Depths of Darkness",
      description: "You've dived deeper and deeper into the Dark Factor, "
          "drawing out more and more of its power with greater and greater "
          "ease.\n"
          "-[Permanent]: This Transformation loses the Exhausting Aspect.\n"
          "-[Passive]: While in the Full Power State, you gain access to all "
          "effects granted by the 6th effect of Fraction of the Dark "
          "Factor.\n"
          "-[Permanent]: This Transformation loses the Draining Aspect and "
          "gains the Strainless Aspect.",
    ),
  ),

  // ==================================== Divine Saiyan line (Super Saiyan God Stage
  // 1 + Super Saiyan Blue Stage 2; True Super Saiyan God and Super Saiyan Rosé are
  // Variant stages of the same line).
  // ============================================ Divine Saiyan: Super Saiyan God ===
  TransformationDef(
    name: "Super Saiyan God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "You may become a Super Saiyan God through divine "
        "training, or by gathering six Saiyans with a Good Z-Soul (including "
        "yourself) and having five of them target you with the Super Saiyan "
        "God Ritual Maneuver (usable only by Characters who have gained "
        "information on the ritual).",
    transformationLine: "Divine Saiyan",
    stage: 1,
    aspects: [
      "Enhanced Save (Impulsive/Corporeal/Cognitive)",
      "God Ki",
      "Innate State (Radiant God)",
      "Glowing",
      "Natural (LV1)",
      "Fading (LV1)",
      "Limited (LV5)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Battle of Gods",
        description: "Your lust for battle, now enhanced by the might of your "
            "divine transformation, rises rapidly, adapting you for combat "
            "with other divine beings.\n"
            "(1)-[Passive]: While you possess 1+ stacks of Divine Battle Born, "
            "increase the Dice Score of your Duel Clashes by 1(T).\n"
            "(2)-[Passive]: While you possess 1+ stacks of Divine Battle Born, "
            "you have access to the Divine Flame God Maneuver.\n"
            "(3)-[Passive]: While you possess 2+ stacks of Divine Battle Born, "
            "increase your Soak Value by 1(T).\n"
            "(4)-[Passive]: While you possess 2+ stacks of Divine Battle Born, "
            "you have access to the Divine Attack God Maneuver.\n"
            "(5)-[Triggered/Threshold, 1/Encounter]: Use a Healing Surge as an "
            "Out-of-Sequence Maneuver. If you do, gain a stack of Divine "
            "Battle Born.",
      ),
      TransformationTrait(
        name: "Red Flame of Life",
        description: "The burning aura surrounding you keeps you fired up to "
            "stay in the fight.\n"
            "(1)-[Passive]: You have access to the Divine Breathing God "
            "Maneuver.\n"
            "(2)-[Passive]: While you possess 3+ stacks of Divine Battle Born, "
            "you have access to the Divine Counter God Maneuver.\n"
            "(3)-[1/Round]: While you possess 3+ stacks of Divine Battle Born, "
            "you may use the Defend Maneuver without spending a Counter "
            "Action.\n"
            "(4)-[Triggered]: If you would use a Ki Surge through an effect, "
            "you may use a Healing Surge instead.\n"
            "(5)-[Triggered, 1/Round]: If you use a Healing Surge, regain "
            "Divine Ki Points equal to 1/2 of your Surgency.\n"
            "(6)-[Triggered/Power, 1/Encounter]: Use a Healing Surge. Then, "
            "enter the Superior State until the start of your next turn.",
      ),
      TransformationTrait(
        name: "Song of Hope (Legendary Trait)",
        description: "Thanks to the divine energy that now flows through you, "
            "you can empower your body with godly strength for a short time.\n"
            "(1)-[Triggered/Start of Combat Round, Resource]: If you would "
            "gain a stack of Battle Born through the first effect of Born for "
            "Battle, gain a stack of 'Divine Battle Born' (max. 3) instead. "
            "Each stack increases your Wound Rolls by 1(T) and counts as a "
            "Battle Born stack applied to your Wound Roll for your effects "
            "(not towards your Battle Born limit).\n"
            "(2)-[Passive]: While in a Transformation of the Divine Saiyan Line "
            "and/or the Radiant God State, increase your Strike and Dodge "
            "Rolls by 1(T) for each stack of Divine Battle Born.\n"
            "(3)-[Triggered, 1/Round]: If you use a Healing Surge, regain Ki "
            "Points equal to 1/2 of your Surgency.\n"
            "(4)-[Triggered, 1/Encounter]: If you leave a Divine Saiyan Line "
            "Transformation due to failing a Stress Test or the Limited "
            "Aspect, you may enter an Alternate Form with 1+ level of Natural "
            "(ignoring Stress Exhaustion); if you do, enter the Radiant God "
            "State until you leave it.\n"
            "Radiant God Special State — (1)-[Passive]: Increase your "
            "Surgency by 1(T) for every stack of Divine Battle Born you "
            "possess. (2)-[Triggered, 1/Round]: If you use a Signature "
            "Technique, increase its Wound Roll by 1(T) for each stack of "
            "Divine Battle Born you possess. (3)-[Triggered, 1/Round]: If you "
            "are hit by an Attacking Maneuver, for its duration increase your "
            "Damage Reduction by 1(T) for each stack of Divine Battle Born you "
            "possess. (4)-[Triggered/Power, 1/Encounter]: If you are below the "
            "Injured Health Threshold, double your amount of Divine Battle "
            "Born stacks until the start of your next turn (if you do, you "
            "cannot regain Life, Ki, or Divine Ki Points until then).",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Ignited Crimson Flame",
      description: "The scarlet blaze of divine power that you wield now heeds "
          "your command.\n"
          "(1)-[Permanent]: Super Saiyan God loses the Fading and Limited "
          "Aspects, and gains the Perfect Ki Control Aspect.\n"
          "(2)-[Permanent, Passive]: Upon gaining this Mastery Trait, select 2 "
          "God Maneuvers. Gain access to those while in the Super Saiyan God "
          "Transformation.\n"
          "(3)-[Passive]: While in the Superior State, all Transformations in "
          "the Divine Saiyan Transformation Line gain the Armored Aspect.\n"
          "(4)-[Triggered/Power, 1/Round]: You may spend 2 stacks of Battle "
          "Born to gain a stack of Divine Battle Born.",
    ),
  ),

  // ============================================ Divine Saiyan: Super Saiyan Blue ===
  TransformationDef(
    name: "Super Saiyan Blue",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Mastered Super Saiyan 1.",
    transformationLine: "Divine Saiyan",
    stage: 2,
    aspects: [
      "Enhanced Save (Cognitive/Impulsive/Corporeal)",
      "God Ki",
      "Perfect Ki Control",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Weakening",
      "Draining (LV2)",
      "Difficult (LV1)",
    ],
    amb: _legendary6Amb,
    traits: [
      TransformationTrait(
        name: "Blue Saiyan",
        description: "The azure haze of aura that clings to you combines the "
            "familiar spark of the Super Saiyan you have long wielded with the "
            "nascent divine embers you have recently cultivated to become "
            "something greater.\n"
            "(1)-[Passive]: While you have 2+ stacks of Divine Battle Born, "
            "increase the Tier of Power Extra Dice for your Combat Rolls by 1 "
            "Category and increase your Damage Reduction by 1(T).\n"
            "(2)-[1/Round]: While you have 6+ stacks of Battle Born, you may "
            "use the Power Up Maneuver as an Instant Maneuver.\n"
            "(3)-[Triggered/Power, 1/Round]: Spend 5(bT) Divine Ki Points to "
            "enter the Radiant God State until the start of your next turn.\n"
            "(4)-[Permanent, Option]: Select one (based on a Transformation "
            "you have access to) below.",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Blue Style Trait',
            options: [
              TraitOption(
                name: 'Blue Classic (Super Saiyan 1)',
                description: '[Passive]: You gain access to the Option effect '
                    'you chose for the 3rd effect of S-Cells.',
              ),
              TraitOption(
                name: 'Blue Legacy (Ancestral Super Saiyan)',
                description: '[Passive]: You gain access to the 5th effect of '
                    'Origin of the Warrior Race.',
              ),
              TraitOption(
                name: 'Blue Defender (Future Super Saiyan)',
                description: '[Passive]: You gain access to the 3rd effect of '
                    'Stand Against Evil.',
              ),
              TraitOption(
                name: 'Blue Dominance (Superior Super Saiyan)',
                description: '[Passive]: You gain access to the 4th effect of '
                    'Crazed Battle Lust.',
              ),
              TraitOption(
                name: 'Blue Class (Xeno Super Saiyan)',
                description: '[Passive]: You gain access to the 4th effect of '
                    'Super Saiyan Class.',
              ),
              TraitOption(
                name: 'Blue Power (All-Out Form)',
                description: '[Passive]: You gain access to the 5th effect of '
                    'Unleash it All.',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Blue Flame of Power (Red Flame of Life)",
        description: "The sparkling aura surrounding you in this form gives "
            "you great strength and restores your energy.\n"
            "(1)-[Passive]: Increase the Dice Score for your Duel Clashes by "
            "1(T).\n"
            "(2)-[Passive]: Increase your maximum number of Energy Charges by "
            "1 for every 3 stacks of Battle Born you possess (max. 2).\n"
            "(3)-[Passive]: While you possess 3 stacks of Divine Battle Born, "
            "apply your Damage Attribute an additional time to your Attacking "
            "Maneuvers that have 3+ Energy Charges.\n"
            "(4)-[Triggered, 1/Encounter]: If you spend Divine Ki Points to "
            "apply a Ki Wager to an Ultimate Signature Technique, increase the "
            "Wound Roll of that Attacking Maneuver by 1/2 of the amount of "
            "Divine Ki Points spent on the Ki Wager.\n"
            "(5)-[Triggered/Power, 1/Encounter]: If you have 3 stacks of "
            "Divine Battle Born or are below the Injured Health Threshold, use "
            "a Ki Surge as an Out-of-Sequence Maneuver. If you do, regain "
            "Divine Ki Points equal to your Surgency.",
      ),
      TransformationTrait(
        name: "Breakthrough the Limit (Legendary Trait)",
        description: "You obey no masters, brook no arguments, and accept no "
            "limitations.\n"
            "(1)-[Passive]: While you possess 2+ stacks of Divine Battle Born, "
            "increase your Tier of Power Extra Dice by 1 Dice Category.\n"
            "(2)-[1/Round]: If you are in the Radiant God State, you may use "
            "the Energy Charge Maneuver as an Instant Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique, it gains an Energy Charge (max. 3) for every 2 Battle "
            "Born Stacks you possess.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Tamed Blue Flame",
        description: "You've taken full control over the sapphire cloud of "
            "divine power you now wield, truly becoming a god in your own "
            "right.\n"
            "(1)-[Permanent]: You gain access to the Perfected Constraint "
            "Evolved Stage for Super Saiyan Blue.\n"
            "(2)-[Permanent, Passive]: Upon gaining this Mastery Trait, select "
            "2 God Maneuvers. Gain access to those while in the Super Saiyan "
            "Blue Transformation.",
      ),
      TransformationTrait(
        name: "Fully Perfected Super Saiyan Blue",
        description: "Your mastery of the godly power infused into this "
            "Transformation has given you the ability to reduce the energy "
            "leaking out of your body.\n"
            "(1)-[Permanent]: Super Saiyan Blue loses the Weakening Aspect and "
            "the Draining Aspect.\n"
            "(2)-[Triggered/Radiant God, 1/Encounter]: Enter the Superior "
            "State until the end of the turn.",
      ),
    ],
  ),

  // ============================================ Divine Saiyan: True Super Saiyan God ===
  TransformationDef(
    name: "True Super Saiyan God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Spark of Divinity.",
    transformationLine: "Divine Saiyan",
    stage: 1,
    aspects: [
      "Variant (Super Saiyan God)",
      "Enhanced Save (Impulsive/Corporeal/Cognitive)",
      "God Ki",
      "Innate State (Radiant God)",
      "Glowing",
      "Natural (LV1)",
    ],
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Saiyan God (Battle of Gods)",
        description: "Awakening to true divine power buried deep within you, "
            "you are not a mere imitation of a deity, but something more.\n"
            "(1)-[Passive]: While you possess 1+ stacks of Divine Battle Born, "
            "increase the Dice Score of your Duel Clashes by 1(T).\n"
            "(2)-[Passive]: While you possess 1+ stacks of Divine Battle Born, "
            "you have access to the Divine Flame God Maneuver.\n"
            "(3)-[Passive]: While you possess 2+ stacks of Divine Battle Born, "
            "increase your Surgency by 1(T).\n"
            "(4)-[Passive]: While you possess 2+ stacks of Divine Battle Born, "
            "you have access to the Divine Attack God Maneuver.\n"
            "(5)-[Passive]: While you are in the Blazing God State, double the "
            "amount of Divine Ki Points regained by the 4th effect of Awoken "
            "Embers.\n"
            "(6)-[Triggered/Start of Turn, 1/Encounter]: If you have 3+ stacks "
            "of Divine Battle Born, enter the Blazing God State until you "
            "leave the Divine Saiyan Transformation Line.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Ignited Divine Embers",
      description: "The scarlet blaze of your divine power seeps into your "
          "very soul, forever changing you.\n"
          "(1)-[Permanent]: True Super Saiyan God gains the Perfect Ki Control "
          "Aspect.\n"
          "(2)-[Permanent, Passive]: Upon gaining this Mastery Trait, select 2 "
          "God Maneuvers. Gain access to those while in the True Super Saiyan "
          "God Transformation.\n"
          "(3)-[Passive]: While in the Blazing God State, all Transformations "
          "in the Divine Saiyan Transformation Line gain the Armored Aspect.\n"
          "(4)-[Triggered/Power, 1/Round]: You may spend 2 stacks of Battle "
          "Born to gain a stack of Divine Battle Born.",
    ),
  ),

  // ============================================ Divine Saiyan: Super Saiyan Rosé ===
  TransformationDef(
    name: "Super Saiyan Rosé",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 5,
    stressTestRequirement: 30,
    prerequisiteText: "Divine Candidate (or a Divine Role) and access to Super "
        "Saiyan 1. Does not require access to the lower stage of its line.",
    transformationLine: "Divine Saiyan",
    stage: 2,
    aspects: [
      "Variant (Super Saiyan Blue)",
      "Enhanced Save (Cognitive/Impulsive/Corporeal)",
      "God Ki",
      "Perfect Ki Control",
      "Super Saiyan Form",
      "Raging",
      "Glowing",
      "Light Dependent",
      "Power High (LV3)",
    ],
    amb: _legendary6Amb,
    traits: [
      TransformationTrait(
        name: "Pink Flame of Divinity (Blue Flame of Power)",
        description: "The godly aura of divinity surrounding you grants you "
            "far greater mastery over the godly energy you wield.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select a God Maneuver. While in this "
            "Transformation, you have access to that God Maneuver.\n"
            "(2)-[Passive]: Increase the Dice Score for your Duel Clashes by "
            "1(T).\n"
            "(3)-[Passive]: While you possess 3 stacks of Divine Battle Born, "
            "increase your Wound Rolls by 1/4 of your Surgency.\n"
            "(4)-[Triggered/Start of Turn]: Regain Divine Ki Points equal to "
            "1/4 of your Surgency.\n"
            "(5)-[Triggered, 1/Round]: If you spend Divine Ki Points to pay "
            "the Ki Point Cost of a Signature Technique, increase the Wound "
            "Roll of that Attacking Maneuver by 1/2 of your Surgency.\n"
            "(6)-[Triggered/Power, 1/Encounter]: If you have 3 stacks of "
            "Divine Battle Born, use a Ki Surge as an Out-of-Sequence Maneuver. "
            "If you do, enter the Superior State until the start of your next "
            "turn.",
      ),
      TransformationTrait(
        name: "Empowered by Pain (Breakthrough the Limit) (Legendary Trait)",
        description: "You are able to quickly turn your pain into combat "
            "power.\n"
            "(1)-[Passive]: Gain the Song of Hope Legendary Trait if you do "
            "not already possess it.\n"
            "(2)-[Passive]: Increase your Surgency by 1(T) for every stack of "
            "Divine Battle Born you possess after the first.\n"
            "(3)-[Triggered/Threshold]: If you are in the God Ki Special "
            "State, regain Divine Ki Points equal to 1/2 of your Surgency.\n"
            "(4)-[Triggered, 1/Encounter]: If you trigger the 6th effect of "
            "Divine Candidate, gain a stack of Divine Battle Born.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Beautiful Pink Flame",
      description: "You have forsaken mortal power to fully embrace your "
          "divine nature.\n"
          "(1)-[Permanent]: Super Saiyan Rosé loses the Power High Aspect.\n"
          "(2)-[Passive]: Double the reduction to Ki Point Cost from the 3rd "
          "effect of Divine Training.\n"
          "(3)-[Permanent, Passive]: Upon gaining this Mastery Trait, select a "
          "God Maneuver. Gain access to that while in the Super Saiyan Rosé "
          "Transformation.",
    ),
  ),

  // ================================== Appointed God line (Shinjin; Suppressed
  // Divinity Null Stage + Divinity Unleashed Stage 1).
  // ========================================= Appointed God: Suppressed Divinity (0) ===
  TransformationDef(
    name: "Suppressed Divinity",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Shinjin",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 14,
    prerequisiteText: "Appointed God line, Null Stage.",
    transformationLine: "Appointed God",
    stage: 0,
    aspects: ["Enhanced Save (Cognitive)", "God Ki", "Natural (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Divine Role",
        description: "Granted dominion over an aspect of reality, you now stand "
            "tall as a true deity in your own right.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Suppressed "
            "Divinity, select 2 God Maneuvers. You have access to those God "
            "Maneuvers while in any Transformation of the Appointed God "
            "Transformation Line.\n"
            "(2)-[Passive]: You gain access to the Injury Transfer and "
            "Space-Time Connection Unique Abilities (both Magical, 10(T); see "
            "the site).\n"
            "(3)-[Passive]: Increase the Combat Rolls of all Allies within a "
            "Large Sphere AoE (centered on you) by 1(T).\n"
            "(4)-[Triggered]: If you use Combat Recovery, all Allies within a "
            "Large Sphere AoE (centered on you) regain Ki Points equal to 1/2 "
            "of your Surgency.",
      ),
    ],
  ),

  // ========================================= Appointed God: Divinity Unleashed (1) ===
  TransformationDef(
    name: "Divinity Unleashed",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Shinjin",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    transformationLine: "Appointed God",
    stage: 1,
    aspects: [
      "Enhanced Save (All)",
      "God Ki",
      "Battle Uniform",
      "Difficult (LV1)",
    ],
    battleUniform: BattleUniformDef(
      category: ApparelCategory.combatClothing,
      craftsmanshipGrade: 5,
      qualityNames: ['Combat Ready', 'Divine Apparel'],
    ),
    amb: _legendary4Amb,
    traits: [
      TransformationTrait(
        name: "Cosmic Flow",
        description: "Your godly energy allows you to overwhelm lesser foes "
            "and prove your divine superiority.\n"
            "(1)-[Passive]: Attacking Maneuvers that target Allies within a "
            "Huge Sphere AoE (centered on you) trigger your Exploit "
            "Maneuver.\n"
            "(2)-[Passive]: Increase the AoE for the 3rd effect of Divine Role "
            "by 1 Magnitude.\n"
            "(3)-[Passive]: If you would use Divine Ki Points to pay the Ki "
            "Point Cost of an Attacking Maneuver, reduce the Ki Point Cost by "
            "2(T).\n"
            "(4)-[Passive]: If you would use Divine Ki Points for a Ki Wager, "
            "increase the Wound Roll of that Attacking Maneuver by 1/2 of the "
            "amount of Divine Ki Points spent on the Ki Wager.\n"
            "(5)-[Triggered]: If you use Combat Recovery, regain Divine Ki "
            "Points equal to 1/2 of your Surgency.\n"
            "(6)-[Triggered, 1/Encounter]: If you use Combat Recovery while "
            "below the Injured Health Threshold, double the amount of Life and "
            "Ki Points you regain, and double the Divine Ki Points regained "
            "from the 5th effect of Cosmic Flow for this use.",
      ),
      TransformationTrait(
        name: "Ascended Divine Magic",
        description: "Your holy magic grows in strength, empowered by divine "
            "energy.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to Divinity "
            "Unleashed, select a Domain Trait. You have access to that Domain "
            "Trait while in Divinity Unleashed.\n"
            "(2)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select a Size Category (Small, Medium or Large). "
            "You become that Size Category while in this Transformation.\n"
            "(3)-[Passive]: Increase your Might and Saving Throws by 1(T) for "
            "the duration of any Clash initiated by an Opponent.\n"
            "(4)-[Passive]: Increase the Skill Bonus of your Knowledge, "
            "Creature Handling, Clairvoyance, Perception, Use Magic, and "
            "Investigation Skills by 2.\n"
            "Select your Domain Trait below (matching your Divine Magic God "
            "domain).",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Domain Trait',
            options: [
              TraitOption(
                name: 'True God of Peace',
                description: '(2)-[Permanent]: Divinity Unleashed gains the '
                    'Innate State (Mindful) and Mindful Aspects. (3)-[Ruling]: '
                    "'L' equals your current level of the Mindful State. "
                    '(4)-[Passive]: Ignore the 2nd effect of the Mindful '
                    'State. (5)-[Passive]: Increase your Strike and Dodge '
                    'Rolls by L(T). (6)-[Passive]: Reduce the Divine Ki Point '
                    'Cost of the Divine Peace God Maneuver by L(T). '
                    '(7)-[Automatic]: If you fail a Steadfast Check, or the '
                    'Combat Round ends without using Combat Recovery, set your '
                    'Mindful level to Calm. (8)-[Triggered, 1/Round]: If you '
                    'use Combat Recovery, enter the next level of the Mindful '
                    'State.',
              ),
              TraitOption(
                name: 'True God of Judgement',
                description: '(2)-[Passive]: Increase the AMB (FO/MA) of '
                    'Divinity Unleashed by 1(T). (3)-[Passive]: Increase the '
                    'Dice Category of your Energy Charges by 1. (4)-[Passive]: '
                    'Increase your Combat Rolls by 1(T) for each Health '
                    'Threshold you are below. (5)-[Passive]: While below the '
                    'Injured Health Threshold, double the Energy Charges '
                    'gained from God of Judgement. (6)-[Triggered, '
                    '1/Encounter]: If you use the Divine Judgement Maneuver '
                    'while Injured, do not pay its Divine Ki Point Cost and '
                    'apply an Energy Charge to the Attacking Maneuver made '
                    'through it.',
                ambPerTierBonus: {DbuAttribute.force: 1, DbuAttribute.magic: 1},
              ),
              TraitOption(
                name: 'True God of Power',
                description: '(2)-[Permanent]: Divinity Unleashed gains the '
                    'Bulky and Armored Aspects. (3)-[Passive]: Reduce your '
                    'Muscle Penalty by 1(bT). (4)-[Passive]: Increase the AMB '
                    '(FO/TE) of Divinity Unleashed by 1(T) for each stack of '
                    'Super Stack you possess. (5)-[Triggered, 1/Encounter]: If '
                    'you use the Divine Muscle God Maneuver in response to an '
                    'Attacking Maneuver, set that Maneuver\'s Damage Category '
                    'to Standard for your Damage calculation (if already '
                    'Standard, double your Soak Value for its duration).',
              ),
              TraitOption(
                name: 'True God of Survival',
                description: '(2)-[Passive]: Increase the AMB (IN) of Divinity '
                    'Unleashed by 1(T). (3)-[Passive]: Increase your Surgency '
                    'by 2(T). (4)-[Passive]: Increase your Combat Rolls and '
                    'Soak Value by 2(T) while above the Injured Health '
                    'Threshold. (5)-[Triggered, 1/Round]: If you get hit by an '
                    'Attacking Maneuver and receive Damage, regain Life Points '
                    'equal to your Insight Modifier. (6)-[Triggered, '
                    '1/Encounter]: If you use the Divine Healing God Maneuver '
                    'while below the Injured Health Threshold, do not pay its '
                    'Divine Ki Point Cost and double the Life Points '
                    'regained.',
                ambPerTierBonus: {DbuAttribute.insight: 1},
              ),
              TraitOption(
                name: 'True God of Wisdom',
                description: '(2)-[Passive]: Set the AMB (SC/PE) of Divinity '
                    "Unleashed to match the Transformation's AMB (MA). "
                    '(3)-[Passive]: Double the bonus from the effect of God of '
                    'Wisdom. (4)-[Triggered, 1/Round]: If you use the Divine '
                    'Wisdom God Maneuver, regain Life Points equal to 1/2 of '
                    'your Personality or Scholarship Modifier (whichever is '
                    'higher). (5)-[Triggered, 1/Round]: If you use the Hype '
                    'and/or Analysis Maneuver, remove a Combat Condition '
                    '(except Suffocating or Pinned) from yourself or an '
                    'adjacent Ally. (6)-[Triggered/Transform, 1/Encounter]: '
                    'Use the Divine Wisdom God Maneuver Out-of-Sequence (no '
                    'Divine Ki Point Cost, does not count towards its 1/Round '
                    'limit).',
              ),
              TraitOption(
                name: 'True God of War',
                description: '(2)-[Passive]: Increase your Combat Rolls by '
                    '2(T) while wielding a Weapon. (3)-[Passive]: While '
                    'wielding a Weapon, it gains the Divine Armament Quality '
                    'free (Weapon Type: All; if an Attacking Maneuver with '
                    'this Weapon has its Ki Point Cost paid with Divine Ki '
                    'Points, apply your Greater Dice to its Strike and Wound '
                    'Rolls). (4)-[Passive]: Ignore the Ki Point Cost for '
                    'Magical Materialization if you create a Weapon through '
                    'it. (5)-[Triggered, 1/Round]: If you use the Divine '
                    'Weapon God Maneuver, apply your Damage Attribute an '
                    'additional time.',
              ),
              TraitOption(
                name: 'True God of Magic',
                description: '(2)-[Passive]: Increase the AMB (IN/MA) of '
                    'Divinity Unleashed by 1(T). (3)-[Passive]: Increase your '
                    'Combat Rolls by 2(T). (4)-[Passive]: Reduce the Divine Ki '
                    'Point Cost of Divine Spell by 1(bT). (5)-[Passive]: '
                    'During a Combat Round in which you used a Magical Unique '
                    'Ability, your Magic Attacks have their Wound Rolls '
                    'increased by 1/4 (rounded up) of your Magic Modifier. '
                    '(6)-[Triggered/Transform]: Upon entering Divinity '
                    'Unleashed, select a Magical Unique Ability you meet the '
                    'Prerequisites for; gain access to it until you leave.',
                ambPerTierBonus: {DbuAttribute.insight: 1, DbuAttribute.magic: 1},
              ),
              TraitOption(
                name: 'True God of Many',
                description: '(2)-[Passive]: Increase the Combat Rolls and '
                    'Soak Value of your Minions by 1(T). (3)-[Passive]: Your '
                    'Minions gain double the bonus from the 3rd effect of '
                    'Divine Role. (4)-[Passive]: While in the Spectator State, '
                    'increase your Soak Value and Damage Reduction by 2(T). '
                    '(5)-[Passive]: Your Minions may spend your Counter '
                    'Actions as if they were their own. (6)-[Triggered, '
                    '1/Encounter]: If you use the Divine Summoning God '
                    'Maneuver, any Minions moved by it may use the Power Up '
                    'Maneuver Out-of-Sequence (before any Exploit Maneuvers).',
              ),
              TraitOption(
                name: 'True God of Time',
                description: '(2)-[Permanent]: If you do not have access to '
                    'the Time Power Enhancement, gain access to it. '
                    '(3)-[Permanent]: Divinity Unleashed gains the Linked '
                    '(Time Power) Aspect. (4)-[Passive]: Reduce the Stress '
                    'Test Requirement of Time Power by 4. (5)-[Passive]: '
                    'Increase your Combat Rolls during a Frozen Turn by 1(T). '
                    '(6)-[Passive]: A Character may use the Signature Technique '
                    'Maneuver instead of the Basic Attack Maneuver through '
                    'your use of the Freeze Attack God Maneuver. '
                    '(7)-[Triggered, 1/Encounter]: If you target an Ally with '
                    'the Freeze Attack God Maneuver, apply your Damage '
                    'Attribute to any Attacking Maneuver they make through '
                    'it.',
              ),
              TraitOption(
                name: 'True God of an Element',
                description: '(2)-[Passive]: Increase the AMB (FO/MA) of '
                    'Divinity Unleashed by 1(T). (3)-[Passive]: Double the '
                    'bonus to your Strike and Wound Rolls from Favored '
                    'Element. (4)-[Passive]: Reduce the Divine Ki Point Cost '
                    'of Divine Element by 2(bT). (5)-[Triggered, 1/Round]: If '
                    'you spend Divine Ki Points to pay the Ki Point Cost of an '
                    'Attacking Maneuver with a Profile of your Favored '
                    'Element, apply an Energy Charge. (6)-[Permanent, Option]: '
                    'Choose God of the Elements [Passive]: select up to 3 '
                    "Profiles with 'Elemental' in their name as your Favored "
                    'Elements; or God of Focus [Passive, Ruling]: select a '
                    "Favored Element as your 'Divine Focus' (its Attacking "
                    'Maneuvers may target an additional Character if no AoE, '
                    'or +1 AoE Magnitude if they have one).',
                ambPerTierBonus: {DbuAttribute.force: 1, DbuAttribute.magic: 1},
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "God of a Domain (Legendary Trait)",
        description: "You rise to godly power, giving you control over some "
            "aspect of reality, a divine Domain.\n"
            "(1)-[Ruling]: Your choice for the 3rd effect of Divine Magic is "
            "known as your 'Domain'.\n"
            "(2)-[Passive]: Increase your maximum number of Divine Ki Points "
            "by 1/2.\n"
            "(3)-[Passive, Ruling]: Gain access to a Domain Maneuver whose "
            "bracketed Domain matches yours. All Domain Maneuvers are God "
            "Maneuvers (all [1/Round]):\n"
            "Divine Peace (God of Peace) — Counter; 2 Counter Actions; DKP "
            "Cost: Varies. Effect: If in the Mindful State, use in response to "
            "being targeted by an Attacking Maneuver (not an Ultimate "
            "Signature); spend Divine Ki Points equal to that Maneuver's "
            "combined Ki Point Cost and Ki Wager to cancel it (no Actions/Ki "
            "regained). Each Energy Charge on it treats its Ki Point Cost as "
            "2(T) higher (using the attacker's ToP).\n"
            "Divine Judgement (God of Judgement) — Out-of-Sequence; DKP Cost: "
            "5(T). Effect: If hit by an Attacking Maneuver and you take "
            "Damage, use the Basic Attack Maneuver Out-of-Sequence targeting "
            "that Character; increase its Wound Roll by 1/2 of the Damage you "
            "received (cannot exceed your Damage Attribute).\n"
            "Divine Muscle (God of Power) — Counter; 1 Counter Action; DKP "
            "Cost: 2(bT). Effect: If hit by an Attacking Maneuver, use this to "
            "increase your Soak Value by 1(T) for each Super Stack (before "
            "calculations); treated as the Direct Hit option of the Defend "
            "Maneuver.\n"
            "Divine Healing (God of Survival) — Counter; 2 Counter Actions; "
            "DKP Cost: 2(bT). Effect: If hit and you take Damage, regain "
            "2d10(bT) Life Points, increasing the Dice Score by your Surgency "
            "(counts as Combat Recovery for your effects).\n"
            "Divine Wisdom (God of Wisdom) — Instant; DKP Cost: 2(bT). "
            "Effect: Use a Special Maneuver that is a Standard Maneuver with "
            "an Action Cost of 1 Action as an Out-of-Sequence Maneuver.\n"
            "Divine Weapon (God of War) — Instant; DKP Cost: 2(bT). Effect: "
            "Use the Basic Attack Maneuver Out-of-Sequence (must be an Armed "
            "Attack).\n"
            "Divine Spell (God of Magic) — Instant; DKP Cost: 2(bT). Effect: "
            "Use a Unique Ability that is a Standard Maneuver with an Action "
            "Cost of 1 Action as an Out-of-Sequence Maneuver.\n"
            "Divine Summoning (God of Many) — Instant; DKP Cost: 2(bT) per "
            "Minion targeted. Effect: Target any number of your Minions; place "
            "them on unoccupied Square(s). If this places a Minion adjacent to "
            "an Opponent, it triggers that Minion's Exploit Maneuver (only one "
            "Minion may Exploit through this).\n"
            "Freeze Attack (God of Time) — Instant; DKP Cost: 5(bT). Effect: "
            "Target yourself or an Ally; that Character begins a Frozen Turn "
            "with 1 Action (instead of the 2 from Time Freeze), spent on the "
            "Basic Attack Maneuver.\n"
            "Divine Element (God of an Element) — Instant; DKP Cost: 2(bT). "
            "Effect: Use the Basic Attack Maneuver Out-of-Sequence (must use "
            "your Favored Element as a Profile).\n"
            "Battle Uniform — Combat Clothing, Craftsmanship Grade 5. Combat "
            "Ready: Increase your Strike and Dodge Rolls by 1/2 (rounded up) "
            "of your Apparel Bonus. Divine Apparel: Increase your Apparel "
            "Bonus by 1(bT). Enchanted: Increase your Soak Value by the "
            "Apparel Bonus. Rejuvenating Light: If you use a Surge Maneuver, "
            "regain 3(bT) Divine Ki Points.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Divine Entity",
        description: "You have gained full control over your godly might, "
            "allowing you to reach an even greater height.\n"
            "(1)-[Permanent]: Divinity Unleashed gains M levels of the Scaling "
            "Aspect.\n"
            "(2)-[Passive]: The 4th effect of Cosmic Flow uses your entire "
            "Surgency, instead of 1/2.\n"
            "(3)-[Triggered]: If you spend a Counter Action(s), regain 1(bT) "
            "Divine Ki Points for each Counter Action spent.",
      ),
      TransformationTrait(
        name: "True Divinity",
        description: "Your divine might surpasses even the greatest of godly "
            "beings and transcends all known limits of power.\n"
            "(1)-[Permanent]: Divinity Unleashed gains the Perfect Ki Control "
            "Aspect.\n"
            "(2)-[Passive]: You may spend your Counter Actions as if they were "
            "Actions for Combat Recovery.\n"
            "(3)-[Triggered, 1/Encounter]: If you spend 3 Counter Actions in a "
            "Combat Round, upon spending that final Counter Action, regain "
            "Divine Ki Points equal to your Surgency.",
      ),
    ],
  ),

  // ==================================== GENERIC EVOLVED STAGES — apply onto any
  // qualifying Original Form (Racial Requirement inherited, so "Any" here); the
  // listed AMB/Aspects ADD to the Original's and the Stress Test is an addition.
  // ================================================================ Barrier Form ===
  TransformationDef(
    name: "Barrier Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Access to the Barrier Unique "
        "Ability. Tier of Power Requirement: Same as Original Form. Stress "
        "Test Requirement: +2.",
    aspects: ["Draining (LV2)", "Peaked"],
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Protection from Harm",
        description: "Y\n"
            "(1)-[Acclimated]: If the Original Form is Mastered, reduce the "
            "level of Barrier Form's Draining Aspect by 1. If the Original "
            "Form is Fully Mastered, reduce the level of Barrier Form's "
            "Draining Aspect by 2 instead.\n"
            "(2)-[Passive]: Increase your Damage Reduction by 1(T)\n"
            "(3)-[Passive]: Reduce the Ki Point Cost of the Barrier Unique "
            "Ability by 2(T).\n"
            "(4)-[Triggered, 1/Round]: If you make a Clash that is initiated "
            "by another Character and uses either your Cognitive or Corporeal "
            "Save, you may spend 5(bT) Ki Points to automatically win that "
            "Clash.\n"
            "(5)-[1/Encounter]: You may use the Barrier Unique Ability "
            "without paying its Action Cost.",
        automation: [
          // (2) +1(T) Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
  ),

  // ============================================================ Berserk Controlled ===
  TransformationDef(
    name: "Berserk Controlled",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    prerequisiteText: "Evolved Stage: Generic. Saiyan Race, have previously "
        "entered the Berserk State. Tier of Power Requirement: Equal to "
        "Original Form. Stress Test Requirement: +4.",
    aspects: [
      "Enhanced Save (Cognitive)",
      "Innate State (Berserk)",
      "Peaked",
      "Exhausting",
      "Straining",
      "Draining (LV1)",
      "Fading (LV1)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "True Nature of the Saiyans",
        description: "Your innate lust for battle runs rampant, though it no "
            "longer overwhelms your conscious mind.\n"
            "(1)-[Acclimated]: If the Original Form is Fully Mastered, "
            "Berserk Controlled loses the Exhausting, Straining, Draining, "
            "and Fading Aspects.\n"
            "(2)-[Constant]: If you are in the Berserk State and not in this "
            "Transformation, you may use the Transformation Maneuver as an "
            "Instant Maneuver to attempt and enter Berserk Controlled.\n"
            "(3)-[Passive]: You cannot gain the Compelled Combat Condition "
            "and, upon entering this Transformation, you immediately stop "
            "suffering from the Compelled Combat Condition if you were in it "
            "previously.\n"
            "(4)-[Passive]: Ignore the 1st and 3rd effects of the Berserk "
            "State.\n"
            "(5)-[Passive]: The 2nd effect of the Berserk State increases "
            "the relevant Combat Rolls instead of reducing them.\n"
            "(6)-[Triggered/Transform, 1/Encounter]: For the Combat Roll "
            "with the lowest number of Battle Born stacks applied to it, set "
            "its number of Battle Born stacks to 2. This effect cannot "
            "reduce the number of Battle Born stacks applied to a Combat "
            "Roll.",
      ),
    ],
  ),

  // ============================================================= Empowered Form ===
  TransformationDef(
    name: "Empowered Form",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Original Form is a fully "
        "Mastered Alternate Form (not Restrained Form or its variants) with no "
        "effects that make it Legendary. Stress Test Requirement: +13.",
    aspects: ["Enhanced Save (All)", "Peaked", "Pinnacle (LV1)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 3, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Cha-La Head Cha-La",
        description: "You bring the full force of your Transformation to bear, "
            "unleashing the latent power of that Transformation that few ever "
            "reach.\n"
            "(1)-[Passive]: If the Original Form possesses the Scaling Aspect, "
            "reduce the Stress Test Requirement of this Transformation by 4 "
            "and the Attribute Modifier Bonuses (AG/FO/TE/MA) of this "
            "Transformation by 2(T), but Empowered Form gains 2 levels of the "
            "Scaling Aspect.\n"
            "(2)-[Passive]: If the Original Form of this Transformation has an "
            "Attribute Modifier Bonus to any Attribute that is not already "
            "increased by Empowered, increase Empowered Form's Attribute "
            "Modifier Bonus for that Attribute by 1(T) (this increase is "
            "modified by Empowered Form's Scaling Aspect, if it possesses "
            "it).\n"
            "(3)-[Triggered/Transform]: If you were in the Original Form for "
            "this Transformation before entering it, increase your Combat "
            "Rolls and Soak Value by 1(T) until you leave this "
            "Transformation.\n"
            "(4)-[Permanent, Option]: Upon gaining access to this "
            "Transformation, select and gain access to one of the following "
            "effects while you're in this Transformation (this applies "
            "regardless of the Original Form):",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Empowered Option',
            options: [
              TraitOption(
                name: 'We Gotta Power!',
                description: '[Passive]: While you possess 2+ stacks of Power, '
                    'increase your Combat Rolls and Soak Value by 1(T).',
              ),
              TraitOption(
                name: 'Mystical Adventure',
                description: "[Passive]: Empowered Form gains the Perfect Ki "
                    "Control Aspect and its Attribute Modifier Bonus (IN) is "
                    "increased by 1(T).",
                ambPerTierBonus: {DbuAttribute.insight: 1},
              ),
              TraitOption(
                name: 'Limit Break x Survivor',
                description: '[Passive]: Empowered Form gains the Armored '
                    'Aspect and its Attribute Modifier Bonus (TE) is increased '
                    'by 1(T).',
                ambPerTierBonus: {DbuAttribute.tenacity: 1},
              ),
              TraitOption(
                name: 'Super Survivor',
                description: '[Passive]: Empowered Form gains the High Speed '
                    'Aspect and its Attribute Modifier Bonus (AG) is increased '
                    'by 1(T).',
                ambPerTierBonus: {DbuAttribute.agility: 1},
              ),
              TraitOption(
                name: 'Dan Dan Kokoro',
                description: '[Passive]: Empowered Form has its Attribute '
                    'Modifier Bonuses (FO/MA) increased by 1(T) and you '
                    'increase the Dice Category of your Energy Charges by 1 '
                    'Category.',
                ambPerTierBonus: {DbuAttribute.force: 1, DbuAttribute.magic: 1},
              ),
              TraitOption(
                name: 'Dragon Soul',
                description: '[Permanent, Passive]: Upon gaining this effect, '
                    'select Raging or Mindful; Empowered Form gains the Aspect '
                    'of the same name and the Innate State Aspect for that '
                    'State.',
              ),
              TraitOption(
                name: 'Fight It Out!!',
                description: '[Passive]: Empowered Form gains the Bulky Aspect '
                    'and you reduce your Muscle Penalty by 1(bT).',
              ),
            ],
          ),
        ],
      ),
      TransformationTrait(
        name: "Rock the Dragon (Legendary Trait)",
        description: "You've mastered the art of drawing out greater power "
            "from your Transformations.\n"
            "(1)-[Passive]: Increase the amount of Life and Ki Points you "
            "regain from Legend Realized by 1d6(bT).\n"
            "(2)-[1/Encounter]: While in a Form that is an Original Form for "
            "Empowered Form, you may use the Transformation Maneuver as an "
            "Instant Maneuver. If you use this effect, you must attempt to "
            "enter Empowered Form (with your current Form as the Original "
            "Form).\n"
            "(3)-[Triggered, 1/Encounter]: Upon entering an Alternate Form or "
            "Empowered Form through the Transformation Maneuver, you may gain 1 "
            "Action.",
      ),
    ],
  ),

  // ================================================================== Full Power ===
  TransformationDef(
    name: "Full Power",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Original Form is Mastered. Tier "
        "of Power Requirement: +1 higher than Original Form. Stress Test "
        "Requirement: +2.",
    aspects: ["Pinnacle (LV2)", "Draining (LV1)", "Peaked"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Power to the Limit",
        description: "You push your Form's power to its limit.\n"
            "(1)-[Passive]: Increase your maximum number of Power Stacks by "
            "1.\n"
            "(2)-[Triggered/Transform]: Use the Power Up Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: If you hit an Opponent with an "
            "Attacking Maneuver that has a Ki Wager equal to or exceeding 1/4 "
            "of your Max Capacity, apply an Energy Charge to that Attacking "
            "Maneuver.",
      ),
    ],
  ),

  // ============================================================== Power Stressed ===
  TransformationDef(
    name: "Power Stressed",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Tier of Power Requirement: Same "
        "as Original Form. Stress Test Requirement: Same as Original Form.",
    aspects: [
      "Pinnacle (LV2)",
      "Bulky",
      "Draining (LV2)",
      "Exhausting",
      "Peaked",
      "Weakening",
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Stressed by Power",
        description: "Your body is overwhelmed and distorted by the power "
            "you've flooded into it.\n"
            "(1)-[Passive]: If your Original Form is Mastered, reduce the "
            "Muscle Penalty by 1(bT).\n"
            "(2)-[Passive]: Increase the Ki Point Cost of all your Attacking "
            "Maneuvers by 2(T).",
      ),
    ],
  ),

  // =============================================================== Muscular Form ===
  TransformationDef(
    name: "Muscular Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Muscular Warrior Talent. Tier "
        "of Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+3.",
    aspects: ["Bulky", "Peaked"],
    amb: {
      DbuAttribute.agility:
          TransformationAmb(coefficient: -1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Bulging Strength",
        description: "Your muscular bulk grants you greater resilience and "
            "output, but at the cost of speed.\n"
            "(1)-[Passive]: While you only possess 1 Super Stack, increase the "
            "Attribute Modifier Bonus (AG) of this Transformation by 1(T).\n"
            "(2)-[Passive]: For every Super Stack you possess after the first, "
            "increase your Soak Value and Wound Rolls by 1(T).\n"
            "(3)-[Triggered, 1/Round]: If you use a Signature Technique, apply "
            "your Damage Attribute to that Attacking Maneuver an additional "
            "time.",
      ),
    ],
  ),

  // ================================================================ Furious Form ===
  TransformationDef(
    name: "Furious Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Angry Warrior Talent. Tier of "
        "Power Requirement: Equal to Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Innate State (Raging)", "Raging", "Peaked"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Fury Infusement",
        description: "B\n"
            "(1)-[Passive]: Increase L by 1 for the effects of your Raging "
            "Talents.\n"
            "(2)-[Passive]: Ignore Reduced Momentum.\n"
            "(3)-[Passive]: While in the 2nd or higher level of the Raging "
            "State, this Transformation gains the Armored Aspect.\n"
            "(4)-[Triggered]: If you reduce your Life Points through the "
            "effects of a Raging Talent, regain an equal amount of Ki "
            "Points.\n"
            "(5)-[Triggered, 1/Round]: If you score a Botch Result on a Combat "
            "Roll, you may use the Basic Attack Maneuver as an Out-of-Sequence "
            "Maneuver.\n"
            "(6)-[Triggered, 1/Encounter]: After rolling your Strike Roll for "
            "an Attacking Maneuver, you may make that Combat Roll a Botch "
            "Result regardless of Natural Result. If you do, and still manage "
            "to hit that Opponent, apply an Energy Charge to that Attacking "
            "Maneuver.",
      ),
    ],
  ),

  // =============================================== Path of Might (Chosen by Power) ===
  TransformationDef(
    name: "Path of Might",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Force or Magic Score of 10+. "
        "Tier of Power Requirement: Same as Original Form. Stress Test "
        "Requirement: +4.",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by Power",
        description: "Might makes right, and you possess all the might. None "
            "can stand against you.\n"
            "(1)-[Triggered/Power, Resource]: Gain 1 stack of Super Power "
            "(max. 3).\n"
            "(2)-[Passive]: While you possess a stack of Super Power, increase "
            "your Wound Rolls and your Might by 1(T).\n"
            "(3)-[Passive]: Double the bonus from the 2nd effect of Chosen by "
            "Power if you possess 3 stacks of Super Power.\n"
            "(4)-[1/Round]: As an Instant Maneuver during your turn or an "
            "Ally's turn, you may spend a stack of Super Power to target an "
            "Opponent and make a Might Clash against them. If you win, they "
            "gain the Guard Down and Broken Combat Conditions until the end of "
            "the current turn.\n"
            "(5)-[Triggered, 1/Round]: When making an Attacking Maneuver, you "
            "may spend a stack of Super Power to increase the Wound Roll by "
            "your Might. You do not lose that stack until after concluding "
            "that Attacking Maneuver.\n"
            "(6)-[Triggered, 1/Round]: If an Opponent targets you with an "
            "Attacking Maneuver, you may spend a stack of Super Power to use "
            "the Power Flare option of the Defend Maneuver without spending a "
            "Counter Action; if you do, increase your Dice Score for that "
            "Power Flare by your Might.\n"
            "(7)-[Triggered/Power, 1/Encounter]: Spend 2 stacks of Super Power "
            "to remove all Combat Conditions you are suffering from (except "
            "Pinned or Suffocating).\n"
            "(8)-[Triggered, 1/Encounter]: If you lose a Might Clash initiated "
            "by an Opponent, you may spend a stack of Super Power to win that "
            "Might Clash instead.",
      ),
    ],
  ),

  // ======================================= Path of Resilience (Chosen by Durability) ===
  TransformationDef(
    name: "Path of Resilience",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Tenacity Score of 10+. Tier of "
        "Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Armored", "Enhanced Save (Corporeal)", "Peaked"],
    amb: {
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by Durability",
        description: "Others may be an unstoppable force, but you have become "
            "an immovable object. None can overcome your defenses.\n"
            "(1)-[Triggered, Resource]: If you receive Damage from an "
            "Opponent's Attacking Maneuver, gain a stack of Steel (max. 3).\n"
            "(2)-[Passive]: Increase your Speeds by 1/4 (rounded up) of your "
            "Tenacity Modifier.\n"
            "(3)-[Passive]: Increase your Soak Value and Damage Reduction by "
            "1(T).\n"
            "(4)-[Triggered, 1/Round]: If you are targeted by an Attacking "
            "Maneuver, you may spend a stack of Steel to use the Direct Hit or "
            "Guard option of the Defend Maneuver without spending a Counter "
            "Action.\n"
            "(5)-[Triggered, 1/Round]: If an adjacent Ally is targeted by an "
            "Attacking Maneuver that does not possess an AoE, you may become "
            "the target of that Attacking Maneuver instead of your Ally.\n"
            "(6)-[Triggered/Start of Combat Round]: Target an Opponent. Make a "
            "Clash (Corporeal) against that Opponent. If you win, they gain "
            "the Compelled Combat Condition until the end of the Combat Round "
            "with you as the target.",
      ),
    ],
  ),

  // ============================================= Path of Speed (Chosen by the Speed) ===
  TransformationDef(
    name: "Path of Speed",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Agility Score of 10+. Tier of "
        "Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Enhanced Save (Impulsive)", "High Speed", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by the Speed",
        description: "By focusing on your swift agility, you can move faster "
            "and faster, surpassing even the swiftest of warriors.\n"
            "(1)-[Triggered, Resource]: If you use the Movement Maneuver, gain "
            "1 stack of Speed Blitz (max. 2).\n"
            "(2)-[1/Round]: You may spend a stack of Speed Blitz to use the "
            "Basic Attack Maneuver or Signature Technique Maneuver as an "
            "Instant Maneuver. If you do, Agility is your Damage Attribute for "
            "that Attacking Maneuver.\n"
            "(3)-[Triggered]: If you are targeted by an Attacking Maneuver, "
            "you may spend a stack of Speed Blitz to increase your Dodge Roll "
            "against that Attacking Maneuver by 2(T).\n"
            "(4)-[1/Encounter]: As an Instant Maneuver, you may spend 2 stacks "
            "of Speed Blitz to remove the Staggered, Blinded, Impediment, and "
            "Guard Down Combat Conditions.\n"
            "(5)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you "
            "can spend a stack of Speed Blitz to apply the Charging Assault "
            "Advantage to that Attacking Maneuver. If you do, Agility is your "
            "Damage Attribute for that Attacking Maneuver.\n"
            "(6)-[Triggered, 1/Encounter]: If you use an Attacking Maneuver "
            "that possesses the Charging Assault Advantage, you may increase "
            "the Wound Roll of that Attacking Maneuver by 1/2 (rounded up) of "
            "your Boosted Speed.",
      ),
    ],
  ),

  // ========================================== Path of Control (Chosen by Consistency) ===
  TransformationDef(
    name: "Path of Control",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Insight Score of 10+. Tier of "
        "Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Enhanced Save (Cognitive)", "Perfect Ki Control", "Peaked"],
    amb: {
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by Consistency",
        description: "You have mastered the art of controlling your aura, "
            "ensuring that you spend less energy to achieve the same results, "
            "making you even more efficient in battle.\n"
            "(1)-[Passive]: Increase your Surgency by 2(T).\n"
            "(2)-[Triggered/Start of Turn]: Regain 3(bT) Life and Ki Points.\n"
            "(3)-[1/Encounter]: Use a Healing Surge as an Instant Maneuver.\n"
            "(4)-[1/Encounter]: Use a Ki Surge as an Instant Maneuver.",
      ),
    ],
  ),

  // ============================================== Path of the Heart (Chosen by Heart) ===
  TransformationDef(
    name: "Path of the Heart",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Personality Score of 10+. Tier "
        "of Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Enhanced Save (Morale)", "Peaked"],
    amb: {
      DbuAttribute.personality:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by the Heart",
        description: "You are a lively, charismatic sort who embraces all "
            "kinds of means to survive a combat encounter, and none can match "
            "your pep and social acuity.\n"
            "(1)-[Passive]: While you are Hyped, increase your Combat Rolls by "
            "1/4 (rounded up) of your Personality.\n"
            "(2)-[1/Round]: You may use the Hype Maneuver as an Instant "
            "Maneuver.\n"
            "(3)-[Triggered, 1/Encounter]: If you use the Hype Maneuver, you "
            "may increase your Personality Modifier by 2(T) until the end of "
            "your next turn.",
      ),
    ],
  ),

  // =========================================== Path of the Scholar (Chosen by Mind) ===
  TransformationDef(
    name: "Path of the Scholar",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Scholarship Score of 10+. Tier "
        "of Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.scholarship:
          TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Chosen by the Mind",
        description: "Knowledge is power, and you know this all too well. Your "
            "knowledge surpasses that of all others, allowing you to reign "
            "supreme.\n"
            "(1)-[Passive]: If there is an Analyzed Opponent, increase your "
            "Combat Rolls by 1/4 (rounded up) of your Scholarship.\n"
            "(2)-[Passive]: You may target an additional Opponent for the "
            "effects of the Analysis Maneuver.\n"
            "(3)-[1/Round]: You may use the Analysis Maneuver as an Instant "
            "Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you use your Might or a Saving Throw "
            "for a Clash initiated by an Opponent, you may use your "
            "Scholarship Modifier instead of your Might, or your Scholarship "
            "Score instead of the Attribute Score used by that Saving Throw, "
            "respectively.\n"
            "(5)-[Triggered, 1/Encounter]: If you use the Analysis Maneuver, "
            "you may increase your Scholarship Modifier by 2(T) until the end "
            "of your next turn.",
      ),
    ],
  ),

  // =========================================================== Awakened Potential ===
  TransformationDef(
    name: "Awakened Potential",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. 2 stacks of Unlocked Potential; "
        "Original Form is not Potential Unleashed. Tier of Power Requirement: "
        "Equal to Original Form or 4+ (whichever is higher). Stress Test "
        "Requirement: +5.",
    aspects: ["Perfect Ki Control", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Potential of the Form",
        description: "You awaken the full sleeping potential within you "
            "alongside your existing Transformation.\n"
            "(1)-[Passive]: Increase Z by 1 for the effects of Unlocked "
            "Potential.\n"
            "(2)-[Passive]: Ignore the 2nd effect of the Surging State.\n"
            "(3)-[Triggered]: If you apply the 5th effect of Potential to a "
            "Combat Roll, increase that Combat Roll by 1(T).\n"
            "(4)-[Triggered, 1/Encounter]: If you use a Signature Technique "
            "while in the Surging State, apply 2 Energy Charges to that "
            "Attacking Maneuver.",
      ),
    ],
  ),

  // ============================================================ Dark Ki: Unleashed ===
  TransformationDef(
    name: "Dark Ki: Unleashed",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Fully Mastered Dark Ki. Tier of "
        "Power Requirement: Equal to Original Form or 4+ (whichever is "
        "higher). Stress Test Requirement: +5.",
    aspects: ["Linked (Dark Ki)", "Limited (LV4)", "Exhausting", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Controlled Dark Ki",
        description: "B\n"
            "(1)-[Acclimated]: While the Original Form is Fully Mastered, "
            "ignore the effects of the Limited Aspect and the 4th effect of "
            "Controlled Dark Ki.\n"
            "(2)-[Passive]: Ignore the effects of the Rampaging Aspect.\n"
            "(3)-[Passive]: Increase your maximum number of Evil Points by "
            "3(bT).\n"
            "(4)-[Passive]: The 5th effect of Disorientating Darkness loses "
            "the [Triggered] Keyword and gains the [Automatic] Keyword.\n"
            "(5)-[Triggered, 1/Round]: If you spend 5(bT) Evil Points on the "
            "2nd effect of Power of Evil, you may increase the Damage Category "
            "of that Attacking Maneuver by 1 Category.\n"
            "(6)-[Triggered, 1/Round]: If you spend 5(bT) Evil Points on the "
            "3rd effect of Power of Evil, you may reduce the Damage Category "
            "of that Attacking Maneuver by 1 Category for the sake of your "
            "Damage Calculation.\n"
            "(7)-[Triggered, 1/Encounter]: If you use a Healing Surge to "
            "increase your Life Points above a Health Threshold, you may "
            "maximize your Evil Points.",
      ),
    ],
  ),

  // ========================================================= Principles of Kaioken ===
  TransformationDef(
    name: "Principles of Kaioken",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Access to Kaioken. Tier of "
        "Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Glowing", "Light Dependent", "Straining", "Peaked"],
    amb: {},
    traits: [
      TransformationTrait(
        name: "Sparks of Red",
        description: "By converting life into power, you emulate the effects "
            "of Kaioken's crimson flames.\n"
            "(1)-[Permanent]: You cannot enter this Evolved Stage if you are "
            "in a different Transformation with 'Kaioken' in the name.\n"
            "(2)-[Passive]: You cannot enter a different Transformation with "
            "'Kaioken' in the name.\n"
            "(3)-[Passive]: For each stack of Power you possess, increase the "
            "Attribute Modifier Bonus (AG/FO/MA) of this Evolved Stage by 1(T) "
            "(max. 3(T)).\n"
            "(4)-[1/Round]: Spend 4(bT) Life Points to use the Power Up "
            "Maneuver as an Instant Maneuver.\n"
            "(5)-[Automatic]: When making an Attacking Maneuver, reduce your "
            "Life Points by 2(bT) for each stack of Power you possess (max. "
            "6(bT)).",
      ),
    ],
  ),

  // ================================================================ Rampage Form ===
  TransformationDef(
    name: "Rampage Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Tier of Power Requirement: Same "
        "as Original Form. Stress Test Requirement: +5.",
    aspects: [
      "Rampaging (LV2)",
      "Innate State (Surging)",
      "Peaked",
      "Exhausting",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Rampant Beast",
        description: "The tension inside you releases, driving you into a "
            "furious frenzy of combat.\n"
            "(1)-[Acclimated]: If the Original Form is fully Mastered, ignore "
            "the effects of the Rampaging Aspect.\n"
            "(2)-[Passive]: If you have the Compelled Combat Condition, your "
            "Focus is whatever Character you are targeting through the "
            "Compelled Combat Condition's effects.\n"
            "(3)-[Passive]: Ignore the 4th effect of the Surging State.\n"
            "(4)-[Passive]: Increase your Strike Rolls by 1(T) against your "
            "Focus.\n"
            "(5)-[Passive]: For each Health Threshold you are below, increase "
            "your Soak Value and Wound Rolls by 1(T).",
      ),
    ],
  ),

  // ================================================================= Serene Form ===
  TransformationDef(
    name: "Serene Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Calm Mind Talent. Tier of Power "
        "Requirement: Equal to Original Form. Stress Test Requirement: +4.",
    aspects: ["Innate State (Mindful)", "Mindful", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Focused State of Mind",
        description: "B\n"
            "(1)-[Passive]: Increase L by 1 for the effects of your Mindful "
            "Talents.\n"
            "(2)-[Passive]: Ignore the effects of the Impaired Combat "
            "Condition.\n"
            "(3)-[Passive]: While in the 2nd or higher level of the Mindful "
            "State, this Transformation gains the Perfect Ki Control Aspect.\n"
            "(4)-[Triggered, 2/Round]: If you use the Defend Maneuver, you may "
            "regain 3(bT) Life Points.\n"
            "(5)-[Triggered, 1/Round]: If you score a Critical Result on a "
            "Combat Roll, you may gain 1 Counter Action.\n"
            "(6)-[Triggered, 1/Encounter]: After rolling your Wound Roll for "
            "an Attacking Maneuver, you may make that Combat Roll a Critical "
            "Result regardless of the Natural Result. If you do, ignore the "
            "2nd effect of the Calm level of the Mindful State for the "
            "duration of that Attacking Maneuver.",
      ),
    ],
  ),

  // ================================================================ Power of a God ===
  TransformationDef(
    name: "Power of a God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Original Form does not possess "
        "the God Ki Aspect. Tier of Power Requirement: Equal to Original Form "
        "or 4+ (whichever is higher). Stress Test Requirement: +5.",
    aspects: ["God Ki", "Draining (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Form of Divine Power",
        description: "The power of a god flows through you, granting you "
            "unrivaled strength befitting a nascent deity.\n"
            "(1)-[Acclimated]: If the Original Form is fully Mastered: remove "
            "the Draining Aspect; upon first entering with a fully Mastered "
            "Original Form, select a God Maneuver to gain access to with that "
            "Original Form; and when you spend Divine Ki Points on an Attacking "
            "Maneuver's Ki Point Cost, reduce that cost by 2(T).\n"
            "(2)-[Passive]: Increase your Combat Rolls by 1(T) while you are in "
            "the Healthy Health Threshold.\n"
            "(3)-[1/Round]: You may use the Basic Attack Maneuver as an Instant "
            "Maneuver, but that Attacking Maneuver must have a Ki Point Cost of "
            "at least 4(T). If you do, you must spend Divine Ki Points to pay "
            "its Ki Point Cost.\n"
            "(4)-[Triggered, 1/Round]: If you spend Divine Ki Points to pay the "
            "Ki Point Cost of an Attacking Maneuver, increase its Damage "
            "Category by 1 Category.\n"
            "(5)-[Triggered/Transform, 1/Encounter]: Regain Life Points equal "
            "to your Surgency.",
      ),
      TransformationTrait(
        name: "Consistent Divine Power (Legendary Trait)",
        description: "Thanks to your newfound divinity, you have tapped into "
            "the full power of a god, able to wield that power on a whim.\n"
            "(1)-[Triggered/Power]: While in the Original Form for the Power "
            "of a God Evolved Stage, you may enter the God Ki Special State "
            "until the end of your turn.\n"
            "(2)-[Triggered]: If you are hit by an Attacking Maneuver while in "
            "the Original Form for this Evolved Stage, but before you "
            "calculate Damage, you may use the Transformation Maneuver as an "
            "Out-of-Sequence Maneuver to attempt to enter this Evolved Stage "
            "for that Transformation.\n"
            "(3)-[Passive]: While in the Healthy Health Threshold, increase "
            "your Damage Reduction by 1(T).",
      ),
    ],
  ),

  // ========================================================= Power of a Demon God ===
  TransformationDef(
    name: "Power of a Demon God",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Any",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Original Form does not possess "
        "the God Ki Aspect; Demon Clansman. Tier of Power Requirement: Equal "
        "to Original Form or 4+ (whichever is higher). Stress Test "
        "Requirement: +5.",
    aspects: ["God Ki", "Draining (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Form of Demonic Power",
        description: "Your thirst for violence is unquenchable, and your "
            "attacks reflect that brutal nature.\n"
            "(1)-[Acclimated]: If the Original Form is fully Mastered: remove "
            "the Draining Aspect; upon first entering with a fully Mastered "
            "Original Form, select a God Maneuver to gain with that Original "
            "Form; and when you spend Divine Ki Points on an Attacking "
            "Maneuver's Ki Point Cost, apply an Energy Charge to it.\n"
            "(2)-[Passive]: Increase your Combat Rolls against Opponents "
            "suffering from the Branded Combat Condition by 1(T).\n"
            "(3)-[Passive]: Increase the Damage Category of your Signature "
            "Techniques whose only target(s) are Branded Opponents by 1 "
            "Category.\n"
            "(4)-[1/Round]: You may use the Basic Attack Maneuver as an Instant "
            "Maneuver, but it must have a Ki Point Cost of at least 4(T) paid "
            "with Divine Ki Points.\n"
            "(5)-[Triggered/Power]: Target an Opponent who is not at Long Range "
            "and make a Clash (Cognitive) against them. If you win, they gain "
            "the Branded Combat Condition until the start of your next turn.\n"
            "(6)-[Triggered, 1/Encounter]: If you trigger the 5th effect of "
            "Form of Demonic Power, you may target all Opponents.",
      ),
      TransformationTrait(
        name: "Consistent Demonic Power (Legendary Trait)",
        description: "Due to your unholy divinity, you have awakened the "
            "brutal might of a demon god, able to unleash that strength "
            "at-will.\n"
            "(1)-[Triggered/Power]: While in the Original Form for the Power "
            "of a Demon God Evolved Stage, you may enter the God Ki Special "
            "State until the end of your turn.\n"
            "(2)-[Triggered]: If you are hit by an Attacking Maneuver while in "
            "the Original Form for this Evolved Stage, but before you "
            "calculate Damage, you may use the Transformation Maneuver as an "
            "Out-of-Sequence Maneuver to attempt to enter this Evolved Stage "
            "for that Transformation.\n"
            "(3)-[Passive]: Increase your Damage Reduction by 1(T) against "
            "Attacking Maneuvers made by Characters suffering from a Combat "
            "Condition.",
      ),
    ],
  ),

  // =============================================================== Power-Stressed ===
  TransformationDef(
    name: "Power-Stressed",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Tier of Power / Stress Test "
        "Requirement: Same as Original Form.",
    aspects: [
      "Bulky",
      "Draining (LV2)",
      "Exhausting",
      "Peaked",
      "Weakening",
    ],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Stressed by Power",
        description: "Your body is overwhelmed and distorted by the power "
            "you've flooded into it.\n"
            "(1)-[Passive]: If your Original Form is Mastered, reduce the "
            "Muscle Penalty by 1(bT).\n"
            "(2)-[Passive]: Increase the Ki Point Cost of all your Attacking "
            "Maneuvers by 2(T).",
      ),
    ],
  ),

  // =========================================================== Style of Formation ===
  TransformationDef(
    name: "Style of Formation",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Access to the Hype Maneuver; "
        "the Original Form does not have a Battle Uniform. Tier of Power "
        "Requirement: Equal to Original Form. Stress Test Requirement: +5.",
    aspects: ["Battle Uniform"],
    // (3) "The Battle Uniform of this Transformation is the same as that of
    // Formation." — Standard Clothing, Craftsmanship Grade 4.
    battleUniform: BattleUniformDef(
      category: ApparelCategory.standardClothing,
      craftsmanshipGrade: 4,
      qualityNames: ['Durable'],
    ),
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Inherited Love",
        description: "You have been entrusted with the mighty power that is "
            "love itself.\n"
            "(1)-[Permanent, Passive]: Upon gaining access to this "
            "Transformation, select and gain access to a Form of Love (see - "
            "Formation).\n"
            "(2)-[Passive]: Increase the Attribute Modifier Bonus (PE) of this "
            "Transformation to match the total Attribute Modifier Bonus (FO or "
            "MA - whichever is higher) of this Transformation (including both "
            "the Original Form's AMB and that of this Evolved Stage).\n"
            "(3)-[Passive]: The Battle Uniform of this Transformation is the "
            "same as that of Formation.\n"
            "(4)-[Triggered/Transform, Resource]: Gain a stack of Love.\n"
            "(5)-[Triggered/Power, 1/Round]: Gain a stack of Love.\n"
            "(6)-[1/Round]: If you would spend a Counter Action for any "
            "reason, you may spend a stack of Love instead.\n"
            "(7)-[Triggered/Power, 1/Encounter]: Increase your Personality "
            "Modifier by 1(T) for each stack of Love you possess until the "
            "start of your next turn.",
      ),
    ],
  ),

  // ======================================================== Transforming Class Up ===
  TransformationDef(
    name: "Transforming Class Up",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Class Up Awakening. Tier of "
        "Power Requirement: Same as Original Form. Stress Test Requirement: "
        "+4.",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Power to the Limit",
        description: "Y\n"
            "(1)-[Acclimated]: If the Original Form is Fully Mastered, "
            "Transforming Class Up gains the Perfect Ki Control Aspect.\n"
            "(2)-[Choice]: Depending on your choice for the Option effect of "
            "Class Selection: Hero — AMB (AG/TE) +1(T); Elite — AMB (IN) "
            "+1(T); Berserker — AMB (FO/TE/MA) +1(T).\n"
            "(2)-[Choice]: Hero — +1 Dice Category to Tier of Power Extra Dice "
            "on Dodge Rolls; Elite — on Strike Rolls; Berserker — on Wound "
            "Rolls.\n"
            "(3)-[Choice]: Hero [Triggered/Power, 1/Round, 3/Encounter]: if "
            "below Injured, Healing Surge as a 1-Action Standard; Elite "
            "[1/Round, 3/Encounter]: if Ki below 1/4 max, Ki Surge as a "
            "1-Action Standard; Berserker [Triggered, 1/Round, 3/Encounter]: "
            "if below Injured and you deal Damage, use the Basic Attack "
            "Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // ========================================================== Splendid Evolution ===
  TransformationDef(
    name: "Splendid Evolution",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Arcosian",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Arcosian Race; Original Form "
        "cannot be Brilliant Evolution or any Stages of Metamorphosis. Tier "
        "of Power Requirement: Equal to Original Form or 4+ (whichever is "
        "higher). Stress Test Requirement: +5.",
    aspects: ["Armored", "Draining (LV2)", "Glowing", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Splendid Form",
        description: "The shining carapace you have wrapped yourself in gleams "
            "with your radiant superiority.\n"
            "(1)-[Permanent]: The Legendary Trait for this Evolved Stage is "
            "Maximum the Overwhelm (see — Brilliant Evolution).\n"
            "(2)-[Acclimated]: If the Original Form is mastered, this "
            "Transformation loses the Draining Aspect.\n"
            "(3)-[Passive]: Gain access to a Brilliant Evolution Trait (see — "
            "Brilliant Evolution). The Trait you gain must have the name of "
            "the Evolution Trait you selected for the 3rd effect of "
            "Overwhelming Fighter in brackets after the name.\n"
            "(4)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(5)-[Passive]: Increase the Apparel Bonus of your Plating by "
            "1(T).\n"
            "(6)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
            "Technique, you may spend 2 stacks of Overwhelm to apply an Energy "
            "Charge for each Health Threshold you are below to that Attacking "
            "Maneuver.",
      ),
      TransformationTrait(
        name: "Maximum the Overwhelm (Legendary Trait)",
        description: "Inherited from Brilliant Evolution (this Evolved Stage's "
            "Legendary Trait per its 1st effect). Your overwhelming power "
            "permeates the battlefield, and you become truly unstoppable — see "
            "Brilliant Evolution.",
      ),
    ],
  ),

  // ============================================================== Namekian Glare ===
  TransformationDef(
    name: "Namekian Glare",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Namekian",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Generic. Namekian Race. Tier of Power "
        "Requirement: Equal to Original Form or 4+ (whichever is higher). "
        "Stress Test Requirement: +5(G).",
    aspects: ["Graded", "Peaked"],
    // AMB (AG/FO/TE/MA) is +G(T) — Namekian Glare has 2 Grades.
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [1, 2]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2]),
      DbuAttribute.tenacity: TransformationAmb(graded: true, gradePerTier: [1, 2]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2]),
    },
    traits: [
      TransformationTrait(
        name: "Glowing Gaze",
        description: "The radiant ruby or shining sapphire glow of your eyes "
            "ensure that you miss no details, and that no enemy can stand "
            "before you without fear. (AMB AG/FO/TE/MA is +G(T), set by "
            "Grade.)\n"
            "(1)-[Permanent]: This Transformation cannot be used in "
            "conjunction with the Red-Eyed Namekian Transformation.\n"
            "(2)-[Permanent]: You cannot enter the 2nd Grade of Namekian Glare "
            "unless your base Tier of Power is 5+.\n"
            "-[Ruling]: If you had selected an Opponent to become Studied "
            "through the 2nd effect of Intelligent Fighter at the end of the "
            "last Combat Round, you have a 'Warrior's Gaze' this Combat Round. "
            "If an Ally, you have a 'Draconic Gaze'.\n"
            "(3)-[Passive]: Increase your Surgency by 1/2 of G(T).\n"
            "(4)-[Passive]: While you have a Warrior's Gaze, increase your "
            "Wound Rolls by G(T).\n"
            "(5)-[Passive]: While you have a Draconic Gaze, increase the Wound "
            "Rolls of your Studied Allies by G(T).\n"
            "(6)-[Triggered/Power, 1/Round]: If you have a Warrior's Gaze, "
            "enter the Surging State until the end of your turn. If you have a "
            "Draconic Gaze, a willing Studied Ally enters the Surging State "
            "until the end of their turn (ignoring the Surging State's 2nd "
            "effect when exiting).\n"
            "(7)-[Graded]: Namekian Glare has 2 Grades, each increasing your "
            "Tier of Power Extra Dice by 1 Dice Category and setting the "
            "Stress Test Requirement and AMB.",
        automation: [
          // (3) +1/2 of G(T) Surgency (G = the card's Grade stepper).
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
            perTransformationGrade: true,
            fractionDenominator: 2,
            roundUp: true,
          ),
        ],
      ),
    ],
  ),

  // ================================================================ Super Tuffle ===
  TransformationDef(
    name: "Super Tuffle",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Neo-Tuffle",
    prerequisiteText: "Evolved Stage: Generic. Neo-Tuffle Race. Tier of Power "
        "Requirement: +1 higher than Original Form. Stress Test Requirement: "
        "+5.",
    aspects: ["Draining (LV1)", "Power High (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Tuffle Supremacy",
        description: "Your sense of pride and superiority grants you great "
            "strength with which to avenge your forebears.\n"
            "(1)-[Acclimated]: If the Original Form is Mastered: Super Tuffle "
            "loses the Draining and Power High Aspects; ignore the 2nd effect "
            "of the Surging and Superior States; and when you use the 5th "
            "effect of Tuffle Supremacy, you may enter the Surging State "
            "instead of the Superior State (your Focus must be your "
            "Inferior).\n"
            "(2)-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "(3)-[1/Round]: Spend 2 Revenge Points to use the Movement "
            "Maneuver, Power Up Maneuver, or Energy Charge Maneuver as an "
            "Instant Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you use the Energy Charge Maneuver, "
            "you may spend 2 Revenge Points to gain an additional Energy "
            "Charge from that use.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Enter the Superior State "
            "until the start of your next turn.",
      ),
    ],
  ),

  // ============================================================= Tuffleized Form ===
  TransformationDef(
    name: "Tuffleized Form",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Any",
    prerequisiteText: "Evolved Stage: Generic. Overtaken and Tuffleization "
        "Awakenings. Tier of Power Requirement: Equal to Original Form. Stress "
        "Test Requirement: +4.",
    aspects: ["Pinnacle (LV2)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Parasitic Transformation",
        description: "B\n"
            "(1)-[Acclimated]: If the Original Form is Fully Mastered, this "
            "Transformation gains the Natural (LV1) Aspect.\n"
            "(2)-[Passive]: Increase your Tier of Power Extra Dice by 1 "
            "Category.\n"
            "(3)-[Passive]: Increase the Wound Rolls of your Attacking "
            "Maneuvers that target your Inferior by 1(T).\n"
            "(4)-[Passive]: Increase your Damage Reduction by 1(T) for the "
            "duration of Attacking Maneuvers made by your Inferior.\n"
            "(5)-[Triggered, 1/Round]: If you are dealt Damage by an Attacking "
            "Maneuver made by your Inferior, and that Damage did not Defeat "
            "you or knock you through a Health Threshold, you may use a Basic "
            "Attack Maneuver as an Out-of-Sequence Maneuver targeting your "
            "Inferior.\n"
            "(6)-[Triggered/Surging, 1/Round]: You may use the Energy Charge "
            "Maneuver as an Out-of-Sequence Maneuver.",
      ),
    ],
  ),

  // =================================================================== Legendary ===
  // (The "Legendary Super Saiyan Evolved Stage" granted by the Legendary
  // Saiyan Factor Trait; transcribed live 20 Jul 2026 — was previously only
  // referenced by other effects, never catalogued.)
  TransformationDef(
    name: "Legendary",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    prerequisiteText: "Evolved Stage: Generic. Original Form (or an Evolved "
        "Stage applied to it) has Super Saiyan Form Aspect, Legendary Saiyan "
        "Factor Trait. Tier of Power Requirement: Same as Original Form. "
        "Stress Test Requirement: +5.",
    aspects: [
      "Armored",
      "Bulky",
      "Pinnacle (LV1)",
      "Growth (LV1)",
      "Peaked",
      "Rampaging (LV2)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Unlimited Power",
        description: "Your power grows stronger and stronger, the longer you "
            "fight for.\n"
            "(1)-[Acclimated]: If the Original Form is Mastered:\n"
            "Remove the Rampaging Aspect from this Evolved Stage.\n"
            "Reduce your Muscle Penalty by 1(bT).\n"
            "Ignore the 5th effect of Unlimited Power.\n"
            "The 6th effect of Unlimited Power becomes [Triggered] instead of "
            "[Automatic].\n"
            "(2)-[Passive]: While you possess 4+ stacks of Battle Born "
            "applied to your Wound Rolls, increase the Attribute Modifier "
            "Bonus (FO/TE/MA) of this Transformation by 1(T).\n"
            "(3)-[Passive]: While you possess 6+ stacks of Battle Born, "
            "ignore all Health Threshold Penalties.\n"
            "(4)-[Passive]: Your Ki Points may exceed your Maximum Ki "
            "Points.\n"
            "(5)-[Automatic]: At the end of your turn, reduce your Life "
            "Points by 1/10th (rounded up) of your Ki Points.\n"
            "(6)-[Automatic/Start of Turn]: Reduce your Life Points by "
            "1/10th of your Maximum Life Points to use a Ki Surge as an "
            "Out-of-Sequence Maneuver.",
      ),
      TransformationTrait(
        name: "Unstoppable Legend (Legendary Trait)",
        description: "You are nearly impossible to kill, and even harder to "
            "hold at bay.\n"
            "(1)-[Passive]: While in a Transformation with the Super Saiyan "
            "Form Aspect, increase your Wound Rolls and Soak Value by 1(T).\n"
            "(2)-[Triggered]: Upon making a Stress Test to enter or remain in "
            "a Transformation with the Super Saiyan Form Aspect, you may "
            "(after seeing the result) reduce your Life Points by 1/10th of "
            "your Maximum Life Points to increase the Dice Score of that "
            "Stress Test by 2.\n"
            "(3)-[Triggered, 1/Encounter]: Upon entering a Transformation "
            "with the Super Saiyan Form Aspect, gain a stack of Battle Born. "
            "You must apply this stack of Battle Born to your Wound Rolls.",
        automation: [
          // (1) +1(T) Wound Rolls and Soak while in a Super-Saiyan-Form-
          // Aspect Transformation (always-on Legendary Trait).
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

  // ============================================================ Legendary Oozaru ===
  // (Standalone Legendary Form; transcribed live 20 Jul 2026 — missing from
  // the catalogue until now.)
  TransformationDef(
    name: "Legendary Oozaru",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    stressTestRequirement: 25,
    prerequisiteText: "Legendary Mutant Trait, access to Oozaru, and access "
        "to Super Saiyan 1",
    aspects: [
      "Enhanced Save (Corporeal)",
      "Armored",
      "Bulky",
      "Strainless",
      "Raging (LV2)",
      "Growth (LV3)",
      "Rampaging (LV2)",
      "Dedicated",
      "Difficult (LV1)",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 2, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 4, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 3, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 2, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Hulking Power",
        description: "The rampaging fury of your full power emerges in your "
            "Great Ape form.\n"
            "-[Permanent]: If you fail the Stress Test for this "
            "Transformation, enter the Oozaru Transformation (you still "
            "suffer Stress Exhaustion).\n"
            "-[Permanent]: This Transformation is considered a part of the "
            "Great Ape Transformation Line for all effects.\n"
            "-[Passive]: Treat all characters as if they were 1 Size Category "
            "smaller for the sake of your effects and the Punching Down rules "
            "when you are targeted by one of their Attacking Maneuvers, or "
            "when you target them with one of your Attacking Maneuvers.\n"
            "-[Passive]: This Transformation gains access to the Rampaging "
            "Assault Trait.\n"
            "-[Passive]: Ignore the Strike Penalty from your Super Stacks.",
      ),
      TransformationTrait(
        name: "Super Saiyan Heritage",
        description: "Despite the nature of this Transformation, you are "
            "still infused with the awesome power of the Super Saiyan.\n"
            "-[Permanent]: This Transformation is considered a part of the "
            "Super Saiyan Transformation Line for all effects.\n"
            "-[Passive]: Apply your Tier of Power Extra Dice an additional "
            "time.\n"
            "-[Passive]: Increase your Maximum Ki Points and Max Capacity by "
            "1/4.\n"
            "-[Triggered/Transform]: Regain Ki Points equal to 1/4 of your "
            "Max Capacity.",
        automation: [
          // +1/4 Maximum Ki Points and Max Capacity while active.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.maxKiQuarter,
              AffectedStat.maxCapacityQuarter,
            ],
            coefficient: 1,
          ),
        ],
      ),
      TransformationTrait(
        name: "Legendary Rampage",
        description: "Pure power flows through you, driving you to "
            "absolutely destroy your enemies.\n"
            "-[Triggered/Transform]: Maximize your Battle Born stacks applied "
            "to your Wound Roll.\n"
            "-[Passive]: Reduce the Dice Score of your roll against the "
            "Rampaging Aspect by 2.\n"
            "-[Passive]: While in the Raging State or while suffering from "
            "the Compelled Combat Condition, gain the following effects:\n"
            "[Passive]: Double the bonus to your Wound Roll from your stacks "
            "of Battle Born.\n"
            "[Passive]: Double the bonus to your Soak Value from your Size "
            "Category.\n"
            "[Triggered/Start of Turn]: Before you roll for the Rampaging "
            "Aspect, lose Life Points equal to your Power Level and regain Ki "
            "Points equal to twice the amount of Life Points lost.\n"
            "[Triggered, 2/Round]: If an Opponent is hit by any of your "
            "Attacking Maneuvers, they gain the Broken Combat Condition until "
            "the start of your next turn.",
      ),
      TransformationTrait(
        name: "Legend (Legendary Trait)",
        description: "No other Great Ape can compare to the awe-inspiring "
            "might of your legendary power.\n"
            "-[Passive]: Increase the Attribute Modifier Bonus (FO/TE) of "
            "every Transformation in the Great Ape Transformation Line by "
            "1(T).\n"
            "-[Passive]: You cannot enter the Golden Oozaru Transformation.\n"
            "-[Passive]: While you are in the Raging State, increase your "
            "Strike Rolls by 1(T).",
        automation: [
          // (3rd bullet) +1(T) Strike Rolls while in the Raging State.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.strike],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedStateActive,
            conditionStateName: 'Raging',
          ),
        ],
      ),
      TransformationTrait(
        name: "Arguably the Real Legendary Super Saiyan (Exceed Trait)",
        description: "Unleashing the full might of the Legendary Super "
            "Saiyan in the bestial form of the Great Ape, you tower over "
            "even the greatest warriors of all time.\n"
            "-[Passive]: This Transformation gains the Scaling (LV2) "
            "Aspect.\n"
            "-[Passive]: Increase the Wound Roll of any Attacking Maneuver "
            "you make with a Ki Wager by 1/2 of the amount of Ki Points "
            "spent on the Ki Wager.\n"
            "-[Triggered]: If you hit an Opponent with an Attacking Maneuver "
            "that possesses a Ki Wager of 10(bT) or more, increase the "
            "Damage Category of that Attacking Maneuver by 1 Category.",
        // (2nd bullet) Wound Roll +1/2 of the Ki wagered.
        wagerWoundEffect: WagerWoundEffect(fractionOfWagerDen: 2),
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Superior Specimen",
      description: "The pinnacle of power emerges in your Great Ape form, "
          "proving your Great Ape to be the strongest out there.\n"
          "-[Permanent]: Legendary Oozaru loses the Rampaging Aspect and "
          "increases the Attribute Modifier Bonus (AG) by +2(T).\n"
          "-[Permanent]: Remove the first effect of Rampaging Assault while "
          "in this Transformation.\n"
          "-[Passive]: Halve the penalties to your Defense Value from your "
          "Size Category and halve the penalties to your Dodge Rolls from "
          "your stacks of Super Stack.\n"
          "-[Passive]: You do not lose Life Points through the effects "
          "gained through the third effect of Legendary Rampage.\n"
          "-[Automatic/Transform]: Enter the Raging State until you leave "
          "this Transformation.",
    ),
  ),

  // ============================================================= Condensed Legend ===
  TransformationDef(
    name: "Condensed Legend",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    prerequisiteText: "Evolved Stage: Generic. Original Form (or an Evolved "
        "Stage applied to it) has the Super Saiyan Form Aspect and is "
        "Mastered; Legendary Saiyan Factor Trait. Tier of Power Requirement: "
        "Same as Original Form. Stress Test Requirement: +5.",
    aspects: ["Armored", "Bulky", "Pinnacle (LV1)", "Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Power Redefined",
        description: "You redistribute your intense power, bringing it to heel "
            "under your control.\n"
            "(1)-[Permanent]: Condensed Legend is considered to be the "
            "Legendary Evolved Stage for all of your effects, except the 1st "
            "effect of Legendary Saiyan.\n"
            "(2)-[Passive]: Reduce your Muscle Penalty by 1(bT).\n"
            "(3)-[Passive]: Increase the maximum number of Battle Born stacks "
            "for your Strike and Dodge Rolls by 1.\n"
            "(4)-[Passive]: While you possess 4+ stacks of Battle Born, "
            "increase your Combat Rolls and Might by 1(T).\n"
            "(5)-[Passive]: Your Ki Points may exceed your Maximum Ki Points.\n"
            "(6)-[Triggered/Transform]: This Transformation gains the Growth "
            "(LV1) Aspect until you leave this Transformation.\n"
            "(7)-[Triggered/Power]: Regain Ki Points equal to your Might.",
      ),
      TransformationTrait(
        name: "Sparks of Super Saiyan (Legendary Trait)",
        description: "The Super Saiyan power flowing through you helps you "
            "keep your momentum in a fight.\n"
            "(1)-[Passive]: While you are in a Transformation with the Super "
            "Saiyan Form Aspect and have 8+ stacks of Battle Born, increase "
            "your Combat Rolls by 1(T).\n"
            "(2)-[Triggered, 1/Round]: If you gain a stack of Battle Born, "
            "regain Life Points equal to your Might.",
      ),
    ],
  ),

  // ======================================================= Super Saiyan Resurgence ===
  TransformationDef(
    name: "Super Saiyan Resurgence",
    type: TransformationType.form,
    formType: FormType.alternate,
    racialRequirement: "Saiyan",
    prerequisiteText: "Evolved Stage: Generic. Super Saiyan 1; Original Form "
        "does not have the Super Saiyan Form Aspect. Tier of Power "
        "Requirement: +1 higher than Original Form. Stress Test Requirement: "
        "+5.",
    aspects: [
      "Super Saiyan Form",
      "Raging",
      "Draining (LV1)",
      "Power High (LV1)",
      "Peaked",
    ],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Golden Resurgence",
        description: "A golden blaze of power erupts around you, further "
            "strengthening the powers you wield now.\n"
            "(1)-[Acclimated]: If the Original Form is Mastered: Super Saiyan "
            "Resurgence loses the Draining and Power High Aspects; treat the "
            "Superior State as the Raging State for the Raging Aspect; and when "
            "you use the 3rd effect of Golden Resurgence, you may enter the "
            "Superior State instead of the Raging State (lasting until the "
            "start of your next turn).\n"
            "(2)-[Passive]: Increase the Dice Score for your Duel Clashes by "
            "1(T).\n"
            "(3)-[Triggered/Transform]: Enter the Raging State until the end "
            "of your turn.\n"
            "(4)-[Permanent, Option]: Select one (based on a Transformation "
            "you have access to) below.",
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Golden Style Trait',
            options: [
              TraitOption(
                name: 'Golden Warrior (Super Saiyan 1)',
                description: '[Passive]: You gain access to the Option effect '
                    'you chose for the 3rd effect of S-Cells.',
              ),
              TraitOption(
                name: 'Golden Defender (Future Super Saiyan)',
                description: '[Passive]: You gain access to the 3rd effect of '
                    'Stand Against Evil.',
              ),
              TraitOption(
                name: 'Golden Superiority (Superior Super Saiyan)',
                description: '[Passive]: You gain access to the 4th effect of '
                    'Crazed Battle Lust.',
              ),
              TraitOption(
                name: 'Golden Class (Xeno Super Saiyan)',
                description: '[Passive]: You gain access to the 4th effect of '
                    'Super Saiyan Class.',
              ),
              TraitOption(
                name: 'Golden Resilience (Ancestral Super Saiyan)',
                description: '[Passive]: You gain access to the 2nd and 4th '
                    'effects of Origin of the Warrior Race.',
              ),
              TraitOption(
                name: 'Golden Blood (Descended Super Saiyan)',
                description: '[Passive]: You gain access to the 5th effect of '
                    'Awoken Saiya Power.',
              ),
              TraitOption(
                name: 'Golden Cells (Bio Super Saiyan)',
                description: '[Passive]: You gain access to the 4th effect of '
                    'Mixed S-Cells.',
              ),
              TraitOption(
                name: 'Golden Whiskers (Super Neko Majin)',
                description: "[Passive]: You gain access to the 1st and 4th "
                    "effects of I'm Shining!!",
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ============================================ Beyond Divine Saiyan (Evolved SS Blue) ===
  TransformationDef(
    name: "Beyond Divine Saiyan",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan Blue). Stress Test "
        "Requirement: Varies (by Grade).",
    aspects: ["Graded", "Difficult (LV1)"],
    // AMB (AG/FO/TE/MA) is +G(T) — Beyond Divine Saiyan has 3 Grades.
    amb: {
      DbuAttribute.agility: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.force: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.tenacity: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
      DbuAttribute.magic: TransformationAmb(graded: true, gradePerTier: [1, 2, 3]),
    },
    traits: [
      TransformationTrait(
        name: "Divine Super Saiyan 2",
        description: "Your divine power fills every nook and cranny of your "
            "being, elevating you to a state even beyond godhood. (AMB "
            "AG/FO/TE/MA is +G(T), set by Grade.)\n"
            "(1)-[Graded]: Beyond Divine Saiyan has 3 Grades (Divine Super "
            "Saiyan 2 / 3 / Full Power Divine Super Saiyan), each with its own "
            "Stress Test Requirement, a required number of Masteries, and a "
            "Godly Super Saiyan Trait (per Grade):\n"
            "Divine Sparks — (1)-[Passive]: If you possess 3+ stacks of Divine "
            "Battle Born, increase your Tier of Power Extra Dice by G Dice "
            "Categories. (2)-[Passive]: While in the Radiant God State, "
            "increase your Strike and Dodge Rolls by 1(T). (3)-[Passive]: Your "
            "Attacking Maneuvers with a Ki Wager equal to or exceeding 1/4 of "
            "your Max Capacity have their Damage Category increased by 1.\n"
            "Beyond Divine Limits — (1)-[Passive]: While in the Radiant God "
            "State, increase your Wound Rolls and Soak Value by 1(T). "
            "(2)-[Passive]: Increase the Wound Roll of any Attacking Maneuver "
            "you make with a Ki Wager by 1/2 of the amount of Ki Points or "
            "Divine Ki Points wagered.\n"
            "Utmost Divinity — (1)-[Passive]: Increase your maximum number of "
            "Divine Battle Born stacks by 1. (2)-[Passive]: Beyond Divine "
            "Saiyan gains the Innate State (Radiant God) Aspect. "
            "(3)-[Triggered/Start of Turn]: Regain x(bT) Life Points, where x "
            "equals your current number of Divine Battle Born stacks.",
      ),
    ],
    masteryTraits: [
      TransformationTrait(
        name: "Divine Super Saiyan 3",
        description: "In all the worlds, power like yours has never been "
            "witnessed before.\n"
            "(1)-[Triggered/Start of Turn]: Regain M(bT) Divine Ki Points.\n"
            "(2)-[Passive]: You gain access to the 2nd Grade of Beyond Divine "
            "Saiyan.",
      ),
      TransformationTrait(
        name: "Full Power Divine Super Saiyan",
        description: "True divine power flows through you, making you more "
            "than a match for any impostor to godhood.\n"
            "(1)-[Triggered/Start of Turn]: Use the Power Up Maneuver or "
            "Energy Charge Maneuver as an Out-of-Sequence Maneuver.\n"
            "(2)-[Passive]: You gain access to the 3rd Grade of Beyond Divine "
            "Saiyan.",
      ),
    ],
  ),

  // ========================================== Super Saiyan Blue Evolved (Evolved) ===
  TransformationDef(
    name: "Super Saiyan Blue Evolved",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan Blue). Fully "
        "Mastered Super Saiyan Blue. Stress Test Requirement: +4.",
    aspects: ["Draining (LV2)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Evolved Blue Saiyan",
        description: "Your sapphire aura turns to cobalt as your power "
            "skyrockets to display your divine superiority.\n"
            "(1)-[Passive]: Increase your Tier of Power Extra Dice by 2 Dice "
            "Categories.\n"
            "(2)-[Passive]: For every stack of Divine Battle Born you possess, "
            "increase your Wound Rolls and Soak Value by 1(T).\n"
            "(3)-[Passive]: You gain access to the Concentrated Blue God "
            "Maneuver — Concentrated Blue [1/Encounter]; Maneuver Type: "
            "Standard; Action Cost: 1 Action; DKP Cost: 6(T). Effect: Use the "
            "Energy Charge Maneuver as an Out-of-Sequence Maneuver without "
            "spending its Ki Point Cost; the declared Attacking Maneuver "
            "becomes 'Infused with Blue'. Your Opponent cannot use any "
            "Triggered effects in response to being targeted with or hit by "
            "this Attacking Maneuver. If an 'Infused with Blue' Attacking "
            "Maneuver is used in a Duel (regardless of who initiated it), "
            "increase your Dice Score for the Duel Clashes of that Duel "
            "Maneuver by 2(T).\n"
            "(4)-[Permanent, Option]: Select one: Promised Power [Passive]: "
            "gains the Bulky Aspect and reduce Muscle Penalty by 1(bT); Royal "
            "Blue [Passive]: +1 max Power stacks and double Divine Ki regained "
            "through the Divine Flame God Maneuver.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Deeper Blue",
      description: "Mastering the haze of azure power surrounding you has "
          "granted you access to the true depths of divine power.\n"
          "(1)-[Permanent]: Super Saiyan Blue Evolved loses the Draining "
          "Aspect.\n"
          "(2)-[Permanent]: Super Saiyan Blue Evolved gains the Innate State "
          "(Radiant God) Aspect.\n"
          "(3)-[Passive]: The Concentrated Blue God Maneuver loses the "
          "[1/Encounter] Keyword and gains the [1/Round] Keyword.\n"
          "(4)-[Passive]: While you have 3+ stacks of Divine Battle Born, gain "
          "an additional Energy Charge through the Energy Charge Maneuver used "
          "through the effects of Concentrated Blue.",
    ),
  ),

  // ======================================= Super Full Power Saiyan 4 (Evolved SS4) ===
  TransformationDef(
    name: "Super Full Power Saiyan 4",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 4,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 4). Enter only via "
        "the 8th effect of Primal Resilience. Stress Test Requirement: Same as "
        "Original Form.",
    aspects: ["Peaked"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Hope-Filled Warrior",
        description: "Carrying the hopes and dreams of your comrades, you "
            "awaken an even greater power.\n"
            "(1)-[Permanent]: You can only enter this Evolved Stage through "
            "the 8th effect of Primal Resilience.\n"
            "(2)-[Automatic]: Upon entering this Transformation, leave the "
            "Entrusted State.\n"
            "(3)-[Automatic]: If your Ki Points fall below 1/4 of your Maximum "
            "Ki Points, leave this Evolved Stage.\n"
            "(4)-[Passive]: All of your Attacking Maneuvers gain the Full "
            "Wager Advantage.\n"
            "(5)-[Passive]: Your number of Ki Points may exceed your Maximum "
            "Ki Points.\n"
            "(6)-[Triggered/Transform]: Set the number of Battle Born stacks "
            "on each Combat Roll to 4, regardless of the limit (cannot "
            "decrease any Combat Roll's Battle Born).\n"
            "(7)-[Triggered, 1/Encounter]: If you use the Direct Hit option of "
            "the Defend Maneuver in response to an Attacking Maneuver, set its "
            "Damage Category to Standard for your Damage Calculation. If you "
            "received Damage, regain Ki Points equal to that Damage and use a "
            "Basic Attack/Signature Technique Maneuver Out-of-Sequence; if no "
            "Damage, use the Power Up or Energy Charge Maneuver Out-of-Sequence.",
      ),
    ],
  ),

  // ==================================== Super Saiyan 4 Limit Breaker (Evolved SS4) ===
  TransformationDef(
    name: "Super Saiyan 4 Limit Breaker",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 4). Fully Mastered "
        "Super Saiyan 4. Stress Test Requirement: +4.",
    aspects: ["Perfect Ki Control", "Draining (LV2)"],
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.insight: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: "Broken Limits",
        description: "You break through the upper ceiling of possibility, "
            "leaving beyond only shattered shards of your former limits.\n"
            "(1)-[Passive]: Increase your Tier of Power Extra Dice by 1 Dice "
            "Category.\n"
            "(2)-[Passive]: Increase your maximum number of Battle Born stacks "
            "for each Combat Roll by 1.\n"
            "(3)-[Passive]: Reduce the Ki Point Cost of your Multiplicative "
            "Technique by 3(T).\n"
            "(4)-[1/Round]: If you possess 6+ stacks of Battle Born, you may "
            "use the Power Up Maneuver as an Instant Maneuver.\n"
            "(5)-[Triggered/Power, 1/Encounter]: Use a Healing or Ki Surge as "
            "an Out-of-Sequence Maneuver.\n"
            "(6)-[Triggered, 1/Encounter]: If you use your Multiplicative "
            "Technique while below the Injured Health Threshold, you may apply "
            "either the All-Out or Complete Annihilation Super Profile to it "
            "and then apply an Energy Charge for every 4 stacks of Battle Born "
            "you possess.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Deeper Red",
      description: "Reaching even deeper inside you, you expand your power yet "
          "again, achieving the ultimate peak of primal power.\n"
          "(1)-[Permanent]: Super Saiyan 4 Limit Breaker loses the Draining "
          "Aspect.\n"
          "(2)-[Passive]: While you possess 10+ stacks of Battle Born, "
          "increase your Combat Rolls and Soak Value by 1(T).\n"
          "(3)-[Passive]: Double the increase to your Capacity from the Super "
          "Saiyan Form Aspect (does not stack with other such doublings).\n"
          "(4)-[Triggered, 1/Round]: If you knock an Opponent through a Health "
          "Threshold with your Multiplicative Technique, reduce their Dice "
          "Score for that Steadfast Check by 2 and they gain a stack of the "
          "Broken Combat Condition until the start of your next turn.\n"
          "(5)-[Triggered, 1/Round]: If you Defeat an Opponent with your "
          "Multiplicative Technique, to use a [Triggered/Defeated] effect they "
          "must first pass a Steadfast Check.",
    ),
  ),

  // ============================================== Super Saiyan 5 (Evolved SS4) ===
  TransformationDef(
    name: "Super Saiyan 5",
    type: TransformationType.form,
    formType: FormType.legendary,
    racialRequirement: "Saiyan",
    tierOfPowerRequirement: 6,
    prerequisiteText: "Evolved Stage: Unique (Super Saiyan 4). Fully Mastered "
        "Super Saiyan 4. Stress Test Requirement: +4.",
    aspects: [
      "Innate State (Raging/Bloodlusted)",
      "Exhausting",
      "Straining",
      "Draining (LV2)",
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
        name: "Primal Aggression",
        description: "An almost instinctual thirst for violence is fueling "
            "you now. You don't plan to stop until you put your enemy in the "
            "dirt or die trying.\n"
            "(1)-[Permanent]: You cannot enter the Super Saiyan 5 "
            "Transformation unless you are in the Bloodlusted State.\n"
            "(2)-[Passive]: You cannot leave the Bloodlusted State through "
            "any means.\n"
            "(3)-[Ruling]: Your 'Primal Force' is equal to x(T), where x is "
            "equal to 1/2 of the number of Battle Born stacks applied to "
            "your Wound Rolls (max. 3(T)).\n"
            "(4)-[Passive]: Increase your maximum number of Battle Born "
            "stacks you may apply to your Wound Rolls by 4, but you do not "
            "gain any bonuses to your Strike or Dodge Rolls from any stacks "
            "of Battle Born applied to them.\n"
            "(5)-[Passive]: While your number of Battle Born stacks applied "
            "to your Wound Rolls exceeds the number of stacks applied to "
            "your Strike or Dodge Rolls, increase your Strike Rolls, Dodge "
            "Rolls, and Soak Value by your Primal Force.\n"
            "(6)-[Passive]: For any effects that apply bonuses based on your "
            "number of Battle Born stacks, treat your number of Battle Born "
            "stacks as if they were 1 higher for every 2 stacks of Battle "
            "Born applied to your Wound Rolls.\n"
            "(7)-[Automatic]: Upon leaving this Transformation, you suffer "
            "from the Impediment Combat Condition for the remainder of the "
            "Combat Encounter.\n"
            "(8)-[Triggered, 1/Round]: If you spend a stack(s) of Battle "
            "Born through any effects, regain Life and Ki Points equal to "
            "your Primal Force.\n"
            "(9)-[Triggered, 1/Encounter]: If you use your Multiplicative "
            "Technique while below the Injured Health Threshold, before you "
            "apply any other [Triggered] effects in response to that "
            "Attacking Maneuver, you may gain a stack of Battle Born in each "
            "Combat Roll.",
      ),
      TransformationTrait(
        name: "Primal Hunger (Legendary Trait)",
        description: "Beyond seeking battle, the Saiyan blood within you "
            "boils over and seeks the destruction of your enemies.\n"
            "(1)-[Triggered, 1/Round]: If you would enter the Raging or "
            "Superior State through an effect (except that of an Aspect), "
            "you may instead enter the Bloodlusted Special State for the "
            "duration listed for that effect.",
      ),
      TransformationTrait(
        name: "Bloodlusted (Special State)",
        description: "(1)-[Passive]: Apply your Tier of Power Extra Dice an "
            "additional time to your Wound Rolls, ignoring the Tier of Power "
            "Limit (see — Core Rules).\n"
            "(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, "
            "you may spend a stack of Battle Born to apply an Energy Charge "
            "to that Attacking Maneuver.\n"
            "(3)-[Triggered, 1/Round]: If you are hit by an Attacking "
            "Maneuver, you may spend a stack of Battle Born to use the Basic "
            "Attack Maneuver or Signature Technique Maneuver as an "
            "Out-of-Sequence Maneuver.\n"
            "(4)-[Triggered, 1/Round]: If you Defeat or knock an Opponent "
            "through a Health Threshold with an Attacking Maneuver, gain a "
            "stack of Battle Born.\n"
            "(5)-[Triggered, 1/Encounter]: If you Defeat an Opponent with "
            "one of your Attacking Maneuvers and trigger the 4th effect of "
            "Bloodlusted, instead of gaining a single stack of Battle Born, "
            "you may apply a stack of Battle Born to each Combat Roll.",
      ),
    ],
    masteryTrait: TransformationTrait(
      name: "Primal Focus",
      description: "You have learned to harness the inner beast, no longer "
          "losing yourself to your bloodlust.\n"
          "(1)-[Permanent]: Super Saiyan 5 loses the Draining, Exhausting, "
          "Straining Aspects, and gains access to the Innate State (Mindful) "
          "Aspect.\n"
          "(2)-[Permanent]: Ignore the 1st and 7th effects of Primal "
          "Aggression.\n"
          "(3)-[Passive]: While you possess 6+ stacks of Battle Born applied "
          "to your Wound Rolls, increase your Combat Rolls and Surgency by "
          "1(T).\n"
          "(4)-[Passive]: Ignore the 2nd effect for the first Levels of the "
          "Mindful and Raging States.\n"
          "(5)-[1/Round]: Spend a stack of Battle Born to use the Power Up "
          "Maneuver as an Instant Maneuver.\n"
          "(6)-[1/Round]: Spend 2 stacks of Battle Born to use a Healing "
          "Surge as an Instant Maneuver.\n"
          "(7)-[Triggered, 1/Encounter]: If you use your Multiplicative "
          "Technique while you are below the Injured Health Threshold, you "
          "may apply either the All-Out Super Profile or the Complete "
          "Annihilation Super Profile to that Attacking Maneuver.",
    ),
  ),
];

/// Looks up an Alternate Form by name, or `null` if unrecognized.
TransformationDef? alternateFormByName(String name) {
  for (final f in kDbuAlternateForms) {
    if (f.name == name) return f;
  }
  return null;
}
