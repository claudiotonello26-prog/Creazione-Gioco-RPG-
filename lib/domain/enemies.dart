import 'exercise.dart';
import 'items.dart';

class EnemyDef {
  const EnemyDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.region,
    this.isBoss = false,
    this.isBeast = false,
    this.weakTo,
    this.strongAgainst,
    this.loot = const {},
    this.rareDrop,
    this.rareDropChance = 0,
    required this.moves,
    required this.level,
    required this.group,
  });

  /// Con cosa lo si batte: se sono più d'uno, sceglie il giocatore (il boss
  /// li alterna).
  final List<Move> moves;

  /// Modelli di movimento usati dal contatore.
  List<ExerciseId> get exercises => [for (final m in moves) m.trackAs];

  /// Livello consigliato della spedizione da cui viene.
  final int level;
  final MuscleGroup group;

  final String id;
  final String name;

  /// Gradino 1–5: decide rep richieste, difesa e forza dei colpi.
  final int tier;
  final String region;
  final bool isBoss;
  final bool isBeast;
  final WeaponStyle? weakTo;
  final WeaponStyle? strongAgainst;
  final Map<String, int> loot;
  final String? rareDrop;
  final double rareDropChance;

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

  /// Secondi tra un attacco e l'altro.
  double get attackInterval => isBoss ? 3.5 : 4.0;

  /// Rune per uccisione: crescono più delle rep richieste, così per ogni rep
  /// un nemico più duro paga di più.
  int get runeReward => const [20, 40, 65, 95, 130][tier - 1] * (isBoss ? 3 : 1);
}

/// I nemici del mondo: per ogni gruppo quattro spedizioni, ognuna con un
/// mostro e un boss. Il gradino sale con la spedizione: I 1/2, II 2/3,
/// III 4/4, IV 5/5 (mostro/boss).
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
      Move('Push-up sulle ginocchia', ExerciseId.pushUp, ratio: 0.8),
    ],
    loot: {'iron_ore': 3, 'coal': 2},
  ),
  'hollow_smith': EnemyDef(
    id: 'hollow_smith',
    name: 'Fabbro Svuotato',
    tier: 2,
    level: 1,
    group: MuscleGroup.push,
    region: 'Le Forge Sepolte',
    isBoss: true,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
    ],
    loot: {'iron_ingot': 2, 'coal': 2, 'forge_stone_1': 1},
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
  ),
  'iron_castellan': EnemyDef(
    id: 'iron_castellan',
    name: 'Castellano di Ferro',
    tier: 3,
    level: 10,
    group: MuscleGroup.push,
    region: 'Il Bastione di Ferro',
    isBoss: true,
    moves: [
      Move('Push-up larghi', ExerciseId.pushUp),
    ],
    loot: {'steel_ingot': 3, 'forge_stone_2': 1},
  ),
  'ember_giant': EnemyDef(
    id: 'ember_giant',
    name: 'Gigante di Brace',
    tier: 4,
    level: 25,
    group: MuscleGroup.push,
    region: 'La Fornace dei Giganti',
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.4),
    ],
    loot: {'ember_iron': 2, 'coal': 3},
  ),
  'living_bellows': EnemyDef(
    id: 'living_bellows',
    name: 'Il Mantice Vivente',
    tier: 4,
    level: 25,
    group: MuscleGroup.push,
    region: 'La Fornace dei Giganti',
    isBoss: true,
    moves: [
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.4),
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.4),
    ],
    loot: {'ember_iron': 4, 'forge_stone_2': 1},
  ),
  'forge_servant': EnemyDef(
    id: 'forge_servant',
    name: 'Servo della Fucina',
    tier: 5,
    level: 45,
    group: MuscleGroup.push,
    region: 'La Fucina degli Dei',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.4),
    ],
    loot: {'godforge_steel': 2, 'ember_iron': 1},
  ),
  'fallen_smith_god': EnemyDef(
    id: 'fallen_smith_god',
    name: 'Il Dio Fabbro Decaduto',
    tier: 5,
    level: 45,
    group: MuscleGroup.push,
    region: 'La Fucina degli Dei',
    isBoss: true,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
      Move('Push-up diamante', ExerciseId.pushUp, ratio: 0.4),
      Move('Pike push-up', ExerciseId.pushUp, ratio: 0.4),
    ],
    loot: {'godforge_steel': 4, 'forge_stone_3': 1, 'ancient_stone': 1},
    rareDrop: 'lord_of_the_keep_blade',
    rareDropChance: 0.08,
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
    ],
    loot: {'ash_wood': 3, 'raw_hide': 1},
  ),
  'hollow_stag': EnemyDef(
    id: 'hollow_stag',
    name: 'Il Cervo Cavo',
    tier: 2,
    level: 1,
    group: MuscleGroup.legs,
    region: 'Il Bosco di Cenere',
    isBoss: true,
    isBeast: true,
    moves: [
      Move('Affondi', ExerciseId.lunge),
    ],
    loot: {'raw_hide': 3, 'ash_wood': 3, 'beast_essence': 2},
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
      Move('Affondi', ExerciseId.lunge),
    ],
    loot: {'tanned_leather': 1, 'oak_wood': 2},
  ),
  'marsh_matron': EnemyDef(
    id: 'marsh_matron',
    name: 'La Matrona della Palude',
    tier: 3,
    level: 10,
    group: MuscleGroup.legs,
    region: 'La Palude dei Cacciatori',
    isBoss: true,
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Affondi', ExerciseId.lunge),
    ],
    loot: {'tanned_leather': 3, 'oak_wood': 3, 'forge_stone_2': 1},
  ),
  'gorge_harpy': EnemyDef(
    id: 'gorge_harpy',
    name: 'Arpia delle Gole',
    tier: 4,
    level: 25,
    group: MuscleGroup.legs,
    region: 'Le Gole del Vento',
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    moves: [
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.6),
    ],
    loot: {'gale_silver': 2, 'raw_hide': 2},
  ),
  'weightless_knight': EnemyDef(
    id: 'weightless_knight',
    name: 'Il Cavaliere Senza Peso',
    tier: 4,
    level: 25,
    group: MuscleGroup.legs,
    region: 'Le Gole del Vento',
    isBoss: true,
    moves: [
      Move('Affondi', ExerciseId.lunge),
      Move('Ponte per glutei', ExerciseId.squat, ratio: 0.6),
    ],
    loot: {'gale_silver': 4, 'forge_stone_2': 1},
  ),
  'wind_sentinel': EnemyDef(
    id: 'wind_sentinel',
    name: 'Sentinella del Vento',
    tier: 5,
    level: 45,
    group: MuscleGroup.legs,
    region: 'La Vetta della Bufera',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Jump squat', ExerciseId.squat, ratio: 0.35),
    ],
    loot: {'steel_feather': 2, 'gale_silver': 1},
  ),
  'storm_king': EnemyDef(
    id: 'storm_king',
    name: 'Il Re della Tempesta',
    tier: 5,
    level: 45,
    group: MuscleGroup.legs,
    region: 'La Vetta della Bufera',
    isBoss: true,
    moves: [
      Move('Squat', ExerciseId.squat),
      Move('Affondi', ExerciseId.lunge),
      Move('Jump squat', ExerciseId.squat, ratio: 0.35),
    ],
    loot: {'steel_feather': 4, 'forge_stone_3': 1, 'somber_stone': 1},
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
    ],
    loot: {'bronze_ingot': 2, 'bone': 2},
  ),
  'crypt_keeper': EnemyDef(
    id: 'crypt_keeper',
    name: 'Il Custode della Cripta',
    tier: 2,
    level: 1,
    group: MuscleGroup.core,
    region: 'La Cripta di Bronzo',
    isBoss: true,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Leg raise', ExerciseId.legRaise),
    ],
    loot: {'bronze_ingot': 4, 'bone': 3, 'holy_shard': 1},
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
      Move('Leg raise', ExerciseId.legRaise),
    ],
    loot: {'gold_ingot': 1, 'holy_shard': 1},
  ),
  'golden_priest': EnemyDef(
    id: 'golden_priest',
    name: 'Il Sacerdote d\'Oro',
    tier: 3,
    level: 10,
    group: MuscleGroup.core,
    region: 'Il Tempio Dorato',
    isBoss: true,
    moves: [
      Move('Leg raise', ExerciseId.legRaise),
    ],
    loot: {'gold_ingot': 3, 'holy_shard': 2},
  ),
  'penitent': EnemyDef(
    id: 'penitent',
    name: 'Il Penitente',
    tier: 4,
    level: 25,
    group: MuscleGroup.core,
    region: 'Il Santuario Consacrato',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Crunch a bicicletta', ExerciseId.crunch, ratio: 0.45),
    ],
    loot: {'hallowed_gold': 2, 'holy_shard': 1},
  ),
  'chained_maiden': EnemyDef(
    id: 'chained_maiden',
    name: 'La Vergine Incatenata',
    tier: 4,
    level: 25,
    group: MuscleGroup.core,
    region: 'Il Santuario Consacrato',
    isBoss: true,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.4),
      Move('Crunch', ExerciseId.crunch),
    ],
    loot: {'hallowed_gold': 4, 'forge_stone_2': 1},
  ),
  'black_inquisitor': EnemyDef(
    id: 'black_inquisitor',
    name: 'Inquisitore Nero',
    tier: 5,
    level: 45,
    group: MuscleGroup.core,
    region: 'La Cattedrale del Martire',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('V-up', ExerciseId.legRaise, ratio: 0.4),
    ],
    loot: {'martyr_obsidian': 2, 'hallowed_gold': 1},
  ),
  'eternal_martyr': EnemyDef(
    id: 'eternal_martyr',
    name: 'Il Martire Eterno',
    tier: 5,
    level: 45,
    group: MuscleGroup.core,
    region: 'La Cattedrale del Martire',
    isBoss: true,
    moves: [
      Move('Crunch', ExerciseId.crunch),
      Move('Leg raise', ExerciseId.legRaise),
      Move('V-up', ExerciseId.legRaise, ratio: 0.4),
    ],
    loot: {'martyr_obsidian': 4, 'forge_stone_3': 1, 'ancient_stone': 1},
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
    ],
    loot: {'moon_silver': 2, 'beast_essence': 1},
  ),
  'moon_moth': EnemyDef(
    id: 'moon_moth',
    name: 'La Falena di Luna',
    tier: 2,
    level: 1,
    group: MuscleGroup.cardio,
    region: 'Le Rovine Lunari',
    isBoss: true,
    isBeast: true,
    moves: [
      Move('High knees', ExerciseId.jumpingJack, ratio: 0.6),
    ],
    loot: {'moon_silver': 3, 'beast_essence': 2, 'coal': 2},
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
      Move('High knees', ExerciseId.jumpingJack, ratio: 0.6),
    ],
    loot: {'abyss_ink': 2, 'moon_silver': 1},
  ),
  'eyeless_librarian': EnemyDef(
    id: 'eyeless_librarian',
    name: 'Il Bibliotecario Senz\'Occhi',
    tier: 3,
    level: 10,
    group: MuscleGroup.cardio,
    region: 'La Biblioteca Allagata',
    isBoss: true,
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
      Move('High knees', ExerciseId.jumpingJack, ratio: 0.6),
    ],
    loot: {'abyss_ink': 3, 'forge_stone_2': 1},
  ),
  'mad_astrologer': EnemyDef(
    id: 'mad_astrologer',
    name: 'Astrologo Folle',
    tier: 4,
    level: 25,
    group: MuscleGroup.cardio,
    region: 'L\'Osservatorio Crollato',
    weakTo: WeaponStyle.melee,
    moves: [
      Move('Mountain climber', ExerciseId.jumpingJack),
    ],
    loot: {'abyss_crystal': 2, 'abyss_ink': 1},
  ),
  'star_eye': EnemyDef(
    id: 'star_eye',
    name: 'L\'Occhio delle Stelle',
    tier: 4,
    level: 25,
    group: MuscleGroup.cardio,
    region: 'L\'Osservatorio Crollato',
    isBoss: true,
    moves: [
      Move('High knees', ExerciseId.jumpingJack, ratio: 0.6),
      Move('Mountain climber', ExerciseId.jumpingJack),
    ],
    loot: {'abyss_crystal': 4, 'forge_stone_2': 1},
  ),
  'star_shard': EnemyDef(
    id: 'star_shard',
    name: 'Frammento Stellare',
    tier: 5,
    level: 45,
    group: MuscleGroup.cardio,
    region: 'Il Pozzo delle Stelle',
    weakTo: WeaponStyle.magic,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.25),
    ],
    loot: {'star_iron': 2, 'abyss_crystal': 1},
  ),
  'star_devourer': EnemyDef(
    id: 'star_devourer',
    name: 'Il Divoratore di Stelle',
    tier: 5,
    level: 45,
    group: MuscleGroup.cardio,
    region: 'Il Pozzo delle Stelle',
    isBoss: true,
    moves: [
      Move('Burpee', ExerciseId.squat, ratio: 0.25),
      Move('Jumping jack', ExerciseId.jumpingJack),
    ],
    loot: {'star_iron': 4, 'forge_stone_3': 1, 'somber_stone': 1},
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
    ],
    loot: {'forge_stone_1': 1, 'gem_rough': 1},
  ),
  'mute_gardener': EnemyDef(
    id: 'mute_gardener',
    name: 'Il Giardiniere Muto',
    tier: 2,
    level: 1,
    group: MuscleGroup.stretching,
    region: 'Il Giardino del Silenzio',
    isBoss: true,
    moves: [
      Move('Affondo statico', ExerciseId.stretch),
      Move('Piegamento in avanti', ExerciseId.stretch),
    ],
    loot: {'forge_stone_1': 2, 'gem_rough': 2},
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
    ],
    loot: {'forge_stone_2': 1, 'gem_cut': 1},
  ),
  'twisted_abbot': EnemyDef(
    id: 'twisted_abbot',
    name: 'L\'Abate Contorto',
    tier: 3,
    level: 10,
    group: MuscleGroup.stretching,
    region: 'Il Monastero Sospeso',
    isBoss: true,
    moves: [
      Move('Cobra', ExerciseId.stretch),
      Move('Farfalla', ExerciseId.stretch),
    ],
    loot: {'forge_stone_2': 1, 'gem_cut': 2},
  ),
  'steam_nymph': EnemyDef(
    id: 'steam_nymph',
    name: 'Ninfa di Vapore',
    tier: 4,
    level: 25,
    group: MuscleGroup.stretching,
    region: 'Le Terme degli Antichi',
    moves: [
      Move('Posizione del bambino', ExerciseId.stretch),
    ],
    loot: {'ancient_stone': 1, 'gem_pure': 1},
  ),
  'baths_queen': EnemyDef(
    id: 'baths_queen',
    name: 'La Regina delle Terme',
    tier: 4,
    level: 25,
    group: MuscleGroup.stretching,
    region: 'Le Terme degli Antichi',
    isBoss: true,
    moves: [
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Posizione del bambino', ExerciseId.stretch),
    ],
    loot: {'ancient_stone': 1, 'gem_pure': 2, 'forge_stone_3': 1},
  ),
  'dreamer': EnemyDef(
    id: 'dreamer',
    name: 'Il Sognatore',
    tier: 5,
    level: 45,
    group: MuscleGroup.stretching,
    region: 'Il Chiostro del Sogno',
    moves: [
      Move('Torsione da seduto', ExerciseId.stretch),
    ],
    loot: {'somber_stone': 1, 'gem_perfect': 1},
  ),
  'sleepless_one': EnemyDef(
    id: 'sleepless_one',
    name: 'Colui che Non Dorme',
    tier: 5,
    level: 45,
    group: MuscleGroup.stretching,
    region: 'Il Chiostro del Sogno',
    isBoss: true,
    moves: [
      Move('Torsione da seduto', ExerciseId.stretch),
      Move('Posizione del piccione', ExerciseId.stretch),
      Move('Cobra', ExerciseId.stretch),
    ],
    loot: {'somber_stone': 1, 'gem_perfect': 2, 'forge_stone_3': 1},
  ),
};

/// Una spedizione: un mostro e un boss dello stesso gruppo, con i materiali
/// che si trovano solo lì.
class Expedition {
  const Expedition({
    required this.id,
    required this.name,
    required this.group,
    required this.level,
    required this.blurb,
    required this.monsterId,
    required this.bossId,
  });

  final String id;
  final String name;
  final MuscleGroup group;

  /// Livello consigliato: sotto, senza l'equipaggiamento giusto, si muore.
  final int level;
  final String blurb;
  final String monsterId;
  final String bossId;

  EnemyDef get monster => enemyDefs[monsterId]!;
  EnemyDef get boss => enemyDefs[bossId]!;

  /// Tutti i materiali che può lasciare, per mostrarli prima di partire.
  List<String> get drops => {...monster.loot.keys, ...boss.loot.keys}.toList();
}

const List<Expedition> expeditions = [
  Expedition(
    id: 'buried_forges',
    name: 'Le Forge Sepolte',
    group: MuscleGroup.push,
    level: 1,
    blurb: 'Fornaci spente sotto la città. Qui si comincia a battere il ferro.',
    monsterId: 'slag_goblin',
    bossId: 'hollow_smith',
  ),
  Expedition(
    id: 'iron_bastion',
    name: 'Il Bastione di Ferro',
    group: MuscleGroup.push,
    level: 10,
    blurb: 'Le mura che nessuno ha mai preso. Acciaio in ogni pietra.',
    monsterId: 'fallen_knight',
    bossId: 'iron_castellan',
  ),
  Expedition(
    id: 'giants_furnace',
    name: 'La Fornace dei Giganti',
    group: MuscleGroup.push,
    level: 25,
    blurb: 'La brace qui non si spegne mai. Il ferro diventa rosso e resta rosso.',
    monsterId: 'ember_giant',
    bossId: 'living_bellows',
  ),
  Expedition(
    id: 'godforge',
    name: 'La Fucina degli Dei',
    group: MuscleGroup.push,
    level: 45,
    blurb: 'Dove un dio batteva le sue lame. Ne è rimasto il martello, e lui.',
    monsterId: 'forge_servant',
    bossId: 'fallen_smith_god',
  ),
  Expedition(
    id: 'ash_wood_forest',
    name: 'Il Bosco di Cenere',
    group: MuscleGroup.legs,
    level: 1,
    blurb: 'Alberi bruciati che non cadono. Legna e pelli per chi le sa prendere.',
    monsterId: 'hollow_goblin',
    bossId: 'hollow_stag',
  ),
  Expedition(
    id: 'hunters_marsh',
    name: 'La Palude dei Cacciatori',
    group: MuscleGroup.legs,
    level: 10,
    blurb: 'Chi caccia qui finisce cacciato. Cuoio buono, quercia nera.',
    monsterId: 'carrion_hound',
    bossId: 'marsh_matron',
  ),
  Expedition(
    id: 'wind_gorge',
    name: 'Le Gole del Vento',
    group: MuscleGroup.legs,
    level: 25,
    blurb: 'Un vento che taglia la pelle. Le arpie ci fanno il nido.',
    monsterId: 'gorge_harpy',
    bossId: 'weightless_knight',
  ),
  Expedition(
    id: 'storm_peak',
    name: 'La Vetta della Bufera',
    group: MuscleGroup.legs,
    level: 45,
    blurb: 'In cima non si respira. Chi ci arriva vola.',
    monsterId: 'wind_sentinel',
    bossId: 'storm_king',
  ),
  Expedition(
    id: 'bronze_crypt',
    name: 'La Cripta di Bronzo',
    group: MuscleGroup.core,
    level: 1,
    blurb: 'Tombe chiuse da porte di bronzo. I morti non le hanno aperte, finora.',
    monsterId: 'bronze_skeleton',
    bossId: 'crypt_keeper',
  ),
  Expedition(
    id: 'golden_temple',
    name: 'Il Tempio Dorato',
    group: MuscleGroup.core,
    level: 10,
    blurb: 'Oro sulle colonne, oro nelle ossa dei sacerdoti.',
    monsterId: 'ash_wyrm',
    bossId: 'golden_priest',
  ),
  Expedition(
    id: 'hallowed_sanctum',
    name: 'Il Santuario Consacrato',
    group: MuscleGroup.core,
    level: 25,
    blurb: 'La luce qui brucia. L\'oro benedetto si raccoglie dalle lacrime delle statue.',
    monsterId: 'penitent',
    bossId: 'chained_maiden',
  ),
  Expedition(
    id: 'martyr_cathedral',
    name: 'La Cattedrale del Martire',
    group: MuscleGroup.core,
    level: 45,
    blurb: 'Nera e oro. Il Martire prega ancora, e non per te.',
    monsterId: 'black_inquisitor',
    bossId: 'eternal_martyr',
  ),
  Expedition(
    id: 'lunar_ruins',
    name: 'Le Rovine Lunari',
    group: MuscleGroup.cardio,
    level: 1,
    blurb: 'Di notte la luna si posa sulle pietre e le lascia d\'argento.',
    monsterId: 'spectral_archer',
    bossId: 'moon_moth',
  ),
  Expedition(
    id: 'flooded_library',
    name: 'La Biblioteca Allagata',
    group: MuscleGroup.cardio,
    level: 10,
    blurb: 'I libri galleggiano. L\'inchiostro, nell\'acqua nera, è ancora vivo.',
    monsterId: 'drowned_scribe',
    bossId: 'eyeless_librarian',
  ),
  Expedition(
    id: 'fallen_observatory',
    name: 'L\'Osservatorio Crollato',
    group: MuscleGroup.cardio,
    level: 25,
    blurb: 'Il telescopio è caduto, ma qualcuno guarda ancora le stelle.',
    monsterId: 'mad_astrologer',
    bossId: 'star_eye',
  ),
  Expedition(
    id: 'star_well',
    name: 'Il Pozzo delle Stelle',
    group: MuscleGroup.cardio,
    level: 45,
    blurb: 'Un pozzo senza fondo. In fondo, cadono stelle.',
    monsterId: 'star_shard',
    bossId: 'star_devourer',
  ),
  Expedition(
    id: 'silent_garden',
    name: 'Il Giardino del Silenzio',
    group: MuscleGroup.stretching,
    level: 1,
    blurb: 'Gli spiriti qui non si combattono: si calmano. Tieni la posa e svaniscono.',
    monsterId: 'restless_spirit',
    bossId: 'mute_gardener',
  ),
  Expedition(
    id: 'hanging_monastery',
    name: 'Il Monastero Sospeso',
    group: MuscleGroup.stretching,
    level: 10,
    blurb: 'Monaci piegati dal tempo. Chi resta immobile più di loro passa.',
    monsterId: 'broken_monk',
    bossId: 'twisted_abbot',
  ),
  Expedition(
    id: 'ancient_baths',
    name: 'Le Terme degli Antichi',
    group: MuscleGroup.stretching,
    level: 25,
    blurb: 'Vapore e pietra calda. Qui le gemme si puliscono da sole.',
    monsterId: 'steam_nymph',
    bossId: 'baths_queen',
  ),
  Expedition(
    id: 'dream_cloister',
    name: 'Il Chiostro del Sogno',
    group: MuscleGroup.stretching,
    level: 45,
    blurb: 'Chi dorme qui sogna per sempre. Tu resta sveglio e fermo.',
    monsterId: 'dreamer',
    bossId: 'sleepless_one',
  ),
];

List<Expedition> expeditionsOf(MuscleGroup g) =>
    expeditions.where((e) => e.group == g).toList();

Expedition expeditionById(String id) => expeditions.firstWhere((e) => e.id == id);
