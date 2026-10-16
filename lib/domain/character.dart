import 'dart:math';

import 'items.dart';

enum Attribute {
  vigor('Vigore', 'Punti vita: resisti di più ai colpi dei boss'),
  endurance('Resistenza', 'Quanto dura il Rampage prima di calare'),
  strength('Forza', 'Attacco con armi pesanti, armature pesanti'),
  dexterity('Destrezza', 'Attacco con armi leggere, critici più forti'),
  faith('Fede', 'Danno sacro, cure e benedizioni'),
  intelligence('Intelligenza', 'Magie ed effetti di stato');

  const Attribute(this.label, this.description);
  final String label;
  final String description;
}

class Character {
  Character({
    this.name = 'Senza Nome',
    this.xp = 0,
    this.disciplinePoints = 0,
    Map<Attribute, int>? attributes,
    this.runes = 0,
    WeaponInstance? weapon,
    List<String>? amulets,
    Map<String, int>? materials,
    List<WeaponInstance>? weapons,
    Set<String>? perks,
  })  : attributes = attributes ??
            {for (final a in Attribute.values) a: baseAttribute},
        weapon = weapon ?? WeaponInstance(weaponId: 'pilgrim_blade'),
        amulets = amulets ?? [],
        materials = materials ?? {},
        weapons = weapons ?? [],
        perks = perks ?? {};

  static const int baseAttribute = 10;

  String name;
  int xp;

  /// Punti guadagnati solo con stretching e sfide di mobilità.
  int disciplinePoints;
  final Map<Attribute, int> attributes;

  /// Valuta di gioco.
  int runes;
  WeaponInstance weapon;
  final List<WeaponInstance> weapons;
  final List<String> amulets;
  final Map<String, int> materials;
  final Set<String> perks;

  static const int maxAmuletSlots = 3;

  /// XP necessari per passare dal livello [level] al successivo.
  static int xpForLevel(int level) => (100 * pow(level, 1.5)).round();

  int get level {
    var lvl = 1;
    var remaining = xp;
    while (remaining >= xpForLevel(lvl)) {
      remaining -= xpForLevel(lvl);
      lvl++;
    }
    return lvl;
  }

  /// XP accumulati nel livello attuale e XP necessari per il prossimo.
  (int, int) get levelProgress {
    var lvl = 1;
    var remaining = xp;
    while (remaining >= xpForLevel(lvl)) {
      remaining -= xpForLevel(lvl);
      lvl++;
    }
    return (remaining, xpForLevel(lvl));
  }

  int get spentPoints => attributes.values
      .fold(0, (sum, v) => sum + (v - baseAttribute));

  /// Un punto per livello sopra il primo, più i Punti Disciplina.
  int get availablePoints => (level - 1) + disciplinePoints - spentPoints;

  bool raise(Attribute a) {
    if (availablePoints <= 0) return false;
    attributes[a] = attributes[a]! + 1;
    return true;
  }

  int attr(Attribute a) => attributes[a]!;

  /// Vita massima nel PvE.
  int get maxHp => 80 + attr(Attribute.vigor) * 6;

  /// Secondi di pausa prima che il Rampage inizi a calare.
  double get rampageGrace => 2.0 + attr(Attribute.endurance) * 0.08;

  void addMaterial(String id, int qty) =>
      materials[id] = (materials[id] ?? 0) + qty;

  bool spendMaterial(String id, int qty) {
    final have = materials[id] ?? 0;
    if (have < qty) return false;
    materials[id] = have - qty;
    return true;
  }

  /// Ogni 10 punti oltre il 10 in un attributo si sblocca una scelta di perk.
  List<PerkChoice> get unlockedPerkChoices => [
        for (final c in perkChoices)
          if (c.isUnlocked(this)) c,
      ];

  Map<String, dynamic> toJson() => {
        'name': name,
        'xp': xp,
        'discipline': disciplinePoints,
        'attributes': {for (final e in attributes.entries) e.key.name: e.value},
        'runes': runes,
        'weapon': weapon.toJson(),
        'weapons': [for (final w in weapons) w.toJson()],
        'amulets': amulets,
        'materials': materials,
        'perks': perks.toList(),
      };

  factory Character.fromJson(Map<String, dynamic> j) => Character(
        name: j['name'] as String,
        xp: j['xp'] as int,
        disciplinePoints: j['discipline'] as int,
        attributes: {
          for (final a in Attribute.values)
            a: (j['attributes'] as Map)[a.name] as int? ?? baseAttribute,
        },
        runes: j['runes'] as int,
        weapon: WeaponInstance.fromJson(j['weapon'] as Map<String, dynamic>),
        weapons: [
          for (final w in j['weapons'] as List)
            WeaponInstance.fromJson(w as Map<String, dynamic>),
        ],
        amulets: List<String>.from(j['amulets'] as List),
        materials: Map<String, int>.from(j['materials'] as Map),
        perks: Set<String>.from(j['perks'] as List),
      );
}

class Perk {
  const Perk(this.id, this.name, this.description);
  final String id;
  final String name;
  final String description;
}

class PerkChoice {
  const PerkChoice(this.requirements, this.options);

  final Map<Attribute, int> requirements;
  final List<Perk> options;

  bool isUnlocked(Character c) =>
      requirements.entries.every((e) => c.attr(e.key) >= e.value);
}

const perkChoices = [
  PerkChoice({Attribute.strength: 20}, [
    Perk('colossus_blow', 'Colpo del Colosso',
        'Ogni 5ª rep perfetta di fila è un colpo caricato'),
    Perk('iron_skin', 'Pelle di Ferro', '−10% danno fisico subito'),
  ]),
  PerkChoice({Attribute.faith: 20}, [
    Perk('blessing', 'Benedizione',
        'Ogni rep perfetta cura il 2% dei punti vita'),
    Perk('judgement', 'Giudizio',
        '+15% danno sacro contro nemici sotto metà vita'),
  ]),
  PerkChoice({Attribute.strength: 30, Attribute.faith: 30}, [
    Perk('crusader', 'Crociato',
        'Gli attacchi pesanti aggiungono un\'esplosione di luce sacra'),
  ]),
];
