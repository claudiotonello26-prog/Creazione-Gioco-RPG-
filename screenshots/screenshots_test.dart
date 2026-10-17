// Schermate dell'app per controllare la grafica senza un telefono:
//   flutter test screenshots --update-goldens
// Le immagini finiscono in screenshots/out/. Non fa parte della CI.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/main.dart';
import 'package:iron_oath/ui/screens/combat_screen.dart';
import 'package:iron_oath/ui/screens/walk_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _fonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  await _loadFont('MaterialIcons',
      ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  await _loadFont('Cinzel', ['assets/fonts/Cinzel-Regular.ttf', 'assets/fonts/Cinzel-Bold.ttf']);
  await _loadFont('EBGaramond', [
    'assets/fonts/EBGaramond-Regular.ttf',
    'assets/fonts/EBGaramond-SemiBold.ttf',
    'assets/fonts/EBGaramond-Italic.ttf',
  ]);
  await _loadFont('Roboto', ['$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf']);
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  // Barra di navigazione di Android a tre tasti, come sul Galaxy A35.
  t.view.padding = const FakeViewPadding(top: 72, bottom: 144);
}

Future<GameState> _state({bool onboarded = true}) async {
  SharedPreferences.setMockInitialValues({});
  final s = GameState();
  await s.load();
  if (onboarded) {
    s.acceptHealth();
    s.completeTest({
      for (final id in baseExercises) id: const TestResult(reps: 15, variantLevel: 0),
    });
  }
  return s;
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.pumpAndSettle();
  // Le immagini degli asset si decodificano fuori dal tempo finto del test.
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));
}

void main() {
  setUpAll(_fonts);

  testWidgets('onboarding', (t) async {
    _phone(t);
    await t.pumpWidget(IronOathApp(state: await _state(onboarded: false)));
    await _shot(t, '01_avviso');
    await t.tap(find.text('HO CAPITO, INIZIAMO'));
    await _shot(t, '02_giuramento');
  });

  testWidgets('schede', (t) async {
    _phone(t);
    await t.pumpWidget(IronOathApp(state: await _state()));
    await _shot(t, '10_home');
    for (final (i, label) in ['Allenati', 'Forgia', 'Arena', 'Eroe'].indexed) {
      await t.tap(find.widgetWithText(NavigationDestination, label));
      await _shot(t, '1${i + 1}_${label.toLowerCase()}');
    }
  });

  testWidgets('camminata e YOU DIED', (t) async {
    _phone(t);
    await t.pumpWidget(IronOathApp(state: await _state()));
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byType(NavigationBar)))
        .push(MaterialPageRoute<void>(builder: (_) => const WalkScreen()));
    await _shot(t, '20_camminata');
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(backgroundColor: Color(0xFF1C1712), body: YouDiedOverlay()),
    ));
    await _shot(t, '21_you_died');
  });
}
