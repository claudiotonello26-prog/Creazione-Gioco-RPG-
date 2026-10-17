import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/items.dart';

void main() {
  Character strongHero() => Character(
        weapon: WeaponInstance(weaponId: 'penitent_greatsword', upgrade: 10),
        attributes: {
          for (final a in Attribute.values) a: 40,
        },
      );

  test('rep richieste per gradino: 12 / 14 / 18 con test di 20', () {
    int reps(String id) => CombatEngine(
          enemy: enemyDefs[id]!,
          character: Character(),
          testReps: 20,
        ).expectedReps;
    expect(reps('hollow_goblin'), 12);
    expect(reps('carrion_hound'), 14);
    expect(reps('forge_servant'), 18);
  });

  test('con rep perfette e build sufficiente il nemico cade al numero previsto', () {
    final e = CombatEngine(
      enemy: enemyDefs['fallen_knight']!,
      character: strongHero(),
      testReps: 20,
      random: Random(1),
    );
    // Pausa lunga tra le rep: niente Rampage, si misura il valore puro.
    var reps = 0;
    while (e.status == CombatStatus.fighting) {
      e.registerRep(RepQuality.perfect);
      e.rampage = 0;
      reps++;
    }
    expect(reps, e.expectedReps);
    expect(e.status, CombatStatus.victory);
  });

  test('la build non riduce mai le rep sotto il previsto', () {
    final e = CombatEngine(
      enemy: enemyDefs['hollow_goblin']!,
      character: strongHero(),
      testReps: 20,
    );
    expect(e.penetration, 1.0);
    expect(e.lootBonus, greaterThan(0));
    var reps = 0;
    while (e.status == CombatStatus.fighting) {
      e.registerRep(RepQuality.perfect);
      e.rampage = 0;
      reps++;
    }
    expect(reps, greaterThanOrEqualTo(e.expectedReps));
  });

  test('con forma scarsa servono più rep', () {
    final e = CombatEngine(
      enemy: enemyDefs['hollow_goblin']!,
      character: strongHero(),
      testReps: 20,
    );
    var reps = 0;
    while (e.status == CombatStatus.fighting) {
      e.registerRep(RepQuality.poor);
      e.rampage = 0;
      reps++;
    }
    expect(reps, greaterThan(e.expectedReps));
  });

  test('build troppo debole: i colpi rimbalzano', () {
    final e = CombatEngine(
      enemy: enemyDefs['forge_servant']!,
      character: Character(),
      testReps: 20,
    );
    final hit = e.registerRep(RepQuality.perfect);
    expect(hit.bounced, isTrue);
    expect(e.penetration, lessThan(1.0));
  });

  test('il nemico attacca a tempo e a vita zero si muore', () {
    final e = CombatEngine(
      enemy: enemyDefs['forge_servant']!,
      character: Character(),
      testReps: 20,
    );
    var t = 0.0;
    while (e.status == CombatStatus.fighting && t < 600) {
      e.tick(0.5);
      t += 0.5;
    }
    expect(e.status, CombatStatus.defeated);
    expect(e.rewards().runes, 0);
  });

  test('il Rampage sale con rep senza pause e dà fino a +20%', () {
    final e = CombatEngine(
      enemy: enemyDefs['forge_servant']!,
      character: strongHero(),
      testReps: 100,
    );
    for (var i = 0; i < 12; i++) {
      e.registerRep(RepQuality.perfect);
    }
    expect(e.rampage, 1.0);
    final hit = e.registerRep(RepQuality.perfect);
    expect(hit.damage, closeTo(1.2, 1e-9));
    e.tick(30);
    expect(e.rampage, lessThan(1.0));
  });

  test('scaling: Forza alza il danno dello Spadone', () {
    final weak = Character(weapon: WeaponInstance(weaponId: 'penitent_greatsword'));
    final strong = Character(
      weapon: WeaponInstance(weaponId: 'penitent_greatsword'),
      attributes: {for (final a in Attribute.values) a: 10}..[Attribute.strength] = 30,
    );
    expect(strong.weapon.attackRating(strong), greaterThan(weak.weapon.attackRating(weak)));
  });

  test('ritmo giusto: l\'eroe base vince con poco margine, a metà ritmo muore', () {
    CombatStatus fight(double secondsPerRep) {
      final e = CombatEngine(
        enemy: enemyDefs['hollow_goblin']!,
        character: Character(weapon: WeaponInstance(weaponId: 'pilgrim_blade', upgrade: 3)),
        testReps: 20,
      );
      var t = 0.0;
      var next = secondsPerRep;
      while (e.status == CombatStatus.fighting && t < 600) {
        e.tick(0.1);
        t += 0.1;
        if (t >= next && e.status == CombatStatus.fighting) {
          e.registerRep(RepQuality.good);
          next += secondsPerRep;
        }
      }
      return e.status;
    }

    expect(fight(2.0), CombatStatus.victory);
    expect(fight(4.5), CombatStatus.defeated);
  });

  test('se ti fermi il nemico recupera vita', () {
    final e = CombatEngine(
      enemy: enemyDefs['hollow_goblin']!,
      character: strongHero(),
      testReps: 20,
    );
    e.registerRep(RepQuality.perfect);
    final hp = e.enemyHp;
    for (var i = 0; i < 50; i++) {
      e.tick(0.1);
    }
    expect(e.enemyHp, greaterThan(hp));
  });

  test('caccia infinita: ogni ondata è più forte', () {
    final a = CombatEngine(enemy: enemyDefs['hollow_goblin']!, character: Character(), testReps: 20);
    final b = CombatEngine(
        enemy: enemyDefs['hollow_goblin']!, character: Character(), testReps: 20, wave: 3);
    expect(b.enemyMaxHp, greaterThan(a.enemyMaxHp));
    expect(b.hitDamage, greaterThan(a.hitDamage));
  });
}
