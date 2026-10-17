import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';
import 'walk_screen.dart';

/// Scheda del personaggio: chi sei, quanto vali, cosa porti e cosa hai in
/// bisaccia per la forgia.
class HeroTab extends StatelessWidget {
  const HeroTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final trained = s.trainedGroups.values.expand((g) => g).toSet();
    final (xpIn, xpNeed) = c.levelProgress;
    final materials = c.materials.entries
        .where((e) => e.value > 0 && !e.key.startsWith('amulet_'))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Palette.gold, width: 2),
                    gradient: const RadialGradient(
                      colors: [Color(0xFF2E2416), Palette.night],
                    ),
                    boxShadow: [
                      BoxShadow(color: Palette.gold.withValues(alpha: 0.25), blurRadius: 24),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset('assets/images/helm.png'),
                ),
                const SizedBox(height: 12),
                Text(c.name.toUpperCase(), style: titleStyle(size: 22, spacing: 4)),
                Text('Livello ${c.level} · ${c.weapon.displayName}',
                    style: const TextStyle(color: Palette.ash)),
                const SizedBox(height: 10),
                StatBar(value: xpIn / xpNeed, color: Palette.gold, label: '$xpIn / $xpNeed XP'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    InfoChip(Icons.diamond_outlined, '${c.runes} rune'),
                    InfoChip(Icons.local_fire_department, 'Streak ${s.streak}',
                        color: Palette.ember),
                    InfoChip(Icons.all_inclusive, 'Caccia: record ${s.bestHuntWave}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SectionTitle('Valori'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: [
            _Stat('Vita', '${c.maxHp}', Icons.favorite, Palette.blood),
            _Stat('Attacco', '${c.weapon.attackRating(c).round()}', Icons.gavel, Palette.goldBright),
            _Stat('Rampage', '${c.rampageGrace.toStringAsFixed(1)} s', Icons.bolt, Palette.ember),
            for (final a in Attribute.values)
              _Stat(a.label, '${c.attr(a)}', _attrIcon(a), Palette.gold),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Vita = 80 + Vigore × 6. Rampage = secondi di pausa prima che il bonus cali.',
          style: TextStyle(color: Palette.ash, fontSize: 12),
        ),
        const SectionTitle('Equipaggiamento'),
        ActionTile(
          icon: Icons.gavel,
          title: c.weapon.displayName,
          subtitle: '${c.weapon.def.style.label}'
              '${c.weapon.def.heavy ? ' · pesante' : ''} · '
              '${c.weapon.def.scaling.entries.map((e) => '${e.key.label} ${e.value.label}').join(', ')}',
        ),
        for (final id in c.amulets)
          ActionTile(
            icon: Icons.brightness_7_outlined,
            title: amuletDefs[id]?.name ?? id,
            subtitle: amuletDefs[id]?.description,
          ),
        if (c.amulets.isEmpty)
          const Text('Nessun amuleto indossato: si comprano alla Forgia.',
              style: TextStyle(color: Palette.ash)),
        SectionTitle('Bisaccia della forgia',
            trailing: Text('${c.weapons.length + 1} armi',
                style: const TextStyle(color: Palette.ash))),
        if (materials.isEmpty)
          const Text('Vuota. Sconfiggi mostri e cammina per raccogliere materiali.',
              style: TextStyle(color: Palette.ash))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in materials)
                InfoChip(_materialIcon(m.key), '${m.value}× ${materialNames[m.key] ?? m.key}'),
            ],
          ),
        const SizedBox(height: 8),
        ActionTile(
          icon: Icons.directions_walk,
          title: 'Camminata',
          subtitle: 'I passi di oggi diventano minerale, legno e pietre',
          color: Palette.goldBright,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const WalkScreen())),
        ),
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
        const SectionTitle('Altro'),
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

  static IconData _attrIcon(Attribute a) => switch (a) {
        Attribute.vigor => Icons.favorite_border,
        Attribute.endurance => Icons.timer_outlined,
        Attribute.strength => Icons.fitness_center,
        Attribute.dexterity => Icons.flash_on,
        Attribute.faith => Icons.wb_sunny_outlined,
        Attribute.intelligence => Icons.auto_awesome,
      };

  static IconData _materialIcon(String id) => switch (id) {
        'iron_ore' => Icons.landscape_outlined,
        'ash_wood' => Icons.forest_outlined,
        'beast_essence' => Icons.water_drop_outlined,
        'holy_shard' => Icons.flare,
        _ => Icons.hexagon_outlined,
      };
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            Text(value, style: titleStyle(size: 18, color: Palette.holy, spacing: 0)),
            FittedBox(
              child: Text(label.toUpperCase(),
                  style: const TextStyle(color: Palette.ash, fontSize: 11, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}
