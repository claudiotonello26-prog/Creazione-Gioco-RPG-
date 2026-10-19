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
    // 40 passi per ciocco: 4000 passi sono 100 legni.
    expect(s.claimSteps(1010).$1, 25);
    expect(s.character.materials['ash_wood'], 25);
    expect(s.stepBank, 10);
    // Riscuotere di nuovo lo stesso totale non dà nulla.
    expect(s.claimSteps(1010).$1, 0);
    expect(s.claimSteps(1040).$1, 1);
  });

  test('i passi si mettono da parte e si spendono quanti se ne vuole', () {
    expect(s.collectSteps(1000), 1000);
    expect(s.collectSteps(1000), 0, reason: 'gli stessi passi non contano due volte');
    expect(s.stepBank, 1000);
    // 3 ciocchi da 40 passi: restano 880 passi in riserva.
    expect(s.spendSteps('ash_wood', 120).$1, 3);
    expect(s.stepBank, 880);
    // Solo unità intere: 50 passi fanno un ciocco, gli altri 10 restano.
    expect(s.spendSteps('ash_wood', 50).$1, 1);
    expect(s.stepBank, 840);
    // Non si spende più di quel che si ha.
    expect(s.spendSteps('ash_wood', 99999).$1, 21);
    expect(s.stepBank, 0);
    expect(s.character.materials['ash_wood'], 25);
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
    s.character.addMaterial('ash_wood', 40);
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
