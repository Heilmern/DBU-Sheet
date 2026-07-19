/// homebrew_repository.dart
/// ---------------------------------------------------------------------------
/// Persistence for the player's HOMEBREW library — the custom Talents, Traits,
/// Transformations, etc. authored in the Homebrew maker.
///
/// Mirrors `CharacterRepository` exactly (same shared_preferences approach, one
/// JSON blob under one key) but under a SEPARATE key, so homebrew never bloats
/// the character save and the two can grow/version independently. Keeping the
/// stores separate is the mitigation for the web `localStorage` size limit if
/// a homebrew library ever gets large.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/homebrew.dart';

class HomebrewRepository {
  HomebrewRepository._(this._prefs);

  /// The storage key under which the JSON-encoded homebrew library lives.
  static const String _storageKey = 'dbu_homebrew_v1';

  final SharedPreferences _prefs;

  static Future<HomebrewRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return HomebrewRepository._(prefs);
  }

  /// Loads all homebrew entries, newest-updated first. Fails safe to `[]`.
  Future<List<HomebrewEntry>> loadAll() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(HomebrewEntry.fromJson)
          .toList();
      entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<HomebrewEntry> entries) async {
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  /// Inserts or updates (matched by id), stamping `updatedAt`. Returns the
  /// updated library, newest-updated first.
  Future<List<HomebrewEntry>> upsert(HomebrewEntry entry) async {
    entry.updatedAt = DateTime.now();
    final all = await loadAll();
    final index = all.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      all[index] = entry;
    } else {
      all.add(entry);
    }
    await _saveAll(all);
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  /// Deletes an entry by id. Returns the updated library.
  Future<List<HomebrewEntry>> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
    return all;
  }
}
