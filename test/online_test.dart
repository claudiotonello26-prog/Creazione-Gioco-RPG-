import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/online/arena_live.dart';
import 'package:iron_oath/online/nakama_client.dart';
import 'package:iron_oath/pose/pose_frame.dart';
import 'package:iron_oath/pose/rep_counter.dart';
import 'package:iron_oath/pose/rep_input.dart';

/// Sorgente di rep pilotata dal test, con lo scheletro di un braccio.
class FakeInput extends RepInput {
  FakeInput() : super(ExerciseId.pushUp);
  PoseFrame? current;

  @override
  PoseFrame? get pose => current;
  @override
  FormHint get hint => FormHint.none;
  @override
  int get count => 0;
  @override
  Duration get held => Duration.zero;
  @override
  String? get error => null;
  @override
  Future<void> start() async {}

  void arm(double angle) {
    final rad = angle * pi / 180;
    current = PoseFrame({
      Joint.leftShoulder: const JointPoint(500, 300, 0.99),
      Joint.leftElbow: const JointPoint(500, 400, 0.99),
      Joint.leftWrist: JointPoint(500 + 100 * sin(rad), 400 - 100 * cos(rad), 0.99),
    }, scale: 1000);
    notifyListeners();
  }

  void rep() => emit(const RepEvent(RepQuality.perfect));
}

void main() {
  test('ServerConfig accetta host, porta e URL', () {
    final a = ServerConfig.parse('192.168.1.10')!;
    expect((a.host, a.port, a.ssl), ('192.168.1.10', 7350, false));
    final b = ServerConfig.parse('https://arena.example.org')!;
    expect((b.port, b.ssl), (443, true));
    expect(b.ws('t').toString(), startsWith('wss://arena.example.org:443/ws?'));
    expect(ServerConfig.parse('  '), isNull);
  });

  test('lo scheletro viaggia normalizzato e conserva gli angoli', () {
    final input = FakeInput()..arm(90);
    final wire = input.current!.toWire();
    expect(wire, hasLength(Joint.values.length));
    final back = PoseFrame.fromWire(wire);
    expect(back.angle(Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist), closeTo(90, 0.5));
    expect(back[Joint.nose], isNull);
  });

  final url = Platform.environment['NAKAMA_URL'];
  test('duello live contro il server vero', () async {
    final config = ServerConfig.parse(url!)!;
    final run = DateTime.now().millisecondsSinceEpoch;
    final aIn = FakeInput(), bIn = FakeInput();
    final a = ArenaLiveSession(
        client: NakamaClient(config), exercise: ExerciseId.pushUp,
        deviceId: 'dart-a-$run', username: 'dartA$run');
    final b = ArenaLiveSession(
        client: NakamaClient(config), exercise: ExerciseId.pushUp,
        deviceId: 'dart-b-$run', username: 'dartB$run');
    aIn.arm(170);
    bIn.arm(170);
    await Future.wait([a.start(aIn), b.start(bIn)]);
    expect(a.error, isNull);

    Future<void> until(bool Function() cond, {int seconds = 30}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!cond()) {
        if (DateTime.now().isAfter(end)) fail('timeout: ${a.phase} / ${a.error}');
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    await until(() => a.phase == LivePhase.running && b.phase == LivePhase.running);

    // A completa 20 push-up veri; B resta fermo.
    for (var r = 0; r < 20; r++) {
      for (final angle in [170.0, 120.0, 80.0, 80.0, 120.0, 165.0]) {
        aIn.arm(angle);
        await Future<void>.delayed(const Duration(milliseconds: 110));
      }
      aIn.rep();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    await until(() => (a.me?.reps ?? 0) == 20);
    expect(b.opponentPose, isNotNull, reason: 'B vede l\'avatar di A');
    expect(b.opponent?.reps, 20);

    // B abbandona: A vince a tavolino.
    await b.cancel();
    await until(() => a.phase == LivePhase.finished);
    expect(a.result!.outcome, 1);
    expect(a.result!.delta, 25);
    expect(a.result!.points, 1025);
    a.dispose();
    b.dispose();
  }, skip: url == null ? 'NAKAMA_URL non impostata' : false, timeout: const Timeout(Duration(minutes: 2)));
}
