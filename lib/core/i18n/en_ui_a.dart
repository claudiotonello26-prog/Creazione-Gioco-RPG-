/// Traduzioni inglesi (chiave: il testo italiano usato nel codice).
const Map<String, String> enUiA = {
  // ---- Online: messaggi mostrati al giocatore.
  'Nessun giocatore si chiama {name}.': 'No player is called {name}.',
  'Richiesta di amicizia inviata a {name}.': 'Friend request sent to {name}.',
  '{name} è entrato nella gilda.': '{name} has joined the guild.',
  'Accesso al server non riuscito ({code})': 'Could not sign in to the server ({code})',
  'RPC {id} fallita ({code})': 'RPC {id} failed ({code})',
  'Errore del server ({code})': 'Server error ({code})',
  'Errore del server': 'Server error',
  'Il server non risponde': 'The server is not responding',
  'Connessione chiusa': 'Connection closed',

  // ---- Guida.
  'GUIDA': 'GUIDE',
  '"Ogni abilità è una strada. Qui c\'è scritto dove porta." '
          'Tocca un\'abilità per vedere cosa sblocca, livello per livello.':
      '"Every skill is a road. Here it is written where it leads." '
          'Tap a skill to see what it unlocks, level by level.',
  'Come funziona': 'How it works',
  'Abilità': 'Skills',
  'Quest giornaliera': 'Daily quest',
  'Ogni esercizio della quest si fa combattendo un nemico del tuo livello: le rep contano '
          'per la quest e ogni uccisione lascia bottino. Chiusa la quest ricevi rune, XP, una '
          'Chiave della Spedizione e un forziere di materiali della tua fascia. Lo stretching '
          'finale dà un Punto Disciplina.':
      'Every exercise in the quest is done by fighting an enemy of your level: the reps count '
          'toward the quest and every kill drops loot. Finish the quest and you receive runes, XP, '
          'an Expedition Key and a chest of materials for your tier. The closing stretching '
          'grants a Discipline Point.',
  'Spedizioni': 'Expeditions',
  'Ogni gruppo muscolare ha quattro spedizioni a mappa: quattro tappe, il boss in cima e un '
          'forziere. Sotto il livello consigliato si muore facilmente. "Zavorrato" raddoppia le '
          'rep e il bottino; una Chiave raddoppia il forziere.':
      'Every muscle group has four map expeditions: four stages, the boss at the top and a '
          'chest. Below the recommended level, death comes easily. "Weighted" doubles the reps '
          'and the loot; a Key doubles the chest.',
  'Giuramento e build': 'Oath and build',
  'Ogni gruppo lascia i suoi materiali base (ferro, bronzo, argento, pelle, gemme), utili a '
          'tutti. I componenti di build (Ferro di Brace, Argento di Bufera, Oro Consacrato, '
          'Cristallo d\'Abisso e i loro cuori rari) arrivano invece sempre per la build del tuo '
          'Giuramento, da qualunque gruppo. Così chi gioca Forza non deve fare solo Spinta, e '
          'chi fa cardio non raccoglie roba inutile. Il Giuramento si cambia dalla Home.':
      'Every group drops its own base materials (iron, bronze, silver, leather, gems), useful to '
          'everyone. Build components (Ember Iron, Gale Silver, Hallowed Gold, Abyss Crystal and '
          'their rare hearts), instead, always come for the build of your Oath, whatever the '
          'group. So a Strength player need not do only Push, and whoever does cardio gathers '
          'nothing useless. You change your Oath from the Home.',
  'Caccia e combattimenti liberi': 'Hunts and free fights',
  'Qualunque nemico, anche sopra il tuo livello. Rinasce dopo ogni uccisione e il bottino '
          'si ritira alla fine. La fatica riduce il bottino se insisti troppo sullo stesso '
          'gruppo nello stesso giorno. La caccia infinita chiama nemici sempre più forti.':
      'Any enemy, even above your level. It rises again after every kill and the loot is '
          'collected at the end. Fatigue reduces the loot if you push the same group too hard '
          'on the same day. The endless hunt summons ever stronger enemies.',
  'Postura': 'Stance',
  'Aggressiva: più danni dati e subiti, sale l\'Attacco. Equilibrata: metà e metà. '
          'Difensiva: un quarto di danni in meno, sale la Difesa.':
      'Aggressive: more damage dealt and taken, trains Attack. Balanced: half and half. '
          'Defensive: a quarter less damage taken, trains Defence.',
  'Raccolta': 'Gathering',
  'I passi del giorno (da mezzanotte, fino a un massimo giornaliero) si spendono su una '
          'risorsa: ogni tot passi un\'unità. La Raccolta mostra i passi ancora da consumare. '
          'Le risorse migliori chiedono livello e attrezzo.':
      'The day\'s steps (from midnight, up to a daily cap) are spent on a resource: one unit '
          'every so many steps. Gathering shows the steps you have yet to spend. The best '
          'resources require a level and a tool.',
  'Traguardi di passi': 'Step milestones',
  'Nella Home vedi i passi totali di oggi. A 2.000, 4.000 e 6.000 passi ricevi 20 rune, '
          'a 10.000 (l\'obiettivo consigliato) 40 rune, il doppio. Si riscattano una volta al giorno e '
          'sono a parte dalla quest giornaliera.':
      'The Home shows today\'s total steps. At 2,000, 4,000 and 6,000 steps you receive 20 runes, '
          'at 10,000 (the recommended goal) 40 runes, double. They can be claimed once a day and '
          'are separate from the daily quest.',
  'Incantamento': 'Enchanting',
  'Ogni livello si fa con la sua pietra. Armi normali: Pietra di forgia I fino a +3, '
          'II da +4 a +6, III da +7 a +9, la Pietra di forgia astrale per il +10. Armi speciali '
          '(più rare, con effetti diversi): Pietra delle Tenebre I, II, III, IV per +1..+4 e la '
          'Pietra Epica dell\'Eclissi per il +5. Le pietre delle Tenebre si fondono alla '
          'Fornace partendo dalla precedente.':
      'Every level takes its own stone. Normal weapons: Forge Stone I up to +3, '
          'II from +4 to +6, III from +7 to +9, the Astral Forge Stone for +10. Special weapons '
          '(rarer, with different effects): Somber Stone I, II, III, IV for +1..+4 and the '
          'Epic Eclipse Stone for +5. Somber Stones are smelted at the Furnace, starting from '
          'the previous one.',
  'Amuleti dell\'arma': 'Weapon amulets',
  'Ogni arma ha tre incastri. Il primo è per un amuleto d\'affinità (fuoco, vento, '
          'arcano, luce): dà colore e aura alla lama e la fa crescere con un attributo. A +3 '
          'la lama si tinge, a +6 si accende, a +10 ha l\'aura completa; senza amuleto resta '
          'acciaio. Gli altri due sono passivi (contro i boss, critici, danno). Si mettono e '
          'tolgono dalla Fattucchiera, dall\'Armeria o dall\'Incantamento: quello tolto torna '
          'nella borsa.':
      'Every weapon has three sockets. The first is for an affinity amulet (fire, wind, '
          'arcane, light): it gives the blade colour and aura and makes it scale with an '
          'attribute. At +3 the blade takes on a hue, at +6 it ignites, at +10 it bears the full '
          'aura; without an amulet it stays bare steel. The other two are passives (against '
          'bosses, crits, damage). They are set and removed at the Witch, the Armory or '
          'Enchanting: a removed amulet goes back in your bag.',
  'Mercato': 'Market',
  'Il mercante compra a metà prezzo e vende al doppio. La fattucchiera crea gli amuleti '
          'd\'affinità, vende i passivi e li incastra nell\'arma.':
      'The merchant buys at half price and sells at double. The witch crafts affinity '
          'amulets, sells the passives and sets them into your weapon.',
  'Arena': 'Arena',
  'Sta nel Training, in alto accanto all\'Allenamento. Niente statistiche né build: vince '
          'chi si allena meglio, e le rep scorrette non contano. Il live contro persone vere '
          'richiede la fotocamera.':
      'It lives in Training, at the top next to Workout. No stats, no builds: whoever trains '
          'best wins, and sloppy reps do not count. Live matches against real people require '
          'the camera.',
  'Gilda': 'Guild',
  'Fonda una gilda o entra in quella dei tuoi amici. Fondatore e ufficiali invitano per '
          'nome. Apri un allenamento e fino a quattro membri si uniscono in diretta: chi l\'ha '
          'aperto dà il via. Puoi sfidare un membro: è un duello vero, ma non tocca i punti '
          'dell\'Arena. Serve il server online e la fotocamera.':
      'Found a guild or join your friends\' one. The founder and officers invite by name. '
          'Open a workout and up to four members join live: whoever opened it gives the '
          'signal. You can challenge a member: it is a true duel, but it does not touch your '
          'Arena points. Requires the online server and the camera.',
  'Spendi i passi nei boschi della Raccolta. Ogni albero nuovo chiede '
          'un livello e spesso un\'ascia migliore.':
      'Spend your steps in the woods of Gathering. Every new tree demands a level and often '
          'a better axe.',
  'Spendi i passi nelle cave. Prima pietra e carbone, poi ferro, argento '
          'lunare e minerale stellare.':
      'Spend your steps in the quarries. First stone and coal, then iron, moonsilver and '
          'star ore.',
  'Alla Carpenteria il legno diventa assi, impugnature, archi, bastoni e scudi.':
      'At the Carpentry, wood becomes planks, hilts, bows, staves and shields.',
  'Alla Fornace il minerale diventa lingotti e pietre di forgia.':
      'At the Furnace, ore becomes ingots and forge stones.',
  'All\'Incudine nascono spade, martelli, armature e attrezzi di metallo.':
      'At the Anvil, swords, hammers, armor and metal tools are born.',
  'Cresce colpendo con armi da mischia e a distanza. +2% di danno per livello, '
          'e le armi migliori chiedono un livello minimo per essere impugnate.':
      'Grows by striking with melee and ranged weapons. +2% damage per level, and the best '
          'weapons require a minimum level to wield.',
  'Cresce incassando colpi e tenendo le posizioni. +0,5% di colpi assorbiti per '
          'livello (fino al 30%), e le armature pesanti chiedono un livello minimo.':
      'Grows by taking hits and holding positions. +0.5% of blows absorbed per level (up to '
          '30%), and heavy armor requires a minimum level.',
  'Cresce combattendo con un bastone. Decide quali bastoni puoi impugnare.':
      'Grows by fighting with a staff. It decides which staves you can wield.',
  'Cresce completando le spedizioni e abbattendo i loro boss. Indica il '
          'livello consigliato per ogni mappa.':
      'Grows by completing expeditions and felling their bosses. It marks the recommended '
          'level for every map.',
  ' · serve {tool}': ' · needs {tool}',
  ' (attrezzo)': ' (tool)',
  '{name} · armatura': '{name} · armor',
  'scudo': 'shield',
  'seconda lama': 'second blade',
  'Impugni {name}{rare} · danno {dmg}': 'Wield {name}{rare} · damage {dmg}',
  ' (rara, dai boss)': ' (rare, from bosses)',
  '+{n}% di danno con ogni arma': '+{n}% damage with every weapon',
  'Indossi {name} · assorbe {pct}%': 'Wear {name} · absorbs {pct}%',
  '+{n}% di colpi assorbiti': '+{n}% of blows absorbed',
  'Livello {lvl} · prossimo sblocco al {next}': 'Level {lvl} · next unlock at {next}',
  'Livello {lvl}': 'Level {lvl}',

  // ---- Sentiero.
  'Tappa {n} del sentiero': 'Stage {n} of the path',
  'Il guardiano ti aspetta in cima.': 'The guardian awaits you at the top.',
  'Tappa superata.': 'Stage cleared.',
  'Quasi: riprova la tappa.': 'Almost: try the stage again.',
  '{boss} · esercizio {i}/{n} · {sec} secondi a sfinimento':
      '{boss} · exercise {i}/{n} · {sec} seconds to exhaustion',
  'Il guardiano resta in piedi. Riprova quando vuoi.':
      'The guardian still stands. Try again whenever you like.',
  'GUARDIANO ABBATTUTO': 'GUARDIAN FELLED',
  '{boss} è caduto.': '{boss} has fallen.',
  'CONTINUA': 'CONTINUE',
  'Base': 'Basic',
  'Corpo libero': 'Bodyweight',
  'Profondo': 'Deep',
  'Zavorrato': 'Weighted',
  'Pose più profonde. Il guardiano lascia il doppio del bottino.':
      'Deeper poses. The guardian drops double loot.',
  'Tieni ogni posa: conta restare fermi, non quanto arrivi giù.':
      'Hold every pose: staying still is what counts, not how low you go.',
  'Con sedia, zaino o manubri. Il guardiano lascia il doppio del bottino.':
      'With a chair, backpack or dumbbells. The guardian drops double loot.',
  'Nessun attrezzo: solo il tuo corpo.': 'No equipment: only your body.',
  'Circuito {n}×{sec} s': 'Circuit {n}×{sec} s',
  'Tieni 20 s': 'Hold 20 s',
  '{n} rep': '{n} reps',
  'Sentiero completato oggi. Domani il guardiano torna più affamato.':
      'Path completed today. Tomorrow the guardian returns hungrier.',
  // Esercizi dei sentieri.
  'Push-up': 'Push-up',
  'Push-up larghi': 'Wide push-ups',
  'Pike push-up': 'Pike push-ups',
  'Diamond push-up': 'Diamond push-up',
  'Piegamento in avanti': 'Forward fold',
  'Affondo statico': 'Static lunge',
  'Farfalla': 'Butterfly stretch',
  'Cobra': 'Cobra',
  'Crunch': 'Crunch',
  'Leg raise': 'Leg raise',
  'Plank': 'Plank',
  'V-up': 'V-up',
  'Squat': 'Squat',
  'Affondi': 'Lunges',
  'Ponte per glutei': 'Glute bridge',
  'Jump squat': 'Jump squat',
  'Jumping jack': 'Jumping jack',
  'High knees': 'High knees',
  'Mountain climber': 'Mountain climber',
  'Burpee': 'Burpee',
  'Dip su sedia': 'Chair dips',
  'Push-up con zaino': 'Backpack push-up',
  'Pike push-up piedi sulla sedia': 'Feet-elevated pike push-ups',
  'Floor press con manubri': 'Dumbbell floor press',
  'Posizione del piccione': 'Pigeon pose',
  'Posizione del bambino': 'Child\'s pose',
  'Torsione da seduto': 'Seated twist',
  'Piegamento in avanti a gambe larghe': 'Wide-legged forward fold',
  'Crunch con manubrio': 'Dumbbell crunch',
  'Leg raise con pesi alle caviglie': 'Leg raise with ankle weights',
  'Plank zavorrato': 'Weighted plank',
  'Russian twist con manubrio': 'Dumbbell Russian twist',
  'Squat bulgaro sulla sedia': 'Bulgarian split squat on a chair',
  'Goblet squat con manubrio': 'Dumbbell goblet squat',
  'Affondi con manubri': 'Dumbbell lunges',
  'Step-up sulla sedia': 'Chair step-ups',
  'Burpee con zaino': 'Backpack burpee',
  'Jumping jack con zaino': 'Backpack jumping jack',
  'Thruster con manubri': 'Dumbbell thruster',
  'Squat jump con zaino': 'Backpack squat jump',
  // Guardiani dei sentieri.
  'Il Muro di Ferro': 'The Iron Wall',
  'Il Monaco Contorto': 'The Twisted Monk',
  'Il Nodo di Serpi': 'The Serpent Knot',
  'Il Colosso delle Paludi': 'The Mire Colossus',
  'Il Corridore Cinereo': 'The Ashen Runner',

  // ---- Avvio, questionario e test.
  'Il regno è caduto. Il tuo corpo è l\'ultima arma.':
      'The kingdom has fallen. Your body is the last weapon.',
  'PRIMA DI INIZIARE': 'BEFORE YOU BEGIN',
  'Questo è un gioco, non un consiglio medico. Se hai problemi '
          'di salute, dolori o sei in gravidanza, senti un medico prima '
          'di allenarti. Fermati se senti dolore, vertigini o fiato '
          'corto.\n\nLa fotocamera serve solo a contare le rep: le '
          'immagini restano sul telefono.':
      'This is a game, not medical advice. If you have health problems, pain, or are '
          'pregnant, talk to a doctor before training. Stop if you feel pain, dizziness or '
          'shortness of breath.\n\nThe camera is only used to count reps: the images stay on '
          'your phone.',
  'HO CAPITO, INIZIAMO': 'UNDERSTOOD, LET\'S BEGIN',
  'IL TUO GIURAMENTO': 'YOUR OATH',
  'Nome del tuo eroe': 'Your hero\'s name',
  'Obiettivo': 'Goal',
  'Restare in forma': 'Stay in shape',
  'Perdere peso': 'Lose weight',
  'Diventare più forte': 'Get stronger',
  'Più resistenza': 'More endurance',
  'Giorni a settimana': 'Days per week',
  '{n} giorni': '{n} days',
  'Dolori o limitazioni': 'Pain or limitations',
  'Es. ginocchio destro, spalla… (facoltativo)': 'E.g. right knee, shoulder… (optional)',
  'Modalità di gioco': 'Game mode',
  'Test iniziale, quest del giorno su misura e progressione.':
      'Initial test, a daily quest tailored to you, and progression.',
  'Combatti come vuoi, scegli tu esercizi e mostri.':
      'Fight as you please: you choose the exercises and the monsters.',
  'AL TEST DELLA PROVA': 'TO THE TRIAL TEST',
  'Riscaldamento': 'Warm-up',
  'Jumping jack a ritmo tranquillo: non conta per il test':
      'Jumping jacks at an easy pace: does not count for the test',
  'Più rep corrette possibili in 60 secondi': 'As many correct reps as possible in 60 seconds',
  'Massimo di rep per gamba: prima la destra, poi cambia. Fermati quando la forma cede.':
      'Max reps per leg: right first, then switch. Stop when your form breaks.',
  'Massimo di rep. Fermati quando la forma cede.': 'Max reps. Stop when your form breaks.',
  'Proviamo con: {name}': 'Let\'s try: {name}',
  'TORNEO DELLA PROVA': 'TRIAL TOURNAMENT',
  'TEST DELLA PROVA': 'TRIAL TEST',
  'Il test cerca il tuo massimo: in ogni prova fai più ripetizioni che puoi. '
          'Prima scaldati con 40 secondi di jumping jack, poi si parte dalle gambe.':
      'The test seeks your maximum: in every trial do as many reps as you can. '
          'First warm up with 40 seconds of jumping jacks, then we start with the legs.',
  'INIZIA IL RISCALDAMENTO': 'START THE WARM-UP',
  'Sono già caldo': 'I\'m already warm',
  'Salta il test (valori da principiante)': 'Skip the test (beginner values)',
  'Prova {n} di {total}': 'Trial {n} of {total}',
  'Più ripetizioni che puoi, prima con la destra e poi con la sinistra.':
      'As many reps as you can, first with the right, then with the left.',
  'Più ripetizioni che puoi.': 'As many reps as you can.',
  'Fai più rep corrette possibili in 60 secondi.':
      'Do as many correct reps as possible in 60 seconds.',
  'Tieni la posizione il più a lungo possibile.': 'Hold the position as long as you can.',
  'Appoggia il telefono a terra o su un mobile, a 2–3 metri, in modo '
          'che tutto il corpo sia inquadrato di lato. Serve buona luce.':
      'Place the phone on the floor or on a piece of furniture, 2–3 metres away, so that '
          'your whole body is framed from the side. Good lighting is needed.',
  'Versioni facilitate': 'Easier versions',
  'INIZIA LA PROVA': 'START THE TRIAL',
  'Passa alla versione facilitata': 'Switch to the easier version',
  'Riposo': 'Rest',
  'Salta': 'Skip',
  'IL TUO PUNTO DI PARTENZA': 'YOUR STARTING POINT',
  'Da questi numeri nasce la tua quest giornaliera: il 60% del test, '
          'che salirà del 5% ogni 7 giorni fatti bene.':
      'Your daily quest is born from these numbers: 60% of the test, '
          'rising by 5% every 7 days done well.',
  'Risultati e quest': 'Results and quest',
  'Test: {n} per gamba': 'Test: {n} per leg',
  'Test: {n}': 'Test: {n}',
  'PRESTA GIURAMENTO': 'SWEAR THE OATH',

  // ---- Cammino del Novizio.
  'Missione "{title}" compiuta! {loot}.': 'Mission "{title}" complete! {loot}.',
  '+{n} rune': '+{n} runes',
  'Il Cammino del Novizio è finito. Non sei più un novizio. Sei... appena accettabile. Continua così.':
      'The Novice\'s Path is over. You are no longer a novice. You are... barely acceptable. '
          'Keep it up.',
  'CAMMINO DEL NOVIZIO · {n}/{total}': 'NOVICE\'S PATH · {n}/{total}',
  'RISCUOTI': 'CLAIM',
  'VAI': 'GO',

  // ---- Creazione del personaggio.
  'IL TUO CAVALIERE': 'YOUR KNIGHT',
  'Corpo': 'Body',
  'Uomo': 'Man',
  'Donna': 'Woman',
  'Viso': 'Face',
  'Pelle': 'Skin',
  'Capelli': 'Hair',
  'Occhi': 'Eyes',
  'Barba': 'Beard',
  'Colore': 'Colour',
  'Maglia': 'Shirt',
  'Pantaloni': 'Trousers',
  'AVANTI': 'NEXT',
  'Aspetto aggiornato.': 'Appearance updated.',

  // ---- Impostazioni.
  'IMPOSTAZIONI': 'SETTINGS',
  'Conta le rep con la fotocamera': 'Count reps with the camera',
  'Spento: inserimento manuale, rep non verificate': 'Off: manual entry, unverified reps',
  'Consigli del Comandante Reynard': 'Commander Reynard\'s tips',
  'Riaccendendolo, rivedi tutti i consigli dall\'inizio':
      'Turning it back on shows all the tips again from the start',
  'Server dell\'Arena live': 'Live Arena server',
  'Non impostato': 'Not set',
  'Rifai il test': 'Retake the test',
  'Ricalcola la quest sui tuoi numeri di oggi': 'Recalculate the quest from today\'s numbers',
  'Ricomincia da capo': 'Start over',
  'Server dell\'Arena': 'Arena server',
  'es. arena.iron-oath.it oppure 192.168.1.10:7350': 'e.g. arena.iron-oath.it or 192.168.1.10:7350',
  'Annulla': 'Cancel',
  'Salva': 'Save',
  'Ricominciare?': 'Start over?',
  'Perderai eroe, progressi e record salvati su questo telefono.':
      'You will lose your hero, progress and records saved on this phone.',
  'Ricomincia': 'Start over',
  'Effetti sonori': 'Sound effects',
  'Musica': 'Music',
  'Voce del Comandante Reynard': 'Commander Reynard\'s voice',
  // ---- Creazione del personaggio: teste disegnate.
  'ASPETTO': 'LOOK',
  'Rasata': 'Shaved',
  'Rasata, sorriso': 'Shaved, smiling',
  'Rasata, fiera': 'Shaved, proud',
  'Corti': 'Short',
  'Coda alta': 'High ponytail',
  'Cresta intrecciata': 'Braided crest',
  'Lunghi mossi': 'Long and wavy',
  'Treccia': 'Braid',
  'Caschetto': 'Bob',
  'Rasato': 'Shaved',
  'Rasato, sorriso': 'Shaved, smiling',
  'Corti pettinati': 'Short and combed',
  'Spettinati e barba corta': 'Tousled, short beard',
  'Chignon e barba': 'Bun and beard',
  'Cresta e pizzetto': 'Mohawk and goatee',
  'Mossi con baffi': 'Wavy, moustache',
  'Treccine': 'Cornrows',
  'Lunghi con baffi': 'Long, moustache',
  'Spettinati': 'Tousled',
  'Chignon': 'Bun',
  'Cresta': 'Mohawk',
  'Mossi': 'Wavy',
  'Lunghi': 'Long',
  'Nessuna': 'None',
  'Corta': 'Short',
  'Folta': 'Full',
  'Pizzetto e baffi': 'Goatee and moustache',
  'Baffi e pizzetto': 'Moustache and goatee',
  'Baffi': 'Moustache',
};
