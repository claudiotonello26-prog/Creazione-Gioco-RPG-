import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/i18n.dart';
import '../domain/character.dart';
import '../domain/combat.dart';
import '../domain/contracts.dart';
import '../domain/enemies.dart';
import '../domain/exercise.dart';
import '../domain/items.dart';
import '../domain/market.dart';
import '../domain/pvp.dart';
import '../domain/routine.dart';
import '../domain/novice.dart';
import '../domain/progress.dart';
import '../domain/skills.dart';
import '../domain/walking.dart';

enum PlayMode {
  /// Come GymScape: combattimenti liberi, nessuna routine imposta.
  free('Libera'),

  /// Test iniziale, quest del giorno e progressione.
  path('Percorso');

  const PlayMode(this._label);
  final String _label;
  String get label => tr(_label);
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

  /// Traguardi di passi di oggi già riscattati (0-4).
  int stepMilestones = 0;

  /// Rep fatte oggi in combattimento per gruppo muscolare (fatica).
  final Map<MuscleGroup, int> combatReps = {};

  /// Tappe del sentiero completate oggi per gruppo (4 esercizi + boss).
  final Map<MuscleGroup, int> pathDone = {};

  /// Punto raggiunto oggi su ogni mappa: 0-3 tappe, 4 boss, 5 forziere da
  /// aprire, 6 finita.
  final Map<String, int> expeditionStep = {};

  /// Bottino della quest giornaliera, per mostrarlo dopo.
  final Map<String, int> questLoot = {};

  Map<String, dynamic> toJson() => {
        'qloot': questLoot,
        'day': day,
        'quest': {for (final e in questDone.entries) e.key.name: e.value},
        'variety': {for (final e in varietyUsed.entries) e.key.name: e.value},
        'stretch': stretchingDone,
        'rewarded': questRewarded,
        'exp': expeditionDone,
        'xp': xpEarned,
        'good': goodForm,
        'steps': claimedSteps,
        'smile': stepMilestones,
        'combat': {for (final e in combatReps.entries) e.key.name: e.value},
        'path': {for (final e in pathDone.entries) e.key.name: e.value},
        'map': expeditionStep,
      };

  factory DailyState.fromJson(Map<String, dynamic> j) {
    final d = DailyState(j['day'] as String)
      ..stretchingDone = j['stretch'] as bool
      ..questRewarded = j['rewarded'] as bool
      ..expeditionDone = j['exp'] as bool
      ..xpEarned = j['xp'] as int
      ..goodForm = j['good'] as bool? ?? true
      ..claimedSteps = j['steps'] as int? ?? 0
      ..stepMilestones = j['smile'] as int? ?? 0;
    (j['quest'] as Map).forEach(
      (k, v) => d.questDone[ExerciseId.values.byName(k as String)] = v as int,
    );
    (j['variety'] as Map).forEach(
      (k, v) => d.varietyUsed[MuscleGroup.parse(k as String)] = v as int,
    );
    ((j['combat'] as Map?) ?? const {}).forEach(
      (k, v) => d.combatReps[MuscleGroup.parse(k as String)] = v as int,
    );
    ((j['path'] as Map?) ?? const {}).forEach(
      (k, v) => d.pathDone[MuscleGroup.parse(k as String)] = v as int,
    );
    ((j['map'] as Map?) ?? const {}).forEach((k, v) => d.expeditionStep[k as String] = v as int);
    ((j['qloot'] as Map?) ?? const {}).forEach((k, v) => d.questLoot[k as String] = v as int);
    return d;
  }
}

class ArenaRecord {
  ArenaRecord(this.exercise, this.opponent, this.won, this.day);
  final ExerciseId exercise;
  final String opponent;
  final int won; // 1 vittoria, 0 pareggio, -1 sconfitta
  final String day;

  Map<String, dynamic> toJson() => {'ex': exercise.name, 'opp': opponent, 'won': won, 'day': day};
  factory ArenaRecord.fromJson(Map<String, dynamic> j) => ArenaRecord(
        ExerciseId.values.byName(j['ex'] as String),
        j['opp'] as String,
        j['won'] as int,
        j['day'] as String,
      );
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
  /// Valore salvato, confrontato con le risposte del questionario: resta in
  /// italiano e si traduce solo quando lo si mostra.
  String goal = 'Restare in forma';
  int daysPerWeek = 3;
  String limitations = '';

  /// false = inserimento manuale delle rep (emulatori, accessibilità).
  bool useCamera = true;

  /// Lingua scelta nelle impostazioni (Automatica = quella del telefono).
  LangPref langPref = LangPref.auto;
  Lang get lang => appLang;

  /// Server dell'Arena live (Nakama), es. "arena.iron-oath.it" o "192.168.1.10:7350".
  String serverAddress = '';

  /// Identificativo anonimo del telefono per l'account online.
  String deviceId = '';

  /// Gilda e amici di prova finché il server non c'è (LocalGuildService).
  Map<String, dynamic> socialLocal = {};

  Map<ExerciseId, TestResult> test = {};
  DateTime? testDate;
  Map<ExerciseId, int> records = {};

  /// Storico di tutte le serie, giorno per giorno, e livello del primo test
  /// in rep equivalenti: è lo 0% dell'andamento della forza.
  TrainingHistory history = {};
  Map<ExerciseId, double> baselineEq = {};

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

  /// Spedizioni di cui è caduto il boss.
  Set<String> clearedExpeditions = {};

  /// Contratto di Caccia firmato, se c'è, e giorno dell'ultimo annullamento
  /// gratuito.
  HuntContract? contract;
  String? freeCancelDay;

  /// Giorni (yyyy-mm-dd) in cui hai aperto l'app e in cui hai chiuso la quest.
  Set<String> activeDays = {};
  Set<String> questDays = {};

  /// XP dei mestieri (Taglialegna, Minatore, Carpenteria, Fornace, Incudine).
  Map<Skill, int> skillXp = {};

  /// Giuramento: la build per cui arrivano i componenti speciali. null = la
  /// più alta fra Forza, Destrezza, Fede e Intelligenza.
  Attribute? oath;

  Attribute get build {
    if (oath != null) return oath!;
    var best = oathAttributes.first;
    for (final a in oathAttributes) {
      if (character.attr(a) > character.attr(best)) best = a;
    }
    return best;
  }

  void setLook(Appearance look) {
    character.look = look;
    _changed();
  }

  void setOath(Attribute? a) {
    oath = a;
    _changed();
  }

  Map<String, int> _forBuild(Map<String, int> loot) => lootForBuild(loot, build);

  /// Materia prima che i passi stanno raccogliendo e passi avanzati.
  String gatherTarget = 'ash_wood';
  int stepBank = 0;

  /// Contatori per il Cammino del Novizio (vittorie, oggetti creati...).
  Map<String, int> stats = {};

  /// Missione del Novizio in corso (== noviceQuests.length: finito).
  int noviceStep = 0;

  /// Consigli del trainer già visti, e se il trainer appare.
  Set<String> seenHints = {};
  bool trainerEnabled = true;

  void setTrainerEnabled(bool v) {
    trainerEnabled = v;
    if (v) seenHints = {};
    _changed();
  }

  late DailyState daily;

  // ---------------------------------------------------------------- persistenza

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    appLang = resolveLang(langPref);
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
    if (onboarded && activeDays.add(today)) await _save();
    notifyListeners();
  }

  static String _newDeviceId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Salva la gilda di prova dopo che LocalGuildService l'ha cambiata.
  void saveSocial() => _save();

  void setServerAddress(String value) {
    serverAddress = value.trim();
    _changed();
  }

  /// Punti stagione ufficiali arrivati dal server dopo un duello live.
  void applyLiveArena(
    ExerciseId id,
    String opponent,
    int outcome,
    int? serverPoints,
    List<RepQuality> reps, {
    LiveMode mode = LiveMode.arena,
  }) {
    // Sfide tra amici e allenamenti di gilda non toccano la stagione.
    if (mode == LiveMode.arena) {
      if (serverPoints != null) {
        arenaPoints = serverPoints;
      } else {
        arenaPoints = (arenaPoints + rankDelta(outcome)).clamp(0, 99999);
      }
    }
    if (mode != LiveMode.group) {
      final tag = mode == LiveMode.arena ? 'live' : tr('amico');
      arenaHistory.insert(0, ArenaRecord(id, '$opponent ($tag)', outcome.sign, today));
      if (arenaHistory.length > 30) arenaHistory.removeLast();
    }
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
        'langPref': langPref.name,
        'server': serverAddress,
        'device': deviceId,
        'social': socialLocal,
        'test': {for (final e in test.entries) e.key.name: e.value.toJson()},
        'testDate': testDate?.toIso8601String(),
        'records': {for (final e in records.entries) e.key.name: e.value},
        'history': {
          for (final d in history.entries)
            d.key: {for (final e in d.value.entries) e.key: e.value.toJson()},
        },
        'baseline': {for (final e in baselineEq.entries) e.key.name: e.value},
        'progression': progression,
        'goodDays': goodDays,
        'subs': {for (final e in substitutions.entries) e.key.name: e.value},
        'character': character.toJson(),
        'streak': streak,
        'lastDay': lastActiveDay,
        'keys': expeditionKeys,
        'cleared': clearedExpeditions.toList(),
        if (contract != null) 'contract': contract!.toJson(),
        if (freeCancelDay != null) 'freeCancel': freeCancelDay,
        'trained': {
          for (final e in trainedGroups.entries) e.key: [for (final g in e.value) g.name],
        },
        'arena': arenaPoints,
        'arenaHistory': [for (final r in arenaHistory) r.toJson()],
        'daily': daily.toJson(),
        'bestHunt': bestHuntWave,
        'activeDays': _recent(activeDays),
        'questDays': _recent(questDays),
        'skills': {for (final e in skillXp.entries) e.key.name: e.value},
        if (oath != null) 'oath': oath!.name,
        'gather': gatherTarget,
        'bank': stepBank,
        'stats': stats,
        'novice': noviceStep,
        'hints': seenHints.toList(),
        'trainer': trainerEnabled,
      };

  /// Bastano gli ultimi 120 giorni per il calendario.
  List<String> _recent(Set<String> days) => (days.toList()..sort()).reversed.take(120).toList();

  void _fromJson(Map<String, dynamic> j) {
    healthAccepted = j['health'] as bool;
    onboarded = j['onboarded'] as bool;
    mode = PlayMode.values.byName(j['mode'] as String);
    goal = j['goal'] as String;
    daysPerWeek = j['days'] as int;
    limitations = j['limits'] as String;
    useCamera = j['camera'] as bool? ?? true;
    // Il vecchio campo 'lang' non era una scelta del giocatore: chi non ha
    // ancora scelto segue il telefono.
    langPref = LangPref.values.asNameMap()[j['langPref']] ?? LangPref.auto;
    appLang = resolveLang(langPref);
    serverAddress = j['server'] as String? ?? '';
    deviceId = j['device'] as String? ?? '';
    socialLocal = j['social'] is Map ? Map<String, dynamic>.from(j['social'] as Map) : {};
    test = {
      for (final e in (j['test'] as Map).entries)
        ExerciseId.values.byName(e.key as String): TestResult.fromJson(
          e.value as Map<String, dynamic>,
        ),
    };
    testDate = j['testDate'] == null ? null : DateTime.parse(j['testDate'] as String);
    history = {
      for (final d in (j['history'] as Map? ?? const {}).entries)
        d.key as String: {
          for (final e in (d.value as Map).entries)
            e.key as String: ExerciseDay.fromJson(e.value as Map<String, dynamic>),
        },
    };
    baselineEq = {
      for (final e in (j['baseline'] as Map? ?? const {}).entries)
        ExerciseId.values.byName(e.key as String): (e.value as num).toDouble(),
    };
    if (baselineEq.isEmpty) _setBaseline();
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
    _migrateAmulets();
    streak = j['streak'] as int;
    lastActiveDay = j['lastDay'] as String?;
    expeditionKeys = j['keys'] as int;
    clearedExpeditions = {...(j['cleared'] as List? ?? const []).cast<String>()};
    contract = j['contract'] is Map
        ? HuntContract.fromJson(Map<String, dynamic>.from(j['contract'] as Map))
        : null;
    freeCancelDay = j['freeCancel'] as String?;
    trainedGroups = {
      for (final e in (j['trained'] as Map).entries)
        e.key as String: {for (final g in e.value as List) MuscleGroup.parse(g as String)},
    };
    arenaPoints = j['arena'] as int;
    arenaHistory = [
      for (final r in j['arenaHistory'] as List) ArenaRecord.fromJson(r as Map<String, dynamic>),
    ];
    daily = DailyState.fromJson(j['daily'] as Map<String, dynamic>);
    bestHuntWave = j['bestHunt'] as int? ?? 0;
    activeDays = Set<String>.from(j['activeDays'] as List? ?? const []);
    questDays = Set<String>.from(j['questDays'] as List? ?? const []);
    skillXp = {
      for (final e in ((j['skills'] as Map?) ?? const {}).entries)
        Skill.values.byName(e.key as String): e.value as int,
    };
    gatherTarget = j['gather'] as String? ?? 'ash_wood';
    oath = j['oath'] == null ? null : Attribute.values.byName(j['oath'] as String);
    // Prima degli attrezzi si poteva minare a mani nude: chi l'ha già fatto
    // tiene il piccone.
    if ((skillXp[Skill.mining] ?? 0) > 0 && (character.materials['ash_pickaxe'] ?? 0) == 0) {
      character.materials['ash_pickaxe'] = 1;
    }
    stepBank = j['bank'] as int? ?? 0;
    stats = Map<String, int>.from(j['stats'] as Map? ?? const {});
    noviceStep = j['novice'] as int? ?? 0;
    // La missione "Armati" è arrivata dopo: chi aveva già iniziato il
    // Cammino la salta, ha già spada e scudo.
    final char = j['character'] as Map?;
    if (char != null && !char.containsKey('armed') && j.containsKey('novice')) noviceStep++;
    seenHints = Set<String>.from(j['hints'] as List? ?? const []);
    trainerEnabled = j['trainer'] as bool? ?? true;
  }

  Future<void> resetAll() async {
    await _prefs?.remove(_storageKey);
    healthAccepted = false;
    onboarded = false;
    test = {};
    testDate = null;
    records = {};
    history = {};
    baselineEq = {};
    progression = 1.0;
    goodDays = 0;
    substitutions = {};
    character = Character();
    streak = 0;
    lastActiveDay = null;
    expeditionKeys = 0;
    clearedExpeditions = {};
    contract = null;
    freeCancelDay = null;
    trainedGroups = {};
    arenaPoints = 1000;
    arenaHistory = [];
    bestHuntWave = 0;
    activeDays = {};
    questDays = {};
    skillXp = {};
    gatherTarget = 'ash_wood';
    stepBank = 0;
    stats = {};
    noviceStep = 0;
    seenHints = {};
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
    final opened = onboarded && activeDays.add(today);
    if (before != daily.day || opened) _changed();
  }

  void _markActive() {
    activeDays.add(today);
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

  void setLangPref(LangPref value) {
    langPref = value;
    appLang = resolveLang(value);
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
    character.name = name.trim().isEmpty ? tr('Senza Nome') : name.trim();
    _changed();
  }

  void completeTest(Map<ExerciseId, TestResult> results) {
    test = Map.of(results);
    testDate = _clock();
    progression = 1.0;
    goodDays = 0;
    results.forEach((id, r) => _updateRecord(id, r.reps));
    if (baselineEq.isEmpty) _setBaseline();
    // Il test è una serie al massimo: entra nello storico come le altre.
    results.forEach((id, r) {
      final (name, diff) = _usualVariant(id);
      logSet(name, id, r.reps, difficulty: diff);
    });
    onboarded = true;
    _changed();
  }

  /// Il primo test fissa il livello di partenza della forza.
  void _setBaseline() {
    baselineEq = {
      for (final e in test.entries)
        e.key: e.value.reps *
            variantDifficulty(e.value.variantLevel) /
            (e.key == ExerciseId.plank ? plankSecondsPerRep : 1),
    };
  }

  /// Difficoltà della versione che il giocatore fa di solito.
  double usualDifficulty(ExerciseId id) => _usualVariant(id).$2;

  /// Nome e difficoltà della versione che il giocatore fa di solito.
  (String, double) _usualVariant(ExerciseId id) {
    final lvl = test[id]?.variantLevel ?? 0;
    return (exercises[id]!.variant(lvl).nameIt, variantDifficulty(lvl));
  }

  /// Registra una serie nello storico. [difficulty] rispetto alla versione
  /// base: 2.5 = vale due rep e mezzo di quella base.
  void logSet(
    String name,
    ExerciseId trackAs,
    int reps, {
    required double difficulty,
    MuscleGroup? group,
  }) {
    if (reps <= 0) return;
    final day = history.putIfAbsent(today, () => {});
    day
        .putIfAbsent(
          _historyName(name),
          () => ExerciseDay(
            trackAs: trackAs,
            region: BodyRegion.of(trackAs, group: group),
          ),
        )
        .add(reps, difficulty);
    if (history.length > 400) {
      final keys = history.keys.toList()..sort();
      history.remove(keys.first);
    }
  }

  /// Lo storico usa i nomi italiani degli esercizi, in qualunque lingua: un
  /// nome arrivato già tradotto torna alla sua chiave italiana.
  static String _historyName(String name) {
    if (appLang == Lang.it || enStrings[name] == name) return name;
    for (final e in enStrings.entries) {
      if (e.value == name) return e.key;
    }
    return name;
  }

  bool get retestDue =>
      testDate != null && _clock().difference(testDate!).inDays >= RoutineRules.retestEveryDays;

  // -------------------------------------------------------------- quest

  List<QuestItem> get quest => RoutineRules.dailyQuest(test, progression: progression);

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
  int addTraining(
    ExerciseId id,
    List<RepQuality> reps, {
    bool countsForQuest = true,
    bool inCombat = false,
    String? name,
    double? difficulty,
    MuscleGroup? pathGroup,
  }) {
    if (reps.isEmpty) return 0;
    _rollDay();
    final usual = _usualVariant(id);
    logSet(name ?? usual.$1, id, reps.length, difficulty: difficulty ?? usual.$2, group: pathGroup);
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
    questDays.add(today);
    _count('quests');
    expeditionKeys += 1;
    character.runes += 100;
    _gainXp(150);
    final loot = questLootFor(character.level, build, Random());
    loot.forEach(character.addMaterial);
    daily.questLoot
      ..clear()
      ..addAll(loot);
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

  void recordBest(
    ExerciseId id,
    int value, {
    String? name,
    double difficulty = 1,
    MuscleGroup? group,
  }) {
    _updateRecord(id, value);
    if (id == ExerciseId.plank) {
      logSet(name ?? 'Plank', id, value, difficulty: difficulty, group: group);
    }
    _changed();
  }

  /// Le high knees non hanno un test: valgono come i jumping jack.
  int testRepsFor(ExerciseId id) =>
      test[id == ExerciseId.highKnees ? ExerciseId.jumpingJack : id]?.reps ?? 10;

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
    CombatRewards r,
    ExerciseId exercise,
    List<RepQuality> reps, {
    required bool victory,
    Stance stance = Stance.balanced,
    Random? random,
    int hitsTaken = 0,
  }) {
    _rollDay();
    if (reps.isNotEmpty) _wearGear(hitsTaken);
    // La postura decide dove va l'esperienza di combattimento.
    final combatXp = reps.length * 4;
    // Il bastone e il catalizzatore allenano la Magia; spade e archi l'Attacco.
    final offense = character.weapon.def.style == WeaponStyle.magic ? Skill.magic : Skill.attack;
    switch (stance) {
      case Stance.aggressive:
        _gainSkill(offense, combatXp);
      case Stance.defensive:
        _gainSkill(Skill.defense, combatXp);
      case Stance.balanced:
        _gainSkill(offense, combatXp ~/ 2);
        _gainSkill(Skill.defense, combatXp - combatXp ~/ 2);
    }
    final group = exercises[exercise]!.group;
    final before = daily.combatReps[group] ?? 0;
    final fatigue = fatigueFor(before, reps.length);
    daily.combatReps[group] = before + reps.length;
    final scaled = r.scaled(fatigue, random ?? Random());
    final granted = scaled.withMaterials(_forBuild(scaled.materials));

    // Le rep in combattimento contano anche per la quest giornaliera.
    var xp = addTraining(exercise, reps, inCombat: true);
    if (victory) {
      final bonus = (r.xp * 0.25).round();
      _gainXp(bonus);
      xp += bonus;
    }
    if (victory) _count('wins');
    character.runes += granted.runes;
    granted.materials.forEach(character.addMaterial);
    if (granted.rareWeapon != null) {
      character.weapons.add(WeaponInstance(weaponId: granted.rareWeapon!));
    }
    _changed();
    return (xp, granted, fatigue);
  }

  // ----------------------------------------------------------------- sentieri

  int pathProgress(MuscleGroup g) {
    _rollDay();
    return daily.pathDone[g] ?? 0;
  }

  /// Una tappa del sentiero superata: si sblocca la successiva.
  void completePathStep(MuscleGroup g, int step) {
    _rollDay();
    if (step != (daily.pathDone[g] ?? 0)) return;
    daily.pathDone[g] = step + 1;
    _count('path_steps');
    _changed();
  }

  /// Bottino del boss a circuito: fisso, perché 30 secondi a sfinimento
  /// valgono per tutti allo stesso modo. Lo Zavorrato dà di più.
  Map<String, int> bossLoot(MuscleGroup g, {required bool weighted, Random? random}) {
    final r = random ?? Random();
    final m = weighted ? 2 : 1;
    // Il guardiano lascia i materiali base del suo gruppo.
    final base = switch (g) {
      MuscleGroup.push => {'iron_ingot': 2, 'bone': 2},
      MuscleGroup.legs => {'raw_hide': 3, 'bone': 2},
      MuscleGroup.core => {'bronze_ingot': 2, 'bone': 2},
      MuscleGroup.cardio => {'silver_ingot': 1, 'beast_essence': 2},
      MuscleGroup.stretching || MuscleGroup.mobility => {'gem_rough': 1, 'beast_essence': 2},
    };
    final loot = <String, int>{
      for (final e in base.entries) e.key: e.value * m,
      'forge_stone_1': 1 * m,
    };
    if (r.nextDouble() < (weighted ? 0.5 : 0.3)) loot['holy_shard'] = 1;
    if (r.nextDouble() < (weighted ? 0.12 : 0.06)) loot['ancient_stone'] = 1;
    if (r.nextDouble() < (weighted ? 0.06 : 0.03)) loot['somber_stone'] = 1;
    _forBuild(loot).forEach(character.addMaterial);
    daily.pathDone[g] = (daily.pathDone[g] ?? 0) + 1;
    _count('boss_wins');
    _gainXp(150 * m);
    _markActive();
    _changed();
    return loot;
  }

  // -------------------------------------------------------- Cammino del Novizio

  NoviceQuest? get noviceQuest =>
      noviceStep < noviceQuests.length ? noviceQuests[noviceStep] : null;

  bool get noviceReady {
    final q = noviceQuest;
    return q != null && stat(q.stat) >= q.target;
  }

  /// Riscuote la missione completata e passa alla prossima.
  NoviceQuest? claimNovice() {
    final q = noviceQuest;
    if (q == null || !noviceReady) return null;
    character.runes += q.runes;
    q.loot.forEach(character.addMaterial);
    noviceStep++;
    _changed();
    return q;
  }

  /// Prima missione: il trainer consegna spada e scudo e li equipaggia.
  void armUp() {
    if (character.armed) return;
    character.armed = true;
    character.offhands.add('wooden_shield');
    character.offhandId ??= 'wooden_shield';
    _count('armed');
    _changed();
  }

  /// Segna un consiglio del trainer come visto. Ritorna true la prima volta.
  bool markHint(String id) {
    if (!seenHints.add(id)) return false;
    _changed();
    return true;
  }

  // --------------------------------------------------------------- camminata

  void setGatherTarget(String id) {
    final r = resourceById(id);
    if (!canGather(r)) return;
    gatherTarget = id;
    _changed();
  }

  /// Traguardi raggiunti ma non ancora riscattati.
  int pendingStepMilestones(int stepsToday) {
    _rollDay();
    return stepMilestones.where((m) => stepsToday >= m).length - daily.stepMilestones;
  }

  /// Riscatta i traguardi di passi raggiunti oggi: ritorna le rune date.
  int claimStepMilestones(int stepsToday) {
    _rollDay();
    var runes = 0;
    while (daily.stepMilestones < stepMilestones.length &&
        stepsToday >= stepMilestones[daily.stepMilestones]) {
      runes += stepMilestoneRunes(daily.stepMilestones);
      daily.stepMilestones++;
    }
    if (runes > 0) {
      character.runes += runes;
      _changed();
    }
    return runes;
  }

  /// Quanti passi servono per un'unità di [r], con l'attrezzo migliore.
  int stepsPerUnit(Resource r) => (r.stepsPerUnit / (1 + gatherBonus(r.skill))).round();

  /// I passi nuovi di oggi finiscono nella riserva, da spendere dove si
  /// vuole. Ritorna quanti ne sono entrati.
  int collectSteps(int stepsToday) {
    _rollDay();
    final capped = min(stepsToday, dailyStepCap);
    if (capped <= daily.claimedSteps) return 0;
    final fresh = capped - daily.claimedSteps;
    stepBank += fresh;
    daily.claimedSteps = capped;
    _changed();
    return fresh;
  }

  /// Spende fino a [steps] passi della riserva su [resourceId]: solo unità
  /// intere, il resto resta in riserva. Ritorna (unità, livelli guadagnati).
  (int, int) spendSteps(String resourceId, int steps) {
    var r = resourceById(resourceId);
    if (!canGather(r)) return (0, 0);
    gatherTarget = r.id;
    final per = stepsPerUnit(r);
    final units = min(steps, stepBank) ~/ per;
    if (units <= 0) {
      _changed();
      return (0, 0);
    }
    stepBank -= units * per;
    character.addMaterial(r.id, units);
    _count('gather:${r.id}', units);
    final levels = _gainSkill(r.skill, units * r.xp);
    _changed();
    return (units, levels);
  }

  /// I passi nuovi di oggi vanno tutti nella raccolta scelta: ogni
  /// [Resource.stepsPerUnit] passi un'unità, il resto aspetta il prossimo giro.
  /// Ritorna (unità, livelli di mestiere guadagnati).
  (int, int) claimSteps(int stepsToday) {
    collectSteps(stepsToday);
    if (!canGather(resourceById(gatherTarget))) gatherTarget = 'ash_wood';
    return spendSteps(gatherTarget, stepBank);
  }

  void recordHuntWave(int wave) {
    if (wave <= bestHuntWave) return;
    bestHuntWave = wave;
    _changed();
  }

  /// Una chiave raddoppia il bottino di una spedizione.
  bool useExpeditionKey() {
    _rollDay();
    if (expeditionKeys <= 0) return false;
    expeditionKeys--;
    daily.expeditionDone = true;
    _changed();
    return true;
  }

  /// Il boss della spedizione è caduto.
  void clearExpedition(String id) {
    final e = expeditionById(id);
    // La prima volta vale di più; poi ogni ripetizione allena comunque.
    _gainSkill(Skill.expeditions, (clearedExpeditions.contains(id) ? 40 : 120) + 10 * e.level);
    clearedExpeditions.add(id);
    _count('expeditions');
    _changed();
  }

  /// Vittoria nello Stretching: lo spirito si calma se tieni la posa. Paga
  /// come un combattimento vinto, senza danni né fatica.
  // --------------------------------------------------------------- mappe

  static const int mapBoss = 4, mapChest = 5, mapDone = 6;

  /// Quota delle rune del forziere quando la mappa è già stata aperta.
  static const double chestRepeatRunes = 0.25;

  int expeditionProgress(String id) {
    _rollDay();
    return daily.expeditionStep[id] ?? 0;
  }

  /// Una tappa della mappa superata: si accende la successiva.
  void completeExpeditionStep(String id, int step) {
    _rollDay();
    if (step != (daily.expeditionStep[id] ?? 0) || step >= mapBoss) return;
    daily.expeditionStep[id] = step + 1;
    _count('path_steps');
    _changed();
  }

  /// Il boss della mappa cade dopo il circuito: lascia il suo bottino e
  /// mostra il forziere.
  Map<String, int> expeditionBossDown(Expedition e, {bool weighted = false, Random? random}) {
    _rollDay();
    final m = weighted ? 2 : 1;
    // Come ogni vittoria: i comuni, o al loro posto un pezzo speciale.
    final special = e.boss.rollSpecial(random ?? Random(), multiplier: m.toDouble());
    final Map<String, int> loot;
    if (special == null) {
      loot = _forBuild({for (final l in e.boss.commonLoot.entries) l.key: l.value * m});
      loot.forEach(character.addMaterial);
    } else {
      loot = {_grantItem(special): 1};
    }
    _gainXp(150 * m);
    _gainSkill(Skill.expeditions, 60);
    daily.expeditionStep[e.id] = mapChest;
    daily.pathDone[e.group] = (daily.pathDone[e.group] ?? 0) + 1;
    clearExpedition(e.id);
    final c = contract;
    if (c != null && c.targets.contains(e.id)) c.done.add(e.id);
    _count('boss_wins');
    _markActive();
    _changed();
    return loot;
  }

  /// Apre il forziere: prima i garantiti, poi i rari. [multiplier] è 2 con lo
  /// Zavorrato o la chiave, 4 con entrambi: moltiplica quantità e probabilità.
  /// Ritorna gli oggetti nell'ordine in cui escono e quali sono rari.
  List<(String, int, bool)> openChest(Expedition e, {int multiplier = 1, Random? random}) {
    _rollDay();
    if ((daily.expeditionStep[e.id] ?? 0) != mapChest) return const [];
    final r = random ?? Random();
    final out = <(String, int, bool)>[];
    // Le rune piene solo la prima volta: rifare la stessa mappa ogni giorno
    // rendeva più dei combattimenti (tre quarti delle rune, dal simulatore).
    final repeat = stat('chest:${e.id}') > 0;
    final runes = (e.chest.runes * multiplier * (repeat ? chestRepeatRunes : 1)).round();
    character.runes += runes;
    out.add(('runes', runes, false));
    for (final g in _forBuild(e.chest.guaranteed).entries) {
      character.addMaterial(g.key, g.value * multiplier);
      out.add((g.key, g.value * multiplier, false));
    }
    for (final (id, p) in e.chest.rares) {
      if (r.nextDouble() >= min(1.0, p * multiplier)) continue;
      out.add((_grantItem(id), 1, true));
    }
    daily.expeditionStep[e.id] = mapDone;
    _count('chests');
    _count('chest:${e.id}');
    _changed();
    return out;
  }

  // ------------------------------------------------------ contratti di caccia

  bool canSign(Contractor c) => contract == null && skillLevel(Skill.expeditions) >= c.minSkill;

  /// Firma un contratto: solo ora si scoprono le spedizioni da finire.
  HuntContract? signContract(Contractor c, {Random? random}) {
    if (!canSign(c)) return null;
    contract = HuntContract(
      contractorId: c.id,
      targets: drawContractTargets(c, character.level, random ?? Random()),
    );
    _changed();
    return contract;
  }

  /// Il primo annullamento del giorno è gratis, poi costa rune.
  bool get freeCancelToday => freeCancelDay != today;

  bool cancelContract() {
    final c = contract;
    if (c == null) return false;
    if (freeCancelToday) {
      freeCancelDay = today;
    } else {
      final cost = cancelCost(c.contractor);
      if (character.runes < cost) return false;
      character.runes -= cost;
    }
    contract = null;
    _changed();
    return true;
  }

  /// Consegna il contratto finito: rune, XP di Spedizioni e il forziere del
  /// committente. Ritorna gli oggetti come [openChest].
  List<(String, int, bool)> deliverContract({Random? random}) {
    final c = contract;
    if (c == null || !c.complete) return const [];
    final who = c.contractor;
    final r = random ?? Random();
    final out = <(String, int, bool)>[];
    character.runes += who.runes;
    out.add(('runes', who.runes, false));
    for (final g in _forBuild(who.guaranteed).entries) {
      character.addMaterial(g.key, g.value);
      out.add((g.key, g.value, false));
    }
    for (final (id, p) in who.rares) {
      if (r.nextDouble() >= p) continue;
      out.add((_grantItem(id == buildRareWeapon ? rareWeaponFor(build) : id), 1, true));
    }
    _gainSkill(Skill.expeditions, who.skillXp);
    contract = null;
    _count('contracts');
    _changed();
    return out;
  }

  /// Dà un oggetto qualunque: arma, amuleto o materiale. Ritorna la chiave
  /// con cui lo si ritrova.
  String _grantItem(String id) {
    if (weaponDefs.containsKey(id)) {
      character.weapons.add(WeaponInstance(weaponId: id));
      return id;
    }
    final key = amuletDefs.containsKey(id) ? 'amulet_$id' : forBuild(id, build);
    character.addMaterial(key, 1);
    return key;
  }

  /// Un mostro di spedizione abbattuto: sale l'abilità Spedizioni.
  void expeditionKill(EnemyDef e) {
    _gainSkill(Skill.expeditions, e.isBoss ? 60 : 25);
    _changed();
  }

  CombatRewards holdVictory(EnemyDef e, {required int seconds, double lootMultiplier = 1}) {
    _rollDay();
    final materials = _forBuild({
      for (final l in e.commonLoot.entries) l.key: max(1, (l.value * lootMultiplier).round()),
    });
    materials.forEach(character.addMaterial);
    final runes = (e.runeReward * lootMultiplier).round();
    character.runes += runes;
    final xp = seconds * 4 + (e.isBoss ? 60 : 25);
    _gainXp(xp);
    _gainSkill(Skill.defense, seconds);
    _gainSkill(Skill.expeditions, e.isBoss ? 60 : 25);
    trainedGroups.putIfAbsent(today, () => {}).add(MuscleGroup.stretching);
    _count('wins');
    _markActive();
    _changed();
    return CombatRewards(xp: xp, runes: runes, materials: materials);
  }

  // ------------------------------------------------------------------ forgia

  bool hasMaterials(Map<String, int> needed) =>
      needed.entries.every((e) => (character.materials[e.key] ?? 0) >= e.value);

  // ------------------------------------------------------------ manutenzione

  /// Ogni scontro consuma un punto dell'arma impugnata e, se il nemico ha
  /// colpito, uno di ogni armatura indossata.
  void _wearGear(int hitsTaken) {
    final w = character.weapon;
    if (w.wear < maxWear) w.wear++;
    if (hitsTaken <= 0) return;
    for (final id in character.worn.values.toSet()) {
      character.armorWear[id] = min(maxWear, character.wearOf(id) + 1);
    }
  }

  /// Oggetti da riparare: (id, livello di forgia, usura). Le armi rare
  /// valgono come livello 25.
  List<(String, int, int)> get gearToRepair => [
        for (final w in [character.weapon, ...character.weapons])
          if (w.wear > 0) (w.weaponId, w.def.rare ? 25 : w.def.craftLevel, w.wear),
        for (final id in character.armors)
          if (character.wearOf(id) > 0) (id, armorDefs[id]!.craftLevel, character.wearOf(id)),
      ];

  int get repairAllCost =>
      gearToRepair.fold(0, (sum, g) => sum + repairCost(g.$2, g.$3));

  /// Qualcosa ha già perso forza per l'usura.
  bool get gearWornOut =>
      character.weapon.wear > wearFreeUpTo ||
      character.worn.values.any((id) => character.wearOf(id) > wearFreeUpTo);

  /// Usura più alta fra l'arma impugnata e l'armatura indossata.
  int get worstWear => [
        character.weapon.wear,
        for (final id in character.worn.values) character.wearOf(id),
      ].reduce(max);

  /// Ripara tutto all'Incudine: costa rune e allena la Forgiatura (2 XP per
  /// punto d'usura).
  bool repairAll() {
    final cost = repairAllCost;
    if (cost <= 0 || character.runes < cost) return false;
    var points = 0;
    for (final w in [character.weapon, ...character.weapons]) {
      points += w.wear;
      w.wear = 0;
    }
    for (final v in character.armorWear.values) {
      points += v;
    }
    character.armorWear.clear();
    character.runes -= cost;
    _gainSkill(Skill.smithing, points * 2);
    _count('repairs');
    _changed();
    return true;
  }

  // ----------------------------------------------------------------- mestieri

  /// Elemento della build per la ruota degli elementi.
  Affinity get heroElement => Affinity.attributes[build]!;

  int skillLevel(Skill k) => skillProgress(skillXp[k] ?? 0, max: k.maxLevel).$1;

  (int, int, int) skillProgressOf(Skill k) => skillProgress(skillXp[k] ?? 0, max: k.maxLevel);

  /// Livello che potenzia l'arma impugnata: Magia per bastoni e
  /// catalizzatori, Attacco per il resto (è quello che sale combattendo).
  int get attackLevel =>
      skillLevel(character.weapon.def.usesMagic ? Skill.magic : Skill.attack);
  int get defenseLevel => skillLevel(Skill.defense);

  /// Potere d'attacco mostrato nella Home: arma, attributi e livello di Attacco.
  int get attackValue => (character.weapon.attackRating(character) *
          (1 + CombatEngine.attackBonus(attackLevel)) *
          (1 + (character.offhand?.damageBonus ?? 0) + character.armorAttributeBonus))
      .round();

  /// Colpi assorbiti: armatura, scudo e livello di Difesa.
  double get defenseValue =>
      min(0.75, character.damageReduction + CombatEngine.defenseBonus(defenseLevel));

  /// Attrezzi posseduti (stanno nell'inventario come oggetti singoli).
  bool hasTool(String id) => (character.materials[id] ?? 0) > 0;

  /// Il miglior attrezzo della famiglia vale anche per quelli sotto.
  bool hasToolAtLeast(String id) {
    final family = axes.contains(id) ? axes : pickaxes;
    final need = family.indexOf(id);
    for (var i = need; i < family.length; i++) {
      if (hasTool(family[i])) return true;
    }
    return false;
  }

  bool canGather(Resource r) =>
      skillLevel(r.skill) >= r.level && (r.tool == null || hasToolAtLeast(r.tool!));

  /// Raccolta in più grazie al miglior attrezzo della famiglia.
  double gatherBonus(Skill skill) {
    final family = skill == Skill.woodcutting ? axes : pickaxes;
    var best = 0.0;
    for (final t in family) {
      if (hasTool(t)) best = max(best, toolYield[t]!);
    }
    return best;
  }

  int stationLevel(Station s) => skillLevel(Skill.forStation(s));

  /// Ritorna i livelli guadagnati (0 se nessuno).
  int _gainSkill(Skill k, int xp) {
    final before = skillLevel(k);
    skillXp[k] = (skillXp[k] ?? 0) + xp;
    return skillLevel(k) - before;
  }

  void _count(String key, [int n = 1]) => stats[key] = (stats[key] ?? 0) + n;

  int stat(String key) => key == 'hunt_wave' ? bestHuntWave : (stats[key] ?? 0);

  /// Fornace e Carpenteria: trasforma materiali in altri materiali.
  bool canCraftMaterial(MaterialRecipe r) =>
      stationLevel(r.station) >= r.level &&
      hasMaterials(r.inputs) &&
      !(r.tool && hasTool(r.output));

  bool craftMaterial(MaterialRecipe r) {
    if (!canCraftMaterial(r)) return false;
    r.inputs.forEach(character.spendMaterial);
    character.addMaterial(r.output, r.qty);
    _gainSkill(Skill.forStation(r.station), materialCraftXp(r.level, r.inputs));
    _count('craft:${r.output}', r.qty);
    _changed();
    return true;
  }

  bool craftForgeStone() =>
      craftMaterial(materialRecipes.firstWhere((r) => r.output == 'forge_stone_1'));

  bool canCraft(WeaponDef def) =>
      def.recipe.isNotEmpty &&
      stationLevel(def.station) >= def.craftLevel &&
      hasMaterials(def.recipe);

  /// Grado di qualità sicuro se lo forgi adesso.
  CraftQuality craftQuality(Station station, int craftLevel) =>
      CraftQuality.base(stationLevel(station), craftLevel);

  bool craftWeapon(WeaponDef def, {Random? random}) {
    if (!canCraft(def)) return false;
    def.recipe.forEach(character.spendMaterial);
    final q = CraftQuality.roll(stationLevel(def.station), def.craftLevel, random ?? Random());
    lastCraftQuality = q;
    character.weapons.add(WeaponInstance(weaponId: def.id, quality: q));
    _gainSkill(Skill.forStation(def.station), craftXp(def.craftLevel) * gearCraftXpFactor);
    _count('craft:${def.id}');
    _changed();
    return true;
  }

  /// Un'armatura si forgia una volta, e si riforgia solo quando la
  /// Forgiatura è salita abbastanza da farla di un grado migliore.
  bool canReforgeArmor(ArmorDef def) =>
      character.armors.contains(def.id) &&
      craftQuality(Station.anvil, def.craftLevel).index > character.qualityOf(def.id).index;

  bool canCraftArmor(ArmorDef def) =>
      (!character.armors.contains(def.id) || canReforgeArmor(def)) &&
      stationLevel(Station.anvil) >= def.craftLevel &&
      hasMaterials(def.recipe);

  /// Qualità dell'ultimo pezzo forgiato, per la festa a schermo.
  CraftQuality? lastCraftQuality;

  bool craftArmor(ArmorDef def, {Random? random}) {
    if (!canCraftArmor(def)) return false;
    def.recipe.forEach(character.spendMaterial);
    var q = CraftQuality.roll(stationLevel(Station.anvil), def.craftLevel, random ?? Random());
    if (q.index < character.qualityOf(def.id).index) q = character.qualityOf(def.id);
    lastCraftQuality = q;
    character.armors.add(def.id);
    character.armorQuality[def.id] = q;
    character.armorWear.remove(def.id);
    for (final slot in ArmorSlot.values) {
      character.worn[slot] = def.id;
    }
    _gainSkill(Skill.smithing, craftXp(def.craftLevel) * gearCraftXpFactor);
    _count('craft:${def.id}');
    _changed();
    return true;
  }

  /// Indossa un pezzo (null = toglilo).
  void wearPiece(ArmorSlot slot, String? id) {
    if (id == null) {
      character.worn.remove(slot);
    } else if (character.armors.contains(id) && canWear(id)) {
      character.worn[slot] = id;
    }
    _changed();
  }

  bool canCraftOffhand(OffhandDef def) =>
      !character.offhands.contains(def.id) &&
      stationLevel(def.station) >= def.craftLevel &&
      hasMaterials(def.recipe);

  bool craftOffhand(OffhandDef def) {
    if (!canCraftOffhand(def)) return false;
    def.recipe.forEach(character.spendMaterial);
    character.offhands.add(def.id);
    character.offhandId = def.id;
    _gainSkill(Skill.forStation(def.station), craftXp(def.craftLevel) * gearCraftXpFactor);
    _count('craft:${def.id}');
    _changed();
    return true;
  }

  void wearCape(String? id) {
    if (id != null && !character.capes.contains(id)) return;
    character.capeId = id;
    _changed();
  }

  bool buyCape(String id) {
    final cape = capeDefs[id];
    if (cape == null || character.capes.contains(id) || character.runes < cape.price) return false;
    character.runes -= cape.price;
    character.capes.add(id);
    character.capeId = id;
    _changed();
    return true;
  }

  /// Amuleto al collo: solo passivi; quello di prima torna nella borsa.
  bool wearNeck(String? id) {
    final old = character.neck;
    if (id != null) {
      final a = amuletDefs[id];
      if (a == null || a.isAffinity || a.isBane || amuletCount(id) <= 0) return false;
      character.spendMaterial('amulet_$id', 1);
    }
    if (old != null) character.addMaterial('amulet_$old', 1);
    character.neck = id;
    _changed();
    return true;
  }

  void holdOffhand(String? id) {
    if (id != null && !character.offhands.contains(id)) return;
    character.offhandId = id;
    _changed();
  }

  bool upgradeWeapon(WeaponInstance w) {
    final stone = w.nextStone;
    if (stone == null) return false;
    final runes = w.nextRuneCost;
    if (character.runes < runes) return false;
    if (!character.spendMaterial(stone, w.nextStoneCost)) return false;
    character.runes -= runes;
    w.upgrade++;
    _count('upgrades');
    _changed();
    return true;
  }

  /// Livello richiesto per impugnare l'arma è raggiunto?
  bool canWield(WeaponDef d) =>
      skillLevel(d.usesMagic ? Skill.magic : Skill.attack) >= d.wieldLevel;

  bool canWear(String armorId) => defenseLevel >= armorDefs[armorId]!.wearLevel;

  void equip(WeaponInstance w) {
    if (identical(w, character.weapon) || !canWield(w.def)) return;
    character.weapons.remove(w);
    character.weapons.add(character.weapon);
    character.weapon = w;
    _changed();
  }

  /// Prima gli amuleti si indossavano sul personaggio: ora vanno
  /// incastonati nell'arma impugnata.
  void _migrateAmulets() {
    for (final id in List.of(character.amulets)) {
      final a = amuletDefs[id];
      if (a == null) continue;
      final slots = a.isAffinity ? const [0] : const [1, 2];
      final free = slots.where((i) => character.weapon.sockets[i] == null);
      if (free.isNotEmpty) socketAmulet(character.weapon, free.first, id, notify: false);
    }
    character.amulets.clear();
  }

  int amuletCount(String id) => character.materials['amulet_$id'] ?? 0;

  /// Incastona un amuleto nell'arma: la prima incastonatura accetta solo
  /// quelli d'affinità, le altre due solo i passivi. Quello che c'era torna
  /// nella borsa.
  bool socketAmulet(WeaponInstance w, int slot, String id, {bool notify = true}) {
    final a = amuletDefs[id];
    if (a == null || a.isAffinity != (slot == 0) || a.isWard || amuletCount(id) <= 0) return false;
    final old = w.sockets[slot];
    character.spendMaterial('amulet_$id', 1);
    if (old != null) character.addMaterial('amulet_$old', 1);
    w.sockets[slot] = id;
    if (notify) _changed();
    return true;
  }

  void unsocketAmulet(WeaponInstance w, int slot) {
    final old = w.sockets[slot];
    if (old == null) return;
    character.addMaterial('amulet_$old', 1);
    w.sockets[slot] = null;
    _changed();
  }

  bool canCraftAmulet(String id) => amuletRecipes[id] != null && hasMaterials(amuletRecipes[id]!);

  /// La Fattucchiera incanta gli amuleti d'affinità con il cuore della build.
  bool craftAmulet(String id) {
    if (!canCraftAmulet(id)) return false;
    amuletRecipes[id]!.forEach(character.spendMaterial);
    character.addMaterial('amulet_$id', 1);
    _count('craft:amulet_$id', 1);
    _changed();
    return true;
  }

  bool buyAmulet(String id, int price) {
    if (character.runes < price) return false;
    character.runes -= price;
    character.addMaterial('amulet_$id', 1);
    _changed();
    return true;
  }

  // ---------------------------------------------------------------- mercato

  bool sellMaterial(String id, [int n = 1]) {
    if (!sellable(id) || !character.spendMaterial(id, n)) return false;
    character.runes += sellPrice(id) * n;
    _count('sell', n);
    _changed();
    return true;
  }

  bool buyMaterial(String id, [int n = 1]) {
    final cost = buyPrice(id) * n;
    if (cost <= 0 || character.runes < cost) return false;
    character.runes -= cost;
    character.addMaterial(id, n);
    _changed();
    return true;
  }

  /// Vende un'arma della rastrelliera (non quella impugnata).
  bool sellWeapon(WeaponInstance w) {
    if (identical(w, character.weapon) || !character.weapons.remove(w)) return false;
    character.runes += weaponValue(w);
    _count('sell');
    _changed();
    return true;
  }

  bool ownsAmulet(String id) => (character.materials['amulet_$id'] ?? 0) > 0;

  // --------------------------------------------------------------- attributi

  bool raiseAttribute(Attribute a) {
    final ok = character.raise(a);
    if (ok) {
      _count('attr');
      _changed();
    }
    return ok;
  }

  void choosePerk(PerkChoice choice, Perk perk) {
    if (choice.options.any(character.perks.contains)) return;
    character.perks.add(perk.id);
    _changed();
  }

  // -------------------------------------------------------------------- arena

  Division divisionOf(ExerciseId id) => divisionFor(id, records[id] ?? 0);

  void recordArena(
    ExerciseId id,
    String opponent,
    int comparison,
    ArenaResult mine,
    List<RepQuality> reps,
  ) {
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
    if (arenaPoints >= 1600) return tr('Campione della Stagione');
    if (arenaPoints >= 1300) return tr('Cavaliere d\'Arena');
    if (arenaPoints >= 1100) return tr('Scudiero d\'Arena');
    return tr('Recluta d\'Arena');
  }
}
