/// update_service.dart
/// ---------------------------------------------------------------------------
/// Checks whether a newer build of the app has been published to the project's
/// GitHub Releases, so the UI can nudge the user to download it.
///
/// It hits GitHub's public, unauthenticated "latest release" endpoint
/// (60 requests/hour/IP — ample for a manual "check for updates" button plus a
/// one-shot check on launch), reads the release's `tag_name` (e.g. "v0.1.3"),
/// and compares it against the running [currentVersion]. No token is needed and
/// nothing is stored server-side.
///
/// The service is deliberately UI-free and side-effect-free: it returns an
/// [UpdateCheck] describing the outcome and lets the caller decide what to show
/// and whether to open the download page (via `url_launcher`).
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../data/changelog.dart';

/// `owner/repo` slug for the GitHub project the releases live under.
const String _kRepoSlug = 'Heilmern/DBU-Sheet';

/// The outcome of a single update check.
enum UpdateStatus {
  /// A newer release than the running build is available.
  updateAvailable,

  /// The running build is the newest release (or newer than any published).
  upToDate,

  /// The check couldn't complete (offline, rate-limited, API error, …).
  error,
}

/// The result of [UpdateService.check] — a status plus, when an update exists,
/// the details needed to tell the user about it and send them to the download.
class UpdateCheck {
  const UpdateCheck({
    required this.status,
    this.latestVersion,
    this.releaseName,
    this.notes,
    this.releaseUrl,
    this.error,
  });

  final UpdateStatus status;

  /// The latest published version, normalised without a leading "v"
  /// (e.g. "0.1.3"). Null when [status] is [UpdateStatus.error].
  final String? latestVersion;

  /// The release's human title (GitHub's release "name"), if any.
  final String? releaseName;

  /// The release notes (GitHub's release "body"), if any.
  final String? notes;

  /// The release page to open for downloading (GitHub's `html_url`).
  final String? releaseUrl;

  /// A short description of what went wrong when [status] is
  /// [UpdateStatus.error].
  final String? error;

  bool get isUpdateAvailable => status == UpdateStatus.updateAvailable;
}

class UpdateService {
  const UpdateService();

  /// Queries GitHub for the latest release and compares it to [current]
  /// (defaults to the running build's [currentVersion]).
  ///
  /// Never throws — network/parse failures come back as an
  /// [UpdateStatus.error] result so callers can stay simple.
  Future<UpdateCheck> check({String? current}) async {
    final running = current ?? currentVersion;
    final uri = Uri.parse(
      'https://api.github.com/repos/$_kRepoSlug/releases/latest',
    );
    try {
      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          // GitHub's API requires a User-Agent; browsers set their own on web,
          // where this header is ignored, so it's harmless there.
          'User-Agent': 'DBU-Sheet-App',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return UpdateCheck(
          status: UpdateStatus.error,
          error: 'GitHub returned HTTP ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?)?.trim();
      if (tag == null || tag.isEmpty) {
        return const UpdateCheck(
          status: UpdateStatus.error,
          error: 'No release tag found.',
        );
      }

      final latest = _normalise(tag);
      final newer = compareVersions(latest, _normalise(running)) > 0;

      return UpdateCheck(
        status: newer ? UpdateStatus.updateAvailable : UpdateStatus.upToDate,
        latestVersion: latest,
        releaseName: (data['name'] as String?)?.trim().isEmpty ?? true
            ? null
            : (data['name'] as String).trim(),
        notes: (data['body'] as String?)?.trim().isEmpty ?? true
            ? null
            : (data['body'] as String).trim(),
        releaseUrl: data['html_url'] as String?,
      );
    } catch (e) {
      return UpdateCheck(
        status: UpdateStatus.error,
        error: 'Could not reach GitHub ($e).',
      );
    }
  }

  /// Strips a leading "v"/"V" and surrounding whitespace from a version/tag.
  static String _normalise(String raw) {
    final t = raw.trim();
    return (t.startsWith('v') || t.startsWith('V')) ? t.substring(1) : t;
  }
}

/// Compares two dotted numeric versions ("0.1.2" vs "0.1.10") segment by
/// segment, treating missing trailing segments as 0. Non-numeric noise in a
/// segment (e.g. a "-beta" suffix) is ignored so it degrades gracefully.
///
/// Returns <0 if [a] < [b], 0 if equal, >0 if [a] > [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .split('.')
      .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();

  final pa = parts(a);
  final pb = parts(b);
  final n = math.max(pa.length, pb.length);
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
