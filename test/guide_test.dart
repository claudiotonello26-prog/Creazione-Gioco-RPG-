import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
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
}
