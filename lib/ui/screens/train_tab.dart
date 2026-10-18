import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/art.dart';
import '../../core/theme.dart';
import '../../game/battle_game.dart' show enemyArtPath;
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
          title: tr('Quest giornaliera'),
          subtitle: tr(
              '{p}% fatta · premio: una chiave che raddoppia il bottino (ne hai {n})',
              {'p': (s.questProgress * 100).round(), 'n': s.expeditionKeys}),
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestScreen())),
        ),
        _QuickFights(playerLevel: s.character.level),
        SectionTitle(tr('Spedizioni')),
        for (final g in worldGroups)
          _GroupCard(
            group: g,
            cleared: expeditionsOf(g).where((e) => s.clearedExpeditions.contains(e.id)).length,
            trainedThisWeek: trainedThisWeek.contains(g),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => GroupScreen(group: g))),
          ),
        SectionTitle(tr('Caccia libera: tocca un nemico per combattere')),
        for (final a in baseAnimals)
          _FreeFightTile(enemy: a, playerLevel: s.character.level, icon: Icons.pets),
        ActionTile(
          icon: Icons.menu_book,
          title: tr('Tutti i nemici ({n})', {'n': bestiary.length}),
          subtitle: tr('Animali, mostri e boss, dal più debole al più forte'),
          color: Palette.goldBright,
          onTap: () =>
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BestiaryScreen())),
        ),
        const SizedBox(height: 6),
        Text(
          tr('Il tuo piano ({n} giorni a settimana): {plan}', {
            'n': s.daysPerWeek,
            'plan': plan.map((d) => d.map((g) => g.label).join(' + ')).join(' · '),
          }),
          style: const TextStyle(color: Palette.ash, fontSize: 12),
        ),
      ],
    );
  }
}

/// In cima al Training: i nemici adatti al tuo livello, in grande e a
/// colori su fondo neutro. Un tocco e si combatte.
class _QuickFights extends StatelessWidget {
  const _QuickFights({required this.playerLevel});
  final int playerLevel;

  @override
  Widget build(BuildContext context) {
    // Prima chi ha già l'illustrazione, poi dal più vicino al tuo livello.
    final list = bestiary.where((e) => !e.isBoss && e.level <= playerLevel + 2).toList()
      ..sort((a, b) {
        final art = (Art.has(enemyArtPath(b)) ? 1 : 0) - (Art.has(enemyArtPath(a)) ? 1 : 0);
        if (art != 0) return art;
        return (a.level - playerLevel).abs().compareTo((b.level - playerLevel).abs());
      });
    final foes = list.take(8).toList();
    if (foes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(tr('Combatti subito')),
        SizedBox(
          height: 222,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: foes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = foes[i];
              final under = playerLevel < e.level;
              return SizedBox(
                width: 150,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(21),
                    onTap: () => startFreeFight(context, e, respawn: true),
                    child: Column(
                      children: [
                        EnemyPortrait(e, size: 150),
                        const SizedBox(height: 6),
                        OneLine(e.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            align: Alignment.center),
                        Text(
                          tr('Liv. {n}', {'n': e.level}),
                          style: TextStyle(
                            color: under ? Palette.ember : Palette.goldBright,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
                      tr(groupMaterials[group]!),
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
                          trainedThisWeek ? tr('Fatto questa settimana') : tr('Bonus Varietà'),
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Palette.goldBright, size: 30),
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
          SectionTitle(tr('Spedizioni')),
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
            SectionTitle(tr('Combattimenti liberi: tocca un nemico')),
            for (final m in {for (final e in list) ...e.monsters})
              _FreeFightTile(enemy: m, playerLevel: s.character.level),
            for (final e in list)
              _FreeFightTile(enemy: e.boss, playerLevel: s.character.level, icon: Icons.castle),
            SectionTitle(tr('Caccia infinita')),
            ActionTile(
              icon: Icons.all_inclusive,
              title: tr('Caccia: {name}', {'name': list.first.monster.name}),
              subtitle: '${tr('Nemici sempre più forti')}'
                  '${s.bestHuntWave > 0 ? tr(' · record {n}', {'n': s.bestHuntWave}) : ''}',
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
      appBar: OathBar(title: Text(tr('CACCIA'))),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                chip(tr('Tutti'), null),
                chip(tr('Animali'), 'animals'),
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

/// Un nemico da combattere in libero, che rinasce finché non ti fermi:
/// ritratto grande su fondo neutro, cosa serve per batterlo e un pulsante.
class _FreeFightTile extends StatelessWidget {
  const _FreeFightTile({required this.enemy, required this.playerLevel, this.icon});
  final EnemyDef enemy;
  final int playerLevel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final under = playerLevel < enemy.level;
    final levelColor = under ? Palette.ember : Palette.goldBright;
    void fight() => startFreeFight(context, enemy, respawn: true);
    return Card(
      child: InkWell(
        onTap: fight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              EnemyPortrait(enemy, size: 104, fallback: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OneLine(enemy.name, style: titleStyle(size: 16, spacing: 1)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('Liv. {n}', {'n': enemy.level}),
                          style: TextStyle(
                            color: levelColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('Si batte con: {moves}',
                          {'moves': enemy.moves.map((m) => m.name).join(tr(' o '))}),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Palette.holy, fontSize: 14),
                    ),
                    Text(
                      tr('Lascia: {loot}', {
                        'loot': enemy.loot.keys.map((k) => materialNames[k] ?? k).join(', '),
                      }),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Palette.ash, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (under)
                          Expanded(
                            child: Text(
                              tr('Più forte di te'),
                              style: const TextStyle(color: Palette.ember, fontSize: 13),
                            ),
                          )
                        else
                          const Spacer(),
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              textStyle: const TextStyle(
                                fontFamily: kTitleFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                            onPressed: fight,
                            child: Text(tr('COMBATTI')),
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
                Text(tr('Boss: {name}', {'name': e.boss.name}),
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
    isScrollControlled: true,
    showDragHandle: true,
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
    final e = widget.enemy;
    final under = context.read<GameState>().character.level < e.level;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Il mostro in grande, su fondo neutro: si vede bene anche se è scuro.
          Center(child: EnemyPortrait(e, size: 190)),
          const SizedBox(height: 8),
          Center(child: OneLine(e.name, style: titleStyle(size: 20), align: Alignment.center)),
          Center(
            child: Text(
              under
                  ? tr('Livello {n} · più forte di te', {'n': e.level})
                  : tr('Livello {n}', {'n': e.level}),
              style: TextStyle(
                color: under ? Palette.ember : Palette.ash,
                fontSize: 15,
              ),
            ),
          ),
          SectionTitle(
            e.moves.length > 1 ? tr('Scegli l\'esercizio') : tr('Si combatte con'),
          ),
          OathChoice<Move>(
            options: [for (final m in widget.enemy.moves) (m, m.name)],
            selected: _move,
            columns: widget.enemy.moves.length.clamp(1, 2),
            onChanged: (m) => setState(() => _move = m),
          ),
          SectionTitle(tr('Postura')),
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
                  tr('Colpisci più forte ma subisci di più. Allena l\'Attacco.'),
                Stance.balanced =>
                  tr('Né troppo né poco. Allena Attacco e Difesa insieme.'),
                Stance.defensive =>
                  tr('Subisci il 25% di danni in meno. Allena la Difesa.'),
              },
              style: const TextStyle(color: Palette.ash)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((_move, _stance)),
            child: Text(tr('COMBATTI')),
          ),
        ],
      ),
    );
  }
}
