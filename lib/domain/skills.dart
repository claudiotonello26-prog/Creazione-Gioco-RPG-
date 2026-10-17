import 'dart:math';

import 'items.dart';

/// Mestieri che salgono di livello come su Gymscape: i passi allenano
/// Taglialegna e Minatore, la forgia allena Carpenteria, Fornace e Incudine.
enum Skill {
  woodcutting('Taglialegna'),
  mining('Minatore'),
  carpentry('Carpenteria'),
  smelting('Fornace'),
  smithing('Incudine');

  const Skill(this.label);
  final String label;

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
(int, int, int) skillProgress(int xp) {
  var lvl = 1;
  var rest = xp;
  while (lvl < maxSkillLevel && rest >= skillXpForLevel(lvl)) {
    rest -= skillXpForLevel(lvl);
    lvl++;
  }
  return (lvl, rest, skillXpForLevel(lvl));
}

/// Materia prima che si raccoglie camminando.
class Resource {
  const Resource(this.id, this.skill, this.level, this.stepsPerUnit, this.xp, this.where);
  final String id;
  final Skill skill;

  /// Livello del mestiere che la sblocca.
  final int level;
  final int stepsPerUnit;

  /// XP del mestiere per ogni unità raccolta.
  final int xp;

  /// Dove la si trova, per il racconto.
  final String where;

  String get name => materialNames[id] ?? id;
}

const List<Resource> resources = [
  Resource('ash_wood', Skill.woodcutting, 1, 400, 10, 'Boschi di cenere'),
  Resource('oak_wood', Skill.woodcutting, 5, 700, 18, 'Querceto nero'),
  Resource('yew_wood', Skill.woodcutting, 12, 1100, 30, 'Cimitero dei tassi'),
  Resource('ebony_wood', Skill.woodcutting, 20, 1800, 50, 'Selva del crepuscolo'),
  Resource('coal', Skill.mining, 1, 300, 8, 'Cave di carbone'),
  Resource('iron_ore', Skill.mining, 1, 500, 12, 'Miniera del pellegrino'),
  Resource('moon_silver', Skill.mining, 8, 900, 24, 'Grotte lunari'),
  Resource('star_ore', Skill.mining, 16, 1500, 40, 'Cratere della stella caduta'),
];

Resource resourceById(String id) => resources.firstWhere((r) => r.id == id);

/// XP del mestiere per un oggetto creato.
int craftXp(int level) => 8 + level * 3;
