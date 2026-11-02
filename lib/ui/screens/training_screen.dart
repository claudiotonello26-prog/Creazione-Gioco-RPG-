import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
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
import '../../core/sound.dart';
import '../../core/art.dart';

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

  /// Esercizi per gamba: prima tutta la destra, poi CAMBIA GAMBA e la sinistra.
  bool get _perLeg => exercises[widget.exercise]!.perLeg;
  int _leg = 0;
  final List<List<RepQuality>> _legReps = [[], []];

  /// Secondi di pausa del cambio gamba (0 = non in pausa).
  int _switching = 0;

  @override
  void initState() {
    super.initState();
    _input = createRepInput(context.read<GameState>().useCamera, widget.exercise);
    _input.start();
    _sub = _input.reps.listen(_onRep);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_switching > 0) {
      setState(() => _switching--);
      return;
    }
    if (_countdown > 0) {
      setState(() => _countdown--);
      Sound.play(_countdown == 0 ? Sfx.countdownGo : Sfx.countdownTick);
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
    if (_countdown > 0 || _finished || _switching > 0) return;
    setState(() {
      _reps.add(e.quality);
      if (_perLeg) _legReps[_leg].add(e.quality);
    });
    Sound.play(switch (e.quality) {
      RepQuality.perfect => Sfx.repPerfect,
      RepQuality.good => Sfx.repGood,
      RepQuality.poor => Sfx.repPoor,
    });
    final t = widget.target;
    if (_perLeg && t != null && _legReps[_leg].length >= t) {
      _leg == 0 ? _switchLeg() : _finish();
    } else if (!_perLeg && t != null && _countReps >= t) {
      _finish();
    }
  }

  /// Fine della prima gamba: avviso grande, suono e vibrazione, 5 secondi
  /// per cambiare, poi si riparte da zero sull'altra.
  void _switchLeg() {
    if (_leg == 1) return;
    HapticFeedback.heavyImpact();
    if (Art.has(Sfx.switchLeg.path)) {
      Sound.play(Sfx.switchLeg);
    } else {
      SystemSound.play(SystemSoundType.alert);
    }
    setState(() {
      _leg = 1;
      _switching = 5;
    });
  }

  /// Rep della gamba in corso (o di tutta la serie se non è per gamba).
  int get _countReps => _perLeg ? _legReps[_leg].length : _reps.length;

  void _finish() {
    if (_finished) return;
    _finished = true;
    Sound.play(Sfx.setDone);
    _watch.stop();
    // Per gamba vale la gamba più debole: se la seconda resta indietro conta quella.
    final reps = !_perLeg
        ? List.of(_reps)
        : _legReps[1].isEmpty
            ? List.of(_legReps[0])
            : _legReps[1].length < _legReps[0].length
                ? List.of(_legReps[1])
                : _legReps[0].sublist(0, _legReps[1].length);
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
    final perLeg = _perLeg;
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
                            ? RepCounterBadge(text: '$_countdown', caption: tr('Preparati'))
                            : ListenableBuilder(
                                listenable: _input,
                                builder: (_, _) => RepCounterBadge(
                                  text: _input.isHold ? '${_input.held.inSeconds}s' : counterText,
                                  caption: [
                                    if (perLeg) _leg == 0 ? tr('gamba destra') : tr('gamba sinistra'),
                                    if (remaining != null) '$remaining s',
                                  ].join(' · '),
                                ),
                              ),
                      ),
                    ),
                    if (_switching > 0)
                      Positioned.fill(child: _SwitchLegOverlay(seconds: _switching)),
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
                tr('Perfette {p} · Buone {g} · Scarse {s}', {
                  'p': _reps.where((r) => r == RepQuality.perfect).length,
                  'g': _reps.where((r) => r == RepQuality.good).length,
                  's': _reps.where((r) => r == RepQuality.poor).length,
                }),
                style: const TextStyle(color: Palette.ash),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: perLeg && _leg == 0
                    ? FilledButton(onPressed: _switchLeg, child: Text(tr('CAMBIA GAMBA')))
                    : FilledButton(onPressed: _finish, child: Text(tr('TERMINA SERIE'))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CAMBIA GAMBA a tutto schermo, leggibile da lontano.
class _SwitchLegOverlay extends StatelessWidget {
  const _SwitchLegOverlay({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, color: Palette.goldBright, size: 90),
            Text(tr('CAMBIA GAMBA'), style: titleStyle(size: 34, spacing: 3)),
            const SizedBox(height: 8),
            Text(tr('Ora la sinistra · {s}', {'s': seconds}), style: titleStyle(size: 20, color: Palette.holy)),
          ],
        ),
      ),
    );
  }
}
