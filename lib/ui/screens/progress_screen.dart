import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/progress.dart';
import '../widgets/common.dart';

const Map<BodyRegion, Color> regionColors = {
  BodyRegion.upper: Palette.ember,
  BodyRegion.core: Palette.goldBright,
  BodyRegion.legs: Palette.frost,
};


/// Andamento della forza reale nella Home: indice per Parte alta, Core e
/// Gambe (100 = test iniziale), con giorno, settimana o mese.
class ProgressCard extends StatefulWidget {
  const ProgressCard({super.key, this.showDetails = true});
  final bool showDetails;

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  ProgressSpan _span = ProgressSpan.week;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final points = computeProgress(s.history, s.baselineEq, DateTime.now(), _span);
    final current = points.last;
    final previous = points.length > 1 ? points[points.length - 2] : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OathChoice<ProgressSpan>(
              options: [for (final sp in ProgressSpan.values) (sp, sp.label)],
              selected: _span,
              height: 36,
              onChanged: (v) => setState(() => _span = v),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 160, child: CustomPaint(painter: StrengthChartPainter(points))),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final r in BodyRegion.values)
                  Expanded(
                    child: _RegionStat(region: r, points: points),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rep in questo periodo: ${current.reps}'
              '${previous != null ? ' (prima ${previous.reps})' : ''}. '
              '100 è la tua forza al primo test: le versioni più dure contano di più.',
              style: const TextStyle(color: Palette.ash, fontSize: 13),
            ),
            if (widget.showDetails)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const ProgressScreen())),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('Ogni esercizio e i record'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RegionStat extends StatelessWidget {
  const _RegionStat({required this.region, required this.points});
  final BodyRegion region;
  final List<ProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = [for (final p in points) p.strength[region]].whereType<double>().toList();
    final color = regionColors[region]!;
    final last = values.isEmpty ? null : values.last;
    final delta = last == null ? null : last - 100;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(region.label, style: const TextStyle(color: Palette.ash, fontSize: 13)),
          ],
        ),
        Text(
          last == null ? '–' : '${last.round()}',
          style: titleStyle(size: 22).copyWith(color: color),
        ),
        Text(
          delta == null ? 'da allenare' : '${delta >= 0 ? '+' : ''}${delta.round()}% dall\'inizio',
          style: TextStyle(
            color: delta == null ? Palette.ash : (delta >= 0 ? Palette.moss : Palette.blood),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Tre linee, una per zona, con la riga tratteggiata del 100.
class StrengthChartPainter extends CustomPainter {
  StrengthChartPainter(this.points);
  final List<ProgressPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, bottom = 18.0;
    final w = size.width - left, h = size.height - bottom;
    var hi = 120.0, lo = 80.0;
    for (final p in points) {
      for (final v in p.strength.values) {
        if (v > hi) hi = v;
        if (v < lo) lo = v;
      }
    }
    hi = (hi / 10).ceil() * 10.0 + 5;
    lo = (lo / 10).floor() * 10.0 - 5;
    double y(double v) => h - (v - lo) / (hi - lo) * h;
    double x(int i) => left + (points.length == 1 ? w / 2 : i * w / (points.length - 1));

    final grid = Paint()
      ..color = Palette.iron
      ..strokeWidth = 1;
    final label = TextStyle(
      color: Palette.ash.withValues(alpha: 0.8),
      fontSize: 11,
      fontFamily: 'EBGaramond',
    );
    void text(String t, Offset at, {bool center = false}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(center ? tp.width / 2 : 0, tp.height / 2));
    }

    for (final v in [lo + 5, 100.0, hi - 5]) {
      final yy = y(v);
      if (v == 100) {
        for (var xx = left; xx < size.width; xx += 8) {
          canvas.drawLine(
            Offset(xx, yy),
            Offset(xx + 4, yy),
            Paint()
              ..color = Palette.gold
              ..strokeWidth = 1,
          );
        }
      } else {
        canvas.drawLine(Offset(left, yy), Offset(size.width, yy), grid);
      }
      text('${v.round()}', Offset(0, yy));
    }
    final step = (points.length / 6).ceil();
    for (var i = 0; i < points.length; i += step) {
      text(points[i].label, Offset(x(i), size.height - 6), center: true);
    }

    for (final region in BodyRegion.values) {
      final color = regionColors[region]!;
      final path = Path();
      var started = false;
      for (var i = 0; i < points.length; i++) {
        final v = points[i].strength[region];
        if (v == null) continue;
        final o = Offset(x(i), y(v));
        if (started) {
          path.lineTo(o.dx, o.dy);
        } else {
          path.moveTo(o.dx, o.dy);
          started = true;
        }
        canvas.drawCircle(o, 3, Paint()..color = color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(StrengthChartPainter old) => true;
}

/// Ogni esercizio: rep nel periodo, serie migliore di solito, ultima e record.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressSpan _span = ProgressSpan.week;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final now = DateTime.now();
    final from = switch (_span) {
      ProgressSpan.day => DateTime(now.year, now.month, now.day),
      ProgressSpan.week => DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1)),
      ProgressSpan.month => DateTime(now.year, now.month),
    };
    final list = exerciseSummaries(s.history, from);
    return Scaffold(
      appBar: OathBar(title: const Text('IL TUO ANDAMENTO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ProgressCard(showDetails: false),
          const SectionTitle('Esercizi'),
          OathChoice<ProgressSpan>(
            options: const [
              (ProgressSpan.day, 'Oggi'),
              (ProgressSpan.week, 'Settimana'),
              (ProgressSpan.month, 'Mese'),
            ],
            selected: _span,
            height: 36,
            onChanged: (v) => setState(() => _span = v),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Text(
              'Ancora nessuna serie registrata: allenati e qui vedrai tutto.',
              style: TextStyle(color: Palette.ash),
            ),
          for (final e in list) _ExerciseRow(e),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(this.e);
  final ExerciseSummary e;

  @override
  Widget build(BuildContext context) {
    final unit = e.trackAs == ExerciseId.plank ? ' s' : '';
    final vsUsual = e.usualBest == 0 ? null : e.lastBest - e.usualBest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(e.name, style: titleStyle(size: 16))),
                if (e.record > 0 && e.lastBest >= e.record && e.lastDay == e.recordDay)
                  const InfoChip(Icons.emoji_events, 'RECORD', color: Palette.goldBright),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Nel periodo: ${e.repsInPeriod}$unit in ${e.daysInPeriod} giorni · '
              'Record: ${e.record}$unit in una serie',
              style: const TextStyle(color: Palette.ash, fontSize: 13),
            ),
            Text(
              'Ultima volta: ${e.lastBest}$unit'
              '${vsUsual == null ? '' : ' · di solito ${e.usualBest.toStringAsFixed(0)}$unit '
                  '(${vsUsual >= 0 ? '+' : ''}${vsUsual.round()})'}',
              style: TextStyle(
                color:
                    vsUsual == null ? Palette.ash : (vsUsual >= 0 ? Palette.moss : Palette.blood),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
