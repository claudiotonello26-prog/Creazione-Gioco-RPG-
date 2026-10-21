import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';
import '../../core/i18n.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/exercise.dart';
import '../../domain/pvp.dart';
import '../../pose/rep_counter.dart';
import '../../pose/rep_input.dart';
import '../widgets/common.dart';
import '../widgets/exercise_view.dart';
import 'arena_live_screen.dart';

class ArenaTab extends StatelessWidget {
  const ArenaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final wins = s.arenaHistory.where((r) => r.won > 0).length;
    final losses = s.arenaHistory.where((r) => r.won < 0).length;
    return FoldedListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  tr('ARENA PURA'),
                  style: const TextStyle(letterSpacing: 4, color: Palette.goldBright, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(tr('{title} · {points} punti stagione', {'title': s.seasonTitle, 'points': s.arenaPoints})),
                Text(
                  tr('Vittorie {wins} · Sconfitte {losses}', {'wins': wins, 'losses': losses}),
                  style: const TextStyle(color: Palette.ash),
                ),
              ],
            ),
          ),
        ),
        SectionTitle(tr('Duello live online')),
        if (s.serverAddress.isEmpty || !s.useCamera)
          Text(
            s.serverAddress.isEmpty
                ? tr('Imposta il server dell\'Arena nel Profilo per sfidare persone vere.')
                : tr('Il live richiede la fotocamera: le rep devono essere verificate.'),
            style: const TextStyle(color: Palette.ash),
          )
        else
          for (final c in arenaChallenges.values)
            ActionTile(
              icon: Icons.public,
              title: tr('{exercise} · live', {'exercise': exercises[c.exercise]!.name}),
              subtitle: tr('Contro una persona vera'),
              color: Palette.goldBright,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ArenaLiveScreen(challenge: c))),
            ),
        SectionTitle(tr('Duello contro ombre')),
        for (final c in arenaChallenges.values)
          ActionTile(
            icon: Icons.sports_kabaddi,
            title: exercises[c.exercise]!.name,
            subtitle: tr('Divisione: {division}', {'division': s.divisionOf(c.exercise).label}),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => ArenaDuelScreen(challenge: c))),
          ),
        if (s.arenaHistory.isNotEmpty) ...[
          SectionTitle(tr('Ultimi duelli')),
          for (final r in s.arenaHistory.take(10))
            ListTile(
              dense: true,
              leading: Icon(
                r.won > 0 ? Icons.emoji_events : (r.won < 0 ? Icons.close : Icons.drag_handle),
                color: r.won > 0 ? Palette.goldBright : Palette.ash,
              ),
              title: OneLine(tr('{exercise} contro {opponent}', {'exercise': exercises[r.exercise]!.name, 'opponent': tr(r.opponent)})),
              trailing: Text(r.day, style: const TextStyle(color: Palette.ash)),
            ),
        ],
      ],
    );
  }
}

/// Duello: tu contro un avversario della tua divisione. In questa versione
/// l'avversario è un "fantasma" generato in locale; il live passerà dal
/// server trasmettendo solo i punti dello scheletro.
class ArenaDuelScreen extends StatefulWidget {
  const ArenaDuelScreen({super.key, required this.challenge});
  final ArenaChallenge challenge;

  @override
  State<ArenaDuelScreen> createState() => _ArenaDuelScreenState();
}

class _ArenaDuelScreenState extends State<ArenaDuelScreen> {
  late final ArenaOpponent _opponent;
  late final RepInput _input;
  StreamSubscription<RepEvent>? _sub;
  final List<RepQuality> _reps = [];
  final _watch = Stopwatch();
  Timer? _timer;
  int _countdown = 5;
  bool _over = false;
  Duration _notHolding = Duration.zero;

  static const _maxDuration = Duration(minutes: 3);

  ArenaChallenge get c => widget.challenge;

  @override
  void initState() {
    super.initState();
    final s = context.read<GameState>();
    _opponent = ArenaOpponent.generate(s.divisionOf(c.exercise));
    _input = createRepInput(s.useCamera, c.exercise);
    _input.start();
    _sub = _input.reps.listen((e) {
      if (_countdown > 0 || _over) return;
      setState(() => _reps.add(e.quality));
      if (c.goal == ChallengeGoal.fastestReps && _myReps >= c.targetReps) _end();
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  int get _myReps => exercises[c.exercise]!.perLeg ? _reps.length ~/ 2 : _reps.length;

  int _tenths = 0;
  void _tick() {
    if (_over) return;
    if (_countdown > 0) {
      if (++_tenths % 10 == 0) {
        setState(() => _countdown--);
        if (_countdown == 0) _watch.start();
      }
      return;
    }
    final t = _watch.elapsed;
    switch (c.goal) {
      case ChallengeGoal.mostRepsInTime:
        if (t.inSeconds >= c.seconds) _end();
      case ChallengeGoal.longestHold:
        _notHolding =
            _input.holdingNow ? Duration.zero : _notHolding + const Duration(milliseconds: 100);
        if (_input.held > Duration.zero && _notHolding > const Duration(seconds: 2)) _end();
      case ChallengeGoal.fastestReps:
        break;
    }
    if (t > _maxDuration) _end();
    if (mounted) setState(() {});
  }

  void _end() {
    if (_over) return;
    _over = true;
    _watch.stop();
    final mine = ArenaResult(
      validReps: _myReps,
      elapsedSeconds: c.goal == ChallengeGoal.longestHold
          ? _input.held.inMilliseconds / 1000
          : _watch.elapsed.inMilliseconds / 1000,
      formScore: ArenaResult.formScoreOf(_reps),
      completed: c.goal != ChallengeGoal.fastestReps || _myReps >= c.targetReps,
    );
    final theirs = _opponent.resultFor(c);
    final cmp = compareResults(c, mine, theirs);
    context.read<GameState>().recordArena(c.exercise, _opponent.name, cmp, mine, _reps);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Text(
          cmp > 0 ? tr('VITTORIA') : (cmp < 0 ? tr('SCONFITTA') : tr('PAREGGIO')),
          textAlign: TextAlign.center,
          style: TextStyle(color: cmp > 0 ? Palette.goldBright : Palette.ash, letterSpacing: 4),
        ),
        content: Text(
          tr('Tu: {mine}\n{opponent}: {theirs}\n\nPunti stagione {delta}', {
            'mine': _describe(mine),
            'opponent': _opponent.displayName,
            'theirs': _describe(theirs),
            'delta': '${rankDelta(cmp) >= 0 ? '+' : ''}${rankDelta(cmp)}',
          }),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(tr('CONTINUA')),
          ),
        ],
      ),
    );
  }

  String _describe(ArenaResult r) => switch (c.goal) {
        ChallengeGoal.fastestReps => r.completed
            ? '${r.elapsedSeconds.toStringAsFixed(1)} s'
            : tr('{done}/{target} rep (non completata)', {'done': r.validReps, 'target': c.targetReps}),
        ChallengeGoal.mostRepsInTime => tr('{n} rep', {'n': r.validReps}),
        ChallengeGoal.longestHold => '${r.elapsedSeconds.toStringAsFixed(0)} s',
      };

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  double get _opponentProgress {
    final t = _watch.elapsed.inMilliseconds / 1000;
    return switch (c.goal) {
      ChallengeGoal.fastestReps => _opponent.repsAt(t) / c.targetReps,
      ChallengeGoal.mostRepsInTime => _opponent.repsAt(t) / (c.seconds / 1.2),
      ChallengeGoal.longestHold => t / _opponent.holdSeconds,
    };
  }

  double get _myProgress => switch (c.goal) {
        ChallengeGoal.fastestReps => _myReps / c.targetReps,
        ChallengeGoal.mostRepsInTime => _myReps / (c.seconds / 1.2),
        ChallengeGoal.longestHold => _input.held.inMilliseconds / 1000 / _opponent.holdSeconds,
      };

  @override
  Widget build(BuildContext context) {
    final oppReps = _opponent.repsAt(_watch.elapsed.inMilliseconds / 1000);
    return PopScope(
      canPop: _countdown > 0 || _over,
      child: Scaffold(
        appBar: OathBar(title: Text(exercises[c.exercise]!.name.toUpperCase())),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(c.description, style: const TextStyle(color: Palette.ash)),
                  const SizedBox(height: 10),
                  StatBar(
                    value: _myProgress,
                    color: Palette.goldBright,
                    label: c.goal == ChallengeGoal.longestHold
                        ? tr('Tu · {s}s', {'s': _input.held.inSeconds})
                        : tr('Tu · {n} rep', {'n': _myReps}),
                    height: 14,
                  ),
                  const SizedBox(height: 8),
                  StatBar(
                    value: _opponentProgress,
                    color: Palette.blood,
                    label: '${_opponent.displayName} (${_opponent.division.label})'
                        '${c.goal == ChallengeGoal.longestHold ? '' : ' · ${tr('{n} rep', {'n': c.goal == ChallengeGoal.fastestReps ? oppReps.clamp(0, c.targetReps) : oppReps})}'}',
                    height: 14,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _countdown > 0 ? tr('Inizia tra {n}', {'n': _countdown}) : '${_watch.elapsed.inSeconds}s',
                    style: const TextStyle(fontSize: 22, color: Palette.goldBright),
                  ),
                ],
              ),
            ),
            Expanded(child: ExerciseView(input: _input)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _countdown > 0 || _over ? null : _end,
                    child: Text(tr('Mi fermo qui')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on RepInput {
  bool get holdingNow {
    final self = this;
    if (self is ManualRepInput) return self.holding;
    return hint == FormHint.none;
  }
}
