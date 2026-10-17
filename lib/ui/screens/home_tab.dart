import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import 'gear_screens.dart';
import 'novice_card.dart';
import 'onboarding.dart';
import 'progress_screen.dart';
import 'quest_screen.dart';
import 'attributes_tab.dart';
import 'settings_screen.dart';

/// La schermata del personaggio: il cavaliere e i suoi numeri, i mestieri,
/// gli attributi, il Cammino del Novizio, la quest e l'andamento.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});
  final void Function(int tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final (xpIn, xpNeed) = c.levelProgress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Expanded(child: Text('GYM OATH', style: titleStyle(size: 16, spacing: 6))),
            IconButton(
              tooltip: 'Impostazioni',
              icon: const Icon(Icons.settings_outlined, color: Palette.ash),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.2, -0.1),
                          radius: 0.8,
                          colors: [Color(0xFF3A2C16), Color(0x00000000)],
                        ),
                      ),
                      child: Align(
                        alignment: const Alignment(-0.45, 0),
                        child: KnightView(character: c, height: 270),
                      ),
                    ),
                    Positioned(
                      top: 28,
                      right: -4,
                      child: Column(
                        children: [
                          _GearButton(
                            icon: Icons.shield,
                            label: 'EQUIPAGGIAMENTO',
                            onTap: () => openEquipment(context),
                          ),
                          const SizedBox(height: 10),
                          _GearButton(
                            icon: Icons.backpack,
                            label: 'INVENTARIO',
                            onTap: () => openInventory(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.name.toUpperCase(), style: titleStyle(size: 22, spacing: 4)),
                Text('Livello ${c.level} · ${c.weapon.displayName}'
                    '${c.offhand != null ? ' · ${c.offhand!.name}' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Palette.ash)),
                const SizedBox(height: 10),
                StatBar(value: xpIn / xpNeed, color: Palette.gold, label: '$xpIn / $xpNeed XP'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat('Vita', '${c.maxHp}', Icons.favorite, Palette.blood),
                    _Stat('Attacco', '${s.attackValue}', Icons.gavel, Palette.goldBright),
                    _Stat('Difesa', '${(s.defenseValue * 100).round()}%',
                        Icons.shield_outlined, Palette.frost),
                    _Stat('Rune', '${c.runes}', Icons.diamond_outlined, Palette.gold),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Abilità'),
        _SkillRows(progress: s.skillProgressOf),
        const SizedBox(height: 4),
        const _AttributePanel(),
        const SizedBox(height: 8),
        NoviceCard(onNavigate: onNavigate),
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
        const SectionTitle('Il tuo andamento'),
        const ProgressCard(),
      ],
    );
  }
}

/// Pulsante d'oro sul lato destro del riquadro del personaggio.
class _GearButton extends StatelessWidget {
  const _GearButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.goldBright,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Palette.gold, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 80,
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Palette.night, size: 26),
              const SizedBox(height: 3),
              FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(label,
                      style: const TextStyle(
                          color: Palette.night,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le abilità in due righe centrate: combattimento sopra, produzione sotto.
/// Tutte le caselle hanno la stessa larghezza, così le righe si allineano.
class _SkillRows extends StatelessWidget {
  const _SkillRows({required this.progress});
  final (int, int, int) Function(Skill) progress;

  @override
  Widget build(BuildContext context) {
    const gap = 6.0;
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - gap * (Skill.crafts.length - 1)) / Skill.crafts.length;
      Widget row(List<Skill> skills) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, k) in skills.indexed) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(width: w, height: 86, child: _SkillTile(skill: k, progress: progress(k))),
              ],
            ],
          );
      return Column(children: [
        row(Skill.combatSkills),
        const SizedBox(height: gap),
        row(Skill.crafts),
      ]);
    });
  }
}

/// Gli attributi: con punti liberi si distribuiscono con + e −, poi si
/// conferma. Finché non confermi non cambia niente.
class _AttributePanel extends StatefulWidget {
  const _AttributePanel();

  @override
  State<_AttributePanel> createState() => _AttributePanelState();
}

class _AttributePanelState extends State<_AttributePanel> {
  final Map<Attribute, int> _pending = {};

  int get _spent => _pending.values.fold(0, (a, b) => a + b);

  void _confirm(GameState s) {
    _pending.forEach((a, n) {
      for (var i = 0; i < n; i++) {
        s.raiseAttribute(a);
      }
    });
    setState(_pending.clear);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final left = c.availablePoints - _spent;
    final allocating = c.availablePoints > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Attributi',
          trailing: allocating
              ? Text('$left ${left == 1 ? 'punto' : 'punti'} da spendere',
                  style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold))
              : TextButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const AttributesScreen())),
                  child: const Text('Perk e record'),
                ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: allocating ? 1.25 : 1.7,
          children: [
            for (final a in Attribute.values)
              _AttrTile(
                attribute: a,
                value: c.attr(a) + (_pending[a] ?? 0),
                added: _pending[a] ?? 0,
                onPlus: allocating && left > 0
                    ? () => setState(() => _pending[a] = (_pending[a] ?? 0) + 1)
                    : null,
                onMinus: (_pending[a] ?? 0) > 0
                    ? () => setState(() => _pending[a] = _pending[a]! - 1)
                    : null,
                allocating: allocating,
              ),
          ],
        ),
        if (allocating) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _spent > 0 ? () => setState(_pending.clear) : null,
                child: const FittedBox(child: Text('ANNULLA')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _spent > 0 ? () => _confirm(s) : null,
                child: const Text('CONFERMA'),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

IconData skillIcon(Skill k) => switch (k) {
      Skill.attack => Icons.gavel,
      Skill.defense => Icons.shield_outlined,
      Skill.magic => Icons.auto_fix_high,
      Skill.expeditions => Icons.explore,
      Skill.woodcutting => Icons.forest,
      Skill.mining => Icons.landscape,
      Skill.carpentry => Icons.carpenter,
      Skill.smelting => Icons.local_fire_department,
      Skill.smithing => Icons.hardware,
    };

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.skill, required this.progress});
  final Skill skill;
  final (int, int, int) progress;

  @override
  Widget build(BuildContext context) {
    final (lvl, xpIn, xpNeed) = progress;
    final color = skill.combat ? Palette.ember : Palette.gold;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(skillIcon(skill), color: color, size: 22),
            Text('$lvl', style: titleStyle(size: 18, color: Palette.holy, spacing: 0)),
            FittedBox(
              child: Text(skill.label,
                  style: const TextStyle(color: Palette.ash, fontSize: 11)),
            ),
            const SizedBox(height: 3),
            StatBar(value: xpNeed == 0 ? 1 : xpIn / xpNeed, color: color, height: 4),
          ],
        ),
      ),
    );
  }
}

class _AttrTile extends StatelessWidget {
  const _AttrTile({
    required this.attribute,
    required this.value,
    required this.added,
    required this.onPlus,
    required this.onMinus,
    required this.allocating,
  });
  final Attribute attribute;
  final int value;
  final int added;
  final VoidCallback? onPlus;
  final VoidCallback? onMinus;
  final bool allocating;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, VoidCallback? onTap) => InkResponse(
          onTap: onTap,
          radius: 18,
          child: Icon(icon, size: 26, color: onTap == null ? Palette.iron : Palette.goldBright),
        );
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: added > 0 ? Palette.goldBright : Palette.iron),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value',
                style: titleStyle(
                    size: 20, color: added > 0 ? Palette.holy : Palette.goldBright, spacing: 0)),
            FittedBox(
              child: Text(attribute.label, style: const TextStyle(color: Palette.ash, fontSize: 12)),
            ),
            if (allocating) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  step(Icons.remove_circle_outline, onMinus),
                  step(Icons.add_circle, onPlus),
                ],
              ),
            ],
          ],
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
