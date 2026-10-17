import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../widgets/common.dart';
import 'onboarding.dart';
import '../../domain/items.dart';
import '../../domain/novice.dart';
import '../widgets/knight_view.dart';
import '../widgets/trainer.dart';
import 'quest_screen.dart';
import 'settings_screen.dart';
import 'walk_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});
  final void Function(int tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final (xpIn, xpNeed) = c.levelProgress;
    final materials = c.materials.entries
        .where((e) => e.value > 0 && !e.key.startsWith('amulet_'))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Expanded(child: Text('IRON OATH', style: titleStyle(size: 16, spacing: 6))),
            IconButton(
              tooltip: 'Impostazioni',
              icon: const Icon(Icons.settings_outlined, color: Palette.ash),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        // Il tuo cavaliere, come appare con l'equipaggiamento di oggi.
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.1),
                      radius: 0.8,
                      colors: [Color(0xFF3A2C16), Color(0x00000000)],
                    ),
                  ),
                  child: Center(child: KnightView(character: c, height: 290)),
                ),
                const SizedBox(height: 8),
                Text(c.name.toUpperCase(), style: titleStyle(size: 22, spacing: 4)),
                Text('Livello ${c.level} · ${c.weapon.displayName}'
                    '${c.armor != null ? ' · ${c.armor!.name}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.ash)),
                const SizedBox(height: 10),
                StatBar(value: xpIn / xpNeed, color: Palette.gold, label: '$xpIn / $xpNeed XP'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat('Vita', '${c.maxHp}', Icons.favorite, Palette.blood),
                    _Stat('Attacco', '${c.weapon.attackRating(c).round()}', Icons.gavel,
                        Palette.goldBright),
                    _Stat('Difesa', '${((c.armor?.reduction ?? 0) * 100).round()}%',
                        Icons.shield_outlined, Palette.frost),
                    _Stat('Rune', '${c.runes}', Icons.diamond_outlined, Palette.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (s.noviceQuest != null) _NoviceCard(state: s),
        if (c.availablePoints > 0)
          ActionTile(
            icon: Icons.add_circle,
            title: '${c.availablePoints} punti da spendere',
            subtitle: 'Vai su Attributi per far crescere il tuo cavaliere',
            color: Palette.goldBright,
            onTap: () => onNavigate(4),
          ),
        if (!s.questComplete) ...[
          SectionTitle(
            'Quest giornaliera',
            trailing: Text(
              '${(s.questProgress * 100).round()}%',
              style: const TextStyle(color: Palette.ash),
            ),
          ),
          if (s.mode == PlayMode.free && !s.questComplete)
            const Text(
              'Sei in modalità Libera: la quest è facoltativa ma dà la Chiave della Spedizione.',
              style: TextStyle(color: Palette.ash),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatBar(
                    value: s.questProgress,
                    color: Palette.gold,
                    height: 12,
                  ),
                  const SizedBox(height: 10),
                  for (final q in s.quest)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            s.questDoneFor(q.exercise) >= q.target
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: s.questDoneFor(q.exercise) >= q.target
                                ? Palette.goldBright
                                : Palette.ash,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q.label)),
                          Text(
                            '${s.questDoneFor(q.exercise).clamp(0, q.target)}/${q.target}'
                            '${q.info.perLeg ? ' per gamba' : ''}',
                            style: const TextStyle(color: Palette.ash),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Icon(
                        s.daily.stretchingDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: s.daily.stretchingDone
                            ? Palette.goldBright
                            : Palette.ash,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Stretching guidato (5 min)')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuestScreen()),
                    ),
                    child: Text(
                      s.questComplete ? 'QUEST COMPLETATA' : 'CONTINUA LA QUEST',
                    ),
                  ),
                  if (s.questComplete)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Hai guadagnato una Chiave della Spedizione. Vai su Allenati.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Palette.goldBright),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          SectionTitle('Quest completata',
              trailing: Text('Streak ${s.streak}', style: const TextStyle(color: Palette.ember))),
          _QuestCalendar(today: DateTime.now(), active: s.activeDays, quests: s.questDays),
          const SizedBox(height: 6),
          const Text(
            'Hai guadagnato una Chiave della Spedizione. Torna domani per la prossima quest.',
            style: TextStyle(color: Palette.ash, fontSize: 13),
          ),
        ],
        if (s.retestDue) ...[
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.emoji_events_outlined,
            title: 'Torneo della Prova',
            subtitle: 'Sono passate 4 settimane: rifai il test e guarda quanto sei migliorato.',
            color: Palette.goldBright,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FitnessTestScreen(isRetest: true),
              ),
            ),
          ),
        ],
        const SectionTitle('Oggi'),
        ActionTile(
          icon: Icons.directions_walk,
          title: 'Camminata',
          subtitle: 'Collega i passi del telefono: diventano materiali da forgia',
          color: Palette.goldBright,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WalkScreen())),
        ),
        ActionTile(
          icon: Icons.explore_outlined,
          title: 'Spedizioni',
          subtitle: s.daily.expeditionDone
              ? 'Spedizione di oggi già fatta'
              : '${s.expeditionKeys} chiavi disponibili',
          onTap: () => onNavigate(1),
        ),
        ActionTile(
          icon: Icons.sports_kabaddi,
          title: 'Arena Pura',
          subtitle: '${s.seasonTitle} · ${s.arenaPoints} punti',
          onTap: () => onNavigate(3),
        ),
        ActionTile(
          icon: Icons.hardware,
          title: 'Forgia',
          subtitle: 'Potenzia ${c.weapon.displayName}',
          onTap: () => onNavigate(2),
        ),
        const SectionTitle('Equipaggiamento'),
        ActionTile(
          icon: Icons.gavel,
          title: c.weapon.displayName,
          subtitle: '${c.weapon.def.style.label} · aura di ${c.weapon.def.affinity.label.toLowerCase()}',
          onTap: () => onNavigate(2),
        ),
        ActionTile(
          icon: Icons.shield_outlined,
          title: c.armor?.name ?? 'Nessuna armatura',
          subtitle: c.armor == null
              ? 'Forgiala all\'Incudine'
              : 'Assorbe il ${(c.armor!.reduction * 100).round()}% dei colpi',
          onTap: () => onNavigate(2),
        ),
        for (final id in c.amulets)
          ActionTile(
            icon: Icons.brightness_7_outlined,
            title: amuletDefs[id]?.name ?? id,
            subtitle: amuletDefs[id]?.description,
          ),
        const SectionTitle('Bisaccia'),
        if (materials.isEmpty)
          const Text('Vuota. Sconfiggi mostri e cammina per raccogliere materiali.',
              style: TextStyle(color: Palette.ash))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in materials)
                InfoChip(Icons.hexagon_outlined, '${m.value}× ${materialNames[m.key] ?? m.key}'),
            ],
          ),
      ],
    );
  }
}

/// Il Cammino del Novizio: una missione guidata alla volta.
class _NoviceCard extends StatelessWidget {
  const _NoviceCard({required this.state});
  final GameState state;

  Future<void> _claim(BuildContext context) async {
    final done = state.claimNovice();
    if (done == null) return;
    final next = state.noviceQuest;
    await showTrainer(context, [
      TrainerLine(
        TrainerPose.cheering,
        'Missione "${done.title}" compiuta! '
        '${[if (done.runes > 0) '+${done.runes} rune', for (final e in done.loot.entries) '+${e.value} ${materialNames[e.key]}'].join(', ')}.',
      ),
      if (next != null)
        TrainerLine(TrainerPose.pointing, next.trainer)
      else
        const TrainerLine(TrainerPose.crossed,
            'Il Cammino del Novizio è finito. Non sei più un novizio. Sei... appena accettabile. Continua così.'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final q = state.noviceQuest!;
    final have = state.stat(q.stat).clamp(0, q.target);
    final ready = state.noviceReady;
    return Card(
      child: InkWell(
        onTap: () => ready
            ? _claim(context)
            : showTrainer(context, [TrainerLine(TrainerPose.pointing, q.trainer)]),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const TrainerFigure(pose: TrainerPose.crossed, height: 84),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CAMMINO DEL NOVIZIO · ${state.noviceStep + 1}/${noviceQuests.length}',
                        style: titleStyle(size: 11, color: Palette.gold, spacing: 1.5)),
                    const SizedBox(height: 2),
                    Text(q.title, style: titleStyle(size: 17, color: Palette.holy, spacing: 0.5)),
                    Text(q.goal, style: const TextStyle(color: Palette.ash, fontSize: 13)),
                    const SizedBox(height: 6),
                    StatBar(value: have / q.target, color: Palette.gold, label: '$have / ${q.target}'),
                    if (ready) ...[
                      const SizedBox(height: 6),
                      FilledButton(onPressed: () => _claim(context), child: const Text('RISCUOTI')),
                    ],
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          Text(value, style: titleStyle(size: 17, color: Palette.holy, spacing: 0)),
          Text(label.toUpperCase(),
              style: const TextStyle(color: Palette.ash, fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }
}

/// Ultime 4 settimane: oro pieno = quest completata, cerchio = app aperta.
class _QuestCalendar extends StatelessWidget {
  const _QuestCalendar({required this.today, required this.active, required this.quests});
  final DateTime today;
  final Set<String> active;
  final Set<String> quests;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final day0 = DateTime(today.year, today.month, today.day);
    // Si parte dal lunedì di 3 settimane fa.
    final start = day0.subtract(Duration(days: day0.weekday - 1 + 21));
    const names = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                for (final n in names)
                  Expanded(
                    child: Center(
                        child: Text(n, style: const TextStyle(color: Palette.ash, fontSize: 12))),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            for (var week = 0; week < 4; week++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    for (var d = 0; d < 7; d++)
                      Expanded(child: _cell(start.add(Duration(days: week * 7 + d)), day0)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 10, color: Palette.goldBright),
                Text(' quest fatta    ', style: TextStyle(color: Palette.ash, fontSize: 12)),
                Icon(Icons.circle_outlined, size: 10, color: Palette.gold),
                Text(' app aperta', style: TextStyle(color: Palette.ash, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(DateTime d, DateTime today) {
    final k = _key(d);
    final future = d.isAfter(today);
    final quest = quests.contains(k);
    final open = active.contains(k);
    final isToday = d == today;
    return Center(
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: quest ? Palette.goldBright : null,
          border: Border.all(
            color: quest || open ? Palette.gold : (isToday ? Palette.ash : Palette.iron),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Text('${d.day}',
            style: TextStyle(
              fontSize: 12,
              color: quest ? Palette.night : (future ? Palette.iron : Palette.ash),
              fontWeight: quest ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}
