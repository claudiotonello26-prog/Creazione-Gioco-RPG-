import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../widgets/common.dart';
import '../widgets/trainer.dart';
import 'training_screen.dart';

/// Esercizio di un sentiero: è un [Move].
typedef PathExercise = Move;

/// Sentieri a corpo libero: nessun attrezzo, si fanno ovunque.
const Map<MuscleGroup, List<PathExercise>> bodyweightPaths = {
  MuscleGroup.push: [
    PathExercise('Push-up', ExerciseId.pushUp),
    PathExercise('Push-up larghi', ExerciseId.pushUp),
    PathExercise('Pike push-up', ExerciseId.pushUp, ratio: 0.4),
    PathExercise('Diamond push-up', ExerciseId.pushUp, ratio: 0.4),
  ],
  MuscleGroup.stretching: [
    PathExercise('Piegamento in avanti', ExerciseId.stretch),
    PathExercise('Affondo statico', ExerciseId.stretch),
    PathExercise('Farfalla', ExerciseId.stretch),
    PathExercise('Cobra', ExerciseId.stretch),
  ],
  MuscleGroup.core: [
    PathExercise('Crunch', ExerciseId.crunch),
    PathExercise('Leg raise', ExerciseId.legRaise),
    PathExercise('Plank', ExerciseId.plank),
    PathExercise('V-up', ExerciseId.legRaise, ratio: 0.4),
  ],
  MuscleGroup.legs: [
    PathExercise('Squat', ExerciseId.squat),
    PathExercise('Affondi', ExerciseId.lunge),
    PathExercise('Ponte per glutei', ExerciseId.squat, ratio: 0.6),
    PathExercise('Jump squat', ExerciseId.squat, ratio: 0.35),
  ],
  MuscleGroup.cardio: [
    PathExercise('Jumping jack', ExerciseId.jumpingJack),
    PathExercise('High knees', ExerciseId.highKnees, ratio: 0.6),
    PathExercise('Mountain climber', ExerciseId.jumpingJack, ratio: 0.5),
    PathExercise('Burpee', ExerciseId.squat, ratio: 0.25),
  ],
};

/// Sentieri Zavorrati: sedia, zaino o manubri, per chi vuole di più.
const Map<MuscleGroup, List<PathExercise>> weightedPaths = {
  MuscleGroup.push: [
    PathExercise('Dip su sedia', ExerciseId.pushUp),
    PathExercise('Push-up con zaino', ExerciseId.pushUp, ratio: 0.4),
    PathExercise('Pike push-up piedi sulla sedia', ExerciseId.pushUp, ratio: 0.35),
    PathExercise('Floor press con manubri', ExerciseId.pushUp),
  ],
  MuscleGroup.stretching: [
    PathExercise('Posizione del piccione', ExerciseId.stretch),
    PathExercise('Posizione del bambino', ExerciseId.stretch),
    PathExercise('Torsione da seduto', ExerciseId.stretch),
    PathExercise('Piegamento in avanti a gambe larghe', ExerciseId.stretch),
  ],
  MuscleGroup.core: [
    PathExercise('Crunch con manubrio', ExerciseId.crunch, ratio: 0.45),
    PathExercise('Leg raise con pesi alle caviglie', ExerciseId.legRaise, ratio: 0.4),
    PathExercise('Plank zavorrato', ExerciseId.plank),
    PathExercise('Russian twist con manubrio', ExerciseId.crunch),
  ],
  MuscleGroup.legs: [
    PathExercise('Squat bulgaro sulla sedia', ExerciseId.lunge),
    PathExercise('Goblet squat con manubrio', ExerciseId.squat),
    PathExercise('Affondi con manubri', ExerciseId.lunge, ratio: 0.45),
    PathExercise('Step-up sulla sedia', ExerciseId.lunge),
  ],
  MuscleGroup.cardio: [
    PathExercise('Burpee con zaino', ExerciseId.squat, ratio: 0.2),
    PathExercise('Jumping jack con zaino', ExerciseId.jumpingJack, ratio: 0.45),
    PathExercise('Thruster con manubri', ExerciseId.squat, ratio: 0.35),
    PathExercise('Squat jump con zaino', ExerciseId.squat, ratio: 0.3),
  ],
};

/// Nome del guardiano in cima a ogni sentiero.
const Map<MuscleGroup, String> pathBosses = {
  MuscleGroup.push: 'Il Muro di Ferro',
  MuscleGroup.stretching: 'Il Monaco Contorto',
  MuscleGroup.core: 'Il Nodo di Serpi',
  MuscleGroup.legs: 'Il Colosso delle Paludi',
  MuscleGroup.cardio: 'Il Corridore Cinereo',
};

const int bossSeconds = 30;

/// Il sentiero di un gruppo muscolare disegnato come una mappa: quattro
/// tappe e il boss in cima. Si sale una tappa alla volta.
class PathScreen extends StatefulWidget {
  const PathScreen({super.key, required this.group});
  final MuscleGroup group;

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  bool _weighted = false;

  @override
  void initState() {
    super.initState();
    maybeShowHint(context, 'path');
  }

  bool get _stretch => widget.group == MuscleGroup.stretching;

  List<PathExercise> get _steps => (_weighted ? weightedPaths : bodyweightPaths)[widget.group]!;

  int _target(GameState s, PathExercise e) =>
      (s.testRepsFor(e.trackAs) * e.ratio).round().clamp(3, 999);

  Future<void> _run(PathExercise e, int index) async {
    final s = context.read<GameState>();
    final result = await Navigator.of(context).push<SetResult>(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          exercise: e.trackAs,
          title: tr(e.name),
          subtitle: tr('Tappa {n} del sentiero', {'n': index + 1}),
          target: e.hold ? null : _target(s, e),
          timeLimit: e.hold ? const Duration(seconds: 60) : null,
        ),
      ),
    );
    if (result == null || !mounted) return;
    final ok =
        e.hold ? result.held.inSeconds >= 20 : result.reps.length >= (_target(s, e) * 0.8).floor();
    if (result.reps.isNotEmpty) {
      s.addTraining(
        e.trackAs,
        result.reps,
        countsForQuest: false,
        name: e.name,
        difficulty: s.usualDifficulty(e.trackAs) / e.ratio,
        pathGroup: widget.group,
      );
    }
    if (e.trackAs == ExerciseId.plank) {
      s.recordBest(
        ExerciseId.plank,
        result.held.inSeconds,
        name: e.name,
        difficulty: _weighted ? 1.5 : 1,
        group: widget.group,
      );
    }
    if (ok) {
      s.completePathStep(widget.group, index);
      toast(context, index == 3 ? tr('Il guardiano ti aspetta in cima.') : tr('Tappa superata.'));
    } else {
      toast(context, tr('Quasi: riprova la tappa.'));
    }
  }

  /// Boss: circuito di tutti gli esercizi, 30 secondi ciascuno a sfinimento.
  /// Il bottino arriva a circuito finito, qualunque sia il numero di rep.
  Future<void> _boss() async {
    final s = context.read<GameState>();
    final steps = _steps;
    for (var i = 0; i < steps.length; i++) {
      final e = steps[i];
      final r = await Navigator.of(context).push<SetResult>(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            exercise: e.trackAs,
            title: tr(e.name),
            subtitle: tr('{boss} · esercizio {i}/{n} · {sec} secondi a sfinimento', {
              'boss': tr(pathBosses[widget.group]!),
              'i': i + 1,
              'n': steps.length,
              'sec': bossSeconds,
            }),
            timeLimit: const Duration(seconds: bossSeconds),
          ),
        ),
      );
      if (!mounted) return;
      if (r == null) {
        toast(context, tr('Il guardiano resta in piedi. Riprova quando vuoi.'));
        return;
      }
      if (r.reps.isNotEmpty) {
        s.addTraining(
          e.trackAs,
          r.reps,
          countsForQuest: false,
          name: e.name,
          difficulty: s.usualDifficulty(e.trackAs) / e.ratio,
          pathGroup: widget.group,
        );
      }
    }
    final loot = s.bossLoot(widget.group, weighted: _weighted);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Text(
          tr('GUARDIANO ABBATTUTO'),
          textAlign: TextAlign.center,
          style: titleStyle(size: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('{boss} è caduto.', {'boss': tr(pathBosses[widget.group]!)})),
            const SizedBox(height: 8),
            for (final e in loot.entries)
              Text(
                '+${e.value} ${materialNames[e.key] ?? e.key}',
                style: TextStyle(
                  color: const {
                    'ancient_stone',
                    'somber_stone',
                    'somber_stone_2',
                    'somber_stone_3',
                    'somber_stone_4',
                    'epic_stone',
                    'holy_shard',
                  }.contains(e.key)
                      ? Palette.goldBright
                      : Palette.holy,
                ),
              ),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('CONTINUA')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final progress = s.pathProgress(widget.group);
    final steps = _steps;
    return Scaffold(
      appBar: OathBar(title: Text(widget.group.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OathChoice<bool>(
            options: [
              (false, _stretch ? tr('Base') : tr('Corpo libero')),
              (true, _stretch ? tr('Profondo') : tr('Zavorrato')),
            ],
            selected: _weighted,
            onChanged: (v) => setState(() => _weighted = v),
          ),
          const SizedBox(height: 6),
          Text(
            _stretch
                ? (_weighted
                    ? tr('Pose più profonde. Il guardiano lascia il doppio del bottino.')
                    : tr('Tieni ogni posa: conta restare fermi, non quanto arrivi giù.'))
                : _weighted
                    ? tr('Con sedia, zaino o manubri. Il guardiano lascia il doppio del bottino.')
                    : tr('Nessun attrezzo: solo il tuo corpo.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash, fontSize: 15),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              const h = 620.0;
              // Dal basso verso l'alto, a serpentina.
              final xs = [0.25, 0.72, 0.28, 0.7, 0.5];
              final ys = [0.86, 0.68, 0.5, 0.32, 0.1];
              final points = [for (var i = 0; i < 5; i++) Offset(xs[i] * w, ys[i] * h)];
              return SizedBox(
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _TrailPainter(points, progress))),
                    for (var i = 0; i < 5; i++)
                      Positioned(
                        left: points[i].dx - 70,
                        top: points[i].dy - 38,
                        width: 140,
                        child: _Node(
                          index: i,
                          boss: i == 4,
                          state: i < progress
                              ? _NodeState.done
                              : (i == progress ? _NodeState.open : _NodeState.locked),
                          title: tr(i == 4 ? pathBosses[widget.group]! : steps[i].name),
                          subtitle: i == 4
                              ? tr('Circuito {n}×{sec} s', {'n': steps.length, 'sec': bossSeconds})
                              : (steps[i].hold
                                  ? tr('Tieni 20 s')
                                  : tr('{n} rep', {'n': _target(s, steps[i])})),
                          onTap: i != progress ? null : (i == 4 ? _boss : () => _run(steps[i], i)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (progress >= 5)
            Text(
              tr('Sentiero completato oggi. Domani il guardiano torna più affamato.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.goldBright),
            ),
        ],
      ),
    );
  }
}

enum _NodeState { done, open, locked }

class _Node extends StatelessWidget {
  const _Node({
    required this.index,
    required this.boss,
    required this.state,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int index;
  final bool boss;
  final _NodeState state;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final open = state == _NodeState.open;
    final size = boss ? 76.0 : 60.0;
    final color = switch (state) {
      _NodeState.done => Palette.goldBright,
      _NodeState.open => boss ? Palette.blood : Palette.gold,
      _NodeState.locked => Palette.iron,
    };
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state == _NodeState.done ? Palette.gold : Palette.stone,
              border: Border.all(color: color, width: open ? 3 : 2),
              boxShadow:
                  open ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 18)] : null,
            ),
            child: Center(
              child: switch (state) {
                _NodeState.done => const Icon(Icons.check, color: Palette.night, size: 30),
                _NodeState.locked => Icon(
                    boss ? Icons.castle : Icons.lock_outline,
                    color: Palette.iron,
                    size: boss ? 34 : 24,
                  ),
                _NodeState.open => boss
                    ? const Icon(Icons.castle, color: Palette.holy, size: 36)
                    : Text('${index + 1}', style: titleStyle(size: 24, color: Palette.holy)),
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: state == _NodeState.locked ? Palette.ash : Palette.holy,
              fontWeight: open ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Palette.ash, fontSize: 15)),
        ],
      ),
    );
  }
}

/// Sentiero tratteggiato tra le tappe: oro dove sei già passato.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.progress);
  final List<Offset> points;
  final int progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final mid = Offset((a.dx + b.dx) / 2 + (i.isEven ? 30 : -30), (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final paint = Paint()
        ..color = i < progress ? Palette.gold : Palette.iron
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 18) {
          canvas.drawPath(m.extractPath(d, min(d + 9, m.length)), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.progress != progress;
}
