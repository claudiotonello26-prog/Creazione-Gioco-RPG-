import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import 'arena_tab.dart';
import 'forge_tab.dart';
import 'home_tab.dart';
import '../widgets/trainer.dart';
import 'attributes_tab.dart';
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

  static const _hints = ['home', 'training', 'forge', 'arena', 'attributes'];

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Livello su! Hai $points punti da spendere in Attributi.'),
          backgroundColor: Palette.stoneLight,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'VAI', onPressed: () => goTo(4)),
        ));
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
      const ForgeTab(),
      const ArenaTab(),
      const AttributesTab(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: goTo,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.castle_outlined), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Training'),
          const NavigationDestination(icon: Icon(Icons.hardware), label: 'Forgia'),
          const NavigationDestination(icon: Icon(Icons.sports_kabaddi), label: 'Arena'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: points > 0,
              label: Text('$points'),
              child: const Icon(Icons.trending_up),
            ),
            label: 'Attributi',
          ),
        ],
      ),
    );
  }
}
