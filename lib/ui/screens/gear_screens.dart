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
                    style: const TextStyle(fontSize: 15, color: Palette.ash, height: 1.1),
                  ),
                ],
              ),
            ),
            ),
          ),
      ],
    );

/// Il Mercato: le botteghe dei mercanti e la Fattucchiera (amuleti).
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: OathBar(
          accent: Sections.market,
          title: Text(tr('MERCATO')),
          actions: const [_Runes()],
          bottom: TabBar(
            tabs: [
              Tab(text: tr('Botteghe')),
              Tab(text: tr('Fattucchiera')),
            ],
          ),
        ),
        body: const TabBarView(children: [_Shops(), _Witch()]),
      ),
    );
  }
}

class _Runes extends StatelessWidget {
  const _Runes();

  @override
  Widget build(BuildContext context) {
    final runes = context.select<GameState, int>((s) => s.character.runes);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.diamond_outlined, color: Palette.goldBright, size: 18),
      const SizedBox(width: 4),
      Text('$runes', style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold)),
    ]);
  }
}

extension ShopLook on ShopKeeper {
  Color get color => switch (this) {
        ShopKeeper.general => Palette.gold,
        ShopKeeper.smith => Palette.frost,
        ShopKeeper.hunter => const Color(0xFF7FC25A),
        ShopKeeper.mage => const Color(0xFF9B6BE0),
      };

  IconData get icon => switch (this) {
        ShopKeeper.general => Icons.storefront,
        ShopKeeper.smith => Icons.hardware,
        ShopKeeper.hunter => Icons.pets,
        ShopKeeper.mage => Icons.auto_fix_high,
      };

  int levelIn(GameState s) => s.shopLevel(this);

  /// Gli articoli in vendita adesso, più il prossimo che si sblocca.
  List<ShopItem> stockFor(GameState s) =>
      unlockedPlusNext(shopStock[this]!, (i) => i.$2, levelIn(s));
}

void openShop(BuildContext context, ShopKeeper k) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopScreen(keeper: k)));

/// Un pulsante per bottega: il busto del mercante a sinistra, a destra il
/// nome e qualche articolo che vende.
class _Shops extends StatelessWidget {
  const _Shops();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    // Le quattro botteghe si dividono tutto lo schermo; il busto cresce con lo spazio.
    return FillPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final k in ShopKeeper.values)
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => openShop(context, k),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, box) => Row(
                        children: [
                          NpcBust(k.art,
                              icon: k.icon, color: k.color, size: (box.maxHeight / 1.15).clamp(60.0, 150.0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OneLine(k.role.toUpperCase(),
                                    align: Alignment.centerLeft,
                                    style: titleStyle(size: 19, spacing: 1.5).copyWith(color: k.color)),
                                const SizedBox(height: 2),
                                OneLine(k.name,
                                    align: Alignment.centerLeft,
                                    style: const TextStyle(color: Palette.ash, fontSize: 15)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    for (final (id, _) in k.stockFor(s).where((i) => i.$2 <= k.levelIn(s)).take(5))
                                      ItemIcon(id, size: 30),
                                    if (k == ShopKeeper.general)
                                      const Icon(Icons.sell_outlined, color: Palette.goldBright, size: 26),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: k.color, size: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una bottega: il mercante in grande, gli articoli al tuo livello (più il
/// prossimo, col lucchetto) e, all'Emporio, la vendita e i mantelli.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.keeper});
  final ShopKeeper keeper;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final k = keeper;
    final lvl = k.levelIn(s);
    return Scaffold(
      appBar: OathBar(
        accent: Sections.market,
        title: Text(k.role.toUpperCase()),
        actions: const [_Runes()],
      ),
      body: FoldedListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              NpcBust(k.art, icon: k.icon, color: k.color, size: 140),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.name, style: titleStyle(size: 18, spacing: 1).copyWith(color: k.color)),
                    const SizedBox(height: 6),
                    if (k.skill != null)
                      StatChip(Icons.trending_up, '${k.skill!.label} $lvl', color: Palette.ash),
                  ],
                ),
              ),
            ],
          ),
          SectionTitle(tr('Compra')),
          for (final (id, need) in k.stockFor(s))
            need <= lvl ? _BuyRow(id) : _LockedRow(id, need, k),
          if (k == ShopKeeper.general) ...[
            const _SellList(),
            const _Capes(),
          ],
        ],
      ),
    );
  }
}

/// Icona, nome, quanti ne hai e il prezzo sul pulsante.
class _BuyRow extends StatelessWidget {
  const _BuyRow(this.id);
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final weapon = weaponDefs[id];
    final price = weapon != null ? weaponBuyPrice(id) : buyPrice(id);
    final have = weapon != null
        ? s.character.weapons.where((w) => w.weaponId == id).length
        : s.character.materials[id] ?? 0;
    void buy() {
      if (weapon != null ? s.buyWeapon(id) : s.buyMaterial(id)) {
        Sound.play(Sfx.buy);
      } else {
        Sound.play(Sfx.locked);
        toast(context, tr('Rune insufficienti'));
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CodexTap(id, child: ItemIcon(id, size: 46)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLine(itemName(id), align: Alignment.centerLeft),
                  StatChip(Icons.inventory_2_outlined, '$have', color: Palette.ash),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: s.character.runes >= price ? buy : null,
              icon: const Icon(Icons.diamond_outlined, size: 18),
              label: Text('$price'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il prossimo articolo: si vede cos'è e a che livello arriva.
class _LockedRow extends StatelessWidget {
  const _LockedRow(this.id, this.level, this.keeper);
  final String id;
  final int level;
  final ShopKeeper keeper;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.5,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                CodexTap(id, child: ItemIcon(id, size: 46)),
                const SizedBox(width: 10),
                Expanded(child: OneLine(itemName(id), align: Alignment.centerLeft)),
                const Icon(Icons.lock_outline, color: Palette.ember, size: 20),
                const SizedBox(width: 4),
                Text(
                  keeper.skill == null
                      ? tr('Liv. {n}', {'n': level})
                      : '${keeper.skill!.label} $level',
                  style: const TextStyle(color: Palette.ember, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
}

/// L'Emporio compra tutto: materiali e armi della rastrelliera.
class _SellList extends StatelessWidget {
  const _SellList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final toSell = c.materials.entries.where((e) => e.value > 0 && sellable(e.key)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(tr('Vendi')),
        if (toSell.isEmpty && c.weapons.isEmpty)
          Text(tr('Niente da vendere.'), style: const TextStyle(color: Palette.ash)),
        for (final e in toSell)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  CodexTap(e.key, child: ItemIcon(e.key, size: 40)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLine(itemName(e.key), align: Alignment.centerLeft),
                        Row(children: [
                          StatChip(Icons.inventory_2_outlined, '${e.value}', color: Palette.ash),
                          const SizedBox(width: 10),
                          StatChip(Icons.diamond_outlined, '${sellPrice(e.key)}', color: Palette.goldBright),
                        ]),
                      ],
                    ),
                  ),
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
      ],
    );
  }
}

class _Capes extends StatelessWidget {
  const _Capes();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        for (final e in amuletRecipes.entries.where((e) => amuletDefs[e.key]!.isAffinity))
          ActionTile(
            icon: Icons.brightness_7,
            color: amuletDefs[e.key]!.apply.aura!.color,
            title: amuletDefs[e.key]!.name,
            below: CostRow(
              needs: e.value,
              have: s.character.materials,
              onTapItem: (id) => openCodex(context, id),
            ),
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
        // Gemme (nell'arma) e talismani (al collo) contro l'elemento di un
        // nemico: per i boss che battono la tua build.
        SectionTitle(tr('Contro gli elementi')),
        for (final e in amuletRecipes.entries.where((e) => !amuletDefs[e.key]!.isAffinity))
          Builder(builder: (context) {
            final a = amuletDefs[e.key]!;
            final el = a.apply.ward ?? a.apply.bane!;
            return ActionTile(
              icon: a.isWard ? Icons.shield_moon : Icons.diamond,
              color: el.color,
              title: a.name + (s.amuletCount(a.id) > 0 ? ' ×${s.amuletCount(a.id)}' : ''),
              subtitle: a.description,
              below: CostRow(
                needs: e.value,
                have: s.character.materials,
                onTapItem: (id) => openCodex(context, id),
              ),
              trailing: FilledButton(
                onPressed: s.canCraftAmulet(e.key)
                    ? () async {
                        final ok = await craftCountdown(
                          context,
                          title: a.name,
                          itemId: 'amulet_${e.key}',
                          color: el.color,
                          sound: Sfx.craftEnchant,
                        );
                        if (ok && context.mounted) s.craftAmulet(e.key);
                      }
                    : null,
                child: Text(tr('CREA')),
              ),
            );
          }),
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
