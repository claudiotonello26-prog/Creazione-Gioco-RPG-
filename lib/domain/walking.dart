import 'dart:math';

/// La Camminata: i passi del giorno diventano materiali da forgia.
///
/// Si conta sul totale del giorno, così riscuotere più volte dà solo la
/// differenza e nessun passo vale due volte.
class StepMilestone {
  const StepMilestone(this.steps, this.loot, this.title);
  final int steps;
  final Map<String, int> loot;
  final String title;
}

/// Oltre questo i passi non danno più nulla: niente farming col telefono in
/// lavatrice.
const int dailyStepCap = 25000;

const int stepsPerOre = 1000;
const int stepsPerWood = 2500;

const List<StepMilestone> stepMilestones = [
  StepMilestone(5000, {'forge_stone_1': 1}, 'Pellegrino'),
  StepMilestone(10000, {'forge_stone_1': 1, 'holy_shard': 1}, 'Viandante'),
  StepMilestone(15000, {'forge_stone_2': 1}, 'Crociato in marcia'),
  StepMilestone(20000, {'ancient_stone': 1}, 'Leggenda delle strade'),
];

/// Materiali totali che valgono [steps] passi in un giorno.
Map<String, int> lootForSteps(int steps) {
  final s = min(max(steps, 0), dailyStepCap);
  final loot = <String, int>{};
  void add(String id, int q) {
    if (q > 0) loot[id] = (loot[id] ?? 0) + q;
  }

  add('iron_ore', s ~/ stepsPerOre);
  add('ash_wood', s ~/ stepsPerWood);
  for (final m in stepMilestones) {
    if (s >= m.steps) m.loot.forEach(add);
  }
  return loot;
}

/// Quello che spetta passando da [claimed] a [total] passi nello stesso giorno.
Map<String, int> stepLootDelta(int claimed, int total) {
  final before = lootForSteps(claimed);
  final after = lootForSteps(total);
  return {
    for (final e in after.entries)
      if (e.value - (before[e.key] ?? 0) > 0) e.key: e.value - (before[e.key] ?? 0),
  };
}

/// Prossimo traguardo da raggiungere, o null se sono finiti.
StepMilestone? nextMilestone(int steps) {
  for (final m in stepMilestones) {
    if (steps < m.steps) return m;
  }
  return null;
}
