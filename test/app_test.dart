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
    expect(find.text('IRON OATH'), findsOneWidget);
    await tester.tap(find.text('HO CAPITO, INIZIAMO'));
    await tester.pumpAndSettle();
    expect(find.text('IL TUO GIURAMENTO'), findsOneWidget);
  });

  testWidgets('dopo il test si vedono le cinque schede', (tester) async {
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
    for (final label in ['Home', 'Training', 'Forgia', 'Arena', 'Attributi']) {
      expect(find.text(label), findsWidgets);
    }
    for (final label in ['Training', 'Forgia', 'Arena', 'Attributi']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }
    expect(find.text('VIGORE'), findsOneWidget);
  });

  testWidgets('Ser Corvino si presenta alla prima apertura', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    state.acceptHealth();
    state.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('SER CORVINO'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('SER CORVINO'));
      await tester.pumpAndSettle();
    }
    expect(find.text('SER CORVINO'), findsNothing);
    expect(state.seenHints, contains('home'));
  });
}
