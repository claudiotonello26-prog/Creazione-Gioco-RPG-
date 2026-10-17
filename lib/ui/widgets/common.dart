import 'package:flutter/material.dart';

import '../../core/art.dart';
import '../../core/theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          children: [
            Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  border: Border.all(color: Palette.goldBright, width: 1.2),
                  boxShadow: [BoxShadow(color: Palette.gold.withValues(alpha: 0.5), blurRadius: 6)],
                ),
                alignment: Alignment.center,
                child: Container(width: 3, height: 3, color: Palette.goldBright),
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.8),
              child: Text(text.toUpperCase(), style: titleStyle(size: 13, spacing: 1.6)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Palette.gold.withValues(alpha: 0.8),
                                Palette.gold.withValues(alpha: 0.15),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Palette.gold.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Palette.gold.withValues(alpha: 0.3),
                          Palette.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
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
          leading: Icon(icon, color: color),
          title: Text(title),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: const TextStyle(color: Palette.ash, fontSize: 13)),
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
          onTap: enabled ? onTap : null,
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
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CraftCountdown(title: title, itemId: itemId, color: color, seconds: seconds),
  );
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
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.seconds),
  )
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
          child: const Text('ANNULLA'),
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
