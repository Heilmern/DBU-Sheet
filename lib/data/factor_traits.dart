/// factor_traits.dart
/// ---------------------------------------------------------------------------
/// Racial Factors catalogue (Player → Races → Racial Factors pages),
/// verbatim from the site (confirmed 04 July 2026). Mirrors the shape of
/// `race_traits.dart` deliberately — a Factor Trait IS a Racial Trait once
/// applied (see `toRaceTraitDef`), it's just sourced from a Factor's page
/// instead of the character's Race page.
///
/// FRAMEWORK (racial-factors page, verbatim):
///   "A Racial Factor is a change that can be applied to a Race at Character
///   Creation ... that replaces a Secondary Racial Trait of your choice from
///   your Race with one of the Factor Traits listed by your selected Racial
///   Factor." / "you can only gain access to a Factor if you possess a
///   suitable Racial Trait (that is not a Factor Trait) to exchange for the
///   Factor Trait." / "Factor Traits are considered Racial Traits. They are
///   Primary or Secondary, depending on which type of Racial Trait they
///   replaced." / "Each Factor can be taken a number of times listed for
///   that Factor ... its 'Maximum Factor'." / "If a Factor Trait has a
///   Racial Trait listed in brackets, it means that it must replace that
///   specific Racial Trait. In instances of this, a Factor Trait may even
///   replace a Primary Racial Trait." / "Some Factor Traits can only be
///   selected by certain Races."
///
/// SCOPE: like `race_traits.dart`, references to other un-modeled catalogues
/// (Bestial Traits, Monstrous Traits, specific Unique Abilities/Talents/
/// Transformations/Enhancements) are kept as descriptive text rather than
/// built out as their own structured systems — those are large enough to be
/// their own future milestones.
library;

import 'dbu_rules.dart';
import 'race_traits.dart';

/// A single Trait granted by a Racial Factor. Structurally identical to a
/// Racial Trait's content (name/category/description/automation/options) —
/// see [toRaceTraitDef], which converts one into a genuine `RaceTraitDef` at
/// the moment it's swapped in, so every existing piece of machinery that
/// operates on Racial Traits (automation, granted Resources, Option
/// pickers, the Information page's Trait list) works on it unmodified.
class FactorTraitDef {
  const FactorTraitDef({
    required this.name,
    required this.category,
    required this.description,
    this.optionGroups = const [],
    this.automation = const [],
    this.grantedResources = const [],
    this.raceRestriction,
    this.excludedRaces = const [],
    this.mustReplaceTraitName,
    this.dependentChoice,
    this.beastGrants = const [],
  });

  final String name;
  final TraitCategory category;
  final String description;
  final List<RaceTraitOptionGroup> optionGroups;
  final List<RaceTraitAutomation> automation;
  final List<GrantedResource> grantedResources;

  /// Bestial/Monstrous Trait grants this Factor Trait provides — surfaced as
  /// inline pickers once the Factor Trait is applied (it becomes a
  /// `RaceTraitDef` via [toRaceTraitDef], carrying these through). See
  /// `BeastTraitGrant`.
  final List<BeastTraitGrant> beastGrants;

  /// CONFIRMED (verbatim, racial-factors page): "If a Factor Trait has a
  /// Racial Trait listed in brackets, it means that it must replace that
  /// specific Racial Trait. In instances of this, a Factor Trait may even
  /// replace a Primary Racial Trait." When set, this Factor Trait is only
  /// offered as a swap-in for the Racial Trait of this exact name
  /// (regardless of tier); when null, it follows the default rule (any
  /// Secondary Racial Trait of the player's choosing).
  final String? mustReplaceTraitName;

  /// A `[Choice]` effect on this Factor Trait whose actual text depends on
  /// an Option chosen for a different Trait — see `DependentChoice` (e.g.
  /// Disguised Shadow's Choice depends on Personified Dragon Ball's Option).
  final DependentChoice? dependentChoice;

  /// If set, ONLY a character of this Race may select this Factor Trait
  /// (e.g. Mutation's "Legendary Saiyan" — Saiyan only). Verbatim: "Some
  /// Factor Traits can only be selected by certain Races."
  final String? raceRestriction;

  /// Races that may NOT select this Factor Trait even though the parent
  /// Factor's Racial Requirement would otherwise allow them (used for
  /// Alternate Upbringing's "X-Raised" Traits — verbatim: "You cannot
  /// select a Factor Trait for Alternate Upbringing if your Race is in the
  /// name of that Factor Trait").
  final List<String> excludedRaces;

  bool get isAutomated => automation.isNotEmpty;

  bool isEligibleForRace(String race) =>
      (raceRestriction == null || raceRestriction == race) &&
      !excludedRaces.contains(race);

  /// Converts this Factor Trait into a genuine [RaceTraitDef], as it exists
  /// once applied to a character (CONFIRMED: "Factor Traits are considered
  /// Racial Traits"). [tier] is the tier of the Racial Trait it replaced
  /// (Primary or Secondary — Factor Traits inherit it), or
  /// [RaceTraitTier.secondary] if granted without replacing anything.
  RaceTraitDef toRaceTraitDef({
    required String race,
    RaceTraitTier tier = RaceTraitTier.secondary,
  }) {
    return RaceTraitDef(
      race: race,
      tier: tier,
      category: category,
      name: name,
      description: description,
      automation: automation,
      optionGroups: optionGroups,
      grantedResources: grantedResources,
      dependentChoice: dependentChoice,
      beastGrants: beastGrants,
    );
  }
}

/// A single Racial Factor (racial-factors page's catalogue, verified 04 July
/// 2026 against each Factor's own page).
class FactorDef {
  const FactorDef({
    required this.name,
    required this.description,
    required this.racialRequirementText,
    this.allowedRaces = const [],
    this.excludedRaces = const [],
    required this.maxFactor,
    required this.prerequisiteText,
    required this.traits,
  });

  final String name;

  /// Verbatim flavour text from the Factor's own page.
  final String description;

  /// Verbatim "Racial Requirement:" line, shown as-is for reference.
  final String racialRequirementText;

  /// Races eligible for this Factor. Empty = "Any" (subject to
  /// [excludedRaces]).
  final List<String> allowedRaces;

  /// Races excluded even under an "Any" Racial Requirement (e.g. Alternate
  /// Upbringing excludes Android/Bio Android).
  final List<String> excludedRaces;

  /// CONFIRMED (verbatim): "Each Factor can be taken a number of times
  /// listed for that Factor ... its 'Maximum Factor'." Most are 1.
  final int maxFactor;

  /// Verbatim "Prerequisite(s):" line — shown to the player as a reminder;
  /// not programmatically enforced (e.g. alignment/narrative prerequisites
  /// this app doesn't model as strict gates).
  final String prerequisiteText;

  final List<FactorTraitDef> traits;

  bool isEligibleForRace(String race) =>
      !excludedRaces.contains(race) &&
      (allowedRaces.isEmpty || allowedRaces.contains(race));
}

/// The full Racial Factors catalogue — all 9 Factors from the Player →
/// Races → Racial Factors section.
const List<FactorDef> kDbuFactors = [
  // ================================================ Alternate Upbringing ===
  FactorDef(
    name: 'Alternate Upbringing',
    description: 'The circumstances of your birth and early life are '
        "largely forgotten; instead, your parents- the ones who raised "
        "you, anyways- are of a different race than you. Perhaps you "
        "were born on one world and raised on another, or perhaps you "
        "were placed in the care of a trusted friend, but regardless, "
        "you've come to see the universe through another race's eyes.",
    racialRequirementText: 'Any (Except Android, Robot, or Bio-Android)',
    excludedRaces: ['Android', 'Bio Android'],
    maxFactor: 1,
    prerequisiteText:
        'This Factor Trait can only be gained at Character Creation. You '
        'cannot select a Factor Trait for Alternate Upbringing if your '
        'Race is in the name of that Factor Trait.',
    traits: [
      FactorTraitDef(
        name: 'Angel-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Angel'],
        description: 'Thanks to your upbringing at the hands of the '
            'divine, you allow your instincts to guide your survival in '
            'combat.\n'
            '(1)-[Passive]: While you possess no Counter Actions, '
            'increase your Defense Value by 1(T).\n'
            '(2)-[Passive]: While you possess no Counter Actions, '
            'increase the Dice Score for any Clash initiated by an '
            'Opponent that uses your Saving Throws by 1(T).\n'
            "(3)-[Triggered, 1/Round]: If you are targeted by an "
            "Opponent's Attacking Maneuver while you possess no Counter "
            "Actions, you may spend 3(bT) Ki Points to use the Defend "
            "Maneuver without spending a Counter Action.\n"
            '(4)-[Triggered/Start of Combat Round]: You may spend a '
            'Counter Action to use the Movement Maneuver or Power Up '
            'Maneuver as an Out-of-Sequence Maneuver.',
      ),
      FactorTraitDef(
        name: 'Arcosian-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Arcosian'],
        description: 'Under the tutelage of the brutal Arcosian race, '
            'you have learned to overwhelm enemies by targeting their '
            'weak points.\n'
            '(1)-[Triggered, 3/Round]: If you hit an Opponent with an '
            'Attacking Maneuver, increase your Wound Rolls by 1(T) '
            'until the end of your turn.\n'
            '(2)-[Triggered, 1/Round]: If you would use the Signature '
            'Technique Maneuver after triggering the first effect of '
            'Arcosian-Raised twice during this Combat Round, you may '
            'increase the Damage Category of that Attacking Maneuver by '
            '1 Category.',
      ),
      FactorTraitDef(
        name: 'Cerealian-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Cerealian'],
        description: 'Patiently taught by the Cerealian race, you '
            'understand the importance of waiting for your perfect '
            'moment to strike.\n'
            '(1)-[Passive]: Increase the Wound Rolls of your Called '
            'Shots and Exploit Maneuvers by 1(T).\n'
            '(2)-[Triggered, 1/Round]: If you hit an Opponent with a '
            'Called Shot and deal Damage, they gain a stack of the '
            'Broken Combat Condition until the start of your next '
            'turn.\n'
            "(3)-[Triggered, 1/Round]: If an Opponent would trigger "
            "your Exploit Maneuver, you may spend 3(bT) Ki Points to "
            "use the Exploit Maneuver without spending a Counter "
            "Action.",
      ),
      FactorTraitDef(
        name: 'Demon-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Demon'],
        description: 'Growing up with the sly cunning and trickery of '
            'Demons, you turn your experience with these tactics '
            'against your foes.\n'
            '(1)-[Passive]: Increase the Wound Rolls of your Attacking '
            'Maneuvers against Opponents suffering from a Combat '
            'Condition by 1(T).\n'
            '(2)-[Passive]: Increase the Dice Score of your Might '
            'Clashes against Opponents suffering from a Combat '
            'Condition by 1(T).\n'
            '(3)-[Triggered/Power, 1/Round]: Spend 3(bT) Ki Points to '
            'make a Might Clash against all Opponents within a Sphere '
            'AoE (centered on you). If you win, those Opponents gain '
            'the Impediment Combat Condition until the end of your '
            'turn.',
      ),
      FactorTraitDef(
        name: 'Earthling-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Earthling'],
        description: 'Under the skilled guidance of Earthlings, you '
            'have absorbed their tenacious tendency to adapt to any '
            'situation.\n'
            '(1)-[Passive]: Increase the amount of Technique Points '
            'you gain from Skill Improvement by 3.\n'
            '(2)-[Passive]: Reduce the Technique Point Cost to create '
            'a Signature Technique by 2 after all other calculations.\n'
            '(3)-[Triggered]: When you use the Signature Technique '
            'Maneuver, for this instance of using your chosen Signature '
            'Technique, you may either: apply an Energy Charge to that '
            'Attacking Maneuver, or add a single Advantage with a TP '
            'cost of up to 10 TP to your chosen Signature Technique.',
      ),
      FactorTraitDef(
        name: 'Glass Tribe-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Glass Tribe'],
        description: 'Carrying the legacy of the stoic, stalwart Glass '
            'Tribe, you have acclimatized to their mindset.\n'
            '(1)-[Passive]: Ignore any Health Threshold Penalties while '
            'in the Surging State.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(T) '
            'while in the Healthy Health Threshold.\n'
            '(3)-[Triggered, 1/Round]: If you use an Attacking '
            'Maneuver, you can enter the Surging State for the '
            'duration of that Attacking Maneuver. If you trigger this '
            'effect while you are not suffering from any Health '
            'Threshold Penalties, do not apply the 2nd effect of the '
            'Surging State upon leaving the Surging State entered '
            'through this effect.',
      ),
      FactorTraitDef(
        name: 'Heran-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Heran'],
        description: 'Brought up by the cutthroat conquerors from '
            'Planet Hera, you have incorporated their reckless '
            'teamwork tactics into your repertoire.\n'
            '(1)-[Passive]: Increase the Strike and Wound Rolls of '
            'your Attacking Maneuvers that target an Opponent who has '
            'at least one of your Allies on a Square adjacent to them '
            'by 1(T).\n'
            '(2)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver while there is an Ally adjacent to '
            'that Opponent, that Ally may use the Movement Maneuver as '
            'an Out-of-Sequence Maneuver. If they do, that movement '
            'does not trigger the Exploit Maneuver from the hit '
            'Opponent.\n'
            '(3)-[Triggered, 1/Round]: If you knock an Opponent '
            'through a Health Threshold with an Attacking Maneuver, '
            'you may target one adjacent Ally. That Ally may use the '
            'Basic Attack Maneuver as an Out-of-Sequence Maneuver, but '
            'they must target that Opponent with the Attacking '
            'Maneuver.',
      ),
      FactorTraitDef(
        name: 'Konatsian-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Konatsian'],
        description: 'Reared under the watchful eye of the wise '
            'Konatsian race, you have specialized in a single combat '
            'role.\n'
            "(1)-[Passive]: Upon gaining this Factor, select a "
            "Vocation to gain access to.\n"
            '(2)-[Triggered, Resource]: If an Ally (except a Minion) '
            'is Defeated, gain a stack of Inherited Tension (max. 3). '
            'Inherited Tension can be spent as if it was Tension for '
            'the effects of a Vocation.\n'
            '(3)-[Triggered/Start of Turn]: If you are below the '
            'Injured Health Threshold, gain a stack of Inherited '
            'Tension.',
        grantedResources: [
          GrantedResource(
            name: 'Inherited Tension',
            maxStacks: 3,
            description: 'Gained on an Ally being Defeated, or at the '
                'start of your turn while below Injured; spend as if '
                'it were Tension for your Vocation.',
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Majin-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Majin'],
        description: 'Influenced by the chaotic and unpredictable '
            'Majins, your high-energy, off-kilter smile sets off '
            'mental alarms for all who encounter you.\n'
            '(1)-[Passive]: Upon gaining this Factor Trait, select a '
            'Skill that uses Personality as its Attribute. You gain a '
            'Skill Rank in the Skill selected for this effect.\n'
            '(2)-[Passive]: Increase your Surgency by 2(T).\n'
            '(3)-[Passive]: Reduce the TP Cost of all Magical Unique '
            'Abilities by 2.\n'
            '(4)-[Triggered, 1/Round]: If you fail to hit an Opponent '
            'with an Attacking Maneuver, make a Clash (Bluff vs '
            'Perception/Intuition) against that Opponent. If you win, '
            'you may use the Basic Attack Maneuver against that '
            'Opponent as an Out-of-Sequence Maneuver.',
        automation: [
          // (2) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Namekian-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Namekian'],
        description: 'Living in a peaceful environment raising Ajisa '
            'trees with the Namekians, you practiced patience, '
            'analysis, and keeping a cool head under pressure.\n'
            '(1)-[Passive]: Upon gaining this Factor Trait, select a '
            'Skill that uses Insight as its Attribute. You gain a '
            'Skill Rank in the Skill selected for this effect.\n'
            '(2)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(3)-[Passive]: Reduce the TP Cost of all Magical Unique '
            'Abilities by 2.\n'
            '(4)-[Triggered/Start of Combat Round]: Select an '
            'Opponent. Increase your Combat Rolls against the selected '
            'Opponent by 1(T) until the end of the Combat Round.',
        automation: [
          // (2) +2 Racial Life Modifier = +2 Max Life per Power Level.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.maxLife],
            coefficient: 2,
            kind: TraitMagnitudeKind.perPowerLevel,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Neko Majin-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Neko Majin'],
        description: 'Imbued with the whimsical mysticism and '
            'mischievous mimicry of the Neko Majin race, you snatch '
            'the techniques of everyone around you.\n'
            '(1)-[Passive]: At Character Creation, gain the Quick '
            'Learner Talent.\n'
            "(2)-[Passive]: You may ignore the effects of any "
            "Disadvantage with 'Restricted' in its name on any "
            "Signature Technique or Aura you have gained through the "
            "effects of Quick Learner.\n"
            '(3)-[Triggered, 1/Round]: If you use a Copied Technique, '
            'increase the Wound Roll of that Attacking Maneuver by '
            '2(T).\n'
            '(4)-[Triggered, 1/Round]: If you gain access to a Copied '
            'Technique, regain Ki Points equal to the Ki Point Cost of '
            'that Copied Technique.',
      ),
      FactorTraitDef(
        name: 'Neo-Tuffle-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Neo-Tuffle'],
        description: 'Mentored by the spiteful, vengeful Neo-Tuffles, '
            'you channel their seething hatred against your enemies.\n'
            '(1)-[Triggered/Start of Combat Round]: Select an '
            'Opponent. Increase your Combat Rolls against the selected '
            'Opponent by 1(T) until the end of the Combat Round.\n'
            '(2)-[Triggered, 1/Encounter]: Upon applying the first '
            'effect of Neo-Tuffle-Raised, if you are below the Injured '
            'Health Threshold, you may enter the Surging State until '
            'the end of the Combat Round. If you do, for the effects '
            'of the Surging State, you must select the same Opponent '
            'as the Opponent selected for the first effect of this '
            'Trait.\n'
            '(3)-[Triggered, 1/Round]: If you use the Signature '
            'Technique Maneuver, you may apply Greater Dice to the '
            'Wound Roll of that Signature Technique.',
      ),
      FactorTraitDef(
        name: 'Saiyan-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Saiyan'],
        description: 'Trained relentlessly by the proud warrior '
            'Saiyans, you have earned your right to call yourself a '
            'warrior.\n'
            '(1)-[Passive]: Increase your Wound Rolls and Surgency by '
            '1(T) for every Health Threshold you are below.\n'
            '(2)-[Passive]: While you are below the Injured Health '
            'Threshold, increase your Soak Value by 1(T).\n'
            '(3)-[Passive]: Ignore all Health Threshold Penalties '
            'while in the Superior State.\n'
            "(4)-[Triggered, 1/Encounter]: If you take Damage from an "
            "Opponent's Attacking Maneuver, you may use the Basic "
            "Attack Maneuver as an Out-of-Sequence Maneuver. If you "
            "do, you are in the Superior State for the duration of "
            "this Attacking Maneuver.\n"
            '(5)-[Triggered/Power, 1/Encounter]: If you are below the '
            'Injured Health Threshold, enter the Superior State until '
            'the end of your next turn.',
      ),
      FactorTraitDef(
        name: 'Shadow Dragon-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Shadow Dragon'],
        description: 'Surrounded from an early age by the '
            'reality-warping tricks of the Shadow Dragons, you have '
            'taken some of that power for yourself and made it your '
            'own.\n'
            '(1)-[Triggered]: If you or an Opponent (who is not at '
            'Long Range) scores a Botch Result on a Combat Roll, '
            'regain 2(bT) Ki Points.\n'
            '(2)-[Triggered, 1/Round]: If an Opponent within your '
            'Melee Range scores a Botch Result, this triggers your '
            'Exploit Maneuver.\n'
            '(3)-[Triggered/Power, 1/Round]: Spend 3(bT) Ki Points to '
            'make a Might Clash against all Opponents within a Sphere '
            'AoE (centered on you). If you win, those Opponents gain '
            'the Impaired Combat Condition until the start of your '
            'next turn.',
      ),
      FactorTraitDef(
        name: 'Shinjin-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Shinjin'],
        description: 'Under the shelter of the poised and pragmatic '
            'Shinjin race, you have grown adept at waiting out your '
            "opponents and turning their own power against them.\n"
            '(1)-[Passive]: You can sense God Ki.\n'
            '(2)-[Triggered]: Increase your Combat Rolls and Soak '
            'Value by 1(T) for the duration of any of your Counter '
            'Maneuvers.\n'
            '(3)-[Triggered]: At the end of the Combat Round, regain '
            '2(bT) Life and Ki Points for each Counter Action you '
            'possess.\n'
            '(4)-[Triggered/Start of Combat Round]: You may spend 1 '
            'Action to gain 2 Counter Actions.',
      ),
      FactorTraitDef(
        name: 'Yardrat-Raised',
        category: TraitCategory.mind,
        excludedRaces: ['Yardrat'],
        description: 'Enlightened by the calm, collected Yardrats, '
            'you possess spiritual depth that others of your race '
            'cannot fathom.\n'
            '(1)-[Passive]: At Character Creation, gain a stack of '
            'Spirit Control. This stack of Spirit Control does not '
            'count towards your Awakening Limit, and you do not gain '
            'the Attribute Modifier Bonus from this stack of Spirit '
            'Control.\n'
            '(2)-[Passive]: At Character Creation, you may apply the '
            'Yardrat Material Special Apparel Quality as if it was a '
            'normal Apparel Quality through creating a Gear Kit.\n'
            '(3)-[Passive]: Reduce the TP Cost of all Unique Abilities '
            'by 2.\n'
            '(4)-[Passive]: Treat your uses of the Empower Maneuver as '
            'if you spent 1 Action more than you actually did for its '
            'effects.\n'
            '(5)-[Triggered, 1/Encounter]: If an Ally gains Ki Points '
            'through your use of the Empower Maneuver, they may regain '
            'Life Points equal to 1/2 of the Ki Points regained.',
      ),
      FactorTraitDef(
        name: 'Other-Raised',
        category: TraitCategory.mind,
        description: 'Cared for by one of the myriad alien species in '
            'the universe, you have steeped in their culture, '
            'traditions, and mindset to become the person you are now.\n'
            '(1)-[Passive]: Select a Race created through Custom '
            'Species. Gain access to a Custom Species Racial Trait of '
            'the Mind-Category possessed by that Race (you do not '
            'gain any Twinned effects). You cannot trade this Racial '
            'Trait out for a Factor Trait.',
      ),
      FactorTraitDef(
        name: 'Wild Child',
        category: TraitCategory.mind,
        description: 'Fending for yourself in the wilds with only the '
            'most savage of beasts to guide you, you have attuned '
            'yourself to nature.\n'
            '(1)-[Prerequisite]: You cannot take this Factor Trait if '
            'you possess the Beast-Man Factor. If you gain the '
            'Beast-Man Factor, you lose this Factor Trait and regain '
            'the Secondary Trait you exchanged for it.\n'
            '(2)-[Passive]: You may use Signature Techniques while in '
            'the Feral State.\n'
            "(3)-[Passive, Ruling]: Upon gaining this Factor Trait, "
            "select 2 'Pseudo-Bestial Traits' (a curated list of "
            "9 nature-mimicry effects on the site — Mimicry of Bestial "
            "Hunger/Movement/Resilience/Senses, Flailing Limbs, "
            "Penetrating Fangs, Rending Claws, the Whipping Tail — not "
            "catalogued individually here; not modeled in this app).\n"
            '(4)-[Triggered/Power, 2/Round, Adventurous]: Gain access '
            'to 1 of your selected Pseudo-Bestial Traits until the '
            'start of your next turn.\n'
            '(5)-[Triggered/Power, 1/Encounter]: Enter the Feral State '
            'until the end of your next turn. If you are already in '
            'the Feral State, you may enter the Superior State until '
            'the start of your next turn or gain access to 2 of your '
            'selected Pseudo-Bestial Traits until the start of your '
            'next turn.',
      ),
      FactorTraitDef(
        name: 'Zooner-Raised',
        category: TraitCategory.mind,
        description: 'Instructed by the illustrious and arrogant '
            "peoples of Zoon, your marksmanship is excellent, though "
            "you're often wide open to counterattack.\n"
            '(1)-[Passive]: While in the Healthy Health Threshold, '
            'increase the Wound Rolls of your Signature Techniques by '
            '2(T).\n'
            '(2)-[Passive]: While below the Injured Health Threshold, '
            'reduce your Combat Rolls and Soak Value by 1(bT).\n'
            '(3)-[Triggered, 1/Round]: If your Signature Technique '
            'becomes a Called Shot, you ignore the Strike Roll penalty '
            'from that Attacking Maneuver being a Called Shot. If you '
            'do, after concluding that Attacking Maneuver, reduce your '
            'Awareness, Defense Value, and Soak Value by 1(bT) until '
            'the start of your next turn.\n'
            '(4)-[Triggered, 1/Round]: If you use the Signature '
            'Technique Maneuver, gain an Energy Charge on that '
            'Attacking Maneuver. If you do, after concluding that '
            'Attacking Maneuver, reduce your Awareness, Defense Value, '
            'and Soak Value by 1(bT) until the start of your next '
            'turn.',
      ),
    ],
  ),

  // ============================================================ Beast-Man ===
  FactorDef(
    name: 'Beast-Man',
    description: "You're not a monster, you're a Beast-Man! Half-man, "
        "half-animal, you're your own best friend… or worst nightmare. "
        "Whether you possess your furry features at all times, or "
        "transform into a rampaging beast in the light of the full "
        "moon, one thing is certain: the beast is on the prowl.",
    racialRequirementText:
        'Android, Bio-Android, Custom Species, Demon, Earthling',
    allowedRaces: ['Android', 'Bio Android', 'Custom Species', 'Demon', 'Earthling'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Part Beast',
        category: TraitCategory.body,
        description: 'These unique souls are anthropomorphic animals, '
            'capable of combining their bestial features with the '
            'benefits of a humanoid body, creating a powerful fighter '
            'with the best of both worlds.\n'
            '(1)-[Passive]: Select and gain two Bestial Traits.\n'
            '(2)-[Passive]: Increase the Dice Score of your Perception '
            'Skill Checks by 2 and reduce the Critical Target of your '
            'Strike and Dodge Rolls by 1.',
        beastGrants: [
          BeastTraitGrant(kind: BeastTraitKind.bestial, count: 2),
        ],
      ),
      FactorTraitDef(
        name: 'Were-Beast',
        category: TraitCategory.body,
        description: 'Awakening their bestial side under some arcane '
            'condition known only to them, these unfortunate souls '
            'turn into animals.\n'
            "(1)-[Ruling]: Upon gaining this Factor Trait, select 2 "
            "Bestial Traits. These are known as your 'Were-Traits'. "
            "When you select your Were-Traits, any Option effects or "
            "choices made for their effects are decided then and "
            "remain as such when you gain access to them.\n"
            '(2)-[Ruling]: Upon gaining this Factor Trait, the '
            'Secondary Racial Trait you exchanged for this Factor '
            "Trait becomes known as your 'Normal Trait'. Any Option "
            'effects or choices made for the effects of your Normal '
            'Trait are decided upon gaining this Factor Trait and '
            'remain as such when you regain access to it.\n'
            "(3)-[Addendum]: A 'Trigger' — a narrative device such as "
            'the moon\'s presence — must be agreed with your ARC; '
            "without it present you cannot use the 4th effect's "
            "Were-Traits option, and with it present you cannot use "
            "that effect's Normal Trait option. If you possess a "
            'Trigger, your Racial Life Modifier is increased by 2.\n'
            '(4)-[Triggered/Start of Combat Round]: You may choose to '
            'either regain access to your Normal Trait until the end '
            'of the Combat Round, OR gain access to your Were-Traits '
            'until the end of this Combat Round.',
        beastGrants: [
          // (1) Select 2 Bestial Traits (your "Were-Traits").
          BeastTraitGrant(
            kind: BeastTraitKind.bestial,
            count: 2,
            label: 'Were-Traits — select 2 Bestial Traits',
          ),
        ],
      ),
    ],
  ),

  // ================================================ Cybernetic Enhancement ===
  FactorDef(
    name: 'Cybernetic Enhancement',
    description: 'We can rebuild you. We have the technology. We can '
        'make you stronger, faster, better than you were before. All '
        'you have to do… is nearly die. It happens more often than you '
        'realize— someone loses a limb, or nearly dies, and thanks to '
        'the advances of medical science, they are restored to full '
        'health, and they\'re somehow… improved for it.',
    racialRequirementText: 'Any',
    maxFactor: 3,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Armor Plating',
        category: TraitCategory.body,
        description: 'Your skin has been reinforced against damage, '
            'allowing you to withstand stronger hits.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(bT).\n'
            '(3)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver, reduce the Damage Category of that Attacking '
            'Maneuver by 1 Category.',
      ),
      FactorTraitDef(
        name: 'Cloaking System',
        category: TraitCategory.body,
        description: "You have the ability to slip past your "
            "enemies' notice.\n"
            '(1)-[Passive]: Increase the Natural Result of your '
            'Stealth Skill Checks by 1.\n'
            '(2)-[Passive]: Increase your Wound Rolls by 2(T) against '
            'your Oblivious Character(s).\n'
            '(3)-[1/Round]: As a Standard Maneuver with an Action Cost '
            'of 1 and a Ki Point Cost of 10(bT), enter the Invisible '
            'State.\n'
            '(4)-[1/Round]: As an Instant Maneuver during your turn, '
            'or in response to the end of your turn, leave the '
            'Invisible State.\n'
            '(5)-[Automatic/Start of Turn]: If you are in the '
            'Invisible State due to the 3rd effect of Cloaking System, '
            'reduce your Ki Points and Capacity by 8(bT).',
      ),
      FactorTraitDef(
        name: 'Emergency Energy Supplies',
        category: TraitCategory.body,
        description: 'Your reserve power core makes it easier for you '
            'to recover your stamina and stay in the fight.\n'
            '(1)-[Passive]: Increase your Surgency by 3(bT).\n'
            '(2)-[Passive]: You may use the Surge Maneuver an '
            'additional time per Combat Encounter.\n'
            '(3)-[Triggered, 1/Encounter]: If you use a Surge, you may '
            'use the Power Up Maneuver as an Out-of-Sequence Maneuver.',
        automation: [
          // (1) +3(bT) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 3,
            tierScaling: TierScaling.base,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Integrated Weapon',
        category: TraitCategory.body,
        description: 'A powerful weapon has been included in your '
            'cybernetic augmentations.\n'
            '(1)-[Passive]: When you gain this Factor Trait, create a '
            'Weapon of Craftsmanship Grade 4 and Integrate it. This '
            'Weapon additionally has the Regenerating Quality. This '
            'Quality does not occupy any Quality Slots.\n'
            '(2)-[Passive]: Increase the Wound Rolls of any Attacking '
            'Maneuvers made with an Integrated Weapon by 2(T).',
      ),
      FactorTraitDef(
        name: 'Life Support',
        category: TraitCategory.body,
        description: 'Your body is kept alive by machinery, rendering '
            'you far more durable than before.\n'
            '(1)-[Passive]: You are Unnatural.\n'
            '(2)-[Passive]: Increase your Racial Life Modifier by 4.\n'
            '(3)-[Passive]: Increase your Soak Value and Surgency by '
            '1(T) and 2(T) respectively.',
      ),
      FactorTraitDef(
        name: 'Mental Supercomputer',
        category: TraitCategory.body,
        description: 'Your inbuilt hardware is capable of running '
            'calculations at speeds well above and beyond your natural '
            'capabilities.\n'
            '(1)-[Passive]: Increase your Scholarship and Personality '
            'Modifiers by 1(T) while you have 2+ stacks of Power.\n'
            '(2)-[Triggered, 1/Round]: When you use the Analysis or '
            'Hype Maneuver, increase your Strike and Wound Rolls by '
            '1(T) and 2(T) respectively until the end of your turn.\n'
            '(3)-[Triggered, 1/Round]: When you use the Command '
            'Maneuver, each targeted Minion has their Combat Rolls '
            'increased by 1(T) for the duration of their turn.\n'
            '(4)-[Triggered/Start of Turn, 1/Encounter]: Use the Power '
            'Up Maneuver as an Out-of-Sequence Maneuver. If you do, '
            'gain an additional Power stack from this use of the '
            'Power Up Maneuver.',
      ),
      FactorTraitDef(
        name: 'Metallic Exoskeleton',
        category: TraitCategory.body,
        description: 'You have covered your body in a protective '
            'metal skin, ensuring your internal organs are safe from '
            'external damage.\n'
            "(1)-[Passive, Ruling]: Upon gaining this Trait, gain a "
            "'Metal Exoskeleton' while you possess this Trait. Your "
            "Metal Exoskeleton is Natural Armor.\n"
            '(2)-[Triggered, 1/Round]: If you use the Direct Hit or '
            'Guard options of the Defend Maneuver, you may increase '
            "your Soak Value (before any calculations) by your Metal "
            "Exoskeleton's Apparel Bonus for the duration of that "
            "Maneuver.",
      ),
      FactorTraitDef(
        name: 'Nanomachine Repair',
        category: TraitCategory.body,
        description: 'With nanites in your bloodstream constantly '
            'working to heal your wounds, you regenerate at an '
            'astonishing rate.\n'
            '(1)-[Triggered/Start of Combat Round]: Regain 3(bT) Life '
            'Points. Increase this amount by 1(bT) for every Health '
            'Threshold you are below.\n'
            '(2)-[Triggered/Defeated]: Halve your Ki Points. When the '
            'Initiative Order comes to your next turn, regain Life '
            'Points equal to the Ki Points lost and stop being '
            'Defeated.',
      ),
      FactorTraitDef(
        name: 'Onboard Computer',
        category: TraitCategory.body,
        description: 'You have the ability to track targets with the '
            'computer built into your augments.\n'
            '(1)-[Passive]: Integrate a Scouter with a Craft DC of '
            'Master.\n'
            '(2)-[Passive]: Increase the Dice Score of your Perception '
            'and Clairvoyance Skill Checks by 2.\n'
            '(3)-[Triggered/Start of Combat Round]: Target an '
            'Opponent. Increase either your Strike or Dodge Rolls '
            'against them by 2(T) for the duration of this Combat '
            'Round.',
      ),
      FactorTraitDef(
        name: 'Robotic Limb',
        category: TraitCategory.body,
        description: 'An extra limb has been added to your body '
            'beyond that of your original anatomy, and you have the '
            'ability to use it in battle.\n'
            '(1)-[Passive]: Increase your Strike Rolls when using the '
            'Parry effect of the Defend Maneuver by 1(T).\n'
            '(2)-[Passive]: Increase your Wound Rolls for Attacking '
            'Maneuvers of the Physical Foundation by 1(T).\n'
            '(3)-[Passive]: Gain access to the Tail Attack Maneuver.',
      ),
      FactorTraitDef(
        name: 'Rocket Sleeves',
        category: TraitCategory.body,
        description: 'You have the ability to move faster, farther, '
            'and more nimbly while expending less energy.\n'
            '(1)-[Passive]: When using the Movement Maneuver, you may '
            'move up to your Boosted Speed without increasing the KP '
            'Cost of the Maneuver.\n'
            '(2)-[Passive]: Increase your Boosted Speed by 2(T).\n'
            '(3)-[Triggered, 1/Round]: If you use the Movement '
            'Maneuver to move a number of Squares up to your Boosted '
            'Speed, increase your Wound Rolls by 3(T) until the end of '
            'your turn and increase your Dodge Rolls by 1(T) until '
            'the start of your next turn.',
      ),
      FactorTraitDef(
        name: 'Signature Amplifier',
        category: TraitCategory.body,
        description: 'Your attacks are imbued with extra force thanks '
            'to your machine upgrades.\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of all of your '
            'Signature Techniques by 2(T).\n'
            '(2)-[Passive]: All of your Ultimate Signature Techniques '
            'of the Physical or Energy Foundation gain a rank of Power '
            'Shot.\n'
            '(3)-[Triggered, 1/Round]: If you use the Signature '
            'Technique Maneuver to use an Attacking Maneuver of the '
            'Physical or Energy Foundation, you may apply an Energy '
            'Charge to that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Synthetic Muscle',
        category: TraitCategory.body,
        description: 'Replacing your organic muscles with artificial '
            "ones, you've enhanced your strength significantly.\n"
            '(1)-[Passive]: You cannot possess any number of Super '
            'Stacks.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(T) and '
            'apply your Greater Dice to the Wound Rolls of your '
            'Attacking Maneuvers of the Physical or Energy Foundation.\n'
            '(3)-[Triggered, 1/Round]: If you hit an Opponent with an '
            'Attacking Maneuver of the Physical or Energy Foundation, '
            'you may spend 2(bT) Ki Points to apply your Greater Dice '
            'to the Wound Roll of that Attacking Maneuver an '
            'additional time.',
      ),
    ],
  ),

  // ===================================================== Demon Clansman ===
  FactorDef(
    name: 'Demon Clansman',
    description: 'Though not necessarily a demon by blood, the '
        'darkness of demonic evil fills your heart and flows through '
        'your veins, transforming you into a demon yourself.',
    racialRequirementText: 'Any',
    maxFactor: 1,
    prerequisiteText: 'To obtain this Factor, a Character must be Pure '
        "Evil. If a Character with this Factor's alignment turns to "
        'Good or Pure Good, they lose this Factor and regain the '
        "Racial Trait they exchanged for this Factor's Factor Trait.",
    traits: [
      FactorTraitDef(
        name: 'Heart of Evil',
        category: TraitCategory.mind,
        description: 'The pure darkness of demonic evil has awakened '
            'inside you, unlocking new powers.\n'
            '(1)-[Passive]: Increase your Wound Rolls and Might '
            'Clashes against Opponents suffering from a Combat '
            'Condition by 1(T).\n'
            '(2)-[Triggered]: If an Opponent within a Large Sphere AoE '
            '(centered on you) makes a Stress Test or Steadfast Check '
            'while suffering from a Combat Condition, you may spend up '
            'to 6(bT) Ki Points. For every 3(bT) Ki Points spent, '
            'reduce the Dice Score of their roll by 1.\n'
            '(3)-[Triggered, 1/Round]: If you knock an Opponent '
            'through a Health Threshold with an Attacking Maneuver, '
            'make a Might Clash against them. If you win, you may '
            'apply one of the following to that Opponent: a stack of '
            'Broken until the end of your next turn; a stack of '
            'Impaired until the end of your next turn; or Shaken until '
            'the start of your next turn.\n'
            '(4)-[Option]: Upon gaining this Factor Trait, choose one '
            'of the following effects (some have a Race listed in '
            'brackets — you may only choose that effect if your Race '
            'matches the listed Race):',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Sadistic Demon Lord',
                description: '[Triggered, 1/Round]: If you inflict a '
                    'Combat Condition upon an Opponent or Defeat an '
                    'Opponent, regain Ki Points equal to your Might.',
              ),
              TraitOption(
                name: 'Resilient Demon Lord',
                description: '[Triggered]: If you are targeted by an '
                    'Attacking Maneuver from an Opponent with a Combat '
                    'Condition, increase your Soak Value and Damage '
                    'Reduction by 1(T) for the duration of that '
                    'Attacking Maneuver.',
              ),
              TraitOption(
                name: 'Evil Saiyan of Legend (Saiyan only)',
                description: '[Passive]: You gain access to the Evil '
                    'Saiyan Enhancement. Additionally, reduce the '
                    'Stress Test Requirement for Evil Saiyan by 3 and '
                    'it gains the Natural (LV2) Aspect.',
              ),
              TraitOption(
                name: 'Demonic Skills (Namekian only)',
                description: '[Triggered]: If you Defeat a Studied '
                    'Opponent or knock them through a Health '
                    'Threshold, regain Ki Points equal to your '
                    'Surgency.',
              ),
              TraitOption(
                name: 'Demonic God (Shinjin only)',
                description: '[1/Round]: As an Instant Maneuver, you '
                    'may spend a Counter Action to use the Basic '
                    'Attack Maneuver, Signature Technique Maneuver, or '
                    'a Unique Ability with an Action Cost of 1 Action '
                    'as an Out-of-Sequence Maneuver.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ============================================================= Monster ===
  FactorDef(
    name: 'Monster',
    description: 'Whether due to circumstances or lineage, you are a '
        'monstrously misunderstood creature. Your preternatural '
        'nature creates an uncanny image in the minds of others.',
    racialRequirementText: 'Earthling or Demon',
    allowedRaces: ['Earthling', 'Demon'],
    maxFactor: 1,
    prerequisiteText: "You are not Unnatural before applying the "
        "effects of any of Monster's Factor Traits.",
    traits: [
      FactorTraitDef(
        name: 'Custom Monstrosity',
        category: TraitCategory.body,
        description: 'You are a horror to behold unlike any the world '
            'has known before you.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Upon gaining this Factor Trait, select a '
            'Combat Roll or Soak Value. Increase your choice by 1(T).\n'
            '(3)-[Passive]: You gain access to 1 Monstrous Trait and 1 '
            'Bestial Trait.',
        beastGrants: [
          BeastTraitGrant(kind: BeastTraitKind.monstrous),
          BeastTraitGrant(kind: BeastTraitKind.bestial),
        ],
      ),
      FactorTraitDef(
        name: 'Devil',
        category: TraitCategory.body,
        description: 'From the depths of HFIL, your darkness spreads '
            'as you manifest in the land of the living.\n'
            '(1)-[Passive]: You gain access to the Winged Beast '
            'Bestial Traits and the Unique Monstrosity Monstrous '
            'Trait.\n'
            '(2)-[Passive]: You gain access to the Magical '
            'Materialization Unique Ability.\n'
            '(3)-[Passive]: For the Unique Monstrosity Monstrous '
            'Trait, you may select any Unique Ability regardless of '
            'the TP Cost (follow the usual restrictions for Unique '
            'Monstrosity).',
        beastGrants: [
          BeastTraitGrant(
            kind: BeastTraitKind.bestial,
            count: 0,
            fixed: ['Winged Beast'],
          ),
          BeastTraitGrant(
            kind: BeastTraitKind.monstrous,
            count: 0,
            fixed: ['Unique Monstrosity'],
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Fairy',
        category: TraitCategory.body,
        description: 'A spirit of nature, your pointed ears and '
            'gossamer wings mark you as a powerful trickster.\n'
            '(1)-[Passive]: Upon gaining this Factor Trait, select a '
            'Size Category (Nano/Tiny/Small). That becomes your base '
            'Size Category.\n'
            '(2)-[Passive]: Upon gaining this Factor Trait, gain a '
            'Skill Improvement.\n'
            '(3)-[Passive]: You gain access to the Winged Beast '
            'Bestial Trait.\n'
            '(4)-[Passive]: You gain access to the Unique Monstrosity '
            'Monstrous Trait.\n'
            '(5)-[Triggered, 1/Round]: If you make a Skill Clash, '
            'increase the Dice Score of that Clash by 2.\n'
            '(6)-[Triggered, 1/Round]: If you make a Clash that uses '
            'your Saving Throws, increase the Dice Score of that Clash '
            'by 1(T).',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.bestial, count: 0, fixed: ['Winged Beast']),
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous,
              count: 0,
              fixed: ['Unique Monstrosity']),
        ],
      ),
      FactorTraitDef(
        name: 'Genie',
        category: TraitCategory.body,
        description: 'Your magical, mystical nature allows you the '
            'uncanny use of preternatural powers and the ability to '
            'survive hits that would incinerate lesser beings.\n'
            '(1)-[Passive]: You may use your Magic Modifier instead of '
            'your Force Modifier when calculating Surgency.\n'
            '(2)-[Passive]: You gain access to the Unique Monstrosity '
            'Monstrous Trait.\n'
            '(3)-[Passive]: Increase your Damage Reduction by 1/2 of '
            'your Insight Modifier.\n'
            "(4)-[Triggered, 1/Round]: If you receive no Damage from "
            "an Opponent's Attacking Maneuver that targeted you due "
            "to any means, you may use a Surge as an Out-of-Sequence "
            "Maneuver but only apply 1/4 (rounded up) of your "
            "Surgency.",
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous,
              count: 0,
              fixed: ['Unique Monstrosity']),
        ],
      ),
      FactorTraitDef(
        name: 'Ghost',
        category: TraitCategory.body,
        description: 'From beyond the veil, you haunt the living, '
            'clinging to the life you lost.\n'
            '(1)-[Passive]: You are Unnatural.\n'
            '(2)-[Passive]: You gain access to the Soar Maneuver. If '
            'you already have access to the Soar Maneuver, gain '
            'access to the Frequent Flyer Talent.\n'
            '(3)-[Passive]: You gain access to the Spectral Monster '
            'Monstrous Trait.\n'
            '(4)-[Passive]: Reduce the Damage Category of all '
            'Physical or Energy Attacks that hit you to Standard (for '
            'your Damage Calculation), but increase the Damage '
            'Category of all Magic Attacks that hit you by 1 Category '
            '(for your Damage Calculation).\n'
            '(5)-[Triggered/Incorporeal, 1/Encounter]: Use a Healing '
            'Surge as an Out-of-Sequence Maneuver.',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous,
              count: 0,
              fixed: ['Spectral Monster']),
        ],
      ),
      FactorTraitDef(
        name: 'Goblin',
        category: TraitCategory.body,
        description: 'Small but sturdy, you are more of a pest than '
            'threat, but notoriously hard to kill.\n'
            '(1)-[Passive]: Your base Size Category is Small, but '
            'while your Size Category is smaller than Large, you may '
            'use the Large Size Category to calculate your Soak Value '
            'Bonus/Penalty for your Size Category.\n'
            '(2)-[Passive]: You gain access to the Unrelenting '
            'Monstrous Trait.\n'
            '(3)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver while below the Injured Health Threshold, you '
            'may choose to reduce your Life Points to their lowest '
            'possible value instead of receiving Damage from that '
            'Attacking Maneuver. If you do, and trigger the 3rd effect '
            'of Unrelenting, double your Surgency for the duration of '
            'the Healing Surge used through its effects.',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous,
              count: 0,
              fixed: ['Unrelenting']),
        ],
      ),
      FactorTraitDef(
        name: 'Mummy',
        category: TraitCategory.body,
        description: 'Wrapped in bandages and returned from death, '
            'you are a walking corpse ready to take your revenge on '
            'the living for disturbing your eternal slumber.\n'
            '(1)-[Passive]: You are Unnatural.\n'
            '(2)-[Passive]: Increase your Damage Reduction and '
            'Surgency by 2(bT).\n'
            '(3)-[Passive]: You gain access to the Extending Attack '
            'Monstrous Trait.\n'
            '(4)-[Triggered/Defeated]: Make a Steadfast Check. If you '
            'succeed, enter the Undying State until the end of your '
            'next turn.',
        beastGrants: [
          BeastTraitGrant(
            kind: BeastTraitKind.monstrous,
            count: 0,
            fixed: ['Extension Attack'],
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Plant Monster',
        category: TraitCategory.body,
        description: 'As some kind of monstrous, sapient plant '
            'creature, you are able to uproot yourself and ambulate '
            'across the battlefield, and many foes fear becoming your '
            'next source of fertilizer.\n'
            '(1)-[Passive]: You gain access to the Arboreal Bestial '
            'Trait.\n'
            '(2)-[Passive]: You gain access to the Elemental Assault '
            'Monstrous Trait. You must select the Elemental '
            '(Plantlife) Profile for the 1st effect of Elemental '
            'Assault and the Counter Elemental for the 2nd effect of '
            'Elemental Assault.\n'
            '(3)-[Passive]: While you are Rooted, increase your '
            'Surgency by 2(bT).\n'
            '(4)-[Passive]: While you are not Rooted, increase your '
            'Defense Value and Speeds by 1(T) and 2(bT) respectively.\n'
            '(5)-[Triggered]: When making any type of Physical '
            'Attacking Maneuver or Grapple Maneuver, you may increase '
            'your Melee Range by 3 Squares for the duration of that '
            'Maneuver.\n'
            '(6)-[Triggered]: If you use an Attacking Maneuver, you '
            'may spend a stack of Sunlight to apply the Multi-Profile '
            'Super Profile to that attacking Maneuver. If you do, you '
            'must select the Elemental (Plantlife) Profile for the '
            'effects of Multi-Profile.\n'
            '(7)-[Triggered, 1/Encounter]: If you gain a stack of '
            'Sunlight, gain a stack of Sunlight.',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.bestial, count: 0, fixed: ['Arboreal']),
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous,
              count: 0,
              fixed: ['Elemental Assault']),
        ],
      ),
      FactorTraitDef(
        name: 'Troll',
        category: TraitCategory.body,
        description: 'Driven by instinct and protected by thick, '
            'armor-like skin, you are dense of both body and mind.\n'
            '(1)-[Passive]: Your base Size Category is Enormous.\n'
            '(2)-[Passive]: You gain access to the Bestial Build (you '
            'must select Thick Hide for its Option effect) Bestial '
            'Trait and the Bloodlust Monstrous Trait.\n'
            '(3)-[Passive]: You may apply Punching Down if a target '
            'is only 1 Size Category smaller than you.\n'
            '(4)-[Triggered/Power, 1/Encounter]: Enter the Feral State '
            'until the end of your next turn. If you were already in '
            'the Feral State, you may enter the Surging State until '
            'the start of your next turn instead.',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.bestial, count: 0, fixed: ['Bestial Build']),
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous, count: 0, fixed: ['Bloodlust']),
        ],
      ),
      FactorTraitDef(
        name: 'Vampire',
        category: TraitCategory.body,
        description: 'Sustaining your unlife by draining the vitality '
            'of other beings, you are able to turn into a bat.\n'
            '(1)-[Passive]: You are Unnatural.\n'
            '(2)-[Passive]: Increase the amount of Life Points you '
            'regain through all effects except a Surge by 1/2 of your '
            'Surgency.\n'
            '(3)-[Passive]: You gain access to the Soar Maneuver. If '
            'you already have access to the Soar Maneuver, gain '
            'access to the Frequent Flyer Talent.\n'
            '(4)-[Passive]: You gain access to the Shapeshift Unique '
            'Ability, but it possesses the Specific Form Restriction '
            '(Small Size Category and Winged Beast Bestial Trait).\n'
            '(5)-[Passive]: You gain access to the Feast Monstrous '
            'Trait and the Fangs Bestial Trait (you must select the '
            "Savage effect for its Option effect).\n"
            '(6)-[Triggered, 1/Round]: If you deal Damage with an '
            'Attacking Maneuver, you may use the Bite Special Maneuver '
            'as an Out-of-Sequence Maneuver.',
        beastGrants: [
          BeastTraitGrant(
              kind: BeastTraitKind.monstrous, count: 0, fixed: ['Feast']),
          BeastTraitGrant(
              kind: BeastTraitKind.bestial, count: 0, fixed: ['Fangs']),
        ],
      ),
    ],
  ),

  // ============================================================ Mutation ===
  FactorDef(
    name: 'Mutation',
    description: 'Amongst some species, there exist some individuals '
        'with rare and unusual abilities, warping their bodies and '
        'sometimes even their minds. Sometimes the changes are '
        'obvious, but sometimes they are subtle, making them all the '
        'more deadly.',
    racialRequirementText: 'Any',
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Brute',
        category: TraitCategory.body,
        description: 'You may not be the smartest tool in the crayon '
            'box, but you can take hits as well as you dish them out.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Passive]: Increase your Soak by 1(bT).\n'
            '(3)-[Passive]: Increase your Tenacity Modifier by 1(T).\n'
            '(4)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver that you did not use a Counter Maneuver in '
            'response to, increase your Soak Value by 1/2 (rounded '
            'up) for the duration of that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Captain',
        category: TraitCategory.mind,
        description: 'You are a leader among men, capable of '
            'inspiring greatness in others.\n'
            '(1)-[Passive]: Increase the Dice Score of all of your '
            'Skills that use your Personality Attribute by 1.\n'
            '(2)-[Passive]: Increase your Personality Modifier by '
            '1(T).\n'
            '(3)-[Triggered, 1/Round]: When you use the Hype Maneuver, '
            'target an Ally who is not at Long Range. Increase their '
            'Combat Rolls by 1/4 (rounded up) of your Personality '
            'Modifier until the start of your next turn.\n'
            '(4)-[Triggered, 1/Encounter]: When you use the Hype '
            'Maneuver, enter the Superior State until the end of your '
            'next turn.',
      ),
      FactorTraitDef(
        name: 'Giant Gene',
        category: TraitCategory.body,
        description: 'The blood of giants runs through your veins, '
            'spurring your growth to tremendous heights.\n'
            '(1)-[Passive]: Your base Size Category is Enormous.\n'
            '(2)-[Passive]: For calculating the bonus/penalty to your '
            'Defense Value from your Size Category, and for the '
            'effects of Punching Up, you are considered to be of the '
            'Large Size Category if your Size Category is Enormous or '
            'larger.\n'
            '(3)-[Passive]: While your Size Category is Enormous, '
            'treat your Size Category as if it was Gigantic for '
            'calculating Punching Down.\n'
            '(4)-[Triggered, 1/Round]: If you use an Attacking '
            'Maneuver that has Punching Down applied to it, increase '
            'the Wound Roll of that Attacking Maneuver by 2(bT).\n'
            '(5)-[Triggered, 1/Round]: If you are hit by a Called '
            'Shot, increase your Damage Reduction by 2(bT) for the '
            'duration of that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Psychic',
        category: TraitCategory.mind,
        description: 'Your unique mind allows you to utilize strange '
            'and unusual abilities.\n'
            '(1)-[Passive]: You can choose to ignore the Ability '
            'Score Prerequisites of a Unique Ability or Advancement by '
            'increasing the Technique Point Cost by 4. Upon gaining a '
            'Power Level, if you would now meet the Prerequisites for '
            'a Unique Ability you gained through this effect, regain '
            'the additional 4 TP spent.\n'
            '(2)-[Passive]: Increase your Insight Modifier and '
            'Cognitive Saving Throw by 1(T).\n'
            '(3)-[Passive]: You may use your Insight Score instead of '
            'your Magic Score to calculate the Skill Bonus for the '
            'Use Magic Skill.\n'
            '(4)-[Passive]: Gain access to the Telekinesis Unique '
            'Ability. If you already had access to that Unique '
            'Ability, you may instead gain access to a Unique Ability '
            'with a TP Cost of 20 or less that you meet the '
            'Prerequisites for.\n'
            '(5)-[Triggered, 1/Round]: If you win a Clash for the '
            "effects of a Unique Ability against an Opponent, reduce "
            "that Opponent's Life Points by your Insight Modifier.",
      ),
      FactorTraitDef(
        name: 'Speedster',
        category: TraitCategory.body,
        description: 'Your speed is unparalleled among your kind.\n'
            '(1)-[Passive]: Increase your Defense Value by 1(T) for '
            "the duration of your Opponents' Exploit Maneuvers.\n"
            '(2)-[Passive]: Increase your Agility Modifier by 1(T).\n'
            "(3)-[Triggered, 1/Round]: At the start of any Character's "
            "turn, you may use the Movement Maneuver as an "
            "Out-of-Sequence.\n"
            '(4)-[Triggered, 1/Round]: If you would move your Boosted '
            'Speed through the Movement Maneuver, do not increase the '
            'Ki Point Cost of the Movement Maneuver.\n'
            '(5)-[Triggered, 1/Round]: If you would use the Rapid '
            'Movement effect of the Movement Maneuver, you may make a '
            'Basic Attack Maneuver as an Out-of-Sequence Maneuver '
            'immediately afterwards.\n'
            '(6)-[Triggered, 1/Encounter]: If you are targeted by an '
            'Attacking Maneuver, double your Agility Modifier for the '
            'duration of that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Tactician',
        category: TraitCategory.mind,
        description: 'Your analytical mind is beyond compare.\n'
            '(1)-[Passive]: Increase the Dice Score of all of your '
            'Skills that use your Scholarship Attribute by 1.\n'
            '(2)-[Passive]: Increase your Scholarship Modifier by '
            '1(T).\n'
            '(3)-[Triggered, 1/Round]: When you use the Analysis '
            'Maneuver, target an Ally who is not at Long Range. '
            'Increase their Combat Rolls by 1/4 (rounded up) of your '
            'Scholarship Modifier until the start of your next turn.\n'
            '(4)-[Triggered, 1/Encounter]: When you use the Analysis '
            'Maneuver, enter the Superior State until the end of your '
            'next turn.',
      ),
      FactorTraitDef(
        name: 'Technician',
        category: TraitCategory.mind,
        description: 'You are highly skilled at the technical aspects '
            'of combat, and innately adept at teamwork.\n'
            '(1)-[Passive]: Increase the Dice Category of your Energy '
            'Charges by 1.\n'
            '(2)-[Passive]: Increase your Force and Magic Modifiers by '
            '1(T).\n'
            '(3)-[Passive]: Reduce the Ki Point Cost of your Signature '
            'Techniques by 1(T).\n'
            '(4)-[Triggered, 1/Round]: When using a Signature '
            'Technique, it gains an Energy Charge.\n'
            '(5)-[Triggered, 1/Encounter]: When you use the Signature '
            'Technique Maneuver, you may ignore the effects of all '
            'Disadvantages applied to that Signature Technique. If you '
            'do, you must trigger the 4th effect of Technician for '
            'that Signature Technique.\n'
            "(6)-[Triggered, 1/Encounter]: If you use the United "
            "Attack Maneuver in response to an Ally's Attacking "
            "Maneuver, you may use that Ally's Signature Technique "
            "for that use of the United Attack Maneuver. If you do, "
            "ignore all Disadvantages for that Signature Technique.",
      ),
      FactorTraitDef(
        name: 'Emperor',
        category: TraitCategory.body,
        raceRestriction: 'Arcosian',
        description: 'Your power is so immense it must be held back '
            'lest it destroy all those around you.\n'
            '(1)-[Passive]: Gain access to all stages of the '
            'Metamorphosis Transformation Line.\n'
            '(2)-[Passive]: All of your Forms with a Racial '
            'Requirement of Arcosian are considered to be a part of '
            'the Metamorphosis Transformation Line for your effects.\n'
            '(3)-[Triggered]: Upon using the Transformation Maneuver, '
            'you may spend any amount of Overwhelm Stacks to increase '
            'your Stress Bonus by 1 for every 2 stacks of Overwhelm '
            'spent for the duration of that Maneuver.\n'
            '(4)-[Triggered, 1/Round]: Upon benefiting from the '
            'effects of Legend Realized, maximize your Overwhelm '
            'stacks.\n'
            '(5)-[Triggered, 1/Encounter]: At the end of your turn, '
            'before you apply the second effect of Overwhelming '
            'Fighter, you may use the Transformation Maneuver as an '
            'Out-of-Sequence Maneuver if you are below the Injured '
            'Health Threshold.',
      ),
      FactorTraitDef(
        name: 'Tremendous Lord',
        category: TraitCategory.body,
        raceRestriction: 'Namekian',
        description: 'Your body grows to titanic heights, allowing '
            'you to literally tower over your enemies.\n'
            '(1)-[Passive]: If your Size Category is greater than '
            'Large, for calculating the bonus/penalty to your Defense '
            "Value from your Size Category, and for the effects of "
            "your Opponent's Punching Up, you are considered to be of "
            "the Large Size Category.\n"
            '(2)-[Passive]: Gain access to the Great Namekian '
            'Enhancement. Additionally, the Great Namekian Enhancement '
            'gains the Natural (LV1) Aspect.\n'
            '(3)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver made by a Character of a smaller Size Category, '
            'increase your Soak Value by 1(bT) for each Size Category '
            'you are larger than that attacking Character.\n'
            '(4)-[Triggered, 1/Encounter]: If you use a Healing Surge '
            'through the 3rd effect of Namekian Biology, immediately '
            'afterwards you may use the Transformation Maneuver as an '
            'Out-of-Sequence Maneuver.',
      ),
      FactorTraitDef(
        name: 'Legendary Saiyan',
        category: TraitCategory.body,
        raceRestriction: 'Saiyan',
        description: 'Your power is constantly growing, overflowing '
            'beyond even your maximum potential.\n'
            '(1)-[Passive]: Each time you gain access to a Form with '
            'the Super Saiyan Form Aspect, you gain access to the '
            'Legendary Super Saiyan Evolved Stage for that '
            'Transformation. This effect also applies if you gain an '
            'Evolved Stage with the Super Saiyan Form Aspect (that '
            'does not have the Pinnacle Aspect) for a Form.\n'
            '(2)-[Passive]: Increase the maximum number of Battle Born '
            'stacks for your Wound Rolls by 2.\n'
            '(3)-[Passive]: While in the Raging and/or Superior State, '
            'increase your Might, Wound Rolls, and Soak Value by '
            '1(T).\n'
            '(4)-[Triggered, 1/Round]: If you gain a stack of Battle '
            'Born, regain Ki Points equal to your Might.',
      ),
      FactorTraitDef(
        name: 'Golden Fruit',
        category: TraitCategory.body,
        raceRestriction: 'Shinjin',
        description: 'Born from the blessed Golden Fruit of the '
            'Kaiju Tree, you are far stronger than the rest of your '
            'kin.\n'
            '(1)-[1/Round]: If you are in the God Ki State, you may '
            'spend 3(bT) Divine Ki Points to gain 1 Counter Action as '
            'an Instant Maneuver.\n'
            '(2)-[Triggered/Start of Turn]: Regain 4(bT) Divine Ki '
            'Points.\n'
            '(3)-[Triggered/Power, 1/Encounter]: Enter the God Ki '
            'State until the end of your next turn. If you are '
            'already in the God Ki State, enter the Superior State '
            'instead.',
      ),
    ],
  ),

  // ========================================================= Reincarnated ===
  FactorDef(
    name: 'Reincarnated',
    description: 'A powerful being, born again. Although you have '
        'gone through the process of reincarnation, your soul '
        'cleansed and thrown back into the world to be born and '
        'raised again… Some of that immense power you once held has '
        'remained.',
    racialRequirementText: 'Any',
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Lingering Power',
        category: TraitCategory.mind,
        description: 'Drawing on the strength remaining deep in your '
            'soul from your past life, you have greater strength than '
            'others of your race.\n'
            "(1)-[Ruling]: Upon gaining the Reincarnated Factor, you "
            "must select a Character that is deceased (with the "
            "permission of your ARC) to be your 'Past Life'. Your "
            "'Past Life' no longer exists as an independent Character.\n"
            "(2)-[Passive]: Gain a Skill Rank in the Skill with the "
            "highest number of Skill Ranks among your Past Life's "
            "Skills (if it's a tie, you decide).\n"
            "(3)-[Passive]: Increase the Attribute Score of the "
            "Attribute that your Past Life had the highest Attribute "
            "Score in by 2 (if it's a tie, you decide).\n"
            "(4)-[Passive]: Gain a Talent that your Past Life "
            "possessed and you meet the Prerequisites for.\n"
            '(5)-[Triggered/Power, 1/Encounter]: Increase your Combat '
            "Rolls by 2(bT), using your Past Life's base Tier of Power "
            "to calculate the bonus, until the end of your next turn.",
      ),
    ],
  ),

  // ============================================================== Undead ===
  FactorDef(
    name: 'Undead',
    description: 'Whether by an unearthly spirit or by some '
        'supernatural force, these bodies, once deceased, now move '
        'with unlife. The exact nature of their return from beyond '
        'the veil may vary, but regardless of the reasons or the '
        'animating forces, when the dead walk the earth once more, '
        'the living are in grave danger.',
    racialRequirementText: 'Any',
    maxFactor: 1,
    prerequisiteText: 'You are not Unnatural before applying the '
        'effects of the Undead Survival Factor.',
    traits: [
      FactorTraitDef(
        name: 'Undead Survival',
        category: TraitCategory.body,
        description: 'Your decaying body is animated by unnatural '
            'forces, making it more resilient than before.\n'
            '(1)-[Passive]: You are Unnatural, but reduce your Racial '
            'Life Modifier by 2 (this can allow your Racial Life '
            'Modifier to become negative).\n'
            '(2)-[Passive]: Increase the Dice Score of your Steadfast '
            'Checks by 1.\n'
            '(3)-[Passive]: While you are in the Undying State, you '
            'cannot regain Life Points through the effects of any of '
            'your Traits.\n'
            '(4)-[Triggered/Defeated]: Use a Healing Surge as an '
            'Out-of-Sequence Maneuver, then enter the Undying State '
            'until the end of the Combat Encounter.\n'
            '(5)-[Automatic]: Leave the Undying State if your current '
            'Life Points reaches a negative value that equals or '
            'exceeds 1/2 (rounded up) of your Maximum Life Points.',
      ),
    ],
  ),

  // ======================================================= Unstable Clone ===
  FactorDef(
    name: 'Unstable Clone',
    description: 'The cloning process was flawed, manifesting with '
        'your mind being clouded by nothing but thoughts of violence. '
        'Everything within your sight must fall before you, rendered '
        'immobile by the weight of your aggression. Fueled by the '
        "pain of your body systematically coming apart at the seams, "
        "you lose any sense of reason and go absolutely berserk.",
    racialRequirementText: 'Any',
    maxFactor: 1,
    prerequisiteText: 'You must exchange a Secondary Racial Trait of '
        'the Mind Category for this Factor\'s Factor Trait, this '
        'Factor must be gained at Character Creation.',
    traits: [
      FactorTraitDef(
        name: 'Bio-Berserker',
        category: TraitCategory.body,
        description: 'Driven by a rage that comes from the '
            'instability of your cloning process, you attack anything '
            'that moves.\n'
            "(1)-[Addendum]: You are a clone of an existing Character "
            "(work out the details — inherited Factors/Awakenings/"
            "Forms — with your ARC).\n"
            "(2)-[Ruling]: All Squares within a Large Sphere AoE "
            "(centered on you) are known as your 'Field of "
            "Aggression'.\n"
            '(3)-[Automatic/Start of Turn]: If you have any Opponents '
            'within your Field of Aggression, roll a 1d10. If your '
            'result is a 1, you gain the Compelled Combat Condition '
            'against a random Opponent within your Field of Aggression '
            'until the start of your next turn.\n'
            '(4)-[Passive]: For each Opponent within your Field of '
            'Aggression, increase your Soak Value and Wound Rolls by '
            '1(T) (max. 5(T)).\n'
            '(5)-[Passive]: While you have an Opponent within your '
            'Field of Aggression, increase your Might and Surgency by '
            '1(T).\n'
            '(6)-[Passive]: Opponents entering your Field of '
            'Aggression trigger your Exploit Maneuver.\n'
            '(7)-[Triggered, 1/Round]: If you target an Opponent '
            'within your Field of Aggression with an Attacking '
            'Maneuver, apply 1/2 of your Damage Attribute to that '
            'Attacking Maneuver.',
      ),
    ],
  ),

  // =====================================================================
  // Race-specific Factors (verified 05 July 2026) — each listed under its
  // own Race's page in the site nav rather than under the general
  // Racial Factors index.
  // =====================================================================

  // --------------------------------------------------------------- Android ---
  FactorDef(
    name: 'Machine Mutant',
    description: 'The core of your being is made of living metal, '
        'allowing you to absorb other kinds of technology into '
        'yourself.',
    racialRequirementText: 'Android',
    allowedRaces: ['Android'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Mutant Core',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Energy Core',
        description: 'The core of your being is made of living metal, '
            'allowing you to absorb other kinds of technology into '
            'yourself.\n'
            '(1)-[Passive]: While you are in the Healthy Health '
            'Threshold, reduce the Damage Category of any Attacking '
            'Maneuver that targets you by 1 Category for the sake of '
            'your Damage calculation.\n'
            '(2)-[Passive]: Apply your Racial Saving Throw Bonus to '
            'the Corporeal Saving Throw in addition to the Cognitive '
            'Saving Throw.\n'
            '(3)-[1/Round]: As a Standard Maneuver with an Action Cost '
            'of 1 Action, Integrate any Item you possess or currently '
            'have Equipped. Regain Ki Points equal to 1/10th of your '
            'Maximum Ki Points upon Integrating any Item through this '
            'effect. This effect triggers the Exploit Maneuver from '
            'all Opponents within a Sphere AoE (centered on you).\n'
            '(4)-[1/Round, 3/Encounter]: As an Instant Maneuver, you '
            'may destroy one of your Integrated Items to either use '
            'the Power Up Maneuver or use a Surge of your choice as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
  ),
  FactorDef(
    name: 'OG Soldier',
    description: 'You are able to perfectly replicate an enemy\'s '
        'abilities.',
    racialRequirementText: 'Android',
    allowedRaces: ['Android'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Mimicry Program',
        category: TraitCategory.body,
        description: "You are able to perfectly replicate an enemy's "
            "abilities.\n"
            "(1)-[Triggered, Ruling]: If you enter a Grapple as the "
            "Grappler, gain a 'Cyber Copy' of that Character. You can "
            "only possess up to 3 Cyber Copies. If you would gain any "
            "more Cyber Copies, you would have to replace one of the "
            "Cyber Copies you possess.\n"
            '(2)-[Passive]: Gain access to the Copy Being Unique '
            'Ability, but you cannot gain any Advancements for that '
            'Unique Ability and rather than select a Character, you '
            'must select a Cyber Copy you possess for its effects.\n'
            '(3)-[Passive]: You may use the Copy Being Unique Ability '
            'any number of times per Combat Encounter (though, if it '
            'is used, you stop being a Copy of the last Cyber Copy you '
            'were), and when Copying a Cyber Copy, you maintain access '
            'to this Factor Trait ignoring all Prerequisites.\n'
            "(4)-[Addendum]: A Cyber Copy is a perfect copy of a "
            "Character, though that copy doesn't exist as a Character "
            "but rather as something that can be used as a target for "
            "the Copy Being Unique Ability. A Cyber Copy possesses "
            "everything that Character has: Power Level, Race, any "
            "Subraces or Factors, Talents, Transformations, Signature "
            "Techniques, Unique Abilities, etc. Unlike a typical "
            "Character when targeted by Copy Being, a Cyber Copy does "
            "not copy any Apparel, Weapons, or Accessories possessed "
            "from the copied Character. Note any Form or Enhancements "
            "that Character was in at the time — the Cyber Copy is "
            "treated as if in those for the effects of Copy Being.",
      ),
    ],
  ),
  FactorDef(
    name: 'Tamagami',
    description: 'By storing your selected Dragon Ball within your '
        'body, only those you deem worthy or who defeat you in combat '
        'can take it from you.',
    racialRequirementText: 'Android',
    allowedRaces: ['Android'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Protector of the Dragon Ball',
        category: TraitCategory.body,
        description: 'By storing your selected Dragon Ball within '
            'your body, only those you deem worthy or who defeat you '
            'in combat can take it from you.\n'
            '(1)-[1/Encounter]: As a Standard Maneuver with an Action '
            'Cost of 2 Actions, you may integrate a Dragon Ball (see — '
            'Special Items).\n'
            '(2)-[1/Encounter]: As a Standard Maneuver with an Action '
            'Cost of 3 Actions, you may stop integrating a Dragon Ball '
            'and offer it to another character on a Square adjacent to '
            'you. If that character accepts that Dragon Ball, they '
            'enter the Superior State until the end of their next '
            'turn, but you cannot integrate another Dragon Ball for '
            'the remainder of this Combat Encounter.\n'
            '(3)-[Passive]: You can only integrate a single Dragon '
            'Ball.\n'
            '(4)-[Passive]: While you\'re Adventuring, you may '
            'integrate a Dragon Ball as a Free Maneuver.\n'
            '(5)-[Passive]: While you have an Integrated Dragon Ball, '
            'increase your Wound Rolls and Soak Value by 1(T).\n'
            '(6)-[Passive]: While you have an Integrated Dragon Ball, '
            'increase the amount of Ki Points you regain from all '
            'sources by 1/2.\n'
            '(7)-[Passive]: You may use your Magic Modifier instead of '
            'your Force Modifier when calculating Surgency (see — '
            'Surges).\n'
            '(8)-[Passive]: Upon gaining this Factor Trait, you may '
            'replace the bonus to your Force Attribute Score from your '
            'Racial Attribute Score Increase with a bonus to your '
            'Magic Attribute Score. Then, regardless of if you applied '
            'that effect, you may gain a Talent from the Weapon, '
            'Magic, Physical, or Energy Talent Categories.\n'
            '(9)-[Automatic/Defeat]: If you possess an Integrated '
            'Dragon Ball, it stops being Integrated and is placed on a '
            'Square adjacent to you.',
      ),
    ],
  ),

  // ----------------------------------------------------------- Bio Android ---
  FactorDef(
    name: 'Weapon of Mass Destruction',
    description: 'Your body is a weapon in and of itself, built for '
        'nothing but pure destruction.',
    racialRequirementText: 'Bio-Android',
    allowedRaces: ['Bio Android'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Biological Weapon',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Your body is a weapon in and of itself, built '
            'for nothing but pure destruction.\n'
            '(1)-[Prerequisite]: Uncanny Monster Racial Trait.\n'
            '(2)-[Passive]: Increase your Maximum Adaptation Points by '
            '2.\n'
            '(3)-[Passive]: You gain access to an additional Signature '
            'Technique.\n'
            '(4)-[Triggered, 1/Round]: If you spend 3+ Adaptation '
            'Points on the Wound Roll of an Attacking Maneuver, '
            'increase the Damage Category of that Attacking Maneuver '
            'by 1 Category.\n'
            '(5)-[Triggered, 1/Encounter]: If you use a Signature '
            'Technique, you may spend all of your remaining Adaptation '
            'Points to apply your Greater Dice to the Wound Roll of '
            'that Attacking Maneuver for every 2 Adaptation Points '
            'spent this way.',
      ),
    ],
  ),
  FactorDef(
    name: 'Genetic Splicing',
    description: 'Genetic Splicing has a unique element to it: each '
        'Factor Trait has a Saving Throw listed after its name. If you '
        'gain that Factor Trait, you apply your Racial Saving Throw '
        'Bonus to that Saving Throw.',
    racialRequirementText: 'Bio-Android',
    allowedRaces: ['Bio Android'],
    maxFactor: 3,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Android Cybernetics',
        category: TraitCategory.body,
        description: '[Cognitive] In addition to your genetics, you '
            'are enhanced with Android cybernetics, allowing you to '
            'outlast all but the most resilient opponents.\n'
            '(1)-[Passive]: Increase your Damage Reduction by 1(bT).\n'
            '(2)-[Passive]: Increase your Maximum Ki Points by 2 for '
            'each Power Level reached.\n'
            '(3)-[Triggered]: If you use a Ki Surge, you may spend up '
            'to 2 Adaptation Points. For every Adaptation Point spent, '
            'apply 1/2 of your Surgency to that Ki Surge.\n'
            '(4)-[Triggered/Start of Combat Round]: Regain 2(bT) Ki '
            'Points and 1 Adaptation Point.\n'
            '(5)-[Triggered, 1/Encounter]: If you spend 2+ Adaptation '
            'Points on the Wound Roll of a Signature Technique, apply '
            'an Energy Charge to that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Angel Genes',
        category: TraitCategory.body,
        description: '[Impulsive] A fraction of the divine power of '
            'the Angels flows through you, granting you powerful '
            'instincts.\n'
            '(1)-[Passive]: You can sense God Ki.\n'
            '(2)-[Passive]: While you are above the Injured Health '
            'Threshold, increase your Combat Rolls by 1(T).\n'
            '(3)-[Triggered/Power, 1/Round]: Spend an Adaptation Point '
            'to remove a stack of any Combat Condition you are '
            'suffering from (except Pinned, Suffocating, Stress '
            'Exhaustion, and Transfigured).\n'
            '(4)-[Triggered/Start of Round]: If you are above the '
            'Injured Health Threshold, gain an Adaptation Point.',
      ),
      FactorTraitDef(
        name: 'Arcosian Genes',
        category: TraitCategory.body,
        description: '[Any – you decide] Your body is made tougher by '
            "the inclusion of the Arcosians' extraordinary biology.\n"
            '(1)-[Passive]: Gain access to the Tail Attack Special '
            'Maneuver.\n'
            '(2)-[Passive]: You cannot gain the Suffocating Combat '
            'Condition.\n'
            "(3)-[Passive, Ruling]: Upon gaining this Trait, gain a "
            "'Plating' while you have this Trait. Your Plating is "
            "Natural Armor (see — Natural Armor).\n"
            '(4)-[Choice]: Depending on your choice for the 4th effect '
            'of Arcosian Genes, gain one of the following effects: '
            'Genetic Survivor [Triggered]: If your Plating has its '
            'Break Value reduced, gain an Adaptation Point. / Genetic '
            'Aggressor [Triggered]: If you spend 2+ Adaptation Points '
            'on the Strike or Wound Roll of an Attacking Maneuver, '
            'increase the Wound Roll by the Apparel Bonus of your '
            'Plating. / Genetic Agility [Triggered]: If you spend 2+ '
            'Adaptation Points on a Dodge Roll, increase the Dice '
            "Score by 1/2 of your Plating's Apparel Bonus. / Pursuit "
            'of Perfection [Triggered/Start of Turn]: Gain 1 '
            'Adaptation Point.\n'
            '(5)-[Triggered, 1/Round]: If you use a Healing Surge, '
            'your Plating regains 1 Break Value. If the piece of '
            'Apparel was broken, it stops being broken (Break Value '
            'goes from 0 to 1).',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Genetic Survivor',
                description: '[Triggered]: If your Plating has its '
                    'Break Value reduced, gain an Adaptation Point.',
              ),
              TraitOption(
                name: 'Genetic Aggressor',
                description: '[Triggered]: If you spend 2+ Adaptation '
                    'Points on the Strike or Wound Roll of an Attacking '
                    'Maneuver, increase the Wound Roll by the Apparel '
                    'Bonus of your Plating.',
              ),
              TraitOption(
                name: 'Genetic Agility',
                description: '[Triggered]: If you spend 2+ Adaptation '
                    'Points on a Dodge Roll, increase the Dice Score by '
                    "1/2 of your Plating's Apparel Bonus.",
              ),
              TraitOption(
                name: 'Pursuit of Perfection',
                description:
                    '[Triggered/Start of Turn]: Gain 1 Adaptation '
                    'Point.',
              ),
            ],
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Cerealian Genes',
        category: TraitCategory.body,
        description: '[Impulsive] Possessing the evolved right eye of '
            'the Cerealians, your talents for perception and striking '
            'vital points are unparalleled.\n'
            '(1)-[Passive]: Reduce the Critical Target of your Strike '
            'Rolls by 1.\n'
            '(2)-[Passive]: You cannot suffer from the Long Range '
            'Penalty, but none of your Signature Techniques may '
            'possess the Short Range Disadvantage.\n'
            '(3)-[Triggered]: If you score a Critical Result on the '
            'Strike Roll of an Attacking Maneuver, you may spend an '
            'Adaptation Point to increase the Wound Roll of that '
            'Attacking Maneuver by 3(T).\n'
            '(4)-[Triggered]: If you score a Critical Result on the '
            'Strike Roll of an Attacking Maneuver, gain an Adaptation '
            'Point.\n'
            '(5)-[Triggered, 1/Round]: When making an Attacking '
            'Maneuver, you may spend 2 Adaptation Points to turn that '
            'Attacking Maneuver into a Called Shot without paying the '
            'additional Action Cost.',
      ),
      FactorTraitDef(
        name: 'Demon Genes',
        category: TraitCategory.body,
        description: '[Cognitive] Filled with the overflowing power '
            'of the Demon race, you use your sly cunning and '
            'adaptability to overwhelm your enemies.\n'
            '(1)-[Triggered/Start of Turn]: Roll a 1d10. If you score '
            'a Natural Result of 6+ on this roll, enter the Superior '
            'State until the end of your turn. If you score a Dice '
            'Score of 5 or less, suffer from the Impediment Combat '
            'Condition until the end of your turn.\n'
            '(2)-[Triggered/Start of Turn]: If you score a Natural '
            'Result of 8+ on the 1st effect of Demon Genes, gain an '
            'Adaptation Point. If the Natural Result is 10, gain 2 '
            'Adaptation Points instead.\n'
            '(3)-[Automatic/Start of Turn]: If you score a Natural '
            'Result of 1 on the 1st effect of Demon Genes, lose all of '
            'your Adaptation Points. If you have no Adaptation Points, '
            'suffer from the Fatigued Combat Condition until the end '
            'of your turn.\n'
            '(4)-[Triggered/Superior, 1/Round]: Spend an Adaptation '
            'Point to use the Power Up Maneuver as an Out-of-Sequence '
            'Maneuver.\n'
            '(5)-[Option]: Upon gaining this Factor Trait, choose one '
            'of the following effects to have access to while you '
            'possess this Trait: Demon Person Genes [Passive]: '
            'Increase the Natural Result of the 1d10 rolled for the '
            '1st effect of Demon Genes by 1 (after being rolled), '
            'unless the Natural Result is 1. / Makyan Genes [Passive]: '
            'Reduce the Natural Result of the 1d10 rolled for the 1st '
            'effect of Demon Genes by 1. If you enter the Superior '
            'State through the 1st effect of Demon Genes, gain an '
            'Adaptation Point. / Phantom Genes [Triggered, 1/Round]: '
            'If you enter the Superior State through the 1st effect '
            'of Demon Genes, you may remove a Combat Condition '
            '(Impaired, Broken, Impediment, or Guard Down) you are '
            'suffering from.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Demon Person Genes',
                description: '[Passive]: Increase the Natural Result '
                    'of the 1d10 rolled for the 1st effect of Demon '
                    'Genes by 1 (after being rolled), unless the '
                    'Natural Result is 1.',
              ),
              TraitOption(
                name: 'Makyan Genes',
                description: '[Passive]: Reduce the Natural Result of '
                    'the 1d10 rolled for the 1st effect of Demon Genes '
                    'by 1. If you enter the Superior State through the '
                    '1st effect of Demon Genes, gain an Adaptation '
                    'Point.',
              ),
              TraitOption(
                name: 'Phantom Genes',
                description: '[Triggered, 1/Round]: If you enter the '
                    'Superior State through the 1st effect of Demon '
                    'Genes, you may remove a Combat Condition '
                    '(Impaired, Broken, Impediment, or Guard Down) you '
                    'are suffering from.',
              ),
            ],
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Earthling Genes',
        category: TraitCategory.body,
        description: '[Morale] In your heart beats the pure '
            'determination of the Earthlings, allowing you to '
            'persevere no matter how the odds are stacked against '
            'you.\n'
            '(1)-[Passive]: Increase the number of Technique Points '
            'you gain from Skill Improvements by 3.\n'
            '(2)-[Passive]: While you are below the Injured Health '
            'Threshold, increase all of your Combat Rolls and Soak '
            'Value by 1(T).\n'
            '(3)-[Passive]: Double the bonus to the Wound Rolls of '
            'your Signature Techniques from your Adaptation Points.\n'
            '(4)-[Triggered, 1/Round]: If you deal Damage to an '
            'Opponent with a Signature Technique, gain an Adaptation '
            'Point.',
      ),
      FactorTraitDef(
        name: 'Glass Genes',
        category: TraitCategory.body,
        description: '[Any – you decide] The power to manipulate '
            'glass infuses your genetics, clearly marking your Glass '
            'Tribe inheritance.\n'
            '(1)-[Passive]: You gain access to the Glassification '
            'Special Maneuver and the Glass Profile.\n'
            '(2)-[Passive]: Increase your Damage Reduction by 1(T).\n'
            '(3)-[Passive]: Increase your Combat Rolls by 1(T) and '
            'your Surgency by 2(T) while occupying a Square with the '
            'Glass Environmental Quality, or while adjacent to a '
            'Feature with the Glass Feature Quality.\n'
            '(4)-[Triggered/Start of Turn]: If you are occupying a '
            'Square with the Glass Environmental Quality and all '
            'adjacent Squares possess the Glass Environmental Quality '
            'or are occupied by a Feature with the Glass Feature '
            'Quality, gain an Adaptation Point.\n'
            '(5)-[Triggered, 1/Round]: If you use an Attacking '
            'Maneuver of the Glass Profile, you may spend 2 Adaptation '
            'Points to apply an Energy Charge to that Attacking '
            'Maneuver.',
      ),
      FactorTraitDef(
        name: 'Heran Genes',
        category: TraitCategory.body,
        description: '[Any – you decide] The blood of conquerors '
            'flows through your veins, thanks to the Heran genes '
            'infused in your genetic structure.\n'
            '(1)-[Passive]: Increase your Soak Value by 1(T) while '
            'you possess 2+ stacks of Power.\n'
            '(2)-[1/Round]: While you are below the Injured Health '
            'Threshold, you may use the Power Up Maneuver as an '
            'Instant Maneuver.\n'
            '(3)-[Triggered, 1/Round]: If you would use an Attacking '
            'Maneuver that possesses an AoE, you may spend up to 2 '
            'Adaptation Points to increase the Magnitude of that AoE '
            'by 1 Category for each Adaptation Point spent.\n'
            '(4)-[Triggered, 1/Round]: If you would use an Attacking '
            'Maneuver that does not possess an AoE, you may spend 2 '
            'Adaptation Points to apply a Standard Cone or Line AoE to '
            'that Attacking Maneuver.\n'
            '(5)-[Triggered/Start of Turn]: Lose up to 2 stacks of '
            'Power. For every stack of Power lost, gain an Adaptation '
            'Point.',
      ),
      FactorTraitDef(
        name: 'Konatsian Genes',
        category: TraitCategory.body,
        description: '[Morale] As the battle ebbs and flows, the '
            'tension inside you grows as your Konatsian blood rises to '
            'the occasion.\n'
            '(1)-[Triggered]: If you spend 2+ Adaptation Points '
            'through the second effect of Artificial Warrior to '
            'increase the Wound Roll of an Attacking Maneuver, '
            'increase your Wound Roll for that Attacking Maneuver by '
            '1(T) for each Health Threshold you are below.\n'
            '(2)-[Triggered]: If you spend 2+ Adaptation Points '
            'through the third effect of Artificial Warrior, increase '
            'your Soak Value by 1(T) for each Health Threshold you are '
            'below for the duration of that Attacking Maneuver.\n'
            '(3)-[Triggered]: If an Ally is Defeated, gain an '
            'Adaptation Point.\n'
            '(4)-[Triggered/Start of Turn]: If you are below the '
            'Injured Health Threshold, gain an Adaptation Point.\n'
            '(5)-[Triggered, 1/Encounter]: If you are below the '
            'Injured Health Threshold, you may spend 3 Adaptation '
            'Points to enter the Superior State until the end of your '
            'next turn. If you enter the Superior State through this '
            'effect, ignore the second effect of the Superior State.',
      ),
      FactorTraitDef(
        name: 'Majin Genes',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Majin Regeneration',
        description: '[Morale] Partially made of chewing gum-like '
            'goop, you embody the whimsical chaos of the Majin race.\n'
            '(1)-[Passive]: You are Unnatural.\n'
            '(2)-[Passive]: Gain access to a Majin Secondary Trait of '
            'your choice. That Trait cannot be traded out for Factor '
            'Traits.\n'
            '(3)-[Triggered]: If you take Collision Damage, you may '
            'spend an Adaptation Point to ignore that Collision '
            'Damage.\n'
            '(4)-[Triggered, 1/Round]: If you are targeted by an '
            'Attacking Maneuver, gain an Adaptation Point.',
      ),
      FactorTraitDef(
        name: 'Namekian Genes',
        category: TraitCategory.body,
        description: '[Any – you choose] With the regenerative powers '
            'of the Namekians, you are able to recover from damage '
            'easily and effectively.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[1/Round]: As a Standard Action with an Action Cost '
            'of 1 and a Ki Point Cost of 4(bT) Ki Points, use a Healing '
            'Surge.\n'
            '(3)-[Triggered/Start of Combat Round]: Regain 3(bT) Life '
            'Points and 1 Adaptation Point.\n'
            '(4)-[Option]: Upon gaining this Factor Trait, choose one '
            'of the following effects to have access to while you '
            'possess this Trait: Genes of a Warrior Clan [Triggered, '
            '1/Round]: If you spend 2+ Adaptation Points on the Wound '
            'Roll of an Attacking Maneuver, increase the Wound Roll by '
            '1/2 of your Surgency. / Genes of a Dragon Clan [Passive]: '
            'Gain access to the Healing Hands Unique Ability while you '
            'have this effect. You may spend Adaptation Points when '
            'using the Healing Hands Unique Ability to increase the '
            'amount of Life Points regained by your target(s) by '
            '4(bT) for every Adaptation Point spent.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Genes of a Warrior Clan',
                description: '[Triggered, 1/Round]: If you spend 2+ '
                    'Adaptation Points on the Wound Roll of an '
                    'Attacking Maneuver, increase the Wound Roll by '
                    '1/2 of your Surgency.',
              ),
              TraitOption(
                name: 'Genes of a Dragon Clan',
                description: '[Passive]: Gain access to the Healing '
                    'Hands Unique Ability while you have this effect. '
                    'You may spend Adaptation Points when using the '
                    'Healing Hands Unique Ability to increase the '
                    "amount of Life Points regained by your target(s) "
                    'by 4(bT) for every Adaptation Point spent.',
              ),
            ],
          ),
        ],
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Neko Majin Genes',
        category: TraitCategory.body,
        description: '[Cognitive or Morale] Whimsical and magical, '
            'the Neko Majin genetics within you allow you to confound '
            'and astound your enemies.\n'
            '(1)-[Passive]: You gain access to the Illusion and '
            'Shapeshift Unique Abilities.\n'
            '(2)-[Passive]: Reduce the Ki Point Cost of all Unique '
            'Abilities by 2(T).\n'
            '(3)-[Triggered, 3/Round]: After seeing your result for a '
            'Combat Roll, you may spend 1 Adaptation Point to reroll. '
            'You must take the second result.\n'
            '(4)-[Triggered/Start of Turn]: Regain 2(bT) Ki Points and '
            '1 Adaptation Point.',
      ),
      FactorTraitDef(
        name: 'Neo-Tuffle Genes',
        category: TraitCategory.body,
        description: '[Cognitive] Driven by the intense lust for '
            'revenge inherent in the Neo-Tuffles, you bear down '
            'single-mindedly on any opponent who dares stand in your '
            'way.\n'
            '(1)-[Triggered]: If you receive Damage from an '
            "Opponent's Attacking Maneuver, you gain an Adaptation "
            'Point.\n'
            '(2)-[Triggered, 1/Round]: If you receive Damage from an '
            "Opponent's Attacking Maneuver, you may spend 2 Adaptation "
            'Points to use the Basic Attack Maneuver as an '
            'Out-of-Sequence Maneuver. You must target that Opponent '
            'for this Attacking Maneuver.\n'
            '(3)-[Option]: Upon gaining this Factor Trait, choose one '
            'of the following effects to have access to while you '
            'possess this Trait: Genes of Hatred [Triggered, 1/Round]: '
            'If you spend 3+ Adaptation Points on the Strike Roll of '
            'an Attacking Maneuver, increase the Wound Roll of that '
            'Attacking Maneuver by an equal amount. / Genes of a '
            'Parasite [Triggered, 1/Round]: If you hit an Opponent '
            'with an Attacking Maneuver that you spent 3+ Adaptation '
            'Points on, reduce their Ki points by x(bT), where x is '
            'equal to three times the amount of Adaptation Points you '
            'spent.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Genes of Hatred',
                description: '[Triggered, 1/Round]: If you spend 3+ '
                    'Adaptation Points on the Strike Roll of an '
                    'Attacking Maneuver, increase the Wound Roll of '
                    'that Attacking Maneuver by an equal amount.',
              ),
              TraitOption(
                name: 'Genes of a Parasite',
                description: '[Triggered, 1/Round]: If you hit an '
                    'Opponent with an Attacking Maneuver that you '
                    'spent 3+ Adaptation Points on, reduce their Ki '
                    'points by x(bT), where x is equal to three times '
                    'the amount of Adaptation Points you spent.',
              ),
            ],
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Other Genes',
        category: TraitCategory.body,
        description: '[Any – you decide] The blood of one of the '
            'many wild and wonderful alien races of the galaxy '
            'empowers you.\n'
            '(1)-[Passive]: Select a Race created through Custom '
            'Species. Gain access to a Custom Species Racial Trait '
            'possessed by that Race (you do not gain any Twinned '
            'effects). You cannot trade this Racial Trait out for a '
            'Factor Trait.\n'
            '(2)-[Triggered/Power, 1/Round]: Gain 1 Adaptation Point.',
      ),
      FactorTraitDef(
        name: 'Saiyan Genes',
        category: TraitCategory.body,
        description: '[Any – you decide] With the warrior blood of '
            'the Saiyans coursing through your veins, your hunger for '
            'a fight lets you constantly adapt to the changing tides '
            'of battle.\n'
            '(1)-[Triggered/Threshold, Resource]: Gain a stack of '
            'Battle Creation (max. 2) and 1 Adaptation Point.\n'
            '(2)-[Passive]: For each stack of Battle Creation, '
            'increase your Combat Rolls and Surgency by 1(T).\n'
            '(3)-[Passive]: For each stack of Battle Creation, '
            'increase the Dice Score of your Steadfast Checks by 1.\n'
            '(4)-[Triggered/Defeated]: Spend 3 Adaptation Points to '
            'make a Steadfast Check, but reduce the Dice Score of this '
            'Steadfast Check by 2. If you succeed, set your Life '
            'Points to 1 below the Critical Health Threshold and '
            'maximize your Adaptation Points.\n'
            '(5)-[Triggered, 1/Encounter]: If you succeed the '
            'Steadfast Check for the 4th effect of Saiyan Genes, set '
            'your stacks of Battle Creation to 3.',
        grantedResources: [
          GrantedResource(
            name: 'Battle Creation',
            maxStacks: 2,
            description: 'Gained at a Health Threshold along with an '
                'Adaptation Point; boosts Combat Rolls/Surgency and '
                'Steadfast Checks per stack.',
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Shadow Dragon Genes',
        category: TraitCategory.body,
        description: '[Morale] Comprised of the negative energy of '
            'the Shadow Dragons, you share some of their ability to '
            'warp reality.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by 2.\n'
            '(2)-[Triggered/Start of Turn]: You may reduce your Life '
            'Points by up to 8(bT) to regain an equal amount of Ki '
            'Points.\n'
            '(3)-[Triggered]: If you gain an Adaptation Point, regain '
            '1(bT) Ki Points.\n'
            '(4)-[Triggered]: If an Opponent who is not at Long Range '
            'scores a Botch Result, you may spend an Adaptation Point '
            'to inflict the Impaired Combat Condition on that Opponent '
            'until the start of their next turn.\n'
            '(5)-[Triggered, 1/Round]: If you reduce your Life Points '
            'by 4(bT) or more through the second effects of Dragon '
            'Genes, gain an Adaptation Point.\n'
            '(6)-[Triggered, 1/Encounter]: If you reduce your Life '
            'Points by 8(bT) or more through the second effects of '
            'Dragon Genes, gain 2 Adaptation Points.',
      ),
      FactorTraitDef(
        name: 'Shinjin Genes',
        category: TraitCategory.body,
        description: '[Cognitive] Harnessing the keen insight and ki '
            'efficiency of the Shinjin, you are capable of feats of '
            'near-godly power.\n'
            '(1)-[Passive]: You can sense God Ki.\n'
            '(2)-[Passive]: Reduce the TP Cost of all Unique Abilities '
            'by 2.\n'
            '(3)-[Passive]: Reduce the Ki Point Cost of all Attacking '
            'Maneuvers by 1(T).\n'
            '(4)-[Passive]: Increase your Combat Rolls and Soak Value '
            'by 1(T) for the duration of your Counter Maneuvers.\n'
            '(5)-[Triggered]: At the end of a Combat Round, for every '
            '2 Counter Actions you possess, gain an Adaptation Point.\n'
            '(6)-[1/Round]: Spend 2 Adaptation Points to use a Counter '
            'Maneuver without spending the Action Cost.',
      ),
      FactorTraitDef(
        name: 'Yardrat Genes',
        category: TraitCategory.body,
        description: '[Cognitive or Impulsive] The energy efficiency '
            'and teamwork tendencies of the Yardrat peoples allow you '
            'to grant your unimaginable strength to your Allies.\n'
            '(1)-[Passive]: Increase your Maximum Ki Points by 2 for '
            'every Power Level reached.\n'
            '(2)-[Triggered]: If an Ally makes a Combat Roll, you can '
            'spend any number of Adaptation Points on that Combat '
            'Roll. For each Adaptation Point spent, increase that '
            'Combat Roll by 1(T).\n'
            '(3)-[Triggered]: If you are targeted by an Attacking '
            'Maneuver, you may spend up to 4(bT) Ki Points. For every '
            '2(bT) Ki Points spent, increase your Strike and Dodge '
            'Rolls by 1(T) for the duration of that Attacking '
            'Maneuver.\n'
            '(4)-[Triggered, 1/Round]: If you use the Empower '
            'Maneuver, gain an Adaptation Point for every Action spent '
            'on the Empower Maneuver.\n'
            '(5)-[Option]: Upon gaining this Factor Trait, choose one '
            'of the following effects to have access to while you '
            'possess this Trait: Tall Yardrat Genes [Triggered]: When '
            'you apply the 3rd effect of Yardrat Genes, increase your '
            'Soak Value by 1(T) for every 2(bT) Ki Points spent '
            'through that effect. This increase lasts for the '
            'duration of that Attacking Maneuver. / Bulbous Yardrat '
            'Genes [Triggered, 1/Round]: If you target an Ally with '
            'the Empower Maneuver, you may transfer any stacks of '
            'Power you possess to that Ally. These Power stacks last '
            'until the end of their next turn.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Tall Yardrat Genes',
                description: '[Triggered]: When you apply the 3rd '
                    'effect of Yardrat Genes, increase your Soak Value '
                    'by 1(T) for every 2(bT) Ki Points spent through '
                    'that effect. This increase lasts for the duration '
                    'of that Attacking Maneuver.',
              ),
              TraitOption(
                name: 'Bulbous Yardrat Genes',
                description: '[Triggered, 1/Round]: If you target an '
                    'Ally with the Empower Maneuver, you may transfer '
                    'any stacks of Power you possess to that Ally. '
                    'These Power stacks last until the end of their '
                    'next turn.',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  FactorDef(
    name: 'Bio-Focus',
    description: 'Though your genes are entirely artificial, your '
        'cybernetic enhancements are even more prominent — or drawn '
        'from another race entirely.',
    racialRequirementText: 'Bio-Android',
    allowedRaces: ['Bio Android'],
    maxFactor: 1,
    prerequisiteText: 'Genetic Splicing Factor',
    traits: [
      FactorTraitDef(
        name: 'Genetic Focus: Android',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Though your genes are entirely artificial, '
            'your cybernetic enhancements are even more prominent.\n'
            '(1)-[Prerequisite]: Android Cybernetics Factor Trait.\n'
            '(2)-[Passive]: Double the amount of Ki Points you gain '
            'through the 4th effect of Android Cybernetics.\n'
            '(3)-[Passive]: Increase your Surgency by 2(T).\n'
            '(4)-[Multi-Option/2]: Upon gaining this Factor, choose '
            'two of the following effects to have access to while you '
            'possess this Trait: Surging Power [Triggered/Power]: '
            'Spend 3(bT) Ki Points to gain an additional stack of '
            'Power. / Weapon Ports [Passive, Ruling]: At Character '
            'Creation, create 2 Weapons with a Craftsmanship Grade of '
            '2 that have different Weapon Types. These Weapons '
            'possess the Artisan Weapon Quality (1 Slot). These '
            "Weapons are known as your 'Installed Weapons', are "
            'Integrated into your Character, and cannot be destroyed '
            'through any means. / Power Absorption [Passive]: You '
            'gain access to the Power Drain and Attack Absorption '
            'Special Maneuvers (see — Special Maneuvers). / Hyper '
            'Resilience [Triggered, 2/Round]: If you take less Damage '
            'than 1/2 of your Soak Value from an Attacking Maneuver, '
            'you take no Damage. / Enhanced Reflexes [Triggered, '
            '1/Round]: When you are the target of an Attacking '
            'Maneuver, you may choose to ignore all of your stacks of '
            'Diminishing Defense against that Attacking Maneuver. If '
            'you possess no stacks of Diminishing Defense, then apply '
            'your Greater Dice to this Dodge Roll. / Weapon Style '
            '[Passive]: You gain the Weapon Specialist Talent, and '
            'when creating any type of Signature Technique, you may '
            'add the Weapon Assisted Advantage to that Signature '
            'Technique without spending Technique Points. / Heroic '
            'Style [Triggered]: Increase your Combat Rolls by 1(T) '
            'until the end of your turn when you use the Hype '
            'Maneuver. / Calculating Style [Triggered]: Increase your '
            'Combat Rolls by 1(T) until the end of your turn when you '
            'use the Analysis Maneuver. / Alternate Scale Structure '
            '[Passive]: Upon gaining this effect, select either the '
            'Tiny Size Category or the Enormous Size Category. That '
            'selected Size Category becomes your base Size Category. '
            'Additionally, if you choose Tiny, increase your Soak '
            'Value by 1(T) and if you choose Enormous, increase your '
            'Defense Value by 1(T). / Extension Feature [Passive]: '
            'You possess the Extension Attack Monstrous Trait.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Multi-Option',
            maxChoices: 2,
            options: [
              TraitOption(
                name: 'Surging Power',
                description: '[Triggered/Power]: Spend 3(bT) Ki '
                    'Points to gain an additional stack of Power.',
              ),
              TraitOption(
                name: 'Weapon Ports',
                description: '[Passive, Ruling]: At Character '
                    'Creation, create 2 Weapons with a Craftsmanship '
                    'Grade of 2 that have different Weapon Types. '
                    'These Weapons possess the Artisan Weapon Quality '
                    '(1 Slot). These Weapons are known as your '
                    "'Installed Weapons', are Integrated into your "
                    'Character, and cannot be destroyed through any '
                    'means.',
              ),
              TraitOption(
                name: 'Power Absorption',
                description: '[Passive]: You gain access to the '
                    'Power Drain and Attack Absorption Special '
                    'Maneuvers (see — Special Maneuvers).',
              ),
              TraitOption(
                name: 'Hyper Resilience',
                description: '[Triggered, 2/Round]: If you take less '
                    'Damage than 1/2 of your Soak Value from an '
                    'Attacking Maneuver, you take no Damage.',
              ),
              TraitOption(
                name: 'Enhanced Reflexes',
                description: '[Triggered, 1/Round]: When you are the '
                    'target of an Attacking Maneuver, you may choose '
                    'to ignore all of your stacks of Diminishing '
                    'Defense against that Attacking Maneuver. If you '
                    'possess no stacks of Diminishing Defense, then '
                    'apply your Greater Dice to this Dodge Roll.',
              ),
              TraitOption(
                name: 'Weapon Style',
                description: '[Passive]: You gain the Weapon '
                    'Specialist Talent, and when creating any type of '
                    'Signature Technique, you may add the Weapon '
                    'Assisted Advantage to that Signature Technique '
                    'without spending Technique Points.',
              ),
              TraitOption(
                name: 'Heroic Style',
                description: '[Triggered]: Increase your Combat '
                    'Rolls by 1(T) until the end of your turn when '
                    'you use the Hype Maneuver.',
              ),
              TraitOption(
                name: 'Calculating Style',
                description: '[Triggered]: Increase your Combat '
                    'Rolls by 1(T) until the end of your turn when '
                    'you use the Analysis Maneuver.',
              ),
              TraitOption(
                name: 'Alternate Scale Structure',
                description: '[Passive]: Upon gaining this effect, '
                    'select either the Tiny Size Category or the '
                    'Enormous Size Category. That selected Size '
                    'Category becomes your base Size Category. '
                    'Additionally, if you choose Tiny, increase your '
                    'Soak Value by 1(T) and if you choose Enormous, '
                    'increase your Defense Value by 1(T).',
              ),
              TraitOption(
                name: 'Extension Feature',
                description: '[Passive]: You possess the Extension '
                    'Attack Monstrous Trait.',
                beastGrants: [
                  BeastTraitGrant(
                    kind: BeastTraitKind.monstrous,
                    count: 0,
                    fixed: ['Extension Attack'],
                  ),
                ],
              ),
            ],
          ),
        ],
        automation: [
          // (3) +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Angel',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'You closely resemble a member of the enigmatic '
            'Angel race.\n'
            '(1)-[Prerequisite]: Angel Genes Factor Trait.\n'
            '(2)-[Passive]: While you are below the Injured Health '
            'Threshold, increase your Surgency by 2(T).\n'
            '(3)-[Passive]: While you have no Adaptation Points, '
            'increase your Defense Value and Soak Value by 1(T).\n'
            '(4)-[Triggered]: If you spend an Adaptation Point, '
            'regain 2(bT) Life Points.\n'
            '(5)-[Triggered]: If you spend Adaptation Points on a '
            'Combat Roll, increase its Natural Result by 1 for each '
            'Adaptation Point spent (max. +2).\n'
            '(6)-[Triggered/Injured]: Use a Healing Surge as an '
            'Out-of-Sequence Maneuver.',
        automation: [
          // (2) While below the Injured Health Threshold: +2(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 2,
            tierScaling: TierScaling.current,
            condition: TraitCondition.whileBelowInjuredThreshold,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Arcosian',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Your Arcosian genes give you an overwhelmingly '
            'intimidating visage.\n'
            '(1)-[Prerequisite]: Arcosian Genes Factor Trait.\n'
            '(2)-[Passive]: Increase the Apparel Bonus of your '
            'Plating by 1(T).\n'
            '(3)-[Passive]: Double the bonus to your Wound Rolls of '
            'your Tail Attack from your Adaptation Points.\n'
            '(4)-[Triggered]: If you spend Adaptation Points on the '
            'Wound Roll of an Attacking Maneuver, and a target of that '
            'Attacking Maneuver receives Damage, gain an Adaptation '
            'Point.\n'
            '(5)-[Triggered, 1/Encounter]: If you knock an Opponent '
            'through a Health Threshold or Defeat them with an '
            'Attacking Maneuver, maximize your Adaptation Points. If '
            'you already had a number of Adaptation Points equal to '
            'or exceeding 1/2 of your maximum number of Adaptation '
            'Points, you may use the Energy Charge Maneuver as an '
            'Out-of-Sequence Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Cerealian',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Your crimson right eye is the most prominent '
            'feature of your genetically-engineered appearance.\n'
            '(1)-[Prerequisite]: Cerealian Genes Factor Trait.\n'
            '(2)-[Passive]: You do not have to spend an Adaptation '
            'Point to trigger the 3rd effect of Cerealian Genes.\n'
            '(3)-[Passive]: Increase the Wound Rolls of your Called '
            'Shots and Exploit Maneuvers by 2(T).\n'
            '(4)-[Triggered, 1/Round]: If an Opponent triggers your '
            'Exploit Maneuver, you may spend 2 Adaptation Points to '
            'use the Exploit Maneuver without paying the Action '
            'Cost.\n'
            '(5)-[Triggered, 1/Encounter]: If you spend 2+ Adaptation '
            'Points on the Strike Roll of an Attacking Maneuver, you '
            'score a Critical Result on that Strike Roll regardless '
            'of the Natural Result.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Demon',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Your infernal heritage marks you as a '
            'demon\'s kin.\n'
            '(1)-[Prerequisite]: Demon Genes Factor Trait.\n'
            '(2)-[Passive]: You are considered to possess the Demon '
            'Clansman Factor for all Prerequisites.\n'
            '(3)-[Passive]: Increase your Combat Rolls and Damage '
            'Reduction by 1(T) against Opponents suffering from a '
            'Combat Condition.\n'
            '(4)-[Triggered, 1/Round]: You can spend an Adaptation '
            'Point to reroll the 1d10 for the 1st effect of Demon '
            'Genes. If you do, you must accept the results and cannot '
            'reroll again through any effect.\n'
            '(5)-[Triggered, 1/Round]: If you deal Damage to an '
            'Opponent with an Attacking Maneuver, spend an Adaptation '
            'Point to make a Clash (Impulsive/Corporeal/Cognitive/'
            'Morale) against that Opponent. If you win, they suffer '
            'from either the: Drained, Broken, or Impaired Combat '
            'Condition (you decide) until the start of your next '
            'turn.\n'
            '(6)-[Triggered, 1/Encounter]: If you roll a Natural '
            'Result of 10 on the 1st effect of Demon Genes, you may '
            'use the Power Up Maneuver as an Out-of-Sequence '
            'Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Earthling',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Your unyielding human spirit shines through '
            'your artificial genetics.\n'
            '(1)-[Prerequisite]: Earthling Genes Factor Trait.\n'
            '(2)-[Passive]: For each Health Threshold you are below, '
            'increase your Wound Rolls and Surgency by 1(T).\n'
            '(3)-[Passive]: Increase the amount of Technique Points '
            'you gain from Skill Improvement by 2.\n'
            '(4)-[Triggered]: When you use the Signature Technique '
            'Maneuver, spend an Adaptation Point. If you do, for this '
            'instance of using your chosen Signature Technique, you '
            'may either: apply an Energy Charge to that Attacking '
            'Maneuver, or add a single Advantage with a TP cost of up '
            'to 10 TP to your chosen Signature Technique.\n'
            '(5)-[Triggered/Threshold, 1/Encounter]: Upon making your '
            'Steadfast Check for this Health Threshold, you can spend '
            'up to 3 Adaptation Points. For every Adaptation Point '
            'spent, increase the Dice Score of your Steadfast Check '
            'by 1.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Glass',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'Fragile in appearance but resilient in truth, '
            'your Glass Tribe genetics belie your durability.\n'
            '(1)-[Prerequisite]: Glass Genes Factor Trait.\n'
            '(2)-[Passive]: Halve your Soak Value.\n'
            '(3)-[Passive]: Gain Damage Reduction equal to your Soak '
            'Value.\n'
            '(4)-[Triggered, 1/Round]: If you use a Signature '
            'Technique, you may apply the Multi-Profile Super Profile '
            'to that Attacking Maneuver. If you do, you must select '
            'the Glass Profile for the effects of Multi-Profile, and '
            'you must trigger the 5th effect of Glass Genes on this '
            'Attacking Maneuver (if you have 2+ Adaptation Points).\n'
            '(5)-[Triggered/Start of Turn]: Spend 3 Adaptation Points '
            'to enter the Surging State until the end of your turn.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Herans',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The conquering spirit of the Herans flows '
            'through your artificial veins.\n'
            '(1)-[Prerequisite]: Heran Genes Factor Trait.\n'
            '(2)-[Passive]: For every stack of Power you possess, '
            'increase your Wound Rolls by 1(T).\n'
            '(3)-[Passive]: Increase your maximum number of Power '
            'stacks by 1.\n'
            '(4)-[Triggered/Power, 1/Round]: Instead of gaining an '
            'Adaptation Point, you may spend an Adaptation Point to '
            'gain an additional stack of Power.\n'
            '(5)-[Triggered, 1/Encounter]: If you deal Damage to an '
            'Opponent with an Attacking Maneuver, you may spend an '
            'Adaptation Point to target an Ally adjacent to that '
            'Opponent. That Ally can use the Basic Attack Maneuver as '
            'an Out-of-Sequence Maneuver, but they must target that '
            'Opponent with that Attacking Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Konatsians',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The wise, single-minded focus of the '
            'Konatsians is bred into your artificial genes.\n'
            '(1)-[Prerequisite]: Konatsian Genes Factor Trait.\n'
            '(2)-[Passive]: Gain access to the Konatsian-Raised '
            'Factor Trait.\n'
            '(3)-[Passive]: While you are below the Injured Health '
            'Threshold, you may spend 3 Adaptation Points and 3(bT) '
            'Ki Points as if they were 1 Tension.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Majins',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'A trace of Majin goop lingers in your '
            'artificial genetics.\n'
            '(1)-[Prerequisite]: Majins Genes Factor Trait.\n'
            '(2)-[Passive]: Gain access to a Majin Secondary Trait of '
            'your choice. That Trait cannot be traded out for Factor '
            'Traits.\n'
            '(3)-[Passive]: You may use your Magic Modifier instead '
            'of your Force Modifier when calculating Surgency (see — '
            'Surges).\n'
            '(4)-[Passive]: Increase your Soak Value and Defense '
            'Value by 1(T).\n'
            '(5)-[Triggered/Threshold]: Spend an Adaptation Point to '
            'use a Healing Surge as an Out-of-Sequence Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If you use a Healing '
            'Surge, maximize your Adaptation Points. Then, you may '
            'use any Standard Maneuver with an Action Cost of 1 '
            'Action as an Out-of-Sequence Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Namekians',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The patient, regenerative nature of the '
            'Namekians has left its mark on your genetics.\n'
            '(1)-[Prerequisite]: Namekian Genes Factor Trait.\n'
            '(1)-[Passive]: Increase your Surgency by 1(T).\n'
            '(2)-[Passive]: You may use your Magic Modifier instead '
            'of your Force Modifier when calculating Surgency (see — '
            'Surges).\n'
            '(3)-[Triggered]: When making any type of Physical '
            'Attacking Maneuver or Grapple Maneuver, you may increase '
            'your Melee Range by 3 Squares for the duration of that '
            'Maneuver.\n'
            '(4)-[Triggered, 1/Round]: Upon hitting an Opponent with '
            'a Physical Attacking Maneuver or initiating a Grapple, '
            'you may move that Character any number of Squares up to '
            'your current Melee Range in any direction – ignoring the '
            'usual rules for Movement in a Grapple if you initiated a '
            'Grapple.\n'
            '(5)-[Triggered, 1/Round]: If you use a Healing Surge, '
            'you may spend any number of Adaptation Points. For each '
            'Adaptation Point spent, increase the amount of Life '
            'Points regained by 2(bT).\n'
            '(6)-[Triggered, 1/Encounter]: If you use a Healing Surge '
            'to increase your Life Points above a Health Threshold, '
            'maximize your Adaptation Points.',
        automation: [
          // (1) +1(T) Surgency.
          RaceTraitAutomation(
            affectedStats: [AffectedStat.surgency],
            coefficient: 1,
            tierScaling: TierScaling.current,
          ),
        ],
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Neko Majins',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The whimsical, mischievous nature of the Neko '
            'Majins expresses itself through your artificial genes.\n'
            '(1)-[Prerequisite]: Neko Majins Genes Factor Trait.\n'
            '(2)-[Passive]: You may use your Magic Modifier instead '
            'of your Force Modifier when calculating Surgency (see — '
            'Surges).\n'
            "(3)-[Passive]: Upon gaining this Factor Trait, create a "
            "Majin-Dama Special Accessory (see — Neko Majins) while "
            "you possess this Trait, which is Integrated into your "
            "Character. Another Character may take an Integrated "
            "Majin-Dama from you using the Snatch Special Maneuver if "
            "you are Defeated or Sleeping. That Character "
            "automatically wins the Clash if you are Defeated; if "
            "they lose the Clash while you are Sleeping, you lose the "
            "Sleeping Combat Condition. A stolen Majin-Dama stops "
            "being Integrated.\n"
            '(4)-[1/Round]: You can spend 1 Action to Integrate a '
            'Majin-Dama you possess.\n'
            '(5)-[1/Round]: As an Instant Maneuver, you can spend 1 '
            'Action to expel an Integrated Majin-Dama from your body. '
            'When you do, it stops being Integrated and is dropped or '
            'Equipped (your choice).\n'
            '(6)-[Passive]: If you have no Integrated Majin-Dama, '
            'reduce your Combat Rolls and Soak Value by 2(T).\n'
            '(7)-[Passive]: While you have an Integrated Majin-Dama, '
            'double the amount of Ki Points and Adaptation Points '
            'gained through the 4th effect of Neko Majin Genes.\n'
            '(8)-[1/Encounter]: If you have an Integrated Majin Dama, '
            'use a Surge of your choice as an Instant Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Neo-Tuffle',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The vengeful, spiteful drive of the '
            'Neo-Tuffles is bred into your genetics.\n'
            '(1)-[Prerequisite]: Neo-Tuffle Genes Factor Trait.\n'
            "(2)-[Triggered/Start of Combat Round, Ruling]: Target an "
            "Opponent. That Opponent becomes an 'Inferior Specimen' "
            "until the end of the Combat Round.\n"
            '(3)-[Passive]: Increase your Combat Rolls by 1(T) '
            'against an Inferior Specimen.\n'
            '(4)-[Passive]: Halve the amount of Adaptation Points '
            'required for the 2nd effect of Neo-Tuffle Genes if the '
            'attacking Character is an Inferior Specimen.\n'
            '(5)-[Choice]: Depending on your choice for the Option '
            'effect of Neo-Tuffle Genes, choose one of the following '
            'effects: Genes of Hatred [Triggered]: If you use the '
            'Energy Charge Maneuver, gain an Adaptation Point. / '
            'Genes of a Parasite [Passive]: You gain access to the '
            'Liquid Form Maneuver (see — Special Maneuvers). While in '
            'Liquid Form, you have access to the Possess Maneuver '
            '(see — Special Maneuvers).',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Custom',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'You carry the genetic legacy of one of the '
            'myriad alien races of the galaxy.\n'
            '(1)-[Prerequisite]: Other Genes Factor Trait.\n'
            '(2)-[Passive]: Gain the Twinned effects of the Racial '
            'Trait gained through the effects of Other Genes.\n'
            '(3)-[Passive]: Upon gaining this Factor Trait, gain a '
            'Character Perk. You lose anything gained from this '
            'Character Perk if you lose this Trait.\n'
            '(5)-[Triggered, 1/Encounter]: If you use the 2nd effect '
            'of Other Genes, instead of gaining 1 Adaptation Point, '
            'you may maximize your Adaptation Points.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Saiyan',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The proud warrior blood of the Saiyans '
            'resonates within your engineered body.\n'
            '(1)-[Prerequisite]: Saiyan Genes Factor Trait.\n'
            '(2)-[Passive]: For each stack of Battle Creation, '
            'increase your Soak Value by 1(T).\n'
            '(3)-[Triggered/Start of Combat Round]: At the start of '
            'every even-numbered Combat Round, you gain 1 Adaptation '
            'Point.\n'
            '(4)-[Triggered, 1/Round]: If you would gain a stack of '
            'Battle Creation while at your maximum, you may instead '
            'use the Power Up Maneuver as an Out-of-Sequence '
            'Maneuver.\n'
            '(5)-[Triggered/Start of Turn, 1/Encounter]: If you have '
            'triggered the 3rd effect of Genetic Focus: Saiyan at '
            'least 2 times previously during this Combat Encounter, '
            'you may gain a stack of Battle Creation.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Shadow Dragon',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The reality-warping negative energy of the '
            'Shadow Dragons courses through your artificial veins.\n'
            '(1)-[Prerequisite]: Shadow Dragon Genes Factor Trait.\n'
            '(2)-[Passive]: Gain 1 Bestial Trait.\n'
            '(3)-[Passive]: Increase your Soak Value and Defense '
            'Value by 1(T) against Attacking Maneuvers made by '
            'Opponents with the Impaired Combat Condition.\n'
            '(4)-[Passive]: You gain access to the Unify Maneuver, '
            'but your Race is considered to be Shadow Dragon for the '
            'effects of the Unify Maneuver. If a target is in their '
            'Ball Form and is Defeated, they do not need to be '
            'willing for the effects of the Unify Maneuver.',
        beastGrants: [
          BeastTraitGrant(kind: BeastTraitKind.bestial),
        ],
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Shinjin',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The near-godly insight of the Shinjin '
            'manifests through your artificial genetics.\n'
            '(1)-[Prerequisite]: Shinjin Genes Factor Trait.\n'
            '(2)-[Passive]: You gain access to the Magical '
            'Materialization, Telepathy, Telekinesis, and Second '
            'Sight Unique Abilities.\n'
            '(3)-[Passive]: Upon gaining this Factor Trait, gain a '
            'Skill Rank in each of the following skills while you '
            'have access to this Trait: Creature Handling, '
            'Clairvoyance, Perception, Use Magic and Investigation.\n'
            '(4)-[Passive]: Your minimum Action Cost for Combat '
            'Recovery is 1 Action.\n'
            '(5)-[Triggered, 1/Round]: If you use Combat Recovery, '
            'you may spend 2 Adaptation Points to not trigger an '
            'Exploit Maneuver.',
      ),
      FactorTraitDef(
        name: 'Genetic Focus: Yardrat',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Uncanny Monster',
        description: 'The energy-efficient, team-oriented spirit of '
            'the Yardrat flows through your engineered body.\n'
            '(1)-[Prerequisite]: Yardrat Genes Factor Trait.\n'
            '(2)-[Passive]: Upon gaining this Factor Trait, gain a '
            'stack of Spirit Control while you possess this Trait. '
            'This stack of Spirit Control does not count towards your '
            'Awakening Limit, and you do not gain the Attribute '
            'Modifier Bonus from this stack of Spirit Control.\n'
            "(3)-[Triggered, 1/Round, Ruling]: If you give Ki Points "
            "to an Ally (except a Minion) through the Empower "
            "Maneuver, you become 'Bio-Bonded' until you become "
            "Bio-Bonded to another Ally. You cannot be Bio-Bonded "
            "with a Character that another Bio-Android is already "
            "Bio-Bonded to.\n"
            '(4)-[Triggered]: When your Bio-Bonded Ally is hit by an '
            'Attacking Maneuver, you may spend any number of '
            'Adaptation Points. For each spent, increase their Damage '
            'Reduction by 1(T) for the duration of that Attacking '
            'Maneuver.\n'
            '(5)-[Choice]: Depending on your Choice for the Option '
            'effect of Yardrat Genes, gain one of the following '
            'effects: Tall Yardrat Genes [Passive]: While you are on '
            'an adjacent Square to your Bio-Bonded Ally, increase the '
            'Wound Rolls and Soak Value of both you and your '
            'Bio-Bonded Ally by 1(T). / Bulbous Yardrat Genes '
            '[Passive]: While they are not at Long Range, increase '
            'the Combat Rolls and Soak Value of your Bio-Bonded Ally '
            'by 1(T).',
      ),
    ],
  ),

  // -------------------------------------------------------------- Demon ---
  FactorDef(
    name: 'Megath',
    description: 'Your body is so massive that it defies logic and '
        'reason.',
    racialRequirementText: 'Demon',
    allowedRaces: ['Demon'],
    maxFactor: 1,
    prerequisiteText: 'Demon Person Subrace, Gigantic Demon effect '
        'chosen for the Option effect of Denizen of the Demon Realm',
    traits: [
      FactorTraitDef(
        name: 'Colossal Demon',
        category: TraitCategory.body,
        description: 'Your body is so massive that it defies logic '
            'and reason.\n'
            '(1)-[Passive]: Your Racial Life Modifier is increased '
            'by 4.\n'
            '(2)-[Passive]: Increase your base Size Category from '
            'Gigantic to Colossal.\n'
            '(3)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver, for the duration of that Attacking Maneuver, '
            'increase your Soak Value by 1(T) for each Size Category '
            'you are larger than the attacking Character.\n'
            '(4)-[Triggered, 1/Round]: When making an Attacking '
            'Maneuver, apply the Extra Dice from Punching Down (see — '
            'Size) an additional time.',
      ),
    ],
  ),

  // --------------------------------------------------------------- Earthling ---
  FactorDef(
    name: 'Dragon Ball Hero',
    description: 'You have the ability to change into your Avatar '
        'form, temporarily changing your race.',
    racialRequirementText: 'Earthling',
    allowedRaces: ['Earthling'],
    maxFactor: 1,
    prerequisiteText: 'This Factor can only be gained through the '
        'effects of the Hero Switch Special Accessory.',
    traits: [
      FactorTraitDef(
        name: 'Switch to a Hero',
        category: TraitCategory.body,
        description: 'You have the ability to change into your '
            'Avatar form, temporarily changing your race.\n'
            "(1)-[Addendum]: Upon gaining this Factor, create an "
            "additional Character of the same Power Level as you – "
            "this Character is not a real entity, but a Character you "
            "can become through the 2nd effect of Switch to a Hero. "
            "This Character's Race must be either: Android, Arcosian, "
            "Bio-Android, Demon, Majin, Namekian, Saiyan, or Shinjin. "
            "This Character is known as your 'Avatar'. Whenever you "
            "gain a Power Level, so does your Avatar. Your Avatar "
            "gains Transformations completely independently from you, "
            "decided by the ARC as with any other Character, but upon "
            "Character Creation, your Avatar will gain the Class "
            "Avatar Greater Awakening. Your Avatar shares the current "
            "value of their Life Points, Ki Points, and Capacity with "
            "you (and vice-versa). If you would regain this Factor "
            "after losing it, you maintain the same Avatar you "
            "possessed before but it gains Power Levels until it "
            "matches your current Power Level.\n"
            '(2)-[1/Encounter]: As a Standard Action with an Action '
            'Cost of 1, switch to your Avatar until the end of the '
            'Combat Encounter. Your Avatar takes your place on the '
            'Battlefield and the Initiative Order. You have control '
            'of your Avatar as if it was your Character, and your '
            'Avatar gains any Combat Conditions you were suffering '
            'from for their remaining duration.\n'
            '(3)-[Triggered, 1/Encounter]: If you use the 2nd effect '
            'of Switch to a Hero when you are in a Transformation, '
            'you may use the Transformation Maneuver as an '
            'Out-of-Sequence Maneuver after switching to your '
            'Avatar.',
      ),
    ],
  ),
  FactorDef(
    name: 'Saiyan Ancestry',
    description: 'The diluted Saiyan blood flowing through your '
        'veins has awoken, granting you some of the resilience and '
        'combat prowess of your forefathers.',
    racialRequirementText: 'Earthling',
    allowedRaces: ['Earthling'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Dormant Saiya Power',
        category: TraitCategory.body,
        description: 'The diluted Saiyan blood flowing through your '
            'veins has awoken, granting you some of the resilience '
            'and combat prowess of your forefathers.\n'
            '(1)-[Passive]: You automatically succeed all Steadfast '
            'Checks for the Bruised Health Threshold. You also cannot '
            'gain any failures for the Bruised Health Threshold due to '
            'any rules like Massive Damage (see – Health Thresholds) '
            'or any effects such as Pain to Power (see — Limit '
            'Break).\n'
            '(2)-[Triggered/Defeated]: You may make a Steadfast Check '
            '(if you do, reduce your Dice Score by 2). If you '
            'succeed, set your Life Points to 1.\n'
            '(3)-[Triggered/Threshold, Resource]: Gain a stack of '
            'Warrior Blood (max. 3). For each stack of Warrior Blood, '
            'increase your Wound Rolls by 1(T) and the Dice Score of '
            'your Steadfast Checks by 1. If you possess 2+ stacks of '
            'Warrior Blood, increase all of your Combat Rolls by '
            '1(T).',
        grantedResources: [
          GrantedResource(
            name: 'Warrior Blood',
            maxStacks: 3,
            description: 'Gained at a Health Threshold; boosts Wound '
                'Rolls and Steadfast Checks per stack, plus Combat '
                'Rolls at 2+ stacks.',
          ),
        ],
      ),
    ],
  ),
  FactorDef(
    name: 'Triclops',
    description: 'You have a literal third eye in your forehead, '
        'which coincides with your mystical third eye, granting you '
        'great mystical power.',
    racialRequirementText: 'Earthling',
    allowedRaces: ['Earthling'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Three-Eyes',
        category: TraitCategory.body,
        description: 'You have a literal third eye in your forehead, '
            'which coincides with your mystical third eye, granting '
            'you great mystical power.\n'
            '(1)-[Passive]: For each Health Threshold you are below, '
            'increase the Wound Rolls for your Signature Techniques '
            'by 1(T).\n'
            '(2)-[Passive]: You can choose to ignore the Ability '
            'Score Prerequisites of a Unique Ability or Advancement '
            'by increasing the Technique Point Cost by 4. Upon '
            'gaining a Power Level, if you would now meet the '
            'Prerequisites for a Unique Ability you gained through '
            'this effect, regain the additional 4 TP spent.\n'
            '(3)-[Triggered]: The first time you would gain a stack '
            'of Diminishing Defense from each Opponent during each '
            'Combat Round, you do not gain that stack of Diminishing '
            'Defense.\n'
            '(4)-[Triggered]: The first time you would gain a stack '
            'of Diminishing Offense during each Combat Round, you do '
            'not gain that stack of Diminishing Offense.\n'
            '(5)-[Triggered/Power]: Regain 4(bT) Ki Points.\n'
            '(6)-[Triggered/Start of Turn, 1/Encounter]: If you are '
            'below the Injured Health Threshold, you may reduce your '
            'Life Points to 1 below the Critical Health Threshold '
            '(ignoring Reduced Momentum). If you do, you '
            'automatically succeed the Steadfast Check for that '
            'Health Threshold and you may use a Ki Surge as an '
            'Out-of-Sequence Maneuver.',
      ),
    ],
  ),

  // ---------------------------------------------------------------- Majin ---
  FactorDef(
    name: 'Assimilating Majin',
    description: 'Possessing the ability to absorb the bodies and '
        'powers of others, you can grow stronger by consuming beings '
        'with the scattered pieces of your body.',
    racialRequirementText: 'Majin',
    allowedRaces: ['Majin'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Assimilation',
        category: TraitCategory.body,
        description: 'Possessing the ability to absorb the bodies '
            'and powers of others, you can grow stronger by consuming '
            'beings with the scattered pieces of your body.\n'
            '(1)-[Passive]: Increase your Corporeal Save by 1(T).\n'
            '(2)-[Passive]: You gain access to the Absorb Maneuver.\n'
            '(3)-[Passive]: If you have the Primordial Majin Factor, '
            'your Goops gain access to (and can use) the Absorb '
            'Maneuver (see — Special Maneuvers) ignoring the '
            '(Non-Minion) tag. Your Goop uses your Combat Rolls and '
            'Saving Throws for this Maneuver, and if they succeed, '
            'they are instantly Defeated and you are treated as if '
            'you succeeded at using the Absorb Maneuver on your '
            'target instead.\n'
            '(4)-[Triggered]: Upon gaining a stack of the Absorption '
            'Awakening, you may replace your Top Layer of Apparel '
            'with the Top Layer of Apparel equipped by the Absorbed '
            'Character for that stack of Absorption. If you do, that '
            'piece of Apparel may gain any Special Apparel Qualities '
            'possessed by the piece of Apparel it replaced.',
      ),
    ],
  ),
  FactorDef(
    name: 'Android Majin',
    description: 'You have the unique ability to absorb more of your '
        'targets than just their abilities, taking a very piece of '
        'them even after they\'ve escaped you.',
    racialRequirementText: 'Majin',
    allowedRaces: ['Majin'],
    maxFactor: 1,
    prerequisiteText: 'Assimilation Factor Trait',
    traits: [
      FactorTraitDef(
        name: 'DNA Absorption',
        category: TraitCategory.body,
        description: 'You have the unique ability to absorb more of '
            'your targets than just their abilities, taking a very '
            'piece of them even after they\'ve escaped you.\n'
            "(1)-[Triggered, Ruling]: Upon gaining a stack of "
            "Absorption, gain a 'DNA Copy' of that stack's Absorbed "
            "Character. You can only possess up to 3 DNA Copies. If "
            "you would gain any more DNA Copies, you would have to "
            "replace one of the DNA Copies you possess.\n"
            '(2)-[Triggered/Power, 1/Round, 3/Encounter]: Choose a '
            'DNA Copy, then gain a stack of Absorption as a Level 2 '
            'Temporary Awakening with that DNA Copy as the Absorbed '
            'Character. If you already have a stack of Absorption '
            'from this effect, then when triggering this effect you '
            'may replace that stack of Absorption with one using a '
            'different DNA Copy.\n'
            "(3)-[Addendum]: A DNA Copy is a perfect copy of a "
            "Character, though that copy doesn't exist as a "
            "Character, but rather as something that can be used as "
            "an Absorbed Character for Absorption through the "
            "effects of DNA Absorption. A DNA Copy is a perfect copy "
            "of the Character, possessing everything that Character "
            "has at the time it was recorded. DNA Copies have a few "
            "rules that apply to the Absorption Awakening: If the "
            "only stack of Absorption as a Temporary Awakening you "
            "possess is one that uses a DNA Copy as the Absorbed "
            "Character, you may ignore the 5th effect of Assimilated "
            "Power. If you lose a stack of Absorption using a DNA "
            "Copy as the Absorbed Character, then no Absorbed "
            "Character is freed or produced due to the 7th effect of "
            "Assimilated Power as the DNA Copy doesn't exist as a "
            "Character. You cannot gain a stack of Absorption with a "
            "DNA Copy as a non-Temporary Awakening, even if you "
            "trigger the 8th effect of Assimilated Power.",
      ),
    ],
  ),
  FactorDef(
    name: 'Chaotic Majin',
    description: 'You are a being of primordial chaos, inherently '
        'unpredictable.',
    racialRequirementText: 'Majin',
    allowedRaces: ['Majin'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Absolute Chaos',
        category: TraitCategory.body,
        description: 'You are a being of primordial chaos, '
            'inherently unpredictable.\n'
            '(1)-[Passive]: Upon gaining access to this Factor, gain '
            'access to the Pure Form Transformation.\n'
            '(2)-[Passive]: Pure Form gains the Prelude Aspect.\n'
            '(3)-[Passive]: Upon mastering Pure Form, it gains the '
            'Natural (LV1) Aspect. Increase the level of this Aspect '
            'by 1 if it is Fully Mastered.\n'
            '(4)-[Passive]: Pure Form becomes part of the Pure Majin '
            'Transformation Line, with Internalized Chaos as its Null '
            'Stage, and you gain access to that Null Stage. '
            '(Internalized Chaos, its associated Null Stage '
            'Transformation, is not modeled in this app — '
            'Transformations are a future milestone; see the '
            'Transformation Line Prerequisite text above for its '
            'existence.)',
      ),
    ],
  ),
  FactorDef(
    name: 'Diluted Majin',
    description: 'Though you have less magical goo in your '
        'composition than most Majins, you\'re still hardy and '
        'nearly indestructible.',
    racialRequirementText: 'Majin',
    allowedRaces: ['Majin'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Traces of Majin',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Majin Regeneration',
        description: 'Though you have less magical goo in your '
            'composition than most Majins, you\'re still hardy and '
            'nearly indestructible.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by '
            '4.\n'
            '(2)-[Passive]: For each Health Threshold you are below, '
            'increase your Soak Value by 1(T).\n'
            '(3)-[Passive]: For each stack of Power you possess, '
            'increase your Wound Rolls by 1(T).\n'
            '(4)-[Triggered, 1/Round]: If you are hit by an Attacking '
            'Maneuver of the Direct or Lethal Damage Category, you '
            'may spend up to 8(bT) Ki Points. For every 4(bT) Ki '
            'Points spent, you may lower the Damage Category by 1.\n'
            '(5)-[Option]: Upon gaining access to this Factor Trait, '
            'select one of the following effects: Low Dilution '
            '[Triggered, 1/Round]: If you take Damage from an '
            'Attacking Maneuver, regain Life Points equal to your '
            'Surgency. / Highly Diluted [Passive]: You cannot use the '
            '7th effect of Rubbery Body, but while you have 2+ stacks '
            'of Power, increase the Wound Rolls of your Signature '
            'Techniques by 2(T).',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Low Dilution',
                description: '[Triggered, 1/Round]: If you take '
                    'Damage from an Attacking Maneuver, regain Life '
                    'Points equal to your Surgency.',
              ),
              TraitOption(
                name: 'Highly Diluted',
                description: '[Passive]: You cannot use the 7th '
                    'effect of Rubbery Body, but while you have 2+ '
                    'stacks of Power, increase the Wound Rolls of '
                    'your Signature Techniques by 2(T).',
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  FactorDef(
    name: 'Primordial Majin',
    description: 'Made entirely out of a magical, chewing gum-esque '
        'substance, you can heal and split yourself into multiple '
        'pieces with ease.',
    racialRequirementText: 'Majin',
    allowedRaces: ['Majin'],
    maxFactor: 1,
    prerequisiteText: 'You are not a Minion',
    traits: [
      FactorTraitDef(
        name: 'From Goop',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Majin Regeneration',
        description: 'Made entirely out of a magical, chewing '
            'gum-esque substance, you can heal and split yourself '
            'into multiple pieces with ease.\n'
            '(1)-[Passive]: You may use your Magic Modifier instead '
            'of your Force Modifier when calculating Surgency (see — '
            'Surges).\n'
            '(2)-[Passive]: Upon gaining access to this Factor '
            'Trait, select and gain access to a Talent from the '
            'Minion Talent Category or Racial Talent Category (Majin '
            'Race) while you possess this Factor Trait.\n'
            '(3)-[1/Round]: As a Standard Maneuver with an Action '
            'Cost of 1 Action and a Ki Point Cost of 4(bT), use a '
            'Healing Surge.\n'
            '(4)-[Triggered/Threshold]: Use a Healing Surge as an '
            'Out-of-Sequence Maneuver. Increase the amount of Life '
            'Points you regain through this effect by 2(bT) for every '
            'Health Threshold you are below upon triggering the '
            'effect.\n'
            "(5)-[Triggered, 3/Round, Ruling]: When you use the "
            "Healing Surge, you may halve the amount of Life Points "
            "you regain from that Healing Surge to create a 'Goop' "
            "in an unoccupied Square within a Large Sphere AoE "
            "(centered on you), as an Out of Sequence Maneuver. A "
            "Goop is a Duplicate Minion, but does not possess the "
            "Apparel, Accessories, or Weapons of their creator. A "
            "Goop cannot use any Maneuvers except the Movement "
            "Maneuver, but they may always take their Act Phase, "
            "even if you do not use the Command Maneuver.\n"
            '(6)-[1/Round]: As a Standard Maneuver with a Variable '
            'Action Cost (1~3 Actions), for each Action spent, Defeat '
            'one of your Goops (they cannot trigger a '
            '[Triggered/Defeated] effect in response to this effect). '
            'If you do, regain Life Points equal to 1/2 of the total '
            'amount of Life Points they had remaining. You cannot '
            'target a Goop you created this Turn with this effect.\n'
            '(7)-[Triggered/Defeated]: You may Defeat any number of '
            'your Goops, and regain Life Points equal to 1/2 of the '
            'total amount of Life Points amongst all of the Goops '
            'Defeated by this effect. Then, use a Healing Surge as an '
            'Out-of-Sequence Maneuver.\n'
            '(8)-[Automatic]: All of your Goops die at the end of the '
            'Combat Encounter. Regain Life Points equal to 1/2 of the '
            'total Life Points amongst those Goops before they died.',
      ),
    ],
  ),

  // ------------------------------------------------------------ Namekian ---
  FactorDef(
    name: 'Dark Vassal',
    description: 'You were created in a unique form for a purpose, '
        'to serve your progenitor.',
    racialRequirementText: 'Namekian',
    allowedRaces: ['Namekian'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Dragon-like',
        category: TraitCategory.body,
        description: 'You were created in a unique form for a '
            'purpose, to serve your progenitor.\n'
            '(1)-[Passive]: Upon gaining this Factor Trait, select '
            'and gain access to up to 2 Bestial Traits. For each '
            'Bestial Trait gained, reduce your Racial Life Modifier '
            'by 1.\n'
            '(2)-[Passive]: Increase your Wound Rolls against Studied '
            'Opponents by 1(T).\n'
            '(3)-[Option]: Upon gaining this Factor Trait, select and '
            'gain access to one of the following effects: Dragon '
            "Lord's Fury [Triggered, 1/Round]: If an Ally is hit by "
            'an Attacking Maneuver from a Studied Opponent, you may '
            'use the Intervene Maneuver without spending a Counter '
            "Action. / Dragon Lord's Rage [Triggered, 1/Round]: If a "
            'Studied Ally on an adjacent Square targets an Opponent '
            'with an Attacking Maneuver, you may use the United '
            'Attack Maneuver without spending an Action through its '
            'effects.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: "Dragon Lord's Fury",
                description: '[Triggered, 1/Round]: If an Ally is '
                    'hit by an Attacking Maneuver from a Studied '
                    'Opponent, you may use the Intervene Maneuver '
                    'without spending a Counter Action.',
              ),
              TraitOption(
                name: "Dragon Lord's Rage",
                description: '[Triggered, 1/Round]: If a Studied '
                    'Ally on an adjacent Square targets an Opponent '
                    'with an Attacking Maneuver, you may use the '
                    'United Attack Maneuver without spending an '
                    'Action through its effects.',
              ),
            ],
          ),
        ],
        beastGrants: [
          // (1) Select up to 2 Bestial Traits (each reduces your Racial Life
          // Modifier by 1 — apply that RLM cost manually).
          BeastTraitGrant(
            kind: BeastTraitKind.bestial,
            count: 2,
            label: 'Gain up to 2 Bestial Traits (each −1 Racial Life Modifier)',
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------------- Neko Majin ---
  FactorDef(
    name: 'Feline Warrior',
    description: 'You redirect your inherent magic towards your '
        'combat capabilities.',
    racialRequirementText: 'Neko Majin',
    allowedRaces: ['Neko Majin'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Combat Cat',
        category: TraitCategory.mind,
        mustReplaceTraitName: 'Whimsical Magic',
        description: 'You redirect your inherent magic towards your '
            'combat capabilities.\n'
            '(1)-[Passive]: Reduce the Ki Point Cost of your '
            'Attacking Maneuvers by 1(T). Double this reduction if '
            'you are below the Injured Health Threshold.\n'
            '(2)-[Passive]: Increase your Dice Score for any Might '
            'Clash initiated by an Opponent by 1(T).\n'
            '(3)-[Passive]: While you have an Integrated Majin-Dama, '
            'increase your Wound Rolls and Soak Value by 1(T).\n'
            '(4)-[Passive]: While in the Superior State, apply your '
            'Greater Dice an additional time to the Wound Roll of '
            'your Signature Techniques.\n'
            '(5)-[Triggered, 1/Round]: If you use the Signature '
            'Technique Maneuver, you may spend 1 Action to enter the '
            'Superior State for the duration of that Attacking '
            'Maneuver. If you were already in the Superior State, you '
            'may instead apply an Energy Charge to that Attacking '
            'Maneuver.\n'
            '(6)-[Triggered, 1/Encounter]: If you trigger the 5th '
            'effect of Combat Cat while below the Injured Health '
            'Threshold, you do not have to spend an Action to '
            'utilize its effects.',
      ),
    ],
  ),
  FactorDef(
    name: 'Usagi Majin',
    description: 'Instead of taking the physical form of a cat, you '
        'more closely resemble a rabbit.',
    racialRequirementText: 'Neko Majin',
    allowedRaces: ['Neko Majin'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Greedy Rabbit',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Feline Build',
        description: 'Instead of taking the physical form of a cat, '
            'you more closely resemble a rabbit.\n'
            '(1)-[Passive]: At Character Creation, gain the Bestial '
            'Build and Land-Based Beast Bestial Traits.\n'
            '(2)-[Passive]: For every Integrated Majin-Dama you '
            'possess, increase your Maximum Life Points by 1 for '
            'each Power Level reached.\n'
            '(3)-[Passive]: Increase your Speed by 1(T) and Defense '
            'Value by 1(T) for each of your Active Integrated '
            'Majin-Damas.\n'
            '(4)-[Passive]: You may have 2 Active Integrated '
            'Majin-Damas (ignoring the maximum for Integrated '
            'Accessories). Apply the effects of any Active Integrated '
            'Majin-Dama you possess, ignoring Double-Dip.\n'
            '(5)-[Triggered/Start of Turn]: Regain 2(bT) Ki Points '
            'for every Integrated Majin-Dama you possess (max. '
            '10(bT)).\n'
            '(6)-[Triggered, 1/Encounter]: Target an Opponent. Make '
            'a Clash (Cognitive/Morale) against that Opponent. If you '
            'win, they enter the Sleeping Combat Condition.',
        beastGrants: [
          BeastTraitGrant(
            kind: BeastTraitKind.bestial,
            count: 0,
            fixed: ['Bestial Build', 'Land-Based Beast'],
          ),
        ],
      ),
    ],
  ),

  // -------------------------------------------------------------- Saiyan ---
  FactorDef(
    name: 'Alternate Universe Saiyan',
    description: 'Lithe, slender, and optimized for speed, nothing '
        'keeps you from finishing off your target.',
    racialRequirementText: 'Saiyan',
    allowedRaces: ['Saiyan'],
    maxFactor: 1,
    prerequisiteText: 'Tailless option selected for Saiyan Heritage',
    traits: [
      FactorTraitDef(
        name: 'Alternative Warrior Race',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Powerful Physique',
        description: 'Lithe, slender, and optimized for speed, '
            'nothing keeps you from finishing off your target.\n'
            '(1)-[Passive]: While you possess 4+ stacks of Battle '
            'Born, increase your Stress Bonus by 1.\n'
            '(2)-[Passive]: While you possess 6+ stacks of Battle '
            'Born, increase your Strike and Dodge Rolls by 1(T).\n'
            '(3)-[Passive]: While you possess 2+ stacks of Power, '
            'increase your Tier of Power Extra Dice by 1 Dice '
            'Category (min. 1d4).\n'
            '(4)-[Triggered, 1/Encounter]: If you are hit by an '
            'Attacking Maneuver that does not possess a Ki Wager that '
            "exceeds 1/2 of the attacker's Max Capacity or 3+ Energy "
            'Charges, gain a stack of Battle Born, and then you may '
            'roll your Strike Roll or Dodge Roll (you decide). If the '
            'Dice Score of this roll exceeds the Dice Score made by '
            'the attacking Character, you are not hit by that '
            'Attacking Maneuver. You can only use this effect if you '
            'are below the Bruised Health Threshold.',
      ),
    ],
  ),
  FactorDef(
    name: 'Ancient Saiyan',
    description: 'Built to take massive damage even from early on in '
        'their evolution, some Saiyans are capable of shrugging off '
        'hits that would take down even their modern counterparts.',
    racialRequirementText: 'Saiyan',
    allowedRaces: ['Saiyan'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Primitive Durability',
        category: TraitCategory.body,
        description: 'Built to take massive damage even from early '
            'on in their evolution, some Saiyans are capable of '
            'shrugging off hits that would take down even their '
            'modern counterparts.\n'
            '(1)-[Passive]: Increase your Racial Life Modifier by '
            '2.\n'
            '(2)-[Passive]: For every 3 stacks of Battle Born you '
            'possess, increase your Soak Value by 1(T) and the Dice '
            'Score of your Steadfast Checks by 1.\n'
            '(3)-[Triggered, 1/Round]: If you gain a stack of Battle '
            'Born, regain Life Points equal to your Surgency.\n'
            '(4)-[Triggered/Undying]: Use a Healing Surge as an '
            'Out-of-Sequence Maneuver.\n'
            '(5)-[Triggered, 1/Encounter]: If you fail a Steadfast '
            'Check, you can instead choose to pass it automatically.',
      ),
    ],
  ),
  FactorDef(
    name: 'Half-Saiyan',
    description: 'Combining the best Saiyans have to offer with the '
        'blood of another race, you represent the combined strengths '
        'of both of your parent races.',
    racialRequirementText: 'Saiyan',
    allowedRaces: ['Saiyan'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Warrior of Two Worlds',
        category: TraitCategory.body,
        description: 'Combining the best Saiyans have to offer with '
            'the blood of another race, you represent the combined '
            'strengths of both of your parent races.\n'
            '(1)-[Passive]: While you possess 4+ stacks of Battle '
            'Born, increase your Wound Rolls by 2(T). Double this '
            'bonus for any Attacking Maneuver made through the '
            'Signature Technique Maneuver.\n'
            '(2)-[Passive]: While you are below the Injured Health '
            'Threshold, increase your Strike and Wound Rolls by '
            '1(T).\n'
            '(3)-[Option]: At Character Creation, choose one of the '
            'following effects: Inherited Fury [Passive]: While you '
            'are in the Raging State, increase your Wound Rolls by '
            '1(bT) for every Health Threshold you or the Ally with '
            'the lowest Health Threshold is below (whichever results '
            'in a higher bonus). / Inherited Aggression [Passive]: '
            'For each Health Threshold an Opponent is below, increase '
            'your Wound Rolls against them by 1(bT). / Inherited '
            'Creativity [Passive]: Increase the amount of Technique '
            'Points you gain from Skill Improvements by 3 and reduce '
            'the Ki Point Cost of your Signature Techniques by 1(T). '
            '/ Inherited Freedom [Passive]: While you are below the '
            'Injured Health Threshold, increase your Boosted Speed '
            'and Defense Value by 1(bT). / Inherited Resolve '
            '[Passive]: While you are below the Injured Health '
            'Threshold, increase your Damage Reduction by 1(bT).\n'
            '(4)-[Choice]: Depending on your choice for the Option '
            'effect of this Trait, gain the following effect: see '
            'below.',
        optionGroups: [
          RaceTraitOptionGroup(
            label: 'Option',
            options: [
              TraitOption(
                name: 'Inherited Fury',
                description: '[Passive]: While you are in the Raging '
                    'State, increase your Wound Rolls by 1(bT) for '
                    'every Health Threshold you or the Ally with the '
                    'lowest Health Threshold is below (whichever '
                    'results in a higher bonus).',
              ),
              TraitOption(
                name: 'Inherited Aggression',
                description: '[Passive]: For each Health Threshold an '
                    'Opponent is below, increase your Wound Rolls '
                    'against them by 1(bT).',
              ),
              TraitOption(
                name: 'Inherited Creativity',
                description: '[Passive]: Increase the amount of '
                    'Technique Points you gain from Skill Improvements '
                    'by 3 and reduce the Ki Point Cost of your '
                    'Signature Techniques by 1(T).',
              ),
              TraitOption(
                name: 'Inherited Freedom',
                description: '[Passive]: While you are below the '
                    'Injured Health Threshold, increase your Boosted '
                    'Speed and Defense Value by 1(bT).',
              ),
              TraitOption(
                name: 'Inherited Resolve',
                description: '[Passive]: While you are below the '
                    'Injured Health Threshold, increase your Damage '
                    'Reduction by 1(bT).',
              ),
            ],
          ),
        ],
        dependentChoice: DependentChoice(
          sourceTraitName: 'Warrior of Two Worlds',
          sourceGroupLabel: 'Option',
          textByOption: {
            'Inherited Fury': '[Triggered, 1/Encounter]: If you gain '
                'a stack of Battle Born, enter the Raging State until '
                'the end of your next turn. If you were already in '
                'the Raging State, you may enter the Surging State '
                'for this effect instead.',
            'Inherited Aggression': '[Triggered, 1/Encounter]: If '
                'you knock an Opponent through a Health Threshold, '
                'gain a stack of Battle Born.',
            'Inherited Creativity': '[Triggered/Start of Turn, '
                '1/Encounter]: Create a Signature Technique with a TP '
                'Cost up to your maximum TP Cost for your base Tier '
                'of Power, you have access to that Signature '
                'Technique for the remainder of the Combat Encounter. '
                'That Signature Technique cannot possess any '
                'Disadvantages.',
            'Inherited Freedom': '[Triggered/Start of Turn]: You may '
                'spend 1 Counter Action to use a Standard Maneuver '
                'with an Action Cost of 1 Action as an '
                'Out-of-Sequence Maneuver. If you do, you cannot use '
                'a Counter Maneuver until the start of your next '
                'turn. If you do, you cannot use a Counter Maneuver '
                'until the start of your next turn.',
            'Inherited Resolve': '[Triggered/Start of Turn]: Regain '
                'x(bT) Life and Ki Points, where x is equal to twice '
                'the number of Health Thresholds you are below.',
          },
        ),
      ),
    ],
  ),

  // --------------------------------------------------------- Shadow Dragon ---
  FactorDef(
    name: 'Disguised Dragon',
    description: 'You take on a seemingly ordinary form until it\'s '
        'time to unleash your true draconic nature.',
    racialRequirementText: 'Shadow Dragon',
    allowedRaces: ['Shadow Dragon'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Disguised Shadow',
        category: TraitCategory.body,
        mustReplaceTraitName: 'Draconic Physique',
        description: 'You take on a seemingly ordinary form until '
            'it\'s time to unleash your true draconic nature.\n'
            '(1)-[Passive]: Gain access to the Monster Form '
            'Transformation and Monster Form gains the Absorbed '
            'Apparel Aspect.\n'
            '(2)-[Passive]: You do not have access to the Bestial '
            'Trait you selected for the 2nd effect of Personified '
            'Dragon Ball while in your Normal State (see — '
            'Transformation Rules).\n'
            '(3)-[Passive]: While in your Normal State, double the '
            'amount of Ki Points you regain through the 4th effect of '
            'Negative Ki.\n'
            '(4)-[Passive]: Increase the Dice Score of your Saving '
            'Throw and Might Clashes against Opponents suffering from '
            'the Impaired Combat Condition by 1(T).\n'
            '(5)-[Choice]: Depending on your choice for the Option '
            'effect of Personified Dragon Ball, apply the following '
            'effect:',
        dependentChoice: DependentChoice(
          sourceTraitName: 'Personified Dragon Ball',
          sourceGroupLabel: 'Option',
          textByOption: {
            'Sinister Dragon': '[Passive]: Increase the Wound Rolls '
                'of your Attacking Maneuvers made through the Exploit '
                'Maneuver by 2(T).',
            'Hazy Dragon': '[Passive]: Ignore the penalties from the '
                'Bog Environment. Instead, while you are in the Bog '
                'Environment, increase your Combat Rolls by 1(bT) and '
                'increase your Speeds by 1/2.',
            'Elemental Dragon': '[Triggered, 1/Round]: If you knock '
                'an Opponent through a Health Threshold with an '
                "Attacking Maneuver of your Favored Element's "
                'Profile, they gain a stack of Impaired until the '
                'start of your next turn.',
            'Noble Dragon': '[Triggered]: If you inflict the '
                'Compelled Combat Condition upon an Opponent through '
                'the effects of Noble Dragon, they gain a stack of '
                'Impaired until the start of your next turn.',
            'Regenerative Dragon': '[Triggered/Defeat]: You are not '
                'Defeated and lose all of your Dragon Slimes. For '
                'every Dragon Slime lost, regain Life Points equal to '
                '1/10th of your Maximum Life Points.',
            'Ominous Dragon': '[Passive]: Gain access to the Terrify '
                'Maneuver. Additionally, if you inflict a Combat '
                'Condition to an Opponent through the Terrify '
                "Maneuver's effects, that Opponent also suffers from "
                'the Impaired Combat Condition until the start of '
                'your turn.',
            'Natural Dragon': '[Triggered]: Upon gaining a stack of '
                'Absorption, you may increase your Size Category to '
                'Gigantic while you possess that stack of Absorption. '
                'Additionally, increase your Soak Value and Wound '
                'Rolls by 1(T) while you possess at least 1 stack of '
                'Absorption.',
          },
        ),
      ),
    ],
  ),
  FactorDef(
    name: 'Inverted Shadow',
    description: 'Pure of mind and soul, you are composed of '
        'positive energy, rather than the negative energy of your '
        'counterparts.',
    racialRequirementText: 'Shadow Dragon',
    allowedRaces: ['Shadow Dragon'],
    maxFactor: 1,
    prerequisiteText: 'N/A',
    traits: [
      FactorTraitDef(
        name: 'Dragon of Light',
        category: TraitCategory.body,
        description: 'Pure of mind and soul, you are composed of '
            'positive energy, rather than the negative energy of '
            'your counterparts.\n'
            '(1)-[Automatic, Resource]: If you would gain a stack(s) '
            'of Negative Energy, gain an equal number of Positive '
            'Energy stacks instead. Positive Energy is also '
            'considered to be Negative Energy for all of your '
            'effects.\n'
            '(2)-[Passive]: Instead of reducing your Life Points, '
            'you may spend Ki Points for the 1st effect of Negative '
            'Ki.\n'
            '(3)-[Triggered]: If an Ally who is not at Long Range '
            'makes a Combat Roll, after you see the Dice Score of '
            'that Combat Roll, you may spend a stack of Positive '
            'Energy to increase the Natural Result of that Combat '
            'Roll by 1.\n'
            '(4)-[Triggered]: Each time you gain Positive Energy, '
            'regain 1(bT) Life Points for every Positive Energy '
            'stack gained.\n'
            '(5)-[Triggered, 1/Round]: If you or an Ally scores a '
            'Critical Result on a Combat Roll, gain 1 Positive '
            'Energy.\n'
            '(6)-[Triggered, 1/Encounter]: If an Ally within a Large '
            'Sphere AoE (centered on you) would be Defeated, you may '
            'spend all of your Positive Energy. If you do, that Ally '
            'regains 2(bT) Life Points for every Positive Energy '
            'spent.',
        grantedResources: [
          GrantedResource(
            name: 'Positive Energy',
            maxStacks: 10,
            description: 'Replaces Negative Energy gains; used for '
                'Combat Roll boosts and emergency Ally healing.',
          ),
        ],
      ),
    ],
  ),
];

/// Looks up a Factor by name, or `null` if unrecognized.
FactorDef? factorByName(String name) {
  for (final f in kDbuFactors) {
    if (f.name == name) return f;
  }
  return null;
}
