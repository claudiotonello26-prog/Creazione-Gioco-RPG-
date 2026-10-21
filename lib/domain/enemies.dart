// I nomi restano in italiano nel campo privato e si traducono nel getter.
// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import '../core/i18n.dart';
import 'exercise.dart';
import 'items.dart';

class EnemyDef {
  const EnemyDef({
    required this.id,
    required String name,
    required this.tier,
    required String region,
    this.isBoss = false,
    this.isBeast = false,
    this.isAnimal = false,
    this.isVeteran = false,
    this.weakTo,
    this.strongAgainst,
    this.loot = const {},
    this.rareDrop,
    this.rareDropChance = 0,
    required this.moves,
    required this.level,
    required this.group,
  })  : _name = name,
        _region = region;

  /// Con cosa lo si batte: se sono più d'uno, sceglie il giocatore (il boss
  /// li alterna).
  final List<Move> moves;

  /// Modelli di movimento usati dal contatore.
  List<ExerciseId> get exercises => [for (final m in moves) m.trackAs];

  /// Livello consigliato della spedizione da cui viene.
  final int level;
  final MuscleGroup group;

  final String id;
  final String _name;

  /// Il nome base in italiano, senza «(Veterano)»: per confronti e chiavi.
  String get nameIt => _name;

  /// Il nome da mostrare, nella lingua corrente, con «(Veterano)» se serve.
  String get name => isVeteran
      ? tr('{name} (Veterano)', {'name': tr(_name)})
      : tr(_name);

  /// Gradino 1–5: decide rep richieste, difesa e forza dei colpi.
  final int tier;
  final String _region;
  String get region => tr(_region);
  final bool isBoss;
  final bool isBeast;

  /// Animale da caccia: l'immagine sta in assets/art/animals.
  final bool isAnimal;

  /// Versione Veterano di una tappa: stessa immagine con il bordo rosso.
  final bool isVeteran;
  final WeaponStyle? weakTo;
  final WeaponStyle? strongAgainst;
  final Map<String, int> loot;
  final String? rareDrop;
  final double rareDropChance;

  /// Comuni: le risorse che lascia SEMPRE, una o due, nelle quantità
  /// mostrate (poi scalate dallo sforzo).
  Map<String, int> get commonLoot {
    final out = <String, int>{
      for (final e in loot.entries)
        if (dropRarity(e.key) == Rarity.common) e.key: e.value,
    };
    // Gli spiriti dello Stretching lasciano pietre e gemme: sono le loro
    // risorse.
    if (out.isEmpty) out.addAll(loot);
    return Map.fromEntries(out.entries.take(2));
  }

  /// Non comuni possibili (da 1 a 4): solo dal livello [uncommonFromLevel],
  /// mai dagli animali.
  List<String> get uncommonLoot {
    if (isAnimal || level < uncommonFromLevel) return const [];
    final common = commonLoot.keys.toSet();
    final out = <String>[
      for (final id in loot.keys)
        if (!common.contains(id) && dropRarity(id) == Rarity.uncommon) id,
      if (rareDrop != null && dropRarity(rareDrop!) == Rarity.uncommon) rareDrop!,
    ];
    // Il gradino porta con sé le sue pietre e schegge.
    for (final id in _tierUncommons[tier - 1]) {
      if (out.length >= 2) break;
      if (!out.contains(id)) out.add(id);
    }
    return out.toSet().take(4).toList();
  }

  /// Rari possibili (al massimo 2): solo dal livello [rareFromLevel].
  List<String> get rareLoot {
    if (isAnimal || level < rareFromLevel) return const [];
    final common = commonLoot.keys.toSet();
    final out = <String>[
      if (rareDrop != null && dropRarity(rareDrop!) == Rarity.rare) rareDrop!,
      for (final id in loot.keys)
        if (!common.contains(id) && dropRarity(id) == Rarity.rare) id,
    ];
    if (out.length < 2) {
      final extra = _tierRares[tier - 1];
      if (extra != null && !out.contains(extra)) out.add(extra);
    }
    return out.toSet().take(2).toList();
  }

  /// Probabilità che una vittoria si trasformi in un non comune o in un
  /// raro al posto dei comuni: zero sotto il livello 5, poi cresce del 4,5%
  /// a livello (≈5% al 10, 8% al 22, 20% al 41, 35% dal 55), ×1,5 per boss
  /// e Veterani.
  double get specialChance {
    if (uncommonLoot.isEmpty && rareLoot.isEmpty) return 0;
    var p = 0.04 * pow(1.045, level - uncommonFromLevel);
    if (isBoss) p *= 1.5;
    if (isVeteran) p *= 1.5;
    return min(isBoss ? 0.5 : 0.35, p.toDouble());
  }

  /// Fra i drop speciali, quota dei rari: dall'8% al livello 10 fino al
  /// 35%.
  double get rareShare {
    if (rareLoot.isEmpty) return 0;
    if (uncommonLoot.isEmpty) return 1;
    return min(0.35, 0.08 * pow(1.04, level - rareFromLevel)).toDouble();
  }

  /// Tira il drop speciale di una vittoria: null se restano i comuni,
  /// altrimenti l'id del pezzo non comune o raro che li sostituisce.
  /// [multiplier] alza la probabilità (caccia infinita, bottino), [bonus] la
  /// somma (amuleti da cacciatore).
  String? rollSpecial(Random random, {double multiplier = 1, double bonus = 0}) {
    if (random.nextDouble() >= min(0.9, specialChance * multiplier + bonus)) return null;
    final rares = rareLoot, uncommons = uncommonLoot;
    final pickRare = rares.isNotEmpty && (uncommons.isEmpty || random.nextDouble() < rareShare);
    final pool = pickRare ? rares : uncommons;
    return pool.isEmpty ? null : pool[random.nextInt(pool.length)];
  }

  static const int uncommonFromLevel = 5, rareFromLevel = 10;
  static const List<List<String>> _tierUncommons = [
    ['forge_stone_1'],
    ['forge_stone_1', 'holy_shard'],
    ['forge_stone_2', 'holy_shard'],
    ['forge_stone_2', 'gem_rough'],
    ['forge_stone_2', 'gem_cut'],
  ];
  static const List<String?> _tierRares = [
    null,
    'somber_stone',
    'somber_stone',
    'ancient_stone',
    'ancient_stone',
  ];

  /// Il mostro come lo si incontra su una tappa: gradino e livello della
  /// tappa, e da Veterano bottino ×1,5 e raro ×2.
  EnemyDef atStep(ExpeditionStep step) => EnemyDef(
        id: id,
        name: _name,
        tier: step.tier,
        region: _region,
        isBoss: isBoss,
        isBeast: isBeast,
        isAnimal: isAnimal,
        isVeteran: step.veteran,
        weakTo: weakTo,
        strongAgainst: strongAgainst,
        loot: step.veteran
            ? {for (final e in loot.entries) e.key: (e.value * 1.5).ceil()}
            : loot,
        rareDrop: rareDrop,
        rareDropChance: step.veteran ? rareDropChance * 2 : rareDropChance,
        moves: [step.move],
        level: step.level,
        group: group,
      );

  /// Quota del test richiesta per abbatterlo con rep perfette.
  /// Con test di 20 push-up: gradino 1 → 12, gradino 3 → 15, gradino 5 → 20.
  double get repFactor => const [0.6, 0.68, 0.75, 0.88, 1.0][tier - 1] *
      (isBoss ? 1.6 : 1.0);

  /// Potere d'attacco minimo per colpire a pieno.
  double get defense => const [15.0, 24.0, 34.0, 46.0, 60.0][tier - 1] *
      (isBoss ? 1.15 : 1.0);

  /// Margine di tempo che il nemico concede: con 1.9 l'eroe base muore dopo
  /// 1,9 volte il tempo che serve ad abbatterlo al ritmo giusto. Più basso =
  /// più difficile.
  double get pressure => const [1.9, 1.75, 1.6, 1.45, 1.35][tier - 1] * (isBoss ? 0.9 : 1.0);

  /// Secondi tra un attacco e l'altro, in media: il colpo vero arriva a un
  /// momento a caso fra metà e una volta e mezzo, senza barra che lo annunci.
  double get attackInterval => isBoss ? 3.5 : 4.0;

  /// Probabilità che un colpo sia critico (×[critMultiplier]).
  double get critChance => isBoss ? 0.15 : 0.08;
  static const double critMultiplier = 1.8;

  /// Elemento del nemico, dal gruppo: la Spinta è Fuoco (forge e giganti),
  /// le Gambe Vento, il Core Luce (cripte e cattedrali), il Cardio Arcano
  /// (stelle e biblioteche). Lo Stretching non ne ha.
  Affinity? get element => switch (group) {
        MuscleGroup.push => Affinity.fire,
        MuscleGroup.legs => Affinity.wind,
        MuscleGroup.core => Affinity.holy,
        MuscleGroup.cardio => Affinity.arcane,
        _ => null,
      };

  /// L'elemento pesa per intero sui boss e a metà sugli altri nemici.
  double get elementWeight => isBoss ? 1.0 : 0.5;

  /// Rune per uccisione: crescono più delle rep richieste, così per ogni rep
  /// un nemico più duro paga di più.
  int get runeReward => const [20, 40, 65, 95, 130][tier - 1] * (isBoss ? 3 : 1);
}

/// I nemici del mondo, dal piano dei contenuti: per ogni gruppo quattro
/// spedizioni con due mostri (che tornano da Veterani) e un boss.
const Map<String, EnemyDef> enemyDefs = {
  'slag_goblin': EnemyDef(
    id: 'slag_goblin',
    name: 'Goblin delle Scorie',
    tier: 1,
    level: 1,
    group: MuscleGroup.push,
    region: 'Le Forge Sepolte',
    isBeast: true,
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Push-up inclinati', ExerciseId.pushUp, ratio: 0.65),
      Move('Push-up', ExerciseId.pushUp),
    ],
    loot: {'iron_ingot': 1, 'bone': 2},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.08,
  ),
  'hollow_apprentice': EnemyDef(
    id: 'hollow_apprentice',
    name: 'Garzone Svuotato',
    tier: 1,
    level: 3,
    group: MuscleGroup.push,
    region: 'Le Forge Sepolte',
    moves: [
      Move('Push-up sulle ginocchia', ExerciseId.pushUp, ratio: 0.65),
      Move('Push-up larghi', ExerciseId.pushUp),
    ],
    loot: {'iron_ingot': 1, 'coal': 3},
    rareDrop: 'reinforced_grip',
    rareDropChance: 0.06,
  ),
  'hollow_smith': EnemyDef(
    id: 'hollow_smith',
    name: 'Il Fabbro Svuotato',
    tier: 2,
    level: 9,
    group: MuscleGroup.push,
    region: 'Le Forge Sepolte',
    isBoss: true,
    moves: [
      Move('Push-up inclinati', ExerciseId.pushUp, ratio: 0.65),
      Move('Push-up sulle ginocchia', ExerciseId.pushUp, ratio: 0.65),
      Move('Push-up', ExerciseId.pushUp),
      Move('Push-up larghi', ExerciseId.pushUp),
    ],
    loot: {'iron_ingot': 2, 'bone': 2, 'forge_stone_1': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'fallen_knight': EnemyDef(
    id: 'fallen_knight',
    name: 'Cavaliere Caduto',
    tier: 2,
    level: 10,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
    ],
    loot: {'iron_ingot': 2, 'steel_ingot': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.06,
  ),
  'keep_sentinel': EnemyDef(
    id: 'keep_sentinel',
    name: 'Sentinella del Bastione',
    tier: 2,
    level: 13,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    moves: [
      Move('Push-up larghi', ExerciseId.pushUp),
    ],
    loot: {'steel_ingot': 1, 'iron_ingot': 1},
    rareDrop: 'holy_shard',
    rareDropChance: 0.08,
  ),
  'wall_archer': EnemyDef(
    id: 'wall_archer',
    name: 'Arciere delle Mura',
    tier: 3,
    level: 16,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    moves: [
      Move('Dip su sedia', ExerciseId.pushUp),
    ],
    loot: {'steel_ingot': 1, 'beast_essence': 1},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.12,
  ),
  'keep_brute': EnemyDef(
    id: 'keep_brute',
    name: 'Carceriere del Bastione',
    tier: 3,
    level: 19,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    moves: [
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2),
    ],
    loot: {'steel_ingot': 2},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.08,
  ),
  'iron_castellan': EnemyDef(
    id: 'iron_castellan',
    name: 'Il Castellano di Ferro',
    tier: 3,
    level: 22,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    isBoss: true,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
      Move('Push-up larghi', ExerciseId.pushUp),
      Move('Dip su sedia', ExerciseId.pushUp),
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2),
    ],
    loot: {'steel_ingot': 3, 'forge_stone_2': 1},
    rareDrop: 'ancient_stone',
    rareDropChance: 0.03,
  ),
  'ember_giant': EnemyDef(
    id: 'ember_giant',
    name: 'Gigante di Brace',
    tier: 3,
    level: 25,
    group: MuscleGroup.push,
    region: 'La Fornace dei Giganti',
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2),
      Move('Dip su sedia', ExerciseId.pushUp),
    ],
    loot: {'ember_iron': 2, 'bone': 3},
    rareDrop: 'ember_heart',
    rareDropChance: 0.01,
  ),
  'chained_stoker': EnemyDef(
    id: 'chained_stoker',
    name: 'Fuochista Incatenato',
    tier: 3,
    level: 29,
    group: MuscleGroup.push,
    region: 'La Fornace dei Giganti',
    moves: [
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2),
      Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175),
    ],
    loot: {'ember_iron': 1, 'coal': 5, 'steel_ingot': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'living_bellows': EnemyDef(
    id: 'living_bellows',
    name: 'Il Mantice Vivente',
    tier: 4,
    level: 41,
    group: MuscleGroup.push,
    region: 'La Fornace dei Giganti',
    isBoss: true,
    moves: [
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2),
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2),
      Move('Dip su sedia', ExerciseId.pushUp),
      Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175),
    ],
    loot: {'ember_iron': 4, 'forge_stone_2': 1},
    rareDrop: 'ember_heart',
    rareDropChance: 0.05,
  ),
  'forge_servant': EnemyDef(
    id: 'forge_servant',
    name: 'Servo della Fucina',
    tier: 4,
    level: 45,
    group: MuscleGroup.push,
    region: 'La Fucina degli Dei',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Pike push-up piedi sulla sedia', ExerciseId.pushUp, ratio: 0.175),
      Move('Push-up esplosivi', ExerciseId.pushUp, ratio: 0.2),
    ],
    loot: {'godforge_steel': 2, 'ember_iron': 1},
    rareDrop: 'forge_stone_3',
    rareDropChance: 0.06,
  ),
  'anvil_golem': EnemyDef(
    id: 'anvil_golem',
    name: 'Golem dell\'Incudine',
    tier: 4,
    level: 50,
    group: MuscleGroup.push,
    region: 'La Fucina degli Dei',
    moves: [
      Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175),
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2),
    ],
    loot: {'godforge_steel': 1, 'steel_ingot': 2, 'ember_iron': 1},
    rareDrop: 'ember_heart',
    rareDropChance: 0.03,
  ),
  'fallen_smith_god': EnemyDef(
    id: 'fallen_smith_god',
    name: 'Il Dio Fabbro Decaduto',
    tier: 5,
    level: 65,
    group: MuscleGroup.push,
    region: 'La Fucina degli Dei',
    isBoss: true,
    moves: [
      Move('Pike push-up piedi sulla sedia', ExerciseId.pushUp, ratio: 0.175),
      Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175),
      Move('Push-up esplosivi', ExerciseId.pushUp, ratio: 0.2),
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2),
    ],
    loot: {'godforge_steel': 4, 'forge_stone_3': 1, 'ancient_stone': 1},
    rareDrop: 'ember_heart',
    rareDropChance: 0.1,
  ),
  'hollow_goblin': EnemyDef(
    id: 'hollow_goblin',
    name: 'Goblin Svuotato',
    tier: 1,
    level: 1,
    group: MuscleGroup.legs,
    region: 'Il Bosco di Cenere',
    isBeast: true,
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3),
    ],
    loot: {'bone': 3, 'raw_hide': 1},
    rareDrop: 'beast_essence',
    rareDropChance: 0.15,
  ),
  'ash_scarecrow': EnemyDef(
    id: 'ash_scarecrow',
    name: 'Spaventapasseri di Cenere',
    tier: 1,
    level: 3,
    group: MuscleGroup.legs,
    region: 'Il Bosco di Cenere',
    moves: [
      Move('Affondi', ExerciseId.lunge),
      Move('Step-up sulla sedia', ExerciseId.lunge),
    ],
    loot: {'ash_wood': 4, 'raw_hide': 1},
    rareDrop: 'reinforced_grip',
    rareDropChance: 0.06,
  ),
  'hollow_stag': EnemyDef(
    id: 'hollow_stag',
    name: 'Il Cervo Cavo',
    tier: 2,
    level: 9,
    group: MuscleGroup.legs,
    region: 'Il Bosco di Cenere',
    isBoss: true,
    isBeast: true,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Affondi', ExerciseId.lunge),
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3),
      Move('Step-up sulla sedia', ExerciseId.lunge),
    ],
    loot: {'raw_hide': 3, 'bone': 3, 'beast_essence': 2},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.25,
  ),
  'carrion_hound': EnemyDef(
    id: 'carrion_hound',
    name: 'Segugio della Carogna',
    tier: 2,
    level: 10,
    group: MuscleGroup.legs,
    region: 'La Palude dei Cacciatori',
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3),
    ],
    loot: {'tanned_leather': 1, 'beast_essence': 2},
    rareDrop: 'raw_hide',
    rareDropChance: 0.2,
  ),
  'bog_drowned': EnemyDef(
    id: 'bog_drowned',
    name: 'Annegato della Palude',
    tier: 2,
    level: 13,
    group: MuscleGroup.legs,
    region: 'La Palude dei Cacciatori',
    moves: [
      Move('Affondi', ExerciseId.lunge),
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
    ],
    loot: {'tanned_leather': 1, 'raw_hide': 2, 'oak_wood': 3},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.06,
  ),
  'marsh_matron': EnemyDef(
    id: 'marsh_matron',
    name: 'La Matrona della Palude',
    tier: 3,
    level: 22,
    group: MuscleGroup.legs,
    region: 'La Palude dei Cacciatori',
    isBoss: true,
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Affondi', ExerciseId.lunge),
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3),
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
    ],
    loot: {'tanned_leather': 3, 'beast_essence': 3, 'forge_stone_2': 1},
    rareDrop: 'ancient_stone',
    rareDropChance: 0.03,
  ),
  'gorge_harpy': EnemyDef(
    id: 'gorge_harpy',
    name: 'Arpia delle Gole',
    tier: 3,
    level: 25,
    group: MuscleGroup.legs,
    region: 'Le Gole del Vento',
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
      Move('Step-up sulla sedia', ExerciseId.lunge),
    ],
    loot: {'gale_silver': 2, 'raw_hide': 2},
    rareDrop: 'storm_eye',
    rareDropChance: 0.01,
  ),
  'cliff_raider': EnemyDef(
    id: 'cliff_raider',
    name: 'Predone delle Gole',
    tier: 3,
    level: 29,
    group: MuscleGroup.legs,
    region: 'Le Gole del Vento',
    moves: [
      Move('Squat bulgaro sulla sedia', ExerciseId.lunge),
      Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2),
    ],
    loot: {'gale_silver': 1, 'tanned_leather': 2},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'weightless_knight': EnemyDef(
    id: 'weightless_knight',
    name: 'Il Cavaliere Senza Peso',
    tier: 4,
    level: 41,
    group: MuscleGroup.legs,
    region: 'Le Gole del Vento',
    isBoss: true,
    moves: [
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
      Move('Squat bulgaro sulla sedia', ExerciseId.lunge),
      Move('Step-up sulla sedia', ExerciseId.lunge),
      Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2),
    ],
    loot: {'gale_silver': 4, 'forge_stone_2': 1},
    rareDrop: 'storm_eye',
    rareDropChance: 0.05,
  ),
  'wind_sentinel': EnemyDef(
    id: 'wind_sentinel',
    name: 'Sentinella del Vento',
    tier: 4,
    level: 45,
    group: MuscleGroup.legs,
    region: 'La Vetta della Bufera',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2),
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
    ],
    loot: {'steel_feather': 2, 'gale_silver': 1},
    rareDrop: 'forge_stone_3',
    rareDropChance: 0.06,
  ),
  'thunder_ram': EnemyDef(
    id: 'thunder_ram',
    name: 'Ariete del Tuono',
    tier: 4,
    level: 50,
    group: MuscleGroup.legs,
    region: 'La Vetta della Bufera',
    moves: [
      Move('Squat bulgaro sulla sedia', ExerciseId.lunge),
      Move('Pistol squat assistito', ExerciseId.squat, ratio: 0.15),
    ],
    loot: {'steel_feather': 1, 'tanned_leather': 3, 'gale_silver': 1},
    rareDrop: 'storm_eye',
    rareDropChance: 0.03,
  ),
  'storm_king': EnemyDef(
    id: 'storm_king',
    name: 'Il Re della Tempesta',
    tier: 5,
    level: 65,
    group: MuscleGroup.legs,
    region: 'La Vetta della Bufera',
    isBoss: true,
    moves: [
      Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2),
      Move('Squat bulgaro sulla sedia', ExerciseId.lunge),
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
      Move('Pistol squat assistito', ExerciseId.squat, ratio: 0.15),
    ],
    loot: {'steel_feather': 4, 'forge_stone_3': 1, 'somber_stone': 1},
    rareDrop: 'storm_eye',
    rareDropChance: 0.1,
  ),
  'bronze_skeleton': EnemyDef(
    id: 'bronze_skeleton',
    name: 'Scheletro di Bronzo',
    tier: 1,
    level: 1,
    group: MuscleGroup.core,
    region: 'La Cripta di Bronzo',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Plank', ExerciseId.plank),
    ],
    loot: {'bronze_ingot': 2, 'bone': 2},
    rareDrop: 'holy_shard',
    rareDropChance: 0.08,
  ),
  'tomb_crawler': EnemyDef(
    id: 'tomb_crawler',
    name: 'Strisciante delle Tombe',
    tier: 1,
    level: 3,
    group: MuscleGroup.core,
    region: 'La Cripta di Bronzo',
    moves: [
      Move('Leg raise', ExerciseId.legRaise),
      Move('Superman', ExerciseId.crunch),
    ],
    loot: {'bronze_ingot': 1, 'bone': 3},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.08,
  ),
  'crypt_keeper': EnemyDef(
    id: 'crypt_keeper',
    name: 'Il Custode della Cripta',
    tier: 2,
    level: 9,
    group: MuscleGroup.core,
    region: 'La Cripta di Bronzo',
    isBoss: true,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Leg raise', ExerciseId.legRaise),
      Move('Plank', ExerciseId.plank),
      Move('Superman', ExerciseId.crunch),
    ],
    loot: {'bronze_ingot': 4, 'bone': 3, 'holy_shard': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'ash_wyrm': EnemyDef(
    id: 'ash_wyrm',
    name: 'Viverna di Cenere',
    tier: 2,
    level: 10,
    group: MuscleGroup.core,
    region: 'Il Tempio Dorato',
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Plank', ExerciseId.plank),
    ],
    loot: {'gold_ingot': 1, 'holy_shard': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.06,
  ),
  'gilded_acolyte': EnemyDef(
    id: 'gilded_acolyte',
    name: 'Accolito Dorato',
    tier: 2,
    level: 13,
    group: MuscleGroup.core,
    region: 'Il Tempio Dorato',
    moves: [
      Move('Leg raise', ExerciseId.legRaise),
      Move('Russian twist', ExerciseId.crunch),
    ],
    loot: {'gold_ingot': 1, 'bronze_ingot': 2},
    rareDrop: 'holy_shard',
    rareDropChance: 0.2,
  ),
  'golden_priest': EnemyDef(
    id: 'golden_priest',
    name: 'Il Sacerdote d\'Oro',
    tier: 3,
    level: 22,
    group: MuscleGroup.core,
    region: 'Il Tempio Dorato',
    isBoss: true,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Leg raise', ExerciseId.legRaise),
      Move('Plank', ExerciseId.plank),
      Move('Russian twist', ExerciseId.crunch),
    ],
    loot: {'gold_ingot': 3, 'holy_shard': 2},
    rareDrop: 'ancient_stone',
    rareDropChance: 0.03,
  ),
  'penitent': EnemyDef(
    id: 'penitent',
    name: 'Il Penitente',
    tier: 3,
    level: 25,
    group: MuscleGroup.core,
    region: 'Il Santuario Consacrato',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.2),
      Move('Plank', ExerciseId.plank),
    ],
    loot: {'hallowed_gold': 2, 'holy_shard': 1},
    rareDrop: 'martyr_tear',
    rareDropChance: 0.01,
  ),
  'censer_bearer': EnemyDef(
    id: 'censer_bearer',
    name: 'Portaturibolo',
    tier: 3,
    level: 29,
    group: MuscleGroup.core,
    region: 'Il Santuario Consacrato',
    moves: [
      Move('Russian twist', ExerciseId.crunch),
      Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225),
    ],
    loot: {'hallowed_gold': 1, 'gold_ingot': 2},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'chained_maiden': EnemyDef(
    id: 'chained_maiden',
    name: 'La Vergine Incatenata',
    tier: 4,
    level: 41,
    group: MuscleGroup.core,
    region: 'Il Santuario Consacrato',
    isBoss: true,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.2),
      Move('Russian twist', ExerciseId.crunch),
      Move('Plank', ExerciseId.plank),
      Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225),
    ],
    loot: {'hallowed_gold': 4, 'forge_stone_2': 1},
    rareDrop: 'martyr_tear',
    rareDropChance: 0.05,
  ),
  'black_inquisitor': EnemyDef(
    id: 'black_inquisitor',
    name: 'Inquisitore Nero',
    tier: 4,
    level: 45,
    group: MuscleGroup.core,
    region: 'La Cattedrale del Martire',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.2),
      Move('Plank laterale', ExerciseId.plank),
    ],
    loot: {'martyr_obsidian': 2, 'hallowed_gold': 1},
    rareDrop: 'forge_stone_3',
    rareDropChance: 0.06,
  ),
  'cathedral_gargoyle': EnemyDef(
    id: 'cathedral_gargoyle',
    name: 'Gargoyle della Cattedrale',
    tier: 4,
    level: 50,
    group: MuscleGroup.core,
    region: 'La Cattedrale del Martire',
    moves: [
      Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225),
      Move('Leg raise', ExerciseId.legRaise),
    ],
    loot: {'martyr_obsidian': 1, 'gold_ingot': 2, 'hallowed_gold': 1},
    rareDrop: 'martyr_tear',
    rareDropChance: 0.03,
  ),
  'eternal_martyr': EnemyDef(
    id: 'eternal_martyr',
    name: 'Il Martire Eterno',
    tier: 5,
    level: 65,
    group: MuscleGroup.core,
    region: 'La Cattedrale del Martire',
    isBoss: true,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.2),
      Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225),
      Move('Plank laterale', ExerciseId.plank),
      Move('Leg raise', ExerciseId.legRaise),
    ],
    loot: {'martyr_obsidian': 4, 'forge_stone_3': 1, 'ancient_stone': 1},
    rareDrop: 'martyr_tear',
    rareDropChance: 0.1,
  ),
  'spectral_archer': EnemyDef(
    id: 'spectral_archer',
    name: 'Arciere Spettrale',
    tier: 1,
    level: 1,
    group: MuscleGroup.cardio,
    region: 'Le Rovine Lunari',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'silver_ingot': 1, 'beast_essence': 1},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.08,
  ),
  'lunar_wisp': EnemyDef(
    id: 'lunar_wisp',
    name: 'Fuoco Fatuo Lunare',
    tier: 1,
    level: 3,
    group: MuscleGroup.cardio,
    region: 'Le Rovine Lunari',
    moves: [
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
      Move('Squat veloci', ExerciseId.squat),
    ],
    loot: {'moon_silver': 4, 'beast_essence': 1},
    rareDrop: 'gem_rough',
    rareDropChance: 0.1,
  ),
  'moon_moth': EnemyDef(
    id: 'moon_moth',
    name: 'La Falena di Luna',
    tier: 2,
    level: 9,
    group: MuscleGroup.cardio,
    region: 'Le Rovine Lunari',
    isBoss: true,
    isBeast: true,
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
      Move('Squat veloci', ExerciseId.squat),
    ],
    loot: {'silver_ingot': 1, 'beast_essence': 2, 'bone': 2},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'drowned_scribe': EnemyDef(
    id: 'drowned_scribe',
    name: 'Scriba Annegato',
    tier: 2,
    level: 10,
    group: MuscleGroup.cardio,
    region: 'La Biblioteca Allagata',
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'abyss_ink': 2, 'silver_ingot': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.06,
  ),
  'living_tome': EnemyDef(
    id: 'living_tome',
    name: 'Tomo Vivente',
    tier: 2,
    level: 13,
    group: MuscleGroup.cardio,
    region: 'La Biblioteca Allagata',
    moves: [
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
    ],
    loot: {'abyss_ink': 2},
    rareDrop: 'gem_cut',
    rareDropChance: 0.08,
  ),
  'eyeless_librarian': EnemyDef(
    id: 'eyeless_librarian',
    name: 'Il Bibliotecario Senz\'Occhi',
    tier: 3,
    level: 22,
    group: MuscleGroup.cardio,
    region: 'La Biblioteca Allagata',
    isBoss: true,
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
    ],
    loot: {'abyss_ink': 3, 'forge_stone_2': 1},
    rareDrop: 'ancient_stone',
    rareDropChance: 0.03,
  ),
  'mad_astrologer': EnemyDef(
    id: 'mad_astrologer',
    name: 'Astrologo Folle',
    tier: 3,
    level: 25,
    group: MuscleGroup.cardio,
    region: 'L\'Osservatorio Crollato',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
      Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'abyss_crystal': 2, 'abyss_ink': 1},
    rareDrop: 'star_core',
    rareDropChance: 0.01,
  ),
  'brass_automaton': EnemyDef(
    id: 'brass_automaton',
    name: 'Automa d\'Ottone',
    tier: 3,
    level: 29,
    group: MuscleGroup.cardio,
    region: 'L\'Osservatorio Crollato',
    moves: [
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
    ],
    loot: {'abyss_crystal': 1, 'bronze_ingot': 2, 'silver_ingot': 1},
    rareDrop: 'forge_stone_2',
    rareDropChance: 0.1,
  ),
  'star_eye': EnemyDef(
    id: 'star_eye',
    name: 'L\'Occhio delle Stelle',
    tier: 4,
    level: 41,
    group: MuscleGroup.cardio,
    region: 'L\'Osservatorio Crollato',
    isBoss: true,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
      Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25),
      Move('High knees', ExerciseId.highKnees, ratio: 0.6),
    ],
    loot: {'abyss_crystal': 4, 'forge_stone_2': 1},
    rareDrop: 'star_core',
    rareDropChance: 0.05,
  ),
  'star_shard': EnemyDef(
    id: 'star_shard',
    name: 'Frammento Stellare',
    tier: 4,
    level: 45,
    group: MuscleGroup.cardio,
    region: 'Il Pozzo delle Stelle',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
      Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'star_iron': 2, 'abyss_crystal': 1},
    rareDrop: 'forge_stone_3',
    rareDropChance: 0.06,
  ),
  'void_stalker': EnemyDef(
    id: 'void_stalker',
    name: 'Cacciatore del Vuoto',
    tier: 4,
    level: 50,
    group: MuscleGroup.cardio,
    region: 'Il Pozzo delle Stelle',
    moves: [
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'star_iron': 1, 'abyss_crystal': 1, 'star_ore': 5},
    rareDrop: 'star_core',
    rareDropChance: 0.03,
  ),
  'star_devourer': EnemyDef(
    id: 'star_devourer',
    name: 'Il Divoratore di Stelle',
    tier: 5,
    level: 65,
    group: MuscleGroup.cardio,
    region: 'Il Pozzo delle Stelle',
    isBoss: true,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.125),
      Move('Jump squat', ExerciseId.squat, ratio: 0.175),
      Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25),
      Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25),
    ],
    loot: {'star_iron': 4, 'forge_stone_3': 1, 'somber_stone': 1},
    rareDrop: 'star_core',
    rareDropChance: 0.1,
  ),
  'restless_spirit': EnemyDef(
    id: 'restless_spirit',
    name: 'Spirito Inquieto',
    tier: 1,
    level: 1,
    group: MuscleGroup.stretching,
    region: 'Il Giardino del Silenzio',
    moves: [
      Move('Piegamento in avanti', ExerciseId.stretch),
      Move('Farfalla', ExerciseId.stretch),
    ],
    loot: {'forge_stone_1': 1, 'gem_rough': 1},
    rareDrop: 'gem_cut',
    rareDropChance: 0.05,
  ),
  'wandering_lantern': EnemyDef(
    id: 'wandering_lantern',
    name: 'Lanterna Vagante',
    tier: 1,
    level: 3,
    group: MuscleGroup.stretching,
    region: 'Il Giardino del Silenzio',
    moves: [
      Move('Affondo statico', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
    ],
    loot: {'coal': 4, 'gem_rough': 1},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.15,
  ),
  'mute_gardener': EnemyDef(
    id: 'mute_gardener',
    name: 'Il Giardiniere Muto',
    tier: 2,
    level: 9,
    group: MuscleGroup.stretching,
    region: 'Il Giardino del Silenzio',
    isBoss: true,
    moves: [
      Move('Piegamento in avanti', ExerciseId.stretch),
      Move('Affondo statico', ExerciseId.stretch),
      Move('Farfalla', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
    ],
    loot: {'forge_stone_1': 2, 'gem_rough': 2},
    rareDrop: 'gem_cut',
    rareDropChance: 0.15,
  ),
  'broken_monk': EnemyDef(
    id: 'broken_monk',
    name: 'Monaco Spezzato',
    tier: 2,
    level: 10,
    group: MuscleGroup.stretching,
    region: 'Il Monastero Sospeso',
    moves: [
      Move('Farfalla', ExerciseId.stretch),
      Move('Gatto-mucca', ExerciseId.stretch),
    ],
    loot: {'forge_stone_2': 1, 'gem_cut': 1},
    rareDrop: 'holy_shard',
    rareDropChance: 0.1,
  ),
  'bell_wraith': EnemyDef(
    id: 'bell_wraith',
    name: 'Spettro della Campana',
    tier: 2,
    level: 13,
    group: MuscleGroup.stretching,
    region: 'Il Monastero Sospeso',
    moves: [
      Move('Cobra', ExerciseId.stretch),
      Move('Piegamento a gambe larghe', ExerciseId.stretch),
    ],
    loot: {'bronze_ingot': 2, 'gem_cut': 1},
    rareDrop: 'holy_shard',
    rareDropChance: 0.15,
  ),
  'twisted_abbot': EnemyDef(
    id: 'twisted_abbot',
    name: 'L\'Abate Contorto',
    tier: 3,
    level: 22,
    group: MuscleGroup.stretching,
    region: 'Il Monastero Sospeso',
    isBoss: true,
    moves: [
      Move('Farfalla', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
      Move('Gatto-mucca', ExerciseId.stretch),
      Move('Piegamento a gambe larghe', ExerciseId.stretch),
    ],
    loot: {'forge_stone_2': 1, 'gem_cut': 2},
    rareDrop: 'gem_pure',
    rareDropChance: 0.1,
  ),
  'steam_nymph': EnemyDef(
    id: 'steam_nymph',
    name: 'Ninfa di Vapore',
    tier: 3,
    level: 25,
    group: MuscleGroup.stretching,
    region: 'Le Terme degli Antichi',
    moves: [
      Move('Posizione del bambino', ExerciseId.stretch),
      Move('Torsione da seduto', ExerciseId.stretch),
    ],
    loot: {'gem_pure': 1, 'forge_stone_2': 1},
    rareDrop: 'ancient_stone',
    rareDropChance: 0.05,
  ),
  'bath_serpent': EnemyDef(
    id: 'bath_serpent',
    name: 'Serpe delle Terme',
    tier: 3,
    level: 29,
    group: MuscleGroup.stretching,
    region: 'Le Terme degli Antichi',
    moves: [
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
    ],
    loot: {'gem_cut': 2, 'forge_stone_2': 1},
    rareDrop: 'gem_pure',
    rareDropChance: 0.1,
  ),
  'baths_queen': EnemyDef(
    id: 'baths_queen',
    name: 'La Regina delle Terme',
    tier: 4,
    level: 41,
    group: MuscleGroup.stretching,
    region: 'Le Terme degli Antichi',
    isBoss: true,
    moves: [
      Move('Posizione del bambino', ExerciseId.stretch),
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Torsione da seduto', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
    ],
    loot: {'ancient_stone': 1, 'gem_pure': 2, 'forge_stone_3': 1},
    rareDrop: 'dream_pearl',
    rareDropChance: 0.05,
  ),
  'dreamer': EnemyDef(
    id: 'dreamer',
    name: 'Il Sognatore',
    tier: 4,
    level: 45,
    group: MuscleGroup.stretching,
    region: 'Il Chiostro del Sogno',
    moves: [
      Move('Torsione da seduto', ExerciseId.stretch),
      Move('Mezza spaccata', ExerciseId.stretch),
    ],
    loot: {'gem_perfect': 1, 'forge_stone_3': 1},
    rareDrop: 'somber_stone',
    rareDropChance: 0.04,
  ),
  'sleepwalker': EnemyDef(
    id: 'sleepwalker',
    name: 'Il Sonnambulo',
    tier: 4,
    level: 50,
    group: MuscleGroup.stretching,
    region: 'Il Chiostro del Sogno',
    moves: [
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Piegamento a gambe larghe', ExerciseId.stretch),
    ],
    loot: {'gem_pure': 1, 'forge_stone_3': 1},
    rareDrop: 'dream_pearl',
    rareDropChance: 0.03,
  ),
  'sleepless_one': EnemyDef(
    id: 'sleepless_one',
    name: 'Colui che Non Dorme',
    tier: 5,
    level: 65,
    group: MuscleGroup.stretching,
    region: 'Il Chiostro del Sogno',
    isBoss: true,
    moves: [
      Move('Torsione da seduto', ExerciseId.stretch),
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Mezza spaccata', ExerciseId.stretch),
      Move('Piegamento a gambe larghe', ExerciseId.stretch),
    ],
    loot: {'somber_stone': 1, 'gem_perfect': 2, 'forge_stone_3': 1},
    rareDrop: 'dream_pearl',
    rareDropChance: 0.1,
  ),
  'lord_of_the_keep': EnemyDef(
    id: 'lord_of_the_keep',
    name: 'Il Signore della Rocca',
    tier: 4,
    level: 30,
    group: MuscleGroup.push,
    region: 'La Rocca (Prova del Giuramento)',
    isBoss: true,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
      Move('Squat', ExerciseId.squat),
      Move('Crunch', ExerciseId.crunch),
      Move('Jumping jack', ExerciseId.jumpingJack),
    ],
    loot: {'steel_ingot': 4, 'forge_stone_3': 1, 'ancient_stone': 1},
    rareDrop: 'lord_of_the_keep_blade',
    rareDropChance: 0.08,
  ),
};

/// Una tappa della mappa: un mostro e l'esercizio con cui lo si batte. Dalla
/// terza tappa torna da Veterano: un gradino in più, bottino più ricco.
class ExpeditionStep {
  const ExpeditionStep(this.monsterId, this.move,
      {required this.level, required this.tier, this.veteran = false});
  final String monsterId;
  final Move move;
  final int level;
  final int tier;
  final bool veteran;

  EnemyDef get monster => enemyDefs[monsterId]!.atStep(this);
}

/// Il forziere in cima alla mappa: i garantiti escono sempre, i rari con la
/// loro probabilità. Zavorrato o con la chiave raddoppia entrambi.
class Chest {
  const Chest({
    required String name,
    required this.art,
    required this.runes,
    required this.guaranteed,
    required this.rares,
  }) : _name = name;
  final String _name;
  String get name => tr(_name);
  final String art;
  final int runes;
  final Map<String, int> guaranteed;
  final List<(String, double)> rares;
}

/// Una spedizione: una mappa con quattro tappe, il boss in cima e il forziere.
class Expedition {
  const Expedition({
    required this.id,
    required String name,
    required this.roman,
    required this.group,
    required this.level,
    required String blurb,
    required this.steps,
    required this.bossId,
    required this.chest,
  })  : _name = name,
        _blurb = blurb;

  final String id;
  final String _name;
  String get name => tr(_name);
  final String roman;
  final MuscleGroup group;

  /// Livello consigliato: sotto, senza l'equipaggiamento giusto, si muore.
  final int level;
  final String _blurb;
  String get blurb => tr(_blurb);
  final List<ExpeditionStep> steps;
  final String bossId;
  final Chest chest;

  EnemyDef get boss => enemyDefs[bossId]!;

  /// Il primo mostro della mappa.
  EnemyDef get monster => enemyDefs[steps.first.monsterId]!;

  /// I mostri diversi che si incontrano, nell'ordine della mappa.
  List<EnemyDef> get monsters => [
        for (final id in {for (final s in steps) s.monsterId}) enemyDefs[id]!,
      ];

  String get background => 'assets/art/maps/$id.png';

  /// Tutti i materiali che può lasciare, per mostrarli prima di partire.
  List<String> get drops =>
      {
        for (final e in [...monsters, boss]) ...[...e.commonLoot.keys, ...e.uncommonLoot, ...e.rareLoot],
        ...chest.guaranteed.keys,
      }.toList();
}

const List<Expedition> expeditions = [
  Expedition(
    id: 'buried_forges',
    name: 'Le Forge Sepolte',
    roman: 'I',
    group: MuscleGroup.push,
    level: 1,
    blurb: 'Fornaci spente sotto la città. Qui si comincia a battere il ferro.',
    steps: [
      ExpeditionStep('slag_goblin', Move('Push-up inclinati', ExerciseId.pushUp, ratio: 0.65), level: 1, tier: 1),
      ExpeditionStep('hollow_apprentice', Move('Push-up sulle ginocchia', ExerciseId.pushUp, ratio: 0.65), level: 3, tier: 1),
      ExpeditionStep('slag_goblin', Move('Push-up', ExerciseId.pushUp), level: 5, tier: 2, veteran: true),
      ExpeditionStep('hollow_apprentice', Move('Push-up larghi', ExerciseId.pushUp), level: 7, tier: 2, veteran: true),
    ],
    bossId: 'hollow_smith',
    chest: Chest(
      name: 'Forziere di legno marcito',
      art: 'chest_wood',
      runes: 300,
      guaranteed: {'iron_ingot': 4, 'bone': 4, 'forge_stone_1': 1, 'beast_essence': 2},
      rares: [('forge_stone_2', 0.15), ('gem_rough', 0.3), ('colossus_seal', 0.03)],
    ),
  ),
  Expedition(
    id: 'iron_bastion',
    name: 'Il Bastione di Ferro',
    roman: 'II',
    group: MuscleGroup.push,
    level: 10,
    blurb: 'Le mura che nessuno ha mai preso. Acciaio in ogni pietra.',
    steps: [
      ExpeditionStep('fallen_knight', Move('Push-up', ExerciseId.pushUp), level: 10, tier: 2),
      ExpeditionStep('keep_sentinel', Move('Push-up larghi', ExerciseId.pushUp), level: 13, tier: 2),
      ExpeditionStep('wall_archer', Move('Dip su sedia', ExerciseId.pushUp), level: 16, tier: 3),
      ExpeditionStep('keep_brute', Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2), level: 19, tier: 3),
    ],
    bossId: 'iron_castellan',
    chest: Chest(
      name: 'Forziere di ferro',
      art: 'chest_iron',
      runes: 900,
      guaranteed: {'steel_ingot': 6, 'forge_stone_2': 1, 'forge_stone_1': 2},
      rares: [('forge_stone_2', 0.25), ('gem_cut', 0.2), ('colossus_seal', 0.06), ('ancient_stone', 0.04)],
    ),
  ),
  Expedition(
    id: 'giants_furnace',
    name: 'La Fornace dei Giganti',
    roman: 'III',
    group: MuscleGroup.push,
    level: 25,
    blurb: 'La brace qui non si spegne mai. Il ferro diventa rosso e resta rosso.',
    steps: [
      ExpeditionStep('ember_giant', Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2), level: 25, tier: 3),
      ExpeditionStep('chained_stoker', Move('Pike push-up', ExerciseId.pushUp, ratio: 0.2), level: 29, tier: 3),
      ExpeditionStep('ember_giant', Move('Dip su sedia', ExerciseId.pushUp), level: 33, tier: 4, veteran: true),
      ExpeditionStep('chained_stoker', Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175), level: 37, tier: 4, veteran: true),
    ],
    bossId: 'living_bellows',
    chest: Chest(
      name: 'Forziere d\'argento',
      art: 'chest_silver',
      runes: 2000,
      guaranteed: {'ember_iron': 8, 'forge_stone_2': 1},
      rares: [('forge_stone_3', 0.2), ('ancient_stone', 0.1), ('ember_heart', 0.04), ('ember_amulet', 0.06)],
    ),
  ),
  Expedition(
    id: 'godforge',
    name: 'La Fucina degli Dei',
    roman: 'IV',
    group: MuscleGroup.push,
    level: 45,
    blurb: 'Dove un dio batteva le sue lame. Ne è rimasto il martello, e lui.',
    steps: [
      ExpeditionStep('forge_servant', Move('Pike push-up piedi sulla sedia', ExerciseId.pushUp, ratio: 0.175), level: 45, tier: 4),
      ExpeditionStep('anvil_golem', Move('Push-up arciere', ExerciseId.pushUp, ratio: 0.175), level: 50, tier: 4),
      ExpeditionStep('forge_servant', Move('Push-up esplosivi', ExerciseId.pushUp, ratio: 0.2), level: 55, tier: 5, veteran: true),
      ExpeditionStep('anvil_golem', Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.2), level: 60, tier: 5, veteran: true),
    ],
    bossId: 'fallen_smith_god',
    chest: Chest(
      name: 'Forziere d\'oro del Giuramento',
      art: 'chest_gold',
      runes: 4000,
      guaranteed: {'godforge_steel': 8, 'forge_stone_3': 1, 'gem_pure': 1},
      rares: [('smith_god_hammer', 0.05), ('ember_heart', 0.12), ('ancient_stone', 0.15), ('somber_stone', 0.1), ('gem_perfect', 0.1)],
    ),
  ),
  Expedition(
    id: 'ash_wood_forest',
    name: 'Il Bosco di Cenere',
    roman: 'I',
    group: MuscleGroup.legs,
    level: 1,
    blurb: 'Alberi bruciati che non cadono. Legna e pelli per chi le sa prendere.',
    steps: [
      ExpeditionStep('hollow_goblin', Move('Squat', ExerciseId.squat), level: 1, tier: 1),
      ExpeditionStep('ash_scarecrow', Move('Affondi', ExerciseId.lunge), level: 3, tier: 1),
      ExpeditionStep('hollow_goblin', Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3), level: 5, tier: 2, veteran: true),
      ExpeditionStep('ash_scarecrow', Move('Step-up sulla sedia', ExerciseId.lunge), level: 7, tier: 2, veteran: true),
    ],
    bossId: 'hollow_stag',
    chest: Chest(
      name: 'Forziere di legno marcito',
      art: 'chest_wood',
      runes: 300,
      guaranteed: {'raw_hide': 6, 'bone': 6, 'beast_essence': 6, 'forge_stone_1': 1},
      rares: [('forge_stone_2', 0.15), ('gem_rough', 0.3), ('hunter_heart', 0.03)],
    ),
  ),
  Expedition(
    id: 'hunters_marsh',
    name: 'La Palude dei Cacciatori',
    roman: 'II',
    group: MuscleGroup.legs,
    level: 10,
    blurb: 'Chi caccia qui finisce cacciato. Cuoio buono, quercia nera.',
    steps: [
      ExpeditionStep('carrion_hound', Move('Squat', ExerciseId.squat), level: 10, tier: 2),
      ExpeditionStep('bog_drowned', Move('Affondi', ExerciseId.lunge), level: 13, tier: 2),
      ExpeditionStep('carrion_hound', Move('Ponte per glutei', ExerciseId.squat, ratio: 0.3), level: 16, tier: 3, veteran: true),
      ExpeditionStep('bog_drowned', Move('Jump squat', ExerciseId.squat, ratio: 0.175), level: 19, tier: 3, veteran: true),
    ],
    bossId: 'marsh_matron',
    chest: Chest(
      name: 'Forziere di ferro',
      art: 'chest_iron',
      runes: 900,
      guaranteed: {'tanned_leather': 6, 'beast_essence': 6, 'forge_stone_2': 1, 'forge_stone_1': 2},
      rares: [('forge_stone_2', 0.25), ('gem_cut', 0.2), ('hunter_heart', 0.06), ('ancient_stone', 0.04)],
    ),
  ),
  Expedition(
    id: 'wind_gorge',
    name: 'Le Gole del Vento',
    roman: 'III',
    group: MuscleGroup.legs,
    level: 25,
    blurb: 'Un vento che taglia la pelle. Le arpie ci fanno il nido.',
    steps: [
      ExpeditionStep('gorge_harpy', Move('Jump squat', ExerciseId.squat, ratio: 0.175), level: 25, tier: 3),
      ExpeditionStep('cliff_raider', Move('Squat bulgaro sulla sedia', ExerciseId.lunge), level: 29, tier: 3),
      ExpeditionStep('gorge_harpy', Move('Step-up sulla sedia', ExerciseId.lunge), level: 33, tier: 4, veteran: true),
      ExpeditionStep('cliff_raider', Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2), level: 37, tier: 4, veteran: true),
    ],
    bossId: 'weightless_knight',
    chest: Chest(
      name: 'Forziere d\'argento',
      art: 'chest_silver',
      runes: 2000,
      guaranteed: {'gale_silver': 8, 'forge_stone_2': 1},
      rares: [('forge_stone_3', 0.2), ('ancient_stone', 0.1), ('storm_eye', 0.04), ('gale_amulet', 0.06)],
    ),
  ),
  Expedition(
    id: 'storm_peak',
    name: 'La Vetta della Bufera',
    roman: 'IV',
    group: MuscleGroup.legs,
    level: 45,
    blurb: 'In cima non si respira. Chi ci arriva vola.',
    steps: [
      ExpeditionStep('wind_sentinel', Move('Affondi saltati', ExerciseId.lunge, ratio: 0.2), level: 45, tier: 4),
      ExpeditionStep('thunder_ram', Move('Squat bulgaro sulla sedia', ExerciseId.lunge), level: 50, tier: 4),
      ExpeditionStep('wind_sentinel', Move('Jump squat', ExerciseId.squat, ratio: 0.175), level: 55, tier: 5, veteran: true),
      ExpeditionStep('thunder_ram', Move('Pistol squat assistito', ExerciseId.squat, ratio: 0.15), level: 60, tier: 5, veteran: true),
    ],
    bossId: 'storm_king',
    chest: Chest(
      name: 'Forziere d\'oro del Giuramento',
      art: 'chest_gold',
      runes: 4000,
      guaranteed: {'steel_feather': 8, 'forge_stone_3': 1, 'gem_pure': 1},
      rares: [('storm_king_spear', 0.05), ('storm_eye', 0.12), ('ancient_stone', 0.15), ('somber_stone', 0.1), ('gem_perfect', 0.1)],
    ),
  ),
  Expedition(
    id: 'bronze_crypt',
    name: 'La Cripta di Bronzo',
    roman: 'I',
    group: MuscleGroup.core,
    level: 1,
    blurb: 'Tombe chiuse da porte di bronzo. I morti non le hanno aperte, finora.',
    steps: [
      ExpeditionStep('bronze_skeleton', Move('Crunch', ExerciseId.crunch), level: 1, tier: 1),
      ExpeditionStep('tomb_crawler', Move('Leg raise', ExerciseId.legRaise), level: 3, tier: 1),
      ExpeditionStep('bronze_skeleton', Move('Plank', ExerciseId.plank), level: 5, tier: 2, veteran: true),
      ExpeditionStep('tomb_crawler', Move('Superman', ExerciseId.crunch), level: 7, tier: 2, veteran: true),
    ],
    bossId: 'crypt_keeper',
    chest: Chest(
      name: 'Forziere di legno marcito',
      art: 'chest_wood',
      runes: 300,
      guaranteed: {'bronze_ingot': 8, 'bone': 6, 'holy_shard': 2, 'forge_stone_1': 1, 'beast_essence': 2},
      rares: [('forge_stone_2', 0.15), ('gem_rough', 0.3), ('fervent', 0.03)],
    ),
  ),
  Expedition(
    id: 'golden_temple',
    name: 'Il Tempio Dorato',
    roman: 'II',
    group: MuscleGroup.core,
    level: 10,
    blurb: 'Oro sulle colonne, oro nelle ossa dei sacerdoti.',
    steps: [
      ExpeditionStep('ash_wyrm', Move('Crunch', ExerciseId.crunch), level: 10, tier: 2),
      ExpeditionStep('gilded_acolyte', Move('Leg raise', ExerciseId.legRaise), level: 13, tier: 2),
      ExpeditionStep('ash_wyrm', Move('Plank', ExerciseId.plank), level: 16, tier: 3, veteran: true),
      ExpeditionStep('gilded_acolyte', Move('Russian twist', ExerciseId.crunch), level: 19, tier: 3, veteran: true),
    ],
    bossId: 'golden_priest',
    chest: Chest(
      name: 'Forziere di ferro',
      art: 'chest_iron',
      runes: 900,
      guaranteed: {'gold_ingot': 6, 'holy_shard': 4, 'forge_stone_2': 1, 'forge_stone_1': 2},
      rares: [('forge_stone_2', 0.25), ('gem_cut', 0.2), ('fervent', 0.06), ('ancient_stone', 0.04)],
    ),
  ),
  Expedition(
    id: 'hallowed_sanctum',
    name: 'Il Santuario Consacrato',
    roman: 'III',
    group: MuscleGroup.core,
    level: 25,
    blurb: 'La luce qui brucia. L\'oro benedetto si raccoglie dalle lacrime delle statue.',
    steps: [
      ExpeditionStep('penitent', Move('V-up', ExerciseId.legRaise, ratio: 0.2), level: 25, tier: 3),
      ExpeditionStep('censer_bearer', Move('Russian twist', ExerciseId.crunch), level: 29, tier: 3),
      ExpeditionStep('penitent', Move('Plank', ExerciseId.plank), level: 33, tier: 4, veteran: true),
      ExpeditionStep('censer_bearer', Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225), level: 37, tier: 4, veteran: true),
    ],
    bossId: 'chained_maiden',
    chest: Chest(
      name: 'Forziere d\'argento',
      art: 'chest_silver',
      runes: 2000,
      guaranteed: {'hallowed_gold': 8, 'forge_stone_2': 1},
      rares: [('forge_stone_3', 0.2), ('ancient_stone', 0.1), ('martyr_tear', 0.04), ('holy_amulet', 0.06)],
    ),
  ),
  Expedition(
    id: 'martyr_cathedral',
    name: 'La Cattedrale del Martire',
    roman: 'IV',
    group: MuscleGroup.core,
    level: 45,
    blurb: 'Nera e oro. Il Martire prega ancora, e non per te.',
    steps: [
      ExpeditionStep('black_inquisitor', Move('V-up', ExerciseId.legRaise, ratio: 0.2), level: 45, tier: 4),
      ExpeditionStep('cathedral_gargoyle', Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.225), level: 50, tier: 4),
      ExpeditionStep('black_inquisitor', Move('Plank laterale', ExerciseId.plank), level: 55, tier: 5, veteran: true),
      ExpeditionStep('cathedral_gargoyle', Move('Leg raise', ExerciseId.legRaise), level: 60, tier: 5, veteran: true),
    ],
    bossId: 'eternal_martyr',
    chest: Chest(
      name: 'Forziere d\'oro del Giuramento',
      art: 'chest_gold',
      runes: 4000,
      guaranteed: {'martyr_obsidian': 8, 'forge_stone_3': 1, 'gem_pure': 1},
      rares: [('eternal_martyr_blade', 0.05), ('martyr_tear', 0.12), ('ancient_stone', 0.15), ('somber_stone', 0.1), ('gem_perfect', 0.1)],
    ),
  ),
  Expedition(
    id: 'lunar_ruins',
    name: 'Le Rovine Lunari',
    roman: 'I',
    group: MuscleGroup.cardio,
    level: 1,
    blurb: 'Di notte la luna si posa sulle pietre e le lascia d\'argento.',
    steps: [
      ExpeditionStep('spectral_archer', Move('Jumping jack', ExerciseId.jumpingJack), level: 1, tier: 1),
      ExpeditionStep('lunar_wisp', Move('High knees', ExerciseId.highKnees, ratio: 0.6), level: 3, tier: 1),
      ExpeditionStep('spectral_archer', Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25), level: 5, tier: 2, veteran: true),
      ExpeditionStep('lunar_wisp', Move('Squat veloci', ExerciseId.squat), level: 7, tier: 2, veteran: true),
    ],
    bossId: 'moon_moth',
    chest: Chest(
      name: 'Forziere di legno marcito',
      art: 'chest_wood',
      runes: 300,
      guaranteed: {'silver_ingot': 2, 'beast_essence': 6, 'bone': 4, 'forge_stone_1': 1},
      rares: [('forge_stone_2', 0.15), ('gem_rough', 0.3), ('martyr_relic', 0.03)],
    ),
  ),
  Expedition(
    id: 'flooded_library',
    name: 'La Biblioteca Allagata',
    roman: 'II',
    group: MuscleGroup.cardio,
    level: 10,
    blurb: 'I libri galleggiano. L\'inchiostro, nell\'acqua nera, è ancora vivo.',
    steps: [
      ExpeditionStep('drowned_scribe', Move('Jumping jack', ExerciseId.jumpingJack), level: 10, tier: 2),
      ExpeditionStep('living_tome', Move('High knees', ExerciseId.highKnees, ratio: 0.6), level: 13, tier: 2),
      ExpeditionStep('drowned_scribe', Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25), level: 16, tier: 3, veteran: true),
      ExpeditionStep('living_tome', Move('Burpee', ExerciseId.squat, ratio: 0.125), level: 19, tier: 3, veteran: true),
    ],
    bossId: 'eyeless_librarian',
    chest: Chest(
      name: 'Forziere di ferro',
      art: 'chest_iron',
      runes: 900,
      guaranteed: {'abyss_ink': 6, 'forge_stone_2': 1, 'forge_stone_1': 2},
      rares: [('forge_stone_2', 0.25), ('gem_cut', 0.2), ('martyr_relic', 0.06), ('ancient_stone', 0.04)],
    ),
  ),
  Expedition(
    id: 'fallen_observatory',
    name: 'L\'Osservatorio Crollato',
    roman: 'III',
    group: MuscleGroup.cardio,
    level: 25,
    blurb: 'Il telescopio è caduto, ma qualcuno guarda ancora le stelle.',
    steps: [
      ExpeditionStep('mad_astrologer', Move('Burpee', ExerciseId.squat, ratio: 0.125), level: 25, tier: 3),
      ExpeditionStep('brass_automaton', Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25), level: 29, tier: 3),
      ExpeditionStep('mad_astrologer', Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25), level: 33, tier: 4, veteran: true),
      ExpeditionStep('brass_automaton', Move('High knees', ExerciseId.highKnees, ratio: 0.6), level: 37, tier: 4, veteran: true),
    ],
    bossId: 'star_eye',
    chest: Chest(
      name: 'Forziere d\'argento',
      art: 'chest_silver',
      runes: 2000,
      guaranteed: {'abyss_crystal': 8, 'forge_stone_2': 1},
      rares: [('forge_stone_3', 0.2), ('ancient_stone', 0.1), ('star_core', 0.04), ('abyss_amulet', 0.06)],
    ),
  ),
  Expedition(
    id: 'star_well',
    name: 'Il Pozzo delle Stelle',
    roman: 'IV',
    group: MuscleGroup.cardio,
    level: 45,
    blurb: 'Un pozzo senza fondo. In fondo, cadono stelle.',
    steps: [
      ExpeditionStep('star_shard', Move('Burpee', ExerciseId.squat, ratio: 0.125), level: 45, tier: 4),
      ExpeditionStep('void_stalker', Move('Jump squat', ExerciseId.squat, ratio: 0.175), level: 50, tier: 4),
      ExpeditionStep('star_shard', Move('Skater jump', ExerciseId.jumpingJack, ratio: 0.25), level: 55, tier: 5, veteran: true),
      ExpeditionStep('void_stalker', Move('Mountain climber', ExerciseId.jumpingJack, ratio: 0.25), level: 60, tier: 5, veteran: true),
    ],
    bossId: 'star_devourer',
    chest: Chest(
      name: 'Forziere d\'oro del Giuramento',
      art: 'chest_gold',
      runes: 4000,
      guaranteed: {'star_iron': 8, 'forge_stone_3': 1, 'gem_pure': 1},
      rares: [('devourer_eye', 0.05), ('star_core', 0.12), ('ancient_stone', 0.15), ('somber_stone', 0.1), ('gem_perfect', 0.1)],
    ),
  ),
  Expedition(
    id: 'silent_garden',
    name: 'Il Giardino del Silenzio',
    roman: 'I',
    group: MuscleGroup.stretching,
    level: 1,
    blurb: 'Gli spiriti qui non si combattono: si calmano. Tieni la posa e svaniscono.',
    steps: [
      ExpeditionStep('restless_spirit', Move('Piegamento in avanti', ExerciseId.stretch), level: 1, tier: 1),
      ExpeditionStep('wandering_lantern', Move('Affondo statico', ExerciseId.stretch), level: 3, tier: 1),
      ExpeditionStep('restless_spirit', Move('Farfalla', ExerciseId.stretch), level: 5, tier: 2, veteran: true),
      ExpeditionStep('wandering_lantern', Move('Cobra', ExerciseId.stretch), level: 7, tier: 2, veteran: true),
    ],
    bossId: 'mute_gardener',
    chest: Chest(
      name: 'Forziere di legno marcito',
      art: 'chest_wood',
      runes: 300,
      guaranteed: {'gem_rough': 5, 'forge_stone_1': 1, 'beast_essence': 2},
      rares: [('forge_stone_2', 0.15), ('gem_rough', 0.3), ('martyr_relic', 0.03)],
    ),
  ),
  Expedition(
    id: 'hanging_monastery',
    name: 'Il Monastero Sospeso',
    roman: 'II',
    group: MuscleGroup.stretching,
    level: 10,
    blurb: 'Monaci piegati dal tempo. Chi resta immobile più di loro passa.',
    steps: [
      ExpeditionStep('broken_monk', Move('Farfalla', ExerciseId.stretch), level: 10, tier: 2),
      ExpeditionStep('bell_wraith', Move('Cobra', ExerciseId.stretch), level: 13, tier: 2),
      ExpeditionStep('broken_monk', Move('Gatto-mucca', ExerciseId.stretch), level: 16, tier: 3, veteran: true),
      ExpeditionStep('bell_wraith', Move('Piegamento a gambe larghe', ExerciseId.stretch), level: 19, tier: 3, veteran: true),
    ],
    bossId: 'twisted_abbot',
    chest: Chest(
      name: 'Forziere di ferro',
      art: 'chest_iron',
      runes: 900,
      guaranteed: {'gem_cut': 5, 'forge_stone_2': 1, 'forge_stone_1': 2},
      rares: [('forge_stone_2', 0.25), ('gem_cut', 0.2), ('martyr_relic', 0.06), ('ancient_stone', 0.04)],
    ),
  ),
  Expedition(
    id: 'ancient_baths',
    name: 'Le Terme degli Antichi',
    roman: 'III',
    group: MuscleGroup.stretching,
    level: 25,
    blurb: 'Vapore e pietra calda. Qui le gemme si puliscono da sole.',
    steps: [
      ExpeditionStep('steam_nymph', Move('Posizione del bambino', ExerciseId.stretch), level: 25, tier: 3),
      ExpeditionStep('bath_serpent', Move('Posizione del piccione', ExerciseId.stretch), level: 29, tier: 3),
      ExpeditionStep('steam_nymph', Move('Torsione da seduto', ExerciseId.stretch), level: 33, tier: 4, veteran: true),
      ExpeditionStep('bath_serpent', Move('Cobra', ExerciseId.stretch), level: 37, tier: 4, veteran: true),
    ],
    bossId: 'baths_queen',
    chest: Chest(
      name: 'Forziere d\'argento',
      art: 'chest_silver',
      runes: 2000,
      guaranteed: {'gem_pure': 4, 'forge_stone_2': 1, 'gem_cut': 1},
      rares: [('forge_stone_3', 0.2), ('ancient_stone', 0.1), ('dream_pearl', 0.04), ('gem_perfect', 0.06)],
    ),
  ),
  Expedition(
    id: 'dream_cloister',
    name: 'Il Chiostro del Sogno',
    roman: 'IV',
    group: MuscleGroup.stretching,
    level: 45,
    blurb: 'Chi dorme qui sogna per sempre. Tu resta sveglio e fermo.',
    steps: [
      ExpeditionStep('dreamer', Move('Torsione da seduto', ExerciseId.stretch), level: 45, tier: 4),
      ExpeditionStep('sleepwalker', Move('Posizione del piccione', ExerciseId.stretch), level: 50, tier: 4),
      ExpeditionStep('dreamer', Move('Mezza spaccata', ExerciseId.stretch), level: 55, tier: 5, veteran: true),
      ExpeditionStep('sleepwalker', Move('Piegamento a gambe larghe', ExerciseId.stretch), level: 60, tier: 5, veteran: true),
    ],
    bossId: 'sleepless_one',
    chest: Chest(
      name: 'Forziere d\'oro del Giuramento',
      art: 'chest_gold',
      runes: 4000,
      guaranteed: {'gem_perfect': 4, 'forge_stone_3': 1, 'gem_pure': 2},
      rares: [('sleepless_seal', 0.05), ('dream_pearl', 0.12), ('ancient_stone', 0.15), ('somber_stone', 0.1), ('gem_perfect', 0.1)],
    ),
  ),
];

List<Expedition> expeditionsOf(MuscleGroup g) =>
    expeditions.where((e) => e.group == g).toList();

Expedition expeditionById(String id) => expeditions.firstWhere((e) => e.id == id);

enum Rarity { common, uncommon, rare }

/// Rarità di un drop: le risorse di base sono comuni (anche i componenti
/// delle build), pietre, schegge e gemme grezze non comuni, pietre alte,
/// gemme pure, cuori, amuleti e armi rari.
Rarity dropRarity(String id) {
  if (weaponDefs.containsKey(id) || amuletDefs.containsKey(id) || id.startsWith('amulet_')) {
    return Rarity.rare;
  }
  const uncommon = {
    'forge_stone_1',
    'forge_stone_2',
    'holy_shard',
    'gem_rough',
    'gem_cut',
    'reinforced_grip',
    'somber_stone_2',
  };
  const rare = {
    'forge_stone_3',
    'ancient_stone',
    'somber_stone',
    'somber_stone_3',
    'somber_stone_4',
    'epic_stone',
    'gem_pure',
    'gem_perfect',
    'ember_heart',
    'storm_eye',
    'martyr_tear',
    'star_core',
    'dream_pearl',
    'hunter_heart',
  };
  if (rare.contains(id)) return Rarity.rare;
  if (uncommon.contains(id)) return Rarity.uncommon;
  return Rarity.common;
}
