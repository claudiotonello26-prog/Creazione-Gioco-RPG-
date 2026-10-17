import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/art.dart';
import 'core/theme.dart';
import 'data/game_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/intro_screen.dart';
import 'ui/screens/onboarding.dart';
import 'core/sound.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
        builder: (context, child) => _intro
            ? child!
            : SoulsBackground(child: SafeArea(top: false, child: child!)),
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
