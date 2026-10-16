# Iron Oath — Fitness RPG dark fantasy

App per **Android e iOS** in cui ti alleni davvero davanti alla fotocamera: ogni
ripetizione fatta bene è un colpo del tuo eroe. Ispirata a GymScape, con stile
dark fantasy alla souls e un PvP di puro allenamento.

La specifica è il documento di progetto
"Fitness RPG medievale – Documento di progetto" (Claude Docs). *Iron Oath* è il
nome di lavoro, ancora da decidere.

## Cosa c'è già

| Area | Contenuto |
| --- | --- |
| Onboarding | Avviso di salute, questionario (obiettivo, 2–6 giorni, limitazioni), modalità **Percorso** o **Libera** |
| Test della Prova | 6 esercizi con la fotocamera, versioni facilitate automatiche se non fai nemmeno una rep, pause, ritest ogni 4 settimane |
| Quest giornaliera | 60% del test (minimo 3), divisibile in più serie, stretching obbligatorio, +5% ogni 7 giorni fatti bene, proposta della versione più dura, sostituzione solo per dolore dichiarato |
| Conteggio rep | ML Kit Pose Detection sul telefono, angoli delle articolazioni + macchina a stati, qualità perfetta/buona/scarsa, mezze rep scartate, rep troppo veloci scartate. Inserimento manuale per emulatori |
| Combattimento | Vita del nemico calibrata sul tuo test, rep perfette = critici, Rampage fino a +20%, posture, attacchi a tempo, difesa del nemico (i colpi rimbalzano se la build è debole), fuga tenendo gli XP |
| Build (PvE) | 6 attributi, Punti Disciplina dallo stretching, armi con scaling S–E, potenziamento +0/+10 (rare +0/+5) con pietre di forgia, amuleti, perk a scelta definitiva |
| PvE | Combattimenti liberi, 2 spedizioni (4 tappe + boss) con la Chiave della Spedizione, una al giorno |
| Arena Pura (PvP) | Sfide del documento (20 push-up, 30 squat, 60 s di jumping jack, plank…), divisioni per esercizio, punti stagione, spareggio sulla forma. Avversario per ora "fantasma" locale |
| Schermate | Home, Allenati, Forgia, Arena, Profilo (mappa del corpo, record, attributi, impostazioni) |

Salvataggio locale sul telefono (`shared_preferences`).

## Cosa manca (prossimi passi dalla roadmap)

- Calibrazione del contatore su telefoni reali (obiettivo errore < 5%).
- Illustrazioni 2D e animazioni Spine al posto delle silhouette vettoriali.
- Backend (account, gilde, classifiche) e **PvP live** con trasmissione dei soli punti dello scheletro.
- Passi da Apple Health / Health Connect per la raccolta, abbonamento con RevenueCat.
- Campagna a capitoli, dungeon infiniti, boss di gilda, eventi stagionali.

## Stack

Flutter + Flame (scena 2D) + ML Kit Pose Detection (sul telefono, nessun video
al server). Android minSdk 24, iOS 15.5.

## Avviare il progetto

```bash
flutter pub get
flutter test          # regole di gioco, contatore rep, PvP, salvataggi
flutter run           # su un telefono collegato
```

Su emulatore la fotocamera spesso non c'è: in **Profilo → Conta le rep con la
fotocamera** passa all'inserimento manuale.

La CI (GitHub Actions) esegue analisi e test e compila un APK di debug
scaricabile dagli artifact della run. La compilazione iOS senza firma si
lancia a mano da *Actions → CI → Run workflow*.

## Struttura

```
lib/
  domain/   regole pure: esercizi, routine, personaggio, oggetti, nemici, combattimento, PvP
  pose/     scheletro, contatore di rep, fotocamera + ML Kit
  data/     stato del gioco e salvataggio
  game/     scena di battaglia con Flame
  ui/       schermate e widget
test/       test unitari e di interfaccia
```
