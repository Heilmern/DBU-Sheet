/// file_transfer_service.dart
/// ---------------------------------------------------------------------------
/// Saving and opening share codes as `.json` FILES, on all five targets.
///
/// This is the thin I/O layer that sits on top of `ImportExportService`: that
/// class turns a character/homebrew into a String, this one moves that String
/// to and from a file. Keeping them separate means the envelope logic stays
/// pure and unit-testable while all the platform quirks live here.
///
/// Backed by `file_picker`, which declares plugin implementations for android,
/// ios, web, macos and windows (verified against its own pubspec) — one API,
/// no per-platform branches in the UI.
///
/// Two platform quirks are normalised here so callers never see them:
///  • On WEB, `saveFile` starts a browser download and always returns `null`,
///    whereas on every other platform `null` means "user cancelled". We use
///    `kIsWeb` (a Flutter compile-time constant, not `dart:io`) to tell the two
///    apart, so a successful web download isn't reported as a cancellation.
///  • Windows throws if a file name contains forbidden characters, so names
///    derived from a character's name are sanitised before use.
///
/// Picking uses `FileType.any` rather than filtering to `.json`: extension
/// filtering is unreliable on Android (it goes through MIME mapping) and the
/// importer already validates content and reports friendly errors, so an
/// over-eager filter would cost more than it gains.
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// How a save attempt ended.
enum FileSaveStatus {
  /// Written to disk (or downloaded, on web).
  saved,

  /// The user dismissed the save dialog.
  cancelled,

  /// Something went wrong — see [FileSaveResult.error].
  failed,
}

class FileSaveResult {
  const FileSaveResult(this.status, {this.path, this.error});

  final FileSaveStatus status;

  /// Where it landed, when the platform reports a path (null on web).
  final String? path;
  final String? error;

  bool get ok => status == FileSaveStatus.saved;
}

/// How an open attempt ended. [contents] is set only when [ok].
class FilePickResult {
  const FilePickResult.picked(String this.contents)
      : error = null,
        cancelled = false;
  const FilePickResult.cancelled()
      : contents = null,
        error = null,
        cancelled = true;
  const FilePickResult.failure(String this.error)
      : contents = null,
        cancelled = false;

  final String? contents;
  final String? error;
  final bool cancelled;

  bool get ok => contents != null;
}

class FileTransferService {
  FileTransferService._();

  /// Characters/homebrew are exported as plain `.json`.
  static const String extension = 'json';

  /// Strips characters that are illegal in file names on Windows (and awkward
  /// everywhere else), collapsing whitespace. Falls back to [fallback] when the
  /// result would be empty.
  static String sanitizeFileName(String name, {String fallback = 'export'}) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        // Trailing dots/spaces are invalid on Windows.
        .replaceAll(RegExp(r'[. ]+$'), '');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  /// Prompts for a location and writes [content] as UTF-8.
  ///
  /// [baseName] is the suggested name WITHOUT extension; it's sanitised and
  /// `.json` is appended.
  static Future<FileSaveResult> saveJson({
    required String baseName,
    required String content,
    String? dialogTitle,
  }) async {
    final fileName = '${sanitizeFileName(baseName)}.$extension';
    final bytes = Uint8List.fromList(utf8.encode(content));
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
      );
      // On web the browser handled the download and `path` is always null —
      // that's success, not cancellation.
      if (kIsWeb) return const FileSaveResult(FileSaveStatus.saved);
      if (path == null) {
        return const FileSaveResult(FileSaveStatus.cancelled);
      }
      return FileSaveResult(FileSaveStatus.saved, path: path);
    } catch (e) {
      return FileSaveResult(FileSaveStatus.failed, error: '$e');
    }
  }

  /// Prompts for a file and returns its contents decoded as UTF-8.
  static Future<FilePickResult> pickJson({String? dialogTitle}) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        // `withData` is what makes this work identically on web (no path) and
        // on desktop/mobile — we always read bytes, never a path.
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const FilePickResult.cancelled();
      }
      final bytes = result.files.first.bytes;
      if (bytes == null) {
        return const FilePickResult.failure(
          "That file couldn't be read. Try again, or paste the code instead.",
        );
      }
      return FilePickResult.picked(utf8.decode(bytes));
    } on FormatException {
      return const FilePickResult.failure(
        "That file isn't readable text — pick the .json file you exported.",
      );
    } catch (e) {
      return FilePickResult.failure('$e');
    }
  }
}
