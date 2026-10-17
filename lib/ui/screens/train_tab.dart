import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../game/battle_game.dart' show enemyArtPath;
import '../../core/art.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/combat.dart';
import '../../domain/enemies.dart';
import '../../domain/exercise.dart';
import '../../domain/hunting.dart';
import '../../domain/items.dart';
import '../../domain/routine.dart';
import '../widgets/common.dart';
import '../widgets/trainer.dart';
import 'combat_screen.dart';
import 'novice_card.dart';
import 'expedition_map.dart';
import 'quest_screen.dart';

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
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestScreen())),
        ),
        const SectionTitle('Spedizioni'),
        for (final g in worldGroups)
          _GroupCard(
            group: g,
            cleared: expeditionsOf(g).where((e) => s.clearedExpeditions.contains(e.id)).length,
            trainedThisWeek: trainedThisWeek.contains(g),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupScreen(group: g))),
          ),
        const SectionTitle('Caccia libera'),
        for (final a in baseAnimals)
          _FreeFightTile(enemy: a, playerLevel: s.character.level, icon: Icons.pets),
        ActionTile(
          icon: Icons.menu_book,
          title: 'Tutti i nemici (${bestiary.length})',
          subtitle: 'Animali, mostri e boss, dal livello 1 in su',
          color: Palette.goldBright,
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BestiaryScreen())),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(group.label.toUpperCase(), style: titleStyle(size: 15)),
                        ),
                        Text(
                          '$cleared/4',
                          style: const TextStyle(color: Palette.ash, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      groupMaterials[group]!,
                      style: const TextStyle(color: Palette.ash, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: StatBar(value: cleared / 4, color: Palette.gold, height: 5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trainedThisWeek ? 'Fatto questa settimana' : 'Bonus Varietà',
                          style: TextStyle(
                            color: trainedThisWeek ? Palette.ash : Palette.ember,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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
      appBar: OathBar(title: Text(group.label.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Spedizioni'),
          for (final e in list)
            _ExpeditionCard(
              expedition: e,
              cleared: s.clearedExpeditions.contains(e.id),
              underLevel: s.character.level < e.level,
              oath: s.build,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ExpeditionMapScreen(expedition: e))),
            ),
          if (group != MuscleGroup.stretching) ...[
            const SectionTitle('Combattimenti liberi'),
            for (final m in {for (final e in list) ...e.monsters})
              _FreeFightTile(enemy: m, playerLevel: s.character.level),
            for (final e in list)
              _FreeFightTile(enemy: e.boss, playerLevel: s.character.level, icon: Icons.castle),
            const SectionTitle('Caccia infinita'),
            ActionTile(
              icon: Icons.all_inclusive,
              title: 'Caccia: ${list.first.monster.name}',
              subtitle: 'Nemici sempre più forti${s.bestHuntWave > 0 ? ' · record ${s.bestHuntWave}' : ''}',
              color: Palette.ember,
              onTap: () => startFreeFight(context, list.first.monster, endless: true),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tutti i nemici dell'allenamento libero, per livello, filtrabili.
class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  /// null = tutti; 'animals' = solo animali; altrimenti un gruppo.
  Object? _filter;

  bool _keep(EnemyDef e) => switch (_filter) {
        null => true,
        'animals' => e.isAnimal,
        final MuscleGroup g => !e.isAnimal && e.group == g,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final list = bestiary.where(_keep).toList();
    Widget chip(String label, Object? value) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: _filter == value,
            onSelected: (_) => setState(() => _filter = value),
          ),
        );
    return Scaffold(
      appBar: OathBar(title: const Text('CACCIA')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                chip('Tutti', null),
                chip('Animali', 'animals'),
                for (final g in worldGroups.where((g) => g != MuscleGroup.stretching))
                  chip(g.label, g),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (final e in list)
                  _FreeFightTile(
                    enemy: e,
                    playerLevel: s.character.level,
                    icon: e.isAnimal ? Icons.pets : (e.isBoss ? Icons.castle : null),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un nemico da combattere in libero, che rinasce finché non ti fermi.
class _FreeFightTile extends StatelessWidget {
  const _FreeFightTile({required this.enemy, required this.playerLevel, this.icon});
  final EnemyDef enemy;
  final int playerLevel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final under = playerLevel < enemy.level;
    return Card(
      child: ListTile(
        leading: Art.has(enemyArtPath(enemy))
            ? SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(enemyArtPath(enemy), fit: BoxFit.contain),
              )
            : Icon(icon ?? Icons.repeat, color: under ? Palette.blood : Palette.goldBright),
        title: OneLine(enemy.name),
        subtitle: Text(
          '${enemy.moves.map((m) => m.name).join(' o ')} · '
          '${enemy.loot.keys.map((k) => materialNames[k] ?? k).join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Palette.ash, fontSize: 13),
        ),
        trailing: Text(
          'LV ${enemy.level}',
          style: TextStyle(
            color: under ? Palette.blood : Palette.goldBright,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => startFreeFight(context, enemy, respawn: true),
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
    required this.oath,
  });
  final Expedition expedition;
  final bool cleared;
  final bool underLevel;
  final Attribute oath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    // Sopra il tuo livello la spedizione si vede, ma avvolta nella nebbia.
    return Opacity(
      opacity: underLevel ? 0.6 : 1,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: OneLine(e.name, style: titleStyle(size: 16))),
                    if (cleared)
                      const Icon(Icons.check_circle, color: Palette.goldBright, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${e.roman} · LV ${e.level}',
                      style: TextStyle(
                        color: underLevel ? Palette.blood : Palette.goldBright,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Boss: ${e.boss.name}',
                    style: const TextStyle(color: Palette.ember, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final d in {for (final d in e.drops) forBuild(d, oath)})
                      Tooltip(message: itemName(d), child: ItemIcon(d, size: 30)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un combattimento: si sceglie l'esercizio del mostro e la postura. Ritorna
/// true se il nemico cade.
Future<bool> startFreeFight(
  BuildContext context,
  EnemyDef enemy, {
  bool endless = false,
  bool respawn = false,
  double lootMultiplier = 1,
  Move? move,
}) async {
  final st = context.read<GameState>();
  if (endless && st.trainerEnabled && st.markHint('hunt')) {
    await showTrainer(context, trainerHints['hunt']!);
    if (!context.mounted) return false;
  }
  final choice = await showModalBottomSheet<(Move, Stance)>(
    context: context,
    backgroundColor: Palette.stone,
    builder: (_) => _FightSetup(enemy: enemy, move: move),
  );
  if (choice == null || !context.mounted) return false;
  final won = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CombatScreen(
        enemy: enemy,
        exercise: choice.$1.trackAs,
        move: choice.$1,
        stance: choice.$2,
        endless: endless,
        respawn: respawn,
        lootMultiplier: lootMultiplier,
      ),
    ),
  );
  return won == true;
}

class _FightSetup extends StatefulWidget {
  const _FightSetup({required this.enemy, this.move});
  final EnemyDef enemy;
  final Move? move;

  @override
  State<_FightSetup> createState() => _FightSetupState();
}

class _FightSetupState extends State<_FightSetup> {
  late Move _move = widget.move ?? widget.enemy.moves.first;
  Stance _stance = Stance.balanced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            widget.enemy.moves.length > 1
                ? '${widget.enemy.name}: scegli l\'esercizio'
                : '${widget.enemy.name} si batte con',
          ),
          OathChoice<Move>(
            options: [for (final m in widget.enemy.moves) (m, m.name)],
            selected: _move,
            columns: widget.enemy.moves.length.clamp(1, 2),
            onChanged: (m) => setState(() => _move = m),
          ),
          const SectionTitle('Postura'),
          OathChoice<Stance>(
            options: [for (final st in Stance.values) (st, st.label)],
            selected: _stance,
            color: Sections.training,
            onChanged: (st) => setState(() => _stance = st),
          ),
          const SizedBox(height: 6),
          Text(
              switch (_stance) {
                Stance.aggressive =>
                  'Più danni dati e subiti · sale l\'Attacco',
                Stance.balanced =>
                  'Metà Attacco, metà Difesa',
                Stance.defensive =>
                  '-25% danni subiti · sale la Difesa',
              },
              style: const TextStyle(color: Palette.ash)),
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
