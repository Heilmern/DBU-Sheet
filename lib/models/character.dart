/// character.dart
/// ---------------------------------------------------------------------------
/// The persisted data model for a single DBU character.
///
/// IMPORTANT DESIGN RULE: this model stores ONLY the values a player actually
/// *chooses* or *tracks* — Attribute Scores, Skill Ranks, Power Level, current
/// resource pools, biography, Z-Soul, etc. It never stores *derived* numbers
/// (Max Life, Skill bonuses, Aptitudes). Those are always recomputed on demand
/// by `services/character_calculator.dart`. This guarantees that if a rule or
/// formula changes, every existing saved character updates automatically and no
/// stale/incorrect totals can ever be written to disk.
///
/// Every field is JSON-serializable so a character can be saved on any platform
/// (Android, iOS, Windows, macOS, Web) using a single code path.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import '../data/apparel.dart';
import '../data/custom_buff_targets.dart';
import '../data/custom_species_traits.dart';
import '../data/dbu_rules.dart';
import '../data/homebrew_registry.dart';
import '../data/signature_profiles.dart';
import '../data/unique_abilities.dart';
import '../data/weapons.dart';
import 'homebrew.dart';

/// Tracks Skill Ranks for one Skill. For an Encompassing Skill (Craft,
/// Knowledge) ranks are stored per-Specialty; for a normal Skill the single
/// bucket keyed by [SkillProgress.normalKey] is used.
class SkillProgress {
  SkillProgress({Map<String, int>? ranks}) : ranks = ranks ?? {};

  /// The key used for a non-Encompassing skill's single rank bucket.
  static const String normalKey = '_';

  /// Map of specialty-name → number of Skill Ranks. For a normal skill this is
  /// `{ '_': ranks }`.
  final Map<String, int> ranks;

  /// Rank count for a specialty (or the whole skill, for normal skills).
  int ranksFor([String specialty = normalKey]) => ranks[specialty] ?? 0;

  void setRanks(String specialty, int value) {
    ranks[specialty] = value < 0 ? 0 : value;
  }

  Map<String, dynamic> toJson() => {'ranks': ranks};

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    final raw = (json['ranks'] as Map?) ?? const {};
    return SkillProgress(
      ranks: raw.map((k, v) => MapEntry(k as String, (v as num).toInt())),
    );
  }
}

/// The Z-Soul: a character's guiding quote, alignment and Karma tracker.
class ZSoul {
  ZSoul({
    this.quote = '',
    this.alignment = 'Neutral',
    this.description = '',
    int? karma,
  }) : karma = karma ?? KarmaRules.startingKarma;

  String quote;
  String alignment;
  String description;

  /// Karma Meter value. Starts at 2, caps at 4 per the Z-Souls & Karma Points
  /// rules (see `KarmaRules`).
  int karma;

  Map<String, dynamic> toJson() => {
        'quote': quote,
        'alignment': alignment,
        'description': description,
        'karma': karma,
      };

  factory ZSoul.fromJson(Map<String, dynamic> json) => ZSoul(
        quote: json['quote'] as String? ?? '',
        alignment: json['alignment'] as String? ?? 'Neutral',
        description: json['description'] as String? ?? '',
        karma: (json['karma'] as num?)?.toInt() ?? KarmaRules.startingKarma,
      );
}

/// A single row in the Resources / Conditions / States trackers. All three
/// sections share this shape (Name, current Stacks, Max Stacks, free-text
/// Notes) — this is a deliberately simple, un-automated tracker: the official
/// rulebook's full named catalogs (e.g. Conditions like Blinded/Broken, States
/// like Raging/Undying) each have unique numeric effects that are NOT applied
/// automatically here. That automation is a dedicated future milestone; for
/// now the player reads the effect off the rulebook and just tracks stacks.
class TrackedEntry {
  TrackedEntry({
    this.name = '',
    this.stacks = 0,
    this.maxStacks = 1,
    this.notes = '',
    this.replacesTraitName = '',
  });

  String name;
  int stacks;
  int maxStacks;
  String notes;

  /// Only meaningful for `Character.factorTraits` rows: the name of a
  /// canonical Racial Trait this freeform (often homebrew) Factor Trait
  /// represents replacing — kept in sync with `Character.inactiveRaceTraitNames`
  /// by the Information page's checkbox, so a custom Factor Trait can
  /// deactivate a Trait of the player's choosing without needing a
  /// structured `FactorSelection` entry.
  String replacesTraitName;

  Map<String, dynamic> toJson() => {
        'name': name,
        'stacks': stacks,
        'maxStacks': maxStacks,
        'notes': notes,
        'replacesTraitName': replacesTraitName,
      };

  factory TrackedEntry.fromJson(Map<String, dynamic> json) => TrackedEntry(
        name: json['name'] as String? ?? '',
        stacks: (json['stacks'] as num?)?.toInt() ?? 0,
        maxStacks: (json['maxStacks'] as num?)?.toInt() ?? 1,
        notes: json['notes'] as String? ?? '',
        replacesTraitName: json['replacesTraitName'] as String? ?? '',
      );
}

/// A single Custom Buff/Debuff row (Custom Buffs & Debuffs page/tab).
///
/// CONFIRMED (old sheet, verbatim): "-Total: ... where the bonuses from the
/// Flat and (T) columns are totalled" — this app additionally supports a
/// (bT) [Base Tier of Power] column exactly as the old sheet did. Total =
/// `flat + perBaseTier×BaseTierOfPower + perTier×TierOfPower`, applied to
/// [affectedStat] only while [active] is true.
class CustomBuff {
  CustomBuff({
    this.group = '',
    this.name = '',
    this.active = true,
    this.target = CustomBuffTarget.strikeAll,
    this.flat = 0,
    this.perBaseTier = 0,
    this.perTier = 0,
  });

  /// Optional group identifier — buffs sharing a non-empty group all become
  /// Active together when any one of them does. (Grouping is a display/UX
  /// convenience left to the UI; the model just stores the tag.)
  String group;
  String name;
  bool active;

  /// What this buff targets — the full old-sheet dropdown (see
  /// `data/custom_buff_targets.dart`). Resolves to one or more atomic
  /// `AffectedStat` channels via `CustomBuffTarget.channels`.
  CustomBuffTarget target;
  int flat;
  int perBaseTier;
  int perTier;

  Map<String, dynamic> toJson() => {
        'group': group,
        'name': name,
        'active': active,
        'target': target.name,
        'flat': flat,
        'perBaseTier': perBaseTier,
        'perTier': perTier,
      };

  factory CustomBuff.fromJson(Map<String, dynamic> json) => CustomBuff(
        group: json['group'] as String? ?? '',
        name: json['name'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        // Accept the new `target` key, else map a legacy `affectedStat`.
        target: customBuffTargetByName(
                (json['target'] ?? json['affectedStat']) as String?) ??
            CustomBuffTarget.strikeAll,
        flat: (json['flat'] as num?)?.toInt() ?? 0,
        perBaseTier: (json['perBaseTier'] as num?)?.toInt() ?? 0,
        perTier: (json['perTier'] as num?)?.toInt() ?? 0,
      );
}

/// Which of the Inventory page's freeform sections an [InventoryItem] belongs
/// to. NB: Apparel, Weapons and Accessories are NOT stored as [InventoryItem]s
/// — each has its own fully modelled list ([Character.apparel] /
/// [Character.weapons] / [Character.accessories]); the `apparel`, `weapon` and
/// `accessory` values here are retained only for backward-compatibility with
/// old saves. The freeform tracker now covers only Gear. Purely a model
/// grouping, not a rules catalogue.
enum InventoryCategory { apparel, weapon, accessory, gear }

extension InventoryCategoryDisplay on InventoryCategory {
  String get displayName {
    switch (this) {
      case InventoryCategory.apparel:
        return 'Apparel';
      case InventoryCategory.weapon:
        return 'Weapons';
      case InventoryCategory.accessory:
        return 'Accessories';
      case InventoryCategory.gear:
        return 'Gear';
    }
  }

  /// Singular noun for buttons/labels ("Add Weapon", not "Add Weapons").
  String get singular {
    switch (this) {
      case InventoryCategory.apparel:
        return 'Apparel';
      case InventoryCategory.weapon:
        return 'Weapon';
      case InventoryCategory.accessory:
        return 'Accessory';
      case InventoryCategory.gear:
        return 'Gear';
    }
  }

  /// Verb for the "currently in use" checkbox: Apparel is Worn, a Weapon is
  /// Wielded, an Accessory is Equipped. Gear has no equipped state.
  String get equippedLabel {
    switch (this) {
      case InventoryCategory.apparel:
        return 'Worn';
      case InventoryCategory.weapon:
        return 'Wielded';
      case InventoryCategory.accessory:
        return 'Equipped';
      case InventoryCategory.gear:
        return '';
    }
  }
}

/// One line on the Inventory page — a freeform, un-automated record of a single
/// owned item, grouped by [category]. Same spirit as [TrackedEntry] and
/// [TalentEntry]: the Inventory is a tracker the player fills in by hand. The
/// site's full Apparel/Weapon sub-systems (Break Value, Doff Bonus, layer
/// penalties, Craft TN, Apparel/Weapon Qualities, Battle Uniform) are NOT
/// modelled or applied to any stat automatically — that's a dedicated future
/// milestone — so each item just records its Name, an optional freeform
/// Type/Category [detail], [quantity], whether it's currently worn/wielded/
/// [equipped], and free-text [notes].
class InventoryItem {
  InventoryItem({
    this.category = InventoryCategory.gear,
    this.name = '',
    this.detail = '',
    this.quantity = 1,
    this.equipped = false,
    this.notes = '',
  });

  InventoryCategory category;
  String name;

  /// Freeform secondary descriptor whose meaning depends on [category] — an
  /// Apparel's "Category / Grade", a Weapon's "Type / Size / Category", an
  /// Accessory's kind. Not shown for Gear.
  String detail;

  /// How many of this item are owned — mainly meaningful for Gear/consumables.
  int quantity;

  /// Whether the item is currently Worn (Apparel) / Wielded (Weapon) /
  /// Equipped (Accessory). Ignored for Gear.
  bool equipped;

  String notes;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'name': name,
        'detail': detail,
        'quantity': quantity,
        'equipped': equipped,
        'notes': notes,
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        category: InventoryCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => InventoryCategory.gear,
        ),
        name: json['name'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        equipped: json['equipped'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

/// Which of the (up to three) Apparel Layers a worn piece occupies. Only the
/// Top Layer grants the Armor / Combat Clothing Category benefit (see
/// `CharacterCalculator`). Integrated Apparel is always the Bottom Layer.
enum WornLayer { top, middle, bottom }

extension WornLayerDisplay on WornLayer {
  String get displayName {
    switch (this) {
      case WornLayer.top:
        return 'Top Layer';
      case WornLayer.middle:
        return 'Middle Layer';
      case WornLayer.bottom:
        return 'Bottom Layer';
    }
  }
}

/// One Apparel Quality chosen for a piece of Apparel — its catalogue [name]
/// (see `data/apparel.dart`), how many Quality [slots] it occupies (relevant
/// only when the Quality has a slot range, e.g. Segmented Weight 1~2), and any
/// free-text [notes] the player recorded (e.g. the Team Name / chosen Skill a
/// Quality asks you to pick).
class ApparelQualitySelection {
  ApparelQualitySelection({
    this.name = '',
    this.slots = 1,
    this.notes = '',
  });

  String name;
  int slots;
  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slots': slots,
        'notes': notes,
      };

  factory ApparelQualitySelection.fromJson(Map<String, dynamic> json) =>
      ApparelQualitySelection(
        name: json['name'] as String? ?? '',
        slots: (json['slots'] as num?)?.toInt() ?? 1,
        notes: json['notes'] as String? ?? '',
      );
}

/// A structured piece of Apparel — the Inventory page's Apparel section models
/// the site's Apparel sub-system fully (unlike the freeform Weapons/Accessories/
/// Gear [InventoryItem] lists). Stores only the player's CHOICES; every derived
/// value (Apparel Grade, Apparel Bonus, Quality-Slot budget, max Break Value,
/// Category benefit, Apparel Penalty, Damage Reduction) is computed by
/// `CharacterCalculator` from the `data/apparel.dart` catalogue — see that file.
class ApparelPiece {
  ApparelPiece({
    this.name = '',
    this.craftsmanshipGrade = 1,
    this.category = ApparelCategory.standardClothing,
    this.size = DbuSize.medium,
    this.worn = false,
    this.layer = WornLayer.top,
    this.breakValue = kDefaultApparelBreakValue,
    List<ApparelQualitySelection>? qualities,
    this.notes = '',
  }) : qualities = qualities ?? [];

  String name;

  /// Craftsmanship Grade 1–5 — determines the Craft DC, the Apparel Grade
  /// (Low/Standard/High → Apparel Bonus) and the number of Quality Slots (see
  /// `craftsmanshipInfo`).
  int craftsmanshipGrade;

  ApparelCategory category;

  /// The Size Category the piece was made for (only a Character of that Size
  /// may wear it — not enforced here, tracked for reference).
  DbuSize size;

  /// Whether the piece is currently worn. A worn, un-broken piece grants its
  /// benefits; a broken one (Break Value 0) does not.
  bool worn;

  /// Which Layer the piece is worn on (only meaningful while [worn]).
  WornLayer layer;

  /// Current Break Value. The maximum (default 3, +3 with Durable) is derived;
  /// this tracks the current value, which drops as the piece takes damage and
  /// is restored on repair. A piece is broken (loses its benefit) at 0.
  int breakValue;

  /// The Apparel Qualities on this piece — see [ApparelQualitySelection].
  final List<ApparelQualitySelection> qualities;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'craftsmanshipGrade': craftsmanshipGrade,
        'category': category.name,
        'size': size.name,
        'worn': worn,
        'layer': layer.name,
        'breakValue': breakValue,
        'qualities': qualities.map((q) => q.toJson()).toList(),
        'notes': notes,
      };

  factory ApparelPiece.fromJson(Map<String, dynamic> json) => ApparelPiece(
        name: json['name'] as String? ?? '',
        craftsmanshipGrade:
            (json['craftsmanshipGrade'] as num?)?.toInt() ?? 1,
        category: ApparelCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => ApparelCategory.standardClothing,
        ),
        size: DbuSize.values.firstWhere(
          (s) => s.name == json['size'],
          orElse: () => DbuSize.medium,
        ),
        worn: json['worn'] as bool? ?? false,
        layer: WornLayer.values.firstWhere(
          (l) => l.name == json['layer'],
          orElse: () => WornLayer.top,
        ),
        breakValue:
            (json['breakValue'] as num?)?.toInt() ?? kDefaultApparelBreakValue,
        qualities: ((json['qualities'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ApparelQualitySelection.fromJson)
            .toList(),
        notes: json['notes'] as String? ?? '',
      );
}

/// One Weapon Quality chosen for a Weapon — its catalogue [name] (see
/// `data/weapons.dart`), how many Quality [slots] it occupies (relevant only
/// when the Quality has a slot range, e.g. Artisan 1~2) and any free-text
/// [notes] the player recorded (e.g. the Alignment / Profile a Quality asks you
/// to pick). Parallel to [ApparelQualitySelection].
class WeaponQualitySelection {
  WeaponQualitySelection({
    this.name = '',
    this.slots = 1,
    this.notes = '',
  });

  String name;
  int slots;
  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'slots': slots,
        'notes': notes,
      };

  factory WeaponQualitySelection.fromJson(Map<String, dynamic> json) =>
      WeaponQualitySelection(
        name: json['name'] as String? ?? '',
        slots: (json['slots'] as num?)?.toInt() ?? 1,
        notes: json['notes'] as String? ?? '',
      );
}

/// A structured Weapon — the Inventory page's Weapons section models the site's
/// Weapon sub-system (unlike the freeform Accessories/Gear [InventoryItem]
/// lists). Stores only the player's CHOICES; every derived value (Life Points,
/// Damage Reduction, Quality-Slot budget, per-Attack Strike/Wound modifiers) is
/// computed by `CharacterCalculator` from the `data/weapons.dart` catalogue.
class WeaponPiece {
  WeaponPiece({
    this.name = '',
    this.type = WeaponType.physical,
    this.size = WeaponSize.standard,
    this.category = '',
    this.craftsmanshipGrade = 1,
    this.wielded = false,
    this.lifePoints,
    List<WeaponQualitySelection>? qualities,
    this.notes = '',
  }) : qualities = qualities ?? [];

  String name;

  /// Physical / Energy / Magic — decides available Categories and which Wound
  /// Roll the Weapon feeds.
  WeaponType type;

  WeaponSize size;

  /// The chosen Weapon Category name (see `weaponCategoryByName`) — must be one
  /// of the Categories available to [type]; '' when none chosen.
  String category;

  /// Craftsmanship Grade 1–5 — determines the Craft DC and the number of
  /// Quality Slots (shares Apparel's `craftsmanshipInfo` table; a Weapon has no
  /// Low/Standard/High Grade of its own).
  int craftsmanshipGrade;

  /// Whether the Weapon is currently wielded. A wielded, un-broken Weapon
  /// applies its effects; wielding any Weapon incurs the Weapon Penalty.
  bool wielded;

  /// Current Life Points; `null` means topped-up to the derived maximum
  /// (32 + 8×Power Level, plus Shield/Durable bonuses). Drops as the Weapon is
  /// Called-Shot; a Weapon at 0 is broken and cannot make Attacking Maneuvers.
  int? lifePoints;

  /// The Weapon Qualities on this Weapon — see [WeaponQualitySelection].
  final List<WeaponQualitySelection> qualities;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'size': size.name,
        'category': category,
        'craftsmanshipGrade': craftsmanshipGrade,
        'wielded': wielded,
        'lifePoints': lifePoints,
        'qualities': qualities.map((q) => q.toJson()).toList(),
        'notes': notes,
      };

  factory WeaponPiece.fromJson(Map<String, dynamic> json) => WeaponPiece(
        name: json['name'] as String? ?? '',
        type: WeaponType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => WeaponType.physical,
        ),
        size: WeaponSize.values.firstWhere(
          (s) => s.name == json['size'],
          orElse: () => WeaponSize.standard,
        ),
        category: json['category'] as String? ?? '',
        craftsmanshipGrade: (json['craftsmanshipGrade'] as num?)?.toInt() ?? 1,
        wielded: json['wielded'] as bool? ?? false,
        lifePoints: (json['lifePoints'] as num?)?.toInt(),
        qualities: ((json['qualities'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WeaponQualitySelection.fromJson)
            .toList(),
        notes: json['notes'] as String? ?? '',
      );
}

/// One Accessory the character owns — a catalogue pick (see
/// `data/accessories.dart`'s `accessoryByName`) plus whether it's currently
/// [equipped] and any free-text [notes] (e.g. the Intended Character an
/// Accessory asks you to declare). Unlike Apparel/Weapons, an Accessory has no
/// crafted parameters — its effect comes wholesale from the catalogue.
class AccessorySelection {
  AccessorySelection({
    this.name = '',
    this.equipped = false,
    this.notes = '',
  });

  String name;

  /// Whether the Accessory is currently equipped — only an equipped Accessory
  /// grants its benefit (max 2 equipped at once, not enforced here).
  bool equipped;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'equipped': equipped,
        'notes': notes,
      };

  factory AccessorySelection.fromJson(Map<String, dynamic> json) =>
      AccessorySelection(
        name: json['name'] as String? ?? '',
        equipped: json['equipped'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

/// One Basic Item the character owns — a catalogue pick (see
/// `data/basic_items.dart`'s `basicItemByName`) plus how many they carry
/// ([quantity]) and any free-text [notes] (e.g. the trigger a Bomb selected, or
/// how many Senzu Beans a bag rolled). Basic Items are Action-triggered
/// consumables/utilities — none grant a passive stat effect — so this is a
/// reference tracker like [TrackedEntry], not fed into any derived stat.
class BasicItemSelection {
  BasicItemSelection({
    this.name = '',
    this.quantity = 1,
    this.notes = '',
  });

  String name;
  int quantity;
  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'notes': notes,
      };

  factory BasicItemSelection.fromJson(Map<String, dynamic> json) =>
      BasicItemSelection(
        name: json['name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        notes: json['notes'] as String? ?? '',
      );
}

/// The level of a Signature Technique (see `data/signature_modifiers.dart` and
/// the Signatures tab). Ultimate/Dramatic Finisher both add +4 TP and share the
/// Ultimate rules; a Dramatic Finisher additionally carries a Super Profile.
enum SignatureLevel {
  superTech('Super'),
  ultimate('Ultimate'),
  dramaticFinisher('Dramatic Finisher');

  const SignatureLevel(this.displayName);
  final String displayName;

  /// Ultimate and Dramatic Finisher both count as Ultimate Signature Techniques
  /// (the +4 TP surcharge, once-per-encounter, possession limits).
  bool get isUltimate => this != SignatureLevel.superTech;
}

/// One Advantage or Disadvantage chosen for a Signature Technique — its
/// catalogue [name] (see `signatureModifierByName`) and how many [rank]s of it
/// are owned (≥ 1).
class SigModifierSelection {
  SigModifierSelection({this.name = '', this.rank = 1, this.free = false});

  String name;
  int rank;

  /// When `true`, this Advantage's TP Cost does not count against the
  /// character's Technique Point budget (e.g. a Trait that grants a free
  /// Advantage). The Advantage still applies its effect; only the pool
  /// spending is discounted. Only meaningful for Advantages.
  bool free;

  Map<String, dynamic> toJson() => {'name': name, 'rank': rank, 'free': free};

  factory SigModifierSelection.fromJson(Map<String, dynamic> json) =>
      SigModifierSelection(
        name: json['name'] as String? ?? '',
        rank: (json['rank'] as num?)?.toInt() ?? 1,
        free: json['free'] as bool? ?? false,
      );
}

/// A player-built Signature Technique — stores only the choices; the TP/KP costs
/// and per-technique combat modifiers are computed by `CharacterCalculator` from
/// the `data/signature_*.dart` catalogues.
class SignatureTechnique {
  SignatureTechnique({
    this.name = '',
    this.level = SignatureLevel.superTech,
    this.foundation = SigFoundation.physical,
    this.profileName = '',
    this.superProfileName = '',
    List<SigModifierSelection>? advantages,
    List<SigModifierSelection>? disadvantages,
    this.usedThisEncounter = false,
    this.freeTp = 0,
    this.notes = '',
  })  : advantages = advantages ?? [],
        disadvantages = disadvantages ?? [];

  String name;
  SignatureLevel level;

  /// The concrete Foundation chosen (Physical/Energy/Magic). Multi-Foundation
  /// Profiles are usable under any Foundation, so this is always concrete.
  SigFoundation foundation;

  /// The base Profile name (see `signatureProfileByName`); '' when unchosen.
  String profileName;

  /// The Super Profile name — only meaningful for a Dramatic Finisher.
  String superProfileName;

  final List<SigModifierSelection> advantages;
  final List<SigModifierSelection> disadvantages;

  /// Tracks the Ultimate "once per Combat Encounter" limit (player-toggled).
  bool usedThisEncounter;

  /// A flat Technique Point discount for this Technique — "free TP" granted by
  /// a Trait/Talent/effect (e.g. a Favored Technique). Reduces what this
  /// Technique costs against the character's TP budget, floored at 0. Does NOT
  /// change the Technique's own TP Cost (which still drives KP Cost and the
  /// per-Tier spend cap).
  int freeTp;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level.name,
        'foundation': foundation.name,
        'profileName': profileName,
        'superProfileName': superProfileName,
        'advantages': advantages.map((a) => a.toJson()).toList(),
        'disadvantages': disadvantages.map((d) => d.toJson()).toList(),
        'usedThisEncounter': usedThisEncounter,
        'freeTp': freeTp,
        'notes': notes,
      };

  factory SignatureTechnique.fromJson(Map<String, dynamic> json) =>
      SignatureTechnique(
        name: json['name'] as String? ?? '',
        level: SignatureLevel.values.firstWhere(
          (l) => l.name == json['level'],
          orElse: () => SignatureLevel.superTech,
        ),
        foundation: SigFoundation.values.firstWhere(
          (f) => f.name == json['foundation'],
          orElse: () => SigFoundation.physical,
        ),
        profileName: json['profileName'] as String? ?? '',
        superProfileName: json['superProfileName'] as String? ?? '',
        advantages: ((json['advantages'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SigModifierSelection.fromJson)
            .toList(),
        disadvantages: ((json['disadvantages'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SigModifierSelection.fromJson)
            .toList(),
        usedThisEncounter: json['usedThisEncounter'] as bool? ?? false,
        freeTp: (json['freeTp'] as num?)?.toInt() ?? 0,
        notes: json['notes'] as String? ?? '',
      );
}

/// One Unique Ability the character owns — a catalogue pick (see
/// `data/unique_abilities.dart`) plus the player's state: the chosen [type]
/// (only when the ability lists both Technical/Magical), which [advancements]
/// and [restrictions] are applied (by name), and free-text [notes]. The TP/KP
/// costs are computed by `CharacterCalculator` from those choices.
class UniqueAbilitySelection {
  UniqueAbilitySelection({
    this.name = '',
    this.type,
    Set<String>? advancements,
    Set<String>? restrictions,
    this.freeTechnique = false,
    Set<String>? freeAdvancements,
    this.notes = '',
  })  : advancements = advancements ?? {},
        restrictions = restrictions ?? {},
        freeAdvancements = freeAdvancements ?? {};

  String name;

  /// The chosen classification when the ability permits both; `null` otherwise
  /// (or when not yet chosen — the ability's sole type is used then).
  UniqueAbilityType? type;

  /// Names of the ability's Advancements the character has bought.
  final Set<String> advancements;

  /// Names of the ability's Restrictions the character has applied.
  final Set<String> restrictions;

  /// When `true`, the whole Unique Ability was obtained without paying its TP
  /// Cost (e.g. a Trait/Awakening that grants a Unique Ability for free). It
  /// contributes 0 to the character's Technique Point budget.
  bool freeTechnique;

  /// Names of this ability's Advancements gained for free (their TP Cost does
  /// not count against the character's Technique Point budget).
  final Set<String> freeAdvancements;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type?.name,
        'advancements': advancements.toList(),
        'restrictions': restrictions.toList(),
        'freeTechnique': freeTechnique,
        'freeAdvancements': freeAdvancements.toList(),
        'notes': notes,
      };

  factory UniqueAbilitySelection.fromJson(Map<String, dynamic> json) =>
      UniqueAbilitySelection(
        name: json['name'] as String? ?? '',
        type: UniqueAbilityType.values
            .cast<UniqueAbilityType?>()
            .firstWhere((t) => t?.name == json['type'], orElse: () => null),
        advancements: ((json['advancements'] as List?) ?? const [])
            .whereType<String>()
            .toSet(),
        restrictions: ((json['restrictions'] as List?) ?? const [])
            .whereType<String>()
            .toSet(),
        freeTechnique: json['freeTechnique'] as bool? ?? false,
        freeAdvancements: ((json['freeAdvancements'] as List?) ?? const [])
            .whereType<String>()
            .toSet(),
        notes: json['notes'] as String? ?? '',
      );
}

/// A single freeform Talent row (Name/Notes/Prerequisites/Description) —
/// Talents don't have an in-app catalogue yet (future milestone), so this is
/// purely a place to record them, same spirit as the freeform [TrackedEntry]
/// lists before their catalogues existed.
class TalentEntry {
  TalentEntry({
    this.name = '',
    this.prerequisites = '',
    this.description = '',
    this.notes = '',
  });

  String name;
  String prerequisites;
  String description;
  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'prerequisites': prerequisites,
        'description': description,
        'notes': notes,
      };

  factory TalentEntry.fromJson(Map<String, dynamic> json) => TalentEntry(
        name: json['name'] as String? ?? '',
        prerequisites: json['prerequisites'] as String? ?? '',
        description: json['description'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

/// What the player redeemed one Progression grant slot as — see
/// `Character.progressionChoices`/`BonusPerkEntry`. Shared shape for both,
/// since a Bonus Perk is just a `characterPerk`-style grant that isn't tied
/// to the Power Level Table.
class ProgressionChoice {
  ProgressionChoice({
    this.resolvedKind = ProgressionGrantKind.attributeAddition,
    Map<DbuAttribute, int>? attributePoints,
    this.talentName = '',
    Map<String, int>? skillRanks,
    this.notes = '',
  })  : attributePoints = attributePoints ?? {},
        skillRanks = skillRanks ?? {};

  /// Which of the 3 concrete kinds this slot was redeemed as. For a slot
  /// whose static kind is already concrete (`attributeAddition`/
  /// `talentAddition`/`skillImprovement`), this always mirrors that kind —
  /// only a `characterPerk` slot lets the player choose freely.
  ProgressionGrantKind resolvedKind;

  /// Used when [resolvedKind] is `attributeAddition`: Attribute → points
  /// spent there (should sum to `kAttributeAdditionPoints`, not enforced).
  final Map<DbuAttribute, int> attributePoints;

  /// Used when [resolvedKind] is `talentAddition`: the Talent's name (see
  /// `data/talents.dart`'s `talentByName`, or a freeform name for a
  /// homebrew Talent). Synced into `Character.talents` — see
  /// `services/progression_talent_sync.dart`.
  String talentName;

  /// Used when [resolvedKind] is `skillImprovement`: Skill key
  /// (`'SkillName::specialtyKey'`, `specialtyKey` = `SkillProgress.normalKey`
  /// for a non-Encompassing Skill) → Ranks granted by this slot.
  final Map<String, int> skillRanks;

  /// Freeform notes (e.g. why/how this Perk was redeemed this way).
  String notes;

  Map<String, dynamic> toJson() => {
        'resolvedKind': resolvedKind.name,
        'attributePoints':
            attributePoints.map((k, v) => MapEntry(k.name, v)),
        'talentName': talentName,
        'skillRanks': skillRanks,
        'notes': notes,
      };

  factory ProgressionChoice.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['attributePoints'] as Map?) ?? const {};
    final points = <DbuAttribute, int>{};
    rawPoints.forEach((k, v) {
      final attr = DbuAttribute.values
          .cast<DbuAttribute?>()
          .firstWhere((a) => a?.name == k, orElse: () => null);
      if (attr != null) points[attr] = (v as num?)?.toInt() ?? 0;
    });
    final rawRanks = (json['skillRanks'] as Map?) ?? const {};
    return ProgressionChoice(
      resolvedKind: ProgressionGrantKind.values
              .cast<ProgressionGrantKind?>()
              .firstWhere((k) => k?.name == json['resolvedKind'],
                  orElse: () => null) ??
          ProgressionGrantKind.attributeAddition,
      attributePoints: points,
      talentName: json['talentName'] as String? ?? '',
      skillRanks: rawRanks.map(
        (k, v) => MapEntry(k as String, (v as num?)?.toInt() ?? 0),
      ),
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// A freeform bonus Perk gained outside the Power Level Table (a Trait, or
/// ARC benevolence) — old sheet's "Bonus Perks" section. `powerLevel == null`
/// means it's always active ("otherwise, they're always on").
class BonusPerkEntry {
  BonusPerkEntry({
    this.powerLevel,
    this.source = '',
    this.resolvedKind = ProgressionGrantKind.attributeAddition,
    Map<DbuAttribute, int>? attributePoints,
    this.talentName = '',
    Map<String, int>? skillRanks,
    this.notes = '',
  })  : attributePoints = attributePoints ?? {},
        skillRanks = skillRanks ?? {};

  int? powerLevel;
  String source;
  ProgressionGrantKind resolvedKind;
  final Map<DbuAttribute, int> attributePoints;
  String talentName;
  final Map<String, int> skillRanks;
  String notes;

  Map<String, dynamic> toJson() => {
        'powerLevel': powerLevel,
        'source': source,
        'resolvedKind': resolvedKind.name,
        'attributePoints':
            attributePoints.map((k, v) => MapEntry(k.name, v)),
        'talentName': talentName,
        'skillRanks': skillRanks,
        'notes': notes,
      };

  factory BonusPerkEntry.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['attributePoints'] as Map?) ?? const {};
    final points = <DbuAttribute, int>{};
    rawPoints.forEach((k, v) {
      final attr = DbuAttribute.values
          .cast<DbuAttribute?>()
          .firstWhere((a) => a?.name == k, orElse: () => null);
      if (attr != null) points[attr] = (v as num?)?.toInt() ?? 0;
    });
    final rawRanks = (json['skillRanks'] as Map?) ?? const {};
    return BonusPerkEntry(
      powerLevel: (json['powerLevel'] as num?)?.toInt(),
      source: json['source'] as String? ?? '',
      resolvedKind: ProgressionGrantKind.values
              .cast<ProgressionGrantKind?>()
              .firstWhere((k) => k?.name == json['resolvedKind'],
                  orElse: () => null) ??
          ProgressionGrantKind.attributeAddition,
      attributePoints: points,
      talentName: json['talentName'] as String? ?? '',
      skillRanks: rawRanks.map(
        (k, v) => MapEntry(k as String, (v as num?)?.toInt() ?? 0),
      ),
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// One Transformation the character has gained access to, plus the player's
/// state for it — see `data/transformations.dart`. Which catalogue a name
/// resolves to (Awakening / Enhancement / Form) is looked up by the
/// calculator/UI; this just stores the choices.
class TransformationSelection {
  TransformationSelection({
    this.name = '',
    this.active = false,
    this.stacks = 1,
    this.grade = 1,
    this.masteryLevel = 0,
    this.grandAwakeningActive = false,
    this.transcended = false,
    Map<String, Set<String>>? optionChoices,
    Map<DbuAttribute, int>? customAmb,
    Map<DbuAttribute, int>? flatAmb,
    this.notes = '',
  })  : optionChoices = optionChoices ?? {},
        customAmb = customAmb ?? {},
        flatAmb = flatAmb ?? {};

  /// The Transformation's name (matches a `TransformationDef.name`).
  String name;

  /// Whether the character is currently IN this Transformation — only
  /// meaningful for Enhancements/Forms (Awakenings are always active, so
  /// this is ignored for them). Drives Attribute Modifier Bonus / Ki
  /// Multiplier automation.
  bool active;

  /// Number of Stacks (Awakenings only), 1..`maxStacks`.
  int stacks;

  /// Current Grade (Graded Transformations only), 1+.
  int grade;

  /// How many times this Transformation has been Mastered (0 = not yet;
  /// Forms/Enhancements only).
  int masteryLevel;

  /// Whether a Super Awakening's Grand Awakening is currently active
  /// (switched on via the Full Awakening Maneuver). Drives the Grand
  /// Awakening Trait's automation; meaningless for other Transformations.
  bool grandAwakeningActive;

  /// Whether an Enhancement with the Transcendent Aspect is currently
  /// Transcended (requires Fully Mastered + 1 extra Mastery — tracked
  /// manually, not enforced). Drives the Transcendent Trait's automation
  /// while the Enhancement is active.
  bool transcended;

  /// Chosen Option(s) for this Transformation's Traits, keyed
  /// `'<Trait name>::<Option group label>'` (same shape as
  /// `Character.raceTraitOptionChoices`).
  final Map<String, Set<String>> optionChoices;

  /// Player-authored Attribute Modifier Bonus for this Transformation, on top
  /// of (or in place of) the catalogue's fixed `TransformationDef.amb` table.
  /// Lets a player pick which Attribute(s) a bonus lands on and enter the
  /// value — needed for Awakenings whose bonus is "to an Attribute of your
  /// choice", and for Grade-set (`*`) tables the app can't auto-derive. Added
  /// into the computed Attribute Modifier the same way the catalogue AMB is
  /// (always-on × Stacks for Awakenings; active-only for Enhancements/Forms) —
  /// see `CharacterCalculator.transformationModifierBonus`.
  final Map<DbuAttribute, int> customAmb;

  /// A **flat** (never ×Stacks) player-distributed Attribute Modifier Bonus for
  /// this Transformation — the mechanism behind per-Stack "distribute a point
  /// between AG/TE each Stack" Traits (e.g. Steady Progress). Driven by a
  /// Trait's `distributableAmb`; added once (after the ×Stacks step) in
  /// `CharacterCalculator.transformationModifierBonus`.
  final Map<DbuAttribute, int> flatAmb;

  String notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'active': active,
        'stacks': stacks,
        'grade': grade,
        'masteryLevel': masteryLevel,
        'grandAwakeningActive': grandAwakeningActive,
        'transcended': transcended,
        'optionChoices':
            optionChoices.map((k, v) => MapEntry(k, v.toList())),
        'customAmb': customAmb.map((k, v) => MapEntry(k.name, v)),
        'flatAmb': flatAmb.map((k, v) => MapEntry(k.name, v)),
        'notes': notes,
      };

  factory TransformationSelection.fromJson(Map<String, dynamic> json) =>
      TransformationSelection(
        name: json['name'] as String? ?? '',
        active: json['active'] as bool? ?? false,
        stacks: (json['stacks'] as num?)?.toInt() ?? 1,
        grade: (json['grade'] as num?)?.toInt() ?? 1,
        masteryLevel: (json['masteryLevel'] as num?)?.toInt() ?? 0,
        grandAwakeningActive: json['grandAwakeningActive'] as bool? ?? false,
        transcended: json['transcended'] as bool? ?? false,
        optionChoices:
            ((json['optionChoices'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(
            k as String,
            ((v as List?) ?? const []).whereType<String>().toSet(),
          ),
        ),
        customAmb: _ambFromJson(json['customAmb']),
        flatAmb: _ambFromJson(json['flatAmb']),
        notes: json['notes'] as String? ?? '',
      );

  static Map<DbuAttribute, int> _ambFromJson(Object? raw) {
    final result = <DbuAttribute, int>{};
    ((raw as Map?) ?? const {}).forEach((k, v) {
      final attr = DbuAttribute.values
          .cast<DbuAttribute?>()
          .firstWhere((a) => a?.name == k, orElse: () => null);
      if (attr != null) result[attr] = (v as num?)?.toInt() ?? 0;
    });
    return result;
  }
}

/// Records that a Racial Trait has been swapped out for a compatible
/// Racial Factor's Factor Trait (see `data/factor_traits.dart`). CONFIRMED
/// (racial-factors page, verbatim): "Factor Traits are considered Racial
/// Traits. They are Primary or Secondary, depending on which type of
/// Racial Trait they replaced." — so once selected, the Factor Trait is
/// looked up and converted into a genuine `RaceTraitDef` (see
/// `FactorTraitDef.toRaceTraitDef`) standing in for [replacedTraitName]
/// wherever Racial Traits are computed or displayed (see
/// `CharacterCalculator.activeRaceTraits`).
class FactorSelection {
  FactorSelection({
    this.factorName = '',
    this.factorTraitName = '',
    this.replacedTraitName = '',
  });

  /// Which Racial Factor (`FactorDef.name`) this Factor Trait comes from.
  String factorName;

  /// Which Factor Trait (`FactorTraitDef.name`) was chosen.
  String factorTraitName;

  /// The Racial Trait (`RaceTraitDef.name`) this Factor Trait replaced —
  /// normally a Secondary Trait, per the framework's default rule.
  String replacedTraitName;

  Map<String, dynamic> toJson() => {
        'factorName': factorName,
        'factorTraitName': factorTraitName,
        'replacedTraitName': replacedTraitName,
      };

  factory FactorSelection.fromJson(Map<String, dynamic> json) =>
      FactorSelection(
        factorName: json['factorName'] as String? ?? '',
        factorTraitName: json['factorTraitName'] as String? ?? '',
        replacedTraitName: json['replacedTraitName'] as String? ?? '',
      );
}

/// A complete, saveable character.
class Character {
  Character({
    required this.id,
    this.name = '',
    this.player = '',
    this.race = 'Custom Species',
    this.subspecies = '',
    this.age = '',
    this.gender = '',
    this.height = '',
    this.weight = '',
    this.hairColor = '',
    this.eyeColor = '',
    this.skinTone = '',
    this.imageUrl = '',
    this.size = DbuSize.medium,
    this.powerLevel = 1,
    List<DbuAttribute?>? raceAttributeIncreaseChoices,
    Map<String, SkillProgress>? skills,
    ZSoul? zSoul,
    this.currentLife,
    this.currentKi,
    this.capacitySpent = 0,
    this.bonusTechniquePoints = 0,
    this.superStacks = 0,
    this.powerStacks = 0,
    this.diminishingOffenseStacks = 0,
    this.diminishingDefenseStacks = 0,
    this.holdingBackStacks = 0,
    this.bruisedSteadfastPassed = false,
    this.injuredSteadfastPassed = false,
    this.criticalSteadfastPassed = false,
    List<TrackedEntry>? resources,
    List<TrackedEntry>? conditions,
    List<TrackedEntry>? states,
    List<CustomBuff>? customBuffs,
    Set<String>? inactiveRaceTraitNames,
    List<String>? extraRaceTraits,
    Map<String, Set<String>>? raceTraitOptionChoices,
    List<FactorSelection>? factorSelections,
    List<TrackedEntry>? factorTraits,
    List<TrackedEntry>? customRaceTraits,
    Set<String>? customPrimaryTraits,
    List<DbuSavingThrow>? customSavingThrows,
    Map<String, FlawCompensation>? customFlawCompensation,
    List<TalentEntry>? talents,
    List<HomebrewSelection>? homebrewSelections,
    List<InventoryItem>? inventory,
    List<ApparelPiece>? apparel,
    List<WeaponPiece>? weapons,
    List<AccessorySelection>? accessories,
    List<BasicItemSelection>? basicItems,
    List<SignatureTechnique>? signatureTechniques,
    List<UniqueAbilitySelection>? uniqueAbilities,
    Map<String, ProgressionChoice>? progressionChoices,
    List<BonusPerkEntry>? bonusPerks,
    List<TransformationSelection>? transformations,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : raceAttributeIncreaseChoices = raceAttributeIncreaseChoices ?? [],
        skills = skills ?? _defaultSkills(),
        zSoul = zSoul ?? ZSoul(),
        resources = resources ?? [],
        conditions = conditions ?? [],
        states = states ?? [],
        customBuffs = customBuffs ?? [],
        inactiveRaceTraitNames = inactiveRaceTraitNames ?? {},
        extraRaceTraits = extraRaceTraits ?? [],
        raceTraitOptionChoices = raceTraitOptionChoices ?? {},
        factorSelections = factorSelections ?? [],
        factorTraits = factorTraits ?? [],
        customRaceTraits = customRaceTraits ?? [],
        customPrimaryTraits = customPrimaryTraits ?? {},
        customSavingThrows = customSavingThrows ?? [],
        customFlawCompensation = customFlawCompensation ?? {},
        talents = talents ?? [],
        homebrewSelections = homebrewSelections ?? [],
        inventory = inventory ?? [],
        apparel = apparel ?? [],
        weapons = weapons ?? [],
        accessories = accessories ?? [],
        basicItems = basicItems ?? [],
        signatureTechniques = signatureTechniques ?? [],
        uniqueAbilities = uniqueAbilities ?? [],
        progressionChoices = progressionChoices ?? {},
        bonusPerks = bonusPerks ?? [],
        transformations = transformations ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Stable unique identifier (used as the storage key and list key).
  final String id;

  // --- Basic Information ----------------------------------------------------
  String name;
  String player;
  String race;
  String subspecies;
  String age;
  String gender;
  String height;
  String weight;
  String hairColor;
  String eyeColor;
  String skinTone;

  /// A URL or (later) local path to the character portrait.
  String imageUrl;

  DbuSize size;

  /// Power Level 1–30. Drives Tier of Power and all pool maximums.
  int powerLevel;

  // --- Mechanical choices ---------------------------------------------------
  /// Resolved picks for this Race's `RaceAttributeIncrease.choices` (e.g.
  /// Cerealian's "either Force or Magic") — index *i* is the pick for
  /// `raceByName(race).attributeIncrease.choices[i]`; `null`/missing index =
  /// not yet chosen. See [scoreOf], which is fully computed from this plus
  /// [progressionChoices]/[bonusPerks] — Attribute Scores are no longer a
  /// directly-editable stored value. Custom Species uses this same path (its
  /// three +2/+2/+1 slots) rather than a freeform per-Attribute entry.
  final List<DbuAttribute?> raceAttributeIncreaseChoices;

  /// Skill Ranks keyed by Skill name — the Character-Creation BASE
  /// allocation only (Racial `RaceDef.skillRanks` pool, or `customSkillRanks`
  /// for Custom Species). Progression's Skill Improvement grants add on top
  /// of this at calculation time — see `CharacterCalculator.totalSkillRanks`.
  final Map<String, SkillProgress> skills;

  ZSoul zSoul;

  // --- Live resource tracking (nullable = currently full) -------------------
  int? currentLife;
  int? currentKi;

  /// Capacity Points spent. Current Capacity is fully derived as
  /// `Max Capacity - capacitySpent` (unlike Life/Ki, Capacity is tracked by
  /// how much has been spent, not by an independent "current" value).
  int capacitySpent;

  /// A manual adjustment to the character's maximum Technique Points, for any
  /// TP source the engine can't auto-derive (a flat trait grant, a homebrew
  /// bonus, an ARC ruling). The computed maximum (Skill Improvements + Gifted
  /// Student + trait per-Skill-Improvement bonuses) is added to this — see
  /// `CharacterCalculator.techniquePointBudget`.
  int bonusTechniquePoints;

  /// Number of Super Stacks currently possessed (0..`CapacityRules.maxSuperStacks`).
  int superStacks;

  /// Default Resources/trackers every character has access to regardless of
  /// Talents (see `DefaultResourceRules`): stacks of the Power Up Maneuver's
  /// Power Resource (0..2), and the universal Diminishing Offense/Defense
  /// combat-attrition trackers. Unlike the freeform [resources] list below,
  /// these have known formulas and are auto-applied by the calculator.
  int powerStacks;
  int diminishingOffenseStacks;
  int diminishingDefenseStacks;

  /// Stacks of the Holding Back Special Maneuver (0..base Tier of Power —
  /// CONFIRMED verbatim: "Gain any number of Holding Back Stacks up to an
  /// amount equal to your base Tier of Power"). Auto-applied by the
  /// calculator: −1 Tier of Power per Stack (Stacks == base ToP → ToP set to
  /// 1 AND −1(bT) Combat Rolls), +1 Concealment Skill Bonus per Stack
  /// (max 3). Catalogue/homebrew automations reference it as the named
  /// resource 'Holding Back'.
  int holdingBackStacks;

  /// Whether the character passed the Steadfast Check for each Health
  /// Threshold — when true, that threshold's Combat Roll penalty is
  /// nullified (Thresholds & Conditions page).
  bool bruisedSteadfastPassed;
  bool injuredSteadfastPassed;
  bool criticalSteadfastPassed;

  /// Freeform tracked lists (Name/Stacks/Max Stacks/Notes) — see
  /// [TrackedEntry].
  final List<TrackedEntry> resources;
  final List<TrackedEntry> conditions;
  final List<TrackedEntry> states;

  /// Custom Buffs & Debuffs — see [CustomBuff].
  final List<CustomBuff> customBuffs;

  // --- Racial Traits / Information page --------------------------------------
  /// Names of canonical Racial Traits (see `race_traits.dart`) the player has
  /// switched OFF, typically because they exchanged that Trait for a
  /// compatible Factor's Trait instead (racial-rules framework page: "you
  /// may choose to swap this Trait out ... in exchange for the Trait
  /// belonging to that Factor"). The replacement itself is recorded in
  /// [factorTraits]. A name here has no effect unless it matches a Trait
  /// belonging to this character's current [race].
  final Set<String> inactiveRaceTraitNames;

  /// Racial Traits ADOPTED from other Races (an ARC-approved cross-Race
  /// pick — e.g. gained through a Transformation, story reward, or table
  /// ruling), stored as `'<Race>::<Trait name>'` references into the Racial
  /// Trait catalogue. Resolved by
  /// `CharacterCalculator.extraRaceTraitDefs` and merged into
  /// `activeRaceTraits`, so the adopted Trait's automation, Options and
  /// combat reminders all apply exactly like a native Trait. Managed from
  /// the Information tab's "Traits from other Races" section.
  final List<String> extraRaceTraits;

  /// Chosen Option(s) for Racial Traits with a `[Option]`/`[Multi-Option/N]`
  /// choice — see `RaceTraitOptionGroup` in `data/race_traits.dart`. Keyed
  /// by `'<Trait name>::<Option group label>'` (a Trait can have more than
  /// one choice point, e.g. Android's Technological Being has both a plain
  /// Option and a separate Multi-Option/2); value is the set of chosen
  /// `TraitOption.name`s, sized to that group's `maxChoices`.
  final Map<String, Set<String>> raceTraitOptionChoices;

  /// Racial Traits currently swapped out for a compatible Racial Factor's
  /// Factor Trait — see [FactorSelection]. Structured alternative to
  /// [factorTraits] below, used by the "Swap for Factor" picker on the
  /// Information page.
  final List<FactorSelection> factorSelections;

  /// Freeform record of Factor Traits gained WITHOUT exchanging a Racial
  /// Trait — not currently reachable through Character Creation (every
  /// Factor today requires swapping out a Racial Trait, see
  /// [factorSelections] instead), but the framework explicitly allows a
  /// Factor Trait to be "gained without exchanging a Racial Trait through
  /// the effects of a Trait" (in which case it's just a Secondary Trait
  /// outright) — this is reserved for that future case, expected once
  /// Awakenings that grant Factors are modeled. Reuses [TrackedEntry]'s
  /// Name/Notes shape purely for its free-text fields.
  final List<TrackedEntry> factorTraits;

  /// Racial Trait selections for a Custom Species character. A `TrackedEntry`
  /// whose `name` matches a catalogue Trait (`kDbuCustomSpeciesTraits`)
  /// resolves to that Trait's effects/automation; any other name is treated as
  /// freeform (no automation), as before.
  final List<TrackedEntry> customRaceTraits;

  /// Custom Species only: the (up to 2) **Primary** Racial Traits — the ones
  /// that gain their `[Twinned]` effects (the other selected Traits are
  /// Secondary, base effects only). Holds the `TrackedEntry.name`s.
  final Set<String> customPrimaryTraits;

  /// For a Custom Species character only: which Saving Throw receives the
  /// Racial Saving Throw Bonus. The site's rule is "Choose One (Impulsive,
  /// Cognitive, Corporeal or Morale)", so this normally holds exactly one
  /// entry — it stays a list because Traits (e.g. Big Personality) can add a
  /// second. Every other Race's Saving Throw(s) come from
  /// `RaceDef.savingThrows` instead — see `raceByName`.
  final List<DbuSavingThrow> customSavingThrows;

  /// For a Custom Species character only: the compensation chosen for each
  /// Flaw Trait taken, keyed by the Flaw's Trait name (verbatim, Step 7: "For
  /// each Flaw Trait you pick, either increase the Racial Life Modifier of
  /// your Race by 2 or increase the number of Skill Ranks granted by your Race
  /// by 1"). Only keys that also appear in [customRaceTraits] count — see
  /// `CharacterCalculator.racialLifeModifier` / `raceSkillRanks`. The Racial
  /// Skill Rank count and Racial Life Modifier are otherwise fixed by the
  /// `RaceDef('Custom Species')` baseline (2 and +3), not entered by hand.
  final Map<String, FlawCompensation> customFlawCompensation;

  /// Talents the character has taken — see [TalentEntry]. Prefilled from
  /// `data/talents.dart`'s catalogue when picked via a catalogue-picker
  /// dialog (Information tab or Progression tab), but a row can also be a
  /// freeform/homebrew entry typed by hand.
  final List<TalentEntry> talents;

  /// Player-authored HOMEBREW this character possesses, stored as CHOICES only
  /// (a name + whether it's currently active) exactly like every other
  /// catalogue pick. The definitions themselves live in the homebrew library
  /// and are resolved at compute time via `HomebrewRegistry.byName` — see
  /// `CharacterCalculator.activeHomebrew`.
  final List<HomebrewSelection> homebrewSelections;

  // --- Inventory ------------------------------------------------------------
  /// The character's owned items, grouped by [InventoryItem.category] into the
  /// Inventory page's four sections (Apparel / Weapons / Accessories / Gear).
  /// A freeform, un-automated tracker — see [InventoryItem]. Apparel is NOT
  /// stored here; it has its own fully-modelled [apparel] list.
  final List<InventoryItem> inventory;

  /// The character's Apparel — a structured, automated part of the Inventory
  /// (Grade/Category/Qualities feed derived stats). See [ApparelPiece] and
  /// `data/apparel.dart`.
  final List<ApparelPiece> apparel;

  /// The character's Weapons — a structured, automated part of the Inventory
  /// (Type/Size/Category/Qualities feed the Weapon Penalty, per-Attack combat
  /// modifiers, Life Points and Damage Reduction). See [WeaponPiece] and
  /// `data/weapons.dart`. Not stored as [InventoryItem]s.
  final List<WeaponPiece> weapons;

  /// The character's Accessories — catalogue picks whose "while equipped"
  /// effects feed derived stats (max 2 equipped). See [AccessorySelection] and
  /// `data/accessories.dart`. Not stored as [InventoryItem]s.
  final List<AccessorySelection> accessories;

  /// The character's Basic Items — catalogue picks (consumables/utilities) with
  /// a Quantity. Reference-only (Action-triggered, no passive stat effect). See
  /// [BasicItemSelection] and `data/basic_items.dart`.
  final List<BasicItemSelection> basicItems;

  // --- Signature Techniques -------------------------------------------------
  /// The character's Signature Techniques — player-built attacks whose TP/KP
  /// costs and per-technique combat modifiers are computed from the
  /// `data/signature_*.dart` catalogues. See [SignatureTechnique].
  final List<SignatureTechnique> signatureTechniques;

  // --- Unique Abilities -----------------------------------------------------
  /// The character's Unique Abilities — catalogue picks plus chosen Advancements
  /// / Restrictions; TP/KP costs are computed from `data/unique_abilities.dart`.
  /// See [UniqueAbilitySelection].
  final List<UniqueAbilitySelection> uniqueAbilities;

  // --- Progression ------------------------------------------------------
  /// One resolved choice per Progression grant slot, keyed
  /// `'$powerLevel:$slotIndex'` (slot index = position within
  /// `grantsForLevel(powerLevel)`) — see [ProgressionChoice].
  final Map<String, ProgressionChoice> progressionChoices;

  /// Freeform bonus Perks gained outside the Power Level Table (a Trait, or
  /// ARC benevolence) — see [BonusPerkEntry].
  final List<BonusPerkEntry> bonusPerks;

  // --- Transformations ------------------------------------------------------
  /// Transformations the character has gained access to (Awakenings /
  /// Enhancements / Forms) plus their per-Transformation state — see
  /// [TransformationSelection] and `data/transformations.dart`.
  final List<TransformationSelection> transformations;

  // --- Bookkeeping ----------------------------------------------------------
  final DateTime createdAt;
  DateTime updatedAt;

  /// Convenience: display name for the list, never blank.
  String get displayName => name.trim().isEmpty ? 'Unnamed Warrior' : name;

  /// Every known Skill gets an empty progress bucket so the sheet is complete.
  static Map<String, SkillProgress> _defaultSkills() =>
      {for (final s in kDbuSkills) s.name: SkillProgress()};

  /// Migrates a pre-rules save's freeform Custom Species Attribute bonus
  /// (`customAttributeIncreasePoints`, a raw per-Attribute map) onto the
  /// standard `RaceAttributeIncrease` choice slots the Race now uses (+2/+2/+1
  /// — see the `RaceDef('Custom Species')` entry). Returns `null` when the old
  /// values don't fit that shape (e.g. a homebrewed spread), in which case the
  /// player re-picks — no silently-wrong Scores.
  static List<DbuAttribute?>? _migrateLegacyCustomAttributePoints(Map? raw) {
    if (raw == null || raw.isEmpty) return null;
    final points = <DbuAttribute, int>{};
    raw.forEach((k, v) {
      final attr = DbuAttribute.values
          .cast<DbuAttribute?>()
          .firstWhere((a) => a?.name == k, orElse: () => null);
      final amount = (v as num?)?.toInt() ?? 0;
      if (attr != null && amount != 0) points[attr] = amount;
    });
    final twos = points.entries.where((e) => e.value == 2).toList();
    final ones = points.entries.where((e) => e.value == 1).toList();
    if (points.length != 3 || twos.length != 2 || ones.length != 1) return null;
    return [twos[0].key, twos[1].key, ones.single.key];
  }

  /// Computed Attribute Score = 1 (Character Creation baseline) + racial
  /// bonus (fixed + chosen slots) + every resolved Progression/Bonus-Perk
  /// Attribute Addition through the current [powerLevel]. No longer a
  /// directly-edited stored value — see `RaceAttributeIncrease` in
  /// `data/dbu_rules.dart`. Custom Species goes through the same path: its
  /// baseline is three choice slots (+2/+2/+1).
  int scoreOf(DbuAttribute attr) {
    var score = 1;
    // Homebrew-aware: a homebrew Race's Attribute Score Increases apply
    // exactly like an official Race's (official wins a name clash).
    final r = HomebrewRegistry.resolveRace(race);
    score += r.attributeIncrease.fixed[attr] ?? 0;
    for (var i = 0; i < r.attributeIncrease.choices.length; i++) {
      final picked = i < raceAttributeIncreaseChoices.length
          ? raceAttributeIncreaseChoices[i]
          : null;
      if (picked == attr) score += r.attributeIncrease.choices[i].amount;
    }
    score += _progressionAttributePointsFor(attr);
    return score;
  }

  /// Sums `attributePoints[attr]` across every resolved
  /// `ProgressionGrantKind.attributeAddition` slot (Main Progression +
  /// Bonus Perks) whose Power Level has been reached (or is unset, for a
  /// Bonus Perk that's "always on").
  int _progressionAttributePointsFor(DbuAttribute attr) {
    var total = 0;
    for (final level in kPowerLevelGrants) {
      if (level.powerLevel > powerLevel) continue;
      for (var slot = 0; slot < level.grants.length; slot++) {
        final choice = progressionChoices['${level.powerLevel}:$slot'];
        if (choice == null) continue;
        if (choice.resolvedKind != ProgressionGrantKind.attributeAddition) {
          continue;
        }
        total += choice.attributePoints[attr] ?? 0;
      }
    }
    for (final perk in bonusPerks) {
      if (perk.powerLevel != null && perk.powerLevel! > powerLevel) continue;
      if (perk.resolvedKind != ProgressionGrantKind.attributeAddition) {
        continue;
      }
      total += perk.attributePoints[attr] ?? 0;
    }
    return total;
  }

  /// Returns a fresh character with a new id and default stats.
  factory Character.blank(String id) => Character(id: id);

  // --- JSON (de)serialization ----------------------------------------------
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'player': player,
        'race': race,
        'subspecies': subspecies,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'hairColor': hairColor,
        'eyeColor': eyeColor,
        'skinTone': skinTone,
        'imageUrl': imageUrl,
        'size': size.name,
        'powerLevel': powerLevel,
        'raceAttributeIncreaseChoices':
            raceAttributeIncreaseChoices.map((a) => a?.name).toList(),
        'skills': skills.map((k, v) => MapEntry(k, v.toJson())),
        'zSoul': zSoul.toJson(),
        'currentLife': currentLife,
        'currentKi': currentKi,
        'capacitySpent': capacitySpent,
        'bonusTechniquePoints': bonusTechniquePoints,
        'superStacks': superStacks,
        'powerStacks': powerStacks,
        'holdingBackStacks': holdingBackStacks,
        'diminishingOffenseStacks': diminishingOffenseStacks,
        'diminishingDefenseStacks': diminishingDefenseStacks,
        'bruisedSteadfastPassed': bruisedSteadfastPassed,
        'injuredSteadfastPassed': injuredSteadfastPassed,
        'criticalSteadfastPassed': criticalSteadfastPassed,
        'resources': resources.map((r) => r.toJson()).toList(),
        'conditions': conditions.map((r) => r.toJson()).toList(),
        'states': states.map((r) => r.toJson()).toList(),
        'customBuffs': customBuffs.map((b) => b.toJson()).toList(),
        'inactiveRaceTraitNames': inactiveRaceTraitNames.toList(),
        'extraRaceTraits': extraRaceTraits,
        'raceTraitOptionChoices': raceTraitOptionChoices
            .map((k, v) => MapEntry(k, v.toList())),
        'factorSelections':
            factorSelections.map((f) => f.toJson()).toList(),
        'factorTraits': factorTraits.map((r) => r.toJson()).toList(),
        'customRaceTraits': customRaceTraits.map((r) => r.toJson()).toList(),
        'customPrimaryTraits': customPrimaryTraits.toList(),
        'customSavingThrows':
            customSavingThrows.map((sv) => sv.name).toList(),
        'customFlawCompensation':
            customFlawCompensation.map((k, v) => MapEntry(k, v.name)),
        'talents': talents.map((t) => t.toJson()).toList(),
        'homebrewSelections':
            homebrewSelections.map((h) => h.toJson()).toList(),
        'inventory': inventory.map((i) => i.toJson()).toList(),
        'apparel': apparel.map((a) => a.toJson()).toList(),
        'weapons': weapons.map((w) => w.toJson()).toList(),
        'accessories': accessories.map((a) => a.toJson()).toList(),
        'basicItems': basicItems.map((b) => b.toJson()).toList(),
        'signatureTechniques':
            signatureTechniques.map((s) => s.toJson()).toList(),
        'uniqueAbilities':
            uniqueAbilities.map((u) => u.toJson()).toList(),
        'progressionChoices':
            progressionChoices.map((k, v) => MapEntry(k, v.toJson())),
        'bonusPerks': bonusPerks.map((p) => p.toJson()).toList(),
        'transformations':
            transformations.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Character.fromJson(Map<String, dynamic> json) {
    // Old saves stored a flat 'attributeScores' map; that key is now simply
    // ignored (Attribute Scores are computed — see `scoreOf`).
    final rawChoices = (json['raceAttributeIncreaseChoices'] as List?) ?? const [];
    final raceAttrChoices = rawChoices.map((v) {
      return DbuAttribute.values
          .cast<DbuAttribute?>()
          .firstWhere((a) => a?.name == v, orElse: () => null);
    }).toList();
    if (raceAttrChoices.every((a) => a == null)) {
      final migrated = _migrateLegacyCustomAttributePoints(
          json['customAttributeIncreasePoints'] as Map?);
      if (migrated != null) {
        raceAttrChoices
          ..clear()
          ..addAll(migrated);
      }
    }

    final rawFlaws = (json['customFlawCompensation'] as Map?) ?? const {};
    final flawComp = <String, FlawCompensation>{};
    rawFlaws.forEach((k, v) {
      final pick = FlawCompensation.values
          .cast<FlawCompensation?>()
          .firstWhere((f) => f?.name == v, orElse: () => null);
      if (k is String && pick != null) flawComp[k] = pick;
    });

    // Skills: start from the full default set, then overlay saved ranks so that
    // newly-added skills automatically appear on old characters.
    final skills = _defaultSkills();
    final rawSkills = (json['skills'] as Map?) ?? const {};
    rawSkills.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        skills[key as String] = SkillProgress.fromJson(value);
      }
    });

    return Character(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      player: json['player'] as String? ?? '',
      race: json['race'] as String? ?? 'Custom Species',
      subspecies: json['subspecies'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      hairColor: json['hairColor'] as String? ?? '',
      eyeColor: json['eyeColor'] as String? ?? '',
      skinTone: json['skinTone'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      size: DbuSize.values.firstWhere(
        (s) => s.name == json['size'],
        orElse: () => DbuSize.medium,
      ),
      powerLevel: (json['powerLevel'] as num?)?.toInt() ?? 1,
      raceAttributeIncreaseChoices: raceAttrChoices,
      skills: skills,
      zSoul: json['zSoul'] is Map<String, dynamic>
          ? ZSoul.fromJson(json['zSoul'] as Map<String, dynamic>)
          : ZSoul(),
      currentLife: (json['currentLife'] as num?)?.toInt(),
      currentKi: (json['currentKi'] as num?)?.toInt(),
      capacitySpent: (json['capacitySpent'] as num?)?.toInt() ?? 0,
      bonusTechniquePoints:
          (json['bonusTechniquePoints'] as num?)?.toInt() ?? 0,
      superStacks: (json['superStacks'] as num?)?.toInt() ?? 0,
      powerStacks: (json['powerStacks'] as num?)?.toInt() ?? 0,
      holdingBackStacks: (json['holdingBackStacks'] as num?)?.toInt() ?? 0,
      diminishingOffenseStacks:
          (json['diminishingOffenseStacks'] as num?)?.toInt() ?? 0,
      diminishingDefenseStacks:
          (json['diminishingDefenseStacks'] as num?)?.toInt() ?? 0,
      bruisedSteadfastPassed: json['bruisedSteadfastPassed'] as bool? ?? false,
      injuredSteadfastPassed: json['injuredSteadfastPassed'] as bool? ?? false,
      criticalSteadfastPassed:
          json['criticalSteadfastPassed'] as bool? ?? false,
      resources: _entriesFromJson(json['resources']),
      conditions: _entriesFromJson(json['conditions']),
      states: _entriesFromJson(json['states']),
      customBuffs: ((json['customBuffs'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomBuff.fromJson)
          .toList(),
      inactiveRaceTraitNames: ((json['inactiveRaceTraitNames'] as List?) ??
              const [])
          .whereType<String>()
          .toSet(),
      extraRaceTraits: ((json['extraRaceTraits'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      raceTraitOptionChoices:
          ((json['raceTraitOptionChoices'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          ((v as List?) ?? const []).whereType<String>().toSet(),
        ),
      ),
      factorSelections: ((json['factorSelections'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FactorSelection.fromJson)
          .toList(),
      factorTraits: _entriesFromJson(json['factorTraits']),
      customRaceTraits: _entriesFromJson(json['customRaceTraits']),
      customPrimaryTraits: ((json['customPrimaryTraits'] as List?) ?? const [])
          .whereType<String>()
          .toSet(),
      customSavingThrows: ((json['customSavingThrows'] as List?) ?? const [])
          .whereType<String>()
          .map((name) => DbuSavingThrow.values
              .cast<DbuSavingThrow?>()
              .firstWhere((sv) => sv?.name == name, orElse: () => null))
          .whereType<DbuSavingThrow>()
          .toList(),
      customFlawCompensation: flawComp,
      talents: ((json['talents'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TalentEntry.fromJson)
          .toList(),
      homebrewSelections: ((json['homebrewSelections'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(HomebrewSelection.fromJson)
          .toList(),
      inventory: ((json['inventory'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InventoryItem.fromJson)
          .toList(),
      apparel: ((json['apparel'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ApparelPiece.fromJson)
          .toList(),
      weapons: ((json['weapons'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WeaponPiece.fromJson)
          .toList(),
      accessories: ((json['accessories'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AccessorySelection.fromJson)
          .toList(),
      basicItems: ((json['basicItems'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BasicItemSelection.fromJson)
          .toList(),
      signatureTechniques: ((json['signatureTechniques'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SignatureTechnique.fromJson)
          .toList(),
      uniqueAbilities: ((json['uniqueAbilities'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(UniqueAbilitySelection.fromJson)
          .toList(),
      progressionChoices:
          ((json['progressionChoices'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          ProgressionChoice.fromJson(v as Map<String, dynamic>),
        ),
      ),
      bonusPerks: ((json['bonusPerks'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BonusPerkEntry.fromJson)
          .toList(),
      transformations: ((json['transformations'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TransformationSelection.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  static List<TrackedEntry> _entriesFromJson(Object? raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TrackedEntry.fromJson)
          .toList();

  /// Deep-ish copy used by the editor so edits can be cancelled without
  /// mutating the stored original until the user taps Save.
  Character copy() => Character.fromJson(jsonDecode(jsonEncode(toJson())));
}
