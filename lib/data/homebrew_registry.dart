/// homebrew_registry.dart
/// ---------------------------------------------------------------------------
/// The RUNTIME catalogue of player-authored homebrew.
///
/// Every other catalogue in `lib/data/` is a compiled-in `const` list plus an
/// `xByName` lookup. Homebrew is the same idea, except the content is authored
/// by the player at runtime, so the list is loaded from the homebrew repository
/// instead of being const. Keeping it here — behind the same `byName` lookup
/// shape — means the calculator resolves homebrew exactly the way it resolves
/// Talents (`talentByName`) or Transformations (`transformationByName`), and
/// `Character` keeps storing only the player's CHOICES (see
/// [HomebrewSelection]) rather than duplicating definitions.
///
/// Ownership: `main.dart` seeds this at startup and the Homebrew library screen
/// refreshes it after any save/delete, so edits to a homebrew definition
/// immediately re-derive every character that uses it — the same guarantee the
/// const catalogues give (no stale totals can reach disk).
///
/// STRUCTURED OVERLAYS: beyond the generic `byName` entry lookup (used by the
/// buff pipeline for possessed homebrew), the registry converts structured
/// entries into real catalogue defs on demand:
///   • [raceDefByName] / [resolveRace]         → `RaceDef`
///   • [conditionDefByName] / [resolveConditionDef] → `ConditionDef`
///   • [transformationDefByName] / [transformationDefs] → `TransformationDef`
///   • [factorDefs] / [factorDefByName]        → `FactorDef`
/// The OFFICIAL catalogue always wins a name clash (the `resolve*` helpers
/// check it first), so homebrew can never shadow site content.
/// ---------------------------------------------------------------------------
library;

import '../models/homebrew.dart';
import 'accessories.dart';
import 'apparel.dart';
import 'basic_items.dart';
import 'dbu_rules.dart';
import 'factor_traits.dart';
import 'signature_modifiers.dart';
import 'transformations.dart';
import 'unique_abilities.dart';
import 'weapons.dart';

class HomebrewRegistry {
  HomebrewRegistry._();

  static List<HomebrewEntry> _entries = const [];

  /// Every known homebrew definition. Empty until [setAll] is called.
  static List<HomebrewEntry> get all => _entries;

  /// Replaces the registry contents (called with the full library).
  static void setAll(Iterable<HomebrewEntry> entries) {
    _entries = List.unmodifiable(entries);
  }

  /// Empties the registry — used by tests to isolate cases.
  static void clear() => _entries = const [];

  /// Case-insensitive name lookup, mirroring the catalogues' `xByName`.
  /// Returns null when no homebrew of that name is in the library.
  static HomebrewEntry? byName(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final e in _entries) {
      if (e.name.trim().toLowerCase() == needle) return e;
    }
    return null;
  }

  /// [byName] restricted to a single category (so e.g. a homebrew Talent
  /// can't masquerade as a Race just by sharing a name).
  static HomebrewEntry? _byNameIn(
      String name, bool Function(HomebrewEntry) test) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final e in _entries) {
      if (test(e) && e.name.trim().toLowerCase() == needle) return e;
    }
    return null;
  }

  // ==========================================================================
  // Races
  // ==========================================================================

  /// Every homebrew Race, converted (for the Race dropdown).
  static List<RaceDef> raceDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.race && e.name.trim().isNotEmpty)
            e.raceData.toRaceDef(e.displayName),
      ];

  /// The homebrew Race of this name, or null.
  static RaceDef? raceDefByName(String name) =>
      _byNameIn(name, (e) => e.category == HomebrewCategory.race)
          ?.let((e) => e.raceData.toRaceDef(e.displayName));

  /// Homebrew-aware replacement for `raceByName`: an official Race wins,
  /// then a homebrew Race, then the standard zero-modifier fallback.
  static RaceDef resolveRace(String name) {
    for (final r in kDbuRaces) {
      if (r.name == name) return r;
    }
    return raceDefByName(name) ?? RaceDef(name);
  }

  // ==========================================================================
  // Conditions
  // ==========================================================================

  /// Every homebrew Condition, converted (for the Conditions tracker's
  /// catalogue picker).
  static List<ConditionDef> conditionDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.condition &&
              e.name.trim().isNotEmpty)
            e.conditionData.toConditionDef(e.displayName, e.effectText),
      ];

  /// The homebrew Condition of this name, or null.
  static ConditionDef? conditionDefByName(String name) =>
      _byNameIn(name, (e) => e.category == HomebrewCategory.condition)?.let(
          (e) => e.conditionData.toConditionDef(e.displayName, e.effectText));

  /// Homebrew-aware replacement for `conditionDefByName` (official wins).
  static ConditionDef? resolveConditionDef(String name) {
    for (final c in kDbuConditions) {
      if (c.name == name) return c;
    }
    return conditionDefByName(name);
  }

  // ==========================================================================
  // Transformations (Awakenings / Enhancements / Forms)
  // ==========================================================================

  /// Every homebrew Transformation matching [test], converted (for the
  /// Transformations tab's add-pickers).
  static List<TransformationDef> transformationDefs(
          [bool Function(TransformationDef)? test]) =>
      [
        for (final e in _entries)
          if (e.isTransformationLike && e.name.trim().isNotEmpty)
            if (e.transformationData.toTransformationDef(e) case final def
                when test == null || test(def))
              def,
      ];

  /// The homebrew Transformation of this name, or null — the fallback arm of
  /// `CharacterCalculator.transformationByName`, which makes a homebrew
  /// Awakening/Enhancement/Form flow through the entire Transformation
  /// pipeline (AMB, Traits, stacks/grades, Ki Multiplier, limits).
  static TransformationDef? transformationDefByName(String name) =>
      _byNameIn(name, (e) => e.isTransformationLike)
          ?.let((e) => e.transformationData.toTransformationDef(e));

  // ==========================================================================
  // Factor Traits
  // ==========================================================================

  /// Every homebrew Factor Trait as a one-Trait `FactorDef` (joins
  /// `kDbuFactors` in the eligibility/swap machinery).
  static List<FactorDef> factorDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.factorTrait &&
              e.name.trim().isNotEmpty)
            e.factorData.toFactorDef(e),
      ];

  /// The homebrew Factor of this name, or null (resolves a
  /// `FactorSelection.factorName` that isn't in the official catalogue).
  static FactorDef? factorDefByName(String name) =>
      _byNameIn(name, (e) => e.category == HomebrewCategory.factorTrait)
          ?.let((e) => e.factorData.toFactorDef(e));

  // ==========================================================================
  // States
  // ==========================================================================

  /// Every homebrew State, converted (for the States tracker's picker).
  static List<StateDef> stateDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.state && e.name.trim().isNotEmpty)
            e.stateData.toStateDef(e.displayName, e.effectText),
      ];

  /// Homebrew-aware replacement for `stateDefByName` (official wins).
  static StateDef? resolveStateDef(String name) {
    for (final s in kDbuStates) {
      if (s.name == name) return s;
    }
    return _byNameIn(name, (e) => e.category == HomebrewCategory.state)
        ?.let((e) => e.stateData.toStateDef(e.displayName, e.effectText));
  }

  // ==========================================================================
  // Apparel / Weapon Qualities
  // ==========================================================================

  /// Every homebrew Apparel Quality, converted (for the Quality picker).
  static List<ApparelQualityDef> apparelQualityDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.apparelQuality &&
              e.name.trim().isNotEmpty)
            e.apparelQualityData.toDef(e),
      ];

  /// Homebrew-aware replacement for `apparelQualityByName` (official wins).
  static ApparelQualityDef? resolveApparelQuality(String name) =>
      apparelQualityByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.apparelQuality)
          ?.let((e) => e.apparelQualityData.toDef(e));

  /// Every homebrew Weapon Quality, converted (for the Quality picker).
  static List<WeaponQualityDef> weaponQualityDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.weaponQuality &&
              e.name.trim().isNotEmpty)
            e.weaponQualityData.toDef(e),
      ];

  /// Homebrew-aware replacement for `weaponQualityByName` (official wins).
  static WeaponQualityDef? resolveWeaponQuality(String name) =>
      weaponQualityByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.weaponQuality)
          ?.let((e) => e.weaponQualityData.toDef(e));

  // ==========================================================================
  // Accessories / Basic Items
  // ==========================================================================

  /// Every homebrew Accessory, converted (for the Accessories picker).
  static List<AccessoryDef> accessoryDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.accessory &&
              e.name.trim().isNotEmpty)
            e.accessoryData.toDef(e),
      ];

  /// Homebrew-aware replacement for `accessoryByName` (official wins).
  static AccessoryDef? resolveAccessory(String name) =>
      accessoryByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.accessory)
          ?.let((e) => e.accessoryData.toDef(e));

  /// Every homebrew Basic Item, converted (for the Basic Items picker).
  static List<BasicItemDef> basicItemDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.basicItem &&
              e.name.trim().isNotEmpty)
            e.basicItemData.toDef(e),
      ];

  /// Homebrew-aware replacement for `basicItemByName` (official wins).
  static BasicItemDef? resolveBasicItem(String name) =>
      basicItemByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.basicItem)
          ?.let((e) => e.basicItemData.toDef(e));

  // ==========================================================================
  // Signature Advantages / Disadvantages
  // ==========================================================================

  /// Every homebrew Signature modifier of the requested polarity, converted
  /// (for the Signatures tab's Advantage/Disadvantage pickers).
  static List<SigModifierDef> sigModifierDefs({required bool disadvantages}) =>
      [
        for (final e in _entries)
          if (e.category == HomebrewCategory.signatureModifier &&
              e.name.trim().isNotEmpty &&
              e.sigModifierData.isDisadvantage == disadvantages)
            e.sigModifierData.toDef(e),
      ];

  /// Homebrew-aware replacement for `signatureModifierByName` (official
  /// wins).
  static SigModifierDef? resolveSignatureModifier(String name) =>
      signatureModifierByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.signatureModifier)
          ?.let((e) => e.sigModifierData.toDef(e));

  // ==========================================================================
  // Unique Abilities
  // ==========================================================================

  /// Every homebrew Unique Ability, converted (for the UA tab's picker).
  static List<UniqueAbilityDef> uniqueAbilityDefs() => [
        for (final e in _entries)
          if (e.category == HomebrewCategory.uniqueAbility &&
              e.name.trim().isNotEmpty)
            e.uniqueAbilityData.toDef(e),
      ];

  /// Homebrew-aware replacement for `uniqueAbilityByName` (official wins).
  static UniqueAbilityDef? resolveUniqueAbility(String name) =>
      uniqueAbilityByName(name) ??
      _byNameIn(name, (e) => e.category == HomebrewCategory.uniqueAbility)
          ?.let((e) => e.uniqueAbilityData.toDef(e));
}

/// Scoped `let` (Kotlin-style) so the lookups above stay expression-bodied.
extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
