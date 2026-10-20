import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/codex.dart';

void main() {
  test('il minerale di ferro si trova camminando e dal Mercante, e diventa lingotto', () {
    final src = codexSources('iron_ore', Attribute.strength);
    expect(src.map((s) => s.kind), containsAll([SourceKind.walk, SourceKind.shop]));
    expect(codexUses('iron_ore').map((u) => u.itemId), contains('iron_ingot'));
  });

  test('i componenti di build arrivano secondo il Giuramento', () {
    expect(codexSources('ember_iron', Attribute.strength), isNotEmpty);
    expect(
      codexSources('ember_iron', Attribute.dexterity).where((s) => s.kind == SourceKind.enemy),
      isEmpty,
    );
    expect(buildOf('gale_silver'), Attribute.dexterity);
  });

  test('gli amuleti dei forzieri e dei nemici hanno la loro pagina', () {
    expect(codexEntry('amulet_hunter_heart'), isNotNull);
    expect(codexSources('amulet_hunter_heart', Attribute.strength), isNotEmpty);
  });

  test('le pietre di forgia dicono quali potenziamenti fanno', () {
    expect(codexUses('forge_stone_1').map((u) => u.text).join(), contains('+1'));
  });

  test('ogni oggetto del Codice si trova da qualche parte', () {
    final orphans = [
      for (final e in codexEntries)
        if (codexSources(e.id, buildOf(e.id) ?? Attribute.strength).isEmpty) e.id,
    ];
    expect(orphans, isEmpty, reason: orphans.join(', '));
  });
}
