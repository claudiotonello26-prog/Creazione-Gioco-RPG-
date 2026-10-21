// Collezione: ogni materiale che serve a una ricetta, a una pietra di
// potenziamento o a un amuleto deve avere almeno una fonte (mostri, forzieri,
// contratti, quest, boss, passi, Mercante o un'altra ricetta), per ogni
// build. Controllo statico sui dati del gioco, senza simulare.

import 'dart:math';

import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/contracts.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/hunting.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:iron_oath/domain/novice.dart';
import 'package:iron_oath/domain/skills.dart';

/// Dove si trova ogni materiale grezzo per la build [build] (id → fonti).
Map<String, Set<String>> sourcesFor(Attribute build) {
  final out = <String, Set<String>>{};
  void add(String id, String where) =>
      out.putIfAbsent(forBuild(id, build), () => {}).add(where);

  for (final e in [...enemyDefs.values, ...baseAnimals, ...huntAnimals]) {
    for (final id in e.commonLoot.keys) {
      add(id, e.nameIt);
    }
    for (final id in [...e.uncommonLoot, ...e.rareLoot]) {
      if (weaponDefs.containsKey(id)) continue;
      add(amuletDefs.containsKey(id) ? 'amulet_$id' : id, '${e.nameIt} (raro)');
    }
  }
  for (final e in expeditions) {
    for (final id in e.chest.guaranteed.keys) {
      add(id, 'forziere ${e.id}');
    }
    for (final (id, _) in e.chest.rares) {
      add(amuletDefs.containsKey(id) ? 'amulet_$id' : id, 'forziere ${e.id} (raro)');
    }
  }
  for (final c in contractors) {
    for (final id in c.guaranteed.keys) {
      add(id, 'contratto ${c.id}');
    }
    for (final (id, _) in c.rares) {
      if (id == buildRareWeapon) continue;
      add(amuletDefs.containsKey(id) ? 'amulet_$id' : id, 'contratto ${c.id} (raro)');
    }
  }
  final r = Random(1);
  for (var level = 1; level <= 60; level += 5) {
    for (var i = 0; i < 40; i++) {
      for (final id in questLootFor(level, build, r).keys) {
        // questLootFor converte già per la build.
        out.putIfAbsent(id, () => {}).add('quest del giorno');
      }
    }
  }
  final g = GameState()..setOath(build);
  for (final m in MuscleGroup.values) {
    for (var i = 0; i < 30; i++) {
      for (final id in g.bossLoot(m, weighted: true, random: r).keys) {
        add(id, 'boss del sentiero');
      }
    }
  }
  for (final q in noviceQuests) {
    for (final id in q.loot.keys) {
      add(id, 'Cammino del Novizio');
    }
  }
  for (final id in merchantStock) {
    add(id, 'Mercante');
  }
  for (final res in resources) {
    add(res.id, 'passi');
  }
  for (final id in amuletPrices.keys) {
    add('amulet_$id', 'Fattucchiera');
  }
  return out;
}

/// Cosa serve a una build: ricette di armi, armature, mani sinistre,
/// materiali e amuleti che non usano i componenti delle altre build, più
/// tutte le pietre di potenziamento.
Map<String, Set<String>> needsFor(Attribute build) {
  final others = {
    for (final e in buildMaterials.entries)
      if (e.key != build) ...e.value,
  };
  final out = <String, Set<String>>{};
  void need(String what, Map<String, int> recipe) {
    if (recipe.keys.any(others.contains)) return;
    for (final id in recipe.keys) {
      out.putIfAbsent(id, () => {}).add(what);
    }
  }

  for (final w in weaponDefs.values) {
    need('arma ${w.id}', w.recipe);
    for (var l = 1; l <= w.maxUpgrade; l++) {
      need('${w.id} +$l', {stoneFor(w, l)!: 1});
    }
  }
  for (final a in armorDefs.values) {
    if (a.attribute != null && a.attribute != build) continue;
    need('armatura ${a.id}', a.recipe);
  }
  for (final o in offhandDefs.values) {
    need('mano sinistra ${o.id}', o.recipe);
  }
  for (final r in materialRecipes) {
    need('ricetta ${r.output}', r.inputs);
  }
  for (final e in amuletRecipes.entries) {
    need('amuleto ${e.key}', e.value);
  }
  return out;
}

/// Materiali necessari che non si trovano da nessuna parte (né direttamente
/// né da una ricetta sbloccabile), per build: id → chi li chiede.
Map<String, Set<String>> unobtainable(Attribute build) {
  final sources = sourcesFor(build);
  final have = {...sources.keys};
  // Chiusura: una ricetta i cui ingredienti si trovano rende trovabile il
  // suo prodotto.
  var changed = true;
  while (changed) {
    changed = false;
    for (final r in materialRecipes) {
      if (!have.contains(r.output) && r.inputs.keys.every(have.contains)) {
        have.add(r.output);
        changed = true;
      }
    }
    for (final e in amuletRecipes.entries) {
      final id = 'amulet_${e.key}';
      if (!have.contains(id) && e.value.keys.every(have.contains)) {
        have.add(id);
        changed = true;
      }
    }
  }
  final needs = needsFor(build);
  return {
    for (final e in needs.entries)
      if (!have.contains(e.key)) e.key: e.value,
  };
}

/// Materiali che si trovano ma non servono a niente (solo da vendere).
Set<String> unused() {
  final used = <String>{};
  for (final b in oathAttributes) {
    used.addAll(needsFor(b).keys);
  }
  final found = <String>{};
  for (final b in oathAttributes) {
    found.addAll(sourcesFor(b).keys);
  }
  return found
      .where((id) =>
          !used.contains(id) &&
          !id.startsWith('amulet_') &&
          !isTool(id) &&
          !weaponDefs.containsKey(id) &&
          !armorDefs.containsKey(id) &&
          !offhandDefs.containsKey(id))
      .toSet();
}
