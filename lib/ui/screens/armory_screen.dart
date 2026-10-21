import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/items.dart';
import '../widgets/common.dart';
import '../widgets/element_badge.dart';
import '../widgets/knight_view.dart';
import '../widgets/oath_bar.dart';
import '../widgets/weapon_sockets.dart';
import 'gear_screens.dart';

/// I posti dell'Armeria intorno al cavaliere.
enum GearSlot {
  offhand('Mano sinistra'),
  weapon('Mano destra'),
  helm('Elmo'),
  chest('Corazza'),
  gloves('Bracciali'),
  legs('Gambali'),
  boots('Stivali'),
  neck('Amuleto'),
  cape('Mantello');

  const GearSlot(this._label);
  final String _label;
  String get label => tr(_label);

  ArmorSlot? get armor => switch (this) {
        helm => ArmorSlot.helm,
        chest => ArmorSlot.chest,
        gloves => ArmorSlot.gloves,
        legs => ArmorSlot.legs,
        boots => ArmorSlot.boots,
        _ => null,
      };
}

/// L'Armeria: il cavaliere intero al centro, i pezzi indossati intorno, i
/// totali e gli effetti; sotto, quello che si possiede per il posto scelto.
/// Toccare un oggetto lo indossa subito.
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key, this.initial = GearSlot.weapon});
  final GearSlot initial;

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  late GearSlot _slot = widget.initial;

  void _select(GearSlot slot) {
    Sound.play(Sfx.tap);
    setState(() => _slot = slot);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    Widget slot(GearSlot g) => _SlotBox(
          slot: g,
          character: c,
          selected: _slot == g,
          onTap: () => _select(g),
        );
    return Scaffold(
      appBar: OathBar(title: Text(tr('ARMERIA'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: [
              slot(GearSlot.offhand),
              Expanded(
                child: Column(
                  children: [
                    OneLine(
                      c.name.toUpperCase(),
                      align: Alignment.center,
                      style: titleStyle(size: 18, color: Palette.goldBright),
                    ),
                    Text(tr('Livello {level}', {'level': c.level}), style: const TextStyle(color: Palette.ash)),
                  ],
                ),
              ),
              slot(GearSlot.weapon),
            ],
          ),
          // Il cavaliere riempie lo spazio tra le colonne dei pezzi: i bordi
          // trasparenti della sua tela passano sotto le caselle.
          Stack(
            children: [
              Positioned.fill(
                child: OverflowBox(
                  minWidth: 0,
                  minHeight: 0,
                  maxWidth: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: KnightView(character: c, height: _SlotBox.height * 4.3),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      for (final g in [
                        GearSlot.helm,
                        GearSlot.chest,
                        GearSlot.gloves,
                        GearSlot.legs,
                        GearSlot.boots,
                      ])
                        slot(g),
                    ],
                  ),
                  const Spacer(),
                  Column(children: [slot(GearSlot.neck), slot(GearSlot.cape)]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Total(tr('Attacco'), '${s.attackValue}', Palette.goldBright)),
              Expanded(
                child: _Total(tr('Difesa'), '${(s.defenseValue * 100).round()}%', Palette.frost),
              ),
              Expanded(child: _Total(tr('Vita'), '${c.maxHp}', Palette.blood)),
            ],
          ),
          SectionTitle(tr('Effetti')),
          for (final e in _effects(c)) _EffectLine(e),
          SectionTitle(_slot.label),
          _Choices(slot: _slot),
        ],
      ),
    );
  }

  /// Quello che fanno arma, amuleti, scudo, armatura e mantello addosso.
  List<String> _effects(Character c) {
    final w = c.weapon;
    final aura = w.aura;
    final build = c.armorAttributeBonus;
    return [
      tr('{weapon}: potere {power}', {'weapon': w.displayName, 'power': w.attackRating(c).round()}),
      if (aura != null)
        tr('Affinità {aura}: cresce con {attr}', {'aura': aura.label, 'attr': aura.attributeLabel}),
      for (final a in w.amulets.where((a) => !a.isAffinity)) '${a.name}: ${a.description}',
      if (c.offhand != null) '${c.offhand!.name}: ${c.offhand!.effect}',
      if (build > 0) tr('Armatura di build: +{pct}% di danno', {'pct': (build * 100).round()}),
      if (c.cape != null && c.cape!.reduction > 0) '${c.cape!.name}: ${c.cape!.effect}',
      if (amuletDefs[c.neck] != null)
        '${amuletDefs[c.neck]!.name}: ${amuletDefs[c.neck]!.description}',
    ];
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value, this.color);
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

class _EffectLine extends StatelessWidget {
  const _EffectLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.diamond, size: 10, color: Palette.gold),
            const SizedBox(width: 8),
            Expanded(child: OneLine(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
}

/// Icona di un pezzo d'equipaggiamento, colorata dal materiale.
Widget gearIcon(GearSlot slot, Character c, {double size = 40, String? id}) {
  Widget icon(IconData data, Color color) => Icon(data, size: size, color: color);
  Color steel(int look) => switch (look) {
        2 => const Color(0xFFC9CED6),
        1 => const Color(0xFF9DA3AB),
        _ => const Color(0xFFB08850),
      };
  switch (slot) {
    case GearSlot.weapon:
      return SizedBox(
        width: size,
        height: size,
        child: FittedBox(child: WeaponPreview(weapon: c.weapon, size: 120)),
      );
    case GearSlot.offhand:
      final o = offhandDefs[id ?? c.offhandId];
      if (o == null) return icon(Icons.shield_outlined, Palette.ash.withValues(alpha: 0.25));
      return icon(o.isShield ? Icons.shield : Icons.colorize, Palette.holy);
    case GearSlot.neck:
      final a = id ?? c.neck;
      if (a == null) return icon(Icons.brightness_7, Palette.ash.withValues(alpha: 0.25));
      return ItemIcon('amulet_$a', size: size);
    case GearSlot.cape:
      final cape = capeDefs[id ?? c.capeId];
      return icon(
        Icons.dry_cleaning,
        cape == null ? Palette.ash.withValues(alpha: 0.25) : Color(cape.color).withValues(alpha: 1),
      );
    default:
      final armor = armorDefs[id ?? c.worn[slot.armor]];
      final data = switch (slot) {
        GearSlot.helm => Icons.sports_motorsports,
        GearSlot.chest => Icons.shield,
        GearSlot.gloves => Icons.back_hand,
        GearSlot.legs => Icons.accessibility_new,
        _ => Icons.hiking,
      };
      return icon(data, armor == null ? Palette.ash.withValues(alpha: 0.25) : steel(armor.look));
  }
}

class _SlotBox extends StatelessWidget {
  const _SlotBox({
    required this.slot,
    required this.character,
    required this.selected,
    required this.onTap,
  });

  static const double width = 64;

  /// Casella, etichetta e margini.
  static const double height = 80;

  final GearSlot slot;
  final Character character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Palette.stone,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? Palette.goldBright : Palette.gold.withValues(alpha: 0.45),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: Palette.gold.withValues(alpha: 0.35), blurRadius: 10)]
                      : null,
                ),
                child: gearIcon(slot, character, size: 36),
              ),
              const SizedBox(height: 2),
              OneLine(
                slot.label.toUpperCase(),
                align: Alignment.center,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  color: selected ? Palette.goldBright : Palette.ash,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un oggetto posseduto per il posto scelto.
class _Choice {
  const _Choice({
    required this.icon,
    required this.name,
    required this.detail,
    required this.worn,
    this.onTap,
    this.quality,
    this.wear,
  });
  final Widget icon;
  final String name;
  final String detail;
  final bool worn;
  final VoidCallback? onTap;

  /// Grado della forgia e usura, per armi e armature forgiate.
  final CraftQuality? quality;
  final int? wear;
}

class _Choices extends StatelessWidget {
  const _Choices({required this.slot});
  final GearSlot slot;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final choices = <_Choice>[];
    String? empty;
    Widget? extra;
    switch (slot) {
      case GearSlot.weapon:
        for (final w in [c.weapon, ...c.weapons]) {
          final wield = s.canWield(w.def);
          choices.add(_Choice(
            icon: SizedBox(
              width: 44,
              height: 44,
              child: FittedBox(child: WeaponPreview(weapon: w, size: 120)),
            ),
            name: w.displayName,
            detail: wield
                ? tr('Potere {power}', {'power': w.attackRating(c).round()})
                : tr('Serve {skill} {level}', {'skill': w.def.usesMagic ? tr('Magia') : tr('Attacco'), 'level': w.def.wieldLevel}),
            worn: identical(w, c.weapon),
            onTap: identical(w, c.weapon) || !wield ? null : () => s.equip(w),
            quality: w.crafted ? w.quality : null,
            wear: w.wear,
          ));
        }
        extra = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(tr('Amuleti dell\'arma')),
            WeaponSockets(weapon: c.weapon),
          ],
        );
      case GearSlot.offhand:
        if (!c.weapon.def.oneHanded && c.offhands.isNotEmpty) {
          extra = Text(
            tr('{weapon} si impugna a due mani: la mano sinistra resta libera.', {'weapon': c.weapon.def.name}),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          );
        }
        for (final id in c.offhands) {
          final o = offhandDefs[id]!;
          choices.add(_Choice(
            icon: gearIcon(slot, c, id: id),
            name: o.name,
            detail: o.effect,
            worn: c.offhandId == id,
            onTap: () => s.holdOffhand(c.offhandId == id ? null : id),
          ));
        }
        empty = tr('Niente per la mano sinistra: lo scudo di legno si fa in Carpenteria.');
      case GearSlot.neck:
        final ids = {
          ?c.neck,
          for (final a in amuletDefs.values)
            if (!a.isAffinity && !a.isBane && s.amuletCount(a.id) > 0) a.id,
        };
        for (final id in ids) {
          final a = amuletDefs[id]!;
          choices.add(_Choice(
            icon: ItemIcon('amulet_$id', size: 40),
            name: a.name,
            detail: a.description,
            worn: c.neck == id,
            onTap: () => s.wearNeck(c.neck == id ? null : id),
          ));
        }
        empty = tr('Nessun amuleto nella borsa: la Fattucchiera vende i passivi.');
        extra = OutlinedButton.icon(
          onPressed: () => openMarket(context, tab: 1),
          icon: const Icon(Icons.storefront),
          label: Text(tr('Vai dalla Fattucchiera')),
        );
      case GearSlot.cape:
        for (final id in c.capes) {
          final cape = capeDefs[id]!;
          choices.add(_Choice(
            icon: gearIcon(slot, c, id: id),
            name: cape.name,
            detail: cape.effect,
            worn: c.capeId == id,
            onTap: () => s.wearCape(c.capeId == id ? null : id),
          ));
        }
        extra = OutlinedButton.icon(
          onPressed: () => openMarket(context),
          icon: const Icon(Icons.storefront),
          label: Text(tr('Altri mantelli dal Mercante')),
        );
      default:
        final armor = slot.armor!;
        for (final id in c.armors) {
          final a = armorDefs[id]!;
          final wear = s.canWear(id);
          choices.add(_Choice(
            icon: gearIcon(slot, c, id: id),
            name: a.name,
            detail: wear
                ? tr('Assorbe il {pct}%', {'pct': (c.armorReduction(a) * armor.weight * 100).toStringAsFixed(1)})
                : tr('Serve Difesa {level}', {'level': a.wearLevel}),
            worn: c.worn[armor] == id,
            onTap: !wear ? null : () => s.wearPiece(armor, c.worn[armor] == id ? null : id),
            quality: c.qualityOf(id),
            wear: c.wearOf(id),
          ));
        }
        empty = tr('Nessuna armatura: la prima si forgia all\'Incudine.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choices.isEmpty && empty != null)
          Text(empty, textAlign: TextAlign.center, style: const TextStyle(color: Palette.ash)),
        if (choices.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [for (final ch in choices) _ChoiceTile(ch)],
          ),
        if (extra != null) ...[const SizedBox(height: 12), extra],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile(this.choice);
  final _Choice choice;

  @override
  Widget build(BuildContext context) {
    final ch = choice;
    final locked = ch.onTap == null && !ch.worn;
    return Opacity(
      opacity: locked ? 0.5 : 1,
      child: Material(
        color: Palette.stone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: ch.worn ? Palette.goldBright : Palette.gold.withValues(alpha: 0.35),
            width: ch.worn ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: ch.onTap == null
              ? null
              : () {
                  Sound.play(Sfx.confirm);
                  ch.onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ch.icon,
                    if (ch.worn)
                      const Positioned(
                        right: -14,
                        top: -6,
                        child: Icon(Icons.check_circle, size: 16, color: Palette.goldBright),
                      ),
                    if (locked)
                      const Positioned(
                        right: -14,
                        top: -6,
                        child: Icon(Icons.lock_outline, size: 16, color: Palette.ash),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                OneLine(
                  ch.name,
                  align: Alignment.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: ch.worn ? Palette.goldBright : Palette.holy,
                  ),
                ),
                OneLine(
                  ch.detail,
                  align: Alignment.center,
                  style: const TextStyle(fontSize: 11, color: Palette.ash),
                ),
                if (ch.quality != null || (ch.wear ?? 0) > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (ch.quality != null) QualityPips(ch.quality!, size: 6),
                      const SizedBox(width: 4),
                      WearBar(ch.wear ?? 0, width: 30),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
