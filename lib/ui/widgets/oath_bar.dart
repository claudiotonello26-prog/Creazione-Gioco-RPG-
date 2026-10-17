import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../screens/guide_screen.dart';
import '../screens/settings_screen.dart';

/// La barra di ogni schermata: GYM OATH con guida e impostazioni sempre a
/// portata, e sotto il nome della sezione fra due fregi.
class OathBar extends StatelessWidget implements PreferredSizeWidget {
  const OathBar({super.key, required this.title, this.actions, this.bottom, this.tools = true, this.accent});

  /// Nome della sezione (Raccolta, Mercato...).
  final Widget title;

  /// Mostrati a destra del nome della sezione, come le rune nel Mercato.
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// Guida e impostazioni; spenti nelle loro stesse schermate.
  final bool tools;

  /// Colore della sezione per il nome e i fregi.
  final Color? accent;

  static const double _top = 56, _section = 34, _side = 84;

  @override
  Size get preferredSize =>
      Size.fromHeight(_top + _section + 4 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
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
                      // Stessa larghezza a sinistra e a destra: il titolo
                      // resta sempre al centro dello schermo.
                      SizedBox(
                        width: _side,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: canPop
                              ? BarButton(
                                  icon: Icons.arrow_back,
                                  tooltip: 'Indietro',
                                  onTap: () => Navigator.of(context).maybePop(),
                                )
                              : null,
                        ),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: _Brand(),
                        ),
                      ),
                      SizedBox(
                        width: _side,
                        child: tools
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  BarButton(
                                    icon: Icons.menu_book_outlined,
                                    tooltip: 'Guida',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const GuideScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  BarButton(
                                    icon: Icons.settings_outlined,
                                    tooltip: 'Impostazioni',
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const _GoldRule(),
              SizedBox(
                height: _section,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      // Il nome non si allarga oltre il 60%: i due fregi
                      // prendono il resto in parti uguali, così resta al centro.
                      child: LayoutBuilder(
                        builder: (context, box) => Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(child: _Flourish(flip: true, color: accent ?? Palette.gold)),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: DefaultTextStyle(
                                  style: titleStyle(
                                    size: 13,
                                    spacing: 2.4,
                                    color: accent ?? Palette.holy,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  child: title,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _Flourish(color: accent ?? Palette.gold)),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    if (actions != null)
                      Positioned(
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Palette.stone,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Palette.gold.withValues(alpha: 0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
                        ),
                      ),
                  ],
                ),
              ),
              const _GoldRule(faint: true),
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
  const _GoldRule({this.faint = false});
  final bool faint;

  @override
  Widget build(BuildContext context) {
    final c = faint ? Palette.gold.withValues(alpha: 0.35) : Palette.gold;
    return Container(
      height: faint ? 1 : 3,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c, width: 1),
          bottom: faint ? BorderSide.none : BorderSide(color: c.withValues(alpha: 0.4), width: 1),
        ),
      ),
    );
  }
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

/// Elmo e GYM OATH, al centro.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_helmet.png', height: 28),
          const SizedBox(width: 8),
          Text(
            'GYM OATH',
            style: titleStyle(size: 17, spacing: 4, color: Palette.goldBright).copyWith(
              shadows: [Shadow(color: Palette.gold.withValues(alpha: 0.6), blurRadius: 12)],
            ),
          ),
        ],
      ),
    );
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
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: Palette.holy),
          ),
        ),
      ),
    );
  }
}
