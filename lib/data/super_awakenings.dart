import 'dbu_rules.dart';
import 'race_traits.dart';
import 'transformations.dart';

/// All Super Awakenings from dbu-rpg.com, transcribed as [TransformationDef]s.
///
/// A Super Awakening is the pinnacle Awakening tier: a character may possess
/// only one (see [kMaxSuperAwakenings]). Each carries a **Grand Awakening**
/// Trait whose first effect is a `[Grand Trigger]` condition; the Grand
/// Awakening is switched on via the **Full Awakening Maneuver**. That Trait is
/// stored in [TransformationDef.grandAwakening] (rendered as its own togglable
/// subsection), separate from the always-on base Traits in `traits`.
///
/// Super Awakening AMB is written "(T)" on the site (tier-scaled), so entries
/// use `TransformationAmb(coefficient: 1, tierScaled: true)`.
const List<TransformationDef> kDbuSuperAwakenings = [
  // ============================================================== ANY RACE ===
  TransformationDef(
    name: 'Bottomless Potential',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: '2 stacks of Unlocked Potential',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Infinite Potential',
        description: 'There is no limit to the power you might achieve with '
            'enough time and effort.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Ignore the effects of the Fatigued Combat '
            'Condition.\n'
            '(3)-[Passive]: While you possess a stack of Power, increase '
            'your Combat Rolls and Soak Value by 1(T).\n'
            '(4)-[Passive]: The 6th effect of Potential loses [1/Encounter] '
            'and gains [1/Round].\n'
            '(5)-[Triggered]: If you score a Critical Result on a Wound '
            'Roll, increase the Dice Score by 2(T).\n'
            '(6)-[Triggered, 1/Encounter]: If you take Damage exceeding your '
            'current Life while below the Injured Threshold, set your Life '
            'to 1 instead (auto-succeed the Critical Steadfast Check; no '
            'Reduced Momentum).',
        automation: [
          // (3) While you possess a stack of Power: +1(T) Combat Rolls and
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
            condition: TraitCondition.whileAnyPowerStack,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Unleash it All, the Hidden Power',
      description: 'With a surge of energy, you draw out every reserve you '
          'have and awaken every ounce of power at your disposal, dormant or '
          'otherwise.\n'
          '(1)-[Grand Trigger]: You have triggered the 6th effect of Infinite '
          'Potential, OR an Ally (except a Minion) is Defeated, OR you have '
          '2+ stacks of Power while below the Injured Health Threshold.\n'
          '(2)-[Passive]: Increase your Attribute Modifiers (AG/FO/TE/MA) by '
          '1(T).\n'
          '(3)-[Passive]: The 3rd effect of Deeper Potential loses '
          '[1/Encounter] and gains [1/Round].\n'
          '(4)-[Passive]: The Ki Point Cost of your Attacking Maneuvers do '
          'not reduce your Capacity.\n'
          "(5)-[Passive]: All Opponents are considered your 'Focus' for the "
          'effects of the Surging State.\n'
          '(6)-[Triggered]: If an effect would let you enter the Surging '
          'State while already Surging, instead use the Energy Charge '
          'Maneuver Out-of-Sequence.\n'
          '(7)-[Triggered, 1/Encounter]: Upon using the Full Awakening '
          'Maneuver, enter the Surging State until you are Defeated.',
      // (2) +1(T) Attribute Modifiers (AG/FO/TE/MA) while Grand Awakened.
      ambBonus: {
        DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
        DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
        DbuAttribute.tenacity:
            TransformationAmb(coefficient: 1, tierScaled: true),
        DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
      },
    ),
  ),
  TransformationDef(
    name: 'Energy Consumption',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 1,
    maxStacks: 1,
    prerequisiteText: 'Energy Drain Unique Ability, 2+ Skill Ranks in Use '
        'Magic',
    // Listed on the site as Transformation Type: Manifested Power. AMB is
    // granted by Lifeforce (trait effect), not a flat table.
    amb: {},
    traits: [
      TransformationTrait(
        name: 'Hunger for Power',
        description: 'You consume the life force energy of other beings in '
            'order to empower yourself.\n'
            '-[Triggered, Resource]: Each time you gain Ki from a target via '
            'Energy Drain, gain 1 Lifeforce (max Z).\n'
            '-[Triggered]: If you gain Miracle Empowerment, gain 1 '
            'Lifeforce.\n'
            '-[Passive]: You only lose 1/2 of Z (rounded up) Lifeforce at '
            'the end of each Combat Encounter.\n'
            "-[Passive]: Increase this Manifested Power's Attribute Modifier "
            'Bonus (AG/FO/TE/MA) by your Lifeforce (independent of stacks).\n'
            '-[Passive]: Per your amount of Lifeforce, unlock the following '
            'scaling effects:\n'
            '2+: Increase the Dice Score of your Magical Wound Roll for the '
            'effects of the Energy Drain Unique Ability by 1/2 of your Insight '
            'Modifier.\n'
            '3+: You may use the Energy Drain Unique Ability an additional '
            'time per Combat Round.\n'
            '4+: You gain access to the Planetary Consumption Unique Ability.\n'
            '5+: You gain access to the Fire and Flames Unique Ability.\n'
            '6+: You gain access to the Forced Empowerment Unique Ability.\n'
            '7+: You may use the Energy Drain Unique Ability an additional '
            'time per Combat Round.',
      ),
      TransformationTrait(
        name: 'Power Restoration',
        description: 'With every morsel of life energy you consume, you grow '
            'stronger and stronger, becoming unstoppable.\n'
            '-[Passive]: Increase your Maximum Ki Point Pool by 10 × Z.\n'
            '-[Passive]: While at maximum Lifeforce, +2(T) Damage '
            'Reduction.\n'
            '-[Passive]: While your Lifeforce < 1/2 of Z (rounded up), Energy '
            'Drain has a KP Cost of 0.\n'
            '-[Triggered]: Upon gaining Lifeforce, regain 2(bT) Life '
            'Points.\n'
            '-[Triggered, 1/Round]: On a Signature Technique, spend up to '
            '1/2 (rounded up) of Z Lifeforce; each reduces the Ki Cost by '
            '1(T) and adds an Energy Charge.',
      ),
    ],
  ),
  TransformationDef(
    name: 'Grandmaster',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Martial Skill Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Martial Arts Master',
        description: 'You are extremely skilled at reading the flow of '
            'battle and reacting accordingly.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of your Signature '
            'Techniques by 1(T).\n'
            '(3)-[Passive]: While below the Bruised Threshold, +1(T) Combat '
            'Rolls and Soak Value.\n'
            '(4)-[Triggered]: When you use the Signature Technique Maneuver, '
            'either apply an Energy Charge or add a single qualifying '
            'Advantage to that Signature Technique.\n'
            '(5)-[Triggered/Start of Combat Round]: Gain 1 Counter Action.\n'
            '(6)-[Triggered, 1/Encounter]: If you use the Stance Maneuver, '
            'gain 1 Action.',
        automation: [
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
    grandAwakening: TransformationTrait(
      name: 'Secrets of the Master',
      description: 'Through all your training, you have developed techniques '
          'that few or, indeed, no others have even conceptualized.\n'
          '(1)-[Grand Trigger]: You are below the Injured Health Threshold or '
          'facing an Opponent whose base Tier of Power exceeds yours.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Surgency by 1(T) and '
          '2(T) respectively.\n'
          '(3)-[Passive]: Gain access to the Void Stance for the Stance '
          'Maneuver (detailed below).\n'
          '(4)-[Triggered, 1/Round]: If you target an Opponent with a no-AoE '
          'attack, their Tier of Power is set to base and their Power-stack '
          'Combat bonus is 0 for that attack.\n'
          '(5)-[Automatic/Start of Turn]: If in the Void Stance, reduce your '
          'Life and Ki Points by 5(bT).\n'
          '\n'
          'Void Stance — an additional Stance for the Stance Maneuver. While '
          'in the Void Stance, you gain the following effects: Increase your '
          'Combat Rolls by 1(T). Increase the Natural Result of your Combat '
          'Rolls by 1. Set the Ki Point Cost of your Attacking Maneuvers to '
          'their Minimum Value (1/2 of the Profile\'s Ki Point Cost). You are '
          'not considered to be suffering from any Combat Conditions for the '
          'effects of your Opponents, regardless of if you are suffering from '
          'any Combat Conditions or not. Upon entering the Void Stance, select '
          'another Stance. You are considered to be in that Stance for the '
          'effects of all Transformation Traits except those of Grandmaster. '
          'When you use the Stance Change Special Maneuver, instead of '
          'changing to a different Stance, you may simply leave the Void '
          'Stance and then immediately re-enter Void Stance.',
      automation: [
        // (2) +1(T) Combat Rolls and +2(T) Surgency while Grand Awakened.
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
        ),
        RaceTraitAutomation(
          affectedStats: [AffectedStat.surgency],
          coefficient: 2,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Mortal Flames',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Mortal Power',
        description: 'The sheer force of your energy rivals anything the '
            'Gods can possibly wield against you.\n'
            '(1)-[Passive]: You cannot enter the God Ki State or God Ki '
            'Aspect Transformations, nor spend/use Divine Ki Points.\n'
            '(2)-[Passive]: You can sense God Ki.\n'
            '(3)-[Passive]: Increase all your Saving Throws by 1(T).\n'
            '(4)-[Passive]: Increase your Might and Surgency by 1(T) and '
            '2(T) respectively.\n'
            '(5)-[Passive]: Increase your maximum number of Power stacks by '
            '1.\n'
            '(6)-[Passive]: While at maximum Power stacks, +1(T) Combat '
            'Rolls and Soak Value.',
        automation: [
          // (3) +1(T) all Saving Throws.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.impulsiveSave,
              AffectedStat.cognitiveSave,
              AffectedStat.corporealSave,
              AffectedStat.moraleSave,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (4) +1(T) Might and +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.might],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Flames of a Mortal Heart',
      description: 'Your overflowing energy lashes out at others, burning '
          "them as if with flames that aren't there.\n"
          '(1)-[Grand Trigger]: You are below the Injured Health Threshold.\n'
          '(2)-[Passive]: Increase your Wound Rolls and Soak Value by 3(T).\n'
          '(3)-[Passive]: Increase the Power stacks gained from the Power Up '
          'Maneuver by 1.\n'
          '(4)-[Passive]: Gain access to the Flames of Power Modifier '
          'Maneuver (detailed below).\n'
          '(5)-[Triggered]: If you win the Flames of Power Might Clash vs 1+ '
          'Opponent, gain 1 Action.\n'
          '(6)-[Triggered/Power, 3/Encounter]: Use a Ki Surge as an '
          'Out-of-Sequence Maneuver.\n'
          '\n'
          'Flames of Power Modifier Maneuver [1/Round] — Action Cost: 1 '
          'Action; Base Maneuver: Power Up Maneuver; KP Cost: 5(T). Effect: '
          'You become Fired Up until the start of your next turn. While you '
          'are Fired Up, ignore the Aflame Environmental Quality and increase '
          'your Tier of Power by 1 (see - Breakthrough). Upon becoming Fired '
          'Up, all Squares within a Destructive Sphere AoE (centered on you) '
          'become Aflame. Additionally, make a Might Clash against all '
          'Opponents within that AoE. If you win, that Character has their '
          'Life Points reduced by your Might.',
      automation: [
        // (2) +3(T) Wound Rolls and Soak Value while Grand Awakened.
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
            AffectedStat.soak,
          ],
          coefficient: 3,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Ruler of Time',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Access to the Time Freeze Unique Ability',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Temporal Master',
        description: 'You rule over the timeline with an iron fist, '
            'dictating every ebb and flow.\n'
            '(1)-[Permanent]: Gain access to the Time Power Enhancement (or '
            "master it if you already have it).\n"
            '(2)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(3)-[Passive]: Increase your Maximum Ki Points by 1/5.\n'
            '(4)-[Passive]: Increase your Combat Rolls during Frozen Turns '
            'by 1(T).\n'
            '(5)-[1/Round]: Use the Basic Attack or Movement Maneuver as an '
            'Instant Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If you inflict Slowed on an '
            'Opponent, make a Clash (Cognitive vs Impulsive/Corporeal/'
            'Cognitive/Morale); if you win, they skip their next turn.\n'
            '(7)-[Adventurous]: Spend Ki equal to your Max Capacity to free '
            'someone trapped by Time Labyrinth.',
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Commander of Chronology',
      description: 'When it comes to the flow of time, your word is law.\n'
          '(1)-[Grand Trigger]: You have used the Time Freeze Unique Ability '
          '3+ times this Combat Encounter and are below the Injured '
          'Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls by 1(T).\n'
          '(3)-[Passive]: All attacks made during a Frozen Turn gain an '
          'Energy Charge.\n'
          '(4)-[Passive]: If in the Time Power Enhancement, gain the Time '
          'Labyrinth Unique Ability (freeze a Character outside time) and '
          'the Time Rail Special Maneuver (reflect a Basic Attack) — see the '
          'site.\n'
          '(5)-[Triggered/Start of Combat Round, 1/Encounter]: Decide the '
          'Initiative Order of all Characters for this Combat Round.\n'
          '(6)-[Triggered/Defeated, 1/Encounter]: Make a Steadfast Check '
          '(−2 Dice Score); if you succeed, reset Life and Ki to max but '
          'lose all Resources and exit non-Natural Transformations (except '
          'Time Power).',
      automation: [
        // (2) +1(T) Combat Rolls while Grand Awakened.
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
        ),
      ],
    ),
  ),
  // Added post-ZIM (2026-07-12) from the live site (Transformation pages
  // published after the offline archive was captured).
  TransformationDef(
    name: 'Results of Supreme Training',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Training Beyond Limits',
        description: 'Hellish training that could be reasonably called '
            'torture has made you stronger than you could have ever '
            'dreamed.\n'
            '(1)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Points by 2 for each Power Level reached.\n'
            '(2)-[Passive]: Upon gaining this Awakening, gain 4 Character '
            'Perks to spend immediately.',
        automation: [
          // (1) +2 Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Awakened Through Training',
      description: 'What\'s the big idea pushing you into a corner? Don\'t '
          'they know that fighting for your life is the best kind of '
          'exercise?\n'
          '(1)-[Grand Trigger]: You have used the Power Up Maneuver 2+ '
          'times in a single turn while below the Injured Health '
          'Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls, Soak Value, and '
          'Surgency by 1(T).\n'
          '(3)-[Passive]: Increase your Stress Bonus by 1.\n'
          '(4)-[Multi-Option/2]: When you use the Full Awakening Maneuver, '
          'select and gain access to 2 of the following effects until the '
          'end of the Combat Encounter: Pure Attributes [Passive] — select '
          '2 Attributes and increase their Attribute Modifiers by 1(T) for '
          'the Encounter; Pure Skill [Passive] — create and gain access to '
          'a Signature Technique with a TP Cost of 50 or less, then apply '
          'an applicable Super Profile to it; Pure Talent [Passive] — '
          'select 2 Talents you meet the Prerequisites for and gain access '
          'to them for the Encounter.',
      automation: [
        // (2) +1(T) Combat Rolls, Soak Value and Surgency while Grand
        // Awakened.
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.strike,
            AffectedStat.dodge,
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
            AffectedStat.soak,
            AffectedStat.surgency,
          ],
          coefficient: 1,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Divine Ascension',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Obtained Divinity',
        description: '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: You are always in the God Ki Special State.\n'
            '(4)-[Passive]: If a Racial or Transformation Trait would put you '
            'in the God Ki State, you may enter the Superior State instead.\n'
            '(5)-[Passive]: Upon gaining this Awakening, select 2 God '
            'Maneuvers; you gain access to both.\n'
            '(6)-[Triggered]: Regain 2(bT) Divine Ki Points per Action spent '
            'on Combat Recovery.\n'
            '(7)-[Triggered, 1/Round]: On a Ki Surge, regain Divine Ki '
            'Points equal to 1/2 of your Surgency.\n'
            '(8)-[Triggered/Power, 1/Encounter]: Use a Ki Surge as an '
            'Out-of-Sequence Maneuver.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Awakened to Divine Power',
      description: '(1)-[Grand Trigger]: You are below the Injured Health '
          'Threshold and have used the 8th effect of Obtained Divinity this '
          'Combat Encounter.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(bT).\n'
          '(3)-[Passive]: Increase the Dice Category of your Greater Dice by '
          '2 Categories.\n'
          '(4)-[1/Round]: Use a Standard God Maneuver (1 Action) as an '
          'Instant Maneuver; its Divine Ki Point Cost is increased by 2(T).\n'
          '(5)-[Triggered/Start of Turn]: While in a Legendary Form or a '
          'Transcended Enhancement of Tier of Power 4+, regain 3(bT) Divine '
          'Ki Points.\n'
          '(6)-[Triggered/Power, 1/Encounter]: Enter the Superior State '
          'until the start of your next turn; if already Superior, you may '
          'enter the Surging State instead.',
      automation: [
        // (2) +1(bT) Combat Rolls and Soak Value while Grand Awakened.
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
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Awoken',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Any',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Cultivation of the Self Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Awoken to the Self',
        description: 'You are strong enough to compete without transforming '
            'like some warriors, and you relish the chance to show them '
            'up.\n'
            '(1)-[Passive]: Increase your Maximum Life Points and Maximum Ki '
            'Point Pool by 2 for each Power Level reached.\n'
            '(2)-[Passive]: Increase your Awakening Limit for your Lesser '
            'Awakenings by 2 (if you are using the Awakening Points Variant '
            'Rule, then gain 2 Awakening Points instead).\n'
            '(3)-[Passive]: While you are not in a Form, apply the following '
            'effects: increase your Surgency by 1(T); increase your Wound '
            'Rolls and Soak Value by 1(T); increase the Dice Score of your '
            'Steadfast Checks by 1.',
        automation: [
          // (1) +2 Max Life and Max Ki per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife, AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (3) While not in a Form: +1(T) Surgency, Wound Rolls and Soak
          // Value.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.surgency,
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNotInForm,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Awoken to the Truth',
      description: 'Your techniques alone make you a formidable opponent, '
          'and with them, you are ready to take on any fight, any '
          'opponent.\n'
          '(1)-[Grand Trigger]: You are below the Injured Health Threshold, '
          'OR at least 1 of your Opponents has a higher base Tier of Power '
          'than you.\n'
          '(2)-[Passive]: Double the Attribute Modifier Bonus of Awoken.\n'
          '(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver, you '
          'may apply a qualifying Advantage with a TP Cost of 10 or less to '
          'that Attacking Maneuver.\n'
          '(4)-[Choice]: Depending on your choice for the Option effect of '
          'Enhancement of the Self: Pure Resolve [Passive] — increase your '
          'Stress Bonus by 2; Built Different [Passive] — increase your '
          'Wound Rolls and Soak Value by 1(T).\n'
          '(5)-[Choice]: Depending on that same choice: Pure Resolve '
          '[Triggered, 1/Encounter] — when you use the Full Awakening '
          'Maneuver, you may trigger the Burst Limit for any Enhancement '
          'you are currently in (even if you have already used a Burst '
          'Limit this Combat Encounter); Built Different [Triggered, '
          '1/Encounter] — when you use the Full Awakening Maneuver, increase '
          'your Tier of Power by 1 (see — Breakthrough) until the end of '
          'your next turn.',
      // (2) Doubling the AMB while Grand Awakened is a multiplicative
      // interaction with the base table — shown as text, not auto-applied
      // (the (T) AMB is already live via the amb map). The Choice effects
      // depend on the Enhancement of the Self Option and stay reference
      // text.
    ),
  ),

  // ============================================================= ANDROID ===
  TransformationDef(
    name: 'Mightiest Android',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Android',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Cutting-Edge Survivability',
        description: 'Durable and reliable, your cybernetics and your power '
            'core ensure that you never tire and you never, ever, go '
            'down.\n'
            '(1)-[Passive]: Increase your Stress Bonus and Racial Life '
            'Modifier by 1 and 2 respectively.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: While in the Healthy Threshold, +1(T) Damage '
            'Reduction.\n'
            '(4)-[Choice]: Per your Technological Being 2nd-effect choice: '
            'Enhanced Organism — regain the Functional Purpose Racial Trait; '
            'Construct — ignore Critical Threshold Penalties and +2 Max Ki '
            'per Power Level.\n'
            '(5)-[Triggered, 1/Encounter]: If Damage would reduce your Life '
            'to 0, it reduces it to 1 instead.',
        automation: [
          // (1) +2 Racial Life Modifier = +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (3) While in the Healthy Threshold: +1(T) Damage Reduction.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.damageReduction],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileHealthyThreshold,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Cutting-Edge Power',
      description: 'Standing at the pinnacle of technology, you stop holding '
          'back to prove just how superior you truly are.\n'
          '(1)-[Grand Trigger]: You are below the Bruised Threshold and your '
          'Ki is below 1/2 of Maximum.\n'
          '(2)-[Passive]: Increase your Combat Rolls by 1(T).\n'
          '(3)-[Passive]: +1(T) Wound Rolls per Energy Charge applied to an '
          'attack (max 3(T)).\n'
          '(4)-[Triggered]: On an attack, spend 2(bT) Ki to apply an Energy '
          'Charge.\n'
          '(5)-[Triggered, 1/Encounter]: If you Ki Surge below the Critical '
          'Threshold, set your Life to 1 below the Injured Threshold.\n'
          '(6)-[Triggered, 1/Encounter]: On a Signature Technique, trigger '
          'the 4th effect up to 3 times for that attack.',
      automation: [
        // (2) +1(T) Combat Rolls while Grand Awakened.
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
        ),
      ],
    ),
  ),

  // =============================================================== ANGEL ===
  TransformationDef(
    name: 'Experienced Angel',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Angel',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Angelic Patience',
        description: 'You never use your full power in battle, choosing '
            'instead to aid others and avoid harm.\n'
            '(1)-[Passive]: Increase your Surgency by 2(T).\n'
            '(2)-[Passive]: Increase your Soak Value and Dodge Rolls by '
            '1(T).\n'
            '(3)-[Passive]: Increase the Combat Rolls of your Allies by '
            '1(T).\n'
            '(4)-[Passive]: Halve all Damage from Basic-Attack Maneuvers.\n'
            '(5)-[Triggered/Start of Turn]: Transfer 1 Counter Action to an '
            'Ally of your choice.\n'
            '(6)-[1/Encounter]: Spend a Counter Action to use a Healing '
            'Surge as an Instant Maneuver.',
        automation: [
          // (1) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (2) +1(T) Soak Value and Dodge Rolls.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.dodge],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'I Suppose I Must Act',
      description: 'Left with no choice due to the intensity of battle, you '
          'finally use a fraction of your full potential.\n'
          '(1)-[Grand Trigger]: You have used the 6th effect of Angelic '
          'Patience.\n'
          '(2)-[Passive]: Ignore the 2nd, 3rd, 4th, and 5th effects of '
          'Angelic Patience.\n'
          '(3)-[Passive]: Increase your Stress Bonus by 1 and your Combat '
          'Rolls by 2(T).\n'
          '(4)-[Passive]: Reduce the Critical Target of your Combat Rolls by '
          '1.\n'
          '(5)-[Triggered]: On a Critical Result, +2(T) that Combat Roll\'s '
          'Dice Score.\n'
          '(6)-[Triggered/Start of Combat Round]: Gain 1 Counter Action.\n'
          '(7)-[1/Round]: Spend a Counter Action to use a Ki Surge as an '
          'Instant Maneuver.\n'
          '(8)-[Triggered/Start of Turn]: Spend 3 Counter Actions to enter '
          'the Superior State until the start of your next turn.\n'
          '(9)-[Triggered/Superior, 1/Encounter]: Enter the Determined '
          'State.',
      automation: [
        // (3) +2(T) Combat Rolls while Grand Awakened (the Stress Bonus is
        // not modelled).
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.strike,
            AffectedStat.dodge,
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
          ],
          coefficient: 2,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),

  // ============================================================ ARCOSIAN ===
  TransformationDef(
    name: 'Boundless Evolution',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Arcosian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Mind of the Conqueror',
        description: 'The overwhelming aggression of your people flows '
            'through you, leading you to dominate the battlefield.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase the Apparel Bonus of your Plating by '
            '1(bT).\n'
            '(3)-[Passive]: For every 2 Overwhelm stacks, +1(T) Wound '
            'Rolls.\n'
            '(4)-[Passive]: Ignore the 5th effect of Survivor.\n'
            '(5)-[Triggered/Start of Turn]: While in your highest-ToP Form, '
            'gain an Overwhelm stack.\n'
            '(6)-[Triggered/Power, 1/Encounter]: Maximize your Overwhelm and '
            'Power stacks from this Power Up.',
        automation: [
          // (3) +1(T) Wound Rolls per 2 tracked 'Overwhelm' Resource stacks.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            kind: TraitMagnitudeKind.perNamedResourceStack,
            resourceName: 'Overwhelm',
            fractionDenominator: 2,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Resplendent Aggression',
      description: 'Glorious and elegant in your every move, you unleash a '
          'torrent of offensive might, overwhelming all who stand against '
          'you.\n'
          '(1)-[Grand Trigger]: You are in your highest-ToP Form, below the '
          'Bruised Threshold, and at maximum Overwhelm stacks.\n'
          "(2)-[Passive]: Increase your Combat Rolls by 1/4 of your Plating's "
          'Apparel Bonus.\n'
          '(3)-[Passive]: Double the Wound bonus from the 3rd effect of Mind '
          'of the Conqueror.\n'
          '(4)-[Passive]: +1 Dice Category to Energy Charges on your '
          'Signature Techniques.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'apply Legend Realized.\n'
          '(6)-[Triggered, 1/Encounter]: On an Ultimate Signature, target up '
          'to 2 more times (stacking Damage Category / Attribute increases '
          'per extra target).',
    ),
  ),
  // ========================================================== BIO-ANDROID ===
  TransformationDef(
    name: 'Genetic Max',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Bio-Android',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Artificial Max',
        description: 'Your biological design is flawless, having been '
            'revised for peak power and durability.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: +1 Dice Category to Energy Charges on your '
            'Signature Techniques.\n'
            '(4)-[Passive]: Upon gaining this Awakening, you may change your '
            'base Size Category to Gigantic.\n'
            '(5)-[Passive]: Per your Weapon of Mass Destruction Factor '
            'access: with it — regain Uncanny Monster or gain the Maximum '
            'Destruction Trait, plus 25 TP for Signature Techniques; without '
            'it — gain the Weapon of Mass Destruction Factor.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Beyond the Max',
      description: 'The sheer damage you were created to dish out is nothing '
          'short of staggering.\n'
          '(1)-[Grand Trigger]: You have your maximum Adaptation Points and '
          'are below the Injured Threshold.\n'
          '(2)-[Passive]: Increase your maximum Adaptation Points by 2.\n'
          '(3)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(4)-[Passive]: Double the Adaptation Points gained from Power Up '
          'while you have none.\n'
          '(5)-[Triggered]: If you spend all your Adaptation Points on a '
          'Combat Roll, +1(T) that roll.\n'
          '(6)-[Triggered, 1/Encounter]: If you use the 5th effect of '
          'Biological Weapon, enter the Superior State until the end of your '
          'next turn.',
      automation: [
        // (3) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),

  // =========================================================== CEREALIAN ===
  TransformationDef(
    name: 'Greatest Cerealian',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Cerealian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Cerealian Confidence',
        description: 'Your faith in your eyesight is unshakeable. You know '
            'that whatever it beholds must be the truth, and that faith '
            'fills you with confidence that you can take down anything in '
            'your sight.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Increase the Natural Results of your Strike and '
            'Wound Rolls by 1.\n'
            '(4)-[Triggered]: On a Critical Result, +2(T) that Combat '
            "Roll's Dice Score.\n"
            '(5)-[Triggered]: If an attack knocks an Opponent through a '
            'Threshold, −2 to their Steadfast Check for it.\n'
            '(6)-[Triggered, 1/Encounter]: If you Exploit an Opponent, apply '
            '2 Energy Charges (Impediment if they fail a knocked-through '
            'Steadfast Check).',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Devastating Sniper',
      description: 'Your people are amazing snipers, that much is common '
          'knowledge — but your accuracy and power make you terrifying on '
          'the battlefield, picking off enemies from a range most think '
          'impossible.\n'
          '(1)-[Grand Trigger]: You have hit Opponents with 3+ Called Shots '
          'this Combat Encounter.\n'
          '(2)-[Passive]: Increase your Combat Rolls by 1(T).\n'
          '(3)-[Passive]: Double the bonus from the 3rd effect of Cerealian '
          'Confidence.\n'
          '(4)-[Passive]: Increase your maximum Critical Eye stacks by 2.\n'
          '(5)-[Triggered, 1/Round]: On a Critical Strike Roll, apply an '
          'Energy Charge.\n'
          '(6)-[Triggered, 1/Encounter]: On a Critical Strike Roll, apply '
          'the Complete Annihilation Super Profile.\n'
          '(7)-[Triggered, 1/Encounter]: On a Critical on both Strike and '
          'Wound Rolls, +1 Tier of Power for that Wound Roll.',
    ),
  ),

  // ============================================================== DEMON ===
  TransformationDef(
    name: 'Demonic Heart',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Demon',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Faustian Bargain',
        description: 'In a devilish trade, you give up part of your future '
            'strength to unleash extra power here and now.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: +1(T) Dice Score for Might Clashes against '
            'Combat-Condition Opponents.\n'
            '(4)-[Triggered]: When making a Pressure Check, reduce your Life '
            'by 4(bT) for +1 Dice Score.\n'
            '(5)-[Triggered, 1/Encounter]: If you fail a Pressure Check, '
            'succeed instead (then gain 2 Demonic Fatigue after the next '
            'Demonic Pressure).\n'
            '(6)-[Triggered/Power, 1/Encounter]: Gain 2 Demonic Power (then 2 '
            'Demonic Fatigue after the next Demonic Pressure).',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Double or Nothing',
      description: 'Doubling down on your fate, you go all in, regardless of '
          'the stakes.\n'
          '(1)-[Grand Trigger]: You have not failed a Pressure Check in 3 '
          'Combat Rounds, OR you have succeeded 5 Pressure Checks while '
          'below the Injured Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(3)-[Passive]: You may apply the 4th effect of Faustian Bargain '
          'without spending Life.\n'
          '(4)-[Passive]: The 5th and 6th effects of Faustian Bargain lose '
          '[1/Encounter] and gain [1/Round].\n'
          '(5)-[Triggered/Start of Turn]: Roll 1d10; on a 10, you do not '
          'trigger the 3rd effect of Demonic Pressure.\n'
          '(6)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'lose all Demonic Fatigue and gain Demonic Power equal to 1/2 the '
          'Fatigue lost.',
      automation: [
        // (2) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),

  // ============================================================ EARTHLING ===
  TransformationDef(
    name: 'Earthling Spirit',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Earthling',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'From A to Z, a Warrior from Earth',
        description: 'Through tenacity and grit, you have drawn greater '
            'power out of every corner of your being.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Your Health Thresholds shift more forgiving '
            '(Bruised 3/4, Injured 1/2, Critical 1/4 of Max Life).\n'
            '(3)-[Multi-Option/2]: Upon gaining access to this Transformation, '
            'choose two of the following effects (if an effect has an '
            'Awakening or Factor listed in brackets, it requires you have that '
            'Awakening or Factor):',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Effects',
            maxChoices: 2,
            options: [
              TraitOption(
                name: 'Earthling Control',
                description: '[Passive]: Reduce the Ki Point Cost of all your '
                    'Attacking Maneuvers and Counter Maneuvers by 1(T).',
              ),
              TraitOption(
                name: 'Steel Resolve',
                description: '[Passive]: While below the Injured Health '
                    'Threshold, increase your Damage Reduction and Wound Rolls '
                    'by 1(T).',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.damageReduction,
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                    condition: TraitCondition.whileBelowInjuredThreshold,
                  ),
                ],
              ),
              TraitOption(
                name: 'Resolute Vengeance',
                description: '[Triggered/Threshold]: If you are knocked through '
                    "a Health Threshold by an Opponent's Attacking Maneuver, "
                    'enter the Surging State until the end of your next turn. '
                    'You must select that Opponent as your Focus through the '
                    'effects of the Surging State.',
              ),
              TraitOption(
                name: 'Ki Enlightenment (Triclops)',
                description: '[Triggered/Power]: Regain 4(bT) Capacity.',
              ),
              TraitOption(
                name: 'Balance between Bloodlines (Saiyan Ancestry)',
                description: '[Passive]: For each stack of Warrior Blood you '
                    'possess, increase the required Natural Result to trigger '
                    'the 2nd effect of Earthling Resolve by 1 (3 or less with '
                    '1 stack, 4 or less with 2 stacks, etc).',
              ),
              TraitOption(
                name: 'Dragon Master (Dragon Warrior)',
                description: '[Passive]: Upon gaining this Awakening, select '
                    'and gain access to an additional effect from the 3rd '
                    'effect of Quick to Master.',
              ),
              TraitOption(
                name: 'Power of Experience (Seasoned Warrior)',
                description: '[Passive]: The 4th effect of Gathered Experience '
                    'loses its [1/Encounter] Keyword and instead gains the '
                    '[3/Encounter] Keyword.',
              ),
              TraitOption(
                name: 'Final Stand Master (Desperate Warrior)',
                description: '[Passive]: While below the Injured Health '
                    'Threshold, increase your Strike and Wound Rolls by 1(T). '
                    'Additionally, the 4th effect of Secret Reserve applies '
                    'when above the Critical Health Threshold, instead of the '
                    'Injured Health Threshold.',
                automation: [
                  RaceTraitAutomation(
                    affectedStats: [
                      AffectedStat.strike,
                      AffectedStat.woundPhysical,
                      AffectedStat.woundEnergy,
                      AffectedStat.woundMagic,
                    ],
                    coefficient: 1,
                    tierScaling: TierScaling.current,
                    condition: TraitCondition.whileBelowInjuredThreshold,
                  ),
                ],
              ),
              TraitOption(
                name: 'Resolute Warrior of Earth (Warrior of Earth)',
                description: '[Passive]: Double the bonus from the 2nd effect '
                    'of Techniques of Earth.',
              ),
              TraitOption(
                name: 'Earthling Martial Arts (Martial Skill)',
                description: '[Passive]: Gain access to the Art of Earth '
                    'Advantage.',
              ),
              TraitOption(
                name: 'Hard Earned Transformation (Cultivation of the Self)',
                description: '[Passive]: Fully Mastered Legendary Forms are '
                    'considered Transcended Enhancements (as if they had their '
                    'Transcendent Trait) for the effects of Enhancement of the '
                    'Self and the Unlimited State. Requirement: Earthling '
                    'Martial Arts.',
              ),
            ],
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Spirit at the Brink',
      description: 'You refuse to stay down. You never quit. Enduring all '
          'hardships, you manage to persevere and thrive.\n'
          '(1)-[Grand Trigger]: You are below the Critical Health '
          'Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(3)-[Passive]: +1 Dice Category to your Energy Charges.\n'
          '(4)-[Passive]: Gain an additional Option effect from the 3rd '
          'effect of From A to Z while this Grand Awakening is active.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'turn previously failed Health-Threshold Steadfast Checks into '
          'successes.\n'
          '(6)-[Triggered, 1/Encounter]: On an Ultimate Signature, apply one '
          'qualifying Super Profile (All Out, Complete Annihilation, Giga '
          'Flare, Super Beam/Combination/Launch).',
      automation: [
        // (2) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),

  // ========================================================= GLASS TRIBE ===
  TransformationDef(
    name: 'Glasswork Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Glass Tribe',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Masterclass in Glass',
        description: '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Damage Reduction and Surgency by '
            '1(T).\n'
            '(3)-[Passive]: Increase your Corporeal Save by 1(T).\n'
            '(4)-[Triggered, 1/Round]: On a Signature Technique with the '
            'Glass Profile, apply an Energy Charge.\n'
            '(5)-[Triggered, 1/Encounter]: If you use the 5th effect of '
            'Heart of Glass, also regain Ki equal to the Life gained through '
            'that Healing Surge.',
        automation: [
          // (2) +1(T) Damage Reduction and Surgency.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.damageReduction,
              AffectedStat.surgency,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
          // (3) +1(T) Corporeal Save.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.corporealSave],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Razor-Edge of Refinement',
      description: '(1)-[Grand Trigger]: You have triggered the 5th effect '
          'of Heart of Glass and are below the Injured Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Damage Reduction by '
          '1(T).\n'
          "(3)-[Ruling]: An Opponent on a Glass Environmental Quality Square "
          "is 'On the Edge'; +1 Dice Category to Energy Charges if all "
          'targets are On the Edge.\n'
          '(4)-[Passive]: Double the Glass Profile Wound bonus if all '
          'targets are On the Edge.\n'
          '(5)-[Triggered/Start of Combat Round]: Apply the Glass '
          'Environmental Quality to a Large Sphere AoE.\n'
          '(6)-[Triggered/Start of Turn]: Corporeal Clash vs all On-the-Edge '
          'Opponents; on a win, −1/2 your Damage Reduction to their Life.\n'
          '(7)-[Triggered, 1/Encounter]: On a Lethal Ultimate Signature vs '
          'an On-the-Edge Opponent, apply 2 extra Energy Charges (ignore '
          'maximum).',
      automation: [
        // (2) +1(T) Combat Rolls and Damage Reduction while Grand Awakened.
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
        ),
      ],
    ),
  ),

  // =============================================================== HERAN ===
  TransformationDef(
    name: 'Galactic Heran',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Heran',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Powerful Privateer',
        description: 'Driven by your endless greed, you rise to greater and '
            'greater heights of power.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Wound Rolls, Soak Value, and '
            'Surgency by 1(T).\n'
            '(3)-[Passive]: Increase your maximum number of Power stacks by '
            '1.\n'
            '(4)-[Triggered/Power]: Spend 1 Greed for an additional Power '
            'stack from Power Up.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Below the Bruised '
            'Threshold, use a Surge of your choice Out-of-Sequence.',
        automation: [
          // (2) +1(T) Wound Rolls, Soak Value and Surgency.
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
              AffectedStat.soak,
              AffectedStat.surgency,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Power of the Space Raider',
      description: 'Thanks to your vast experiences plundering worlds across '
          'the universe, you have learned the most effective ways to use '
          'your strength to strike terror into the hearts of the masses.\n'
          '(1)-[Grand Trigger]: You have reached maximum Power stacks while '
          'below the Injured Threshold.\n'
          '(2)-[Passive]: While you possess 2+ Power stacks, +1(T) Combat '
          'Rolls.\n'
          '(3)-[Passive]: Increase the Magnitudes of your attack AoEs by '
          '1.\n'
          '(4)-[Passive]: Each Power stack increases your Wound Rolls by '
          '1(T).\n'
          '(5)-[Triggered/Start of Turn]: Gain a stack of Greed.\n'
          '(6)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'enter the Surging State until the start of your next turn.\n'
          '(7)-[Triggered/Start of Turn, 1/Encounter]: Ignore the 7th effect '
          'of Greed of the Hera, then Power Up Out-of-Sequence (regain '
          '2(bT) Life+Ki per Power stack).',
      automation: [
        // (4) +1(T) Wound Rolls per Power stack while Grand Awakened.
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
    ),
  ),

  // =========================================================== KONATSIAN ===
  TransformationDef(
    name: 'Konatsian Will',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Konatsian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Final Line of Defense',
        description: 'You are the last, best hope for civilization, holding '
            'the line against all who threaten your people.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your maximum number of Tension stacks '
            'by 1.\n'
            '(3)-[Passive]: Gain an additional Tension stack via the 2nd '
            'effect of Battle Tension while below the Critical Threshold.\n'
            '(4)-[Passive]: Your Health Thresholds shift more forgiving '
            '(Bruised 3/4, Injured 1/2, Critical 1/4 of Max Life).\n'
            '(5)-[Triggered/Power, 1/Encounter]: Energy Charge Maneuver '
            'Out-of-Sequence with +1 Energy Charge per 2 Tension stacks.',
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Triumphant Last Stand',
      description: 'With the last of your stamina, and the burning resolve '
          'inside you, you draw on an inner wellspring of power to ensure '
          'victory, no matter the cost.\n'
          '(1)-[Grand Trigger]: You are below the Injured Threshold and have '
          '4+ Tension stacks.\n'
          '(2)-[Passive]: For each Health Threshold you are below, +1(T) '
          'Combat Rolls.\n'
          '(3)-[Triggered]: Each time you gain Tension, regain 2(bT) Life '
          'and Ki per stack gained.\n'
          '(4)-[Triggered, 1/Round]: If an effect would let you enter the '
          'Entrusted State while already in it, enter the Surging State '
          'instead.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'enter the Entrusted State.',
      automation: [
        // (2) +1(T) Combat Rolls per Health Threshold below while Grand
        // Awakened.
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
      ],
    ),
  ),

  // =============================================================== MAJIN ===
  TransformationDef(
    name: 'Immemorial Chaos',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Mastered Pure Form',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Chaotic Combat',
        description: 'Wild and erratic, your combat style makes no sense to '
            'anyone but you, making it very hard to counter.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: While in the Pure Form Transformation, +1(T) '
            'Soak and Defense Value.\n'
            '(4)-[Passive]: While in Pure Form, use any 1-Action Standard '
            'Maneuver as an Instant Maneuver (still spend 1 Action).\n'
            '(5)-[Triggered, 1/Encounter]: If you roll a 6 on the Chaos Die, '
            'use a Healing Surge Out-of-Sequence.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (3) While in the Pure Form Transformation: +1(T) Soak and
          // Defense Value.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.soak, AffectedStat.defenseValue],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileNamedTransformationActive,
            conditionTransformationName: 'Pure Form',
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Chaotic Jackpot',
      description: 'Chaos is the name of the game, and you play to win. '
          'Whether by luck or some unknowable skill, you unleash the purest '
          'form of chaos onto the world around you.\n'
          '(1)-[Grand Trigger]: You roll a 6 on the Chaos Die 3 times in 1 '
          'Combat Round, OR you enter Pure Form with 3 stacks of Channeled '
          'Chaos.\n'
          '(2)-[Passive]: While in Pure Form, +1(T) Strike and +2(T) Wound '
          'Rolls.\n'
          '(3)-[Triggered]: On an attack, spend Channeled Chaos stacks for '
          'an equal number of Energy Charges.\n'
          '(4)-[Triggered, 1/Encounter]: On the 3rd Chaos-Die 6 in a Round, '
          'you cannot lose Life until the end of your next turn.\n'
          '(5)-[Triggered/Power, 1/Round]: While in Pure Form, spend 2 '
          "Channeled Chaos to increase Pure Form's AMB (AG/FO/TE/MA) by 1(T) "
          '(max +3(T)).',
      automation: [
        // (2) While in Pure Form: +1(T) Strike and +2(T) Wound Rolls.
        RaceTraitAutomation(
          affectedStats: [AffectedStat.strike],
          coefficient: 1,
          tierScaling: TierScaling.current,
          condition: TraitCondition.whileNamedTransformationActive,
          conditionTransformationName: 'Pure Form',
        ),
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
          ],
          coefficient: 2,
          tierScaling: TierScaling.current,
          condition: TraitCondition.whileNamedTransformationActive,
          conditionTransformationName: 'Pure Form',
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Mightiest Majin',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Assimilation Factor Trait',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Your Might is my Right',
        description: "You are able to draw even more power out of the "
            "entities you've absorbed and incorporated into yourself.\n"
            '(1)-[Passive]: +1(T) Dice Score for the Cognitive Clashes from '
            'the 5th and 8th effects of Assimilated Power.\n'
            '(2)-[Passive]: While you have a stack of Absorption, +1 Stress '
            'Bonus.\n'
            '(3)-[Passive]: While you have a stack of Absorption, +1(T) '
            'Combat Rolls and Soak Value.\n'
            '(4)-[Passive]: Apply an Energy Charge to any Signature '
            'Technique you use that is possessed by an Absorbed Character.',
        automation: [
          // (3) While you own the Absorption Awakening (always active while
          // possessed): +1(T) Combat Rolls and Soak Value.
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
            conditionTransformationName: 'Absorption',
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Birth of the Mightiest Majin',
      description: 'You have drawn out even more of your stolen power, '
          'becoming truly unstoppable.\n'
          '(1)-[Grand Trigger]: You gain a stack of Absorption, OR you are '
          'below the Injured Threshold while possessing a stack of '
          'Absorption.\n'
          '(2)-[Automatic/Start of Turn]: If you have no Absorption stacks, '
          'stop benefiting from this Grand Awakening.\n'
          '(3)-[Passive]: +2(T) Surgency, and +1(T) more per Absorption '
          'stack after the first.\n'
          '(4)-[Passive]: Increase the Life and Ki restored through the Full '
          'Awakening Maneuver by your Surgency.\n'
          '(5)-[Passive]: Double the bonus from the 3rd effect of Your Might '
          'is my Right.\n'
          "(6)-[Triggered/Start of Turn, 1/Encounter]: Gain an Absorbed "
          "Character's Secondary Racial Trait until you lose that Absorption "
          'stack / the Encounter ends.\n'
          '(7)-[Triggered, 1/Encounter]: If you lose the 5th-effect '
          'Assimilated Power Clash, you may win instead.',
      automation: [
        // (3) +2(T) Surgency while Grand Awakened (the extra +1(T) per
        // Absorption stack after the first stays manual).
        RaceTraitAutomation(
          affectedStats: [AffectedStat.surgency],
          coefficient: 2,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Unkillable Majin',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Majin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Always Bouncing Back',
        description: 'You never stay down for very long, thanks to your '
            'indestructible physiology.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: While above the Injured Threshold, +1(T) Soak '
            'and Defense Value.\n'
            '(4)-[Passive]: While at the Healthy Threshold, all Collision '
            'Damage is reduced to 0.\n'
            '(5)-[Passive]: The 3rd effect of Majin Regeneration and 3rd '
            'effect of From Goop become Instant Maneuvers (still spend 1 '
            'Action).\n'
            '(6)-[Triggered, 1/Encounter]: If you use a Healing Surge, use '
            'the Basic Attack Maneuver Out-of-Sequence afterwards.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Boundless Majin',
      description: "Thanks to your unique physiology, you don't have to obey "
          'any of the conventional limitations of the other races.\n'
          '(1)-[Grand Trigger]: You entered the Bruised Threshold from '
          'Injured/Critical via a Healing Surge.\n'
          '(2)-[Passive]: Your Life may exceed your Maximum by up to 1/2 of '
          'your Maximum.\n'
          '(3)-[Passive]: While below the Injured Threshold, +2(T) '
          'Surgency.\n'
          '(4)-[Passive]: While above the Injured Threshold, +1(T) Strike '
          'and +2(T) Wound Rolls.\n'
          '(5)-[Passive]: While at the Healthy Threshold, +1(T) Combat '
          'Rolls.\n'
          '(6)-[Passive]: You may spend Life as Ki for Ki Wagering (reduces '
          'Capacity as spent Ki).\n'
          '(7)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'regain 1/2 of your Maximum Life Points.',
      automation: [
        // (3) While below the Injured Threshold: +2(T) Surgency.
        RaceTraitAutomation(
          affectedStats: [AffectedStat.surgency],
          coefficient: 2,
          tierScaling: TierScaling.current,
          condition: TraitCondition.whileBelowInjuredThreshold,
        ),
        // (5) While at the Healthy Threshold: +1(T) Combat Rolls.
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
  ),

  // ============================================================ NAMEKIAN ===
  TransformationDef(
    name: "Dragon's Blessing",
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'An Extra Gift',
        description: "Thanks to the favor of the Eternal Dragon, you've "
            'gained an extra power all your own.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: +1(T) Soak Value for the duration of attacks by '
            'Studied Opponents.\n'
            '(4)-[Passive]: While you possess 1+ Power stacks, +1(T) Wound '
            'Rolls for you and your Studied Allies.\n'
            '(5)-[Triggered, 1/Round]: On a Signature Technique vs a Studied '
            'Opponent, gain a free Energy Charge (counts for Mandatory '
            'Charge).\n'
            '(6)-[Triggered/Injured, 1/Character]: If your base ToP is 5+, '
            'permanently gain the Ajisa Namekian Legendary Form (Transform '
            'into it Out-of-Sequence).',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (4) While 1+ Power stacks: +1(T) own Wound Rolls (the Studied
          // Ally share is manual).
          RaceTraitAutomation(
            affectedStats: [
              AffectedStat.woundPhysical,
              AffectedStat.woundEnergy,
              AffectedStat.woundMagic,
            ],
            coefficient: 1,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileAnyPowerStack,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Unleash the Dragon',
      description: 'Tapping into the power left within you by the Eternal '
          'Dragon, you become nigh-unstoppable, dishing out punishment and '
          'regenerating damage without batting an eye.\n'
          '(1)-[Grand Trigger]: You are below the Bruised Threshold, OR you '
          'are in the Ajisa Namekian Transformation.\n'
          '(2)-[Passive]: Select an additional Character for the 2nd effect '
          'of Intelligent Fighter.\n'
          '(3)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(4)-[Passive]: While in the Surging State, +1 Natural Result to '
          'your Strike and Wound Rolls.\n'
          '(5)-[1/Encounter]: Use the 3rd effect of Namekian Biology as an '
          'Instant Maneuver.\n'
          '(6)-[Triggered, 1/Encounter]: If you use a Healing Surge, enter '
          'the Surging State until the end of your turn (Focus a Studied '
          'Opponent).',
      automation: [
        // (3) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),
  TransformationDef(
    name: 'Mass-Fusion',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Namekian',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Super Namekian Awakening, 3+ stacks of Unified '
        'Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Namekian Honor',
        description: 'As a proud representative of the Namekian people, you '
            "uphold your people's honor and dignity.\n"
            "(1)-[Ruling]: For all effects here, 'Z' = your number of "
            'Unified stacks.\n'
            '(2)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(3)-[Passive]: Increase your Racial Life Modifier by Z.\n'
            '(4)-[Passive]: While at the Healthy Threshold, reduce the '
            'Damage Category of all attacks by 1 for your Damage '
            'Calculation.\n'
            '(5)-[Passive]: The 6th effect of Unified loses [1/Encounter] '
            'but costs 2Z(bT) Ki Points.\n'
            '(6)-[Passive]: Your first 2 Unified stacks do not count towards '
            'your Awakening Limit.\n'
            '(7)-[Triggered, 1/Encounter]: If you Healing Surge below the '
            'Injured Threshold, apply your Surgency an additional time.',
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Awaken! The Super Namekian!',
      description: 'The full power of the many other Namekians you merged '
          'with finally fully awakens, making you even sturdier.\n'
          '(1)-[Grand Trigger]: 6 Combat Rounds have passed this Encounter '
          '(−1 Round for each Round you ended having taken Damage).\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by 1/2 '
          'of Z(bT).\n'
          '(3)-[Passive]: Increase the Life and Ki regained through the Full '
          'Awakening Maneuver by your Surgency.\n'
          '(5)-[Triggered, 1/Round]: On an attack, spend Life up to your '
          'Surgency to increase its Wound Roll by an equal amount.\n'
          '(6)-[Triggered, 1/Encounter]: If targeted by an attack, use the '
          'Direct Hit or Guard option of the Defend Maneuver without a '
          'Counter Action.\n'
          '(7)-[Triggered, 1/Encounter]: If hit by an attack, +your Surgency '
          'to Soak Value for that attack.',
    ),
  ),

  // =========================================================== NEKO MAJIN ===
  TransformationDef(
    name: 'Strongest Neko',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Neko Majin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'An Integrated Majin-Dama',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: '#1 Neko Majin',
        description: '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Upon obtaining this Super Awakening, select an '
            'Integrated Majin-Dama; it becomes a Super Majin-Dama (+1(T) '
            'AG/TE/FO/MA/IN and +2 Max Life/Ki per Power Level).\n'
            '(4)-[Triggered, 1/Round]: On an Energy Charge declaring a '
            'Copied Technique, spend 3(bT) Ki for an additional Energy '
            'Charge (counts as 2 uses for Mandatory Charge).\n'
            '(5)-[1/Encounter]: Use the Energy Charge Maneuver as an Instant '
            'Maneuver (must declare a Copied Technique).',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Full Power Majin-Dama',
      description: '(1)-[Grand Trigger]: You are below the Injured '
          'Threshold, have an Integrated Super Majin-Dama, and have a Copied '
          'Technique.\n'
          '(2)-[Passive]: Double the Attribute Modifier Bonus increase from '
          'your Super Majin-Dama.\n'
          '(3)-[Passive]: For the effects of Neko Majin-Dama, increase x by '
          '1.\n'
          '(4)-[Passive]: +1 Dice Category to Energy Charges on your Copied '
          'Techniques.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, use '
          'the Energy Charge Maneuver Out-of-Sequence.\n'
          '(6)-[Triggered, 1/Encounter]: On an Ultimate Signature that is a '
          'Copied Technique, apply one qualifying Super Profile (All Out, '
          'Complete Annihilation, Giga Flare, Super Beam/Combination/'
          'Launch).',
    ),
  ),

  // =========================================================== NEO-TUFFLE ===
  TransformationDef(
    name: 'Tuffle Masterpiece',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Neo-Tuffle',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Last Hope of the Tuffles',
        description: 'The dying wish of your creators was to see their '
            'killers face the same fate. You are their executioner.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Increase your maximum Revenge Points by 2.\n'
            '(4)-[Passive]: For each Health Threshold you are below, +1(T) '
            'Wound Rolls.\n'
            '(5)-[Passive]: Double the Revenge Points gained via the 1st '
            'effect of Energy of Revenge.\n'
            '(6)-[Passive]: Per Subrace: Hatred Embodiment — +1 Damage '
            'Category vs your Inferior; Parasite — while Possessing, +1(T) '
            "the host's Combat Rolls/Soak (and share effects 3 and 5).",
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (4) +1(T) Wound Rolls per Health Threshold below.
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
    ],
    grandAwakening: TransformationTrait(
      name: 'Revenge Death Attack',
      description: 'The time has finally come to avenge your fallen '
          'creators. Unleash their hatred and finally achieve their '
          'revenge.\n'
          '(1)-[Grand Trigger]: You have spent 7+ Revenge Points in 1 Combat '
          'Round while below the Bruised Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls by 1(T).\n'
          '(3)-[Passive]: +2(T) Soak Value for the duration of your '
          "Inferior's attacks.\n"
          '(4)-[Passive]: +1 Tier of Power for the duration of your '
          'Ultimate Signatures.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'maximize your Revenge Points.\n'
          '(6)-[Triggered, 1/Encounter]: On an Ultimate Signature, apply one '
          'qualifying Super Profile (All Out, Complete Annihilation, Genki, '
          'Giga Flare, Super Beam/Combination/Launch).',
      automation: [
        // (2) +1(T) Combat Rolls while Grand Awakened.
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
        ),
      ],
    ),
  ),

  // ============================================================== SAIYAN ===
  TransformationDef(
    name: 'Endless Zenkai',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: '3 stacks of Zenkai',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Cycle of Pain and Power',
        description: 'You have overcome the limits on how many times you can '
            'grow stronger when recovering from the brink of death.\n'
            '(1)-[Passive]: While below the Bruised Threshold, +1 Stress '
            'Bonus.\n'
            '(2)-[Passive]: For each Health Threshold you are below, +1(T) '
            'Surgency, Soak Value, and Wound Rolls.\n'
            '(3)-[Passive]: Increase Z for all Zenkai Traits by 1 for each '
            'Health Threshold you are below.\n'
            '(4)-[1/Encounter]: As an Instant Maneuver, reduce your Life by '
            'up to 1/2 of Max to gain an equal amount of Ki (may exceed Max '
            'Ki; no Reduced Momentum, may trigger knocked-through effects).',
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
    ],
    grandAwakening: TransformationTrait(
      name: 'This Pain Will Make Me Stronger…!',
      description: 'When you reach the edge and feel the cold grasp of death '
          'upon you, you do not turn away — rather, you embrace the feeling '
          'and feel your power grow in response.\n'
          '(1)-[Grand Trigger]: You have triggered the 4th effect of Born '
          'for Battle this Combat Encounter.\n'
          '(2)-[Passive]: You are always considered below the Critical '
          'Threshold for your effects.\n'
          '(3)-[Passive]: Increase your Combat Rolls and Damage Reduction by '
          '1(T).\n'
          '(4)-[Passive]: Double the Life regained through the Full '
          'Awakening Maneuver.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, +1 '
          'Tier of Power until the start of your next turn.',
      automation: [
        // (3) +1(T) Combat Rolls and Damage Reduction while Grand Awakened.
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
        ),
      ],
    ),
  ),
  TransformationDef(
    name: 'Limitless Saiyan',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Saiyans Have No Limits',
        description: 'You consistently push yourself past the limit, '
            'shattering everyone\'s expectations and going to realms no one '
            'thought possible.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: For each Health Threshold you are below, +1(T) '
            'Wound Rolls.\n'
            '(4)-[Passive]: While in your highest-ToP Form, gain an '
            'additional Power stack from Power Up.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Below the Bruised '
            'Threshold, use a Surge of your choice Out-of-Sequence.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (3) +1(T) Wound Rolls per Health Threshold below.
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
    ],
    grandAwakening: TransformationTrait(
      name: 'Charge at Full Power',
      description: 'The energy at your fingertips is infinite and endless; '
          'you need only reach out to it to achieve even greater power.\n'
          '(1)-[Grand Trigger]: You are in your highest-ToP Form, below the '
          'Bruised Threshold, and have 2+ Power stacks.\n'
          '(2)-[Passive]: While you possess 2+ Power stacks, +1(T) each '
          'Combat Roll per Battle Born stack applied to it (max 2(T) each).\n'
          '(3)-[Passive]: +1(T) Dice Score for your Duel Clashes.\n'
          '(4)-[Triggered, 1/Round]: On a Signature Technique with 6+ Battle '
          'Born, +1 Tier of Power for that attack.\n'
          '(5)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'gain a stack of Battle Born.\n'
          '(6)-[Triggered, 1/Encounter]: On an Ultimate Signature, apply one '
          'qualifying Super Profile (All Out, Complete Annihilation, Giga '
          'Flare, Super Beam/Combination/Launch).',
    ),
  ),
  TransformationDef(
    name: 'Saiyan Prodigy',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Saiyan',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Access to Pure Progress',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Learning through Combat',
        description: 'Your combat prowess skyrockets as the battle '
            'continues, and you grow exponentially stronger the longer you '
            'fight.\n'
            '(1)-[Passive]: While you possess 4+ Progress stacks, +1 Stress '
            'Bonus.\n'
            '(2)-[Passive]: While you possess 4+ Battle Born stacks, +1 '
            'Stress Bonus.\n'
            '(3)-[Passive]: Increase your Surgency by 2(T).\n'
            '(4)-[Triggered, 1/Round]: If you knock an Opponent through a '
            'Threshold, gain a Battle Born stack.\n'
            '(5)-[Triggered, 1/Encounter]: If you trigger the 3rd effect of '
            'Born for Battle, gain 2 Progress stacks.',
        automation: [
          // (3) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Bottomless Combat Prowess',
      description: 'There is no limit to the depth of your combat potential '
          '— you grow in battle at a mind-boggling speed.\n'
          '(1)-[Grand Trigger]: You are in the Flow State and possess 4+ '
          'Battle Born stacks.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(3)-[Triggered, Resource]: In the Flow State, Battle Born gained '
          'past your maximum instead becomes Bottomless Battle Born (apply '
          'each to your lowest-stacked Strike/Dodge/Wound; +1(T) each).\n'
          '(4)-[Triggered, 1/Round]: If you gain a Progress stack via Combat '
          'Imprinting, gain a Battle Born stack.\n'
          '(5)-[Automatic]: Upon leaving the Flow State, lose all Bottomless '
          'Battle Born stacks.',
      automation: [
        // (2) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),

  // ======================================================== SHADOW DRAGON ===
  TransformationDef(
    name: 'Draconic Ascension',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Warrior of the Eternal Dragon',
        description: 'One of many aspects of the Eternal Dragon, you share '
            'some of its vast power.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Ignore Reduced Momentum.\n'
            '(4)-[Passive]: Increase the maximum Life reduction from the 1st '
            'effect of Negative Ki by 4(bT).\n'
            '(5)-[Triggered]: On a Critical Wound Roll, +2(T) its Dice '
            'Score.\n'
            '(6)-[Triggered, 1/Round]: If you gain Negative Energy, use the '
            'Power Up Maneuver Out-of-Sequence.\n'
            '(7)-[Triggered/Start of Combat Round, 1/Encounter]: Below the '
            'Injured Threshold, use a Healing Surge Out-of-Sequence.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Rise of the Shadow Dragon',
      description: 'As your power grows, reality turns on its head as '
          'darkness falls upon your enemies, leaving them utterly at your '
          'mercy.\n'
          '(1)-[Grand Trigger]: You possess 10+ Negative Energy, OR you are '
          'below the Injured Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Surgency by 1(T).\n'
          '(3)-[Passive]: +1 Negative Energy gained through all your '
          'effects.\n'
          '(4)-[Triggered]: On a Wound Roll, spend 2 Negative Energy to make '
          'it a Critical Result.\n'
          '(5)-[Triggered, 1/Round]: If an Opponent scores a Critical, spend '
          '4 Negative Energy to make it a Botch instead.\n'
          '(6)-[Triggered/Power, 1/Encounter]: Roll 1d8; gain that many '
          'Negative Energy.\n'
          '(7)-[Triggered, 1/Encounter]: On a Signature Technique, spend up '
          'to 6 Negative Energy for an Energy Charge per 2 spent.',
      automation: [
        // (2) +1(T) Combat Rolls and Surgency while Grand Awakened.
        RaceTraitAutomation(
          affectedStats: [
            AffectedStat.strike,
            AffectedStat.dodge,
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
  ),
  TransformationDef(
    name: 'Omega',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Shadow Dragon',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'You are a Shadow Dragon made from a set of 7 Dragon '
        'Balls',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Dragon Ball Collector',
        description: 'You\'ve gained great power by absorbing some of your '
            '"siblings", allowing you to access their powers as if they were '
            'your own.\n'
            "(1)-[Ruling]: For all effects here, 'Z' = your number of "
            'Unified stacks.\n'
            '(2)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(3)-[Passive]: Ignore Reduced Momentum.\n'
            '(4)-[Passive]: Increase the maximum Life reduction from the 1st '
            'effect of Negative Ki by Z(bT).\n'
            '(5)-[Passive]: The 6th effect of Unified loses [1/Encounter] '
            'but costs 2Z(bT) Ki Points.\n'
            '(6)-[Passive]: Your first 2 Unified stacks do not count towards '
            'your Awakening Limit.\n'
            '(7)-[Triggered/Start of Combat Round, 1/Encounter]: With 6+ '
            'Unified (or a Temporary Unified stack), Power Up '
            'Out-of-Sequence.',
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'The Ultimate Shadow Dragon',
      description: 'The combined power of the Dragon Balls within you grants '
          'you an even greater portion of the power of the dragon which you '
          'were fractured from, allowing you to warp reality even further.\n'
          '(1)-[Grand Trigger]: You have triggered the 7th effect of Dragon '
          'Ball Collector.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by 1/2 '
          'of Z(bT).\n'
          '(3)-[Passive]: Gain all Personified Dragon Ball Option effects of '
          'your Merged Characters (duplicate effects give +1(bT) Wound '
          'instead).\n'
          '(4)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'increase the Life and Ki regained by your Surgency.\n'
          '(5)-[Triggered/Power, 1/Encounter]: With 6+ Unified (or a '
          'Temporary Unified stack), +1 Tier of Power until the start of '
          'your next turn.',
    ),
  ),

  // ============================================================= SHINJIN ===
  TransformationDef(
    name: 'Divine Authority',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Shinjin',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    prerequisiteText: 'Ascension Greater Awakening',
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Actions of The Watcher',
        description: 'You have borne witness to the lives of mortals for '
            'eons and now, with absolute conviction, you know just what to '
            'do to fulfill your duties.\n'
            '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: The 2nd effect of Celestial Perfection applies '
            'below the Bruised Threshold instead of Injured.\n'
            '(3)-[Passive]: Increase Life and Ki regained through Combat '
            'Recovery by 1/2 of your Surgency.\n'
            '(4)-[Passive]: You are always in the God Ki Special State.\n'
            '(5)-[Passive]: You may enter the Surging State instead of God '
            'Ki through the 6th effect of Celestial Perfection.\n'
            '(6)-[Choice]: Depending on your choice for the 3rd effect of '
            'Divine Magic, gain the following effects:\n'
            'God of Peace [Passive]: While in the Mindful State, increase your '
            'Combat Rolls by 1(T).\n'
            'God of Judgment [Passive]: Increase the Dice Category of your '
            'Energy Charge Extra Dice by 1 Category.\n'
            'God of Power [Passive]: For each stack of Super Stack you possess, '
            'increase your Wound Rolls by 1(T).\n'
            'God of Survival [Triggered/Threshold]: Use the Combat Recovery '
            'Maneuver (as if you spent 1 Action) as an Out-of-Sequence '
            'Maneuver.\n'
            'God of Wisdom [Passive]: Increase your Scholarship and '
            'Personality Modifiers by 1(T).\n'
            'God of War [Passive]: Your Armed Attacks have their Critical '
            'Target for their Wound Rolls reduced by 1. Additionally, if you '
            'score a Critical Result on the Wound Roll for an Armed Attack, '
            'increase the Wound Roll by 2(T).\n'
            'God of Magic [1/Round]: You may use a Unique Ability that is a '
            'Standard Action with an Action Cost of 1 Action as an Instant '
            'Maneuver.\n'
            'God of Many [Passive]: Increase the Combat Rolls and Soak Value '
            'of your Minions by 1(bT).\n'
            'God of Time [Passive]: Reduce the Ki Point Cost of all Unique '
            "Abilities with 'Time' in their name by 2(T).\n"
            'God of an Element [Passive]: Reduce the Ki Point Cost of your '
            'Favored Element by 2(T).',
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Divine Speech',
      description: 'No one understands your true glory, but by extolling '
          'your divine virtue, you draw power from your own grandeur, your '
          'certainty that your path is righteous and your cause just.\n'
          '(1)-[Grand Trigger]: You spend 3 Actions on the Combat Recovery '
          'Maneuver while below the Injured Threshold.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Surgency by 1(T) '
          'and 2(T) respectively.\n'
          '(3)-[1/Round]: As an Instant Maneuver, spend 2 Counter Actions to '
          'use a 1-Action Standard Maneuver Out-of-Sequence.\n'
          '(4)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'gain 2 Counter Actions.\n'
          '(5)-[Triggered/Start of Combat Round]: Gain an additional Counter '
          'Action.',
      automation: [
        // (2) +1(T) Combat Rolls and +2(T) Surgency while Grand Awakened.
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
        ),
        RaceTraitAutomation(
          affectedStats: [AffectedStat.surgency],
          coefficient: 2,
          tierScaling: TierScaling.current,
        ),
      ],
    ),
  ),

  // ============================================================= YARDRAT ===
  TransformationDef(
    name: 'Yardrat Master',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.mind,
    racialRequirement: 'Yardrat',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Spiritual People',
        description: '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Increase your Maximum Ki Points by 2 for each '
            'Power Level reached.\n'
            '(4)-[Passive]: Increase your Max Capacity by 1/4.\n'
            '(5)-[Passive]: Use each Spiritual Unique Ability an additional '
            'time per Combat Round.\n'
            '(6)-[1/Encounter]: Use a Ki Surge as an Instant Maneuver.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
          // (3) +2 Max Ki per Power Level. ((4)'s ×1.25 Max Capacity is
          // multiplicative — text only.)
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxKi],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: 'Heart of Yardrat',
      description: '(1)-[Grand Trigger]: You and your Bonded Ally are below '
          'the Bruised Threshold, OR (with the Battle Yardrat Awakening) you '
          'are below the Injured Threshold.\n'
          '(2)-[Passive]: Increase the Combat Rolls of you and your Bonded '
          'Ally by 1(T).\n'
          '(3)-[Passive]: Double the bonus from the 2nd effect of Spiritual '
          'People.\n'
          '(4)-[Triggered/Start of Turn]: Regain 3(bT) Life and Ki '
          'Points.\n'
          '(5)-[Triggered, 1/Round]: If you or your Bonded Ally use a '
          "Signature Technique, +2(T) its Ki Cost for an Energy Charge.\n"
          '(6)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'your Bonded Ally regains 1/10th of their max Life and Ki.\n'
          '(7)-[Triggered, 1/Encounter]: On a Ki Surge, you or your Bonded '
          'Ally enter the Superior State until the start of your next turn.',
      automation: [
        // (2) +1(T) own Combat Rolls while Grand Awakened (the Bonded Ally
        // share is manual).
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
        ),
      ],
    ),
  ),

  // ====================================================== CUSTOM SPECIES ===
  TransformationDef(
    name: 'The Incredible Mightiest',
    type: TransformationType.awakening,
    awakeningType: AwakeningType.superAwakening,
    origin: TransformationOrigin.body,
    racialRequirement: 'Custom Species',
    tierOfPowerRequirement: 4,
    maxStacks: 1,
    amb: {
      DbuAttribute.agility: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.force: TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.tenacity:
          TransformationAmb(coefficient: 1, tierScaled: true),
      DbuAttribute.magic: TransformationAmb(coefficient: 1, tierScaled: true),
    },
    traits: [
      TransformationTrait(
        name: 'Clash! 10 Billion Power Warriors!',
        description: '(1)-[Passive]: Increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Upon gaining this Awakening, select a Custom '
            'Species Racial Trait without its Twinned effects; gain access '
            'to its Twinned effects.\n'
            '(4)-[Passive]: +1 Dice Category to your Greater Dice.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Enter the Superior State '
            'until the start of your next turn.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
    ],
    grandAwakening: TransformationTrait(
      name: "I'm the One who will Win!",
      description: '(1)-[Grand Trigger]: You are below the Injured Threshold '
          'and have 2+ Power stacks.\n'
          '(2)-[Passive]: Increase your Combat Rolls and Soak Value by '
          '1(T).\n'
          '(3)-[Passive]: Double the bonus from the 4th effect of Clash! 10 '
          'Billion Power Warriors!\n'
          '(4)-[Passive]: Ignore all of your Flaws.\n'
          '(5)-[Triggered, 1/Round]: If an effect would let you enter the '
          'Superior State while already in it, use a 1-Action Standard '
          'Maneuver Out-of-Sequence instead.\n'
          '(6)-[Triggered, 1/Encounter]: On the Full Awakening Maneuver, '
          'enter the Superior State until Defeated / a failed Steadfast '
          'Check / the Encounter ends / your Ki reaches 0.',
      automation: [
        // (2) +1(T) Combat Rolls and Soak Value while Grand Awakened.
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
  ),
];

/// Looks up a Super Awakening by name, or `null` if unrecognized.
TransformationDef? superAwakeningByName(String name) {
  for (final a in kDbuSuperAwakenings) {
    if (a.name == name) return a;
  }
  return null;
}
