import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/art.dart';
import '../../core/theme.dart';
import '../../core/sound.dart';
import '../../domain/enemies.dart';
import '../../domain/items.dart';
import '../../game/battle_game.dart' show enemyArtPath;

/// Titolo di sezione al centro, fra due fili d'oro simmetrici; l'eventuale
/// dettaglio ([trailing]) va sotto, sempre al centro.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget rule(bool left) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: left ? Alignment.centerLeft : Alignment.centerRight,
                end: left ? Alignment.centerRight : Alignment.centerLeft,
                colors: [Palette.gold.withValues(alpha: 0), Palette.gold.withValues(alpha: 0.8)],
              ),
            ),
          ),
        );
    Widget diamond() => Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              border: Border.all(color: Palette.goldBright, width: 1.2),
              boxShadow: [BoxShadow(color: Palette.gold.withValues(alpha: 0.5), blurRadius: 6)],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                rule(true),
                const SizedBox(width: 8),
                diamond(),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.7),
                  child: OneLine(
                    text.toUpperCase(),
                    align: Alignment.center,
                    style: titleStyle(size: 13, spacing: 1.6),
                  ),
                ),
                const SizedBox(width: 10),
                diamond(),
                const SizedBox(width: 8),
                rule(false),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 14),
                child: trailing!,
              ),
            ),
        ],
      ),
    );
  }
}

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.value,
    required this.color,
    this.label,
    this.height = 10,
  });

  final double value;
  final Color color;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(label!, style: const TextStyle(fontSize: 12, color: Palette.ash)),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: height,
            color: color,
            backgroundColor: Palette.iron,
          ),
        ),
      ],
    );
  }
}

/// Le voci già sbloccate al livello [lvl] e quella che si sblocca per prima
/// dopo, in ordine di livello.
List<T> unlockedPlusNext<T>(List<T> items, int Function(T) level, int lvl) {
  final sorted = [...items]..sort((a, b) => level(a).compareTo(level(b)));
  final open = sorted.where((x) => level(x) <= lvl).toList();
  final next = sorted.where((x) => level(x) > lvl).firstOrNull;
  return [...open, ?next];
}

/// Un dato a colpo d'occhio: icona e numero, niente frasi.
class StatChip extends StatelessWidget {
  const StatChip(this.icon, this.text, {super.key, this.color = Palette.holy});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// Cosa serve per creare qualcosa: icona di ogni materiale con «hai/serve»,
/// verde se basta e rosso se manca.
class CostRow extends StatelessWidget {
  const CostRow({super.key, required this.needs, required this.have, this.onTapItem});
  final Map<String, int> needs;
  final Map<String, int> have;
  final void Function(String id)? onTapItem;

  static const ok = Color(0xFF7FC97A), missing = Color(0xFFE0605A);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final e in needs.entries)
          GestureDetector(
            onTap: onTapItem == null ? null : () => onTapItem!(e.key),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ItemIcon(e.key, size: 26),
                const SizedBox(width: 2),
                Text(
                  '${have[e.key] ?? 0}/${e.value}',
                  style: TextStyle(
                    color: (have[e.key] ?? 0) >= e.value ? ok : missing,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// L'etichetta di una barra di esperienza con quanto manca al prossimo
/// livello: «120 / 300 XP · mancano 180».
String xpLeftLabel(int xpIn, int xpNeed) => xpNeed <= 0
    ? '$xpIn XP'
    : tr('{xp} / {need} XP · mancano {left}', {'xp': xpIn, 'need': xpNeed, 'left': xpNeed - xpIn});

class InfoChip extends StatelessWidget {
  const InfoChip(this.icon, this.text, {super.key, this.color = Palette.gold});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.stoneLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

/// Riga cliccabile in stile pergamena scura.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color = Palette.gold,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Card(
        child: ListTile(
          minVerticalPadding: 10,
          leading: Icon(icon, color: color, size: 30),
          title: OneLine(title, align: Alignment.centerLeft),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: const TextStyle(color: Palette.ash, fontSize: 14)),
          trailing: trailing ??
              (onTap != null ? Icon(Icons.chevron_right, color: color, size: 30) : null),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}

/// Quanto è duro un nemico per te: verde si batte facile, arancio è una
/// sfida, rosso è quasi impossibile. Un boss conta due livelli in più.
enum Difficulty {
  easy(Color(0xFF7FC25A)),
  medium(Color(0xFFE5962B)),
  hard(Color(0xFFE0483C));

  const Difficulty(this.color);
  final Color color;

  static Difficulty of(EnemyDef e, int playerLevel) {
    final gap = e.level + (e.isBoss ? 2 : 0) - playerLevel;
    if (gap <= 0) return easy;
    if (gap <= 2) return medium;
    return hard;
  }

  String get label => switch (this) {
        easy => tr('Facile'),
        medium => tr('Impegnativo'),
        hard => tr('Difficile'),
      };
}

/// «Liv. 3 · Facile» in una pastiglia del colore della difficoltà.
class LevelBadge extends StatelessWidget {
  const LevelBadge(this.enemy, this.playerLevel, {super.key, this.big = false});
  final EnemyDef enemy;
  final int playerLevel;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final d = Difficulty.of(enemy, playerLevel);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: big ? 12 : 8, vertical: big ? 5 : 3),
      decoration: BoxDecoration(
        color: d.color.withValues(alpha: 0.18),
        border: Border.all(color: d.color, width: 1.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${tr('Liv. {n}', {'n': enemy.level})} · ${d.label}',
        style: TextStyle(
          color: d.color,
          fontWeight: FontWeight.bold,
          fontSize: big ? 15 : 13,
        ),
      ),
    );
  }
}

/// Il ritratto di un nemico su fondo neutro grigio pietra, così anche i
/// mostri scuri si vedono bene. Senza immagine mostra un simbolo.
class EnemyPortrait extends StatelessWidget {
  const EnemyPortrait(
    this.enemy, {
    super.key,
    this.size = 96,
    this.border,
    this.dim = false,
    this.fallback,
  });
  final EnemyDef enemy;
  final double size;
  final Color? border;
  final bool dim;
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final art = enemyArtPath(enemy);
    final ring = border ?? (enemy.isBoss ? Palette.blood : Palette.gold);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: neutralBackdrop,
        borderRadius: BorderRadius.circular(size * 0.14),
        border: Border.all(color: ring, width: size >= 120 ? 2.5 : 2),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(size * 0.05),
      child: Opacity(
        opacity: dim ? 0.45 : 1,
        child: Art.has(art)
            ? Image.asset(art, fit: BoxFit.contain)
            : Icon(
                fallback ??
                    (enemy.isAnimal ? Icons.pets : (enemy.isBoss ? Icons.castle : Icons.shield)),
                size: size * 0.5,
                color: Palette.night.withValues(alpha: 0.7),
              ),
      ),
    );
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Palette.stoneLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// L'icona di un oggetto: l'immagine di Antigravity se c'è
/// (`assets/art/items/<id>.png`), altrimenti un simbolo del suo tipo.
class ItemIcon extends StatelessWidget {
  const ItemIcon(this.id, {super.key, this.size = 40});
  final String id;
  final double size;

  static (IconData, Color) symbolOf(String id) {
    bool has(String s) => id.contains(s);
    if (id.startsWith('amulet_')) {
      final aura = amuletDefs[id.substring(7)]?.apply.aura;
      return (Icons.brightness_7, aura?.color ?? Palette.goldBright);
    }
    if (has('somber')) return (Icons.hexagon, const Color(0xFF9B6BE0));
    if (id == 'epic_stone') return (Icons.auto_awesome, const Color(0xFFFF8A3D));
    if (id == 'ancient_stone') return (Icons.hexagon, const Color(0xFF8FE3FF));
    if (has('plank') || has('grip')) return (Icons.view_agenda, const Color(0xFFB08850));
    if (has('wood')) return (Icons.forest, const Color(0xFF9C7A4B));
    if (has('coal')) return (Icons.landscape, const Color(0xFF6B6B6B));
    if (has('ore') || has('moon_silver')) return (Icons.landscape, Palette.frost);
    if (has('ingot') || has('steel') || has('iron') || has('gold') || has('silver')) {
      return (Icons.view_module, has('gold') ? Palette.goldBright : Palette.ash);
    }
    if (has('hide') || has('leather')) return (Icons.layers, const Color(0xFFA8714A));
    if (has('bone')) return (Icons.spa, Palette.holy);
    if (has('gem') ||
        has('crystal') ||
        has('pearl') ||
        has('core') ||
        has('heart') ||
        has('eye') ||
        has('tear')) {
      return (Icons.diamond, const Color(0xFF9FD3FF));
    }
    if (has('stone') || has('shard')) return (Icons.hexagon, Palette.gold);
    if (has('essence') || has('ink')) return (Icons.water_drop, const Color(0xFFB07ACC));
    if (has('amulet')) return (Icons.brightness_7, Palette.goldBright);
    if (has('axe') || has('pickaxe')) return (Icons.handyman, Palette.ash);
    return (Icons.hexagon_outlined, Palette.gold);
  }

  @override
  Widget build(BuildContext context) {
    final path = 'assets/art/items/$id.png';
    if (Art.has(path)) return Image.asset(path, width: size, height: size);
    final (icon, color) = symbolOf(id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.28), Colors.transparent]),
      ),
      child: Icon(icon, color: color, size: size * 0.62),
    );
  }
}

/// Cinque secondi prima di creare qualcosa, con ANNULLA: true se si va avanti.
Future<bool> craftCountdown(
  BuildContext context, {
  required String title,
  String? itemId,
  Color color = Palette.gold,
  int seconds = 5,
  Sfx sound = Sfx.confirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CraftCountdown(title: title, itemId: itemId, color: color, seconds: seconds),
  );
  Sound.play(ok == true ? sound : Sfx.craftCancel);
  return ok == true;
}

class _CraftCountdown extends StatefulWidget {
  const _CraftCountdown({
    required this.title,
    required this.itemId,
    required this.color,
    required this.seconds,
  });
  final String title;
  final String? itemId;
  final Color color;
  final int seconds;

  @override
  State<_CraftCountdown> createState() => _CraftCountdownState();
}

class _CraftCountdownState extends State<_CraftCountdown> with SingleTickerProviderStateMixin {
  int _lastTick = -1;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )
    ..addListener(() {
      final left = (widget.seconds * (1 - _c.value)).ceil();
      if (left != _lastTick) {
        _lastTick = left;
        if (left > 0 && left < widget.seconds) Sound.play(Sfx.craftTick, volume: 0.6);
      }
    })
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed && mounted) Navigator.pop(context, true);
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final left = (widget.seconds * (1 - _c.value)).ceil();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title.toUpperCase(),
                  textAlign: TextAlign.center, style: titleStyle(size: 15, color: widget.color)),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1 - _c.value,
                        strokeWidth: 5,
                        color: widget.color,
                        backgroundColor: Palette.iron,
                      ),
                    ),
                    if (widget.itemId != null && Art.has('assets/art/items/${widget.itemId}.png'))
                      Opacity(opacity: 0.35, child: ItemIcon(widget.itemId!, size: 70)),
                    Text('$left', style: titleStyle(size: 40, color: Palette.holy)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: Palette.blood, foregroundColor: Palette.holy),
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('ANNULLA')),
        ),
      ],
    );
  }
}

/// Sfondo di una sezione: l'illustrazione (assets/art/backgrounds, quando
/// c'è) appena visibile e un alone del colore della sezione in alto.
class SectionBackdrop extends StatelessWidget {
  const SectionBackdrop({super.key, required this.art, required this.color, required this.child});
  final String art;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = 'assets/art/backgrounds/$art.png';
    return Stack(
      fit: StackFit.expand,
      children: [
        if (Art.has(path)) Opacity(opacity: 0.3, child: Image.asset(path, fit: BoxFit.cover)),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.1),
                radius: 1.1,
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Testo su una riga sola: se non ci sta si rimpicciolisce, non va mai a capo.
class OneLine extends StatelessWidget {
  const OneLine(this.text, {super.key, this.style, this.align = Alignment.centerLeft});
  final String text;
  final TextStyle? style;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align,
      child: Text(text, maxLines: 1, softWrap: false, style: style),
    );
  }
}

/// Selettore a pulsanti fissi: celle tutte uguali su una griglia ordinata
/// ([columns] per riga), etichette su una riga sola.
class OathChoice<T> extends StatelessWidget {
  const OathChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.columns,
    this.color = Palette.gold,
    this.height = 48,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final int? columns;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? (options.length <= 4 ? options.length : 3);
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += cols) {
      rows.add(Row(
        children: [
          for (var j = i; j < i + cols; j++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: j == i ? 0 : 6),
                child: j < options.length
                    ? OathToggle(
                        label: options[j].$2,
                        selected: options[j].$1 == selected,
                        onTap: () => onChanged(options[j].$1),
                        color: color,
                        height: height,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < rows.length; r++)
          Padding(padding: EdgeInsets.only(top: r == 0 ? 0 : 6), child: rows[r]),
      ],
    );
  }
}

/// Una cella del selettore: si può usare anche da sola come interruttore.
class OathToggle extends StatelessWidget {
  const OathToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = Palette.gold,
    this.height = 48,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Palette.night : Palette.holy;
    return Material(
      color: selected ? color : Palette.stoneLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: selected ? color : color.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                Sound.play(Sfx.tap, volume: 0.7);
                onTap!();
              },
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? Palette.night : color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: OneLine(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: kTitleFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
