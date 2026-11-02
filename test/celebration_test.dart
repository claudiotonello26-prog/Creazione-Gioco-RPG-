import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> _ready() async {
  SharedPreferences.setMockInitialValues({});
  final s = GameState();
  await s.load();
  s.acceptHealth();
  s.completeTest({for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0)});
  s.trainerEnabled = false;
  return s;
}

void main() {
  testWidgets('salire di livello e alzare un attributo fa apparire la festa al centro',
      (tester) async {
    final s = await _ready();
    await tester.pumpWidget(IronOathApp(state: s));
    await tester.pumpAndSettle();
    expect(find.text('SEI SALITO DI LIVELLO'), findsNothing);

    // Abbastanza esperienza per salire: lo stretching la registra e avvisa.
    s.character.xp = Character.xpForLevel(2) + 1;
    s.completeStretching();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SEI SALITO DI LIVELLO'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('SEI SALITO DI LIVELLO'), findsNothing);

    final before = s.character.attr(Attribute.strength);
    expect(s.raiseAttribute(Attribute.strength), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('MIGLIORATO'), findsOneWidget);
    expect(find.text('${before + 1}'), findsWidgets);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });
}
