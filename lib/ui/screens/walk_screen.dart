import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/skills.dart';
import '../../domain/walking.dart';
import '../../health/step_source.dart';
import '../widgets/common.dart';
import '../widgets/trainer.dart';

/// La Camminata: i passi di oggi (Samsung Health, Google Fit, smartwatch,
/// tramite Health Connect o Salute) diventano minerale, legno e pietre.
class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

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
    maybeShowHint(context, 'walk');
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
      toast(context, 'Ancora qualche passo: servono ${r.stepsPerUnit} passi per ${r.name}.');
      return;
    }
    toast(
        context,
        '+$units ${r.name}'
        '${levels > 0 ? ' · ${r.skill.label} sale al livello ${s.skillLevel(r.skill)}!' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final steps = _steps ?? 0;
    final target = resourceById(s.gatherTarget);
    final fresh = (min(steps, dailyStepCap) - s.daily.claimedSteps).clamp(0, dailyStepCap);
    final ready = (fresh + s.stepBank) ~/ target.stepsPerUnit;
    return Scaffold(
      appBar: AppBar(title: const Text('CAMMINATA')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: _StepRing(
                steps: steps,
                goal: target.stepsPerUnit,
                progress: ((fresh + s.stepBank) % target.stepsPerUnit) / target.stepsPerUnit,
                known: _steps != null,
              ),
            ),
            const SizedBox(height: 12),
            Text('Stai raccogliendo: ${target.name}',
                textAlign: TextAlign.center, style: titleStyle(size: 15)),
            Text('${target.where} · ${target.stepsPerUnit} passi per unità',
                textAlign: TextAlign.center, style: const TextStyle(color: Palette.ash)),
            const SizedBox(height: 12),
            if (_access == null)
              const Center(child: CircularProgressIndicator())
            else if (_access != StepAccess.ready)
              _ConnectCard(access: _access!, busy: _busy, onConnect: _connect)
            else
              FilledButton.icon(
                onPressed: fresh + s.stepBank > 0 ? () => _claim(s) : null,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(ready > 0 ? 'RACCOGLI $ready × ${target.name.toUpperCase()}' : 'CAMMINA ANCORA'),
              ),
            for (final skill in [Skill.woodcutting, Skill.mining]) ...[
              SectionTitle(skill.label,
                  trailing: Text('Livello ${s.skillLevel(skill)}',
                      style: const TextStyle(color: Palette.goldBright))),
              Builder(builder: (_) {
                final (_, xpIn, xpNeed) = skillProgress(s.skillXp[skill] ?? 0);
                return StatBar(value: xpIn / xpNeed, color: Palette.gold, label: '$xpIn / $xpNeed XP');
              }),
              const SizedBox(height: 6),
              for (final r in resources.where((r) => r.skill == skill))
                _resourceTile(s, r),
            ],
            const SizedBox(height: 8),
            Text(
              'Scegli cosa raccogliere: i materiali migliori si sbloccano salendo di '
              'livello nel mestiere. Si conta da mezzanotte, fino a $dailyStepCap passi al giorno.',
              style: const TextStyle(color: Palette.ash, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resourceTile(GameState s, Resource r) {
    final unlocked = s.skillLevel(r.skill) >= r.level;
    final selected = s.gatherTarget == r.id;
    return ActionTile(
      icon: unlocked
          ? (selected ? Icons.radio_button_checked : Icons.radio_button_off)
          : Icons.lock_outline,
      color: selected ? Palette.goldBright : (unlocked ? Palette.gold : Palette.iron),
      title: r.name,
      subtitle: unlocked
          ? '${r.where} · ${r.stepsPerUnit} passi · hai ${s.character.materials[r.id] ?? 0}'
          : 'Si sblocca a ${r.skill.label} livello ${r.level}',
      enabled: unlocked,
      onTap: unlocked ? () => s.setGatherTarget(r.id) : null,
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
      StepAccess.unsupported => ('I passi si leggono solo sul telefono.', null),
      StepAccess.needsHealthConnect => (
          'Serve Health Connect di Google: raccoglie i passi di Samsung Health, '
              'Google Fit e smartwatch.',
          'INSTALLA HEALTH CONNECT'
        ),
      _ => (
          android
              ? 'Concedi a Iron Oath di leggere i passi. Su Samsung: apri Samsung Health › '
                  'Impostazioni › Health Connect e attiva la condivisione dei passi.'
              : 'Concedi a Iron Oath di leggere i passi da Salute.',
          'COLLEGA I PASSI'
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
  const _StepRing(
      {required this.steps, required this.goal, required this.progress, required this.known});
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
              const Text('passi oggi', style: TextStyle(color: Palette.ash)),
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
    canvas.drawArc(r, 0, 2 * pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..color = Palette.iron);
    canvas.drawArc(r, -pi / 2, 2 * pi * progress, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..color = Palette.goldBright);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
