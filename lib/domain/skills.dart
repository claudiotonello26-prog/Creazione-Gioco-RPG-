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

  /// XP del mestiere per ogni unità raccolta.
  final int xp;

  /// Dove la si trova, per il racconto.
  final String _where;
  String get where => tr(_where);

  /// Attrezzo minimo per raccoglierla (null = a mani nude).
  final String? tool;

  String get name => tr(materialNames[id] ?? id);
}

const List<Resource> resources = [
  Resource('ash_wood', Skill.woodcutting, 1, 40, 10, 'Boschi di cenere'),
  Resource('oak_wood', Skill.woodcutting, 5, 70, 18, 'Querceto nero', tool: 'iron_axe'),
  Resource('yew_wood', Skill.woodcutting, 12, 110, 30, 'Cimitero dei tassi', tool: 'steel_axe'),
  Resource('ebony_wood', Skill.woodcutting, 20, 180, 50, 'Selva del crepuscolo', tool: 'steel_axe'),
  Resource('coal', Skill.mining, 1, 30, 8, 'Cave di carbone'),
  Resource('iron_ore', Skill.mining, 1, 50, 12, 'Miniera del pellegrino', tool: 'ash_pickaxe'),
  Resource('moon_silver', Skill.mining, 8, 90, 24, 'Grotte lunari', tool: 'iron_pickaxe'),
  Resource(
    'star_ore',
    Skill.mining,
    16,
    150,
    40,
    'Cratere della stella caduta',
    tool: 'steel_pickaxe',
  ),
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
