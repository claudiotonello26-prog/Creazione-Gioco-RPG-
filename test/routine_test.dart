import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';

void main() {
  test('la quest è il 60% del test, per difetto, minimo 3', () {
    expect(RoutineRules.questTarget(10), 6);
    expect(RoutineRules.questTarget(30), 18);
    expect(RoutineRules.questTarget(15), 9);
    expect(RoutineRules.questTarget(35), 21);
    expect(RoutineRules.questTarget(12), 7);
    expect(RoutineRules.questTarget(50), 30);
    expect(RoutineRules.questTarget(2), 3);
  });

  test('la progressione sale del 5% ogni 7 giorni buoni', () {
    var p = 1.0;
    for (var day = 1; day <= 14; day++) {
      p = RoutineRules.nextProgression(p, day);
    }
    expect(p, closeTo(1.1025, 1e-9));
    expect(RoutineRules.questTarget(20, progression: p), 13);
  });

  test('quest giornaliera con i sei esercizi', () {
    final quest = RoutineRules.dailyQuest({
      for (final id in baseExercises) id: const TestResult(reps: 20, variantLevel: 0),
    });
    expect(quest.map((q) => q.exercise), baseExercises);
    expect(quest.every((q) => q.target == 12), isTrue);
  });

  test('piano settimanale per giorni scelti', () {
    expect(weeklyPlan(2), hasLength(2));
    expect(weeklyPlan(3), hasLength(3));
    expect(weeklyPlan(4).last, [MuscleGroup.cardio]);
    expect(weeklyPlan(5).expand((d) => d), contains(MuscleGroup.mobility));
  });
}
