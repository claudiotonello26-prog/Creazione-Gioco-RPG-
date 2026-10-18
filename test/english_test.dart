import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/core/i18n.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/main.dart';
import 'package:iron_oath/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parole che in un testo inglese non dovrebbero comparire.
final _italian = RegExp(
  r'\b(il|della|delle|degli|che|non|sei|hai|con|una|nel|alla|sul|più|ogni|tuo|tua|ancora|oggi|giorno|passi|livello|nuovo|scegli|forgia|allenati|riposo|bottino)\b|[àèìòù]',
  caseSensitive: false,
);

List<String> _italianTexts(WidgetTester tester) => [
      for (final w in tester.widgetList<RichText>(find.byType(RichText)))
        if (_italian.hasMatch(w.text.toPlainText())) w.text.toPlainText(),
    ];

void main() {
  tearDown(() => systemLang = () => Lang.it);

  testWidgets('con il telefono in inglese le schede sono in inglese', (tester) async {
    systemLang = () => Lang.en;
    SharedPreferences.setMockInitialValues({});
    final state = GameState();
    await state.load();
    expect(appLang, Lang.en);
    state.acceptHealth();
    state.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 10, variantLevel: 0),
    });
    state.trainerEnabled = false;
    await tester.pumpWidget(IronOathApp(state: state));
    await tester.pumpAndSettle();
    final found = <String>{..._italianTexts(tester)};
    for (final label in ['Training', 'Gathering', 'Forge', 'Market', 'Guild', 'Home']) {
      await tester.tap(find.widgetWithText(NavigationDestination, label));
      await tester.pumpAndSettle();
      found.addAll(_italianTexts(tester));
    }
    await tester.scrollUntilVisible(
      find.text('ARMORY'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    found.addAll(_italianTexts(tester));
    expect(find.text('ARMORY'), findsOneWidget);
    expect(found, isEmpty, reason: found.join('\n'));
    state.setLangPref(LangPref.it);
    await tester.pumpAndSettle();
    expect(find.text('ARMERIA'), findsOneWidget);
  });

  testWidgets('dalle impostazioni si passa a English e la Home cambia', (tester) async {
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
    expect(find.text('Raccolta'), findsWidgets);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Lingua'), findsOneWidget);
    await tester.tap(find.text('ENGLISH'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);
    expect(state.langPref, LangPref.en);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('Gathering'), findsWidgets);
    expect(find.text('Raccolta'), findsNothing);
  });
}
