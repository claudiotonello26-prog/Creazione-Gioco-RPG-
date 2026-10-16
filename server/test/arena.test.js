const test = require('node:test');
const assert = require('node:assert');
const { loadModule, armPose, plankPose } = require('./load');

const m = loadModule();
const OP = m.__exports.ARENA_OP;

function newMatch(exercise) {
  const init = m.arenaMatchInit({}, null, null, { exercise, players: 'a,b' });
  const s = init.state;
  s.players.a = m.arenaNewPlayer({ userId: 'a', username: 'Alda', sessionId: '1', node: 'n' });
  s.players.b = m.arenaNewPlayer({ userId: 'b', username: 'Brann', sessionId: '2', node: 'n' });
  return s;
}

/** Porta il duello in fase running al tick restituito. */
function start(s) {
  m.arenaHandleMessage(s, 1, 'a', OP.READY, '{}');
  m.arenaHandleMessage(s, 1, 'b', OP.READY, '{}');
  m.arenaAdvance(s, 1);
  assert.strictEqual(s.phase, 'countdown');
  const t = 1 + m.__exports.ARENA_COUNTDOWN_TICKS;
  m.arenaAdvance(s, t);
  assert.strictEqual(s.phase, 'running');
  return t;
}

/** Una rep completa di push-up: pose giù, pose su, poi la rep dichiarata. */
function pushUp(s, user, tick, quality) {
  const seq = [170, 120, 80, 80, 120, 165];
  for (let i = 0; i < seq.length; i++) {
    m.arenaHandleMessage(s, tick + i, user, OP.POSE, JSON.stringify({ k: armPose(seq[i]) }));
  }
  return m.arenaHandleMessage(s, tick + seq.length, user, OP.REP, JSON.stringify({ q: quality || 'perfect' }));
}

test('angolo del gomito', () => {
  const k = armPose(90);
  assert.ok(Math.abs(m.arenaAngle(k, 1, 3, 5) - 90) < 1e-6);
});

test('una rep senza scheletro che scende e risale viene rifiutata', () => {
  const s = newMatch('pushUp');
  const t = start(s);
  for (let i = 0; i < 5; i++) {
    m.arenaHandleMessage(s, t + i, 'a', OP.POSE, JSON.stringify({ k: armPose(165) }));
  }
  const r = m.arenaHandleMessage(s, t + 6, 'a', OP.REP, '{"q":"perfect"}');
  assert.strictEqual(r.rejected, true);
  assert.strictEqual(s.players.a.reps.length, 0);
});

test('mezza rep (non scende sotto la soglia) rifiutata', () => {
  const s = newMatch('pushUp');
  const t = start(s);
  [170, 140, 125, 140, 170].forEach((a, i) =>
    m.arenaHandleMessage(s, t + i, 'a', OP.POSE, JSON.stringify({ k: armPose(a) })));
  assert.strictEqual(m.arenaHandleMessage(s, t + 6, 'a', OP.REP, '{}').rejected, true);
});

test('rep vere accettate, rep a raffica rifiutate', () => {
  const s = newMatch('pushUp');
  let t = start(s);
  assert.ok(!pushUp(s, 'a', t).rejected);
  t += 10;
  assert.ok(!pushUp(s, 'a', t).rejected);
  // Seconda dichiarazione subito dopo, senza nuovo movimento.
  assert.strictEqual(m.arenaHandleMessage(s, t + 7, 'a', OP.REP, '{}').rejected, true);
  assert.strictEqual(s.players.a.reps.length, 2);
});

test('20 push-up: vince chi arriva prima, il duello finisce quando entrambi hanno finito', () => {
  const s = newMatch('pushUp');
  let t = start(s);
  for (let i = 0; i < 20; i++) {
    pushUp(s, 'a', t);
    t += 8;
  }
  assert.strictEqual(s.players.a.done, true);
  assert.strictEqual(m.arenaAdvance(s, t), false);
  for (let i = 0; i < 20; i++) {
    pushUp(s, 'b', t);
    t += 8;
  }
  assert.strictEqual(m.arenaAdvance(s, t), true);
  const r = m.arenaComputeResult(s, t);
  assert.strictEqual(r.winner, 'a');
  assert.strictEqual(r.results.a.delta, 25);
  assert.strictEqual(r.results.b.delta, -15);
});

test('chi abbandona perde a tavolino', () => {
  const s = newMatch('squat');
  const t = start(s);
  s.players.a.left = true;
  assert.strictEqual(m.arenaAdvance(s, t + 1), true);
  const r = m.arenaComputeResult(s, t + 1);
  assert.strictEqual(r.winner, 'b');
  assert.strictEqual(r.results.a.forfeit, true);
});

test('jumping jack: finisce a 60 secondi', () => {
  const s = newMatch('jumpingJack');
  const t = start(s);
  assert.strictEqual(m.arenaAdvance(s, t + 599), false);
  assert.strictEqual(m.arenaAdvance(s, t + 600), true);
});

test('plank: conta il tempo allineato e finisce dopo 2 s fuori posizione', () => {
  const s = newMatch('plank');
  const t = start(s);
  for (let i = 0; i <= 50; i++) {
    m.arenaHandleMessage(s, t + i, 'a', OP.POSE, JSON.stringify({ k: plankPose(true) }));
  }
  for (let i = 51; i <= 80; i++) {
    m.arenaHandleMessage(s, t + i, 'a', OP.POSE, JSON.stringify({ k: plankPose(false) }));
  }
  assert.ok(Math.abs(s.players.a.heldMs - 5000) < 1);
  m.arenaAdvance(s, t + 80);
  assert.strictEqual(s.players.a.done, true);
});

test('confronto: a parità di tempo vince la forma migliore', () => {
  const c = m.ARENA_CHALLENGES.pushUp;
  const a = { validReps: 20, seconds: 30, formScore: 0.95, completed: true };
  const b = { validReps: 20, seconds: 30, formScore: 0.8, completed: true };
  assert.strictEqual(m.arenaCompare(c, a, b), 1);
  assert.strictEqual(m.arenaCompare(c, b, a), -1);
});

test('titoli di stagione', () => {
  assert.strictEqual(m.arenaSeasonTitle(1000), "Recluta d'Arena");
  assert.strictEqual(m.arenaSeasonTitle(1650), 'Campione della Stagione');
});
