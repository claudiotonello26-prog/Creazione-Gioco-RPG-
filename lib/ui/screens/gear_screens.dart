import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/items.dart';
import '../../domain/market.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';

void openEquipment(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EquipmentScreen()));

void openInventory(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InventoryScreen()));

void openMarket(BuildContext context, {int tab = 0}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(initialTab: tab)));

/// Quello che il cavaliere ha addosso: arma, armatura pezzo per pezzo, mano
/// sinistra e amuleti.
class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    return Scaffold(
      appBar: OathBar(title: const Text('EQUIPAGGIAMENTO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: KnightView(character: c, height: 220)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _Big('Attacco', '${s.attackValue}', Palette.goldBright)),
              Expanded(child: _Big('Difesa', '${(s.defenseValue * 100).round()}%', Palette.frost)),
              Expanded(child: _Big('Vita', '${c.maxHp}', Palette.blood)),
            ],
          ),
          const SectionTitle('Armi'),
          for (final w in [c.weapon, ...c.weapons])
            ActionTile(
              icon: identical(w, c.weapon)
                  ? Icons.check_circle
                  : s.canWield(w.def)
                      ? Icons.gavel
                      : Icons.lock_outline,
              title: w.displayName,
              subtitle: '${w.def.style.label}${w.def.oneHanded ? ' a una mano' : ' a due mani'}'
                  ' · potere ${w.attackRating(c).round()}'
                  '${identical(w, c.weapon) ? ' · impugnata' : s.canWield(w.def) ? ' · tocca per impugnare' : ' · serve ${w.def.usesMagic ? 'Magia' : 'Attacco'} ${w.def.wieldLevel}'}',
              color: identical(w, c.weapon)
                  ? Palette.goldBright
                  : s.canWield(w.def)
                      ? Palette.gold
                      : Palette.ash,
              onTap: identical(w, c.weapon) || !s.canWield(w.def) ? null : () => s.equip(w),
            ),
          const SectionTitle('Armatura'),
          if (c.armors.isEmpty)
            const Text(
              'Nessuna armatura: la prima si forgia all\'Incudine.',
              style: TextStyle(color: Palette.ash),
            ),
          if (c.armors.isNotEmpty)
            for (final slot in ArmorSlot.values)
              ActionTile(
                icon: Icons.shield_outlined,
                title: '${slot.label}: ${c.piece(slot)?.name ?? 'nessuno'}',
                subtitle:
                    'Vale il ${(slot.weight * 100).round()}% della protezione · tocca per cambiare',
                color: c.piece(slot) != null ? Palette.goldBright : Palette.ash,
                onTap: () => _pickPiece(context, s, slot),
              ),
          const SectionTitle('Mano sinistra'),
          if (c.offhands.isEmpty)
            const Text(
              'Niente in mano sinistra. Lo scudo di legno si fa in Carpenteria.',
              style: TextStyle(color: Palette.ash),
            ),
          if (c.offhands.isNotEmpty && !c.weapon.def.oneHanded)
            Text(
              '${c.weapon.def.name} si impugna a due mani: scudo e seconda lama restano sulla schiena.',
              style: const TextStyle(color: Palette.ash),
            ),
          for (final id in c.offhands)
            ActionTile(
              icon: c.offhandId == id ? Icons.check_circle : Icons.shield_moon_outlined,
              title: offhandDefs[id]!.name,
              subtitle: '${offhandDefs[id]!.effect}'
                  '${c.offhandId == id ? ' · in mano' : ' · tocca per impugnare'}',
              color: c.offhandId == id ? Palette.goldBright : Palette.gold,
              onTap: () => s.holdOffhand(c.offhandId == id ? null : id),
            ),
          SectionTitle('Amuleti (${c.amulets.length}/${Character.maxAmuletSlots})'),
          if (!amuletDefs.keys.any(s.ownsAmulet))
            const Text(
              'Nessun amuleto. Li vende la Fattucchiera al Mercato.',
              style: TextStyle(color: Palette.ash),
            ),
          for (final a in amuletDefs.values.where((a) => s.ownsAmulet(a.id)))
            ActionTile(
              icon: Icons.brightness_7_outlined,
              title: a.name,
              subtitle: a.description,
              color: c.amulets.contains(a.id) ? Palette.goldBright : Palette.ash,
              trailing: Switch(
                value: c.amulets.contains(a.id),
                onChanged: (_) => s.toggleAmulet(a.id),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => openMarket(context, tab: 1),
            icon: const Icon(Icons.storefront),
            label: const Text('Vai dalla Fattucchiera'),
          ),
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: titleStyle(size: 22, color: color, spacing: 0)),
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: Palette.ash, fontSize: 11, letterSpacing: 1),
          ),
        ],
      );
}

void _pickPiece(BuildContext context, GameState s, ArmorSlot slot) {
  final c = s.character;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.night,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(slot.label),
          for (final id in [null, ...c.armors])
            ActionTile(
              icon: c.worn[slot] == id ? Icons.check_circle : Icons.shield_outlined,
              title: id == null ? 'Nessuno' : armorDefs[id]!.name,
              subtitle: id == null
                  ? 'Solo la tunica'
                  : s.canWear(id)
                      ? 'Assorbe il ${(armorDefs[id]!.reduction * slot.weight * 100).round()}% dei colpi'
                      : 'Serve Difesa ${armorDefs[id]!.wearLevel}',
              color: c.worn[slot] == id ? Palette.goldBright : Palette.gold,
              onTap: id != null && !s.canWear(id)
                  ? null
                  : () {
                      s.wearPiece(slot, id);
                      Navigator.pop(ctx);
                    },
            ),
        ],
      ),
    ),
  );
}

/// Tutto quello che il cavaliere porta nella bisaccia.
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final owned =
        c.materials.entries.where((e) => e.value > 0 && !e.key.startsWith('amulet_')).toList();
    final tools = owned.where((e) => isTool(e.key)).toList();
    final stones = owned.where((e) => e.key.contains('stone') || e.key == 'holy_shard').toList();
    final mats = owned.where((e) => !tools.contains(e) && !stones.contains(e)).toList();
    return Scaffold(
      appBar: OathBar(title: const Text('INVENTARIO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.diamond_outlined, color: Palette.gold),
              const SizedBox(width: 8),
              Text('${c.runes} rune', style: titleStyle(size: 20)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => openMarket(context),
                icon: const Icon(Icons.storefront),
                label: const Text('MERCATO'),
              ),
            ],
          ),
          if (owned.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Vuoto. Sconfiggi mostri e cammina per raccogliere materiali.',
                style: TextStyle(color: Palette.ash),
              ),
            ),
          if (tools.isNotEmpty) ...[
            const SectionTitle('Attrezzi'),
            for (final t in tools)
              ActionTile(
                icon: Icons.handyman,
                title: materialNames[t.key] ?? t.key,
                subtitle: '+${((toolYield[t.key] ?? 0) * 100).round()}% di raccolta camminando',
              ),
          ],
          if (stones.isNotEmpty) ...[const SectionTitle('Pietre e reliquie'), _grid(stones)],
          if (mats.isNotEmpty) ...[const SectionTitle('Materiali'), _grid(mats)],
          if (c.weapons.isNotEmpty) ...[
            const SectionTitle('Armi nella rastrelliera'),
            for (final w in c.weapons)
              ActionTile(icon: Icons.gavel, title: w.displayName, subtitle: w.def.style.label),
          ],
        ],
      ),
    );
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
        ],
      );
}

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
          title: const Text('MERCATO'),
          actions: [
            Center(
              child: Text('$runes rune  ', style: const TextStyle(color: Palette.goldBright)),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mercante'),
              Tab(text: 'Fattucchiera'),
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
        const Text(
          '"Compro tutto, a metà prezzo. Vendo poco, al doppio. È il mercato, cavaliere."',
          style: TextStyle(color: Palette.ash, fontStyle: FontStyle.italic),
        ),
        const SectionTitle('Vendi'),
        if (toSell.isEmpty && c.weapons.isEmpty)
          const Text('Niente da vendere.', style: TextStyle(color: Palette.ash)),
        for (final e in toSell)
          ActionTile(
            icon: Icons.sell_outlined,
            title: materialNames[e.key] ?? e.key,
            subtitle: 'Hai ${e.value} · ${sellPrice(e.key)} rune l\'uno'
                '${e.value > 1 ? ', tutti ${sellPrice(e.key) * e.value}' : ''}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SmallButton('VENDI 1', () => s.sellMaterial(e.key)),
                if (e.value > 1) _SmallButton('TUTTI', () => s.sellMaterial(e.key, e.value)),
              ],
            ),
          ),
        for (final w in List.of(c.weapons))
          ActionTile(
            icon: Icons.gavel,
            title: w.displayName,
            subtitle: 'Arma nella rastrelliera',
            trailing: TextButton(
              onPressed: () => s.sellWeapon(w),
              child: Text('${weaponValue(w)} rune'),
            ),
          ),
        const SectionTitle('Compra'),
        for (final id in merchantStock)
          ActionTile(
            icon: Icons.shopping_bag_outlined,
            title: materialNames[id] ?? id,
            subtitle: 'Hai ${c.materials[id] ?? 0}',
            trailing: TextButton(
              onPressed: () {
                if (!s.buyMaterial(id)) toast(context, 'Rune insufficienti');
              },
              child: Text('${buyPrice(id)} rune'),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '"Un amuleto non ti rende forte. Ti rende... diverso." Ne puoi portare tre.',
          style: TextStyle(color: Palette.ash, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        for (final a in amuletDefs.values)
          ActionTile(
            icon: Icons.brightness_7_outlined,
            title: a.name,
            subtitle: a.description,
            color: s.ownsAmulet(a.id) ? Palette.goldBright : Palette.gold,
            trailing: s.ownsAmulet(a.id)
                ? const Icon(Icons.check, color: Palette.goldBright)
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
