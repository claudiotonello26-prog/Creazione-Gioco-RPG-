import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/pvp.dart';
import '../../online/guild_service.dart';
import '../../online/nakama_client.dart';
import '../widgets/common.dart';
import 'arena_live_screen.dart';
import 'settings_screen.dart';

/// La Gilda: fondarla o entrarci, invitare amici, allenarsi insieme in
/// diretta e sfidarsi tra amici. Tutto passa dal server online.
class GuildTab extends StatefulWidget {
  const GuildTab({super.key, this.service});

  /// Per i test: un servizio già pronto invece di quello verso il server.
  final GuildService? service;

  @override
  State<GuildTab> createState() => _GuildTabState();
}

class _GuildTabState extends State<GuildTab> {
  GuildService? _service;
  String _address = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.watch<GameState>();
    if (widget.service != null) {
      _service ??= widget.service;
      return;
    }
    if (s.serverAddress == _address) return;
    _address = s.serverAddress;
    _service?.dispose();
    _service = null;
    final config = ServerConfig.parse(_address);
    if (config == null) return;
    _service = GuildService(
      client: NakamaClient(config),
      deviceId: s.deviceId,
      username: s.character.name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), ''),
    )..refresh();
  }

  @override
  void dispose() {
    if (widget.service == null) _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    if (service == null) return const _NoServer();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => RefreshIndicator(
        onRefresh: service.refresh,
        child: service.guild == null || service.pending
            ? _NoGuild(service: service)
            : _MyGuild(service: service),
      ),
    );
  }
}

class _NoServer extends StatelessWidget {
  const _NoServer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Intro(),
        const SizedBox(height: 16),
        const Text(
          'La gilda vive sul server online: impostalo nelle Impostazioni per fondarne una o '
          'entrare in quella dei tuoi amici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.ash),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: const Text('IMPOSTAZIONI'),
          ),
        ),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.shield_outlined, color: Sections.guild, size: 40),
            SizedBox(height: 8),
            Text(
              'Una gilda è il tuo gruppo: vi allenate insieme in diretta e vi sfidate tra amici. '
              'Le sfide in gilda non toccano i punti dell\'Arena.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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

  GuildService get g => widget.service;

  @override
  void dispose() {
    _name.dispose();
    _motto.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Intro(),
        if (g.error != null) _Error(g.error!),
        if (g.pending)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Hai chiesto di entrare in ${g.guild!.name}: aspetta che un capo ti accetti.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.goldBright),
            ),
          ),
        const SectionTitle('Fonda una gilda'),
        TextField(
          controller: _name,
          maxLength: 24,
          decoration: const InputDecoration(labelText: 'Nome della gilda'),
        ),
        TextField(
          controller: _motto,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Motto (facoltativo)'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: g.loading
              ? null
              : () {
                  final name = _name.text.trim();
                  if (name.length < 3) {
                    _snack(context, 'Il nome deve avere almeno 3 lettere.');
                    return;
                  }
                  _guard(context, g.createGuild(name, _motto.text.trim()));
                },
          child: const Text('FONDA'),
        ),
        const SectionTitle('Cerca una gilda'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(labelText: 'Nome'),
                onSubmitted: (v) => _guard(context, g.search(v.trim())),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _guard(context, g.search(_search.text.trim())),
              child: const Text('CERCA'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final found in g.found)
          ActionTile(
            icon: Icons.shield_outlined,
            color: Sections.guild,
            title: found.name,
            subtitle: '${found.count} membri'
                '${found.description.isEmpty ? '' : ' · ${found.description}'}',
            trailing: FilledButton(
              onPressed: () => _guard(context, g.join(found.id)),
              child: const Text('ENTRA'),
            ),
          ),
        _Friends(service: g),
      ],
    );
  }
}

/// La mia gilda: sfide, allenamenti aperti, membri, inviti.
class _MyGuild extends StatelessWidget {
  const _MyGuild({required this.service});
  final GuildService service;

  @override
  Widget build(BuildContext context) {
    final g = service;
    final guild = g.guild!;
    final rooms = g.sessions.where((x) => !x.friendly).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                  '${g.members.where((m) => m.state <= 2).length} membri',
                  style: const TextStyle(color: Palette.ash),
                ),
              ],
            ),
          ),
        ),
        if (g.error != null) _Error(g.error!),
        if (g.challenges.isNotEmpty) ...[
          const SectionTitle('Sfide ricevute'),
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
                    tooltip: 'Rifiuta',
                    icon: const Icon(Icons.close, color: Palette.ash),
                    onPressed: () => _guard(context, g.dismiss(c)),
                  ),
                  FilledButton(
                    onPressed: () {
                      g.dismiss(c);
                      _live(context, g, c.exercise, c.matchId, LiveMode.friendly);
                    },
                    child: const Text('ACCETTA'),
                  ),
                ],
              ),
            ),
        ],
        const SectionTitle('Allenamenti in corso'),
        if (rooms.isEmpty)
          const Text(
            'Nessuno si sta allenando adesso. Aprine uno: chi è in gilda lo vede qui e si unisce.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.ash),
          ),
        for (final r in rooms)
          ActionTile(
            icon: Icons.groups,
            color: Sections.guild,
            title: '${r.hostName} · ${exercises[r.exercise]!.name}',
            subtitle: '${r.size} su 4 nella sala',
            trailing: FilledButton(
              onPressed: () => _live(context, g, r.exercise, r.matchId, LiveMode.group),
              child: const Text('UNISCITI'),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final c = await _pickChallenge(context, 'Allenati con la gilda');
            if (c == null || !context.mounted) return;
            final id = await _guard(context, g.openSession(c.exercise));
            if (id != null && context.mounted) _live(context, g, c.exercise, id, LiveMode.group);
          },
          label: const Text('APRI UN ALLENAMENTO'),
        ),
        const SectionTitle('Membri'),
        for (final m in g.members) _MemberTile(service: g, member: m),
        _Invite(service: g),
        _Friends(service: g),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Palette.stone,
                  title: Text('Lasciare ${guild.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Resto'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Lascio'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) _guard(context, g.leave());
            },
            child: const Text('Lascia la gilda', style: TextStyle(color: Palette.ash)),
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
    final role = switch (m.state) {
      0 => 'Fondatore',
      1 => 'Ufficiale',
      2 => 'Membro',
      _ => 'Chiede di entrare',
    };
    Widget? trailing;
    if (m.state == 3 && service.isLeader) {
      trailing = FilledButton(
        onPressed: () => _guard(context, service.acceptMember(m.id)),
        child: const Text('ACCETTA'),
      );
    } else if (!me && m.state <= 2) {
      trailing = FilledButton(
        onPressed: () async {
          final c = await _pickChallenge(context, 'Sfida ${m.name}');
          if (c == null || !context.mounted) return;
          final id = await _guard(context, service.openSession(c.exercise, opponent: m.id));
          if (id != null && context.mounted) {
            _live(context, service, c.exercise, id, LiveMode.friendly);
          }
        },
        child: const Text('SFIDA'),
      );
    }
    return ActionTile(
      icon: m.online ? Icons.circle : Icons.circle_outlined,
      color: m.online ? Palette.moss : Palette.ash,
      title: me ? '${m.name} (tu)' : m.name,
      subtitle: m.online ? '$role · online' : role,
      trailing: trailing,
    );
  }
}

/// Invita un giocatore per nome.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Invita'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome del giocatore'),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                final text = await _guard(context, widget.service.invite(name));
                if (text != null && context.mounted) {
                  _name.clear();
                  _snack(context, text);
                }
              },
              child: const Text('INVITA'),
            ),
          ],
        ),
        if (!widget.service.isLeader)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Solo fondatore e ufficiali fanno entrare: tu mandi la richiesta d\'amicizia.',
              style: TextStyle(color: Palette.ash, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

/// Amici: richieste ricevute e chi si può portare in gilda.
class _Friends extends StatelessWidget {
  const _Friends({required this.service});
  final GuildService service;

  @override
  Widget build(BuildContext context) {
    final g = service;
    final inGuild = g.members.map((m) => m.id).toSet();
    final list = g.friends.where((f) => f.state <= 2 && !inGuild.contains(f.id)).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Amici'),
        for (final f in list)
          ActionTile(
            icon: Icons.person_outline,
            title: f.name,
            subtitle: switch (f.state) {
              1 => 'Richiesta inviata',
              2 => 'Ti ha chiesto l\'amicizia',
              _ => g.guild == null ? 'Amico' : 'Non è nella gilda',
            },
            trailing: f.state == 2
                ? FilledButton(
                    onPressed: () => _guard(context, g.acceptFriend(f.id)),
                    child: const Text('ACCETTA'),
                  )
                : f.state == 0 && g.guild != null && g.isLeader && !g.pending
                    ? FilledButton(
                        onPressed: () => _guard(context, g.addToGuild(f.id)),
                        child: const Text('IN GILDA'),
                      )
                    : null,
          ),
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
    _snack(context, 'Le sfide dal vivo richiedono la fotocamera: le rep devono essere verificate.');
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
