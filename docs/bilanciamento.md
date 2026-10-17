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
| Sforzo | vita del nemico ÷ (20 × fattore gradino), tra 0,5 e 5 | Paghi le rep reali: un test basso dà nemici corti che pagano meno a uccisione, e una vita in più in caccia paga di più. |
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

## 4. Camminata

| Passi di oggi | Ricompensa |
|---|---|
| Ogni 1000 | 1 Minerale di ferro |
| Ogni 2500 | 1 Legno di frassino cenere |
| 5000 | Pietra di forgia I |
| 10000 | Pietra di forgia I e Scheggia sacra |
| 15000 | Pietra di forgia II |
| 20000 | Pietra antica |

- Il tetto è 25.000 passi al giorno.
- Si conta dal totale del giorno, quindi riscuotere più volte non raddoppia nulla.

## Dove sta nel codice

- `lib/domain/combat.dart`:
  - per la difficoltà: `hitDamage`, rigenerazione e `wave`;
  - per le ricompense: `effortFactor`, `averageQuality`, `waveBonus` e `lootBonus`.
- `lib/domain/enemies.dart`: `pressure` e `runeReward`.
- `lib/data/game_state.dart`: `fatigueAt` e `applyCombatRewards`.
- `lib/domain/walking.dart`: la Camminata.
- Test: `test/combat_test.dart`, `test/economy_test.dart` e `test/walking_test.dart`. La tabella qui sopra la stampa il test "tabella di bilanciamento".
