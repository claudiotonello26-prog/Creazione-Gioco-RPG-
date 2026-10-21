import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../domain/items.dart';

/// Il simbolo di un elemento: Fuoco, Vento, Arcano, Luce.
class ElementIcon extends StatelessWidget {
  const ElementIcon(this.element, {super.key, this.size = 18});
  final Affinity element;
  final double size;

  static IconData iconOf(Affinity a) => switch (a) {
        Affinity.fire => Icons.local_fire_department,
        Affinity.wind => Icons.air,
        Affinity.arcane => Icons.auto_awesome,
        Affinity.holy => Icons.wb_sunny,
      };

  @override
  Widget build(BuildContext context) => Tooltip(
        message: element.label,
        child: Icon(iconOf(element), color: element.color, size: size),
      );
}

/// Elemento del nemico contro il tuo: sullo scudo quanto danno ricevi in più
/// o in meno, sulla spada quanto ne fai. Verde conviene, rosso no.
class MatchupBadge extends StatelessWidget {
  const MatchupBadge({
    super.key,
    required this.element,
    required this.takenMult,
    required this.damageMult,
  });
  final Affinity element;
  final double takenMult;
  final double damageMult;

  @override
  Widget build(BuildContext context) {
    Widget part(IconData icon, double mult, {required bool lowerIsBetter}) {
      final pct = ((mult - 1) * 100).round();
      if (pct == 0) return const SizedBox.shrink();
      final good = lowerIsBetter ? pct < 0 : pct > 0;
      final color = good ? const Color(0xFF7FC36B) : Palette.blood;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          Text(
            '${pct > 0 ? '+' : ''}$pct%',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ]),
      );
    }

    return Tooltip(
      message: tr('Elemento {el}: scudo = danno che ricevi, spada = danno che fai',
          {'el': element.label}),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ElementIcon(element, size: 16),
        part(Icons.shield, takenMult, lowerIsBetter: true),
        part(Icons.colorize, damageMult, lowerIsBetter: false),
      ]),
    );
  }
}

/// Piccolo rombo colorato del grado di qualità della forgia.
class QualityPips extends StatelessWidget {
  const QualityPips(this.quality, {super.key, this.size = 8});
  final CraftQuality quality;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: quality.label,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < CraftQuality.values.length - 1; i++)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: size,
                  height: size,
                  color: i < quality.index ? quality.color : quality.color.withValues(alpha: 0.18),
                ),
              ),
            ),
        ]),
      );
}

/// Barretta dello stato dell'oggetto: verde, gialla oltre il 60% d'usura,
/// rossa quando è quasi consumato.
class WearBar extends StatelessWidget {
  const WearBar(this.wear, {super.key, this.width = 40});
  final int wear;
  final double width;

  @override
  Widget build(BuildContext context) {
    final left = 1 - wear / maxWear;
    final color = wear > 85
        ? Palette.blood
        : wear > wearFreeUpTo
            ? Palette.ember
            : const Color(0xFF7FC36B);
    return Tooltip(
      message: tr('Stato {n}%', {'n': (left * 100).round()}),
      child: Container(
        width: width,
        height: 4,
        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(2)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: left.clamp(0.0, 1.0),
          child: Container(
              decoration:
                  BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ),
      ),
    );
  }
}
