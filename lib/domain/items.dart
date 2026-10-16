import 'character.dart';

/// Gradi di scaling stile souls.
enum ScalingGrade {
  s(1.2),
  a(1.0),
  b(0.8),
  c(0.6),
  d(0.4),
  e(0.2);

  const ScalingGrade(this.coefficient);
  final double coefficient;

  String get label => name.toUpperCase();
}

enum WeaponStyle {
  melee('Corpo a corpo'),
  ranged('Distanza'),
  magic('Magia');

  const WeaponStyle(this.label);
  final String label;
}

enum DamageType { physical, holy, magic }

class WeaponDef {
  const WeaponDef({
    required this.id,
    required this.name,
    required this.style,
    required this.baseDamage,
    required this.scaling,
    required this.damageType,
    this.rare = false,
    this.heavy = false,
    this.recipe = const {},
  });

  final String id;
  final String name;
  final WeaponStyle style;
  final int baseDamage;
  final Map<Attribute, ScalingGrade> scaling;
  final DamageType damageType;
  final bool rare;
  final bool heavy;

  /// Materiali necessari alla forgia; vuoto = non forgiabile.
  final Map<String, int> recipe;

  int get maxUpgrade => rare ? 5 : 10;
}

const Map<String, WeaponDef> weaponDefs = {
  'pilgrim_blade': WeaponDef(
    id: 'pilgrim_blade',
    name: 'Lama del Pellegrino',
    style: WeaponStyle.melee,
    baseDamage: 20,
    scaling: {Attribute.strength: ScalingGrade.d, Attribute.dexterity: ScalingGrade.b},
    damageType: DamageType.physical,
  ),
  'penitent_greatsword': WeaponDef(
    id: 'penitent_greatsword',
    name: 'Spadone del Penitente',
    style: WeaponStyle.melee,
    baseDamage: 30,
    heavy: true,
    scaling: {
      Attribute.strength: ScalingGrade.b,
      Attribute.faith: ScalingGrade.c,
      Attribute.dexterity: ScalingGrade.e,
    },
    damageType: DamageType.holy,
    recipe: {'iron_ore': 12, 'beast_essence': 4},
  ),
  'cathedral_hammer': WeaponDef(
    id: 'cathedral_hammer',
    name: 'Martello della Cattedrale',
    style: WeaponStyle.melee,
    baseDamage: 28,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.c, Attribute.faith: ScalingGrade.b},
    damageType: DamageType.holy,
    recipe: {'iron_ore': 10, 'holy_shard': 3},
  ),
  'ashwood_bow': WeaponDef(
    id: 'ashwood_bow',
    name: 'Arco di Frassino Cenere',
    style: WeaponStyle.ranged,
    baseDamage: 18,
    scaling: {Attribute.dexterity: ScalingGrade.a},
    damageType: DamageType.physical,
    recipe: {'ash_wood': 10, 'beast_essence': 2},
  ),
  'ember_staff': WeaponDef(
    id: 'ember_staff',
    name: 'Bastone della Brace',
    style: WeaponStyle.magic,
    baseDamage: 16,
    scaling: {Attribute.intelligence: ScalingGrade.a},
    damageType: DamageType.magic,
    recipe: {'ash_wood': 6, 'beast_essence': 6},
  ),
  'lord_of_the_keep_blade': WeaponDef(
    id: 'lord_of_the_keep_blade',
    name: 'Lama del Signore della Rocca',
    style: WeaponStyle.melee,
    baseDamage: 38,
    rare: true,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.a, Attribute.faith: ScalingGrade.d},
    damageType: DamageType.physical,
  ),
};

class WeaponInstance {
  WeaponInstance({required this.weaponId, this.upgrade = 0});

  final String weaponId;
  int upgrade;

  WeaponDef get def => weaponDefs[weaponId]!;

  String get displayName => upgrade > 0 ? '${def.name} +$upgrade' : def.name;

  /// A +3, +6 e +10 l'aspetto cambia.
  int get visualTier => switch (upgrade) {
        >= 10 => 3,
        >= 6 => 2,
        >= 3 => 1,
        _ => 0,
      };

  /// Potere d'attacco: danno base potenziato + scaling sugli attributi.
  double attackRating(Character c, {double amuletBonus = 0}) {
    final base = def.baseDamage * (1 + 0.12 * upgrade);
    var scaled = 0.0;
    def.scaling.forEach((attr, grade) {
      scaled += (c.attr(attr) - Character.baseAttribute).clamp(0, 99) *
          grade.coefficient *
          (1 + 0.05 * upgrade);
    });
    return (base + scaled) * (1 + amuletBonus);
  }

  /// Pietra richiesta per il prossimo potenziamento.
  String? get nextStone {
    if (upgrade >= def.maxUpgrade) return null;
    if (def.rare) return 'somber_stone';
    final next = upgrade + 1;
    if (next <= 3) return 'forge_stone_1';
    if (next <= 6) return 'forge_stone_2';
    if (next <= 9) return 'forge_stone_3';
    return 'ancient_stone';
  }

  int get nextStoneCost => def.rare ? upgrade + 1 : (upgrade % 3) + 1;

  Map<String, dynamic> toJson() => {'id': weaponId, 'up': upgrade};

  factory WeaponInstance.fromJson(Map<String, dynamic> j) =>
      WeaponInstance(weaponId: j['id'] as String, upgrade: j['up'] as int);
}

class Amulet {
  const Amulet(this.id, this.name, this.description, this.apply);
  final String id;
  final String name;
  final String description;
  final AmuletEffect apply;
}

class AmuletEffect {
  const AmuletEffect({
    this.holyDamage = 0,
    this.heavyDamage = 0,
    this.rareLoot = 0,
    this.lowHpDamage = 0,
  });
  final double holyDamage;
  final double heavyDamage;
  final double rareLoot;
  final double lowHpDamage;
}

const Map<String, Amulet> amuletDefs = {
  'fervent': Amulet('fervent', 'Amuleto del Fervente', '+10% danno sacro',
      AmuletEffect(holyDamage: 0.10)),
  'colossus_seal': Amulet('colossus_seal', 'Sigillo del Colosso',
      '+8% danno con armi pesanti', AmuletEffect(heavyDamage: 0.08)),
  'hunter_heart': Amulet('hunter_heart', 'Cuore del Cacciatore',
      '+10% probabilità di bottino raro contro le bestie',
      AmuletEffect(rareLoot: 0.10)),
  'martyr_relic': Amulet('martyr_relic', 'Reliquia del Martire',
      '+15% danno quando la vita è sotto il 30%',
      AmuletEffect(lowHpDamage: 0.15)),
};

const Map<String, String> materialNames = {
  'iron_ore': 'Minerale di ferro',
  'ash_wood': 'Legno di frassino cenere',
  'beast_essence': 'Essenza di bestia',
  'holy_shard': 'Scheggia sacra',
  'forge_stone_1': 'Pietra di forgia I',
  'forge_stone_2': 'Pietra di forgia II',
  'forge_stone_3': 'Pietra di forgia III',
  'ancient_stone': 'Pietra antica',
  'somber_stone': 'Pietra cupa',
};

/// Alla fornace: minerale dai passi + essenza dai mostri = Pietra di forgia I.
const Map<String, int> forgeStone1Recipe = {'iron_ore': 3, 'beast_essence': 1};
