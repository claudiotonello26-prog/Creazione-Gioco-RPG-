import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/data/game_state.dart';
import 'package:iron_oath/domain/items.dart';
import 'package:iron_oath/domain/skills.dart';
import 'package:iron_oath/domain/walking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late GameState s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = GameState(clock: () => DateTime(2026, 10, 17, 12));
    await s.load();
  });

  test('i passi diventano legno di frassino e i resti si tengono', () {
    expect(s.claimSteps(1000), (2, 0));
    expect(s.character.materials['ash_wood'], 2);
    expect(s.stepBank, 200);
    // Riscuotere di nuovo lo stesso totale non dà nulla.
    expect(s.claimSteps(1000).$1, 0);
    expect(s.claimSteps(1200).$1, 1);
  });

  test('il tetto giornaliero vale anche a rate', () {
    s.setGatherTarget('coal');
    s.claimSteps(dailyStepCap);
    final coal = s.character.materials['coal']!;
    s.claimSteps(dailyStepCap + 20000);
    expect(s.character.materials['coal'], coal);
  });

  test('i legni rari vogliono livello di Taglialegna e accetta', () {
    s.setGatherTarget('oak_wood');
    expect(s.gatherTarget, 'ash_wood');
    s.skillXp[Skill.woodcutting] = 100000;
    s.setGatherTarget('oak_wood');
    expect(s.gatherTarget, 'ash_wood', reason: 'senza Accetta di ferro non si taglia');
    s.character.addMaterial('iron_axe', 1);
    s.setGatherTarget('oak_wood');
    expect(s.gatherTarget, 'oak_wood');
  });

  test('il piccone di frassino si fa una volta sola e apre la miniera', () {
    final ore = resourceById('iron_ore');
    s.character.materials.remove('ash_pickaxe');
    expect(s.canGather(ore), isFalse);
    final r = materialRecipes.firstWhere((r) => r.output == 'ash_pickaxe');
    s.character.addMaterial('ash_plank', 2);
    s.character.addMaterial('ash_wood', 4);
    expect(s.canCraftMaterial(r), isTrue);
    s.craftMaterial(r);
    expect(s.canGather(ore), isTrue);
    expect(s.canCraftMaterial(r), isFalse);
  });

  test('un attrezzo migliore raccoglie più in fretta', () {
    expect(s.gatherBonus(Skill.woodcutting), 0);
    s.character.addMaterial('steel_axe', 1);
    expect(s.gatherBonus(Skill.woodcutting), closeTo(0.4, 1e-9));
    expect(s.hasToolAtLeast('iron_axe'), isTrue);
  });

  test('le ricette sono bloccate dal livello della postazione', () {
    s.character.addMaterial('oak_wood', 4);
    final oak = s.character.materials['oak_wood'];
    expect(s.stat('craft:oak_plank'), 0);
    expect(oak, 4);
    expect(skillProgress(0).$1, 1);
  });
}
