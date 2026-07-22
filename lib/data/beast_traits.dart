/// beast_traits.dart
/// ---------------------------------------------------------------------------
/// The Bestial Traits and Monstrous Traits catalogues (their own pages on the
/// live site). Many Racial Traits, Racial Factors, Subraces, Awakenings and
/// Forms grant "a Bestial Trait" / "a Monstrous Trait"; this file holds the
/// actual, selectable list of what those grants can pick, transcribed verbatim.
///
/// Each entry is modeled as a `RaceTraitDef` (race `'Bestial'` / `'Monstrous'`)
/// so it reuses the whole Racial-Trait pipeline for free — verbatim rendering,
/// the `[Option]`/`[Multi-Option]` pickers, granted Resources, and the same
/// additive `automation` machinery. Only effects that are a clean, always-on
/// (or simply-conditioned) additive bonus to a stat the sheet already computes
/// are auto-applied — every other effect is shown as text, exactly the
/// convention used for Racial Traits (see `race_traits.dart`).
library;

import 'dbu_rules.dart';
import 'race_traits.dart';

/// Verbatim "Bestial Limit" rule from the Bestial Traits page — shown as a
/// reminder wherever Bestial Traits are picked. "You cannot benefit from more
/// than 4 Bestial Traits at any one time."
const int kBestialTraitLimit = 4;

/// The catalogue for a given [kind].
List<RaceTraitDef> beastTraitsFor(BeastTraitKind kind) =>
    kind == BeastTraitKind.bestial ? kBestialTraits : kMonstrousTraits;

/// Look up a single Bestial/Monstrous Trait by [kind] + [name] (null if the
/// name is unrecognized — tolerant of stale/renamed picks).
RaceTraitDef? beastTraitByName(BeastTraitKind kind, String name) {
  for (final t in beastTraitsFor(kind)) {
    if (t.name == name) return t;
  }
  return null;
}

// ===========================================================================
// BESTIAL TRAITS
// ===========================================================================
const List<RaceTraitDef> kBestialTraits = [
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Alternate Sight',
    description:
        "Your eyes are clearly designed to work in a different way than most, "
        "allowing you to see in the dark.\n"
        "(1)-[Passive]: Treat the Light Level as if it was 1 level closer to "
        "Normal (0).\n"
        "(2)-[Passive]: Increase the Dice Score of your Perception Skill "
        "Checks by 1.\n"
        "(3)-[Passive]: Increase the Natural Result of your Dodge Rolls by "
        "1.\n"
        "(4)-[1/Round]: As an Instant Maneuver, target an Opponent who is not "
        "Hidden from you. Make a Skill Clash (Perception vs Perception/"
        "Stealth) against them. If you win, increase the Strike and Wound "
        "Rolls of your next Attacking Maneuver made against that Opponent "
        "during this Combat Round by 1(T) and 2(T) respectively.",
    automation: [
      // (2) +1 Perception Skill Checks (flat).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.skillPerception],
        coefficient: 1,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Arboreal',
    description:
        "While most beasts of note are mammals or insects, you are instead "
        "animate flora, which allows you to utilize the sun's energy in place "
        "of your own. (Inspired by the Homebrew from Gyrobbio of the DBU "
        "Discord)\n"
        "(1)-[Triggered/Start of Turn, Resource]: Gain a stack of Sunlight "
        "(max. 2) if the Light Level is Normal or higher.\n"
        "(2)-[1/Round]: As a Standard Action with an Action Cost of 1 Action, "
        "you may spend a stack of Sunlight to use a Ki Surge.\n"
        "(3)-[1/Round, Ruling]: As a Standard Action with an Action Cost of 1 "
        "Action, you become 'Rooted'. While you are Rooted: You cannot use "
        "the Movement Maneuver or any other effect that would allow you to "
        "move. Increase your Soak Value by 2(bT) for each stack of Sunlight "
        "you possess. Reduce your Defense Value by 2(bT). If an Opponent "
        "makes a Clash that would result in an effect to move you on a win, "
        "increase your Dice Score for that Clash by 2(T).\n"
        "(4)-[1/Round]: As an Instant Maneuver during your turn, you stop "
        "being Rooted.\n"
        "(5)-[Automatic]: If you are moved for any reason while Rooted, you "
        "stop being Rooted.\n"
        "(6)-[Triggered, 1/Round]: If you gain a stack of Sunlight while you "
        "are Rooted, regain Life Points equal to your Surgency.",
    grantedResources: [
      GrantedResource(
        name: 'Sunlight',
        maxStacks: 2,
        description: "Gained at Start of Turn if the Light Level is Normal or "
            "higher; spent for Ki Surges / Rooted effects (Arboreal).",
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Bestial Build',
    description:
        "Animals come in a variety of shapes, sizes, and anatomies. Because "
        "of this, some have varying methods of self-defense.\n"
        "(1)-[Passive]: Increase your Racial Life Modifier by 2.\n"
        "(2)-[Option]: Upon gaining this Bestial Trait, choose one of the "
        "following effects:",
    automation: [
      // (1) +2 Racial Life Modifier.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.racialLifeModifier],
        coefficient: 2,
      ),
    ],
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Thick Hide',
            description: '[Passive]: Increase your Soak Value by 2(T) and '
                'your Corporeal Saving Throw by 1(T).',
            automation: [
              RaceTraitAutomation(
                affectedStats: [AffectedStat.soak],
                coefficient: 2,
                tierScaling: TierScaling.current,
              ),
              RaceTraitAutomation(
                affectedStats: [AffectedStat.corporealSave],
                coefficient: 1,
                tierScaling: TierScaling.current,
              ),
            ],
          ),
          TraitOption(
            name: 'Slender',
            description: '[Passive]: Increase your Defense Value and '
                'Impulsive Saving Throw by 1(T).',
            automation: [
              RaceTraitAutomation(
                affectedStats: [
                  AffectedStat.defenseValue,
                  AffectedStat.impulsiveSave,
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
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Blood in the Water',
    description:
        "Sensing your enemy's weaknesses, you grow bolder, hoping for a quick "
        "kill while they're too weak to fight back.\n"
        "(1)-[Passive]: Increase your Wound Rolls against Opponent(s) by "
        "1(bT) for each Health Threshold they are below.\n"
        "(2)-[Triggered, 1/Round]: If you knock an Opponent through a Health "
        "Threshold with one of your Attacking Maneuvers, reduce the Dice "
        "Score of their Steadfast Check by 2.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Burrowing Beast',
    description:
        "With a body built for digging through the soil, you stay safely "
        "hidden underground.\n"
        "(1)-[1/Round, Ruling]: When using the Movement Maneuver while in the "
        "Standard Environment, you can go 'Underground' if the Hardness value "
        "for the ground is 3 or less.\n"
        "(2)-[Passive]: While you are Underground, you have Cover.\n"
        "(3)-[Passive]: While you are in Cover, increase your Defense Value "
        "by 1(bT).\n"
        "(4)-[Passive]: While you are in Cover, your use of the Movement "
        "Maneuver does not trigger the Exploit Maneuver.\n"
        "(5)-[1/Round]: While you are in Cover, you may use the Movement "
        "Maneuver as an Instant Maneuver.\n"
        "(6)-[Automatic/Start of Turn]: You stop being Underground.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Camouflage',
    description:
        "You possess, via some biological means, the ability to hide from "
        "predators and other dangers.\n"
        "(1)-[1/Round]: Spend 1 Action and 8(bT) Ki Points to enter the "
        "Invisible Special State. You can exit the Invisible State at any "
        "time as an Instant Maneuver.\n"
        "(2)-[Automatic/Start of Turn]: If you are in the Invisible State due "
        "to the first effect of Camouflage, reduce your Ki Points by 6(bT).",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Claws',
    description:
        "While some species evolved claws purely for grip while running, "
        "yours evolved them for combat. You can rend your enemy's flesh with "
        "your claws.\n"
        "(1)-[Passive]: Create a Physical Weapon of the Slashing Category "
        "with a Craftsmanship Grade of 2 (you cannot select the Transforming "
        "Weapon Quality for this Weapon). This Weapon becomes Integrated while "
        "you possess this Bestial Trait.\n"
        "(2)-[Triggered, 1/Round]: If you hit an Opponent with your first "
        "Physical Attack after moving into their Melee Range this Combat "
        "Round, make a Clash (Impulsive) against them. If you win, they are "
        "knocked Prone.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Elemental Adaptation',
    description:
        "You are particularly suited to an environment with an elemental "
        "extreme as one of its core features.\n"
        "(1)-[Passive, Ruling]: Upon gaining this Bestial Trait, select a "
        "Profile with 'Elemental' in the name. This Profile is known as your "
        "'Resisted Element'.\n"
        "(2)-[Passive]: Halve all Damage you receive from Attacking Maneuvers "
        "of your Resisted Element.\n"
        "(3)-[Passive]: If your Resisted Element is a Connected Profile of a "
        "Battle Weather, ignore the effects of that Battle Weather.\n"
        "(4)-[Passive]: If your Resisted Element is not a Connected Profile "
        "of a Battle Weather, increase your Racial Life Modifier by 2.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Extra Limbs',
    description:
        "You have more than four limbs, allowing you to perform multiple "
        "complex actions at the same time.\n"
        "(1)-[Passive]: You are in the Multiple Arms Special State.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Fangs',
    description:
        "All animals must eat, but you draw your nourishment from other "
        "animals, and your teeth have evolved to prove it.\n"
        "(1)-[Passive]: Gain access to the Bite Attack Maneuver.\n"
        "(2)-[Option]: Upon gaining this Bestial Trait for the first time, "
        "choose one of the following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Savage',
            description: '[Passive]: Increase the Wound Roll of your Bite '
                'Attack Maneuver by 2(T).',
          ),
          TraitOption(
            name: 'Venomous',
            description: '[Triggered, 2/Encounter]: If you deal Damage to an '
                'Opponent with your Bite Attack Maneuver, make a Corporeal '
                'Clash against that Opponent. If you win, they suffer from '
                'the Poisoned Combat Condition.',
          ),
        ],
      ),
    ],
    trailingText:
        "(3)-[Adventurous]: If you choose the Venomous Option effect of "
        "Fangs, you may spend 2 hours while Adventuring to create a Poison "
        "Vial. You can only do this once during each Adventuring Session.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Grippy Grabbers',
    description:
        "You grip. You grab. You squeeze 'em tightly.\n"
        "(1)-[Passive]: Increase the Dice Score of your Grapple Checks by "
        "1(T).\n"
        "(2)-[Passive]: Increase your Wound Rolls by 1(T) for Physical and "
        "Energy Attacks.\n"
        "(3)-[Triggered, 1/Round]: If you are in a Grapple as the Grappler, "
        "you may target your Opponent as an Instant Maneuver. If you do, make "
        "a Grapple Check against them. If you win, you may either reduce their "
        "Life Points by your Might or use the Launch Maneuver as an "
        "Out-of-Sequence Maneuver.\n"
        "(4)-[Triggered, 1/Encounter]: If you use a Signature Technique of "
        "the Physical or Energy Foundation, you may apply an Energy Charge to "
        "that Attacking Maneuver.",
    automation: [
      // (2) +1(T) Wound Rolls for Physical and Energy Attacks.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.woundPhysical, AffectedStat.woundEnergy],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Impaling Horn',
    description:
        "In combat, you charge headfirst into battle, your horns thrust "
        "forward to damage your enemies and protect you from recoil.\n"
        "(1)-[Passive]: Increase your Wound Rolls for your Physical Attacks "
        "with the Charging Assault Advantage by 2(T).\n"
        "(2)-[Triggered, 1/Round]: If an Opponent attempts to use the "
        "Blockade Maneuver against you, make a Physical Attack through the "
        "Basic Attack Maneuver against them as an Out-of-Sequence Maneuver.\n"
        "(3)-[Triggered, 1/Round]: If you hit an Opponent with a Physical "
        "Attack that has the Charging Assault Advantage, spend 4(bT) Ki "
        "Points to increase the Damage Category by 1.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Land-Based Beast',
    description:
        "Adapted for moving quickly on the ground, your powerful charge sends "
        "enemies scattering out of your way.\n"
        "(1)-[Passive]: While in the Standard Battle Environment, increase "
        "your Defense Value and Speed by 1(bT).\n"
        "(2)-[Passive]: While in the Standard Battle Environment, reduce the "
        "Ki Point Cost to use your Boosted Speed through the Movement "
        "Maneuver by 1(bT).\n"
        "(3)-[Triggered, 1/Round]: When making a Physical Attacking Maneuver, "
        "while in the Standard Environment, target an Opponent within your "
        "Boosted Speed. Before making the Attacking Maneuver, move to an "
        "unoccupied adjacent Square around that Opponent. When you use this "
        "effect, ignore the effects of the Sky Environment for this Attacking "
        "Maneuver.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Regenerating Beast',
    description:
        "Thanks to your unique regenerative powers, even losing a limb isn't "
        "a mortal wound for you. (inspired by the Homebrew from Heilmern of "
        "the DBU Discord)\n"
        "(1)-[Passive]: Increase your Surgency by 1/4 (rounded up) of your "
        "Tenacity Modifier.\n"
        "(2)-[1/Round, 3/Encounter]: If you haven't used a Healing Surge this "
        "Combat Round, then as a Standard Action with an Action Cost of 1 "
        "Action, you may use a Healing Surge. If you do, you cannot use "
        "another Healing Surge for the duration of this Combat Round.\n"
        "(3)-[Triggered/Start of Combat Round]: Regain 2(bT) Life Points for "
        "every Health Threshold you are below.",
    automation: [
      // (1) +1/4 (rounded up) Tenacity Modifier to Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.tenacity,
        fractionDenominator: 4,
        roundUp: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Retractable Limbs',
    description:
        "You have the innate ability to retract vulnerable parts of your "
        "body, making you less prone to injury. (inspired by the Homebrew "
        "from Idios of the DBU Discord)\n"
        "(1)-[Passive]: Increase your Defense Value by 1(bT) while below the "
        "Injured Health Threshold.\n"
        "(2)-[Passive]: Gain access to the Physical Retreat Unique Ability.\n"
        "(3)-[Triggered, 1/Round]: If you successfully avoid or otherwise "
        "take 0 Damage from an Opponent's Called Shot, you may use the Basic "
        "Attack Maneuver as an Out-of-Sequence Maneuver.",
    automation: [
      // (1) +1(bT) Defense Value while below the Injured Health Threshold.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue],
        coefficient: 1,
        tierScaling: TierScaling.base,
        condition: TraitCondition.whileBelowInjuredThreshold,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Return to Heritage',
    description:
        "You have the inherent ability to push away your conscious mind and "
        "act on instinct alone.\n"
        "(1)-[Passive]: While in the Feral State, increase your Combat Rolls "
        "by 1(bT).\n"
        "(2)-[Passive]: Reduce the Stress Test Requirement of the Feral Fist "
        "Enhancement Power by 2.\n"
        "(3)-[Passive]: You have access to Feral Fist Enhancement Power.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Silk Production',
    description:
        "Through something in your body you are able to generate a strong "
        "form of silk that you can use to incapacitate your enemies. "
        "(inspired by the Homebrew from MemeKingDave of the DBU Discord)\n"
        "(1)-[Passive]: Gain access to the Binding Unique Ability.\n"
        "(2)-[Passive]: Increase the Dice Score of any Strike Rolls or Might "
        "Clashes you make through the effects of the Binding Unique Ability "
        "by 1(bT).\n"
        "(3)-[1/Round]: As an Instant Maneuver while you are within a Large "
        "Sphere AoE (centered on the closest Feature to you), you may move to "
        "any other Square within that AoE.\n"
        "(4)-[Triggered, Adventurous]: If you would make a Craft (Apparel) or "
        "Medicine Skill Check, you may spend 2(bT) Ki Points to increase the "
        "Dice Score of that Skill Check by 2.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Sturdy Shell',
    description:
        "Your body is protected by a heavy duty shell. Once your defenses "
        "are broken, however, you become much more agile. (by Idios of the "
        "DBU Discord)\n"
        "(1)-[Passive, Ruling]: Upon gaining this Bestial Trait, gain a "
        "'Shell'. Your Shell is Natural Armor.\n"
        "(2)-[Passive]: Your Shell gains the Dense Armor Apparel Quality. "
        "This Quality does not occupy any Quality Slots.\n"
        "(3)-[Passive]: While your Shell is unbroken, halve any Collision "
        "Damage you would suffer.\n"
        "(4)-[Triggered/Threshold]: You may reduce your Shell's Break Value "
        "by 1 to increase your Dice Score for this Health Threshold's "
        "Steadfast Check by 1.\n"
        "(5)-[Triggered, 1/Encounter]: If your Shell is broken, increase your "
        "Combat rolls by 1/2 of its Apparel Bonus (rounded up) until the end "
        "of your next turn.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Tail',
    description:
        "Born with a long, maneuverable tail, you can use this tail as an "
        "extra hand, or in some cases, as a weapon.\n"
        "(1)-[Passive]: Gain access to the Tail Attack Maneuver.\n"
        "(2)-[Passive]: Increase the Strike Roll of your Tail Attack Maneuver "
        "by 1(T).",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Treacherous Spikes',
    description:
        "With the spines or quills emerging from your body, you defend "
        "passively against any attacks from predators or other foes.\n"
        "(1)-[Passive, Ruling]: Upon gaining this Bestial Trait, gain a "
        "'Quillset'. Your Quillset is Natural Armor.\n"
        "(2)-[Passive]: Your Quillset gains the Spiked Apparel Quality. This "
        "Quality does not occupy any Quality Slots.\n"
        "(3)-[Passive]: While you possess a stack of Power, increase the "
        "Apparel Bonus for your Quillset by 1(T).\n"
        "(4)-[1/Round]: As a Standard Action with an Action Cost of 1 Action, "
        "either select an Opponent who is not at Long Range, or select all "
        "Opponents within a Large Cone AoE (starting from you). Make a Clash "
        "(Corporeal/Impulsive) against the selected Opponent(s). If you win, "
        "reduce their Life Points by 9(bT) and then reduce the Break Value "
        "for your Quillset by 1.\n"
        "(5)-[Triggered, 1/Round]: If you use a Healing Surge, your Quillset "
        "regains 1 Break Value. If the piece of Apparel was broken, it stops "
        "being broken (Break Value goes from 0 to 1).",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Underwater Beast',
    description:
        "Adapted specifically for life under the surface of the water, you "
        "are a great swimmer.\n"
        "(1)-[Passive]: You cannot gain the Suffocating Combat Condition from "
        "the Underwater Battle Environment.\n"
        "(2)-[Passive]: While in the Underwater Battle Environment, increase "
        "your Defense Value and Speed by 1(bT).\n"
        "(3)-[Passive]: While in the Underwater Battle Environment, reduce "
        "the Ki Point Cost to use your Boosted Speed through the Movement "
        "Maneuver by 1(bT).\n"
        "(4)-[1/Round]: If you are in the Underwater Battle Environment, you "
        "can use the Movement Maneuver as an Instant Maneuver.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Weather Resilient',
    description:
        "You are perfectly adapted to a specific type of weather.\n"
        "(1)-[Passive]: Select a Battle Weather. You are immune to the "
        "effects of any Weather Effects from that selected Battle Weather.\n"
        "(2)-[Passive]: While you are within your selected Battle Weather, "
        "increase your Combat Rolls by 1(T).\n"
        "(3)-[1/Encounter]: If you are in your chosen Battle Weather, you may "
        "use a Surge as an Instant Maneuver.",
  ),
  RaceTraitDef(
    race: 'Bestial',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Winged Beast',
    description:
        "Possessing powerful wings that enable you to soar through the skies, "
        "you rise above your enemies and strike from the skies.\n"
        "(1)-[Passive]: Gain access to the Soar Special Maneuver.\n"
        "(2)-[Passive]: While in the Low Sky or High Sky Battle Environment, "
        "increase your Defense Value and Speed by 1(bT).\n"
        "(3)-[Passive]: While in the Low Sky or High Sky Battle Environment, "
        "reduce the Ki Point Cost to use your Boosted Speed through the "
        "Movement Maneuver by 1(bT).\n"
        "(4)-[Triggered, 1/Round]: If you use the Soar Maneuver, you may use "
        "any Standard Maneuver with an Action Cost of 1 Action immediately "
        "afterwards as an Out-of-Sequence Maneuver.",
  ),
];

// ===========================================================================
// MONSTROUS TRAITS
// ===========================================================================
const List<RaceTraitDef> kMonstrousTraits = [
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Adaptive Toughness',
    description:
        "Your defenses grow as your body sustains damage.\n"
        "(1)-[Passive]: Increase your Damage Reduction by 1(T) for every "
        "Health Threshold you are below.\n"
        "(2)-[Triggered, 1/Round]: When you are targeted by an Attacking "
        "Maneuver, double the bonus to your Damage Reduction from the first "
        "effect of Adaptive Toughness for the duration of that Attacking "
        "Maneuver.",
    automation: [
      // (1) +1(T) Damage Reduction per Health Threshold below.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Bloodlust',
    description:
        "Your monstrous nature is predatory, driving you to rend flesh and "
        "sate an unending hunger.\n"
        "(1)-[Triggered, Resource]: When you knock an Opponent through a "
        "Health Threshold or Defeat a Minion, gain a stack of Bloodlust (max. "
        "3). When you Defeat an Opponent (except a Minion), gain 3 stacks of "
        "Bloodlust.\n"
        "(2)-[Passive]: Each stack of Bloodlust increases your Strike and "
        "Wound Rolls by 1(T).\n"
        "(3)-[Automatic]: You lose a stack of Bloodlust at the end of any "
        "Combat Round you did not successfully trigger the first effect of "
        "Bloodlust.",
    grantedResources: [
      GrantedResource(
        name: 'Bloodlust',
        maxStacks: 3,
        description: "Gained on knocking an Opponent through a Threshold / "
            "Defeating; each stack +1(T) Strike and Wound Rolls (Bloodlust).",
      ),
    ],
    automation: [
      // (2) +1(T) Strike and Wound Rolls per stack of Bloodlust.
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.strike,
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Bloodlust',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Brood Parent',
    description:
        "You are able to split yourself or otherwise reproduce alone, "
        "allowing you to swarm the battlefield with your clones or "
        "offspring.\n"
        "(1)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 "
        "Action and a Ki Point Cost of 5(T), create a Duplicate Minion. Your "
        "Duplicate Minion's base Size Category is 1 Size Category smaller than "
        "yours.\n"
        "(2)-[Multi-Option/2]: Upon gaining this Monstrous Trait, select two "
        "of the following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Choose 2',
        maxChoices: 2,
        options: [
          TraitOption(
            name: 'Draining Minions',
            description: '[Passive]: Your Minions created through the first '
                'effect of Brood Parent gain access to the Power Drain '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Exploiting Minions',
            description: '[Triggered, 1/Round]: When one of your Minions '
                'created through the first effect of Brood Parent are '
                'Defeated, you may target a Square they occupied with an '
                'Attacking Maneuver of the Clearing Profile as an '
                'Out-of-Sequence Maneuver.',
          ),
          TraitOption(
            name: 'Mini Minions',
            description: '[Passive]: When creating a Minion through the first '
                'effect of Brood Parent, you may choose to reduce their Size '
                'Category by up to 2 more Categories. If you do, for each '
                'reduction, reduce their Soak Value by an additional 1(T) and '
                'increase their Defense Value by 1(T).',
          ),
          TraitOption(
            name: 'Many Minions',
            description: "[Passive]: The first effect of Brood Parent's "
                'Keyword changes from 1/Round to 3/Round.',
          ),
          TraitOption(
            name: 'Consumable Minions',
            description: '[1/Round]: As an Instant Maneuver, you may target '
                'any number of your Minions created through the first effect '
                'of Brood Parent and Defeat them. You regain Ki Points equal '
                'to 1/4 (rounded up) of their collected Ki Points. You cannot '
                'target a Minion with this effect if it was created during '
                'this Combat Round.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Dissipating Dodge',
    description:
        "You have the uncanny ability to move around the battlefield as if "
        "you were teleporting.\n"
        "(1)-[1/Round]: As an Instant Maneuver, you may spend 2(bT) Ki Points "
        "to select an unoccupied Square within 6 Squares of you and place "
        "yourself on that Square. If that Square is within the Melee Range of "
        "an Opponent, make an Impulsive Clash against them. If you win, they "
        "suffer from the Guard Down Combat Condition against your next "
        "Attacking Maneuver until the end of your turn.\n"
        "(2)-[Triggered]: If you are targeted by an Attacking Maneuver, you "
        "may spend 4(bT) Ki Points to reduce your Size Category to Nano for "
        "the sake of calculating the bonus/penalty to Defense Value from your "
        "Size Category for the duration of that Attacking Maneuver. You "
        "cannot use this effect if you are suffering from the Guard Down or "
        "Impediment Combat Condition(s).",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Elemental Assault',
    description:
        "Your species is intrinsically tied to an element of the natural "
        "world, and as such, can produce that element at will. (Partially "
        "inspired by the homebrew of Dunkaccino in the DBU Discord).\n"
        "(1)-[Passive]: Upon gaining this Trait, select a Profile with "
        "'Elemental' in the name to become your Favored Element.\n"
        "(2)-[Option]: Upon gaining this Trait, select one of the following "
        "effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Counter Elemental',
            description: '[Passive, Ruling]: Increase the Wound Rolls of your '
                'Favored Element by 3(T), but select an additional Profile '
                "with 'Elemental' in the name, except the one chosen for the "
                'first effect of Elemental Assault. This Profile becomes your '
                "'Vulnerability'. If you are hit by an Attacking Maneuver of "
                'your Vulnerability, increase the Damage Category of that '
                'Attacking Maneuver by 1 Category for the sake of your Damage '
                'Calculation.',
          ),
          TraitOption(
            name: 'Elemental Infusion',
            description: '[Triggered]: When you use a Physical Attack or '
                'Energy Attack, you may apply the Multi-Profile Super Profile '
                'to that Attacking Maneuver. If you do, you must select your '
                'Favored Element for the effects of Multi-Profile.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Extension Attack',
    description:
        "Whether by means of extended hair, limbs, bandages or even a "
        "prehensile tongue, you possess a means of attacking and binding up "
        "an opponent from a distance. (Partially inspired by the Homebrew of "
        "Comeau in the DBU Discord)\n"
        "(1)-[Passive]: When making the Grapple Maneuver against an Opponent "
        "or maintaining it against an Opponent, you may increase your Melee "
        "Range by 3 Squares for the duration of that Maneuver.\n"
        "(2)-[Passive]: While you are Grappling an Opponent who is 3 or more "
        "Squares away from you, you do not suffer the Guard Down Condition.\n"
        "(3)-[Option]: Upon gaining this Trait, select and apply one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Extending Weapon',
            description: '[Passive, Ruling]: Upon gaining this Monstrous '
                'Trait, create and Integrate a Physical Weapon with the '
                'Extending and Hidden Qualities. This becomes known as your '
                "'Prehensile Weapon'.",
          ),
          TraitOption(
            name: 'Mystic Attack',
            description: '[Triggered]: When making any type of Physical '
                'Attacking Maneuver, you may increase your Melee Range by +3 '
                'Squares for the duration of that Maneuver. Upon hitting a '
                'Character, you may move that Character any number of Squares '
                'up to your current Melee Range (including the bonus from this '
                'effect) in any direction.',
          ),
        ],
      ),
    ],
    trailingText:
        "(4)-[Choice]: Depending on your choice for the Option effect of this "
        "Trait, apply the following effects:\n"
        "• Extending Weapon [1/Round]: As an Instant Maneuver, you may apply "
        "the Telekinetic and Extending Qualities to a Weapon you are wielding "
        "that does not currently possess them (this does not count towards "
        "the maximum number of Qualities that Weapon can possess). While "
        "benefitting from those Qualities, ignore all other effects from this "
        "Trait. You may remove the Telekinetic and Extending Qualities given "
        "to a Weapon through this effect as an Instant Maneuver.\n"
        "• Mystic Attack [Passive]: Ignore Cover for Opponents who are not "
        "Hidden from you and increase the Wound Rolls of your Physical "
        "Attacking Maneuvers against Opponents not on an adjacent Square to "
        "you by 2(T).",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Feast',
    description:
        "Absorbing the life essence of your enemies, you revitalize "
        "yourself.\n"
        "(1)-[Triggered]: If you deal Damage to an Opponent with an Attacking "
        "Maneuver made through the effects of the Bite Maneuver, regain Life "
        "Points equal to 1/2 of the Damage dealt.\n"
        "(2)-[Passive]: You gain access to the Draining Attack Modifier "
        "Maneuver, the Bite Attack Special Maneuver, and the Drain Life "
        "Advantage.\n"
        "(3)-[Triggered]: When you use the Bite Maneuver or apply the effects "
        "of the Draining Attack Maneuver to an Attacking Maneuver, you may "
        "reduce your Life Points by up to 3(bT) to increase the Wound Roll by "
        "twice the amount of Life Points lost.",
    trailingText:
        "Drain Life Advantage — TP Cost: 8. Requirement: Physical Attack, "
        "access to the Draining Attack Maneuver. Effect: You may use the "
        "Draining Attack Maneuver in response to the Signature Technique "
        "Maneuver for this Signature Technique.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Innate Weaponry',
    description:
        "Able to produce a weapon from your very flesh, you are never left "
        "without a weapon at hand, making you always deadly.\n"
        "(1)-[2/Round]: As a Standard Maneuver with an Action Cost of 1 "
        "Action, create a Weapon with a Craftsmanship Grade of 4.\n"
        "(2)-[Passive]: Increase the Strike and Wound Rolls of your Armed "
        "Attacks by 1(T).",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Light Consumption',
    description:
        "From a planet consumed by darkness, you have the unnatural ability "
        "to absorb light and gain nutrition from it.\n"
        "(1)-[1/Round, Resource]: As a Standard Action with an Action Cost of "
        "2 Actions, target an Opponent who meets any conditions from the list "
        "below. Make a Clash (Corporeal) against that Opponent. If you win, "
        "apply the effects listed below:\n"
        "• In a Transformation with the Light Dependent Aspect: The targeted "
        "Opponent exits the Transformation with the Light Dependent Aspect "
        "(unless that Transformation has the Dedicated Aspect), but they do "
        "not gain Stress Exhaustion. Gain a number of Light Stacks equal to "
        "that Transformation's Tier of Power Requirement plus 1/2 (rounded "
        "up) of that Opponent's Tier of Power.\n"
        "• Has any stacks of Power: The targeted Opponent loses their stacks "
        "of Power. Gain a number of Light Stacks equal to 1/2 (rounded up) of "
        "that Opponent's Tier of Power for each stack of Power they had "
        "possessed.\n"
        "(2)-[Triggered, 1/Round]: As a Counter Action with an Action Cost of "
        "1 Counter Action, when you are targeted by an Attacking Maneuver "
        "that is of the Energy Type or the Light Profile, you can make a "
        "Might Clash against that attacking Character. If you win, you take "
        "no Damage from that Attacking Maneuver, but instead the attacking "
        "Character makes an Urgent Wound Roll for their Attacking Maneuver as "
        "if you were hit, and you regain Ki Points equal to 1/2 of the Dice "
        "Score. For every 1/5 of your Maximum Ki Point Pool regained as Ki "
        "Points, gain 1(bT) Light Stack(s).\n"
        "(3)-[Automatic/Start of Combat Round]: Regain Ki Points equal to "
        "your amount of Light Stacks, then halve your number of Light "
        "Stacks.\n"
        "(4)-[Automatic]: At the end of the Combat Round, reduce your Life "
        "Points by your number of Light Stacks. If your number of Light "
        "Stacks exceeds 2(bT), then reduce your Life Points by 1/5 of your "
        "Maximum Life Points.",
    grantedResources: [
      GrantedResource(
        name: 'Light Stack',
        maxStacks: 20,
        description: "Gained by consuming light/Power; converts to Ki at "
            "Start of Round, but drains Life at end of Round (Light "
            "Consumption). No hard cap on the site — generous tracker cap.",
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Petrification Plating',
    description:
        "Your body is weighed down by some form of natural armor that you "
        "are able to shed to protect yourself.\n"
        "(1)-[Triggered/Start of Combat Encounter, Triggered/Power]: Gain a "
        "Plate (max. 3).\n"
        "(2)-[Passive]: For each Plate you possess: gain 1(bT) Damage "
        "Reduction, reduce the amount of Squares you move through by any "
        "means by 1(bT), and reduce the Combat Rolls of any Opponent you are "
        "grappling as the Grappler by 1(bT).\n"
        "(3)-[Triggered, 1/Round]: If you are hit by an Attacking Maneuver, "
        "you can spend 1 Plate to increase your Damage Reduction by 5(bT) for "
        "the duration of that Attacking Maneuver.\n"
        "(4)-[1/Encounter]: As a Standard Action with an Action Cost of 1 "
        "Action, you can remove all of your Plates. Increase your Combat "
        "Rolls by 1(T) for every Plate removed until the start of your next "
        "turn.",
    grantedResources: [
      GrantedResource(
        name: 'Plate',
        maxStacks: 3,
        description: "Gained at Start of Encounter / on Power; each Plate "
            "+1(bT) Damage Reduction (Petrification Plating).",
      ),
    ],
    automation: [
      // (2) +1(bT) Damage Reduction per Plate.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: 1,
        tierScaling: TierScaling.base,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Plate',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Ravaging Charger',
    description:
        "Your monstrous body is built to charge opponents, slamming into "
        "them with your weight and momentum.\n"
        "(1)-[Passive]: Increase your Speeds by 1(T).\n"
        "(2)-[Passive]: Increase the Strike Rolls of your Attacking Maneuvers "
        "with the Charging Assault Advantage by 1(T).\n"
        "(3)-[Triggered, 1/Round]: If you hit an Opponent with an Attacking "
        "Maneuver that possesses the Charging Assault Advantage, make a Clash "
        "(Impulsive vs Impulsive/Corporeal) against them. If you win, apply "
        "1/2 of your maximum Boosted Speed to the Wound Roll of that "
        "Attacking Maneuver.",
    automation: [
      // (1) +1(T) Speeds (Normal and Boosted).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.speedNormal, AffectedStat.speedBoosted],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Shedding Transformation',
    description:
        "Your monstrous power emerges when you would otherwise be defeated.\n"
        "(1)-[Passive]: Double the amount of Life Points you gain from Legend "
        "Realized.\n"
        "(2)-[Triggered/Defeated]: Set your Life Points to 1 and then, you "
        "may either: use the Transformation Maneuver as an Out-of-Sequence "
        "Maneuver, or trigger Legend Realized.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Slimy Consistency',
    description:
        "Your body's unusual physiology makes you unnaturally slimy, allowing "
        "you to protect yourself in unusual ways.\n"
        "(1)-[Passive, Ruling]: As a Standard Action with an Action Cost of 1 "
        "Action, you may 'Store' any Basic Items, Accessories, pieces of "
        "Apparel, or Weapons. While they are Stored, they cannot be targeted "
        "by the Snatch Maneuver.\n"
        "(2)-[2/Round]: As an Instant Maneuver, you may remove any Stored "
        "Items and gain access to them again, or equip any Stored "
        "Weapons/Apparel/Accessories.\n"
        "(3)-[Triggered, 1/Round]: If you are hit by a Physical Attack that "
        "does not deal Damage, you may either: Use the Grapple Maneuver as an "
        "Out-of-Sequence Maneuver against the Opponent who used the Attacking "
        "Maneuver. Use the Basic Attack Maneuver as an Out-of-Sequence "
        "Maneuver against the Opponent who used the Attacking Maneuver. If "
        "the Physical Attack was an Armed Attack, make a Might Clash against "
        "the Opponent who used the Attacking Maneuver. If you win, you may "
        "Store their Weapon inside of your body, un-equipping it from them.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Spectral Monster',
    description:
        "You have the ability to shift your body to an incorporeal state, "
        "allowing you to pass through objects and avoid attacks. (Inspired by "
        "the Homebrew from Idios in the DBU Discord)\n"
        "(1)-[1/Round]: As a Standard Action with an Action Cost of 1 Action "
        "and a Ki Point Cost of 6(bT), enter the Incorporeal Special State.\n"
        "(2)-[1/Round]: As an Instant Maneuver during your turn, you can exit "
        "the Incorporeal Special State.\n"
        "(3)-[Triggered, 1/Round]: If you are not in the Incorporeal State "
        "and are targeted by an Attacking Maneuver, you can spend a Counter "
        "Action and 10(bT) Ki Points to enter the Incorporeal State.\n"
        "(4)-[Automatic/Start of Turn]: If you are in the Incorporeal State "
        "due to the effects of Spectral Monster, spend 6(bT) Ki Points.",
    trailingText:
        "Incorporeal State:\n"
        "(1)-[Triggered]: If any Attacking Maneuver you are targeted by "
        "possesses a Wound Roll whose Dice Score is less than 1/4 of your "
        "Maximum Life Points, you receive no Damage from that Attacking "
        "Maneuver.\n"
        "(2)-[Automatic]: If you suffer Damage from an Attacking Maneuver, "
        "leave the Incorporeal State. If you exit the Incorporeal state "
        "through this effect, you may not enter it again until the end of "
        "your next turn.\n"
        "(3)-[Passive]: Increase your Grapple Checks as the Grappled by "
        "2(T).\n"
        "(4)-[Passive]: You may not use any Attacking Maneuvers.\n"
        "(5)-[Passive]: For the sake of Collision, the Square you occupy is "
        "always considered to be empty. Additionally, you may pass through "
        "Characters and Features during any movement without colliding with "
        "them.\n"
        "(6)-[Passive]: You cannot suffer from Collision Damage.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Super Elastic Body',
    description:
        "Your flesh is stretchy, squishy, and otherwise impermeable to "
        "conventional forms of attack – allowing you to easily reflect and "
        "repel kinetic assaults. (by Comeau in the DBU Discord)\n"
        "(1)-[Passive]: Increase your Damage Reduction against Physical and "
        "Energy Attacks by 2(T).\n"
        "(2)-[Triggered]: If you would use the Reflect Maneuver, increase "
        "your Strike Rolls by 1(T) for the duration of that Maneuver.\n"
        "(3)-[Triggered, 1/Round]: If you avoid an Attacking Maneuver through "
        "the effects of the Parry option of the Defend Maneuver, you may use "
        "the Launch Maneuver as an Out-of-Sequence Maneuver against the "
        "attacking Character as if they were in a Grapple with you as the "
        "Grappler.\n"
        "(4)-[Triggered, 1/Round]: If you would use the Direct Hit option of "
        "the Defend Maneuver against an Opponent's Physical or Energy Attack "
        "and receive no Damage while not using the second effect of the "
        "Shield Weapon Category, you may treat it as though you avoided that "
        "Attacking Maneuver through the effect of the Parry option of the "
        "Defend Maneuver instead.\n"
        "(5)-[Passive]: While you possess any stacks of the Slowed Combat "
        "Condition or you are currently suffering the effects of the Freezing "
        "Climate Battle Weather, ignore all other effects of this Trait.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Terrifying Visage',
    description:
        "Your appearance is grotesque or otherworldly, horrifying all who "
        "lay eyes upon you.\n"
        "(1)-[Passive]: Increase the Natural Result of your Intimidation "
        "Skill Checks by 1.\n"
        "(2)-[Passive]: Gain access to the Terrify Maneuver if you do not "
        "possess it.\n"
        "(3)-[Triggered, 1/Round]: If you win a Clash using the Terrify "
        "Maneuver, you may use the Power Up Maneuver or Transformation "
        "Maneuver as an Out-of-Sequence Maneuver.",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Unique Monstrosity',
    description:
        "Your mutated physique is so unique that you are able to perform "
        "techniques that few others can.\n"
        "(1)-[Passive]: Upon gaining this Trait, select any Unique Ability "
        "with a TP Cost of 20 or less. You must still meet any Prerequisites, "
        "except those of a listed Attribute Score and if the listed Skill "
        "Ranks required are 2 or less. You gain access to that Unique Ability "
        "while you possess this Trait.\n"
        "(2)-[Passive]: Reduce the Ki Point Cost of the Unique Ability you "
        "chose for the first effect of Unique Monstrosity by 2(T).",
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Unrelenting',
    description:
        "Thanks to your monstrous power, you continue to get back up no "
        "matter how many times you've been knocked down.\n"
        "(1)-[Passive]: Increase the Dice Score of your Steadfast Checks by "
        "1.\n"
        "(2)-[Passive]: For each Health Threshold you are below, increase "
        "your Soak Value and Surgency by 1(T).\n"
        "(3)-[Triggered/Defeated]: Use a Healing Surge as an Out-of-Sequence "
        "Maneuver.",
    automation: [
      // (2) +1(T) Soak Value and Surgency per Health Threshold below.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak, AffectedStat.surgency],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Monstrous',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Weather Environment',
    description:
        "Your monstrous body is adapted to be particularly effective in a "
        "specific environmental condition.\n"
        "(1)-[Option]: Upon gaining access to this Monster Trait, select one "
        "of the following:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Battle Weather',
            description: '[Passive]: Choose a Battle Weather upon gaining this '
                'effect. You do not suffer the effects of your chosen Battle '
                'Weather.\n'
                '[Choice — Passive]: While in your chosen Battle Weather, '
                'increase your Combat Rolls by 1(T).',
          ),
          TraitOption(
            name: 'Light',
            description: '[Passive]: Ignore the penalties from Light Levels.\n'
                '[Choice — Passive]: While the Light Level is not Normal, '
                'increase your Wound Rolls by 3(T).',
          ),
        ],
      ),
    ],
  ),
];
