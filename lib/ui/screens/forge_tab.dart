import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import 'gear_screens.dart';
import '../../core/sound.dart';

IconData stationIcon(Station s) => switch (s) {
  Station.carpentry => Icons.carpenter,
  Station.furnace => Icons.local_fire_department,
  Station.anvil => Icons.hardware,
  Station.enchant => Icons.auto_awesome,
};

/// La Forgia: quattro postazioni come su Gymscape, poi equipaggiamento e mercato.
class ForgeTab extends StatelessWidget {
  const ForgeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
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
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => StationScreen(station: st))),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ActionTile(
          icon: Icons.shield,
          title: 'Equipaggiamento',
          subtitle: 'Arma, armatura pezzo per pezzo, mano sinistra, amuleti',
          color: Palette.goldBright,
          onTap: () => openEquipment(context),
        ),
        ActionTile(
          icon: Icons.storefront,
          title: 'Mercato',
          subtitle: 'Vendi quello che avanza, compra materiali, amuleti dalla Fattucchiera',
          onTap: () => openMarket(context),
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
                  border: Border.all(color: station.accent, width: 1.5),
                  gradient: RadialGradient(
                    colors: [station.accent.withValues(alpha: 0.35), Palette.night],
                  ),
                  boxShadow: [
                    BoxShadow(color: station.accent.withValues(alpha: 0.35), blurRadius: 14),
                  ],
                ),
                child: Icon(stationIcon(station), color: station.accent, size: 32),
              ),
              const SizedBox(height: 10),
              FittedBox(
                child: Text(
                  station.label.toUpperCase(),
                  style: titleStyle(size: 14, color: station.accent),
                ),
              ),
              Text(
                level == null ? 'Potenzia l\'arma' : 'Livello $level',
                style: const TextStyle(color: Palette.ash, fontSize: 13),
              ),
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
      appBar: OathBar(title: Text(station.label.toUpperCase()), accent: station.accent),
      body: SectionBackdrop(
        art: 'station_${station.name}',
        color: station.accent,
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: station == Station.enchant ? _enchant(context, s) : _crafting(context, s),
      ),
      ),
    );
  }

  List<Widget> _crafting(BuildContext context, GameState s) {
    final skill = Skill.forStation(station);
    final (lvl, xpIn, xpNeed) = skillProgress(s.skillXp[skill] ?? 0);
    final mats = materialRecipes.where((r) => r.station == station).toList();
    final weapons =
        weaponDefs.values.where((d) => d.recipe.isNotEmpty && d.station == station).toList()
          ..sort((a, b) => a.craftLevel.compareTo(b.craftLevel));
    final armors = station == Station.anvil ? armorDefs.values.toList() : <ArmorDef>[];
    final offhands = offhandDefs.values.where((o) => o.station == station).toList();
    return [
      Icon(stationIcon(station), color: station.accent, size: 40),
      const SizedBox(height: 6),
      Text(
        station.description,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Palette.ash),
      ),
      const SizedBox(height: 10),
      StatBar(
        value: xpIn / xpNeed,
        color: Palette.gold,
        label: 'Livello $lvl · $xpIn / $xpNeed XP',
      ),
      if (mats.isNotEmpty) const SectionTitle('Lavorazioni'),
      for (final r in mats)
        _RecipeTile(
          title: materialNames[r.output] ?? r.output,
          inputs: r.inputs,
          level: r.level,
          unlocked: lvl >= r.level,
          have: s.character.materials[r.output] ?? 0,
          canMake: s.canCraftMaterial(r),
          done: r.tool && s.hasTool(r.output),
          onMake: () => s.craftMaterial(r),
          icon: Icons.hexagon_outlined,
          stationLabel: station.label,
          color: station.accent,
          sound: stationSound(station),
          itemId: r.output,
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
          color: station.accent,
          sound: stationSound(station),
          itemId: d.id,
          note:
              '${d.style.label} · aura di ${d.affinity.label.toLowerCase()}'
              '${d.wieldLevel > 1 ? ' · si impugna con ${d.usesMagic ? 'Magia' : 'Attacco'} ${d.wieldLevel}' : ''}',
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
          color: station.accent,
          sound: stationSound(station),
          itemId: a.id,
          note:
              'Assorbe il ${(a.reduction * 100).round()}% dei colpi'
              '${a.wearLevel > 1 ? ' · si indossa con Difesa ${a.wearLevel}' : ''}',
        ),
      if (offhands.isNotEmpty) const SectionTitle('Mano sinistra'),
      for (final o in offhands)
        _RecipeTile(
          title: o.name,
          inputs: o.recipe,
          level: o.craftLevel,
          unlocked: lvl >= o.craftLevel,
          canMake: s.canCraftOffhand(o),
          done: s.character.offhands.contains(o.id),
          onMake: () {
            s.craftOffhand(o);
            toast(context, '${o.name} in mano (con un\'arma a una mano).');
          },
          icon: o.isShield ? Icons.shield_moon_outlined : Icons.gavel,
          stationLabel: station.label,
          color: station.accent,
          sound: stationSound(station),
          itemId: o.id,
          note: o.effect,
        ),
    ];
  }

  List<Widget> _enchant(BuildContext context, GameState s) {
    final c = s.character;
    final w = c.weapon;
    final next = WeaponInstance(
      weaponId: w.weaponId,
      upgrade: (w.upgrade + 1).clamp(0, w.def.maxUpgrade),
    );
    final stone = w.nextStone;
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              WeaponPreview(weapon: w, size: 130),
              Text(w.displayName, style: const TextStyle(color: Palette.holy)),
            ],
          ),
          if (stone != null) const Icon(Icons.arrow_forward, color: Palette.gold),
          if (stone != null)
            Column(
              children: [
                WeaponPreview(weapon: next, size: 130),
                Text('+${next.upgrade}', style: titleStyle(size: 16)),
              ],
            ),
        ],
      ),
      const SizedBox(height: 12),
      _UpgradePreview(level: w.upgrade, max: w.def.maxUpgrade),
      const SizedBox(height: 12),
      Text(
        'Potere d\'attacco ${w.attackRating(c).round()}'
        '${stone != null ? ' → ${next.attackRating(c).round()}' : ''}',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      if (stone != null)
        FilledButton(
          onPressed: (c.materials[stone] ?? 0) >= w.nextStoneCost
              ? () async {
                  final ok = await craftCountdown(
                    context,
                    title: 'Incanta a +${w.upgrade + 1}',
                    itemId: stone,
                    color: Station.enchant.accent,
                    sound: Sfx.craftEnchant,
                  );
                  if (!ok || !context.mounted) return;
                  s.upgradeWeapon(w);
                  toast(context, '${w.displayName}: l\'acciaio canta.');
                }
              : null,
          child: Text(
            'INCANTA A +${w.upgrade + 1} '
            '(${w.nextStoneCost}× ${materialNames[stone]}, hai ${c.materials[stone] ?? 0})',
          ),
        )
      else
        const Text(
          'Potenziamento massimo raggiunto',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.goldBright),
        ),
      const SectionTitle('Le quattro aure'),
      for (final a in Affinity.values)
        ActionTile(
          icon: Icons.blur_on,
          color: a.color,
          title: '${a.label} · ${a.attributeLabel}',
          subtitle: switch (a) {
            Affinity.fire => 'Lama rossa, a +10 avvolta dal fuoco',
            Affinity.wind => 'Lama verde, a +10 vortici di vento',
            Affinity.arcane => 'Lama blu, a +10 neon azzurro e puntini di luce',
            Affinity.holy => 'Lama d\'oro, a +10 aura luminosa e fulmini oro-azzurri',
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
    required this.color,
    this.sound = Sfx.confirm,
    this.itemId,
    this.have,
    this.note,
    this.done = false,
  });

  final String title;
  final Sfx sound;
  final Map<String, int> inputs;
  final int level;
  final bool unlocked;
  final bool canMake;
  final VoidCallback onMake;
  final IconData icon;
  final String stationLabel;
  final Color color;
  final String? itemId;
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
      color: unlocked ? color : Palette.iron,
      title: '$title${have != null && have! > 0 ? '  ·  hai $have' : ''}',
      subtitle: unlocked ? [?note, needs].join('\n') : 'Si sblocca a $stationLabel livello $level',
      enabled: unlocked,
      trailing: done
          ? const Icon(Icons.check, color: Palette.goldBright)
          : !unlocked
          ? null
          : FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Palette.night,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 36),
              ),
              onPressed: canMake
                  ? () async {
                      if (await craftCountdown(context, title: title, itemId: itemId, color: color, sound: sound)) {
                        onMake();
                      }
                    }
                  : null,
              child: const Text('CREA'),
            ),
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

/// Il suono di fine lavorazione di ogni postazione.
Sfx stationSound(Station s) => switch (s) {
      Station.carpentry => Sfx.craftCarpentry,
      Station.furnace => Sfx.craftFurnace,
      Station.anvil => Sfx.craftAnvil,
      Station.enchant => Sfx.craftEnchant,
    };
