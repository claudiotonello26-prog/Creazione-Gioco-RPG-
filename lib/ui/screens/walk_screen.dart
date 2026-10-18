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
import '../../health/step_source.dart';
import '../widgets/common.dart';
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
                    label: '$xpIn / $xpNeed XP',
                  );
                },
              ),
              const SizedBox(height: 6),
              for (final r in resources.where((r) => r.skill == skill)) _resourceTile(s, r),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resourceTile(GameState s, Resource r) {
    final levelOk = s.skillLevel(r.skill) >= r.level;
    final unlocked = s.canGather(r);
    final selected = s.gatherTarget == r.id;
    final bonus = s.gatherBonus(r.skill);
    final steps = (r.stepsPerUnit / (1 + bonus)).round();
    return ActionTile(
      icon: unlocked
          ? (selected ? Icons.radio_button_checked : Icons.radio_button_off)
          : Icons.lock_outline,
      color: selected ? Palette.goldBright : (unlocked ? Palette.gold : Palette.iron),
      title: r.name,
      subtitle: !levelOk
          ? tr('Si sblocca a {skill} livello {n}', {'skill': r.skill.label, 'n': r.level})
          : !unlocked
              ? tr('Serve: {tool} (si crea in Forgia)', {'tool': materialNames[r.tool]})
              : '${tr('{where} · {n} passi', {'where': r.where, 'n': steps})}'
                  '${bonus > 0 ? tr(' (attrezzo +{p}%)', {'p': (bonus * 100).round()}) : ''}'
                  '${tr(' · hai {n}', {'n': s.character.materials[r.id] ?? 0})}',
      enabled: unlocked,
      onTap: unlocked
          ? () {
              s.setGatherTarget(r.id);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GatherScreen(resource: r, stepsToday: _steps),
                ),
              );
            }
          : null,
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

/// Una risorsa: i passi di oggi si spendono qui. La barra si carica e ogni
/// [Resource.stepsPerUnit] passi esce un'unità, che compare al centro.
class GatherScreen extends StatefulWidget {
  const GatherScreen({super.key, required this.resource, this.stepsToday});
  final Resource resource;

  /// Passi letti dalla Camminata; se mancano si rileggono.
  final int? stepsToday;

  @override
  State<GatherScreen> createState() => _GatherScreenState();
}

class _GatherScreenState extends State<GatherScreen> {
  int? _steps;

  /// Cosa mostrare in sovraimpressione: (oggetto, quantità, abilità salita).
  (String, int, int)? _popup;

  Resource get _r => widget.resource;

  @override
  void initState() {
    super.initState();
    _steps = widget.stepsToday;
    if (_steps == null) _read();
  }

  Future<void> _read() async {
    final src = StepSource();
    if (await src.access() != StepAccess.ready) return;
    final steps = await src.stepsToday();
    if (mounted) setState(() => _steps = steps);
  }

  Future<void> _spend(GameState s) async {
    final steps = _steps;
    if (steps == null) return;
    s.setGatherTarget(_r.id);
    final before = s.skillLevel(_r.skill);
    final (units, _) = s.claimSteps(steps);
    if (units == 0) {
      toast(context, tr('La barra si carica: servono {n} passi per {res}.', {'n': _r.stepsPerUnit, 'res': _r.name}));
      return;
    }
    final after = s.skillLevel(_r.skill);
    Sound.play(_r.skill == Skill.mining ? Sfx.gatherOre : Sfx.gatherWood);
    setState(() => _popup = (_r.id, units, after > before ? after : 0));
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _popup = null);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final per = (_r.stepsPerUnit / (1 + s.gatherBonus(_r.skill))).round();
    final fresh = _steps == null
        ? 0
        : (min(_steps!, dailyStepCap) - s.daily.claimedSteps).clamp(0, dailyStepCap);
    final available = fresh + s.stepBank;
    final charge = (available % per) / per;
    final ready = available ~/ per;
    final (lvl, xpIn, xpNeed) = s.skillProgressOf(_r.skill);
    return Scaffold(
      appBar: OathBar(title: Text(tr('Gathering').toUpperCase()), accent: Sections.gathering),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: ItemIcon(_r.id, size: 120)),
              const SizedBox(height: 8),
              OneLine(_r.name, align: Alignment.center, style: titleStyle(size: 20)),
              Text(
                tr('{where} · hai {n}', {'where': _r.where, 'n': s.character.materials[_r.id] ?? 0}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash),
              ),
              SectionTitle(tr('Carica')),
              StatBar(
                value: charge,
                color: Palette.goldBright,
                height: 16,
                label: tr('{a} / {b} passi', {'a': available % per, 'b': per}),
              ),
              const SizedBox(height: 6),
              Text(
                _steps == null
                    ? tr('Collega i passi nella Raccolta per spenderli qui.')
                    : '${tr('Passi da spendere: {a} · ogni {per} passi un\'unità', {'a': available, 'per': per})}'
                        '${ready > 0 ? tr(' · pronte {n}', {'n': ready}) : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: available > 0 && _steps != null ? () => _spend(s) : null,
                icon: const Icon(Icons.directions_walk),
                label: Text(ready > 0 ? tr('CONSUMA I PASSI · {n}', {'n': ready}) : tr('CONSUMA I PASSI')),
              ),
              SectionTitle(
                _r.skill.label,
                trailing: Text(tr('Livello {n}', {'n': lvl}), style: const TextStyle(color: Palette.goldBright)),
              ),
              StatBar(
                value: xpIn / xpNeed,
                color: Palette.gold,
                height: 10,
                label: '$xpIn / $xpNeed XP',
              ),
              const SizedBox(height: 6),
              Text(
                tr('+{xp} XP per ogni {res}', {'xp': _r.xp, 'res': _r.name.toLowerCase()}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash, fontSize: 13),
              ),
            ],
          ),
          if (_popup != null)
            Positioned.fill(
              child: _GatherPopup(popup: _popup!, skill: _r.skill),
            ),
        ],
      ),
    );
  }
}

/// Sovraimpressione al centro: l'oggetto raccolto e, se è salita, l'abilità.
class _GatherPopup extends StatelessWidget {
  const _GatherPopup({required this.popup, required this.skill});
  final (String, int, int) popup;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final (id, n, level) = popup;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.92),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 28),
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
                    colors: [
                      Palette.gold.withValues(alpha: 0.35),
                      Palette.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: ItemIcon(id, size: 110),
              ),
              const SizedBox(height: 8),
              OneLine(
                '+$n ${itemName(id)}',
                align: Alignment.center,
                style: titleStyle(size: 22, color: Palette.holy),
              ),
              if (level > 0) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Palette.night,
                    border: Border.all(color: Palette.goldBright, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Palette.goldBright.withValues(alpha: 0.5), blurRadius: 20),
                    ],
                  ),
                  child: OneLine(
                    tr('{skill} · LIVELLO {n}', {'skill': skill.label.toUpperCase(), 'n': level}),
                    align: Alignment.center,
                    style: titleStyle(size: 18, color: Palette.goldBright),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
