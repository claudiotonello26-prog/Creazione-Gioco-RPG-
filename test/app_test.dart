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
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    for (final label in ['Home', 'Allenati', 'Forgia', 'Arena', 'Profilo']) {
      expect(find.text(label), findsWidgets);
    }
    for (final label in ['Allenati', 'Forgia', 'Arena', 'Profilo']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
    }
    expect(find.text('MAPPA DEL CORPO (7 GIORNI)'), findsOneWidget);
  });
}
