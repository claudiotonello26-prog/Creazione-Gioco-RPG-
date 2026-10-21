import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Character hero(Attribute build, {String weapon = 'pilgrim_blade'}) => Character(
        weapon: WeaponInstance(weaponId: weapon),
        attributes: {
          for (final a in Attribute.values) a: a == build ? 30 : 10,
        },
      );

  test('la ruota: Arcano batte Fuoco, Fuoco Vento, Vento Luce, Luce Arcano', () {
    expect(Affinity.arcane.beats, Affinity.fire);
    expect(Affinity.fire.beats, Affinity.wind);
    expect(Affinity.wind.beats, Affinity.holy);
    expect(Affinity.holy.beats, Affinity.arcane);
    for (final a in Affinity.values) {
      expect(a.weakness.beats, a);
    }
  });

  test('un boss d\'Intelligenza picchia più forte una build di Forza', () {
    final boss = enemyDefs['star_devourer']!;
    expect(boss.element, Affinity.arcane);
    final str = CombatEngine(enemy: boss, character: hero(Attribute.strength), testReps: 20);
    final faith = CombatEngine(enemy: boss, character: hero(Attribute.faith), testReps: 20);
    final dex = CombatEngine(enemy: boss, character: hero(Attribute.dexterity), testReps: 20);
    expect(str.elementTakenMult, closeTo(1.30, 1e-9));
    expect(faith.elementTakenMult, closeTo(0.85, 1e-9));
    expect(dex.elementTakenMult, 1.0);
  });

  test('sui nemici normali l\'elemento pesa a metà', () {
    final e = enemyDefs['star_shard']!;
    expect(e.isBoss, false);
    final str = CombatEngine(enemy: e, character: hero(Attribute.strength), testReps: 20);
    expect(str.elementTakenMult, closeTo(1.15, 1e-9));
  });

  test('il talismano al collo e la gemma nell\'arma ribaltano lo svantaggio', () {
    final boss = enemyDefs['star_devourer']!;
    final c = hero(Attribute.strength, weapon: 'ember_cleaver');
    final bare = CombatEngine(enemy: boss, character: c, testReps: 20);
    expect(bare.elementDamageMult, closeTo(0.85, 1e-9)); // Fuoco battuto dall'Arcano
    c.neck = wardFor(Affinity.arcane);
    c.weapon.sockets[1] = baneFor(Affinity.arcane);
    final geared = CombatEngine(enemy: boss, character: c, testReps: 20);
    expect(geared.elementTakenMult, closeTo(1.30 * 0.75, 1e-9));
    expect(geared.elementDamageMult, closeTo(1.05, 1e-9));
  });

  test('lo Stretching non ha elemento', () {
    expect(enemyDefs['sleepless_one']!.element, isNull);
  });

  test('attacchi a tempo casuale: in media come prima, a volte critici', () {
    final enemy = enemyDefs['iron_castellan']!;
    final e = CombatEngine(
        enemy: enemy, character: hero(Attribute.dexterity), testReps: 2000, random: Random(3));
    // Il nemico non cade mai: si contano i colpi in 2000 secondi.
    var hits = 0, crits = 0;
    final damages = <double>{};
    e.heroHp = double.infinity;
    for (var t = 0.0; t < 2000; t += 0.1) {
      final d = e.tick(0.1);
      if (d > 0) {
        hits++;
        damages.add(d.roundToDouble());
        if (e.lastStrikeCritical) crits++;
      }
    }
    final expected = 2000 / enemy.attackInterval;
    expect(hits, inInclusiveRange(expected * 0.9, expected * 1.1));
    expect(crits / hits, closeTo(enemy.critChance, 0.05));
    expect(damages.length, greaterThan(1));
  });

  test('qualità della forgia: 5 livelli sopra la ricetta è Buona, 15 Capolavoro', () {
    expect(CraftQuality.base(10, 10), CraftQuality.crude);
    expect(CraftQuality.base(15, 10), CraftQuality.good);
    expect(CraftQuality.base(20, 10), CraftQuality.fine);
    expect(CraftQuality.base(30, 10), CraftQuality.masterwork);
    final c = Character();
    final crude = WeaponInstance(weaponId: 'steel_longsword').attackRating(c);
    final master =
        WeaponInstance(weaponId: 'steel_longsword', quality: CraftQuality.masterwork).attackRating(c);
    expect(master / crude, closeTo(1.18, 1e-9));
  });

  test('l\'usura non pesa fino al 60%, poi cala fino al −20%, e non rompe', () {
    expect(conditionFactor(0), 1.0);
    expect(conditionFactor(60), 1.0);
    expect(conditionFactor(80), closeTo(0.9, 1e-9));
    expect(conditionFactor(100), closeTo(0.8, 1e-9));
    expect(conditionFactor(500), closeTo(0.8, 1e-9));
  });

  test('ogni scontro consuma arma e armatura, la riparazione costa rune e dà XP', () async {
    final s = GameState();
    s.character.armors.add('gambeson');
    for (final slot in ArmorSlot.values) {
      s.character.worn[slot] = 'gambeson';
    }
    const reward = CombatRewards(xp: 10, runes: 0, materials: {});
    for (var i = 0; i < 70; i++) {
      s.applyCombatRewards(reward, ExerciseId.pushUp, [RepQuality.good],
          victory: true, hitsTaken: i.isEven ? 1 : 0, random: Random(i));
    }
    expect(s.character.weapon.wear, 70);
    expect(s.character.wearOf('gambeson'), 35);
    expect(s.gearWornOut, isTrue);
    final cost = s.repairAllCost;
    expect(cost, greaterThan(0));
    s.character.runes = cost;
    final xp = s.skillXp[Skill.smithing] ?? 0;
    expect(s.repairAll(), isTrue);
    expect(s.character.runes, 0);
    expect(s.character.weapon.wear, 0);
    expect(s.character.wearOf('gambeson'), 0);
    expect(s.skillXp[Skill.smithing], xp + (70 + 35) * 2);
  });

  test('talismani solo al collo, gemme solo nell\'arma', () {
    final s = GameState();
    s.character.addMaterial('amulet_${wardFor(Affinity.fire)}', 1);
    s.character.addMaterial('amulet_${baneFor(Affinity.fire)}', 1);
    expect(s.socketAmulet(s.character.weapon, 1, wardFor(Affinity.fire)), isFalse);
    expect(s.wearNeck(baneFor(Affinity.fire)), isFalse);
    expect(s.wearNeck(wardFor(Affinity.fire)), isTrue);
    expect(s.socketAmulet(s.character.weapon, 1, baneFor(Affinity.fire)), isTrue);
  });

  test('ogni materiale speciale di build si può anche fondere', () {
    for (final list in buildMaterials.values) {
      for (final id in list.take(2)) {
        expect(materialRecipes.any((r) => r.output == id), isTrue, reason: id);
      }
    }
  });
}
