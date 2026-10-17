import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const groups = [
    MuscleGroup.push,
    MuscleGroup.legs,
    MuscleGroup.core,
    MuscleGroup.cardio,
    MuscleGroup.stretching,
  ];

  test('40 nemici in 20 spedizioni, quattro per gruppo a livelli crescenti', () {
    expect(enemyDefs.length, 40);
    expect(expeditions.length, 20);
    for (final g in groups) {
      final list = expeditionsOf(g);
      expect(list.map((e) => e.level), [1, 10, 25, 45], reason: g.label);
      for (final e in list) {
        expect(e.monster.group, g);
        expect(e.boss.isBoss, isTrue);
        expect(e.monster.isBoss, isFalse);
      }
    }
  });

  test('lo Stretching si fa tenendo le pose, gli altri gruppi coi loro esercizi', () {
    for (final e in enemyDefs.values) {
      final holds = e.moves.every((m) => m.trackAs == ExerciseId.stretch);
      expect(holds, e.group == MuscleGroup.stretching, reason: e.name);
    }
  });

  test('i materiali di ogni gruppo si trovano solo lì', () {
    final where = <String, Set<MuscleGroup>>{};
    for (final e in enemyDefs.values) {
      for (final m in e.loot.keys) {
        where.putIfAbsent(m, () => {}).add(e.group);
      }
    }
    for (final build in ['ember_iron', 'gale_silver', 'hallowed_gold', 'abyss_crystal',
        'godforge_steel', 'steel_feather', 'martyr_obsidian', 'star_iron']) {
      expect(where[build]?.length, 1, reason: build);
    }
  });

  test('ogni materiale ha nome e prezzo, ogni ricetta usa materiali noti', () {
    for (final e in enemyDefs.values) {
      for (final m in e.loot.keys) {
        expect(materialNames[m], isNotNull, reason: m);
        expect(sellPrice(m), greaterThan(0), reason: m);
      }
    }
    final recipes = [
      ...weaponDefs.values.map((w) => w.recipe),
      ...armorDefs.values.map((a) => a.recipe),
    ];
    for (final r in recipes) {
      for (final m in r.keys) {
        expect(materialNames[m], isNotNull, reason: m);
      }
    }
  });

  test('i vecchi salvataggi con Dorso passano allo Stretching', () {
    expect(MuscleGroup.parse('back'), MuscleGroup.stretching);
    expect(MuscleGroup.parse('push'), MuscleGroup.push);
  });

  test('vincere lo Stretching paga e la spedizione resta battuta', () async {
    SharedPreferences.setMockInitialValues({});
    final s = GameState(clock: () => DateTime(2026, 10, 17, 12));
    await s.load();
    final e = expeditionById('silent_garden');
    final before = s.character.materials['gem_rough'] ?? 0;
    final r = s.holdVictory(e.monster, seconds: 20, lootMultiplier: 2);
    expect(s.character.materials['gem_rough'], before + 2);
    expect(r.runes, e.monster.runeReward * 2);
    s.clearExpedition(e.id);
    await Future<void>.delayed(Duration.zero);
    final again = GameState(clock: () => DateTime(2026, 10, 17, 12));
    await again.load();
    expect(again.clearedExpeditions, contains('silent_garden'));
  });
}
