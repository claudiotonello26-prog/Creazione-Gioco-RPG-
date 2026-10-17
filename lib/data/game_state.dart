import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/character.dart';
import '../domain/combat.dart';
import '../domain/exercise.dart';
import '../domain/items.dart';
import '../domain/pvp.dart';
import '../domain/routine.dart';
import '../domain/walking.dart';

enum PlayMode {
  /// Come GymScape: combattimenti liberi, nessuna routine imposta.
  free('Libera'),

  /// Test iniziale, quest del giorno e progressione.
  path('Percorso');

  const PlayMode(this.label);
  final String label;
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Stato del giorno, azzerato a mezzanotte.
class DailyState {
  DailyState(this.day);

  final String day;
  final Map<ExerciseId, int> questDone = {};
  final Map<MuscleGroup, int> varietyUsed = {};
  bool stretchingDone = false;
  bool questRewarded = false;
  bool expeditionDone = false;
  int xpEarned = 0;
  bool goodForm = true;

  /// Passi di oggi già trasformati in materiali.
  int claimedSteps = 0;

  /// Rep fatte oggi in combattimento per gruppo muscolare (fatica).
  final Map<MuscleGroup, int> combatReps = {};

  Map<String, dynamic> toJson() => {
        'day': day,
        'quest': {for (final e in questDone.entries) e.key.name: e.value},
        'variety': {for (final e in varietyUsed.entries) e.key.name: e.value},
        'stretch': stretchingDone,
        'rewarded': questRewarded,
        'exp': expeditionDone,
        'xp': xpEarned,
        'good': goodForm,
        'steps': claimedSteps,
        'combat': {for (final e in combatReps.entries) e.key.name: e.value},
      };

  factory DailyState.fromJson(Map<String, dynamic> j) {
    final d = DailyState(j['day'] as String)
      ..stretchingDone = j['stretch'] as bool
      ..questRewarded = j['rewarded'] as bool
      ..expeditionDone = j['exp'] as bool
      ..xpEarned = j['xp'] as int
      ..goodForm = j['good'] as bool? ?? true
      ..claimedSteps = j['steps'] as int? ?? 0;
    (j['quest'] as Map).forEach(
        (k, v) => d.questDone[ExerciseId.values.byName(k as String)] = v as int);
    (j['variety'] as Map).forEach(
        (k, v) => d.varietyUsed[MuscleGroup.values.byName(k as String)] = v as int);
    ((j['combat'] as Map?) ?? const {}).forEach(
        (k, v) => d.combatReps[MuscleGroup.values.byName(k as String)] = v as int);
    return d;
  }
}

class ArenaRecord {
  ArenaRecord(this.exercise, this.opponent, this.won, this.day);
  final ExerciseId exercise;
  final String opponent;
  final int won; // 1 vittoria, 0 pareggio, -1 sconfitta
  final String day;

  Map<String, dynamic> toJson() =>
      {'ex': exercise.name, 'opp': opponent, 'won': won, 'day': day};
  factory ArenaRecord.fromJson(Map<String, dynamic> j) => ArenaRecord(
      ExerciseId.values.byName(j['ex'] as String),
      j['opp'] as String,
      j['won'] as int,
      j['day'] as String);
}

class GameState extends ChangeNotifier {
  GameState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    daily = DailyState(_dayKey(_clock()));
  }

  static const _storageKey = 'iron_oath_save_v1';

  /// Le prime rep del giorno di ogni gruppo valgono doppio.
  static const int varietyBonusReps = 20;
  static const int xpPerRep = 10;

  final DateTime Function() _clock;
  SharedPreferences? _prefs;

  bool healthAccepted = false;
  bool onboarded = false;
  PlayMode mode = PlayMode.path;
  String goal = 'Restare in forma';
  int daysPerWeek = 3;
  String limitations = '';

  /// false = inserimento manuale delle rep (emulatori, accessibilità).
  bool useCamera = true;

  /// Server dell'Arena live (Nakama), es. "arena.iron-oath.it" o "192.168.1.10:7350".
  String serverAddress = '';

  /// Identificativo anonimo del telefono per l'account online.
  String deviceId = '';

  Map<ExerciseId, TestResult> test = {};
  DateTime? testDate;
  Map<ExerciseId, int> records = {};

  /// Moltiplicatore della quest (+5% ogni 7 giorni buoni).
  double progression = 1.0;
  int goodDays = 0;

  /// Esercizi sostituiti dal giocatore per dolore dichiarato.
  Map<ExerciseId, String> substitutions = {};

  Character character = Character();
  int streak = 0;
  String? lastActiveDay;
  int expeditionKeys = 0;

  /// Gruppi allenati per giorno (ultimi 7 giorni) per la mappa del corpo.
  Map<String, Set<MuscleGroup>> trainedGroups = {};

  int arenaPoints = 1000;
  List<ArenaRecord> arenaHistory = [];

  /// Record di nemici abbattuti di fila nella Caccia infinita.
  int bestHuntWave = 0;

  late DailyState daily;

  // ---------------------------------------------------------------- persistenza

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Salvataggio non leggibile, si riparte: $e');
      }
    }
    if (deviceId.isEmpty) {
      deviceId = _newDeviceId();
      await _save();
    }
    _rollDay();
    notifyListeners();
  }

  static String _newDeviceId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  void setServerAddress(String value) {
    serverAddress = value.trim();
    _changed();
  }

  /// Punti stagione ufficiali arrivati dal server dopo un duello live.
  void applyLiveArena(ExerciseId id, String opponent, int outcome, int? serverPoints,
      List<RepQuality> reps) {
    if (serverPoints != null) {
      arenaPoints = serverPoints;
    } else {
      arenaPoints = (arenaPoints + rankDelta(outcome)).clamp(0, 99999);
    }
    arenaHistory.insert(0, ArenaRecord(id, '$opponent (live)', outcome.sign, today));
    if (arenaHistory.length > 30) arenaHistory.removeLast();
    addTraining(id, reps, countsForQuest: false);
  }

  Future<void> _save() async {
    await _prefs?.setString(_storageKey, jsonEncode(toJson()));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Map<String, dynamic> toJson() => {
        'health': healthAccepted,
        'onboarded': onboarded,
        'mode': mode.name,
        'goal': goal,
        'days': daysPerWeek,
        'limits': limitations,
        'camera': useCamera,
        'server': serverAddress,
        'device': deviceId,
        'test': {for (final e in test.entries) e.key.name: e.value.toJson()},
        'testDate': testDate?.toIso8601String(),
        'records': {for (final e in records.entries) e.key.name: e.value},
        'progression': progression,
        'goodDays': goodDays,
        'subs': {for (final e in substitutions.entries) e.key.name: e.value},
        'character': character.toJson(),
        'streak': streak,
        'lastDay': lastActiveDay,
        'keys': expeditionKeys,
        'trained': {
          for (final e in trainedGroups.entries)
            e.key: [for (final g in e.value) g.name],
        },
        'arena': arenaPoints,
        'arenaHistory': [for (final r in arenaHistory) r.toJson()],
        'daily': daily.toJson(),
        'bestHunt': bestHuntWave,
      };

  void _fromJson(Map<String, dynamic> j) {
    healthAccepted = j['health'] as bool;
    onboarded = j['onboarded'] as bool;
    mode = PlayMode.values.byName(j['mode'] as String);
    goal = j['goal'] as String;
    daysPerWeek = j['days'] as int;
    limitations = j['limits'] as String;
    useCamera = j['camera'] as bool? ?? true;
    serverAddress = j['server'] as String? ?? '';
    deviceId = j['device'] as String? ?? '';
    test = {
      for (final e in (j['test'] as Map).entries)
        ExerciseId.values.byName(e.key as String):
            TestResult.fromJson(e.value as Map<String, dynamic>),
    };
    testDate = j['testDate'] == null ? null : DateTime.parse(j['testDate'] as String);
    records = {
      for (final e in (j['records'] as Map).entries)
        ExerciseId.values.byName(e.key as String): e.value as int,
    };
    progression = (j['progression'] as num).toDouble();
    goodDays = j['goodDays'] as int;
    substitutions = {
      for (final e in (j['subs'] as Map).entries)
        ExerciseId.values.byName(e.key as String): e.value as String,
    };
    character = Character.fromJson(j['character'] as Map<String, dynamic>);
    streak = j['streak'] as int;
    lastActiveDay = j['lastDay'] as String?;
    expeditionKeys = j['keys'] as int;
    trainedGroups = {
      for (final e in (j['trained'] as Map).entries)
        e.key as String: {
          for (final g in e.value as List) MuscleGroup.values.byName(g as String),
        },
    };
    arenaPoints = j['arena'] as int;
    arenaHistory = [
      for (final r in j['arenaHistory'] as List)
        ArenaRecord.fromJson(r as Map<String, dynamic>),
    ];
    daily = DailyState.fromJson(j['daily'] as Map<String, dynamic>);
    bestHuntWave = j['bestHunt'] as int? ?? 0;
  }

  Future<void> resetAll() async {
    await _prefs?.remove(_storageKey);
    healthAccepted = false;
    onboarded = false;
    test = {};
    testDate = null;
    records = {};
    progression = 1.0;
    goodDays = 0;
    substitutions = {};
    character = Character();
    streak = 0;
    lastActiveDay = null;
    expeditionKeys = 0;
    trainedGroups = {};
    arenaPoints = 1000;
    arenaHistory = [];
    bestHuntWave = 0;
    daily = DailyState(_dayKey(_clock()));
    notifyListeners();
  }

  // ------------------------------------------------------------------- giorno

  String get today => _dayKey(_clock());

  /// Passa al giorno nuovo se serve. La streak si rompe se ieri non hai
  /// fatto nulla.
  void _rollDay() {
    if (daily.day == today) return;
    daily = DailyState(today);
    final yesterday = _dayKey(_clock().subtract(const Duration(days: 1)));
    if (lastActiveDay != null && lastActiveDay != today && lastActiveDay != yesterday) {
      streak = 0;
    }
    final cutoff = _clock().subtract(const Duration(days: 7));
    trainedGroups.removeWhere((k, _) => DateTime.parse(k).isBefore(cutoff));
  }

  void refreshDay() {
    final before = daily.day;
    _rollDay();
    if (before != daily.day) _changed();
  }

  void _markActive() {
    if (lastActiveDay == today) return;
    final yesterday = _dayKey(_clock().subtract(const Duration(days: 1)));
    streak = lastActiveDay == yesterday ? streak + 1 : 1;
    lastActiveDay = today;
  }

  // ------------------------------------------------------------- onboarding

  void acceptHealth() {
    healthAccepted = true;
    _changed();
  }

  void saveQuestionnaire({
    required String goal,
    required int daysPerWeek,
    required String limitations,
    required PlayMode mode,
  }) {
    this.goal = goal;
    this.daysPerWeek = daysPerWeek.clamp(2, 6);
    this.limitations = limitations;
    this.mode = mode;
    _changed();
  }

  void setUseCamera(bool value) {
    useCamera = value;
    _changed();
  }

  void setMode(PlayMode value) {
    mode = value;
    _changed();
  }

  void setCharacterName(String name) {
    character.name = name.trim().isEmpty ? 'Senza Nome' : name.trim();
    _changed();
  }

  void completeTest(Map<ExerciseId, TestResult> results) {
    test = Map.of(results);
    testDate = _clock();
    progression = 1.0;
    goodDays = 0;
    results.forEach((id, r) => _updateRecord(id, r.reps));
    onboarded = true;
    _changed();
  }

  bool get retestDue =>
      testDate != null &&
      _clock().difference(testDate!).inDays >= RoutineRules.retestEveryDays;

  // -------------------------------------------------------------- quest

  List<QuestItem> get quest =>
      RoutineRules.dailyQuest(test, progression: progression);

  int questDoneFor(ExerciseId id) => daily.questDone[id] ?? 0;

  double get questProgress {
    final q = quest;
    if (q.isEmpty) return 0;
    var done = 0.0;
    for (final item in q) {
      done += (questDoneFor(item.exercise) / item.target).clamp(0.0, 1.0);
    }
    return done / q.length;
  }

  bool get questComplete =>
      quest.isNotEmpty &&
      quest.every((i) => questDoneFor(i.exercise) >= i.target) &&
      daily.stretchingDone;

  /// XP di una serie di rep, con il Bonus Varietà del gruppo muscolare.
  int xpFor(ExerciseId id, List<RepQuality> reps, {bool inCombat = false}) {
    final group = exercises[id]!.group;
    final used = daily.varietyUsed[group] ?? 0;
    var xp = 0.0;
    for (var i = 0; i < reps.length; i++) {
      var repXp = xpPerRep * reps[i].multiplier;
      if (used + i < varietyBonusReps) repXp *= 2;
      if (!inCombat) repXp *= 0.5;
      xp += repXp;
    }
    return xp.round();
  }

  /// Registra rep fatte (quest, sfida o allenamento libero).
  int addTraining(ExerciseId id, List<RepQuality> reps,
      {bool countsForQuest = true, bool inCombat = false}) {
    if (reps.isEmpty) return 0;
    _rollDay();
    final group = exercises[id]!.group;
    final xp = xpFor(id, reps, inCombat: inCombat);
    daily.varietyUsed[group] = (daily.varietyUsed[group] ?? 0) + reps.length;
    if (countsForQuest) {
      daily.questDone[id] = questDoneFor(id) + reps.length;
    }
    final poor = reps.where((r) => r == RepQuality.poor).length;
    if (poor * 2 > reps.length) daily.goodForm = false;
    trainedGroups.putIfAbsent(today, () => {}).add(group);
    _gainXp(xp);
    _markActive();
    _checkQuestReward();
    _changed();
    return xp;
  }

  void completeStretching() {
    _rollDay();
    if (daily.stretchingDone) return;
    daily.stretchingDone = true;
    character.disciplinePoints += 1;
    trainedGroups.putIfAbsent(today, () => {}).add(MuscleGroup.mobility);
    _gainXp(40);
    _markActive();
    _checkQuestReward();
    _changed();
  }

  void _gainXp(int xp) {
    character.xp += xp;
    daily.xpEarned += xp;
  }

  void _checkQuestReward() {
    if (daily.questRewarded || !questComplete) return;
    daily.questRewarded = true;
    expeditionKeys += 1;
    character.runes += 100;
    _gainXp(150);
    if (daily.goodForm) {
      goodDays += 1;
      progression = RoutineRules.nextProgression(progression, goodDays);
    }
  }

  /// Sostituzione solo su richiesta per dolore dichiarato.
  void substitute(ExerciseId id, String replacement) {
    substitutions[id] = replacement;
    _changed();
  }

  /// Il giocatore accetta la versione più difficile proposta.
  void promoteVariant(ExerciseId id) {
    final t = test[id];
    if (t == null || t.variantLevel == 0) return;
    test[id] = TestResult(reps: (t.reps * 0.6).round(), variantLevel: t.variantLevel - 1);
    _changed();
  }

  void _updateRecord(ExerciseId id, int value) {
    if (value > (records[id] ?? 0)) records[id] = value;
  }

  void recordBest(ExerciseId id, int value) {
    _updateRecord(id, value);
    _changed();
  }

  int testRepsFor(ExerciseId id) => test[id]?.reps ?? 10;

  // ------------------------------------------------------------- combattimento

  /// Fatica: le prime [freshReps] rep di un gruppo al giorno pagano pieno,
  /// poi il bottino cala. Ripetere sempre lo stesso esercizio facile rende
  /// meno che cambiare gruppo; gli XP invece contano sempre (sono salute).
  static const int freshReps = 60;
  static const int tiredReps = 120;

  static double fatigueAt(int repsBefore) =>
      repsBefore < freshReps ? 1.0 : (repsBefore < tiredReps ? 0.6 : 0.3);

  /// Moltiplicatore medio per [count] rep fatte dopo [before] rep del giorno.
  static double fatigueFor(int before, int count) {
    if (count <= 0) return fatigueAt(before);
    var sum = 0.0;
    for (var i = 0; i < count; i++) {
      sum += fatigueAt(before + i);
    }
    return sum / count;
  }

  double fatigueOf(MuscleGroup g) => fatigueAt(daily.combatReps[g] ?? 0);

  /// Ritorna gli XP guadagnati (rep con Bonus Varietà + bonus vittoria) e le
  /// ricompense effettivamente date dopo la fatica.
  (int, CombatRewards, double) applyCombatRewards(
      CombatRewards r, ExerciseId exercise, List<RepQuality> reps,
      {required bool victory, Random? random}) {
    _rollDay();
    final group = exercises[exercise]!.group;
    final before = daily.combatReps[group] ?? 0;
    final fatigue = fatigueFor(before, reps.length);
    daily.combatReps[group] = before + reps.length;
    final granted = r.scaled(fatigue, random ?? Random());

    var xp = addTraining(exercise, reps, countsForQuest: false, inCombat: true);
    if (victory) {
      final bonus = (r.xp * 0.25).round();
      _gainXp(bonus);
      xp += bonus;
    }
    character.runes += granted.runes;
    granted.materials.forEach(character.addMaterial);
    if (granted.rareWeapon != null) {
      character.weapons.add(WeaponInstance(weaponId: granted.rareWeapon!));
    }
    _changed();
    return (xp, granted, fatigue);
  }

  // --------------------------------------------------------------- camminata

  /// Trasforma i passi di oggi in materiali. Ritorna solo quelli nuovi.
  Map<String, int> claimSteps(int stepsToday) {
    _rollDay();
    if (stepsToday <= daily.claimedSteps) return const {};
    final loot = stepLootDelta(daily.claimedSteps, stepsToday);
    daily.claimedSteps = stepsToday;
    loot.forEach(character.addMaterial);
    _changed();
    return loot;
  }

  void recordHuntWave(int wave) {
    if (wave <= bestHuntWave) return;
    bestHuntWave = wave;
    _changed();
  }

  bool useExpeditionKey() {
    _rollDay();
    if (expeditionKeys <= 0 || daily.expeditionDone) return false;
    expeditionKeys--;
    daily.expeditionDone = true;
    _changed();
    return true;
  }

  // ------------------------------------------------------------------ forgia

  bool craftForgeStone() {
    for (final e in forgeStone1Recipe.entries) {
      if ((character.materials[e.key] ?? 0) < e.value) return false;
    }
    forgeStone1Recipe.forEach(character.spendMaterial);
    character.addMaterial('forge_stone_1', 1);
    _changed();
    return true;
  }

  bool canCraft(WeaponDef def) =>
      def.recipe.isNotEmpty &&
      def.recipe.entries.every((e) => (character.materials[e.key] ?? 0) >= e.value);

  bool craftWeapon(WeaponDef def) {
    if (!canCraft(def)) return false;
    def.recipe.forEach(character.spendMaterial);
    character.weapons.add(WeaponInstance(weaponId: def.id));
    _changed();
    return true;
  }

  bool upgradeWeapon(WeaponInstance w) {
    final stone = w.nextStone;
    if (stone == null) return false;
    if (!character.spendMaterial(stone, w.nextStoneCost)) return false;
    w.upgrade++;
    _changed();
    return true;
  }

  void equip(WeaponInstance w) {
    if (identical(w, character.weapon)) return;
    character.weapons.remove(w);
    character.weapons.add(character.weapon);
    character.weapon = w;
    _changed();
  }

  void toggleAmulet(String id) {
    if (character.amulets.contains(id)) {
      character.amulets.remove(id);
    } else if (character.amulets.length < Character.maxAmuletSlots) {
      character.amulets.add(id);
    }
    _changed();
  }

  bool buyAmulet(String id, int price) {
    if (character.runes < price || character.materials['amulet_$id'] != null) {
      return false;
    }
    character.runes -= price;
    character.addMaterial('amulet_$id', 1);
    _changed();
    return true;
  }

  bool ownsAmulet(String id) => (character.materials['amulet_$id'] ?? 0) > 0;

  // --------------------------------------------------------------- attributi

  bool raiseAttribute(Attribute a) {
    final ok = character.raise(a);
    if (ok) _changed();
    return ok;
  }

  void choosePerk(PerkChoice choice, Perk perk) {
    if (choice.options.any(character.perks.contains)) return;
    character.perks.add(perk.id);
    _changed();
  }

  // -------------------------------------------------------------------- arena

  Division divisionOf(ExerciseId id) => divisionFor(id, records[id] ?? 0);

  void recordArena(ExerciseId id, String opponent, int comparison, ArenaResult mine,
      List<RepQuality> reps) {
    arenaPoints = (arenaPoints + rankDelta(comparison)).clamp(0, 99999);
    arenaHistory.insert(0, ArenaRecord(id, opponent, comparison.sign, today));
    if (arenaHistory.length > 30) arenaHistory.removeLast();
    final best = id == ExerciseId.plank ? mine.elapsedSeconds.round() : mine.validReps;
    // Nelle sfide "fai N rep" il record non cambia: misuriamo il tempo.
    if (arenaChallenges[id]?.goal != ChallengeGoal.fastestReps) {
      _updateRecord(id, best);
    }
    addTraining(id, reps, countsForQuest: false);
  }

  String get seasonTitle {
    if (arenaPoints >= 1600) return 'Campione della Stagione';
    if (arenaPoints >= 1300) return 'Cavaliere d\'Arena';
    if (arenaPoints >= 1100) return 'Scudiero d\'Arena';
    return 'Recluta d\'Arena';
  }
}
