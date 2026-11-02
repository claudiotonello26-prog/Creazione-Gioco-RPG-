import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/i18n.dart';
import '../domain/exercise.dart';
import 'hero_card.dart';
import 'nakama_client.dart';

/// Stato nel gruppo di Nakama: 0 fondatore, 1 ufficiale, 2 membro,
/// 3 richiesta in attesa.
class GuildMember {
  GuildMember({
    required this.id,
    required this.name,
    required this.state,
    required this.online,
    this.hero,
  });
  final String id;
  final String name;
  final int state;
  final bool online;

  /// Come appare il suo cavaliere; null se non l'ha ancora pubblicato.
  HeroCard? hero;

  bool get isLeader => state <= 1;
}

class Guild {
  Guild({required this.id, required this.name, required this.description, required this.count});
  final String id;
  final String name;
  final String description;
  final int count;

  factory Guild.fromJson(Map<String, dynamic> j) => Guild(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        count: (j['edge_count'] as num?)?.toInt() ?? 0,
      );
}

/// Stato dell'amicizia in Nakama: 0 amici, 1 inviata, 2 ricevuta, 3 bloccato.
class Friend {
  Friend({required this.id, required this.name, required this.state, this.online = false, this.hero});
  final String id;
  final String name;
  final int state;
  final bool online;
  HeroCard? hero;
}

/// Un cavaliere trovato nella ricerca.
class Player {
  Player({required this.id, required this.name, this.online = false, this.hero});
  final String id;
  final String name;
  final bool online;
  final HeroCard? hero;
}

/// Un allenamento di gilda aperto, o una sfida in attesa.
class GuildSession {
  GuildSession({
    required this.matchId,
    required this.friendly,
    required this.exercise,
    required this.host,
    required this.hostName,
    required this.size,
  });
  final String matchId;
  final bool friendly;
  final ExerciseId exercise;
  final String host;
  final String hostName;
  final int size;
}

/// Sfida ricevuta: è una notifica del server con l'id del duello.
class Challenge {
  Challenge({required this.id, required this.matchId, required this.exercise, required this.from});
  final String id;
  final String matchId;
  final ExerciseId exercise;
  final String from;
}

ExerciseId _exercise(Object? name) =>
    ExerciseId.values.firstWhere((e) => e.name == name, orElse: () => ExerciseId.pushUp);

/// La gilda e gli amici del giocatore. Due versioni: quella vera sul server
/// ([NakamaGuildService]) e quella di prova sul telefono, quando il server
/// non c'è ancora (local_guild.dart).
abstract class GuildService extends ChangeNotifier {
  bool loading = false;
  String? error;
  Guild? guild;

  /// Il mio stato nella gilda (vedi [GuildMember.state]).
  int myState = 3;
  List<GuildMember> members = const [];
  List<Friend> friends = const [];
  List<GuildSession> sessions = const [];
  List<Challenge> challenges = const [];
  List<Guild> found = const [];
  List<Player> players = const [];

  /// Vero quando si gioca sul server: sfide e allenamenti in diretta ci
  /// sono solo lì.
  bool get live;
  String get myId;
  bool get isLeader => myState <= 1;
  bool get pending => guild != null && myState == 3;

  /// Ricarica gilda, membri, amici, allenamenti aperti e sfide.
  Future<void> refresh();
  Future<void> createGuild(String name, String description);
  Future<void> search(String name);

  /// I membri di una gilda trovata, per guardarli prima di entrare.
  Future<List<GuildMember>> preview(Guild g);
  Future<void> join(String guildId);
  Future<void> leave();

  /// Cerca cavalieri per nome (basta l'inizio).
  Future<void> searchPlayers(String name);

  /// Manda la richiesta d'amicizia, o accetta quella ricevuta.
  Future<void> addFriend(String id);

  /// Toglie un amico, annulla o rifiuta una richiesta.
  Future<void> removeFriend(String id);
  Future<void> addToGuild(String id);

  /// Invita un giocatore per nome: diventa amico e, se sono un capo, entra
  /// subito nella gilda. Ritorna il messaggio da mostrare.
  Future<String> invite(String name);

  /// Apre un allenamento di gilda o sfida un membro: ritorna il duello.
  Future<String> openSession(ExerciseId exercise, {String? opponent});
  Future<void> dismiss(Challenge c);

  Future<void> acceptFriend(String id) => addFriend(id);

  /// Accetta chi ha chiesto di entrare.
  Future<void> acceptMember(String id) => addToGuild(id);

  /// Stato d'amicizia con [id]: null se non c'è nessun legame.
  int? friendState(String id) {
    for (final f in friends) {
      if (f.id == id) return f.state;
    }
    return null;
  }
}

/// La gilda sul server: gruppi, amici, notifiche e oggetti salvati sono le
/// API standard di Nakama; ricerca dei giocatori, sfide e allenamenti
/// insieme passano dalle RPC del modulo (server/src/guild.ts).
class NakamaGuildService extends GuildService {
  NakamaGuildService({
    required this.client,
    required this.deviceId,
    required this.username,
    this.me,
  });

  final NakamaClient client;
  final String deviceId;
  final String username;

  /// Il mio cavaliere com'è adesso: si pubblica a ogni aggiornamento, così
  /// gli altri lo vedono con l'armatura nuova.
  final HeroCard Function()? me;

  NakamaSession? _session;
  String? _published;

  @override
  bool get live => true;
  @override
  String get myId => _session?.userId ?? '';

  Future<NakamaSession> _auth() async =>
      _session ??= await client.authenticateDevice(deviceId, username: username);

  Future<T> _run<T>(Future<T> Function(NakamaSession s) body) async {
    try {
      final s = await _auth();
      return await body(s);
    } catch (e) {
      error = '$e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _publish(NakamaSession s) async {
    final card = me?.call();
    if (card == null) return;
    final value = jsonEncode(card.toJson());
    if (value == _published) return;
    await client.api(s, 'PUT', '/v2/storage', body: {
      'objects': [
        {
          'collection': 'profile',
          'key': 'hero',
          'value': value,
          'permission_read': 2,
          'permission_write': 1,
        },
      ],
    });
    _published = value;
  }

  /// I cavalieri pubblicati da [ids], per id.
  Future<Map<String, HeroCard>> _heroes(NakamaSession s, Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    final res = await client.api(s, 'POST', '/v2/storage', body: {
      'object_ids': [
        for (final id in list) {'collection': 'profile', 'key': 'hero', 'user_id': id},
      ],
    });
    final out = <String, HeroCard>{};
    for (final o in (res['objects'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      try {
        final card = HeroCard.tryParse(jsonDecode(o['value'] as String? ?? '{}'));
        if (card != null) out[o['user_id'] as String] = card;
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final s = await _auth();
      try {
        await _publish(s);
      } catch (_) {
        // Il cavaliere si ripubblica al prossimo giro.
      }
      final groups = await client.api(s, 'GET', '/v2/user/${s.userId}/group', query: {'limit': '10'});
      final mine = (groups['user_groups'] as List? ?? const []).cast<Map<String, dynamic>>();
      guild = null;
      members = const [];
      sessions = const [];
      challenges = const [];
      if (mine.isNotEmpty) {
        final g = mine.firstWhere(
          (g) => ((g['state'] as num?)?.toInt() ?? 3) <= 2,
          orElse: () => mine.first,
        );
        guild = Guild.fromJson(g['group'] as Map<String, dynamic>);
        myState = (g['state'] as num?)?.toInt() ?? 3;
        if (myState <= 2) await _loadGuild(s);
      }
      final fr = await client.api(s, 'GET', '/v2/friend', query: {'limit': '100'});
      friends = [
        for (final f in (fr['friends'] as List? ?? const []).cast<Map<String, dynamic>>())
          Friend(
            id: (f['user'] as Map<String, dynamic>)['id'] as String,
            name: (f['user'] as Map<String, dynamic>)['username'] as String? ?? '',
            state: (f['state'] as num?)?.toInt() ?? 0,
            online: (f['user'] as Map<String, dynamic>)['online'] == true,
          ),
      ];
      final heroes = await _heroes(s, [...members.map((m) => m.id), ...friends.map((f) => f.id)]);
      for (final m in members) {
        m.hero = heroes[m.id];
      }
      for (final f in friends) {
        f.hero = heroes[f.id];
      }
    } catch (e) {
      error = '$e';
    }
    loading = false;
    notifyListeners();
  }

  Future<List<GuildMember>> _members(NakamaSession s, String guildId) async {
    final users = await client.api(s, 'GET', '/v2/group/$guildId/user', query: {'limit': '100'});
    return [
      for (final u in (users['group_users'] as List? ?? const []).cast<Map<String, dynamic>>())
        GuildMember(
          id: (u['user'] as Map<String, dynamic>)['id'] as String,
          name: (u['user'] as Map<String, dynamic>)['username'] as String? ?? '',
          state: (u['state'] as num?)?.toInt() ?? 2,
          online: (u['user'] as Map<String, dynamic>)['online'] == true,
        ),
    ]..sort((a, b) => a.state.compareTo(b.state));
  }

  Future<void> _loadGuild(NakamaSession s) async {
    final g = guild!;
    members = await _members(s, g.id);
    final open = await client.rpc(s, 'guild_sessions', {'guild': g.id});
    sessions = [
      for (final m in (open['sessions'] as List? ?? const []).cast<Map<String, dynamic>>())
        GuildSession(
          matchId: m['matchId'] as String,
          friendly: m['mode'] == 'friendly',
          exercise: _exercise(m['exercise']),
          host: m['host'] as String? ?? '',
          hostName: m['hostName'] as String? ?? '',
          size: (m['size'] as num?)?.toInt() ?? 0,
        ),
    ];
    // Le sfide restano valide finché il duello è aperto.
    final notes = await client.api(s, 'GET', '/v2/notification', query: {'limit': '50'});
    final openIds = sessions.map((x) => x.matchId).toSet();
    challenges = [];
    for (final n in (notes['notifications'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      if ((n['code'] as num?)?.toInt() != 100) continue;
      final content = jsonDecode(n['content'] as String? ?? '{}') as Map<String, dynamic>;
      final matchId = content['matchId'] as String?;
      if (matchId == null || !openIds.contains(matchId)) continue;
      challenges.add(Challenge(
        id: n['id'] as String,
        matchId: matchId,
        exercise: _exercise(content['exercise']),
        from: content['from'] as String? ?? '',
      ));
    }
  }

  @override
  Future<void> createGuild(String name, String description) async {
    await _run((s) => client.api(s, 'POST', '/v2/group', body: {
          'name': name,
          'description': description,
          'open': true,
          'max_count': 50,
        }));
    await refresh();
  }

  @override
  Future<void> search(String name) async {
    final res = await _run((s) => client.api(s, 'GET', '/v2/group', query: {
          'name': name.isEmpty ? '%' : '$name%',
          'limit': '20',
        }));
    found = [
      for (final g in (res['groups'] as List? ?? const []).cast<Map<String, dynamic>>())
        Guild.fromJson(g),
    ];
    notifyListeners();
  }

  @override
  Future<List<GuildMember>> preview(Guild g) => _run((s) async {
        final list = (await _members(s, g.id)).where((m) => m.state <= 2).toList();
        final heroes = await _heroes(s, list.map((m) => m.id));
        for (final m in list) {
          m.hero = heroes[m.id];
        }
        return list;
      });

  @override
  Future<void> join(String guildId) async {
    await _run((s) => client.api(s, 'POST', '/v2/group/$guildId/join'));
    found = const [];
    await refresh();
  }

  @override
  Future<void> leave() async {
    final g = guild;
    if (g == null) return;
    final others = members.where((m) => m.id != myId && m.state <= 2).toList();
    if (others.isEmpty) {
      // Ultimo rimasto: la gilda si scioglie.
      await _run((s) => client.api(s, 'DELETE', '/v2/group/${g.id}'));
    } else {
      // Il fondatore non può lasciarla senza capo: il più anziano prende il posto.
      if (myState == 0 && !others.any((m) => m.state == 0)) {
        final heir = others.first;
        for (var st = heir.state; st > 0; st--) {
          await _run(
            (s) => client.api(s, 'POST', '/v2/group/${g.id}/promote', query: {'user_ids': heir.id}),
          );
        }
      }
      await _run((s) => client.api(s, 'POST', '/v2/group/${g.id}/leave'));
    }
    await refresh();
  }

  @override
  Future<void> searchPlayers(String name) async {
    final res = await _run((s) => client.rpc(s, 'player_search', {'name': name}));
    final list = (res['players'] as List? ?? const []).cast<Map<String, dynamic>>();
    players = [
      for (final p in list)
        Player(
          id: p['id'] as String,
          name: p['name'] as String? ?? '',
          online: p['online'] == true,
          hero: HeroCard.tryParse(p['hero']),
        ),
    ];
    notifyListeners();
  }

  @override
  Future<void> addFriend(String id) async {
    await _run((s) => client.api(s, 'POST', '/v2/friend', query: {'ids': id}));
    await refresh();
  }

  @override
  Future<void> removeFriend(String id) async {
    await _run((s) => client.api(s, 'DELETE', '/v2/friend', query: {'ids': id}));
    await refresh();
  }

  @override
  Future<String> invite(String name) async {
    final res = await _run((s) => client.api(s, 'GET', '/v2/user', query: {'usernames': name}));
    final users = (res['users'] as List? ?? const []).cast<Map<String, dynamic>>();
    if (users.isEmpty) return tr('Nessun giocatore si chiama {name}.', {'name': name});
    final id = users.first['id'] as String;
    await _run((s) => client.api(s, 'POST', '/v2/friend', query: {'ids': id}));
    final g = guild;
    var text = tr('Richiesta di amicizia inviata a {name}.', {'name': name});
    if (g != null && isLeader) {
      await _run((s) => client.api(s, 'POST', '/v2/group/${g.id}/add', query: {'user_ids': id}));
      text = tr('{name} è entrato nella gilda.', {'name': name});
    }
    await refresh();
    return text;
  }

  @override
  Future<void> addToGuild(String id) async {
    final g = guild;
    if (g == null) return;
    await _run((s) => client.api(s, 'POST', '/v2/group/${g.id}/add', query: {'user_ids': id}));
    await refresh();
  }

  @override
  Future<String> openSession(ExerciseId exercise, {String? opponent}) async {
    final g = guild!;
    final res = await _run((s) => client.rpc(s, 'guild_session_create', {
          'guild': g.id,
          'mode': opponent == null ? 'group' : 'friendly',
          'exercise': exercise.name,
          'opponent': ?opponent,
        }));
    return res['matchId'] as String;
  }

  @override
  Future<void> dismiss(Challenge c) async {
    await _run((s) => client.api(s, 'DELETE', '/v2/notification', query: {'ids': c.id}));
    challenges = challenges.where((x) => x.id != c.id).toList();
    notifyListeners();
  }
}
