# Bilanciamento: sforzo, difficoltà e ricompense

Regola di fondo: **si guadagna per ogni rep fatta bene, non per ogni mostro ucciso.** Chi fa più rep, con forma migliore, contro nemici più duri e cambiando gruppo muscolare prende di più. Ripetere lo stesso esercizio facile al minimo dello sforzo rende sempre meno.

## 1. Quanto è duro un mostro

- **Vita del nemico** = rep previste = test × fattore del gradino (0,60 / 0,68 / 0,75 / 0,88 / 1,00; boss ×1,6). In caccia infinita la vita sale del 20% a ondata.
- **Danno del nemico**: è tarato perché l'eroe base (Vigore 10, 140 di vita) muoia dopo *rep previste × 2,2 s × pressione*.
  - La pressione per gradino è 1,9 / 1,75 / 1,6 / 1,45 / 1,35; i boss hanno ×0,9.
  - Il nemico attacca ogni 4 s (boss ogni 3,5 s).
  - In caccia il danno sale del 10% a ondata.
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
| Legno d'ebano | Taglialegna | 20 | 180 |
| Carbone | Minatore | 1 | 30 |
| Minerale di ferro | Minatore | 1 | 50 |
| Argento lunare | Minatore | 8 | 90 |
| Minerale stellare | Minatore | 16 | 150 |

- Il tetto è 25.000 passi al giorno; i passi già riscossi non si contano due volte.
- Raccogliere dà XP al mestiere. XP per livello: 40 × livello^1,5, fino al livello 30.
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
- Ogni ricetta ha un livello minimo del mestiere della stazione. Creare dà 8 + 3 × livello della ricetta in XP di mestiere.
- Le armature riducono il danno subito: Gambeson 8%, Cotta di Maglia 15%, Piastre del Templare 22%, Armatura Stellare 30%.
- Incantamento: ogni livello ha la sua pietra, mostrata come pulsante con l'icona, e un costo in rune (sezione 9).
  - Armi normali (fino a +10): Pietra di forgia I per +1..+3 (1, 2, 3 pietre), II per +4..+6, III per +7..+9, Pietra di forgia astrale (1) per il +10.
  - Armi speciali (fino a +5, non per forza più forti ma con effetti diversi): Pietra delle Tenebre I, II, III, IV per +1..+4 e Pietra Epica dell'Eclissi per il +5, una pietra per livello. Alla Fornace: Tenebre II = 2 Tenebre I + 1 Scheggia sacra (liv. 10), III = 2 II + 3 Essenza di bestia (14), IV = 2 III + 1 Gemma tagliata (18), Epica = 2 IV + 1 Gemma perfetta (22).
- Amuleti dell'arma: tre incastri per arma, dalla Fattucchiera (o dall'Armeria e dall'Incantamento). Si cambiano quando si vuole; quello tolto torna nella borsa.
  - Incastro 1, affinità (uno solo): fuoco, vento, arcano o luce. Dà colore e aura alla lama e aggiunge scaling C sul suo attributo (Forza, Destrezza, Intelligenza, Fede). A +3 la lama si tinge, a +6 si accende, a +10 aura piena. Senza amuleto d'affinità la lama resta acciaio: il colore non dipende dall'attributo più alto.
  - Incastri 2 e 3, passivi: Sigillo del Regicida +5% contro i boss (700 rune), Zanna del Lupo Grigio +10% danno dei critici (650), Sigillo del Giuramento +5% danno (500), più quelli dei forzieri (Fervente, Colosso, Cacciatore, Martire, Insonne).

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

Da guardare (non ancora toccato): dopo un anno ogni build tiene più di un milione di rune, perché quando l'arma è a +10 non c'è più niente di caro da comprare; e lo stretching dà circa un terzo dell'XP totale.

## Dove sta nel codice

- `lib/domain/combat.dart`:
  - per la difficoltà: `hitDamage`, rigenerazione e `wave`;
  - per le ricompense: `effortFactor`, `averageQuality`, `waveBonus` e `lootBonus`.
- `lib/domain/enemies.dart`: `pressure` e `runeReward`.
- `lib/data/game_state.dart`: `fatigueAt` e `applyCombatRewards`.
- `lib/domain/skills.dart`: materiali raccoglibili e curva dei mestieri.
- `lib/domain/items.dart`: ricette, stazioni e armature.
- `lib/data/game_state.dart`: `claimSteps`, `craftMaterial`, `bossLoot` e `logSet`.
- `lib/domain/progress.dart`: storico, rep equivalenti e indice di forza.
- Simulatore: `test/balance/simulator.dart` (giocatori e build), `test/balance/analysis.dart` (controlli e soglie, classe `Targets`), `test/balance/obtainability.dart` (collezione), `test/balance/balance_test.dart` (avvio).
- Test: `test/combat_test.dart`, `test/economy_test.dart` e `test/walking_test.dart`. La tabella qui sopra la stampa il test "tabella di bilanciamento".
