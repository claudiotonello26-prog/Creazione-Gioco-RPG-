# Genera lib/domain/enemies.dart e lib/domain/hunting.dart da design/contenuti.json.
# Uso: python3 tool/gen_world.py (dalla radice del progetto).
import json, re, sys
d = json.load(open('/mnt/project-files/design/contenuti.json'))
old = open('lib/domain/enemies.dart').read()
def q(s): return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"
# Debolezze e bestie dal file di oggi.
weak, beast = {}, set()
for m in re.finditer(r"  '(\w+)': EnemyDef\((.*?)\n  \),", old, re.S):
    body = m.group(2)
    w = re.search(r"weakTo: (WeaponStyle\.\w+)", body)
    if w: weak[m.group(1)] = w.group(1)
    if 'isBeast: true' in body: beast.add(m.group(1))
blurbs = {m.group(1): m.group(2) for m in re.finditer(r"id: '(\w+)',\n    name: .*?\n    group: .*?\n    level: \d+,\n    blurb: '((?:[^'\\]|\\.)*)'", old)}
GROUP = {'push': 'push', 'legs': 'legs', 'core': 'core', 'cardio': 'cardio', 'stretching': 'stretching'}
TR = {'pushUp','squat','lunge','crunch','legRaise','plank','jumpingJack','highKnees','stretch'}
FIX = {'Push-up sulle ginocchia': 1.3}  # le ginocchia aiutano: più rep del push-up.
moves = {}
for g in d['groups']:
    for e in g['expeditions']:
        for s in e['steps']:
            x = s['exercise']; moves[x['name']] = (x['track'], FIX.get(x['name'], x['ratio']), x['demo'])
# Le high knees hanno il loro contatore (ogni ginocchio una rep).
if 'High knees' in moves: moves['High knees'] = ('highKnees', 1.2, moves['High knees'][2])
moves.setdefault('Push-up', ('pushUp', 1.0, 'push_up'))
for n, t in [('Squat', 'squat'), ('Crunch', 'crunch'), ('Jumping jack', 'jumpingJack')]:
    moves.setdefault(n, (t, 1.0, n.lower()))
def move(n):
    t, r, demo = moves[n]
    assert t in TR, t
    r = round(0.5 * r, 3)
    return f"Move({q(n)}, ExerciseId.{t}{'' if r == 0.5 else f', ratio: {r}'})"
def enemy(m, group):
    L = [f"  {q(m['id'])}: EnemyDef(", f"    id: {q(m['id'])},", f"    name: {q(m['name'])},",
         f"    tier: {m['tier']},", f"    level: {m['level']},", f"    group: MuscleGroup.{group},",
         f"    region: {q(m.get('region') or 'La Rocca')},"]
    if m['kind'] == 'boss': L.append("    isBoss: true,")
    if m['kind'] == 'animal': L += ["    isBeast: true,", "    isAnimal: true,"]
    elif m['id'] in beast: L.append("    isBeast: true,")
    if m['id'] in weak: L.append(f"    weakTo: {weak[m['id']]},")
    L.append("    moves: [")
    L += [f"      {move(n)}," for n in m['moves']]
    L.append("    ],")
    L.append("    loot: {" + ", ".join(f"{q(k)}: {v}" for k, v in m['loot'].items()) + "},")
    if m.get('rare'):
        L += [f"    rareDrop: {q(m['rare'])},", f"    rareDropChance: {m['chance']},"]
    L.append("  ),")
    return "\n".join(L)
mons = [m for m in d['monsters'] if m['kind'] != 'animal']
anim = [m for m in d['monsters'] if m['kind'] == 'animal']
GRP = {'caccia': 'legs', 'prova': 'push'}
enemies = "\n".join(enemy(m, GRP.get(m['group'], m['group'])) for m in mons)
exps = []
for g in d['groups']:
    for e in g['expeditions']:
        steps = "\n".join(
            f"      ExpeditionStep({q(s['monster'])}, {move(s['exercise']['name'])}, level: {s['level']}, tier: {s['tier']}{', veteran: true' if s['veteran'] else ''}),"
            for s in e['steps'])
        c = e['chest']
        rares = ", ".join(f"({q(k)}, {p})" for k, p in c['rares'])
        exps.append(f"""  Expedition(
    id: {q(e['id'])},
    name: {q(e['name'])},
    roman: {q(e['roman'])},
    group: MuscleGroup.{g['id']},
    level: {e['level']},
    blurb: {q(blurbs.get(e['id'], '').replace("\\'", "'"))},
    steps: [
{steps}
    ],
    bossId: {q(e['boss'])},
    chest: Chest(
      name: {q(c['name'])},
      art: {q(c['art'])},
      runes: {c['runes']},
      guaranteed: {{{', '.join(f'{q(k)}: {v}' for k, v in c['guaranteed'].items())}}},
      rares: [{rares}],
    ),
  ),""")
head = old[:old.index("/// I nemici del mondo")]
tail_cls = old[old.index("class Expedition"):old.index("const List<Expedition> expeditions")]
out = head + "/// I nemici del mondo, dal piano dei contenuti: per ogni gruppo quattro\n/// spedizioni con due mostri (che tornano da Veterani) e un boss.\nconst Map<String, EnemyDef> enemyDefs = {\n" + enemies + "\n};\n\n" + "@@EXPCLASS@@" + "const List<Expedition> expeditions = [\n" + "\n".join(exps) + "\n];\n\nList<Expedition> expeditionsOf(MuscleGroup g) =>\n    expeditions.where((e) => e.group == g).toList();\n\nExpedition expeditionById(String id) => expeditions.firstWhere((e) => e.id == id);\n"
open('lib/domain/enemies.dart', 'w').write(out)
hunt = "import 'enemies.dart';\nimport 'exercise.dart';\n\n/// La caccia: animali dei boschi, uno per esercizio base, che lasciano pelle,\n/// ossa ed essenza. Si combattono in libero: rinascono finché non smetti.\nconst List<EnemyDef> huntAnimals = [\n"
for m in anim:
    hunt += enemy(m, 'legs').replace(f"  {q(m['id'])}: EnemyDef(", "  EnemyDef(", 1) + "\n"
hunt += "];\n"
open('lib/domain/hunting.dart', 'w').write(hunt)
json.dump(sorted({v[2] for v in moves.values()}), open('/tmp/claude-0/-home-claude-creazione-gioco-rpg-/1f616d52-03e0-5640-9be4-1ed605abd892/scratchpad/demos.json','w'))
print(len(mons), len(anim), len(exps))
