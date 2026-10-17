import 'dart:math';

import 'items.dart';

/// Mestieri che salgono di livello come su Gymscape: i passi allenano
/// Taglialegna e Minatore, la forgia allena Carpenteria, Fornace e Incudine.
enum Skill {
  woodcutting('Taglialegna'),
  mining('Minatore'),
  carpentry('Carpenteria'),
  smelting('Fornace'),
  smithing('Incudine'),

  /// Combattimento: la postura decide quale dei due sale.
  attack('Attacco'),
  defense('Difesa');

  const Skill(this.label);
  final String label;

  bool get combat => this == attack || this == defense;

  /// I mestieri arrivano al 30, Attacco e Difesa al 99.
  int get maxLevel => combat ? 99 : maxSkillLevel;

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
  const Resource(this.id, this.skill, this.level, this.stepsPerUnit, this.xp, this.where,
      {this.tool});
  final String id;
  final Skill skill;

  /// Livello del mestiere che la sblocca.
  final int level;
  final int stepsPerUnit;

  /// XP del mestiere per ogni unità raccolta.
  final int xp;

  /// Dove la si trova, per il racconto.
  final String where;

  /// Attrezzo minimo per raccoglierla (null = a mani nude).
  final String? tool;

  String get name => materialNames[id] ?? id;
}

const List<Resource> resources = [
  Resource('ash_wood', Skill.woodcutting, 1, 400, 10, 'Boschi di cenere'),
  Resource('oak_wood', Skill.woodcutting, 5, 700, 18, 'Querceto nero', tool: 'iron_axe'),
  Resource('yew_wood', Skill.woodcutting, 12, 1100, 30, 'Cimitero dei tassi', tool: 'steel_axe'),
  Resource('ebony_wood', Skill.woodcutting, 20, 1800, 50, 'Selva del crepuscolo', tool: 'steel_axe'),
  Resource('coal', Skill.mining, 1, 300, 8, 'Cave di carbone'),
  Resource('iron_ore', Skill.mining, 1, 500, 12, 'Miniera del pellegrino', tool: 'ash_pickaxe'),
  Resource('moon_silver', Skill.mining, 8, 900, 24, 'Grotte lunari', tool: 'iron_pickaxe'),
  Resource('star_ore', Skill.mining, 16, 1500, 40, 'Cratere della stella caduta', tool: 'steel_pickaxe'),
];

/// Attrezzi in ordine di qualità: uno migliore vale anche per ciò che
/// sblocca quello precedente, e raccoglie di più a parità di passi.
const List<String> axes = ['iron_axe', 'steel_axe'];
const List<String> pickaxes = ['ash_pickaxe', 'iron_pickaxe', 'steel_pickaxe'];

const Map<String, double> toolYield = {
  'iron_axe': 0.2,
  'steel_axe': 0.4,
  'ash_pickaxe': 0.0,
  'iron_pickaxe': 0.2,
  'steel_pickaxe': 0.4,
};

bool isTool(String id) => toolYield.containsKey(id);

Resource resourceById(String id) => resources.firstWhere((r) => r.id == id);

/// XP del mestiere per un oggetto creato.
int craftXp(int level) => 8 + level * 3;
