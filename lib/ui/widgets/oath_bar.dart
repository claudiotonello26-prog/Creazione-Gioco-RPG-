import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../screens/guide_screen.dart';
import '../screens/settings_screen.dart';

/// La barra di ogni schermata: GYM OATH con guida e impostazioni sempre a
/// portata, e sotto il nome della sezione fra due fregi.
class OathBar extends StatelessWidget implements PreferredSizeWidget {
  const OathBar({super.key, required this.title, this.actions, this.bottom, this.tools = true});

  /// Nome della sezione (Raccolta, Mercato...).
  final Widget title;

  /// Mostrati a destra del nome della sezione, come le rune nel Mercato.
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// Guida e impostazioni; spenti nelle loro stesse schermate.
  final bool tools;

  static const double _top = 50, _section = 34;

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
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: canPop
                          ? IconButton(
                              tooltip: 'Indietro',
                              icon: const Icon(Icons.arrow_back, color: Palette.goldBright),
                              onPressed: () => Navigator.of(context).maybePop(),
                            )
                          : const Icon(Icons.shield_moon_outlined, color: Palette.gold, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        'GYM OATH',
                        textAlign: TextAlign.center,
                        style: titleStyle(size: 17, spacing: 6, color: Palette.goldBright).copyWith(
                          shadows: [
                            Shadow(color: Palette.gold.withValues(alpha: 0.6), blurRadius: 12),
                          ],
                        ),
                      ),
                    ),
                    if (tools) ...[
                      IconButton(
                        tooltip: 'Guida',
                        icon: const Icon(Icons.menu_book_outlined, color: Palette.gold),
                        onPressed: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const GuideScreen())),
                      ),
                      IconButton(
                        tooltip: 'Impostazioni',
                        icon: const Icon(Icons.settings_outlined, color: Palette.gold),
                        onPressed: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    ] else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              const _GoldRule(),
              SizedBox(
                height: _section,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Expanded(child: _Flourish(flip: true)),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 3,
                      child: DefaultTextStyle(
                        style: titleStyle(size: 13, spacing: 2.4, color: Palette.holy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        child: title,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: _Flourish()),
                    ...?actions,
                    const SizedBox(width: 12),
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
  const _Flourish({this.flip = false});
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: flip ? [Colors.transparent, Palette.gold] : [Palette.gold, Colors.transparent],
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
          color: Palette.goldBright,
          boxShadow: [BoxShadow(color: Palette.gold.withValues(alpha: 0.7), blurRadius: 6)],
        ),
      ),
    );
    final dot = Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(color: Palette.gold, shape: BoxShape.circle),
    );
    final parts = [line, const SizedBox(width: 4), dot, const SizedBox(width: 4), gem];
    return Row(children: flip ? parts : parts.reversed.toList());
  }
}
