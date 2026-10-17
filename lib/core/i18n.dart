/// Testi in due lingue: i nomi nascono in inglese (le chiavi) e hanno la
/// traduzione italiana. Si parte dai nomi di gioco (abilità, attributi);
/// il resto dell'interfaccia passa qui un po' alla volta.
library;

enum Lang {
  it('Italiano'),
  en('English');

  const Lang(this.label);
  final String label;
}

/// Lingua corrente, impostata da GameState al caricamento.
Lang appLang = Lang.it;

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
};

/// Il testo [en] nella lingua corrente.
String tr(String en) => appLang == Lang.en ? en : (_it[en] ?? en);
