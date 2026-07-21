/// changelog_screen.dart
/// ---------------------------------------------------------------------------
/// Renders the app's release notes ([kChangelog]) as a scrollable, grouped
/// list. Each release is a card: version + date heading, an optional headline,
/// then its changes each badged by kind (Added / Changed / Fixed).
///
/// It reads purely from [changelog.dart] — to update what's shown, edit that
/// data file, not this screen. Pushed as a normal route from the home AppBar
/// (see `character_list_screen.dart`).
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/changelog.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New"),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          // Cap width so lines stay readable in wide desktop windows.
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: kChangelog.length,
            itemBuilder: (context, i) => _ReleaseCard(entry: kChangelog[i]),
          ),
        ),
      ),
    );
  }
}

/// One release, rendered as a card.
class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'v${entry.version}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (entry.headline != null) ...[
              const SizedBox(height: 4),
              Text(
                entry.headline!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final change in entry.changes) ...[
              _ChangeRow(change: change),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single change line: a coloured kind badge followed by the description.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final ChangelogChange change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KindBadge(kind: change.kind),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(change.text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

/// The small pill labelling a change's kind, colour-coded per kind.
class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final ChangeKind kind;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Map each kind to an on-scheme colour pair so it reads in light AND dark.
    final (Color bg, Color fg) = switch (kind) {
      ChangeKind.added => (scheme.primaryContainer, scheme.onPrimaryContainer),
      ChangeKind.changed => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      ChangeKind.fixed => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
    };
    return Container(
      // Fixed width so all descriptions line up regardless of label length.
      width: 68,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
