import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/contracts.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> _state() async {
  SharedPreferences.setMockInitialValues({});
  final s = GameState();
  await s.load();
  return s;
}

/// XP totali per arrivare al livello [lvl] di un'abilità.
int _xpFor(int lvl) => [for (var l = 1; l < lvl; l++) skillXpForLevel(l)].fold(0, (a, b) => a + b);

void main() {
  test('i committenti chiedono più spedizioni solo ai livelli alti', () {
    expect(contractors.map((c) => c.minSkill), [1, 10, 20, 30]);
    expect(contractors.map((c) => c.expeditions), [1, 1, 2, 3]);
    for (var i = 1; i < contractors.length; i++) {
      expect(contractors[i].runes, greaterThan(contractors[i - 1].runes));
    }
  });

  test('le spedizioni del contratto sono alla portata e di gruppi diversi', () {
    for (var seed = 0; seed < 30; seed++) {
      final t = drawContractTargets(contractors[3], 1, Random(seed));
      expect(t.length, 3);
      expect(t.toSet().length, 3);
      expect(t.map((id) => expeditionById(id).level), everyElement(1));
      expect(t.map((id) => expeditionById(id).group).toSet().length, 3);
    }
  });

  test('l\'arma speciale segue la build', () {
    expect(rareWeaponFor(Attribute.strength), 'smith_god_hammer');
    expect(rareWeaponFor(Attribute.dexterity), 'storm_king_spear');
    expect(rareWeaponFor(Attribute.faith), 'eternal_martyr_blade');
    expect(rareWeaponFor(Attribute.intelligence), 'devourer_eye');
  });

  test('firma, finisci la spedizione, consegna e ricevi il forziere', () async {
    final s = await _state();
    expect(s.canSign(contractors[1]), isFalse, reason: 'serve Spedizioni 10');
    final c = s.signContract(contractors[0], random: Random(1))!;
    expect(c.targets.length, 1);
    expect(s.canSign(contractors[0]), isFalse, reason: 'un contratto alla volta');
    expect(s.deliverContract(), isEmpty);

    final runes = s.character.runes;
    s.expeditionBossDown(expeditionById(c.targets.single));
    expect(s.contract!.complete, isTrue);
    final items = s.deliverContract(random: Random(2));
    expect(items.first, ('runes', 250, false));
    expect(s.character.runes, greaterThanOrEqualTo(runes + 250));
    expect(s.contract, isNull);
  });

  test('il primo annullamento del giorno è gratis, il secondo costa rune', () async {
    final s = await _state();
    s.signContract(contractors[0]);
    expect(s.cancelContract(), isTrue);
    s.signContract(contractors[0]);
    s.character.runes = 0;
    expect(s.cancelContract(), isFalse);
    s.character.runes = 500;
    expect(s.cancelContract(), isTrue);
    expect(s.character.runes, 400);
  });

  test('il contratto resta nel salvataggio', () async {
    final s = await _state();
    s.skillXp[Skill.expeditions] = _xpFor(30);
    s.signContract(contractors[3], random: Random(3));
    s.expeditionBossDown(expeditionById(s.contract!.targets.first));
    await Future<void>.delayed(Duration.zero);
    final t = GameState();
    await t.load();
    expect(t.contract!.contractorId, 'widow');
    expect(t.contract!.targets, s.contract!.targets);
    expect(t.contract!.done, {s.contract!.targets.first});
  });
}
