import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/combat.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import '../widgets/trainer.dart';
import 'combat_screen.dart';
import 'novice_card.dart';
import 'path_screen.dart';
import 'quest_screen.dart';
import 'training_screen.dart';

/// I cinque gruppi in cui si allena: ognuno ha il suo sentiero, le sue
/// quattro spedizioni e i suoi materiali.
const List<MuscleGroup> worldGroups = [
  MuscleGroup.push,
  MuscleGroup.legs,
  MuscleGroup.core,
  MuscleGroup.cardio,
  MuscleGroup.stretching,
];

/// Cosa si trova in ogni gruppo, in breve.
const Map<MuscleGroup, String> groupMaterials = {
  MuscleGroup.push: 'Ferro, acciaio e la linea della Forza',
  MuscleGroup.legs: 'Legno, pelle e la linea della Destrezza',
  MuscleGroup.core: 'Bronzo, oro e la linea della Fede',
  MuscleGroup.cardio: 'Argento lunare, inchiostro e la linea dell\'Intelligenza',
  MuscleGroup.stretching: 'Pietre di forgia e gemme',
};

class TrainTab extends StatelessWidget {
  const TrainTab({super.key, this.onNavigate});
  final void Function(int tab)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final plan = weeklyPlan(s.daysPerWeek);
    final trainedThisWeek = s.trainedGroups.values.expand((g) => g).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onNavigate != null) NoviceCard(onNavigate: onNavigate!),
        ActionTile(
          icon: Icons.assignment_outlined,
          title: 'Quest giornaliera',
          subtitle: '${(s.questProgress * 100).round()}% completata · dà una chiave che raddoppia '
              'il bottino di una spedizione (hai ${s.expeditionKeys} chiavi)',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const QuestScreen())),
        ),
        const SectionTitle('Scegli il gruppo'),
        const Text(
          'Ogni gruppo ha il suo sentiero, quattro spedizioni con mostro e boss, e materiali '
          'che si trovano solo lì.',
          style: TextStyle(color: Palette.ash, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final g in worldGroups)
          _GroupCard(
            group: g,
            cleared: expeditionsOf(g).where((e) => s.clearedExpeditions.contains(e.id)).length,
            trainedThisWeek: trainedThisWeek.contains(g),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupScreen(group: g))),
          ),
        const SizedBox(height: 6),
        Text(
          'Piano per ${s.daysPerWeek} giorni: ${plan.map((d) => d.map((g) => g.label).join(' + ')).join(' · ')}',
          style: const TextStyle(color: Palette.ash, fontSize: 12),
        ),
      ],
    );
  }
}

IconData groupIcon(MuscleGroup g) => switch (g) {
      MuscleGroup.push => Icons.fitness_center,
      MuscleGroup.stretching => Icons.self_improvement,
      MuscleGroup.core => Icons.adjust,
      MuscleGroup.legs => Icons.directions_walk,
      MuscleGroup.cardio => Icons.favorite,
      MuscleGroup.mobility => Icons.accessibility_new,
    };

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.cleared,
    required this.trainedThisWeek,
    required this.onTap,
  });
  final MuscleGroup group;
  final int cleared;
  final bool trainedThisWeek;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.gold, width: 1.5),
                  gradient: const RadialGradient(colors: [Color(0xFF3A2C16), Palette.night]),
                ),
                child: Icon(groupIcon(group), color: Palette.goldBright),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(group.label.toUpperCase(), style: titleStyle(size: 15))),
                      Text('$cleared/4', style: const TextStyle(color: Palette.ash, fontSize: 12)),
                    ]),
                    Text(groupMaterials[group]!,
                        style: const TextStyle(color: Palette.ash, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: StatBar(value: cleared / 4, color: Palette.gold, height: 5)),
                      const SizedBox(width: 8),
                      Text(trainedThisWeek ? 'Fatto questa settimana' : 'Bonus Varietà',
                          style: TextStyle(
                              color: trainedThisWeek ? Palette.ash : Palette.ember, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un gruppo: il sentiero, le quattro spedizioni e la caccia infinita.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.group});
  final MuscleGroup group;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final list = expeditionsOf(group);
    return Scaffold(
      appBar: AppBar(title: Text(group.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            group == MuscleGroup.stretching
                ? 'Qui non si combatte: gli spiriti si calmano se tieni la posa. Non c\'è giusto o '
                    'sbagliato, conta restare fermi. ${groupMaterials[group]}.'
                : '${groupMaterials[group]}. Ogni spedizione ha un mostro e un boss: sotto il livello '
                    'consigliato, senza l\'equipaggiamento giusto, si muore.',
            style: const TextStyle(color: Palette.ash),
          ),
          const SizedBox(height: 8),
          ActionTile(
            icon: Icons.route,
            title: 'Sentiero di allenamento',
            subtitle: 'Quattro tappe e un guardiano in cima · ${s.pathProgress(group)}/5',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => PathScreen(group: group))),
          ),
          const SectionTitle('Spedizioni'),
          for (final e in list)
            _ExpeditionCard(
              expedition: e,
              cleared: s.clearedExpeditions.contains(e.id),
              underLevel: s.character.level < e.level,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ExpeditionScreen(expedition: e))),
            ),
          if (group != MuscleGroup.stretching) ...[
            const SectionTitle('Caccia infinita'),
            ActionTile(
              icon: Icons.all_inclusive,
              title: 'Caccia: ${list.first.monster.name}',
              subtitle: 'Ogni nemico abbattuto ne chiama uno più forte. Più resisti, più è '
                  'probabile un drop raro${s.bestHuntWave > 0 ? ' · record ${s.bestHuntWave}' : ''}',
              color: Palette.ember,
              onTap: () => startFreeFight(context, list.first.monster, endless: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpeditionCard extends StatelessWidget {
  const _ExpeditionCard({
    required this.expedition,
    required this.cleared,
    required this.underLevel,
    required this.onTap,
  });
  final Expedition expedition;
  final bool cleared;
  final bool underLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(e.name, style: titleStyle(size: 16))),
                if (cleared) const Icon(Icons.check_circle, color: Palette.goldBright, size: 20),
                const SizedBox(width: 6),
                Text('LV ${e.level}',
                    style: TextStyle(
                        color: underLevel ? Palette.blood : Palette.goldBright,
                        fontWeight: FontWeight.bold)),
              ]),
              Text(e.blurb, style: const TextStyle(color: Palette.ash, fontSize: 13)),
              const SizedBox(height: 6),
              Text('${e.monster.name} · ${e.monster.moves.map((m) => m.name).join(' o ')}',
                  style: const TextStyle(fontSize: 14)),
              Text('Boss: ${e.boss.name} · ${e.boss.moves.map((m) => m.name).join(', ')}',
                  style: const TextStyle(color: Palette.ember, fontSize: 14)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in e.drops)
                    InfoChip(Icons.hexagon_outlined, materialNames[d] ?? d,
                        color: Palette.goldBright),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un combattimento: si sceglie l'esercizio del mostro e la postura. Ritorna
/// true se il nemico cade.
Future<bool> startFreeFight(BuildContext context, EnemyDef enemy,
    {bool endless = false, double lootMultiplier = 1}) async {
  final st = context.read<GameState>();
  if (endless && st.trainerEnabled && st.markHint('hunt')) {
    await showTrainer(context, trainerHints['hunt']!);
    if (!context.mounted) return false;
  }
  final choice = await showModalBottomSheet<(Move, Stance)>(
    context: context,
    backgroundColor: Palette.stone,
    builder: (_) => _FightSetup(enemy: enemy),
  );
  if (choice == null || !context.mounted) return false;
  final won = await Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => CombatScreen(
      enemy: enemy,
      exercise: choice.$1.trackAs,
      move: choice.$1,
      stance: choice.$2,
      endless: endless,
      lootMultiplier: lootMultiplier,
    ),
  ));
  return won == true;
}

class _FightSetup extends StatefulWidget {
  const _FightSetup({required this.enemy});
  final EnemyDef enemy;

  @override
  State<_FightSetup> createState() => _FightSetupState();
}

class _FightSetupState extends State<_FightSetup> {
  late Move _move = widget.enemy.moves.first;
  Stance _stance = Stance.balanced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(widget.enemy.moves.length > 1
              ? '${widget.enemy.name}: scegli l\'esercizio'
              : '${widget.enemy.name} si batte con'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in widget.enemy.moves)
                ChoiceChip(
                  label: Text(m.name),
                  selected: _move == m,
                  onSelected: (_) => setState(() => _move = m),
                ),
            ],
          ),
          const SectionTitle('Postura'),
          SegmentedButton<Stance>(
            segments: [
              for (final st in Stance.values) ButtonSegment(value: st, label: Text(st.label)),
            ],
            selected: {_stance},
            onSelectionChanged: (v) => setState(() => _stance = v.first),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_stance) {
              Stance.aggressive =>
                'Colpi più penetranti, ma subisci più danni. Ogni rep fa salire Attacco.',
              Stance.balanced => 'Nessun vantaggio né svantaggio. Le rep vanno metà ad Attacco, metà a Difesa.',
              Stance.defensive =>
                'Subisci un quarto di danni in meno, colpi meno penetranti. Ogni rep fa salire Difesa.',
            },
            style: const TextStyle(color: Palette.ash),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((_move, _stance)),
            child: const Text('COMBATTI'),
          ),
        ],
      ),
    );
  }
}

/// Una spedizione: prima il mostro, poi il boss. Nello Stretching si tiene
/// la posa invece di combattere.
class ExpeditionScreen extends StatefulWidget {
  const ExpeditionScreen({super.key, required this.expedition});
  final Expedition expedition;

  @override
  State<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends State<ExpeditionScreen> {
  int _stage = 0;
  bool _failed = false;
  bool _useKey = false;
  bool _keyUsed = false;

  List<EnemyDef> get _enemies => [widget.expedition.monster, widget.expedition.boss];
  bool get _stretching => widget.expedition.group == MuscleGroup.stretching;

  /// Secondi da tenere ogni posa: salgono con la spedizione.
  int get _holdSeconds => switch (widget.expedition.level) {
        < 10 => 20,
        < 25 => 30,
        < 45 => 40,
        _ => 60,
      };

  double _multiplier(GameState s) {
    if (_keyUsed) return 2;
    if (_useKey && s.useExpeditionKey()) {
      _keyUsed = true;
      return 2;
    }
    return 1;
  }

  Future<void> _go() async {
    final s = context.read<GameState>();
    final enemy = _enemies[_stage];
    final m = _multiplier(s);
    final won = _stretching ? await _hold(s, enemy, m) : await startFreeFight(context, enemy, lootMultiplier: m);
    if (!mounted) return;
    setState(() {
      if (won) {
        _stage++;
        if (_stage == 2) s.clearExpedition(widget.expedition.id);
      } else {
        _failed = true;
      }
    });
  }

  /// Tutte le pose dello spirito, una dopo l'altra, tenute per [_holdSeconds].
  Future<bool> _hold(GameState s, EnemyDef enemy, double m) async {
    var total = 0;
    for (final (i, move) in enemy.moves.indexed) {
      final r = await Navigator.of(context).push<SetResult>(MaterialPageRoute(
        builder: (_) => TrainingScreen(
          exercise: ExerciseId.stretch,
          title: move.name,
          subtitle: '${enemy.name} · posa ${i + 1}/${enemy.moves.length} · '
              'tienila $_holdSeconds secondi',
          timeLimit: Duration(seconds: _holdSeconds + 15),
        ),
      ));
      if (!mounted || r == null || r.held.inSeconds < _holdSeconds) {
        if (mounted) toast(context, 'Lo spirito si agita ancora. Riprova la posa.');
        return false;
      }
      total += r.held.inSeconds;
    }
    final loot = s.holdVictory(enemy, seconds: total, lootMultiplier: m);
    if (!mounted) return true;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Text('${enemy.name.toUpperCase()} SI CALMA',
            textAlign: TextAlign.center, style: titleStyle(size: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+${loot.xp} XP · +${loot.runes} rune'),
            for (final e in loot.materials.entries)
              Text('+${e.value} ${materialNames[e.key] ?? e.key}',
                  style: const TextStyle(color: Palette.goldBright)),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('CONTINUA'))],
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final e = widget.expedition;
    final done = _stage >= 2;
    return Scaffold(
      appBar: AppBar(title: Text(e.name.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(e.blurb, style: const TextStyle(color: Palette.ash)),
          if (s.character.level < e.level)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Livello consigliato ${e.level}: tu sei al ${s.character.level}. '
                '${_stretching ? 'Le pose saranno lunghe.' : 'Senza armi e armature migliori rischi di cadere.'}',
                style: const TextStyle(color: Palette.blood),
              ),
            ),
          const SizedBox(height: 8),
          for (var i = 0; i < 2; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < _stage ? Palette.gold : Palette.iron,
                  foregroundColor: Palette.night,
                  child: Text(i == 1 ? 'B' : '1'),
                ),
                title: Text(_enemies[i].name),
                subtitle: Text(
                  '${_enemies[i].moves.map((m) => m.name).join(_stretching ? ', poi ' : ' o ')}'
                  '${_stretching ? ' · $_holdSeconds s per posa' : ''}\n'
                  'Lascia: ${_enemies[i].loot.keys.map((k) => materialNames[k] ?? k).join(', ')}',
                  style: const TextStyle(color: Palette.ash),
                ),
                isThreeLine: true,
                trailing: i < _stage ? const Icon(Icons.check, color: Palette.goldBright) : null,
              ),
            ),
          if (!done && (s.expeditionKeys > 0 || _keyUsed))
            SwitchListTile(
              value: _useKey || _keyUsed,
              onChanged: _keyUsed ? null : (v) => setState(() => _useKey = v),
              title: const Text('Usa una chiave: bottino doppio'),
              subtitle: Text(_keyUsed ? 'Chiave usata' : 'Ne hai ${s.expeditionKeys}',
                  style: const TextStyle(color: Palette.ash)),
            ),
          const SizedBox(height: 16),
          if (done)
            Text(
              _stretching ? 'Spedizione completata. Il chiostro è in pace.' : 'Spedizione completata. Il boss è caduto.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.goldBright, fontSize: 18),
            )
          else if (_failed)
            Column(
              children: [
                Text(_stretching ? 'Lo spirito non si è calmato.' : 'Sei caduto. Il bottino raccolto resta tuo.',
                    style: const TextStyle(color: Palette.ash)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _failed = false),
                  child: const Text('Riprova'),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: _go,
              child: Text(_stage == 1
                  ? (_stretching ? 'CALMA IL BOSS' : 'AFFRONTA IL BOSS')
                  : (_stretching ? 'CALMA LO SPIRITO' : 'AFFRONTA ${_enemies[0].name.toUpperCase()}')),
            ),
        ],
      ),
    );
  }
}
