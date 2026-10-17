/// Il Cammino del Novizio: le prime missioni guidate dal trainer, una alla
/// volta, che insegnano il gioco come la quest iniziale di Gymscape.
class NoviceQuest {
  const NoviceQuest({
    required this.title,
    required this.goal,
    required this.trainer,
    required this.stat,
    required this.target,
    this.runes = 0,
    this.loot = const {},
  });

  final String title;

  /// Cosa fare, in breve.
  final String goal;

  /// Cosa dice il trainer quando la missione si apre.
  final String trainer;

  /// Contatore di GameState.stats da raggiungere.
  final String stat;
  final int target;
  final int runes;
  final Map<String, int> loot;
}

const List<NoviceQuest> noviceQuests = [
  NoviceQuest(
    title: 'Primo sangue',
    goal: 'Vinci un combattimento (Allenati › Combattimenti liberi)',
    trainer: 'Ogni rep fatta bene è un colpo di spada. Scegli un nemico debole e '
        'mostrami di che pasta sei fatto.',
    stat: 'wins',
    target: 1,
    runes: 60,
    loot: {'beast_essence': 2},
  ),
  NoviceQuest(
    title: 'Il sentiero',
    goal: 'Supera due tappe di un sentiero di allenamento',
    trainer: 'I sentieri salgono a tappe: quattro esercizi a corpo libero e un '
        'boss in cima. Comincia dalle prime due.',
    stat: 'path_steps',
    target: 2,
    runes: 40,
    loot: {'iron_ore': 3, 'coal': 2},
  ),
  NoviceQuest(
    title: 'Taglialegna',
    goal: 'Raccogli 4 Legno di frassino camminando',
    trainer: 'Un cavaliere cammina. Collega i passi nella Camminata e scegli il '
        'bosco: ogni 400 passi è un ciocco di frassino.',
    stat: 'gather:ash_wood',
    target: 4,
    runes: 50,
  ),
  NoviceQuest(
    title: 'Mani da falegname',
    goal: 'Crea 2 Assi di frassino in Carpenteria',
    trainer: 'Il legno grezzo non serve a niente. In Forgia, Carpenteria: due assi, '
        'e senza schegge, mi raccomando.',
    stat: 'craft:ash_plank',
    target: 2,
    loot: {'beast_essence': 1},
  ),
  NoviceQuest(
    title: 'Il fuoco della fornace',
    goal: 'Fondi un Lingotto di ferro in Fornace',
    trainer: 'Minerale di ferro e carbone, dentro la Fornace. Il ferro si piega '
        'solo a chi ha pazienza.',
    stat: 'craft:iron_ingot',
    target: 1,
    loot: {'coal': 2, 'iron_ore': 2},
  ),
  NoviceQuest(
    title: 'Prima armatura',
    goal: 'Forgia il Giaco Imbottito all\'Incudine',
    trainer: 'Andare in giro senza armatura è coraggioso. Anche stupido. '
        'Forgiamoci un Giaco Imbottito.',
    stat: 'craft:gambeson',
    target: 1,
    runes: 80,
  ),
  NoviceQuest(
    title: 'Crescere',
    goal: 'Spendi un punto in Attributi',
    trainer: 'Ogni livello ti dà un punto. Vigore per resistere, Forza o Destrezza '
        'per colpire. Scegli la tua strada.',
    stat: 'attr',
    target: 1,
    loot: {'forge_stone_1': 1},
  ),
  NoviceQuest(
    title: 'Il risveglio della lama',
    goal: 'Potenzia l\'arma a +1 in Incantamento',
    trainer: 'Le pietre di forgia risvegliano l\'arma. A +3 cambia colore, a +6 '
        'si accende, a +10 ha la sua aura.',
    stat: 'upgrades',
    target: 1,
    runes: 100,
    loot: {'forge_stone_1': 1},
  ),
  NoviceQuest(
    title: 'Il guardiano',
    goal: 'Completa il circuito del boss in cima a un sentiero',
    trainer: 'Il boss non si batte con la forza ma col fiato: 30 secondi per '
        'esercizio, senza fermarti. Ci vediamo dall\'altra parte.',
    stat: 'boss_wins',
    target: 1,
    runes: 150,
    loot: {'holy_shard': 1},
  ),
  NoviceQuest(
    title: 'Il giuramento',
    goal: 'Completa la quest giornaliera',
    trainer: 'Ultima prova, novizio: la quest giornaliera. Fallo oggi, e domani, '
        'e il giorno dopo. È questo il giuramento.',
    stat: 'quests',
    target: 1,
    runes: 200,
    loot: {'forge_stone_2': 1},
  ),
];
