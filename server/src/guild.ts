// Gilde: i gruppi sono quelli di Nakama (creazione, inviti, membri passano
// dalle API REST standard). Qui ci sono solo le sfide tra amici e gli
// allenamenti di gilda, che sono duelli dell'Arena senza punti stagione.

/** Codice della notifica di sfida: l'app la mostra tra le sfide ricevute. */
const GUILD_CHALLENGE_CODE = 100;

/** Stato nel gruppo: 0 superadmin, 1 admin, 2 membro, 3 richiesta in attesa. */
const GUILD_MEMBER_MAX_STATE = 2;

function guildIsMember(nk: nkruntime.Nakama, userId: string, guild: string): boolean {
  const list = nk.userGroupsList(userId, 100, null);
  const groups = list.userGroups || [];
  for (let i = 0; i < groups.length; i++) {
    if (groups[i].group.id === guild && groups[i].state <= GUILD_MEMBER_MAX_STATE) return true;
  }
  return false;
}

/**
 * Crea una sfida tra amici (mode friendly, con opponent) o un allenamento di
 * gilda (mode group). Ritorna l'id della partita in cui entrare.
 */
function rpcGuildSessionCreate(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string,
): string {
  const userId = ctx.userId || '';
  const req = JSON.parse(payload || '{}');
  const guild = String(req.guild || '');
  const mode = req.mode === 'friendly' ? 'friendly' : 'group';
  const exercise = ARENA_CHALLENGES[req.exercise] ? String(req.exercise) : 'pushUp';
  const opponent = mode === 'friendly' ? String(req.opponent || '') : '';
  if (!guildIsMember(nk, userId, guild)) throw Error('Non sei in questa gilda');
  if (mode === 'friendly') {
    if (!opponent || opponent === userId) throw Error('Avversario mancante');
    if (!guildIsMember(nk, opponent, guild)) throw Error("L'avversario non è nella gilda");
  }
  const matchId = nk.matchCreate(ARENA_MATCH_MODULE, {
    exercise: exercise,
    mode: mode,
    guild: guild,
    host: userId,
    hostName: ctx.username || '',
    players: mode === 'friendly' ? userId + ',' + opponent : '',
  });
  if (mode === 'friendly') {
    nk.notificationSend(opponent, 'Sfida', {
      matchId: matchId,
      exercise: exercise,
      from: ctx.username || '',
      guild: guild,
    }, GUILD_CHALLENGE_CODE, userId, true);
  }
  return JSON.stringify({ matchId: matchId });
}

/** Allenamenti di gilda aperti e sfide in attesa rivolte a chi chiede. */
function rpcGuildSessions(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string,
): string {
  const userId = ctx.userId || '';
  const req = JSON.parse(payload || '{}');
  const guild = String(req.guild || '');
  if (!guildIsMember(nk, userId, guild)) throw Error('Non sei in questa gilda');
  // Con i filtri di dimensione Nakama ignora la query: si filtra qui sotto.
  const matches = nk.matchList(50, true, null, null, null, '+label.guild:' + guild + ' +label.open:1');
  const sessions: any[] = [];
  for (let i = 0; i < matches.length; i++) {
    let label: any;
    try {
      label = JSON.parse(matches[i].label);
    } catch (e) {
      continue;
    }
    if (label.guild !== guild || label.open !== 1) continue;
    if (label.mode === 'friendly' && label.to !== userId && label.host !== userId) continue;
    sessions.push({
      matchId: matches[i].matchId,
      mode: label.mode,
      exercise: label.exercise,
      host: label.host,
      hostName: label.hostName,
      size: matches[i].size,
    });
  }
  return JSON.stringify({ sessions: sessions });
}

/**
 * Cerca cavalieri per nome (basta l'inizio, senza maiuscole). Ritorna anche
 * il loro cavaliere pubblicato (collezione profile, chiave hero) per
 * mostrarlo nella lista. Chi cerca non compare.
 */
function rpcPlayerSearch(
  ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string,
): string {
  const userId = ctx.userId || '';
  const req = JSON.parse(payload || '{}');
  const name = String(req.name || '').replace(/[%_\\]/g, '').slice(0, 24);
  const rows = nk.sqlQuery(
    'SELECT id, username FROM users WHERE username ILIKE $1 AND id <> $2 ' +
      "AND id <> '00000000-0000-0000-0000-000000000000' AND disable_time = '1970-01-01 00:00:00+00' " +
      'ORDER BY update_time DESC LIMIT 20',
    [name + '%', userId],
  );
  if (rows.length === 0) return JSON.stringify({ players: [] });
  const ids: string[] = [];
  for (let i = 0; i < rows.length; i++) ids.push(String(rows[i].id));
  const online: { [id: string]: boolean } = {};
  const users = nk.usersGetId(ids);
  for (let i = 0; i < users.length; i++) online[users[i].userId] = !!users[i].online;
  const heroes: { [id: string]: any } = {};
  const reads: nkruntime.StorageReadRequest[] = [];
  for (let i = 0; i < ids.length; i++) reads.push({ collection: 'profile', key: 'hero', userId: ids[i] });
  const objects = nk.storageRead(reads);
  for (let i = 0; i < objects.length; i++) heroes[objects[i].userId] = objects[i].value;
  const players: any[] = [];
  for (let i = 0; i < rows.length; i++) {
    const id = String(rows[i].id);
    players.push({ id: id, name: String(rows[i].username), online: !!online[id], hero: heroes[id] || null });
  }
  return JSON.stringify({ players: players });
}
