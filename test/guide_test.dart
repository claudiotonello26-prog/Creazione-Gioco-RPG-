import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'dart:math';

import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/hunting.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:iron_oath/ui/screens/guide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('le armi migliori chiedono Attacco o Magia', () {
    expect(weaponDefs['pilgrim_blade']!.wieldLevel, 1);
    expect(weaponDefs['cathedral_hammer']!.wieldLevel, 5);
    expect(weaponDefs['moon_blade']!.wieldLevel, 10);
    expect(weaponDefs['star_greatsword']!.wieldLevel, 20);
    expect(weaponDefs['smith_god_hammer']!.wieldLevel, 25);
    expect(weaponDefs['ebony_staff']!.usesMagic, isTrue);
  });

  test('non si impugna un\'arma sopra il proprio livello', () async {
    SharedPreferences.setMockInitialValues({});
    final s = GameState();
    await s.load();
    final w = WeaponInstance(weaponId: 'moon_blade');
    s.character.weapons.add(w);
    s.equip(w);
    expect(s.character.weapon.weaponId, isNot('moon_blade'));
    s.skillXp[Skill.attack] = 100000;
    s.equip(w);
    expect(s.character.weapon.weaponId, 'moon_blade');
  });

  test('la guida ha sblocchi per ogni abilità, in ordine', () {
    for (final k in Skill.values) {
      final g = guideFor(k);
      expect(g, isNotEmpty, reason: k.name);
      for (var i = 1; i < g.length; i++) {
        expect(g[i].$1, greaterThanOrEqualTo(g[i - 1].$1));
      }
    }
    expect(guideFor(Skill.woodcutting).map((u) => u.$3), contains('ebony_wood'));
  });

  test('i componenti di build seguono il Giuramento, non il gruppo', () {
    expect(forBuild('abyss_crystal', Attribute.strength), 'ember_iron');
    expect(forBuild('star_core', Attribute.faith), 'martyr_tear');
    expect(forBuild('iron_ingot', Attribute.faith), 'iron_ingot');
    expect(
        lootForBuild({'abyss_crystal': 2, 'ember_iron': 1}, Attribute.strength), {'ember_iron': 3});
  });

  test('il Giuramento automatico segue l\'attributo più alto', () async {
    SharedPreferences.setMockInitialValues({});
    final s = GameState();
    await s.load();
    s.character.attributes[Attribute.faith] = 20;
    expect(s.build, Attribute.faith);
    s.setOath(Attribute.intelligence);
    expect(s.build, Attribute.intelligence);
  });

  test('ogni esercizio della quest ha un nemico da combattere', () {
    for (final id in baseExercises) {
      final foe = questFoe(id, 1);
      expect(foe, isNotNull, reason: id.name);
      expect(foe!.$2.trackAs, id);
      expect(foe.$1.isBoss, isFalse);
    }
    expect(questFoe(ExerciseId.pushUp, 30)!.$1.level,
        greaterThan(questFoe(ExerciseId.pushUp, 1)!.$1.level));
  });

  test('il forziere della quest dà materiali e, più avanti, i componenti di build', () {
    final low = questLootFor(1, Attribute.strength, Random(1));
    expect(low['iron_ingot'], 2);
    final high = questLootFor(35, Attribute.dexterity, Random(1));
    expect(high['gale_silver'], 2);
    expect(high['steel_feather'], 1);
  });

  test('traguardi di passi: 20 rune ciascuno, 26 a 10000, una volta al giorno', () async {
    SharedPreferences.setMockInitialValues({});
    final s = GameState();
    await s.load();
    final start = s.character.runes;
    expect(s.pendingStepMilestones(1500), 0);
    expect(s.claimStepMilestones(4500), 40);
    expect(s.claimStepMilestones(4500), 0);
    expect(s.pendingStepMilestones(12000), 2);
    expect(s.claimStepMilestones(12000), 60);
    expect(s.character.runes - start, 100);
  });

  test('ogni livello ha la sua pietra', () {
    final normal = weaponDefs['pilgrim_blade']!;
    final rare = weaponDefs['lord_of_the_keep_blade']!;
    expect([
      for (var l = 1; l <= 10; l++) stoneFor(normal, l)
    ], [
      'forge_stone_1',
      'forge_stone_1',
      'forge_stone_1',
      'forge_stone_2',
      'forge_stone_2',
      'forge_stone_2',
      'forge_stone_3',
      'forge_stone_3',
      'forge_stone_3',
      'ancient_stone',
    ]);
    expect([for (var l = 1; l <= 5; l++) stoneFor(rare, l)],
        ['somber_stone', 'somber_stone_2', 'somber_stone_3', 'somber_stone_4', 'epic_stone']);
  });

  test('gli amuleti si incastonano nell\'arma e tornano nella borsa', () async {
    SharedPreferences.setMockInitialValues({});
    final s = GameState();
    await s.load();
    final w = s.character.weapon;
    s.character.addMaterial('amulet_ember_amulet', 1);
    s.character.addMaterial('amulet_fang_charm', 1);
    expect(s.socketAmulet(w, 1, 'ember_amulet'), isFalse);
    expect(s.socketAmulet(w, 0, 'fang_charm'), isFalse);
    expect(s.socketAmulet(w, 0, 'ember_amulet'), isTrue);
    expect(s.socketAmulet(w, 2, 'fang_charm'), isTrue);
    expect(w.aura, Affinity.fire);
    expect(s.amuletCount('ember_amulet'), 0);
    s.unsocketAmulet(w, 0);
    expect(w.aura, isNull);
    expect(s.amuletCount('ember_amulet'), 1);
  });
}
