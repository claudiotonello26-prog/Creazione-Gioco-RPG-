import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/character.dart';
import '../../domain/items.dart';

/// Forma dell'arma da disegnare.
enum WeaponShape { sword, greatsword, hammer, bow, staff }

WeaponShape shapeOf(WeaponDef d) {
  if (d.style == WeaponStyle.ranged) return WeaponShape.bow;
  if (d.style == WeaponStyle.magic) return WeaponShape.staff;
  if (d.id.contains('hammer')) return WeaponShape.hammer;
  return d.heavy ? WeaponShape.greatsword : WeaponShape.sword;
}

/// Colore della lama: acciaio a +0, si tinge a +3, si accende a +6, brilla
/// con l'aura completa a +10.
Color bladeColor(WeaponInstance w) {
  const steel = Color(0xFFB9BEC6);
  final a = w.def.affinity.color;
  return switch (w.visualTier) {
    0 => steel,
    1 => Color.lerp(steel, a, 0.4)!,
    2 => Color.lerp(steel, a, 0.75)!,
    _ => a,
  };
}

/// Il cavaliere in piedi con l'arma, disegnato a vettori finché non arrivano
/// le illustrazioni di Antigravity (assets/art/knight/knight_sN_idle.png).
class KnightView extends StatelessWidget {
  const KnightView({super.key, required this.character, this.height = 300});
  final Character character;
  final double height;

  @override
  Widget build(BuildContext context) {
    final stage = (character.level ~/ 10 + 1).clamp(1, 5);
    final painted = CustomPaint(
      size: Size(height * 0.8, height),
      painter: KnightPainter(
        weapon: character.weapon,
        armorLook: character.armor?.look ?? -1,
      ),
    );
    return SizedBox(
      height: height,
      width: height * 0.8,
      child: Image.asset(
        'assets/art/knight/knight_s${stage}_idle.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => painted,
      ),
    );
  }
}

class KnightPainter extends CustomPainter {
  KnightPainter({required this.weapon, required this.armorLook});

  final WeaponInstance weapon;

  /// -1 tunica, 0 stoffa imbottita, 1 maglia, 2 piastre.
  final int armorLook;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final tier = weapon.visualTier;
    final aff = weapon.def.affinity;

    // Luce a terra e aura alle spalle.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.965), width: w * 0.8, height: h * 0.06),
      Paint()
        ..color = Palette.gold.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    if (tier >= 2) {
      canvas.drawCircle(
        Offset(cx, h * 0.5),
        w * (tier == 3 ? 0.55 : 0.42),
        Paint()
          ..color = aff.color.withValues(alpha: tier == 3 ? 0.28 : 0.14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }

    final steel = switch (armorLook) {
      2 => const Color(0xFF9DA3AB),
      1 => const Color(0xFF7D8288),
      0 => const Color(0xFF6B5A44),
      _ => const Color(0xFF4E4236),
    };
    final dark = Color.lerp(steel, Colors.black, 0.55)!;
    final trim = armorLook >= 2 ? Palette.goldBright : Palette.gold.withValues(alpha: 0.7);
    Paint fill(Color c) => Paint()..color = c;
    Paint shade(Rect r, Color c) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color.lerp(c, Colors.black, 0.45)!, Color.lerp(c, Colors.white, 0.25)!, c,
          Color.lerp(c, Colors.black, 0.55)!],
        stops: const [0, 0.35, 0.6, 1],
      ).createShader(r);
    final line = Paint()
      ..color = trim
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.008;

    // Mantello.
    final cape = Path()
      ..moveTo(cx - w * 0.2, h * 0.27)
      ..quadraticBezierTo(cx - w * 0.36, h * 0.65, cx - w * 0.3, h * 0.93)
      ..lineTo(cx + w * 0.3, h * 0.93)
      ..quadraticBezierTo(cx + w * 0.36, h * 0.65, cx + w * 0.2, h * 0.27)
      ..close();
    canvas.drawPath(cape, fill(const Color(0xFF4A1612)));
    canvas.drawPath(
        cape,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x99000000)],
          ).createShader(Rect.fromLTWH(0, h * 0.27, w, h * 0.66)));

    // Gambe e schinieri.
    for (final side in [-1, 1]) {
      final r = Rect.fromLTWH(cx + side * w * 0.085 - w * 0.065, h * 0.62, w * 0.13, h * 0.3);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * 0.03)), shade(r, steel));
      canvas.drawCircle(Offset(r.center.dx, h * 0.72), w * 0.04, shade(r, steel));
      canvas.drawCircle(Offset(r.center.dx, h * 0.72), w * 0.04, line);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left - w * 0.01, h * 0.9, r.width + w * 0.03, h * 0.04),
              Radius.circular(w * 0.02)),
          fill(dark));
    }

    // Busto.
    final torsoRect = Rect.fromLTWH(cx - w * 0.19, h * 0.27, w * 0.38, h * 0.38);
    final torso = Path()
      ..moveTo(cx - w * 0.19, h * 0.29)
      ..lineTo(cx + w * 0.19, h * 0.29)
      ..lineTo(cx + w * 0.16, h * 0.55)
      ..lineTo(cx + w * 0.2, h * 0.66)
      ..lineTo(cx - w * 0.2, h * 0.66)
      ..lineTo(cx - w * 0.16, h * 0.55)
      ..close();
    canvas.drawPath(torso, shade(torsoRect, steel));
    if (armorLook == 1) {
      // Anelli della maglia.
      final ring = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.save();
      canvas.clipPath(torso);
      for (var y = h * 0.29; y < h * 0.66; y += w * 0.025) {
        for (var x = cx - w * 0.2; x < cx + w * 0.2; x += w * 0.03) {
          canvas.drawArc(Rect.fromCircle(center: Offset(x, y), radius: w * 0.014), 0, pi, false, ring);
        }
      }
      canvas.restore();
    }
    if (armorLook >= 2) {
      // Croce templare sul pettorale.
      final cross = Paint()..color = const Color(0xFF9E2B25);
      canvas.drawRect(Rect.fromLTWH(cx - w * 0.022, h * 0.33, w * 0.044, h * 0.2), cross);
      canvas.drawRect(Rect.fromLTWH(cx - w * 0.09, h * 0.38, w * 0.18, h * 0.04), cross);
    }
    canvas.drawPath(torso, line);
    // Cintura.
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.17, h * 0.555, w * 0.34, h * 0.03), fill(const Color(0xFF3A2A1A)));
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.025, h * 0.552, w * 0.05, h * 0.036), fill(trim));

    // Braccia e spallacci.
    for (final side in [-1, 1]) {
      final arm = Rect.fromLTWH(cx + side * w * 0.235 - w * 0.055, h * 0.3, w * 0.11, h * 0.26);
      canvas.drawRRect(RRect.fromRectAndRadius(arm, Radius.circular(w * 0.04)), shade(arm, steel));
      final pauldron = Rect.fromCenter(
          center: Offset(cx + side * w * 0.215, h * 0.3), width: w * 0.2, height: h * 0.1);
      canvas.drawOval(pauldron, shade(pauldron, steel));
      canvas.drawArc(pauldron, pi, pi, false, line);
    }

    // Arma: spade e martello piantati davanti, arco e bastone di lato.
    _weapon(canvas, size);

    // Mani sul pomolo.
    for (final side in [-1, 1]) {
      canvas.drawCircle(Offset(cx + side * w * 0.035, h * 0.555), w * 0.04, fill(dark));
    }

    // Elmo (armet con visiera a becco, come l'icona).
    _helm(canvas, Offset(cx, h * 0.17), w * 0.2, steel, trim);
  }

  void _helm(Canvas canvas, Offset c, double r, Color steel, Color trim) {
    final rect = Rect.fromCircle(center: c, radius: r);
    final dome = Path()
      ..moveTo(c.dx, c.dy - r * 1.25)
      ..cubicTo(c.dx + r * 0.25, c.dy - r * 0.9, c.dx + r * 0.95, c.dy - r * 0.75, c.dx + r * 0.95, c.dy)
      ..lineTo(c.dx + r * 0.85, c.dy + r * 0.7)
      ..lineTo(c.dx, c.dy + r * 1.1)
      ..lineTo(c.dx - r * 0.85, c.dy + r * 0.7)
      ..lineTo(c.dx - r * 0.95, c.dy)
      ..cubicTo(c.dx - r * 0.95, c.dy - r * 0.75, c.dx - r * 0.25, c.dy - r * 0.9, c.dx, c.dy - r * 1.25)
      ..close();
    canvas.drawPath(
        dome,
        Paint()
          ..shader = LinearGradient(colors: [
            Color.lerp(steel, Colors.black, 0.4)!,
            Color.lerp(steel, Colors.white, 0.35)!,
            Color.lerp(steel, Colors.black, 0.5)!,
          ]).createShader(rect));
    final line = Paint()
      ..color = trim
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dome, line);
    canvas.drawLine(Offset(c.dx, c.dy - r * 1.25), Offset(c.dx, c.dy + r * 1.1), line);
    // Fessure degli occhi con bagliore.
    final eye = Paint()..color = const Color(0xFFFFC75A);
    final glow = Paint()
      ..color = const Color(0xFFFF9A3D).withValues(alpha: 0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12);
    for (final side in [-1, 1]) {
      final slit = Path()
        ..moveTo(c.dx + side * r * 0.12, c.dy + r * 0.12)
        ..lineTo(c.dx + side * r * 0.78, c.dy - r * 0.02)
        ..lineTo(c.dx + side * r * 0.78, c.dy + r * 0.1)
        ..lineTo(c.dx + side * r * 0.12, c.dy + r * 0.24)
        ..close();
      canvas.drawPath(slit, glow);
      canvas.drawPath(slit, eye);
      // Fori di respirazione.
      for (var i = 0; i < 3; i++) {
        for (var j = 0; j < 2; j++) {
          canvas.drawCircle(Offset(c.dx + side * r * (0.22 + j * 0.18), c.dy + r * (0.42 + i * 0.16)),
              r * 0.035, Paint()..color = Colors.black.withValues(alpha: 0.7));
        }
      }
    }
  }

  void _weapon(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2;
    final tier = weapon.visualTier;
    final aff = weapon.def.affinity;
    final color = bladeColor(weapon);
    final shape = shapeOf(weapon.def);
    final metal = Paint()..color = color;
    final hilt = Paint()..color = Palette.gold;
    final grip = Paint()..color = const Color(0xFF3A2416);

    Path blade;
    switch (shape) {
      case WeaponShape.sword:
      case WeaponShape.greatsword:
        final bw = shape == WeaponShape.greatsword ? w * 0.075 : w * 0.05;
        blade = Path()
          ..moveTo(cx - bw / 2, h * 0.6)
          ..lineTo(cx + bw / 2, h * 0.6)
          ..lineTo(cx + bw / 2, h * 0.9)
          ..lineTo(cx, h * 0.96)
          ..lineTo(cx - bw / 2, h * 0.9)
          ..close();
        _aura(canvas, blade, aff, tier, w);
        canvas.drawPath(blade, metal);
        canvas.drawLine(Offset(cx, h * 0.6), Offset(cx, h * 0.93),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.35)
              ..strokeWidth = 1.2);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.13, h * 0.585, w * 0.26, h * 0.022), hilt);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.02, h * 0.5, w * 0.04, h * 0.085), grip);
        canvas.drawCircle(Offset(cx, h * 0.495), w * 0.028, hilt);
      case WeaponShape.hammer:
        blade = Path()..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w * 0.12, h * 0.84, w * 0.24, h * 0.1), Radius.circular(w * 0.02)));
        _aura(canvas, blade, aff, tier, w);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.02, h * 0.5, w * 0.04, h * 0.36), grip);
        canvas.drawPath(blade, metal);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.12, h * 0.875, w * 0.24, h * 0.012), hilt);
      case WeaponShape.staff:
        final x = cx + w * 0.33;
        canvas.drawRect(Rect.fromLTWH(x - w * 0.015, h * 0.2, w * 0.03, h * 0.74), grip);
        blade = Path()..addOval(Rect.fromCircle(center: Offset(x, h * 0.18), radius: w * 0.05));
        _aura(canvas, blade, aff, tier, w);
        canvas.drawPath(blade, metal);
        canvas.drawCircle(Offset(x, h * 0.18), w * 0.06,
            Paint()
              ..color = Palette.gold
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case WeaponShape.bow:
        final x = cx + w * 0.33;
        blade = Path()
          ..moveTo(x, h * 0.25)
          ..quadraticBezierTo(x + w * 0.14, h * 0.5, x, h * 0.78);
        final limb = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round;
        _aura(canvas, blade, aff, tier, w, stroke: true);
        canvas.drawPath(blade, limb);
        canvas.drawLine(Offset(x, h * 0.25), Offset(x, h * 0.78),
            Paint()
              ..color = Palette.holy.withValues(alpha: 0.7)
              ..strokeWidth = 1);
    }
  }

  /// Aura dell'arma: bagliore che cresce con il livello, e a +10 i segni
  /// dell'elemento (fiamme, vento, neon, raggi).
  void _aura(Canvas canvas, Path shape, Affinity aff, int tier, double w, {bool stroke = false}) {
    if (tier == 0) return;
    final glow = Paint()
      ..color = aff.glow.withValues(alpha: [0.0, 0.35, 0.6, 0.9][tier])
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, [0.0, 4.0, 8.0, 14.0][tier])
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = w * 0.06;
    canvas.drawPath(shape, glow);
    if (tier < 3) return;
    final b = shape.getBounds();
    final rnd = Random(aff.index);
    final accent = Paint()
      ..color = aff.glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    switch (aff) {
      case Affinity.fire:
        for (var i = 0; i < 7; i++) {
          final x = b.left + rnd.nextDouble() * b.width;
          final y = b.top + rnd.nextDouble() * b.height;
          final flame = Path()
            ..moveTo(x - 4, y + 6)
            ..quadraticBezierTo(x - 6, y - 4, x, y - 14)
            ..quadraticBezierTo(x + 6, y - 4, x + 4, y + 6)
            ..close();
          canvas.drawPath(flame, Paint()..color = const Color(0xFFFF9A3D).withValues(alpha: 0.8));
        }
      case Affinity.wind:
        for (var i = 0; i < 4; i++) {
          final y = b.top + b.height * (0.15 + i * 0.22);
          canvas.drawArc(Rect.fromCenter(center: Offset(b.center.dx, y), width: b.width + 30, height: 12),
              pi * 0.1, pi * 1.3, false, accent);
        }
      case Affinity.arcane:
        canvas.drawPath(
            shape,
            Paint()
              ..color = const Color(0xFF7FF4FF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case Affinity.holy:
        for (var i = 0; i < 12; i++) {
          final a = i * pi / 6;
          final c = b.center;
          canvas.drawLine(c + Offset(cos(a), sin(a)) * (b.shortestSide / 2 + 6),
              c + Offset(cos(a), sin(a)) * (b.longestSide / 2 + 18), accent..strokeWidth = 1);
        }
    }
  }

  @override
  bool shouldRepaint(KnightPainter old) =>
      old.weapon.weaponId != weapon.weaponId ||
      old.weapon.upgrade != weapon.upgrade ||
      old.armorLook != armorLook;
}

/// Solo l'arma, grande, per l'Incantamento: mostra come cambierà.
class WeaponPreview extends StatelessWidget {
  const WeaponPreview({super.key, required this.weapon, this.size = 160});
  final WeaponInstance weapon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: size * 1.6,
          maxHeight: size * 2.4,
          alignment: const Alignment(0, 0.55),
          child: CustomPaint(
            size: Size(size * 1.6, size * 2.4),
            painter: _WeaponOnly(weapon),
          ),
        ),
      ),
    );
  }
}

class _WeaponOnly extends KnightPainter {
  _WeaponOnly(WeaponInstance w) : super(weapon: w, armorLook: -1);

  @override
  void paint(Canvas canvas, Size size) {
    // Arco e bastone sono disegnati di lato: li riporta al centro.
    final side = shapeOf(weapon.def);
    if (side == WeaponShape.bow || side == WeaponShape.staff) {
      canvas.translate(-size.width * 0.33, 0);
    }
    _weapon(canvas, size);
  }
}
