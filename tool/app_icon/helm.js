// Elmo templare a linee: tratti oro sfumati e luminosi su nero, sagoma
// affusolata e fessure degli occhi inclinate verso il centro (sguardo
// aggressivo). Restituisce SVG 1024×1024, elmo centrato in (512,512).
function strokes() {
  return `
    <!-- sagoma: calotta arrotondata, guance che si stringono fino al mento a punta -->
    <path d="M512 150 C 640 150 718 236 728 360 L 736 560 C 738 650 690 740 512 878
             C 334 740 286 650 288 560 L 296 360 C 306 236 384 150 512 150 Z"/>
    <!-- seconda linea interna, più sottile -->
    <path class="thin" d="M512 196 C 616 196 680 266 688 368 L 694 556 C 696 630 656 704 512 820
             C 368 704 328 630 330 556 L 336 368 C 344 266 408 196 512 196 Z"/>
    <!-- cresta centrale (braccio verticale della croce) -->
    <path d="M512 150 L 512 410"/>
    <path d="M512 548 L 512 878"/>
    <!-- fascia della fronte a V (braccio orizzontale della croce) -->
    <path d="M300 404 L 512 450 L 724 404"/>
    <!-- fessure degli occhi inclinate -->
    <path class="eye" d="M338 452 L 486 496 L 478 520 L 346 488 Z"/>
    <path class="eye" d="M686 452 L 538 496 L 546 520 L 678 488 Z"/>
    <!-- prese d'aria: tagli obliqui sulle guance -->
    <path class="thin" d="M400 600 L 450 640 M 392 640 L 442 680 M 388 680 L 434 716"/>
    <path class="thin" d="M624 600 L 574 640 M 632 640 L 582 680 M 636 680 L 590 716"/>
  `;
}

function defs() {
  return `
  <defs>
    <linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="0" y1="150" x2="0" y2="880">
      <stop offset="0" stop-color="#FFF3C8"/>
      <stop offset="0.35" stop-color="#E9C873"/>
      <stop offset="0.75" stop-color="#B8862E"/>
      <stop offset="1" stop-color="#5E4214"/>
    </linearGradient>
    <radialGradient id="eyeGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FFE7A0"/>
      <stop offset="1" stop-color="#E0A040" stop-opacity="0"/>
    </radialGradient>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="14"/>
    </filter>
    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="3"/>
    </filter>
  </defs>
  <style>
    .lines path { fill: none; stroke: url(#gold); stroke-width: 14; stroke-linecap: round; stroke-linejoin: round; }
    .lines path.thin { stroke-width: 6; opacity: 0.8; }
    .lines path.eye { fill: #FFE29A; stroke-width: 6; }
  </style>`;
}

function background() {
  return `<rect width="1024" height="1024" fill="#000"/>
  <radialGradient id="bgGlow" cx="0.5" cy="0.45" r="0.55">
    <stop offset="0" stop-color="#2A1E0C" stop-opacity="0.9"/>
    <stop offset="1" stop-color="#000" stop-opacity="0"/>
  </radialGradient>
  <rect width="1024" height="1024" fill="url(#bgGlow)"/>`;
}

function svg({ bg = true, scale = 1 } = {}) {
  const t = `translate(512 512) scale(${scale}) translate(-512 -514)`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  ${defs()}
  ${bg ? background() : ''}
  <g transform="${t}">
    <g class="lines" filter="url(#glow)" opacity="0.75">${strokes()}</g>
    <g class="lines" filter="url(#soft)" opacity="0.6">${strokes()}</g>
    <g class="lines">${strokes()}</g>
    <ellipse cx="420" cy="486" rx="90" ry="22" fill="url(#eyeGlow)" opacity="0.5" transform="rotate(16 420 486)"/>
    <ellipse cx="604" cy="486" rx="90" ry="22" fill="url(#eyeGlow)" opacity="0.5" transform="rotate(-16 604 486)"/>
  </g>
</svg>`;
}

module.exports = { svg, background: () => `<defs/>${background()}` };
