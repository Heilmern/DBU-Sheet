/// multi_select_dialog.dart
/// ---------------------------------------------------------------------------
/// A generic "pick some/all of these" dialog — the shared UI behind every
/// "Export All / Multiple" action (character roster, homebrew library).
/// Starts with every item checked (so a bare confirm = "export everything")
/// and offers a Select All / Select None shortcut for narrowing down to a
/// handful. Returns the chosen subset, or null if the user cancelled.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

/// Shows the dialog and returns the selected items, or null if cancelled.
/// [subtitleOf] is optional per-item secondary text (e.g. a category label).
Future<List<T>?> showMultiSelectDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) titleOf,
  String Function(T)? subtitleOf,
  String confirmLabel = 'Export',
}) {
  return showDialog<List<T>>(
    context: context,
    builder: (ctx) => _MultiSelectDialog<T>(
      title: title,
      items: items,
      titleOf: titleOf,
      subtitleOf: subtitleOf,
      confirmLabel: confirmLabel,
    ),
  );
}

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    required this.confirmLabel,
  });

  final String title;
  final List<T> items;
  final String Function(T) titleOf;
  final String Function(T)? subtitleOf;
  final String confirmLabel;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  // Every item starts checked — a bare confirm exports the whole set.
  late final Set<int> _selected = {
    for (var i = 0; i < widget.items.length; i++) i,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('${_selected.length} / ${widget.items.length} selected'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selected
                    ..clear()
                    ..addAll(
                        [for (var i = 0; i < widget.items.length; i++) i])),
                  child: const Text('All'),
                ),
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('None'),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  final subtitle = widget.subtitleOf?.call(item);
                  return CheckboxListTile(
                    dense: true,
                    value: _selected.contains(i),
                    title: Text(widget.titleOf(item)),
                    subtitle: subtitle == null ? null : Text(subtitle),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.add(i);
                      } else {
                        _selected.remove(i);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    [for (final i in _selected) widget.items[i]],
                  ),
          child: Text('${widget.confirmLabel} (${_selected.length})'),
        ),
      ],
    );
  }
}
