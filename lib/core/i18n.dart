/// Testi in due lingue. Il codice scrive i testi in italiano e li passa a
/// [tr], che in inglese li cerca nelle tabelle di lib/core/i18n/. I primi
/// nomi di gioco (abilità, attributi, schede) nascono invece in inglese e
/// hanno la traduzione italiana qui sotto: [tr] funziona in tutti e due i
/// versi.
///
/// Le parti variabili si scrivono tra graffe: tr('Hai fatto {n} rep',
/// {'n': reps}). Il test i18n_test controlla che ogni testo abbia la sua
/// traduzione.
library;

import 'i18n/en_data_enemies.dart';
import 'i18n/en_data_items.dart';
import 'i18n/en_domain.dart';
import 'i18n/en_ui_a.dart';
import 'i18n/en_ui_b.dart';
import 'i18n/en_ui_c.dart';

enum Lang {
  it('Italiano'),
  en('English');

  const Lang(this.label);
  final String label;
}

/// Scelta della lingua nelle impostazioni: quella del telefono o una fissa.
enum LangPref {
  auto('Automatica'),
  it('Italiano'),
  en('English');

  const LangPref(this._label);
  final String _label;
  String get label => this == auto ? tr(_label) : _label;
}

/// Lingua corrente, impostata da GameState al caricamento.
Lang appLang = Lang.it;

/// Lingua del telefono: italiano se è l'italiano, inglese altrimenti.
/// main.dart la legge dal sistema; i test la fissano all'italiano.
Lang Function() systemLang = () => Lang.it;

/// La lingua che vale per [pref].
Lang resolveLang(LangPref pref) => switch (pref) {
      LangPref.auto => systemLang(),
      LangPref.it => Lang.it,
      LangPref.en => Lang.en,
    };

const Map<String, String> _it = {
  // Abilità di combattimento.
  'Trees': 'Alberi',
  'Ores': 'Minerali',
  'Attack': 'Attacco',
  'Defence': 'Difesa',
  'Magic': 'Magia',
  'Expeditions': 'Spedizioni',
  // Abilità di produzione.
  'Woodcutting': 'Boscaiolo',
  'Mining': 'Minatore',
  'Carpentry': 'Falegnameria',
  'Smelting': 'Fusione',
  'Smithing': 'Forgiatura',
  // Attributi.
  'Vigor': 'Vigore',
  'Endurance': 'Resistenza',
  'Strength': 'Forza',
  'Dexterity': 'Destrezza',
  'Faith': 'Fede',
  'Intelligence': 'Intelligenza',
  // Schede.
  'Home': 'Home',
  'Training': 'Training',
  'Gathering': 'Raccolta',
  'Forge': 'Forgia',
  'Market': 'Mercato',
  'Arena': 'Arena',
  'Guild': 'Gilda',
};

const Map<String, String> _enCore = {
  'Automatica': 'Automatic',
  'Lingua': 'Language',
  'Segue la lingua del telefono': 'Follows the phone language',
};

/// Tutte le traduzioni inglesi, dall'italiano.
final Map<String, String> enStrings = {
  ..._enCore,
  ...enDataEnemies,
  ...enDataItems,
  ...enDomain,
  ...enUiA,
  ...enUiB,
  ...enUiC,
};

/// Le chiavi inglesi che hanno la traduzione italiana.
Map<String, String> get itStrings => _it;

/// Il testo [text] nella lingua corrente, con le parti {nome} sostituite da
/// [args].
String tr(String text, [Map<String, Object?> args = const {}]) {
  var out = appLang == Lang.en ? (enStrings[text] ?? text) : (_it[text] ?? text);
  for (final e in args.entries) {
    out = out.replaceAll('{${e.key}}', '${e.value}');
  }
  return out;
}
