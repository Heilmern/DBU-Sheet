/// changelog.dart
/// ---------------------------------------------------------------------------
/// The app's release notes, as structured data.
///
/// Each release is a [ChangelogEntry] carrying its version, date and a grouped
/// list of changes. The list [kChangelog] is ordered NEWEST-FIRST — the first
/// entry is always the current release, and [currentVersion] is derived from
/// it, so there's a single source of truth for "what version am I running".
///
/// TO ADD A RELEASE: prepend a new [ChangelogEntry] to the top of [kChangelog].
/// Keep the `version` in step with `pubspec.yaml`'s version. Group changes by
/// [ChangeKind] (added / changed / fixed) so the screen can badge them.
/// ---------------------------------------------------------------------------
library;

/// The category a single change falls under — drives its colour/label badge
/// on the Changelog screen.
enum ChangeKind {
  added('Added'),
  changed('Changed'),
  fixed('Fixed');

  const ChangeKind(this.label);

  /// Human-readable badge text (e.g. "Added").
  final String label;
}

/// One line item within a release.
class ChangelogChange {
  const ChangelogChange(this.kind, this.text);

  final ChangeKind kind;
  final String text;
}

/// A single released version and everything that shipped in it.
class ChangelogEntry {
  const ChangelogEntry({
    required this.version,
    required this.date,
    this.headline,
    required this.changes,
  });

  /// Semantic version string, e.g. "0.1.0". Kept in step with `pubspec.yaml`.
  final String version;

  /// Human-readable release date, e.g. "21 Jul 2026".
  final String date;

  /// Optional one-line summary shown under the version heading.
  final String? headline;

  /// The individual changes in this release.
  final List<ChangelogChange> changes;
}

/// The version of the release at the top of [kChangelog].
String get currentVersion => kChangelog.first.version;

/// Every release, NEWEST FIRST. Prepend new entries here.
const List<ChangelogEntry> kChangelog = [
    ChangelogEntry(
    version: '0.1.1',
    date: '21 Jul 2026',
    headline: 'First public testing build of Universal Scouter — the '
        'unofficial Dragon Ball Universe character sheet and rules engine.',
    changes: [
      ChangelogChange(ChangeKind.added,
          'Added natural armor to the Racial Traits of all Races that have it.'),
      ChangelogChange(ChangeKind.fixed,
          'Fixed Z-soul names.'),
      ChangelogChange(ChangeKind.fixed,
          'practiced now allows you to select the two extra skills you get from it.'),
      ChangelogChange(ChangeKind.fixed,
          'Fixed a bug with Custom buffs not showing correctly on the character sheet.'),
      ChangelogChange(ChangeKind.added,
          'A confirmation before leaving a character edit screen with unsaved changes.'),
      ChangelogChange(ChangeKind.fixed,
          'Fixed a bug with the combat tracker not resetting correctly on round boundary.'),
      ChangelogChange(ChangeKind.changed,
          'Changed where the progression preview is shown, it is now on top of the progression tab.'),
      ChangelogChange(ChangeKind.fixed,
          'Fixed the very awkaward bug where typing a talent name would add fake talents in the information tabs.'),
      ChangelogChange(ChangeKind.changed,
          'In the combat tracker, the attack reminders in the attack tab are now on their own column.'),
      ChangelogChange(ChangeKind.changed,
          'Techniques are now on two columns.'),
    ],
  ),
  ChangelogEntry(
    version: '0.1.0',
    date: '21 Jul 2026',
    headline: 'First public testing build of Universal Scouter — the '
        'unofficial Dragon Ball Universe character sheet and rules engine.',
    changes: [
      ChangelogChange(ChangeKind.added,
          'Live rules engine: you enter only the choices a player makes — '
          'Attribute increases, Skill Ranks, Power Level, owned content, gear '
          '— and every derived number (Max Life, Skill bonuses, Aptitudes, '
          'combat rolls, resource pools) recomputes on the fly. Nothing '
          'derived is stored, so numbers can never go stale on disk.'),
      ChangelogChange(ChangeKind.added,
          'Character tab: identity, race, size, Power Level and Tier of Power; '
          'the seven Attributes, Skills, Status pools (Life / Ki / Capacity), '
          'Aptitudes, Saving Throws, Combat Rolls, Z-Soul and freeform Custom '
          'Buffs.'),
      ChangelogChange(ChangeKind.added,
          'Information tab: Racial Traits, Factors and Talents with their '
          'numeric effects applied automatically — including Traits adopted '
          'from other Races, which apply exactly like native ones.'),
      ChangelogChange(ChangeKind.added,
          'Progression tab: the Progression grant track — Attribute '
          'increases, Skill Improvements and what each level unlocks.'),
      ChangelogChange(ChangeKind.added,
          'Transformations tab with complete catalogues: Awakenings '
          '(Lesser / Greater / Super), Enhancements, and Forms (Alternate '
          'Forms, Evolved Stages, Legendary Forms), including Aspects, Stacks '
          'and Grand Awakenings, all with live-automated effects.'),
      ChangelogChange(ChangeKind.added,
          'Inventory tab: Apparel and Weapons with Craftsmanship Grades and '
          'Qualities, plus Accessories, Basic Items and freeform Gear.'),
      ChangelogChange(ChangeKind.added,
          'Signatures tab: the Signature Techniques builder (Foundations, '
          'Profiles, Advantages / Disadvantages) with live TP and KP cost '
          'math.'),
      ChangelogChange(ChangeKind.added,
          'Unique Abilities tab: the full catalogue with Advancements and '
          'Restrictions.'),
      ChangelogChange(ChangeKind.added,
          'References tab: an attack-roll calculator that assembles Strike / '
          'Wound / Dodge / Duel rolls, dice expressions, Ki costs and damage '
          'categories from the character\'s current state.'),
      ChangelogChange(ChangeKind.added,
          'Combat tracker: a live companion that walks the phase cycle, '
          'resets Actions and Diminishing trackers on the round boundary, '
          'counts attacks (auto-applying Diminishing Offense after the '
          'third), and hosts a damage calculator plus Weather / Environment / '
          'Light battlefield pickers.'),
      ChangelogChange(ChangeKind.added,
          'In-combat reminders: every owned Trait, Talent, Transformation, '
          'Condition, State, Gear Quality or ability whose rules text names '
          'the current timing surfaces its verbatim sentence on the matching '
          'phase — with the full Maneuver catalogue riding along as reference.'),
      ChangelogChange(ChangeKind.added,
          'Homebrew library: author custom Races, Conditions, States, '
          'Transformations, Factors, gear Qualities, Accessories, Basic '
          'Items, Signature modifiers and Unique Abilities using the same '
          'automation vocabulary as the official catalogues, so they plug '
          'into the exact same engine (official definitions win any name '
          'clash).'),
      ChangelogChange(ChangeKind.added,
          'Import / Export: characters share as compact codes (or .json '
          'files) that bundle every homebrew definition they reference, so a '
          'character arrives at another table fully working.'),
      ChangelogChange(ChangeKind.added,
          'Cross-platform from a single codebase — Android, iOS, Windows, '
          'macOS and Web — with a responsive, width-capped UI and on-device '
          'persistence, following the OS light / dark preference.'),
      ChangelogChange(ChangeKind.added,
          'This changelog, reachable from the home screen.'),
    ],
  ),
];
