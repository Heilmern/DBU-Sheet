/// apparel.dart
/// ---------------------------------------------------------------------------
/// Static rules data for the APPAREL sub-system (Inventory page → Apparel).
/// Single source of truth for everything the calculator/UI needs to model a
/// piece of Apparel exactly as the live site's "Apparel" article defines it:
///
///   • [ApparelCategory]        — the four Categories (Armor / Weights / Combat
///                                Clothing / Standard Clothing), each granting
///                                a distinct benefit while worn.
///   • [ApparelGrade]           — Low / Standard / High → Apparel Bonus of
///                                1(bT) / 2(bT) / 3(bT).
///   • [kCraftsmanshipGrades]   — the Craftsmanship Grade table (Grade 1–5 →
///                                Craft DC Difficulty, Apparel Grade, and the
///                                number of Quality Slots).
///   • [kDbuApparelQualities]   — the full Apparel Qualities catalogue
///                                (standard + Special), transcribed verbatim,
///                                each with its Category restriction, Prereq
///                                text, Quality-Slot count (or range) and
///                                Effects text.
///
/// AUTOMATION. Like the Conditions/States catalogues, only the numerically
/// unambiguous effects are auto-applied to derived stats; the rest are shown as
/// reference text (`automation == null`). A Quality's [ApparelQualityDef.
/// automation] captures the parts the engine can apply: a flat change to the
/// piece's Apparel Bonus, Break-Value bonuses, penalty-exclusion / DR flags,
/// and direct stat effects (see [ApparelQualityAutomation]/[ApparelStatEffect]).
/// Situational or narrative effects (skill dice, retaliation damage, minion
/// buffs, weather, etc.) are deliberately left un-automated — the player reads
/// the Effects text and applies them when they matter.
///
/// PROVENANCE: transcribed from the offline ZIM archive's `/apparel/` article
/// (dbu-rpg.com, 2026-07-03 backup) — see the `zim-archive-lookup` memory note.
/// ---------------------------------------------------------------------------
library;

import 'dbu_rules.dart' show AffectedStat;

/// The four Apparel Categories. Each grants its benefit while the piece is worn
/// (Armor/Combat Clothing benefits require it to be the Top Layer — see
/// `CharacterCalculator`).
enum ApparelCategory {
  armor('Armor'),
  weights('Weights'),
  combatClothing('Combat Clothing'),
  standardClothing('Standard Clothing');

  const ApparelCategory(this.displayName);
  final String displayName;
}

/// Apparel Grade → Apparel Bonus (in multiples of Base Tier of Power).
/// CONFIRMED (verbatim): "Low: Apparel Bonus of 1(bT). Standard: 2(bT). High:
/// 3(bT)."
enum ApparelGrade {
  low('Low', 1),
  standard('Standard', 2),
  high('High', 3);

  const ApparelGrade(this.displayName, this.bonusPerBaseTier);
  final String displayName;

  /// The `x` in the Apparel Bonus of `x(bT)` for this Grade.
  final int bonusPerBaseTier;
}

/// One row of the Craftsmanship Grade table (CONFIRMED, verbatim):
///
///   Grade | Craft DC     | Apparel Grade | # Quality Slots
///   1     | Apprentice   | Low           | 0
///   2     | Qualified    | Low           | 1
///   3     | Expert       | Standard      | 2
///   4     | Master       | Standard      | 3
///   5     | Grandmaster  | High          | 4
class CraftsmanshipGradeInfo {
  const CraftsmanshipGradeInfo({
    required this.grade,
    required this.craftDc,
    required this.apparelGrade,
    required this.qualitySlots,
  });

  /// Craftsmanship Grade, 1–5.
  final int grade;

  /// The Craft DC Difficulty Category name for this Grade (a Difficulty
  /// Category, not a raw number — Standard Clothing lowers it by 1, noted in
  /// the UI rather than computed).
  final String craftDc;

  final ApparelGrade apparelGrade;

  /// How many Quality Slots a piece of this Craftsmanship Grade has.
  final int qualitySlots;
}

/// The Craftsmanship Grade table, indexable by Grade via [craftsmanshipInfo].
const List<CraftsmanshipGradeInfo> kCraftsmanshipGrades = [
  CraftsmanshipGradeInfo(
      grade: 1,
      craftDc: 'Apprentice',
      apparelGrade: ApparelGrade.low,
      qualitySlots: 0),
  CraftsmanshipGradeInfo(
      grade: 2,
      craftDc: 'Qualified',
      apparelGrade: ApparelGrade.low,
      qualitySlots: 1),
  CraftsmanshipGradeInfo(
      grade: 3,
      craftDc: 'Expert',
      apparelGrade: ApparelGrade.standard,
      qualitySlots: 2),
  CraftsmanshipGradeInfo(
      grade: 4,
      craftDc: 'Master',
      apparelGrade: ApparelGrade.standard,
      qualitySlots: 3),
  CraftsmanshipGradeInfo(
      grade: 5,
      craftDc: 'Grandmaster',
      apparelGrade: ApparelGrade.high,
      qualitySlots: 4),
];

/// The [CraftsmanshipGradeInfo] for a Craftsmanship [grade] (clamped 1–5).
CraftsmanshipGradeInfo craftsmanshipInfo(int grade) {
  final g = grade.clamp(1, kCraftsmanshipGrades.length);
  return kCraftsmanshipGrades[g - 1];
}

/// The default (unmodified) maximum Break Value of any piece of Apparel.
/// CONFIRMED (verbatim): "All pieces of Apparel by default have a Break Value
/// of 3."
const int kDefaultApparelBreakValue = 3;

/// How the magnitude of an [ApparelStatEffect] is derived:
///   • [perBaseTier]           — `coefficient` × Base Tier of Power.
///   • [apparelBonus]          — `coefficient` × the piece's Apparel Bonus.
///   • [halfApparelBonusRoundUp] — `coefficient` × ⌈Apparel Bonus / 2⌉.
enum ApparelEffectBasis { perBaseTier, apparelBonus, halfApparelBonusRoundUp }

/// A single automated stat change granted by an Apparel Quality while the piece
/// is worn (and not broken). Sign lives in [coefficient] (a Quality may buff or
/// debuff), summed into the same additive pipeline as Custom Buffs.
class ApparelStatEffect {
  const ApparelStatEffect({
    required this.stats,
    required this.coefficient,
    required this.basis,
  });

  final List<AffectedStat> stats;
  final int coefficient;
  final ApparelEffectBasis basis;
}

/// The auto-applicable part of an Apparel Quality's effect. Everything here is
/// something the engine can resolve into numbers; anything else stays in the
/// Quality's free-text Effects.
class ApparelQualityAutomation {
  const ApparelQualityAutomation({
    this.apparelBonusPerBaseTier = 0,
    this.breakValueBonus = 0,
    this.unbreakable = false,
    this.excludedFromApparelPenalty = false,
    this.halvesArmorDamageReduction = false,
    this.statEffects = const [],
  });

  /// Adds `x(bT)` to the piece's Apparel Bonus (Dense Armor +1, Divine Apparel
  /// +1). This flows into the Category benefit too (e.g. more Armor DR).
  final int apparelBonusPerBaseTier;

  /// Raises the piece's maximum Break Value (Durable +3).
  final int breakValueBonus;

  /// The piece's Break Value can never be reduced (Unbreakable).
  final bool unbreakable;

  /// The piece does not count toward the Apparel Penalty (Lightweight, Sleek
  /// Design).
  final bool excludedFromApparelPenalty;

  /// Halves the Damage Reduction this Armor grants (Sleek Design).
  final bool halvesArmorDamageReduction;

  /// Direct stat effects (Jacket, Enchanted, Combat Ready, Dense Armor's
  /// Combat-Roll reduction, …).
  final List<ApparelStatEffect> statEffects;
}

/// One entry in the Apparel Qualities catalogue.
class ApparelQualityDef {
  const ApparelQualityDef({
    required this.name,
    required this.categories,
    required this.prerequisites,
    required this.minSlots,
    required this.maxSlots,
    required this.effects,
    this.isSpecial = false,
    this.automation,
  });

  final String name;

  /// Which Apparel Categories may take this Quality.
  final Set<ApparelCategory> categories;

  /// The Prerequisite text (applies to the WEARER, not the crafter) — "N/A"
  /// when there is none. Not auto-checked (like other catalogue prereqs).
  final String prerequisites;

  /// Quality-Slot cost. Equal for a fixed cost; a range (e.g. 1~2, 1~3) when
  /// the player may choose how many Slots it occupies.
  final int minSlots;
  final int maxSlots;

  /// The verbatim Effects text.
  final String effects;

  /// Special Apparel Qualities are ARC-granted and "very powerful" — the site
  /// warns against more than one per piece. Surfaced separately in the picker.
  final bool isSpecial;

  /// The auto-applicable part of the effect, or `null` when the Quality is
  /// reference-only (situational/narrative — not applied to any stat).
  final ApparelQualityAutomation? automation;

  bool get hasSlotRange => maxSlots > minSlots;
  bool get isAutomated => automation != null;

  /// A short "1" / "1~2" label for the Slot cost.
  String get slotLabel => hasSlotRange ? '$minSlots~$maxSlots' : '$minSlots';
}

const Set<ApparelCategory> _all = {
  ApparelCategory.armor,
  ApparelCategory.weights,
  ApparelCategory.combatClothing,
  ApparelCategory.standardClothing,
};
const Set<ApparelCategory> _allExceptWeights = {
  ApparelCategory.armor,
  ApparelCategory.combatClothing,
  ApparelCategory.standardClothing,
};

/// The full Apparel Qualities catalogue (standard first, then Special).
/// Effects text is transcribed verbatim from the site.
const List<ApparelQualityDef> kDbuApparelQualities = [
  // --- Standard Apparel Qualities ------------------------------------------
  ApparelQualityDef(
    name: 'Armed',
    categories: _allExceptWeights,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'While you wear this piece of Apparel, you possess an Integrated '
        'Weapon. When this piece of Apparel is created, create a Weapon with a '
        'Craftsmanship Grade equal to that of this piece of Apparel - that '
        'Weapon is the Integrated Weapon.',
  ),
  ApparelQualityDef(
    name: 'Beautiful Attire',
    categories: _all,
    prerequisites: 'Personality Score of 4+',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Dice Score on Skill Checks with a Skill of your choice '
        '(when creating this piece of Apparel) by 2. The Skill must use your '
        'Personality Score to be chosen.',
  ),
  ApparelQualityDef(
    name: 'Dense Armor',
    categories: {ApparelCategory.armor},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Apparel Bonus by 1(bT) but reduce your Combat Rolls by '
        'an equal amount.',
    automation: ApparelQualityAutomation(
      apparelBonusPerBaseTier: 1,
      statEffects: [
        ApparelStatEffect(
          stats: [
            AffectedStat.strike,
            AffectedStat.dodge,
            AffectedStat.woundPhysical,
            AffectedStat.woundEnergy,
            AffectedStat.woundMagic,
          ],
          coefficient: -1,
          basis: ApparelEffectBasis.perBaseTier,
        ),
      ],
    ),
  ),
  ApparelQualityDef(
    name: 'Durable',
    categories: _all,
    prerequisites: 'This piece of Apparel does not have the Lightweight '
        'Apparel Quality',
    minSlots: 1,
    maxSlots: 1,
    effects: 'Increase the maximum Break Value for this piece of Apparel by 3.',
    automation: ApparelQualityAutomation(breakValueBonus: 3),
  ),
  ApparelQualityDef(
    name: 'Environmental Protection',
    categories: {ApparelCategory.standardClothing},
    prerequisites: 'N/A',
    minSlots: 2,
    maxSlots: 2,
    effects:
        'Ignore the effects of Battle Environments, Environmental Qualities, '
        'and Unbreathable Atmosphere.',
  ),
  ApparelQualityDef(
    name: 'Focal',
    categories: {ApparelCategory.weights},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Upon creating this piece of Apparel, select either your Strike or '
        'Dodge Rolls. The chosen Combat Roll is the only Combat Roll reduced by '
        'the effects of the Weight Apparel Category, but only that Combat Roll '
        "benefits from this piece of Apparel's Doff Bonus.",
  ),
  ApparelQualityDef(
    name: 'Hefty Plating',
    categories: {ApparelCategory.weights},
    prerequisites: 'Force Score of 6+',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'The Hardness Value of this piece of Apparel is set to 4. If you hit an '
        'Opponent with this piece of Apparel through the Throw Maneuver, make a '
        'Might Clash against them. If you win, they are knocked Prone.',
  ),
  ApparelQualityDef(
    name: 'Jacket',
    categories: {ApparelCategory.standardClothing},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Soak Value by 1(bT). This piece of Apparel can be worn '
        'over Armor.',
    automation: ApparelQualityAutomation(
      statEffects: [
        ApparelStatEffect(
          stats: [AffectedStat.soak],
          coefficient: 1,
          basis: ApparelEffectBasis.perBaseTier,
        ),
      ],
    ),
  ),
  ApparelQualityDef(
    name: 'Joint Protection',
    categories: {ApparelCategory.armor},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'The first time in a Combat Encounter that your Break Value would be '
        'lowered while being at its maximum Break Value, your Break Value is '
        'not lowered.',
  ),
  ApparelQualityDef(
    name: 'Lab Coat',
    categories: {ApparelCategory.standardClothing},
    prerequisites: 'Scholarship Score of 4+',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Dice Score on Skill Checks with a Skill of your choice '
        '(when creating this piece of Apparel) by 2. The Skill must use your '
        'Scholarship Score to be chosen.',
  ),
  ApparelQualityDef(
    name: "Leader's Insignia",
    categories: _allExceptWeights,
    prerequisites: 'Personality Score of 6+',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase the Combat Rolls of your Minions by 1(bT). If this piece of '
        'Apparel has the Team Outfit Quality, increase the Wound Roll of all '
        'Allies with the same team name by 1(bT) – this bonus does not stack if '
        'multiple Characters possess this Quality.',
  ),
  ApparelQualityDef(
    name: 'Lightweight',
    categories: _allExceptWeights,
    prerequisites:
        'This piece of Apparel does not have the Durable Apparel Quality.',
    minSlots: 1,
    maxSlots: 1,
    effects: 'This piece of Apparel does not count towards the Apparel Penalty.',
    automation: ApparelQualityAutomation(excludedFromApparelPenalty: true),
  ),
  ApparelQualityDef(
    name: 'Loose',
    categories: {ApparelCategory.combatClothing, ApparelCategory.standardClothing},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects: 'You can Doff this piece of Apparel through the No-Effort Maneuver.',
  ),
  ApparelQualityDef(
    name: 'Mystical',
    categories: {ApparelCategory.combatClothing, ApparelCategory.standardClothing},
    prerequisites: '2+ Skill Ranks in Clairvoyance and Use Magic',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase the Dice Score of your Use Magic and Clairvoyance Skill '
        'Checks by 1.',
  ),
  ApparelQualityDef(
    name: 'Parrying Armor',
    categories: {ApparelCategory.armor},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'While you do not have a Weapon equipped, increase your Strike Rolls '
        'when using the Parry effect of the Defend Maneuver by 1/2 (rounded up) '
        'of the Apparel Bonus.',
  ),
  ApparelQualityDef(
    name: 'Segmented Weight',
    categories: {ApparelCategory.weights},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'For each Quality Slot this Quality occupies, increase the duration of '
        'the Doff Bonus for doffing this piece of Apparel for the first time in '
        'a Combat Encounter by 1 Combat Round.',
  ),
  ApparelQualityDef(
    name: 'Sleek Design',
    categories: {ApparelCategory.armor},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Halve the Damage Reduction gained from this Armor. This Armor does not '
        'count towards your Apparel Penalty.',
    automation: ApparelQualityAutomation(
      excludedFromApparelPenalty: true,
      halvesArmorDamageReduction: true,
    ),
  ),
  ApparelQualityDef(
    name: 'Spiked',
    categories: {ApparelCategory.armor},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'When you are struck by an Unarmed Physical Attack from an Opponent on '
        'an adjacent Square to you, reduce their Life Points by the Apparel '
        'Bonus for this piece of Armor.',
  ),
  ApparelQualityDef(
    name: 'Stealth Suit',
    categories: {ApparelCategory.combatClothing, ApparelCategory.standardClothing},
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects: 'Increase the Dice Score of your Stealth Skill Checks by 2.',
  ),
  ApparelQualityDef(
    name: 'Stretching',
    categories: _all,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        "This piece of Apparel's Size Category is the current Size Category of "
        "this piece of Apparel's wearer.",
  ),
  ApparelQualityDef(
    name: 'Team Outfit',
    categories: _all,
    prerequisites: 'N/A',
    minSlots: 2,
    maxSlots: 2,
    effects:
        'When you select this Apparel Quality, choose a Team Name. Each Ally '
        'wearing a piece of Apparel with this Apparel Quality and the same Team '
        'Name increases their Stress Bonus by 1 (this bonus does not stack).',
  ),
  ApparelQualityDef(
    name: 'Terrifying Design',
    categories: {
      ApparelCategory.armor,
      ApparelCategory.combatClothing,
      ApparelCategory.standardClothing,
    },
    prerequisites: '2+ Skill Ranks in Intimidation',
    minSlots: 1,
    maxSlots: 1,
    effects: 'Increase the Dice Score of your Intimidation Skill Checks by 2.',
  ),
  ApparelQualityDef(
    name: 'Training Support',
    categories: {ApparelCategory.weights},
    prerequisites: '2+ Skill Ranks in the Concealment Skill',
    minSlots: 2,
    maxSlots: 2,
    effects:
        'If you possess any stacks of Holding Back while wearing this Apparel, '
        'you may ignore the reduction to your Combat Rolls from the effects of '
        'the Weight Apparel Category.',
  ),
  ApparelQualityDef(
    name: 'Weather Resistant',
    categories: _all,
    prerequisites: '2+ Skill Ranks in the Survival Skill',
    minSlots: 1,
    maxSlots: 3,
    effects:
        'When you gain this Quality, choose any type of Battle Weather. Treat '
        'the Weather Tier as if it was x Weather Tiers lower, where x is equal '
        'to the number of Quality Slots occupied by this Apparel Quality. If '
        'this would treat the Weather Tier as if it was 0 or less, completely '
        'ignore the effects of that Battle Weather.',
  ),
  // --- Special Apparel Qualities -------------------------------------------
  ApparelQualityDef(
    name: "Assassin's Craft",
    categories: _all,
    prerequisites: '2+ Skill Ranks in the Stealth Skill',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'While you are Hidden, increase your Wound Rolls by the Apparel Bonus '
        'against your Oblivious Characters.',
  ),
  ApparelQualityDef(
    name: 'Combat Ready',
    categories: _allExceptWeights,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'Increase your Strike and Dodge Rolls by 1/2 (rounded up) of your '
        'Apparel Bonus.',
    automation: ApparelQualityAutomation(
      statEffects: [
        ApparelStatEffect(
          stats: [AffectedStat.strike, AffectedStat.dodge],
          coefficient: 1,
          basis: ApparelEffectBasis.halfApparelBonusRoundUp,
        ),
      ],
    ),
  ),
  ApparelQualityDef(
    name: 'Divine Apparel',
    categories: _all,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects: 'Increase your Apparel Bonus by 1(bT).',
    automation: ApparelQualityAutomation(apparelBonusPerBaseTier: 1),
  ),
  ApparelQualityDef(
    name: 'Enchanted',
    categories: _allExceptWeights,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects: 'Increase your Soak Value by the Apparel Bonus.',
    automation: ApparelQualityAutomation(
      statEffects: [
        ApparelStatEffect(
          stats: [AffectedStat.soak],
          coefficient: 1,
          basis: ApparelEffectBasis.apparelBonus,
        ),
      ],
    ),
  ),
  ApparelQualityDef(
    name: 'Legacy',
    categories: _allExceptWeights,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'Increase the Natural Result for all Steadfast Checks and Saving Throws '
        'by 2.',
  ),
  ApparelQualityDef(
    name: 'Resolute Belief',
    categories: _all,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects: 'Increase your Stress Bonus by 2.',
  ),
  ApparelQualityDef(
    name: 'Unbreakable',
    categories: _all,
    prerequisites: 'Durable Apparel Quality',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects: 'This piece of Apparel cannot have its Break Value reduced.',
    automation: ApparelQualityAutomation(unbreakable: true),
  ),
  ApparelQualityDef(
    name: 'Yardrat Material',
    categories: _all,
    prerequisites: 'The user possesses the Spirit Control Awakening.',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'Halve the Ki Point Cost for any Unique Ability that lists the Spirit '
        'Control Awakening as a Prerequisite.',
  ),
];

/// Looks up an Apparel Quality by exact [name], or `null` if unknown.
ApparelQualityDef? apparelQualityByName(String name) {
  for (final q in kDbuApparelQualities) {
    if (q.name == name) return q;
  }
  return null;
}

/// The Qualities available to a given Apparel [category] (for the picker's
/// Category-filtered dropdown).
List<ApparelQualityDef> apparelQualitiesFor(ApparelCategory category) =>
    kDbuApparelQualities.where((q) => q.categories.contains(category)).toList();
