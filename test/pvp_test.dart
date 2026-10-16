import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/pvp.dart';

void main() {
  test('divisioni per esercizio in base al record', () {
    expect(divisionFor(ExerciseId.pushUp, 5), Division.recruit);
    expect(divisionFor(ExerciseId.pushUp, 30), Division.knight);
    expect(divisionFor(ExerciseId.squat, 70), Division.champion);
  });

  test('N rep: vince il tempo più basso, la forma fa da spareggio', () {
    final c = arenaChallenges[ExerciseId.pushUp]!;
    const fast = ArenaResult(validReps: 20, elapsedSeconds: 30, formScore: 0.8);
    const slow = ArenaResult(validReps: 20, elapsedSeconds: 40, formScore: 1.0);
    expect(compareResults(c, fast, slow), greaterThan(0));
    const sameTimeBetterForm = ArenaResult(validReps: 20, elapsedSeconds: 30, formScore: 0.95);
    expect(compareResults(c, sameTimeBetterForm, fast), greaterThan(0));
  });

  test('chi non completa perde contro chi completa', () {
    final c = arenaChallenges[ExerciseId.squat]!;
    const done = ArenaResult(validReps: 30, elapsedSeconds: 170, formScore: 0.6);
    const notDone = ArenaResult(validReps: 25, elapsedSeconds: 60, formScore: 1, completed: false);
    expect(compareResults(c, done, notDone), greaterThan(0));
  });

  test('jumping jack: più rep in 60 secondi', () {
    final c = arenaChallenges[ExerciseId.jumpingJack]!;
    final opp = ArenaOpponent.generate(Division.squire, random: Random(3));
    final r = opp.resultFor(c);
    expect(r.elapsedSeconds, 60);
    expect(r.validReps, greaterThan(20));
  });

  test('avversari più forti nelle divisioni alte', () {
    final rnd = Random(7);
    final recruit = ArenaOpponent.generate(Division.recruit, random: rnd);
    final champ = ArenaOpponent.generate(Division.champion, random: rnd);
    expect(champ.secondsPerRep, lessThan(recruit.secondsPerRep));
  });
}
