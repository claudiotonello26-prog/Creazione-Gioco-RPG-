import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/items.dart';

/// Rune per rep di un nemico vinto con rep tutte della qualità data.
double runesPerRep(String enemyId, {int test = 20, int wave = 0, RepQuality q = RepQuality.perfect}) {
  final e = CombatEngine(
    enemy: enemyDefs[enemyId]!,
    character: Character(weapon: WeaponInstance(weaponId: 'pilgrim_blade', upgrade: 10)),
    testReps: test,
    wave: wave,
  );
  while (e.status == CombatStatus.fighting) {
    e.registerRep(q);
  }
  return e.rewards().runes / e.reps;
}

void main() {
  test('nemici più duri pagano di più per ogni rep', () {
    expect(runesPerRep('ash_wyrm'), greaterThan(runesPerRep('fallen_knight')));
    expect(runesPerRep('fallen_knight'), greaterThan(runesPerRep('hollow_goblin')));
  });

  test('nella caccia ogni ondata paga di più per rep', () {
    expect(runesPerRep('hollow_goblin', wave: 5), greaterThan(runesPerRep('hollow_goblin')));
  });

  test('un test basso non regala bottino: si paga a rep', () {
    final weak = runesPerRep('hollow_goblin', test: 8);
    final strong = runesPerRep('hollow_goblin', test: 30);
    expect((weak - strong).abs() / strong, lessThan(0.35));
  });

  test('la forma scarsa paga meno', () {
    expect(runesPerRep('hollow_goblin', q: RepQuality.poor),
        lessThan(runesPerRep('hollow_goblin') * 0.75));
  });

  test('fatica: dopo 60 rep dello stesso gruppo il bottino cala', () {
    expect(GameState.fatigueAt(0), 1.0);
    expect(GameState.fatigueAt(59), 1.0);
    expect(GameState.fatigueAt(60), 0.6);
    expect(GameState.fatigueAt(150), 0.3);
    expect(GameState.fatigueFor(50, 20), closeTo(0.8, 0.001));
  });

  test('tabella di bilanciamento', () {
    for (final id in ['hollow_goblin', 'carrion_hound', 'fallen_knight', 'ash_wyrm', 'lord_of_the_keep']) {
      final e = CombatEngine(enemy: enemyDefs[id]!, character: Character(), testReps: 20);
      // ignore: avoid_print
      print('$id hp=${e.enemyMaxHp.toStringAsFixed(1)} hit=${e.hitDamage.toStringAsFixed(1)}/${enemyDefs[id]!.attackInterval}s '
          'runes/rep=${runesPerRep(id).toStringAsFixed(2)}');
    }
    for (final w in [0, 3, 6, 10]) {
      final e = CombatEngine(enemy: enemyDefs['hollow_goblin']!, character: Character(), testReps: 20, wave: w);
      // ignore: avoid_print
      print('wave $w hp=${e.enemyMaxHp.toStringAsFixed(1)} hit=${e.hitDamage.toStringAsFixed(1)} runes/rep=${runesPerRep('hollow_goblin', wave: w).toStringAsFixed(2)}');
    }
  });
}
