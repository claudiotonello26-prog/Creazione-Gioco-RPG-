import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/combat.dart';
import '../domain/exercise.dart';
import '../pose/pose_frame.dart';
import '../pose/rep_counter.dart';
import '../pose/rep_input.dart';
import 'nakama_client.dart';

/// Codici dei messaggi: gli stessi di server/src/arena_match.ts.
class ArenaOp {
  static const ready = 1;
  static const pose = 2;
  static const rep = 3;
  static const state = 10;
  static const result = 11;
  static const poseRelay = 12;
  static const repRejected = 13;
}

enum LivePhase { idle, connecting, searching, joining, waiting, countdown, running, finished, error }

class LivePlayer {
  LivePlayer({required this.id, required this.name});
  final String id;
  String name;
  int reps = 0;
  double held = 0;
  bool done = false;
  bool left = false;
}

class LiveResult {
  LiveResult({
    required this.outcome,
    required this.delta,
    required this.points,
    required this.mine,
    required this.theirs,
    required this.forfeit,
  });

  /// 1 vittoria, 0 pareggio, −1 sconfitta.
  final int outcome;
  final int delta;
  final int? points;
  final Map<String, dynamic> mine;
  final Map<String, dynamic>? theirs;

  /// L'avversario ha abbandonato.
  final bool forfeit;
}

/// Duello live dell'Arena Pura: matchmaking, invio dello scheletro e delle
/// rep, stato e risultato decisi dal server.
class ArenaLiveSession extends ChangeNotifier {
  ArenaLiveSession({
    required this.client,
    required this.exercise,
    required this.deviceId,
    required this.username,
  });

  final NakamaClient client;
  final ExerciseId exercise;
  final String deviceId;
  final String username;

  LivePhase phase = LivePhase.idle;
  String? error;
  String? myId;
  LivePlayer? me;
  LivePlayer? opponent;
  int countdown = 0;
  double elapsed = 0;
  int rejected = 0;
  PoseFrame? opponentPose;
  LiveResult? result;

  NakamaSession? _session;
  NakamaSocket? _socket;
  String? _ticket;
  String? _matchId;
  RepInput? _input;
  StreamSubscription<RepEvent>? _repSub;
  StreamSubscription<MatchData>? _dataSub;
  Timer? _poseTimer;
  PoseFrame? _lastSentPose;
  bool _disposed = false;

  bool get isActive =>
      phase != LivePhase.idle && phase != LivePhase.finished && phase != LivePhase.error;

  void _set(LivePhase p) {
    phase = p;
    if (!_disposed) notifyListeners();
  }

  Future<void> start(RepInput input) async {
    _input = input;
    try {
      _set(LivePhase.connecting);
      _session = await client.authenticateDevice(deviceId, username: username);
      myId = _session!.userId;
      _socket = await client.connect(_session!);
      _dataSub = _socket!.onMatchData.listen(_onData);
      _socket!.onError.listen((e) => _fail('$e'));

      _set(LivePhase.searching);
      final matched = _socket!.onMatchmakerMatched.first;
      _ticket = await _socket!.addMatchmaker(exercise.name);
      final m = await matched;
      _ticket = null;

      _set(LivePhase.joining);
      _matchId = await _socket!.joinMatch(m['match_id'] as String);
      _socket!.sendMatchData(_matchId!, ArenaOp.ready, const {});
      _set(LivePhase.waiting);

      _repSub = input.reps.listen(_onRep);
      _poseTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _sendPose());
    } catch (e) {
      _fail('$e');
    }
  }

  void _fail(String message) {
    if (phase == LivePhase.finished || _disposed) return;
    error = message;
    _set(LivePhase.error);
    _shutdown();
  }

  void _onRep(RepEvent e) {
    if (phase != LivePhase.running || _matchId == null) return;
    _sendPose(force: true);
    _socket?.sendMatchData(_matchId!, ArenaOp.rep, {'q': e.quality.name});
  }

  void _sendPose({bool force = false}) {
    if (_matchId == null || phase != LivePhase.running) return;
    final pose = _input?.pose;
    if (pose == null || (!force && identical(pose, _lastSentPose))) return;
    _lastSentPose = pose;
    _socket?.sendMatchData(_matchId!, ArenaOp.pose, {'k': pose.toWire()});
  }

  void _onData(MatchData d) {
    switch (d.opCode) {
      case ArenaOp.state:
        _applyState(d.data);
      case ArenaOp.poseRelay:
        final k = d.data['k'];
        if (k is List) opponentPose = PoseFrame.fromWire(k);
      case ArenaOp.repRejected:
        rejected++;
      case ArenaOp.result:
        _applyResult(d.data);
    }
    if (!_disposed) notifyListeners();
  }

  void _applyState(Map<String, dynamic> s) {
    countdown = (s['countdown'] as num?)?.toInt() ?? 0;
    elapsed = (s['elapsed'] as num?)?.toDouble() ?? 0;
    final players = (s['players'] as Map<String, dynamic>?) ?? const {};
    players.forEach((id, raw) {
      final p = raw as Map<String, dynamic>;
      final target = id == myId
          ? (me ??= LivePlayer(id: id, name: p['name'] as String? ?? ''))
          : (opponent ??= LivePlayer(id: id, name: p['name'] as String? ?? ''));
      target
        ..name = p['name'] as String? ?? target.name
        ..reps = (p['reps'] as num?)?.toInt() ?? 0
        ..held = (p['held'] as num?)?.toDouble() ?? 0
        ..done = p['done'] == true
        ..left = p['left'] == true;
    });
    final next = switch (s['phase']) {
      'countdown' => LivePhase.countdown,
      'running' => LivePhase.running,
      'finished' => LivePhase.finished,
      _ => phase,
    };
    if (next != phase && phase != LivePhase.finished) phase = next;
  }

  void _applyResult(Map<String, dynamic> r) {
    final results = (r['results'] as Map<String, dynamic>?) ?? const {};
    final mine = (results[myId] as Map<String, dynamic>?) ?? const {};
    Map<String, dynamic>? theirs;
    results.forEach((id, v) {
      if (id != myId) theirs = v as Map<String, dynamic>;
    });
    result = LiveResult(
      outcome: (mine['outcome'] as num?)?.toInt() ?? 0,
      delta: (mine['delta'] as num?)?.toInt() ?? 0,
      points: (mine['points'] as num?)?.toInt(),
      mine: mine,
      theirs: theirs,
      forfeit: theirs?['forfeit'] == true,
    );
    phase = LivePhase.finished;
    _shutdown();
  }

  /// Le mie rep valide secondo il server (le rep rifiutate non contano).
  List<RepQuality> get serverCountedReps =>
      List.filled(me?.reps ?? 0, RepQuality.good);

  Future<void> cancel() async {
    try {
      if (_ticket != null) await _socket?.removeMatchmaker(_ticket!);
      if (_matchId != null && phase != LivePhase.finished) await _socket?.leaveMatch(_matchId!);
    } catch (_) {
      // Si esce comunque.
    }
    _shutdown();
  }

  void _shutdown() {
    _poseTimer?.cancel();
    _poseTimer = null;
    _repSub?.cancel();
    _repSub = null;
    final socket = _socket;
    _socket = null;
    _dataSub?.cancel();
    socket?.close();
  }

  @override
  void dispose() {
    _disposed = true;
    _shutdown();
    super.dispose();
  }
}
