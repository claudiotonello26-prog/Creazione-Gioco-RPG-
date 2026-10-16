import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/items.dart';
import '../widgets/common.dart';

const Map<String, int> amuletPrices = {
  'fervent': 600,
  'colossus_seal': 600,
  'hunter_heart': 450,
  'martyr_relic': 800,
};

class ForgeTab extends StatelessWidget {
  const ForgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final w = c.weapon;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Arma impugnata'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.displayName,
                    style: const TextStyle(fontSize: 20, color: Palette.goldBright)),
                Text(
                  '${w.def.style.label}${w.def.heavy ? ' · pesante' : ''}${w.def.rare ? ' · RARA' : ''}',
                  style: const TextStyle(color: Palette.ash),
                ),
                const SizedBox(height: 8),
                Text('Potere d\'attacco ${w.attackRating(c).round()}'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final e in w.def.scaling.entries)
                      InfoChip(Icons.trending_up, '${e.key.label} ${e.value.label}'),
                  ],
                ),
                const SizedBox(height: 8),
                _UpgradePreview(level: w.upgrade, max: w.def.maxUpgrade),
                const SizedBox(height: 12),
                if (w.nextStone != null)
                  FilledButton(
                    onPressed: (c.materials[w.nextStone] ?? 0) >= w.nextStoneCost
                        ? () {
                            s.upgradeWeapon(w);
                            toast(context, '${w.displayName}: l\'acciaio canta.');
                          }
                        : null,
                    child: Text(
                        'POTENZIA A +${w.upgrade + 1} (${w.nextStoneCost}× ${materialNames[w.nextStone]})'),
                  )
                else
                  const Text('Potenziamento massimo raggiunto',
                      style: TextStyle(color: Palette.goldBright)),
              ],
            ),
          ),
        ),
        if (c.weapons.isNotEmpty) ...[
          const SectionTitle('Armeria'),
          for (final other in c.weapons)
            ActionTile(
              icon: Icons.gavel,
              title: other.displayName,
              subtitle: 'Potere ${other.attackRating(c).round()} · tocca per impugnare',
              onTap: () => s.equip(other),
            ),
        ],
        const SectionTitle('Fornace'),
        ActionTile(
          icon: Icons.local_fire_department,
          title: 'Pietra di forgia I',
          subtitle: forgeStone1Recipe.entries
              .map((e) => '${e.value}× ${materialNames[e.key]}')
              .join(' + '),
          trailing: TextButton(
            onPressed: () {
              if (!s.craftForgeStone()) toast(context, 'Materiali insufficienti');
            },
            child: const Text('Crea'),
          ),
        ),
        const SectionTitle('Incudine'),
        for (final def in weaponDefs.values.where((d) => d.recipe.isNotEmpty))
          ActionTile(
            icon: Icons.hardware,
            title: def.name,
            subtitle: def.recipe.entries
                .map((e) => '${e.value}× ${materialNames[e.key]} (${c.materials[e.key] ?? 0})')
                .join(' · '),
            enabled: s.canCraft(def),
            trailing: TextButton(
              onPressed: s.canCraft(def) ? () => s.craftWeapon(def) : null,
              child: const Text('Forgia'),
            ),
          ),
        SectionTitle('Amuleti (${c.amulets.length}/${Character.maxAmuletSlots})'),
        for (final a in amuletDefs.values)
          ActionTile(
            icon: Icons.brightness_7_outlined,
            title: a.name,
            subtitle: a.description,
            color: c.amulets.contains(a.id) ? Palette.goldBright : Palette.ash,
            trailing: s.ownsAmulet(a.id)
                ? Switch(value: c.amulets.contains(a.id), onChanged: (_) => s.toggleAmulet(a.id))
                : TextButton(
                    onPressed: () {
                      if (!s.buyAmulet(a.id, amuletPrices[a.id]!)) {
                        toast(context, 'Rune insufficienti');
                      }
                    },
                    child: Text('${amuletPrices[a.id]} rune'),
                  ),
          ),
        const SectionTitle('Materiali'),
        if (c.materials.values.every((v) => v == 0))
          const Text('Sconfiggi mostri per raccogliere materiali.',
              style: TextStyle(color: Palette.ash)),
        for (final m in c.materials.entries.where((e) => e.value > 0 && !e.key.startsWith('amulet_')))
          ListTile(
            dense: true,
            title: Text(materialNames[m.key] ?? m.key),
            trailing: Text('${m.value}', style: const TextStyle(color: Palette.goldBright)),
          ),
      ],
    );
  }
}

/// Anteprima dei livelli: a +3, +6 e +10 l'aspetto cambia.
class _UpgradePreview extends StatelessWidget {
  const _UpgradePreview({required this.level, required this.max});
  final int level;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= max; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: (i == 3 || i == 6 || i == 10) ? 14 : 8,
              color: i <= level ? Palette.goldBright : Palette.iron,
            ),
          ),
      ],
    );
  }
}
