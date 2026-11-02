// ignore_for_file: prefer_initializing_formals

// Contratti di Caccia (dalla Razzia di Gymscape): un committente affida un
// contratto sigillato; solo dopo la firma si scopre quali spedizioni portare
// a termine. Più sale l'abilità Spedizioni, più committenti si aprono: chiedono
// più spedizioni e pagano forzieri migliori, fino alle armi speciali della
// propria build.

import 'dart:math';

import '../core/i18n.dart';
import 'character.dart';
import 'enemies.dart';
import 'items.dart';

/// Al posto di un oggetto nei rari: l'arma speciale della build del giocatore.
const String buildRareWeapon = 'build_rare_weapon';

class Contractor {
  const Contractor({
    required this.id,
    required String name,
    required String blurb,
    required this.minSkill,
    required this.expeditions,
    required String chestName,
    required this.runes,
    required this.skillXp,
    required this.guaranteed,
    required this.rares,
  }) : _name = name,
       _blurb = blurb,
       _chestName = chestName;

  final String id;
  final String _name;
  String get name => tr(_name);
  final String _blurb;
  String get blurb => tr(_blurb);

  /// Livello dell'abilità Spedizioni per firmare.
  final int minSkill;

  /// Quante spedizioni diverse chiede il contratto.
  final int expeditions;

  final String _chestName;
  String get chestName => tr(_chestName);
  final int runes;

  /// XP di Spedizioni alla consegna.
  final int skillXp;

  /// I componenti di build (Forza) diventano quelli del Giuramento.
  final Map<String, int> guaranteed;
  final List<(String, double)> rares;

  int get tier => contractors.indexOf(this) + 1;
}

const List<Contractor> contractors = [
  Contractor(
    id: 'bran',
    name: 'Bran il Guercio',
    blurb: 'Vecchio cacciatore di taglie. Paga poco, ma paga sempre.',
    minSkill: 1,
    expeditions: 1,
    chestName: 'Forziere del Cacciatore',
    runes: 250,
    skillXp: 150,
    guaranteed: {'iron_ingot': 3, 'tanned_leather': 2, 'forge_stone_1': 2, 'gem_rough': 1},
    rares: [('ember_iron', 0.5), ('forge_stone_2', 0.25), ('oath_sigil', 0.03)],
  ),
  Contractor(
    id: 'ilse',
    name: 'Sorella Ilse della Lanterna',
    blurb: 'Una monaca che tiene il conto dei mostri. Vuole prove, non chiacchiere.',
    minSkill: 10,
    expeditions: 1,
    chestName: 'Forziere Rinforzato',
    runes: 600,
    skillXp: 350,
    guaranteed: {
      'steel_ingot': 3,
      'forge_stone_2': 1,
      'ember_iron': 2,
      'gem_cut': 1,
      'holy_shard': 1,
    },
    rares: [
      ('godforge_steel', 0.3),
      ('ancient_stone', 0.1),
      ('ember_heart', 0.03),
      ('regicide_seal', 0.04),
    ],
  ),
  Contractor(
    id: 'varo',
    name: 'Capitano Varo',
    blurb: 'Mercenario senza bandiera. Due spedizioni, nessuna domanda.',
    minSkill: 20,
    expeditions: 2,
    chestName: 'Forziere Ornato',
    runes: 1200,
    skillXp: 800,
    guaranteed: {'silver_ingot': 3, 'forge_stone_3': 1, 'godforge_steel': 2, 'gem_pure': 1},
    rares: [
      ('ember_heart', 0.15),
      ('ancient_stone', 0.2),
      ('somber_stone', 0.15),
      (buildRareWeapon, 0.04),
    ],
  ),
  Contractor(
    id: 'widow',
    name: 'La Vedova Grigia',
    blurb: 'Nessuno sa chi paghi davvero. Tre spedizioni, e un forziere che vale un regno.',
    minSkill: 30,
    expeditions: 3,
    chestName: 'Forziere Antico',
    runes: 2500,
    skillXp: 1600,
    guaranteed: {
      'star_ingot': 3,
      'forge_stone_3': 2,
      'godforge_steel': 3,
      'gem_perfect': 1,
      'ember_heart': 1,
    },
    rares: [
      (buildRareWeapon, 0.1),
      ('somber_stone', 0.3),
      ('epic_stone', 0.03),
      ('sleepless_seal', 0.04),
    ],
  ),
];

Contractor contractorById(String id) => contractors.firstWhere((c) => c.id == id);

/// L'arma speciale di una build: quella rara che cresce di più con il suo
/// attributo.
String rareWeaponFor(Attribute build) {
  WeaponDef? best;
  for (final w in weaponDefs.values) {
    if (!w.rare) continue;
    final grade = w.scaling[build];
    if (grade == null) continue;
    if (best == null || grade.coefficient > best.scaling[build]!.coefficient) best = w;
  }
  return best!.id;
}

/// Un contratto firmato: le spedizioni da finire e quelle già fatte.
class HuntContract {
  HuntContract({required this.contractorId, required this.targets, Set<String>? done})
    : done = done ?? {};
  final String contractorId;
  final List<String> targets;
  final Set<String> done;

  Contractor get contractor => contractorById(contractorId);
  bool get complete => targets.every(done.contains);

  Map<String, dynamic> toJson() => {'c': contractorId, 't': targets, 'd': done.toList()};

  factory HuntContract.fromJson(Map<String, dynamic> j) => HuntContract(
    contractorId: j['c'] as String,
    targets: (j['t'] as List).cast<String>(),
    done: {...(j['d'] as List).cast<String>()},
  );
}

/// Sceglie le spedizioni del contratto fra quelle alla portata del
/// cavaliere, da gruppi muscolari diversi quando si può.
List<String> drawContractTargets(Contractor c, int playerLevel, Random r) {
  var pool = expeditions.where((e) => e.level <= playerLevel).toList();
  if (pool.length < c.expeditions) {
    pool = (expeditions.toList()..sort((a, b) => a.level.compareTo(b.level)))
        .take(max(c.expeditions, 5))
        .toList();
  }
  pool.shuffle(r);
  final out = <Expedition>[];
  for (final e in pool) {
    if (out.length == c.expeditions) break;
    if (out.every((o) => o.group != e.group)) out.add(e);
  }
  for (final e in pool) {
    if (out.length == c.expeditions) break;
    if (!out.contains(e)) out.add(e);
  }
  return [for (final e in out) e.id];
}

/// Rune per annullare un contratto dopo il primo annullamento gratuito del
/// giorno.
int cancelCost(Contractor c) => 100 * c.tier;
