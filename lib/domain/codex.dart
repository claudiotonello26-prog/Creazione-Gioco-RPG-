// Il Codice del Giuramento: per ogni oggetto del gioco, dove si trova e a
// cosa serve. Tutto si ricava dalle tabelle di oggetti, nemici e ricette,
// così il libro resta giusto quando cambiano i contenuti.

import '../core/i18n.dart';
import 'character.dart';
import 'combat.dart';
import 'enemies.dart';
import 'hunting.dart';
import 'items.dart';
import 'market.dart';
import 'skills.dart';

/// Le pagine del Codice, nell'ordine dei filtri.
enum CodexKind {
  material('Materiali'),
  stone('Pietre e reliquie'),
  tool('Attrezzi'),
  amulet('Amuleti'),
  weapon('Armi'),
  armor('Armature'),
  offhand('Mano sinistra'),
  cape('Mantelli');

  const CodexKind(this._label);
  final String _label;
  String get label => tr(_label);
}

/// Da dove arriva un oggetto.
enum SourceKind { enemy, chest, anyFight, walk, craft, shop }

class CodexSource {
  const CodexSource(this.kind, this.text, {this.chance, this.enemy});
  final SourceKind kind;
  final String text;

  /// Probabilità per vittoria o per forziere; null = sempre.
  final double? chance;

  /// Il nemico che lo lascia, per mostrarne il ritratto.
  final EnemyDef? enemy;
}

/// Come si usa un oggetto.
enum UseKind { recipe, upgrade, socket, sell }

/// A cosa serve: [itemId] è l'oggetto che se ne ricava, se ha una pagina.
class CodexUse {
  const CodexUse(this.text, {this.itemId, this.kind = UseKind.recipe});
  final String text;
  final String? itemId;
  final UseKind kind;
}

class CodexEntry {
  const CodexEntry(this.id, this.kind);
  final String id;
  final CodexKind kind;

  String get name => codexName(id);

  /// Una riga su cosa fa, per armi, armature e amuleti.
  String? get effect => switch (kind) {
    CodexKind.weapon => () {
      final w = weaponDefs[id]!;
      return tr('{style} · danno base {dmg} · si impugna da Attacco {lvl}', {
        'style': w.style.label,
        'dmg': w.baseDamage,
        'lvl': w.wieldLevel,
      });
    }(),
    CodexKind.armor => () {
      final a = armorDefs[id]!;
      return tr('Assorbe il {pct}% dei colpi (set completo) · si indossa da Difesa {lvl}', {
        'pct': (a.reduction * 100).round(),
        'lvl': a.wearLevel,
      });
    }(),
    CodexKind.offhand => offhandDefs[id]!.effect,
    CodexKind.cape => capeDefs[id]!.effect,
    CodexKind.amulet => amuletDefs[id.substring(7)]!.description,
    CodexKind.tool => tr('+{pct}% di raccolta camminando', {
      'pct': ((toolYield[id] ?? 0) * 100).round(),
    }),
    _ => null,
  };
}

/// Il nome di qualunque oggetto, armature e mantelli compresi.
String codexName(String id) =>
    armorDefs[id]?.name ?? capeDefs[id]?.name ?? offhandDefs[id]?.name ?? itemName(id);

CodexKind _kindOf(String id) {
  if (weaponDefs.containsKey(id)) return CodexKind.weapon;
  if (armorDefs.containsKey(id)) return CodexKind.armor;
  if (offhandDefs.containsKey(id)) return CodexKind.offhand;
  if (capeDefs.containsKey(id)) return CodexKind.cape;
  if (id.startsWith('amulet_')) return CodexKind.amulet;
  if (isTool(id)) return CodexKind.tool;
  if (id.contains('stone') || id == 'holy_shard') return CodexKind.stone;
  return CodexKind.material;
}

/// Tutte le pagine del Codice.
final List<CodexEntry> codexEntries = [
  for (final id in materialNamesIt.keys) CodexEntry(id, _kindOf(id)),
  for (final id in amuletDefs.keys) CodexEntry('amulet_$id', CodexKind.amulet),
  for (final id in weaponDefs.keys) CodexEntry(id, CodexKind.weapon),
  for (final id in armorDefs.keys) CodexEntry(id, CodexKind.armor),
  for (final id in offhandDefs.keys) CodexEntry(id, CodexKind.offhand),
  for (final id in capeDefs.keys) CodexEntry(id, CodexKind.cape),
];

CodexEntry? codexEntry(String id) {
  for (final e in codexEntries) {
    if (e.id == id) return e;
  }
  return null;
}

/// Ogni nemico una volta sola: animali, mostri e boss.
List<EnemyDef> get _allEnemies {
  final seen = <String>{};
  return [
    for (final e in [...baseAnimals, ...huntAnimals, ...enemyDefs.values])
      if (seen.add(e.id)) e,
  ];
}

/// La chiave con cui un drop finisce nella borsa: gli amuleti hanno il
/// prefisso, i componenti di build diventano quelli del Giuramento.
String _bagKey(String raw, Attribute build) =>
    amuletDefs.containsKey(raw) ? 'amulet_$raw' : forBuild(raw, build);

/// La build a cui appartiene un componente, se è di una build sola.
Attribute? buildOf(String id) {
  for (final e in buildMaterials.entries) {
    if (e.value.contains(id)) return e.key;
  }
  return null;
}

/// Dove si trova [id] per chi ha giurato su [build].
List<CodexSource> codexSources(String id, Attribute build) {
  final out = <CodexSource>[];
  bool same(String raw) => _bagKey(raw, build) == id;

  for (final e in _allEnemies) {
    if (e.loot.keys.any(same)) {
      out.add(
        CodexSource(
          SourceKind.enemy,
          tr('{enemy} · {region}', {'enemy': e.name, 'region': e.region}),
          enemy: e,
        ),
      );
    }
    final rare = e.rareDrop;
    if (rare != null && same(rare)) {
      out.add(
        CodexSource(
          SourceKind.enemy,
          tr('{enemy} · {region}', {'enemy': e.name, 'region': e.region}),
          chance: e.rareDropChance,
          enemy: e,
        ),
      );
    }
  }
  if (CombatEngine.uncommonDrops.contains(id)) {
    out.add(
      CodexSource(
        SourceKind.anyFight,
        tr('Qualunque nemico, come drop non comune'),
        chance: CombatEngine.uncommonBase / CombatEngine.uncommonDrops.length,
      ),
    );
  }
  if (CombatEngine.rareDrops.contains(id)) {
    out.add(
      CodexSource(
        SourceKind.anyFight,
        tr('Qualunque nemico, come drop raro'),
        chance: CombatEngine.rareBase / CombatEngine.rareDrops.length,
      ),
    );
  }
  for (final x in expeditions) {
    if (x.chest.guaranteed.keys.any(same)) {
      out.add(
        CodexSource(
          SourceKind.chest,
          tr('{chest} · {map}', {'chest': x.chest.name, 'map': x.name}),
        ),
      );
    }
    for (final (raw, p) in x.chest.rares) {
      if (same(raw)) {
        out.add(
          CodexSource(
            SourceKind.chest,
            tr('{chest} · {map}', {'chest': x.chest.name, 'map': x.name}),
            chance: p,
          ),
        );
      }
    }
  }
  for (final r in resources) {
    if (r.id == id) {
      out.add(
        CodexSource(
          SourceKind.walk,
          tr('Camminando: {where}, da {skill} {lvl}', {
            'where': r.where,
            'skill': r.skill.label,
            'lvl': r.level,
          }),
        ),
      );
    }
  }
  for (final r in materialRecipes) {
    if (r.output == id) {
      out.add(
        CodexSource(
          SourceKind.craft,
          tr('{station} livello {lvl}', {'station': r.station.label, 'lvl': r.level}),
        ),
      );
    }
  }
  final weapon = weaponDefs[id];
  if (weapon != null && weapon.recipe.isNotEmpty) {
    out.add(
      CodexSource(
        SourceKind.craft,
        tr('{station} livello {lvl}', {'station': weapon.station.label, 'lvl': weapon.craftLevel}),
      ),
    );
  }
  final armor = armorDefs[id];
  if (armor != null) {
    out.add(
      CodexSource(
        SourceKind.craft,
        tr('{station} livello {lvl}', {'station': Station.anvil.label, 'lvl': armor.craftLevel}),
      ),
    );
  }
  final off = offhandDefs[id];
  if (off != null) {
    out.add(
      CodexSource(
        SourceKind.craft,
        tr('{station} livello {lvl}', {'station': off.station.label, 'lvl': off.craftLevel}),
      ),
    );
  }
  if (id.startsWith('amulet_') && amuletRecipes.containsKey(id.substring(7))) {
    out.add(CodexSource(SourceKind.craft, Station.enchant.label));
  }
  if (merchantStock.contains(id)) {
    out.add(CodexSource(SourceKind.shop, tr('Mercante · {runes} rune', {'runes': buyPrice(id)})));
  }
  if (id.startsWith('amulet_') && amuletPrices.containsKey(id.substring(7))) {
    out.add(
      CodexSource(
        SourceKind.shop,
        tr('Fattucchiera · {runes} rune', {'runes': amuletPrices[id.substring(7)]}),
      ),
    );
  }
  final cape = capeDefs[id];
  if (cape != null) {
    out.add(
      cape.price > 0
          ? CodexSource(SourceKind.shop, tr('Mercante · {runes} rune', {'runes': cape.price}))
          : CodexSource(SourceKind.shop, tr('Ce l\'hai dall\'inizio')),
    );
  }
  if (id == 'pilgrim_blade') {
    out.add(CodexSource(SourceKind.shop, tr('Ce l\'hai dall\'inizio')));
  }
  // Prima le vie sicure (passi, forgia, negozi), poi i nemici dal più
  // facile, così si vede subito chi si può già battere; i forzieri in fondo.
  const order = [
    SourceKind.walk,
    SourceKind.craft,
    SourceKind.shop,
    SourceKind.enemy,
    SourceKind.anyFight,
    SourceKind.chest,
  ];
  // Dart non ordina in modo stabile: a parità vale l'ordine di partenza.
  final pos = {for (final (i, s) in out.indexed) s: i};
  int key(CodexSource s) => (order.indexOf(s.kind) * 1000 + (s.enemy?.level ?? 0)) * 1000 + pos[s]!;
  out.sort((a, b) => key(a).compareTo(key(b)));
  return out;
}

/// A cosa serve [id]: ricette che lo usano, potenziamenti, vendita.
List<CodexUse> codexUses(String id) {
  final out = <CodexUse>[];
  String qty(Map<String, int> recipe) => '×${recipe[id]}';
  for (final r in materialRecipes) {
    if (r.inputs.containsKey(id)) {
      out.add(
        CodexUse(
          tr('{qty} per {item} ({station})', {
            'qty': qty(r.inputs),
            'item': codexName(r.output),
            'station': r.station.label,
          }),
          itemId: r.output,
        ),
      );
    }
  }
  for (final w in weaponDefs.values) {
    if (w.recipe.containsKey(id)) {
      out.add(
        CodexUse(
          tr('{qty} per {item} ({station})', {
            'qty': qty(w.recipe),
            'item': w.name,
            'station': w.station.label,
          }),
          itemId: w.id,
        ),
      );
    }
  }
  for (final a in armorDefs.values) {
    if (a.recipe.containsKey(id)) {
      out.add(
        CodexUse(
          tr('{qty} per {item} ({station})', {
            'qty': qty(a.recipe),
            'item': a.name,
            'station': Station.anvil.label,
          }),
          itemId: a.id,
        ),
      );
    }
  }
  for (final o in offhandDefs.values) {
    if (o.recipe.containsKey(id)) {
      out.add(
        CodexUse(
          tr('{qty} per {item} ({station})', {
            'qty': qty(o.recipe),
            'item': o.name,
            'station': o.station.label,
          }),
          itemId: o.id,
        ),
      );
    }
  }
  for (final e in amuletRecipes.entries) {
    if (e.value.containsKey(id)) {
      out.add(
        CodexUse(
          tr('{qty} per {item} ({station})', {
            'qty': qty(e.value),
            'item': codexName('amulet_${e.key}'),
            'station': Station.enchant.label,
          }),
          itemId: 'amulet_${e.key}',
        ),
      );
    }
  }
  // Pietre: per quali livelli di potenziamento servono.
  final normal = <int>[], rare = <int>[];
  for (var lvl = 1; lvl <= 10; lvl++) {
    if (stoneFor(_normalWeapon, lvl) == id) normal.add(lvl);
    if (stoneFor(_rareWeapon, lvl) == id) rare.add(lvl);
  }
  String range(List<int> l) => l.length == 1 ? '+${l.first}' : '+${l.first} – +${l.last}';
  if (normal.isNotEmpty) {
    out.add(
      CodexUse(
        tr('Potenzia le armi comuni a {lvl}', {'lvl': range(normal)}),
        kind: UseKind.upgrade,
      ),
    );
  }
  if (rare.isNotEmpty) {
    out.add(
      CodexUse(
        tr('Potenzia le armi speciali a {lvl}', {'lvl': range(rare)}),
        kind: UseKind.upgrade,
      ),
    );
  }
  if (id.startsWith('amulet_')) {
    out.add(
      CodexUse(
        amuletDefs[id.substring(7)]!.isAffinity
            ? tr('Si incastona nella prima sede dell\'arma: ne decide l\'aura')
            : tr('Si incastona in una delle due sedi passive dell\'arma, o si porta al collo'),
        kind: UseKind.socket,
      ),
    );
  }
  if (sellable(id) && sellPrice(id) > 0) {
    out.add(
      CodexUse(
        tr('Il Mercante lo compra a {runes} rune', {'runes': sellPrice(id)}),
        kind: UseKind.sell,
      ),
    );
  }
  return out;
}

final WeaponDef _normalWeapon = weaponDefs.values.firstWhere((w) => !w.rare);
final WeaponDef _rareWeapon = weaponDefs.values.firstWhere((w) => w.rare);
