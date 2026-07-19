/// accessories.dart
/// ---------------------------------------------------------------------------
/// Static rules data for the ACCESSORIES sub-system (Inventory page →
/// Accessories). Single source of truth for the site's Accessories — a subset
/// of Basic Items that are "worn equipment that grant some additional effect …
/// while equipped."
///
/// Unlike Apparel/Weapons (which the player CRAFTS by choosing a Grade / Type /
/// Size / Category / Qualities), Accessories are a FIXED CATALOGUE of named
/// items ([kDbuAccessories]) — the player simply owns one and marks it equipped.
/// Each carries a Craft DC (a Difficulty Category, or '' for Special/ARC-granted
/// ones) and its verbatim [AccessoryDef.effects].
///
/// GLOBAL RULES (verbatim): "You can only equip up to 2 Accessories at once. You
/// can spend 1 Action to equip or remove an Accessory. You cannot wear two of
/// the same Accessory, nor benefit from the same Accessory's effects twice."
///
/// AUTOMATION. Like Apparel/Weapons, only the unconditional, numerically
/// unambiguous "while equipped" effects are auto-applied (via
/// [AccessoryAutomation]); the many situational/narrative Accessories (granted
/// Maneuvers, Skill-Check bonuses, Fusions, conditional or element-specific
/// effects, etc.) are shown as reference text (`automation == null`).
///
/// PROVENANCE: transcribed from the offline ZIM archive's
/// `/basic-items-accessories/` article (dbu-rpg.com, 2026-07-03 backup) — see
/// the `zim-archive-lookup` memory note.
/// ---------------------------------------------------------------------------
library;

import 'dbu_rules.dart' show AffectedStat;

/// "You can only equip up to 2 Accessories at once."
const int kMaxEquippedAccessories = 2;

/// How the magnitude of an [AccessoryStatEffect] scales:
///   • [perBaseTier] — `coefficient` × Base Tier of Power.
///   • [perTier]     — `coefficient` × Tier of Power.
enum AccessoryEffectBasis { perBaseTier, perTier }

/// A single automated stat change granted by an Accessory while it is equipped.
class AccessoryStatEffect {
  const AccessoryStatEffect({
    required this.stats,
    required this.coefficient,
    this.basis = AccessoryEffectBasis.perBaseTier,
  });

  final List<AffectedStat> stats;
  final int coefficient;
  final AccessoryEffectBasis basis;
}

/// The auto-applicable part of an Accessory's effect. Everything here is applied
/// unconditionally while the Accessory is equipped; conditional/situational
/// parts of the same Accessory stay in the free-text [AccessoryDef.effects].
class AccessoryAutomation {
  const AccessoryAutomation({
    this.statEffects = const [],
    this.damageReductionPerBaseTier = 0,
  });

  /// Direct stat effects (Bunny Ears Speed, Sash Impulsive Save, …).
  final List<AccessoryStatEffect> statEffects;

  /// An unconditional Damage-Reduction bonus while equipped (Armored Gloves,
  /// Helmet → 1(bT)). Feeds the Damage Calculator.
  final int damageReductionPerBaseTier;
}

/// One entry in the Accessories catalogue.
class AccessoryDef {
  const AccessoryDef({
    required this.name,
    required this.craftDc,
    required this.description,
    required this.effects,
    this.isTech = false,
    this.isSpecial = false,
    this.automation,
  });

  final String name;

  /// The Craft DC Difficulty Category (e.g. "Apprentice", "Master", or the
  /// Scouter's "Variable (Qualified ~ Grandmaster)"). '' for Special
  /// Accessories, which "cannot be obtained by Crafting."
  final String craftDc;

  /// The Accessory's short flavour sentence (the line before "–Effects:").
  final String description;

  /// The verbatim Effects text.
  final String effects;

  /// Whether the Accessory carries the [Tech] tag (Technology — hard to
  /// replicate through magical means).
  final bool isTech;

  /// Special Accessories are Special Basic Items — ARC-granted, no Craft DC.
  final bool isSpecial;

  /// The auto-applicable part of the effect, or `null` when reference-only.
  final AccessoryAutomation? automation;

  bool get isAutomated => automation != null;
}

/// The full Accessories catalogue (standard first, then Special). Effects text
/// transcribed verbatim from the site.
const List<AccessoryDef> kDbuAccessories = [
  // --- Standard Accessories -------------------------------------------------
  AccessoryDef(
    name: 'Armored Gloves',
    craftDc: 'Expert',
    description: 'These gloves contain metal plates that provide wrist and '
        'forearm protection.',
    effects: 'Increase your Damage Reduction by 1(bT).',
    automation: AccessoryAutomation(damageReductionPerBaseTier: 1),
  ),
  AccessoryDef(
    name: 'Battle Jacket Belt',
    craftDc: 'Master',
    isTech: true,
    description: 'A mechanical belt not unlike a Capsule, this item unfolds into '
        'or releases an armored suit or mecha with you as the Pilot!',
    effects:
        'When you first gain/craft this Accessory, select a Battle Jacket you '
        'possess. That Battle Jacket is Stored within this Accessory.\n\n'
        "If there's enough space for the Square Occupancy of the Stored Battle "
        'Jacket, you may spend 1 Action while wearing the Belt to make it appear '
        'instantly on your position, or return the Stored Battle Jacket in your '
        'Belt, if you are piloting the Stored Battle Jacket or on an Adjacent '
        'Square. If you make the Battle Jacket appear in your position, you '
        'automatically enter this Battle Jacket through this effect.',
  ),
  AccessoryDef(
    name: 'Bunny Ears',
    craftDc: 'Apprentice',
    description: 'This bunny-eared headband makes you look cool, and you feel '
        'faster somehow.',
    effects: "Increase the wearer's Normal Speed by 1(bT) and their Boosted "
        'Speed by 2(bT).',
    automation: AccessoryAutomation(
      statEffects: [
        AccessoryStatEffect(stats: [AffectedStat.speedNormal], coefficient: 1),
        AccessoryStatEffect(stats: [AffectedStat.speedBoosted], coefficient: 2),
      ],
    ),
  ),
  AccessoryDef(
    name: 'Champion Belt',
    craftDc: 'Master',
    description: 'A belt of leather and gold indicating a win in a tournament of '
        'some kind, marking your martial prowess.',
    effects: 'Increase your Morale Saving Throw by 1(bT) and increase all Skill '
        'Checks that use your Personality Score by 2.',
    // Only the unconditional Morale Save is automated; the Personality-Skill
    // bonus is a Skill-Check dice bonus this app doesn't compute.
    automation: AccessoryAutomation(
      statEffects: [
        AccessoryStatEffect(stats: [AffectedStat.moraleSave], coefficient: 1),
      ],
    ),
  ),
  AccessoryDef(
    name: 'Eyeglasses',
    craftDc: 'Apprentice',
    description: 'A piece of eye-wear designed to correct poor vision.',
    effects:
        'When you gain or create this Accessory, you must declare an Intended '
        "Character. If you're the Intended Character, increase the Natural "
        'Result of any Perception Skill Check by 1 while wearing this '
        "Accessory.\n\nIf you're not the Intended Character, reduce the Natural "
        'Result on any Perception Skill check made relying on sight by 1 while '
        'wearing this Accessory.',
  ),
  AccessoryDef(
    name: 'Eyepatch',
    craftDc: 'Apprentice',
    description: 'Created with the intention of hiding a damaged eye, these are '
        'often worn by fierce warriors or cutthroats; either way, they indicate '
        'that the wearer is quite dangerous.',
    effects:
        'Decrease the Natural Result of any Perception checks made that rely on '
        'sight by 1, but in return increase the Natural Result of any '
        'Intimidation checks by 1.',
  ),
  AccessoryDef(
    name: 'Fashionable Accessories',
    craftDc: 'Qualified',
    description: 'This collection of pins, jewelry, sashes, and other assorted '
        'wearable items is the perfect accent to your everyday wear, making you '
        'feel like a million zeni.',
    effects: 'Increase your Morale Saving Throws by 1(bT) while wearing Standard '
        'Clothing in addition to this Accessory.',
    // Conditional on wearing Standard Clothing — left to the player.
  ),
  AccessoryDef(
    name: 'Flowing Fashion',
    craftDc: 'Expert',
    description: 'You wear a scarf or cape, making you look like a true hero!',
    effects: 'Increase the Dice Score for any Skill Checks with your Performance '
        'Skill by 2. Increase your Combat Rolls by 1(bT) while Hyped.',
  ),
  AccessoryDef(
    name: 'Galactic Receiver',
    craftDc: 'Qualified',
    isTech: true,
    description: 'A specialized Communicator worn on the ear, this device serves '
        'as an aid to hearing as well.',
    effects:
        'When you roll a Perception Skill Check related to your hearing, '
        'increase the Natural Result by 2. This Accessory also serves as a '
        'Communicator.',
  ),
  AccessoryDef(
    name: 'Helmet',
    craftDc: 'Expert',
    description: 'Protective headgear that reduces the risk of injury.',
    effects: 'Increase your Damage Reduction by 1(bT). Additionally, increase '
        'your Bluff Skill Checks by 2.',
    automation: AccessoryAutomation(damageReductionPerBaseTier: 1),
  ),
  AccessoryDef(
    name: 'Hologram Projector',
    craftDc: 'Expert',
    isTech: true,
    description:
        'Large, comic book letters appear when you strike your opponent!',
    effects: 'When using the Signature Technique Maneuver, you may use your '
        'Personality Modifier for the Damage Attribute of that Attacking '
        'Maneuver.',
  ),
  AccessoryDef(
    name: 'Jetpack',
    craftDc: 'Qualified',
    isTech: true,
    description: 'This is a wearable device that allows flight to characters who '
        'cannot otherwise fly.',
    effects:
        "A Jetpack has a Ki Point Pool of 30(bT), based on the creator's Tier "
        'of Power at the time of creation. When you would spend Ki Points '
        'through the Movement Maneuver, remove them from the Jetpack instead. '
        'You gain access to the Soar Maneuver.',
  ),
  AccessoryDef(
    name: 'Ki-Sealing Handcuff',
    craftDc: 'Grandmaster',
    isTech: true,
    description: 'These handcuffs are designed for super-powered fighters, '
        'allowing them to be restrained even by weaker foes.',
    effects:
        'When this Accessory is created, you must create a Key Basic Item for '
        'this instance of the Accessory. You may spend 3 Actions to place this '
        'Accessory on a Defeated Opponent or a Character with the Oblivious '
        'Combat Condition, even if they are already wearing an Accessory. In the '
        'case of the latter, you must make a Skill Check (Stealth/Thievery vs '
        'Perception) to put the Ki-Sealing Handcuff on them.\n\nWhile wearing '
        'this Accessory, you suffer from a stack of the Fatigued Combat '
        'Condition (that cannot be removed while you’re wearing this '
        'Accessory) and you cannot use any Transformation Maneuvers, Signature '
        'Techniques, Unique Abilities, Ki Wagers, or any Profile aside from '
        'Simple (Physical).\n\nWhile wearing this Accessory, you cannot remove '
        'this Accessory and you cannot target this Accessory with a Called '
        'Shot.\n\nIf you possess the correct Key, you may remove this Accessory '
        'by spending 1 Action.',
  ),
  AccessoryDef(
    name: 'Mask',
    craftDc: 'Qualified',
    description: 'A false face that can be worn over your real face to protect '
        'your identity.',
    effects: 'Increase your Bluff Skill Checks by 2.',
  ),
  AccessoryDef(
    name: 'Metamo-Ring',
    craftDc: 'Grandmaster',
    isTech: true,
    description: 'Possessing the properties of the Potara Earring and '
        'implemented through the Fusion Dance, wearing this ring allows for an '
        'easily accessible, albeit weaker, Fusion.',
    effects:
        'When you use the Metamoran Fusion Dance Unique Ability, if you target '
        'another Character with a Metamo-Ring equipped, you both automatically '
        'succeed at Performance Skill Check for the Metamoran Fusion Dance, but '
        'you use the EX-Fusion Fusion Method instead of Metamorese Fusion.',
  ),
  AccessoryDef(
    name: 'Micro Band',
    craftDc: 'Master',
    isTech: true,
    description: 'A watch that allows you to shrink.',
    effects: 'At the cost of 1 Action, you may reduce your Size Category to the '
        'Tiny or Nano Size Category. You can spend 1 Action to return to your '
        'base Size Category.',
  ),
  AccessoryDef(
    name: 'Oven Mitt',
    craftDc: 'Novice',
    description: "A padded mitten designed to protect one's hand from being "
        'burned.',
    effects: "You can't use the Energy Focus Aura while wearing this Accessory. "
        'Increase your Damage Reduction against Attacking Maneuvers of the '
        'Elemental (Fire) Profile by 1(bT).',
    // Damage Reduction is element-specific (Fire only) — left to the player.
  ),
  AccessoryDef(
    name: 'Sash',
    craftDc: 'Qualified',
    description: 'A flowing piece of fabric, typically worn hanging free from '
        'the waist or around one shoulder.',
    effects: 'Increase your Impulsive Saving Throws by 1(bT).',
    automation: AccessoryAutomation(
      statEffects: [
        AccessoryStatEffect(stats: [AffectedStat.impulsiveSave], coefficient: 1),
      ],
    ),
  ),
  AccessoryDef(
    name: 'Scouter',
    craftDc: 'Variable (Qualified ~ Grandmaster)',
    isTech: true,
    description: 'A more advanced, wearable version of the Scout Scope, this one '
        'functions as a Communicator as well.',
    effects:
        'During a Combat Encounter, you can spend 1 Action to attempt to scan '
        'the strength of another Character. Characters may attempt a Concealment '
        'Skill Check equal to the Craft DC of this Scouter to try and avoid '
        'being scanned. If they succeed, nothing happens and they automatically '
        'succeed on any further Concealment Skill Checks to avoid being spotted '
        'by a Scouter for the remainder of the Combat Encounter. If their '
        'current Tier of Power is the same as their base Tier of Power, you also '
        'learn of their Power Level.\n\nIf the Craft DC of a Scouter is Expert '
        'or lower, it can be destroyed when a Character of Tier of Power 2+ '
        '(Qualified) or 3+ (Expert) uses the Power Up Maneuver within 15 Squares '
        'of you, or when within several hundred miles while Adventuring.\n\n'
        'While you have this Accessory equipped, you have access to the Scan '
        'Adventuring Maneuver. The Scouter also functions as a Communicator.',
  ),
  AccessoryDef(
    name: 'Sheath/Holster',
    craftDc: 'Qualified',
    description: 'You can store a Weapon in this Accessory for ease of travel.',
    effects:
        'When you unsheathe your Weapon for the first time in a Combat '
        'Encounter, increase your next Strike Roll made for an Armed Attack with '
        'that Weapon during this Combat Round by 2(T).\n\nAt the end of each '
        'Combat Encounter, if you sheathe your Weapon, that Weapon regains 1/4 '
        'of its Life Points. This effect does not apply if the Weapon is '
        'destroyed.',
  ),
  AccessoryDef(
    name: 'Shock Collar',
    craftDc: 'Expert',
    isTech: true,
    description: 'This collar is designed to emit an electric shock when the '
        'corresponding remote is triggered.',
    effects:
        'This Accessory is connected to a Remote Control. If the Remote Control '
        'triggers the effects of a Shock Collar, reduce your Life Points by 1/5 '
        'of your Maximum Life Points. If you are knocked through a Health '
        'Threshold by this effect, you are knocked Prone.',
  ),
  AccessoryDef(
    name: 'Space Helmet',
    craftDc: 'Expert',
    isTech: true,
    description: 'An airtight helmet that offers you breathable air.',
    effects:
        'While you are wearing this Accessory, ignore Unbreathable Environments.',
  ),
  AccessoryDef(
    name: 'Sunglasses',
    craftDc: 'Apprentice',
    description: "A pair of glasses designed to darken one's vision to protect "
        'against bright light.',
    effects: 'Ignore the effects of the Solar Flare Unique Ability and treat the '
        'Light Level as if it was 1 lower for you.',
  ),
  AccessoryDef(
    name: 'Suppression Crown',
    craftDc: 'Master',
    isTech: true,
    description: 'Designed to prevent a rampaging fighter from going out of '
        'control, this cruel device weakens their combat abilities.',
    effects:
        "Reduces the power of the wearer's Transformations. Reduce the Attribute "
        'Modifier Bonuses (AG/FO/MA) of all Forms by 1(T). If the wearer would '
        'attempt to transform into a Legendary Form, increase the Stress Test '
        'Requirement by 4.\n\nIf they still make the Stress Test and '
        'successfully transform into a Legendary Form, destroy this Accessory.',
  ),
  AccessoryDef(
    name: 'Time Breaker Mask',
    craftDc: 'Grandmaster',
    description: 'A unique kind of mask used by the Time Breakers, this mask '
        'asserts control over an individual, allowing you to make them do as you '
        'please.',
    effects:
        'A Time Breaker Mask can only be created through the Magical '
        'Materialization Unique Ability. Increase your Bluff Skill Check by 2 '
        'and gain the Masked Warrior Awakening as a Level 2 Temporary Awakening. '
        'You cannot lose that Awakening while this Accessory is equipped, but you '
        'lose it the instant this Accessory becomes unequipped.',
  ),
  AccessoryDef(
    name: 'Transformation Device',
    craftDc: 'Master',
    isTech: true,
    description: 'A watch or other small, easily hidden device that allows you '
        'to quickly change your outfit and take on a new identity!',
    effects: "Gain access to the Hero Enhancement Power while you're wearing "
        'this Accessory.',
  ),
  AccessoryDef(
    name: 'Trucker Hat',
    craftDc: 'Qualified',
    description: 'A typical ball cap worn by those who drive for a living, these '
        'are hardly fashionable, but they do serve to keep the light of your '
        'eyes.',
    effects: 'Increase the Dice Score for any Skill Checks with your Pilot Skill '
        'by 2. Increase the Wound Rolls of any Blitz Attacking Maneuver made as '
        'the Pilot of a Vehicle by 2(bT).',
  ),
  // --- Special Accessories --------------------------------------------------
  AccessoryDef(
    name: 'Bloodstained Accessory',
    craftDc: '',
    isSpecial: true,
    description: 'A piece of cloth or keepsake stained with the blood of a '
        "fallen comrade used to remind you what you're fighting for.",
    effects: 'This Accessory has multiple effects that apply while it is '
        'equipped:\n\nIncrease the Dice Score of your Steadfast Checks by 1.\n\n'
        'Increase your Morale Saves by 1(bT).\n\nWhile in the Raging State, '
        'increase your Wound Rolls by 1(T).\n\nIf you enter the Raging State, '
        'you may enter the Determined State until the end of your turn. This '
        'effect can only be used once for this Accessory.\n\nWhen an Ally dies, '
        'you may take an Accessory they possess or tear off a piece of their '
        'Apparel by spending 2 Actions beside them. If you do, that Accessory or '
        'piece of Apparel becomes a Bloodstained Accessory.',
    // Only the unconditional Morale Save is automated; the Steadfast dice and
    // Raging-State effects are situational.
    automation: AccessoryAutomation(
      statEffects: [
        AccessoryStatEffect(stats: [AffectedStat.moraleSave], coefficient: 1),
      ],
    ),
  ),
  AccessoryDef(
    name: 'Hero Switch',
    craftDc: '',
    isSpecial: true,
    description: 'This wrist-mounted device allows you to turn into your '
        'alternate identity.',
    effects:
        'While this Accessory is equipped, you gain access to the Future Hero '
        'Enhancement (even if you do not have access to the Hero '
        'Enhancement).\n\nAdditionally, if your Race is Earthling, you gain '
        'access to the Dragon Ball Hero Factor and gain access to its Factor '
        'Trait without having to exchange any of your Racial Traits.',
  ),
  AccessoryDef(
    name: "Hero's Flute",
    craftDc: '',
    isSpecial: true,
    description: 'This musical instrument vibrates with magical power, bestowing '
        'the necessary skills to become a hero upon its bearer.',
    effects: 'While this Accessory is equipped, you gain access to the Heroic '
        'Melodies Awakening as a Temporary Awakening, ignoring its '
        'Prerequisites.',
  ),
  AccessoryDef(
    name: 'Potara Earring',
    craftDc: '',
    isSpecial: true,
    description: 'A divine artifact of the Kaioshin, these earrings allow the '
        'Kaioshin great power via Fusion in times of need, and can be used in '
        'conjunction with other Kaioshin artifacts.',
    effects:
        'Potara Earrings come in a set of two. When two people are wearing each '
        'piece of a Potara Earring set on opposite ears, they use the Potara '
        'Fusion Method as an Out-of-Sequence Maneuver.',
  ),
  AccessoryDef(
    name: 'Soul Potara Earring',
    craftDc: '',
    isSpecial: true,
    description: 'A unique variant of the Potara Earring that allows you to '
        'merge with a willing partner.',
    effects:
        'You gain access to the Absorption Special Maneuver. If you would '
        'unequip this Accessory, you lose any stacks of the Absorption Awakening '
        'and free any Characters who were stored there.',
  ),
  AccessoryDef(
    name: 'Tertian Oculus',
    craftDc: '',
    isSpecial: true,
    description: 'A magical prosthetic third eye that you can embed in your '
        'forehead, granting you great power.',
    effects: 'You gain access to the Demonic Third Eye Legendary Form.',
  ),
];

/// Looks up an Accessory by exact [name], or `null` if unknown.
AccessoryDef? accessoryByName(String name) {
  for (final a in kDbuAccessories) {
    if (a.name == name) return a;
  }
  return null;
}
