import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';
import '../../core/i18n.dart';

import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/exercise.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Perk, equilibrio dei gruppi e record. I punti si spendono in Home.
class AttributesScreen extends StatelessWidget {
  const AttributesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final trained = s.trainedGroups.values.expand((g) => g).toSet();
    return Scaffold(
      appBar: OathBar(title: Text(tr('PERK E RECORD'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in Attribute.values)
            ListTile(
              dense: true,
              leading: Icon(_icon(a), color: Palette.gold),
              title: OneLine('${a.label} ${c.attr(a)}'),
              subtitle: Text(_effect(a, c), style: const TextStyle(color: Palette.ash)),
            ),
          if (c.unlockedPerkChoices.isNotEmpty) ...[
            SectionTitle(tr('Perk')),
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
                          title: OneLine(p.name),
                          subtitle: Text(p.description, style: const TextStyle(color: Palette.ash)),
                        ),
                    ],
                  ),
                ),
              ),
            Text(
              tr('La scelta è definitiva: si cambia solo con un oggetto di Rinascita.'),
              style: const TextStyle(color: Palette.ash, fontSize: 12),
            ),
          ],
          SectionTitle(tr('Il tuo corpo')),
          Text(tr('Gruppi allenati negli ultimi 7 giorni'), style: const TextStyle(color: Palette.ash)),
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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                tr('Squilibrio: alcuni gruppi sono trascurati. Il Bonus Varietà li premia.'),
                style: const TextStyle(color: Palette.ember),
              ),
            ),
          SectionTitle(tr('Record reali')),
          for (final id in [...baseExercises, ExerciseId.plank])
            ListTile(
              dense: true,
              title: OneLine(exercises[id]!.name),
              subtitle: Text(
                tr('Divisione {division}', {'division': s.divisionOf(id).label}),
                style: const TextStyle(color: Palette.ash),
              ),
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
            title: tr('Impostazioni'),
            subtitle: tr('Fotocamera, modalità, server dell\'Arena, nuovo test'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
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
        Attribute.vigor => tr('Vita {hp} · resisti di più ai colpi', {'hp': c.maxHp}),
        Attribute.endurance => tr('Il Rampage regge {s} s di pausa', {'s': c.rampageGrace.toStringAsFixed(1)}),
        _ => a.description,
      };
}
