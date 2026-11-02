import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/core/i18n.dart';
import 'package:iron_oath/domain/hunting.dart';
import 'package:iron_oath/domain/items.dart';

/// Nomi di esercizi già inglesi: restano così in tutte e due le lingue.
const _alreadyEnglish = {'Squat', 'Push-up', 'Crunch', 'Leg raise', 'Jumping jack', 'High knees'};

void main() {
  setUp(() => appLang = Lang.it);
  tearDown(() => appLang = Lang.it);

  /// Ogni testo mostrato da oggetti, materiali, mercato e caccia.
  Map<String, String> texts() => {
        for (final s in WeaponStyle.values) s.label: 'WeaponStyle.${s.name}',
        for (final s in Station.values) ...{
          s.label: 'Station.${s.name}',
          s.description: 'Station.${s.name}.description',
        },
        for (final a in Affinity.values) ...{
          a.label: 'Affinity.${a.name}',
          a.attributeLabel: 'Affinity.${a.name}.attribute',
        },
        for (final s in ArmorSlot.values) s.label: 'ArmorSlot.${s.name}',
        for (final w in weaponDefs.values) w.nameIt: 'weapon ${w.id}',
        for (final a in armorDefs.values) a.nameIt: 'armor ${a.id}',
        for (final c in capeDefs.values) c.nameIt: 'cape ${c.id}',
        for (final o in offhandDefs.values) o.nameIt: 'offhand ${o.id}',
        for (final a in amuletDefs.values) ...{
          a.nameIt: 'amulet ${a.id}',
          a.descriptionIt: 'amulet ${a.id}.description',
        },
        for (final e in materialNamesIt.entries) e.value: 'material ${e.key}',
        'Assorbe un altro {pct}% dei colpi': 'effect',
        'Solo stile': 'effect',
        '+{pct}% di danno con due lame': 'effect',
        for (final e in [...baseAnimals, ...huntAnimals]) ...{
          e.name: 'hunt ${e.id}',
          e.region: 'hunt ${e.id}.region',
          for (final m in e.moves)
            if (!_alreadyEnglish.contains(m.name)) m.name: 'hunt ${e.id}.move',
        },
      };

  test('ogni testo di oggetti, materiali e caccia ha la traduzione inglese', () {
    final missing = [
      for (final e in texts().entries)
        if (!enStrings.containsKey(e.key)) '${e.value}: ${e.key}',
    ];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('in inglese nomi ed effetti cambiano lingua', () {
    appLang = Lang.en;
    expect(weaponDefs['pilgrim_blade']!.name, 'Pilgrim\'s Blade');
    expect(weaponDefs['star_greatsword']!.name, 'Starforged Greatsword');
    expect(WeaponInstance(weaponId: 'pilgrim_blade', upgrade: 2).displayName, 'Pilgrim\'s Blade +2');
    expect(materialNames['iron_ingot'], 'Iron ingot');
    expect(itemName('fervent'), 'Amulet of the Fervent');
    expect(Station.furnace.label, 'Furnace');
    expect(capeDefs['oath_cape']!.effect, 'Absorbs another 5% of each blow');
    expect(offhandDefs['twin_blade']!.effect, '+12% damage when dual-wielding');
    appLang = Lang.it;
    expect(weaponDefs['pilgrim_blade']!.name, 'Lama del Pellegrino');
    expect(materialNames['iron_ingot'], 'Lingotto di ferro');
    expect(capeDefs['pilgrim_cape']!.effect, 'Solo stile');
  });
}
