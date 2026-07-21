/// progression_talent_sync.dart
/// ---------------------------------------------------------------------------
/// Keeps a Character's freeform Talents list (see `models/character.dart`)
/// in sync with the Talents recorded via the Progression tab's Talent
/// Addition slots (Main Progression + Bonus Perks) — e.g. picking "Agile
/// Warrior" for a PL9 Talent Addition should make it show up (and be
/// automated) on the Information tab's Talents list without the player
/// having to add it there by hand too.
///
/// This deliberately lives OUTSIDE `character_calculator.dart` (a pure,
/// read-only rules engine) — same one-way, idempotent, ADDITIVE spirit as
/// `race_resource_sync.dart`'s `ensureRaceGrantedResources`: it only creates
/// missing rows; it never edits or removes ones the player already has, so
/// removing a Talent pick from Progression later doesn't silently delete
/// the player's Information-tab entry — they can remove it by hand if they
/// want. The Information tab's own "Add from catalogue"/"Add blank" buttons
/// are untouched and remain the explicit fallback for Talents gained
/// outside Progression (e.g. from a Trait).
/// ---------------------------------------------------------------------------
library;

import '../data/homebrew_registry.dart';
import '../models/character.dart';
import 'character_calculator.dart';

/// Ensures [c.talents] contains an entry (case-insensitive name match) for
/// every Talent name recorded across ALL of [c]'s Progression Talent
/// Addition slots (Main Progression + Bonus Perks, regardless of whether
/// that Power Level has been reached yet — a planned-ahead pick still gets
/// a row to fill in). Missing entries are appended prefilled from
/// `HomebrewRegistry.resolveTalentDef` (official catalogue first, then
/// homebrew Talents), or just the bare name for a freeform one; existing
/// entries are left untouched.
void ensureProgressionTalentsInTalentList(Character c) {
  final names = CharacterCalculator.progressionTalentsThroughLevel(
    c,
    999, // no cutoff — sync every planned pick, not just reached ones
  );

  for (final name in names) {
    final exists = c.talents.any(
      (t) => t.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );
    if (exists) continue;

    final catalogueTalent = HomebrewRegistry.resolveTalentDef(name);
    c.talents.add(TalentEntry(
      name: name,
      prerequisites: catalogueTalent?.prerequisitesText ?? '',
      description: catalogueTalent?.description ?? '',
    ));
  }
}
