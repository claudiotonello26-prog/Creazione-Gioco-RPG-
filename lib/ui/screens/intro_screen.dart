import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// L'apertura: buio, poi GYM OATH sale lentamente in oro, come una grazia
/// in Elden Ring. Dura 3,5 secondi; un tocco la salta.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 3500);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: IntroScreen.duration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        })
        ..forward();
  bool _done = false;

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Valore da 0 a 1 nella finestra [a, b] del tempo totale.
  double _span(double t, double a, double b) =>
      Curves.easeInOut.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Material(
        color: Colors.black,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // 0–0,15 buio · fino a 0,6 sale la scritta · poi brilla · da 0,85 sfuma.
            final rise = _span(t, 0.12, 0.6);
            final out = 1 - _span(t, 0.85, 1.0);
            final glow = rise * (0.6 + 0.4 * sin(t * pi * 2.2).abs());
            return Opacity(
              opacity: out,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _GracePainter(progress: _span(t, 0.05, 0.7), glow: glow),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: rise,
                      child: Transform.scale(
                        scale: 0.96 + 0.04 * rise,
                        child: Text(
                          'GYM OATH',
                          style: TextStyle(
                            fontFamily: 'Cinzel',
                            fontSize: 30,
                            letterSpacing: 8 + 3 * rise,
                            color: Palette.goldBright,
                            shadows: [
                              Shadow(color: Palette.goldBright.withValues(alpha: 0.9 * glow), blurRadius: 18),
                              Shadow(color: const Color(0xFFFFE9A8).withValues(alpha: 0.5 * glow), blurRadius: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: _span(t, 0.45, 0.75) * 0.8,
                      child: Container(
                        width: 160 * _span(t, 0.4, 0.75),
                        height: 1,
                        color: Palette.gold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Il simbolo: un anello sottile con una spada verticale, che si disegna.
class _GracePainter extends CustomPainter {
  _GracePainter({required this.progress, required this.glow});
  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.38;
    final halo = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFE9A8).withValues(alpha: 0.35 * glow),
        const Color(0x00000000),
      ]).createShader(Rect.fromCircle(center: c, radius: size.width * 0.6));
    canvas.drawCircle(c, size.width * 0.6, halo);
    final line = Paint()
      ..color = Palette.goldBright.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + 3 * glow);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false, line);
    // Lama verticale e guardia.
    final blade = (progress * 1.4).clamp(0.0, 1.0);
    final top = c.dy - size.height * 0.48;
    final bottom = c.dy + size.height * 0.48;
    canvas.drawLine(Offset(c.dx, top), Offset(c.dx, top + (bottom - top) * blade), line);
    final guard = ((progress - 0.5) * 2).clamp(0.0, 1.0);
    if (guard > 0) {
      final y = c.dy - size.height * 0.12;
      final w = size.width * 0.2 * guard;
      canvas.drawLine(Offset(c.dx - w, y), Offset(c.dx + w, y), line);
    }
  }

  @override
  bool shouldRepaint(_GracePainter old) => old.progress != progress || old.glow != glow;
}
