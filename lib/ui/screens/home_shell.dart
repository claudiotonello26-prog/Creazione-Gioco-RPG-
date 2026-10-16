import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/game_state.dart';
import 'arena_tab.dart';
import 'forge_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
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

  void goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onNavigate: goTo),
      const TrainTab(),
      const ForgeTab(),
      const ArenaTab(),
      const ProfileTab(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.castle_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Allenati'),
          NavigationDestination(icon: Icon(Icons.hardware), label: 'Forgia'),
          NavigationDestination(icon: Icon(Icons.sports_kabaddi), label: 'Arena'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }
}
