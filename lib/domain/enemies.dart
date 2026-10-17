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
    this.exercises = const [ExerciseId.pushUp],
  });

  /// Con cosa lo si batte: se sono due, sceglie il giocatore.
  final List<ExerciseId> exercises;

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

const String regionCathedral = 'Cattedrali in Rovina';

const Map<String, EnemyDef> enemyDefs = {
  'hollow_goblin': EnemyDef(
    id: 'hollow_goblin',
    exercises: [ExerciseId.squat],
    name: 'Goblin Svuotato',
    tier: 1,
    region: regionCathedral,
    isBeast: true,
    weakTo: WeaponStyle.melee,
    loot: {'beast_essence': 1},
  ),
  'carrion_hound': EnemyDef(
    id: 'carrion_hound',
    exercises: [ExerciseId.lunge],
    name: 'Segugio della Carogna',
    tier: 2,
    region: regionCathedral,
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    loot: {'beast_essence': 2},
  ),
  'fallen_knight': EnemyDef(
    id: 'fallen_knight',
    exercises: [ExerciseId.pushUp],
    name: 'Cavaliere Caduto',
    tier: 3,
    region: regionCathedral,
    strongAgainst: WeaponStyle.ranged,
    weakTo: WeaponStyle.magic,
    loot: {'iron_ore': 2, 'forge_stone_2': 1},
  ),
  'ash_wyrm': EnemyDef(
    id: 'ash_wyrm',
    exercises: [ExerciseId.crunch, ExerciseId.legRaise],
    name: 'Viverna di Cenere',
    tier: 5,
    region: regionCathedral,
    isBeast: true,
    weakTo: WeaponStyle.ranged,
    loot: {'forge_stone_3': 1, 'holy_shard': 2},
  ),
  // Spedizione Spinta "La Rocca del Penitente".
  'keep_sentinel': EnemyDef(
    id: 'keep_sentinel',
    exercises: [ExerciseId.legRaise],
    name: 'Sentinella',
    tier: 2,
    region: 'La Rocca del Penitente',
    loot: {'iron_ore': 2},
  ),
  'wall_archer': EnemyDef(
    id: 'wall_archer',
    exercises: [ExerciseId.jumpingJack],
    name: 'Arciere delle Mura',
    tier: 2,
    region: 'La Rocca del Penitente',
    loot: {'ash_wood': 2},
  ),
  'keep_brute': EnemyDef(
    id: 'keep_brute',
    exercises: [ExerciseId.squat],
    name: 'Bruto',
    tier: 3,
    region: 'La Rocca del Penitente',
    loot: {'beast_essence': 2},
  ),
  'keep_fallen_knight': EnemyDef(
    id: 'keep_fallen_knight',
    exercises: [ExerciseId.pushUp],
    name: 'Cavaliere Caduto',
    tier: 3,
    region: 'La Rocca del Penitente',
    loot: {'forge_stone_2': 1},
  ),
  'lord_of_the_keep': EnemyDef(
    id: 'lord_of_the_keep',
    exercises: [ExerciseId.pushUp, ExerciseId.squat],
    name: 'Signore della Rocca',
    tier: 3,
    isBoss: true,
    region: 'La Rocca del Penitente',
    loot: {'forge_stone_3': 1, 'ancient_stone': 1, 'holy_shard': 2},
    rareDrop: 'lord_of_the_keep_blade',
    rareDropChance: 0.08,
  ),
  'marsh_matron': EnemyDef(
    id: 'marsh_matron',
    exercises: [ExerciseId.lunge, ExerciseId.crunch],
    name: 'Matrona della Palude',
    tier: 3,
    isBoss: true,
    region: 'La Palude degli Annegati',
    weakTo: WeaponStyle.melee,
    loot: {'forge_stone_3': 1, 'ancient_stone': 1, 'ash_wood': 4},
  ),
};

class ExpeditionStage {
  const ExpeditionStage(this.enemyId, this.exercises);
  final String enemyId;

  /// Esercizi fissi della tappa; il boss li ruota tutti.
  final List<ExerciseId> exercises;
}

class Expedition {
  const Expedition({
    required this.id,
    required this.name,
    required this.group,
    required this.stages,
  });

  final String id;
  final String name;
  final MuscleGroup group;
  final List<ExpeditionStage> stages;
}

/// Gli esercizi specifici della spinta vengono rilevati con lo stesso modello
/// del push-up (angolo del gomito), con varianti diverse mostrate a schermo.
const Map<String, Expedition> expeditions = {
  'penitent_keep': Expedition(
    id: 'penitent_keep',
    name: 'La Rocca del Penitente',
    group: MuscleGroup.push,
    stages: [
      ExpeditionStage('keep_sentinel', [ExerciseId.pushUp]),
      ExpeditionStage('wall_archer', [ExerciseId.pushUp]),
      ExpeditionStage('keep_brute', [ExerciseId.pushUp]),
      ExpeditionStage('keep_fallen_knight', [ExerciseId.pushUp]),
      ExpeditionStage('lord_of_the_keep', [ExerciseId.pushUp]),
    ],
  ),
  'drowned_marsh': Expedition(
    id: 'drowned_marsh',
    name: 'La Palude degli Annegati',
    group: MuscleGroup.legs,
    stages: [
      ExpeditionStage('hollow_goblin', [ExerciseId.squat]),
      ExpeditionStage('carrion_hound', [ExerciseId.lunge]),
      ExpeditionStage('keep_brute', [ExerciseId.squat]),
      ExpeditionStage('fallen_knight', [ExerciseId.lunge]),
      ExpeditionStage('marsh_matron', [ExerciseId.squat, ExerciseId.lunge]),
    ],
  ),
};

/// Nomi visualizzati delle tappe della spedizione Spinta (esercizi diversi
/// della stessa famiglia).
const Map<String, String> pushStageExerciseLabel = {
  'keep_sentinel': 'Push-up',
  'wall_archer': 'Pike push-up (spalle)',
  'keep_brute': 'Dip su sedia (tricipiti)',
  'keep_fallen_knight': 'Push-up larghi (petto)',
  'lord_of_the_keep': 'I quattro esercizi a rotazione',
};
