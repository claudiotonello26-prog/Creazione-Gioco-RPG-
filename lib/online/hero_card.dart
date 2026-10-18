import '../domain/character.dart';
import '../domain/items.dart';

/// Il biglietto da visita di un cavaliere: quello che gli altri vedono di
/// lui nella gilda e nella ricerca. Sul server sta tra gli oggetti salvati
/// (collezione `profile`, chiave `hero`), leggibile da tutti.
class HeroCard {
  HeroCard({
    required this.name,
    this.level = 1,
    Appearance? look,
    this.worn = const {},
    this.cape,
    this.weapon = 'pilgrim_blade',
  }) : look = look ?? Appearance();

  final String name;
  final int level;
  final Appearance look;
  final Map<ArmorSlot, String> worn;
  final String? cape;
  final String weapon;

  factory HeroCard.of(Character c) => HeroCard(
        name: c.name,
        level: c.level,
        look: c.look,
        worn: Map.of(c.worn),
        cape: c.capeId,
        weapon: c.weapon.weaponId,
      );

  WeaponInstance get weaponInstance =>
      WeaponInstance(weaponId: weaponDefs.containsKey(weapon) ? weapon : 'pilgrim_blade');

  Map<String, dynamic> toJson() => {
        'n': name,
        'lv': level,
        'look': look.toJson(),
        'worn': {for (final e in worn.entries) e.key.name: e.value},
        'cape': cape,
        'w': weapon,
      };

  /// Legge quello che arriva dal server: un campo strano non deve far
  /// sparire il giocatore, al massimo lo si vede senza armatura.
  static HeroCard? tryParse(Object? j) {
    if (j is! Map) return null;
    try {
      final worn = j['worn'] is Map ? j['worn'] as Map : const {};
      return HeroCard(
        name: j['n'] as String? ?? '',
        level: (j['lv'] as num?)?.toInt() ?? 1,
        look: j['look'] is Map
            ? Appearance.fromJson(Map<String, dynamic>.from(j['look'] as Map))
            : null,
        worn: {
          for (final slot in ArmorSlot.values)
            if (worn[slot.name] is String && armorDefs.containsKey(worn[slot.name]))
              slot: worn[slot.name] as String,
        },
        cape: j['cape'] is String && capeDefs.containsKey(j['cape']) ? j['cape'] as String : null,
        weapon: j['w'] as String? ?? 'pilgrim_blade',
      );
    } catch (_) {
      return null;
    }
  }
}
