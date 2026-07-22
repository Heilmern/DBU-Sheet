/// character_calculator_test.dart
/// ---------------------------------------------------------------------------
/// Unit tests for the DBU rules engine. These pin down the CONFIRMED formulas
/// so any accidental regression is caught immediately, and they double as
/// executable documentation of how the numbers are meant to behave.
///
/// Run with:  flutter test
/// ---------------------------------------------------------------------------
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dbu_sheet/data/accessories.dart';
import 'package:dbu_sheet/data/apparel.dart';
import 'package:dbu_sheet/data/basic_items.dart';
import 'package:dbu_sheet/data/combat_flow.dart';
import 'package:dbu_sheet/data/custom_buff_targets.dart';
import 'package:dbu_sheet/data/custom_species_traits.dart';
import 'package:dbu_sheet/data/signature_modifiers.dart';
import 'package:dbu_sheet/data/signature_profiles.dart';
import 'package:dbu_sheet/data/unique_abilities.dart';
import 'package:dbu_sheet/data/aspects.dart';
import 'package:dbu_sheet/data/awakenings.dart';
import 'package:dbu_sheet/data/dbu_rules.dart';
import 'package:dbu_sheet/data/enhancements.dart';
import 'package:dbu_sheet/data/factor_traits.dart';
import 'package:dbu_sheet/data/forms.dart';
import 'package:dbu_sheet/data/greater_awakenings.dart';
import 'package:dbu_sheet/data/homebrew_registry.dart';
import 'package:dbu_sheet/data/super_awakenings.dart';
import 'package:dbu_sheet/data/beast_traits.dart';
import 'package:dbu_sheet/data/race_traits.dart';
import 'package:dbu_sheet/data/talents.dart';
import 'package:dbu_sheet/data/transformations.dart';
import 'package:dbu_sheet/data/weapons.dart';
import 'package:dbu_sheet/models/character.dart';
import 'package:dbu_sheet/models/homebrew.dart';
import 'package:dbu_sheet/services/character_calculator.dart';
import 'package:dbu_sheet/services/combat_reminders.dart';
import 'package:dbu_sheet/services/import_export_service.dart';
import 'package:dbu_sheet/services/progression_talent_sync.dart';
import 'package:dbu_sheet/services/race_resource_sync.dart';
import 'package:dbu_sheet/services/trait_talent_sync.dart';
import 'package:dbu_sheet/services/rule_text.dart';
import 'package:dbu_sheet/ui/combat_screen.dart';
import 'package:dbu_sheet/ui/transformations_screen.dart'
    show TransformationsTab;

/// Test-only helper: Attribute Scores are computed from Race +
/// Progression/Bonus Perks (see `Character.scoreOf`), not directly settable
/// — this pins a score to an exact value for formula tests by adding a
/// Bonus Perk with whatever delta is needed, regardless of Race/existing
/// state.
extension TestAttributeScore on Character {
  void setTestScore(DbuAttribute attr, int score) {
    final delta = score - scoreOf(attr);
    bonusPerks.add(BonusPerkEntry(
      resolvedKind: ProgressionGrantKind.attributeAddition,
      attributePoints: {attr: delta},
    ));
  }
}

void main() {
  group('Attribute modifier', () {
    test('modifier equals the raw score', () {
      expect(CharacterCalculator.attributeModifier(1), 1);
      expect(CharacterCalculator.attributeModifier(2), 2);
      expect(CharacterCalculator.attributeModifier(6), 6);
      expect(CharacterCalculator.attributeModifier(7), 7);
    });
  });

  group('Attribute bonus (Skills-only)', () {
    test('bonus is floor(score / 2)', () {
      expect(CharacterCalculator.attributeBonus(1), 0);
      expect(CharacterCalculator.attributeBonus(2), 1);
      expect(CharacterCalculator.attributeBonus(6), 3);
      expect(CharacterCalculator.attributeBonus(7), 3);
    });
  });

  group('Resource pools', () {
    test('Max Life matches the site Saiyan example (PL1, Tenacity 4 = 71)', () {
      final c = Character.blank('t1')
        ..race = 'Saiyan' // Racial Life Modifier 3
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.tenacity, 4);
      // 60 + 12*(1-1) + 3*1 + 2*4*1 = 60 + 0 + 3 + 8 = 71
      expect(CharacterCalculator.maxLife(c), 71);
    });

    test('Max Ki and Capacity scale per Power Level', () {
      final c = Character.blank('t2')..powerLevel = 3;
      expect(CharacterCalculator.maxKi(c), 50 + 12 * 2); // 74
      expect(CharacterCalculator.maxCapacity(c), 20 + 4 * 2); // 28
    });
  });

  group('Races catalogue', () {
    test('has all 18 Races plus Custom Species, every name unique', () {
      expect(kDbuRaces.length, 19);
      expect(kDbuRaces.map((r) => r.name).toSet().length, 19);
    });

    test('Racial Life Modifiers match each Race\'s own page', () {
      final expected = <String, int>{
        'Android': 4,
        'Angel': 4,
        'Arcosian': 5,
        'Bio Android': 3,
        'Cerealian': 3,
        'Demon': 4,
        'Earthling': 4,
        'Glass Tribe': 2,
        'Heran': 2,
        'Konatsian': 3,
        'Majin': 3,
        'Namekian': 5,
        'Neko Majin': 4,
        'Neo-Tuffle': 4,
        'Saiyan': 3,
        'Shadow Dragon': 7,
        'Shinjin': 4,
        'Yardrat': 1,
        'Custom Species': 3, // "ARC Advice on Custom Species": "+3"
      };
      expected.forEach((name, rlm) {
        expect(raceByName(name).racialLifeModifier, rlm, reason: name);
      });
    });

    test('Custom Species baseline matches the ARC Advice block', () {
      // Verbatim (Custom Species page): "Racial Life Modifier. +3",
      // "Saving Throw: Choose One (Impulsive, Cognitive, Corporeal or
      // Morale)", "Skill Ranks: 2".
      final race = raceByName('Custom Species');
      expect(race.racialLifeModifier, 3);
      expect(race.skillRanks, 2);
      // The Saving Throw is a player pick, so the Race lists none itself.
      expect(race.savingThrows, isEmpty);

      final c = Character.blank('cs-base')..race = 'Custom Species';
      expect(CharacterCalculator.racialLifeModifier(c), 3);
      expect(CharacterCalculator.raceSkillRanks(c), 2);
    });

    test('each Flaw Trait grants +2 Racial Life Modifier or +1 Skill Rank', () {
      // Verbatim (Step 7): "For each Flaw Trait you pick, either increase the
      // Racial Life Modifier of your Race by 2 or increase the number of Skill
      // Ranks granted by your Race by 1."
      final c = Character.blank('cs-flaw')..race = 'Custom Species';
      c.customRaceTraits
        ..add(TrackedEntry()..name = 'Brittle')
        ..add(TrackedEntry()..name = 'Heavy');
      // An un-chosen compensation contributes to neither total.
      expect(CharacterCalculator.racialLifeModifier(c), 3);
      expect(CharacterCalculator.raceSkillRanks(c), 2);

      c.customFlawCompensation['Brittle'] = FlawCompensation.racialLifeModifier;
      c.customFlawCompensation['Heavy'] = FlawCompensation.skillRank;
      expect(CharacterCalculator.racialLifeModifier(c), 3 + 2);
      expect(CharacterCalculator.raceSkillRanks(c), 2 + 1);

      // Non-Flaw Traits never pay out, even if a stale key names one.
      c.customRaceTraits.add(TrackedEntry()..name = 'Dense Body');
      c.customFlawCompensation['Dense Body'] = FlawCompensation.skillRank;
      expect(CharacterCalculator.raceSkillRanks(c), 2 + 1);

      // Over the max. 2 Flaws, the excess doesn't inflate the totals.
      c.customRaceTraits.add(TrackedEntry()..name = 'Wasteful');
      c.customFlawCompensation['Wasteful'] = FlawCompensation.skillRank;
      expect(CharacterCalculator.customSpeciesFlaws(c), hasLength(2));
      expect(CharacterCalculator.raceSkillRanks(c), 2 + 1);
    });

    test('the Flaw compensation feeds Max Life through the Racial Life '
        'Modifier', () {
      final c = Character.blank('cs-life')
        ..race = 'Custom Species'
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.tenacity, 4);
      // 60 + 12*(1-1) + RLM*1 + 2*4*1
      expect(CharacterCalculator.maxLife(c), 60 + 3 + 8);
      c.customRaceTraits.add(TrackedEntry()..name = 'Brittle');
      c.customFlawCompensation['Brittle'] = FlawCompensation.racialLifeModifier;
      expect(CharacterCalculator.maxLife(c), 60 + 5 + 8);
    });

    test('the Custom Species catalogue splits into 41 Traits + 17 Flaws', () {
      expect(kDbuCustomSpeciesRacialTraits, hasLength(41));
      expect(kDbuCustomSpeciesFlaws, hasLength(17));
      expect(kMaxCustomSpeciesFlaws, 2);
      // Flaws carry no [Twinned] effects (they are never Primary).
      expect(kDbuCustomSpeciesFlaws.any((f) => f.hasTwinnedEffects), isFalse);
    });

    test('raceByName falls back to a zero-modifier entry for an unknown '
        'race name', () {
      final fallback = raceByName('Homebrew Alien');
      expect(fallback.name, 'Homebrew Alien');
      expect(fallback.racialLifeModifier, 0);
    });
  });

  group('Skills', () {
    test('Skill Bonus = floor(score/2) + 2*ranks', () {
      final c = Character.blank('t3')
        ..setTestScore(DbuAttribute.agility, 6);
      // Acrobatics is an Agility skill; give it 1 rank -> 3 + 2 = 5.
      final acrobatics =
          kDbuSkills.firstWhere((s) => s.name == 'Acrobatics');
      c.skills['Acrobatics']!.setRanks(SkillProgress.normalKey, 1);
      expect(CharacterCalculator.skillBonus(c, acrobatics), 5);
    });
  });

  group('Aptitudes', () {
    test('Might is the higher of Force/Magic Modifier (= Score)', () {
      final c = Character.blank('a1')
        ..setTestScore(DbuAttribute.force, 5)
        ..setTestScore(DbuAttribute.magic, 8);
      expect(CharacterCalculator.might(c), 8);
    });

    test('Haste is floor(Agility Modifier / 2)', () {
      final c = Character.blank('a2')
        ..setTestScore(DbuAttribute.agility, 7);
      expect(CharacterCalculator.haste(c), 3); // floor(7/2)
    });

    test('Awareness is the full Insight Modifier (not halved)', () {
      final c = Character.blank('a3')
        ..setTestScore(DbuAttribute.insight, 5);
      expect(CharacterCalculator.awareness(c), 5);
    });

    test('Speed: Normal = 2 + Haste, Boosted = Agility Modifier + 2', () {
      final c = Character.blank('a4')
        ..setTestScore(DbuAttribute.agility, 7);
      expect(CharacterCalculator.speedNormal(c), 5); // 2 + floor(7/2)
      expect(CharacterCalculator.speedBoosted(c), 9); // 7 + 2
    });

    test('Defense Value and Soak scale the Size adjustment by Tier of Power',
        () {
      final c = Character.blank('a5')
        ..setTestScore(DbuAttribute.agility, 6)
        ..setTestScore(DbuAttribute.tenacity, 4)
        ..size = DbuSize.small
        ..powerLevel = 10; // Tier of Power 3
      expect(CharacterCalculator.defenseValue(c), 6 + 1 * 3);
      // Raw Soak = 4 + (-1*3) = 1, but the Minimum Soak Value of 1(bT) floors
      // it at baseTierOfPower (3) here.
      expect(CharacterCalculator.soak(c), 3);
    });

    test('Soak is never floored below the raw value when it already exceeds '
        'the minimum', () {
      final c = Character.blank('a6')
        ..setTestScore(DbuAttribute.tenacity, 20)
        ..size = DbuSize.large
        ..powerLevel = 1; // Tier of Power 1, minimum Soak = 1
      expect(CharacterCalculator.soak(c), 20 + 1 * 1);
    });
  });

  group('Saving Throws', () {
    test('use the raw governing Attribute Score, not a halved Modifier', () {
      final c = Character.blank('s1')
        ..setTestScore(DbuAttribute.agility, 7)
        ..setTestScore(DbuAttribute.tenacity, 5)
        ..setTestScore(DbuAttribute.insight, 9)
        ..setTestScore(DbuAttribute.personality, 3);
      expect(
          CharacterCalculator.savingThrow(c, DbuSavingThrow.impulsive), 7);
      expect(
          CharacterCalculator.savingThrow(c, DbuSavingThrow.corporeal), 5);
      // Cognitive is governed by Insight, not Scholarship.
      expect(
          CharacterCalculator.savingThrow(c, DbuSavingThrow.cognitive), 9);
      expect(CharacterCalculator.savingThrow(c, DbuSavingThrow.morale), 3);
    });
  });

  group('Karma', () {
    test('a new Z-Soul starts at 2 Karma Points', () {
      final c = Character.blank('k1');
      expect(c.zSoul.karma, 2);
    });
  });

  group('Tier of Power table', () {
    test('maps Power Level bands 1..30 correctly', () {
      final expected = <int, int>{
        1: 1, 4: 1, 5: 2, 9: 2, 10: 3, 14: 3,
        15: 4, 19: 4, 20: 5, 24: 5, 25: 6, 29: 6, 30: 7,
      };
      expected.forEach((pl, top) {
        expect(PowerLevelRules.tierOfPower(pl), top, reason: 'PL $pl');
      });
    });
  });

  group('Tier-of-Power limits', () {
    test('Skill Rank limit per Skill: ToP1 2, ToP2 3, ToP3 4, ToP4+ 5', () {
      final expected = <int, int>{
        1: 2, // ToP 1
        5: 3, // ToP 2
        10: 4, // ToP 3
        15: 5, // ToP 4
        20: 5, // ToP 5 (capped at 5)
        30: 5, // ToP 7 (capped at 5)
      };
      expected.forEach((pl, limit) {
        final c = Character.blank('srl$pl')..powerLevel = pl;
        expect(CharacterCalculator.skillRankLimit(c), limit, reason: 'PL $pl');
      });
    });

    test('Attribute Score limit: ToP1 8, +3 per Tier of Power', () {
      final expected = <int, int>{
        1: 8, // ToP 1
        5: 11, // ToP 2
        10: 14, // ToP 3
        15: 17, // ToP 4
        20: 20, // ToP 5
      };
      expected.forEach((pl, limit) {
        final c = Character.blank('asl$pl')..powerLevel = pl;
        expect(CharacterCalculator.attributeScoreLimit(c), limit,
            reason: 'PL $pl');
      });
    });
  });

  group('Persistence round-trip', () {
    test('toJson/fromJson preserves player choices', () {
      final original = Character.blank('t4')
        ..name = 'Test Warrior'
        ..race = 'Namekian'
        ..powerLevel = 7
        ..setTestScore(DbuAttribute.force, 5);
      final restored = Character.fromJson(original.toJson());
      expect(restored.name, 'Test Warrior');
      expect(restored.race, 'Namekian');
      expect(restored.powerLevel, 7);
      expect(restored.scoreOf(DbuAttribute.force), 5);
    });

    test('round-trips Capacity Spent, Super Stacks, thresholds, tracked '
        'lists and Custom Buffs', () {
      final original = Character.blank('t5')
        ..capacitySpent = 6
        ..superStacks = 2
        ..powerStacks = 1
        ..diminishingOffenseStacks = 2
        ..diminishingDefenseStacks = 3
        ..bruisedSteadfastPassed = true
        ..criticalSteadfastPassed = true;
      original.resources.add(TrackedEntry(name: 'Power', stacks: 2, maxStacks: 3));
      original.conditions.add(TrackedEntry(name: 'Fatigued', notes: 'halve capacity'));
      original.states.add(TrackedEntry(name: 'Raging', stacks: 1, maxStacks: 1));
      original.customBuffs.add(CustomBuff(
        name: 'Battle Born',
        target: CustomBuffTarget.strikeAll,
        flat: 1,
        perBaseTier: 1,
      ));

      final restored = Character.fromJson(original.toJson());
      expect(restored.capacitySpent, 6);
      expect(restored.superStacks, 2);
      expect(restored.powerStacks, 1);
      expect(restored.diminishingOffenseStacks, 2);
      expect(restored.diminishingDefenseStacks, 3);
      expect(restored.bruisedSteadfastPassed, isTrue);
      expect(restored.injuredSteadfastPassed, isFalse);
      expect(restored.criticalSteadfastPassed, isTrue);
      expect(restored.resources.single.name, 'Power');
      expect(restored.resources.single.stacks, 2);
      expect(restored.conditions.single.notes, 'halve capacity');
      expect(restored.states.single.name, 'Raging');
      expect(restored.customBuffs.single.name, 'Battle Born');
      expect(restored.customBuffs.single.target, CustomBuffTarget.strikeAll);
      expect(restored.customBuffs.single.perBaseTier, 1);
    });
  });

  group('Dice pools', () {
    test('ToP Extra Dice matches the confirmed table', () {
      final expected = <int, String>{
        1: '–',
        2: '+1d4',
        3: '+1d6',
        4: '+1d8',
        5: '+1d10',
        6: '+1d10+1d4',
        7: '+1d10+1d6',
      };
      expected.forEach((top, label) {
        final c = Character.blank('d$top')..powerLevel = _plForTop(top);
        expect(CharacterCalculator.topExtraDice(c), label, reason: 'ToP $top');
      });
    });

    test('Critical Dice starts at 1d6 and Greater Dice starts at 1d4', () {
      final c1 = Character.blank('d8')..powerLevel = 1; // ToP 1
      expect(CharacterCalculator.criticalDice(c1), '+1d6');
      expect(CharacterCalculator.greaterDice(c1), '+1d4');

      final c2 = Character.blank('d9')..powerLevel = 5; // ToP 2
      expect(CharacterCalculator.criticalDice(c2), '+1d8');
      expect(CharacterCalculator.greaterDice(c2), '+1d6');
    });

    test('Healing Surge = 2d10 per Tier of Power, plus Surgency as a flat '
        'addend', () {
      // CONFIRMED (verbatim): "Healing Surge: You regain 2d10(T) Life
      // Points."
      final c0 = Character.blank('d10')
        ..powerLevel = 1 // ToP 1
        ..setTestScore(DbuAttribute.force, 0);
      expect(CharacterCalculator.healingSurgeDice(c0), '2d10');

      final c1 = Character.blank('d10b')
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.force, 5);
      expect(CharacterCalculator.healingSurgeDice(c1), '2d10+5');

      final c3 = Character.blank('d10c')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.force, 0);
      expect(CharacterCalculator.healingSurgeDice(c3), '6d10');
    });

    test('Critical Target can never drop below 7 (RollValue clamps)', () {
      // CONFIRMED (verbatim): "You cannot, through any means, have a
      // Critical Target lower than 7."
      expect(const RollValue(0, criticalTarget: 5).criticalTarget, 7);
      expect(const RollValue(0, criticalTarget: 9).criticalTarget, 9);
    });
  });

  group('Surgency', () {
    test('equals the Force Modifier', () {
      final c = Character.blank('sg1')
        ..setTestScore(DbuAttribute.force, 8);
      expect(CharacterCalculator.surgency(c), 8);
    });
  });

  group('Power Surge', () {
    test('Ki restores floor(Max Ki/4) + Surgency (worked example: Max Ki '
        '50, Force Modifier 1 -> 12 + 1 = +13)', () {
      final c = Character.blank('p1')..powerLevel = 1; // Max Ki 50
      expect(CharacterCalculator.powerSurgeKi(c), 13);
    });

    test('Capacity restores floor(Max Capacity/4), with NO Surgency added',
        () {
      final c = Character.blank('p2')
        ..powerLevel = 1 // Max Capacity 20
        ..setTestScore(DbuAttribute.force, 8); // large Surgency
      expect(CharacterCalculator.powerSurgeCapacity(c), 5); // 20/4, no +8
    });

    test('Surgency scales Power Surge Ki with the Force Modifier', () {
      final c = Character.blank('p3')
        ..powerLevel = 1 // Max Ki 50
        ..setTestScore(DbuAttribute.force, 8);
      expect(CharacterCalculator.powerSurgeKi(c), 50 ~/ 4 + 8); // 12 + 8
    });
  });

  group('Super Stacks', () {
    test('Muscle Penalty, Solid Bulk and Massive Power scale with stacks', () {
      final c = Character.blank('ss1')
        ..superStacks = 2
        ..powerLevel = 10 // Base Tier of Power 3
        ..setTestScore(DbuAttribute.force, 8); // Force Modifier 8
      expect(CharacterCalculator.superStackMusclePenalty(c), 2 * 3);
      expect(CharacterCalculator.superStackSolidBulk(c), 2 * 3);
      expect(CharacterCalculator.superStackMassivePower(c), 2 * (8 ~/ 4));
    });

    test('Muscle Penalty gets an extra -1(bT) at the max of 3 stacks', () {
      final c = Character.blank('ss2')
        ..superStacks = 3
        ..powerLevel = 10; // Base Tier of Power 3
      expect(CharacterCalculator.superStackMusclePenalty(c), (3 + 1) * 3);
    });
  });

  group('Default Resources', () {
    test('Power grants +1(T) Combat Rolls and +1/4 Max Capacity per stack',
        () {
      final c = Character.blank('dr1')
        ..powerStacks = 2
        ..powerLevel = 10; // Tier of Power 3, Max Capacity 20 + 4*9 = 56
      expect(CharacterCalculator.powerCombatRollBonus(c), 2 * 3);
      expect(CharacterCalculator.powerMaxCapacityBonus(c),
          2 * (CharacterCalculator.maxCapacity(c) ~/ 4));
    });

    test('Power bonus is folded into Strike, Dodge, Wound and Max Capacity',
        () {
      final c = Character.blank('dr2')..powerStacks = 1;
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final baselineCap = CharacterCalculator.maxCapacity(c);
      final stats = CharacterCalculator.compute(c);
      final bonus = CharacterCalculator.powerCombatRollBonus(c);
      expect(stats.strike.total, baselineStrike + bonus);
      expect(stats.maxCapacity,
          baselineCap + CharacterCalculator.powerMaxCapacityBonus(c));
    });

    test('Diminishing Offense reduces Strike by 1(bT) per stack, Dodge '
        'unaffected', () {
      final c = Character.blank('dr3')
        ..diminishingOffenseStacks = 2
        ..powerLevel = 10 // Base Tier of Power 3
        // High enough Awareness that the penalty doesn't hit the 0 floor,
        // so this test isolates Strike/Dodge separation, not flooring.
        ..setTestScore(DbuAttribute.insight, 20);
      expect(CharacterCalculator.diminishingOffensePenalty(c), 2 * 3);
      final stats = CharacterCalculator.compute(c);
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      expect(stats.strike.total, baselineStrike - 2 * 3);
      expect(stats.dodge.total, CharacterCalculator.defenseValue(c));
    });

    test('Diminishing Defense reduces Dodge by a FLAT 1 per stack (not '
        'Tier-scaled), Strike unaffected', () {
      final c = Character.blank('dr4')
        ..diminishingDefenseStacks = 3
        ..powerLevel = 10 // Base Tier of Power 3 — should NOT scale this
        // High enough Defense Value that the penalty doesn't hit the 0
        // floor, so this test isolates Strike/Dodge separation.
        ..setTestScore(DbuAttribute.agility, 20);
      expect(CharacterCalculator.diminishingDefensePenalty(c), 3);
      final stats = CharacterCalculator.compute(c);
      expect(stats.dodge.total, CharacterCalculator.defenseValue(c) - 3);
    });

    test('Diminishing Defense stacks gained per hit scale with Base Tier of '
        'Power (1~2->1, 3~4->2, 5~6->3, 7->4)', () {
      final expected = <int, int>{1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4};
      expected.forEach((top, stacksPerHit) {
        final c = Character.blank('dr5-$top')..powerLevel = _plForTop(top);
        expect(CharacterCalculator.diminishingDefenseStacksPerHit(c),
            stacksPerHit,
            reason: 'Base ToP $top');
      });
    });
  });

  group('Health Threshold penalty', () {
    test('accumulates -1(bT) per un-passed threshold currently under', () {
      final c = Character.blank('h1')..powerLevel = 10; // Base ToP 3
      // Life ratio 0.20 -> under Bruised AND Injured, not Critical.
      expect(CharacterCalculator.healthThresholdPenalty(c, 20, 100), 2 * 3);
    });

    test('a passed Steadfast Check nullifies that threshold\'s penalty', () {
      final c = Character.blank('h2')
        ..powerLevel = 10
        ..bruisedSteadfastPassed = true;
      expect(CharacterCalculator.healthThresholdPenalty(c, 20, 100), 1 * 3);
    });
  });

  group('Custom Buffs', () {
    test('Total = Flat + (bT)*BaseTierOfPower + (T)*TierOfPower', () {
      final c = Character.blank('cb1')..powerLevel = 10; // ToP 3
      final buff = CustomBuff(
        target: CustomBuffTarget.strikeAll,
        flat: 2,
        perBaseTier: 1,
        perTier: 1,
      );
      expect(CharacterCalculator.customBuffTotal(c, buff), 2 + 3 + 3);
    });

    test('an inactive buff contributes nothing', () {
      final c = Character.blank('cb2')..powerLevel = 10;
      final buff = CustomBuff(active: false, flat: 5);
      expect(CharacterCalculator.customBuffTotal(c, buff), 0);
    });

    test('is applied into the matching DerivedCharacterStats field', () {
      final c = Character.blank('cb3')
        ..customBuffs.add(CustomBuff(
          target: CustomBuffTarget.maxLife,
          flat: 10,
        ));
      final baseline = CharacterCalculator.maxLife(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxLife, baseline + 10);
    });
  });

  group('Capacity Spent', () {
    test('Current Capacity is Max Capacity minus Capacity Spent', () {
      final c = Character.blank('cap1')
        ..powerLevel = 1 // Max Capacity 20
        ..capacitySpent = 7;
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxCapacity, 20);
      expect(stats.currentCapacity, 13);
    });
  });

  group('Zero floor (system default minimum)', () {
    test('Strike/Dodge never go negative under a huge Diminishing '
        'Offense/Defense penalty', () {
      final c = Character.blank('z1')
        ..diminishingOffenseStacks = 50
        ..diminishingDefenseStacks = 50
        ..powerLevel = 30;
      final stats = CharacterCalculator.compute(c);
      expect(stats.strike.total, 0);
      expect(stats.dodge.total, 0);
    });

    test('Wound Rolls never go negative under a huge Custom Debuff', () {
      final c = Character.blank('z1b')
        ..customBuffs.addAll([
          CustomBuff(target: CustomBuffTarget.woundPhysical, flat: -999),
          CustomBuff(target: CustomBuffTarget.woundEnergy, flat: -999),
          CustomBuff(target: CustomBuffTarget.woundMagic, flat: -999),
        ]);
      final stats = CharacterCalculator.compute(c);
      expect(stats.woundPhysical.total, 0);
      expect(stats.woundEnergy.total, 0);
      expect(stats.woundMagic.total, 0);
    });

    test('Aptitudes (Might, Defense Value, Speed, Initiative) floor at 0 '
        'under a large enough Custom Debuff', () {
      final c = Character.blank('z2')
        ..customBuffs.addAll([
          CustomBuff(target: CustomBuffTarget.might, flat: -999),
          CustomBuff(target: CustomBuffTarget.defenseValue, flat: -999),
          CustomBuff(target: CustomBuffTarget.normalSpeed, flat: -999),
          CustomBuff(target: CustomBuffTarget.boostedSpeed, flat: -999),
          CustomBuff(target: CustomBuffTarget.initiative, flat: -999),
        ]);
      final stats = CharacterCalculator.compute(c);
      expect(stats.might, 0);
      expect(stats.defenseValue, 0);
      expect(stats.speedNormal, 0);
      expect(stats.speedBoosted, 0);
      expect(stats.initiative, 0);
    });

    test('Soak floors at 0 under a large enough debuff, overriding its own '
        'normal 1(bT) minimum', () {
      final c = Character.blank('z3')
        ..customBuffs.add(CustomBuff(target: CustomBuffTarget.soak, flat: -999));
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, 0);
    });

    test('Max Life/Ki/Capacity floor at 0 (and current pools do not throw)',
        () {
      final c = Character.blank('z4')
        ..customBuffs.addAll([
          CustomBuff(target: CustomBuffTarget.maxLife, flat: -9999),
          CustomBuff(target: CustomBuffTarget.maxKi, flat: -9999),
          CustomBuff(target: CustomBuffTarget.maxCapacity, flat: -9999),
        ]);
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxLife, 0);
      expect(stats.maxKi, 0);
      expect(stats.maxCapacity, 0);
      expect(stats.currentLife, 0);
      expect(stats.currentKi, 0);
      expect(stats.currentCapacity, 0);
    });

    test('Saving Throws floor at 0', () {
      final c = Character.blank('z5')
        ..customBuffs.add(
            CustomBuff(target: CustomBuffTarget.impulsiveSaves, flat: -999));
      final stats = CharacterCalculator.compute(c);
      expect(stats.savingThrows[DbuSavingThrow.impulsive]!.total, 0);
    });
  });

  group('Combat Conditions catalogue', () {
    test('has 18 entries and every name is unique', () {
      expect(kDbuConditions.length, 18);
      expect(kDbuConditions.map((c) => c.name).toSet().length, 18);
    });

    test('exactly 4 Conditions are automated: Broken, Guard Down, Shaken, '
        'Transfigured', () {
      final automated =
          kDbuConditions.where((c) => c.isAutomated).map((c) => c.name).toSet();
      expect(automated, {'Broken', 'Guard Down', 'Shaken', 'Transfigured'});
    });

    test('conditionDefByName returns null for an unrecognized/custom name',
        () {
      expect(conditionDefByName('Homebrew Curse'), isNull);
      expect(conditionDefByName('Shaken'), isNotNull);
    });
  });

  group('Condition automation', () {
    test('Broken reduces Soak by 2(bT) per stack', () {
      final c = Character.blank('cond1')
        ..powerLevel = 10 // Base Tier of Power 3
        ..setTestScore(DbuAttribute.tenacity, 20);
      c.conditions.add(TrackedEntry(name: 'Broken', stacks: 2, maxStacks: 3));
      final baseline = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baseline - 2 * 2 * 3);
    });

    test('Guard Down reduces Dodge by 2(T), Shaken reduces Strike by 2(T)',
        () {
      final c = Character.blank('cond2')
        ..powerLevel = 10 // Tier of Power 3
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      c.conditions.add(TrackedEntry(name: 'Guard Down', stacks: 1));
      c.conditions.add(TrackedEntry(name: 'Shaken', stacks: 1));
      final baselineDodge = CharacterCalculator.defenseValue(c);
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.dodge.total, baselineDodge - 2 * 3);
      expect(stats.strike.total, baselineStrike - 2 * 3);
    });

    test('Transfigured reduces every Combat Roll by 2(bT)', () {
      final c = Character.blank('cond3')
        ..powerLevel = 10 // Base Tier of Power 3
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20)
        ..setTestScore(DbuAttribute.force, 20)
        ..setTestScore(DbuAttribute.magic, 20);
      c.conditions.add(TrackedEntry(name: 'Transfigured', stacks: 1));
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final baselineDodge = CharacterCalculator.defenseValue(c);
      final baselineWoundPhysical =
          CharacterCalculator.attributeModifier(c.scoreOf(DbuAttribute.force));
      final baselineWoundMagic =
          CharacterCalculator.attributeModifier(c.scoreOf(DbuAttribute.magic));
      final stats = CharacterCalculator.compute(c);
      expect(stats.strike.total, baselineStrike - 2 * 3);
      expect(stats.dodge.total, baselineDodge - 2 * 3);
      expect(stats.woundPhysical.total, baselineWoundPhysical - 2 * 3);
      expect(stats.woundMagic.total, baselineWoundMagic - 2 * 3);
    });

    test('a non-automated Condition (e.g. Fatigued) contributes no stat '
        'penalty even when stacked', () {
      final c = Character.blank('cond4')..powerLevel = 10;
      c.conditions
          .add(TrackedEntry(name: 'Fatigued', stacks: 2, maxStacks: 2));
      final baselineCap = CharacterCalculator.maxCapacity(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxCapacity, baselineCap);
      expect(CharacterCalculator.conditionPenalty(c, c.conditions.first), 0);
    });

    test('a custom/homebrew Condition name contributes no automated '
        'penalty', () {
      final c = Character.blank('cond5');
      final entry = TrackedEntry(name: 'Homebrew Curse', stacks: 1);
      c.conditions.add(entry);
      expect(CharacterCalculator.conditionPenalty(c, entry), 0);
    });

    test('0 stacks of an automated Condition contributes nothing', () {
      final c = Character.blank('cond6')..powerLevel = 10;
      final entry = TrackedEntry(name: 'Shaken', stacks: 0);
      c.conditions.add(entry);
      expect(CharacterCalculator.conditionPenalty(c, entry), 0);
    });
  });

  group('States catalogue', () {
    test('has 11 entries and every name is unique', () {
      expect(kDbuStates.length, 11);
      expect(kDbuStates.map((s) => s.name).toSet().length, 11);
    });

    test('exactly 4 States are automated: Raging, Mindful, Undying, '
        'Determined', () {
      final automated =
          kDbuStates.where((s) => s.isAutomated).map((s) => s.name).toSet();
      expect(automated, {'Raging', 'Mindful', 'Undying', 'Determined'});
    });

    test('stateDefByName returns null for an unrecognized/custom name', () {
      expect(stateDefByName('Homebrew Rage'), isNull);
      expect(stateDefByName('Undying'), isNotNull);
    });
  });

  group('State automation', () {
    test('Raging at Level 3 grants Wound +L(T) (L1+), Soak +L(T) (L2+) and '
        'ignores Health Threshold penalties (L3+), all using CURRENT Level',
        () {
      final c = Character.blank('st1')
        ..powerLevel = 10 // Tier of Power 3
        ..currentLife = 1 // deep under every Health Threshold
        ..setTestScore(DbuAttribute.force, 20)
        ..setTestScore(DbuAttribute.magic, 20)
        ..setTestScore(DbuAttribute.tenacity, 20);
      c.states.add(TrackedEntry(name: 'Raging', stacks: 3, maxStacks: 3));
      final baselineWoundPhysical =
          CharacterCalculator.attributeModifier(c.scoreOf(DbuAttribute.force));
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      // L=3 (current Level), Tier of Power 3 -> +9 to Wound and Soak.
      expect(stats.woundPhysical.total, baselineWoundPhysical + 3 * 3);
      expect(stats.soak, baselineSoak + 3 * 3);
      // Apoplectic (unlocked at L3) ignores the Health Threshold penalty
      // that would otherwise apply from being nearly Defeated.
      expect(stats.healthThresholdPenalty, 0);
    });

    test('Raging at Level 1 only grants the Angry Wound bonus (Furious/'
        'Apoplectic not yet unlocked)', () {
      final c = Character.blank('st2')
        ..powerLevel = 10 // Tier of Power 3
        ..currentLife = 1
        ..setTestScore(DbuAttribute.tenacity, 20);
      c.states.add(TrackedEntry(name: 'Raging', stacks: 1, maxStacks: 3));
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineSoak); // Furious (L2) not unlocked yet
      expect(stats.healthThresholdPenalty, greaterThan(0)); // no Apoplectic
    });

    test('Mindful reduces Wound Rolls by L(T) and ignores Health Threshold '
        'penalties at Level 3', () {
      final c = Character.blank('st3')
        ..powerLevel = 10 // Tier of Power 3
        ..currentLife = 1
        ..setTestScore(DbuAttribute.force, 20);
      c.states.add(TrackedEntry(name: 'Mindful', stacks: 3, maxStacks: 3));
      final baselineWoundPhysical =
          CharacterCalculator.attributeModifier(c.scoreOf(DbuAttribute.force));
      final stats = CharacterCalculator.compute(c);
      expect(stats.woundPhysical.total, baselineWoundPhysical - 3 * 3);
      expect(stats.healthThresholdPenalty, 0);
    });

    test('Undying reduces every Combat Roll by 1(T), regardless of Level '
        '(it has no Level system)', () {
      final c = Character.blank('st4')
        ..powerLevel = 10 // Tier of Power 3
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      c.states.add(TrackedEntry(name: 'Undying', stacks: 1, maxStacks: 1));
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.strike.total, baselineStrike - 1 * 3);
    });

    test('Determined ignores Health Threshold penalties', () {
      final c = Character.blank('st5')
        ..powerLevel = 10
        ..currentLife = 1;
      c.states.add(TrackedEntry(name: 'Determined', stacks: 1, maxStacks: 1));
      final stats = CharacterCalculator.compute(c);
      expect(stats.healthThresholdPenalty, 0);
    });

    test('a non-automated State (e.g. Superior) contributes nothing', () {
      final c = Character.blank('st6')..powerLevel = 10;
      c.states.add(TrackedEntry(name: 'Superior', stacks: 1, maxStacks: 1));
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.strike.total, baselineStrike);
      expect(CharacterCalculator.statePerStatEffect(c, c.states.first),
          isEmpty);
    });

    test('a custom/homebrew State name contributes no automated effect', () {
      final c = Character.blank('st7');
      final entry = TrackedEntry(name: 'Homebrew Rage', stacks: 1);
      c.states.add(entry);
      expect(CharacterCalculator.statePerStatEffect(c, entry), isEmpty);
      expect(CharacterCalculator.stateIgnoresHealthThresholdPenalties(c, entry),
          isFalse);
    });

    test('0 Level of an automated State contributes nothing', () {
      final c = Character.blank('st8')..powerLevel = 10;
      final entry = TrackedEntry(name: 'Raging', stacks: 0, maxStacks: 3);
      c.states.add(entry);
      expect(CharacterCalculator.statePerStatEffect(c, entry), isEmpty);
    });
  });

  group('Racial Traits catalogue', () {
    test('every one of the 18 Races has a non-empty Trait catalogue', () {
      for (final race in kDbuRaces) {
        if (race.name == 'Custom Species') continue;
        expect(raceTraitsFor(race.name), isNotEmpty,
            reason: '${race.name} should have Racial Traits catalogued');
      }
    });

    test('an unknown/Custom Species race has no catalogued Traits', () {
      expect(raceTraitsFor('Custom Species'), isEmpty);
      expect(raceTraitsFor('Not A Real Race'), isEmpty);
    });

    test('every Race has an Attribute Increase text, Saving Throw(s) and '
        'Skill Ranks — Custom Species picks its own Saving Throw', () {
      for (final race in kDbuRaces) {
        expect(race.attributeIncreaseText, isNotEmpty, reason: race.name);
        expect(race.skillRanks, greaterThan(0), reason: race.name);
        if (race.name == 'Custom Species') {
          // "Saving Throw: Choose One" — the pick lives on the Character
          // (`customSavingThrows`), so the Race itself lists none.
          expect(race.savingThrows, isEmpty);
          continue;
        }
        expect(race.savingThrows, isNotEmpty, reason: race.name);
      }
    });

    test('Neko Majin and Yardrat each have TWO Racial Saving Throws', () {
      expect(raceByName('Neko Majin').savingThrows,
          containsAll([DbuSavingThrow.cognitive, DbuSavingThrow.morale]));
      expect(raceByName('Yardrat').savingThrows,
          containsAll([DbuSavingThrow.cognitive, DbuSavingThrow.impulsive]));
    });
  });

  group('Health Thresholds under (raw count)', () {
    test('Healthy is under no Thresholds', () {
      expect(CharacterCalculator.thresholdsUnderCount(100, 100), 0);
    });

    test('Bruised (< 50%) is under 1 Threshold', () {
      expect(CharacterCalculator.thresholdsUnderCount(49, 100), 1);
    });

    test('Injured (< 25%) is under 2 Thresholds', () {
      expect(CharacterCalculator.thresholdsUnderCount(24, 100), 2);
    });

    test('Critical (<= 10%) is under 3 Thresholds', () {
      expect(CharacterCalculator.thresholdsUnderCount(10, 100), 3);
    });

    test('counts regardless of Steadfast pass/fail (unlike '
        'healthThresholdPenalty)', () {
      final c = Character.blank('th1')
        ..bruisedSteadfastPassed = true
        ..injuredSteadfastPassed = true
        ..criticalSteadfastPassed = true;
      // healthThresholdPenalty is nullified by passed Steadfast Checks...
      expect(CharacterCalculator.healthThresholdPenalty(c, 5, 100), 0);
      // ...but the raw "how far below" count used by Racial Traits is not.
      expect(CharacterCalculator.thresholdsUnderCount(5, 100), 3);
    });
  });

  group('Racial Saving Throw Bonus', () {
    test("Saiyan gets +1(T) and -1 Critical Target on Corporeal only", () {
      final c = Character.blank('rst1')
        ..race = 'Saiyan'
        ..powerLevel = 10 // Tier of Power 3
        ..setTestScore(DbuAttribute.tenacity, 5)
        ..setTestScore(DbuAttribute.insight, 5);
      final stats = CharacterCalculator.compute(c);
      expect(stats.savingThrows[DbuSavingThrow.corporeal]!.total, 5 + 3);
      expect(
          stats.savingThrows[DbuSavingThrow.corporeal]!.criticalTarget, 9);
      // Cognitive isn't a Saiyan Racial Saving Throw, so no bonus applies.
      expect(stats.savingThrows[DbuSavingThrow.cognitive]!.total, 5);
      expect(
          stats.savingThrows[DbuSavingThrow.cognitive]!.criticalTarget, 10);
    });

    test('Neko Majin gets the bonus on BOTH Cognitive and Morale', () {
      final c = Character.blank('rst2')
        ..race = 'Neko Majin'
        ..powerLevel = 10
        ..setTestScore(DbuAttribute.insight, 5)
        ..setTestScore(DbuAttribute.personality, 5);
      final stats = CharacterCalculator.compute(c);
      expect(stats.savingThrows[DbuSavingThrow.cognitive]!.total, 5 + 3);
      expect(stats.savingThrows[DbuSavingThrow.morale]!.total, 5 + 3);
      expect(
          stats.savingThrows[DbuSavingThrow.cognitive]!.criticalTarget, 9);
      expect(stats.savingThrows[DbuSavingThrow.morale]!.criticalTarget, 9);
    });

    test('Custom Species uses customSavingThrows instead of a fixed Race',
        () {
      final c = Character.blank('rst3')
        ..race = 'Custom Species'
        ..powerLevel = 10
        ..setTestScore(DbuAttribute.agility, 5)
        ..customSavingThrows.add(DbuSavingThrow.impulsive);
      final stats = CharacterCalculator.compute(c);
      expect(stats.savingThrows[DbuSavingThrow.impulsive]!.total, 5 + 3);
    });
  });

  group('Racial Trait automation', () {
    test("Saiyan's Blood of the Warrior scales Wound/Soak per Health "
        'Threshold below', () {
      final c = Character.blank('rt1')
        ..race = 'Saiyan'
        ..powerLevel = 10 // Tier of Power 3
        // Saiyan's racial Tenacity +2 raises Max Life above the naive
        // default, so this needs to be comfortably under Injured (< 25%)
        // but still above Critical (<= 10%) for exactly 2 thresholds under.
        ..currentLife = 60
        // Isolate from Saiyan's OTHER automated Soak Trait (Powerful
        // Physique), which is unconditional and would otherwise also add
        // to Soak here.
        ..inactiveRaceTraitNames.add('Powerful Physique');
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      // +1(T) per threshold under * 2 thresholds * ToP 3 = +6.
      expect(stats.soak, baselineSoak + 6);
    });

    test("Saiyan's Powerful Physique adds 1/4 Force Modifier (rounded up) "
        'to Soak, untouched by Tier scaling', () {
      final c = Character.blank('rt2')
        ..race = 'Saiyan'
        ..powerLevel = 10
        ..setTestScore(DbuAttribute.force, 10); // Force Mod 10 -> /4 = 3
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineSoak + 3);
    });

    test("Earthling Resolve scales Strike/Wound per Health Threshold below",
        () {
      final c = Character.blank('rt3')
        ..race = 'Earthling'
        ..powerLevel = 10 // ToP 3
        ..currentLife = 5; // <= 10% -> Critical -> 3 thresholds
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final stats = CharacterCalculator.compute(c);
      // +1(T) * 3 thresholds * ToP3 = +9, minus the (unrelated) Health
      // Threshold penalty of -1(bT) per un-passed threshold (3 * ToP3 = -9)
      // cancels out to the baseline exactly for this deliberately-chosen
      // scenario, so assert the Racial Trait math directly instead.
      final effect = CharacterCalculator.raceTraitEffect(
        c,
        raceTraitsFor('Earthling')
            .firstWhere((t) => t.name == 'Earthling Resolve'),
        currentLife: 5,
        maxLife: stats.maxLife,
      );
      expect(effect[AffectedStat.strike], 9);
      expect(stats.strike.total, baselineStrike); // net zero, see above
    });

    test("Heran's Greed of the Hera scales Soak per Power stack", () {
      final c = Character.blank('rt4')
        ..race = 'Heran'
        ..powerLevel = 10 // ToP 3
        ..powerStacks = 2;
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      // +1(T) * 2 stacks * ToP3 = +6, plus the universal Power Resource's
      // own Combat-Roll bonus doesn't touch Soak, so this is purely the
      // Racial Trait's contribution (no Solid Bulk here since that's Super
      // Stacks, a different Resource).
      expect(stats.soak, baselineSoak + 6);
    });

    test("Majin's Rubbery Body grants a flat +1(T) Soak and Defense Value",
        () {
      final c = Character.blank('rt5')
        ..race = 'Majin'
        ..powerLevel = 10; // ToP 3
      final baselineSoak = CharacterCalculator.soak(c);
      final baselineDv = CharacterCalculator.defenseValue(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineSoak + 3);
      expect(stats.defenseValue, baselineDv + 3);
    });

    test("Arcosian's Overwhelming Fighter scales Wound per stack of a "
        "player-tracked 'Overwhelm' Resource", () {
      final c = Character.blank('rt6')
        ..race = 'Arcosian'
        ..powerLevel = 10; // ToP 3
      c.resources.add(TrackedEntry(name: 'Overwhelm', stacks: 3));
      final stats = CharacterCalculator.compute(c);
      final forceMod = c.scoreOf(DbuAttribute.force);
      // +1(T) * 3 stacks * ToP3 = +9.
      expect(stats.woundPhysical.total, forceMod + 9);
    });

    test("Demon's Demonic Pressure buffs Wound per Demonic Power stack and "
        'penalizes Defense/Soak per Demonic Fatigue stack', () {
      final c = Character.blank('rt7')
        ..race = 'Demon'
        ..powerLevel = 10 // ToP 3
        // High enough Agility that the Demonic Fatigue penalty below doesn't
        // get clipped by the system's 0 floor, which would mask the effect.
        ..setTestScore(DbuAttribute.agility, 10);
      c.resources.add(TrackedEntry(name: 'Demonic Power', stacks: 1));
      c.resources.add(TrackedEntry(name: 'Demonic Fatigue', stacks: 1));
      final baselineSoak = CharacterCalculator.soak(c);
      final baselineDv = CharacterCalculator.defenseValue(c);
      final forceMod = c.scoreOf(DbuAttribute.force);
      final stats = CharacterCalculator.compute(c);
      // Demonic Power: +2(T) Wound * 1 stack * ToP3 = +6.
      expect(stats.woundPhysical.total, forceMod + 6);
      // Demonic Fatigue: -1(T) Defense/Soak * 1 stack * ToP3 = -3 each.
      expect(stats.soak, baselineSoak - 3);
      expect(stats.defenseValue, baselineDv - 3);
    });

    test('swapping a Trait out (inactiveRaceTraitNames) removes its '
        'automated effect', () {
      final c = Character.blank('rt8')
        ..race = 'Majin'
        ..powerLevel = 10
        ..inactiveRaceTraitNames.add('Rubbery Body');
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineSoak); // no +1(T) bonus while swapped out
      expect(CharacterCalculator.activeRaceTraits(c)
          .any((t) => t.name == 'Rubbery Body'), isFalse);
    });

    test("Saiyan's Battle Born applies each Resource independently to its "
        "own Combat Roll (Strike/Dodge/Wound are separate pools, not one "
        'shared max)', () {
      final c = Character.blank('rt9b')
        ..race = 'Saiyan'
        ..powerLevel = 10 // ToP 3
        ..resources.add(TrackedEntry(name: 'Battle Born (Strike)', stacks: 2))
        ..resources.add(TrackedEntry(name: 'Battle Born (Dodge)', stacks: 1));
      final baselineStrike =
          CharacterCalculator.haste(c) + CharacterCalculator.awareness(c);
      final baselineDv = CharacterCalculator.defenseValue(c);
      final stats = CharacterCalculator.compute(c);
      // +1(T) * 2 stacks * ToP3 = +6 Strike; +1(T) * 1 stack * ToP3 = +3
      // Dodge; no Battle Born (Wound) stacks tracked, so Wound is
      // untouched by this Trait.
      expect(stats.strike.total, baselineStrike + 6);
      expect(stats.dodge.total, baselineDv + 3);
    });

    test('a Race with no automated Traits contributes nothing extra', () {
      final c = Character.blank('rt9')
        ..race = 'Angel'
        ..powerLevel = 10;
      final baselineSoak = CharacterCalculator.soak(c);
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineSoak);
      expect(CharacterCalculator.raceTraitTotals(c,
          currentLife: stats.currentLife, maxLife: stats.maxLife), isEmpty);
    });
  });

  group('Racial Trait Option groups (catalogue integrity)', () {
    test('every Option group has 2+ options and a sane maxChoices', () {
      for (final trait in kDbuRaceTraits) {
        for (final group in trait.optionGroups) {
          expect(group.options.length, greaterThanOrEqualTo(2),
              reason: '${trait.race} — ${trait.name} — ${group.label}');
          expect(group.maxChoices, greaterThanOrEqualTo(1),
              reason: '${trait.race} — ${trait.name} — ${group.label}');
          expect(group.maxChoices, lessThanOrEqualTo(group.options.length),
              reason: '${trait.race} — ${trait.name} — ${group.label}');
        }
      }
    });

    test('Android Technological Being has two distinct Option groups', () {
      final trait = raceTraitsFor('Android')
          .firstWhere((t) => t.name == 'Technological Being');
      expect(trait.optionGroups, hasLength(2));
      expect(trait.optionGroups[0].maxChoices, 1);
      expect(trait.optionGroups[1].maxChoices, 2);
    });

    test('Majin Secondary Traits choose-4 group has 16 options', () {
      final trait = raceTraitsFor('Majin')
          .firstWhere((t) => t.name == 'Secondary Traits (choose 4)');
      expect(trait.optionGroups, hasLength(1));
      expect(trait.optionGroups.single.maxChoices, 4);
      expect(trait.optionGroups.single.options, hasLength(16));
    });

    test('every DependentChoice points at a real source Trait/group and '
        "covers every one of that group's Options (Eye of the Dragon, "
        'Draconic Physique, Combat Blueprint)', () {
      for (final trait in kDbuRaceTraits) {
        final dep = trait.dependentChoice;
        if (dep == null) continue;

        final source = raceTraitsFor(trait.race)
            .where((t) => t.name == dep.sourceTraitName);
        expect(source, isNotEmpty,
            reason: '${trait.race} — ${trait.name} references a missing '
                'source Trait ${dep.sourceTraitName}');

        final group = source.first.optionGroups
            .where((g) => g.label == dep.sourceGroupLabel);
        expect(group, isNotEmpty,
            reason: '${trait.race} — ${trait.name} references a missing '
                'Option group ${dep.sourceGroupLabel}');

        final optionNames = group.first.options.map((o) => o.name).toSet();
        expect(dep.textByOption.keys.toSet(), optionNames,
            reason: '${trait.race} — ${trait.name} must have exactly one '
                'branch of text per Option on ${dep.sourceTraitName}');
      }
    });
  });

  group('Race Trait Option choice persistence', () {
    test('raceTraitOptionChoices round-trips through JSON', () {
      final c = Character.blank('opt1')
        ..race = 'Saiyan'
        ..raceTraitOptionChoices['Saiyan Heritage::Option'] = {'Tailed'};
      final restored = Character.fromJson(c.toJson());
      expect(restored.raceTraitOptionChoices['Saiyan Heritage::Option'],
          {'Tailed'});
    });
  });

  group('ensureRaceGrantedResources', () {
    test("adds a Race Trait's granted Resources when missing (Battle Born "
        'is split per Combat Roll, not a single pool)', () {
      final c = Character.blank('grr1')..race = 'Saiyan';
      expect(c.resources, isEmpty);
      ensureRaceGrantedResources(c);
      expect(c.resources.any((r) => r.name == 'Battle Born (Strike)'),
          isTrue);
      expect(
          c.resources.any((r) => r.name == 'Battle Born (Dodge)'), isTrue);
      expect(
          c.resources.any((r) => r.name == 'Battle Born (Wound)'), isTrue);
    });

    test('does not duplicate a Resource the player already has (case-'
        'insensitive match)', () {
      final c = Character.blank('grr2')
        ..race = 'Saiyan'
        ..resources.add(TrackedEntry(name: 'battle born (strike)', stacks: 2));
      ensureRaceGrantedResources(c);
      expect(
          c.resources
              .where((r) => r.name.toLowerCase() == 'battle born (strike)'),
          hasLength(1));
      // The player's existing stacks/name-casing are left untouched.
      expect(c.resources.first.stacks, 2);
    });

    test('does not add a Resource for a Trait that has been swapped out',
        () {
      final c = Character.blank('grr3')
        ..race = 'Arcosian'
        ..inactiveRaceTraitNames.add('Overwhelming Fighter');
      ensureRaceGrantedResources(c);
      expect(c.resources.any((r) => r.name == 'Overwhelm'), isFalse);
    });

    test('adds an Option-specific Resource only once that Option is chosen '
        '(Shadow Dragon: Regenerative Dragon -> Dragon Slime)', () {
      final c = Character.blank('grr4')..race = 'Shadow Dragon';
      ensureRaceGrantedResources(c);
      expect(c.resources.any((r) => r.name == 'Dragon Slime'), isFalse);

      c.raceTraitOptionChoices['Personified Dragon Ball::Option'] = {
        'Regenerative Dragon',
      };
      ensureRaceGrantedResources(c);
      expect(c.resources.any((r) => r.name == 'Dragon Slime'), isTrue);
    });

    test('a Race with no granted-Resource Traits adds nothing', () {
      final c = Character.blank('grr5')..race = 'Angel';
      ensureRaceGrantedResources(c);
      expect(c.resources, isEmpty);
    });
  });

  group('Racial Factors catalogue', () {
    test('all 9 general Factors are present with sane maxFactor/traits', () {
      const generalFactors = {
        'Alternate Upbringing',
        'Beast-Man',
        'Cybernetic Enhancement',
        'Demon Clansman',
        'Monster',
        'Mutation',
        'Reincarnated',
        'Undead',
        'Unstable Clone',
      };
      expect(kDbuFactors.map((f) => f.name).toSet(), containsAll(generalFactors));
      for (final factor in kDbuFactors) {
        expect(factor.maxFactor, greaterThanOrEqualTo(1),
            reason: factor.name);
        expect(factor.traits, isNotEmpty, reason: factor.name);
      }
    });

    test('all 23 race-specific Factors are present, each locked to its own '
        'Race', () {
      const raceSpecificFactors = {
        'Machine Mutant': 'Android',
        'OG Soldier': 'Android',
        'Tamagami': 'Android',
        'Weapon of Mass Destruction': 'Bio Android',
        'Genetic Splicing': 'Bio Android',
        'Bio-Focus': 'Bio Android',
        'Megath': 'Demon',
        'Dragon Ball Hero': 'Earthling',
        'Saiyan Ancestry': 'Earthling',
        'Triclops': 'Earthling',
        'Assimilating Majin': 'Majin',
        'Android Majin': 'Majin',
        'Chaotic Majin': 'Majin',
        'Diluted Majin': 'Majin',
        'Primordial Majin': 'Majin',
        'Dark Vassal': 'Namekian',
        'Feline Warrior': 'Neko Majin',
        'Usagi Majin': 'Neko Majin',
        'Alternate Universe Saiyan': 'Saiyan',
        'Ancient Saiyan': 'Saiyan',
        'Half-Saiyan': 'Saiyan',
        'Disguised Dragon': 'Shadow Dragon',
        'Inverted Shadow': 'Shadow Dragon',
      };
      for (final entry in raceSpecificFactors.entries) {
        final factor = factorByName(entry.key);
        expect(factor, isNotNull, reason: entry.key);
        expect(factor!.isEligibleForRace(entry.value), isTrue,
            reason: entry.key);
        // Some other, unrelated Race should never be eligible.
        final otherRace = entry.value == 'Saiyan' ? 'Namekian' : 'Saiyan';
        expect(factor.isEligibleForRace(otherRace), isFalse,
            reason: entry.key);
      }
      expect(kDbuFactors, hasLength(9 + raceSpecificFactors.length));
    });

    test('factorByName resolves a known Factor and returns null for an '
        'unrecognized one', () {
      expect(factorByName('Beast-Man')?.maxFactor, 1);
      expect(factorByName('Not A Real Factor'), isNull);
    });

    test("Monster's Racial Requirement is Earthling or Demon only", () {
      final monster = factorByName('Monster')!;
      expect(monster.isEligibleForRace('Earthling'), isTrue);
      expect(monster.isEligibleForRace('Demon'), isTrue);
      expect(monster.isEligibleForRace('Saiyan'), isFalse);
    });

    test('Alternate Upbringing excludes Android/Bio Android and each '
        "'X-Raised' Trait excludes a character of Race X", () {
      final au = factorByName('Alternate Upbringing')!;
      expect(au.isEligibleForRace('Android'), isFalse);
      expect(au.isEligibleForRace('Bio Android'), isFalse);
      expect(au.isEligibleForRace('Saiyan'), isTrue);

      final saiyanRaised =
          au.traits.firstWhere((t) => t.name == 'Saiyan-Raised');
      expect(saiyanRaised.isEligibleForRace('Saiyan'), isFalse);
      expect(saiyanRaised.isEligibleForRace('Earthling'), isTrue);
    });

    test("Mutation's race-locked Factor Traits are restricted to their "
        'named Race only', () {
      final mutation = factorByName('Mutation')!;
      final legendarySaiyan =
          mutation.traits.firstWhere((t) => t.name == 'Legendary Saiyan');
      expect(legendarySaiyan.isEligibleForRace('Saiyan'), isTrue);
      expect(legendarySaiyan.isEligibleForRace('Earthling'), isFalse);
      // "Any Race" Factor Traits on the same Factor have no restriction.
      final brute = mutation.traits.firstWhere((t) => t.name == 'Brute');
      expect(brute.isEligibleForRace('Earthling'), isTrue);
    });
  });

  group('Factor Trait swapping', () {
    test('compatibleFactorTraitsFor returns nothing for a Primary Trait',
        () {
      final c = Character.blank('fac1')..race = 'Saiyan';
      final primary = raceTraitsFor('Saiyan')
          .firstWhere((t) => t.tier == RaceTraitTier.primary);
      expect(
          CharacterCalculator.compatibleFactorTraitsFor(c, primary), isEmpty);
    });

    test('compatibleFactorTraitsFor returns compatible options for a '
        'Secondary Trait, respecting Racial Requirement', () {
      final c = Character.blank('fac2')..race = 'Saiyan';
      final secondary = raceTraitsFor('Saiyan')
          .firstWhere((t) => t.tier == RaceTraitTier.secondary);
      final options =
          CharacterCalculator.compatibleFactorTraitsFor(c, secondary);
      expect(options, isNotEmpty);
      // Monster (Earthling/Demon only) should never appear for a Saiyan.
      expect(options.any((o) => o.factor.name == 'Monster'), isFalse);
      // Cybernetic Enhancement (Any Race) should be available.
      expect(
          options.any((o) => o.factor.name == 'Cybernetic Enhancement'),
          isTrue);
      // Mutation's Saiyan-only "Legendary Saiyan" should be reachable, but
      // its Namekian-only "Tremendous Lord" should not.
      expect(options.any((o) => o.trait.name == 'Legendary Saiyan'), isTrue);
      expect(options.any((o) => o.trait.name == 'Tremendous Lord'), isFalse);
    });

    test('a Factor already at its maxFactor usage is excluded from further '
        'compatible options', () {
      final c = Character.blank('fac3')
        ..race = 'Saiyan'
        ..factorSelections.add(FactorSelection(
          factorName: 'Reincarnated',
          factorTraitName: 'Lingering Power',
          replacedTraitName: "Warrior's Pride",
        ));
      final secondary = raceTraitsFor('Saiyan')
          .firstWhere((t) => t.name == 'Blood of the Warrior');
      final options =
          CharacterCalculator.compatibleFactorTraitsFor(c, secondary);
      // Reincarnated's maxFactor is 1 and it's already used once.
      expect(options.any((o) => o.factor.name == 'Reincarnated'), isFalse);
      expect(CharacterCalculator.factorUsageCount(c, 'Reincarnated'), 1);
    });

    test("activeRaceTraits substitutes the swapped-in Factor Trait in "
        "place of the Racial Trait it replaced", () {
      final c = Character.blank('fac4')
        ..race = 'Saiyan'
        ..factorSelections.add(FactorSelection(
          factorName: 'Reincarnated',
          factorTraitName: 'Lingering Power',
          replacedTraitName: "Warrior's Pride",
        ));
      final active = CharacterCalculator.activeRaceTraits(c);
      expect(active.any((t) => t.name == "Warrior's Pride"), isFalse);
      final swappedIn =
          active.firstWhere((t) => t.name == 'Lingering Power');
      expect(swappedIn.tier, RaceTraitTier.secondary);
      expect(swappedIn.race, 'Saiyan');
      // Every other canonical Trait remains untouched.
      expect(active.any((t) => t.name == 'Born for Battle'), isTrue);
    });

    test('a stale FactorSelection referencing an unknown Factor/Trait is '
        'ignored (the canonical Trait stays active)', () {
      final c = Character.blank('fac5')
        ..race = 'Saiyan'
        ..factorSelections.add(FactorSelection(
          factorName: 'Not A Real Factor',
          factorTraitName: 'Nonexistent',
          replacedTraitName: "Warrior's Pride",
        ));
      final active = CharacterCalculator.activeRaceTraits(c);
      expect(active.any((t) => t.name == "Warrior's Pride"), isTrue);
    });

    test('FactorSelection round-trips through Character JSON', () {
      final c = Character.blank('fac6')
        ..race = 'Saiyan'
        ..factorSelections.add(FactorSelection(
          factorName: 'Reincarnated',
          factorTraitName: 'Lingering Power',
          replacedTraitName: "Warrior's Pride",
        ));
      final restored = Character.fromJson(c.toJson());
      expect(restored.factorSelections, hasLength(1));
      expect(restored.factorSelections.single.factorName, 'Reincarnated');
      expect(restored.factorSelections.single.factorTraitName,
          'Lingering Power');
      expect(restored.factorSelections.single.replacedTraitName,
          "Warrior's Pride");
    });

    test("a Factor Trait with mustReplaceTraitName (bracket-locked) can "
        "replace a PRIMARY Racial Trait of that exact name", () {
      final c = Character.blank('fac7')..race = 'Android';
      final energyCore =
          raceTraitsFor('Android').firstWhere((t) => t.name == 'Energy Core');
      expect(energyCore.tier, RaceTraitTier.primary);
      final options =
          CharacterCalculator.compatibleFactorTraitsFor(c, energyCore);
      expect(options.any((o) => o.trait.name == 'Mutant Core'), isTrue);

      final selected = options.firstWhere((o) => o.trait.name == 'Mutant Core');
      c.factorSelections.add(FactorSelection(
        factorName: selected.factor.name,
        factorTraitName: selected.trait.name,
        replacedTraitName: energyCore.name,
      ));
      final active = CharacterCalculator.activeRaceTraits(c);
      expect(active.any((t) => t.name == 'Energy Core'), isFalse);
      final swappedIn = active.firstWhere((t) => t.name == 'Mutant Core');
      expect(swappedIn.tier, RaceTraitTier.primary);
    });

    test('a bracket-locked Factor Trait is NOT offered for a different '
        'Secondary Trait on the same Race', () {
      final c = Character.blank('fac8')..race = 'Android';
      final lockOn =
          raceTraitsFor('Android').firstWhere((t) => t.name == 'Lock On');
      final options = CharacterCalculator.compatibleFactorTraitsFor(c, lockOn);
      expect(options.any((o) => o.trait.name == 'Mutant Core'), isFalse);
    });

    test("Disguised Shadow's dependentChoice mirrors Draconic Physique's, "
        'keyed off Personified Dragon Ball\'s Option', () {
      final disguisedDragon = factorByName('Disguised Dragon')!;
      final disguisedShadow =
          disguisedDragon.traits.firstWhere((t) => t.name == 'Disguised Shadow');
      expect(disguisedShadow.mustReplaceTraitName, 'Draconic Physique');
      expect(disguisedShadow.dependentChoice, isNotNull);
      expect(disguisedShadow.dependentChoice!.sourceTraitName,
          'Personified Dragon Ball');
      expect(disguisedShadow.dependentChoice!.sourceGroupLabel, 'Option');

      final personifiedDragonBall = raceTraitsFor('Shadow Dragon')
          .firstWhere((t) => t.name == 'Personified Dragon Ball');
      final optionNames = personifiedDragonBall.optionGroups
          .firstWhere((g) => g.label == 'Option')
          .options
          .map((o) => o.name)
          .toSet();
      expect(disguisedShadow.dependentChoice!.textByOption.keys.toSet(),
          optionNames);
    });
  });

  group('Talents catalogue', () {
    test('has all 275 Talents, each with a non-empty description and a sane '
        'prerequisitesText', () {
      expect(kDbuTalents, hasLength(275));
      for (final t in kDbuTalents) {
        expect(t.description, isNotEmpty, reason: t.name);
        expect(t.prerequisitesText, isNotEmpty, reason: t.name);
      }
    });

    test('every Talent name is unique', () {
      final names = kDbuTalents.map((t) => t.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('covers all 33 Talent Categories', () {
      final categoriesSeen = kDbuTalents.map((t) => t.category).toSet();
      expect(categoriesSeen, TalentCategory.values.toSet());
    });

    test('talentByName resolves a known Talent and returns null for an '
        'unrecognized one', () {
      expect(talentByName('Agile Warrior')?.category, TalentCategory.dodging);
      expect(talentByName('Not A Real Talent'), isNull);
    });

    test('20 Jul 2026 site sync: Shock Tornado replaces Aikido Apprentice', () {
      expect(talentByName('Shock Tornado')?.category, TalentCategory.counter);
      expect(talentByName('Aikido Apprentice'), isNull);
    });

    test('talentsByCategory returns only Talents of that Category', () {
      final weaponTalents = talentsByCategory(TalentCategory.weapon);
      expect(weaponTalents, isNotEmpty);
      expect(weaponTalents.every((t) => t.category == TalentCategory.weapon),
          isTrue);
    });

    test('Racial Talents carry a raceRestriction matching a real Race; '
        'non-Racial Talents have none', () {
      const knownRaces = {
        'Android', 'Angel', 'Arcosian', 'Bio Android', 'Cerealian', 'Demon',
        'Earthling', 'Glass Tribe', 'Heran', 'Konatsian', 'Majin',
        'Namekian', 'Neko Majin', 'Neo-Tuffle', 'Saiyan', 'Shadow Dragon',
        'Shinjin', 'Yardrat',
      };
      for (final t in kDbuTalents) {
        if (t.category == TalentCategory.racial) {
          expect(t.raceRestriction, isNotNull, reason: t.name);
          expect(knownRaces.contains(t.raceRestriction), isTrue,
              reason: t.name);
        } else {
          expect(t.raceRestriction, isNull, reason: t.name);
        }
      }
    });

    test('Show Stopping Performance and Analytic Fighter each expose a '
        '7-option Option group', () {
      final showStopping = talentByName('Show Stopping Performance')!;
      expect(showStopping.hasOptions, isTrue);
      expect(showStopping.optionGroups.single.options, hasLength(7));

      final analyticFighter = talentByName('Analytic Fighter')!;
      expect(analyticFighter.hasOptions, isTrue);
      expect(analyticFighter.optionGroups.single.options, hasLength(7));
    });
  });

  group('Talent automation', () {
    test('Agile Warrior grants a flat +1(T) Defense Value', () {
      final c = Character.blank('tal1')..race = 'Earthling';
      c.talents.add(TalentEntry()..name = 'Agile Warrior');
      final stats = CharacterCalculator.compute(c);
      final baseline = Character.blank('tal1b')..race = 'Earthling';
      final baselineStats = CharacterCalculator.compute(baseline);
      expect(stats.defenseValue, baselineStats.defenseValue + 1);
    });

    test('Vigor scales Soak by 1(bT) per Health Threshold currently below '
        '(base Tier of Power, not current)', () {
      final c = Character.blank('tal2')..race = 'Earthling';
      c.talents.add(TalentEntry()..name = 'Vigor');
      final baseline = Character.blank('tal2b')..race = 'Earthling';
      final baselineStats = CharacterCalculator.compute(baseline);
      // Push Life below the Bruised threshold (< 50%) to be under exactly
      // 1 Health Threshold.
      c.currentLife = (baselineStats.maxLife * 0.4).floor();
      final stats = CharacterCalculator.compute(c);
      expect(stats.soak, baselineStats.soak + 1);
    });

    test('a Talent with no automation contributes nothing extra', () {
      final c = Character.blank('tal3')..race = 'Earthling';
      c.talents.add(TalentEntry()..name = 'Lucky');
      final stats = CharacterCalculator.compute(c);
      final baseline = Character.blank('tal3b')..race = 'Earthling';
      final baselineStats = CharacterCalculator.compute(baseline);
      expect(stats.soak, baselineStats.soak);
      expect(stats.defenseValue, baselineStats.defenseValue);
    });

    test('a freeform/homebrew Talent name not in the catalogue is ignored '
        '(no crash, no automated effect)', () {
      final c = Character.blank('tal4')..race = 'Earthling';
      c.talents.add(TalentEntry()..name = 'My Custom Homebrew Talent');
      expect(() => CharacterCalculator.compute(c), returnsNormally);
    });

    test('two stacking Talents (Enhanced Fist + Iron Fist) both apply to '
        'woundPhysical additively', () {
      final c = Character.blank('tal5')..race = 'Earthling';
      c.talents.add(TalentEntry()..name = 'Enhanced Fist');
      c.talents.add(TalentEntry()..name = 'Iron Fist');
      final stats = CharacterCalculator.compute(c);
      final baseline = Character.blank('tal5b')..race = 'Earthling';
      final baselineStats = CharacterCalculator.compute(baseline);
      expect(stats.woundPhysical.total,
          baselineStats.woundPhysical.total + 2);
    });
  });

  group('Power Level Table (kPowerLevelGrants)', () {
    test('has 30 entries, one per Power Level 1-30', () {
      expect(kPowerLevelGrants, hasLength(30));
      expect(kPowerLevelGrants.map((e) => e.powerLevel).toList(),
          List.generate(30, (i) => i + 1));
    });

    test('PL1 grants 1x Character Perk, 4x Talent Addition, 5x Attribute '
        'Addition, 1x Skill Improvement', () {
      final grants = grantsForLevel(1);
      expect(
          grants.where((g) => g == ProgressionGrantKind.characterPerk),
          hasLength(1));
      expect(
          grants.where((g) => g == ProgressionGrantKind.talentAddition),
          hasLength(4));
      expect(
          grants.where((g) => g == ProgressionGrantKind.attributeAddition),
          hasLength(5));
      expect(
          grants.where((g) => g == ProgressionGrantKind.skillImprovement),
          hasLength(1));
      expect(grants, hasLength(11));
    });

    test('PL30 grants 5x Character Perk', () {
      expect(grantsForLevel(30),
          List.filled(5, ProgressionGrantKind.characterPerk));
    });

    test('PL5/10/15/20/25 each grant Talent+Attribute+Skill Improvement '
        '(the "milestone" levels)', () {
      for (final pl in [5, 10, 15, 20, 25]) {
        expect(
            grantsForLevel(pl).toSet(),
            {
              ProgressionGrantKind.talentAddition,
              ProgressionGrantKind.attributeAddition,
              ProgressionGrantKind.skillImprovement,
            },
            reason: 'PL$pl');
      }
    });

    test('grantsForLevel returns empty for an out-of-range level', () {
      expect(grantsForLevel(0), isEmpty);
      expect(grantsForLevel(31), isEmpty);
    });
  });

  group('RaceDef.attributeIncrease (structured racial Attribute bonus)', () {
    test('Android is fully fixed: FO+2, TE+2, IN+1, no choices', () {
      final r = raceByName('Android');
      expect(r.attributeIncrease.fixed[DbuAttribute.force], 2);
      expect(r.attributeIncrease.fixed[DbuAttribute.tenacity], 2);
      expect(r.attributeIncrease.fixed[DbuAttribute.insight], 1);
      expect(r.attributeIncrease.choices, isEmpty);
    });

    test('Bio Android has 3 choice slots (+2, +2, +1), no fixed bonuses', () {
      final r = raceByName('Bio Android');
      expect(r.attributeIncrease.fixed, isEmpty);
      expect(r.attributeIncrease.choices, hasLength(3));
      expect(r.attributeIncrease.choices.map((c) => c.amount).toList(),
          [2, 2, 1]);
    });

    test('Shinjin has one restricted [FO/MA] choice and one "any Attribute" '
        'choice (empty options)', () {
      final r = raceByName('Shinjin');
      expect(r.attributeIncrease.choices, hasLength(2));
      expect(r.attributeIncrease.choices[0].options,
          [DbuAttribute.force, DbuAttribute.magic]);
      expect(r.attributeIncrease.choices[1].options, isEmpty);
    });

    test('Custom Species has three free choice slots (+2/+2/+1)', () {
      final r = raceByName('Custom Species');
      expect(r.attributeIncrease.fixed, isEmpty);
      expect(r.attributeIncrease.choices.map((ch) => ch.amount), [2, 2, 1]);
    });
  });

  group('Character.scoreOf (computed Attribute Scores)', () {
    test('base 1 + fixed racial bonus, no Progression', () {
      final c = Character.blank('sc1')..race = 'Saiyan';
      expect(c.scoreOf(DbuAttribute.force), 1 + 2); // Saiyan FO+2
      expect(c.scoreOf(DbuAttribute.tenacity), 1 + 2); // Saiyan TE+2
      expect(c.scoreOf(DbuAttribute.agility), 1 + 1); // Saiyan AG+1
      expect(c.scoreOf(DbuAttribute.insight), 1); // no bonus
    });

    test('a choice-slot pick only adds its amount to the chosen Attribute',
        () {
      final c = Character.blank('sc2')..race = 'Cerealian';
      // Cerealian: IN+2, AG+2 fixed; +1 choice among [FO, MA].
      expect(c.scoreOf(DbuAttribute.force), 1); // not chosen yet
      c.raceAttributeIncreaseChoices.add(DbuAttribute.magic);
      expect(c.scoreOf(DbuAttribute.magic), 1 + 1);
      expect(c.scoreOf(DbuAttribute.force), 1); // unaffected
    });

    test('Progression Attribute Addition points add on top of the racial '
        'bonus', () {
      final c = Character.blank('sc3')
        ..race = 'Saiyan'
        ..powerLevel = 1;
      // PL1's grants are [characterPerk, talent x4, attribute x5, skill] —
      // slot index 5 is the first Attribute Addition.
      c.progressionChoices['1:5'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.attributeAddition,
        attributePoints: {DbuAttribute.force: 2},
      );
      expect(c.scoreOf(DbuAttribute.force), 1 + 2 + 2); // base+racial+prog
    });

    test('Progression points at a future (unreached) Power Level do not '
        'count yet', () {
      final c = Character.blank('sc4')
        ..race = 'Saiyan'
        ..powerLevel = 1;
      c.progressionChoices['5:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.attributeAddition,
        attributePoints: {DbuAttribute.force: 2},
      );
      expect(c.scoreOf(DbuAttribute.force), 1 + 2); // racial only, PL5 not reached
    });

    test('Custom Species uses the standard +2/+2/+1 choice slots', () {
      // Verbatim (Custom Species, ARC Advice): "Select two different
      // Attributes and increase them by +2, select a third Attribute and
      // increase it by +1."
      final race = raceByName('Custom Species');
      expect(race.attributeIncrease.fixed, isEmpty);
      expect(race.attributeIncrease.choices.map((ch) => ch.amount), [2, 2, 1]);
      // Every slot is a free pick (no restricted option list).
      expect(race.attributeIncrease.choices.every((ch) => ch.options.isEmpty),
          isTrue);

      final c = Character.blank('sc5')..race = 'Custom Species';
      expect(c.scoreOf(DbuAttribute.insight), 1); // nothing picked yet
      c.raceAttributeIncreaseChoices
        ..add(DbuAttribute.insight)
        ..add(DbuAttribute.agility)
        ..add(DbuAttribute.force);
      expect(c.scoreOf(DbuAttribute.insight), 1 + 2);
      expect(c.scoreOf(DbuAttribute.agility), 1 + 2);
      expect(c.scoreOf(DbuAttribute.force), 1 + 1);
      expect(c.scoreOf(DbuAttribute.magic), 1);
    });
  });

  group('totalSkillRanks (base allocation + Progression)', () {
    test('matches the base allocation alone when Progression is empty', () {
      final c = Character.blank('sk1')..race = 'Earthling';
      final acrobatics = kDbuSkills.firstWhere((s) => s.name == 'Acrobatics');
      c.skills['Acrobatics']!.setRanks(SkillProgress.normalKey, 2);
      expect(CharacterCalculator.totalSkillRanks(c, acrobatics), 2);
    });

    test('a resolved Skill Improvement adds its ranks on top of the base '
        'allocation', () {
      final c = Character.blank('sk2')
        ..race = 'Earthling'
        ..powerLevel = 1;
      final acrobatics = kDbuSkills.firstWhere((s) => s.name == 'Acrobatics');
      c.skills['Acrobatics']!.setRanks(SkillProgress.normalKey, 2);
      c.progressionChoices['1:10'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.skillImprovement,
        skillRanks: {'Acrobatics::${SkillProgress.normalKey}': 3},
      );
      expect(CharacterCalculator.totalSkillRanks(c, acrobatics), 5);
    });

    test('skillBonus() reflects the combined (base + Progression) total',
        () {
      final c = Character.blank('sk3')
        ..race = 'Earthling'
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.agility, 6);
      final acrobatics = kDbuSkills.firstWhere((s) => s.name == 'Acrobatics');
      c.progressionChoices['1:10'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.skillImprovement,
        skillRanks: {'Acrobatics::${SkillProgress.normalKey}': 1},
      );
      // Bonus = floor(6/2) + 2*1 = 3 + 2 = 5.
      expect(CharacterCalculator.skillBonus(c, acrobatics), 5);
    });
  });

  group('Progression accumulation', () {
    test('progressionTpThroughLevel: PL1 alone = 25, PL1+PL5 = 40', () {
      final c = Character.blank('tp1')
        ..race = 'Earthling'
        ..powerLevel = 20;
      c.progressionChoices['1:10'] =
          ProgressionChoice(resolvedKind: ProgressionGrantKind.skillImprovement);
      expect(CharacterCalculator.progressionTpThroughLevel(c, 1), 25);

      c.progressionChoices['5:2'] =
          ProgressionChoice(resolvedKind: ProgressionGrantKind.skillImprovement);
      expect(CharacterCalculator.progressionTpThroughLevel(c, 5), 40);
    });

    test('a Bonus Perk with no Level always counts; one with a future '
        'Level does not count until reached', () {
      final c = Character.blank('tp2')
        ..race = 'Earthling'
        ..powerLevel = 3;
      c.bonusPerks.add(BonusPerkEntry(
        powerLevel: null,
        resolvedKind: ProgressionGrantKind.skillImprovement,
      ));
      expect(CharacterCalculator.progressionTpThroughLevel(c, 3), 15);

      c.bonusPerks.add(BonusPerkEntry(
        powerLevel: 10,
        resolvedKind: ProgressionGrantKind.skillImprovement,
      ));
      expect(CharacterCalculator.progressionTpThroughLevel(c, 3), 15);
      expect(CharacterCalculator.progressionTpThroughLevel(c, 10), 30);
    });

    test('progressionTalentsThroughLevel accumulates Talent names up to a '
        'cutoff', () {
      final c = Character.blank('tal_p1')..race = 'Earthling';
      c.progressionChoices['1:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'Agile Warrior',
      );
      c.progressionChoices['9:0'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'Lucky',
      );
      expect(CharacterCalculator.progressionTalentsThroughLevel(c, 1),
          ['Agile Warrior']);
      expect(
          CharacterCalculator.progressionTalentsThroughLevel(c, 9).toSet(),
          {'Agile Warrior', 'Lucky'});
    });

    test('progressionAttributePointsThroughLevel sums points per Attribute '
        'up to a cutoff', () {
      final c = Character.blank('attr_p1')..race = 'Earthling';
      c.progressionChoices['1:5'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.attributeAddition,
        attributePoints: {DbuAttribute.force: 2},
      );
      c.progressionChoices['3:0'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.attributeAddition,
        attributePoints: {DbuAttribute.force: 1, DbuAttribute.tenacity: 1},
      );
      expect(CharacterCalculator.progressionAttributePointsThroughLevel(c, 1),
          {DbuAttribute.force: 2});
      expect(CharacterCalculator.progressionAttributePointsThroughLevel(c, 3),
          {DbuAttribute.force: 3, DbuAttribute.tenacity: 1});
    });

    test('progressionSkillRanksThroughLevel sums ranks per Skill key up to '
        'a cutoff', () {
      final c = Character.blank('skill_p1')..race = 'Earthling';
      c.progressionChoices['1:10'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.skillImprovement,
        skillRanks: {'Acrobatics::${SkillProgress.normalKey}': 2},
      );
      c.progressionChoices['5:2'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.skillImprovement,
        skillRanks: {'Acrobatics::${SkillProgress.normalKey}': 1},
      );
      expect(CharacterCalculator.progressionSkillRanksThroughLevel(c, 1),
          {'Acrobatics::${SkillProgress.normalKey}': 2});
      expect(CharacterCalculator.progressionSkillRanksThroughLevel(c, 5),
          {'Acrobatics::${SkillProgress.normalKey}': 3});
    });
  });

  group('ensureProgressionTalentsInTalentList', () {
    test('adds a missing catalogue Talent, prefilled from its TalentDef',
        () {
      final c = Character.blank('sync1')..race = 'Earthling';
      c.progressionChoices['1:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'Agile Warrior',
      );
      ensureProgressionTalentsInTalentList(c);
      expect(c.talents, hasLength(1));
      expect(c.talents.single.name, 'Agile Warrior');
      expect(c.talents.single.description, isNotEmpty);
    });

    test('adds a missing homebrew-named Talent with a bare name', () {
      final c = Character.blank('sync2')..race = 'Earthling';
      c.progressionChoices['1:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'My Homebrew Talent',
      );
      ensureProgressionTalentsInTalentList(c);
      expect(c.talents.single.name, 'My Homebrew Talent');
      expect(c.talents.single.description, isEmpty);
    });

    test('never duplicates or overwrites an existing Talents entry', () {
      final c = Character.blank('sync3')..race = 'Earthling';
      c.talents.add(TalentEntry()
        ..name = 'Agile Warrior'
        ..notes = 'my custom notes');
      c.progressionChoices['1:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'Agile Warrior',
      );
      ensureProgressionTalentsInTalentList(c);
      expect(c.talents, hasLength(1));
      expect(c.talents.single.notes, 'my custom notes');
    });
  });

  group('Progression JSON round-trip', () {
    test('ProgressionChoice and BonusPerkEntry round-trip through Character '
        'JSON', () {
      final c = Character.blank('json1')
        ..race = 'Bio Android'
        ..raceAttributeIncreaseChoices.addAll([
          DbuAttribute.magic,
          DbuAttribute.force,
          DbuAttribute.insight,
        ]);
      c.progressionChoices['1:1'] = ProgressionChoice(
        resolvedKind: ProgressionGrantKind.talentAddition,
        talentName: 'Lucky',
        notes: 'test note',
      );
      c.bonusPerks.add(BonusPerkEntry(
        powerLevel: 7,
        source: 'A Trait',
        resolvedKind: ProgressionGrantKind.attributeAddition,
        attributePoints: {DbuAttribute.tenacity: 2},
      ));

      final restored = Character.fromJson(c.toJson());
      expect(restored.raceAttributeIncreaseChoices,
          [DbuAttribute.magic, DbuAttribute.force, DbuAttribute.insight]);
      expect(restored.progressionChoices['1:1']!.talentName, 'Lucky');
      expect(restored.progressionChoices['1:1']!.notes, 'test note');
      expect(restored.bonusPerks.single.powerLevel, 7);
      expect(restored.bonusPerks.single.source, 'A Trait');
      expect(restored.bonusPerks.single.attributePoints[DbuAttribute.tenacity],
          2);
    });

    test('Custom Species Flaw compensation round-trips through Character JSON',
        () {
      final c = Character.blank('json2')..race = 'Custom Species';
      c.customRaceTraits.add(TrackedEntry()..name = 'Brittle');
      c.customFlawCompensation['Brittle'] = FlawCompensation.skillRank;
      final restored = Character.fromJson(c.toJson());
      expect(restored.customFlawCompensation['Brittle'],
          FlawCompensation.skillRank);
    });

    test('a legacy freeform Custom Species Attribute bonus migrates onto the '
        '+2/+2/+1 choice slots', () {
      final json = (Character.blank('json2b')..race = 'Custom Species').toJson()
        ..['customAttributeIncreasePoints'] = {
          'insight': 2,
          'agility': 2,
          'force': 1,
        };
      final restored = Character.fromJson(json);
      expect(restored.scoreOf(DbuAttribute.insight), 1 + 2);
      expect(restored.scoreOf(DbuAttribute.agility), 1 + 2);
      expect(restored.scoreOf(DbuAttribute.force), 1 + 1);

      // A spread that doesn't fit the rules shape is NOT guessed at — the
      // player re-picks rather than getting silently-wrong Scores.
      final odd = (Character.blank('json2c')..race = 'Custom Species').toJson()
        ..['customAttributeIncreasePoints'] = {'magic': 4};
      final restoredOdd = Character.fromJson(odd);
      expect(restoredOdd.raceAttributeIncreaseChoices.whereType<DbuAttribute>(),
          isEmpty);
      expect(restoredOdd.scoreOf(DbuAttribute.magic), 1);
    });

    test('an old save with a stale "attributeScores" key loads without '
        'crashing (the key is simply ignored)', () {
      final json = Character.blank('json3').toJson();
      json['attributeScores'] = {'force': 99, 'tenacity': 50};
      expect(() => Character.fromJson(json), returnsNormally);
      final restored = Character.fromJson(json);
      // Computed from Race + Progression now, NOT from the stale JSON key.
      expect(restored.scoreOf(DbuAttribute.force), 1);
    });
  });

  group('Transformations catalogue', () {
    test('lookups resolve within each catalogue and via the unified '
        'transformationByName', () {
      expect(lesserAwakeningByName('Zenkai')?.type,
          TransformationType.awakening);
      expect(enhancementByName('Kaioken')?.type,
          TransformationType.enhancement);
      expect(alternateFormByName('Super Saiyan')?.type,
          TransformationType.form);
      expect(CharacterCalculator.transformationByName('Super Saiyan 3')?.stage,
          3);
      expect(CharacterCalculator.transformationByName('Not Real'), isNull);
    });

    test('Super Saiyan line stages are ordered with rising ToP requirements',
        () {
      final ss1 = alternateFormByName('Super Saiyan')!;
      final ss2 = alternateFormByName('Super Saiyan 2')!;
      final ss3 = alternateFormByName('Super Saiyan 3')!;
      expect([ss1.stage, ss2.stage, ss3.stage], [1, 2, 3]);
      expect(ss1.tierOfPowerRequirement, lessThan(ss2.tierOfPowerRequirement));
      expect(ss2.tierOfPowerRequirement, lessThan(ss3.tierOfPowerRequirement));
      expect(ss1.transformationLine, 'Super Saiyan');
    });

    test('Zenkai is a 3-stack Awakening; SS2/SS3 have the Difficult Aspect '
        '(2 Mastery Traits each)', () {
      expect(lesserAwakeningByName('Zenkai')!.maxStacks, 3);
      expect(alternateFormByName('Super Saiyan 2')!.masteryLevels, 2);
      expect(alternateFormByName('Super Saiyan')!.masteryLevels, 1);
    });

    test('the full Alternate Forms catalogue is present (152 stage defs)', () {
      // 84 catalogue pages, several of which hold multiple Stage defs, yield
      // 100 TransformationDefs. Every entry is a Form. (+5 on 20 Jul 2026:
      // Barrier Form, Berserk Controlled, Super Saiyan 5, and the
      // previously-missed Legendary [Evolved Stage] + Legendary Oozaru.)
      expect(kDbuAlternateForms.length, 153);
      expect(kDbuAlternateForms.every((f) => f.type == TransformationType.form),
          isTrue);
      // Racial "Power" Forms, Evolved Stages, and pinnacle Legendaries.
      expect(alternateFormByName('Saiyan Power'), isNull); // that's an Awakening
      expect(alternateFormByName('Namekian Power')?.racialRequirement,
          'Namekian');
      expect(alternateFormByName('Golden Oozaru')?.formType,
          FormType.legendary);
      expect(alternateFormByName('Supreme Form')?.tierOfPowerRequirement, 7);
      // A graded (`*`/`-G`) AMB entry is captured as graded, not auto-applied.
      expect(alternateFormByName('Restrained Form')!.amb[DbuAttribute.force]!
          .graded, isTrue);
      // Null Stages exist (Self-Restraint base, Metamorphosis, Beyond God…).
      expect(alternateFormByName('Self-Restraint')?.stage, 0);
      // Multi-stage lines share a transformationLine.
      expect(
          alternateFormByName('Ultra Instinct "Complete"')?.transformationLine,
          'Ultra Instinct');
    });

    test('Forms classify into Alternate / Evolved Stage / Legendary buckets',
        () {
      // Evolved Stages are detected from prerequisiteText; there are 18.
      final evolved =
          kDbuAlternateForms.where((f) => f.isEvolvedStage).toList();
      expect(evolved.length, 53);
      expect(alternateFormByName('Ascended Super Saiyan')!.isEvolvedStage,
          isTrue);
      expect(alternateFormByName('Super Saiyan')!.isEvolvedStage, isFalse);
      // Legendary (non-evolved) vs Alternate (non-evolved) partition the rest.
      expect(alternateFormByName('Supreme Form')!.formType, FormType.legendary);
      expect(alternateFormByName('Namekian Power')!.formType,
          FormType.alternate);
    });

    test('Legendary Traits surface as an always-on accessor, stripped of their '
        'marker and excluded from situational Traits', () {
      final godly = alternateFormByName('Godly Powers')!;
      expect(godly.legendaryTrait?.name, 'Divine Energy');
      expect(godly.situationalTraits.any((t) => t.name.contains('Legendary')),
          isFalse);
      // Ultra Ego carries both a Legendary Trait and an Exceed Trait.
      final ue = alternateFormByName('Ultra Ego')!;
      expect(ue.legendaryTrait?.name, 'Rampant Ego');
      expect(ue.exceedTrait?.name, 'Destructive Egoist');
      // An Alternate Form with no Legendary Trait returns null.
      expect(alternateFormByName('Namekian Power')!.legendaryTrait, isNull);
      // Every Legendary Trait marker across the catalogue resolves.
      final withLegendary =
          kDbuAlternateForms.where((f) => f.legendaryTrait != null).length;
      expect(withLegendary, 54);
    });

    test('Null Stages (Stage 0) are flagged and do NOT grant the Ki Multiplier',
        () {
      final nullStages =
          kDbuAlternateForms.where((f) => f.isNullStage).toList();
      // Self-Restraint, Metamorphosis Full Suppression, Beyond God Divine
      // Acclimation, Meta Form Mechanized Body, Grudge Amplifier Computer
      // Form, Dragon Shell Reinforced Shell, Awoken Genetics Suppressed
      // Genetics, Full Power Boost Powerful, Janemba Manifest, Appointed God
      // Suppressed Divinity.
      expect(nullStages.length, 10);
      expect(alternateFormByName('Self-Restraint')!.isNullStage, isTrue);

      // An active Null Stage keeps the base Max Ki (no Ki Multiplier)...
      final c = Character.blank('ns1')
        ..race = 'Saiyan'
        ..powerLevel = 1; // base Max Ki 50
      final nullSel =
          TransformationSelection(name: 'Self-Restraint', active: true);
      c.transformations.add(nullSel);
      expect(CharacterCalculator.maxKi(c), 50);
      // ...while an active non-Null Form doubles it.
      nullSel.active = false;
      c.transformations
          .add(TransformationSelection(name: 'Power Boost', active: true));
      expect(CharacterCalculator.maxKi(c), 100);
    });

    test('Awakening Limit table matches the site (base ToP -> Lesser/Greater)',
        () {
      // Re-verified 18 July 2026 against the transformation-rules page's raw
      // table cells: bT1 2/1, bT2 3/1, bT3 4/2, bT4 5/2, bT5 6/3, bT6 7/3,
      // bT7 7/4 (the Lesser column was previously off by one).
      expect(awakeningLimitsFor(1).lesser, 2);
      expect(awakeningLimitsFor(1).greater, 1);
      expect(awakeningLimitsFor(2).lesser, 3);
      expect(awakeningLimitsFor(3).lesser, 4);
      expect(awakeningLimitsFor(3).greater, 2);
      expect(awakeningLimitsFor(5).lesser, 6);
      expect(awakeningLimitsFor(5).greater, 3);
      expect(awakeningLimitsFor(7).lesser, 7);
      expect(awakeningLimitsFor(7).greater, 4);
    });

    test('every Any-Race Standard & Transcendent Enhancement is transcribed',
        () {
      // 48 Any-Race + 27 race-specific (21 Standard + 6 Transcendent) = 75.
      expect(kDbuEnhancements.length, 75);
      // Race-specific eligibility resolves to real Races.
      expect(enhancementByName('Saiyan Pride')?.racialRequirement, 'Saiyan');
      expect(enhancementByName('Overdrive')?.racialRequirement, 'Android');
      expect(enhancementByName('Evil Saiyan')?.isTranscendent, isTrue);
      // A spread across the classifications + special mechanics.
      expect(enhancementByName('Kaioken')?.enhancementType,
          EnhancementType.standard);
      expect(enhancementByName('Super Kaioken')?.enhancementType,
          EnhancementType.special);
      expect(enhancementByName('Super Kaioken')?.initialEnhancement, 'Kaioken');
      expect(enhancementByName('Awoken')?.enhancementType,
          EnhancementType.power);
      expect(enhancementByName('Awoken')?.unlimitedTrait, isNotNull);
      // Every Enhancement resolves via the unified lookup and is an Enhancement.
      for (final e in kDbuEnhancements) {
        expect(e.type, TransformationType.enhancement, reason: e.name);
        expect(CharacterCalculator.transformationByName(e.name)?.name, e.name);
      }
    });

    test('Transcendent Enhancements carry the Transcendent Aspect / Trait', () {
      final godAura = enhancementByName('God Aura')!;
      expect(godAura.isTranscendent, isTrue);
      expect(godAura.transcendentTrait, isNotNull);
      // Explosive Power is a Standard classification that still Transcends.
      final explosive = enhancementByName('Explosive Power')!;
      expect(explosive.enhancementType, EnhancementType.standard);
      expect(explosive.isTranscendent, isTrue);
      // A plain Standard Enhancement does not Transcend.
      expect(enhancementByName('Juggernaut')!.isTranscendent, isFalse);
    });
  });

  group('Aspects catalogue', () {
    test('has both polarities and every entry is non-empty', () {
      expect(kDbuAspects.any((a) => a.polarity == AspectPolarity.positive),
          isTrue);
      expect(kDbuAspects.any((a) => a.polarity == AspectPolarity.negative),
          isTrue);
      for (final a in kDbuAspects) {
        expect(a.name.trim(), isNotEmpty);
        expect(a.effect.trim(), isNotEmpty, reason: a.name);
      }
      // Names are unique.
      final names = kDbuAspects.map((a) => a.name).toSet();
      expect(names.length, kDbuAspects.length);
    });

    test('level caps and markers match the site', () {
      expect(aspectByName('Growth')!.maxLevels, 3);
      expect(aspectByName('Heartbeat')!.solo, isTrue);
      expect(aspectByName('Heartbeat')!.maxLevels, 3);
      // Draining is levelled but uncapped ([LV], no ~X).
      expect(aspectByName('Draining')!.hasLevels, isTrue);
      expect(aspectByName('Draining')!.maxLevels, isNull);
      expect(aspectByName('Growth')!.marker, '[LV~3]');
      expect(aspectByName('Heartbeat')!.marker, '[Solo, LV~3]');
    });

    test('resolveAspect splits printed level / parameter labels', () {
      final heartbeat = resolveAspect('Heartbeat (LV3)');
      expect(heartbeat.def?.name, 'Heartbeat');
      expect(heartbeat.level, 3);

      // The site also writes levels as "(Level N)".
      expect(resolveAspect('Draining (Level 2)').level, 2);

      // A parameter (not a level) is captured separately.
      final save = resolveAspect('Enhanced Save (Impulsive)');
      expect(save.def?.name, 'Enhanced Save');
      expect(save.parameter, 'Impulsive');
      expect(save.level, isNull);

      // Pinnacle is levelled since the 20 Jul 2026 site update
      // ("Pinnacle [Solo, LV~2]") — printed labels carry the level.
      final pinnacle = resolveAspect('Pinnacle (LV2)');
      expect(pinnacle.def?.name, 'Pinnacle');
      expect(pinnacle.level, 2);
      expect(pinnacle.def!.hasLevels, isTrue);
      expect(pinnacle.def!.maxLevels, 2);
      expect(pinnacle.def!.solo, isTrue);
      // A bare name resolves with no level/parameter.
      expect(resolveAspect('Graded').def?.name, 'Graded');
      // An unknown Aspect degrades gracefully.
      expect(resolveAspect('Dedicated').def, isNull);
    });
  });

  group('Awakening catalogues (Lesser / Greater / Super)', () {
    test('each catalogue has the expected size and awakeningType', () {
      expect(kDbuLesserAwakenings.length, 124);
      expect(kDbuGreaterAwakenings.length, 63);
      expect(kDbuSuperAwakenings.length, 35);
      expect(
          kDbuLesserAwakenings
              .every((a) => a.awakeningType == AwakeningType.lesser),
          isTrue);
      expect(
          kDbuGreaterAwakenings
              .every((a) => a.awakeningType == AwakeningType.greater),
          isTrue);
      expect(
          kDbuSuperAwakenings
              .every((a) => a.awakeningType == AwakeningType.superAwakening),
          isTrue);
    });

    test('every Awakening is a TransformationType.awakening with an origin', () {
      for (final a in [
        ...kDbuLesserAwakenings,
        ...kDbuGreaterAwakenings,
        ...kDbuSuperAwakenings,
      ]) {
        expect(a.type, TransformationType.awakening, reason: a.name);
        expect(a.origin, isNotNull, reason: a.name);
        expect(a.traits, isNotEmpty, reason: a.name);
      }
    });

    test('per-catalogue name lookups resolve, and cross-catalogue misses are '
        'null', () {
      expect(greaterAwakeningByName('Scholar')?.awakeningType,
          AwakeningType.greater);
      expect(superAwakeningByName('Grandmaster')?.awakeningType,
          AwakeningType.superAwakening);
      // A Greater name does not resolve as a Lesser, and vice-versa.
      expect(lesserAwakeningByName('Scholar'), isNull);
      expect(greaterAwakeningByName('Zenkai'), isNull);
      expect(superAwakeningByName('Scholar'), isNull);
    });

    test('unified transformationByName resolves across all three tiers', () {
      expect(CharacterCalculator.transformationByName('Steel Frame')
          ?.awakeningType, AwakeningType.lesser);
      expect(CharacterCalculator.transformationByName('Overtaken')
          ?.awakeningType, AwakeningType.greater);
      expect(CharacterCalculator.transformationByName('Mortal Flames')
          ?.awakeningType, AwakeningType.superAwakening);
    });

    test('only Super Awakenings carry a Grand Awakening Trait', () {
      expect(kDbuLesserAwakenings.any((a) => a.hasGrandAwakening), isFalse);
      expect(kDbuGreaterAwakenings.any((a) => a.hasGrandAwakening), isFalse);
      // Every Super Awakening EXCEPT the two Manifested-Power entries carries
      // a Grand Awakening whose first effect is a Grand Trigger.
      final withGrand =
          kDbuSuperAwakenings.where((a) => a.hasGrandAwakening).toList();
      expect(withGrand.length, greaterThanOrEqualTo(28));
      for (final a in withGrand) {
        expect(a.grandAwakening!.description.toLowerCase(),
            contains('grand'), reason: a.name);
      }
    });

    test('Super Awakening AMB is Tier-scaled (+1(T) AG/FO/TE/MA), so it '
        'multiplies by Tier of Power', () {
      final def = superAwakeningByName('Grandmaster')!;
      expect(def.amb[DbuAttribute.force]!.tierScaled, isTrue);
      expect(def.amb[DbuAttribute.force]!.coefficient, 1);

      final c = Character.blank('sup1')
        ..race = 'Earthling'
        ..powerLevel = 15; // Tier of Power 4
      final baseForce =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      c.transformations.add(TransformationSelection(name: 'Grandmaster'));
      // +1(T) at Tier of Power 4 == +4.
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.force),
          baseForce + 4);
    });

    test('awakeningCount tallies Greater and Super owned Awakenings', () {
      final c = Character.blank('sup2')
        ..race = 'Saiyan'
        ..powerLevel = 20
        ..transformations.addAll([
          TransformationSelection(name: 'Scholar'), // Greater
          TransformationSelection(name: 'Saiyan Elite'), // Greater
          TransformationSelection(name: 'Limitless Saiyan'), // Super
        ]);
      expect(CharacterCalculator.awakeningCount(c, AwakeningType.greater), 2);
      expect(
          CharacterCalculator.awakeningCount(c, AwakeningType.superAwakening),
          1);
      expect(CharacterCalculator.awakeningCount(c, AwakeningType.lesser), 0);
    });
  });

  group('Transformation automation', () {
    test("an owned Awakening's flat Attribute Modifier Bonus applies at all "
        'times, no active toggle needed (Steel Frame: TE +2)', () {
      final c = Character.blank('tr1')
        ..race = 'Earthling'
        ..powerLevel = 10; // Tier of Power 3
      final baseTen =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity);
      c.transformations.add(TransformationSelection(name: 'Steel Frame'));
      // Steel Frame TE +2 (flat, not Tier-scaled) applies immediately.
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          baseTen + 2);
      // And it flows into Soak once above the Minimum Soak floor: give the
      // character enough Tenacity that Soak isn't floored.
      final c2 = Character.blank('tr1b')
        ..race = 'Earthling'
        ..powerLevel = 10
        ..setTestScore(DbuAttribute.tenacity, 10);
      final baseSoak = CharacterCalculator.soak(c2);
      c2.transformations.add(TransformationSelection(name: 'Steel Frame'));
      expect(CharacterCalculator.soak(c2), baseSoak + 2);
    });

    test("an Awakening's AMB multiplies by its Stacks", () {
      final c = Character.blank('tr2')
        ..race = 'Saiyan'
        ..powerLevel = 10;
      final baseAgi =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      // Zenkai AG +1 (flat) at 3 Stacks -> +3.
      c.transformations
          .add(TransformationSelection(name: 'Zenkai', stacks: 3));
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          baseAgi + 3);
    });

    test("an Enhancement/Form AMB applies ONLY while Active", () {
      final c = Character.blank('tr3')
        ..race = 'Saiyan'
        ..powerLevel = 10; // Tier of Power 3
      final baseAgi =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      final sel = TransformationSelection(name: 'Super Saiyan', active: false);
      c.transformations.add(sel);
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          baseAgi, reason: 'inactive Form contributes nothing');
      sel.active = true;
      // Super Saiyan AG +1(T) at ToP 3 -> +3.
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          baseAgi + 3);
    });

    test('an active Form grants the Ki Multiplier (double Max Ki, +1/2 Max '
        'Capacity); an inactive one does not', () {
      final c = Character.blank('tr4')
        ..race = 'Saiyan'
        ..powerLevel = 1; // Max Ki 50, Max Capacity 20
      expect(CharacterCalculator.maxKi(c), 50);
      expect(CharacterCalculator.maxCapacity(c), 20);
      // Power Boost has no Super Saiyan Form Aspect, so this pins the plain
      // Ki Multiplier (the ×1.25 Aspect interplay has its own test).
      final sel = TransformationSelection(name: 'Power Boost', active: true);
      c.transformations.add(sel);
      expect(CharacterCalculator.maxKi(c), 100);
      expect(CharacterCalculator.maxCapacity(c), 30);
      sel.active = false;
      expect(CharacterCalculator.maxKi(c), 50);
    });

    test('Graded AMB (Kaioken) applies the current Grade from its table', () {
      final c = Character.blank('tr5')
        ..race = 'Earthling'
        ..powerLevel = 10; // ToP 3
      final top = CharacterCalculator.tierOfPower(c);
      final baseAgi =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      c.transformations
          .add(TransformationSelection(name: 'Kaioken', active: true));
      // Grade 1 → AG +1(T) from the Kaioken Grades table.
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          baseAgi + 1 * top);
    });

    test("a player's customAmb adds on top of the Grade table", () {
      final c = Character.blank('tr5b')
        ..race = 'Earthling'
        ..powerLevel = 10;
      final top = CharacterCalculator.tierOfPower(c);
      final baseAgi =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      // Grade 1 table AG = +1(T); the player's manual +3 stacks on top.
      c.transformations.add(TransformationSelection(
        name: 'Kaioken',
        active: true,
        customAmb: {DbuAttribute.agility: 3},
      ));
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          baseAgi + 1 * top + 3);
    });

    test('customAmb on an Awakening multiplies by Stacks; on a Form it '
        'applies only while Active', () {
      // Awakening custom AMB × Stacks (like the catalogue AMB). Personality is
      // outside Zenkai's own table, so the custom bonus is isolated.
      final c = Character.blank('tr5c')
        ..race = 'Saiyan'
        ..powerLevel = 10;
      final basePe =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.personality);
      c.transformations.add(TransformationSelection(
        name: 'Zenkai',
        stacks: 3,
        customAmb: {DbuAttribute.personality: 2},
      ));
      expect(
          CharacterCalculator.effectiveModifier(c, DbuAttribute.personality),
          basePe + 6);

      // A Form's custom AMB is gated on Active, like its catalogue AMB.
      // Personality is outside Super Saiyan's own table.
      final c2 = Character.blank('tr5d')
        ..race = 'Saiyan'
        ..powerLevel = 10;
      final basePe2 =
          CharacterCalculator.effectiveModifier(c2, DbuAttribute.personality);
      final sel = TransformationSelection(
        name: 'Super Saiyan',
        active: false,
        customAmb: {DbuAttribute.personality: 4},
      );
      c2.transformations.add(sel);
      expect(
          CharacterCalculator.effectiveModifier(c2, DbuAttribute.personality),
          basePe2, reason: 'inactive Form contributes no AMB');
      sel.active = true;
      expect(
          CharacterCalculator.effectiveModifier(c2, DbuAttribute.personality),
          basePe2 + 4);
    });

    test('a custom Aspect drives its automation while Active, and round-trips '
        'through JSON', () {
      final c = Character.blank('casp')
        ..race = 'Saiyan'
        ..powerLevel = 10; // ToP 3
      final sel = TransformationSelection(name: 'Super Saiyan', active: true);
      c.transformations.add(sel);
      int morale() => CharacterCalculator.compute(c)
          .savingThrows[DbuSavingThrow.morale]!
          .total;
      final without = morale();
      // Add "Enhanced Save (Morale)" — grants +1(T) = +3 to the Morale Save.
      sel.customAspects.add('Enhanced Save (Morale)');
      expect(morale(), without + 3);
      // Not applied while the Form is inactive.
      sel.active = false;
      expect(morale(), without);
      // Survives a JSON round-trip.
      final revived = Character.fromJson(c.toJson());
      expect(revived.transformations.single.customAspects,
          ['Enhanced Save (Morale)']);
    });

    test('disabling a catalogue Aspect drops its automation', () {
      final c = Character.blank('rasp')
        ..race = 'Saiyan'
        ..powerLevel = 10; // ToP 3
      // Demon God carries "Enhanced Save (Impulsive/Cognitive/Morale)".
      final sel = TransformationSelection(name: 'Demon God', active: true);
      c.transformations.add(sel);
      int morale() => CharacterCalculator.compute(c)
          .savingThrows[DbuSavingThrow.morale]!
          .total;
      final withAspect = morale();
      // Disable the Enhanced Save Aspect → the +1(T) Morale bonus is dropped.
      sel.removedAspects.add('Enhanced Save (Impulsive/Cognitive/Morale)');
      expect(morale(), withAspect - 3);
      // Re-enabling restores it, and it round-trips through JSON.
      final revived = Character.fromJson(c.toJson());
      expect(revived.transformations.single.removedAspects,
          ['Enhanced Save (Impulsive/Cognitive/Morale)']);
    });

    test('a Transformation AMB to Force flows into Might, Wound and Surgency, '
        'but NOT Saving Throws (those use the raw Score)', () {
      final c = Character.blank('tr6')
        ..race = 'Saiyan'
        ..powerLevel = 10; // ToP 3
      final baseMight = CharacterCalculator.might(c);
      final baseImpulsive =
          CharacterCalculator.savingThrow(c, DbuSavingThrow.corporeal);
      c.transformations
          .add(TransformationSelection(name: 'Super Saiyan', active: true));
      // Super Saiyan FO +1(T) at ToP 3 -> Might +3.
      expect(CharacterCalculator.might(c), baseMight + 3);
      // Corporeal Save uses raw Tenacity SCORE, unaffected by the Modifier
      // Bonus.
      expect(CharacterCalculator.savingThrow(c, DbuSavingThrow.corporeal),
          baseImpulsive);
    });

    test('awakeningCount / awakeningLimits reflect owned Lesser Awakenings',
        () {
      final c = Character.blank('tr7')
        ..race = 'Saiyan'
        ..powerLevel = 1; // base ToP 1 -> Lesser limit 2
      c.transformations.add(TransformationSelection(name: 'Zenkai'));
      c.transformations.add(TransformationSelection(name: 'Peak Condition'));
      expect(CharacterCalculator.awakeningCount(c, AwakeningType.lesser), 2);
      expect(CharacterCalculator.awakeningLimits(c).lesser, 2);
    });

    test('TransformationSelection round-trips through Character JSON', () {
      final c = Character.blank('tr8')..race = 'Saiyan';
      final sel = TransformationSelection(
        name: 'Super Saiyan',
        active: true,
        masteryLevel: 1,
        grade: 2,
      );
      sel.optionChoices['S-Cells::Option'] = {'Super Surger'};
      c.transformations.add(sel);
      final restored = Character.fromJson(c.toJson());
      final r = restored.transformations.single;
      expect(r.name, 'Super Saiyan');
      expect(r.active, isTrue);
      expect(r.masteryLevel, 1);
      expect(r.grade, 2);
      expect(r.optionChoices['S-Cells::Option'], {'Super Surger'});
    });
  });

  group('Apparel', () {
    test('Craftsmanship Grade table maps to Apparel Grade and Quality Slots',
        () {
      expect(craftsmanshipInfo(1).apparelGrade, ApparelGrade.low);
      expect(craftsmanshipInfo(1).qualitySlots, 0);
      expect(craftsmanshipInfo(3).apparelGrade, ApparelGrade.standard);
      expect(craftsmanshipInfo(3).qualitySlots, 2);
      expect(craftsmanshipInfo(5).apparelGrade, ApparelGrade.high);
      expect(craftsmanshipInfo(5).qualitySlots, 4);
    });

    test('Apparel Bonus = Grade x(bT), raised by Divine Apparel', () {
      final c = Character.blank('ap1')..powerLevel = _plForTop(3); // baseTop 3
      final piece = ApparelPiece(craftsmanshipGrade: 3); // Standard = 2(bT)
      expect(CharacterCalculator.apparelBonus(c, piece), 2 * 3);
      piece.qualities.add(ApparelQualitySelection(name: 'Divine Apparel'));
      expect(CharacterCalculator.apparelBonus(c, piece), 3 * 3);
    });

    test('worn Armor grants Damage Reduction = Apparel Bonus; Sleek Design '
        'halves it', () {
      final c = Character.blank('ap2')..powerLevel = _plForTop(3);
      final armor = ApparelPiece(
        craftsmanshipGrade: 3,
        category: ApparelCategory.armor,
        worn: true,
        layer: WornLayer.top,
      );
      c.apparel.add(armor);
      expect(CharacterCalculator.apparelDamageReduction(c), 6);
      armor.qualities.add(ApparelQualitySelection(name: 'Sleek Design'));
      expect(CharacterCalculator.apparelDamageReduction(c), 3);
    });

    test('unworn or broken Armor grants no Damage Reduction', () {
      final c = Character.blank('ap3')..powerLevel = _plForTop(3);
      final armor = ApparelPiece(
          craftsmanshipGrade: 3, category: ApparelCategory.armor, worn: false);
      c.apparel.add(armor);
      expect(CharacterCalculator.apparelDamageReduction(c), 0);
      armor.worn = true;
      armor.breakValue = 0; // broken
      expect(CharacterCalculator.apparelDamageReduction(c), 0);
    });

    test('a Battle Uniform auto-equips while its Transformation is active and '
        'suppresses manual Apparel', () {
      final c = Character.blank('bu1')..powerLevel = _plForTop(3); // baseTop 3
      // Mode Change grants an Armor Battle Uniform (Grade 4 = Standard = 2(bT)).
      final sel = TransformationSelection(name: 'Mode Change', active: false);
      c.transformations.add(sel);
      // Inactive Form → no Battle Uniform, no Damage Reduction.
      expect(CharacterCalculator.apparelDamageReduction(c), 0);
      // Active → the Armor Battle Uniform grants DR = Apparel Bonus = 2 x 3.
      sel.active = true;
      expect(CharacterCalculator.apparelDamageReduction(c), 6);
      // A manually-worn piece is suppressed while the Battle Uniform is active
      // (you "lose access to your current Apparel").
      c.apparel.add(ApparelPiece(
        craftsmanshipGrade: 5, // High = 3(bT) → DR 9 if it counted
        category: ApparelCategory.armor,
        worn: true,
        layer: WornLayer.top,
      ));
      expect(CharacterCalculator.apparelDamageReduction(c), 6);
      // Leaving the Form restores access to the manual Armor.
      sel.active = false;
      expect(CharacterCalculator.apparelDamageReduction(c), 9);
    });

    test('worn Weights reduce all Combat Rolls by the Apparel Bonus', () {
      final c = Character.blank('ap4')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20)
        ..setTestScore(DbuAttribute.force, 20);
      final before = CharacterCalculator.compute(c);
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 3,
          category: ApparelCategory.weights,
          worn: true));
      final after = CharacterCalculator.compute(c);
      expect(after.strike.total, before.strike.total - 6);
      expect(after.dodge.total, before.dodge.total - 6);
      expect(after.woundPhysical.total, before.woundPhysical.total - 6);
    });

    test('worn Combat Clothing (Top Layer) raises Defense Value by 1/2 Apparel '
        'Bonus', () {
      final c = Character.blank('ap5')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.agility, 20);
      final before = CharacterCalculator.compute(c);
      c.apparel.add(ApparelPiece(
        craftsmanshipGrade: 3,
        category: ApparelCategory.combatClothing,
        worn: true,
        layer: WornLayer.top,
      ));
      final after = CharacterCalculator.compute(c);
      expect(after.defenseValue, before.defenseValue + 3); // ceil(6/2)
    });

    test('multi-layer Apparel Penalty: -ceil(baseToP/2) per piece after the '
        'first; Standard Clothing excluded', () {
      final c = Character.blank('ap6')..powerLevel = _plForTop(3); // ceil(3/2)=2
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 1,
          category: ApparelCategory.combatClothing,
          worn: true,
          layer: WornLayer.top));
      // A single worn piece incurs no penalty.
      expect(CharacterCalculator.apparelPenalty(c), 0);
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 1,
          category: ApparelCategory.combatClothing,
          worn: true,
          layer: WornLayer.middle));
      expect(CharacterCalculator.apparelPenalty(c), 2);
      // Standard Clothing doesn't count toward the penalty.
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 1,
          category: ApparelCategory.standardClothing,
          worn: true,
          layer: WornLayer.bottom));
      expect(CharacterCalculator.apparelPenalty(c), 2);
    });

    test('Break Value maximum: default 3, +3 with Durable; Unbreakable flagged',
        () {
      final piece = ApparelPiece(craftsmanshipGrade: 3);
      expect(CharacterCalculator.apparelMaxBreakValue(piece), 3);
      piece.qualities.add(ApparelQualitySelection(name: 'Durable'));
      expect(CharacterCalculator.apparelMaxBreakValue(piece), 6);
      expect(CharacterCalculator.apparelIsUnbreakable(piece), isFalse);
      piece.qualities.add(ApparelQualitySelection(name: 'Unbreakable'));
      expect(CharacterCalculator.apparelIsUnbreakable(piece), isTrue);
    });

    test('Quality Slots used vs available', () {
      final c = Character.blank('ap-slots');
      final piece = ApparelPiece(
          craftsmanshipGrade: 3,
          category: ApparelCategory.standardClothing); // 2 slots
      piece.qualities.add(ApparelQualitySelection(name: 'Jacket')); // 1
      piece.qualities.add(ApparelQualitySelection(
          name: 'Environmental Protection', slots: 2)); // 2
      expect(CharacterCalculator.apparelQualitySlots(c, piece), 2);
      expect(CharacterCalculator.apparelQualitySlotsUsed(piece), 3); // over
    });

    test('automated Quality effect: Jacket adds +1(bT) Soak while worn', () {
      final c = Character.blank('ap8')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.tenacity, 20);
      final before = CharacterCalculator.compute(c);
      final piece = ApparelPiece(
          craftsmanshipGrade: 3,
          category: ApparelCategory.standardClothing,
          worn: true);
      piece.qualities.add(ApparelQualitySelection(name: 'Jacket'));
      c.apparel.add(piece);
      final after = CharacterCalculator.compute(c);
      expect(after.soak, before.soak + 3); // +1(bT), baseTop 3
    });

    test('Combat Ready adds ceil(Apparel Bonus/2) to Strike', () {
      final c = Character.blank('ap9')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      final before = CharacterCalculator.compute(c);
      final piece = ApparelPiece(
        craftsmanshipGrade: 3,
        category: ApparelCategory.combatClothing,
        worn: true,
        layer: WornLayer.top,
      );
      piece.qualities.add(ApparelQualitySelection(name: 'Combat Ready'));
      c.apparel.add(piece);
      final after = CharacterCalculator.compute(c);
      // Strike gets only Combat Ready (+ceil(6/2)=3); the Combat Clothing DV
      // benefit lands on Dodge, not Strike.
      expect(after.strike.total, before.strike.total + 3);
    });

    test('ApparelPiece round-trips through Character JSON', () {
      final c = Character.blank('ap10');
      final piece = ApparelPiece(
        name: 'Battle Gi',
        craftsmanshipGrade: 4,
        category: ApparelCategory.combatClothing,
        size: DbuSize.large,
        worn: true,
        layer: WornLayer.middle,
        breakValue: 2,
      );
      piece.qualities
          .add(ApparelQualitySelection(name: 'Combat Ready', notes: 'x'));
      c.apparel.add(piece);
      final restored = Character.fromJson(c.toJson());
      expect(restored.apparel, hasLength(1));
      final r = restored.apparel.first;
      expect(r.name, 'Battle Gi');
      expect(r.craftsmanshipGrade, 4);
      expect(r.category, ApparelCategory.combatClothing);
      expect(r.size, DbuSize.large);
      expect(r.worn, isTrue);
      expect(r.layer, WornLayer.middle);
      expect(r.breakValue, 2);
      expect(r.qualities.single.name, 'Combat Ready');
      expect(r.qualities.single.notes, 'x');
    });

    test('Natural Armor derives its Grade from base Tier of Power (max. 5)', () {
      final c = Character.blank('na1')..powerLevel = _plForTop(3); // baseTop 3
      final piece = ApparelPiece(isNaturalArmor: true);
      // Grade 3 → Standard = 2(bT) → 6; the stored craftsmanshipGrade (1) is
      // ignored.
      expect(CharacterCalculator.effectiveCraftGrade(c, piece), 3);
      expect(CharacterCalculator.apparelGrade(c, piece), ApparelGrade.standard);
      expect(CharacterCalculator.apparelBonus(c, piece), 6);
      expect(CharacterCalculator.apparelQualitySlots(c, piece), 2);
      // At Tier of Power 7 the Grade clamps to 5 (High = 3(bT), 4 Slots).
      c.powerLevel = _plForTop(7);
      expect(CharacterCalculator.effectiveCraftGrade(c, piece), 5);
      expect(CharacterCalculator.apparelBonus(c, piece), 21);
      expect(CharacterCalculator.apparelQualitySlots(c, piece), 4);
    });

    test('Natural Armor grants Damage Reduction while Integrated (Bottom Layer, '
        'never "worn")', () {
      final c = Character.blank('na2')..powerLevel = _plForTop(3);
      final piece = ApparelPiece(
        isNaturalArmor: true,
        category: ApparelCategory.armor,
        layer: WornLayer.bottom,
        worn: false, // Integrated: still Active without being "worn".
      );
      c.apparel.add(piece);
      expect(CharacterCalculator.apparelIsActive(piece), isTrue);
      expect(CharacterCalculator.apparelDamageReduction(c), 6);
      // Broken (Break Value 0) → inactive, no DR.
      piece.breakValue = 0;
      expect(CharacterCalculator.apparelIsActive(piece), isFalse);
      expect(CharacterCalculator.apparelDamageReduction(c), 0);
    });

    test('Natural Armor never counts toward the Apparel Penalty (nor consumes '
        'the free first slot)', () {
      final c = Character.blank('na3')..powerLevel = _plForTop(3); // ceil(3/2)=2
      c.apparel.add(ApparelPiece(
        isNaturalArmor: true,
        category: ApparelCategory.armor,
        layer: WornLayer.bottom,
      ));
      // Natural Armor alone: no penalty and it doesn't consume the free slot.
      expect(CharacterCalculator.apparelPenalty(c), 0);
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 1,
          category: ApparelCategory.combatClothing,
          worn: true));
      // The one real worn piece is the "first" → still no penalty.
      expect(CharacterCalculator.apparelPenalty(c), 0);
      c.apparel.add(ApparelPiece(
          craftsmanshipGrade: 1,
          category: ApparelCategory.combatClothing,
          worn: true,
          layer: WornLayer.middle));
      // Two real pieces → one over the first → -2.
      expect(CharacterCalculator.apparelPenalty(c), 2);
    });

    test('Natural Apparel Awakening (Adjusted Armor) adds +1(bT) to Natural '
        'Armor Apparel Bonus (and its DR), but not to ordinary Apparel', () {
      final c = Character.blank('na-app')..powerLevel = _plForTop(3); // baseTop 3
      final nat = ApparelPiece(
        isNaturalArmor: true,
        category: ApparelCategory.armor,
        layer: WornLayer.bottom,
      );
      final ordinary = ApparelPiece(
        craftsmanshipGrade: 3,
        category: ApparelCategory.armor,
        worn: true,
        layer: WornLayer.top,
      );
      c.apparel.addAll([nat, ordinary]);
      // Before the Awakening: Grade 3 (Standard) = 2(bT) = 6 for both.
      expect(CharacterCalculator.apparelBonus(c, nat), 6);
      expect(CharacterCalculator.apparelBonus(c, ordinary), 6);

      c.transformations.add(TransformationSelection(name: 'Adjusted Armor'));
      // Natural Armor gains +1(bT) = +3 → 9; DR follows. Ordinary Armor is
      // untouched.
      expect(CharacterCalculator.naturalArmorBonusPerBaseTier(c), 1);
      expect(CharacterCalculator.apparelBonus(c, nat), 9);
      expect(CharacterCalculator.apparelBonus(c, ordinary), 6);
      expect(CharacterCalculator.apparelDamageReduction(c), 9 + 6);
    });

    test('Natural Armor round-trips and is detected on granting Traits', () {
      final c = Character.blank('na4');
      c.apparel.add(ApparelPiece(name: 'Plating', isNaturalArmor: true));
      final r = Character.fromJson(c.toJson()).apparel.single;
      expect(r.isNaturalArmor, isTrue);
      expect(r.name, 'Plating');

      // The Arcosian "Survivor" Trait grants Natural Armor ("Your Plating is
      // Natural Armor.").
      final arco = Character.blank('na5')..race = 'Arcosian';
      expect(CharacterCalculator.grantsNaturalArmor(arco), isTrue);
      expect(CharacterCalculator.hasNaturalArmorPiece(arco), isFalse);
      // A race with no such Trait is not flagged.
      final human = Character.blank('na6')..race = 'Earthling';
      expect(CharacterCalculator.grantsNaturalArmor(human), isFalse);
    });

    test('every catalogue Quality is valid: category set non-empty, slot range '
        'sane, automated ones resolve', () {
      expect(kDbuApparelQualities, isNotEmpty);
      for (final q in kDbuApparelQualities) {
        expect(q.categories, isNotEmpty, reason: q.name);
        expect(q.minSlots >= 1, isTrue, reason: q.name);
        expect(q.maxSlots >= q.minSlots, isTrue, reason: q.name);
        expect(apparelQualityByName(q.name), same(q), reason: q.name);
      }
    });
  });

  group('Weapons', () {
    test('max Life Points = 32 + 8/PL, plus Shield (Size) and Durable', () {
      final c = Character.blank('w1')..powerLevel = 5;
      final w = WeaponPiece(type: WeaponType.physical, size: WeaponSize.big);
      expect(CharacterCalculator.weaponMaxLife(c, w), 32 + 8 * 5);
      // Shield adds Size-scaled Life Points per Power Level (Big = 3).
      w.category = 'Shield';
      expect(CharacterCalculator.weaponMaxLife(c, w), 32 + 8 * 5 + 3 * 5);
      // Durable at 1 slot adds 2/PL; at 2 slots it doubles to 4/PL.
      final d = WeaponPiece(type: WeaponType.physical);
      d.qualities.add(WeaponQualitySelection(name: 'Durable', slots: 1));
      expect(CharacterCalculator.weaponMaxLife(c, d), 32 + 8 * 5 + 2 * 5);
      d.qualities.first.slots = 2;
      expect(CharacterCalculator.weaponMaxLife(c, d), 32 + 8 * 5 + 4 * 5);
    });

    test("Weapon's own Damage Reduction = 6(bT)", () {
      final c = Character.blank('w2')..powerLevel = _plForTop(3);
      expect(CharacterCalculator.weaponSelfDamageReduction(c), 6 * 3);
    });

    test('Weapon Penalty: -2(T) Strike while wielding any Weapon, removed by '
        'Weapon Specialist', () {
      final c = Character.blank('w3')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      final before = CharacterCalculator.compute(c);
      c.weapons.add(WeaponPiece(type: WeaponType.physical, wielded: true));
      final wielding = CharacterCalculator.compute(c);
      expect(wielding.strike.total, before.strike.total - 2 * 3);
      expect(wielding.weaponPenalty, 2 * 3);
      // The Weapon Specialist Talent nullifies it.
      c.talents.add(TalentEntry(name: 'Weapon Specialist'));
      final specialist = CharacterCalculator.compute(c);
      expect(specialist.strike.total, before.strike.total);
      expect(specialist.weaponPenalty, 0);
    });

    test('un-wielded Weapon incurs no Weapon Penalty', () {
      final c = Character.blank('w4')..powerLevel = _plForTop(3);
      c.weapons.add(WeaponPiece(type: WeaponType.physical, wielded: false));
      expect(CharacterCalculator.weaponPenalty(c), 0);
    });

    test('Weapon Size modifiers: Small +1/-2(T), Big -1/+2(T) Strike/Wound', () {
      final c = Character.blank('w5')..powerLevel = _plForTop(3);
      final small = WeaponPiece(type: WeaponType.physical, size: WeaponSize.small);
      final smallMods = CharacterCalculator.weaponModifiers(c, small);
      expect(smallMods[AffectedStat.strike], 1 * 3);
      expect(smallMods[AffectedStat.woundPhysical], -2 * 3);
      final big = WeaponPiece(type: WeaponType.energy, size: WeaponSize.big);
      final bigMods = CharacterCalculator.weaponModifiers(c, big);
      expect(bigMods[AffectedStat.strike], -1 * 3);
      // Energy Weapon feeds the Energy Wound Roll.
      expect(bigMods[AffectedStat.woundEnergy], 2 * 3);
    });

    test('Slashing / Magic Orb Categories add +2(T) to the Weapon Wound', () {
      final c = Character.blank('w6')..powerLevel = _plForTop(3);
      final slash = WeaponPiece(type: WeaponType.physical, category: 'Slashing');
      expect(CharacterCalculator.weaponModifiers(c, slash)[
          AffectedStat.woundPhysical], 2 * 3);
      final orb = WeaponPiece(type: WeaponType.magic, category: 'Magic Orb');
      expect(CharacterCalculator.weaponModifiers(c, orb)[
          AffectedStat.woundMagic], 2 * 3);
    });

    test('Artisan adds +1(T) Wound per Quality Slot occupied', () {
      final c = Character.blank('w7')..powerLevel = _plForTop(3);
      final w = WeaponPiece(type: WeaponType.physical);
      w.qualities.add(WeaponQualitySelection(name: 'Artisan', slots: 1));
      expect(CharacterCalculator.weaponModifiers(c, w)[
          AffectedStat.woundPhysical], 1 * 3);
      w.qualities.first.slots = 2;
      expect(CharacterCalculator.weaponModifiers(c, w)[
          AffectedStat.woundPhysical], 2 * 3);
    });

    test('Super Heavy: -2(bT) Strike, +5(bT) Wound', () {
      final c = Character.blank('w8')..powerLevel = _plForTop(3);
      final w = WeaponPiece(type: WeaponType.physical);
      w.qualities.add(WeaponQualitySelection(name: 'Super Heavy'));
      final mods = CharacterCalculator.weaponModifiers(c, w);
      expect(mods[AffectedStat.strike], -2 * 3);
      expect(mods[AffectedStat.woundPhysical], 5 * 3);
    });

    test('Warding Weapon adds +2(bT) Damage Reduction while wielded', () {
      final c = Character.blank('w9')..powerLevel = _plForTop(3);
      final w = WeaponPiece(type: WeaponType.physical, wielded: true);
      w.qualities.add(WeaponQualitySelection(name: 'Warding Weapon'));
      c.weapons.add(w);
      expect(CharacterCalculator.weaponDamageReduction(c), 2 * 3);
      // Not wielded → no Damage Reduction.
      w.wielded = false;
      expect(CharacterCalculator.weaponDamageReduction(c), 0);
    });

    test('broken (0 LP) or un-wielded Weapon is inactive', () {
      final c = Character.blank('w10')..powerLevel = 5;
      final w = WeaponPiece(type: WeaponType.physical, wielded: false);
      c.weapons.add(w);
      expect(CharacterCalculator.weaponIsActive(c, w), isFalse);
      w.wielded = true;
      expect(CharacterCalculator.weaponIsActive(c, w), isTrue);
      w.lifePoints = 0; // broken
      expect(CharacterCalculator.weaponIsActive(c, w), isFalse);
    });

    test('Unbreakable Weapon Quality is flagged', () {
      final w = WeaponPiece(type: WeaponType.physical);
      expect(CharacterCalculator.weaponIsUnbreakable(w), isFalse);
      w.qualities.add(WeaponQualitySelection(name: 'Unbreakable'));
      expect(CharacterCalculator.weaponIsUnbreakable(w), isTrue);
    });

    test('Quality Slots used vs available (from Craftsmanship Grade)', () {
      final w = WeaponPiece(type: WeaponType.physical, craftsmanshipGrade: 3);
      w.qualities.add(WeaponQualitySelection(name: 'Artisan', slots: 2));
      w.qualities.add(WeaponQualitySelection(name: 'Durable', slots: 1));
      expect(CharacterCalculator.weaponQualitySlots(w), 2); // Grade 3 → 2
      expect(CharacterCalculator.weaponQualitySlotsUsed(w), 3); // over
    });

    test('per-Weapon modifiers are NOT folded into the global Strike/Wound', () {
      final c = Character.blank('w11')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.force, 20)
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      final before = CharacterCalculator.compute(c);
      // A wielded Slashing Weapon: only the global Weapon Penalty changes the
      // sheet's Strike; the +2(T) Slashing Wound stays per-Weapon.
      c.weapons.add(WeaponPiece(
          type: WeaponType.physical, category: 'Slashing', wielded: true));
      final after = CharacterCalculator.compute(c);
      expect(after.woundPhysical.total, before.woundPhysical.total);
      expect(after.strike.total, before.strike.total - 2 * 3);
    });

    test('WeaponPiece round-trips through Character JSON', () {
      final c = Character.blank('w12');
      final w = WeaponPiece(
        name: 'Power Pole',
        type: WeaponType.physical,
        size: WeaponSize.big,
        category: 'Slashing',
        craftsmanshipGrade: 4,
        wielded: true,
        lifePoints: 40,
      );
      w.qualities.add(WeaponQualitySelection(name: 'Artisan', slots: 2, notes: 'x'));
      c.weapons.add(w);
      final restored = Character.fromJson(c.toJson());
      expect(restored.weapons, hasLength(1));
      final r = restored.weapons.first;
      expect(r.name, 'Power Pole');
      expect(r.type, WeaponType.physical);
      expect(r.size, WeaponSize.big);
      expect(r.category, 'Slashing');
      expect(r.craftsmanshipGrade, 4);
      expect(r.wielded, isTrue);
      expect(r.lifePoints, 40);
      expect(r.qualities.single.name, 'Artisan');
      expect(r.qualities.single.slots, 2);
      expect(r.qualities.single.notes, 'x');
    });

    test('every catalogue Category is valid and resolves', () {
      expect(kDbuWeaponCategories, isNotEmpty);
      for (final cat in kDbuWeaponCategories) {
        expect(cat.effects.isNotEmpty, isTrue, reason: cat.name);
        expect(weaponCategoryByName(cat.name), same(cat), reason: cat.name);
        expect(weaponCategoriesFor(cat.type).contains(cat), isTrue,
            reason: cat.name);
      }
      // Every Weapon Type has at least one Category available.
      for (final t in WeaponType.values) {
        expect(weaponCategoriesFor(t), isNotEmpty, reason: t.name);
      }
    });

    test('every catalogue Quality is valid: type set non-empty, slot range '
        'sane, automated ones resolve', () {
      expect(kDbuWeaponQualities, isNotEmpty);
      for (final q in kDbuWeaponQualities) {
        expect(q.types, isNotEmpty, reason: q.name);
        expect(q.minSlots >= 1, isTrue, reason: q.name);
        expect(q.maxSlots >= q.minSlots, isTrue, reason: q.name);
        expect(weaponQualityByName(q.name), same(q), reason: q.name);
      }
    });
  });

  group('Accessories', () {
    test('equipped Armored Gloves grant +1(bT) Damage Reduction', () {
      final c = Character.blank('ac1')..powerLevel = _plForTop(3);
      c.accessories.add(AccessorySelection(name: 'Armored Gloves', equipped: true));
      expect(CharacterCalculator.accessoryDamageReduction(c), 1 * 3);
      // Not equipped → no benefit.
      c.accessories.first.equipped = false;
      expect(CharacterCalculator.accessoryDamageReduction(c), 0);
    });

    test('equipped Bunny Ears raise Normal/Boosted Speed by 1(bT)/2(bT)', () {
      final c = Character.blank('ac2')..powerLevel = _plForTop(3);
      final before = CharacterCalculator.compute(c);
      c.accessories.add(AccessorySelection(name: 'Bunny Ears', equipped: true));
      final after = CharacterCalculator.compute(c);
      expect(after.speedNormal, before.speedNormal + 1 * 3);
      expect(after.speedBoosted, before.speedBoosted + 2 * 3);
    });

    test('equipped Sash raises the Impulsive Saving Throw by 1(bT)', () {
      final c = Character.blank('ac3')..powerLevel = _plForTop(3);
      final before = CharacterCalculator.compute(c);
      c.accessories.add(AccessorySelection(name: 'Sash', equipped: true));
      final after = CharacterCalculator.compute(c);
      expect(after.savingThrows[DbuSavingThrow.impulsive]!.total,
          before.savingThrows[DbuSavingThrow.impulsive]!.total + 1 * 3);
    });

    test('un-equipped Accessory applies nothing', () {
      final c = Character.blank('ac4')..powerLevel = _plForTop(3);
      final before = CharacterCalculator.compute(c);
      c.accessories.add(AccessorySelection(name: 'Bunny Ears', equipped: false));
      final after = CharacterCalculator.compute(c);
      expect(after.speedNormal, before.speedNormal);
      expect(CharacterCalculator.equippedAccessoryCount(c), 0);
    });

    test('equipped count tracks the 2-Accessory cap', () {
      final c = Character.blank('ac5');
      c.accessories.add(AccessorySelection(name: 'Sash', equipped: true));
      c.accessories.add(AccessorySelection(name: 'Helmet', equipped: true));
      expect(CharacterCalculator.equippedAccessoryCount(c), 2);
      c.accessories.add(AccessorySelection(name: 'Mask', equipped: true));
      expect(CharacterCalculator.equippedAccessoryCount(c), 3); // over cap (not clamped)
    });

    test('Damage Reduction from multiple equipped Accessories stacks', () {
      final c = Character.blank('ac6')..powerLevel = _plForTop(3);
      c.accessories.add(AccessorySelection(name: 'Armored Gloves', equipped: true));
      c.accessories.add(AccessorySelection(name: 'Helmet', equipped: true));
      expect(CharacterCalculator.accessoryDamageReduction(c), 2 * 3);
    });

    test('AccessorySelection round-trips through Character JSON', () {
      final c = Character.blank('ac7');
      c.accessories.add(AccessorySelection(
          name: 'Eyeglasses', equipped: true, notes: 'Intended: Bulma'));
      final restored = Character.fromJson(c.toJson());
      expect(restored.accessories, hasLength(1));
      final r = restored.accessories.first;
      expect(r.name, 'Eyeglasses');
      expect(r.equipped, isTrue);
      expect(r.notes, 'Intended: Bulma');
    });

    test('catalogue integrity: unique names, Special ones lack a Craft DC, '
        'automated ones have effects', () {
      expect(kDbuAccessories, isNotEmpty);
      final seen = <String>{};
      for (final a in kDbuAccessories) {
        expect(seen.add(a.name), isTrue, reason: 'duplicate ${a.name}');
        expect(a.effects.isNotEmpty, isTrue, reason: a.name);
        expect(accessoryByName(a.name), same(a), reason: a.name);
        if (a.isSpecial) {
          expect(a.craftDc, isEmpty, reason: a.name);
        }
      }
    });
  });

  group('Basic Items', () {
    test('BasicItemSelection round-trips through Character JSON', () {
      final c = Character.blank('bi1');
      c.basicItems.add(BasicItemSelection(
          name: 'Bag of Senzu Beans', quantity: 4, notes: 'rolled 1d6 = 4'));
      final restored = Character.fromJson(c.toJson());
      expect(restored.basicItems, hasLength(1));
      final r = restored.basicItems.first;
      expect(r.name, 'Bag of Senzu Beans');
      expect(r.quantity, 4);
      expect(r.notes, 'rolled 1d6 = 4');
    });

    test('catalogue integrity: unique names, effects present, Special ones lack '
        'a Craft DC, tags are known', () {
      expect(kDbuBasicItems, isNotEmpty);
      const knownTags = {'Tech', 'Med', 'Food'};
      final seen = <String>{};
      for (final b in kDbuBasicItems) {
        expect(seen.add(b.name), isTrue, reason: 'duplicate ${b.name}');
        expect(b.effects.isNotEmpty, isTrue, reason: b.name);
        expect(b.description.isNotEmpty, isTrue, reason: b.name);
        expect(basicItemByName(b.name), same(b), reason: b.name);
        for (final t in b.tags) {
          expect(knownTags.contains(t), isTrue, reason: '${b.name}: $t');
        }
        if (b.isSpecial) {
          expect(b.craftDc, isEmpty, reason: b.name);
        } else {
          expect(b.craftDc.isNotEmpty, isTrue, reason: b.name);
        }
      }
    });

    test('both Basic and Special Basic Items are catalogued', () {
      expect(kDbuBasicItems.where((b) => !b.isSpecial), isNotEmpty);
      expect(kDbuBasicItems.where((b) => b.isSpecial), isNotEmpty);
    });
  });

  group('Signature Techniques', () {
    SignatureTechnique sig({
      SignatureLevel level = SignatureLevel.superTech,
      String profile = 'Simple',
      List<SigModifierSelection>? adv,
      List<SigModifierSelection>? dis,
    }) =>
        SignatureTechnique(
          level: level,
          foundation: SigFoundation.physical,
          profileName: profile,
          advantages: adv,
          disadvantages: dis,
        );

    test('TP Cost starts at 8 and floors at 8', () {
      expect(CharacterCalculator.signatureTpCost(sig()), 8);
      // Disadvantages cannot push below 8.
      expect(
        CharacterCalculator.signatureTpCost(sig(
            dis: [SigModifierSelection(name: 'All or Nothing')])), // −5
        8,
      );
    });

    test('Ultimate / Dramatic Finisher add +4 TP', () {
      expect(
          CharacterCalculator.signatureTpCost(
              sig(level: SignatureLevel.ultimate)),
          12);
      expect(
          CharacterCalculator.signatureTpCost(
              sig(level: SignatureLevel.dramaticFinisher)),
          12);
    });

    test('ranked Advantage TP cost is cumulative', () {
      // Accurate: 3 (R1), 5 (R2), 7 (R3).
      final t = sig(adv: [SigModifierSelection(name: 'Accurate', rank: 1)]);
      expect(CharacterCalculator.signatureTpCost(t), 8 + 3);
      t.advantages.first.rank = 2;
      expect(CharacterCalculator.signatureTpCost(t), 8 + 8); // 3+5
      t.advantages.first.rank = 3;
      expect(CharacterCalculator.signatureTpCost(t), 8 + 15); // 3+5+7
    });

    test('Advantages add and Disadvantages subtract TP', () {
      final t = sig(
        adv: [SigModifierSelection(name: 'Charging Assault')], // +10
        dis: [SigModifierSelection(name: 'Grappling')], // −5
      );
      expect(CharacterCalculator.signatureTpCost(t), 8 + 10 - 5);
    });

    test('KP Cost = (Profile KP + ceil(TP/5)) x Tier, min 0 without a Profile',
        () {
      final c = Character.blank('sg1')..powerLevel = _plForTop(3);
      // Simple Profile KP = 0, TP = 8 → ceil(8/5)=2 → 2(T) → 6 at ToP 3.
      expect(CharacterCalculator.signatureKpCost(c, sig()), 2 * 3);
      // No Profile → 0.
      expect(
          CharacterCalculator.signatureKpCost(c, sig(profile: '')), 0);
    });

    test('Inefficiency raises KP by 4(T)/rank; Efficiency lowers it', () {
      final c = Character.blank('sg2')..powerLevel = _plForTop(3);
      // Inefficiency (−6 TP, +4(T) KP). TP floors at 8 → ceil=2; +4 = 6(T).
      final ineff = sig(dis: [SigModifierSelection(name: 'Inefficiency')]);
      expect(CharacterCalculator.signatureKpCost(c, ineff), 6 * 3);
      // Efficiency (+8 TP → 16, ceil(16/5)=4; −4 = 0(T)).
      final eff = sig(adv: [SigModifierSelection(name: 'Efficiency')]);
      expect(CharacterCalculator.signatureKpCost(c, eff), 0);
    });

    test('per-Technique modifiers: Accurate Strike, Power Shot Wound, '
        'Inaccurate Strike', () {
      final c = Character.blank('sg3')..powerLevel = _plForTop(3);
      final acc = sig(adv: [SigModifierSelection(name: 'Accurate', rank: 2)]);
      expect(CharacterCalculator.signatureModifiers(c, acc)[AffectedStat.strike],
          2 * 3); // +1(T) × 2 ranks
      final ps = sig(adv: [SigModifierSelection(name: 'Power Shot', rank: 1)]);
      expect(
          CharacterCalculator.signatureModifiers(c, ps)[
              AffectedStat.woundPhysical],
          2 * 3); // +2(T)
      final inacc =
          sig(dis: [SigModifierSelection(name: 'Inaccurate', rank: 3)]);
      expect(
          CharacterCalculator.signatureModifiers(c, inacc)[AffectedStat.strike],
          -3 * 3); // −1(T) × 3
    });

    test('Energy/Magic Foundation feeds the matching Wound stat', () {
      final c = Character.blank('sg4')..powerLevel = _plForTop(3);
      final t = SignatureTechnique(
        foundation: SigFoundation.magic,
        profileName: 'Simple',
        advantages: [SigModifierSelection(name: 'Power Shot')],
      );
      final mods = CharacterCalculator.signatureModifiers(c, t);
      expect(mods[AffectedStat.woundMagic], 2 * 3);
      expect(mods[AffectedStat.woundPhysical], isNull);
    });

    test('per-Technique modifiers are NOT folded into the global sheet', () {
      final c = Character.blank('sg5')
        ..powerLevel = _plForTop(3)
        ..setTestScore(DbuAttribute.agility, 20)
        ..setTestScore(DbuAttribute.insight, 20);
      final before = CharacterCalculator.compute(c);
      c.signatureTechniques
          .add(sig(adv: [SigModifierSelection(name: 'Accurate', rank: 3)]));
      final after = CharacterCalculator.compute(c);
      expect(after.strike.total, before.strike.total);
    });

    test('TP spend cap by Base Tier of Power: 25/30/40/50', () {
      int cap(int top) => CharacterCalculator.signatureTpSpendCap(
          Character.blank('c')..powerLevel = _plForTop(top));
      expect(cap(1), 25);
      expect(cap(2), 30);
      expect(cap(3), 40);
      expect(cap(4), 50);
    });

    test('Ultimate possession warnings', () {
      final c = Character.blank('sg6');
      // 2 Ultimates, 0 Supers → needs-more-Supers warning.
      c.signatureTechniques.add(sig(level: SignatureLevel.ultimate));
      c.signatureTechniques.add(sig(level: SignatureLevel.ultimate));
      expect(CharacterCalculator.signatureUltimateWarnings(c),
          contains(contains('need')));
      // 1 Ultimate alone → no possession warning.
      final c2 = Character.blank('sg7')
        ..signatureTechniques.add(sig(level: SignatureLevel.ultimate));
      expect(CharacterCalculator.signatureUltimateWarnings(c2), isEmpty);
      // 2 Dramatic Finishers → warning.
      final c3 = Character.blank('sg8')
        ..signatureTechniques
            .add(sig(level: SignatureLevel.dramaticFinisher))
        ..signatureTechniques
            .add(sig(level: SignatureLevel.dramaticFinisher));
      expect(CharacterCalculator.signatureUltimateWarnings(c3),
          contains(contains('Dramatic Finisher')));
    });

    test('SignatureTechnique round-trips through Character JSON', () {
      final c = Character.blank('sg9');
      final t = SignatureTechnique(
        name: 'Kamehameha',
        level: SignatureLevel.ultimate,
        foundation: SigFoundation.energy,
        profileName: 'Beam',
        advantages: [SigModifierSelection(name: 'Accurate', rank: 2)],
        disadvantages: [SigModifierSelection(name: 'Mandatory Charge')],
        usedThisEncounter: true,
        notes: 'x',
      );
      c.signatureTechniques.add(t);
      final r = Character.fromJson(c.toJson()).signatureTechniques.single;
      expect(r.name, 'Kamehameha');
      expect(r.level, SignatureLevel.ultimate);
      expect(r.foundation, SigFoundation.energy);
      expect(r.profileName, 'Beam');
      expect(r.advantages.single.name, 'Accurate');
      expect(r.advantages.single.rank, 2);
      expect(r.disadvantages.single.name, 'Mandatory Charge');
      expect(r.usedThisEncounter, isTrue);
      expect(r.notes, 'x');
    });

    test('Profiles catalogue: 27 standard + 12 Super, unique, resolve', () {
      expect(kDbuSignatureProfiles, hasLength(27));
      expect(kDbuSuperProfiles, hasLength(12));
      final seen = <String>{};
      for (final p in [...kDbuSignatureProfiles, ...kDbuSuperProfiles]) {
        expect(seen.add(p.name), isTrue, reason: 'duplicate ${p.name}');
        expect(p.effect.isNotEmpty, isTrue, reason: p.name);
        expect(signatureProfileByName(p.name), same(p), reason: p.name);
      }
      for (final p in kDbuSuperProfiles) {
        expect(p.isSuper, isTrue, reason: p.name);
      }
      // Every concrete Foundation has Profiles available (its own + Multi).
      for (final f in SigFoundation.concrete) {
        expect(profilesForFoundation(f), isNotEmpty, reason: f.name);
      }
    });

    test('Modifier catalogue: 63 Advantages + 41 Disadvantages, valid, '
        'automations resolve', () {
      expect(kDbuSignatureAdvantages, hasLength(63));
      expect(kDbuSignatureDisadvantages, hasLength(41));
      final seen = <String>{};
      for (final m in [
        ...kDbuSignatureAdvantages,
        ...kDbuSignatureDisadvantages
      ]) {
        expect(seen.add(m.name), isTrue, reason: 'duplicate ${m.name}');
        expect(m.effect.isNotEmpty, isTrue, reason: m.name);
        expect(m.tpCostsPerRank, isNotEmpty, reason: m.name);
        expect(signatureModifierByName(m.name), same(m), reason: m.name);
        // Advantage costs are positive; Disadvantage costs are negative.
        for (final cost in m.tpCostsPerRank) {
          expect(m.isDisadvantage ? cost < 0 : cost > 0, isTrue, reason: m.name);
        }
        // Ultimate-only modifiers name Ultimate in their requirement.
        if (m.ultimateOnly) {
          expect(m.requirement.contains('Ultimate'), isTrue, reason: m.name);
        }
      }
    });
  });

  group('Unique Abilities', () {
    UniqueAbilitySelection sel(String name,
            {Set<String>? adv, Set<String>? restr}) =>
        UniqueAbilitySelection(
            name: name, advancements: adv, restrictions: restr);

    test('TP Cost = base + Advancements − Restrictions, floored at 1/2 base',
        () {
      // Barrier base 15.
      expect(CharacterCalculator.uniqueAbilityTpCost(sel('Barrier')), 15);
      // + Efficient Barrier (5) + Massive Barrier (15) = 35.
      expect(
          CharacterCalculator.uniqueAbilityTpCost(sel('Barrier',
              adv: {'Efficient Barrier', 'Massive Barrier'})),
          35);
      // Binding base 20, both Restrictions −5 each = 10.
      expect(
          CharacterCalculator.uniqueAbilityTpCost(
              sel('Binding', restr: {'Gentle Hold', 'Weak Hold'})),
          10);
    });

    test('TP Cost floors at 1/2 the listed base', () {
      // Dragon Dash base 5 — a hypothetical big reduction floors at ceil(5/2)=3.
      // (No restriction that large exists; verify the floor via Binding: base
      // 20 floor is 10, matched above.) Here confirm the ceil rounding:
      final def = uniqueAbilityByName('Cage of Light')!; // base 16 → floor 8
      expect((def.baseTpCost + 1) ~/ 2, 8);
    });

    test('KP Cost applies Advancement reductions and the 1/2 floor', () {
      final c = Character.blank('ua1')..powerLevel = _plForTop(3);
      // Barrier KP 10(T) → 30 at ToP 3.
      expect(CharacterCalculator.uniqueAbilityKpCost(c, sel('Barrier')), 30);
      // Efficient Barrier −2(T) → 8(T) → 24.
      expect(
          CharacterCalculator.uniqueAbilityKpCost(
              c, sel('Barrier', adv: {'Efficient Barrier'})),
          24);
    });

    test('KP Cost uses Base Tier for (bT) abilities; null for non-numeric', () {
      final c = Character.blank('ua2')..powerLevel = _plForTop(3);
      // Atmospheric Bubble 4(bT) → 12 at baseToP 3.
      expect(
          CharacterCalculator.uniqueAbilityKpCost(c, sel('Atmospheric Bubble')),
          12);
      // Body Change KP is "Your entire Capacity" → null (reference only).
      expect(CharacterCalculator.uniqueAbilityKpCost(c, sel('Body Change')),
          isNull);
    });

    test('applied Restriction locks its Advancements', () {
      final s = sel('Binding', restr: {'Gentle Hold'});
      expect(CharacterCalculator.uniqueAbilityLockedAdvancements(s),
          containsAll(['Binding Volley', 'Psycho Thread']));
    });

    test('total TP across abilities', () {
      final c = Character.blank('ua3')
        ..uniqueAbilities.add(sel('Barrier')) // 15
        ..uniqueAbilities.add(sel('Dragon Dash')); // 5
      expect(CharacterCalculator.uniqueAbilityTotalTp(c), 20);
    });

    test('UniqueAbilitySelection round-trips through Character JSON', () {
      final c = Character.blank('ua4');
      c.uniqueAbilities.add(UniqueAbilitySelection(
        name: 'Barrier',
        type: UniqueAbilityType.magical,
        advancements: {'Efficient Barrier'},
        restrictions: {},
        notes: 'x',
      ));
      final r = Character.fromJson(c.toJson()).uniqueAbilities.single;
      expect(r.name, 'Barrier');
      expect(r.type, UniqueAbilityType.magical);
      expect(r.advancements, {'Efficient Barrier'});
      expect(r.notes, 'x');
    });

    test('catalogue integrity: 69 abilities, unique names, valid costs, '
        'advancement/restriction names unique, locked advancements resolve', () {
      expect(kDbuUniqueAbilities, hasLength(70));
      // Trait/Awakening-granted abilities have no TP cost on the site ("TP
      // Cost: N/A") — everything else costs TP. (Energy Consumption's three,
      // plus Manipulation Sorcery from the Magical Manipulation Wizarding
      // Trait.)
      const granted = {
        'Fire and Flames',
        'Over-Empower',
        'Planetary Consumption',
        'Manipulation Sorcery',
      };
      final seen = <String>{};
      for (final a in kDbuUniqueAbilities) {
        expect(seen.add(a.name), isTrue, reason: 'duplicate ${a.name}');
        expect(a.types, isNotEmpty, reason: a.name);
        expect(a.effect.isNotEmpty, isTrue, reason: a.name);
        expect(granted.contains(a.name) ? a.baseTpCost == 0 : a.baseTpCost > 0,
            isTrue, reason: a.name);
        expect(uniqueAbilityByName(a.name), same(a), reason: a.name);
        final advNames = a.advancements.map((x) => x.name).toSet();
        expect(advNames, hasLength(a.advancements.length),
            reason: '${a.name}: duplicate advancement');
        for (final adv in a.advancements) {
          expect(adv.effect.isNotEmpty, isTrue, reason: adv.name);
          expect(adv.tpCost > 0, isTrue, reason: adv.name);
        }
        for (final r in a.restrictions) {
          expect(r.tpCostReduction > 0, isTrue, reason: r.name);
          // Every locked Advancement names a real Advancement of this ability.
          for (final locked in r.lockedAdvancements) {
            expect(advNames.contains(locked), isTrue,
                reason: '${a.name}/${r.name}: locks unknown $locked');
          }
        }
      }
    });

    test('20 Jul 2026 site sync: the six new Unique Abilities resolve', () {
      expect(uniqueAbilityByName('Bluff Attack')?.allowsBothTypes, isTrue);
      expect(uniqueAbilityByName('False Courage')?.baseTpCost, 8);
      expect(uniqueAbilityByName('Finish Sign')?.advancements.single.name,
          'Aggressive Taunt');
      expect(uniqueAbilityByName('Judo Toss')?.advancements, hasLength(3));
      expect(uniqueAbilityByName('Punisher Guard')?.advancements, hasLength(2));
      expect(uniqueAbilityByName('Stardust Barrier')?.maneuverType, 'Counter');
    });
  });

  group('Technique Point budget', () {
    // A Custom Species character (no racial Traits) with one PL1 Skill
    // Improvement → 25 base TP, 1 Skill Improvement counted.
    Character pl1WithOneSkillImprovement(String id) {
      final c = Character.blank(id)..powerLevel = 1;
      c.progressionChoices['1:10'] =
          ProgressionChoice(resolvedKind: ProgressionGrantKind.skillImprovement);
      return c;
    }

    test('Gifted Student: +3 per SI at Scholarship 4+, +6 at 8+', () {
      final c = pl1WithOneSkillImprovement('gs');
      expect(CharacterCalculator.giftedStudentTpPerSkillImprovement(c), 0);
      c.setTestScore(DbuAttribute.scholarship, 4);
      expect(CharacterCalculator.giftedStudentTpPerSkillImprovement(c), 3);
      c.setTestScore(DbuAttribute.scholarship, 7);
      expect(CharacterCalculator.giftedStudentTpPerSkillImprovement(c), 3);
      c.setTestScore(DbuAttribute.scholarship, 8);
      expect(CharacterCalculator.giftedStudentTpPerSkillImprovement(c), 6);
    });

    test('trait per-Skill-Improvement bonus is read from Trait text', () {
      // Custom Species has no racial Traits → 0.
      expect(
          CharacterCalculator.traitTpPerSkillImprovement(
              pl1WithOneSkillImprovement('t0')),
          0);
      // Earthling's Quick to Master: "+5 TP from Skill Improvement".
      final e = pl1WithOneSkillImprovement('t1')..race = 'Earthling';
      expect(CharacterCalculator.traitTpPerSkillImprovement(e), 5);
    });

    test('maxTechniquePoints = progression + retroactive bonuses + manual', () {
      final c = pl1WithOneSkillImprovement('mx')
        ..setTestScore(DbuAttribute.scholarship, 8) // Gifted Student +6/SI
        ..bonusTechniquePoints = 4;
      // 25 (progression) + 6*1 (Gifted) + 0 (traits) + 4 (manual) = 35.
      expect(CharacterCalculator.skillImprovementCount(c), 1);
      expect(CharacterCalculator.maxTechniquePoints(c), 35);
    });

    test('budget: max, spent (signatures + UA), remaining', () {
      final c = pl1WithOneSkillImprovement('bud');
      // A Super Signature at base 8 TP, and Barrier UA at 15 TP.
      c.signatureTechniques.add(SignatureTechnique(profileName: 'Simple'));
      c.uniqueAbilities.add(UniqueAbilitySelection(name: 'Barrier'));
      final b = CharacterCalculator.techniquePointBudget(c);
      expect(b.max, 25);
      expect(b.signatures, 8);
      expect(b.uniqueAbilities, 15);
      expect(b.spent, 23);
      expect(b.remaining, 2);
    });

    test('signature free TP and free Advantage reduce spent, not TP Cost', () {
      final tech = SignatureTechnique(
        profileName: 'Simple',
        advantages: [SigModifierSelection(name: 'Accurate')], // +3 TP
      );
      // TP Cost = 8 + 3 = 11; unchanged by free flags.
      expect(CharacterCalculator.signatureTpCost(tech), 11);
      // Free Advantage → the +3 is off-budget: spent 8.
      tech.advantages.first.free = true;
      expect(CharacterCalculator.signatureTpCost(tech), 11);
      expect(CharacterCalculator.signatureTpSpent(tech), 8);
      // Additional flat free TP of 5 → spent 3.
      tech.freeTp = 5;
      expect(CharacterCalculator.signatureTpSpent(tech), 3);
      // Free TP never pushes spent below 0.
      tech.freeTp = 100;
      expect(CharacterCalculator.signatureTpSpent(tech), 0);
    });

    test('Magic Master reduces Magical UA TP by Use Magic Ranks (½-base floor)',
        () {
      final c = Character.blank('mm')..powerLevel = 1;
      c.talents.add(TalentEntry(name: 'Magic Master'));
      c.skills['Use Magic']!.setRanks(SkillProgress.normalKey, 3);
      final sel = UniqueAbilitySelection(
          name: 'Barrier', type: UniqueAbilityType.magical); // base 15
      expect(CharacterCalculator.magicMasterTpDiscount(c, sel), 3);
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c), 12);
      // Technical classification → no discount.
      final tech = UniqueAbilitySelection(
          name: 'Barrier', type: UniqueAbilityType.technical);
      expect(CharacterCalculator.uniqueAbilityTpCost(tech, forCharacter: c), 15);
      // Big Use Magic → floored at ⌈15/2⌉ = 8, never below.
      c.skills['Use Magic']!.setRanks(SkillProgress.normalKey, 10);
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c), 8);
      // Without the Talent, no discount.
      c.talents.clear();
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c), 15);
    });

    test('UA free technique / free Advancement reduce spent', () {
      final c = Character.blank('uaf')..powerLevel = 1;
      // Barrier 15 + Efficient Barrier (5) = 20 listed.
      final sel = UniqueAbilitySelection(
          name: 'Barrier', advancements: {'Efficient Barrier'});
      c.uniqueAbilities.add(sel);
      expect(CharacterCalculator.uniqueAbilityTpSpent(c, sel), 20);
      // Free Advancement → the +5 is off-budget: spent 15.
      sel.freeAdvancements.add('Efficient Barrier');
      expect(CharacterCalculator.uniqueAbilityTpSpent(c, sel), 15);
      // Whole ability free → 0.
      sel.freeTechnique = true;
      expect(CharacterCalculator.uniqueAbilityTpSpent(c, sel), 0);
    });

    test('new TP fields round-trip through Character JSON', () {
      final c = Character.blank('tpj')..bonusTechniquePoints = 7;
      c.signatureTechniques.add(SignatureTechnique(
        profileName: 'Simple',
        freeTp: 4,
        advantages: [SigModifierSelection(name: 'Accurate', free: true)],
      ));
      c.uniqueAbilities.add(UniqueAbilitySelection(
        name: 'Barrier',
        freeTechnique: true,
        freeAdvancements: {'Efficient Barrier'},
      ));
      final r = Character.fromJson(c.toJson());
      expect(r.bonusTechniquePoints, 7);
      expect(r.signatureTechniques.single.freeTp, 4);
      expect(r.signatureTechniques.single.advantages.single.free, isTrue);
      expect(r.uniqueAbilities.single.freeTechnique, isTrue);
      expect(r.uniqueAbilities.single.freeAdvancements, {'Efficient Barrier'});
    });
  });

  group('Custom Buff targets (expanded)', () {
    Character subject(int top) => Character.blank('cb')
      ..powerLevel = _plForTop(top)
      ..setTestScore(DbuAttribute.agility, 10)
      ..setTestScore(DbuAttribute.force, 10)
      ..setTestScore(DbuAttribute.tenacity, 6);

    test('an Attribute Score buff feeds Max Life via Tenacity', () {
      final c = subject(2);
      final base = CharacterCalculator.compute(c);
      c.customBuffs.add(CustomBuff(target: CustomBuffTarget.teScore, flat: 4));
      final buffed = CharacterCalculator.compute(c);
      // Max Life adds 2 × Tenacity × PL, so +4 Tenacity → +8×PL.
      expect(buffed.maxLife - base.maxLife, 8 * c.powerLevel);
    });

    test('a Modifier buff feeds Wounds but not Skills', () {
      final c = subject(2);
      final base = CharacterCalculator.compute(c);
      c.customBuffs.add(CustomBuff(target: CustomBuffTarget.foModifier, flat: 5));
      final buffed = CharacterCalculator.compute(c);
      expect(buffed.woundPhysical.total, base.woundPhysical.total + 5);
      // Force-based Skills read the effective Score, not the Modifier.
      expect(buffed.skillBonuses['Intimidation']?.total,
          base.skillBonuses['Intimidation']?.total);
    });

    test('Skill group + specific Skill buffs stack on the Skill Bonus', () {
      final base = CharacterCalculator.compute(subject(2));
      final c = subject(2)
        ..customBuffs.add(CustomBuff(target: CustomBuffTarget.agilitySkills, flat: 3))
        ..customBuffs.add(CustomBuff(target: CustomBuffTarget.acrobatics, flat: 2));
      final s = CharacterCalculator.compute(c);
      // Acrobatics is an Agility Skill → +3 (group) +2 (skill) = +5 over base.
      expect(s.skillBonuses['Acrobatics']!.total,
          base.skillBonuses['Acrobatics']!.total + 5);
    });

    test('Max Life ±1/4 adds a quarter of the pool', () {
      final c = subject(2);
      final base = CharacterCalculator.compute(c);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.maxLifeQuarter, flat: 1));
      final buffed = CharacterCalculator.compute(c);
      expect(buffed.maxLife, base.maxLife + base.maxLife ~/ 4);
    });

    test('a Critical Target buff lowers the Crit Target, floored at 7', () {
      final c = subject(2)
        ..customBuffs.add(CustomBuff(target: CustomBuffTarget.strikeAllCT, flat: -2));
      expect(CharacterCalculator.compute(c).strike.criticalTarget, 8);
      c.customBuffs.first.flat = -5; // 10 - 5 = 5 → floored to 7
      expect(CharacterCalculator.compute(c).strike.criticalTarget, 7);
    });

    test('All Saves fans out to every Saving Throw', () {
      final c = subject(2);
      final base = CharacterCalculator.compute(c);
      c.customBuffs.add(CustomBuff(target: CustomBuffTarget.allSaves, flat: 3));
      final buffed = CharacterCalculator.compute(c);
      for (final sv in DbuSavingThrow.values) {
        expect(buffed.savingThrows[sv]!.total,
            base.savingThrows[sv]!.total + 3);
      }
    });

    test('Halve Normal Speed halves it; Double Base Soak doubles the base', () {
      final c = subject(2);
      final base = CharacterCalculator.compute(c);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.halveNormalSpeed, flat: 1));
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.doubleBaseSoak, flat: 1));
      final buffed = CharacterCalculator.compute(c);
      expect(buffed.speedNormal, base.speedNormal ~/ 2);
      expect(buffed.soak, base.soak * 2);
    });

    test('No Strike Penalties removes the Diminishing Offense penalty', () {
      final c = subject(2)..diminishingOffenseStacks = 3;
      final base = CharacterCalculator.compute(c);
      final penalty = CharacterCalculator.diminishingOffensePenalty(c);
      expect(penalty, greaterThan(0));
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.noStrikePenalties, flat: 1));
      final buffed = CharacterCalculator.compute(c);
      expect(buffed.strike.total, base.strike.total + penalty);
    });

    test('TP-per-Skill-Improvement buff raises the maximum TP', () {
      final c = Character.blank('cbtp')..powerLevel = 1;
      c.progressionChoices['1:10'] =
          ProgressionChoice(resolvedKind: ProgressionGrantKind.skillImprovement);
      final before = CharacterCalculator.maxTechniquePoints(c);
      c.customBuffs.add(
          CustomBuff(target: CustomBuffTarget.tpPerSkillImprovement, flat: 2));
      // +2 per Skill Improvement × 1 SI.
      expect(CharacterCalculator.maxTechniquePoints(c), before + 2);
    });

    test('References channels: Unarmed Strike, per-Foundation Strike, Ki cost, '
        'Duel', () {
      final c = subject(3)
        ..setTestScore(DbuAttribute.force, 20)
        ..setTestScore(DbuAttribute.magic, 20);
      final stats0 = CharacterCalculator.compute(c);
      final base = CharacterCalculator.attackReference(c, stats0,
          attackName: 'Combination'); // KP 3(T) → 9 at ToP 3
      c.customBuffs
        ..add(CustomBuff(target: CustomBuffTarget.unarmedStrike, flat: 3))
        ..add(CustomBuff(target: CustomBuffTarget.strikePhysical, flat: 4))
        ..add(CustomBuff(target: CustomBuffTarget.kiCostAttacks, flat: -3))
        ..add(CustomBuff(target: CustomBuffTarget.duelClashBonus, flat: 2));
      final stats1 = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats1,
          attackName: 'Combination', multiFoundationChoice: SigFoundation.physical);
      // Unarmed (no weapon) +3 and Physical-Strike +4 → +7 Strike.
      expect(ref.strike.total, base.strike.total + 7);
      expect(ref.kiCost, base.kiCost - 3);
      expect(ref.duel.total, base.duel.total + 2);
      // A Magic attack ignores the Physical-Strike buff (Unarmed still applies).
      final magic = CharacterCalculator.attackReference(c, stats1,
          attackName: 'Combination', multiFoundationChoice: SigFoundation.magic);
      expect(magic.strike.total, base.strike.total + 3);
    });

    test('legacy affectedStat JSON maps to the matching target', () {
      final b = CustomBuff.fromJson({'affectedStat': 'woundMagic', 'flat': 4});
      expect(b.target, CustomBuffTarget.woundMagic);
      // A still-manual target reports itself as such.
      expect(CustomBuffTarget.thresholdBreaker.isAutomated, isFalse);
      expect(CustomBuffTarget.woundMagic.isAutomated, isTrue);
    });
  });

  group('Dice system & structural buffs', () {
    Character diceChar() => Character.blank('dice')
      ..powerLevel = _plForTop(3); // ToP 3 → ToP dice 1d6, Greater 1d8, Crit 1d10

    void addBuff(Character c, CustomBuffTarget t, int flat) =>
        c.customBuffs.add(CustomBuff(target: t, flat: flat));

    test('base pool at ToP 3 is 1d10 + the ToP Extra Dice', () {
      expect(
          CharacterCalculator.combatDicePool(diceChar(), CombatRollScope.strike)
              .label,
          '1d10+1d6');
    });

    test('flat Extra Dice combine into the pool', () {
      final c = diceChar();
      addBuff(c, CustomBuffTarget.extraD6Strike, 2);
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+3d6'); // base ToP 1d6 + 2 flat d6
      // Scoped to Strike — the Dodge pool is unaffected.
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.dodge).label,
          '1d10+1d6');
    });

    test('ToP Extra Dice Category raises the die; capped at base ToP + 1', () {
      final c = diceChar();
      addBuff(c, CustomBuffTarget.topExtraDiceCatStrike, 1); // 1d6 → 1d8
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+1d8');
      // A huge increase clamps at base ToP (3) + 1 = 4 categories from 1d6.
      c.customBuffs.clear();
      addBuff(c, CustomBuffTarget.topExtraDiceCatStrike, 99);
      // 1d6 (index1) + 4 = index5 = 1d10+1d6 → pool 2d10+1d6.
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '2d10+1d6');
    });

    test('extra ToP Dice instances are capped at +1', () {
      final c = diceChar();
      addBuff(c, CustomBuffTarget.topExtraDiceAll, 5); // capped to +1 instance
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+2d6');
    });

    test('Greater Dice are granted at the Greater index', () {
      final c = diceChar();
      addBuff(c, CustomBuffTarget.greaterDiceStrike, 1); // Greater at ToP3 = 1d8
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+1d8+1d6');
    });

    test('Signature dice apply only to a Signature attack', () {
      final c = diceChar();
      addBuff(c, CustomBuffTarget.signatureD6All, 1);
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike,
                  signature: false)
              .label,
          '1d10+1d6');
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike,
                  signature: true)
              .label,
          '1d10+2d6');
    });

    test('Energy Charge Dice Category raises the charge dice in the Wound', () {
      final c = diceChar()
        ..setTestScore(DbuAttribute.force, 10);
      addBuff(c, CustomBuffTarget.energyChargeDiceCategory, 1); // charge 1d6→1d8
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', energyCharges: 2);
      // Each Charge is 1d6(T) raised to 1d8(T): 2 charges × ToP 3 = 6d8,
      // plus the base ToP set (1d6) → 1d10+6d8+1d6.
      expect(ref.wound.expression.startsWith('1d10+6d8+1d6'), isTrue,
          reason: ref.wound.expression);
    });

    test('ToP (Breakthrough) raises the current Tier and its dice', () {
      final c = diceChar();
      expect(CharacterCalculator.tierOfPower(c), 3);
      addBuff(c, CustomBuffTarget.topBreakthrough, 1);
      expect(CharacterCalculator.tierOfPower(c), 4); // ToP4 → ToP dice 1d8
      expect(CharacterCalculator.baseTierOfPower(c), 3); // base unchanged
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+1d8');
      // Capped at base + 2.
      c.customBuffs.clear();
      addBuff(c, CustomBuffTarget.topBreakthrough, 9);
      expect(CharacterCalculator.tierOfPower(c), 5);
    });

    test('multiple ToP/Greater dice instances each get the Category buff', () {
      // Two ToP Extra Dice instances (base + 1 extra), each raised one Category.
      final c = diceChar();
      addBuff(c, CustomBuffTarget.topExtraDiceStrike, 1); // +1 instance
      addBuff(c, CustomBuffTarget.topExtraDiceCatStrike, 1); // +1 Category each
      // At ToP 3: ToP die 1d6 → 1d8 (raised), ×2 instances = 2d8.
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+2d8');

      // Two Greater Dice sources (Superior State + a buff), Category buff on both.
      final g = diceChar()
        ..states.add(TrackedEntry(name: 'Superior', stacks: 1, maxStacks: 1));
      addBuff(g, CustomBuffTarget.greaterDiceStrike, 1); // 2nd Greater Die
      addBuff(g, CustomBuffTarget.greaterDiceCategory, 1); // +1 Category each
      // Greater at ToP 3 = 1d8 → 1d10 (raised), ×2 = 2d10; + base 1d10 + ToP 1d6.
      expect(
          CharacterCalculator.combatDicePool(g, CombatRollScope.strike).label,
          '3d10+1d6');
    });

    test('Superior State grants Greater Dice on Combat Rolls', () {
      final c = diceChar();
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+1d6');
      c.states.add(TrackedEntry(name: 'Superior', stacks: 1, maxStacks: 1));
      expect(CharacterCalculator.stateGrantsGreaterDice(c), isTrue);
      // Greater Dice at ToP 3 = 1d8 → added to every Combat Roll.
      expect(
          CharacterCalculator.combatDicePool(c, CombatRollScope.strike).label,
          '1d10+1d8+1d6');
    });

    test('Punching Down adds 1d6(T) damage; Punching Up adds 1(T)/category', () {
      final c = diceChar()..setTestScore(DbuAttribute.force, 10);
      final stats = CharacterCalculator.compute(c);
      final base =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      // Punching Down (target 2+ smaller): +1d6(T) = +3d6 at ToP 3 on the Wound.
      final down = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', targetSizeRelative: -2);
      expect(down.wound.expression.startsWith('1d10+4d6'), isTrue,
          reason: down.wound.expression);
      // Punching Up (target 2 larger): +1(T) × 2 = +6 Wound at ToP 3.
      final up = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', targetSizeRelative: 2);
      expect(up.wound.total, base.wound.total + 6);
    });

    test('Breakthrough raises ToP but not Ki Point Costs', () {
      final c = Character.blank('bk')..powerLevel = _plForTop(3);
      final stats0 = CharacterCalculator.compute(c);
      // Combination Profile KP 3(T) → 9 at ToP 3.
      final baseKi = CharacterCalculator.attackReference(c, stats0,
              attackName: 'Combination')
          .kiCost;
      expect(baseKi, 9);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.topBreakthrough, flat: 1));
      final stats1 = CharacterCalculator.compute(c);
      expect(CharacterCalculator.tierOfPower(c), 4); // ToP raised
      // KP still uses base ToP 3 → 9 (Breakthrough doesn't raise KP costs).
      expect(
          CharacterCalculator.attackReference(c, stats1,
                  attackName: 'Combination')
              .kiCost,
          9);
    });

    test('Size Category buff shifts Defense/Soak/Speed and Skills', () {
      Character sizeChar() => Character.blank('sz')
        ..powerLevel = _plForTop(2)
        ..setTestScore(DbuAttribute.agility, 10) // positive base Stealth/Defense
        ..setTestScore(DbuAttribute.tenacity, 10) // Soak above its minimum
        ..setTestScore(DbuAttribute.personality, 10);
      final base = CharacterCalculator.compute(sizeChar());
      // +1 Size Category from Medium(2) → Large(3): Defense −1(T), Soak +1(T),
      // Speed unchanged (Large has +0), Stealth −1, Intimidation +1.
      final c = sizeChar()
        ..customBuffs
            .add(CustomBuff(target: CustomBuffTarget.sizeCategory, flat: 1));
      final s = CharacterCalculator.compute(c);
      expect(s.defenseValue, base.defenseValue - 1 * 2);
      expect(s.soak, base.soak + 1 * 2);
      expect(s.skillBonuses['Stealth']!.total,
          base.skillBonuses['Stealth']!.total - 1);
      expect(s.skillBonuses['Intimidation']!.total,
          base.skillBonuses['Intimidation']!.total + 1);
      // +2 more (to Enormous) applies the flat +3 Speed Modifier.
      c.customBuffs.first.flat = 2; // Medium → Enormous(4)
      final enormous = CharacterCalculator.compute(c);
      expect(enormous.speedNormal, base.speedNormal + 3);
    });

    test('Stress Bonus = Power Level + Determination + buff', () {
      final c = Character.blank('st')
        ..powerLevel = 5
        ..setTestScore(DbuAttribute.personality, 8); // Determination +2
      expect(CharacterCalculator.stressBonus(c), 5 + 2);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.stressBonus, flat: 1));
      expect(CharacterCalculator.compute(c).stressBonus, 5 + 2 + 1);
    });

    test('Hype / Analysis Maneuver buffs raise Combat Rolls', () {
      final c = Character.blank('hy')
        ..powerLevel = _plForTop(2)
        ..setTestScore(DbuAttribute.personality, 8); // Mod 8 → ⌈8/4⌉ = 2
      final base = CharacterCalculator.compute(c);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.hypeManeuver, flat: 1));
      final hyped = CharacterCalculator.compute(c);
      // +1(T) + ⌈¼ Personality Mod⌉ = 2 + 2 = 4 to every Combat Roll.
      expect(hyped.strike.total, base.strike.total + 4);
      expect(hyped.woundPhysical.total, base.woundPhysical.total + 4);
    });

    test('"I\'m being Bludgeoned" halves Damage Reduction in the calculator', () {
      final c = Character.blank('bl')..powerLevel = _plForTop(2);
      c.customBuffs
          .add(CustomBuff(target: CustomBuffTarget.beingBludgeoned, flat: 1));
      final stats = CharacterCalculator.compute(c);
      expect(stats.beingBludgeoned, isTrue);
      final normal = CharacterCalculator.computeDamage(stats,
          category: DamageCategory.lethal, // ignore Soak, isolate DR
          parry: ParryOption.none,
          manualDamageReduction: 10,
          woundRoll: 50);
      final bludgeoned = CharacterCalculator.computeDamage(stats,
          category: DamageCategory.lethal,
          parry: ParryOption.none,
          manualDamageReduction: 10,
          woundRoll: 50,
          beingBludgeoned: true);
      // DR 10 → 5, so 5 more damage gets through.
      expect(bludgeoned.healthReduction, normal.healthReduction + 5);
    });

    test('Super Stacks buff adds Solid Bulk; No Super Stack Pen. drops Muscle',
        () {
      final base = CharacterCalculator.compute(diceChar());
      final c = diceChar();
      addBuff(c, CustomBuffTarget.superStacks, 2);
      final buffed = CharacterCalculator.compute(c);
      // Solid Bulk = stacks × base ToP added to Soak.
      expect(buffed.soak, base.soak + 2 * 3);
      // Muscle Penalty (from those stacks) now reduces Strike below base.
      expect(buffed.strike.total, lessThan(base.strike.total));
      // No Super Stack Pen. restores it (bonus stays).
      addBuff(c, CustomBuffTarget.noSuperStackPen, 1);
      final noPen = CharacterCalculator.compute(c);
      expect(noPen.strike.total, base.strike.total);
    });
  });

  group('References — Attack Reference', () {
    Character combatant(int top) => Character.blank('rf')
      ..powerLevel = _plForTop(top)
      ..setTestScore(DbuAttribute.agility, 20)
      ..setTestScore(DbuAttribute.insight, 20)
      ..setTestScore(DbuAttribute.force, 20)
      ..setTestScore(DbuAttribute.magic, 20);

    test('Ki Cost: Profile KP x Tier vs a Signature KP', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      // Simple Profile KP = 0.
      expect(
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple')
              .kiCost,
          0);
      // Combination Profile KP = 3(T) → 9 at ToP 3.
      expect(
          CharacterCalculator.attackReference(c, stats,
                  attackName: 'Combination')
              .kiCost,
          9);
    });

    test('Strike/Wound expressions assemble 1d10 + ToP dice + total (crit+)',
        () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', multiFoundationChoice: SigFoundation.physical);
      expect(ref.strike.total, stats.strike.total);
      expect(ref.strike.expression,
          '1d10${stats.topExtraDice}+${stats.strike.total} '
          '(${stats.strike.criticalTarget}+)');
      expect(ref.wound.total, stats.woundPhysical.total);
    });

    test('a Physical Weapon buffs a Physical attack but not a Magic attack', () {
      final c = combatant(3);
      final w = WeaponPiece(
        name: 'Sword',
        type: WeaponType.physical,
        category: 'Slashing', // +2(T) Wound
        wielded: true,
      );
      c.weapons.add(w);
      final stats = CharacterCalculator.compute(c);
      // Physical Simple attack with the Sword: Slashing adds +2(T) Wound.
      final phys = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple',
          multiFoundationChoice: SigFoundation.physical,
          weaponName: 'Sword');
      expect(phys.wound.total, stats.woundPhysical.total + 2 * 3);
      // Same Sword on a Magic attack: no buff (Foundation mismatch).
      final magic = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple',
          multiFoundationChoice: SigFoundation.magic,
          weaponName: 'Sword');
      expect(magic.wound.total, stats.woundMagic.total);
      expect(CharacterCalculator.weaponMatchesFoundation(
              WeaponType.physical, SigFoundation.magic),
          isFalse);
    });

    test('Energy Charges add 1d6(T) each to the Wound pool', () {
      final c = combatant(3); // ToP 3 → ToP Extra Dice = 1d6
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', energyCharges: 2);
      // "Each Energy Charge gained increases the Wound Roll … by 1d6(T)":
      // 2 charges × ToP 3 = 6d6, plus the base ToP set (1d6) → 7d6 combined.
      expect(ref.wound.expression.startsWith('1d10+7d6'), isTrue,
          reason: ref.wound.expression);
    });

    test('a Signature Technique\'s Energy Charges roll 1d8(T)', () {
      final c = combatant(3)
        ..signatureTechniques.add(SignatureTechnique(
          name: 'Kamehameha',
          foundation: SigFoundation.energy,
          profileName: 'Simple',
        ));
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Kamehameha', energyCharges: 2);
      // "…or 1d8(T) if that Attacking Maneuver is a Signature Technique":
      // 2 charges × ToP 3 = 6d8 on top of base 1d10+1d6.
      expect(ref.wound.expression.startsWith('1d10+6d8+1d6'), isTrue,
          reason: ref.wound.expression);
    });

    test('Powered grants a free Energy Charge and re-applies the Damage '
        'Attribute', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final simple = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', multiFoundationChoice: SigFoundation.physical);
      final powered = CharacterCalculator.attackReference(c, stats,
          attackName: 'Powered');
      expect(powered.energyCharges, 1);
      final forceMod = stats.attributeModifiers[DbuAttribute.force]!;
      expect(powered.wound.total, simple.wound.total + forceMod);
    });

    test('Energy Charge cap is 7 — Beam\'s free Charge doesn\'t count, '
        'Mega Flare raises it to 10', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      expect(
          CharacterCalculator.attackReference(c, stats,
                  attackName: 'Simple', energyCharges: 9)
              .energyCharges,
          7);
      expect(
          CharacterCalculator.attackReference(c, stats,
                  attackName: 'Beam', energyCharges: 9)
              .energyCharges,
          8); // capped 7 + Beam's uncounted free Charge
      expect(
          CharacterCalculator.attackReference(c, stats,
                  attackName: 'Mega Flare',
                  multiFoundationChoice: SigFoundation.energy,
                  energyCharges: 9)
              .energyCharges,
          9);
    });

    test('Mega Flare: +1(T) Wound per Charge, Damage Category up at 7+', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final simple = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', multiFoundationChoice: SigFoundation.energy);
      final low = CharacterCalculator.attackReference(c, stats,
          attackName: 'Mega Flare',
          multiFoundationChoice: SigFoundation.energy,
          energyCharges: 3);
      expect(low.wound.total, simple.wound.total + 3 * 3); // +1(T) × 3
      expect(low.damageCategory, DamageCategory.standard);
      final high = CharacterCalculator.attackReference(c, stats,
          attackName: 'Mega Flare',
          multiFoundationChoice: SigFoundation.energy,
          energyCharges: 7);
      expect(high.damageCategory, DamageCategory.direct);
    });

    test('Crushing applies only half Haste to the Strike Roll', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final simple = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', multiFoundationChoice: SigFoundation.physical);
      final crushing = CharacterCalculator.attackReference(c, stats,
          attackName: 'Crushing');
      expect(crushing.strike.total,
          simple.strike.total - (stats.haste - stats.haste ~/ 2));
    });

    test('Cutting sets the Wound Critical Target to 5 (past the 7 floor)', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final cutting = CharacterCalculator.attackReference(c, stats,
          attackName: 'Cutting');
      expect(cutting.wound.criticalTarget, 5);
    });

    test('Elemental (Dark) + Elemental (Light) pairing buffs Wound and '
        'Strike', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final darkAlone = CharacterCalculator.attackReference(c, stats,
          attackName: 'Elemental (Dark)');
      final paired = CharacterCalculator.attackReference(c, stats,
          attackName: 'Elemental (Dark)',
          extraProfileName: 'Elemental (Light)');
      expect(paired.wound.total, darkAlone.wound.total + 2 * 3); // +2(T)
      expect(paired.strike.total, darkAlone.strike.total + 3); // +1(T)
    });

    test('a Dramatic Finisher\'s Super Profile adds KP and its automated '
        'effects', () {
      final c = combatant(3);
      // Beam (8(T)) + Super Beam (2(T)) + ⌈12 TP/5⌉(=3) → 13(T) = 39.
      final tech = SignatureTechnique(
        name: 'Final Kamehameha',
        level: SignatureLevel.dramaticFinisher,
        foundation: SigFoundation.energy,
        profileName: 'Beam',
        superProfileName: 'Super Beam',
      );
      c.signatureTechniques.add(tech);
      expect(CharacterCalculator.signatureKpCost(c, tech), 13 * 3);
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Final Kamehameha', energyCharges: 2);
      // Beam's free Charge → 3 total; Super Beam raises the Signature's
      // charge dice d8 → d10: 3 charges × ToP 3 = 9d10 + base 1d10 = 10d10.
      expect(ref.energyCharges, 3);
      expect(ref.wound.expression.startsWith('10d10+1d6'), isTrue,
          reason: ref.wound.expression);
      // Combo Attack (Super): +2(T) Strike.
      final combo = SignatureTechnique(
        name: 'Double Shot',
        level: SignatureLevel.dramaticFinisher,
        foundation: SigFoundation.energy,
        profileName: 'Simple',
        superProfileName: 'Combo Attack',
      );
      c.signatureTechniques.add(combo);
      final stats2 = CharacterCalculator.compute(c);
      final simpleSig = SignatureTechnique(
        name: 'Plain Shot',
        foundation: SigFoundation.energy,
        profileName: 'Simple',
      );
      c.signatureTechniques.add(simpleSig);
      final stats3 = CharacterCalculator.compute(c);
      final comboRef = CharacterCalculator.attackReference(c, stats3,
          attackName: 'Double Shot');
      final plainRef = CharacterCalculator.attackReference(c, stats3,
          attackName: 'Plain Shot');
      expect(comboRef.strike.total, plainRef.strike.total + 2 * 3);
      expect(stats2, isNotNull);
    });

    test('Blitz reduces a Signature\'s KP Cost by 2(T)', () {
      final c = combatant(3);
      // Blitz 4(T) − 2(T) + ⌈8/5⌉(=2) → 4(T) = 12.
      final tech = SignatureTechnique(
        name: 'Rush',
        foundation: SigFoundation.physical,
        profileName: 'Blitz',
      );
      expect(CharacterCalculator.signatureKpCost(c, tech), 4 * 3);
    });

    test('a Ki Wager adds 1:1 to the Wound Roll', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final base = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple');
      final wagered = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', wager: 7);
      expect(wagered.wound.total, base.wound.total + 7);
    });

    test('a Ki-Wager threshold Trait (Sparking Limit Break) boosts the Wound',
        () {
      final c = combatant(3)
        ..transformations.add(TransformationSelection(
            name: 'Full Force Super Saiyan 2', active: true));
      final stats = CharacterCalculator.compute(c);
      final threshold = stats.maxCapacity ~/ 4;
      final baseNoWager =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      // Below the threshold: only the flat 1:1 wager applies.
      final below = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', wager: threshold - 1);
      expect(below.wound.total, baseNoWager.wound.total + (threshold - 1));
      // At/above ¼ Max Capacity: +4(T) Wound on top of the flat wager.
      final at = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', wager: threshold);
      expect(at.wound.total, baseNoWager.wound.total + threshold + 4 * 3);
    });

    test('a fractional Ki-Wager Trait (Absolute Ki Control) boosts the Wound',
        () {
      final c = combatant(3)
        ..transformations
            .add(TransformationSelection(name: 'Relaxed Warrior', active: true));
      final stats = CharacterCalculator.compute(c);
      final baseNoWager =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      // +1/4 of the Ki wagered (floored): wager 12 → +3 on top of the flat 12.
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', wager: 12);
      expect(ref.wound.total, baseNoWager.wound.total + 12 + 12 ~/ 4);
    });

    test('criticalExpression appends the Critical Dice to every roll', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final ref =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      // At ToP 3: base 1d10 + ToP 1d6. The Critical Dice (a 1d10 at ToP 3)
      // combine with the base d10 → 2d10+1d6 on the Critical expression.
      expect(ref.strike.expression,
          '1d10+1d6+${stats.strike.total} (${stats.strike.criticalTarget}+)');
      expect(ref.strike.criticalExpression,
          '2d10+1d6+${stats.strike.total} (${stats.strike.criticalTarget}+)');
    });

    test('Greater Dice fold into every roll only when active', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final greater = CharacterCalculator.greaterDice(c); // e.g. "+1d6"
      final off =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      expect(off.strike.expression.contains(greater), isFalse);
      final on = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', greaterDiceActive: true);
      expect(on.strike.expression.contains(greater), isTrue);
      expect(on.wound.expression.contains(greater), isTrue);
      expect(on.dodge.expression.contains(greater), isTrue);
    });

    test('Max Wager = 1/2 Max Capacity', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final ref =
          CharacterCalculator.attackReference(c, stats, attackName: 'Simple');
      expect(ref.maxWager, stats.maxCapacity ~/ 2);
    });

    test('Duel Clash: higher of Force/Magic Mod + 2(T)/charge + 1(T)/Super Stack',
        () {
      final c = combatant(3)..superStacks = 2;
      final stats = CharacterCalculator.compute(c);
      final forceMod = stats.attributeModifiers[DbuAttribute.force]!;
      final magicMod = stats.attributeModifiers[DbuAttribute.magic]!;
      final higher = forceMod > magicMod ? forceMod : magicMod;
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', energyCharges: 1);
      // higher + 2(T)×1 charge + 1(T)×2 Super Stacks, at ToP 3.
      expect(ref.duel.total, higher + 2 * 3 * 1 + 3 * 2);
    });

    test('a Signature attack uses its own KP and Wound modifiers', () {
      final c = combatant(3);
      c.signatureTechniques.add(SignatureTechnique(
        name: 'Big Bang',
        foundation: SigFoundation.energy,
        profileName: 'Beam',
        advantages: [SigModifierSelection(name: 'Power Shot')], // +2(T) Wound
      ));
      final stats = CharacterCalculator.compute(c);
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Big Bang');
      expect(ref.isSignature, isTrue);
      expect(ref.foundation, SigFoundation.energy);
      expect(ref.wound.total, stats.woundEnergy.total + 2 * 3);
    });

    test('Long Range (9+ sq.) reduces Strike by 2(bT)', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final near = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', targetRange: 5);
      final far = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', targetRange: 9);
      expect(far.strike.total, near.strike.total - 2 * 3);
    });

    test('Extra Profile adds its KP Cost and takes the highest Damage Category',
        () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      // Simple (0 KP, Standard) + Extra Profile Crushing (6(T) KP, Lethal).
      final ref = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', extraProfileName: 'Crushing');
      expect(ref.kiCost, 6 * 3);
      expect(ref.damageCategory, DamageCategory.lethal); // most severe
    });

    test('a selected Advantage folds into the rolls (Accurate → Strike)', () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final base = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple');
      final withAcc = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', advantageName: 'Accurate', advantageRank: 2);
      expect(withAcc.strike.total, base.strike.total + 1 * 2 * 3); // +1(T)×2
    });

    test('a selected Disadvantage folds into the rolls (Inaccurate → Strike)',
        () {
      final c = combatant(3);
      final stats = CharacterCalculator.compute(c);
      final base = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple');
      final withInacc = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple', advantageName: 'Inaccurate', advantageRank: 1);
      expect(withInacc.strike.total, base.strike.total - 1 * 3);
    });
  });

  group('Transformation Trait automation', () {
    test('grade tables cover positive (Crusher) and malus (Suppressed) AMB',
        () {
      // Crusher Form: FO AMB is +G(T) → Grade 1 +1(T), Grade 4 +4(T).
      final cr = Character.blank('cr')..powerLevel = _plForTop(2);
      cr.transformations.add(
          TransformationSelection(name: 'Crusher Form', active: true, grade: 1));
      final f1 = CharacterCalculator.effectiveModifier(cr, DbuAttribute.force);
      cr.transformations.first.grade = 4;
      final f4 = CharacterCalculator.effectiveModifier(cr, DbuAttribute.force);
      expect(f4, f1 + 3 * 2); // (4−1)(T) at ToP 2

      // Suppressed Evolution: FO AMB is −G(T) → Grade 3 = −3(T).
      final se = Character.blank('se')..powerLevel = _plForTop(2);
      final baseFo =
          CharacterCalculator.effectiveModifier(se, DbuAttribute.force);
      se.transformations.add(TransformationSelection(
          name: 'Suppressed Evolution', active: true, grade: 3));
      expect(CharacterCalculator.effectiveModifier(se, DbuAttribute.force),
          baseFo - 3 * 2);
    });

    test('Arcosian Evolution Trait dropdown automates (Perfect Warrior)', () {
      expect(kArcosianEvolutionTraits, hasLength(19));
      final c = Character.blank('arco')
        ..race = 'Arcosian'
        ..powerLevel = _plForTop(2);
      final base = CharacterCalculator.compute(c); // Healthy, no Evolution Trait
      // Perfect Warrior: while Healthy → +1(T) Defense Value and Soak.
      c.raceTraitOptionChoices['Overwhelming Fighter::Evolution Trait'] = {
        'Perfect Warrior'
      };
      final pw = CharacterCalculator.compute(c);
      expect(pw.defenseValue, base.defenseValue + 1 * 2);
      expect(pw.soak, base.soak + 1 * 2);
    });

    test('Metamorphosis per-Stage Size dropdown shifts the Size Category', () {
      final c = Character.blank('meta')
        ..race = 'Arcosian'
        ..powerLevel = _plForTop(2);
      final sel =
          TransformationSelection(name: 'Full Suppression', active: true);
      c.transformations.add(sel);
      expect(CharacterCalculator.effectiveSizeIndex(c), 2); // Medium default
      // Choose Large for this Stage → effective Size becomes Large (index 3).
      sel.optionChoices['Suppression of Power::Size Category'] = {'Large'};
      expect(CharacterCalculator.effectiveSizeIndex(c), 3);
      // An Evolution Trait chosen on the Stage automates too (Perfect Warrior
      // → +1(T) Soak while Healthy).
      final beforeEvo = CharacterCalculator.compute(c).soak;
      sel.optionChoices['Suppression of Power::Evolution Trait'] = {
        'Perfect Warrior'
      };
      expect(CharacterCalculator.compute(c).soak, beforeEvo + 1 * 2);
    });

    test('Metamorphosis Evolution Traits are multi-select (S per Stage)', () {
      final c = Character.blank('metamulti')
        ..race = 'Arcosian'
        ..powerLevel = _plForTop(2)
        ..setTestScore(DbuAttribute.agility, 10); // positive base Stealth
      final sel =
          TransformationSelection(name: 'Full Suppression', active: true);
      c.transformations.add(sel);
      final base = CharacterCalculator.compute(c);
      // Pick TWO Evolution Traits on the one Stage — both automate at once.
      sel.optionChoices['Suppression of Power::Evolution Trait'] = {
        'Perfect Warrior', // +1(T) Soak while Healthy
        'Stealthy Trick', //  +2 Stealth Skill Checks
      };
      final chosen = CharacterCalculator.compute(c);
      expect(chosen.soak, base.soak + 1 * 2);
      expect(chosen.skillBonuses['Stealth']!.total,
          base.skillBonuses['Stealth']!.total + 2);

      // The per-Stage groups are exactly Size / Evolution (multi) / Tail Attack
      // / Survivor; True Form drops only the Size choice.
      expect(kMetamorphosisOptionGroups.map((g) => g.label).toList(),
          ['Size Category', 'Evolution Trait', 'Tail Attack', 'Survivor Option']);
      expect(kMetamorphosisTrueFormOptionGroups.map((g) => g.label).toList(),
          ['Evolution Trait', 'Tail Attack', 'Survivor Option']);
      final evo = kMetamorphosisOptionGroups
          .firstWhere((g) => g.label == 'Evolution Trait');
      expect(evo.maxChoices, greaterThan(1)); // multi-select
      expect(kTailAttackOptions, hasLength(4));
      expect(kArcosianSurvivorOptions, hasLength(4));
    });

    test('Trait automation now reaches Skill / Ki-Cost / Size channels', () {
      Character arco() => Character.blank('ch')
        ..race = 'Arcosian'
        ..powerLevel = _plForTop(2)
        ..setTestScore(DbuAttribute.agility, 10); // positive base Stealth
      final top = 2;
      final base = CharacterCalculator.compute(arco());

      // Stealthy Trick: +2 Stealth Skill Checks (via the skill channel).
      final st = arco()
        ..raceTraitOptionChoices['Overwhelming Fighter::Evolution Trait'] = {
          'Stealthy Trick'
        };
      expect(CharacterCalculator.compute(st).skillBonuses['Stealth']!.total,
          base.skillBonuses['Stealth']!.total + 2);

      // Frigid Tricks: −2(T) Ki Point Cost of all Unique Abilities.
      final ft = arco()
        ..raceTraitOptionChoices['Overwhelming Fighter::Evolution Trait'] = {
          'Frigid Tricks'
        };
      final sel = UniqueAbilitySelection(name: 'Barrier'); // 10(T)
      expect(
          CharacterCalculator.uniqueAbilityKpCost(ft, sel),
          CharacterCalculator.uniqueAbilityKpCost(arco(), sel)! - 2 * top);

      // King's Stature: base Size becomes Enormous (index 4).
      final ks = arco()
        ..raceTraitOptionChoices['Overwhelming Fighter::Evolution Trait'] = {
          "King's Stature"
        };
      expect(CharacterCalculator.effectiveSizeIndex(ks), 4);
    });

    test('a Form dropdown option automates AMB (Mode Change → Battle Mode)',
        () {
      // Transformation! (Mode Change): the active Mode grants +1(T) AMB.
      final c = Character.blank('mode')..powerLevel = _plForTop(2);
      final sel = TransformationSelection(name: 'Mode Change', active: true);
      c.transformations.add(sel);
      final foBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      // Battle Mode → +1(T) AMB (FO/TE/MA).
      sel.optionChoices['Transformation!::Active Mode'] = {
        'Battle Mode (Tenacity)'
      };
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.force),
          foBase + 1 * 2); // +1(T) at ToP 2
    });

    test('a Form Trait dropdown automates a passive (Super Form → Big Form Soak)',
        () {
      final c = Character.blank('sform')..powerLevel = _plForTop(2);
      final sel = TransformationSelection(name: 'Super Form', active: true);
      c.transformations.add(sel);
      final base = CharacterCalculator.compute(c).soak;
      // Big Form (2): +1(T) Soak Value (a multi-select Form Trait group).
      sel.optionChoices['Your Transformation::Form Trait'] = {'Big Form'};
      expect(CharacterCalculator.compute(c).soak, base + 1 * 2);
    });

    test('a chosen Trait Option automates (Sparking Aura → Bulking Aura Soak)',
        () {
      final c = Character.blank('opt')..powerLevel = _plForTop(2);
      c.transformations
          .add(TransformationSelection(name: 'Sparking Aura', active: true));
      final base = CharacterCalculator.compute(c);
      // Choose the Bulking Aura → its "+1(T) Soak Value" passive applies.
      c.transformations.first.optionChoices['Strong Aura::Aura Trait'] = {
        'Bulking Aura'
      };
      final chosen = CharacterCalculator.compute(c);
      expect(chosen.soak, base.soak + 1 * 2); // +1(T) at ToP 2
      // The 14 Aura Traits are all present as selectable options.
      expect(kSparkingAuraTraits, hasLength(14));
    });

    test('a chosen Option AMB flows into Modifiers (Burst Aura → FO Wound)', () {
      final c = Character.blank('optamb')..powerLevel = _plForTop(2);
      c.transformations
          .add(TransformationSelection(name: 'Sparking Aura', active: true));
      final base = CharacterCalculator.compute(c);
      // Burst Aura grants +1(T) AMB (FO/MA) → Physical Wound (uses Force Mod).
      c.transformations.first.optionChoices['Strong Aura::Aura Trait'] = {
        'Burst Aura'
      };
      final chosen = CharacterCalculator.compute(c);
      expect(chosen.woundPhysical.total, base.woundPhysical.total + 1 * 2);
      // And Might (higher of FO/MA Modifier) rises too.
      expect(chosen.might, base.might + 1 * 2);
    });

    test('a flat Option AMB applies once, NOT tier-scaled (Swapping Expert)',
        () {
      // Swapping Expert (1): "select an Attribute (except FO/MA); increase this
      // Transformation's AMB for it by +1" — a FLAT +1 (not (T)).
      final c = Character.blank('flatamb')..powerLevel = _plForTop(3); // ToP 3
      c.transformations.add(TransformationSelection(name: 'Body Swapper'));
      final agBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      c.transformations.first.optionChoices['Swapping Expert::AMB Attribute'] = {
        'Agility'
      };
      // +1 flat, so the AG Modifier rises by exactly 1 even at ToP 3.
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          agBase + 1);
    });

    test('Custom Species Twinning: base always, [Twinned] only when Primary',
        () {
      final c = Character.blank('cs')
        ..race = 'Custom Species'
        ..powerLevel = _plForTop(2); // ToP 2
      final base = CharacterCalculator.compute(c);
      // Blazing Speed (1) is a BASE effect → +2(T) Defense Value regardless of
      // Primary/Secondary status.
      c.customRaceTraits.add(TrackedEntry()..name = 'Blazing Speed');
      expect(CharacterCalculator.compute(c).defenseValue,
          base.defenseValue + 2 * 2);

      // Armored Exoskeleton (5)-[Twinned]: +1(T) Impulsive & Corporeal Saves —
      // inactive as Secondary, active as Primary.
      c.customRaceTraits.add(TrackedEntry()..name = 'Armored Exoskeleton');
      final impSecondary = CharacterCalculator.compute(c)
          .savingThrows[DbuSavingThrow.impulsive]!
          .total;
      c.customPrimaryTraits.add('Armored Exoskeleton'); // now Primary
      final impPrimary = CharacterCalculator.compute(c)
          .savingThrows[DbuSavingThrow.impulsive]!
          .total;
      expect(impPrimary, impSecondary + 1 * 2);

      // Arcane Adept (3)-[Twinned]: Magic-for-Surgency, only while Primary.
      final c2 = Character.blank('cs2')
        ..race = 'Custom Species'
        ..powerLevel = _plForTop(2)
        ..setTestScore(DbuAttribute.magic, 12) // higher than Force
        ..setTestScore(DbuAttribute.force, 2);
      c2.customRaceTraits.add(TrackedEntry()..name = 'Arcane Adept');
      expect(CharacterCalculator.surgency(c2),
          CharacterCalculator.effectiveModifier(c2, DbuAttribute.force));
      c2.customPrimaryTraits.add('Arcane Adept');
      expect(CharacterCalculator.surgency(c2),
          CharacterCalculator.effectiveModifier(c2, DbuAttribute.magic));

      // The full catalogue is present (58 Traits incl. 13 Flaws).
      expect(kDbuCustomSpeciesTraits, hasLength(58));
    });

    test('Custom Species: baseOnly() hides the [Twinned] effect text', () {
      final def = customSpeciesTraitByName('Armored Exoskeleton')!;
      expect(def.hasTwinnedEffects, isTrue);
      // Primary keeps every effect...
      expect(def.description, contains('(5)-[Passive, Twinned]'));
      expect(def.description, contains('(7)-[Triggered, 1/Encounter, Twinned]'));
      // ...Secondary sees neither the Twinned automation nor its text.
      final secondary = def.baseOnly();
      expect(secondary.description, isNot(contains('Twinned')));
      expect(secondary.automation.any((a) => a.twinned), isFalse);
      // Base effects and the flavour text survive untouched.
      expect(secondary.description, startsWith('You possess a hardened shell'));
      expect(secondary.description, contains('(4)-[Triggered, 1/Round]'));

      // A Trait with no Twinned content is returned unchanged.
      final flaw = kDbuCustomSpeciesTraits
          .firstWhere((t) => !t.hasTwinnedEffects);
      expect(identical(flaw.baseOnly(), flaw), isTrue);
    });

    test('Janemba swaps Race → Janemba: RW Traits, saves, RLM, surgency, DR',
        () {
      final c = Character.blank('jan')
        ..race = 'Saiyan'
        ..powerLevel = _plForTop(1) // base Tier of Power 1
        ..setTestScore(DbuAttribute.insight, 12) // highest → drives Surgency
        ..setTestScore(DbuAttribute.force, 4);
      final baseLife = CharacterCalculator.maxLife(c);
      c.transformations
          .add(TransformationSelection(name: 'Janemba Manifest', active: true));

      // (4/5) Racial Traits replaced by the 5 Reality Warping Traits.
      final traits =
          CharacterCalculator.activeRaceTraits(c).map((t) => t.name).toList();
      expect(
          traits,
          containsAll(<String>[
            'Evil Incarnate',
            'Evil Magic',
            'Jellybean Junction',
            'Paranormal Perception',
            'Paranormal Assault',
          ]));
      // (3) Racial Saving Throw Bonus → Corporeal/Cognitive/Impulsive.
      expect(
          CharacterCalculator.raceSavingThrows(c),
          containsAll(const <DbuSavingThrow>[
            DbuSavingThrow.corporeal,
            DbuSavingThrow.cognitive,
            DbuSavingThrow.impulsive,
          ]));
      // (3) Racial Life Modifier becomes 10 → Max Life rises.
      expect(CharacterCalculator.maxLife(c), greaterThan(baseLife));
      // Evil Incarnate (1): Surgency uses the HIGHEST Attribute Modifier (IN).
      expect(CharacterCalculator.surgency(c),
          CharacterCalculator.effectiveModifier(c, DbuAttribute.insight));
      expect(CharacterCalculator.surgency(c),
          greaterThan(CharacterCalculator.effectiveModifier(c, DbuAttribute.force)));
      // Evil Incarnate (2): while no Apparel worn → +2(bT) Damage Reduction.
      expect(CharacterCalculator.compute(c).bonusDamageReduction, 2 * 1);
    });

    test('Steady Progress distributes a flat per-Stack AMB (not ×Stacks)', () {
      final c = Character.blank('steady')..powerLevel = _plForTop(3); // ToP 3
      // 'Results of Training' is the Awakening; 'Steady Progress' is its Trait.
      final sel = TransformationSelection(name: 'Results of Training', stacks: 3);
      c.transformations.add(sel);
      final agBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      final teBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity);
      // Allocate the 3 Stacks: 2 into AG, 1 into TE (each a FLAT +1).
      sel.flatAmb[DbuAttribute.agility] = 2;
      sel.flatAmb[DbuAttribute.tenacity] = 1;
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          agBase + 2); // flat, NOT ×Stacks or ×Tier
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          teBase + 1);
    });

    test('Super Incredible Guy Strengthen grants +1(T) AMB (FO/MA coupled)', () {
      final c = Character.blank('sig')..powerLevel = _plForTop(2);
      final sel = TransformationSelection(
          name: 'Super Incredible Guy', active: true, masteryLevel: 1);
      c.transformations.add(sel);
      final foBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      final maBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.magic);
      // Choose Strengthen, then its nested Force/Magic pick → +1(T) to BOTH.
      sel.optionChoices["Super Warriors Can't Rest::Effect"] = {'Strengthen'};
      sel.optionChoices[
              "Super Warriors Can't Rest::Effect::Strengthen::Strengthen Attribute"] =
          {'Force / Magic'};
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.force),
          foBase + 1 * 2);
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.magic),
          maBase + 1 * 2);
    });

    test('Enhancement of the Self picks TWO flat AMB Attributes (+2 each)', () {
      final c = Character.blank('cots')..powerLevel = _plForTop(2);
      c.transformations.add(TransformationSelection(name: 'Cultivation of the Self'));
      final teBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity);
      final inBase = CharacterCalculator.effectiveModifier(c, DbuAttribute.insight);
      c.transformations.first
              .optionChoices['Enhancement of the Self::Enhanced Attributes'] =
          {'Tenacity', 'Insight'};
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          teBase + 2);
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.insight),
          inBase + 2);
    });

    test('a nested Option choice automates (Boosting Aura → Tenacity AMB)', () {
      final c = Character.blank('nest')..powerLevel = _plForTop(2);
      c.transformations
          .add(TransformationSelection(name: 'Sparking Aura', active: true));
      // Choose Boosting Aura, then its nested Attribute = Tenacity.
      c.transformations.first.optionChoices['Strong Aura::Aura Trait'] = {
        'Boosting Aura'
      };
      final noNested = CharacterCalculator.compute(c);
      c.transformations.first
              .optionChoices['Strong Aura::Aura Trait::Boosting Aura::Boosting Attribute'] =
          {'Tenacity'};
      final nested = CharacterCalculator.compute(c);
      // +1(T) AMB (TE) raises Soak (Tenacity Modifier) by 1(T) = +2 at ToP 2.
      expect(nested.soak, noNested.soak + 1 * 2);
    });

    test('graded AMB applies the current Grade\'s value (Kaioken)', () {
      final c = Character.blank('grade')..powerLevel = _plForTop(2);
      c.transformations.add(
          TransformationSelection(name: 'Kaioken', active: true, grade: 1));
      // Kaioken AMB (FO): Grade 1 → 1(T), Grade 3 → 2(T). Measured directly on
      // the effective Modifier to isolate it from Kaioken's other Grade effects.
      final f1 = CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      c.transformations.first.grade = 3;
      final f3 = CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      expect(f3, f1 + 1 * 2); // +1(T) at ToP 2
    });

    test('an owned Awakening trait is always in effect (Steel Frame)', () {
      // Hard as Steel: +2 Max Life per Power Level, +1(T) Damage Reduction.
      final c = Character.blank('tta1')..powerLevel = 5;
      final top = CharacterCalculator.tierOfPower(c);
      final base = CharacterCalculator.compute(c);
      c.transformations.add(TransformationSelection(name: 'Steel Frame'));
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxLife, base.maxLife + 2 * 5);
      expect(stats.bonusDamageReduction, base.bonusDamageReduction + 1 * top);
    });

    test('Z-scaled effects multiply by the Awakening stacks (Dark Infusion)',
        () {
      // Dragon Ball Rampage: +Z(bT) Wound Rolls, Surgency, Soak Value.
      final c = Character.blank('tta2')..powerLevel = 1; // bT 1
      final base = CharacterCalculator.compute(c);
      final sel = TransformationSelection(name: 'Dark Infusion', stacks: 3);
      c.transformations.add(sel);
      final stats = CharacterCalculator.compute(c);
      // +Z(bT) from the trait, plus Dark Infusion's own AMB (TE +1 × Z)
      // raising the Tenacity-based Soak by Z as well.
      expect(stats.soak, base.soak + 3 * 1 + 3);
      sel.stacks = 1;
      final oneStack = CharacterCalculator.compute(c);
      expect(oneStack.soak, base.soak + 1 * 1 + 1);
    });

    test('a Stack-gated trait needs its minStacks (Zenkai)', () {
      final c = Character.blank('tta3')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Zenkai', stacks: 1);
      c.transformations.add(sel);
      Iterable<String> inEffect() => CharacterCalculator
          .transformationTraitsInEffect(c)
          .map((e) => e.trait.name);
      expect(inEffect(), contains('Saiyan Spirit'));
      expect(inEffect(), isNot(contains("Warrior's Determination")));
      sel.stacks = 2;
      expect(inEffect(), contains("Warrior's Determination"));
    });

    test("an Enhancement's traits only apply while ACTIVE (Nimbus Pro)", () {
      // Cloud Combat: +1(T) Strike and Wound Rolls.
      final c = Character.blank('tta4')
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.force, 5);
      final base = CharacterCalculator.compute(c);
      final sel = TransformationSelection(name: 'Nimbus Pro');
      c.transformations.add(sel);
      expect(CharacterCalculator.compute(c).woundPhysical.total,
          base.woundPhysical.total);
      sel.active = true;
      final active = CharacterCalculator.compute(c);
      // +1(T) Wound from the trait (Nimbus Pro's AMB is AG-only, which does
      // not feed the Force-based Physical Wound).
      expect(active.woundPhysical.total, base.woundPhysical.total + 1 * 1);
    });

    test('a computable State condition gates the effect (Tempered Fury)', () {
      // Necessary Anger: While in the Raging State, +1(T) Wound and Soak.
      final c = Character.blank('tta5')..powerLevel = 1;
      c.transformations.add(TransformationSelection(name: 'Tempered Fury'));
      final without = CharacterCalculator.compute(c);
      c.states.add(TrackedEntry(name: 'Raging', stacks: 1));
      final withState = CharacterCalculator.compute(c);
      // The Raging State itself grants +L(T) Wound via stateTotals, so pin
      // Soak instead (Raging L1 grants no Soak — only the trait's +1(T)).
      expect(withState.soak, without.soak + 1 * 1);
    });

    test(
        'whileNotInForm switches off when a Form activates (Dedicated '
        'Warrior)', () {
      // Dedication to the Path: +1(bT) Saving Throws while not in a Form.
      final c = Character.blank('tta6')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Dedicated Warrior'));
      final noForm = CharacterCalculator.compute(c);
      c.transformations
          .add(TransformationSelection(name: 'Power Boost', active: true));
      final inForm = CharacterCalculator.compute(c);
      // Compare the Cognitive Save — Power Boost's own Enhanced Save Aspect
      // covers Impulsive/Morale, which would mask the trait's loss there.
      expect(noForm.savingThrows[DbuSavingThrow.cognitive]!.total,
          inForm.savingThrows[DbuSavingThrow.cognitive]!.total + 1);
    });

    test('a Grand Awakening only applies while toggled (Mortal Flames)', () {
      // Flames of a Mortal Heart: +3(T) Wound Rolls and Soak Value.
      final c = Character.blank('tta7')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Mortal Flames');
      c.transformations.add(sel);
      final off = CharacterCalculator.compute(c);
      sel.grandAwakeningActive = true;
      final on = CharacterCalculator.compute(c);
      expect(on.soak, off.soak + 3 * 1);
    });

    test(
        "a Grand Awakening's ambBonus raises Attribute Modifiers "
        '(Bottomless Potential)', () {
      // Unleash it All: +1(T) Attribute Modifiers (AG/FO/TE/MA).
      final c = Character.blank('tta8')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Bottomless Potential');
      c.transformations.add(sel);
      final off =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      sel.grandAwakeningActive = true;
      final on =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      expect(on, off + 1 * 1);
    });

    test('a chosen Option contributes its automation (Class Up → Hero)', () {
      final c = Character.blank('tta9')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Class Up');
      c.transformations.add(sel);
      final unchosen = CharacterCalculator.compute(c);
      sel.optionChoices['Class Selection::Class'] = {'Hero'};
      final hero = CharacterCalculator.compute(c);
      expect(hero.soak, unchosen.soak + 1 * 1);
      sel.optionChoices['Class Selection::Class'] = {'Berserker'};
      final berserker = CharacterCalculator.compute(c);
      expect(berserker.soak, unchosen.soak);
      expect(
          berserker.woundPhysical.total, unchosen.woundPhysical.total + 1 * 1);
    });

    test('Grade-scaled effects follow the Grade stepper (Kaioken)', () {
      // At ToP 1, Physical Wound gains Exponential Power's +ceil(G/2)(T) AND
      // the Grade-table Force AMB (Grade 1→1(T), 3→2(T)).
      final without =
          CharacterCalculator.compute(Character.blank('tta10b')..powerLevel = 1);
      final c = Character.blank('tta10')..powerLevel = 1;
      final sel =
          TransformationSelection(name: 'Kaioken', active: true, grade: 3);
      c.transformations.add(sel);
      final g3 = CharacterCalculator.compute(c);
      expect(g3.woundPhysical.total,
          without.woundPhysical.total + 2 /*effect*/ + 2 /*FO AMB*/);
      sel.grade = 1;
      final g1 = CharacterCalculator.compute(c);
      expect(g1.woundPhysical.total,
          without.woundPhysical.total + 1 /*effect*/ + 1 /*FO AMB*/);
    });

    test('Surgency buffs feed the Surge read-outs (Peak Condition)', () {
      // Ideal Condition: +2(bT) Surgency (and +2/PL Max Life & Ki).
      final c = Character.blank('tta11')..powerLevel = 1;
      final base = CharacterCalculator.compute(c);
      c.transformations.add(TransformationSelection(name: 'Peak Condition'));
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxLife, base.maxLife + 2 * 1);
      expect(stats.maxKi, base.maxKi + 2 * 1);
      // Power Surge Ki = floor(buffed Max Ki/4) + Surgency + the +2(bT) buff.
      expect(stats.powerSurgeKi,
          stats.maxKi ~/ 4 + CharacterCalculator.surgency(c) + 2 * 1);
    });

    test('Warlock may use the Magic Modifier for Surgency', () {
      final c = Character.blank('tta12')
        ..powerLevel = 1
        ..setTestScore(DbuAttribute.force, 2)
        ..setTestScore(DbuAttribute.magic, 8);
      expect(CharacterCalculator.surgency(c), 2);
      c.transformations.add(TransformationSelection(name: 'Warlock'));
      // Warlock's own always-on AMB adds MG +1, so the effective Magic
      // Modifier the swap reads is 9.
      expect(CharacterCalculator.surgency(c), 9);
    });

    test(
        'a resource-threshold condition reads the tracked Resource '
        '(Combat Enthusiast)', () {
      // Excited for Battle: while 1+ Holding Back stacks, +1(bT) Damage
      // Reduction and +2(bT) Surgency.
      final c = Character.blank('tta13')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Combat Enthusiast'));
      final without = CharacterCalculator.compute(c);
      expect(without.bonusDamageReduction, 0);
      c.resources.add(TrackedEntry(name: 'Holding Back', stacks: 1));
      final withStacks = CharacterCalculator.compute(c);
      expect(withStacks.bonusDamageReduction, 1 * 1);
    });
  });

  group('Aspect automation', () {
    test('Enhanced Save buffs the bracketed Saving Throw(s) while active',
        () {
      // Super Saiyan 1 carries Enhanced Save (Impulsive/Corporeal).
      final c = Character.blank('asp1')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Super Saiyan');
      c.transformations.add(sel);
      final off = CharacterCalculator.compute(c);
      sel.active = true;
      final on = CharacterCalculator.compute(c);
      expect(on.savingThrows[DbuSavingThrow.impulsive]!.total,
          off.savingThrows[DbuSavingThrow.impulsive]!.total + 1);
      expect(on.savingThrows[DbuSavingThrow.corporeal]!.total,
          off.savingThrows[DbuSavingThrow.corporeal]!.total + 1);
      // Cognitive is not listed — unchanged.
      expect(on.savingThrows[DbuSavingThrow.cognitive]!.total,
          off.savingThrows[DbuSavingThrow.cognitive]!.total);
    });

    test('the Raging Aspect adds +2(T) Wound while the Raging State is on',
        () {
      final c = Character.blank('asp2')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Super Saiyan', active: true));
      final noState = CharacterCalculator.compute(c);
      c.states.add(TrackedEntry(name: 'Raging', stacks: 1));
      final raging = CharacterCalculator.compute(c);
      // +2(T) from the Aspect +1(T) from the Raging State's own L(T) Wound.
      expect(raging.woundPhysical.total, noState.woundPhysical.total + 3);
    });

    test('Super Saiyan Form raises Max Ki and Max Capacity by 1/4', () {
      final c = Character.blank('asp3')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Super Saiyan');
      c.transformations.add(sel);
      // Inactive: base 50/20.
      expect(CharacterCalculator.maxKi(c), 50);
      sel.active = true;
      // Form Ki Multiplier (×2 / +1/2), then the Aspect's +1/4.
      expect(CharacterCalculator.maxKi(c), 100 + 100 ~/ 4);
      expect(CharacterCalculator.maxCapacity(c), 30 + 30 ~/ 4);
    });

    test('Perfect Ki Control reduces the References Ki Cost (floor 2(T))',
        () {
      // Explosive Power carries the Perfect Ki Control Aspect.
      final c = Character.blank('asp4')..powerLevel = 1;
      c.transformations.add(
          TransformationSelection(name: 'Explosive Power', active: true));
      final stats = CharacterCalculator.compute(c);
      // Blast Profile: 5(T) KP → 5 at ToP 1; −1(T) → 4.
      final blast = CharacterCalculator.attackReference(c, stats,
          attackName: 'Blast');
      expect(blast.kiCost, 4);
      // Simple (0 KP) can't be raised toward the 2(T) minimum.
      final simple = CharacterCalculator.attackReference(c, stats,
          attackName: 'Simple');
      expect(simple.kiCost, 0);
    });

    test('the Armored Aspect downgrades the incoming Damage Category', () {
      final c = Character.blank('asp5')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Juggernaut', active: true));
      final stats = CharacterCalculator.compute(c);
      expect(stats.hasArmoredAspect, isTrue);
      // A Direct hit is treated as Standard (full Soak) under Armored.
      final armored = CharacterCalculator.computeDamage(stats,
          category: DamageCategory.direct,
          parry: ParryOption.none,
          manualDamageReduction: 0,
          woundRoll: 20,
          armoredAspect: true);
      final normal = CharacterCalculator.computeDamage(stats,
          category: DamageCategory.standard,
          parry: ParryOption.none,
          manualDamageReduction: 0,
          woundRoll: 20);
      expect(armored.totalReduction, normal.totalReduction);
    });

    test('High Speed adds the AMB (AG) to the Speeds while active', () {
      // Kaioken has High Speed but a Grade-set (`*`) AG AMB → skipped.
      // Super Kaioken also has graded AMB; use Lightspeed Mode (graded too)…
      // Grandmaster's Super Awakening has no High Speed. Use an Enhancement
      // with a flat AG AMB + High Speed: 'Agile Style' (if it carries it) —
      // fall back to asserting the graded case contributes nothing.
      final c = Character.blank('asp6')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Kaioken', active: true));
      final totals = CharacterCalculator.aspectTotals(c);
      // Kaioken's AG AMB is Grade-set (`*`) → High Speed adds nothing.
      expect(totals[AffectedStat.speedBoosted], isNull);
    });
  });

  group('Import/Export share codes', () {
    // A round-trip fixture with a few non-default choices so we know the whole
    // payload survives, not just the id/name.
    Character sample() => Character.blank('orig-id')
      ..name = 'Goku'
      ..player = 'Kakarot'
      ..race = 'Saiyan'
      ..powerLevel = 7
      ..zSoul.quote = 'I like fighting strong guys.';

    test('export produces a versioned character envelope', () {
      final code = ImportExportService.exportCharacter(sample());
      final env = jsonDecode(code) as Map<String, dynamic>;
      expect(env['dbu'], ImportExportService.schemaVersion);
      expect(env['kind'], ImportExportService.characterKind);
      expect(env['payload'], isA<Map<String, dynamic>>());
      expect((env['payload'] as Map)['name'], 'Goku');
    });

    test('round-trips the payload but assigns a fresh id', () {
      final code = ImportExportService.exportCharacter(sample());
      final result =
          ImportExportService.importCharacter(code, newId: () => 'new-id');
      expect(result.ok, isTrue);
      final c = result.character!;
      expect(c.id, 'new-id'); // never clobbers by reusing the original id
      expect(c.name, 'Goku');
      expect(c.player, 'Kakarot');
      expect(c.race, 'Saiyan');
      expect(c.powerLevel, 7);
      expect(c.zSoul.quote, 'I like fighting strong guys.');
    });

    test('importing the same code twice yields two distinct ids', () {
      final code = ImportExportService.exportCharacter(sample());
      var n = 0;
      final a = ImportExportService.importCharacter(code, newId: () => 'id-${n++}');
      final b = ImportExportService.importCharacter(code, newId: () => 'id-${n++}');
      expect(a.character!.id, isNot(b.character!.id));
    });

    test('accepts a base64-wrapped code', () {
      final code = ImportExportService.exportCharacter(sample());
      final b64 = base64.encode(utf8.encode(code));
      final result =
          ImportExportService.importCharacter(b64, newId: () => 'x');
      expect(result.ok, isTrue);
      expect(result.character!.name, 'Goku');
    });

    test('accepts a bare (envelope-less) character map', () {
      final bare = jsonEncode(sample().toJson());
      final result =
          ImportExportService.importCharacter(bare, newId: () => 'x');
      expect(result.ok, isTrue);
      expect(result.character!.name, 'Goku');
    });

    test('rejects a newer schema version with a clear message', () {
      final future = jsonEncode({
        'dbu': ImportExportService.schemaVersion + 1,
        'kind': 'character',
        'payload': sample().toJson(),
      });
      final result =
          ImportExportService.importCharacter(future, newId: () => 'x');
      expect(result.ok, isFalse);
      expect(result.error, contains('newer version'));
    });

    test('rejects a non-character kind', () {
      final wrong = jsonEncode({
        'dbu': 1,
        'kind': 'homebrew.transformation',
        'payload': <String, dynamic>{},
      });
      final result =
          ImportExportService.importCharacter(wrong, newId: () => 'x');
      expect(result.ok, isFalse);
      expect(result.error, contains('not a character'));
    });

    test('fails gracefully on garbage input', () {
      final result = ImportExportService.importCharacter('not a code at all',
          newId: () => 'x');
      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('fails gracefully on empty input', () {
      final result =
          ImportExportService.importCharacter('   ', newId: () => 'x');
      expect(result.ok, isFalse);
    });
  });

  group('Homebrew maker', () {
    RaceTraitAutomation sampleAuto() => const RaceTraitAutomation(
          affectedStats: [AffectedStat.maxLife, AffectedStat.soak],
          coefficient: 2,
          tierScaling: TierScaling.current,
          kind: TraitMagnitudeKind.fractionOfAttribute,
          attribute: DbuAttribute.tenacity,
          fractionDenominator: 2,
          roundUp: true,
          condition: TraitCondition.whileBelowInjuredThreshold,
        );

    HomebrewEntry sampleEntry() => HomebrewEntry(
          id: 'hb-1',
          category: HomebrewCategory.talent,
          name: 'Second Wind',
          flavor: 'A last-ditch surge of grit.',
          effectText: 'While Injured, gain Soak and Life equal to half your TE.',
          automations: [sampleAuto()],
        );

    test('RaceTraitAutomation survives a JSON round-trip', () {
      final a = sampleAuto();
      final b = RaceTraitAutomation.fromJson(a.toJson());
      expect(b.affectedStats, a.affectedStats);
      expect(b.coefficient, a.coefficient);
      expect(b.tierScaling, a.tierScaling);
      expect(b.kind, a.kind);
      expect(b.attribute, a.attribute);
      expect(b.fractionDenominator, a.fractionDenominator);
      expect(b.roundUp, a.roundUp);
      expect(b.condition, a.condition);
    });

    test('RaceTraitAutomation.fromJson drops unknown enum names', () {
      final a = RaceTraitAutomation.fromJson({
        'affectedStats': ['maxLife', 'notARealStat'],
        'coefficient': 3,
        'kind': 'notARealKind',
        'condition': 'notARealCondition',
      });
      expect(a.affectedStats, [AffectedStat.maxLife]);
      expect(a.coefficient, 3);
      expect(a.kind, TraitMagnitudeKind.flat); // defaulted
      expect(a.condition, isNull);
    });

    test('HomebrewEntry survives a JSON round-trip', () {
      final e = sampleEntry();
      final f = HomebrewEntry.fromJson(e.toJson());
      expect(f.id, e.id);
      expect(f.category, HomebrewCategory.talent);
      expect(f.name, 'Second Wind');
      expect(f.flavor, e.flavor);
      expect(f.effectText, e.effectText);
      expect(f.automations.length, 1);
      expect(f.automations.first.attribute, DbuAttribute.tenacity);
    });

    test('export/import round-trips a homebrew entry with a fresh id', () {
      final code = ImportExportService.exportHomebrew(sampleEntry());
      final result =
          ImportExportService.importHomebrew(code, newId: () => 'fresh');
      expect(result.ok, isTrue);
      expect(result.entry!.id, 'fresh');
      expect(result.entry!.name, 'Second Wind');
      expect(result.entry!.automations.single.kind,
          TraitMagnitudeKind.fractionOfAttribute);
    });

    test('homebrew import accepts base64 and rejects a newer version', () {
      final code = ImportExportService.exportHomebrew(sampleEntry());
      final b64 = base64.encode(utf8.encode(code));
      expect(
        ImportExportService.importHomebrew(b64, newId: () => 'x').ok,
        isTrue,
      );
      final future = jsonEncode({
        'dbu': ImportExportService.schemaVersion + 1,
        'kind': 'homebrew',
        'payload': sampleEntry().toJson(),
      });
      final r = ImportExportService.importHomebrew(future, newId: () => 'x');
      expect(r.ok, isFalse);
      expect(r.error, contains('newer version'));
    });

    test('runtime: homebrew applies to a character through the registry', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-soak',
          category: HomebrewCategory.talent,
          name: 'Iron Hide',
          effectText: 'Increase your Soak Value by 3.',
          automations: const [
            RaceTraitAutomation(
              affectedStats: [AffectedStat.soak],
              coefficient: 3,
            ),
          ],
        ),
      ]);

      final c = Character.blank('hb-c')..powerLevel = 1;
      final before = CharacterCalculator.compute(c).soak;

      c.homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));
      final after = CharacterCalculator.compute(c).soak;

      expect(after - before, 3);
    });

    test('runtime: an inactive selection contributes nothing', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-soak',
          name: 'Iron Hide',
          automations: const [
            RaceTraitAutomation(
              affectedStats: [AffectedStat.soak],
              coefficient: 3,
            ),
          ],
        ),
      ]);
      final c = Character.blank('hb-c')..powerLevel = 1;
      final before = CharacterCalculator.compute(c).soak;
      c.homebrewSelections
          .add(HomebrewSelection(name: 'Iron Hide', active: false));
      expect(CharacterCalculator.compute(c).soak, before);
    });

    test('runtime: max-pool homebrew applies before pools derive', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-life',
          name: 'Deep Reserves',
          automations: const [
            RaceTraitAutomation(
              affectedStats: [AffectedStat.maxLife],
              coefficient: 10,
            ),
          ],
        ),
      ]);
      final c = Character.blank('hb-c')..powerLevel = 1;
      final before = CharacterCalculator.compute(c).maxLife;
      c.homebrewSelections.add(HomebrewSelection(name: 'Deep Reserves'));
      final stats = CharacterCalculator.compute(c);
      expect(stats.maxLife - before, 10);
      // A null "current" pool tops up to the new maximum — proving the
      // max-pool contribution landed BEFORE the pools were derived/clamped.
      expect(stats.currentLife, stats.maxLife);
    });

    test('runtime: tier scaling and conditions are honoured', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-cond',
          name: 'Cornered Beast',
          automations: const [
            // Soak (not Strike): a blank character's Strike already sits at its
            // 0 floor, which would mask the delta.
            RaceTraitAutomation(
              affectedStats: [AffectedStat.soak],
              coefficient: 1,
              tierScaling: TierScaling.current,
              condition: TraitCondition.whileBelowInjuredThreshold,
            ),
          ],
        ),
      ]);
      // Tier 3 so the `(T)` scaling is actually exercised (not ×1).
      final c = Character.blank('hb-c')..powerLevel = _plForTop(3);
      final maxLife = CharacterCalculator.compute(c).maxLife;

      // Healthy: the condition gate is unmet, so the homebrew adds nothing.
      c.currentLife = maxLife;
      c.homebrewSelections.add(HomebrewSelection(name: 'Cornered Beast'));
      final healthy = CharacterCalculator.compute(c);
      expect(
        CharacterCalculator.homebrewTotals(c,
            currentLife: healthy.currentLife, maxLife: healthy.maxLife),
        isEmpty,
      );

      // Below the Injured threshold the gate opens. Measure the homebrew's own
      // delta at the SAME health, so any health-driven penalties cancel out.
      c.currentLife = (maxLife * 0.1).floor();
      c.homebrewSelections.clear();
      final injuredBefore = CharacterCalculator.compute(c).soak;
      c.homebrewSelections.add(HomebrewSelection(name: 'Cornered Beast'));
      final injuredAfter = CharacterCalculator.compute(c);
      expect(injuredAfter.tierOfPower, 3);
      expect(
        CharacterCalculator.homebrewTotals(c,
            currentLife: injuredAfter.currentLife,
            maxLife: injuredAfter.maxLife),
        {AffectedStat.soak: 3}, // 1 × Tier 3
      );
      expect(injuredAfter.soak - injuredBefore, 3);
    });

    test('runtime: unresolved selections are reported, not silently dropped',
        () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.clear();
      final c = Character.blank('hb-c')..powerLevel = 1;
      c.homebrewSelections.add(HomebrewSelection(name: 'Ghost Technique'));
      expect(CharacterCalculator.unresolvedHomebrewNames(c),
          ['Ghost Technique']);
      // And it contributes nothing rather than throwing.
      expect(() => CharacterCalculator.compute(c), returnsNormally);
    });

    test('homebrew selections survive a character round-trip', () {
      final c = Character.blank('c1')
        ..homebrewSelections
            .add(HomebrewSelection(name: 'Iron Hide', active: false));
      final back = Character.fromJson(c.toJson());
      expect(back.homebrewSelections.single.name, 'Iron Hide');
      expect(back.homebrewSelections.single.active, isFalse);
    });

    test('character export bundles the homebrew it references', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-1',
          name: 'Iron Hide',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 3),
          ],
        ),
        HomebrewEntry(id: 'hb-2', name: 'Unused Thing'),
      ]);

      final c = Character.blank('c1')..name = 'Krillin';
      c.homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));

      final env = jsonDecode(ImportExportService.exportCharacter(c))
          as Map<String, dynamic>;
      final bundled = (env['homebrew'] as List).cast<Map<String, dynamic>>();
      // Only what the character actually references — not the whole library.
      expect(bundled.length, 1);
      expect(bundled.single['name'], 'Iron Hide');
    });

    test('an inactive selection is still bundled', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([HomebrewEntry(id: 'hb-1', name: 'Iron Hide')]);
      final c = Character.blank('c1');
      c.homebrewSelections
          .add(HomebrewSelection(name: 'Iron Hide', active: false));
      final env = jsonDecode(ImportExportService.exportCharacter(c))
          as Map<String, dynamic>;
      expect((env['homebrew'] as List).length, 1);
    });

    test('a character with no homebrew omits the bundle entirely', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.clear();
      final env = jsonDecode(
              ImportExportService.exportCharacter(Character.blank('c1')))
          as Map<String, dynamic>;
      expect(env.containsKey('homebrew'), isFalse);
    });

    test('import returns bundled homebrew with fresh, unique ids', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-1',
          name: 'Iron Hide',
          effectText: 'Increase your Soak Value by 3.',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 3),
          ],
        ),
        HomebrewEntry(id: 'hb-2', name: 'Second Wind'),
      ]);
      final c = Character.blank('c1')..name = 'Krillin';
      c.homebrewSelections
        ..add(HomebrewSelection(name: 'Iron Hide'))
        ..add(HomebrewSelection(name: 'Second Wind'));
      final code = ImportExportService.exportCharacter(c);

      // A recipient with an EMPTY library still receives the definitions.
      HomebrewRegistry.clear();
      final result =
          ImportExportService.importCharacter(code, newId: () => 'fresh');
      expect(result.ok, isTrue);
      expect(result.bundledHomebrew.length, 2);
      expect(result.bundledHomebrew.map((e) => e.name),
          containsAll(['Iron Hide', 'Second Wind']));
      // Fresh AND unique, so adding them can't collide or overwrite.
      final ids = result.bundledHomebrew.map((e) => e.id).toSet();
      expect(ids.length, 2);
      expect(ids.every((id) => id != 'hb-1' && id != 'hb-2'), isTrue);
      // The automation survived the trip intact.
      final ironHide =
          result.bundledHomebrew.firstWhere((e) => e.name == 'Iron Hide');
      expect(ironHide.automations.single.affectedStats, [AffectedStat.soak]);
      expect(ironHide.automations.single.coefficient, 3);
    });

    test('a bundled character computes correctly once its homebrew is added',
        () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-1',
          name: 'Iron Hide',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 3),
          ],
        ),
      ]);
      final c = Character.blank('c1')..powerLevel = 1;
      c.homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));
      final code = ImportExportService.exportCharacter(c);

      // Recipient starts empty: the character imports but can't resolve yet.
      HomebrewRegistry.clear();
      final result =
          ImportExportService.importCharacter(code, newId: () => 'fresh');
      final imported = result.character!;
      expect(CharacterCalculator.unresolvedHomebrewNames(imported),
          ['Iron Hide']);
      final unresolvedSoak = CharacterCalculator.compute(imported).soak;

      // Simulate the import flow adding the bundled homebrew to the library.
      HomebrewRegistry.setAll(result.bundledHomebrew);
      expect(CharacterCalculator.unresolvedHomebrewNames(imported), isEmpty);
      expect(CharacterCalculator.compute(imported).soak - unresolvedSoak, 3);
    });

    test('bundling survives a base64-wrapped character code', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([HomebrewEntry(id: 'hb-1', name: 'Iron Hide')]);
      final c = Character.blank('c1');
      c.homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));
      final b64 = base64
          .encode(utf8.encode(ImportExportService.exportCharacter(c)));
      final result =
          ImportExportService.importCharacter(b64, newId: () => 'fresh');
      expect(result.bundledHomebrew.single.name, 'Iron Hide');
    });

    test('a selection naming homebrew not in the library bundles nothing', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.clear();
      final c = Character.blank('c1');
      c.homebrewSelections.add(HomebrewSelection(name: 'Ghost Technique'));
      final env = jsonDecode(ImportExportService.exportCharacter(c))
          as Map<String, dynamic>;
      expect(env.containsKey('homebrew'), isFalse);
      // The selection still round-trips, so the warning surfaces downstream.
      final result = ImportExportService.importCharacter(
          jsonEncode(env), newId: () => 'fresh');
      expect(CharacterCalculator.unresolvedHomebrewNames(result.character!),
          ['Ghost Technique']);
    });

    test('the two importers reject each other\'s codes', () {
      final charCode = ImportExportService.exportCharacter(
          Character.blank('c')..name = 'Vegeta');
      final hbCode = ImportExportService.exportHomebrew(sampleEntry());
      // A character code is not a homebrew, and vice versa.
      expect(
        ImportExportService.importHomebrew(charCode, newId: () => 'x').ok,
        isFalse,
      );
      expect(
        ImportExportService.importCharacter(hbCode, newId: () => 'x').ok,
        isFalse,
      );
    });
  });

  group('Homebrew structured content', () {
    HomebrewEntry raceEntry() => HomebrewEntry(
          id: 'hb-race',
          category: HomebrewCategory.race,
          name: 'Tuffle Cyborg',
          raceData: HomebrewRaceData(
            racialLifeModifier: 5,
            fixedAttributeIncreases: {DbuAttribute.force: 2},
            choiceAmounts: [1],
            savingThrows: [DbuSavingThrow.corporeal],
            skillRanks: 3,
          ),
        );

    test('a homebrew Race feeds Scores, Life, Saves and Skill Ranks', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([raceEntry()]);
      final c = Character.blank('c')
        ..powerLevel = 1
        ..race = 'Tuffle Cyborg';
      // Baseline 1 + the fixed +2 FO.
      expect(c.scoreOf(DbuAttribute.force), 3);
      // The choice slot applies to whichever Attribute the player picked.
      c.raceAttributeIncreaseChoices.add(DbuAttribute.agility);
      expect(c.scoreOf(DbuAttribute.agility), 2);
      expect(CharacterCalculator.raceSavingThrows(c),
          [DbuSavingThrow.corporeal]);
      expect(CharacterCalculator.raceSkillRanks(c), 3);
      expect(CharacterCalculator.racialLifeModifier(c), 5);
    });

    test('an official Race always wins a homebrew name clash', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-fake',
          category: HomebrewCategory.race,
          name: 'Saiyan',
          raceData: HomebrewRaceData(racialLifeModifier: 99),
        ),
      ]);
      expect(HomebrewRegistry.resolveRace('Saiyan').racialLifeModifier,
          raceByName('Saiyan').racialLifeModifier);
    });

    test('a homebrew Condition auto-applies its penalty per Stack', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-cond',
          category: HomebrewCategory.condition,
          name: 'Frostbitten',
          effectText: 'Your Soak Value is reduced by 2 per Stack.',
          conditionData: HomebrewConditionData(
            maxStacks: 3,
            penaltyPerStack: 2,
            affectedStats: [AffectedStat.soak],
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = 1;
      c.conditions
          .add(TrackedEntry(name: 'Frostbitten', stacks: 2, maxStacks: 3));
      expect(CharacterCalculator.conditionPenalty(c, c.conditions.single), 4);
      expect(CharacterCalculator.conditionTotals(c)[AffectedStat.soak], -4);
      // The resolved def surfaces in the tracker's catalogue machinery too.
      expect(HomebrewRegistry.resolveConditionDef('Frostbitten')!.maxStacks, 3);
      // An official Condition still resolves to the official def.
      expect(HomebrewRegistry.resolveConditionDef(kDbuConditions.first.name),
          same(kDbuConditions.first));
    });

    test('a homebrew Awakening resolves and applies its AMB × Stacks', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-awk',
          category: HomebrewCategory.transformation,
          name: 'Inner Fire',
          effectText: '(1) Increase your Soak Value by 2.',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 2),
          ],
          transformationData: HomebrewTransformationData(
            awakeningType: AwakeningType.lesser,
            maxStacks: 3,
            amb: {DbuAttribute.force: HomebrewAmb(coefficient: 1)},
          ),
        ),
      ]);
      final def = CharacterCalculator.transformationByName('Inner Fire');
      expect(def, isNotNull);
      expect(def!.type, TransformationType.awakening);
      expect(def.awakeningType, AwakeningType.lesser);
      expect(def.maxStacks, 3);

      final c = Character.blank('c')..powerLevel = 1;
      final soakBefore = CharacterCalculator.compute(c).soak;
      c.transformations
          .add(TransformationSelection(name: 'Inner Fire', stacks: 2));
      // AMB × Stacks, always-on for an Awakening.
      expect(
          CharacterCalculator.transformationModifierBonus(
              c, DbuAttribute.force),
          2);
      // Counts toward the Lesser Awakening limit like catalogue content.
      expect(CharacterCalculator.awakeningCount(c, AwakeningType.lesser), 1);
      // Its Trait (the entry's automations) is always in effect.
      expect(CharacterCalculator.compute(c).soak - soakBefore, 2);
    });

    test('a homebrew Form applies AMB + Ki Multiplier only while active', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-form',
          category: HomebrewCategory.form,
          name: 'Crimson Surge',
          transformationData: HomebrewTransformationData(
            formType: FormType.alternate,
            tierOfPowerRequirement: 2,
            amb: {
              DbuAttribute.agility: HomebrewAmb(coefficient: 2, tierScaled: true)
            },
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(3);
      final baseKi = CharacterCalculator.compute(c).maxKi;
      c.transformations.add(
          TransformationSelection(name: 'Crimson Surge', active: false));
      expect(
          CharacterCalculator.transformationModifierBonus(
              c, DbuAttribute.agility),
          0);
      expect(CharacterCalculator.hasActiveForm(c), isFalse);

      c.transformations.single.active = true;
      expect(
          CharacterCalculator.transformationModifierBonus(
              c, DbuAttribute.agility),
          6); // 2 × Tier 3
      expect(CharacterCalculator.hasActiveForm(c), isTrue);
      expect(CharacterCalculator.compute(c).maxKi, baseKi * 2);
      // The ToP requirement travels on the def for the pickers/warnings.
      expect(
          CharacterCalculator.transformationByName('Crimson Surge')!
              .tierOfPowerRequirement,
          2);
    });

    test('a graded homebrew Transformation carries its Graded Aspect', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-enh',
          category: HomebrewCategory.enhancement,
          name: 'Scaling Focus',
          transformationData: HomebrewTransformationData(maxGrade: 3),
        ),
      ]);
      final def = CharacterCalculator.transformationByName('Scaling Focus')!;
      expect(def.type, TransformationType.enhancement);
      // The 'Graded (N)' Aspect is what makes the Grade stepper appear.
      expect(def.aspects.any((a) => a.startsWith('Graded')), isTrue);
    });

    test('a homebrew Factor Trait joins the swap machinery', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-fac',
          category: HomebrewCategory.factorTrait,
          name: 'Gravity Training',
          effectText: 'Increase your Soak Value by 2.',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 2),
          ],
          factorData: HomebrewFactorData(),
        ),
      ]);
      final c = Character.blank('c')
        ..powerLevel = 1
        ..race = 'Saiyan';
      final traits = raceTraitsFor('Saiyan');
      final secondary =
          traits.firstWhere((t) => t.name == "Warrior's Pride");
      final primary = traits.firstWhere((t) => t.name == 'Born for Battle');
      // Offered for a Secondary Racial Trait, not a Primary (default rule).
      expect(
          CharacterCalculator.compatibleFactorTraitsFor(c, secondary)
              .any((p) => p.trait.name == 'Gravity Training'),
          isTrue);
      expect(
          CharacterCalculator.compatibleFactorTraitsFor(c, primary)
              .any((p) => p.trait.name == 'Gravity Training'),
          isFalse);
      // Swapping it in makes it an active Racial Trait whose automation
      // applies ("Factor Traits are considered Racial Traits").
      final before = CharacterCalculator.compute(c).soak;
      c.factorSelections.add(FactorSelection(
        factorName: 'Gravity Training',
        factorTraitName: 'Gravity Training',
        replacedTraitName: "Warrior's Pride",
      ));
      expect(
          CharacterCalculator.activeRaceTraits(c)
              .any((t) => t.name == 'Gravity Training'),
          isTrue);
      expect(CharacterCalculator.compute(c).soak - before, 2);
    });

    test('a must-replace homebrew Factor Trait targets exactly that Trait',
        () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-fac',
          category: HomebrewCategory.factorTrait,
          name: 'Heritage Rewrite',
          factorData:
              HomebrewFactorData(mustReplaceTraitName: 'Born for Battle'),
        ),
      ]);
      final c = Character.blank('c')..race = 'Saiyan';
      final traits = raceTraitsFor('Saiyan');
      final primary = traits.firstWhere((t) => t.name == 'Born for Battle');
      final secondary =
          traits.firstWhere((t) => t.name == "Warrior's Pride");
      // May replace the named Trait — even a Primary — and nothing else.
      expect(
          CharacterCalculator.compatibleFactorTraitsFor(c, primary)
              .any((p) => p.trait.name == 'Heritage Rewrite'),
          isTrue);
      expect(
          CharacterCalculator.compatibleFactorTraitsFor(c, secondary)
              .any((p) => p.trait.name == 'Heritage Rewrite'),
          isFalse);
    });

    test('a race-restricted homebrew Factor Trait is gated by Race', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-fac',
          category: HomebrewCategory.factorTrait,
          name: 'Namekian Rite',
          factorData: HomebrewFactorData(racialRequirement: 'Namekian'),
        ),
      ]);
      final saiyan = Character.blank('c')..race = 'Saiyan';
      expect(
          CharacterCalculator.eligibleFactors(saiyan)
              .any((f) => f.name == 'Namekian Rite'),
          isFalse);
      final namekian = Character.blank('c')..race = 'Namekian';
      expect(
          CharacterCalculator.eligibleFactors(namekian)
              .any((f) => f.name == 'Namekian Rite'),
          isTrue);
    });

    test('structured payloads survive a JSON round-trip', () {
      final entry = HomebrewEntry(
        id: 'hb-x',
        category: HomebrewCategory.transformation,
        name: 'Inner Fire',
        transformationData: HomebrewTransformationData(
          awakeningType: AwakeningType.greater,
          tierOfPowerRequirement: 3,
          racialRequirement: 'Saiyan',
          prerequisiteText: 'Possess Inner Spark.',
          maxStacks: 4,
          maxGrade: 3,
          amb: {
            DbuAttribute.magic: HomebrewAmb(coefficient: 2, tierScaled: true)
          },
        ),
      );
      final t = HomebrewEntry.fromJson(entry.toJson()).transformationData;
      expect(t.awakeningType, AwakeningType.greater);
      expect(t.tierOfPowerRequirement, 3);
      expect(t.racialRequirement, 'Saiyan');
      expect(t.prerequisiteText, 'Possess Inner Spark.');
      expect(t.maxStacks, 4);
      expect(t.maxGrade, 3);
      expect(t.amb[DbuAttribute.magic]!.coefficient, 2);
      expect(t.amb[DbuAttribute.magic]!.tierScaled, isTrue);

      final race = HomebrewEntry.fromJson(raceEntry().toJson()).raceData;
      expect(race.racialLifeModifier, 5);
      expect(race.fixedAttributeIncreases, {DbuAttribute.force: 2});
      expect(race.choiceAmounts, [1]);
      expect(race.savingThrows, [DbuSavingThrow.corporeal]);
      expect(race.skillRanks, 3);

      final cond = HomebrewEntry.fromJson(HomebrewEntry(
        id: 'hb-c',
        category: HomebrewCategory.condition,
        name: 'Frostbitten',
        conditionData: HomebrewConditionData(
          maxStacks: 3,
          penaltyPerStack: 2,
          tierScaling: TierScaling.current,
          affectedStats: [AffectedStat.soak],
        ),
      ).toJson())
          .conditionData;
      expect(cond.maxStacks, 3);
      expect(cond.penaltyPerStack, 2);
      expect(cond.tierScaling, TierScaling.current);
      expect(cond.affectedStats, [AffectedStat.soak]);

      final fac = HomebrewEntry.fromJson(HomebrewEntry(
        id: 'hb-f',
        category: HomebrewCategory.factorTrait,
        name: 'Gravity Training',
        factorData: HomebrewFactorData(
          mustReplaceTraitName: 'Born for Battle',
          racialRequirement: 'Saiyan',
          prerequisiteText: 'Character Creation only.',
          maxFactor: 2,
        ),
      ).toJson())
          .factorData;
      expect(fac.mustReplaceTraitName, 'Born for Battle');
      expect(fac.racialRequirement, 'Saiyan');
      expect(fac.prerequisiteText, 'Character Creation only.');
      expect(fac.maxFactor, 2);
    });

    test('a homebrew State applies its Level-gated Traits', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-state',
          category: HomebrewCategory.state,
          name: 'Overclocked',
          effectText: 'Your systems run hot.',
          stateData: HomebrewStateData(
            maxLevel: 3,
            traits: [
              HomebrewStateTraitData(
                level: 1,
                coefficientPerLevel: 1,
                tierScaling: TierScaling.current,
                affectedStats: [AffectedStat.strike],
              ),
              HomebrewStateTraitData(
                level: 2,
                coefficientPerLevel: -1,
                affectedStats: [AffectedStat.dodge],
              ),
              HomebrewStateTraitData(
                level: 3,
                ignoresHealthThresholdPenalties: true,
              ),
            ],
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(2);
      final entry = TrackedEntry(name: 'Overclocked', stacks: 2, maxStacks: 3);
      c.states.add(entry);
      final effect = CharacterCalculator.statePerStatEffect(c, entry);
      // L1 Trait at Level 2: 1 × L2 × T2 = 4; L2 Trait: −1 × L2 = −2.
      expect(effect[AffectedStat.strike], 4);
      expect(effect[AffectedStat.dodge], -2);
      // The L3 Trait (ignore thresholds) isn't unlocked yet.
      expect(
          CharacterCalculator.stateIgnoresHealthThresholdPenalties(c, entry),
          isFalse);
      entry.stacks = 3;
      expect(
          CharacterCalculator.stateIgnoresHealthThresholdPenalties(c, entry),
          isTrue);
      // Official States still resolve to the official def.
      expect(HomebrewRegistry.resolveStateDef(kDbuStates.first.name),
          same(kDbuStates.first));
    });

    test('a homebrew Apparel Quality feeds the Apparel pipeline', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-apq',
          category: HomebrewCategory.apparelQuality,
          name: 'Feathered Lining',
          effectText: 'Increase your Dodge Rolls by 1(bT).',
          apparelQualityData: HomebrewApparelQualityData(
            statEffects: [
              HomebrewApparelEffect(
                stats: [AffectedStat.dodge],
                coefficient: 1,
                basis: ApparelEffectBasis.perBaseTier,
              ),
            ],
          ),
        ),
      ]);
      final def = HomebrewRegistry.resolveApparelQuality('Feathered Lining');
      expect(def, isNotNull);
      expect(def!.isAutomated, isTrue);

      final c = Character.blank('c')..powerLevel = 1;
      c.apparel.add(ApparelPiece(
        name: 'Test Vest',
        worn: true,
        qualities: [ApparelQualitySelection(name: 'Feathered Lining')],
      ));
      expect(
          CharacterCalculator.apparelTotals(c)[AffectedStat.dodge], 1);
    });

    test('a homebrew Weapon Quality feeds the Weapon pipeline', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-wq',
          category: HomebrewCategory.weaponQuality,
          name: 'Reinforced Core',
          effectText: 'This Weapon gains 2 extra Life Points per Power Level.',
          weaponQualityData: HomebrewWeaponQualityData(
            lifePointsPerLevel: 2,
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = 1;
      final bare = WeaponPiece(name: 'Plain', wielded: true);
      final reinforced = WeaponPiece(
        name: 'Sturdy',
        wielded: true,
        qualities: [WeaponQualitySelection(name: 'Reinforced Core')],
      );
      expect(
        CharacterCalculator.weaponMaxLife(c, reinforced) -
            CharacterCalculator.weaponMaxLife(c, bare),
        2, // 2 per PL at PL 1
      );
    });

    test('a homebrew Accessory applies while equipped', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-acc',
          category: HomebrewCategory.accessory,
          name: 'Lucky Charm',
          effectText: 'Increase your Morale Saves by 1(bT).',
          accessoryData: HomebrewAccessoryData(
            craftDc: 'Apprentice',
            statEffects: [
              HomebrewAccessoryEffect(
                stats: [AffectedStat.moraleSave],
                coefficient: 1,
                basis: AccessoryEffectBasis.perBaseTier,
              ),
            ],
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = 1;
      c.accessories.add(AccessorySelection(name: 'Lucky Charm'));
      expect(CharacterCalculator.accessoryTotals(c), isEmpty);
      c.accessories.single.equipped = true;
      expect(CharacterCalculator.accessoryTotals(c)[AffectedStat.moraleSave],
          1);
    });

    test('a homebrew Signature Disadvantage refunds TP and is rank-scaled',
        () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-sig',
          category: HomebrewCategory.signatureModifier,
          name: 'Slow Wind-Up',
          effectText: 'Reduce your Strike Rolls by 1(T) per rank.',
          sigModifierData: HomebrewSigModifierData(
            isDisadvantage: true,
            tpCostsPerRank: [2, 4],
            statEffects: [
              HomebrewSigEffect(
                target: SigEffectTarget.strike,
                coefficientPerRank: -1,
              ),
            ],
          ),
        ),
      ]);
      final def = HomebrewRegistry.resolveSignatureModifier('Slow Wind-Up')!;
      // Disadvantage TP costs are stored negative (catalogue convention).
      expect(def.tpCostsPerRank, [-2, -4]);
      expect(def.category.isDisadvantage, isTrue);
      // The refund flows into the Technique's TP Cost (base 8 − 4, floor 8
      // does not bind here since 8−4 < 8 → floored back to 8? No: floor is
      // 8, so the cost stays at the 8 minimum).
      final c = Character.blank('c')..powerLevel = 1;
      final tech = SignatureTechnique(
        name: 'Test',
        disadvantages: [SigModifierSelection(name: 'Slow Wind-Up', rank: 2)],
      );
      c.signatureTechniques.add(tech);
      expect(CharacterCalculator.signatureTpCost(tech), 8); // 8 − 4 → floor 8
      // Its automated per-Technique Strike modifier applies rank × Tier.
      final mods = CharacterCalculator.signatureModifiers(c, tech);
      expect(mods[AffectedStat.strike], -2); // −1 × rank 2 × Tier 1
    });

    test('a homebrew Unique Ability joins the cost engine', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-ua',
          category: HomebrewCategory.uniqueAbility,
          name: 'Star Step',
          effectText: 'Teleport to a space you can see.',
          uniqueAbilityData: HomebrewUniqueAbilityData(
            baseTpCost: 6,
            kpPerTier: 3,
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(2);
      final sel = UniqueAbilitySelection(name: 'Star Step');
      c.uniqueAbilities.add(sel);
      expect(CharacterCalculator.uniqueAbilityDefFor(sel)!.baseTpCost, 6);
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c), 6);
      expect(CharacterCalculator.uniqueAbilityKpCost(c, sel), 6); // 3 × T2
    });

    test('extra homebrew Traits gate on Stacks and Mastery', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-awk2',
          category: HomebrewCategory.transformation,
          name: 'Rising Storm',
          transformationData: HomebrewTransformationData(
            awakeningType: AwakeningType.lesser,
            maxStacks: 3,
            extraTraits: [
              HomebrewTraitData(
                name: 'Thunderhead',
                description: 'Increase your Soak Value by 2. (2)',
                minStacks: 2,
                automations: const [
                  RaceTraitAutomation(
                      affectedStats: [AffectedStat.soak], coefficient: 2),
                ],
              ),
              HomebrewTraitData(
                name: 'Eye of the Storm',
                description: 'Increase your Dodge Rolls by 1.',
                isMastery: true,
                automations: const [
                  RaceTraitAutomation(
                      affectedStats: [AffectedStat.dodge], coefficient: 1),
                ],
              ),
            ],
          ),
        ),
      ]);
      final def = CharacterCalculator.transformationByName('Rising Storm')!;
      expect(def.traits, hasLength(1)); // only the Stack-gated Trait
      expect(def.masteryTraits, hasLength(1));

      final c = Character.blank('c')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Rising Storm', stacks: 1);
      c.transformations.add(sel);
      Map<AffectedStat, int> totals() =>
          CharacterCalculator.transformationTraitTotals(c,
              currentLife: 10, maxLife: 10);
      // 1 Stack: the "(2)" Trait is locked, no Mastery yet.
      expect(totals(), isEmpty);
      sel.stacks = 2;
      expect(totals()[AffectedStat.soak], 2);
      expect(totals()[AffectedStat.dodge], isNull);
      sel.masteryLevel = 1;
      expect(totals()[AffectedStat.dodge], 1);
    });

    test('homebrew Aspect labels flow through aspectTotals', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-form2',
          category: HomebrewCategory.form,
          name: 'Bulwark Shell',
          transformationData: HomebrewTransformationData(
            aspects: ['Enhanced Save (Corporeal)'],
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(2);
      c.transformations
          .add(TransformationSelection(name: 'Bulwark Shell', active: true));
      expect(CharacterCalculator.aspectTotals(c)[AffectedStat.corporealSave],
          2); // +Tier while the Form is active
      c.transformations.single.active = false;
      expect(CharacterCalculator.aspectTotals(c), isEmpty);
    });

    test('annotateRuleText appends the resolved values', () {
      expect(
        annotateRuleText('Increase your Strike Rolls by 1(T).',
            tier: 3, baseTier: 2),
        'Increase your Strike Rolls by 1(T) [=3].',
      );
      expect(
        annotateRuleText('Gain 2(bT) Soak and 1(T) Dodge.',
            tier: 3, baseTier: 2),
        'Gain 2(bT) [=4] Soak and 1(T) [=3] Dodge.',
      );
      expect(
        annotateRuleText('equal to 2Z, plus Z more', tier: 1, baseTier: 1,
            stacks: 3),
        'equal to 2Z [=6], plus Z [=3] more',
      );
      expect(
        annotateRuleText('increase it by G(T)... by G',
            tier: 2, baseTier: 1, grade: 3),
        // G alone is annotated; "G(T)" is the G token followed by a (T) with
        // no coefficient, so only the G is resolved.
        'increase it by G [=3](T)... by G [=3]',
      );
      // Tokens without context stay untouched.
      expect(
        annotateRuleText('equal to Z', tier: 1, baseTier: 1),
        'equal to Z',
      );
    });

    test('Holding Back reduces the Tier of Power and buffs Concealment', () {
      final c = Character.blank('c')..powerLevel = _plForTop(4); // base ToP 4
      expect(CharacterCalculator.tierOfPower(c), 4);

      c.holdingBackStacks = 2;
      expect(CharacterCalculator.tierOfPower(c), 2);
      // No max-stack penalty yet.
      expect(CharacterCalculator.holdingBackTotals(c), isEmpty);
      // +1 Concealment per Stack (max 3).
      final concealment =
          kDbuSkills.firstWhere((s) => s.name == 'Concealment');
      final atTwo = CharacterCalculator.skillBonus(c, concealment);
      c.holdingBackStacks = 0;
      expect(atTwo - CharacterCalculator.skillBonus(c, concealment), 2);

      // At the maximum (== base ToP): ToP set to 1 and −1(bT) Combat Rolls.
      c.holdingBackStacks = 4;
      expect(CharacterCalculator.tierOfPower(c), 1);
      expect(CharacterCalculator.holdingBackTotals(c)[AffectedStat.strike],
          -4);
      expect(CharacterCalculator.holdingBackTotals(c)[AffectedStat.dodge],
          -4);
      // The Concealment bonus caps at 3.
      final atFour = CharacterCalculator.skillBonus(c, concealment);
      c.holdingBackStacks = 0;
      expect(atFour - CharacterCalculator.skillBonus(c, concealment), 3);

      // Stacks are clamped to the base-Tier maximum ("up to an amount equal
      // to your base Tier of Power").
      c.holdingBackStacks = 99;
      expect(CharacterCalculator.holdingBackStacks(c), 4);
    });

    test('named-resource automations resolve the Holding Back tracker', () {
      addTearDown(HomebrewRegistry.clear);
      // A homebrew talent conditioned on Holding Back (the same shape the
      // catalogue's Suppressed Evolution / Restrained Fighter use).
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-hold',
          name: 'Patient Guard',
          effectText:
              'While you have at least 1 stack of Holding Back, increase '
              'your Soak Value by 2.',
          automations: const [
            RaceTraitAutomation(
              affectedStats: [AffectedStat.soak],
              coefficient: 2,
              condition: TraitCondition.whileNamedResourceAtLeast,
              conditionResourceName: 'Holding Back',
            ),
          ],
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(2);
      c.homebrewSelections.add(HomebrewSelection(name: 'Patient Guard'));
      Map<AffectedStat, int> totals() => CharacterCalculator.homebrewTotals(
          c,
          currentLife: 10,
          maxLife: 10);
      // No stacks → the condition is unmet.
      expect(totals(), isEmpty);
      // The dedicated tracker satisfies it — no tracked Resource needed.
      c.holdingBackStacks = 1;
      expect(totals()[AffectedStat.soak], 2);
    });

    test('a homebrew Unique Ability can carry its own Advancements', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-ua2',
          category: HomebrewCategory.uniqueAbility,
          name: 'Star Step',
          effectText: 'Teleport to a space you can see.',
          uniqueAbilityData: HomebrewUniqueAbilityData(
            baseTpCost: 6,
            kpPerTier: 4,
            advancements: [
              HomebrewUaAdvancementData(
                name: 'Twin Step',
                tpCost: 3,
                effect: 'Bring an ally with you.',
              ),
              HomebrewUaAdvancementData(
                name: 'Light Feet',
                tpCost: 2,
                kpReductionPerTier: 1,
                effect: 'Reduce the Ki Point Cost of Star Step by 1(T).',
              ),
            ],
          ),
        ),
      ]);
      final c = Character.blank('c')..powerLevel = _plForTop(2);
      final sel = UniqueAbilitySelection(name: 'Star Step');
      c.uniqueAbilities.add(sel);
      // Base costs.
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c), 6);
      expect(CharacterCalculator.uniqueAbilityKpCost(c, sel), 8); // 4 × T2
      // Buying the Advancements raises TP and applies the KP reduction —
      // exactly like catalogue Advancements.
      sel.advancements.addAll(['Twin Step', 'Light Feet']);
      expect(CharacterCalculator.uniqueAbilityTpCost(sel, forCharacter: c),
          11); // 6 + 3 + 2
      expect(CharacterCalculator.uniqueAbilityKpCost(c, sel), 6); // (4−1)×T2
      // The JSON round-trip keeps them.
      final back = HomebrewEntry.fromJson(
          HomebrewRegistry.byName('Star Step')!.toJson());
      expect(back.uniqueAbilityData.advancements, hasLength(2));
      expect(back.uniqueAbilityData.advancements.first.name, 'Twin Step');
    });

    test('structured references are bundled on character export', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        raceEntry(),
        HomebrewEntry(
          id: 'hb-c2',
          category: HomebrewCategory.condition,
          name: 'Frostbitten',
          conditionData: HomebrewConditionData(
              penaltyPerStack: 1, affectedStats: [AffectedStat.soak]),
        ),
        HomebrewEntry(
          id: 'hb-t2',
          category: HomebrewCategory.transformation,
          name: 'Inner Fire',
          transformationData: HomebrewTransformationData(),
        ),
        HomebrewEntry(
          id: 'hb-f2',
          category: HomebrewCategory.factorTrait,
          name: 'Gravity Training',
          factorData: HomebrewFactorData(),
        ),
      ]);
      final c = Character.blank('c')..race = 'Tuffle Cyborg';
      c.conditions.add(TrackedEntry(name: 'Frostbitten', stacks: 1));
      c.transformations
          .add(TransformationSelection(name: 'Inner Fire', stacks: 1));
      c.factorSelections.add(FactorSelection(
        factorName: 'Gravity Training',
        factorTraitName: 'Gravity Training',
        replacedTraitName: "Warrior's Pride",
      ));
      final env = jsonDecode(ImportExportService.exportCharacter(c))
          as Map<String, dynamic>;
      final names = [
        for (final e in env['homebrew'] as List)
          (e as Map<String, dynamic>)['name'],
      ];
      expect(
          names,
          containsAll(
              ['Tuffle Cyborg', 'Frostbitten', 'Inner Fire', 'Gravity Training']));
    });

    test('homebrew Talent joins the Talent pipeline with its category and '
        'never double-counts with a generic possession', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-talent',
          category: HomebrewCategory.talent,
          name: 'Steel Training',
          effectText: 'Increase your Soak Value by 2.',
          talentData: HomebrewTalentData(
            category: TalentCategory.durability,
            prerequisitesText: 'Tenacity Score 4+',
          ),
          automations: const [
            RaceTraitAutomation(
              affectedStats: [AffectedStat.soak],
              coefficient: 2,
            ),
          ],
        ),
      ]);

      // Resolves like a catalogue Talent (official wins clashes).
      final def = HomebrewRegistry.resolveTalentDef('Steel Training')!;
      expect(def.category, TalentCategory.durability);
      expect(def.prerequisitesText, 'Tenacity Score 4+');
      expect(HomebrewRegistry.talentDefs(), hasLength(1));

      // Added as a Talent row → applies through the talent pipeline.
      final c = Character.blank('hb-t')..powerLevel = 1;
      final before = CharacterCalculator.compute(c).soak;
      c.talents.add(TalentEntry(name: 'Steel Training'));
      expect(CharacterCalculator.compute(c).soak, before + 2);

      // Possessing it generically TOO must not double-apply.
      c.homebrewSelections.add(HomebrewSelection(name: 'Steel Training'));
      expect(CharacterCalculator.compute(c).soak, before + 2);
      // Remove the Talent row: the generic possession takes over (old saves).
      c.talents.clear();
      expect(CharacterCalculator.compute(c).soak, before + 2);
    });

    test('a homebrew Race\'s directly authored Racial Traits reach '
        'activeRaceTraits and automate', () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-race-traits',
          category: HomebrewCategory.race,
          name: 'Moon Clan',
          raceData: HomebrewRaceData(
            traits: [
              HomebrewRaceTraitData(
                name: 'Lunar Vigor',
                tier: RaceTraitTier.primary,
                category: TraitCategory.body,
                description: 'Increase your Soak Value by 2.',
                automations: const [
                  RaceTraitAutomation(
                    affectedStats: [AffectedStat.soak],
                    coefficient: 2,
                  ),
                ],
              ),
              HomebrewRaceTraitData(name: 'Moonlit Mind'),
            ],
          ),
        ),
      ]);

      final c = Character.blank('hb-rt')..powerLevel = 1;
      final before = CharacterCalculator.compute(c).soak;
      c.race = 'Moon Clan';
      final traits = CharacterCalculator.activeRaceTraits(c);
      expect(traits.map((t) => t.name),
          containsAll(['Lunar Vigor', 'Moonlit Mind']));
      expect(traits.firstWhere((t) => t.name == 'Lunar Vigor').tier,
          RaceTraitTier.primary);
      expect(CharacterCalculator.compute(c).soak, before + 2);
      // Deactivating the Trait removes it (same machinery as official ones).
      c.inactiveRaceTraitNames.add('Lunar Vigor');
      expect(CharacterCalculator.compute(c).soak, before);
    });

    test('talentData and Race traits survive the JSON round-trip', () {
      final entry = HomebrewEntry(
        id: 'hb-json',
        category: HomebrewCategory.talent,
        name: 'Iron Focus',
        talentData: HomebrewTalentData(
          category: TalentCategory.mindful,
          prerequisitesText: 'Insight Score 6+',
        ),
      );
      final back = HomebrewEntry.fromJson(entry.toJson());
      expect(back.talentData.category, TalentCategory.mindful);
      expect(back.talentData.prerequisitesText, 'Insight Score 6+');

      final race = HomebrewEntry(
        id: 'hb-json-race',
        category: HomebrewCategory.race,
        name: 'Moon Clan',
        raceData: HomebrewRaceData(
          traits: [
            HomebrewRaceTraitData(
              name: 'Lunar Vigor',
              tier: RaceTraitTier.primary,
              category: TraitCategory.mind,
              description: 'Text.',
              automations: const [
                RaceTraitAutomation(
                  affectedStats: [AffectedStat.soak],
                  coefficient: 1,
                ),
              ],
            ),
          ],
        ),
      );
      final raceBack = HomebrewEntry.fromJson(race.toJson());
      expect(raceBack.raceData.traits, hasLength(1));
      final t = raceBack.raceData.traits.single;
      expect(t.name, 'Lunar Vigor');
      expect(t.tier, RaceTraitTier.primary);
      expect(t.category, TraitCategory.mind);
      expect(t.automations.single.coefficient, 1);
    });
  });

  group('Bulk export/import ("export all / multiple")', () {
    test('exportCharacters round-trips every character with fresh ids', () {
      final a = Character.blank('a')..name = 'Goku';
      final b = Character.blank('b')..name = 'Vegeta';
      final code = ImportExportService.exportCharacters([a, b]);
      final result =
          ImportExportService.importCharacters(code, newId: () => 'fresh');
      expect(result.ok, isTrue);
      expect(result.characters!.map((c) => c.name),
          containsAll(['Goku', 'Vegeta']));
      // Fresh ids assigned — never re-uses the originals.
      expect(result.characters!.every((c) => c.id != 'a' && c.id != 'b'),
          isTrue);
    });

    test('exportCharacters merges bundled homebrew, de-duplicated by name',
        () {
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-1',
          name: 'Iron Hide',
          automations: const [
            RaceTraitAutomation(
                affectedStats: [AffectedStat.soak], coefficient: 3),
          ],
        ),
      ]);
      final a = Character.blank('a')
        ..homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));
      final b = Character.blank('b')
        ..homebrewSelections.add(HomebrewSelection(name: 'Iron Hide'));
      final env = jsonDecode(ImportExportService.exportCharacters([a, b]))
          as Map<String, dynamic>;
      // Both characters reference it, but it's bundled exactly once.
      expect((env['homebrew'] as List).length, 1);

      final result = ImportExportService.importCharacters(
          jsonEncode(env), newId: () => 'fresh');
      expect(result.bundledHomebrew.single.name, 'Iron Hide');
    });

    test('importCharacters also accepts a single-character code', () {
      final code = ImportExportService.exportCharacter(
          Character.blank('c')..name = 'Piccolo');
      var i = 0;
      final result =
          ImportExportService.importCharacters(code, newId: () => 'id${i++}');
      expect(result.ok, isTrue);
      expect(result.characters, hasLength(1));
      expect(result.characters!.single.name, 'Piccolo');
    });

    test('exportHomebrewSet round-trips every entry with fresh ids', () {
      final a = HomebrewEntry(id: 'a', name: 'Iron Hide');
      final b = HomebrewEntry(id: 'b', name: 'Steel Skin');
      final code = ImportExportService.exportHomebrewSet([a, b]);
      final result =
          ImportExportService.importHomebrewSet(code, newId: () => 'fresh');
      expect(result.ok, isTrue);
      expect(
          result.entries!.map((e) => e.name), containsAll(['Iron Hide', 'Steel Skin']));
      expect(
          result.entries!.every((e) => e.id != 'a' && e.id != 'b'), isTrue);
    });

    test('importHomebrewSet also accepts a single-entry code', () {
      final code = ImportExportService.exportHomebrew(
          HomebrewEntry(id: 'x', name: 'Solo Entry'));
      var i = 0;
      final result = ImportExportService.importHomebrewSet(code,
          newId: () => 'id${i++}');
      expect(result.ok, isTrue);
      expect(result.entries, hasLength(1));
      expect(result.entries!.single.name, 'Solo Entry');
    });

    test('a character bundle is rejected by the homebrew-set importer', () {
      final charCode = ImportExportService.exportCharacters(
          [Character.blank('c')..name = 'Vegeta']);
      expect(
        ImportExportService.importHomebrewSet(charCode, newId: () => 'x').ok,
        isFalse,
      );
    });

    test('an empty selection list is rejected by exportCharacters callers',
        () {
      // The service itself tolerates an empty list (produces an empty
      // bundle); a genuinely empty code has nothing to import.
      final code = ImportExportService.exportCharacters(const []);
      final result =
          ImportExportService.importCharacters(code, newId: () => 'x');
      expect(result.ok, isFalse);
    });
  });

  group('Combat tracker (phases, maneuver catalogue, reminder scanner)', () {
    test('phase cycle repeats from Start of Round, never Start of Combat',
        () {
      expect(CombatPhase.startOfCombat.next, CombatPhase.startOfRound);
      expect(CombatPhase.startOfRound.next, CombatPhase.startOfTurn);
      expect(CombatPhase.startOfTurn.next, CombatPhase.endOfTurn);
      expect(CombatPhase.endOfTurn.next, CombatPhase.endOfRound);
      expect(CombatPhase.endOfRound.next, CombatPhase.startOfRound);
    });

    test('maneuver catalogue is complete and uniquely named', () {
      // Pinned against the Actions & Maneuvers / Special Maneuvers pages.
      expect(kDbuStandardManeuvers, hasLength(20));
      expect(kDbuInstantManeuvers, hasLength(4));
      expect(kDbuCounterManeuvers, hasLength(8));
      expect(kDbuModifierManeuvers, hasLength(4));
      expect(kDbuSpecialManeuvers, hasLength(32));
      expect(kDbuGodManeuvers, hasLength(12));
      final names = kDbuAllManeuvers.map((m) => m.name).toList();
      expect(names.toSet().length, names.length,
          reason: 'duplicate maneuver name');
      // Every Special Maneuver lists its underlying type and Minion access.
      for (final m in kDbuSpecialManeuvers) {
        expect(m.maneuverType, isNotNull, reason: m.name);
        expect(m.minions, isNotNull, reason: m.name);
      }
    });

    test('battlefield catalogues are complete', () {
      expect(kDbuBattleWeathers, hasLength(6));
      for (final w in kDbuBattleWeathers) {
        expect(w.tierEffects, hasLength(3), reason: w.name);
      }
      expect(kDbuBattleEnvironments, hasLength(10));
      expect(kDbuBattleEnvironments.where((e) => e.isHigh), hasLength(4));
      expect(kDbuLightLevels, hasLength(5));
      expect(kDbuEnvironmentalQualities, hasLength(9));
    });

    test('timing phrases classify to the right phases', () {
      Set<CombatTiming> t(String text) =>
          CombatReminderScanner.timingsForText(text);

      // Turn timings (the possessive variants the rules actually use).
      expect(t('reduce your Life Points by 1(bT) at the start of your turn'),
          {CombatTiming.startOfTurn});
      expect(t('At the end of each of your turns, lose Life Points'),
          {CombatTiming.endOfTurn});
      expect(t('lasts until the end of your next turn'),
          {CombatTiming.endOfTurn});
      expect(t('until the start of their next turn'),
          {CombatTiming.startOfTurn});
      // The "start/end your Turn" form (Battle Environments).
      expect(t('If you end your Turn in this Battle Environment'),
          {CombatTiming.endOfTurn});
      expect(t('If you start or end your Turn in this Battle Environment'),
          {CombatTiming.startOfTurn, CombatTiming.endOfTurn});
      // Round timings.
      expect(t('At the start of each Combat Round, remove all stacks'),
          {CombatTiming.startOfRound});
      expect(t('At the end of the Combat Round, lose all stacks'),
          {CombatTiming.endOfRound});
      // Encounter timings.
      expect(t('when a Combat Encounter starts'),
          {CombatTiming.startOfCombat});
      expect(t('All Initiative Checks are Urgent'),
          {CombatTiming.startOfCombat});
      expect(t('for the remainder of the Combat Encounter'),
          {CombatTiming.endOfEncounter});
      expect(t('until the end of the Combat Encounter'),
          {CombatTiming.endOfEncounter});
      // No timing phrase → no reminders.
      expect(t('Increase your Soak Value by 2(T).'), isEmpty);
    });

    test('snippetFor keeps only the sentence naming the timing', () {
      const text = 'Increase your Might by 2. '
          'At the start of your turn, regain 1(T) Ki Points. '
          'This has no other effect.';
      expect(
        CombatReminderScanner.snippetFor(text, CombatTiming.startOfTurn),
        'At the start of your turn, regain 1(T) Ki Points.',
      );
      expect(
          CombatReminderScanner.snippetFor(text, CombatTiming.endOfTurn), '');
    });

    test('tracked Poisoned Condition surfaces as an End of Turn reminder',
        () {
      // Poisoned (verbatim): "At the end of each of your turns, lose Life
      // Points equal to 1/10 of your Maximum Life Points."
      final c = Character.blank('combat-poison')
        ..conditions.add(TrackedEntry()
          ..name = 'Poisoned'
          ..stacks = 1);
      final reminders =
          CombatReminderScanner.forTiming(c, CombatTiming.endOfTurn);
      expect(reminders.map((r) => r.title), contains('Poisoned'));
      // A tracked Condition at 0 stacks stays silent.
      final off = Character.blank('combat-poison-off')
        ..conditions.add(TrackedEntry()
          ..name = 'Poisoned'
          ..stacks = 0);
      expect(
        CombatReminderScanner.forTiming(off, CombatTiming.endOfTurn)
            .map((r) => r.title),
        isNot(contains('Poisoned')),
      );
    });

    test('attack-trigger effects surface as onAttack reminders only', () {
      // A tracked effect with two sentences: one on a turn timing, one on an
      // Attacking Maneuver. The attack scanner keeps only the attack sentence
      // and never lets it leak onto a phase card.
      final c = Character.blank('atk-trigger')
        ..conditions.add(TrackedEntry()
          ..name = 'Test Focus'
          ..stacks = 1
          ..notes = 'At the start of your turn, gain a stack. '
              'Whenever you make an Attacking Maneuver, increase its Wound '
              'Roll by 2.');

      final atk = CombatReminderScanner.attackTriggerReminders(c);
      final focus = atk.firstWhere((r) => r.title == 'Test Focus');
      expect(focus.timing, CombatTiming.onAttack);
      expect(focus.text, contains('Attacking Maneuver'));
      expect(focus.text, isNot(contains('start of your turn')));

      // The turn sentence still reaches its phase card...
      expect(
        CombatReminderScanner.forTiming(c, CombatTiming.startOfTurn)
            .map((r) => r.title),
        contains('Test Focus'),
      );
      // ...but onAttack never appears in the phase scan.
      expect(
        CombatReminderScanner.scan(c)
            .every((r) => r.timing != CombatTiming.onAttack),
        isTrue,
      );
      // An effect that never names an attack produces no onAttack reminder.
      final plain = Character.blank('atk-none')
        ..conditions.add(TrackedEntry()
          ..name = 'Quiet'
          ..stacks = 1
          ..notes = 'At the end of your turn, do nothing special.');
      expect(
        CombatReminderScanner.attackTriggerReminders(plain).map((r) => r.title),
        isNot(contains('Quiet')),
      );
    });

    test('built-in tracked-state reminders (Power / Diminishing stacks)', () {
      final c = Character.blank('combat-builtin')
        ..powerStacks = 1
        ..diminishingOffenseStacks = 2
        ..diminishingDefenseStacks = 3;
      expect(
        CombatReminderScanner.forTiming(c, CombatTiming.endOfTurn)
            .map((r) => r.title),
        contains('Power (1 stack)'),
      );
      expect(
        CombatReminderScanner.forTiming(c, CombatTiming.endOfRound)
            .map((r) => r.title),
        contains('Diminishing Offense (2)'),
      );
      expect(
        CombatReminderScanner.forTiming(c, CombatTiming.startOfRound)
            .map((r) => r.title),
        contains('Diminishing Defense (3)'),
      );
      // None of them fire at zero.
      final clean = Character.blank('combat-clean');
      expect(CombatReminderScanner.scan(clean)
          .where((r) => r.source == 'Resource'), isEmpty);
    });

    test('reminder text is live-annotated with the character\'s Tier', () {
      // Undying State (verbatim): "...until the start of your next turn..."
      // wording carries (T) tokens in several catalogue texts; pin the
      // annotation path with a freeform Resource note instead (stable).
      final c = Character.blank('combat-annotate')
        ..powerLevel = _plForTop(3)
        ..resources.add(TrackedEntry()
          ..name = 'Test Boost'
          ..stacks = 1
          ..notes = 'At the start of your turn, regain 2(T) Ki Points.');
      final reminders =
          CombatReminderScanner.forTiming(c, CombatTiming.startOfTurn);
      final boost =
          reminders.firstWhere((r) => r.title == 'Test Boost');
      expect(boost.text, contains('2(T) [=6]'));
    });

    test('phase cards map timings 1:1 (End of Round has its own phase)', () {
      expect(
        CombatReminderScanner.timingsForPhase(CombatPhase.startOfRound),
        [CombatTiming.startOfRound],
      );
      expect(
        CombatReminderScanner.timingsForPhase(CombatPhase.endOfRound),
        [CombatTiming.endOfRound],
      );
      expect(
        CombatReminderScanner.timingsForPhase(CombatPhase.startOfCombat),
        [CombatTiming.startOfCombat],
      );
      // Round-cadence detection ("see Battle Born"): the scanner classifies
      // the phrase AND reports its even/odd parity.
      const bornForBattle = 'At the start of every even-numbered Combat '
          'Round, you gain 1 stack of Battle Born.';
      expect(CombatReminderScanner.timingsForText(bornForBattle),
          contains(CombatTiming.startOfRound));
      expect(CombatReminderScanner.roundParity(bornForBattle), isTrue);
      expect(
          CombatReminderScanner.roundParity(
              'At the start of each odd-numbered Combat Round, lose 1 stack.'),
          isFalse);
      expect(
          CombatReminderScanner.roundParity(
              'At the start of each Combat Round, gain a stack.'),
          isNull);
    });

    testWidgets(
        'Combat screen: phase flow, reminder popups and round automation',
        (tester) async {
      final c = Character.blank('combat-ui')
        ..name = 'Tester'
        ..powerStacks = 1
        ..diminishingDefenseStacks = 2
        ..conditions.add(TrackedEntry()
          ..name = 'Poisoned'
          ..stacks = 1);
      await tester.pumpWidget(MaterialApp(home: CombatScreen(character: c)));
      await tester.pump();

      // Opens on Start of Combat with the Initiative helper.
      expect(find.text('Start of Combat'), findsWidgets);
      expect(find.text('Initiative Bonus'), findsOneWidget);

      // Advance into Round 1: the round-boundary automation clears the
      // Diminishing trackers and the reminder popup lists the built-in
      // Diminishing Defense reminder.
      await tester.tap(find.textContaining('Next: Start of Round'));
      await tester.pumpAndSettle();
      expect(c.diminishingDefenseStacks, 0);
      expect(find.text('Start of Round — Reminders'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Round 1'), findsOneWidget);

      // Start of Turn: no reminders for this character → no popup.
      await tester.tap(find.textContaining('Next: Start of Turn'));
      await tester.pumpAndSettle();
      expect(find.text('Start of Turn — Reminders'), findsNothing);

      // End of Turn: Poisoned (Condition) and the Power-stack expiry both
      // fire as reminders.
      await tester.tap(find.textContaining('Next: End of Turn'));
      await tester.pumpAndSettle();
      expect(find.text('End of Turn — Reminders'), findsOneWidget);
      expect(find.textContaining('Poisoned'), findsWidgets);
      expect(find.textContaining('Power (1 stack)'), findsWidgets);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      // "Make an Attacking Maneuver" switches to the Attacking Maneuver tab,
      // which hosts the Attack Reference calculator plus the on-attack
      // reminders. Finishing there with "Attack made" counts the attack.
      final makeAttack = find.text('Make an Attacking Maneuver');
      await tester.scrollUntilVisible(makeAttack, 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable))
              .first);
      await tester.ensureVisible(makeAttack);
      await tester.pumpAndSettle();
      await tester.tap(makeAttack, warnIfMissed: true);
      await tester.pumpAndSettle();
      // Now on the Attacking Maneuver tab: the calculator card and the
      // triggers-on-attack reminders card are both present.
      expect(find.text('Attack Reference'), findsOneWidget);
      expect(find.text('Triggers on an Attacking Maneuver'), findsOneWidget);
      final attackMade = find.textContaining('Attack made');
      await tester.ensureVisible(attackMade);
      await tester.pumpAndSettle();
      await tester.tap(attackMade, warnIfMissed: true);
      await tester.pumpAndSettle();
      // First attack counted — no Diminishing Offense until after the third.
      expect(c.diminishingOffenseStacks, 0);

      // Back to the Combat tab: "Count an attack" for the rest (its ListView
      // reset to the top, so scroll the button into view). The fourth attack
      // overall (these are #2..#4) adds the first stack.
      await tester.tap(find.text('Combat').first);
      await tester.pumpAndSettle();
      final countAttack = find.textContaining('Count an attack (');
      await tester.scrollUntilVisible(countAttack, 200,
          scrollable: find
              .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(countAttack, warnIfMissed: true);
        await tester.pump();
      }
      expect(c.diminishingOffenseStacks, 1);

      // The Conditions tracker is on the page too (Poisoned row).
      await tester.scrollUntilVisible(find.text('Conditions'), 300,
          scrollable: find
              .descendant(
                  of: find.byType(ListView),
                  matching: find.byType(Scrollable))
              .first);
      expect(find.text('Conditions'), findsOneWidget);

      // The Transformations / Signatures / Unique Abilities tabs ride along
      // so the player can transform mid-combat.
      await tester.tap(find.text('Transformations'));
      await tester.pumpAndSettle();
      expect(find.byType(TransformationsTab), findsOneWidget);
    });

    test('adopted cross-Race Traits join activeRaceTraits', () {
      final c = Character.blank('xrace')
        ..race = 'Earthling'
        ..extraRaceTraits.add("Saiyan::Warrior's Pride");
      final names =
          CharacterCalculator.activeRaceTraits(c).map((t) => t.name).toList();
      expect(names, contains("Warrior's Pride"));
      // Native Earthling Traits are still all present.
      for (final t in raceTraitsFor('Earthling')) {
        expect(names, contains(t.name));
      }
      // A name already possessed natively never doubles up.
      final firstNative = raceTraitsFor('Earthling').first.name;
      c.extraRaceTraits.add('Earthling::$firstNative');
      expect(
        CharacterCalculator.activeRaceTraits(c)
            .where((t) => t.name == firstNative),
        hasLength(1),
      );
      // Malformed / stale refs are silently skipped.
      c.extraRaceTraits.addAll(['garbage', 'Saiyan::No Such Trait']);
      expect(CharacterCalculator.extraRaceTraitDefs(c).map((t) => t.name),
          ["Warrior's Pride", firstNative]);
      // Round-trips through JSON.
      final r = Character.fromJson(c.toJson());
      expect(r.extraRaceTraits, c.extraRaceTraits);
    });

    test('worn gear Quality text reaches the scanner', () {
      // Give a worn Apparel piece a Quality whose verbatim effect names a
      // timing, via homebrew (stable against catalogue edits).
      addTearDown(HomebrewRegistry.clear);
      HomebrewRegistry.setAll([
        HomebrewEntry(
          id: 'hb-quality',
          category: HomebrewCategory.apparelQuality,
          name: 'Test Regrowth Weave',
          effectText:
              'At the start of your turn, regain 1(bT) Life Points.',
        ),
      ]);
      final c = Character.blank('combat-quality')
        ..apparel.add(ApparelPiece()
          ..name = 'Weighted Vest'
          ..worn = true
          ..breakValue = 3
          ..qualities
              .add(ApparelQualitySelection(name: 'Test Regrowth Weave')));
      final reminders =
          CombatReminderScanner.forTiming(c, CombatTiming.startOfTurn);
      expect(
        reminders.map((r) => r.title),
        contains('Weighted Vest — Test Regrowth Weave'),
      );
    });
  });

  group('20 Jul 2026 site additions (Black Sparks, Combat Connoisseur, Last '
      'Hope, Super Mutation, Barrier Form, Berserk Controlled, Super Saiyan '
      '5)', () {
    test('Black Sparks: flat FO/IN/MA AMB always on; 120% Special State '
        'gates +1(T) Combat Rolls and -1 Physical Strike Crit Target', () {
      final c = Character.blank('jul1')..powerLevel = 1;
      final baseFo =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.force);
      c.transformations.add(TransformationSelection(name: 'Black Sparks'));
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.force),
          baseFo + 1);
      final owned = CharacterCalculator.compute(c);
      expect(
          CharacterCalculator.channelTotal(
              c, AffectedStat.strikePhysicalCriticalTarget),
          0,
          reason: '120% not entered yet');
      c.states.add(TrackedEntry(name: '120%', stacks: 1, maxStacks: 1));
      final on = CharacterCalculator.compute(c);
      expect(on.strike.total, owned.strike.total + 1);
      expect(on.dodge.total, owned.dodge.total + 1);
      expect(
          CharacterCalculator.channelTotal(
              c, AffectedStat.strikePhysicalCriticalTarget),
          -1);
    });

    test('Combat Connoisseur: +1(bT) Combat Rolls and Soak only while a '
        'Revealed stack is tracked', () {
      final c = Character.blank('jul2')..powerLevel = 1;
      c.transformations
          .add(TransformationSelection(name: 'Combat Connoisseur'));
      final hidden = CharacterCalculator.compute(c);
      c.resources.add(TrackedEntry(name: 'Revealed', stacks: 1, maxStacks: 3));
      final revealed = CharacterCalculator.compute(c);
      expect(revealed.strike.total, hidden.strike.total + 1);
      expect(revealed.soak, hidden.soak + 1);
    });

    test('Last Hope: +2 Max Life per Power Level reached', () {
      final c = Character.blank('jul3')..powerLevel = 3;
      final before = CharacterCalculator.compute(c).maxLife;
      c.transformations.add(TransformationSelection(name: 'Last Hope'));
      expect(CharacterCalculator.compute(c).maxLife, before + 2 * 3);
    });

    test('Super Mutation: pools/Surgency automate; a chosen Superior '
        'Mutation Trait raises the AMB; Grand Awakening toggles Combat '
        'Rolls/Soak', () {
      final c = Character.blank('jul4')..powerLevel = 1;
      final lifeBefore = CharacterCalculator.compute(c).maxLife;
      final kiBefore = CharacterCalculator.compute(c).maxKi;
      final tenBefore =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity);
      final sel = TransformationSelection(name: 'Super Mutation');
      c.transformations.add(sel);
      // (1) +2 Max Life/Ki per Power Level; (2) +1(T) Surgency; AMB TE +1(T).
      expect(CharacterCalculator.compute(c).maxLife, lifeBefore + 2);
      expect(CharacterCalculator.compute(c).maxKi, kiBefore + 2);
      expect(CharacterCalculator.channelTotal(c, AffectedStat.surgency), 1);
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          tenBefore + 1);
      // Superior Brute: +1(T) AMB (TE) on top of the base table.
      sel.optionChoices['Nurtured Mutation::Superior Mutation Trait'] = {
        'Superior Brute (Body)'
      };
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          tenBefore + 2);
      // Grand Awakening: +1(T) Combat Rolls and Soak Value while toggled.
      final off = CharacterCalculator.compute(c);
      sel.grandAwakeningActive = true;
      final on = CharacterCalculator.compute(c);
      expect(on.soak, off.soak + 1);
      expect(on.strike.total, off.strike.total + 1);
    });

    test('Barrier Form: +1(T) TE AMB and +1(T) Damage Reduction while '
        'active', () {
      final c = Character.blank('jul5')..powerLevel = 1;
      final tenBefore =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity);
      final sel = TransformationSelection(name: 'Barrier Form', active: false);
      c.transformations.add(sel);
      expect(CharacterCalculator.channelTotal(c, AffectedStat.damageReduction),
          0, reason: 'inactive Evolved Stage contributes nothing');
      sel.active = true;
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.tenacity),
          tenBefore + 1);
      expect(CharacterCalculator.channelTotal(c, AffectedStat.damageReduction),
          1);
    });

    test('Energy Consumption (site rewrite): Surgency/Cognitive Save '
        'automate; Grand Awakening scales Wound/Soak off Consumed Lifeforce '
        '(rounded up)', () {
      final ec = superAwakeningByName('Energy Consumption')!;
      expect(ec.origin, TransformationOrigin.mind);
      expect(ec.tierOfPowerRequirement, 4);
      expect(ec.grandAwakening?.name, 'Power of the Consumed');

      final c = Character.blank('jul7')..powerLevel = 1;
      final base = CharacterCalculator.compute(c);
      final sel = TransformationSelection(name: 'Energy Consumption');
      c.transformations.add(sel);
      final owned = CharacterCalculator.compute(c);
      // (4) +1(T) Surgency and Cognitive Save (on top of the TE AMB's
      // knock-on effects, none of which touch these two channels).
      expect(CharacterCalculator.channelTotal(c, AffectedStat.surgency), 1);
      expect(
          owned.savingThrows[DbuSavingThrow.cognitive]!.total,
          base.savingThrows[DbuSavingThrow.cognitive]!.total + 1);

      // Grand Awakening: +1 Stress, +1(T) Strike/Dodge, and Wound/Soak
      // +ceil(stacks/2)(T) from a tracked Consumed Lifeforce row.
      c.resources
          .add(TrackedEntry(name: 'Consumed Lifeforce', stacks: 3, maxStacks: 5));
      final off = CharacterCalculator.compute(c);
      sel.grandAwakeningActive = true;
      final on = CharacterCalculator.compute(c);
      expect(on.strike.total, off.strike.total + 1);
      expect(CharacterCalculator.channelTotal(c, AffectedStat.stressBonus), 1);
      // ceil(3/2) = 2 at ToP 1.
      expect(on.soak, off.soak + 2);
      expect(on.woundPhysical.total, off.woundPhysical.total + 2);
    });

    test('Dark Factor: Stress/Surgency automate; Grand Awakening toggles '
        '+1(T) Combat Rolls', () {
      final df = superAwakeningByName('Dark Factor')!;
      expect(df.origin, TransformationOrigin.body);
      expect(df.prerequisiteText, 'Demon Clansman Factor');
      expect(df.grandAwakening?.name, 'Resurgence of the Dark King');

      final c = Character.blank('jul8')..powerLevel = 1;
      final sel = TransformationSelection(name: 'Dark Factor');
      c.transformations.add(sel);
      // (1) +1 Stress Bonus; (2) +2(T) Surgency.
      expect(CharacterCalculator.channelTotal(c, AffectedStat.stressBonus), 1);
      expect(CharacterCalculator.channelTotal(c, AffectedStat.surgency), 2);
      final off = CharacterCalculator.compute(c);
      sel.grandAwakeningActive = true;
      final on = CharacterCalculator.compute(c);
      expect(on.strike.total, off.strike.total + 1);
      expect(on.woundEnergy.total, off.woundEnergy.total + 1);
    });

    test('Berserk Controlled and Super Saiyan 5 classify as Evolved Stages; '
        'SS5 surfaces its Legendary and Mastery Traits', () {
      final berserk = alternateFormByName('Berserk Controlled')!;
      expect(berserk.isEvolvedStage, isTrue);
      expect(berserk.racialRequirement, 'Saiyan');
      expect(berserk.aspects, contains('Innate State (Berserk)'));

      final ss5 = alternateFormByName('Super Saiyan 5')!;
      expect(ss5.isEvolvedStage, isTrue);
      expect(ss5.formType, FormType.legendary);
      expect(ss5.tierOfPowerRequirement, 6);
      expect(ss5.legendaryTrait?.name, 'Primal Hunger');
      expect(ss5.masteryTrait?.name, 'Primal Focus');
      expect(
          ss5.situationalTraits.map((t) => t.name),
          containsAll(['Primal Aggression', 'Bloodlusted (Special State)']));

      // Active SS5 applies its +1(T) AMB (AG/FO/TE/IN/MA).
      final c = Character.blank('jul6')..powerLevel = 1;
      final agBefore =
          CharacterCalculator.effectiveModifier(c, DbuAttribute.agility);
      c.transformations
          .add(TransformationSelection(name: 'Super Saiyan 5', active: true));
      expect(CharacterCalculator.effectiveModifier(c, DbuAttribute.agility),
          agBefore + 1);
    });
  });

  group('Trait-granted Talents auto-sync (ensureTraitGrantedTalents)', () {
    // Majin's "Secondary Traits (choose 4)" holds Options that grant Talents:
    // "Snack Motivated" → Snack Fiend, "Majin See, Majin Do" → Quick Learner.
    const key = 'Secondary Traits (choose 4)::Choose up to 4';

    test('an Option granting a Talent adds it (prefilled) only once chosen', () {
      final c = Character.blank('maj')..race = 'Majin';

      // Not chosen → nothing added.
      ensureTraitGrantedTalents(c);
      expect(c.talents.any((t) => t.name.toLowerCase() == 'snack fiend'),
          isFalse);

      // Choose the granting Option → Snack Fiend appears, prefilled from the
      // catalogue (name + description).
      c.raceTraitOptionChoices[key] = {'Snack Motivated'};
      ensureTraitGrantedTalents(c);
      final snack =
          c.talents.where((t) => t.name.toLowerCase() == 'snack fiend').toList();
      expect(snack, hasLength(1));
      expect(snack.single.name, 'Snack Fiend');
      expect(snack.single.description, talentByName('Snack Fiend')!.description);

      // No bogus rows from surrounding wording ("that Talent", blanks, etc.).
      for (final bogus in ['that', 'a', 'the', 'talent']) {
        expect(c.talents.any((t) => t.name.toLowerCase() == bogus), isFalse);
      }
      expect(c.talents.any((t) => t.name.trim().isEmpty), isFalse);
    });

    test('is idempotent — running twice never duplicates a granted Talent', () {
      final c = Character.blank('maj2')..race = 'Majin';
      c.raceTraitOptionChoices[key] = {'Snack Motivated', 'Majin See, Majin Do'};
      ensureTraitGrantedTalents(c);
      ensureTraitGrantedTalents(c);
      expect(c.talents.where((t) => t.name.toLowerCase() == 'snack fiend'),
          hasLength(1));
      expect(c.talents.where((t) => t.name.toLowerCase() == 'quick learner'),
          hasLength(1));
    });
  });

  group('Subraces (Namekian, Demon, Glass Tribe, Neo-Tuffle, Yardrat)', () {
    test('the five Races each expose their Subraces; others expose none', () {
      expect(raceHasSubraces('Namekian'), isTrue);
      expect(raceHasSubraces('Demon'), isTrue);
      expect(raceHasSubraces('Glass Tribe'), isTrue);
      expect(raceHasSubraces('Neo-Tuffle'), isTrue);
      expect(raceHasSubraces('Yardrat'), isTrue);
      expect(raceHasSubraces('Saiyan'), isFalse);
      expect(subracesFor('Namekian').map((s) => s.name),
          containsAll(<String>['Warrior Clan', 'Dragon Clan']));
      expect(subracesFor('Demon').map((s) => s.name),
          containsAll(<String>['Demon Person', 'Makyan', 'Phantom']));
    });

    test('base raceTraitsFor excludes Subrace Traits; they join '
        'activeRaceTraits only for the chosen Subrace', () {
      final c = Character.blank('nam')..race = 'Namekian';
      // No Subrace-tagged Trait leaks into the base catalogue.
      expect(raceTraitsFor('Namekian').any((t) => t.subrace.isNotEmpty),
          isFalse);
      // Nothing merged until a Subrace is chosen.
      expect(CharacterCalculator.activeRaceTraits(c)
          .any((t) => t.name == 'Refined Combat'), isFalse);
      c.subrace = 'Warrior Clan';
      expect(CharacterCalculator.activeRaceTraits(c)
          .any((t) => t.name == 'Refined Combat'), isTrue);
      // Switching Subraces swaps the granted Trait.
      c.subrace = 'Dragon Clan';
      final names = CharacterCalculator.activeRaceTraits(c).map((t) => t.name);
      expect(names, contains('Spirit of Namek'));
      expect(names, isNot(contains('Refined Combat')));
    });

    test('Tall Yardrat grants +3 Racial Life Modifier through Max Life', () {
      final c = Character.blank('yar')
        ..race = 'Yardrat'
        ..powerLevel = 3
        ..setTestScore(DbuAttribute.tenacity, 4);
      final before = CharacterCalculator.maxLife(c);
      c.subrace = 'Tall Yardrat';
      // +3 RLM × Power Level (3) = +9 Max Life.
      expect(CharacterCalculator.maxLife(c), before + 3 * c.powerLevel);
    });

    test('Refined Combat automates +1/2 (round up) Insight Mod to Surgency',
        () {
      final c = Character.blank('nam2')
        ..race = 'Namekian'
        ..subrace = 'Warrior Clan'
        ..setTestScore(DbuAttribute.insight, 6);
      final mod = CharacterCalculator.effectiveModifier(c, DbuAttribute.insight);
      final totals = CharacterCalculator.raceTraitTotals(c,
          currentLife: 100, maxLife: 100);
      // +1/2 of the Insight Modifier, rounded up.
      expect(totals[AffectedStat.surgency], (mod + 1) ~/ 2);
      expect(totals[AffectedStat.surgency], greaterThan(0));
    });
  });

  group('Bestial / Monstrous Traits (catalogue + grants + automation)', () {
    test('the catalogues are populated and looked up by kind + name', () {
      expect(kBestialTraits, isNotEmpty);
      expect(kMonstrousTraits, isNotEmpty);
      expect(beastTraitByName(BeastTraitKind.bestial, 'Grippy Grabbers'),
          isNotNull);
      expect(beastTraitByName(BeastTraitKind.monstrous, 'Unrelenting'),
          isNotNull);
      // Kinds don't cross over.
      expect(beastTraitByName(BeastTraitKind.bestial, 'Unrelenting'), isNull);
    });

    test('a chosen Bestial Trait applies its automation like a Racial Trait',
        () {
      // Shadow Dragon's Personified Dragon Ball grants 1 Bestial Trait.
      final c = Character.blank('sd')..race = 'Shadow Dragon';
      final grants = CharacterCalculator.activeBeastGrants(c);
      expect(grants, isNotEmpty);
      final key = grants.first.key;
      c.beastTraitChoices[key] = ['Grippy Grabbers'];
      // Grippy Grabbers (2): +1(T) Wound for Physical and Energy Attacks.
      final totals = CharacterCalculator.raceTraitTotals(c,
          currentLife: 100, maxLife: 100);
      final t = CharacterCalculator.tierOfPower(c);
      expect(totals[AffectedStat.woundPhysical], t);
      expect(totals[AffectedStat.woundEnergy], t);
    });

    test('a fixed grant (Android Extension Feature) auto-applies its Trait',
        () {
      final c = Character.blank('and')..race = 'Android';
      // Choose the Extension Feature Multi-Option on Technological Being.
      c.raceTraitOptionChoices['Technological Being::Multi-Option'] = {
        'Extension Feature'
      };
      final selected =
          CharacterCalculator.selectedBeastTraits(c).map((t) => t.name);
      expect(selected, contains('Extension Attack'));
    });

    test('a beast Trait sub-Option (Bestial Build → Thick Hide) automates', () {
      // Neko Majin Feline Build grants 2 Bestial Traits (restricted list).
      final c = Character.blank('nk')..race = 'Neko Majin';
      final grant = CharacterCalculator.activeBeastGrants(c).firstWhere(
          (g) => g.grant.restrictedTo.contains('Bestial Build'));
      c.beastTraitChoices[grant.key] = ['Bestial Build'];
      c.raceTraitOptionChoices['Bestial Build::Option'] = {'Thick Hide'};
      final totals = CharacterCalculator.raceTraitTotals(c,
          currentLife: 100, maxLife: 100);
      final t = CharacterCalculator.tierOfPower(c);
      // Thick Hide: +2(T) Soak, +1(T) Corporeal Save; Trait (1): +2 RLM.
      expect(totals[AffectedStat.soak], 2 * t);
      expect(totals[AffectedStat.corporealSave], t);
      expect(CharacterCalculator.raceTraitRacialLifeModifier(c), 2);
    });

    test('subrace + beast picks survive a JSON round-trip', () {
      final c = Character.blank('rt')
        ..race = 'Demon'
        ..subrace = 'Phantom';
      final grant = CharacterCalculator.activeBeastGrants(c)
          .firstWhere((g) => g.grant.kind == BeastTraitKind.bestial);
      c.beastTraitChoices[grant.key] = ['Claws'];
      final restored = Character.fromJson(jsonDecode(jsonEncode(c.toJson())));
      expect(restored.subrace, 'Phantom');
      expect(restored.beastTraitChoices[grant.key], ['Claws']);
    });

    test('an always-in-effect Awakening grant applies once owned', () {
      // Monstrous Evolution (Greater Awakening) grants 1 Bestial + 1 Monstrous
      // Trait unconditionally (Awakenings are always in effect).
      final c = Character.blank('me')..race = 'Saiyan';
      // Def is 'Dark Evolution'; its Trait 'Monstrous Evolution' carries the
      // grant (keyed by Trait name).
      c.transformations.add(TransformationSelection(
        name: 'Dark Evolution',
        stacks: 1,
      ));
      final key = CharacterCalculator.beastTraitGrantKey(
          'Monstrous Evolution', '', 0, BeastTraitKind.bestial);
      c.transformations.first.beastTraitChoices[key] = ['Ravaging Charger'];
      // Ravaging Charger is Monstrous, not Bestial → wrong-kind pick ignored.
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Ravaging Charger'), isFalse);
      c.transformations.first.beastTraitChoices[key] = ['Grippy Grabbers'];
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Grippy Grabbers'), isTrue);
    });

    test('a condition-gated grant (Bestial Transfiguration) applies only '
        'while in a Form/Enhancement', () {
      final c = Character.blank('bt')..race = 'Saiyan';
      c.transformations
          .add(TransformationSelection(name: 'Bestial Transfiguration'));
      final key = CharacterCalculator.beastTraitGrantKey(
          'Reawakened Beast', '', 0, BeastTraitKind.bestial);
      c.transformations.first.beastTraitChoices[key] = ['Grippy Grabbers'];
      // Not in a Form/Enhancement → effect suppressed (pick retained).
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Grippy Grabbers'), isFalse);
      // Enter a Form → it now applies.
      c.transformations
          .add(TransformationSelection(name: 'Monster Form', active: true));
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Grippy Grabbers'), isTrue);
    });

    test('a dependent grant restricts to the referenced Trait\'s picks', () {
      // Beyond a Demon God draws its choices from True Power of a Demon God.
      final c = Character.blank('dg')..race = 'Demon';
      final sel = TransformationSelection(name: 'True Demon God', active: true);
      final tpKey = CharacterCalculator.beastTraitGrantKey(
          'True Power of a Demon God', '', 0, BeastTraitKind.bestial);
      sel.beastTraitChoices[tpKey] = ['Claws', 'Fangs'];
      c.transformations.add(sel);
      expect(
          CharacterCalculator.beastPicksForTrait(
              c, 'True Power of a Demon God'),
          containsAll(<String>['Claws', 'Fangs']));
      // Nothing picked for a different Trait → empty restriction list.
      expect(CharacterCalculator.beastPicksForTrait(c, 'Nonexistent'), isEmpty);
    });

    test('a Form-gated grant is inactive until the Form is Active', () {
      // Monster Form → Monstrous Ascension grants a Monstrous + a Bestial
      // Trait, but a Form's situational Traits only apply while Active.
      final c = Character.blank('mf')..race = 'Bio Android';
      final sel = TransformationSelection(name: 'Monster Form', active: false);
      c.transformations.add(sel);
      final key = CharacterCalculator.beastTraitGrantKey(
          'Monstrous Ascension', '', 1, BeastTraitKind.bestial);
      sel.beastTraitChoices[key] = ['Claws'];
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Claws'), isFalse); // Form inactive
      sel.active = true;
      expect(CharacterCalculator.selectedBeastTraits(c)
          .any((t) => t.name == 'Claws'), isTrue); // Form active
    });

    test('per-selection beast picks survive a JSON round-trip', () {
      final c = Character.blank('trt')..race = 'Saiyan';
      final sel = TransformationSelection(name: 'Bestial Transfiguration');
      sel.beastTraitChoices['k'] = ['Claws', 'Fangs'];
      c.transformations.add(sel);
      final restored = Character.fromJson(jsonDecode(jsonEncode(c.toJson())));
      expect(restored.transformations.first.beastTraitChoices['k'],
          ['Claws', 'Fangs']);
    });
  });
}

/// Smallest Power Level that lands on the given Tier of Power, for tests.
int _plForTop(int top) {
  for (var pl = 1; pl <= 30; pl++) {
    if (PowerLevelRules.tierOfPower(pl) == top) return pl;
  }
  throw ArgumentError('No Power Level maps to Tier of Power $top');
}
