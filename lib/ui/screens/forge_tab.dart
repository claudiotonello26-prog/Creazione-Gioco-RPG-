import 'dart:math';

import 'package:flutter/material.dart';

import 'codex_screen.dart';
import '../../domain/codex.dart';

import '../widgets/oath_bar.dart';
import '../../core/i18n.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/element_badge.dart';
import '../widgets/weapon_sockets.dart';
import '../widgets/knight_view.dart';
import 'gear_screens.dart';
import '../../core/sound.dart';

IconData styleIcon(WeaponStyle s) => switch (s) {
  WeaponStyle.melee => Icons.colorize,
  WeaponStyle.ranged => Icons.call_made,
  WeaponStyle.magic => Icons.auto_fix_high,
};

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
    Widget station(Station st) => _StationButton(
          station: st,
          level: st == Station.enchant ? null : s.stationLevel(st),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => StationScreen(station: st))),
        );
    final st = Station.values;
    final tiles = [
      if (s.repairAllCost > 0) const _RepairTile(),
      ActionTile(
        icon: Icons.shield,
        title: tr('Equipaggiamento'),
        color: Palette.goldBright,
        onTap: () => openEquipment(context),
      ),
      ActionTile(
        icon: Icons.auto_stories,
        title: tr('Codice del Giuramento'),
        onTap: () => openCodex(context),
      ),
    ];
    // Le quattro postazioni si allargano a riempire lo schermo.
    return FillPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sempre quadrate, il più grandi possibile; postazioni e scorciatoie
          // stanno insieme, centrate nella pagina.
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              const gap = 10.0;
              final rows = (st.length + 1) ~/ 2;
              final reserve = 12 + 80.0 * (tiles.length);
              final side = min((box.maxWidth - gap) / 2, (box.maxHeight - reserve - gap * (rows - 1)) / rows);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var r = 0; r < st.length; r += 2) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(dimension: side, child: station(st[r])),
                        const SizedBox(width: gap),
                        SizedBox.square(
                            dimension: side, child: r + 1 < st.length ? station(st[r + 1]) : null),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...tiles,
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Manutenzione: un solo tasto ripara arma e armature con le rune.
class _RepairTile extends StatelessWidget {
  const _RepairTile();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final cost = s.repairAllCost;
    final worn = s.gearWornOut;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.build, color: worn ? Palette.ember : Palette.ash, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Manutenzione'), style: titleStyle(size: 15, color: worn ? Palette.ember : Palette.holy)),
                  const SizedBox(height: 4),
                  WearBar(s.worstWear, width: 120),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: s.character.runes >= cost
                  ? () {
                      if (s.repairAll()) {
                        Sound.play(Sfx.confirm);
                        toast(context, tr('Tutto riparato.'));
                      }
                    }
                  : null,
              icon: const Icon(Icons.hardware, size: 18),
              label: Text(tr('{runes} rune', {'runes': cost})),
            ),
          ],
        ),
      ),
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
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
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
                child: Icon(stationIcon(station), color: station.accent, size: 48),
              ),
              const SizedBox(height: 14),
              FittedBox(
                child: Text(
                  station.label.toUpperCase(),
                  style: titleStyle(size: 16, color: station.accent),
                ),
              ),
              Text(
                level == null ? tr('Potenzia l\'arma') : tr('Liv. {n}', {'n': level}),
                style: const TextStyle(color: Palette.ash, fontSize: 15),
              ),
            ],
          ),
            ),
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
    // Solo quello che si può già fare, più la prossima cosa da sbloccare:
    // il resto compare salendo di livello.
    final mats = unlockedPlusNext(
        materialRecipes.where((r) => r.station == station).toList(), (r) => r.level, lvl);
    final weapons = unlockedPlusNext(
        weaponDefs.values.where((d) => d.recipe.isNotEmpty && d.station == station).toList(),
        (d) => d.craftLevel,
        lvl);
    final armors = unlockedPlusNext(
        station == Station.anvil ? armorDefs.values.toList() : <ArmorDef>[],
        (a) => a.craftLevel,
        lvl);
    final offhands = unlockedPlusNext(
        offhandDefs.values.where((o) => o.station == station).toList(), (o) => o.craftLevel, lvl);
    return [
      // Icona, livello e barra in una riga; la descrizione sta dietro il "?".
      Row(
        children: [
          Icon(stationIcon(station), color: station.accent, size: 36),
          const SizedBox(width: 10),
          Text(tr('Liv. {n}', {'n': lvl}), style: titleStyle(size: 17, color: station.accent)),
          const SizedBox(width: 12),
          Expanded(
            child: StatBar(value: xpIn / xpNeed, color: Palette.gold, label: '$xpIn / $xpNeed XP'),
          ),
          HelpButton(station.description),
        ],
      ),
      if (mats.isNotEmpty) SectionTitle(tr('Lavorazioni')),
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
      if (weapons.isNotEmpty) SectionTitle(tr('Armi')),
      for (final d in weapons)
        _RecipeTile(
          title: d.name,
          inputs: d.recipe,
          level: d.craftLevel,
          unlocked: lvl >= d.craftLevel,
          canMake: s.canCraft(d),
          onMake: () {
            s.craftWeapon(d);
            toast(
                context,
                tr('{weapon} ({quality}) è pronta: impugnala dall\'Armeria.',
                    {'weapon': d.name, 'quality': s.lastCraftQuality!.label}));
          },
          icon: Icons.gavel,
          stationLabel: station.label,
          color: station.accent,
          sound: stationSound(station),
          itemId: d.id,
          stats: [
            StatChip(styleIcon(d.style), '${d.baseDamage}'),
            StatChip(Icons.auto_awesome, d.affinity.label, color: d.affinity.color),
            if (lvl >= d.craftLevel) QualityPips(s.craftQuality(station, d.craftLevel)),
            if (d.wieldLevel > 1)
              StatChip(
                d.usesMagic ? Icons.auto_fix_high : Icons.colorize,
                'Lv ${d.wieldLevel}',
                color: Palette.ash,
              ),
          ],
        ),
      if (armors.isNotEmpty) SectionTitle(tr('Armature')),
      for (final a in armors)
        _RecipeTile(
          title: a.name,
          inputs: a.recipe,
          level: a.craftLevel,
          unlocked: lvl >= a.craftLevel,
          canMake: s.canCraftArmor(a),
          done: s.character.armors.contains(a.id) && !s.canReforgeArmor(a),
          onMake: () {
            s.craftArmor(a);
            toast(context,
                tr('{armor} ({quality}) indossata.', {'armor': a.name, 'quality': s.lastCraftQuality!.label}));
          },
          icon: Icons.shield_outlined,
          stationLabel: station.label,
          color: station.accent,
          sound: stationSound(station),
          itemId: a.id,
          stats: [
            StatChip(Icons.shield, '-${(a.reduction * 100).round()}%'),
            if (lvl >= a.craftLevel) QualityPips(s.craftQuality(Station.anvil, a.craftLevel)),
            if (s.canReforgeArmor(a)) StatChip(Icons.upgrade, tr('Riforgia'), color: Palette.goldBright),
            if (a.wearLevel > 1) StatChip(Icons.lock_open, 'Lv ${a.wearLevel}', color: Palette.ash),
          ],
        ),
      if (offhands.isNotEmpty) SectionTitle(tr('Mano sinistra')),
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
            toast(context, tr('{item} in mano (con un\'arma a una mano).', {'item': o.name}));
          },
          icon: o.isShield ? Icons.shield_moon_outlined : Icons.gavel,
          stationLabel: station.label,
          color: station.accent,
          sound: stationSound(station),
          itemId: o.id,
          stats: [
            o.isShield
                ? StatChip(Icons.shield, '-${(o.reduction * 100).round()}%')
                : StatChip(Icons.colorize, '+${(o.damageBonus * 100).round()}%'),
          ],
        ),
    ];
  }

  List<Widget> _enchant(BuildContext context, GameState s) {
    final c = s.character;
    final w = c.weapon;
    final next = WeaponInstance(
      weaponId: w.weaponId,
      upgrade: (w.upgrade + 1).clamp(0, w.def.maxUpgrade),
      quality: w.quality,
      wear: w.wear,
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
        tr('Potere d\'attacco {power}', {'power': w.attackRating(c).round()}) +
            (stone != null ? ' → ${next.attackRating(c).round()}' : ''),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      if (stone != null)
        _StoneButton(
          stone: stone,
          cost: w.nextStoneCost,
          have: c.materials[stone] ?? 0,
          runes: w.nextRuneCost,
          haveRunes: c.runes,
          level: w.upgrade + 1,
          onTap: () async {
            final ok = await craftCountdown(
              context,
              title: '${w.def.name} +${w.upgrade + 1}',
              itemId: stone,
              color: Station.enchant.accent,
              sound: Sfx.craftEnchant,
            );
            if (!ok || !context.mounted) return;
            s.upgradeWeapon(w);
            toast(context, tr('{weapon}: l\'acciaio canta.', {'weapon': w.displayName}));
          },
        )
      else
        Text(
          tr('Potenziamento massimo raggiunto'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.goldBright),
        ),
      SectionTitle(tr('Amuleti')),
      WeaponSockets(weapon: w),
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
    this.stats = const [],
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

  /// I numeri che contano (danno, difesa, livello per usarlo), come icone.
  final List<Widget> stats;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final s = context.read<GameState>();
    final entry = itemId == null ? null : codexEntry(itemId!);
    final button = done
        ? const Icon(Icons.check_circle, color: Palette.goldBright, size: 30)
        : !unlocked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: Palette.iron, size: 24),
              Text('Lv $level', style: const TextStyle(color: Palette.ash, fontSize: 15)),
            ],
          )
        : FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Palette.night,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 36),
            ),
            onPressed: canMake
                ? () async {
                    if (await craftCountdown(
                      context,
                      title: title,
                      itemId: itemId,
                      color: color,
                      sound: sound,
                    )) {
                      onMake();
                    }
                  }
                : null,
            child: Text(tr('CREA')),
          );
    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: Card(
        child: InkWell(
          onTap: itemId == null ? null : () => openCodex(context, itemId),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                entry != null ? CodexIcon(entry, size: 44) : Icon(icon, color: color, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: OneLine(title, style: const TextStyle(fontSize: 16))),
                          if (have != null && have! > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '×$have',
                              style: const TextStyle(
                                color: Palette.goldBright,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Wrap(spacing: 10, runSpacing: 2, children: stats),
                      ],
                      const SizedBox(height: 5),
                      CostRow(
                        needs: inputs,
                        have: s.character.materials,
                        onTapItem: (id) => openCodex(context, id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                button,
              ],
            ),
          ),
        ),
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

/// Il potenziamento è la pietra stessa: si tocca la pietra per salire di
/// un livello.
class _StoneButton extends StatelessWidget {
  const _StoneButton({
    required this.stone,
    required this.cost,
    required this.have,
    required this.runes,
    required this.haveRunes,
    required this.level,
    required this.onTap,
  });
  final String stone;
  final int cost;
  final int have;

  /// Rune del potenziamento e rune del giocatore.
  final int runes;
  final int haveRunes;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enoughRunes = haveRunes >= runes;
    final ok = have >= cost && enoughRunes;
    final accent = Station.enchant.accent;
    return Opacity(
      opacity: ok ? 1 : 0.55,
      child: Material(
        color: Palette.stoneLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: ok ? accent : Palette.iron, width: 1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: ok
              ? onTap
              : () => toast(
                  context,
                  have < cost
                      ? tr('Ti servono {cost}× {item}.', {'cost': cost, 'item': itemName(stone)})
                      : tr('Ti servono {runes} rune.', {'runes': runes}),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                ItemIcon(stone, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneLine(itemName(stone), style: titleStyle(size: 14, spacing: 1)),
                      const SizedBox(height: 4),
                      Text(
                        tr('{cost}× · ne hai {n}', {'cost': cost, 'n': have}),
                        style: TextStyle(color: have >= cost ? Palette.holy : Palette.ash),
                      ),
                      Text(
                        tr('{runes} rune', {'runes': runes}),
                        style: TextStyle(color: enoughRunes ? Palette.holy : Palette.ash),
                      ),
                    ],
                  ),
                ),
                Text('+$level', style: titleStyle(size: 28, color: ok ? accent : Palette.ash)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
