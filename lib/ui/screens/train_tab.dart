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
import '../widgets/element_badge.dart';
import '../widgets/trainer.dart';
import 'codex_screen.dart';
import 'contracts_screen.dart';
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
    return FoldedListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onNavigate != null) NoviceCard(onNavigate: onNavigate!),
        // La quest a colpo d'occhio: barra e chiavi; il resto è dentro.
        Card(
          child: InkWell(
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuestScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Icon(s.questComplete ? Icons.task_alt : Icons.assignment_outlined,
                      color: s.questComplete ? Palette.goldBright : Palette.gold, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLine(tr('Quest giornaliera'), align: Alignment.centerLeft),
                        const SizedBox(height: 6),
                        StatBar(
                          value: s.questProgress,
                          color: Palette.gold,
                          label: '${(s.questProgress * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: tr('Chiave della Spedizione: raddoppia il bottino'),
                    child: StatChip(Icons.key, '${s.expeditionKeys}', color: Palette.goldBright),
                  ),
                  const Icon(Icons.chevron_right, color: Palette.gold, size: 28),
                ],
              ),
            ),
          ),
        ),
        _QuickFights(playerLevel: s.character.level),
        SectionTitle(tr('Spedizioni')),
        AlertDot(
          on: s.contract?.complete ?? false,
          child: ActionTile(
            icon: Icons.history_edu,
            title: tr('Bacheca delle Taglie'),
            subtitle: s.contract == null
                ? tr('Firma un contratto: spedizioni da finire per un forziere')
                : s.contract!.complete
                    ? tr('Contratto finito: torna a riscuotere!')
                    : tr('Contratto di {who}: {done} / {n} spedizioni', {
                        'who': s.contract!.contractor.name,
                        'done': s.contract!.targets.where(s.contract!.done.contains).length,
                        'n': s.contract!.targets.length,
                      }),
            color: s.contract?.complete == true ? Palette.goldBright : Palette.gold,
            onTap: () => openContracts(context),
          ),
        ),
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
          subtitle: tr('Filtra per esercizio, difficoltà e zona'),
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
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: foes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final e = foes[i];
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
                        const SizedBox(height: 2),
                        LevelBadge(e, playerLevel),
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
  ExerciseId? _exercise;
  Difficulty? _difficulty;

  bool _keepGroup(EnemyDef e) => switch (_filter) {
        null => true,
        'animals' => e.isAnimal,
        final MuscleGroup g => !e.isAnimal && e.group == g,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final level = s.character.level;
    final list = bestiary
        .where((e) =>
            _keepGroup(e) &&
            (_exercise == null || e.exercises.contains(_exercise)) &&
            (_difficulty == null || Difficulty.of(e, level) == _difficulty))
        .toList();
    // Gli esercizi che compaiono nei nemici, nell'ordine dell'elenco esercizi.
    final used = {for (final e in bestiary) ...e.exercises};
    final exerciseIds = [for (final id in ExerciseId.values) if (used.contains(id)) id];
    Widget chip<T>(String label, T? value, T? current, void Function(T?) set, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(label, style: color == null ? null : TextStyle(color: color)),
            selected: current == value,
            onSelected: (_) => setState(() => set(value)),
          ),
        );
    Widget bar(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(title,
                    style: const TextStyle(color: Palette.ash, fontSize: 13)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(children: chips),
                ),
              ),
            ],
          ),
        );
    return Scaffold(
      appBar: OathBar(title: Text(tr('CACCIA'))),
      body: Column(
        children: [
          bar(tr('Esercizio'), [
            chip<ExerciseId>(tr('Tutti'), null, _exercise, (v) => _exercise = v),
            for (final id in exerciseIds)
              chip<ExerciseId>(exercises[id]!.name, id, _exercise, (v) => _exercise = v),
          ]),
          bar(tr('Difficoltà'), [
            chip<Difficulty>(tr('Tutte'), null, _difficulty, (v) => _difficulty = v),
            for (final d in Difficulty.values)
              chip<Difficulty>(d.label, d, _difficulty, (v) => _difficulty = v, color: d.color),
          ]),
          bar(tr('Zona'), [
            chip<Object>(tr('Tutte'), null, _filter, (v) => _filter = v),
            chip<Object>(tr('Animali'), 'animals', _filter, (v) => _filter = v),
            for (final g in worldGroups.where((g) => g != MuscleGroup.stretching))
              chip<Object>(g.label, g, _filter, (v) => _filter = v),
          ]),
          const SizedBox(height: 4),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(tr('Nessun nemico con questi filtri'),
                        style: const TextStyle(color: Palette.ash)),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      for (final e in list)
                        _FreeFightTile(
                          enemy: e,
                          playerLevel: level,
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
/// ritratto grande su fondo neutro, l'esercizio per batterlo, il livello
/// colorato per difficoltà e cosa lascia.
class _FreeFightTile extends StatelessWidget {
  const _FreeFightTile({required this.enemy, required this.playerLevel, this.icon});
  final EnemyDef enemy;
  final int playerLevel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final oath = context.watch<GameState>().build;
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
                    OneLine(enemy.name, style: titleStyle(size: 16, spacing: 1)),
                    const SizedBox(height: 4),
                    Row(children: [
                      LevelBadge(enemy, playerLevel),
                      if (enemy.element != null) ...[
                        const SizedBox(width: 8),
                        ElementIcon(enemy.element!, size: 18),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, size: 18, color: Palette.goldBright),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            enemy.moves.map((m) => m.name).join(tr(' o ')),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.holy,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final k in {for (final k in enemy.commonLoot.keys) forBuild(k, oath)})
                                CodexTap(k,
                                    child: Tooltip(
                                        message: itemName(k), child: ItemIcon(k, size: 26))),
                              if (enemy.rareLoot.isNotEmpty)
                                Tooltip(
                                  message: tr('Raro: {name}', {
                                    'name': enemy.rareLoot.map((id) => itemName(_dropKey(id, oath))).join(', '),
                                  }),
                                  child: const Icon(Icons.star, color: _rareColor, size: 20),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
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

const _commonColor = Palette.holy;
const _uncommonColor = Color(0xFF6FB7E8);
const _rareColor = Color(0xFFC58BEA);

/// Le ricompense di un nemico divise per rarità, con l'icona di ogni cosa:
/// si capisce subito chi attaccare per avere quello che manca.
class _EnemyRewards extends StatelessWidget {
  const _EnemyRewards(this.enemy);
  final EnemyDef enemy;

  String _pct(double p) {
    final v = p * 100;
    return '${v < 10 && v != v.roundToDouble() ? v.toStringAsFixed(1) : v.round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final oath = context.watch<GameState>().build;
    final special = enemy.specialChance;
    final uncommon = [for (final id in enemy.uncommonLoot) _dropKey(id, oath)];
    final rare = [for (final id in enemy.rareLoot) _dropKey(id, oath)];
    // Probabilità di ciascun pezzo, a vittoria.
    final pUncommon = uncommon.isEmpty ? 0.0 : special * (1 - enemy.rareShare) / uncommon.length;
    final pRare = rare.isEmpty ? 0.0 : special * enemy.rareShare / rare.length;
    Widget item(String id, String note, Color color, {bool highlight = false}) => CodexTap(
        id,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: color.withValues(alpha: highlight ? 1 : 0.5),
                    width: highlight ? 2 : 1,
                  ),
                ),
                child: weaponDefs.containsKey(id)
                    ? Icon(Icons.hardware, color: color, size: 34)
                    : ItemIcon(id, size: 34),
              ),
              const SizedBox(height: 3),
              Text(
                itemName(id),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Palette.holy, height: 1.15),
              ),
              Text(note,
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    Widget row(String title, Color color, String hint, List<Widget> items) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, color: color),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hint,
                        style: const TextStyle(color: Palette.ash, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 8, children: items),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(tr('Comuni'), _commonColor, tr('a ogni vittoria'), [
          for (final e in lootForBuild(enemy.commonLoot, oath).entries)
            item(e.key, 'x${e.value}', _commonColor),
        ]),
        if (uncommon.isNotEmpty)
          row(tr('Non comuni'), _uncommonColor, tr('al posto dei comuni'), [
            for (final id in uncommon) item(id, _pct(pUncommon), _uncommonColor),
          ]),
        if (rare.isNotEmpty)
          row(tr('Rari'), _rareColor, tr('più spesso in caccia infinita'), [
            for (final id in rare) item(id, _pct(pRare), _rareColor, highlight: true),
          ]),
      ],
    );
  }
}

/// La chiave d'inventario di un drop per la build: amuleti col prefisso,
/// componenti delle build convertiti.
String _dropKey(String id, Attribute oath) {
  if (amuletDefs.containsKey(id)) return 'amulet_$id';
  if (weaponDefs.containsKey(id)) return id;
  return forBuild(id, oath);
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
                    for (final d in {for (final d in e.drops) _dropKey(d, oath)})
                      CodexTap(d,
                          child: Tooltip(message: itemName(d), child: ItemIcon(d, size: 30))),
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
    final level = context.read<GameState>().character.level;
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
          const SizedBox(height: 4),
          Center(child: LevelBadge(e, level, big: true)),
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
          SectionTitle(tr('Ricompense')),
          _EnemyRewards(e),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((_move, _stance)),
            child: Text(tr('COMBATTI')),
          ),
        ],
      ),
    );
  }
}
