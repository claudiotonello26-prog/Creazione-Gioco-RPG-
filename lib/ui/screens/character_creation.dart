import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
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
  late final Appearance _look = Appearance.fromJson(
    context.read<GameState>().character.look.toJson(),
  );

  void _set(void Function() f) => setState(f);

  @override
  Widget build(BuildContext context) {
    final s = context.read<GameState>();
    // Copia: il painter confronta il look vecchio col nuovo per ridisegnare.
    final look = Appearance.fromJson(_look.toJson());
    final preview = Character(name: s.character.name, look: look);
    final drawn = HeroView.available;
    return Scaffold(
      appBar: OathBar(title: Text(tr('IL TUO CAVALIERE'))),
      body: Column(
        children: [
          SizedBox(
            height: drawn ? 300 : 230,
            child: Center(
              child: drawn
                  ? HeroView(look: look, height: 292)
                  : CustomPaint(size: const Size(184, 230), painter: KnightPainter.of(preview)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _Row(
                  label: tr('Corpo'),
                  child: OathChoice<bool>(
                    options: [(false, tr('Uomo')), (true, tr('Donna'))],
                    selected: _look.female,
                    height: 38,
                    onChanged: (v) => _set(() => _look.female = v),
                  ),
                ),
                if (drawn) ...[
                  _Styles(look: _look, onPick: (i) => _set(() => _look.style = i)),
                  _Swatches(
                    label: tr('Capelli'),
                    colors: Appearance.hairColors,
                    natural: Appearance.naturalHair,
                    selected: _look.hair,
                    onPick: (i) => _set(() => _look.hair = i),
                  ),
                  _Swatches(
                    label: tr('Occhi'),
                    colors: Appearance.eyeColors,
                    natural: Appearance.naturalEyes,
                    selected: _look.eyes,
                    onPick: (i) => _set(() => _look.eyes = i),
                  ),
                ] else ...[
                  _Row(
                    label: tr('Viso'),
                    child: OathChoice<int>(
                      options: [for (var i = 0; i < Appearance.faces; i++) (i, '${i + 1}')],
                      selected: _look.face,
                      height: 38,
                      onChanged: (i) => _set(() => _look.face = i),
                    ),
                  ),
                  _Swatches(
                    label: tr('Pelle'),
                    colors: Appearance.skinTones,
                    selected: _look.skin,
                    onPick: (i) => _set(() => _look.skin = i),
                  ),
                  _Swatches(
                    label: tr('Capelli'),
                    colors: Appearance.hairColors,
                    natural: Appearance.naturalHair,
                    selected: _look.hair,
                    onPick: (i) => _set(() => _look.hair = i),
                  ),
                  _Swatches(
                    label: tr('Occhi'),
                    colors: Appearance.eyeColors,
                    natural: Appearance.naturalEyes,
                    selected: _look.eyes,
                    onPick: (i) => _set(() => _look.eyes = i),
                  ),
                  if (!_look.female) ...[
                    _Row(
                      label: tr('Barba'),
                      child: Switch(
                        value: _look.beard,
                        onChanged: (v) => _set(() => _look.beard = v),
                      ),
                    ),
                    if (_look.beard)
                      _Swatches(
                        label: tr('Colore'),
                        colors: Appearance.hairColors,
                        selected: _look.beardColor,
                        onPick: (i) => _set(() => _look.beardColor = i),
                      ),
                  ],
                ],
                _Swatches(
                  label: tr('Maglia'),
                  colors: Appearance.clothColors,
                  natural: Appearance.naturalShirt,
                  selected: _look.shirt,
                  onPick: (i) => _set(() => _look.shirt = i),
                ),
                _Swatches(
                  label: tr('Pantaloni'),
                  colors: Appearance.clothColors,
                  natural: Appearance.naturalPants,
                  selected: _look.pants,
                  onPick: (i) => _set(() => _look.pants = i),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    s.setLook(_look);
                    widget.onDone();
                  },
                  child: Text(tr('AVANTI')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le teste disegnate: viso, capelli e barba, una miniatura per ciascuna.
class _Styles extends StatelessWidget {
  const _Styles({required this.look, required this.onPick});
  final Appearance look;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final names = look.styleNames;
    final dir = HeroView.dir(look.female);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OneLine(tr('ASPETTO'), style: titleStyle(size: 12, spacing: 1.2)),
              const SizedBox(width: 10),
              Expanded(
                child: OneLine(
                  tr(names[look.styleIndex]),
                  style: const TextStyle(color: Palette.ash, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: names.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final on = i == look.styleIndex;
                return GestureDetector(
                  onTap: () => onPick(i),
                  child: Container(
                    width: 72,
                    decoration: BoxDecoration(
                      color: Palette.stoneLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: on ? Palette.goldBright : Palette.iron,
                        width: on ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      '$dir/thumb_$i.png',
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                );
              },
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
    this.natural,
  });
  final String label;
  final List<int> colors;
  final int selected;
  final ValueChanged<int> onPick;

  /// Colore originale dell'illustrazione: primo cerchio, indice -1.
  final int? natural;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i, int color, {bool original = false}) => GestureDetector(
      onTap: () => onPick(i),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: i == selected ? Palette.goldBright : Palette.iron,
            width: i == selected ? 3 : 1,
          ),
        ),
        child: original ? const Icon(Icons.auto_awesome, size: 14, color: Palette.holy) : null,
      ),
    );
    return _Row(
      label: label,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (natural != null) dot(Appearance.natural, natural!, original: true),
          for (var i = 0; i < colors.length; i++) dot(i, colors[i]),
        ],
      ),
    );
  }
}

/// Apre la creazione del personaggio dalle impostazioni (per cambiare aspetto).
void openCharacterCreation(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => CharacterCreationScreen(
        onDone: () {
          Navigator.of(ctx).pop();
          toast(ctx, tr('Aspetto aggiornato.'));
        },
      ),
    ),
  );
}
