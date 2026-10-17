import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/pose/pose_frame.dart';
import 'package:iron_oath/pose/rep_counter.dart';

/// Push-up visto di lato: spalla fissa, gomito e polso piegati di [angle].
PoseFrame pushUpFrame(double elbowAngle, Duration t) {
  const shoulder = JointPoint(0, 0);
  const elbow = JointPoint(0, 1);
  final rad = elbowAngle * pi / 180;
  // Il polso forma l'angolo richiesto con il segmento gomito→spalla.
  final wrist = JointPoint(sin(rad), 1 - cos(rad));
  return PoseFrame({
    Joint.leftShoulder: shoulder,
    Joint.leftElbow: elbow,
    Joint.leftWrist: wrist,
  }, timestamp: t);
}

List<RepEvent> run(AngleRepCounter c, List<double> angles, {int msPerFrame = 100}) {
  final events = <RepEvent>[];
  for (var i = 0; i < angles.length; i++) {
    final e = c.add(pushUpFrame(angles[i], Duration(milliseconds: i * msPerFrame)));
    if (e != null) events.add(e);
  }
  return events;
}

List<double> rep(double bottom, double top) =>
    [170, 150, 130, 110, bottom, bottom, 110, 130, 150, top, top, top];

void main() {
  test('angolo calcolato correttamente', () {
    expect(pushUpFrame(90, Duration.zero).angle(Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
        closeTo(90, 1e-6));
  });

  test('rep profonde e distese = perfette', () {
    final c = counterFor(ExerciseId.pushUp, smoothing: 0);
    final events = run(c, [for (var i = 0; i < 3; i++) ...rep(70, 170)]);
    expect(events, hasLength(3));
    expect(events.every((e) => e.quality == RepQuality.perfect), isTrue);
  });

  test('mezze rep non contano', () {
    final c = counterFor(ExerciseId.pushUp);
    final events = run(c, [for (var i = 0; i < 3; i++) ...[170, 140, 120, 115, 120, 140, 170]]);
    expect(events, isEmpty);
    expect(c.hint, isNot(FormHint.notVisible));
  });

  test('discesa sufficiente ma non profonda = buona', () {
    final c = AngleRepCounter(
      measure: (f) => f.angle(Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
      requiredJoints: const [Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist],
      downThreshold: 100,
      perfectDown: 85,
      upThreshold: 155,
      looseUp: 140,
      smoothing: 0,
    );
    final events = run(c, rep(95, 170));
    expect(events.single.quality, RepQuality.good);
  });

  test('senza distensione completa = scarsa', () {
    final c = AngleRepCounter(
      measure: (f) => f.angle(Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
      requiredJoints: const [Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist],
      downThreshold: 100,
      perfectDown: 85,
      upThreshold: 155,
      looseUp: 140,
      smoothing: 0,
    );
    final events = run(c, [170, 120, 95, 95, 120, 145, 145, 145, 145, 145, 145, 145, 145]);
    expect(events.single.quality, RepQuality.poor);
  });

  test('rep troppo veloci sono implausibili e scartate', () {
    final c = counterFor(ExerciseId.pushUp, smoothing: 0);
    final events = run(c, rep(70, 170), msPerFrame: 10);
    expect(events, isEmpty);
  });

  test('scheletro non visibile', () {
    final c = counterFor(ExerciseId.pushUp);
    expect(c.add(const PoseFrame({})), isNull);
    expect(c.hint, FormHint.notVisible);
  });

  test('high knees: ogni ginocchio sopra l\'anca è una rep, alternando le gambe', () {
    // In piedi di fronte: spalla sopra l'anca, il ginocchio sale davanti.
    PoseFrame frame(double leftHip, double rightHip, int ms) {
      JointPoint knee(double deg, double x) {
        final r = deg * pi / 180;
        return JointPoint(x + sin(r) * 0.5, 1 - cos(r) * 0.5);
      }

      return PoseFrame({
        Joint.leftShoulder: const JointPoint(-0.2, 0),
        Joint.rightShoulder: const JointPoint(0.2, 0),
        Joint.leftHip: const JointPoint(-0.2, 1),
        Joint.rightHip: const JointPoint(0.2, 1),
        Joint.leftKnee: knee(leftHip, -0.2),
        Joint.rightKnee: knee(rightHip, 0.2),
      }, timestamp: Duration(milliseconds: ms));
    }

    final t = ExerciseTracker(ExerciseId.highKnees);
    var ms = 0;
    var events = 0;
    for (var i = 0; i < 6; i++) {
      final left = i.isEven;
      for (final a in <double>[175, 150, 120, 95, 90, 95, 120, 150, 175, 178, 178, 178, 178, 178, 178, 178]) {
        if (t.add(frame(left ? a : 178, left ? 178 : a, ms)) != null) events++;
        ms += 60;
      }
    }
    expect(events, 6);
  });
}
