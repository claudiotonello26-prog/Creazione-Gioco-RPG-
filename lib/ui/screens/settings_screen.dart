import 'package:flutter/material.dart';

import '../widgets/oath_bar.dart';

import 'package:provider/provider.dart';

import '../../core/sound.dart';
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
      appBar: const OathBar(title: Text('IMPOSTAZIONI'), tools: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: s.useCamera,
            onChanged: s.setUseCamera,
            title: const Text('Conta le rep con la fotocamera'),
            subtitle: const Text(
              'Spento: inserimento manuale, rep non verificate',
              style: TextStyle(color: Palette.ash),
            ),
          ),
          SwitchListTile(
            value: s.trainerEnabled,
            onChanged: s.setTrainerEnabled,
            title: const Text('Consigli di Ser Corvino'),
            subtitle: const Text(
              'Riaccendendolo, rivedi tutti i consigli dall\'inizio',
              style: TextStyle(color: Palette.ash),
            ),
          ),
          const _SoundSwitches(),
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
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OathChoice<Lang>(
                options: [for (final l in Lang.values) (l, l.label)],
                selected: s.lang,
                height: 38,
                onChanged: s.setLang,
              ),
            ),
          ),
          ListTile(
            title: const Text('Modalità di gioco'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OathChoice<PlayMode>(
                options: [for (final m in PlayMode.values) (m, m.label)],
                selected: s.mode,
                height: 38,
                onChanged: s.setMode,
              ),
            ),
          ),
          ActionTile(
            icon: Icons.emoji_events_outlined,
            title: 'Rifai il test',
            subtitle: 'Ricalcola la quest sui tuoi numeri di oggi',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FitnessTestScreen(isRetest: true))),
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

/// Effetti, musica e voce di Ser Corvino: si accendono e spengono a parte.
class _SoundSwitches extends StatefulWidget {
  const _SoundSwitches();

  @override
  State<_SoundSwitches> createState() => _SoundSwitchesState();
}

class _SoundSwitchesState extends State<_SoundSwitches> {
  @override
  Widget build(BuildContext context) {
    Widget sw(String title, bool value, Future<void> Function(bool) set) => SwitchListTile(
          value: value,
          title: Text(title),
          onChanged: (v) async {
            await set(v);
            if (mounted) setState(() {});
          },
        );
    return Column(
      children: [
        sw('Effetti sonori', Sound.sfxOn, Sound.setSfx),
        sw('Musica', Sound.musicOn, Sound.setMusic),
        sw('Voce di Ser Corvino', Sound.voiceOn, Sound.setVoice),
      ],
    );
  }
}
