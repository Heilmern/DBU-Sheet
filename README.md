# DBU Character Sheet

An unofficial, cross-platform character sheet app for the **Dragon Ball Universe (DBU)** tabletop RPG (<https://dbu-rpg.com/>). It reimagines the community's original Google-Sheets character sheet as a native app, driven by the current rules on the DBU website.

Built with **Flutter** from a single codebase targeting **Android, iOS, Windows, macOS and Web**.

> This is a fan-made tool and is not affiliated with or endorsed by the DBU team. All game rules and terminology belong to their respective creators.

---

## What it does

A full character builder and live rules engine. You enter only the choices a player actually makes — Attribute increases, Skill Ranks, Power Level, owned Transformations, gear, and so on — and every derived number (Max Life, Skill bonuses, Aptitudes, combat rolls, resource pools) is recomputed on the fly. Nothing derived is ever stored, so a rules change can never leave a stale total on disk.

The character editor is organised into eight tabs:

- **Character** — identity, race, size, Power Level → live Tier of Power; the seven Attributes, Skills, Status pools (Life / Ki / Capacity), Aptitudes, Saving Throws, Combat Rolls, Z-Soul, and freeform Custom Buffs.
- **Information** — Racial Traits, Factors, and Talents, with their numeric effects applied automatically — including Traits adopted from other Races (table-approved cross-Race picks that apply exactly like native ones).
- **Progression** — the Progression grant track (Attribute increases, Skill Improvements, and what each level unlocks).
- **Transformations** — Awakenings (Lesser / Greater / Super), Enhancements, and Forms (Alternate Forms, Evolved Stages, Legendary Forms), including Aspects, Stacks, and Grand Awakenings.
- **Inventory** — Apparel and Weapons (with Craftsmanship Grades and Qualities), plus Accessories, Basic Items, and freeform Gear.
- **Signatures** — the Signature Techniques builder (Foundations, Profiles, Advantages/Disadvantages) with live TP and KP cost math.
- **Unique Abilities** — the Unique Abilities catalogue with Advancements, Restrictions, and cost math.
- **References** — a scratchpad attack-roll calculator that assembles Strike / Wound / Dodge / Duel roll strings, dice expressions, Ki costs, and damage categories from the character's current state.

Beyond the editor:

- **Combat tracker** — a "Start Combat" button opens a live combat companion that walks the phase cycle (Start of Combat → Start of Round → Start of Turn → End of Turn → repeat), resets Actions and clears the Diminishing trackers on the round boundary, counts attacks (auto-applying Diminishing Offense after the third), hosts a damage calculator and Battlefield pickers (Weather / Environment / Light), and **pops up reminders scanned from everything the character possesses** — any owned Trait, Talent, Transformation, Condition, State, gear Quality, or ability whose rules text names the current timing ("at the start of your turn", "end of each Combat Round", …) surfaces its verbatim sentence on the right phase. The full Maneuver catalogue rides along as live-annotated reference, and the Information / Transformations / Inventory / Signatures / Unique Abilities tabs are available in-combat so transforming mid-fight is one tap.
- **Homebrew library** — player-authored Races, Conditions, States, Transformations, Factors, gear Qualities, Accessories, Basic Items, Signature modifiers, and Unique Abilities, authored with the same automation vocabulary the official catalogues use, so they plug into the exact same rules engine (the official catalogue wins any name clash).
- **Import / Export** — characters share as compact codes that bundle every homebrew definition they reference, so a character arrives at another table fully working.

Editable inputs are outlined fields; **computed values are tinted read-only chips**, mirroring how the spreadsheet greyed-out its formula cells. Every derived number recalculates instantly as you edit, and characters persist on-device on every platform.

---

## Project layout

```
lib/
├── main.dart                          App entry, theme, repository bootstrap
├── data/                              Static rules content (one file per domain)
│   ├── dbu_rules.dart                 SINGLE SOURCE OF TRUTH for core rules data
│   │                                  (attributes, skills, sizes, races, PL table,
│   │                                   progression grants, dice rules)
│   ├── transformations.dart           Shared Transformation model + enums
│   ├── awakenings.dart / greater_awakenings.dart / super_awakenings.dart
│   ├── enhancements.dart / forms.dart / aspects.dart
│   ├── apparel.dart / weapons.dart / accessories.dart / basic_items.dart
│   ├── signature_profiles.dart / signature_modifiers.dart
│   ├── unique_abilities.dart
│   ├── race_traits.dart / factor_traits.dart / talents.dart
│   ├── custom_species_traits.dart / custom_buff_targets.dart
│   └── …
├── models/
│   └── character.dart                 Persisted character model (raw choices + JSON)
├── services/
│   ├── character_calculator.dart      The RULES ENGINE — all derived values
│   ├── character_repository.dart      Cross-platform persistence (shared_preferences)
│   ├── race_resource_sync.dart        Additive sync helpers (never edit/remove)
│   └── progression_talent_sync.dart
└── ui/
    ├── character_list_screen.dart     The roster/menu
    ├── character_edit_screen.dart     The 8-tab editor shell
    ├── information_screen.dart / progression_screen.dart
    ├── transformations_screen.dart / inventory_screen.dart
    ├── signatures_screen.dart / unique_abilities_screen.dart
    ├── references_screen.dart
    └── widgets/                       SectionCard, DerivedStat, TP budget, etc.
```

### Design principle: raw data in, derived data computed

The saved model (`character.dart`) stores **only what the player chooses** — Attribute increases, Skill Ranks, Power Level, biography, Z-Soul, owned content, current resource pools. It never stores computed totals (Max Life, Skill bonuses, Aptitudes, Attribute Scores). Those are recomputed on demand by `character_calculator.dart`.

Why this matters: when a DBU formula changes, you edit **one file** and every saved character updates automatically — no stale or wrong numbers can ever be written to disk. See [DEVELOPING.md](DEVELOPING.md) for the full architecture and a guide to adding new content.

---

## Getting started

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel; the project targets Dart SDK `^3.12`).

The per-platform host folders (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`) are generated by Flutter and contain no app logic — all app code lives under `lib/`. If they're missing, generate them once with `flutter create .` (this does **not** overwrite anything in `lib/`).

```bash
flutter pub get            # fetch dependencies (only shared_preferences)

flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d macos       # macOS
flutter run                # Android/iOS device, emulator, or simulator
```

### Building release artifacts

```bash
flutter build apk          # Android
flutter build ios          # iOS  (requires Xcode, on macOS)
flutter build web          # Web
flutter build windows      # Windows
flutter build macos        # macOS
```

### Tests and analysis

The test suite lives at the repository root (not in a `test/` directory), so it must be named explicitly:

```bash
dart analyze                                        # must be clean
flutter test character_calculator_test.dart         # run the suite
```

Run a single test/group by name substring:

```bash
flutter test character_calculator_test.dart --plain-name "Awakening Limit table"
```

### Cross-platform notes

- The only third-party dependency is **`shared_preferences`**, which is officially supported on all five targets, so there is **no platform-specific code** in `lib/`.
- iOS/macOS builds require **Xcode**; Windows builds require **Visual Studio** with the “Desktop development with C++” workload. These are Flutter's standard toolchain requirements, not app-specific.
- The UI is responsive: content is width-capped so it reads well from a phone up to a maximized desktop window.

---

## Rules provenance

All rules data is transcribed from the official DBU website as of 10/07/2026. Effect and trait wording is copied verbatim; every mechanically-resolvable effect is wired into the calculator so the on-screen numbers stay consistent with the rules, and situational or GM-adjudicated effects are surfaced as labelled reference text.

The `character_calculator_test.dart` suite pins the confirmed formulas and catalogue counts, and doubles as executable documentation of the rules engine.

---

## Contributing

See [DEVELOPING.md](DEVELOPING.md) for the working guide (how to add a choice, catalogue entry, or formula) and [Explanation.md](Explanation.md) for the full design rationale — what each part of the code does and why it was built that way. In short: **a new *choice* goes on the model, a new *catalogue* goes in `lib/data/`, and a new *formula* goes in the calculator** — never blend the three. After any change, `dart analyze` must be clean and `flutter test character_calculator_test.dart` must pass.

---

## License

Fan project for personal/table use. Respect the DBU creators' rights to the underlying game system.
