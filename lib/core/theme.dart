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

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.gold,
    onPrimary: Palette.night,
    secondary: Palette.ember,
    surface: Palette.stone,
    onSurface: Palette.holy,
    error: Palette.blood,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.night,
    textTheme: base.textTheme.apply(
      fontFamily: 'serif',
      bodyColor: Palette.holy,
      displayColor: Palette.holy,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.night,
      foregroundColor: Palette.goldBright,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        fontSize: 20,
        letterSpacing: 2,
        color: Palette.goldBright,
      ),
    ),
    cardTheme: CardThemeData(
      color: Palette.stone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Palette.iron),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.stone,
      indicatorColor: Palette.iron,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: Palette.ash),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? Palette.goldBright : Palette.ash,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.gold,
        foregroundColor: Palette.night,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(
            fontFamily: 'serif', fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.goldBright,
        side: const BorderSide(color: Palette.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.gold,
      linearTrackColor: Palette.iron,
    ),
    dividerTheme: const DividerThemeData(color: Palette.iron),
  );
}
