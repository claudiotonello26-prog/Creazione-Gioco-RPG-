// I nomi restano in italiano nel campo privato e si traducono nel getter.
// ignore_for_file: prefer_initializing_formals

import 'dart:math';
import 'dart:ui' show Color;

import '../core/i18n.dart';
import 'character.dart';

/// Gradi di scaling stile souls.
enum ScalingGrade {
  s(1.2),
  a(1.0),
  b(0.8),
  c(0.6),
  d(0.4),
  e(0.2);

  const ScalingGrade(this.coefficient);
  final double coefficient;

  String get label => name.toUpperCase();
}

enum WeaponStyle {
  melee('Corpo a corpo'),
  ranged('Distanza'),
  magic('Magia');

  const WeaponStyle(this._label);
  final String _label;
  String get label => tr(_label);
}

enum DamageType { physical, holy, magic }

class WeaponDef {
  const WeaponDef({
    required this.id,
    required String name,
    required this.style,
    required this.baseDamage,
    required this.scaling,
    required this.damageType,
    this.rare = false,
    this.heavy = false,
    this.recipe = const {},
    this.craftLevel = 1,
  }) : _name = name;

  final String id;
  final String _name;

  /// Nome tradotto nella lingua corrente; [nameIt] è quello italiano.
  String get name => tr(_name);
  String get nameIt => _name;
  final WeaponStyle style;
  final int baseDamage;
  final Map<Attribute, ScalingGrade> scaling;
  final DamageType damageType;
  final bool rare;
  final bool heavy;

  /// Materiali necessari alla forgia; vuoto = non forgiabile.
  final Map<String, int> recipe;

  /// Livello della postazione (Carpenteria o Incudine) richiesto.
  final int craftLevel;

  int get maxUpgrade => rare ? 5 : 10;

  /// Archi e bastoni nascono in Carpenteria, il resto all'Incudine.
  Station get station => style == WeaponStyle.melee ? Station.anvil : Station.carpentry;

  /// Livello di Attacco (o di Magia per i bastoni) per impugnarla.
  int get wieldLevel => rare ? 25 : wieldLevelFor(craftLevel);

  /// I bastoni crescono con la Magia, il resto con l'Attacco.
  bool get usesMagic => style == WeaponStyle.magic;

  /// Le armi a una mano lasciano libera la sinistra per scudo o seconda lama.
  bool get oneHanded => style == WeaponStyle.melee && !heavy;

  /// Elemento dell'aura: segue l'attributo che scala di più.
  Affinity get affinity {
    Attribute? best;
    var bestCoef = 0.0;
    for (final e in scaling.entries) {
      if (!Affinity.attributes.containsKey(e.key)) continue;
      if (e.value.coefficient > bestCoef) {
        best = e.key;
        bestCoef = e.value.coefficient;
      }
    }
    return Affinity.attributes[best] ?? Affinity.fire;
  }
}

/// Le quattro postazioni della Forgia.
enum Station {
  carpentry('Carpenteria', 'Lavora il legno: assi, impugnature, archi e bastoni'),
  furnace('Fornace', 'Fondi i metalli: lingotti e pietre di forgia'),
  anvil('Incudine', 'Batti spade, martelli e armature'),
  enchant('Incantamento', 'Le pietre speciali potenziano l\'arma e ne risvegliano l\'aura');

  const Station(this._label, this._description);
  final String _label;
  final String _description;
  String get label => tr(_label);
  String get description => tr(_description);

  /// Colore della postazione: legno arancio, fuoco rosso, acciaio blu,
  /// incanto viola.
  Color get accent => switch (this) {
        carpentry => const Color(0xFFD9893A),
        furnace => const Color(0xFFD2452F),
        anvil => const Color(0xFF6E9BC9),
        enchant => const Color(0xFFA77BE0),
      };
}

/// Colore dell'arma potenziata: a +3 si tinge, a +6 si accende, a +10
/// ha l'aura completa.
enum Affinity {
  fire('Fuoco', 'Forza', Color(0xFFE0452B), Color(0xFFFF9A3D)),
  wind('Vento', 'Destrezza', Color(0xFF4FBF6A), Color(0xFFB8F5C4)),
  arcane('Arcano', 'Intelligenza', Color(0xFF3D7BFF), Color(0xFF7FF4FF)),
  holy('Luce divina', 'Fede', Color(0xFFE9C34A), Color(0xFFFFF4C2));

  const Affinity(this._label, this._attributeLabel, this.color, this.glow);
  final String _label;
  final String _attributeLabel;
  String get label => tr(_label);
  String get attributeLabel => tr(_attributeLabel);
  final Color color;
  final Color glow;

  static const Map<Attribute, Affinity> attributes = {
    Attribute.strength: fire,
    Attribute.dexterity: wind,
    Attribute.intelligence: arcane,
    Attribute.faith: holy,
  };
}

/// Lavorazione di un materiale in un altro (Fornace e Carpenteria), sbloccata
/// dal livello della postazione.
class MaterialRecipe {
  const MaterialRecipe(
    this.output,
    this.station,
    this.inputs, {
    this.level = 1,
    this.qty = 1,
    this.tool = false,
  });

  /// Attrezzo: se ne costruisce uno solo.
  final bool tool;
  final String output;
  final Station station;
  final Map<String, int> inputs;
  final int level;
  final int qty;
}

const List<MaterialRecipe> materialRecipes = [
  MaterialRecipe('ash_plank', Station.carpentry, {'ash_wood': 20}),
  MaterialRecipe('ash_pickaxe', Station.carpentry, {'ash_plank': 1, 'ash_wood': 20}, tool: true),
  MaterialRecipe(
    'iron_axe',
    Station.anvil,
    {'iron_ingot': 2, 'ash_plank': 1},
    level: 4,
    tool: true,
  ),
  MaterialRecipe(
    'iron_pickaxe',
    Station.anvil,
    {'iron_ingot': 3, 'oak_plank': 1},
    level: 6,
    tool: true,
  ),
  MaterialRecipe(
    'steel_axe',
    Station.anvil,
    {'steel_ingot': 2, 'oak_plank': 1},
    level: 10,
    tool: true,
  ),
  MaterialRecipe(
    'steel_pickaxe',
    Station.anvil,
    {'steel_ingot': 3, 'yew_plank': 1},
    level: 12,
    tool: true,
  ),
  MaterialRecipe(
      'reinforced_grip',
      Station.carpentry,
      {
        'ash_plank': 1,
        'beast_essence': 1,
      },
      level: 2),
  MaterialRecipe('oak_plank', Station.carpentry, {'oak_wood': 20}, level: 5),
  MaterialRecipe('yew_plank', Station.carpentry, {'yew_wood': 20}, level: 12),
  MaterialRecipe('ebony_plank', Station.carpentry, {'ebony_wood': 20}, level: 20),
  MaterialRecipe('iron_ingot', Station.furnace, {'iron_ore': 20, 'coal': 10}),
  MaterialRecipe('forge_stone_1', Station.furnace, forgeStone1Recipe),
  MaterialRecipe('steel_ingot', Station.furnace, {'iron_ingot': 2, 'coal': 20}, level: 6),
  MaterialRecipe('forge_stone_2', Station.furnace, {'forge_stone_1': 2, 'holy_shard': 1}, level: 8),
  MaterialRecipe('silver_ingot', Station.furnace, {'moon_silver': 20, 'coal': 10}, level: 10),
  MaterialRecipe(
      'forge_stone_3',
      Station.furnace,
      {
        'forge_stone_2': 2,
        'beast_essence': 3,
      },
      level: 14),
  MaterialRecipe('star_ingot', Station.furnace, {'star_ore': 20, 'coal': 20}, level: 18),
  // Il binario delle armi speciali: Tenebre I cade dai nemici, le altre si
  // fondono dalla precedente; l'Epica chiude a +5.
  MaterialRecipe('somber_stone_2', Station.furnace, {'somber_stone': 2, 'holy_shard': 1},
      level: 10),
  MaterialRecipe('somber_stone_3', Station.furnace, {'somber_stone_2': 2, 'beast_essence': 3},
      level: 14),
  MaterialRecipe('somber_stone_4', Station.furnace, {'somber_stone_3': 2, 'gem_cut': 1}, level: 18),
  MaterialRecipe('epic_stone', Station.furnace, {'somber_stone_4': 2, 'gem_perfect': 1}, level: 22),
];

/// Requisito per usare ciò che si forgia a un certo livello di postazione:
/// gli oggetti base subito, poi a 5, 10 e 20.
int wieldLevelFor(int craftLevel) => craftLevel < 5
    ? 1
    : craftLevel < 10
        ? 5
        : craftLevel < 20
            ? 10
            : 20;

/// Pezzi d'armatura: ogni armatura forgiata si indossa pezzo per pezzo, e
/// ogni pezzo pesa per una quota della sua protezione.
/// Pezzi dell'armatura, nell'ordine dell'Armeria. Il peso è la quota della
/// protezione del pezzo: in tutto fanno 1.
enum ArmorSlot {
  helm('Elmo', 0.20),
  chest('Corazza', 0.40),
  gloves('Bracciali', 0.10),
  legs('Gambali', 0.20),
  boots('Stivali', 0.10);

  const ArmorSlot(this._label, this.weight);
  final String _label;
  String get label => tr(_label);
  final double weight;
}

/// Armature: riducono il danno dei colpi nemici.
class ArmorDef {
  const ArmorDef({
    required this.id,
    required String name,
    required this.reduction,
    required this.recipe,
    required this.look,
    this.craftLevel = 1,
    this.attribute,
  }) : _name = name;
  final String id;
  final String _name;
  String get name => tr(_name);
  String get nameIt => _name;

  /// Materiale di build: +5% di danno ogni 10 punti di questo attributo, in
  /// proporzione al pezzo indossato.
  final Attribute? attribute;

  /// Livello dell'Incudine richiesto.
  final int craftLevel;

  /// Quota di danno assorbita (0..1).
  final double reduction;
  final Map<String, int> recipe;

  /// 0 stoffa, 1 maglia, 2 piastre: decide come appare il cavaliere.
  final int look;

  /// Livello di Difesa per indossarla.
  int get wearLevel => wieldLevelFor(craftLevel);
}

const Map<String, ArmorDef> armorDefs = {
  'gambeson': ArmorDef(
    id: 'gambeson',
    name: 'Giaco Imbottito',
    reduction: 0.08,
    recipe: {'beast_essence': 3, 'ash_plank': 1},
    look: 0,
  ),
  'chainmail': ArmorDef(
    id: 'chainmail',
    name: 'Cotta di Maglia',
    reduction: 0.15,
    recipe: {'iron_ingot': 4, 'beast_essence': 2},
    look: 1,
    craftLevel: 4,
  ),
  'templar_plate': ArmorDef(
    id: 'templar_plate',
    name: 'Piastre del Templare',
    reduction: 0.22,
    recipe: {'steel_ingot': 6, 'holy_shard': 2, 'forge_stone_2': 1},
    look: 2,
    craftLevel: 10,
  ),
  'leather_armor': ArmorDef(
    id: 'leather_armor',
    name: 'Armatura di Cuoio',
    reduction: 0.12,
    recipe: {'tanned_leather': 4, 'raw_hide': 2},
    look: 0,
    craftLevel: 3,
  ),
  'bronze_mail': ArmorDef(
    id: 'bronze_mail',
    name: 'Usbergo di Bronzo',
    reduction: 0.17,
    recipe: {'bronze_ingot': 6, 'raw_hide': 2},
    look: 1,
    craftLevel: 6,
  ),
  'ember_plate': ArmorDef(
    id: 'ember_plate',
    name: 'Piastre di Brace',
    reduction: 0.26,
    recipe: {'ember_iron': 6, 'steel_ingot': 2},
    look: 2,
    craftLevel: 15,
    attribute: Attribute.strength,
  ),
  'gale_leathers': ArmorDef(
    id: 'gale_leathers',
    name: 'Cuoio di Bufera',
    reduction: 0.24,
    recipe: {'gale_silver': 5, 'tanned_leather': 3},
    look: 0,
    craftLevel: 15,
    attribute: Attribute.dexterity,
  ),
  'hallowed_plate': ArmorDef(
    id: 'hallowed_plate',
    name: 'Piastre Consacrate',
    reduction: 0.26,
    recipe: {'hallowed_gold': 6, 'bronze_ingot': 2},
    look: 2,
    craftLevel: 15,
    attribute: Attribute.faith,
  ),
  'abyss_robes': ArmorDef(
    id: 'abyss_robes',
    name: 'Veste d\'Abisso',
    reduction: 0.22,
    recipe: {'abyss_crystal': 5, 'abyss_ink': 3},
    look: 0,
    craftLevel: 15,
    attribute: Attribute.intelligence,
  ),
  'godforge_plate': ArmorDef(
    id: 'godforge_plate',
    name: 'Armatura della Fucina Divina',
    reduction: 0.33,
    recipe: {'godforge_steel': 7, 'ember_iron': 2},
    look: 2,
    craftLevel: 23,
    attribute: Attribute.strength,
  ),
  'storm_leathers': ArmorDef(
    id: 'storm_leathers',
    name: 'Manto della Tempesta',
    reduction: 0.3,
    recipe: {'steel_feather': 6, 'gale_silver': 2},
    look: 0,
    craftLevel: 23,
    attribute: Attribute.dexterity,
  ),
  'martyr_plate': ArmorDef(
    id: 'martyr_plate',
    name: 'Armatura del Martire',
    reduction: 0.33,
    recipe: {'martyr_obsidian': 7, 'hallowed_gold': 2},
    look: 2,
    craftLevel: 23,
    attribute: Attribute.faith,
  ),
  'star_robes': ArmorDef(
    id: 'star_robes',
    name: 'Veste Stellare',
    reduction: 0.28,
    recipe: {'star_iron': 6, 'abyss_crystal': 2},
    look: 0,
    craftLevel: 23,
    attribute: Attribute.intelligence,
  ),
  'star_plate': ArmorDef(
    id: 'star_plate',
    name: 'Armatura Stellare',
    reduction: 0.3,
    recipe: {'star_ingot': 6, 'silver_ingot': 2},
    look: 2,
    craftLevel: 20,
  ),
};

/// Mantelli: si comprano dal Mercante, proteggono un poco e colorano il
/// cavaliere.
class CapeDef {
  const CapeDef({
    required this.id,
    required String name,
    required this.color,
    this.reduction = 0,
    this.price = 0,
  }) : _name = name;
  final String id;
  final String _name;
  String get name => tr(_name);
  String get nameIt => _name;
  final int color;

  /// Quota di danno in più assorbita.
  final double reduction;
  final int price;

  String get effect =>
      reduction > 0
          ? tr('Assorbe un altro {pct}% dei colpi', {'pct': (reduction * 100).round()})
          : tr('Solo stile');
}

const Map<String, CapeDef> capeDefs = {
  'pilgrim_cape': CapeDef(id: 'pilgrim_cape', name: 'Mantello del Pellegrino', color: 0xFF4A1612),
  'scarlet_cape': CapeDef(
    id: 'scarlet_cape',
    name: 'Mantello Scarlatto',
    color: 0xFF8E1F1A,
    reduction: 0.02,
    price: 400,
  ),
  'wolf_cape': CapeDef(
    id: 'wolf_cape',
    name: 'Mantello del Lupo Grigio',
    color: 0xFF5A5F66,
    reduction: 0.03,
    price: 900,
  ),
  'oath_cape': CapeDef(
    id: 'oath_cape',
    name: 'Mantello del Giuramento',
    color: 0xFF1F2E5A,
    reduction: 0.05,
    price: 2000,
  ),
};

/// Mano sinistra: scudo o seconda lama, solo con un'arma a una mano.
class OffhandDef {
  const OffhandDef({
    required this.id,
    required String name,
    required this.recipe,
    required this.station,
    this.reduction = 0,
    this.damageBonus = 0,
    this.craftLevel = 1,
  }) : _name = name;
  final String id;
  final String _name;
  String get name => tr(_name);
  String get nameIt => _name;
  final Map<String, int> recipe;
  final Station station;
  final int craftLevel;

  /// Scudo: quota di danno in più assorbita.
  final double reduction;

  /// Seconda lama: danno in più.
  final double damageBonus;

  bool get isShield => reduction > 0;

  String get effect => isShield
      ? tr('Assorbe un altro {pct}% dei colpi', {'pct': (reduction * 100).round()})
      : tr('+{pct}% di danno con due lame', {'pct': (damageBonus * 100).round()});
}

const Map<String, OffhandDef> offhandDefs = {
  'wooden_shield': OffhandDef(
    id: 'wooden_shield',
    name: 'Scudo di Quercia',
    recipe: {'oak_plank': 3, 'iron_ingot': 1},
    station: Station.carpentry,
    reduction: 0.06,
    craftLevel: 5,
  ),
  'twin_blade': OffhandDef(
    id: 'twin_blade',
    name: 'Lama Gemella',
    recipe: {'steel_ingot': 2, 'reinforced_grip': 1},
    station: Station.anvil,
    damageBonus: 0.12,
    craftLevel: 7,
  ),
  'kite_shield': OffhandDef(
    id: 'kite_shield',
    name: 'Scudo a Mandorla',
    recipe: {'steel_ingot': 4, 'oak_plank': 2, 'holy_shard': 1},
    station: Station.anvil,
    reduction: 0.12,
    craftLevel: 11,
  ),
};

const Map<String, WeaponDef> weaponDefs = {
  'pilgrim_blade': WeaponDef(
    id: 'pilgrim_blade',
    name: 'Lama del Pellegrino',
    style: WeaponStyle.melee,
    baseDamage: 20,
    scaling: {Attribute.strength: ScalingGrade.d, Attribute.dexterity: ScalingGrade.b},
    damageType: DamageType.physical,
  ),
  'penitent_greatsword': WeaponDef(
    id: 'penitent_greatsword',
    name: 'Spadone del Penitente',
    style: WeaponStyle.melee,
    baseDamage: 30,
    heavy: true,
    scaling: {
      Attribute.strength: ScalingGrade.b,
      Attribute.faith: ScalingGrade.c,
      Attribute.dexterity: ScalingGrade.e,
    },
    damageType: DamageType.holy,
    recipe: {'iron_ingot': 4, 'reinforced_grip': 1, 'beast_essence': 2},
    craftLevel: 3,
  ),
  'cathedral_hammer': WeaponDef(
    id: 'cathedral_hammer',
    name: 'Martello della Cattedrale',
    style: WeaponStyle.melee,
    baseDamage: 28,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.c, Attribute.faith: ScalingGrade.b},
    damageType: DamageType.holy,
    recipe: {'iron_ingot': 3, 'ash_plank': 2, 'holy_shard': 3},
    craftLevel: 5,
  ),
  'ashwood_bow': WeaponDef(
    id: 'ashwood_bow',
    name: 'Arco di Frassino Cenere',
    style: WeaponStyle.ranged,
    baseDamage: 18,
    scaling: {Attribute.dexterity: ScalingGrade.a},
    damageType: DamageType.physical,
    recipe: {'ash_plank': 5, 'beast_essence': 2},
    craftLevel: 3,
  ),
  'ember_staff': WeaponDef(
    id: 'ember_staff',
    name: 'Bastone della Brace',
    style: WeaponStyle.magic,
    baseDamage: 16,
    scaling: {Attribute.intelligence: ScalingGrade.a},
    damageType: DamageType.magic,
    recipe: {'ash_plank': 3, 'beast_essence': 6},
    craftLevel: 4,
  ),
  'steel_longsword': WeaponDef(
    id: 'steel_longsword',
    name: 'Spada Lunga d\'Acciaio',
    style: WeaponStyle.melee,
    baseDamage: 28,
    scaling: {Attribute.strength: ScalingGrade.c, Attribute.dexterity: ScalingGrade.b},
    damageType: DamageType.physical,
    recipe: {'steel_ingot': 4, 'reinforced_grip': 1},
    craftLevel: 7,
  ),
  'moon_blade': WeaponDef(
    id: 'moon_blade',
    name: 'Lama d\'Argento Lunare',
    style: WeaponStyle.melee,
    baseDamage: 30,
    scaling: {Attribute.faith: ScalingGrade.a, Attribute.dexterity: ScalingGrade.c},
    damageType: DamageType.holy,
    recipe: {'silver_ingot': 4, 'reinforced_grip': 1, 'holy_shard': 2},
    craftLevel: 12,
  ),
  'star_greatsword': WeaponDef(
    id: 'star_greatsword',
    name: 'Spadone Stellare',
    style: WeaponStyle.melee,
    baseDamage: 40,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.s},
    damageType: DamageType.physical,
    recipe: {'star_ingot': 5, 'ebony_plank': 1, 'beast_essence': 6},
    craftLevel: 20,
  ),
  'yew_longbow': WeaponDef(
    id: 'yew_longbow',
    name: 'Arco Lungo di Tasso',
    style: WeaponStyle.ranged,
    baseDamage: 26,
    scaling: {Attribute.dexterity: ScalingGrade.a},
    damageType: DamageType.physical,
    recipe: {'yew_plank': 6, 'silver_ingot': 1, 'beast_essence': 4},
    craftLevel: 12,
  ),
  'ebony_staff': WeaponDef(
    id: 'ebony_staff',
    name: 'Bastone d\'Ebano del Crepuscolo',
    style: WeaponStyle.magic,
    baseDamage: 30,
    scaling: {Attribute.intelligence: ScalingGrade.s},
    damageType: DamageType.magic,
    recipe: {'ebony_plank': 6, 'star_ingot': 1, 'holy_shard': 2},
    craftLevel: 20,
  ),
  'ember_cleaver': WeaponDef(
    id: 'ember_cleaver',
    name: 'Mannaia di Brace',
    style: WeaponStyle.melee,
    baseDamage: 36,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.a},
    damageType: DamageType.physical,
    recipe: {'ember_iron': 5, 'steel_ingot': 2},
    craftLevel: 14,
  ),
  'godforge_greatsword': WeaponDef(
    id: 'godforge_greatsword',
    name: 'Spadone della Fucina Divina',
    style: WeaponStyle.melee,
    baseDamage: 46,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.s},
    damageType: DamageType.physical,
    recipe: {'godforge_steel': 6, 'ember_iron': 2},
    craftLevel: 22,
  ),
  'gale_bow': WeaponDef(
    id: 'gale_bow',
    name: 'Arco di Bufera',
    style: WeaponStyle.ranged,
    baseDamage: 32,
    scaling: {Attribute.dexterity: ScalingGrade.a},
    damageType: DamageType.physical,
    recipe: {'gale_silver': 5, 'oak_plank': 2},
    craftLevel: 14,
  ),
  'feather_saber': WeaponDef(
    id: 'feather_saber',
    name: 'Sciabola di Piuma d\'Acciaio',
    style: WeaponStyle.melee,
    baseDamage: 40,
    scaling: {Attribute.dexterity: ScalingGrade.s},
    damageType: DamageType.physical,
    recipe: {'steel_feather': 6, 'gale_silver': 2},
    craftLevel: 22,
  ),
  'hallowed_mace': WeaponDef(
    id: 'hallowed_mace',
    name: 'Mazza Consacrata',
    style: WeaponStyle.melee,
    baseDamage: 34,
    scaling: {Attribute.faith: ScalingGrade.a, Attribute.strength: ScalingGrade.d},
    damageType: DamageType.holy,
    recipe: {'hallowed_gold': 5, 'bronze_ingot': 3},
    craftLevel: 14,
  ),
  'martyr_halberd': WeaponDef(
    id: 'martyr_halberd',
    name: 'Alabarda del Martire',
    style: WeaponStyle.melee,
    baseDamage: 46,
    heavy: true,
    scaling: {Attribute.faith: ScalingGrade.s},
    damageType: DamageType.holy,
    recipe: {'martyr_obsidian': 6, 'hallowed_gold': 2},
    craftLevel: 22,
  ),
  'abyss_staff': WeaponDef(
    id: 'abyss_staff',
    name: 'Bastone d\'Abisso',
    style: WeaponStyle.magic,
    baseDamage: 32,
    scaling: {Attribute.intelligence: ScalingGrade.a},
    damageType: DamageType.magic,
    recipe: {'abyss_crystal': 5, 'oak_plank': 2},
    craftLevel: 14,
  ),
  'star_catalyst': WeaponDef(
    id: 'star_catalyst',
    name: 'Catalizzatore di Ferro Stellare',
    style: WeaponStyle.magic,
    baseDamage: 42,
    scaling: {Attribute.intelligence: ScalingGrade.s},
    damageType: DamageType.magic,
    recipe: {'star_iron': 6, 'abyss_crystal': 2},
    craftLevel: 22,
  ),
  'lord_of_the_keep_blade': WeaponDef(
    id: 'lord_of_the_keep_blade',
    name: 'Lama del Signore della Rocca',
    style: WeaponStyle.melee,
    baseDamage: 38,
    rare: true,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.a, Attribute.faith: ScalingGrade.d},
    damageType: DamageType.physical,
  ),
  // Le armi rare dei forzieri d'oro: una per build.
  'smith_god_hammer': WeaponDef(
    id: 'smith_god_hammer',
    name: 'Martello del Dio Fabbro',
    style: WeaponStyle.melee,
    baseDamage: 44,
    rare: true,
    heavy: true,
    scaling: {Attribute.strength: ScalingGrade.s},
    damageType: DamageType.physical,
  ),
  'storm_king_spear': WeaponDef(
    id: 'storm_king_spear',
    name: 'Lancia del Re della Tempesta',
    style: WeaponStyle.melee,
    baseDamage: 40,
    rare: true,
    scaling: {Attribute.dexterity: ScalingGrade.s},
    damageType: DamageType.physical,
  ),
  'eternal_martyr_blade': WeaponDef(
    id: 'eternal_martyr_blade',
    name: 'Lama del Martire Eterno',
    style: WeaponStyle.melee,
    baseDamage: 44,
    rare: true,
    heavy: true,
    scaling: {Attribute.faith: ScalingGrade.s},
    damageType: DamageType.holy,
  ),
  'devourer_eye': WeaponDef(
    id: 'devourer_eye',
    name: 'Occhio del Divoratore',
    style: WeaponStyle.magic,
    baseDamage: 42,
    rare: true,
    scaling: {Attribute.intelligence: ScalingGrade.s},
    damageType: DamageType.magic,
  ),
};

class WeaponInstance {
  WeaponInstance({required this.weaponId, this.upgrade = 0, List<String?>? sockets})
      : sockets = sockets == null || sockets.length != 3
            ? List<String?>.filled(3, null)
            : List<String?>.of(sockets);

  final String weaponId;
  int upgrade;

  WeaponDef get def => weaponDefs[weaponId]!;

  String get displayName => upgrade > 0 ? '${def.name} +$upgrade' : def.name;

  /// A +3, +6 e +10 l'aspetto cambia.
  int get visualTier => switch (upgrade) {
        >= 10 => 3,
        >= 6 => 2,
        >= 3 => 1,
        _ => 0,
      };

  /// Potere d'attacco: danno base potenziato + scaling sugli attributi.
  double attackRating(Character c, {double amuletBonus = 0}) {
    final base = def.baseDamage * (1 + 0.12 * upgrade);
    var scaled = 0.0;
    def.scaling.forEach((attr, grade) {
      scaled += (c.attr(attr) - Character.baseAttribute).clamp(0, 99) *
          grade.coefficient *
          (1 + 0.05 * upgrade);
    });
    // L'amuleto d'affinità aggiunge uno scaling C sul suo attributo.
    final aura = this.aura;
    if (aura != null) {
      final attr = Affinity.attributes.entries.firstWhere((e) => e.value == aura).key;
      scaled += (c.attr(attr) - Character.baseAttribute).clamp(0, 99) *
          ScalingGrade.c.coefficient *
          (1 + 0.05 * upgrade);
    }
    return (base + scaled) * (1 + amuletBonus);
  }

  /// Pietra richiesta per il prossimo potenziamento: Forgia I fino a +3, II
  /// fino a +6, III fino a +9, Astrale per il +10. Le armi speciali hanno le
  /// Tenebre I-IV per +1..+4 e l'Epica per il +5.
  String? get nextStone => stoneFor(def, upgrade + 1);

  int get nextStoneCost => nextStone == null ? 0 : stoneCostFor(def, upgrade + 1);

  /// Tre incastonature: [0] l'amuleto d'affinità (colore, aura e scaling),
  /// [1] e [2] amuleti passivi.
  final List<String?> sockets;

  /// L'aura viene solo dall'amuleto d'affinità: senza, acciaio nudo.
  Affinity? get aura => amuletDefs[sockets[0]]?.apply.aura;

  /// Livello visivo dell'aura: tinta a +3, luce a +6, aura piena a +10.
  int get glowTier => aura == null ? 0 : visualTier;

  Iterable<Amulet> get amulets => sockets.map((id) => amuletDefs[id]).whereType<Amulet>();

  Map<String, dynamic> toJson() => {'id': weaponId, 'up': upgrade, 'am': sockets};

  factory WeaponInstance.fromJson(Map<String, dynamic> j) => WeaponInstance(
        weaponId: j['id'] as String,
        upgrade: j['up'] as int,
        sockets: (j['am'] as List?)?.cast<String?>(),
      );
}

/// Pietra per arrivare al livello [level].
String? stoneFor(WeaponDef def, int level) {
  if (level > def.maxUpgrade || level < 1) return null;
  if (def.rare) {
    return level == 5
        ? 'epic_stone'
        : level == 1
            ? 'somber_stone'
            : 'somber_stone_$level';
  }
  if (level <= 3) return 'forge_stone_1';
  if (level <= 6) return 'forge_stone_2';
  if (level <= 9) return 'forge_stone_3';
  return 'ancient_stone';
}

/// Quante pietre: 1, 2, 3 dentro ogni gradino; una sola per Astrale,
/// Tenebre ed Epica.
int stoneCostFor(WeaponDef def, int level) => def.rare || level == 10 ? 1 : ((level - 1) % 3) + 1;

class Amulet {
  const Amulet(this.id, String name, String description, this.apply)
      : _name = name,
        _description = description;
  final String id;
  final String _name;
  final String _description;
  String get name => tr(_name);
  String get nameIt => _name;
  String get description => tr(_description);
  String get descriptionIt => _description;
  final AmuletEffect apply;

  /// Gli amuleti d'affinità vanno nella prima incastonatura, gli altri nelle
  /// due passive.
  bool get isAffinity => apply.aura != null;
}

class AmuletEffect {
  const AmuletEffect({
    this.holyDamage = 0,
    this.heavyDamage = 0,
    this.rareLoot = 0,
    this.lowHpDamage = 0,
    this.damage = 0,
    this.lootBonus = 0,
    this.bossDamage = 0,
    this.critDamage = 0,
    this.aura,
  });

  /// Danno in più contro i boss.
  final double bossDamage;

  /// Danno in più delle rep perfette (i critici).
  final double critDamage;
  final double holyDamage;
  final double heavyDamage;
  final double rareLoot;
  final double lowHpDamage;

  /// Danno in più con qualunque arma.
  final double damage;

  /// Rune e materiali in più da ogni vittoria.
  final double lootBonus;

  /// L'aura che l'arma prende, qualunque sia il suo scaling.
  final Affinity? aura;
}

const Map<String, Amulet> amuletDefs = {
  'fervent': Amulet(
    'fervent',
    'Amuleto del Fervente',
    '+10% danno sacro',
    AmuletEffect(holyDamage: 0.10),
  ),
  'colossus_seal': Amulet(
    'colossus_seal',
    'Sigillo del Colosso',
    '+8% danno con armi pesanti',
    AmuletEffect(heavyDamage: 0.08),
  ),
  'hunter_heart': Amulet(
    'hunter_heart',
    'Cuore del Cacciatore',
    '+10% probabilità di bottino raro contro le bestie',
    AmuletEffect(rareLoot: 0.10),
  ),
  'martyr_relic': Amulet(
    'martyr_relic',
    'Reliquia del Martire',
    '+15% danno quando la vita è sotto il 30%',
    AmuletEffect(lowHpDamage: 0.15),
  ),
  'ember_amulet': Amulet(
    'ember_amulet',
    'Amuleto della Brace',
    'Fuoco: l\'arma cresce con la Forza',
    AmuletEffect(damage: 0.05, aura: Affinity.fire),
  ),
  'gale_amulet': Amulet(
    'gale_amulet',
    'Amuleto della Bufera',
    'Vento: l\'arma cresce con la Destrezza',
    AmuletEffect(damage: 0.05, aura: Affinity.wind),
  ),
  'holy_amulet': Amulet(
    'holy_amulet',
    'Amuleto della Luce',
    'Luce divina: l\'arma cresce con la Fede',
    AmuletEffect(damage: 0.05, aura: Affinity.holy),
  ),
  'abyss_amulet': Amulet(
    'abyss_amulet',
    'Amuleto dell\'Abisso',
    'Arcano: l\'arma cresce con l\'Intelligenza',
    AmuletEffect(damage: 0.05, aura: Affinity.arcane),
  ),
  'regicide_seal': Amulet(
    'regicide_seal',
    'Sigillo del Regicida',
    '+5% danno contro i boss',
    AmuletEffect(bossDamage: 0.05),
  ),
  'fang_charm': Amulet(
    'fang_charm',
    'Zanna del Lupo Grigio',
    '+10% danno dei critici',
    AmuletEffect(critDamage: 0.10),
  ),
  'oath_sigil': Amulet(
    'oath_sigil',
    'Sigillo del Giuramento',
    '+5% danno',
    AmuletEffect(damage: 0.05),
  ),
  'sleepless_seal': Amulet(
    'sleepless_seal',
    'Sigillo dell\'Insonne',
    '+10% rune e materiali da ogni vittoria',
    AmuletEffect(lootBonus: 0.10),
  ),
};

/// Gli amuleti d'aura si incantano con il cuore della build.
const Map<String, Map<String, int>> amuletRecipes = {
  'ember_amulet': {'ember_heart': 1, 'gem_pure': 1, 'ember_iron': 4},
  'gale_amulet': {'storm_eye': 1, 'gem_pure': 1, 'gale_silver': 4},
  'holy_amulet': {'martyr_tear': 1, 'gem_pure': 1, 'hallowed_gold': 4},
  'abyss_amulet': {'star_core': 1, 'gem_pure': 1, 'abyss_crystal': 4},
};

/// Il nome di qualunque oggetto: materiale, arma o amuleto.
String itemName(String id) =>
    materialNames[id] ??
    weaponDefs[id]?.name ??
    amuletDefs[id.replaceFirst('amulet_', '')]?.name ??
    id;

/// I nomi dei materiali nella lingua corrente (per l'italiano, la tabella
/// [materialNamesIt] così com'è).
Map<String, String> get materialNames {
  if (appLang == Lang.it) return materialNamesIt;
  final cached = _materialNamesCache;
  if (cached != null && cached.$1 == appLang) return cached.$2;
  final out = Map<String, String>.unmodifiable({
    for (final e in materialNamesIt.entries) e.key: tr(e.value),
  });
  _materialNamesCache = (appLang, out);
  return out;
}

(Lang, Map<String, String>)? _materialNamesCache;

/// I nomi italiani dei materiali, come scritti nel codice.
const Map<String, String> materialNamesIt = {
  'iron_ore': 'Minerale di ferro',
  'ash_wood': 'Legno di frassino cenere',
  'beast_essence': 'Essenza di bestia',
  'ash_pickaxe': 'Piccone di frassino',
  'iron_axe': 'Accetta di ferro',
  'iron_pickaxe': 'Piccone di ferro',
  'steel_axe': 'Accetta d\'acciaio',
  'steel_pickaxe': 'Piccone d\'acciaio',
  'holy_shard': 'Scheggia sacra',
  'forge_stone_1': 'Pietra di forgia I',
  'forge_stone_2': 'Pietra di forgia II',
  'forge_stone_3': 'Pietra di forgia III',
  'ancient_stone': 'Pietra di forgia astrale',
  'somber_stone': 'Pietra delle Tenebre I',
  'somber_stone_2': 'Pietra delle Tenebre II',
  'somber_stone_3': 'Pietra delle Tenebre III',
  'somber_stone_4': 'Pietra delle Tenebre IV',
  'epic_stone': 'Pietra Epica dell\'Eclissi',
  'iron_ingot': 'Lingotto di ferro',
  'ash_plank': 'Asse di frassino',
  'reinforced_grip': 'Impugnatura rinforzata',
  'oak_wood': 'Legno di quercia nera',
  'yew_wood': 'Legno di tasso dei morti',
  'ebony_wood': 'Legno d\'ebano del crepuscolo',
  'coal': 'Carbone',
  'moon_silver': 'Argento lunare',
  'star_ore': 'Minerale stellare',
  'oak_plank': 'Asse di quercia',
  'yew_plank': 'Asse di tasso',
  'ebony_plank': 'Asse d\'ebano',
  'steel_ingot': 'Lingotto d\'acciaio',
  'silver_ingot': 'Lingotto d\'argento lunare',
  'star_ingot': 'Lingotto stellare',
  // Materiali base dei gruppi.
  'raw_hide': 'Pelle grezza',
  'tanned_leather': 'Cuoio conciato',
  'bronze_ingot': 'Lingotto di bronzo',
  'gold_ingot': 'Lingotto d\'oro',
  'bone': 'Ossa antiche',
  'abyss_ink': 'Inchiostro d\'abisso',
  // Materiali di build: Forza, Destrezza, Fede, Intelligenza.
  'ember_iron': 'Ferro di Brace',
  'godforge_steel': 'Acciaio della Fucina Divina',
  'gale_silver': 'Argento di Bufera',
  'steel_feather': 'Piuma d\'Acciaio',
  'hallowed_gold': 'Oro Consacrato',
  'martyr_obsidian': 'Ossidiana del Martire',
  'abyss_crystal': 'Cristallo d\'Abisso',
  // Componenti rari delle build.
  'ember_heart': 'Cuore di Brace',
  'storm_eye': 'Occhio della Tempesta',
  'martyr_tear': 'Lacrima del Martire',
  'star_core': 'Nucleo Stellare',
  'dream_pearl': 'Perla del Sogno',
  'star_iron': 'Ferro Stellare',
  // Gemme dello Stretching: serviranno agli amuleti da innestare nell'arma.
  'gem_rough': 'Gemma grezza',
  'gem_cut': 'Gemma tagliata',
  'gem_pure': 'Gemma pura',
  'gem_perfect': 'Gemma perfetta',
};

/// Alla fornace: minerale dai passi + essenza dai mostri = Pietra di forgia I.
/// Componenti di build per attributo: [I, II, cuore raro]. Ogni gruppo
/// muscolare li lascia cadere, ma arrivano sempre quelli del Giuramento del
/// giocatore, così nessuna build è costretta a un solo gruppo.
const Map<Attribute, List<String>> buildMaterials = {
  Attribute.strength: ['ember_iron', 'godforge_steel', 'ember_heart'],
  Attribute.dexterity: ['gale_silver', 'steel_feather', 'storm_eye'],
  Attribute.faith: ['hallowed_gold', 'martyr_obsidian', 'martyr_tear'],
  Attribute.intelligence: ['abyss_crystal', 'star_iron', 'star_core'],
};

/// Le build che si possono giurare.
const List<Attribute> oathAttributes = [
  Attribute.strength,
  Attribute.dexterity,
  Attribute.faith,
  Attribute.intelligence,
];

/// Il componente equivalente per la build [build] (gli altri restano uguali).
String forBuild(String id, Attribute build) {
  for (final list in buildMaterials.values) {
    final i = list.indexOf(id);
    if (i >= 0) return buildMaterials[build]![i];
  }
  return id;
}

Map<String, int> lootForBuild(Map<String, int> loot, Attribute build) {
  final out = <String, int>{};
  loot.forEach((k, v) => out.update(forBuild(k, build), (o) => o + v, ifAbsent: () => v));
  return out;
}

/// Il forziere della quest giornaliera: materiali della fascia del
/// giocatore, una pietra di forgia e, dalla fascia III, i componenti della
/// sua build (con una piccola probabilità del cuore raro).
Map<String, int> questLootFor(int level, Attribute build, Random r) {
  final tier = (level ~/ 10).clamp(0, 3);
  final loot = <String, int>{
    ...switch (tier) {
      0 => {'iron_ingot': 2, 'ash_plank': 1, 'beast_essence': 2, 'forge_stone_1': 1},
      1 => {'steel_ingot': 2, 'oak_plank': 1, 'holy_shard': 1, 'forge_stone_1': 2},
      2 => {'silver_ingot': 2, 'yew_plank': 1, 'forge_stone_2': 1},
      _ => {'star_ingot': 2, 'ebony_plank': 1, 'forge_stone_3': 1},
    },
  };
  final parts = buildMaterials[build]!;
  if (tier >= 1) loot[parts[0]] = tier == 1 ? 1 : 2;
  if (tier >= 3) loot[parts[1]] = 1;
  if (tier >= 2 && r.nextDouble() < 0.1) loot[parts[2]] = 1;
  if (r.nextDouble() < 0.25) loot['gem_rough'] = 1;
  return loot;
}

const Map<String, int> forgeStone1Recipe = {'iron_ore': 30, 'beast_essence': 1};
