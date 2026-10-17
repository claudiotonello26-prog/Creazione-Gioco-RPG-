import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/exercise.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Ultima scheda: dove si spendono i punti negli attributi.
class AttributesTab extends StatelessWidget {
  const AttributesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final trained = s.trainedGroups.values.expand((g) => g).toSet();
    final points = c.availablePoints;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: points > 0 ? Palette.goldBright : Palette.stoneLight,
                    border: Border.all(color: Palette.gold),
                  ),
                  alignment: Alignment.center,
                  child: Text('$points',
                      style: titleStyle(size: 26, color: points > 0 ? Palette.night : Palette.ash)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    points > 0
                        ? 'Punti da spendere: tocca + sull\'attributo che vuoi far crescere.'
                        : 'Nessun punto libero. Ne guadagni uno a ogni livello e con '
                            'stretching e mobilità (Punti Disciplina: ${c.disciplinePoints}).',
                    style: TextStyle(color: points > 0 ? Palette.goldBright : Palette.ash),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final a in Attribute.values)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Icon(_icon(a), color: Palette.gold, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.label.toUpperCase(), style: titleStyle(size: 15)),
                        Text(_effect(a, c), style: const TextStyle(color: Palette.ash, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('${c.attr(a)}', style: titleStyle(size: 26, color: Palette.holy, spacing: 0)),
                  IconButton(
                    iconSize: 34,
                    icon: Icon(Icons.add_circle,
                        color: points > 0 ? Palette.goldBright : Palette.iron),
                    onPressed: points > 0 ? () => s.raiseAttribute(a) : null,
                  ),
                ],
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
        const SectionTitle('Il tuo corpo'),
        const Text('Gruppi allenati negli ultimi 7 giorni', style: TextStyle(color: Palette.ash)),
        const SizedBox(height: 6),
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
        const SizedBox(height: 8),
        ActionTile(
          icon: Icons.settings_outlined,
          title: 'Impostazioni',
          subtitle: 'Fotocamera, modalità, server dell\'Arena, nuovo test',
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  static IconData _icon(Attribute a) => switch (a) {
        Attribute.vigor => Icons.favorite_border,
        Attribute.endurance => Icons.timer_outlined,
        Attribute.strength => Icons.fitness_center,
        Attribute.dexterity => Icons.air,
        Attribute.faith => Icons.wb_sunny_outlined,
        Attribute.intelligence => Icons.auto_awesome,
      };

  static String _effect(Attribute a, Character c) => switch (a) {
        Attribute.vigor => 'Vita ${c.maxHp} · resisti di più ai colpi',
        Attribute.endurance =>
          'Il Rampage regge ${c.rampageGrace.toStringAsFixed(1)} s di pausa',
        _ => a.description,
      };
}
