import 'dart:math';

import '../core/i18n.dart';
import 'items.dart';

/// Abilità che salgono di livello come su Gymscape. Combattimento: Attacco,
/// Difesa e Magia (la postura e l'arma decidono quale sale), Spedizioni
/// (sale battendo i nemici delle spedizioni). Produzione: i passi allenano
/// Boscaiolo e Minatore, la forgia Falegnameria, Fusione e Forgiatura.
enum Skill {
  woodcutting('Woodcutting'),
  mining('Mining'),
  carpentry('Carpentry'),
  smelting('Smelting'),
  smithing('Smithing'),
  attack('Attack'),
  defense('Defence'),
  magic('Magic'),
  expeditions('Expeditions');

  const Skill(this.key);

  /// Nome inglese, che è anche la chiave della traduzione.
  final String key;
  String get label => tr(key);

  bool get combat => combatSkills.contains(this);

  /// I mestieri arrivano al 30, le abilità di combattimento al 99.
  int get maxLevel => combat ? 99 : maxSkillLevel;

  static const List<Skill> combatSkills = [attack, defense, magic, expeditions];
  static const List<Skill> crafts = [woodcutting, mining, carpentry, smelting, smithing];

  static Skill forStation(Station s) => switch (s) {
        Station.carpentry => carpentry,
        Station.furnace => smelting,
        _ => smithing,
      };
}

const int maxSkillLevel = 30;

/// XP per passare dal livello [level] al successivo.
int skillXpForLevel(int level) => (40 * pow(level, 1.5)).round();

/// (livello, xp nel livello, xp per il prossimo)
(int, int, int) skillProgress(int xp, {int max = maxSkillLevel}) {
  var lvl = 1;
  var rest = xp;
  while (lvl < max && rest >= skillXpForLevel(lvl)) {
    rest -= skillXpForLevel(lvl);
    lvl++;
  }
  return (lvl, rest, skillXpForLevel(lvl));
}

/// Materia prima che si raccoglie camminando.
class Resource {
  const Resource(
    this.id,
    this.skill,
    this.level,
    this.stepsPerUnit,
    this.xp,
    this._where, {
    this.tool,
  });
  final String id;
  final Skill skill;

  /// Livello del mestiere che la sblocca.
  final int level;
  final int stepsPerUnit;

  /// XP del mestiere per ogni unità raccolta. Ridotti del 40% quando sono
  /// arrivati i minerali alti: il Minatore arrivava al 30 in un mese e mezzo,
  /// prima che la Fornace potesse usare quello che scavava.
  final int xp;

  /// Dove la si trova, per il racconto.
  final String _where;
  String get where => tr(_where);

  /// Attrezzo minimo per raccoglierla (null = a mani nude).
  final String? tool;

  String get name => tr(materialNames[id] ?? id);
}

const List<Resource> resources = [
  Resource('ash_wood', Skill.woodcutting, 1, 40, 6, 'Boschi di cenere'),
  Resource('oak_wood', Skill.woodcutting, 5, 70, 11, 'Querceto nero', tool: 'iron_axe'),
  Resource('yew_wood', Skill.woodcutting, 12, 110, 18, 'Cimitero dei tassi', tool: 'steel_axe'),
  Resource('storm_resin', Skill.woodcutting, 14, 140, 22, 'Pinete battute dal fulmine',
      tool: 'steel_axe'),
  Resource('ebony_wood', Skill.woodcutting, 20, 180, 30, 'Selva del crepuscolo', tool: 'steel_axe'),
  Resource('coal', Skill.mining, 1, 30, 5, 'Cave di carbone'),
  Resource('iron_ore', Skill.mining, 1, 50, 7, 'Miniera del pellegrino', tool: 'ash_pickaxe'),
  Resource('copper_ore', Skill.mining, 4, 60, 9, 'Filoni di rame', tool: 'ash_pickaxe'),
  Resource('moon_silver', Skill.mining, 8, 90, 14, 'Grotte lunari', tool: 'iron_pickaxe'),
  Resource('gold_ore', Skill.mining, 10, 110, 17, 'Vene d\'oro della cattedrale',
      tool: 'iron_pickaxe'),
  Resource('ember_ore', Skill.mining, 14, 140, 22, 'Miniera ardente', tool: 'steel_pickaxe'),
  Resource(
    'star_ore',
    Skill.mining,
    16,
    150,
    24,
    'Cratere della stella caduta',
    tool: 'steel_pickaxe',
  ),
  Resource('abyss_geode', Skill.mining, 18, 170, 26, 'Pozzi d\'abisso', tool: 'steel_pickaxe'),
  Resource('living_obsidian', Skill.mining, 22, 200, 33, 'Bocca del vulcano spento',
      tool: 'star_pickaxe'),
];

/// Attrezzi in ordine di qualità: uno migliore vale anche per ciò che
/// sblocca quello precedente, e raccoglie di più a parità di passi.
const List<String> axes = ['iron_axe', 'steel_axe', 'star_axe'];
const List<String> pickaxes = ['ash_pickaxe', 'iron_pickaxe', 'steel_pickaxe', 'star_pickaxe'];

const Map<String, double> toolYield = {
  'iron_axe': 0.2,
  'steel_axe': 0.4,
  'star_axe': 0.6,
  'ash_pickaxe': 0.0,
  'iron_pickaxe': 0.2,
  'steel_pickaxe': 0.4,
  'star_pickaxe': 0.6,
};

bool isTool(String id) => toolYield.containsKey(id);

Resource resourceById(String id) => resources.firstWhere((r) => r.id == id);

/// XP del mestiere per un oggetto creato.
int craftXp(int level) => 8 + level * 3;

/// XP di una lavorazione (lingotti, assi, materiali speciali): pesa anche
/// quanta materia prima consuma, fino a ×4. Un lingotto di ferro (30 pezzi)
/// vale il triplo di un oggetto da 10: prima la Fornace saliva dieci volte
/// più piano del Minatore che la riforniva.
int materialCraftXp(int level, Map<String, int> inputs) {
  final units = inputs.values.fold(0, (a, b) => a + b);
  return (craftXp(level) * (units / 10).clamp(1.0, 4.0)).round();
}

/// Armi, armature e mani sinistre valgono molto più di un lingotto: costano
/// materiali rari e si fanno di rado, quindi devono far salire il mestiere.
const int gearCraftXpFactor = 10;
