/// combat_reminders.dart
/// ---------------------------------------------------------------------------
/// The Combat page's REMINDER ENGINE. Scans every trait/ability text the
/// character currently possesses — active Racial Traits (+ chosen Options),
/// Talents, Transformation Traits in effect (+ Aspects), tracked
/// Conditions/States/Resources, worn Apparel Qualities, wielded Weapon
/// Qualities, equipped Accessories, owned Unique Abilities (+ Advancements)
/// and active homebrew — for the timing phrases the rules use ("at the start
/// of your turn", "at the end of each Combat Round", "when a Combat
/// Encounter starts", …) and surfaces the matching sentences on the right
/// phase card of the Combat tracker.
///
/// The scan is purely textual (the sentences shown ARE the verbatim rule
/// text — nothing is applied to any stat from here), so it can never
/// double-apply an effect the calculator already automates; it only reminds.
/// A handful of built-in reminders come from tracked state instead of text
/// (Power stack expiry, Diminishing Offense/Defense clears), with their rule
/// text quoted verbatim from the Actions & Maneuvers / Attacking pages.
///
/// Timing classification ([CombatTiming]) is finer-grained than the
/// tracker's four [CombatPhase]s: the round boundary (endOfRound) renders in
/// the Start of Round card ("the previous Round just ended") and
/// endOfEncounter in the End Combat dialog — see `ui/combat_screen.dart`.
/// ---------------------------------------------------------------------------
library;

import '../data/combat_flow.dart';
import '../data/homebrew_registry.dart';
import '../models/character.dart';
import 'character_calculator.dart';
import 'rule_text.dart';

/// When during a Combat Encounter a scanned effect fires or expires.
///
/// [onAttack] is not a phase timing — it tags effects whose text triggers
/// when you make an Attacking Maneuver / attack / Signature Technique, shown
/// on the Attacking Maneuver tab rather than any phase card. It is never
/// produced by the phase-timing classifier ([timingsForText]) nor returned
/// by [timingsForPhase], so it can never leak onto a phase card.
enum CombatTiming {
  startOfCombat('Start of Combat'),
  startOfRound('Start of Round'),
  startOfTurn('Start of Turn'),
  endOfTurn('End of Turn'),
  endOfRound('End of Round'),
  endOfEncounter('End of Combat'),
  onAttack('On an Attacking Maneuver');

  const CombatTiming(this.displayName);

  final String displayName;
}

/// One reminder: the verbatim sentence(s) of [text] from [source]/[title]
/// that mention the [timing].
class CombatReminder {
  const CombatReminder({
    required this.source,
    required this.title,
    required this.timing,
    required this.text,
  });

  /// Where this came from ("Racial Trait", "Condition", "Weapon Quality"…).
  final String source;

  /// The owning Trait/ability/item name.
  final String title;

  final CombatTiming timing;

  /// The verbatim sentence(s) that mention this timing (live-annotated:
  /// every `N(T)`/`N(bT)`/`Z`/`G` token gets its resolved value appended).
  final String text;
}

/// Scans a character's possessed content for combat-timing phrases.
class CombatReminderScanner {
  CombatReminderScanner._();

  // --- Timing phrase patterns ----------------------------------------------
  // The rules phrase turn/round/encounter timings very consistently; these
  // patterns match the possessive variants ("your/their/each of your/the
  // current/next turn(s)") without matching unrelated uses of "turn".
  static final RegExp _turnPhrase = RegExp(
    r'\b(start|beginning|end) of (?:your|their|his|her|its|the|that|this|'
    r'each of (?:your|their)|every) ?(?:current |next )?turns?\b',
    caseSensitive: false,
  );
  static final RegExp _startYourTurnPhrase = RegExp(
    r'\bstarts? (or ends? )?(?:your|their|its) turn\b',
    caseSensitive: false,
  );
  static final RegExp _endYourTurnPhrase = RegExp(
    r'\bends? (?:your|their|its) turn\b',
    caseSensitive: false,
  );
  // `[a-z-]` keeps hyphenated fillers matching ("start of every
  // even-numbered Combat Round" — Born for Battle, Adaptation cadences).
  static final RegExp _roundPhrase = RegExp(
    r'\b(start|beginning|end) of (?:[a-z-]+ ){0,3}?Combat Round\b',
    caseSensitive: false,
  );

  /// "every even-numbered Combat Round" / "each odd-numbered Combat Round" —
  /// effects on a Round cadence. See [roundParity].
  static final RegExp _roundParityPhrase = RegExp(
    r'\b(even|odd)(?:-numbered)? Combat Rounds?\b',
    caseSensitive: false,
  );
  static final RegExp _encounterPhrase = RegExp(
    r'\b(start|beginning|end|remainder) of (?:[a-z]+ ){0,3}?Combat '
    r'Encounter\b',
    caseSensitive: false,
  );
  static final RegExp _encounterStartsPhrase = RegExp(
    r'\bwhen (?:a |the )?Combat Encounter (?:starts|begins)\b|'
    r'\broll(?:ing)? Initiative\b|\bInitiative Checks?\b',
    caseSensitive: false,
  );
  static final RegExp _encounterEndsPhrase = RegExp(
    r'\bwhen (?:a |the )?Combat Encounter ends\b|'
    r'\bafter (?:ending|overcoming) a Combat Encounter\b',
    caseSensitive: false,
  );

  /// Whether [text] fires only on even (`true`) or odd (`false`) numbered
  /// Combat Rounds, or has no such cadence (`null`) — so the tracker can
  /// mark a "every even-numbered Combat Round" reminder as not-this-Round.
  static bool? roundParity(String text) {
    final m = _roundParityPhrase.firstMatch(text);
    if (m == null) return null;
    return m.group(1)!.toLowerCase() == 'even';
  }

  /// Every timing phrase found in [text].
  static Set<CombatTiming> timingsForText(String text) {
    final timings = <CombatTiming>{};
    for (final m in _turnPhrase.allMatches(text)) {
      timings.add(m.group(1)!.toLowerCase() == 'end'
          ? CombatTiming.endOfTurn
          : CombatTiming.startOfTurn);
    }
    for (final m in _startYourTurnPhrase.allMatches(text)) {
      timings.add(CombatTiming.startOfTurn);
      if (m.group(1) != null) timings.add(CombatTiming.endOfTurn);
    }
    if (_endYourTurnPhrase.hasMatch(text)) {
      timings.add(CombatTiming.endOfTurn);
    }
    for (final m in _roundPhrase.allMatches(text)) {
      timings.add(m.group(1)!.toLowerCase() == 'end'
          ? CombatTiming.endOfRound
          : CombatTiming.startOfRound);
    }
    for (final m in _encounterPhrase.allMatches(text)) {
      timings.add(switch (m.group(1)!.toLowerCase()) {
        'end' || 'remainder' => CombatTiming.endOfEncounter,
        _ => CombatTiming.startOfCombat,
      });
    }
    if (_encounterStartsPhrase.hasMatch(text)) {
      timings.add(CombatTiming.startOfCombat);
    }
    if (_encounterEndsPhrase.hasMatch(text)) {
      timings.add(CombatTiming.endOfEncounter);
    }
    return timings;
  }

  /// Splits [text] into sentences (newlines are hard boundaries) and keeps
  /// only those mentioning [timing] — the reminder shows just the relevant
  /// verbatim sentence(s), not the whole trait.
  static String snippetFor(String text, CombatTiming timing) {
    final sentences = <String>[];
    for (final line in text.split('\n')) {
      for (final sentence in line.split(RegExp(r'(?<=[.!?])\s+'))) {
        if (timingsForText(sentence).contains(timing)) {
          sentences.add(sentence.trim());
        }
      }
    }
    return sentences.join('\n');
  }

  /// Classifies [text] and emits one [CombatReminder] per timing found —
  /// the shared path for every scanned source (also used by the Combat page
  /// for its ephemeral Battle Weather/Environment/Light picks).
  static Iterable<CombatReminder> remindersFromText({
    required String source,
    required String title,
    required String text,
    int? tier,
    int? baseTier,
    int? stacks,
    int? grade,
  }) sync* {
    for (final timing in timingsForText(text)) {
      var snippet = snippetFor(text, timing);
      if (snippet.isEmpty) continue;
      if (tier != null && baseTier != null) {
        snippet = annotateRuleText(
          snippet,
          tier: tier,
          baseTier: baseTier,
          stacks: stacks,
          grade: grade,
        );
      }
      yield CombatReminder(
        source: source,
        title: title,
        timing: timing,
        text: snippet,
      );
    }
  }

  /// Enumerates every trait/ability/item text the character currently
  /// possesses, calling [emit] once per source. Shared by [scan] (which
  /// classifies each text by phase timing) and [attackTriggerReminders]
  /// (which matches attack-trigger phrases instead) so both stay in sync.
  static void _forEachSource(
    Character c,
    void Function(String source, String title, String text,
            {int? stacks, int? grade})
        emit,
  ) {
    void addText({
      required String source,
      required String title,
      required String text,
      int? stacks,
      int? grade,
    }) =>
        emit(source, title, text, stacks: stacks, grade: grade);

    // --- Racial Traits (incl. Factor swaps / Custom Species) + Options ----
    for (final trait in CharacterCalculator.activeRaceTraits(c)) {
      addText(
        source: 'Racial Trait',
        title: trait.name,
        text: '${trait.description}\n${trait.trailingText}',
      );
      for (final group in trait.optionGroups) {
        final chosen =
            c.raceTraitOptionChoices['${trait.name}::${group.label}'] ?? {};
        for (final option in group.options) {
          if (chosen.contains(option.name)) {
            addText(
              source: 'Racial Trait',
              title: '${trait.name} — ${option.name}',
              text: option.description,
            );
          }
        }
      }
    }

    // --- Talents (catalogue-backed by def; freeform rows by their text) ---
    final knownTalents =
        CharacterCalculator.activeTalentDefs(c).map((t) => t.name).toSet();
    for (final def in CharacterCalculator.activeTalentDefs(c)) {
      addText(source: 'Talent', title: def.name, text: def.description);
    }
    for (final entry in c.talents) {
      if (knownTalents.contains(entry.name)) continue;
      addText(
        source: 'Talent',
        title: entry.name,
        text: '${entry.description}\n${entry.notes}',
      );
    }

    // --- Transformation Traits in effect (live Z/G annotation) ------------
    for (final inEffect in CharacterCalculator.transformationTraitsInEffect(c)) {
      addText(
        source: inEffect.def.name,
        title: inEffect.trait.name,
        text: inEffect.trait.description,
        stacks: inEffect.sel.stacks,
        grade: inEffect.sel.grade,
      );
      for (final option in CharacterCalculator.chosenTraitOptions(
          inEffect.trait, inEffect.sel.optionChoices)) {
        addText(
          source: inEffect.def.name,
          title: '${inEffect.trait.name} — ${option.name}',
          text: option.description,
          stacks: inEffect.sel.stacks,
          grade: inEffect.sel.grade,
        );
      }
    }

    // --- Aspects of Transformations in effect ------------------------------
    for (final aspect in CharacterCalculator.activeAspects(c)) {
      final def = aspect.def;
      if (def == null) continue;
      addText(source: 'Aspect', title: aspect.label, text: def.effect,
          stacks: aspect.level);
    }

    // --- Tracked Conditions / States / Resources ---------------------------
    for (final entry in c.conditions) {
      if (entry.stacks <= 0 || entry.name.trim().isEmpty) continue;
      final def = HomebrewRegistry.resolveConditionDef(entry.name);
      addText(
        source: 'Condition',
        title: entry.name,
        text: def?.description ?? entry.notes,
        stacks: entry.stacks,
      );
    }
    for (final entry in c.states) {
      if (entry.stacks <= 0 || entry.name.trim().isEmpty) continue;
      final def = HomebrewRegistry.resolveStateDef(entry.name);
      addText(
        source: 'State',
        title: entry.name,
        text: def?.description ?? entry.notes,
        stacks: entry.stacks,
      );
    }
    for (final entry in c.resources) {
      if (entry.stacks <= 0 || entry.name.trim().isEmpty) continue;
      addText(
        source: 'Resource',
        title: entry.name,
        text: entry.notes,
        stacks: entry.stacks,
      );
    }

    // --- Inventory: worn Apparel / wielded Weapons / equipped Accessories --
    for (final piece in c.apparel) {
      if (!CharacterCalculator.apparelIsActive(piece)) continue;
      for (final q in piece.qualities) {
        final def = HomebrewRegistry.resolveApparelQuality(q.name);
        if (def == null) continue;
        addText(
          source: 'Apparel Quality',
          title: piece.name.trim().isEmpty
              ? def.name
              : '${piece.name} — ${def.name}',
          text: def.effects,
        );
      }
    }
    for (final weapon in c.weapons) {
      if (!CharacterCalculator.weaponIsActive(c, weapon)) continue;
      for (final q in weapon.qualities) {
        final def = HomebrewRegistry.resolveWeaponQuality(q.name);
        if (def == null) continue;
        addText(
          source: 'Weapon Quality',
          title: weapon.name.trim().isEmpty
              ? def.name
              : '${weapon.name} — ${def.name}',
          text: def.effects,
        );
      }
    }
    for (final selection in c.accessories) {
      if (!selection.equipped) continue;
      final def = HomebrewRegistry.resolveAccessory(selection.name);
      if (def == null) continue;
      addText(source: 'Accessory', title: def.name, text: def.effects);
    }

    // --- Unique Abilities (+ owned Advancements) ---------------------------
    for (final sel in c.uniqueAbilities) {
      final def = CharacterCalculator.uniqueAbilityDefFor(sel);
      if (def == null) continue;
      addText(source: 'Unique Ability', title: def.name, text: def.effect);
      for (final adv in CharacterCalculator.uniqueAbilityAdvancementDefs(sel)) {
        addText(
          source: 'Unique Ability',
          title: '${def.name} — ${adv.name}',
          text: adv.effect,
        );
      }
    }

    // --- Active homebrew ---------------------------------------------------
    for (final entry in CharacterCalculator.activeHomebrew(c)) {
      addText(source: 'Homebrew', title: entry.name, text: entry.effectText);
    }
  }

  /// Scans everything the character possesses. Reminders are returned in
  /// source order; filter by [CombatReminder.timing] for a phase card.
  static List<CombatReminder> scan(Character c) {
    final tier = CharacterCalculator.tierOfPower(c);
    final baseTier = CharacterCalculator.baseTierOfPower(c);
    final reminders = <CombatReminder>[];

    _forEachSource(c, (source, title, text, {stacks, grade}) {
      reminders.addAll(remindersFromText(
        source: source,
        title: title,
        text: text,
        tier: tier,
        baseTier: baseTier,
        stacks: stacks,
        grade: grade,
      ));
    });

    // --- Built-in tracked-state reminders (rule text verbatim) -------------
    if (c.powerStacks > 0) {
      reminders.add(CombatReminder(
        source: 'Resource',
        title: 'Power (${c.powerStacks} stack${c.powerStacks == 1 ? '' : 's'})',
        timing: CombatTiming.endOfTurn,
        text: 'Power Up Maneuver: “Gain a stack of Power until the end '
            'of your next turn.” Remove any expired stack now.',
      ));
    }
    if (c.diminishingDefenseStacks > 0) {
      reminders.add(CombatReminder(
        source: 'Resource',
        title: 'Diminishing Defense (${c.diminishingDefenseStacks})',
        timing: CombatTiming.startOfRound,
        text: 'At the start of each Combat Round, remove all stacks of '
            'Diminishing Defense.',
      ));
    }
    if (c.diminishingOffenseStacks > 0) {
      reminders.add(CombatReminder(
        source: 'Resource',
        title: 'Diminishing Offense (${c.diminishingOffenseStacks})',
        timing: CombatTiming.endOfRound,
        text: 'At the end of the Combat Round, lose all stacks of '
            'Diminishing Offense.',
      ));
    }

    return reminders;
  }

  /// [scan] filtered to one timing.
  static List<CombatReminder> forTiming(Character c, CombatTiming timing) =>
      [for (final r in scan(c)) if (r.timing == timing) r];

  // --- Attack-trigger phrases ----------------------------------------------
  // Effects that fire when you make an Attacking Maneuver / attack / land a
  // Strike or Wound / spend a Ki Wager or Energy Charge / use a Signature
  // Technique. Matched per-sentence so the reminder shows only the relevant
  // line. Word boundaries keep "attack" from matching inside longer words.
  static final RegExp _attackTriggerPhrase = RegExp(
    r'\b(attacking maneuvers?|attacks?|strike rolls?|wound rolls?|'
    r'signature techniques?|ki wagers?|energy charges?|critical (?:hit|result))\b',
    caseSensitive: false,
  );

  /// The sentence(s) of [text] that mention an attack trigger (newlines are
  /// hard boundaries), joined — mirrors [snippetFor] but phrase-matched.
  static String _attackSnippet(String text) {
    final sentences = <String>[];
    for (final line in text.split('\n')) {
      for (final sentence in line.split(RegExp(r'(?<=[.!?])\s+'))) {
        if (_attackTriggerPhrase.hasMatch(sentence)) {
          sentences.add(sentence.trim());
        }
      }
    }
    return sentences.join('\n');
  }

  /// Reminders for effects that trigger when the character makes an Attacking
  /// Maneuver / attack / Signature Technique — surfaced on the Attacking
  /// Maneuver tab. Purely textual, like [scan]; every reminder carries
  /// [CombatTiming.onAttack].
  static List<CombatReminder> attackTriggerReminders(Character c) {
    final tier = CharacterCalculator.tierOfPower(c);
    final baseTier = CharacterCalculator.baseTierOfPower(c);
    final reminders = <CombatReminder>[];
    _forEachSource(c, (source, title, text, {stacks, grade}) {
      final snippet = _attackSnippet(text);
      if (snippet.isEmpty) return;
      reminders.add(CombatReminder(
        source: source,
        title: title,
        timing: CombatTiming.onAttack,
        text: annotateRuleText(
          snippet,
          tier: tier,
          baseTier: baseTier,
          stacks: stacks,
          grade: grade,
        ),
      ));
    });
    return reminders;
  }

  /// Maps a tracker phase to the timings its card shows — 1:1 now that the
  /// round boundary has its own End of Round phase (see [CombatPhase.next]).
  static List<CombatTiming> timingsForPhase(CombatPhase phase) =>
      switch (phase) {
        CombatPhase.startOfCombat => const [CombatTiming.startOfCombat],
        CombatPhase.startOfRound => const [CombatTiming.startOfRound],
        CombatPhase.startOfTurn => const [CombatTiming.startOfTurn],
        CombatPhase.endOfTurn => const [CombatTiming.endOfTurn],
        CombatPhase.endOfRound => const [CombatTiming.endOfRound],
      };
}
