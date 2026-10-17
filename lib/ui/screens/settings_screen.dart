import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/i18n.dart';
import '../../data/game_state.dart';
import '../../online/nakama_client.dart';
import '../widgets/common.dart';
import 'onboarding.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('IMPOSTAZIONI')),
      body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          value: s.useCamera,
          onChanged: s.setUseCamera,
          title: const Text('Conta le rep con la fotocamera'),
          subtitle: const Text('Spento: inserimento manuale, rep non verificate',
              style: TextStyle(color: Palette.ash)),
        ),
        SwitchListTile(
          value: s.trainerEnabled,
          onChanged: s.setTrainerEnabled,
          title: const Text('Consigli di Ser Corvino'),
          subtitle: const Text('Riaccendendolo, rivedi tutti i consigli dall\'inizio',
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
          title: const Text('Lingua / Language'),
          trailing: SegmentedButton<Lang>(
            segments: [
              for (final l in Lang.values) ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {s.lang},
            onSelectionChanged: (v) => s.setLang(v.first),
          ),
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
      ),
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
