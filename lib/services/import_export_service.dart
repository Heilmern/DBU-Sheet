/// import_export_service.dart
/// ---------------------------------------------------------------------------
/// Portable import/export of characters as a versioned, self-describing
/// "share code" — the mechanism that lets players move characters between
/// devices and (eventually) share homebrew.
///
/// This layer is PURE Dart: no Flutter, no files, no storage — it only reads
/// the models plus the runtime homebrew catalogue (`HomebrewRegistry`, needed
/// to resolve which homebrew a character uses so it can be bundled). That keeps
/// it unit-testable and keeps the actual transfer mechanism (clipboard today, a
/// `.json` file later) a thin layer on top — both just move the String this
/// class produces.
///
/// The portable unit is a small ENVELOPE wrapping any payload:
///
///   {
///     "dbu": 1,                     // envelope schema version
///     "kind": "character",          // future: "homebrew.transformation", ...
///     "app": "0.1.0",               // exporting app version (informational)
///     "exportedAt": "2026-07-17…",  // ISO-8601 timestamp
///     "payload": { …Character.toJson()… },
///     "homebrew": [ …HomebrewEntry.toJson()… ]   // character codes only
///   }
///
/// A character code BUNDLES every homebrew definition it references, so the
/// code is self-contained: a recipient who doesn't have your homebrew still
/// gets a character whose numbers work. On import, bundled definitions the
/// player doesn't already have (matched by name) are added to their library;
/// same-named homebrew they already own is never overwritten.
///
/// The `dbu` version is the forward-compat hook: a code made by a NEWER app
/// (higher `dbu`) is rejected with a clear message instead of loading a payload
/// this build can't understand. Older payloads always load, because
/// `Character.fromJson` already ignores missing/extra keys.
///
/// Design choices worth knowing:
///  • Import ALWAYS assigns a fresh id (via the injected `newId` callback) so an
///    imported character is added as a NEW roster entry — importing never
///    silently overwrites an existing character, and importing the same code
///    twice yields two independent copies.
///  • Import is tolerant of three input shapes: the envelope JSON, base64 of the
///    envelope JSON (survives chat/email that mangles raw JSON), or — as a last
///    resort — a bare `Character.toJson()` map with no envelope.
///  • Nothing throws for bad input: [importCharacter] returns a result object
///    carrying either the character or a human-readable error, so the UI can
///    show a message without a try/catch.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import '../data/homebrew_registry.dart';
import '../models/character.dart';
import '../models/homebrew.dart';

/// Outcome of an import attempt: exactly one of [character] / [error] is set.
class CharacterImportResult {
  const CharacterImportResult.success(
    Character this.character, {
    this.bundledHomebrew = const [],
  }) : error = null;

  const CharacterImportResult.failure(String this.error)
      : character = null,
        bundledHomebrew = const [];

  /// The imported character (with a fresh id) on success, else null.
  final Character? character;

  /// A human-readable failure reason on error, else null.
  final String? error;

  /// Homebrew definitions that travelled with the character (each already
  /// given a fresh id). The caller decides what to add to the library — see
  /// the import flow in `character_list_screen.dart`, which adds only names
  /// the player doesn't already have.
  final List<HomebrewEntry> bundledHomebrew;

  bool get ok => character != null;
}

/// Outcome of a homebrew import: exactly one of [entry] / [error] is set.
class HomebrewImportResult {
  const HomebrewImportResult.success(HomebrewEntry this.entry) : error = null;
  const HomebrewImportResult.failure(String this.error) : entry = null;

  final HomebrewEntry? entry;
  final String? error;

  bool get ok => entry != null;
}

/// Outcome of importing a MULTI-character bundle (see [ImportExportService.
/// exportCharacters]): exactly one of [characters] / [error] is set.
class CharactersImportResult {
  const CharactersImportResult.success(
    List<Character> this.characters, {
    this.bundledHomebrew = const [],
  }) : error = null;

  const CharactersImportResult.failure(String this.error)
      : characters = null,
        bundledHomebrew = const [];

  /// The imported characters (each with a fresh id) on success, else null.
  final List<Character>? characters;

  final String? error;

  /// Every homebrew definition bundled with ANY of the characters, de-duplicated
  /// by name (each already given a fresh id).
  final List<HomebrewEntry> bundledHomebrew;

  bool get ok => characters != null;
}

/// Outcome of importing a MULTI-homebrew bundle (see [ImportExportService.
/// exportHomebrewSet]): exactly one of [entries] / [error] is set.
class HomebrewSetImportResult {
  const HomebrewSetImportResult.success(List<HomebrewEntry> this.entries)
      : error = null;
  const HomebrewSetImportResult.failure(String this.error) : entries = null;

  final List<HomebrewEntry>? entries;
  final String? error;

  bool get ok => entries != null;
}

class ImportExportService {
  ImportExportService._();

  /// Current envelope schema version. Bump when the envelope shape changes in a
  /// way older builds can't read; [importCharacter] rejects anything higher.
  static const int schemaVersion = 1;

  /// The `kind` tag for a character envelope. Homebrew will use its own tags.
  static const String characterKind = 'character';

  /// The `kind` tag for a homebrew envelope.
  static const String homebrewKind = 'homebrew';

  /// The `kind` tag for a MULTI-character bundle (see [exportCharacters]).
  static const String charactersKind = 'characters';

  /// The `kind` tag for a MULTI-homebrew bundle (see [exportHomebrewSet]).
  static const String homebrewSetKind = 'homebrewSet';

  /// Exporting app version, recorded for diagnostics. Keep in step with
  /// `pubspec.yaml`'s `version:` when it matters; it's informational only.
  static const String appVersion = '0.1.0';

  /// Every homebrew definition [c] references — active or not, de-duplicated,
  /// resolved from the runtime registry. Beyond the explicit
  /// `homebrewSelections`, a character can now reference structured homebrew
  /// through its Race, tracked Conditions, owned Transformations and Factor
  /// swaps — all of those are bundled too, so the code stays self-contained.
  /// Names that don't resolve to homebrew (official catalogue content or
  /// freeform text) are skipped (there's nothing to bundle).
  ///
  /// Inactive selections are included on purpose: the recipient should receive
  /// the definition so they can toggle it on, not just the ones switched on at
  /// export time.
  static List<HomebrewEntry> referencedHomebrew(Character c) {
    final out = <HomebrewEntry>[];
    final seen = <String>{};
    void add(String name, [bool Function(HomebrewEntry)? test]) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      final def = HomebrewRegistry.byName(name);
      if (def != null && (test == null || test(def))) out.add(def);
    }

    for (final s in c.homebrewSelections) {
      add(s.name);
    }
    add(c.race, (e) => e.category == HomebrewCategory.race);
    for (final entry in c.conditions) {
      add(entry.name, (e) => e.category == HomebrewCategory.condition);
    }
    for (final entry in c.states) {
      add(entry.name, (e) => e.category == HomebrewCategory.state);
    }
    for (final s in c.transformations) {
      add(s.name, (e) => e.isTransformationLike);
    }
    for (final f in c.factorSelections) {
      add(f.factorName, (e) => e.category == HomebrewCategory.factorTrait);
    }
    for (final piece in c.apparel) {
      for (final q in piece.qualities) {
        add(q.name, (e) => e.category == HomebrewCategory.apparelQuality);
      }
    }
    for (final weapon in c.weapons) {
      for (final q in weapon.qualities) {
        add(q.name, (e) => e.category == HomebrewCategory.weaponQuality);
      }
    }
    for (final a in c.accessories) {
      add(a.name, (e) => e.category == HomebrewCategory.accessory);
    }
    for (final b in c.basicItems) {
      add(b.name, (e) => e.category == HomebrewCategory.basicItem);
    }
    for (final tech in c.signatureTechniques) {
      for (final m in [...tech.advantages, ...tech.disadvantages]) {
        add(m.name, (e) => e.category == HomebrewCategory.signatureModifier);
      }
    }
    for (final ua in c.uniqueAbilities) {
      add(ua.name, (e) => e.category == HomebrewCategory.uniqueAbility);
    }
    return out;
  }

  /// Wraps [character] in an envelope and returns pretty-printed JSON suitable
  /// for copying to the clipboard or writing to a `.json` file.
  ///
  /// Any homebrew the character uses is BUNDLED alongside the payload (as a
  /// sibling `homebrew` array, so the character's own JSON stays untouched),
  /// making the code self-contained: a recipient who has never seen your
  /// homebrew still gets a character whose numbers work. Pass [homebrew]
  /// explicitly to override what gets bundled; by default it's resolved from
  /// the runtime registry via [referencedHomebrew].
  static String exportCharacter(
    Character character, {
    DateTime? now,
    List<HomebrewEntry>? homebrew,
  }) {
    final bundled = homebrew ?? referencedHomebrew(character);
    final envelope = <String, dynamic>{
      'dbu': schemaVersion,
      'kind': characterKind,
      'app': appVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'payload': character.toJson(),
      if (bundled.isNotEmpty)
        'homebrew': bundled.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses a share code (envelope JSON, base64 of it, or a bare character map)
  /// and returns the resulting character with a fresh id from [newId].
  ///
  /// Never throws: malformed input yields a [CharacterImportResult.failure].
  static CharacterImportResult importCharacter(
    String raw, {
    required String Function() newId,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const CharacterImportResult.failure('Nothing to import — the code is empty.');
    }

    final resolved =
        _resolvePayload(text, expectedKind: characterKind, label: 'character');
    if (resolved.error != null) {
      return CharacterImportResult.failure(resolved.error!);
    }

    // Assign a fresh id so the import is always added as a new roster entry.
    final withNewId = Map<String, dynamic>.from(resolved.payload!)
      ..['id'] = newId();

    try {
      return CharacterImportResult.success(
        Character.fromJson(withNewId),
        bundledHomebrew: _bundledHomebrew(resolved.envelope, newId),
      );
    } catch (_) {
      return const CharacterImportResult.failure(
        "The character code is corrupted and couldn't be read.",
      );
    }
  }

  /// Wraps every character in [characters] into ONE bundle envelope — the
  /// "export all/multiple" flow. Payload is a LIST of `Character.toJson()`;
  /// the bundled `homebrew` array is the union (de-duplicated by name) of what
  /// every included character references, so the single code stays
  /// self-contained no matter how many characters share homebrew.
  static String exportCharacters(
    List<Character> characters, {
    DateTime? now,
  }) {
    final bundled = <HomebrewEntry>[];
    final seen = <String>{};
    for (final c in characters) {
      for (final entry in referencedHomebrew(c)) {
        final key = entry.name.trim().toLowerCase();
        if (seen.add(key)) bundled.add(entry);
      }
    }
    final envelope = <String, dynamic>{
      'dbu': schemaVersion,
      'kind': charactersKind,
      'app': appVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'payload': characters.map((c) => c.toJson()).toList(),
      if (bundled.isNotEmpty)
        'homebrew': bundled.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses a multi-character bundle code and returns each character with a
  /// fresh id from [newId]. Never throws: malformed input yields a
  /// [CharactersImportResult.failure]. A single-character code (or a bare
  /// payload) also works here, imported as a one-element list, so the UI can
  /// point one "Import" action at either shape.
  static CharactersImportResult importCharacters(
    String raw, {
    required String Function() newId,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const CharactersImportResult.failure(
          'Nothing to import — the code is empty.');
    }

    final resolved = _resolveListPayload(text,
        expectedKind: charactersKind,
        singularKind: characterKind,
        label: 'character');
    if (resolved.error != null) {
      return CharactersImportResult.failure(resolved.error!);
    }

    final out = <Character>[];
    for (final m in resolved.payloads!) {
      try {
        out.add(Character.fromJson({...m, 'id': newId()}));
      } catch (_) {
        // Skip a corrupt entry; the rest of the bundle still imports.
      }
    }
    if (out.isEmpty) {
      return const CharactersImportResult.failure(
          "The character code is corrupted and couldn't be read.");
    }
    return CharactersImportResult.success(
      out,
      bundledHomebrew: _bundledHomebrew(resolved.envelope, newId),
    );
  }

  /// Reads the envelope's bundled `homebrew` array, giving each entry a fresh,
  /// unique id so adding them can never overwrite unrelated library entries.
  /// Malformed entries are skipped rather than failing the whole import.
  static List<HomebrewEntry> _bundledHomebrew(
    Map<String, dynamic>? envelope,
    String Function() newId,
  ) {
    final raw = envelope?['homebrew'];
    if (raw is! List) return const [];
    final out = <HomebrewEntry>[];
    var i = 0;
    for (final m in raw.whereType<Map<String, dynamic>>()) {
      try {
        out.add(HomebrewEntry.fromJson({...m, 'id': '${newId()}-hb${i++}'}));
      } catch (_) {
        // Skip a corrupt bundled definition; the character still imports.
      }
    }
    return out;
  }

  /// Wraps [entry] in a homebrew envelope and returns pretty-printed JSON.
  static String exportHomebrew(HomebrewEntry entry, {DateTime? now}) {
    final envelope = <String, dynamic>{
      'dbu': schemaVersion,
      'kind': homebrewKind,
      'app': appVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'payload': entry.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses a homebrew share code and returns the entry with a fresh id.
  /// Never throws: malformed input yields a [HomebrewImportResult.failure].
  static HomebrewImportResult importHomebrew(
    String raw, {
    required String Function() newId,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const HomebrewImportResult.failure('Nothing to import — the code is empty.');
    }

    final resolved =
        _resolvePayload(text, expectedKind: homebrewKind, label: 'homebrew');
    if (resolved.error != null) {
      return HomebrewImportResult.failure(resolved.error!);
    }

    final withNewId = Map<String, dynamic>.from(resolved.payload!)
      ..['id'] = newId();

    try {
      return HomebrewImportResult.success(HomebrewEntry.fromJson(withNewId));
    } catch (_) {
      return const HomebrewImportResult.failure(
        "The homebrew code is corrupted and couldn't be read.",
      );
    }
  }

  /// Wraps every entry in [entries] into ONE bundle envelope — the "export
  /// all/multiple" flow for the Homebrew library. Payload is a LIST of
  /// `HomebrewEntry.toJson()`.
  static String exportHomebrewSet(List<HomebrewEntry> entries, {DateTime? now}) {
    final envelope = <String, dynamic>{
      'dbu': schemaVersion,
      'kind': homebrewSetKind,
      'app': appVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'payload': entries.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(envelope);
  }

  /// Parses a multi-homebrew bundle code and returns each entry with a fresh
  /// id from [newId]. Never throws: malformed input yields a
  /// [HomebrewSetImportResult.failure]. A single-homebrew code (or a bare
  /// payload) also works here, imported as a one-element list.
  static HomebrewSetImportResult importHomebrewSet(
    String raw, {
    required String Function() newId,
  }) {
    final text = raw.trim();
    if (text.isEmpty) {
      return const HomebrewSetImportResult.failure(
          'Nothing to import — the code is empty.');
    }

    final resolved = _resolveListPayload(text,
        expectedKind: homebrewSetKind,
        singularKind: homebrewKind,
        label: 'homebrew');
    if (resolved.error != null) {
      return HomebrewSetImportResult.failure(resolved.error!);
    }

    final out = <HomebrewEntry>[];
    for (final m in resolved.payloads!) {
      try {
        out.add(HomebrewEntry.fromJson({...m, 'id': newId()}));
      } catch (_) {
        // Skip a corrupt entry; the rest of the bundle still imports.
      }
    }
    if (out.isEmpty) {
      return const HomebrewSetImportResult.failure(
          "The homebrew code is corrupted and couldn't be read.");
    }
    return HomebrewSetImportResult.success(out);
  }

  /// Shared envelope resolver for a MULTI-entry bundle. Accepts three shapes:
  /// a bundle envelope (`kind == expectedKind`, `payload` a List), a SINGLE
  /// envelope of the singular kind (`payload` a Map — wrapped as a one-element
  /// list, so "Import" works on either an individual or a bundled code), or a
  /// bare List/Map with no envelope markers.
  static ({
    List<Map<String, dynamic>>? payloads,
    Map<String, dynamic>? envelope,
    String? error,
  }) _resolveListPayload(
    String text, {
    required String expectedKind,
    required String singularKind,
    required String label,
  }) {
    final decoded = _decodeJson(text);
    if (decoded is List) {
      return (
        payloads: decoded.whereType<Map<String, dynamic>>().toList(),
        envelope: null,
        error: null,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return (
        payloads: null,
        envelope: null,
        error:
            "That doesn't look like a $label code. Paste the full code you copied.",
      );
    }

    if (decoded.containsKey('payload') || decoded.containsKey('dbu')) {
      final version = (decoded['dbu'] as num?)?.toInt();
      if (version != null && version > schemaVersion) {
        return (
          payloads: null,
          envelope: null,
          error: 'This $label was exported by a newer version of the app. '
              'Update the app, then try importing again.',
        );
      }
      final kind = decoded['kind'] as String?;
      if (kind != null && kind != expectedKind && kind != singularKind) {
        return (
          payloads: null,
          envelope: null,
          error: 'This code is a "$kind", not a $label.',
        );
      }
      final rawPayload = decoded['payload'];
      if (rawPayload is List) {
        return (
          payloads: rawPayload.whereType<Map<String, dynamic>>().toList(),
          envelope: decoded,
          error: null,
        );
      }
      if (rawPayload is Map<String, dynamic>) {
        return (payloads: [rawPayload], envelope: decoded, error: null);
      }
      return (
        payloads: null,
        envelope: null,
        error: 'The $label code is missing its data.',
      );
    }

    // No envelope markers: treat the whole object as a single bare payload.
    return (payloads: [decoded], envelope: null, error: null);
  }

  /// Shared envelope resolver for both character and homebrew imports.
  /// Returns the inner payload map, or an error message. Tolerates a raw
  /// envelope, a base64-wrapped envelope, and a bare (envelope-less) payload.
  static ({
    Map<String, dynamic>? payload,
    Map<String, dynamic>? envelope,
    String? error,
  }) _resolvePayload(
    String text, {
    required String expectedKind,
    required String label,
  }) {
    final decoded = _decodeJson(text);
    if (decoded is! Map<String, dynamic>) {
      return (
        payload: null,
        envelope: null,
        error:
            "That doesn't look like a $label code. Paste the full code you copied.",
      );
    }

    if (decoded.containsKey('payload') || decoded.containsKey('dbu')) {
      final version = (decoded['dbu'] as num?)?.toInt();
      if (version != null && version > schemaVersion) {
        return (
          payload: null,
          envelope: null,
          error: 'This $label was exported by a newer version of the app. '
              'Update the app, then try importing again.',
        );
      }
      final kind = decoded['kind'] as String?;
      if (kind != null && kind != expectedKind) {
        return (
          payload: null,
          envelope: null,
          error: 'This code is a "$kind", not a $label.',
        );
      }
      final rawPayload = decoded['payload'];
      if (rawPayload is! Map<String, dynamic>) {
        return (
          payload: null,
          envelope: null,
          error: 'The $label code is missing its data.',
        );
      }
      return (payload: rawPayload, envelope: decoded, error: null);
    }

    // No envelope markers: treat the whole object as a bare payload.
    return (payload: decoded, envelope: null, error: null);
  }

  /// Tries to decode [text] as JSON, then (if that fails) as base64-of-JSON.
  /// Returns the decoded value, or null if neither works.
  static dynamic _decodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      // Fall through to a base64 attempt.
    }
    try {
      final bytes = base64.decode(base64.normalize(text));
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }
}
