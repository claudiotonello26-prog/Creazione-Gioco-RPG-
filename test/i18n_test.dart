import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/core/i18n.dart';

/// Le chiavi scritte come testo fisso dentro tr(...), in tutto lib/.
/// Due testi attaccati ('a' 'b') valgono come uno solo.
Map<String, String> _trKeys() {
  final literal = RegExp(r"""'((?:[^'\\\n]|\\.)*)'|"((?:[^"\\\n]|\\.)*)" """.trim());
  final call = RegExp(
    r"""\btr\(\s*((?:(?:'(?:[^'\\\n]|\\.)*'|"(?:[^"\\\n]|\\.)*")\s*)+)[,)]""",
  );
  String unescape(String s) => s.replaceAllMapped(
        RegExp(r'\\(.)'),
        (m) => switch (m[1]) { 'n' => '\n', 't' => '\t', _ => m[1]! },
      );
  final keys = <String, String>{};
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    if (f.path.contains('${Platform.pathSeparator}i18n')) continue;
    final src = f.readAsStringSync();
    for (final m in call.allMatches(src)) {
      final key = literal
          .allMatches(m[1]!)
          .map((l) => unescape(l[1] ?? l[2]!))
          .join();
      keys[key] = f.path;
    }
  }
  return keys;
}

Set<String> _placeholders(String s) =>
    {for (final m in RegExp(r'\{(\w+)\}').allMatches(s)) m[1]!};

void main() {
  final keys = _trKeys();

  test('ogni testo passato a tr ha la traduzione inglese', () {
    final missing = [
      for (final e in keys.entries)
        if (!enStrings.containsKey(e.key) && !itStrings.containsKey(e.key))
          '${e.value}: ${e.key}',
    ];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('le parti variabili usano {nome}, non \$nome', () {
    final bad = [
      for (final e in keys.entries)
        if (e.key.contains(r'$')) '${e.value}: ${e.key}',
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('la traduzione ha le stesse parti variabili', () {
    final bad = [
      for (final e in enStrings.entries)
        if (!_placeholders(e.key).containsAll(_placeholders(e.value)) ||
            !_placeholders(e.value).containsAll(_placeholders(e.key)))
          '${e.key} → ${e.value}',
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('tr sostituisce le parti variabili e cambia lingua', () {
    appLang = Lang.en;
    expect(tr('Lingua'), 'Language');
    expect(tr('Vigor'), 'Vigor');
    appLang = Lang.it;
    expect(tr('Vigor'), 'Vigore');
    expect(tr('{n} rep', {'n': 3}), '3 rep');
  });
}
