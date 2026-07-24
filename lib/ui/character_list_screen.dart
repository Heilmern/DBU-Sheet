/// character_list_screen.dart
/// ---------------------------------------------------------------------------
/// The app's home menu. Shows every saved character in a selectable list with:
///   • a "Create New Character" button (opens a blank editor),
///   • an "Edit Selected" button (opens the editor for the highlighted entry),
///   • a per-row delete action (with confirmation).
///
/// The screen owns the in-memory roster and the currently-selected id, and
/// talks to [CharacterRepository] for all persistence. It's built to be legible
/// on everything from a phone to a desktop window (responsive max width).
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/changelog.dart';
import '../data/homebrew_registry.dart';
import '../models/character.dart';
import '../models/homebrew.dart';
import '../services/character_calculator.dart';
import '../services/character_repository.dart';
import '../services/file_transfer_service.dart';
import '../services/homebrew_repository.dart';
import '../services/import_export_service.dart';
import '../services/update_service.dart';
import 'changelog_screen.dart';
import 'character_edit_screen.dart';
import 'widgets/multi_select_dialog.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({
    super.key,
    required this.repository,
    required this.homebrewRepository,
  });

  final CharacterRepository repository;

  /// Needed so an imported character's BUNDLED homebrew can be added to the
  /// player's library (see `_mergeBundledHomebrew`).
  final HomebrewRepository homebrewRepository;

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  /// The loaded roster, kept in memory and refreshed after every mutation.
  List<Character> _characters = [];

  /// Id of the currently highlighted character (null = none selected).
  String? _selectedId;

  /// True while the initial load from storage is in flight.
  bool _loading = true;

  /// Guards against overlapping update checks (the launch check and a rapid
  /// button tap, or repeated taps).
  bool _checkingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Quietly check once on launch; only surfaces UI if an update exists.
    _checkForUpdates(silent: true);
  }

  /// Reloads the roster from storage and repaints.
  Future<void> _refresh() async {
    final chars = await widget.repository.loadAll();
    if (!mounted) return;
    setState(() {
      _characters = chars;
      _loading = false;
      // Drop the selection if the selected character no longer exists.
      if (_selectedId != null &&
          !chars.any((c) => c.id == _selectedId)) {
        _selectedId = null;
      }
    });
  }

  /// Checks GitHub Releases for a newer build.
  ///
  /// When [silent] (the on-launch check), it stays invisible unless an update
  /// is available — no "you're up to date" / error noise. A manual tap
  /// ([silent] false) always gives feedback so the user knows the check ran.
  Future<void> _checkForUpdates({bool silent = false}) async {
    if (_checkingForUpdate) return;
    _checkingForUpdate = true;

    final messenger = ScaffoldMessenger.of(context);
    if (!silent) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Checking for updates…')),
      );
    }

    final result = await const UpdateService().check();
    if (!mounted) {
      _checkingForUpdate = false;
      return;
    }

    switch (result.status) {
      case UpdateStatus.updateAvailable:
        await _showUpdateDialog(result);
      case UpdateStatus.upToDate:
        if (!silent) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text("You're on the latest version (v$currentVersion)."),
              ),
            );
        }
      case UpdateStatus.error:
        if (!silent) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text("Couldn't check for updates. Try again later."),
              ),
            );
        }
    }

    _checkingForUpdate = false;
  }

  /// Shows the "update available" dialog with release notes and a link out to
  /// the GitHub release page for downloading.
  Future<void> _showUpdateDialog(UpdateCheck result) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update available — v${result.latestVersion}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're running v$currentVersion."),
                if (result.notes != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    result.releaseName ?? "What's new",
                    style: Theme.of(ctx)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(result.notes!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: result.releaseUrl == null
                ? null
                : () async {
                    final ok = await launchUrl(
                      Uri.parse(result.releaseUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open the download page.'),
                        ),
                      );
                    }
                  },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  /// Generates a reasonably-unique id for a new character.
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Opens the editor. [character] null → create flow; otherwise edit flow.
  Future<void> _openEditor({Character? character}) async {
    final isNew = character == null;
    final working = character?.copy() ?? Character.blank(_newId());

    // The editor persists in-place via [onSave] (Save no longer closes the
    // page), so nothing needs to come back through the pop result — the roster
    // is already refreshed by the time the editor closes.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CharacterEditScreen(
          character: working,
          isNew: isNew,
          onSave: (c) async {
            await widget.repository.upsert(c);
            _selectedId = c.id;
            await _refresh();
          },
        ),
      ),
    );
  }

  /// Confirms and deletes a character.
  Future<void> _confirmDelete(Character character) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete character?'),
        content: Text(
          'This will permanently delete "${character.displayName}". '
          'This cannot be undone.',
        ),
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
      await widget.repository.delete(character.id);
      await _refresh();
    }
  }

  /// Shows the character's portable share code with a one-tap Copy button.
  Future<void> _exportCharacter(Character character) async {
    final code = ImportExportService.exportCharacter(character);
    final bundled = ImportExportService.referencedHomebrew(character).length;
    await _showExportCodeDialog(
      title: 'Export "${character.displayName}"',
      intro: 'Copy this code and send it to another device, then use '
          'Import there.',
      code: code,
      bundledCount: bundled,
      fileBaseName: character.displayName,
      what: 'Character',
    );
  }

  /// Opens a checkbox picker over the whole roster (every character starts
  /// checked, so a bare confirm exports all of them) and produces ONE
  /// self-contained code covering just the selected characters.
  Future<void> _exportMultiple() async {
    if (_characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No characters to export.')),
      );
      return;
    }
    final chosen = await showMultiSelectDialog<Character>(
      context: context,
      title: 'Export characters',
      items: _characters,
      titleOf: (c) => c.displayName,
      subtitleOf: (c) => '${c.race} · PL ${c.powerLevel}',
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;

    final code = ImportExportService.exportCharacters(chosen);
    final bundledCount = <String>{
      for (final c in chosen)
        for (final e in ImportExportService.referencedHomebrew(c))
          e.name.trim().toLowerCase(),
    }.length;
    await _showExportCodeDialog(
      title: 'Export ${chosen.length} characters',
      intro: 'Copy this code and send it to another device, then use '
          'Import there — every selected character imports at once.',
      code: code,
      bundledCount: bundledCount,
      fileBaseName: 'Characters (${chosen.length})',
      what: '${chosen.length} characters',
    );
  }

  /// The shared Save-file/Copy dialog behind both the single- and
  /// multi-character export flows.
  Future<void> _showExportCodeDialog({
    required String title,
    required String intro,
    required String code,
    required int bundledCount,
    required String fileBaseName,
    required String what,
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
              if (bundledCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Includes $bundledCount homebrew definition'
                        '${bundledCount == 1 ? '' : 's'} — the recipient '
                        'gets them automatically.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    code,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
              await _saveCodeToFile(
                baseName: fileBaseName,
                code: code,
                what: what,
              );
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

  /// Writes a share code to a user-chosen `.json` file and reports the outcome.
  Future<void> _saveCodeToFile({
    required String baseName,
    required String code,
    required String what,
  }) async {
    final result = await FileTransferService.saveJson(
      baseName: baseName,
      content: code,
      dialogTitle: 'Save $what',
    );
    if (!mounted) return;
    switch (result.status) {
      case FileSaveStatus.saved:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.path == null
                ? '$what saved.'
                : '$what saved to ${result.path}'),
          ),
        );
      case FileSaveStatus.cancelled:
        break; // User backed out — say nothing.
      case FileSaveStatus.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save the file: ${result.error}")),
        );
    }
  }

  /// Prompts for a pasted share code and imports it as a NEW roster entry.
  Future<void> _importCharacter() async {
    final controller = TextEditingController();
    // Pre-fill from the clipboard if it looks like it might hold a code, as a
    // convenience — the user can still clear/replace it.
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
          title: const Text('Import character(s)'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open a .json file, or paste a character code — a single '
                  'character or an "export all/multiple" bundle both work.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FileTransferService.pickJson(
                      dialogTitle: 'Open character file',
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
                    border: OutlineInputBorder(),
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

    // A single character and an "export all/multiple" bundle share one parser
    // (importCharacters accepts either shape), so one Import action handles
    // both — the player never has to know which kind of code they were given.
    final result = ImportExportService.importCharacters(
      controller.text,
      newId: _newId,
    );
    controller.dispose();

    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
      return;
    }

    final imported = result.characters!;
    for (final c in imported) {
      await widget.repository.upsert(c);
    }
    // Any homebrew that travelled with the character(s) joins the library
    // first, so the sheet's numbers resolve immediately on the next rebuild.
    final addedHomebrew = await _mergeBundledHomebrew(result.bundledHomebrew);
    _selectedId = imported.length == 1 ? imported.single.id : null;
    await _refresh();
    if (!mounted) return;
    final extra = addedHomebrew == 0
        ? ''
        : '  Added $addedHomebrew homebrew to your library.';
    final label = imported.length == 1
        ? 'Imported "${imported.single.displayName}".'
        : 'Imported ${imported.length} characters.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label$extra')),
    );
  }

  /// Adds bundled homebrew whose NAME isn't already in the player's library.
  /// Same-named homebrew they already own is left untouched — an imported
  /// character must never silently rewrite the recipient's own definitions.
  /// Returns how many were actually added.
  Future<int> _mergeBundledHomebrew(List<HomebrewEntry> bundled) async {
    var added = 0;
    for (final entry in bundled) {
      if (HomebrewRegistry.byName(entry.name) != null) continue;
      final all = await widget.homebrewRepository.upsert(entry);
      // Refresh the runtime catalogue as we go, so the next name check sees
      // what we just added and characters re-derive with it immediately.
      HomebrewRegistry.setAll(all);
      added++;
    }
    return added;
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the selected character without relying on package:collection's
    // firstOrNull, keeping the dependency surface minimal.
    Character? selected;
    if (_selectedId != null) {
      for (final c in _characters) {
        if (c.id == _selectedId) {
          selected = c;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DBU Characters'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Edit selected',
            icon: const Icon(Icons.edit),
            // Disabled until a character is selected.
            onPressed: selected == null
                ? null
                : () => _openEditor(character: selected),
          ),
          IconButton(
            tooltip: 'Export all / multiple',
            icon: const Icon(Icons.upload_outlined),
            onPressed: _characters.isEmpty ? null : _exportMultiple,
          ),
          IconButton(
            tooltip: 'Import character(s)',
            icon: const Icon(Icons.download),
            onPressed: _importCharacter,
          ),
          // The two least-used actions live in an overflow menu so the five
          // icons don't crowd out the AppBar title on a phone.
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'whatsnew':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangelogScreen()),
                  );
                case 'updates':
                  _checkForUpdates();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'whatsnew',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text("What's new (v$currentVersion)"),
                ),
              ),
              const PopupMenuItem(
                value: 'updates',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.update),
                  title: Text('Check for updates'),
                ),
              ),
            ],
          ),
        ],
      ),
      // Primary create action as a FAB (idiomatic Material 3, and leaves the
      // bottom edge free for the home NavigationBar). Editing is also reachable
      // by long-pressing a row or via the AppBar action above.
      floatingActionButton: FloatingActionButton.extended(
        // Both home-shell sections stay alive in an IndexedStack, so their FABs
        // share one route subtree and need distinct Hero tags.
        heroTag: 'fab-character-list',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Create New'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _characters.isEmpty
              ? _EmptyRoster(onCreate: () => _openEditor())
              : Center(
                  child: ConstrainedBox(
                    // Cap width so lines don't stretch across wide desktop
                    // windows.
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 88),
                      itemCount: _characters.length,
                      itemBuilder: (context, i) {
                        final c = _characters[i];
                        final isSelected = c.id == _selectedId;
                        final stats = CharacterCalculator.compute(c);
                        return _CharacterTile(
                          character: c,
                          tierOfPower: stats.tierOfPower,
                          maxLife: stats.maxLife,
                          selected: isSelected,
                          onTap: () => setState(
                            () => _selectedId = isSelected ? null : c.id,
                          ),
                          onDoubleTap: () => _openEditor(character: c),
                          onEdit: () => _openEditor(character: c),
                          onDelete: () => _confirmDelete(c),
                          onExport: () => _exportCharacter(c),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

/// A single row in the roster.
class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.character,
    required this.tierOfPower,
    required this.maxLife,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final Character character;
  final int tierOfPower;
  final int maxLife;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  /// First non-blank character of a name, uppercased, for the avatar badge.
  /// Uses a plain substring to avoid depending on package:characters.
  String _initial(String s) {
    final trimmed = s.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = [
      character.race,
      if (character.subrace.trim().isNotEmpty) character.subrace,
      'PL ${character.powerLevel}',
      'ToP $tierOfPower',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: selected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        // Long-press is a quick shortcut straight into editing.
        onLongPress: onDoubleTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            _initial(character.displayName),
            style: theme.textTheme.titleLarge,
          ),
        ),
        title: Text(
          character.displayName,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitleParts.join('  •  ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick glance at total Life Points.
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$maxLife',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Life', style: theme.textTheme.labelSmall),
              ],
            ),
            // One overflow menu instead of three inline icons — side by side
            // they starved the name + subtitle into a tall multi-line stack on
            // a phone.
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'export':
                    onExport();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                  ),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.ios_share),
                    title: Text('Export / share'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Friendly empty-state shown when there are no characters yet.
class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No characters yet',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create your first Dragon Ball Universe warrior to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create New Character'),
            ),
          ],
        ),
      ),
    );
  }
}
