import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import '../../domain/hunting.dart';
import '../../domain/items.dart';
import 'train_tab.dart' show startFreeFight;
import 'training_screen.dart';

/// Alternative a basso impatto, solo se il giocatore dichiara dolore.
const Map<ExerciseId, String> lowImpactAlternatives = {
  ExerciseId.pushUp: 'Push-up al muro',
  ExerciseId.crunch: 'Dead bug',
  ExerciseId.legRaise: 'Plank sugli avambracci',
  ExerciseId.squat: 'Ponte per glutei',
  ExerciseId.lunge: 'Ponte per glutei',
  ExerciseId.jumpingJack: 'Marcia sul posto',
};

/// Ogni voce della quest si fa combattendo: un nemico che si batte con
/// quell'esercizio, che rinasce finché vuoi. Le rep contano per la quest e
/// ogni uccisione lascia il suo bottino.
Future<void> runQuestItem(BuildContext context, QuestItem q) async {
  final s = context.read<GameState>();
  final foe = questFoe(q.exercise, s.character.level);
  if (foe != null) {
    await startFreeFight(context, foe.$1, respawn: true, move: foe.$2);
    return;
  }
  final remaining = (q.target - s.questDoneFor(q.exercise)).clamp(1, 9999);
  final result = await Navigator.of(context).push<SetResult>(
    MaterialPageRoute(
      builder: (_) => TrainingScreen(
        exercise: q.exercise,
        title: q.label,
        target: remaining,
        subtitle: 'Puoi dividere la quest in più serie durante la giornata: conta il totale.',
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  final xp = s.addTraining(q.exercise, result.reps);
  if (result.reps.isNotEmpty) toast(context, '+$xp XP');
}

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: OathBar(title: const Text('QUEST GIORNALIERA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatBar(value: s.questProgress, color: Palette.gold, height: 12),
          const SectionTitle('Esercizi'),
          for (final q in s.quest) _QuestRow(item: q),
          const SectionTitle('Chiusura obbligatoria'),
          ActionTile(
            icon: Icons.self_improvement,
            title: 'Stretching guidato',
            subtitle: s.daily.stretchingDone
                ? 'Fatto: +1 Punto Disciplina'
                : '5 posizioni da 40 secondi · dà Punti Disciplina',
            trailing: s.daily.stretchingDone
                ? const Icon(Icons.check_circle, color: Palette.goldBright)
                : null,
            onTap: s.daily.stretchingDone
                ? null
                : () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const StretchingScreen())),
          ),
          SectionTitle(s.questComplete ? 'Bottino ottenuto' : 'Bottino'),
          _QuestLoot(loot: s.questComplete ? s.daily.questLoot : null),
        ],
      ),
    );
  }
}

/// Ricompensa della quest: rune, XP, chiave e il forziere di materiali.
class _QuestLoot extends StatelessWidget {
  const _QuestLoot({this.loot});
  final Map<String, int>? loot;

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget icon, String text) => SizedBox(
          width: 76,
          child: Column(
            children: [
              SizedBox(height: 40, child: Center(child: icon)),
              const SizedBox(height: 4),
              Text(text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, color: Palette.ash)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 10,
          children: [
            cell(const Icon(Icons.diamond_outlined, color: Palette.goldBright), '100 rune'),
            cell(const Icon(Icons.auto_awesome, color: Palette.goldBright), '150 XP'),
            cell(const Icon(Icons.vpn_key_outlined, color: Palette.goldBright), 'Chiave'),
            if (loot != null)
              for (final e in loot!.entries)
                cell(ItemIcon(e.key, size: 36), '${e.value}× ${itemName(e.key)}')
            else
              cell(const Icon(Icons.inventory_2_outlined, color: Palette.gold), 'Forziere di materiali'),
          ],
        ),
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({required this.item});
  final QuestItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final done = s.questDoneFor(item.exercise);
    final complete = done >= item.target;
    final substitute = s.substitutions[item.exercise];
    final foe = questFoe(item.exercise, s.character.level)?.$1;
    return Card(
      child: ListTile(
        leading: Icon(
          complete ? Icons.check_circle : Icons.sports_martial_arts,
          color: complete ? Palette.goldBright : Palette.gold,
        ),
        title: Text(substitute ?? item.label),
        subtitle: Text(
          '${done.clamp(0, item.target)}/${item.target}${item.info.perLeg ? ' per gamba' : ''}'
          '${foe != null && !complete ? ' · contro ${foe.name}' : ''}'
          '${RoutineRules.shouldSuggestHarderVariant(item) ? ' · pronto per la versione successiva!' : ''}',
          style: const TextStyle(color: Palette.ash),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) => _menu(context, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'pain', child: Text('Ho dolore / un blocco')),
            if (RoutineRules.shouldSuggestHarderVariant(item))
              const PopupMenuItem(value: 'promote', child: Text('Passa alla versione più dura')),
          ],
        ),
        onTap: complete ? null : () => runQuestItem(context, item),
      ),
    );
  }

  void _menu(BuildContext context, String v) {
    final s = context.read<GameState>();
    if (v == 'promote') {
      s.promoteVariant(item.exercise);
      toast(context, 'Nuova versione sbloccata. I numeri ripartono più bassi.');
      return;
    }
    final alt = lowImpactAlternatives[item.exercise]!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: const Text('Sostituire l\'esercizio?'),
        content: Text(
          'Lo sostituiamo con "$alt", a basso impatto sullo stesso gruppo. '
          'Se il dolore continua, senti un medico o un fisioterapista.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              s.substitute(item.exercise, alt);
              Navigator.pop(ctx);
            },
            child: const Text('Sostituisci'),
          ),
        ],
      ),
    );
  }
}

/// Stretching guidato: 5 posizioni da 40 secondi.
class StretchingScreen extends StatefulWidget {
  const StretchingScreen({super.key});

  @override
  State<StretchingScreen> createState() => _StretchingScreenState();
}

class _StretchingScreenState extends State<StretchingScreen> {
  static const _poses = [
    (
      'Allungamento dei quadricipiti',
      'In piedi, tira il tallone verso il gluteo. Cambia gamba a metà.',
    ),
    ('Piegamento in avanti', 'Gambe tese, scendi con il busto senza forzare.'),
    ('Affondo basso con anca aperta', 'Ginocchio dietro a terra, spingi il bacino in avanti.'),
    ('Allungamento del petto', 'Mani intrecciate dietro la schiena, apri le spalle.'),
    ('Posizione del bambino', 'Siediti sui talloni e allunga le braccia avanti.'),
  ];
  static const _seconds = 40;

  int _index = 0;
  int _left = _seconds;
  Timer? _timer;
  bool _running = false;

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _left--);
      if (_left <= 0) _next();
    });
  }

  void _next() {
    if (_index + 1 >= _poses.length) {
      _timer?.cancel();
      context.read<GameState>().completeStretching();
      toast(context, 'Stretching completato: +1 Punto Disciplina');
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _left = _seconds;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (name, how) = _poses[_index];
    return Scaffold(
      appBar: OathBar(title: const Text('STRETCHING')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatBar(
              value: (_index + (_seconds - _left) / _seconds) / _poses.length,
              color: Palette.gold,
              label: 'Posizione ${_index + 1} di ${_poses.length}',
            ),
            const Spacer(),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, color: Palette.goldBright),
            ),
            const SizedBox(height: 8),
            Text(
              how,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.ash),
            ),
            const SizedBox(height: 24),
            Text(
              '$_left',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 72, color: Palette.holy),
            ),
            const Spacer(),
            FilledButton(onPressed: _toggle, child: Text(_running ? 'PAUSA' : 'VIA')),
          ],
        ),
      ),
    );
  }
}
