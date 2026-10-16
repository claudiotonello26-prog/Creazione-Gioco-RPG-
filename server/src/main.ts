// Modulo server di Iron Oath per Nakama: Arena Pura live e classifiche.

const ARENA_MATCH_MODULE = 'arena_duel';
const ARENA_SEASON_BOARD = 'arena_season';
const ARENA_BEST_BOARD_PREFIX = 'arena_best_';
const ARENA_START_POINTS = 1000;
const ARENA_STORAGE = 'arena';

function arenaReadSeasonPoints(nk: nkruntime.Nakama, userId: string): number {
  const objs = nk.storageRead([{ collection: ARENA_STORAGE, key: 'season', userId: userId }]);
  if (objs.length === 0) return ARENA_START_POINTS;
  const v = objs[0].value;
  return typeof v.points === 'number' ? v.points : ARENA_START_POINTS;
}

function arenaAddSeasonPoints(nk: nkruntime.Nakama, userId: string, delta: number): number {
  const points = Math.max(0, arenaReadSeasonPoints(nk, userId) + delta);
  nk.storageWrite([{
    collection: ARENA_STORAGE,
    key: 'season',
    userId: userId,
    value: { points: points },
    permissionRead: 1,
    // Solo il server scrive i punti.
    permissionWrite: 0,
  }]);
  return points;
}

/** Il matchmaker ha trovato due avversari: crea il duello autoritativo. */
function arenaMatchmakerMatched(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  matches: nkruntime.MatchmakerResult[],
): string | void {
  if (matches.length === 0) return;
  const exercise = String(matches[0].properties.exercise || 'pushUp');
  const players: string[] = [];
  for (let i = 0; i < matches.length; i++) players.push(matches[i].presence.userId);
  return nk.matchCreate(ARENA_MATCH_MODULE, { exercise: exercise, players: players.join(',') });
}

/** Punti stagione, titolo e posizione del giocatore. */
function rpcArenaProfile(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string,
): string {
  const userId = ctx.userId || '';
  const points = arenaReadSeasonPoints(nk, userId);
  const list = nk.leaderboardRecordsList(ARENA_SEASON_BOARD, [userId], 1);
  const own = list.ownerRecords && list.ownerRecords.length > 0 ? list.ownerRecords[0] : null;
  return JSON.stringify({
    points: points,
    title: arenaSeasonTitle(points),
    rank: own ? own.rank : null,
  });
}

/** Prime 20 posizioni della stagione o di un esercizio. */
function rpcArenaTop(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string,
): string {
  let board = ARENA_SEASON_BOARD;
  try {
    const req = JSON.parse(payload || '{}');
    if (req.exercise && ARENA_CHALLENGES[req.exercise]) board = ARENA_BEST_BOARD_PREFIX + req.exercise;
  } catch (e) {
    // Payload non valido: classifica di stagione.
  }
  const list = nk.leaderboardRecordsList(board, null, 20);
  const records = (list.records || []).map((r) => ({
    rank: r.rank,
    name: r.username,
    score: r.score,
  }));
  return JSON.stringify({ board: board, records: records });
}

function InitModule(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
) {
  // Stagioni di 8 settimane: reset il primo lunedì di ogni bimestre.
  nk.leaderboardCreate(ARENA_SEASON_BOARD, true, 'descending', 'set', '0 0 1 */2 *');
  const exercises = Object.keys(ARENA_CHALLENGES);
  for (let i = 0; i < exercises.length; i++) {
    const c = ARENA_CHALLENGES[exercises[i]];
    const order: nkruntime.SortOrder = c.goal === 'fastestReps' ? 'ascending' : 'descending';
    nk.leaderboardCreate(ARENA_BEST_BOARD_PREFIX + exercises[i], true, order, 'best', null);
  }

  initializer.registerMatch(ARENA_MATCH_MODULE, {
    matchInit: arenaMatchInit,
    matchJoinAttempt: arenaMatchJoinAttempt,
    matchJoin: arenaMatchJoin,
    matchLeave: arenaMatchLeave,
    matchLoop: arenaMatchLoop,
    matchTerminate: arenaMatchTerminate,
    matchSignal: arenaMatchSignal,
  });
  initializer.registerMatchmakerMatched(arenaMatchmakerMatched);
  initializer.registerRpc('arena_profile', rpcArenaProfile);
  initializer.registerRpc('arena_top', rpcArenaTop);
  logger.info('Iron Oath: modulo Arena caricato');
}
