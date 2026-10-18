import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../domain/combat.dart';
import '../../domain/exercise.dart';
import '../../pose/pose_frame.dart';
import '../../pose/rep_counter.dart';
import '../../pose/rep_input.dart';

/// Crea la sorgente di rep giusta in base all'impostazione fotocamera.
RepInput createRepInput(bool useCamera, ExerciseId exercise) =>
    useCamera ? CameraRepInput(exercise) : ManualRepInput(exercise);

String hintText(FormHint h) => switch (h) {
      FormHint.none => '',
      FormHint.notVisible => tr('Mettiti tutto nell\'inquadratura'),
      FormHint.goDeeper => tr('Scendi di più: le mezze rep non contano'),
      FormHint.extendFully => tr('Distenditi del tutto'),
    };

/// Anteprima della fotocamera con lo scheletro sopra, oppure i pulsanti per
/// l'inserimento manuale.
class ExerciseView extends StatelessWidget {
  const ExerciseView({super.key, required this.input, this.overlay});

  final RepInput input;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: input,
      builder: (context, _) {
        final i = input;
        Widget body;
        if (i is CameraRepInput && i.error == null) {
          final c = i.controller;
          if (c == null || !c.value.isInitialized) {
            body = const Center(child: CircularProgressIndicator());
          } else {
            body = _CameraWithSkeleton(controller: c, pose: i.pose);
          }
        } else if (i is ManualRepInput) {
          body = _ManualPad(input: i);
        } else {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '${i.error}\n\n${tr('Puoi passare all\'inserimento manuale dal Profilo.')}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final hint = hintText(i.hint);
        return Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (hint.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Palette.night.withValues(alpha: 0.75),
                  child: Text(hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Palette.goldBright)),
                ),
              ),
            ?overlay,
          ],
        );
      },
    );
  }
}

class _CameraWithSkeleton extends StatelessWidget {
  const _CameraWithSkeleton({required this.controller, required this.pose});
  final CameraController controller;
  final PoseFrame? pose;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    // In verticale l'immagine del sensore è ruotata: larghezza e altezza si
    // scambiano.
    final imageSize =
        preview == null ? const Size(480, 640) : Size(preview.height, preview.width);
    final mirror = controller.description.lensDirection == CameraLensDirection.front;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: imageSize.width,
          height: imageSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              CustomPaint(
                painter: SkeletonPainter(
                  pose: pose,
                  imageSize: imageSize,
                  mirror: mirror && Platform.isAndroid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _bones = [
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

/// Disegna lo scheletro: è anche quello che, nel PvP, anima l'avatar.
class SkeletonPainter extends CustomPainter {
  SkeletonPainter({required this.pose, required this.imageSize, this.mirror = false});

  final PoseFrame? pose;
  final Size imageSize;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose;
    if (p == null) return;
    final sx = size.width / imageSize.width, sy = size.height / imageSize.height;
    Offset map(JointPoint j) =>
        Offset(mirror ? size.width - j.x * sx : j.x * sx, j.y * sy);

    final bone = Paint()
      ..color = Palette.goldBright
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = Palette.ember.withValues(alpha: 0.35)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final (a, b) in _bones) {
      final ja = p[a], jb = p[b];
      if (ja == null || jb == null || ja.likelihood < 0.4 || jb.likelihood < 0.4) {
        continue;
      }
      canvas.drawLine(map(ja), map(jb), glow);
      canvas.drawLine(map(ja), map(jb), bone);
    }
    final dot = Paint()..color = Palette.holy;
    for (final j in p.joints.values) {
      if (j.likelihood >= 0.4) canvas.drawCircle(map(j), 4, dot);
    }
  }

  @override
  bool shouldRepaint(SkeletonPainter old) => old.pose != pose;
}

class _ManualPad extends StatelessWidget {
  const _ManualPad({required this.input});
  final ManualRepInput input;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.stone,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tr('Inserimento manuale'),
            style: const TextStyle(color: Palette.ash, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            tr('Rep non verificate: non valgono per le classifiche.'),
            style: const TextStyle(color: Palette.ash, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (input.isHold)
            FilledButton.icon(
              onPressed: input.toggleHold,
              icon: Icon(input.holding ? Icons.pause : Icons.play_arrow),
              label: Text(input.holding ? tr('Mi fermo') : tr('Tengo la posizione')),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final q in RepQuality.values)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: switch (q) {
                        RepQuality.perfect => Palette.goldBright,
                        RepQuality.good => Palette.gold,
                        RepQuality.poor => Palette.ash,
                      },
                    ),
                    onPressed: () => input.tapRep(q),
                    child: Text(tr('Rep {q}', {'q': q.label.toLowerCase()})),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Grande contatore al centro in alto.
class RepCounterBadge extends StatelessWidget {
  const RepCounterBadge({super.key, required this.text, this.caption});
  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.8),
        border: Border.all(color: Palette.gold),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: Palette.goldBright)),
          if (caption != null)
            Text(caption!, style: const TextStyle(fontSize: 12, color: Palette.ash)),
        ],
      ),
    );
  }
}
