import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('primo avvio: avviso di salute e questionario', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    await tester.pumpWidget(IronOathApp(state: state));
    expect(find.text('GYM OATH'), findsOneWidget);
    await tester.ensureVisible(find.text('HO CAPITO, INIZIAMO'));
    await tester.tap(find.text('HO CAPITO, INIZIAMO'));
    await tester.pumpAndSettle();
    expect(find.text('IL TUO GIURAMENTO'), findsOneWidget);
  });

  testWidgets('dopo il test si vedono le sei schede', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    state.acceptHealth();
    state.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
    state.trainerEnabled = false;
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Training', 'Raccolta', 'Forgia', 'Mercato', 'Gilda']) {
      expect(find.text(label), findsWidgets);
    }
    for (final label in ['Training', 'Raccolta', 'Forgia', 'Mercato', 'Gilda', 'Home']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }
    // Armeria e Inventario stanno sotto la scheda del personaggio.
    await tester.scrollUntilVisible(
      find.text('ARMERIA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ARMERIA'), findsOneWidget);
  });

  testWidgets('Il Comandante Reynard si presenta alla prima apertura', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    state.acceptHealth();
    state.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('COMANDANTE REYNARD'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('COMANDANTE REYNARD'));
      await tester.pumpAndSettle();
    }
    expect(find.text('COMANDANTE REYNARD'), findsNothing);
    expect(state.seenHints, contains('home'));
  });
}
