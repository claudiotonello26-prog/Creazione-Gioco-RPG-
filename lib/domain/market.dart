/// Il Mercato: il Mercante compra e vende materiali e armi, la Fattucchiera
/// vende amuleti. Il Mercante compra a metà del prezzo a cui vende.
library;

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

/// Il Mercante vende solo materiali di base e pietre basse, al doppio.
const List<String> merchantStock = [
  'ash_wood',
  'iron_ore',
  'coal',
  'beast_essence',
  'oak_wood',
  'forge_stone_1',
];

int buyPrice(String id) => sellPrice(id) * 2;

bool sellable(String id) =>
    materialValues.containsKey(id) && !isTool(id) && !id.startsWith('amulet_');

/// Un'arma vale le rune dei materiali della ricetta, più i potenziamenti.
int weaponValue(WeaponInstance w) {
  var v = 0;
  w.def.recipe.forEach((k, n) => v += sellPrice(k) * n);
  return (v == 0 ? 40 : v) + w.upgrade * 25;
}

const Map<String, int> amuletPrices = {
  'fervent': 600,
  'colossus_seal': 600,
  'hunter_heart': 450,
  'martyr_relic': 800,
};
