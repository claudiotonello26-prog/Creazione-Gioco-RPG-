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
import 'package:iron_oath/ui/screens/path_screen.dart';
import 'package:iron_oath/ui/screens/progress_screen.dart';
import 'package:iron_oath/domain/progress.dart';
import 'package:iron_oath/ui/widgets/exercise_demo.dart';
import 'package:iron_oath/ui/screens/forge_tab.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/ui/screens/gear_screens.dart';
import 'package:iron_oath/ui/screens/train_tab.dart';
import 'package:iron_oath/domain/enemies.dart';
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

  testWidgets('apertura', (t) async {
    _phone(t);
    await t.pumpWidget(IronOathApp(state: await _state(), intro: true));
    await t.pump(const Duration(milliseconds: 2400));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/00_apertura.png'));
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
  });

  testWidgets('onboarding', (t) async {
    _phone(t);
    await t.pumpWidget(IronOathApp(state: await _state(onboarded: false)));
    await _shot(t, '01_avviso');
    await t.tap(find.text('HO CAPITO, INIZIAMO'));
    await _shot(t, '02_giuramento');
  });

  testWidgets('schede', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    await t.pumpWidget(IronOathApp(state: st));
    await _shot(t, '10_home');
    for (final (i, label) in ['Training', 'Forgia', 'Arena', 'Attributi'].indexed) {
      await t.tap(find.widgetWithText(NavigationDestination, label));
      await _shot(t, '1${i + 1}_${label.toLowerCase()}');
    }
  });

  testWidgets('camminata e YOU DIED', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byType(NavigationBar)))
        .push(MaterialPageRoute<void>(builder: (_) => const WalkScreen()));
    await _shot(t, '20_camminata');
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(backgroundColor: Color(0xFF1C1712), body: YouDiedOverlay()),
    ));
    await _shot(t, '21_you_died');
  });

  testWidgets('trainer, sentiero, forgia', (t) async {
    _phone(t);
    final st = await _state();
    st.character.addMaterial('forge_stone_1', 3);
    st.character.addMaterial('iron_ore', 6);
    st.character.addMaterial('coal', 3);
    st.character.weapon.upgrade = 10;
    st.character.armors.add('templar_plate');
    for (final slot in ArmorSlot.values) {
      st.character.worn[slot] = 'templar_plate';
    }
    await t.pumpWidget(IronOathApp(state: st));
    await _shot(t, '30_trainer');
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    await _shot(t, '31_home_cavaliere');
    st.trainerEnabled = false;
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => const PathScreen(group: MuscleGroup.push)));
    await _shot(t, '32_sentiero');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const StationScreen(station: Station.furnace)));
    await _shot(t, '33_fornace');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const StationScreen(station: Station.enchant)));
    await _shot(t, '34_incantamento');
  });

  testWidgets('equipaggiamento, inventario, mercato', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.runes = 900;
    st.character.addMaterial('iron_ore', 7);
    st.character.addMaterial('forge_stone_1', 2);
    st.character.addMaterial('holy_shard', 1);
    st.character.armors.add('gambeson');
    st.character.worn[ArmorSlot.chest] = 'gambeson';
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => const EquipmentScreen()));
    await _shot(t, '50_equipaggiamento');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const InventoryScreen()));
    await _shot(t, '51_inventario');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const MarketScreen()));
    await _shot(t, '52_mercato');
  });

  testWidgets('gruppi e spedizioni', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.clearedExpeditions.add('buried_forges');
    st.expeditionKeys = 2;
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => const GroupScreen(group: MuscleGroup.push)));
    await _shot(t, '60_gruppo_spinta');
    nav.push(MaterialPageRoute<void>(builder: (_) => ExpeditionScreen(expedition: expeditionById('giants_furnace'))));
    await _shot(t, '61_spedizione');
    nav.pop();
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const GroupScreen(group: MuscleGroup.stretching)));
    await _shot(t, '62_gruppo_stretching');
  });

  testWidgets('andamento della forza', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    final now = DateTime.now();
    for (var d = 40; d >= 0; d -= 2) {
      final day = dayKeyOf(now.subtract(Duration(days: d)));
      final g = (40 - d) / 40;
      st.history[day] = {
        'Push-up': ExerciseDay(trackAs: ExerciseId.pushUp, region: BodyRegion.upper)
          ..add((st.testRepsFor(ExerciseId.pushUp) * (0.9 + 0.35 * g)).round(), 1),
        'Crunch': ExerciseDay(trackAs: ExerciseId.crunch, region: BodyRegion.core)
          ..add((st.testRepsFor(ExerciseId.crunch) * (1 + 0.15 * g)).round(), 1),
        'Squat': ExerciseDay(trackAs: ExerciseId.squat, region: BodyRegion.legs)
          ..add((st.testRepsFor(ExerciseId.squat) * (1.05 + 0.5 * g)).round(), 1),
      };
    }
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byType(NavigationBar)))
        .push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));
    await _shot(t, '40_andamento');
  });

  testWidgets('dimostrazioni degli esercizi', (t) async {
    _phone(t);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0B09),
        body: GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.fromLTRB(4, 60, 4, 4),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final m in DemoMove.values)
              for (final f in [0.0, 1.0])
                Container(
                  color: const Color(0xFF17130F),
                  child: Stack(children: [
                    Positioned.fill(child: CustomPaint(painter: DemoPainter(m, f))),
                    if (f == 0)
                      Text(m.file, style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ]),
                ),
          ],
        ),
      ),
    ));
    await _shot(t, '41_dimostrazioni');
  });
}
