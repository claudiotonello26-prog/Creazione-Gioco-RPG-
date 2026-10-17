/// Il Mercato: il Mercante compra e vende materiali e armi, la Fattucchiera
/// vende amuleti. Il Mercante compra a metà del prezzo a cui vende.
library;

import 'items.dart';
import 'skills.dart';

/// Valore in rune di un'unità (prezzo di vendita al Mercante).
const Map<String, int> materialValues = {
  'ash_wood': 4,
  'iron_ore': 5,
  'beast_essence': 8,
  'coal': 4,
  'oak_wood': 9,
  'yew_wood': 16,
  'ebony_wood': 28,
  'moon_silver': 20,
  'star_ore': 40,
  'ash_plank': 10,
  'oak_plank': 20,
  'yew_plank': 36,
  'ebony_plank': 60,
  'iron_ingot': 14,
  'steel_ingot': 30,
  'silver_ingot': 50,
  'star_ingot': 90,
  'reinforced_grip': 25,
  'forge_stone_1': 30,
  'forge_stone_2': 80,
  'forge_stone_3': 200,
  'holy_shard': 60,
  'ancient_stone': 250,
  'somber_stone': 250,
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
