import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/ui/widgets/knight_view.dart';

void main() {
  test('la vecchia armatura intera si carica su tutti i pezzi', () {
    final j = Character().toJson()
      ..remove('worn')
      ..['armor'] = 'chainmail'
      ..['armors'] = ['chainmail'];
    final c = Character.fromJson(j);
    for (final slot in ArmorSlot.values) {
      expect(c.worn[slot], 'chainmail');
    }
    expect(c.damageReduction, closeTo(0.15, 1e-9));
    expect(Character.fromJson(c.toJson()).worn, c.worn);
  });

  test('i pezzi pesano per la loro quota e lo scudo si somma', () {
    final c = Character(armors: {'templar_plate'}, offhands: {'kite_shield'})
      ..worn[ArmorSlot.chest] = 'templar_plate'
      ..offhandId = 'kite_shield';
    expect(c.damageReduction, closeTo(0.22 * 0.45 + 0.12, 1e-9));
  });

  test('scudo e seconda lama contano solo con un\'arma a una mano', () {
    final c = Character(offhands: {'twin_blade'})..offhandId = 'twin_blade';
    expect(c.offhand?.id, 'twin_blade');
    c.weapon = WeaponInstance(weaponId: 'penitent_greatsword');
    expect(c.offhand, isNull);
    c.weapon = WeaponInstance(weaponId: 'ashwood_bow');
    expect(c.offhand, isNull);
  });

  test('gli strati del cavaliere partono sempre dal corpo base', () {
    final c = Character();
    final layers = knightLayers(c, KnightPose.attack);
    expect(layers.first, 'assets/art/knight/attack/base.png');
  });
}
