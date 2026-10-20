import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/game_state.dart';
import '../../domain/character.dart';
import '../../domain/codex.dart';
import '../../domain/exercise.dart';
import '../../domain/items.dart';
import '../widgets/common.dart';
import '../widgets/oath_bar.dart';
import 'train_tab.dart' show startFreeFight;

/// Apre il Codice del Giuramento: sulla pagina di [id] se c'è, altrimenti
/// sull'indice.
void openCodex(BuildContext context, [String? id]) {
  final entry = id == null ? null : codexEntry(id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => entry == null ? const CodexScreen() : CodexEntryScreen(entry),
    ),
  );
}

/// Avvolge un'icona di oggetto: toccandola si apre la sua pagina del Codice.
class CodexTap extends StatelessWidget {
  const CodexTap(this.id, {super.key, required this.child});
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (codexEntry(id) == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openCodex(context, id),
      child: child,
    );
  }
}

/// Quanti ne hai di un oggetto, qualunque sia il tipo.
int codexOwned(Character c, CodexEntry e) => switch (e.kind) {
  CodexKind.weapon => [c.weapon, ...c.weapons].where((w) => w.weaponId == e.id).length,
  CodexKind.armor => c.armors.contains(e.id) ? 1 : 0,
  CodexKind.offhand => c.offhands.contains(e.id) ? 1 : 0,
  CodexKind.cape => c.capes.contains(e.id) ? 1 : 0,
  _ => c.materials[e.id] ?? 0,
};

/// L'icona di una pagina: il disegno dell'oggetto se c'è, altrimenti il
/// simbolo del suo tipo.
class CodexIcon extends StatelessWidget {
  const CodexIcon(this.entry, {super.key, this.size = 40});
  final CodexEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (IconData? icon, Color color) = switch (entry.kind) {
      CodexKind.weapon => (Icons.gavel, Palette.goldBright),
      CodexKind.armor => (Icons.shield_outlined, Palette.ash),
      CodexKind.offhand => (Icons.shield_moon_outlined, Palette.gold),
      CodexKind.cape => (Icons.dry_cleaning, Color(capeDefs[entry.id]!.color).withValues(alpha: 1)),
      _ => (null, Palette.gold),
    };
    if (icon == null) return ItemIcon(entry.id, size: size);
    return SizedBox(
      width: size,
      height: size,
      child: Icon(icon, color: color, size: size * 0.8),
    );
  }
}

/// L'indice del Codice: ricerca per nome e filtro per tipo.
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  String _query = '';
  CodexKind? _kind;
  bool _ownedOnly = false;

  /// Di base solo ciò che hai o puoi ottenere adesso: il resto si svela
  /// salendo di livello (o cercandolo per nome).
  bool _later = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final q = _query.trim().toLowerCase();
    bool now(CodexEntry e) =>
        codexOwned(c, e) > 0 ||
        codexReachable(
          codexSources(e.id, s.build),
          level: c.level,
          skillLevel: s.skillLevel,
          stationLevel: s.stationLevel,
        );
    var hidden = 0;
    final list = <CodexEntry>[];
    for (final e in codexEntries) {
      if (_kind != null && e.kind != _kind) continue;
      if (q.isNotEmpty && !e.name.toLowerCase().contains(q)) continue;
      if (_ownedOnly && codexOwned(c, e) == 0) continue;
      if (!_later && q.isEmpty && !now(e)) {
        hidden++;
        continue;
      }
      list.add(e);
    }
    return Scaffold(
      appBar: OathBar(title: Text(tr('CODICE DEL GIURAMENTO')), accent: Sections.forge),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Palette.gold),
                hintText: tr('Cerca un oggetto'),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(tr('Tutto'), _kind == null, () => setState(() => _kind = null)),
                for (final k in CodexKind.values)
                  _chip(k.label, _kind == k, () => setState(() => _kind = _kind == k ? null : k)),
                _chip(
                  tr('Anche più avanti'),
                  _later,
                  () => setState(() => _later = !_later),
                ),
                _chip(
                  tr('Solo i miei'),
                  _ownedOnly,
                  () => setState(() => _ownedOnly = !_ownedOnly),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      tr('Nessun oggetto con questi filtri'),
                      style: const TextStyle(color: Palette.ash),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: list.length + (hidden > 0 ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == list.length) {
                        return TextButton.icon(
                          onPressed: () => setState(() => _later = true),
                          icon: const Icon(Icons.lock_clock, color: Palette.ash),
                          label: Text(
                            tr('Altri {n} si svelano salendo di livello', {'n': hidden}),
                            style: const TextStyle(color: Palette.ash),
                          ),
                        );
                      }
                      final e = list[i];
                      final owned = codexOwned(c, e);
                      return Card(
                        child: ListTile(
                          leading: CodexIcon(e, size: 40),
                          title: OneLine(e.name),
                          subtitle: Text(
                            e.kind.label,
                            style: const TextStyle(color: Palette.ash, fontSize: 13),
                          ),
                          trailing: owned > 0
                              ? Text(
                                  '×$owned',
                                  style: titleStyle(size: 15, color: Palette.holy, spacing: 0),
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => CodexEntryScreen(e))),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: FilterChip(
      label: Text(label),
      selected: on,
      onSelected: (_) => onTap(),
      selectedColor: Palette.gold.withValues(alpha: 0.3),
      checkmarkColor: Palette.goldBright,
    ),
  );
}

/// La pagina di un oggetto: cosa fa, quanti ne hai, dove si trova e a cosa
/// serve. Ogni ricetta porta alla pagina di ciò che produce.
class CodexEntryScreen extends StatelessWidget {
  const CodexEntryScreen(this.entry, {super.key});
  final CodexEntry entry;

  String _pct(double p) {
    final v = p * 100;
    if (v >= 10 || v == v.roundToDouble()) return '${v.round()}%';
    return '${v.toStringAsFixed(v < 1 ? 2 : 1)}%';
  }

  static bool _isDrop(SourceKind k) =>
      k == SourceKind.enemy || k == SourceKind.chest || k == SourceKind.anyFight;

  static IconData _sourceIcon(SourceKind k) => switch (k) {
    SourceKind.enemy => Icons.pest_control,
    SourceKind.chest => Icons.inventory_2,
    SourceKind.anyFight => Icons.casino,
    SourceKind.walk => Icons.directions_walk,
    SourceKind.craft => Icons.local_fire_department,
    SourceKind.shop => Icons.storefront,
  };

  @override
  Widget build(BuildContext context) {
    final s = context.watch<GameState>();
    final c = s.character;
    final owned = codexOwned(c, entry);
    final sources = codexSources(entry.id, s.build);
    final uses = codexUses(entry.id);
    final otherBuild = buildOf(entry.id);
    return Scaffold(
      appBar: OathBar(title: Text(tr('CODICE DEL GIURAMENTO')), accent: Sections.forge),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: CodexIcon(entry, size: 110)),
          const SizedBox(height: 8),
          OneLine(entry.name, align: Alignment.center, style: titleStyle(size: 20)),
          Text(
            '${entry.kind.label} · ${tr('ne hai {n}', {'n': owned})}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.ash),
          ),
          if (entry.effect != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.effect!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.holy, fontSize: 16),
            ),
          ],
          SectionTitle(tr('Dove si trova')),
          if (otherBuild != null && otherBuild != s.build)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tr(
                  'Arriva solo a chi ha giurato su {attr}: a te i nemici lasciano il componente della tua build.',
                  {'attr': otherBuild.label},
                ),
                style: const TextStyle(color: Palette.ember),
              ),
            ),
          if (sources.isEmpty)
            Text(
              tr('Non si trova ancora da nessuna parte.'),
              style: const TextStyle(color: Palette.ash),
            ),
          for (final src in sources)
            Card(
              child: ListTile(
                leading: src.enemy != null
                    ? EnemyPortrait(src.enemy!, size: 44)
                    : Icon(_sourceIcon(src.kind), color: Palette.gold, size: 30),
                title: Text(src.text),
                subtitle: src.enemy == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: LevelBadge(src.enemy!, c.level),
                      ),
                onTap: src.enemy == null || src.enemy!.group == MuscleGroup.stretching
                    ? null
                    : () => startFreeFight(context, src.enemy!, respawn: true),
                trailing: !_isDrop(src.kind)
                    ? null
                    : Text(
                        src.chance == null ? tr('sempre') : _pct(src.chance!),
                        style: TextStyle(
                          color: src.chance == null ? Palette.holy : const Color(0xFFC58BEA),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          SectionTitle(tr('A cosa serve')),
          if (uses.isEmpty)
            Text(tr('Non serve a creare altro.'), style: const TextStyle(color: Palette.ash)),
          for (final u in uses)
            Card(
              child: ListTile(
                leading: u.itemId != null && codexEntry(u.itemId!) != null
                    ? CodexIcon(codexEntry(u.itemId!)!, size: 36)
                    : Icon(
                        switch (u.kind) {
                          UseKind.upgrade => Icons.upgrade,
                          UseKind.socket => Icons.radio_button_checked,
                          UseKind.sell => Icons.storefront,
                          UseKind.recipe => Icons.handyman,
                        },
                        color: Palette.gold,
                        size: 30,
                      ),
                title: Text(u.text),
                trailing: u.itemId != null && codexEntry(u.itemId!) != null
                    ? const Icon(Icons.chevron_right, color: Palette.gold)
                    : null,
                onTap: u.itemId != null && codexEntry(u.itemId!) != null
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CodexEntryScreen(codexEntry(u.itemId!)!)),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
