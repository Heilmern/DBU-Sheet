/// signature_profiles.dart
/// ---------------------------------------------------------------------------
/// Static rules data for FOUNDATIONS & PROFILES — the base attack templates a
/// Signature Technique is built on (Signatures tab). Single source of truth for
/// the site's "Foundations & Profiles" article plus the Super Profiles used by
/// Dramatic Finishers.
///
///   • [SigFoundation]          — Physical / Energy / Magic, plus `multi` for
///                                Multi-Foundation Profiles (the player picks a
///                                concrete Foundation when using them).
///   • [SigProfileDef]          — one Profile: its Foundation, Damage Category,
///                                Ki-Point Cost (`x(T)`) and verbatim effect.
///   • [kDbuSignatureProfiles]  — the 27 standard Profiles (4 Multi-Foundation,
///                                6 Physical, 6 Energy, 11 Magic).
///   • [kDbuSuperProfiles]      — the 12 Super Profiles (Dramatic Finisher only;
///                                free additions with their own Prerequisite,
///                                often with non-numeric KP costs).
///
/// KP COST. A Profile's KP Cost is `kpCostPerTier(T)` (e.g. Simple 0, Combination
/// 3(T)). The Signature-Technique KP formula (see `CharacterCalculator`) starts
/// from this and adds `⌈TP/5⌉(T)`. Super Profiles are reference-only here (their
/// KP is added narratively and several are "Varies"/"N/A"), so their
/// [SigProfileDef.kpCostPerTier] may be null and [kpCostText] carries the
/// verbatim cost.
///
/// PROVENANCE: transcribed verbatim from the offline ZIM archive's
/// `/foundations-profiles/` and `/super-profiles/` articles (dbu-rpg.com,
/// 2026-07-03 backup), cross-checked against the live site.
/// ---------------------------------------------------------------------------
library;

import 'dbu_rules.dart' show DamageCategory;

/// The three Foundations, plus `multi` for Multi-Foundation Profiles (which
/// belong to no single Foundation — the player chooses one when using them).
enum SigFoundation {
  physical('Physical'),
  energy('Energy'),
  magic('Magic'),
  multi('Multi-Foundation');

  const SigFoundation(this.displayName);
  final String displayName;

  /// The concrete Foundations a player may actually pick for a Signature
  /// Technique (Multi-Foundation resolves to one of these at use time).
  static List<SigFoundation> get concrete =>
      const [SigFoundation.physical, SigFoundation.energy, SigFoundation.magic];
}

/// One Profile (standard or Super).
class SigProfileDef {
  const SigProfileDef({
    required this.name,
    required this.foundation,
    required this.effect,
    this.damageCategory,
    this.kpCostPerTier,
    this.kpCostText = '',
    this.isSuper = false,
    this.prerequisite = '',
  });

  final String name;

  /// The Profile's Foundation (`multi` for Multi-Foundation Profiles). Super
  /// Profiles carry `multi` too — they apply on top of whatever the base
  /// Profile's Foundation is.
  final SigFoundation foundation;

  /// The verbatim Effect text.
  final String effect;

  /// The Profile's base Damage Category (null for Super Profiles, which don't
  /// list one — they modify the base attack).
  final DamageCategory? damageCategory;

  /// The `x` in the Profile's `x(T)` KP Cost, used by the KP calculator. Null
  /// when the cost is non-numeric (some Super Profiles: "Varies"/"N/A").
  final int? kpCostPerTier;

  /// The KP Cost exactly as the site writes it (for display) — derived
  /// `"$kpCostPerTier(T)"` for standard Profiles, verbatim for the odd ones.
  final String kpCostText;

  /// Super Profiles are applied only via a Dramatic Finisher (free additions).
  final bool isSuper;

  /// Super Profiles list a Prerequisite (not a KP-costed Requirement). '' for
  /// standard Profiles.
  final String prerequisite;

  /// A short "3(T)" / "0" label for the KP Cost.
  String get kpLabel => kpCostText.isNotEmpty
      ? kpCostText
      : (kpCostPerTier == null
          ? '—'
          : (kpCostPerTier == 0 ? '0' : '$kpCostPerTier(T)'));
}

/// The 27 standard Signature-Technique Profiles. Effects verbatim.
const List<SigProfileDef> kDbuSignatureProfiles = [
  // --- Multi-Foundation Profiles -------------------------------------------
  SigProfileDef(
    name: 'Simple',
    foundation: SigFoundation.multi,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 0,
    effect: 'None.',
  ),
  SigProfileDef(
    name: 'Combination',
    foundation: SigFoundation.multi,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 3,
    effect:
        'After you hit an Opponent with this Attacking Maneuver but before you '
        'roll your Wound Roll, roll your Strike Roll for this Attacking Maneuver '
        'against the Dice Score of their Dodge Roll or Strike Roll (if they used '
        'the Parry option of the Defend Maneuver) an additional 3 times. For '
        'every additional time your Strike Roll exceeds their Dice Score, '
        'increase the Wound Roll by an additional 2(T).',
  ),
  SigProfileDef(
    name: 'Launching',
    foundation: SigFoundation.multi,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 3,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver gains '
        'the Knockback Advantage for free (this does not increase the KP Cost, '
        'or the TP Cost if it is a Signature Technique).\n\nDouble any Collision '
        'Damage a Character suffers due to any movement resulting from this '
        "Attacking Maneuver's use of the Knockback Advantage.",
  ),
  SigProfileDef(
    name: 'Mega Flare',
    foundation: SigFoundation.multi,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 4,
    effect: 'This Profile has multiple effects:\n\nThe maximum number of Energy '
        'Charges for this Profile is 10.\n\nFor every Energy Charge applied to '
        'this Attacking Maneuver, increase the Wound Roll by 1(T).\n\nIf the '
        'number of Energy Charges applied to this Attacking Maneuver is 7+, '
        'increase the Damage Category by 1 Category.',
  ),
  // --- Physical Profiles ----------------------------------------------------
  SigProfileDef(
    name: 'Blitz',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 4,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver gains '
        'the Charging Assault Advantage for free (this does not increase the KP '
        'Cost, or the TP Cost if it is a Signature Technique).\n\nIf you move a '
        'number of Squares that exceeds your Normal Speed due to the effects of '
        'Charging Assault, increase the Wound Roll of that Attacking Maneuver by '
        '1/2 of your Agility Modifier.\n\nIf this Attacking Maneuver is a '
        'Signature Technique, reduce the KP Cost by 2(T).',
  ),
  SigProfileDef(
    name: 'Crushing',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.lethal,
    kpCostPerTier: 6,
    effect: 'Only apply half of your Haste to the Strike Roll for this Attacking '
        'Maneuver.',
  ),
  SigProfileDef(
    name: 'Pinpoint',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 4,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver '
        "ignores an amount of the target's Soak Value equal to your Insight "
        'Modifier.\n\nIf you score a Critical Result on the Strike Roll for this '
        'Attacking Maneuver, double your Insight Modifier for the duration of '
        'this Attacking Maneuver.',
  ),
  SigProfileDef(
    name: 'Powered',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nApply your Damage Attribute '
        'an additional time for this Attacking Maneuver.\n\nThis Attacking '
        'Maneuver gains an Energy Charge.',
  ),
  SigProfileDef(
    name: 'Soaring',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 5,
    effect: 'This Attacking Maneuver has a Standard Line AoE.',
  ),
  SigProfileDef(
    name: 'Sweeping',
    foundation: SigFoundation.physical,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 4,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver has a '
        'Minor Sphere AoE (centered on you).\n\nAllies in this Attacking '
        "Maneuver's AoE are not targeted by this Attacking Maneuver.\n\nIf you "
        'deal Damage with this Attacking Maneuver, double the amount of '
        'Diminishing Defense stacks a target would receive from this Attacking '
        'Maneuver.',
  ),
  // --- Energy Profiles ------------------------------------------------------
  SigProfileDef(
    name: 'Beam',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Attacking Maneuver gains an Energy Charge that does not count '
        'towards your maximum number of Energy Charges.',
  ),
  SigProfileDef(
    name: 'Blast',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 5,
    effect: 'This Attacking Maneuver has a Cone AoE.',
  ),
  SigProfileDef(
    name: 'Clearing',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 6,
    effect: 'This Profile has multiple effects:\n\nTarget a Square that is not '
        'at Long Range. This Attacking Maneuver has a Sphere AoE centered on '
        'your chosen Square.\n\nThe minimum Natural Result for the Strike Roll '
        'for this Attacking Maneuver is 5 (if your Natural Result is less than '
        '5, it becomes 5). This is applied after rolling and applying any '
        'increases to your Natural Result.',
  ),
  SigProfileDef(
    name: 'Concentrated',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.lethal,
    kpCostPerTier: 10,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver has a '
        "Line AoE.\n\nIgnore 1/2 of your target's Damage Reduction.\n\nThe AoE "
        'for this Attacking Maneuver cannot have a Magnitude larger than '
        'Standard, nor can it have an AoE applied to it other than the Line AoE.',
  ),
  SigProfileDef(
    name: 'Cutting',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 6,
    effect: 'This Profile has multiple effects:\n\nOn the Strike Roll for this '
        'Attacking Maneuver, if you do not score a Critical Result, then you '
        'score a Botch Result regardless of the Natural Result.\n\nOn a Critical '
        'Result for the Strike Roll of this Attacking Maneuver, increase the '
        'Damage Category by 1 Category.\n\nOn the Wound Roll for this Attacking '
        'Maneuver, the Critical Target is 5 (ignoring the usual limit).',
  ),
  SigProfileDef(
    name: 'Wave',
    foundation: SigFoundation.energy,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 6,
    effect: 'Target a Square that is not at Long Range. This Attacking Maneuver '
        'has a Line AoE centered on your chosen Square, pointing in any cardinal '
        'direction of your choice.',
  ),
  // --- Magic Profiles -------------------------------------------------------
  SigProfileDef(
    name: 'Elemental (Dark)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 2,
    effect: 'This Profile has multiple effects:\n\nWhen making a Ki Wager for '
        'this Attacking Maneuver, you may spend your Life Points instead of your '
        'Ki Points (reduce your Capacity as if you spent Ki Points as '
        'usual).\n\nAny Squares occupied by Character(s) who take Damage from '
        'this Attacking Maneuver have their Light Level reduced by 1 Level (see '
        '— Light Levels) until the start of your next turn. If this Attacking '
        'Maneuver has an AoE, then all Squares within the AoE have their Light '
        'Level reduced by 1 Level instead until the start of your next turn '
        'instead.\n\nIf this Attacking Maneuver has the Elemental (Light) '
        'Profile applied to it, increase the Wound Rolls by 2(T).',
  ),
  SigProfileDef(
    name: 'Elemental (Earth)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 4,
    effect: 'This Attacking Maneuver gains the effects of the Bludgeoning Weapon '
        'Category as if this Attacking Maneuver was made with a Weapon, even if '
        'it was Unarmed. Apply the effects of the Staggering Quality as if this '
        'Attacking Maneuver was made with a Weapon, even if it was Unarmed.',
  ),
  SigProfileDef(
    name: 'Elemental (Fire)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nIf you knock an Opponent '
        'through a Health Threshold, they gain a stack of the Broken Combat '
        'Condition until the end of your next turn.\n\nAny Squares occupied by '
        'Character(s) who take Damage from this Attacking Maneuver become Aflame '
        '(see - Environmental Qualities, Battle Environments) until the start of '
        'your next turn. If this Attacking Maneuver has an AoE, then all Squares '
        'within the AoE become Aflame until the start of your next turn instead.',
  ),
  SigProfileDef(
    name: 'Elemental (Ice)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nIf you knock an Opponent '
        'through a Health Threshold, they gain a stack of the Slowed Combat '
        'Condition until the end of your next turn.\n\nAny Squares occupied by '
        'Character(s) who take Damage from this Attacking Maneuver become Frozen '
        '(see - Environmental Qualities, Battle Environments) until the start of '
        'your next turn. If this Attacking Maneuver has an AoE, then all Squares '
        'within the AoE become Frozen until the start of your next turn instead.',
  ),
  SigProfileDef(
    name: 'Elemental (Light)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 2,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver gains '
        'the Full Wager Advantage for free (this does not increase the KP Cost, '
        'or the TP Cost if it is a Signature Technique).\n\nAny Squares occupied '
        'by Character(s) who take Damage from this Attacking Maneuver have their '
        'Light Level increased by 1 Level (see — Light Levels) until the start '
        'of your next turn. If this Attacking Maneuver has an AoE, then all '
        'Squares within the AoE have their Light Level increased by 1 Level '
        'instead until the start of your next turn instead.\n\nIf this Attacking '
        'Maneuver has the Elemental (Dark) Profile applied to it, increase the '
        'Strike Roll by 1(T).',
  ),
  SigProfileDef(
    name: 'Elemental (Lightning)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nIf you knock an Opponent '
        'through a Health Threshold, they gain the Impediment Combat Condition '
        'until the end of your next turn.\n\nAny Squares occupied by '
        'Character(s) who take Damage from this Attacking Maneuver become '
        'Electrified (see - Environmental Qualities, Battle Environments) until '
        'the start of your next turn. If this Attacking Maneuver has an AoE, '
        'then all Squares within the AoE become Electrified until the start of '
        'your next turn instead.',
  ),
  SigProfileDef(
    name: 'Elemental (Metal)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.lethal,
    kpCostPerTier: 8,
    effect: 'Any Squares occupied by Character(s) who take Damage from this '
        'Attacking Maneuver become Metallic (see - Environmental Qualities, '
        'Battle Environments). If this Attacking Maneuver has an AoE, then all '
        'Squares and Features within the AoE become Metallic and gain the '
        'Dangerous Environment Quality or the Sharp Feature Quality '
        'respectively. Any Squares or Features that become Metallic through this '
        'effect have their Hardness Rank increased to 3 if it was lower.',
  ),
  SigProfileDef(
    name: 'Elemental (Plantlife)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.standard,
    kpCostPerTier: 3,
    effect: 'This Profile has multiple effects:\n\nThis Attacking Maneuver gains '
        'the Staggering Attack Advantage for free (this does not increase the KP '
        'Cost, or the TP Cost if it is a Signature Technique).\n\nAfter using '
        'this Attacking Maneuver (regardless of if you hit your target(s) or '
        'deal damage), you may create a Feature occupying an unoccupied Square '
        'of your choice adjacent to the target(s) of this Attacking Maneuver. '
        'This Feature has a Hardness Rank of 1 and the Splintering Feature '
        'Quality. If this Attacking Maneuver possessed an AoE, you may instead '
        'fill all of the unoccupied Squares within that AoE with Features that '
        'possess a Hardness Rank of 1 and the Splintering Feature Quality.',
  ),
  SigProfileDef(
    name: 'Elemental (Poison)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nIf you knock an Opponent '
        'through a Health Threshold, they gain the Poisoned Combat Condition '
        'until the end of your next turn.\n\nAny Squares occupied by '
        'Character(s) who take Damage from this Attacking Maneuver become '
        'Poisoned (see - Environmental Qualities, Battle Environments) until the '
        'start of your next turn. If this Attacking Maneuver has an AoE, then '
        'all Squares within the AoE become Poisoned until the start of your next '
        'turn instead.',
  ),
  SigProfileDef(
    name: 'Elemental (Water)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 8,
    effect: 'This Profile has multiple effects:\n\nIf you knock an Opponent '
        'through a Health Threshold, they gain the Prone Combat Condition.\n\n'
        'Any Squares occupied by Character(s) who take Damage from this '
        'Attacking Maneuver become the Bog Environment (see - Battle '
        'Environments) until the start of your next turn. If this Attacking '
        'Maneuver has an AoE, then all Squares within the AoE become the Bog '
        'Environment until the start of your next turn instead.',
  ),
  SigProfileDef(
    name: 'Elemental (Wind)',
    foundation: SigFoundation.magic,
    damageCategory: DamageCategory.direct,
    kpCostPerTier: 4,
    effect: 'This Attacking Maneuver gains the effects of the Slashing Weapon '
        'Category as if this Attacking Manuever was made with a Weapon, even if '
        'it is Unarmed.',
  ),
];

/// The 12 Super Profiles (Dramatic Finisher only). They list a Prerequisite
/// rather than a KP-costed Requirement, and several have non-numeric KP Costs.
const List<SigProfileDef> kDbuSuperProfiles = [
  SigProfileDef(
    name: 'All Out',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'Your Life Points are below the Injured Health Threshold.',
    effect: 'This Profile has multiple effects:\n\nYou must Ki Wager all of your '
        'Ki Points on this Attacking Maneuver. This Ki Wager ignores your '
        'Capacity, but the amount of Ki Points spent cannot exceed your Max '
        'Capacity.\n\nAfter using this Attacking Maneuver, set your Capacity to '
        '0 and change any successes on Steadfast Checks for the Health '
        'Thresholds that you are below to failures (meaning that you suffer from '
        'the Health Threshold Penalties as if you failed those Steadfast '
        'Checks).',
  ),
  SigProfileDef(
    name: 'Cataclysmic Attack',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 4,
    kpCostText: '4(T)',
    prerequisite: 'This Attacking Maneuver has an AoE.',
    effect: 'The AoE for this Attacking Maneuver covers the entire Battlefield.',
  ),
  SigProfileDef(
    name: 'Combo Attack',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'This Attacking Maneuver does not possess an AoE and you '
        'possess another Signature Technique that does not possess an AoE.',
    effect: 'Select a different Super Signature Technique that you have access '
        'to that does not possess an AoE. After hitting your Opponent with this '
        'Attacking Maneuver, you may use the Signature Technique Maneuver as an '
        'Out-of-Sequence Maneuver (ignoring its frequency limit per Combat '
        'Round) to use the Signature Technique you selected when first applying '
        'this Super Profile to this Signature Technique. Increase the Strike '
        'Roll for this Attacking Maneuver by 2(T).',
  ),
  SigProfileDef(
    name: 'Complete Annihilation',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'This Attacking Maneuver possesses 3+ Energy Charges.',
    effect: 'This Profile has multiple effects:\n\nApply your Damage Attribute '
        'an additional time.\n\nIf a target of this Attacking Maneuver is in the '
        'Undying State, increase the amount of Damage they receive by 1/2.\n\nIf '
        'an Opponent is Defeated by this Attacking Maneuver, they cannot '
        'activate any effects with the Triggered/Defeated Keyword.',
  ),
  SigProfileDef(
    name: 'Genki',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostText: 'N/A',
    prerequisite: 'You possess the Energy Gathering Unique Ability.',
    effect: 'When making this Attacking Maneuver, lose all stacks of Lifeforce. '
        'For each stack of Lifeforce lost through this effect, increase your '
        'Wound Roll by 4(bT).\n\nWhile you have declared an Attacking Maneuver '
        'with this Super Profile for the effects of Energy Charge, if an Ally '
        'would give you Ki Points through the Empower Maneuver, instead of '
        'gaining those Ki points, you gain an additional Ki Wager that does not '
        'count towards your Capacity equal to 1/2 of those Ki Points.',
  ),
  SigProfileDef(
    name: 'Giga Flare',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostText: '2(T) per Action spent through its effects',
    prerequisite: 'This Attacking Maneuver possesses the Mega Flare Profile.',
    effect: 'Spend up to 2 Actions. For each Action spent, this Attacking '
        'Maneuver gains 2 Energy Charges.',
  ),
  SigProfileDef(
    name: 'Karmic',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'Z-Soul Alignment is not Neutral',
    effect: 'Increase the Damage Category by 1 Category against Characters who '
        "have an opposing Z-Soul. If that Opponent's Z-Soul Alignment is "
        "'Pure', apply this bonus twice.",
  ),
  SigProfileDef(
    name: 'Multi-Profile',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostText: 'Varies',
    prerequisite: 'N/A.',
    effect: 'Select a different Profile you have access to when applying this '
        'Super Profile. Apply that Profile to this Attacking Maneuver, but do '
        'not apply its Ki Point Cost. That Attacking Maneuver is also considered '
        'to be of that Profile. The Ki Point Cost of this Super Profile varies '
        'depending on the Ki Point Cost of the selected Profile:\n\n=< 4(T). The '
        'Ki point Cost of Multi-Profile is 1(T).\n\n5(T) ~ 7(T). The Ki point '
        'Cost of Multi-Profile is 2(T).\n\n>= 8(T). The Ki point Cost of '
        'Multi-Profile is 3(T).',
  ),
  SigProfileDef(
    name: 'Super Beam',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'This Attacking Maneuver possesses the Beam Profile.',
    effect: 'This Super Profile has multiple effects:\n\nThis Attacking Maneuver '
        'gains a Line AoE.\n\nIncrease the Line AoE by 1 Magnitude for every 2 '
        'Energy Charges applied to this Attacking Maneuver.\n\nIncrease the Dice '
        'Category of the Extra Dice gained from your Energy Charges by 1 Dice '
        'Category.',
  ),
  SigProfileDef(
    name: 'Super Combination',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'This Attacking Maneuver possesses the Combination Profile.',
    effect: 'You may spend any number of additional Actions when using this '
        'Signature Technique. For each Action spent:\n\nApply a rank of the '
        'Alotta Lotta Attacks and Peppering Blows Advantages (this may allow you '
        'to exceed the maximum).\n\nApply an Energy Charge to this Attacking '
        'Maneuver.',
  ),
  SigProfileDef(
    name: 'Super Launch',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 2,
    kpCostText: '2(T)',
    prerequisite: 'This Attacking Maneuver possesses the Launching Profile.',
    effect: 'This Super Profile has multiple effects:\n\nYou automatically '
        'succeed the Might Clash for the effects of the Knockback '
        'Advantage.\n\nUpon moving a Character through the effects of the '
        'Knockback Advantage, reduce their Life Points by the amount of Squares '
        'they would move through its effects (even if they do not move that '
        'number of Squares).',
  ),
  SigProfileDef(
    name: 'Weather Maximizer',
    foundation: SigFoundation.multi,
    isSuper: true,
    kpCostPerTier: 4,
    kpCostText: '4(T)',
    prerequisite:
        'This Attacking Maneuver possesses the Weather Calling Advantage.',
    effect: 'The Battle Weather created by the Weather Calling Advantage is '
        'Cataclysmic.',
  ),
];

/// Looks up a standard or Super Profile by exact [name], or `null` if unknown.
SigProfileDef? signatureProfileByName(String name) {
  for (final p in kDbuSignatureProfiles) {
    if (p.name == name) return p;
  }
  for (final p in kDbuSuperProfiles) {
    if (p.name == name) return p;
  }
  return null;
}

/// The standard Profiles available for a chosen [foundation]: Profiles of that
/// Foundation plus all Multi-Foundation Profiles.
List<SigProfileDef> profilesForFoundation(SigFoundation foundation) =>
    kDbuSignatureProfiles
        .where((p) =>
            p.foundation == foundation || p.foundation == SigFoundation.multi)
        .toList();
