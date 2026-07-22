/// race_traits.dart
/// ---------------------------------------------------------------------------
/// Racial Traits catalogue (Player → Races pages, Primary + Secondary Racial
/// Traits sections). Complements `RaceDef` in `dbu_rules.dart` with each
/// Race's actual Trait text, verbatim from the site
///
/// AUTOMATION: like Conditions/States (see `ConditionDef`/`StateDef` in
/// `dbu_rules.dart`), the overwhelming majority of Racial Trait effects rely
/// on mechanics this app doesn't model — bespoke stack resources with their
/// own gain/loss rules (Overwhelm, Demonic Power/Fatigue, Tension,
/// Adaptation Points, Critical Eye, Revenge Points, Negative Energy...),
/// Clashes, per-Maneuver choices, Character-Creation Options, and
/// Ally/Opponent-targeted effects — a full simulation of these is out of
/// scope for a character sheet. Only the handful of Traits whose effect is a
/// clean, unconditional (or simply-conditioned) additive bonus to a stat
/// this app already computes are auto-applied (see [RaceTraitDef.isAutomated]
/// and [RaceTraitDef.automation]); every other Trait still gets its full
/// verbatim text so the player always has the rules on hand, they just apply
/// the effect themselves — same automated-vs-not convention as the Combat
/// Conditions/States catalogues.
library;

import 'dbu_rules.dart';

/// Whether a Racial Trait is filed under Body or Mind on its Race's page.
enum TraitCategory {
  body('Body'),
  mind('Mind');

  const TraitCategory(this.displayName);
  final String displayName;
}

enum RaceTraitTier {
  primary('Primary'),
  secondary('Secondary');

  const RaceTraitTier(this.displayName);
  final String displayName;
}

/// How a Racial Trait's automated magnitude is computed. Mirrors the simple
/// per-stack shape of `StateTraitDef`/`ConditionDef` but adds the extra
/// magnitude shapes Racial Traits actually use in their verbatim text.
enum TraitMagnitudeKind {
  /// `coefficient × tierScalingValue` — an unconditional flat bonus.
  flat,

  /// `coefficient × (Health Thresholds currently below) × tierScalingValue`.
  /// Uses the RAW threshold count (regardless of Steadfast pass/fail) —
  /// distinct from `CharacterCalculator.healthThresholdPenalty`, since
  /// Racial Trait text like "for each Health Threshold you are below"
  /// applies whether or not the Steadfast Check for that threshold was
  /// passed. See `CharacterCalculator.thresholdsUnderCount`.
  perHealthThresholdBelow,

  /// `coefficient × round(AttributeModifier / fractionDenominator) × tierScalingValue`.
  fractionOfAttribute,

  /// `coefficient × Character.powerStacks × tierScalingValue` — for Traits
  /// that scale off the universal Power Resource this app already tracks.
  perPowerStack,

  /// `coefficient × floor(stacks of a same-named entry in
  /// Character.resources / fractionDenominator) × tierScalingValue` — for
  /// Traits that grant their OWN stacking Resource (Overwhelm, Demonic
  /// Power, ...). `fractionDenominator` (default 1) supports "for every 2
  /// stacks of X" wordings.
  perNamedResourceStack,

  /// `coefficient × Character.powerLevel × tierScalingValue` — for effects
  /// worded "for each Power Level reached" (e.g. the De-Aged Awakening's
  /// Ideal Condition: "Increase your Maximum Life Points and Maximum Ki
  /// Points by 2 for each Power Level reached").
  perPowerLevel,

  /// `coefficient × floor(stacks of an OWNED Transformation named by
  /// `resourceName` / fractionDenominator) × tierScalingValue` — for effects
  /// scaling off another Transformation's Stacks ("for every stack of
  /// Absorption you possess…"). `resourceName` names the Transformation for
  /// this kind.
  perNamedTransformationStack,
}

/// A computable gate on an automated effect — for effects whose verbatim text
/// is conditional, but on a condition THIS APP CAN EVALUATE from the sheet's
/// own state ("While you are in a Form or Enhancement...", "While not wearing
/// any Apparel..."). An automation entry with a condition contributes 0 while
/// the condition is unmet. Genuinely situational conditions (per-Maneuver,
/// Opponent-dependent, GM-adjudicated) stay un-automated text, as ever.
enum TraitCondition {
  /// "While you are not in a Form" — no owned Form is active.
  whileNotInForm,

  /// "While you are in a Form or Enhancement" — any owned Form or
  /// Enhancement is active.
  whileInFormOrEnhancement,

  /// "While in a Form" — any owned Form is active (Null Stages don't count,
  /// same rule as the Ki Multiplier).
  whileInForm,

  /// "While you have a Power stack" / "While you possess 2+ stacks of
  /// Power" — at least [RaceTraitAutomation.conditionAmount] (default 1)
  /// stacks of the universal Power Resource.
  whileAnyPowerStack,

  /// "While you are in the Healthy Health Threshold" — zero Health
  /// Thresholds currently below.
  whileHealthyThreshold,

  /// "While not wearing any Apparel" — no Apparel piece is Worn.
  whileNoApparelWorn,

  /// "While you possess 3 Super Stacks" (the maximum).
  whileMaxSuperStacks,

  /// While a same-named entry in `Character.states` has 1+ stacks — for
  /// effects gated on a State this app tracks by name (e.g. a Form's Exceed
  /// Trait, active "while in the Exceed State"). Set
  /// [RaceTraitAutomation.conditionStateName].
  whileNamedStateActive,

  /// While a same-named entry in `Character.resources` has at least
  /// [RaceTraitAutomation.conditionAmount] stacks ("While you have at least
  /// 1 stack of Holding Back…", "While you possess 3+ stacks of Tension…").
  /// Set [RaceTraitAutomation.conditionResourceName] + `conditionAmount`.
  /// The name 'Holding Back' additionally resolves against the sheet's
  /// dedicated Holding Back tracker (`Character.holdingBackStacks`) — see
  /// `CharacterCalculator.namedResourceStacks` — so both this condition and
  /// `TraitMagnitudeKind.perNamedResourceStack` automate Holding-Back-
  /// dependent effects (catalogue and homebrew alike) with no extra enum.
  whileNamedResourceAtLeast,

  /// "While below the Bruised Health Threshold" — 1+ Health Thresholds
  /// currently under (Life < 50% of Max).
  whileBelowBruisedThreshold,

  /// "While below the Injured Health Threshold" — 2+ Health Thresholds
  /// currently under (Life < 25% of Max).
  whileBelowInjuredThreshold,

  /// While a same-named entry in `Character.conditions` has 1+ stacks
  /// ("While suffering from the Compelled Combat Condition…"). Set
  /// [RaceTraitAutomation.conditionStateName] (shared with
  /// [whileNamedStateActive] — the two conditions read different lists).
  whileNamedConditionActive,

  /// While a specific owned Transformation is ACTIVE ("While in Wrathful…").
  /// Set [RaceTraitAutomation.conditionTransformationName].
  whileNamedTransformationActive,

  /// While ANY owned Form/Enhancement with the named Aspect is ACTIVE
  /// ("While in a Form with the Super Saiyan Form Aspect…"). Set
  /// [RaceTraitAutomation.conditionAspectName] — matched as a prefix against
  /// the Transformation's raw aspect labels (so `'Super Saiyan Form'`
  /// matches `'Super Saiyan Form'` and levelled variants).
  whileFormWithAspectActive,

  /// "While you are not suffering from any Health Threshold Penalties" —
  /// every currently-under Threshold had its Steadfast Check passed (or none
  /// are under).
  whileNoHealthThresholdPenalties,
}

/// A single automated numeric effect of a Racial Trait.
class RaceTraitAutomation {
  const RaceTraitAutomation({
    required this.affectedStats,
    required this.coefficient,
    this.tierScaling = TierScaling.none,
    this.kind = TraitMagnitudeKind.flat,
    this.attribute,
    this.fractionDenominator = 1,
    this.roundUp = false,
    this.resourceName,
    this.condition,
    this.conditionStateName,
    this.conditionResourceName,
    this.conditionAmount = 1,
    this.conditionTransformationName,
    this.conditionAspectName,
    this.perTransformationStack = false,
    this.perTransformationGrade = false,
    this.twinned = false,
  });

  final List<AffectedStat> affectedStats;
  final int coefficient;
  final TierScaling tierScaling;
  final TraitMagnitudeKind kind;

  /// Used only by [TraitMagnitudeKind.fractionOfAttribute].
  final DbuAttribute? attribute;
  final int fractionDenominator;
  final bool roundUp;

  /// Used only by [TraitMagnitudeKind.perNamedResourceStack] — matched
  /// case-insensitively against a `TrackedEntry.name` in
  /// `Character.resources`.
  final String? resourceName;

  /// A computable gate — this entry contributes 0 while the condition is
  /// unmet (see [TraitCondition]). Null = unconditional.
  final TraitCondition? condition;

  /// Used only by [TraitCondition.whileNamedStateActive] — matched
  /// case-insensitively against a `TrackedEntry.name` in `Character.states`.
  final String? conditionStateName;

  /// Used only by [TraitCondition.whileNamedResourceAtLeast] — matched
  /// case-insensitively against a `TrackedEntry.name` in
  /// `Character.resources`.
  final String? conditionResourceName;

  /// Used only by [TraitCondition.whileNamedResourceAtLeast] — the minimum
  /// number of stacks required.
  final int conditionAmount;

  /// Used only by [TraitCondition.whileNamedTransformationActive] — matched
  /// case-insensitively against an owned Transformation's name.
  final String? conditionTransformationName;

  /// Used only by [TraitCondition.whileFormWithAspectActive] — matched as a
  /// case-insensitive prefix against an active Transformation's aspect
  /// labels.
  final String? conditionAspectName;

  /// Transformation Traits only: multiply the magnitude by the Awakening's
  /// current number of Stacks (the site's `Z` — e.g. "increase your Wound
  /// Rolls, Surgency, and Soak Value by Z(bT)"). Ignored for Racial
  /// Traits/Talents (they have no stack context).
  final bool perTransformationStack;

  /// Transformation Traits only: multiply the magnitude by the
  /// Transformation's current Grade (the site's `G` — Graded Enhancements
  /// like Kaioken/Lightspeed Mode). `fractionDenominator` divides the Grade
  /// first ("1/2 (rounded up) of G(T)" → `fractionDenominator: 2,
  /// roundUp: true`). Ignored outside the Transformation pipeline.
  final bool perTransformationGrade;

  /// Custom Species only: this automation entry is a **`[Twinned]`** effect —
  /// it applies only when the Trait is one of the character's 2 **Primary**
  /// (Twinned) Custom Species Traits. Base (non-Twinned) entries always apply.
  /// `CharacterCalculator.activeRaceTraits` strips Twinned entries from a
  /// Secondary Trait's copy so the automation pipeline needs no per-entry
  /// gating (see `customSpeciesActiveTraits`).
  final bool twinned;

  // --- JSON (de)serialization ----------------------------------------------
  // Added so player-authored HOMEBREW can persist and share the very same
  // automation objects the calculator consumes (see `models/homebrew.dart`).
  // Only non-default fields are written, keeping share codes compact; parsing
  // is tolerant of unknown enum names (they're dropped) so a code made by a
  // newer build still loads.

  /// Resolves an enum value by its `.name`, or null if absent/not a String.
  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'affectedStats': affectedStats.map((s) => s.name).toList(),
        'coefficient': coefficient,
        if (tierScaling != TierScaling.none) 'tierScaling': tierScaling.name,
        if (kind != TraitMagnitudeKind.flat) 'kind': kind.name,
        if (attribute != null) 'attribute': attribute!.name,
        if (fractionDenominator != 1) 'fractionDenominator': fractionDenominator,
        if (roundUp) 'roundUp': true,
        if (resourceName != null) 'resourceName': resourceName,
        if (condition != null) 'condition': condition!.name,
        if (conditionStateName != null) 'conditionStateName': conditionStateName,
        if (conditionResourceName != null)
          'conditionResourceName': conditionResourceName,
        if (conditionAmount != 1) 'conditionAmount': conditionAmount,
        if (conditionTransformationName != null)
          'conditionTransformationName': conditionTransformationName,
        if (conditionAspectName != null)
          'conditionAspectName': conditionAspectName,
        if (perTransformationStack) 'perTransformationStack': true,
        if (perTransformationGrade) 'perTransformationGrade': true,
        if (twinned) 'twinned': true,
      };

  factory RaceTraitAutomation.fromJson(Map<String, dynamic> json) {
    final stats = ((json['affectedStats'] as List?) ?? const [])
        .map((n) => _enumByName(AffectedStat.values, n))
        .whereType<AffectedStat>()
        .toList();
    return RaceTraitAutomation(
      affectedStats: stats,
      coefficient: (json['coefficient'] as num?)?.toInt() ?? 0,
      tierScaling:
          _enumByName(TierScaling.values, json['tierScaling']) ??
              TierScaling.none,
      kind: _enumByName(TraitMagnitudeKind.values, json['kind']) ??
          TraitMagnitudeKind.flat,
      attribute: _enumByName(DbuAttribute.values, json['attribute']),
      fractionDenominator:
          (json['fractionDenominator'] as num?)?.toInt() ?? 1,
      roundUp: json['roundUp'] as bool? ?? false,
      resourceName: json['resourceName'] as String?,
      condition: _enumByName(TraitCondition.values, json['condition']),
      conditionStateName: json['conditionStateName'] as String?,
      conditionResourceName: json['conditionResourceName'] as String?,
      conditionAmount: (json['conditionAmount'] as num?)?.toInt() ?? 1,
      conditionTransformationName:
          json['conditionTransformationName'] as String?,
      conditionAspectName: json['conditionAspectName'] as String?,
      perTransformationStack:
          json['perTransformationStack'] as bool? ?? false,
      perTransformationGrade:
          json['perTransformationGrade'] as bool? ?? false,
      twinned: json['twinned'] as bool? ?? false,
    );
  }
}

/// A Resource a Racial Trait (or a specific chosen [TraitOption] within one)
/// grants access to — e.g. Saiyan's Battle Born, Arcosian's Overwhelm,
/// Demon's Demonic Power/Fatigue. This app can't automate GAINING/LOSING
/// stacks of these (that needs full combat-round simulation), but it CAN
/// make sure a tracker for them exists on the Character page the moment the
/// Trait (or Option) becomes active — see
/// `services/race_resource_sync.dart`'s `ensureRaceGrantedResources`.
class GrantedResource {
  const GrantedResource({
    required this.name,
    required this.maxStacks,
    required this.description,
  });

  /// Matched against `TrackedEntry.name` in `Character.resources` — must
  /// stay in sync with any `RaceTraitAutomation.resourceName` that reads it.
  final String name;

  /// max where the site states one; otherwise a generous cap is
  /// used and noted in [description]
  final int maxStacks;

  final String description;
}

/// Whether a granted flesh-Trait comes from the Bestial Traits catalogue or
/// the Monstrous Traits catalogue (both live in `beast_traits.dart`).
enum BeastTraitKind {
  bestial('Bestial Trait'),
  monstrous('Monstrous Trait');

  const BeastTraitKind(this.displayName);
  final String displayName;
}

/// A "gain N Bestial/Monstrous Trait(s)" effect on a Trait or Option. Rendered
/// as an inline multi-select against the relevant catalogue; the player's
/// picks are stored in `Character.beastTraitChoices` (keyed by the grant's
/// stable key — see `CharacterCalculator.beastTraitGrantKey`) and their clean
/// additive effects are auto-applied exactly like a Racial Trait's.
class BeastTraitGrant {
  const BeastTraitGrant({
    required this.kind,
    this.count = 1,
    this.restrictedTo = const [],
    this.restrictedToTraitPicks,
    this.fixed = const [],
    this.label,
    this.twinned = false,
    this.condition,
  });

  final BeastTraitKind kind;

  /// If set, the choices are limited to the beast Traits the player already
  /// picked for the named Trait's grant(s) — a cross-Trait dependency (e.g.
  /// "Beyond a Demon God": "select a Bestial Trait you selected for the 1st
  /// effect of True Power of a Demon God"). Resolved live from every
  /// selection's picks via `CharacterCalculator.beastPicksForTrait`; takes
  /// precedence over [restrictedTo].
  final String? restrictedToTraitPicks;

  /// A computable gate — this grant's selected Trait(s) contribute their
  /// automation ONLY while the condition is met (e.g. Bestial Transfiguration's
  /// access "while you are in a Form or Enhancement"). The picker still renders
  /// so the choice persists; only the effect is suppressed while unmet.
  /// Supports the Form/Enhancement-presence conditions (see
  /// `CharacterCalculator.beastGrantConditionMet`); other conditions are
  /// treated as always-met.
  final TraitCondition? condition;

  /// Custom Species only: this grant is a `[Twinned]` effect — it applies only
  /// when the Trait is one of the character's 2 **Primary** (Twinned) Custom
  /// Species Traits. `RaceTraitDef.baseOnly()` strips Twinned grants from a
  /// Secondary Trait's copy. Ignored for official Traits.
  final bool twinned;

  /// How many Traits the player selects for this grant.
  final int count;

  /// If non-empty, the choices are limited to these catalogue names (e.g. Neko
  /// Majin's Feline Build — "Bestial Build, Land-Based Beast, Claws, or
  /// Fangs"). Empty = the whole catalogue for [kind].
  final List<String> restrictedTo;

  /// Specific catalogue names granted with NO choice (e.g. Android's Extension
  /// Feature — "You possess the Extension Attack Monstrous Trait"). These are
  /// always active while the grant is, and shown read-only.
  final List<String> fixed;

  /// Optional override for the picker's heading (defaults to a sentence built
  /// from [count]/[kind]).
  final String? label;

  bool get isFixed => count == 0 && fixed.isNotEmpty;
}

/// A single Character-Creation choice offered by a Racial Trait (`[Option]`
/// tag = pick 1, `[Multi-Option/N]` = pick up to N — see
/// [RaceTraitOptionGroup.maxChoices]).
class TraitOption {
  const TraitOption({
    required this.name,
    required this.description,
    this.grantedResources = const [],
    this.automation = const [],
    this.ambPerTierBonus = const {},
    this.ambFlatBonus = const {},
    this.optionGroups = const [],
    this.beastGrants = const [],
  });

  final String name;
  final String description;

  /// Resources granted ONLY when this specific Option is chosen (as opposed
  /// to `RaceTraitDef.grantedResources`, granted just by having the Trait).
  final List<GrantedResource> grantedResources;

  /// Clean additive automation applied ONLY while this Option is the chosen
  /// one (e.g. Class Up's Hero/Elite/Berserker Class Selection: "[Passive]:
  /// Increase your Dodge Rolls and Soak Value by 1(T)"). Same machinery as
  /// the Trait-level [RaceTraitDef.automation].
  final List<RaceTraitAutomation> automation;

  /// Attribute Modifier Bonus granted ONLY while this Option is chosen (and,
  /// for a Transformation Trait Option, while the Transformation is in
  /// effect), keyed Attribute → per-Tier-of-Power coefficient (a `+N(T)` AMB,
  /// e.g. Burst Aura's "Increase the AMB (FO/MA) by 1(T)"). Fed into
  /// `CharacterCalculator.transformationModifierBonus`.
  final Map<DbuAttribute, int> ambPerTierBonus;

  /// A **flat** (non-Tier-scaled) Attribute Modifier Bonus granted while this
  /// Option is chosen, keyed Attribute → `+N`. Used by Awakenings whose AMB is
  /// flat rather than `(T)` — e.g. Swapping Expert's "select an Attribute
  /// (except FO/MA); increase this Transformation's AMB for it by +1". Added
  /// once (not ×Stacks) in `transformationModifierBonus`.
  final Map<DbuAttribute, int> ambFlatBonus;

  /// Further choice(s) nested inside this Option — a "select one" that only
  /// appears once this Option is chosen (e.g. Boosting Aura's "select an
  /// Attribute (AG or TE)"). Rendered as a sub-dropdown; the chosen nested
  /// Option's own `automation`/`ambPerTierBonus` apply. Choices are keyed
  /// `"<parentKey>::<thisOptionName>::<nestedGroupLabel>"`.
  final List<RaceTraitOptionGroup> optionGroups;

  /// Bestial/Monstrous Trait grants that apply ONLY while this Option is the
  /// chosen one (e.g. Arcosian's Bestial Evolution — "Select and gain a
  /// Bestial Trait"). See `BeastTraitGrant`.
  final List<BeastTraitGrant> beastGrants;
}

/// One Character-Creation choice point within a Racial Trait. A single
/// Trait can have more than one of these (e.g. Android's Technological Being
/// has both a 2-way [Option] AND an 11-way [Multi-Option/2]), so they're
/// modeled as a list on `RaceTraitDef` rather than flattened onto it.
class RaceTraitOptionGroup {
  const RaceTraitOptionGroup({
    required this.label,
    required this.options,
    this.maxChoices = 1,
  });

  /// Short label shown above the picker, e.g. "Option" or "Choose 2".
  final String label;
  final List<TraitOption> options;

  /// 1 for a plain `[Option]` tag; N for a `[Multi-Option/N]` tag.
  final int maxChoices;
}

/// A `[Choice]` effect that lives on THIS Trait but whose actual bonus
/// depends on the Option the player picked for a DIFFERENT Trait (e.g.
/// Earthling's Eye of the Dragon effect (3) reads "Depending on your choice
/// for the Option effect of Quick to Master..." — the full text for every
/// branch is printed on Eye of the Dragon's own page, not on Quick to
/// Master's). [textByOption] holds the complete text for every branch (so
/// the Trait's full original text is always available even before a choice
/// is made); the Information page looks up the player's actual choice on
/// [sourceTraitName]/[sourceGroupLabel] and highlights the matching branch.
class DependentChoice {
  const DependentChoice({
    required this.sourceTraitName,
    required this.sourceGroupLabel,
    required this.textByOption,
  });

  /// The OTHER Trait whose Option this Choice depends on.
  final String sourceTraitName;

  /// The Option group's label on that other Trait (matches
  /// `RaceTraitOptionGroup.label`).
  final String sourceGroupLabel;

  /// Option name → the full effect text that applies if the player chose
  /// that Option on the source Trait.
  final Map<String, String> textByOption;
}

/// A single Primary or Secondary Racial Trait.
class RaceTraitDef {
  const RaceTraitDef({
    required this.race,
    required this.tier,
    required this.category,
    required this.name,
    required this.description,
    this.automation = const [],
    this.optionGroups = const [],
    this.trailingText = '',
    this.grantedResources = const [],
    this.dependentChoice,
    this.subrace = '',
    this.beastGrants = const [],
  });

  /// Which Race this Trait belongs to (matches `RaceDef.name`).
  final String race;

  /// If non-empty, this Trait is granted by (and only active with) the named
  /// **Subrace** of [race] — see `kDbuSubraces` / `subraceTraitsFor`. Five
  /// Races have Subraces on the site (Namekian, Demon, Glass Tribe,
  /// Neo-Tuffle, Yardrat); picking one grants exactly this extra Racial Trait.
  /// Base (non-Subrace) Traits leave this `''` and are returned by
  /// `raceTraitsFor`; Subrace Traits are filtered out of that list and only
  /// merged into `CharacterCalculator.activeRaceTraits` when the character's
  /// `Character.subrace` matches.
  final String subrace;

  /// Bestial/Monstrous Traits this Trait grants access to — rendered as an
  /// inline picker on the Trait's card (see `beast_traits.dart`,
  /// `Character.beastTraitChoices`). Unconditional grants from the Trait
  /// itself; per-Option grants live on `TraitOption.beastGrants` instead.
  final List<BeastTraitGrant> beastGrants;
  final RaceTraitTier tier;
  final TraitCategory category;
  final String name;

  /// Verbatim flavour text + numbered effects from the Race's own page, up
  /// to (and including the intro sentence of) any `[Option]`/`[Multi-
  /// Option]` block.
  final String description;

  final List<RaceTraitAutomation> automation;

  /// Character-Creation choice(s) offered by this Trait — see
  /// `RaceTraitOptionGroup`. Rendered as a dropdown (single choice) or a
  /// multi-select (Multi-Option) on the Information page.
  final List<RaceTraitOptionGroup> optionGroups;

  /// Verbatim numbered effects that come AFTER the `[Option]` block on the
  /// Race's own page (several Traits keep listing plain Passive/Triggered
  /// effects once the Option choice is done) — rendered below the option
  /// picker(s) so the on-screen order matches the site's.
  final String trailingText;

  /// A `[Choice]` effect on THIS Trait whose actual text depends on an
  /// Option chosen for a different Trait — see `DependentChoice`.
  final DependentChoice? dependentChoice;

  /// Resources granted just by having this Trait active (unconditional on
  /// any Option pick) — see `GrantedResource`.
  final List<GrantedResource> grantedResources;

  bool get isAutomated =>
      automation.isNotEmpty ||
      optionGroups
          .any((g) => g.options.any((o) => o.automation.isNotEmpty));

  bool get hasOptions => optionGroups.isNotEmpty;

  /// Whether any automation entry is a `[Twinned]` effect (Custom Species).
  bool get hasTwinnedAutomation => automation.any((a) => a.twinned);

  /// Whether any numbered effect in the verbatim text carries the `[Twinned]`
  /// keyword — i.e. this Trait has effects a Secondary Trait does not possess.
  bool get hasTwinnedText =>
      _hasTwinnedLine(description) || _hasTwinnedLine(trailingText);

  /// Whether this Trait has ANY `[Twinned]` content (text and/or automation).
  bool get hasTwinnedEffects => hasTwinnedAutomation || hasTwinnedText;

  /// A copy of this Trait with its `[Twinned]` content removed — both the
  /// automation entries and the verbatim `[Twinned]`-keyword effect lines,
  /// since a **Secondary** Custom Species Trait does not possess them at all.
  /// If there is no Twinned content, returns `this` unchanged.
  RaceTraitDef baseOnly() {
    if (!hasTwinnedEffects) return this;
    return RaceTraitDef(
      race: race,
      tier: tier,
      category: category,
      name: name,
      description: _stripTwinnedLines(description),
      automation: automation.where((a) => !a.twinned).toList(),
      optionGroups: optionGroups,
      trailingText: _stripTwinnedLines(trailingText),
      grantedResources: grantedResources,
      dependentChoice: dependentChoice,
      subrace: subrace,
      beastGrants: beastGrants.where((g) => !g.twinned).toList(),
    );
  }
}

/// Matches a numbered effect's leading keyword block, e.g. `(4)-[Passive,
/// Twinned]:` — group 1 is the comma-separated keyword list.
final RegExp _effectKeywords = RegExp(r'^\(\d+\)-\[([^\]]*)\]');

bool _lineIsTwinned(String line) {
  final m = _effectKeywords.firstMatch(line.trimLeft());
  if (m == null) return false;
  return m
      .group(1)!
      .split(',')
      .any((k) => k.trim().toLowerCase() == 'twinned');
}

bool _hasTwinnedLine(String text) =>
    text.split('\n').any(_lineIsTwinned);

/// Drops every `[Twinned]`-keyword effect line from a verbatim effect text,
/// leaving the flavour text and base effects untouched.
String _stripTwinnedLines(String text) {
  if (text.isEmpty) return text;
  return text
      .split('\n')
      .where((l) => !_lineIsTwinned(l))
      .join('\n')
      .trimRight();
}

/// The full Primary + Secondary Racial Trait catalogue for all 18 Races
/// (Custom Species instead uses freeform Racial Trait selection — see
/// `Character.customRaceTraits`). automated effects (verbatim):
///   • Saiyan — Blood of the Warrior: "For each Health Threshold you are
///     below, increase your Wound Rolls, Soak Value and Surgency ... by
///     1(T)".
///   • Saiyan — Powerful Physique: "Increase your Soak Value by 1/4 of your
///     Force Modifier (rounded up)."
///   • Earthling — Earthling Resolve: "For each Health Threshold you are
///     below, increase your Strike and Wound Rolls by 1(T)."
///   • Heran — Greed of the Hera: "Each stack of Power you possess increases
///     your Soak Value by 1(T)" (uses the existing `Character.powerStacks`
///     field directly).
///   • Majin — Rubbery Body: "Increase your Soak Value and Defense Value by
///     1(T)."
///   • Arcosian — Overwhelming Fighter: "For each stack of Overwhelm,
///     increase your Wound Rolls by 1(T)" (player must track an "Overwhelm"
///     Resource entry themselves; the stat bonus per stack is automatic).
///   • Demon — Demonic Pressure: "For each stack of Demonic Power, increase
///     your Wound Rolls by 2(T)" / "For each stack of Demonic Fatigue,
///     reduce your Defense Value and Soak Value by 1(T)" (same Resource-
///     tracking caveat as Overwhelm above).
/// The 19 Arcosian **Evolution Traits** (Arcosians page), selectable via the
/// Overwhelming Fighter Racial Trait (and, per Stage — multi-select — by the
/// Metamorphosis line). Effects verbatim; the numeric always-on `[Passive]`
/// effects that map
/// onto a stat the buffs pipeline computes are automated (Last Resource,
/// Perfect Warrior). Skill/Ki-Cost/Size/Maneuver-granting effects are shown as
/// text (those channels aren't yet fed by Trait automation).
const List<TraitOption> kArcosianEvolutionTraits = [
  TraitOption(
    name: 'Aerodynamic',
    description: '(1)-[Passive]: Treat your Size Category as 1 Category lower '
        'for the Size bonus/penalty to your Defense Value.\n'
        '(2)-[Passive]: Reduce the Ki Point Cost for using your Boosted Speed '
        'through the Movement Maneuver by 2(T).\n'
        '(3)-[Triggered]: If you dodge an Attacking Maneuver, gain a stack of '
        'Overwhelm.',
  ),
  TraitOption(
    name: 'Balance of Magic and Might',
    description: '(1)-[Passive]: While your Force and Magic Scores are equal, '
        'increase your Wound Rolls by 1(T).\n'
        '(2)-[Triggered/Start of Turn]: If your Force and Magic Scores are '
        'equal, gain a stack of Overwhelm.',
  ),
  TraitOption(
    name: 'Bestial Evolution',
    description: '(1)-[Passive]: Select and gain a Bestial Trait of your '
        'choice while you have this Evolution Trait.',
    beastGrants: [BeastTraitGrant(kind: BeastTraitKind.bestial)],
  ),
  TraitOption(
    name: 'Bio-Suit',
    description: '(1)-[Passive]: Increase the Apparel Bonus of your Plating by '
        '1(T).\n'
        '(2)-[Triggered]: If you are hit by an Attacking Maneuver and take no '
        'Damage, gain a stack of Overwhelm.',
  ),
  TraitOption(
    name: 'Burning Hatred',
    description: '(1)-[Triggered/Start of Combat Round, Ruling]: Select an '
        "Opponent — your 'Enemy'. You gain the Compelled Combat Condition "
        'against your Enemy until the end of the Combat Round.\n'
        '(2)-[Passive]: Increase your Wound Rolls against your Enemy by 3(T).\n'
        '(3)-[Triggered]: If you Defeat your Enemy or knock them through a '
        'Health Threshold, maximize your stacks of Overwhelm.',
  ),
  TraitOption(
    name: 'Comfortable Count',
    description: '(1)-[Triggered/Start of Turn, Resource]: If in the Spectator '
        'State, gain a stack of Comfort.\n'
        '(2)-[Triggered, 1/Round]: If you gain a Comfort stack, regain 3(bT) '
        'Life and Ki Points.\n'
        '(3)-[Triggered, 1/Round]: If you leave the Spectator State, you may '
        'exchange all Comfort stacks for Overwhelm stacks (excess lets you '
        'Power Up / Transform Out-of-Sequence).',
  ),
  TraitOption(
    name: 'Elongated Tail',
    description: '(1)-[Triggered]: When using the Tail Attack Maneuver, +1 '
        'Square Melee Range (or +1 per Category above Large).\n'
        '(2)-[Triggered, 1/Round]: On a Tail Attack hit, forgo the Overwhelm '
        'stack to Grapple that Opponent Out-of-Sequence.\n'
        '(3)-[Triggered, 1/Round]: If you enter a Grapple as the Grappler, '
        'maximize your Overwhelm stacks.',
  ),
  TraitOption(
    name: 'Frigid Tricks',
    description: '(1)-[Passive]: Reduce the Ki Point Cost of all Unique '
        'Abilities by 2(T).\n'
        '(2)-[Passive]: Increase the Dice Score of any Clash you make through '
        'a Unique Ability using your Might or Saving Throws by 1(T).\n'
        '(3)-[Triggered, 1/Round]: If you use a Unique Ability, gain a stack '
        'of Overwhelm.',
    automation: [
      // (1) −2(T) Ki Point Cost of all Unique Abilities.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.kiCostUniqueAbilities],
        coefficient: -2,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  TraitOption(
    name: 'Furious Onslaught',
    description: '(1)-[1/Round]: Reduce your Overwhelm stacks by 2 to use the '
        'Signature Technique Maneuver as an Instant Maneuver.\n'
        '(2)-[Triggered, 1/Round]: If you Defeat an Opponent with an Attacking '
        'Maneuver, maximize your Overwhelm stacks.',
  ),
  TraitOption(
    name: "King's Stature",
    description: '(1)-[Passive]: Your base Size Category becomes Enormous.\n'
        '(2)-[Triggered, 1/Round]: If hit by a smaller Opponent, +1(T) Soak '
        'per Size Category they are smaller for that Maneuver.\n'
        '(3)-[Triggered/Start of Turn]: If you have the highest Size Category '
        'in the Encounter, gain a stack of Overwhelm.',
    automation: [
      // (1) base Size Category becomes Enormous (index 4) — +2 from Medium,
      // the Arcosian default (shifts the effective Size Category).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.sizeCategory],
        coefficient: 2,
        tierScaling: TierScaling.none,
      ),
    ],
  ),
  TraitOption(
    name: 'Last Resource',
    description: '(1)-[Passive]: Increase your Wound Rolls by 1(T) for each '
        'Health Threshold you are below.\n'
        '(2)-[Triggered/Threshold]: Maximize your stacks of Overwhelm.\n'
        '(3)-[Triggered, 1/Encounter]: Below Injured, you may apply Energy '
        'Charges up to your Overwhelm stacks to an Attacking Maneuver (then '
        'lose that many stacks).',
    automation: [
      // (1) +1(T) Wound Rolls per Health Threshold below.
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  TraitOption(
    name: 'Majestic Grace',
    description: '(1)-[Passive]: Gain access to the Hype Maneuver. If you '
        'already had it, increase your Personality Modifier by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use the Hype Maneuver, gain a stack '
        'of Overwhelm.',
  ),
  TraitOption(
    name: 'Perfect Warrior',
    description: '(1)-[Passive]: While you are in the Healthy Health '
        'Threshold, increase your Defense Value and Soak Value by 1(T).\n'
        '(2)-[Triggered/Start of Turn]: If in the Healthy Health Threshold, '
        'gain a stack of Overwhelm.',
    automation: [
      // (1) While Healthy: +1(T) Defense Value and Soak Value.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue, AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
        condition: TraitCondition.whileHealthyThreshold,
      ),
    ],
  ),
  TraitOption(
    name: 'Redirected Energy',
    description: '(1)-[Triggered]: On gaining an Overwhelm stack, regain 2(bT) '
        'Ki Points.\n'
        '(2)-[Triggered, 1/Round]: On hitting an Opponent, you may reduce your '
        'Overwhelm stacks by 1 to regain Ki equal to ½ of that Maneuver\'s Ki '
        'Point Cost.',
  ),
  TraitOption(
    name: 'Ruler',
    description: '(1)-[Passive]: No limit to Minions possessed (up to 10 in a '
        'Combat Encounter at once).\n'
        '(2)-[Triggered]: If a Minion hits and damages an Opponent, gain a '
        'stack of Overwhelm.\n'
        '(3)-[Triggered/Power, 1/Round]: Spend 2 Overwhelm stacks to give '
        'Allies in a Large Sphere AoE +1(T) Soak and Combat Rolls until your '
        'next turn.',
  ),
  TraitOption(
    name: 'Searing Anger',
    description: '(1)-[Passive]: Gain access to the Seething Fury '
        'Enhancement.\n'
        '(2)-[Passive]: Reduce the Stress Test Requirement for Seething Fury '
        'by 2.\n'
        '(3)-[Triggered, 1/Round]: On hitting an Opponent while Raging, double '
        'your Overwhelm-stack Wound bonus for that Maneuver (then set Overwhelm '
        'to 1).\n'
        '(4)-[Triggered/Raging]: Maximize your Overwhelm stacks.',
  ),
  TraitOption(
    name: 'Stealthy Trick',
    description: '(1)-[Passive]: Increase the Dice Score of your Stealth Skill '
        'Checks by 2.\n'
        '(2)-[Triggered, 1/Round]: If you win a Clash using your Stealth '
        'Skill, gain a stack of Overwhelm.\n'
        '(3)-[Triggered, 1/Round]: If you hit an Oblivious Character, +1(T) '
        'Wound against them per 2 Overwhelm stacks.',
    automation: [
      // (1) +2 Stealth Skill Checks (flat, not Tier-scaled).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.skillStealth],
        coefficient: 2,
        tierScaling: TierScaling.none,
      ),
    ],
  ),
  TraitOption(
    name: 'Studied Lord',
    description: '(1)-[Passive]: Gain access to the Analysis Maneuver. If you '
        'already had it, increase your Scholarship Modifier by 1(T).\n'
        '(2)-[Triggered, 1/Round]: If you use the Analysis Maneuver, gain a '
        'stack of Overwhelm.',
  ),
  TraitOption(
    name: 'Terrifying Pressure',
    description: '(1)-[Passive]: Gain access to the Terrify Maneuver. If you '
        'already had it, increase your Intimidation Skill Checks by 2.\n'
        '(2)-[Triggered, 1/Round]: If you win the Terrify Clash against an '
        'Opponent, gain a stack of Overwhelm.\n'
        '(3)-[Triggered, 1/Encounter]: If you inflict Shaken on an Opponent, '
        'you may enter the Superior State until the end of your next turn.',
  ),
];

/// The Arcosian **Survivor** Option (Arcosians page, Survivor Trait effect (2)):
/// choose one Plating effect. Also re-choosable per Stage of Metamorphosis. All
/// four scale off *the Plating's Apparel Bonus* (an apparel-specific value, not a
/// flat channel), so they're surfaced as verbatim text rather than auto-applied.
const List<TraitOption> kArcosianSurvivorOptions = [
  TraitOption(
    name: 'Dense Plating',
    description: "[Passive]: Increase your Soak Value by 1/2 (rounded up) "
        "of your Plating's Apparel Bonus.",
  ),
  TraitOption(
    name: 'Sleek Plating',
    description: "[Passive]: Increase your Defense Value by 1/2 (rounded up) "
        "of your Plating's Apparel Bonus.",
  ),
  TraitOption(
    name: 'Power Plating',
    description: "[Passive]: Increase your Wound Rolls by your Plating's "
        "Apparel Bonus.",
  ),
  TraitOption(
    name: 'Combat Plating',
    description: '[Passive]: Your Plating gains the Armed Quality without '
        'occupying a Quality Slot.',
  ),
];

const List<RaceTraitDef> kDbuRaceTraits = [
  // =========================================================== Android ===
  RaceTraitDef(
    race: 'Android',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Technological Being',
    description:
        "Created by or enhanced by technology, Androids aren't natural "
        "entities- or at least, not entirely.\n"
        "(1)-[Passive]: While in the Healthy Health Threshold, increase your "
        "Damage Reduction by 1(T).\n"
        "(2)-[Option]: At Character Creation, choose one of the following "
        "effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Enhanced Organism',
            description: '[Passive]: Gain the Alternate Upbringing '
                'Factor, ignoring its Racial Requirements. You must '
                'exchange the Functional Purpose Racial Trait for the '
                'Factor Trait. Additionally, increase your Racial Life '
                'Modifier by 2 and select an additional Saving Throw to '
                'apply your Racial Saving Throw Bonus to.',
          ),
          TraitOption(
            name: 'Construct',
            description: '[Passive]: Ignore the penalties for the '
                'Bruised or Injured Health Thresholds, but reduce your '
                'Steadfast Checks by 3 for the Critical Health Threshold '
                'and double its penalties. Double the increase to your '
                'Maximum Life Points from the effects of Talents. You '
                'are Unnatural.',
          ),
        ],
      ),
      RaceTraitOptionGroup(
        label: 'Multi-Option',
        maxChoices: 2,
        options: [
          TraitOption(
            name: 'Surging Power',
            description: '[Triggered/Power]: Spend 3(bT) Ki Points to '
                'gain an additional stack of Power.',
          ),
          TraitOption(
            name: 'Weapon Ports',
            description: '[Passive, Ruling]: At Character Creation, '
                'create 2 Weapons with a Craftsmanship Grade of 2 that '
                'have different Weapon Types. These Weapons possess the '
                'Artisan Weapon Quality (1 Slot). These Weapons are '
                "known as your 'Installed Weapons', are Integrated into "
                'your Character, and cannot be destroyed through any '
                'means.',
          ),
          TraitOption(
            name: 'Power Absorption',
            description: '[Passive]: You gain access to the Power '
                'Drain and Attack Absorption Special Maneuvers.',
          ),
          TraitOption(
            name: 'Hyper Resilience',
            description: '[Triggered, 2/Round]: If you take less '
                'Damage than 1/2 of your Soak Value from an Attacking '
                'Maneuver, you take no Damage.',
          ),
          TraitOption(
            name: 'Enhanced Reflexes',
            description: '[Triggered, 1/Round]: When you are the '
                'target of an Attacking Maneuver, you may choose to '
                'ignore all of your stacks of Diminishing Defense '
                'against that Attacking Maneuver. If you possess no '
                'stacks of Diminishing Defense, then apply your Greater '
                'Dice to this Dodge Roll.',
          ),
          TraitOption(
            name: 'Weapon Style',
            description: '[Passive]: You gain the Weapon Specialist '
                'Talent, and when creating any type of Signature '
                'Technique, you may add the Weapon Assisted Advantage '
                'to that Signature Technique without spending Technique '
                'Points.',
          ),
          TraitOption(
            name: 'Heroic Style',
            description: '[Triggered]: Increase your Combat Rolls by '
                '1(T) until the end of your turn when you use the Hype '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Calculating Style',
            description: '[Triggered]: Increase your Combat Rolls by '
                '1(T) until the end of your turn when you use the '
                'Analysis Maneuver.',
          ),
          TraitOption(
            name: 'Alternate Scale Structure',
            description: '[Passive]: Upon gaining this effect, select '
                'either the Tiny Size Category or the Enormous Size '
                'Category. That selected Size Category becomes your '
                'base Size Category. Additionally, if you choose Tiny, '
                'increase your Soak Value by 1(T) and if you choose '
                'Enormous, increase your Defense Value by 1(T).',
          ),
          TraitOption(
            name: 'Extension Feature',
            description: '[Passive]: You possess the Extension Attack '
                'Monstrous Trait.',
            beastGrants: [
              BeastTraitGrant(
                kind: BeastTraitKind.monstrous,
                count: 0,
                fixed: ['Extension Attack'],
              ),
            ],
          ),
          TraitOption(
            name: 'Magical Machine',
            description: '[Passive]: Reduce the TP Cost of all Unique '
                'Abilities by 3 and gain access to the Magical '
                'Materialization and Telekinesis Unique Abilities. Upon '
                'gaining this effect, you may replace the bonus to your '
                'Force Attribute Score from your Racial Attribute Score '
                'Increase with a bonus to your Magic Attribute Score.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Android',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Energy Core',
    description:
        "Powered by an internal core of some variety, Androids' bodies are "
        "fueled by an inorganic energy source that grants them special "
        "abilities.\n"
        "(1)-[Passive]: Any Traits, Maneuvers, or effects used by other "
        "Characters cannot reduce your Ki Points.\n"
        "(2)-[Passive]: You automatically succeed any Concealment Skill "
        "Checks, even if you have no Skill Ranks in Concealment.\n"
        "(3)-[Passive]: If you've already used the Energy Charge Maneuver "
        "once during this Combat Round, reduce the Ki Point Cost for the "
        "Energy Charge Maneuver by 1(T).\n"
        "(4)-[Option]: Upon gaining access to this Trait, choose one of "
        "the following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Infinite Energy',
            description: '[Triggered/Start of Combat Round]: Regain '
                '4(bT) Ki Points.\n'
                '[Choice — 1/Round]: As a Standard Action with an '
                'Action Cost of 1 Action, you may use a Ki Surge.',
          ),
          TraitOption(
            name: 'Power Battery',
            description: '[Passive]: Reduce the Ki Point Cost of all '
                'Attacking Maneuvers by 2(T) and you always benefit '
                'from Ki Multiplier even when you are not in a Form, '
                'but you cannot regain Ki Points through Ki Surges or '
                'Combat Recovery. If you would gain Ki Multiplier from '
                'another source, increase your Combat Rolls by 1(bT) '
                'instead.\n'
                '[Choice — Passive]: While your Ki Points exceed your '
                'Max Capacity, increase your Soak Value and Combat '
                'Rolls by 1(bT).',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Lock On',
    description:
        "Whether by sheer single-mindedness or via their on-board computers, "
        "Androids can hone in on a single target and find their weak spots.\n"
        "(1)-[Triggered/Start of Turn, Ruling]: Target an Opponent, they "
        "become your 'Target' until the start of your next turn. Increase "
        "your Strike and Wound Rolls against your Target by 2(T). While you "
        "have a Target, reduce your Dodge Rolls by 1(T) against all other "
        "Characters.\n"
        "(2)-[Triggered, 1/Round]: If you Defeat your Target with an "
        "Attacking Maneuver, regain Ki Points equal to double your Surgency.\n"
        "(3)-[Passive]: Increase your Perception Skill Checks by 2.",
  ),
  RaceTraitDef(
    race: 'Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Damage Inhibitor',
    description:
        "Durable and reinforced (often with metal), Androids can shrug off "
        "damage more easily than most.\n"
        "(1)-[Passive]: Increase your Damage Reduction by 2(T) and halve any "
        "Collision Damage you receive.\n"
        "(2)-[Triggered, 1/Round]: If you use the Direct Hit option of the "
        "Defend Maneuver, reduce the Damage Category of that Attacking "
        "Maneuver by 1 Category for the sake of your Damage calculation.\n"
        "(3)-[Triggered, 1/Round]: If you use the Direct Hit or Guard "
        "options of the Defend Maneuver, increase your Damage Reduction by "
        "2(T) for the duration of that Maneuver.",
  ),
  RaceTraitDef(
    race: 'Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Functional Purpose',
    description:
        "Specialization allows the diversity of Android designs to truly "
        "shine, allowing each Android to excel far and above others in one "
        "specific area of expertise.\n"
        "(1)-[Passive]: Upon gaining this Racial Trait, gain a Skill Rank in "
        "a Skill of your choice, then reduce the Critical Target for a "
        "Skill you have 2+ Skill Ranks in by 1. You cannot choose "
        "Perception for either choice.\n"
        "(2)-[Option]: Upon gaining this Racial Trait, choose one of "
        "the following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Destroyer',
            description: '[Triggered, 1/Round]: If you use the '
                'Signature Technique Maneuver, you may spend 2(T) Ki '
                'Points to apply an Energy Charge to that Attacking '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Protector',
            description: '[Triggered, 1/Round]: If an Opponent hits '
                'one of your Allies with an Attacking Maneuver, you may '
                'use the Intervene Maneuver without spending a Counter '
                'Action as long as you are within 8 Squares of that '
                'Ally. If you do, increase your Damage Reduction by '
                '2(T) for the duration of that Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Companion',
            description: '[Passive]: While Personality has the highest '
                'Attribute Score amongst your Attributes, increase your '
                'Combat Rolls and Initiative Rolls by 1(bT).',
          ),
          TraitOption(
            name: 'Researcher',
            description: '[Passive]: While Scholarship has the highest '
                'Attribute Score amongst your Attributes, increase your '
                'Combat Rolls and Initiative Rolls by 1(bT).',
          ),
          TraitOption(
            name: 'Leader',
            description: '[Passive]: Increase the Combat Rolls of all '
                'your Minions by 1(T) and increase their Maximum Life '
                'Points by 5(bT).',
          ),
        ],
      ),
    ],
  ),

  // ============================================================= Angel ===
  RaceTraitDef(
    race: 'Angel',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Discarded Divinity',
    description:
        "Stepping down from the realm of the gods, you blend in among "
        "mortalkind.\n"
        "(1)-[Passive]: Gain access to the True Angel Enhancement.\n"
        "(2)-[Passive]: You can sense God Ki.\n"
        "(3)-[Passive]: Increase your Max Capacity by 1/4, but you cannot "
        "Ki Wager a number of Ki Points that exceed 1/4 of your Max "
        "Capacity.\n"
        "(4)-[Passive]: While above the Bruised Health Threshold, apply "
        "your Racial Saving Throw Bonus to all Saving Throws instead of "
        "just Impulsive, and halve the Ki Point Cost for all Attacking "
        "Maneuvers.\n"
        "(5)-[Passive]: While above the Injured Health Threshold, increase "
        "your Awareness, Soak Value, and Defense Value by 1(T).\n"
        "(6)-[Passive]: While in the Spectator State, increase your Soak "
        "Value and Defense Value by 1(T).\n"
        "(7)-[Triggered/Threshold]: You may spend Ki Points up to an amount "
        "equal to 1/2 of your Max Capacity to regain an equal number of "
        "Life Points.",
  ),
  RaceTraitDef(
    race: 'Angel',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Lingering Instincts',
    description:
        "Your body has a tendency to move on its own in combat, without "
        "you needing to think about it.\n"
        "(1)-[Passive]: While you have no Counter Actions, all Combat "
        "Rolls you make in response to an Opponent's Attacking Maneuver "
        "have their Dice Score increased by 1(T).\n"
        "(2)-[Triggered]: When making a Strike or Dodge Roll, you may spend "
        "a Counter Action to set your Natural Result for that Combat Roll "
        "to 9. You cannot score a Critical or Botch Result on this Combat "
        "Roll. For each of your effects applied to this Combat Roll that "
        "would increase the Natural Result or reduce the Critical Target, "
        "increase your Dice Score by 1.\n"
        "(3)-[Triggered, 1/Round]: If targeted by an Opponent's Attacking "
        "Maneuver while you possess no Counter Actions and are above the "
        "Injured Health Threshold, you may use the Defend Maneuver without "
        "spending a Counter Action.",
  ),
  RaceTraitDef(
    race: 'Angel',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Angelic Defense',
    description:
        "You tirelessly maintain your guard, always moving out of the way "
        "of attacks with the greatest efficiency, never expending more "
        "energy than necessary.\n"
        "(1)-[Passive]: While above the Injured Health Threshold, halve the "
        "penalties you receive from Diminishing Defense.\n"
        "(2)-[Triggered, 1/Round]: If hit by an Attacking Maneuver you "
        "didn't respond to with a Counter Maneuver, spend a Counter Action "
        "to reroll your Dodge Roll with +1(T) Dice Score; if it now beats "
        "the Strike Roll, you dodge instead.\n"
        "(3)-[Triggered/Start of Combat Round]: While above the Bruised "
        "Health Threshold, gain an additional Counter Action.",
  ),
  RaceTraitDef(
    race: 'Angel',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Angelic Offense',
    description:
        "In the midst of battle, you instinctively launch attacks and "
        "counterattacks with speed and precision, sending your enemies "
        "reeling.\n"
        "(1)-[Passive]: While above the Injured Health Threshold, halve the "
        "penalties you receive from Diminishing Offense.\n"
        "(2)-[Triggered, 1/Round]: If you hit an Opponent, spend a Counter "
        "Maneuver to Clash (Impulsive/Cognitive); on a win they gain Guard "
        "Down against the next Attacking Maneuver targeting them this "
        "Round.\n"
        "(3)-[Triggered, 1/Round]: If you take no Damage from an Attacking "
        "Maneuver while you had no Counter Actions, use the Basic Attack "
        "Maneuver as an Out-of-Sequence Maneuver.\n"
        "(4)-[Triggered, 1/Round]: If you Defeat or knock an Opponent "
        "through a Threshold while above Injured, gain a Counter Action.",
  ),
  RaceTraitDef(
    race: 'Angel',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Divine Physique',
    description:
        "Even without your full power, your body is built to surpass those "
        "of mortals.\n"
        "(1)-[Passive]: While above the Injured Health Threshold, you "
        "cannot gain the Impaired Combat Condition.\n"
        "(2)-[Passive]: If in the Healthy Health Threshold, ignore the 2nd "
        "effect of the Superior State.\n"
        "(3)-[Passive]: While in the Superior State, you are also "
        "considered Healthy for all of your effects.\n"
        "(4)-[Triggered/Start of Turn]: For each Health Threshold you are "
        "above, regain 1(bT) Life and Ki Points.\n"
        "(5)-[Triggered/Power, 1/Encounter]: While below the Injured Health "
        "Threshold, spend a Counter Action to enter the Superior State "
        "until the end of your next turn.",
  ),

  // ========================================================== Arcosian ===
  RaceTraitDef(
    race: 'Arcosian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Overwhelming Fighter',
    description:
        "Arcosians are aggressive fighters who break down their opponents "
        "with powerful attacks and their unique capabilities.\n"
        "(1)-[Triggered, Resource]: If you hit any number of Opponents with "
        "an Attacking Maneuver, gain 1 Overwhelm (max. 4). For each stack "
        "of Overwhelm, increase your Wound Rolls by 1(T).\n"
        "(2)-[Automatic]: You lose all stacks of Overwhelm at the end of "
        "each of your turns.\n"
        "(3)-[Passive]: At Character Creation, select and gain access to "
        "an Evolution Trait (choose below).\n"
        "(4)-[Passive]: Gain access to the Tail Attack Maneuver.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Overwhelm',
      ),
    ],
    grantedResources: [
      GrantedResource(
        name: 'Overwhelm',
        maxStacks: 4,
        description: 'Gained on hitting any Opponent(s) with an '
            'Attacking Maneuver; lost at the end of your turn. Each stack '
            'adds +1(T) to your Wound Rolls (automated below).',
      ),
    ],
    // (3) select an Evolution Trait — the numeric always-on picks automate.
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Evolution Trait',
        options: kArcosianEvolutionTraits,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Arcosian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Survivor',
    description:
        "With sturdy bodies capable of surviving even the icy black depths "
        "of space, Arcosians are capable of withstanding far more damage "
        "than most races.\n"
        "(1)-[Passive, Ruling]: At Character Creation, gain a 'Plating'. "
        "Your Plating is Natural Armor.\n"
        "(2)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    trailingText:
        "(3)-[Triggered, 1/Round]: If you benefit from Legend Realized "
        "or use a Healing Surge, your Plating regains 1 Break Value. If "
        "the piece of Apparel was broken, it stops being broken (Break "
        "Value goes from 0 to 1).\n"
        "(4)-[Passive]: You cannot gain the Suffocating Combat "
        "Condition.\n"
        "(5)-[Passive]: While your Life Points are below 0, reduce "
        "your Combat Rolls by 1(bT) and your Stress Value by 1.\n"
        "(6)-[Passive]: You are not Defeated when your Life Points "
        "reach 0. Instead, your Life Points can reach negative values "
        "up to 1/4 (rounded up) of your Maximum Life Points. You are "
        "Defeated when your Life Points are reduced to this value, as "
        "if your Life Points were dropped to 0 if you did not possess "
        "this effect.\n"
        "(7)-[Passive]: If one of your effects would reduce your Life "
        "Points to 1 or set your amount of Life Points to 1 while your "
        "Life Points are below 0, instead set your Life Points to 1 "
        "above your lowest possible amount of Life Points.",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: kArcosianSurvivorOptions,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Arcosian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Overwhelming Assault',
    description:
        "Relentless in their pursuit of victory, Arcosians do not stop "
        "attacking until their enemies stop moving.\n"
        "(1)-[Triggered]: Using the Energy Charge Maneuver grants a stack "
        "of Overwhelm.\n"
        "(2)-[Triggered, 1/Round]: On an Attacking Maneuver, spend 2+ "
        "stacks of Overwhelm to apply, per 2 stacks spent: an Energy "
        "Charge, +1 AoE Magnitude, -4(T) Ki Point Cost, or +1 Damage "
        "Category (no repeats).",
  ),
  RaceTraitDef(
    race: 'Arcosian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Surprising Resilience',
    description:
        "Your body can take far more punishment than most would think.\n"
        "(1)-[Passive]: Increase the Dice Score of your Steadfast Checks "
        "by 1.\n"
        "(2)-[Passive]: Increase your Stress Bonus by 1 while not suffering "
        "any Health Threshold Penalties.\n"
        "(3)-[Triggered/Threshold]: Succeeding the Steadfast Check for this "
        "Threshold maximizes your Overwhelm stacks.",
  ),
  RaceTraitDef(
    race: 'Arcosian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Overwhelming Pressure',
    description:
        "The incredible pressure of an Arcosian's presence is enough to "
        "make lesser beings quake in terror and awe.\n"
        "(1)-[Triggered]: Hitting a Character with an Attacking Maneuver "
        "increases the Wound Roll by 1(T) per Health Threshold they are "
        "below (calculated independently per target).\n"
        "(2)-[Triggered, 1/Round]: Hitting multiple Characters with an AoE "
        "applies effect 1 as if all were as far below as the worst-off "
        "target.\n"
        "(3)-[Triggered, 1/Round]: Knocking an Opponent through a Threshold "
        "or Defeating them lets you enter the Superior State until end of "
        "turn.",
  ),

  // ======================================================= Bio Android ===
  RaceTraitDef(
    race: 'Bio Android',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Artificial Warrior',
    description:
        "Through the power of science and genetic engineering, you have "
        "been created to be the perfect warrior.\n"
        "(1)-[Triggered/Power, Resource]: Gain an Adaptation Point (max. "
        "3).\n"
        "(2)-[Triggered]: When making a Combat Roll, you may spend any "
        "number of Adaptation Points. For each spent, increase the Dice "
        "Score of that Combat Roll by 1(T).\n"
        "(3)-[Triggered]: When you are hit by an Attacking Maneuver, you "
        "may spend any number of Adaptation Points. For each spent, "
        "increase your Damage Reduction by 1(T) for the duration of that "
        "Attacking Maneuver.\n"
        "(4)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Genetic Survivor',
            description: '[Passive]: Increase your Racial Life Modifier '
                'by 2 and your Soak Value by 1(T).\n'
                '[Choice — Triggered, 1/Round]: If you are hit by an '
                'Attacking Maneuver and the Damage from that Attacking '
                'Maneuver (if any) does not knock you through a Health '
                'Threshold, gain an Adaptation Point.',
          ),
          TraitOption(
            name: 'Genetic Aggressor',
            description: '[Passive]: Increase your Strike and Wound '
                'Rolls by 1(T).\n'
                '[Choice — Triggered, 1/Round]: If you deal Damage to '
                'an Opponent with an Attacking Maneuver, gain an '
                'Adaptation Point.',
          ),
          TraitOption(
            name: 'Genetic Agility',
            description: '[Passive]: Increase your Dodge Rolls and '
                'Speeds by 1(T).\n'
                '[Choice — Triggered, 1/Round]: If you successfully '
                'Dodge an Attacking Maneuver, gain an Adaptation Point.',
          ),
          TraitOption(
            name: 'Pursuit of Perfection',
            description: '[Passive]: Gain access to the Absorb Special '
                'Maneuver and increase your maximum number of Adaptation '
                'Points by 1.\n'
                "[Choice — Addendum]: See 'Absorbed Perfection' below — "
                'work with your ARC to define a Perfection Target '
                '(a set of Character traits you can absorb power from); '
                'while you hold a stack of Absorption with that target, '
                'you gain the Perfection Awakening as a Level 1 '
                'Temporary Awakening that persists even after the '
                'Combat Encounter ends.',
          ),
        ],
      ),
    ],
    grantedResources: [
      GrantedResource(
        name: 'Adaptation Point',
        maxStacks: 3,
        description: 'Gained via Power Up (and per your Option choice '
            'above); spend on Combat Rolls (+1(T) Dice Score each) or '
            'Damage Reduction (+1(T) each) when hit.',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Bio Android',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Uncanny Monster',
    description:
        "An artificially created monster, you are able to consume the "
        "life force of other beings, allowing you to recover yourself.\n"
        "(1)-[Passive]: Increase the Dice Score of your Intimidation Skill "
        "Checks by 2.\n"
        "(2)-[Passive]: Gain 2 Bestial Traits or a Monstrous Trait (redo-"
        "able upon gaining a stack of Perfection).\n"
        "(3)-[Passive]: You gain access to the Draining Attack Maneuver and "
        "the Drain Life Advantage.\n"
        "(4)-[Triggered]: Draining 5+(bT) Ki Points from an equal/higher "
        "ToP Opponent lets you use the Power Up Maneuver as an "
        "Out-of-Sequence Maneuver.",
  ),
  RaceTraitDef(
    race: 'Bio Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Combat Blueprint',
    description:
        "Designed as a weapon of war, you are able to adapt to any combat "
        "scenario.\n"
        "(1)-[1/Round]: As an Instant Maneuver during your turn, you may "
        "spend any number of Power stacks. For each spent Power stack, "
        "regain 2(bT) Life and Ki Points. If you spend 2+ stacks through "
        "this effect, gain an Adaptation Point.\n"
        "(2)-[Choice]: Depending on your choice for the Option effect of "
        "Artificial Warrior, gain access to the corresponding effect:",
    dependentChoice: DependentChoice(
      sourceTraitName: 'Artificial Warrior',
      sourceGroupLabel: 'Option',
      textByOption: {
        'Genetic Survivor': '[Triggered, 1/Round]: If you spend 2+ '
            'Adaptation Points through the 3rd effect of Artificial '
            'Warrior, you may reduce the Damage Category of that '
            'Attacking Maneuver by 1 Category for the sake of your '
            'Damage Calculation.',
        'Genetic Aggressor': '[Triggered, 1/Round]: If you spend 2+ '
            'Adaptation Points on the Strike Roll of an Attacking '
            'Maneuver, you may apply an Energy Charge to that Attacking '
            'Maneuver.',
        'Genetic Agility': '[Triggered, 1/Round]: If you spend 2+ '
            'Adaptation Points on the Dodge Roll of an Attacking '
            'Maneuver, you may ignore all Diminishing Defense you are '
            'suffering from for the duration of that Maneuver.',
        'Pursuit of Perfection': '[Triggered/Start of Combat Round]: '
            'Gain 1 Adaptation Point.',
      },
    ),
  ),
  RaceTraitDef(
    race: 'Bio Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Offensive Design',
    description:
        "Literally built for battle, your potent offense is one of your "
        "best selling points.\n"
        "(1)-[Passive]: Reduce the Critical Target of your Strike and "
        "Wound Rolls by 1.\n"
        "(2)-[Triggered, 3/Round]: If you gain an Adaptation Point, "
        "regain 1(bT) Ki Points.\n"
        "(3)-[Triggered, 3/Round]: If you score a Critical Result on "
        "your Strike or Wound Roll, gain an Adaptation Point.\n"
        "(4)-[Triggered, 1/Encounter]: If you hit an Opponent with an "
        "Attacking Maneuver that you have spent 3+ Adaptation Points "
        "on the Combat Rolls of, you may increase the Damage Category "
        "of that Attacking Maneuver by 1 Category.",
  ),
  RaceTraitDef(
    race: 'Bio Android',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Defensive Design',
    description:
        "You were able to withstand as much punishment as possible, so "
        "that you can stand tall on the battlefield.\n"
        "(1)-[Passive]: Reduce the Critical Target of your Dodge Rolls "
        "by 1.\n"
        "(2)-[Passive]: Increase your Damage Reduction by 1(T).\n"
        "(3)-[Triggered, 3/Round]: If you gain an Adaptation Point, "
        "regain 1(bT) Life Points.\n"
        "(4)-[Triggered, 3/Round]: If you score a Critical Result on "
        "your Dodge Rolls, gain an Adaptation Point.\n"
        "(5)-[1/Encounter]: You may spend 2 Adaptation Points to use "
        "the Defend Maneuver without spending a Counter Action.",
  ),

  // ========================================================= Cerealian ===
  RaceTraitDef(
    race: 'Cerealian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Evolved Right Eye',
    description:
        "A powerful evolved eye that allows Cerealians to see details that "
        "others can't, including at a much further distance than others "
        "could possibly imagine.\n"
        "(1)-[Passive]: Increase your Perception Skill Checks by 2 and "
        "reduce their Critical Target by 1.\n"
        "(2)-[Passive]: Reduce the Critical Target for your Combat Rolls "
        "by 1.\n"
        "(3)-[Passive]: You cannot suffer from the Long Range Penalty, but "
        "none of your Signature Techniques may possess the Short Range "
        "Disadvantage.\n"
        "(4)-[Triggered, Resource]: Each time you score a Critical "
        "Result on a Combat Roll, gain a stack of Critical Eye (max. "
        "3). When you hit an Opponent with an Attacking Maneuver, you "
        "can spend any number of Critical Eye stacks to increase the "
        "Wound Roll of that Attacking Maneuver by 2(T) for each "
        "Critical Eye stack spent.\n"
        "(5)-[Triggered, 1/Round, 2/Encounter]: After rolling your "
        "Strike Roll for an Attacking Maneuver, you may declare that "
        "it is a Critical Result regardless of the Natural Result. If "
        "your result would have been a Botch Result, it is also no "
        "longer a Botch Result.",
    grantedResources: [
      GrantedResource(
        name: 'Critical Eye',
        maxStacks: 3,
        description: 'Gained on a Critical Combat Roll; spend stacks on '
            'a hit for +2(T) Wound each.',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Cerealian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Pinpoint Combat',
    description:
        "Cerealians have developed a way to fight that utilizes the "
        "enhanced sight of their right eye, allowing them to make better "
        "use of their natural gift by striking at key points and attacking "
        "during openings made by their opponents.\n"
        "(1)-[Passive]: Increase the Wound Rolls of your Called Shots and "
        "Exploit Maneuvers by 2(T).\n"
        "(2)-[Triggered, 1/Round]: When making an Attacking Maneuver, "
        "you may spend 2 stacks of Critical Eye to use the Called Shot "
        "Maneuver without spending an Action through its effects.\n"
        "(3)-[Triggered, 1/Round]: If an Opponent uses an effect or "
        "Maneuver that would allow an Ally to use the Exploit Maneuver, "
        "your Ally may allow you to use the Exploit Maneuver in their "
        "stead regardless of how far away you are from your Opponent. "
        "Your Ally may allow you to spend their Counter Action instead "
        "of your own for this use of the Exploit Maneuver.",
  ),
  RaceTraitDef(
    race: 'Cerealian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Patient Sniper',
    description:
        "Due to most Cerealians utilizing the range of vision granted to "
        "them via their right eye for sniping, they've learned to patiently "
        "await an opportune moment to strike an opponent, regardless of the "
        "distance between them.\n"
        "(1)-[Triggered]: If an Ally moves an Opponent, this triggers "
        "your Exploit Maneuver against that Opponent.\n"
        "(2)-[Triggered]: If an Ally inflicts a Combat Condition on an "
        "Opponent, this triggers your Exploit Maneuver against that "
        "Opponent.\n"
        "(3)-[Triggered]: If you make an Attacking Maneuver through the "
        "Exploit Maneuver during an Ally's Turn, increase the Natural "
        "Result for your Strike and Wound Rolls on that Attacking "
        "Maneuver by 1.\n"
        "(4)-[Triggered/Start of Combat Round, 3/Encounter]: Target an "
        "Ally with a lower Initiative than you. During this Combat "
        "Round, take your turn immediately after they end their turn "
        "instead of your usual place in the Initiative Order.",
  ),
  RaceTraitDef(
    race: 'Cerealian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Scarlet Spotter',
    description:
        "The enhanced vision of the Cerealians' evolved eye allows them to "
        "better target an opponent's vitals, even in the heat of the "
        "moment, giving them the opportunity to better capitalize on- and "
        "exploit- an opponent's movements.\n"
        "(1)-[Triggered]: If you target an Opponent with a Called Shot, "
        "you may spend 2 stacks of Critical Eye to ignore that "
        "Opponent's Damage Reduction.\n"
        "(2)-[Triggered, 1/Round]: If you suffer no damage from an "
        "Opponent's Attacking Maneuver that targets you due to any "
        "reason, you may use the Exploit Maneuver as if they triggered "
        "its effects.\n"
        "(3)-[Triggered, 1/Round]: If you knock an Opponent through a "
        "Health Threshold with a Called Shot or an Attacking Maneuver "
        "made through the Exploit Maneuver, that Opponent suffers from "
        "2 stacks of the Broken Combat Condition until the end of your "
        "next turn.",
  ),
  RaceTraitDef(
    race: 'Cerealian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Critical Point',
    description:
        "Trained to strike the vital points on your opponents' bodies with "
        "deadly precision, your attacks always strike true.\n"
        "(1)-[Passive]: If your Attacking Maneuver possesses 3+ Energy "
        "Charges, set the Critical Target for that Attacking Maneuver's "
        "Strike Roll to 5.\n"
        "(2)-[Triggered, 1/Round]: If you use the Energy Charge "
        "Maneuver, you may spend 3(bT) Ki Points. If you do and use the "
        "declared Attacking Maneuver for that use of the Energy Charge "
        "Maneuver during this Combat Round, increase the Strike and "
        "Wound Rolls of that Attacking Maneuver by 2(T). Double this "
        "bonus if you score a Critical Result on the Strike Roll of "
        "that Attacking Maneuver.\n"
        "(3)-[Triggered, 1/Round]: If you Defeat an Opponent or knock "
        "them through a Health Threshold with an Attacking Maneuver of "
        "which you scored a Critical Result on the Strike Roll, "
        "maximize your stacks of Critical Eye.",
  ),

  // ============================================================= Demon ===
  RaceTraitDef(
    race: 'Demon',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Demonic Combat',
    description:
        "Sly and cunning, demons prefer to trick and trap opponents rather "
        "than face them head-on.\n"
        "(1)-[Passive]: You are considered to possess the Demon Clansman "
        "Factor for all Prerequisites.\n"
        "(2)-[Passive]: Increase the Wound Rolls of your Attacking "
        "Maneuvers against Opponents suffering a Combat Condition by 2(T); "
        "increase your Damage Reduction against such Opponents' attacks by "
        "1(T).\n"
        "(3)-[Triggered, 1/Round]: Knocking an Opponent through a "
        "Threshold triggers a Might Clash — win and they're knocked "
        "Prone.\n"
        "(4)-[Triggered/Start of Turn, 1/Round]: Spend 4(bT) Ki Points to "
        "Clash (Cognitive) against a non-Long-Range Opponent; win and they "
        "suffer Impediment until end of your turn.",
  ),
  RaceTraitDef(
    race: 'Demon',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Demonic Pressure',
    description:
        "The sheer power in a demon's body is overwhelming to lesser "
        "beings, and their presence alone can make grown men give up the "
        "fight.\n"
        "(1)-[Triggered, 3/Round, Ruling]: If you make an Attacking "
        "Maneuver during your turn, make a 'Pressure Check'. A Pressure "
        "Check is a 1d10, where a Dice Score of 4+ is a success and a "
        "result of 3 or less is a fail.\n"
        "(2)-[Automatic, Resource]: If you succeed at a Pressure Check, "
        "gain a stack of Demonic Power. If you fail at a Pressure "
        "Check, gain a stack of Demonic Fatigue.\n"
        "(3)-[Automatic/Start of Turn]: You lose all stacks of Demonic "
        "Power and Demonic Fatigue.\n"
        "(4)-[Passive]: For each stack of Demonic Power, increase your "
        "Wound Rolls by 2(T).\n"
        "(5)-[Passive]: For each stack of Demonic Fatigue, reduce your "
        "Defense Value and Soak Value by 1(T).\n"
        "(6)-[Passive]: While you possess 2+ stacks of Demonic Power, "
        "increase your Might by 1(T).",
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 2,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Demonic Power',
      ),
      RaceTraitAutomation(
        affectedStats: [AffectedStat.defenseValue, AffectedStat.soak],
        coefficient: -1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Demonic Fatigue',
      ),
    ],
    grantedResources: [
      GrantedResource(
        name: 'Demonic Power',
        maxStacks: 20,
        description: 'Gained on a successful Pressure Check; lost at the '
            'start of your turn. Each stack adds +2(T) Wound Rolls '
            '(automated below). No stated maximum on the site.',
      ),
      GrantedResource(
        name: 'Demonic Fatigue',
        maxStacks: 20,
        description: 'Gained on a failed Pressure Check; lost at the '
            'start of your turn. Each stack reduces Defense Value/Soak '
            'by 1(T) (automated below). No stated maximum on the site.',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Demon',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Demonic Resilience',
    description:
        "Demons thrive in a realm where survival is all that matters, "
        "making them hardier than most.\n"
        "(1)-[Passive]: While below the Injured Health Threshold, "
        "increase your Cognitive Save by 1(T).\n"
        "(2)-[Triggered, 2/Round]: If you are targeted by an Attacking "
        "Maneuver, you may make a Pressure Check. If you succeed, "
        "increase your Damage Reduction by 2(T) until the start of "
        "your next turn.\n"
        "(3)-[Triggered/Threshold]: If you succeed at the Steadfast "
        "Check for this Health Threshold, regain Life and Ki Points "
        "equal to double your Might.\n"
        "(4)-[Triggered, 1/Encounter]: If you fail a Steadfast Check, "
        "you may make a Pressure Check. If you succeed, you instead "
        "succeed at that Steadfast Check.",
  ),
  RaceTraitDef(
    race: 'Demon',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Demonic Creativity',
    description:
        "The twisted minds of demons are often ingenius and difficult to "
        "predict.\n"
        "(1)-[Passive]: Increase the number of Technique Points you "
        "gain from Skill Improvements by 3.\n"
        "(2)-[1/Round]: As an Instant Maneuver, you may spend 2 stacks "
        "of Demonic Power to use a Maneuver with an Action Cost of 1 "
        "as an Out-of-Sequence Maneuver.\n"
        "(3)-[Triggered, 1/Round]: If you use the Signature Technique "
        "Maneuver, you can spend 1 stack of Demonic Power you possess "
        "to apply the Condition Advantage to that Attacking Maneuver.\n"
        "(4)-[Triggered, 1/Round, 3/Encounter]: If you make a Pressure "
        "Check, you may choose to roll the 1d10 twice and use the "
        "higher of the two results. If you still fail, you gain 2 "
        "stacks of Demonic Fatigue instead of 1.",
  ),

  // ========================================================== Earthling ===
  RaceTraitDef(
    race: 'Earthling',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Earthling Resolve',
    description:
        "Earthlings have immeasurable and unbreakable determination to "
        "protect life, their allies, and their world. As an Earthling, you "
        "will never give up, and you will never back down.\n"
        "(1)-[Passive]: For each Health Threshold you are below, increase "
        "your Strike and Wound Rolls by 1(T).\n"
        "(2)-[Triggered, 1/Round]: On a Natural Result of 2 or less, reroll "
        "your Base Dice (must take the second result).\n"
        "(3)-[Triggered, 1/Encounter]: Succeeding a Steadfast Check removes "
        "all Combat Conditions except Suffocating.\n"
        "(4)-[Triggered/Threshold, 1/Encounter]: Spend up to 6(bT) Life "
        "Points on your Steadfast Check — every 2(bT) spent increases the "
        "Dice Score by 1.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.strike,
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Earthling',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Quick to Master',
    description:
        "Earthlings are known for their ability to learn fast and "
        "effectively. This allows for them to specialize in certain "
        "skills, while also adopting the ability to adjust their "
        "techniques on the fly.\n"
        "(1)-[Passive]: Increase the amount of Technique Points you gain "
        "from Skill Improvement by 5.\n"
        "(2)-[Triggered]: When you use the Signature Technique Maneuver, "
        "for this instance of using your chosen Signature Technique, you "
        "may either: Apply an Energy Charge to that Attacking Maneuver. "
        "Add a single Advantage with a TP cost of up to 10 TP to your "
        "chosen Signature Technique.\n"
        "(3)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Way of the...',
        options: [
          TraitOption(
            name: 'Way of the Warrior',
            description: '[Triggered]: When you use the Signature '
                'Technique Maneuver, you may reduce your Life Points by '
                'up to 10(bT) to gain a free Ki Wager on this Attacking '
                'Maneuver equal to the reduction.',
          ),
          TraitOption(
            name: 'Way of the Serene',
            description: '[Triggered/Mindful]: Your Dodge Rolls have '
                'their Critical Target reduced by 1 and you increase the '
                'Natural Result by 1 on all Dodge Rolls until you leave '
                'the Mindful State.',
          ),
          TraitOption(
            name: 'Way of the Fury',
            description: '[Triggered/Raging]: Increase your Wound Rolls '
                'by 2(T) until you leave the Raging State.',
          ),
          TraitOption(
            name: 'Way of the Elements',
            description: "[Passive]: Upon gaining this effect, select a "
                "Profile with 'Elemental' in the name – it becomes a "
                'Favored Element.',
          ),
          TraitOption(
            name: 'Way of the Mystic',
            description: '[Passive]: Reduce the TP Cost of all Unique '
                'Abilities by 5 TP.',
          ),
          TraitOption(
            name: 'Way of the Weaponmaster',
            description: '[Passive]: You gain the Weapon Specialist '
                'Talent, and when creating any type of Signature '
                'Technique, you may add the Weapon Assisted Advantage to '
                'that Signature Technique without spending Technique '
                'Points (this does not count towards your maximum TP '
                'Cost of that Signature Technique).',
          ),
          TraitOption(
            name: 'Way of the Pilot',
            description: '[Passive]: You gain the Expert Pilot Talent '
                'and increase the amount of Technique Points your '
                'Battle Jackets get at Jacket Creation and each new Tier '
                'of Power by 5.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Earthling',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Last Resort',
    description:
        "No matter the situation, no matter how grim it looks, an "
        "Earthling can dig deep and draw out an unexpected wellspring of "
        "power.\n"
        "(1)-[Passive]: If your Capacity is 0 when you roll the Wound "
        "Roll for a Signature Technique, increase the Wound Roll by "
        "2(T).\n"
        "(2)-[Triggered, 1/Encounter]: When you use the Signature "
        "Technique Maneuver to use a Signature Technique while you are "
        "below the Injured Health Threshold, you do not have to pay "
        "the Ki Point Cost for that instance of the Signature "
        "Technique.\n"
        "(3)-[Triggered/Power, 1/Encounter]: Double the bonus from the "
        "first effect of Earthling Resolve until the end of your next "
        "turn.",
  ),
  RaceTraitDef(
    race: 'Earthling',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Experienced Fighter',
    description:
        "Many Earthlings that train in combat spend years honing a "
        "particular skill, allowing them to keep up with other races "
        "despite their disadvantages.\n"
        "(1)-[Triggered/Start of Combat Round]: If last Round you Ki-"
        "Wagered nothing and used 2+ Attacking Maneuvers with no more than "
        "1 Energy Charge, use Combat Recovery Out-of-Sequence without its "
        "Defense Value penalty.\n"
        "(2)-[1/Round]: As an Instant Maneuver, you can spend 3(T) Ki "
        "Points to target an Opponent and apply one of the following "
        "effects (these effects cannot stack):\n"
        "Exploitation Strike [Triggered]: Increase the Strike Roll of "
        "your next Attacking Maneuver against the targeted Opponent by "
        "2(T). The penalty they are currently suffering from Diminishing "
        "Defense is doubled for the duration of this Attacking Maneuver.\n"
        "Instinct-Driven Dodge [Triggered]: Increase your Dodge Roll "
        "against the next Attacking Maneuver that targets you from the "
        "targeted Opponent by 2(T). You ignore any penalties due to the "
        "effects of Diminishing Defense for this Dodge Roll.\n"
        "Punishing Blow [Triggered]: The next Attacking Maneuver you "
        "make against the targeted Opponent has its Wound Roll increased "
        "by 3(T) and its Damage Category increased by 1 category.",
  ),
  RaceTraitDef(
    race: 'Earthling',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Eye of the Dragon',
    description:
        "Earthlings are as varied as the many cities and locales on their "
        "home planet, Earth, but one thing is always certain: what they "
        "lack in raw power, they make up for with hard work.\n"
        "(1)-[Passive]: If you've already used the Energy Charge "
        "Maneuver once during this Combat Round, reduce the Ki Point "
        "Cost for the Energy Charge Maneuver by 1(T).\n"
        "(2)-[Triggered, 1/Round]: When using the Signature Technique "
        "Maneuver, if this is the first time in the Combat Encounter you "
        "have used this Signature Technique, you may apply both effects "
        "from the second effect of Quick to Master instead of having to "
        "select one.\n"
        "(3)-[Choice]: Depending on your choice for the Option effect of "
        "Quick to Master, gain the following effect:",
    dependentChoice: DependentChoice(
      sourceTraitName: 'Quick to Master',
      sourceGroupLabel: 'Way of the...',
      textByOption: {
        'Way of the Warrior': '[Triggered]: When you reduce your Life '
            'Points by 10(bT) through the effect of Way of the Warrior, '
            'that Attacking Maneuver gains an Energy Charge (this Energy '
            "Charge does not count towards your maximum).",
        'Way of the Serene': '[Triggered/Power, 1/Round, 2/Encounter]: '
            'Enter the Mindful State until the end of your next turn.',
        'Way of the Fury': '[Triggered/Power, 1/Round, 2/Encounter]: '
            'Enter the Raging State until the end of your next turn.',
        'Way of the Elements': "[Passive]: Reduce the Ki Point Cost of "
            "any Signature Technique that uses your Favored Elements' "
            'Profile by 2(T).',
        'Way of the Mystic': '[Passive]: Reduce the Ki Point Cost of '
            'all your Unique Abilities by 2(T).',
        'Way of the Weaponmaster': '[Triggered, 1/Round]: If you would '
            'target an Opponent with an Armed Attack, you may increase '
            'the Strike and Wound Rolls for that Attacking Maneuver by '
            '1(T) and 2(T) respectively.',
        'Way of the Pilot': '[Triggered, 1/Round]: If you would target '
            'an Opponent with an Attacking Maneuver while piloting a '
            "Battle Jacket or Vehicle, you may spend up to 10(bT) of "
            "that Battle Jacket or Vehicle's Life Points to increase the "
            'Wound Roll for that Attacking Maneuver by an equal amount.',
      },
    ),
  ),

  // ======================================================= Glass Tribe ===
  RaceTraitDef(
    race: 'Glass Tribe',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Body of Glass',
    description:
        "Brittle and unyielding, your body is hard to damage but shatters "
        "under extreme force.\n"
        "(1)-[Passive]: Halve your Soak Value.\n"
        "(2)-[Passive]: Gain Damage Reduction equal to your Soak Value.\n"
        "(3)-[Passive]: If your Top Layer of Apparel is not of the "
        "Armor or Weights Apparel Category, increase your Damage "
        "Reduction by the Apparel Bonus of that piece of Apparel.\n"
        "(4)-[Passive]: You gain access to the Glassification Special "
        "Maneuver and the Glass Profile.\n"
        "(5)-[Passive]: Increase your Combat Rolls by 1(T) while "
        "occupying a Square with the Glass Environmental Quality, or "
        "while adjacent to a Feature with the Glass Feature Quality.\n"
        "(6)-[Triggered, 1/Round]: If you or an Ally is targeted by an "
        "Attacking Maneuver while adjacent to a Feature with the Glass "
        "Feature Quality and the attacking Character is not adjacent "
        "to the targeted Character, they may benefit from cover using "
        "the adjacent Feature even if it is not between the attacking "
        "Character and the target.",
  ),
  RaceTraitDef(
    race: 'Glass Tribe',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Heart of Glass',
    description:
        "Implacable and unrevealing, your impassive demeanor betrays none "
        "of your pain nor turmoil.\n"
        "(1)-[Passive]: Ignore all Health Threshold Penalties while in "
        "the Surging State.\n"
        "(2)-[Passive]: Ignore the effects of the Fatigued Combat "
        "Condition while in the Healthy Health Threshold.\n"
        "(3)-[Triggered, 1/Round]: If you use an Attacking Maneuver of "
        "the Glass Profile while occupying a Square with the Glass "
        "Environmental Quality, you may enter the Surging State for "
        "the duration of that Attacking Maneuver.\n"
        "(4)-[Triggered/Threshold]: When you make a Steadfast Check, "
        "you may choose to fail that Steadfast Check without rolling "
        "to use a Ki Surge as an Out-of-Sequence Maneuver. Then, you "
        "may enter the Surging State until the end of your turn.\n"
        "(5)-[Triggered, 1/Encounter]: If you leave the Surging State, "
        "you may use a Healing Surge as an Out-of-Sequence Maneuver. "
        "If you do, remove any stacks of the Fatigued Combat Condition "
        "you are suffering from.",
  ),
  RaceTraitDef(
    race: 'Glass Tribe',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Warriors of Glass',
    description:
        "Your uncanny ability to manipulate glass allows you to create "
        "animate glass statues that you can use to attack.\n"
        "(1)-[1/Round, Ruling]: As a Standard Maneuver with an Action "
        "Cost of 1 Action, you can spend up to 8(bT) Ki Points. For "
        "every 2(bT) Ki Points spent, select a Square with the Glass "
        "Environmental Quality. Create a 'Glass Soldier' on that "
        "Square and remove the Glass Environmental Quality from that "
        "Square. A Glass Soldier is a Feature with the Resilient, "
        "Glass, and Reflective Environmental Qualities, and a Hardness "
        "Rank of 2 (before modification).\n"
        "(2)-[Passive]: If an Opponent that was adjacent to a Glass "
        "Soldier uses the Movement Maneuver to move away from that "
        "Glass Soldier, this triggers your Exploit Maneuver. If you "
        "use the Exploit Maneuver, you must also apply the 4th effect "
        "of Warriors of Glass.\n"
        "(3)-[1/Round]: As an Instant Maneuver, you may move any "
        "number of Glass Soldiers by a number of Squares up to 1/2 of "
        "your Force or Magic Score (whichever is higher). You cannot "
        "cause Collision with this movement.\n"
        "(4)-[Triggered]: If you use an Attacking Maneuver, you can "
        "have that Attacking Maneuver originate from a Square occupied "
        "by a Glass Soldier of your choice as if you were on that "
        "Square instead of any Squares you currently occupy.\n"
        "(5)-[Triggered/Start of Turn]: If a Glass Soldier is "
        "occupying a Square with the Glass Environmental Quality, it "
        "regains all of its Life Points. If a Glass Soldier is "
        "occupying a Square that does not possess the Glass "
        "Environmental Quality, that Square and all adjacent Squares "
        "gain the Glass Environmental Quality.",
  ),
  RaceTraitDef(
    race: 'Glass Tribe',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Glass Combat',
    description:
        "Your glass-like body grants you a high tolerance for physical "
        "stress, allowing you to push your powers of glass creation and "
        "manipulation to their absolute limits.\n"
        "(1)-[Passive]: You may use the Glass Profile an additional "
        "time per Combat Round through the Basic Attack Maneuver.\n"
        "(2)-[Passive]: While in the Surging State, increase the "
        "Strike Rolls of your Attacking Maneuvers of the Glass Profile "
        "by 1(T).\n"
        "(3)-[1/Round]: During your turn, if you are occupying a "
        "Square that has the Glass Environmental Quality, you may use "
        "the Movement Maneuver as an Instant Maneuver. If you do, you "
        "must end this movement on a Square that has the Glass "
        "Environmental Quality.\n"
        "(4)-[Triggered, 1/Round]: When you or an adjacent Ally use an "
        "Attacking Maneuver of any Profile except the Glass Profile, "
        "you may spend 2(bT) Ki Points to apply the effects of the "
        "Glass Profile to that Attacking Maneuver. If you do, that "
        "Attacking Maneuver is also considered to be of the Glass "
        "Profile for all effects.\n"
        "(5)-[Triggered, 1/Round]: If you or an Ally is hit by an "
        "Attacking Maneuver while adjacent to a Feature with the Glass "
        "Environmental Quality, you may destroy that Feature to reduce "
        "the Damage by 1/2 of that Feature's Hardness Value.\n"
        "(6)-[Triggered, 1/Encounter]: If you target only Squares "
        "through the effects of the Glassification Maneuver, you do "
        "not have to pay the Ki Point Cost.",
  ),

  // ============================================================= Heran ===
  RaceTraitDef(
    race: 'Heran',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Greed of the Hera',
    description:
        "A race of conquering warriors, the Herans' greed is renowned "
        "throughout the galaxy.\n"
        "(1)-[Passive]: Each stack of Power you possess increases your "
        "Soak Value by 1(T).\n"
        "(2)-[Triggered, 1/Round]: An AoE hit lets you use the Basic "
        "Attack Maneuver Out-of-Sequence.\n"
        "(3)-[Triggered, 1/Round]: Spend 3(bT) Ki Points to add a Cone/"
        "Line AoE to a non-AoE Basic Attack.\n"
        "(4)-[Triggered, 1/Round]: Spend up to 4(bT) Ki Points on a Minor/"
        "Standard AoE attack for +1 Magnitude per 2(bT) spent.\n"
        "(5)-[Triggered, Resource]: Gaining Power stacks also grants equal "
        "Greed stacks (same max as Power).\n"
        "(6)-[Triggered]: Spend Greed stacks when hit for +2(T) Damage "
        "Reduction each.\n"
        "(7)-[Automatic/Start of Turn]: Lose all Power stacks (after other "
        "start-of-turn effects), regaining 2(bT) Ki per stack lost.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perPowerStack,
      ),
    ],
    grantedResources: [
      GrantedResource(
        name: 'Greed',
        maxStacks: 2,
        description: 'Gained 1-for-1 whenever you gain a stack of Power '
            '(same maximum as Power); spend on being hit for +2(T) '
            'Damage Reduction each.',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Heran',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Brigand Combat',
    description:
        "Due to their strong lust for battle and their lack of ethics, "
        "Herans are often viewed as bandits, brigands, or even pirates.\n"
        "(1)-[Passive]: Increase the Strike and Wound Rolls of your "
        "Attacking Maneuvers that target an Opponent who has at least "
        "one of your Allies on a Square adjacent to them by 1(T) and "
        "2(T) respectively.\n"
        "(2)-[Triggered, 1/Round]: If you deal Damage to an Opponent "
        "with one of your Attacking Maneuvers, you may select an Ally "
        "adjacent to your Opponent (that was targeted by this Attacking "
        "Maneuver but did not take Damage from this Attacking Maneuver). "
        "That Ally may use the Basic Attack Maneuver as an "
        "Out-of-Sequence Maneuver. If they do, they must target the "
        "Opponent that triggered this effect.\n"
        "(3)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Riches of Might',
            description: '[Passive]: Increase your Racial Life '
                'Modifier by 3 and increase your Might by 1(T).',
          ),
          TraitOption(
            name: 'Riches of Mysticism',
            description: '[Passive]: Upon gaining this effect, gain '
                'access to a Unique Ability with a TP Cost of 20 or '
                'less (that you meet the prerequisites for) and reduce '
                'the TP Cost of all Unique Abilities by 2.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Heran',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Power of the Hera',
    description:
        "As a warrior race, Herans' bodies overflow with energy, which "
        "they redirect into their attacks.\n"
        "(1)-[Passive]: Increase the maximum amount of Energy Charges "
        "you can apply to your Attacking Maneuver by your maximum "
        "amount of Power stacks.\n"
        "(2)-[Triggered, 1/Round]: If you use the Energy Charge "
        "Maneuver, gain a stack of Power until the start of your next "
        "turn.\n"
        "(3)-[Triggered, 1/Round]: If you Defeat a Character or knock "
        "a Character through a Health Threshold with your Attacking "
        "Maneuver, you may use the Power Up Maneuver as an "
        "Out-of-Sequence Maneuver.\n"
        "(4)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
        "Technique, you may spend any number of Greed stacks to apply "
        "an equal amount of Energy Charges to that Attacking Maneuver.",
  ),
  RaceTraitDef(
    race: 'Heran',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Cutthroat Teamwork',
    description:
        "Uncaring about the safety of their comrades, Herans will do "
        "whatever it takes to win.\n"
        "(1)-[Passive]: Increase the Wound Rolls of your Attacking "
        "Maneuvers with AoEs that possess 2+ targets by 2(T). This "
        "bonus is doubled if you possess any Allies among those "
        "targets.\n"
        "(2)-[1/Round]: As a Standard Maneuver with an Action Cost of "
        "1, you may target an Ally on an adjacent Square. Make a "
        "Might Clash against them. If you win, you may move that Ally "
        "onto any Square within a Large Sphere AoE (centered on you).\n"
        "(3)-[Triggered, 1/Round]: If you hit an Ally (that is not a "
        "Minion) with an Attacking Maneuver (and inflicted Damage) "
        "while they are on an adjacent Square to an Opponent, make a "
        "Clash (Corporeal/Morale) against that Opponent. If you win, "
        "that Opponent gains the Guard Down and Broken Combat "
        "Conditions until the end of your turn.\n"
        "(4)-[Triggered/Power, 1/Round]: If you have hit an Ally (that "
        "is not a Minion) with one of your Attacking Maneuvers (and "
        "inflicted Damage) during this Combat Round, you may gain an "
        "additional Stack of Power through this use of the Power Up "
        "Maneuver.",
  ),
  RaceTraitDef(
    race: 'Heran',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Galaxy at the Brink',
    description:
        "As conquerors and warriors, Herans are resilient, and grow "
        "stronger as the battle continues.\n"
        "(1)-[Passive]: While you are below the Injured Health "
        "Threshold, increase your maximum number of Power stacks by "
        "1.\n"
        "(2)-[Passive]: Increase the Dice Score of your Steadfast "
        "Check by 1 while you have a stack of Power.\n"
        "(3)-[Triggered, 1/Encounter]: If you are below the Injured "
        "Health Threshold and would trigger the 7th effect of Greed "
        "of the Hera while possessing 2+ stacks of Power, you may "
        "choose to ignore that effect. If you do, use a Ki Surge as "
        "an Out-of-Sequence Maneuver.",
  ),

  // ========================================================= Konatsian ===
  RaceTraitDef(
    race: 'Konatsian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Battle Tension',
    description:
        "Skilled and trained for battle, you're ready for any obstacle "
        "your enemies might throw at you.\n"
        "(1)-[Triggered/Threshold, Resource]: Gain a stack of Tension "
        "(max. 5).\n"
        "(2)-[Triggered/Start of Turn]: Below the Injured Health Threshold, "
        "gain a stack of Tension.\n"
        "(3)-[Triggered]: An Ally (non-Minion) being Defeated grants a "
        "stack of Tension.\n"
        "(4)-[Passive]: 1+ Tension stack grants +1(T) Damage Reduction.\n"
        "(5)-[Passive]: 2+ Tension stacks grant +1(T) to Clashes an "
        "Opponent initiates using your Might/Saving Throws.\n"
        "(6)-[Triggered/Power, 1/Round]: 3+ Tension stacks let you clear a "
        "Combat Condition (except Pinned/Suffocating/Stress Exhaustion/"
        "Transfigured).\n"
        "(7)-[Triggered/Defeat]: 4+ Tension stacks regain 1/4 Max Life and "
        "cost 2 Tension.\n"
        "(8)-[Triggered/Start of Turn, 1/Encounter]: 5+ Tension stacks let "
        "you enter the Entrusted Special State.",
    grantedResources: [
      GrantedResource(
        name: 'Tension',
        maxStacks: 5,
        description: 'Gained at Health Thresholds, at the start of your '
            'turn while below Injured, and on an Ally being Defeated; '
            'spend on Damage Reduction, Clashes, clearing Combat '
            'Conditions and more (see full effect above).',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Konatsian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Vocation Training',
    description:
        "Trained to work in teams to cover each others' weaknesses, "
        "Konatsians take on specialized combat roles.\n"
        "(1)-[Passive]: At Character Creation, gain access to a Talent "
        "from the Physical Attack, Energy Attack, Magic Attack, or "
        "Weapon Talent Category that you meet the Prerequisites for.\n"
        "(2)-[Passive]: At Character Creation, select and gain access "
        "to a Vocation of your choice.",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Vocation',
        options: [
          TraitOption(
            name: 'Warrior',
            description: 'A frontliner that focuses on melee combat, '
                'you are equally capable of offense and defense.\n'
                '(1)-[Passive]: Increase your Racial Life Modifier by '
                '2.\n'
                '(2)-[Passive]: While you are wielding a Weapon, '
                'increase your Damage Reduction by 2(T).\n'
                '(3)-[Passive]: While you are wielding a Weapon, reduce '
                'the Ki Point Cost for the Guard option of the Defend '
                'Maneuver by 2(T).\n'
                '(4)-[Triggered, 1/Round]: If you make an Armed Attack, '
                'spend 1 stack of Tension to increase the Damage '
                'Category of that Attacking Maneuver by 1 Category and '
                'the Wound Roll of that Attacking Maneuver by 2(T) for '
                'each Health Threshold you are below. You do not lose '
                'this stack of Tension until after you complete this '
                'Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Mage',
            description: 'Specialized in long-range magical attacks, '
                'you fight from the back lines, protected by your '
                'teammates.\n'
                '(1)-[Passive]: Reduce the Ki Point Cost of your Magic '
                'Attacks by 1(T) and reduce the TP Cost of all Magical '
                'Unique Abilities by 2.\n'
                '(2)-[Passive]: Gain access to the Boom and Zoom '
                'Special Maneuvers.\n'
                '(3)-[Triggered, 1/Round]: When using a Magic Attack '
                'that does not possess an AoE, you can spend 2(bT) Ki '
                'Points to apply a Line or Cone AoE to that Attacking '
                'Maneuver.\n'
                '(4)-[Triggered, 1/Round]: When using a Magic Attack '
                'with an AoE, you may spend up to 4(bT) Ki Points. For '
                'every 2(bT) Ki Points spent, increase the Magnitude of '
                'that Attacking Maneuver by 1.',
          ),
          TraitOption(
            name: 'Martial Artist',
            description: 'As a mid-range fighter specialized in unarmed '
                'combat, you can swap between the front lines and the '
                'rear-guard as needed.\n'
                '(1)-[Passive]: Reduce the Ki Point Cost of your '
                'Physical and Energy Attacks by 1(T).\n'
                '(2)-[Passive]: While you are not wielding a Weapon, '
                'increase your Speeds and Defense Value by 1(T).\n'
                '(3)-[1/Round]: You can spend 1 stack of Tension to use '
                'the Defend Maneuver without spending a Counter Action. '
                'If you do, the Guard Option of the Defend Maneuver has '
                'its Ki Point Cost (before any other modifications) set '
                'to 2(T).\n'
                '(4)-[Triggered, 1/Round]: If you use an Unarmed Attack '
                'that does not possess an AoE, you may spend 2(bT) Ki '
                'Points to apply a Line or Cone AoE to that Attacking '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Priest',
            description: 'Dedicated to supporting your comrades, you '
                'remain on the back line, keeping your party members in '
                'the fight.\n'
                '(1)-[Passive]: Increase your Surgency by 2(T) and '
                'reduce the Ki Point Cost of your Magical Unique '
                'Abilities by 1(T).\n'
                '(2)-[Passive]: You may use your Magic Modifier instead '
                'of your Force Modifier when calculating Surgency.\n'
                '(3)-[Passive]: Gain access to the Healing Hands Unique '
                'Ability and the Whack Special Maneuver.\n'
                '(4)-[Triggered]: If you use the Healing Hands Unique '
                'Ability, you may spend 2(bT) Ki Points to target any '
                'Ally who is not at Long Range with its effects, '
                'instead of an Ally within your Melee Range. If you do, '
                'increase the amount of Life Points they regain from '
                'this use of Healing Hands by 1/2 of your Surgency.',
            automation: [
              // (1) +2(T) Surgency ((2)'s Magic-Modifier swap and the Ki
              // Cost reduction stay manual).
              RaceTraitAutomation(
                affectedStats: [AffectedStat.surgency],
                coefficient: 2,
                tierScaling: TierScaling.current,
              ),
            ],
          ),
          TraitOption(
            name: 'Thief',
            description: 'Though extremely versatile in combat, your '
                'actual role in the group is to provide non-combat '
                'skills and scout ahead to ensure the overall safety of '
                'your teammates.\n'
                '(1)-[Passive]: Your Racial Saving Throw Bonus is '
                'applied to all of your Saving Throws.\n'
                '(2)-[Passive]: Increase the Skill Bonus of your Skills '
                'by 1.\n'
                "(3)-[1/Round, Ruling]: You may use a 'Thief Maneuver' "
                'as an Instant Maneuver if you have access to it.\n'
                '(4)-[Triggered, 1/Round]: When making a Skill Clash or '
                'a Clash that uses your Saving Throws against an '
                'Opponent, you can spend 1 Tension to increase your '
                'Dice Score by 1 or 1(T) respectively. If you win a '
                'Clash after using this effect, you may use the Basic '
                'Attack Maneuver or Signature Technique Maneuver as an '
                'Out-of-Sequence Maneuver but the Opponent you won the '
                'Clash against must be a target of that Attacking '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Ranger',
            description: 'Specialized in long-range combat with a '
                'weapon, your marksmanship is second to none.\n'
                '(1)-[Passive]: Increase your Boosted Speed by 2(T).\n'
                '(2)-[Passive]: While wielding a Weapon, increase your '
                'Strike Rolls by 1(T).\n'
                '(3)-[Triggered, 1/Round]: If you end your movement '
                'made through the Movement Maneuver adjacent to a '
                'Character, you may spend 1 Tension to apply one of the '
                'following effects depending on if that Character is '
                'an Ally or an Opponent: Ally — remove all Combat '
                'Conditions from that Ally (except Pinned, Suffocating, '
                'or Transfigured). Opponent — use the Basic Attack '
                'Maneuver as an Out-of-Sequence Maneuver (must be an '
                'Armed Attack including that adjacent Opponent as a '
                'target); after concluding it, you may move up to your '
                'Boosted Speed in a straight line away from that '
                "Opponent without triggering the Exploit Maneuver.\n"
                '(4)-[Triggered/Start of Turn]: You may spend 4(bT) Ki '
                'Points to use the Movement Maneuver as an '
                'Out-of-Sequence Maneuver.',
          ),
          TraitOption(
            name: 'Dancer',
            description: 'A skilled performer, your greatest value to '
                'the team lies in your ability to boost morale.\n'
                '(1)-[Passive]: If Personality has the highest '
                'Attribute Score among your Attributes, increase your '
                'Defense Value and Initiative by 1(bT).\n'
                '(2)-[Passive]: While Hyped, increase your Strike and '
                'Wound Rolls by 1(T).\n'
                '(3)-[Passive]: Gain access to the Dance Modifier '
                'Maneuver.\n'
                '(4)-[Triggered/Start of Combat Round]: Spend 1 Tension '
                'to use the Hype Maneuver as an Out-of-Sequence '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Gadabout',
            description: 'Chaotic and whimsical, your unpredictable '
                'nature is beneficial and detrimental in equal measure '
                'to friend and foe alike.\n'
                '(1)-[Passive]: Gain access to the Goof and the Hocus '
                'Pocus Special Maneuvers.\n'
                '(2)-[Triggered/Power]: Roll a 1d10. If you roll a 3 or '
                'less, you do not gain a stack of Power. If you roll a '
                '4 or more, gain an additional stack of Power.\n'
                '(3)-[Triggered/Start of Turn]: Roll a 1d10. If you '
                'roll a 1, spend 3 Tension or skip your turn. If you '
                'roll an 8 or higher, you may use a Standard Maneuver '
                'with an Action Cost of 1 Action as an Out-of-Sequence '
                'Maneuver.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Konatsian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Questing Wisdom',
    description:
        "Guided by truth and wisdom, you follow the surest path to your "
        "goals.\n"
        "(1)-[Passive]: Increase the number of Technique Points you "
        "gain from Skill Improvements by 3.\n"
        "(2)-[Passive]: You may use the 4th effect of the Entrusted "
        "Special State when you use the Signature Technique Maneuver "
        "instead of a Basic Attack Maneuver.\n"
        "(3)-[Triggered, 1/Round]: When you regain Ki Points through "
        "an Ally's use of the Empower Maneuver, you may use the Power "
        "Up Maneuver or Transformation Maneuver as an Out-of-Sequence "
        "Maneuver.\n"
        "(4)-[Triggered, 1/Round]: When you use the Signature Technique "
        "Maneuver, you may spend up to x(T) Life Points to increase the "
        "Wound Roll of that Attacking Maneuver by an equal amount. For "
        "this effect, x is equal to twice your number of Tension "
        "Stacks. If you are knocked through a Health Threshold by this "
        "effect, do not suffer from Reduced Momentum.\n"
        "(5)-[Triggered, 1/Encounter]: If you use an Ultimate Signature "
        "Technique, gain 1 Tension.",
  ),
  RaceTraitDef(
    race: 'Konatsian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Heart of Courage',
    description:
        "With the fire of righteousness and courage burning inside you, "
        "you seek justice on your own terms.\n"
        "(1)-[Passive]: While you possess 2+ stacks of Tension, "
        "increase the Dice Score of your Steadfast Checks by 1.\n"
        "(2)-[Passive]: While you possess 3+ stacks of Tension, "
        "increase your Soak Value by 2(T).\n"
        "(3)-[Passive]: While you are in the Entrusted State, increase "
        "your Wound Rolls by 1(T) for each stack of Tension you "
        "possess.\n"
        "(4)-[Triggered, 1/Encounter]: If you lose a Clash initiated by "
        "an Opponent that used your Saving Throws or Might, you may "
        "instead win that Clash.\n"
        "(5)-[Triggered/Start of Turn, 1/Encounter]: Ignore the "
        "effects of all Combat Conditions (except Pinned, Prone, "
        "Suffocating, or Transfigured) you are suffering from until "
        "the end of your next turn. While you are ignoring the effects "
        "of Combat Conditions through this effect, you are not "
        "considered to be suffering from any Combat Conditions for the "
        "effects of your Opponents.\n"
        "(6)-[Triggered, 1/Encounter]: After you stop ignoring the "
        "effects of Combat Conditions through the 5th effect of Heart "
        "of Courage, gain 1 Tension.",
  ),
  RaceTraitDef(
    race: 'Konatsian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Fight against Power',
    description:
        "Tenacious and determined, you stand against your foes no matter "
        "how strong they might be.\n"
        "(1)-[Passive]: While below the Injured Health Threshold, "
        "increase your Wound Rolls and Surgency by 2(T).\n"
        "(2)-[Triggered, 1/Round]: If you are hit by an Opponent's "
        "Attacking Maneuver that inflicts Damage equal to or exceeding "
        "1/4 (rounded up) of your Maximum Life Points, gain a stack of "
        "Tension.\n"
        "(3)-[Triggered, 1/Encounter]: If you apply the 4th effect of "
        "the Entrusted State to an Attacking Maneuver, you may apply "
        "an Energy Charge to that Attacking Maneuver for every 2 "
        "stacks of Tension you possess. After concluding that Attacking "
        "Maneuver, lose all stacks of Tension.",
  ),

  // ============================================================= Majin ===
  RaceTraitDef(
    race: 'Majin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Rubbery Body',
    description:
        "Stretchy and elastic, Majins are more durable than most and can "
        "easily put themselves back together.\n"
        "(1)-[Passive]: You are Unnatural.\n"
        "(2)-[Passive]: Increase your Soak Value and Defense Value by "
        "1(T).\n"
        "(3)-[Passive]: Increase your Grapple Checks as the Grappled "
        "by 1(bT) and increase the Dice Score of your Might Clash when "
        "targeted by the Pin Maneuver by 2(bT).\n"
        "(4)-[Passive]: Halve the Ki Point Cost of the Reflect Maneuver.\n"
        "(5)-[Passive]: Halve any Collision Damage you receive.\n"
        "(6)-[Passive]: Increase the Damage you receive from an "
        "Attacking Maneuver that has a Damage Category of Direct or "
        "higher by 5(bT).\n"
        "(7)-[Triggered]: When making any type of Physical Attacking "
        "Maneuver or Grapple Maneuver, you may increase your Melee "
        "Range by 3 Squares for the duration of that Maneuver.\n"
        "(8)-[Triggered, 1/Round]: Upon hitting an Opponent with a "
        "Physical Attacking Maneuver or initiating a Grapple, you may "
        "move that Character any number of Squares up to your current "
        "Melee Range in any direction — ignoring the usual rules for "
        "Movement in a Grapple if you initiated a Grapple.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak, AffectedStat.defenseValue],
        coefficient: 1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Majin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Majin Regeneration',
    description:
        "The unique composition of the Majin race allows them to quickly "
        "regenerate from any and all forms of damage.\n"
        "(1)-[Passive]: You may use your Magic Modifier instead of "
        "your Force Modifier when calculating Surgency.\n"
        "(2)-[Passive]: For each Health Threshold you are below, "
        "increase the amount of Life Points you regain from Healing "
        "Surges by 2(bT).\n"
        "(3)-[1/Round]: As a Standard Maneuver with an Action Cost of "
        "1 Action, use a Healing Surge.\n"
        "(4)-[Triggered/Threshold]: Use a Healing Surge as an "
        "Out-of-Sequence Maneuver.\n"
        "(5)-[Triggered/Defeated]: Use a Healing Surge as an "
        "Out-of-Sequence Maneuver. If you do, double the amount of "
        "Life Points you regain from this Healing Surge.",
  ),
  RaceTraitDef(
    race: 'Majin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Secondary Traits (choose 4)',
    description:
        "Unlike other creatures, the Majin are a whimsical and magical "
        "people who show a wild array of wonderful and wacky abilities. "
        "Instead of fixed Secondary Racial Traits, choose up to 4 from: "
        "Bouncy Physique, Burrowed Strike, Dangerous Liquid, Disarming "
        "Demeanor, Elastic Tentacle, Magical Being, Majin Malice, Majin "
        "Mass-Shift, Majin Mentality, Majin See Majin Do, Majin Style, "
        "Quick Sleep, Revenge Bomber, Snack Motivated, Steaming Fury, or "
        "Transfiguration Beam.",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Choose up to 4',
        maxChoices: 4,
        options: [
          TraitOption(
            name: 'Bouncy Physique',
            description: "With your body's unique composition, you are "
                'able to bounce around the battlefield like a rubber '
                'ball.\n'
                '(1)-[Passive]: Increase your Strike Rolls by 2(T) when '
                'using the Reflect Maneuver.\n'
                '(2)-[Triggered, 1/Round]: If you are hit by an '
                'Attacking Maneuver, after calculating Damage, you may '
                'move any number of Squares away from your Opponent in '
                'a straight line up to your Might. This movement does '
                'not provoke the Exploit Maneuver, even if you leave '
                'their Melee Range.\n'
                '(3)-[Triggered, 1/Round]: If you receive Collision '
                'Damage, you may end any movement you would normally '
                'suffer and immediately use the Movement Maneuver as an '
                'Out-of-Sequence Maneuver.',
          ),
          TraitOption(
            name: 'Burrowed Strike',
            description: 'Your erratic, unpredictable strikes can '
                "burrow through the earth to hit opponents who can't "
                'see it coming.\n'
                '(1)-[Triggered]: When making a Physical Attack, you '
                'may target any Opponent within the Standard '
                'Environment who is not at Long Range for that '
                'Attacking Maneuver, ignoring Cover. This Attacking '
                'Maneuver triggers the Exploit Maneuver for any '
                'Opponent on an adjacent Square to you.\n'
                '(2)-[Triggered, 1/Round]: When making an Attacking '
                'Maneuver of the Simple Profile, you may spend 2(bT) Ki '
                'Points to double the amount of Diminishing Defense '
                'your Opponent suffers from that Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Dangerous Liquid',
            description: 'Able to shift your body into a liquid form, '
                'you can enter another\'s body and destroy them from '
                'within.\n'
                '(1)-[Passive]: You gain access to the Liquid Form '
                'Special Maneuver. While in the Liquid Form, you gain '
                'access to the Internal Attack Special Maneuver.',
          ),
          TraitOption(
            name: 'Disarming Demeanor',
            description: 'Your off-putting, bizarre anatomy and '
                'generally unnatural personality make you impossible to '
                'read for most normal beings, offering you the '
                'advantage in combat.\n'
                '(1)-[Triggered, 1/Round]: If you fail to hit an '
                'Opponent with an Attacking Maneuver, make a Clash '
                '(Bluff vs Perception/Intuition) against that Opponent. '
                'If you win, you may use the Basic Attack Maneuver '
                'against that Opponent as an Out-of-Sequence Maneuver.\n'
                '(2)-[Triggered, 1/Round]: If you are hit by an '
                "Opponent's Attacking Maneuver, make a Clash (Bluff vs "
                'Perception/Intuition) against that Opponent. If you '
                'win, instead of taking Damage, the Attacking Maneuver '
                'returns to Defense Declaration and you may attempt to '
                'dodge that Attacking Maneuver again or use a Counter '
                'Maneuver instead.\n'
                '(3)-[Triggered, 1/Encounter]: If an Opponent uses a '
                'Counter Maneuver in response to your Attacking '
                'Maneuver, you may choose to cancel your Attacking '
                'Maneuver (regaining any Ki Points spent) and use the '
                'Basic Attack Maneuver or Signature Technique Maneuver '
                'instead (against that Counter Maneuver).',
          ),
          TraitOption(
            name: 'Elastic Tentacle',
            description: "You don't really have a tail, per se, but "
                'the tentacle(s) on your head sure put in work.\n'
                '(1)-[Passive]: You gain access to the Tail Attack '
                'Special Maneuver.\n'
                '(2)-[Passive]: Increase the Strike Rolls of your '
                'Physical Attacks by 1(T).\n'
                '(3)-[Triggered]: If you hit an Opponent with the Tail '
                'Attack Maneuver, double the amount of Diminishing '
                'Defense they suffer from that Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Magical Being',
            description: 'Your innate magical ability allows you to '
                'pick up on magic far easier than most other people.\n'
                '(1)-[Passive]: Reduce the TP Cost of all Magical '
                'Unique Abilities for you by 3.\n'
                '(2)-[Passive]: You gain access to the Magical '
                'Materialization, Healing Hands, and Telekinesis Unique '
                'Abilities.',
          ),
          TraitOption(
            name: 'Majin Malice',
            description: 'Your regenerative powers allow you to force '
                'your body past the limits most species would be able '
                'to survive.\n'
                '(1)-[Triggered, 1/Round]: If you would use a Healing '
                'Surge, you may forgo gaining Life Points to instead '
                'regain an equal amount of Ki Points and Capacity '
                'instead. This can allow your Capacity to exceed your '
                'Max Capacity.\n'
                '(2)-[Triggered, 1/Encounter]: If you would use an '
                'Ultimate Signature Technique, you may apply up to 5 '
                'ranks of Backlash to that Signature Technique. For '
                'each rank of Backlash added, increase the Wound Roll '
                'of that Signature Technique by 2(T).\n'
                '(3)-[Triggered/Power, 1/Round, 3/Encounter]: You may '
                'spend 5(bT) Life Points to use the Basic Attack '
                'Maneuver, Signature Technique Maneuver, or Energy '
                'Charge Maneuver as an Out-of-Sequence Maneuver.',
          ),
          TraitOption(
            name: 'Majin Mass-Shift',
            description: 'You have the ability to sculpt your body at '
                'will.\n'
                '(1)-[Passive]: You gain access to the Shapeshift '
                'Unique Ability. You cannot swap this Racial Trait out '
                'through its effects.\n'
                '(2)-[Passive]: Increase the Dice Score of your Bluff, '
                'Persuasion, and Intimidation Skill Checks by 1.\n'
                '(3)-[Passive]: Depending on your Size Category, apply '
                'the following effects: Smaller than Medium — increase '
                'your Soak Value by 1(bT). Medium — reduce the Ki Point '
                'Cost of your Unique Abilities by 2(T). Larger than '
                'Medium — increase your Defense Value by 1(bT).',
          ),
          TraitOption(
            name: 'Majin Mentality',
            description: "You're smarter and/or friendlier than the "
                'average Majin.\n'
                '(1)-[Passive]: While Personality and/or Scholarship is '
                'your Attribute with the highest Attribute Score, '
                'increase your Combat Rolls and Initiative by 1(bT).\n'
                '(2)-[Triggered, 1/Round]: If you use a Signature '
                'Technique, increase the Wound Roll of that Attacking '
                'Maneuver by 1/2 (rounded up) of your Scholarship or '
                'Personality Modifier (whichever is higher).',
          ),
          TraitOption(
            name: 'Majin See, Majin Do',
            description: 'Known for your childlike innocence and '
                'demeanor, you are able to pick things up much faster '
                'than others, just like a child.\n'
                '(1)-[Passive]: Gain the Quick Learner Talent (even if '
                'you do not meet the Prerequisites), but ignore the '
                '3rd effect of that Talent.\n'
                "(2)-[Passive]: You may ignore the effects of any "
                "Disadvantage with 'Restricted' in its name on any "
                'Signature Technique or Aura you have gained through '
                'the effects of Quick Learner.\n'
                '(3)-[Passive]: For Copied Techniques, you may use '
                'either your Force or Magic Modifier as the Damage '
                'Attribute and ignore the Force Score prerequisite to '
                'use Energy Attacks.\n'
                '(4)-[Triggered, 1/Encounter]: When you target an '
                'Opponent with a Copied Technique, make a Morale Clash '
                'against them. If you win, they have Guard Down against '
                'this Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Majin Style',
            description: 'Your clothes are clearly part of your body, '
                'allowing them to reform with you and grow in power as '
                'you do.\n'
                "(1)-[Passive, Ruling]: Upon gaining access to this "
                "Racial Trait, create a piece of Apparel with a "
                "Craftsmanship Grade of 2 and no Apparel Qualities, "
                "known as your 'Default Costume'.\n"
                '(2)-[Passive]: Each time you reach a new base Tier of '
                'Power after the first, gain 1 Equipment Point to spend '
                'on improving your Default Costume.\n'
                '(3)-[Adventurous]: You may spend 5 minutes to fully '
                'repair your Default Costume.\n'
                '(4)-[1/Character]: If your base Tier of Power is 5+, '
                'upon gaining an Equipment Point through the 2nd '
                'effect of Majin Style, you may spend that Equipment '
                'Point to gain an applicable Special Apparel Quality of '
                'your choice on your Default Costume.\n'
                '(5)-[Triggered, 1/Round]: If you use a Healing Surge '
                'while wearing your Default Costume, that piece of '
                'Apparel regains 1 Break Value.\n'
                '(6)-[Triggered, 1/Encounter]: At the end of each '
                'Combat Encounter, your Default Costume is fully '
                'repaired.',
          ),
          TraitOption(
            name: 'Quick Sleep',
            description: "You don't need to sleep, but a quick nap "
                'never hurts.\n'
                '(1)-[Passive]: Your Defense Value is not reduced by '
                'the effects of the Combat Recovery Maneuver.\n'
                '(2)-[Triggered, 2/Encounter]: When using the Combat '
                'Recovery Maneuver, reduce the Action Cost by 1.\n'
                '(3)-[Triggered, 1/Encounter]: At the end of your turn, '
                'you may gain the Sleeping Combat Condition until the '
                'start of your next turn. At the start of your next '
                'turn, if you lose the Sleeping Combat Condition '
                'through this effect, regain 1/4 of your Maximum Life '
                'Points and 1/4 of your Maximum Ki Points.',
          ),
          TraitOption(
            name: 'Revenge Bomber',
            description: "Able to blow yourself up to take out the "
                "competition, you're well aware that you can put "
                'yourself back together after.\n'
                '(1)-[Passive]: Increase the Wound Roll of any '
                'Attacking Maneuver of the Explosion Profile that '
                'possesses the Self-Explosion Disadvantage by 3(T).\n'
                '(2)-[Triggered, 1/Encounter]: When using an Attacking '
                'Maneuver of the Explosion Profile, you may apply the '
                'Self-Explosion Disadvantage to that Attacking Maneuver '
                'to apply the Final Chance Advantage to that Attacking '
                'Maneuver (even if it is not an Ultimate Signature '
                'Technique).\n'
                '(3)-[Triggered/Defeated]: If you are Defeated by one '
                'of your effects reducing your Life Points to 0, '
                'immediately use a Healing Surge and increase the Dice '
                'Score by 1d6(T).',
          ),
          TraitOption(
            name: 'Snack Motivated',
            description: "With a body powered by sugary sweets and a "
                "bottomless appetite, it turns out that you'll do "
                'almost anything for a tasty treat.\n'
                '(1)-[Passive]: Gain access to the Snack Fiend Talent.\n'
                '(2)-[Passive]: Double the amount of Life and Ki '
                'Points regained from the Snack Basic Item.\n'
                "(3)-[Triggered/Power, 1/Round]: If you've used the "
                'Snack Basic Item during this Combat Round, gain an '
                'additional stack of Power through this use of the '
                'Power Up Maneuver.',
          ),
          TraitOption(
            name: 'Steaming Fury',
            description: 'With your hair-trigger temper, you can '
                'spout steam from your body whenever you get angry.\n'
                '(1)-[Passive]: Ignore the effects of the Obscured '
                'Environmental Quality.\n'
                '(2)-[Triggered/Raging]: All Squares within a Standard '
                'Sphere AoE (centered on you) gain the Obscured '
                'Environmental Quality until the end of your next '
                'turn.\n'
                '(3)-[Triggered/Power, 1/Round, 3/Encounter]: Enter the '
                'Raging State until the end of your next turn.',
          ),
          TraitOption(
            name: 'Transfiguration Beam',
            description: 'You can fire a magical beam that transforms '
                'characters into an object!\n'
                '(1)-[Passive]: Reduce the Critical Target of your '
                'Strike Rolls for your Energy and Magic Attacks by 1.\n'
                '(2)-[Passive]: Gain access to the Transfiguration '
                'Special Maneuver. For the Transfiguration Maneuver, '
                'you gain the following effects: you can target any '
                'Opponent who is not at Long Range; you can make a '
                'Strike Roll as if making a Magic Attack instead of a '
                'Physical Attack.',
          ),
        ],
      ),
    ],
  ),

  // ========================================================= Namekian ===
  RaceTraitDef(
    race: 'Namekian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Namekian Biology',
    description:
        "Namekians possess the unique ability to rapidly expand and "
        "divide their cells at will, allowing them to regrow limbs, "
        "stretch or grow to gigantic proportions, or regenerate damage "
        "with a thought, so long as their heads are intact. They also "
        "possess exceptional hearing.\n"
        "(1)-[Passive]: Reduce the Critical Target of your Clairvoyance "
        "and Perception Skill Checks by 1.\n"
        "(2)-[Passive]: Increase the Dice Score of your Steadfast "
        "Checks by 1.\n"
        "(3)-[1/Round]: As a Standard Action with an Action Cost of 1 "
        "Action and a Ki Point Cost of 4(bT) Ki Points, use a Healing "
        "Surge. Each time you use this effect after the first, "
        "increase the Ki Point Cost by 2(bT) for the remainder of the "
        "Combat Encounter.\n"
        "(4)-[Triggered]: When making any type of Physical Attacking "
        "Maneuver or Grapple Maneuver, you may increase your Melee "
        "Range by 3 Squares for the duration of that Maneuver.\n"
        "(5)-[Triggered, 1/Round]: Upon hitting an Opponent with a "
        "Physical Attacking Maneuver or initiating a Grapple, you may "
        "move that Character any number of Squares up to your current "
        "Melee Range in any direction — ignoring the usual rules for "
        "Movement in a Grapple if you initiated a Grapple.\n"
        "(6)-[Triggered/Start of Combat Round]: Regain 3(bT) Life "
        "Points.",
  ),
  RaceTraitDef(
    race: 'Namekian',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Intelligent Fighter',
    description:
        "Known as some of the most intelligent fighters in the universe, "
        "the Namekian people can quickly learn the fighting style of their "
        "opponent and use that knowledge to find openings others may "
        "miss.\n"
        "(1)-[Passive]: At Character Creation, select a Skill that "
        "uses Insight as its Attribute. You gain a Skill Rank in the "
        "Skill selected for this effect.\n"
        "(2)-[Triggered, Ruling]: At the end of each Combat Round, "
        "select a Character (except yourself) that has used at least "
        "1 Attacking Maneuver during this Combat Round. That selected "
        "Character becomes 'Studied' until the end of the next Combat "
        "Round.\n"
        "(3)-[Triggered, 1/Round]: If you Defeat a Studied Opponent "
        "with an Attacking Maneuver, regain Ki Points equal to your "
        "Surgency.\n"
        "(4)-[Triggered, 1/Round]: If a Studied Ally would be Defeated "
        "by the Damage from an Opponent's Attacking Maneuver, reduce "
        "the Damage by your Surgency.\n"
        "(5)-[Passive]: Increase your Combat Rolls by 1(T) against "
        "Studied Opponents.\n"
        "(6)-[Passive]: Increase the Combat Rolls of Studied Allies by "
        "1(T).",
  ),
  RaceTraitDef(
    race: 'Namekian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Namekian Techniques',
    description:
        "Known for their magical prowess, even among their warriors, this "
        "peace-loving race has developed certain techniques over time for "
        "both times of peace and times of war.\n"
        "(1)-[Passive]: You gain access to the Magical Materialization "
        "and Telekinesis Unique Abilities.\n"
        "(2)-[Passive]: You gain access to the Unify Maneuver.\n"
        "(3)-[Passive]: Increase the number of Technique Points you "
        "gain from Skill Improvements by 3.\n"
        "(4)-[Triggered/Power, 1/Round]: Target an Opponent: If your "
        "targeted Opponent is Studied, you may use the Signature "
        "Technique Maneuver or Basic Attack Maneuver as an "
        "Out-of-Sequence Maneuver. If you do, the Opponent you "
        "targeted for this effect must be a target for this Attacking "
        "Maneuver. If your targeted Opponent is not Studied, they "
        "become Studied until the end of the Combat Round.",
  ),
  RaceTraitDef(
    race: 'Namekian',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Telepathic Warning',
    description:
        "With their inherent grasp of telepathy and their peaceful, "
        "social nature, Namekians are capable of great feats of teamwork, "
        "helping each other to avoid attacks.\n"
        "(1)-[Passive]: You gain access to the Telepathy Unique "
        "Ability.\n"
        "(2)-[Triggered, 2/Round]: If an Opponent targets you and/or "
        "an Ally with an Attacking Maneuver, you may immediately "
        "increase the Dodge Roll of yourself and any Allies targeted "
        "by that Attacking Maneuver by 1(T) for the duration of that "
        "Attacking Maneuver. If an Ally is Studied, double this "
        "increase to their Dodge Roll.\n"
        "(3)-[Triggered, 1/Round]: When you trigger the second effect "
        "of Telepathic Warning, if the attacker is a Studied Opponent, "
        "you may spend a Counter Action to increase the bonus to "
        "Dodge Rolls from this effect by 2(T).",
  ),

  // ======================================================= Neko Majin ===
  RaceTraitDef(
    race: 'Neko Majin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Neko Majin-Dama',
    description:
        "You possess a Majin-Dama, a wondrous ball stored in your body "
        "that grants you special abilities.\n"
        "(1)-[Passive]: You gain access to the Illusion and Shapeshift "
        "Unique Abilities.\n"
        "(2)-[Passive]: At Character Creation, create a Majin-Dama "
        "Special Accessory, which is Integrated into your Character. "
        "Another Character may take an Integrated Majin-Dama from you "
        "using the Snatch Special Maneuver if you are Defeated or "
        "Sleeping. That Character automatically wins the Clash if you "
        "are Defeated; if they lose the Clash while you are Sleeping, "
        "you lose the Sleeping Combat Condition. A stolen Majin-Dama "
        "stops being Integrated.\n"
        "(3)-[1/Round]: You can spend 1 Action to Integrate a "
        "Majin-Dama you possess.\n"
        "(4)-[1/Round]: As an Instant Maneuver, you can spend 1 Action "
        "to expel an Integrated Majin-Dama from your body. When you "
        "do, it stops being Integrated and is dropped or Equipped "
        "(your choice).\n"
        "(5)-[Passive]: If you have no Integrated Majin-Dama, reduce "
        "your Combat Rolls and Soak Value by 2(T) and you cannot use "
        "Signature Techniques, Unique Abilities, or enter "
        "Transformations. While you are suffering from these effects, "
        "you may, with ARC permission, spend 2 Karma Points to create "
        "a new Majin-Dama and Integrate it.\n"
        "(6)-[x/Encounter]: Use a Surge of your choice as an Instant "
        "Maneuver. x, for this effect, is equal to your number of "
        "Integrated Majin-Dama (even if they are Inactive).\n"
        "(7)-[Triggered, x/Encounter]: When you make a roll of any "
        "kind, after seeing the result, you may reroll that roll. x, "
        "for this effect, is equal to your number of Integrated "
        "Majin-Dama (even if they are Inactive).\n"
        "\n"
        "Majin-Dama Special Item: A mystical orb originally contained "
        "in the body of a Neko Majin. Effect: Increase your Combat "
        "Rolls and Soak Value by 1(T) and your Maximum Ki Points by 2 "
        "for each Power Level reached.",
  ),
  RaceTraitDef(
    race: 'Neko Majin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Neko Mimicry',
    description:
        "Neko Majins can unerringly replicate the techniques of others "
        "with ease after witnessing them, often putting a spin on them to "
        "boot.\n"
        "(1)-[Passive]: At Character Creation, gain the Quick Learner "
        "Talent.\n"
        "(2)-[Passive]: You may ignore the effects of any Disadvantage "
        "with 'Restricted' in its name on any Signature Technique you "
        "have gained through the effects of Quick Learner (either as "
        "Copied Techniques or those you have gained through the second "
        "effect of Quick Learner).\n"
        "(3)-[Passive]: For Copied Techniques, you may use either your "
        "Force or Magic Modifier as the Damage Attribute and ignore "
        "the Force Score prerequisite to use Energy Attacks.\n"
        "(4)-[Triggered, 1/Round]: If an Opponent who is not at Long "
        "Range uses a Standard Maneuver with an Action Cost of 1 "
        "Action, you may use that Maneuver as an Out-of-Sequence "
        "Maneuver. If the Maneuver was a Special Maneuver, you must "
        "have access to that Special Maneuver to use it.\n"
        "(5)-[Triggered, 1/Round]: If you use a Copied Technique "
        "possessed by a Character, apply the following effects "
        "depending on if that Character is an Ally or an Opponent: "
        "Ally — that Ally may use the United Attack Maneuver without "
        "spending an Action through its effects (they must still be on "
        "an adjacent Square to you). Opponent — make a Clash (Morale) "
        "against that Opponent. If you win, they suffer from the Guard "
        "Down Combat Condition for the duration of that Attacking "
        "Maneuver.\n"
        "(6)-[Triggered, 1/Encounter]: When using a Copied Technique, "
        "you may apply the Multi-Profile Super Profile to that "
        "Attacking Maneuver. If you do, you must select a Profile that "
        "is used by at least 1 of your Signature Techniques.",
  ),
  RaceTraitDef(
    race: 'Neko Majin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Feline Build',
    description:
        "While Neko Majins may not be cats, they share many of the same "
        "traits.\n"
        "(1)-[Passive]: At Character Creation, gain two Bestial Traits "
        "from the following options: Bestial Build, Land-Based Beast, "
        "Claws, or Fangs.\n"
        "(2)-[Passive]: Increase the Dice Score of your Perception "
        "Skill Checks by 2.\n"
        "(3)-[Triggered/Start of Turn]: While you have an Integrated "
        "Majin-Dama, regain 5(bT) Ki Points.\n"
        "(4)-[Triggered, 1/Round]: If you receive no Damage from an "
        "Attacking Maneuver that targets you, you may use the "
        "Signature Technique Maneuver as an Out-of-Sequence Maneuver. "
        "If you do, your Attacking Maneuver must be a Copied "
        "Technique.",
    automation: [
      // (2) +2 Perception Skill Checks (flat).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.skillPerception],
        coefficient: 2,
      ),
    ],
    beastGrants: [
      // (1) "gain two Bestial Traits from: Bestial Build, Land-Based Beast,
      // Claws, or Fangs."
      BeastTraitGrant(
        kind: BeastTraitKind.bestial,
        count: 2,
        restrictedTo: ['Bestial Build', 'Land-Based Beast', 'Claws', 'Fangs'],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Neko Majin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Quick Thinking',
    description:
        "Neko Majins are known for their ability to pick up tactics on "
        "their feet.\n"
        "(1)-[Passive]: Increase the amount of Technique Points you "
        "gain from Skill Improvement by 3.\n"
        "(2)-[Passive]: Any Signature Techniques gained through the "
        "4th effect of Quick Learner are still considered 'Copied "
        "Techniques' for all of your effects (except those of Quick "
        "Learner).\n"
        "(3)-[Triggered]: When you use the Signature Technique "
        "Maneuver to use a Signature Technique other than a Copied "
        "Technique, for this instance of using your chosen Signature "
        "Technique, you may add a single Advantage with a TP cost of "
        "up to 10 TP to your chosen Signature Technique if one of your "
        "Copied Techniques possesses that Advantage.",
  ),

  // ======================================================= Neo-Tuffle ===
  RaceTraitDef(
    race: 'Neo-Tuffle',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Energy of Revenge',
    description:
        "Created by Tuffle scientists for the sole purpose of enacting "
        "vengeance on those who slaughtered the fallen Tuffles, Neo-"
        "Tuffles draw strength from their single-minded hatred.\n"
        "(1)-[Triggered, Resource]: Whenever you receive Damage from "
        "an Opponent's Attacking Maneuver, gain 1 Revenge Point (max. "
        "4). When making an Attacking Maneuver, you may spend any "
        "number of Revenge Points to increase your Wound Roll by 1(T) "
        "for each point spent. Double this effect if your Attacking "
        "Maneuver is an Ultimate Signature Technique.\n"
        "(2)-[Passive]: You cannot gain the Poisoned Combat Condition.\n"
        "(3)-[Passive]: You can only wear a single layer of Apparel, "
        "but increase your Soak Value by 1(bT).",
    grantedResources: [
      GrantedResource(
        name: 'Revenge Point',
        maxStacks: 4,
        description: 'Gained when you take Damage; spend on an attack '
            'for +1(T) Wound each (doubled on Ultimate Signature '
            'Techniques).',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Neo-Tuffle',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Tuffle Superiority',
    description:
        "Born with a belief in the superior intelligence of Tuffles, Neo-"
        "Tuffles look down on all other races.\n"
        "(1)-[Triggered/Start of Combat Round, Ruling]: Target an "
        "Opponent. That Opponent becomes your 'Inferior' until the end "
        "of the Combat Round.\n"
        "(2)-[Passive]: Increase your Combat Rolls by 1(T) against "
        "your Inferior.\n"
        "(3)-[Passive]: If you possess the Energy of Revenge Trait, "
        "double the amount of Revenge Points you gain from Attacking "
        "Maneuvers made by your Inferior. If you do not, increase your "
        "Wound Rolls by an additional 1(T) against your Inferior.\n"
        "(4)-[Triggered, 1/Encounter]: Upon declaring an Inferior, if "
        "they are currently in a higher Health Threshold than you, you "
        "may enter the Surging State until the end of your next turn. "
        "If you do, you must target your Inferior for the effects of "
        "the Surging State and you can only target that Opponent for "
        "the first effect of the Tuffle Superiority Trait until you "
        "leave the Surging State. You immediately leave the Surging "
        "State that you entered through this effect if your Inferior "
        "is Defeated.",
  ),
  RaceTraitDef(
    race: 'Neo-Tuffle',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Legacy of the Scholars',
    description:
        "You possess the great wisdom of the Tuffles and know when to go "
        "all in as well as when to fold.\n"
        "(1)-[Passive]: Apply your Greater Dice to the Wound Roll(s) "
        "of your Signature Techniques if their target(s) include your "
        "Inferior.\n"
        "(2)-[Triggered]: If you would use a Super Signature, you may "
        "spend 2 Revenge Points to apply the Ascended Signature "
        "Advantage to that Attacking Maneuver.\n"
        "(3)-[Triggered, 1/Encounter]: When you are targeted by an "
        "Attacking Maneuver with 3+ Energy Charges, you may use the "
        "Defend Maneuver without spending a Counter Action and "
        "ignoring the increase to the Ki Point Cost of the Guard "
        "option of the Defend Maneuver from any Energy Charges on "
        "that Attacking Maneuver.",
  ),
  RaceTraitDef(
    race: 'Neo-Tuffle',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Violent Rebuke',
    description:
        "Built to withstand the brutal punishment that annihilated the "
        "Tuffle race, you can take a hit and dish out one in return.\n"
        "(1)-[Passive]: You may use your Scholarship or Personality "
        "Modifier instead of your Force Modifier for the effects of "
        "Surgency.\n"
        "(2)-[Triggered/Threshold]: If you succeed at the Steadfast "
        "Check for this Health Threshold, use a Healing or Ki Surge "
        "(you decide) as an Out-of-Sequence Maneuver.\n"
        "(3)-[Triggered, 1/Round]: After completing an Opponent's "
        "Attacking Maneuver that targeted you, regardless of if it "
        "hits, you may make a Basic Attack Maneuver against them as an "
        "Out-of-Sequence Maneuver. You cannot Ki Wager on this "
        "Attacking Maneuver unless that Opponent was your Inferior.",
  ),

  // ============================================================= Saiyan ===
  RaceTraitDef(
    race: 'Saiyan',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Born for Battle',
    description:
        "A warrior race evolved for eternal combat, Saiyans adapt as "
        "battle wears on, allowing them to adjust to the fight before them "
        "and grow stronger the longer they fight for.\n"
        "(1)-[Triggered, Resource]: At the start of every even-numbered "
        "Combat Round, you gain 1 stack of Battle Born. Whenever you gain "
        "a stack of Battle Born, you must apply it to either Strike, "
        "Dodge, or Wound (you decide). You can only have up to 2 stacks "
        "of Battle Born on a single Combat Roll. Each stack of Battle "
        "Born increases the corresponding Combat Roll by 1(T).\n"
        "(2)-[Triggered/Threshold]: Use a Ki Surge as an Out-of-Sequence "
        "Maneuver. If you do, gain a stack of Battle Born.\n"
        "(3)-[Triggered, 1/Encounter]: If you trigger the 2nd effect of "
        "Saiyan Heritage, set the number of Battle Born stacks on each "
        "Combat Roll to 3, regardless of the limit. This effect cannot "
        "decrease the number of Battle Born stacks on any Combat Roll.\n"
        "(4)-[Triggered, 1/Encounter]: If you are knocked through the "
        "Critical Health Threshold, or trigger an effect with the "
        "Triggered/Defeated Keyword, gain a stack of the Zenkai Awakening "
        "as a Level 1 Temporary Awakening.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.strike],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Battle Born (Strike)',
      ),
      RaceTraitAutomation(
        affectedStats: [AffectedStat.dodge],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Battle Born (Dodge)',
      ),
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Battle Born (Wound)',
      ),
    ],
    grantedResources: [
      GrantedResource(
        name: 'Battle Born (Strike)',
        maxStacks: 2,
        description: "Battle Born stacks you've applied to Strike "
            'Rolls. Each stack is +1(T) Strike (automated below). Capped '
            "at 2 (3 if you've triggered Saiyan Heritage's 2nd effect "
            'this Encounter — raise the Max Stacks by hand if so).',
      ),
      GrantedResource(
        name: 'Battle Born (Dodge)',
        maxStacks: 2,
        description: "Battle Born stacks you've applied to Dodge "
            'Rolls. Each stack is +1(T) Dodge (automated below). Capped '
            'at 2 (3 under the same Saiyan Heritage condition above).',
      ),
      GrantedResource(
        name: 'Battle Born (Wound)',
        maxStacks: 2,
        description: "Battle Born stacks you've applied to Wound "
            'Rolls. Each stack is +1(T) Wound (automated below). Capped '
            'at 2 (3 under the same Saiyan Heritage condition above). '
            'Each stack you gain must be assigned to only one of '
            'Strike/Dodge/Wound — track them as separate Resource rows '
            "since that's how the Trait actually splits them.",
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Saiyan',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Saiyan Heritage',
    description:
        "A warrior race evolved with a monkey-like tail which, in the "
        "light of the full moon, allows them to transform into the mighty "
        "Oozaru, Saiyans are extremely hard to kill.\n"
        "(1)-[Passive]: You automatically succeed all Steadfast Checks "
        "for the Bruised Health Threshold. You also cannot gain any "
        "failures for the Bruised Health Threshold due to any rules "
        "like Massive Damage or any effects such as Pain to Power.\n"
        "(2)-[Triggered/Defeated]: You may make a Steadfast Check (if "
        "you do, reduce your Dice Score by 2). If you succeed, you "
        "enter the Undying State until the end of your next turn.\n"
        "(3)-[Addendum]: Please refer to the 'Saiyan Tail' text below.\n"
        "(4)-[Automatic]: If you suffer from Tail Restraint during a "
        "Grapple while you are Tailed, you are immediately knocked "
        "Prone and cannot remove the Prone Combat Condition until you "
        "escape the Grapple.\n"
        "(5)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Tailed',
            description: '[Passive]: You possess a tail. While you '
                'possess that tail, you have access to the Oozaru '
                'Alternate Form and increase your Stress Bonus by 1. '
                'When your base Tier of Power is 5+, double this bonus.'
                '\n\n'
                'Saiyan Tail: Tailed Saiyans can lose their tail through '
                'the Called Shot Maneuver. If their tail is targeted '
                'and hit by a Called Shot of the Lethal Damage '
                'Category, or one made with a Weapon of the Slashing '
                'Weapon Category that deals Damage equal to or '
                "exceeding 1/4 (rounded up) of the Saiyan's Maximum "
                'Life Points, their tail is removed and they are not '
                'treated as Tailed (or benefiting from its effects) '
                'until they regrow their tail. Upon losing a tail, a '
                'Saiyan may select either: Regrow — roll a 1d4+1 for '
                'the number of Combat Encounters (or an equivalent '
                "real-time period, at the ARC's discretion) until the "
                'tail grows back; during the final Combat Encounter, '
                'if below the Injured Health Threshold, you may spend '
                'a Karma Point as an Instant Maneuver to instantly '
                'regrow it. Accept — your choice for the Option effect '
                'of Saiyan Heritage becomes Tailless.',
          ),
          TraitOption(
            name: 'Tailless',
            description: '[Passive]: Increase your Wound Rolls and '
                'Soak Value by 1(T) while in a Form and/or Enhancement.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Saiyan',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: "Warrior's Pride",
    description:
        "A proud race of warriors, Saiyans often hold their reputation "
        "above all else, believing themselves superior to all others in "
        "the heat of battle.\n"
        "(1)-[Passive]: Apply your Racial Saving Throw Bonus to Cognitive "
        "as well as Corporeal.\n"
        "(2)-[Passive]: While Superior, ignore Health Threshold Penalties "
        "and the Impaired/Fatigued Combat Conditions.\n"
        "(3)-[Triggered/Raging, Triggered/Power, 1/Encounter]: Enter the "
        "Superior State until end of next turn.\n"
        "(4)-[Triggered/Start of Combat Encounter]: Gain a stack of Battle "
        "Born.",
  ),
  RaceTraitDef(
    race: 'Saiyan',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Blood of the Warrior',
    description:
        "With their constant fighting, Saiyans evolved to grow stronger "
        "the more damage they take, allowing them to survive battles they "
        "would otherwise have lost.\n"
        "(1)-[Passive]: For each Health Threshold you are below, increase "
        "your Wound Rolls, Soak Value and Surgency by 1(T).\n"
        "(2)-[Triggered, 1/Encounter]: Double your Surgency for a Healing "
        "Surge.\n"
        "(3)-[Triggered/Start of Turn, 1/Encounter]: With 6+ Battle Born "
        "stacks, or below Injured, increase your Tier of Power by +1 "
        "until end of turn.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
          AffectedStat.soak,
          AffectedStat.surgency,
        ],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perHealthThresholdBelow,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Saiyan',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Powerful Physique',
    description:
        "With strong bodies built for battle, Saiyans can endure massive "
        "blows and continue to dish out great amounts of damage.\n"
        "(1)-[Passive]: Increase your Soak Value by 1/4 of your Force "
        "Modifier (rounded up).\n"
        "(2)-[Passive]: While you possess 2+ stacks of Power, increase "
        "your Force Modifier by 1(T).\n"
        "(3)-[Triggered, 1/Round]: Using the Defend Maneuver doubles the "
        "bonus to Soak from effect 1 for that Maneuver.\n"
        "(4)-[Triggered, 1/Encounter]: After being hit, use the Basic "
        "Attack Maneuver Out-of-Sequence with +Force Modifier Wound.",
    automation: [
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.force,
        fractionDenominator: 4,
        roundUp: true,
      ),
    ],
  ),

  // ==================================================== Shadow Dragon ===
  RaceTraitDef(
    race: 'Shadow Dragon',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Negative Ki',
    description:
        "Produced by the overwhelming negative energy stored in the "
        "Dragon Balls over time when they are overused, Shadow Dragons can "
        "tap into the force that created them to manipulate reality.\n"
        "(1)-[Triggered/Start of Combat Round, Resource]: Reduce your Life "
        "Points by up to 8(bT); every 2(bT) lost grants 1 Negative "
        "Energy.\n"
        "(2)-[Triggered/Start of Turn]: Spend Negative Energy on a Morale "
        "Clash against equal Opponents — win inflicts Impaired.\n"
        "(3)-[Triggered]: Spend up to 2 Negative Energy to reduce an "
        "Impaired Opponent's Natural Result within your Melee Range.\n"
        "(4)-[Triggered]: Gaining Negative Energy regains 1(T) Ki per "
        "point.\n"
        "(5)-[Automatic]: Lose all Negative Energy at Round end, regaining "
        "1(T) Ki per point lost.",
    grantedResources: [
      GrantedResource(
        name: 'Negative Energy',
        maxStacks: 10,
        description: 'Gained by voluntarily losing Life Points at the '
            'start of a Combat Round (2(bT) Life per point); spend on '
            'Morale Clashes, softening Impaired Opponents\' rolls, and '
            'more. No stated maximum on the site.',
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Shadow Dragon',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Personified Dragon Ball',
    description:
        "Tied to one of the Dragon Balls, your true form is actually one "
        "of the magical wish-granting orbs and, as its representative, "
        "you have unique abilities.\n"
        "(1)-[Passive]: Gain 1 Bestial Trait.\n"
        "(2)-[Passive]: You gain access to the Unify Maneuver, but you "
        "can only use it on a Shadow Dragon that is from the same set "
        "of Dragon Balls as you. If that Shadow Dragon is in their Ball "
        "Form and is Defeated, they do not need to be willing for the "
        "effects of the Unify Maneuver.\n"
        "(3)-[1/Round]: As a Standard Action with an Action Cost of 1, "
        "you can transform into your Ball Form.\n"
        "(4)-[Triggered/Start of Turn]: If you are in your Ball Form, "
        "you may exit your Ball Form and return to normal.\n"
        "(5)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    beastGrants: [
      // (1) "Gain 1 Bestial Trait."
      BeastTraitGrant(kind: BeastTraitKind.bestial),
    ],
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Sinister Dragon',
            description: '[Triggered, 1/Round]: If an Opponent scores '
                'a Botch Result on their Combat Roll, or if an Opponent '
                'who is suffering from the Impaired Combat Condition '
                'failed to inflict any Damage to you with an Attacking '
                'Maneuver that targeted you, you may use the Exploit '
                'Maneuver as if they triggered its effects. '
                'Furthermore, you may spend 2 Negative Energy instead '
                'of a Counter Action to use the Exploit Maneuver '
                'through this effect.',
          ),
          TraitOption(
            name: 'Hazy Dragon',
            description: '[Triggered/Power, 1/Round]: Spend up to 4 '
                'Negative Energy to turn all Squares within a Sphere '
                'AoE (centered on you) into the Bog Environment. For '
                'every Negative Energy spent after the first, increase '
                'the Magnitude of this effect by 1.',
          ),
          TraitOption(
            name: 'Elemental Dragon',
            description: "[Passive]: Upon gaining this effect, select "
                "a Profile with 'Elemental' in the name – it becomes a "
                'Favored Element.',
          ),
          TraitOption(
            name: 'Noble Dragon',
            description: '[1/Round]: Spend 1 Action to target an '
                'Opponent. Make a Morale Clash against them. If you '
                'win, you both gain the Compelled Combat Condition '
                'against one another until the start of your next '
                'turn. While you possess the Compelled Combat '
                'Condition inflicted by this effect, increase your '
                'Soak Value and Wound Rolls by 1(T).',
          ),
          TraitOption(
            name: 'Regenerative Dragon',
            description: '[Triggered, Resource]: When you gain 4+ '
                'Negative Energy at once, gain a stack of Dragon Slime '
                '(max 3). Whenever you are knocked through a Health '
                'Threshold, you may spend a stack of Dragon Slime to '
                'use a Healing Surge.',
            grantedResources: [
              GrantedResource(
                name: 'Dragon Slime',
                maxStacks: 3,
                description: 'Gained on gaining 4+ Negative Energy at '
                    'once; spend a stack when knocked through a Health '
                    'Threshold to use a Healing Surge.',
              ),
            ],
          ),
          TraitOption(
            name: 'Ominous Dragon',
            description: '[Passive]: Increase the Dice Score of your '
                'Intimidation Skill Checks by 2 and, while Personality '
                'has the highest Attribute Score amongst your '
                'Attributes, increase your Combat Rolls and Initiative '
                'by 1(bT).',
          ),
          TraitOption(
            name: 'Natural Dragon',
            description: '[Passive]: While you are in your Ball Form, '
                'you also have access to the Absorb Maneuver. '
                'Additionally, increase your Combat Rolls by 1(T) '
                'while you possess at least 1 stack of the Absorption '
                'Awakening. Upon gaining a stack of the Absorption '
                'Awakening, immediately leave your Ball Form and '
                'return to normal.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Shadow Dragon',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Draconic Physique',
    description:
        "Though Shadow Dragons are far removed in appearance from the "
        "Eternal Dragon with which they share a name, they possess the "
        "supernatural abilities of a draconic form.\n"
        "(1)-[Passive, Ruling]: At Character Creation or upon gaining "
        "this Trait, gain 'Dragon Scales' while you possess this Trait. "
        "Your Dragon Scales are Natural Armor.\n"
        "(2)-[Passive]: Increase your Soak Value and Defense Value by "
        "1(T) against Attacking Maneuvers made by Opponents with the "
        "Impaired Combat Condition.\n"
        "(3)-[Choice]: Depending on your choice for the Option effect of "
        "Personified Dragon Ball, apply the following effect:",
    dependentChoice: DependentChoice(
      sourceTraitName: 'Personified Dragon Ball',
      sourceGroupLabel: 'Option',
      textByOption: {
        'Sinister Dragon': '[Passive]: Increase the Wound Rolls of your '
            'Attacking Maneuvers made through the Exploit Maneuver by '
            '2(T).',
        'Hazy Dragon': '[Passive]: Ignore the penalties from the Bog '
            'Environment. Instead, while you are in the Bog Environment, '
            'increase your Combat Rolls by 1(bT) and increase your '
            'Speeds by 1/2.',
        'Elemental Dragon': '[Triggered, 1/Round]: If you knock an '
            'Opponent through a Health Threshold with an Attacking '
            "Maneuver of your Favored Element's Profile, they gain a "
            'stack of Impaired until the start of your next turn.',
        'Noble Dragon': '[Triggered]: If you inflict the Compelled '
            'Combat Condition upon an Opponent through the effects of '
            'Noble Dragon, they gain a stack of Impaired until the '
            'start of your next turn.',
        'Regenerative Dragon': '[Triggered/Defeat]: You are not '
            'Defeated and lose all of your Dragon Slimes. For every '
            'Dragon Slime lost, regain Life Points equal to 1/10th of '
            'your Maximum Life Points.',
        'Ominous Dragon': '[Passive]: Gain access to the Terrify '
            'Maneuver. Additionally, if you inflict a Combat Condition '
            "to an Opponent through the Terrify Maneuver's effects, "
            'that Opponent also suffers from the Impaired Combat '
            'Condition until the start of your turn.',
        'Natural Dragon': '[Triggered]: Upon gaining a stack of '
            'Absorption, you may increase your Size Category to '
            'Gigantic while you possess that stack of Absorption. '
            'Additionally, increase your Soak Value and Wound Rolls by '
            '1(T) while you possess at least 1 stack of Absorption.',
      },
    ),
  ),
  RaceTraitDef(
    race: 'Shadow Dragon',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Karmic Reflection',
    description:
        "Your personality is an inverse reflection of the wish that made "
        "you; in the same way that your morality is inverted, so too may "
        "you invert reality.\n"
        "(1)-[Passive]: For calculating your Morale Save, use the "
        "higher of your Magic or Force Score if they exceed your "
        "Personality Score.\n"
        "(2)-[Triggered]: If you or an Opponent (who is not at Long "
        "Range) scores a Botch Result on a Combat Roll, gain 1 "
        "Negative Energy.\n"
        "(3)-[Triggered/Power]: Spend 2(bT) Life Points to gain 1 "
        "Negative Energy.\n"
        "(4)-[Triggered/Threshold]: Spend up to 2 Negative Energy to "
        "increase the Dice Score of your Steadfast Check for this "
        "Health Threshold by an equal amount. If you succeed at the "
        "Steadfast Check, regain 2(T) Ki Points for every Negative "
        "Energy spent on this effect.\n"
        "(5)-[Triggered, 1/Encounter]: If your Opponent scores a "
        "Critical Result on their Combat Roll, they score a Botch "
        "Result instead (regardless of their Natural Result).",
  ),
  RaceTraitDef(
    race: 'Shadow Dragon',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Wrath of the Dragon',
    description:
        "Imbued with the righteous fury of the Eternal Dragon that "
        "spawned you, you bring punishment upon those who would misuse "
        "the Dragon Balls.\n"
        "(1)-[Passive]: Increase the Dice Score of your Wound Roll by "
        "2(T) if you scored a Critical Result on that Wound Roll.\n"
        "(2)-[Triggered]: If you hit an Opponent suffering from the "
        "Impaired Combat Condition with an Attacking Maneuver that is "
        "not an AoE, increase the Natural Result of that Wound Roll by "
        "1 for each stack of the Impaired Combat Condition that "
        "Opponent is suffering from.\n"
        "(3)-[Triggered]: If you use an Attacking Maneuver that "
        "possesses an AoE, for each Opponent targeted by that Attacking "
        "Maneuver that is suffering from the Impaired Combat Condition, "
        "increase the Natural Result of that Wound Roll by 1.\n"
        "(4)-[Triggered, 1/Round]: If you or an Ally knock an Opponent "
        "(who is not at Long Range) through a Health Threshold with an "
        "Attacking Maneuver, you may spend 1 Negative Energy to reduce "
        "the Dice Score of their Steadfast Check by 2.\n"
        "(5)-[Triggered, 1/Round]: If an Opponent who is not at Long "
        "Range fails their Steadfast Check, you may spend 1 Negative "
        "Energy to inflict a stack of the Impaired Combat Condition on "
        "that Opponent until the start of your next turn.",
  ),

  // ============================================================ Shinjin ===
  RaceTraitDef(
    race: 'Shinjin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Divine Magic',
    description:
        "With the pure magical energies born from their divine nature, "
        "Shinjin possess various abilities.\n"
        "(1)-[Passive]: Gain access to the Magical Materialization, "
        "Telepathy, Telekinesis, and Second Sight Unique Abilities.\n"
        "(2)-[Passive]: At Character Creation, gain a Skill Rank in "
        "Knowledge (any), Creature Handling, Clairvoyance, Perception, Use "
        "Magic, and Investigation.\n"
        "(3)-[Option]: At Character Creation, choose one of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'God of Peace',
            description: '[Triggered/Power, 1/Round]: Enter the '
                'Mindful State until the start of your next turn.',
          ),
          TraitOption(
            name: 'God of Judgment',
            description: '[Triggered, 1/Round]: If you use the '
                'Signature Technique Maneuver, apply an Energy Charge '
                'to that Attacking Maneuver.',
          ),
          TraitOption(
            name: 'God of Power',
            description: '[Passive]: You gain the Muscular Warrior '
                'Talent. Additionally, increase your Force Modifier by '
                '1(T) while in a Form or an Enhancement.',
          ),
          TraitOption(
            name: 'God of Survival',
            description: '[Passive]: Increase the Dice Score of your '
                'Steadfast Checks by 2 and increase your Surgency by '
                '1/2 (rounded up) of your Insight Modifier.',
            automation: [
              // +ceil(Insight Modifier / 2) Surgency.
              RaceTraitAutomation(
                affectedStats: [AffectedStat.surgency],
                coefficient: 1,
                kind: TraitMagnitudeKind.fractionOfAttribute,
                attribute: DbuAttribute.insight,
                fractionDenominator: 2,
                roundUp: true,
              ),
            ],
          ),
          TraitOption(
            name: 'God of Wisdom',
            description: '[Passive]: If Scholarship and/or Personality '
                'have the highest Attribute Score among your '
                'Attributes, increase all of your Combat Rolls and '
                'Initiative Rolls by 1(bT).',
          ),
          TraitOption(
            name: 'God of War',
            description: '[Passive]: You gain the Weapon Specialist '
                'Talent, and when creating any type of Signature '
                'Technique, you may add the Weapon Assisted Advantage '
                'to that Signature Technique without spending Technique '
                'Points.',
          ),
          TraitOption(
            name: 'God of Magic',
            description: '[Passive]: Reduce the TP Cost of all Magical '
                'Unique Abilities by 3 TP and reduce the KP Cost of '
                'your Magical Unique Abilities by 2(T).',
          ),
          TraitOption(
            name: 'God of Many',
            description: '[Passive]: You gain the Master of Minions '
                'Talent, and your Minions have their Combat Rolls '
                'increased by 1(T) while you are in the Spectator '
                'State.',
          ),
          TraitOption(
            name: 'God of Time',
            description: '[Passive]: Gain access to the Time Freeze '
                'Unique Ability with the Straining Time Freeze and '
                'Difficult Time Freeze Restrictions. Increase your '
                'Wound Rolls by 2(T) during Frozen Turns.',
          ),
          TraitOption(
            name: 'God of an Element',
            description: "[Passive]: Upon gaining this effect, select "
                "a Profile with 'Elemental' in the name – it becomes a "
                'Favored Element.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Shinjin',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Skill of the Watcher',
    description:
        "You are a divine being meant to watch over the universe or rule "
        "over it. The patience to observe others leads to you gaining "
        "critical information.\n"
        "(1)-[Passive]: You can sense God Ki.\n"
        "(2)-[Passive]: Your minimum Action Cost for Combat Recovery is "
        "1 Action.\n"
        "(3)-[Triggered]: Increase your Combat Rolls and Soak Value by "
        "1(T) for the duration of any of your Counter Maneuvers.\n"
        "(4)-[Triggered]: At the end of the Combat Round, regain 2(bT) "
        "Life and Ki Points for each Counter Action you possess.\n"
        "(5)-[Triggered, 1/Round]: If you deal Damage with an Attacking "
        "Maneuver made through the Exploit Maneuver, or do not receive "
        "Damage from an Attacking Maneuver that you used the Defend "
        "Maneuver in response to, you may use the Power Up Maneuver as "
        "an Out-of-Sequence Maneuver.\n"
        "(6)-[Triggered/Start of Combat Round]: You may spend 1 Action "
        "to gain 2 Counter Actions.",
  ),
  RaceTraitDef(
    race: 'Shinjin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Celestial Potential',
    description:
        "As divine entities entrusted to watch over the fledgling "
        "universe, Shinjin have seen the best ways to mitigate their "
        "mistakes and capitalize on their successes.\n"
        "(1)-[Triggered, 1/Round]: When you score a Botch Result on a "
        "Combat Roll, increase your Dice Score by 2(T) instead of "
        "suffering the penalty.\n"
        "(2)-[Triggered, 1/Round]: When you score a Critical Dice "
        "Result on a Combat Roll, increase your Dice Score by an "
        "additional 2(T).\n"
        "(3)-[Triggered/Power, 1/Encounter]: You may convert up to 2 "
        "of your Counter Actions into Actions.",
  ),
  RaceTraitDef(
    race: 'Shinjin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Cosmic Efficiency',
    description:
        "You have absolute control of the flow of Ki throughout your "
        "body. This natural affinity allows you to use your Ki in the "
        "most effective and efficient way.\n"
        "(1)-[Passive]: You may use your Magic Modifier instead of "
        "your Force Modifier when calculating Surgency.\n"
        "(2)-[Passive]: Reduce the Ki Point Cost of all your Attacking "
        "Maneuvers by 2(T).\n"
        "(3)-[Passive]: Increase the Dice Score of your Combat "
        "Recovery by 1d6(T).",
  ),
  RaceTraitDef(
    race: 'Shinjin',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Flow of Combat',
    description:
        "You are as serene and peaceful in combat as you are at a tea "
        "party, graceful and poised even in the midst of battlefield "
        "chaos.\n"
        "(1)-[Triggered]: If you suffer no Damage from an Opponent's "
        "Attacking Maneuver that targets you, this triggers your "
        "Exploit Maneuver.\n"
        "(2)-[Triggered/Start of Turn]: If you have taken no Damage "
        "since the end of your last turn, you may use Combat Recovery "
        "as if you spent 1 Action as an Out-of-Sequence Maneuver. If "
        "you do, ignore the reduction to your Defense Value from the "
        "effects of Combat Recovery.\n"
        "(3)-[Triggered, 1/Encounter]: If you are targeted by an "
        "Opponent's Attacking Maneuver, you may use the Defend "
        "Maneuver without spending a Counter Action.",
  ),

  // ============================================================ Yardrat ===
  RaceTraitDef(
    race: 'Yardrat',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'People of the Spirit',
    description:
        "A spiritually focused culture, Yardrat society promotes inner "
        "peace and enlightenment.\n"
        "(1)-[Passive]: At Character Creation, gain a stack of Spirit "
        "Control. This stack of Spirit Control does not count towards "
        "your Awakening Limit, and you do not gain the Attribute "
        "Modifier Bonus from this stack of Spirit Control.\n"
        "(2)-[Passive]: At Character Creation, gain 2 Skill Ranks in "
        "the Clairvoyance Skill.\n"
        "(3)-[Passive]: You are always treated as being within the "
        "Melee Range of your Allies for the effects of the Empower "
        "Maneuver.\n"
        "(4)-[Passive]: Reduce the TP Cost of all Unique Abilities by "
        "3.\n"
        "(5)-[1/Encounter]: As an Instant Maneuver, you may use the "
        "Empower Maneuver as if you spent 3 Actions. Your target for "
        "this usage of the Empower Maneuver may immediately use a "
        "Surge of their choice as an Out-of-Sequence Maneuver.",
  ),
  RaceTraitDef(
    race: 'Yardrat',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Power of the Weak',
    description:
        "Though physically unimpressive, Yardrats more than make up for "
        "their shortcomings by sharing their spiritual power with others.\n"
        "(1)-[Passive]: When using the Empower Maneuver to give Ki "
        "Points to an Ally, you must always give the maximum amount of "
        "Ki Points possible to that Ally.\n"
        "(2)-[Passive]: Increase the Ki Point Cost of all your "
        "Attacking Maneuvers by 2(T), but reduce the Ki Point Cost of "
        "all your Unique Abilities by 2(T).\n"
        "(3)-[Triggered]: If you are targeted by an Attacking Maneuver, "
        "you may spend up to 4(bT) Ki Points. For every 2(bT) Ki Points "
        "spent, increase your Strike and Dodge Rolls by 1(T) for the "
        "duration of that Attacking Maneuver.\n"
        "(4)-[Triggered, 1/Round, Ruling]: If you give Ki Points to an "
        "Ally (except a Minion) through the Empower Maneuver, you "
        "become 'Bonded' until you become Bonded to another Ally. You "
        "cannot be Bonded with a Character that another Yardrat is "
        "already Bonded to.\n"
        "(5)-[Triggered, 2/Round]: If a Bonded Ally hits an Opponent "
        "with an Attacking Maneuver, you may spend up to 3(bT) Ki "
        "Points. Increase the Wound Roll of that Attacking Maneuver by "
        "an equal amount.\n"
        "(6)-[Triggered, 2/Round]: If a Bonded Ally is hit by an "
        "Opponent's Attacking Maneuver, you may spend up to 3(bT) Ki "
        "Points. Increase your Bonded Ally's Soak Value by an equal "
        "amount for the duration of that Attacking Maneuver.",
  ),
  RaceTraitDef(
    race: 'Yardrat',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Masters of Movement',
    description:
        "While Yardrats may not hit particularly hard, they're "
        "notoriously difficult to hurt due to their unique ability to "
        "dart around the battlefield.\n"
        "(1)-[Passive]: You gain access to the Instant Transmission "
        "Unique Ability.\n"
        "(2)-[Passive]: At Character Creation, you may apply the "
        "Yardrat Material Special Apparel Quality as if it was a "
        "normal Apparel Quality through creating a Gear Kit.\n"
        "(3)-[Triggered/Threshold]: If you succeed at the Steadfast "
        "Check for this Threshold, select a Square within the "
        "Battlefield. You are removed from your current place on the "
        "Battlefield and placed on that Square. If you were in a "
        "Grapple before applying this effect, you must make a Clash "
        "(Cognitive) against the Grappler. If you win, that Grapple "
        "ends and you may apply this effect as usual. If you lose, "
        "this effect fails and is not applied.\n"
        "(4)-[Triggered/Start of Turn]: Select a Square within the "
        "Battlefield. Either you or a willing Ally are removed from "
        "your current place on the Battlefield and placed on that "
        "Square. If you or your chosen Ally were in a Grapple before "
        "applying this effect, you must make a Clash (Cognitive) "
        "against the Grappler. If you win, that Grapple ends and you "
        "may apply this effect as usual. If you lose, this effect "
        "fails and is not applied.\n"
        "(5)-[Triggered, 1/Round]: If you are placed on a Square "
        "adjacent to an Opponent, you may use the Basic Attack "
        "Maneuver against them as an Out-of-Sequence Maneuver.\n"
        "(6)-[Triggered, 1/Round]: If you are placed on a Square "
        "adjacent to an Ally, you may use the Power Up Maneuver as an "
        "Out-of-Sequence Maneuver.",
  ),
  RaceTraitDef(
    race: 'Yardrat',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Conduit of Spirit',
    description:
        "The spiritual energy that ripples and flows through the Yardrat "
        "people allows them to perform unique feats of teamwork.\n"
        "(1)-[Passive]: Increase your Cognitive Saving Throw and Might "
        "by 1(T) while you have at least 1 Ally and none of your "
        "Allies are Defeated.\n"
        "(2)-[Triggered, 1/Round]: If a Bonded Ally is targeted by an "
        "Opponent's effect that requires them to use the Cognitive "
        "Saving Throw for a Clash, you may choose to shift the target "
        "of that effect to you (regardless of distance or AoE that "
        "was used to target that Ally). Apply the effect as usual, but "
        "with you as the target instead of the targeted Ally, "
        "including what occurs if you lose this Clash.\n"
        "(3)-[Triggered/Power, 1/Round]: You may choose not to gain a "
        "stack of Power and instead gain a stack of the Impaired "
        "Combat Condition until the start of your next turn. If you "
        "do, you may target a willing Ally within a Large Sphere AoE "
        "(centered on you). That Ally enters the Superior State until "
        "the end of their next turn.\n"
        "(4)-[Triggered, 1/Encounter]: If you and at least 1 of your "
        "Allies are targeted by an Opponent's Attacking Maneuver with "
        "an AoE, you may make a Might Clash against that Opponent, but "
        "increase the Dice Score of their Might Clash by 1(T) for "
        "every Energy Charge or rank of the Power Shot Advantage "
        "applied to that Attacking Maneuver. If you do, increase your "
        "Might by 1/2 of the total Might of all other Allies targeted "
        "by that Attacking Maneuver. If you win this Might Clash, that "
        "Attacking Maneuver fails to hit you or any of your Allies. "
        "You suffer a stack of the Fatigue Combat Condition after "
        "using this effect.",
  ),
];

/// The **Reality Warping Traits** (Janemba page). While the Janemba Manifest
/// form is active, effect (4) of Janemba! Janemba! strips your normal Racial
/// Traits and effect (5) grants these instead — so the calculator returns this
/// list from `activeRaceTraits` (and swaps the Racial Life Modifier to 10 /
/// Racial Saving Throw Bonus to Corporeal/Cognitive/Impulsive) whenever
/// Janemba is active. Modelled as real `RaceTraitDef`s so their automation
/// flows through the same racial-trait pipeline as any other Race's Traits.
/// Evil Incarnate's always-on numeric effects are automated (its "highest
/// Attribute Modifier for Surgency" is handled in `surgency()`); the rest are
/// situational/"set to maximum"/battlefield effects kept as verbatim text.
const List<RaceTraitDef> kJanembaRealityWarpingTraits = [
  RaceTraitDef(
    race: 'Janemba',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Evil Incarnate',
    description: 'Janemba is beyond your pathetic morality, mortal.\n'
        '(1)-[Passive]: Use your highest Attribute Modifier to calculate your '
        'Surgency.\n'
        '(2)-[Passive]: While you are not wearing any Apparel, increase your '
        'Damage Reduction by 2(bT), your Combat Rolls by 1(bT), and your '
        'Stress Bonus by 1.\n'
        '(3)-[Passive]: Your Life Points and Ki Points can exceed their '
        'Maximums.\n'
        '(4)-[Passive]: On a Combat Roll, if you score a Natural Result of 6, '
        'you score a Critical Result regardless of your Critical Target.\n'
        '(5)-[Triggered, 1/Round]: If you fail a Steadfast Check for a Health '
        'Threshold, roll a 1d10. On a result of 6, you instead succeed at that '
        'Steadfast Check and then target the nearest character; they gain the '
        'Impediment Combat Condition until the end of their next turn.\n'
        '(6)-[Triggered, 1/Round]: If you score a Botch Result on a Combat '
        'Roll, roll a 1d10. On a result of 6, you score a Critical Result on '
        'that Combat Roll instead. If you score a Critical Result through this '
        'effect, all other Characters suffer from the Impaired Combat '
        'Condition until the start of your next turn.',
    automation: [
      // (2) While no Apparel worn: +2(bT) Damage Reduction.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.damageReduction],
        coefficient: 2,
        tierScaling: TierScaling.base,
        condition: TraitCondition.whileNoApparelWorn,
      ),
      // (2) +1(bT) Combat Rolls (Strike + Dodge + all Wounds).
      RaceTraitAutomation(
        affectedStats: [
          AffectedStat.strike,
          AffectedStat.dodge,
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficient: 1,
        tierScaling: TierScaling.base,
        condition: TraitCondition.whileNoApparelWorn,
      ),
      // (2) +1 Stress Bonus (flat, not tier-scaled).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.stressBonus],
        coefficient: 1,
        tierScaling: TierScaling.none,
        condition: TraitCondition.whileNoApparelWorn,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Janemba',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Evil Magic',
    description: "Janemba's power is beyond measure. Bow down before "
        'Janemba.\n'
        '(1)-[Passive]: You cannot create Signature Techniques or obtain '
        'Unique Abilities through the normal means. You can only gain access '
        'to them through the effects of Traits.\n'
        '(2)-[Passive]: Set your number of Use Magic Skill Ranks to the '
        'maximum for your base Tier of Power.\n'
        '(3)-[Passive]: When making an Attacking Maneuver, you can select any '
        'Attribute Modifier as the Damage Attribute for that Attacking '
        'Maneuver.\n'
        '(4)-[Passive]: You may use the Profiles of every Foundation, '
        'regardless of your Attribute Score. Additionally, you gain access to '
        'the Glass Profile (see — Glass Tribe).\n'
        '(5)-[1/Round]: You may use a Unique Ability you do not have access '
        'to, as long as you meet the Prerequisites.\n'
        '(6)-[Triggered/Start of Turn]: Create a Super Signature Technique '
        'with a TP Cost up to the maximum Technique Point Cost for your base '
        'Tier of Power. You have access to that Signature Technique until the '
        'start of your next turn. That Signature Technique cannot possess the '
        'Ascended Signature Advantage.\n'
        '(7)-[Triggered, 1/Encounter]: When you create a Signature Technique '
        'through the 6th effect of Evil Magic, you may create an Ultimate '
        'Signature Technique instead of a Super Signature Technique.',
  ),
  RaceTraitDef(
    race: 'Janemba',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Jellybean Junction',
    description: 'Janemba creates entire universes. Your puny existence is '
        "meaningless in the face of Janemba's might.\n"
        '(1)-[1/Round, Ruling]: As a Standard Maneuver with an Action Cost of '
        "1 Action, you can create up to 1(bT) 'Jellybean Features' within a "
        'Destructive Sphere AoE (centered on you). Jellybean Features are '
        'Features with a Hardness Rank of 3 and the Floating and Resilient '
        'Feature Qualities.\n'
        '(2)-[1/Round]: As a Standard Maneuver with an Action Cost of 1 '
        'Action, you may move any number of Jellybean Features either a number '
        'of Squares equal to 1/2 of your Might, or into a High Environment 1 '
        'rank higher or lower than the one they are currently in. This '
        'movement can cause Collision, but you cannot cause Collision in this '
        'manner to a single Character more than once per Combat Round.\n'
        '(3)-[Passive]: Increase your Wound Rolls by 2(T) while you have at '
        'least 1 Jellybean Feature within a Sphere AoE (centered on you).\n'
        '(4)-[Triggered/Start of Combat Encounter]: You can create up to '
        '1(bT) Jellybean Features within a Destructive Sphere AoE (centered '
        'on you).',
  ),
  RaceTraitDef(
    race: 'Janemba',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.mind,
    name: 'Paranormal Perception',
    description: 'Janemba sees all, even through dimensions and realities. '
        'Janemba sees you, now, in front of the computer. Fear Janemba.\n'
        '(1)-[Passive]: Set your number of Perception and Clairvoyance Skill '
        'Ranks to the maximum for your base Tier of Power.\n'
        '(2)-[Triggered/Start of Combat Round, Ruling]: Select an Opponent. '
        "They become your 'Victim' until the end of the Combat Round. Increase "
        'your Strike Rolls and Dodge Rolls against your Victim by 1(T).\n'
        '(3)-[Triggered, 1/Round]: If you are targeted by an Attacking '
        'Maneuver of your Victim, you may use the Defend Maneuver without '
        'spending a Counter Action.\n'
        '(4)-[Triggered, 1/Round]: If you target your Victim with an Attacking '
        'Maneuver that does not possess an AoE, make a Clash '
        '(Perception/Clairvoyance vs Stealth/Concealment) against that Victim. '
        'If you win, apply an Energy Charge to that Attacking Maneuver.',
  ),
  RaceTraitDef(
    race: 'Janemba',
    tier: RaceTraitTier.secondary,
    category: TraitCategory.body,
    name: 'Paranormal Assault',
    description: 'Your paltry attempts to defend against Janemba are '
        'laughable, mortal. Janemba will deal with you later.\n'
        '(1)-[Passive]: Gain access to the Portal Creation, Illusion Smash, '
        'Copy Being, and Copy Clone Unique Abilities, as well as all of their '
        'Advancements.\n'
        '(2)-[Passive]: Gain access to the World Transfiguration Special '
        'Maneuver.\n'
        '(3)-[Triggered]: When making any type of Physical Attacking Maneuver '
        'or Grapple Maneuver, you may increase your Melee Range by 3 Squares '
        'for the duration of that Maneuver.\n'
        '(4)-[Triggered, 1/Round]: Upon hitting an Opponent with a Physical '
        'Attacking Maneuver or initiating a Grapple, you may move that '
        'Character any number of Squares up to your current Melee Range in any '
        'direction — ignoring the usual rules for Movement in a Grapple if you '
        'initiated a Grapple.\n'
        '(5)-[Triggered, 1/Round]: When you target an Opponent with an '
        'Attacking Maneuver that was used as an Out-of-Sequence Maneuver, make '
        'a Clash (Perception vs Perception/Stealth) against that Opponent. If '
        'you win, they gain the Guard Down Combat Condition for the duration '
        'of that Attacking Maneuver.',
  ),
];

/// All Primary + Secondary Racial Traits for [raceName] (empty for Custom
/// Species or an unrecognized name — Custom Species instead uses freeform
/// selection, see `Character.customRaceTraits`). Subrace-granted Traits are
/// NOT included here (they live in `kDbuSubraceTraits` and are merged in by
/// `CharacterCalculator.activeRaceTraits` only for the chosen Subrace).
List<RaceTraitDef> raceTraitsFor(String raceName) =>
    kDbuRaceTraits.where((t) => t.race == raceName).toList(growable: false);

// ===========================================================================
// SUBRACES
// ---------------------------------------------------------------------------
// Five Races have a "Subrace" section on their page (Namekian, Demon, Glass
// Tribe, Neo-Tuffle, Yardrat). Choosing a Subrace grants exactly one extra
// Racial Trait (transcribed verbatim below, automated where the effect is a
// clean additive bonus — same convention as every other Racial Trait). The
// player's pick lives in `Character.subrace`; the Trait is merged into
// `activeRaceTraits` (so its automation, Options and the beast-Trait picker on
// Phantom's Fallen Idol all apply just like a native Trait).
// ===========================================================================

/// One selectable Subrace — its name (as it appears on the site) and a short
/// one-line blurb for the dropdown. The actual granted Trait(s) live in
/// [kDbuSubraceTraits], matched by `race` + `subrace`.
class SubraceDef {
  const SubraceDef({
    required this.race,
    required this.name,
    required this.blurb,
  });

  final String race;
  final String name;
  final String blurb;
}

const List<SubraceDef> kDbuSubraces = [
  SubraceDef(
    race: 'Namekian',
    name: 'Warrior Clan',
    blurb: 'Bred for battle — front-line protectors of their people.',
  ),
  SubraceDef(
    race: 'Namekian',
    name: 'Dragon Clan',
    blurb: 'Greater magical prowess and healing — support from the rear.',
  ),
  SubraceDef(
    race: 'Demon',
    name: 'Demon Person',
    blurb: 'Citizens of the Demon Realm who wield magic effortlessly.',
  ),
  SubraceDef(
    race: 'Demon',
    name: 'Makyan',
    blurb: 'Tied to the Makyo Star — ever stronger as it draws near.',
  ),
  SubraceDef(
    race: 'Demon',
    name: 'Phantom',
    blurb: 'Monstrous juggernauts — unstoppable beasts of the Demon Realm.',
  ),
  SubraceDef(
    race: 'Glass Tribe',
    name: 'Glass User',
    blurb: 'Shape the battlefield with glass — heal and protect your Allies.',
  ),
  SubraceDef(
    race: 'Glass Tribe',
    name: 'Glass Warrior',
    blurb: 'Embed glass shards in foes to enhance your abilities.',
  ),
  SubraceDef(
    race: 'Neo-Tuffle',
    name: 'Hatred Embodiment',
    blurb: 'Grow stronger the longer the fight — powered by hatred.',
  ),
  SubraceDef(
    race: 'Neo-Tuffle',
    name: 'Parasite',
    blurb: 'Liquefy and possess other beings to take control.',
  ),
  SubraceDef(
    race: 'Yardrat',
    name: 'Tall Yardrat',
    blurb: 'The battle-ready Yardrats who stand at the forefront.',
  ),
  SubraceDef(
    race: 'Yardrat',
    name: 'Bulbous Yardrat',
    blurb: 'Masters of combat support who fight through their Allies.',
  ),
];

/// The Subraces available to [raceName] (empty if the Race has none).
List<SubraceDef> subracesFor(String raceName) =>
    kDbuSubraces.where((s) => s.race == raceName).toList(growable: false);

/// Whether [raceName] has any Subraces to choose from.
bool raceHasSubraces(String raceName) =>
    kDbuSubraces.any((s) => s.race == raceName);

/// The extra Racial Trait(s) granted by [subrace] of [raceName] — empty when
/// [subrace] is blank or unrecognized.
List<RaceTraitDef> subraceTraitsFor(String raceName, String subrace) =>
    subrace.isEmpty
        ? const []
        : kDbuSubraceTraits
            .where((t) => t.race == raceName && t.subrace == subrace)
            .toList(growable: false);

/// The eleven Subrace Traits (one per Subrace), verbatim from each Race's
/// page. Clean additive effects are automated; every other effect is shown as
/// text for the player to apply. Phantom's Fallen Idol carries a
/// `BeastTraitGrant` (its 2nd effect grants a Monstrous + a Bestial Trait).
const List<RaceTraitDef> kDbuSubraceTraits = [
  // ---------------------------------------------------------- Namekian ---
  RaceTraitDef(
    race: 'Namekian',
    subrace: 'Warrior Clan',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Refined Combat',
    description:
        "Literally bred for battle, Warriors train from birth to protect "
        "their brethren from any threats to their people and their planet.\n"
        "(1)-[Passive]: Increase your Soak Value and Wound Rolls against "
        "Studied Opponents by 1(T).\n"
        "(2)-[Passive]: Increase your Surgency by 1/2 (rounded up) of your "
        "Insight Modifier.\n"
        "(3)-[Multi-Option/2]: At Character Creation, choose two of the "
        "following effects:",
    automation: [
      // (2) +1/2 (rounded up) Insight Modifier to Surgency.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.surgency],
        coefficient: 1,
        kind: TraitMagnitudeKind.fractionOfAttribute,
        attribute: DbuAttribute.insight,
        fractionDenominator: 2,
        roundUp: true,
      ),
    ],
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Choose 2',
        maxChoices: 2,
        options: [
          TraitOption(
            name: 'Hand to Hand',
            description: '[Triggered, 1/Round]: When you hit a Studied '
                'Opponent with a Physical Attack, you may increase the Wound '
                'Roll by 1/2 of your Surgency. If you do, that Opponent stops '
                'being Studied after you complete this Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Blaster',
            description: '[Triggered, 1/Round]: When you hit a Studied '
                'Opponent with an Energy Attack, you may increase the Wound '
                'Roll by 1/2 of your Surgency. If you do, that Opponent stops '
                'being Studied after you complete this Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Grappler',
            description: '[Triggered, 1/Round]: If you successfully initiate '
                'a Grapple with a Studied Opponent, you may use the Launch '
                'Maneuver or Pin Maneuver as an Out-of-Sequence Maneuver. If '
                'you do, that Opponent stops being Studied after you complete '
                'that Maneuver.',
          ),
          TraitOption(
            name: 'Defender',
            description: '[Triggered, 1/Round]: When you are hit by an attack '
                'from a Studied Opponent, you may increase your Soak Value by '
                '1/2 of your Surgency for the duration of that Attacking '
                'Maneuver and reduce the Damage Category of that Attacking '
                'Maneuver by 1. If you do, that Opponent stops being Studied '
                'after you complete that Maneuver.',
          ),
          TraitOption(
            name: 'Fleet-Footed',
            description: '[Triggered, 1/Round]: When you are targeted by an '
                'Attacking Maneuver from a Studied Opponent, you may increase '
                'your Defense Value by 1/2 of your Surgency for the duration '
                'of that Attacking Maneuver. If you do, that Opponent stops '
                'being Studied after you complete that Maneuver.',
          ),
          TraitOption(
            name: 'Protector',
            description: '[Triggered, 1/Round]: When a Studied Ally is hit by '
                'an Attacking Maneuver, you may use the Intervene Maneuver '
                'without spending a Counter Action.',
          ),
          TraitOption(
            name: 'Trusted Ally',
            description: '[Triggered, 1/Round]: When you target an Ally with '
                'the Empower Maneuver, they become Studied until the end of '
                'their next turn. If they were already Studied, they may use '
                'the Power Up Maneuver or Transformation Maneuver as an '
                'Out-of-Sequence Maneuver instead.',
          ),
          TraitOption(
            name: 'Power Channeler',
            description: '[Triggered, 1/Round]: If you target a Studied '
                'Opponent with the Signature Technique Maneuver, you may gain '
                'a free Energy Charge on that Attacking Maneuver that counts '
                'towards the required amount of Energy Charges necessary for '
                'the Mandatory Charge Disadvantage. If you do, that Opponent '
                'stops being Studied after you complete this Attacking '
                'Maneuver.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Namekian',
    subrace: 'Dragon Clan',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Spirit of Namek',
    description:
        "Known for their greater magical prowess and their healing powers, "
        "Dragon Clan Namekians focus on supporting their Warrior brethren "
        "from the rear.\n"
        "(1)-[Passive]: Gain the Healing Hands Unique Ability.\n"
        "(2)-[Passive]: Increase the Soak Value and Wound Rolls of your "
        "Studied Allies by 1(T).\n"
        "(3)-[Passive]: You may use your Magic Modifier instead of your Force "
        "Modifier when calculating Surgency.\n"
        "(4)-[Multi-Option/2]: At Character Creation, choose two of the "
        "following effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Choose 2',
        maxChoices: 2,
        options: [
          TraitOption(
            name: 'Caster',
            description: '[Triggered, 1/Round]: When you hit a Studied '
                'Opponent with a Magical Attack, you may increase the Wound '
                'Roll by 1/2 of your Surgency. If you do, that Opponent stops '
                'being Studied after you complete this Attacking Maneuver.',
          ),
          TraitOption(
            name: 'Supporter',
            description: '[Triggered, 1/Round]: When a Studied Ally hits an '
                'Opponent with an Attacking Maneuver, you may increase the '
                'Wound Roll by 1/2 of your Surgency. If you do, that Ally '
                'stops being Studied after they complete this Attacking '
                'Maneuver.',
          ),
          TraitOption(
            name: 'Debuffer',
            description: '[1/Round]: As an Instant Maneuver, you can target a '
                'Studied Opponent. Make a Clash (Cognitive) against them. If '
                'you win, they suffer from the Impediment Combat Condition '
                'until the end of this turn.',
          ),
          TraitOption(
            name: 'Healer',
            description: '[Triggered]: Increase the amount of Life Points '
                'regained from your use of Healing Hands by your Surgency. '
                'Additionally, if you use Healing Hands on a Studied Ally, '
                'they may either: regain Ki Points equal to 1/2 of the Life '
                'Points they gained, OR stop suffering from a Combat '
                'Condition (except Suffocating).',
          ),
          TraitOption(
            name: 'Life Burn',
            description: '[Triggered/Power, 1/Encounter]: You may reduce your '
                'Maximum Life Points and your Life Points by 1/4 of your '
                'Maximum Life Points. If you do, increase your Combat Rolls '
                'by 2(T) until you fail a Steadfast Check.',
          ),
          TraitOption(
            name: 'Magician',
            description: '[Passive]: Reduce the Technique Point Cost of any '
                'Magical Unique Abilities by 3 and reduce their Ki Point Cost '
                'by 2(T).',
          ),
          TraitOption(
            name: 'Bestower',
            description: '[Passive]: Gain access to the Magical Enhancement '
                'Unique Ability and the Unleash Dormant Power Advancement. '
                'Additionally, when selecting a character to become Studied '
                'through the second effect of Intelligent Fighter, you may '
                'select an additional character to be Studied, but they must '
                'be an Ally.',
          ),
          TraitOption(
            name: 'Poko Priest',
            description: '[1/Round]: As a Standard Action with an Action Cost '
                'of 2 and a Ki Point Cost of 5(bT), create a Minion. This '
                'Minion is of the Namekian Race and must possess the Dark '
                'Vassal Factor. In addition, that Minion gains 2(bT) '
                'Attribute Points to spend at Character Creation.',
          ),
        ],
      ),
    ],
  ),

  // ------------------------------------------------------------- Demon ---
  RaceTraitDef(
    race: 'Demon',
    subrace: 'Demon Person',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Denizen of the Demon Realm',
    description:
        "Magical in nature themselves, the citizens of the Demon Realm wield "
        "magic effortlessly against their foes.\n"
        "(1)-[Passive]: Increase the Dice Score of your Pressure Checks by 1 "
        "while at least 1 Opponent is suffering from a Combat Condition that "
        "you inflicted.\n"
        "(2)-[Passive]: At Character Creation, select any Magical Unique "
        "Ability with a TP Cost of 30 or less. You must still meet any "
        "Prerequisites, except those of a listed Attribute Score and if the "
        "listed Skill Ranks required are 2 or less. You gain access to that "
        "Unique Ability while you possess this Trait.\n"
        "(3)-[Option]: At Character Creation, choose one of the following "
        "effects:",
    optionGroups: [
      RaceTraitOptionGroup(
        label: 'Option',
        options: [
          TraitOption(
            name: 'Demon Warrior',
            description: '[Passive]: You gain the Weapon Specialist Talent, '
                'and when creating any type of Signature Technique, you may '
                'add the Weapon Assisted Advantage to that Signature '
                'Technique without spending Technique Points.',
          ),
          TraitOption(
            name: 'Demon Mage',
            description: '[Passive]: Reduce the Technique Point Cost of any '
                'Magical Unique Abilities by 3 and reduce their Ki Point Cost '
                'by 2(T).',
          ),
          TraitOption(
            name: 'Demon Face',
            description: '[Passive]: If Scholarship and/or Personality have '
                'the highest Attribute Score among your Attributes, increase '
                'all of your Combat Rolls and Initiative Rolls by 1(bT).',
          ),
          TraitOption(
            name: 'Elemental Demon',
            description: '[Passive]: Upon gaining this effect, select a '
                "Profile with 'Elemental' in the name – it becomes a Favored "
                'Element.',
          ),
          TraitOption(
            name: 'Gigantic Demon',
            description: '[Passive]: Increase your Racial Life Modifier by 4 '
                'and your base Size Category becomes Gigantic. If any other '
                'effect from a Factor (except Megath) would change your base '
                'Size Category, ignore it.',
            automation: [
              // +4 Racial Life Modifier (the base-Size change stays manual —
              // it depends on your chosen base Size, which the sheet can't
              // infer a delta for).
              RaceTraitAutomation(
                affectedStats: [AffectedStat.racialLifeModifier],
                coefficient: 4,
              ),
            ],
          ),
          TraitOption(
            name: 'Transforming Demon',
            description: '[Passive]: Gain access to the Super Demon Alternate '
                'Form. Additionally, increase your Stress Bonus by 1. Double '
                'this bonus if your base Tier of Power is 5+.',
          ),
        ],
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Demon',
    subrace: 'Makyan',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Demons of the Makyo Star',
    description:
        "Intrinsically tied to the power imbued in the Makyo Star, Makyans "
        "are a varied but powerful group that only grows stronger as the "
        "Makyo Star draws near.\n"
        "(1)-[Passive]: While you possess 2+ stacks of Demonic Power, "
        "increase your Combat Rolls by 1(T).\n"
        "(2)-[Addendum]: Please refer to the 'Makyo Star' text box below.\n"
        "(3)-[Triggered]: Each time you gain a stack(s) of Demonic Power, "
        "regain Ki Points equal to 1/4 (rounded up) of your Might for each "
        "stack of Demonic Power gained.\n"
        "(4)-[Triggered]: If you would make a Pressure Check, you may reduce "
        "your Dice Score for that Pressure Check by 2. If you use this effect "
        "and still succeed at that Pressure Check, gain an additional stack "
        "of Demonic Power.\n"
        "(5)-[Triggered/Power, 1/Round, 3/Encounter]: Gain a stack of "
        "Demonic Power.",
    trailingText:
        "Makyo Star: The Makyo Star is the home planet for the Makyans. When "
        "upon the Makyo Star or even when it is nearby, they gain an immense "
        "amount of power.\n"
        "When a Makyan is on or near to the Makyo Star, they gain access to "
        "the Makyo Star Awakening as a Level 2 Temporary Awakening. Unlike "
        "typical Temporary Awakenings that Characters lose access to at the "
        "end of the Combat Encounter, the Makyo Star Awakening remains until "
        "they are too far away from the Makyo Star to gain its effects.\n"
        "The degree of proximity to the Makyo Star to gain its effects, and "
        "the current position of the Makyo Star, are both decided by your "
        "ARC.",
  ),
  RaceTraitDef(
    race: 'Demon',
    subrace: 'Phantom',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Fallen Idol',
    description:
        "Beasts of monstrous proportions, these demons are known far and "
        "wide as unstoppable juggernauts that few can match.\n"
        "(1)-[Passive]: At Character Creation, your base Size Category may be "
        "anything between the Small Size Category and the Gigantic Size "
        "Category.\n"
        "(2)-[Passive]: Select and gain access to a Monstrous Trait and a "
        "Bestial Trait.\n"
        "(3)-[Passive]: For each stack of Demonic Power, increase your Soak "
        "Value by 1(T) and the Dice Score of your Steadfast Checks by 1.\n"
        "(4)-[Triggered, 1/Round]: If you succeed a Pressure Check while you "
        "possess the Impediment, Guard Down, Broken, and/or Impaired Combat "
        "Condition(s) you may make a Clash (Cognitive) against an Opponent "
        "who is not at Long Range. If you win, you lose a stack of one of "
        "those listed Combat Conditions and that Opponent gains that stack of "
        "your selected Combat Condition until the end of your turn.",
    automation: [
      // (3) +1(T) Soak Value per stack of Demonic Power (the +1 Steadfast
      // Dice Score per stack isn't a channel the sheet computes).
      RaceTraitAutomation(
        affectedStats: [AffectedStat.soak],
        coefficient: 1,
        tierScaling: TierScaling.current,
        kind: TraitMagnitudeKind.perNamedResourceStack,
        resourceName: 'Demonic Power',
      ),
    ],
    beastGrants: [
      // (2) "Select and gain access to a Monstrous Trait and a Bestial Trait."
      BeastTraitGrant(kind: BeastTraitKind.monstrous),
      BeastTraitGrant(kind: BeastTraitKind.bestial),
    ],
  ),

  // ------------------------------------------------------- Glass Tribe ---
  RaceTraitDef(
    race: 'Glass Tribe',
    subrace: 'Glass User',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Glass Mastery',
    description:
        "By covering the battlefield and even your comrades with glass, you "
        "shape the flow of battle, healing and protecting your Allies as "
        "well as yourself.\n"
        "(1)-[Passive]: Increase your Might and Corporeal Saves by 1(T) while "
        "in the Healthy Health Threshold.\n"
        "(2)-[Passive]: Increase your Damage Reduction and Surgency by 1(T) "
        "and 2(T) respectively while occupying a Square with the Glass "
        "Environmental Quality and all adjacent Squares either possess the "
        "Glass Environmental Quality or are occupied by a Feature with the "
        "Glass Feature Quality.\n"
        "(3)-[Passive]: You gain access to the Float Mirror Special "
        "Maneuver.\n"
        "(4)-[Triggered]: If you target an Ally with the effects of the "
        "Glassification Special Maneuver and you win the Clash, instead of "
        "applying stacks of Slowed, that Ally regains Life Points and Ki "
        "Points equal to 1/2 of your Might for each time they were "
        "targeted.\n"
        "(5)-[Triggered/Start of Turn]: If every Square within a Large Sphere "
        "AoE (centered on you) has the Glass Environmental Quality or is "
        "occupied by a Feature with the Glass Feature Quality, regain 3(bT) "
        "Life and Ki Points.\n"
        "(6)-[Triggered/Start of Combat Encounter]: If you are in the Healthy "
        "Health Threshold, use the Glassification Maneuver as an "
        "Out-of-Sequence Maneuver as if you spent 3 Actions for its effects. "
        "You do not have to pay the Ki Point Cost for this use of the "
        "Glassification Maneuver if you only target Squares through its "
        "effects.",
    trailingText:
        "Float Mirror [1/Encounter]: You redirect the force of an attack, "
        "absorbing the attack and firing it back at the opponent.\n"
        "– Maneuver Type: Counter Maneuver\n"
        "– Action Cost: 1 Counter Action\n"
        "– Minions: N/A\n"
        "– KP Cost: 8(T)\n"
        "– Effect: If you and/or any Allies are targeted by an Attacking "
        "Maneuver while all targets of that Attacking Maneuver are occupying "
        "a Square with the Glass Environmental Quality and are within a "
        "Destructive Sphere AoE (centered on you), you may use this Counter "
        "Maneuver.\n"
        "Make a Might Clash against the attacking Character, but increase "
        "their Dice Score by 1(T) for every Energy Charge or rank of Power "
        "Shot applied to their Attacking Maneuver. If you win, that Attacking "
        "Maneuver misses all of its targets, is no longer an Absolute Attack "
        "if it would be otherwise, and cannot apply the effects of the Homing "
        "Advantage.\n"
        "Then, if that Attacking Maneuver was of the Energy Foundation or the "
        "Elemental (Light) Profile, you may roll Strike against an Opponent "
        "of your choice using the Profile of the initial Attacking Maneuver. "
        "If they are hit, the original attacking Character rolls the Wound "
        "Roll for their initial Attacking Maneuver instead as an Urgent Roll, "
        "including any Ki Wagers and Energy Charges included on that Attacking "
        "Maneuver. Damage calculation occurs as usual from this point.",
  ),
  RaceTraitDef(
    race: 'Glass Tribe',
    subrace: 'Glass Warrior',
    tier: RaceTraitTier.primary,
    category: TraitCategory.mind,
    name: 'Glass Shards',
    description:
        "By leaving shards of glass embedded in your foes, you are able to "
        "enhance your other abilities by manipulating the shards of glass "
        "your enemies carry.\n"
        "(1)-[Triggered, Ruling]: If you hit Opponent(s) with an Attacking "
        "Maneuver of the Glass Profile, they become a 'Shard Carrier' until "
        "the start of your next turn.\n"
        "(2)-[Passive]: All Attacking Maneuvers you make that do not possess "
        "an AoE and only target a Shard Carrier gain the Homing Advantage.\n"
        "(3)-[Passive]: Increase the Dice Score of any Clash that uses your "
        "Might or Saving Throws against a Shard Carrier by 1(T).\n"
        "(4)-[Passive]: You may target a Shard Carrier with Glassification "
        "even if they are not within your Melee Range, regardless of their "
        "actual position on the Battlefield.\n"
        "(5)-[1/Round]: As an Instant Maneuver, select a Shard Carrier. Use "
        "the Basic Attack Maneuver as an Out-of-Sequence Maneuver. If you do, "
        "you must select the Glass Profile for that Attacking Maneuver and "
        "that Attacking Maneuver must include your selected Shard Carrier as "
        "a target. After concluding that Attacking Maneuver, that Character "
        "stops being a Shard Carrier.\n"
        "(6)-[1/Round]: As an Instant Maneuver, select a Shard Carrier. Make "
        "a Clash (Corporeal vs Corporeal/Impulsive) against that Character. "
        "If you win, reduce their Life Points by your Might. Then, regardless "
        "of if you win or lose, every Square within a Minor Sphere AoE "
        "(centered on that Character) gains the Glass Environmental Quality. "
        "After concluding this effect, that Character stops being a Shard "
        "Carrier.\n"
        "(7)-[Triggered, 1/Round]: If you use an Attacking Maneuver of the "
        "Glass Profile that does not possess an AoE and only targets a Shard "
        "Carrier, you may apply an Energy Charge to that Attacking Maneuver. "
        "After concluding that Attacking Maneuver, that Character stops being "
        "a Shard Carrier.",
  ),

  // -------------------------------------------------------- Neo-Tuffle ---
  RaceTraitDef(
    race: 'Neo-Tuffle',
    subrace: 'Hatred Embodiment',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Hate Empowerment',
    description:
        "Empowered by the hatred you feel for those who destroyed your "
        "predecessors, you grow stronger as the fight wears on.\n"
        "(1)-[Triggered, 1/Round]: If you spend 2+ Revenge Points on a single "
        "Attacking Maneuver that targets your Inferior, you may add an Energy "
        "Charge to that Attacking Maneuver.\n"
        "(2)-[Triggered]: Each time you spend Revenge Points, for every 2 "
        "Revenge Points spent, increase your Soak Value by 1(T) until the "
        "start of your next turn. The bonus to your Soak Value from this "
        "effect cannot exceed 4(T).\n"
        "(3)-[Triggered]: Gain 1 Revenge Point when you use the Power Up or "
        "Energy Charge Maneuver.\n"
        "(4)-[1/Round]: You may spend 2 Revenge Points to make a Basic Attack "
        "Maneuver as an Instant Maneuver. If you do, you must target your "
        "Inferior with this Attacking Maneuver.",
  ),
  RaceTraitDef(
    race: 'Neo-Tuffle',
    subrace: 'Parasite',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Parasitic Biology',
    description:
        "Able to liquefy into a smaller form and enter another being's body, "
        "you possess the power to take control over that being.\n"
        "(1)-[Passive]: You gain access to the Liquid Form Maneuver. While in "
        "Liquid Form, you have access to the Internal Attack Maneuver and the "
        "Possess Maneuver.\n"
        "(2)-[Passive]: When using the Possess Maneuver, you can only target "
        "a willing Character. To target an unwilling Character they must be; "
        "a character of a larger Size Category who is below the Bruised "
        "Health Threshold, OR a Character of a larger Size Category that has "
        "been damaged by one of your Attacking Maneuvers this Combat Round.\n"
        "(3)-[Triggered]: Each time you hit your Inferior with an Attacking "
        "Maneuver, reduce their Ki Points by 2(bT). If you spent Revenge "
        "Points on that Attacking Maneuver, increase the reduction by 1(bT) "
        "for every Revenge Point spent.\n"
        "(4)-[Triggered]: If you are hit by an Attacking Maneuver, regain "
        "3(bT) Ki Points for each Revenge Point you gained as a result of "
        "that Attacking Maneuver.\n"
        "(5)-[Triggered, 1/Round]: If you knock your Inferior through a "
        "Health Threshold with an Attacking Maneuver, and they fail the "
        "Steadfast Check for that Health Threshold, reduce their Combat Rolls "
        "by 1(bT) and their Stress Bonus by 1 while they suffer the Health "
        "Threshold Penalties for that Health Threshold.",
  ),

  // ----------------------------------------------------------- Yardrat ---
  RaceTraitDef(
    race: 'Yardrat',
    subrace: 'Tall Yardrat',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Spiritual Warrior',
    description:
        "More prepared for battle than their brethren, these Yardrats stand "
        "at the forefront of the battlefield, supported by those lesser "
        "suited to combat.\n"
        "(1)-[Passive]: Increase your Racial Life Modifier by 3.\n"
        "(2)-[Triggered]: When you apply the 3rd effect of Power of the Weak, "
        "increase your Soak Value by 1(T) for every 2(bT) Ki Points spent "
        "through that effect. This increase lasts for the duration of that "
        "Attacking Maneuver.\n"
        "(3)-[Triggered]: If your Bonded Ally targets an Opponent with an "
        "Attacking Maneuver, you may spend a Counter Action to use the Basic "
        "Attack Maneuver as an Out-of-Sequence Maneuver. If you do, you must "
        "target the same Opponent with this Attacking Maneuver.\n"
        "(4)-[Triggered, 1/Round]: If you use the Empower Maneuver to give Ki "
        "Points to an Ally, gain 1 Counter Action.\n"
        "(5)-[Triggered, 1/Round]: If you use the Basic Attack Maneuver, you "
        "do not have to pay the Ki Point Cost for this Attacking Maneuver. "
        "You still have to pay any Ki Points spent through a Ki Wager or "
        "other effects.\n"
        "(6)-[Triggered/Defeated]: If you have a Bonded Ally, they may use "
        "the Empower Maneuver as an Out-of-Sequence Maneuver as if they spent "
        "2 Actions. Instead of regaining Ki Points through this use of the "
        "Empower Maneuver, you regain Life Points equal to the amount of Ki "
        "Points spent.",
    automation: [
      // (1) +3 Racial Life Modifier.
      RaceTraitAutomation(
        affectedStats: [AffectedStat.racialLifeModifier],
        coefficient: 3,
      ),
    ],
  ),
  RaceTraitDef(
    race: 'Yardrat',
    subrace: 'Bulbous Yardrat',
    tier: RaceTraitTier.primary,
    category: TraitCategory.body,
    name: 'Spiritual Pacifist',
    description:
        "The true masters of combat support, these Yardrats prefer to avoid "
        "combat, only offering support to those who fight on their behalf.\n"
        "(1)-[Passive]: Your base Size Category is Small.\n"
        "(2)-[Passive]: Your Bonded Ally has their Combat Rolls increased by "
        "1(T).\n"
        "(3)-[Triggered, 1/Round]: If you are hit by an Attacking Maneuver, "
        "your Bonded Ally may use the Intervene Maneuver without spending a "
        "Counter Action.\n"
        "(4)-[Triggered, 1/Round]: If you target an Ally with the Empower "
        "Maneuver, you may transfer a number of Power Stacks you possess up "
        "to the amount of Actions spent on the Empower Maneuver to that Ally. "
        "These Power stacks last until the end of their next turn.\n"
        "(5)-[Triggered, 1/Round]: If you give Ki Points to an Ally through "
        "the Empower Maneuver, they may regain Life Points equal to 1/4 "
        "(rounded up) of the amount of Ki Points they gained.\n"
        "(6)-[Triggered/Defeated]: You may use the Empower Maneuver as an "
        "Out-of-Sequence Maneuver as if you spent 9,001 Actions.",
  ),
];
