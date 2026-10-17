import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import 'knight_view.dart';
import '../../core/sound.dart';

const String trainerName = 'Ser Corvino';

class TrainerLine {
  const TrainerLine(this.pose, this.text);
  final TrainerPose pose;
  final String text;
}

/// Consigli del trainer alla prima visita di ogni parte del gioco.
const Map<String, List<TrainerLine>> trainerHints = {
  'home': [
    TrainerLine(TrainerPose.crossed,
        'Dunque sei tu il nuovo giurato. Sono Ser Corvino, maestro d\'armi. Ti seguirò ovunque, che ti piaccia o no.'),
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
        'L\'Arena Pura: niente armi, niente build. Solo tu e le tue rep contro un altro giurato. Qui non si bara.'),
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

/// Il consiglio [id] alla prima volta che serve, poi mai più.
void maybeShowHint(BuildContext context, String id) {
  final s = context.read<GameState>();
  final lines = trainerHints[id];
  if (lines == null || !s.trainerEnabled || s.seenHints.contains(id)) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted || !s.markHint(id)) return;
    showTrainer(context, lines);
  });
}

class _TrainerOverlay extends StatefulWidget {
  const _TrainerOverlay({required this.lines});
  final List<TrainerLine> lines;

  @override
  State<_TrainerOverlay> createState() => _TrainerOverlayState();
}

/// Il file voce di una battuta: `<sezione>_<n>` per i consigli fissi
/// (es. home_1), altrimenti un verso secondo la posa (corvino_pointing).
String voiceIdFor(TrainerLine line) {
  for (final e in trainerHints.entries) {
    final i = e.value.indexWhere((l) => l.text == line.text);
    if (i >= 0) return '${e.key}_${i + 1}';
  }
  return 'corvino_${line.pose.name}';
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
    if (!Sound.voice(voiceIdFor(line))) Sound.voice('corvino_${line.pose.name}');
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
    return SafeArea(
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: _next,
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
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
                        Text(trainerName.toUpperCase(),
                            style:
                                titleStyle(size: 13, spacing: 3, color: const Color(0xFF3A2A10))),
                        const SizedBox(height: 6),
                        Text(line.text,
                            style: const TextStyle(
                                fontSize: 17,
                                color: Color(0xFF14100A),
                                height: 1.3,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            last ? 'HO CAPITO' : 'AVANTI  ${_i + 1}/${widget.lines.length}',
                            style: titleStyle(size: 12, color: const Color(0xFF3A2A10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: CustomPaint(
                        size: const Size(24, 14),
                        painter: _Tail(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: TrainerFigure(key: ValueKey(line.pose), pose: line.pose, height: 150),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      ..lineTo(size.width * 0.3, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = Palette.gold);
  }

  @override
  bool shouldRepaint(_) => false;
}
