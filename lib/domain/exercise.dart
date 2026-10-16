/// Esercizi, gruppi muscolari e versioni facilitate.
///
/// Fonte: documento di progetto, sezioni "Onboarding e test iniziali" e
/// "Sfide per gruppo muscolare".
library;

enum MuscleGroup {
  push('Spinta'),
  back('Dorso e postura'),
  core('Core e addome'),
  legs('Gambe'),
  cardio('Cardio'),
  mobility('Mobilità');

  const MuscleGroup(this.label);
  final String label;
}

/// Come si misura un esercizio nel test.
enum TestMode {
  /// Massimo di rep corrette.
  maxReps,

  /// Rep corrette in 60 secondi.
  repsIn60s,

  /// Durata tenuta (plank).
  hold,
}

/// I sei esercizi della base total body, più il plank usato in Arena.
enum ExerciseId {
  pushUp,
  crunch,
  legRaise,
  squat,
  lunge,
  jumpingJack,
  plank,
}

class ExerciseVariant {
  const ExerciseVariant(this.name, {this.level = 0});

  final String name;

  /// 0 = versione completa; numeri più alti = più facilitata.
  final int level;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.testMode,
    required this.variants,
    this.perLeg = false,
  });

  final ExerciseId id;
  final String name;
  final MuscleGroup group;
  final TestMode testMode;

  /// variants[0] è la versione completa, le successive sono facilitate in
  /// ordine.
  final List<ExerciseVariant> variants;

  /// Gli affondi si contano per gamba.
  final bool perLeg;

  ExerciseVariant variant(int level) =>
      variants[level.clamp(0, variants.length - 1)];

  int get easiestLevel => variants.length - 1;
}

const Map<ExerciseId, Exercise> exercises = {
  ExerciseId.pushUp: Exercise(
    id: ExerciseId.pushUp,
    name: 'Push-up',
    group: MuscleGroup.push,
    testMode: TestMode.maxReps,
    variants: [
      ExerciseVariant('Push-up', level: 0),
      ExerciseVariant('Push-up sulle ginocchia', level: 1),
      ExerciseVariant('Push-up inclinati', level: 2),
      ExerciseVariant('Push-up al muro', level: 3),
    ],
  ),
  ExerciseId.crunch: Exercise(
    id: ExerciseId.crunch,
    name: 'Crunch',
    group: MuscleGroup.core,
    testMode: TestMode.maxReps,
    variants: [
      ExerciseVariant('Crunch', level: 0),
      ExerciseVariant('Crunch corto', level: 1),
    ],
  ),
  ExerciseId.legRaise: Exercise(
    id: ExerciseId.legRaise,
    name: 'Leg raise',
    group: MuscleGroup.core,
    testMode: TestMode.maxReps,
    variants: [
      ExerciseVariant('Leg raise', level: 0),
      ExerciseVariant('Leg raise a ginocchia piegate', level: 1),
    ],
  ),
  ExerciseId.squat: Exercise(
    id: ExerciseId.squat,
    name: 'Squat',
    group: MuscleGroup.legs,
    testMode: TestMode.repsIn60s,
    variants: [
      ExerciseVariant('Squat', level: 0),
      ExerciseVariant('Squat sulla sedia', level: 1),
    ],
  ),
  ExerciseId.lunge: Exercise(
    id: ExerciseId.lunge,
    name: 'Affondi',
    group: MuscleGroup.legs,
    testMode: TestMode.maxReps,
    perLeg: true,
    variants: [
      ExerciseVariant('Affondi', level: 0),
      ExerciseVariant('Affondi con appoggio', level: 1),
    ],
  ),
  ExerciseId.jumpingJack: Exercise(
    id: ExerciseId.jumpingJack,
    name: 'Jumping jack',
    group: MuscleGroup.cardio,
    testMode: TestMode.repsIn60s,
    variants: [
      ExerciseVariant('Jumping jack', level: 0),
      ExerciseVariant('Step jack', level: 1),
    ],
  ),
  ExerciseId.plank: Exercise(
    id: ExerciseId.plank,
    name: 'Plank',
    group: MuscleGroup.core,
    testMode: TestMode.hold,
    variants: [ExerciseVariant('Plank', level: 0)],
  ),
};

/// I sei esercizi del test iniziale e della quest giornaliera, in ordine.
const List<ExerciseId> baseExercises = [
  ExerciseId.pushUp,
  ExerciseId.crunch,
  ExerciseId.legRaise,
  ExerciseId.squat,
  ExerciseId.lunge,
  ExerciseId.jumpingJack,
];
