/// signature_modifiers.dart
/// ---------------------------------------------------------------------------
/// Static rules data for Signature-Technique ADVANTAGES & DISADVANTAGES — the
/// modifiers a player buys (Advantages, +TP) or takes (Disadvantages, −TP) to
/// shape a Signature Technique (Signatures tab).
///
///   • [SigModifierCategory]    — the 8 Advantage + 7 Disadvantage categories.
///   • [SigModifierDef]         — one modifier: its category, per-rank TP costs
///                                (positive for Advantages, negative for
///                                Disadvantages), Requirement, verbatim Effect,
///                                Ultimate-only flag, and optional automation.
///   • [kDbuSignatureAdvantages] / [kDbuSignatureDisadvantages] — the full
///                                catalogues (~112 entries), Effects verbatim.
///
/// RANKS. Many modifiers can be taken multiple times; [SigModifierDef.
/// tpCostsPerRank] lists the TP cost of EACH rank (a one-element list = a
/// single-rank modifier). Buying rank N costs the sum of the first N entries —
/// see `CharacterCalculator.signatureTpCost`.
///
/// AUTOMATION. Like Apparel/Weapons, only the unconditional per-technique
/// numeric effects are auto-applied (Strike/Wound deltas per rank, and the
/// KP-cost changes of Efficiency/Inefficiency); everything conditional or
/// narrative stays reference text (`automation == null`) and is labelled "not
/// automated" in the UI.
///
/// PROVENANCE: transcribed verbatim from the offline ZIM archive's `/signature/`
/// article (dbu-rpg.com, 2026-07-03 backup), cross-checked against the live site.
/// ---------------------------------------------------------------------------
library;

/// The Advantage and Disadvantage categories (the site groups entries under
/// these headers). Advantage and Disadvantage categories are distinct even when
/// they share a display name (e.g. Movement / Miscellaneous).
enum SigModifierCategory {
  // Advantage categories.
  areaAdv('Area', isDisadvantage: false),
  chargeAdv('Charge', isDisadvantage: false),
  magicAdv('Magic', isDisadvantage: false),
  movementAdv('Movement', isDisadvantage: false),
  powerAdv('Power', isDisadvantage: false),
  surpriseAdv('Surprise', isDisadvantage: false),
  technicalAdv('Technical', isDisadvantage: false),
  miscAdv('Miscellaneous', isDisadvantage: false),
  // Disadvantage categories.
  movementDis('Movement', isDisadvantage: true),
  resourceDis('Resource', isDisadvantage: true),
  restrictionDis('Restriction', isDisadvantage: true),
  setUpDis('Set-Up', isDisadvantage: true),
  targetingDis('Targeting', isDisadvantage: true),
  weaknessDis('Weakness', isDisadvantage: true),
  miscDis('Miscellaneous', isDisadvantage: true);

  const SigModifierCategory(this.displayName, {required this.isDisadvantage});
  final String displayName;
  final bool isDisadvantage;
}

/// Which Combat Roll a [SigStatEffect] targets. `wound` resolves to the
/// Technique's own Wound Roll (Physical/Energy/Magic per its Foundation).
enum SigEffectTarget { strike, wound }

/// Whether a [SigStatEffect] scales with Tier of Power (`perTier`) or Base Tier
/// of Power (`perBaseTier`).
enum SigEffectBasis { perTier, perBaseTier }

/// A per-rank Combat-Roll change from an automated modifier (Accurate,
/// Inaccurate, Power Shot, Low Penetration).
class SigStatEffect {
  const SigStatEffect({
    required this.target,
    required this.coefficientPerRank,
    this.basis = SigEffectBasis.perTier,
  });

  final SigEffectTarget target;

  /// Applied `coefficientPerRank × rank × Tier`. Sign already baked in.
  final int coefficientPerRank;
  final SigEffectBasis basis;
}

/// The auto-applicable part of a modifier's effect.
class SigModifierAutomation {
  const SigModifierAutomation({
    this.statEffects = const [],
    this.kpPerTierPerRank = 0,
  });

  /// Per-technique Strike/Wound deltas (scaled by rank).
  final List<SigStatEffect> statEffects;

  /// Change to the Technique's total KP Cost, `kpPerTierPerRank × rank × Tier`
  /// (Efficiency −4, Inefficiency +4).
  final int kpPerTierPerRank;
}

/// One Advantage or Disadvantage.
class SigModifierDef {
  const SigModifierDef({
    required this.name,
    required this.category,
    required this.description,
    required this.tpCostsPerRank,
    required this.requirement,
    required this.effect,
    this.ultimateOnly = false,
    this.automation,
  });

  final String name;
  final SigModifierCategory category;

  /// The flavour sentence (before "–TP Cost:").
  final String description;

  /// The TP cost of each rank (positive for Advantages, negative for
  /// Disadvantages). Length = max rank; a single-element list = single-rank.
  final List<int> tpCostsPerRank;

  /// The Requirement text ("N/A" when none) — what the Signature Technique needs
  /// to take this modifier (not what's needed to use it). Not auto-checked.
  final String requirement;

  /// The verbatim Effect text.
  final String effect;

  /// True when the modifier can only be taken by an Ultimate Signature Technique
  /// (Requirement includes "Ultimate Signature Technique").
  final bool ultimateOnly;

  /// The auto-applicable part of the effect, or `null` when reference-only.
  final SigModifierAutomation? automation;

  bool get isDisadvantage => category.isDisadvantage;
  int get maxRank => tpCostsPerRank.length;
  bool get isRanked => tpCostsPerRank.length > 1;
  bool get isAutomated => automation != null;

  /// Cumulative TP cost of owning [rank] ranks (sum of the first [rank] entries,
  /// clamped to the available ranks). Negative for Disadvantages.
  int tpCostForRank(int rank) {
    final r = rank.clamp(1, tpCostsPerRank.length);
    var total = 0;
    for (var i = 0; i < r; i++) {
      total += tpCostsPerRank[i];
    }
    return total;
  }

  /// A short "5" / "4~6" / "3/5/7" label for the TP cost across ranks.
  String get tpLabel => tpCostsPerRank.length == 1
      ? '${tpCostsPerRank.first}'
      : tpCostsPerRank.join('/');
}

/// The full Advantages catalogue (8 categories). Effects verbatim.
const List<SigModifierDef> kDbuSignatureAdvantages = [
  // --- Area Advantages ------------------------------------------------------
  SigModifierDef(
    name: 'Controlled Blast',
    category: SigModifierCategory.areaAdv,
    description:
        'You can create blast effects from almost anywhere on the battlefield.',
    tpCostsPerRank: [5],
    requirement: 'Cone AoE.',
    effect:
        "Instead of yourself being the Target Square, this Attacking Maneuver's "
        'Target Square is any Square you select on the Battlefield that is not '
        'at Long Range, pointing in any direction you wish.',
  ),
  SigModifierDef(
    name: 'Hurricane Assault',
    category: SigModifierCategory.areaAdv,
    description: 'The range of your sweeping attack extends beyond your physical '
        'body.',
    tpCostsPerRank: [4],
    requirement: 'Sweeping Profile.',
    effect: "This Attacking Maneuver's Magnitude becomes Standard (before any "
        'other effects apply).',
  ),
  SigModifierDef(
    name: 'Intense Blast',
    category: SigModifierCategory.areaAdv,
    description: 'Your area of effect blasts are deadly enough that they clip '
        'even those that avoid it.',
    tpCostsPerRank: [15],
    requirement: 'This Attacking Maneuver possesses an AoE.',
    effect: 'This Signature Technique is an Absolute Attack (see - Attacking).',
  ),
  SigModifierDef(
    name: 'Pinpoint Precision',
    category: SigModifierCategory.areaAdv,
    description: 'Your uncanny accuracy allows you to hit a single target '
        'precisely where you want, to terrifying results.',
    tpCostsPerRank: [6],
    requirement: 'This Signature Technique possesses an AoE of Standard or Minor '
        'Magnitude, this Attacking Maneuver does not possess the Concentrated '
        'Strike Advantage.',
    effect: 'If this Attacking Maneuver targets only a single Opponent, you can '
        'use the Called Shot Maneuver on this Attacking Maneuver. If you hit an '
        'Opponent with a Called Shot, apply a rank of the Broken Combat '
        'Condition until the start of your next turn.',
  ),
  SigModifierDef(
    name: 'Splitting',
    category: SigModifierCategory.areaAdv,
    description: 'Your attack splits into several projectiles that let it strike '
        'more than one enemy.',
    tpCostsPerRank: [4, 6],
    requirement:
        'Energy or Magic Foundation that does not have an Area of Effect.',
    effect: 'At Attack Declaration, when using this Signature Technique, select '
        'up to 2 Opponents (First Rank) or up to 4 Opponents (Second Rank). '
        'They are the targets for this Attacking Maneuver. For each Opponent you '
        'chose after the first, reduce your Wound Roll by 1(T).',
  ),
  SigModifierDef(
    name: 'Terrain Destruction',
    category: SigModifierCategory.areaAdv,
    description: 'Your area of effect blasts cover a larger area.',
    tpCostsPerRank: [3, 5, 7],
    requirement: 'The Signature Technique possesses an AoE.',
    effect: "Increase the AoE's Magnitude by 1 for each rank of this Advantage.",
  ),
  SigModifierDef(
    name: 'Widespread Assault',
    category: SigModifierCategory.areaAdv,
    description:
        'Your attack has such destructive force that it covers a large area.',
    tpCostsPerRank: [8],
    requirement: 'Attacking Maneuver does not possess an AoE.',
    effect: 'Select an Area of Effect (see — Area of Effect). This Attacking '
        'Maneuver gains the selected AoE at the Standard Magnitude. If you '
        'choose the Sphere AoE, the Target Square for this AoE may be any '
        'Square, rather than just a Square that you occupy.',
  ),
  // --- Charge Advantages ----------------------------------------------------
  SigModifierDef(
    name: 'Concentrated Strike',
    category: SigModifierCategory.chargeAdv,
    description:
        'You channel all of the destructive force of this attack into a single '
        'point.',
    tpCostsPerRank: [8],
    requirement: 'This Attacking Maneuver possesses an AoE, this Attacking '
        'Maneuver does not possess the Pinpoint Precision Advantage.',
    effect: "If you only target a single Character with this Attacking "
        "Maneuver's AoE, apply an Energy Charge to this Attacking Maneuver.",
  ),
  SigModifierDef(
    name: 'Maximum Charge',
    category: SigModifierCategory.chargeAdv,
    description: 'Your Energy Charges are even stronger when used on this '
        'technique.',
    tpCostsPerRank: [6],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'Increase the Dice Category of the Extra Dice gained from any Energy '
        'Charges by 1 Category.',
  ),
  // --- Magic Advantages -----------------------------------------------------
  SigModifierDef(
    name: 'Reinforced Plantlife',
    category: SigModifierCategory.magicAdv,
    description: 'Your conjured plant matter is tougher and thicker.',
    tpCostsPerRank: [3, 4, 5],
    requirement: 'Elemental (Plantlife) Profile.',
    effect: 'Increase the Hardness Rank of the Features created through this '
        "Attacking Maneuver's use of the Elemental (Plantlife) Profile by the "
        'number of ranks in this Advantage.',
  ),
  SigModifierDef(
    name: 'Weather Calling',
    category: SigModifierCategory.magicAdv,
    description: 'Change the Battle Weather through your magic.',
    tpCostsPerRank: [10],
    requirement: 'Elemental (Any except Light/Dark/Metal/Water) Profile.',
    effect: 'When you hit an Opponent with this Signature Technique, apply the '
        'Battle Weather in a Sphere AoE (centered on that Opponent) whose '
        'Connected Profile is your Elemental Profile for this Signature '
        'Technique. The Tier is Natural if this is a Super Signature and '
        'Unnatural if this Attacking Maneuver is an Ultimate Signature.',
  ),
  // --- Movement Advantages --------------------------------------------------
  SigModifierDef(
    name: 'Back Flip',
    category: SigModifierCategory.movementAdv,
    description: 'You can move while attacking at range with this technique.',
    tpCostsPerRank: [2],
    requirement: 'Hit and Run Advantage, Energy Attack, Magic Attack, Soaring '
        'Profile, Physical Attack with the Charging Assault Advantage, the '
        'Attacking Maneuver does not possess an AoE (except the Line AoE).',
    effect: 'Apply the effects of Hit and Run before using the Signature '
        'Technique but after Attack Declaration, instead of the usual timing. If '
        'this Attacking Maneuver has the Charging Assault Advantage, this effect '
        'is applied before Charging Assault and the KP Cost of this Maneuver is '
        'reduced by 1(T).',
  ),
  SigModifierDef(
    name: 'Charging Assault',
    category: SigModifierCategory.movementAdv,
    description: 'Your attack lets you rush forward and turn your momentum into '
        'power.',
    tpCostsPerRank: [10],
    requirement: 'N/A',
    effect: 'At Attack Declaration, you may move up to your Boosted Speed in a '
        'straight line towards your Opponent before any rolls, as long as your '
        'Movement would end with them in your Melee Range. If you move more than '
        '3 Squares through this effect, increase your Wound Roll by 1 for each '
        'Square you moved after the third. This bonus cannot exceed 2(T).\n\nIf '
        'you are in a High Environment, you may move up or down 1 rank of High '
        'Environment when using this effect. If you are in the Low Sky '
        'Environment, you may leave the High Environments entirely and return to '
        'a typical Battle Environment for the Square that you end your movement '
        'on.',
  ),
  SigModifierDef(
    name: 'Express Ticket',
    category: SigModifierCategory.movementAdv,
    description: "Don't stop your charge, and instead take your victim along for "
        'a ride to squash.',
    tpCostsPerRank: [6],
    requirement: 'Charging Assault Advantage.',
    effect: 'When you hit an Opponent with this Signature Technique, make a '
        'Might Clash against them. If you win, move any number of Squares up to '
        'your Boosted Speed in one direction. The target also moves the same '
        'number of Squares in that direction. If you move your full Boosted '
        'Speed without the Opponent colliding with Battle Terrain or another '
        'Character, reduce their Life Points by 1/2 of your Might.',
  ),
  SigModifierDef(
    name: 'High-Speed Dash',
    category: SigModifierCategory.movementAdv,
    description:
        'You use your full speed to strike your enemy while avoiding being hit '
        'yourself.',
    tpCostsPerRank: [2],
    requirement: 'Hit and Run Advantage.',
    effect: 'The movement through the effects of the Hit and Run Advantage uses '
        'your Boosted Speed and does not trigger the Exploit Maneuver.',
  ),
  SigModifierDef(
    name: 'Hit and Run',
    category: SigModifierCategory.movementAdv,
    description: 'This technique allows you to attack and then flee.',
    tpCostsPerRank: [8],
    requirement: 'N/A',
    effect: 'After using this Signature Technique, the user may move any number '
        'of Squares up to their Normal Speed in a straight line (you can move '
        'through the Square of the Opponent targeted by this Attacking Maneuver '
        'for this movement without causing collision). This movement triggers '
        'the Exploit Maneuver if you leave the Melee Range of an Opponent.',
  ),
  SigModifierDef(
    name: 'Knockback',
    category: SigModifierCategory.movementAdv,
    description: 'Your technique pushes the opponent away.',
    tpCostsPerRank: [4],
    requirement: 'N/A',
    effect: 'If you successfully Damage an Opponent with this Signature '
        'Technique, after the Wound Roll, you may make a Might Clash. If you '
        'win, move the target a number of Squares in a straight line away from '
        'you in any direction up to your Might.',
  ),
  SigModifierDef(
    name: 'Two-Step Strike',
    category: SigModifierCategory.movementAdv,
    description: 'You fling your opponent away from you before using that '
        'distance to land a decisive blow.',
    tpCostsPerRank: [8],
    requirement: 'Energy Attack, Magic Attack, Soaring Profile, or a Physical '
        'Attack with the Charging Assault Advantage; does not possess the '
        'Concentration Disadvantage.',
    effect: 'If you would use this Attacking Maneuver with an Opponent within '
        'your Melee Range, before Attack Declaration, you may target that '
        'Opponent with the Push Back option of the Thrust Maneuver as an '
        'Out-of-Sequence Maneuver.',
  ),
  // --- Power Advantages -----------------------------------------------------
  SigModifierDef(
    name: 'Accurate',
    category: SigModifierCategory.powerAdv,
    description: "A technique that hones one's focus on the target when in use.",
    tpCostsPerRank: [3, 5, 7],
    requirement: 'This Signature Technique does not have the Inaccurate '
        'Disadvantage.',
    effect: 'Increase your Strike Rolls for this Signature Technique by 1(T) for '
        'each rank of this Advantage.',
    automation: SigModifierAutomation(statEffects: [
      SigStatEffect(target: SigEffectTarget.strike, coefficientPerRank: 1),
    ]),
  ),
  SigModifierDef(
    name: 'Armor-Piercing',
    category: SigModifierCategory.powerAdv,
    description: "Your insight into your opponents' defenses allow you to bypass "
        'them more effectively.',
    tpCostsPerRank: [8],
    requirement: 'Pinpoint Profile.',
    effect: "Ignore the target's Damage Reduction equal to 1/2 of your Insight "
        'Modifier.',
  ),
  SigModifierDef(
    name: 'Brutal Blitz',
    category: SigModifierCategory.powerAdv,
    description:
        'When you rush headlong into battle, you can turn your momentum into '
        'power.',
    tpCostsPerRank: [5],
    requirement: 'Blitz Profile.',
    effect: 'If you move a number of Squares equal to your Boosted Speed through '
        'the effects of Charging Assault, you may use your Agility as the Damage '
        'Attribute for that Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Final Chance',
    category: SigModifierCategory.powerAdv,
    description: 'Pour all your pride and life into this attack.',
    tpCostsPerRank: [4],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'When you use this technique, if you are below the Injured Health '
        'Threshold, you may reduce your Life Points to 0 at Attack Declaration '
        'to increase the Ki Wager by an equal amount. You are not Defeated until '
        'after this Attacking Maneuver would be completed.',
  ),
  SigModifierDef(
    name: 'Full Wager',
    category: SigModifierCategory.powerAdv,
    description: 'You are able to unleash all of your energy in this single '
        'attack!',
    tpCostsPerRank: [10],
    requirement: 'N/A',
    effect: 'For this Attacking Maneuver, the amount of Ki Points you can Ki '
        'Wager is only limited by your remaining Capacity.',
  ),
  SigModifierDef(
    name: 'Last Legs',
    category: SigModifierCategory.powerAdv,
    description:
        "Ignore your Threshold penalties and gain power for each Threshold "
        "you're below.",
    tpCostsPerRank: [6],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'Ignore all Health Threshold penalties during this Attacking '
        'Maneuver. Increase your Strike and Wounds Rolls by 1(T) for each Health '
        "Threshold you're below.",
  ),
  SigModifierDef(
    name: 'Long Shot',
    category: SigModifierCategory.powerAdv,
    description: 'This technique is stronger when used at a far distance.',
    tpCostsPerRank: [3, 4],
    requirement: 'N/A',
    effect: 'Increase your Strike Roll and Wound Rolls for this Signature '
        'Technique by 1(T) for each rank of this Advantage when targeting '
        'Opponents who are 9+ Squares away from you.',
  ),
  SigModifierDef(
    name: 'Minion Destroyer',
    category: SigModifierCategory.powerAdv,
    description: 'You can create a lethal attack, strongly damaging those who '
        'are weaker than you.',
    tpCostsPerRank: [11],
    requirement: 'N/A',
    effect: 'If a Minion takes Damage from this Attacking Maneuver, increase the '
        'amount of Damage taken by the Damage Attribute.',
  ),
  SigModifierDef(
    name: 'Overwhelming Terror',
    category: SigModifierCategory.powerAdv,
    description: "When an enemy trembles in fear before you, they can't defend "
        'against this technique.',
    tpCostsPerRank: [12],
    requirement: 'Access to the Terrify Maneuver.',
    effect: 'Apply an Energy Charge to this Attacking Maneuver if all of the '
        'targets for this Attacking Maneuver are suffering from the Shaken '
        'Combat Condition.',
  ),
  SigModifierDef(
    name: 'Peppering Blows',
    category: SigModifierCategory.powerAdv,
    description: 'Your constant flurry of attacks makes it harder for your '
        'opponent to dodge your attacks.',
    tpCostsPerRank: [6, 8, 10],
    requirement: 'Combination Profile.',
    effect: 'For each rank of this Advantage, this Attacking Maneuver is '
        'considered another Attacking Maneuver for the sake of applying '
        'Diminishing Defense stacks.',
  ),
  SigModifierDef(
    name: 'Power Burst',
    category: SigModifierCategory.powerAdv,
    description: 'Max out your muscles to push out every drop of power!',
    tpCostsPerRank: [6, 5, 4],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'For each rank of this Advantage, gain 1 Super Stack for the '
        'duration of this Attacking Maneuver, ignoring the penalties to your '
        'Strike Roll from the Muscle Penalty.',
  ),
  SigModifierDef(
    name: 'Power Shot',
    category: SigModifierCategory.powerAdv,
    description: 'Your signature technique has more power.',
    tpCostsPerRank: [4, 6, 8],
    requirement:
        'This Signature Technique does not have the Low Penetration Disadvantage.',
    effect: 'Increase your Wound Rolls for this Signature Technique by 2(T) for '
        'each rank of this Advantage.',
    automation: SigModifierAutomation(statEffects: [
      SigStatEffect(target: SigEffectTarget.wound, coefficientPerRank: 2),
    ]),
  ),
  SigModifierDef(
    name: 'Shattering Blow',
    category: SigModifierCategory.powerAdv,
    description: 'Deal a portion of your opponents Soak as damage to them.',
    tpCostsPerRank: [4, 6, 6, 8],
    requirement: 'Crushing Profile.',
    effect: 'If you inflict Damage with this Attacking Maneuver, increase the '
        "amount of Damage inflicted by 1/4 of the target's Soak Value for each "
        'rank of this Advantage.',
  ),
  SigModifierDef(
    name: 'Sky Assault',
    category: SigModifierCategory.powerAdv,
    description: 'Your attack is exceptionally accurate when aimed upwards.',
    tpCostsPerRank: [3],
    requirement: 'Energy or Magic Foundation.',
    effect: 'Ignore any penalties from Long Range due to an Opponent being on a '
        'higher High Environment.',
  ),
  SigModifierDef(
    name: 'Super Advantage',
    category: SigModifierCategory.powerAdv,
    description: 'Double the power of one Advantage.',
    tpCostsPerRank: [11],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'Double the bonus gained from one of the following Advantages '
        '(chosen upon gaining this Advantage): Long Shot, Power Shot (up to 3 '
        'Ranks), or Accurate.',
  ),
  SigModifierDef(
    name: 'Transformation Boost',
    category: SigModifierCategory.powerAdv,
    description: 'The power of your transformation is multiplied with this '
        'attack.',
    tpCostsPerRank: [6],
    requirement: 'Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'At Attack Declaration, if you are in a Form or Transcended '
        'Enhancement, apply an Energy Charge to this Attacking Maneuver.',
  ),
  // --- Surprise Advantages --------------------------------------------------
  SigModifierDef(
    name: 'Counter',
    category: SigModifierCategory.surpriseAdv,
    description:
        "Your technique works best when used as a response to an opponent's "
        'attack.',
    tpCostsPerRank: [7],
    requirement: 'N/A',
    effect: 'When you use the Cross Counter option of the Defend Maneuver, you '
        'may use the Signature Technique Maneuver to use this Signature '
        'Technique instead of the Basic Attack Maneuver. If you do, your Defense '
        'Value is not halved for this use of the Cross Counter option of the '
        'Defend Maneuver.',
  ),
  SigModifierDef(
    name: 'Delayed',
    category: SigModifierCategory.surpriseAdv,
    description: "This Signature Technique's damage comes later than one would "
        'expect, at the whim of the user.',
    tpCostsPerRank: [8],
    requirement: 'This cannot be applied to any Attacking Maneuver except '
        'through those that were used through the Signature Technique Maneuver '
        '(even if they are treated as Signature Techniques otherwise).',
    effect: 'If you hit an Opponent with this Attacking Maneuver, roll Wound as '
        'normal but instead of your Opponent taking any Damage, keep a record of '
        'the Dice Score of your Wound Roll and apply a stack of Imminent to the '
        'target(s) for the remainder of the Combat Encounter. While they possess '
        'this stack of Imminent, you cannot use this Signature Technique.\n\nAs '
        'an Instant Maneuver, you may remove this stack of Imminent from all '
        'targets who possess it to apply the Dice Score of the Wound Roll '
        'against their Soak Value and calculate/apply Damage as usual.',
  ),
  SigModifierDef(
    name: 'Exploiting Technique',
    category: SigModifierCategory.surpriseAdv,
    description: 'This Signature Technique can be used quickly if an opening '
        'presents itself.',
    tpCostsPerRank: [7],
    requirement: 'Does not possess an AoE or the Mandatory Charge, Special Set '
        'Up, Grappling, Time-Skipped, Trick Technique, or the Lead Up '
        'Disadvantages.',
    effect: 'When you use the Exploit Maneuver, instead of the Basic Attack '
        'Maneuver, you may use the Signature Technique Maneuver to use this '
        'Signature Technique.',
  ),
  SigModifierDef(
    name: 'Fake Out',
    category: SigModifierCategory.surpriseAdv,
    description: 'This Signature Technique looks a lot more impressive than it '
        "is, forcing the Opponent's hand in defending against it.",
    tpCostsPerRank: [10],
    requirement: '2+ Skill Ranks in Bluff, Super Signature.',
    effect: 'Upon Attack Declaration, make a Clash (Bluff vs Intuition) against '
        'the target(s) of this Attacking Maneuver. If you win, the losing '
        'target(s) must either use the Guard option of the Defend Maneuver or '
        'make a typical Dodge Roll against this Attacking Maneuver – they cannot '
        'use any other Counter Maneuver (except the Afterimage Technique). If a '
        'target chose to Dodge this Attacking Maneuver, then after completing '
        'this Attacking Maneuver, you may use the Basic Attack Maneuver or '
        'Signature Technique Maneuver against that target as an Out-of-Sequence '
        'Maneuver. You can only target a single Character that attempts to dodge '
        'this Attacking Maneuver with this effect and you cannot use a Signature '
        "Technique with the Fake Out Advantage if you've already used one during "
        'this Combat Round.',
  ),
  SigModifierDef(
    name: 'Instant Assault',
    category: SigModifierCategory.surpriseAdv,
    description:
        'Your attack hits out of nowhere, leaving enemies no time to prepare.',
    tpCostsPerRank: [10],
    requirement: 'N/A',
    effect: 'No Instant Maneuvers can be triggered in response to this Attacking '
        'Maneuver.',
  ),
  SigModifierDef(
    name: 'Low Stakes Attack',
    category: SigModifierCategory.surpriseAdv,
    description: 'You never really intended this to be a big attack anyways.',
    tpCostsPerRank: [5],
    requirement: 'Fake Out Advantage.',
    effect: 'This Signature Technique does not count towards your uses of the '
        'Signature Technique Maneuver.',
  ),
  SigModifierDef(
    name: 'Personal Bomb',
    category: SigModifierCategory.surpriseAdv,
    description: 'You can create a delayed explosion of raw power that catches '
        'your enemies unaware.',
    tpCostsPerRank: [12],
    requirement: 'Delayed, Sphere AoE.',
    effect: 'If this Attacking Maneuver would target multiple Characters, you '
        'can instead select a single target. When you remove this Signature '
        "Technique's only stack of Imminent, apply this Signature Technique's "
        'AoE (centered on the target the stack of Imminent was on). All '
        'Characters (other than the initial target) within that AoE act as if '
        'they were targeted by this Signature Technique – make a new Strike Roll '
        'against those Characters as if this Signature Technique was an Attacking '
        'Maneuver that did not possess the Delayed Advantage. All targets of '
        'this Signature Technique receive the initially rolled Wound Roll as '
        'usual.',
  ),
  SigModifierDef(
    name: 'Trick Attack',
    category: SigModifierCategory.surpriseAdv,
    description:
        'You confuse or distract your opponent, bypassing their defenses in the '
        'process.',
    tpCostsPerRank: [4],
    requirement: '2+ Skill Ranks in Bluff or Acrobatics.',
    effect: 'Select a Skill – Bluff or Acrobatics. When you target an Opponent '
        'with this Attacking Maneuver, make a Clash (Your selected Skill vs '
        'Intuition/Perception). If you win, this Attacking Maneuver has its '
        'Strike Roll increased by 2(bT).',
  ),
  // --- Technical Advantages -------------------------------------------------
  SigModifierDef(
    name: 'Condition',
    category: SigModifierCategory.technicalAdv,
    description: 'This attack is meant to cripple an opponent temporarily.',
    tpCostsPerRank: [14],
    requirement:
        "Cannot be applied to the 'Elemental (Fire/Ice/Water/Lightning/Poison)' "
        'Profiles.',
    effect: 'If this Attacking Maneuver deals Damage to an Opponent, apply one '
        'of the Combat Conditions below for the duration listed (chosen when '
        'gaining this Advantage):\n\nGuard Down: Until the start of your next '
        'turn.\n\nDrained: Until the start of your next turn.\n\nShaken: Until '
        'the end of the target’s next turn.\n\nPoisoned: Until the end of '
        'the target’s next turn.\n\nIf an Opponent is already suffering '
        'from your selected Combat Condition, instead increase the Wound Roll '
        'for this Attacking Maneuver against them by 3(T).',
  ),
  SigModifierDef(
    name: 'Deadly Drop',
    category: SigModifierCategory.technicalAdv,
    description:
        'You use gravity to slam an Opponent into the ground for massive damage.',
    tpCostsPerRank: [8],
    requirement:
        'Physical Attack, Grappling Disadvantage, Restricted – High Environment.',
    effect: 'If this Attacking Maneuver hits an Opponent while you are the '
        'Grappler in a Grapple in a High Environment (except Deep Space), you '
        '(and any characters you are Grappling) may leave all High Environments '
        'and return to the Battle Environment on the Square you are occupying. '
        'Then, make a Might Clash against the target of this Attacking Maneuver. '
        'If you win, they Collide with the Square underneath them (see - Ground '
        'Collision). Increase the Collision Damage they suffer by 1/2 of your '
        'Might multiplied by the rank of the High Environment you were in when '
        'you applied this effect.',
  ),
  SigModifierDef(
    name: 'Hefty Stagger',
    category: SigModifierCategory.technicalAdv,
    description: "This technique is exceptionally good at disrupting an "
        "opponent's balance.",
    tpCostsPerRank: [4, 6],
    requirement: 'Staggering Attack Advantage.',
    effect: 'Increase the Dice Score for the Might Clash initiated through the '
        'effects of Staggering Attack by 1(T) for each rank of this Advantage.',
  ),
  SigModifierDef(
    name: 'Homing',
    category: SigModifierCategory.technicalAdv,
    description: 'Your attack is able to be controlled in some way to allow it '
        'to try again.',
    tpCostsPerRank: [6, 8, 10],
    requirement: 'This Attacking Maneuver does not have an Area of Effect.',
    effect: 'When you miss an Opponent with this Signature Technique, you may '
        'roll your Strike Roll an additional time equal to the ranks of this '
        "Advantage. For each time you've missed, increase your Strike Roll by "
        '1(T). Attacks from the Homing Advantage are still considered one '
        'Attacking Maneuver and therefore do not inflict further Diminishing '
        'Defense upon an Opponent.\n\nIf you have 2+ Ranks in Homing, if an '
        'Opponent that was targeted by this Attacking Maneuver moves outside of '
        "this Attacking Maneuver's range, if they are still within the "
        'Battlefield, you may still target them with this Attacking Maneuver but '
        'if you miss, you cannot apply the effects of Homing on that Attacking '
        'Maneuver.',
  ),
  SigModifierDef(
    name: 'Penetration',
    category: SigModifierCategory.technicalAdv,
    description: "Your technique weakens the target's bodily defenses "
        'temporarily.',
    tpCostsPerRank: [12, 6, 6],
    requirement: 'This Attacking Maneuver does not have an Area of Effect '
        '(Sphere/Cone) or the Low Penetration Disadvantage.',
    effect: 'When you hit an Opponent with this Attacking Maneuver, apply a '
        'number of stacks of the Broken Combat Condition equal to the ranks of '
        'this Advantage until the start of your next turn.',
  ),
  SigModifierDef(
    name: 'Perfect Strike',
    category: SigModifierCategory.technicalAdv,
    description: "Your attack doesn't waste a single drop of energy.",
    tpCostsPerRank: [8],
    requirement: 'Simple Profile, Ultimate Signature Technique.',
    ultimateOnly: true,
    effect: 'Halve the reduction to your Capacity Rate from any Ki Points spent '
        "on this Signature Technique's Ki Point Cost (you must still pay the "
        'full Ki Point Cost).',
  ),
  SigModifierDef(
    name: 'Powerbomb',
    category: SigModifierCategory.technicalAdv,
    description: 'By releasing your grabbed opponent at the right time, you can '
        'add momentum to your attack to deal even greater damage.',
    tpCostsPerRank: [11, 4],
    requirement: 'Physical Attack, Grappling Disadvantage.',
    effect: 'When using this Attacking Maneuver while in a Grapple that you are '
        'the Grappler of against a target that is the Grappled in that same '
        'Grapple, you can choose to end the Grapple after completing this '
        'Attacking Maneuver. If you do, you cannot use the Grapple Maneuver '
        'until the start of your next turn, but this Attacking Maneuver has its '
        'Wound Roll increased by 1/2 of your Might for each Rank of this '
        'Advantage.',
  ),
  SigModifierDef(
    name: 'Rebound',
    category: SigModifierCategory.technicalAdv,
    description:
        'You have precision control over how your energy moves around the '
        'battlefield.',
    tpCostsPerRank: [2],
    requirement: 'Homing Advantage.',
    effect: 'When you roll your Strike Roll again through the effects of the '
        'Homing Advantage, you can select a different target for this Attacking '
        'Maneuver to target instead of targeting the Opponent you missed. Only '
        'the Opponent who was initially targeted by this Attacking Maneuver '
        'receives Diminishing Defense after this Attacking Maneuver is '
        'completed.',
  ),
  SigModifierDef(
    name: 'Staggering Attack',
    category: SigModifierCategory.technicalAdv,
    description: "Your attack disrupts your opponent's balance, making it "
        'difficult for them to move.',
    tpCostsPerRank: [6],
    requirement: 'N/A',
    effect: 'If you inflict Damage to an Opponent with this Attacking Maneuver, '
        'make a Might Clash against your Opponent. If you win, they gain the '
        'Staggered Combat Condition until the end of their turn.',
  ),
  SigModifierDef(
    name: 'Sudden Blast',
    category: SigModifierCategory.technicalAdv,
    description: 'This explosive technique is impossible to reflect.',
    tpCostsPerRank: [4],
    requirement: 'Clearing Profile.',
    effect: 'A Character cannot use the Reflect Maneuver as a Modifier Maneuver '
        'through the effects of the Parry option of the Defend Maneuver or the '
        'Deflect/Distant Deflect options of the Intervene Maneuver in response '
        'to this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Sustained',
    category: SigModifierCategory.technicalAdv,
    description: "Your attack continues to deal Damage after it's been used.",
    tpCostsPerRank: [6, 6, 6, 6, 6],
    requirement: 'N/A',
    effect: 'If you deal Damage with this Signature Technique, your Opponent '
        'gains a Stack of DOT for each Rank of this Advantage. This effect lasts '
        'for 3 Combat Rounds. If the Opponent is dealt Damage by an Attacking '
        'Maneuver with this Advantage while suffering from this effect, reset '
        'the amount of Combat Rounds until this effect ends.',
  ),
  SigModifierDef(
    name: 'Terrain Slam',
    category: SigModifierCategory.technicalAdv,
    description: 'Your attack slams an enemy into the scenery, causing massive '
        'damage.',
    tpCostsPerRank: [7],
    requirement: '1+ ranks of the Powerbomb Advantage',
    effect: 'After concluding this Attacking Maneuver, make a Might Clash '
        'against the target(s) of this Attacking Maneuver. If you win this Clash '
        'against an Opponent, choose an unoccupied Square or a Feature adjacent '
        'to that Opponent. That Opponent collides with your chosen '
        'Square/Feature.',
  ),
  // --- Miscellaneous Advantages ---------------------------------------------
  SigModifierDef(
    name: 'Alotta Lotta Attacks',
    category: SigModifierCategory.miscAdv,
    description:
        'You throw out even more attacks when using the Combination Profile.',
    tpCostsPerRank: [3, 5, 7],
    requirement: 'Combination Profile.',
    effect: 'After you hit an Opponent, roll your Strike Roll an additional time '
        'for each rank of this Advantage.',
  ),
  SigModifierDef(
    name: 'Ascended Signature',
    category: SigModifierCategory.miscAdv,
    description: 'Turn the power up to a new level! A Super becomes an Ultimate!',
    tpCostsPerRank: [8],
    requirement: 'Super Signature Technique.',
    effect: 'At Attack Declaration, this Signature Technique can become an '
        'Ultimate Signature Technique. If it does, you cannot use this Signature '
        'Technique for the remainder of the Combat Encounter. This Signature '
        'Technique still cannot gain Advantages that require an Ultimate '
        'Signature Technique.',
  ),
  SigModifierDef(
    name: 'Efficiency',
    category: SigModifierCategory.miscAdv,
    description: 'This Signature Technique is surprisingly efficient with ki '
        'expenditure for its effects.',
    tpCostsPerRank: [8, 7],
    requirement:
        'This Signature Technique does not have the Inefficiency Disadvantage.',
    effect: 'Reduce the total KP Cost of this Attacking Maneuver by 4(T) for '
        'each rank.',
    automation: SigModifierAutomation(kpPerTierPerRank: -4),
  ),
  SigModifierDef(
    name: 'Forceful Launch',
    category: SigModifierCategory.miscAdv,
    description: 'You put even more power into your attacks to knock enemies '
        'further away from you.',
    tpCostsPerRank: [4, 6, 8],
    requirement: 'Launching Profile.',
    effect: 'Increase the amount of Squares an Opponent is moved through the '
        "effects of Knockback and your Dice Score for Knockback's Might Clash by "
        '1(T) for each rank of this Advantage.',
  ),
  SigModifierDef(
    name: 'Precise Strike',
    category: SigModifierCategory.miscAdv,
    description: 'The shock wave your attack makes is explosively stronger.',
    tpCostsPerRank: [4],
    requirement: 'Launching Profile.',
    effect: 'If you score a Critical Result on the Strike Roll for this '
        'Attacking Maneuver, increase the amount of Squares your Opponent moves '
        'from Knockback by 1/2.',
  ),
  SigModifierDef(
    name: 'Throwing Technique',
    category: SigModifierCategory.miscAdv,
    description: 'This technique allows you to lob an object at your foes.',
    tpCostsPerRank: [5],
    requirement: 'Simple Profile of the Physical Foundation.',
    effect: 'When you use the Throw Maneuver, you may use this Signature '
        'Technique instead (you still follow the typical range rules for the '
        'Throw Maneuver). This also treats the Throw Maneuver as the Signature '
        'Technique Maneuver for any effects and uses any [x/Round] limitations '
        'of the Signature Technique Maneuver - if you cannot use the Signature '
        'Technique Maneuver, then you cannot use a Signature Technique through '
        'the Throw Maneuver either. You may only use this Signature Technique '
        'through the effects of the Throw Maneuver while wielding a Weapon with '
        'the Throwing Weapon Quality.',
  ),
  SigModifierDef(
    name: 'Transformation Flare',
    category: SigModifierCategory.miscAdv,
    description: 'You can transform in the midst of using this technique when '
        'your power is otherwise insufficient.',
    tpCostsPerRank: [4],
    requirement: 'Restricted – Untransformed Disadvantage.',
    effect: 'If this Signature Technique hits an Opponent or if an Opponent '
        'initiates a Duel Maneuver against this Attacking Maneuver, you may use '
        'the Transformation Maneuver as an Out-of-Sequence Maneuver before you '
        'roll the Wound Roll or any rolls involved in that Duel Maneuver. You '
        'leave any Transformation you entered through this effect after '
        'concluding the Attacking Maneuver or Duel Maneuver and Damage has been '
        'calculated. Entering a Transformation in this way ignores the effects '
        'of the Restricted - Untransformed Disadvantage.',
  ),
  SigModifierDef(
    name: 'Twin-Linked',
    category: SigModifierCategory.miscAdv,
    description:
        'The technique has a more consistent and stronger Strike or Wound value.',
    tpCostsPerRank: [10],
    requirement: 'This Signature Technique does not have the Dead-Link '
        'Disadvantage for your chosen Combat Roll.',
    effect: 'Choose Strike or Wound. When making the selected Combat Roll for '
        'this Attacking Maneuver, roll it a second time and use the highest Dice '
        'Score of the two rolls. If you select Strike, this effect is not '
        'applied to the additional Strike Rolls made with the Combination '
        'Profile.',
  ),
  SigModifierDef(
    name: 'Weapon Assisted',
    category: SigModifierCategory.miscAdv,
    description: 'You are able to use a weapon to perform this attack.',
    tpCostsPerRank: [2],
    requirement: 'N/A',
    effect: 'This attack can be used while wielding a Weapon and benefits from '
        'its Size, Category, and Qualities – making it an Armed Attack if it '
        'does. Physical Weapons apply only to Physical Profiles, Energy Weapons '
        'for Energy Profiles, and Magic Weapons for Magic Profiles.',
  ),
];

/// The full Disadvantages catalogue (7 categories). TP costs are negative.
const List<SigModifierDef> kDbuSignatureDisadvantages = [
  // --- Movement Disadvantages -----------------------------------------------
  SigModifierDef(
    name: 'Drop Down',
    category: SigModifierCategory.movementDis,
    description: 'An air-to-ground assault, this technique uses the momentum of '
        'gravity to aid in dealing massive damage.',
    tpCostsPerRank: [-2],
    requirement: 'Charging Assault Advantage, Restricted – Environment (High).',
    effect: 'To use this Signature Technique, you must be in a High Environment '
        'and the target for this Attacking Maneuver must not be in the High '
        'Environment or a lower rank of High Environment.',
  ),
  SigModifierDef(
    name: 'Recoil',
    category: SigModifierCategory.movementDis,
    description: 'Using this technique sends you bouncing off of your target.',
    tpCostsPerRank: [-2],
    requirement: 'Hit and Run Advantage.',
    effect: 'When you use the effects of Hit and Run through this Signature '
        'Technique, you must move your full Normal Speed in a straight line in '
        'the opposite direction of the Opponent targeted by this Attacking '
        'Maneuver (if there are multiple, your ARC decides which Opponent). This '
        'movement can cause Collision if you would enter an occupied Square.',
  ),
  // --- Resource Disadvantages -----------------------------------------------
  SigModifierDef(
    name: 'All or Nothing',
    category: SigModifierCategory.resourceDis,
    description:
        'Give it your all! This Signature Technique draws out all of your power.',
    tpCostsPerRank: [-5],
    requirement: 'N/A',
    effect: 'You must make the highest Ki Wager possible for this Signature '
        'Technique. If, after using this Signature Technique, your Capacity is '
        'not 0 – set your Capacity to 0.',
  ),
  SigModifierDef(
    name: 'Backlash',
    category: SigModifierCategory.resourceDis,
    description: 'Your technique drains away your very life essence to use.',
    tpCostsPerRank: [-2, -3, -3, -3, -3],
    requirement: 'N/A',
    effect: 'Reduce your Life Points by 2(bT) for each rank of this Advantage '
        'after concluding this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Inefficiency',
    category: SigModifierCategory.resourceDis,
    description:
        'Your technique is more wasteful with Ki and costs more for less bang.',
    tpCostsPerRank: [-6, -7],
    requirement:
        'This Signature Technique does not have the Efficiency Advantage.',
    effect: 'Increase the total KP Cost of this Attacking Maneuver by 4(T) for '
        'each rank.',
    automation: SigModifierAutomation(kpPerTierPerRank: 4),
  ),
  // --- Restriction Disadvantages --------------------------------------------
  SigModifierDef(
    name: 'Concentration',
    category: SigModifierCategory.restrictionDis,
    description: "You can't use this technique while an enemy is close due to "
        'reasons relating to concentration or freedom of movement.',
    tpCostsPerRank: [-4],
    requirement: 'Energy Foundation, Magic Foundation, Soaring Profile, or '
        'Physical Foundation with the Widespread Assault or Charging Assault '
        'Advantage.',
    effect: 'You cannot use this Signature Technique through the Signature '
        "Technique Maneuver if you are within an Opponent's Melee Range. You may "
        'still use the Energy Charge Maneuver for this Signature Technique '
        "within an Opponent's Melee Range.",
  ),
  SigModifierDef(
    name: 'Grappling',
    category: SigModifierCategory.restrictionDis,
    description: 'The technique requires you to be holding the target.',
    tpCostsPerRank: [-5],
    requirement: 'N/A',
    effect: 'You can only use this Attacking Maneuver if you are currently '
        'Grappling at least one of the target(s) of this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Restricted – Environment',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used while in a certain '
        'Environment.',
    tpCostsPerRank: [-6],
    requirement: 'N/A',
    effect: 'Choose a Battle Environment other than Standard, if you select High '
        'then you select every High Environment. You cannot use this Signature '
        'Technique unless you are in the chosen Battle Environment.',
  ),
  SigModifierDef(
    name: 'Restricted – Stance',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used while in a certain Stance.',
    tpCostsPerRank: [-3],
    requirement: 'Martial Skill Awakening',
    effect: 'Choose a Stance (see - Martial Skill). You can only use this '
        'Signature Technique while in your chosen Stance.',
  ),
  SigModifierDef(
    name: 'Restricted – State',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used while in a certain State.',
    tpCostsPerRank: [-4],
    requirement: 'N/A',
    effect: 'Choose a State. You cannot use this Signature Technique unless you '
        'are in the chosen State.',
  ),
  SigModifierDef(
    name: 'Restricted – Transformation',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used in certain transformations.',
    tpCostsPerRank: [-2, -4],
    requirement: 'This Attacking Maneuver does not possess the Restricted - '
        'Untransformed Disadvantage.',
    effect: 'Choose a type of Transformation (Enhancement or Form). You can only '
        'use this Signature Technique while in that category of Transformation. '
        'If you have two ranks, instead choose a single Transformation '
        '(Enhancement or Form) or a Transformation Line. You can only use it '
        'while in that specific Transformation or Transformation Line.',
  ),
  SigModifierDef(
    name: 'Restricted – Untransformed',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used while not in a Transformation.',
    tpCostsPerRank: [-6],
    requirement: 'You possess a Form, this Attacking Maneuver does not possess '
        'the Restricted - Transformation Disadvantage.',
    effect: 'You cannot use this Signature Technique unless you are in your '
        'Normal State (see — Transformation Rules).',
  ),
  SigModifierDef(
    name: 'Restricted – Weapon',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique can only be used with certain weapons.',
    tpCostsPerRank: [-2, -4],
    requirement: 'Weapon Assisted Advantage.',
    effect: 'Choose a Weapon Category from those that use the same Foundation as '
        'this Signature Technique. You can only use this Signature Technique with '
        'a Weapon of that Weapon Category. If you have two ranks, instead choose '
        'a single Weapon. You can only use it with that specific Weapon.',
  ),
  SigModifierDef(
    name: 'Restricted – Weather',
    category: SigModifierCategory.restrictionDis,
    description:
        'This technique can only be used while in a certain Battle Weather.',
    tpCostsPerRank: [-4],
    requirement: 'N/A',
    effect: 'Choose a Battle Weather. You cannot use this Signature Technique '
        'unless you are in the chosen Battle Weather.',
  ),
  SigModifierDef(
    name: 'Required Counter',
    category: SigModifierCategory.restrictionDis,
    description:
        'This technique is only usable when your opponent is in the midst of '
        'attacking.',
    tpCostsPerRank: [-5],
    requirement: 'Counter Advantage.',
    effect: 'You cannot use this Signature Technique Maneuver except through the '
        'effects of the Counter Advantage.',
  ),
  SigModifierDef(
    name: 'Time-Skipped',
    category: SigModifierCategory.restrictionDis,
    description: 'This technique is designed to be used outside of time.',
    tpCostsPerRank: [-4],
    requirement: 'Time to Make the Donuts Advancement',
    effect: 'This Attacking Maneuver can only be used through the effects of the '
        'Time-Skip Unique Ability.',
  ),
  SigModifierDef(
    name: 'Vehicle Attack',
    category: SigModifierCategory.restrictionDis,
    description:
        'This technique requires the use of your vehicle to ram into your '
        'enemies.',
    tpCostsPerRank: [-4],
    requirement: 'Blitz Profile OR Restricted - Weapon Disadvantage.',
    effect: 'You cannot use this Signature Technique unless you are Piloting a '
        'Vehicle.',
  ),
  // --- Set-Up Disadvantages -------------------------------------------------
  SigModifierDef(
    name: 'Consolidated Strike',
    category: SigModifierCategory.setUpDis,
    description:
        'This technique relies heavily upon exploiting a vital area on the '
        'target.',
    tpCostsPerRank: [-4],
    requirement: 'Attacking Maneuver does not possess an AoE.',
    effect: 'To use this Signature Technique, you must apply the Called Shot '
        'Modifier Maneuver to this Attacking Maneuver. If you cannot apply the '
        'Called Shot Modifier Maneuver to this Attacking Maneuver for any reason '
        '(such as through lacking the Actions to pay the Action Cost), then you '
        'cannot use this Signature Technique. If this would occur after '
        'declaring it, then the use of the Signature Technique Maneuver fails '
        'and you regain the Action Cost and Ki Point Cost of the Signature '
        'Technique Maneuver (if it was declared through the Energy Charge '
        'Maneuver, you lose all accumulated Energy Charges).',
  ),
  SigModifierDef(
    name: 'Lead Up',
    category: SigModifierCategory.setUpDis,
    description: 'This technique is part of a combination and must be used as '
        'part of a certain order of attacks.',
    tpCostsPerRank: [-6],
    requirement:
        'This Signature Technique does not possess the Mandatory Charge '
        'Disadvantage.',
    effect: 'Select a Profile. To use this Signature Technique, you must hit an '
        'Opponent with an Attacking Maneuver of your selected Profile as your '
        'last Maneuver before you use this Signature Technique. The Opponent hit '
        'by that last Attacking Maneuver must also be a target for this '
        'Signature Technique.',
  ),
  SigModifierDef(
    name: 'Mandatory Charge',
    category: SigModifierCategory.setUpDis,
    description: 'The technique requires a certain accumulation of energy before '
        'it can be used.',
    tpCostsPerRank: [-4, -8, -10],
    requirement: 'N/A',
    effect: 'You must use the Energy Charge Maneuver on this Technique two times '
        'for each rank of this Disadvantage before it can be used.',
  ),
  SigModifierDef(
    name: 'Sneak Attack',
    category: SigModifierCategory.setUpDis,
    description: 'This technique only works when you catch your enemy unawares.',
    tpCostsPerRank: [-4],
    requirement: 'N/A',
    effect: 'You can only use this Signature Technique when Hidden, and all of '
        'your target(s) for this Attacking Maneuver must be your Oblivious '
        'Characters.',
  ),
  SigModifierDef(
    name: 'Special Set Up',
    category: SigModifierCategory.setUpDis,
    description:
        'In order to use this technique, you must perform another action first.',
    tpCostsPerRank: [-4],
    requirement: 'This Signature Technique does not possess the Mandatory Charge '
        'Disadvantage or the Lead Up Disadvantage.',
    effect: 'Select a Special Maneuver you have access to that has an Action '
        "Cost of 1 Standard Action. You can't use this Signature Technique if "
        'you didn’t use your selected Special Maneuver as your last '
        'Maneuver this Combat Round.',
  ),
  // --- Targeting Disadvantages ----------------------------------------------
  SigModifierDef(
    name: 'Distant Explosion',
    category: SigModifierCategory.targetingDis,
    description: 'This technique requires that you launch it at an enemy.',
    tpCostsPerRank: [-3],
    requirement: 'Sphere AoE, this Attacking Maneuver does not have the '
        'Self-Explosion Disadvantage',
    effect: 'You must select a Square occupied by an Opponent to be the Target '
        'Square for the AoE of this Attacking Maneuver (that Opponent is also a '
        'target for this Attacking Maneuver).',
  ),
  SigModifierDef(
    name: 'Hostile Chase',
    category: SigModifierCategory.targetingDis,
    description:
        'Your attacks that do not hit their marks run the risk of hitting you.',
    tpCostsPerRank: [-7],
    requirement: '2+ ranks of the Homing Advantage, Energy or Magic Foundation',
    effect: 'If you score a Botch Result on any Strike Roll made for this '
        'Attacking Maneuver, or your Opponent scored a Critical Result on their '
        'Dodge Roll against this Attacking Maneuver, you are hit by this '
        'Attacking Maneuver. Roll Wound as an Urgent Roll and apply Damage as '
        'you would normally.',
  ),
  SigModifierDef(
    name: 'Limited Line',
    category: SigModifierCategory.targetingDis,
    description: 'This attack can only travel a certain distance.',
    tpCostsPerRank: [-4, -2],
    requirement: 'Line AoE.',
    effect: 'Instead of covering all Squares in a straight line to the end of '
        'the Battlefield, your Line AoE ends 8 Squares from you. If you have 2 '
        'Ranks in this Disadvantage, the Line AoE only covers 4 Squares in a '
        'direct line.',
  ),
  SigModifierDef(
    name: 'Self-Explosion',
    category: SigModifierCategory.targetingDis,
    description: 'Your explosion attack originates from you.',
    tpCostsPerRank: [-6],
    requirement: 'Sphere AoE, this Attacking Maneuver does not have the Distant '
        'Explosion Disadvantage.',
    effect: 'You must select a Square you occupy to be the Target Square for the '
        'AoE of this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Skyward Strike',
    category: SigModifierCategory.targetingDis,
    description:
        'This technique requires you to attack your opponent from far below '
        'them.',
    tpCostsPerRank: [-8],
    requirement: 'This Signature Technique does not possess an AoE and is of the '
        'Energy Foundation, Magic Foundation, or Physical Foundation with the '
        'Charging Assault Advantage.',
    effect: 'You cannot use this Signature Technique unless your target is in a '
        'High Environment of a higher rank than you or while you are not in a '
        'High Environment. You may ignore this effect if you are both in the '
        'Deep Space Environment.',
  ),
  SigModifierDef(
    name: 'Small Scale Blast',
    category: SigModifierCategory.targetingDis,
    description: 'This attack has less destructive force than normal.',
    tpCostsPerRank: [-4],
    requirement:
        'Sphere AoE, this Signature Technique has no ranks of Terrain '
        'Destruction.',
    effect: 'The Magnitude from your Sphere AoE becomes Minor.',
  ),
  SigModifierDef(
    name: 'Volatile Explosion',
    category: SigModifierCategory.targetingDis,
    description: 'Your technique knows no friend or foe – only destruction.',
    tpCostsPerRank: [-8],
    requirement: 'Sphere AoE (see — Area of Effect).',
    effect: 'If you are within the AoE of this Signature Technique, you are also '
        'considered a target for this Attacking Maneuver. This Attacking '
        'Maneuver automatically hits you and you cannot use a Counter Maneuver '
        'in response to it.',
  ),
  // --- Weakness Disadvantages -----------------------------------------------
  SigModifierDef(
    name: 'Compressed Element',
    category: SigModifierCategory.weaknessDis,
    description: 'This technique is unable to affect the battlefield.',
    tpCostsPerRank: [-4],
    requirement:
        'Elemental (Fire/Ice/Lightning/Poison/Water/Dark/Light/Plantlife).',
    effect: 'Ignore the second listed effect of the Elemental Profile(s) applied '
        'to this Signature Technique.',
  ),
  SigModifierDef(
    name: 'Exhaustive',
    category: SigModifierCategory.weaknessDis,
    description: 'Your technique leaves you exhausted.',
    tpCostsPerRank: [-6, -10],
    requirement: 'N/A',
    effect: 'After using this Signature Technique, gain a number of Stacks for '
        'the Fatigued Combat Condition equal to the number of ranks spent on '
        'this Disadvantage until the end of your next turn. If you use this '
        'Signature Technique during this effect, refresh the duration of this '
        'effect.',
  ),
  SigModifierDef(
    name: 'Inaccurate',
    category: SigModifierCategory.weaknessDis,
    description: 'The technique is clumsy, hard to aim, or gives the opponent '
        'more time to react.',
    tpCostsPerRank: [-4, -5, -6],
    requirement:
        'This Signature Technique does not have the Accurate Advantage.',
    effect: 'Decrease your Strike Rolls for this Signature Technique by 1(T) for '
        'each rank of this Disadvantage.',
    automation: SigModifierAutomation(statEffects: [
      SigStatEffect(target: SigEffectTarget.strike, coefficientPerRank: -1),
    ]),
  ),
  SigModifierDef(
    name: 'Low Penetration',
    category: SigModifierCategory.weaknessDis,
    description: 'The technique has weak power for its effort.',
    tpCostsPerRank: [-2, -3, -4],
    requirement: 'This Signature Technique does not have the Power Shot or '
        'Penetration Advantage.',
    effect: 'Reduce your Wound Rolls for this Signature Technique by 1(T) for '
        'each rank of this Disadvantage.',
    automation: SigModifierAutomation(statEffects: [
      SigStatEffect(target: SigEffectTarget.wound, coefficientPerRank: -1),
    ]),
  ),
  SigModifierDef(
    name: 'Low-Power Crush',
    category: SigModifierCategory.weaknessDis,
    description:
        'This technique is blunted in exchange for dealing pure damage.',
    tpCostsPerRank: [-10],
    requirement: 'Crushing Profile',
    effect: 'Halve your Damage Attribute for this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Short Range',
    category: SigModifierCategory.weaknessDis,
    description: "This technique is best used right in your opponent's face.",
    tpCostsPerRank: [-2, -2],
    requirement: 'Energy or Magic Foundation, this Attacking Maneuver does not '
        'have an Area of Effect.',
    effect: 'If this Attacking Maneuver possesses 1 Rank of this Disadvantage, '
        'reduce your Strike and Wound Rolls for this Signature Technique by '
        '2(bT) against Opponents outside of your Melee Range. If this Attacking '
        'Maneuver possesses 2 Ranks of this Disadvantage, you can only target '
        'Characters in your Melee Range with this Attacking Maneuver.',
  ),
  SigModifierDef(
    name: 'Stat Drain',
    category: SigModifierCategory.weaknessDis,
    description: 'The technique weakens or drains your power after use.',
    tpCostsPerRank: [-7, -7, -7],
    requirement: 'N/A',
    effect: 'For each rank of this Disadvantage, after using this Signature '
        'Technique, reduce your Combat Rolls and Soak Value by 1(bT) until the '
        'end of your next turn.',
  ),
  // --- Miscellaneous Disadvantages ------------------------------------------
  SigModifierDef(
    name: 'Climax Attack',
    category: SigModifierCategory.miscDis,
    description: 'Your technique is something used as a last resort or when your '
        'blood is pumping high enough.',
    tpCostsPerRank: [-2, -3, -4],
    requirement: 'N/A',
    effect: 'You can only use this Signature Technique while below the Bruised '
        'Threshold (First Rank), the Injured Threshold (Second Rank), or the '
        'Critical Threshold (Third Rank).',
  ),
  SigModifierDef(
    name: 'Dead-Link',
    category: SigModifierCategory.miscDis,
    description:
        'The technique has a less consistent and weaker Strike or Wound value.',
    tpCostsPerRank: [-6],
    requirement: 'This Signature Technique does not have the Twin-Link Advantage '
        'for your chosen Combat Roll.',
    effect: 'Choose Strike or Wound. When making the selected Combat Roll, roll '
        'it a second time and use the lower Dice Score of the two rolls.',
  ),
  SigModifierDef(
    name: 'Shoot and Pray',
    category: SigModifierCategory.miscDis,
    description:
        'You loose so many attacks with such imprecision that you quickly tire '
        'yourself out.',
    tpCostsPerRank: [-3, -4],
    requirement: 'Combination Profile.',
    effect: 'This Attacking Maneuver counts as an additional number of Attacking '
        'Maneuvers equal to its number of ranks for the effects of Diminishing '
        'Offense.',
  ),
  SigModifierDef(
    name: 'Short Delay',
    category: SigModifierCategory.miscDis,
    description: "This technique's effects dissipate quickly if not used.",
    tpCostsPerRank: [-4],
    requirement: 'Delayed Advantage.',
    effect: "If you haven't used an Instant Maneuver to remove this Signature "
        "Technique's stack of Imminent after 2 Combat Rounds have passed, you "
        'must remove the stack of Imminent and apply the Wound Roll at the end '
        'of that Combat Round.',
  ),
  SigModifierDef(
    name: 'United Attack',
    category: SigModifierCategory.miscDis,
    description: 'This technique requires more than one person to execute.',
    tpCostsPerRank: [-10],
    requirement: 'N/A',
    effect: 'To use this Signature Technique, you must have an Ally in your '
        'Combat Encounter who also possesses this Signature Technique. When '
        'using the Signature Technique Maneuver to use this Signature Technique, '
        'you must first ask consent from one of your Allies who possesses this '
        'Signature Technique. If they consent, they must in turn use the United '
        'Attack Maneuver on this Signature Technique. Failure to gain consent or '
        'the inability of the requested Ally to use the United Attack Maneuver '
        'results in the Signature Technique Maneuver failing – regain your '
        'Action and Ki Points spent on this Signature Technique Maneuver.',
  ),
];

/// Looks up an Advantage or Disadvantage by exact [name], or `null`.
SigModifierDef? signatureModifierByName(String name) {
  for (final m in kDbuSignatureAdvantages) {
    if (m.name == name) return m;
  }
  for (final m in kDbuSignatureDisadvantages) {
    if (m.name == name) return m;
  }
  return null;
}

/// The modifiers in a given [category] (for the category-grouped picker).
List<SigModifierDef> modifiersFor(SigModifierCategory category) {
  final source = category.isDisadvantage
      ? kDbuSignatureDisadvantages
      : kDbuSignatureAdvantages;
  return source.where((m) => m.category == category).toList();
}
