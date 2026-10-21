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
import '../../domain/walking.dart';
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

  void _claim(GameState s) {
    final steps = _steps;
    if (steps == null) return;
    final r = resourceById(s.gatherTarget);
    final (units, levels) = s.claimSteps(steps);
    if (units == 0) {
      toast(context, tr('Ancora qualche passo: servono {n} passi per {res}.', {'n': r.stepsPerUnit, 'res': r.name}));
      return;
    }
    toast(
      context,
      '+$units ${r.name}'
      '${levels > 0 ? tr(' · {skill} sale al livello {lvl}!', {'skill': r.skill.label, 'lvl': s.skillLevel(r.skill)}) : ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final steps = _steps ?? 0;
    final target = resourceById(s.gatherTarget);
    final fresh = (min(steps, dailyStepCap) - s.daily.claimedSteps).clamp(0, dailyStepCap);
    final ready = (fresh + s.stepBank) ~/ target.stepsPerUnit;
    return Scaffold(
      appBar: OathBar(title: Text(tr('Gathering').toUpperCase()), accent: Sections.gathering),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: _StepRing(
                steps: fresh + s.stepBank,
                goal: target.stepsPerUnit,
                progress: ((fresh + s.stepBank) % target.stepsPerUnit) / target.stepsPerUnit,
                known: _steps != null,
              ),
            ),
            const SizedBox(height: 12),
            OneLine(
              tr('Stai raccogliendo: {res}', {'res': target.name}),
              align: Alignment.center,
              style: titleStyle(size: 15),
            ),
            Text(
              tr('{where} · {n} passi per unità', {'where': target.where, 'n': target.stepsPerUnit}),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.ash),
            ),
            const SizedBox(height: 12),
            if (_access == null)
              const Center(child: CircularProgressIndicator())
            else if (_access != StepAccess.ready)
              _ConnectCard(access: _access!, busy: _busy, onConnect: _connect)
            else
              FilledButton.icon(
                onPressed: fresh + s.stepBank > 0 ? () => _claim(s) : null,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  ready > 0
                      ? tr('RACCOGLI {n} × {res}', {'n': ready, 'res': target.name.toUpperCase()})
                      : tr('CAMMINA ANCORA'),
                ),
              ),
            for (final skill in [Skill.woodcutting, Skill.mining]) ...[
              SectionTitle(
                '${skill == Skill.woodcutting ? tr('Trees') : tr('Ores')} · ${skill.label}',
                trailing: Text(
                  tr('Livello {n}', {'n': s.skillLevel(skill)}),
                  style: const TextStyle(color: Palette.goldBright),
                ),
              ),
              Builder(
                builder: (_) {
                  final (_, xpIn, xpNeed) = skillProgress(s.skillXp[skill] ?? 0);
                  return StatBar(
                    value: xpIn / xpNeed,
                    color: Palette.gold,
                    label: xpLeftLabel(xpIn, xpNeed),
                  );
                },
              ),
              const SizedBox(height: 6),
              for (final r in unlockedPlusNext(resources.where((r) => r.skill == skill).toList(),
                  (r) => r.level, s.skillLevel(skill)))
                _resourceTile(s, r),
            ],
          ],
        ),
      ),
    );
  }

  /// Una risorsa come un mostro della caccia: l'immagine grande a sinistra,
  /// a destra passi, scorta e cosa manca, a colpo d'occhio.
  Widget _resourceTile(GameState s, Resource r) {
    final levelOk = s.skillLevel(r.skill) >= r.level;
    final unlocked = s.canGather(r);
    final selected = s.gatherTarget == r.id;
    final bonus = s.gatherBonus(r.skill);
    final steps = (r.stepsPerUnit / (1 + bonus)).round();
    final have = s.character.materials[r.id] ?? 0;
    final ring = selected ? Palette.goldBright : (unlocked ? Palette.gold : Palette.iron);
    void open() {
      s.setGatherTarget(r.id);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GatherScreen(resource: r, stepsToday: _steps)),
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

class _StepRing extends StatelessWidget {
  const _StepRing({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.known,
  });
  final int steps;
  final int goal;
  final double progress;
  final bool known;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0.0, 1.0)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_walk, color: Palette.gold, size: 28),
              Text(known ? '$steps' : '—', style: titleStyle(size: 34, color: Palette.holy)),
              Text(tr('da consumare'), style: const TextStyle(color: Palette.ash)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(8);
    canvas.drawArc(
      r,
      0,
      2 * pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = Palette.iron,
    );
    canvas.drawArc(
      r,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = Palette.goldBright,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
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
    return Scaffold(
      appBar: OathBar(title: Text(tr('Gathering').toUpperCase()), accent: Sections.gathering),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: ResourcePortrait(_r.id, size: 170)),
              const SizedBox(height: 6),
              OneLine(_r.name, align: Alignment.center, style: titleStyle(size: 20)),
              Text(
                tr('{where} · hai {n}', {'where': _r.where, 'n': s.character.materials[_r.id] ?? 0}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash),
              ),
              SectionTitle(
                _r.skill.label,
                trailing: Text(tr('Livello {n}', {'n': lvl}),
                    style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold)),
              ),
              StatBar(value: xpIn / xpNeed, color: Palette.gold, height: 12, label: xpLeftLabel(xpIn, xpNeed)),
              if (lvl < maxSkillLevel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr('Al livello {lvl}: ancora {n} raccolte, circa {steps} passi', {
                      'lvl': lvl + 1,
                      'n': ((xpNeed - xpIn) / _r.xp).ceil(),
                      'steps': ((xpNeed - xpIn) / _r.xp).ceil() * per,
                    }),
                    style: const TextStyle(color: Palette.ash, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                tr('+{xp} XP per ogni {res} · {per} passi l\'una',
                    {'xp': _r.xp, 'res': _r.name.toLowerCase(), 'per': per}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash, fontSize: 13),
              ),

              // 1. Dal vivo: premi e cammina.
              SectionTitle(tr('Raccogli camminando')),
              _Panel(
                active: live,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      live
                          ? tr('Cammina: ogni passo riempie la barra. Puoi tenere il telefono in tasca.')
                          : tr('Premi e cammina: i passi nuovi vanno tutti qui e la barra si riempie mentre cammini.'),
                      style: const TextStyle(color: Palette.holy, fontSize: 14),
                    ),
                    if (live) ...[
                      const SizedBox(height: 12),
                      StatBar(
                        value: _charge / per,
                        color: Sections.gathering,
                        height: 22,
                        label: tr('{a} / {b} passi', {'a': _charge, 'b': per}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('In questa uscita: {s} passi · {n} × {res}',
                            {'s': _sessionSteps, 'n': _sessionUnits, 'res': _r.name}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: 12),
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

              // 2. Con i passi già fatti: scegli quanti.
              SectionTitle(tr('Usa i passi già fatti')),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, color: Palette.gold),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('Passi da spendere: {n}', {'n': bank}),
                            style: titleStyle(size: 15, color: Palette.holy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_known && bank == 0)
                      Text(tr('Collega i passi nella Raccolta per spenderli qui.'),
                          style: const TextStyle(color: Palette.ash))
                    else if (ready == 0)
                      Text(
                        tr('Ti servono ancora {n} passi per la prossima unità.',
                            {'n': per - bank % per}),
                        style: const TextStyle(color: Palette.ash),
                      )
                    else ...[
                      if (ready > 1)
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: units.toDouble(),
                                min: 1,
                                max: ready.toDouble(),
                                divisions: ready - 1,
                                label: '$units',
                                onChanged: (v) => setState(() => _units = v.round()),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _units = ready),
                              child: Text(tr('TUTTI')),
                            ),
                          ],
                        ),
                      Text(
                        tr('{n} × {res} = {s} passi · +{xp} XP',
                            {'n': units, 'res': _r.name, 's': units * per, 'xp': units * _r.xp}),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Palette.goldBright, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _gain(s, units * per),
                        icon: Icon(_r.skill == Skill.mining ? Icons.hardware : Icons.forest),
                        label: Text('$verb $units × ${_r.name.toUpperCase()}'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
