import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/sound.dart';

/// L'apertura: un anello d'oro si traccia, il braccio emerge inciso nella
/// luce, poi GYM OATH sale e l'elmo appare sotto, come una grazia in Elden Ring. Dura 3,5 secondi; un tocco la salta.
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
        ..addListener(_cue)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        })
        ..forward();
  bool _done = false;
  var _cues = 0;

  /// Tre suoni sull'animazione: il braccio che emerge, l'anello che si
  /// chiude, l'elmo che sale.
  void _cue() {
    const at = [0.0, 0.36, 0.5];
    const sounds = [Sfx.splashReveal, Sfx.splashRing, Sfx.splashHelm];
    while (_cues < at.length && _c.value >= at[_cues]) {
      Sound.play(sounds[_cues++]);
    }
  }

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
            // 0,02–0,4 l'anello si disegna e il braccio emerge dal buio come
            // inciso nell'oro · 0,35–0,6 sale la scritta · 0,5–0,8 l'elmo
            // sale da sotto · da 0,88 tutto sfuma.
            final ring = _span(t, 0.02, 0.38);
            final reveal = _span(t, 0.08, 0.42);
            final rise = _span(t, 0.35, 0.62);
            final helm = _span(t, 0.5, 0.8);
            final out = 1 - _span(t, 0.88, 1.0);
            final glow = rise * (0.6 + 0.4 * sin(t * pi * 2.2).abs());
            return Opacity(
              opacity: out,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _RingPainter(progress: ring, glow: glow),
                        child: Padding(
                          padding: const EdgeInsets.all(34),
                          child: ShaderMask(
                            // Una lama di luce attraversa il braccio dal basso a
                            // sinistra verso il pugno e lo lascia acceso.
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (r) => LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: const [Colors.white, Colors.white, Colors.transparent],
                              stops: [
                                0,
                                (reveal * 1.2 - 0.1).clamp(0.0, 1.0),
                                (reveal * 1.2 + 0.05).clamp(0.0, 1.0)
                              ],
                            ).createShader(r),
                            child: Image.asset(
                              'assets/images/arm_gold.png',
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: rise,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - rise)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            // Scritta alla Elden Ring: serif sottile, molto
                            // spaziata, oro che sfuma in luce, alone caldo.
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFF4CF), Palette.goldBright, Color(0xFFB08A3A)],
                                stops: [0, 0.5, 1],
                              ).createShader(r),
                              child: Text(
                                'GYM OATH',
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 54,
                                  letterSpacing: 10 + 6 * rise,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: Palette.goldBright.withValues(alpha: 0.9 * glow),
                                        blurRadius: 22),
                                    Shadow(
                                        color:
                                            const Color(0xFFFFE9A8).withValues(alpha: 0.55 * glow),
                                        blurRadius: 60),
                                  ],
                                ),
                              ),
                            ),
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
                      opacity: helm,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - helm)),
                        child: Transform.scale(
                          scale: 0.9 + 0.1 * helm,
                          child: Image.asset('assets/images/logo_helmet.png', height: 96),
                        ),
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

/// Anello d'oro che si traccia attorno al braccio, con una scintilla in testa
/// e una seconda linea sottile che lo segue.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.glow});
  final double progress;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    const start = pi / 2;
    final sweep = 2 * pi * progress;
    canvas.drawCircle(
      c,
      r + 10,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE9A8).withValues(alpha: 0.18 * progress + 0.12 * glow),
          const Color(0x00000000),
        ]).createShader(Rect.fromCircle(center: c, radius: r + 10)),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Palette.goldBright
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2 + 2 * glow);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, line);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 7),
      start,
      -sweep * 0.98,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Palette.gold.withValues(alpha: 0.55),
    );
    // Quattro rombi cardinali che si accendono quando l'anello li raggiunge.
    for (var k = 0; k < 4; k++) {
      final a = start + k * pi / 2;
      if (sweep < k * pi / 2) continue;
      final o = c + Offset(cos(a), sin(a)) * r;
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(a);
      canvas.drawPath(
        Path()
          ..moveTo(-6, 0)
          ..lineTo(0, -3.5)
          ..lineTo(6, 0)
          ..lineTo(0, 3.5)
          ..close(),
        Paint()..color = Palette.goldBright,
      );
      canvas.restore();
    }
    if (progress < 1) {
      final a = start + sweep;
      final tip = c + Offset(cos(a), sin(a)) * r;
      canvas.drawCircle(
        tip,
        7,
        Paint()
          ..color = const Color(0xFFFFF3C4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(tip, 2.2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.glow != glow;
}
