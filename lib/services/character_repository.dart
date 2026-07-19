/// character_repository.dart
/// ---------------------------------------------------------------------------
/// Persistence for the character roster.
///
/// Storage is done with `shared_preferences`, which provides ONE identical API
/// across all five target platforms (Android, iOS, Windows, macOS, Web). The
/// whole roster is serialized to a single JSON string under one key. For the
/// expected number of characters (tens, not thousands) this is simple, fast and
/// perfectly adequate; if the roster ever grows huge, this class is the only
/// place that would need to swap in a database — the rest of the app talks to
/// the repository interface, not to storage directly.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';

class CharacterRepository {
  CharacterRepository._(this._prefs);

  /// The storage key under which the JSON-encoded roster lives.
  static const String _storageKey = 'dbu_characters_v1';

  final SharedPreferences _prefs;

  /// Async factory — obtains the platform storage handle once and reuses it.
  static Future<CharacterRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CharacterRepository._(prefs);
  }

  /// Loads all saved characters, newest-updated first. Returns an empty list on
  /// first run or if the stored data is somehow unreadable (fails safe).
  Future<List<Character>> loadAll() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final chars = decoded
          .whereType<Map<String, dynamic>>()
          .map(Character.fromJson)
          .toList();
      chars.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return chars;
    } catch (_) {
      // Corrupt/incompatible data: don't crash the app, just start fresh.
      return [];
    }
  }

  /// Persists the entire roster.
  Future<void> _saveAll(List<Character> characters) async {
    final encoded =
        jsonEncode(characters.map((c) => c.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  /// Inserts a new character or updates an existing one (matched by id),
  /// stamping its `updatedAt`. Returns the updated roster.
  Future<List<Character>> upsert(Character character) async {
    character.updatedAt = DateTime.now();
    final all = await loadAll();
    final index = all.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      all[index] = character;
    } else {
      all.add(character);
    }
    await _saveAll(all);
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  /// Deletes a character by id. Returns the updated roster.
  Future<List<Character>> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((c) => c.id == id);
    await _saveAll(all);
    return all;
  }
}
