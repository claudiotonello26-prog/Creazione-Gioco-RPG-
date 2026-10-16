import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import 'combat_screen.dart';
import 'quest_screen.dart';
import 'training_screen.dart';

/// Esercizio di una sfida: [trackAs] è il modello di movimento usato dal
/// contatore (es. tutti i push-up usano l'angolo del gomito).
class ChallengeExercise {
  const ChallengeExercise(this.name, this.trackAs, {this.advanced = false, this.ratio = 0.5});
  final String name;
  final ExerciseId trackAs;
  final bool advanced;
  final double ratio;
}

const Map<MuscleGroup, List<ChallengeExercise>> muscleChallenges = {
  MuscleGroup.push: [
    ChallengeExercise('Push-up', ExerciseId.pushUp),
    ChallengeExercise('Push-up larghi', ExerciseId.pushUp),
    ChallengeExercise('Dip su sedia', ExerciseId.pushUp),
    ChallengeExercise('Pike push-up', ExerciseId.pushUp, ratio: 0.4),
    ChallengeExercise('Diamond push-up', ExerciseId.pushUp, advanced: true, ratio: 0.4),
    ChallengeExercise('Archer push-up', ExerciseId.pushUp, advanced: true, ratio: 0.3),
    ChallengeExercise('Push-up esplosivi', ExerciseId.pushUp, advanced: true, ratio: 0.35),
  ],
  MuscleGroup.back: [
    ChallengeExercise('Superman', ExerciseId.legRaise, ratio: 0.8),
    ChallengeExercise('Rematore sotto il tavolo', ExerciseId.pushUp, ratio: 0.6),
    ChallengeExercise('Plank con tocco spalle', ExerciseId.plank),
    ChallengeExercise('Rematore a un braccio', ExerciseId.pushUp, advanced: true, ratio: 0.4),
  ],
  MuscleGroup.core: [
    ChallengeExercise('Crunch', ExerciseId.crunch),
    ChallengeExercise('Leg raise', ExerciseId.legRaise),
    ChallengeExercise('Plank', ExerciseId.plank),
    ChallengeExercise('V-up', ExerciseId.legRaise, advanced: true, ratio: 0.4),
    ChallengeExercise('Leg raise completi', ExerciseId.legRaise, advanced: true, ratio: 0.6),
  ],
  MuscleGroup.legs: [
    ChallengeExercise('Squat', ExerciseId.squat),
    ChallengeExercise('Affondi', ExerciseId.lunge),
    ChallengeExercise('Ponte per glutei', ExerciseId.squat, ratio: 0.6),
    ChallengeExercise('Jump squat', ExerciseId.squat, advanced: true, ratio: 0.35),
    ChallengeExercise('Squat bulgaro', ExerciseId.lunge, advanced: true, ratio: 0.5),
  ],
  MuscleGroup.cardio: [
    ChallengeExercise('Jumping jack', ExerciseId.jumpingJack),
    ChallengeExercise('High knees', ExerciseId.jumpingJack, ratio: 0.6),
    ChallengeExercise('Burpee completi', ExerciseId.squat, advanced: true, ratio: 0.25),
  ],
};

class TrainTab extends StatelessWidget {
  const TrainTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final plan = weeklyPlan(s.daysPerWeek);
    final trainedThisWeek = s.trainedGroups.values.expand((g) => g).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Quest giornaliera',
          subtitle: '${(s.questProgress * 100).round()}% completata',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const QuestScreen())),
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
        const SectionTitle('Sfide per gruppo muscolare'),
        Text(
          'Piano per ${s.daysPerWeek} giorni: ${plan.map((d) => d.map((g) => g.label).join(' + ')).join(' · ')}',
          style: const TextStyle(color: Palette.ash, fontSize: 13),
        ),
        const SizedBox(height: 6),
        for (final g in muscleChallenges.keys)
          ActionTile(
            icon: Icons.bolt,
            title: g.label,
            subtitle: trainedThisWeek.contains(g)
                ? 'Allenato questa settimana'
                : 'Non ancora allenato questa settimana · Bonus Varietà attivo',
            color: trainedThisWeek.contains(g) ? Palette.gold : Palette.ember,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChallengeScreen(group: g))),
          ),
        const SectionTitle('Combattimenti liberi'),
        for (final e in enemyDefs.values.where((e) => e.region == regionCathedral))
          ActionTile(
            icon: Icons.whatshot,
            title: e.name,
            subtitle: 'Gradino ${e.tier}'
                '${e.weakTo != null ? ' · debole a ${e.weakTo!.label.toLowerCase()}' : ''}',
            onTap: () => _freeFight(context, e),
          ),
      ],
    );
  }

  Future<void> _freeFight(BuildContext context, EnemyDef enemy) async {
    final choice = await showModalBottomSheet<(ExerciseId, Stance)>(
      context: context,
      backgroundColor: Palette.stone,
      builder: (_) => const _FightSetup(),
    );
    if (choice == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CombatScreen(enemy: enemy, exercise: choice.$1, stance: choice.$2),
    ));
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

class _FightSetup extends StatefulWidget {
  const _FightSetup();

  @override
  State<_FightSetup> createState() => _FightSetupState();
}

class _FightSetupState extends State<_FightSetup> {
  ExerciseId _exercise = ExerciseId.pushUp;
  Stance _stance = Stance.balanced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Scegli l\'esercizio'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in baseExercises)
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
              Stance.aggressive => 'Colpi più penetranti, ma subisci più danni.',
              Stance.balanced => 'Nessun vantaggio né svantaggio.',
              Stance.defensive => 'Subisci un quarto di danni in meno, colpi meno penetranti.',
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

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, required this.group});
  final MuscleGroup group;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  bool _advanced = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final list = muscleChallenges[widget.group]!.where((c) => c.advanced == _advanced).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _advanced,
            onChanged: (v) => setState(() => _advanced = v),
            title: const Text('Livello avanzato'),
            subtitle: const Text('Versioni più dure e più volume',
                style: TextStyle(color: Palette.ash)),
          ),
          if (widget.group == MuscleGroup.back)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'La sfida Dorso bilancia la spinta della quest e protegge la postura.',
                style: TextStyle(color: Palette.ash),
              ),
            ),
          for (final c in list)
            ActionTile(
              icon: Icons.fitness_center,
              title: c.name,
              subtitle: c.trackAs == ExerciseId.plank
                  ? 'Tieni la posizione'
                  : '${_target(s, c)} rep',
              onTap: () => _run(context, c),
            ),
        ],
      ),
    );
  }

  int _target(GameState s, ChallengeExercise c) {
    final base = s.testRepsFor(c.trackAs) * c.ratio * (_advanced ? 1.2 : 1.0);
    return base.round().clamp(3, 999);
  }

  Future<void> _run(BuildContext context, ChallengeExercise c) async {
    final s = context.read<GameState>();
    final hold = c.trackAs == ExerciseId.plank;
    final result = await Navigator.of(context).push<SetResult>(MaterialPageRoute(
      builder: (_) => TrainingScreen(
        exercise: c.trackAs,
        title: c.name,
        target: hold ? null : _target(s, c),
        timeLimit: hold ? const Duration(minutes: 3) : null,
      ),
    ));
    if (result == null || !context.mounted) return;
    if (hold) {
      s.recordBest(ExerciseId.plank, result.held.inSeconds);
      toast(context, 'Tenuto ${result.held.inSeconds} secondi');
      return;
    }
    final xp = s.addTraining(c.trackAs, result.reps, countsForQuest: false);
    toast(context, '+$xp XP');
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
