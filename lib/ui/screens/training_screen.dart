import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/exercise.dart';
import '../../pose/rep_counter.dart';
import '../../pose/rep_input.dart';
import '../widgets/exercise_demo.dart';
import '../widgets/exercise_view.dart';

/// Esito di una serie.
class SetResult {
  const SetResult(this.reps, this.held, this.elapsed);
  final List<RepQuality> reps;
  final Duration held;
  final Duration elapsed;
}

/// Una serie di un esercizio: conta le rep con la fotocamera e si chiude da
/// sola al raggiungimento del target o allo scadere del tempo.
class TrainingScreen extends StatefulWidget {
  const TrainingScreen({
    super.key,
    required this.exercise,
    required this.title,
    this.target,
    this.timeLimit,
    this.subtitle,
  });

  final ExerciseId exercise;
  final String title;
  final String? subtitle;
  final int? target;
  final Duration? timeLimit;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late final RepInput _input;
  final List<RepQuality> _reps = [];
  StreamSubscription<RepEvent>? _sub;
  final _watch = Stopwatch();
  Timer? _ticker;
  bool _finished = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _input = createRepInput(context.read<GameState>().useCamera, widget.exercise);
    _input.start();
    _sub = _input.reps.listen(_onRep);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_countdown > 0) {
      setState(() => _countdown--);
      if (_countdown == 0) _watch.start();
      return;
    }
    final limit = widget.timeLimit;
    if (limit != null && _watch.elapsed >= limit) {
      _finish();
    } else {
      setState(() {});
    }
  }

  void _onRep(RepEvent e) {
    if (_countdown > 0 || _finished) return;
    setState(() => _reps.add(e.quality));
    final t = widget.target;
    if (t != null && _countReps >= t) _finish();
  }

  /// Per gli affondi il target è per gamba: contano le coppie.
  int get _countReps => exercises[widget.exercise]!.perLeg ? _reps.length ~/ 2 : _reps.length;

  void _finish() {
    if (_finished) return;
    _finished = true;
    _watch.stop();
    final perLeg = exercises[widget.exercise]!.perLeg;
    final reps = perLeg ? [for (var i = 0; i + 1 < _reps.length; i += 2) _reps[i]] : List.of(_reps);
    Navigator.of(context).pop(SetResult(reps, _input.held, _watch.elapsed));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perLeg = exercises[widget.exercise]!.perLeg;
    final limit = widget.timeLimit;
    final remaining = limit == null ? null : (limit - _watch.elapsed).inSeconds.clamp(0, 9999);
    final counterText = _input.isHold
        ? '${_input.held.inSeconds}s'
        : (widget.target != null ? '$_countReps/${widget.target}' : '$_countReps');

    return Scaffold(
      appBar: OathBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash),
              ),
            ),
          Expanded(
            child: ExerciseView(
              input: _input,
              overlay: Positioned.fill(
                child: Stack(
                  children: [
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _countdown > 0
                            ? RepCounterBadge(text: '$_countdown', caption: 'Preparati')
                            : ListenableBuilder(
                                listenable: _input,
                                builder: (_, _) => RepCounterBadge(
                                  text: _input.isHold ? '${_input.held.inSeconds}s' : counterText,
                                  caption: [
                                    if (perLeg) 'per gamba',
                                    if (remaining != null) '$remaining s',
                                  ].join(' · '),
                                ),
                              ),
                      ),
                    ),
                    // Come si fa l'esercizio: due pose in loop.
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: ExerciseDemo(move: demoFor(widget.title, widget.exercise)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_reps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                'Perfette ${_reps.where((r) => r == RepQuality.perfect).length} · '
                'Buone ${_reps.where((r) => r == RepQuality.good).length} · '
                'Scarse ${_reps.where((r) => r == RepQuality.poor).length}',
                style: const TextStyle(color: Palette.ash),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _finish, child: const Text('TERMINA SERIE')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
