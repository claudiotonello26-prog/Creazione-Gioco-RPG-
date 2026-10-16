// Duello autoritativo dell'Arena Pura. Il server riceve solo i punti dello
// scheletro e le rep dichiarate dal telefono, verifica le rep e decide il
// vincitore. Nessuna immagine passa dal server.

const ARENA_OP = {
  // Client → server
  READY: 1,
  POSE: 2,
  REP: 3,
  // Server → client
  STATE: 10,
  RESULT: 11,
  POSE_RELAY: 12,
  REP_REJECTED: 13,
};

const ARENA_TICK_RATE = 10;
const ARENA_TICK_MS = 1000 / ARENA_TICK_RATE;
const ARENA_COUNTDOWN_TICKS = 5 * ARENA_TICK_RATE;
const ARENA_JOIN_TIMEOUT_TICKS = 30 * ARENA_TICK_RATE;
const ARENA_LINGER_TICKS = 3 * ARENA_TICK_RATE;
/** Il plank finisce dopo 2 secondi fuori posizione. */
const ARENA_HOLD_BREAK_MS = 2000;

interface ArenaPlayer {
  presence: nkruntime.Presence | null;
  userId: string;
  username: string;
  ready: boolean;
  reps: string[];
  rejected: number;
  lastRepMs: number;
  samples: PoseSample[];
  heldMs: number;
  lastSample: PoseSample | null;
  lastAlignedMs: number;
  done: boolean;
  doneMs: number;
  left: boolean;
}

interface ArenaState extends nkruntime.MatchState {
  exercise: string;
  challenge: ArenaChallengeDef;
  expected: string[];
  players: { [userId: string]: ArenaPlayer };
  phase: 'waiting' | 'countdown' | 'running' | 'finished';
  phaseTick: number;
  /** Ora reale (ms) di inizio del duello: le rep si misurano su questa. */
  startWallMs: number;
  createdTick: number;
  result: any;
}

function arenaNewPlayer(p: nkruntime.Presence): ArenaPlayer {
  return {
    presence: p,
    userId: p.userId,
    username: p.username,
    ready: false,
    reps: [],
    rejected: 0,
    lastRepMs: -10000,
    samples: [],
    heldMs: 0,
    lastSample: null,
    lastAlignedMs: -1,
    done: false,
    doneMs: 0,
    left: false,
  };
}

function arenaElapsedMs(state: ArenaState, tick: number): number {
  return state.phase === 'running' || state.phase === 'finished'
    ? (tick - state.phaseTick) * ARENA_TICK_MS
    : 0;
}

function arenaValidReps(state: ArenaState, p: ArenaPlayer): number {
  return state.challenge.perLeg ? Math.floor(p.reps.length / 2) : p.reps.length;
}

function arenaPlayerResult(state: ArenaState, p: ArenaPlayer, nowMs: number): ArenaPlayerResult {
  const c = state.challenge;
  const reps = arenaValidReps(state, p);
  let seconds: number;
  if (c.goal === 'longestHold') seconds = p.heldMs / 1000;
  else if (c.goal === 'fastestReps') seconds = (p.done ? p.doneMs : nowMs) / 1000;
  else seconds = c.seconds;
  return {
    validReps: reps,
    seconds: seconds,
    formScore: arenaFormScore(p.reps),
    completed: c.goal !== 'fastestReps' || reps >= c.targetReps,
  };
}

function arenaPlayerIds(state: ArenaState): string[] {
  return Object.keys(state.players);
}

function arenaPresences(state: ArenaState): nkruntime.Presence[] {
  const out: nkruntime.Presence[] = [];
  const ids = arenaPlayerIds(state);
  for (let i = 0; i < ids.length; i++) {
    const p = state.players[ids[i]];
    if (p.presence && !p.left) out.push(p.presence);
  }
  return out;
}

function arenaBroadcastState(dispatcher: nkruntime.MatchDispatcher, state: ArenaState, tick: number) {
  const now = arenaElapsedMs(state, tick);
  const players: { [id: string]: any } = {};
  const ids = arenaPlayerIds(state);
  for (let i = 0; i < ids.length; i++) {
    const p = state.players[ids[i]];
    players[p.userId] = {
      name: p.username,
      ready: p.ready,
      reps: arenaValidReps(state, p),
      rejected: p.rejected,
      held: Math.round(p.heldMs / 100) / 10,
      done: p.done,
      left: p.left,
    };
  }
  const countdown = state.phase === 'countdown'
    ? Math.ceil((ARENA_COUNTDOWN_TICKS - (tick - state.phaseTick)) / ARENA_TICK_RATE)
    : 0;
  dispatcher.broadcastMessage(ARENA_OP.STATE, JSON.stringify({
    phase: state.phase,
    exercise: state.exercise,
    countdown: countdown,
    elapsed: Math.round(now) / 1000,
    players: players,
  }));
}

/** Elabora un messaggio di un giocatore. Esposta per i test. */
function arenaHandleMessage(
  state: ArenaState,
  tick: number,
  userId: string,
  opCode: number,
  payload: string,
  receiveTimeMs?: number,
): { rejected?: boolean } {
  const p = state.players[userId];
  if (!p || p.left) return {};
  if (opCode === ARENA_OP.READY && state.phase === 'waiting') {
    p.ready = true;
    return {};
  }
  if (state.phase !== 'running' || p.done) return {};
  // L'ora di arrivo del messaggio è più precisa del tick (100 ms).
  const now = receiveTimeMs !== undefined && state.startWallMs > 0
    ? Math.max(0, receiveTimeMs - state.startWallMs)
    : arenaElapsedMs(state, tick);
  let msg: any;
  try {
    msg = JSON.parse(payload || '{}');
  } catch (e) {
    return {};
  }
  if (opCode === ARENA_OP.POSE && msg && msg.k && msg.k.length >= 13) {
    const s = arenaSample(state.exercise, msg.k, now);
    if (state.exercise === 'plank') {
      const prev = p.lastSample;
      if (prev && prev.aligned && s.aligned && s.t - prev.t <= 600) p.heldMs += s.t - prev.t;
      if (s.aligned) p.lastAlignedMs = s.t;
      p.lastSample = s;
    } else {
      p.samples.push(s);
      while (p.samples.length > 0 && p.samples[0].t < now - ARENA_POSE_WINDOW_MS) p.samples.shift();
    }
    return {};
  }
  if (opCode === ARENA_OP.REP && state.exercise !== 'plank') {
    const q = msg && ARENA_QUALITY[msg.q] !== undefined ? msg.q : 'good';
    if (!arenaValidateRep(state.exercise, p.samples, p.lastRepMs, now)) {
      p.rejected++;
      return { rejected: true };
    }
    p.reps.push(q);
    p.lastRepMs = now;
    // La rep consumata non può validarne un'altra.
    p.samples = [];
    const c = state.challenge;
    if (c.goal === 'fastestReps' && arenaValidReps(state, p) >= c.targetReps) {
      p.done = true;
      p.doneMs = now;
    }
  }
  return {};
}

/** Avanza fasi e condizioni di fine. Ritorna true quando il duello è finito. */
function arenaAdvance(state: ArenaState, tick: number, wallMs?: number): boolean {
  const ids = arenaPlayerIds(state);
  if (state.phase === 'waiting') {
    let readyCount = 0;
    for (let i = 0; i < ids.length; i++) if (state.players[ids[i]].ready) readyCount++;
    if (ids.length === 2 && readyCount === 2) {
      state.phase = 'countdown';
      state.phaseTick = tick;
    }
    return false;
  }
  if (state.phase === 'countdown') {
    if (tick - state.phaseTick >= ARENA_COUNTDOWN_TICKS) {
      state.phase = 'running';
      state.phaseTick = tick;
      state.startWallMs = wallMs || 0;
    }
    return false;
  }
  if (state.phase !== 'running') return false;

  const now = wallMs && state.startWallMs > 0
    ? wallMs - state.startWallMs
    : arenaElapsedMs(state, tick);
  const c = state.challenge;
  let allDone = true;
  let anyLeft = false;
  for (let i = 0; i < ids.length; i++) {
    const p = state.players[ids[i]];
    if (p.left) anyLeft = true;
    if (c.goal === 'longestHold' && !p.done && p.heldMs > 0 &&
        now - p.lastAlignedMs > ARENA_HOLD_BREAK_MS) {
      p.done = true;
      p.doneMs = now;
    }
    if (!p.done) allDone = false;
  }
  const limit = c.goal === 'mostRepsInTime'
    ? c.seconds
    : c.goal === 'longestHold' ? ARENA_MAX_HOLD_SECONDS : ARENA_MAX_SECONDS;
  return anyLeft || allDone || now >= limit * 1000;
}

/** Calcola il risultato. Chi abbandona perde a tavolino. */
function arenaComputeResult(state: ArenaState, tick: number): any {
  const now = arenaElapsedMs(state, tick);
  const ids = arenaPlayerIds(state);
  const results: { [id: string]: any } = {};
  for (let i = 0; i < ids.length; i++) {
    results[ids[i]] = arenaPlayerResult(state, state.players[ids[i]], now);
  }
  let cmp = 0;
  if (ids.length === 2) {
    const a = state.players[ids[0]], b = state.players[ids[1]];
    if (a.left !== b.left) cmp = a.left ? -1 : 1;
    else cmp = arenaCompare(state.challenge, results[ids[0]], results[ids[1]]);
  }
  const winner = ids.length < 2 ? null : cmp > 0 ? ids[0] : cmp < 0 ? ids[1] : null;
  for (let i = 0; i < ids.length; i++) {
    const mine = i === 0 ? cmp : -cmp;
    results[ids[i]].outcome = mine;
    results[ids[i]].delta = ids.length === 2 ? arenaRankDelta(mine) : 0;
    results[ids[i]].name = state.players[ids[i]].username;
    results[ids[i]].forfeit = state.players[ids[i]].left;
  }
  return { winner: winner, exercise: state.exercise, results: results };
}

function arenaSaveResult(nk: nkruntime.Nakama, logger: nkruntime.Logger, state: ArenaState, result: any) {
  const ids = Object.keys(result.results);
  for (let i = 0; i < ids.length; i++) {
    const id = ids[i];
    const r = result.results[id];
    try {
      const points = arenaAddSeasonPoints(nk, id, r.delta);
      r.points = points;
      nk.leaderboardRecordWrite(ARENA_SEASON_BOARD, id, r.name, points);
      const c = state.challenge;
      const board = ARENA_BEST_BOARD_PREFIX + state.exercise;
      if (c.goal === 'fastestReps' && r.completed && !r.forfeit) {
        // Classifica ascendente in millisecondi.
        nk.leaderboardRecordWrite(board, id, r.name, Math.round(r.seconds * 1000));
      } else if (c.goal === 'mostRepsInTime') {
        nk.leaderboardRecordWrite(board, id, r.name, r.validReps);
      } else if (c.goal === 'longestHold') {
        nk.leaderboardRecordWrite(board, id, r.name, Math.round(r.seconds));
      }
    } catch (e) {
      logger.error('Salvataggio risultato arena fallito per %s: %s', id, String(e));
    }
  }
}

// ----------------------------------------------------------------- handler

function arenaMatchInit(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  params: { [key: string]: string },
): { state: nkruntime.MatchState; tickRate: number; label: string } {
  const exercise = ARENA_CHALLENGES[params.exercise] ? params.exercise : 'pushUp';
  const state: ArenaState = {
    exercise: exercise,
    challenge: ARENA_CHALLENGES[exercise],
    expected: params.players ? params.players.split(',') : [],
    players: {},
    phase: 'waiting',
    phaseTick: 0,
    startWallMs: 0,
    createdTick: 0,
    result: null,
  };
  return {
    state: state,
    tickRate: ARENA_TICK_RATE,
    label: JSON.stringify({ mode: 'arena', exercise: exercise }),
  };
}

function arenaMatchJoinAttempt(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  presence: nkruntime.Presence, metadata: { [key: string]: any },
): { state: nkruntime.MatchState; accept: boolean; rejectMessage?: string } | null {
  const s = state as ArenaState;
  if (s.phase !== 'waiting') return { state: s, accept: false, rejectMessage: 'Duello già iniziato' };
  if (s.expected.length > 0 && s.expected.indexOf(presence.userId) < 0) {
    return { state: s, accept: false, rejectMessage: 'Non sei in questo duello' };
  }
  if (!s.players[presence.userId] && Object.keys(s.players).length >= 2) {
    return { state: s, accept: false, rejectMessage: 'Duello pieno' };
  }
  return { state: s, accept: true };
}

function arenaMatchJoin(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  presences: nkruntime.Presence[],
): { state: nkruntime.MatchState } | null {
  const s = state as ArenaState;
  for (let i = 0; i < presences.length; i++) {
    const p = presences[i];
    const existing = s.players[p.userId];
    if (existing) {
      existing.presence = p;
      existing.left = false;
    } else {
      s.players[p.userId] = arenaNewPlayer(p);
    }
  }
  arenaBroadcastState(dispatcher, s, tick);
  return { state: s };
}

function arenaMatchLeave(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  presences: nkruntime.Presence[],
): { state: nkruntime.MatchState } | null {
  const s = state as ArenaState;
  for (let i = 0; i < presences.length; i++) {
    const p = s.players[presences[i].userId];
    if (!p) continue;
    if (s.phase === 'waiting') delete s.players[presences[i].userId];
    else p.left = true;
  }
  if (arenaPresences(s).length === 0 && s.phase !== 'running') return null;
  return { state: s };
}

function arenaMatchLoop(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  messages: nkruntime.MatchMessage[],
): { state: nkruntime.MatchState } | null {
  const s = state as ArenaState;
  if (s.createdTick === 0) s.createdTick = tick;

  for (let i = 0; i < messages.length; i++) {
    const m = messages[i];
    const payload = nk.binaryToString(m.data);
    const r = arenaHandleMessage(s, tick, m.sender.userId, m.opCode, payload, m.receiveTimeMs);
    if (r.rejected) {
      dispatcher.broadcastMessage(ARENA_OP.REP_REJECTED, '{}', [m.sender]);
    }
    if (m.opCode === ARENA_OP.POSE && s.phase === 'running') {
      // Solo lo scheletro arriva all'avversario, che lo usa per l'avatar.
      const others = arenaPresences(s).filter((p) => p.userId !== m.sender.userId);
      if (others.length > 0) {
        dispatcher.broadcastMessage(
          ARENA_OP.POSE_RELAY,
          '{"u":"' + m.sender.userId + '","k":' + arenaExtractPose(payload) + '}',
          others, null, false);
      }
    }
  }

  if (s.phase === 'finished') {
    return tick - s.phaseTick >= ARENA_LINGER_TICKS ? null : { state: s };
  }
  if (s.phase === 'waiting' && tick - s.createdTick > ARENA_JOIN_TIMEOUT_TICKS) {
    logger.info('Duello abbandonato prima di iniziare');
    return null;
  }

  const ended = arenaAdvance(s, tick, Date.now());
  if (ended) {
    s.result = arenaComputeResult(s, tick);
    s.phase = 'finished';
    s.phaseTick = tick;
    arenaSaveResult(nk, logger, s, s.result);
    dispatcher.broadcastMessage(ARENA_OP.RESULT, JSON.stringify(s.result));
  }
  if (tick % 2 === 0 || ended) arenaBroadcastState(dispatcher, s, tick);
  return { state: s };
}

function arenaExtractPose(payload: string): string {
  try {
    const msg = JSON.parse(payload);
    return JSON.stringify(msg.k || []);
  } catch (e) {
    return '[]';
  }
}

function arenaMatchTerminate(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  graceSeconds: number,
): { state: nkruntime.MatchState } | null {
  return { state: state };
}

function arenaMatchSignal(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  dispatcher: nkruntime.MatchDispatcher, tick: number, state: nkruntime.MatchState,
  data: string,
): { state: nkruntime.MatchState; data?: string } | null {
  return { state: state };
}
