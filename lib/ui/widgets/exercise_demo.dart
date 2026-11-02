import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/art.dart';
import '../../core/theme.dart';
import '../../domain/exercise.dart';

/// Movimenti con una dimostrazione: due fotogrammi (su e giù) che si
/// alternano, come su Gymscape. Le illustrazioni arrivano da Antigravity
/// (`assets/art/demos/<movimento>_a.png` e `_b.png`); fino ad allora un
/// cavaliere stilizzato fa il movimento.
enum DemoMove {
  pushUp,
  kneePushUp,
  inclinePushUp,
  pikePushUp,
  dip,
  floorPress,
  row,
  superman,
  crunch,
  legRaise,
  plank,
  vUp,
  russianTwist,
  squat,
  lunge,
  gluteBridge,
  stepUp,
  jumpingJack,
  highKnees,
  mountainClimber,
  burpee,
  jumpSquat,
  forwardFold,
  lungeHold,
  butterfly,
  cobra,
  childPose,
  seatedTwist;

  /// Nome del file: push_up, knee_push_up...
  String get file => name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}

/// Il movimento da mostrare per un esercizio, dal nome che vede il
/// giocatore; se non lo riconosce, dall'esercizio base.
DemoMove demoFor(String name, ExerciseId trackAs) {
  final n = _italianName(name).toLowerCase();
  const byWord = [
    ('affondi saltati', DemoMove.lunge),
    ('skater', DemoMove.jumpingJack),
    ('gatto', DemoMove.childPose),
    ('spaccata', DemoMove.lungeHold),
    ('piegamento', DemoMove.forwardFold),
    ('affondo statico', DemoMove.lungeHold),
    ('piccione', DemoMove.lungeHold),
    ('farfalla', DemoMove.butterfly),
    ('cobra', DemoMove.cobra),
    ('bambino', DemoMove.childPose),
    ('torsione', DemoMove.seatedTwist),
    ('ginocchia piegate', DemoMove.legRaise),
    ('ginocchia', DemoMove.kneePushUp),
    ('inclinat', DemoMove.inclinePushUp),
    ('al muro', DemoMove.inclinePushUp),
    ('pike', DemoMove.pikePushUp),
    ('dip', DemoMove.dip),
    ('floor press', DemoMove.floorPress),
    ('rematore', DemoMove.row),
    ('superman', DemoMove.superman),
    ('snow angel', DemoMove.superman),
    ('russian', DemoMove.russianTwist),
    ('v-up', DemoMove.vUp),
    ('crunch', DemoMove.crunch),
    ('leg raise', DemoMove.legRaise),
    ('plank', DemoMove.plank),
    ('ponte', DemoMove.gluteBridge),
    ('step-up', DemoMove.stepUp),
    ('jumping jack', DemoMove.jumpingJack),
    ('step jack', DemoMove.jumpingJack),
    ('high knees', DemoMove.highKnees),
    ('mountain', DemoMove.mountainClimber),
    ('burpee', DemoMove.burpee),
    ('jump', DemoMove.jumpSquat),
    ('affondi', DemoMove.lunge),
    ('bulgaro', DemoMove.lunge),
    ('squat', DemoMove.squat),
    ('thruster', DemoMove.squat),
    ('push-up', DemoMove.pushUp),
  ];
  for (final (word, move) in byWord) {
    if (n.contains(word)) return move;
  }
  return switch (trackAs) {
    ExerciseId.pushUp => DemoMove.pushUp,
    ExerciseId.crunch => DemoMove.crunch,
    ExerciseId.legRaise => DemoMove.legRaise,
    ExerciseId.squat => DemoMove.squat,
    ExerciseId.lunge => DemoMove.lunge,
    ExerciseId.jumpingJack => DemoMove.jumpingJack,
    ExerciseId.highKnees => DemoMove.highKnees,
    ExerciseId.plank => DemoMove.plank,
    ExerciseId.stretch => DemoMove.forwardFold,
  };
}

/// Il nome italiano di un esercizio già tradotto: le parole chiave qui sopra
/// sono in italiano.
String _italianName(String name) {
  if (appLang == Lang.it) return name;
  for (final e in enStrings.entries) {
    if (e.value == name) return e.key;
  }
  return name;
}

/// Riquadro con la dimostrazione che va in loop.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({super.key, required this.move, this.size = 120});
  final DemoMove move;
  final double size;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = 'assets/art/demos/${widget.move.file}_a.png';
    final b = 'assets/art/demos/${widget.move.file}_b.png';
    final art = Art.has(a) && Art.has(b);
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => art
            // Le illustrazioni sono due fotogrammi: si alternano a metà corsa.
            ? Image.asset(_c.value < 0.5 ? a : b, fit: BoxFit.contain, gaplessPlayback: true)
            : CustomPaint(
                painter: DemoPainter(widget.move, Curves.easeInOut.transform(_c.value)),
              ),
      ),
    );
  }
}

/// Posa: testa, spalla, gomito, mano, anca, ginocchio, piede del lato vicino;
/// gomito, mano, ginocchio e piede del lato lontano (se mancano, uguali al
/// vicino, spostati per la prospettiva a 45°).
class _Pose {
  const _Pose(this.p, {this.far, this.mirror = false});
  final List<Offset> p;
  final List<Offset>? far;

  /// Vista di fronte: il lato lontano è lo specchio di quello vicino.
  final bool mirror;
}

const _o = Offset.new;

_Pose _lying(Offset el, Offset ha, Offset kn, Offset ft,
        {Offset hip = const Offset(0.45, 0.87),
        Offset sh = const Offset(0.72, 0.86),
        Offset head = const Offset(0.82, 0.84)}) =>
    _Pose([head, sh, el, ha, hip, kn, ft]);

const _stand = _Pose([
  Offset(0.5, 0.17),
  Offset(0.5, 0.29),
  Offset(0.52, 0.43),
  Offset(0.53, 0.56),
  Offset(0.5, 0.56),
  Offset(0.51, 0.73),
  Offset(0.5, 0.9),
]);
const _plankHigh = _Pose([
  Offset(0.83, 0.63),
  Offset(0.74, 0.68),
  Offset(0.75, 0.78),
  Offset(0.75, 0.88),
  Offset(0.47, 0.76),
  Offset(0.3, 0.82),
  Offset(0.12, 0.88),
]);
const _squatDown = _Pose([
  Offset(0.47, 0.36),
  Offset(0.46, 0.46),
  Offset(0.6, 0.47),
  Offset(0.72, 0.45),
  Offset(0.36, 0.66),
  Offset(0.56, 0.68),
  Offset(0.5, 0.9),
]);

(_Pose, _Pose, Rect?) _frames(DemoMove m) {
  switch (m) {
    case DemoMove.pushUp:
      return (
        _plankHigh,
        const _Pose([
          Offset(0.84, 0.78),
          Offset(0.74, 0.81),
          Offset(0.66, 0.76),
          Offset(0.75, 0.88),
          Offset(0.47, 0.84),
          Offset(0.3, 0.86),
          Offset(0.12, 0.88),
        ]),
        null
      );
    case DemoMove.kneePushUp:
      return (
        const _Pose([
          Offset(0.83, 0.6),
          Offset(0.74, 0.66),
          Offset(0.75, 0.77),
          Offset(0.75, 0.88),
          Offset(0.5, 0.75),
          Offset(0.35, 0.88),
          Offset(0.18, 0.8),
        ]),
        const _Pose([
          Offset(0.84, 0.77),
          Offset(0.74, 0.8),
          Offset(0.66, 0.75),
          Offset(0.75, 0.88),
          Offset(0.5, 0.81),
          Offset(0.35, 0.88),
          Offset(0.18, 0.8),
        ]),
        null
      );
    case DemoMove.inclinePushUp:
      return (
        const _Pose([
          Offset(0.77, 0.52),
          Offset(0.68, 0.58),
          Offset(0.7, 0.65),
          Offset(0.72, 0.72),
          Offset(0.44, 0.73),
          Offset(0.28, 0.82),
          Offset(0.12, 0.9),
        ]),
        const _Pose([
          Offset(0.79, 0.64),
          Offset(0.7, 0.68),
          Offset(0.62, 0.64),
          Offset(0.72, 0.72),
          Offset(0.45, 0.78),
          Offset(0.28, 0.85),
          Offset(0.12, 0.9),
        ]),
        const Rect.fromLTRB(0.66, 0.72, 0.9, 0.9)
      );
    case DemoMove.pikePushUp:
      return (
        const _Pose([
          Offset(0.67, 0.8),
          Offset(0.62, 0.7),
          Offset(0.66, 0.8),
          Offset(0.7, 0.9),
          Offset(0.45, 0.5),
          Offset(0.33, 0.72),
          Offset(0.25, 0.9),
        ]),
        const _Pose([
          Offset(0.69, 0.87),
          Offset(0.63, 0.78),
          Offset(0.58, 0.8),
          Offset(0.7, 0.9),
          Offset(0.45, 0.56),
          Offset(0.33, 0.74),
          Offset(0.25, 0.9),
        ]),
        null
      );
    case DemoMove.dip:
      return (
        const _Pose([
          Offset(0.42, 0.32),
          Offset(0.38, 0.42),
          Offset(0.37, 0.52),
          Offset(0.35, 0.62),
          Offset(0.44, 0.62),
          Offset(0.66, 0.62),
          Offset(0.8, 0.9),
        ]),
        const _Pose([
          Offset(0.44, 0.45),
          Offset(0.4, 0.55),
          Offset(0.28, 0.55),
          Offset(0.35, 0.62),
          Offset(0.45, 0.76),
          Offset(0.66, 0.7),
          Offset(0.8, 0.9),
        ]),
        const Rect.fromLTRB(0.14, 0.62, 0.36, 0.9)
      );
    case DemoMove.floorPress:
      return (
        _lying(_o(0.72, 0.72), _o(0.72, 0.6), _o(0.3, 0.72), _o(0.2, 0.88)),
        _lying(_o(0.63, 0.86), _o(0.67, 0.75), _o(0.3, 0.72), _o(0.2, 0.88)),
        null
      );
    case DemoMove.row:
      return (
        const _Pose([
          Offset(0.74, 0.38),
          Offset(0.65, 0.42),
          Offset(0.66, 0.56),
          Offset(0.67, 0.7),
          Offset(0.4, 0.52),
          Offset(0.45, 0.7),
          Offset(0.42, 0.9),
        ]),
        const _Pose([
          Offset(0.74, 0.38),
          Offset(0.65, 0.42),
          Offset(0.55, 0.38),
          Offset(0.6, 0.52),
          Offset(0.4, 0.52),
          Offset(0.45, 0.7),
          Offset(0.42, 0.9),
        ]),
        null
      );
    case DemoMove.superman:
      return (
        _lying(_o(0.82, 0.88), _o(0.92, 0.88), _o(0.3, 0.88), _o(0.15, 0.88),
            sh: _o(0.7, 0.86), head: _o(0.8, 0.84)),
        _lying(_o(0.82, 0.76), _o(0.93, 0.71), _o(0.3, 0.83), _o(0.15, 0.77),
            sh: _o(0.7, 0.81), head: _o(0.8, 0.75)),
        null
      );
    case DemoMove.crunch:
      return (
        _lying(_o(0.82, 0.8), _o(0.84, 0.84), _o(0.33, 0.7), _o(0.22, 0.88)),
        _lying(_o(0.74, 0.66), _o(0.75, 0.72), _o(0.33, 0.7), _o(0.22, 0.88),
            sh: _o(0.66, 0.76), head: _o(0.73, 0.69)),
        null
      );
    case DemoMove.legRaise:
      return (
        _lying(_o(0.6, 0.88), _o(0.5, 0.89), _o(0.3, 0.86), _o(0.15, 0.85)),
        _lying(_o(0.6, 0.88), _o(0.5, 0.89), _o(0.43, 0.68), _o(0.42, 0.5)),
        null
      );
    case DemoMove.plank:
      return (
        const _Pose([
          Offset(0.8, 0.68),
          Offset(0.72, 0.72),
          Offset(0.72, 0.88),
          Offset(0.84, 0.88),
          Offset(0.47, 0.77),
          Offset(0.3, 0.82),
          Offset(0.12, 0.88),
        ]),
        const _Pose([
          Offset(0.8, 0.69),
          Offset(0.72, 0.73),
          Offset(0.72, 0.88),
          Offset(0.84, 0.88),
          Offset(0.47, 0.79),
          Offset(0.3, 0.83),
          Offset(0.12, 0.88),
        ]),
        null
      );
    case DemoMove.vUp:
      return (
        _lying(_o(0.9, 0.86), _o(0.97, 0.86), _o(0.3, 0.86), _o(0.15, 0.85)),
        _lying(_o(0.58, 0.55), _o(0.5, 0.45), _o(0.42, 0.66), _o(0.36, 0.48),
            hip: _o(0.5, 0.87), sh: _o(0.62, 0.66), head: _o(0.66, 0.57)),
        null
      );
    case DemoMove.russianTwist:
      const seat = [Offset(0.58, 0.5), Offset(0.55, 0.6)];
      return (
        const _Pose([
          Offset(0.58, 0.5),
          Offset(0.55, 0.6),
          Offset(0.6, 0.72),
          Offset(0.58, 0.82),
          Offset(0.45, 0.84),
          Offset(0.6, 0.7),
          Offset(0.75, 0.78),
        ]),
        _Pose([
          seat[0],
          seat[1],
          const Offset(0.66, 0.62),
          const Offset(0.74, 0.66),
          const Offset(0.45, 0.84),
          const Offset(0.6, 0.7),
          const Offset(0.75, 0.78),
        ]),
        null
      );
    case DemoMove.squat:
      return (_stand, _squatDown, null);
    case DemoMove.lunge:
      return (
        _stand,
        const _Pose([
          Offset(0.48, 0.28),
          Offset(0.48, 0.39),
          Offset(0.49, 0.52),
          Offset(0.5, 0.64),
          Offset(0.48, 0.66),
          Offset(0.65, 0.72),
          Offset(0.66, 0.9),
        ], far: [
          Offset(0.49, 0.52),
          Offset(0.5, 0.64),
          Offset(0.4, 0.86),
          Offset(0.25, 0.88)
        ]),
        null
      );
    case DemoMove.gluteBridge:
      return (
        _lying(_o(0.6, 0.88), _o(0.5, 0.89), _o(0.38, 0.7), _o(0.32, 0.88),
            hip: _o(0.5, 0.86), sh: _o(0.73, 0.85), head: _o(0.82, 0.86)),
        _lying(_o(0.6, 0.88), _o(0.5, 0.89), _o(0.38, 0.68), _o(0.32, 0.88),
            hip: _o(0.53, 0.68), sh: _o(0.73, 0.83), head: _o(0.82, 0.86)),
        null
      );
    case DemoMove.stepUp:
      return (
        const _Pose([
          Offset(0.44, 0.17),
          Offset(0.43, 0.29),
          Offset(0.44, 0.43),
          Offset(0.45, 0.55),
          Offset(0.42, 0.55),
          Offset(0.55, 0.6),
          Offset(0.6, 0.75),
        ], far: [
          Offset(0.44, 0.43),
          Offset(0.45, 0.55),
          Offset(0.42, 0.72),
          Offset(0.42, 0.9)
        ]),
        const _Pose([
          Offset(0.62, 0.04),
          Offset(0.62, 0.15),
          Offset(0.63, 0.28),
          Offset(0.64, 0.4),
          Offset(0.62, 0.4),
          Offset(0.63, 0.57),
          Offset(0.62, 0.75),
        ], far: [
          Offset(0.63, 0.28),
          Offset(0.64, 0.4),
          Offset(0.7, 0.52),
          Offset(0.65, 0.66)
        ]),
        const Rect.fromLTRB(0.52, 0.75, 0.82, 0.9)
      );
    case DemoMove.jumpingJack:
      return (
        const _Pose([
          Offset(0.5, 0.17),
          Offset(0.5, 0.29),
          Offset(0.56, 0.42),
          Offset(0.57, 0.56),
          Offset(0.5, 0.56),
          Offset(0.53, 0.73),
          Offset(0.54, 0.9),
        ], mirror: true),
        const _Pose([
          Offset(0.5, 0.17),
          Offset(0.5, 0.29),
          Offset(0.62, 0.18),
          Offset(0.6, 0.05),
          Offset(0.5, 0.56),
          Offset(0.58, 0.73),
          Offset(0.66, 0.9),
        ], mirror: true),
        null
      );
    case DemoMove.highKnees:
      const a = _Pose([
        Offset(0.5, 0.17),
        Offset(0.5, 0.29),
        Offset(0.44, 0.41),
        Offset(0.42, 0.52),
        Offset(0.5, 0.56),
        Offset(0.62, 0.52),
        Offset(0.6, 0.7),
      ], far: [
        Offset(0.57, 0.4),
        Offset(0.6, 0.3),
        Offset(0.5, 0.73),
        Offset(0.5, 0.9)
      ]);
      const b = _Pose([
        Offset(0.5, 0.17),
        Offset(0.5, 0.29),
        Offset(0.57, 0.4),
        Offset(0.6, 0.3),
        Offset(0.5, 0.56),
        Offset(0.5, 0.73),
        Offset(0.5, 0.9),
      ], far: [
        Offset(0.44, 0.41),
        Offset(0.42, 0.52),
        Offset(0.62, 0.52),
        Offset(0.6, 0.7)
      ]);
      return (a, b, null);
    case DemoMove.mountainClimber:
      final p = _plankHigh.p;
      return (
        _Pose(p.sublist(0, 5) + const [Offset(0.6, 0.78), Offset(0.5, 0.86)],
            far: [p[2], p[3], p[5], p[6]]),
        _Pose(p, far: [p[2], p[3], const Offset(0.6, 0.78), const Offset(0.5, 0.86)]),
        null
      );
    case DemoMove.burpee:
      return (_stand, _plankHigh, null);
    case DemoMove.forwardFold:
      return (
        const _Pose([
          Offset(0.58, 0.5),
          Offset(0.55, 0.4),
          Offset(0.58, 0.55),
          Offset(0.58, 0.7),
          Offset(0.48, 0.55),
          Offset(0.49, 0.73),
          Offset(0.48, 0.9),
        ]),
        const _Pose([
          Offset(0.55, 0.76),
          Offset(0.53, 0.64),
          Offset(0.54, 0.77),
          Offset(0.53, 0.89),
          Offset(0.47, 0.52),
          Offset(0.48, 0.71),
          Offset(0.48, 0.9),
        ]),
        null
      );
    case DemoMove.lungeHold:
      const low = _Pose([
        Offset(0.5, 0.36),
        Offset(0.5, 0.47),
        Offset(0.6, 0.6),
        Offset(0.66, 0.7),
        Offset(0.49, 0.7),
        Offset(0.66, 0.74),
        Offset(0.68, 0.9),
      ], far: [
        Offset(0.6, 0.6),
        Offset(0.66, 0.7),
        Offset(0.32, 0.88),
        Offset(0.16, 0.9)
      ]);
      const lower = _Pose([
        Offset(0.51, 0.39),
        Offset(0.51, 0.5),
        Offset(0.61, 0.62),
        Offset(0.66, 0.72),
        Offset(0.5, 0.74),
        Offset(0.67, 0.76),
        Offset(0.68, 0.9),
      ], far: [
        Offset(0.61, 0.62),
        Offset(0.66, 0.72),
        Offset(0.32, 0.89),
        Offset(0.15, 0.9)
      ]);
      return (low, lower, null);
    case DemoMove.butterfly:
      return (
        const _Pose([
          Offset(0.5, 0.4),
          Offset(0.5, 0.52),
          Offset(0.56, 0.66),
          Offset(0.53, 0.8),
          Offset(0.5, 0.82),
          Offset(0.66, 0.8),
          Offset(0.52, 0.88),
        ], mirror: true),
        const _Pose([
          Offset(0.5, 0.45),
          Offset(0.5, 0.56),
          Offset(0.56, 0.7),
          Offset(0.53, 0.83),
          Offset(0.5, 0.82),
          Offset(0.7, 0.86),
          Offset(0.52, 0.88),
        ], mirror: true),
        null
      );
    case DemoMove.cobra:
      return (
        _lying(_o(0.74, 0.9), _o(0.79, 0.9), _o(0.3, 0.88), _o(0.15, 0.88),
            sh: _o(0.7, 0.86), head: _o(0.8, 0.84)),
        _lying(_o(0.72, 0.8), _o(0.74, 0.89), _o(0.3, 0.88), _o(0.15, 0.88),
            hip: _o(0.47, 0.86), sh: _o(0.66, 0.7), head: _o(0.74, 0.6)),
        null
      );
    case DemoMove.childPose:
      return (
        const _Pose([
          Offset(0.72, 0.8),
          Offset(0.62, 0.76),
          Offset(0.76, 0.82),
          Offset(0.86, 0.87),
          Offset(0.4, 0.78),
          Offset(0.58, 0.88),
          Offset(0.3, 0.9),
        ]),
        const _Pose([
          Offset(0.74, 0.84),
          Offset(0.63, 0.79),
          Offset(0.78, 0.85),
          Offset(0.89, 0.88),
          Offset(0.39, 0.8),
          Offset(0.58, 0.88),
          Offset(0.3, 0.9),
        ]),
        null
      );
    case DemoMove.seatedTwist:
      return (
        const _Pose([
          Offset(0.5, 0.42),
          Offset(0.5, 0.54),
          Offset(0.58, 0.66),
          Offset(0.62, 0.74),
          Offset(0.45, 0.84),
          Offset(0.62, 0.72),
          Offset(0.62, 0.88),
        ]),
        const _Pose([
          Offset(0.48, 0.42),
          Offset(0.48, 0.54),
          Offset(0.38, 0.62),
          Offset(0.3, 0.78),
          Offset(0.45, 0.84),
          Offset(0.62, 0.72),
          Offset(0.62, 0.88),
        ]),
        null
      );
    case DemoMove.jumpSquat:
      return (
        _squatDown,
        const _Pose([
          Offset(0.5, 0.07),
          Offset(0.5, 0.19),
          Offset(0.54, 0.08),
          Offset(0.56, -0.02),
          Offset(0.5, 0.46),
          Offset(0.52, 0.63),
          Offset(0.5, 0.8),
        ]),
        null
      );
  }
}

/// Cavaliere stilizzato che si muove tra le due pose.
class DemoPainter extends CustomPainter {
  DemoPainter(this.move, this.t);
  final DemoMove move;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final (a, b, prop) = _frames(move);
    Offset lerp(int i) => Offset.lerp(a.p[i], b.p[i], t)!;
    Offset far(int i, int k) {
      if (a.mirror) {
        final o = lerp(i);
        return Offset(1 - o.dx, o.dy);
      }
      final fa = a.far?[k] ?? a.p[i];
      final fb = b.far?[k] ?? b.p[i];
      // Prospettiva a 45°: il lato lontano è un po' più in alto e indietro.
      return Offset.lerp(fa, fb, t)! + const Offset(0.035, -0.025);
    }

    final s = size.shortestSide;
    Offset px(Offset o) => Offset(o.dx * size.width, o.dy * size.height);

    // Pavimento.
    canvas.drawLine(
        px(const Offset(0.05, 0.905)),
        px(const Offset(0.95, 0.905)),
        Paint()
          ..color = Palette.iron
          ..strokeWidth = 2);
    if (prop != null) {
      final r = Rect.fromLTRB(prop.left * size.width, prop.top * size.height,
          prop.right * size.width, prop.bottom * size.height);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s * 0.02)),
          Paint()..color = const Color(0xFF4A3A28));
    }

    Paint limb(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = s * w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    const nearSteel = Color(0xFF9DA3AB);
    const farSteel = Color(0xFF5E636A);
    void chain(List<Offset> pts, Paint p) {
      final path = Path()..moveTo(px(pts[0]).dx, px(pts[0]).dy);
      for (final q in pts.skip(1)) {
        path.lineTo(px(q).dx, px(q).dy);
      }
      canvas.drawPath(path, p);
    }

    final head = lerp(0), sh = lerp(1), hip = lerp(4);
    // Lato lontano, più scuro.
    chain([hip, far(5, 2), far(6, 3)], limb(farSteel, 0.07));
    chain([sh, far(2, 0), far(3, 1)], limb(farSteel, 0.055));
    // Busto con il giaco imbottito.
    chain([sh, hip], limb(const Color(0xFF6B5A44), 0.13));
    chain([sh, hip], limb(Palette.gold.withValues(alpha: 0.5), 0.13)..strokeWidth = 1.2);
    // Lato vicino.
    chain([hip, lerp(5), lerp(6)], limb(nearSteel, 0.075));
    chain([sh, lerp(2), lerp(3)], limb(nearSteel, 0.06));
    canvas.drawCircle(px(lerp(3)), s * 0.035, Paint()..color = const Color(0xFF3A2416));
    // Elmo con la fessura che brilla.
    final hc = px(head);
    canvas.drawCircle(hc, s * 0.065, Paint()..color = nearSteel);
    canvas.drawCircle(
        hc,
        s * 0.065,
        Paint()
          ..color = Palette.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    final facing = (head.dx - sh.dx).abs() > 0.03 ? (head.dx > sh.dx ? 1.0 : -1.0) : 1.0;
    canvas.drawLine(
        hc + Offset(s * 0.005 * facing, -s * 0.005),
        hc + Offset(s * 0.055 * facing, -s * 0.012),
        Paint()
          ..color = const Color(0xFFFFC75A)
          ..strokeWidth = s * 0.014
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(DemoPainter old) => old.t != t || old.move != move;
}
