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
    expect(c.damageReduction, closeTo(0.22 * 0.40 + 0.12, 1e-9));
  });

  test('bracciali e stivali arrivano dalla corazza e dai gambali già addosso', () {
    final j = Character().toJson()
      ..['worn'] = {'helm': 'chainmail', 'chest': 'chainmail', 'legs': 'gambeson'}
      ..['armors'] = ['chainmail', 'gambeson']
      ..remove('capes')
      ..remove('cape');
    final c = Character.fromJson(j);
    expect(c.worn[ArmorSlot.gloves], 'chainmail');
    expect(c.worn[ArmorSlot.boots], 'gambeson');
    expect(c.capeId, 'pilgrim_cape', reason: 'il mantello di sempre resta addosso');
  });

  test('mantello e amuleto al collo contano e si salvano', () {
    final c = Character(capes: {'pilgrim_cape', 'oath_cape'})
      ..capeId = 'oath_cape'
      ..neck = 'regicide_seal';
    expect(c.damageReduction, closeTo(0.05, 1e-9));
    expect(c.wornAmulets.map((a) => a.id), contains('regicide_seal'));
    final back = Character.fromJson(c.toJson());
    expect(back.capeId, 'oath_cape');
    expect(back.neck, 'regicide_seal');
    c.capeId = null;
    expect(Character.fromJson(c.toJson()).capeId, isNull);
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
