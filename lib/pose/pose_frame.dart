import 'dart:math';

/// Punti dello scheletro usati dal contatore. Sono un sottoinsieme dei 33
/// punti di ML Kit / MediaPipe Pose, indipendente dal plugin così la logica
/// si testa senza fotocamera.
enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class JointPoint {
  const JointPoint(this.x, this.y, [this.likelihood = 1.0]);

  /// Coordinate normalizzate o in pixel: contano solo gli angoli e i
  /// rapporti tra distanze.
  final double x;
  final double y;
  final double likelihood;
}

class PoseFrame {
  const PoseFrame(this.joints, {this.timestamp = Duration.zero, this.scale = 1});

  final Map<Joint, JointPoint> joints;
  final Duration timestamp;

  /// Lato maggiore dell'immagine in pixel: dividendo entrambe le coordinate
  /// per lo stesso valore gli angoli non cambiano.
  final double scale;

  /// Scheletro compatto per la rete: [x, y, likelihood] per ogni Joint, in
  /// ordine, normalizzato. Nessuna immagine lascia il telefono.
  List<List<double>> toWire() => [
        for (final j in Joint.values)
          if (joints[j] case final p?)
            [_r(p.x / scale), _r(p.y / scale), _r(p.likelihood)]
          else
            const [0.0, 0.0, 0.0],
      ];

  static double _r(double v) => (v * 1000).roundToDouble() / 1000;

  factory PoseFrame.fromWire(List<dynamic> k) => PoseFrame({
        for (var i = 0; i < k.length && i < Joint.values.length; i++)
          if ((k[i] as List).length == 3 && ((k[i] as List)[2] as num) > 0)
            Joint.values[i]: JointPoint(
              ((k[i] as List)[0] as num).toDouble(),
              ((k[i] as List)[1] as num).toDouble(),
              ((k[i] as List)[2] as num).toDouble(),
            ),
      });

  JointPoint? operator [](Joint j) => joints[j];

  bool hasAll(Iterable<Joint> required, {double minLikelihood = 0.5}) =>
      required.every((j) => (joints[j]?.likelihood ?? 0) >= minLikelihood);

  /// Angolo in gradi nel vertice [b] tra i segmenti b→a e b→c.
  double? angle(Joint a, Joint b, Joint c) {
    final pa = joints[a], pb = joints[b], pc = joints[c];
    if (pa == null || pb == null || pc == null) return null;
    final v1x = pa.x - pb.x, v1y = pa.y - pb.y;
    final v2x = pc.x - pb.x, v2y = pc.y - pb.y;
    final n1 = sqrt(v1x * v1x + v1y * v1y), n2 = sqrt(v2x * v2x + v2y * v2y);
    if (n1 == 0 || n2 == 0) return null;
    final cos = ((v1x * v2x + v1y * v2y) / (n1 * n2)).clamp(-1.0, 1.0);
    return acos(cos) * 180 / pi;
  }

  double? distance(Joint a, Joint b) {
    final pa = joints[a], pb = joints[b];
    if (pa == null || pb == null) return null;
    return sqrt(pow(pa.x - pb.x, 2) + pow(pa.y - pb.y, 2));
  }

  /// Media dei due lati, o il lato più visibile se uno manca.
  double? bilateral(double? left, double? right) {
    if (left == null) return right;
    if (right == null) return left;
    return (left + right) / 2;
  }
}
