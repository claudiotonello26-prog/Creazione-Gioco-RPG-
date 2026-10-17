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
                      size: const Size(190, 130),
                      painter: _ArmPainter(progress: _span(t, 0.03, 0.55), glow: glow),
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
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: _span(t, 0.5, 0.8),
                      child: Image.asset('assets/images/logo_helmet.png', height: 96),
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

/// Un braccio piegato visto di lato, il bicipite in tensione: si disegna
/// come un tratto d'oro.
class _ArmPainter extends CustomPainter {
  _ArmPainter({required this.progress, required this.glow});
  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y * size.height);
    void cubic(Path path, double x1, double y1, double x2, double y2, double x3, double y3) =>
        path.cubicTo(p(x1, y1).dx, p(x1, y1).dy, p(x2, y2).dx, p(x2, y2).dy, p(x3, y3).dx,
            p(x3, y3).dy);
    final start = p(0.04, 0.56);
    final outline = Path()..moveTo(start.dx, start.dy);
    // Spalla e deltoide.
    cubic(outline, 0.06, 0.42, 0.15, 0.38, 0.23, 0.43);
    // Il bicipite, gonfio.
    cubic(outline, 0.3, 0.16, 0.54, 0.18, 0.61, 0.5);
    // Interno dell'avambraccio fino al polso.
    cubic(outline, 0.66, 0.42, 0.66, 0.3, 0.69, 0.21);
    // Il pugno chiuso.
    cubic(outline, 0.62, 0.13, 0.67, 0.0, 0.78, 0.0);
    cubic(outline, 0.9, 0.0, 0.95, 0.13, 0.88, 0.22);
    // Esterno dell'avambraccio, più largo verso il gomito.
    cubic(outline, 0.9, 0.36, 0.98, 0.55, 0.93, 0.7);
    // Gomito.
    cubic(outline, 0.9, 0.82, 0.82, 0.87, 0.7, 0.87);
    // Sotto: il tricipite fino all'ascella.
    cubic(outline, 0.5, 0.91, 0.28, 0.93, 0.04, 0.84);
    final details = Path();
    void stroke(double x0, double y0, double x1, double y1, double x2, double y2) {
      details
        ..moveTo(p(x0, y0).dx, p(x0, y0).dy)
        ..quadraticBezierTo(p(x1, y1).dx, p(x1, y1).dy, p(x2, y2).dx, p(x2, y2).dy);
    }

    // Il pollice che chiude il pugno.
    stroke(0.68, 0.11, 0.74, 0.17, 0.82, 0.16);
    // La piega del gomito e il tricipite.
    stroke(0.38, 0.63, 0.49, 0.68, 0.6, 0.6);
    stroke(0.22, 0.76, 0.38, 0.74, 0.52, 0.8);
    final line = Paint()
      ..color = Palette.goldBright.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + 3 * glow);
    final halo = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFFFFE9A8).withValues(alpha: 0.3 * glow),
        const Color(0x00000000),
      ]).createShader(Rect.fromCircle(center: p(0.5, 0.5), radius: size.width * 0.6));
    canvas.drawCircle(p(0.5, 0.5), size.width * 0.6, halo);
    void drawPart(Path path, double from, double to) {
      final k = ((progress - from) / (to - from)).clamp(0.0, 1.0);
      if (k <= 0) return;
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * k), line);
      }
    }

    drawPart(outline, 0, 0.85);
    drawPart(details, 0.7, 1);
  }

  @override
  bool shouldRepaint(_ArmPainter old) => old.progress != progress || old.glow != glow;
}
