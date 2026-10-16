# Icona dell'app

Elmo templare oro su fondo scuro, disegnato in SVG (`helm.js`) e reso con Chromium (`render.js`).
Icona provvisoria: verrà sostituita dall'icona generata con Antigravity (`assets/art/ui/app_icon.png`).

Rigenerare: `node render.js` (richiede Playwright), poi ridimensionare `icon_full.png`, `icon_fg.png`
e `icon_bg.png` nelle cartelle `android/app/src/main/res/mipmap-*` e in `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
