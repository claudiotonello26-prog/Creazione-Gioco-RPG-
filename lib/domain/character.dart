import 'dart:math';

import '../core/i18n.dart';

import 'items.dart';

enum Attribute {
  vigor('Vigor', 'Punti vita: resisti di più ai colpi dei boss'),
  endurance('Endurance', 'Quanto dura il Rampage prima di calare'),
  strength('Strength', 'Attacco con armi pesanti, armature pesanti'),
  dexterity('Dexterity', 'Attacco con armi leggere, critici più forti'),
  faith('Faith', 'Danno sacro, cure e benedizioni'),
  intelligence('Intelligence', 'Magie ed effetti di stato');

  const Attribute(this.key, this._description);
  final String key;
  String get label => tr(key);
  final String _description;
  String get description => tr(_description);
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
    Map<ArmorSlot, String>? worn,
    Set<String>? armors,
    this.offhandId,
    Set<String>? offhands,
    this.capeId = 'pilgrim_cape',
    Set<String>? capes,
    this.neck,
    Appearance? look,
  })  : look = look ?? Appearance(),
        capes = capes ?? {'pilgrim_cape'},
        attributes = attributes ?? {for (final a in Attribute.values) a: baseAttribute},
        weapon = weapon ?? WeaponInstance(weaponId: 'pilgrim_blade'),
        amulets = amulets ?? [],
        materials = materials ?? {},
        weapons = weapons ?? [],
        perks = perks ?? {},
        worn = worn ?? {},
        armors = armors ?? {},
        offhands = offhands ?? {};

  static const int baseAttribute = 10;

  String name;
  int xp;

  /// Aspetto scelto alla creazione: si vede quando non c'è l'elmo o
  /// l'armatura.
  Appearance look;

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

  /// Pezzi d'armatura indossati (slot vuoto = solo la tunica) e armature
  /// possedute.
  final Map<ArmorSlot, String> worn;
  final Set<String> armors;

  ArmorDef? piece(ArmorSlot slot) => armorDefs[worn[slot]];

  /// Mano sinistra (scudo o seconda lama) e oggetti posseduti.
  String? offhandId;
  final Set<String> offhands;

  /// Mantello addosso (null: nessuno) e mantelli posseduti.
  String? capeId;
  final Set<String> capes;
  CapeDef? get cape => capeDefs[capeId];

  /// Amuleto al collo: un passivo in più oltre ai due dell'arma.
  String? neck;

  /// Tutti gli amuleti che contano: quelli dell'arma e quello al collo.
  Iterable<Amulet> get wornAmulets => [
        ...weapon.amulets,
        if (amuletDefs[neck] != null) amuletDefs[neck]!,
      ];

  /// La mano sinistra conta solo con un'arma a una mano.
  OffhandDef? get offhand => weapon.def.oneHanded ? offhandDefs[offhandId] : null;

  /// Quota di danno assorbita da armatura e scudo.
  double get damageReduction {
    var r = 0.0;
    for (final slot in ArmorSlot.values) {
      r += (piece(slot)?.reduction ?? 0) * slot.weight;
    }
    return r + (offhand?.reduction ?? 0) + (cape?.reduction ?? 0);
  }

  /// Danno in più dai pezzi d'armatura dei materiali di build: +5% ogni 10
  /// punti dell'attributo legato, in proporzione al pezzo.
  double get armorAttributeBonus {
    var b = 0.0;
    for (final slot in ArmorSlot.values) {
      final a = piece(slot)?.attribute;
      if (a != null) b += slot.weight * attr(a) / 10 * 0.05;
    }
    return b;
  }

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

  int get spentPoints => attributes.values.fold(0, (sum, v) => sum + (v - baseAttribute));

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

  void addMaterial(String id, int qty) => materials[id] = (materials[id] ?? 0) + qty;

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
        'worn': {for (final e in worn.entries) e.key.name: e.value},
        'armors': armors.toList(),
        'offhand': offhandId,
        'offhands': offhands.toList(),
        'cape': capeId,
        'capes': capes.toList(),
        'neck': neck,
        'look': look.toJson(),
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
          for (final w in j['weapons'] as List) WeaponInstance.fromJson(w as Map<String, dynamic>),
        ],
        amulets: List<String>.from(j['amulets'] as List),
        materials: Map<String, int>.from(j['materials'] as Map),
        perks: Set<String>.from(j['perks'] as List),
        worn: _readWorn(j),
        armors: Set<String>.from(j['armors'] as List? ?? const []),
        offhandId: j['offhand'] as String?,
        offhands: Set<String>.from(j['offhands'] as List? ?? const []),
        capeId: j.containsKey('capes') ? j['cape'] as String? : 'pilgrim_cape',
        capes: j['capes'] == null ? null : Set<String>.from(j['capes'] as List),
        neck: j['neck'] as String?,
        look: j['look'] == null ? null : Appearance.fromJson(j['look'] as Map<String, dynamic>),
      );
}

/// Prima dei pezzi separati c'era un'armatura intera: la si indossa tutta.
Map<ArmorSlot, String> _readWorn(Map<String, dynamic> j) {
  final w = j['worn'] as Map?;
  if (w != null) {
    final worn = {
      for (final slot in ArmorSlot.values)
        if (w[slot.name] is String) slot: w[slot.name] as String,
    };
    // Bracciali e stivali sono arrivati dopo: si prendono dalla stessa
    // armatura di corazza e gambali, così la protezione non cala.
    if (!w.containsKey(ArmorSlot.gloves.name) && worn[ArmorSlot.chest] != null) {
      worn[ArmorSlot.gloves] = worn[ArmorSlot.chest]!;
    }
    if (!w.containsKey(ArmorSlot.boots.name) && worn[ArmorSlot.legs] != null) {
      worn[ArmorSlot.boots] = worn[ArmorSlot.legs]!;
    }
    return worn;
  }
  final old = j['armor'] as String?;
  return old == null ? {} : {for (final slot in ArmorSlot.values) slot: old};
}

class Perk {
  const Perk(this.id, this._name, this._description);
  final String id;
  final String _name;
  final String _description;
  String get name => tr(_name);
  String get description => tr(_description);
}

class PerkChoice {
  const PerkChoice(this.requirements, this.options);

  final Map<Attribute, int> requirements;
  final List<Perk> options;

  bool isUnlocked(Character c) => requirements.entries.every((e) => c.attr(e.key) >= e.value);
}

const perkChoices = [
  PerkChoice({
    Attribute.strength: 20
  }, [
    Perk('colossus_blow', 'Colpo del Colosso', 'Ogni 5ª rep perfetta di fila è un colpo caricato'),
    Perk('iron_skin', 'Pelle di Ferro', '−10% danno fisico subito'),
  ]),
  PerkChoice({
    Attribute.faith: 20
  }, [
    Perk('blessing', 'Benedizione', 'Ogni rep perfetta cura il 2% dei punti vita'),
    Perk('judgement', 'Giudizio', '+15% danno sacro contro nemici sotto metà vita'),
  ]),
  PerkChoice({
    Attribute.strength: 30,
    Attribute.faith: 30
  }, [
    Perk('crusader', 'Crociato', 'Gli attacchi pesanti aggiungono un\'esplosione di luce sacra'),
  ]),
];

/// Aspetto del personaggio. Gli indici puntano alle tavolozze qui sotto.
class Appearance {
  Appearance({
    this.female = false,
    this.face = 0,
    this.skin = 1,
    this.hair = 0,
    this.eyes = 0,
    this.beard = true,
    this.beardColor = 0,
    this.shirt = 0,
    this.pants = 0,
  });

  bool female;

  /// 0 ovale, 1 squadrato, 2 tondo, 3 affilato.
  int face;
  int skin;
  int hair;
  int eyes;
  bool beard;
  int beardColor;
  int shirt;
  int pants;

  static const int faces = 4;
  static const List<int> skinTones = [0xFFF1D3B5, 0xFFD9AE8A, 0xFFB07D57, 0xFF7A4E31];
  static const List<int> hairColors = [
    0xFF2B1D14,
    0xFF5A3A22,
    0xFF9A6A3A,
    0xFFD6B26A,
    0xFF8E2E1E,
    0xFFB9B4AC,
  ];
  static const List<int> eyeColors = [0xFF4A2E1A, 0xFF3F6E9E, 0xFF4E7A45, 0xFF7A7F86];
  static const List<int> clothColors = [
    0xFF6B5A44,
    0xFF4A1612,
    0xFF2F3E4E,
    0xFF3D4A2C,
    0xFF5B4A6E,
    0xFFB9A98A,
  ];

  /// Barba solo per i personaggi maschili che la vogliono.
  bool get hasBeard => !female && beard;

  Map<String, dynamic> toJson() => {
        'f': female,
        'face': face,
        'skin': skin,
        'hair': hair,
        'eyes': eyes,
        'beard': beard,
        'bc': beardColor,
        'shirt': shirt,
        'pants': pants,
      };

  factory Appearance.fromJson(Map<String, dynamic> j) => Appearance(
        female: j['f'] as bool? ?? false,
        face: j['face'] as int? ?? 0,
        skin: j['skin'] as int? ?? 1,
        hair: j['hair'] as int? ?? 0,
        eyes: j['eyes'] as int? ?? 0,
        beard: j['beard'] as bool? ?? true,
        beardColor: j['bc'] as int? ?? 0,
        shirt: j['shirt'] as int? ?? 0,
        pants: j['pants'] as int? ?? 0,
      );
}
