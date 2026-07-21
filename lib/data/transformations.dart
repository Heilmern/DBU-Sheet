/// transformations.dart
/// ---------------------------------------------------------------------------
/// Shared data model for the Transformations system (Transformations →
/// Transformation Catalog on the site), verbatim from the site
/// (transformation-rules page, confirmed 05 July 2026). The three catalogue
/// files — `awakenings.dart`, `enhancements.dart`, `forms.dart` — all use the
/// `TransformationDef` type defined here.
///
/// FRAMEWORK (transformation-rules page, verbatim highlights):
///   • "Attribute Modifier Bonus. Each Transformation has a table which lists
///     the various Attributes and has bonuses underneath. While you are in
///     that Transformation, you gain a bonus to the relevant Attribute equal
///     to the listed bonus. Awakenings are Transformations that are always
///     active, so any Attribute Modifier Bonus listed on an Awakening is
///     applied at all times."
///   • "Transformation Stacking ... you can only be in a maximum of 1 Form
///     and 1 Enhancement at any one time." (Awakenings are always active.)
///   • "Ki Multiplier. While you are in a Form that you entered through the
///     Transformation Maneuver, your Maximum Ki Points are doubled and your
///     Max Capacity is increased by 1/2."
///   • Awakenings can Stack (up to Maximum No of Stacks), gaining repeat
///     Attribute Modifier Bonuses but not repeat Traits; "Z" in a Trait's
///     text = the number of Stacks. Some Traits gate behind a Stack count
///     (a "(2)"/"(3)" after the Trait name).
///
/// AUTOMATION: like `race_traits.dart`/`talents.dart`, only the clean,
/// mechanical parts map onto stats this app computes:
///   • Attribute Modifier Bonus (the per-Transformation table) is auto-
///     applied to Attribute MODIFIERS (see `CharacterCalculator`'s
///     `transformationModifierBonus`) — always for owned Awakenings (×
///     stacks), and while ACTIVE for Enhancements/Forms.
///   • Ki Multiplier for an active Form.
/// The Traits themselves (situational/conditional effects) are shown as
/// verbatim text for the player to apply, same convention as everywhere.
/// A `*` in the site's Attribute table means the bonus is set by the
/// Transformation's Grade (see the Graded Aspect) — those are shown as text,
/// not auto-applied, since they depend on grade-table lookups this app
/// doesn't model yet.
///
/// SCOPE: Enhancements (`enhancements.dart`, all 75) and every Form
/// (`forms.dart`, 147 Stage defs — the Alternate Forms, Legendary Forms and
/// Evolved Stages menus) are fully transcribed on this structure. A Legendary
/// Form's always-on Legendary Trait and a Form's Exceed Trait are authored
/// inline in `traits` with " (Legendary Trait)"/" (Exceed Trait)" markers and
/// surfaced via `legendaryTrait`/`exceedTrait`/`situationalTraits`. Awakenings
/// remain a representative seed covering every mechanic (stacks/Z-scaling,
/// grades/mastery/burst-limit, Grand Awakening).
library;

import 'dbu_rules.dart';
import 'race_traits.dart';

/// The three Transformation Types (verbatim): "Awakenings ... permanent
/// boosts ... Enhancements ... amplify their power temporarily ... Forms ...
/// a full on change to the body and abilities of the user temporarily."
enum TransformationType {
  awakening('Awakening'),
  enhancement('Enhancement'),
  form('Form');

  const TransformationType(this.displayName);
  final String displayName;
}

/// An Awakening's Type — this pass covers Lesser; Greater/Super are later.
enum AwakeningType {
  lesser('Lesser'),
  greater('Greater'),
  superAwakening('Super');

  const AwakeningType(this.displayName);
  final String displayName;
}

/// An Awakening's Origin (Body or Mind).
enum TransformationOrigin {
  body('Body'),
  mind('Mind');

  const TransformationOrigin(this.displayName);
  final String displayName;
}

/// An Enhancement's classification. Standard = a typical Enhancement; Special
/// = "an evolution or a rediscovery" of an Initial Enhancement you already
/// possess (see `TransformationDef.initialEnhancement`); Power = an
/// "Enhancement Power" (the site's Greater-Enhancement tier), which carries an
/// Unlimited Trait (see `TransformationDef.unlimitedTrait`) rather than a
/// Standard/Special line.
enum EnhancementType {
  standard('Standard'),
  special('Special'),
  power('Power');

  const EnhancementType(this.displayName);
  final String displayName;
}

/// A Form's Sub-Type (Alternate or Legendary — this pass covers Alternate).
enum FormType {
  alternate('Alternate'),
  legendary('Legendary');

  const FormType(this.displayName);
  final String displayName;
}

/// One Attribute's entry in a Transformation's Attribute Modifier Bonus
/// table. `–` on the site = absent from the map (no bonus). `+1` (flat, on
/// Awakenings) = `coefficient: 1, tierScaled: false`. `+2(T)` =
/// `coefficient: 2, tierScaled: true`. `*` (Grade-set) = `graded: true`,
/// which is shown as text and NOT auto-applied.
class TransformationAmb {
  const TransformationAmb({
    this.coefficient = 0,
    this.tierScaled = false,
    this.graded = false,
    this.gradePerTier = const [],
  });

  /// Base magnitude (before Tier scaling / stack multiplication).
  final int coefficient;

  /// Whether the site wrote "(T)" (scale by current Tier of Power).
  final bool tierScaled;

  /// Whether the site wrote "*" (bonus set by the Transformation's Grade).
  /// Auto-applied when [gradePerTier] is provided (the Grade table); otherwise
  /// shown as reference text.
  final bool graded;

  /// The per-Tier AMB coefficient at each Grade (index 0 = Grade 1), for graded
  /// Transformations whose AMB follows a Grade table — e.g. Kaioken's
  /// AG/FO/MA is `[1, 1, 2]` (Grade 1→1(T), 2→1(T), 3→2(T)). The value at the
  /// character's current Grade is scaled by (T). Empty = not a Grade table.
  final List<int> gradePerTier;
}

/// A single Trait belonging to a Transformation. Reuses `race_traits.dart`'s
/// Option/automation machinery so the Information/Transformations pages can
/// render them identically to Racial Traits.
/// A Ki-Wager-conditional bonus to the Wound Roll of an Attacking Maneuver,
/// applied by the References tab's Attack Reference (the wager amount is an
/// ephemeral input there, so this can't flow through the persistent buff
/// pipeline like the always-on `automation`). Two shapes, matching the site's
/// wager wordings:
///   • a THRESHOLD flat bonus — "an Attacking Maneuver with a Ki Wager ≥ X has
///     its Wound Roll increased by [bonusPerTier](T)", the threshold being
///     either a fraction of Max Capacity (`thresholdMaxCapacityDen`, e.g. 4 →
///     ¼ Max Capacity) or a per-Tier amount (`thresholdPerTier`, e.g. 2 → 2(T)).
///   • a FRACTION of the wager — "increase the Wound Roll by 1/N of the Ki
///     Points spent on the Ki Wager" (`fractionOfWagerDen`, floored).
///
/// Divine-Ki-specific wager effects are NOT modelled here (the app doesn't
/// track Divine vs normal Ki Points) — they stay verbatim reference text.
class WagerWoundEffect {
  const WagerWoundEffect({
    this.thresholdMaxCapacityDen = 0,
    this.thresholdPerTier = 0,
    this.bonusPerTier = 0,
    this.fractionOfWagerDen = 0,
    this.signatureOnly = false,
    this.ultimateOnly = false,
  });

  /// Threshold = Max Capacity ÷ this (e.g. 4 → ¼ Max Capacity). 0 = unused.
  final int thresholdMaxCapacityDen;

  /// Threshold = this × Tier of Power (e.g. 2 → 2(T)). 0 = unused.
  final int thresholdPerTier;

  /// Flat Wound bonus per Tier of Power once the threshold is met.
  final int bonusPerTier;

  /// Wound bonus = wager ÷ this (floored) — a fraction of the Ki wagered.
  final int fractionOfWagerDen;

  final bool signatureOnly;
  final bool ultimateOnly;

  /// The Wound Roll bonus for a given wager / Tier / Max Capacity context.
  int woundBonus({
    required int wager,
    required int tierOfPower,
    required int maxCapacity,
    required bool isSignature,
    required bool isUltimate,
  }) {
    if (wager <= 0) return 0;
    if (signatureOnly && !isSignature) return 0;
    if (ultimateOnly && !isUltimate) return 0;
    if (fractionOfWagerDen > 0) return wager ~/ fractionOfWagerDen;
    final threshold = thresholdMaxCapacityDen > 0
        ? maxCapacity ~/ thresholdMaxCapacityDen
        : thresholdPerTier * tierOfPower;
    return wager >= threshold ? bonusPerTier * tierOfPower : 0;
  }
}

class TransformationTrait {
  const TransformationTrait({
    required this.name,
    required this.description,
    this.minStacks = 1,
    this.optionGroups = const [],
    this.automation = const [],
    this.ambBonus = const {},
    this.distributableAmb = const [],
    this.wagerWoundEffect,
  });

  final String name;

  /// Verbatim flavour text + numbered effects.
  final String description;

  /// For an Awakening Trait gated behind a Stack count (a "(2)"/"(3)" after
  /// the Trait name) — the Trait is only active once the character has this
  /// many Stacks of the Awakening. 1 = always active.
  final int minStacks;

  /// Character-Creation-style choice(s) offered by this Trait (`[Option]`).
  final List<RaceTraitOptionGroup> optionGroups;

  /// The clean, additive stat automation (most Traits are situational and
  /// stay text-only) — applied while this Trait is in effect (see
  /// `CharacterCalculator.transformationTraitsInEffect`).
  final List<RaceTraitAutomation> automation;

  /// An extra Attribute Modifier Bonus granted by this Trait's text while it
  /// is in effect (e.g. a Grand Awakening's "Increase your Attribute
  /// Modifiers (AG/FO/TE/MA) by 2(T)") — added into
  /// `CharacterCalculator.transformationModifierBonus` on top of the
  /// Transformation's own `amb` table. Applied ONCE (Traits don't repeat per
  /// Stack), honouring `tierScaled`; `graded` entries are ignored as ever.
  final Map<DbuAttribute, TransformationAmb> ambBonus;

  /// Attributes among which the player distributes a **flat +1** AMB per Stack
  /// gained (the site's per-Stack "select AG or TE; increase this Awakening's
  /// AMB for it by 1 (after Stacks)" — e.g. Steady Progress's AG/TE). When
  /// non-empty, the UI renders one stepper per listed Attribute writing to
  /// `TransformationSelection.flatAmb`; the total should equal the Stack count.
  final List<DbuAttribute> distributableAmb;

  /// A Ki-Wager-conditional Wound Roll bonus, applied in the References tab's
  /// Attack Reference while this Trait is in effect (see [WagerWoundEffect]).
  final WagerWoundEffect? wagerWoundEffect;

  bool get hasOptions => optionGroups.isNotEmpty;

  bool get isAutomated =>
      automation.isNotEmpty ||
      ambBonus.isNotEmpty ||
      optionGroups
          .any((g) => g.options.any((o) => o.automation.isNotEmpty));
}

/// A single Transformation (one page of the Transformation Catalog). A Form
/// Stage is its own `TransformationDef` (sharing a `transformationLine`),
/// mirroring the rules: "A Stage ... each being their own Transformation."
class TransformationDef {
  const TransformationDef({
    required this.name,
    required this.type,
    required this.racialRequirement,
    this.tierOfPowerRequirement = 1,
    this.prerequisiteText = 'N/A',
    this.aspects = const [],
    this.amb = const {},
    this.traits = const [],
    this.masteryTrait,
    this.masteryTraits = const [],
    this.burstLimit,
    this.transcendentTrait,
    this.unlimitedTrait,
    // Awakening-specific:
    this.awakeningType,
    this.origin,
    this.maxStacks = 1,
    this.grandAwakening,
    // Enhancement-specific:
    this.enhancementType,
    this.initialEnhancement,
    this.stressTestRequirement,
    // Form-specific:
    this.formType,
    this.transformationLine,
    this.stage,
  });

  final String name;
  final TransformationType type;

  /// Verbatim "Racial Requirement:" line (e.g. "Any", "Saiyan").
  final String racialRequirement;

  /// Verbatim "Tier of Power Requirement." minimum.
  final int tierOfPowerRequirement;

  /// Verbatim "Prerequisite(s):" line — reference, not programmatically
  /// enforced (same convention as Factors/Talents).
  final String prerequisiteText;

  /// Verbatim "Aspects:" line, split into individual aspect labels (shown as
  /// reference chips; Aspects are a large sub-system not yet modelled).
  final List<String> aspects;

  /// The Attribute Modifier Bonus table (only Attributes with a bonus are
  /// present).
  final Map<DbuAttribute, TransformationAmb> amb;

  final List<TransformationTrait> traits;

  /// The single Mastery Trait (for Forms/Enhancements without the Difficult
  /// Aspect). Verbatim: "When a Transformation is mastered, that
  /// Transformation gains its Mastery Trait."
  final TransformationTrait? masteryTrait;

  /// Multiple Mastery Traits, unlocked one-per-Mastery for a Transformation
  /// with the Difficult Aspect (each requires an additional level of
  /// Mastery). Index 0 = 1st Mastery, etc.
  final List<TransformationTrait> masteryTraits;

  /// The Burst Limit Trait (Enhancements only) — verbatim: "Upon entering an
  /// Enhancement ... you may choose to trigger its Burst Limit Trait."
  final TransformationTrait? burstLimit;

  /// The Transcendent Trait carried by an Enhancement with the Transcendent
  /// Aspect (null otherwise) — verbatim: "If you have Fully Mastered an
  /// Enhancement with the Transcendent Aspect, you may gain access to its
  /// Transcendent Trait while it is Transcended. To gain it, you must gain an
  /// additional level of Mastery when the Transformation is already Fully
  /// Mastered." A Transcended Enhancement counts as a Form for Transformation
  /// Stacking. Rendered as its own togglable subsection, like a Super
  /// Awakening's `grandAwakening`.
  final TransformationTrait? transcendentTrait;

  /// True if this Enhancement can Transcend (has the Transcendent Aspect).
  bool get isTranscendent =>
      transcendentTrait != null || aspects.any((a) => a == 'Transcendent');

  /// The Unlimited Trait carried by an Enhancement Power (`EnhancementType.
  /// power`); null otherwise. Unlocked via Power Improvement: Unlimited (a
  /// Greater-Enhancement sub-system not otherwise modelled); rendered as its
  /// own togglable subsection.
  final TransformationTrait? unlimitedTrait;

  // --- Awakening-specific ---
  final AwakeningType? awakeningType;
  final TransformationOrigin? origin;

  /// "Maximum No of Stacks" (1 for most).
  final int maxStacks;

  /// The "Grand Awakening" Trait carried by a Super Awakening (null for
  /// Lesser/Greater). Its first effect is a `[Grand Trigger]` condition and it
  /// is switched on via the Full Awakening Maneuver — modelled here as a
  /// dedicated Trait so the UI can render it as its own togglable subsection.
  final TransformationTrait? grandAwakening;

  /// True if this is a Super Awakening with a Grand Awakening Trait.
  bool get hasGrandAwakening => grandAwakening != null;

  // --- Enhancement-specific ---
  final EnhancementType? enhancementType;

  /// For a Special Enhancement: the name of its Initial Enhancement.
  final String? initialEnhancement;

  /// "Stress Test Requirement" (Enhancements/Forms; null for Awakenings).
  final int? stressTestRequirement;

  // --- Form-specific ---
  final FormType? formType;

  /// The Transformation Line this Form Stage belongs to (e.g. "Super
  /// Saiyan"); null for a standalone Form.
  final String? transformationLine;

  /// This Form's Stage number within its line (1, 2, 3...; 0 = Null Stage).
  final int? stage;

  /// True if this Form is an Evolved Stage of another Form (its
  /// `Evolved Stage Type: Generic/Unique (X)` page). Detected from
  /// `prerequisiteText`, which for every Evolved Stage begins "Evolved Stage".
  /// Per the Evolved Stages rules, an Evolved Stage is 1 Stage above its
  /// Original Form, shares that Form's Transformation Line, inherits its
  /// Racial Requirement, and ADDS its AMB/Aspects on top of the Original's;
  /// its Stress Test Requirement is an addition. Those combinations are shown
  /// as reference text (in `prerequisiteText`), not auto-computed.
  bool get isEvolvedStage =>
      type == TransformationType.form &&
      prerequisiteText.startsWith('Evolved Stage');

  /// For a UNIQUE Evolved Stage, the name of the specific Original Form it
  /// evolves — parsed from the `Evolved Stage: Unique (<Original Form>)`
  /// prefix of [prerequisiteText]. Null for a Generic Evolved Stage (which
  /// applies broadly, not to one named Form) or a non-Evolved Form.
  String? get evolvedStageOriginalForm {
    if (!isEvolvedStage) return null;
    final m = RegExp(r'Evolved Stage:\s*Unique\s*\(([^)]+)\)')
        .firstMatch(prerequisiteText);
    return m?.group(1)?.trim();
  }

  /// True if this is a GENERIC Evolved Stage — one that can be applied to a
  /// range of Original Forms (its eligibility is gated by prerequisites too
  /// varied to enumerate here), as opposed to a Unique Evolved Stage tied to
  /// one named Form.
  bool get isGenericEvolvedStage =>
      isEvolvedStage && evolvedStageOriginalForm == null;

  /// A Null Stage (Stage 0) counts as the Character's Normal State, NOT a
  /// Form: it does NOT grant the Ki Multiplier and (if Legendary) has no
  /// Legendary Trait. Only its Traits and Attribute Modifier Bonus apply.
  bool get isNullStage => type == TransformationType.form && stage == 0;

  /// True if this Transformation has at least one Mastery Trait to unlock.
  bool get canBeMastered => masteryTrait != null || masteryTraits.isNotEmpty;

  /// How many Mastery levels this Transformation has (Difficult Aspect = the
  /// number of `masteryTraits`; a single `masteryTrait` = 1).
  int get masteryLevels =>
      masteryTraits.isNotEmpty ? masteryTraits.length : (masteryTrait != null ? 1 : 0);

  /// The always-on Legendary Trait of a Legendary Form. Rules (transformation-
  /// rules): "Legendary Traits are Traits that your Character possesses at ALL
  /// TIMES after gaining access to that Legendary Form" — i.e. not gated by the
  /// Form being active, unlike the situational `traits`. It is authored inline
  /// in `traits` with a " (Legendary Trait)" name marker and surfaced here with
  /// the marker stripped, so the UI can render it in its own always-active
  /// subsection. (A Null Stage of a Legendary Form has none — its Traits carry
  /// no such marker.)
  TransformationTrait? get legendaryTrait => _markedTrait('(Legendary Trait)');

  /// The Exceed Trait (active while in the Exceed State), authored inline in
  /// `traits` with a " (Exceed Trait)" marker.
  TransformationTrait? get exceedTrait => _markedTrait('(Exceed Trait)');

  /// `traits` minus the Legendary/Exceed Traits — the situational Traits shown
  /// only while the Form/Enhancement is active.
  List<TransformationTrait> get situationalTraits => [
        for (final t in traits)
          if (!t.name.endsWith('(Legendary Trait)') &&
              !t.name.endsWith('(Exceed Trait)'))
            t,
      ];

  TransformationTrait? _markedTrait(String marker) {
    for (final t in traits) {
      if (t.name.endsWith(marker)) {
        return TransformationTrait(
          name: t.name.replaceAll(' $marker', '').trim(),
          description: t.description,
          minStacks: t.minStacks,
          optionGroups: t.optionGroups,
          automation: t.automation,
        );
      }
    }
    return null;
  }
}

/// Awakening Limit table (transformation-rules page, verbatim): maximum
/// number of Lesser/Greater Awakenings a Character may possess, by their
/// base Tier of Power. (Super Awakenings are always capped at 1.)
class AwakeningLimits {
  const AwakeningLimits(this.lesser, this.greater);
  final int lesser;
  final int greater;
}

/// Base Tier of Power → Awakening Limits. CONFIRMED against the
/// transformation-rules page's Awakening Limit table (raw `<td>` cells,
/// re-verified 18 July 2026 — the Lesser column was previously off by one):
/// bT1 → 2/1, bT2 → 3/1, bT3 → 4/2, bT4 → 5/2, bT5 → 6/3, bT6 → 7/3,
/// bT7 → 7/4.
AwakeningLimits awakeningLimitsFor(int baseTierOfPower) {
  const table = {
    1: AwakeningLimits(2, 1),
    2: AwakeningLimits(3, 1),
    3: AwakeningLimits(4, 2),
    4: AwakeningLimits(5, 2),
    5: AwakeningLimits(6, 3),
    6: AwakeningLimits(7, 3),
    7: AwakeningLimits(7, 4),
  };
  return table[baseTierOfPower.clamp(1, 7)] ?? const AwakeningLimits(2, 1);
}

/// The maximum Super Awakenings any Character may possess (verbatim: "Each
/// Character can only possess a single Super Awakening").
const int kMaxSuperAwakenings = 1;
