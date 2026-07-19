/// homebrew_list_screen.dart
/// ---------------------------------------------------------------------------
/// The Homebrew library — the roster equivalent for player-authored content.
/// Lists saved homebrew entries grouped by category, with create / edit /
/// delete and the same copy-paste share-code export/import as characters.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/homebrew_registry.dart';
import '../models/homebrew.dart';
import '../services/file_transfer_service.dart';
import '../services/homebrew_repository.dart';
import '../services/import_export_service.dart';
import 'homebrew_edit_screen.dart';
import 'widgets/multi_select_dialog.dart';

class HomebrewListScreen extends StatefulWidget {
  const HomebrewListScreen({super.key, required this.repository});

  final HomebrewRepository repository;

  @override
  State<HomebrewListScreen> createState() => _HomebrewListScreenState();
}

class _HomebrewListScreenState extends State<HomebrewListScreen> {
  List<HomebrewEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final entries = await widget.repository.loadAll();
    // Keep the runtime catalogue in step so edits here immediately re-derive
    // every character that uses this homebrew.
    HomebrewRegistry.setAll(entries);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _openEditor({HomebrewEntry? entry}) async {
    final isNew = entry == null;
    final working = entry?.copy() ?? HomebrewEntry.blank(_newId());
    final saved = await Navigator.of(context).push<HomebrewEntry>(
      MaterialPageRoute(
        builder: (_) => HomebrewEditScreen(entry: working, isNew: isNew),
      ),
    );
    if (saved != null) {
      await widget.repository.upsert(saved);
      await _refresh();
    }
  }

  Future<void> _confirmDelete(HomebrewEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete homebrew?'),
        content: Text('This will permanently delete "${entry.displayName}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.repository.delete(entry.id);
      await _refresh();
    }
  }

  Future<void> _export(HomebrewEntry entry) async {
    final code = ImportExportService.exportHomebrew(entry);
    await _showExportCodeDialog(
      title: 'Export "${entry.displayName}"',
      intro: 'Copy this code and share it with other players.',
      code: code,
      fileBaseName: entry.displayName,
    );
  }

  /// Opens a checkbox picker over the whole library (every entry starts
  /// checked, so a bare confirm exports all of it) and produces ONE
  /// self-contained code covering just the selected entries.
  Future<void> _exportMultiple() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No homebrew to export.')),
      );
      return;
    }
    final chosen = await showMultiSelectDialog<HomebrewEntry>(
      context: context,
      title: 'Export homebrew',
      items: _entries,
      titleOf: (e) => e.displayName,
      subtitleOf: (e) => e.category.displayName,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;

    final code = ImportExportService.exportHomebrewSet(chosen);
    await _showExportCodeDialog(
      title: 'Export ${chosen.length} homebrew entries',
      intro: 'Copy this code and share it with other players — every '
          'selected entry imports at once.',
      code: code,
      fileBaseName: 'Homebrew (${chosen.length})',
    );
  }

  /// The shared Save-file/Copy dialog behind both the single- and
  /// multi-entry export flows.
  Future<void> _showExportCodeDialog({
    required String title,
    required String intro,
    required String code,
    required String fileBaseName,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intro),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveCodeToFile(fileBaseName, code);
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Save file'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard.')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Writes a homebrew code to a user-chosen `.json` file.
  Future<void> _saveCodeToFile(String baseName, String code) async {
    final result = await FileTransferService.saveJson(
      baseName: baseName,
      content: code,
      dialogTitle: 'Save homebrew',
    );
    if (!mounted) return;
    switch (result.status) {
      case FileSaveStatus.saved:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.path == null
                ? 'Homebrew saved.'
                : 'Homebrew saved to ${result.path}'),
          ),
        );
      case FileSaveStatus.cancelled:
        break;
      case FileSaveStatus.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save the file: ${result.error}")),
        );
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final clipText = clip?.text?.trim() ?? '';
    if (clipText.startsWith('{') || clipText.startsWith('ey')) {
      controller.text = clipText;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Import homebrew'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open a .json file, or paste a homebrew code — a single '
                  'entry or an "export all/multiple" bundle both work.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FileTransferService.pickJson(
                      dialogTitle: 'Open homebrew file',
                    );
                    if (picked.ok) {
                      setDialogState(() => controller.text = picked.contents!);
                    } else if (picked.error != null && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(picked.error!)),
                      );
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open file…'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 4,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: '…or paste code here',
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    // A single entry and an "export all/multiple" bundle share one parser
    // (importHomebrewSet accepts either shape), so one Import action handles
    // both.
    final result =
        ImportExportService.importHomebrewSet(controller.text, newId: _newId);
    controller.dispose();
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }
    for (final entry in result.entries!) {
      await widget.repository.upsert(entry);
    }
    await _refresh();
    if (!mounted) return;
    final label = result.entries!.length == 1
        ? 'Imported "${result.entries!.single.displayName}".'
        : 'Imported ${result.entries!.length} homebrew entries.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homebrew'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Export all / multiple',
            icon: const Icon(Icons.upload_outlined),
            onPressed: _entries.isEmpty ? null : _exportMultiple,
          ),
          IconButton(
            tooltip: 'Import homebrew',
            icon: const Icon(Icons.download),
            onPressed: _import,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Distinct from the roster FAB: both live in the same IndexedStack.
        heroTag: 'fab-homebrew-list',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Homebrew'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const _EmptyHomebrew()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                      children: _buildGroupedList(context),
                    ),
                  ),
                ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final category in HomebrewCategory.values) {
      final inCat = _entries.where((e) => e.category == category).toList();
      if (inCat.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          category.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      for (final e in inCat) {
        final autos = e.automations.length;
        widgets.add(Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            onTap: () => _openEditor(entry: e),
            title: Text(
              e.displayName,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              [
                if (e.flavor.trim().isNotEmpty) e.flavor.trim(),
                autos == 0
                    ? 'Reference only'
                    : '$autos automated effect${autos == 1 ? '' : 's'}',
              ].join('  •  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openEditor(entry: e),
                ),
                IconButton(
                  tooltip: 'Export / share',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => _export(e),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(e),
                ),
              ],
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}

class _EmptyHomebrew extends StatelessWidget {
  const _EmptyHomebrew();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No homebrew yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create custom Talents, Traits, Transformations and more — '
              'write the text, then pick what to automate.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
