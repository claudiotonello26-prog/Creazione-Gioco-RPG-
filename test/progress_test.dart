import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/progress.dart';

void main() {
  final now = DateTime(2026, 10, 17);
  final baseline = {ExerciseId.pushUp: 20 * variantDifficulty(1)}; // 20 sulle ginocchia

  ExerciseDay set(int reps, double diff) =>
      ExerciseDay(trackAs: ExerciseId.pushUp, region: BodyRegion.upper)..add(reps, diff);

  test('meno rep ma più difficili: la forza sale lo stesso', () {
    final history = <String, Map<String, ExerciseDay>>{
      '2026-10-10': {'Push-up sulle ginocchia': set(20, variantDifficulty(1))},
      '2026-10-17': {'Push-up': set(14, variantDifficulty(0))},
    };
    final days = computeProgress(history, baseline, now, ProgressSpan.day);
    expect(days.last.strength[BodyRegion.upper], greaterThan(100));
    expect(days.last.reps, 14);
    final week7 = days[days.length - 8];
    expect(week7.strength[BodyRegion.upper], closeTo(100, 0.01));
  });

  test('settimane e mesi prendono la serie migliore', () {
    final history = <String, Map<String, ExerciseDay>>{
      '2026-10-13': {'Push-up sulle ginocchia': set(10, variantDifficulty(1))},
      '2026-10-15': {'Push-up sulle ginocchia': set(30, variantDifficulty(1))},
    };
    final weeks = computeProgress(history, baseline, now, ProgressSpan.week);
    expect(weeks.last.strength[BodyRegion.upper], closeTo(150, 0.01));
    expect(weeks.last.reps, 40);
    final months = computeProgress(history, baseline, now, ProgressSpan.month);
    expect(months.last.label, 'ott');
    expect(months.first.strength, isEmpty);
  });

  test('record e confronto con il solito', () {
    final history = <String, Map<String, ExerciseDay>>{
      '2026-10-10': {'Squat': ExerciseDay(trackAs: ExerciseId.squat)..add(20, 1)},
      '2026-10-12': {'Squat': ExerciseDay(trackAs: ExerciseId.squat)..add(30, 1)},
      '2026-10-17': {'Squat': ExerciseDay(trackAs: ExerciseId.squat)..add(25, 1)},
    };
    final s = exerciseSummaries(history, DateTime(2026, 10, 12)).single;
    expect(s.record, 30);
    expect(s.lastBest, 25);
    expect(s.usualBest, 25);
    expect(s.repsInPeriod, 55);
  });
}
