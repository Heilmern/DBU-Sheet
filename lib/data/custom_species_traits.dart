/// custom_species_traits.dart
/// ---------------------------------------------------------------------------
/// The **Custom Species Racial Traits** catalogue (Custom Species page),
/// verbatim from the site. Custom Species is a ruleset, not a Race: a player
/// picks 5 Racial Traits, designates **2 as Primary** (they gain their
/// `[Twinned]` effects) and 3 as **Secondary** (base effects only). Twinning is
/// NOT a separate doubled trait — each Trait lists its base effects plus
/// `[Twinned]`-marked ones inline; being Primary unlocks the marked ones.
///
/// Each Trait is a `RaceTraitDef` (race 'Custom Species'). Numeric always-on
/// self-buffs are automated via `RaceTraitAutomation`; a `[Twinned]` effect's
/// automation carries `twinned: true` so it only applies for a Primary Trait
/// (see `CharacterCalculator.customSpeciesActiveTraits`, which strips Twinned
/// automation from a Secondary Trait's copy via `RaceTraitDef.baseOnly`).
/// `baseOnly` also strips the `[Twinned]`-keyword effect **lines** from the
/// verbatim text, so a Secondary Trait's card shows only the effects it
/// actually possesses — the Information tab renders that stripped copy.
/// Situational / "set to maximum" / Resource / battlefield effects stay as
/// verbatim reference text, as elsewhere.
///
/// **Flaw Traits** (max. 2) are the 17 negative Traits at the end of the page;
/// they carry no `[Twinned]` effects and are authored with
/// `RaceTraitTier.secondary` (see `isCustomSpeciesFlaw`) — every one of the 41
/// non-Flaw Traits is `primary`, since Primary/Secondary for a Custom Species
/// is the per-character Twinning choice, not a catalogue property. Each Flaw
/// taken grants a `FlawCompensation` pick (Racial Life Modifier +2 or Skill
/// Ranks +1), recorded on `Character.customFlawCompensation`.
///
/// The Custom Species baseline stat line (Attribute Score Increase 2/2/1,
/// Racial Life Modifier +3, one chosen Saving Throw, 2 Skill Ranks) lives on
/// the `RaceDef('Custom Species')` entry in `dbu_rules.dart`, like every other
/// Race — it is NOT freeform.
library;

import 'dbu_rules.dart';
import 'race_traits.dart';

const List<RaceTraitDef> kDbuCustomSpeciesTraits = [
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Abnormal Anatomy',
    description: 'Due to some quirk of biology, you do not possess an easily '
        'recognizable anatomical structure, making it hard for opponents to '
        'properly identify how to hurt you.\n'
        '(1)-[Passive]: You are Unnatural.\n'
        '(2)-[Passive]: Increase your Damage Reduction by 1(T) and halve any '
        'Collision Damage you receive.\n'
        '(3)-[Passive]: Reduce the Damage Category of all Attacking Maneuvers '
        'that hit you by 1 Category for the sake of your Damage calculation. '
        'This effect does not apply to Attacking Maneuvers with 3+ Energy '
        'Charges.\n'
        '(4)-[Passive, Twinned]: Reduce the Damage Category of all Called '
        'Shots that target you by 1 Category for the sake of your Damage '
        'calculation.\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you use the Direct Hit or Guard '
        'options of the Defend Maneuver, you may also increase your Damage '
        'Reduction by 1/2 of its total value for the duration of that '
        'Attacking Maneuver.',
    automation: [
      // (2) +1(T) Damage Reduction (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Arcane Adept',
    description: 'Excelling in the magical arts, your species has grasped the '
        'secrets of the universe and learned to twist them to manipulate '
        'reality.\n'
        '(1)-[Triggered, 1/Round]: When making a Magical Attack, you may '
        'either: Increase the Wound Roll by 3(T); or add a rank of an '
        'applicable Advantage to that instance of the Attacking Maneuver with '
        'a TP Cost of 10 or less.\n'
        '(2)-[Passive]: Reduce the Technique Point Cost of any Magical Unique '
        'Abilities by 2.\n'
        '(3)-[Passive, Twinned]: You may use your Magic Modifier instead of '
        'your Force Modifier when calculating Surgency (see - Surges).\n'
        '(4)-[Passive, Twinned]: Increase the Wound Roll of any Attacking '
        'Maneuver from the Mega Flare Profile by 1(T) for each Energy Charge '
        'applied to it.\n'
        '(5)-[Triggered, 1/Encounter, Twinned]: When using the Signature '
        'Technique Maneuver to use a Magic Attack, you may ignore the effects '
        'of all Advantages and Disadvantages on that Signature Technique for '
        'the duration of that Attacking Maneuver. If you do, increase the '
        "Wound Roll of the Signature Technique by 1/2 of that Signature "
        "Technique's TP Cost.",
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Armed Affinity',
    description: 'Trained from a young age to wield a weapon, you are more '
        'adept with weapons than most.\n'
        '(1)-[Passive]: You gain the Weapon Specialist Talent, and when '
        'creating any type of Signature Technique, you may add the Weapon '
        'Assisted Advantage to that Signature Technique without spending '
        'Technique Points.\n'
        '(2)-[Passive]: Reduce the Critical Target for the Strike and Wound '
        'Rolls of your Armed Attacks by 1.\n'
        '(3)-[Passive, Twinned]: Increase the Strike Rolls for your Armed '
        'Attacks by 1(T).\n'
        '(4)-[Triggered, Twinned]: If you score a Critical Result on the '
        'Strike or Wound Roll for an Armed Attack, increase the Wound Roll for '
        'that Attacking Maneuver by 2(T).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Armored Exoskeleton',
    description: 'You possess a hardened shell of some kind that functions '
        'like armor.\n'
        "(1)-[Passive, Ruling]: Upon gaining this Trait, create an "
        "'Exoskeleton'. Your Exoskeleton is Natural Armor (see - Natural "
        "Armor).\n"
        '(2)-[Passive]: Upon gaining this Trait, select up to 2 Quality Slots '
        'worth of applicable Qualities. Your Exoskeleton gains those Qualities '
        'without them occupying any Quality Slots.\n'
        '(3)-[Passive]: While your Exoskeleton has a Break Value of 2+, '
        'increase your Damage Reduction by 1(bT).\n'
        '(4)-[Triggered, 1/Round]: If you use a Healing Surge, your Exoskeleton '
        'regains 1 Break Value. If the piece of Apparel was broken, it stops '
        'being broken (Break Value goes from 0 to 1).\n'
        '(5)-[Passive, Twinned]: Increase your Impulsive and Corporeal Saving '
        'Throws by 1(T).\n'
        '(6)-[Triggered, 1/Round, Twinned]: If you use the Direct Hit or Guard '
        'options of the Defend Maneuver, double your Apparel Bonus for the '
        'duration of that Maneuver.\n'
        '(7)-[Triggered, 1/Encounter, Twinned]: If you are hit by an Attacking '
        'Maneuver, you may set the Damage Category for that Attacking Maneuver '
        'to Standard.',
    automation: [
      // (5)-[Twinned]: +1(T) Impulsive and Corporeal Saving Throws.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.impulsiveSave, AffectedStat.corporealSave],
        coefficient: 1,
        tierScaling: TierScaling.current,
        twinned: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Blazing Speed',
    description: 'Graced with extreme speed, your species is the fastest in '
        'the universe.\n'
        '(1)-[Passive]: Increase your Normal and Boosted Speeds and Defense '
        'Value by 1(T) and 2(T) respectively.\n'
        '(2)-[Triggered, 1/Round]: If you use the Rapid Movement effect of the '
        'Movement Maneuver, increase your Wound Rolls by 2(T) until the end of '
        'your turn.\n'
        '(3)-[Triggered, 1/Round, Twinned]: After concluding a Movement '
        'Maneuver on an adjacent Square to an Opponent, you may use the Basic '
        'Attack Maneuver as an Out-of-Sequence Maneuver. If you do, you must '
        'target an Opponent that is on an adjacent Square for this Attacking '
        'Maneuver.\n'
        '(4)-[Triggered/Start of Turn, Twinned]: Use the Movement Maneuver as '
        'an Out-of-Sequence Maneuver.',
    automation: [
      // (1) +1(T) Normal & Boosted Speeds.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.speedNormal, AffectedStat.speedBoosted],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
      // (1) +2(T) Defense Value.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue],
        coefficient: 2,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Dense Body',
    description: 'Far more massive than your size would suggest, your body is '
        'extremely durable.\n'
        '(1)-[Passive]: Increase your Soak Value by 1(T).\n'
        '(2)-[Passive]: You count as 1 Size Category larger for: calculating '
        'Punching Down when targeted by an Attacking Maneuver; calculating '
        'Gigantic Grip (as both the Grappler and Grappled).\n'
        '(3)-[Passive]: Increase the reduction to your Movement from the '
        'Sudden Stop Maneuver by 1/2 of your Tenacity Modifier.\n'
        '(4)-[Triggered, 1/Round]: If you are moved by an Opponent\'s effect, '
        'you may use the Sudden Stop Maneuver in response to that movement '
        'without spending a Counter Action.\n'
        '(5)-[Passive, Twinned]: Double the increase to your Soak Value from '
        'the first effect of Dense Body while you are in the Healthy Health '
        'Threshold.\n'
        '(6)-[Passive, Twinned]: Increase your Dice Score when making a Might '
        'Clash as the target of the Pin Maneuver by 2(T).\n'
        '(7)-[Triggered, 1/Round, Twinned]: If you would receive Collision '
        'Damage, you can reduce that Collision Damage to 0.',
    automation: [
      // (1) +1(T) Soak Value (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Alternate Scale',
    description: 'Unlike most species, you are exceptionally large or small.\n'
        '(1)-[Option]: At Character Creation, choose one of the following '
        'effects: Big [Passive]: Your base Size Category is Enormous. Little '
        '[Passive]: Your base Size Category is Tiny.\n'
        '(2)-[Choice]: Depending on your choice for the Option effect: Big '
        '[Passive]: If your Size Category is greater than Large, for '
        'calculating the bonus/penalty to your Defense Value from your Size '
        "Category, and for the effects of your Opponent's Punching Up, you are "
        'considered to be of the Large Size Category. Little [Passive]: If '
        'your Size Category is smaller than Small, for calculating the '
        'bonus/penalty to your Soak Value from your Size Category, and for the '
        "effects of your Opponent's Punching Down, you are considered to be of "
        'the Small Size Category.\n'
        '(3)-[Choice, Twinned]: Big [Passive]: Your base Size Category is '
        'Gigantic instead of Enormous. Little [Passive]: Your base Size '
        'Category is Nano instead of Tiny.\n'
        '(4)-[Choice, Twinned]: Big [Passive]: Increase your Strike Rolls by '
        '1(T). Little [Passive]: Increase your Wound Rolls by 2(T).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Attackers Tactics',
    description: 'As a tactically-minded species, you have a strong affinity '
        'with offensive strategies.\n'
        '(1)-[Triggered/Start of Combat Round, Resource]: Gain 1 Tactic Point '
        '(max. 4).\n'
        '(2)-[Passive]: When you or an Ally use an Attacking Maneuver, you can '
        'spend up to 2 Tactic Points to increase their Combat Rolls for the '
        'duration of that Maneuver by 1(T) for each Tactic Point spent.\n'
        '(3)-[Triggered]: When you or an Ally hit an Opponent with an '
        'Attacking Maneuver, you can spend up to 2 Tactic Points to increase '
        'the Wound Roll of that Attacking Maneuver by 2(T) for each Tactic '
        'Point spent.\n'
        "(4)-[Passive, Twinned]: Gain access to the Defender's Tactics Trait. "
        "If you already have access to Defender's Tactics, then increase the "
        'amount of Tactic Points you gain from the first effect of '
        "Attacker's Tactics by 1.",
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Big Personality',
    description: "Known for your species' powerful charismatic presence, you "
        'are a force of personality.\n'
        '(1)-[Passive]: Apply your Racial Saving Throw Bonus to Morale as well '
        'as what you selected for this Race. If you already selected Morale, '
        'then instead pick any other Saving Throw that your Racial Saving '
        'Throw Bonus is not already being applied to.\n'
        '(2)-[Passive]: While Personality has the highest Attribute Score '
        'amongst your Attributes, increase all of your Combat Rolls and '
        'Initiative by 1(bT).\n'
        '(3)-[Triggered, 1/Round]: When you make an Attacking Maneuver against '
        'an Opponent(s), spend 3(bT) Ki Points to make a Clash (Morale) '
        'against them. If you win, they have Guard Down against this Attacking '
        'Maneuver.\n'
        '(4)-[Passive, Twinned]: Increase your Personality Modifier by 1(T).\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you use the Hype Maneuver, '
        'increase your Combat Rolls by 1(T) until the end of your turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Brute Force',
    description: 'Focused on putting all your power into your attacks and '
        'leaving no room in your mind for techniques, your savagery on the '
        'battlefield is known by all.\n'
        '(1)-[Passive]: Increase the Ki Point Cost for all of your Attacking '
        'Maneuvers by 2(T), but increase their Wound Rolls by 4(T).\n'
        '(3)-[Triggered/Start of Turn]: You exit the Feral State.\n'
        '(4)-[Passive, Twinned]: While in the Feral State, any Attacking '
        'Maneuvers made through the Basic Attack Maneuver have a rank of Power '
        'Shot applied to them.\n'
        '(5)-[Triggered, 1/Encounter, Twinned]: Upon leaving the Feral State '
        'through the 3rd effect of Brute Force, you may use the Energy Charge '
        'Maneuver. If you declared a Signature Technique for this use of the '
        'Energy Charge Maneuver, you may apply an additional Energy Charge to '
        'that Attacking Maneuver if you use it during this Turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Combative Organism',
    description: 'Physically adapted to a life of battle, your body easily '
        'adjusts to perform the tasks you require in combat.\n'
        '(1)-[Multi-Option/2]: Upon gaining this Trait, choose two of the '
        'following effects — you do not benefit from them except through the '
        'second effect of Combative Organism: Striking Stance [Passive]: '
        'Increase your Strike Rolls by 1(T). Double this bonus if you are '
        'below the Injured Health Threshold. Wounding Stance [Passive]: '
        'Increase your Wound Rolls by 2(T). Double this bonus if you are below '
        'the Injured Health Threshold. Dodging Stance [Passive]: Increase your '
        'Dodge Rolls by 1(T). Double this bonus if you are below the Injured '
        'Health Threshold. Pursuing Stance [Passive]: Increase your Speed by '
        '2(T). Double this bonus if you are below the Injured Health '
        'Threshold.\n'
        '(2)-[Triggered/Start of Turn]: Select one of the effects you chose '
        'through the first effect of this Trait; you benefit from that effect '
        'until the start of your next turn.\n'
        '(3)-[Passive, Twinned]: Through the second effect of Combative '
        'Organism, you can choose any effect from the Multi-Option effect, '
        'even if you did not choose them.\n'
        '(4)-[Triggered/Power, 1/Round, Twinned]: Select an additional effect '
        'from the first effect of Combative Organism to benefit from until the '
        'start of your next turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Death Defier',
    description: 'At your strongest just before death, your species refuses '
        'to go down without a fight.\n'
        '(1)-[Triggered/Defeated]: Gain the Slowed Combat Condition and enter '
        'the Undying State until the end of your next turn.\n'
        '(2)-[Passive]: While in the Undying State, increase your Wound Rolls '
        'by 2(T).\n'
        '(3)-[Passive, Twinned]: Ignore the 3rd effect of the Undying State.\n'
        '(4)-[Triggered/Undying, Twinned]: Use a Healing Surge as an '
        'Out-of-Sequence Maneuver.',
    automation: [
      // (2) +2(T) Wound Rolls while the tracked Undying State is active.
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 2,
        tierScaling: TierScaling.current,
        condition: TraitCondition.whileNamedStateActive,
        conditionStateName: 'Undying',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: "Defender's Tactics",
    description: 'Above and beyond your strategic prowess, your species is '
        'known specifically for their ability to hold the line against '
        'assault.\n'
        '(1)-[Triggered/Start of Combat Round, Resource]: Gain 1 Tactic Point '
        '(max. 4).\n'
        '(2)-[Passive]: When you or an Ally are targeted by an Attacking '
        'Maneuver, you can spend up to 2 Tactic Points to increase their '
        'Combat Rolls for the duration of that Attacking Maneuver by 1(T) for '
        'each Tactic Point spent.\n'
        '(3)-[Triggered]: When you or an Ally uses the Defend Maneuver, you '
        'can spend up to 2 Tactic Points to reduce the Ki Point Cost of the '
        'Guard effect by 2(T) for each Tactic Point spent, or increase their '
        'Soak Value for the duration of that Attacking Maneuver by 2(T) for '
        'each Tactic Point spent.\n'
        "(4)-[Passive, Twinned]: Gain access to the Attacker's Tactics Trait. "
        "If you already have access to Attacker's Tactics, then increase the "
        'amount of Tactic Points you gain from the first effect of '
        "Defender's Tactics by 1.",
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Enhanced Eyes',
    description: 'More perceptive than most, your race is capable of seeing '
        'even the most minute details from far away.\n'
        '(1)-[Passive]: Reduce the Critical Target for your Strike and Wound '
        'Rolls for Attacking Maneuvers made through the Signature Technique '
        'Maneuver by 1.\n'
        '(2)-[Passive]: Gain a Skill Rank in the Perception Skill and reduce '
        'the Critical Target for your Perception Skill Checks by 2.\n'
        '(3)-[Passive]: You cannot suffer from the Long Range Penalty, but you '
        'also cannot use any Signature Techniques that possess the Short Range '
        'Disadvantage.\n'
        '(4)-[Triggered, 1/Round]: If you use the Basic Attack Maneuver, you '
        'may spend 3(bT) Ki Points to use the Called Shot Maneuver in response '
        'to that Attacking Maneuver without spending an Action through its '
        'effects.\n'
        '(5)-[Passive, Twinned]: Ignore the reduction to your Strike Roll from '
        'the effects of the Called Shot Maneuver and increase the Wound Rolls '
        'of your Called Shots by 2(T).\n'
        '(6)-[Triggered, 1/Round, Twinned]: If you target an Opponent with a '
        'Called Shot, you may apply an Energy Charge to that Attacking '
        'Maneuver.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Fluid Physique',
    description: 'Able to change your size seemingly at will, you are as big, '
        'or small, as the situation demands.\n'
        '(2)-[1/Round]: As an Instant Maneuver, either gain or lose 1 Mass.\n'
        '(3)-[Triggered]: When making a Signature Technique, you may increase '
        'your Mass by up to 2 for the duration of that Attacking Maneuver.\n'
        '(4)-[Automatic/Threshold]: You lose 1 Mass. If you succeed at your '
        'Steadfast Save for that Health Threshold, either gain up to 2 Mass or '
        'regain 3(T) Life Points immediately.\n'
        '(6)-[Passive, Twinned]: For every 3 Mass you possess, increase your '
        'Wound Rolls and Soak Value by 1(bT).\n'
        '(7)-[Passive, Twinned]: Increase your Defense Value by 2(bT). Reduce '
        'this bonus by 1(bT) while your Mass is 2+, and stop benefiting from '
        'this bonus completely if your Mass is 4+.\n'
        '(8)-[Passive, Twinned]: Gain access to the Liquid Form Maneuver and '
        'you gain the Elemental (Water) Profile as a Favored Element (see - '
        'Foundations & Profiles).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Foreseer',
    description: 'Your species possesses the coveted power of future sight.\n'
        '(1)-[Passive]: Gain access to the Precognition Unique Ability.\n'
        '(2)-[Triggered, Ruling]: If you target an Opponent with the '
        "Precognition Unique Ability, that Opponent becomes a 'Foreseen' "
        'Opponent until the end of their turn.\n'
        '(3)-[Triggered]: Any movement from your Foreseen Opponent triggers '
        'your Exploit Maneuver, regardless of how far away you are from that '
        'Opponent.\n'
        '(4)-[Triggered]: If your Foreseen Opponent targets you or an Ally '
        'with an Attacking Maneuver that fails to deal Damage (either due to '
        'missing or having its Damage reduced to 0), you may use the Basic '
        'Attack Maneuver against that Opponent as an Out-of-Sequence '
        'Maneuver.\n'
        '(5)-[Passive, Twinned]: Increase your Wound Rolls against the '
        'Foreseen Opponent by 2(T).\n'
        '(6)-[Triggered, 1/Round, Twinned]: If your Foreseen Opponent is '
        'knocked through a Health Threshold, reduce the Dice Score of their '
        'Steadfast Check by 2.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Forged in Battle',
    description: 'Your species evolved under the ever-present threat of '
        'conflict, becoming a warrior race.\n'
        '(1)-[Triggered/Start of Combat Round]: Reduce a Combat Roll of your '
        'choice by 1(T). If you do, increase a different Combat Roll of your '
        'choice by 2(T) until the end of the Combat Round.\n'
        '(2)-[Triggered, 1/Round]: When using a Signature Technique, you can '
        'reduce your Soak Value and Defense Value by 1(T) until the start of '
        'your next turn to increase your Strike and Wound Rolls for that '
        'Attacking Maneuver by 1(T) and 3(T) respectively.\n'
        '(3)-[Triggered, 1/Encounter]: If you fail a Steadfast Check, you can '
        'instead choose to suffer from the Impediment Combat Condition until '
        'the end of your next turn to automatically succeed at that Steadfast '
        'Check.\n'
        '(4)-[Passive, Twinned]: You do not reduce a Combat Roll for the first '
        'effect of Forged in Battle.\n'
        '(5)-[Triggered/Start of Turn, Twinned]: You may spend 4(bT) Ki Points '
        'to stop suffering from the Impediment Combat Condition.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Inherent Transformation',
    description: 'Your race possesses the coveted ability to change their '
        'form, growing in power as they do.\n'
        '(1)-[Passive]: Increase your Stress Bonus by 1 while below the '
        'Injured Health Threshold.\n'
        "(2)-[Passive, Ruling]: Select a Transformation Type, this is known "
        "as your 'Primary Transformation'.\n"
        '(3)-[Passive]: Depending on the Transformation Type of your Primary '
        'Transformation, apply one of the following effects: Awakening '
        '[Passive]: Select and gain access to a Lesser Awakening (ToP '
        'Requirement 1) you meet the requirements for — it does not count '
        'towards your Awakening Limit but grants no AMB (if that '
        "Transformation is of the Mind Category, this Trait becomes Mind). "
        'Enhancement [Passive]: Select and gain access to an Enhancement (ToP '
        'Requirement 1) you meet the requirements for. Form [Passive]: Select '
        'and gain access to a Form (ToP Requirement 2 or less) you meet the '
        'requirements for (if its ToP Requirement is 2, it gains the Prelude '
        'Aspect).\n'
        '(4)-[Passive, Twinned]: You may apply the increase to your Stress '
        'Bonus from the first effect of Inherent Transformation regardless of '
        'your current Health Threshold.\n'
        '(5)-[Passive, Twinned]: Depending on the Transformation Type of your '
        'Primary Transformation: Awakening [Triggered/Start of Turn]: While in '
        'your Normal State, regain 3(bT) Ki Points. Enhancement [Passive]: '
        'Reduce the Stress Test Requirement for the Enhancement selected for '
        'the third effect by 2. Form [Passive]: While in a Form, increase your '
        'Attribute Modifier (FO/MA) by 1(T).',
    automation: [
      // (1) +1 Stress Bonus while below the Injured Health Threshold (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.stressBonus],
        coefficient: 1,
        tierScaling: TierScaling.none,
        condition: TraitCondition.whileBelowInjuredThreshold,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Inner Nature',
    description: 'Like a caged beast, a burning rage coils within you, '
        'waiting for the moment that it can be unleashed — whether you want it '
        'to be or not.\n'
        "(1)-[Prerequisite]: Inherent Transformation Racial Trait with 'Form' "
        'chosen as the Primary Transformation. Inner Nature cannot be chosen '
        'an additional time and become a Primary Racial Trait unless you have '
        'Inherent Transformation as a Primary Racial Trait.\n'
        '(2)-[Passive]: All of your Forms gain the Rampage Form Evolved '
        'Stage.\n'
        '(3)-[Passive]: To enter a Form, you must enter the Rampage Form '
        'Evolved Stage with that Form as the Original Form unless that Form is '
        'fully Mastered.\n'
        "(4)-[Passive]: While a Form isn't fully Mastered, the Rampage Form "
        'Evolved Stage does not increase the Stress Test Requirement.\n'
        '(5)-[Passive]: While in the Rampage Form Evolved Stage, increase your '
        'Combat Rolls and Soak Value by 1(T).\n'
        '(6)-[Passive, Twinned]: Double the Stress Bonus from the 1st effect '
        'of Inherent Transformation.\n'
        '(7)-[Passive, Twinned]: While in your Normal State, increase your '
        'Surgency by 2(T).\n'
        '(8)-[Triggered, 1/Encounter, Twinned]: If you enter the Rampage Form '
        'through the Transformation Maneuver, you may increase your Tier of '
        'Power by 1 (see - Breakthrough) until the end of your next turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Invulnerable',
    description: 'Your species is capable of completely avoiding harm from '
        'attacks of a certain variety.\n'
        '(1)-[Passive, Ruling]: Upon gaining this Trait, select a Foundation '
        '(Physical, Energy or Magical). This is known as your Resisted '
        'Foundation. Halve any Damage you receive from Attacking Maneuvers of '
        'your Resisted Foundation.\n'
        '(2)-[Triggered]: If you receive Damage from an Attacking Maneuver of '
        'your Resisted Foundation, and are not Defeated, you may spend a '
        'Counter Action to target an Opponent who is not at Long Range. Make a '
        'Clash (Corporeal vs Corporeal/Impulsive) against that Opponent. If '
        'you win, they receive Damage equal to the Damage you received or your '
        'Soak Value (whichever is higher).\n'
        '(3)-[Passive, Twinned]: Increase your Soak Value by 2(bT).\n'
        '(4)-[Passive, Twinned]: Instead of halving any Damage you take '
        'through the first effect of Invulnerable, you only receive 1/4 of any '
        'Damage dealt by your Resisted Foundation.\n'
        '(5)-[Triggered, Twinned]: Increase the Damage inflicted by the second '
        'effect of Invulnerable by 1/4 (rounded up) of your Might.',
    automation: [
      // (3)-[Twinned]: +2(bT) Soak Value.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 2,
        tierScaling: TierScaling.base,
        twinned: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Ki Control',
    description: 'Well-versed in the arts of ki and energy manipulation, your '
        'race is extremely adept at empowering their attacks and sensing and '
        'concealing ki.\n'
        '(1)-[Passive]: Gain a Skill Rank in the Clairvoyance and Concealment '
        'Skills. Additionally, reduce the Critical Target for any Skill Checks '
        'made with those Skills by 1.\n'
        '(2)-[Passive]: Halve the starting TP Cost for creating Signature '
        'Techniques of the Physical or Energy Foundation.\n'
        '(3)-[Triggered, 1/Round]: If you use a Signature Technique of the '
        'Physical or Energy Foundation, you may spend 2(T) Ki Points to apply '
        'an Energy Charge to that Attacking Maneuver.\n'
        '(4)-[Passive, Twinned]: Reduce the Ki Point Cost of all Physical or '
        'Energy Attacks by 2(T).\n'
        '(5)-[Passive, Twinned]: You automatically succeed any Concealment '
        'Skill Checks.\n'
        '(6)-[Triggered, 1/Encounter, Twinned]: If you use a Signature '
        'Technique of the Physical or Energy Foundation, halve its Ki Point '
        'Cost for this use of that Signature Technique.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Killer Instinct',
    description: "With the hunter's instinct of a predator, you are able to "
        'overwhelm your targets with your combat prowess.\n'
        '(1)-[Passive]: Gain a Skill Rank in the Intimidation Skill.\n'
        '(2)-[Triggered, 1/Round]: If you Defeat an Opponent or knock them '
        'through a Health Threshold with an Attacking Maneuver, you may choose '
        'and apply one of the following effects: Refreshing Instinct '
        '[1/Encounter]: use a Ki Surge Out-of-Sequence. Punishing Instinct '
        '[1/Encounter]: increase your Wound Rolls by 2(T) until the end of '
        'your next turn. Power Instinct [1/Encounter]: increase your Tier of '
        'Power by 1 until the end of your turn. Prepared Instinct '
        '[1/Encounter]: fully restore your Capacity Rate.\n'
        '(3)-[Passive, Twinned]: Increase your Wound Rolls by 1(T) for every 2 '
        'Skill Ranks you have in the Intimidation Skill. The 5th Skill Rank in '
        'Intimidation counts as 2 Skill Ranks for this effect.\n'
        '(4)-[Triggered, 1/Encounter, Twinned]: When you trigger the second '
        'effect of Killer Instinct, you may select 2 effects to apply instead '
        'of 1.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Lingering Presence',
    description: 'Your species has a knack for inflicting lasting damage on '
        'their enemies.\n'
        '(1)-[Triggered]: If you deal Damage to an Opponent with an Attacking '
        'Maneuver, they gain a stack of Damage Over Time (DOT - see Damage & '
        'Conditions) until the start of your next turn.\n'
        "(2)-[Triggered, 1/Round]: If you are hit by an Opponent's Attacking "
        'Maneuver that possesses any number of DOT stacks, you may increase '
        'your Soak Value for the duration of that Attacking Maneuver by 1(bT) '
        'for each stack of DOT applied to the attacking Opponent.\n'
        '(3)-[Passive, Twinned]: Increase your Strike and Wound Rolls against '
        'Opponents with any number of DOT stacks by 1(T).\n'
        '(4)-[Triggered, 1/Round, Twinned]: If you knock an Opponent through a '
        'Health Threshold with an Attacking Maneuver, all stacks of DOT they '
        'are currently suffering from last an additional Combat Round.\n'
        '(5)-[1/Encounter, Twinned]: As a Standard Action with an Action Cost '
        'of 2, target all Opponents within a Destructive Sphere AoE (centered '
        'on you). Make a Might Clash against those Opponents. If you win, that '
        'Opponent gains 3 DOT stacks until the start of your next turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Magical Mastery',
    description: 'Your race has unique, inherent access to magic.\n'
        '(1)-[Passive]: You gain access to the Magical Materialization and '
        'Telekinesis Unique Abilities.\n'
        '(2)-[Passive]: Reduce the TP Cost of all Magical Unique Abilities by '
        '2.\n'
        '(3)-[Passive]: Upon gaining this Trait, select any Magical Unique '
        'Ability with a TP Cost of 30 or less (you must still meet any '
        'Prerequisites, except a listed Attribute Score, and if the listed '
        'Skill Ranks required are 2 or less). You gain access to that Unique '
        'Ability while you possess this Trait.\n'
        '(4)-[Passive, Twinned]: Reduce the Ki Point Cost of your Magical '
        'Unique Abilities by 2(T) and increase the Dice Score of any of your '
        'Clashes made through the effects of a Unique Ability that use either '
        'your Might or a Saving Throw for the Clash by 1(T).\n'
        '(5)-[Triggered/Start of Combat Round, 1/Encounter, Twinned]: Select a '
        'Unique Ability you meet the Prerequisites for that has a TP Cost of '
        '30 or less; you gain access to that Unique Ability until the end of '
        'the Combat Round.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Mirrored Mind',
    description: 'Through an advanced form of mimicry, you are able to learn '
        'how to replicate the actions and techniques of everyone around '
        'you.\n'
        '(1)-[Passive]: Gain the Quick Learner Talent (even if you do not meet '
        'the Prerequisites).\n'
        "(2)-[Passive]: You may ignore the effects of any Disadvantage with "
        "'Restricted' in its name on any Signature Technique you have gained "
        'through the effects of Quick Learner.\n'
        '(3)-[Triggered, 1/Encounter]: When you gain a Copied Technique, enter '
        'the Superior State until the end of your next turn.\n'
        '(4)-[Passive, Twinned]: Increase the Wound Rolls of your Copied '
        'Techniques by 2(T).\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you gain access to a Copied '
        'Technique, regain Ki Points equal to 1/2 of its Ki Point Cost.\n'
        '(6)-[Triggered/Superior, 1/Encounter, Twinned]: Increase the Strike '
        'and Wound Rolls of your Signature Techniques by 1(T) and 2(T) '
        'respectively until the end of your next turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Monstrous',
    description: 'Unlike most humanoids, you possess features that mark you as '
        'more dangerous, animalistic, or outright creepy.\n'
        '(1)-[Passive]: Select and gain access to a Factor Trait from the '
        'Monster Factor while you possess this Trait (while you possess this '
        'Trait, you are considered to have the Monster Factor even if you do '
        'not meet any Prerequisites).\n'
        '(2)-[Passive, Twinned]: Gain 1 Monstrous Trait.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Natural Fusion',
    description: 'By some means unavailable to others, you possess the '
        'inherent ability to combine with others, becoming far more '
        'powerful.\n'
        '(1)-[Passive]: Apply your Racial Saving Throw Bonus to Cognitive as '
        'well as what you selected for this Race. If you already selected '
        'Cognitive, then instead pick any other Saving Throw that your Racial '
        'Saving Throw Bonus is not already being applied to.\n'
        '(2)-[Option]: Upon gaining this Trait, select and gain one of the '
        'following effects: Creature Consumption [Passive]: Gain access to the '
        'Absorb Maneuver. Bodily Possession [Passive]: Gain access to the '
        'Possess Maneuver. Merged Power [Passive]: Gain access to the Merge '
        'Fusion Method (only with another member of your Race).\n'
        '(3)-[Passive, Twinned]: Apply your Racial Saving Throw Bonus to '
        'Corporeal as well as what you selected for this Race. If you already '
        'selected Corporeal, then instead pick any other Saving Throw that '
        'your Racial Saving Throw Bonus is not already being applied to.\n'
        '(4)-[Choice, Twinned]: Depending on your Option choice: Creature '
        'Consumption [Passive]: While you have a stack of Absorption, increase '
        'your Combat Rolls and Soak Value by 1(T). Bodily Possession '
        '[Passive]: While you are a Possessing Character, increase the Combat '
        'Rolls and Soak Value of the character with your connected Overtaken '
        'Awakening by 1(T). Merged Power [Passive]: Upon exiting a Fusion, you '
        'do not suffer Stress Exhaustion.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Natural Perfection',
    description: 'Your species does everything well; even their failures can '
        'be considered perfect.\n'
        '(1)-[Triggered]: Upon scoring a Botch Result or a Critical Result, '
        'regain 2(bT) Ki Points.\n'
        '(2)-[Triggered, 1/Round]: When you score a Botch Result on a Combat '
        'Roll, increase your Dice Score by 2(T) instead of suffering the '
        'penalty.\n'
        '(3)-[Triggered, 1/Round]: When you score a Critical Result on a '
        'Combat Roll, increase your Dice Score by an additional 2(T).\n'
        '(4)-[Triggered, 1/Round, Twinned]: After seeing the result of your '
        'Combat Roll, you may increase or reduce the Natural Result by up to '
        '2.\n'
        '(5)-[Triggered, 1/Encounter, Twinned]: After rolling a Combat Roll, '
        'you may declare that it is a Critical Result regardless of the '
        'Natural Result. If your result would have been a Botch Result, it is '
        'also no longer a Botch Result.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Piloting Prowess',
    description: 'Your species is known for their expertise with Battle '
        'Jackets, particularly in upgrading their combat efficiency.\n'
        '(1)-[Passive]: You gain the Expert Pilot Talent and increase the '
        'amount of Technique Points your Battle Jackets get at Jacket Creation '
        'and each new Tier of Power by 5.\n'
        '(2)-[Passive]: While in a Vehicle or a Battle Jacket, increase your '
        'Dodge Rolls against Called Shots by 2(T).\n'
        '(3)-[Passive, Twinned]: Increase the Maximum Life Points for your '
        'Primary Battle Jacket by 4 for each of your Power Levels reached.\n'
        '(4)-[Triggered/Start of Turn, Twinned]: If you are Piloting a Vehicle '
        'or Battle Jacket, you may use the Movement Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Race of Scholars',
    description: 'Well known for their intelligence and technological '
        'pursuits, your species is smarter than the average bear.\n'
        '(1)-[Passive]: Select a Skill that uses your Scholarship Attribute. '
        'Gain a Skill Rank in that Skill.\n'
        '(2)-[Passive]: While Scholarship has the highest Attribute Score '
        'amongst your Attributes, increase all of your Combat Rolls and '
        'Initiative by 1(bT).\n'
        '(3)-[Triggered, 1/Round]: When you make a Clash that uses your Saving '
        "Throw through an Opponent's effects, you may substitute the Attribute "
        'used for that Saving Throw with your Scholarship.\n'
        '(4)-[Passive, Twinned]: Increase your Scholarship Modifier by 1(T).\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you use the Analysis Maneuver, '
        'increase your Combat Rolls by 1(T) until the end of your turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Racial State',
    description: "Your species is well-known for their common personality "
        'trait, be it an aggressive tendency towards anger, or a calm, '
        'peaceful zen.\n'
        '(1)-[Passive]: While in a State, increase your Soak Value by 1(T).\n'
        '(2)-[Option]: At Character Creation, choose one of the following '
        'effects: Unyielding Rage [Triggered/Power, 2/Encounter]: Enter the '
        'Raging State until the end of your next turn. Calm Mind '
        '[Triggered/Power, 2/Encounter]: Enter the Mindful State until the end '
        'of your next turn.\n'
        '(3)-[Passive, Twinned]: While in a State, increase your Wound Rolls '
        'by 1(T).\n'
        '(4)-[Passive, Twinned]: For the second effect of Racial State, the '
        '2/Encounter Keyword for its effects is replaced by the 1/Round '
        'Keyword.\n'
        '(5)-[Choice, Twinned]: Unyielding Rage [Triggered/Raging]: Use the '
        'Power Up or Energy Charge Maneuver as an Out-of-Sequence Maneuver. '
        'Calm Mind [Triggered/Mindful]: Use a Standard Maneuver with an Action '
        'Cost of 1 Action as an Out-of-Sequence Maneuver.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Racial Technique',
    description: 'Your race has developed a unique technique, known or taught '
        'only to your own people.\n'
        '(1)-[Passive]: Upon creating a Race with this Trait, that Race gains '
        'access to a Signature Technique or Unique Ability (including '
        'Advancements) that has a total TP Cost of 25 or less. If you choose a '
        'Unique Ability, you may ignore any Attribute Score Prerequisites and '
        'any Skill Rank Prerequisites (if the required Skill Ranks are 2 or '
        'less). This becomes known as your Racial Technique.\n'
        '(2)-[Triggered, 1/Round]: Upon using your Racial Technique, regain '
        '2(bT) Ki Points.\n'
        '(3)-[Triggered, 1/Encounter]: If you use your Racial Technique while '
        'below the Injured Health Threshold, you do not have to pay its Ki '
        'Point Cost. If the Ki Point Cost is already 0, you may instead use a '
        'Ki Surge as an Out-of-Sequence Maneuver.\n'
        '(4)-[Passive, Twinned]: Increase your Maximum Ki Points by 2 for '
        'every Power Level reached.\n'
        '(5)-[Triggered, Twinned]: When using your Racial Technique, you may '
        'apply a rank of an Advantage or an Advancement (whichever is '
        'applicable) with a TP Cost of 10 or lower for that instance of the '
        'Racial Technique.',
    automation: [
      // (4)-[Twinned]: +2 Maximum Ki Points per Power Level.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.maxKi],
        coefficient: 2,
        tierScaling: TierScaling.none,
        kind: TraitMagnitudeKind.perPowerLevel,
        twinned: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Regenerative Anatomy',
    description: 'You are especially hard to kill thanks to your incredible '
        'regenerative abilities.\n'
        '(1)-[Passive]: Increase your Surgency by 2(T) for each Health '
        'Threshold you are below.\n'
        '(3)-[Passive, Twinned]: For the second effect of Regenerative '
        'Anatomy, the Ki Point Cost does not increase regardless of how many '
        'times the effect is used.\n'
        '(4)-[Triggered, 1/Round, Twinned]: If you use a Healing Surge, '
        'increase your Soak Value by 2(T) until the start of your next turn.',
    automation: [
      // (1) +2(T) Surgency per Health Threshold below (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 2,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Seizing Initiative',
    description: 'Your species thinks and acts faster than most, allowing you '
        'to take charge of the battlefield.\n'
        '(1)-[Passive]: Increase your Initiative Value by 1/4 (rounded up) of '
        'your Insight Modifier.\n'
        '(2)-[Triggered/Start of Combat Round]: You may increase or reduce '
        'your Initiative by up to 2(bT) until the end of the Combat Round.\n'
        '(3)-[Triggered/Start of Turn, 3/Encounter]: If your Initiative Value '
        'is the highest among all Characters, gain 1 Action.\n'
        '(4)-[Passive, Twinned]: Increase your Wound Rolls against Opponents '
        'with a lower Initiative Value than you by 2(T).\n'
        '(5)-[Triggered/Start of Combat Round, 1/Encounter, Twinned]: Before '
        'any other effects trigger, you may set your Initiative Value to 9001 '
        'for the duration of this Combat Round.',
    automation: [
      // (1) +1/4 (rounded up) of Insight Modifier to Initiative Value (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.initiative],
        coefficient: 1,
        tierScaling: TierScaling.none,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.insight,
        fractionDenominator: 4,
        roundUp: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Skilled Species',
    description: 'Your species is highly varied and adaptable, allowing them '
        'to display a wide variety of skills and abilities.\n'
        '(1)-[Passive]: Gain an additional Skill Rank at Character '
        'Creation.\n'
        '(2)-[Passive]: Increase the amount of Technique Points you gain from '
        'Skill Improvement by 3.\n'
        '(3)-[Triggered]: When you use the Signature Technique Maneuver, for '
        'this instance of using your chosen Signature Technique, you may gain '
        'a rank of Inefficiency. If you do, you may apply 2 ranks of Power '
        'Shot to that Attacking Maneuver (these may exceed the limit).\n'
        '(4)-[Passive, Twinned]: Increase the Dice Score of all of your Skill '
        'Checks by 2.\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you win a Clash that uses one '
        'of your Skills, increase your Combat Rolls by 1(T) until the end of '
        'your turn.\n'
        '(6)-[Triggered, 1/Encounter, Twinned]: If you win a Clash that uses '
        'one of your Skills, you may use the Signature Technique Maneuver as '
        'an Out-of-Sequence Maneuver.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Solid Guard',
    description: "Known for your species' ability to defend against any "
        'attack, your guard is always up.\n'
        '(1)-[Triggered]: When using the Defend Maneuver, you gain the '
        'following effects for the duration of the Maneuver, depending on the '
        'effect chosen: Parry: Increase your Strike Roll by 1(T). Power Flare: '
        'Increase your Wound Roll by 2(T). Guard: Increase your Damage '
        'Reduction by 1/4 (rounded up) of your Might. Direct Hit: Increase '
        'your Soak Value by 2(T) before any calculations. Cross Counter: '
        'Instead of halving your Defense Value, reduce it by 2(T).\n'
        '(2)-[Triggered, Twinned]: If you use the Defend Maneuver, increase '
        'your Soak Value and Combat Rolls by 1(T) for the duration of that '
        'Maneuver.\n'
        '(3)-[Triggered, 1/Encounter, Twinned]: If you are targeted by an '
        'Attacking Maneuver, you may use the Defend Maneuver without spending '
        'a Counter Action.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Squadron Species',
    description: 'Your species is innately adept at working together, '
        'naturally forming into combat groups when it comes time for '
        'battle.\n'
        '(1)-[Passive]: Increase your Combat Rolls by 1(T) if an Ally is on an '
        'adjacent Square to you.\n'
        '(2)-[Triggered, 1/Round]: If an Ally on an adjacent Square to you '
        'uses an Attacking Maneuver, you may use the United Attack Maneuver '
        'without spending an Action for its effects.\n'
        '(3)-[Triggered, 1/Round]: If an Ally on an adjacent Square to you is '
        'hit by an Attacking Maneuver, you may use the Intervene Maneuver '
        'without spending a Counter Action.\n'
        '(4)-[Passive, Twinned]: Increase your Damage Reduction by 1(T) if an '
        'Ally is on an adjacent Square to you.\n'
        '(5)-[Triggered, 1/Round, Twinned]: If an Ally on an adjacent Square '
        'to you is knocked through a Health Threshold, you may spend 5(bT) Ki '
        'Points to increase the Dice Score for their Steadfast Check by 2.\n'
        '(6)-[Triggered, 1/Encounter, Twinned]: If an Ally on an adjacent '
        'Square to you would receive enough Damage to be Defeated, before they '
        'take that Damage, reduce the amount of Damage so their Life Points '
        'will be 1 above the amount required to be Defeated. Reduce your Life '
        'Points by an amount equal to the reduction.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Technique Crafter',
    description: 'You are able to shape your fighting style spontaneously, '
        'often using it to adapt to the battlefield circumstances.\n'
        '(1)-[Passive]: Reduce the Technique Points you gain from Skill '
        'Improvements by 3.\n'
        '(2)-[Passive]: At Character Creation, gain 10 Spontaneous Technique '
        'Points (STP). Each time you gain a Skill Improvement, gain 5 STP.\n'
        '(3)-[2/Encounter]: When you use the Signature Technique Maneuver, you '
        'can create a Super Signature Technique with a TP Cost up to the total '
        'amount of STP you possess, but it cannot possess any Disadvantages or '
        'the Ascended Signature Advantage. Use that Signature Technique for '
        'the Signature Technique Maneuver; after you have used it, you lose '
        'access to it.\n'
        '(4)-[Passive, Twinned]: Any Signature Technique created through the '
        '3rd effect of Technique Crafter has a TP Cost of 0 (rather than 8) '
        'before applying Advantages.\n'
        '(5)-[Passive, Twinned]: Increase the Wound Rolls of your Signature '
        'Techniques by 2(T).\n'
        '(6)-[Triggered, 1/Encounter, Twinned]: If you use a Signature '
        'Technique created through the 3rd effect of Technique Crafter, halve '
        'the Ki Point Cost of that Attacking Maneuver.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Vital Vitality',
    description: 'Your species is notoriously hard to put down, but once they '
        'take damage, they go down much more quickly.\n'
        '(1)-[Passive]: While in the Healthy Health Threshold, reduce the Ki '
        'Point Cost of all Maneuvers by 2(T).\n'
        '(2)-[Passive]: While you are above the Injured Health Threshold, '
        'increase your Combat Rolls and Soak Value by 1(T).\n'
        '(3)-[Passive]: Increase your Surgency by 2(bT).\n'
        '(4)-[Passive]: While you are below the Injured Health Threshold, '
        'reduce your Combat Rolls and Soak Value by 1(bT), and reduce the Dice '
        'Score of your Steadfast Checks by 2.\n'
        '(5)-[Passive, Twinned]: While you are below the Injured Health '
        'Threshold, double the increase to your Surgency from the 3rd effect '
        'of Vital Vitality.\n'
        '(6)-[Triggered/Injured, 1/Encounter, Twinned]: Use a Healing Surge as '
        'an Out-of-Sequence Maneuver. If you do, triple your Surgency for the '
        'duration of this Maneuver.',
    automation: [
      // (3) +2(bT) Surgency (base, always-on).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 2,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Warrior Race',
    description: 'The blood of a proud warrior species surges through your '
        'veins, giving you the strength to keep fighting.\n'
        '(1)-[Passive]: For each Health Threshold you are below, increase your '
        'Wound Rolls by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you are hit by an Attacking Maneuver, '
        'regain 3(bT) Life Points.\n'
        '(3)-[Triggered/Threshold]: Use a Ki Surge.\n'
        '(4)-[Passive, Twinned]: For each Health Threshold you are below, '
        'increase your Surgency by 2(T).\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you regain Life Points, you may '
        'use the Power Up Maneuver as an Out-of-Sequence Maneuver.\n'
        '(6)-[Triggered/Defeated, 1/Encounter, Twinned]: Regain Life Points '
        'equal to your Surgency.',
    automation: [
      // (1) +1(T) Wound Rolls per Health Threshold below (base).
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
      // (4)-[Twinned]: +2(T) Surgency per Health Threshold below.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 2,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
        twinned: true,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Wise Warriors',
    description: 'Your species is good at reading other people in combat and '
        'identifying their movements before the first punch is even thrown.\n'
        '(1)-[Passive]: Increase your Defense Value by 1/4 (rounded up) of '
        'your Insight Modifier.\n'
        '(2)-[Triggered, 1/Round]: If you are targeted by a Signature '
        'Technique, you may increase your Defense Value by 1/2 of your Insight '
        'Modifier for the duration of that Attacking Maneuver.\n'
        '(3)-[Triggered, 1/Encounter]: When you are targeted by an Attacking '
        'Maneuver with 3+ Energy Charges, you may use the Defend Maneuver '
        'without spending a Counter Action and ignoring the increase to the '
        'Ki Point Cost of the Guard option from any Energy Charges on that '
        'Attacking Maneuver.\n'
        '(4)-[Passive, Twinned]: Increase your Soak Value by 1/4 (rounded up) '
        'of your Insight Modifier.\n'
        '(5)-[Triggered, 1/Round, Twinned]: If you are hit by a Signature '
        'Technique, you may increase your Damage Reduction by 1/2 of your '
        'Insight Modifier for the duration of that Attacking Maneuver.',
    automation: [
      // (1) +1/4 (rounded up) of Insight Modifier to Defense Value (base).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue],
        coefficient: 1,
        tierScaling: TierScaling.none,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.insight,
        fractionDenominator: 4,
        roundUp: true,
      ),
      // (4)-[Twinned]: +1/4 (rounded up) of Insight Modifier to Soak Value.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.none,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.insight,
        fractionDenominator: 4,
        roundUp: true,
        twinned: true,
      ),
    ],
  ),

  // ============================================================= FLAW TRAITS ===
  // Negative Traits (max. 2). Each Flaw taken raises Racial Life Modifier by 2
  // OR grants +1 Skill Rank (a Character-Creation choice, tracked elsewhere).
  // Flaws carry no [Twinned] effects.
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Awkward Anatomy',
    description: "Your race doesn't possess a humanoid structure, lacking "
        'limbs that can be used for holds and traditional martial arts.\n'
        '(1)-[Passive]: You cannot use the Grapple Maneuver, Terrain Lift '
        'Maneuver, or Throw Maneuver. You also cannot equip any Weapons or use '
        'Armed Attacking Maneuvers.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Brittle',
    description: 'Your bones break more easily than most, or you are '
        'otherwise more susceptible to damage.\n'
        '(1)-[Passive]: Increase all Damage you take by 1(bT).',
    automation: [
      // (1) Increase Damage taken by 1(bT) = -1(bT) Damage Reduction.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: -1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Easily Staggered',
    description: 'Your race has a hard time recovering from powerful blows.\n'
        '(1)-[Automatic, 1/Round]: If you fail a Steadfast Check, gain the '
        'Slowed Combat Condition until the end of your turn.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Elemental Vulnerability',
    description: 'You are especially sensitive to a particular natural '
        'element.\n'
        "(1)-[Passive, Ruling]: Select a Profile with 'Elemental' in the name. "
        'Increase the Damage you receive from Attacking Maneuvers of that '
        'Profile by 2(bT).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Environmental Preference',
    description: 'Specifically adapted to a unique environment, your body — '
        'while capable of existing in other environments — suffers outside of '
        'its natural environment.\n'
        '(1)-[Passive]: At Character Creation, select a Battle Environment '
        'except Standard. While not in your selected Battle Environment, '
        'reduce your Combat Rolls by 1(bT).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Fragile Heart',
    description: "Easily affected by an enemy's words, you are a kind, gentle "
        "soul who can't handle harsh criticisms.\n"
        '(1)-[Passive]: Reduce your Morale Saving Throw by 1(bT).\n'
        '(2)-[Passive]: If you lose the Morale Clash for the Insult Maneuver, '
        'gain the Shaken Combat Condition until the end of your next turn.',
    automation: [
      // (1) -1(bT) Morale Saving Throw.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.moraleSave],
        coefficient: -1,
        tierScaling: TierScaling.base,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Heavy',
    description: 'Your body is large and hard to move, slowing you '
        'considerably.\n'
        '(1)-[Passive]: Reduce your Speed by 1/4 (rounded up) and treat your '
        'Size Category as if it was 1 higher for the sake of your Defense '
        'Value Bonus/Penalty. This Flaw cannot be taken if you possess the '
        'Blazing Speed Racial Trait.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Limited Form',
    description: 'Unable to unleash your full power without external stimulus '
        'of some kind, you do not control your Transformation.\n'
        '(1)-[Prerequisite]: This Flaw can only be gained if you possess the '
        'Inherent Transformation Racial Trait and select either the '
        'Enhancement or Form Transformation Type for its effects.\n'
        '(2)-[Passive]: You cannot enter the Transformation selected by '
        'Inherent Transformation at will; the Transformation possesses a '
        'unique Prerequisite, such as taking a certain drug or only being '
        'possible within proximity to a certain celestial body. Discuss the '
        'specifics with your ARC.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Limited Recovery',
    description: "Your race's anatomy makes it difficult to recover your "
        'stamina or mend your wounds during the heat of battle.\n'
        '(1)-[Passive]: Halve the amount of Life Points regained from your '
        'Combat Recovery and Healing Surge (before applying Surgency).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Low Resilience',
    description: 'Your resolve for battle is easily shaken.\n'
        '(1)-[Passive]: Reduce the Dice Score of your Steadfast Checks by 1.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Minion Species',
    description: 'Your species tends towards natural subservience to other, '
        'stronger beings.\n'
        '(1)-[Passive]: This Race gains one less Custom Species Racial Trait, '
        'but this Race is treated as a Minion Race. You cannot gain the '
        'Minion no More Factor if you possess this Flaw.\n'
        "(2)-[Passive]: Reduce your Racial Life Modifier by 2 and your Race's "
        'number of Skill Ranks by 1.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Poor Eyesight',
    description: 'Your race heavily relies on other senses to make up for '
        'lackluster vision.\n'
        '(1)-[Passive]: Reduce the Natural Result of your Perception Checks by '
        '1.\n'
        '(2)-[Passive]: Reduce your Combat Rolls against Opponents who are at '
        'Long Range by 1(T).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Reclusive Form',
    description: 'You are, by whatever means, able to take refuge in an '
        'inanimate form.\n'
        '(1)-[Automatic]: When you are Defeated, you become an Item (speak '
        'with your ARC to decide what item you become).',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Small and Fragile',
    description: 'Shorter and less hardy than other races, you are more suited '
        'to intellectual pursuits than combat.\n'
        '(1)-[Passive]: You cannot take this Flaw if you possess the Alternate '
        'Scale Racial Trait.\n'
        '(2)-[Passive]: Your base Size Category is Small.\n'
        '(3)-[Passive]: Treat your Size Category as if it was 1 lower when '
        'calculating your Soak Value bonus/penalty from your Size Category.',
    automation: [
      // (2) Base Size Category becomes Small (one below the Medium default).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.sizeCategory],
        coefficient: -1,
        tierScaling: TierScaling.none,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Wasteful',
    description: 'Your species puts so much effort into their attacks to the '
        'point of inefficiency.\n'
        '(1)-[Passive]: Increase the Ki Point Cost of all your Attacking '
        'Maneuvers by 2(T).\n'
        '(2)-[Passive]: Increase the Wound Roll of all your Attacking '
        'Maneuvers by 1(T).',
    automation: [
      // (2) +1(T) Wound Rolls of all Attacking Maneuvers.
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
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Weak Spot',
    description: 'No matter how tough you are, there is some spot on your body '
        'that, when struck, renders you defenseless.\n'
        '(1)-[Passive]: Select a part of your body to be a Weak Spot. Your '
        'Opponent, if they know of your Weak Spot, can target it with a Called '
        'Shot. If you are hit in your Weak Spot, that Attacking Maneuver '
        'becomes Lethal regardless of any effects that could reduce the Damage '
        'Category and ignores all Damage Reduction.',
  ),
  RaceTraitDef(
    race: 'Custom Species',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Weather Vulnerability',
    description: 'Your anatomy is susceptible to certain forms of weather, '
        'leaving you scurrying for cover.\n'
        '(1)-[Passive]: At Character Creation, select a Battle Weather. While '
        'in that Battle Weather, reduce your Combat Rolls by 1(bT).\n'
        '(2)-[Automatic/Start of Turn]: If you are in your selected Battle '
        'Weather, reduce your Life Points by 5(bT).',
  ),
];

/// Looks up a Custom Species Racial Trait by name (case-sensitive), or `null`.
RaceTraitDef? customSpeciesTraitByName(String name) {
  for (final t in kDbuCustomSpeciesTraits) {
    if (t.name == name) return t;
  }
  return null;
}

/// Whether a catalogue Trait is a **Flaw Trait** — the negative Traits at the
/// end of the Custom Species page. They are authored with
/// `RaceTraitTier.secondary` (every non-Flaw Custom Species Trait is
/// `primary`), since Primary/Secondary for a Custom Species means Twinned /
/// not-Twinned and is a per-character choice, not a catalogue property.
bool isCustomSpeciesFlaw(RaceTraitDef def) =>
    def.race == 'Custom Species' && def.tier == RaceTraitTier.secondary;

/// The Flaw Traits only (17 of the 58) — max. 2 per Race.
List<RaceTraitDef> get kDbuCustomSpeciesFlaws =>
    kDbuCustomSpeciesTraits.where(isCustomSpeciesFlaw).toList();

/// The non-Flaw Traits (41 of the 58) — the pool the 5 Racial Traits are
/// picked from.
List<RaceTraitDef> get kDbuCustomSpeciesRacialTraits =>
    kDbuCustomSpeciesTraits.where((t) => !isCustomSpeciesFlaw(t)).toList();

/// Maximum number of Flaw Traits a Custom Species may take (verbatim: "Decide
/// if your Race possesses any Flaw Traits (max. 2)").
const int kMaxCustomSpeciesFlaws = 2;

/// The compensation a Custom Species gains for each Flaw Trait it takes.
/// CONFIRMED verbatim (Custom Species page, Step 7): "For each Flaw Trait you
/// pick, either increase the Racial Life Modifier of your Race by 2 or
/// increase the number of Skill Ranks granted by your Race by 1."
enum FlawCompensation {
  racialLifeModifier('Racial Life Modifier +2'),
  skillRank('Skill Ranks +1');

  const FlawCompensation(this.displayName);
  final String displayName;
}

/// How much a Flaw Trait raises the Racial Life Modifier when that
/// compensation is chosen.
const int kFlawLifeModifierBonus = 2;

/// How many Skill Ranks a Flaw Trait grants when that compensation is chosen.
const int kFlawSkillRankBonus = 1;
