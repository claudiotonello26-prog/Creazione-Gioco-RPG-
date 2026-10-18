import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/pvp.dart';
import '../../online/guild_service.dart';
import '../../online/hero_card.dart';
import '../../online/local_guild.dart';
import '../../online/nakama_client.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import '../widgets/oath_bar.dart';
import 'arena_live_screen.dart';
import 'settings_screen.dart';

/// La Gilda, in due schede: la gilda (fondarla, cercarne una e guardarci
/// dentro, il salone coi cavalieri, allenamenti e sfide) e i Cavalieri
/// (cercare giocatori, amicizie). Senza server tutto funziona con gilde e
/// cavalieri di prova salvati sul telefono.
class GuildTab extends StatefulWidget {
  const GuildTab({super.key, this.service});

  /// Per i test: un servizio già pronto invece di quello verso il server.
  final GuildService? service;

  @override
  State<GuildTab> createState() => _GuildTabState();
}

class _GuildTabState extends State<GuildTab> {
  GuildService? _service;
  String? _address;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.watch<GameState>();
    if (widget.service != null) {
      if (_service == null) {
        _service = widget.service;
        _refreshSoon();
      }
      return;
    }
    if (s.serverAddress == _address) return;
    _address = s.serverAddress;
    _service?.dispose();
    HeroCard me() => HeroCard.of(s.character);
    final config = ServerConfig.parse(_address!);
    _service = config == null
        ? LocalGuildService(store: s.socialLocal, save: s.saveSocial, me: me)
        : NakamaGuildService(
            client: NakamaClient(config),
            deviceId: s.deviceId,
            username: s.character.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), ''),
            me: me,
          );
    _refreshSoon();
  }

  /// Dopo il disegno: chi ascolta il servizio non si aggiorna mentre si
  /// sta costruendo.
  void _refreshSoon() {
    final service = _service;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && service == _service) service?.refresh();
    });
  }

  @override
  void dispose() {
    if (widget.service == null) _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service!;
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final asked = service.friends.where((f) => f.state == 2).length;
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: OathBar(
              title: Text(tr('Guild').toUpperCase()),
              accent: Sections.guild,
              bottom: TabBar(
                onTap: (_) => Sound.play(Sfx.tab),
                tabs: [
                  Tab(text: tr('Gilda')),
                  Tab(
                    child: Badge(
                      isLabelVisible: asked > 0,
                      label: Text('$asked'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(tr('Cavalieri')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: service.refresh,
                  child: service.guild == null || service.pending
                      ? _NoGuild(service: service)
                      : _MyGuild(service: service),
                ),
                RefreshIndicator(
                  onRefresh: service.refresh,
                  child: _Knights(service: service),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Senza server: si gioca con gilde e cavalieri di prova.
class _Offline extends StatelessWidget {
  const _Offline();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Palette.stoneLight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Palette.ash),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('Server non collegato: gilde e cavalieri sono di prova e restano su questo telefono.'),
                style: const TextStyle(color: Palette.ash, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: Text(tr('SERVER')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, color: Sections.guild, size: 40),
            const SizedBox(height: 8),
            Text(
              tr('Una gilda è il tuo gruppo: vi allenate insieme in diretta e vi sfidate tra amici. Le sfide in gilda non toccano i punti dell\'Arena.'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Il busto del cavaliere, per le liste: la testa e le spalle con l'elmo e
/// l'armatura che porta.
class HeroPortrait extends StatelessWidget {
  const HeroPortrait({super.key, required this.hero, this.size = 56, this.online = false});
  final HeroCard? hero;
  final double size;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final h = hero;
    final full = size * 2.9;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Palette.night,
        border: Border.all(color: online ? Palette.moss : Palette.iron, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: h == null || !HeroView.available
          ? Icon(Icons.person, color: Palette.ash, size: size * 0.6)
          : OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: full,
              maxWidth: size,
              child: Transform.translate(
                offset: Offset(0, -full * 0.02),
                child: SizedBox(
                  height: full,
                  width: size,
                  child: HeroView(look: h.look, height: full, worn: h.worn, cape: h.cape),
                ),
              ),
            ),
    );
  }
}

/// Un cavaliere in lista: ritratto, nome, livello e un'azione.
class _KnightTile extends StatelessWidget {
  const _KnightTile({
    required this.name,
    required this.hero,
    this.subtitle,
    this.online = false,
    this.trailing,
    this.onTap,
  });
  final String name;
  final HeroCard? hero;
  final String? subtitle;
  final bool online;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (hero != null) tr('Livello {n}', {'n': hero!.level}),
      ?subtitle,
      if (online) tr('in linea'),
    ];
    return Card(
      child: ListTile(
        minVerticalPadding: 8,
        leading: HeroPortrait(hero: hero, online: online, size: 50),
        title: OneLine(name, align: Alignment.centerLeft),
        subtitle: parts.isEmpty
            ? null
            : Text(parts.join(' · '), style: const TextStyle(color: Palette.ash, fontSize: 14)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Il cavaliere a figura intera, con nome e livello sotto.
class _Standing extends StatelessWidget {
  const _Standing({required this.name, required this.hero, this.height = 170, this.badge, this.onTap});
  final String name;
  final HeroCard? hero;
  final double height;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final h = hero;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: max(height * 0.5, 84),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: h == null || !HeroView.available
                  ? Icon(Icons.person, color: Palette.ash, size: height * 0.5)
                  : HeroView(
                      look: h.look,
                      height: height,
                      worn: h.worn,
                      cape: h.cape,
                      weapon: h.weaponInstance,
                    ),
            ),
            const SizedBox(height: 4),
            OneLine(
              name,
              align: Alignment.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            OneLine(
              [if (h != null) tr('Lv {n}', {'n': h.level}), ?badge].join(' · '),
              align: Alignment.center,
              style: const TextStyle(color: Palette.ash, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il salone: i cavalieri della gilda in fila, a figura intera.
class _Hall extends StatelessWidget {
  const _Hall({required this.members, required this.service, this.height = 170});
  final List<GuildMember> members;
  final GuildService service;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final m in members.where((m) => m.state <= 2))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _Standing(
                name: m.id == service.myId ? tr('{name} (tu)', {'name': m.name}) : m.name,
                hero: m.hero,
                height: height,
                badge: m.state <= 1 ? _role(m.state) : null,
                onTap: () => showKnight(context, service, id: m.id, name: m.name, hero: m.hero, online: m.online),
              ),
            ),
        ],
      ),
    );
  }
}

String _role(int state) => switch (state) {
      0 => tr('Fondatore'),
      1 => tr('Ufficiale'),
      2 => tr('Membro'),
      _ => tr('Chiede di entrare'),
    };

/// Fonda una gilda o cercane una.
class _NoGuild extends StatefulWidget {
  const _NoGuild({required this.service});
  final GuildService service;

  @override
  State<_NoGuild> createState() => _NoGuildState();
}

class _NoGuildState extends State<_NoGuild> {
  final _name = TextEditingController();
  final _motto = TextEditingController();
  final _search = TextEditingController();
  bool _searched = false;

  GuildService get g => widget.service;

  @override
  void initState() {
    super.initState();
    // Si parte con qualche gilda da guardare.
    if (g.found.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) g.search('').then((_) => _searched = true, onError: (_) {});
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _motto.dispose();
    _search.dispose();
    super.dispose();
  }

  void _find() {
    _searched = true;
    _guard(context, g.search(_search.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!g.live) const _Offline(),
        const _Intro(),
        if (g.error != null) _Error(g.error!),
        if (g.pending)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              tr('Hai chiesto di entrare in {guild}: aspetta che un capo ti accetti.', {'guild': g.guild!.name}),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.goldBright),
            ),
          ),
        SectionTitle(tr('Cerca una gilda')),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(labelText: tr('Nome')),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _find, child: Text(tr('CERCA'))),
          ],
        ),
        const SizedBox(height: 8),
        if (_searched && g.found.isEmpty)
          Text(
            tr('Nessuna gilda con questo nome. Fondala tu!'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          ),
        for (final found in g.found)
          ActionTile(
            icon: Icons.shield_outlined,
            color: Sections.guild,
            title: found.name,
            subtitle: tr('{n} membri', {'n': found.count}) +
                (found.description.isEmpty ? '' : ' · ${found.description}'),
            onTap: () => _showGuild(context, g, found),
          ),
        SectionTitle(tr('Fonda una gilda')),
        TextField(
          controller: _name,
          maxLength: 24,
          decoration: InputDecoration(labelText: tr('Nome della gilda')),
        ),
        TextField(
          controller: _motto,
          maxLength: 60,
          decoration: InputDecoration(labelText: tr('Motto (facoltativo)')),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: g.loading
              ? null
              : () {
                  final name = _name.text.trim();
                  if (name.length < 3) {
                    _snack(context, tr('Il nome deve avere almeno 3 lettere.'));
                    return;
                  }
                  _guard(context, g.createGuild(name, _motto.text.trim()));
                },
          child: Text(tr('FONDA')),
        ),
      ],
    );
  }
}

/// Dentro una gilda trovata: i suoi cavalieri, prima di entrare.
Future<void> _showGuild(BuildContext context, GuildService service, Guild guild) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.stone,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<GuildMember>>(
          future: service.preview(guild),
          builder: (ctx, snap) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield, color: Sections.guild, size: 36),
              OneLine(
                guild.name.toUpperCase(),
                align: Alignment.center,
                style: const TextStyle(
                  fontFamily: kTitleFont,
                  fontSize: 20,
                  letterSpacing: 2,
                  color: Palette.goldBright,
                ),
              ),
              if (guild.description.isNotEmpty)
                Text(
                  guild.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 8),
              if (snap.hasError)
                Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: Palette.blood))
              else if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Text(
                  tr('{n} membri', {'n': snap.data!.length}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.ash),
                ),
                const SizedBox(height: 8),
                _Hall(members: snap.data!, service: service, height: 150),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _guard(context, service.join(guild.id));
                },
                child: Text(tr('ENTRA NELLA GILDA')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// La scheda di un cavaliere: figura intera e cosa si può fare con lui.
Future<void> showKnight(
  BuildContext context,
  GuildService service, {
  required String id,
  required String name,
  HeroCard? hero,
  bool online = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.stone,
    builder: (ctx) => ListenableBuilder(
      listenable: service,
      builder: (ctx, _) {
        final me = id == service.myId;
        final state = service.friendState(id);
        final inGuild = service.members.any((m) => m.id == id && m.state <= 2);
        final canRecruit =
            state == 0 && !inGuild && service.guild != null && service.isLeader && !service.pending;
        final canDuel = service.live && inGuild && !me && service.myState <= 2;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: _Standing(name: name, hero: hero, height: 300)),
                if (online)
                  Text(tr('in linea'), textAlign: TextAlign.center, style: const TextStyle(color: Palette.moss)),
                const SizedBox(height: 12),
                if (!me) ...[
                  switch (state) {
                    null => FilledButton.icon(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _guard(ctx, service.addFriend(id)),
                        label: Text(tr('CHIEDI L\'AMICIZIA')),
                      ),
                    1 => OutlinedButton(
                        onPressed: () => _guard(ctx, service.removeFriend(id)),
                        child: Text(tr('Richiesta inviata · annulla')),
                      ),
                    2 => FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: () => _guard(ctx, service.acceptFriend(id)),
                        label: Text(tr('ACCETTA L\'AMICIZIA')),
                      ),
                    _ => OutlinedButton(
                        onPressed: () => _guard(ctx, service.removeFriend(id)),
                        child: Text(tr('Amici · togli')),
                      ),
                  },
                  if (canRecruit) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.shield),
                      onPressed: () => _guard(ctx, service.addToGuild(id)),
                      label: Text(tr('PORTA IN GILDA')),
                    ),
                  ],
                  if (canDuel) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.sports_kabaddi),
                      style: FilledButton.styleFrom(backgroundColor: Palette.blood),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _challenge(context, service, id, name);
                      },
                      label: Text(tr('SFIDA')),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _challenge(BuildContext context, GuildService service, String id, String name) async {
  final c = await _pickChallenge(context, tr('Sfida {name}', {'name': name}));
  if (c == null || !context.mounted) return;
  final match = await _guard(context, service.openSession(c.exercise, opponent: id));
  if (match != null && context.mounted) {
    _live(context, service, c.exercise, match, LiveMode.friendly);
  }
}

/// La mia gilda: il salone coi cavalieri, sfide, allenamenti, membri.
class _MyGuild extends StatelessWidget {
  const _MyGuild({required this.service});
  final GuildService service;

  @override
  Widget build(BuildContext context) {
    final g = service;
    final guild = g.guild!;
    final rooms = g.sessions.where((x) => !x.friendly).toList();
    final asking = g.members.where((m) => m.state == 3).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!g.live) const _Offline(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.shield, color: Sections.guild, size: 40),
                const SizedBox(height: 6),
                OneLine(
                  guild.name.toUpperCase(),
                  align: Alignment.center,
                  style: const TextStyle(
                    fontFamily: kTitleFont,
                    fontSize: 22,
                    letterSpacing: 3,
                    color: Palette.goldBright,
                  ),
                ),
                if (guild.description.isNotEmpty)
                  Text(
                    guild.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 4),
                Text(
                  tr('{n} membri', {'n': g.members.where((m) => m.state <= 2).length}),
                  style: const TextStyle(color: Palette.ash),
                ),
                const SizedBox(height: 8),
                _Hall(members: g.members, service: g),
              ],
            ),
          ),
        ),
        if (g.error != null) _Error(g.error!),
        if (asking.isNotEmpty && g.isLeader) ...[
          SectionTitle(tr('Chiedono di entrare')),
          for (final m in asking)
            _KnightTile(
              name: m.name,
              hero: m.hero,
              online: m.online,
              trailing: FilledButton(
                onPressed: () => _guard(context, g.acceptMember(m.id)),
                child: Text(tr('ACCETTA')),
              ),
            ),
        ],
        if (g.challenges.isNotEmpty) ...[
          SectionTitle(tr('Sfide ricevute')),
          for (final c in g.challenges)
            ActionTile(
              icon: Icons.sports_kabaddi,
              color: Palette.blood,
              title: c.from,
              subtitle: exercises[c.exercise]!.name,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: tr('Rifiuta'),
                    icon: const Icon(Icons.close, color: Palette.ash),
                    onPressed: () => _guard(context, g.dismiss(c)),
                  ),
                  FilledButton(
                    onPressed: () {
                      g.dismiss(c);
                      _live(context, g, c.exercise, c.matchId, LiveMode.friendly);
                    },
                    child: Text(tr('ACCETTA')),
                  ),
                ],
              ),
            ),
        ],
        SectionTitle(tr('Allenamenti in corso')),
        if (!g.live)
          Text(
            tr('Le sfide e gli allenamenti in diretta arrivano con il server online.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          )
        else ...[
          if (rooms.isEmpty)
            Text(
              tr('Nessuno si sta allenando adesso. Aprine uno: chi è in gilda lo vede qui e si unisce.'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.ash),
            ),
          for (final r in rooms)
            ActionTile(
              icon: Icons.groups,
              color: Sections.guild,
              title: '${r.hostName} · ${exercises[r.exercise]!.name}',
              subtitle: tr('{n} su 4 nella sala', {'n': r.size}),
              trailing: FilledButton(
                onPressed: () => _live(context, g, r.exercise, r.matchId, LiveMode.group),
                child: Text(tr('UNISCITI')),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final c = await _pickChallenge(context, tr('Allenati con la gilda'));
              if (c == null || !context.mounted) return;
              final id = await _guard(context, g.openSession(c.exercise));
              if (id != null && context.mounted) _live(context, g, c.exercise, id, LiveMode.group);
            },
            label: Text(tr('APRI UN ALLENAMENTO')),
          ),
        ],
        SectionTitle(tr('Membri')),
        for (final m in g.members.where((m) => m.state <= 2)) _MemberTile(service: g, member: m),
        _Invite(service: g),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Palette.stone,
                  title: Text(tr('Lasciare {guild}?', {'guild': guild.name})),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr('Resto')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr('Lascio')),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) _guard(context, g.leave());
            },
            child: Text(tr('Lascia la gilda'), style: const TextStyle(color: Palette.ash)),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.service, required this.member});
  final GuildService service;
  final GuildMember member;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final me = m.id == service.myId;
    return _KnightTile(
      name: me ? tr('{name} (tu)', {'name': m.name}) : m.name,
      hero: m.hero,
      online: m.online,
      subtitle: _role(m.state),
      onTap: () => showKnight(context, service, id: m.id, name: m.name, hero: m.hero, online: m.online),
      trailing: !me && service.live
          ? FilledButton(
              onPressed: () => _challenge(context, service, m.id, m.name),
              child: Text(tr('SFIDA')),
            )
          : null,
    );
  }
}

/// Porta in gilda gli amici, o invita per nome.
class _Invite extends StatefulWidget {
  const _Invite({required this.service});
  final GuildService service;

  @override
  State<_Invite> createState() => _InviteState();
}

class _InviteState extends State<_Invite> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.service;
    final inGuild = g.members.map((m) => m.id).toSet();
    final free = g.friends.where((f) => f.state == 0 && !inGuild.contains(f.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(tr('Invita')),
        if (g.isLeader)
          for (final f in free)
            _KnightTile(
              name: f.name,
              hero: f.hero,
              online: f.online,
              subtitle: tr('Amico'),
              trailing: FilledButton(
                onPressed: () => _guard(context, g.addToGuild(f.id)),
                child: Text(tr('IN GILDA')),
              ),
            ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                decoration: InputDecoration(labelText: tr('Nome del giocatore')),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                final text = await _guard(context, g.invite(name));
                if (text != null && context.mounted) {
                  _name.clear();
                  _snack(context, text);
                }
              },
              child: Text(tr('INVITA')),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            g.isLeader
                ? tr('Cerca altri cavalieri nella scheda Cavalieri: prima diventate amici, poi li porti in gilda.')
                : tr('Solo fondatore e ufficiali fanno entrare: tu mandi la richiesta d\'amicizia.'),
            style: const TextStyle(color: Palette.ash, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// La seconda scheda: cercare cavalieri, richieste d'amicizia, amici.
class _Knights extends StatefulWidget {
  const _Knights({required this.service});
  final GuildService service;

  @override
  State<_Knights> createState() => _KnightsState();
}

class _KnightsState extends State<_Knights> {
  final _search = TextEditingController();
  bool _searched = false;

  GuildService get g => widget.service;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _find() {
    final q = _search.text.trim();
    if (q.isEmpty && g.live) {
      _snack(context, tr('Scrivi almeno l\'inizio del nome.'));
      return;
    }
    setState(() => _searched = true);
    _guard(context, g.searchPlayers(q));
  }

  Widget _friendAction(String id, int? state) => switch (state) {
        null => FilledButton(
            onPressed: () => _guard(context, g.addFriend(id)),
            child: Text(tr('AMICIZIA')),
          ),
        1 => Text(tr('Inviata'), style: const TextStyle(color: Palette.ash)),
        2 => FilledButton(
            onPressed: () => _guard(context, g.acceptFriend(id)),
            child: Text(tr('ACCETTA')),
          ),
        _ => const Icon(Icons.check, color: Palette.moss),
      };

  @override
  Widget build(BuildContext context) {
    final asked = g.friends.where((f) => f.state == 2).toList();
    final sent = g.friends.where((f) => f.state == 1).toList();
    final mates = g.friends.where((f) => f.state == 0).toList();
    void open(String id, String name, HeroCard? hero, bool online) =>
        showKnight(context, g, id: id, name: name, hero: hero, online: online);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!g.live) const _Offline(),
        SectionTitle(tr('Cerca cavalieri')),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(labelText: tr('Nome del cavaliere')),
                onSubmitted: (_) => _find(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _find, child: Text(tr('CERCA'))),
          ],
        ),
        const SizedBox(height: 8),
        if (_searched && g.players.isEmpty)
          Text(
            tr('Nessun cavaliere con questo nome.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          ),
        if (_searched)
          for (final p in g.players)
            _KnightTile(
              name: p.name,
              hero: p.hero,
              online: p.online,
              onTap: () => open(p.id, p.name, p.hero, p.online),
              trailing: _friendAction(p.id, g.friendState(p.id)),
            ),
        if (asked.isNotEmpty) ...[
          SectionTitle(tr('Richieste ricevute')),
          for (final f in asked)
            _KnightTile(
              name: f.name,
              hero: f.hero,
              online: f.online,
              onTap: () => open(f.id, f.name, f.hero, f.online),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: tr('Rifiuta'),
                    icon: const Icon(Icons.close, color: Palette.ash),
                    onPressed: () => _guard(context, g.removeFriend(f.id)),
                  ),
                  FilledButton(
                    onPressed: () => _guard(context, g.acceptFriend(f.id)),
                    child: Text(tr('ACCETTA')),
                  ),
                ],
              ),
            ),
        ],
        SectionTitle(tr('Amici')),
        if (mates.isEmpty)
          Text(
            tr('Ancora nessun amico. Cerca un cavaliere per nome e chiedigli l\'amicizia.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          ),
        for (final f in mates)
          _KnightTile(
            name: f.name,
            hero: f.hero,
            online: f.online,
            onTap: () => open(f.id, f.name, f.hero, f.online),
            trailing: const Icon(Icons.chevron_right, color: Sections.guild),
          ),
        if (sent.isNotEmpty) ...[
          SectionTitle(tr('Richieste inviate')),
          for (final f in sent)
            _KnightTile(
              name: f.name,
              hero: f.hero,
              online: f.online,
              subtitle: tr('in attesa'),
              onTap: () => open(f.id, f.name, f.hero, f.online),
              trailing: IconButton(
                tooltip: tr('Annulla'),
                icon: const Icon(Icons.close, color: Palette.ash),
                onPressed: () => _guard(context, g.removeFriend(f.id)),
              ),
            ),
        ],
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child:
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Palette.blood)),
      );
}

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );

/// Esegue un'azione sul server: se fallisce lo dice e ritorna null.
Future<T?> _guard<T>(BuildContext context, Future<T> action) async {
  try {
    return await action;
  } catch (e) {
    if (context.mounted) _snack(context, '$e');
    return null;
  }
}

Future<ArenaChallenge?> _pickChallenge(BuildContext context, String title) {
  return showModalBottomSheet<ArenaChallenge>(
    context: context,
    backgroundColor: Palette.stone,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(title),
          for (final c in arenaChallenges.values)
            ActionTile(
              icon: Icons.fitness_center,
              color: Sections.guild,
              title: exercises[c.exercise]!.name,
              subtitle: c.description,
              onTap: () => Navigator.pop(ctx, c),
            ),
        ],
      ),
    ),
  );
}

/// Entra nel duello o nell'allenamento; al ritorno la lista si aggiorna.
Future<void> _live(
  BuildContext context,
  GuildService service,
  ExerciseId exercise,
  String matchId,
  LiveMode mode,
) async {
  if (!context.read<GameState>().useCamera) {
    _snack(
      context,
      tr('Le sfide dal vivo richiedono la fotocamera: le rep devono essere verificate.'),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArenaLiveScreen(
        challenge: arenaChallenges[exercise]!,
        matchId: matchId,
        mode: mode,
      ),
    ),
  );
  await service.refresh();
}
