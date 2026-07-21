/// tp_budget.dart
/// ---------------------------------------------------------------------------
/// A shared Technique Point (TP) budget summary, rendered identically at the
/// top of the Signatures and Unique Abilities tabs (TP is one pool shared
/// between the two sub-systems).
///
/// Shows the computed Maximum TP (Skill Improvements + Gifted Student + Trait
/// per-Skill-Improvement bonuses + a manual adjustment), the amount Spent
/// across Signatures and Unique Abilities (honouring the free-TP discounts),
/// and the Remaining balance (highlighted red when overspent). The manual
/// "Bonus TP" adjustment is editable here so any un-automatable TP source can
/// be reconciled.
/// ---------------------------------------------------------------------------
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/character.dart';
import '../../services/character_calculator.dart';
import 'sheet_widgets.dart';

class TpBudgetCard extends StatelessWidget {
  const TpBudgetCard({
    super.key,
    required this.character,
    required this.onUpdate,
  });

  final Character character;
  final void Function(VoidCallback mutate) onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = CharacterCalculator.techniquePointBudget(character);
    final over = b.remaining < 0;

    final breakdown = <String>[
      'Skill Improvements: ${b.progression}',
      if (b.giftedStudent != 0) 'Gifted Student: +${b.giftedStudent}',
      if (b.traits != 0) 'Traits: +${b.traits}',
      if (b.bonus != 0) 'Manual bonus: ${b.bonus >= 0 ? '+' : ''}${b.bonus}',
    ].join('\n');
    final spentBreakdown =
        'Signatures: ${b.signatures}\nUnique Abilities: ${b.uniqueAbilities}';

    return SectionCard(
      title: 'Technique Points',
      icon: Icons.savings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'One shared pool across Signatures and Unique Abilities. ',
            style:
                theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DerivedStat(
                label: 'Maximum',
                value: '${b.max}',
                emphasize: true,
                tooltip: breakdown,
              ),
              DerivedStat(
                label: 'Spent',
                value: '${b.spent}',
                emphasize: true,
                tooltip: spentBreakdown,
              ),
              DerivedStat(
                label: 'Remaining',
                value: '${b.remaining}',
                emphasize: true,
                warn: over,
                tooltip: over ? 'You have spent more TP than your maximum' : null,
              ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey('tp-bonus-${character.id}'),
                  initialValue: character.bonusTechniquePoints == 0
                      ? ''
                      : '${character.bonusTechniquePoints}',
                  decoration: const InputDecoration(
                    labelText: 'Bonus TP',
                    border: OutlineInputBorder(),
                    isDense: true,
                    helperText: 'manual',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                  ],
                  onChanged: (v) => onUpdate(() =>
                      character.bonusTechniquePoints = int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          if (over)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Over budget by ${-b.remaining} TP.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
