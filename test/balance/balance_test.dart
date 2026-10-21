// Simulatore di bilanciamento: gira a ogni `flutter test` e in CI.
//
//   flutter test test/balance
//   flutter test test/balance --dart-define=SIM_DAYS=365 --dart-define=SIM_SEEDS=3
//
// Scrive il rapporto in build/balance/report.md (e le build a confronto in
// build/balance/builds.md) e fallisce se trova un muro o
// una scorciatoia (gravità BLOCCO).
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'analysis.dart';
import 'simulator.dart';

const int simDays = int.fromEnvironment('SIM_DAYS', defaultValue: 90);
const int simSeeds = int.fromEnvironment('SIM_SEEDS', defaultValue: 1);
const int buildDays = int.fromEnvironment('SIM_BUILD_DAYS', defaultValue: 365);

void main() {
  test('simulatore di bilanciamento: nessun muro e nessuna scorciatoia', () {
    final players = runProfiles(standardProfiles, days: simDays, seeds: simSeeds);
    final report = BalanceReport(players, simDays)..analyze();
    final md = report.markdown();
    final file = File('build/balance/report.md');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(md);
    print(md);
    expect(report.blockers.map((f) => '${f.area}: ${f.title}: ${f.detail}').toList(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('build a confronto: Forza, Destrezza, Fede e Intelligenza allineate', () {
    final players = runProfiles(buildProfiles, days: buildDays);
    final report = BalanceReport(players, buildDays)..analyzeBuilds();
    final md = report.markdown();
    final file = File('build/balance/builds.md');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(md);
    print(md);
    expect(report.blockers.map((f) => '${f.area}: ${f.title}: ${f.detail}').toList(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 20)));
}
