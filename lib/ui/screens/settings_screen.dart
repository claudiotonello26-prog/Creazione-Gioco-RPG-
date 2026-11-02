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
      appBar: OathBar(title: Text(tr('IMPOSTAZIONI')), tools: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: s.useCamera,
            onChanged: s.setUseCamera,
            title: Text(tr('Conta le rep con la fotocamera')),
            subtitle: Text(
              tr('Spento: inserimento manuale, rep non verificate'),
              style: const TextStyle(color: Palette.ash),
            ),
          ),
          SwitchListTile(
            value: s.trainerEnabled,
            onChanged: s.setTrainerEnabled,
            title: Text(tr('Consigli del Comandante Reynard')),
            subtitle: Text(
              tr('Riaccendendolo, rivedi tutti i consigli dall\'inizio'),
              style: const TextStyle(color: Palette.ash),
            ),
          ),
          const _SoundSwitches(),
          ListTile(
            title: Text(tr('Server dell\'Arena live')),
            subtitle: Text(
              s.serverAddress.isEmpty ? tr('Non impostato') : s.serverAddress,
              style: const TextStyle(color: Palette.ash),
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => _editServer(context, s),
          ),
          ListTile(
            title: Text(tr('Lingua')),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OathChoice<LangPref>(
                    options: [for (final l in LangPref.values) (l, l.label)],
                    selected: s.langPref,
                    height: 38,
                    onChanged: s.setLangPref,
                  ),
                  if (s.langPref == LangPref.auto)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        tr('Segue la lingua del telefono'),
                        style: const TextStyle(color: Palette.ash),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text(tr('Modalità di gioco')),
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
            title: tr('Rifai il test'),
            subtitle: tr('Ricalcola la quest sui tuoi numeri di oggi'),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const FitnessTestScreen(isRetest: true))),
          ),
          ActionTile(
            icon: Icons.delete_forever_outlined,
            title: tr('Ricomincia da capo'),
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
        title: Text(tr('Server dell\'Arena')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: tr('es. arena.iron-oath.it oppure 192.168.1.10:7350'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Annulla'))),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty &&
                  ServerConfig.parse(controller.text) == null) {
                return;
              }
              s.setServerAddress(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(tr('Salva')),
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
        title: Text(tr('Ricominciare?')),
        content: Text(tr('Perderai eroe, progressi e record salvati su questo telefono.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Annulla'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Palette.blood),
            onPressed: () {
              Navigator.pop(ctx);
              s.resetAll();
            },
            child: Text(tr('Ricomincia')),
          ),
        ],
      ),
    );
  }
}

/// Effetti, musica e voce del Comandante Reynard: si accendono e spengono a parte.
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
        sw(tr('Effetti sonori'), Sound.sfxOn, Sound.setSfx),
        sw(tr('Musica'), Sound.musicOn, Sound.setMusic),
        sw(tr('Voce del Comandante Reynard'), Sound.voiceOn, Sound.setVoice),
      ],
    );
  }
}
