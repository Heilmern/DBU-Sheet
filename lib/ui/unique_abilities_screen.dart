/// unique_abilities_screen.dart
/// ---------------------------------------------------------------------------
/// The UNIQUE ABILITIES TAB — the site's Unique Abilities sub-system, mirroring
/// the old sheet's dedicated tab.
///
/// A Unique Ability is a TP-purchased Maneuver picked from the catalogue
/// (`data/unique_abilities.dart`). Each owned ability shows its structured
/// fields + verbatim Effect, a Type chooser (when it lists both Technical and
/// Magical), an Advancements checklist and a Restrictions checklist, and derived
/// TP Cost / KP Cost chips. The calculator computes the costs; the effects
/// themselves are reference text (this is a mostly-reference catalogue, like
/// Basic Items, with a cost engine on top).
///
/// TP Cost reflects the Magic Master Talent's per-Use-Magic-Rank discount on
/// Magical abilities. The shared [TpBudgetCard] shows the character's Technique
/// Point pool; a "Free ability" toggle and per-Advancement "Free" toggles keep
/// granted-for-free costs off the budget (via `uniqueAbilityTpSpent`).
///
/// Follows the shared tab contract `({character, stats, onUpdate})`.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';

import '../data/homebrew_registry.dart';
import '../data/unique_abilities.dart';
import '../models/character.dart';
import '../services/character_calculator.dart';
import 'widgets/sheet_widgets.dart';
import 'widgets/tp_budget.dart';

class UniqueAbilitiesTab extends StatelessWidget {
  const UniqueAbilitiesTab({
    super.key,
    required this.character,
    required this.stats,
    required this.onUpdate,
  });

  final Character character;
  final DerivedCharacterStats stats;
  final void Function(VoidCallback mutate) onUpdate;

  Character get _c => character;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Budget first — it's the number the player checks constantly.
            TpBudgetCard(character: _c, onUpdate: onUpdate),
            _buildIntro(context),
            for (final sel in _c.uniqueAbilities) _buildAbilityCard(context, sel),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Unique Abilities',
      icon: Icons.psychology_alt_outlined,
      trailing: IconButton(
        tooltip: 'Add Unique Ability',
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _pickAbility(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TP-purchased Maneuvers. Pick an ability, then buy Advancements '
            '(+TP) or apply Restrictions (−TP). ',
            style: theme.textTheme.bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DerivedStat(
                label: 'Abilities',
                value: '${_c.uniqueAbilities.length}',
              ),
              DerivedStat(
                label: 'Total TP Spent',
                value: '${CharacterCalculator.uniqueAbilityTotalTpSpent(_c)}',
                emphasize: true,
              ),
            ],
          ),
          if (_c.uniqueAbilities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No Unique Abilities yet.',
                  style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  Widget _buildAbilityCard(BuildContext context, UniqueAbilitySelection sel) {
    final theme = Theme.of(context);
    final def = CharacterCalculator.uniqueAbilityDefFor(sel);
    final tp = CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: _c);
    final spent = CharacterCalculator.uniqueAbilityTpSpent(_c, sel);
    final magicMaster = CharacterCalculator.magicMasterTpDiscount(_c, sel);
    final kp = CharacterCalculator.uniqueAbilityKpCost(_c, sel);
    final locked = CharacterCalculator.uniqueAbilityLockedAdvancements(sel);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sel.name.isEmpty ? '(unknown Ability)' : sel.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    onUpdate(() => _c.uniqueAbilities.remove(sel)),
              ),
            ],
          ),
          if (def == null)
            Text('This ability is no longer in the catalogue.',
                style: theme.textTheme.bodySmall)
          else ...[
            if (def.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(def.description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
            // Type chooser (only when the ability permits both).
            if (def.allowsBothTypes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('Type: ', style: theme.textTheme.labelMedium),
                    const SizedBox(width: 4),
                    for (final t in UniqueAbilityType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t.displayName),
                          selected: sel.type == t,
                          onSelected: (_) => onUpdate(() => sel.type = t),
                        ),
                      ),
                  ],
                ),
              ),
            // Derived chips.
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DerivedStat(
                  label: 'TP Cost',
                  value: '$tp',
                  emphasize: true,
                  tooltip: magicMaster > 0
                      ? 'Magic Master: −$magicMaster TP (Use Magic Ranks)'
                      : null,
                ),
                if (spent != tp)
                  DerivedStat(
                    label: 'TP Spent',
                    value: '$spent',
                    tooltip: 'Cost against your TP budget after free choices',
                  ),
                DerivedStat(
                  label: 'KP Cost',
                  value: kp != null ? '$kp' : def.kpCostText,
                  emphasize: true,
                ),
                DerivedStat(label: 'Maneuver', value: def.maneuverType),
                DerivedStat(label: 'Action Cost', value: def.actionCost),
                if (def.minions != 'N/A')
                  DerivedStat(label: 'Minions', value: def.minions),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                visualDensity: VisualDensity.compact,
                label: const Text('Free ability (no TP)'),
                selected: sel.freeTechnique,
                onSelected: (v) => onUpdate(() => sel.freeTechnique = v),
                tooltip: 'A Trait/effect granted this Unique Ability without '
                    'paying its TP Cost',
              ),
            ),
            const SizedBox(height: 8),
            if (def.prerequisites != 'N/A')
              Text('Prerequisites: ${def.prerequisites}',
                  style: theme.textTheme.labelSmall),
            if (def.passiveBonus != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Passive Bonus: ${def.passiveBonus}',
                    style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 6),
            Text(def.effect, style: theme.textTheme.bodySmall),
            if (def.advancements.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildAdvancements(context, sel, def, locked),
            ],
            if (def.restrictions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildRestrictions(context, sel, def),
            ],
          ],
          const SizedBox(height: 6),
          ResizableTextField(
            key: ValueKey('ua-notes-${identityHashCode(sel)}'),
            label: 'Notes',
            value: sel.notes,
            initialLines: 2,
            onChanged: (v) => onUpdate(() => sel.notes = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancements(BuildContext context, UniqueAbilitySelection sel,
      UniqueAbilityDef def, Set<String> locked) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Advancements',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        for (final adv in def.advancements)
          _modifierTile(
            context,
            title: adv.name,
            tpLabel: '+${adv.tpCost} TP',
            selected: sel.advancements.contains(adv.name),
            locked: locked.contains(adv.name),
            lockedNote: 'Locked by an applied Restriction',
            prerequisites: adv.prerequisites,
            effect: adv.effect,
            onToggle: (v) => onUpdate(() {
              if (v) {
                sel.advancements.add(adv.name);
              } else {
                sel.advancements.remove(adv.name);
                sel.freeAdvancements.remove(adv.name);
              }
            }),
            showFree: sel.advancements.contains(adv.name),
            freeSelected: sel.freeAdvancements.contains(adv.name),
            onFreeToggle: (v) => onUpdate(() {
              if (v) {
                sel.freeAdvancements.add(adv.name);
              } else {
                sel.freeAdvancements.remove(adv.name);
              }
            }),
          ),
      ],
    );
  }

  Widget _buildRestrictions(BuildContext context, UniqueAbilitySelection sel,
      UniqueAbilityDef def) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Restrictions',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        for (final r in def.restrictions)
          _modifierTile(
            context,
            title: r.name,
            tpLabel: '−${r.tpCostReduction} TP',
            selected: sel.restrictions.contains(r.name),
            locked: false,
            prerequisites: 'N/A',
            effect: r.lockedAdvancements.isEmpty
                ? r.effect
                : '${r.effect}\nLocked Advancements: '
                    '${r.lockedAdvancements.join(', ')}.',
            onToggle: (v) => onUpdate(() {
              if (v) {
                sel.restrictions.add(r.name);
                // Removing conflict: drop any now-locked Advancements.
                sel.advancements.removeWhere(
                    (a) => def.restrictions.any((rr) =>
                        rr.name == r.name && rr.lockedAdvancements.contains(a)));
              } else {
                sel.restrictions.remove(r.name);
              }
            }),
          ),
      ],
    );
  }

  Widget _modifierTile(
    BuildContext context, {
    required String title,
    required String tpLabel,
    required bool selected,
    required bool locked,
    String lockedNote = '',
    required String prerequisites,
    required String effect,
    required ValueChanged<bool> onToggle,
    bool showFree = false,
    bool freeSelected = false,
    ValueChanged<bool>? onFreeToggle,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: locked ? null : (v) => onToggle(v ?? false),
              ),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleSmall?.copyWith(
                        decoration:
                            locked ? TextDecoration.lineThrough : null)),
              ),
              Text(tpLabel, style: theme.textTheme.labelMedium),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locked && lockedNote.isNotEmpty)
                  Text(lockedNote,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.error)),
                if (prerequisites != 'N/A')
                  Text('Prereq: $prerequisites',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontStyle: FontStyle.italic)),
                Text(effect, style: theme.textTheme.bodySmall),
                if (showFree && onFreeToggle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        visualDensity: VisualDensity.compact,
                        label: const Text('Free (no TP)'),
                        selected: freeSelected,
                        onSelected: (v) => onFreeToggle(v),
                        tooltip: 'A Trait/effect granted this Advancement '
                            'without paying its TP',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAbility(BuildContext context) async {
    final taken = _c.uniqueAbilities.map((s) => s.name).toSet();
    final chosen = await showDialog<UniqueAbilityDef>(
      context: context,
      builder: (ctx) => _UniqueAbilityPickerDialog(taken: taken),
    );
    if (chosen == null) return;
    onUpdate(() => _c.uniqueAbilities.add(
          UniqueAbilitySelection(
            name: chosen.name,
            // Default the type when the ability has a single classification.
            type: chosen.allowsBothTypes ? null : chosen.types.first,
          ),
        ));
  }
}

/// A search-and-pick dialog over the Unique Abilities catalogue.
class _UniqueAbilityPickerDialog extends StatefulWidget {
  const _UniqueAbilityPickerDialog({required this.taken});

  final Set<String> taken;

  @override
  State<_UniqueAbilityPickerDialog> createState() =>
      _UniqueAbilityPickerDialogState();
}

class _UniqueAbilityPickerDialogState
    extends State<_UniqueAbilityPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final matches = [
      ...kDbuUniqueAbilities,
      ...HomebrewRegistry.uniqueAbilityDefs(),
    ]
        .where((a) =>
            !widget.taken.contains(a.name) &&
            (query.isEmpty ||
                a.name.toLowerCase().contains(query) ||
                a.effect.toLowerCase().contains(query)))
        .toList();

    return AlertDialog(
      title: const Text('Unique Abilities'),
      content: SizedBox(
        width: 500,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search',
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
              child: matches.isEmpty
                  ? const Center(child: Text('No matching Abilities.'))
                  : ListView(
                      children: [
                        for (final a in matches)
                          ListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Flexible(child: Text(a.name)),
                                const SizedBox(width: 6),
                                Text('[${a.typeLabel}]',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.secondary)),
                                const SizedBox(width: 6),
                                Text('${a.baseTpCost} TP · ${a.kpCostText} KP',
                                    style: theme.textTheme.labelSmall),
                              ],
                            ),
                            subtitle: Text(a.effect,
                                maxLines: 3, overflow: TextOverflow.ellipsis),
                            onTap: () => Navigator.of(context).pop(a),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
