import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../widgets/common.dart';
import 'onboarding.dart';
import 'quest_screen.dart';
import 'walk_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});
  final void Function(int tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final (xpIn, xpNeed) = c.levelProgress;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.gold, width: 2),
                    color: Palette.stoneLight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset('assets/images/helm.png'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Palette.goldBright,
                        ),
                      ),
                      Text(
                        'Livello ${c.level} · ${c.weapon.displayName}',
                        style: const TextStyle(color: Palette.ash),
                      ),
                      const SizedBox(height: 6),
                      StatBar(
                        value: xpIn / xpNeed,
                        color: Palette.gold,
                        label: '$xpIn / $xpNeed XP',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoChip(
              Icons.local_fire_department,
              'Streak ${s.streak}',
              color: Palette.ember,
            ),
            InfoChip(Icons.diamond_outlined, '${c.runes} rune'),
            InfoChip(Icons.vpn_key_outlined, '${s.expeditionKeys} chiavi'),
            if (c.availablePoints > 0)
              InfoChip(
                Icons.add_circle_outline,
                '${c.availablePoints} punti da spendere',
                color: Palette.goldBright,
              ),
          ],
        ),
        if (s.retestDue) ...[
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.emoji_events_outlined,
            title: 'Torneo della Prova',
            subtitle: 'Sono passate 4 settimane: rifai il test e guarda quanto sei migliorato.',
            color: Palette.goldBright,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FitnessTestScreen(isRetest: true),
              ),
            ),
          ),
        ],
        SectionTitle(
          'Quest giornaliera',
          trailing: Text(
            '${(s.questProgress * 100).round()}%',
            style: const TextStyle(color: Palette.ash),
          ),
        ),
        if (s.mode == PlayMode.free)
          const Text(
            'Sei in modalità Libera: la quest è facoltativa ma dà la Chiave della Spedizione.',
            style: TextStyle(color: Palette.ash),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatBar(
                  value: s.questProgress,
                  color: Palette.gold,
                  height: 12,
                ),
                const SizedBox(height: 10),
                for (final q in s.quest)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          s.questDoneFor(q.exercise) >= q.target
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: s.questDoneFor(q.exercise) >= q.target
                              ? Palette.goldBright
                              : Palette.ash,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(q.label)),
                        Text(
                          '${s.questDoneFor(q.exercise).clamp(0, q.target)}/${q.target}'
                          '${q.info.perLeg ? ' per gamba' : ''}',
                          style: const TextStyle(color: Palette.ash),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Icon(
                      s.daily.stretchingDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: s.daily.stretchingDone
                          ? Palette.goldBright
                          : Palette.ash,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Stretching guidato (5 min)')),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuestScreen()),
                  ),
                  child: Text(
                    s.questComplete ? 'QUEST COMPLETATA' : 'CONTINUA LA QUEST',
                  ),
                ),
                if (s.questComplete)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Hai guadagnato una Chiave della Spedizione. Vai su Allenati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Palette.goldBright),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SectionTitle('Oggi'),
        ActionTile(
          icon: Icons.directions_walk,
          title: 'Camminata',
          subtitle: 'Collega i passi del telefono: diventano materiali da forgia',
          color: Palette.goldBright,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WalkScreen())),
        ),
        ActionTile(
          icon: Icons.explore_outlined,
          title: 'Spedizioni',
          subtitle: s.daily.expeditionDone
              ? 'Spedizione di oggi già fatta'
              : '${s.expeditionKeys} chiavi disponibili',
          onTap: () => onNavigate(1),
        ),
        ActionTile(
          icon: Icons.sports_kabaddi,
          title: 'Arena Pura',
          subtitle: '${s.seasonTitle} · ${s.arenaPoints} punti',
          onTap: () => onNavigate(3),
        ),
        ActionTile(
          icon: Icons.hardware,
          title: 'Forgia',
          subtitle: 'Potenzia ${c.weapon.displayName}',
          onTap: () => onNavigate(2),
        ),
      ],
    );
  }
}
