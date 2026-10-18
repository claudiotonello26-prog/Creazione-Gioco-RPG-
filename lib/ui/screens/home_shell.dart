import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import 'arena_tab.dart';
import 'guild_tab.dart';
import 'forge_tab.dart';
import 'home_tab.dart';
import '../widgets/common.dart';
import '../widgets/oath_bar.dart';
import '../widgets/trainer.dart';
import '../../core/i18n.dart';
import 'gear_screens.dart';
import 'walk_screen.dart';
import 'train_tab.dart';
import '../../core/sound.dart';

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
    Sound.music(Music.home);
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

  static const _hints = ['home', 'training', 'walk', 'forge', 'market', 'guild'];

  static const _music = [
    Music.home,
    Music.training,
    Music.gathering,
    Music.forge,
    Music.market,
    Music.guild,
  ];

  void goTo(int tab) {
    if (tab != _tab) Sound.play(Sfx.tab);
    Sound.music(_music[tab]);
    setState(() => _tab = tab);
    maybeShowHint(context, _hints[tab]);
  }

  int _lastPoints = -1;
  bool? _questDone;

  /// Avviso quando arrivano punti nuovi da spendere.
  void _notifyPoints(int points) {
    if (_lastPoints >= 0 && points > _lastPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Sound.play(Sfx.levelUp);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(points == 1
                ? tr('Livello su! +1 punto attributo.')
                : tr('Livello su! +{points} punti attributo.', {'points': points})),
            backgroundColor: Palette.stoneLight,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: tr('VAI'), onPressed: () => goTo(0)),
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
    final quest = context.read<GameState>().questComplete;
    if (_questDone == false && quest) Sound.play(Sfx.questDone);
    _questDone = quest;
    // Raccolta e Mercato hanno già la loro barra; alle altre la dà la shell.
    Widget framed(String section, Color color, Widget body) => Scaffold(
          backgroundColor: Colors.transparent,
          appBar: OathBar(title: Text(tr(section).toUpperCase()), accent: color),
          body: body,
        );
    // Ogni scheda ha il suo colore e il suo sfondo.
    final tabs = [
      SectionBackdrop(
        art: 'home',
        color: Sections.home,
        child: framed('Home', Sections.home, HomeTab(onNavigate: goTo)),
      ),
      SectionBackdrop(
        art: 'training',
        color: Sections.training,
        child: _TrainingSection(onNavigate: goTo),
      ),
      const SectionBackdrop(
        art: 'gathering',
        color: Sections.gathering,
        child: WalkScreen(asTab: true),
      ),
      SectionBackdrop(
        art: 'forge',
        color: Sections.forge,
        child: framed('Forge', Sections.forge, const ForgeTab()),
      ),
      const SectionBackdrop(art: 'market', color: Sections.market, child: MarketScreen()),
      SectionBackdrop(
        art: 'guild',
        color: Sections.guild,
        child: framed('Guild', Sections.guild, const GuildTab()),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C160F), Color(0xFF0B0907)],
          ),
          border: Border(top: BorderSide(color: Palette.gold, width: 1)),
          boxShadow: [BoxShadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, -4))],
        ),
        child: NavigationBarTheme(
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
                  child: _navIcon('home', Icons.castle_outlined),
                ),
                label: tr('Home'),
              ),
              NavigationDestination(
                icon: _navIcon('training', Icons.fitness_center),
                label: tr('Training'),
              ),
              NavigationDestination(
                icon: _navIcon('gathering', Icons.directions_walk),
                label: tr('Gathering'),
              ),
              NavigationDestination(icon: _navIcon('forge', Icons.hardware), label: tr('Forge')),
              NavigationDestination(
                  icon: _navIcon('market', Icons.storefront), label: tr('Market')),
              NavigationDestination(
                  icon: _navIcon('guild', Icons.shield_outlined), label: tr('Guild')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icona della barra in basso: l'illustrazione di Antigravity se c'è.
Widget _navIcon(String id, IconData fallback) {
  final path = 'assets/art/nav/$id.png';
  return Art.has(path) ? Image.asset(path, width: 28, height: 28) : Icon(fallback);
}

/// Training: l'allenamento e l'Arena, scelti in alto come Mercante e
/// Fattucchiera nel Mercato.
class _TrainingSection extends StatelessWidget {
  const _TrainingSection({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: OathBar(
          title: Text(tr('Training').toUpperCase()),
          accent: Sections.training,
          bottom: TabBar(
            onTap: (i) {
              Sound.play(Sfx.tab);
              Sound.music(i == 0 ? Music.training : Music.arena);
              if (i == 1) maybeShowHint(context, 'arena');
            },
            tabs: [Tab(text: tr('Allenamento')), Tab(text: tr('Arena'))],
          ),
        ),
        body: TabBarView(
          children: [TrainTab(onNavigate: onNavigate), const ArenaTab()],
        ),
      ),
    );
  }
}
