/// Storico degli allenamenti e andamento della forza reale.
///
/// Ogni serie diventa "rep equivalenti" alla versione base dell'esercizio:
/// rep × difficoltà. Una versione più dura vale di più, una facilitata meno.
/// L'indice di forza di una zona è la serie migliore del periodo divisa per
/// quella del test iniziale (100 = come al primo giorno). Così, se dopo una
/// settimana fai meno rep ma più difficili, l'indice sale lo stesso.
library;

import 'dart:math';

import '../core/i18n.dart';
import 'exercise.dart';

enum BodyRegion {
  upper('Parte alta'),
  core('Core'),
  legs('Gambe');

  const BodyRegion(this._label);
  final String _label;
  String get label => tr(_label);

  static BodyRegion? of(ExerciseId id, {MuscleGroup? group}) {
    if (group == MuscleGroup.push) return upper;
    if (group == MuscleGroup.cardio || group == MuscleGroup.stretching) return null;
    return switch (id) {
      ExerciseId.pushUp => upper,
      ExerciseId.crunch || ExerciseId.legRaise || ExerciseId.plank => core,
      ExerciseId.squat || ExerciseId.lunge => legs,
      ExerciseId.jumpingJack || ExerciseId.highKnees || ExerciseId.stretch => null,
    };
  }
}

/// Le versioni facilitate valgono meno: ogni gradino in giù vale il 60%
/// (come il passaggio di versione che propone il gioco: 60% delle rep).
double variantDifficulty(int level) => pow(0.6, level).toDouble();

/// Secondi di plank che valgono una rep.
const double plankSecondsPerRep = 2;

/// Un esercizio in un giorno: rep totali, serie migliore e serie migliore in
/// rep equivalenti.
class ExerciseDay {
  ExerciseDay({
    required this.trackAs,
    this.region,
    this.reps = 0,
    this.sets = 0,
    this.bestSet = 0,
    this.bestEq = 0,
  });

  final ExerciseId trackAs;
  final BodyRegion? region;
  int reps;
  int sets;
  int bestSet;
  double bestEq;

  void add(int setReps, double difficulty) {
    reps += setReps;
    sets++;
    bestSet = max(bestSet, setReps);
    final eq = setReps * difficulty / (trackAs == ExerciseId.plank ? plankSecondsPerRep : 1);
    bestEq = max(bestEq, eq);
  }

  Map<String, dynamic> toJson() => {
        't': trackAs.name,
        'g': region?.name,
        'r': reps,
        's': sets,
        'b': bestSet,
        'e': double.parse(bestEq.toStringAsFixed(2)),
      };

  factory ExerciseDay.fromJson(Map<String, dynamic> j) => ExerciseDay(
        trackAs: ExerciseId.values.byName(j['t'] as String),
        region: j['g'] == null ? null : BodyRegion.values.byName(j['g'] as String),
        reps: j['r'] as int,
        sets: j['s'] as int,
        bestSet: j['b'] as int,
        bestEq: (j['e'] as num).toDouble(),
      );
}

/// Giorno → nome dell'esercizio (come lo vede il giocatore) → dati.
typedef TrainingHistory = Map<String, Map<String, ExerciseDay>>;

enum ProgressSpan {
  day('Giorno', 14),
  week('Settimana', 12),
  month('Mese', 12);

  const ProgressSpan(this._label, this.buckets);
  final String _label;
  String get label => tr(_label);

  /// Quanti periodi mostra il grafico.
  final int buckets;
}

/// Un periodo del grafico.
class ProgressPoint {
  ProgressPoint(this.label, this.start, this.end);
  final String label;
  final DateTime start;

  /// Escluso.
  final DateTime end;
  final Map<BodyRegion, double> strength = {};
  int reps = 0;
}

String dayKeyOf(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDay(String k) => DateTime.parse(k);

const _months = ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Periodi da mostrare, dal più vecchio a oggi.
List<ProgressPoint> progressBuckets(DateTime now, ProgressSpan span) {
  final today = DateTime(now.year, now.month, now.day);
  final out = <ProgressPoint>[];
  for (var i = span.buckets - 1; i >= 0; i--) {
    switch (span) {
      case ProgressSpan.day:
        final d = today.subtract(Duration(days: i));
        out.add(ProgressPoint('${d.day}', d, d.add(const Duration(days: 1))));
      case ProgressSpan.week:
        final monday = today.subtract(Duration(days: today.weekday - 1 + 7 * i));
        final label = appLang == Lang.it
            ? '${monday.day}/${monday.month}'
            : '${monday.month}/${monday.day}';
        out.add(ProgressPoint(label, monday,
            monday.add(const Duration(days: 7))));
      case ProgressSpan.month:
        final m = DateTime(today.year, today.month - i);
        final names = appLang == Lang.it ? _months : _monthsEn;
        out.add(ProgressPoint(names[m.month - 1], m, DateTime(m.year, m.month + 1)));
    }
  }
  return out;
}

/// Riempie i periodi: rep totali e indice di forza per zona (100 = test
/// iniziale). Per ogni esercizio conta la serie migliore del periodo; la zona
/// fa la media degli esercizi allenati.
List<ProgressPoint> computeProgress(
  TrainingHistory history,
  Map<ExerciseId, double> baselineEq,
  DateTime now,
  ProgressSpan span,
) {
  final points = progressBuckets(now, span);
  for (final p in points) {
    final best = <BodyRegion, Map<ExerciseId, double>>{};
    for (final day in history.entries) {
      final d = _parseDay(day.key);
      if (d.isBefore(p.start) || !d.isBefore(p.end)) continue;
      for (final e in day.value.values) {
        p.reps += e.reps;
        final r = e.region;
        if (r == null) continue;
        final m = best.putIfAbsent(r, () => {});
        m[e.trackAs] = max(m[e.trackAs] ?? 0, e.bestEq);
      }
    }
    best.forEach((region, perExercise) {
      final ratios = [
        for (final e in perExercise.entries)
          if ((baselineEq[e.key] ?? 0) > 0) e.value / baselineEq[e.key]!,
      ];
      if (ratios.isEmpty) return;
      p.strength[region] = 100 * ratios.reduce((a, b) => a + b) / ratios.length;
    });
  }
  return points;
}

/// Riepilogo di un esercizio per la pagina di dettaglio.
class ExerciseSummary {
  ExerciseSummary(this.name, this.trackAs);

  /// Il nome come sta nello storico (italiano): è la chiave.
  final String name;

  /// Il nome tradotto, da mostrare.
  String get label => tr(name);
  final ExerciseId trackAs;
  int repsInPeriod = 0;
  int daysInPeriod = 0;
  int record = 0;
  String? recordDay;
  int lastBest = 0;
  String? lastDay;

  /// Media della serie migliore nei giorni prima dell'ultimo.
  double usualBest = 0;
}

List<ExerciseSummary> exerciseSummaries(TrainingHistory history, DateTime from) {
  final byName = <String, ExerciseSummary>{};
  final bestSets = <String, List<int>>{};
  final days = history.keys.toList()..sort();
  for (final day in days) {
    for (final e in history[day]!.entries) {
      final s = byName.putIfAbsent(e.key, () => ExerciseSummary(e.key, e.value.trackAs));
      final x = e.value;
      if (!_parseDay(day).isBefore(from)) {
        s.repsInPeriod += x.reps;
        s.daysInPeriod++;
      }
      if (x.bestSet > s.record) {
        s.record = x.bestSet;
        s.recordDay = day;
      }
      bestSets.putIfAbsent(e.key, () => []).add(x.bestSet);
      s.lastBest = x.bestSet;
      s.lastDay = day;
    }
  }
  for (final s in byName.values) {
    final all = bestSets[s.name]!;
    final before = all.sublist(0, all.length - 1);
    s.usualBest = before.isEmpty ? 0 : before.reduce((a, b) => a + b) / before.length;
  }
  final list = byName.values.toList()
    ..sort((a, b) => (b.lastDay ?? '').compareTo(a.lastDay ?? ''));
  return list;
}
