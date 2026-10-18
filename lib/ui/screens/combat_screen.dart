import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/art.dart';
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
import '../widgets/exercise_demo.dart';
import '../widgets/exercise_view.dart';
import '../widgets/knight_view.dart';
import '../../core/sound.dart';

/// Combattimento: ogni rep valida è un attacco, il nemico colpisce a tempo.
///
/// Prima di iniziare ci sono 5 secondi per mettersi in posizione. In caccia
/// infinita ([endless]) ogni nemico abbattuto ne fa arrivare uno più forte,
/// finché non muori o fuggi.
class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.enemy,
    required this.exercise,
    this.stance = Stance.balanced,
    this.exerciseLabel,
    this.endless = false,
    this.respawn = false,
    this.move,
    this.lootMultiplier = 1,
  });

  /// L'esercizio come lo vede il giocatore: nome e difficoltà.
  final Move? move;

  /// Bottino doppio con la chiave della spedizione.
  final double lootMultiplier;

  final EnemyDef enemy;
  final ExerciseId exercise;
  final Stance stance;
  final String? exerciseLabel;
  final bool endless;

  /// Combattimento libero: il nemico rinasce uguale dopo ogni uccisione, si
  /// va avanti finché si vuole e il bottino si ritira alla fine.
  final bool respawn;

  bool get looping => endless || respawn;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

enum _Phase { countdown, fighting, ended }

class _CombatScreenState extends State<CombatScreen> {
  static const int prepareSeconds = 5;
  static const int nextWaveSeconds = 3;

  late CombatEngine _engine;
  late final BattleGame _game;
  late final RepInput _input;
  StreamSubscription<RepEvent>? _sub;
  Timer? _loop;
  Timer? _countdownTimer;
  final List<RepQuality> _reps = [];
  final _watch = Stopwatch();
  Duration _last = Duration.zero;

  _Phase _phase = _Phase.countdown;
  int _countdown = prepareSeconds;
  bool _youDied = false;

  int _wave = 0;
  int _kills = 0;
  int _totalReps = 0;
  int _totalXp = 0;
  int _totalRunes = 0;
  final Map<String, int> _totalMaterials = {};
  final List<String> _rareWeapons = [];

  /// Fatica più bassa toccata (1 = bottino pieno).
  double _minFatigue = 1;

  @override
  void initState() {
    super.initState();
    Sound.pushMusic(widget.enemy.isBoss ? Music.boss : Music.combat);
    final state = context.read<GameState>();
    _engine = _newEngine(state);
    final c = state.character;
    final drawn = !Art.has('assets/art/knight/attack/base.png') && HeroView.canShow(c);
    final hero = drawn ? HeroView.layersOf(c.look, c.worn, cape: c.capeId) : const <(String, int?, double)>[];
    _game = BattleGame(
      enemy: widget.enemy,
      weaponTier: state.character.weapon.glowTier,
      style: state.character.weapon.def.style,
      heroLayers: drawn
          ? [for (final l in hero) l.$1]
          : [
              if (Art.has('assets/art/knight/attack/base.png'))
                ...knightLayers(state.character, KnightPose.attack),
            ],
      heroTints: [
        for (final (_, tint, opacity) in hero)
          tint == null ? null : Color(tint).withValues(alpha: opacity),
      ],
      heroFist: drawn ? HeroView.rightFist(c.look.female) : null,
      // Il colore lo dà solo l'amuleto d'affinità incastonato.
      weaponTint: state.character.weapon.glowTier == 0
          ? null
          : state.character.weapon.aura!.color.withValues(
              alpha: [0.0, 0.35, 0.6, 0.7][state.character.weapon.glowTier],
            ),
    );
    // La fotocamera parte subito: i 5 secondi servono a mettersi in posizione.
    _input = createRepInput(state.useCamera, widget.exercise);
    _input.start();
    _sub = _input.reps.listen(_onRep);
    _startCountdown(prepareSeconds);
  }

  CombatEngine _newEngine(GameState state) => CombatEngine(
        enemy: widget.enemy,
        character: state.character,
        testReps:
            max(3, (state.testRepsFor(widget.exercise) / (widget.move?.difficulty ?? 1)).round()),
        stance: widget.stance,
        wave: _wave,
        difficulty: widget.move?.difficulty ?? 1,
        attackLevel: state.attackLevel,
        defenseLevel: state.defenseLevel,
      );

  void _startCountdown(int seconds) {
    _phase = _Phase.countdown;
    _countdown = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      Sound.play(_countdown <= 0 ? Sfx.countdownGo : Sfx.countdownTick);
      if (_countdown <= 0) {
        t.cancel();
        _beginFight();
      }
    });
  }

  void _beginFight() {
    setState(() => _phase = _Phase.fighting);
    _watch
      ..reset()
      ..start();
    _last = Duration.zero;
    _loop = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _onRep(RepEvent e) {
    // Le rep durante il conto alla rovescia non contano.
    if (_phase != _Phase.fighting || _engine.status != CombatStatus.fighting) return;
    _reps.add(e.quality);
    final hit = _engine.registerRep(e.quality);
    _game.heroStrike(damage: hit.damage, critical: hit.critical, bounced: hit.bounced);
    Sound.play(hit.bounced ? Sfx.heroBounce : hit.critical ? Sfx.heroCrit : Sfx.heroHit);
    setState(() {});
    _checkEnd();
  }

  void _tick() {
    final now = _watch.elapsed;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    final taken = _engine.tick(dt);
    if (taken > 0) {
      _game.enemyStrike(taken);
      Sound.play(Sfx.enemyHit);
    }
    if (mounted) setState(() {});
    _checkEnd();
  }

  /// Applica le ricompense di questo nemico e le somma al totale della caccia.
  int _collect(CombatRewards rewards, {required bool victory}) {
    final m = widget.lootMultiplier;
    if (victory && m != 1) {
      rewards = CombatRewards(
        xp: rewards.xp,
        runes: (rewards.runes * m).round(),
        materials: {for (final e in rewards.materials.entries) e.key: (e.value * m).round()},
        rareWeapon: rewards.rareWeapon,
      );
    }
    final (xp, granted, fatigue) = context.read<GameState>().applyCombatRewards(
          rewards,
          widget.exercise,
          List.of(_reps),
          victory: victory,
          stance: widget.stance,
        );
    if (victory && fatigue < 1) _minFatigue = fatigue < _minFatigue ? fatigue : _minFatigue;
    _totalReps += _reps.length;
    _totalXp += xp;
    _totalRunes += granted.runes;
    granted.materials.forEach((k, v) => _totalMaterials[k] = (_totalMaterials[k] ?? 0) + v);
    if (granted.rareWeapon != null) _rareWeapons.add(granted.rareWeapon!);
    _reps.clear();
    return xp;
  }

  Future<void> _checkEnd() async {
    if (_phase != _Phase.fighting || _engine.status == CombatStatus.fighting) return;
    _loop?.cancel();
    _watch.stop();
    final status = _engine.status;
    final rewards = _engine.rewards();

    if (status == CombatStatus.victory) {
      _game.enemyDefeated();
      Sound.play(Sfx.enemyDie);
      _collect(rewards, victory: true);
      if (widget.looping) {
        // Il prossimo nemico arriva subito: niente pause lunghe.
        _kills++;
        if (widget.endless) {
          _wave++;
          context.read<GameState>().recordHuntWave(_wave);
        }
        _engine = _newEngine(context.read<GameState>());
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        _game.respawnEnemy(_wave);
        setState(() => _startCountdown(nextWaveSeconds));
        return;
      }
    } else {
      _collect(rewards, victory: false);
    }

    setState(() => _phase = _Phase.ended);
    if (status == CombatStatus.defeated) {
      _game.heroDied();
      Sound.play(Sfx.youDied);
      setState(() => _youDied = true);
      await Future<void>.delayed(const Duration(milliseconds: 3800));
      if (!mounted) return;
      setState(() => _youDied = false);
    } else if (status == CombatStatus.fled) {
      _game.heroFled();
      Sound.play(Sfx.fled);
      await Future<void>.delayed(const Duration(milliseconds: 900));
    } else {
      Sound.play(Sfx.victory);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        status: status,
        endless: widget.looping,
        wavesCleared: _kills,
        reps: _totalReps,
        xp: _totalXp,
        runes: _totalRunes,
        materials: _totalMaterials,
        rareWeapons: _rareWeapons,
        fatigue: _minFatigue,
      ),
    );
    if (mounted) Navigator.of(context).pop(status == CombatStatus.victory);
  }

  Future<void> _flee() async {
    if (_phase == _Phase.ended) return;
    _countdownTimer?.cancel();
    if (_phase == _Phase.countdown) {
      // In caccia infinita tra un'ondata e l'altra: si esce col bottino.
      if (widget.looping && _kills > 0) {
        _phase = _Phase.fighting;
        _engine.status = CombatStatus.fled;
        await _checkEnd();
      } else if (mounted) {
        _phase = _Phase.ended;
        Navigator.of(context).pop(false);
      }
      return;
    }
    _engine.status = CombatStatus.fled;
    await _checkEnd();
  }

  @override
  void dispose() {
    Sound.popMusic();
    _loop?.cancel();
    _countdownTimer?.cancel();
    _sub?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    final label = widget.move?.name ?? widget.exerciseLabel ?? exercises[widget.exercise]!.name;
    final title = widget.endless
        ? tr('CACCIA · ONDATA {n}', {'n': _wave + 1})
        : widget.respawn
            ? '${widget.enemy.name.toUpperCase()} · $_kills'
            : widget.enemy.name.toUpperCase();
    return PopScope(
      canPop: _phase == _Phase.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _flee();
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: OathBar(title: Text(title)),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Column(
                    children: [
                      StatBar(
                        value: e.enemyHp / e.enemyMaxHp,
                        color: Palette.blood,
                        label: '${tr('{name} · livello {n}', {'name': widget.enemy.name, 'n': widget.enemy.level})}'
                            '${widget.enemy.isBoss ? ' · BOSS' : ''}'
                            '${_wave > 0 ? tr(' · +{p}% vita', {'p': (_wave * CombatEngine.waveHpStep * 100).round()}) : ''}',
                        height: 12,
                      ),
                      const SizedBox(height: 4),
                      StatBar(
                        value: _phase == _Phase.fighting ? e.attackTimerProgress : 0,
                        color: Palette.ember,
                        height: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget(game: _game),
                      if (_phase == _Phase.countdown)
                        _CountdownOverlay(
                          seconds: _countdown,
                          title: _kills == 0
                              ? tr('PREPARATI')
                              : widget.endless
                                  ? tr('ONDATA {n}', {'n': _wave + 1})
                                  : tr('RINASCE'),
                          subtitle: _kills == 0
                              ? tr('Mettiti in posizione davanti alla fotocamera')
                              : widget.endless
                                  ? tr('Arriva un nemico più forte')
                                  : tr('Si rialza: continua o ritirati col bottino'),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatBar(
                          value: e.heroHp / e.heroMaxHp,
                          color: Palette.moss,
                          label: tr('Vita {hp}/{max}', {'hp': e.heroHp.round(), 'max': e.heroMaxHp.round()}),
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
                    '${tr('{label} · {reps} rep su circa {max} · postura {stance}', {
                      'label': label,
                      'reps': e.reps,
                      'max': e.enemyMaxHp.round(),
                      'stance': e.stance.label,
                    })}'
                    '${e.penetration < 1 ? tr(' · i colpi rimbalzano: serve un\'arma migliore') : ''}',
                    style: const TextStyle(color: Palette.ash, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ExerciseView(
                    input: _input,
                    overlay: Positioned(
                      left: 10,
                      bottom: 10,
                      child: ExerciseDemo(move: demoFor(label, widget.exercise), size: 96),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _phase == _Phase.ended ? null : _flee,
                  icon: const Icon(Icons.directions_run, color: Palette.ash),
                  label: Text(
                    widget.looping && _kills > 0
                        ? tr('Ritirati col bottino')
                        : tr('Fuggi (tieni l\'esperienza delle rep fatte)'),
                    style: const TextStyle(color: Palette.ash),
                  ),
                ),
              ],
            ),
          ),
          if (_youDied) const Positioned.fill(child: YouDiedOverlay()),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.seconds, required this.title, required this.subtitle});
  final int seconds;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.night.withValues(alpha: 0.72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: titleStyle(size: 22, spacing: 6)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey(seconds),
            tween: Tween(begin: 1.6, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: Text(
              '${seconds.clamp(1, 99)}',
              style: titleStyle(size: 72, color: Palette.holy, spacing: 0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// La scritta rossa dei souls: fascia nera, lettere che emergono lente.
class YouDiedOverlay extends StatelessWidget {
  const YouDiedOverlay({super.key});

  static const Color deathRed = Color(0xFFA3201A);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2200),
      curve: Curves.easeInOut,
      builder: (context, t, _) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Colors.black.withValues(alpha: 0.35 * t)),
              Center(
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.85 * t),
                        Colors.black.withValues(alpha: 0.85 * t),
                        Colors.black.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.25, 0.75, 1],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * t,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'YOU DIED',
                          style: TextStyle(
                            fontFamily: kTitleFont,
                            fontSize: 52,
                            letterSpacing: 6,
                            color: deathRed,
                            shadows: [
                              Shadow(color: deathRed.withValues(alpha: 0.6), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.status,
    required this.endless,
    required this.wavesCleared,
    required this.reps,
    required this.xp,
    required this.runes,
    required this.materials,
    required this.rareWeapons,
    this.fatigue = 1,
  });

  final double fatigue;
  final CombatStatus status;
  final bool endless;
  final int wavesCleared;
  final int reps;
  final int xp;
  final int runes;
  final Map<String, int> materials;
  final List<String> rareWeapons;

  @override
  Widget build(BuildContext context) {
    final victory = status == CombatStatus.victory;
    final title = endless
        ? tr('CACCIA FINITA')
        : switch (status) {
            CombatStatus.victory => tr('NEMICO ABBATTUTO'),
            CombatStatus.defeated => tr('SEI CADUTO'),
            _ => tr('SEI FUGGITO'),
          };
    return AlertDialog(
      backgroundColor: Palette.stone,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: victory || (endless && wavesCleared > 0) ? Palette.goldBright : Palette.blood,
          letterSpacing: 3,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (endless) Text(tr('Nemici abbattuti: {n}', {'n': wavesCleared})),
          Text(tr('{reps} rep · +{xp} XP', {'reps': reps, 'xp': xp})),
          if (runes > 0) Text(tr('+{n} rune', {'n': runes})),
          for (final m in materials.entries) Text('+${m.value} ${materialNames[m.key] ?? m.key}'),
          for (final w in rareWeapons)
            Text(
              tr('ARMA RARA: {name}', {'name': weaponDefs[w]!.name}),
              style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold),
            ),
          if (fatigue < 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tr('Gruppo muscolare affaticato: bottino al {p}%. '
                    'Cambia gruppo per tornare al pieno, gli XP restano interi.',
                    {'p': (fatigue * 100).round()}),
                style: const TextStyle(color: Palette.ember),
              ),
            ),
          if (status == CombatStatus.defeated)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tr('Tieni il ritmo: se rallenti il nemico si rimette in forze. '
                    'Più Vigore e un\'arma potenziata ti fanno resistere di più.'),
                style: const TextStyle(color: Palette.ash),
              ),
            ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('CONTINUA'))),
      ],
    );
  }
}
