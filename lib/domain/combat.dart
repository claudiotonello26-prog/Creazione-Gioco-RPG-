import 'dart:math';

import 'character.dart';
import 'enemies.dart';
import 'items.dart';

/// Qualità di una rep valida. Le rep scorrette non arrivano mai qui: il
/// contatore non le conta.
enum RepQuality {
  perfect(1.0, 'Perfetta'),
  good(0.85, 'Buona'),
  poor(0.6, 'Scarsa');

  const RepQuality(this.multiplier, this.label);
  final double multiplier;
  final String label;
}

enum Stance {
  aggressive('Aggressiva', 1.15, 1.15),
  balanced('Bilanciata', 1.0, 1.0),
  defensive('Difensiva', 0.9, 0.75);

  const Stance(this.label, this.penetrationMult, this.damageTakenMult);
  final String label;
  final double penetrationMult;
  final double damageTakenMult;
}

/// fled = fuga volontaria; defeated = vita a zero (YOU DIED).
enum CombatStatus { fighting, victory, defeated, fled }

class RepHit {
  const RepHit({
    required this.damage,
    required this.quality,
    required this.critical,
    required this.charged,
    required this.bounced,
  });

  final double damage;
  final RepQuality quality;
  final bool critical;

  /// Colpo caricato del perk Colpo del Colosso.
  final bool charged;

  /// Il potere d'attacco è sotto la difesa del nemico.
  final bool bounced;
}

/// Un combattimento: la vita del nemico è calibrata sul test del giocatore,
/// la build decide se si sopravvive abbastanza da finire le rep.
///
/// Regola d'oro: la build non riduce mai le rep sotto quelle previste. Il
/// potere oltre la difesa del nemico diventa bottino extra, non danno.
class CombatEngine {
  CombatEngine({
    required this.enemy,
    required this.character,
    required int testReps,
    this.stance = Stance.balanced,
    this.wave = 0,
    this.attackLevel = 1,
    this.defenseLevel = 1,
    Random? random,
  })  : _random = random ?? Random(),
        expectedReps = max(3, (testReps * enemy.repFactor).round()) {
    enemyMaxHp = expectedReps * (1 + waveHpStep * wave);
    enemyHp = enemyMaxHp;
    heroMaxHp = character.maxHp.toDouble();
    heroHp = heroMaxHp;
    _attackTimer = enemy.attackInterval;
    // Il nemico è tarato sull'eroe base (vita 140): chi tiene il ritmo di una
    // rep ogni ~2 secondi vince con poco margine; chi rallenta, sbaglia la
    // forma o ha una build debole muore. Il Vigore dà tempo in più.
    final secondsToKill = expectedReps * secondsPerRep * enemy.pressure;
    hitDamage = baseHeroHp * enemy.attackInterval / secondsToKill * (1 + waveDamageStep * wave);
  }

  /// Ritmo di riferimento della taratura.
  static const double secondsPerRep = 2.2;
  static const double baseHeroHp = 140;

  /// Caccia infinita: ogni nemico abbattuto ne arriva uno più forte.
  static const double waveHpStep = 0.2;
  static const double waveDamageStep = 0.1;

  /// Dopo questa pausa senza rep il nemico si rimette in forze.
  static const double regenDelay = 3.0;
  static const double regenPerSecond = 0.03;

  static const double rampageMaxBonus = 0.20;
  static const double rampagePerRep = 0.1;
  static const double rampageDecayPerSecond = 0.25;

  final EnemyDef enemy;
  final Character character;
  final Stance stance;
  final int wave;
  final Random _random;

  /// Livelli di Attacco e Difesa, allenati dalla postura.
  final int attackLevel;
  final int defenseLevel;

  /// +2% di danno per livello di Attacco.
  static double attackBonus(int level) => 0.02 * (level - 1);

  /// +0,5% di colpi assorbiti per livello di Difesa, fino al 30%.
  static double defenseBonus(int level) => min(0.3, 0.005 * (level - 1));

  /// Probabilità di un drop non comune e di uno raro per nemico abbattuto:
  /// in caccia infinita crescono del 35% a ondata.
  static const double uncommonBase = 0.08, rareBase = 0.015, dropGrowth = 1.35;
  double get dropMultiplier => pow(dropGrowth, wave).toDouble();
  double get uncommonChance => min(0.9, uncommonBase * dropMultiplier);
  double get rareChance => min(0.6, rareBase * dropMultiplier);
  static const List<String> uncommonDrops = ['holy_shard', 'forge_stone_2', 'moon_silver'];
  static const List<String> rareDrops = ['ancient_stone', 'somber_stone', 'star_ore'];

  /// Danno di ogni colpo del nemico, prima di postura e perk.
  late final double hitDamage;

  /// Rep previste con forma perfetta.
  final int expectedReps;

  late final double enemyMaxHp;
  late double enemyHp;
  late final double heroMaxHp;
  late double heroHp;

  /// 0..1, vale fino a +20% di danno.
  double rampage = 0;
  double _sinceLastRep = 0;
  late double _attackTimer;
  int _perfectStreak = 0;

  int reps = 0;
  int perfectReps = 0;
  double _qualitySum = 0;
  CombatStatus status = CombatStatus.fighting;

  double get attackTimerProgress => 1 - _attackTimer / enemy.attackInterval;

  AmuletEffect get _amulets {
    var holy = 0.0, heavy = 0.0, rare = 0.0, lowHp = 0.0;
    for (final id in character.amulets) {
      final a = amuletDefs[id]?.apply;
      if (a == null) continue;
      holy += a.holyDamage;
      heavy += a.heavyDamage;
      rare += a.rareLoot;
      lowHp += a.lowHpDamage;
    }
    return AmuletEffect(
        holyDamage: holy, heavyDamage: heavy, rareLoot: rare, lowHpDamage: lowHp);
  }

  /// Potere d'attacco effettivo contro questo nemico.
  double get attackPower {
    final weapon = character.weapon;
    final a = _amulets;
    var bonus = 0.0;
    if (weapon.def.damageType == DamageType.holy) bonus += a.holyDamage;
    if (weapon.def.heavy) bonus += a.heavyDamage;
    if (heroHp < heroMaxHp * 0.3) bonus += a.lowHpDamage;
    if (character.perks.contains('judgement') &&
        weapon.def.damageType == DamageType.holy &&
        enemyHp < enemyMaxHp / 2) {
      bonus += 0.15;
    }
    var power = weapon.attackRating(character, amuletBonus: bonus) *
        stance.penetrationMult *
        (1 + attackBonus(attackLevel));
    power *= 1 + (character.offhand?.damageBonus ?? 0) + character.armorAttributeBonus;
    if (enemy.weakTo == weapon.def.style) power *= 1.25;
    if (enemy.strongAgainst == weapon.def.style) power *= 0.75;
    return power;
  }

  /// Quota di danno che passa la difesa (0.25..1).
  double get penetration => (attackPower / enemy.defense).clamp(0.25, 1.0);

  /// Bottino extra dal potere oltre la difesa del nemico (0..25%): poco,
  /// perché farmare nemici deboli con un'arma enorme non deve convenire.
  double get lootBonus =>
      ((attackPower / enemy.defense - 1) * 0.25).clamp(0.0, 0.25);

  RepHit registerRep(RepQuality quality) {
    if (status != CombatStatus.fighting) {
      throw StateError('Il combattimento è finito');
    }
    reps++;
    _qualitySum += quality.multiplier;
    _sinceLastRep = 0;
    rampage = min(1.0, rampage + rampagePerRep);

    final critical = quality == RepQuality.perfect;
    if (critical) {
      perfectReps++;
      _perfectStreak++;
    } else {
      _perfectStreak = 0;
    }

    final charged = critical &&
        character.perks.contains('colossus_blow') &&
        _perfectStreak % 5 == 0;

    final bounced = attackPower < enemy.defense;
    var damage = quality.multiplier *
        penetration *
        (1 + rampage * rampageMaxBonus) *
        (charged ? 1.5 : 1.0);
    // Una rep valida fa sempre almeno un minimo di danno: il combattimento
    // non si blocca mai.
    damage = max(damage, 0.1);

    enemyHp = max(0, enemyHp - damage);

    if (critical && character.perks.contains('blessing')) {
      heroHp = min(heroMaxHp, heroHp + heroMaxHp * 0.02);
    }

    if (enemyHp <= 0) status = CombatStatus.victory;

    return RepHit(
      damage: damage,
      quality: quality,
      critical: critical,
      charged: charged,
      bounced: bounced,
    );
  }

  /// Avanza il tempo. Ritorna il danno subito in questo intervallo (0 se il
  /// nemico non ha attaccato).
  double tick(double dt) {
    if (status != CombatStatus.fighting) return 0;
    _sinceLastRep += dt;
    if (_sinceLastRep > character.rampageGrace) {
      rampage = max(0, rampage - rampageDecayPerSecond * dt);
    }
    if (_sinceLastRep > regenDelay) {
      enemyHp = min(enemyMaxHp, enemyHp + enemyMaxHp * regenPerSecond * dt);
    }

    _attackTimer -= dt;
    if (_attackTimer > 0) return 0;
    _attackTimer += enemy.attackInterval;

    var taken = hitDamage * stance.damageTakenMult;
    if (character.perks.contains('iron_skin')) taken *= 0.9;
    taken *= 1 - min(0.75, character.damageReduction + defenseBonus(defenseLevel));
    heroHp = max(0, heroHp - taken);
    if (heroHp <= 0) status = CombatStatus.defeated;
    return taken;
  }

  /// Sforzo richiesto rispetto a chi fa 20 rep al test: chi ha nemici da
  /// poche rep prende meno a uccisione, chi ne ha di lunghi di più. Così il
  /// bottino segue le rep fatte davvero, non il numero di nemici.
  double get effortFactor => (enemyMaxHp / (20 * enemy.repFactor)).clamp(0.5, 5.0);

  /// Qualità media delle rep (1 = tutte perfette, 0.6 = tutte scarse).
  double get averageQuality => reps == 0 ? 1.0 : _qualitySum / reps;

  /// Premio di rischio della caccia infinita, oltre alla vita in più che
  /// è già pagata da [effortFactor].
  double get waveBonus => 1 + waveRewardStep * wave;
  static const double waveRewardStep = 0.1;

  /// Ricompense a fine combattimento. Se fuggi o muori tieni gli XP delle rep
  /// fatte.
  CombatRewards rewards() {
    final xp = reps * 10 + perfectReps * 5;
    if (status != CombatStatus.victory) {
      return CombatRewards(xp: xp, runes: 0, materials: const {});
    }
    final pay = (1 + lootBonus) * effortFactor * averageQuality * waveBonus;
    final materials = <String, int>{
      for (final e in enemy.loot.entries) e.key: max(1, (e.value * pay).round()),
    };
    // Drop casuali: anche un nemico facile può lasciare qualcosa di buono,
    // e più resisti in caccia più è probabile.
    if (_random.nextDouble() < uncommonChance) {
      final id = uncommonDrops[_random.nextInt(uncommonDrops.length)];
      materials[id] = (materials[id] ?? 0) + 1;
    }
    if (_random.nextDouble() < rareChance) {
      final id = rareDrops[_random.nextInt(rareDrops.length)];
      materials[id] = (materials[id] ?? 0) + 1;
    }
    String? rare;
    var weaponChance = enemy.rareDropChance;
    if (enemy.isBeast) weaponChance += _amulets.rareLoot;
    if (enemy.rareDrop != null &&
        _random.nextDouble() < weaponChance * (1 + lootBonus) * dropMultiplier) {
      rare = enemy.rareDrop;
    }
    return CombatRewards(
      xp: xp,
      runes: (enemy.runeReward * pay).round(),
      materials: materials,
      rareWeapon: rare,
    );
  }
}

class CombatRewards {
  const CombatRewards({
    required this.xp,
    required this.runes,
    required this.materials,
    this.rareWeapon,
  });

  /// Stesse ricompense ridotte dalla fatica (rune e materiali, non XP né
  /// armi rare). L'arrotondamento è casuale così anche 0,3 di essenza
  /// vale qualcosa in media.
  CombatRewards scaled(double factor, Random random) {
    if (factor >= 1) return this;
    int r(num v) {
      final x = v * factor;
      return x.floor() + (random.nextDouble() < x - x.floor() ? 1 : 0);
    }

    return CombatRewards(
      xp: xp,
      runes: r(runes),
      materials: {
        for (final e in materials.entries)
          if (r(e.value) > 0) e.key: r(e.value),
      },
      rareWeapon: rareWeapon,
    );
  }

  final int xp;
  final int runes;
  final Map<String, int> materials;
  final String? rareWeapon;
}
