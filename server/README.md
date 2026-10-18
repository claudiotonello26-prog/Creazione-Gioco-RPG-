# Server dell'Arena live

Modulo [Nakama](https://heroiclabs.com/nakama/) che gestisce i duelli live
dell'Arena Pura.

- **Duelli autoritativi**: il matchmaker abbina due giocatori sullo stesso
  esercizio e il server crea il duello (`arena_duel`).
- **Solo scheletro, niente video**: il telefono invia ~10 volte al secondo i
  13 punti dello scheletro normalizzati; il server li inoltra all'avversario,
  che li usa per animare l'avatar.
- **Anti-cheat**: una rep dichiarata vale solo se lo scheletro, dopo l'ultima
  rep, è sceso sotto la soglia e risalito, con un ritmo umano (≥ 350 ms).
  Le rep rifiutate tornano al telefono (op 13).
- **Classifiche**: punti stagione (`arena_season`, +25 / −15 / +5, reset ogni
  2 mesi) e record per esercizio (`arena_best_<esercizio>`). Chi abbandona
  perde a tavolino.
- **RPC**: `arena_profile` (punti, titolo, posizione) e `arena_top`
  (prime 20 posizioni, di stagione o di un esercizio).

## Gilde

- Le gilde sono i **gruppi** di Nakama: creazione, ricerca, ingresso, inviti
  (`/v2/group/{id}/add`), membri e uscita passano dalle API REST standard;
  gli amici da `/v2/friend`.
- **Sfida tra amici** (`guild_session_create` con `mode: "friendly"` e
  `opponent`): duello a due senza punti stagione né record; l'avversario
  riceve una notifica (codice 100) con l'id del duello.
- **Allenamento di gilda** (`guild_session_create` con `mode: "group"`):
  fino a quattro membri, parte al via di chi l'ha aperto (op 4), alla fine
  una classifica senza vincitore.
- `guild_sessions` elenca allenamenti aperti e sfide in attesa della gilda,
  solo per chi ne fa parte. Le partite private aspettano fino a 5 minuti.

Le soglie degli angoli e le regole delle sfide specchiano quelle dell'app
(`lib/pose/rep_counter.dart`, `lib/domain/pvp.dart`): vanno cambiate insieme.

## Protocollo

| Op | Direzione | Contenuto |
| --- | --- | --- |
| 1 READY | client → server | `{}` |
| 2 POSE | client → server | `{"k": [[x, y, prob], …13]}` |
| 3 REP | client → server | `{"q": "perfect" \| "good" \| "poor"}` |
| 4 START | client → server | allenamento di gilda: il via di chi l'ha aperto |
| 10 STATE | server → client | fase, conto alla rovescia, tempo, rep per giocatore |
| 11 RESULT | server → client | vincitore, risultati, punti |
| 12 POSE | server → client | scheletro dell'avversario `{"u", "k"}` |
| 13 REP_REJECTED | server → client | rep non valida |

## Avvio

```bash
npm ci
npm run build                 # compila src/ in build/index.js
docker compose up -d          # Nakama + PostgreSQL sulla porta 7350
```

## Online (produzione)

Su un server Linux nuovo (Ubuntu 24.04, 2 GB di RAM bastano), da root:

```bash
curl -fsSL https://raw.githubusercontent.com/claudiotonello26-prog/Creazione-Gioco-RPG-/main/server/deploy/install.sh | bash
```

Lo script installa Docker, scarica il codice, crea le password in
`/opt/gym-oath/server/.env` e avvia Nakama, PostgreSQL e Caddy
(`docker-compose.prod.yml`). Caddy prende da solo il certificato HTTPS:
senza un dominio usa `<ip-con-trattini>.sslip.io`, che è gratis. Android
accetta solo HTTPS, quindi nell'app va scritto `https://<host>`.
Rilanciare lo script aggiorna il server all'ultimo codice del ramo
(`BRANCH=altro-ramo` per usarne un altro).

## Test

```bash
node --test test/arena.test.js                                   # regole e duello, senza server
NAKAMA_URL=http://127.0.0.1:7350 node --test test/integration.test.js   # contro un Nakama vero
```
