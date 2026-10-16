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
}
