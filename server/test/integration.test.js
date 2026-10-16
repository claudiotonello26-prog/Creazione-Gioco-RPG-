// Test end-to-end contro un Nakama vero con questo modulo caricato.
// Si esegue solo se NAKAMA_URL è impostata, es. NAKAMA_URL=http://127.0.0.1:7350
const test = require('node:test');
const assert = require('node:assert');
const { armPose } = require('./load');

const BASE = process.env.NAKAMA_URL;
const KEY = process.env.NAKAMA_SERVER_KEY || 'defaultkey';

async function auth(deviceId, username) {
  const res = await fetch(`${BASE}/v2/account/authenticate/device?create=true&username=${username}`, {
    method: 'POST',
    headers: {
      Authorization: 'Basic ' + Buffer.from(KEY + ':').toString('base64'),
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ id: deviceId }),
  });
  assert.strictEqual(res.status, 200, await res.clone().text());
  return (await res.json()).token;
}

function userIdOf(token) {
  return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()).uid;
}

function connect(token) {
  const ws = new WebSocket(`${BASE.replace('http', 'ws')}/ws?lang=it&status=true&token=${token}`);
  const inbox = [];
  const waiters = [];
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    inbox.push(msg);
    for (const w of waiters.slice()) {
      if (w.pred(msg)) {
        waiters.splice(waiters.indexOf(w), 1);
        w.resolve(msg);
      }
    }
  };
  const client = {
    ws,
    inbox,
    send: (obj) => ws.send(JSON.stringify(obj)),
    wait: (pred, ms = 15000) =>
      new Promise((resolve, reject) => {
        const found = inbox.find(pred);
        if (found) return resolve(found);
        const w = { pred, resolve };
        waiters.push(w);
        setTimeout(() => reject(new Error('timeout')), ms).unref();
      }),
    data: (matchId, op, obj) =>
      client.send({
        match_data_send: {
          match_id: matchId,
          op_code: String(op),
          data: Buffer.from(JSON.stringify(obj)).toString('base64'),
        },
      }),
  };
  return new Promise((resolve) => (ws.onopen = () => resolve(client)));
}

const decode = (m) => JSON.parse(Buffer.from(m.match_data.data, 'base64').toString());
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

test('duello live di push-up tra due giocatori', { skip: !BASE, timeout: 120000 }, async (t) => {
  const run = Date.now();
  const tA = await auth(`device-a-${run}`, `alda${run}`);
  const tB = await auth(`device-b-${run}`, `brann${run}`);
  const a = await connect(tA);
  const b = await connect(tB);
  t.after(() => {
    a.ws.close();
    b.ws.close();
  });

  for (const c of [a, b]) {
    c.send({
      cid: '1',
      matchmaker_add: {
        min_count: 2,
        max_count: 2,
        query: '+properties.exercise:pushUp',
        string_properties: { exercise: 'pushUp' },
      },
    });
  }
  const mA = await a.wait((m) => m.matchmaker_matched);
  const mB = await b.wait((m) => m.matchmaker_matched);
  const matchId = mA.matchmaker_matched.match_id;
  assert.ok(matchId, 'il server crea un duello autoritativo');
  assert.strictEqual(mB.matchmaker_matched.match_id, matchId);

  a.send({ cid: '2', match_join: { match_id: matchId } });
  b.send({ cid: '2', match_join: { match_id: matchId } });
  await a.wait((m) => m.match);
  await b.wait((m) => m.match);

  a.data(matchId, 1, {});
  b.data(matchId, 1, {});
  await a.wait((m) => m.match_data && m.match_data.op_code === '10' && decode(m).phase === 'running', 20000);

  // A fa 20 rep vere; B dichiara rep senza muoversi (devono essere rifiutate).
  const down = [170, 120, 80, 80, 120, 165];
  for (let r = 0; r < 20; r++) {
    for (const angle of down) {
      a.data(matchId, 2, { k: armPose(angle) });
      b.data(matchId, 2, { k: armPose(170) });
      await sleep(60);
    }
    a.data(matchId, 3, { q: 'perfect' });
    b.data(matchId, 3, { q: 'perfect' });
    await sleep(120);
  }

  const relay = b.inbox.find((m) => m.match_data && m.match_data.op_code === '12');
  assert.ok(relay, "B riceve lo scheletro di A per animare l'avatar");
  assert.strictEqual(decode(relay).u, userIdOf(tA));
  assert.ok(b.inbox.some((m) => m.match_data && m.match_data.op_code === '13'), 'B riceve i rifiuti');

  // B abbandona: il duello si chiude subito con A vincitore.
  b.send({ cid: '3', match_leave: { match_id: matchId } });
  const res = await a.wait((m) => m.match_data && m.match_data.op_code === '11', 20000);
  const result = decode(res);
  const idA = userIdOf(tA);
  assert.strictEqual(result.winner, idA);
  assert.strictEqual(result.results[idA].validReps, 20);
  assert.strictEqual(result.results[idA].points, 1025);

  // La classifica di stagione è aggiornata e leggibile via RPC.
  const rpc = await fetch(`${BASE}/v2/rpc/arena_profile`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${tA}` },
    body: JSON.stringify('{}'),
  });
  const profile = JSON.parse((await rpc.json()).payload);
  assert.strictEqual(profile.points, 1025);

  const top = await fetch(`${BASE}/v2/rpc/arena_top`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${tA}` },
    body: JSON.stringify('{}'),
  });
  const board = JSON.parse((await top.json()).payload);
  assert.ok(board.records.some((r) => r.name === `alda${run}` && r.score === 1025));

});
