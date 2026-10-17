import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/art.dart';
import 'core/theme.dart';
import 'data/game_state.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Art.init();
  final state = GameState();
  await state.load();
  runApp(IronOathApp(state: state));
}

class IronOathApp extends StatelessWidget {
  const IronOathApp({super.key, required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'Iron Oath',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Niente sotto la barra di navigazione di Android (Android 15+ disegna
        // l'app a tutto schermo): tutte le pagine, i fogli e i dialoghi
        // stanno sopra.
        builder: (context, child) => SoulsBackground(
          child: SafeArea(top: false, child: child!),
        ),
        home: Consumer<GameState>(
          builder: (_, s, _) =>
              s.onboarded ? const HomeShell() : const OnboardingFlow(),
        ),
      ),
    );
  }
}
