# Explanation — how the code works and why it is built this way

This document explains the design of the DBU Character Sheet in depth: what each part of the codebase does, the reasoning behind the major decisions, and the policies that keep the project consistent as it grows. [README.md](README.md) covers what the app is; [DEVELOPING.md](DEVELOPING.md) covers how to make changes; this document covers *why the code looks the way it does*.

---

## 1. The problem being solved

The Dragon Ball Universe TTRPG has an unusually deep character model: seven Attributes feeding a dozen Aptitudes, a Tier-of-Power system that scales almost every number, hundreds of Transformations with stacking and grading rules, gear with crafting grades and quality slots, technique builders with their own point economies, and a large body of situational Traits. The community originally tracked all of this in a Google Sheet: formula cells everywhere, greyed-out to show they were computed.

That spreadsheet is the app's spiritual ancestor, and its single best idea — *the player types choices, the sheet derives everything* — became the project's foundation. Everything else follows from taking that idea seriously in application code.

---

## 2. The core decision: store choices, compute everything else

The whole architecture rests on one rule:

> **The saved model stores only what the player chooses or tracks. Every number the player reads is derived on demand.**

Concretely, `lib/models/character.dart` stores Attribute increases (not Scores), base Skill Ranks (not bonuses), Power Level (not Tier), owned Transformations (not their stat effects), current pools (not maximums). `lib/services/character_calculator.dart` — a large collection of static, side-effect-free functions over an immutable `Character` — produces every derived value, and the UI calls it on every rebuild.

**Why:**

- **Rules change; saves shouldn't rot.** When a formula on the DBU site changes, the fix is a one-file edit in the calculator, and every saved character updates automatically the next time it renders. If derived totals were persisted, every save would need migration — and a missed migration would silently show wrong numbers.
- **No dual-write bugs.** There is exactly one path from a choice to a displayed number. Nothing can get out of sync because there is no second copy to desynchronize.
- **Recompute-on-build is affordable.** The calculator is pure arithmetic over in-memory data; recomputing the full derived state on each edit is far below UI-frame cost, so the simplicity is essentially free.

The corollary is a three-way separation that every change must respect:

| Kind of thing | Where it lives |
| --- | --- |
| A player **choice** | `lib/models/character.dart` |
| Static **rules data** | `lib/data/*.dart` |
| A **formula** | `lib/services/character_calculator.dart` |

Blending these (a formula in a widget, a catalogue constant in the model) is the one structural mistake the project guards against most.

---

## 3. The persisted model and schema tolerance

`Character` serializes to plain JSON. Deserialization is deliberately *forgiving*: every field falls back to a sensible default when its key is missing, and unknown keys are ignored.

**Why:** the schema grows constantly (new subsystems add fields several times a month), and the app runs on five platforms with no server. Tolerant JSON means:

- Old saves always load — there is no migration framework because none is needed.
- A newer save opened by an older build simply ignores the fields it doesn't know.
- A hand-edited or partially corrupted save degrades gracefully instead of crashing.

Where an old representation must be upgraded (for example, the early freeform Custom Species attribute spread becoming structured choice slots), the model performs a *best-effort* migration at load and falls back to "player re-picks" when the old data doesn't fit the new shape — wrong-but-silent values are never fabricated.

A related policy applies throughout: **selections are stored by name**, not by index or object reference (`"Kaioken"`, `"Saiyan:Warrior's Pride"`, a Condition called `"Poisoned"`). Name-keyed references survive catalogue reordering and let stale references fail soft: an unresolvable name simply contributes nothing (and, where it matters, is surfaced as a visible warning rather than an error).

---

## 4. The rules engine

`character_calculator.dart` is intentionally a single large file of static methods rather than a class hierarchy.

**Why:**

- The DBU rules are one tightly interconnected system (Tier of Power touches nearly everything). A single file with a disciplined internal layout keeps every formula one search away and avoids artificial seams.
- Static, pure functions make the engine trivially testable — the test suite calls the same functions the UI does, with no setup.
- The file opens with a provenance header. Every formula is annotated as **confirmed** (verified against the rules text, usually with the verbatim quote in a comment) or marked `// VERIFY:` (a best-effort derivation, kept isolated so a future correction is a one-line change). This turns the engine into an auditable record of *where each number comes from*.

Derived state reaches the UI as a `DerivedCharacterStats` snapshot produced by `CharacterCalculator.compute(character)`. Screens never do arithmetic; they render the snapshot and write choices back.

### The automation pipeline

The hardest part of the rules is that *content* modifies *stats*: a Racial Trait adds to Soak, a Transformation multiplies Ki, a worn Quality excludes a penalty. The engine handles this with one shared vocabulary instead of per-feature code paths:

- **`RaceTraitAutomation`** (defined in `race_traits.dart`, used everywhere) describes a numeric effect: which `AffectedStat` channels it feeds, its magnitude kind (flat, per-Tier, per-stack, per-Power-Level, fraction-of-pool, …), and an optional computable condition gate (while a named State is active, while below a Health Threshold, …).
- **`AffectedStat`** is the closed set of stat channels (Strike, Dodge, the three Wounds, Saves, pools, speeds, Soak, Damage Reduction, Surgency, skill channels, Ki-cost channels, dice channels, …). Every buff source — Racial Traits, Talents, Transformation Traits, Aspects, Conditions, States, gear, homebrew, and the player's freeform Custom Buffs — resolves into per-channel integer totals that are summed in one place.
- **Gating is centralized.** One authority function per content type decides what is "in effect" (for Transformations: Awakenings always-on gated by Stacks, Enhancements/Forms while active, Mastery Traits by mastery level, and so on). Because activation logic lives in exactly one place, the stat pipeline, the UI display, and the combat reminders can never disagree about whether a Trait applies.
- **Choose-one effects are data, not prose.** When a Trait says "select one of the following," it is modelled as an option group; the UI renders a dropdown (or multi-select chips), the choice is stored under a `"<TraitName>:<GroupLabel>"` key, and the chosen option's automation flows through the same pipeline — including nested choices inside choices.

The design goal is that adding new content is *authoring*, not *programming*: a new catalogue entry with automation attached participates in every derived number, every warning, and every combat reminder without a single engine change.

### What gets automated, and what deliberately doesn't

The standing policy is **transcribe the rules text verbatim, then automate every mechanically resolvable effect**. Effects stay as labelled "reference text, not automated" only when they are genuinely situational: opponent-relative, per-use choices, GM-adjudicated outcomes, narrative permissions. The UI always says so explicitly, so a player never has to guess whether a number already includes an effect.

Verbatim transcription is itself a load-bearing decision. Paraphrasing rules text creates two problems: subtle drift from the source (which players will notice at the table), and unsearchability (players look for the exact wording they know). Copying exactly — and layering live value annotation on top (see §7) — avoids both.

### Warnings, not clamps

Where the rules impose limits (Attribute Score caps by Tier, Skill Rank caps, the two-Accessory limit, duplicate-choice restrictions), the app **shows a red warning instead of clamping the value**.

**Why:** tables houserule, content grants exceptions, and data entry sometimes happens out of order. A sheet that silently rewrites what the player typed is worse than one that says "this exceeds the limit" and trusts the table. The engine treats the player's input as truth and the rules as a lens over it.

---

## 5. The data catalogues

`lib/data/` holds the static game content — one file per domain, every catalogue following the same shape: a `const List<XDef>` plus a `xByName(String)` lookup. The content covers the complete published catalogues (Awakenings, Enhancements, Forms, Aspects, gear Qualities, Accessories, Basic Items, Signature Profiles and modifiers, Unique Abilities, Racial and Factor Traits, Talents, Custom Species Traits, Maneuvers, Battle Weather/Environments/Light Levels), with effect wording copied verbatim.

Decisions worth noting:

- **`const` everywhere.** The catalogues are compile-time constants: zero load cost, structurally immutable, and safe to share.
- **Counts are pinned by tests.** The suite asserts exact catalogue sizes (124 Lesser Awakenings, 75 Enhancements, 147 Form definitions, 32 Special Maneuvers, …). A pinned count catches both accidental deletions and half-finished additions, and doubles as a completeness record.
- **Names are the join keys.** Cross-references between systems (a Transformation naming an Aspect, a Technique naming a Profile, a character naming anything) are resolved by name through the lookup functions, consistent with the tolerance policy in §3.
- **Computed classification over stored flags.** Where the site expresses structure through conventions (a Form Stage's prerequisite line, a "(Legendary Trait)" suffix inside a trait name), the model detects it with computed getters rather than duplicating the information in flags that could drift from the text.

---

## 6. The dice engine

DBU rolls are built from a base d10 plus a growing set of "Extra Dice": Tier-of-Power dice, Greater Dice, Critical Dice, Energy-Charge dice, and flat bonus dice, with a "Dice Category" progression (d4 → d6 → d8 → d10 → d10+d4 → …) that effects can raise.

The engine models a roll as a **`DicePool`** — a `{sides: count}` multiset — assembled per roll scope by `combatDicePool`. Category math is table-driven (`DiceRules.categoryDice`), so "increase the Dice Category by 1" is an index bump, and wrapping past d10 falls out of the table rather than being special-cased. The pool renders canonically (largest die first, e.g. `2d10+1d6`), which is what makes the one-tap **copyable roll expressions** possible: the string the player copies *is* the pool plus the flat bonus and Critical Target, with a second variant that appends the Critical Dice for critical results.

---

## 7. Live-value rule text

Verbatim rules text is full of scaling tokens: `2(T)` means "2 × Tier of Power," `1(bT)` uses the base Tier, `Z` scales by Stacks, `G` by Grade. `services/rule_text.dart` provides `annotateRuleText`, a display-only helper that appends the resolved value after every token — `2(T) [=6]` at Tier 3.

**Why this shape:** the wording itself is never altered (transcription stays verbatim and searchable) and the rules engine never parses prose (automation stays structured). Annotation is a pure presentation layer, which means it can never introduce a rules bug — the worst failure mode is a missing annotation.

---

## 8. The UI layer

### One working copy, one mutation path

The character editor (`character_edit_screen.dart`) owns a single working copy of the character and a `DerivedCharacterStats` snapshot. Its tabs share one contract — `({character, stats, onUpdate})` — where `onUpdate(mutate)` applies a mutation and re-derives. Tabs are stateless with respect to character data: they render what they're given and write back through the callback.

**Why:** with eight tabs editing the same character, any tab-local caching would be a desync waiting to happen. The single-owner design makes "switch tabs mid-edit" trivially safe. Saving pops the working copy back to the roster screen for persistence; backing out discards it — an explicit, predictable commit boundary.

### Persisted vs ephemeral state

A strict line separates what belongs on the model from what is merely session state:

- **On the model:** anything with meaning beyond the current screen — pools, stacks, tracked Conditions, gear state.
- **Ephemeral widget state:** pure calculators and scratchpads — the References attack calculator's inputs, the Damage Calculator fields, the combat tracker's phase/Round/Actions and Battlefield picks.

The test for which side something belongs on: *would a player expect it to still be there after closing the app?*

### Visual language

Editable inputs are outlined fields; computed values are tinted read-only chips (`DerivedStat`). This deliberately mirrors the original spreadsheet's greyed formula cells — the visual grammar its users already know: *outlined = yours to change, tinted = the engine's answer.*

### List rows and widget identity

Repeating editable rows (tracked Conditions, Resources, gear) key their stateful inner widgets by **row object identity**, not by index or by the value being edited. Index keys leave a deleted row's element state attached to its successor (a dropdown showing the removed row's pick); value-based keys remount the field on every keystroke and drop the cursor. Identity keys (`ObjectKey(entry)`) get both cases right: stable while editing, correctly re-seeded when rows are added or removed.

### Responsiveness

Content is width-capped for readability, and the densest screens (the Character sheet, the combat tracker) split into two balanced columns under a single shared scroll view above a 1000-logical-pixel breakpoint. The column split is curated rather than computed because section heights vary wildly; a naive balancer would put the 21-row Skills block anywhere.

---

## 9. The combat tracker

The combat page (opened via "Start Combat") is a live table companion built on three ideas:

1. **The phase cycle is the spine.** Start of Combat → Start of Round → Start of Turn → End of Turn → repeat, with the Round boundary carrying the real automation: Actions reset (respecting Reduced Momentum), Counter Actions reset, and the Diminishing Offense/Defense trackers clear — each backed by the verbatim rule it implements. Phase state is ephemeral; mutations to real tracked values go through the same working copy as the editor, so combat damage persists exactly when the player saves.

2. **Reminders are scanned, not hand-listed.** The reminder engine (`services/combat_reminders.dart`) classifies every piece of rules text the character currently possesses — active Racial Traits and their chosen Options, Talents, Transformation Traits in effect, Aspects, tracked Conditions/States/Resources, worn and wielded gear Qualities, equipped Accessories, Unique Abilities, homebrew, and the session's Battlefield picks — against the timing phrases the rules actually use ("at the start of your turn," "at the end of each Combat Round," "when a Combat Encounter starts," "if you end your Turn in…"). Matching *sentences* (verbatim, live-annotated) surface on the right phase card and pop up on phase advance.

   The scanner is **purely textual and read-only by design**: it never applies anything to a stat, so it can never double-apply an effect the calculator already automates. The two systems are complementary — automation handles what is computable, reminders handle what the player must do at the right moment. Reminders for a round boundary are gathered *before* the boundary's automation mutates state, so "your Diminishing Defense clears now" can still be shown about the stacks that were just cleared.

3. **Reference is a first-class feature.** The complete Maneuver catalogue (Standard/Instant/Counter/Modifier/Special), the Battle Weather/Environment/Light Level catalogues, and the end-of-encounter rules are on the page verbatim with live token annotation — because at the table, "what exactly does Guard cost?" is a mid-fight question. Attacking routes into the same attack calculator the References tab uses, hosted as its own page, and finishing it with "Attack made" feeds the Diminishing Offense counting.

The tracker also hosts the Information / Transformations / Inventory / Signatures / Unique Abilities tabs directly, on the same working copy, because transforming is the single most common mid-combat action and should not require leaving the tracker. Any change made there re-derives stats and re-feeds the reminder scan immediately.

---

## 10. Homebrew

The homebrew system's central decision: **player-authored content converts into the same definition types the official catalogues use.** A homebrew Race becomes a `RaceDef`, a homebrew Transformation a `TransformationDef`, a homebrew Weapon Quality a `WeaponQualityDef`, and so on — each entering the engine through one resolver per type that checks the official catalogue first (the official entry wins any name clash).

**Why:** the alternative — a parallel "homebrew effects" code path — would bifurcate every feature forever. By converting at the boundary, homebrew content participates in AMB, Stacks and Grades, Aspects, the buffs pipeline, cost math, warnings, and combat reminders with no engine awareness that it isn't official. Homebrew authoring uses the same `RaceTraitAutomation` vocabulary through enum-driven forms, so the authoring surface grows automatically as the vocabulary does.

Categories that are inherently freeform (a Talent, a loose Racial Trait, "Other") stay generic: possession of the entry *is* the effect, via the same buffs pipeline.

Character export bundles every homebrew definition the character references, so a shared character is self-contained at the receiving table.

---

## 11. Persistence and sharing

- `character_repository.dart` serializes the whole roster to one JSON string under a single `shared_preferences` key — identical behaviour on all five platforms, and the only file that touches storage. `loadAll` fails safe (empty roster over crash). If the roster ever outgrows this, the swap is contained to one file.
- **Why `shared_preferences` and nothing else:** it is the one storage plugin with first-class support on every target, and the roster is small (text). A database would add per-platform failure modes for no user-visible benefit. Keeping the dependency list at exactly one package is a deliberate portability stance — before any dependency is added, it must support Android, iOS, Windows, macOS, and Web.
- Import/export uses a versioned envelope with compact codes; characters bundle their referenced homebrew (see §10).

### The additive sync helpers

Two helpers run on the editor's update path: one ensures Resources granted by active Racial Traits exist in the tracked list; one ensures Talents picked through Progression appear in the Talent list. Both are **additive and idempotent** — they only add missing entries, never edit or remove.

**Why never remove:** the player may have annotated or adjusted the synced entry, and races/choices can change transiently while editing. One-way sync makes the helpers safe to run on every keystroke; cleanup stays a human decision.

---

## 12. Testing philosophy

The suite (`character_calculator_test.dart`, at the repository root) is the project's executable rules record:

- **Formula pins.** Every confirmed formula has a test asserting exact values, usually mirroring the rules text in its comment. A regression is caught as a diff against the rules, not as a vague failure.
- **Catalogue pins.** Exact counts and structural invariants (unique names, required fields per entry type) keep the catalogues honest.
- **Round-trip tests.** Model serialization is exercised both directly and through the import/export envelope, including tolerance cases (missing keys, stale names).
- **A widget smoke test** drives the combat tracker end to end — phase advancing, the round-boundary automation, reminder popups, attack counting, tab hosting — because the tracker's value is in its *behaviour*, not its arithmetic.

The test file living at the root (not `test/`) is a historical quirk; it must be named explicitly when running (`flutter test character_calculator_test.dart`).

---

## 13. Rules provenance workflow

All rules content comes from the official DBU website.
---

## 14. Policy summary

For quick reference, the standing policies that shape every change:

1. **Raw choices in, everything else computed.** No derived value is ever persisted.
2. **Choice → model, catalogue → `lib/data/`, formula → calculator.** Never blend.
3. **Transcribe verbatim; automate everything mechanically resolvable; label the rest "not automated."**
4. **The live site wins** over any older source; verify against the offline archive for exact text.
5. **Tolerant persistence.** Old saves load; unknown keys are ignored; stale names fail soft and visibly.
6. **Warnings, not clamps.** The sheet flags rule violations; it does not overwrite the player's input.
7. **One dependency, five platforms.** No platform-specific code in `lib/`.
8. **Headers stay current; `dart analyze` clean; the test suite green.** Every change ends with all three.
