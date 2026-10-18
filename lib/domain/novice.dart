/// Il Cammino del Novizio: le prime missioni guidate dal trainer, una alla
/// volta, che insegnano il gioco come la quest iniziale di Gymscape.
/// Dove porta il pulsante della missione.
enum NoviceAction {
  arm,
  fightGoblin,
  dailyQuest,
  walk,
  carpentry,
  furnace,
  anvil,
  training,
  attributes,
  enchant,
  market,
  hunt,
}

class NoviceQuest {
  const NoviceQuest({
    required this.title,
    required this.goal,
    required this.trainer,
    required this.stat,
    required this.target,
    required this.action,
    this.runes = 0,
    this.loot = const {},
    this.gather,
  });

  final String title;

  /// Cosa fare, in breve.
  final String goal;

  /// Cosa dice il trainer quando la missione si apre.
  final String trainer;

  /// Contatore di GameState.stats da raggiungere.
  final String stat;
  final int target;
  final NoviceAction action;
  final int runes;
  final Map<String, int> loot;

  /// Per le missioni di camminata: cosa scegliere da raccogliere.
  final String? gather;
}

const List<NoviceQuest> noviceQuests = [
  NoviceQuest(
    title: 'Armati',
    goal: 'Prendi spada e scudo ed equipaggiali',
    trainer: 'A mani nude non vai da nessuna parte. Tieni: la Lama del Pellegrino '
        'e uno Scudo di Quercia. Non sono un granché, ma sono tuoi.',
    stat: 'armed',
    target: 1,
    action: NoviceAction.arm,
    runes: 20,
  ),
  NoviceQuest(
    title: 'Primo sangue',
    goal: 'Batti il Goblin Svuotato a colpi di squat',
    trainer: 'Ogni mostro si batte col suo esercizio: il goblin con gli squat. '
        'Ogni rep fatta bene è un colpo di spada. Fammi vedere.',
    stat: 'wins',
    target: 1,
    action: NoviceAction.fightGoblin,
    runes: 60,
    loot: {'beast_essence': 2},
  ),
  NoviceQuest(
    title: 'Il giuramento del giorno',
    goal: 'Completa la quest giornaliera',
    trainer: 'Ogni giorno una quest: pochi esercizi, tutto il corpo. Fatta quella, '
        'il giorno è tuo e il calendario si accende d\'oro.',
    stat: 'quests',
    target: 1,
    action: NoviceAction.dailyQuest,
    runes: 80,
    loot: {'ash_wood': 20},
  ),
  NoviceQuest(
    title: 'Passi di cenere',
    goal: 'Raccogli 40 Legni di frassino camminando',
    trainer: 'Un cavaliere cammina. Collega i passi e scegli il bosco: ogni 40 '
        'passi è un ciocco di frassino.',
    stat: 'gather:ash_wood',
    target: 40,
    action: NoviceAction.walk,
    gather: 'ash_wood',
    runes: 40,
  ),
  NoviceQuest(
    title: 'Il primo attrezzo',
    goal: 'Costruisci il Piccone di frassino in Carpenteria',
    trainer: 'Il ferro sta sotto la roccia, e con le unghie non ci arrivi. '
        'Un\'asse e venti ciocchi, ed ecco il tuo primo piccone.',
    stat: 'craft:ash_pickaxe',
    target: 1,
    action: NoviceAction.carpentry,
    loot: {'coal': 10},
  ),
  NoviceQuest(
    title: 'Sotto la roccia',
    goal: 'Raccogli 20 Minerali di ferro camminando',
    trainer: 'Ora il piccone ce l\'hai. Nella Camminata scegli la miniera e '
        'cammina: 50 passi, un minerale.',
    stat: 'gather:iron_ore',
    target: 20,
    action: NoviceAction.walk,
    gather: 'iron_ore',
    runes: 50,
    loot: {'coal': 10},
  ),
  NoviceQuest(
    title: 'Fuoco e metallo',
    goal: 'Fondi un Lingotto di ferro in Fornace',
    trainer: 'Minerale e carbone, dentro la Fornace. Il ferro si piega solo a chi '
        'ha pazienza.',
    stat: 'craft:iron_ingot',
    target: 1,
    action: NoviceAction.furnace,
    loot: {'ash_wood': 20, 'beast_essence': 2},
  ),
  NoviceQuest(
    title: 'Ferro addosso',
    goal: 'Forgia il Giaco Imbottito all\'Incudine',
    trainer: 'Andare in giro senza armatura è coraggioso. Anche stupido. '
        'Forgiamoci un Giaco Imbottito.',
    stat: 'craft:gambeson',
    target: 1,
    action: NoviceAction.anvil,
    runes: 80,
  ),
  NoviceQuest(
    title: 'Il primo sentiero',
    goal: 'Supera una tappa di un sentiero di allenamento',
    trainer: 'I sentieri salgono a tappe: quattro esercizi a corpo libero e un '
        'guardiano in cima. Comincia dalla prima.',
    stat: 'path_steps',
    target: 1,
    action: NoviceAction.training,
    runes: 40,
    loot: {'iron_ore': 20, 'coal': 20},
  ),
  NoviceQuest(
    title: 'Più forte',
    goal: 'Assegna un punto attributo',
    trainer: 'Ogni livello ti dà un punto. Vigore per resistere, Forza o Destrezza '
        'per colpire. Scegli la tua strada.',
    stat: 'attr',
    target: 1,
    action: NoviceAction.attributes,
    loot: {'forge_stone_1': 1},
  ),
  NoviceQuest(
    title: 'Lama affilata',
    goal: 'Potenzia l\'arma a +1 all\'Incantamento',
    trainer: 'Le pietre di forgia risvegliano l\'arma. A +3 cambia colore, a +6 '
        'si accende, a +10 ha la sua aura.',
    stat: 'upgrades',
    target: 1,
    action: NoviceAction.enchant,
    runes: 100,
    loot: {'forge_stone_1': 1},
  ),
  NoviceQuest(
    title: 'Il guardiano',
    goal: 'Sconfiggi il guardiano in cima a un sentiero',
    trainer: 'Il guardiano non si batte con la forza ma col fiato: 30 secondi per '
        'esercizio, senza fermarti. Il bottino arriva comunque.',
    stat: 'boss_wins',
    target: 1,
    action: NoviceAction.training,
    runes: 150,
    loot: {'holy_shard': 1},
  ),
  NoviceQuest(
    title: 'Al mercato',
    goal: 'Vendi un materiale al Mercante',
    trainer: 'Quello che avanza diventa rune. Il Mercante compra tutto, a metà '
        'prezzo. Non dirgli che te l\'ho detto.',
    stat: 'sell',
    target: 1,
    action: NoviceAction.market,
    runes: 60,
  ),
  NoviceQuest(
    title: 'La caccia',
    goal: 'Arriva all\'ondata 3 della Caccia infinita',
    trainer: 'Nella caccia ogni nemico abbattuto ne chiama uno più forte. Più '
        'resisti, più è probabile che lascino qualcosa di raro.',
    stat: 'hunt_wave',
    target: 3,
    action: NoviceAction.hunt,
    runes: 120,
    loot: {'forge_stone_2': 1},
  ),
  NoviceQuest(
    title: 'Il giuramento',
    goal: 'Completa 3 quest giornaliere',
    trainer: 'Ultima prova, novizio: la quest giornaliera. Oggi, domani e il '
        'giorno dopo. È questo il giuramento.',
    stat: 'quests',
    target: 3,
    action: NoviceAction.dailyQuest,
    runes: 250,
    loot: {'forge_stone_2': 1, 'holy_shard': 1},
  ),
];
