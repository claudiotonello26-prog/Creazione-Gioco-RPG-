import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/art.dart';
import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/skills.dart';

/// Che cosa è salito: il livello del personaggio, un'abilità o un attributo.
enum CelebrationKind { level, skill, attribute }

class Celebration {
  const Celebration(this.kind, this.title, this.subtitle, {this.from, this.to});
  final CelebrationKind kind;
  final String title;
  final String subtitle;
  final int? from;
  final int? to;

  /// Illustrazione dell'emblema, se Antigravity l'ha già disegnata:
  /// `assets/art/celebrations/level_up.png`, `skill_up.png`, `stat_up.png`.
  String get art =>
      'assets/art/celebrations/${switch (kind) {
        CelebrationKind.level => 'level_up',
        CelebrationKind.skill => 'skill_up',
        CelebrationKind.attribute => 'stat_up',
      }}.png';

  Color get color => switch (kind) {
    CelebrationKind.level => Palette.goldBright,
    CelebrationKind.skill => Palette.frost,
    CelebrationKind.attribute => Palette.ember,
  };

  IconData get icon => switch (kind) {
    CelebrationKind.level => Icons.military_tech,
    CelebrationKind.skill => Icons.auto_awesome,
    CelebrationKind.attribute => Icons.trending_up,
  };
}

/// Guarda lo stato del gioco e, quando qualcosa sale (livello, abilità,
/// attributo), mostra al centro dello schermo un'iscrizione dorata che
/// appare, brilla e svanisce. Non blocca i tocchi: si gioca anche mentre c'è.
class CelebrationLayer extends StatefulWidget {
  const CelebrationLayer({super.key, required this.state, required this.child});
  final GameState state;
  final Widget child;

  @override
  State<CelebrationLayer> createState() => _CelebrationLayerState();
}

class _CelebrationLayerState extends State<CelebrationLayer> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2600);

  late final AnimationController _anim = AnimationController(vsync: this, duration: _duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });

  final List<Celebration> _queue = [];
  Celebration? _current;

  Character? _character;
  int _level = 0;
  Map<Attribute, int> _attrs = {};
  Map<Skill, int> _skills = {};

  @override
  void initState() {
    super.initState();
    _snapshot();
    widget.state.addListener(_changed);
  }

  @override
  void dispose() {
    widget.state.removeListener(_changed);
    _anim.dispose();
    super.dispose();
  }

  void _snapshot() {
    final s = widget.state;
    _character = s.character;
    _level = s.character.level;
    _attrs = Map.of(s.character.attributes);
    _skills = {for (final k in Skill.values) k: s.skillLevel(k)};
  }

  void _changed() {
    final s = widget.state;
    // Personaggio nuovo (caricamento, nuova partita): nessuna festa.
    if (!identical(s.character, _character) || !s.onboarded) return _snapshot();
    final found = <Celebration>[];
    final level = s.character.level;
    if (level > _level) {
      found.add(
        Celebration(
          CelebrationKind.level,
          tr('LIVELLO {n}', {'n': level}),
          level - _level == 1
              ? tr('+1 punto attributo da spendere')
              : tr('+{n} punti attributo da spendere', {'n': level - _level}),
          from: _level,
          to: level,
        ),
      );
    }
    for (final k in Skill.values) {
      final now = s.skillLevel(k);
      final before = _skills[k] ?? now;
      if (now > before) {
        found.add(
          Celebration(
            CelebrationKind.skill,
            k.label.toUpperCase(),
            tr('Guarda nella Guida cosa sblocca questo livello'),
            from: before,
            to: now,
          ),
        );
      }
    }
    for (final a in Attribute.values) {
      final now = s.character.attr(a);
      final before = _attrs[a] ?? now;
      if (now > before) {
        found.add(
          Celebration(
            CelebrationKind.attribute,
            a.label.toUpperCase(),
            a.description,
            from: before,
            to: now,
          ),
        );
      }
    }
    _snapshot();
    if (found.isEmpty) return;
    // Più attributi alzati di fila: resta solo l'ultimo per ciascuno.
    for (final c in found) {
      _queue.removeWhere((q) => q.kind == c.kind && q.title == c.title);
      _queue.add(c);
    }
    if (_current == null) _next();
  }

  void _next() {
    if (!mounted) return;
    if (_queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final c = _queue.removeAt(0);
    Sound.play(c.kind == CelebrationKind.level ? Sfx.levelUp : Sfx.skillUp);
    setState(() => _current = c);
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = _current;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (c != null)
          Positioned.fill(
            child: IgnorePointer(
              // Sopra al Navigator non c'è un Material: senza, il testo è sottolineato.
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => _CelebrationView(c, _anim.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Un fotogramma dell'animazione: [t] va da 0 a 1.
class _CelebrationView extends StatelessWidget {
  const _CelebrationView(this.c, this.t);
  final Celebration c;
  final double t;

  @override
  Widget build(BuildContext context) {
    // Entra in 0.18, resta, esce negli ultimi 0.2.
    final enter = Curves.easeOutBack.transform((t / 0.18).clamp(0.0, 1.0));
    final exit = Curves.easeIn.transform(((t - 0.8) / 0.2).clamp(0.0, 1.0));
    final opacity = (t / 0.12).clamp(0.0, 1.0) * (1 - exit);
    final scale = 0.6 + 0.4 * enter + 0.08 * exit;
    final emblem = 150.0;
    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [Colors.black.withValues(alpha: 0.88), Colors.black.withValues(alpha: 0.6)],
          ),
        ),
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: emblem * 1.8,
                  height: emblem * 1.8,
                  child: CustomPaint(
                    painter: _RaysPainter(color: c.color, turn: t),
                    child: Center(
                      child: Art.has(c.art)
                          ? Image.asset(c.art, width: emblem, height: emblem)
                          : _Emblem(c, size: emblem),
                    ),
                  ),
                ),
                // Una fascia scura dietro le scritte: si leggono sopra qualsiasi schermata.
                Container(
                  width: MediaQuery.sizeOf(context).width,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Palette.night.withValues(alpha: 0),
                        Palette.night.withValues(alpha: 0.95),
                        Palette.night.withValues(alpha: 0.95),
                        Palette.night.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.2, 0.8, 1],
                    ),
                    border: Border.symmetric(
                      horizontal: BorderSide(color: c.color.withValues(alpha: 0.6)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.kind == CelebrationKind.level
                            ? tr('SEI SALITO DI LIVELLO')
                            : tr('MIGLIORATO'),
                        style: titleStyle(
                          size: 14,
                          color: Palette.holy,
                          spacing: 3,
                        ).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 6)]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.title,
                        textAlign: TextAlign.center,
                        style: titleStyle(size: 34, color: c.color, spacing: 3).copyWith(
                          shadows: [
                            Shadow(color: c.color.withValues(alpha: 0.8), blurRadius: 18),
                            const Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      if (c.kind != CelebrationKind.level && c.from != null && c.to != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${c.from}',
                                style: titleStyle(size: 26, color: Palette.ash, spacing: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.arrow_forward, color: c.color, size: 26),
                              ),
                              Text(
                                '${c.to}',
                                style: titleStyle(size: 30, color: Palette.holy, spacing: 1),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          c.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Palette.holy,
                            fontSize: 17,
                            shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// L'emblema disegnato finché manca l'illustrazione: uno scudo a rombo con
/// bordo dorato e il simbolo al centro.
class _Emblem extends StatelessWidget {
  const _Emblem(this.c, {required this.size});
  final Celebration c;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size * 0.66,
        height: size * 0.66,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [c.color.withValues(alpha: 0.45), Palette.night]),
          border: Border.all(color: c.color, width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.7), blurRadius: 30)],
        ),
        child: Transform.rotate(
          angle: -math.pi / 4,
          child: c.kind == CelebrationKind.level && c.to != null
              ? Center(
                  child: Text(
                    '${c.to}',
                    style: titleStyle(size: size * 0.3, color: c.color),
                  ),
                )
              : Icon(c.icon, color: c.color, size: size * 0.34),
        ),
      ),
    );
  }
}

/// Raggi di luce che ruotano piano dietro l'emblema.
class _RaysPainter extends CustomPainter {
  const _RaysPainter({required this.color, required this.turn});
  final Color color;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final ray = Paint()..color = color.withValues(alpha: 0.18);
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = turn * math.pi * 0.6 + i * 2 * math.pi / n;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + r * math.cos(a - 0.09), c.dy + r * math.sin(a - 0.09))
        ..lineTo(c.dx + r * math.cos(a + 0.09), c.dy + r * math.sin(a + 0.09))
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.turn != turn || old.color != color;
}
