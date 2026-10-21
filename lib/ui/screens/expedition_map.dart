import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../../game/battle_game.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import 'train_tab.dart';
import 'rest_screen.dart';
import 'training_screen.dart';
import '../../core/sound.dart';

/// Posizione delle tappe sulla mappa, in frazioni dello spazio (dal basso
/// verso l'alto): le quattro tappe e il boss in cima.
const List<Offset> mapStops = [
  Offset(0.5, 0.84),
  Offset(0.68, 0.68),
  Offset(0.36, 0.53),
  Offset(0.64, 0.38),
  Offset(0.5, 0.18),
];

/// Colori dello sfondo finché Antigravity non ha dipinto la mappa.
const Map<MuscleGroup, (Color, Color)> _mapTints = {
  MuscleGroup.push: (Color(0xFF3A1A0E), Color(0xFF0E0806)),
  MuscleGroup.legs: (Color(0xFF1E2A14), Color(0xFF080A06)),
  MuscleGroup.core: (Color(0xFF3A2E12), Color(0xFF0C0A05)),
  MuscleGroup.cardio: (Color(0xFF14223A), Color(0xFF05080E)),
  MuscleGroup.stretching: (Color(0xFF2A1E36), Color(0xFF0A070E)),
  MuscleGroup.mobility: (Color(0xFF2A1E36), Color(0xFF0A070E)),
};

/// La mappa di una spedizione: un sentiero con quattro tappe e il boss in
/// cima, il Comandante Reynard che guarda a braccia conserte, il forziere alla fine.
/// Si azzera ogni giorno.
class ExpeditionMapScreen extends StatefulWidget {
  const ExpeditionMapScreen({super.key, required this.expedition});
  final Expedition expedition;

  @override
  State<ExpeditionMapScreen> createState() => _ExpeditionMapScreenState();
}

class _ExpeditionMapScreenState extends State<ExpeditionMapScreen> {
  bool _weighted = false;
  bool _useKey = false;
  bool _keyUsed = false;

  Expedition get _e => widget.expedition;
  bool get _stretching => _e.group == MuscleGroup.stretching;

  /// Secondi per posa nello Stretching: crescono con la spedizione.
  int get _holdSeconds => const [20, 30, 40, 60][(_e.steps.first.tier - 1).clamp(0, 3)];

  int get _multiplier => (_weighted ? 2 : 1) * (_useKey || _keyUsed ? 2 : 1);

  void _spendKey(GameState s) {
    if (_useKey && !_keyUsed && s.useExpeditionKey()) _keyUsed = true;
  }

  Future<void> _runStep(int i) async {
    final s = context.read<GameState>();
    final step = _e.steps[i];
    final enemy = step.monster;
    _spendKey(s);
    final won = _stretching
        ? await _hold(s, enemy, step.move)
        : await startFreeFight(context, enemy, lootMultiplier: _keyUsed ? 2 : 1);
    if (!mounted) return;
    if (won) {
      if (!_stretching) s.expeditionKill(enemy);
      s.completeExpeditionStep(_e.id, i);
      toast(context, i == 3 ? tr('Il boss ti aspetta in cima.') : tr('Tappa superata.'));
    }
  }

  /// Una posa dello Stretching tenuta abbastanza calma lo spirito.
  Future<bool> _hold(GameState s, EnemyDef enemy, Move move) async {
    final r = await Navigator.of(context).push<SetResult>(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          exercise: ExerciseId.stretch,
          title: move.name,
          subtitle: tr('{name} · tienila {s} secondi', {'name': enemy.name, 's': _holdSeconds}),
          timeLimit: Duration(seconds: _holdSeconds + 15),
        ),
      ),
    );
    if (!mounted) return false;
    if (r == null || r.held.inSeconds < _holdSeconds) {
      toast(context, tr('Lo spirito si agita ancora. Riprova la posa.'));
      return false;
    }
    final loot = s.holdVictory(enemy, seconds: r.held.inSeconds, lootMultiplier: _keyUsed ? 2 : 1);
    toast(
      context,
      tr('{name} si calma · {loot}', {
        'name': enemy.name,
        'loot': loot.materials.entries.map((e) => '+${e.value} ${itemName(e.key)}').join(', '),
      }),
    );
    return true;
  }

  /// Il boss: circuito dei quattro esercizi delle tappe, 30 secondi ciascuno.
  Future<void> _boss() async {
    final s = context.read<GameState>();
    _spendKey(s);
    // Prima gli esercizi in piedi, poi quelli a terra: il telefono si sposta una volta.
    final moves = byPhonePosition([for (final st in _e.steps) st.move], (m) => m.trackAs);
    for (var i = 0; i < moves.length; i++) {
      final m = moves[i];
      if (i > 0) {
        final go = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => RestScreen(
              name: m.name,
              exercise: m.trackAs,
              index: i + 1,
              total: moves.length,
              movePhone: onFloor(m.trackAs) != onFloor(moves[i - 1].trackAs),
            ),
          ),
        );
        if (!mounted) return;
        if (go != true) {
          toast(context, tr('{name} resta in piedi. Riprova quando vuoi.', {'name': _e.boss.name}));
          return;
        }
      }
      final r = await Navigator.of(context).push<SetResult>(
        MaterialPageRoute(
          builder: (_) => TrainingScreen(
            exercise: m.trackAs,
            title: m.name,
            subtitle: m.hold
                ? tr('{name} · esercizio {i}/{n} · tieni la posa 30 secondi',
                    {'name': _e.boss.name, 'i': i + 1, 'n': moves.length})
                : tr('{name} · esercizio {i}/{n} · a sfinimento 30 secondi',
                    {'name': _e.boss.name, 'i': i + 1, 'n': moves.length}),
            timeLimit: const Duration(seconds: 30),
          ),
        ),
      );
      if (!mounted) return;
      if (r == null) {
        toast(context, tr('{name} resta in piedi. Riprova quando vuoi.', {'name': _e.boss.name}));
        return;
      }
      if (r.reps.isNotEmpty) {
        s.addTraining(
          m.trackAs,
          r.reps,
          countsForQuest: false,
          name: m.nameIt,
          difficulty: s.usualDifficulty(m.trackAs) * m.difficulty,
          pathGroup: _e.group,
        );
      }
    }
    final loot = s.expeditionBossDown(_e, weighted: _weighted);
    if (!mounted) return;
    toast(
      context,
      tr('{name} è caduto! {loot}', {
        'name': _e.boss.name,
        'loot': loot.entries.map((e) => '+${e.value} ${itemName(e.key)}').join(', '),
      }),
    );
  }

  Future<void> _openChest() async {
    final s = context.read<GameState>();
    final items = s.openChest(_e, multiplier: _multiplier);
    if (items.isEmpty || !mounted) return;
    Sound.play(Sfx.chestOpen);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChestDialog(title: _e.chest.name, items: items),
    );
  }

  String _reynard(int progress, bool underLevel) {
    if (underLevel && progress == 0) {
      return tr('Livello {n}? Tu sei sotto. Coraggioso. O sciocco. Vediamo.', {'n': _e.level});
    }
    return switch (progress) {
      0 => tr('Prima tappa. Fammi vedere.'),
      1 => tr('Non male. La prossima morde di più.'),
      2 => tr('Da qui in su sono Veterani. Respira.'),
      3 => tr('Ultima tappa prima del boss. Niente scuse.'),
      GameState.mapBoss => tr('Eccolo. Quattro esercizi, trenta secondi l\'uno. Fino in fondo.'),
      GameState.mapChest => tr('Il forziere è tuo. Aprilo, che ho fretta.'),
      _ => tr('Mappa finita per oggi. Domani si ricomincia.'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final progress = s.expeditionProgress(_e.id);
    final under = s.character.level < _e.level;
    final (top, bottom) = _mapTints[_e.group]!;
    return Scaffold(
      appBar: OathBar(title: Text('${_e.roman} · ${_e.name.toUpperCase()}')),
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          // In alto restano le opzioni: le tappe stanno nello spazio sotto.
          final top0 = under ? 120.0 : 70.0;
          final pts = [for (final p in mapStops) Offset(p.dx * w, top0 + p.dy * (h - top0))];
          return Stack(
            children: [
              Positioned.fill(
                child: Art.has(_e.background)
                    ? Image.asset(_e.background, fit: BoxFit.cover)
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [top, bottom],
                          ),
                        ),
                        child: CustomPaint(painter: _MistPainter(seed: _e.id.hashCode)),
                      ),
              ),
              Positioned.fill(child: CustomPaint(painter: _TrailPainter(pts, progress))),
              for (var i = 0; i < 4; i++)
                _place(
                  pts[i],
                  120,
                  _StepNode(
                    index: i,
                    step: _e.steps[i],
                    state: i < progress
                        ? _NodeState.done
                        : (i == progress ? _NodeState.open : _NodeState.locked),
                    holdSeconds: _stretching ? _holdSeconds : null,
                    onTap: i == progress ? () => _runStep(i) : null,
                  ),
                ),
              _place(
                pts[4],
                150,
                _BossNode(
                  expedition: _e,
                  progress: progress,
                  onTap: switch (progress) {
                    GameState.mapBoss => _boss,
                    GameState.mapChest => _openChest,
                    _ => null,
                  },
                ),
              ),
              // Il Comandante Reynard in basso a sinistra, a braccia conserte.
              Positioned(
                left: 0,
                bottom: 0,
                child: TrainerFigure(pose: TrainerPose.crossed, height: h * 0.26),
              ),
              Positioned(
                left: 8,
                bottom: h * 0.26 + 4,
                width: min(210, w * 0.5),
                child: _Bubble(_reynard(progress, under)),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _MapOptions(
                  stretching: _stretching,
                  weighted: _weighted,
                  onWeighted:
                      progress >= GameState.mapChest ? null : (v) => setState(() => _weighted = v),
                  keys: s.expeditionKeys,
                  useKey: _useKey || _keyUsed,
                  onKey: _keyUsed || (s.expeditionKeys == 0 && !_useKey)
                      ? null
                      : (v) => setState(() => _useKey = v),
                  underLevel: under ? _e.level : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _place(Offset p, double width, Widget child) =>
      Positioned(left: p.dx - width / 2, top: p.dy - 34, width: width, child: child);
}

class _MapOptions extends StatelessWidget {
  const _MapOptions({
    required this.stretching,
    required this.weighted,
    required this.onWeighted,
    required this.keys,
    required this.useKey,
    required this.onKey,
    required this.underLevel,
  });
  final bool stretching;
  final bool weighted;
  final ValueChanged<bool>? onWeighted;
  final int keys;
  final bool useKey;
  final ValueChanged<bool>? onKey;
  final int? underLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OathToggle(
                label: stretching ? tr('Profondo ×2') : tr('Zavorrato ×2'),
                icon: Icons.fitness_center,
                selected: weighted,
                height: 38,
                onTap: onWeighted == null ? null : () => onWeighted!(!weighted),
              ),
            ),
            if (keys > 0 || useKey) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OathToggle(
                  label: useKey ? tr('Chiave ×2') : tr('Chiave ({n})', {'n': keys}),
                  icon: Icons.vpn_key,
                  selected: useKey,
                  height: 38,
                  onTap: onKey == null ? null : () => onKey!(!useKey),
                ),
              ),
            ],
          ],
        ),
        if (underLevel != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Palette.night.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Palette.blood),
            ),
            child: Text(
              tr('Livello consigliato {n}. Sei più debole: migliora armi e armature o rischi di cadere.', {'n': underLevel}),
              style: const TextStyle(color: Palette.blood, fontSize: 14),
            ),
          ),
      ],
    );
  }
}

enum _NodeState { done, open, locked }

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.step,
    required this.state,
    required this.holdSeconds,
    required this.onTap,
  });
  final int index;
  final ExpeditionStep step;
  final _NodeState state;
  final int? holdSeconds;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final monster = step.monster;
    final open = state == _NodeState.open;
    final ring = switch (state) {
      _NodeState.done => Palette.goldBright,
      _NodeState.open => step.veteran ? Palette.blood : Palette.gold,
      _NodeState.locked => Palette.iron,
    };
    final size = step.veteran ? 74.0 : 68.0;
    final art = enemyArtPath(monster);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state == _NodeState.done ? Palette.gold : Palette.stone,
              // Fondo neutro: i mostri scuri si vedono anche sulla mappa.
              gradient: state != _NodeState.done && Art.has(art) ? neutralBackdrop : null,
              border: Border.all(
                color: step.veteran && state != _NodeState.done ? const Color(0xFF7A1010) : ring,
                width: open ? 3 : 2,
              ),
              boxShadow:
                  open ? [BoxShadow(color: ring.withValues(alpha: 0.6), blurRadius: 18)] : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: switch (state) {
              _NodeState.done => const Icon(Icons.check, color: Palette.night, size: 30),
              _ when Art.has(art) => Opacity(
                  opacity: state == _NodeState.locked ? 0.4 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(art, fit: BoxFit.contain),
                  ),
                ),
              _NodeState.locked => const Icon(Icons.lock_outline, color: Palette.iron),
              _NodeState.open => Center(
                  child: Text('${index + 1}', style: titleStyle(size: 24, color: Palette.holy)),
                ),
            },
          ),
          const SizedBox(height: 3),
          _Label(
            title: step.veteran
                ? tr('{name} · Veterano', {'name': enemyDefs[step.monsterId]!.name})
                : monster.name,
            subtitle:
                '${step.move.name}${holdSeconds != null ? ' · $holdSeconds s' : ''} · LV ${step.level}',
            dim: state == _NodeState.locked,
            bold: open,
            red: step.veteran,
          ),
        ],
      ),
    );
  }
}

class _BossNode extends StatelessWidget {
  const _BossNode({required this.expedition, required this.progress, required this.onTap});
  final Expedition expedition;
  final int progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final boss = expedition.boss;
    final chest = progress >= GameState.mapChest;
    final open = progress == GameState.mapBoss || progress == GameState.mapChest;
    final art = chest ? 'assets/art/chests/${expedition.chest.art}.png' : enemyArtPath(boss);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progress == GameState.mapDone ? Palette.gold : Palette.stone,
              gradient: progress != GameState.mapDone && Art.has(art) ? neutralBackdrop : null,
              border: Border.all(
                color: open ? (chest ? Palette.goldBright : Palette.blood) : Palette.iron,
                width: open ? 3 : 2,
              ),
              boxShadow: open
                  ? [
                      BoxShadow(
                        color: (chest ? Palette.goldBright : Palette.blood).withValues(alpha: 0.6),
                        blurRadius: 22,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: progress == GameState.mapDone
                ? const Icon(Icons.check, color: Palette.night, size: 36)
                : Art.has(art)
                    ? Opacity(
                        opacity: open ? 1 : 0.45,
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(art, fit: BoxFit.contain),
                        ),
                      )
                    : Icon(
                        chest ? Icons.inventory_2 : Icons.castle,
                        size: 38,
                        color: open ? Palette.goldBright : Palette.iron,
                      ),
          ),
          const SizedBox(height: 3),
          _Label(
            title: chest ? expedition.chest.name : boss.name,
            subtitle: chest
                ? (progress == GameState.mapDone ? tr('Aperto') : tr('Tocca per aprire'))
                : tr('Boss · circuito 4×30 s'),
            dim: !open && !chest,
            bold: open,
            red: !chest,
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.title,
    required this.subtitle,
    required this.dim,
    required this.bold,
    this.red = false,
  });
  final String title;
  final String subtitle;
  final bool dim;
  final bool bold;
  final bool red;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: dim ? Palette.ash : (red ? const Color(0xFFE88A7A) : Palette.holy),
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              height: 1.1,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: Palette.ash, fontSize: 14, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// La nuvoletta del Comandante Reynard.
class _Bubble extends StatelessWidget {
  const _Bubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Palette.holy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Palette.night, fontSize: 15, fontStyle: FontStyle.italic),
      ),
    );
  }
}

/// Il sentiero tra le tappe: oro dove sei già passato.
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points, this.progress);
  final List<Offset> points;
  final int progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final mid = Offset((a.dx + b.dx) / 2 + (i.isEven ? 40 : -40), (a.dy + b.dy) / 2);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final lit = i < progress;
      canvas.drawPath(
        path,
        Paint()
          ..color = (lit ? Palette.goldBright : Colors.black).withValues(alpha: lit ? 0.25 : 0.35)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      final paint = Paint()
        ..color = lit ? Palette.goldBright : Palette.ash.withValues(alpha: 0.6)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 16) {
          canvas.drawPath(m.extractPath(d, min(d + 8, m.length)), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.progress != progress || old.points != points;
}

/// Nebbia e rocce appena accennate, finché non arriva lo sfondo dipinto.
class _MistPainter extends CustomPainter {
  _MistPainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    for (var i = 0; i < 14; i++) {
      final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      canvas.drawCircle(
        c,
        40 + r.nextDouble() * 90,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.025 + r.nextDouble() * 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
    final ground = Paint()..color = Colors.black.withValues(alpha: 0.35);
    for (var i = 0; i < 6; i++) {
      final x = r.nextDouble() * size.width;
      final y = size.height * (0.25 + r.nextDouble() * 0.7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 60 + r.nextDouble() * 80, height: 18),
        ground,
      );
    }
  }

  @override
  bool shouldRepaint(_MistPainter old) => false;
}

/// Il forziere che si apre: gli oggetti escono uno alla volta, il raro con un
/// lampo d'oro.
class ChestDialog extends StatefulWidget {
  const ChestDialog({super.key, required this.title, required this.items});
  final String title;
  final List<(String, int, bool)> items;

  @override
  State<ChestDialog> createState() => _ChestDialogState();
}

class _ChestDialogState extends State<ChestDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 450 * widget.items.length),
  )
    ..addListener(() => setState(() {}))
    ..forward();

  int get _shown => (_reveal.value * widget.items.length).ceil();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.stone,
      title: Column(
        children: [
          const Icon(Icons.inventory_2, color: Palette.goldBright, size: 44),
          const SizedBox(height: 6),
          OneLine(
            widget.title.toUpperCase(),
            align: Alignment.center,
            style: titleStyle(size: 17),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, n, rare) in widget.items.take(_shown))
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: rare ? Palette.goldBright.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: rare ? Border.all(color: Palette.goldBright) : null,
                boxShadow: rare
                    ? [BoxShadow(color: Palette.goldBright.withValues(alpha: 0.5), blurRadius: 14)]
                    : null,
              ),
              child: Text(
                id == 'runes' ? tr('+{n} rune', {'n': n}) : '${rare ? tr('RARO · ') : '+$n '}${itemName(id)}',
                style: TextStyle(
                  color: rare ? Palette.goldBright : Palette.holy,
                  fontWeight: rare ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _shown >= widget.items.length ? () => Navigator.pop(context) : null,
          child: Text(tr('PRENDI TUTTO')),
        ),
      ],
    );
  }
}
