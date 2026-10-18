import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/i18n.dart';
import '../domain/exercise.dart';
import 'nakama_client.dart';

/// Stato nel gruppo di Nakama: 0 fondatore, 1 ufficiale, 2 membro,
/// 3 richiesta in attesa.
class GuildMember {
  GuildMember({required this.id, required this.name, required this.state, required this.online});
  final String id;
  final String name;
  final int state;
  final bool online;

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
  Friend({required this.id, required this.name, required this.state});
  final String id;
  final String name;
  final int state;
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

/// La gilda del giocatore: gruppi, amici e notifiche sono le API standard di
/// Nakama; sfide e allenamenti insieme passano dalle RPC del modulo
/// (server/src/guild.ts).
class GuildService extends ChangeNotifier {
  GuildService({required this.client, required this.deviceId, required this.username});

  final NakamaClient client;
  final String deviceId;
  final String username;

  NakamaSession? _session;
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

  String get myId => _session?.userId ?? '';
  bool get isLeader => myState <= 1;
  bool get pending => guild != null && myState == 3;

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

  /// Ricarica gilda, membri, amici, allenamenti aperti e sfide.
  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final s = await _auth();
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
          ),
      ];
    } catch (e) {
      error = '$e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _loadGuild(NakamaSession s) async {
    final g = guild!;
    final users = await client.api(s, 'GET', '/v2/group/${g.id}/user', query: {'limit': '100'});
    members = [
      for (final u in (users['group_users'] as List? ?? const []).cast<Map<String, dynamic>>())
        GuildMember(
          id: (u['user'] as Map<String, dynamic>)['id'] as String,
          name: (u['user'] as Map<String, dynamic>)['username'] as String? ?? '',
          state: (u['state'] as num?)?.toInt() ?? 2,
          online: (u['user'] as Map<String, dynamic>)['online'] == true,
        ),
    ]..sort((a, b) => a.state.compareTo(b.state));
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

  Future<void> createGuild(String name, String description) async {
    await _run((s) => client.api(s, 'POST', '/v2/group', body: {
          'name': name,
          'description': description,
          'open': true,
          'max_count': 50,
        }));
    await refresh();
  }

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

  Future<void> join(String guildId) async {
    await _run((s) => client.api(s, 'POST', '/v2/group/$guildId/join'));
    found = const [];
    await refresh();
  }

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

  /// Invita un giocatore per nome: diventa amico e, se sono un capo, entra
  /// subito nella gilda. Ritorna il messaggio da mostrare.
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

  /// Accetta una richiesta d'amicizia o porta un amico nella gilda.
  Future<void> acceptFriend(String id) async {
    await _run((s) => client.api(s, 'POST', '/v2/friend', query: {'ids': id}));
    await refresh();
  }

  Future<void> addToGuild(String id) async {
    final g = guild;
    if (g == null) return;
    await _run((s) => client.api(s, 'POST', '/v2/group/${g.id}/add', query: {'user_ids': id}));
    await refresh();
  }

  /// Accetta chi ha chiesto di entrare.
  Future<void> acceptMember(String id) => addToGuild(id);

  /// Apre un allenamento di gilda o sfida un membro: ritorna il duello.
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

  Future<void> dismiss(Challenge c) async {
    await _run((s) => client.api(s, 'DELETE', '/v2/notification', query: {'ids': c.id}));
    challenges = challenges.where((x) => x.id != c.id).toList();
    notifyListeners();
  }
}
