import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../screens/guide_screen.dart';
import '../screens/settings_screen.dart';

/// La barra di ogni schermata, una riga sola per lasciare spazio al
/// contenuto: a sinistra indietro (o l'elmo), al centro il nome della
/// sezione fra due fregi nel suo colore, a destra rune, guida e impostazioni.
class OathBar extends StatelessWidget implements PreferredSizeWidget {
  const OathBar({super.key, required this.title, this.actions, this.bottom, this.tools = true, this.accent});

  /// Nome della sezione (Raccolta, Mercato...).
  final Widget title;

  /// Mostrati a destra, prima di guida e impostazioni, come le rune nel Mercato.
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// Guida e impostazioni; spenti nelle loro stesse schermate.
  final bool tools;

  /// Colore della sezione per il nome e i fregi.
  final Color? accent;

  static const double _top = 54;

  @override
  Size get preferredSize => Size.fromHeight(_top + 3 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final color = accent ?? Palette.gold;
    final name = DefaultTextStyle(
      style: titleStyle(size: 15, spacing: 2.6, color: accent ?? Palette.holy).copyWith(
        shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
      ),
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.center,
      child: title,
    );
    final right = [
      if (actions != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Palette.stone,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Palette.gold.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ),
      if (tools) ...[
        const SizedBox(width: 6),
        BarButton(
          icon: Icons.menu_book_outlined,
          tooltip: tr('Guida'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GuideScreen()),
          ),
        ),
        const SizedBox(width: 6),
        BarButton(
          icon: Icons.settings_outlined,
          tooltip: tr('Impostazioni'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xF2120E0A), Color(0xE6191410)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _top,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (canPop)
                        BarButton(
                          icon: Icons.arrow_back,
                          tooltip: tr('Indietro'),
                          onTap: () => Navigator.of(context).maybePop(),
                        )
                      else
                        Image.asset('assets/images/logo_helmet.png', height: 30),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 34, child: _Flourish(flip: true, color: color)),
                            const SizedBox(width: 8),
                            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: name)),
                            const SizedBox(width: 8),
                            SizedBox(width: 34, child: _Flourish(color: color)),
                          ],
                        ),
                      ),
                      ...right,
                    ],
                  ),
                ),
              ),
              const _GoldRule(),
              ?bottom,
            ],
          ),
        ),
      ),
    );
  }
}

/// Doppio filo dorato sotto la barra.
class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) => Container(
        height: 3,
        decoration: BoxDecoration(
          border: Border(
            top: const BorderSide(color: Palette.gold, width: 1),
            bottom: BorderSide(color: Palette.gold.withValues(alpha: 0.4), width: 1),
          ),
        ),
      );
}

/// Fregio: un filo che sfuma verso l'esterno con un rombo accanto al titolo.
class _Flourish extends StatelessWidget {
  const _Flourish({this.flip = false, this.color = Palette.gold});
  final bool flip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: flip ? [Colors.transparent, color] : [color, Colors.transparent],
          ),
        ),
      ),
    );
    final gem = Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
        ),
      ),
    );
    final dot = Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final parts = [line, const SizedBox(width: 4), dot, const SizedBox(width: 4), gem];
    return Row(children: flip ? parts : parts.reversed.toList());
  }
}

/// Tasto tondo grigio della barra: si vede che si può premere.
class BarButton extends StatelessWidget {
  const BarButton({super.key, required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF3A3632),
        shape: CircleBorder(side: BorderSide(color: Palette.ash.withValues(alpha: 0.35))),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 19, color: Palette.holy),
          ),
        ),
      ),
    );
  }
}
