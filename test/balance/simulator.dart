// Simulatore di bilanciamento: giocatori finti che usano il GameState vero,
// giorno dopo giorno, come farebbe una persona con l'app. Nessuna parte del
// gioco è copiata qui: combattimenti, bottino, fatica, forgia e passi passano
// tutti dal codice dell'app, così ogni modifica alle regole si vede subito nei
// numeri.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/hunting.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:iron_oath/domain/routine.dart';
import 'package:iron_oath/domain/skills.dart';

/// Come si allena un giocatore simulato.
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.label,
    required this.testReps,
    required this.secondsPerRep,
    required this.pPerfect,
    required this.pGood,
    required this.daysPerWeek,
    required this.repsPerSession,
    required this.stepsPerDay,
    this.build = Attribute.dexterity,
    this.varied = true,
    this.stretching = true,
    this.hunts = true,
  });

  final String id;
  final String label;

  /// Rep al test iniziale, uguali per tutti gli esercizi base.
  final int testReps;

  /// Ritmo medio: secondi fra una rep e l'altra.
  final double secondsPerRep;

  /// Probabilità di rep perfetta e buona (il resto è scarsa).
  final double pPerfect;
  final double pGood;

  final int daysPerWeek;

  /// Rep che fa in un giorno di allenamento, in tutto.
  final int repsPerSession;
  final int stepsPerDay;
  final Attribute build;

  /// false = fa sempre e solo push-up (il giocatore che cerca la scorciatoia).
  final bool varied;
  final bool stretching;

  /// Con le rep che avanzano va a caccia infinita.
  final bool hunts;
}

/// I giocatori tipo. Il «medio» è quello su cui si tarano le soglie.
const List<PlayerProfile> standardProfiles = [
  PlayerProfile(
    id: 'principiante',
    label: 'Principiante (test 8, lento, 3 giorni)',
    testReps: 8,
    secondsPerRep: 2.8,
    pPerfect: 0.35,
    pGood: 0.4,
    daysPerWeek: 3,
    repsPerSession: 80,
    stepsPerDay: 4000,
    build: Attribute.strength,
  ),
  PlayerProfile(
    id: 'medio',
    label: 'Medio (test 20, 3 giorni, 8.000 passi)',
    testReps: 20,
    secondsPerRep: 2.2,
    pPerfect: 0.55,
    pGood: 0.35,
    daysPerWeek: 3,
    repsPerSession: 150,
    stepsPerDay: 8000,
  ),
  PlayerProfile(
    id: 'costante',
    label: 'Costante (test 20, 5 giorni, 10.000 passi)',
    testReps: 20,
    secondsPerRep: 2.0,
    pPerfect: 0.6,
    pGood: 0.3,
    daysPerWeek: 5,
    repsPerSession: 200,
    stepsPerDay: 10000,
    build: Attribute.faith,
  ),
  PlayerProfile(
    id: 'atleta',
    label: 'Atleta (test 40, 6 giorni, 12.000 passi)',
    testReps: 40,
    secondsPerRep: 1.6,
    pPerfect: 0.75,
    pGood: 0.2,
    daysPerWeek: 6,
    repsPerSession: 350,
    stepsPerDay: 12000,
    build: Attribute.intelligence,
  ),
  PlayerProfile(
    id: 'furbo',
    label: 'Furbo (solo push-up, forma sporca)',
    testReps: 20,
    secondsPerRep: 2.0,
    pPerfect: 0.2,
    pGood: 0.3,
    daysPerWeek: 5,
    repsPerSession: 200,
    stepsPerDay: 3000,
    varied: false,
    stretching: false,
  ),
];

/// Una foto della partita alla fine di un giorno.
class DaySnapshot {
  DaySnapshot({
    required this.day,
    required this.level,
    required this.runes,
    required this.attack,
    required this.defense,
    required this.maxHp,
    required this.weapon,
    required this.armor,
    required this.reps,
    required this.effort,
    required this.runesEarned,
    required this.lootValue,
    required this.wins,
    required this.deaths,
    required this.bestTier,
  });

  final int day;
  final int level;
  final int runes;
  final int attack;
  final double defense;
  final int maxHp;
  final String weapon;
  final String armor;

  /// Rep fatte oggi e sforzo (rep × difficoltà della versione).
  final int reps;
  final double effort;

  /// Rune guadagnate oggi e valore al Mercante dei materiali presi.
  final int runesEarned;
  final int lootValue;
  final int wins;
  final int deaths;

  /// Gradino più alto battuto finora.
  final int bestTier;
}

/// Un combattimento simulato.
class FightLog {
  FightLog(this.enemy, this.move, this.wave, this.status, this.reps, this.seconds, this.runes,
      this.lootValue, this.fatigue);
  final String enemy;
  final String move;
  final int wave;
  final CombatStatus status;
  final int reps;
  final double seconds;
  final int runes;
  final int lootValue;
  final double fatigue;
}

/// Una spedizione: giorno in cui il livello la consiglia e giorno in cui è
/// stata finita la prima volta.
class ExpeditionLog {
  int? unlockedDay;
  int? clearedDay;

  /// Ultimo giorno in cui era la spedizione scelta.
  int? lastDay;
  int attempts = 0;
  int deaths = 0;
}

/// Valore al Mercante di un bottino.
int lootValueOf(Map<String, int> m) {
  var v = 0;
  m.forEach((k, n) => v += sellPrice(k) * n);
  return v;
}

/// Un giocatore simulato che usa il GameState vero.
class SimPlayer {
  SimPlayer(this.profile, {int seed = 1})
      : random = Random(seed ^ profile.id.hashCode),
        _start = DateTime(2026, 1, 5, 18) {
    state = GameState(clock: () => _start.add(Duration(days: _day)));
  }

  final PlayerProfile profile;
  final Random random;
  final DateTime _start;
  late final GameState state;
  int _day = 0;

  final List<DaySnapshot> days = [];
  final List<FightLog> fights = [];
  final Map<String, ExpeditionLog> expeditionLog = {
    for (final e in expeditions) e.id: ExpeditionLog(),
  };

  int bestTier = 0;

  /// Da dove arrivano XP e rune, per fonte (combattimento, forziere, quest...).
  final Map<String, int> xpBy = {};
  final Map<String, int> runesBy = {};

  T _track<T>(String source, T Function() f) {
    final xp = c.xp, runes = c.runes;
    final out = f();
    xpBy[source] = (xpBy[source] ?? 0) + c.xp - xp;
    if (c.runes > runes) runesBy[source] = (runesBy[source] ?? 0) + c.runes - runes;
    return out;
  }

  // Contatori del giorno.
  int _reps = 0;
  double _effort = 0;
  int _runes = 0;
  int _loot = 0;
  int _wins = 0;
  int _deaths = 0;
  int _budget = 0;

  /// Nemici che oggi hanno già ucciso il giocatore: non li riprova.
  final Set<String> _beatenBy = {};

  Character get c => state.character;

  // ---------------------------------------------------------------- avvio

  void start() {
    state.saveQuestionnaire(
      goal: 'Restare in forma',
      daysPerWeek: profile.daysPerWeek,
      limitations: '',
      mode: PlayMode.path,
    );
    state.setOath(profile.build);
    state.completeTest({
      for (final id in baseExercises) id: TestResult(reps: profile.testReps, variantLevel: 0),
    });
  }

  bool _isTrainingDay(int day) {
    // Giorni sparsi nella settimana: 3 giorni = lun, mer, ven.
    final dow = day % 7;
    const plans = {
      2: [0, 3],
      3: [0, 2, 4],
      4: [0, 1, 3, 4],
      5: [0, 1, 2, 3, 4],
      6: [0, 1, 2, 3, 4, 5],
      7: [0, 1, 2, 3, 4, 5, 6],
    };
    return plans[profile.daysPerWeek.clamp(2, 7)]!.contains(dow);
  }

  void run(int totalDays) {
    start();
    for (var d = 0; d < totalDays; d++) {
      _day = d;
      simulateDay();
    }
  }

  // ---------------------------------------------------------------- giorno

  void simulateDay() {
    state.refreshDay();
    _reps = 0;
    _effort = 0;
    _runes = 0;
    _loot = 0;
    _wins = 0;
    _deaths = 0;
    _beatenBy.clear();
    final runesBefore = c.runes;

    _walk();
    if (_isTrainingDay(_day)) {
      _budget = profile.repsPerSession;
      _quest();
      if (profile.stretching) _track('stretching', state.completeStretching);
      for (final g in _groupsToday()) {
        _expedition(g);
      }
      _farm();
    }
    _manage();

    days.add(DaySnapshot(
      day: _day,
      level: c.level,
      runes: c.runes,
      attack: state.attackValue,
      defense: state.defenseValue,
      maxHp: c.maxHp,
      weapon: c.weapon.displayName,
      armor: c.worn[ArmorSlot.chest] ?? '-',
      reps: _reps,
      effort: _effort,
      runesEarned: max(0, c.runes - runesBefore) + _spentToday,
      lootValue: _loot,
      wins: _wins,
      deaths: _deaths,
      bestTier: bestTier,
    ));
    spentRunes += _spentToday;
    _spentToday = 0;
  }

  int _spentToday = 0;

  /// Rune spese in tutto (Mercante, amuleti).
  int spentRunes = 0;

  /// Il furbo fa solo spinta; gli altri ruotano i gruppi.
  List<MuscleGroup> _groupsToday() {
    if (!profile.varied) return [MuscleGroup.push];
    const rota = [MuscleGroup.push, MuscleGroup.legs, MuscleGroup.core, MuscleGroup.cardio];
    final i = days.length;
    return [rota[i % 4], if (profile.stretching) MuscleGroup.stretching];
  }

  void _walk() {
    if (profile.stepsPerDay <= 0) return;
    final steps = (profile.stepsPerDay * (0.7 + random.nextDouble() * 0.6)).round();
    _track('passi', () => state.claimStepMilestones(steps));
    state.setGatherTarget(_gatherChoice());
    final before = Map.of(c.materials);
    state.claimSteps(steps);
    final gained = <String, int>{
      for (final e in c.materials.entries)
        if (e.value > (before[e.key] ?? 0)) e.key: e.value - (before[e.key] ?? 0),
    };
    _loot += lootValueOf(gained);
  }

  /// Cosa raccogliere: la materia prima che manca di più alla prossima
  /// forgia, se no legno e minerale a turno.
  String _gatherChoice() {
    final want = _missingRaw();
    for (final id in want) {
      final r = resources.where((r) => r.id == id).firstOrNull;
      if (r != null && state.canGather(r)) return id;
    }
    final options = [
      for (final r in resources)
        if (state.canGather(r)) r.id,
    ];
    return options[_day % options.length];
  }

  // -------------------------------------------------------- combattimento

  /// Un combattimento con il motore vero. Ritorna il motore a fine scontro.
  CombatEngine fight(
    EnemyDef enemy,
    Move move, {
    int wave = 0,
    bool apply = true,
    double? pace,
  }) {
    final engine = _engine(enemy, move, wave);
    final secPerRep = pace ?? profile.secondsPerRep;
    final qualities = <RepQuality>[];
    var t = 0.0;
    // 3 secondi di preparazione come nel gioco: il nemico non attacca.
    var nextRep = secPerRep * (0.8 + random.nextDouble() * 0.4);
    while (engine.status == CombatStatus.fighting && t < 600) {
      const dt = 0.1;
      t += dt;
      engine.tick(dt);
      if (engine.status != CombatStatus.fighting) break;
      if (t >= nextRep) {
        final q = _quality();
        qualities.add(q);
        engine.registerRep(q);
        // Con la stanchezza del giorno il ritmo cala un po'.
        final tired = 1 + min(0.25, (_reps + qualities.length) / 1200);
        nextRep = t + secPerRep * tired * (0.8 + random.nextDouble() * 0.4);
      }
    }
    if (!apply) return engine;

    final rewards = engine.rewards();
    final victory = engine.status == CombatStatus.victory;
    final (_, granted, fatigue) = _track(
        'combattimento',
        () => state.applyCombatRewards(
              rewards,
              move.trackAs,
              qualities,
              victory: victory,
              random: random,
            ));
    _reps += qualities.length;
    _budget -= qualities.length;
    _effort += qualities.length * move.difficulty;
    _runes += granted.runes;
    final lv = lootValueOf(granted.materials) + granted.runes;
    _loot += lootValueOf(granted.materials);
    if (victory) {
      _wins++;
      bestTier = max(bestTier, enemy.tier);
    } else {
      _deaths++;
      _beatenBy.add(enemy.id);
    }
    fights.add(FightLog(enemy.id, move.nameIt, wave, engine.status, qualities.length, t,
        granted.runes, lv, fatigue));
    return engine;
  }

  CombatEngine _engine(EnemyDef enemy, Move move, int wave) => CombatEngine(
        enemy: enemy,
        character: c,
        // Come nella schermata di combattimento.
        testReps: max(3, (state.testRepsFor(move.trackAs) / move.difficulty).round()),
        wave: wave,
        difficulty: move.difficulty,
        attackLevel: state.attackLevel,
        defenseLevel: state.defenseLevel,
        random: random,
      );

  RepQuality _quality() {
    final r = random.nextDouble();
    if (r < profile.pPerfect) return RepQuality.perfect;
    if (r < profile.pPerfect + profile.pGood) return RepQuality.good;
    return RepQuality.poor;
  }

  /// Prova a vuoto, con il ritmo del giocatore: vincerebbe?
  bool canBeat(EnemyDef enemy, Move move, {int wave = 0}) {
    var wins = 0;
    for (var i = 0; i < 3; i++) {
      final e = fight(enemy, move, wave: wave, apply: false);
      if (e.status == CombatStatus.victory) wins++;
    }
    return wins >= 2;
  }

  int _expectedReps(EnemyDef enemy, Move move) =>
      (_engine(enemy, move, 0).expectedReps / 0.85).ceil();

  /// La versione che il giocatore sceglie: quella che conta il suo esercizio
  /// del giorno, se no la prima che non è una tenuta.
  Move? _moveFor(EnemyDef enemy, {ExerciseId? prefer}) {
    final moves = enemy.moves.where((m) => !m.hold).toList();
    if (moves.isEmpty) return null;
    if (prefer != null) {
      final m = moves.where((m) => m.trackAs == prefer).firstOrNull;
      if (m != null) return m;
    }
    if (!profile.varied) {
      final m = moves.where((m) => m.trackAs == ExerciseId.pushUp).firstOrNull;
      if (m != null) return m;
      return null;
    }
    return moves.first;
  }

  // ---------------------------------------------------------------- quest

  void _quest() {
    final exercisesToday = profile.varied ? baseExercises : [ExerciseId.pushUp];
    for (final id in exercisesToday) {
      final item = state.quest.where((q) => q.exercise == id).firstOrNull;
      if (item == null) continue;
      var guard = 0;
      while (state.questDoneFor(id) < item.target && _budget > 0 && guard++ < 10) {
        final foe = questFoe(id, c.level);
        if (foe == null) break;
        final e = fight(foe.$1, foe.$2);
        if (e.status != CombatStatus.victory) break;
      }
    }
  }

  // ------------------------------------------------------------ spedizioni

  void _expedition(MuscleGroup g) {
    final list = expeditionsOf(g);
    // La più alta consigliata al livello, se no la prima.
    final open = list.where((e) => e.level <= c.level).toList();
    final e = open.isEmpty ? list.first : open.last;
    final log = expeditionLog[e.id]!;
    if (c.level >= e.level) log.unlockedDay ??= _day;
    log.lastDay = _day;
    if (state.expeditionProgress(e.id) >= GameState.mapChest) return;
    log.attempts++;
    if (g == MuscleGroup.stretching) {
      for (var i = state.expeditionProgress(e.id); i < 4; i++) {
        final step = e.steps[i];
        final loot = _track('stretching',
            () => state.holdVictory(step.monster, seconds: 30 + 10 * step.tier));
        _loot += lootValueOf(loot.materials);
        state.completeExpeditionStep(e.id, i);
      }
    } else {
      for (var i = state.expeditionProgress(e.id); i < 4; i++) {
        final step = e.steps[i];
        final enemy = step.monster;
        if (_budget < _expectedReps(enemy, step.move)) return;
        final r = fight(enemy, step.move);
        if (r.status != CombatStatus.victory) {
          log.deaths++;
          return;
        }
        state.expeditionKill(enemy);
        state.completeExpeditionStep(e.id, i);
      }
    }
    // Il boss è un circuito: si completa sempre.
    final weighted = false;
    final bossLoot = _track('boss', () => state.expeditionBossDown(e, weighted: weighted));
    _loot += lootValueOf(bossLoot);
    final useKey = state.expeditionKeys > 0 && state.useExpeditionKey();
    final before = c.runes;
    final chest =
        _track('forziere', () => state.openChest(e, multiplier: useKey ? 2 : 1, random: random));
    _runes += c.runes - before;
    for (final (id, n, _) in chest) {
      if (id != 'runes') _loot += sellPrice(id) * n;
    }
    log.clearedDay ??= _day;
  }

  // ------------------------------------------------------------ farmare

  /// Le rep che avanzano: caccia infinita al mostro più forte che regge, o
  /// il nemico che lascia il materiale che manca.
  void _farm() {
    var guard = 0;
    while (_budget > 5 && guard++ < 40) {
      final target = _farmTarget();
      if (target == null) return;
      final (enemy, move) = target;
      if (profile.hunts) {
        // Caccia infinita: ondate finché regge o finiscono le rep.
        var wave = 0;
        while (_budget > 0) {
          final r = fight(enemy, move, wave: wave);
          if (r.status != CombatStatus.victory) break;
          wave++;
          state.recordHuntWave(wave);
        }
      } else {
        final r = fight(enemy, move);
        if (r.status != CombatStatus.victory) continue;
      }
    }
  }

  (EnemyDef, Move)? _farmTarget() {
    final groups = _groupsToday();
    final missing = _missingAll().toSet();
    (EnemyDef, Move)? best;
    var bestScore = -1.0;
    for (final e in bestiary) {
      if (e.isBoss || _beatenBy.contains(e.id)) continue;
      if (profile.varied && !groups.contains(e.group) && e.group != MuscleGroup.legs) continue;
      final m = _moveFor(e);
      if (m == null) continue;
      if (e.level > c.level + 3) continue;
      if (_budget < _expectedReps(e, m)) continue;
      // Più alto il gradino e il livello, meglio; molto meglio se lascia ciò che manca.
      var score = e.tier * 10.0 + e.level * 0.5;
      if (e.loot.keys.any(missing.contains)) score += 25;
      if (score <= bestScore) continue;
      if (!canBeat(e, m)) continue;
      best = (e, m);
      bestScore = score;
    }
    return best;
  }

  // ------------------------------------------------------- gestione

  /// Dopo l'allenamento: attributi, perk, forgia, potenziamenti, amuleti.
  void _manage() {
    // Attributi: due nella build, uno in Vigore.
    var i = 0;
    while (c.availablePoints > 0) {
      state.raiseAttribute(i % 3 == 2 ? Attribute.vigor : profile.build);
      i++;
    }
    for (final choice in c.unlockedPerkChoices) {
      state.choosePerk(choice, choice.options.first);
    }

    // Attrezzi per raccogliere.
    for (final t in ['ash_pickaxe', 'iron_axe', 'iron_pickaxe', 'steel_axe', 'steel_pickaxe']) {
      if (!state.hasTool(t)) _obtain(t, 1);
    }

    // Armatura: la migliore che si può indossare.
    final armor = _targetArmor();
    if (armor != null && _obtainAll(armor.recipe)) state.craftArmor(armor);

    // Arma: la migliore per la build che si può impugnare.
    final weapon = _targetWeapon();
    if (weapon != null && _obtainAll(weapon.recipe) && state.craftWeapon(weapon)) {
      final w = c.weapons.lastWhere((w) => w.weaponId == weapon.id);
      if (w.attackRating(c) > c.weapon.attackRating(c)) state.equip(w);
    }

    _practice();

    // Potenziamenti dell'arma impugnata.
    var guard = 0;
    while (guard++ < 10) {
      final stone = c.weapon.nextStone;
      if (stone == null) break;
      if (!_obtain(stone, c.weapon.nextStoneCost)) break;
      if (!state.upgradeWeapon(c.weapon)) break;
    }

    // Amuleti passivi con le rune che avanzano.
    for (final (id, slot) in [('oath_sigil', 1), ('fang_charm', 2)]) {
      if (c.weapon.sockets[slot] != null) continue;
      if (state.ownsAmulet(id)) {
        state.socketAmulet(c.weapon, slot, id);
        continue;
      }
      final price = amuletPrices[id]!;
      if (c.runes >= price + 300) {
        state.buyAmulet(id, price);
        _spentToday += price;
        state.socketAmulet(c.weapon, slot, id);
      }
    }
  }

  /// Come un giocatore vero: con i materiali che avanzano lavora alle
  /// postazioni per alzarne il livello, e vende le armi fatte per esercizio.
  void _practice() {
    bool spare(Map<String, int> m) => m.entries.every((e) => (c.materials[e.key] ?? 0) >= e.value * 2);
    for (final station in [Station.carpentry, Station.furnace, Station.anvil]) {
      var guard = 0;
      while (guard++ < 30) {
        final level = state.stationLevel(station);
        final mats = materialRecipes
            .where((r) => r.station == station && !r.tool && r.level <= level && spare(r.inputs))
            .toList()
          ..sort((a, b) => b.level - a.level);
        if (mats.isNotEmpty && state.craftMaterial(mats.first)) continue;
        final weapons = weaponDefs.values
            .where((w) =>
                w.station == station && w.recipe.isNotEmpty && w.craftLevel <= level && spare(w.recipe))
            .toList()
          ..sort((a, b) => b.craftLevel - a.craftLevel);
        if (weapons.isNotEmpty && state.craftWeapon(weapons.first)) {
          state.sellWeapon(c.weapons.lastWhere((w) => w.weaponId == weapons.first.id));
          continue;
        }
        break;
      }
    }
  }

  ArmorDef? _targetArmor() {
    final current = c.piece(ArmorSlot.chest)?.reduction ?? 0;
    ArmorDef? best;
    for (final a in armorDefs.values) {
      if (c.armors.contains(a.id) || a.reduction <= current) continue;
      if (!state.canWear(a.id) || state.stationLevel(Station.anvil) < a.craftLevel) continue;
      if (a.attribute != null && a.attribute != profile.build) continue;
      if (best == null || a.reduction > best.reduction) best = a;
    }
    return best;
  }

  WeaponDef? _targetWeapon() {
    final current = c.weapon.attackRating(c);
    WeaponDef? best;
    var bestRating = current * 1.05;
    for (final w in weaponDefs.values) {
      if (w.recipe.isEmpty || !state.canWield(w)) continue;
      if (state.stationLevel(w.station) < w.craftLevel) continue;
      if (c.weapons.any((x) => x.weaponId == w.id) || c.weapon.weaponId == w.id) continue;
      final r = WeaponInstance(weaponId: w.id).attackRating(c);
      if (r > bestRating) {
        best = w;
        bestRating = r;
      }
    }
    return best;
  }

  /// Materiali che mancano alla prossima arma, armatura e pietra.
  List<String> _missingAll() {
    final need = <String, int>{};
    void add(Map<String, int> m) => m.forEach((k, v) => need[k] = (need[k] ?? 0) + v);
    final a = _targetArmor();
    if (a != null) add(a.recipe);
    final w = _targetWeapon();
    if (w != null) add(w.recipe);
    final s = c.weapon.nextStone;
    if (s != null) add({s: c.weapon.nextStoneCost});
    final out = <String>[];
    void expand(String id, int qty, int depth) {
      final have = c.materials[id] ?? 0;
      if (have >= qty || depth > 4) return;
      final r = materialRecipes.where((r) => r.output == id).firstOrNull;
      if (r == null || state.stationLevel(r.station) < r.level) {
        out.add(id);
        return;
      }
      final crafts = ((qty - have) / r.qty).ceil();
      r.inputs.forEach((k, v) => expand(k, v * crafts, depth + 1));
    }

    need.forEach((k, v) => expand(k, v, 0));
    return out;
  }

  List<String> _missingRaw() => [
        for (final id in _missingAll())
          if (resources.any((r) => r.id == id)) id,
      ];

  bool _obtainAll(Map<String, int> m) {
    for (final e in m.entries) {
      if (!_obtain(e.key, e.value)) return false;
    }
    return true;
  }

  /// Ottiene [qty] di [id] forgiandolo dai materiali che ha, o comprandolo
  /// dal Mercante se costa poco rispetto alle rune.
  bool _obtain(String id, int qty, [int depth = 0]) {
    if ((c.materials[id] ?? 0) >= qty) return true;
    if (depth > 4) return false;
    final r = materialRecipes.where((r) => r.output == id).firstOrNull;
    if (r != null && state.stationLevel(r.station) >= r.level) {
      var guard = 0;
      while ((c.materials[id] ?? 0) < qty && guard++ < 50) {
        for (final e in r.inputs.entries) {
          if (!_obtain(e.key, e.value, depth + 1)) return false;
        }
        if (!state.craftMaterial(r)) return false;
      }
      return (c.materials[id] ?? 0) >= qty;
    }
    // Il Mercante: compra solo se costa meno di un terzo delle rune.
    final missing = qty - (c.materials[id] ?? 0);
    final cost = buyPrice(id) * missing;
    if (merchantStock.contains(id) && cost > 0 && cost * 3 <= c.runes) {
      state.buyMaterial(id, missing);
      _spentToday += cost;
      return true;
    }
    return false;
  }
}

/// Esegue tutti i profili per [days] giorni con [seeds] semi diversi.
Map<String, List<SimPlayer>> runProfiles(List<PlayerProfile> profiles,
    {required int days, int seeds = 1}) {
  return {
    for (final p in profiles)
      p.id: [
        for (var s = 0; s < seeds; s++) SimPlayer(p, seed: 1000 + s)..run(days),
      ],
  };
}
