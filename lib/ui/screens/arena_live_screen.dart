import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/pvp.dart';
import '../../online/arena_live.dart';
import '../../online/nakama_client.dart';
import '../../pose/pose_frame.dart';
import '../../pose/rep_input.dart';
import '../widgets/exercise_view.dart';

/// Duello live: l'avversario è un avatar animato dal suo scheletro, nessun
/// video. Conteggio e vincitore li decide il server.
class ArenaLiveScreen extends StatefulWidget {
  const ArenaLiveScreen({super.key, required this.challenge});
  final ArenaChallenge challenge;

  @override
  State<ArenaLiveScreen> createState() => _ArenaLiveScreenState();
}

class _ArenaLiveScreenState extends State<ArenaLiveScreen> {
  late final ArenaLiveSession _session;
  late final RepInput _input;
  bool _recorded = false;

  ArenaChallenge get c => widget.challenge;

  @override
  void initState() {
    super.initState();
    final s = context.read<GameState>();
    final config = ServerConfig.parse(s.serverAddress)!;
    // Nel live servono rep verificate: sempre la fotocamera.
    _input = CameraRepInput(c.exercise);
    _input.start();
    _session = ArenaLiveSession(
      client: NakamaClient(config),
      exercise: c.exercise,
      deviceId: s.deviceId,
      username: s.character.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), ''),
    )..addListener(_onChange);
    _session.start(_input);
  }

  void _onChange() {
    if (_session.phase == LivePhase.finished && !_recorded && _session.result != null) {
      _recorded = true;
      final r = _session.result!;
      context.read<GameState>().applyLiveArena(
            c.exercise,
            _session.opponent?.name ?? 'Avversario',
            r.outcome,
            r.points,
            _session.serverCountedReps,
          );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session.removeListener(_onChange);
    if (_session.isActive) _session.cancel();
    _session.dispose();
    _input.dispose();
    super.dispose();
  }

  String get _phaseText => switch (_session.phase) {
        LivePhase.idle || LivePhase.connecting => 'Connessione al server…',
        LivePhase.searching => 'Cerco un avversario per ${exercises[c.exercise]!.name}…',
        LivePhase.joining || LivePhase.waiting => 'Avversario trovato. Mettiti in posizione.',
        LivePhase.countdown => 'Inizia tra ${_session.countdown}',
        LivePhase.running => '${_session.elapsed.toStringAsFixed(0)} s',
        LivePhase.finished => 'Duello concluso',
        LivePhase.error => _session.error ?? 'Errore',
      };

  String _score(LivePlayer? p) {
    if (p == null) return '—';
    if (c.goal == ChallengeGoal.longestHold) return '${p.held.toStringAsFixed(0)} s';
    return c.goal == ChallengeGoal.fastestReps ? '${p.reps}/${c.targetReps}' : '${p.reps} rep';
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return PopScope(
      canPop: !s.isActive || s.phase == LivePhase.searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: OathBar(title: Text('LIVE · ${exercises[c.exercise]!.name.toUpperCase()}')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                _phaseText,
                style: TextStyle(
                  fontSize: 18,
                  color: s.phase == LivePhase.error ? Palette.blood : Palette.goldBright,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: _PlayerPanel(
                      name: s.opponent?.name ?? 'Avversario',
                      score: _score(s.opponent),
                      color: Palette.blood,
                      child: CustomPaint(
                        painter: AvatarPainter(pose: s.opponentPose, color: Palette.blood),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PlayerPanel(
                      name: 'Tu',
                      score: _score(s.me),
                      color: Palette.goldBright,
                      child: ListenableBuilder(
                        listenable: _input,
                        builder: (_, _) => CustomPaint(
                          painter: AvatarPainter(pose: _input.pose, color: Palette.goldBright),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.rejected > 0)
              Text(
                '${s.rejected} rep non valide per il server (movimento incompleto)',
                style: const TextStyle(color: Palette.ember, fontSize: 12),
              ),
            if (s.phase == LivePhase.finished && s.result != null) _ResultCard(result: s.result!),
            if (s.phase != LivePhase.finished)
              Expanded(flex: 3, child: ExerciseView(input: _input)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: s.isActive
                      ? OutlinedButton(onPressed: _confirmLeave, child: const Text('Abbandona'))
                      : FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('TORNA ALL\'ARENA'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    if (_session.phase == LivePhase.searching) {
      await _session.cancel();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: const Text('Abbandonare il duello?'),
        content: const Text('Chi abbandona perde a tavolino.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Resto')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Abbandono')),
        ],
      ),
    );
    if (ok == true) {
      await _session.cancel();
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.name,
    required this.score,
    required this.color,
    required this.child,
  });

  final String name;
  final String score;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Palette.stone,
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color),
            ),
          ),
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(score, style: TextStyle(fontSize: 22, color: color)),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final LiveResult result;

  @override
  Widget build(BuildContext context) {
    final title = switch (result.outcome) {
      > 0 => result.forfeit ? 'VITTORIA A TAVOLINO' : 'VITTORIA',
      < 0 => 'SCONFITTA',
      _ => 'PAREGGIO',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                color: result.outcome > 0 ? Palette.goldBright : Palette.ash,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Punti stagione ${result.delta >= 0 ? '+' : ''}${result.delta}'
              '${result.points != null ? ' · totale ${result.points}' : ''}',
            ),
            const SizedBox(height: 4),
            const Text(
              'Risultato verificato dal server sulle rep valide.',
              style: TextStyle(color: Palette.ash, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

const _avatarBones = [
  (Joint.leftShoulder, Joint.rightShoulder),
  (Joint.leftShoulder, Joint.leftElbow),
  (Joint.leftElbow, Joint.leftWrist),
  (Joint.rightShoulder, Joint.rightElbow),
  (Joint.rightElbow, Joint.rightWrist),
  (Joint.leftShoulder, Joint.leftHip),
  (Joint.rightShoulder, Joint.rightHip),
  (Joint.leftHip, Joint.rightHip),
  (Joint.leftHip, Joint.leftKnee),
  (Joint.leftKnee, Joint.leftAnkle),
  (Joint.rightHip, Joint.rightKnee),
  (Joint.rightKnee, Joint.rightAnkle),
];

/// Avatar del cavaliere animato dallo scheletro, adattato al riquadro.
class AvatarPainter extends CustomPainter {
  AvatarPainter({required this.pose, required this.color});
  final PoseFrame? pose;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    if (p == null) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'In attesa…',
          style: TextStyle(color: Palette.ash),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }
    final pts = p.joints.entries.where((e) => e.value.likelihood >= 0.4).toList();
    if (pts.isEmpty) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final e in pts) {
      minX = e.value.x < minX ? e.value.x : minX;
      maxX = e.value.x > maxX ? e.value.x : maxX;
      minY = e.value.y < minY ? e.value.y : minY;
      maxY = e.value.y > maxY ? e.value.y : maxY;
    }
    final w = (maxX - minX).abs() < 1e-6 ? 1.0 : maxX - minX;
    final h = (maxY - minY).abs() < 1e-6 ? 1.0 : maxY - minY;
    final scale = 0.8 * (size.width / w < size.height / h ? size.width / w : size.height / h);
    final ox = (size.width - w * scale) / 2, oy = (size.height - h * scale) / 2;
    Offset map(JointPoint j) => Offset(ox + (j.x - minX) * scale, oy + (j.y - minY) * scale);

    final armor = Paint()
      ..color = const Color(0xFF4A423A)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (a, b) in _avatarBones) {
      final ja = p[a], jb = p[b];
      if (ja == null || jb == null || ja.likelihood < 0.4 || jb.likelihood < 0.4) continue;
      canvas.drawLine(map(ja), map(jb), armor);
      canvas.drawLine(map(ja), map(jb), edge);
    }
    final ls = p[Joint.leftShoulder], rs = p[Joint.rightShoulder];
    if (ls != null && rs != null) {
      final mid = (map(ls) + map(rs)) / 2;
      final shoulder = (map(ls) - map(rs)).distance;
      final head = mid.translate(0, -shoulder * 0.55);
      final r = (shoulder * 0.3).clamp(8.0, 40.0);
      canvas.drawCircle(head, r, Paint()..color = const Color(0xFF4A423A));
      canvas.drawLine(
        head.translate(-r * 0.6, 0),
        head.translate(r * 0.6, 0),
        Paint()
          ..color = Palette.ember
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(AvatarPainter old) => old.pose != pose;
}
