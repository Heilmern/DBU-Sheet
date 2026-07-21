/// trait_talent_sync.dart
/// ---------------------------------------------------------------------------
/// Keeps a Character's Talents list (see `models/character.dart`) in sync with
/// the Talents their Racial Traits grant — e.g. Earthling's "gain the Expert
/// Pilot Talent" or a Trait's "gain access to the Snack Fiend Talent" should
/// drop that Talent onto the Information tab's Talents list automatically,
/// prefilled from the catalogue, without the player re-typing it by hand.
///
/// Same one-way, idempotent, ADDITIVE spirit as `race_resource_sync.dart` and
/// `progression_talent_sync.dart`: it only creates missing rows (case-
/// insensitive name match); it never edits or removes ones the player already
/// has, so a Trait that stops applying later never silently deletes the
/// player's notes on that Talent — they can remove the row by hand.
///
/// DISCOVERY: rather than annotate every Trait, the grant is detected from the
/// verbatim Trait text — a "gain / obtain / gain access to … `<Name>` Talent"
/// phrase — and `<Name>` is only accepted when it resolves to a REAL catalogue
/// Talent (official or homebrew), so generic wording ("gain a Talent from the
/// Weapon Talent Category") and negations ("cannot gain the X Talent", "lose
/// access to …") add nothing. False positives are harmless anyway: the sync is
/// additive, so a stray row is one the player can delete.
/// ---------------------------------------------------------------------------
library;

import '../data/homebrew_registry.dart';
import '../data/talents.dart';
import '../models/character.dart';
import 'character_calculator.dart';

/// Matches a Talent grant: a grant verb, an optional "access to"/"the", then a
/// name ending in " Talent". The name is validated against the catalogue by
/// the caller, so this can be liberal.
final RegExp _grantPattern = RegExp(
  r"(?:gain(?:s|ed)?|obtain(?:s|ed)?|have|has|had)\s+"
  r"(?:access\s+to\s+)?(?:the\s+)?([A-Za-z0-9'!/&.\- ]+?)\s+Talent\b",
  caseSensitive: false,
);

/// Words just before a grant that flip it into a NON-grant (negations and
/// losses), checked against the short run of text preceding a match.
const List<String> _negations = [
  'cannot',
  "can't",
  'could not',
  "couldn't",
  'not ',
  'never',
  'no longer',
  'lose',
  'lost',
  'without',
  "don't",
];

/// Ensures [c.talents] contains an entry for every catalogue Talent granted by
/// the character's active Racial Traits (and their chosen Options), plus any
/// Racial Traits adopted from other Races. Missing entries are appended
/// prefilled from the catalogue; existing entries are left untouched.
void ensureTraitGrantedTalents(Character c) {
  // Canonical-cased name for every catalogue Talent, keyed by lowercase.
  // Homebrew first so an official Talent of the same name wins the casing.
  final canonicalByLower = <String, String>{
    for (final t in HomebrewRegistry.talentDefs())
      t.name.trim().toLowerCase(): t.name.trim(),
    for (final t in kDbuTalents) t.name.trim().toLowerCase(): t.name.trim(),
  };

  final granted = <String>{};
  void scan(String text) => granted.addAll(_grantedTalents(text, canonicalByLower));

  for (final trait in [
    ...CharacterCalculator.activeRaceTraits(c),
    ...CharacterCalculator.extraRaceTraitDefs(c),
  ]) {
    scan(trait.description);
    if (trait.trailingText.isNotEmpty) scan(trait.trailingText);
    for (final group in trait.optionGroups) {
      final chosen =
          c.raceTraitOptionChoices['${trait.name}::${group.label}'] ??
              const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.name)) scan(option.description);
      }
    }
  }

  for (final name in granted) {
    final exists = c.talents.any(
      (t) => t.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (exists) continue;
    final def = HomebrewRegistry.resolveTalentDef(name);
    c.talents.add(TalentEntry(
      name: def?.name ?? name,
      prerequisites: def?.prerequisitesText ?? '',
      description: def?.description ?? '',
    ));
  }
}

/// The canonical names of catalogue Talents [text] grants (see [_grantPattern]
/// / [_negations]); empty when it grants none.
Set<String> _grantedTalents(String text, Map<String, String> canonicalByLower) {
  final result = <String>{};
  for (final match in _grantPattern.allMatches(text)) {
    // Skip when a negation/loss immediately precedes the grant.
    final start = match.start;
    final pre = text
        .substring((start - 16).clamp(0, text.length), start)
        .toLowerCase();
    if (_negations.any(pre.contains)) continue;

    final candidate = match.group(1)!.trim().toLowerCase();
    final canonical = canonicalByLower[candidate];
    if (canonical != null) result.add(canonical);
  }
  return result;
}
