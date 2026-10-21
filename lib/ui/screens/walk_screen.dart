import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../../health/live_steps.dart';
import '../../health/step_source.dart';
import '../widgets/common.dart';
import 'codex_screen.dart';
import '../widgets/trainer.dart';
import '../../core/sound.dart';

/// La Camminata: i passi di oggi (Samsung Health, Google Fit, smartwatch,
/// tramite Health Connect o Salute) diventano minerale, legno e pietre.
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key, this.asTab = false});

  /// Come scheda in basso: il consiglio lo mostra la barra quando la apri.
  final bool asTab;

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> with WidgetsBindingObserver {
  final _source = StepSource();
  StepAccess? _access;
  int? _steps;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!widget.asTab) maybeShowHint(context, 'walk');
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Tornando da Health Connect o dal Play Store si ricontrolla.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final access = await _source.access();
    int? steps;
    if (access == StepAccess.ready) steps = await _source.stepsToday();
    if (!mounted) return;
    // I passi nuovi vanno subito in riserva: un solo numero da spendere.
    if (steps != null) context.read<GameState>().collectSteps(steps);
    setState(() {
      _access = access;
      _steps = steps;
    });
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    if (_access == StepAccess.needsHealthConnect) {
      await _source.installHealthConnect();
    } else {
      await _source.requestPermission();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: OathBar(title: Text(tr('Gathering').toUpperCase()), accent: Sections.gathering),
      body: RefreshIndicator(
        onRefresh: _refresh,
        // Tutto in una schermata: i passi in grande, poi Foresta e Miniera.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: max(box.maxHeight, 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BigSteps(steps: s.stepBank, known: _steps != null || s.stepBank > 0),
                    if (_access != null && _access != StepAccess.ready)
                      _ConnectCard(access: _access!, busy: _busy, onConnect: _connect),
                    const SizedBox(height: 12),
                    Expanded(child: _RealmButton(skill: Skill.woodcutting, steps: _steps)),
                    const SizedBox(height: 12),
                    Expanded(child: _RealmButton(skill: Skill.mining, steps: _steps)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// I passi da spendere, grandi, in cima alla Raccolta.
class _BigSteps extends StatelessWidget {
  const _BigSteps({required this.steps, required this.known});
  final int steps;
  final bool known;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_walk, color: Palette.goldBright, size: 44),
              const SizedBox(width: 8),
              Text(
                known ? '$steps' : '—',
                style: titleStyle(size: 52, color: Palette.holy, spacing: 1).copyWith(
                  shadows: [Shadow(color: Palette.gold.withValues(alpha: 0.5), blurRadius: 16)],
                ),
              ),
            ],
          ),
          Text(tr('passi da spendere').toUpperCase(),
              style: titleStyle(size: 12, color: Palette.ash, spacing: 2.5)),
        ],
      );
}

/// Il piccolo contatore dei passi nella testata: si aggiorna subito.
class StepsChip extends StatelessWidget {
  const StepsChip({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.select<GameState, int>((s) => s.stepBank);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.directions_walk, color: Palette.goldBright, size: 18),
      const SizedBox(width: 2),
      Text('$bank', style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold)),
    ]);
  }
}

extension on Skill {
  String get realm => this == Skill.mining ? tr('Miniera') : tr('Foresta');
  Color get realmColor => this == Skill.mining ? Palette.frost : Sections.gathering;
}

/// Pulsantone della Foresta o della Miniera: la risorsa migliore che sai
/// raccogliere, livello del mestiere e quante ce ne sono.
class _RealmButton extends StatelessWidget {
  const _RealmButton({required this.skill, required this.steps});
  final Skill skill;
  final int? steps;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final list = resources.where((r) => r.skill == skill).toList();
    final open = list.where(s.canGather).toList();
    final best = open.isEmpty ? list.first : open.last;
    final (lvl, xpIn, xpNeed) = s.skillProgressOf(skill);
    final color = skill.realmColor;
    return Card(
      margin: EdgeInsets.zero,
      shape: GildedBorder(color: color, ornate: true),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GatherListScreen(skill: skill, stepsToday: steps)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              LayoutBuilder(
                builder: (context, b) =>
                    ResourcePortrait(best.id, size: min(b.maxHeight, 150), border: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.realm.toUpperCase(), style: titleStyle(size: 24, color: color, spacing: 3)),
                    const SizedBox(height: 4),
                    Text('${skill.label} · ${tr('Liv. {n}', {'n': lvl})}',
                        style: const TextStyle(color: Palette.holy, fontSize: 15)),
                    const SizedBox(height: 6),
                    StatBar(value: xpIn / xpNeed, color: color, height: 6),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 2,
                      children: [for (final r in open.reversed.take(4)) ItemIcon(r.id, size: 26)],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}

/// La lista dei legni o dei minerali, con i passi in piccolo nella testata.
class GatherListScreen extends StatelessWidget {
  const GatherListScreen({super.key, required this.skill, this.stepsToday});
  final Skill skill;
  final int? stepsToday;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final list = unlockedPlusNext(
        resources.where((r) => r.skill == skill).toList(), (r) => r.level, s.skillLevel(skill));
    return Scaffold(
      appBar: OathBar(
        title: Text(skill.realm.toUpperCase()),
        accent: skill.realmColor,
        actions: const [StepsChip()],
      ),
      body: FoldedListView(
        padding: const EdgeInsets.all(16),
        children: [for (final r in list) _ResourceCard(resource: r, stepsToday: stepsToday)],
      ),
    );
  }
}

/// Una risorsa come un mostro della caccia: l'immagine grande a sinistra,
/// a destra passi, scorta e cosa manca, a colpo d'occhio.
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, this.stepsToday});
  final Resource resource;
  final int? stepsToday;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final r = resource;
    final levelOk = s.skillLevel(r.skill) >= r.level;
    final unlocked = s.canGather(r);
    final selected = s.gatherTarget == r.id;
    final bonus = s.gatherBonus(r.skill);
    final steps = s.stepsPerUnit(r);
    final have = s.character.materials[r.id] ?? 0;
    final ring = selected ? Palette.goldBright : (unlocked ? Palette.gold : Palette.iron);
    void open() {
      s.setGatherTarget(r.id);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GatherScreen(resource: r, stepsToday: stepsToday)),
      );
    }

    Widget fact(IconData icon, String text, Color color) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        );

    return Card(
      shape: selected ? const GildedBorder(color: Palette.goldBright, ornate: true) : null,
      child: InkWell(
        onTap: unlocked ? open : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ResourcePortrait(r.id, size: 96, border: ring, dim: !unlocked),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OneLine(r.name,
                        align: Alignment.centerLeft,
                        style: titleStyle(size: 15, spacing: 1)
                            .copyWith(color: unlocked ? null : Palette.ash)),
                    const SizedBox(height: 6),
                    if (!levelOk)
                      fact(Icons.lock_outline, tr('Liv. {n}', {'n': r.level}), Palette.ember)
                    else if (!unlocked)
                      CodexTap(
                        r.tool!,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_outline, size: 18, color: Palette.ember),
                          const SizedBox(width: 4),
                          ItemIcon(r.tool!, size: 30),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(materialNames[r.tool] ?? r.tool!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Palette.ember, fontSize: 14)),
                          ),
                        ]),
                      )
                    else
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          fact(Icons.directions_walk, '$steps', Palette.holy),
                          fact(Icons.inventory_2_outlined, '$have', Palette.goldBright),
                          if (bonus > 0) fact(Icons.handyman, '+${(bonus * 100).round()}%', Palette.frost),
                        ],
                      ),
                  ],
                ),
              ),
              if (unlocked)
                Icon(selected ? Icons.check_circle : Icons.chevron_right, color: ring, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.access, required this.busy, required this.onConnect});
  final StepAccess access;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final android = !Platform.isIOS;
    final (text, button) = switch (access) {
      StepAccess.unsupported => (tr('I passi si leggono solo sul telefono.'), null),
      StepAccess.needsHealthConnect => (
          tr('Serve Health Connect di Google: raccoglie i passi di Samsung Health, '
              'Google Fit e smartwatch.'),
          tr('INSTALLA HEALTH CONNECT'),
        ),
      _ => (
          android
              ? tr('Concedi a Gym Oath di leggere i passi. Su Samsung: apri Samsung Health › '
                  'Impostazioni › Health Connect e attiva la condivisione dei passi.')
              : tr('Concedi a Gym Oath di leggere i passi da Salute.'),
          tr('COLLEGA I PASSI'),
        ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text),
            if (button != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: busy ? null : onConnect, child: Text(button)),
            ],
          ],
        ),
      ),
    );
  }
}

/// «MINA», «TAGLIA» o «RACCOGLI», secondo il mestiere.
String gatherVerb(Skill k) => switch (k) {
      Skill.mining => tr('MINA'),
      Skill.woodcutting => tr('TAGLIA'),
      _ => tr('RACCOGLI'),
    };

String _liveVerb(Skill k) => switch (k) {
      Skill.mining => tr('INIZIA A MINARE'),
      Skill.woodcutting => tr('INIZIA A TAGLIARE'),
      _ => tr('INIZIA A RACCOGLIERE'),
    };

/// Una risorsa. Due modi di raccoglierla: spendere quanti passi vuoi tra
/// quelli già fatti, oppure premere il pulsante e camminare: i passi nuovi
/// riempiono la barra dal vivo e a ogni soglia esce un'unità.
class GatherScreen extends StatefulWidget {
  const GatherScreen({super.key, required this.resource, this.stepsToday});
  final Resource resource;

  /// Passi letti dalla Camminata; se mancano si rileggono.
  final int? stepsToday;

  @override
  State<GatherScreen> createState() => _GatherScreenState();
}

class _GatherScreenState extends State<GatherScreen> {
  bool _known = false;

  /// Quante unità spendere dalla riserva.
  int _units = 1;

  LiveSteps? _live;
  bool _starting = false;

  /// Passi della raccolta dal vivo non ancora diventati un'unità.
  int _charge = 0;
  int _sessionSteps = 0;
  int _sessionUnits = 0;

  _Gain? _popup;
  int _popupId = 0;

  Resource get _r => widget.resource;

  @override
  void initState() {
    super.initState();
    final steps = widget.stepsToday;
    if (steps != null) {
      _known = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<GameState>().collectSteps(steps);
      });
    } else {
      _read();
    }
  }

  @override
  void dispose() {
    _live?.stop();
    super.dispose();
  }

  Future<void> _read() async {
    final src = StepSource();
    if (await src.access() != StepAccess.ready) return;
    final steps = await src.stepsToday();
    if (!mounted || steps == null) return;
    context.read<GameState>().collectSteps(steps);
    setState(() => _known = true);
  }

  /// Fa l'unità, mostra in sovraimpressione oggetto, XP e livello.
  void _gain(GameState s, int steps) {
    final (lvlBefore, xpInBefore, xpNeedBefore) = s.skillProgressOf(_r.skill);
    final (units, _) = s.spendSteps(_r.id, steps);
    if (units == 0) return;
    final (lvl, xpIn, xpNeed) = s.skillProgressOf(_r.skill);
    Sound.play(_r.skill == Skill.mining ? Sfx.gatherOre : Sfx.gatherWood);
    final id = ++_popupId;
    setState(() {
      _units = 1;
      _popup = _Gain(
        id: _r.id,
        units: units,
        xp: units * _r.xp,
        level: lvl,
        leveledUp: lvl > lvlBefore,
        from: lvl > lvlBefore ? 0 : xpInBefore / xpNeedBefore,
        to: xpIn / xpNeed,
      );
    });
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _popupId == id) setState(() => _popup = null);
    });
  }

  Future<void> _toggleLive() async {
    if (_live != null) {
      _live!.stop();
      setState(() => _live = null);
      return;
    }
    setState(() => _starting = true);
    final s = context.read<GameState>();
    var first = true;
    final live = LiveSteps((today) {
      if (!mounted) return;
      final fresh = s.collectSteps(today);
      // La prima lettura porta solo i passi già fatti: vanno in riserva.
      if (first) {
        first = false;
        return;
      }
      if (fresh <= 0) return;
      _sessionSteps += fresh;
      _charge += fresh;
      final per = s.stepsPerUnit(_r);
      if (_charge >= per) {
        final full = _charge ~/ per * per;
        _charge -= full;
        _sessionUnits += full ~/ per;
        _gain(s, full);
      } else {
        setState(() {});
      }
    });
    final ok = await live.start();
    if (!mounted) {
      live.stop();
      return;
    }
    setState(() {
      _starting = false;
      if (ok) {
        _live = live;
        _charge = 0;
        _sessionSteps = 0;
        _sessionUnits = 0;
      }
    });
    if (!ok) toast(context, tr('Collega i passi nella Raccolta per raccogliere camminando.'));
  }

  /// «Spendili tutti»: prima chiede, con l'immagine di cosa esce.
  Future<void> _spendAll(GameState s, int ready, int per) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Spendili tutti?'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResourcePortrait(_r.id, size: 130),
            const SizedBox(height: 10),
            Text('$ready × ${_r.name}',
                textAlign: TextAlign.center, style: titleStyle(size: 16, color: Palette.goldBright)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatChip(Icons.directions_walk, '-${ready * per}', color: Palette.holy),
                const SizedBox(width: 14),
                StatChip(Icons.auto_awesome, '+${ready * _r.xp} XP', color: Palette.goldBright),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annulla'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('CONFERMA'))),
        ],
      ),
    );
    if (ok == true && mounted) _gain(s, ready * per);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final per = s.stepsPerUnit(_r);
    final bank = s.stepBank;
    final ready = bank ~/ per;
    final units = min(max(_units, 1), max(1, ready));
    final (lvl, xpIn, xpNeed) = s.skillProgressOf(_r.skill);
    final live = _live != null;
    final verb = gatherVerb(_r.skill);
    final have = s.character.materials[_r.id] ?? 0;
    return Scaffold(
      appBar: OathBar(
        title: Text(_r.skill.realm.toUpperCase()),
        accent: _r.skill.realmColor,
        actions: const [StepsChip()],
      ),
      body: Stack(
        children: [
          // Una schermata sola e sempre piena: chi è in alto, la scelta dei
          // passi al centro che prende tutto lo spazio, camminare in fondo.
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: SizedBox(
                height: max(box.maxHeight, 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ResourcePortrait(_r.id, size: 130),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_r.name, style: titleStyle(size: 17, spacing: 1)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    StatChip(Icons.inventory_2_outlined, '$have', color: Palette.goldBright),
                                    StatChip(Icons.directions_walk, '$per', color: Palette.holy),
                                    StatChip(Icons.auto_awesome, '+${_r.xp}', color: Palette.ash),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${_r.skill.label} · ${tr('Liv. {n}', {'n': lvl})}',
                                    style: const TextStyle(color: Palette.ash, fontSize: 13)),
                                const SizedBox(height: 4),
                                StatBar(value: xpIn / xpNeed, color: _r.skill.realmColor, height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: _Panel(
                          child: !_known && bank == 0
                              ? Center(
                                  child: Text(tr('Collega i passi nella Raccolta per spenderli qui.'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Palette.ash, fontSize: 16)),
                                )
                              : ready == 0
                                  ? Center(
                                      child: Text(
                                        tr('Ti servono ancora {n} passi per la prossima unità.',
                                            {'n': per - bank % per}),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Palette.ash, fontSize: 16),
                                      ),
                                    )
                                  : _ChooseUnits(
                                      units: units,
                                      ready: ready,
                                      per: per,
                                      xp: _r.xp,
                                      verb: verb,
                                      color: _r.skill.realmColor,
                                      onChanged: (n) => setState(() => _units = n),
                                      onTake: () => _gain(s, units * per),
                                      onAll: () => _spendAll(s, ready, per),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Panel(
                        active: live,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (live) ...[
                              StatBar(
                                value: _charge / per,
                                color: Sections.gathering,
                                height: 22,
                                label: tr('{a} / {b} passi', {'a': _charge, 'b': per}),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StatChip(Icons.directions_walk, '$_sessionSteps', color: Palette.holy),
                                  const SizedBox(width: 14),
                                  StatChip(Icons.inventory_2_outlined, '+$_sessionUnits',
                                      color: Palette.goldBright),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            live
                                ? OutlinedButton.icon(
                                    onPressed: _toggleLive,
                                    icon: const Icon(Icons.stop_circle_outlined),
                                    label: Text(tr('FERMA')),
                                  )
                                : FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: Sections.gathering),
                                    onPressed: _starting ? null : _toggleLive,
                                    icon: const Icon(Icons.directions_walk),
                                    label: Text(_liveVerb(_r.skill)),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_popup != null)
            Positioned.fill(
              child: _GatherPopup(key: ValueKey(_popupId), gain: _popup!, skill: _r.skill),
            ),
        ],
      ),
    );
  }
}

/// La scelta dei passi, grande: quante unità in cifre, cursore spesso con
/// meno e più, PRENDI e SPENDILI TUTTI.
class _ChooseUnits extends StatelessWidget {
  const _ChooseUnits({
    required this.units,
    required this.ready,
    required this.per,
    required this.xp,
    required this.verb,
    required this.color,
    required this.onChanged,
    required this.onTake,
    required this.onAll,
  });
  final int units, ready, per, xp;
  final String verb;
  final Color color;
  final ValueChanged<int> onChanged;
  final VoidCallback onTake, onAll;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, int to) => IconButton.outlined(
          iconSize: 30,
          style: IconButton.styleFrom(
            foregroundColor: Palette.goldBright,
            side: const BorderSide(color: Palette.gold),
          ),
          onPressed: to >= 1 && to <= ready && to != units ? () => onChanged(to) : null,
          icon: Icon(icon),
        );
    // Scorciatoie: 1, 5, 10, 25 e metà; tutti è il pulsante in fondo.
    final quick = {for (final n in [5, 10, 25, ready ~/ 2]) if (n > 1 && n < ready) n}.toList()..sort();
    Widget pick(int n, String label) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(label),
            selected: units == n,
            showCheckmark: false,
            selectedColor: Palette.gold,
            labelStyle: TextStyle(color: units == n ? Palette.night : Palette.holy),
            onSelected: (_) => onChanged(n),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr('quanti ne prendi').toUpperCase(),
            textAlign: TextAlign.center, style: titleStyle(size: 12, color: Palette.ash, spacing: 2.5)),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$units×',
                  style: titleStyle(size: 120, color: Palette.holy, spacing: 0).copyWith(
                    shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 24)],
                  )),
            ),
          ),
        ),
        if (quick.isNotEmpty) ...[
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 6,
            children: [
              pick(1, '1'),
              for (final n in quick) pick(n, n == ready ~/ 2 && n != 5 && n != 10 && n != 25 ? tr('metà') : '$n'),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatChip(Icons.directions_walk, '-${units * per}', color: Palette.holy),
            const SizedBox(width: 16),
            StatChip(Icons.auto_awesome, '+${units * xp} XP', color: Palette.goldBright),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            step(Icons.remove, units - 1),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                  activeTrackColor: color,
                  inactiveTrackColor: Palette.iron,
                  thumbColor: Palette.goldBright,
                ),
                child: Slider(
                  value: units.toDouble(),
                  min: 1,
                  max: max(ready, 2).toDouble(),
                  divisions: max(ready - 1, 1),
                  label: '$units',
                  onChanged: ready > 1 ? (v) => onChanged(v.round()) : null,
                ),
              ),
            ),
            step(Icons.add, units + 1),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton(onPressed: onTake, child: Text('$verb $units×')),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: onAll,
                  child: FittedBox(child: Text(tr('TUTTI · {n}×', {'n': ready}))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.active = false});
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Palette.stoneLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Sections.gathering : Palette.iron,
            width: active ? 2 : 1,
          ),
        ),
        child: child,
      );
}

/// Cosa è appena uscito: per la sovraimpressione.
class _Gain {
  const _Gain({
    required this.id,
    required this.units,
    required this.xp,
    required this.level,
    required this.leveledUp,
    required this.from,
    required this.to,
  });
  final String id;
  final int units;
  final int xp;
  final int level;
  final bool leveledUp;

  /// Riempimento della barra XP prima e dopo.
  final double from;
  final double to;
}

/// Sovraimpressione al centro: l'oggetto raccolto, gli XP guadagnati e la
/// barra del mestiere che sale.
class _GatherPopup extends StatelessWidget {
  const _GatherPopup({super.key, required this.gain, required this.skill});
  final _Gain gain;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final g = gain;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        builder: (_, t, _) {
          final pop = Curves.easeOutBack.transform((t / 0.5).clamp(0.0, 1.0));
          final fill = Curves.easeOut.transform(((t - 0.3) / 0.7).clamp(0.0, 1.0));
          return Opacity(
            opacity: (t / 0.25).clamp(0.0, 1.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Transform.scale(
                scale: 0.6 + 0.4 * pop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Palette.gold.withValues(alpha: 0.35), Palette.gold.withValues(alpha: 0)],
                        ),
                      ),
                      child: ItemIcon(g.id, size: 110),
                    ),
                    OneLine(
                      '+${g.units} ${itemName(g.id)}',
                      align: Alignment.center,
                      style: titleStyle(size: 24, color: Palette.holy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('+{xp} XP {skill}', {'xp': g.xp, 'skill': skill.label}),
                      style: titleStyle(size: 18, color: Sections.gathering),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          tr('Livello {n}', {'n': g.level}),
                          style: titleStyle(
                            size: 15,
                            color: g.leveledUp ? Palette.goldBright : Palette.holy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatBar(
                            value: g.from + (g.to - g.from) * fill,
                            color: Palette.goldBright,
                            height: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
