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

async function api(token, method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  assert.strictEqual(res.status, 200, `${method} ${path}: ${text}`);
  return text ? JSON.parse(text) : {};
}

const rpcCall = async (token, id, payload) =>
  JSON.parse((await api(token, 'POST', `/v2/rpc/${id}`, JSON.stringify(payload))).payload || '{}');

test('gilda: inviti, sfida tra amici e allenamento insieme', { skip: !BASE, timeout: 60000 }, async (t) => {
  const run = Date.now();
  const tA = await auth(`device-ga-${run}`, `gilda_a${run}`);
  const tB = await auth(`device-gb-${run}`, `gilda_b${run}`);
  const idA = userIdOf(tA), idB = userIdOf(tB);

  // A crea la gilda e invita B (amicizia + aggiunta al gruppo).
  const guild = await api(tA, 'POST', '/v2/group', { name: `Ordine ${run}`, description: 'Prova', open: false, max_count: 50 });
  await api(tA, 'POST', `/v2/friend?usernames=gilda_b${run}`);
  await api(tA, 'POST', `/v2/group/${guild.id}/add?user_ids=${idB}`);
  const mine = await api(tB, 'GET', `/v2/user/${idB}/group?limit=10`);
  assert.ok(mine.user_groups.some((g) => g.group.id === guild.id), 'B è nella gilda');
  const members = await api(tB, 'GET', `/v2/group/${guild.id}/user?limit=50`);
  assert.strictEqual(members.group_users.length, 2);

  // A sfida B: B riceve la notifica e vede la sfida tra le sessioni.
  const duel = await rpcCall(tA, 'guild_session_create', { guild: guild.id, mode: 'friendly', exercise: 'squat', opponent: idB });
  assert.ok(duel.matchId);
  const notes = await api(tB, 'GET', '/v2/notification?limit=10');
  const note = notes.notifications.find((n) => n.code === 100);
  assert.ok(note, 'B riceve la sfida');
  assert.strictEqual(JSON.parse(note.content).matchId, duel.matchId);

  // A apre un allenamento di gilda: B lo vede, un estraneo no.
  const group = await rpcCall(tA, 'guild_session_create', { guild: guild.id, mode: 'group', exercise: 'pushUp' });
  await sleep(1500); // Nakama indicizza le etichette ogni secondo.
  const seen = await rpcCall(tB, 'guild_sessions', { guild: guild.id });
  assert.deepStrictEqual(seen.sessions.map((s) => s.matchId).sort(), [duel.matchId, group.matchId].sort());
  assert.ok(seen.sessions.every((s) => s.hostName === `gilda_a${run}`));
  const tC = await auth(`device-gc-${run}`, `gilda_c${run}`);
  const denied = await fetch(`${BASE}/v2/rpc/guild_sessions`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${tC}` },
    body: JSON.stringify(JSON.stringify({ guild: guild.id })),
  });
  assert.notStrictEqual(denied.status, 200, 'chi non è nella gilda non vede gli allenamenti');

  // B entra nell'allenamento: al via di A parte, e la lista non lo mostra più.
  const a = await connect(tA);
  const b = await connect(tB);
  t.after(() => {
    a.ws.close();
    b.ws.close();
  });
  a.send({ cid: '1', match_join: { match_id: group.matchId } });
  b.send({ cid: '1', match_join: { match_id: group.matchId } });
  await a.wait((m) => m.match);
  await b.wait((m) => m.match);
  a.data(group.matchId, 1, {});
  b.data(group.matchId, 1, {});
  await sleep(500);
  a.data(group.matchId, 4, {});
  await b.wait((m) => m.match_data && m.match_data.op_code === '10' && decode(m).phase === 'countdown', 10000);
  await sleep(1500);
  const after = await rpcCall(tB, 'guild_sessions', { guild: guild.id });
  assert.ok(!after.sessions.some((s) => s.matchId === group.matchId));
  assert.ok(idA);
});
