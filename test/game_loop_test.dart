import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/hunting.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:iron_oath/domain/novice.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GameState s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = GameState(clock: () => DateTime(2026, 10, 17, 12));
    await s.load();
  });

  const rewards = CombatRewards(xp: 10, runes: 10, materials: {});
  final reps = List.filled(10, RepQuality.good);

  test('la postura decide se sale Attacco o Difesa', () {
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true, stance: Stance.aggressive);
    expect(s.skillXp[Skill.attack], 40);
    expect(s.skillXp[Skill.defense] ?? 0, 0);
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true, stance: Stance.defensive);
    expect(s.skillXp[Skill.defense], 40);
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true);
    expect(s.skillXp[Skill.attack], 60);
    expect(s.skillXp[Skill.defense], 60);
  });

  test('Attacco e Difesa alzano i numeri del cavaliere', () {
    final atk = s.attackValue, def = s.defenseValue;
    s.skillXp[Skill.attack] = 100000;
    s.skillXp[Skill.defense] = 100000;
    expect(s.attackValue, greaterThan(atk));
    expect(s.defenseValue, greaterThan(def));
    expect(s.defenseValue, lessThanOrEqualTo(0.75));
  });

  test('nella caccia la probabilità di drop speciale cresce in modo esponenziale', () {
    CombatEngine at(int wave) => CombatEngine(
        enemy: enemyDefs['hollow_goblin']!, character: Character(), testReps: 20, wave: wave);
    expect(at(5).dropMultiplier / at(4).dropMultiplier, closeTo(1.35, 1e-9));
  });

  test('ogni mostro: 1-2 comuni sempre, al massimo 4 non comuni e 2 rari', () {
    for (final e in [...enemyDefs.values, ...baseAnimals, ...huntAnimals]) {
      expect(e.commonLoot.length, inInclusiveRange(1, 2), reason: e.id);
      expect(e.uncommonLoot.length, lessThanOrEqualTo(4), reason: e.id);
      expect(e.rareLoot.length, lessThanOrEqualTo(2), reason: e.id);
      if (e.isAnimal || e.level < EnemyDef.uncommonFromLevel) {
        expect(e.specialChance, 0, reason: e.id);
      }
      if (e.level < EnemyDef.rareFromLevel) expect(e.rareLoot, isEmpty, reason: e.id);
    }
  });

  test('i mostri bassi danno sempre i loro comuni, quelli alti a volte un pezzo speciale', () {
    final goblin = enemyDefs['hollow_goblin']!;
    for (var i = 0; i < 50; i++) {
      final f = CombatEngine(enemy: goblin, character: Character(), testReps: 20, random: Random(i));
      while (f.status == CombatStatus.fighting) {
        f.registerRep(RepQuality.perfect);
      }
      expect(f.rewards().materials.keys.toSet(), goblin.commonLoot.keys.toSet());
    }
    final high = enemyDefs.values.where((e) => !e.isBoss).reduce((a, b) => a.level >= b.level ? a : b);
    var special = 0;
    for (var i = 0; i < 300; i++) {
      final f = CombatEngine(enemy: high, character: Character(), testReps: 20, random: Random(i));
      while (f.status == CombatStatus.fighting) {
        f.registerRep(RepQuality.perfect);
      }
      final r = f.rewards();
      if (r.rareWeapon != null || !r.materials.keys.toSet().containsAll(high.commonLoot.keys)) {
        special++;
      }
    }
    expect(special, inInclusiveRange(60, 140));
  });

  test('ogni mostro ha il suo esercizio', () {
    expect(enemyDefs['hollow_goblin']!.moves.map((m) => m.name), ['Squat', 'Ponte per glutei']);
    expect(enemyDefs['carrion_hound']!.exercises, [ExerciseId.squat, ExerciseId.squat]);
    expect(enemyDefs['fallen_knight']!.exercises, [ExerciseId.pushUp]);
    expect(enemyDefs['ash_wyrm']!.exercises, [ExerciseId.crunch, ExerciseId.plank]);
  });

  test('il Mercante compra a metà e vende al doppio', () {
    s.character.runes = 0;
    s.character.addMaterial('iron_ore', 3);
    final have = s.character.materials['iron_ore']!;
    expect(s.sellMaterial('iron_ore', 2), isTrue);
    expect(s.character.runes, sellPrice('iron_ore') * 2);
    expect(s.character.materials['iron_ore'], have - 2);
    expect(s.stat('sell'), 2);
    expect(s.buyMaterial('iron_ore'), isTrue);
    expect(s.character.runes, 0);
    expect(s.sellMaterial('ash_pickaxe'), isFalse, reason: 'gli attrezzi non si vendono');
  });

  test('si parte a mani vuote, la prima missione dà spada e scudo', () {
    expect(s.character.armed, isFalse);
    expect(s.character.offhandId, isNull);
    s.armUp();
    expect(s.character.armed, isTrue);
    expect(s.character.offhandId, 'wooden_shield');
    expect(s.noviceReady, isTrue);
  });

  test('non si vende l\'arma impugnata', () {
    expect(s.sellWeapon(s.character.weapon), isFalse);
  });

  test('il Cammino del Novizio parte da spada e scudo e finisce col giuramento', () {
    expect(noviceQuests.first.action, NoviceAction.arm);
    expect(noviceQuests[1].action, NoviceAction.fightGoblin);
    expect(noviceQuests.last.stat, 'quests');
    expect(noviceQuests.length, 15);
    s.bestHuntWave = 3;
    expect(s.stat('hunt_wave'), 3);
  });
}
