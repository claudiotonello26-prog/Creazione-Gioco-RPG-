import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import 'knight_view.dart';
import '../../core/sound.dart';

const String trainerName = 'Comandante Reynard';

class TrainerLine {
  const TrainerLine(this.pose, this.text);
  final TrainerPose pose;
  final String text;
}

/// Consigli del trainer alla prima visita di ogni parte del gioco.
const Map<String, List<TrainerLine>> trainerHints = {
  'home': [
    TrainerLine(TrainerPose.crossed,
        'Dunque sei tu il nuovo giurato. Sono il Comandante Reynard, maestro d\'armi. Ti seguirò ovunque, che ti piaccia o no.'),
    TrainerLine(TrainerPose.pointing,
        'Questa è la tua casa: il tuo cavaliere, la quest del giorno e il Cammino del Novizio. Segui le mie missioni e diventerai qualcuno.'),
    TrainerLine(TrainerPose.goofy, 'E non guardarmi così. L\'elmo è storto per scelta stilistica.'),
  ],
  'training': [
    TrainerLine(TrainerPose.pointing,
        'Qui si suda. Scegli il gruppo: ognuno ha quattro spedizioni, con un mostro e un boss, e materiali che trovi solo lì.'),
    TrainerLine(TrainerPose.thinking,
        'Vuoi la Forza? Spinta. Destrezza? Gambe. Fede? Core. Intelligenza? Cardio. E lo Stretching ti dà le pietre per incantare.'),
    TrainerLine(TrainerPose.crossed,
        'Guarda il livello consigliato. Sotto, senza armi e armature migliori, torni a casa in una cassa.'),
  ],
  'path': [
    TrainerLine(TrainerPose.crossed,
        'Una tappa alla volta. Fai le rep che ti chiedo, con la forma giusta: le mezze rep non le conto.'),
    TrainerLine(TrainerPose.cheering,
        'In cima c\'è il guardiano: 30 secondi per esercizio, a sfinimento. Se arrivi in fondo, il bottino è tuo.'),
  ],
  'forge': [
    TrainerLine(TrainerPose.pointing,
        'La Forgia ha quattro postazioni. Carpenteria per il legno, Fornace per i metalli, Incudine per armi e armature.'),
    TrainerLine(TrainerPose.thinking,
        'E l\'Incantamento: le pietre risvegliano l\'arma. A +3 cambia colore, a +6 si accende, a +10 ha la sua aura.'),
    TrainerLine(TrainerPose.facepalm,
        'Ogni postazione sale di livello man mano che lavori. No, non puoi forgiare lo Spadone Stellare il primo giorno.'),
  ],
  'walk': [
    TrainerLine(TrainerPose.pointing,
        'Un cavaliere cammina. I tuoi passi raccolgono legno nei boschi o minerale in miniera: scegli tu dove andare.'),
    TrainerLine(TrainerPose.crossed,
        'Più raccogli, più sali di livello come Taglialegna e Minatore, e si aprono boschi e miniere migliori.'),
  ],
  'arena': [
    TrainerLine(TrainerPose.crossed,
        'L\'Arena Pura, qui in alto accanto all\'Allenamento: niente armi, niente build. Solo tu e le tue rep contro un altro giurato. Qui non si bara.'),
  ],
  'guild': [
    TrainerLine(TrainerPose.cheering,
        'La Gilda! Fondane una o entra in quella dei tuoi amici: vi allenate insieme in diretta e vi sfidate senza toccare i punti dell\'Arena.'),
  ],
  'attributes': [
    TrainerLine(TrainerPose.thinking,
        'Ogni livello ti dà un punto. Vigore per la vita, Forza e Destrezza per le armi, Fede e Intelligenza per la magia.'),
    TrainerLine(
        TrainerPose.goofy, 'Io li ho messi tutti in Carisma. Ah, non c\'è Carisma? Peccato.'),
  ],
  'hunt': [
    TrainerLine(TrainerPose.cheering,
        'La Caccia infinita! Ogni nemico abbattuto ne chiama uno più forte. Vediamo quanto resisti prima di sentire YOU DIED.'),
  ],
};

/// Mostra il trainer in sovraimpressione con una o più battute.
Future<void> showTrainer(BuildContext context, List<TrainerLine> lines) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Trainer',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _TrainerOverlay(lines: lines),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
        child: child,
      ),
    ),
  );
}

/// Gesti da mostrare una volta per schermata, dopo le battute del trainer:
/// se si scorre in giù e, se c'è, la seconda scheda in alto da toccare.
const Map<String, (bool, String?)> gestureHints = {
  'home': (true, null),
  'training': (true, 'Arena'),
  'walk': (true, null),
  'market': (false, 'Fattucchiera'),
  'guild': (true, 'Cavalieri'),
};

/// Il consiglio [id] alla prima volta che serve, poi mai più.
void maybeShowHint(BuildContext context, String id) {
  final s = context.read<GameState>();
  final lines = trainerHints[id];
  final gesture = gestureHints[id];
  if ((lines == null && gesture == null) || !s.trainerEnabled || s.seenHints.contains(id)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!context.mounted || !s.markHint(id)) return;
    if (lines != null) await showTrainer(context, lines);
    if (gesture != null && context.mounted) {
      await showGestureHint(context, scroll: gesture.$1, tab: gesture.$2);
    }
  });
}

/// La mano che mostra il gesto: freccia che rimbalza verso il basso per
/// scorrere, cerchio che pulsa sulla seconda scheda in alto. Sparisce da
/// sola o al tocco.
Future<void> showGestureHint(BuildContext context, {bool scroll = true, String? tab}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Hint',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => _GestureHint(scroll: scroll, tab: tab),
  );
}

class _GestureHint extends StatefulWidget {
  const _GestureHint({required this.scroll, this.tab});
  final bool scroll;
  final String? tab;

  @override
  State<_GestureHint> createState() => _GestureHintState();
}

/// La scritta su una targhetta scura, leggibile sopra qualsiasi cosa.
Widget _pill(Widget child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.night.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.gold.withValues(alpha: 0.6)),
      ),
      child: child,
    );

class _GestureHintState extends State<_GestureHint> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final w = MediaQuery.sizeOf(context).width;
    const label = TextStyle(
      color: Palette.goldBright,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.none,
      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
    );
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (widget.tab != null)
              // La seconda scheda è la metà destra della riga sotto la testata.
              Positioned(
                top: pad.top + 57,
                left: w / 2,
                width: w / 2,
                height: 48,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Palette.goldBright.withValues(alpha: 0.5 + 0.5 * _anim.value),
                        width: 2 + 2 * _anim.value,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.tab != null)
              Positioned(
                top: pad.top + 57 + 52,
                left: w / 2,
                width: w / 2,
                child: Column(
                  children: [
                    const Icon(Icons.touch_app, color: Palette.goldBright, size: 34),
                    _pill(Text(tr('Tocca qui per: {tab}', {'tab': tr(widget.tab!)}),
                        textAlign: TextAlign.center, style: label)),
                  ],
                ),
              ),
            if (widget.scroll)
              Positioned(
                bottom: pad.bottom + 110,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, child) =>
                      Transform.translate(offset: Offset(0, 14 * _anim.value), child: child),
                  child: Column(
                    children: [
                      _pill(Text(tr('Scorri in giù: c\'è dell\'altro'), style: label)),
                      const Icon(Icons.keyboard_double_arrow_down, color: Palette.goldBright, size: 44),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOverlay extends StatefulWidget {
  const _TrainerOverlay({required this.lines});
  final List<TrainerLine> lines;

  @override
  State<_TrainerOverlay> createState() => _TrainerOverlayState();
}

/// Il file voce di una battuta: `<sezione>_<n>` per i consigli fissi
/// (es. home_1), altrimenti un verso secondo la posa (reynard_pointing).
String voiceIdFor(TrainerLine line) {
  for (final e in trainerHints.entries) {
    final i = e.value.indexWhere((l) => l.text == line.text);
    if (i >= 0) return '${e.key}_${i + 1}';
  }
  return 'reynard_${line.pose.name}';
}

class _TrainerOverlayState extends State<_TrainerOverlay> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _speak();
  }

  @override
  void dispose() {
    Sound.stopVoice();
    super.dispose();
  }

  void _speak() {
    final line = widget.lines[_i];
    if (!Sound.voice(voiceIdFor(line))) Sound.voice('reynard_${line.pose.name}');
  }

  void _next() {
    if (_i < widget.lines.length - 1) {
      setState(() => _i++);
      _speak();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.lines[_i];
    final last = _i == widget.lines.length - 1;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(builder: (context, box) {
          // Reynard dalla vita in su, grande quanto lo schermo permette,
          // appoggiato al bordo in basso; la nuvoletta sopra la testa.
          final h = min(box.maxHeight * 0.5, box.maxWidth * 440 / 480);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: TrainerFigure(key: ValueKey(line.pose), pose: line.pose, height: h, bust: true),
                  ),
                ),
              ),
              // Il taglio sotto la cintura sfuma nel nero.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.18,
                child: const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xE6000000)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: h * 0.97,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Nuvoletta.
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        // Oro pieno con testo nero: stacca dal resto dell'app.
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Palette.goldBright, Palette.gold],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF6B5320), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Palette.gold.withValues(alpha: 0.35), blurRadius: 18)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(trainerName).toUpperCase(),
                                style:
                                    titleStyle(size: 13, spacing: 3, color: const Color(0xFF3A2A10))),
                            const SizedBox(height: 6),
                            Text(tr(line.text),
                                style: const TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF14100A),
                                    height: 1.3,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                last ? tr('HO CAPITO') : tr('AVANTI  {i}/{n}', {'i': _i + 1, 'n': widget.lines.length}),
                                style: titleStyle(size: 12, color: const Color(0xFF3A2A10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // La punta scende verso la testa di Reynard.
                      Center(
                        child: CustomPaint(size: const Size(28, 16), painter: _Tail()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Tail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(_) => false;
}
