/// sheet_widgets.dart
/// ---------------------------------------------------------------------------
/// Small, reusable presentation widgets shared across the character sheet UI.
/// Keeping these here avoids repetition and gives the sheet a consistent look:
///   • [SectionCard]         — a titled, elevated container for one sheet
///                             section.
///   • [DerivedStat]         — a compact read-only "label: value" chip for
///                             computed numbers (Max Life, Aptitudes, Combat
///                             Rolls, ...).
///   • [ResizableTextField]  — a multi-line text field with a drag handle so
///                             the player can grow the box to fit long
///                             Description/Notes/Effect text instead of
///                             being stuck scrolling inside a cramped box.
///   • [TalentCataloguePickerDialog] — a search-and-pick dialog over the
///                             full Talents catalogue, shared by the
///                             Information and Progression tabs.
/// These are purely visual and hold no business logic.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../../data/homebrew_registry.dart';
import '../../data/talents.dart';

/// A titled card that groups one section of the sheet (e.g. "Attributes").
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  /// Optional widget shown at the right of the header (e.g. a helper note).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// A compact read-only display for a single derived/computed value.
class DerivedStat extends StatelessWidget {
  const DerivedStat({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.warn = false,
    this.tooltip,
  });

  final String label;
  final String value;

  /// When true, the value is drawn larger/bolder (for headline numbers).
  final bool emphasize;

  /// When true, the chip is tinted with the error colour to flag a value that
  /// breaks a rules limit (e.g. an Attribute Score or Skill Ranks over the
  /// Tier-of-Power cap).
  final bool warn;

  /// Optional hover/long-press explanation (e.g. what limit was exceeded).
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: warn
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: warn
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: (emphasize
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: warn ? theme.colorScheme.onErrorContainer : null,
            ),
          ),
        ],
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// A multi-line [TextFormField] the player can drag-resize (via the handle
/// in its bottom-right corner) instead of being stuck with a fixed-height
/// box that scrolls internally. Starts at [initialLines] tall and can be
/// dragged down to reveal the rest of long Description/Notes/Effect text
/// without scrolling, or back up to [minLines] to save space.
class ResizableTextField extends StatefulWidget {
  const ResizableTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.initialLines = 3,
    this.minLines = 2,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  /// How tall the box starts, in approximate text lines.
  final int initialLines;

  /// How far the player can shrink the box, in approximate text lines.
  final int minLines;

  @override
  State<ResizableTextField> createState() => _ResizableTextFieldState();
}

class _ResizableTextFieldState extends State<ResizableTextField> {
  // Approximate single-line height (font + line spacing) used only to seed
  // a sane starting pixel height from a line count — the field itself grows
  // continuously in pixels once the player starts dragging, not in whole
  // lines.
  static const double _lineHeight = 20;
  static const double _chromePadding = 28;
  static const double _maxHeight = 600;

  late double _height;

  @override
  void initState() {
    super.initState();
    _height = widget.initialLines * _lineHeight + _chromePadding;
  }

  double get _minHeight => widget.minLines * _lineHeight + _chromePadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Stack(
        children: [
          SizedBox(
            height: _height,
            child: TextFormField(
              initialValue: widget.value,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.fromLTRB(12, 12, 26, 12),
              ),
              onChanged: widget.onChanged,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) => setState(() {
                  _height = (_height + details.delta.dy)
                      .clamp(_minHeight, _maxHeight);
                }),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sentinel returned by a catalogue-picker dialog's "Custom Entry" action —
/// distinguishes "the player wants a blank/homebrew row" from `null`
/// (Cancel/dismiss, meaning "do nothing") and from an actual catalogue pick,
/// without needing a shared supertype for `TalentDef`/Factor Trait pairs.
const Object kCustomCatalogueEntry = Object();

/// Browses the full Talents catalogue (all 33 Talent Categories) — shared by
/// the Information tab's Talents section and the Progression tab's Talent
/// Addition slots. Returns the chosen `TalentDef`, [kCustomCatalogueEntry]
/// if the player tapped "Custom Entry" (only shown when [allowCustomEntry]
/// is true), or `null` on Cancel/dismiss.
class TalentCataloguePickerDialog extends StatefulWidget {
  const TalentCataloguePickerDialog({super.key, this.allowCustomEntry = false});

  /// Whether to show a "Custom Entry" action alongside Cancel — used by
  /// callers that want catalogue-pick-by-default with a homebrew fallback.
  /// Per-row re-pick dialogs leave this off, since Cancel already gets you
  /// back to the existing freeform fields.
  final bool allowCustomEntry;

  @override
  State<TalentCataloguePickerDialog> createState() =>
      _TalentCataloguePickerDialogState();
}

class _TalentCataloguePickerDialogState
    extends State<TalentCataloguePickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _flavorText(String description) => description.split('\n').first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();

    // Official catalogue plus homebrew Talents (the official catalogue wins
    // a name clash — `resolveTalentDef` order — so clashes are skipped here).
    final homebrewNames = <String>{};
    final allTalents = [
      ...kDbuTalents,
      for (final t in HomebrewRegistry.talentDefs())
        if (talentByName(t.name) == null && homebrewNames.add(t.name)) t,
    ];
    final byCategory = <TalentCategory, List<TalentDef>>{};
    for (final talent in allTalents) {
      final matches = query.isEmpty ||
          talent.name.toLowerCase().contains(query) ||
          talent.category.displayName.toLowerCase().contains(query) ||
          (talent.raceRestriction?.toLowerCase().contains(query) ?? false) ||
          _flavorText(talent.description).toLowerCase().contains(query);
      if (!matches) continue;
      byCategory.putIfAbsent(talent.category, () => []).add(talent);
    }

    return AlertDialog(
      title: const Text('Pick a Talent'),
      content: SizedBox(
        width: 480,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Talents',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: byCategory.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final category in byCategory.keys) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              category.displayName,
                              style: theme.textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          for (final talent in byCategory[category]!)
                            ListTile(
                              dense: true,
                              title: Text(homebrewNames.contains(talent.name)
                                  ? '${talent.name}  (Homebrew)'
                                  : talent.name),
                              subtitle: Text(
                                talent.raceRestriction != null
                                    ? '(${talent.raceRestriction}) '
                                        '${_flavorText(talent.description)}'
                                    : _flavorText(talent.description),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: talent.isAutomated
                                  ? Icon(Icons.bolt,
                                      size: 18,
                                      color: theme.colorScheme.primary)
                                  : null,
                              onTap: () =>
                                  Navigator.of(context).pop(talent),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.allowCustomEntry)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(kCustomCatalogueEntry),
            child: const Text('Custom Entry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
