import 'enemies.dart';
import 'exercise.dart';

/// Cinque animali di livello 1, uno per esercizio base: si cacciano sempre,
/// per fare volume quando si vuole.
const List<EnemyDef> baseAnimals = [
  EnemyDef(
    id: 'ash_hare',
    name: 'Lepre di cenere',
    tier: 1,
    level: 1,
    group: MuscleGroup.legs,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Squat', ExerciseId.squat)],
    loot: {'raw_hide': 1, 'bone': 1},
  ),
  EnemyDef(
    id: 'red_fox',
    name: 'Volpe rossa',
    tier: 1,
    level: 1,
    group: MuscleGroup.push,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [
      Move('Push-up', ExerciseId.pushUp),
      Move('Push-up sulle ginocchia', ExerciseId.pushUp, ratio: 0.65),
    ],
    loot: {'raw_hide': 1, 'bone': 1},
  ),
  EnemyDef(
    id: 'grey_badger',
    name: 'Tasso grigio',
    tier: 1,
    level: 1,
    group: MuscleGroup.core,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Crunch', ExerciseId.crunch), Move('Leg raise', ExerciseId.legRaise)],
    loot: {'raw_hide': 1, 'bone': 1},
  ),
  EnemyDef(
    id: 'carrion_crow',
    name: 'Corvo carogna',
    tier: 1,
    level: 1,
    group: MuscleGroup.cardio,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Jumping jack', ExerciseId.jumpingJack)],
    loot: {'raw_hide': 1, 'beast_essence': 1},
  ),
  EnemyDef(
    id: 'wild_goat',
    name: 'Capra selvatica',
    tier: 1,
    level: 1,
    group: MuscleGroup.cardio,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [Move('High knees', ExerciseId.jumpingJack, ratio: 0.3)],
    loot: {'raw_hide': 1, 'bone': 1},
  ),
];

/// La caccia: animali dei boschi, uno per esercizio base, che lasciano pelle,
/// ossa ed essenza. Si combattono in libero: rinascono finché non smetti.
const List<EnemyDef> huntAnimals = [
  EnemyDef(
    id: 'ash_deer',
    name: 'Cervo di Cenere',
    tier: 1,
    level: 1,
    group: MuscleGroup.legs,
    region: 'Bosco di frassino',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Squat', ExerciseId.squat)],
    loot: {'raw_hide': 2, 'bone': 1},
    rareDrop: 'beast_essence',
    rareDropChance: 0.1,
  ),
  EnemyDef(
    id: 'tusk_boar',
    name: 'Cinghiale Zannuto',
    tier: 2,
    level: 5,
    group: MuscleGroup.legs,
    region: 'Querceto nero',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Push-up', ExerciseId.pushUp)],
    loot: {'raw_hide': 3, 'bone': 1, 'beast_essence': 1},
    rareDrop: 'tanned_leather',
    rareDropChance: 0.1,
  ),
  EnemyDef(
    id: 'grave_wolf',
    name: 'Lupo delle Tombe',
    tier: 3,
    level: 10,
    group: MuscleGroup.legs,
    region: 'Cimitero dei tassi',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Jumping jack', ExerciseId.jumpingJack)],
    loot: {'raw_hide': 4, 'tanned_leather': 1, 'beast_essence': 2},
    rareDrop: 'forge_stone_1',
    rareDropChance: 0.1,
  ),
  EnemyDef(
    id: 'dusk_bear',
    name: 'Orso del Crepuscolo',
    tier: 4,
    level: 16,
    group: MuscleGroup.legs,
    region: 'Selva del crepuscolo',
    isBeast: true,
    isAnimal: true,
    moves: [Move('Crunch', ExerciseId.crunch)],
    loot: {'raw_hide': 5, 'tanned_leather': 2, 'beast_essence': 3},
    rareDrop: 'hunter_heart',
    rareDropChance: 0.02,
  ),
];

/// Tutto ciò che si può affrontare in allenamento libero, per livello: gli
/// animali, i mostri e i boss di ogni gruppo (tranne gli spiriti dello
/// Stretching, che si calmano tenendo le pose). Niente è bloccato: sopra il
/// tuo livello si muore, ma si può provare.
List<EnemyDef> get bestiary => [
      ...baseAnimals,
      ...huntAnimals,
      ...enemyDefs.values.where((e) => e.group != MuscleGroup.stretching),
    ]..sort(
        (a, b) => a.level != b.level
            ? a.level.compareTo(b.level)
            : (a.isBoss ? 1 : 0) - (b.isBoss ? 1 : 0),
      );

/// Il nemico della quest giornaliera per un esercizio: il più forte che il
/// giocatore può reggere al suo livello, fra quelli che si battono con quel
/// movimento (niente boss).
(EnemyDef, Move)? questFoe(ExerciseId id, int level) {
  (EnemyDef, Move)? best;
  for (final e in bestiary) {
    if (e.isBoss) continue;
    final m = e.moves.where((m) => m.trackAs == id).firstOrNull;
    if (m == null) continue;
    final b = best;
    final fits = e.level <= level;
    final bestFits = b != null && b.$1.level <= level;
    if (b == null ||
        (fits && (!bestFits || e.level > b.$1.level)) ||
        (!fits && !bestFits && e.level < b.$1.level)) {
      best = (e, m);
    }
  }
  return best;
}
