import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/sound.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/contracts.dart';
import '../../domain/enemies.dart';
import '../../domain/items.dart';
import '../../domain/skills.dart';
import '../widgets/common.dart';
import '../widgets/oath_bar.dart';
import 'codex_screen.dart';
import 'expedition_map.dart';

void openContracts(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContractsScreen()));

/// La Bacheca delle Taglie: un contratto alla volta, sigillato finché non lo
/// firmi. Si finisce portando a termine le spedizioni che chiede.
class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final skill = s.skillLevel(Skill.expeditions);
    final active = s.contract;
    return Scaffold(
      appBar: OathBar(title: Text(tr('BACHECA DELLE TAGLIE')), accent: Sections.training),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(
              'Firma un contratto sigillato: solo dopo scopri quali spedizioni finire. '
              'Portale a termine fino al boss e torna qui a riscuotere il forziere.',
            ),
            style: const TextStyle(color: Palette.ash),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Abilità Spedizioni: livello {n}', {'n': skill}),
            style: const TextStyle(color: Palette.goldBright, fontWeight: FontWeight.bold),
          ),
          if (active != null) ...[
            SectionTitle(tr('Contratto in corso')),
            _ActiveContract(contract: active),
          ],
          SectionTitle(tr('Committenti')),
          for (final c in contractors) _ContractorCard(contractor: c, skill: skill),
        ],
      ),
    );
  }
}

class _ActiveContract extends StatelessWidget {
  const _ActiveContract({required this.contract});
  final HuntContract contract;

  Future<void> _deliver(BuildContext context) async {
    final s = context.read<GameState>();
    final title = contract.contractor.chestName;
    final items = s.deliverContract();
    if (items.isEmpty) return;
    Sound.play(Sfx.chestOpen);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChestDialog(title: title, items: items),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final s = context.read<GameState>();
    final free = s.freeCancelToday;
    final cost = cancelCost(contract.contractor);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Text(tr('Strappare il contratto?')),
        content: Text(
          free
              ? tr('Il primo annullamento di oggi è gratis.')
              : tr('Oggi hai già annullato: questo costa {n} rune.', {'n': cost}),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Tienilo'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('STRAPPA'))),
        ],
      ),
    );
    if (ok == true && !s.cancelContract() && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('Non hai abbastanza rune.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final who = contract.contractor;
    final done = contract.targets.where(contract.done.contains).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.history_edu, color: Palette.goldBright, size: 30),
                const SizedBox(width: 8),
                Expanded(child: OneLine(who.name, style: titleStyle(size: 16))),
                Text(
                  '$done / ${contract.targets.length}',
                  style: titleStyle(size: 16, color: Palette.holy, spacing: 0),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final id in contract.targets)
              _TargetTile(expedition: expeditionById(id), done: contract.done.contains(id)),
            const SizedBox(height: 8),
            if (contract.complete)
              FilledButton.icon(
                onPressed: () => _deliver(context),
                icon: const Icon(Icons.inventory_2),
                label: Text(tr('CONSEGNA E APRI IL FORZIERE')),
              )
            else
              Text(
                tr(
                  'Porta a termine ogni spedizione fino al boss: vale anche se l\'hai già finita altre volte.',
                ),
                style: const TextStyle(color: Palette.ash, fontSize: 13),
              ),
            TextButton(onPressed: () => _cancel(context), child: Text(tr('Strappa il contratto'))),
          ],
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({required this.expedition, required this.done});
  final Expedition expedition;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    return Card(
      color: Palette.stoneLight,
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.map_outlined,
          color: done ? Palette.goldBright : Palette.gold,
          size: 30,
        ),
        title: OneLine('${e.roman} · ${e.name}'),
        subtitle: Text(
          '${e.group.label} · LV ${e.level} · ${tr('Boss: {name}', {'name': e.boss.name})}',
          style: const TextStyle(color: Palette.ash, fontSize: 13),
        ),
        trailing: done ? null : const Icon(Icons.chevron_right, color: Palette.gold),
        onTap: done
            ? null
            : () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ExpeditionMapScreen(expedition: e))),
      ),
    );
  }
}

class _ContractorCard extends StatelessWidget {
  const _ContractorCard({required this.contractor, required this.skill});
  final Contractor contractor;
  final int skill;

  Future<void> _sign(BuildContext context) async {
    final s = context.read<GameState>();
    final c = s.signContract(contractor);
    if (c == null) return;
    Sound.play(Sfx.confirm);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: Column(
          children: [
            const Icon(Icons.history_edu, color: Palette.goldBright, size: 44),
            const SizedBox(height: 6),
            Text(
              tr('IL SIGILLO SI SPEZZA'),
              textAlign: TextAlign.center,
              style: titleStyle(size: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.targets.length == 1
                  ? tr('{who} ti chiede una spedizione:', {'who': contractor.name})
                  : tr('{who} ti chiede {n} spedizioni:', {
                      'who': contractor.name,
                      'n': c.targets.length,
                    }),
            ),
            const SizedBox(height: 8),
            for (final id in c.targets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '• ${expeditionById(id).roman} · ${expeditionById(id).name} '
                  '(${expeditionById(id).group.label})',
                  style: const TextStyle(color: Palette.holy, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('IN MARCIA')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = contractor;
    final locked = skill < c.minSkill;
    final oath = s.build;
    final rares = [
      for (final (id, _) in c.rares)
        id == buildRareWeapon
            ? rareWeaponFor(oath)
            : amuletDefs.containsKey(id)
            ? 'amulet_$id'
            : forBuild(id, oath),
    ];
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_outline : Icons.person_pin,
                    color: locked ? Palette.iron : Palette.goldBright,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: OneLine(c.name, style: titleStyle(size: 16))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                c.blurb,
                style: const TextStyle(color: Palette.ash, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),
              Text(
                c.expeditions == 1
                    ? tr('Chiede 1 spedizione · {chest} · {runes} rune', {
                        'chest': c.chestName,
                        'runes': c.runes,
                      })
                    : tr('Chiede {n} spedizioni · {chest} · {runes} rune', {
                        'n': c.expeditions,
                        'chest': c.chestName,
                        'runes': c.runes,
                      }),
                style: const TextStyle(color: Palette.holy, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final id in lootForBuild(c.guaranteed, oath).keys)
                    CodexTap(
                      id,
                      child: Tooltip(message: itemName(id), child: ItemIcon(id, size: 30)),
                    ),
                  const Icon(Icons.star, color: Color(0xFFC58BEA), size: 18),
                  for (final id in rares)
                    CodexTap(
                      id,
                      child: Tooltip(
                        message: tr('Raro: {name}', {'name': itemName(id)}),
                        child: weaponDefs.containsKey(id)
                            ? const Icon(Icons.hardware, color: Color(0xFFC58BEA), size: 28)
                            : ItemIcon(id, size: 30),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (locked)
                Text(
                  tr('Si sblocca a Spedizioni livello {n}', {'n': c.minSkill}),
                  style: const TextStyle(color: Palette.ember),
                )
              else
                FilledButton(
                  onPressed: s.canSign(c) ? () => _sign(context) : null,
                  child: Text(
                    s.contract == null ? tr('FIRMA IL CONTRATTO') : tr('HAI GIÀ UN CONTRATTO'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
