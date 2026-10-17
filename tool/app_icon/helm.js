// Elmo da cavaliere (armet con visiera a becco, ispirato alla foto di
// riferimento dell'utente) disegnato a sole linee oro nette e luminose su
// nero. Metà destra disegnata, la sinistra è lo specchio. SVG 1024×1024.
function half() {
  // bordo della visiera: da (700,486) al becco (512,800)
  const edgeX = (y) => 700 - (y - 486) * (188 / 314);
  const holes = [];
  for (let r = 0; r < 6; r++) {
    const y = 540 + r * 36;
    for (let c = 0; c < 4; c++) {
      const x = 546 + c * 34;
      if (x < edgeX(y) - 26) holes.push(`<circle class="dot" cx="${x}" cy="${y}" r="6.5"/>`);
    }
  }
  const rivets = [[600, 404], [690, 396], [612, 868], [668, 842]]
    .map(([x, y]) => `<circle class="dot" cx="${x}" cy="${y}" r="7"/>`).join('');
  return `
    <!-- calotta a punta con cresta -->
    <path d="M512 112 C 536 172 588 206 640 238 C 712 282 742 356 744 430 L 740 560 C 738 620 730 680 712 716"/>
    <!-- bordo della visiera fino al becco -->
    <path d="M700 486 L 512 800"/>
    <path d="M744 470 L 700 486 L 700 700"/>
    <!-- fascia della fronte -->
    <path d="M512 418 C 600 410 680 400 744 388"/>
    <!-- fessura dell'occhio inclinata verso il becco -->
    <path class="eye" d="M548 458 L 704 432 L 702 456 L 552 482 Z"/>
    <!-- linea della cresta laterale -->
    <path class="thin" d="M540 150 C 590 230 616 310 622 400"/>
    <!-- perno della visiera -->
    <circle cx="744" cy="430" r="16"/>
    <!-- gorgiera: due fasce -->
    <path d="M512 800 L 640 772 C 676 764 700 744 712 716"/>
    <path d="M512 842 C 600 840 680 818 726 772 L 736 812 C 690 862 604 888 512 890"/>
    ${holes.join('')}
    ${rivets}
  `;
}

function strokes() {
  return `
    <path d="M512 112 L 512 418"/>
    <path class="thin" d="M512 482 L 512 800"/>
    <g>${half()}</g>
    <g transform="translate(1024 0) scale(-1 1)">${half()}</g>`;
}

function defs() {
  return `
  <defs>
    <linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="0" y1="110" x2="0" y2="900">
      <stop offset="0" stop-color="#FFF6D2"/>
      <stop offset="0.3" stop-color="#F2D27E"/>
      <stop offset="0.7" stop-color="#D2A040"/>
      <stop offset="1" stop-color="#8E6420"/>
    </linearGradient>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="10"/>
    </filter>
  </defs>
  <style>
    .lines path, .lines circle { fill: none; stroke: url(#gold); stroke-width: 12; stroke-linecap: round; stroke-linejoin: round; }
    .lines path.thin { stroke-width: 6; }
    .lines path.eye { fill: #FFE9A8; stroke-width: 5; }
    .lines circle.dot { fill: url(#gold); stroke: none; }
  </style>`;
}

function background() {
  return `<rect width="1024" height="1024" fill="#000"/>`;
}

function svg({ bg = true, scale = 1 } = {}) {
  const t = `translate(512 512) scale(${scale * 0.92}) translate(-512 -501)`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  ${defs()}
  ${bg ? background() : ''}
  <g transform="${t}">
    <g class="lines" filter="url(#glow)" opacity="0.55">${strokes()}</g>
    <g class="lines">${strokes()}</g>
  </g>
</svg>`;
}

module.exports = { svg, background: () => background() };
