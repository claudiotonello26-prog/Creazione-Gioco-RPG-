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
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/ui/screens/gear_screens.dart';
import 'package:iron_oath/ui/screens/train_tab.dart';
import 'package:iron_oath/ui/screens/expedition_map.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:iron_oath/ui/screens/guide_screen.dart';
import 'package:iron_oath/ui/screens/quest_screen.dart';
import 'package:iron_oath/ui/screens/character_creation.dart';
import 'package:iron_oath/ui/screens/rest_screen.dart';
import 'package:iron_oath/ui/screens/steps_card.dart';
import 'package:iron_oath/core/theme.dart';
import 'package:iron_oath/core/art.dart';
import 'package:iron_oath/online/guild_service.dart';
import 'package:iron_oath/online/nakama_client.dart';
import 'package:iron_oath/ui/screens/guild_tab.dart';
import 'package:iron_oath/ui/widgets/oath_bar.dart';
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
  await _loadFont('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
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
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await t.pump(const Duration(milliseconds: 900));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/00a_apertura_anello.png'));
    await t.pump(const Duration(milliseconds: 2100));
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
    for (final (i, label) in ['Training', 'Raccolta', 'Forgia', 'Mercato', 'Gilda'].indexed) {
      await t.tap(find.widgetWithText(NavigationDestination, label));
      await _shot(t, '1${i + 1}_${label.toLowerCase()}');
    }
  });

  testWidgets('training con arena e gilda', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.useCamera = true;
    st.serverAddress = '127.0.0.1';
    await t.pumpWidget(IronOathApp(state: st));
    await t.tap(find.widgetWithText(NavigationDestination, 'Training'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(Tab, 'Arena'));
    await _shot(t, '16_training_arena');
    final g =
        GuildService(
            client: NakamaClient(ServerConfig.parse('127.0.0.1')!),
            deviceId: 'x',
            username: 'Aldric',
          )
          ..guild = Guild(
            id: 'g',
            name: 'Ordine del Ferro',
            description: 'Mai saltare il giorno gambe',
            count: 4,
          )
          ..myState = 0
          ..members = [
            GuildMember(id: '', name: 'Aldric', state: 0, online: true),
            GuildMember(id: 'b', name: 'Brenna', state: 1, online: true),
            GuildMember(id: 'c', name: 'Corvo', state: 2, online: false),
            GuildMember(id: 'd', name: 'Dario', state: 3, online: false),
          ]
          ..sessions = [
            GuildSession(
              matchId: 'm',
              friendly: false,
              exercise: ExerciseId.squat,
              host: 'b',
              hostName: 'Brenna',
              size: 2,
            ),
          ]
          ..challenges = [
            Challenge(id: 'n', matchId: 'm2', exercise: ExerciseId.pushUp, from: 'Corvo'),
          ];
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: const OathBar(title: Text('GILDA'), accent: Sections.guild),
          body: GuildTab(service: g),
        ),
      ),
    );
    await _shot(t, '17_gilda');
    await t.drag(find.byType(ListView).last, const Offset(0, -700));
    await _shot(t, '18_gilda_membri');
  });

  testWidgets('home con punti da spendere', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.disciplinePoints = 3;
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -560));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.add_circle).first);
    await t.tap(find.byIcon(Icons.add_circle).at(2));
    await _shot(t, '16_home_attributi');
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
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(backgroundColor: Color(0xFF1C1712), body: YouDiedOverlay()),
      ),
    );
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
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const StationScreen(station: Station.furnace)),
    );
    await _shot(t, '33_fornace');
    nav.pop();
    await t.pumpAndSettle();
    st.character.weapon.upgrade = 2;
    st.character.addMaterial('forge_stone_1', 4);
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const StationScreen(station: Station.enchant)),
    );
    await _shot(t, '34_incantamento');
  });

  testWidgets('risorsa, guida, bestiario', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.skillXp[Skill.woodcutting] = 30;
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => GatherScreen(resource: resourceById('ash_wood'), stepsToday: 22),
      ),
    );
    await _shot(t, '22_risorsa');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => GatherScreen(resource: resourceById('ash_wood'), stepsToday: 100),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.textContaining('CONSUMA I PASSI'));
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, '23_risorsa_bottino');
    await t.pump(const Duration(seconds: 3));
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const GuideScreen()));
    await t.pumpAndSettle();
    await t.tap(find.text('GIURAMENTO E BUILD'));
    await _shot(t, '24_guida');
    await t.scrollUntilVisible(find.text('ATTACCO'), 300);
    await t.tap(find.text('ATTACCO'));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).last, const Offset(0, -500));
    await _shot(t, '24b_guida_attacco');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const BestiaryScreen()));
    await _shot(t, '25_bestiario');
  });

  testWidgets('quest e postazione', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.addMaterial('ash_wood', 45);
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => const QuestScreen()));
    await _shot(t, '26_quest');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const StationScreen(station: Station.carpentry)),
    );
    await _shot(t, '35_carpenteria');
    await t.tap(find.text('CREA').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 1200));
    expect(find.text('ANNULLA'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/36_creazione_countdown.png'),
    );
    await t.tap(find.text('ANNULLA'));
    await t.pumpAndSettle();
  });

  testWidgets('personaggio disegnato', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.worn.clear();
    st.character.capeId = null;
    st.character.offhandId = null;
    st.character.look
      ..female = false
      ..style = 4
      ..hair = Appearance.natural
      ..shirt = 2
      ..pants = Appearance.natural;
    await t.runAsync(Art.init);
    await t.pumpWidget(IronOathApp(state: st));
    await _shot(t, '70_home_personaggio');
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => CharacterCreationScreen(onDone: () {})));
    await _shot(t, '71_creazione_uomo');
    await t.tap(find.text('DONNA'));
    await t.pumpAndSettle();
    await t.tap(find.byType(GestureDetector).at(0));
    await _shot(t, '72_creazione_donna');
    nav.pop();
    st.character.look
      ..female = true
      ..style = 6;
    for (final slot in [ArmorSlot.helm, ArmorSlot.chest, ArmorSlot.gloves, ArmorSlot.legs]) {
      st.character.worn[slot] = 'gambeson';
    }
    st.notifyListeners();
    await _shot(t, '73_home_giaco');
  });

  testWidgets('creazione personaggio e pausa tra esercizi', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.look
      ..hair = 2
      ..beard = true
      ..beardColor = 2
      ..face = 1
      ..shirt = 3;
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => CharacterCreationScreen(onDone: () {})));
    await _shot(t, '03_creazione_personaggio');
    await t.tap(find.text('DONNA'));
    await t.pumpAndSettle();
    await _shot(t, '03b_creazione_donna');
    nav.pop();
    await t.pumpAndSettle();
    st.claimStepMilestones(4300);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Column(
              children: [
                StepsCard(onOpenGathering: () {}, debugSteps: 4300),
                StepsCard(onOpenGathering: () {}, debugSteps: 10450),
              ],
            ),
          ),
        ),
      ),
    );
    await _shot(t, '38_passi_home');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const RestScreen(
          name: 'Crunch',
          exercise: ExerciseId.crunch,
          index: 2,
          total: 4,
          movePhone: true,
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/37_pausa_sposta_telefono.png'),
    );
    nav.pop();
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('equipaggiamento, inventario, mercato', (t) async {
    _phone(t);
    final st = await _state();
    st.trainerEnabled = false;
    st.character.runes = 900;
    st.character.addMaterial('iron_ore', 7);
    st.character.addMaterial('forge_stone_1', 2);
    st.character.addMaterial('holy_shard', 1);
    st.character.armors.addAll(['gambeson', 'chainmail']);
    for (final slot in ArmorSlot.values) {
      st.character.worn[slot] = slot == ArmorSlot.boots ? 'gambeson' : 'chainmail';
    }
    st.character.offhands.add('wooden_shield');
    st.character.offhandId = 'wooden_shield';
    st.character.capes.add('scarlet_cape');
    st.character.capeId = 'scarlet_cape';
    st.character.addMaterial('amulet_fang_charm', 1);
    st.wearNeck('fang_charm');
    st.character.weapon.upgrade = 6;
    st.character.addMaterial('amulet_ember_amulet', 1);
    st.character.addMaterial('amulet_regicide_seal', 1);
    st.character.addMaterial('beast_essence', 4);
    st.socketAmulet(st.character.weapon, 0, 'ember_amulet');
    st.socketAmulet(st.character.weapon, 1, 'regicide_seal');
    await t.pumpWidget(IronOathApp(state: st));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(NavigationBar)));
    nav.push(MaterialPageRoute<void>(builder: (_) => const EquipmentScreen()));
    await _shot(t, '50_equipaggiamento');
    await t.tap(find.text('CORAZZA'));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView).first, const Offset(0, -900));
    await _shot(t, '50b_armeria_corazza');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const InventoryScreen()));
    await _shot(t, '51_inventario');
    await t.tap(find.widgetWithText(Tab, 'Armi'));
    await _shot(t, '51b_inventario_armi');
    nav.pop();
    await t.pumpAndSettle();
    nav.push(MaterialPageRoute<void>(builder: (_) => const MarketScreen()));
    await _shot(t, '52_mercato');
    await t.tap(find.text('Fattucchiera'));
    await t.pumpAndSettle();
    await _shot(t, '53_fattucchiera');
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
    st.completeExpeditionStep('buried_forges', 0);
    st.completeExpeditionStep('buried_forges', 1);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ExpeditionMapScreen(expedition: expeditionById('buried_forges')),
      ),
    );
    await _shot(t, '61_spedizione');
    nav.pop();
    await t.pumpAndSettle();
    final e = expeditionById('lunar_ruins');
    for (var i = 0; i < 4; i++) {
      st.completeExpeditionStep(e.id, i);
    }
    st.expeditionBossDown(e);
    nav.push(MaterialPageRoute<void>(builder: (_) => ExpeditionMapScreen(expedition: e)));
    await _shot(t, '63_mappa_forziere');
    await t.tap(find.text('Tocca per aprire'));
    await t.pump(const Duration(seconds: 5));
    await _shot(t, '64_forziere_aperto');
    await t.tap(find.text('PRENDI TUTTO'));
    await t.pumpAndSettle();
    nav.pop();
    nav.pop();
    await t.pumpAndSettle();
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const GroupScreen(group: MuscleGroup.stretching)),
    );
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
    await t.pumpWidget(
      MaterialApp(
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
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: DemoPainter(m, f))),
                        if (f == 0)
                          Text(m.file, style: const TextStyle(color: Colors.white, fontSize: 9)),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
    await _shot(t, '41_dimostrazioni');
  });
}
