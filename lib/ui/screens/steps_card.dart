import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/walking.dart';
import '../../health/step_source.dart';
import '../widgets/common.dart';

/// Passi di oggi nella Home: quattro traguardi (2000, 4000, 6000, 10000),
/// ognuno con qualche runa. Sono a parte dalla quest: servono solo a far
/// camminare.
class StepsCard extends StatefulWidget {
  const StepsCard({super.key, required this.onOpenGathering, this.debugSteps});
  final VoidCallback onOpenGathering;

  /// Solo per le schermate di prova.
  final int? debugSteps;

  @override
  State<StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends State<StepsCard> with WidgetsBindingObserver {
  final _source = StepSource();
  int? _steps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _steps = widget.debugSteps;
    if (_steps == null) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && widget.debugSteps == null) _refresh();
  }

  Future<void> _refresh() async {
    try {
      if (await _source.access() != StepAccess.ready) return;
      final steps = await _source.stepsToday();
      if (mounted) setState(() => _steps = steps);
    } catch (_) {}
  }

  void _claim(GameState s) {
    final runes = s.claimStepMilestones(_steps ?? 0);
    if (runes == 0) return;
    Sound.play(Sfx.questDone);
    toast(context, tr('+{runes} rune per i passi di oggi.', {'runes': runes}));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final steps = _steps;
    final top = stepMilestones.last;
    final claimed = s.daily.stepMilestones;
    final pending = steps == null ? 0 : s.pendingStepMilestones(steps);
    return Card(
      child: InkWell(
        onTap: steps == null ? widget.onOpenGathering : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk, color: Palette.gold, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OneLine(tr('PASSI DI OGGI'), style: titleStyle(size: 13, spacing: 1.6)),
                  ),
                  Text(
                    steps == null ? tr('Collega i passi') : '${_fmt(steps)} / ${_fmt(top)}',
                    style: TextStyle(
                      color: steps == null ? Palette.ash : Palette.holy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MilestoneBar(steps: steps ?? 0, claimed: claimed),
              if (pending > 0) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => _claim(s),
                  child: OneLine(
                    tr('RISCATTA +{runes} RUNE', {'runes': _pendingRunes(claimed, pending)}),
                    align: Alignment.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _pendingRunes(int claimed, int pending) => [
        for (var i = claimed; i < claimed + pending; i++) stepMilestoneRunes(i),
      ].fold(0, (a, b) => a + b);
}

String _fmt(int n) => n >= 1000 ? '${n ~/ 1000}${appLang == Lang.it ? '.' : ','}${(n % 1000).toString().padLeft(3, '0')}' : '$n';

/// Barra fino a 10000 con le quattro tappe: oro se riscattata, accesa se
/// raggiunta, spenta se ancora da fare.
class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.steps, required this.claimed});
  final int steps;
  final int claimed;

  @override
  Widget build(BuildContext context) {
    final top = stepMilestones.last;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Palette.iron,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (steps / top).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Palette.gold, Palette.goldBright]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < stepMilestones.length; i++)
                Positioned(
                  left: (w * stepMilestones[i] / top - 26).clamp(0.0, w - 52),
                  top: 0,
                  width: 52,
                  child: _Mark(
                    label: '${stepMilestones[i] ~/ 1000}k',
                    runes: stepMilestoneRunes(i),
                    reached: steps >= stepMilestones[i],
                    claimed: i < claimed,
                    big: i == stepMilestones.length - 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.label,
    required this.runes,
    required this.reached,
    required this.claimed,
    required this.big,
  });
  final String label;
  final int runes;
  final bool reached;
  final bool claimed;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final color = claimed
        ? Palette.goldBright
        : reached
            ? Palette.ember
            : Palette.ash.withValues(alpha: 0.6);
    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Center(
            child: Container(
              width: big ? 32 : 26,
              height: big ? 32 : 26,
              decoration: BoxDecoration(
                color: claimed ? Palette.gold : Palette.stone,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: reached && !claimed
                    ? [BoxShadow(color: Palette.ember.withValues(alpha: 0.6), blurRadius: 10)]
                    : null,
              ),
              child: Icon(
                claimed ? Icons.check : Icons.diamond_outlined,
                size: big ? 16 : 13,
                color: claimed ? Palette.night : color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        OneLine(
          '$label · $runes',
          align: Alignment.center,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
