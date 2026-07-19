/// weapons.dart
/// ---------------------------------------------------------------------------
/// Static rules data for the WEAPONS sub-system (Inventory page → Weapons).
/// Single source of truth for everything the calculator/UI needs to model a
/// Weapon exactly as the live site's "Weapons" article defines it:
///
///   • [WeaponType]             — Physical / Energy / Magic (chosen at creation;
///                                decides which Weapon Categories are available
///                                and which Wound Roll the Weapon feeds).
///   • [WeaponSize]             — Small / Standard / Big, each adjusting the
///                                Strike/Wound Rolls of Attacks made with it
///                                (and the Shield Category's Life-Point scaling).
///   • [kDbuWeaponCategories]   — the Weapon Categories per Type (Physical:
///                                Bludgeoning/Slashing/Piercing/Shield; Energy:
///                                Efficient/Precision/High Power; Magic: Magic
///                                Staff/Elemental Tool/Magic Orb), effects
///                                transcribed verbatim.
///   • [kDbuWeaponQualities]    — the full Weapon Qualities catalogue (standard
///                                + Special), transcribed verbatim, each with
///                                its Type restriction, Prereq text, Quality-Slot
///                                count (or range) and Effects.
///
/// The Craftsmanship Grade table (Grade 1–5 → Craft DC / Quality-Slot budget) is
/// SHARED with Apparel — a Weapon has no Low/Standard/High "Grade" of its own,
/// only the Craft DC and Quality-Slot columns matter — so the calculator reuses
/// `craftsmanshipInfo` from `apparel.dart` rather than duplicating the table.
///
/// AUTOMATION. Like Apparel, only the numerically unambiguous, always-on-while-
/// wielded effects are auto-applied; the rest are shown as reference text
/// (`automation == null`). A Quality's [WeaponQualityAutomation]/a Category's
/// automation captures the parts the engine can resolve: a per-Attack Strike/
/// Wound change, extra Weapon Life Points, a Damage-Reduction bonus, or the
/// Unbreakable flag. Situational or narrative effects (Called Shots, Throw
/// Maneuver, Profiles, Clashes, granted Basic Items, etc.) are left un-automated.
///
/// PROVENANCE: transcribed from the offline ZIM archive's `/weapons/` article
/// (dbu-rpg.com, 2026-07-03 backup) — see the `zim-archive-lookup` memory note.
/// ---------------------------------------------------------------------------
library;

// --- Weapon-wide constants (verbatim from the Weapons article) -------------

/// "Each Weapon starts with 32 Life Points and gains 8 Life Points each Power
/// Level."
const int kWeaponBaseLifePoints = 32;
const int kWeaponLifePointsPerLevel = 8;

/// "Weapons have Damage Reduction of 6(bT)." (the Weapon's own DR, used when an
/// Opponent Called-Shots the Weapon — not the wielder's DR).
const int kWeaponDamageReductionPerBaseTier = 6;

/// "Weapons have a Hardness Value of 2 by default." (throwing only — not added
/// to the Wound Roll).
const int kWeaponHardnessValue = 2;

/// "While wielding any type of Weapon, reduce your Strike Rolls by 2(T). To
/// remove the Weapon Penalty, gain the Weapon Specialist Talent."
const int kWeaponPenaltyPerTier = 2;

/// "You can only wield two Weapons at any one time."
const int kMaxWieldedWeapons = 2;

/// The Talent name that removes the Weapon Penalty (see `data/talents.dart`).
const String kWeaponSpecialistTalentName = 'Weapon Specialist';

/// The three Weapon Types. The chosen Type decides which Weapon Categories are
/// available and which Wound Roll (Physical/Energy/Magic) the Weapon feeds.
enum WeaponType {
  physical('Physical'),
  energy('Energy'),
  magic('Magic');

  const WeaponType(this.displayName);
  final String displayName;
}

/// Weapon Size (CONFIRMED, verbatim):
///   • Small:    Strike +1(T), Wound -2(T). (Shield: 1 Life Point per PL.)
///   • Standard: no influence on Combat Rolls.  (Shield: 2 Life Points per PL.)
///   • Big:      Strike -1(T), Wound +2(T). (Shield: 3 Life Points per PL.)
/// The Shield Weapon Category scales its bonus Life Points by "1 for Small
/// Weapons, 2 for Standard Weapons, and 3 for Large Weapons" — captured here as
/// [shieldLifePointsPerLevel].
enum WeaponSize {
  small('Small', strikePerTier: 1, woundPerTier: -2, shieldLifePointsPerLevel: 1),
  standard('Standard',
      strikePerTier: 0, woundPerTier: 0, shieldLifePointsPerLevel: 2),
  big('Big', strikePerTier: -1, woundPerTier: 2, shieldLifePointsPerLevel: 3);

  const WeaponSize(
    this.displayName, {
    required this.strikePerTier,
    required this.woundPerTier,
    required this.shieldLifePointsPerLevel,
  });

  final String displayName;

  /// `x` in "Strike Rolls ... by x(T)" from this Size.
  final int strikePerTier;

  /// `x` in "Wound Rolls ... by x(T)" from this Size.
  final int woundPerTier;

  /// Shield Category bonus Life Points per Power Level for this Size.
  final int shieldLifePointsPerLevel;
}

// --- Weapon Categories -----------------------------------------------------

/// One Weapon Category (e.g. Slashing, High Power, Magic Staff). Each belongs to
/// exactly one [WeaponType] and grants its [effects] while wielding a Weapon of
/// that Category. The numerically-applicable parts are captured as fields; the
/// rest live in the verbatim [effects] text.
class WeaponCategoryDef {
  const WeaponCategoryDef({
    required this.name,
    required this.type,
    required this.description,
    required this.effects,
    this.woundBonusPerTier = 0,
    this.grantsShieldLifePoints = false,
    this.grantedQuality = '',
  });

  final String name;
  final WeaponType type;

  /// The Category's short flavour sentence (the line before "–Effects:").
  final String description;

  /// The verbatim Effects text.
  final String effects;

  /// An always-on "increase the Wound Rolls of Attacking Maneuvers with this
  /// Weapon by x(T)" this Category grants (Slashing, Magic Orb → 2). Feeds the
  /// Weapon's own Wound Roll (Physical/Energy/Magic per its Type).
  final int woundBonusPerTier;

  /// Whether this Category grants the Shield Life-Point scaling (Shield only).
  final bool grantsShieldLifePoints;

  /// A Weapon Quality this Category grants for free (not counting toward Quality
  /// Slots) — Bludgeoning→Staggering, Piercing→Lasting Wounds, Precision→Far
  /// Sight, Magic Orb→Spiritual Weapon. Informational (its own effect is shown
  /// on the granted Quality); '' when none.
  final String grantedQuality;
}

/// The full Weapon Categories catalogue, grouped by Type. Effects verbatim.
const List<WeaponCategoryDef> kDbuWeaponCategories = [
  // --- Physical -------------------------------------------------------------
  WeaponCategoryDef(
    name: 'Bludgeoning',
    type: WeaponType.physical,
    description: 'This Weapon is a blunt, dull object used for bashing enemies.',
    effects:
        "Attacking Maneuvers made with this Weapon ignore 1/2 of your target's "
        'Damage Reduction. This Weapon also possesses the Staggering Weapon '
        'Quality (this Weapon Quality does not count towards your Quality Slots).',
    grantedQuality: 'Staggering',
  ),
  WeaponCategoryDef(
    name: 'Slashing',
    type: WeaponType.physical,
    description: 'A sharp blade on this Weapon is meant for cutting open enemy '
        'flesh and leaving large wounds.',
    effects:
        'Apply any Diminishing Defense from Attacking Maneuvers made with this '
        'Weapon at Attack Declaration. Additionally, increase the Wound Rolls of '
        'Attacking Maneuvers with this Weapon by 2(T).',
    woundBonusPerTier: 2,
  ),
  WeaponCategoryDef(
    name: 'Piercing',
    type: WeaponType.physical,
    description: "Intended for penetrating a target's vital points and damaging "
        'organs, this Weapon is sharp and lethal.',
    effects:
        'Attacking Maneuvers made with this Weapon ignore 1/4 (rounded up) of '
        "your target's Soak Value (before any reductions). This Weapon also "
        'possesses the Lasting Wounds Weapon Quality (this Weapon Quality does '
        'not count towards your Quality Slots).',
    grantedQuality: 'Lasting Wounds',
  ),
  WeaponCategoryDef(
    name: 'Shield',
    type: WeaponType.physical,
    description: 'This Weapon is intended for defense, rather than offense.',
    effects:
        'Increase the Life Points of this Weapon by x for each of your Power '
        'Levels. X is 1 for Small Weapons, 2 for Standard Weapons, and 3 for '
        'Large Weapons. Additionally, while you are wielding this Weapon, you '
        'gain access to the Block Special Maneuver.',
    grantsShieldLifePoints: true,
  ),
  // --- Energy ---------------------------------------------------------------
  WeaponCategoryDef(
    name: 'Efficient',
    type: WeaponType.energy,
    description:
        'This Weapon is easy to use, allowing for the user to expend less energy.',
    effects:
        'Attacking Maneuvers made using this Weapon have their Ki Point Cost '
        'reduced by 2(T). Additionally, increase the Wound Rolls of Attacking '
        'Maneuvers made with the Simple Profile by 2(T).',
  ),
  WeaponCategoryDef(
    name: 'Precision',
    type: WeaponType.energy,
    description: 'This Weapon has precision accuracy intended for lethal damage '
        'dealt from far away.',
    effects:
        'Increase the Strike and Wound Rolls for any Called Shot made using '
        'this Weapon by 1(T) and 2(T) respectively. This Weapon also possesses '
        'the Far Sight Weapon Quality (this Weapon Quality does not count '
        'towards your Quality Slots).',
    grantedQuality: 'Far Sight',
  ),
  WeaponCategoryDef(
    name: 'High Power',
    type: WeaponType.energy,
    description:
        'This Weapon funnels energy into massive blasts of pure destruction.',
    effects:
        'Apply an Energy Charge to any Attacking Maneuver made using this Weapon '
        'with a Ki Wager equal to or exceeding 1/2 of your Max Capacity. '
        'Additionally, increase the Magnitude of any Attacking Maneuver that '
        'possesses an AoE used by this Weapon by 1 Magnitude.',
  ),
  // --- Magic ----------------------------------------------------------------
  WeaponCategoryDef(
    name: 'Magic Staff',
    type: WeaponType.magic,
    description:
        'This Weapon is a mystical staff which empowers magical attacks.',
    effects:
        'While wielding this Weapon, reduce the Ki Point Cost of your Magic '
        'Attacks and your Magical Unique Abilities by 2(T). Additionally, while '
        'wielding this Weapon, increase the Dice Score of your Use Magic Skill '
        'Checks by 2.',
  ),
  WeaponCategoryDef(
    name: 'Elemental Tool',
    type: WeaponType.magic,
    description: 'This Weapon possesses the mystical means to influence the '
        'natural world, and may not look like a Weapon at all.',
    effects:
        "Upon creating this Weapon, select a Profile with 'Elemental' in the "
        'name. While wielding this Weapon, that Element becomes a Favored '
        'Element.',
  ),
  WeaponCategoryDef(
    name: 'Magic Orb',
    type: WeaponType.magic,
    description: 'This Weapon allows you to see your enemies from far away.',
    effects:
        'This Weapon possesses the Spiritual Weapon Quality (this Weapon Quality '
        'does not count towards your Quality Slots). Additionally, increase the '
        'Wound Rolls of Attacking Maneuvers with this Weapon by 2(T).',
    woundBonusPerTier: 2,
    grantedQuality: 'Spiritual Weapon',
  ),
];

/// Looks up a Weapon Category by exact [name], or `null` if unknown.
WeaponCategoryDef? weaponCategoryByName(String name) {
  for (final cat in kDbuWeaponCategories) {
    if (cat.name == name) return cat;
  }
  return null;
}

/// The Categories available to a given Weapon [type] (for the picker).
List<WeaponCategoryDef> weaponCategoriesFor(WeaponType type) =>
    kDbuWeaponCategories.where((cat) => cat.type == type).toList();

// --- Weapon Qualities ------------------------------------------------------

/// Which Combat Roll a [WeaponStatEffect] targets. `wound` resolves to the
/// Weapon's own Wound Roll (Physical/Energy/Magic per its [WeaponType]) at
/// compute time.
enum WeaponEffectTarget { strike, wound }

/// How the magnitude of a [WeaponStatEffect] is derived:
///   • [perTier]     — `coefficient` × Tier of Power.
///   • [perBaseTier] — `coefficient` × Base Tier of Power.
enum WeaponEffectBasis { perTier, perBaseTier }

/// A single automated Combat-Roll change granted by a Weapon Quality while the
/// Weapon is wielded. Sign lives in [coefficient]. When [perSlot] is true the
/// magnitude is multiplied by the number of Quality Slots the Quality occupies
/// (Artisan: "for each Quality Slot ... increase your Wound Rolls ... by 1(T)").
class WeaponStatEffect {
  const WeaponStatEffect({
    required this.target,
    required this.coefficient,
    required this.basis,
    this.perSlot = false,
  });

  final WeaponEffectTarget target;
  final int coefficient;
  final WeaponEffectBasis basis;
  final bool perSlot;
}

/// The auto-applicable part of a Weapon Quality's effect.
class WeaponQualityAutomation {
  const WeaponQualityAutomation({
    this.statEffects = const [],
    this.lifePointsPerLevel = 0,
    this.lifePointsPerLevelPerSlot = false,
    this.damageReductionPerBaseTier = 0,
    this.unbreakable = false,
  });

  /// Per-Attack Strike/Wound changes (Artisan, Giant Weapon, Super Heavy…).
  final List<WeaponStatEffect> statEffects;

  /// Extra Weapon Life Points per Power Level (Durable: 2). Multiplied by the
  /// occupied Quality Slots when [lifePointsPerLevelPerSlot] is true.
  final int lifePointsPerLevel;
  final bool lifePointsPerLevelPerSlot;

  /// A Damage-Reduction bonus (to the WIELDER) while wielding this Weapon
  /// (Warding Weapon: 2(bT)).
  final int damageReductionPerBaseTier;

  /// The Weapon cannot have its Life Points reduced (Unbreakable).
  final bool unbreakable;
}

/// One entry in the Weapon Qualities catalogue.
class WeaponQualityDef {
  const WeaponQualityDef({
    required this.name,
    required this.types,
    required this.prerequisites,
    required this.minSlots,
    required this.maxSlots,
    required this.effects,
    this.isSpecial = false,
    this.automation,
  });

  final String name;

  /// Which Weapon Types may take this Quality (a Type restriction of "All" /
  /// "Any" / "N/A" on the site maps to all three Types).
  final Set<WeaponType> types;

  /// The Prerequisite text (applies to the WIELDER, not the crafter) — "N/A"
  /// when there is none. Not auto-checked (like other catalogue prereqs).
  final String prerequisites;

  /// Quality-Slot cost. Equal for a fixed cost; a range (e.g. 1~2, 1~3) when
  /// the player may choose how many Slots it occupies.
  final int minSlots;
  final int maxSlots;

  /// The verbatim Effects text.
  final String effects;

  /// Special Weapon Qualities are ARC-granted and "very powerful" — the site
  /// warns against more than one per Weapon. Surfaced separately in the picker.
  final bool isSpecial;

  /// The auto-applicable part of the effect, or `null` when the Quality is
  /// reference-only (situational/narrative — not applied to any stat).
  final WeaponQualityAutomation? automation;

  bool get hasSlotRange => maxSlots > minSlots;
  bool get isAutomated => automation != null;

  /// A short "1" / "1~2" label for the Slot cost.
  String get slotLabel => hasSlotRange ? '$minSlots~$maxSlots' : '$minSlots';
}

const Set<WeaponType> _allTypes = {
  WeaponType.physical,
  WeaponType.energy,
  WeaponType.magic,
};
const Set<WeaponType> _energyMagic = {WeaponType.energy, WeaponType.magic};
const Set<WeaponType> _physicalEnergy = {WeaponType.physical, WeaponType.energy};
const Set<WeaponType> _physical = {WeaponType.physical};

/// The full Weapon Qualities catalogue (standard first, then Special). Effects
/// text is transcribed verbatim from the site.
const List<WeaponQualityDef> kDbuWeaponQualities = [
  // --- Standard Weapon Qualities -------------------------------------------
  WeaponQualityDef(
    name: 'Artisan',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'For each Quality Slot taken up by the Artisan Quality, increase your '
        'Wound Rolls made with this Weapon by 1(T).',
    automation: WeaponQualityAutomation(
      statEffects: [
        WeaponStatEffect(
          target: WeaponEffectTarget.wound,
          coefficient: 1,
          basis: WeaponEffectBasis.perTier,
          perSlot: true,
        ),
      ],
    ),
  ),
  WeaponQualityDef(
    name: 'Barrage Weapon',
    types: _physical,
    prerequisites: 'Throwing Weapon',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'When using the Throw Maneuver to throw this Weapon, you may use the '
        'Combination Profile (Physical) instead of the Simple Profile.',
  ),
  WeaponQualityDef(
    name: 'Boomerang',
    types: _physical,
    prerequisites: 'Throwing Weapon Weapon Quality, you do not have the '
        'Multi-Storage Weapon Quality.',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'If you throw this Weapon through the Throw Maneuver, you may equip it '
        'again immediately, ignoring the distance between you and the Weapon.\n\n'
        'If this Weapon Quality takes up 2 Slots, apply the Homing Advantage to '
        'any Attacking Maneuver made with this Weapon through the Throw Maneuver.',
  ),
  WeaponQualityDef(
    name: 'Breaker',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'If you hit a piece of Apparel with this Weapon, double the loss of '
        'Break Value. If you hit a Weapon instead, increase the Damage dealt to '
        'that Weapon by 1/4 (rounded up).',
  ),
  WeaponQualityDef(
    name: 'Burst Fire',
    types: _energyMagic,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'When making an Attacking Maneuver using this Weapon, you may spend any '
        'number of Actions, this Attacking Maneuver gains an Energy Charge for '
        'each Action spent.',
  ),
  WeaponQualityDef(
    name: 'Concealed',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'The first Armed Attack you make with this Weapon each Combat Round, '
        'make a Clash (Stealth vs Perception) against the target(s) of that '
        'Attacking Maneuver. If you win, they have the Guard Down Combat '
        'Condition against this Attacking Maneuver.',
  ),
  WeaponQualityDef(
    name: 'Controller Weapon',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'Upon applying this Weapon Quality, this Weapon can be treated as the '
        'Remote Control Basic Item. Select what this Remote Control is attuned '
        'to upon applying the Weapon Quality. If this Weapon Quality takes up 2 '
        'Quality Slots, this Remote Control can be used for all Items of that '
        'type (Vehicles/Battle Jackets still require the appropriate '
        'Quality/Trait to be used with a Remote Control).',
  ),
  WeaponQualityDef(
    name: 'Duelist',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Strike Rolls when using the Parry effect of the Defend '
        'Maneuver by 1(T).',
  ),
  WeaponQualityDef(
    name: 'Durable',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        "Increase this Weapon's Life Points by 2 for each of your Power Levels. "
        'If this takes up 2 Quality Slots, double the amount of Life Points '
        'gained from this Weapon Quality.',
    automation: WeaponQualityAutomation(
      lifePointsPerLevel: 2,
      lifePointsPerLevelPerSlot: true,
    ),
  ),
  WeaponQualityDef(
    name: 'Extending',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Melee Range by 3 for the duration of any Attacking '
        'Maneuvers made with this Weapon. If the Attacking Maneuver has an AoE, '
        'instead increase the Magnitude by 1, except for the Line AoE.',
  ),
  WeaponQualityDef(
    name: 'Far Sight',
    types: _energyMagic,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Ignore the penalties for Long Range for Armed Attacks made using this '
        'Weapon.',
  ),
  WeaponQualityDef(
    name: 'Flexible',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'For each Quality Slot this Weapon Quality takes up, select a different '
        'Weapon Category of the same Foundation for this Weapon. At the start of '
        'your turn, you may change this Weapon’s Weapon Category to any '
        'other Weapon Category selected from this Weapon Quality until the end '
        'of your turn.',
  ),
  WeaponQualityDef(
    name: 'Giant Weapon',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 2,
    maxSlots: 2,
    effects:
        'Increase your Wound Rolls with this Weapon by 3(T). Reduce your Strike '
        'Rolls with this Weapon by 1(T) for every Size Category you are smaller '
        'than Enormous.',
    // Only the flat +3(T) Wound is automated; the Strike reduction scales with
    // how many Size Categories below Enormous you are — Enormous isn't a Size
    // this app models (creation Sizes are Small/Medium/Large), so that part is
    // left to the player (shown in the effects text).
    automation: WeaponQualityAutomation(
      statEffects: [
        WeaponStatEffect(
          target: WeaponEffectTarget.wound,
          coefficient: 3,
          basis: WeaponEffectBasis.perTier,
        ),
      ],
    ),
  ),
  WeaponQualityDef(
    name: 'High-Tech',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Your Damage Attribute for any Attacking Maneuver made with this Weapon '
        'is Scholarship.',
  ),
  WeaponQualityDef(
    name: 'Lasting Wounds',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'If you deal Damage with an Attacking Maneuver that uses this Weapon, '
        'inflict one stack of DOT on an Opponent until the start of your next '
        'turn.',
  ),
  WeaponQualityDef(
    name: 'Long Range Weapon',
    types: _energyMagic,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Increase your Strike Rolls by 1(T) against Opponents that are 9+ '
        'Squares away from you.',
  ),
  WeaponQualityDef(
    name: 'Multi-Storage',
    types: _physical,
    prerequisites: 'Throwing Weapon, this Weapon does not have the Boomerang '
        'Weapon Quality',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'If you use the Throw Maneuver for this Weapon, instead of throwing this '
        'Weapon, use a copy of this Weapon instead. That copy of this Weapon '
        'ceases to exist after you complete the Throw Maneuver. You may use the '
        'Throw Maneuver to throw this Weapon up to 3 times per Combat Round, '
        'instead of the usual 1/Round limitation for the Throw Maneuver.',
  ),
  WeaponQualityDef(
    name: 'Quick Draw',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'When you Unsheathe this Weapon, if your next Maneuver is an Attacking '
        'Maneuver, increase the Strike Roll of that Attacking Maneuver by 1(T). '
        'If you would Sheathe this Weapon, increase the Wound Roll of the next '
        'Attacking Maneuver you would make with this Weapon by 2(T).',
  ),
  WeaponQualityDef(
    name: 'Shishkebab',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 3,
    effects:
        'While this Weapon is equipped, you may spend 1 Action to gain a Snack '
        'Basic Item. You can use this effect a number of times per Combat '
        'Encounter equal to the number of Quality Slots this Weapon Quality is '
        'occupying. This effect cannot be used if this Weapon is created through '
        'Magic Materialization or through the Ki Blade Enhancement.',
  ),
  WeaponQualityDef(
    name: 'Spiritual Weapon',
    types: _allTypes,
    prerequisites: '2+ Skill Ranks in Clairvoyance or Use Magic',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'This Weapon is also treated as a Crystal Ball (see — Basic Items).',
  ),
  WeaponQualityDef(
    name: 'Staggering',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'If an Attacking Maneuver with this Weapon knocks an Opponent through a '
        'Health Threshold, make a Might Clash against them. If you win, they are '
        'knocked Prone.',
  ),
  WeaponQualityDef(
    name: 'Targeting System',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'Increase the Natural Result of any Strike Roll made as part of an '
        'Attacking Maneuver with this Weapon by the amount of Quality Slots it '
        'occupies.',
  ),
  WeaponQualityDef(
    name: 'Telekinetic',
    types: _allTypes,
    prerequisites: 'The wielder has the Telekinesis Unique Ability.',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'Wielding this Weapon does not count towards your maximum number of '
        'Weapons you’re able to wield. Also, when making an Attacking '
        'Maneuver with this Weapon, it can originate from any square within a '
        'Large Sphere AoE (centered on you) as if you were on that square.',
  ),
  WeaponQualityDef(
    name: 'Throwing Weapon',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    effects:
        'If this Weapon hits an Opponent with the use of the Throw Maneuver, '
        'apply the effects of its Weapon Category and any qualifying Weapon '
        'Qualities.',
  ),
  WeaponQualityDef(
    name: 'Transforming Weapon',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'For each Quality Slot this Weapon Quality takes up, select a Weapon '
        'Category of a different Weapon Type. You may use this Weapon as if it '
        'was a Weapon of that Weapon Category and Weapon Type. If you do, it has '
        'the same Weapon Size as this Weapon, but only benefits from other '
        'Weapon Qualities that are applicable to that Weapon Type.',
  ),
  WeaponQualityDef(
    name: 'Variable',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 2,
    effects:
        'Select an additional Weapon Size upon applying this Weapon Quality for '
        'each Quality Slot it takes up. During your turn, you can use the No '
        'Effort Maneuver to change this Weapon’s Weapon Size to another '
        'Weapon Size selected upon gaining this Quality or back to its original '
        'Weapon Size.',
  ),
  // --- Special Weapon Qualities --------------------------------------------
  WeaponQualityDef(
    name: 'Dimension Blade',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'Increase the Damage Category of all Attacking Maneuvers made with this '
        'Weapon by 1 Category. Each Attacking Maneuver made with this Weapon '
        'reduces the Life Points of this Weapon by 1/10 of its Maximum Life '
        'Points.',
  ),
  WeaponQualityDef(
    name: 'Elemental Blade',
    types: _physicalEnergy,
    prerequisites: 'N/A',
    minSlots: 2,
    maxSlots: 2,
    isSpecial: true,
    effects:
        "Upon creating this Weapon, select a Profile with 'Elemental' in the "
        'name. Apply the Multi-Profile Super Profile to any Attacking Maneuvers '
        'you use, with the Profile selected for the Multi-Profile Super Profile '
        'being the Elemental Profile you selected. If it meets the '
        'Prerequisites, also apply the Compressed Element Disadvantage to those '
        'Attacking Maneuvers.',
  ),
  WeaponQualityDef(
    name: 'Elongation',
    types: _physical,
    prerequisites: 'Extension Weapon Quality',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'When making an Attacking Maneuver with this Weapon, the entire '
        'Battlefield is your Melee Range. If an Attacking Maneuver made with '
        'this Weapon has an AoE, increase the Magnitude for that AoE by 2. This '
        'effect replaces the effects of the Extension Weapon Quality.',
  ),
  WeaponQualityDef(
    name: 'Karmic Edge',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'When this Weapon is created, select either Good/Pure Good or Evil/Pure '
        'Evil. Apply an Energy Charge to all Attacking Maneuvers using this '
        'Weapon against Opponents whose Alignment matches the chosen Alignments.',
  ),
  WeaponQualityDef(
    name: 'Regenerating',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        "At the end of each Combat Encounter, this Weapon's Life Points are "
        'completely recovered. If it was destroyed during the Combat Encounter, '
        'it is completely repaired.',
  ),
  WeaponQualityDef(
    name: 'Super Heavy',
    types: _physical,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'Reduce your Strike Rolls with this Weapon by 2(bT), but increase your '
        'Wound Rolls by 5(bT). The Hardness Value for this Weapon is 4.\n\n'
        'While using this Weapon over time, you can become accustomed to the '
        'intense weight. Your ARC decides when this occurs, but when it does, '
        'remove the reduction to your Strike Rolls while using this Weapon.',
    automation: WeaponQualityAutomation(
      statEffects: [
        WeaponStatEffect(
          target: WeaponEffectTarget.strike,
          coefficient: -2,
          basis: WeaponEffectBasis.perBaseTier,
        ),
        WeaponStatEffect(
          target: WeaponEffectTarget.wound,
          coefficient: 5,
          basis: WeaponEffectBasis.perBaseTier,
        ),
      ],
    ),
  ),
  WeaponQualityDef(
    name: 'Unbreakable',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'This Weapon cannot be destroyed by any means. You cannot use effects '
        'that would reduce the Life Points of this Weapon.',
    automation: WeaponQualityAutomation(unbreakable: true),
  ),
  WeaponQualityDef(
    name: 'Warding Weapon',
    types: _allTypes,
    prerequisites: 'N/A',
    minSlots: 1,
    maxSlots: 1,
    isSpecial: true,
    effects:
        'While wielding this Weapon, increase your Damage Reduction by 2(bT) and '
        'increase your Dice Score in any Clash initiated by an Opponent by 1(T).',
    automation: WeaponQualityAutomation(damageReductionPerBaseTier: 2),
  ),
];

/// Looks up a Weapon Quality by exact [name], or `null` if unknown.
WeaponQualityDef? weaponQualityByName(String name) {
  for (final q in kDbuWeaponQualities) {
    if (q.name == name) return q;
  }
  return null;
}

/// The Qualities available to a given Weapon [type] (for the picker).
List<WeaponQualityDef> weaponQualitiesFor(WeaponType type) =>
    kDbuWeaponQualities.where((q) => q.types.contains(type)).toList();
