import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../widgets/common.dart';
import '../widgets/knight_view.dart';
import '../widgets/oath_bar.dart';

/// Creazione del personaggio: si parte senza armatura, con il proprio viso e
/// i propri vestiti. L'armatura poi si forgia e copre tutto.
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  late final Appearance _look =
      Appearance.fromJson(context.read<GameState>().character.look.toJson());

  void _set(void Function() f) => setState(f);

  @override
  Widget build(BuildContext context) {
    final s = context.read<GameState>();
    // Copia: il painter confronta il look vecchio col nuovo per ridisegnare.
    final preview = Character(name: s.character.name, look: Appearance.fromJson(_look.toJson()));
    return Scaffold(
      appBar: const OathBar(title: Text('IL TUO CAVALIERE')),
      body: Column(
        children: [
          SizedBox(
            height: 230,
            child: Center(
              child: CustomPaint(
                size: const Size(184, 230),
                painter: KnightPainter.of(preview),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _Row(
                  label: 'Corpo',
                  child: OathChoice<bool>(
                    options: const [(false, 'Uomo'), (true, 'Donna')],
                    selected: _look.female,
                    height: 38,
                    onChanged: (v) => _set(() => _look.female = v),
                  ),
                ),
                _Row(
                  label: 'Viso',
                  child: OathChoice<int>(
                    options: [for (var i = 0; i < Appearance.faces; i++) (i, '${i + 1}')],
                    selected: _look.face,
                    height: 38,
                    onChanged: (i) => _set(() => _look.face = i),
                  ),
                ),
                _Swatches(
                  label: 'Pelle',
                  colors: Appearance.skinTones,
                  selected: _look.skin,
                  onPick: (i) => _set(() => _look.skin = i),
                ),
                _Swatches(
                  label: 'Capelli',
                  colors: Appearance.hairColors,
                  selected: _look.hair,
                  onPick: (i) => _set(() => _look.hair = i),
                ),
                _Swatches(
                  label: 'Occhi',
                  colors: Appearance.eyeColors,
                  selected: _look.eyes,
                  onPick: (i) => _set(() => _look.eyes = i),
                ),
                if (!_look.female) ...[
                  _Row(
                    label: 'Barba',
                    child: Switch(
                      value: _look.beard,
                      onChanged: (v) => _set(() => _look.beard = v),
                    ),
                  ),
                  if (_look.beard)
                    _Swatches(
                      label: 'Colore',
                      colors: Appearance.hairColors,
                      selected: _look.beardColor,
                      onPick: (i) => _set(() => _look.beardColor = i),
                    ),
                ],
                _Swatches(
                  label: 'Maglia',
                  colors: Appearance.clothColors,
                  selected: _look.shirt,
                  onPick: (i) => _set(() => _look.shirt = i),
                ),
                _Swatches(
                  label: 'Pantaloni',
                  colors: Appearance.clothColors,
                  selected: _look.pants,
                  onPick: (i) => _set(() => _look.pants = i),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    s.setLook(_look);
                    widget.onDone();
                  },
                  child: const Text('AVANTI'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            padding: const EdgeInsets.only(top: 8),
            child: OneLine(label.toUpperCase(), style: titleStyle(size: 12, spacing: 1.2)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches({
    required this.label,
    required this.colors,
    required this.selected,
    required this.onPick,
  });
  final String label;
  final List<int> colors;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return _Row(
      label: label,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (var i = 0; i < colors.length; i++)
            GestureDetector(
              onTap: () => onPick(i),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(colors[i]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == selected ? Palette.goldBright : Palette.iron,
                    width: i == selected ? 3 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Apre la creazione del personaggio dalle impostazioni (per cambiare aspetto).
void openCharacterCreation(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (ctx) => CharacterCreationScreen(onDone: () {
      Navigator.of(ctx).pop();
      toast(ctx, 'Aspetto aggiornato.');
    }),
  ));
}
