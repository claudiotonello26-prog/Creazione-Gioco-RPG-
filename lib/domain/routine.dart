import 'exercise.dart';

/// Risultato di un esercizio nel test: rep (o rep per gamba) e versione usata.
class TestResult {
  const TestResult({required this.reps, required this.variantLevel});

  final int reps;
  final int variantLevel;

  Map<String, dynamic> toJson() => {'reps': reps, 'variant': variantLevel};

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
        reps: json['reps'] as int,
        variantLevel: json['variant'] as int,
      );
}

class QuestItem {
  const QuestItem({
    required this.exercise,
    required this.target,
    required this.variantLevel,
  });

  final ExerciseId exercise;
  final int target;
  final int variantLevel;

  Exercise get info => exercises[exercise]!;
  String get label => info.variant(variantLevel).name;
}

/// Regole della quest giornaliera total body.
class RoutineRules {
  static const double questRatio = 0.60;
  static const int minimumReps = 3;
  static const double weeklyIncrease = 0.05;
  static const int daysForIncrease = 7;
  static const int retestEveryDays = 28;

  /// Quando una versione facilitata arriva a circa 15 rep nella quest, si
  /// propone la versione successiva.
  static const int promoteVariantAt = 15;

  /// 60% del test, arrotondato per difetto, minimo 3 rep, moltiplicato per la
  /// progressione accumulata.
  static int questTarget(int testReps, {double progression = 1.0}) {
    final raw = (testReps * questRatio * progression).floor();
    return raw < minimumReps ? minimumReps : raw;
  }

  static List<QuestItem> dailyQuest(
    Map<ExerciseId, TestResult> test, {
    double progression = 1.0,
  }) {
    return [
      for (final id in baseExercises)
        if (test[id] != null)
          QuestItem(
            exercise: id,
            target: questTarget(test[id]!.reps, progression: progression),
            variantLevel: test[id]!.variantLevel,
          ),
    ];
  }

  /// Dopo [daysForIncrease] giorni di quest completate con buona forma i numeri
  /// salgono del 5%.
  static double nextProgression(double current, int goodDaysInARow) {
    if (goodDaysInARow > 0 && goodDaysInARow % daysForIncrease == 0) {
      return current * (1 + weeklyIncrease);
    }
    return current;
  }

  static bool shouldSuggestHarderVariant(QuestItem item) =>
      item.variantLevel > 0 && item.target >= promoteVariantAt;
}

/// Sfide suggerite dopo la quest, in base ai giorni di allenamento scelti.
List<List<MuscleGroup>> weeklyPlan(int daysPerWeek) {
  switch (daysPerWeek) {
    case <= 2:
      return [
        [MuscleGroup.push, MuscleGroup.stretching],
        [MuscleGroup.legs, MuscleGroup.core],
      ];
    case 3:
      return [
        [MuscleGroup.push],
        [MuscleGroup.legs],
        [MuscleGroup.core, MuscleGroup.stretching],
      ];
    case 4:
      return [
        [MuscleGroup.push],
        [MuscleGroup.legs],
        [MuscleGroup.stretching, MuscleGroup.core],
        [MuscleGroup.cardio],
      ];
    default:
      return [
        [MuscleGroup.push],
        [MuscleGroup.legs],
        [MuscleGroup.stretching, MuscleGroup.core],
        [MuscleGroup.cardio],
        [MuscleGroup.mobility],
        if (daysPerWeek >= 6) [MuscleGroup.push, MuscleGroup.stretching],
      ];
  }
}
