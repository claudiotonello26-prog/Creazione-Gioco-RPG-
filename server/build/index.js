"use strict";
// Regole dell'Arena Pura lato server. Specchiano lib/domain/pvp.dart e le
// soglie di lib/pose/rep_counter.dart nell'app: se cambiano lì, vanno
// cambiate anche qui.
//
// Funzioni pure, senza API di Nakama, così i test le eseguono in Node.
var ARENA_CHALLENGES = {
    pushUp: { goal: 'fastestReps', targetReps: 20, seconds: 0, perLeg: false },
    squat: { goal: 'fastestReps', targetReps: 30, seconds: 0, perLeg: false },
    lunge: { goal: 'fastestReps', targetReps: 20, seconds: 0, perLeg: true },
    crunch: { goal: 'fastestReps', targetReps: 30, seconds: 0, perLeg: false },
    jumpingJack: { goal: 'mostRepsInTime', targetReps: 0, seconds: 60, perLeg: false },
    plank: { goal: 'longestHold', targetReps: 0, seconds: 0, perLeg: false },
};
var ARENA_DIVISIONS = ['recruit', 'squire', 'knight', 'champion'];
/** Durata massima di un duello, in secondi. */
var ARENA_MAX_SECONDS = 180;
var ARENA_MAX_HOLD_SECONDS = 600;
/** Ordine dei punti dello scheletro nei messaggi POSE (come l'enum Joint). */
var JOINT = {
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
function arenaAngle(k, a, b, c) {
    var pa = k[a], pb = k[b], pc = k[c];
    if (!pa || !pb || !pc)
        return null;
    if (pa[2] < 0.5 || pb[2] < 0.5 || pc[2] < 0.5)
        return null;
    var v1x = pa[0] - pb[0], v1y = pa[1] - pb[1];
    var v2x = pc[0] - pb[0], v2y = pc[1] - pb[1];
    var n1 = Math.sqrt(v1x * v1x + v1y * v1y);
    var n2 = Math.sqrt(v2x * v2x + v2y * v2y);
    if (n1 === 0 || n2 === 0)
        return null;
    var cos = (v1x * v2x + v1y * v2y) / (n1 * n2);
    cos = Math.max(-1, Math.min(1, cos));
    return (Math.acos(cos) * 180) / Math.PI;
}
function arenaBilateral(l, r) {
    if (l === null)
        return r;
    if (r === null)
        return l;
    return (l + r) / 2;
}
var J = JOINT;
var ARENA_ANGLES = {
    pushUp: {
        measure: function (k) { return arenaBilateral(arenaAngle(k, J.leftShoulder, J.leftElbow, J.leftWrist), arenaAngle(k, J.rightShoulder, J.rightElbow, J.rightWrist)); },
        down: 100,
        up: 140,
    },
    squat: {
        measure: function (k) { return arenaBilateral(arenaAngle(k, J.leftHip, J.leftKnee, J.leftAnkle), arenaAngle(k, J.rightHip, J.rightKnee, J.rightAnkle)); },
        down: 110,
        up: 145,
    },
    crunch: {
        measure: function (k) { return arenaBilateral(arenaAngle(k, J.leftShoulder, J.leftHip, J.leftKnee), arenaAngle(k, J.rightShoulder, J.rightHip, J.rightKnee)); },
        down: 100,
        up: 115,
    },
    lunge: {
        // La gamba davanti è quella più piegata.
        measure: function (k) {
            var l = arenaAngle(k, J.leftHip, J.leftKnee, J.leftAnkle);
            var r = arenaAngle(k, J.rightHip, J.rightKnee, J.rightAnkle);
            if (l === null)
                return r;
            if (r === null)
                return l;
            return Math.min(l, r);
        },
        down: 105,
        up: 145,
    },
    jumpingJack: {
        measure: function (k) {
            var arms = arenaBilateral(arenaAngle(k, J.leftHip, J.leftShoulder, J.leftWrist), arenaAngle(k, J.rightHip, J.rightShoulder, J.rightWrist));
            return arms === null ? null : 180 - arms;
        },
        down: 50,
        up: 130,
    },
};
/** Margine di tolleranza sulle soglie: lo scheletro arriva a ~10 fps. */
var ARENA_ANGLE_TOLERANCE = 8;
var ARENA_MIN_REP_MS = 350;
var ARENA_POSE_WINDOW_MS = 4000;
function arenaSample(exercise, k, t) {
    if (exercise === 'plank') {
        var body = arenaBilateral(arenaAngle(k, J.leftShoulder, J.leftHip, J.leftAnkle), arenaAngle(k, J.rightShoulder, J.rightHip, J.rightAnkle));
        return { t: t, angle: body, aligned: body !== null && body >= 155 };
    }
    var def = ARENA_ANGLES[exercise];
    return { t: t, angle: def ? def.measure(k) : null, aligned: false };
}
/**
 * Anti-cheat: una rep dichiarata dal telefono vale solo se lo scheletro
 * trasmesso, dopo l'ultima rep accettata, è sceso sotto la soglia e poi
 * risalito, e se il ritmo è umano.
 */
function arenaValidateRep(exercise, samples, lastAcceptedMs, nowMs) {
    var def = ARENA_ANGLES[exercise];
    if (!def)
        return false;
    if (nowMs - lastAcceptedMs < ARENA_MIN_REP_MS)
        return false;
    var from = Math.max(lastAcceptedMs, nowMs - ARENA_POSE_WINDOW_MS);
    var wentDown = false;
    var cameUp = false;
    for (var i = 0; i < samples.length; i++) {
        var s = samples[i];
        if (s.t < from || s.angle === null)
            continue;
        if (!wentDown) {
            if (s.angle <= def.down + ARENA_ANGLE_TOLERANCE)
                wentDown = true;
        }
        else if (s.angle >= def.up - ARENA_ANGLE_TOLERANCE) {
            cameUp = true;
            break;
        }
    }
    return wentDown && cameUp;
}
/** Secondi di plank tenuti, sommando solo gli intervalli brevi tra frame allineati. */
function arenaHeldSeconds(samples) {
    var held = 0;
    for (var i = 1; i < samples.length; i++) {
        var a = samples[i - 1], b = samples[i];
        var gap = b.t - a.t;
        if (a.aligned && b.aligned && gap > 0 && gap <= 600)
            held += gap;
    }
    return held / 1000;
}
var ARENA_QUALITY = { perfect: 1.0, good: 0.85, poor: 0.6 };
function arenaFormScore(qualities) {
    if (qualities.length === 0)
        return 0;
    var sum = 0;
    for (var i = 0; i < qualities.length; i++)
        sum += ARENA_QUALITY[qualities[i]] || 0;
    return sum / qualities.length;
}
/** >0 se vince a, <0 se vince b, 0 pareggio. Come compareResults in Dart. */
function arenaCompare(c, a, b) {
    var primary = 0;
    if (c.goal === 'fastestReps') {
        if (a.completed !== b.completed)
            return a.completed ? 1 : -1;
        primary = a.completed ? b.seconds - a.seconds : a.validReps - b.validReps;
    }
    else if (c.goal === 'mostRepsInTime') {
        primary = a.validReps - b.validReps;
    }
    else {
        primary = a.seconds - b.seconds;
    }
    if (primary !== 0)
        return primary > 0 ? 1 : -1;
    var f = a.formScore - b.formScore;
    return f > 0 ? 1 : f < 0 ? -1 : 0;
}
/** Punti stagione: +25 vittoria, −15 sconfitta, +5 pareggio, mai sotto 0. */
function arenaRankDelta(cmp) {
    return cmp > 0 ? 25 : cmp < 0 ? -15 : 5;
}
function arenaSeasonTitle(points) {
    if (points >= 1600)
        return 'Campione della Stagione';
    if (points >= 1300)
        return "Cavaliere d'Arena";
    if (points >= 1100)
        return "Scudiero d'Arena";
    return "Recluta d'Arena";
}
// Duello autoritativo dell'Arena Pura. Il server riceve solo i punti dello
// scheletro e le rep dichiarate dal telefono, verifica le rep e decide il
// vincitore. Nessuna immagine passa dal server.
var ARENA_OP = {
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
var ARENA_TICK_RATE = 10;
var ARENA_TICK_MS = 1000 / ARENA_TICK_RATE;
var ARENA_COUNTDOWN_TICKS = 5 * ARENA_TICK_RATE;
var ARENA_JOIN_TIMEOUT_TICKS = 30 * ARENA_TICK_RATE;
var ARENA_LINGER_TICKS = 3 * ARENA_TICK_RATE;
/** Il plank finisce dopo 2 secondi fuori posizione. */
var ARENA_HOLD_BREAK_MS = 2000;
function arenaNewPlayer(p) {
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
function arenaElapsedMs(state, tick) {
    return state.phase === 'running' || state.phase === 'finished'
        ? (tick - state.phaseTick) * ARENA_TICK_MS
        : 0;
}
function arenaValidReps(state, p) {
    return state.challenge.perLeg ? Math.floor(p.reps.length / 2) : p.reps.length;
}
function arenaPlayerResult(state, p, nowMs) {
    var c = state.challenge;
    var reps = arenaValidReps(state, p);
    var seconds;
    if (c.goal === 'longestHold')
        seconds = p.heldMs / 1000;
    else if (c.goal === 'fastestReps')
        seconds = (p.done ? p.doneMs : nowMs) / 1000;
    else
        seconds = c.seconds;
    return {
        validReps: reps,
        seconds: seconds,
        formScore: arenaFormScore(p.reps),
        completed: c.goal !== 'fastestReps' || reps >= c.targetReps,
    };
}
function arenaPlayerIds(state) {
    return Object.keys(state.players);
}
function arenaPresences(state) {
    var out = [];
    var ids = arenaPlayerIds(state);
    for (var i = 0; i < ids.length; i++) {
        var p = state.players[ids[i]];
        if (p.presence && !p.left)
            out.push(p.presence);
    }
    return out;
}
function arenaBroadcastState(dispatcher, state, tick) {
    var now = arenaElapsedMs(state, tick);
    var players = {};
    var ids = arenaPlayerIds(state);
    for (var i = 0; i < ids.length; i++) {
        var p = state.players[ids[i]];
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
    var countdown = state.phase === 'countdown'
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
function arenaHandleMessage(state, tick, userId, opCode, payload, receiveTimeMs) {
    var p = state.players[userId];
    if (!p || p.left)
        return {};
    if (opCode === ARENA_OP.READY && state.phase === 'waiting') {
        p.ready = true;
        return {};
    }
    if (state.phase !== 'running' || p.done)
        return {};
    // L'ora di arrivo del messaggio è più precisa del tick (100 ms).
    var now = receiveTimeMs !== undefined && state.startWallMs > 0
        ? Math.max(0, receiveTimeMs - state.startWallMs)
        : arenaElapsedMs(state, tick);
    var msg;
    try {
        msg = JSON.parse(payload || '{}');
    }
    catch (e) {
        return {};
    }
    if (opCode === ARENA_OP.POSE && msg && msg.k && msg.k.length >= 13) {
        var s = arenaSample(state.exercise, msg.k, now);
        if (state.exercise === 'plank') {
            var prev = p.lastSample;
            if (prev && prev.aligned && s.aligned && s.t - prev.t <= 600)
                p.heldMs += s.t - prev.t;
            if (s.aligned)
                p.lastAlignedMs = s.t;
            p.lastSample = s;
        }
        else {
            p.samples.push(s);
            while (p.samples.length > 0 && p.samples[0].t < now - ARENA_POSE_WINDOW_MS)
                p.samples.shift();
        }
        return {};
    }
    if (opCode === ARENA_OP.REP && state.exercise !== 'plank') {
        var q = msg && ARENA_QUALITY[msg.q] !== undefined ? msg.q : 'good';
        if (!arenaValidateRep(state.exercise, p.samples, p.lastRepMs, now)) {
            p.rejected++;
            return { rejected: true };
        }
        p.reps.push(q);
        p.lastRepMs = now;
        // La rep consumata non può validarne un'altra.
        p.samples = [];
        var c = state.challenge;
        if (c.goal === 'fastestReps' && arenaValidReps(state, p) >= c.targetReps) {
            p.done = true;
            p.doneMs = now;
        }
    }
    return {};
}
/** Avanza fasi e condizioni di fine. Ritorna true quando il duello è finito. */
function arenaAdvance(state, tick, wallMs) {
    var ids = arenaPlayerIds(state);
    if (state.phase === 'waiting') {
        var readyCount = 0;
        for (var i = 0; i < ids.length; i++)
            if (state.players[ids[i]].ready)
                readyCount++;
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
    if (state.phase !== 'running')
        return false;
    var now = wallMs && state.startWallMs > 0
        ? wallMs - state.startWallMs
        : arenaElapsedMs(state, tick);
    var c = state.challenge;
    var allDone = true;
    var anyLeft = false;
    for (var i = 0; i < ids.length; i++) {
        var p = state.players[ids[i]];
        if (p.left)
            anyLeft = true;
        if (c.goal === 'longestHold' && !p.done && p.heldMs > 0 &&
            now - p.lastAlignedMs > ARENA_HOLD_BREAK_MS) {
            p.done = true;
            p.doneMs = now;
        }
        if (!p.done)
            allDone = false;
    }
    var limit = c.goal === 'mostRepsInTime'
        ? c.seconds
        : c.goal === 'longestHold' ? ARENA_MAX_HOLD_SECONDS : ARENA_MAX_SECONDS;
    return anyLeft || allDone || now >= limit * 1000;
}
/** Calcola il risultato. Chi abbandona perde a tavolino. */
function arenaComputeResult(state, tick) {
    var now = arenaElapsedMs(state, tick);
    var ids = arenaPlayerIds(state);
    var results = {};
    for (var i = 0; i < ids.length; i++) {
        results[ids[i]] = arenaPlayerResult(state, state.players[ids[i]], now);
    }
    var cmp = 0;
    if (ids.length === 2) {
        var a = state.players[ids[0]], b = state.players[ids[1]];
        if (a.left !== b.left)
            cmp = a.left ? -1 : 1;
        else
            cmp = arenaCompare(state.challenge, results[ids[0]], results[ids[1]]);
    }
    var winner = ids.length < 2 ? null : cmp > 0 ? ids[0] : cmp < 0 ? ids[1] : null;
    for (var i = 0; i < ids.length; i++) {
        var mine = i === 0 ? cmp : -cmp;
        results[ids[i]].outcome = mine;
        results[ids[i]].delta = ids.length === 2 ? arenaRankDelta(mine) : 0;
        results[ids[i]].name = state.players[ids[i]].username;
        results[ids[i]].forfeit = state.players[ids[i]].left;
    }
    return { winner: winner, exercise: state.exercise, results: results };
}
function arenaSaveResult(nk, logger, state, result) {
    var ids = Object.keys(result.results);
    for (var i = 0; i < ids.length; i++) {
        var id = ids[i];
        var r = result.results[id];
        try {
            var points = arenaAddSeasonPoints(nk, id, r.delta);
            r.points = points;
            nk.leaderboardRecordWrite(ARENA_SEASON_BOARD, id, r.name, points);
            var c = state.challenge;
            var board = ARENA_BEST_BOARD_PREFIX + state.exercise;
            if (c.goal === 'fastestReps' && r.completed && !r.forfeit) {
                // Classifica ascendente in millisecondi.
                nk.leaderboardRecordWrite(board, id, r.name, Math.round(r.seconds * 1000));
            }
            else if (c.goal === 'mostRepsInTime') {
                nk.leaderboardRecordWrite(board, id, r.name, r.validReps);
            }
            else if (c.goal === 'longestHold') {
                nk.leaderboardRecordWrite(board, id, r.name, Math.round(r.seconds));
            }
        }
        catch (e) {
            logger.error('Salvataggio risultato arena fallito per %s: %s', id, String(e));
        }
    }
}
// ----------------------------------------------------------------- handler
function arenaMatchInit(ctx, logger, nk, params) {
    var exercise = ARENA_CHALLENGES[params.exercise] ? params.exercise : 'pushUp';
    var state = {
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
function arenaMatchJoinAttempt(ctx, logger, nk, dispatcher, tick, state, presence, metadata) {
    var s = state;
    if (s.phase !== 'waiting')
        return { state: s, accept: false, rejectMessage: 'Duello già iniziato' };
    if (s.expected.length > 0 && s.expected.indexOf(presence.userId) < 0) {
        return { state: s, accept: false, rejectMessage: 'Non sei in questo duello' };
    }
    if (!s.players[presence.userId] && Object.keys(s.players).length >= 2) {
        return { state: s, accept: false, rejectMessage: 'Duello pieno' };
    }
    return { state: s, accept: true };
}
function arenaMatchJoin(ctx, logger, nk, dispatcher, tick, state, presences) {
    var s = state;
    for (var i = 0; i < presences.length; i++) {
        var p = presences[i];
        var existing = s.players[p.userId];
        if (existing) {
            existing.presence = p;
            existing.left = false;
        }
        else {
            s.players[p.userId] = arenaNewPlayer(p);
        }
    }
    arenaBroadcastState(dispatcher, s, tick);
    return { state: s };
}
function arenaMatchLeave(ctx, logger, nk, dispatcher, tick, state, presences) {
    var s = state;
    for (var i = 0; i < presences.length; i++) {
        var p = s.players[presences[i].userId];
        if (!p)
            continue;
        if (s.phase === 'waiting')
            delete s.players[presences[i].userId];
        else
            p.left = true;
    }
    if (arenaPresences(s).length === 0 && s.phase !== 'running')
        return null;
    return { state: s };
}
function arenaMatchLoop(ctx, logger, nk, dispatcher, tick, state, messages) {
    var s = state;
    if (s.createdTick === 0)
        s.createdTick = tick;
    var _loop_1 = function (i) {
        var m = messages[i];
        var payload = nk.binaryToString(m.data);
        var r = arenaHandleMessage(s, tick, m.sender.userId, m.opCode, payload, m.receiveTimeMs);
        if (r.rejected) {
            dispatcher.broadcastMessage(ARENA_OP.REP_REJECTED, '{}', [m.sender]);
        }
        if (m.opCode === ARENA_OP.POSE && s.phase === 'running') {
            // Solo lo scheletro arriva all'avversario, che lo usa per l'avatar.
            var others = arenaPresences(s).filter(function (p) { return p.userId !== m.sender.userId; });
            if (others.length > 0) {
                dispatcher.broadcastMessage(ARENA_OP.POSE_RELAY, '{"u":"' + m.sender.userId + '","k":' + arenaExtractPose(payload) + '}', others, null, false);
            }
        }
    };
    for (var i = 0; i < messages.length; i++) {
        _loop_1(i);
    }
    if (s.phase === 'finished') {
        return tick - s.phaseTick >= ARENA_LINGER_TICKS ? null : { state: s };
    }
    if (s.phase === 'waiting' && tick - s.createdTick > ARENA_JOIN_TIMEOUT_TICKS) {
        logger.info('Duello abbandonato prima di iniziare');
        return null;
    }
    var ended = arenaAdvance(s, tick, Date.now());
    if (ended) {
        s.result = arenaComputeResult(s, tick);
        s.phase = 'finished';
        s.phaseTick = tick;
        arenaSaveResult(nk, logger, s, s.result);
        dispatcher.broadcastMessage(ARENA_OP.RESULT, JSON.stringify(s.result));
    }
    if (tick % 2 === 0 || ended)
        arenaBroadcastState(dispatcher, s, tick);
    return { state: s };
}
function arenaExtractPose(payload) {
    try {
        var msg = JSON.parse(payload);
        return JSON.stringify(msg.k || []);
    }
    catch (e) {
        return '[]';
    }
}
function arenaMatchTerminate(ctx, logger, nk, dispatcher, tick, state, graceSeconds) {
    return { state: state };
}
function arenaMatchSignal(ctx, logger, nk, dispatcher, tick, state, data) {
    return { state: state };
}
// Modulo server di Iron Oath per Nakama: Arena Pura live e classifiche.
var ARENA_MATCH_MODULE = 'arena_duel';
var ARENA_SEASON_BOARD = 'arena_season';
var ARENA_BEST_BOARD_PREFIX = 'arena_best_';
var ARENA_START_POINTS = 1000;
var ARENA_STORAGE = 'arena';
function arenaReadSeasonPoints(nk, userId) {
    var objs = nk.storageRead([{ collection: ARENA_STORAGE, key: 'season', userId: userId }]);
    if (objs.length === 0)
        return ARENA_START_POINTS;
    var v = objs[0].value;
    return typeof v.points === 'number' ? v.points : ARENA_START_POINTS;
}
function arenaAddSeasonPoints(nk, userId, delta) {
    var points = Math.max(0, arenaReadSeasonPoints(nk, userId) + delta);
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
function arenaMatchmakerMatched(ctx, logger, nk, matches) {
    if (matches.length === 0)
        return;
    var exercise = String(matches[0].properties.exercise || 'pushUp');
    var players = [];
    for (var i = 0; i < matches.length; i++)
        players.push(matches[i].presence.userId);
    return nk.matchCreate(ARENA_MATCH_MODULE, { exercise: exercise, players: players.join(',') });
}
/** Punti stagione, titolo e posizione del giocatore. */
function rpcArenaProfile(ctx, logger, nk, payload) {
    var userId = ctx.userId || '';
    var points = arenaReadSeasonPoints(nk, userId);
    var list = nk.leaderboardRecordsList(ARENA_SEASON_BOARD, [userId], 1);
    var own = list.ownerRecords && list.ownerRecords.length > 0 ? list.ownerRecords[0] : null;
    return JSON.stringify({
        points: points,
        title: arenaSeasonTitle(points),
        rank: own ? own.rank : null,
    });
}
/** Prime 20 posizioni della stagione o di un esercizio. */
function rpcArenaTop(ctx, logger, nk, payload) {
    var board = ARENA_SEASON_BOARD;
    try {
        var req = JSON.parse(payload || '{}');
        if (req.exercise && ARENA_CHALLENGES[req.exercise])
            board = ARENA_BEST_BOARD_PREFIX + req.exercise;
    }
    catch (e) {
        // Payload non valido: classifica di stagione.
    }
    var list = nk.leaderboardRecordsList(board, null, 20);
    var records = (list.records || []).map(function (r) { return ({
        rank: r.rank,
        name: r.username,
        score: r.score,
    }); });
    return JSON.stringify({ board: board, records: records });
}
function InitModule(ctx, logger, nk, initializer) {
    // Stagioni di 8 settimane: reset il primo lunedì di ogni bimestre.
    nk.leaderboardCreate(ARENA_SEASON_BOARD, true, 'descending', 'set', '0 0 1 */2 *');
    var exercises = Object.keys(ARENA_CHALLENGES);
    for (var i = 0; i < exercises.length; i++) {
        var c = ARENA_CHALLENGES[exercises[i]];
        var order = c.goal === 'fastestReps' ? 'ascending' : 'descending';
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
