import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/items.dart';
import '../../domain/character.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import 'gear_screens.dart';
import 'novice_card.dart';
import 'onboarding.dart';
import 'progress_screen.dart';
import 'quest_screen.dart';
import 'steps_card.dart';
import 'attributes_tab.dart';

/// La schermata del personaggio: il cavaliere e i suoi numeri, i mestieri,
/// gli attributi, il Cammino del Novizio, la quest e l'andamento.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigate});

  /// Le due prove di prima schermata (si sceglie dagli screenshot).
  static HomeLayout layout = HomeLayout.center;
  final void Function(int tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final (xpIn, xpNeed) = c.levelProgress;
    // La prima schermata entra tutta: eroe, livello, numeri e abilità.
    // Sotto, scorrendo, attributi, passi, Cammino e quest.
    return LayoutBuilder(
      builder: (context, box) => ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          SizedBox(
            height: max(box.maxHeight - 8, 520),
            child: HomeTab.layout == HomeLayout.side
                ? _HomeTopSide(state: s, xp: (xpIn, xpNeed))
                : _HomeTopCenter(state: s, xp: (xpIn, xpNeed)),
          ),
        const SizedBox(height: 4),
        const _AttributePanel(),
        const SizedBox(height: 8),
        StepsCard(onOpenGathering: () => onNavigate(2)),
        NoviceCard(onNavigate: onNavigate),
        if (!s.questComplete) ...[
          SectionTitle(
            tr('Quest giornaliera'),
            trailing: Text(
              '${(s.questProgress * 100).round()}%',
              style: const TextStyle(color: Palette.ash),
            ),
          ),
          if (s.mode == PlayMode.free && !s.questComplete)
            Text(
              tr('Sei in modalità Libera: la quest è facoltativa ma dà la Chiave della Spedizione.'),
              style: const TextStyle(color: Palette.ash),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatBar(value: s.questProgress, color: Palette.gold, height: 12),
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
                            '${q.info.perLeg ? tr(' per gamba') : ''}',
                            style: const TextStyle(color: Palette.ash),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Icon(
                        s.daily.stretchingDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                        color: s.daily.stretchingDone ? Palette.goldBright : Palette.ash,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tr('Stretching guidato (5 min)'))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const QuestScreen())),
                    child: Text(s.questComplete ? tr('QUEST COMPLETATA') : tr('CONTINUA LA QUEST')),
                  ),
                  if (s.questComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        tr('Hai guadagnato una Chiave della Spedizione: usala nel Training per raddoppiare il bottino.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Palette.goldBright),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          SectionTitle(
            tr('Quest completata'),
            trailing: Text(tr('Streak {n}', {'n': s.streak}), style: const TextStyle(color: Palette.ember)),
          ),
          _QuestCalendar(today: DateTime.now(), active: s.activeDays, quests: s.questDays),
          const SizedBox(height: 6),
          Text(
            tr('Hai guadagnato una Chiave della Spedizione. Torna domani per la prossima quest.'),
            style: const TextStyle(color: Palette.ash, fontSize: 13),
          ),
        ],
        if (s.retestDue) ...[
          const SizedBox(height: 12),
          ActionTile(
            icon: Icons.emoji_events_outlined,
            title: tr('Torneo della Prova'),
            subtitle: tr('Sono passate 4 settimane: rifai il test e guarda quanto sei migliorato.'),
            color: Palette.goldBright,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FitnessTestScreen(isRetest: true))),
          ),
        ],
        SectionTitle(tr('Il tuo andamento')),
        const ProgressCard(),
        ],
      ),
    );
  }
}

/// Pulsante d'oro sotto la scheda del personaggio.
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
          width: 148,
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Palette.night, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Palette.night,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          tr('Attributi'),
          trailing: allocating
              ? Text(
                  left == 1
                      ? tr('{n} punto da spendere', {'n': left})
                      : tr('{n} punti da spendere', {'n': left}),
                  style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold),
                )
              : TextButton(
                  onPressed: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const AttributesScreen())),
                  child: Text(tr('Perk e record')),
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
                onPlus: allocating &&
                        left > 0 &&
                        c.attr(a) + (_pending[a] ?? 0) < Character.maxAttribute
                    ? () => setState(() => _pending[a] = (_pending[a] ?? 0) + 1)
                    : null,
                onMinus: (_pending[a] ?? 0) > 0
                    ? () => setState(() => _pending[a] = _pending[a]! - 1)
                    : null,
                allocating: allocating,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _OathTile(state: s),
        if (allocating) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _spent > 0 ? () => setState(_pending.clear) : null,
                  child: FittedBox(child: Text(tr('ANNULLA'))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _spent > 0 ? () => _confirm(s) : null,
                  child: Text(tr('CONFERMA')),
                ),
              ),
            ],
          ),
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

/// Come si allena un'abilità, in una riga.
String skillHint(Skill k) => switch (k) {
      Skill.woodcutting => tr('Sale camminando: spendi i passi nei boschi della Raccolta.'),
      Skill.mining => tr('Sale camminando: spendi i passi nelle cave della Raccolta.'),
      Skill.carpentry => tr('Sale creando assi, archi e bastoni in Carpenteria.'),
      Skill.smelting => tr('Sale fondendo lingotti e pietre alla Fornace.'),
      Skill.smithing => tr('Sale forgiando armi e armature all\'Incudine.'),
      Skill.attack => tr('Sale combattendo con spade e archi, in postura aggressiva o bilanciata.'),
      Skill.defense => tr('Sale combattendo in postura difensiva o bilanciata, e tenendo le pose.'),
      Skill.magic => tr('Sale combattendo con i bastoni, in postura aggressiva o bilanciata.'),
      Skill.expeditions => tr('Sale battendo i nemici delle spedizioni.'),
    };

void _showSkill(BuildContext context, Skill skill, (int, int, int) progress) {
  final (lvl, xpIn, xpNeed) = progress;
  final max = lvl >= skill.maxLevel;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.stone,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(skillIcon(skill), color: skill.combat ? Palette.ember : Palette.gold, size: 40),
          const SizedBox(height: 6),
          Text(skill.label.toUpperCase(), style: titleStyle(size: 18)),
          Text(tr('Livello {n}', {'n': lvl}), style: const TextStyle(color: Palette.goldBright)),
          const SizedBox(height: 12),
          if (max)
            Text(tr('Livello massimo raggiunto'), style: const TextStyle(color: Palette.holy))
          else
            StatBar(
              value: xpNeed == 0 ? 1 : xpIn / xpNeed,
              color: Palette.gold,
              height: 12,
              label: xpLeftLabel(xpIn, xpNeed),
            ),
          const SizedBox(height: 12),
          Text(skillHint(skill),
              textAlign: TextAlign.center, style: const TextStyle(color: Palette.ash, fontSize: 15)),
        ],
      ),
    ),
  );
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
            Text(
              '$value',
              style: titleStyle(
                size: 20,
                color: added > 0 ? Palette.holy : Palette.goldBright,
                spacing: 0,
              ),
            ),
            FittedBox(
              child: Text(
                attribute.label,
                style: const TextStyle(color: Palette.ash, fontSize: 12),
              ),
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
    final names = appLang == Lang.it
        ? const ['L', 'M', 'M', 'G', 'V', 'S', 'D']
        : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
                      child: Text(n, style: const TextStyle(color: Palette.ash, fontSize: 12)),
                    ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 10, color: Palette.goldBright),
                Text(tr(' quest fatta    '), style: const TextStyle(color: Palette.ash, fontSize: 12)),
                const Icon(Icons.circle_outlined, size: 10, color: Palette.gold),
                Text(tr(' app aperta'), style: const TextStyle(color: Palette.ash, fontSize: 12)),
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
        child: Text(
          '${d.day}',
          style: TextStyle(
            fontSize: 12,
            color: quest ? Palette.night : (future ? Palette.iron : Palette.ash),
            fontWeight: quest ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Il Giuramento: per quale build arrivano i componenti speciali, da
/// qualunque gruppo muscolare.
class _OathTile extends StatelessWidget {
  const _OathTile({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final b = state.build;
    final parts = buildMaterials[b]!;
    return ActionTile(
      icon: Icons.local_fire_department_outlined,
      title: tr('Giuramento: {build}', {'build': b.label}) + (state.oath == null ? tr(' (auto)') : ''),
      subtitle: tr('Ogni spedizione ti dà {a} e {b}', {'a': itemName(parts[0]), 'b': itemName(parts[1])}),
      trailing: ItemIcon(parts[0], size: 30),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Palette.night,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(tr('Giuramento')),
              ActionTile(
                icon: Icons.auto_awesome,
                title: tr('Automatico'),
                subtitle: tr('Segue il tuo attributo di build più alto'),
                color: state.oath == null ? Palette.goldBright : Palette.gold,
                onTap: () {
                  state.setOath(null);
                  Navigator.pop(ctx);
                },
              ),
              for (final a in oathAttributes)
                ActionTile(
                  icon: state.oath == a ? Icons.check_circle : Icons.circle_outlined,
                  title: a.label,
                  subtitle: buildMaterials[a]!.map(itemName).join(' · '),
                  color: state.oath == a ? Palette.goldBright : Palette.gold,
                  trailing: ItemIcon(buildMaterials[a]![0], size: 28),
                  onTap: () {
                    state.setOath(a);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HomeLayout { side, center }

/// Prova A: l'eroe a sinistra a tutta altezza, a destra nome, livello,
/// numeri e i due tasti; sotto tutte le abilità.
class _HomeTopSide extends StatelessWidget {
  const _HomeTopSide({required this.state, required this.xp});
  final GameState state;
  final (int, int) xp;

  @override
  Widget build(BuildContext context) {
    final c = state.character;
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            shape: const GildedBorder(ornate: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.75,
                          colors: [Color(0xFF3A2C16), Color(0x00000000)],
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, b) =>
                            Center(child: KnightView(character: c, height: b.maxHeight)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OneLine(c.name.toUpperCase(),
                            align: Alignment.centerLeft, style: titleStyle(size: 18, spacing: 2)),
                        _LevelLine(state: state, xp: xp),
                        const Spacer(),
                        _StatGrid(state: state),
                        const Spacer(),
                        _GearButton(
                            icon: Icons.shield, label: tr('ARMERIA'), onTap: () => openEquipment(context)),
                        const SizedBox(height: 8),
                        _GearButton(
                          icon: Icons.backpack,
                          label: tr('INVENTARIO'),
                          onTap: () => openInventory(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SkillGrid(progress: state.skillProgressOf),
      ],
    );
  }
}

/// Prova B: l'eroe al centro con i numeri ai lati, sotto nome e livello,
/// le abilità e i due tasti.
class _HomeTopCenter extends StatelessWidget {
  const _HomeTopCenter({required this.state, required this.xp});
  final GameState state;
  final (int, int) xp;

  @override
  Widget build(BuildContext context) {
    final c = state.character;
    final stats = _stats(state);
    Widget side(List<Widget> two) => SizedBox(
          width: 74,
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: two),
        );
    return Column(
      children: [
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            shape: const GildedBorder(ornate: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        side([stats[0], stats[1]]),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: RadialGradient(
                                radius: 0.7,
                                colors: [Color(0xFF3A2C16), Color(0x00000000)],
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, b) =>
                                  Center(child: KnightView(character: c, height: b.maxHeight)),
                            ),
                          ),
                        ),
                        side([stats[2], stats[3]]),
                      ],
                    ),
                  ),
                  OneLine(c.name.toUpperCase(),
                      align: Alignment.center, style: titleStyle(size: 18, spacing: 3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _LevelLine(state: state, xp: xp, center: true),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SkillGrid(progress: state.skillProgressOf),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GearButton(
                  icon: Icons.shield, label: tr('ARMERIA'), onTap: () => openEquipment(context)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GearButton(
                icon: Icons.backpack,
                label: tr('INVENTARIO'),
                onTap: () => openInventory(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Livello, arma e barra dell'esperienza.
class _LevelLine extends StatelessWidget {
  const _LevelLine({required this.state, required this.xp, this.center = false});
  final GameState state;
  final (int, int) xp;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = state.character;
    final (xpIn, xpNeed) = xp;
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('Liv. {n}', {'n': c.level}),
                style: titleStyle(size: 15, color: Palette.goldBright, spacing: 1)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                c.armed ? c.weapon.displayName : tr('A mani vuote'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Palette.ash, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        StatBar(value: xpIn / xpNeed, color: Palette.gold, height: 6),
        const SizedBox(height: 2),
        Text('$xpIn / $xpNeed XP', style: const TextStyle(color: Palette.ash, fontSize: 11)),
      ],
    );
  }
}

List<Widget> _stats(GameState s) => [
      _MiniStat(Icons.favorite, '${s.character.maxHp}', Palette.blood, tr('Vita')),
      _MiniStat(Icons.gavel, '${s.attackValue}', Palette.goldBright, tr('Attacco')),
      _MiniStat(Icons.shield_outlined, '${(s.defenseValue * 100).round()}%', Palette.frost, tr('Difesa')),
      _MiniStat(Icons.diamond_outlined, '${s.character.runes}', Palette.gold, tr('Rune')),
    ];

/// I quattro numeri in una griglia 2×2.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final st = _stats(state);
    return Column(
      children: [
        Row(children: [Expanded(child: st[0]), Expanded(child: st[1])]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: st[2]), Expanded(child: st[3])]),
      ],
    );
  }
}

/// Icona e numero; il nome sta nel suggerimento.
class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.color, this.label);
  final IconData icon;
  final String value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            FittedBox(child: Text(value, style: titleStyle(size: 17, color: Palette.holy, spacing: 0))),
            Text(label.toUpperCase(),
                style: const TextStyle(color: Palette.ash, fontSize: 9.5, letterSpacing: 1)),
          ],
        ),
      );
}

/// Tutte le abilità in due righe compatte: combattimento sopra, mestieri sotto.
class _SkillGrid extends StatelessWidget {
  const _SkillGrid({required this.progress});
  final (int, int, int) Function(Skill) progress;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Skill> skills) => Row(
          children: [
            for (final (i, k) in skills.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _SkillChip(skill: k, progress: progress(k))),
            ],
          ],
        );
    return Column(
      children: [
        row(Skill.combatSkills),
        const SizedBox(height: 6),
        row(Skill.crafts),
      ],
    );
  }
}

/// Icona, livello e barra: il nome e come sale sono dietro al tocco.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.progress});
  final Skill skill;
  final (int, int, int) progress;

  @override
  Widget build(BuildContext context) {
    final (lvl, xpIn, xpNeed) = progress;
    final color = skill.combat ? Palette.ember : Palette.gold;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showSkill(context, skill, progress),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(skillIcon(skill), color: color, size: 18),
                  const SizedBox(width: 4),
                  Text('$lvl', style: titleStyle(size: 16, color: Palette.holy, spacing: 0)),
                ],
              ),
              const SizedBox(height: 2),
              FittedBox(
                child: Text(skill.label, style: const TextStyle(color: Palette.ash, fontSize: 10.5)),
              ),
              const SizedBox(height: 3),
              StatBar(value: xpNeed == 0 ? 1 : xpIn / xpNeed, color: color, height: 3),
            ],
          ),
        ),
      ),
    );
  }
}
