import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/core/i18n.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/novice.dart';
import 'package:iron_oath/domain/progress.dart';
import 'package:iron_oath/domain/pvp.dart';
import 'package:iron_oath/domain/skills.dart';

/// I testi italiani dei dati di dominio mostrati al giocatore. I test girano
/// in italiano, quindi i getter danno il testo originale (la chiave).
List<String> _domainTexts() => [
      for (final g in MuscleGroup.values) g.label,
      for (final e in exercises.values) ...[
        e.name,
        for (final v in e.variants) v.name,
      ],
      for (final q in noviceQuests) ...[q.title, q.goal, q.trainer],
      for (final a in Attribute.values) a.description,
      for (final c in perkChoices)
        for (final p in c.options) ...[p.name, p.description],
      for (final r in resources) r.where,
      for (final q in RepQuality.values) q.label,
      for (final s in Stance.values) s.label,
      for (final r in BodyRegion.values) r.label,
      for (final s in ProgressSpan.values) s.label,
      for (final d in Division.values) d.label,
      for (final m in PlayMode.values) m.label,
      // Nomi degli avversari fantasma dell'Arena.
      'Ser Varek', 'Ildra la Grigia', 'Fratello Osmund', 'Kael di Cenere', 'Maelis',
      'Il Penitente', 'Thorne', 'Sorella Vesna', 'Brann Mezzaluna',
      // Testi generati.
      'Senza Nome', 'amico',
      'Campione della Stagione', 'Cavaliere d\'Arena', 'Scudiero d\'Arena', 'Recluta d\'Arena',
      '{n} rep valide: vince il tempo più basso',
      '{n} rep valide per gamba: vince il tempo più basso',
      '{s} secondi: vince chi fa più rep valide',
      'Vince chi resiste di più',
    ];

/// Tutti i nomi passati a Move('...') in lib/: sono gli esercizi che il
/// giocatore vede.
Set<String> _moveNames() {
  final re = RegExp(r"Move\(\s*'((?:[^'\\]|\\.)*)'");
  return {
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File && f.path.endsWith('.dart'))
        for (final m in re.allMatches(f.readAsStringSync())) m[1]!.replaceAll(r"\'", "'"),
  };
}

void main() {
  setUp(() => appLang = Lang.it);

  test('i testi dei dati di dominio hanno la traduzione inglese', () {
    final missing = [
      for (final t in _domainTexts())
        if (!enStrings.containsKey(t) && !itStrings.containsKey(t)) t,
    ];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('i nomi delle mosse hanno la traduzione inglese', () {
    final missing = [
      for (final t in _moveNames())
        if (!enStrings.containsKey(t)) t,
    ];
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('in inglese i getter traducono, i nomi grezzi restano italiani', () {
    appLang = Lang.en;
    final lunge = exercises[ExerciseId.lunge]!;
    expect(lunge.name, 'Lunges');
    expect(lunge.nameIt, 'Affondi');
    expect(lunge.variant(1).nameIt, 'Affondi con appoggio');
    expect(noviceQuests.first.title, 'Arm Yourself');
    expect(noviceQuests[1].title, 'First Blood');
    expect(MuscleGroup.legs.label, 'Legs');
    expect(
      arenaChallenges[ExerciseId.lunge]!.description,
      '20 valid reps per leg: fastest time wins',
    );
    appLang = Lang.it;
    expect(lunge.name, 'Affondi');
  });

  test('lo storico tiene i nomi italiani anche in inglese', () {
    appLang = Lang.en;
    final s = GameState(clock: () => DateTime(2026, 3, 2));
    s.addTraining(ExerciseId.lunge, [RepQuality.good], name: tr('Affondi'));
    s.addTraining(ExerciseId.pushUp, [RepQuality.good]);
    expect(s.history.values.first.keys, containsAll(['Affondi', 'Push-up']));
    appLang = Lang.it;
  });
}
