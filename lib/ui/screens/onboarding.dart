import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/exercise.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import 'character_creation.dart';
import 'training_screen.dart';

/// Avviso di salute → questionario → test con la fotocamera.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    if (!state.healthAccepted) return const HealthWarningScreen();
    return const QuestionnaireScreen();
  }
}

class HealthWarningScreen extends StatelessWidget {
  const HealthWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Image.asset('assets/images/helm.png', height: 120),
                    const SizedBox(height: 18),
                    Text(
                      'GYM OATH',
                      textAlign: TextAlign.center,
                      style: titleStyle(size: 36, spacing: 8),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Il regno è caduto. Il tuo corpo è l\'ultima arma.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Palette.ash,
                        fontStyle: FontStyle.italic,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRIMA DI INIZIARE', style: titleStyle(size: 14)),
                            const SizedBox(height: 10),
                            const Text(
                              'Questo è un gioco, non un consiglio medico. Se hai problemi '
                              'di salute, dolori o sei in gravidanza, senti un medico prima '
                              'di allenarti. Fermati se senti dolore, vertigini o fiato '
                              'corto.\n\nLa fotocamera serve solo a contare le rep: le '
                              'immagini restano sul telefono.',
                              style: TextStyle(color: Palette.ash, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.read<GameState>().acceptHealth(),
                      child: const Text('HO CAPITO, INIZIAMO'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _name = TextEditingController();
  final _limits = TextEditingController();
  String _goal = 'Restare in forma';
  int _days = 3;
  PlayMode _mode = PlayMode.path;

  static const _goals = [
    'Restare in forma',
    'Perdere peso',
    'Diventare più forte',
    'Più resistenza',
  ];

  @override
  void dispose() {
    _name.dispose();
    _limits.dispose();
    super.dispose();
  }

  void _continue() {
    final state = context.read<GameState>();
    state.setCharacterName(_name.text);
    state.saveQuestionnaire(
      goal: _goal,
      daysPerWeek: _days,
      limitations: _limits.text,
      mode: _mode,
    );
    // Prima il cavaliere (senza armatura), poi il test.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => CharacterCreationScreen(
        onDone: () => Navigator.of(ctx).pushReplacement(
          MaterialPageRoute(builder: (_) => const FitnessTestScreen()),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OathBar(title: const Text('IL TUO GIURAMENTO')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nome del tuo eroe',
              border: OutlineInputBorder(),
            ),
          ),
          const SectionTitle('Obiettivo'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _goals)
                ChoiceChip(
                  label: Text(g),
                  selected: _goal == g,
                  onSelected: (_) => setState(() => _goal = g),
                ),
            ],
          ),
          const SectionTitle('Giorni di allenamento a settimana'),
          Slider(
            value: _days.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            label: '$_days',
            onChanged: (v) => setState(() => _days = v.round()),
          ),
          Text('$_days giorni', textAlign: TextAlign.center),
          const SectionTitle('Dolori o limitazioni'),
          TextField(
            controller: _limits,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Es. ginocchio destro, spalla… (facoltativo)',
              border: OutlineInputBorder(),
            ),
          ),
          const SectionTitle('Modalità di gioco'),
          for (final m in PlayMode.values)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: _mode == m ? Palette.gold : Palette.iron),
              ),
              child: ListTile(
                onTap: () => setState(() => _mode = m),
                leading: Icon(
                  _mode == m ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Palette.gold,
                ),
                title: Text(m.label),
                subtitle: Text(
                  m == PlayMode.path
                      ? 'Test iniziale, quest del giorno su misura e progressione.'
                      : 'Combatti come vuoi, scegli tu esercizi e mostri.',
                  style: const TextStyle(color: Palette.ash),
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _continue, child: const Text('AL TEST DELLA PROVA')),
        ],
      ),
    );
  }
}

/// Test iniziale: sei prove con pause. Se non fai neanche una rep si passa
/// da soli alla versione facilitata successiva.
class FitnessTestScreen extends StatefulWidget {
  const FitnessTestScreen({super.key, this.isRetest = false});
  final bool isRetest;

  @override
  State<FitnessTestScreen> createState() => _FitnessTestScreenState();
}

class _FitnessTestScreenState extends State<FitnessTestScreen> {
  int _index = 0;
  int _variant = 0;
  final Map<ExerciseId, TestResult> _results = {};

  /// Prima le gambe, che continuano a scaldare il corpo, poi la parte alta,
  /// il core e per ultimo il cardio.
  static const List<ExerciseId> order = [
    ExerciseId.squat,
    ExerciseId.lunge,
    ExerciseId.pushUp,
    ExerciseId.crunch,
    ExerciseId.legRaise,
    ExerciseId.jumpingJack,
  ];

  /// 40 secondi di jumping jack prima del test: non contano.
  bool _warmedUp = false;

  ExerciseId get _current => order[_index];
  bool get _done => _index >= order.length;

  Future<void> _warmUp() async {
    await Navigator.of(context).push<SetResult>(
      MaterialPageRoute(
        builder: (_) => const TrainingScreen(
          exercise: ExerciseId.jumpingJack,
          title: 'Riscaldamento',
          subtitle: 'Jumping jack a ritmo tranquillo: non conta per il test',
          timeLimit: Duration(seconds: 40),
        ),
      ),
    );
    if (mounted) setState(() => _warmedUp = true);
  }

  Future<void> _runCurrent() async {
    final ex = exercises[_current]!;
    final timed = ex.testMode == TestMode.repsIn60s;
    final result = await Navigator.of(context).push<SetResult>(
      MaterialPageRoute(
        builder: (_) => TrainingScreen(
          exercise: _current,
          title: ex.variant(_variant).name,
          subtitle: timed
              ? 'Più rep corrette possibili in 60 secondi'
              : 'Massimo di rep${ex.perLeg ? ' per gamba: prima la destra, poi cambia' : ''}. '
                  'Fermati quando la forma cede.',
          timeLimit: timed ? const Duration(seconds: 60) : null,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final reps = result.reps.length;
    if (reps == 0 && _variant < ex.easiestLevel) {
      setState(() => _variant++);
      toast(context, 'Proviamo con: ${ex.variant(_variant).name}');
      return;
    }
    setState(() {
      _results[_current] = TestResult(reps: reps, variantLevel: _variant);
      _index++;
      _variant = 0;
    });
    if (!_done) await _rest();
  }

  Future<void> _rest() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RestDialog(seconds: 90),
    );
  }

  Widget _warmUpPage() => Scaffold(
        appBar: OathBar(title: Text(widget.isRetest ? 'TORNEO DELLA PROVA' : 'TEST DELLA PROVA')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Text('Riscaldamento', style: titleStyle(size: 26)),
            const SizedBox(height: 8),
            const Text(
              'Il test cerca il tuo massimo: in ogni prova fai più ripetizioni che puoi. '
              'Prima scaldati con 40 secondi di jumping jack, poi si parte dalle gambe.',
              style: TextStyle(color: Palette.ash, fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _warmUp, child: const Text('INIZIA IL RISCALDAMENTO')),
            TextButton(
              onPressed: () => setState(() => _warmedUp = true),
              child: const Text('Sono già caldo'),
            ),
            if (!widget.isRetest)
              TextButton(
                onPressed: _skipWithDefaults,
                child: const Text('Salta il test (valori da principiante)'),
              ),
          ],
        ),
      );

  void _skipWithDefaults() {
    // Valori da principiante per chi vuole giocare in modalità Libera subito.
    const defaults = {
      ExerciseId.pushUp: TestResult(reps: 10, variantLevel: 1),
      ExerciseId.crunch: TestResult(reps: 20, variantLevel: 0),
      ExerciseId.legRaise: TestResult(reps: 10, variantLevel: 1),
      ExerciseId.squat: TestResult(reps: 25, variantLevel: 0),
      ExerciseId.lunge: TestResult(reps: 10, variantLevel: 0),
      ExerciseId.jumpingJack: TestResult(reps: 40, variantLevel: 0),
    };
    _complete(defaults);
  }

  void _complete(Map<ExerciseId, TestResult> results) {
    context.read<GameState>().completeTest(results);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _Summary(results: _results, onConfirm: () => _complete(_results));
    if (!_warmedUp) return _warmUpPage();
    final ex = exercises[_current]!;
    return Scaffold(
      appBar: OathBar(title: Text(widget.isRetest ? 'TORNEO DELLA PROVA' : 'TEST DELLA PROVA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StatBar(
            value: _index / order.length,
            color: Palette.gold,
            label: 'Prova ${_index + 1} di ${order.length}',
          ),
          const SizedBox(height: 20),
          Text(
            ex.variant(_variant).name,
            style: const TextStyle(fontSize: 28, color: Palette.goldBright),
          ),
          const SizedBox(height: 8),
          Text(
              switch (ex.testMode) {
                TestMode.maxReps =>
                  'Più ripetizioni che puoi${ex.perLeg ? ', prima con la destra e poi con la sinistra' : ''}.',
                TestMode.repsIn60s => 'Fai più rep corrette possibili in 60 secondi.',
                TestMode.hold => 'Tieni la posizione il più a lungo possibile.',
              },
              style: const TextStyle(color: Palette.ash, fontSize: 16)),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Appoggia il telefono a terra o su un mobile, a 2–3 metri, in modo '
                'che tutto il corpo sia inquadrato di lato. Serve buona luce.',
                style: TextStyle(color: Palette.ash),
              ),
            ),
          ),
          if (ex.variants.length > 1) ...[
            const SectionTitle('Versioni facilitate'),
            for (final v in ex.variants.skip(1))
              Text('· ${v.name}', style: const TextStyle(color: Palette.ash)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _runCurrent, child: const Text('INIZIA LA PROVA')),
          if (_variant < ex.easiestLevel)
            TextButton(
              onPressed: () => setState(() => _variant++),
              child: const Text('Passa alla versione facilitata'),
            ),
          if (!widget.isRetest && _index == 0)
            TextButton(
              onPressed: _skipWithDefaults,
              child: const Text('Salta il test (valori da principiante)'),
            ),
        ],
      ),
    );
  }
}

class _RestDialog extends StatefulWidget {
  const _RestDialog({required this.seconds});
  final int seconds;

  @override
  State<_RestDialog> createState() => _RestDialogState();
}

class _RestDialogState extends State<_RestDialog> {
  late int _left = widget.seconds;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _left > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _left--);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.stone,
      title: const Text('Riposo'),
      content: Text(
        '$_left s',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40, color: Palette.goldBright),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Salta')),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.results, required this.onConfirm});
  final Map<ExerciseId, TestResult> results;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final quest = RoutineRules.dailyQuest(results);
    return Scaffold(
      appBar: OathBar(title: const Text('IL TUO PUNTO DI PARTENZA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Da questi numeri nasce la tua quest giornaliera: il 60% del test, '
            'che salirà del 5% ogni 7 giorni fatti bene.',
            style: TextStyle(color: Palette.ash),
          ),
          const SectionTitle('Risultati e quest'),
          for (final q in quest)
            Card(
              child: ListTile(
                title: Text(q.label),
                subtitle: Text(
                  'Test: ${results[q.exercise]!.reps}${q.info.perLeg ? ' per gamba' : ''}',
                  style: const TextStyle(color: Palette.ash),
                ),
                trailing: Text(
                  '${q.target}',
                  style: const TextStyle(fontSize: 22, color: Palette.goldBright),
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onConfirm, child: const Text('PRESTA GIURAMENTO')),
        ],
      ),
    );
  }
}
