/// Il Mercato: quattro botteghe (Emporio, Fabbro, Cacciatrice, Mago) e la
/// Fattucchiera con gli amuleti. L'Emporio compra tutto a metà del prezzo a
/// cui le botteghe vendono.
library;

import '../core/i18n.dart';
import 'items.dart';
import 'skills.dart';

/// Valore in rune di un'unità (prezzo di vendita al Mercante).
const Map<String, int> materialValues = {
  'ash_wood': 1,
  'iron_ore': 1,
  'beast_essence': 8,
  'coal': 1,
  'oak_wood': 1,
  'yew_wood': 2,
  'ebony_wood': 3,
  'moon_silver': 2,
  'star_ore': 4,
  'ash_plank': 25,
  'oak_plank': 30,
  'yew_plank': 50,
  'ebony_plank': 80,
  'iron_ingot': 35,
  'steel_ingot': 90,
  'silver_ingot': 70,
  'star_ingot': 140,
  'reinforced_grip': 25,
  'forge_stone_1': 30,
  'forge_stone_2': 80,
  'forge_stone_3': 200,
  'holy_shard': 60,
  'ancient_stone': 250,
  'somber_stone': 250,
  'somber_stone_2': 450,
  'somber_stone_3': 800,
  'somber_stone_4': 1300,
  'epic_stone': 2000,
  'raw_hide': 6,
  'tanned_leather': 14,
  'bronze_ingot': 12,
  'gold_ingot': 24,
  'bone': 5,
  'abyss_ink': 18,
  'ember_iron': 45,
  'gale_silver': 45,
  'hallowed_gold': 45,
  'abyss_crystal': 45,
  'godforge_steel': 110,
  'steel_feather': 110,
  'martyr_obsidian': 110,
  'star_iron': 110,
  'gem_rough': 20,
  'gem_cut': 50,
  'gem_pure': 120,
  'gem_perfect': 300,
  'ember_heart': 400,
  'storm_eye': 400,
  'martyr_tear': 400,
  'star_core': 400,
  'dream_pearl': 400,
};

int sellPrice(String id) => materialValues[id] ?? 0;

/// Chi gestisce una bottega del Mercato e quale mestiere ne apre gli
/// scaffali: si vede quello che serve al tuo livello più il prossimo.
enum ShopKeeper {
  /// L'Emporio compra tutto e vende le materie di base e i mantelli.
  general('general_store', 'Berta dell\'Emporio', 'Emporio', null),

  /// Il fabbro: minerali, lingotti, pietre di forgia.
  smith('smith', 'Mastro Gorran', 'Fabbro', Skill.smithing),

  /// La cacciatrice: pelli, ossa, essenze, assi e archi.
  hunter('hunter', 'Edda la Cacciatrice', 'Cacciatrice', Skill.carpentry),

  /// Il mago: inchiostri, gemme, schegge e bastoni.
  mage('mage', 'Velthar il Mago', 'Mago', Skill.magic);

  const ShopKeeper(this.art, this._name, this._role, this.skill);

  /// Nome del file del busto: `assets/art/npc/<art>.png`.
  final String art;
  final String _name;
  final String _role;

  /// Mestiere che apre gli scaffali (null = livello del personaggio).
  final Skill? skill;

  String get name => tr(_name);
  String get role => tr(_role);
}

/// Un articolo e il livello (del mestiere della bottega) che lo mette in
/// vendita. Un id di [weaponDefs] è un'arma, il resto materiali.
typedef ShopItem = (String id, int level);

const Map<ShopKeeper, List<ShopItem>> shopStock = {
  ShopKeeper.general: [
    ('ash_wood', 1),
    ('coal', 1),
    ('iron_ore', 1),
    ('raw_hide', 1),
    ('beast_essence', 2),
    ('oak_wood', 5),
    ('yew_wood', 12),
  ],
  ShopKeeper.smith: [
    ('iron_ore', 1),
    ('coal', 1),
    ('forge_stone_1', 1),
    ('bronze_ingot', 3),
    ('iron_ingot', 5),
    ('reinforced_grip', 5),
    ('gold_ingot', 8),
    ('steel_ingot', 10),
    ('silver_ingot', 12),
    ('forge_stone_2', 15),
    ('star_ingot', 22),
  ],
  ShopKeeper.hunter: [
    ('raw_hide', 1),
    ('bone', 1),
    ('beast_essence', 1),
    ('ash_plank', 2),
    ('tanned_leather', 3),
    ('ashwood_bow', 3),
    ('oak_plank', 6),
    ('yew_plank', 12),
    ('yew_longbow', 12),
  ],
  ShopKeeper.mage: [
    ('abyss_ink', 1),
    ('gem_rough', 1),
    ('holy_shard', 3),
    ('ember_staff', 4),
    ('moon_silver', 6),
    ('gem_cut', 10),
    ('somber_stone', 15),
    ('ebony_staff', 20),
  ],
};

/// Tutto quello che si può comprare da qualche bottega.
final List<String> merchantStock = {
  for (final l in shopStock.values)
    for (final (id, _) in l)
      if (!weaponDefs.containsKey(id)) id,
}.toList();

/// Le armi vendute dalle botteghe costano il triplo dei materiali.
int weaponBuyPrice(String id) {
  var v = 0;
  weaponDefs[id]!.recipe.forEach((k, n) => v += sellPrice(k) * n);
  return v * 3;
}

/// Le materie prime costano il doppio di quanto le paga l'Emporio, quelle
/// già lavorate (lingotti, assi, cuoio, pietre, gemme tagliate) il triplo:
/// farle da sé resta la via buona.
int buyPrice(String id) => sellPrice(id) * (rawMaterials.contains(id) ? 2 : 3);

const Set<String> rawMaterials = {
  'ash_wood', 'oak_wood', 'yew_wood', 'ebony_wood', 'coal', 'iron_ore', 'moon_silver',
  'star_ore', 'raw_hide', 'bone', 'beast_essence', 'abyss_ink', 'gem_rough',
};

bool sellable(String id) =>
    materialValues.containsKey(id) && !isTool(id) && !id.startsWith('amulet_');

/// Un'arma vale le rune dei materiali della ricetta, più i potenziamenti.
int weaponValue(WeaponInstance w) {
  var v = 0;
  w.def.recipe.forEach((k, n) => v += sellPrice(k) * n);
  return (v == 0 ? 40 : v) + w.upgrade * 25;
}

const Map<String, int> amuletPrices = {
  'regicide_seal': 700,
  'fang_charm': 650,
  'oath_sigil': 500,
  'sleepless_seal': 900,
  'fervent': 600,
  'colossus_seal': 600,
  'hunter_heart': 450,
  'martyr_relic': 800,
};
