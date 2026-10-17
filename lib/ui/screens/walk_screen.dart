import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/walking.dart';
import '../../health/step_source.dart';
import '../widgets/common.dart';

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
    final loot = s.claimSteps(steps);
    if (loot.isEmpty) {
      toast(context, 'Niente di nuovo: cammina ancora e torna qui.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Text('BOTTINO DEL CAMMINO', textAlign: TextAlign.center, style: titleStyle(size: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in loot.entries) Text('+${e.value} ${materialNames[e.key] ?? e.key}'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('CONTINUA')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final steps = _steps ?? 0;
    final claimed = s.daily.claimedSteps;
    final pending = stepLootDelta(claimed, steps);
    final next = nextMilestone(steps);
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
                goal: next?.steps ?? dailyStepCap,
                known: _steps != null,
              ),
            ),
            const SizedBox(height: 12),
            if (_access == null)
              const Center(child: CircularProgressIndicator())
            else if (_access != StepAccess.ready)
              _ConnectCard(access: _access!, busy: _busy, onConnect: _connect)
            else ...[
              Text(
                next == null
                    ? 'Tutti i traguardi di oggi raggiunti.'
                    : 'Prossimo traguardo: ${next.title} a ${next.steps} passi',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.ash),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: pending.isEmpty ? null : () => _claim(s),
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(pending.isEmpty
                    ? 'NIENTE DA RISCUOTERE'
                    : 'RISCUOTI ${pending.values.fold(0, (a, b) => a + b)} MATERIALI'),
              ),
            ],
            const SectionTitle('Cosa danno i passi'),
            const ActionTile(
              icon: Icons.landscape_outlined,
              title: 'Ogni 1000 passi',
              subtitle: '1 Minerale di ferro: con l\'essenza dei mostri fa Pietre di forgia',
            ),
            const ActionTile(
              icon: Icons.forest_outlined,
              title: 'Ogni 2500 passi',
              subtitle: '1 Legno di frassino cenere: archi e aste',
            ),
            for (final m in stepMilestones)
              ActionTile(
                icon: steps >= m.steps ? Icons.check_circle : Icons.flag_outlined,
                color: steps >= m.steps ? Palette.goldBright : Palette.ash,
                title: '${m.title} · ${m.steps} passi',
                subtitle: m.loot.entries
                    .map((e) => '${e.value}× ${materialNames[e.key]}')
                    .join(' + '),
              ),
            const SizedBox(height: 8),
            Text(
              'Si conta da mezzanotte, fino a $dailyStepCap passi al giorno. '
              'Già riscossi oggi: $claimed passi.',
              style: const TextStyle(color: Palette.ash, fontSize: 12),
            ),
          ],
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
  const _StepRing({required this.steps, required this.goal, required this.known});
  final int steps;
  final int goal;
  final bool known;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _RingPainter(min(1.0, steps / goal)),
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
