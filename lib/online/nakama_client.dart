import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/i18n.dart';

/// Indirizzo del server di gioco (Nakama).
class ServerConfig {
  const ServerConfig({
    required this.host,
    this.port = 7350,
    this.ssl = false,
    this.serverKey = 'defaultkey',
  });

  final String host;
  final int port;
  final bool ssl;
  final String serverKey;

  /// Accetta "host", "host:porta" o un URL completo (http/https).
  static ServerConfig? parse(String input, {String serverKey = 'defaultkey'}) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    final ssl = uri.scheme == 'https';
    return ServerConfig(
      host: uri.host,
      port: uri.hasPort ? uri.port : (ssl ? 443 : 7350),
      ssl: ssl,
      serverKey: serverKey,
    );
  }

  Uri http(String path, [Map<String, String>? query]) => Uri(
        scheme: ssl ? 'https' : 'http',
        host: host,
        port: port,
        path: path,
        queryParameters: query,
      );

  Uri ws(String token) => Uri(
        scheme: ssl ? 'wss' : 'ws',
        host: host,
        port: port,
        path: '/ws',
        queryParameters: {'lang': 'it', 'status': 'true', 'token': token},
      );
}

class NakamaException implements Exception {
  NakamaException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sessione autenticata.
class NakamaSession {
  NakamaSession(this.token);
  final String token;

  /// L'id utente è nel payload del JWT.
  String get userId {
    final parts = token.split('.');
    if (parts.length < 2) return '';
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return (jsonDecode(payload) as Map<String, dynamic>)['uid'] as String? ?? '';
  }
}

/// Client minimo per Nakama: autenticazione REST e socket in tempo reale
/// con il protocollo JSON. Copre solo quello che serve all'Arena.
class NakamaClient {
  NakamaClient(this.config, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final ServerConfig config;
  final http.Client _http;

  Future<NakamaSession> authenticateDevice(String deviceId, {String? username}) async {
    final res = await _http
        .post(
          config.http('/v2/account/authenticate/device', {
            'create': 'true',
            'username': ?username,
          }),
          headers: {
            'Authorization': 'Basic ${base64.encode(utf8.encode('${config.serverKey}:'))}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'id': deviceId}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 409 && username != null) {
      // Nome già preso da un altro giocatore: si entra senza nome scelto.
      return authenticateDevice(deviceId);
    }
    if (res.statusCode != 200) {
      throw NakamaException(tr('Accesso al server non riuscito ({code})', {'code': res.statusCode}));
    }
    return NakamaSession((jsonDecode(res.body) as Map<String, dynamic>)['token'] as String);
  }

  Future<Map<String, dynamic>> rpc(NakamaSession s, String id, Map<String, dynamic> payload) async {
    final res = await _http
        .post(
          config.http('/v2/rpc/$id'),
          headers: {'Authorization': 'Bearer ${s.token}'},
          body: jsonEncode(jsonEncode(payload)),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      var message = tr('RPC {id} fallita ({code})', {'id': id, 'code': res.statusCode});
      try {
        message = (jsonDecode(res.body) as Map<String, dynamic>)['message'] as String? ?? message;
      } catch (_) {}
      throw NakamaException(message);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return jsonDecode(body['payload'] as String? ?? '{}') as Map<String, dynamic>;
  }

  /// Chiamata REST alle API standard di Nakama (gruppi, amici, notifiche).
  Future<Map<String, dynamic>> api(
    NakamaSession s,
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final req = http.Request(method, config.http(path, query))
      ..headers['Authorization'] = 'Bearer ${s.token}'
      ..headers['Content-Type'] = 'application/json';
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(
      await _http.send(req).timeout(const Duration(seconds: 10)),
    );
    if (res.statusCode != 200) {
      var message = tr('Errore del server ({code})', {'code': res.statusCode});
      try {
        message = (jsonDecode(res.body) as Map<String, dynamic>)['message'] as String? ?? message;
      } catch (_) {}
      throw NakamaException(message);
    }
    if (res.body.isEmpty) return const {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<NakamaSocket> connect(NakamaSession s, {WebSocketChannel Function(Uri)? connector}) async {
    final channel = (connector ?? WebSocketChannel.connect)(config.ws(s.token));
    await channel.ready.timeout(const Duration(seconds: 10));
    return NakamaSocket(channel);
  }

  void close() => _http.close();
}

/// Messaggio di gioco ricevuto in una partita.
class MatchData {
  MatchData(this.opCode, this.data, this.senderId);
  final int opCode;
  final Map<String, dynamic> data;
  final String? senderId;
}

class NakamaSocket {
  NakamaSocket(this._channel) {
    _sub = _channel.stream.listen(
      _onMessage,
      onError: (Object e) => _errors.add(e),
      onDone: () => _closed.complete(),
    );
  }

  final WebSocketChannel _channel;
  late final StreamSubscription<dynamic> _sub;
  int _cid = 0;
  final _pending = <String, Completer<Map<String, dynamic>>>{};
  final _matchmaker = StreamController<Map<String, dynamic>>.broadcast();
  final _matchData = StreamController<MatchData>.broadcast();
  final _errors = StreamController<Object>.broadcast();
  final _closed = Completer<void>();

  Stream<Map<String, dynamic>> get onMatchmakerMatched => _matchmaker.stream;
  Stream<MatchData> get onMatchData => _matchData.stream;
  Stream<Object> get onError => _errors.stream;
  Future<void> get done => _closed.future;

  void _onMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    final cid = msg['cid'] as String?;
    if (cid != null && _pending.containsKey(cid)) {
      final c = _pending.remove(cid)!;
      if (msg['error'] != null) {
        c.completeError(NakamaException(
            (msg['error'] as Map<String, dynamic>)['message'] as String? ?? tr('Errore del server')));
      } else {
        c.complete(msg);
      }
      return;
    }
    if (msg['matchmaker_matched'] != null) {
      _matchmaker.add(msg['matchmaker_matched'] as Map<String, dynamic>);
    } else if (msg['match_data'] != null) {
      final d = msg['match_data'] as Map<String, dynamic>;
      final payload = d['data'] as String?;
      Map<String, dynamic> data = const {};
      if (payload != null && payload.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
        if (decoded is Map<String, dynamic>) data = decoded;
      }
      final presence = d['presence'] as Map<String, dynamic>?;
      _matchData.add(MatchData(
        int.parse('${d['op_code'] ?? 0}'),
        data,
        presence?['user_id'] as String?,
      ));
    } else if (msg['error'] != null) {
      _errors.add(NakamaException(
          (msg['error'] as Map<String, dynamic>)['message'] as String? ?? tr('Errore del server')));
    }
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> body) {
    final cid = '${++_cid}';
    final c = Completer<Map<String, dynamic>>();
    _pending[cid] = c;
    _channel.sink.add(jsonEncode({'cid': cid, ...body}));
    return c.future.timeout(const Duration(seconds: 10), onTimeout: () {
      _pending.remove(cid);
      throw NakamaException(tr('Il server non risponde'));
    });
  }

  /// Cerca un avversario per lo stesso esercizio.
  Future<String> addMatchmaker(String exercise) async {
    final res = await _request({
      'matchmaker_add': {
        'min_count': 2,
        'max_count': 2,
        'query': '+properties.exercise:$exercise',
        'string_properties': {'exercise': exercise},
      },
    });
    return (res['matchmaker_ticket'] as Map<String, dynamic>)['ticket'] as String;
  }

  Future<void> removeMatchmaker(String ticket) =>
      _request({'matchmaker_remove': {'ticket': ticket}});

  Future<String> joinMatch(String matchId) async {
    final res = await _request({'match_join': {'match_id': matchId}});
    return (res['match'] as Map<String, dynamic>)['match_id'] as String;
  }

  Future<void> leaveMatch(String matchId) => _request({'match_leave': {'match_id': matchId}});

  /// Invio senza attesa di risposta (lo scheletro parte ~10 volte al secondo).
  void sendMatchData(String matchId, int opCode, Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode({
      'match_data_send': {
        'match_id': matchId,
        'op_code': '$opCode',
        'data': base64.encode(utf8.encode(jsonEncode(data))),
      },
    }));
  }

  Future<void> close() async {
    await _sub.cancel();
    await _channel.sink.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(NakamaException(tr('Connessione chiusa')));
    }
    _pending.clear();
    await _matchmaker.close();
    await _matchData.close();
    await _errors.close();
  }
}
