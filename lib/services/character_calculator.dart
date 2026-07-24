/// character_calculator.dart
/// ---------------------------------------------------------------------------
/// The DBU rules ENGINE. Given an immutable [Character] (raw player choices),
/// this produces every *derived* value shown on the sheet: Attribute Modifiers,
/// Skill bonuses, resource pools, Aptitudes, Saving Throws and Combat Rolls.
///
/// Nothing here is persisted — the UI calls into this on every rebuild, so the
/// numbers on screen are always consistent with the current rules. When the DBU
/// system changes a formula, this is usually the only file that changes.
///
/// FORMULA PROVENANCE
/// ------------------
/// CONFIRMED against the live rules (03 July 2026):
///   • Attribute Modifier = Attribute Score
///       (Attributes page, verbatim: "Your Attribute Modifier is equal to
///        your Attribute Score, but ... can be modified by various effects
///        and Transformations." The app doesn't model Transformations/temp
///        effects yet, so Modifier == Score for now — see `attributeModifier`.)
///   • Attribute Bonus (Skills-only) = floor(Score / 2)
///       (Skills page: "Attribute Bonus ... equal to 1/2 of the Skill's
///        assigned Attribute Score". A distinct, smaller value from the
///        Attribute Modifier above — see `attributeBonus`.)
///   • Skill Bonus = Attribute Bonus + 2 × Ranks
///       (Skills page worked example: Agility 6, 1 Rank → +5.)
///   • Max Life = 60 + 12×(PL-1) + RLM×PL + 2×Tenacity×PL
///       (Character Creation, verified against the site's Goku example:
///        Saiyan, Tenacity 4, PL1 → 60 + 3 + 8 = 71.)
///   • Max Ki = 50 + 12×(PL-1)             (Character Creation.)
///   • Max Capacity = 20 + 4×(PL-1)        (Character Creation.)
///   • Might = max(Force Modifier, Magic Modifier)   (Attributes page.)
///   • Initiative = floor(Agility Score / 2)         (Attributes page — uses
///     the raw Score, not the Modifier.)
///   • Haste = floor(Agility Modifier / 2), added to Strike   (Attributes page.)
///   • Awareness = Insight Modifier, added to Strike  (Attributes page,
///     verbatim: "Add your Insight Modifier to Strike Rolls".)
///   • Normal Speed = 2 + floor(Agility Modifier / 2); Boosted Speed =
///     Agility Modifier + 2                            (Attributes page.)
///   • Defense Value = Agility Modifier + Size adjustment × Tier of Power
///     (Attributes + Size pages.)
///   • Soak = Tenacity Modifier + Size adjustment × Tier of Power
///     (Attributes + Size pages.)
///   • Saving Throws = the governing Attribute's raw SCORE (not Modifier)
///     (Attributes page, verbatim per-throw: "The Impulsive Saving Throw
///     uses your Agility Score." / Corporeal→Tenacity / Cognitive→Insight /
///     Morale→Personality.)
///   • Strike Roll adds Haste + Awareness            (Core Rules.)
///   • Dodge Roll adds Defense Value                 (Core Rules.)
///   • Wound Roll adds the Damage Attribute Modifier: Force for
///     Physical/Energy, Magic for Magic.              (Core Rules.)
///   • Critical Target defaults to 10                (Core Rules.)
///   • Starting Karma = 2, Max Karma = 4              (Z-Souls & Karma page —
///     see `KarmaRules` in dbu_rules.dart.)
///   • ToP Extra Dice / Critical Dice / Greater Dice scale with Tier of Power
///     per the Dice Category progression                (Core Rules — see
///     `DiceRules` in dbu_rules.dart.)
///   • Super Stacks (Max 3): Muscle Penalty (-1(bT) Strike/Dodge per stack,
///     extra -1(bT) at 3 stacks), Solid Bulk (+1(bT) Soak per stack), Massive
///     Power (+Force Modifier/4 per stack to Physical/Energy Wound)
///                                                       (Core Rules.)
///   • Surgency = Force Modifier, added to the Life/Ki (not Capacity) gained
///     from any Surge (search-derived, verbatim: "Surgency is a stat where
///     you increase the amount of Life and Ki Points gained through any type
///     of Surge by your Force Modifier".)
///   • Power Surge restores floor(Max Ki/4) + Surgency Ki and
///     floor(Max Capacity/4) Capacity (worked example: Max Ki 50, Force
///     Modifier 1 → 12 + 1 = +13.)
///   • Healing Surge = its die notation (see DiceRules) + Surgency as a flat
///     addend (worked example: "2d10+1" at ToP1 with Force Modifier 1.)
///   • Soak has a minimum value of 1×Base Tier of Power  (Damage & Recovery,
///     verbatim: "You have a Minimum Soak Value of 1(bT).")
///   • Health Threshold penalty: -1×Base Tier of Power to Strike/Dodge/Wound
///     per un-passed threshold currently under (Thresholds & Conditions,
///     verbatim: "For each Health Threshold you're below that you failed the
///     Steadfast Check for, reduce your Combat Rolls by 1(bT)".) Threshold
///     fractions: Bruised <50%, Injured <25%, Critical <=10% of Max Life.
///   • Damage Calculator: Total Reduction = (Soak × Damage Category
///     multiplier, ×1.5 more on Direct Hit) + Damage Reduction (+⌈Might/4⌉ on
///     Guard); Health Reduction = max(0, Wound Roll - Total Reduction)
///                                                       (Damage & Recovery +
///     Actions & Maneuvers pages.)
///   • Custom Buffs: Total = Flat + (bT)×Base Tier of Power + (T)×Tier of
///     Power, applied to the buff's Affected Stat while Active  (old sheet's
///     Custom Buffs & Debuffs tab, reimplemented generically.)
///   • Default Resources (available to every character, unlike Talent-
///     granted Resources — see `DefaultResourceRules`): Power (max 2 stacks,
///     +1(T) to every Combat Roll and +1/4 Max Capacity per stack);
///     Diminishing Offense (-1(bT) Strike per stack); Diminishing Defense
///     (-1 flat Dodge per stack).                        (Actions & Maneuvers
///     + Attacking pages.)
///   • Combat Conditions (Thresholds & Conditions page — full catalogue of
///     18 in `kDbuConditions`, but only 4 have an automated numeric effect,
///     the rest rely on mechanics this app doesn't model — see
///     `ConditionDef` doc): Broken (-2(bT) Soak/stack), Guard Down (-2(T)
///     Dodge), Shaken (-2(T) Strike), Transfigured (-2(bT) to every Combat
///     Roll). Same additive pipeline as Custom Buffs — see
///     `conditionTotals`.
///   • States (States + Special States pages — full catalogue of 11 in
///     `kDbuStates`, but only 4 have an automated Trait, the rest rely on
///     mechanics this app doesn't model — see `StateDef` doc): Raging
///     (+L(T) Wound at Level 1+, +L(T) Soak at Level 2+, ignores Health
///     Threshold penalties at Level 3), Mindful (-L(T) Wound at Level 1+,
///     ignores Health Threshold penalties at Level 3), Undying (-1(T) to
///     every Combat Roll), Determined (ignores Health Threshold penalties).
///     Same additive pipeline as Custom Buffs/Conditions — see
///     `stateTotals` and `anyStateIgnoresHealthThresholdPenalties`.
///
/// FORMERLY BEST-EFFORT, now CONFIRMED from the offline ZIM (12 July 2026):
///   • Skill → Attribute pairings (Skills page — Concealment/Creature
///     Handling/Pilot corrected to Insight, Cooking added).
///   • Healing Surge dice = "2d10(T)" (2d10 per current Tier of Power).
///   • Massive Power rounding = down (Core Rules' global "Round Down" rule:
///     divisions round down unless stated otherwise).
///   • Critical Target floor = 7 ("You cannot, through any means, have a
///     Critical Target lower than 7") — enforced by `RollValue`.
///   • Melee Range by Size (Size page table): Nano→Large "Adjacent",
///     Enormous +1, Gigantic +3, Colossal +6 Squares — constant "Adjacent"
///     for the creation-selectable Sizes this app models.
///   • The multi-layer Apparel Penalty's counting (see `apparelPenalty`).
/// ---------------------------------------------------------------------------
library;

import 'dart:math' as math;

import '../data/accessories.dart';
import '../data/apparel.dart';
import '../data/aspects.dart';
import '../data/awakenings.dart';
import '../data/custom_species_traits.dart';
import '../data/beast_traits.dart';
import '../data/dbu_rules.dart';
import '../data/enhancements.dart';
import '../data/factor_traits.dart';
import '../data/forms.dart';
import '../data/greater_awakenings.dart';
import '../data/homebrew_registry.dart';
import '../data/super_awakenings.dart';
import '../data/race_traits.dart';
import '../data/signature_modifiers.dart';
import '../data/signature_profiles.dart';
import '../data/talents.dart';
import '../data/transformations.dart';
import '../data/unique_abilities.dart';
import '../data/weapons.dart';
import '../models/character.dart';
import '../models/homebrew.dart';

/// A computed value paired with its Critical Target (the natural die result at
/// or above which the roll scores a Critical). Displayed as e.g. "+3 (9+)".
class RollValue {
  const RollValue(this.total, {int criticalTarget = 10})
      // CONFIRMED (Core Rules, verbatim): "You cannot, through any means,
      // have a Critical Target lower than 7."
      : criticalTarget = criticalTarget < 7 ? 7 : criticalTarget;

  final int total;
  final int criticalTarget;

  /// Formats like the old sheet: "+3 (10+)".
  String get label {
    final sign = total >= 0 ? '+' : '';
    return '$sign$total ($criticalTarget+)';
  }
}

/// The result of the Damage Calculator for a single incoming hit.
class DamageResult {
  const DamageResult({required this.totalReduction, required this.healthReduction});

  final int totalReduction;
  final int healthReduction;
}

/// One assembled combat-roll line for the References tab, e.g. Strike =
/// `1d10+1d4+26 (10+)`. [total] is the flat bonus, [criticalTarget] the natural
/// result at/above which it Crits, and [expression] the full dice string of
/// everything currently rolled (base 1d10 + every ToP Extra Dice + Greater
/// Dice when active + per-Energy-Charge dice on the Wound).
/// [criticalDiceExpression] is ONLY the extra Critical Dice you add on a
/// Critical Result (e.g. "1d6"), not the whole roll again — '' below the Tier
/// that grants Critical Dice.
class AttackRollLine {
  const AttackRollLine({
    required this.total,
    required this.criticalTarget,
    required this.expression,
    required this.criticalDiceExpression,
  });

  final int total;
  final int criticalTarget;
  final String expression;
  final String criticalDiceExpression;
}

/// The computed read-out for the References tab's Attack Reference — everything
/// derived from the selected Profile/Signature + situational inputs. A pure
/// scratchpad result (nothing persists). Built by
/// `CharacterCalculator.attackReference`.
class AttackReference {
  const AttackReference({
    required this.isSignature,
    required this.foundation,
    required this.kiCost,
    required this.damageCategory,
    required this.strike,
    required this.wound,
    required this.dodge,
    required this.duel,
    required this.maxWager,
    required this.energyCharges,
    required this.topExtraDice,
    required this.greaterDice,
    required this.criticalDice,
    required this.description,
  });

  final bool isSignature;
  final SigFoundation foundation;

  /// Ki Point Cost of this attack (the Profile's, or the Signature's KP).
  final int kiCost;
  final DamageCategory? damageCategory;

  final AttackRollLine strike;
  final AttackRollLine wound;
  final AttackRollLine dodge;

  /// Duel Clash roll (higher of Force/Magic Modifier + Energy-Charge / Super-
  /// Stack / Raging-Mindful bonuses; inherits the Wound's ToP dice + Crit
  /// Target). CONFIRMED (Duel Maneuver rules).
  final AttackRollLine duel;

  /// Max Ki Wager = ½ Max Capacity. CONFIRMED.
  final int maxWager;

  final int energyCharges;
  final String topExtraDice;
  final String greaterDice;
  final String criticalDice;

  /// The Profile's / Signature's effect text, shown as the attack Description.
  final String description;
}

/// The full set of derived numbers for a character. Computed once, read many.
class DerivedCharacterStats {
  const DerivedCharacterStats({
    required this.tierOfPower,
    required this.baseTierOfPower,
    required this.attributeModifiers,
    required this.maxLife,
    required this.maxKi,
    required this.maxCapacity,
    required this.currentLife,
    required this.currentKi,
    required this.currentCapacity,
    required this.might,
    required this.mightForClashes,
    required this.stressBonus,
    required this.beingBludgeoned,
    required this.haste,
    required this.awareness,
    required this.speedNormal,
    required this.speedBoosted,
    required this.initiative,
    required this.defenseValue,
    required this.soak,
    required this.skillBonuses,
    required this.savingThrows,
    required this.strike,
    required this.dodge,
    required this.woundPhysical,
    required this.woundEnergy,
    required this.woundMagic,
    required this.healthStatus,
    required this.topExtraDice,
    required this.criticalDice,
    required this.greaterDice,
    required this.strikeDice,
    required this.dodgeDice,
    required this.woundDice,
    required this.healingSurgeDice,
    required this.powerSurgeKi,
    required this.powerSurgeCapacity,
    required this.healthThresholdPenalty,
    required this.apparelDamageReduction,
    required this.apparelPenalty,
    required this.weaponDamageReduction,
    required this.weaponPenalty,
    required this.accessoryDamageReduction,
    required this.bonusDamageReduction,
    required this.hasArmoredAspect,
  });

  final int tierOfPower;

  /// Base Tier of Power — derived purely from Power Level, unlike
  /// [tierOfPower] which could later be boosted by Transformations. The two
  /// are numerically identical until this app models Transformations.
  final int baseTierOfPower;

  /// Attribute Modifier (= Attribute Score, absent Transformations/effects
  /// this app doesn't yet model) for each Attribute.
  final Map<DbuAttribute, int> attributeModifiers;

  // Resource pools.
  final int maxLife;
  final int maxKi;
  final int maxCapacity;
  final int currentLife;
  final int currentKi;
  final int currentCapacity;

  // Aptitudes.
  final int might;

  /// Might used specifically in Might Clashes — Might plus a "Might for
  /// Clashes" Custom Buff, tracked separately from [might].
  final int mightForClashes;

  /// Stress Bonus (Power Level + Determination + buffs) — added to a Stress
  /// Test when entering/holding a Transformation. Shown on the Transformations
  /// tab.
  final int stressBonus;

  /// Whether a "I'm being Bludgeoned" Custom Buff is active — the Damage
  /// Calculator then ignores ½ of the character's Damage Reduction.
  final bool beingBludgeoned;

  final int haste;
  final int awareness;
  final int speedNormal;
  final int speedBoosted;
  final int initiative;
  final int defenseValue;
  final int soak;

  /// Skill name → RollValue (bonus + critical target). Encompassing skills key
  /// each specialty as "Skill – Specialty".
  final Map<String, RollValue> skillBonuses;

  /// Saving Throw → RollValue.
  final Map<DbuSavingThrow, RollValue> savingThrows;

  // Combat Rolls.
  final RollValue strike;
  final RollValue dodge;
  final RollValue woundPhysical;
  final RollValue woundEnergy;
  final RollValue woundMagic;

  /// Human-readable Health Threshold label (Healthy / Bruised / Injured /
  /// Critical) based on current Life vs. Max Life.
  final String healthStatus;

  // Dice pools (Core Rules — Dice Category progression, see DiceRules).
  final String topExtraDice;
  final String criticalDice;
  final String greaterDice;

  /// The full dice string actually rolled for each Combat Roll (base `1d10` +
  /// ToP Extra Dice + any Custom-Buff dice), e.g. "1d10+1d6+1d4". The Wound
  /// pool excludes situational Energy-Charge dice (those are added in the
  /// References calculator). See `CharacterCalculator.combatDicePool`.
  final String strikeDice;
  final String dodgeDice;
  final String woundDice;

  /// Healing Surge die notation, e.g. "2d10". VERIFY (see DiceRules doc).
  final String healingSurgeDice;

  /// Power Surge restores this much Ki / Capacity (⌈max/4⌉ each).
  final int powerSurgeKi;
  final int powerSurgeCapacity;

  /// Total penalty currently applied to Strike/Dodge/Wound Rolls from
  /// un-passed Health Thresholds (already folded into those RollValues).
  final int healthThresholdPenalty;

  /// Damage Reduction currently granted by worn Armor — the Damage Calculator
  /// adds this on top of any manual Damage Reduction (see `apparelDamageReduction`).
  final int apparelDamageReduction;

  /// The multi-layer Apparel Penalty currently reducing every Combat Roll
  /// (already folded into those RollValues) — surfaced for display.
  final int apparelPenalty;

  /// Damage Reduction currently granted by wielded Weapons (Warding Weapon) —
  /// the Damage Calculator adds this on top of manual/Apparel Damage Reduction.
  final int weaponDamageReduction;

  /// The Weapon Penalty currently reducing Strike Rolls (2(T) while wielding any
  /// Weapon, unless Weapon Specialist) — already folded into Strike; surfaced
  /// for display.
  final int weaponPenalty;

  /// Damage Reduction currently granted by equipped Accessories (Armored Gloves,
  /// Helmet) — the Damage Calculator adds this on top of manual/Apparel/Weapon
  /// Damage Reduction.
  final int accessoryDamageReduction;

  /// Passive Damage Reduction from the automated buffs pipeline
  /// (`AffectedStat.damageReduction` — Transformation Traits, Custom Buffs…)
  /// — the Damage Calculator adds this on top of the item-granted DRs above.
  final int bonusDamageReduction;

  /// Whether a Transformation with the Armored Aspect is in effect — the
  /// Damage Calculator then reduces incoming Damage Categories by 1.
  final bool hasArmoredAspect;
}

/// Which Combat Roll a dice-pool / dice Custom Buff applies to.
enum CombatRollScope { strike, dodge, wound }

/// Stateless helper that turns a [Character] into [DerivedCharacterStats].
abstract final class CharacterCalculator {
  /// Default Critical Target for most rolls is a natural 10.
  static const int _defaultCritTarget = 10;

  /// This system's default floor: derived stats can't go below 0 unless a
  /// specific rule states a different minimum (e.g. Soak's own 1×Base Tier
  /// of Power floor, applied separately in `soak()` before this is used).
  static int _floor0(int v) => v < 0 ? 0 : v;

  /// Attribute Modifier = Attribute Score. CONFIRMED (Attributes page:
  /// "Your Attribute Modifier is equal to your Attribute Score, but ... can
  /// be modified by various effects and Transformations"). This app doesn't
  /// yet model those temporary effects, so the Modifier simply mirrors the
  /// Score; this is the single place to add such adjustments later.
  static int attributeModifier(int score) => score;

  // ==========================================================================
  // Transformations (Attribute Modifier Bonus, Ki Multiplier, Awakening Limit)
  // ==========================================================================

  /// Resolves a Transformation name to its `TransformationDef` across all
  /// three catalogues (Awakenings / Enhancements / Alternate Forms), or
  /// `null` for an unknown/homebrew name.
  static TransformationDef? transformationByName(String name) =>
      lesserAwakeningByName(name) ??
      greaterAwakeningByName(name) ??
      superAwakeningByName(name) ??
      enhancementByName(name) ??
      alternateFormByName(name) ??
      // Player-authored Transformations resolve last (official wins a name
      // clash) — from here the whole pipeline (AMB, Traits, stacks/grades,
      // Ki Multiplier, Awakening limits) treats them like catalogue defs.
      HomebrewRegistry.transformationDefByName(name);

  /// The `TransformationDef` for each of the character's owned
  /// `TransformationSelection`s, skipping any whose name doesn't resolve
  /// (homebrew/stale) — paired with its selection so callers can read
  /// stacks/active/grade.
  static Iterable<({TransformationSelection sel, TransformationDef def})>
      ownedTransformations(Character c) sync* {
    for (final sel in c.transformations) {
      final def = transformationByName(sel.name);
      if (def != null) yield (sel: sel, def: def);
    }
  }

  /// Every Transformation Trait currently IN EFFECT, paired with its owning
  /// selection/definition — the single gating authority the trait-automation
  /// pipeline and the trait-level AMB both iterate:
  ///   • Awakening Traits are always in effect (Awakenings are always
  ///     active), gated only by their Stack requirement (`minStacks`);
  ///   • an Enhancement/Form's Traits require the Transformation to be
  ///     ACTIVE — except a Legendary Form's Legendary Trait, which is
  ///     "possess[ed] at ALL TIMES after gaining access" (always in effect);
  ///   • Mastery Traits additionally require the recorded Mastery level
  ///     (index i unlocks at masteryLevel > i);
  ///   • a Super Awakening's Grand Awakening requires its manual toggle
  ///     (`TransformationSelection.grandAwakeningActive` — the Full Awakening
  ///     Maneuver); an Enhancement's Transcendent Trait requires the
  ///     Enhancement active + its `transcended` toggle.
  /// Burst Limit and Unlimited Traits are one-shot/sub-system effects and
  /// stay text-only (never yielded here). An Exceed Trait IS yielded while
  /// its Form is active — its automation entries carry the
  /// `whileNamedStateActive('Exceed')` condition so they only contribute
  /// while an "Exceed" State is tracked.
  static Iterable<
      ({
        TransformationSelection sel,
        TransformationDef def,
        TransformationTrait trait,
      })> transformationTraitsInEffect(Character c) sync* {
    for (final owned in ownedTransformations(c)) {
      final sel = owned.sel;
      final def = owned.def;
      switch (def.type) {
        case TransformationType.awakening:
          final stacks = sel.stacks.clamp(1, def.maxStacks);
          for (final t in def.traits) {
            if (t.minStacks <= stacks) yield (sel: sel, def: def, trait: t);
          }
          for (final t in _unlockedMasteryTraits(sel, def)) {
            yield (sel: sel, def: def, trait: t);
          }
          if (sel.grandAwakeningActive && def.grandAwakening != null) {
            yield (sel: sel, def: def, trait: def.grandAwakening!);
          }
        case TransformationType.enhancement:
          if (!sel.active) break;
          for (final t in def.traits) {
            yield (sel: sel, def: def, trait: t);
          }
          for (final t in _unlockedMasteryTraits(sel, def)) {
            yield (sel: sel, def: def, trait: t);
          }
          if (sel.transcended && def.transcendentTrait != null) {
            yield (sel: sel, def: def, trait: def.transcendentTrait!);
          }
        case TransformationType.form:
          final legendary = def.legendaryTrait;
          if (legendary != null) yield (sel: sel, def: def, trait: legendary);
          if (!sel.active) break;
          for (final t in def.situationalTraits) {
            yield (sel: sel, def: def, trait: t);
          }
          final exceed = def.exceedTrait;
          if (exceed != null) yield (sel: sel, def: def, trait: exceed);
          for (final t in _unlockedMasteryTraits(sel, def)) {
            yield (sel: sel, def: def, trait: t);
          }
      }
    }
  }

  static Iterable<TransformationTrait> _unlockedMasteryTraits(
    TransformationSelection sel,
    TransformationDef def,
  ) sync* {
    if (def.masteryTrait != null && sel.masteryLevel >= 1) {
      yield def.masteryTrait!;
    }
    for (var i = 0; i < def.masteryTraits.length; i++) {
      if (sel.masteryLevel > i) yield def.masteryTraits[i];
    }
  }

  /// Every Aspect label carried by a Transformation currently in effect
  /// (Awakenings always; Enhancements/Forms while ACTIVE), resolved against
  /// the Aspects catalogue.
  /// The effective Aspect labels for one owned Transformation: its catalogue
  /// Aspects minus any the player disabled ([TransformationSelection.
  /// removedAspects]), plus any the player added ([customAspects]).
  static List<String> effectiveAspectLabels(
    TransformationDef def,
    TransformationSelection sel,
  ) {
    final removed = sel.removedAspects.toSet();
    return [
      for (final a in def.aspects)
        if (!removed.contains(a)) a,
      ...sel.customAspects,
    ];
  }

  static Iterable<ResolvedAspect> activeAspects(Character c) sync* {
    for (final o in ownedTransformations(c)) {
      final on = o.def.type == TransformationType.awakening || o.sel.active;
      if (!on) continue;
      for (final label in effectiveAspectLabels(o.def, o.sel)) {
        yield resolveAspect(label);
      }
    }
  }

  /// Whether any Transformation currently in effect carries the named Aspect.
  static bool hasActiveAspect(Character c, String name) =>
      activeAspects(c).any((r) => r.def?.name == name);

  /// Automated Aspect effects — the subset of the Aspects catalogue whose
  /// effect is a clean additive bonus to a stat this app computes, applied
  /// while the carrying Transformation is in effect (same additive pipeline
  /// as Traits):
  ///   • Enhanced Save (X): +1(T) to the bracketed Saving Throw(s)
  ///     ("Impulsive/Corporeal", "All", …).
  ///   • Raging: +2(T) Wound Rolls while in the Raging State (tracked in
  ///     the States list).
  ///   • Mindful: +1(T) Dodge Rolls while in the Mindful State (its Parry
  ///     Strike bonus is per-Maneuver — manual).
  ///   • High Speed: Speeds + the Transformation's AMB (AG); only the
  ///     highest applies across Transformations used in conjunction
  ///     (verbatim rule). Grade-set (`*`) AMBs are skipped as ever.
  /// Super Saiyan Form (Max Ki/Capacity ×1.25) is folded into
  /// [maxKi]/[maxCapacity]; Perfect Ki Control into [attackReference]'s Ki
  /// Cost; Armored into [computeDamage]. Everything else stays reference
  /// text.
  static Map<AffectedStat, int> aspectTotals(Character c) {
    final totals = <AffectedStat, int>{};
    void add(AffectedStat s, int v) => totals[s] = (totals[s] ?? 0) + v;
    final top = tierOfPower(c);
    bool stateActive(String name) {
      final target = name.toLowerCase();
      return c.states
          .any((s) => s.name.trim().toLowerCase() == target && s.stacks > 0);
    }

    var highSpeedBest = 0;
    for (final o in ownedTransformations(c)) {
      final on = o.def.type == TransformationType.awakening || o.sel.active;
      if (!on) continue;
      for (final label in effectiveAspectLabels(o.def, o.sel)) {
        final r = resolveAspect(label);
        switch (r.def?.name) {
          case 'Enhanced Save':
            for (final save in _enhancedSaveTargets(r.parameter)) {
              add(save, top);
            }
          case 'Raging':
            if (stateActive('Raging')) {
              add(AffectedStat.woundPhysical, 2 * top);
              add(AffectedStat.woundEnergy, 2 * top);
              add(AffectedStat.woundMagic, 2 * top);
            }
          case 'Mindful':
            if (stateActive('Mindful')) add(AffectedStat.dodge, top);
          case 'High Speed':
            final amb = o.def.amb[DbuAttribute.agility];
            if (amb != null && !amb.graded) {
              final v = amb.coefficient * (amb.tierScaled ? top : 1);
              if (v > highSpeedBest) highSpeedBest = v;
            }
        }
      }
    }
    if (highSpeedBest > 0) {
      add(AffectedStat.speedNormal, highSpeedBest);
      add(AffectedStat.speedBoosted, highSpeedBest);
    }
    return totals;
  }

  /// The Saving-Throw stats named by an Enhanced Save bracket parameter
  /// (e.g. "Impulsive/Corporeal", "All").
  static Iterable<AffectedStat> _enhancedSaveTargets(String? parameter) {
    if (parameter == null) return const [];
    final p = parameter.toLowerCase();
    if (p.contains('all')) {
      return const [
        AffectedStat.impulsiveSave,
        AffectedStat.cognitiveSave,
        AffectedStat.corporealSave,
        AffectedStat.moraleSave,
      ];
    }
    return [
      if (p.contains('impulsive')) AffectedStat.impulsiveSave,
      if (p.contains('cognitive')) AffectedStat.cognitiveSave,
      if (p.contains('corporeal')) AffectedStat.corporealSave,
      if (p.contains('morale')) AffectedStat.moraleSave,
    ];
  }

  /// Attribute Modifier Bonus for [attr] from all of the character's
  /// Transformations — CONFIRMED (transformation-rules, verbatim): an
  /// Awakening's AMB "is applied at all times" (× its Stacks), while an
  /// Enhancement/Form's applies only while ACTIVE. `*` (Grade-set) entries in
  /// the catalogue table are skipped (shown as text, not auto-applied), but a
  /// player's own `TransformationSelection.customAmb` for [attr] is added on
  /// top — that's how a Grade-set or "Attribute of your choice" bonus becomes
  /// live once the player fills it in. A Trait's own `ambBonus` (e.g. a Grand
  /// Awakening's Attribute Modifier increase) is added ONCE while that Trait
  /// is in effect (Traits don't repeat per Stack).
  static int transformationModifierBonus(Character c, DbuAttribute attr) {
    var total = 0;
    final top = tierOfPower(c);
    for (final owned in ownedTransformations(c)) {
      final amb = owned.def.amb[attr];
      int magnitude;
      if (amb == null) {
        magnitude = 0;
      } else if (amb.graded) {
        // Grade-table AMB (e.g. Kaioken): the coefficient at the current Grade.
        final grade = owned.sel.grade < 1 ? 1 : owned.sel.grade;
        magnitude = amb.gradePerTier.isEmpty
            ? 0
            : amb.gradePerTier[(grade - 1).clamp(0, amb.gradePerTier.length - 1)] *
                top;
      } else {
        magnitude = amb.coefficient * (amb.tierScaled ? top : 1);
      }
      magnitude += owned.sel.customAmb[attr] ?? 0;
      final awakening = owned.def.type == TransformationType.awakening;
      final inEffect = awakening || owned.sel.active;
      // Flat player-distributed AMB (e.g. Steady Progress) — added ONCE while
      // in effect, never ×Stacks (the site's "(after Stacks)" wording).
      if (inEffect) total += owned.sel.flatAmb[attr] ?? 0;
      if (magnitude == 0) continue;
      if (awakening) {
        // Always active; stacks multiply the AMB.
        total += magnitude * owned.sel.stacks.clamp(1, owned.def.maxStacks);
      } else if (owned.sel.active) {
        total += magnitude;
      }
    }
    // Trait-level AMB (in-effect Traits only, applied once — no Stack
    // multiplication) + any chosen Trait-Option AMB (e.g. an Aura Trait's
    // "Increase the AMB (…) by N(T)").
    for (final inEffect in transformationTraitsInEffect(c)) {
      final amb = inEffect.trait.ambBonus[attr];
      if (amb != null && !amb.graded) {
        total += amb.coefficient * (amb.tierScaled ? top : 1);
      }
      for (final auto in _chosenOptionsOf(
          inEffect.trait.optionGroups, inEffect.trait.name,
          inEffect.sel.optionChoices)) {
        total += (auto.ambPerTierBonus[attr] ?? 0) * top;
        total += auto.ambFlatBonus[attr] ?? 0; // flat AMB (not ×T)
      }
    }
    return total;
  }

  /// The chosen [TraitOption]s of a Transformation [trait] (including nested
  /// choices) — for the UI's automated read-out.
  static Iterable<TraitOption> chosenTraitOptions(
          TransformationTrait trait, Map<String, Set<String>> choices) =>
      _chosenOptionsOf(trait.optionGroups, trait.name, choices);

  /// Every chosen [TraitOption] of [groups] given the character's [choices],
  /// **recursing into nested Option groups** (a chosen Option's own
  /// `optionGroups`). [keyPrefix] is the trait name at the top level; nested
  /// keys extend it as `"<parentKey>::<optionName>::<nestedGroupLabel>"`,
  /// matching the UI's `_optionPicker`.
  static Iterable<TraitOption> _chosenOptionsOf(
    List<RaceTraitOptionGroup> groups,
    String keyPrefix,
    Map<String, Set<String>> choices,
  ) sync* {
    for (final group in groups) {
      final key = '$keyPrefix::${group.label}';
      final chosen = choices[key] ?? const <String>{};
      for (final option in group.options) {
        if (!chosen.contains(option.name)) continue;
        yield option;
        yield* _chosenOptionsOf(
            option.optionGroups, '$key::${option.name}', choices);
      }
    }
  }

  /// The Attribute Modifier a character's effects actually use — the raw
  /// Sum of every active Custom Buff currently targeting [channel] (resolving
  /// each buff's `CustomBuffTarget` fan-out). Used by the effective
  /// Score/Modifier/Skill helpers so an Attribute/Skill Custom Buff propagates
  /// everywhere that value is read.
  static int customBuffChannel(Character c, AffectedStat channel) {
    var total = 0;
    for (final b in c.customBuffs) {
      if (!b.active || !b.target.channels.contains(channel)) continue;
      total += customBuffTotal(c, b);
    }
    return total;
  }

  /// The total for [channel] from BOTH Custom Buffs AND Racial-Trait / Talent /
  /// Transformation-Trait (+ chosen-Option) automation. The two sources are
  /// disjoint (custom buffs live on `Character.customBuffs`; Trait automation
  /// on the catalogues), so summing them never double-counts. This lets an
  /// Option/Trait `automation` entry target the "Custom-Buff-only" channels —
  /// Skills, Ki Point Costs, Size Category, per-Foundation, dice — that plain
  /// `customBuffChannel` reads (e.g. an Evolution Trait's "+2 Stealth").
  static int channelTotal(Character c, AffectedStat channel) =>
      customBuffChannel(c, channel) + _traitAutomationChannel(c, channel);

  /// The Trait/Race/Talent/Transformation (+Option) automation contribution to
  /// [channel] — reuses the per-source total maps. Health-gated entries use the
  /// base Max Life for their threshold ratio (these channels never feed Life).
  static int _traitAutomationChannel(Character c, AffectedStat channel) {
    final mLife = maxLife(c) < 1 ? 1 : maxLife(c);
    final curLife = (c.currentLife ?? mLife).clamp(0, mLife);
    return (raceTraitTotals(c, currentLife: curLife, maxLife: mLife)[channel] ??
            0) +
        (talentTotals(c, currentLife: curLife, maxLife: mLife)[channel] ?? 0) +
        (homebrewTotals(c, currentLife: curLife, maxLife: mLife)[channel] ??
            0) +
        (transformationTraitTotals(c, currentLife: curLife, maxLife: mLife)[
                channel] ??
            0);
  }

  static AffectedStat _scoreChannel(DbuAttribute a) => switch (a) {
        DbuAttribute.agility => AffectedStat.scoreAgility,
        DbuAttribute.force => AffectedStat.scoreForce,
        DbuAttribute.tenacity => AffectedStat.scoreTenacity,
        DbuAttribute.scholarship => AffectedStat.scoreScholarship,
        DbuAttribute.insight => AffectedStat.scoreInsight,
        DbuAttribute.magic => AffectedStat.scoreMagic,
        DbuAttribute.personality => AffectedStat.scorePersonality,
      };

  static AffectedStat _modChannel(DbuAttribute a) => switch (a) {
        DbuAttribute.agility => AffectedStat.modAgility,
        DbuAttribute.force => AffectedStat.modForce,
        DbuAttribute.tenacity => AffectedStat.modTenacity,
        DbuAttribute.scholarship => AffectedStat.modScholarship,
        DbuAttribute.insight => AffectedStat.modInsight,
        DbuAttribute.magic => AffectedStat.modMagic,
        DbuAttribute.personality => AffectedStat.modPersonality,
      };

  /// Effective Attribute Score = the stored/derived Score plus any Custom Buff
  /// targeting that Attribute's Score. Feeds Skills, Initiative, Max Life
  /// (Tenacity) and — through [effectiveModifier] — every Modifier-derived
  /// value, matching the old sheet's "AG Score"/… buffs.
  static int effectiveScore(Character c, DbuAttribute attr) =>
      c.scoreOf(attr) + customBuffChannel(c, _scoreChannel(attr));

  /// Modifier (= effective Score) plus any Transformation Attribute Modifier
  /// Bonus and any Custom Buff targeting that Attribute's Modifier. This is
  /// what Aptitudes/Combat Rolls read; Saving Throws and Skill Bonuses use the
  /// effective Score instead (an AMB / Modifier buff is not a Score bonus).
  static int effectiveModifier(Character c, DbuAttribute attr) =>
      attributeModifier(effectiveScore(c, attr)) +
      transformationModifierBonus(c, attr) +
      customBuffChannel(c, _modChannel(attr));

  /// Whether the character is currently in at least one active Form —
  /// grants the Ki Multiplier (verbatim: "While you are in a Form ... your
  /// Maximum Ki Points are doubled and your Max Capacity is increased by
  /// 1/2").
  static bool hasActiveForm(Character c) => ownedTransformations(c).any(
        (o) =>
            o.def.type == TransformationType.form &&
            o.sel.active &&
            // A Null Stage (Stage 0) counts as the Normal State and does NOT
            // grant the Ki Multiplier (transformation-rules, Null Stage).
            !o.def.isNullStage,
      );

  /// How many owned Awakenings are of the given [type] (Lesser/Greater/
  /// Super) — for the UI's Awakening-Limit indicator.
  static int awakeningCount(Character c, AwakeningType type) =>
      ownedTransformations(c)
          .where((o) =>
              o.def.type == TransformationType.awakening &&
              o.def.awakeningType == type)
          .length;

  /// The character's Awakening Limits (Lesser/Greater) at their base Tier of
  /// Power — see `awakeningLimitsFor` in `data/transformations.dart`.
  static AwakeningLimits awakeningLimits(Character c) =>
      awakeningLimitsFor(baseTierOfPower(c));

  /// Attribute Bonus = floor(Score / 2). CONFIRMED, but ONLY for Skill Bonus
  /// (Skills page: "Attribute Bonus ... equal to 1/2 of the Skill's assigned
  /// Attribute Score"). This is a smaller, distinct value from the Attribute
  /// Modifier above — do not use it for Aptitudes or Combat Rolls.
  static int attributeBonus(int score) => score ~/ 2;

  /// The character's current Holding Back Stacks, clamped to the legal
  /// 0..base-Tier range (Holding Back Maneuver, verbatim: "Gain any number of
  /// Holding Back Stacks up to an amount equal to your base Tier of Power").
  static int holdingBackStacks(Character c) =>
      c.holdingBackStacks.clamp(0, baseTierOfPower(c));

  /// Total tracked stacks of the named freeform Resource. The special name
  /// 'Holding Back' also counts the dedicated [Character.holdingBackStacks]
  /// tracker, so catalogue/homebrew automations conditioned on Holding Back
  /// resolve against the sheet's own control (a manually-tracked Resource of
  /// the same name still adds, for old saves).
  static int namedResourceStacks(Character c, String name) {
    final target = name.trim().toLowerCase();
    var stacks = c.resources
        .where((r) => r.name.trim().toLowerCase() == target)
        .fold<int>(0, (sum, r) => sum + r.stacks);
    if (target == 'holding back') stacks += holdingBackStacks(c);
    return stacks;
  }

  /// Tier of Power for the character's Power Level.
  /// Current Tier of Power = Base Tier of Power plus any "ToP (Breakthrough)"
  /// Custom Buff, capped by the Tier of Power Limit ("cannot be more than 2 ToP
  /// higher than your base"), minus 1 per Holding Back Stack — CONFIRMED
  /// (Holding Back Maneuver, verbatim): "For each stack of Holding Back,
  /// reduce your Tier of Power by 1. If your number of Holding Back Stacks is
  /// equal to your base Tier of Power, ... set your Tier of Power to 1."
  /// Feeds every (T)-scaled value and the dice pools.
  static int tierOfPower(Character c) {
    final base = baseTierOfPower(c);
    final hb = holdingBackStacks(c);
    if (hb >= base) return 1;
    final bonus = topBreakthroughBonus(c);
    return ((base + bonus).clamp(1, base + 2) - hb).clamp(1, base + 2);
  }

  /// Base Tier of Power — derived purely from Power Level (unaffected by
  /// Breakthrough / (bT) effects). See `DerivedCharacterStats.baseTierOfPower`.
  static int baseTierOfPower(Character c) =>
      PowerLevelRules.tierOfPower(c.powerLevel);

  /// The temporary Tier-of-Power increase from "ToP (Breakthrough)" Custom
  /// Buffs. Computed from flat + per-Base-Tier terms only (a per-Tier term is
  /// ignored here to avoid a circular dependency on the current Tier).
  static int topBreakthroughBonus(Character c) {
    var total = 0;
    for (final b in c.customBuffs) {
      if (!b.active ||
          !b.target.channels.contains(AffectedStat.topBreakthrough)) {
        continue;
      }
      total += b.flat + b.perBaseTier * baseTierOfPower(c);
    }
    return total;
  }

  /// The Combat-Roll penalty for Holding Back at the maximum — CONFIRMED
  /// (Holding Back Maneuver, verbatim): "If your number of Holding Back
  /// Stacks is equal to your base Tier of Power, reduce your Combat Rolls by
  /// 1(bT) and set your Tier of Power to 1."
  static Map<AffectedStat, int> holdingBackTotals(Character c) {
    final base = baseTierOfPower(c);
    if (holdingBackStacks(c) < base) return const {};
    return {
      AffectedStat.strike: -base,
      AffectedStat.dodge: -base,
      AffectedStat.woundPhysical: -base,
      AffectedStat.woundEnergy: -base,
      AffectedStat.woundMagic: -base,
    };
  }

  /// The Tier of Power used for `(T)` Ki Point Costs. CONFIRMED (Core Rules,
  /// Breakthrough): "When you temporarily increase your Tier of Power, you do
  /// not increase your Ki Point Costs." → the Breakthrough increase is removed
  /// from the current Tier for KP purposes (a Breakthrough *reduction* still
  /// lowers KP).
  static int tierOfPowerForKiCost(Character c) {
    final current = tierOfPower(c);
    final increase = (current - baseTierOfPower(c)).clamp(0, 99);
    return current - increase;
  }

  /// Maximum TOTAL Skill Ranks a single Skill may have at the character's Tier
  /// of Power (verbatim): ToP1 → 2, ToP2 → 3, ToP3 → 4, ToP4+ → 5. This caps
  /// the sum of a Skill's base (racial) Ranks and every Progression Skill
  /// Improvement Rank — see `totalSkillRanks`.
  static int skillRankLimit(Character c) => (tierOfPower(c) + 1).clamp(2, 5);

  /// Maximum Attribute Score at the character's Tier of Power (verbatim):
  /// "At Tier of Power 1, your Attribute Scores cannot exceed 8. For every
  /// Tier of Power after the first, increase this limit by 3." → ToP1 8, ToP2
  /// 11, ToP3 14, … (`5 + 3 × Tier of Power`). A display/validation ceiling;
  /// `scoreOf` itself is not clamped so an over-cap choice is visible, not
  /// silently swallowed.
  static int attributeScoreLimit(Character c) => 5 + 3 * tierOfPower(c);

  /// Max Life Points.
  /// = 60 + 12×(PL-1) + RLM×PL + 2×Tenacity×PL. CONFIRMED (Goku example).
  static int maxLife(Character c) {
    final pl = c.powerLevel;
    final rlm = racialLifeModifier(c) +
        customBuffChannel(c, AffectedStat.racialLifeModifier) +
        raceTraitRacialLifeModifier(c);
    final tenacity = effectiveScore(c, DbuAttribute.tenacity);
    return 60 + 12 * (pl - 1) + rlm * pl + 2 * tenacity * pl;
  }

  /// The flat Racial-Life-Modifier bonus contributed by active Racial/Subrace/
  /// Factor Traits, their chosen Options, and selected Bestial/Monstrous Traits
  /// (e.g. Bestial Build's "+2 Racial Life Modifier", Tall Yardrat's "+3",
  /// Gigantic Demon's "+4"). Computed life-independently — every
  /// `AffectedStat.racialLifeModifier` entry is a flat, unconditional bonus, so
  /// this avoids the Max-Life recursion that `raceTraitTotals` (which needs
  /// current/Max Life) would introduce.
  static int raceTraitRacialLifeModifier(Character c) {
    var sum = 0;
    bool isRlm(RaceTraitAutomation a) =>
        a.condition == null &&
        a.kind == TraitMagnitudeKind.flat &&
        a.tierScaling == TierScaling.none &&
        a.affectedStats.contains(AffectedStat.racialLifeModifier);
    void scan(RaceTraitDef t) {
      for (final a in t.automation) {
        if (isRlm(a)) sum += a.coefficient;
      }
      for (final opt in _chosenOptionsOf(
          t.optionGroups, t.name, c.raceTraitOptionChoices)) {
        for (final a in opt.automation) {
          if (isRlm(a)) sum += a.coefficient;
        }
      }
    }

    for (final t in activeRaceTraits(c)) {
      scan(t);
    }
    for (final t in selectedBeastTraits(c)) {
      scan(t);
    }
    return sum;
  }

  /// Max Ki Pool = 50 + 12×(PL-1), DOUBLED while in an active Form (Ki
  /// Multiplier). CONFIRMED (transformation-rules: "While you are in a Form
  /// ... your Maximum Ki Points are doubled").
  static int maxKi(Character c) {
    final base = 50 + 12 * (c.powerLevel - 1);
    var total = hasActiveForm(c) ? base * 2 : base;
    // Super Saiyan Form Aspect (verbatim): "increase your Maximum Ki Points
    // and Max Capacity by 1/4 of their maximums."
    if (hasActiveAspect(c, 'Super Saiyan Form')) total += total ~/ 4;
    return total;
  }

  /// Max Capacity = 20 + 4×(PL-1), increased by 1/2 while in an active Form
  /// (Ki Multiplier). CONFIRMED ("your Max Capacity is increased by 1/2").
  static int maxCapacity(Character c) {
    final base = 20 + 4 * (c.powerLevel - 1);
    var total = hasActiveForm(c) ? base + base ~/ 2 : base;
    // Super Saiyan Form Aspect — see maxKi.
    if (hasActiveAspect(c, 'Super Saiyan Form')) total += total ~/ 4;
    return total;
  }

  /// Skill Bonus = Attribute Bonus (floor(effective Score/2)) + 2×Ranks, plus
  /// any Custom Buff targeting this Skill or its Attribute's Skill group.
  /// CONFIRMED base formula.
  static int skillBonus(Character c, SkillDef skill, {String? specialty}) {
    final score = effectiveScore(c, skill.attribute);
    final ranks = totalSkillRanks(c, skill, specialty: specialty);
    final groupChannel = _skillGroupChannel(skill.attribute);
    final skillBuff = channelTotal(c, _skillChannel(skill.name)) +
        (groupChannel == null ? 0 : channelTotal(c, groupChannel));
    // Size modifies Stealth (smaller = better) and Intimidation (larger = better).
    final sizeMod = switch (skill.name) {
      'Stealth' => sizeStealthModifier(c),
      'Intimidation' => sizeIntimidationModifier(c),
      _ => 0,
    };
    // Holding Back — CONFIRMED (verbatim): "For each stack of Holding Back
    // you possess, increase the Skill Bonus for your Concealment Skill
    // Checks by 1 (max. 3)."
    final holdingBackMod = skill.name == 'Concealment'
        ? holdingBackStacks(c).clamp(0, 3)
        : 0;
    return attributeBonus(score) + 2 * ranks + skillBuff + sizeMod +
        holdingBackMod;
  }

  static AffectedStat? _skillGroupChannel(DbuAttribute a) => switch (a) {
        DbuAttribute.agility => AffectedStat.skillGroupAgility,
        DbuAttribute.force => AffectedStat.skillGroupForce,
        DbuAttribute.scholarship => AffectedStat.skillGroupScholarship,
        DbuAttribute.insight => AffectedStat.skillGroupInsight,
        DbuAttribute.magic => AffectedStat.skillGroupMagic,
        DbuAttribute.personality => AffectedStat.skillGroupPersonality,
        DbuAttribute.tenacity => null, // no Skills use Tenacity
      };

  static const Map<String, AffectedStat> _skillChannels = {
    'Acrobatics': AffectedStat.skillAcrobatics,
    'Bluff': AffectedStat.skillBluff,
    'Clairvoyance': AffectedStat.skillClairvoyance,
    'Concealment': AffectedStat.skillConcealment,
    'Craft': AffectedStat.skillCraft,
    'Creature Handling': AffectedStat.skillCreatureHandling,
    'Intimidation': AffectedStat.skillIntimidation,
    'Intuition': AffectedStat.skillIntuition,
    'Investigation': AffectedStat.skillInvestigation,
    'Knowledge': AffectedStat.skillKnowledge,
    'Medicine': AffectedStat.skillMedicine,
    'Perception': AffectedStat.skillPerception,
    'Performance': AffectedStat.skillPerformance,
    'Persuasion': AffectedStat.skillPersuasion,
    'Pilot': AffectedStat.skillPilot,
    'Stealth': AffectedStat.skillStealth,
    'Survival': AffectedStat.skillSurvival,
    'Thievery': AffectedStat.skillThievery,
    'Use Magic': AffectedStat.skillUseMagic,
  };

  static AffectedStat _skillChannel(String name) =>
      _skillChannels[name] ?? AffectedStat.manual;

  /// Might = the higher of the Force and Magic Modifiers. CONFIRMED.
  /// (Uses effective Modifiers, so a Transformation's Attribute Modifier
  /// Bonus to Force/Magic flows into Might.)
  static int might(Character c) => math.max(
        effectiveModifier(c, DbuAttribute.force),
        effectiveModifier(c, DbuAttribute.magic),
      );

  /// Haste = floor(Agility Modifier / 2). CONFIRMED (added to Strike).
  static int haste(Character c) =>
      effectiveModifier(c, DbuAttribute.agility) ~/ 2;

  /// Initiative = floor(Agility Score / 2). CONFIRMED — uses the raw Score,
  /// not the Modifier (Attributes page: "Add 1/2 of your Agility Score"), so
  /// a Transformation's Modifier Bonus does NOT affect it.
  static int initiative(Character c) =>
      effectiveScore(c, DbuAttribute.agility) ~/ 2;

  /// Awareness = Insight Modifier, added to Strike Rolls. CONFIRMED
  /// (Attributes page, verbatim: "Add your Insight Modifier to Strike
  /// Rolls").
  static int awareness(Character c) =>
      effectiveModifier(c, DbuAttribute.insight);

  /// Normal Speed = 2 + floor(Agility Modifier / 2). CONFIRMED (Attributes
  /// page: "Your Normal Speed ... is calculated by 2+(1/2 of your Agility
  /// Modifier)").
  static int speedNormal(Character c) =>
      2 + effectiveModifier(c, DbuAttribute.agility) ~/ 2 + sizeSpeedModifier(c);

  /// Boosted Speed = Agility Modifier + 2. CONFIRMED (Attributes page:
  /// "Your Boosted Speed ... is calculated by adding 2 to your full Agility
  /// Modifier").
  static int speedBoosted(Character c) =>
      effectiveModifier(c, DbuAttribute.agility) + 2 + sizeSpeedModifier(c);

  /// Defense Value = Agility Modifier + Size adjustment × Tier of Power,
  /// floored at 0. CONFIRMED (Attributes page: "Your Defense Value is equal
  /// to your Agility Modifier"; Size page table: Small +1(T), Large -1(T),
  /// the "(T)" meaning the bonus scales with Tier of Power). The old sheet
  /// explicitly floors Defense Value at 0 *separately* from the rest of the
  /// Dodge Roll: "many effects change your Defense Value but can't bring it
  /// below 0, meaning the rest of your Dodge bonuses will be safe from
  /// penalties" — see the Dodge Roll assembly in `compute()` for the second,
  /// final floor applied after Dodge-specific bonuses/penalties.
  static int defenseValue(Character c) {
    final base = effectiveModifier(c, DbuAttribute.agility);
    return _floor0(base + _sizeDefenseAdj[effectiveSizeIndex(c)] * tierOfPower(c));
  }

  // ==== Size Category (Size page table) ==================================
  // Indices: Nano 0, Small 1, Medium 2, Large 3, Enormous 4, Gigantic 5,
  // Colossal 6. A "Size Category" Custom Buff shifts the effective index.
  static int _sizeBaseIndex(DbuSize s) => switch (s) {
        DbuSize.small => 1,
        DbuSize.medium => 2,
        DbuSize.large => 3,
      };

  /// The character's effective Size index (Nano 0 … Colossal 6), the base Size
  /// shifted by any "Size Category" Custom Buff and clamped to the table.
  static int effectiveSizeIndex(Character c) =>
      (_sizeBaseIndex(c.size) + channelTotal(c, AffectedStat.sizeCategory))
          .clamp(0, 6);

  // Size page table columns (per index above).
  static const List<int> _sizeDefenseAdj = [3, 1, 0, -1, -2, -3, -5]; // (T)
  static const List<int> _sizeSoakAdj = [-3, -1, 0, 1, 2, 3, 5]; // (T)
  static const List<int> _sizeSpeedAdj = [-6, 0, 0, 0, 3, 6, 10]; // flat

  /// Flat Speed Modifier from Size (Nano −6 … Colossal +10).
  static int sizeSpeedModifier(Character c) =>
      _sizeSpeedAdj[effectiveSizeIndex(c)];

  /// Stealth Skill modifier: +1 per Size Category below Medium, −1 per above.
  static int sizeStealthModifier(Character c) => 2 - effectiveSizeIndex(c);

  /// Intimidation Skill modifier: +1 per Size Category above Medium, −1 below.
  static int sizeIntimidationModifier(Character c) => effectiveSizeIndex(c) - 2;

  /// Whether any active Custom Buff targets [channel] (a toggle — the numeric
  /// value is irrelevant, presence marks the effect active).
  static bool hasActiveBuffTarget(Character c, AffectedStat channel) =>
      c.customBuffs.any((b) => b.active && b.target.channels.contains(channel));

  /// Determination (Attributes): Personality Score ≥ 8 → +2, ≥ 4 → +1 to the
  /// Stress Bonus.
  static int determination(Character c) {
    final pe = effectiveScore(c, DbuAttribute.personality);
    if (pe >= 8) return 2;
    if (pe >= 4) return 1;
    return 0;
  }

  /// Stress Bonus (Transformation Rules) = Power Level + Determination, plus a
  /// "Stress Bonus" Custom Buff (e.g. a Trait's "+1(bT)"). Added to a Stress
  /// Test (1d10+1) when entering/holding a Transformation.
  static int stressBonus(Character c) =>
      c.powerLevel +
      determination(c) +
      customBuffChannel(c, AffectedStat.stressBonus);

  /// Might for Clashes = Might plus a "Might for Clashes" Custom Buff — the
  /// value used specifically in Might Clashes, tracked separately from Might.
  static int mightForClashes(Character c) =>
      might(c) + customBuffChannel(c, AffectedStat.mightForClashes);

  /// Combat-Roll bonus from the Hype / Analysis Maneuvers while their toggle
  /// Custom Buff is active (Special Maneuvers): Hype = 1(T)+⌈¼ Personality
  /// Modifier⌉; Analyzed target = 1(T)+⌈¼ Scholarship Modifier⌉.
  static int maneuverCombatRollBonus(Character c) {
    var bonus = 0;
    if (hasActiveBuffTarget(c, AffectedStat.hypeManeuver)) {
      bonus += tierOfPower(c) +
          (effectiveModifier(c, DbuAttribute.personality) / 4).ceil();
    }
    if (hasActiveBuffTarget(c, AffectedStat.analysisInvestigation) ||
        hasActiveBuffTarget(c, AffectedStat.analysisIntuition)) {
      bonus += tierOfPower(c) +
          (effectiveModifier(c, DbuAttribute.scholarship) / 4).ceil();
    }
    return bonus;
  }

  /// Soak = Tenacity Modifier + Size adjustment × Tier of Power, floored at a
  /// minimum of 1×Base Tier of Power. CONFIRMED (Attributes page: "Your Soak
  /// Value is equal to your Tenacity Modifier"; Size page table: Small
  /// -1(T), Large +1(T); Damage & Recovery page, verbatim: "You have a
  /// Minimum Soak Value of 1(bT).").
  static int soak(Character c) {
    final base = effectiveModifier(c, DbuAttribute.tenacity);
    final raw = base + _sizeSoakAdj[effectiveSizeIndex(c)] * tierOfPower(c);
    return math.max(raw, baseTierOfPower(c));
  }

  /// Saving Throw value = the governing Attribute's raw SCORE (not the
  /// Modifier). CONFIRMED (Attributes page, verbatim per-throw: "The
  /// Impulsive Saving Throw uses your Agility Score.", etc — Saving Throws
  /// are explicitly listed among the mechanics unaffected by modifier-
  /// changing effects).
  static int savingThrow(Character c, DbuSavingThrow save) =>
      c.scoreOf(save.attribute);

  /// Whether the character is in a State that grants Greater Dice on Combat
  /// Rolls — the Superior or Entrusted States (CONFIRMED, States catalogue,
  /// verbatim: "Apply Greater Dice to your Combat Rolls").
  static bool stateGrantsGreaterDice(Character c) => c.states.any((s) =>
      s.stacks > 0 && (s.name == 'Superior' || s.name == 'Entrusted'));

  /// The full Extra-Dice pool rolled for a Combat Roll of [scope], including the
  /// base `1d10`: base ToP Extra Dice (with Custom-Buff Category increases and
  /// extra instances), any granted Greater Dice, and flat Extra Dice — plus, on
  /// a Wound, the Energy-Charge dice — 1d6(T) per Charge, 1d8(T) on a
  /// [signature] attack (Attacking page, verbatim: "Each Energy Charge gained
  /// increases the Wound Roll of an Attacking Maneuver by 1d6(T), or 1d8(T)
  /// if that Attacking Maneuver is a Signature Technique"; per the Core Rules
  /// a `1dX(T)` bonus multiplies the DICE COUNT by the Tier), Category-raised
  /// by the Energy Charge Dice Category buffs and
  /// [energyChargeCategoryBonus] (the Super Beam Super Profile) — and, for a
  /// [signature] attack, the Signature-only dice channels.
  /// [greaterDiceActive] adds one Greater Die (the References toggle).
  /// CONFIRMED against the Core Rules Dice section.
  static DicePool combatDicePool(
    Character c,
    CombatRollScope scope, {
    int energyCharges = 0,
    int energyChargeCategoryBonus = 0,
    bool greaterDiceActive = false,
    bool signature = false,
  }) {
    final top = tierOfPower(c);
    final catLimit = baseTierOfPower(c) + 1; // Category Increase Limit
    int ch(AffectedStat a) => customBuffChannel(c, a);

    // Scoped channels (added on top of the "All" channels).
    final scopedTopCat = switch (scope) {
      CombatRollScope.strike => AffectedStat.topDiceCategoryStrike,
      CombatRollScope.dodge => AffectedStat.topDiceCategoryDodge,
      CombatRollScope.wound => AffectedStat.topDiceCategoryWound,
    };
    final scopedExtraTop = switch (scope) {
      CombatRollScope.strike => AffectedStat.extraTopDiceStrike,
      CombatRollScope.dodge => AffectedStat.extraTopDiceDodge,
      CombatRollScope.wound => AffectedStat.extraTopDiceWound,
    };
    final scopedGreater = switch (scope) {
      CombatRollScope.strike => AffectedStat.greaterDiceStrike,
      CombatRollScope.dodge => AffectedStat.greaterDiceDodge,
      CombatRollScope.wound => AffectedStat.greaterDiceWound,
    };
    final (fd4, fd6, fd8, fd10) = switch (scope) {
      CombatRollScope.strike => (
          AffectedStat.flatD4Strike,
          AffectedStat.flatD6Strike,
          AffectedStat.flatD8Strike,
          AffectedStat.flatD10Strike
        ),
      CombatRollScope.dodge => (
          AffectedStat.flatD4Dodge,
          AffectedStat.flatD6Dodge,
          AffectedStat.flatD8Dodge,
          AffectedStat.flatD10Dodge
        ),
      CombatRollScope.wound => (
          AffectedStat.flatD4Wound,
          AffectedStat.flatD6Wound,
          AffectedStat.flatD8Wound,
          AffectedStat.flatD10Wound
        ),
    };

    final pool = DicePool()..addDie(10, 1); // Base Die

    // Tier of Power Extra Dice: index (top-2) raised by Category buffs, with an
    // optional extra instance (capped at +1 by the ToP Limit).
    final topCatInc =
        (ch(AffectedStat.topDiceCategoryAll) + ch(scopedTopCat)).clamp(0, catLimit);
    final topIndex = (top - 2) + topCatInc;
    final extraInstances =
        (ch(AffectedStat.extraTopDiceAll) + ch(scopedExtraTop)).clamp(0, 1);
    for (var i = 0; i < 1 + extraInstances; i++) {
      pool.addCategory(topIndex);
    }

    // Energy Charges (Wound only): 1d6(T) per Charge — 1d8(T) on a Signature
    // Technique — i.e. `top` dice of the Charge's Category per Charge (the
    // Core Rules: "If you see a bonus of 1d6(T), it's a bonus of 1d6 at Tier
    // of Power 1, 2d6 at Tier of Power 2 and 3d6 at Tier of Power 3").
    // Category index 1 = 1d6, 2 = 1d8; raised by the Energy Charge Dice
    // Category buffs + Super Beam (uncapped — the Category Increase Limit
    // explicitly excepts Energy Charges).
    if (scope == CombatRollScope.wound && energyCharges > 0) {
      final ecIndex = (signature ? 2 : 1) +
          energyChargeCategoryBonus +
          ch(AffectedStat.energyChargeDiceCategory) +
          (signature ? ch(AffectedStat.signatureEnergyChargeDiceCategory) : 0);
      for (var i = 0; i < energyCharges * top; i++) {
        pool.addCategory(ecIndex);
      }
    }

    // Greater Dice (index top-1, raised by the Greater Dice Category buff).
    final greaterCatInc =
        ch(AffectedStat.greaterDiceCategory).clamp(0, catLimit);
    // The Superior and Entrusted States "Apply Greater Dice to your Combat
    // Rolls" (CONFIRMED, States catalogue) — automated here from the tracked
    // State, in addition to Greater-Dice Custom Buffs and the References toggle.
    final stateGreater = stateGrantsGreaterDice(c) ? 1 : 0;
    final greaterCount = ch(AffectedStat.greaterDiceAll) +
        ch(scopedGreater) +
        stateGreater +
        (greaterDiceActive ? 1 : 0);
    for (var i = 0; i < greaterCount; i++) {
      pool.addCategory((top - 1) + greaterCatInc);
    }

    // Flat Extra Dice by size.
    pool.addDie(4, ch(AffectedStat.flatD4All) + ch(fd4));
    pool.addDie(6, ch(AffectedStat.flatD6All) + ch(fd6));
    pool.addDie(8, ch(AffectedStat.flatD8All) + ch(fd8));
    pool.addDie(10, ch(AffectedStat.flatD10All) + ch(fd10));

    // Signature-only dice (Strike/Wound scopes of a referenced Signature).
    if (signature && scope != CombatRollScope.dodge) {
      final sExtra = switch (scope) {
        CombatRollScope.wound => AffectedStat.signatureExtraTopWound,
        _ => AffectedStat.signatureExtraTopStrike,
      };
      final (sd4, sd6, sd8, sd10) = switch (scope) {
        CombatRollScope.wound => (
            AffectedStat.signatureFlatD4Wound,
            AffectedStat.signatureFlatD6Wound,
            AffectedStat.signatureFlatD8Wound,
            AffectedStat.signatureFlatD10Wound
          ),
        _ => (
            AffectedStat.signatureFlatD4Strike,
            AffectedStat.signatureFlatD6Strike,
            AffectedStat.signatureFlatD8Strike,
            AffectedStat.signatureFlatD10Strike
          ),
      };
      final sigExtra = ch(AffectedStat.signatureExtraTopAll) + ch(sExtra);
      for (var i = 0; i < sigExtra; i++) {
        pool.addCategory(topIndex);
      }
      pool.addDie(4, ch(AffectedStat.signatureFlatD4All) + ch(sd4));
      pool.addDie(6, ch(AffectedStat.signatureFlatD6All) + ch(sd6));
      pool.addDie(8, ch(AffectedStat.signatureFlatD8All) + ch(sd8));
      pool.addDie(10, ch(AffectedStat.signatureFlatD10All) + ch(sd10));
    }

    return pool;
  }

  /// Health Threshold label. CONFIRMED fractions (Thresholds & Conditions
  /// page, verbatim): Bruised "1/2 ~ 1/4 Maximum Life Points", Injured
  /// "1/4 ~ 1/10", Critical "1/10>=".
  static String healthStatus(int currentLife, int maxLife) {
    if (maxLife <= 0) return 'Healthy';
    final ratio = currentLife / maxLife;
    if (currentLife <= 0) return 'Defeated';
    if (ratio <= 0.10) return 'Critical';
    if (ratio < 0.25) return 'Injured';
    if (ratio < 0.50) return 'Bruised';
    return 'Healthy';
  }

  /// Total Combat Roll penalty from un-passed Health Thresholds. CONFIRMED
  /// (verbatim): "For each Health Threshold you're below that you failed the
  /// Steadfast Check for, reduce your Combat Rolls by 1(bT)." Thresholds are
  /// cumulative — being Critical also counts as being under Injured/Bruised.
  static int healthThresholdPenalty(Character c, int currentLife, int maxLife) {
    if (maxLife <= 0) return 0;
    final ratio = currentLife / maxLife;
    var count = 0;
    if (ratio < 0.50 && !c.bruisedSteadfastPassed) count++;
    if (ratio < 0.25 && !c.injuredSteadfastPassed) count++;
    if (ratio <= 0.10 && !c.criticalSteadfastPassed) count++;
    return count * baseTierOfPower(c);
  }

  /// ToP Extra Dice label, e.g. "–" or "+1d10+1d4". CONFIRMED (see DiceRules).
  static String topExtraDice(Character c) =>
      DiceRules.extraDiceLabel(tierOfPower(c));

  /// Critical Dice label, e.g. "+1d6". CONFIRMED (see DiceRules).
  static String criticalDice(Character c) =>
      DiceRules.criticalDiceLabel(tierOfPower(c));

  /// Greater Dice label, e.g. "+1d4". CONFIRMED (see DiceRules).
  static String greaterDice(Character c) =>
      DiceRules.greaterDiceLabel(tierOfPower(c));

  /// Surgency = Force Modifier, added to the Life/Ki (NOT Capacity) restored
  /// by any Surge. CONFIRMED (search-derived, verbatim: "Surgency is a stat
  /// where you increase the amount of Life and Ki Points gained through any
  /// type of Surge by your Force Modifier").
  ///
  /// The Warlock Lesser Awakening's Master of Magic Trait (verbatim: "You
  /// may use your Magic Modifier instead of your Force Modifier when
  /// calculating Surgency") is automated by name, like Weapon Specialist —
  /// the higher of the two Modifiers is used, since "may" always favours it.
  static int surgency(Character c) {
    final force = effectiveModifier(c, DbuAttribute.force);
    // Evil Incarnate (Janemba): use your HIGHEST Attribute Modifier.
    if (janembaFormActive(c)) {
      return DbuAttribute.values
          .map((a) => effectiveModifier(c, a))
          .reduce(math.max);
    }
    // Warlock, or Arcane Adept (Custom Species, Twinned): use Magic if higher.
    if (ownedTransformations(c).any((o) => o.def.name == 'Warlock') ||
        _hasPrimaryCustomTrait(c, 'Arcane Adept')) {
      return math.max(force, effectiveModifier(c, DbuAttribute.magic));
    }
    return force;
  }

  /// Healing Surge die notation + Surgency as a flat addend, e.g. "2d10+1".
  /// The dice part is VERIFY (see DiceRules); the "+Surgency" suffix is
  /// CONFIRMED (old-sheet worked example: "2d10+1" with Force Modifier 1).
  /// [surgencyBonus] carries any automated `AffectedStat.surgency` buffs
  /// (compute() passes the pipeline total).
  static String healingSurgeDice(Character c, {int surgencyBonus = 0}) {
    final dice = DiceRules.healingSurgeLabel(tierOfPower(c));
    final s = surgency(c) + surgencyBonus;
    return s == 0 ? dice : '$dice+$s';
  }

  /// Power Surge Ki restored = floor(Max Ki / 4) + Surgency. CONFIRMED
  /// (old-sheet worked example: Max Ki 50, Force Modifier 1 → 12 + 1 = +13).
  /// [surgencyBonus] as in [healingSurgeDice]; [buffedMaxKi] lets compute()
  /// pass the pipeline-buffed Max Ki so automated Max-Ki bonuses raise the
  /// Surge too.
  static int powerSurgeKi(Character c,
          {int surgencyBonus = 0, int? buffedMaxKi}) =>
      (buffedMaxKi ?? maxKi(c)) ~/ 4 + surgency(c) + surgencyBonus;

  /// Power Surge Capacity restored = floor(Max Capacity / 4). Surgency does
  /// NOT apply here — it's scoped to "Life and Ki Points" only.
  static int powerSurgeCapacity(Character c) => maxCapacity(c) ~/ 4;

  /// Effective Super Stacks for the BONUS effects (Solid Bulk, Massive Power,
  /// Duel) — the tracked stacks plus "Super Stacks" and "Power Burst S. Stacks"
  /// Custom Buffs.
  static int effectiveSuperStacksBonus(Character c) =>
      c.superStacks +
      customBuffChannel(c, AffectedStat.superStacks) +
      customBuffChannel(c, AffectedStat.powerBurstSuperStacks);

  /// Effective Super Stacks for the Muscle Penalty — the tracked stacks plus
  /// "Super Stacks" (NOT Power Burst stacks, which don't incur the penalty),
  /// or 0 while a "No Super Stack Pen." Custom Buff is active.
  static int effectiveSuperStacksPenalty(Character c) {
    if (customBuffChannel(c, AffectedStat.noSuperStackPenalty) > 0) return 0;
    return c.superStacks + customBuffChannel(c, AffectedStat.superStacks);
  }

  /// Super Stack "Muscle Penalty": -1(bT) to Strike/Dodge per stack, an
  /// extra -1(bT) if at the max of 3 stacks. CONFIRMED (verbatim, see file
  /// header). Returned as a positive magnitude to subtract from rolls.
  static int superStackMusclePenalty(Character c) {
    final stacks = effectiveSuperStacksPenalty(c);
    if (stacks <= 0) return 0;
    final extra = stacks >= CapacityRules.maxSuperStacks ? 1 : 0;
    return (stacks + extra) * baseTierOfPower(c);
  }

  /// Super Stack "Solid Bulk": +1(bT) Soak per stack. CONFIRMED.
  static int superStackSolidBulk(Character c) =>
      effectiveSuperStacksBonus(c) * baseTierOfPower(c);

  /// Super Stack "Massive Power": +Force Modifier/4 to Physical/Energy Wound
  /// per stack. CONFIRMED, incl. the flooring (Core Rules' global "Round
  /// Down" rule: divisions round down unless stated otherwise).
  static int superStackMassivePower(Character c) {
    final forceMod = attributeModifier(c.scoreOf(DbuAttribute.force));
    return effectiveSuperStacksBonus(c) * (forceMod ~/ 4);
  }

  /// Power Resource: +1(T) to every Combat Roll (Strike/Dodge/Wound) per
  /// stack. CONFIRMED (Power Up Maneuver, verbatim: "For each stack of
  /// Power, increase your Combat Rolls by 1(T)").
  static int powerCombatRollBonus(Character c) =>
      c.powerStacks * tierOfPower(c);

  /// Power Resource: +1/4 of the (unbuffed) Max Capacity per stack.
  /// CONFIRMED (Power Up Maneuver, verbatim: "your Max Capacity by 1/4 (this
  /// increase ... only applies for the first 2 stacks of Power)" — the cap
  /// of 2 stacks is already enforced by `DefaultResourceRules.maxPowerStacks`).
  static int powerMaxCapacityBonus(Character c) =>
      c.powerStacks * (maxCapacity(c) ~/ 4);

  /// Diminishing Offense: -1(bT) to Strike Rolls per stack. CONFIRMED
  /// (Attacking page, verbatim: "Each stack ... reduces the Strike Rolls of
  /// your Attacking Maneuvers by 1(bT)"). Stacks reset at the end of each
  /// Combat Round (not automated here — purely player-tracked).
  static int diminishingOffensePenalty(Character c) =>
      c.diminishingOffenseStacks * baseTierOfPower(c);

  /// Diminishing Defense: -1 FLAT (not Tier-scaled) to the Dodge Roll per
  /// stack. CONFIRMED (Attacking page, verbatim: "each stack ... reduces the
  /// Dice Score of your Dodge Rolls by 1"). Stacks reset at the start of
  /// each Combat Round (not automated here).
  static int diminishingDefensePenalty(Character c) =>
      c.diminishingDefenseStacks;

  /// How many Diminishing Defense stacks this character gains each time
  /// they're hit, per the confirmed Base-Tier-of-Power table (see
  /// `DefaultResourceRules`). Informational only — see that class's doc.
  static int diminishingDefenseStacksPerHit(Character c) =>
      DefaultResourceRules.diminishingDefenseStacksPerHit(baseTierOfPower(c));

  /// Total bonus/penalty a single active Custom Buff currently contributes:
  /// Flat + (bT)×Base Tier of Power + (T)×Tier of Power. Inactive buffs
  /// contribute 0. CONFIRMED (old sheet's Custom Buffs & Debuffs tab).
  static int customBuffTotal(Character c, CustomBuff buff) {
    if (!buff.active) return 0;
    return buff.flat +
        buff.perBaseTier * baseTierOfPower(c) +
        buff.perTier * tierOfPower(c);
  }

  /// Sums every active Custom Buff's total per atomic Affected Stat channel,
  /// resolving each buff's `CustomBuffTarget` into its `channels` (a fan-out —
  /// e.g. "Combat Rolls" contributes to Strike + Dodge + all Wounds).
  static Map<AffectedStat, int> customBuffTotals(Character c) {
    final totals = <AffectedStat, int>{};
    for (final buff in c.customBuffs) {
      final total = customBuffTotal(c, buff);
      if (total == 0) continue;
      for (final channel in buff.target.channels) {
        totals[channel] = (totals[channel] ?? 0) + total;
      }
    }
    return totals;
  }

  /// Total per-stack penalty a single tracked Condition currently
  /// contributes, for the small set of Conditions whose effect is
  /// automated (see `ConditionDef.isAutomated`). Unrecognized/custom
  /// Condition names and non-automated official ones return 0.
  static int conditionPenalty(Character c, TrackedEntry entry) {
    final def = HomebrewRegistry.resolveConditionDef(entry.name);
    if (def == null || !def.isAutomated || entry.stacks <= 0) return 0;
    final scale = switch (def.tierScaling) {
      TierScaling.none => 1,
      TierScaling.current => tierOfPower(c),
      TierScaling.base => baseTierOfPower(c),
    };
    return def.magnitudePerStack * entry.stacks * scale;
  }

  /// Sums every tracked Condition's automated penalty per Affected Stat
  /// (as a negative contribution, since Conditions only penalize).
  static Map<AffectedStat, int> conditionTotals(Character c) {
    final totals = <AffectedStat, int>{};
    for (final entry in c.conditions) {
      final def = HomebrewRegistry.resolveConditionDef(entry.name);
      if (def == null || !def.isAutomated) continue;
      final penalty = conditionPenalty(c, entry);
      if (penalty == 0) continue;
      for (final stat in def.affectedStats) {
        totals[stat] = (totals[stat] ?? 0) - penalty;
      }
    }
    return totals;
  }

  /// Per-Affected-Stat contribution of a single tracked State at its current
  /// Level (`entry.stacks`), summing every unlocked Trait (Level <= current
  /// Level — CONFIRMED: "you have access to all of the State Traits equal
  /// to or less than the State's current Level", each evaluated with L =
  /// the CURRENT Level, not the Level it unlocked at). Unlike Conditions,
  /// the sign lives in `StateTraitDef.coefficientPerLevel` (States can buff
  /// as often as they debuff), so this is added directly, not subtracted.
  static Map<AffectedStat, int> statePerStatEffect(
      Character c, TrackedEntry entry) {
    final result = <AffectedStat, int>{};
    final def = HomebrewRegistry.resolveStateDef(entry.name);
    if (def == null || entry.stacks <= 0) return result;
    final level = entry.stacks;
    for (final trait in def.traits) {
      if (trait.level > level || trait.affectedStats.isEmpty) continue;
      final scale = switch (trait.tierScaling) {
        TierScaling.none => 1,
        TierScaling.current => tierOfPower(c),
        TierScaling.base => baseTierOfPower(c),
      };
      final magnitude = trait.coefficientPerLevel * level * scale;
      for (final stat in trait.affectedStats) {
        result[stat] = (result[stat] ?? 0) + magnitude;
      }
    }
    return result;
  }

  /// Sums every tracked State's automated per-stat effect (see
  /// `statePerStatEffect`) across all currently-tracked States.
  static Map<AffectedStat, int> stateTotals(Character c) {
    final totals = <AffectedStat, int>{};
    for (final entry in c.states) {
      statePerStatEffect(c, entry).forEach((stat, v) {
        totals[stat] = (totals[stat] ?? 0) + v;
      });
    }
    return totals;
  }

  /// Whether a single tracked State entry, at its current Level, has an
  /// unlocked Trait that nullifies Health Threshold penalties outright
  /// (Raging/Apoplectic, Mindful/Tranquil, Determined — see
  /// `StateTraitDef.ignoresHealthThresholdPenalties`).
  static bool stateIgnoresHealthThresholdPenalties(
      Character c, TrackedEntry entry) {
    final def = HomebrewRegistry.resolveStateDef(entry.name);
    if (def == null || entry.stacks <= 0) return false;
    final level = entry.stacks;
    return def.traits
        .any((t) => t.level <= level && t.ignoresHealthThresholdPenalties);
  }

  /// Whether ANY currently-tracked State ignores Health Threshold penalties
  /// (see `stateIgnoresHealthThresholdPenalties`).
  static bool anyStateIgnoresHealthThresholdPenalties(Character c) =>
      c.states.any((entry) => stateIgnoresHealthThresholdPenalties(c, entry));

  // ==========================================================================
  // Apparel (Inventory page — structured, automated; see data/apparel.dart)
  // ==========================================================================

  /// The effective Craftsmanship Grade of a piece. Natural Armor derives it
  /// from the wearer's base Tier of Power (max. 5) — CONFIRMED (verbatim:
  /// "The Craftsmanship Grade is equal to the base Tier of Power of that
  /// character (max. 5)."); every other piece uses its stored Grade.
  static int effectiveCraftGrade(Character c, ApparelPiece piece) =>
      piece.isNaturalArmor
          ? baseTierOfPower(c).clamp(1, kCraftsmanshipGrades.length)
          : piece.craftsmanshipGrade;

  /// The Apparel Grade (Low/Standard/High) of a piece, from its (effective)
  /// Craftsmanship Grade (see `craftsmanshipInfo` / [effectiveCraftGrade]).
  static ApparelGrade apparelGrade(Character c, ApparelPiece piece) =>
      craftsmanshipInfo(effectiveCraftGrade(c, piece)).apparelGrade;

  /// How many Quality Slots a piece has (from its effective Craftsmanship
  /// Grade). CONFIRMED: Natural Armor "naturally possesses no Qualities, but
  /// can gain them through effects" — its Slots come from the derived Grade.
  static int apparelQualitySlots(Character c, ApparelPiece piece) =>
      craftsmanshipInfo(effectiveCraftGrade(c, piece)).qualitySlots;

  /// How many Quality Slots the piece's chosen Qualities currently occupy.
  static int apparelQualitySlotsUsed(ApparelPiece piece) => piece.qualities
      .fold<int>(0, (sum, q) => sum + (q.slots < 1 ? 1 : q.slots));

  /// The resolved `ApparelQualityDef`s on a piece (skipping unknown/stale
  /// names), paired with the player's selection.
  static Iterable<({ApparelQualitySelection sel, ApparelQualityDef def})>
      apparelQualityDefs(ApparelPiece piece) sync* {
    for (final sel in piece.qualities) {
      final def = HomebrewRegistry.resolveApparelQuality(sel.name);
      if (def != null) yield (sel: sel, def: def);
    }
  }

  /// The piece's Apparel Bonus = its Grade's `x(bT)` (plus any Quality that
  /// raises the Apparel Bonus, e.g. Dense Armor / Divine Apparel +1(bT)),
  /// × Base Tier of Power. CONFIRMED (verbatim Apparel Grade table).
  static int apparelBonus(Character c, ApparelPiece piece) {
    var perBaseTier = apparelGrade(c, piece).bonusPerBaseTier;
    for (final q in apparelQualityDefs(piece)) {
      perBaseTier += q.def.automation?.apparelBonusPerBaseTier ?? 0;
    }
    if (piece.isNaturalArmor) {
      perBaseTier += naturalArmorBonusPerBaseTier(c);
    }
    return perBaseTier * baseTierOfPower(c);
  }

  /// Extra Apparel Bonus (in multiples of base Tier of Power) that active
  /// effects add to the wearer's Natural Armor. Currently the "Natural Apparel"
  /// Awakening Trait (on the "Adjusted Armor" Lesser Awakening), effect (2):
  /// "Increase the Apparel Bonus of your Natural Armor by 1(bT)." Awakenings
  /// are always in effect (see `transformationTraitsInEffect`), so owning the
  /// Awakening applies the bonus; multiple sources sum. Applied only to Natural
  /// Armor pieces (see `apparelBonus`).
  static int naturalArmorBonusPerBaseTier(Character c) {
    var perBaseTier = 0;
    for (final e in transformationTraitsInEffect(c)) {
      if (e.trait.name == 'Natural Apparel') perBaseTier += 1;
    }
    return perBaseTier;
  }

  /// The piece's maximum Break Value: default 3, +3 per Durable-style Quality.
  /// CONFIRMED (verbatim: default Break Value of 3; Durable +3).
  static int apparelMaxBreakValue(ApparelPiece piece) {
    var max = kDefaultApparelBreakValue;
    for (final q in apparelQualityDefs(piece)) {
      max += q.def.automation?.breakValueBonus ?? 0;
    }
    return max;
  }

  /// Whether any Quality makes the piece's Break Value un-reducible
  /// (Unbreakable).
  static bool apparelIsUnbreakable(ApparelPiece piece) => apparelQualityDefs(piece)
      .any((q) => q.def.automation?.unbreakable ?? false);

  /// Whether a piece is currently granting its benefits — it must be worn and
  /// not broken (Break Value > 0). CONFIRMED (verbatim: a broken piece "no
  /// longer fully functions"; the sheet marks unworn/broken Apparel
  /// "(inactive)"). Natural Armor is Integrated (always on the body) and fully
  /// repaired at the end of each Combat Encounter, so it never needs to be
  /// "worn" — it is Active whenever it is not currently broken.
  static bool apparelIsActive(ApparelPiece piece) =>
      piece.breakValue > 0 && (piece.isNaturalArmor || piece.worn);

  /// Whether a worn piece counts toward the Apparel Penalty — Standard
  /// Clothing never does, nor does a piece with Lightweight / Sleek Design.
  /// Natural Armor "does not count as equipped Apparel for any of your effects"
  /// (verbatim), so it never contributes to (nor consumes the free first slot
  /// of) the Apparel Penalty. CONFIRMED (verbatim).
  static bool _apparelCountsTowardPenalty(ApparelPiece piece) {
    if (piece.isNaturalArmor) return false;
    if (piece.category == ApparelCategory.standardClothing) return false;
    for (final q in apparelQualityDefs(piece)) {
      if (q.def.automation?.excludedFromApparelPenalty ?? false) return false;
    }
    return true;
  }

  /// Apparel Penalty: for each worn piece after the first, reduce every Combat
  /// Roll by ⌈Base Tier of Power / 2⌉. CONFIRMED (verbatim: "For each piece
  /// of Apparel you are wearing after the first, reduce your Combat Rolls by
  /// 1/2 of your base Tier of Power (rounded up)."). Penalty-excluded pieces
  /// are removed from the count entirely — the exclusion Qualities read
  /// "does not count towards the Apparel Penalty" (Sleek Design, verbatim),
  /// so an excluded piece never consumes the free "first" slot either;
  /// Standard Clothing's "does not inflict Apparel Penalties" is treated the
  /// same way.
  static int apparelPenalty(Character c) {
    final counting = effectiveApparel(c)
        .where((p) => apparelIsActive(p) && _apparelCountsTowardPenalty(p))
        .length;
    if (counting <= 1) return 0;
    final perExtra = (baseTierOfPower(c) + 1) ~/ 2; // ⌈baseTop / 2⌉
    return (counting - 1) * perExtra;
  }

  /// The Battle Uniforms currently in effect — one synthesized [ApparelPiece]
  /// per owned Transformation that carries the "Battle Uniform" Aspect and is
  /// in effect (an Awakening always, or an active Enhancement/Form). Each is a
  /// worn, Top-Layer piece with the implicit Stretching Quality plus its
  /// automatable Qualities. Enhancement-sourced uniforms are returned first, so
  /// callers can honour the verbatim priority rule ("apply the Grade and
  /// Category from the non-Transcended Enhancement's Battle Uniform").
  static List<ApparelPiece> _activeBattleUniforms(Character c) {
    final enh = <ApparelPiece>[];
    final other = <ApparelPiece>[];
    for (final o in ownedTransformations(c)) {
      final inEffect =
          o.def.type == TransformationType.awakening || o.sel.active;
      if (!inEffect) continue;
      final bu = o.def.battleUniform;
      if (bu == null) continue;
      final piece = ApparelPiece(
        name: '${o.def.name} Battle Uniform',
        category: bu.category,
        craftsmanshipGrade: bu.craftsmanshipGrade,
        worn: true,
        layer: WornLayer.top,
        qualities: [
          ApparelQualitySelection(name: 'Stretching'),
          for (final q in bu.qualityNames) ApparelQualitySelection(name: q),
        ],
      );
      (o.def.type == TransformationType.enhancement ? enh : other).add(piece);
    }
    return [...enh, ...other];
  }

  /// The Apparel the calculator actually scores. While a Battle Uniform is in
  /// effect you "lose access to your current Apparel" (Battle Uniform Aspect),
  /// so the manual [Character.apparel] is replaced by the single active Battle
  /// Uniform (only one Grade/Category applies at a time — an Enhancement's
  /// takes priority over a Form's/Transcended Enhancement's). Natural Armor is
  /// integrated into the body and is kept. When no Battle Uniform is active,
  /// this is just [Character.apparel].
  static List<ApparelPiece> effectiveApparel(Character c) {
    final bus = _activeBattleUniforms(c);
    if (bus.isEmpty) return c.apparel;
    return [
      ...c.apparel.where((p) => p.isNaturalArmor),
      bus.first,
    ];
  }

  /// The Battle Uniform(s) currently in effect, each paired with the name of
  /// the Transformation granting it — for display. The calculator auto-equips
  /// the highest-priority one (see [effectiveApparel]); when more than one is
  /// listed, only the first actually applies its Grade/Category.
  static Iterable<({String source, BattleUniformDef uniform})>
      activeBattleUniforms(Character c) sync* {
    for (final o in ownedTransformations(c)) {
      final inEffect =
          o.def.type == TransformationType.awakening || o.sel.active;
      if (!inEffect) continue;
      final bu = o.def.battleUniform;
      if (bu != null) yield (source: o.def.name, uniform: bu);
    }
  }

  /// Total Damage Reduction granted by worn Armor. CONFIRMED (verbatim: "Armor.
  /// Gain Damage Reduction equal to the Apparel Bonus" while it's the Top Layer;
  /// Sleek Design halves it). Feeds the Damage Calculator.
  static int apparelDamageReduction(Character c) {
    var total = 0;
    for (final piece in effectiveApparel(c)) {
      if (!apparelIsActive(piece) || piece.category != ApparelCategory.armor) {
        continue;
      }
      // Worn Armor only grants its Damage Reduction as the Top Layer; Natural
      // Armor is Integrated (Bottom Layer) yet still grants it (its whole
      // purpose), so it is exempt from the Top-Layer requirement.
      if (!piece.isNaturalArmor && piece.layer != WornLayer.top) continue;
      var dr = apparelBonus(c, piece);
      final halves = apparelQualityDefs(piece)
          .any((q) => q.def.automation?.halvesArmorDamageReduction ?? false);
      if (halves) dr ~/= 2;
      total += dr;
    }
    return total;
  }

  /// Every worn piece's automated effect, per Affected Stat: the Category
  /// benefit (Weights → −Apparel Bonus to Combat Rolls; Combat Clothing (Top
  /// Layer) → +⌈Apparel Bonus / 2⌉ Defense Value; Armor's Damage Reduction is
  /// handled separately by `apparelDamageReduction`), each Quality's automated
  /// stat effects, and the multi-layer Apparel Penalty. Same additive pipeline
  /// as Custom Buffs/Conditions/States.
  static Map<AffectedStat, int> apparelTotals(Character c) {
    final totals = <AffectedStat, int>{};
    void add(AffectedStat stat, int v) {
      if (v != 0) totals[stat] = (totals[stat] ?? 0) + v;
    }

    const combatRolls = [
      AffectedStat.strike,
      AffectedStat.dodge,
      AffectedStat.woundPhysical,
      AffectedStat.woundEnergy,
      AffectedStat.woundMagic,
    ];

    for (final piece in effectiveApparel(c)) {
      if (!apparelIsActive(piece)) continue;
      final bonus = apparelBonus(c, piece);

      // Category benefit.
      switch (piece.category) {
        case ApparelCategory.weights:
          for (final s in combatRolls) {
            add(s, -bonus);
          }
        case ApparelCategory.combatClothing:
          if (piece.layer == WornLayer.top) {
            add(AffectedStat.defenseValue, (bonus + 1) ~/ 2);
          }
        case ApparelCategory.armor:
        case ApparelCategory.standardClothing:
          break; // Armor DR handled separately; Standard Clothing has none.
      }

      // Automated Quality effects.
      for (final q in apparelQualityDefs(piece)) {
        final auto = q.def.automation;
        if (auto == null) continue;
        for (final effect in auto.statEffects) {
          final magnitude = effect.coefficient *
              switch (effect.basis) {
                ApparelEffectBasis.perBaseTier => baseTierOfPower(c),
                ApparelEffectBasis.apparelBonus => bonus,
                ApparelEffectBasis.halfApparelBonusRoundUp => (bonus + 1) ~/ 2,
              };
          for (final s in effect.stats) {
            add(s, magnitude);
          }
        }
      }
    }

    // Multi-layer Apparel Penalty applies to every Combat Roll.
    final penalty = apparelPenalty(c);
    for (final s in combatRolls) {
      add(s, -penalty);
    }

    return totals;
  }

  // ==========================================================================
  // Weapons (Inventory page — structured, automated; see data/weapons.dart)
  // ==========================================================================

  /// How many Quality Slots a Weapon has (from its Craftsmanship Grade — the
  /// same table Apparel uses; a Weapon has no Low/Standard/High Grade).
  static int weaponQualitySlots(WeaponPiece w) =>
      craftsmanshipInfo(w.craftsmanshipGrade).qualitySlots;

  /// How many Quality Slots the Weapon's chosen Qualities currently occupy.
  static int weaponQualitySlotsUsed(WeaponPiece w) => w.qualities
      .fold<int>(0, (sum, q) => sum + (q.slots < 1 ? 1 : q.slots));

  /// The resolved `WeaponQualityDef`s on a Weapon (skipping unknown/stale
  /// names), paired with the player's selection.
  static Iterable<({WeaponQualitySelection sel, WeaponQualityDef def})>
      weaponQualityDefs(WeaponPiece w) sync* {
    for (final sel in w.qualities) {
      final def = HomebrewRegistry.resolveWeaponQuality(sel.name);
      if (def != null) yield (sel: sel, def: def);
    }
  }

  /// The Weapon's resolved Category, or `null` when none is chosen / it's stale.
  static WeaponCategoryDef? weaponCategory(WeaponPiece w) =>
      w.category.isEmpty ? null : weaponCategoryByName(w.category);

  /// The Weapon's maximum Life Points: base 32 + 8×Power Level, plus the Shield
  /// Category's Size-scaled bonus and any Durable Quality. CONFIRMED (verbatim:
  /// "Each Weapon starts with 32 Life Points and gains 8 Life Points each Power
  /// Level.").
  static int weaponMaxLife(Character c, WeaponPiece w) {
    var max = kWeaponBaseLifePoints + kWeaponLifePointsPerLevel * c.powerLevel;
    final cat = weaponCategory(w);
    if (cat != null && cat.grantsShieldLifePoints) {
      max += w.size.shieldLifePointsPerLevel * c.powerLevel;
    }
    for (final q in weaponQualityDefs(w)) {
      final auto = q.def.automation;
      if (auto == null || auto.lifePointsPerLevel == 0) continue;
      final mult = auto.lifePointsPerLevelPerSlot ? (q.sel.slots < 1 ? 1 : q.sel.slots) : 1;
      max += auto.lifePointsPerLevel * mult * c.powerLevel;
    }
    return max;
  }

  /// The Weapon's current Life Points (a `null` model value means topped-up to
  /// the derived maximum), clamped to that maximum.
  static int weaponCurrentLife(Character c, WeaponPiece w) {
    final max = weaponMaxLife(c, w);
    return (w.lifePoints ?? max).clamp(0, max);
  }

  /// The Weapon's own Damage Reduction (for Called Shots against it): 6(bT).
  static int weaponSelfDamageReduction(Character c) =>
      kWeaponDamageReductionPerBaseTier * baseTierOfPower(c);

  /// Whether any Quality makes the Weapon's Life Points un-reducible
  /// (Unbreakable).
  static bool weaponIsUnbreakable(WeaponPiece w) =>
      weaponQualityDefs(w).any((q) => q.def.automation?.unbreakable ?? false);

  /// Whether a Weapon is currently granting its benefits — it must be wielded
  /// and not broken (Life Points > 0). CONFIRMED (verbatim: a Weapon reduced to
  /// 0 Life Points "is broken and cannot be used for any Attacking Maneuvers").
  static bool weaponIsActive(Character c, WeaponPiece w) =>
      w.wielded && weaponCurrentLife(c, w) > 0;

  /// Whether the character has the Weapon Specialist Talent (which removes the
  /// Weapon Penalty). Detected by Talent name — a Trait/Factor that "grants the
  /// Weapon Specialist Talent" should add it to the character's Talents to be
  /// recognised here.
  static bool hasWeaponSpecialist(Character c) => c.talents.any(
      (t) => t.name.trim().toLowerCase() == kWeaponSpecialistTalentName.toLowerCase());

  /// Whether the character is wielding any Weapon (incurs the Weapon Penalty).
  static bool isWieldingWeapon(Character c) => c.weapons.any((w) => w.wielded);

  /// The Weapon Penalty currently reducing Strike Rolls: 2(T) while wielding any
  /// Weapon, nullified by the Weapon Specialist Talent. CONFIRMED (verbatim).
  static int weaponPenalty(Character c) {
    if (!isWieldingWeapon(c) || hasWeaponSpecialist(c)) return 0;
    return kWeaponPenaltyPerTier * tierOfPower(c);
  }

  /// The AffectedStat a Weapon's Wound bonuses feed, by Weapon Type.
  static AffectedStat _weaponWoundStat(WeaponType type) => switch (type) {
        WeaponType.physical => AffectedStat.woundPhysical,
        WeaponType.energy => AffectedStat.woundEnergy,
        WeaponType.magic => AffectedStat.woundMagic,
      };

  /// A single Weapon's always-on, per-Attack Combat-Roll modifiers (Weapon
  /// Size + its Category's Wound bonus + automated Quality effects). Keyed by
  /// AffectedStat (Strike and the Type's Wound stat). Does NOT include the
  /// global Weapon Penalty (that applies to every Strike while wielding and is
  /// folded into the sheet's Strike separately) — this is the delta for an
  /// Armed Attack made *with this Weapon*.
  static Map<AffectedStat, int> weaponModifiers(Character c, WeaponPiece w) {
    final totals = <AffectedStat, int>{};
    final woundStat = _weaponWoundStat(w.type);
    void add(AffectedStat stat, int v) {
      if (v != 0) totals[stat] = (totals[stat] ?? 0) + v;
    }

    final top = tierOfPower(c);
    final baseTop = baseTierOfPower(c);

    // Weapon Size adjustments.
    add(AffectedStat.strike, w.size.strikePerTier * top);
    add(woundStat, w.size.woundPerTier * top);

    // Category Wound bonus (Slashing / Magic Orb → +2(T)).
    final cat = weaponCategory(w);
    if (cat != null && cat.type == w.type) {
      add(woundStat, cat.woundBonusPerTier * top);
    }

    // Automated Quality Combat-Roll effects.
    for (final q in weaponQualityDefs(w)) {
      final auto = q.def.automation;
      if (auto == null) continue;
      for (final effect in auto.statEffects) {
        final slots = q.sel.slots < 1 ? 1 : q.sel.slots;
        final tierValue = switch (effect.basis) {
          WeaponEffectBasis.perTier => top,
          WeaponEffectBasis.perBaseTier => baseTop,
        };
        final magnitude =
            effect.coefficient * tierValue * (effect.perSlot ? slots : 1);
        final stat = effect.target == WeaponEffectTarget.strike
            ? AffectedStat.strike
            : woundStat;
        add(stat, magnitude);
      }
    }
    return totals;
  }

  /// Total Damage Reduction (to the WIELDER) granted by wielded Weapons — the
  /// Warding Weapon Special Quality: +2(bT) while wielding. Feeds the Damage
  /// Calculator, like Armor's Damage Reduction.
  static int weaponDamageReduction(Character c) {
    var total = 0;
    for (final w in c.weapons) {
      if (!weaponIsActive(c, w)) continue;
      for (final q in weaponQualityDefs(w)) {
        total += (q.def.automation?.damageReductionPerBaseTier ?? 0) *
            baseTierOfPower(c);
      }
    }
    return total;
  }

  /// The global Weapon contribution folded into the sheet's stats: just the
  /// Weapon Penalty on Strike. Per-Weapon Size/Category/Quality modifiers are
  /// NOT folded in — they apply only to Armed Attacks made with that specific
  /// Weapon (and only one Weapon applies per Attack), so they're surfaced
  /// per-Weapon in the UI instead of summed into the single global Strike/Wound.
  static Map<AffectedStat, int> weaponTotals(Character c) {
    final penalty = weaponPenalty(c);
    return penalty == 0 ? const {} : {AffectedStat.strike: -penalty};
  }

  // ==========================================================================
  // Accessories (Inventory page — structured, automated; see
  // data/accessories.dart)
  // ==========================================================================

  /// The resolved `AccessoryDef`s the character owns (skipping unknown/stale
  /// names), paired with the player's selection.
  static Iterable<({AccessorySelection sel, AccessoryDef def})>
      accessoryDefs(Character c) sync* {
    for (final sel in c.accessories) {
      final def = HomebrewRegistry.resolveAccessory(sel.name);
      if (def != null) yield (sel: sel, def: def);
    }
  }

  /// How many Accessories are currently equipped (the site caps this at 2).
  static int equippedAccessoryCount(Character c) =>
      c.accessories.where((a) => a.equipped).length;

  /// Total Damage Reduction (to the wearer) from equipped Accessories that grant
  /// an unconditional DR bonus while equipped (Armored Gloves, Helmet → 1(bT)).
  /// Feeds the Damage Calculator, like Armor / Warding-Weapon Damage Reduction.
  static int accessoryDamageReduction(Character c) {
    var total = 0;
    for (final a in accessoryDefs(c)) {
      if (!a.sel.equipped) continue;
      total +=
          (a.def.automation?.damageReductionPerBaseTier ?? 0) * baseTierOfPower(c);
    }
    return total;
  }

  /// Every equipped Accessory's automated stat effects, per Affected Stat —
  /// joins the same additive pipeline as Custom Buffs/Conditions/States/Apparel.
  static Map<AffectedStat, int> accessoryTotals(Character c) {
    final totals = <AffectedStat, int>{};
    void add(AffectedStat stat, int v) {
      if (v != 0) totals[stat] = (totals[stat] ?? 0) + v;
    }

    for (final a in accessoryDefs(c)) {
      if (!a.sel.equipped) continue;
      final auto = a.def.automation;
      if (auto == null) continue;
      for (final effect in auto.statEffects) {
        final magnitude = effect.coefficient *
            switch (effect.basis) {
              AccessoryEffectBasis.perBaseTier => baseTierOfPower(c),
              AccessoryEffectBasis.perTier => tierOfPower(c),
            };
        for (final s in effect.stats) {
          add(s, magnitude);
        }
      }
    }
    return totals;
  }

  // ==========================================================================
  // Signature Techniques (Signatures tab; see data/signature_*.dart)
  // ==========================================================================

  /// "Ultimate Signature Techniques increase the TP Cost … by 4." Also applies
  /// to Dramatic Finishers.
  static const int kSignatureUltimateTpSurcharge = 4;

  /// "The overall TP Cost of a Signature Technique cannot be less than 8."
  static const int kSignatureBaseTpCost = 8;

  /// The base Profile a Technique is built on (null when none/stale).
  static SigProfileDef? signatureProfileFor(SignatureTechnique tech) =>
      tech.profileName.isEmpty ? null : signatureProfileByName(tech.profileName);

  /// The chosen Advantages/Disadvantages resolved to their catalogue defs
  /// (skipping unknown/stale names), paired with the player's selection.
  static Iterable<({SigModifierSelection sel, SigModifierDef def})>
      signatureModifierDefs(SignatureTechnique tech) sync* {
    for (final sel in [...tech.advantages, ...tech.disadvantages]) {
      final def = HomebrewRegistry.resolveSignatureModifier(sel.name);
      if (def != null) yield (sel: sel, def: def);
    }
  }

  /// Technique Point Cost: 8 + Σ(Advantage rank costs) − Σ(Disadvantage rank
  /// reductions), +4 if Ultimate/Dramatic Finisher, floored at 8. CONFIRMED
  /// (verbatim). Disadvantage costs are stored negative, so they sum directly.
  static int signatureTpCost(SignatureTechnique tech) {
    var tp = kSignatureBaseTpCost;
    for (final m in signatureModifierDefs(tech)) {
      tp += m.def.tpCostForRank(m.sel.rank);
    }
    if (tech.level.isUltimate) tp += kSignatureUltimateTpSurcharge;
    return tp < kSignatureBaseTpCost ? kSignatureBaseTpCost : tp;
  }

  /// The Technique Points on a Signature Technique that are "free" — not paid
  /// from the character's TP budget: the Technique's flat `freeTp` discount
  /// plus the TP Cost of every Advantage flagged free. Disadvantages (negative
  /// TP) are never counted here.
  static int signatureFreeTp(SignatureTechnique tech) {
    var free = tech.freeTp;
    for (final adv in tech.advantages) {
      if (!adv.free) continue;
      final def = HomebrewRegistry.resolveSignatureModifier(adv.name);
      if (def != null) free += def.tpCostForRank(adv.rank);
    }
    return free;
  }

  /// The Technique Points this Signature Technique actually costs against the
  /// character's TP budget = its full TP Cost minus any free TP, floored at 0.
  /// (The full TP Cost — [signatureTpCost] — still drives KP Cost and the
  /// per-Tier spend cap; only pool spending is discounted.)
  static int signatureTpSpent(SignatureTechnique tech) {
    final spent = signatureTpCost(tech) - signatureFreeTp(tech);
    return spent < 0 ? 0 : spent;
  }

  /// Total Technique Points spent across every Signature Technique (honours the
  /// per-Technique free-TP / free-Advantage discounts).
  static int signatureTotalTpSpent(Character c) =>
      c.signatureTechniques.fold(0, (sum, t) => sum + signatureTpSpent(t));

  /// Ki Point Cost = `(Profile KP per Tier + ⌈TP/5⌉ + Efficiency/Inefficiency)
  /// × Tier of Power`, never below the Profile's own KP Cost (and never below
  /// half of it, the absolute minimum). CONFIRMED (verbatim). Returns 0 when no
  /// Profile is chosen yet.
  static int signatureKpCost(Character c, SignatureTechnique tech) {
    final profile = signatureProfileFor(tech);
    if (profile == null) return 0;
    final profilePerTier = profile.kpCostPerTier ?? 0;
    // A Dramatic Finisher's Super Profile adds its own KP Cost (Super
    // Profiles page, verbatim: "Each Super Profile possesses a Ki Point Cost
    // which is added onto the Ki Point Cost of the typical Profile (this
    // also is factored in for the Minimum Ki Point Cost of that Attacking
    // Maneuver)."). Non-numeric Super costs (Genki's N/A, Multi-Profile's
    // Varies) contribute 0 here.
    final superProfile = tech.superProfileName.isEmpty
        ? null
        : signatureProfileByName(tech.superProfileName);
    final superPerTier = superProfile?.kpCostPerTier ?? 0;
    final tp = signatureTpCost(tech);
    var perTier = profilePerTier + superPerTier + ((tp + 4) ~/ 5); // +⌈TP/5⌉
    // Blitz (Profile effect, verbatim): "If this Attacking Maneuver is a
    // Signature Technique, reduce the KP Cost by 2(T)."
    if (profile.name == 'Blitz') perTier -= 2;
    // Efficiency / Inefficiency change the total KP Cost by 4(T) per rank.
    for (final m in signatureModifierDefs(tech)) {
      final kp = m.def.automation?.kpPerTierPerRank ?? 0;
      if (kp != 0) perTier += kp * m.sel.rank;
    }
    // Never below 1/2 the listed KP Cost (absolute minimum; a Super
    // Profile's cost is part of the listed cost per the quote above).
    final floor = (profilePerTier + superPerTier + 1) ~/ 2;
    if (perTier < floor) perTier = floor;
    // Breakthrough does not raise Ki Point Costs — see tierOfPowerForKiCost.
    return perTier * tierOfPowerForKiCost(c);
  }

  /// Maximum Technique Points that may be spent on a single Signature Technique,
  /// by Base Tier of Power (CONFIRMED, verbatim table): 1→25, 2→30, 3→40, 4+→50.
  static int signatureTpSpendCap(Character c) {
    switch (baseTierOfPower(c)) {
      case 1:
        return 25;
      case 2:
        return 30;
      case 3:
        return 40;
      default:
        return 50;
    }
  }

  /// The AffectedStat a Technique's Wound modifiers feed, by its Foundation.
  static AffectedStat _signatureWoundStat(SigFoundation foundation) =>
      switch (foundation) {
        SigFoundation.magic => AffectedStat.woundMagic,
        SigFoundation.energy => AffectedStat.woundEnergy,
        // Physical (and Multi, which resolves concretely) feed Physical Wound.
        _ => AffectedStat.woundPhysical,
      };

  /// A Technique's automated per-attack Strike/Wound modifiers (Accurate,
  /// Power Shot, Inaccurate, Low Penetration — scaled by rank). Surfaced
  /// per-Technique on the card (like a Weapon's per-attack mods), NOT folded
  /// into the global sheet.
  static Map<AffectedStat, int> signatureModifiers(
      Character c, SignatureTechnique tech) {
    final totals = <AffectedStat, int>{};
    final woundStat = _signatureWoundStat(tech.foundation);
    final top = tierOfPower(c);
    final baseTop = baseTierOfPower(c);
    for (final m in signatureModifierDefs(tech)) {
      final auto = m.def.automation;
      if (auto == null) continue;
      for (final e in auto.statEffects) {
        final tier = e.basis == SigEffectBasis.perBaseTier ? baseTop : top;
        final magnitude = e.coefficientPerRank * m.sel.rank * tier;
        final stat = e.target == SigEffectTarget.strike
            ? AffectedStat.strike
            : woundStat;
        totals[stat] = (totals[stat] ?? 0) + magnitude;
      }
    }
    return totals;
  }

  /// How many Super / Ultimate (incl. Dramatic Finisher) Techniques are owned.
  static int signatureSuperCount(Character c) => c.signatureTechniques
      .where((t) => t.level == SignatureLevel.superTech)
      .length;
  static int signatureUltimateCount(Character c) => c.signatureTechniques
      .where((t) => t.level.isUltimate)
      .length;

  /// Possession-rule warnings (not hard-enforced): too many Ultimates, not
  /// enough Supers to back them, over the TP-spend cap, more than one Dramatic
  /// Finisher. CONFIRMED (verbatim rules).
  static List<String> signatureUltimateWarnings(Character c) {
    final warnings = <String>[];
    final supers = signatureSuperCount(c);
    final ultimates = signatureUltimateCount(c);
    if (ultimates > 3) {
      warnings.add('You can only use up to 3 Ultimate Signature Techniques per '
          'Combat Encounter.');
    }
    // 1 Ultimate is free; each further Ultimate needs a matching Super.
    if (ultimates > 1 && supers < ultimates) {
      warnings.add('To possess $ultimates Ultimates you need $ultimates Supers '
          '(you have $supers).');
    }
    if (c.signatureTechniques
            .where((t) => t.level == SignatureLevel.dramaticFinisher)
            .length >
        1) {
      warnings.add('A Character can only possess 1 Dramatic Finisher.');
    }
    final cap = signatureTpSpendCap(c);
    for (final t in c.signatureTechniques) {
      if (signatureTpCost(t) > cap) {
        warnings.add('"${t.name.isEmpty ? 'Unnamed' : t.name}" exceeds the '
            '$cap TP spend cap for this Tier of Power.');
      }
    }
    return warnings;
  }

  // ==========================================================================
  // Unique Abilities (Unique Abilities tab; see data/unique_abilities.dart)
  // ==========================================================================

  /// The catalogue def for an owned Unique Ability (null when unknown/stale).
  static UniqueAbilityDef? uniqueAbilityDefFor(UniqueAbilitySelection sel) =>
      sel.name.isEmpty ? null : HomebrewRegistry.resolveUniqueAbility(sel.name);

  /// The owned Advancements resolved to their defs (skipping unknown/stale).
  static Iterable<UaAdvancementDef> uniqueAbilityAdvancementDefs(
      UniqueAbilitySelection sel) sync* {
    final def = uniqueAbilityDefFor(sel);
    if (def == null) return;
    for (final adv in def.advancements) {
      if (sel.advancements.contains(adv.name)) yield adv;
    }
  }

  /// The applied Restrictions resolved to their defs (skipping unknown/stale).
  static Iterable<UaRestrictionDef> uniqueAbilityRestrictionDefs(
      UniqueAbilitySelection sel) sync* {
    final def = uniqueAbilityDefFor(sel);
    if (def == null) return;
    for (final r in def.restrictions) {
      if (sel.restrictions.contains(r.name)) yield r;
    }
  }

  /// A Unique Ability's TP Cost: base + Σ(owned Advancement TP) − Σ(applied
  /// Restriction reductions) − the Magic Master discount (when [forCharacter]
  /// is supplied), floored at ½ the listed base TP. CONFIRMED (verbatim:
  /// "cannot be reduced below 1/2 of its listed TP Cost").
  ///
  /// [forCharacter] is optional so the raw "listed" cost stays computable
  /// without a Character (used by tests and the picker); the tab passes the
  /// character so the displayed cost reflects the Magic Master Talent's
  /// per-Use-Magic-Rank reduction on Magical abilities.
  static int uniqueAbilityTpCost(UniqueAbilitySelection sel,
      {Character? forCharacter}) {
    final def = uniqueAbilityDefFor(sel);
    if (def == null) return 0;
    var tp = def.baseTpCost;
    for (final adv in uniqueAbilityAdvancementDefs(sel)) {
      tp += adv.tpCost;
    }
    for (final r in uniqueAbilityRestrictionDefs(sel)) {
      tp -= r.tpCostReduction;
    }
    if (forCharacter != null) {
      tp -= magicMasterTpDiscount(forCharacter, sel);
    }
    final floor = (def.baseTpCost + 1) ~/ 2; // ⌈base / 2⌉
    return tp < floor ? floor : tp;
  }

  /// The Talent that reduces Magical Unique Abilities' TP Cost by the
  /// character's Use Magic Skill Ranks (verbatim: "Reduce the TP Cost of all
  /// Magical Unique Abilities by your number of Use Magic Skill Ranks").
  static const String kMagicMasterTalentName = 'Magic Master';

  /// Whether the character owns the Magic Master Talent (detected by name,
  /// like `hasWeaponSpecialist`).
  static bool hasMagicMaster(Character c) => c.talents.any((t) =>
      t.name.trim().toLowerCase() == kMagicMasterTalentName.toLowerCase());

  /// The character's total Skill Ranks in Use Magic.
  static int useMagicRanks(Character c) {
    for (final skill in kDbuSkills) {
      if (skill.name == 'Use Magic') return totalSkillRanks(c, skill);
    }
    return 0;
  }

  /// Whether a Unique Ability selection resolves to the Magical type — either
  /// the player chose Magical, or the ability is Magical-only. A both-types
  /// ability with no chosen type is treated as not-yet-Magical (no discount).
  static bool uniqueAbilityIsMagical(UniqueAbilitySelection sel) {
    final def = uniqueAbilityDefFor(sel);
    if (def == null) return false;
    if (sel.type != null) return sel.type == UniqueAbilityType.magical;
    if (!def.allowsBothTypes) {
      return def.types.contains(UniqueAbilityType.magical);
    }
    return false;
  }

  /// The Magic Master TP discount applicable to [sel]: the character's Use
  /// Magic Ranks, but only when they own Magic Master AND the ability is
  /// Magical. (The ½-base floor is applied by [uniqueAbilityTpCost].)
  static int magicMasterTpDiscount(Character c, UniqueAbilitySelection sel) {
    if (!hasMagicMaster(c)) return 0;
    if (!uniqueAbilityIsMagical(sel)) return 0;
    return useMagicRanks(c);
  }

  /// The Technique Points this Unique Ability actually costs against the
  /// character's TP budget: 0 if the whole ability was gained free; otherwise
  /// its effective TP Cost (with Magic Master) minus the TP Cost of any
  /// Advancements flagged free, floored at 0.
  static int uniqueAbilityTpSpent(Character c, UniqueAbilitySelection sel) {
    if (sel.freeTechnique) return 0;
    var spent = uniqueAbilityTpCost(sel, forCharacter: c);
    for (final adv in uniqueAbilityAdvancementDefs(sel)) {
      if (sel.freeAdvancements.contains(adv.name)) spent -= adv.tpCost;
    }
    return spent < 0 ? 0 : spent;
  }

  /// Total Technique Points spent across all Unique Abilities (honours the
  /// free-technique / free-advancement discounts and Magic Master).
  static int uniqueAbilityTotalTpSpent(Character c) =>
      c.uniqueAbilities.fold(0, (sum, s) => sum + uniqueAbilityTpSpent(c, s));

  /// A Unique Ability's KP Cost = listed KP minus Advancement KP reductions,
  /// floored at ½ the listed KP when the base is ≥ 4(T). Returns `null` when the
  /// KP Cost is non-numeric (e.g. "Your entire Capacity") — the UI shows the
  /// verbatim [UniqueAbilityDef.kpCostText] then. CONFIRMED (verbatim limits).
  static int? uniqueAbilityKpCost(Character c, UniqueAbilitySelection sel) {
    final def = uniqueAbilityDefFor(sel);
    if (def == null || def.kpPerTier == null) return null;
    var perTier = def.kpPerTier!;
    for (final adv in uniqueAbilityAdvancementDefs(sel)) {
      perTier -= adv.kpReductionPerTier;
    }
    // "If a Unique Ability's Ki Point Cost (before modifications) is 4(T) or
    // higher, you cannot reduce it below 1/2 of its Ki Point Cost."
    if (def.kpPerTier! >= 4) {
      final floor = (def.kpPerTier! + 1) ~/ 2;
      if (perTier < floor) perTier = floor;
    }
    if (perTier < 0) perTier = 0;
    final tier =
        def.kpUsesBaseTier ? baseTierOfPower(c) : tierOfPowerForKiCost(c);
    var kp = perTier * tier;
    // Custom Buffs / Trait automation on Unique Ability Ki Point Costs (a
    // negative value reduces — e.g. Frigid Tricks' "−2(T) all Unique Abilities").
    kp += channelTotal(c, AffectedStat.kiCostUniqueAbilities);
    kp += uniqueAbilityIsMagical(sel)
        ? channelTotal(c, AffectedStat.kiCostUniqueAbilitiesMagical)
        : channelTotal(c, AffectedStat.kiCostUniqueAbilitiesTechnical);
    return kp < 0 ? 0 : kp;
  }

  /// The Advancement names currently LOCKED by an applied Restriction (cannot be
  /// taken while that Restriction is on the ability).
  static Set<String> uniqueAbilityLockedAdvancements(
      UniqueAbilitySelection sel) {
    final locked = <String>{};
    for (final r in uniqueAbilityRestrictionDefs(sel)) {
      locked.addAll(r.lockedAdvancements);
    }
    return locked;
  }

  /// Total Technique Points the character has spent across all Unique Abilities.
  static int uniqueAbilityTotalTp(Character c) =>
      c.uniqueAbilities.fold(0, (sum, s) => sum + uniqueAbilityTpCost(s));

  // ==========================================================================
  // References tab — Attack Reference calculator (ephemeral; nothing persists)
  // ==========================================================================

  /// The Wound `RollValue` for a given attack Foundation.
  static RollValue _woundForFoundation(
          DerivedCharacterStats stats, SigFoundation f) =>
      switch (f) {
        SigFoundation.magic => stats.woundMagic,
        SigFoundation.energy => stats.woundEnergy,
        _ => stats.woundPhysical,
      };

  /// Whether a Weapon of [type] buffs an attack of Foundation [f] (Physical
  /// Weapons only apply to Physical attacks, Energy→Energy, Magic→Magic).
  static bool weaponMatchesFoundation(WeaponType type, SigFoundation f) =>
      switch (type) {
        WeaponType.physical => f == SigFoundation.physical,
        WeaponType.energy => f == SigFoundation.energy,
        WeaponType.magic => f == SigFoundation.magic,
      };

  /// Builds the References tab's Attack Reference from the selected attack and
  /// situational inputs. [attackName] is a Profile name (see
  /// `kDbuSignatureProfiles`) or one of the character's Signature Technique
  /// names. [weaponName] is a `Character.weapons` name, or '' for Unarmed — an
  /// equipped Weapon only buffs attacks of its matching Foundation.
  static AttackReference attackReference(
    Character c,
    DerivedCharacterStats stats, {
    required String attackName,
    SigFoundation? multiFoundationChoice,
    String weaponName = '',
    String extraProfileName = '',
    String advantageName = '',
    int advantageRank = 1,
    int energyCharges = 0,
    int wager = 0,
    int targetRange = 0,
    int targetSizeRelative = 0,
    bool greaterDiceActive = false,
    int miscStrike = 0,
    int miscWound = 0,
    int miscDodge = 0,
  }) {
    final top = tierOfPower(c);
    final baseTop = baseTierOfPower(c);
    // Ki Point Costs ignore a Breakthrough ToP increase (Core Rules).
    final kiTop = tierOfPowerForKiCost(c);

    // Resolve the attack: a Signature Technique the character owns, else a
    // catalogue Profile.
    final tech = c.signatureTechniques
        .cast<SignatureTechnique?>()
        .firstWhere((t) => t?.name == attackName, orElse: () => null);
    final profile = tech == null ? signatureProfileByName(attackName) : null;

    // Foundation + Ki cost + Damage Category + description.
    final SigFoundation foundation;
    var kiCost = 0;
    DamageCategory? damageCategory;
    final String description;
    Map<AffectedStat, int> sigMods = const {};
    if (tech != null) {
      foundation = tech.foundation;
      kiCost = signatureKpCost(c, tech);
      damageCategory = signatureProfileFor(tech)?.damageCategory;
      // A Dramatic Finisher shows its Super Profile's effect too.
      final superDef = tech.superProfileName.isEmpty
          ? null
          : signatureProfileByName(tech.superProfileName);
      description = [
        signatureProfileFor(tech)?.effect ?? '',
        if (superDef != null) '${superDef.name} (Super): ${superDef.effect}',
      ].where((s) => s.isNotEmpty).join('\n');
      sigMods = signatureModifiers(c, tech);
    } else if (profile != null) {
      foundation = profile.foundation == SigFoundation.multi
          ? (multiFoundationChoice ?? SigFoundation.physical)
          : profile.foundation;
      kiCost = (profile.kpCostPerTier ?? 0) * kiTop;
      damageCategory = profile.damageCategory;
      description = profile.effect;
    } else {
      foundation = multiFoundationChoice ?? SigFoundation.physical;
      description = '';
    }

    // Extra Profile: adds its KP Cost, and the attack takes the highest Damage
    // Category among applied Profiles. CONFIRMED (verbatim: "apply the highest
    // Damage Category among those Attacking Maneuvers").
    final extraProfile = extraProfileName.isEmpty
        ? null
        : signatureProfileByName(extraProfileName);
    if (extraProfile != null) {
      kiCost += (extraProfile.kpCostPerTier ?? 0) * kiTop;
      final ec = extraProfile.damageCategory;
      if (ec != null &&
          (damageCategory == null || ec.index > damageCategory.index)) {
        damageCategory = ec;
      }
    }

    // ---- Profile-effect automation (Foundations & Profiles / Super
    // Profiles pages, all CONFIRMED verbatim). The Profiles applied to this
    // attack: the base Profile (or the Signature's), a Dramatic Finisher's
    // Super Profile, and the Extra Profile.
    final appliedProfiles = <String>{
      if (profile != null) profile.name,
      if (tech != null) tech.profileName,
      if (tech != null) tech.superProfileName,
      if (extraProfile != null) extraProfile.name,
    }..remove('');
    bool has(String name) => appliedProfiles.contains(name);

    // The Foundation's Damage Attribute (Force for Physical/Energy, Magic
    // for Magic) — already part of the Wound stat once; some Profiles apply
    // it "an additional time".
    final forceMod = stats.attributeModifiers[DbuAttribute.force] ?? 0;
    final magicMod = stats.attributeModifiers[DbuAttribute.magic] ?? 0;
    final damageAttribute =
        foundation == SigFoundation.magic ? magicMod : forceMod;

    // Profile-granted Energy Charges: Powered "This Attacking Maneuver gains
    // an Energy Charge."; Beam "gains an Energy Charge that does not count
    // towards your maximum number of Energy Charges." The maximum is 7
    // (Attacking page), or 10 with Mega Flare ("The maximum number of Energy
    // Charges for this Profile is 10.").
    final chargeCap = has('Mega Flare') ? 10 : 7;
    var totalCharges =
        math.min(energyCharges + (has('Powered') ? 1 : 0), chargeCap);
    if (has('Beam')) totalCharges += 1;

    var profileStrike = 0;
    var profileWound = 0;
    int? profileWoundCritTarget;
    // Powered: "Apply your Damage Attribute an additional time for this
    // Attacking Maneuver."
    if (has('Powered')) profileWound += damageAttribute;
    // Complete Annihilation (Super): "Apply your Damage Attribute an
    // additional time."
    if (has('Complete Annihilation')) profileWound += damageAttribute;
    // Mega Flare: "For every Energy Charge applied to this Attacking
    // Maneuver, increase the Wound Roll by 1(T)."
    if (has('Mega Flare')) profileWound += top * totalCharges;
    // Combo Attack (Super): "Increase the Strike Roll for this Attacking
    // Maneuver by 2(T)."
    if (has('Combo Attack')) profileStrike += 2 * top;
    // Crushing: "Only apply half of your Haste to the Strike Roll for this
    // Attacking Maneuver."
    if (has('Crushing')) profileStrike -= stats.haste - stats.haste ~/ 2;
    // Cutting: "On the Wound Roll for this Attacking Maneuver, the Critical
    // Target is 5 (ignoring the usual limit)."
    if (has('Cutting')) profileWoundCritTarget = 5;
    // Elemental (Dark): "If this Attacking Maneuver has the Elemental
    // (Light) Profile applied to it, increase the Wound Rolls by 2(T)." and
    // Elemental (Light): "If this Attacking Maneuver has the Elemental
    // (Dark) Profile applied to it, increase the Strike Roll by 1(T)."
    if (has('Elemental (Dark)') && has('Elemental (Light)')) {
      profileWound += 2 * top;
      profileStrike += top;
    }
    // Genki (Super): "For each stack of Lifeforce lost through this effect,
    // increase your Wound Roll by 4(bT)." — reads the tracked Lifeforce
    // Resource (losing the stacks on use stays with the player).
    if (has('Genki')) {
      profileWound += 4 * baseTop * namedResourceStacks(c, 'Lifeforce');
    }
    // Super Beam (Super): "Increase the Dice Category of the Extra Dice
    // gained from your Energy Charges by 1 Dice Category."
    final energyChargeCategoryBonus = has('Super Beam') ? 1 : 0;
    // Mega Flare: "If the number of Energy Charges applied to this Attacking
    // Maneuver is 7+, increase the Damage Category by 1 Category."
    if (has('Mega Flare') && totalCharges >= 7 && damageCategory != null) {
      final shifted = (damageCategory.index + 1)
          .clamp(0, DamageCategory.values.length - 1);
      damageCategory = DamageCategory.values[shifted];
    }

    // Equipped-Weapon per-attack modifiers, only if its Foundation matches.
    var weaponStrike = 0;
    var weaponWound = 0;
    if (weaponName.isNotEmpty) {
      final w = c.weapons
          .cast<WeaponPiece?>()
          .firstWhere((x) => x?.name == weaponName, orElse: () => null);
      if (w != null && weaponMatchesFoundation(w.type, foundation)) {
        final m = weaponModifiers(c, w);
        weaponStrike = m[AffectedStat.strike] ?? 0;
        weaponWound = m[_weaponWoundStat(w.type)] ?? 0;
      }
    }

    final sigStrike = sigMods[AffectedStat.strike] ?? 0;
    final sigWound = sigMods[_signatureWoundStat(foundation)] ?? 0;

    // A selected Advantage/Disadvantage folds its automated Strike/Wound/KP
    // effect into the referenced attack at the chosen rank.
    var advStrike = 0;
    var advWound = 0;
    final advDef =
        advantageName.isEmpty
            ? null
            : HomebrewRegistry.resolveSignatureModifier(advantageName);
    final advAuto = advDef?.automation;
    if (advAuto != null) {
      final rank = advantageRank.clamp(1, advDef!.maxRank);
      for (final e in advAuto.statEffects) {
        final tier = e.basis == SigEffectBasis.perBaseTier ? baseTop : top;
        final v = e.coefficientPerRank * rank * tier;
        if (e.target == SigEffectTarget.strike) {
          advStrike += v;
        } else {
          advWound += v;
        }
      }
      kiCost += advAuto.kpPerTierPerRank * rank * kiTop;
      if (kiCost < 0) kiCost = 0;
    }

    // Perfect Ki Control Aspect (verbatim): "Reduce the Ki Point Cost of all
    // Attacking Maneuvers by 1(T). Your Minimum Ki Point Cost for your
    // Attacking Maneuvers is 2(T), this cannot increase the Minimum Ki Point
    // Cost for an Attacking Maneuver."
    if (hasActiveAspect(c, 'Perfect Ki Control')) {
      final reduced = kiCost - kiTop;
      final minCost = 2 * kiTop;
      kiCost = reduced < minCost ? math.min(kiCost, minCost) : reduced;
    }

    // Long Range: an Opponent 9+ Squares away reduces Strike by 2(bT).
    // CONFIRMED (see RangeRules).
    final longRangePenalty = targetRange >= 9
        ? RangeRules.longRangePenaltyPerBaseTier * baseTop
        : 0;

    // Custom Buff channels that only apply to a referenced attack: per-Foundation
    // Strike (+ its Critical Target), Armed/Unarmed Strike/Wound, Ki Point Cost,
    // the Duel Clash bonus, and the attack's Damage Category.
    final armed = weaponName.isNotEmpty;
    final foundationStrikeBuff = customBuffChannel(c, switch (foundation) {
      SigFoundation.energy => AffectedStat.strikeEnergy,
      SigFoundation.magic => AffectedStat.strikeMagic,
      _ => AffectedStat.strikePhysical,
    });
    final foundationStrikeCtBuff = customBuffChannel(c, switch (foundation) {
      SigFoundation.energy => AffectedStat.strikeEnergyCriticalTarget,
      SigFoundation.magic => AffectedStat.strikeMagicCriticalTarget,
      _ => AffectedStat.strikePhysicalCriticalTarget,
    });
    final armedStrikeBuff = customBuffChannel(
        c, armed ? AffectedStat.armedStrike : AffectedStat.unarmedStrike);
    final armedWoundBuff = customBuffChannel(
        c, armed ? AffectedStat.armedWound : AffectedStat.unarmedWound);
    kiCost += customBuffChannel(c, AffectedStat.kiCostAttacks) +
        customBuffChannel(c, AffectedStat.kiCostAttacksNoCap);
    if (kiCost < 0) kiCost = 0;
    // Attacking Damage Category: shift up (Standard→Direct→Lethal) by N.
    if (damageCategory != null) {
      final shifted = (damageCategory.index +
              customBuffChannel(c, AffectedStat.attackingDamageCategory))
          .clamp(0, DamageCategory.values.length - 1);
      damageCategory = DamageCategory.values[shifted];
    }

    // Full per-roll dice pools (base 1d10 + ToP/Greater/flat/Signature Extra
    // Dice, Wound also folding in Energy-Charge dice) — see `combatDicePool`.
    final isSig = tech != null;
    final strikePool = combatDicePool(c, CombatRollScope.strike,
        greaterDiceActive: greaterDiceActive, signature: isSig);
    final woundPool = combatDicePool(c, CombatRollScope.wound,
        energyCharges: totalCharges,
        energyChargeCategoryBonus: energyChargeCategoryBonus,
        greaterDiceActive: greaterDiceActive,
        signature: isSig);
    final dodgePool =
        combatDicePool(c, CombatRollScope.dodge, greaterDiceActive: greaterDiceActive);

    // Size-relative effects (Size page). [targetSizeRelative] = the target's
    // Size Categories relative to yours (− smaller / + larger).
    //  • Punching Down: hitting a target 2+ Categories smaller adds 1d6(T)
    //    damage → represented as Tier-of-Power d6 dice on the Wound.
    //  • Punching Up: targeting a target 2+ Categories larger adds +1(T) to the
    //    Wound Roll for every Category they are larger.
    if (targetSizeRelative <= -2) {
      woundPool.addDie(6, top); // 1d6(T)
    }
    final punchingUpWound =
        targetSizeRelative >= 2 ? top * targetSizeRelative : 0;

    // The Critical Dice added on a Critical Result (index = Tier of Power).
    // The "On a Critical" line shows only this delta — the extra dice you add
    // on a Crit — not the whole roll again. Empty ('') below the tier that
    // grants Critical Dice.
    final critIndex = tierOfPower(c);
    final critDiceLabel = (DicePool()..addCategory(critIndex)).label;

    // Assembles "<pool>±<total> (crit+)" for the base roll.
    String roll(DicePool pool, int total, int crit) =>
        '${pool.label}${total >= 0 ? '+' : ''}$total ($crit+)';

    // Signature-only flat Strike/Wound and Critical-Target Custom Buffs.
    final sigStrikeFlat =
        isSig ? customBuffChannel(c, AffectedStat.signatureStrikeFlat) : 0;
    final sigWoundFlat =
        isSig ? customBuffChannel(c, AffectedStat.signatureWoundFlat) : 0;
    final sigStrikeCt = isSig
        ? customBuffChannel(c, AffectedStat.signatureStrikeCriticalTarget)
        : 0;
    final sigWoundCt = isSig
        ? customBuffChannel(c, AffectedStat.signatureWoundCriticalTarget)
        : 0;

    final strikeTotal = stats.strike.total +
        foundationStrikeBuff +
        armedStrikeBuff +
        weaponStrike +
        sigStrike +
        sigStrikeFlat +
        advStrike +
        profileStrike -
        longRangePenalty +
        miscStrike;
    final strikeCrit =
        (stats.strike.criticalTarget + foundationStrikeCtBuff + sigStrikeCt)
            .clamp(7, 999);
    final wv = _woundForFoundation(stats, foundation);
    // A Ki Wager increases the Wound Roll 1:1 by the Ki spent. CONFIRMED
    // (verbatim: "Increase the Wound Roll … by an amount equal to the Ki Points
    // spent.").
    // Ki-Wager-conditional Wound bonuses from active Transformation Traits
    // (e.g. Super Saiyan 3's Sparking Limit Break "+4(T) if the wager ≥ ¼ Max
    // Capacity", Absolute Ki Control's "+¼ of the Ki wagered"). Divine-Ki
    // wager effects are not modelled (no Divine-Ki tracking) — reference only.
    var wagerWoundBonus = 0;
    if (wager > 0) {
      for (final ie in transformationTraitsInEffect(c)) {
        final e = ie.trait.wagerWoundEffect;
        if (e == null) continue;
        wagerWoundBonus += e.woundBonus(
          wager: wager,
          tierOfPower: top,
          maxCapacity: stats.maxCapacity,
          isSignature: tech != null,
          isUltimate: tech?.level.isUltimate ?? false,
        );
      }
    }
    final woundTotal = wv.total +
        armedWoundBuff +
        weaponWound +
        sigWound +
        sigWoundFlat +
        advWound +
        profileWound +
        wager +
        wagerWoundBonus +
        punchingUpWound +
        miscWound;
    // Cutting sets the Wound's Critical Target to 5 outright ("ignoring the
    // usual limit" — so it bypasses the 7 floor).
    final woundCrit = profileWoundCritTarget ??
        (wv.criticalTarget + sigWoundCt).clamp(7, 999);
    final dodgeTotal = stats.dodge.total + miscDodge;
    // The Duel Clash inherits the Wound's ToP Extra Dice (no Energy Charges).
    final duelPool = combatDicePool(c, CombatRollScope.wound,
        greaterDiceActive: greaterDiceActive);

    // Max Ki Wager = 1/2 of Max Capacity (a normal Wager is further limited by
    // current Capacity/Ki). CONFIRMED (verbatim).
    final maxWager = stats.maxCapacity ~/ 2;

    // Duel Clash: uses the higher of the Force/Magic Modifier, +2(T) per Energy
    // Charge on the Initiating Attack, +1(T) per Super Stack and per Raging/
    // Mindful State. It inherits the Wound's ToP Extra Dice and Critical Target.
    // CONFIRMED (verbatim, Duel Maneuver). The other situational +1(T)s
    // (United-Duel allies, Power Shot, Wound-boosting resource stacks) are left
    // to the Misc Wound field / player.
    final ragingMindful = c.states
        .where((s) =>
            (s.name == 'Raging' || s.name == 'Mindful') && s.stacks > 0)
        .length;
    final duelTotal = (forceMod > magicMod ? forceMod : magicMod) +
        2 * top * totalCharges +
        top * effectiveSuperStacksBonus(c) +
        top * ragingMindful +
        customBuffChannel(c, AffectedStat.duelClashBonus);

    return AttackReference(
      isSignature: tech != null,
      foundation: foundation,
      kiCost: kiCost,
      damageCategory: damageCategory,
      strike: AttackRollLine(
        total: strikeTotal,
        criticalTarget: strikeCrit,
        expression: roll(strikePool, strikeTotal, strikeCrit),
        criticalDiceExpression: critDiceLabel,
      ),
      wound: AttackRollLine(
        total: woundTotal,
        criticalTarget: woundCrit,
        expression: roll(woundPool, woundTotal, woundCrit),
        criticalDiceExpression: critDiceLabel,
      ),
      dodge: AttackRollLine(
        total: dodgeTotal,
        criticalTarget: stats.dodge.criticalTarget,
        expression: roll(dodgePool, dodgeTotal, stats.dodge.criticalTarget),
        criticalDiceExpression: critDiceLabel,
      ),
      duel: AttackRollLine(
        total: duelTotal,
        criticalTarget: wv.criticalTarget,
        expression: roll(duelPool, duelTotal, wv.criticalTarget),
        criticalDiceExpression: critDiceLabel,
      ),
      maxWager: maxWager,
      energyCharges: totalCharges,
      topExtraDice: topExtraDice(c),
      greaterDice: greaterDice(c),
      criticalDice: criticalDice(c),
      description: description,
    );
  }

  /// Damage Calculator: reduces an incoming Wound Roll by Soak (adjusted for
  /// Damage Category and Parry option) plus manual Damage Reduction.
  /// CONFIRMED (verbatim, see file header for Soak/Category/Parry quotes).
  static DamageResult computeDamage(
    DerivedCharacterStats stats, {
    required DamageCategory category,
    required ParryOption parry,
    required int manualDamageReduction,
    required int woundRoll,
    bool armoredAspect = false,
    bool beingBludgeoned = false,
  }) {
    // Armored Aspect (verbatim): "Reduce the Damage Category of all Attacking
    // Maneuvers that hit you by 1 Category for the sake of your Damage
    // Calculation."
    if (armoredAspect && category.index > 0) {
      category = DamageCategory.values[category.index - 1];
    }
    var adjustedSoak = stats.soak * category.soakMultiplier;
    if (parry == ParryOption.directHit) adjustedSoak *= 1.5;
    var damageReduction = manualDamageReduction;
    if (parry == ParryOption.guard) {
      damageReduction += (stats.might / 4).ceil();
    }
    // Bludgeoning Weapons "ignore 1/2 of your target's Damage Reduction".
    if (beingBludgeoned) damageReduction = (damageReduction / 2).floor();
    final totalReduction = adjustedSoak.floor() + damageReduction;
    final healthReduction = math.max(0, woundRoll - totalReduction);
    return DamageResult(
      totalReduction: totalReduction,
      healthReduction: healthReduction,
    );
  }

  /// Maps a Saving Throw to the Custom Buff `AffectedStat` that targets it.
  static AffectedStat _saveAffectedStat(DbuSavingThrow sv) => switch (sv) {
        DbuSavingThrow.impulsive => AffectedStat.impulsiveSave,
        DbuSavingThrow.cognitive => AffectedStat.cognitiveSave,
        DbuSavingThrow.corporeal => AffectedStat.corporealSave,
        DbuSavingThrow.morale => AffectedStat.moraleSave,
      };

  // --- Racial Traits / Information page --------------------------------------

  /// How many Health Thresholds the character is CURRENTLY below, regardless
  /// of whether the Steadfast Check for that Threshold was passed — distinct
  /// from `healthThresholdPenalty`, which only counts un-passed ones. Racial
  /// Trait text like "for each Health Threshold you are below" (Saiyan's
  /// Blood of the Warrior, Earthling's Earthling Resolve) applies
  /// unconditionally, Steadfast result notwithstanding.
  static int thresholdsUnderCount(int currentLife, int maxLife) {
    if (maxLife <= 0) return 0;
    final ratio = currentLife / maxLife;
    var count = 0;
    if (ratio < 0.50) count++;
    if (ratio < 0.25) count++;
    if (ratio <= 0.10) count++;
    return count;
  }

  /// The Saving Throw(s) that receive this character's Racial Saving Throw
  /// Bonus — from `RaceDef.savingThrows` for every Race, or
  /// `Character.customSavingThrows` for a Custom Species character (who has
  /// no fixed Race entry to pull from).
  static List<DbuSavingThrow> raceSavingThrows(Character c) {
    // Janemba: your Racial Saving Throw Bonus applies to Corporeal/Cognitive/
    // Impulsive (Janemba! Janemba! effect 3).
    if (janembaFormActive(c)) {
      return const [
        DbuSavingThrow.corporeal,
        DbuSavingThrow.cognitive,
        DbuSavingThrow.impulsive,
      ];
    }
    return c.race == 'Custom Species'
        ? c.customSavingThrows
        : HomebrewRegistry.resolveRace(c.race).savingThrows;
  }

  /// Racial Skill Ranks freely allocatable by the player — `RaceDef.skillRanks`
  /// for every Race (Custom Species included, whose baseline is 2), plus 1 for
  /// each Flaw Trait that took the Skill Rank compensation (verbatim, Custom
  /// Species Step 7: "For each Flaw Trait you pick, either increase the Racial
  /// Life Modifier of your Race by 2 or increase the number of Skill Ranks
  /// granted by your Race by 1").
  static int raceSkillRanks(Character c) =>
      HomebrewRegistry.resolveRace(c.race).skillRanks +
      kFlawSkillRankBonus *
          customSpeciesFlawsTaking(c, FlawCompensation.skillRank).length;

  /// This character's Racial Life Modifier: `RaceDef.racialLifeModifier`,
  /// overridden to 10 while a Janemba Form is active, plus 2 for each Custom
  /// Species Flaw Trait that took the Racial-Life-Modifier compensation. Does
  /// NOT include the Custom Buff channel — see `maxLife`, its only consumer,
  /// which adds that on top.
  static int racialLifeModifier(Character c) {
    if (janembaFormActive(c)) return 10;
    return HomebrewRegistry.resolveRace(c.race).racialLifeModifier +
        kFlawLifeModifierBonus *
            customSpeciesFlawsTaking(c, FlawCompensation.racialLifeModifier)
                .length;
  }

  /// The Custom Species **Flaw Traits** this character has actually taken —
  /// entries of `Character.customRaceTraits` that resolve to a catalogue Flaw.
  /// Capped at `kMaxCustomSpeciesFlaws` so an over-limit roster can't inflate
  /// the compensation totals (the UI warns about the excess separately).
  static List<RaceTraitDef> customSpeciesFlaws(Character c) {
    if (c.race != 'Custom Species') return const [];
    final flaws = <RaceTraitDef>[];
    for (final entry in c.customRaceTraits) {
      final def = customSpeciesTraitByName(entry.name);
      if (def != null && isCustomSpeciesFlaw(def)) flaws.add(def);
    }
    return flaws.length > kMaxCustomSpeciesFlaws
        ? flaws.sublist(0, kMaxCustomSpeciesFlaws)
        : flaws;
  }

  /// The taken Flaw Traits whose chosen compensation is [pick]. A Flaw with no
  /// recorded choice contributes to neither total until the player picks one.
  static List<RaceTraitDef> customSpeciesFlawsTaking(
    Character c,
    FlawCompensation pick,
  ) =>
      customSpeciesFlaws(c)
          .where((f) => c.customFlawCompensation[f.name] == pick)
          .toList();

  /// Every Racial Trait currently ACTIVE for this character: the Race's
  /// canonical Primary/Secondary catalogue (see `race_traits.dart`), with
  /// any Trait swapped out for a compatible Racial Factor's Factor Trait
  /// (see `Character.factorSelections`) replaced by that Factor Trait —
  /// CONFIRMED (racial-factors page, verbatim): "Factor Traits are
  /// considered Racial Traits" — converted via `FactorTraitDef.toRaceTraitDef`
  /// so every downstream consumer (automation, granted Resources, Option
  /// pickers, the Information page's Trait list) treats it identically to a
  /// Trait from the Race's own page. Any Trait manually deactivated without
  /// a structured Factor swap (see `Character.inactiveRaceTraitNames`) is
  /// omitted outright.
  /// Whether a Janemba-line Form is currently active. While in it, the
  /// Janemba! Janemba! Trait makes your Race 'Janemba' (Racial Life Modifier
  /// 10, Racial Saving Throw Bonus on Corporeal/Cognitive/Impulsive) and
  /// strips your normal Racial Traits, replacing them with the Reality Warping
  /// Traits (`kJanembaRealityWarpingTraits`). Fusion isn't modelled, so the
  /// rules' "if not a Fusion" caveat on the Trait-loss is always taken.
  static bool janembaFormActive(Character c) {
    for (final owned in ownedTransformations(c)) {
      if (owned.sel.active && owned.def.transformationLine == 'Janemba') {
        return true;
      }
    }
    return false;
  }

  /// The active Racial Traits for a **Custom Species** character: each
  /// selected `customRaceTraits` entry resolved to its catalogue Trait
  /// (`kDbuCustomSpeciesTraits`). A **Primary** Trait (in
  /// `customPrimaryTraits`) keeps its full automation (base + `[Twinned]`); a
  /// **Secondary** Trait is stripped to base-only via `baseOnly()`. Names not
  /// in the catalogue are freeform and contribute no automation.
  static List<RaceTraitDef> customSpeciesActiveTraits(Character c) {
    final result = <RaceTraitDef>[];
    for (final entry in c.customRaceTraits) {
      final def = customSpeciesTraitByName(entry.name);
      if (def == null) continue; // freeform / unrecognized → no automation
      result.add(c.customPrimaryTraits.contains(entry.name)
          ? def
          : def.baseOnly());
    }
    return result;
  }

  /// Whether the character has an active (Primary) Custom Species Trait with
  /// the given name — used for the handful of Twinned effects that need a
  /// bespoke calculator hook (e.g. Arcane Adept's Magic-for-Surgency).
  static bool _hasPrimaryCustomTrait(Character c, String name) =>
      c.race == 'Custom Species' &&
      c.customPrimaryTraits.contains(name) &&
      c.customRaceTraits.any((e) => e.name == name);

  /// Resolves [Character.extraRaceTraits] (`'<Race>::<Trait name>'` refs —
  /// Traits adopted from other Races) against the Racial Trait catalogue,
  /// silently skipping malformed/stale refs (same tolerance as every other
  /// name-keyed selection).
  static Iterable<RaceTraitDef> extraRaceTraitDefs(Character c) sync* {
    for (final ref in c.extraRaceTraits) {
      final sep = ref.indexOf('::');
      if (sep <= 0) continue;
      final race = ref.substring(0, sep);
      final name = ref.substring(sep + 2);
      for (final t in raceTraitsFor(race)) {
        if (t.name == name) {
          yield t;
          break;
        }
      }
    }
  }

  static List<RaceTraitDef> activeRaceTraits(Character c) {
    // Janemba strips your Racial Traits and grants the Reality Warping Traits.
    if (janembaFormActive(c)) return kJanembaRealityWarpingTraits;
    final result = <RaceTraitDef>[];
    if (c.race == 'Custom Species') {
      result.addAll(customSpeciesActiveTraits(c));
    } else {
      // Official Traits plus any authored directly on a homebrew Race —
      // both flow through the same Factor-swap / deactivation machinery.
      for (final trait in [
        ...raceTraitsFor(c.race),
        ...HomebrewRegistry.raceTraitDefsFor(c.race),
      ]) {
        FactorSelection? selection;
        for (final s in c.factorSelections) {
          if (s.replacedTraitName == trait.name) {
            selection = s;
            break;
          }
        }
        if (selection != null) {
          final factorTrait = _factorTraitFor(selection);
          if (factorTrait != null) {
            result.add(
              factorTrait.toRaceTraitDef(race: c.race, tier: trait.tier),
            );
            continue;
          }
        }
        if (c.inactiveRaceTraitNames.contains(trait.name)) continue;
        result.add(trait);
      }
    }
    // The chosen Subrace (Namekian, Demon, Glass Tribe, Neo-Tuffle, Yardrat)
    // grants exactly one extra Racial Trait — merged in so its automation,
    // Options and the Fallen Idol beast-Trait picker all apply natively.
    for (final trait in subraceTraitsFor(c.race, c.subrace)) {
      if (!result.any((r) => r.name == trait.name)) result.add(trait);
    }
    // Traits adopted from other Races apply exactly like native ones (their
    // automation, Options and reminders all flow from this list). A name
    // already present natively wins — no double-apply.
    for (final trait in extraRaceTraitDefs(c)) {
      if (!result.any((r) => r.name == trait.name)) result.add(trait);
    }
    return result;
  }

  /// Matches a Trait effect that grants the wearer Natural Armor, e.g. "Your
  /// Plating is Natural Armor." / "Your Dragon Scales are Natural Armor." /
  /// "Your Metal Exoskeleton is Natural Armor.".
  static final RegExp _naturalArmorGrant =
      RegExp(r'\b(?:is|are) Natural Armor', caseSensitive: false);

  /// Whether any of the character's currently-active Racial/Factor/Custom-
  /// Species Traits grants them Natural Armor (scanning each Trait's text and
  /// its selectable Options). Used to surface a "this character should have
  /// Natural Armor" hint in the Inventory, since the piece itself is authored
  /// by the player (Natural Armor can gain Qualities through effects, which the
  /// engine cannot pick for them). See [ApparelPiece.isNaturalArmor].
  static bool grantsNaturalArmor(Character c) {
    bool has(String s) => _naturalArmorGrant.hasMatch(s);
    for (final trait in activeRaceTraits(c)) {
      if (has(trait.description) || has(trait.trailingText)) return true;
      for (final group in trait.optionGroups) {
        for (final opt in group.options) {
          if (has(opt.description)) return true;
        }
      }
    }
    return false;
  }

  /// Whether the character already has a Natural Armor piece in their Apparel.
  static bool hasNaturalArmorPiece(Character c) =>
      c.apparel.any((p) => p.isNaturalArmor);

  /// Resolves a [FactorSelection] to its actual [FactorTraitDef], or `null`
  /// if the Factor/Factor Trait name no longer exists in the catalogue
  /// (e.g. stale save data).
  static FactorTraitDef? _factorTraitFor(FactorSelection selection) {
    final factor = factorByName(selection.factorName) ??
        HomebrewRegistry.factorDefByName(selection.factorName);
    if (factor == null) return null;
    for (final t in factor.traits) {
      if (t.name == selection.factorTraitName) return t;
    }
    return null;
  }

  /// Racial Factors whose Racial Requirement this character's Race
  /// satisfies (see `FactorDef.isEligibleForRace`) — official catalogue plus
  /// homebrew Factor Traits (each a one-Trait `FactorDef`) — does NOT yet
  /// account for `maxFactor`/narrative Prerequisites, see
  /// `compatibleFactorTraitsFor`.
  static List<FactorDef> eligibleFactors(Character c) => [
        ...kDbuFactors,
        ...HomebrewRegistry.factorDefs(),
      ].where((f) => f.isEligibleForRace(c.race)).toList();

  /// How many times [factorName] has already been selected by this
  /// character (see `FactorDef.maxFactor`).
  static int factorUsageCount(Character c, String factorName) =>
      c.factorSelections.where((f) => f.factorName == factorName).length;

  /// Every (Factor, Factor Trait) pair currently available to swap
  /// [sourceTrait] for. CONFIRMED (verbatim): Factor Traits normally
  /// replace a SECONDARY Racial Trait of the player's choice; however "If a
  /// Factor Trait has a Racial Trait listed in brackets, it means that it
  /// must replace that specific Racial Trait. In instances of this, a
  /// Factor Trait may even replace a Primary Racial Trait." — modeled by
  /// `FactorTraitDef.mustReplaceTraitName`. Factors already at their
  /// `maxFactor` are excluded, as are Factor Traits restricted to a
  /// different Race.
  static List<({FactorDef factor, FactorTraitDef trait})>
      compatibleFactorTraitsFor(Character c, RaceTraitDef sourceTrait) {
    final result = <({FactorDef factor, FactorTraitDef trait})>[];
    for (final factor in eligibleFactors(c)) {
      if (factorUsageCount(c, factor.name) >= factor.maxFactor) continue;
      for (final trait in factor.traits) {
        if (!trait.isEligibleForRace(c.race)) continue;
        final mustReplace = trait.mustReplaceTraitName;
        if (mustReplace != null) {
          if (mustReplace != sourceTrait.name) continue;
        } else if (sourceTrait.tier != RaceTraitTier.secondary) {
          continue;
        }
        result.add((factor: factor, trait: trait));
      }
    }
    return result;
  }

  /// Magnitude of a single Racial Trait automation, given the character's
  /// current/max Life (needed for [TraitMagnitudeKind.perHealthThresholdBelow]).
  static int _raceTraitMagnitude(
    Character c,
    RaceTraitAutomation auto,
    int currentLife,
    int maxLife,
  ) {
    if (!_traitConditionMet(c, auto, currentLife, maxLife)) return 0;
    final scale = switch (auto.tierScaling) {
      TierScaling.none => 1,
      TierScaling.current => tierOfPower(c),
      TierScaling.base => baseTierOfPower(c),
    };
    switch (auto.kind) {
      case TraitMagnitudeKind.flat:
        return auto.coefficient * scale;
      case TraitMagnitudeKind.perHealthThresholdBelow:
        return auto.coefficient *
            thresholdsUnderCount(currentLife, maxLife) *
            scale;
      case TraitMagnitudeKind.fractionOfAttribute:
        final mod = attributeModifier(c.scoreOf(auto.attribute!));
        final frac = auto.roundUp
            ? (mod / auto.fractionDenominator).ceil()
            : mod ~/ auto.fractionDenominator;
        return auto.coefficient * frac * scale;
      case TraitMagnitudeKind.perPowerStack:
        return auto.coefficient * c.powerStacks * scale;
      case TraitMagnitudeKind.perNamedResourceStack:
        final stacks = namedResourceStacks(c, auto.resourceName!);
        // fractionDenominator supports "for every 2 stacks of X" wordings;
        // roundUp covers "1/2 (rounded up) of your stacks of X".
        final stackFrac = auto.roundUp
            ? (stacks / auto.fractionDenominator).ceil()
            : stacks ~/ auto.fractionDenominator;
        return auto.coefficient * stackFrac * scale;
      case TraitMagnitudeKind.perPowerLevel:
        return auto.coefficient * c.powerLevel * scale;
      case TraitMagnitudeKind.perNamedTransformationStack:
        final target = auto.resourceName!.trim().toLowerCase();
        var stacks = 0;
        for (final o in ownedTransformations(c)) {
          if (o.def.name.trim().toLowerCase() == target) {
            stacks += o.sel.stacks.clamp(1, o.def.maxStacks);
          }
        }
        return auto.coefficient * (stacks ~/ auto.fractionDenominator) * scale;
    }
  }

  /// Evaluates an automation entry's computable gate (see [TraitCondition]) —
  /// an unmet condition zeroes the entry's contribution.
  static bool _traitConditionMet(
    Character c,
    RaceTraitAutomation auto,
    int currentLife,
    int maxLife,
  ) {
    switch (auto.condition) {
      case null:
        return true;
      case TraitCondition.whileNotInForm:
        return !hasActiveForm(c);
      case TraitCondition.whileInForm:
        return hasActiveForm(c);
      case TraitCondition.whileAnyPowerStack:
        return c.powerStacks >= auto.conditionAmount;
      case TraitCondition.whileInFormOrEnhancement:
        return ownedTransformations(c).any((o) =>
            o.sel.active &&
            (o.def.type == TransformationType.form ||
                o.def.type == TransformationType.enhancement) &&
            !o.def.isNullStage);
      case TraitCondition.whileHealthyThreshold:
        return thresholdsUnderCount(currentLife, maxLife) == 0;
      case TraitCondition.whileNoApparelWorn:
        return !c.apparel.any((p) => p.worn);
      case TraitCondition.whileMaxSuperStacks:
        return c.superStacks >= CapacityRules.maxSuperStacks;
      case TraitCondition.whileNamedStateActive:
        final target = auto.conditionStateName!.trim().toLowerCase();
        return c.states.any(
            (s) => s.name.trim().toLowerCase() == target && s.stacks > 0);
      case TraitCondition.whileNamedResourceAtLeast:
        return namedResourceStacks(c, auto.conditionResourceName!) >=
            auto.conditionAmount;
      case TraitCondition.whileBelowBruisedThreshold:
        return thresholdsUnderCount(currentLife, maxLife) >= 1;
      case TraitCondition.whileBelowInjuredThreshold:
        return thresholdsUnderCount(currentLife, maxLife) >= 2;
      case TraitCondition.whileNamedConditionActive:
        final target = auto.conditionStateName!.trim().toLowerCase();
        return c.conditions.any(
            (e) => e.name.trim().toLowerCase() == target && e.stacks > 0);
      case TraitCondition.whileNamedTransformationActive:
        final target =
            auto.conditionTransformationName!.trim().toLowerCase();
        return ownedTransformations(c).any((o) =>
            o.def.name.trim().toLowerCase() == target &&
            (o.def.type == TransformationType.awakening || o.sel.active));
      case TraitCondition.whileFormWithAspectActive:
        final prefix = auto.conditionAspectName!.trim().toLowerCase();
        return ownedTransformations(c).any((o) =>
            o.sel.active &&
            o.def.type != TransformationType.awakening &&
            o.def.aspects
                .any((a) => a.trim().toLowerCase().startsWith(prefix)));
      case TraitCondition.whileNoHealthThresholdPenalties:
        return healthThresholdPenalty(c, currentLife, maxLife) == 0;
    }
  }

  /// Sums every active Racial Trait's automated effect per Affected Stat
  /// (see `activeRaceTraits`/`RaceTraitDef.isAutomated`) — same additive
  /// pipeline as Custom Buffs/Conditions/States.
  static Map<AffectedStat, int> raceTraitTotals(
    Character c, {
    required int currentLife,
    required int maxLife,
  }) {
    final totals = <AffectedStat, int>{};
    for (final trait in activeRaceTraits(c)) {
      raceTraitEffect(c, trait, currentLife: currentLife, maxLife: maxLife)
          .forEach((stat, v) => totals[stat] = (totals[stat] ?? 0) + v);
    }
    // Bestial/Monstrous Traits gained through any active grant apply their
    // clean additive effects exactly like a Racial Trait (each catalogue entry
    // IS a `RaceTraitDef`).
    for (final bt in selectedBeastTraits(c)) {
      raceTraitEffect(c, bt, currentLife: currentLife, maxLife: maxLife)
          .forEach((stat, v) => totals[stat] = (totals[stat] ?? 0) + v);
    }
    return totals;
  }

  // ==========================================================================
  // Bestial / Monstrous Traits (see `data/beast_traits.dart`)
  // ==========================================================================

  /// A single active "gain N Bestial/Monstrous Trait(s)" grant, paired with the
  /// stable key its player-selected picks are stored under in
  /// `Character.beastTraitChoices`.
  static String beastTraitGrantKey(
    String source,
    String optionName,
    int index,
    BeastTraitKind kind,
  ) =>
      '$source::${optionName.isEmpty ? '_' : optionName}::${kind.name}#$index';

  /// Every currently-active beast-Trait grant on this character — from an
  /// active Racial/Subrace/Factor Trait itself (`RaceTraitDef.beastGrants`) or
  /// from a CHOSEN Option of one (`TraitOption.beastGrants`). Each is paired
  /// with the storage key returned by [beastTraitGrantKey].
  static List<({String key, BeastTraitGrant grant})> activeBeastGrants(
      Character c) {
    final out = <({String key, BeastTraitGrant grant})>[];
    for (final trait in activeRaceTraits(c)) {
      for (var i = 0; i < trait.beastGrants.length; i++) {
        final g = trait.beastGrants[i];
        out.add((key: beastTraitGrantKey(trait.name, '', i, g.kind), grant: g));
      }
      for (final opt in _chosenOptionsOf(
          trait.optionGroups, trait.name, c.raceTraitOptionChoices)) {
        for (var i = 0; i < opt.beastGrants.length; i++) {
          final g = opt.beastGrants[i];
          out.add((
            key: beastTraitGrantKey(trait.name, opt.name, i, g.kind),
            grant: g,
          ));
        }
      }
    }
    return out;
  }

  /// The resolved Bestial/Monstrous Trait defs the character currently has
  /// (fixed grants + the player's picks across every active grant), de-duped by
  /// kind + name so overlapping grants never double-apply. Covers BOTH the
  /// always-on trait pipeline (Racial/Subrace/Factor grants) and
  /// Transformation-gated grants (only while the Transformation is in effect).
  static List<RaceTraitDef> selectedBeastTraits(Character c) {
    final seen = <String>{};
    final out = <RaceTraitDef>[];
    void add(BeastTraitKind kind, String name) {
      final def = beastTraitByName(kind, name);
      if (def == null) return;
      if (seen.add('${kind.name}:$name')) out.add(def);
    }

    void resolve(BeastTraitGrant g, Map<String, List<String>> store, String key) {
      // A gated grant (e.g. "while in a Form or Enhancement") contributes no
      // effect while its condition is unmet — but the player's pick is kept.
      if (!beastGrantConditionMet(c, g)) return;
      for (final name in g.fixed) {
        add(g.kind, name);
      }
      for (final name in (store[key] ?? const <String>[]).take(g.count)) {
        add(g.kind, name);
      }
    }

    for (final g in activeBeastGrants(c)) {
      resolve(g.grant, c.beastTraitChoices, g.key);
    }

    // Transformation-gated grants — only while the Transformation is in effect
    // (Forms/Enhancements active, Awakening Stacks reached). Stored per
    // selection so two Transformations never share picks.
    for (final ie in transformationTraitsInEffect(c)) {
      final trait = ie.trait;
      final store = ie.sel.beastTraitChoices;
      for (var i = 0; i < trait.beastGrants.length; i++) {
        final g = trait.beastGrants[i];
        resolve(g, store, beastTraitGrantKey(trait.name, '', i, g.kind));
      }
      for (final opt in chosenTraitOptions(trait, ie.sel.optionChoices)) {
        for (var i = 0; i < opt.beastGrants.length; i++) {
          final g = opt.beastGrants[i];
          resolve(
              g, store, beastTraitGrantKey(trait.name, opt.name, i, g.kind));
        }
      }
    }
    return out;
  }

  /// Whether a beast-Trait grant's gating condition is currently met. Only the
  /// Form/Enhancement-presence conditions are meaningful for a grant; every
  /// other condition (and no condition) is treated as met. Deliberately
  /// life-independent so it's safe to call from `maxLife` via
  /// `raceTraitRacialLifeModifier`.
  static bool beastGrantConditionMet(Character c, BeastTraitGrant g) {
    switch (g.condition) {
      case null:
        return true;
      case TraitCondition.whileInForm:
        return hasActiveForm(c);
      case TraitCondition.whileNotInForm:
        return !hasActiveForm(c);
      case TraitCondition.whileInFormOrEnhancement:
        return ownedTransformations(c).any((o) =>
            o.sel.active &&
            (o.def.type == TransformationType.form ||
                o.def.type == TransformationType.enhancement) &&
            !o.def.isNullStage);
      default:
        return true;
    }
  }

  /// Every distinct Bestial/Monstrous Trait the player has picked for the named
  /// Trait's grant(s), across BOTH the always-on choices
  /// (`Character.beastTraitChoices`) and every Transformation selection
  /// (`TransformationSelection.beastTraitChoices`). Used to populate a
  /// cross-Trait-restricted grant's picker (see
  /// `BeastTraitGrant.restrictedToTraitPicks`). Keys for a Trait's grants all
  /// start `'<traitName>::'` (see `beastTraitGrantKey`).
  static List<String> beastPicksForTrait(Character c, String traitName) {
    final prefix = '$traitName::';
    final out = <String>{};
    void scan(Map<String, List<String>> store) {
      store.forEach((key, picks) {
        if (key.startsWith(prefix)) {
          out.addAll(picks.where((p) => p.isNotEmpty));
        }
      });
    }

    scan(c.beastTraitChoices);
    for (final sel in c.transformations) {
      scan(sel.beastTraitChoices);
    }
    return out.toList();
  }

  /// Per-stat contribution of a SINGLE Racial Trait (used by the Information
  /// page to show each Trait's own computed effect, mirroring how
  /// `statePerStatEffect` supports the States list's per-entry display).
  static Map<AffectedStat, int> raceTraitEffect(
    Character c,
    RaceTraitDef trait, {
    required int currentLife,
    required int maxLife,
  }) {
    final result = <AffectedStat, int>{};
    _applyAutomation(c, result, trait.automation, currentLife, maxLife);
    // Option-level automation — applied only for the chosen Option(s).
    for (final auto in _chosenOptionAutomation(
        trait.optionGroups, trait.name, c.raceTraitOptionChoices)) {
      _applyAutomation(c, result, [auto], currentLife, maxLife);
    }
    return result;
  }

  /// Applies each automation entry's computed magnitude (× [stackScale] for
  /// `perTransformationStack` entries, × the divided [gradeScale] for
  /// `perTransformationGrade` ones) onto [result] — the shared inner loop of
  /// the Racial Trait / Talent / Transformation Trait pipelines.
  static void _applyAutomation(
    Character c,
    Map<AffectedStat, int> result,
    List<RaceTraitAutomation> autos,
    int currentLife,
    int maxLife, {
    int stackScale = 1,
    int gradeScale = 1,
  }) {
    for (final auto in autos) {
      var magnitude = _raceTraitMagnitude(c, auto, currentLife, maxLife);
      if (auto.perTransformationStack) magnitude *= stackScale;
      if (auto.perTransformationGrade) {
        magnitude *= auto.roundUp
            ? ((gradeScale + auto.fractionDenominator - 1) ~/
                auto.fractionDenominator)
            : gradeScale ~/ auto.fractionDenominator;
      }
      if (magnitude == 0) continue;
      for (final stat in auto.affectedStats) {
        result[stat] = (result[stat] ?? 0) + magnitude;
      }
    }
  }

  /// The automation entries of every CHOSEN Option across [groups] — chosen
  /// per the `'<Trait name>::<group label>'` → names map convention shared
  /// by `Character.raceTraitOptionChoices` and
  /// `TransformationSelection.optionChoices`.
  static Iterable<RaceTraitAutomation> _chosenOptionAutomation(
    List<RaceTraitOptionGroup> groups,
    String traitName,
    Map<String, Set<String>> choices,
  ) =>
      _chosenOptionsOf(groups, traitName, choices)
          .expand((option) => option.automation);

  /// The catalogue `TalentDef` for each of the character's recorded
  /// `TalentEntry`s — official catalogue first, then homebrew Talents (see
  /// `HomebrewRegistry.resolveTalentDef`) — skipping any whose name matches
  /// neither (freeform entries, or stale data): those simply contribute no
  /// automated effect, same tolerance as `_factorTraitFor`.
  static Iterable<TalentDef> activeTalentDefs(Character c) => c.talents
      .map((t) => HomebrewRegistry.resolveTalentDef(t.name))
      .whereType<TalentDef>();

  /// Sums every recorded Talent's automated effect per Affected Stat (see
  /// `TalentDef.isAutomated`) — same additive pipeline as Custom
  /// Buffs/Conditions/States/Racial Traits.
  static Map<AffectedStat, int> talentTotals(
    Character c, {
    required int currentLife,
    required int maxLife,
  }) {
    final totals = <AffectedStat, int>{};
    for (final talent in activeTalentDefs(c)) {
      talentEffect(c, talent, currentLife: currentLife, maxLife: maxLife)
          .forEach((stat, v) => totals[stat] = (totals[stat] ?? 0) + v);
    }
    return totals;
  }

  // ==========================================================================
  // Homebrew (player-authored content — see `data/homebrew_registry.dart`)
  // ==========================================================================

  /// The definitions for every ACTIVE homebrew this character possesses,
  /// resolved by name against the runtime registry. Selections naming homebrew
  /// that isn't in the library are silently skipped here (and surfaced to the
  /// player by [unresolvedHomebrewNames]). A homebrew Talent that is ALSO on
  /// the character's Talents list is skipped too — it already applies through
  /// the Talent pipeline ([activeTalentDefs]), so nothing may double-count.
  static Iterable<HomebrewEntry> activeHomebrew(Character c) sync* {
    for (final s in c.homebrewSelections) {
      if (!s.active) continue;
      final entry = HomebrewRegistry.byName(s.name);
      if (entry == null) continue;
      if (entry.category == HomebrewCategory.talent &&
          c.talents.any((t) =>
              t.name.trim().toLowerCase() ==
              entry.name.trim().toLowerCase())) {
        continue;
      }
      yield entry;
    }
  }

  /// Names the character has selected that no longer resolve to a homebrew
  /// definition — e.g. an imported character referencing homebrew the player
  /// hasn't imported yet. Surfaced as a warning rather than failing silently.
  static List<String> unresolvedHomebrewNames(Character c) => [
        for (final s in c.homebrewSelections)
          if (HomebrewRegistry.byName(s.name) == null) s.name,
      ];

  /// Sums every active homebrew's automated effect per Affected Stat — the same
  /// additive pipeline as Racial Traits / Talents / Transformation Traits.
  static Map<AffectedStat, int> homebrewTotals(
    Character c, {
    required int currentLife,
    required int maxLife,
  }) {
    final totals = <AffectedStat, int>{};
    for (final entry in activeHomebrew(c)) {
      homebrewEffect(c, entry, currentLife: currentLife, maxLife: maxLife)
          .forEach((stat, v) => totals[stat] = (totals[stat] ?? 0) + v);
    }
    return totals;
  }

  /// Per-stat contribution of a SINGLE homebrew entry (used by the Information
  /// page to show each entry's own computed effect, like [talentEffect]).
  static Map<AffectedStat, int> homebrewEffect(
    Character c,
    HomebrewEntry entry, {
    required int currentLife,
    required int maxLife,
  }) {
    final result = <AffectedStat, int>{};
    _applyAutomation(c, result, entry.automations, currentLife, maxLife);
    return result;
  }

  /// Per-stat contribution of a SINGLE Talent (used by the Information page
  /// to show each Talent's own computed effect).
  static Map<AffectedStat, int> talentEffect(
    Character c,
    TalentDef talent, {
    required int currentLife,
    required int maxLife,
  }) {
    final result = <AffectedStat, int>{};
    for (final auto in talent.automation) {
      final magnitude = _raceTraitMagnitude(c, auto, currentLife, maxLife);
      if (magnitude == 0) continue;
      for (final stat in auto.affectedStats) {
        result[stat] = (result[stat] ?? 0) + magnitude;
      }
    }
    return result;
  }

  /// Per-stat contribution of a SINGLE Transformation Trait (used by the
  /// Transformations page to show each Trait's own computed effect, like
  /// `raceTraitEffect` does for the Information page). The magnitude uses the
  /// same machinery as Racial Traits/Talents, plus the Awakening-only `Z`
  /// scaling (`RaceTraitAutomation.perTransformationStack` × the Awakening's
  /// current Stacks).
  static Map<AffectedStat, int> transformationTraitEffect(
    Character c,
    TransformationSelection sel,
    TransformationDef def,
    TransformationTrait trait, {
    required int currentLife,
    required int maxLife,
  }) {
    final result = <AffectedStat, int>{};
    final stacks = def.type == TransformationType.awakening
        ? sel.stacks.clamp(1, def.maxStacks)
        : 1;
    final grade = sel.grade < 1 ? 1 : sel.grade;
    _applyAutomation(c, result, trait.automation, currentLife, maxLife,
        stackScale: stacks, gradeScale: grade);
    // Option-level automation — applied only for the chosen Option(s).
    _applyAutomation(
      c,
      result,
      _chosenOptionAutomation(trait.optionGroups, trait.name, sel.optionChoices)
          .toList(),
      currentLife,
      maxLife,
      stackScale: stacks,
      gradeScale: grade,
    );
    return result;
  }

  /// Sums every in-effect Transformation Trait's automated effect per
  /// Affected Stat (see `transformationTraitsInEffect`) — same additive
  /// pipeline as Custom Buffs/Conditions/States/Racial Traits/Talents.
  /// NOTE: entries targeting the max pools (Max Life/Ki/Capacity) are applied
  /// EARLIER in `compute()` via [maxPoolAutomationTotals] (the pools must
  /// exist before current Life is known), so `compute()` strips those keys
  /// from this map before merging.
  static Map<AffectedStat, int> transformationTraitTotals(
    Character c, {
    required int currentLife,
    required int maxLife,
  }) {
    final totals = <AffectedStat, int>{};
    for (final inEffect in transformationTraitsInEffect(c)) {
      transformationTraitEffect(
        c,
        inEffect.sel,
        inEffect.def,
        inEffect.trait,
        currentLife: currentLife,
        maxLife: maxLife,
      ).forEach((stat, v) => totals[stat] = (totals[stat] ?? 0) + v);
    }
    return totals;
  }

  static const _maxPoolStats = {
    AffectedStat.maxLife,
    AffectedStat.maxKi,
    AffectedStat.maxCapacity,
  };

  /// Whether an automation entry can be evaluated BEFORE the Life pools are
  /// known — max-pool contributions must be, so health-dependent entries
  /// (per-Threshold magnitudes / health-gated conditions) can't target the
  /// pools. (The rules never do this — it would be circular.)
  static bool _isLifeIndependent(RaceTraitAutomation auto) =>
      auto.kind != TraitMagnitudeKind.perHealthThresholdBelow &&
      auto.condition != TraitCondition.whileHealthyThreshold &&
      auto.condition != TraitCondition.whileBelowBruisedThreshold &&
      auto.condition != TraitCondition.whileBelowInjuredThreshold &&
      auto.condition != TraitCondition.whileNoHealthThresholdPenalties;

  /// Automated Max Life / Max Ki / Max Capacity contributions from Racial
  /// Traits, Talents and in-effect Transformation Traits — applied in
  /// `compute()` BEFORE the pools are derived (life-independent entries only,
  /// see [_isLifeIndependent]; the current/max Life arguments passed to the
  /// magnitude helper are placeholders that such entries never read).
  static Map<AffectedStat, int> maxPoolAutomationTotals(Character c) {
    final totals = <AffectedStat, int>{};
    void add(RaceTraitAutomation auto, int stackScale) {
      if (!_isLifeIndependent(auto)) return;
      var magnitude = _raceTraitMagnitude(c, auto, 0, 0);
      if (auto.perTransformationStack) magnitude *= stackScale;
      if (magnitude == 0) return;
      for (final stat in auto.affectedStats) {
        if (!_maxPoolStats.contains(stat)) continue;
        totals[stat] = (totals[stat] ?? 0) + magnitude;
      }
    }

    for (final trait in activeRaceTraits(c)) {
      for (final auto in trait.automation) {
        add(auto, 1);
      }
      for (final auto in _chosenOptionAutomation(
          trait.optionGroups, trait.name, c.raceTraitOptionChoices)) {
        add(auto, 1);
      }
    }
    for (final talent in activeTalentDefs(c)) {
      for (final auto in talent.automation) {
        add(auto, 1);
      }
    }
    for (final entry in activeHomebrew(c)) {
      for (final auto in entry.automations) {
        add(auto, 1);
      }
    }
    for (final inEffect in transformationTraitsInEffect(c)) {
      final stacks = inEffect.def.type == TransformationType.awakening
          ? inEffect.sel.stacks.clamp(1, inEffect.def.maxStacks)
          : 1;
      for (final auto in inEffect.trait.automation) {
        add(auto, stacks);
      }
      for (final auto in _chosenOptionAutomation(inEffect.trait.optionGroups,
          inEffect.trait.name, inEffect.sel.optionChoices)) {
        add(auto, stacks);
      }
    }
    return totals;
  }

  // ==========================================================================
  // Progression (Power Level Table grants + freeform Bonus Perks)
  // ==========================================================================

  /// Every resolved `ProgressionChoice` (table-driven Main Progression slots
  /// + Bonus Perks) whose Power Level has been reached (or is unset, for a
  /// Bonus Perk that's "always on" — old sheet's own wording), through
  /// [level]. Shared iteration used by every `progression*ThroughLevel`
  /// function below.
  static Iterable<ProgressionChoice> _resolvedSlotsThroughLevel(
    Character c,
    int level,
  ) sync* {
    for (final entry in kPowerLevelGrants) {
      if (entry.powerLevel > level) continue;
      for (var slot = 0; slot < entry.grants.length; slot++) {
        final choice = c.progressionChoices['${entry.powerLevel}:$slot'];
        if (choice != null) yield choice;
      }
    }
    for (final perk in c.bonusPerks) {
      if (perk.powerLevel != null && perk.powerLevel! > level) continue;
      yield ProgressionChoice(
        resolvedKind: perk.resolvedKind,
        attributePoints: perk.attributePoints,
        talentName: perk.talentName,
        skillRanks: perk.skillRanks,
      );
    }
  }

  /// Total Technique Points earned from every resolved Skill Improvement
  /// through [level] — CONFIRMED (verbatim): "Skill Improvement... gain 15
  /// Technique Points", with PL1's direct Skill Improvement slot granting an
  /// additional +10 TP ("for a total of 6 Skill Ranks and 25 TP").
  static int progressionTpThroughLevel(Character c, int level) {
    var total = 0;
    for (final entry in kPowerLevelGrants) {
      if (entry.powerLevel > level) continue;
      for (var slot = 0; slot < entry.grants.length; slot++) {
        final choice = c.progressionChoices['${entry.powerLevel}:$slot'];
        if (choice == null) continue;
        if (choice.resolvedKind != ProgressionGrantKind.skillImprovement) {
          continue;
        }
        final isPl1FirstSlot = entry.powerLevel == 1 &&
            entry.grants[slot] == ProgressionGrantKind.skillImprovement;
        total += kSkillImprovementTp +
            (isPl1FirstSlot ? kSkillImprovementFirstBonusTp : 0);
      }
    }
    for (final perk in c.bonusPerks) {
      if (perk.powerLevel != null && perk.powerLevel! > level) continue;
      if (perk.resolvedKind != ProgressionGrantKind.skillImprovement) continue;
      total += kSkillImprovementTp;
    }
    return total;
  }

  /// How many Skill Improvements the character has resolved through their
  /// current Power Level (Main Progression slots + Bonus Perks). Used to scale
  /// the retroactive per-Skill-Improvement TP bonuses (Gifted Student, racial
  /// Traits/Talents) that add TP "each time you gain a Skill Improvement".
  static int skillImprovementCount(Character c) {
    final level = c.powerLevel;
    var count = 0;
    for (final entry in kPowerLevelGrants) {
      if (entry.powerLevel > level) continue;
      for (var slot = 0; slot < entry.grants.length; slot++) {
        final choice = c.progressionChoices['${entry.powerLevel}:$slot'];
        if (choice?.resolvedKind == ProgressionGrantKind.skillImprovement) {
          count++;
        }
      }
    }
    for (final perk in c.bonusPerks) {
      if (perk.powerLevel != null && perk.powerLevel! > level) continue;
      if (perk.resolvedKind == ProgressionGrantKind.skillImprovement) count++;
    }
    return count;
  }

  /// The Gifted Student bonus to Technique Points *per Skill Improvement*
  /// (Attributes page, verbatim): "If your Scholarship Score is 4+, increase …
  /// the amount of Technique Points you gain from Skill Improvements by 3.
  /// Double this bonus if your Scholarship Score is 8+." → Score ≥ 8 → 6,
  /// Score ≥ 4 → 3, else 0. Retroactive.
  static int giftedStudentTpPerSkillImprovement(Character c) {
    final scholarship = c.scoreOf(DbuAttribute.scholarship);
    if (scholarship >= 8) return 6;
    if (scholarship >= 4) return 3;
    return 0;
  }

  /// Matches the site's standard "Increase the number/amount of Technique
  /// Points you gain from Skill Improvement(s) by N" trait/talent wording.
  static final RegExp _tpPerSkillImprovementPattern = RegExp(
    r'Technique Points you gain from Skill Improvements? by (\d+)',
    caseSensitive: false,
  );

  /// The bonus to Technique Points *per Skill Improvement* granted by the
  /// character's active Racial Traits and owned Talents (e.g. Earthling's
  /// Quick to Master +3, an Angel's Angelic Technique +2). Detected from the
  /// standard verbatim wording so any current/future trait with that phrasing
  /// is picked up without per-entry authoring. Retroactive.
  static int traitTpPerSkillImprovement(Character c) {
    var total = 0;
    void scan(String text) {
      for (final m in _tpPerSkillImprovementPattern.allMatches(text)) {
        total += int.parse(m.group(1)!);
      }
    }

    for (final trait in activeRaceTraits(c)) {
      scan(trait.description);
    }
    for (final talent in activeTalentDefs(c)) {
      scan(talent.description);
    }
    return total;
  }

  /// Total extra Technique Points earned *per Skill Improvement* from all
  /// retroactive sources (Gifted Student + Traits/Talents).
  static int techniquePointsPerSkillImprovementBonus(Character c) =>
      giftedStudentTpPerSkillImprovement(c) +
      traitTpPerSkillImprovement(c) +
      customBuffChannel(c, AffectedStat.tpPerSkillImprovement);

  /// The character's maximum Technique Points = base Skill-Improvement TP
  /// (15 each; the PL1 Skill Improvement grants 25) + the retroactive
  /// per-Skill-Improvement bonuses (Gifted Student + Traits) applied to every
  /// Skill Improvement + the manual [Character.bonusTechniquePoints]
  /// adjustment. See [techniquePointBudget] for the itemised breakdown.
  static int maxTechniquePoints(Character c) {
    final progression = progressionTpThroughLevel(c, c.powerLevel);
    final perSi = techniquePointsPerSkillImprovementBonus(c);
    final retroactive = perSi * skillImprovementCount(c);
    return progression + retroactive + c.bonusTechniquePoints;
  }

  /// The character's Technique Point budget: maximum, spent (Signatures +
  /// Unique Abilities, honouring free-TP discounts) and remaining, plus the
  /// itemised sources feeding the maximum (for a UI breakdown/tooltip).
  static ({
    int max,
    int spent,
    int remaining,
    int progression,
    int giftedStudent,
    int traits,
    int bonus,
    int signatures,
    int uniqueAbilities,
  }) techniquePointBudget(Character c) {
    final siCount = skillImprovementCount(c);
    final progression = progressionTpThroughLevel(c, c.powerLevel);
    final giftedStudent = giftedStudentTpPerSkillImprovement(c) * siCount;
    final traits = traitTpPerSkillImprovement(c) * siCount;
    final max = progression + giftedStudent + traits + c.bonusTechniquePoints;
    final signatures = signatureTotalTpSpent(c);
    final uniqueAbilities = uniqueAbilityTotalTpSpent(c);
    final spent = signatures + uniqueAbilities;
    return (
      max: max,
      spent: spent,
      remaining: max - spent,
      progression: progression,
      giftedStudent: giftedStudent,
      traits: traits,
      bonus: c.bonusTechniquePoints,
      signatures: signatures,
      uniqueAbilities: uniqueAbilities,
    );
  }

  /// Talent names from every resolved Talent Addition through [level] (Main
  /// Progression + Bonus Perks) — see `services/progression_talent_sync.dart`.
  static List<String> progressionTalentsThroughLevel(Character c, int level) {
    return _resolvedSlotsThroughLevel(c, level)
        .where((s) => s.resolvedKind == ProgressionGrantKind.talentAddition)
        .map((s) => s.talentName)
        .where((name) => name.trim().isNotEmpty)
        .toList();
  }

  /// Summed Attribute Points from every resolved Attribute Addition through
  /// [level] (Main Progression + Bonus Perks). `Character.scoreOf` uses its
  /// own equivalent capped at the character's current Power Level.
  static Map<DbuAttribute, int> progressionAttributePointsThroughLevel(
    Character c,
    int level,
  ) {
    final totals = <DbuAttribute, int>{};
    for (final s in _resolvedSlotsThroughLevel(c, level)) {
      if (s.resolvedKind != ProgressionGrantKind.attributeAddition) continue;
      s.attributePoints.forEach((attr, points) {
        totals[attr] = (totals[attr] ?? 0) + points;
      });
    }
    return totals;
  }

  /// Summed Skill Ranks (keyed `'SkillName::specialtyKey'`) from every
  /// resolved Skill Improvement through [level] (Main Progression + Bonus
  /// Perks) — see `totalSkillRanks`.
  static Map<String, int> progressionSkillRanksThroughLevel(
    Character c,
    int level,
  ) {
    final totals = <String, int>{};
    for (final s in _resolvedSlotsThroughLevel(c, level)) {
      if (s.resolvedKind != ProgressionGrantKind.skillImprovement) continue;
      s.skillRanks.forEach((key, ranks) {
        totals[key] = (totals[key] ?? 0) + ranks;
      });
    }
    return totals;
  }

  /// Summed Skill Ranks (keyed `'SkillName::specialtyKey'`) granted by the
  /// character's Talents that let the player choose Skills to gain a Rank in
  /// (see `TalentDef.skillRankChoices` — currently just Practiced). The picks
  /// live on `TalentEntry.skillRanks`; this simply totals them across every
  /// Talent the character possesses.
  static Map<String, int> talentSkillRanks(Character c) {
    final totals = <String, int>{};
    for (final entry in c.talents) {
      entry.skillRanks.forEach((key, ranks) {
        if (ranks != 0) totals[key] = (totals[key] ?? 0) + ranks;
      });
    }
    return totals;
  }

  /// Final Skill Ranks = Character-Creation BASE allocation
  /// (`Character.skills`, still directly editable) + every resolved
  /// Progression Skill Improvement through the character's current Power
  /// Level + Skill Ranks chosen for a Talent (e.g. Practiced). This is the
  /// value `skillBonus` uses — Skill Ranks are no longer just the base
  /// allocation on its own.
  static int totalSkillRanks(
    Character c,
    SkillDef skill, {
    String? specialty,
  }) {
    final specialtyKey = specialty ?? SkillProgress.normalKey;
    final key = '${skill.name}::$specialtyKey';
    final base = c.skills[skill.name]?.ranksFor(specialtyKey) ?? 0;
    final fromProgression = progressionSkillRanksThroughLevel(
          c,
          c.powerLevel,
        )[key] ??
        0;
    final fromTalents = talentSkillRanks(c)[key] ?? 0;
    return base + fromProgression + fromTalents;
  }

  /// Computes the full derived-stats bundle for a character.
  static DerivedCharacterStats compute(Character c) {
    // Effective Modifiers include any Transformation Attribute Modifier
    // Bonus (always-on for Awakenings × Stacks, active-only for
    // Enhancements/Forms), so displayed Modifiers and Wound Rolls (which
    // read forceMod/magicMod from this map) both reflect them.
    final mods = {
      for (final a in DbuAttribute.values) a: effectiveModifier(c, a),
    };

    // Custom Buffs, automated Conditions and automated States all feed the
    // same additive pipeline — merge them so every downstream `buffFor()`
    // call picks up all three.
    final buffs = <AffectedStat, int>{...customBuffTotals(c)};
    conditionTotals(c).forEach((stat, v) => buffs[stat] = (buffs[stat] ?? 0) + v);
    stateTotals(c).forEach((stat, v) => buffs[stat] = (buffs[stat] ?? 0) + v);
    int buffFor(AffectedStat s) => buffs[s] ?? 0;

    final top = tierOfPower(c);
    final baseTop = baseTierOfPower(c);

    // Automated Max-pool contributions from Racial Traits / Talents /
    // in-effect Transformation Traits must be applied BEFORE the pools are
    // derived (current Life clamps against Max Life) — see
    // `maxPoolAutomationTotals`. The later per-source merges strip these
    // three keys so nothing double-counts.
    final poolAuto = maxPoolAutomationTotals(c);

    // Floored at 0: a max pool can't go negative (and `.clamp()` below would
    // throw if it did, since its lower bound would exceed its upper bound).
    // Base pool maxima (flat buffs + automation), then the ±¼ channels add N
    // quarters of that base ("Max Life Points ±1/4", etc.).
    final baseLifeMax = maxLife(c) +
        buffFor(AffectedStat.maxLife) +
        (poolAuto[AffectedStat.maxLife] ?? 0);
    final mLife = _floor0(baseLifeMax +
        buffFor(AffectedStat.maxLifeQuarter) * (baseLifeMax ~/ 4));
    final baseKiMax = maxKi(c) +
        buffFor(AffectedStat.maxKi) +
        (poolAuto[AffectedStat.maxKi] ?? 0);
    final mKi = _floor0(
        baseKiMax + buffFor(AffectedStat.maxKiQuarter) * (baseKiMax ~/ 4));
    final baseCapMax = maxCapacity(c) +
        buffFor(AffectedStat.maxCapacity) +
        (poolAuto[AffectedStat.maxCapacity] ?? 0) +
        powerMaxCapacityBonus(c);
    final mCap = _floor0(baseCapMax +
        buffFor(AffectedStat.maxCapacityQuarter) * (baseCapMax ~/ 4));

    // A null "current" pool means the character is topped up to their
    // maximum. Capacity has no independent "current" — it's fully derived
    // from how much has been spent.
    final curLife = (c.currentLife ?? mLife).clamp(0, mLife);
    final curKi = (c.currentKi ?? mKi).clamp(0, mKi);
    final curCap = (mCap - c.capacitySpent).clamp(0, mCap);

    // Racial Traits' automated effects join the same additive pipeline —
    // merged into `buffs` now that curLife/mLife are known (some Trait
    // automations scale off Health Thresholds currently under). Max-pool
    // keys were already applied via `poolAuto` above, so they're stripped
    // from every per-source merge here.
    void mergeStripped(Map<AffectedStat, int> totals) => totals.forEach(
        (stat, v) {
          if (_maxPoolStats.contains(stat)) return;
          buffs[stat] = (buffs[stat] ?? 0) + v;
        });
    mergeStripped(raceTraitTotals(c, currentLife: curLife, maxLife: mLife));

    // Talents' automated effects join the same additive pipeline.
    mergeStripped(talentTotals(c, currentLife: curLife, maxLife: mLife));

    // Player-authored homebrew joins it too — its automations are the very
    // same `RaceTraitAutomation` objects, resolved by name from the runtime
    // registry (see `activeHomebrew`).
    mergeStripped(homebrewTotals(c, currentLife: curLife, maxLife: mLife));

    // In-effect Transformation Traits' automated effects (Awakening Traits ×
    // Stacks where the text says Z; active Enhancements/Forms; always-on
    // Legendary Traits; unlocked Mastery Traits; toggled Grand
    // Awakening/Transcendent Traits) join the same additive pipeline.
    mergeStripped(
        transformationTraitTotals(c, currentLife: curLife, maxLife: mLife));

    // Automated Aspect effects of in-effect Transformations (Enhanced Save,
    // Raging, Mindful, High Speed) join the pipeline too.
    mergeStripped(aspectTotals(c));

    // Holding Back at the maximum (Stacks == base ToP) also penalizes Combat
    // Rolls by 1(bT) — the per-Stack Tier reduction itself lives in
    // `tierOfPower`, and the Concealment bonus in `skillBonus`.
    mergeStripped(holdingBackTotals(c));

    // Worn Apparel (Category benefits, automated Qualities and the multi-layer
    // Apparel Penalty) joins the same additive pipeline.
    apparelTotals(c)
        .forEach((stat, v) => buffs[stat] = (buffs[stat] ?? 0) + v);

    // Wielding a Weapon incurs the Weapon Penalty on Strike (the only global
    // Weapon effect — per-Weapon modifiers are surfaced per-Weapon instead).
    weaponTotals(c)
        .forEach((stat, v) => buffs[stat] = (buffs[stat] ?? 0) + v);

    // Equipped Accessories' automated "while equipped" effects join the pipeline.
    accessoryTotals(c)
        .forEach((stat, v) => buffs[stat] = (buffs[stat] ?? 0) + v);

    // A State Trait that "ignores Health Threshold Penalties" (Raging L3,
    // Mindful L3, Determined) nullifies this outright.
    final thresholdPenalty = anyStateIgnoresHealthThresholdPenalties(c)
        ? 0
        : healthThresholdPenalty(c, curLife, mLife);
    final musclePenalty = superStackMusclePenalty(c);
    final massivePower = superStackMassivePower(c);
    final powerBonus =
        powerCombatRollBonus(c) + maneuverCombatRollBonus(c);
    final offensePenalty = diminishingOffensePenalty(c);
    final defensePenalty = diminishingDefensePenalty(c);

    final h = _floor0(haste(c) + buffFor(AffectedStat.haste));
    final aw = _floor0(awareness(c) + buffFor(AffectedStat.awareness));
    // Defense Value floors at 0 here too — its own base already floors (see
    // `defenseValue()`), but Custom Buffs targeting it could push the
    // combined value negative again.
    final dv = _floor0(defenseValue(c) + buffFor(AffectedStat.defenseValue));
    // Soak's own 1×Base Tier of Power minimum only applies to the base
    // Aptitude (already enforced in `soak()`); Conditions/debuffs on top of
    // it CAN legitimately push the total down to the system's general 0
    // floor (e.g. the Broken Combat Condition explicitly discusses Soak
    // reaching exactly 0).
    // "Double Base Soak" adds the base Soak Aptitude again when toggled on.
    final baseSoak = soak(c);
    final sk = _floor0(baseSoak +
        (buffFor(AffectedStat.doubleBaseSoak) > 0 ? baseSoak : 0) +
        buffFor(AffectedStat.soak) +
        superStackSolidBulk(c));

    // Skill bonuses, expanding Encompassing skills per specialty.
    final skillBonuses = <String, RollValue>{};
    for (final s in kDbuSkills) {
      if (s.isEncompassing) {
        for (final spec in s.specialties) {
          skillBonuses['${s.name} – $spec'] = RollValue(
            _floor0(skillBonus(c, s, specialty: spec)),
            criticalTarget: _defaultCritTarget,
          );
        }
      } else {
        skillBonuses[s.name] = RollValue(
          _floor0(skillBonus(c, s)),
          criticalTarget: _defaultCritTarget,
        );
      }
    }

    // Racial Saving Throw Bonus: +1(T) and -1 Critical Target on the Race's
    // designated Saving Throw(s) (CONFIRMED, racial-rules framework page).
    final racialSaves = raceSavingThrows(c);
    final saves = {
      for (final sv in DbuSavingThrow.values)
        sv: RollValue(
          _floor0(savingThrow(c, sv) +
              buffFor(_saveAffectedStat(sv)) +
              (racialSaves.contains(sv) ? top : 0)),
          criticalTarget:
              _defaultCritTarget - (racialSaves.contains(sv) ? 1 : 0),
        ),
    };

    // Combat Rolls (Core Rules): Strike adds Haste + Awareness; Dodge adds
    // Defense Value; Wound adds the Damage Attribute (Force or Magic). Super
    // Stacks, Power stacks, Diminishing Offense/Defense and un-passed Health
    // Thresholds then apply on top.
    // "No Strike/Dodge/Wound Penalties" Custom Buffs zero the explicit penalty
    // terms for that roll (Muscle, Diminishing Offense/Defense, Health
    // Threshold).
    final noStrikePen = buffFor(AffectedStat.noStrikePenalties) > 0;
    final noDodgePen = buffFor(AffectedStat.noDodgePenalties) > 0;
    final noWoundPen = buffFor(AffectedStat.noWoundPenalties) > 0;
    final strikeThreshold = noStrikePen ? 0 : thresholdPenalty;
    final woundThreshold = noWoundPen ? 0 : thresholdPenalty;

    final strike = RollValue(
      _floor0(
        h +
            aw +
            buffFor(AffectedStat.strike) +
            powerBonus -
            (noStrikePen ? 0 : musclePenalty) -
            (noStrikePen ? 0 : offensePenalty) -
            strikeThreshold,
      ),
      criticalTarget:
          _defaultCritTarget + buffFor(AffectedStat.strikeCriticalTarget),
    );
    final dodge = RollValue(
      _floor0(
        dv +
            buffFor(AffectedStat.dodge) +
            powerBonus -
            (noDodgePen ? 0 : musclePenalty) -
            (noDodgePen ? 0 : defensePenalty) -
            (noDodgePen ? 0 : thresholdPenalty),
      ),
      criticalTarget:
          _defaultCritTarget + buffFor(AffectedStat.dodgeCriticalTarget),
    );
    final forceMod = mods[DbuAttribute.force]!;
    final magicMod = mods[DbuAttribute.magic]!;

    // Speed with its flat buff, the ±¼ channel (N quarters of the running
    // value) and an optional halving toggle.
    int speedWith(int base, AffectedStat flat, AffectedStat quarter,
        AffectedStat halve) {
      var v = base + buffFor(flat);
      v += buffFor(quarter) * (v ~/ 4);
      if (buffFor(halve) > 0) v = v ~/ 2;
      return _floor0(v);
    }

    return DerivedCharacterStats(
      tierOfPower: top,
      baseTierOfPower: baseTop,
      attributeModifiers: mods,
      maxLife: mLife,
      maxKi: mKi,
      maxCapacity: mCap,
      currentLife: curLife,
      currentKi: curKi,
      currentCapacity: curCap,
      might: _floor0(might(c) + buffFor(AffectedStat.might)),
      mightForClashes: _floor0(mightForClashes(c) + buffFor(AffectedStat.might)),
      stressBonus: stressBonus(c),
      beingBludgeoned: hasActiveBuffTarget(c, AffectedStat.beingBludgeoned),
      haste: h,
      awareness: aw,
      speedNormal: speedWith(speedNormal(c), AffectedStat.speedNormal,
          AffectedStat.speedNormalQuarter, AffectedStat.halveNormalSpeed),
      speedBoosted: speedWith(speedBoosted(c), AffectedStat.speedBoosted,
          AffectedStat.speedBoostedQuarter, AffectedStat.halveBoostedSpeed),
      initiative: _floor0(initiative(c) + buffFor(AffectedStat.initiative)),
      defenseValue: dv,
      soak: sk,
      skillBonuses: skillBonuses,
      savingThrows: saves,
      strike: strike,
      dodge: dodge,
      woundPhysical: RollValue(
        _floor0(
          forceMod +
              buffFor(AffectedStat.woundPhysical) +
              massivePower +
              powerBonus -
              woundThreshold,
        ),
        criticalTarget: _defaultCritTarget +
            buffFor(AffectedStat.woundPhysicalCriticalTarget),
      ),
      woundEnergy: RollValue(
        _floor0(
          forceMod +
              buffFor(AffectedStat.woundEnergy) +
              massivePower +
              powerBonus -
              woundThreshold,
        ),
        criticalTarget: _defaultCritTarget +
            buffFor(AffectedStat.woundEnergyCriticalTarget),
      ),
      woundMagic: RollValue(
        _floor0(
          magicMod +
              buffFor(AffectedStat.woundMagic) +
              powerBonus -
              woundThreshold,
        ),
        criticalTarget: _defaultCritTarget +
            buffFor(AffectedStat.woundMagicCriticalTarget),
      ),
      healthStatus: healthStatus(curLife, mLife),
      topExtraDice: topExtraDice(c),
      criticalDice: criticalDice(c),
      greaterDice: greaterDice(c),
      strikeDice: combatDicePool(c, CombatRollScope.strike).label,
      dodgeDice: combatDicePool(c, CombatRollScope.dodge).label,
      woundDice: combatDicePool(c, CombatRollScope.wound).label,
      healingSurgeDice: healingSurgeDice(c,
          surgencyBonus: buffFor(AffectedStat.surgency)),
      powerSurgeKi: powerSurgeKi(c,
          surgencyBonus: buffFor(AffectedStat.surgency), buffedMaxKi: mKi),
      powerSurgeCapacity: powerSurgeCapacity(c),
      healthThresholdPenalty: thresholdPenalty,
      apparelDamageReduction: apparelDamageReduction(c),
      apparelPenalty: apparelPenalty(c),
      weaponDamageReduction: weaponDamageReduction(c),
      weaponPenalty: weaponPenalty(c),
      accessoryDamageReduction: accessoryDamageReduction(c),
      bonusDamageReduction: buffFor(AffectedStat.damageReduction),
      hasArmoredAspect: hasActiveAspect(c, 'Armored'),
    );
  }
}
