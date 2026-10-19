import 'dart:async';
import 'dart:math';

import '../core/i18n.dart';
import '../domain/character.dart';
import '../domain/exercise.dart';
import '../domain/items.dart';
import 'guild_service.dart';
import 'hero_card.dart';
import 'nakama_client.dart';

/// Una gilda di prova che vive sul telefono.
class _NpcGuild {
  const _NpcGuild(this.id, this._name, this._motto);
  final String id;
  final String _name;
  final String _motto;
  String get name => tr(_name);
  String get motto => tr(_motto);
}

const _npcGuilds = [
  _NpcGuild('g_brace', 'Ordine della Brace', 'Il fuoco non salta un giorno.'),
  _NpcGuild('g_crepuscolo', 'Lame del Crepuscolo', 'Ci alleniamo quando gli altri dormono.'),
  _NpcGuild('g_forgia', 'Custodi della Forgia', 'Ogni rep è un colpo di martello.'),
  _NpcGuild('g_pellegrini', 'Pellegrini di Ferro', 'Passo dopo passo, fino in cima.'),
];

/// Cavalieri di prova: nome, gilda (null se senza) e se è in linea.
const _npcKnights = [
  ('Aldric', 'g_brace', true),
  ('Brunilde', 'g_brace', false),
  ('Tancredi', 'g_brace', false),
  ('Isolde', 'g_crepuscolo', true),
  ('Corvino', 'g_crepuscolo', false),
  ('Morgana', 'g_crepuscolo', true),
  ('Ulfric', 'g_crepuscolo', false),
  ('Garrik', 'g_forgia', false),
  ('Elsa', 'g_forgia', true),
  ('Bertrand', 'g_pellegrini', false),
  ('Ginevra', 'g_pellegrini', false),
  ('Rodrigo', null, true),
  ('Selvaggia', null, false),
  ('Ottone', null, false),
  ('Matilde', null, true),
  ('Lancillotto', null, false),
];

const _femaleNames = {
  'Brunilde', 'Isolde', 'Morgana', 'Elsa', 'Ginevra', 'Selvaggia', 'Matilde',
};

/// L'aspetto di un cavaliere di prova: sempre lo stesso per lo stesso nome.
HeroCard _npcHero(int i, String name) {
  final r = Random(name.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x3fffffff));
  final female = _femaleNames.contains(name);
  final hair = female ? Appearance.femaleHair : Appearance.maleHair;
  final look = Appearance(
    female: female,
    style: r.nextInt(Appearance.drawnFaces),
    hairStyle: hair[1 + r.nextInt(hair.length - 1)].$1,
    beardStyle: female ? -1 : Appearance.beards[r.nextInt(Appearance.beards.length)].$1,
    hair: r.nextInt(Appearance.hairColors.length),
    eyes: r.nextInt(Appearance.eyeColors.length),
    shirt: r.nextInt(Appearance.clothColors.length),
    pants: r.nextInt(Appearance.clothColors.length),
  );
  final level = 2 + r.nextInt(28);
  // Più è forte, più ha addosso: dal giaco al cuoio alla cotta di maglia.
  final set = level < 8 ? 'gambeson' : (level < 18 ? 'leather_armor' : 'chainmail');
  final worn = <ArmorSlot, String>{};
  for (final slot in [ArmorSlot.chest, ArmorSlot.legs, ArmorSlot.boots, ArmorSlot.gloves]) {
    if (r.nextInt(10) < 7) worn[slot] = set;
  }
  if (r.nextInt(10) < 3) worn[ArmorSlot.helm] = set;
  const weapons = ['pilgrim_blade', 'steel_longsword', 'cathedral_hammer', 'ashwood_bow', 'ember_staff'];
  return HeroCard(
    name: name,
    level: level,
    look: look,
    worn: worn,
    cape: r.nextBool() ? 'pilgrim_cape' : null,
    weapon: weapons[(i + level) % weapons.length],
  );
}

/// Gilda e amici senza server: gilde e cavalieri di prova, salvati solo sul
/// telefono. Serve a provare tutto prima che il server sia acceso; sfide e
/// allenamenti in diretta restano del server.
class LocalGuildService extends GuildService {
  LocalGuildService({required this.store, required this.save, required this.me});

  /// Lo stato salvato (nel salvataggio di GameState) e chi lo salva.
  final Map<String, dynamic> store;
  final void Function() save;
  final HeroCard Function() me;

  /// Quanto ci mette un cavaliere di prova a rispondere all'amicizia.
  static Duration answerDelay = const Duration(seconds: 3);

  final List<Timer> _timers = [];

  static const _me = 'me';

  @override
  bool get live => false;
  @override
  String get myId => _me;

  Map<String, dynamic> get _friends => (store['friends'] ??= <String, dynamic>{
        // Al primo giro qualcuno ti ha già cercato.
        'npc_14': 2,
      }) as Map<String, dynamic>;

  /// Le gilde fondate sul telefono: id, nome, motto, membri.
  List<Map<String, dynamic>> get _own =>
      ((store['own'] ??= <dynamic>[]) as List).cast<Map<String, dynamic>>();

  /// Cavalieri di prova portati nella gilda fondata da me.
  List<String> get _recruits => ((store['recruits'] ??= <dynamic>[]) as List).cast<String>();

  String? get _guildId => store['guild'] as String?;

  static String _npcId(int i) => 'npc_$i';

  Player _npc(int i) {
    final (name, _, online) = _npcKnights[i];
    return Player(id: _npcId(i), name: name, online: online, hero: _npcHero(i, name));
  }

  Player? _byId(String id) {
    final i = int.tryParse(id.replaceFirst('npc_', ''));
    if (!id.startsWith('npc_') || i == null || i < 0 || i >= _npcKnights.length) return null;
    return _npc(i);
  }

  Guild _guild(String id) {
    for (final g in _npcGuilds) {
      if (g.id == id) return Guild(id: g.id, name: g.name, description: g.motto, count: _roster(id).length);
    }
    final own = _own.firstWhere((g) => g['id'] == id);
    return Guild(
      id: id,
      name: own['name'] as String,
      description: own['motto'] as String? ?? '',
      count: _roster(id).length,
    );
  }

  bool _exists(String? id) =>
      id != null && (_npcGuilds.any((g) => g.id == id) || _own.any((g) => g['id'] == id));

  /// Tutti i membri di una gilda, io compreso se ci sono.
  List<GuildMember> _roster(String guildId) {
    final own = _own.any((g) => g['id'] == guildId);
    final list = <GuildMember>[
      for (var i = 0; i < _npcKnights.length; i++)
        if (_npcKnights[i].$2 == guildId || (own && _recruits.contains(_npcId(i))))
          GuildMember(
            id: _npcId(i),
            name: _npcKnights[i].$1,
            // Il primo cavaliere di una gilda di prova ne è il fondatore.
            state: own ? 2 : (_npcKnights.indexWhere((k) => k.$2 == guildId) == i ? 0 : 2),
            online: _npcKnights[i].$3,
            hero: _npcHero(i, _npcKnights[i].$1),
          ),
    ];
    if (_guildId == guildId) {
      final card = me();
      list.add(GuildMember(
        id: _me,
        name: card.name,
        state: (store['myState'] as int?) ?? 2,
        online: true,
        hero: card,
      ));
    }
    return list..sort((a, b) => a.state.compareTo(b.state));
  }

  @override
  Future<void> refresh() async {
    error = null;
    final id = _guildId;
    if (_exists(id)) {
      guild = _guild(id!);
      myState = (store['myState'] as int?) ?? 2;
      members = _roster(id);
    } else {
      guild = null;
      members = const [];
    }
    friends = [
      for (final e in _friends.entries)
        if (_byId(e.key) case final p?)
          Friend(id: p.id, name: p.name, state: e.value as int, online: p.online, hero: p.hero),
    ];
    notifyListeners();
  }

  @override
  Future<void> createGuild(String name, String description) async {
    final id = 'own_${DateTime.now().millisecondsSinceEpoch}';
    _own.add({'id': id, 'name': name, 'motto': description});
    store['guild'] = id;
    store['myState'] = 0;
    _recruits.clear();
    save();
    await refresh();
  }

  @override
  Future<void> search(String name) async {
    final q = name.toLowerCase();
    found = [
      for (final g in [..._npcGuilds.map((g) => g.id), ..._own.map((g) => g['id'] as String)])
        if (_guild(g).name.toLowerCase().contains(q)) _guild(g),
    ];
    notifyListeners();
  }

  @override
  Future<List<GuildMember>> preview(Guild g) async => _roster(g.id);

  @override
  Future<void> join(String guildId) async {
    _dropOwn();
    store['guild'] = guildId;
    store['myState'] = 2;
    found = const [];
    save();
    await refresh();
  }

  @override
  Future<void> leave() async {
    _dropOwn();
    store.remove('guild');
    save();
    await refresh();
  }

  /// Una gilda mia resta solo finché ci sono io dentro.
  void _dropOwn() {
    _own.removeWhere((g) => g['id'] == _guildId);
    _recruits.clear();
  }

  @override
  Future<void> searchPlayers(String name) async {
    final q = name.toLowerCase();
    players = [
      for (var i = 0; i < _npcKnights.length; i++)
        if (_npcKnights[i].$1.toLowerCase().startsWith(q)) _npc(i),
    ];
    notifyListeners();
  }

  @override
  Future<void> addFriend(String id) async {
    if (_byId(id) == null) return;
    final state = _friends[id] as int?;
    if (state == 2) {
      _friends[id] = 0;
    } else if (state == null) {
      _friends[id] = 1;
      // Il cavaliere di prova accetta dopo un po'.
      _timers.add(Timer(answerDelay, () {
        if (_friends[id] != 1) return;
        _friends[id] = 0;
        save();
        refresh();
      }));
    }
    save();
    await refresh();
  }

  @override
  Future<void> removeFriend(String id) async {
    _friends.remove(id);
    save();
    await refresh();
  }

  @override
  Future<void> addToGuild(String id) async {
    final own = _own.any((g) => g['id'] == _guildId);
    if (!own || !isLeader || _byId(id) == null) return;
    // Uno di una gilda di prova non la lascia.
    final i = int.parse(id.replaceFirst('npc_', ''));
    if (_npcKnights[i].$2 != null) {
      throw NakamaException(
        tr('{name} è già nella gilda {guild}.', {
          'name': _npcKnights[i].$1,
          'guild': _guild(_npcKnights[i].$2!).name,
        }),
      );
    }
    if (!_recruits.contains(id)) _recruits.add(id);
    save();
    await refresh();
  }

  @override
  Future<String> invite(String name) async {
    final i = _npcKnights.indexWhere((k) => k.$1.toLowerCase() == name.toLowerCase());
    if (i < 0) return tr('Nessun giocatore si chiama {name}.', {'name': name});
    await addFriend(_npcId(i));
    return tr('Richiesta di amicizia inviata a {name}.', {'name': _npcKnights[i].$1});
  }

  @override
  Future<String> openSession(ExerciseId exercise, {String? opponent}) async =>
      throw NakamaException(
        tr('Le sfide e gli allenamenti in diretta arrivano con il server online.'),
      );

  @override
  Future<void> dismiss(Challenge c) async {}

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
