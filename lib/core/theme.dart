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
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_r(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
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
}

/// Linea sottile oro sotto la barra del titolo.
class _GoldUnderline extends ShapeBorder {
  const _GoldUnderline();
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 1);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.3,
          colors: [Color(0xFF2A2116), Color(0xFF15110C), Palette.night],
          stops: [0, 0.45, 1],
        ),
      ),
      child: child,
    );
  }
}

TextStyle titleStyle({
  double size = 20,
  Color color = Palette.goldBright,
  double spacing = 2,
}) => TextStyle(
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
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kBodyFont,
  );
  final text = base.textTheme
      .apply(bodyColor: Palette.holy, displayColor: Palette.holy)
      .copyWith(
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          color: Palette.holy,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 17,
          color: Palette.holy,
        ),
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
      backgroundColor: const Color(0xFF0F0C09),
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
          color: s.contains(WidgetState.selected)
              ? Palette.goldBright
              : Palette.ash,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Palette.goldBright
              : Palette.ash,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.gold,
        foregroundColor: Palette.night,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
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
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
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
        textStyle: const TextStyle(
          fontFamily: kTitleFont,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Palette.stone,
      shape: GildedBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(
      contentTextStyle: TextStyle(
        fontFamily: kBodyFont,
        fontSize: 16,
        color: Palette.holy,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.gold,
      linearTrackColor: Palette.iron,
    ),
    dividerTheme: const DividerThemeData(color: Palette.iron),
  );
}
