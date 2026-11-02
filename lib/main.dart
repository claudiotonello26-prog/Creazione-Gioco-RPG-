import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/art.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'data/game_state.dart';
import 'ui/widgets/celebration.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/intro_screen.dart';
import 'ui/screens/onboarding.dart';
import 'core/sound.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  systemLang = () =>
      PlatformDispatcher.instance.locale.languageCode == 'it' ? Lang.it : Lang.en;
  await Art.init();
  await Sound.init();
  final state = GameState();
  await state.load();
  runApp(IronOathApp(state: state, intro: true));
}

class IronOathApp extends StatefulWidget {
  const IronOathApp({super.key, required this.state, this.intro = false});
  final GameState state;

  /// Mostra l'apertura dorata prima della Home.
  final bool intro;

  @override
  State<IronOathApp> createState() => _IronOathAppState();
}

class _IronOathAppState extends State<IronOathApp> {
  late bool _intro = widget.intro;
  late Lang _lang = appLang;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_langChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_langChanged);
    super.dispose();
  }

  /// Cambiata la lingua, si ridisegna tutto: anche i testi dentro widget che
  /// non ascoltano lo stato.
  void _langChanged() {
    if (appLang == _lang || !mounted) return;
    _lang = appLang;
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'Gym Oath',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Niente sotto la barra di navigazione di Android (Android 15+ disegna
        // l'app a tutto schermo): tutte le pagine, i fogli e i dialoghi
        // stanno sopra.
        // Sopra a tutto, le feste per livello, abilità e attributi.
        builder: (context, child) => _intro
            ? child!
            : CelebrationLayer(
                state: state,
                child: SoulsBackground(child: SafeArea(top: false, child: child!)),
              ),
        home: _intro
            ? IntroScreen(onDone: () => setState(() => _intro = false))
            : Consumer<GameState>(
                builder: (_, s, _) =>
                    s.onboarded ? const HomeShell() : const OnboardingFlow(),
              ),
      ),
    );
  }
}
