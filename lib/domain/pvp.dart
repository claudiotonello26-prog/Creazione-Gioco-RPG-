import 'dart:math';

import 'combat.dart';
import 'exercise.dart';

/// Arena Pura: niente statistiche né build, conta solo l'allenamento.
enum Division {
  recruit('Recluta'),
  squire('Scudiero'),
  knight('Cavaliere'),
  champion('Campione');

  const Division(this.label);
  final String label;
}

enum ChallengeGoal {
  /// Fai N rep valide: vince il tempo più basso.
  fastestReps,

  /// Più rep valide in un tempo fisso.
  mostRepsInTime,

  /// Chi resiste di più (plank).
  longestHold,
}

class ArenaChallenge {
  const ArenaChallenge({
    required this.exercise,
    required this.goal,
    this.targetReps = 0,
    this.seconds = 0,
  });

  final ExerciseId exercise;
  final ChallengeGoal goal;
  final int targetReps;
  final int seconds;

  String get description => switch (goal) {
        ChallengeGoal.fastestReps =>
          '$targetReps rep valide${exercises[exercise]!.perLeg ? ' per gamba' : ''}: vince il tempo più basso',
        ChallengeGoal.mostRepsInTime => '$seconds secondi: vince chi fa più rep valide',
        ChallengeGoal.longestHold => 'Vince chi resiste di più',
      };
}

const Map<ExerciseId, ArenaChallenge> arenaChallenges = {
  ExerciseId.pushUp:
      ArenaChallenge(exercise: ExerciseId.pushUp, goal: ChallengeGoal.fastestReps, targetReps: 20),
  ExerciseId.squat:
      ArenaChallenge(exercise: ExerciseId.squat, goal: ChallengeGoal.fastestReps, targetReps: 30),
  ExerciseId.lunge:
      ArenaChallenge(exercise: ExerciseId.lunge, goal: ChallengeGoal.fastestReps, targetReps: 20),
  ExerciseId.crunch:
      ArenaChallenge(exercise: ExerciseId.crunch, goal: ChallengeGoal.fastestReps, targetReps: 30),
  ExerciseId.jumpingJack: ArenaChallenge(
      exercise: ExerciseId.jumpingJack, goal: ChallengeGoal.mostRepsInTime, seconds: 60),
  ExerciseId.plank: ArenaChallenge(exercise: ExerciseId.plank, goal: ChallengeGoal.longestHold),
};

/// Soglie del record personale (rep, o secondi per il plank) per ogni
/// divisione, come le categorie di peso negli sport.
const Map<ExerciseId, List<int>> divisionThresholds = {
  ExerciseId.pushUp: [0, 15, 30, 50],
  ExerciseId.squat: [0, 30, 45, 60],
  ExerciseId.lunge: [0, 12, 25, 40],
  ExerciseId.crunch: [0, 25, 45, 70],
  ExerciseId.jumpingJack: [0, 45, 65, 85],
  ExerciseId.plank: [0, 45, 90, 180],
};

Division divisionFor(ExerciseId exercise, int record) {
  final t = divisionThresholds[exercise] ?? const [0, 15, 30, 50];
  var d = Division.recruit;
  for (var i = 0; i < t.length; i++) {
    if (record >= t[i]) d = Division.values[i];
  }
  return d;
}

/// Risultato di una prova in Arena.
class ArenaResult {
  const ArenaResult({
    required this.validReps,
    required this.elapsedSeconds,
    required this.formScore,
    this.completed = true,
  });

  final int validReps;
  final double elapsedSeconds;

  /// Media della qualità delle rep (0..1): spareggio a parità di risultato.
  final double formScore;
  final bool completed;

  static double formScoreOf(List<RepQuality> reps) =>
      reps.isEmpty ? 0 : reps.map((q) => q.multiplier).reduce((a, b) => a + b) / reps.length;
}

/// Ritorna >0 se vince [a], <0 se vince [b], 0 in caso di pareggio perfetto.
int compareResults(ArenaChallenge c, ArenaResult a, ArenaResult b) {
  int primary;
  switch (c.goal) {
    case ChallengeGoal.fastestReps:
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      if (!a.completed) {
        primary = a.validReps.compareTo(b.validReps);
      } else {
        primary = b.elapsedSeconds.compareTo(a.elapsedSeconds);
      }
    case ChallengeGoal.mostRepsInTime:
      primary = a.validReps.compareTo(b.validReps);
    case ChallengeGoal.longestHold:
      primary = a.elapsedSeconds.compareTo(b.elapsedSeconds);
  }
  if (primary != 0) return primary;
  return a.formScore.compareTo(b.formScore);
}

/// Avversario dell'Arena. In questa versione è un "fantasma" generato in
/// locale con il ritmo tipico della divisione; il duello live passerà dal
/// backend (solo punti dello scheletro, nessun video).
class ArenaOpponent {
  ArenaOpponent({
    required this.name,
    required this.division,
    required this.secondsPerRep,
    required this.formScore,
    required this.holdSeconds,
  });

  final String name;
  final Division division;
  final double secondsPerRep;
  final double formScore;
  final double holdSeconds;

  static const _names = [
    'Ser Varek',
    'Ildra la Grigia',
    'Fratello Osmund',
    'Kael di Cenere',
    'Maelis',
    'Il Penitente',
    'Thorne',
    'Sorella Vesna',
    'Brann Mezzaluna',
  ];

  factory ArenaOpponent.generate(Division division, {Random? random}) {
    final r = random ?? Random();
    final base = const [2.6, 2.1, 1.7, 1.35][division.index];
    final hold = const [40.0, 75.0, 130.0, 210.0][division.index];
    return ArenaOpponent(
      name: _names[r.nextInt(_names.length)],
      division: division,
      secondsPerRep: base * (0.88 + r.nextDouble() * 0.24),
      formScore: 0.8 + r.nextDouble() * 0.2,
      holdSeconds: hold * (0.8 + r.nextDouble() * 0.4),
    );
  }

  /// Rep valide fatte dopo [seconds] secondi.
  int repsAt(double seconds) => (seconds / secondsPerRep).floor();

  ArenaResult resultFor(ArenaChallenge c) => switch (c.goal) {
        ChallengeGoal.fastestReps => ArenaResult(
            validReps: c.targetReps,
            elapsedSeconds: c.targetReps * secondsPerRep,
            formScore: formScore),
        ChallengeGoal.mostRepsInTime => ArenaResult(
            validReps: repsAt(c.seconds.toDouble()),
            elapsedSeconds: c.seconds.toDouble(),
            formScore: formScore),
        ChallengeGoal.longestHold =>
          ArenaResult(validReps: 0, elapsedSeconds: holdSeconds, formScore: formScore),
      };
}

/// Punti classifica della stagione: +25 vittoria, −15 sconfitta.
int rankDelta(int comparison) => comparison > 0 ? 25 : (comparison < 0 ? -15 : 5);

/// arena: duello classificato; friendly: sfida tra amici senza punti;
/// group: allenamento di gilda fino a quattro.
enum LiveMode { arena, friendly, group }
