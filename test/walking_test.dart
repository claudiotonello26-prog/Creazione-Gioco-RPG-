import 'package:flutter_test/flutter_test.dart';
import 'package:iron_oath/domain/walking.dart';

void main() {
  test('1000 passi = 1 minerale, 2500 = anche un legno', () {
    expect(lootForSteps(999), isEmpty);
    expect(lootForSteps(1000), {'iron_ore': 1});
    expect(lootForSteps(2500), {'iron_ore': 2, 'ash_wood': 1});
  });

  test('i traguardi danno pietre', () {
    final l = lootForSteps(10000);
    expect(l['forge_stone_1'], 2);
    expect(l['holy_shard'], 1);
  });

  test('riscuotere a rate non dà mai più che riscuotere una volta', () {
    var claimed = 0;
    final total = <String, int>{};
    for (final s in [800, 3100, 3100, 7400, 12000]) {
      stepLootDelta(claimed, s).forEach((k, v) => total[k] = (total[k] ?? 0) + v);
      claimed = s;
    }
    expect(total, lootForSteps(12000));
  });

  test('oltre il tetto giornaliero non si guadagna', () {
    expect(stepLootDelta(dailyStepCap, dailyStepCap + 20000), isEmpty);
  });
}
