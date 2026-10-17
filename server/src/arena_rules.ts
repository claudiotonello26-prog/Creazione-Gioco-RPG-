// Regole dell'Arena Pura lato server. Specchiano lib/domain/pvp.dart e le
// soglie di lib/pose/rep_counter.dart nell'app: se cambiano lì, vanno
// cambiate anche qui.
//
// Funzioni pure, senza API di Nakama, così i test le eseguono in Node.

type ArenaGoal = 'fastestReps' | 'mostRepsInTime' | 'longestHold';
type RepQualityName = 'perfect' | 'good' | 'poor';

interface ArenaChallengeDef {
  goal: ArenaGoal;
  targetReps: number;
  seconds: number;
  perLeg: boolean;
}

const ARENA_CHALLENGES: { [exercise: string]: ArenaChallengeDef } = {
  pushUp: { goal: 'fastestReps', targetReps: 20, seconds: 0, perLeg: false },
  squat: { goal: 'fastestReps', targetReps: 30, seconds: 0, perLeg: false },
  lunge: { goal: 'fastestReps', targetReps: 20, seconds: 0, perLeg: true },
  crunch: { goal: 'fastestReps', targetReps: 30, seconds: 0, perLeg: false },
  jumpingJack: { goal: 'mostRepsInTime', targetReps: 0, seconds: 60, perLeg: false },
  plank: { goal: 'longestHold', targetReps: 0, seconds: 0, perLeg: false },
};

const ARENA_DIVISIONS = ['recruit', 'squire', 'knight', 'champion'];

/** Durata massima di un duello, in secondi. */
const ARENA_MAX_SECONDS = 180;
const ARENA_MAX_HOLD_SECONDS = 600;

/** Ordine dei punti dello scheletro nei messaggi POSE (come l'enum Joint). */
const JOINT = {
  nose: 0,
  leftShoulder: 1,
  rightShoulder: 2,
  leftElbow: 3,
  rightElbow: 4,
  leftWrist: 5,
  rightWrist: 6,
  leftHip: 7,
  rightHip: 8,
  leftKnee: 9,
  rightKnee: 10,
  leftAnkle: 11,
  rightAnkle: 12,
};

/** [x, y, likelihood], coordinate normalizzate. */
type JointPoint = number[];

interface PoseSample {
  /** Millisecondi dall'inizio del duello, orologio del server. */
  t: number;
  /** Angolo di lavoro: basso nella fase contratta, alto in quella estesa. */
  angle: number | null;
  /** Corpo allineato (solo plank). */
  aligned: boolean;
}

function arenaAngle(k: JointPoint[], a: number, b: number, c: number): number | null {
  const pa = k[a], pb = k[b], pc = k[c];
  if (!pa || !pb || !pc) return null;
  if (pa[2] < 0.5 || pb[2] < 0.5 || pc[2] < 0.5) return null;
  const v1x = pa[0] - pb[0], v1y = pa[1] - pb[1];
  const v2x = pc[0] - pb[0], v2y = pc[1] - pb[1];
  const n1 = Math.sqrt(v1x * v1x + v1y * v1y);
  const n2 = Math.sqrt(v2x * v2x + v2y * v2y);
  if (n1 === 0 || n2 === 0) return null;
  let cos = (v1x * v2x + v1y * v2y) / (n1 * n2);
  cos = Math.max(-1, Math.min(1, cos));
  return (Math.acos(cos) * 180) / Math.PI;
}

function arenaBilateral(l: number | null, r: number | null): number | null {
  if (l === null) return r;
  if (r === null) return l;
  return (l + r) / 2;
}

interface WorkingAngleDef {
  measure: (k: JointPoint[]) => number | null;
  /** Sotto questa soglia la fase contratta è valida. */
  down: number;
  /** Sopra questa soglia la rep è tornata su. */
  up: number;
}

const J = JOINT;

const ARENA_ANGLES: { [exercise: string]: WorkingAngleDef } = {
  pushUp: {
    measure: (k) => arenaBilateral(
      arenaAngle(k, J.leftShoulder, J.leftElbow, J.leftWrist),
      arenaAngle(k, J.rightShoulder, J.rightElbow, J.rightWrist)),
    down: 100,
    up: 140,
  },
  squat: {
    measure: (k) => arenaBilateral(
      arenaAngle(k, J.leftHip, J.leftKnee, J.leftAnkle),
      arenaAngle(k, J.rightHip, J.rightKnee, J.rightAnkle)),
    down: 110,
    up: 145,
  },
  crunch: {
    measure: (k) => arenaBilateral(
      arenaAngle(k, J.leftShoulder, J.leftHip, J.leftKnee),
      arenaAngle(k, J.rightShoulder, J.rightHip, J.rightKnee)),
    down: 100,
    up: 115,
  },
  lunge: {
    // La gamba davanti è quella più piegata.
    measure: (k) => {
      const l = arenaAngle(k, J.leftHip, J.leftKnee, J.leftAnkle);
      const r = arenaAngle(k, J.rightHip, J.rightKnee, J.rightAnkle);
      if (l === null) return r;
      if (r === null) return l;
      return Math.min(l, r);
    },
    down: 105,
    up: 145,
  },
  jumpingJack: {
    measure: (k) => {
      const arms = arenaBilateral(
        arenaAngle(k, J.leftHip, J.leftShoulder, J.leftWrist),
        arenaAngle(k, J.rightHip, J.rightShoulder, J.rightWrist));
      return arms === null ? null : 180 - arms;
    },
    down: 50,
    up: 130,
  },
};

/** Margine di tolleranza sulle soglie: lo scheletro arriva a ~10 fps. */
const ARENA_ANGLE_TOLERANCE = 8;
const ARENA_MIN_REP_MS = 350;
const ARENA_POSE_WINDOW_MS = 4000;

function arenaSample(exercise: string, k: JointPoint[], t: number): PoseSample {
  if (exercise === 'plank') {
    const body = arenaBilateral(
      arenaAngle(k, J.leftShoulder, J.leftHip, J.leftAnkle),
      arenaAngle(k, J.rightShoulder, J.rightHip, J.rightAnkle));
    return { t: t, angle: body, aligned: body !== null && body >= 155 };
  }
  const def = ARENA_ANGLES[exercise];
  return { t: t, angle: def ? def.measure(k) : null, aligned: false };
}

/**
 * Anti-cheat: una rep dichiarata dal telefono vale solo se lo scheletro
 * trasmesso, dopo l'ultima rep accettata, è sceso sotto la soglia e poi
 * risalito, e se il ritmo è umano.
 */
function arenaValidateRep(
  exercise: string,
  samples: PoseSample[],
  lastAcceptedMs: number,
  nowMs: number,
): boolean {
  const def = ARENA_ANGLES[exercise];
  if (!def) return false;
  if (nowMs - lastAcceptedMs < ARENA_MIN_REP_MS) return false;
  const from = Math.max(lastAcceptedMs, nowMs - ARENA_POSE_WINDOW_MS);
  let wentDown = false;
  let cameUp = false;
  for (let i = 0; i < samples.length; i++) {
    const s = samples[i];
    if (s.t < from || s.angle === null) continue;
    if (!wentDown) {
      if (s.angle <= def.down + ARENA_ANGLE_TOLERANCE) wentDown = true;
    } else if (s.angle >= def.up - ARENA_ANGLE_TOLERANCE) {
      cameUp = true;
      break;
    }
  }
  return wentDown && cameUp;
}

/** Secondi di plank tenuti, sommando solo gli intervalli brevi tra frame allineati. */
function arenaHeldSeconds(samples: PoseSample[]): number {
  let held = 0;
  for (let i = 1; i < samples.length; i++) {
    const a = samples[i - 1], b = samples[i];
    const gap = b.t - a.t;
    if (a.aligned && b.aligned && gap > 0 && gap <= 600) held += gap;
  }
  return held / 1000;
}

interface ArenaPlayerResult {
  validReps: number;
  seconds: number;
  formScore: number;
  completed: boolean;
}

const ARENA_QUALITY: { [q: string]: number } = { perfect: 1.0, good: 0.85, poor: 0.6 };

function arenaFormScore(qualities: string[]): number {
  if (qualities.length === 0) return 0;
  let sum = 0;
  for (let i = 0; i < qualities.length; i++) sum += ARENA_QUALITY[qualities[i]] || 0;
  return sum / qualities.length;
}

/** >0 se vince a, <0 se vince b, 0 pareggio. Come compareResults in Dart. */
function arenaCompare(c: ArenaChallengeDef, a: ArenaPlayerResult, b: ArenaPlayerResult): number {
  let primary = 0;
  if (c.goal === 'fastestReps') {
    if (a.completed !== b.completed) return a.completed ? 1 : -1;
    primary = a.completed ? b.seconds - a.seconds : a.validReps - b.validReps;
  } else if (c.goal === 'mostRepsInTime') {
    primary = a.validReps - b.validReps;
  } else {
    primary = a.seconds - b.seconds;
  }
  if (primary !== 0) return primary > 0 ? 1 : -1;
  const f = a.formScore - b.formScore;
  return f > 0 ? 1 : f < 0 ? -1 : 0;
}

/** Punti stagione: +25 vittoria, −15 sconfitta, +5 pareggio, mai sotto 0. */
function arenaRankDelta(cmp: number): number {
  return cmp > 0 ? 25 : cmp < 0 ? -15 : 5;
}

function arenaSeasonTitle(points: number): string {
  if (points >= 1600) return 'Campione della Stagione';
  if (points >= 1300) return "Cavaliere d'Arena";
  if (points >= 1100) return "Scudiero d'Arena";
  return "Recluta d'Arena";
}
