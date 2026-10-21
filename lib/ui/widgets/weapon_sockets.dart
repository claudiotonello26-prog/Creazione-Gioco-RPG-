import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import 'common.dart';

/// Le tre incastonature dell'arma: affinità (colore, aura, scaling) e due
/// passivi. Un tocco apre la scelta fra gli amuleti nella borsa.
class WeaponSockets extends StatelessWidget {
  const WeaponSockets({super.key, required this.weapon});
  final WeaponInstance weapon;

  @override
  Widget build(BuildContext context) {
    context.watch<GameState>();
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Socket(weapon: weapon, slot: i)),
        ],
      ],
    );
  }
}

class _Socket extends StatelessWidget {
  const _Socket({required this.weapon, required this.slot});
  final WeaponInstance weapon;
  final int slot;

  @override
  Widget build(BuildContext context) {
    final a = amuletDefs[weapon.sockets[slot]];
    final color = a?.apply.aura?.color ?? (slot == 0 ? Palette.ember : Palette.gold);
    return Material(
      color: Palette.stoneLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: a == null ? color.withValues(alpha: 0.4) : color, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Sound.play(Sfx.tap, volume: 0.7);
          _pick(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              OneLine(
                slot == 0 ? tr('AFFINITÀ') : tr('PASSIVO'),
                align: Alignment.center,
                style: titleStyle(size: 10, spacing: 1.2, color: color),
              ),
              const SizedBox(height: 6),
              a == null
                  ? Icon(Icons.add_circle_outline, size: 34, color: color.withValues(alpha: 0.6))
                  : ItemIcon('amulet_${a.id}', size: 34),
              const SizedBox(height: 6),
              OneLine(
                a?.name ?? tr('Vuoto'),
                align: Alignment.center,
                style: TextStyle(
                  fontSize: 12,
                  color: a == null ? Palette.ash : Palette.holy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pick(BuildContext context) {
    final s = context.read<GameState>();
    final options = amuletDefs.values
        .where((a) => a.isAffinity == (slot == 0) && !a.isWard && s.amuletCount(a.id) > 0)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.stone,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            SectionTitle(slot == 0 ? tr('Amuleto d\'affinità') : tr('Amuleto passivo')),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  tr('Nessuno nella borsa. Li trovi dalla Fattucchiera.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.ash),
                ),
              ),
            for (final a in options)
              Card(
                child: ListTile(
                  leading: ItemIcon('amulet_${a.id}', size: 34),
                  title: OneLine(a.name),
                  subtitle: Text(a.description, style: const TextStyle(color: Palette.ash)),
                  trailing: Text('×${s.amuletCount(a.id)}'),
                  onTap: () {
                    s.socketAmulet(weapon, slot, a.id);
                    Sound.play(Sfx.craftEnchant);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            if (weapon.sockets[slot] != null)
              TextButton.icon(
                onPressed: () {
                  s.unsocketAmulet(weapon, slot);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.eject),
                label: Text(tr('TOGLI E RIMETTI NELLA BORSA')),
              ),
          ],
        ),
      ),
    );
  }
}
