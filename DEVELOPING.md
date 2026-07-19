# Developer Guide

How the DBU Character Sheet is built, and how to change or extend it. Read this before touching a formula or adding catalogue content. If you only want to run the app, see [README.md](README.md).

---

## 1. The one load-bearing idea

**Raw choices in, everything else computed.**

The app stores only the decisions a player actually makes. Every number a player *reads* is derived from those decisions on demand. Nothing derived is ever persisted.

This split shows up as three kinds of code, and keeping them separate is the single most important rule in the project:

| Kind | Lives in | Holds |
| --- | --- | --- |
| **A choice** the player makes/tracks | `lib/models/character.dart` | Attribute increases, Skill Ranks, Power Level, bio, Z-Soul, owned Transformations/Talents/gear, current resource pools |
| **Static rules data** | `lib/data/*.dart` | Attribute/skill/race enums, catalogues of game content, lookup tables |
| **A formula** | `lib/services/character_calculator.dart` | Every derived value (Max Life, Skill bonuses, Aptitudes, combat rolls, costs) |

> **Put a new *choice* on the model, a new *catalogue* in `lib/data/`, and a new *formula* in the calculator — never blend them.**

Because derived values are recomputed on every rebuild, a rules change is usually a one-file edit in the calculator, and every saved character updates automatically. No stale total can ever reach disk.

---

## 2. The three core files

### `lib/models/character.dart` — the persisted model

- Stores **only** player choices. It never stores derived totals (Max Life, Skill bonuses, Aptitudes, Attribute *Scores*).
- JSON-serializable and **tolerant of missing/extra keys**: old saves load fine, and unknown keys are ignored. This is what lets the schema evolve without migrations.
- Computes nothing beyond trivial accessors. For example, `Character.scoreOf(attr)` derives an Attribute Score from Race + Progression rather than reading a stored field.

When you add a new player choice, it goes here as a new field with a sensible default, wired into `toJson`/`fromJson` defensively (treat a missing key as the default).

### `lib/services/character_calculator.dart` — the rules engine

- A large collection of `static` methods over an immutable `Character` that produce every derived value.
- The UI calls into it on every rebuild, so on-screen numbers are always consistent with the current rules.
- A DBU formula change is usually a one-file edit here.
- The file opens with a doc-comment header documenting formula provenance and confirmed-vs-tentative status. **Read that header before touching a formula.** Best-effort derivations are marked `// VERIFY:` and kept isolated so a correction is a one-line change with no UI impact.

### `lib/data/dbu_rules.dart` — the single source of truth for core rules data

Attribute/skill/size/race enums and const catalogues, the Power-Level → Tier table, the Progression grant table, Conditions/States catalogues, and dice/karma rules. Formula provenance and confirmed-vs-tentative status are documented in the doc-comment headers here and in the calculator — read those first.

---

## 3. Data catalogues (`lib/data/`)

Large static game content is split one file per domain. Every catalogue follows the **same pattern**:

```dart
const List<XDef> kDbuThings = [ /* … const entries … */ ];

XDef? thingByName(String name) => /* lookup */;
```

Current catalogues include:

- **Transformations** — `transformations.dart` holds the shared `TransformationDef` model + enums, the Awakening-Limit table, and `kMaxSuperAwakenings`. Content is split across `awakenings.dart` (Lesser), `greater_awakenings.dart`, `super_awakenings.dart`, `enhancements.dart`, `forms.dart` (Alternate Forms / Evolved Stages / Legendary Forms), and `aspects.dart`.
- **Inventory** — `apparel.dart`, `weapons.dart`, `accessories.dart`, `basic_items.dart` (each with its own enums, grade tables, and quality/automation data).
- **Signatures** — `signature_profiles.dart` (Foundations & Profiles) and `signature_modifiers.dart` (Advantages & Disadvantages).
- **Unique Abilities** — `unique_abilities.dart` (structured fields + effect + nested Advancements/Restrictions).
- **Traits & Talents** — `race_traits.dart`, `factor_traits.dart`, `talents.dart`, `custom_species_traits.dart`.
- **Custom Buffs** — `custom_buff_targets.dart` (the full "buff target" dropdown, grouped, each resolving to one or more atomic stat channels).
- **Combat flow** — `combat_flow.dart` (the combat tracker's static rules: the phase cycle and verbatim phase texts, the complete Maneuver catalogue — Standard/Instant/Counter/Modifier/Special — and the Battle Weather / Battle Environment / Environmental Quality / Light Level catalogues).
- **Homebrew registry** — `homebrew_registry.dart` (the runtime library of player-authored content, seeded at startup; provides `resolveX` lookups that check the official catalogue first — the official entry always wins a name clash — then convert the homebrew entry into the same definition type the engine already consumes).

`CharacterCalculator.transformationByName` resolves a Transformation name across Lesser → Greater → Super → Enhancement → Form.

### How automation works

The goal is: **transcribe site text, and automate everything that can be automated.** Only genuinely situational/narrative effects (skill-check dice, retaliation, GM-adjudicated, opponent-relative) are left as labelled "reference text, not automated."

The automation pipeline has a few layers:

1. **AMB (Attribute Modifier Bonus)** — Transformations grant per-Attribute modifier bonuses. Awakenings apply always-on (× Stacks); Enhancements/Forms apply only while active. Tier-scaled (`(T)`) entries multiply by Tier of Power; graded entries read from a per-Grade table. Traits and Trait `[Option]` choices can also grant AMB (tier-scaled, flat, or distributed per-Stack).
2. **Trait/Aspect stat automation** — every trait with a clean numeric effect carries `RaceTraitAutomation` entries (a vocabulary shared across Racial Traits, Talents, and Transformation Traits, defined in `race_traits.dart`). These flow into an `AffectedStat` "buffs" pipeline that feeds wounds, soak, defense, saves, pools, skills, Ki costs, size, damage reduction, surgency, and more.
3. **Custom Buffs** — the player-facing freeform version of the same pipeline. A `CustomBuffTarget` resolves into one or more atomic `AffectedStat` channels (e.g. "Combat Rolls" fans out to Strike + Dodge + all Wounds).

The calculator has a single gating authority for which effects are currently in effect (e.g. `transformationTraitsInEffect`), so activation rules live in one place rather than being scattered.

### Choose-one / choose-N sub-systems

When a trait says "select and gain one of the following," it's modelled as a real option group (`RaceTraitOptionGroup` / `TraitOption`), not prose. The shared trait renderer shows a dropdown (or a multi-select chip row when more than one choice is allowed), and the chosen option's `automation` flows through the same pipeline, keyed by `"<TraitName>::<GroupLabel>"` — the same key the UI writes to `optionChoices`.

---

## 4. The UI (`lib/ui/`)

- **`character_list_screen.dart`** — the roster: create / edit / delete, backed by the repository.
- **`character_edit_screen.dart`** — an 8-tab `TabController`. The **Character** tab is built inline. Six middle tabs (`InformationTab`, `ProgressionTab`, `TransformationsTab`, `InventoryTab`, `SignaturesTab`, `UniqueAbilitiesTab`) share one contract:

  ```dart
  ({ Character character, DerivedCharacterStats stats, void Function(Mutate) onUpdate })
  ```

  where `stats` is the freshly recomputed derived state, and `onUpdate(mutate)` applies a mutation to the character and re-derives.
- **`references_screen.dart`** (`ReferencesTab`) is different: a `StatefulWidget` taking only `({ character, stats })`. It's a pure scratchpad attack-roll calculator — nothing it does persists, so its inputs are ephemeral widget state.
- **`combat_screen.dart`** — the combat tracker, opened by the "Start Combat" button next to Save. It operates on the **same working copy** as the editor (pool/stack changes persist via Save; phase, Round, Actions and Battlefield picks are ephemeral). The phase cycle (Start of Combat → Start of Round → Start of Turn → End of Turn → repeat) drives round-boundary automation (Actions/Counter reset, Diminishing trackers cleared) and reminder popups from `services/combat_reminders.dart` — a **read-only text scan** of everything the character possesses, classified by the timing phrases in the rules wording. The scan never touches a stat, so it can never double-apply anything the calculator automates. The page also hosts the Information / Transformations / Inventory / Signatures / Unique Abilities tabs on the same contract, and opens the References calculator as an "Attack Reference" page whose *Attack made* action feeds the Diminishing Offense counting.
- **`home_shell.dart` / `homebrew_list_screen.dart` / `homebrew_edit_screen.dart`** — the top-level navigation and the homebrew library editor (enum-driven forms over the same automation vocabulary the catalogues use).
- **`widgets/`** — shared building blocks: `SectionCard`, `DerivedStat` (the tinted read-only chip for computed values), `ResizableTextField`, and the shared `TpBudgetCard`.

**UI convention:** editable inputs are outlined fields; computed values are tinted read-only chips. This mirrors the original spreadsheet's greyed-out formula cells and makes it visually obvious what a player can change versus what the engine derives.

**List-row key convention:** repeating editable rows (tracked Conditions/States/Resources, gear) key their stateful inner widgets — dropdowns and name text fields — by **row object identity** (`ObjectKey(entry)` or a `ValueKey` wrapping the entry), never by index alone (a deleted row's element state would attach to its successor) and never by the value being typed (the field would remount, and drop the cursor, on every keystroke).

---

## 5. Persistence

`lib/services/character_repository.dart` serializes the **whole roster** to one JSON string under a single `shared_preferences` key. It's identical on all five platforms and is the only place storage is touched. `loadAll` fails safe — it returns an empty roster on corrupt/unreadable data rather than crashing. If the roster ever needs a real database, this is the one file to swap.

Two additive sync helpers run from the edit screen's update path:

- `race_resource_sync.dart` — keeps Resource lists in step with Race choices.
- `progression_talent_sync.dart` — keeps Talent lists in step with Progression choices.

Both are **additive and idempotent**: they only add missing entries, and never edit or remove existing ones. The combat tracker's update path runs the same two helpers, since it hosts the editor tabs too.

Other services:

- `combat_reminders.dart` — the combat tracker's timing scanner (see §4).
- `rule_text.dart` — `annotateRuleText`, the display-only helper that appends resolved values after `N(T)` / `N(bT)` / `Z` / `G` / `L` tokens in verbatim rules text. The wording is never altered and the engine never parses prose.
- `import_export_service.dart` / `file_transfer_service.dart` — versioned-envelope character/homebrew codes; a character bundles every homebrew definition it references.
- `homebrew_repository.dart` — persistence for the homebrew library (same `shared_preferences` approach as the roster).

---

## 6. Rules sources and the offline archive

All rules content is transcribed from the official DBU website, cross-referenced against the original community sheet. **Where they disagree, the live site wins.** Wording is copied **verbatim** — no paraphrasing — and every mechanically resolvable effect is wired into the calculator; only genuinely situational/narrative effects stay as labelled reference text.

For exact, untruncated text, transcribe from the offline site snapshot at `References/dbu-rpg.com_f4481821.zim` (a standard ZIM archive). Serve it locally and fetch pages directly:

```bash
kiwix-serve --port=8989 "References/dbu-rpg.com_f4481821.zim"
# then fetch e.g.
#   http://127.0.0.1:8989/content/dbu-rpg.com_f4481821/dbu-rpg.com/<page-slug>/
```

Strip the WordPress markup when reading, but grep the raw `<td>` cells for tables — flattening table markup garbles multi-column rows. Content published after the snapshot is transcribed from the live site and marked `Added post-ZIM` in the catalogue comments.

---

## 7. How to add things (recipes)

### Add a new player choice (something the player tracks)

1. Add a field to `Character` in `models/character.dart`, with a sensible default.
2. Wire it into `toJson`/`fromJson` defensively — a missing key must fall back to the default (old saves must still load).
3. Add a control for it in the relevant UI tab, writing through `onUpdate`.
4. If it affects any derived number, read it from the calculator (next recipe), not from the widget.

### Add a new catalogue entry (a Transformation, Weapon, Trait, Ability, …)

1. Open the matching file in `lib/data/`.
2. Copy the site's effect/trait/quality wording **verbatim** into a new `const` entry, following the existing shape.
3. For every mechanically-resolvable part, attach `automation` (or AMB / option groups as appropriate) so it feeds the derived stats. Leave only genuinely situational text as reference, and label it as not automated in the UI.
4. If the catalogue has a pinned count in the test suite, bump it.

### Add or change a formula

1. Read the doc-comment header of `character_calculator.dart` (and `dbu_rules.dart` if it's core data) for provenance and the confirmed-vs-`// VERIFY:` status.
2. Make the change in the calculator's `static` method. If it's a best-effort derivation, isolate it and mark it `// VERIFY:` so a later correction is one line.
3. Update the doc-comment header to reflect the new behaviour.
4. Add or update a test in `character_calculator_test.dart` — the suite is the executable record of the confirmed formulas.

---

## 8. Non-negotiables

- **No platform-specific code in `lib/`.** `shared_preferences` is the only dependency. Before adding any dependency, confirm it supports all five targets (Android, iOS, Windows, macOS, Web).
- **Keep the doc-comment headers current.** Every file opens with a header explaining its role and (for the calculator/rules) formula provenance. Update it when behaviour changes.
- **After any change:** `dart analyze` must be clean, and `flutter test character_calculator_test.dart` must pass.

---

## 9. Commands

```bash
flutter pub get                                     # fetch deps (only shared_preferences)
dart analyze                                        # lint/analyze — must be clean
flutter test character_calculator_test.dart         # run the test suite
flutter test character_calculator_test.dart --plain-name "Awakening Limit table"   # single test/group
flutter build web                                   # compile smoke-test
flutter run -d chrome                               # run (also -d windows / -d macos / a device)
```

The test file lives at the **repository root**, not in a `test/` directory — a bare `flutter test` fails with "Test directory 'test' not found," so always name the file.
