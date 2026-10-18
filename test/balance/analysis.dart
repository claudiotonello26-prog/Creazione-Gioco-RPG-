// Analisi dei giocatori simulati: cerca muri (contenuti consigliati che non
// si riescono a fare), scorciatoie (ricompense che non seguono lo sforzo) e
// progressione troppo veloce o troppo lenta. Scrive un rapporto leggibile.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:iron_oath/domain/skills.dart';

import 'simulator.dart';

enum Severity {
  /// Un muro o una scorciatoia vera: blocca la CI.
  block('BLOCCO'),

  /// Da guardare, ma non rompe il gioco.
  warn('ATTENZIONE'),
  ok('OK');

  const Severity(this.label);
  final String label;
}

class Finding {
  Finding(this.severity, this.area, this.title, this.detail);
  final Severity severity;
  final String area;
  final String title;
  final String detail;
}

/// Soglie del bilanciamento. Il giocatore «medio» deve stare dentro.
class Targets {
  /// Giorni (di calendario) per arrivare al livello 10 col profilo medio.
  static const int level10MinDays = 4, level10MaxDays = 35;

  /// Una spedizione consigliata al tuo livello va finita entro questi giorni.
  static const int expeditionWallDays = 28;

  /// Dopo 30 giorni ogni postazione della forgia dev'essere salita almeno qui.
  static const int stationMinLevel = 3;

  /// Quota massima delle rune che può venire dai forzieri.
  static const double chestShareMax = 0.6;

  /// Versione facile contro versione dura dello stesso nemico: rune per
  /// unità di sforzo, al massimo così tanto più alte.
  static const double easyVariantMaxRatio = 1.25;

  /// Il furbo (un solo esercizio, forma sporca) deve prendere meno rune per
  /// rep del medio.
  static const double cheaterMaxRatio = 0.9;
}

class BalanceReport {
  BalanceReport(this.players, this.days);
  final Map<String, List<SimPlayer>> players;
  final int days;
  final List<Finding> findings = [];
  final StringBuffer _md = StringBuffer();

  void _add(Severity s, String area, String title, String detail) =>
      findings.add(Finding(s, area, title, detail));

  List<Finding> get blockers => findings.where((f) => f.severity == Severity.block).toList();

  SimPlayer _first(String id) => players[id]!.first;

  // ------------------------------------------------------------- analisi

  void analyze() {
    _progression();
    _expeditions();
    _stations();
    _economy();
    _effortChecks();
    _paceThresholds();
    _market();
  }

  /// Quando arriva ogni livello, profilo per profilo.
  void _progression() {
    _md.writeln('## Progressione\n');
    _md.writeln('| Profilo | Giorno 7 | Giorno 30 | Giorno $days | Liv. 10 al giorno | Rep in tutto | Morti |');
    _md.writeln('|---|---|---|---|---|---|---|');
    for (final e in players.entries) {
      final p = e.value.first;
      String at(int d) {
        final s = p.days[min(d, p.days.length) - 1];
        return 'liv. ${s.level}, att. ${s.attack}, dif. ${(s.defense * 100).round()}%';
      }

      final l10 = p.days.where((d) => d.level >= 10).firstOrNull?.day;
      final reps = p.days.fold(0, (a, d) => a + d.reps);
      final deaths = p.days.fold(0, (a, d) => a + d.deaths);
      final wins = p.days.fold(0, (a, d) => a + d.wins);
      _md.writeln('| ${p.profile.label} | ${at(7)} | ${at(30)} | ${at(days)} | ${l10 ?? 'mai'} | $reps '
          '| $deaths su ${wins + deaths} |');
    }
    _md.writeln();

    final medio = _first('medio');
    final l10 = medio.days.where((d) => d.level >= 10).firstOrNull?.day;
    if (l10 == null || l10 > Targets.level10MaxDays) {
      _add(Severity.block, 'Progressione', 'Il giocatore medio sale troppo piano',
          'Livello 10 al giorno ${l10 ?? 'mai'} (massimo ${Targets.level10MaxDays}).');
    } else if (l10 < Targets.level10MinDays) {
      _add(Severity.warn, 'Progressione', 'Il giocatore medio sale troppo in fretta',
          'Livello 10 al giorno $l10 (minimo ${Targets.level10MinDays}).');
    } else {
      _add(Severity.ok, 'Progressione', 'Velocità del giocatore medio',
          'Livello 10 al giorno $l10, livello ${medio.days.last.level} al giorno $days.');
    }

    _md.writeln('### Da dove arrivano XP e rune\n');
    _md.writeln('| Profilo | XP | Rune |');
    _md.writeln('|---|---|---|');
    for (final e in players.entries) {
      final p = e.value.first;
      String share(Map<String, int> m) {
        final tot = m.values.fold(0, (a, b) => a + b);
        if (tot == 0) return '-';
        final parts = m.entries.where((x) => x.value > 0).toList()
          ..sort((a, b) => b.value - a.value);
        return parts.map((x) => '${x.key} ${(x.value * 100 / tot).round()}%').join(', ');
      }

      _md.writeln('| ${p.profile.id} | ${share(p.xpBy)} | ${share(p.runesBy)} |');
    }
    _md.writeln();
  }

  /// Muri: spedizioni consigliate al tuo livello che non riesci a finire.
  void _expeditions() {
    _md.writeln('## Spedizioni: livello raggiunto e prima vittoria\n');
    _md.writeln('| Spedizione | Gruppo | Liv. | ${players.keys.join(' | ')} |');
    _md.writeln('|---|---|---|${players.keys.map((_) => '---').join('|')}|');
    for (final e in expeditions) {
      final cells = <String>[];
      for (final id in players.keys) {
        final p = _first(id);
        final log = p.expeditionLog[e.id]!;
        final trains = p.profile.varied || e.group == MuscleGroup.push;
        if (!trains) {
          cells.add('–');
          continue;
        }
        final u = log.unlockedDay, cl = log.clearedDay;
        cells.add(u == null
            ? (cl == null ? '·' : 'vinta g$cl')
            : cl == null
                ? '**muro** (da g$u)'
                : 'g$u → g$cl');
        if (u != null && p.profile.varied) {
          final waited = (cl ?? days) - u;
          if (cl == null && (log.lastDay ?? u) - u >= Targets.expeditionWallDays ||
              cl != null && waited > Targets.expeditionWallDays) {
            _add(
                Severity.block,
                'Muro',
                '${e.name} (liv. ${e.level}) per «${p.profile.id}»',
                cl == null
                    ? 'Consigliata dal giorno $u, mai finita in $days giorni '
                        '(${log.attempts} tentativi, ${log.deaths} morti).'
                    : 'Consigliata dal giorno $u, finita solo il giorno $cl.');
          }
        }
      }
      _md.writeln('| ${e.name} | ${e.group.label} | ${e.level} | ${cells.join(' | ')} |');
    }
    _md.writeln('\n`gX → gY`: consigliata dal giorno X, prima vittoria il giorno Y. '
        '`·`: livello non ancora raggiunto.\n');
  }

  /// La forgia: ogni postazione deve poter salire di livello.
  void _stations() {
    _md.writeln('## Mestieri dopo $days giorni\n');
    _md.writeln('| Profilo | ${Skill.values.map((s) => s.label).join(' | ')} | Arma | Armatura |');
    _md.writeln('|---|${Skill.values.map((_) => '---').join('|')}|---|---|');
    for (final e in players.entries) {
      final p = e.value.first;
      _md.writeln('| ${p.profile.id} | ${Skill.values.map(p.state.skillLevel).join(' | ')} '
          '| ${p.state.character.weapon.displayName} | ${p.days.last.armor} |');
    }
    _md.writeln();
    if (days < 30) return;
    final p = _first('medio');
    for (final station in [Station.carpentry, Station.furnace, Station.anvil]) {
      final level = p.state.stationLevel(station);
      if (level < Targets.stationMinLevel) {
        _add(Severity.block, 'Forgia', '${station.label} ferma al livello $level',
            'Dopo $days giorni il giocatore medio non riesce a far salire la postazione: '
                'manca una ricetta ripetibile ai primi livelli.');
      }
    }
  }

  /// Rune: da dove arrivano e se servono a qualcosa.
  void _economy() {
    for (final e in players.entries) {
      final p = e.value.first;
      if (!p.profile.varied) continue;
      final tot = p.runesBy.values.fold(0, (a, b) => a + b);
      final chest = p.runesBy['forziere'] ?? 0;
      if (tot > 0 && chest / tot > Targets.chestShareMax) {
        _add(
            Severity.block,
            'Rune',
            'I forzieri pagano troppo («${p.profile.id}»)',
            '${(chest * 100 / tot).round()}% delle rune viene dai forzieri delle spedizioni, '
                'non dalle rep.');
      }
    }
    final medio = _first('medio');
    final spent = medio.spentRunes, left = medio.state.character.runes;
    if (days >= 60 && spent < (spent + left) * 0.2) {
      _add(Severity.warn, 'Rune', 'Le rune si accumulano senza uso',
          'Dopo $days giorni il giocatore medio ha $left rune e ne ha spese solo $spent: '
              'servono più cose da comprare con le rune.');
    } else {
      _add(Severity.ok, 'Rune', 'Le rune si spendono',
          'Dopo $days giorni il giocatore medio ne ha spese $spent e ne tiene $left.');
    }
  }

  /// Prove mirate sul motore di combattimento: le ricompense seguono lo sforzo?
  void _effortChecks() {
    _md.writeln('## Sforzo e ricompensa\n');

    // 1. Versione facile contro versione dura dello stesso movimento.
    _md.writeln('### Stesso mostro, versioni diverse dell\'esercizio\n');
    _md.writeln('| Mostro | Versione | Difficoltà | Rep | Rune | Rune per rep base |');
    _md.writeln('|---|---|---|---|---|---|');
    var worst = 0.0;
    var worstText = '';
    for (final enemy in [...enemyDefs.values]) {
      final moves = enemy.moves.where((m) => !m.hold).toList();
      if (moves.length < 2) continue;
      final perEffort = <Move, double>{};
      for (final m in moves) {
        final (reps, runes) = _perfectFight(enemy, m);
        perEffort[m] = runes / (reps * m.difficulty);
        if (enemy.id == 'slag_goblin' || enemy.id == 'hollow_smith') {
          _md.writeln('| ${enemy.name} | ${m.name} | ${m.difficulty.toStringAsFixed(2)} | $reps '
              '| $runes | ${perEffort[m]!.toStringAsFixed(2)} |');
        }
      }
      final hi = perEffort.values.reduce(max), lo = perEffort.values.reduce(min);
      if (hi / lo > worst) {
        worst = hi / lo;
        worstText = enemy.name;
      }
    }
    _md.writeln();
    if (worst > Targets.easyVariantMaxRatio) {
      _add(Severity.block, 'Sforzo', 'La versione facile paga più di quella dura',
          'Con $worstText la versione più facile rende ${worst.toStringAsFixed(2)}× rune per '
              'unità di sforzo rispetto alla più dura.');
    } else {
      _add(Severity.ok, 'Sforzo', 'Versioni facili e dure pagano in proporzione',
          'Scarto massimo ${worst.toStringAsFixed(2)}×.');
    }

    // 2. Il furbo contro il medio: rune per rep di combattimento.
    double runesPerRep(SimPlayer p) {
      final reps = p.fights.fold(0, (a, f) => a + f.reps);
      final runes = p.fights.fold(0, (a, f) => a + f.lootValue);
      return reps == 0 ? 0 : runes / reps;
    }

    final cheat = runesPerRep(_first('furbo')), fair = runesPerRep(_first('medio'));
    _md.writeln('Valore (rune + materiali al Mercante) per rep di combattimento: '
        'medio ${fair.toStringAsFixed(1)}, furbo ${cheat.toStringAsFixed(1)}.\n');
    if (cheat > fair * Targets.cheaterMaxRatio) {
      _add(Severity.block, 'Sforzo', 'Ripetere lo stesso esercizio con forma sporca conviene',
          'Il furbo prende ${cheat.toStringAsFixed(1)} per rep contro ${fair.toStringAsFixed(1)} '
              'del medio.');
    } else {
      _add(Severity.ok, 'Sforzo', 'Fatica e forma funzionano',
          'Il furbo prende il ${(cheat * 100 / fair).round()}% per rep del giocatore medio.');
    }
  }

  /// Rep e rune di un combattimento vinto con rep perfette (test 20).
  (int, int) _perfectFight(EnemyDef enemy, Move move) {
    final c = Character(weapon: WeaponInstance(weaponId: 'pilgrim_blade', upgrade: 10));
    final e = CombatEngine(
      enemy: enemy,
      character: c,
      testReps: max(3, (20 / move.difficulty).round()),
      random: Random(1),
      difficulty: move.difficulty,
    );
    while (e.status == CombatStatus.fighting) {
      e.registerRep(RepQuality.perfect);
    }
    return (e.reps, e.rewards().runes);
  }

  /// Il ritmo più lento con cui l'eroe base vince, gradino per gradino.
  void _paceThresholds() {
    _md.writeln('## Ritmo minimo per vincere (eroe base, test 20, rep buone)\n');
    _md.writeln('| Gradino | Mostro | Vita | Danno | Ritmo più lento che vince |');
    _md.writeln('|---|---|---|---|---|');
    for (var tier = 1; tier <= 5; tier++) {
      for (final boss in [false, true]) {
        final enemy = enemyDefs.values.where((e) => e.tier == tier && e.isBoss == boss).firstOrNull;
        if (enemy == null) continue;
        // Con l'arma giusta per il gradino: la difesa non deve far rimbalzare.
        double? slowest;
        for (var pace = 1.5; pace <= 6.0; pace += 0.25) {
          var wins = 0;
          for (var s = 0; s < 5; s++) {
            if (_paceFight(enemy, pace, s)) wins++;
          }
          if (wins >= 3) slowest = pace;
        }
        final e = CombatEngine(enemy: enemy, character: Character(), testReps: 20);
        _md.writeln('| $tier${boss ? ' boss' : ''} | ${enemy.name} | ${e.enemyMaxHp.round()} '
            '| ${e.hitDamage.toStringAsFixed(1)} ogni ${enemy.attackInterval} s '
            '| ${slowest == null ? 'nessuno' : '${slowest.toStringAsFixed(2)} s'} |');
      }
    }
    _md.writeln('\nIl motore è tarato su 2,2 s a rep: sotto i 2 s di margine il gradino '
        'è troppo duro, sopra i 4 s troppo facile.\n');
  }

  bool _paceFight(EnemyDef enemy, double pace, int seed) {
    final r = Random(seed);
    // Arma potenziata quanto basta per passare la difesa.
    final c = Character(weapon: WeaponInstance(weaponId: 'pilgrim_blade', upgrade: 10))
      ..attributes[Attribute.dexterity] = 10 + enemy.tier * 6;
    final e = CombatEngine(enemy: enemy, character: c, testReps: 20, random: r);
    var t = 0.0, next = pace;
    while (e.status == CombatStatus.fighting && t < 600) {
      t += 0.1;
      e.tick(0.1);
      if (e.status != CombatStatus.fighting) break;
      if (t >= next) {
        e.registerRep(r.nextDouble() < 0.5 ? RepQuality.perfect : RepQuality.good);
        next = t + pace * (0.85 + r.nextDouble() * 0.3);
      }
    }
    return e.status == CombatStatus.victory;
  }

  /// Comprare dal Mercante, forgiare e rivendere non deve rendere.
  void _market() {
    final gains = <String>[];
    for (final r in materialRecipes) {
      if (r.tool) continue;
      if (!r.inputs.keys.every(merchantStock.contains)) continue;
      var cost = 0;
      r.inputs.forEach((k, v) => cost += buyPrice(k) * v);
      final sell = sellPrice(r.output) * r.qty;
      if (sell > cost) gains.add('${r.output}: compri a $cost, vendi a $sell');
    }
    if (gains.isEmpty) {
      _add(Severity.ok, 'Mercato', 'Nessun guadagno comprando e rivendendo', '');
    } else {
      _add(Severity.block, 'Mercato', 'Guadagno sicuro al Mercante', gains.join('; '));
    }
  }

  // ------------------------------------------------------------- rapporto

  String markdown() {
    final out = StringBuffer()
      ..writeln('# Rapporto del simulatore di bilanciamento\n')
      ..writeln('${players.length} giocatori simulati per $days giorni con il codice vero del '
          'gioco (GameState, CombatEngine, forgia, passi).\n')
      ..writeln('## Esito\n');
    for (final s in Severity.values) {
      for (final f in findings.where((f) => f.severity == s)) {
        out.writeln('- **${s.label}** · ${f.area} · ${f.title}${f.detail.isEmpty ? '' : ': ${f.detail}'}');
      }
    }
    out
      ..writeln()
      ..writeln('## Profili\n');
    for (final e in players.entries) {
      final p = e.value.first.profile;
      out.writeln('- **${p.id}**: ${p.label}; ${p.repsPerSession} rep per allenamento, '
          'ritmo ${p.secondsPerRep} s, ${(p.pPerfect * 100).round()}% rep perfette.');
    }
    out
      ..writeln()
      ..write(_md);
    return out.toString();
  }
}

/// Le soglie di fatica, per il rapporto.
String fatigueSummary() =>
    'Fatica: 100% fino a ${GameState.freshReps} rep di un gruppo, poi 60% fino a '
    '${GameState.tiredReps}, poi 30%.';
