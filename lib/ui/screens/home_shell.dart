import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import 'arena_tab.dart';
import 'forge_tab.dart';
import 'home_tab.dart';
import '../widgets/trainer.dart';
import '../../core/i18n.dart';
import 'gear_screens.dart';
import 'walk_screen.dart';
import 'train_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    maybeShowHint(context, 'home');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) context.read<GameState>().refreshDay();
  }

  static const _hints = ['home', 'training', 'walk', 'forge', 'market', 'arena'];

  void goTo(int tab) {
    setState(() => _tab = tab);
    maybeShowHint(context, _hints[tab]);
  }

  int _lastPoints = -1;

  /// Avviso quando arrivano punti nuovi da spendere.
  void _notifyPoints(int points) {
    if (_lastPoints >= 0 && points > _lastPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Livello su! Hai $points punti da spendere negli attributi.'),
            backgroundColor: Palette.stoneLight,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'VAI', onPressed: () => goTo(0)),
          ),
        );
      });
    }
    _lastPoints = points;
  }

  @override
  Widget build(BuildContext context) {
    final points = context.watch<GameState>().character.availablePoints;
    _notifyPoints(points);
    final tabs = [
      HomeTab(onNavigate: goTo),
      TrainTab(onNavigate: goTo),
      const WalkScreen(asTab: true),
      const ForgeTab(),
      const MarketScreen(),
      const ArenaTab(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: tabs),
      ),
      bottomNavigationBar: NavigationBarTheme(
        // Sei schede: etichette più piccole perché stiano su una riga.
        data: NavigationBarTheme.of(context).copyWith(
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: kTitleFont,
              fontSize: 9.5,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
              color: states.contains(WidgetState.selected) ? Palette.goldBright : Palette.ash,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: goTo,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: points > 0,
                label: Text('$points'),
                child: const Icon(Icons.castle_outlined),
              ),
              label: tr('Home'),
            ),
            NavigationDestination(icon: const Icon(Icons.fitness_center), label: tr('Training')),
            NavigationDestination(icon: const Icon(Icons.directions_walk), label: tr('Gathering')),
            NavigationDestination(icon: const Icon(Icons.hardware), label: tr('Forge')),
            NavigationDestination(icon: const Icon(Icons.storefront), label: tr('Market')),
            NavigationDestination(icon: const Icon(Icons.sports_kabaddi), label: tr('Arena')),
          ],
        ),
      ),
    );
  }
}
