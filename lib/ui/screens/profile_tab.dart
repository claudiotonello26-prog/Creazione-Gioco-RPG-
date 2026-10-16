import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/exercise.dart';
import '../../online/nakama_client.dart';
import '../widgets/common.dart';
import 'onboarding.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final trained = s.trainedGroups.values.expand((g) => g).toSet();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Mappa del corpo (7 giorni)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in MuscleGroup.values)
              InfoChip(
                trained.contains(g) ? Icons.check_circle : Icons.circle_outlined,
                g.label,
                color: trained.contains(g) ? Palette.goldBright : Palette.blood,
              ),
          ],
        ),
        if (trained.isNotEmpty && trained.length < 4)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Squilibrio: alcuni gruppi sono trascurati. Il Bonus Varietà li premia.',
              style: TextStyle(color: Palette.ember),
            ),
          ),
        const SectionTitle('Record reali'),
        for (final id in [...baseExercises, ExerciseId.plank])
          ListTile(
            dense: true,
            title: Text(exercises[id]!.name),
            subtitle: Text('Divisione ${s.divisionOf(id).label}',
                style: const TextStyle(color: Palette.ash)),
            trailing: Text(
              s.records[id] == null
                  ? '—'
                  : '${s.records[id]}${id == ExerciseId.plank ? ' s' : ''}',
              style: const TextStyle(color: Palette.goldBright, fontSize: 16),
            ),
          ),
        SectionTitle('Attributi',
            trailing: Text('${c.availablePoints} punti',
                style: const TextStyle(color: Palette.goldBright))),
        Text('Punti Disciplina guadagnati: ${c.disciplinePoints} (solo stretching e mobilità)',
            style: const TextStyle(color: Palette.ash, fontSize: 13)),
        for (final a in Attribute.values)
          Card(
            child: ListTile(
              title: Text('${a.label}  ${c.attr(a)}'),
              subtitle: Text(a.description, style: const TextStyle(color: Palette.ash)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Palette.gold),
                onPressed: c.availablePoints > 0 ? () => s.raiseAttribute(a) : null,
              ),
            ),
          ),
        if (c.unlockedPerkChoices.isNotEmpty) ...[
          const SectionTitle('Perk'),
          for (final choice in c.unlockedPerkChoices)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (final p in choice.options)
                      ListTile(
                        leading: Icon(
                          c.perks.contains(p.id)
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: Palette.gold,
                        ),
                        onTap: choice.options.any(c.perks.contains)
                            ? null
                            : () => s.choosePerk(choice, p),
                        title: Text(p.name),
                        subtitle: Text(p.description, style: const TextStyle(color: Palette.ash)),
                      ),
                  ],
                ),
              ),
            ),
          const Text(
            'La scelta è definitiva: si cambia solo con un oggetto di Rinascita.',
            style: TextStyle(color: Palette.ash, fontSize: 12),
          ),
        ],
        const SectionTitle('Impostazioni'),
        SwitchListTile(
          value: s.useCamera,
          onChanged: s.setUseCamera,
          title: const Text('Conta le rep con la fotocamera'),
          subtitle: const Text('Spento: inserimento manuale, rep non verificate',
              style: TextStyle(color: Palette.ash)),
        ),
        ListTile(
          title: const Text('Server dell\'Arena live'),
          subtitle: Text(
            s.serverAddress.isEmpty ? 'Non impostato' : s.serverAddress,
            style: const TextStyle(color: Palette.ash),
          ),
          trailing: const Icon(Icons.edit),
          onTap: () => _editServer(context, s),
        ),
        ListTile(
          title: const Text('Modalità di gioco'),
          trailing: SegmentedButton<PlayMode>(
            segments: [
              for (final m in PlayMode.values) ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {s.mode},
            onSelectionChanged: (v) => s.setMode(v.first),
          ),
        ),
        ActionTile(
          icon: Icons.emoji_events_outlined,
          title: 'Rifai il test',
          subtitle: 'Ricalcola la quest sui tuoi numeri di oggi',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FitnessTestScreen(isRetest: true))),
        ),
        ActionTile(
          icon: Icons.delete_forever_outlined,
          title: 'Ricomincia da capo',
          color: Palette.blood,
          onTap: () => _confirmReset(context, s),
        ),
      ],
    );
  }

  void _editServer(BuildContext context, GameState s) {
    final controller = TextEditingController(text: s.serverAddress);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: const Text('Server dell\'Arena'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'es. arena.iron-oath.it oppure 192.168.1.10:7350',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  ServerConfig.parse(controller.text) == null) {
                return;
              }
              s.setServerAddress(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, GameState s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.stone,
        title: const Text('Ricominciare?'),
        content: const Text('Perderai eroe, progressi e record salvati su questo telefono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Palette.blood),
            onPressed: () {
              Navigator.pop(ctx);
              s.resetAll();
            },
            child: const Text('Ricomincia'),
          ),
        ],
      ),
    );
  }
}
