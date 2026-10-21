# Bilanciamento: sforzo, difficoltà e ricompense

Regola di fondo: **si guadagna per ogni rep fatta bene, non per ogni mostro ucciso.** Chi fa più rep, con forma migliore, contro nemici più duri e cambiando gruppo muscolare prende di più. Ripetere lo stesso esercizio facile al minimo dello sforzo rende sempre meno.

## 1. Quanto è duro un mostro

- **Vita del nemico** = rep previste = test × fattore del gradino (0,60 / 0,68 / 0,75 / 0,88 / 1,00; boss ×1,6). In caccia infinita la vita sale del 20% a ondata.
- **Danno del nemico**: è tarato perché l'eroe base (Vigore 10, 140 di vita) muoia dopo *rep previste × 2,2 s × pressione*.
  - La pressione per gradino è 1,9 / 1,75 / 1,6 / 1,45 / 1,35; i boss hanno ×0,9.
  - Il nemico attacca in media ogni 4 s (boss ogni 3,5 s), ma il colpo vero arriva a un momento a caso fra metà e una volta e mezzo l'intervallo. **Non c'è barra dell'attacco**: lo si sente arrivare.
  - **Critici del nemico**: 8% dei colpi (boss 15%) fanno ×1,8. Il danno base è diviso per (1 + probabilità × 0,8), così in media il nemico fa lo stesso danno di prima: cambia solo la varianza. Il critico si vede («CRITICO -n», più grande e arancio) e fa vibrare il telefono.
  - In caccia il danno sale del 10% a ondata.
  - **Divario di livello**: un nemico sopra il tuo livello colpisce più forte, +9% per ogni livello di distanza (composto): 5 livelli ×1,5, 10 livelli ×2,4, 20 livelli ×5,6. Allo stesso livello o sotto non cambia niente. Un personaggio appena creato (livello 1, senza armatura, 140 di vita) prende 13 danni dai boss di livello 9 (11 colpi), 39 da quelli di livello 22 (4 colpi), 190 da quelli di livello 41 e oltre 1.400 da quelli di livello 65: un colpo solo. Il simulatore lo controlla dal livello 40 in su.
- **Ruota degli elementi**: ogni nemico ha l'elemento del suo gruppo (Spinta = Fuoco, Gambe = Vento, Core = Luce, Cardio = Arcano; lo Stretching nessuno). La tua build ha quello del Giuramento (Forza Fuoco, Destrezza Vento, Fede Luce, Intelligenza Arcano). L'Arcano batte il Fuoco, il Fuoco il Vento, il Vento la Luce, la Luce l'Arcano.
  - Il nemico che batte la tua build ti fa **+30%** di danno, quello che la tua build batte **−15%**.
  - Un'arma il cui elemento (aura dell'amuleto d'affinità, se no lo scaling) batte il nemico fa +15% di danno a rep, quella battuta −15%.
  - Sui nemici normali tutto vale a metà, sui boss per intero.
  - Contromisure: **Talismano** al collo contro un elemento (−25% di danno da quell'elemento) e **Gemma del flagello** nell'arma (+20% di danno a rep contro quell'elemento). Con entrambi un Forza contro un boss Arcano passa da +30%/−15% a −2,5%/+5%.
  - È l'unica eccezione alla regola d'oro «la build non toglie rep»: con la gemma giusta un boss elementare cade con qualche rep in meno.
  - In combattimento sotto la barra della vita del nemico c'è il suo simbolo con scudo e spada colorati (verde conviene, rosso no) e la percentuale.
- **Se ti fermi più di 3 secondi** il nemico recupera il 3% della vita al secondo, quindi non si vince facendo una rep ogni tanto.
- **Effetto pratico** con il goblin e un test di 20:
  - con una rep ogni 2 s vinci con poco margine;
  - con una rep ogni 4,5 s muori (YOU DIED).
  - Il Vigore e l'arma potenziata danno margine.

## 2. Quanto paga una vittoria

Rune e materiali = base del nemico × **sforzo** × **forma** × **ondata** × (1 + bonus arma).

| Fattore | Formula | Perché |
|---|---|---|
| Sforzo | vita del nemico × difficoltà della versione ÷ (20 × fattore gradino), tra 0,5 e 5 | Paghi le rep reali: un test basso dà nemici corti che pagano meno a uccisione, una vita in più in caccia paga di più, e 8 pike push-up (difficoltà 2,5) pagano come 20 push-up. La versione facile non rende più di quella dura. |
| Forma | media della qualità delle rep (perfetta 1, buona 0,85, scarsa 0,6) | Le mezze rep non contano affatto e le rep sporche pagano meno. |
| Ondata | 1 + 10% per ondata | Premio di rischio sopra la vita in più, che è già pagata dallo sforzo. |
| Bonus arma | potere oltre la difesa, massimo +25% | Resta un piccolo bonus, così farmare nemici deboli con un'arma enorme non conviene. |

Le rune base per gradino sono 20 / 40 / 65 / 95 / 130, ×3 per i boss. Crescono più in fretta delle rep richieste, quindi **un nemico più duro paga di più per ogni rep**.

### Comuni, non comuni e rari

Ogni mostro ha tre liste corte:

- **Comuni**: una o due risorse, che escono **a ogni vittoria** nelle quantità mostrate (poi scalate da sforzo e forma).
- **Non comuni** (da 1 a 4: pietre di forgia, schegge sacre, gemme grezze e tagliate, impugnature) solo dai mostri dal **livello 5**.
- **Rari** (al massimo 2: pietre alte, gemme pure, cuori, amuleti, armi speciali) solo dal **livello 10**.

Animali e mostri bassi danno solo comuni. Sopra, a volte la vittoria **si trasforma**: al posto dei comuni esce un pezzo non comune o raro. La probabilità cresce in modo esponenziale col livello del mostro: 4% al livello 5, poi +4,5% composto a livello (5% al 10, 8% al 22, 20% al 41, tetto 35%), ×1,5 per boss e Veterani, ×1,35 a ondata in caccia infinita. Fra i pezzi speciali, la quota dei rari va dall'8% al livello 10 fino al 35%.

| Mostro | Su 300 vittorie: comuni / non comuni / rari |
|---|---|
| Goblin (liv. 1) | 300 / 0 / 0 |
| Scriba Annegato (liv. 10) | 285 / 14 / 1 |
| Carceriere del Bastione (liv. 19) | 278 / 20 / 3 |
| Fuochista Incatenato (liv. 29) | 265 / 29 / 6 |
| Inquisitore Nero (liv. 45) | 230 / 48 / 22 |
| Gargoyle della Cattedrale (liv. 50) | 213 / 57 / 30 |

Le probabilità di ogni pezzo si vedono nella scheda del mostro e nel Codice. Codice: `EnemyDef.commonLoot`, `uncommonLoot`, `rareLoot`, `specialChance`, `rareShare` e `dropRarity` in `lib/domain/enemies.dart`.

### Rune per rep, con test 20 e rep perfette (dai test automatici)

| Nemico | Rep | Danno nemico | Rune per rep |
|---|---|---|---|
| Goblin Svuotato (gradino 1) | 12 | 11 ogni 4 s | 2,3 |
| Segugio della Carogna (gradino 2) | 14 | 10 ogni 4 s | 3,9 |
| Cavaliere Caduto (gradino 3) | 15 | 11 ogni 4 s | 5,0 |
| Viverna di Cenere (gradino 5) | 20 | 9 ogni 4 s | 5,4 |
| Signore della Rocca (boss) | 24 | 6 ogni 3,5 s | 9,6 |

### Caccia infinita: goblin a ondate

| Ondata | Vita | Danno | Rune per rep |
|---|---|---|---|
| 1 | 12 | 11 | 2,3 |
| 4 | 19 | 15 | 3,1 |
| 7 | 26 | 18 | 3,8 |
| 11 | 36 | 22 | 4,8 |

La vita dell'eroe torna piena a ogni ondata. Il danno però cresce, quindi a ritmo normale l'eroe base cade intorno alla 3ª–4ª ondata, e tenendo il ritmo alto si va oltre.

## 3. Fatica: perché non conviene ripetere sempre lo stesso esercizio

Per ogni gruppo muscolare (spinta, gambe, core…) si contano le rep di combattimento del giorno:

| Rep del gruppo oggi | Rune e materiali |
|---|---|
| 0–59 | 100% |
| 60–119 | 60% |
| 120 e oltre | 30% |

- Gli **XP restano sempre interi**, perché sono la salute; cala solo il bottino.
- Cambiando gruppo si torna al 100%.
- A fine combattimento appare un avviso arancione quando il bottino è stato ridotto.
- Si aggiunge al Bonus Varietà già esistente: le prime 20 rep di ogni gruppo al giorno valgono XP doppi.

## 4. Camminata: raccolta dei materiali

Come su Gymscape, i passi si accumulano in una riserva e si convertono nel materiale che scegli. Ogni materiale ha un livello minimo di mestiere.

| Materiale | Mestiere | Livello | Passi per unità |
|---|---|---|---|
| Legno di frassino | Taglialegna | 1 | 40 |
| Legno di quercia | Taglialegna | 5 | 70 |
| Legno di tasso | Taglialegna | 12 | 110 |
| Resina di bufera | Taglialegna | 14 | 140 |
| Legno d'ebano | Taglialegna | 20 | 180 |
| Carbone | Minatore | 1 | 30 |
| Minerale di ferro | Minatore | 1 | 50 |
| Minerale di rame | Minatore | 4 | 60 |
| Argento lunare | Minatore | 8 | 90 |
| Minerale d'oro | Minatore | 10 | 110 |
| Vena di brace | Minatore | 14 | 140 |
| Minerale stellare | Minatore | 16 | 150 |
| Geode d'abisso | Minatore | 18 | 170 |
| Ossidiana viva | Minatore | 22 | 200 (Piccone stellare) |

- Il tetto è 25.000 passi al giorno; i passi già riscossi non si contano due volte.
- Raccogliere dà XP al mestiere. XP per livello: 40 × livello^1,5, fino al livello 30. Gli XP per unità sono stati ridotti del 40% quando sono arrivati i minerali alti: prima il Minatore arrivava al 30 in un mese e mezzo.
- Attrezzi: Accetta e Piccone stellari (Incudine 20) raccolgono il 60% in più e servono per l'Ossidiana viva.
- La Raccolta mostra solo i passi ancora da consumare (riserva + passi nuovi). Il totale del giorno si vede nella Home.

### Traguardi di passi del giorno

Quattro tappe nella Home, a parte dalla quest giornaliera, per spingere a camminare (10.000 è l'obiettivo consigliato):

| Passi totali oggi | Rune |
|---|---|
| 2.000 | 20 |
| 4.000 | 20 |
| 6.000 | 20 |
| 10.000 | 40 (il doppio) |

Totale massimo 100 rune al giorno, quanto un nemico debole: un premio piccolo ma costante. Si riscattano con un tocco e si azzerano a mezzanotte. Nel codice: `stepMilestones` e `stepMilestoneRunes` in `lib/domain/walking.dart`.

## 5. Mestieri e forgia

- Quattro stazioni: Carpenteria (assi, impugnature, archi, bastoni), Fornace (lingotti, pietre di forgia), Incudine (spade, armature) e Incantamento.
- Ogni ricetta ha un livello minimo del mestiere della stazione. Creare dà 8 + 3 × livello della ricetta in XP di mestiere; le lavorazioni (lingotti, assi, materiali speciali) lo moltiplicano per la materia prima consumata ÷ 10, fino a ×4: un lingotto di ferro (30 pezzi) vale il triplo. Prima la Fornace saliva dieci volte più piano del Minatore che la riforniva.
- Le armature riducono il danno subito: Gambeson 8%, Cotta di Maglia 15%, Piastre del Templare 22%, Armatura Stellare 30%.
- **Materiali speciali alla Fornace**: oltre a cadere dai mostri, i materiali delle build si fondono dai minerali dei passi.

| Materiale | Fornace | Ricetta |
|---|---|---|
| Lingotto di bronzo | 4 | 15 Minerale di rame + 5 Carbone |
| Lingotto d'oro | 10 | 20 Minerale d'oro + 10 Carbone |
| Ferro di Brace (Forza) | 15 | 15 Vena di brace + 1 Acciaio + 10 Carbone |
| Argento di Bufera (Destrezza) | 15 | 2 Argento lunare + 10 Resina di bufera |
| Oro Consacrato (Fede) | 15 | 2 Lingotti d'oro + 2 Schegge sacre |
| Cristallo d'Abisso (Intelligenza) | 17 | 12 Geode d'abisso + 10 Carbone |
| Acciaio della Fucina Divina | 24 | 2 Ferro di Brace + 1 Lingotto stellare |
| Piuma d'Acciaio | 24 | 2 Argento di Bufera + 1 Lingotto stellare + 5 Resina |
| Ossidiana del Martire | 24 | 12 Ossidiana viva + 1 Oro Consacrato |
| Ferro Stellare | 24 | 2 Cristalli d'Abisso + 1 Lingotto stellare |

- **Qualità della forgia** per armi e armature: Grezza al livello della ricetta, Buona 5 livelli sopra, Fine 10, Capolavoro 15; il 20% delle volte il martello azzecca un grado in più. Ogni grado vale +6% di attacco o di protezione (Capolavoro +18%). Un'armatura già tua si può **riforgiare** quando la Forgiatura la farebbe di un grado migliore. In Forgia e in Armeria il grado si vede come tre rombi colorati.
- **Manutenzione (leggera)**: ogni scontro consuma 1 punto dell'arma impugnata e, se il nemico ti ha colpito, 1 di ogni armatura indossata. Fino a 60 punti non cambia niente; da 60 a 100 attacco o protezione calano fino al −20%. Non si rompe mai. In Forgia c'è un solo tasto «Manutenzione» che ripara tutto: costa usura × (2 + livello di forgia × 0,4) rune e dà 2 XP di Forgiatura per punto. Il simulatore misura che costi fra il 3% e il 25% delle rune (oggi circa il 5%, una riparazione a settimana) e che si giochi raramente con l'equipaggiamento consumato.
- Incantamento: ogni livello ha la sua pietra, mostrata come pulsante con l'icona, e un costo in rune (sezione 9).
  - Armi normali (fino a +10): Pietra di forgia I per +1..+3 (1, 2, 3 pietre), II per +4..+6, III per +7..+9, Pietra di forgia astrale (1) per il +10.
  - Armi speciali (fino a +5, non per forza più forti ma con effetti diversi): Pietra delle Tenebre I, II, III, IV per +1..+4 e Pietra Epica dell'Eclissi per il +5, una pietra per livello. Alla Fornace: Tenebre II = 2 Tenebre I + 1 Scheggia sacra (liv. 10), III = 2 II + 3 Essenza di bestia (14), IV = 2 III + 1 Gemma tagliata (18), Epica = 2 IV + 1 Gemma perfetta (22).
- Amuleti dell'arma: tre incastri per arma, dalla Fattucchiera (o dall'Armeria e dall'Incantamento). Si cambiano quando si vuole; quello tolto torna nella borsa.
  - Incastro 1, affinità (uno solo): fuoco, vento, arcano o luce. Dà colore e aura alla lama e aggiunge scaling C sul suo attributo (Forza, Destrezza, Intelligenza, Fede). A +3 la lama si tinge, a +6 si accende, a +10 aura piena. Senza amuleto d'affinità la lama resta acciaio: il colore non dipende dall'attributo più alto.
  - Incastri 2 e 3, passivi: Sigillo del Regicida +5% contro i boss (700 rune), Zanna del Lupo Grigio +10% danno dei critici (650), Sigillo del Giuramento +5% danno (500), più quelli dei forzieri (Fervente, Colosso, Cacciatore, Martire, Insonne). Qui vanno anche le **Gemme del flagello** contro un elemento.
  - Al collo: un passivo o un **Talismano** contro un elemento (i talismani solo al collo, le gemme solo nell'arma).
  - Gemme e talismani si creano dalla Fattucchiera con una gemma dello Stretching e i materiali comuni del gruppo di quell'elemento: contro il Fuoco ossa e acciaio delle Forge, contro il Vento pelli e cuoio, contro la Luce bronzo e oro, contro l'Arcano inchiostro d'abisso e argento. Gemma = 1 Gemma tagliata + materiali; Talismano = 1 Gemma pura + materiali.

## 6. Sentieri di allenamento e boss

- Ogni gruppo muscolare ha un sentiero di 4 esercizi a corpo libero e poi il boss. Il livello Zavorrato usa sedia o manubri.
- Un esercizio passa all'80% delle rep richieste.
- Boss: circuito dei 4 esercizi, 30 secondi ciascuno fino allo sfinimento. Il premio arriva sempre, indipendentemente dalle rep.
- Premio boss (doppio nello Zavorrato): 3 Essenze di bestia, 3 Minerali di ferro, 2 Carboni, 1 Pietra di forgia I e 150 XP. Rari: Scheggia sacra 30% (50%), Pietra antica 6% (12%), Pietra cupa 3% (6%).

## 7. Andamento della forza

Ogni serie (quest, combattimenti, sentieri, boss e test) finisce nello storico, giorno per giorno ed esercizio per esercizio.

- **Rep equivalenti** = rep × difficoltà, rispetto alla versione base dell'esercizio.
  - Le versioni facilitate valgono 0,6 per ogni gradino in giù: push-up sulle ginocchia 0,6, inclinati 0,36, al muro 0,22.
  - Negli esercizi dei sentieri la difficoltà è quella della tua versione divisa per il loro rapporto: il pike push-up (0,4) vale 2,5 push-up.
  - Il plank conta 1 rep ogni 2 secondi.
- **Indice di forza** di una zona (Parte alta, Core, Gambe) = la serie migliore del periodo in rep equivalenti, divisa per quella del primo test, × 100. La zona fa la media dei suoi esercizi.
  - 100 vuol dire forte come al primo giorno, 130 vuol dire il 30% in più.
  - Se fai meno rep ma di una versione più dura, l'indice sale lo stesso: 14 push-up pieni battono 20 sulle ginocchia (14 contro 12).
- Il grafico mostra gli ultimi 14 giorni, 12 settimane o 12 mesi. Il cardio conta nelle rep totali ma non nell'indice di forza.
- Nel dettaglio di ogni esercizio: rep nel periodo, record in una serie, ultima serie migliore e confronto con la media delle volte precedenti.

## 8. Forzieri delle spedizioni

- Le mappe si azzerano ogni giorno e si possono rifare. Il forziere dà le rune piene **solo la prima volta** che lo apri; le volte dopo dà il 25% delle rune. Materiali garantiti e rari restano uguali.
- Prima i forzieri ripetuti davano il 70-78% di tutte le rune dei giocatori simulati, più di tutti i combattimenti messi insieme.
- Nel codice: `chestRepeatRunes` e `openChest` in `lib/data/game_state.dart`.

## 9. Simulatore di bilanciamento

Cinque giocatori finti giocano 90 giorni con il codice vero del gioco (GameState, CombatEngine, forgia, passi, spedizioni, caccia), a ogni `flutter test` e quindi a ogni push in CI. Ogni notte gira anche una versione lunga: 365 giorni, tre partite per profilo (workflow «Bilanciamento», lanciabile anche a mano).

| Profilo | Test | Ritmo | Allenamento | Passi |
|---|---|---|---|---|
| Principiante | 8 rep | 2,8 s, 35% perfette | 3 giorni, 80 rep | 4.000 |
| Medio | 20 rep | 2,2 s, 55% perfette | 3 giorni, 150 rep | 8.000 |
| Costante | 20 rep | 2,0 s, 60% perfette | 5 giorni, 200 rep | 10.000 |
| Atleta | 40 rep | 1,6 s, 75% perfette | 6 giorni, 350 rep | 12.000 |
| Furbo | 20 rep | 2,0 s, 20% perfette | 5 giorni, 200 rep solo push-up | 3.000 |

Ogni giocatore fa la quest, lo stretching, la spedizione del gruppo del giorno, poi caccia o farma il materiale che gli manca; dopo l'allenamento spende i punti attributo, forgia l'arma e l'armatura migliori per la sua build, potenzia l'arma e compra amuleti.

Il simulatore controlla, e la CI fallisce se trova un BLOCCO:

- **Muri**: una spedizione consigliata al tuo livello che non finisci entro 28 giorni; una postazione della forgia che dopo 30 giorni non arriva al livello 3.
- **Scorciatoie**: la versione facile di un esercizio che rende più di 1,25× per unità di sforzo; il furbo che prende più del 90% per rep del giocatore medio; i forzieri oltre il 60% delle rune; guadagni sicuri comprando, forgiando e rivendendo al Mercante.
- **Velocità**: il giocatore medio deve arrivare al livello 10 fra il giorno 4 e il 35.
- **Ruota degli elementi**: a 45, 90, 180, 270 e 364 giorni ogni giocatore affronta il boss più alto fino a 4 livelli sopra di sé, otto volte per ogni caso, cambiando solo l'elemento (a favore, neutro, contro, contro con talismano e gemma). Contro l'elemento che ti batte devi perdere almeno il 10% di vita in più del neutro (se no la ruota non si sente, avviso); con talismano e gemma al massimo il 25% in più e non più di 15 punti di vittorie in meno (BLOCCO). Oggi: ×1,4–1,6 di vita persa contro, ×0,9–1,0 con le contromisure; il principiante al giorno 45 vince 2 su 8 contro e 8 su 8 con le contromisure.
- **Critici**: il colpo singolo più forte di quel boss, con l'elemento neutro, non deve togliere più del 60% della vita (BLOCCO; avviso oltre il 45%). Oggi al massimo il 16%.
- **Manutenzione**: le riparazioni devono costare fra il 3% e il 25% delle rune (BLOCCO oltre il 40%) e i giorni chiusi con l'equipaggiamento già indebolito non oltre il 20%.
- **Mestieri**: per ogni profilo il giorno in cui Minatore, Taglialegna, Fusione e Forgiatura arrivano ai livelli che sbloccano minerali e materiali speciali, il primo materiale di build fuso e quanti pezzi escono Grezzi, Buoni, Fini o Capolavori. In un anno di build: Minatore 14 al giorno 10, 22 al 33, 30 al 70; Fusione 15 (materiali di build) fra il 48 e il 58, 24 (secondo grado) verso il 100.

Il rapporto completo (progressione, fonti di XP e rune, spedizioni, mestieri, ritmo minimo per vincere ogni gradino) si legge nel riepilogo della CI e in `build/balance/report.md`.

Cosa ha già trovato e corretto:

1. **Incudine bloccata al livello 1**: il Giaco si forgia una volta sola e nient'altro all'Incudine si faceva sotto il livello 3, quindi armature e armi di Forza e Fede non arrivavano mai. Lo Spadone del Penitente ora è al livello 1 di Incudine: si può forgiare più volte (e rivendere al valore dei materiali) per far salire la postazione.
2. **Forzieri ripetuti**: vedi sezione 8.
3. **Versioni facili più convenienti**: lo sforzo ora conta la difficoltà della versione (sezione 2).

4. **Rune senza uso**: dopo 90 giorni il giocatore medio aveva 115.000 rune e ne aveva spese 2.400. Ora ogni potenziamento dell'arma costa anche rune: 80 × livello^1,6 × (1 + livello di forgia dell'arma ÷ 6), il quintuplo per le armi speciali. La Lama del Pellegrino da +0 a +10 costa circa 16.000 rune in tutto (il +10 da solo 3.700), un'arma di livello 20 quasi quattro volte tanto. Il costo si vede sotto la pietra, all'Incantamento. Il simulatore controlla che si spenda almeno un quinto delle rune.

### Build a confronto (Forza, Destrezza, Fede, Intelligenza)

Altri quattro giocatori, uno per giuramento, con lo stesso impegno (test 20, 4 giorni a settimana, 180 rep, 9.000 passi), giocano un anno intero a ogni `flutter test` (pochi secondi). Ognuno mette due punti su tre nell'attributo della build e uno in Vigore, forgia l'arma migliore che riesce a fare adesso (scelta per quanto varrà a +10, non per com'è appena forgiata) e l'armatura della sua build. Dal giorno 90 in poi l'attacco della build più forte non deve superare di oltre il 30% quello della più debole (BLOCCO; avviso oltre il 15%). Nel primo mese è solo un avviso: le armi della build arrivano a giorni diversi. Rapporto in `build/balance/builds.md`.

Un controllo statico sulla **collezione** verifica che ogni materiale chiesto da armi, armature, mani sinistre, pietre, amuleti e ricette di ogni build cada da qualche parte (mostri, forzieri, contratti, quest, boss, passi, Mercante o un'altra ricetta): uno introvabile è un BLOCCO, uno che non serve a niente un avviso.

| Build | Giorno 30 | Giorno 90 | Giorno 180 | Giorno 365 |
|---|---|---|---|---|
| Forza | liv. 21, att. 136 | liv. 32, att. 375 | liv. 42, att. 725 | liv. 56, att. 807 |
| Destrezza | liv. 21, att. 106 | liv. 32, att. 336 | liv. 42, att. 697 | liv. 56, att. 775 |
| Fede | liv. 21, att. 131 | liv. 32, att. 367 | liv. 42, att. 725 | liv. 56, att. 807 |
| Intelligenza | liv. 21, att. 98 | liv. 32, att. 354 | liv. 42, att. 706 | liv. 56, att. 776 |

Cosa ha trovato e corretto la simulazione lunga:

5. **Attributi senza tetto**: a fine anno l'attributo della build arrivava a 270 e la Fede, moltiplicata dall'armatura del Martire, faceva il doppio di danno delle altre. Ora ogni attributo si ferma a **99** (il «+» si spegne); i punti in più vanno in Vigore e Tempra.
6. **La Magia non contava**: bastoni e catalizzatori allenano la Magia, ma il bonus di danno guardava il livello di Attacco, fermo a 10. Ora l'attacco mostrato e quello in combattimento usano la Magia per le armi magiche.
7. **Incudine ferma al livello 6**: forgiare un'arma, un'armatura o una mano sinistra dava solo il triplo dell'XP di un lingotto. Ora vale **dieci volte** (`gearCraftXpFactor`): gli oggetti costano materiali rari e si fanno di rado.
8. **Intelligenza lenta all'inizio**: il Bastone della Brace aveva il danno base più basso (16) e chiedeva 6 Essenze di bestia. Ora danno 22, ricetta 4 Assi di frassino + 3 Essenze.
9. **Materiali solo da vendere**: Gemma grezza, Lingotto d'oro e Osso non servivano a niente. Ora alla Fornace 3 Gemme grezze fanno una Gemma tagliata (liv. 8), 3 tagliate una pura (14), 3 pure una perfetta (20); le Piastre del Templare chiedono 2 Lingotti d'oro; l'Impugnatura rinforzata 2 Ossa. Resta solo la Perla dei sogni (rara, per ora si vende).

10. **Minatore finito in un mese e mezzo, Fornace ferma**: con i minerali alti il Minatore arrivava al 30 al giorno 45 mentre la Fusione restava sotto il 15 per quattro mesi, e nessuno fondeva i materiali speciali prima del giorno 135. Ora la raccolta dà il 40% di XP in meno e le lavorazioni pesano la materia prima consumata: il Minatore arriva al 30 verso il giorno 70 e la Fusione al 15 verso il 50.
11. **Ruota degli elementi**: con +30% di danno subito il principiante perdeva 6 boss su 8 contro l'elemento che lo batte. Talismano e gemma li riportano a 8 su 8, alla pari del neutro.

Da guardare (non ancora toccato): dopo un anno ogni build tiene più di un milione di rune, perché quando l'arma è a +10 non c'è più niente di caro da comprare; e lo stretching dà circa un terzo dell'XP totale.

## Dove sta nel codice

- `lib/domain/combat.dart`:
  - per la difficoltà: `hitDamage`, rigenerazione e `wave`;
  - per le ricompense: `effortFactor`, `averageQuality`, `waveBonus` e `lootBonus`.
- `lib/domain/enemies.dart`: `pressure`, `runeReward`, `critChance`, `element` ed `elementWeight`.
- `lib/domain/combat.dart`: `elementTakenMult`, `elementDamageMult`, `_nextAttackDelay` (attacchi a tempo casuale).
- `lib/domain/items.dart`: `Affinity.beats` (ruota), `CraftQuality`, `conditionFactor` e `repairCost` (manutenzione), gemme e talismani in `amuletDefs` e `amuletRecipes`.
- `lib/data/game_state.dart`: `fatigueAt` e `applyCombatRewards`.
- `lib/domain/skills.dart`: materiali raccoglibili e curva dei mestieri.
- `lib/domain/items.dart`: ricette, stazioni e armature.
- `lib/data/game_state.dart`: `claimSteps`, `craftMaterial`, `bossLoot` e `logSet`.
- `lib/domain/progress.dart`: storico, rep equivalenti e indice di forza.
- Simulatore: `test/balance/simulator.dart` (giocatori e build), `test/balance/analysis.dart` (controlli e soglie, classe `Targets`), `test/balance/obtainability.dart` (collezione), `test/balance/balance_test.dart` (avvio).
- Test: `test/combat_test.dart`, `test/economy_test.dart` e `test/walking_test.dart`. La tabella qui sopra la stampa il test "tabella di bilanciamento".
