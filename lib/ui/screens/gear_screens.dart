import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';
import '../../core/i18n.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/market.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../../core/sound.dart';
import '../widgets/weapon_sockets.dart';
import 'armory_screen.dart';
import 'codex_screen.dart';

export 'armory_screen.dart' show EquipmentScreen, GearSlot;

void openEquipment(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EquipmentScreen()));

void openInventory(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventoryScreen()));

void openMarket(BuildContext context, {int tab = 0}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(initialTab: tab)));

/// Tutto quello che il cavaliere porta nella bisaccia: oggetti e risorse,
/// e in pagine separate armi e armature.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: OathBar(
          title: Text(tr('INVENTARIO')),
          actions: [
            IconButton(
              tooltip: tr('Codice del Giuramento'),
              icon: const Icon(Icons.auto_stories, color: Palette.goldBright),
              onPressed: () => openCodex(context),
            ),
          ],
          bottom: TabBar(
            tabs: [Tab(text: tr('Oggetti')), Tab(text: tr('Armi')), Tab(text: tr('Armature'))],
          ),
        ),
        body: const TabBarView(children: [_Items(), _Weapons(), _Armors()]),
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final owned = c.materials.entries.where((e) => e.value > 0).toList();
    final amulets = owned.where((e) => e.key.startsWith('amulet_')).toList();
    final tools = owned.where((e) => isTool(e.key)).toList();
    final stones = owned
        .where((e) => !amulets.contains(e) && (e.key.contains('stone') || e.key == 'holy_shard'))
        .toList();
    final mats = owned
        .where((e) => !tools.contains(e) && !stones.contains(e) && !amulets.contains(e))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.diamond_outlined, color: Palette.gold),
            const SizedBox(width: 8),
            Text(tr('{runes} rune', {'runes': c.runes}), style: titleStyle(size: 20)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => openMarket(context),
              icon: const Icon(Icons.storefront),
              label: Text(tr('MERCATO')),
            ),
          ],
        ),
        if (owned.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              tr('Vuoto. Sconfiggi mostri e cammina per raccogliere materiali.'),
              style: const TextStyle(color: Palette.ash),
            ),
          ),
        if (tools.isNotEmpty) ...[
          SectionTitle(tr('Attrezzi')),
          for (final t in tools)
            ActionTile(
              icon: Icons.handyman,
              title: materialNames[t.key] ?? t.key,
              subtitle: tr('+{pct}% di raccolta camminando', {'pct': ((toolYield[t.key] ?? 0) * 100).round()}),
              onTap: () => openCodex(context, t.key),
            ),
        ],
        if (stones.isNotEmpty) ...[SectionTitle(tr('Pietre e reliquie')), _grid(stones)],
        if (amulets.isNotEmpty) ...[SectionTitle(tr('Amuleti nella borsa')), _grid(amulets)],
        if (mats.isNotEmpty) ...[SectionTitle(tr('Materiali')), _grid(mats)],
      ],
    );
  }
}

class _Weapons extends StatelessWidget {
  const _Weapons();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(tr('Armi')),
        for (final w in [c.weapon, ...c.weapons])
          ActionTile(
            icon: identical(w, c.weapon) ? Icons.check_circle : Icons.gavel,
            color: identical(w, c.weapon) ? Palette.goldBright : Palette.gold,
            title: w.displayName,
            onTap: () => openCodex(context, w.weaponId),
            subtitle: tr('{style} · potere {power}', {'style': w.def.style.label, 'power': w.attackRating(c).round()}) +
                (identical(w, c.weapon) ? tr(' · impugnata') : ''),
          ),
        if (c.offhands.isNotEmpty) ...[
          SectionTitle(tr('Mano sinistra')),
          for (final id in c.offhands)
            ActionTile(
              icon: c.offhandId == id ? Icons.check_circle : Icons.shield_moon_outlined,
              color: c.offhandId == id ? Palette.goldBright : Palette.gold,
              title: offhandDefs[id]!.name,
              subtitle: offhandDefs[id]!.effect,
              onTap: () => openCodex(context, id),
            ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => openEquipment(context),
          icon: const Icon(Icons.shield),
          label: Text(tr('Cambia in Armeria')),
        ),
      ],
    );
  }
}

class _Armors extends StatelessWidget {
  const _Armors();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(tr('Armature')),
        if (c.armors.isEmpty)
          Text(
            tr('Nessuna armatura: la prima si forgia all\'Incudine.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          ),
        for (final id in c.armors)
          ActionTile(
            icon: Icons.shield_outlined,
            title: armorDefs[id]!.name,
            onTap: () => openCodex(context, id),
            subtitle: [
              for (final slot in ArmorSlot.values)
                if (c.worn[slot] == id) slot.label,
            ].join(', ').addosso,
          ),
        SectionTitle(tr('Mantelli')),
        for (final id in c.capes)
          ActionTile(
            icon: Icons.dry_cleaning,
            color: Color(capeDefs[id]!.color).withValues(alpha: 1),
            title: capeDefs[id]!.name,
            subtitle: c.capeId == id ? tr('Addosso') : capeDefs[id]!.effect,
            onTap: () => openCodex(context, id),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => openEquipment(context),
          icon: const Icon(Icons.shield),
          label: Text(tr('Cambia in Armeria')),
        ),
      ],
    );
  }
}

/// Come una borsa: icona, quantità e nome per ogni oggetto.
Widget _grid(List<MapEntry<String, int>> items) => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.78,
      children: [
        for (final m in items)
          Card(
            margin: EdgeInsets.zero,
            child: CodexTap(
              m.key,
              child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ItemIcon(m.key, size: 40),
                      Positioned(
                        right: -10,
                        bottom: -4,
                        child: Text(
                          '${m.value}',
                          style: titleStyle(size: 13, color: Palette.holy, spacing: 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemName(m.key),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Palette.ash, height: 1.1),
                  ),
                ],
              ),
            ),
            ),
          ),
      ],
    );

/// Il Mercato: Mercante (compra e vendi) e Fattucchiera (amuleti).
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final runes = context.select<GameState, int>((s) => s.character.runes);
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: OathBar(
          accent: Sections.market,
          title: Text(tr('MERCATO')),
          actions: [
            Center(
              child: Text('${tr('{runes} rune', {'runes': runes})}  ', style: const TextStyle(color: Palette.goldBright)),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: tr('Mercante')),
              Tab(text: tr('Fattucchiera')),
            ],
          ),
        ),
        body: const TabBarView(children: [_Merchant(), _Witch()]),
      ),
    );
  }
}

class _Merchant extends StatelessWidget {
  const _Merchant();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final toSell = c.materials.entries.where((e) => e.value > 0 && sellable(e.key)).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(tr('Vendi')),
        if (toSell.isEmpty && c.weapons.isEmpty)
          Text(tr('Niente da vendere.'), style: const TextStyle(color: Palette.ash)),
        for (final e in toSell)
          ActionTile(
            icon: Icons.sell_outlined,
            title: materialNames[e.key] ?? e.key,
            subtitle: tr('Hai {n} · {price} rune l\'uno', {'n': e.value, 'price': sellPrice(e.key)}) +
                (e.value > 1 ? tr(', tutti {total}', {'total': sellPrice(e.key) * e.value}) : ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SmallButton(tr('VENDI 1'), () {
                  s.sellMaterial(e.key);
                  Sound.play(Sfx.sell);
                }),
                if (e.value > 1)
                  _SmallButton(tr('TUTTI'), () {
                    s.sellMaterial(e.key, e.value);
                    Sound.play(Sfx.sell);
                  }),
              ],
            ),
          ),
        for (final w in List.of(c.weapons))
          ActionTile(
            icon: Icons.gavel,
            title: w.displayName,
            onTap: () => openCodex(context, w.weaponId),
            subtitle: tr('Arma nella rastrelliera'),
            trailing: TextButton(
              onPressed: () {
                s.sellWeapon(w);
                Sound.play(Sfx.sell);
              },
              child: Text(tr('{runes} rune', {'runes': weaponValue(w)})),
            ),
          ),
        SectionTitle(tr('Compra')),
        for (final id in merchantStock)
          ActionTile(
            icon: Icons.shopping_bag_outlined,
            title: materialNames[id] ?? id,
            subtitle: tr('Hai {n}', {'n': c.materials[id] ?? 0}),
            trailing: TextButton(
              onPressed: () {
                if (s.buyMaterial(id)) {
                  Sound.play(Sfx.buy);
                } else {
                  Sound.play(Sfx.locked);
                  toast(context, tr('Rune insufficienti'));
                }
              },
              child: Text(tr('{runes} rune', {'runes': buyPrice(id)})),
            ),
          ),
        SectionTitle(tr('Mantelli')),
        for (final cape in capeDefs.values.where((x) => x.price > 0))
          ActionTile(
            icon: Icons.dry_cleaning,
            color: Color(cape.color).withValues(alpha: 1),
            title: cape.name,
            subtitle: c.capes.contains(cape.id) ? tr('Già tuo') : cape.effect,
            trailing: c.capes.contains(cape.id)
                ? null
                : TextButton(
                    onPressed: () {
                      if (s.buyCape(cape.id)) {
                        Sound.play(Sfx.buy);
                      } else {
                        Sound.play(Sfx.locked);
                        toast(context, tr('Rune insufficienti'));
                      }
                    },
                    child: Text(tr('{runes} rune', {'runes': cape.price})),
                  ),
          ),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: onPressed,
        child: Text(label),
      );
}

class _Witch extends StatelessWidget {
  const _Witch();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final w = s.character.weapon;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(w.displayName),
        WeaponSockets(weapon: w),
        SectionTitle(tr('Affinità')),
        for (final e in amuletRecipes.entries)
          ActionTile(
            icon: Icons.brightness_7,
            color: amuletDefs[e.key]!.apply.aura!.color,
            title: amuletDefs[e.key]!.name,
            subtitle: e.value.entries
                .map((m) => '${m.value}× ${itemName(m.key)} (${s.character.materials[m.key] ?? 0})')
                .join(' · '),
            trailing: FilledButton(
              onPressed: s.canCraftAmulet(e.key)
                  ? () async {
                      final ok = await craftCountdown(
                        context,
                        title: amuletDefs[e.key]!.name,
                        itemId: 'amulet_${e.key}',
                        color: amuletDefs[e.key]!.apply.aura!.color,
                        sound: Sfx.craftEnchant,
                      );
                      if (ok && context.mounted) s.craftAmulet(e.key);
                    }
                  : null,
              child: Text(tr('CREA')),
            ),
          ),
        SectionTitle(tr('Passivi')),
        for (final a in amuletDefs.values.where((a) => !a.isAffinity && amuletPrices[a.id] != null))
          ActionTile(
            icon: Icons.brightness_7_outlined,
            title: a.name,
            subtitle: a.description +
                (s.amuletCount(a.id) > 0 ? tr(' · ne hai {n}', {'n': s.amuletCount(a.id)}) : ''),
            trailing: TextButton(
              onPressed: () {
                if (s.buyAmulet(a.id, amuletPrices[a.id]!)) {
                  Sound.play(Sfx.buy);
                } else {
                  Sound.play(Sfx.locked);
                  toast(context, tr('Rune insufficienti'));
                }
              },
              child: Text(tr('{runes} rune', {'runes': amuletPrices[a.id]})),
            ),
          ),
      ],
    );
  }
}

extension on String {
  String get addosso => isEmpty ? tr('Nella borsa') : tr('Addosso: {slots}', {'slots': this});
}
