import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/character.dart';
import 'package:iron_oath/domain/combat.dart';
import 'package:iron_oath/domain/enemies.dart';
import 'package:iron_oath/domain/exercise.dart';
import 'package:iron_oath/domain/market.dart';
import 'package:iron_oath/domain/novice.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GameState s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = GameState(clock: () => DateTime(2026, 10, 17, 12));
    await s.load();
  });

  const rewards = CombatRewards(xp: 10, runes: 10, materials: {});
  final reps = List.filled(10, RepQuality.good);

  test('la postura decide se sale Attacco o Difesa', () {
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true, stance: Stance.aggressive);
    expect(s.skillXp[Skill.attack], 40);
    expect(s.skillXp[Skill.defense] ?? 0, 0);
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true, stance: Stance.defensive);
    expect(s.skillXp[Skill.defense], 40);
    s.applyCombatRewards(rewards, ExerciseId.squat, reps, victory: true);
    expect(s.skillXp[Skill.attack], 60);
    expect(s.skillXp[Skill.defense], 60);
  });

  test('Attacco e Difesa alzano i numeri del cavaliere', () {
    final atk = s.attackValue, def = s.defenseValue;
    s.skillXp[Skill.attack] = 100000;
    s.skillXp[Skill.defense] = 100000;
    expect(s.attackValue, greaterThan(atk));
    expect(s.defenseValue, greaterThan(def));
    expect(s.defenseValue, lessThanOrEqualTo(0.75));
  });

  test('nella caccia la probabilità di drop raro cresce in modo esponenziale', () {
    CombatEngine at(int wave) => CombatEngine(
        enemy: enemyDefs['hollow_goblin']!, character: Character(), testReps: 20, wave: wave);
    expect(at(0).rareChance, closeTo(0.015, 1e-9));
    expect(at(5).rareChance / at(4).rareChance, closeTo(1.35, 1e-9));
    expect(at(30).rareChance, 0.6);
    expect(at(30).uncommonChance, 0.9);
  });

  test('ogni mostro ha il suo esercizio', () {
    expect(enemyDefs['hollow_goblin']!.exercises, [ExerciseId.squat]);
    expect(enemyDefs['carrion_hound']!.exercises, [ExerciseId.lunge]);
    expect(enemyDefs['fallen_knight']!.exercises, [ExerciseId.pushUp]);
    expect(enemyDefs['ash_wyrm']!.exercises, [ExerciseId.crunch, ExerciseId.legRaise]);
  });

  test('il Mercante compra a metà e vende al doppio', () {
    s.character.runes = 0;
    s.character.addMaterial('iron_ore', 3);
    final have = s.character.materials['iron_ore']!;
    expect(s.sellMaterial('iron_ore', 2), isTrue);
    expect(s.character.runes, sellPrice('iron_ore') * 2);
    expect(s.character.materials['iron_ore'], have - 2);
    expect(s.stat('sell'), 2);
    expect(s.buyMaterial('iron_ore'), isTrue);
    expect(s.character.runes, 0);
    expect(s.sellMaterial('ash_pickaxe'), isFalse, reason: 'gli attrezzi non si vendono');
  });

  test('non si vende l\'arma impugnata', () {
    expect(s.sellWeapon(s.character.weapon), isFalse);
  });

  test('il Cammino del Novizio parte dal goblin e finisce col giuramento', () {
    expect(noviceQuests.first.action, NoviceAction.fightGoblin);
    expect(noviceQuests.last.stat, 'quests');
    expect(noviceQuests.length, 14);
    s.bestHuntWave = 3;
    expect(s.stat('hunt_wave'), 3);
  });
}
