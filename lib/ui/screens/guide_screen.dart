import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/enemies.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/oath_bar.dart';
import 'home_tab.dart' show skillIcon;

/// Un passo della progressione: a quel livello si sblocca qualcosa.
typedef Unlock = (int level, String text, String? itemId);

/// Il libro del cavaliere: abilità per abilità, cosa si sblocca e a che livello.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: const OathBar(title: Text('GUIDA'), tools: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '"Ogni abilità è una strada. Qui c\'è scritto dove porta." '
              'Tocca un\'abilità per vedere cosa sblocca, livello per livello.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.ash, fontStyle: FontStyle.italic),
            ),
          ),
          for (final k in Skill.values)
            _SkillChapter(
              skill: k,
              level: s.skillLevel(k),
              unlocks: guideFor(k),
              intro: _intro[k]!,
            ),
        ],
      ),
    );
  }

  static const Map<Skill, String> _intro = {
    Skill.woodcutting: 'Spendi i passi nei boschi della Raccolta. Ogni albero nuovo chiede '
        'un livello e spesso un\'ascia migliore.',
    Skill.mining: 'Spendi i passi nelle cave. Prima pietra e carbone, poi ferro, argento '
        'lunare e minerale stellare.',
    Skill.carpentry: 'Alla Carpenteria il legno diventa assi, impugnature, archi, bastoni e scudi.',
    Skill.smelting: 'Alla Fornace il minerale diventa lingotti e pietre di forgia.',
    Skill.smithing: 'All\'Incudine nascono spade, martelli, armature e attrezzi di metallo.',
    Skill.attack: 'Cresce colpendo con armi da mischia e a distanza. +2% di danno per livello, '
        'e le armi migliori chiedono un livello minimo per essere impugnate.',
    Skill.defense: 'Cresce incassando colpi e tenendo le posizioni. +0,5% di colpi assorbiti per '
        'livello (fino al 30%), e le armature pesanti chiedono un livello minimo.',
    Skill.magic: 'Cresce combattendo con un bastone. Decide quali bastoni puoi impugnare.',
    Skill.expeditions: 'Cresce completando le spedizioni e abbattendo i loro boss. Indica il '
        'livello consigliato per ogni mappa.',
  };
}

/// Tutto ciò che si sblocca per un'abilità, in ordine di livello.
List<Unlock> guideFor(Skill k) {
  final out = <Unlock>[];
  switch (k) {
    case Skill.woodcutting || Skill.mining:
      for (final r in resources.where((r) => r.skill == k)) {
        out.add((
          r.level,
          '${r.name} · ${r.where}${r.tool != null ? ' · serve ${materialNames[r.tool]}' : ''}',
          r.id,
        ));
      }
    case Skill.carpentry || Skill.smelting || Skill.smithing:
      bool mine(Station st) => Skill.forStation(st) == k && st != Station.enchant;
      for (final r in materialRecipes.where((r) => mine(r.station))) {
        out.add((
          r.level,
          '${materialNames[r.output] ?? r.output}${r.tool ? ' (attrezzo)' : ''}',
          r.output,
        ));
      }
      for (final w in weaponDefs.values.where(
        (w) => !w.rare && w.recipe.isNotEmpty && mine(w.station),
      )) {
        out.add((w.craftLevel, '${w.name} · ${w.style.label.toLowerCase()}', w.id));
      }
      if (k == Skill.smithing) {
        for (final a in armorDefs.values) {
          out.add((a.craftLevel, '${a.name} · armatura', a.id));
        }
      }
      for (final o in offhandDefs.values.where((o) => mine(o.station))) {
        out.add((o.craftLevel, '${o.name} · ${o.isShield ? 'scudo' : 'seconda lama'}', o.id));
      }
    case Skill.attack || Skill.magic:
      final magic = k == Skill.magic;
      for (final w in weaponDefs.values.where((w) => w.usesMagic == magic)) {
        out.add((
          w.wieldLevel,
          'Impugni ${w.name}${w.rare ? ' (rara, dai boss)' : ''} · danno ${w.baseDamage}',
          w.id,
        ));
      }
      if (!magic) {
        for (final l in [10, 20, 30, 50, 99]) {
          out.add((l, '+${2 * (l - 1)}% di danno con ogni arma', null));
        }
      }
    case Skill.defense:
      for (final a in armorDefs.values) {
        out.add((a.wearLevel, 'Indossi ${a.name} · assorbe ${(a.reduction * 100).round()}%', a.id));
      }
      for (final l in [11, 21, 41, 61]) {
        out.add((l, '+${((l - 1) * 0.5).toStringAsFixed(0)}% di colpi assorbiti', null));
      }
    case Skill.expeditions:
      for (final e in expeditions) {
        out.add((e.level, '${e.roman} · ${e.name} · ${e.group.label}', null));
      }
  }
  out.sort((a, b) => a.$1.compareTo(b.$1));
  return out;
}

class _SkillChapter extends StatelessWidget {
  const _SkillChapter({
    required this.skill,
    required this.level,
    required this.unlocks,
    required this.intro,
  });
  final Skill skill;
  final int level;
  final List<Unlock> unlocks;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final next = unlocks.where((u) => u.$1 > level).firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(skillIcon(skill), color: Palette.goldBright),
          iconColor: Palette.goldBright,
          collapsedIconColor: Palette.gold,
          title: Text(skill.label.toUpperCase(), style: titleStyle(size: 14, spacing: 1.5)),
          subtitle: Text(
            'Livello $level${next != null ? ' · prossimo sblocco al ${next.$1}' : ''}',
            style: const TextStyle(color: Palette.ash, fontSize: 12.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            Text(intro, style: const TextStyle(color: Palette.ash, fontSize: 13.5)),
            const SizedBox(height: 8),
            for (final u in unlocks) _UnlockRow(unlock: u, reached: level >= u.$1),
          ],
        ),
      ),
    );
  }
}

class _UnlockRow extends StatelessWidget {
  const _UnlockRow({required this.unlock, required this.reached});
  final Unlock unlock;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final (lvl, text, id) = unlock;
    final color = reached ? Palette.goldBright : Palette.ash;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(4),
              color: reached ? Palette.gold.withValues(alpha: 0.15) : null,
            ),
            child: Text('$lvl', style: titleStyle(size: 12, color: color, spacing: 0)),
          ),
          const SizedBox(width: 10),
          if (id != null) ...[ItemIcon(id, size: 22), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: reached ? Palette.holy : Palette.ash, fontSize: 13.5),
            ),
          ),
          Icon(reached ? Icons.check : Icons.lock_outline, size: 16, color: color),
        ],
      ),
    );
  }
}
