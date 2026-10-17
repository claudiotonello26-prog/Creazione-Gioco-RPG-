import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';

const Map<String, int> amuletPrices = {
  'fervent': 600,
  'colossus_seal': 600,
  'hunter_heart': 450,
  'martyr_relic': 800,
};

IconData stationIcon(Station s) => switch (s) {
      Station.carpentry => Icons.carpenter,
      Station.furnace => Icons.local_fire_department,
      Station.anvil => Icons.hardware,
      Station.enchant => Icons.auto_awesome,
    };

/// La Forgia: quattro postazioni come su Gymscape, poi armeria e amuleti.
class ForgeTab extends StatelessWidget {
  const ForgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            for (final st in Station.values)
              _StationButton(
                station: st,
                level: st == Station.enchant ? null : s.stationLevel(st),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => StationScreen(station: st))),
              ),
          ],
        ),
        const SectionTitle('Armeria'),
        for (final w in [c.weapon, ...c.weapons])
          ActionTile(
            icon: identical(w, c.weapon) ? Icons.check_circle : Icons.gavel,
            title: w.displayName,
            subtitle: '${w.def.style.label} · potere ${w.attackRating(c).round()}'
                '${identical(w, c.weapon) ? ' · impugnata' : ' · tocca per impugnare'}',
            color: identical(w, c.weapon) ? Palette.goldBright : Palette.gold,
            onTap: identical(w, c.weapon) ? null : () => s.equip(w),
          ),
        const SectionTitle('Armature'),
        if (c.armors.isEmpty)
          const Text('Nessuna armatura: la prima si forgia all\'Incudine.',
              style: TextStyle(color: Palette.ash)),
        for (final id in c.armors)
          ActionTile(
            icon: c.armorId == id ? Icons.check_circle : Icons.shield_outlined,
            title: armorDefs[id]!.name,
            subtitle: 'Assorbe il ${(armorDefs[id]!.reduction * 100).round()}% dei colpi'
                '${c.armorId == id ? ' · indossata' : ' · tocca per indossare'}',
            color: c.armorId == id ? Palette.goldBright : Palette.gold,
            onTap: () => s.wearArmor(c.armorId == id ? null : id),
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
      ],
    );
  }
}

class _StationButton extends StatelessWidget {
  const _StationButton({required this.station, required this.level, required this.onTap});
  final Station station;
  final int? level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.gold, width: 1.5),
                  gradient: const RadialGradient(colors: [Color(0xFF3A2C16), Palette.night]),
                ),
                child: Icon(stationIcon(station), color: Palette.goldBright, size: 32),
              ),
              const SizedBox(height: 10),
              FittedBox(child: Text(station.label.toUpperCase(), style: titleStyle(size: 14))),
              Text(level == null ? 'Potenzia l\'arma' : 'Livello $level',
                  style: const TextStyle(color: Palette.ash, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una postazione della forgia.
class StationScreen extends StatelessWidget {
  const StationScreen({super.key, required this.station});
  final Station station;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: Text(station.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: station == Station.enchant ? _enchant(context, s) : _crafting(context, s),
      ),
    );
  }

  List<Widget> _crafting(BuildContext context, GameState s) {
    final skill = Skill.forStation(station);
    final (lvl, xpIn, xpNeed) = skillProgress(s.skillXp[skill] ?? 0);
    final mats = materialRecipes.where((r) => r.station == station).toList();
    final weapons = weaponDefs.values
        .where((d) => d.recipe.isNotEmpty && d.station == station)
        .toList()
      ..sort((a, b) => a.craftLevel.compareTo(b.craftLevel));
    final armors = station == Station.anvil ? armorDefs.values.toList() : <ArmorDef>[];
    return [
      Row(
        children: [
          Icon(stationIcon(station), color: Palette.goldBright, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text(station.description, style: const TextStyle(color: Palette.ash))),
        ],
      ),
      const SizedBox(height: 10),
      StatBar(value: xpIn / xpNeed, color: Palette.gold, label: 'Livello $lvl · $xpIn / $xpNeed XP'),
      if (mats.isNotEmpty) const SectionTitle('Lavorazioni'),
      for (final r in mats)
        _RecipeTile(
          title: materialNames[r.output] ?? r.output,
          inputs: r.inputs,
          level: r.level,
          unlocked: lvl >= r.level,
          have: s.character.materials[r.output] ?? 0,
          canMake: lvl >= r.level && s.hasMaterials(r.inputs),
          onMake: () => s.craftMaterial(r),
          icon: Icons.hexagon_outlined,
          stationLabel: station.label,
        ),
      if (weapons.isNotEmpty) const SectionTitle('Armi'),
      for (final d in weapons)
        _RecipeTile(
          title: d.name,
          inputs: d.recipe,
          level: d.craftLevel,
          unlocked: lvl >= d.craftLevel,
          canMake: s.canCraft(d),
          onMake: () {
            s.craftWeapon(d);
            toast(context, '${d.name} è pronta: impugnala dall\'Armeria.');
          },
          icon: Icons.gavel,
          stationLabel: station.label,
          note: '${d.style.label} · aura di ${d.affinity.label.toLowerCase()}',
        ),
      if (armors.isNotEmpty) const SectionTitle('Armature'),
      for (final a in armors)
        _RecipeTile(
          title: a.name,
          inputs: a.recipe,
          level: a.craftLevel,
          unlocked: lvl >= a.craftLevel,
          canMake: s.canCraftArmor(a),
          done: s.character.armors.contains(a.id),
          onMake: () {
            s.craftArmor(a);
            toast(context, '${a.name} indossata.');
          },
          icon: Icons.shield_outlined,
          stationLabel: station.label,
          note: 'Assorbe il ${(a.reduction * 100).round()}% dei colpi',
        ),
    ];
  }

  List<Widget> _enchant(BuildContext context, GameState s) {
    final c = s.character;
    final w = c.weapon;
    final next = WeaponInstance(weaponId: w.weaponId, upgrade: (w.upgrade + 1).clamp(0, w.def.maxUpgrade));
    final aff = w.def.affinity;
    final stone = w.nextStone;
    return [
      Text(
        'L\'aura di quest\'arma è ${aff.label.toLowerCase()} (${aff.attributeLabel}). '
        'A +3 la lama si tinge, a +6 si accende, a +10 ha l\'aura completa.',
        style: const TextStyle(color: Palette.ash),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(children: [
            WeaponPreview(weapon: w, size: 130),
            Text(w.displayName, style: const TextStyle(color: Palette.holy)),
          ]),
          if (stone != null) const Icon(Icons.arrow_forward, color: Palette.gold),
          if (stone != null)
            Column(children: [
              WeaponPreview(weapon: next, size: 130),
              Text('+${next.upgrade}', style: titleStyle(size: 16)),
            ]),
        ],
      ),
      const SizedBox(height: 12),
      _UpgradePreview(level: w.upgrade, max: w.def.maxUpgrade),
      const SizedBox(height: 12),
      Text('Potere d\'attacco ${w.attackRating(c).round()}'
          '${stone != null ? ' → ${next.attackRating(c).round()}' : ''}',
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      if (stone != null)
        FilledButton(
          onPressed: (c.materials[stone] ?? 0) >= w.nextStoneCost
              ? () {
                  s.upgradeWeapon(w);
                  toast(context, '${w.displayName}: l\'acciaio canta.');
                }
              : null,
          child: Text('INCANTA A +${w.upgrade + 1} '
              '(${w.nextStoneCost}× ${materialNames[stone]}, hai ${c.materials[stone] ?? 0})'),
        )
      else
        const Text('Potenziamento massimo raggiunto',
            textAlign: TextAlign.center, style: TextStyle(color: Palette.goldBright)),
      const SectionTitle('Le quattro aure'),
      for (final a in Affinity.values)
        ActionTile(
          icon: Icons.blur_on,
          color: a.color,
          title: '${a.label} · ${a.attributeLabel}',
          subtitle: switch (a) {
            Affinity.fire => 'Lama rossa, a +10 avvolta dal fuoco',
            Affinity.wind => 'Lama verde, a +10 vortici di vento',
            Affinity.arcane => 'Lama blu, a +10 neon azzurro',
            Affinity.holy => 'Riflessi dorati, a +10 aura divina',
          },
        ),
    ];
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.title,
    required this.inputs,
    required this.level,
    required this.unlocked,
    required this.canMake,
    required this.onMake,
    required this.icon,
    required this.stationLabel,
    this.have,
    this.note,
    this.done = false,
  });

  final String title;
  final Map<String, int> inputs;
  final int level;
  final bool unlocked;
  final bool canMake;
  final VoidCallback onMake;
  final IconData icon;
  final String stationLabel;
  final int? have;
  final String? note;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final s = context.read<GameState>();
    final needs = inputs.entries
        .map((e) => '${e.value}× ${materialNames[e.key]} (${s.character.materials[e.key] ?? 0})')
        .join(' · ');
    return ActionTile(
      icon: unlocked ? icon : Icons.lock_outline,
      color: unlocked ? Palette.gold : Palette.iron,
      title: '$title${have != null && have! > 0 ? '  ·  hai $have' : ''}',
      subtitle: unlocked
          ? [?note, needs].join('\n')
          : 'Si sblocca a $stationLabel livello $level',
      enabled: unlocked,
      trailing: done
          ? const Icon(Icons.check, color: Palette.goldBright)
          : TextButton(onPressed: canMake ? onMake : null, child: const Text('Crea')),
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
