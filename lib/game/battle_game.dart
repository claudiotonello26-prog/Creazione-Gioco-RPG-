import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight;

import '../core/art.dart';
import '../core/theme.dart';
import '../domain/enemies.dart';
import '../domain/items.dart';

/// Scena del combattimento disegnata con Flame. Le figure sono silhouette
/// vettoriali provvisorie, da sostituire con le illustrazioni 2D e le
/// animazioni Spine dell'art bible.
class BattleGame extends FlameGame {
  BattleGame({
    required this.enemy,
    required this.weaponTier,
    required this.style,
    this.heroLayers = const [],
    this.heroTints = const [],
    this.heroFist,
    this.weaponTint,
  });

  final EnemyDef enemy;

  /// Strati del cavaliere in guardia (vuoto = figura vettoriale).
  final List<String> heroLayers;

  /// Tinta di ogni strato (personaggio a livelli: capelli, occhi, vestiti).
  final List<Color?> heroTints;

  /// Pugno sulla tela del personaggio a livelli (0..1): lì va la spada.
  final Offset? heroFist;

  /// Colore della build che tinge l'arma dal +3 in su.
  final Color? weaponTint;

  /// 0..3: aspetto dell'arma (+3, +6, +10).
  final int weaponTier;
  final WeaponStyle style;

  late final _Hero _hero;
  late final _Enemy _enemy;

  @override
  Color backgroundColor() => Palette.night;

  @override
  Future<void> onLoad() async {
    images.prefix = '';
    add(_Backdrop()..size = size);
    final heroSprites = [
      for (final p in heroLayers) await Sprite.load(p, images: images),
    ];
    final enemyArt = enemyArtPath(enemy);
    final enemySprite =
        Art.has(enemyArt) ? await Sprite.load(enemyArt, images: images) : null;
    _hero = _Hero(
      weaponTier: weaponTier,
      layers: heroSprites,
      weaponLayer: heroLayers.indexWhere((p) => p.contains('/weapon_')),
      weaponTint: weaponTint,
      tints: heroTints,
      fist: heroFist,
    )
      ..anchor = Anchor.bottomCenter
      ..size = heroSprites.isEmpty
          ? Vector2(90, 150)
          : (heroFist != null ? Vector2(120, 250) : Vector2(176, 220))
      ..position = Vector2(size.x * 0.25, size.y * 0.86);
    final scale = enemy.isBoss ? 1.7 : (1.0 + enemy.tier * 0.1);
    _enemy = _Enemy(enemy, sprite: enemySprite)
      ..anchor = Anchor.bottomCenter
      ..size = enemySprite == null
          ? Vector2(110 * scale, 150 * scale)
          : Vector2(170 * scale, 170 * scale)
      ..position = Vector2(size.x * 0.72, size.y * 0.86);
    addAll([_hero, _enemy]);
  }

  /// Una rep valida: l'eroe colpisce.
  void heroStrike({required double damage, required bool critical, required bool bounced}) {
    if (!isLoaded) return;
    _hero.add(SequenceEffect([
      MoveByEffect(Vector2(30, -6), EffectController(duration: 0.08)),
      MoveByEffect(Vector2(-30, 6), EffectController(duration: 0.12)),
    ]));
    if (style == WeaponStyle.melee) {
      _enemy.add(SequenceEffect([
        MoveByEffect(Vector2(10, 0), EffectController(duration: 0.05)),
        MoveByEffect(Vector2(-10, 0), EffectController(duration: 0.08)),
      ]));
    } else {
      add(_Projectile(
        from: _hero.position + Vector2(30, -90),
        to: _enemy.position + Vector2(0, -_enemy.size.y * 0.55),
        color: style == WeaponStyle.magic ? Palette.frost : Palette.ash,
      ));
    }
    _enemy.flash(critical ? Palette.goldBright : Palette.holy);
    final text = bounced
        ? 'RIMBALZA'
        : (critical ? 'CRITICO ${(damage * 100).round()}' : '${(damage * 100).round()}');
    _floating(
      text,
      _enemy.position + Vector2(Random().nextDouble() * 40 - 20, -_enemy.size.y - 10),
      critical ? Palette.goldBright : (bounced ? Palette.ash : Palette.holy),
      critical ? 26 : 20,
    );
  }

  /// Il nemico attacca a tempo.
  void enemyStrike(double damage) {
    if (!isLoaded) return;
    _enemy.add(SequenceEffect([
      MoveByEffect(Vector2(-40, 0), EffectController(duration: 0.1)),
      MoveByEffect(Vector2(40, 0), EffectController(duration: 0.2)),
    ]));
    _hero.flash(Palette.blood);
    _floating('-${damage.round()}', _hero.position + Vector2(0, -170), Palette.blood, 22);
  }

  void enemyDefeated() {
    if (!isLoaded) return;
    _enemy.add(OpacityEffect.to(0, EffectController(duration: 1.2)));
    _floating('NEMICO ABBATTUTO', Vector2(size.x / 2, size.y * 0.3), Palette.goldBright, 26);
  }

  /// Caccia infinita: un nuovo nemico emerge dalle rovine.
  void respawnEnemy(int wave) {
    if (!isLoaded) return;
    _enemy
      ..opacity = 0
      ..position = Vector2(size.x * 1.1, size.y * 0.86);
    _enemy.add(OpacityEffect.to(1, EffectController(duration: 0.6)));
    _enemy.add(MoveToEffect(Vector2(size.x * 0.72, size.y * 0.86), EffectController(duration: 0.6)));
    _floating('ONDATA ${wave + 1}', Vector2(size.x / 2, size.y * 0.3), Palette.ember, 26);
  }

  void heroDied() {
    if (!isLoaded) return;
    _hero.add(RotateEffect.to(-pi / 2, EffectController(duration: 0.7)));
    _hero.add(OpacityEffect.to(0.35, EffectController(duration: 1.2)));
  }

  void heroFled() {
    if (!isLoaded) return;
    _hero.add(MoveByEffect(Vector2(-200, 0), EffectController(duration: 0.8)));
  }

  void _floating(String text, Vector2 at, Color color, double fontSize) {
    final t = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: at,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cinzel',
        ),
      ),
    );
    t.add(MoveByEffect(Vector2(0, -50), EffectController(duration: 0.9)));
    t.add(RemoveEffect(delay: 0.9));
    add(t);
  }
}

class _Backdrop extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, size.y),
          [const Color(0xFF1C1712), Palette.night],
        ),
    );
    // Rovine della cattedrale sullo sfondo.
    final ruin = Paint()..color = const Color(0xFF221C16);
    final w = size.x;
    final h = size.y;
    for (var i = 0; i < 5; i++) {
      final x = w * (0.08 + i * 0.21);
      final ph = h * (0.25 + (i % 3) * 0.08);
      canvas.drawRect(Rect.fromLTWH(x, h * 0.86 - ph, w * 0.05, ph), ruin);
      canvas.drawPath(
        Path()
          ..moveTo(x - w * 0.01, h * 0.86 - ph)
          ..lineTo(x + w * 0.025, h * 0.86 - ph - w * 0.05)
          ..lineTo(x + w * 0.06, h * 0.86 - ph)
          ..close(),
        ruin,
      );
    }
    // Luna/sole dorato decadente.
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.18),
      w * 0.09,
      Paint()
        ..color = Palette.gold.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
      Paint()..color = const Color(0xFF14100C),
    );
  }
}

/// Lampo quando si viene colpiti e trasparenza per comparire e svanire
/// (le figure usano Paint propri, quindi la trasparenza va su un layer).
mixin _Flash on PositionComponent implements OpacityProvider {
  Color? _flashColor;
  double _flashTime = 0;

  @override
  double opacity = 1;

  @override
  void renderTree(Canvas canvas) {
    if (opacity >= 1) return super.renderTree(canvas);
    if (opacity <= 0) return;
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    super.renderTree(canvas);
    canvas.restore();
  }

  void flash(Color c) {
    _flashColor = c;
    _flashTime = 0.15;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTime > 0) _flashTime -= dt;
  }

  Color flashTint(Color base) =>
      _flashTime > 0 && _flashColor != null ? _flashColor! : base;

  /// Disegna le illustrazioni: durante il lampo diventano del colore del
  /// colpo, come le figure vettoriali.
  void renderSprites(
    Canvas canvas,
    List<Sprite> sprites, {
    int tinted = -1,
    Color? tint,
    List<Color?> tints = const [],
  }) {
    final flashing = _flashTime > 0 && _flashColor != null;
    for (var i = 0; i < sprites.length; i++) {
      final sp = sprites[i];
      // Adatta mantenendo le proporzioni, appoggiato in basso.
      final k = min(size.x / sp.srcSize.x, size.y / sp.srcSize.y);
      final d = sp.srcSize * k;
      final at = Vector2((size.x - d.x) / 2, size.y - d.y);
      final color = flashing ? _flashColor! : (i == tinted ? tint : null);
      final modulate = flashing || i >= tints.length ? null : tints[i];
      sp.render(
        canvas,
        position: at,
        size: d,
        overridePaint: color != null
            ? (Paint()..colorFilter = ColorFilter.mode(color, BlendMode.srcATop))
            : modulate != null
                ? (Paint()
                  ..colorFilter = ColorFilter.mode(modulate, BlendMode.modulate)
                  ..color = Color.fromRGBO(0, 0, 0, modulate.a))
                : null,
      );
    }
  }
}

/// Dove sta l'illustrazione di un nemico.
String enemyArtPath(EnemyDef e) =>
    'assets/art/${e.isAnimal ? 'animals' : e.isBoss ? 'bosses' : 'enemies'}/${e.id}_idle.png';

class _Hero extends PositionComponent with _Flash {
  _Hero({
    required this.weaponTier,
    this.layers = const [],
    this.weaponLayer = -1,
    this.weaponTint,
    this.tints = const [],
    this.fist,
  });
  final int weaponTier;
  final List<Sprite> layers;
  final int weaponLayer;
  final Color? weaponTint;
  final List<Color?> tints;
  final Offset? fist;

  @override
  void render(Canvas canvas) {
    if (layers.isNotEmpty) {
      renderSprites(canvas, layers, tinted: weaponLayer, tint: weaponTint, tints: tints);
      if (fist case final f?) {
        // Personaggio a livelli in posa rilassata: la spada esce dal pugno,
        // puntata verso il nemico, finché non c'è la posa d'attacco.
        final sp = layers.first;
        final k = min(size.x / sp.srcSize.x, size.y / sp.srcSize.y);
        final d = sp.srcSize * k;
        final at = Offset((size.x - d.x) / 2 + f.dx * d.x, size.y - d.y + f.dy * d.y);
        _blade(canvas, at, d.y * 0.42);
      }
      return;
    }
    final w = size.x, h = size.y;
    final body = Paint()..color = flashTint(const Color(0xFF4A423A));
    final dark = Paint()..color = flashTint(const Color(0xFF2B2520));
    // Mantello.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, h * 0.28)
        ..lineTo(w * 0.1, h)
        ..lineTo(w * 0.7, h)
        ..lineTo(w * 0.6, h * 0.28)
        ..close(),
      dark,
    );
    // Gambe, busto, elmo.
    canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.62, w * 0.12, h * 0.38), body);
    canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.62, w * 0.12, h * 0.38), body);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.26, h * 0.26, w * 0.42, h * 0.4), const Radius.circular(6)),
        body);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.34, h * 0.06, w * 0.26, h * 0.2), const Radius.circular(8)),
        body);
    // Fessura dell'elmo che brilla.
    canvas.drawRect(Rect.fromLTWH(w * 0.4, h * 0.14, w * 0.18, h * 0.025),
        Paint()..color = Palette.ember);
    // Spada: più lunga e luminosa ai gradini +3/+6/+10.
    final bladeColor = [Palette.ash, Palette.holy, Palette.goldBright, Palette.goldBright][weaponTier];
    final len = h * (0.55 + weaponTier * 0.07);
    if (weaponTier >= 2) {
      canvas.drawLine(
        Offset(w * 0.78, h * 0.5),
        Offset(w * 0.78 + len * 0.5, h * 0.5 - len * 0.85),
        Paint()
          ..color = Palette.gold.withValues(alpha: 0.5)
          ..strokeWidth = 12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawLine(
      Offset(w * 0.78, h * 0.5),
      Offset(w * 0.78 + len * 0.5, h * 0.5 - len * 0.85),
      Paint()
        ..color = bladeColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(w * 0.68, h * 0.53), Offset(w * 0.9, h * 0.45),
        Paint()
          ..color = Palette.gold
          ..strokeWidth = 4);
  }

  void _blade(Canvas canvas, Offset grip, double len) {
    final bladeColor = [Palette.ash, Palette.holy, Palette.goldBright, Palette.goldBright][weaponTier];
    final tip = grip + Offset(len * 0.55, -len * 0.83);
    if (weaponTier >= 2) {
      canvas.drawLine(
        grip,
        tip,
        Paint()
          ..color = Palette.gold.withValues(alpha: 0.5)
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }
    canvas.drawLine(
      grip,
      tip,
      Paint()
        ..color = weaponTint ?? bladeColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final guard = Offset(len * 0.1, len * 0.07);
    canvas.drawLine(
      grip + Offset(len * 0.04, -len * 0.06) - guard,
      grip + Offset(len * 0.04, -len * 0.06) + guard,
      Paint()
        ..color = Palette.gold
        ..strokeWidth = 3.5,
    );
  }
}

class _Enemy extends PositionComponent with _Flash {
  _Enemy(this.def, {this.sprite});
  final EnemyDef def;
  final Sprite? sprite;

  @override
  void render(Canvas canvas) {
    // Le illustrazioni dei nemici guardano già a sinistra, verso l'eroe.
    if (sprite != null) return renderSprites(canvas, [sprite!]);
    final w = size.x, h = size.y;
    final base = def.isBoss
        ? const Color(0xFF3B2A22)
        : (def.isBeast ? const Color(0xFF2F2A22) : const Color(0xFF34302C));
    final p = Paint()..color = flashTint(base);
    if (def.isBeast) {
      // Corpo da bestia, basso e largo.
      canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.45, w * 0.9, h * 0.4), p);
      canvas.drawOval(Rect.fromLTWH(w * 0.0, h * 0.35, w * 0.35, h * 0.3), p);
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(Rect.fromLTWH(w * (0.15 + i * 0.2), h * 0.75, w * 0.08, h * 0.25), p);
      }
      canvas.drawCircle(Offset(w * 0.1, h * 0.46), w * 0.03, Paint()..color = Palette.ember);
    } else {
      // Figura armata.
      canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.6, w * 0.14, h * 0.4), p);
      canvas.drawRect(Rect.fromLTWH(w * 0.54, h * 0.6, w * 0.14, h * 0.4), p);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.42), const Radius.circular(6)),
          p);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.36, h * 0.04, w * 0.28, h * 0.2), const Radius.circular(10)),
          p);
      // Spallacci.
      canvas.drawCircle(Offset(w * 0.22, h * 0.26), w * 0.1, p);
      canvas.drawCircle(Offset(w * 0.78, h * 0.26), w * 0.1, p);
      canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.16, h * 0.02),
          Paint()..color = def.isBoss ? Palette.goldBright : Palette.blood);
      // Arma.
      canvas.drawLine(Offset(w * 0.15, h * 0.55), Offset(w * 0.0, h * 0.1),
          Paint()
            ..color = Palette.ash
            ..strokeWidth = 5);
    }
    if (def.isBoss) {
      // Corona spezzata del boss.
      final crown = Paint()..color = Palette.gold;
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.36, h * 0.05)
          ..lineTo(w * 0.4, -h * 0.03)
          ..lineTo(w * 0.46, h * 0.03)
          ..lineTo(w * 0.52, -h * 0.05)
          ..lineTo(w * 0.58, h * 0.03)
          ..lineTo(w * 0.64, -h * 0.02)
          ..lineTo(w * 0.64, h * 0.05)
          ..close(),
        crown,
      );
    }
  }
}

class _Projectile extends PositionComponent {
  _Projectile({required Vector2 from, required this.to, required this.color})
      : super(position: from, size: Vector2.all(10), anchor: Anchor.center);

  final Vector2 to;
  final Color color;

  @override
  Future<void> onLoad() async {
    add(MoveToEffect(to, EffectController(duration: 0.18)));
    add(RemoveEffect(delay: 0.2));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 5,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }
}
