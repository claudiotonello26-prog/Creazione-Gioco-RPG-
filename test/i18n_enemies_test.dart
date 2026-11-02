import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/core/i18n.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/hunting.dart';

void main() {
  /// Tutti i testi mostrati che vengono da enemies.dart e hunting.dart.
  Map<String, String> texts() {
    final out = <String, String>{};
    void add(String text, String where) => out[text] = where;
    final defs = [...enemyDefs.values, ...baseAnimals, ...huntAnimals];
    for (final d in defs) {
      add(d.nameIt, 'nome di ${d.id}');
      add(d.region, 'regione di ${d.id}');
      for (final m in d.moves) {
        add(m.name, 'mossa di ${d.id}');
      }
    }
    for (final e in expeditions) {
      add(e.name, 'nome di ${e.id}');
      add(e.blurb, 'descrizione di ${e.id}');
      add(e.chest.name, 'forziere di ${e.id}');
      for (final s in e.steps) {
        add(s.move.name, 'tappa di ${e.id}');
      }
    }
    return out;
  }

  test('ogni testo di mostri e spedizioni ha la traduzione inglese', () {
    appLang = Lang.it;
    final missing = [
      for (final e in texts().entries)
        if (!enStrings.containsKey(e.key)) '${e.value}: ${e.key}',
    ];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('il Veterano si chiama Veteran in inglese', () {
    final e = expeditions.first;
    final step = e.steps.firstWhere((s) => s.veteran);
    final base = enemyDefs[step.monsterId]!;
    try {
      appLang = Lang.it;
      expect(step.monster.name, '${base.nameIt} (Veterano)');
      expect(step.monster.nameIt, base.nameIt);
      appLang = Lang.en;
      final name = step.monster.name;
      expect(name, contains('Veteran'));
      expect(name, isNot(contains('Veterano')));
      expect(name, '${enStrings[base.nameIt]} (Veteran)');
      expect(e.name, enStrings['Le Forge Sepolte']);
      expect(base.region, 'The Buried Forges');
    } finally {
      appLang = Lang.it;
    }
  });
}
