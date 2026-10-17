import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import '../widgets/trainer.dart';
import 'combat_screen.dart';
import 'novice_card.dart';
import 'path_screen.dart';
import 'quest_screen.dart';

class TrainTab extends StatelessWidget {
  const TrainTab({super.key, this.onNavigate});
  final void Function(int tab)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final plan = weeklyPlan(s.daysPerWeek);
    final trainedThisWeek = s.trainedGroups.values.expand((g) => g).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onNavigate != null) NoviceCard(onNavigate: onNavigate!),
        ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Quest giornaliera',
          subtitle: '${(s.questProgress * 100).round()}% completata',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const QuestScreen())),
        ),
        const SectionTitle('Sentieri di allenamento'),
        const Text(
          'Scegli un gruppo muscolare: quattro tappe a corpo libero e un guardiano in cima.',
          style: TextStyle(color: Palette.ash, fontSize: 13),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            for (final g in bodyweightPaths.keys)
              _PathCard(
                group: g,
                progress: s.pathProgress(g),
                trainedThisWeek: trainedThisWeek.contains(g),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => PathScreen(group: g))),
              ),
          ],
        ),
        Text(
          'Piano per ${s.daysPerWeek} giorni: ${plan.map((d) => d.map((g) => g.label).join(' + ')).join(' · ')}',
          style: const TextStyle(color: Palette.ash, fontSize: 12),
        ),
        const SectionTitle('Spedizioni'),
        for (final e in expeditions.values)
          ActionTile(
            icon: Icons.explore_outlined,
            title: e.name,
            subtitle: 'Gruppo ${e.group.label} · 4 nemici e un boss · serve una chiave',
            enabled: s.expeditionKeys > 0 && !s.daily.expeditionDone,
            onTap: () => _startExpedition(context, e),
          ),
        if (s.daily.expeditionDone)
          const Text('Una spedizione al giorno: torna domani.',
              style: TextStyle(color: Palette.ash)),
        const SectionTitle('Caccia infinita'),
        ActionTile(
          icon: Icons.all_inclusive,
          title: 'Caccia nelle Cattedrali',
          subtitle: 'Ogni nemico abbattuto ne arriva uno più forte, finché resisti'
              '${s.bestHuntWave > 0 ? ' · record ${s.bestHuntWave}' : ''}',
          color: Palette.ember,
          onTap: () => startFreeFight(context, enemyDefs['hollow_goblin']!, endless: true),
        ),
        const SectionTitle('Combattimenti liberi'),
        for (final e in enemyDefs.values.where((e) => e.region == regionCathedral))
          ActionTile(
            icon: Icons.whatshot,
            title: e.name,
            subtitle: 'Gradino ${e.tier} · ${e.exercises.map((x) => exercises[x]!.name).join(' o ')}'
                '${e.weakTo != null ? ' · debole a ${e.weakTo!.label.toLowerCase()}' : ''}',
            onTap: () => startFreeFight(context, e),
          ),
      ],
    );
  }

  Future<void> _startExpedition(BuildContext context, Expedition e) async {
    final s = context.read<GameState>();
    if (!s.useExpeditionKey()) {
      toast(context, 'Serve una Chiave della Spedizione (completa la quest).');
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ExpeditionScreen(expedition: e)));
  }
}

/// Un combattimento libero: si sceglie l'esercizio del mostro e la postura.
Future<void> startFreeFight(BuildContext context, EnemyDef enemy, {bool endless = false}) async {
  final st = context.read<GameState>();
  if (endless && st.trainerEnabled && st.markHint('hunt')) {
    await showTrainer(context, trainerHints['hunt']!);
    if (!context.mounted) return;
  }
  final choice = await showModalBottomSheet<(ExerciseId, Stance)>(
    context: context,
    backgroundColor: Palette.stone,
    builder: (_) => _FightSetup(enemy: enemy),
  );
  if (choice == null || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => CombatScreen(
        enemy: enemy, exercise: choice.$1, stance: choice.$2, endless: endless),
  ));
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.group,
    required this.progress,
    required this.trainedThisWeek,
    required this.onTap,
  });
  final MuscleGroup group;
  final int progress;
  final bool trainedThisWeek;
  final VoidCallback onTap;

  static IconData iconFor(MuscleGroup g) => switch (g) {
        MuscleGroup.push => Icons.fitness_center,
        MuscleGroup.back => Icons.accessibility_new,
        MuscleGroup.core => Icons.adjust,
        MuscleGroup.legs => Icons.directions_walk,
        MuscleGroup.cardio => Icons.favorite,
        MuscleGroup.mobility => Icons.self_improvement,
      };

  @override
  Widget build(BuildContext context) {
    final done = progress >= 5;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconFor(group), color: done ? Palette.goldBright : Palette.gold),
                  const Spacer(),
                  Text(done ? 'FATTO' : '$progress/5',
                      style: TextStyle(color: done ? Palette.goldBright : Palette.ash, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text(group.label, style: titleStyle(size: 14)),
              Text(trainedThisWeek ? 'Allenato questa settimana' : 'Bonus Varietà attivo',
                  style: TextStyle(
                      color: trainedThisWeek ? Palette.ash : Palette.ember, fontSize: 11)),
              const SizedBox(height: 4),
              StatBar(value: progress / 5, color: Palette.gold, height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _FightSetup extends StatefulWidget {
  const _FightSetup({required this.enemy});
  final EnemyDef enemy;

  @override
  State<_FightSetup> createState() => _FightSetupState();
}

class _FightSetupState extends State<_FightSetup> {
  late ExerciseId _exercise = widget.enemy.exercises.first;
  Stance _stance = Stance.balanced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(widget.enemy.exercises.length > 1
              ? '${widget.enemy.name}: scegli l\'esercizio'
              : '${widget.enemy.name} si batte con'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in widget.enemy.exercises)
                ChoiceChip(
                  label: Text(exercises[id]!.name),
                  selected: _exercise == id,
                  onSelected: (_) => setState(() => _exercise = id),
                ),
            ],
          ),
          const SectionTitle('Postura'),
          SegmentedButton<Stance>(
            segments: [
              for (final st in Stance.values) ButtonSegment(value: st, label: Text(st.label)),
            ],
            selected: {_stance},
            onSelectionChanged: (v) => setState(() => _stance = v.first),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_stance) {
              Stance.aggressive =>
                'Colpi più penetranti, ma subisci più danni. Ogni rep fa salire Attacco.',
              Stance.balanced => 'Nessun vantaggio né svantaggio. Le rep vanno metà ad Attacco, metà a Difesa.',
              Stance.defensive =>
                'Subisci un quarto di danni in meno, colpi meno penetranti. Ogni rep fa salire Difesa.',
            },
            style: const TextStyle(color: Palette.ash),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((_exercise, _stance)),
            child: const Text('COMBATTI'),
          ),
        ],
      ),
    );
  }
}

/// Spedizione: quattro tappe con esercizi fissi e un boss finale.
class ExpeditionScreen extends StatefulWidget {
  const ExpeditionScreen({super.key, required this.expedition});
  final Expedition expedition;

  @override
  State<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends State<ExpeditionScreen> {
  int _stage = 0;
  bool _failed = false;

  Future<void> _fight() async {
    final stage = widget.expedition.stages[_stage];
    final enemy = enemyDefs[stage.enemyId]!;
    final exercise = stage.exercises[_stage == widget.expedition.stages.length - 1
        ? DateTime.now().second % stage.exercises.length
        : 0];
    final label = widget.expedition.id == 'penitent_keep'
        ? pushStageExerciseLabel[stage.enemyId]
        : null;
    final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CombatScreen(enemy: enemy, exercise: exercise, exerciseLabel: label),
    ));
    if (!mounted) return;
    setState(() {
      if (won == true) {
        _stage++;
      } else {
        _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expedition;
    final done = _stage >= e.stages.length;
    return Scaffold(
      appBar: AppBar(title: Text(e.name.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < e.stages.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < _stage ? Palette.gold : Palette.iron,
                  foregroundColor: Palette.night,
                  child: Text(i == e.stages.length - 1 ? 'B' : '${i + 1}'),
                ),
                title: Text(enemyDefs[e.stages[i].enemyId]!.name),
                subtitle: Text(
                  e.id == 'penitent_keep'
                      ? pushStageExerciseLabel[e.stages[i].enemyId]!
                      : e.stages[i].exercises.map((x) => exercises[x]!.name).join(' / '),
                  style: const TextStyle(color: Palette.ash),
                ),
                trailing: i < _stage ? const Icon(Icons.check, color: Palette.goldBright) : null,
              ),
            ),
          const SizedBox(height: 16),
          if (done)
            const Text('Spedizione completata. Il boss è caduto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.goldBright, fontSize: 18))
          else if (_failed)
            Column(
              children: [
                const Text('Sei caduto. Il bottino raccolto resta tuo.',
                    style: TextStyle(color: Palette.ash)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _failed = false),
                  child: const Text('Riprova la tappa'),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: _fight,
              child: Text(_stage == e.stages.length - 1 ? 'AFFRONTA IL BOSS' : 'AFFRONTA LA TAPPA ${_stage + 1}'),
            ),
        ],
      ),
    );
  }
}
