import 'enemies.dart';
import 'exercise.dart';

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
    moves: [
      Move('Squat', ExerciseId.squat),
    ],
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
    moves: [
      Move('Push-up', ExerciseId.pushUp),
    ],
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
    moves: [
      Move('Jumping jack', ExerciseId.jumpingJack),
    ],
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
    moves: [
      Move('Crunch', ExerciseId.crunch),
    ],
    loot: {'raw_hide': 5, 'tanned_leather': 2, 'beast_essence': 3},
    rareDrop: 'hunter_heart',
    rareDropChance: 0.02,
  ),
];
