import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late GameState s;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 16, 9);
    s = GameState(clock: () => now);
    await s.load();
    s.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
  });

  List<RepQuality> perfect(int n) => List.filled(n, RepQuality.perfect);

  test('Bonus Varietà: le prime 20 rep del gruppo valgono doppio', () {
    final first = s.xpFor(ExerciseId.pushUp, perfect(10), inCombat: true);
    expect(first, 200);
    s.addTraining(ExerciseId.pushUp, perfect(20));
    final later = s.xpFor(ExerciseId.pushUp, perfect(10), inCombat: true);
    expect(later, 100);
  });

  test('quest completa + stretching = chiave, rune e Punto Disciplina', () {
    for (final q in s.quest) {
      s.addTraining(q.exercise, perfect(q.target));
    }
    expect(s.questComplete, isFalse);
    s.completeStretching();
    expect(s.questComplete, isTrue);
    expect(s.expeditionKeys, 1);
    expect(s.character.disciplinePoints, 1);
    expect(s.useExpeditionKey(), isTrue);
    expect(s.useExpeditionKey(), isFalse, reason: 'una spedizione al giorno');
  });

  test('la streak sale giorno dopo giorno e si rompe saltando un giorno', () {
    s.addTraining(ExerciseId.squat, perfect(5));
    expect(s.streak, 1);
    now = now.add(const Duration(days: 1));
    s.refreshDay();
    s.addTraining(ExerciseId.squat, perfect(5));
    expect(s.streak, 2);
    now = now.add(const Duration(days: 2));
    s.refreshDay();
    expect(s.streak, 0);
    expect(s.questDoneFor(ExerciseId.squat), 0);
  });

  test('salvataggio e ricaricamento', () async {
    s.addTraining(ExerciseId.squat, perfect(5));
    s.character.addMaterial('iron_ore', 3);
    s.character.addMaterial('beast_essence', 1);
    expect(s.craftForgeStone(), isTrue);
    await Future<void>.delayed(Duration.zero);
    final again = GameState(clock: () => now);
    await again.load();
    expect(again.onboarded, isTrue);
    expect(again.character.materials['forge_stone_1'], 1);
    expect(again.questDoneFor(ExerciseId.squat), 5);
  });

  test('ritest dopo 4 settimane', () {
    expect(s.retestDue, isFalse);
    now = now.add(const Duration(days: 28));
    expect(s.retestDue, isTrue);
  });
}
