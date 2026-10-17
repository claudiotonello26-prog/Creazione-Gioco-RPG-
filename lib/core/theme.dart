import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Palette dark fantasy: sfondi scuri, un solo accento di luce (oro, fuoco,
/// luce sacra) per leggere bene sul telefono.
class Palette {
  static const night = Color(0xFF0D0B09);
  static const stone = Color(0xFF17130F);
  static const stoneLight = Color(0xFF241E18);
  static const iron = Color(0xFF3A332B);
  static const gold = Color(0xFFC9A24A);
  static const goldBright = Color(0xFFE9C873);
  static const ember = Color(0xFFE0662B);
  static const holy = Color(0xFFF2E3B3);
  static const blood = Color(0xFF9E2B25);
  static const moss = Color(0xFF6E8B4E);
  static const ash = Color(0xFFB3A99B);
  static const frost = Color(0xFF7FA7C9);
}

/// Ogni sezione ha il suo colore, così si capisce subito dove si è: lo usano
/// la barra in alto, l'alone dello sfondo e i pulsanti principali.
class Sections {
  static const home = Palette.gold;
  static const training = Color(0xFFC0433A);
  static const gathering = Color(0xFF7FA85A);
  static const forge = Color(0xFFE0662B);
  static const market = Color(0xFF5FB0A6);
  static const arena = Color(0xFFC0433A);
  static const guild = Color(0xFF6F8FE0);
}

/// Caratteri: Cinzel per titoli e pulsanti (iscrizioni romane), EB Garamond
/// per il testo (libro antico, ma leggibile).
const kTitleFont = 'Cinzel';
const kBodyFont = 'EBGaramond';

/// Bordo dei pannelli: filo di ferro e angoli dorati, come una cornice
/// incisa. Usato da tutte le Card.
class GildedBorder extends ShapeBorder {
  const GildedBorder({this.color = Palette.gold, this.radius = 4});
  final Color color;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  RRect _r(Rect rect) => RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_r(rect.deflate(1)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRRect(_r(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    _ornaments(canvas, rect);
    canvas.drawRRect(
      _r(rect.deflate(0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.28),
    );
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: 0.9);
    final l = (rect.shortestSide * 0.18).clamp(8.0, 18.0);
    final r = rect.deflate(0.8);
    for (final (o, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + dx * l, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + dy * l),
        corner,
      );
      // piccolo rombo inciso vicino all'angolo
      final c = o.translate(dx * 4.5, dy * 4.5);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 2)
          ..lineTo(c.dx + 2, c.dy)
          ..lineTo(c.dx, c.dy + 2)
          ..lineTo(c.dx - 2, c.dy)
          ..close(),
        Paint()..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  ShapeBorder scale(double t) => GildedBorder(color: color, radius: radius * t);

  /// Filo interno e stemmi a metà dei lati lunghi: la cornice di un reliquiario.
  void _ornaments(Canvas canvas, Rect rect) {
    if (rect.width < 120 || rect.height < 44) return;
    canvas.drawRRect(
      _r(rect.deflate(3.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = color.withValues(alpha: 0.13),
    );
    // Luce dall'alto sul bordo superiore.
    final top = Rect.fromLTWH(rect.left, rect.top, rect.width, 14);
    canvas.drawRect(
      top.deflate(1),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0)],
        ).createShader(top),
    );
    final p = Paint()..color = color.withValues(alpha: 0.85);
    final line = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.6);
    for (final y in [rect.top + 0.8, rect.bottom - 0.8]) {
      final cx = rect.center.dx;
      canvas.drawLine(Offset(cx - 22, y), Offset(cx + 22, y), line);
      canvas.drawPath(
        Path()
          ..moveTo(cx, y - 3.5)
          ..lineTo(cx + 3.5, y)
          ..lineTo(cx, y + 3.5)
          ..lineTo(cx - 3.5, y)
          ..close(),
        p,
      );
      for (final dx in [-9.0, 9.0]) {
        canvas.drawCircle(Offset(cx + dx, y), 1.3, p);
      }
    }
  }
}

/// Linea sottile oro sotto la barra del titolo.
class _GoldUnderline extends ShapeBorder {
  const _GoldUnderline();
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 1);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final y = rect.bottom - 0.5;
    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      Paint()
        ..strokeWidth = 1
        ..shader = LinearGradient(
          colors: [
            Palette.gold.withValues(alpha: 0),
            Palette.gold.withValues(alpha: 0.8),
            Palette.gold.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}

/// Sfondo di tutta l'app: notte calda con un alone dorato in alto e i bordi
/// che sfumano nel nero.
class SoulsBackground extends StatelessWidget {
  const SoulsBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: _StonePainter())),
        child,
      ],
    );
  }
}

/// Pietra di cattedrale: lastre appena accennate, granelli, crepe, un alone
/// di fiaccola in alto e i bordi che sprofondano nel buio. Disegnata una
/// volta sola (seme fisso) e tenuta in cache dal RepaintBoundary.
class _StonePainter extends CustomPainter {
  const _StonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.95),
          radius: 1.35,
          colors: [Color(0xFF33271A), Color(0xFF17120D), Palette.night],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    final rnd = math.Random(7);
    // Lastre: file di blocchi sfalsati, con giunti scuri e una luce sul bordo alto.
    const rowH = 92.0;
    final joint = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1.4;
    final lit = Paint()
      ..color = const Color(0x0FE9C873)
      ..strokeWidth = 1;
    for (var y = 0.0, row = 0; y < size.height; y += rowH, row++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), joint);
      canvas.drawLine(Offset(0, y + 1.5), Offset(size.width, y + 1.5), lit);
      var x = row.isOdd ? -60.0 : 0.0;
      while (x < size.width) {
        final w = 110 + rnd.nextDouble() * 70;
        // Ogni blocco un filo più chiaro o più scuro degli altri.
        canvas.drawRect(
          Rect.fromLTWH(x, y + 2, w - 2, rowH - 3),
          Paint()
            ..color = (rnd.nextBool() ? const Color(0xFFFFE6B0) : Colors.black).withValues(
              alpha: 0.012 + rnd.nextDouble() * 0.025,
            ),
        );
        x += w;
        canvas.drawLine(Offset(x, y), Offset(x, y + rowH), joint);
      }
    }
    // Granelli e polvere.
    final grain = Paint();
    for (var i = 0; i < (size.width * size.height / 260).round(); i++) {
      final light = rnd.nextDouble() < 0.4;
      grain.color = (light ? const Color(0xFFE9D7A8) : Colors.black).withValues(
        alpha: light ? 0.035 : 0.12,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.4 + rnd.nextDouble() * 0.9,
        grain,
      );
    }
    // Qualche crepa.
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0x66000000);
    for (var i = 0; i < 7; i++) {
      var p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final path = Path()..moveTo(p.dx, p.dy);
      var a = rnd.nextDouble() * math.pi * 2;
      for (var k = 0; k < 6; k++) {
        a += (rnd.nextDouble() - 0.5) * 1.2;
        p += Offset(math.cos(a), math.sin(a)) * (8 + rnd.nextDouble() * 18);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, crack);
    }
    // Vignetta.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x00000000), Color(0xC0000000)],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

TextStyle titleStyle({double size = 20, Color color = Palette.goldBright, double spacing = 2}) =>
    TextStyle(
      fontFamily: kTitleFont,
      fontWeight: FontWeight.w700,
      fontSize: size,
      letterSpacing: spacing,
      color: color,
    );

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.gold,
    onPrimary: Palette.night,
    secondary: Palette.ember,
    surface: Palette.stone,
    onSurface: Palette.holy,
    error: Palette.blood,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: kBodyFont);
  final text = base.textTheme.apply(bodyColor: Palette.holy, displayColor: Palette.holy).copyWith(
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16, color: Palette.holy),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 17, color: Palette.holy),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Palette.holy,
        ),
        titleLarge: titleStyle(size: 22),
        headlineSmall: titleStyle(size: 24),
        headlineMedium: titleStyle(size: 28),
        labelLarge: const TextStyle(
          fontFamily: kTitleFont,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Palette.stone,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.night.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      foregroundColor: Palette.goldBright,
      centerTitle: true,
      elevation: 0,
      shape: const _GoldUnderline(),
      titleTextStyle: titleStyle(size: 18, spacing: 3),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xE61A1510),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const GildedBorder(),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
        fontFamily: kBodyFont,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Palette.holy,
      ),
      iconColor: Palette.gold,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Palette.gold.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Palette.gold.withValues(alpha: 0.6)),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: kTitleFont,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: s.contains(WidgetState.selected) ? Palette.goldBright : Palette.ash,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Palette.goldBright : Palette.ash,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.gold,
        foregroundColor: Palette.night,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(
          fontFamily: kTitleFont,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 1.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.goldBright,
        side: const BorderSide(color: Palette.gold),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: const BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(
          fontFamily: kTitleFont,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.goldBright,
        textStyle: const TextStyle(fontFamily: kTitleFont, fontWeight: FontWeight.w700),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Palette.stone, shape: GildedBorder()),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.stoneLight,
      contentTextStyle: TextStyle(fontFamily: kBodyFont, fontSize: 16, color: Palette.holy),
      // L'azione è un pulsante oro con la scritta nera: si vede sempre.
      actionTextColor: Palette.night,
      actionBackgroundColor: Palette.goldBright,
      disabledActionTextColor: Palette.ash,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.gold,
      linearTrackColor: Palette.iron,
    ),
    dividerTheme: const DividerThemeData(color: Palette.iron),
  );
}
