# HANDOVER DI PROGETTO: "GYM OATH" — MODULAR KNIGHT & ASSET PIPELINE

Questo documento contiene tutte le informazioni per riprendere istantaneamente il lavoro sulla nuova macchina con Antigravity.

---

## 1. Obiettivo Generale e Contesto
- **Progetto:** "Gym Oath" — Mobile Dark Fantasy Medieval Fitness RPG.
- **Repository Git:** `Creazione-Gioco-RPG-`
- **Branch attivo:** `art/antigravity`
- **Stile Artistico Rigoroso:**
  - Illustrazione 2D stile fumetto / concept art per mobile game dark fantasy.
  - **Inchiostrazione marcata:** Tratto nero d'inchiostro netto e continuo su silhouette ed elementi interni.
  - **Colorazione & Shading:** Cel-shading pittorico ad alto contrasto, ombre carbone profondo (`#0D0B09`), luce di taglio oro antico/ambra (`#C9A24A`).
  - **NO 3D CGI / aerografo realistico**, **NO stile Disney / cartoon piatto da supereroe**.
  - **Eroi positivi ed espressivi:** Coraggiosi, fieri, atletici e carismatici (fitness atletico da spadaccino/amazzone medievale, NON culturisti gonfiati da palestra moderna).

---

## 2. Stato Attuale del Lavoro

### A. Creature & Boss (100% COMPLETATO)
- Tutti i **67 mostri e boss** sono stati generati, scontornati da magenta `#FF00FF`, ripuliti da qualsiasi alone rosa (`pink_pixels <= 3`), verificati nella griglia master `check_cutout.png`, registrati nel `manifest.json` e pushati su GitHub.

### B. Basi Eroi Uomo & Donna (PERFEZIONATE)
- Le nuove basi modulari rispecchiano il design della base iniziale che piaceva all'utente, ma disegnate nello **stesso identico stile inchiostrato dei mostri** (`ref_cinder_boss.jpg` e `ref_fallen_knight.png`):
  - **Uomo:** Fisico atletico snello e agile da spadaccino (non supereroe palestrato), viso nobile giovanile, testa rasata neutra (silhouette pronta per parrucche ed elmi), camicia di lino grezzo aderente con scollo a V, pantaloni marroni, guanti in pelle e stivali alti con risvolto.
  - **Donna:** Fisico tonico e armonioso da amazzone/paladina, viso splendido e fiero, testa rasata neutra, camicia di lino con scollo a V, pantaloni marroni, guanti e stivali.
  - File pronti in `pipeline/current_bases/`:
    - `hero_male_base.png` (1024x1024 RGBA)
    - `hero_female_base.png` (1024x1024 RGBA)
    - `preview_heroes.jpg` (anteprima bilanciata su fondo scuro)

---

## 3. Struttura dei File nella Cartella `pipeline/`

```text
Creazione-Gioco-RPG-/
├── assets/art/knight/          # Cartella finale degli asset di gioco
├── pipeline/
│   ├── current_bases/          # Basi Uomo e Donna approvate
│   │   ├── hero_male_base.png
│   │   ├── hero_female_base.png
│   │   └── preview_heroes.jpg
│   ├── references/             # Immagini di riferimento stile e personaggio
│   │   ├── ref_cinder_boss.jpg
│   │   ├── ref_fallen_knight.png
│   │   ├── ref_old_male_base.png
│   │   └── ref_old_female_base.png
│   ├── scripts/
│   │   ├── chroma_processor.py              # Script di ritaglio automatico chroma key magenta
│   │   └── generate_knight_customizer.py   # Script principale di generazione tramite Gemini API
│   └── output/                 # Cartella dove vengono salvati gli asset generati
```

---

## 4. Istruzioni e Dipendenze sul Nuovo PC

1. **Requisiti Python:**
   ```bash
   pip install pillow numpy scipy
   ```
   *(Nota: Il processore chroma key usa solo numpy, pillow e scipy, senza bisogno di modelli AI pesanti).*

2. **Chiave API:**
   Impostare la variabile d'ambiente `GEMINI_API_KEY`:
   - PowerShell: `$env:GEMINI_API_KEY="LA_TUA_CHIAVE"`
   - CMD: `set GEMINI_API_KEY=LA_TUA_CHIAVE`
   *(Modello utilizzato: `gemini-2.5-flash-image` via Google AI Studio).*

3. **Esecuzione dello Script di Personalizzazione:**
   Dalla cartella `Creazione-Gioco-RPG-/pipeline/scripts/`:
   ```bash
   python generate_knight_customizer.py all
   ```
   Comandi specifici supportati:
   - `python generate_knight_customizer.py faces` -> Genera i 4 visi maschio e femmina.
   - `python generate_knight_customizer.py hair` -> Genera le 5 pettinature maschio e femmina.
   - `python generate_knight_customizer.py beards` -> Genera i 5 stili di barba/baffi maschio.

---

## 5. Prossimi Passi da Eseguire

1. **Generazione e Ritaglio Componenti Modulari:**
   - **4 Visi:**
     1. Solare / Sorridente (Carismatico ed energico)
     2. Fiero / Determinato (Smirk da guerriero, sguardo affilato)
     3. Severo / Grintoso (Grit da battaglia, denti stretti)
     4. Calmo / Nobile (Compostezza da paladino)
   - **5 Pettinature (Uomo & Donna):**
     - Uomo: Pompadour/spettinato, Codino da guerriero (Topknot), Undercut con treccia, Chioma selvaggia, Buzzcut texture.
     - Donna: Coda di cavallo alta, Treccia laterale valchiria, Bob asimmetrico, Lunghi mossi ondulati, Pixie cut.
   - **5 Barbe/Baffi (Uomo):**
     - Incolta (Stubble), Baffi a manubrio fieri, Pizzo curato, Barba piena da cavaliere, Barba vichinga con treccia e anelli di ferro.
2. **Slicing & Registrazione Coordinate:**
   - Ritagliare i singoli sprite dai fogli generati e salvarli sia come layer full-canvas (1024x1024 trasparenti a offset zero) per lo stacking immediato in gioco (`Stack([base, face, beard, hair, armor])`), sia come sprite isolati con bounding-box JSON.
3. **Pezzi d'Armatura Modulari (Set Cavaliere):**
   - Disegnare le armature del Cavaliere (Tier 1 Gambeson, Tier 2 Cuoio, Tier 3 Maglia di Ferro / Piastre) direttamente sagomate sulle nuove silhouette delle basi.
