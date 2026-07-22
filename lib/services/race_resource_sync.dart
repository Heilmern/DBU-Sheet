/// race_resource_sync.dart
/// ---------------------------------------------------------------------------
/// Keeps a Character's freeform Resources list (see `models/character.dart`)
/// in sync with the stacking Resources their currently-active Racial Traits
/// (and chosen Options) grant — e.g. a Saiyan should see "Battle Born" ready
/// to track on the Character page the moment the Trait is active, without
/// the player having to type the row in by hand.
///
/// This deliberately lives OUTSIDE `character_calculator.dart`: the
/// calculator is a pure, read-only rules engine (see that file's header —
/// "Nothing here is persisted"), whereas this is a one-way, idempotent,
/// ADDITIVE sync. It only creates missing rows; it never edits or removes
/// ones the player already has, so a Trait that gets swapped out later
/// doesn't silently delete the player's tracked stacks/notes on that
/// Resource — they can remove the row by hand if they want.
/// ---------------------------------------------------------------------------
library;

import '../data/race_traits.dart';
import '../models/character.dart';
import 'character_calculator.dart';

/// Ensures [c.resources] contains an entry (case-insensitive name match) for
/// every Resource granted by [c]'s active Racial Traits and their chosen
/// Options (see `RaceTraitDef.grantedResources` / `TraitOption.grantedResources`
/// in `data/race_traits.dart`). Missing entries are appended with 0 stacks
/// and the catalogued max Stacks; existing entries are left untouched. Call
/// after any Race, Trait-swap or Option change (see `_recompute` in
/// `ui/character_edit_screen.dart`).
void ensureRaceGrantedResources(Character c) {
  final granted = <String, int>{};

  void collect(Iterable<GrantedResource> resources) {
    for (final r in resources) {
      granted[r.name] = r.maxStacks;
    }
  }

  for (final trait in CharacterCalculator.activeRaceTraits(c)) {
    collect(trait.grantedResources);
    for (final group in trait.optionGroups) {
      final chosen =
          c.raceTraitOptionChoices['${trait.name}::${group.label}'] ??
              const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.name)) {
          collect(option.grantedResources);
        }
      }
    }
  }

  // Bestial/Monstrous Traits the character has selected grant their own
  // stacking Resources too (Bloodlust, Plate, Sunlight, Light Stack…). Their
  // Option picks live in the same `raceTraitOptionChoices` map keyed by the
  // beast Trait's name, so collect those Options' Resources as well.
  for (final bt in CharacterCalculator.selectedBeastTraits(c)) {
    collect(bt.grantedResources);
    for (final group in bt.optionGroups) {
      final chosen =
          c.raceTraitOptionChoices['${bt.name}::${group.label}'] ??
              const <String>{};
      for (final option in group.options) {
        if (chosen.contains(option.name)) {
          collect(option.grantedResources);
        }
      }
    }
  }

  for (final entry in granted.entries) {
    final exists = c.resources.any(
      (r) => r.name.trim().toLowerCase() == entry.key.toLowerCase(),
    );
    if (!exists) {
      c.resources.add(TrackedEntry(name: entry.key, maxStacks: entry.value));
    }
  }
}
