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

enum CombatStatus { fighting, victory, fled }

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
    Random? random,
  })  : _random = random ?? Random(),
        expectedReps = max(3, (testReps * enemy.repFactor).round()) {
    enemyMaxHp = expectedReps.toDouble();
    enemyHp = enemyMaxHp;
    heroMaxHp = character.maxHp.toDouble();
    heroHp = heroMaxHp;
    _attackTimer = enemy.attackInterval;
  }

  static const double rampageMaxBonus = 0.20;
  static const double rampagePerRep = 0.1;
  static const double rampageDecayPerSecond = 0.25;

  final EnemyDef enemy;
  final Character character;
  final Stance stance;
  final Random _random;

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
        stance.penetrationMult;
    if (enemy.weakTo == weapon.def.style) power *= 1.25;
    if (enemy.strongAgainst == weapon.def.style) power *= 0.75;
    return power;
  }

  /// Quota di danno che passa la difesa (0.25..1).
  double get penetration => (attackPower / enemy.defense).clamp(0.25, 1.0);

  /// Bottino extra dal potere oltre la difesa del nemico (0..50%).
  double get lootBonus =>
      ((attackPower / enemy.defense - 1) * 0.5).clamp(0.0, 0.5);

  RepHit registerRep(RepQuality quality) {
    if (status != CombatStatus.fighting) {
      throw StateError('Il combattimento è finito');
    }
    reps++;
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

    _attackTimer -= dt;
    if (_attackTimer > 0) return 0;
    _attackTimer += enemy.attackInterval;

    var taken = enemy.attackDamage * stance.damageTakenMult;
    if (character.perks.contains('iron_skin')) taken *= 0.9;
    heroHp = max(0, heroHp - taken);
    if (heroHp <= 0) status = CombatStatus.fled;
    return taken;
  }

  /// Ricompense a fine combattimento. Se fuggi tieni gli XP delle rep fatte.
  CombatRewards rewards() {
    final xp = reps * 10 + perfectReps * 5;
    if (status != CombatStatus.victory) {
      return CombatRewards(xp: xp, runes: 0, materials: const {});
    }
    final bonus = 1 + lootBonus;
    final materials = <String, int>{
      for (final e in enemy.loot.entries) e.key: max(1, (e.value * bonus).round()),
    };
    String? rare;
    var rareChance = enemy.rareDropChance;
    if (enemy.isBeast) rareChance += _amulets.rareLoot;
    if (enemy.rareDrop != null && _random.nextDouble() < rareChance * bonus) {
      rare = enemy.rareDrop;
    }
    return CombatRewards(
      xp: xp,
      runes: (enemy.runeReward * bonus).round(),
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

  final int xp;
  final int runes;
  final Map<String, int> materials;
  final String? rareWeapon;
}
