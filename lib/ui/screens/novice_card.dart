import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/enemies.dart';
import '../../domain/items.dart';
import '../../domain/novice.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import '../widgets/trainer.dart';
import 'forge_tab.dart';
import 'quest_screen.dart';
import 'train_tab.dart';

/// Il Cammino del Novizio: una missione alla volta. Toccandola Ser Corvino
/// spiega cosa fare e poi porta dritto dove si fa.
class NoviceCard extends StatelessWidget {
  const NoviceCard({super.key, required this.onNavigate});

  /// Cambia scheda in basso (0 = Home, 1 = Training, 2 = Raccolta, 4 = Mercato).
  final void Function(int tab) onNavigate;

  Future<void> _claim(BuildContext context, GameState state) async {
    final done = state.claimNovice();
    if (done == null) return;
    final next = state.noviceQuest;
    await showTrainer(context, [
      TrainerLine(
        TrainerPose.cheering,
        tr('Missione "{title}" compiuta! {loot}.', {
          'title': done.title,
          'loot': [
            if (done.runes > 0) tr('+{n} rune', {'n': done.runes}),
            for (final e in done.loot.entries) '+${e.value} ${materialNames[e.key]}',
          ].join(', '),
        }),
      ),
      if (next != null)
        TrainerLine(TrainerPose.pointing, next.trainer)
      else
        TrainerLine(TrainerPose.crossed,
            tr('Il Cammino del Novizio è finito. Non sei più un novizio. Sei... appena accettabile. Continua così.')),
    ]);
  }

  Future<void> _go(BuildContext context, GameState state, NoviceQuest q) async {
    await showTrainer(context, [TrainerLine(TrainerPose.pointing, q.trainer)]);
    if (!context.mounted) return;
    goToNoviceAction(context, state, q, onNavigate);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final q = state.noviceQuest;
    if (q == null) return const SizedBox.shrink();
    final have = state.stat(q.stat).clamp(0, q.target);
    final ready = state.noviceReady;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: ready ? Palette.goldBright : Palette.gold, width: ready ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => ready ? _claim(context, state) : _go(context, state, q),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const TrainerFigure(pose: TrainerPose.pointing, height: 84),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('CAMMINO DEL NOVIZIO · {n}/{total}', {'n': state.noviceStep + 1, 'total': noviceQuests.length}),
                        style: titleStyle(size: 11, color: Palette.gold, spacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(q.title, style: titleStyle(size: 17, color: Palette.holy, spacing: 0.5)),
                    Text(q.goal, style: const TextStyle(color: Palette.ash, fontSize: 13)),
                    const SizedBox(height: 6),
                    StatBar(value: have / q.target, color: Palette.gold, label: '$have / ${q.target}'),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ready
                          ? FilledButton(
                              onPressed: () => _claim(context, state),
                              child: Text(tr('RISCUOTI')))
                          : OutlinedButton.icon(
                              onPressed: () => _go(context, state, q),
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: Text(tr('VAI')),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Porta il giocatore dove si fa la missione.
void goToNoviceAction(
    BuildContext context, GameState state, NoviceQuest q, void Function(int tab) onNavigate) {
  void push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  switch (q.action) {
    case NoviceAction.fightGoblin:
      startFreeFight(context, enemyDefs['hollow_goblin']!, respawn: true);
    case NoviceAction.hunt:
      startFreeFight(context, enemyDefs['hollow_goblin']!, endless: true);
    case NoviceAction.dailyQuest:
      push(const QuestScreen());
    case NoviceAction.walk:
      final r = q.gather == null ? null : resourceById(q.gather!);
      if (r != null && state.canGather(r)) state.setGatherTarget(r.id);
      onNavigate(2);
    case NoviceAction.carpentry:
      push(const StationScreen(station: Station.carpentry));
    case NoviceAction.furnace:
      push(const StationScreen(station: Station.furnace));
    case NoviceAction.anvil:
      push(const StationScreen(station: Station.anvil));
    case NoviceAction.enchant:
      push(const StationScreen(station: Station.enchant));
    case NoviceAction.market:
      onNavigate(4);
    case NoviceAction.training:
      onNavigate(1);
    case NoviceAction.attributes:
      onNavigate(0);
  }
}
