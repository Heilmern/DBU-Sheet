/// homebrew.dart
/// ---------------------------------------------------------------------------
/// The persisted model for a player-authored HOMEBREW entry — a custom Talent,
/// Racial Trait, Transformation, Apparel Quality, etc. that isn't in the
/// official catalogues.
///
/// DESIGN: a homebrew entry is deliberately simple — free text the player
/// writes (name / flavor / effect) PLUS a list of automated numeric effects.
/// Those automations are the EXACT same `RaceTraitAutomation` objects the rules
/// engine already consumes for catalogue content (see `data/race_traits.dart`),
/// not a parallel copy. That means:
///   • the "framework" the player automates against is the app's real
///     automation vocabulary (`AffectedStat` + magnitude kinds + conditions),
///     so it stays current automatically as more effect kinds are added, and
///   • wiring homebrew into live character sheets later is a matter of feeding
///     these automations through the existing buff pipeline — no conversion.
///
/// Beyond the shared text + automations, most categories carry a STRUCTURED
/// payload that converts into the real catalogue definition type, so homebrew
/// plugs into the same runtime machinery as official content:
///   • Race            → [HomebrewRaceData]           → `RaceDef`
///   • Condition       → [HomebrewConditionData]      → `ConditionDef`
///   • State           → [HomebrewStateData]          → `StateDef`
///   • Transformation / Enhancement / Form
///                     → [HomebrewTransformationData] → `TransformationDef`
///     (AMB table, ToP requirement, Max Stacks / Grades, Aspect labels, and
///     extra Stack-gated/Mastery Traits — the entry's own automations become
///     the def's main always-on/while-active Trait)
///   • Factor Trait    → [HomebrewFactorData]         → `FactorDef` wrapping
///     one `FactorTraitDef` (what it must replace + requirements)
///   • Apparel Quality → [HomebrewApparelQualityData] → `ApparelQualityDef`
///   • Weapon Quality  → [HomebrewWeaponQualityData]  → `WeaponQualityDef`
///   • Accessory       → [HomebrewAccessoryData]      → `AccessoryDef`
///   • Basic Item      → [HomebrewBasicItemData]      → `BasicItemDef`
///   • Signature Adv/Dis → [HomebrewSigModifierData]  → `SigModifierDef`
///   • Unique Ability  → [HomebrewUniqueAbilityData]  → `UniqueAbilityDef`
///   • Talent          → [HomebrewTalentData]         → `TalentDef` (joins
///     the Talents catalogue picker with its Talent Category)
///   • Race Traits     → [HomebrewRaceTraitData] (on the Race payload)
///                     → `RaceTraitDef` for characters of that Race
/// (Racial Trait entries stay generic on purpose: possession via
/// `homebrewSelections` IS how a standalone always-on Trait applies; Traits
/// belonging to a homebrew Race are authored ON the Race instead.)
/// The conversions live here; `data/homebrew_registry.dart` exposes the
/// resolved defs behind the same `xByName` lookups the calculator already
/// uses, with the OFFICIAL catalogue always winning a name clash.
///
/// Like `Character`, everything is JSON-serializable and tolerant of
/// missing/extra keys so old saves and shared codes keep loading.
/// ---------------------------------------------------------------------------
library;

import '../data/accessories.dart';
import '../data/apparel.dart';
import '../data/basic_items.dart';
import '../data/dbu_rules.dart';
import '../data/factor_traits.dart';
import '../data/race_traits.dart';
import '../data/signature_modifiers.dart';
import '../data/talents.dart';
import '../data/transformations.dart';
import '../data/unique_abilities.dart';
import '../data/weapons.dart';

/// What a homebrew entry represents. Every category carries the shared free
/// text + automations; `race`, `condition`, the three Transformation-like
/// categories and `factorTrait` additionally carry a structured payload that
/// converts into the real catalogue def (see the library doc above).
enum HomebrewCategory {
  talent('Talent'),
  race('Race'),
  racialTrait('Racial Trait'),
  condition('Condition'),
  state('State'),
  transformation('Transformation / Awakening'),
  enhancement('Enhancement'),
  form('Form'),
  factorTrait('Factor Trait'),
  apparelQuality('Apparel Quality'),
  weaponQuality('Weapon Quality'),
  accessory('Accessory'),
  basicItem('Basic Item'),
  signatureModifier('Signature Advantage / Disadvantage'),
  uniqueAbility('Unique Ability'),
  other('Other');

  const HomebrewCategory(this.displayName);
  final String displayName;
}

/// A character's CHOICE to possess a piece of homebrew. Stores only the pick
/// (name + whether it's currently active), never the definition — that lives in
/// the homebrew library and is resolved at compute time by
/// `HomebrewRegistry.byName`, exactly like `talentByName` resolves a Talent.
///
/// Matching is by NAME (case-insensitive), consistent with every other
/// catalogue lookup in the app, so a shared character binds to the recipient's
/// copy of the same-named homebrew.
class HomebrewSelection {
  HomebrewSelection({
    required this.name,
    this.active = true,
    this.notes = '',
  });

  String name;

  /// Whether the effect is currently applying. Always-on homebrew (a Talent)
  /// stays true; a Transformation-like one can be toggled off when not in use.
  bool active;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': active,
        if (notes.isNotEmpty) 'notes': notes,
      };

  factory HomebrewSelection.fromJson(Map<String, dynamic> json) =>
      HomebrewSelection(
        name: json['name'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        notes: json['notes'] as String? ?? '',
      );
}

/// Parses an enum value by its `.name`, falling back when absent/unknown.
T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is String) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
  }
  return fallback;
}

/// One Attribute's entry in a homebrew Transformation's AMB table —
/// the maker's editable mirror of `TransformationAmb` (flat or `(T)`;
/// Grade-table AMBs are beyond homebrew scope).
class HomebrewAmb {
  HomebrewAmb({this.coefficient = 1, this.tierScaled = false});

  int coefficient;

  /// True = the site's `+N(T)` shape (scaled by current Tier of Power).
  bool tierScaled;

  TransformationAmb toAmb() =>
      TransformationAmb(coefficient: coefficient, tierScaled: tierScaled);

  Map<String, dynamic> toJson() => {
        'coefficient': coefficient,
        'tierScaled': tierScaled,
      };

  factory HomebrewAmb.fromJson(Map<String, dynamic> json) => HomebrewAmb(
        coefficient: (json['coefficient'] as num?)?.toInt() ?? 1,
        tierScaled: json['tierScaled'] as bool? ?? false,
      );
}

/// Structured payload for a homebrew TALENT — its Talent Category (so it
/// groups correctly in the Talents catalogue picker) and Prerequisites line.
/// Together with the entry's shared text + automations it converts into a
/// real `TalentDef`, joining the Talent list / Progression picker beside the
/// official catalogue (which wins any name clash, as ever).
class HomebrewTalentData {
  HomebrewTalentData({
    this.category = TalentCategory.miscellaneous,
    this.prerequisitesText = 'N/A',
  });

  TalentCategory category;

  /// Verbatim "–Prerequisites:" line — reference text, like the catalogue's.
  String prerequisitesText;

  TalentDef toTalentDef(HomebrewEntry e) => TalentDef(
        name: e.displayName,
        category: category,
        prerequisitesText:
            prerequisitesText.trim().isEmpty ? 'N/A' : prerequisitesText,
        description: [
          if (e.flavor.trim().isNotEmpty) e.flavor.trim(),
          e.effectText,
        ].join('\n'),
        automation: List.unmodifiable(e.automations),
      );

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'prerequisitesText': prerequisitesText,
      };

  factory HomebrewTalentData.fromJson(Map<String, dynamic> json) =>
      HomebrewTalentData(
        category: _enumFrom(TalentCategory.values, json['category'],
            TalentCategory.miscellaneous),
        prerequisitesText: json['prerequisitesText'] as String? ?? 'N/A',
      );
}

/// One Racial Trait authored directly on a homebrew RACE — converts into a
/// real `RaceTraitDef`, so a character of that Race gets it exactly like an
/// official Racial Trait (Information tab, automation, Factor swaps, combat
/// reminders).
class HomebrewRaceTraitData {
  HomebrewRaceTraitData({
    this.name = '',
    this.tier = RaceTraitTier.secondary,
    this.category = TraitCategory.body,
    this.description = '',
    List<RaceTraitAutomation>? automations,
  }) : automations = automations ?? [];

  String name;
  RaceTraitTier tier;
  TraitCategory category;

  /// Verbatim flavour + numbered effects, like the catalogue's.
  String description;

  final List<RaceTraitAutomation> automations;

  RaceTraitDef toRaceTraitDef(String race) => RaceTraitDef(
        race: race,
        tier: tier,
        category: category,
        name: name.trim().isEmpty ? 'Unnamed Trait' : name.trim(),
        description: description,
        automation: List.unmodifiable(automations),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'tier': tier.name,
        'category': category.name,
        'description': description,
        'automations': [for (final a in automations) a.toJson()],
      };

  factory HomebrewRaceTraitData.fromJson(Map<String, dynamic> json) =>
      HomebrewRaceTraitData(
        name: json['name'] as String? ?? '',
        tier: _enumFrom(
            RaceTraitTier.values, json['tier'], RaceTraitTier.secondary),
        category: _enumFrom(
            TraitCategory.values, json['category'], TraitCategory.body),
        description: json['description'] as String? ?? '',
        automations: ((json['automations'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RaceTraitAutomation.fromJson)
            .toList(),
      );
}

/// Structured payload for a homebrew RACE — everything `RaceDef` needs so a
/// character can select it exactly like an official Race (Racial Life
/// Modifier into Max Life, Attribute Score Increases into `Character.scoreOf`,
/// Racial Saving Throw Bonus, Racial Skill Ranks), plus its own directly
/// authored Racial Traits (see [HomebrewRaceTraitData]).
class HomebrewRaceData {
  HomebrewRaceData({
    this.racialLifeModifier = 0,
    Map<DbuAttribute, int>? fixedAttributeIncreases,
    List<int>? choiceAmounts,
    List<DbuSavingThrow>? savingThrows,
    this.skillRanks = 0,
    List<HomebrewRaceTraitData>? traits,
  })  : fixedAttributeIncreases = fixedAttributeIncreases ?? {},
        choiceAmounts = choiceAmounts ?? [],
        savingThrows = savingThrows ?? [],
        traits = traits ?? [];

  /// Added to Life Points for each Power Level (like every official Race).
  int racialLifeModifier;

  /// Always-applied Attribute Score increases (e.g. Saiyan's +2 FO).
  final Map<DbuAttribute, int> fixedAttributeIncreases;

  /// One entry per "+N to an Attribute of your choice" slot (any Attribute —
  /// the player picks per character, like Custom Species' +2/+2/+1).
  final List<int> choiceAmounts;

  /// Which Saving Throw(s) get the Racial Saving Throw Bonus.
  final List<DbuSavingThrow> savingThrows;

  /// Racial Skill Ranks granted at Character Creation.
  int skillRanks;

  /// The Race's directly authored Racial Traits — a character of this Race
  /// gets them automatically (see `CharacterCalculator.activeRaceTraits`).
  final List<HomebrewRaceTraitData> traits;

  /// Auto-generated display text mirroring the official Races' verbatim
  /// "Attribute Score Increase" line.
  String get attributeIncreaseText {
    final parts = <String>[
      for (final e in fixedAttributeIncreases.entries)
        if (e.value != 0) '+${e.value} ${e.key.displayName}',
      for (final amount in choiceAmounts)
        '+$amount to an Attribute of your choice',
    ];
    return parts.isEmpty ? 'None' : parts.join(', ');
  }

  RaceDef toRaceDef(String name) => RaceDef(
        name,
        racialLifeModifier: racialLifeModifier,
        attributeIncreaseText: attributeIncreaseText,
        attributeIncrease: RaceAttributeIncrease(
          fixed: Map.unmodifiable(
              {for (final e in fixedAttributeIncreases.entries) e.key: e.value}),
          choices: [
            for (final amount in choiceAmounts)
              AttributeIncreaseChoice(amount: amount),
          ],
        ),
        savingThrows: List.unmodifiable(savingThrows),
        skillRanks: skillRanks,
      );

  Map<String, dynamic> toJson() => {
        'racialLifeModifier': racialLifeModifier,
        'fixedAttributeIncreases': {
          for (final e in fixedAttributeIncreases.entries) e.key.name: e.value,
        },
        'choiceAmounts': choiceAmounts,
        'savingThrows': [for (final s in savingThrows) s.name],
        'skillRanks': skillRanks,
        if (traits.isNotEmpty)
          'traits': [for (final t in traits) t.toJson()],
      };

  factory HomebrewRaceData.fromJson(Map<String, dynamic> json) {
    final fixed = <DbuAttribute, int>{};
    ((json['fixedAttributeIncreases'] as Map?) ?? const {})
        .forEach((key, value) {
      for (final attr in DbuAttribute.values) {
        if (attr.name == key) {
          fixed[attr] = (value as num?)?.toInt() ?? 0;
          break;
        }
      }
    });
    return HomebrewRaceData(
      racialLifeModifier:
          (json['racialLifeModifier'] as num?)?.toInt() ?? 0,
      fixedAttributeIncreases: fixed,
      choiceAmounts: [
        for (final v in (json['choiceAmounts'] as List?) ?? const [])
          if (v is num) v.toInt(),
      ],
      savingThrows: [
        for (final raw in (json['savingThrows'] as List?) ?? const [])
          for (final s in DbuSavingThrow.values)
            if (s.name == raw) s,
      ],
      skillRanks: (json['skillRanks'] as num?)?.toInt() ?? 0,
      traits: ((json['traits'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomebrewRaceTraitData.fromJson)
          .toList(),
    );
  }
}

/// Structured payload for a homebrew CONDITION — everything `ConditionDef`
/// needs so it joins the Character tab's Conditions tracker with its penalty
/// auto-applied per Stack (like Blinded/Winded).
class HomebrewConditionData {
  HomebrewConditionData({
    this.maxStacks = 1,
    this.penaltyPerStack = 0,
    this.tierScaling = TierScaling.none,
    List<AffectedStat>? affectedStats,
  }) : affectedStats = affectedStats ?? [];

  int maxStacks;

  /// Penalty magnitude per Stack (entered positive — Conditions only
  /// penalize; the calculator subtracts it, matching `ConditionDef`).
  int penaltyPerStack;

  TierScaling tierScaling;

  /// The stats penalized per Stack. Empty = reference-only Condition.
  final List<AffectedStat> affectedStats;

  ConditionDef toConditionDef(String name, String description) => ConditionDef(
        name,
        maxStacks: maxStacks < 1 ? 1 : maxStacks,
        description: description,
        affectedStats: List.unmodifiable(affectedStats),
        magnitudePerStack: penaltyPerStack,
        tierScaling: tierScaling,
      );

  Map<String, dynamic> toJson() => {
        'maxStacks': maxStacks,
        'penaltyPerStack': penaltyPerStack,
        'tierScaling': tierScaling.name,
        'affectedStats': [for (final s in affectedStats) s.name],
      };

  factory HomebrewConditionData.fromJson(Map<String, dynamic> json) =>
      HomebrewConditionData(
        maxStacks: (json['maxStacks'] as num?)?.toInt() ?? 1,
        penaltyPerStack: (json['penaltyPerStack'] as num?)?.toInt() ?? 0,
        tierScaling: _enumFrom(
            TierScaling.values, json['tierScaling'], TierScaling.none),
        affectedStats: [
          for (final raw in (json['affectedStats'] as List?) ?? const [])
            for (final s in AffectedStat.values)
              if (s.name == raw) s,
        ],
      );
}

/// One unlocked-at-Level Trait of a homebrew STATE — mirrors `StateTraitDef`
/// (magnitude = `coefficientPerLevel × currentLevel × tierScaling`, sign in
/// the coefficient since States buff as often as they debuff).
class HomebrewStateTraitData {
  HomebrewStateTraitData({
    this.level = 1,
    this.coefficientPerLevel = 0,
    this.tierScaling = TierScaling.none,
    List<AffectedStat>? affectedStats,
    this.ignoresHealthThresholdPenalties = false,
  }) : affectedStats = affectedStats ?? [];

  int level;
  int coefficientPerLevel;
  TierScaling tierScaling;
  final List<AffectedStat> affectedStats;
  bool ignoresHealthThresholdPenalties;

  StateTraitDef toStateTraitDef() => StateTraitDef(
        level: level < 1 ? 1 : level,
        affectedStats: List.unmodifiable(affectedStats),
        coefficientPerLevel: coefficientPerLevel,
        tierScaling: tierScaling,
        ignoresHealthThresholdPenalties: ignoresHealthThresholdPenalties,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'coefficientPerLevel': coefficientPerLevel,
        'tierScaling': tierScaling.name,
        'affectedStats': [for (final s in affectedStats) s.name],
        'ignoresHealthThresholdPenalties': ignoresHealthThresholdPenalties,
      };

  factory HomebrewStateTraitData.fromJson(Map<String, dynamic> json) =>
      HomebrewStateTraitData(
        level: (json['level'] as num?)?.toInt() ?? 1,
        coefficientPerLevel:
            (json['coefficientPerLevel'] as num?)?.toInt() ?? 0,
        tierScaling: _enumFrom(
            TierScaling.values, json['tierScaling'], TierScaling.none),
        affectedStats: [
          for (final raw in (json['affectedStats'] as List?) ?? const [])
            for (final s in AffectedStat.values)
              if (s.name == raw) s,
        ],
        ignoresHealthThresholdPenalties:
            json['ignoresHealthThresholdPenalties'] as bool? ?? false,
      );
}

/// Structured payload for a homebrew STATE — joins the Character tab's States
/// tracker with its Level-gated Traits computed live (like Raging/Undying).
class HomebrewStateData {
  HomebrewStateData({
    this.maxLevel = 1,
    List<HomebrewStateTraitData>? traits,
  }) : traits = traits ?? [];

  /// Number of Levels (1 = simply active or not).
  int maxLevel;

  final List<HomebrewStateTraitData> traits;

  StateDef toStateDef(String name, String description) => StateDef(
        name,
        maxLevel: maxLevel < 1 ? 1 : maxLevel,
        description: description,
        traits: [for (final t in traits) t.toStateTraitDef()],
      );

  Map<String, dynamic> toJson() => {
        'maxLevel': maxLevel,
        'traits': [for (final t in traits) t.toJson()],
      };

  factory HomebrewStateData.fromJson(Map<String, dynamic> json) =>
      HomebrewStateData(
        maxLevel: (json['maxLevel'] as num?)?.toInt() ?? 1,
        traits: ((json['traits'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewStateTraitData.fromJson)
            .toList(),
      );
}

/// One automated stat row of a homebrew APPAREL QUALITY (mirrors
/// `ApparelStatEffect` — basis: ×(bT), ×Apparel Bonus, ×½ Apparel Bonus).
class HomebrewApparelEffect {
  HomebrewApparelEffect({
    List<AffectedStat>? stats,
    this.coefficient = 1,
    this.basis = ApparelEffectBasis.perBaseTier,
  }) : stats = stats ?? [];

  final List<AffectedStat> stats;
  int coefficient;
  ApparelEffectBasis basis;

  ApparelStatEffect toEffect() => ApparelStatEffect(
        stats: List.unmodifiable(stats),
        coefficient: coefficient,
        basis: basis,
      );

  Map<String, dynamic> toJson() => {
        'stats': [for (final s in stats) s.name],
        'coefficient': coefficient,
        'basis': basis.name,
      };

  factory HomebrewApparelEffect.fromJson(Map<String, dynamic> json) =>
      HomebrewApparelEffect(
        stats: [
          for (final raw in (json['stats'] as List?) ?? const [])
            for (final s in AffectedStat.values)
              if (s.name == raw) s,
        ],
        coefficient: (json['coefficient'] as num?)?.toInt() ?? 1,
        basis: _enumFrom(ApparelEffectBasis.values, json['basis'],
            ApparelEffectBasis.perBaseTier),
      );
}

/// Structured payload for a homebrew APPAREL QUALITY — joins the Inventory
/// tab's Quality picker and the full Apparel automation pipeline.
class HomebrewApparelQualityData {
  HomebrewApparelQualityData({
    Set<ApparelCategory>? categories,
    this.minSlots = 1,
    this.maxSlots = 1,
    this.prerequisites = '',
    this.apparelBonusPerBaseTier = 0,
    this.breakValueBonus = 0,
    this.unbreakable = false,
    this.excludedFromApparelPenalty = false,
    this.halvesArmorDamageReduction = false,
    List<HomebrewApparelEffect>? statEffects,
  })  : categories = categories ?? ApparelCategory.values.toSet(),
        statEffects = statEffects ?? [];

  final Set<ApparelCategory> categories;
  int minSlots;
  int maxSlots;
  String prerequisites;
  int apparelBonusPerBaseTier;
  int breakValueBonus;
  bool unbreakable;
  bool excludedFromApparelPenalty;
  bool halvesArmorDamageReduction;
  final List<HomebrewApparelEffect> statEffects;

  bool get _hasAutomation =>
      apparelBonusPerBaseTier != 0 ||
      breakValueBonus != 0 ||
      unbreakable ||
      excludedFromApparelPenalty ||
      halvesArmorDamageReduction ||
      statEffects.isNotEmpty;

  ApparelQualityDef toDef(HomebrewEntry entry) => ApparelQualityDef(
        name: entry.displayName,
        categories: Set.unmodifiable(
            categories.isEmpty ? ApparelCategory.values.toSet() : categories),
        prerequisites:
            prerequisites.trim().isEmpty ? 'N/A' : prerequisites.trim(),
        minSlots: minSlots < 1 ? 1 : minSlots,
        maxSlots: maxSlots < minSlots ? minSlots : maxSlots,
        effects: entry.effectText,
        automation: !_hasAutomation
            ? null
            : ApparelQualityAutomation(
                apparelBonusPerBaseTier: apparelBonusPerBaseTier,
                breakValueBonus: breakValueBonus,
                unbreakable: unbreakable,
                excludedFromApparelPenalty: excludedFromApparelPenalty,
                halvesArmorDamageReduction: halvesArmorDamageReduction,
                statEffects: [for (final e in statEffects) e.toEffect()],
              ),
      );

  Map<String, dynamic> toJson() => {
        'categories': [for (final c in categories) c.name],
        'minSlots': minSlots,
        'maxSlots': maxSlots,
        'prerequisites': prerequisites,
        'apparelBonusPerBaseTier': apparelBonusPerBaseTier,
        'breakValueBonus': breakValueBonus,
        'unbreakable': unbreakable,
        'excludedFromApparelPenalty': excludedFromApparelPenalty,
        'halvesArmorDamageReduction': halvesArmorDamageReduction,
        'statEffects': [for (final e in statEffects) e.toJson()],
      };

  factory HomebrewApparelQualityData.fromJson(Map<String, dynamic> json) =>
      HomebrewApparelQualityData(
        categories: {
          for (final raw in (json['categories'] as List?) ?? const [])
            for (final c in ApparelCategory.values)
              if (c.name == raw) c,
        },
        minSlots: (json['minSlots'] as num?)?.toInt() ?? 1,
        maxSlots: (json['maxSlots'] as num?)?.toInt() ?? 1,
        prerequisites: json['prerequisites'] as String? ?? '',
        apparelBonusPerBaseTier:
            (json['apparelBonusPerBaseTier'] as num?)?.toInt() ?? 0,
        breakValueBonus: (json['breakValueBonus'] as num?)?.toInt() ?? 0,
        unbreakable: json['unbreakable'] as bool? ?? false,
        excludedFromApparelPenalty:
            json['excludedFromApparelPenalty'] as bool? ?? false,
        halvesArmorDamageReduction:
            json['halvesArmorDamageReduction'] as bool? ?? false,
        statEffects: ((json['statEffects'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewApparelEffect.fromJson)
            .toList(),
      );
}

/// One automated Strike/Wound row of a homebrew WEAPON QUALITY (mirrors
/// `WeaponStatEffect` — per-Attack while wielded, optionally ×Slots).
class HomebrewWeaponEffect {
  HomebrewWeaponEffect({
    this.target = WeaponEffectTarget.wound,
    this.coefficient = 1,
    this.basis = WeaponEffectBasis.perTier,
    this.perSlot = false,
  });

  WeaponEffectTarget target;
  int coefficient;
  WeaponEffectBasis basis;
  bool perSlot;

  WeaponStatEffect toEffect() => WeaponStatEffect(
        target: target,
        coefficient: coefficient,
        basis: basis,
        perSlot: perSlot,
      );

  Map<String, dynamic> toJson() => {
        'target': target.name,
        'coefficient': coefficient,
        'basis': basis.name,
        'perSlot': perSlot,
      };

  factory HomebrewWeaponEffect.fromJson(Map<String, dynamic> json) =>
      HomebrewWeaponEffect(
        target: _enumFrom(WeaponEffectTarget.values, json['target'],
            WeaponEffectTarget.wound),
        coefficient: (json['coefficient'] as num?)?.toInt() ?? 1,
        basis: _enumFrom(
            WeaponEffectBasis.values, json['basis'], WeaponEffectBasis.perTier),
        perSlot: json['perSlot'] as bool? ?? false,
      );
}

/// Structured payload for a homebrew WEAPON QUALITY — joins the Inventory
/// tab's Weapon Quality picker and the Weapon automation pipeline.
class HomebrewWeaponQualityData {
  HomebrewWeaponQualityData({
    Set<WeaponType>? types,
    this.minSlots = 1,
    this.maxSlots = 1,
    this.prerequisites = '',
    this.lifePointsPerLevel = 0,
    this.lifePointsPerLevelPerSlot = false,
    this.damageReductionPerBaseTier = 0,
    this.unbreakable = false,
    List<HomebrewWeaponEffect>? statEffects,
  })  : types = types ?? WeaponType.values.toSet(),
        statEffects = statEffects ?? [];

  final Set<WeaponType> types;
  int minSlots;
  int maxSlots;
  String prerequisites;
  int lifePointsPerLevel;
  bool lifePointsPerLevelPerSlot;
  int damageReductionPerBaseTier;
  bool unbreakable;
  final List<HomebrewWeaponEffect> statEffects;

  bool get _hasAutomation =>
      lifePointsPerLevel != 0 ||
      damageReductionPerBaseTier != 0 ||
      unbreakable ||
      statEffects.isNotEmpty;

  WeaponQualityDef toDef(HomebrewEntry entry) => WeaponQualityDef(
        name: entry.displayName,
        types: Set.unmodifiable(
            types.isEmpty ? WeaponType.values.toSet() : types),
        prerequisites:
            prerequisites.trim().isEmpty ? 'N/A' : prerequisites.trim(),
        minSlots: minSlots < 1 ? 1 : minSlots,
        maxSlots: maxSlots < minSlots ? minSlots : maxSlots,
        effects: entry.effectText,
        automation: !_hasAutomation
            ? null
            : WeaponQualityAutomation(
                statEffects: [for (final e in statEffects) e.toEffect()],
                lifePointsPerLevel: lifePointsPerLevel,
                lifePointsPerLevelPerSlot: lifePointsPerLevelPerSlot,
                damageReductionPerBaseTier: damageReductionPerBaseTier,
                unbreakable: unbreakable,
              ),
      );

  Map<String, dynamic> toJson() => {
        'types': [for (final t in types) t.name],
        'minSlots': minSlots,
        'maxSlots': maxSlots,
        'prerequisites': prerequisites,
        'lifePointsPerLevel': lifePointsPerLevel,
        'lifePointsPerLevelPerSlot': lifePointsPerLevelPerSlot,
        'damageReductionPerBaseTier': damageReductionPerBaseTier,
        'unbreakable': unbreakable,
        'statEffects': [for (final e in statEffects) e.toJson()],
      };

  factory HomebrewWeaponQualityData.fromJson(Map<String, dynamic> json) =>
      HomebrewWeaponQualityData(
        types: {
          for (final raw in (json['types'] as List?) ?? const [])
            for (final t in WeaponType.values)
              if (t.name == raw) t,
        },
        minSlots: (json['minSlots'] as num?)?.toInt() ?? 1,
        maxSlots: (json['maxSlots'] as num?)?.toInt() ?? 1,
        prerequisites: json['prerequisites'] as String? ?? '',
        lifePointsPerLevel: (json['lifePointsPerLevel'] as num?)?.toInt() ?? 0,
        lifePointsPerLevelPerSlot:
            json['lifePointsPerLevelPerSlot'] as bool? ?? false,
        damageReductionPerBaseTier:
            (json['damageReductionPerBaseTier'] as num?)?.toInt() ?? 0,
        unbreakable: json['unbreakable'] as bool? ?? false,
        statEffects: ((json['statEffects'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewWeaponEffect.fromJson)
            .toList(),
      );
}

/// One automated stat row of a homebrew ACCESSORY (unconditional while
/// equipped, ×(bT) or ×(T)).
class HomebrewAccessoryEffect {
  HomebrewAccessoryEffect({
    List<AffectedStat>? stats,
    this.coefficient = 1,
    this.basis = AccessoryEffectBasis.perBaseTier,
  }) : stats = stats ?? [];

  final List<AffectedStat> stats;
  int coefficient;
  AccessoryEffectBasis basis;

  AccessoryStatEffect toEffect() => AccessoryStatEffect(
        stats: List.unmodifiable(stats),
        coefficient: coefficient,
        basis: basis,
      );

  Map<String, dynamic> toJson() => {
        'stats': [for (final s in stats) s.name],
        'coefficient': coefficient,
        'basis': basis.name,
      };

  factory HomebrewAccessoryEffect.fromJson(Map<String, dynamic> json) =>
      HomebrewAccessoryEffect(
        stats: [
          for (final raw in (json['stats'] as List?) ?? const [])
            for (final s in AffectedStat.values)
              if (s.name == raw) s,
        ],
        coefficient: (json['coefficient'] as num?)?.toInt() ?? 1,
        basis: _enumFrom(AccessoryEffectBasis.values, json['basis'],
            AccessoryEffectBasis.perBaseTier),
      );
}

/// Structured payload for a homebrew ACCESSORY — joins the Inventory tab's
/// Accessories catalogue picker with its while-equipped automation.
class HomebrewAccessoryData {
  HomebrewAccessoryData({
    this.craftDc = '',
    this.isTech = false,
    this.damageReductionPerBaseTier = 0,
    List<HomebrewAccessoryEffect>? statEffects,
  }) : statEffects = statEffects ?? [];

  /// Craft DC Difficulty Category text (e.g. "Apprentice"); '' = not
  /// craftable (a Special Accessory).
  String craftDc;
  bool isTech;
  int damageReductionPerBaseTier;
  final List<HomebrewAccessoryEffect> statEffects;

  bool get _hasAutomation =>
      damageReductionPerBaseTier != 0 || statEffects.isNotEmpty;

  AccessoryDef toDef(HomebrewEntry entry) => AccessoryDef(
        name: entry.displayName,
        craftDc: craftDc.trim(),
        description: entry.flavor,
        effects: entry.effectText,
        isTech: isTech,
        isSpecial: craftDc.trim().isEmpty,
        automation: !_hasAutomation
            ? null
            : AccessoryAutomation(
                statEffects: [for (final e in statEffects) e.toEffect()],
                damageReductionPerBaseTier: damageReductionPerBaseTier,
              ),
      );

  Map<String, dynamic> toJson() => {
        'craftDc': craftDc,
        'isTech': isTech,
        'damageReductionPerBaseTier': damageReductionPerBaseTier,
        'statEffects': [for (final e in statEffects) e.toJson()],
      };

  factory HomebrewAccessoryData.fromJson(Map<String, dynamic> json) =>
      HomebrewAccessoryData(
        craftDc: json['craftDc'] as String? ?? '',
        isTech: json['isTech'] as bool? ?? false,
        damageReductionPerBaseTier:
            (json['damageReductionPerBaseTier'] as num?)?.toInt() ?? 0,
        statEffects: ((json['statEffects'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewAccessoryEffect.fromJson)
            .toList(),
      );
}

/// Structured payload for a homebrew BASIC ITEM — a reference catalogue entry
/// (Action-triggered, no automation by design, like the official ones).
class HomebrewBasicItemData {
  HomebrewBasicItemData({
    this.craftDc = '',
    List<String>? tags,
  }) : tags = tags ?? [];

  /// Craft DC Difficulty Category text; '' = a Special Basic Item.
  String craftDc;

  /// 'Tech' / 'Med' / 'Food' tags.
  final List<String> tags;

  BasicItemDef toDef(HomebrewEntry entry) => BasicItemDef(
        name: entry.displayName,
        craftDc: craftDc.trim(),
        description: entry.flavor,
        effects: entry.effectText,
        tags: List.unmodifiable(tags),
        isSpecial: craftDc.trim().isEmpty,
      );

  Map<String, dynamic> toJson() => {
        'craftDc': craftDc,
        'tags': tags,
      };

  factory HomebrewBasicItemData.fromJson(Map<String, dynamic> json) =>
      HomebrewBasicItemData(
        craftDc: json['craftDc'] as String? ?? '',
        tags: [
          for (final t in (json['tags'] as List?) ?? const [])
            if (t is String) t,
        ],
      );
}

/// One automated per-rank Strike/Wound row of a homebrew SIGNATURE MODIFIER.
class HomebrewSigEffect {
  HomebrewSigEffect({
    this.target = SigEffectTarget.wound,
    this.coefficientPerRank = 1,
    this.basis = SigEffectBasis.perTier,
  });

  SigEffectTarget target;

  /// Applied `coefficientPerRank × rank × Tier` (sign included — an
  /// Advantage buffs, a Disadvantage debuffs).
  int coefficientPerRank;
  SigEffectBasis basis;

  SigStatEffect toEffect() => SigStatEffect(
        target: target,
        coefficientPerRank: coefficientPerRank,
        basis: basis,
      );

  Map<String, dynamic> toJson() => {
        'target': target.name,
        'coefficientPerRank': coefficientPerRank,
        'basis': basis.name,
      };

  factory HomebrewSigEffect.fromJson(Map<String, dynamic> json) =>
      HomebrewSigEffect(
        target: _enumFrom(
            SigEffectTarget.values, json['target'], SigEffectTarget.wound),
        coefficientPerRank:
            (json['coefficientPerRank'] as num?)?.toInt() ?? 1,
        basis: _enumFrom(
            SigEffectBasis.values, json['basis'], SigEffectBasis.perTier),
      );
}

/// Structured payload for a homebrew SIGNATURE ADVANTAGE / DISADVANTAGE —
/// joins the Signatures tab's modifier pickers with its per-rank TP cost and
/// automated Strike/Wound/KP effects.
class HomebrewSigModifierData {
  HomebrewSigModifierData({
    this.isDisadvantage = false,
    List<int>? tpCostsPerRank,
    this.requirement = '',
    this.ultimateOnly = false,
    this.kpPerTierPerRank = 0,
    List<HomebrewSigEffect>? statEffects,
  })  : tpCostsPerRank = tpCostsPerRank ?? [2],
        statEffects = statEffects ?? [];

  bool isDisadvantage;

  /// TP magnitude of each rank, entered POSITIVE; [toDef] applies the sign
  /// (positive Advantage cost / negative Disadvantage reduction), matching
  /// the catalogue convention. Length = max rank.
  final List<int> tpCostsPerRank;

  String requirement;
  bool ultimateOnly;

  /// KP Cost change `× rank × Tier` (Efficiency-style; sign included).
  int kpPerTierPerRank;

  final List<HomebrewSigEffect> statEffects;

  bool get _hasAutomation => kpPerTierPerRank != 0 || statEffects.isNotEmpty;

  SigModifierDef toDef(HomebrewEntry entry) => SigModifierDef(
        name: entry.displayName,
        category: isDisadvantage
            ? SigModifierCategory.miscDis
            : SigModifierCategory.miscAdv,
        description: entry.flavor,
        tpCostsPerRank: [
          for (final tp in tpCostsPerRank.isEmpty ? [2] : tpCostsPerRank)
            isDisadvantage ? -tp.abs() : tp.abs(),
        ],
        requirement: requirement.trim().isEmpty ? 'N/A' : requirement.trim(),
        effect: entry.effectText,
        ultimateOnly: ultimateOnly,
        automation: !_hasAutomation
            ? null
            : SigModifierAutomation(
                statEffects: [for (final e in statEffects) e.toEffect()],
                kpPerTierPerRank: kpPerTierPerRank,
              ),
      );

  Map<String, dynamic> toJson() => {
        'isDisadvantage': isDisadvantage,
        'tpCostsPerRank': tpCostsPerRank,
        'requirement': requirement,
        'ultimateOnly': ultimateOnly,
        'kpPerTierPerRank': kpPerTierPerRank,
        'statEffects': [for (final e in statEffects) e.toJson()],
      };

  factory HomebrewSigModifierData.fromJson(Map<String, dynamic> json) =>
      HomebrewSigModifierData(
        isDisadvantage: json['isDisadvantage'] as bool? ?? false,
        tpCostsPerRank: [
          for (final v in (json['tpCostsPerRank'] as List?) ?? const [])
            if (v is num) v.toInt(),
        ],
        requirement: json['requirement'] as String? ?? '',
        ultimateOnly: json['ultimateOnly'] as bool? ?? false,
        kpPerTierPerRank: (json['kpPerTierPerRank'] as num?)?.toInt() ?? 0,
        statEffects: ((json['statEffects'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewSigEffect.fromJson)
            .toList(),
      );
}

/// One Advancement of a homebrew Unique Ability — mirrors `UaAdvancementDef`
/// (bought with TP on top of the ability; can reduce its KP Cost).
class HomebrewUaAdvancementData {
  HomebrewUaAdvancementData({
    this.name = '',
    this.tpCost = 2,
    this.kpReductionPerTier = 0,
    this.prerequisites = '',
    this.effect = '',
  });

  String name;
  int tpCost;

  /// `x` when the Advancement reduces the ability's KP Cost by `x(T)`.
  int kpReductionPerTier;

  String prerequisites;
  String effect;

  UaAdvancementDef toDef() => UaAdvancementDef(
        name: name.trim().isEmpty ? 'Advancement' : name.trim(),
        description: '',
        prerequisites:
            prerequisites.trim().isEmpty ? 'N/A' : prerequisites.trim(),
        tpCost: tpCost < 0 ? 0 : tpCost,
        effect: effect,
        kpReductionPerTier: kpReductionPerTier,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'tpCost': tpCost,
        'kpReductionPerTier': kpReductionPerTier,
        'prerequisites': prerequisites,
        'effect': effect,
      };

  factory HomebrewUaAdvancementData.fromJson(Map<String, dynamic> json) =>
      HomebrewUaAdvancementData(
        name: json['name'] as String? ?? '',
        tpCost: (json['tpCost'] as num?)?.toInt() ?? 2,
        kpReductionPerTier:
            (json['kpReductionPerTier'] as num?)?.toInt() ?? 0,
        prerequisites: json['prerequisites'] as String? ?? '',
        effect: json['effect'] as String? ?? '',
      );
}

/// Structured payload for a homebrew UNIQUE ABILITY — joins the Unique
/// Abilities tab's catalogue picker with its TP/KP cost math, including its
/// own authored [advancements] (Restrictions stay out of scope — describe
/// them in the effect text).
class HomebrewUniqueAbilityData {
  HomebrewUniqueAbilityData({
    Set<UniqueAbilityType>? types,
    this.prerequisites = '',
    this.baseTpCost = 4,
    this.kpPerTier,
    this.kpUsesBaseTier = false,
    this.kpCostText = '',
    this.maneuverType = '',
    this.actionCost = '',
    this.passiveBonus = '',
    List<HomebrewUaAdvancementData>? advancements,
  })  : types = types ?? {UniqueAbilityType.technical},
        advancements = advancements ?? [];

  /// Technical / Magical (or both — the character then picks one).
  final Set<UniqueAbilityType> types;

  String prerequisites;
  int baseTpCost;

  /// Clean `x(T)`/`x(bT)` KP-cost coefficient, or null for a non-numeric
  /// cost described by [kpCostText] (reference only, like "Your entire
  /// Capacity").
  int? kpPerTier;
  bool kpUsesBaseTier;

  /// Freeform KP-cost text shown when [kpPerTier] is null; auto-derived
  /// (`"N(T)"`) when it is set.
  String kpCostText;

  String maneuverType;
  String actionCost;
  String passiveBonus;

  /// The ability's own Advancements (each bought with TP, and able to
  /// reduce the KP Cost — the cost engine treats them exactly like
  /// catalogue Advancements).
  final List<HomebrewUaAdvancementData> advancements;

  UniqueAbilityDef toDef(HomebrewEntry entry) => UniqueAbilityDef(
        name: entry.displayName,
        description: entry.flavor,
        types: Set.unmodifiable(
            types.isEmpty ? {UniqueAbilityType.technical} : types),
        prerequisites:
            prerequisites.trim().isEmpty ? 'N/A' : prerequisites.trim(),
        baseTpCost: baseTpCost < 0 ? 0 : baseTpCost,
        kpCostText: kpPerTier != null
            ? '$kpPerTier(${kpUsesBaseTier ? 'bT' : 'T'})'
            : (kpCostText.trim().isEmpty ? 'N/A' : kpCostText.trim()),
        kpPerTier: kpPerTier,
        kpUsesBaseTier: kpUsesBaseTier,
        maneuverType:
            maneuverType.trim().isEmpty ? 'N/A' : maneuverType.trim(),
        actionCost: actionCost.trim().isEmpty ? 'N/A' : actionCost.trim(),
        minions: 'N/A',
        passiveBonus:
            passiveBonus.trim().isEmpty ? 'N/A' : passiveBonus.trim(),
        effect: entry.effectText,
        advancements: [for (final a in advancements) a.toDef()],
      );

  Map<String, dynamic> toJson() => {
        'types': [for (final t in types) t.name],
        'prerequisites': prerequisites,
        'baseTpCost': baseTpCost,
        if (kpPerTier != null) 'kpPerTier': kpPerTier,
        'kpUsesBaseTier': kpUsesBaseTier,
        'kpCostText': kpCostText,
        'maneuverType': maneuverType,
        'actionCost': actionCost,
        'passiveBonus': passiveBonus,
        'advancements': [for (final a in advancements) a.toJson()],
      };

  factory HomebrewUniqueAbilityData.fromJson(Map<String, dynamic> json) =>
      HomebrewUniqueAbilityData(
        types: {
          for (final raw in (json['types'] as List?) ?? const [])
            for (final t in UniqueAbilityType.values)
              if (t.name == raw) t,
        },
        prerequisites: json['prerequisites'] as String? ?? '',
        baseTpCost: (json['baseTpCost'] as num?)?.toInt() ?? 4,
        kpPerTier: (json['kpPerTier'] as num?)?.toInt(),
        kpUsesBaseTier: json['kpUsesBaseTier'] as bool? ?? false,
        kpCostText: json['kpCostText'] as String? ?? '',
        maneuverType: json['maneuverType'] as String? ?? '',
        actionCost: json['actionCost'] as String? ?? '',
        passiveBonus: json['passiveBonus'] as String? ?? '',
        advancements: ((json['advancements'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HomebrewUaAdvancementData.fromJson)
            .toList(),
      );
}

/// An EXTRA Trait of a homebrew Transformation, beyond the main one built
/// from the entry's effect text: its own name, verbatim text, automations,
/// and gating — a Stack requirement (`minStacks`, the site's "(2)"/"(3)"
/// suffix) or Mastery ([isMastery] — unlocked by the recorded Mastery level,
/// like any catalogue Mastery Trait).
class HomebrewTraitData {
  HomebrewTraitData({
    this.name = '',
    this.description = '',
    this.minStacks = 1,
    this.isMastery = false,
    List<RaceTraitAutomation>? automations,
  }) : automations = automations ?? [];

  String name;
  String description;
  int minStacks;
  bool isMastery;
  final List<RaceTraitAutomation> automations;

  TransformationTrait toTrait() => TransformationTrait(
        name: name.trim().isEmpty ? 'Trait' : name.trim(),
        description: description,
        minStacks: minStacks < 1 ? 1 : minStacks,
        automation: List.unmodifiable(automations),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'minStacks': minStacks,
        'isMastery': isMastery,
        'automations': [for (final a in automations) a.toJson()],
      };

  factory HomebrewTraitData.fromJson(Map<String, dynamic> json) =>
      HomebrewTraitData(
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        minStacks: (json['minStacks'] as num?)?.toInt() ?? 1,
        isMastery: json['isMastery'] as bool? ?? false,
        automations: ((json['automations'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RaceTraitAutomation.fromJson)
            .toList(),
      );
}

/// Structured payload for a homebrew TRANSFORMATION (Awakening, Enhancement
/// or Form — the entry's [HomebrewCategory] decides which). Converts into a
/// real `TransformationDef`, so the whole Transformation pipeline applies
/// unmodified: an Awakening's AMB is always-on × Stacks, an Enhancement/
/// Form's applies while Active, a Form adds the Ki Multiplier, and the
/// entry's effect text + automations become its single Trait (always-on for
/// an Awakening, while-active otherwise — the standard gating).
class HomebrewTransformationData {
  HomebrewTransformationData({
    this.awakeningType = AwakeningType.lesser,
    this.formType = FormType.alternate,
    this.tierOfPowerRequirement = 1,
    this.racialRequirement = 'Any',
    this.prerequisiteText = '',
    this.maxStacks = 1,
    this.maxGrade = 1,
    Map<DbuAttribute, HomebrewAmb>? amb,
    List<String>? aspects,
    List<HomebrewTraitData>? extraTraits,
  })  : amb = amb ?? {},
        aspects = aspects ?? [],
        extraTraits = extraTraits ?? [];

  /// Which Awakening menu this belongs to (category `transformation` only).
  AwakeningType awakeningType;

  /// Alternate vs Legendary (category `form` only).
  FormType formType;

  /// Verbatim-style "Tier of Power Requirement." minimum.
  int tierOfPowerRequirement;

  /// "Racial Requirement:" — 'Any' or an exact Race name (matched like the
  /// official catalogue's eligibility filter).
  String racialRequirement;

  /// "Prerequisite(s):" — reference text, not enforced (site convention).
  String prerequisiteText;

  /// Maximum No of Stacks (Awakenings only).
  int maxStacks;

  /// Grades: 1 = not Graded; >1 marks the def with a `Graded (N)` Aspect so
  /// the Transformations tab shows its Grade stepper.
  int maxGrade;

  /// The Attribute Modifier Bonus table (absent Attribute = no bonus).
  final Map<DbuAttribute, HomebrewAmb> amb;

  /// Aspect labels exactly as the site prints them (e.g. 'Enhanced Save
  /// (Corporeal)', 'Raging', 'High Speed'). The automated Aspects apply via
  /// the same `aspectTotals` machinery as catalogue Transformations; the
  /// rest render as reference chips.
  final List<String> aspects;

  /// Extra Traits beyond the main one (Stack-gated / Mastery Traits).
  final List<HomebrewTraitData> extraTraits;

  TransformationDef toTransformationDef(HomebrewEntry entry) {
    final type = switch (entry.category) {
      HomebrewCategory.enhancement => TransformationType.enhancement,
      HomebrewCategory.form => TransformationType.form,
      _ => TransformationType.awakening,
    };
    final trait = entry.effectText.trim().isEmpty && entry.automations.isEmpty
        ? null
        : TransformationTrait(
            name: entry.displayName,
            description: entry.effectText,
            automation: List.unmodifiable(entry.automations),
          );
    final cleanAspects = [
      for (final a in aspects)
        if (a.trim().isNotEmpty) a.trim(),
    ];
    return TransformationDef(
      name: entry.displayName,
      type: type,
      racialRequirement:
          racialRequirement.trim().isEmpty ? 'Any' : racialRequirement.trim(),
      tierOfPowerRequirement: tierOfPowerRequirement < 1
          ? 1
          : tierOfPowerRequirement,
      prerequisiteText:
          prerequisiteText.trim().isEmpty ? 'N/A' : prerequisiteText.trim(),
      aspects: [
        ...cleanAspects,
        // The Grades field implies the Graded Aspect (which drives the Grade
        // stepper) unless the author already listed one explicitly.
        if (maxGrade > 1 && !cleanAspects.any((a) => a.startsWith('Graded')))
          'Graded ($maxGrade)',
      ],
      amb: {for (final e in amb.entries) e.key: e.value.toAmb()},
      traits: [
        ?trait,
        for (final t in extraTraits)
          if (!t.isMastery) t.toTrait(),
      ],
      masteryTraits: [
        for (final t in extraTraits)
          if (t.isMastery) t.toTrait(),
      ],
      awakeningType:
          type == TransformationType.awakening ? awakeningType : null,
      maxStacks:
          type == TransformationType.awakening && maxStacks > 1 ? maxStacks : 1,
      formType: type == TransformationType.form ? formType : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'awakeningType': awakeningType.name,
        'formType': formType.name,
        'tierOfPowerRequirement': tierOfPowerRequirement,
        'racialRequirement': racialRequirement,
        'prerequisiteText': prerequisiteText,
        'maxStacks': maxStacks,
        'maxGrade': maxGrade,
        'amb': {for (final e in amb.entries) e.key.name: e.value.toJson()},
        'aspects': aspects,
        'extraTraits': [for (final t in extraTraits) t.toJson()],
      };

  factory HomebrewTransformationData.fromJson(Map<String, dynamic> json) {
    final amb = <DbuAttribute, HomebrewAmb>{};
    ((json['amb'] as Map?) ?? const {}).forEach((key, value) {
      if (value is! Map) return;
      for (final attr in DbuAttribute.values) {
        if (attr.name == key) {
          amb[attr] = HomebrewAmb.fromJson(Map<String, dynamic>.from(value));
          break;
        }
      }
    });
    return HomebrewTransformationData(
      awakeningType: _enumFrom(
          AwakeningType.values, json['awakeningType'], AwakeningType.lesser),
      formType:
          _enumFrom(FormType.values, json['formType'], FormType.alternate),
      tierOfPowerRequirement:
          (json['tierOfPowerRequirement'] as num?)?.toInt() ?? 1,
      racialRequirement: json['racialRequirement'] as String? ?? 'Any',
      prerequisiteText: json['prerequisiteText'] as String? ?? '',
      maxStacks: (json['maxStacks'] as num?)?.toInt() ?? 1,
      maxGrade: (json['maxGrade'] as num?)?.toInt() ?? 1,
      amb: amb,
      aspects: [
        for (final a in (json['aspects'] as List?) ?? const [])
          if (a is String) a,
      ],
      extraTraits: ((json['extraTraits'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomebrewTraitData.fromJson)
          .toList(),
    );
  }
}

/// Structured payload for a homebrew FACTOR TRAIT — what it may replace and
/// its requirements. Converts into a one-Trait `FactorDef`, so the homebrew
/// Factor Trait appears in the Information tab's structured "Swap for
/// Factor" picker under the same replacement rules as official Factors
/// (any Secondary Racial Trait by default, or exactly
/// [mustReplaceTraitName] — even a Primary — when set).
class HomebrewFactorData {
  HomebrewFactorData({
    this.mustReplaceTraitName = '',
    this.racialRequirement = '',
    this.prerequisiteText = '',
    this.maxFactor = 1,
  });

  /// Empty = the default rule (replaces any Secondary Racial Trait of the
  /// player's choice). Set = must replace the Racial Trait of exactly this
  /// name (may be Primary), per the site's brackets convention.
  String mustReplaceTraitName;

  /// Empty = Any. Set = only a character of exactly this Race may take it.
  String racialRequirement;

  /// Reference text, shown as the Factor's Prerequisite(s) line.
  String prerequisiteText;

  /// How many times this Factor can be taken ("Maximum Factor").
  int maxFactor;

  FactorDef toFactorDef(HomebrewEntry entry) {
    final race = racialRequirement.trim();
    return FactorDef(
      name: entry.displayName,
      description: entry.flavor,
      racialRequirementText: race.isEmpty ? 'Any' : race,
      allowedRaces: race.isEmpty ? const [] : [race],
      maxFactor: maxFactor < 1 ? 1 : maxFactor,
      prerequisiteText:
          prerequisiteText.trim().isEmpty ? 'N/A' : prerequisiteText.trim(),
      traits: [
        FactorTraitDef(
          name: entry.displayName,
          category: TraitCategory.body,
          description: entry.effectText,
          automation: List.unmodifiable(entry.automations),
          mustReplaceTraitName: mustReplaceTraitName.trim().isEmpty
              ? null
              : mustReplaceTraitName.trim(),
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'mustReplaceTraitName': mustReplaceTraitName,
        'racialRequirement': racialRequirement,
        'prerequisiteText': prerequisiteText,
        'maxFactor': maxFactor,
      };

  factory HomebrewFactorData.fromJson(Map<String, dynamic> json) =>
      HomebrewFactorData(
        mustReplaceTraitName: json['mustReplaceTraitName'] as String? ?? '',
        racialRequirement: json['racialRequirement'] as String? ?? '',
        prerequisiteText: json['prerequisiteText'] as String? ?? '',
        maxFactor: (json['maxFactor'] as num?)?.toInt() ?? 1,
      );
}

/// A single player-authored homebrew entry.
class HomebrewEntry {
  HomebrewEntry({
    required this.id,
    this.category = HomebrewCategory.other,
    this.name = '',
    this.flavor = '',
    this.effectText = '',
    List<RaceTraitAutomation>? automations,
    HomebrewTalentData? talentData,
    HomebrewRaceData? raceData,
    HomebrewConditionData? conditionData,
    HomebrewStateData? stateData,
    HomebrewTransformationData? transformationData,
    HomebrewFactorData? factorData,
    HomebrewApparelQualityData? apparelQualityData,
    HomebrewWeaponQualityData? weaponQualityData,
    HomebrewAccessoryData? accessoryData,
    HomebrewBasicItemData? basicItemData,
    HomebrewSigModifierData? sigModifierData,
    HomebrewUniqueAbilityData? uniqueAbilityData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : automations = automations ?? [],
        talentData = talentData ?? HomebrewTalentData(),
        raceData = raceData ?? HomebrewRaceData(),
        conditionData = conditionData ?? HomebrewConditionData(),
        stateData = stateData ?? HomebrewStateData(),
        transformationData = transformationData ?? HomebrewTransformationData(),
        factorData = factorData ?? HomebrewFactorData(),
        apparelQualityData = apparelQualityData ?? HomebrewApparelQualityData(),
        weaponQualityData = weaponQualityData ?? HomebrewWeaponQualityData(),
        accessoryData = accessoryData ?? HomebrewAccessoryData(),
        basicItemData = basicItemData ?? HomebrewBasicItemData(),
        sigModifierData = sigModifierData ?? HomebrewSigModifierData(),
        uniqueAbilityData = uniqueAbilityData ?? HomebrewUniqueAbilityData(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  HomebrewCategory category;

  /// The homebrew's name (its title).
  String name;

  /// Free-form flavor/lore text (optional).
  String flavor;

  /// Verbatim rules/effect text — the full written effect, exactly as the
  /// player wants it recorded (mirrors how catalogue effects are transcribed).
  String effectText;

  /// The mechanically-automated numeric effects, authored via the maker's
  /// dropdowns. Empty = a pure reference entry (text only), like a Basic Item.
  /// For a Transformation-like entry these become its single Trait's
  /// automation; for a Factor Trait, the Factor Trait's automation.
  final List<RaceTraitAutomation> automations;

  /// Structured per-category payloads (see the library doc). All are always
  /// present so the maker can edit them freely; only the one matching
  /// [category] is consulted at runtime, and each is serialized only when its
  /// category is selected (keeping shared codes lean).
  final HomebrewTalentData talentData;
  final HomebrewRaceData raceData;
  final HomebrewConditionData conditionData;
  final HomebrewStateData stateData;
  final HomebrewTransformationData transformationData;
  final HomebrewFactorData factorData;
  final HomebrewApparelQualityData apparelQualityData;
  final HomebrewWeaponQualityData weaponQualityData;
  final HomebrewAccessoryData accessoryData;
  final HomebrewBasicItemData basicItemData;
  final HomebrewSigModifierData sigModifierData;
  final HomebrewUniqueAbilityData uniqueAbilityData;

  /// Whether [category] makes this entry a Transformation of some kind.
  bool get isTransformationLike =>
      category == HomebrewCategory.transformation ||
      category == HomebrewCategory.enhancement ||
      category == HomebrewCategory.form;

  DateTime createdAt;
  DateTime updatedAt;

  String get displayName =>
      name.trim().isEmpty ? 'Unnamed ${category.displayName}' : name.trim();

  factory HomebrewEntry.blank(String id) => HomebrewEntry(id: id);

  /// A deep, independent copy (used by the editor's working draft).
  HomebrewEntry copy() => HomebrewEntry.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'name': name,
        'flavor': flavor,
        'effectText': effectText,
        'automations': automations.map((a) => a.toJson()).toList(),
        if (category == HomebrewCategory.talent)
          'talentData': talentData.toJson(),
        if (category == HomebrewCategory.race) 'raceData': raceData.toJson(),
        if (category == HomebrewCategory.condition)
          'conditionData': conditionData.toJson(),
        if (category == HomebrewCategory.state)
          'stateData': stateData.toJson(),
        if (isTransformationLike)
          'transformationData': transformationData.toJson(),
        if (category == HomebrewCategory.factorTrait)
          'factorData': factorData.toJson(),
        if (category == HomebrewCategory.apparelQuality)
          'apparelQualityData': apparelQualityData.toJson(),
        if (category == HomebrewCategory.weaponQuality)
          'weaponQualityData': weaponQualityData.toJson(),
        if (category == HomebrewCategory.accessory)
          'accessoryData': accessoryData.toJson(),
        if (category == HomebrewCategory.basicItem)
          'basicItemData': basicItemData.toJson(),
        if (category == HomebrewCategory.signatureModifier)
          'sigModifierData': sigModifierData.toJson(),
        if (category == HomebrewCategory.uniqueAbility)
          'uniqueAbilityData': uniqueAbilityData.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory HomebrewEntry.fromJson(Map<String, dynamic> json) {
    final category =
        _enumFrom(HomebrewCategory.values, json['category'], HomebrewCategory.other);
    final autos = ((json['automations'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RaceTraitAutomation.fromJson)
        .toList();
    Map<String, dynamic>? sub(String key) {
      final raw = json[key];
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    }

    T? parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = sub(key);
      return raw == null ? null : fromJson(raw);
    }

    return HomebrewEntry(
      id: json['id'] as String? ?? '',
      category: category,
      name: json['name'] as String? ?? '',
      flavor: json['flavor'] as String? ?? '',
      effectText: json['effectText'] as String? ?? '',
      automations: autos,
      talentData: parse('talentData', HomebrewTalentData.fromJson),
      raceData: parse('raceData', HomebrewRaceData.fromJson),
      conditionData: parse('conditionData', HomebrewConditionData.fromJson),
      stateData: parse('stateData', HomebrewStateData.fromJson),
      transformationData:
          parse('transformationData', HomebrewTransformationData.fromJson),
      factorData: parse('factorData', HomebrewFactorData.fromJson),
      apparelQualityData:
          parse('apparelQualityData', HomebrewApparelQualityData.fromJson),
      weaponQualityData:
          parse('weaponQualityData', HomebrewWeaponQualityData.fromJson),
      accessoryData: parse('accessoryData', HomebrewAccessoryData.fromJson),
      basicItemData: parse('basicItemData', HomebrewBasicItemData.fromJson),
      sigModifierData:
          parse('sigModifierData', HomebrewSigModifierData.fromJson),
      uniqueAbilityData:
          parse('uniqueAbilityData', HomebrewUniqueAbilityData.fromJson),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
