/// dbu_rules.dart
/// ---------------------------------------------------------------------------
/// SINGLE SOURCE OF TRUTH for the static rules content of the Dragon Ball
/// Universe (DBU) tabletop RPG, as published on https://dbu-rpg.com/.
///
/// This file deliberately contains ONLY *data* (lists, tables, enums and simple
/// look-ups). All *derived* values (a character's Max Life, Skill bonuses,
/// Aptitudes, etc.) are computed in `services/character_calculator.dart`, which
/// reads from this file. Keeping the raw rules here means that when the DBU
/// system is updated on the website, most maintenance happens in this one place.
///
/// SOURCES (verified against the live site, July 2026):
///   • Attributes ............ https://dbu-rpg.com/attributes/
///   • Skills ................ https://dbu-rpg.com/skills/
///   • Size .................. https://dbu-rpg.com/size/
///   • Character Creation .... https://dbu-rpg.com/character-creation/
///   • Thresholds & Conditions https://dbu-rpg.com/thresholds-conditions/
///     (Combat Conditions catalogue — verified 03 July 2026 against a full
///     offline mirror of the site, not just live search snippets; this
///     caught that the old sheet's catalogue was stale: "Oblivious" and a
///     standalone "Damage Over Time" condition no longer exist, while
///     "Drained", "Impaired", "Staggered" and "Transfigured" are new.)
///
/// Where a specific data point still needs to be double-checked against the
/// rules text, it is flagged with a `// VERIFY:` comment so it is easy to find.
/// ---------------------------------------------------------------------------
library;

/// The seven core Attributes of the DBU system.
///
/// Confirmed on the Attributes page:
///   "These 7 Attributes provide a description of your Character's physical and
///    mental characteristics" — Agility, Force, Tenacity, Scholarship, Insight,
///    Magic, Personality.
///
/// CONFIRMED terminology (Attributes page, verbatim): "Your Attribute
/// Modifier is equal to your Attribute Score, but ... your Attribute Modifier
/// can be modified by various effects and Transformations." The Modifier
/// (not the raw Score) is what most Aptitudes and Combat Rolls use; the raw
/// Score is used for prerequisites and for the few mechanics that are NOT
/// affected by modifier-changing effects (Skills' Attribute Bonus and Saving
/// Throws). See `CharacterCalculator.attributeModifier` vs `.attributeBonus`.
enum DbuAttribute {
  agility('Agility', 'AG'),
  force('Force', 'FO'),
  tenacity('Tenacity', 'TE'),
  scholarship('Scholarship', 'SC'),
  insight('Insight', 'IN'),
  magic('Magic', 'MG'),
  personality('Personality', 'PE');

  const DbuAttribute(this.displayName, this.abbreviation);

  /// Full human-readable name shown in the UI (e.g. "Agility").
  final String displayName;

  /// The short code the rulebook uses when cross-referencing (e.g. "AG").
  final String abbreviation;
}

/// The four Saving Throws. Each is governed by one Attribute and uses that
/// Attribute's raw Score directly (not the Modifier — Attributes page: "your
/// Attribute Score is used for ... mechanics that aren't affected by changes
/// to modifiers – such as your ... Saving Throws").
///
/// CONFIRMED against the Attributes page (verbatim): "The Impulsive Saving
/// Throw uses your Agility Score." / "The Corporeal Saving Throw uses your
/// Tenacity Score." / "The Cognitive Saving Throw uses your Insight Score."
/// / "The Morale Saving Throw uses your Personality Score."
enum DbuSavingThrow {
  impulsive('Impulsive', DbuAttribute.agility),
  cognitive('Cognitive', DbuAttribute.insight),
  corporeal('Corporeal', DbuAttribute.tenacity),
  morale('Morale', DbuAttribute.personality);

  const DbuSavingThrow(this.displayName, this.attribute);

  final String displayName;
  final DbuAttribute attribute;
}

/// Size Categories a character can be built at.
///
/// Character Creation, Step 4: "Choose a Size Category (Small, Medium or
/// Large). The larger a Character is, the more durable they are, while the
/// smaller a Character is, the more evasive they are." Larger categories
/// (Enormous, Gigantic, ...) exist but are reached through Traits/Talents, so
/// only the three selectable-at-creation options are offered by default.
///
/// CONFIRMED against the Size page's table: Small grants +1(T) Defense Value
/// and -1(T) Soak; Large grants -1(T) Defense Value and +1(T) Soak (Medium is
/// the zero baseline). The "(T)" suffix means the value scales with the
/// character's Tier of Power, so `CharacterCalculator` multiplies these
/// adjustments by `PowerLevelRules.tierOfPower`.
enum DbuSize {
  small('Small'),
  medium('Medium'),
  large('Large');

  const DbuSize(this.displayName);
  final String displayName;
}

/// A single Skill definition: its name, the Attribute that feeds its bonus, and
/// whether it is an "Encompassing" Skill that is split into Specialties.
///
/// Skill Bonus rule (Skills page):
///   Skill Bonus = Attribute Bonus (½ of the governing Attribute Score)
///                 + Rank Bonus (+2 per Skill Rank).
class SkillDef {
  const SkillDef(
    this.name,
    this.attribute, {
    this.specialties = const [],
    this.requiresRank = false,
  });

  /// Display name of the skill (e.g. "Acrobatics").
  final String name;

  /// The Attribute whose Score contributes half of the Skill's bonus.
  final DbuAttribute attribute;

  /// For "Encompassing" skills (Craft, Knowledge), the default Specialties.
  /// A character keeps a rank total per specialty. Empty = a normal skill.
  final List<String> specialties;

  /// Some skills (e.g. Flight, marked "(R)") only work if the character has at
  /// least one Rank in them. Purely informational for the UI/rules layer.
  final bool requiresRank;

  bool get isEncompassing => specialties.isNotEmpty;
}

/// The master Skill list — every pairing CONFIRMED against the Skills page
/// (offline ZIM, verified 12 July 2026). The site sorts Skills by Attribute:
/// Agility (Acrobatics, Flight (R), Thievery, Stealth), Scholarship (Craft
/// (R)(E), Knowledge (E), Investigation, Medicine (R)), Insight (Clairvoyance
/// (R), Concealment (R), Creature Handling, Intuition, Perception, Pilot (R),
/// Survival), Magic (Use Magic (R)), Personality (Bluff, Cooking,
/// Intimidation, Persuasion, Performance). There are no Force- or
/// Tenacity-based Skills.
const List<SkillDef> kDbuSkills = [
  SkillDef('Acrobatics', DbuAttribute.agility),
  SkillDef('Bluff', DbuAttribute.personality),
  SkillDef('Clairvoyance', DbuAttribute.insight, requiresRank: true),
  SkillDef('Concealment', DbuAttribute.insight, requiresRank: true),
  SkillDef('Cooking', DbuAttribute.personality),
  SkillDef(
    'Craft',
    DbuAttribute.scholarship,
    specialties: ['Basic Item', 'Apparel', 'Weapons', 'Vehicles'],
    requiresRank: true,
  ),
  SkillDef('Creature Handling', DbuAttribute.insight),
  SkillDef('Flight', DbuAttribute.agility, requiresRank: true),
  SkillDef('Intimidation', DbuAttribute.personality),
  SkillDef('Intuition', DbuAttribute.insight),
  SkillDef('Investigation', DbuAttribute.scholarship),
  SkillDef(
    'Knowledge',
    DbuAttribute.scholarship,
    specialties: ['Science', 'Profession', 'History'],
  ),
  SkillDef('Medicine', DbuAttribute.scholarship, requiresRank: true),
  SkillDef('Perception', DbuAttribute.insight),
  SkillDef('Performance', DbuAttribute.personality),
  SkillDef('Persuasion', DbuAttribute.personality),
  SkillDef('Pilot', DbuAttribute.insight, requiresRank: true),
  SkillDef('Stealth', DbuAttribute.agility),
  SkillDef('Survival', DbuAttribute.insight),
  SkillDef('Thievery', DbuAttribute.agility),
  SkillDef('Use Magic', DbuAttribute.magic, requiresRank: true),
];

/// Z-Soul alignment options (Z-Souls & Karma Points page).
const List<String> kZSoulAlignments = [
  'Pure Good',
  'Good',
  'Neutral',
  'Evil',
  'Pure Evil',
];

/// A Race entry: name, Racial Life Modifier, Attribute Score Increase (display
/// text — several Races let the player choose which Attribute gets which
/// increase, so this is kept as descriptive text rather than a fixed map),
/// the Saving Throw(s) that receive the Racial Saving Throw Bonus, and the
/// number of freely-allocatable Racial Skill Ranks.
///
/// CONFIRMED against each Race's own page (racial-rules framework page,
/// verbatim): "you gain a bonus to your Saving Throws... +1(T) as well as
/// reducing the Critical Target of that Saving Throw by 1" (Racial Saving
/// Throw Bonus — see `CharacterCalculator.racialSavingThrowBonus`); "you gain
/// a number of Skill Ranks that you can freely place in any Skill(s) of your
/// choice" (Racial Skills). Two Races (Neko Majin, Yardrat) grant the bonus
/// to TWO Saving Throws instead of one — both are CONFIRMED verbatim on
/// their own pages.
/// One resolved-by-the-player slot within a `RaceAttributeIncrease` (e.g.
/// "either Force or Magic score is increased by +1"). [options] lists the
/// candidate Attributes the player picks exactly one from; an empty list
/// means "any Attribute" (Shinjin's "select one other Attribute").
class AttributeIncreaseChoice {
  const AttributeIncreaseChoice({required this.amount, this.options = const []});

  final int amount;
  final List<DbuAttribute> options;
}

/// Structured form of a Race's Attribute Score Increase — re-parsed from the
/// verbatim `RaceDef.attributeIncreaseText` (kept unchanged as display
/// flavor) so `Character.scoreOf` can compute Attribute Scores directly
/// instead of the player applying the text by hand. [fixed] entries always
/// apply; each entry in [choices] contributes its `amount` only to whichever
/// Attribute the player picked for that slot (see
/// `Character.raceAttributeIncreaseChoices`).
class RaceAttributeIncrease {
  const RaceAttributeIncrease({this.fixed = const {}, this.choices = const []});

  final Map<DbuAttribute, int> fixed;
  final List<AttributeIncreaseChoice> choices;
}

class RaceDef {
  const RaceDef(
    this.name, {
    this.racialLifeModifier = 0,
    this.attributeIncreaseText = '',
    this.attributeIncrease = const RaceAttributeIncrease(),
    this.savingThrows = const [],
    this.skillRanks = 0,
  });

  final String name;

  /// Racial Life Modifier — added to Life Points for each Power Level.
  /// CONFIRMED against each Race's own page (verbatim "Racial Life
  /// Modifier. +N" line at the top of the page) — see `kDbuRaces`.
  final int racialLifeModifier;

  /// Verbatim "Attribute Score Increase" text from the Race's own page —
  /// still shown as flavor/reference text in the UI. The actual numbers
  /// used for calculation live in [attributeIncrease].
  final String attributeIncreaseText;

  /// Structured form of [attributeIncreaseText] — see `RaceAttributeIncrease`.
  final RaceAttributeIncrease attributeIncrease;

  /// Which Saving Throw(s) receive the Racial Saving Throw Bonus (+1(T) and
  /// -1 Critical Target — see `CharacterCalculator.racialSavingThrowBonus`).
  /// Almost every Race has exactly one; Neko Majin and Yardrat CONFIRMED have
  /// two.
  final List<DbuSavingThrow> savingThrows;

  /// Number of Racial Skill Ranks the player can freely place in any Skill(s)
  /// of their choice at Character Creation. CONFIRMED per-Race (verbatim
  /// "Skill Ranks: N" line).
  final int skillRanks;
}

/// The full playable Race catalogue (Player → Races on the live site, 18
/// Races + Custom Species), verified 04 July 2026. Every Racial Life
/// Modifier below is CONFIRMED verbatim from that Race's own page — this
/// corrected several values this app had wrong (Android, Arcosian, Majin,
/// Namekian) and added the 10 Races that were previously missing (Angel,
/// Cerealian, Demon, Glass Tribe, Heran, Konatsian, Neko Majin, Neo-Tuffle,
/// Shadow Dragon, Shinjin, Yardrat). The site's page titles are plural
/// (e.g. "Saiyans"); this app keeps the established singular convention
/// (e.g. "Saiyan") to match how a character's own Race is phrased.
///
/// Attribute Score Increase text, Racial Saving Throw(s) and Racial Skill
/// Ranks are now CONFIRMED for all 18 Races (verified 04 July 2026 against
/// each Race's own page header) — plus **Custom Species**, whose baseline row
/// comes from that page's "ARC Advice on Custom Species" block (verified 18
/// July 2026 against the live site) rather than being entered freeform by the
/// player. Full Racial Traits catalogues live in the sibling file
/// `race_traits.dart` (kept separate since that data is much larger and
/// display/automation-oriented rather than a simple lookup row).
const List<RaceDef> kDbuRaces = [
  RaceDef(
    'Android',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Both your Force and Tenacity scores are '
        'increased by +2 and your Insight score is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(fixed: {
      DbuAttribute.force: 2,
      DbuAttribute.tenacity: 2,
      DbuAttribute.insight: 1,
    }),
    savingThrows: [DbuSavingThrow.cognitive],
    skillRanks: 3,
  ),
  RaceDef(
    'Angel',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Your Insight score and your Agility score are '
        'increased by +2 and your Tenacity score is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(fixed: {
      DbuAttribute.insight: 2,
      DbuAttribute.agility: 2,
      DbuAttribute.tenacity: 1,
    }),
    savingThrows: [DbuSavingThrow.impulsive],
    skillRanks: 6,
  ),
  RaceDef(
    'Arcosian',
    racialLifeModifier: 5,
    attributeIncreaseText: 'Both your Tenacity and Agility scores are '
        'increased by +2 and your Force score is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(fixed: {
      DbuAttribute.tenacity: 2,
      DbuAttribute.agility: 2,
      DbuAttribute.force: 1,
    }),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 2,
  ),
  RaceDef(
    'Bio Android',
    racialLifeModifier: 3,
    attributeIncreaseText: 'Select two different Attributes and increase '
        "their scores by +2, select a third Attribute and increase its "
        "score by +1. You can't select both Force and Magic.",
    // The "not both Force and Magic" caveat on the two +2 picks is shown as
    // a hint in the UI, not enforced — matches this app's convention for
    // soft/narrative constraints (e.g. Talent/Factor prerequisites).
    attributeIncrease: RaceAttributeIncrease(choices: [
      AttributeIncreaseChoice(amount: 2),
      AttributeIncreaseChoice(amount: 2),
      AttributeIncreaseChoice(amount: 1),
    ]),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 3,
  ),
  RaceDef(
    'Cerealian',
    racialLifeModifier: 3,
    attributeIncreaseText: 'Both your Insight and Agility scores are '
        'increased by 2 and either your Force or Magic score is increased '
        'by 1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2, DbuAttribute.agility: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.impulsive],
    skillRanks: 3,
  ),
  RaceDef(
    'Demon',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Either your Force or Magic score and your '
        'Insight score are increased by +2 and your Personality score is '
        'increased by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2, DbuAttribute.personality: 1},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.cognitive],
    skillRanks: 3,
  ),
  RaceDef(
    'Earthling',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Both your Insight and either your Agility or '
        'Tenacity Scores are increased by +2. Increase your Scholarship or '
        'Personality Score by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.agility, DbuAttribute.tenacity],
        ),
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.scholarship, DbuAttribute.personality],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.morale],
    skillRanks: 4,
  ),
  RaceDef(
    'Glass Tribe',
    racialLifeModifier: 2,
    attributeIncreaseText: 'Your Insight score and your Tenacity score are '
        'increased by +2 and either your Force or Magic score is increased '
        'by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2, DbuAttribute.tenacity: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 4,
  ),
  RaceDef(
    'Heran',
    racialLifeModifier: 2,
    attributeIncreaseText: 'Your Tenacity Score and either your Force or '
        'Magic Score is increased by +2 and your Insight score is '
        'increased by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.tenacity: 2, DbuAttribute.insight: 1},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 3,
  ),
  RaceDef(
    'Konatsian',
    racialLifeModifier: 3,
    attributeIncreaseText: 'Your Insight score and your Personality score '
        'are increased by +2 and your Agility score is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(fixed: {
      DbuAttribute.insight: 2,
      DbuAttribute.personality: 2,
      DbuAttribute.agility: 1,
    }),
    savingThrows: [DbuSavingThrow.morale],
    skillRanks: 3,
  ),
  RaceDef(
    'Majin',
    racialLifeModifier: 3,
    attributeIncreaseText: 'Increase your Personality and either your '
        'Force or Magic Score by +2. Increase your Tenacity score by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.personality: 2, DbuAttribute.tenacity: 1},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.morale],
    skillRanks: 2,
  ),
  RaceDef(
    'Namekian',
    racialLifeModifier: 5,
    attributeIncreaseText: 'Both your Tenacity and Insight scores are '
        'increased by +2 and either your Force or Magic score is increased '
        'by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.tenacity: 2, DbuAttribute.insight: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 3,
  ),
  RaceDef(
    'Neko Majin',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Both your Personality and either your Force or '
        'Magic scores are increased by +2. Increase your Tenacity or '
        'Insight score by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.personality: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.tenacity, DbuAttribute.insight],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.cognitive, DbuSavingThrow.morale],
    skillRanks: 3,
  ),
  RaceDef(
    'Neo-Tuffle',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Both your Tenacity and Insight scores increase '
        'by +2, and increase either your Scholarship or Personality Score '
        'by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.tenacity: 2, DbuAttribute.insight: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.scholarship, DbuAttribute.personality],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.cognitive],
    skillRanks: 3,
  ),
  RaceDef(
    'Saiyan',
    racialLifeModifier: 3, // matches site Goku example
    attributeIncreaseText: 'Both your Force and Tenacity scores are '
        'increased by +2 and your Agility score is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(fixed: {
      DbuAttribute.force: 2,
      DbuAttribute.tenacity: 2,
      DbuAttribute.agility: 1,
    }),
    savingThrows: [DbuSavingThrow.corporeal],
    skillRanks: 2,
  ),
  RaceDef(
    'Shadow Dragon',
    racialLifeModifier: 7,
    attributeIncreaseText: 'Both your Tenacity and either your Force or '
        'Magic scores are increased by +2 and your Personality score is '
        'increased by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.tenacity: 2, DbuAttribute.personality: 1},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.morale],
    skillRanks: 2,
  ),
  RaceDef(
    'Shinjin',
    racialLifeModifier: 4,
    attributeIncreaseText: 'Both your Insight and either your Force or '
        'Magic scores are increased by +2. Select one other Attribute and '
        'increase its score by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 2,
          options: [DbuAttribute.force, DbuAttribute.magic],
        ),
        AttributeIncreaseChoice(amount: 1), // "select one other Attribute"
      ],
    ),
    savingThrows: [DbuSavingThrow.cognitive],
    skillRanks: 2,
  ),
  RaceDef(
    'Yardrat',
    racialLifeModifier: 1,
    attributeIncreaseText: 'Your Insight score and your Agility score are '
        'increased by +2 and either your Scholarship or Personality score '
        'is increased by +1.',
    attributeIncrease: RaceAttributeIncrease(
      fixed: {DbuAttribute.insight: 2, DbuAttribute.agility: 2},
      choices: [
        AttributeIncreaseChoice(
          amount: 1,
          options: [DbuAttribute.scholarship, DbuAttribute.personality],
        ),
      ],
    ),
    savingThrows: [DbuSavingThrow.cognitive, DbuSavingThrow.impulsive],
    skillRanks: 3,
  ),
  // Custom Species is a ruleset, not a Race, but the site's "ARC Advice on
  // Custom Species" block gives it a concrete baseline stat line, CONFIRMED
  // verbatim from the Custom Species page:
  //   "Attribute Score Increase. Select two different Attributes and increase
  //    them by +2, select a third Attribute and increase it by +1."
  //   "Racial Life Modifier. +3"
  //   "Saving Throw: Choose One (Impulsive, Cognitive, Corporeal or Morale)"
  //   "Skill Ranks: 2"
  // The Racial Life Modifier and Skill Ranks are BASE values — each Flaw Trait
  // taken raises one of them (see `CharacterCalculator.racialLifeModifier` /
  // `raceSkillRanks` and `Character.customFlawCompensation`). The Saving Throw
  // is a player pick (`Character.customSavingThrows`), so `savingThrows` is
  // left empty here — see `CharacterCalculator.raceSavingThrows`.
  RaceDef(
    'Custom Species',
    racialLifeModifier: 3,
    attributeIncreaseText: 'Select two different Attributes and increase them '
        'by +2, select a third Attribute and increase it by +1.',
    attributeIncrease: RaceAttributeIncrease(choices: [
      AttributeIncreaseChoice(amount: 2),
      AttributeIncreaseChoice(amount: 2),
      AttributeIncreaseChoice(amount: 1),
    ]),
    skillRanks: 2,
  ),
];

/// Look up a Race by name, falling back to a zero-modifier custom entry so the
/// calculator never crashes on an unknown/renamed race.
RaceDef raceByName(String name) {
  for (final r in kDbuRaces) {
    if (r.name == name) return r;
  }
  return RaceDef(name);
}

/// Power Level rules (Character Creation → Power Levels).
///
/// Power Level ranges from 1 to 30. Each PL maps to a Tier of Power (ToP), the
/// system's central scaling multiplier. The mapping is a simple table:
///   PL 1–4 → ToP 1, 5–9 → 2, 10–14 → 3, 15–19 → 4, 20–24 → 5, 25–29 → 6, 30 → 7
abstract final class PowerLevelRules {
  /// Lowest legal Power Level.
  static const int minPowerLevel = 1;

  /// Highest legal Power Level ("cannot exceed 30").
  static const int maxPowerLevel = 30;

  /// Returns the Tier of Power for a given Power Level, clamped to legal bounds.
  static int tierOfPower(int powerLevel) {
    final pl = powerLevel.clamp(minPowerLevel, maxPowerLevel);
    if (pl >= 30) return 7;
    // PL 1–4 → 1, then +1 for every full band of 5 levels starting at PL 5.
    return (1 + ((pl - 4 + 4) ~/ 5)).clamp(1, 7);
  }
}

/// The four kinds of Progression grant a Power Level can award (Character
/// Creation page, verbatim): "You can exchange a Character Perk for any of
/// the following options: Attribute Addition, Skill Improvement, or Talent
/// Addition." A `characterPerk` slot lets the player pick which of the other
/// three it becomes; the other three kinds are already concrete when the
/// Power Level Table lists them directly (e.g. PL3's "Attribute Addition").
enum ProgressionGrantKind {
  characterPerk('Character Perk'),
  attributeAddition('Attribute Addition'),
  talentAddition('Talent Addition'),
  skillImprovement('Skill Improvement');

  const ProgressionGrantKind(this.displayName);
  final String displayName;
}

/// The fixed grant slots awarded at one Power Level — see `kPowerLevelGrants`.
class PowerLevelGrants {
  const PowerLevelGrants(this.powerLevel, this.grants);

  final int powerLevel;
  final List<ProgressionGrantKind> grants;
}

/// The verbatim Power Level Table (Character Creation page, confirmed 05
/// July 2026): "The Power Level Table summarizes the advancement as you
/// increase in Power Levels from 1~30." Every row below is transcribed
/// directly from that table.
const List<PowerLevelGrants> kPowerLevelGrants = [
  PowerLevelGrants(1, [
    ProgressionGrantKind.characterPerk,
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(2, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(3, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(4, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(5, [
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(6, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(7, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(8, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(9, [ProgressionGrantKind.talentAddition]),
  PowerLevelGrants(10, [
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(11, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(12, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(13, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(14, [ProgressionGrantKind.talentAddition]),
  PowerLevelGrants(15, [
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(16, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(17, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(18, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(19, [ProgressionGrantKind.talentAddition]),
  PowerLevelGrants(20, [
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(21, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(22, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(23, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(24, [ProgressionGrantKind.talentAddition]),
  PowerLevelGrants(25, [
    ProgressionGrantKind.talentAddition,
    ProgressionGrantKind.attributeAddition,
    ProgressionGrantKind.skillImprovement,
  ]),
  PowerLevelGrants(26, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(27, [ProgressionGrantKind.attributeAddition]),
  PowerLevelGrants(28, [ProgressionGrantKind.characterPerk]),
  PowerLevelGrants(29, [ProgressionGrantKind.talentAddition]),
  PowerLevelGrants(30, [
    ProgressionGrantKind.characterPerk,
    ProgressionGrantKind.characterPerk,
    ProgressionGrantKind.characterPerk,
    ProgressionGrantKind.characterPerk,
    ProgressionGrantKind.characterPerk,
  ]),
];

/// The static grant slots for [pl] (empty for an out-of-range level).
List<ProgressionGrantKind> grantsForLevel(int pl) {
  for (final entry in kPowerLevelGrants) {
    if (entry.powerLevel == pl) return entry.grants;
  }
  return const [];
}

/// Skill Improvement grants +15 Technique Points (verbatim); the very first
/// Skill Improvement (PL1's direct table slot) grants an additional +10 TP
/// (+2 Skill Ranks) per the Power Level 1 special-case text — see
/// `CharacterCalculator.progressionTpThroughLevel`.
const int kSkillImprovementTp = 15;
const int kSkillImprovementFirstBonusTp = 10;

/// A Skill Improvement grants 4 Skill Ranks — verbatim: "Select 4 different
/// Skills, each one gains a Skill Rank." Because the four must be *different*
/// Skills, these Ranks never stack on one Skill.
const int kSkillImprovementRanks = 4;

/// The PL1 first Skill Improvement grants an additional 2 Skill Ranks on top
/// of the usual 4 (for 6 total) — verbatim: "an additional 2 Skill Ranks
/// (these Skill Ranks may be placed in the same Skill)". Only these 2 extra
/// Ranks are allowed to stack on an already-chosen Skill.
const int kSkillImprovementFirstBonusRanks = 2;

/// An Attribute Addition grants 2 Attribute Points to spend freely (verbatim).
const int kAttributeAdditionPoints = 2;

/// Karma Point rules (Z-Souls & Karma Points page).
///
/// CONFIRMED (verbatim): "At Character Creation, you possess 2 Karma Points."
/// / "You can possess up to 4 Karma Points." This replaces the old Google
/// Sheet's defaults, which used different starting/maximum values.
abstract final class KarmaRules {
  /// Karma Points a freshly created character starts with.
  static const int startingKarma = 2;

  /// Highest number of Karma Points a character can hold.
  static const int maxKarma = 4;
}

/// Dice Category progression and the three Tier-of-Power-scaled Extra Dice
/// pools (Core Rules page).
///
/// CONFIRMED (verbatim): "This means Dice Categories progress like so: 1d4,
/// 1d6, 1d8, 1d10, 1d10+1d4, 1d10+1d6, 1d10+1d8, 2d10, 2d10+1d4, 2d10+1d6…" —
/// groups of 4: within a group of `n` d10s, positions add nothing/1d4/1d6/1d8,
/// then the 4th position rolls over into `n+1` d10s.
///
///   • ToP Extra Dice (Extra Dice table, verbatim): ToP1 "–", ToP2 "+1d4",
///     ToP3 "+1d6", ToP4 "+1d8", ToP5 "+1d10", ToP6 "+1d10+1d4", ToP7
///     "+1d10+1d6" → category index = ToP-2 (ToP1 has none).
///   • Critical Dice (verbatim): "increase the Dice Score by 1d6. Increase
///     the Dice Category of this Extra Dice by 1 for every Tier of Power
///     reached after the first" → base 1d6 (index 1) at ToP1 → index = ToP.
///   • Greater Dice (verbatim): "start at a 1d4 at Tier of Power 1 and have
///     their Dice Category increased by 1 for each current Tier of Power
///     thereafter" → base 1d4 (index 0) at ToP1 → index = ToP-1.
///   • Healing Surge dice — CONFIRMED (Actions & Maneuvers page, verbatim:
///     "Healing Surge: You regain 2d10(T) Life Points."): 2d10 per current
///     Tier of Power → ToP1 "2d10", ToP2 "4d10", … (the old sheet's worked
///     example "2d10+1" at ToP1 with Force Modifier 1 matches).
abstract final class DiceRules {
  /// Formats the Dice Category at [index] (0-based) in the progression above.
  /// Indices below 0 mean "no dice" (shown by the callers as "–").
  static String categoryLabel(int index) {
    if (index < 0) return '–';
    final tens = index ~/ 4 + (index % 4 == 3 ? 1 : 0);
    final remainder = index % 4;
    if (tens == 0) {
      return '1${const ['d4', 'd6', 'd8', 'd10'][remainder]}';
    }
    if (remainder == 3) return '${tens}d10';
    final extra = const ['d4', 'd6', 'd8'][remainder];
    return '${tens}d10+1$extra';
  }

  /// ToP Extra Dice label added to Combat Rolls, e.g. "–" or "+1d10+1d4".
  static String extraDiceLabel(int tierOfPower) {
    final index = tierOfPower - 2;
    return index < 0 ? '–' : '+${categoryLabel(index)}';
  }

  /// Critical Dice label added on a Critical Result, e.g. "+1d6".
  static String criticalDiceLabel(int tierOfPower) =>
      '+${categoryLabel(tierOfPower)}';

  /// Greater Dice label (occasionally granted by effects), e.g. "+1d4".
  static String greaterDiceLabel(int tierOfPower) =>
      '+${categoryLabel(tierOfPower - 1)}';

  /// Healing Surge dice label — "2d10(T)" = 2d10 per current Tier of Power,
  /// e.g. ToP1 "2d10", ToP3 "6d10". CONFIRMED (see class doc).
  static String healingSurgeLabel(int tierOfPower) =>
      '${2 * tierOfPower.clamp(1, 99)}d10';

  /// The dice of the Dice Category at [index] (0-based) as a {sides: count}
  /// multiset — the structured form of [categoryLabel] (index 4 → {10:1, 4:1}).
  /// Below 0 = no dice. CONFIRMED (Core Rules Dice Category progression).
  static Map<int, int> categoryDice(int index) {
    if (index < 0) return const {};
    final tens = index ~/ 4 + (index % 4 == 3 ? 1 : 0);
    final remainder = index % 4;
    if (tens == 0) return {const [4, 6, 8, 10][remainder]: 1};
    if (remainder == 3) return {10: tens};
    return {10: tens, const [4, 6, 8][remainder]: 1};
  }
}

/// A multiset of dice — `{sides: count}`, e.g. `{10: 2, 6: 1}` = "2d10+1d6".
/// The structured form of a roll's Extra Dice, so Custom Buffs that add dice,
/// grant Greater Dice, or bump a Dice Category can be composed and then
/// rendered as one canonical string (see `CharacterCalculator.combatDicePool`).
class DicePool {
  DicePool([Map<int, int>? dice]) : dice = {...?dice};

  final Map<int, int> dice;

  /// The valid die sizes, largest-first (the site's canonical ordering, e.g.
  /// "2d10+1d6").
  static const List<int> sizes = [10, 8, 6, 4];

  void addDie(int side, [int count = 1]) {
    if (count == 0) return;
    final next = (dice[side] ?? 0) + count;
    if (next <= 0) {
      dice.remove(side);
    } else {
      dice[side] = next;
    }
  }

  void addPool(DicePool other) => other.dice.forEach(addDie);

  /// Adds the dice of Dice Category [index] (see `DiceRules.categoryDice`).
  void addCategory(int index) => DiceRules.categoryDice(index).forEach(addDie);

  int get totalDice => dice.values.fold(0, (a, b) => a + b);
  bool get isEmpty => totalDice == 0;

  /// "2d10+1d6" (largest die first); '' when empty.
  String get label {
    final parts = <String>[];
    for (final side in sizes) {
      final n = dice[side] ?? 0;
      if (n > 0) parts.add('${n}d$side');
    }
    return parts.join('+');
  }

  /// "+2d10+1d6" (leading '+'); '' when empty — for appending to a roll.
  String get suffix => isEmpty ? '' : '+$label';
}

/// Damage Categories (Damage & Recovery page) — how much of the target's Soak
/// applies when calculating Life Point loss from a Wound Roll.
///
/// CONFIRMED (verbatim): Standard "has no special qualities. All attacks do
/// Standard Damage unless otherwise stated."; Direct "only apply 1/2 of their
/// Soak when calculating Damage."; Lethal "bypasses a target's Soak
/// altogether; do not apply their Soak when calculating Damage."
enum DamageCategory {
  standard('Standard', 1.0),
  direct('Direct', 0.5),
  lethal('Lethal', 0.0);

  const DamageCategory(this.displayName, this.soakMultiplier);

  final String displayName;

  /// Fraction of Soak applied when reducing damage of this Category.
  final double soakMultiplier;
}

/// Defend Maneuver options relevant to the Damage Calculator (Actions &
/// Maneuvers page).
///
/// CONFIRMED (verbatim): Direct Hit "increas[es] your current Soak Value by
/// 1/2 for that Attacking Maneuver"; Guard "increases your Damage Reduction
/// by 1/4 (rounded up) of your Might."
enum ParryOption {
  none('None'),
  directHit('Direct Hit'),
  guard('Guard');

  const ParryOption(this.displayName);
  final String displayName;
}

/// The atomic effect channels a buff/automation can target. Racial
/// Traits/Talents/Transformations use the first block directly; the full
/// old-sheet Custom Buff dropdown (`CustomBuffTarget` in
/// `data/custom_buff_targets.dart`) resolves into the added channels below.
/// [manual] is a no-op channel for the few genuinely situational targets the
/// engine can't compute (State-granted dice, narrative toggles) — kept for
/// record-keeping only. (Dice-pool augmentation IS computed — see `DicePool`.)
enum AffectedStat {
  maxLife('Max Life'),
  maxKi('Max Ki'),
  maxCapacity('Max Capacity'),
  might('Might'),
  haste('Haste'),
  awareness('Awareness'),
  speedNormal('Speed (Normal)'),
  speedBoosted('Speed (Boosted)'),
  initiative('Initiative'),
  defenseValue('Defense Value'),
  soak('Soak'),
  strike('Strike'),
  dodge('Dodge'),
  woundPhysical('Wound (Physical)'),
  woundEnergy('Wound (Energy)'),
  woundMagic('Wound (Magic)'),
  impulsiveSave('Impulsive Save'),
  cognitiveSave('Cognitive Save'),
  corporealSave('Corporeal Save'),
  moraleSave('Morale Save'),

  /// Surgency (= Force Modifier) — feeds the Life/Ki restored by Surges
  /// (Healing Surge "+N" addend, Power Surge Ki).
  surgency('Surgency'),

  /// Passive Damage Reduction — fed into the Damage Calculator alongside
  /// Apparel/Weapon/Accessory Damage Reduction.
  damageReduction('Damage Reduction'),

  // ---- Atomic channels added for the full Custom Buff target list. Most map
  // 1:1 from a `CustomBuffTarget` (see data/custom_buff_targets.dart); the UI
  // never lists these directly. ----

  // Attribute Scores (feed `effectiveScore`, which flows into Modifiers,
  // Skill Bonuses, Initiative, Max Life via Tenacity, …).
  scoreAgility('AG Score'),
  scoreForce('FO Score'),
  scoreTenacity('TE Score'),
  scoreScholarship('SC Score'),
  scoreInsight('IN Score'),
  scoreMagic('MA Score'),
  scorePersonality('PE Score'),

  // Attribute Modifiers only (combat math; not Score-derived Skills/Initiative).
  modAgility('AG Modifier'),
  modForce('FO Modifier'),
  modTenacity('TE Modifier'),
  modScholarship('SC Modifier'),
  modInsight('IN Modifier'),
  modMagic('MA Modifier'),
  modPersonality('PE Modifier'),

  // Progression / Tier.
  tpPerSkillImprovement('TP per Skill Improvement'),
  topBreakthrough('ToP (Breakthrough)'),

  // Pools — ±¼ channels add N quarters of the pool's own maximum.
  maxLifeQuarter('Max Life ±1/4'),
  maxKiQuarter('Max Ki ±1/4'),
  maxCapacityQuarter('Max Capacity ±1/4'),
  racialLifeModifier('Racial Life Modifier'),

  // Defense.
  doubleBaseSoak('Double Base Soak'),

  // Super Stacks / range.
  superStacks('Super Stacks'),
  powerBurstSuperStacks('Power Burst S. Stacks'),
  noSuperStackPenalty('No Super Stack Pen.'),
  longRangeDistance('Long Range Distance'),

  // Critical Targets (a negative value lowers the Crit Target — floored at 7).
  strikeCriticalTarget('Strike CT'),
  dodgeCriticalTarget('Dodge CT'),
  woundPhysicalCriticalTarget('Wound CT (Physical)'),
  woundEnergyCriticalTarget('Wound CT (Energy)'),
  woundMagicCriticalTarget('Wound CT (Magic)'),

  // Per-Foundation Strike (applied in the References Attack Reference to a
  // matching-Foundation attack, like per-Foundation Wound).
  strikePhysical('Strike (Physical)'),
  strikeEnergy('Strike (Energy)'),
  strikeMagic('Strike (Magic)'),
  strikePhysicalCriticalTarget('Strike CT (Physical)'),
  strikeEnergyCriticalTarget('Strike CT (Energy)'),
  strikeMagicCriticalTarget('Strike CT (Magic)'),

  // Might / stress / duel.
  mightForClashes('Might for Clashes'),
  stressBonus('Stress Bonus'),
  thresholdBreaker('Threshold Breaker'),
  duelClashBonus('Duel Clash Bonus'),

  // Speed.
  speedNormalQuarter('Normal Speed ±1/4'),
  speedBoostedQuarter('Boosted Speed ±1/4'),
  halveNormalSpeed('Halve Normal Speed'),
  halveBoostedSpeed('Halve Boosted Speed'),

  // Size / penalty-exclusions.
  sizeCategory('Size Category'),
  noStrikePenalties('No Strike Penalties'),
  noDodgePenalties('No Dodge Penalties'),
  noWoundPenalties('No Wound Penalties'),

  // Skill groups (all Skills of an Attribute) + individual Skills.
  skillGroupAgility('Agility Skills'),
  skillGroupForce('Force Skills'),
  skillGroupScholarship('Scholarship Skills'),
  skillGroupInsight('Insight Skills'),
  skillGroupMagic('Magic Skills'),
  skillGroupPersonality('Personality Skills'),
  skillAcrobatics('Acrobatics'),
  skillBluff('Bluff'),
  skillClairvoyance('Clairvoyance'),
  skillConcealment('Concealment'),
  skillCraft('Craft'),
  skillCreatureHandling('Creature Handling'),
  skillIntimidation('Intimidation'),
  skillIntuition('Intuition'),
  skillInvestigation('Investigation'),
  skillKnowledge('Knowledge'),
  skillMedicine('Medicine'),
  skillPerception('Perception'),
  skillPerformance('Performance'),
  skillPersuasion('Persuasion'),
  skillPilot('Pilot'),
  skillStealth('Stealth'),
  skillSurvival('Survival'),
  skillThievery('Thievery'),
  skillUseMagic('Use Magic'),
  hypeManeuver('Hype Maneuver'),
  analysisInvestigation('Analysis Maneuver (Investigation)'),
  analysisIntuition('Analysis Maneuver (Intuition)'),

  // Armed / Unarmed attack modifiers (References Attack Reference).
  armedStrike('Armed Strike'),
  armedWound('Armed Wound'),
  unarmedStrike('Unarmed Strike'),
  unarmedWound('Unarmed Wound'),

  // Ki Point Costs (a negative value reduces the cost).
  kiCostAttacks('Ki Point Cost Attacks'),
  kiCostAttacksNoCap('Ki Point Cost Attacks (no cap)'),
  kiCostUniqueAbilities('Ki Point Cost Unique Abilities'),
  kiCostUniqueAbilitiesMagical('Ki Point Cost Unique Abilities (Magical)'),
  kiCostUniqueAbilitiesTechnical('Ki Point Cost Unique Abilities (Technical)'),
  attackingDamageCategory('Attacking Damage Category'),

  // ---- Dice-pool augmentation (feeds `CharacterCalculator.combatDicePool` and
  // the References roll expressions). "All" applies to every Combat Roll; the
  // scoped channels add to a single roll on top of "All". ----
  // Category increase to the Tier-of-Power Extra Dice.
  topDiceCategoryAll('ToP Extra Dice Cat.'),
  topDiceCategoryStrike('ToP Extra Dice Cat. (Strike)'),
  topDiceCategoryDodge('ToP Extra Dice Cat. (Dodge)'),
  topDiceCategoryWound('ToP Extra Dice Cat. (Wound)'),
  // Additional instances of the ToP Extra Dice (capped at +1 by the rules).
  extraTopDiceAll('ToP Extra Dice (All)'),
  extraTopDiceStrike('ToP Extra Dice (Strike)'),
  extraTopDiceDodge('ToP Extra Dice (Dodge)'),
  extraTopDiceWound('ToP Extra Dice (Wound)'),
  // Granted Greater Dice (count) + their Category increase.
  greaterDiceAll('Greater Dice (All)'),
  greaterDiceStrike('Greater Dice (Strike)'),
  greaterDiceDodge('Greater Dice (Dodge)'),
  greaterDiceWound('Greater Dice (Wound)'),
  greaterDiceCategory('Greater Dice Category'),
  // Flat Extra Dice by size.
  flatD4All('Extra d4 (Combat Rolls)'),
  flatD6All('Extra d6 (Combat Rolls)'),
  flatD8All('Extra d8 (Combat Rolls)'),
  flatD10All('Extra d10 (Combat Rolls)'),
  flatD4Strike('Extra d4 (Strike)'),
  flatD6Strike('Extra d6 (Strike)'),
  flatD8Strike('Extra d8 (Strike)'),
  flatD10Strike('Extra d10 (Strike)'),
  flatD4Dodge('Extra d4 (Dodge)'),
  flatD6Dodge('Extra d6 (Dodge)'),
  flatD8Dodge('Extra d8 (Dodge)'),
  flatD10Dodge('Extra d10 (Dodge)'),
  flatD4Wound('Extra d4 (Wound)'),
  flatD6Wound('Extra d6 (Wound)'),
  flatD8Wound('Extra d8 (Wound)'),
  flatD10Wound('Extra d10 (Wound)'),
  energyChargeDiceCategory('Energy Charge Dice Category'),

  // ---- Signature-attack dice (applied in the References Attack Reference only
  // when the referenced attack is one of the character's Signatures). ----
  signatureStrikeFlat('Signature Strike'),
  signatureWoundFlat('Signature Wound'),
  signatureStrikeCriticalTarget('Signature CT (Strike)'),
  signatureWoundCriticalTarget('Signature CT (Wound)'),
  signatureExtraTopAll('Signature Extra ToP Dice (All)'),
  signatureExtraTopStrike('Signature Extra ToP Dice (Strike)'),
  signatureExtraTopWound('Signature Extra ToP Dice (Wound)'),
  signatureFlatD4All('Signature d4 (All)'),
  signatureFlatD6All('Signature d6 (All)'),
  signatureFlatD8All('Signature d8 (All)'),
  signatureFlatD10All('Signature d10 (All)'),
  signatureFlatD4Strike('Signature d4 (Strike)'),
  signatureFlatD6Strike('Signature d6 (Strike)'),
  signatureFlatD8Strike('Signature d8 (Strike)'),
  signatureFlatD10Strike('Signature d10 (Strike)'),
  signatureFlatD4Wound('Signature d4 (Wound)'),
  signatureFlatD6Wound('Signature d6 (Wound)'),
  signatureFlatD8Wound('Signature d8 (Wound)'),
  signatureFlatD10Wound('Signature d10 (Wound)'),
  signatureEnergyChargeDiceCategory('Signature Energy Charge Dice Category'),

  /// Toggle: the character is being targeted by a Bludgeoning Weapon — the
  /// Damage Calculator ignores ½ of their Damage Reduction.
  beingBludgeoned("I'm being Bludgeoned"),

  /// A catch-all channel for Custom Buff targets whose effect this app can't
  /// yet compute (dice-pool augmentation, narrative toggles). The buff is kept
  /// for record-keeping and shown as "manual — apply yourself"; it feeds no
  /// derived stat. (See data/custom_buff_targets.dart for which map here.)
  manual('Manual (not auto-applied)');

  const AffectedStat(this.displayName);
  final String displayName;
}

/// Capacity/Super Stack rules (Core Rules page).
///
/// CONFIRMED (verbatim): "You can possess up to 3 Super Stacks." / "For each
/// Super Stack you possess, reduce your Strike and Dodge Rolls by 1(bT). If
/// you possess 3 Super Stacks, increase your Muscle Penalty by an additional
/// 1(bT)." / "For each Super Stack you possess, increase your Soak Value by
/// 1(bT)." / "apply 1/4 of your Force Modifier to the Wound Rolls of your
/// Physical and Energy Attacks for each stack" — floored, per the Core Rules'
/// global "Round Down" rule (verbatim: "When you divide any value, if it
/// reaches a fraction, then it is rounded down, unless otherwise stated").
abstract final class CapacityRules {
  static const int maxSuperStacks = 3;
}

/// Melee/Long Range rules (Attacking + Size pages).
///
/// CONFIRMED (verbatim, Size page table): every Size from Nano up through
/// Large has "Adjacent" Melee Range (Small/Medium/Large — the sizes
/// selectable at creation — all show "Adjacent", so it's a true constant for
/// this app's purposes). The full table for the larger, effect-granted Sizes:
/// Enormous "Adjacent +1 Squares", Gigantic "Adjacent +3 Squares", Colossal
/// "Adjacent +6 Squares". Long Range is confirmed: "9+
/// Squares away from your Character", with a "Reduce your Strike Rolls
/// against any Character at Long Range by 2(bT)" penalty — situational
/// (depends on the target's distance, which this app doesn't track), shown
/// as reference info only.
abstract final class RangeRules {
  /// CONFIRMED (Size page table): Adjacent for every Size this app offers.
  static const String meleeReachLabel = 'Adjacent (1 sq.)';

  static const String longRangeLabel = '9+ sq.';

  /// Strike Roll penalty per Base Tier of Power against a Long Range target.
  static const int longRangePenaltyPerBaseTier = 2;
}

/// The Resources every character has access to by default, regardless of
/// Race/Talents — as opposed to the many Talent/Trait-granted Resources
/// (Perfect Points, Talismans, ...) which are freeform-tracked instead (see
/// `TrackedEntry` in models/character.dart) since their full catalogue is a
/// future milestone.
///
/// CONFIRMED (Actions & Maneuvers page, verbatim, Power Up Maneuver — a
/// Standard Maneuver available to all characters): "Gain a stack of Power
/// until the end of your next turn; if you already possess a stack of Power,
/// you may remove a stack of Power before applying this effect. For each
/// stack of Power, increase your Combat Rolls by 1(T) and your Max Capacity
/// by 1/4 (this increase to your Max Capacity only applies for the first 2
/// stacks of Power)." / "Power is a Resource and you cannot possess more
/// than 2 stacks of Power."
///
/// CONFIRMED (Attacking page, verbatim) — universal per-round combat
/// attrition trackers, not technically Resources but co-located here as the
/// old sheet did:
///   • Diminishing Offense: "for each Attacking Maneuver you make after your
///     third during this Combat Round, gain a stack of Diminishing Offense.
///     Each stack of Diminishing Offense reduces the Strike Rolls of your
///     Attacking Maneuvers by 1(bT). At the end of the Combat Round, lose
///     all stacks of Diminishing Offense."
///   • Diminishing Defense: "After each Attacking Maneuver that has targeted
///     you, gain a stack of Diminishing Defense – each stack of Diminishing
///     Defense reduces the Dice Score of your Dodge Rolls by 1 [flat, not
///     Tier-scaled]. Increase the number of Diminishing Defense stacks you
///     gain by 1 for every 2 base Tier of Power reached after Tier of Power
///     1. At the start of each Combat Round, remove all stacks of
///     Diminishing Defense." The "strange" scaling is in how many stacks
///     you GAIN per hit (the per-stack Dodge penalty itself stays flat -1):
///
///       Base Tier of Power | Stacks gained per Attacking Maneuver
///       1~2                | 1
///       3~4                | 2
///       5~6                | 3
///       7                  | 4
///
///     — see `diminishingDefenseStacksPerHit`.
abstract final class DefaultResourceRules {
  static const int maxPowerStacks = 2;

  /// How many Diminishing Defense stacks a character gains each time they're
  /// targeted by an Attacking Maneuver, per the table above. Purely
  /// informational — this app doesn't track individual hits, so the stack
  /// count itself remains a manual stepper the player updates.
  static int diminishingDefenseStacksPerHit(int baseTierOfPower) =>
      (baseTierOfPower.clamp(1, 7) - 1) ~/ 2 + 1;
}

/// How a Condition's automated per-stack penalty scales, matching the site's
/// (T)/(bT) notation: `current` = current Tier of Power, `base` = Base Tier
/// of Power, `none` = flat regardless of Tier.
enum TierScaling { none, current, base }

/// Shared shape for the Conditions and States catalogues, so the tracked-list
/// UI (see `character_edit_screen.dart`) can render either one without
/// knowing which it's showing.
abstract class CatalogDef {
  String get name;
  int get maxStacks;

  /// Verbatim (or near-verbatim) flavour + effect text from the site —
  /// pre-fills a `TrackedEntry.notes` when this entry is selected.
  String get description;

  /// Whether ANY part of this entry's effect is auto-applied to a stat this
  /// app computes.
  bool get isAutomated;
}

/// A single Combat Condition from the Thresholds & Conditions page's
/// catalogue. Mirrors `SkillDef`/`RaceDef`'s role as static rules data.
///
/// Most Conditions are NOT automated here — many rely on mechanics this app
/// doesn't model (multiplicative Speed/Capacity reduction, per-turn Life
/// loss, "Natural Result" die adjustments, pure Action-economy/behavioural
/// restrictions). Only the handful whose effect maps cleanly onto an
/// existing additive Aptitude/Combat Roll (see [affectedStats]) are
/// auto-applied; the rest still get their full effect text as [description]
/// so the player always has the rules on hand, they just apply the number
/// themselves.
class ConditionDef implements CatalogDef {
  const ConditionDef(
    this.name, {
    this.maxStacks = 1,
    required this.description,
    this.affectedStats = const [],
    this.magnitudePerStack = 0,
    this.tierScaling = TierScaling.none,
  });

  @override
  final String name;
  @override
  final int maxStacks;

  @override
  final String description;

  /// Which Aptitudes/Combat Rolls this Condition automatically penalizes
  /// per stack. Empty = not automated (see class doc).
  final List<AffectedStat> affectedStats;

  /// Base penalty per stack, before Tier scaling.
  final int magnitudePerStack;
  final TierScaling tierScaling;

  @override
  bool get isAutomated => affectedStats.isNotEmpty;
}

/// The 18 current Combat Conditions (Thresholds & Conditions page, verified
/// 03 July 2026). CONFIRMED automated effects (verbatim):
///   • Broken [S] (Max 3): "reduce your Soak Value by 2(bT) after all other
///     reductions." (The extra "convert excess into bonus Damage" clause is
///     NOT automated — it needs the Damage Calculator to know this specific
///     Condition applied, which is a future refinement.)
///   • Guard Down: "Reduce your Dodge Rolls ... by 2(T)." (Its Parry-Strike
///     and Ki-cost clauses aren't automated — this app doesn't track which
///     Defend option was used.)
///   • Shaken: "reduce your Strike Rolls by 2(T)."
///   • Transfigured: "have their Combat Rolls reduced by 2(bT)."
const List<ConditionDef> kDbuConditions = [
  ConditionDef(
    'Blinded',
    description: 'For one reason or another, you cannot see for a short '
        'period.\n'
        'Effect: While you have this Combat Condition, suffer from the '
        'effects of the Blinding Light Level, regardless of what the '
        'current Light Level is.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Broken',
    maxStacks: 3,
    description: 'Your durability is reduced, potentially due to flames '
        'wearing away at your body or due to your body being forcefully '
        'tampered with.\n'
        'Effect: For each stack of this Combat Condition, reduce your '
        'Soak Value by 2(bT) after all other reductions. If the '
        'reduction to your Soak Value exceeds your Soak Value before '
        'applying this penalty, increase any Damage you take from '
        'Attacking Maneuvers by the difference.\n'
        '(Only the Soak Value reduction is automated)',
    affectedStats: [AffectedStat.soak],
    magnitudePerStack: 2,
    tierScaling: TierScaling.base,
  ),
  ConditionDef(
    'Compelled',
    description: 'You have lost control of yourself.\n'
        'Effect: When you gain this Combat Condition, you will be given '
        'a target – you can only make Attacking Maneuvers that include '
        'the target as a target for that Attacking Maneuver. If you do '
        'not spend at least 2 Actions (1 Action if you are a Minion) '
        'making Attacking Maneuvers that include that Character as a '
        'Target during each of your turns while you are suffering from '
        'this Combat Condition, reduce your Life Points by 1/10 of your '
        'Maximum Life Points at the end of your turn. Additionally, you '
        'must Ki Wager at least 1/10 (rounded up) of your Max Capacity '
        'on all Attacking Maneuvers against that target and all Combat '
        'Rolls for Attacking Maneuvers made against that target become '
        'Urgent.\n'
        'If your target becomes Hidden to you, change your target for '
        'the effects of Compelled to the closest Character to you '
        'other than your previous target.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Drained',
    description: 'Having been drained of energy, you have a harder time '
        'replenishing the energy you\'ve lost.\n'
        'Effect: Halve your Surgency and increase the Ki Point Cost of '
        'all Attacking Maneuvers by 2(T).\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Fatigued',
    maxStacks: 2,
    description: 'You are exhausted, unable to draw out your full '
        'strength.\n'
        'Effect: For each stack of this Combat Condition, halve your '
        'Max Capacity.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Guard Down',
    description: 'Flat-footed, pushed over, or in any situation that '
        'limits your defense, you become vulnerable.\n'
        'Effect: Reduce your Dodge Rolls and all Strike Rolls made '
        'through the Parry option of the Defend Maneuver by 2(T). '
        'Additionally, increase the Ki Point Cost of the Guard option '
        'of the Defend Maneuver by 1/2 (after all other calculations).\n'
        '(Only the Dodge Rolls penalty is automated)',
    affectedStats: [AffectedStat.dodge],
    magnitudePerStack: 2,
    tierScaling: TierScaling.current,
  ),
  ConditionDef(
    'Impaired',
    maxStacks: 3,
    description: 'You are impeded from succeeding in your goals by some '
        'means, be it a curse of bad luck or a physical obstacle '
        'keeping you from moving the way you want to.\n'
        'Effect: Reduce the Natural Result of your Combat Rolls by the '
        'number of Impaired Stacks you possess.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Impediment',
    description: 'A catch-all combat condition that reflects a '
        'worsened mental state.\n'
        'Effect: Do not apply your Tier of Power Extra Dice (this only '
        'applies to a single instance of Tier of Power Extra Dice — '
        'meaning that if you apply multiple instances through effects, '
        'you only remove a single instance of them). If you do not '
        'possess Tier of Power Extra Dice, reduce your Combat Rolls by '
        '2(bT) instead.\n'
        'Impediment has a unique interaction with the Superior State. '
        'If you are in the Superior State while suffering from the '
        'Impediment Combat Condition, ignore the effects of the '
        'Impediment Combat Condition, but also ignore the first effect '
        'of the Superior State.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Pinned',
    description: 'You are, for one reason or another, stuck in place '
        'and unable to move properly.\n'
        'Effect: Upon gaining this Combat Condition, reduce your '
        'remaining Actions this Combat Round to 1 if you had more '
        'Actions. You only gain 1 Action each Combat Round and cannot '
        'use any Attacking Maneuvers or any effects that allow '
        'Movement.\n'
        'A Pinned Character can spend 1 Action during their turns to '
        'make a Might Clash against the Character who inflicted the '
        'Combat Condition. If they win, they stop being Pinned and '
        'regain their lost Actions. This effect can be repeated as '
        'much as the Pinned Character desires.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Poisoned',
    description: 'Poison flows through your veins, reducing your '
        'ability to fight and sapping away your health.\n'
        'Effect: At the end of each of your turns, lose Life Points '
        'equal to 1/10 of your Maximum Life Points. Additionally, '
        'double any Health Threshold Penalties you suffer from.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Prone',
    description: 'You\'re placed onto the floor, making it difficult '
        'to move or fight back.\n'
        'Effect: Reduce your Speed, Defense Value, and Haste by 1/2 '
        'and increase the Damage Category of all Damage you receive '
        'from Attacking Maneuvers by 1. During your turn, you can '
        'spend 1 Action to stand up and remove the Prone Combat '
        'Condition.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Shaken',
    description: 'Wrought with fear, you cannot fight properly.\n'
        'Effect: You cannot willingly use any effect to move towards '
        'the Character that inflicted this Combat Condition. '
        'Additionally, reduce your Strike Rolls by 2(T).\n'
        '(Only the Strike Rolls penalty is automated)',
    affectedStats: [AffectedStat.strike],
    magnitudePerStack: 2,
    tierScaling: TierScaling.current,
  ),
  ConditionDef(
    'Sleeping',
    description: 'You have been rendered unconscious and thus, unable '
        'to fight.\n'
        'Effect: A Character who is Sleeping cannot use any '
        'Maneuvers, has their Perception and Clairvoyance Skill '
        'Bonuses reduced by 2, and is hit automatically by any '
        'Attacking Maneuver that targets them. If a Sleeping Character '
        'has their Life Points reduced by Damage from an Attacking '
        'Maneuver, Collision Damage, Damage Over Time, the Poisoned '
        'Combat Condition, the Compelled Combat Condition, or any '
        'other Character\'s effects, a Sleeping Character immediately '
        'loses the Sleeping Combat Condition.\n'
        'A Character who is Sleeping, when targeted by an Attacking '
        'Maneuver, can spend a Karma Point to not be automatically hit '
        'and defend normally (they may also use a Counter Maneuver for '
        'the duration of that Attacking Maneuver). An Ally can also '
        'spend a Karma Point to wake a Sleeping Ally as an Instant '
        'Maneuver.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Slowed',
    maxStacks: 3,
    description: 'Your ability to move and fight is reduced to a '
        'crawl, if not a complete standstill.\n'
        'Effect: For each stack of this Combat Condition, you have 1 '
        'less Action during each Combat Round and reduce your Speeds '
        'by 1/4. This effect applies immediately (meaning you lose a '
        'number of Actions equal to the number of Slowed stacks you '
        'gained). If you have 3 stacks of Slowed, you cannot use any '
        'form of Maneuver (including those that cost Counter Actions) '
        'and your turn in Initiative is skipped.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Staggered',
    description: 'You are dazed and unable to move.\n'
        'Effect: You cannot use the Movement Maneuver, the Soar '
        'Maneuver, or move through your own effects.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Stress Exhaustion',
    description: 'The stress of your Transformations catch up to '
        'you, rendering you exhausted.\n'
        'Effect: Upon gaining this Combat Condition, return to your '
        'Normal State and halve your Ki Points if you were benefiting '
        'from the effects of Ki Multiplier. While suffering from this '
        'Combat Condition, you cannot enter any Enhancement or Form.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Suffocating',
    description: 'You cannot breathe.\n'
        'Effect: Reduce your Life Points by 1/5 of your Maximum Life '
        'Points at the end of each of your turns.\n'
        '(Not automated)',
  ),
  ConditionDef(
    'Transfigured',
    description: 'You have been transformed into an object, unable to '
        'fight as effectively as normal.\n'
        'Effect: A Transfigured Character has their Combat Rolls '
        'reduced by 2(bT) and cannot use any Signature Techniques or '
        'Unique Abilities, and can only make Attacking Maneuvers of '
        'the Physical Attack Type.\n'
        '(Only the Combat Rolls penalty is automated)',
    affectedStats: [
      AffectedStat.strike,
      AffectedStat.dodge,
      AffectedStat.woundPhysical,
      AffectedStat.woundEnergy,
      AffectedStat.woundMagic,
    ],
    magnitudePerStack: 2,
    tierScaling: TierScaling.base,
  ),
];

/// Looks up a Condition by name, or `null` if it's a custom/homebrew entry
/// not in the official catalogue (still trackable, just un-automated).
ConditionDef? conditionDefByName(String name) {
  for (final c in kDbuConditions) {
    if (c.name == name) return c;
  }
  return null;
}

/// A single Trait unlocked at a given Level of a State. Traits remain active
/// for every Level the character currently has at or above [level] — States
/// page, verbatim: "You have access to all of the State Traits equal to or
/// less than the State's current Level." Where a Trait's magnitude scales
/// with L, CONFIRMED (verbatim): "L is a number equal to the current Level
/// of the State you are in" — i.e. a Level-1 Trait still active at Level 3
/// uses L=3, not L=1.
///
/// [coefficientPerLevel] carries the sign (positive = buff, negative =
/// debuff); the final per-stat contribution is
/// `coefficientPerLevel × currentLevel × tierScalingValue`, added directly
/// (unlike Conditions, States can buff as often as they debuff).
class StateTraitDef {
  const StateTraitDef({
    this.level = 1,
    this.affectedStats = const [],
    this.coefficientPerLevel = 0,
    this.tierScaling = TierScaling.none,
    this.ignoresHealthThresholdPenalties = false,
  });

  /// The State Level required to unlock this Trait (1 for States with no
  /// Level system).
  final int level;

  final List<AffectedStat> affectedStats;
  final int coefficientPerLevel;
  final TierScaling tierScaling;

  /// Whether this Trait nullifies Health Threshold penalties outright (e.g.
  /// "Ignore any Health Threshold Penalties") — this app's existing
  /// Threshold-penalty pipeline (see `CharacterCalculator`) already computes
  /// a number, so this is a clean flag rather than an [affectedStats] entry.
  final bool ignoresHealthThresholdPenalties;

  bool get isAutomated =>
      affectedStats.isNotEmpty || ignoresHealthThresholdPenalties;
}

/// A State from the States page (base States, each with a Narrative
/// Requirement and — for three of them — multiple Levels) or the Special
/// States page (effect-only, no Narrative Requirement, more "physical"
/// transformations).
///
/// Most States are NOT automated here — many rely on mechanics this app
/// doesn't model (bypassing Clashes entirely, Dice Category bonuses,
/// targeting/Focus restrictions, per-Round/Encounter action economy, or
/// granting effects to an ALLY rather than the character themselves). Only
/// Traits whose effect maps cleanly onto an existing additive Aptitude/
/// Combat Roll, or this app's own Health-Threshold-penalty computation, are
/// auto-applied (see [traits]).
class StateDef implements CatalogDef {
  const StateDef(
    this.name, {
    this.maxLevel = 1,
    required this.description,
    this.traits = const [],
  });

  @override
  final String name;

  /// Number of Levels this State has. CONFIRMED (verbatim): "the amount of
  /// Levels they can possess being shown in brackets after the name of the
  /// State" — 1 means no Level system (the State is simply active or not).
  final int maxLevel;

  @override
  int get maxStacks => maxLevel;

  @override
  final String description;

  final List<StateTraitDef> traits;

  @override
  bool get isAutomated => traits.any((t) => t.isAutomated);
}

/// The 6 base States (States page) + 5 Special States (Special States page),
/// verified 04 July 2026. CONFIRMED automated Traits (verbatim):
///   • Raging: Angry (L1) "increase the Wound Rolls of your Attacking
///     Maneuvers by L(T)"; Furious (L2) "increase your Soak Value by L(T)";
///     Apoplectic (L3) "Ignore any Health Threshold Penalties."
///   • Mindful: Calm (L1) "Reduce the Wound Rolls of your Attacking
///     Maneuvers by L(T)"; Tranquil (L3) "Ignore any Health Threshold
///     Penalties."
///   • Undying: "Reduce your Combat Rolls by 1(T)."
///   • Determined: "You ignore the penalties of any Health Thresholds."
/// Superior, Surging, Entrusted, Liquid, Multiple Arms, Invisible and
/// Spectator have NO automated Traits (Dice-Category bonuses, "damage
/// taken" increases, targeting/Focus restrictions, Skill Check bonuses and
/// ally-targeted effects aren't modeled by this app).
const List<StateDef> kDbuStates = [
  StateDef(
    'Raging',
    maxLevel: 3,
    description: 'Narrative Requirement: A boiling rage, driven by some '
        'kind of intense fury related to your Z-Soul.\n'
        'Angry (Level 1): (1) Increase the Wound Rolls of your Attacking '
        'Maneuvers by L(T) (automated). (2) Increase the Botch Range of '
        'your Strike Rolls, Dodge Rolls, Saving Throws, and Skill Checks '
        'by L (not automated).\n'
        'Furious (Level 2): Increase your Soak Value by L(T) (automated).\n'
        'Apoplectic (Level 3): (1) You may use the Basic Attack Maneuver '
        'as an Out-of-Sequence Maneuver once per Round (not automated). '
        '(2) Ignore any Health Threshold Penalties (automated).',
    traits: [
      StateTraitDef(
        level: 1,
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficientPerLevel: 1,
        tierScaling: TierScaling.current,
      ),
      StateTraitDef(
        level: 2,
        affectedStats: [AffectedStat.soak],
        coefficientPerLevel: 1,
        tierScaling: TierScaling.current,
      ),
      StateTraitDef(level: 3, ignoresHealthThresholdPenalties: true),
    ],
  ),
  StateDef(
    'Mindful',
    maxLevel: 3,
    description: 'Narrative Requirement: A serene calm, a conscious effort '
        'to suppress one\'s emotions to stop them running rampant.\n'
        'Calm (Level 1): (1) Reduce the Critical Target of your Combat '
        'Rolls, Saving Throws, and Skill Checks by L (not automated). '
        '(2) Reduce the Wound Rolls of your Attacking Maneuvers by L(T) '
        '(automated).\n'
        'Zen (Level 2): If you use a Counter Maneuver, regain 2L(bT) Ki '
        'Points (not automated).\n'
        'Tranquil (Level 3): (1) Gain 1 Counter Action at the start of each '
        'Combat Round (not automated). (2) Ignore any Health Threshold '
        'Penalties (automated).',
    traits: [
      StateTraitDef(
        level: 1,
        affectedStats: [
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficientPerLevel: -1,
        tierScaling: TierScaling.current,
      ),
      StateTraitDef(level: 3, ignoresHealthThresholdPenalties: true),
    ],
  ),
  StateDef(
    'Superior',
    description: 'Narrative Requirement: A clear focus achieved through a '
        'sense of elation and intense hunger for victory beyond your usual '
        'self, what most would describe as \'entering the zone\'. '
        '(1) Apply Greater Dice to your Combat Rolls (not automated — '
        'dice-based). (2) Increase the Damage you would receive from an '
        'Opponent\'s Attacking Maneuver by 2(T) (not automated).',
  ),
  StateDef(
    'Undying',
    description: 'Narrative Requirement: Pure determination fuels you, '
        'allowing you to keep fighting beyond what would normally kill '
        'others. (1) You cannot be Defeated but Damage can reduce your '
        'Life Points into negative values; if negative when you leave this '
        'State, you are immediately Defeated (not automated). (2) If you '
        'enter this State from an effect that would have Defeated you, set '
        'your Life Points to 1 (not automated). (3) Reduce your Combat '
        'Rolls by 1(T) (automated).',
    traits: [
      StateTraitDef(
        affectedStats: [
          AffectedStat.strike,
          AffectedStat.dodge,
          AffectedStat.woundPhysical,
          AffectedStat.woundEnergy,
          AffectedStat.woundMagic,
        ],
        coefficientPerLevel: -1,
        tierScaling: TierScaling.current,
      ),
    ],
  ),
  StateDef(
    'Surging',
    description: 'Narrative Requirement: An intent desire to inflict harm '
        'on a single individual out of desperation. A threat of immense '
        'danger to yourself or an ally is required. Targets an Opponent as '
        'your \'Focus\' and Energy Charges Attacking Maneuvers against '
        'them; you can only target your Focus; gain a Fatigued stack on '
        'leaving; immune to Compelled; may leave early on defeating your '
        'Focus. (Not automated — targeting/Focus mechanics.)',
  ),
  StateDef(
    'Determined',
    description: 'Narrative Requirement: A great need that shifts away all '
        'reason, directing all of your energy into this one moment. You '
        'have blocked out everything but the battle before you. '
        '(1) Your Attacking Maneuvers automatically hit their targets, '
        'bypassing Clashes (not automated). (2) You ignore the penalties '
        'of any Health Thresholds (automated). (3) At the start of your '
        'next turn, leave this State and skip that turn (not automated).',
    traits: [StateTraitDef(ignoresHealthThresholdPenalties: true)],
  ),
  StateDef(
    'Entrusted',
    description: 'Special State (entered only via an effect, no Narrative '
        'Requirement). (1) Apply your Greater Dice to your Combat Rolls. '
        '(2) Increase your Stress Bonus by 1. (3) Gain 1 Action upon '
        'entering. (4) Once per Encounter, apply Full Wager Advantage and '
        'All-or-Nothing Disadvantage to a Basic Attack Maneuver, resetting '
        'Capacity to Max first, then leave this State. (Not automated — '
        'Dice/Stress Bonus/Action-economy mechanics this app doesn\'t '
        'model.)',
  ),
  StateDef(
    'Liquid',
    description: 'Special State (entered only via an effect, no Narrative '
        'Requirement). (1) Reduce your Size Category by 1. (2) Increase '
        'Grapple Checks made as the Grappled by 1(T) and cannot be Pinned. '
        '(3) Increase Stealth Skill Checks by 2. (4) Movement Maneuver '
        'doesn\'t provoke the Exploit Maneuver. (5) Cannot use any '
        'Attacking Maneuver or Unique Ability. (6) Once per Round, use a '
        'Healing Surge as a 1-Action Standard Action. (Not automated — '
        'Size/Skill/Action-economy mechanics this app doesn\'t model.)',
  ),
  StateDef(
    'Multiple Arms',
    description: 'Special State (entered only via an effect, no Narrative '
        'Requirement). (1) Wield up to 4 Weapons simultaneously. (2) Gain '
        'an additional Counter Action each Combat Round. (3) Once per '
        'Round, hitting with a Physical Attack applies extra Diminishing '
        'Defense stacks as if from an additional Attacking Maneuver. '
        '(4) Once per Round, reroll your Strike Roll for a Combination '
        'Profile Attacking Maneuver. (5) Once per Round, spend 2 Counter '
        'Actions to use the Basic Attack Maneuver as an Instant Maneuver. '
        '(6) Diminishing Offense doesn\'t apply until after your 4th '
        'Attacking Maneuver each Combat Round. (Not automated — all '
        'situational/Action-economy.)',
  ),
  StateDef(
    'Invisible',
    description: 'Special State (entered only via an effect, no Narrative '
        'Requirement). (1) Become Hidden to all Opponents at the start of '
        'your turn. (2) Remain Hidden even within an Opponent\'s Melee '
        'Range or after hitting them. (3) Hitting an Opponent increases '
        'the Natural Result of their next Search Maneuver to find you by '
        '1. (4) If an Oblivious Opponent hits you, increase its Damage '
        'Category by 1. (Not automated — Hidden-status mechanics this app '
        'doesn\'t model.)',
  ),
  StateDef(
    'Spectator',
    description: 'Special State (entered only via an effect, no Narrative '
        'Requirement). (1) Target an Ally, increasing their Combat Rolls '
        'by 1(bT) until your next turn or you leave this State. (2) You '
        'may instead exit this State at the start of your turn. (3) If you '
        'didn\'t use effect (2), lose all non-Counter Actions, end your '
        'turn, and regain 2d10(bT) Life and Ki Points. (4) Cannot use the '
        'Power Up, Transformation or Energy Charge Maneuvers, or any '
        'other-targeting Attacking Maneuver/Special Maneuver/Unique '
        'Ability. (5) Cannot trigger other [Start of Turn]/[Start of '
        'Combat Round] effects. (Not automated — effect (1) targets an '
        'ALLY, not this character; the rest is action-economy.)',
  ),
];

/// Looks up a State by name, or `null` if it's a custom/homebrew entry not
/// in the official catalogue (still trackable, just un-automated).
StateDef? stateDefByName(String name) {
  for (final s in kDbuStates) {
    if (s.name == name) return s;
  }
  return null;
}
