/// custom_buff_targets.dart
/// ---------------------------------------------------------------------------
/// The full Custom Buff target list, mirroring the old Google-Sheet's Custom
/// Buffs dropdown. Each [CustomBuffTarget] carries a display name, a display
/// [group] (for the grouped dropdown), and the atomic [channels] it resolves
/// into — the buff's computed value is applied to every listed [AffectedStat]
/// channel (a fan-out; e.g. "Combat Rolls" hits Strike + Dodge + all Wounds).
///
/// `CharacterCalculator.customBuffTotals` does the resolution; the wiring for
/// each channel lives in the calculator (see `AffectedStat` in dbu_rules.dart).
/// Targets whose effect the engine can't yet compute (dice-pool augmentation,
/// a few narrative toggles) resolve to [AffectedStat.manual] — they stay in the
/// dropdown for record-keeping, shown as "manual", and feed no derived stat.
/// ---------------------------------------------------------------------------
library;

import 'dbu_rules.dart';

/// Display grouping for the Custom Buff target dropdown.
enum CustomBuffGroup {
  attributes('Attributes'),
  progression('Progression & Tier'),
  pools('Pools'),
  defense('Defense'),
  saves('Saving Throws'),
  aptitudes('Aptitudes'),
  combatRolls('Combat Rolls'),
  might('Might & Stress'),
  speed('Speed'),
  size('Size & Penalties'),
  skills('Skills'),
  dice('Dice'),
  signature('Signature Dice'),
  attacks('Attacks'),
  misc('Misc');

  const CustomBuffGroup(this.displayName);
  final String displayName;
}

/// One selectable Custom Buff target. [channels] is the set of atomic
/// [AffectedStat] channels the buff's value is added to.
enum CustomBuffTarget {
  // ---- Attributes ----
  agScore('AG Score', CustomBuffGroup.attributes, [AffectedStat.scoreAgility]),
  foScore('FO Score', CustomBuffGroup.attributes, [AffectedStat.scoreForce]),
  teScore('TE Score', CustomBuffGroup.attributes, [AffectedStat.scoreTenacity]),
  scScore('SC Score', CustomBuffGroup.attributes,
      [AffectedStat.scoreScholarship]),
  inScore('IN Score', CustomBuffGroup.attributes, [AffectedStat.scoreInsight]),
  maScore('MA Score', CustomBuffGroup.attributes, [AffectedStat.scoreMagic]),
  peScore('PE Score', CustomBuffGroup.attributes,
      [AffectedStat.scorePersonality]),
  agModifier('AG Modifier', CustomBuffGroup.attributes,
      [AffectedStat.modAgility]),
  foModifier('FO Modifier', CustomBuffGroup.attributes, [AffectedStat.modForce]),
  teModifier('TE Modifier', CustomBuffGroup.attributes,
      [AffectedStat.modTenacity]),
  scModifier('SC Modifier', CustomBuffGroup.attributes,
      [AffectedStat.modScholarship]),
  inModifier('IN Modifier', CustomBuffGroup.attributes,
      [AffectedStat.modInsight]),
  maModifier('MA Modifier', CustomBuffGroup.attributes, [AffectedStat.modMagic]),
  peModifier('PE Modifier', CustomBuffGroup.attributes,
      [AffectedStat.modPersonality]),

  // ---- Progression & Tier ----
  tpPerSkillImprovement('TP per Skill Improvement', CustomBuffGroup.progression,
      [AffectedStat.tpPerSkillImprovement]),
  topBreakthrough('ToP (Breakthrough)', CustomBuffGroup.progression,
      [AffectedStat.topBreakthrough]),
  topExtraDiceCat('ToP Extra Dice Cat.', CustomBuffGroup.progression,
      [AffectedStat.topDiceCategoryAll]),
  topExtraDiceCatDodge('ToP Extra Dice Cat. (Dodge)',
      CustomBuffGroup.progression, [AffectedStat.topDiceCategoryDodge]),
  topExtraDiceCatStrike('ToP Extra Dice Cat. (Strike)',
      CustomBuffGroup.progression, [AffectedStat.topDiceCategoryStrike]),
  topExtraDiceCatWound('ToP Extra Dice Cat. (Wound)',
      CustomBuffGroup.progression, [AffectedStat.topDiceCategoryWound]),

  // ---- Pools ----
  maxLife('Max Life Points', CustomBuffGroup.pools, [AffectedStat.maxLife]),
  maxLifeQuarter('Max Life Points ±1/4', CustomBuffGroup.pools,
      [AffectedStat.maxLifeQuarter]),
  maxKi('Max Ki Pool', CustomBuffGroup.pools, [AffectedStat.maxKi]),
  maxKiQuarter('Max Ki Pool ±1/4', CustomBuffGroup.pools,
      [AffectedStat.maxKiQuarter]),
  maxCapacity('Max Capacity', CustomBuffGroup.pools, [AffectedStat.maxCapacity]),
  maxCapacityQuarter('Max Capacity ±1/4', CustomBuffGroup.pools,
      [AffectedStat.maxCapacityQuarter]),
  racialLifeModifier('Racial Life Modifier', CustomBuffGroup.pools,
      [AffectedStat.racialLifeModifier]),

  // ---- Defense ----
  damageReduction('Damage Reduction', CustomBuffGroup.defense,
      [AffectedStat.damageReduction]),
  soak('Soak', CustomBuffGroup.defense, [AffectedStat.soak]),
  doubleBaseSoak('Double Base Soak', CustomBuffGroup.defense,
      [AffectedStat.doubleBaseSoak]),
  superStacks('Super Stacks', CustomBuffGroup.defense,
      [AffectedStat.superStacks]),
  powerBurstSuperStacks('Power Burst S. Stacks', CustomBuffGroup.defense,
      [AffectedStat.powerBurstSuperStacks]),
  noSuperStackPen('No Super Stack Pen.', CustomBuffGroup.defense,
      [AffectedStat.noSuperStackPenalty]),
  longRangeDistance('Long Range Distance', CustomBuffGroup.defense,
      [AffectedStat.manual]),

  // ---- Saving Throws ----
  allSaves('All Saves', CustomBuffGroup.saves, [
    AffectedStat.impulsiveSave,
    AffectedStat.cognitiveSave,
    AffectedStat.corporealSave,
    AffectedStat.moraleSave,
  ]),
  impulsiveSaves('Impulsive Saves', CustomBuffGroup.saves,
      [AffectedStat.impulsiveSave]),
  cognitiveSaves('Cognitive Saves', CustomBuffGroup.saves,
      [AffectedStat.cognitiveSave]),
  corporealSaves('Corporeal Saves', CustomBuffGroup.saves,
      [AffectedStat.corporealSave]),
  moraleSaves('Morale Saves', CustomBuffGroup.saves, [AffectedStat.moraleSave]),

  // ---- Aptitudes ----
  haste('Haste', CustomBuffGroup.aptitudes, [AffectedStat.haste]),
  awareness('Awareness', CustomBuffGroup.aptitudes, [AffectedStat.awareness]),
  initiative('Initiative', CustomBuffGroup.aptitudes, [AffectedStat.initiative]),
  defenseValue('Defense Value', CustomBuffGroup.aptitudes,
      [AffectedStat.defenseValue]),

  // ---- Combat Rolls ----
  combatRolls('Combat Rolls', CustomBuffGroup.combatRolls, [
    AffectedStat.strike,
    AffectedStat.dodge,
    AffectedStat.woundPhysical,
    AffectedStat.woundEnergy,
    AffectedStat.woundMagic,
  ]),
  strikeAll('Strike (All)', CustomBuffGroup.combatRolls, [AffectedStat.strike]),
  strikeAllCT('Strike CT (All)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikeCriticalTarget]),
  strikePhysical('Strike (Physical)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikePhysical]),
  strikePhysicalCT('Strike CT (Physical)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikePhysicalCriticalTarget]),
  strikeEnergy('Strike (Energy)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikeEnergy]),
  strikeEnergyCT('Strike CT (Energy)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikeEnergyCriticalTarget]),
  strikeMagic('Strike (Magic)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikeMagic]),
  strikeMagicCT('Strike CT (Magic)', CustomBuffGroup.combatRolls,
      [AffectedStat.strikeMagicCriticalTarget]),
  dodge('Dodge', CustomBuffGroup.combatRolls, [AffectedStat.dodge]),
  dodgeCT('Dodge CT', CustomBuffGroup.combatRolls,
      [AffectedStat.dodgeCriticalTarget]),
  woundAll('Wound (All)', CustomBuffGroup.combatRolls, [
    AffectedStat.woundPhysical,
    AffectedStat.woundEnergy,
    AffectedStat.woundMagic,
  ]),
  woundAllCT('Wound CT (All)', CustomBuffGroup.combatRolls, [
    AffectedStat.woundPhysicalCriticalTarget,
    AffectedStat.woundEnergyCriticalTarget,
    AffectedStat.woundMagicCriticalTarget,
  ]),
  woundPhysical('Wound (Physical)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundPhysical]),
  woundPhysicalCT('Wound CT (Physical)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundPhysicalCriticalTarget]),
  woundEnergy('Wound (Energy)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundEnergy]),
  woundEnergyCT('Wound CT (Energy)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundEnergyCriticalTarget]),
  woundMagic('Wound (Magic)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundMagic]),
  woundMagicCT('Wound CT (Magic)', CustomBuffGroup.combatRolls,
      [AffectedStat.woundMagicCriticalTarget]),

  // ---- Might & Stress ----
  might('Might', CustomBuffGroup.might, [AffectedStat.might]),
  mightForClashes('Might for Clashes', CustomBuffGroup.might,
      [AffectedStat.mightForClashes]),
  stressBonus('Stress Bonus', CustomBuffGroup.might, [AffectedStat.stressBonus]),
  thresholdBreaker('Threshold Breaker', CustomBuffGroup.might,
      [AffectedStat.manual]),

  // ---- Speed ----
  normalSpeed('Normal Speed', CustomBuffGroup.speed, [AffectedStat.speedNormal]),
  boostedSpeed('Boosted Speed', CustomBuffGroup.speed,
      [AffectedStat.speedBoosted]),
  bothSpeeds('Both Speeds', CustomBuffGroup.speed,
      [AffectedStat.speedNormal, AffectedStat.speedBoosted]),
  normalSpeedQuarter('Normal Speed ±1/4', CustomBuffGroup.speed,
      [AffectedStat.speedNormalQuarter]),
  boostedSpeedQuarter('Boosted Speed ±1/4', CustomBuffGroup.speed,
      [AffectedStat.speedBoostedQuarter]),
  bothSpeedsQuarter('Both Speeds ±1/4', CustomBuffGroup.speed,
      [AffectedStat.speedNormalQuarter, AffectedStat.speedBoostedQuarter]),
  halveNormalSpeed('Halve Normal Speed', CustomBuffGroup.speed,
      [AffectedStat.halveNormalSpeed]),
  halveBoostedSpeed('Halve Boosted Speed', CustomBuffGroup.speed,
      [AffectedStat.halveBoostedSpeed]),
  halveBothSpeeds('Halve Both Speeds', CustomBuffGroup.speed,
      [AffectedStat.halveNormalSpeed, AffectedStat.halveBoostedSpeed]),

  // ---- Size & Penalties ----
  sizeCategory('Size Category', CustomBuffGroup.size,
      [AffectedStat.sizeCategory]),
  noStrikePenalties('No Strike Penalties', CustomBuffGroup.size,
      [AffectedStat.noStrikePenalties]),
  noDodgePenalties('No Dodge Penalties', CustomBuffGroup.size,
      [AffectedStat.noDodgePenalties]),
  noWoundPenalties('No Wound Penalties', CustomBuffGroup.size,
      [AffectedStat.noWoundPenalties]),
  hypeManeuver('Hype Maneuver', CustomBuffGroup.size,
      [AffectedStat.hypeManeuver]),
  analysisInvestigation('Analysis Maneuver (Investigation)',
      CustomBuffGroup.size, [AffectedStat.analysisInvestigation]),
  analysisIntuition('Analysis Maneuver (Intuition)', CustomBuffGroup.size,
      [AffectedStat.analysisIntuition]),

  // ---- Skills ----
  agilitySkills('Agility Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupAgility]),
  forceSkills('Force Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupForce]),
  scholarshipSkills('Scholarship Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupScholarship]),
  insightSkills('Insight Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupInsight]),
  magicSkills('Magic Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupMagic]),
  personalitySkills('Personality Skills', CustomBuffGroup.skills,
      [AffectedStat.skillGroupPersonality]),
  acrobatics('Acrobatics', CustomBuffGroup.skills,
      [AffectedStat.skillAcrobatics]),
  bluff('Bluff', CustomBuffGroup.skills, [AffectedStat.skillBluff]),
  clairvoyance('Clairvoyance', CustomBuffGroup.skills,
      [AffectedStat.skillClairvoyance]),
  concealment('Concealment', CustomBuffGroup.skills,
      [AffectedStat.skillConcealment]),
  craft('Craft', CustomBuffGroup.skills, [AffectedStat.skillCraft]),
  creatureHandling('Creature Handling', CustomBuffGroup.skills,
      [AffectedStat.skillCreatureHandling]),
  intimidation('Intimidation', CustomBuffGroup.skills,
      [AffectedStat.skillIntimidation]),
  intuition('Intuition', CustomBuffGroup.skills, [AffectedStat.skillIntuition]),
  investigation('Investigation', CustomBuffGroup.skills,
      [AffectedStat.skillInvestigation]),
  knowledge('Knowledge', CustomBuffGroup.skills, [AffectedStat.skillKnowledge]),
  medicine('Medicine', CustomBuffGroup.skills, [AffectedStat.skillMedicine]),
  perception('Perception', CustomBuffGroup.skills,
      [AffectedStat.skillPerception]),
  performance('Performance', CustomBuffGroup.skills,
      [AffectedStat.skillPerformance]),
  persuasion('Persuasion', CustomBuffGroup.skills,
      [AffectedStat.skillPersuasion]),
  pilot('Pilot', CustomBuffGroup.skills, [AffectedStat.skillPilot]),
  stealth('Stealth', CustomBuffGroup.skills, [AffectedStat.skillStealth]),
  survival('Survival', CustomBuffGroup.skills, [AffectedStat.skillSurvival]),
  thievery('Thievery', CustomBuffGroup.skills, [AffectedStat.skillThievery]),
  useMagic('Use Magic', CustomBuffGroup.skills, [AffectedStat.skillUseMagic]),
  states('States', CustomBuffGroup.skills, [AffectedStat.manual]),

  // ---- Dice (dice-pool augmentation) ----
  greaterDiceCategory('Greater Dice Category', CustomBuffGroup.dice,
      [AffectedStat.greaterDiceCategory]),
  greaterDiceAll('Greater Dice (All)', CustomBuffGroup.dice,
      [AffectedStat.greaterDiceAll]),
  greaterDiceDodge('Greater Dice (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.greaterDiceDodge]),
  greaterDiceStrike('Greater Dice (Strike)', CustomBuffGroup.dice,
      [AffectedStat.greaterDiceStrike]),
  greaterDiceWound('Greater Dice (Wound)', CustomBuffGroup.dice,
      [AffectedStat.greaterDiceWound]),
  topExtraDiceAll('ToP Extra Dice (All)', CustomBuffGroup.dice,
      [AffectedStat.extraTopDiceAll]),
  topExtraDiceDodge('ToP Extra Dice (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.extraTopDiceDodge]),
  topExtraDiceStrike('ToP Extra Dice (Strike)', CustomBuffGroup.dice,
      [AffectedStat.extraTopDiceStrike]),
  topExtraDiceWound('ToP Extra Dice (Wound)', CustomBuffGroup.dice,
      [AffectedStat.extraTopDiceWound]),
  extraD4Combat('Extra d4 (Combat Rolls)', CustomBuffGroup.dice,
      [AffectedStat.flatD4All]),
  extraD6Combat('Extra d6 (Combat Rolls)', CustomBuffGroup.dice,
      [AffectedStat.flatD6All]),
  extraD8Combat('Extra d8 (Combat Rolls)', CustomBuffGroup.dice,
      [AffectedStat.flatD8All]),
  extraD10Combat('Extra d10 (Combat Rolls)', CustomBuffGroup.dice,
      [AffectedStat.flatD10All]),
  extraD4Dodge('Extra d4 (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.flatD4Dodge]),
  extraD6Dodge('Extra d6 (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.flatD6Dodge]),
  extraD8Dodge('Extra d8 (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.flatD8Dodge]),
  extraD10Dodge('Extra d10 (Dodge)', CustomBuffGroup.dice,
      [AffectedStat.flatD10Dodge]),
  extraD4Strike('Extra d4 (Strike)', CustomBuffGroup.dice,
      [AffectedStat.flatD4Strike]),
  extraD6Strike('Extra d6 (Strike)', CustomBuffGroup.dice,
      [AffectedStat.flatD6Strike]),
  extraD8Strike('Extra d8 (Strike)', CustomBuffGroup.dice,
      [AffectedStat.flatD8Strike]),
  extraD10Strike('Extra d10 (Strike)', CustomBuffGroup.dice,
      [AffectedStat.flatD10Strike]),
  extraD4Wound('Extra d4 (Wound)', CustomBuffGroup.dice,
      [AffectedStat.flatD4Wound]),
  extraD6Wound('Extra d6 (Wound)', CustomBuffGroup.dice,
      [AffectedStat.flatD6Wound]),
  extraD8Wound('Extra d8 (Wound)', CustomBuffGroup.dice,
      [AffectedStat.flatD8Wound]),
  extraD10Wound('Extra d10 (Wound)', CustomBuffGroup.dice,
      [AffectedStat.flatD10Wound]),
  energyChargeDiceCategory('Energy Charge Dice Category', CustomBuffGroup.dice,
      [AffectedStat.energyChargeDiceCategory]),
  // NB: the Superior/Entrusted States grant Greater Dice automatically (see
  // `stateGrantsGreaterDice`), and the "Greater Dice Category" buff above sizes
  // them — so no separate per-State dice-size buffs are needed. Raging/Surging
  // don't grant Combat-Roll dice, so they have none either.

  // ---- Signature Dice (applied to a referenced Signature attack) ----
  signatureCTStrike('Signature CT (Strike)', CustomBuffGroup.signature,
      [AffectedStat.signatureStrikeCriticalTarget]),
  signatureStrike('Signature Strike', CustomBuffGroup.signature,
      [AffectedStat.signatureStrikeFlat]),
  signatureCTWound('Signature CT (Wound)', CustomBuffGroup.signature,
      [AffectedStat.signatureWoundCriticalTarget]),
  signatureWound('Signature Wound', CustomBuffGroup.signature,
      [AffectedStat.signatureWoundFlat]),
  signatureEnergyChargeDiceCategory('Signature Energy Charge Dice Category',
      CustomBuffGroup.signature, [AffectedStat.signatureEnergyChargeDiceCategory]),
  signatureExtraTopAll('Signature Extra ToP Dice (All)',
      CustomBuffGroup.signature, [AffectedStat.signatureExtraTopAll]),
  signatureExtraTopStrike('Signature Extra ToP Dice (Strike)',
      CustomBuffGroup.signature, [AffectedStat.signatureExtraTopStrike]),
  signatureExtraTopWound('Signature Extra ToP Dice (Wound)',
      CustomBuffGroup.signature, [AffectedStat.signatureExtraTopWound]),
  signatureD4All('Signature d4 (All)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD4All]),
  signatureD6All('Signature d6 (All)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD6All]),
  signatureD8All('Signature d8 (All)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD8All]),
  signatureD10All('Signature d10 (All)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD10All]),
  signatureD4Strike('Signature d4 (Strike)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD4Strike]),
  signatureD6Strike('Signature d6 (Strike)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD6Strike]),
  signatureD8Strike('Signature d8 (Strike)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD8Strike]),
  signatureD10Strike('Signature d10 (Strike)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD10Strike]),
  signatureD4Wound('Signature d4 (Wound)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD4Wound]),
  signatureD6Wound('Signature d6 (Wound)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD6Wound]),
  signatureD8Wound('Signature d8 (Wound)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD8Wound]),
  signatureD10Wound('Signature d10 (Wound)', CustomBuffGroup.signature,
      [AffectedStat.signatureFlatD10Wound]),

  // ---- Attacks ----
  duelClashBonus('Duel Clash Bonus', CustomBuffGroup.attacks,
      [AffectedStat.duelClashBonus]),
  armedStrike('Armed Strike', CustomBuffGroup.attacks,
      [AffectedStat.armedStrike]),
  armedWound('Armed Wound', CustomBuffGroup.attacks, [AffectedStat.armedWound]),
  unarmedStrike('Unarmed Strike', CustomBuffGroup.attacks,
      [AffectedStat.unarmedStrike]),
  unarmedWound('Unarmed Wound', CustomBuffGroup.attacks,
      [AffectedStat.unarmedWound]),
  kiCostAttacks('Ki Point Cost Attacks', CustomBuffGroup.attacks,
      [AffectedStat.kiCostAttacks]),
  kiCostAttacksNoCap('Ki Point Cost Attacks (no cap)', CustomBuffGroup.attacks,
      [AffectedStat.kiCostAttacksNoCap]),
  kiCostUniqueAbilities('Ki Point Cost Unique Abilities',
      CustomBuffGroup.attacks, [AffectedStat.kiCostUniqueAbilities]),
  kiCostUniqueAbilitiesMagical('Ki Point Cost Unique Abilities (Magical)',
      CustomBuffGroup.attacks, [AffectedStat.kiCostUniqueAbilitiesMagical]),
  kiCostUniqueAbilitiesTechnical('Ki Point Cost Unique Abilities (Technical)',
      CustomBuffGroup.attacks, [AffectedStat.kiCostUniqueAbilitiesTechnical]),
  attackingDamageCategory('Attacking Damage Category', CustomBuffGroup.attacks,
      [AffectedStat.attackingDamageCategory]),

  // ---- Misc / narrative (kept for record-keeping; not auto-applied) ----
  ignoreTransformationLite('Ignore Transformation Lite', CustomBuffGroup.misc,
      [AffectedStat.manual]),
  beingBludgeoned("I'm being Bludgeoned", CustomBuffGroup.misc,
      [AffectedStat.beingBludgeoned]),
  doffKingsClothing("Doff (A King's Clothing!)", CustomBuffGroup.misc,
      [AffectedStat.manual]);

  const CustomBuffTarget(this.displayName, this.group, this.channels);

  final String displayName;
  final CustomBuffGroup group;
  final List<AffectedStat> channels;

  /// Whether this target actually feeds a derived stat (vs. record-keeping).
  bool get isAutomated => !channels.contains(AffectedStat.manual);
}

/// Legacy `AffectedStat.name` → `CustomBuffTarget` map, for loading old saves
/// that stored a raw `affectedStat` on each Custom Buff.
final Map<String, CustomBuffTarget> kLegacyAffectedStatToTarget = {
  'maxLife': CustomBuffTarget.maxLife,
  'maxKi': CustomBuffTarget.maxKi,
  'maxCapacity': CustomBuffTarget.maxCapacity,
  'might': CustomBuffTarget.might,
  'haste': CustomBuffTarget.haste,
  'awareness': CustomBuffTarget.awareness,
  'speedNormal': CustomBuffTarget.normalSpeed,
  'speedBoosted': CustomBuffTarget.boostedSpeed,
  'initiative': CustomBuffTarget.initiative,
  'defenseValue': CustomBuffTarget.defenseValue,
  'soak': CustomBuffTarget.soak,
  'strike': CustomBuffTarget.strikeAll,
  'dodge': CustomBuffTarget.dodge,
  'woundPhysical': CustomBuffTarget.woundPhysical,
  'woundEnergy': CustomBuffTarget.woundEnergy,
  'woundMagic': CustomBuffTarget.woundMagic,
  'impulsiveSave': CustomBuffTarget.impulsiveSaves,
  'cognitiveSave': CustomBuffTarget.cognitiveSaves,
  'corporealSave': CustomBuffTarget.corporealSaves,
  'moraleSave': CustomBuffTarget.moraleSaves,
  'surgency': CustomBuffTarget.might, // closest existing target
  'damageReduction': CustomBuffTarget.damageReduction,
};

/// Resolves a `CustomBuffTarget.name` (or a legacy `AffectedStat.name`) to a
/// target, for tolerant JSON loading.
CustomBuffTarget? customBuffTargetByName(String? name) {
  if (name == null) return null;
  for (final t in CustomBuffTarget.values) {
    if (t.name == name) return t;
  }
  return kLegacyAffectedStatToTarget[name];
}
