/// aspects.dart
/// ---------------------------------------------------------------------------
/// The Transformation ASPECTS sub-system (Transformations → Aspects on the
/// site), verbatim from the site (transformation-aspects page, confirmed 07
/// July 2026).
///
/// FRAMEWORK (verbatim highlights):
///   • "Each Transformation has a list of Aspects they possess. Aspects are
///     separated into two categories: Positive and Negative, the former
///     benefiting the user and the latter acting as a drawback of the form."
///   • "Aspects that have levels are marked with [LV] at the end of their
///     name. If there is a limit on the number of levels you can possess, it
///     will be shown as ~X … For example, Growth … is shown as Growth
///     [LV~3]."
///   • "Solo Aspects. Some Aspects with levels will have [Solo] after their
///     name. These Aspects do not stack their levels together if used in
///     conjunction with one another."
///   • Some Aspects take a bracketed parameter naming what they apply to —
///     e.g. Enhanced Save (a Saving Throw), Innate State (a State), Linked
///     (an Enhancement), Variant (a Transformation).
///
/// AUTOMATION: like `race_traits.dart`/`talents.dart`, most Aspect effects
/// are situational and are rendered as verbatim Effect text (with the level
/// cap / parameter surfaced) for the player to apply. The clean numeric
/// subset IS auto-applied while the carrying Transformation is in effect —
/// see `CharacterCalculator.aspectTotals` (Enhanced Save / Raging / Mindful /
/// High Speed), `maxKi`/`maxCapacity` (Super Saiyan Form's ×1.25),
/// `attackReference` (Perfect Ki Control's −1(T) KP, floor 2(T)) and
/// `computeDamage` (Armored's Damage-Category −1). A Transformation's
/// `aspects` list (see `TransformationDef.aspects`) stores the raw label the
/// site printed (e.g. `'Heartbeat (LV3)'`, `'Enhanced Save (Impulsive)'`);
/// `resolveAspect` splits that into its `AspectDef` plus the printed level /
/// parameter.
library;

/// Whether an Aspect benefits the user (Positive) or is a drawback (Negative).
enum AspectPolarity {
  positive('Positive'),
  negative('Negative');

  const AspectPolarity(this.displayName);
  final String displayName;
}

/// One Aspect definition (one row of the Aspects page).
class AspectDef {
  const AspectDef({
    required this.name,
    required this.polarity,
    required this.summary,
    required this.effect,
    this.hasLevels = false,
    this.maxLevels,
    this.solo = false,
    this.parameterLabel,
  });

  /// The Aspect's name as it heads its entry (without `[LV]`/`[Solo]` markers).
  final String name;

  final AspectPolarity polarity;

  /// The short italic descriptor line the site prints before the Effect.
  final String summary;

  /// Verbatim "-Effect:" text.
  final String effect;

  /// True if the Aspect can have levels (site marks it `[LV]`/`[LV~X]`).
  final bool hasLevels;

  /// Highest level, when the site prints `[LV~X]`; null = levelled but
  /// uncapped (`[LV]`, e.g. Draining) or not levelled at all.
  final int? maxLevels;

  /// True if a levelled Aspect is `[Solo]` — its levels don't stack with the
  /// same Aspect on another Transformation used in conjunction.
  final bool solo;

  /// For Aspects that take a bracketed parameter, what that parameter names
  /// (e.g. 'Saving Throw', 'State', 'Enhancement', 'Transformation'); null if
  /// the Aspect takes no parameter. NOTE: a levelled Aspect prints its level
  /// in the same brackets instead — see [hasLevels].
  final String? parameterLabel;

  /// True if this Aspect carries no mechanical effect and exists purely to
  /// classify a Transformation (the site prints "N/A. This Aspect exists
  /// entirely for classification." as its Effect). The UI renders these as a
  /// clean muted note rather than the raw "N/A." sentence.
  bool get isClassificationOnly => effect
      .trim()
      .toLowerCase()
      .startsWith('n/a. this aspect exists entirely for classification');

  /// The bracketed suffix the site prints after the name, if any
  /// (`[LV~3]`, `[Solo, LV~2]`, `[LV]`).
  String get marker {
    if (!hasLevels) return '';
    final lv = maxLevels == null ? 'LV' : 'LV~$maxLevels';
    return solo ? '[Solo, $lv]' : '[$lv]';
  }
}

/// The Aspects catalogue — Positive first, then Negative, each verbatim.
const List<AspectDef> kDbuAspects = [
  // ===================================================== Positive Aspects ===
  AspectDef(
    name: 'Absorbed Apparel',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation leaves you without external defenses.',
    effect: 'You lose all of your equipped Apparel while in this '
        'Transformation (regain and equip it when you leave this '
        'Transformation), but increase your Combat Rolls and Soak Value by '
        '1/2 (rounded up) of the Apparel Bonus of the highest piece of '
        'Apparel that you had equipped (max. 2(T)).',
  ),
  AspectDef(
    name: 'Armored',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation provides a defensive boost.',
    effect: 'Reduce the Damage Category of all Attacking Maneuvers that hit '
        'you by 1 Category for the sake of your Damage Calculation.',
  ),
  AspectDef(
    name: 'Battle Uniform',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation includes a unique outfit.',
    effect: 'When you enter this Transformation, you lose access to your '
        'current Apparel until you leave the Transformation. While within the '
        'Transformation, you are equipped with the Apparel described at the '
        "bottom of the Transformation's description. Apparel given through "
        'Battle Uniform has the Stretching Quality, and any Special Qualities '
        'possessed by the Apparel you were previously wearing. All Qualities '
        'unique to Battle Uniforms are Special Qualities. If you\'re '
        'benefiting from the Battle Uniform Aspect from a Form (or Transcended '
        'Enhancement) and an Enhancement concurrently, apply the Grade and '
        "Category from the non-Transcended Enhancement's Battle Uniform.",
  ),
  AspectDef(
    name: 'Bulky',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation causes your muscles to bulge with strength.',
    effect: 'Gain 1 Super Stack while in this Transformation. If this '
        'Transformation is Mastered (or in the case of an Evolved Stage, if '
        'the Original Form is Mastered), you may choose to ignore this effect '
        'upon entering a Transformation with this Aspect.',
  ),
  AspectDef(
    name: 'Enhanced Save',
    polarity: AspectPolarity.positive,
    summary: "This Transformation makes it easier to avoid your enemies' "
        'harmful effects.',
    effect: 'Increase the Saving Throw(s) listed in brackets after this '
        "Aspect's name by 1(T).",
    parameterLabel: 'Saving Throw',
  ),
  AspectDef(
    name: 'Glowing',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation projects a glowing aura of light.',
    effect: 'You are a Light Source that increases the Light Level by 1 in a '
        'Minor Sphere AoE (centered on you). This increase to Light Level '
        'cannot cause the Light Level to exceed Normal.',
  ),
  AspectDef(
    name: 'God Ki',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation grants access to divine ki.',
    effect: 'While you are in this Transformation, you are in the God Ki '
        'State.',
  ),
  AspectDef(
    name: 'Graded',
    polarity: AspectPolarity.positive,
    summary: 'You can draw additional power out of this Transformation.',
    effect: 'This Transformation has Grades (see - Stages and Grades). While '
        'in a Transformation with the Graded Aspect, you may use the '
        'Transformation Maneuver to attempt to enter that same Transformation '
        '(but at a different Grade). If you do, you must still make the Stress '
        'Test for that Transformation at that Grade and if you fail, you will '
        'suffer the typical consequences.',
  ),
  AspectDef(
    name: 'Growth',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation increases the size of your body.',
    effect: 'The first level of this Aspect sets your Size Category to Large '
        'while in this Transformation. For every level after the first, '
        'increase the Size Category you are set to by 1. This Aspect cannot '
        'cause your Size Category to be lower than it would be prior to '
        'applying its effects.',
    hasLevels: true,
    maxLevels: 3,
  ),
  AspectDef(
    name: 'Heartbeat',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation can be entered in the span of a single '
        'heartbeat.',
    effect: 'If your Stress Bonus is equal to or higher than 4 less than the '
        'Stress Test Requirement (or combined Stress Test Requirement if used '
        'alongside another Transformation) of this Transformation, you may '
        'enter this Transformation for the duration of any Maneuver you use or '
        'any Maneuver that targets you. You cannot leave a Transformation to '
        'enter this Transformation, unless that Transformation is a lower '
        'Stage (see - Forms) of this Transformation, and if you do, you return '
        'to the lower Stage after concluding the Maneuver.\n'
        'If this Transformation has the Graded Aspect, and you are already in '
        'this Transformation, you may instead enter a higher Grade for the '
        'duration of a Maneuver through the effects of this Aspect (as long as '
        'you meet the requirement in regards to the Stress Test Requirement of '
        'that Grade).\n'
        'You can only use this effect to enter a Transformation through the '
        'effects of this Aspect a number of times per Combat Round equal to '
        'its levels in this Aspect.',
    hasLevels: true,
    maxLevels: 3,
    solo: true,
  ),
  AspectDef(
    name: 'High Speed',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation dramatically increases your speed.',
    effect: 'Increase your Speeds by the Attribute Modifier Bonus (AG) of '
        'this Transformation. If you are using multiple Transformations in '
        'conjunction with another that possesses this Aspect, only increase '
        'your Speeds by the highest Attribute Modifier Bonus (AG).',
  ),
  AspectDef(
    name: 'Innate State',
    polarity: AspectPolarity.positive,
    summary: 'While in this Transformation, you remain in a specific state of '
        'mind.',
    effect: 'Upon entering this Form, you enter the State listed in brackets '
        'after this Aspect until you leave this Transformation. If you would '
        'leave this State for any reason, at the start of your next turn, '
        'leave this Transformation and gain Stress Exhaustion until the end of '
        'your next turn.',
    parameterLabel: 'State',
  ),
  AspectDef(
    name: 'Linked',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation requires the use of a specific technique.',
    effect: 'Upon entering this Form, you also enter the listed Enhancement in '
        'brackets after this Aspect. If you were already using an Enhancement, '
        'you leave that Enhancement to enter the listed Enhancement. If you '
        'have to leave the Linked Enhancement due to any effects, also leave '
        'this Transformation.',
    parameterLabel: 'Enhancement',
  ),
  AspectDef(
    name: 'Mindful',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation lends itself well to a calm, serene state '
        'of mind.',
    effect: 'While in the Mindful State, increase your Dodge Rolls and your '
        'Strike Rolls for the Parry effect of the Defend Maneuver by 1(T).',
  ),
  AspectDef(
    name: 'Natural',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation is as easy to maintain as not transforming '
        'at all.',
    effect: 'When entering this Transformation and while you are only in this '
        'Transformation (unless you are using it in conjunction solely with '
        'other Transformations with the Natural Aspect), you are not required '
        'to roll Stress Tests. Do not leave this Transformation if you are '
        'suffering from Stress Exhaustion and you can enter this '
        'Transformation while in Stress Exhaustion.\n'
        'At the second level, if you would leave a Transformation, you may '
        'enter this Transformation instead of your Normal State. You still '
        'suffer from the effects of Stress Exhaustion.',
    hasLevels: true,
    maxLevels: 2,
    solo: true,
  ),
  AspectDef(
    name: 'Perfect Ki Control',
    polarity: AspectPolarity.positive,
    summary: 'Being in this Transformation makes it easier to spend your ki.',
    effect: 'Reduce the Ki Point Cost of all Attacking Maneuvers by 1(T). '
        'Your Minimum Ki Point Cost for your Attacking Maneuvers is 2(T), this '
        'cannot increase the Minimum Ki Point Cost for an Attacking Maneuver.',
  ),
  AspectDef(
    // Re-verified live 20 Jul 2026: now levelled ("Pinnacle [Solo, LV~2]")
    // with the 2nd-level opt-out rule appended.
    name: 'Pinnacle',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation can continue to evolve.',
    effect: 'This Evolved Stage can be stacked atop another Evolved Stage '
        'with the same Original Transformation (for more information, see - '
        'Evolved Stages).\n'
        'If a Transformation has the 2nd level of the Pinnacle Aspect, you '
        'can choose whether to apply the Pinnacle Aspect or not when using '
        'the Transformation Maneuver to enter it.',
    hasLevels: true,
    maxLevels: 2,
    solo: true,
  ),
  AspectDef(
    name: 'Prelude',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation is easier to enter than normal.',
    effect: 'If you would select this Transformation for the Transformation '
        "Maneuver, you may reduce this Transformation's Tier of Power "
        'Requirement by 1 and its Stress Test Requirement by 5 until you leave '
        'this Transformation. If you do, you also reduce the Attribute '
        'Modifier Bonuses by 1(T) (this cannot reduce those Attribute Modifier '
        'Bonuses below 1(T)) and you do not benefit from the last '
        'Transformation Trait of this Transformation while in this '
        'Transformation (any Permanent effects are still in effect). If a rule '
        'or effect would increase your Tier of Power while a Transformation is '
        'benefiting from the effects of the Prelude Aspect, you may choose to '
        'remove the effects of the Prelude Aspect for the duration of that '
        'effect (this also includes losing any Holding Back stacks, in which '
        'case it lasts until you leave the Transformation or gain another '
        'Holding Back stack).',
  ),
  AspectDef(
    name: 'Raging',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation is conducive to an aggressive state of mind.',
    effect: 'While in the Raging State, increase your Wound Rolls by 2(T).',
  ),
  AspectDef(
    name: 'Realization',
    polarity: AspectPolarity.positive,
    summary: 'You can restore your energy and vitality more easily in this '
        'Transformation.',
    effect: 'You may apply the effects of Legend Realized as an Instant '
        'Maneuver (in addition to the use gained through entering the '
        'Transformation) x number of times per Combat Encounter, where x is '
        'equal to the amount your base Tier of Power exceeds the original Tier '
        'of Power Requirement for this Transformation (before any '
        'modification, such as through the Scaling Aspect). x cannot exceed 2.',
  ),
  AspectDef(
    name: 'Scaling',
    polarity: AspectPolarity.positive,
    summary: "This Transformation's power grows with you.",
    effect: 'Increase your Attribute Modifier Bonuses for this Transformation '
        '(except IN) by x(T), and the Stress Test Requirement of this '
        'Transformation by 2x, where x is equal to the amount your Tier of '
        'Power exceeds the original (before any modifications) Tier of Power '
        'Requirement for this Transformation. x cannot exceed the level of '
        'this Aspect.\n'
        'Increase the Tier of Power Requirement of this Transformation by x '
        'for the sake of any effects (this includes the effects of other '
        'Aspects like Draining).',
    hasLevels: true,
    maxLevels: 4,
    solo: true,
  ),
  AspectDef(
    name: 'Super Saiyan Form',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation possesses the power of a Super Saiyan.',
    effect: 'Apply your Tier of Power Extra Dice an additional time and '
        'increase your Maximum Ki Points and Max Capacity by 1/4 of their '
        'maximums.\n'
        'A Transformation with this Aspect is considered to be in the Super '
        'Saiyan Transformation Line for the effects of your Traits.',
  ),
  AspectDef(
    name: 'Transcendent',
    polarity: AspectPolarity.positive,
    summary: 'This Transformation reaches great heights of power, allowing it '
        'to take the place of transforming your body.',
    effect: 'This Transformation can become a Transcended Enhancement (see - '
        'Transcendent).',
  ),
  AspectDef(
    name: 'Variant',
    polarity: AspectPolarity.positive,
    summary: '',
    effect: 'This Transformation is a Variant Transformation for the '
        'Transformation listed in brackets.',
    parameterLabel: 'Transformation',
  ),
  // ===================================================== Negative Aspects ===
  AspectDef(
    name: 'Blutz Wave',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation can only be used while you possess a Saiyan '
        'tail.',
    effect: 'A Character can only enter this Transformation if they have the '
        'Tailed Option effect for the Saiyan Heritage Racial Trait. If they '
        'would lose their Tail (or this Option effect) through any means, they '
        'immediately leave this Transformation and suffer from Stress '
        'Exhaustion until the end of their next turn.\n'
        'A Called Shot made against the Tail of a Character with this Aspect '
        'has its Damage Category reduced by 1 Category.\n'
        'A Transformation with this Aspect is considered to be in the Great '
        'Ape Transformation Line for the effects of your Traits.',
  ),
  AspectDef(
    name: 'Bursting',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation leaves you shirtless, for some reason.',
    effect: 'Upon entering this Transformation, destroy your Top Layer of '
        'Apparel.',
  ),
  AspectDef(
    name: 'Difficult',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation is hard to fully master.',
    effect: 'For each level of this Aspect, you must master this '
        'Transformation an additional time. The Mastery Trait is separated '
        'into multiple Traits, ordered by a number in brackets after the name '
        'of the Trait showing how many times that Transformation needed to be '
        'mastered to gain that Trait.\n'
        "A denotation of 'M' refers to the number of times a Transformation "
        'has been Mastered (see — Mastery for more information).',
    hasLevels: true,
    maxLevels: 2,
    solo: true,
  ),
  AspectDef(
    name: 'Draining',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation drains your energy over time.',
    effect: 'At the start of each of your turns, reduce your Ki Points by '
        '3(T) for each level of this Aspect. When calculating the Tier of '
        'Power for Draining, use the highest Tier of Power Requirement for any '
        'Transformation(s) you are currently in, instead of your current Tier '
        'of Power.',
    hasLevels: true,
  ),
  AspectDef(
    name: 'Exhausting',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation leaves you tired.',
    effect: 'If you would leave this Transformation through any means, except '
        'to use the Transformation Maneuver to enter a Transformation with a '
        'higher Tier of Power Requirement, immediately begin suffering from '
        'the Stress Exhaustion and Impediment Combat Conditions until the end '
        'of your next turn.',
  ),
  AspectDef(
    name: 'Fading',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation is only available for a limited time.',
    effect: 'Depending on the level, apply the following effects:\n'
        'LV1: Upon leaving this Transformation, you cannot enter this '
        'Transformation again for the remainder of the Combat Encounter.\n'
        'LV2: Upon leaving this Transformation, you lose access to this '
        'Transformation.',
    hasLevels: true,
    maxLevels: 2,
    solo: true,
  ),
  AspectDef(
    name: 'Light Dependent',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation is fundamentally tied to the aura of light '
        'that it projects.',
    effect: 'N/A. This Aspect exists entirely for classification.',
  ),
  AspectDef(
    name: 'Limited',
    polarity: AspectPolarity.negative,
    summary: 'The power of this Transformation wanes as you fight.',
    effect: 'After using the Transformation Maneuver to enter this '
        'Transformation, you will be forced to leave this Transformation in a '
        'number of Combat Rounds equal to the level of this Aspect. When you '
        'do, you do not suffer from Stress Exhaustion but you cannot enter the '
        'Transformation you left through Limited again until the end of your '
        'next turn. You still suffer Stress Exhaustion if this Transformation '
        'has the Exhausting Aspect.',
    hasLevels: true,
    maxLevels: 5,
    solo: true,
  ),
  AspectDef(
    name: 'Long Transformation',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation takes longer to enter than others.',
    effect: 'Increase the amount of Actions required to enter this '
        'Transformation through the Transformation Maneuver by 1 for each '
        'level of this Aspect. Ignore the effects of the Heartbeat Aspect for '
        'a Transformation with this Aspect, and the Transformation Maneuver '
        'when used to try and enter this Transformation triggers the Exploit '
        'Maneuver from any adjacent Opponents. If you have 2 levels of this '
        'Aspect, then it triggers the Exploit Maneuver from any Opponents who '
        'are not at Long Range.\n'
        'If you are knocked through a Health Threshold when using the '
        'Transformation Maneuver to enter this Transformation with this Aspect '
        'from an Attacking Maneuver used through the Exploit Maneuver, you '
        'automatically fail the Stress Test to enter this Transformation.',
    hasLevels: true,
    maxLevels: 2,
  ),
  AspectDef(
    name: 'Peaked',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation has reached its absolute maximum potential.',
    effect: 'This Transformation cannot be Mastered, but is always considered '
        'Mastered for effects.',
  ),
  AspectDef(
    name: 'Power High',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation overwhelms your reason, increasing your '
        'arrogance.',
    effect: 'Increase the Ki Point Cost for the Guard option of the Defend '
        'Maneuver by 1(T) for each level of the Power High Aspect.',
    hasLevels: true,
    maxLevels: 3,
  ),
  AspectDef(
    name: 'Rampaging',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation overwhelms your mind and causes you to act '
        'uncontrollably.',
    effect: 'Upon entering this Transformation, and at the start of each of '
        'your turns while in this Transformation, gain the Compelled Combat '
        'Condition against the nearest Opponent until the start of your next '
        'turn. If you have 2 levels of Rampaging, instead gain the Compelled '
        'Combat Condition against the nearest Character.\n'
        'While you are suffering from the Compelled Combat Condition, you '
        'cannot leave this Transformation through the Transformation Maneuver, '
        'effects of the Heartbeat Aspect, or Revert Maneuver. Additionally, '
        'your Stress Tests become Urgent.\n'
        'Upon entering this Transformation, or at the start of your turn, you '
        'can spend 1 Karma Point to ignore the effects of the Rampaging Aspect '
        'until the start of your next turn.',
    hasLevels: true,
    maxLevels: 2,
  ),
  AspectDef(
    name: 'Straining',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation eats up your stamina over time.',
    effect: 'While in this Transformation, you must make a Stress Test at the '
        'start of each of your turns.',
  ),
  AspectDef(
    name: 'Weakening',
    polarity: AspectPolarity.negative,
    summary: 'This Transformation grows weaker when your energy reserves are '
        'low.',
    effect: 'If your current Ki Point Pool is below 1/4 of your Maximum Ki '
        'Point Pool while in this Transformation, reduce this '
        "Transformation's Attribute Modifier Bonuses (after all calculations) "
        'by 1/2. You do not suffer this effect if you have entered this '
        'Transformation through the effects of the Heartbeat Aspect.',
  ),
];

/// The result of splitting a Transformation's printed Aspect label (e.g.
/// `'Heartbeat (LV3)'`, `'Enhanced Save (Impulsive)'`) into its definition
/// plus the printed level / parameter.
class ResolvedAspect {
  const ResolvedAspect({
    required this.label,
    this.def,
    this.level,
    this.parameter,
  });

  /// The raw label as printed on the Transformation.
  final String label;

  /// The matched catalogue definition, or null for an unrecognized Aspect.
  final AspectDef? def;

  /// The level parsed from a `(LV2)`/`(LV~2)` bracket, if any.
  final int? level;

  /// The non-level bracket parameter parsed (e.g. `Impulsive`, the Saving
  /// Throw for Enhanced Save), if any.
  final String? parameter;
}

/// Looks up an Aspect by its bare name (no bracket markers).
AspectDef? aspectByName(String name) {
  for (final a in kDbuAspects) {
    if (a.name == name) return a;
  }
  return null;
}

/// Splits a printed Aspect label into its [AspectDef] plus any bracketed level
/// or parameter. Matches the longest catalogue name that prefixes [label]
/// (Aspect names contain spaces, e.g. "Enhanced Save"), then reads the
/// trailing `(...)` as a level (`LV2`) or a parameter (anything else).
ResolvedAspect resolveAspect(String label) {
  final trimmed = label.trim();
  // Find the catalogue entry whose name prefixes the label (longest first).
  AspectDef? best;
  for (final a in kDbuAspects) {
    if ((trimmed == a.name || trimmed.startsWith('${a.name} ') ||
            trimmed.startsWith('${a.name}(')) &&
        (best == null || a.name.length > best.name.length)) {
      best = a;
    }
  }
  // Extract a trailing (…) bracket, if present.
  int? level;
  String? parameter;
  final open = trimmed.indexOf('(');
  if (open >= 0 && trimmed.endsWith(')')) {
    final inner = trimmed.substring(open + 1, trimmed.length - 1).trim();
    final lvMatch =
        RegExp(r'^(?:LV~?|Level\s*)(\d+)$', caseSensitive: false)
            .firstMatch(inner);
    if (lvMatch != null) {
      level = int.tryParse(lvMatch.group(1)!);
    } else if (inner.isNotEmpty) {
      parameter = inner;
    }
  }
  return ResolvedAspect(
    label: trimmed,
    def: best,
    level: level,
    parameter: parameter,
  );
}
