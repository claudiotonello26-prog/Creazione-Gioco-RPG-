import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../../game/battle_game.dart';
import '../../pose/rep_counter.dart';
import '../../pose/rep_input.dart';
import '../widgets/common.dart';
import '../widgets/exercise_view.dart';

/// Combattimento: ogni rep valida è un attacco, il nemico colpisce a tempo.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.enemy,
    required this.exercise,
    this.stance = Stance.balanced,
    this.exerciseLabel,
  });

  final EnemyDef enemy;
  final ExerciseId exercise;
  final Stance stance;
  final String? exerciseLabel;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  late final CombatEngine _engine;
  late final BattleGame _game;
  late final RepInput _input;
  StreamSubscription<RepEvent>? _sub;
  Timer? _loop;
  final List<RepQuality> _reps = [];
  final _watch = Stopwatch();
  Duration _last = Duration.zero;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<GameState>();
    _engine = CombatEngine(
      enemy: widget.enemy,
      character: state.character,
      testReps: state.testRepsFor(widget.exercise),
      stance: widget.stance,
    );
    _game = BattleGame(
      enemy: widget.enemy,
      weaponTier: state.character.weapon.visualTier,
      style: state.character.weapon.def.style,
    );
    _input = createRepInput(state.useCamera, widget.exercise);
    _input.start();
    _sub = _input.reps.listen(_onRep);
    _watch.start();
    _loop = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _onRep(RepEvent e) {
    if (_engine.status != CombatStatus.fighting) return;
    _reps.add(e.quality);
    final hit = _engine.registerRep(e.quality);
    _game.heroStrike(damage: hit.damage, critical: hit.critical, bounced: hit.bounced);
    setState(() {});
    _checkEnd();
  }

  void _tick() {
    final now = _watch.elapsed;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    final taken = _engine.tick(dt);
    if (taken > 0) _game.enemyStrike(taken);
    if (mounted) setState(() {});
    _checkEnd();
  }

  Future<void> _checkEnd() async {
    if (_ended || _engine.status == CombatStatus.fighting) return;
    _ended = true;
    _loop?.cancel();
    final victory = _engine.status == CombatStatus.victory;
    if (victory) {
      _game.enemyDefeated();
    } else {
      _game.heroFled();
    }
    final rewards = _engine.rewards();
    final state = context.read<GameState>();
    final xp = state.applyCombatRewards(rewards, widget.exercise, _reps, victory: victory);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _ResultDialog(victory: victory, rewards: rewards, reps: _reps.length, xp: xp),
    );
    if (mounted) Navigator.of(context).pop(victory);
  }

  Future<void> _flee() async {
    if (_ended) return;
    _engine.status = CombatStatus.fled;
    await _checkEnd();
  }

  @override
  void dispose() {
    _loop?.cancel();
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    final label = widget.exerciseLabel ?? exercises[widget.exercise]!.name;
    return PopScope(
      canPop: _ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _flee();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.enemy.name.toUpperCase())),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Column(
                children: [
                  StatBar(
                    value: e.enemyHp / e.enemyMaxHp,
                    color: Palette.blood,
                    label: '${widget.enemy.name} · gradino ${widget.enemy.tier}'
                        '${widget.enemy.isBoss ? ' · BOSS' : ''}',
                    height: 12,
                  ),
                  const SizedBox(height: 4),
                  StatBar(
                    value: e.attackTimerProgress,
                    color: Palette.ember,
                    height: 4,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: GameWidget(game: _game),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: StatBar(
                      value: e.heroHp / e.heroMaxHp,
                      color: Palette.moss,
                      label: 'Vita ${e.heroHp.round()}/${e.heroMaxHp.round()}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatBar(
                      value: e.rampage,
                      color: Palette.goldBright,
                      label: 'Rampage +${(e.rampage * 20).round()}%',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$label · rep ${e.reps} (previste ~${e.expectedReps}) · '
                'postura ${e.stance.label}'
                '${e.penetration < 1 ? ' · i colpi rimbalzano: build troppo debole' : ''}',
                style: const TextStyle(color: Palette.ash, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(flex: 4, child: ExerciseView(input: _input)),
            SafeArea(
              top: false,
              child: TextButton.icon(
                onPressed: _ended ? null : _flee,
                icon: const Icon(Icons.directions_run, color: Palette.ash),
                label: const Text('Fuggi (tieni gli XP delle rep fatte)',
                    style: TextStyle(color: Palette.ash)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog(
      {required this.victory, required this.rewards, required this.reps, required this.xp});
  final bool victory;
  final int xp;
  final CombatRewards rewards;
  final int reps;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.stone,
      title: Text(victory ? 'NEMICO ABBATTUTO' : 'SEI FUGGITO',
          textAlign: TextAlign.center,
          style: TextStyle(color: victory ? Palette.goldBright : Palette.blood, letterSpacing: 3)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$reps rep · +$xp XP'),
          if (victory) Text('+${rewards.runes} rune'),
          for (final m in rewards.materials.entries)
            Text('+${m.value} ${materialNames[m.key] ?? m.key}'),
          if (rewards.rareWeapon != null)
            Text('ARMA RARA: ${weaponDefs[rewards.rareWeapon]!.name}',
                style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold)),
          if (!victory)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Puoi riprovare quando vuoi. Una build migliore ti fa resistere di più.',
                  style: TextStyle(color: Palette.ash)),
            ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CONTINUA')),
      ],
    );
  }
}
