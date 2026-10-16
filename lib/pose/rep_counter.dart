import 'dart:math';

import '../domain/combat.dart';
import '../domain/exercise.dart';
import 'pose_frame.dart';

/// Evento emesso da un contatore.
class RepEvent {
  const RepEvent(this.quality, {this.side});
  final RepQuality quality;

  /// 'L' / 'R' per gli esercizi contati per gamba.
  final String? side;
}

/// Suggerimento mostrato a schermo quando la posizione non va.
enum FormHint {
  none,
  notVisible,
  goDeeper,
  extendFully,
}

/// Contatore generico: misura un angolo "di lavoro" che scende nella fase
/// contratta e sale nella fase estesa, con isteresi e macchina a stati.
///
/// Una rep conta solo se l'angolo scende sotto [downThreshold] e poi torna
/// sopra [looseUp]. Le mezze rep non contano. La qualità dipende da quanto
/// si scende ([perfectDown]) e da quanto si torna estesi ([upThreshold]).
class AngleRepCounter {
  AngleRepCounter({
    required this.measure,
    required this.requiredJoints,
    required this.downThreshold,
    required this.perfectDown,
    required this.upThreshold,
    required this.looseUp,
    this.minRepDuration = const Duration(milliseconds: 350),
    this.smoothing = 0.5,
  });

  /// Ritorna l'angolo di lavoro del frame, o null se non misurabile.
  final double? Function(PoseFrame) measure;
  final List<Joint> requiredJoints;
  final double downThreshold;
  final double perfectDown;
  final double upThreshold;
  final double looseUp;

  /// Rep più veloci di così sono scartate come implausibili.
  final Duration minRepDuration;

  /// Fattore dello smoothing esponenziale (0 = nessuno).
  final double smoothing;

  /// Dopo essere tornati sopra [looseUp], quanto si aspetta la distensione
  /// completa prima di chiudere la rep.
  static const Duration settleTime = Duration(milliseconds: 600);

  double? _value;
  _Phase _phase = _Phase.up;
  double _minInRep = double.infinity;
  double _maxOnRise = 0;
  Duration? _repStart;
  Duration _riseStart = Duration.zero;
  FormHint hint = FormHint.notVisible;
  int count = 0;

  double? get currentAngle => _value;

  void reset() {
    _value = null;
    _phase = _Phase.up;
    _minInRep = double.infinity;
    _repStart = null;
    count = 0;
  }

  RepEvent? add(PoseFrame frame) {
    if (!frame.hasAll(requiredJoints)) {
      hint = FormHint.notVisible;
      return null;
    }
    final raw = measure(frame);
    if (raw == null) {
      hint = FormHint.notVisible;
      return null;
    }
    _value = _value == null ? raw : _value! * smoothing + raw * (1 - smoothing);
    final v = _value!;
    final t = frame.timestamp;

    switch (_phase) {
      case _Phase.up:
        if (v < downThreshold) {
          _phase = _Phase.down;
          _minInRep = v;
          _repStart ??= t;
          hint = FormHint.none;
        } else {
          // Sta scendendo ma non abbastanza.
          hint = v < looseUp ? FormHint.goDeeper : FormHint.none;
          if (v >= upThreshold) _repStart = t;
        }
        return null;

      case _Phase.down:
        _minInRep = min(_minInRep, v);
        if (v >= looseUp) {
          _phase = _Phase.rising;
          _maxOnRise = v;
          _riseStart = t;
          if (v >= upThreshold) return _finish(t);
        }
        hint = FormHint.none;
        return null;

      case _Phase.rising:
        _maxOnRise = max(_maxOnRise, v);
        if (v >= upThreshold ||
            v < looseUp - 5 ||
            t - _riseStart >= settleTime) {
          final e = _finish(t);
          // Se ha già ripreso a scendere, la prossima rep parte da qui.
          if (v < downThreshold) {
            _phase = _Phase.down;
            _minInRep = v;
            _repStart = t;
          }
          return e;
        }
        return null;
    }
  }

  RepEvent? _finish(Duration t) {
    _phase = _Phase.up;
    final start = _repStart ?? t;
    _repStart = t;
    if (t - start < minRepDuration) {
      hint = FormHint.none;
      return null;
    }
    final fullExtension = _maxOnRise >= upThreshold;
    final deep = _minInRep <= perfectDown;
    final quality = deep && fullExtension
        ? RepQuality.perfect
        : (fullExtension || deep ? RepQuality.good : RepQuality.poor);
    hint = fullExtension ? FormHint.none : FormHint.extendFully;
    count++;
    return RepEvent(quality);
  }
}

enum _Phase { up, down, rising }

/// Plank: conta i secondi tenuti con il corpo allineato.
class HoldCounter {
  HoldCounter({this.minBodyAngle = 155});

  final double minBodyAngle;
  Duration held = Duration.zero;
  Duration? _last;
  bool holding = false;
  FormHint hint = FormHint.notVisible;

  void add(PoseFrame frame) {
    final body = frame.bilateral(
      frame.angle(Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle),
      frame.angle(Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle),
    );
    final ok = body != null && body >= minBodyAngle;
    if (ok && holding && _last != null) held += frame.timestamp - _last!;
    holding = ok;
    hint = body == null
        ? FormHint.notVisible
        : (ok ? FormHint.none : FormHint.extendFully);
    _last = frame.timestamp;
  }
}

/// Affondi: due contatori sul ginocchio, uno per gamba. Conta la gamba
/// davanti, quella che si piega di più.
class LungeCounter {
  final AngleRepCounter left = _knee(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle);
  final AngleRepCounter right =
      _knee(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle);

  static AngleRepCounter _knee(Joint hip, Joint knee, Joint ankle) =>
      AngleRepCounter(
        measure: (f) => f.angle(hip, knee, ankle),
        requiredJoints: [hip, knee, ankle],
        downThreshold: 105,
        perfectDown: 95,
        upThreshold: 160,
        looseUp: 145,
      );

  int get count => min(left.count, right.count);

  RepEvent? add(PoseFrame frame) {
    final l = frame.angle(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle);
    final r = frame.angle(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle);
    // Solo la gamba più piegata avanza il proprio contatore.
    if (l != null && r != null && l < r) {
      final e = left.add(frame);
      return e == null ? null : RepEvent(e.quality, side: 'L');
    }
    final e = right.add(frame);
    return e == null ? null : RepEvent(e.quality, side: 'R');
  }
}

/// Costruisce il contatore giusto per l'esercizio.
///
/// Soglie iniziali da calibrare sul prototipo (obiettivo: errore < 5%).
AngleRepCounter counterFor(ExerciseId id, {double smoothing = 0.5}) {
  switch (id) {
    case ExerciseId.pushUp:
      return AngleRepCounter(
        measure: (f) => f.bilateral(
          f.angle(Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist),
          f.angle(Joint.rightShoulder, Joint.rightElbow, Joint.rightWrist),
        ),
        requiredJoints: const [Joint.leftShoulder, Joint.leftElbow, Joint.leftWrist],
        downThreshold: 100,
        perfectDown: 85,
        upThreshold: 155,
        looseUp: 140,
        smoothing: smoothing,
      );
    case ExerciseId.squat:
      return AngleRepCounter(
        measure: (f) => f.bilateral(
          f.angle(Joint.leftHip, Joint.leftKnee, Joint.leftAnkle),
          f.angle(Joint.rightHip, Joint.rightKnee, Joint.rightAnkle),
        ),
        requiredJoints: const [Joint.leftHip, Joint.leftKnee, Joint.leftAnkle],
        downThreshold: 110,
        perfectDown: 95,
        upThreshold: 160,
        looseUp: 145,
        smoothing: smoothing,
      );
    case ExerciseId.crunch:
      // Angolo spalla-anca-ginocchio: si chiude quando il busto sale.
      return AngleRepCounter(
        measure: (f) => f.bilateral(
          f.angle(Joint.leftShoulder, Joint.leftHip, Joint.leftKnee),
          f.angle(Joint.rightShoulder, Joint.rightHip, Joint.rightKnee),
        ),
        requiredJoints: const [Joint.leftShoulder, Joint.leftHip, Joint.leftKnee],
        downThreshold: 100,
        perfectDown: 80,
        upThreshold: 125,
        looseUp: 115,
        smoothing: smoothing,
      );
    case ExerciseId.legRaise:
      // Angolo spalla-anca-caviglia: da ~180 (sdraiato) a ~90 (gambe su).
      return AngleRepCounter(
        measure: (f) => f.bilateral(
          f.angle(Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle),
          f.angle(Joint.rightShoulder, Joint.rightHip, Joint.rightAnkle),
        ),
        requiredJoints: const [Joint.leftShoulder, Joint.leftHip, Joint.leftAnkle],
        downThreshold: 120,
        perfectDown: 100,
        upThreshold: 160,
        looseUp: 145,
        smoothing: smoothing,
      );
    case ExerciseId.jumpingJack:
      // Angolo di lavoro = 180 − apertura delle braccia: basso a braccia su.
      return AngleRepCounter(
        measure: (f) {
          final arms = f.bilateral(
            f.angle(Joint.leftHip, Joint.leftShoulder, Joint.leftWrist),
            f.angle(Joint.rightHip, Joint.rightShoulder, Joint.rightWrist),
          );
          return arms == null ? null : 180 - arms;
        },
        requiredJoints: const [Joint.leftHip, Joint.leftShoulder, Joint.leftWrist],
        downThreshold: 50,
        perfectDown: 30,
        upThreshold: 150,
        looseUp: 130,
        minRepDuration: const Duration(milliseconds: 250),
        smoothing: smoothing,
      );
    case ExerciseId.lunge:
    case ExerciseId.plank:
      throw ArgumentError('Usa LungeCounter / HoldCounter per $id');
  }
}

/// Facciata unica usata dalle schermate.
class ExerciseTracker {
  ExerciseTracker(this.exercise)
      : _angle = (exercise == ExerciseId.lunge || exercise == ExerciseId.plank)
            ? null
            : counterFor(exercise),
        _lunge = exercise == ExerciseId.lunge ? LungeCounter() : null,
        _hold = exercise == ExerciseId.plank ? HoldCounter() : null;

  final ExerciseId exercise;
  final AngleRepCounter? _angle;
  final LungeCounter? _lunge;
  final HoldCounter? _hold;

  bool get isHold => _hold != null;
  Duration get held => _hold?.held ?? Duration.zero;
  bool get holding => _hold?.holding ?? false;

  FormHint get hint =>
      _angle?.hint ?? _hold?.hint ?? (_lunge != null ? _lunge.left.hint : FormHint.none);

  /// Rep complete (per gli affondi: coppie gamba sinistra + destra).
  int get count => _angle?.count ?? _lunge?.count ?? 0;

  RepEvent? add(PoseFrame frame) {
    if (_hold != null) {
      _hold.add(frame);
      return null;
    }
    return _angle?.add(frame) ?? _lunge?.add(frame);
  }
}
