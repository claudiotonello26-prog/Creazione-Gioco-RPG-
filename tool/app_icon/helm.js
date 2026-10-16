// Elmo templare: restituisce il gruppo SVG centrato in (512,512) nello spazio 1024.
function helm() {
  const holes = [];
  for (const side of [-1, 1]) {
    const cx = 512 + side * 105;
    // fori di respirazione a croce
    const pts = [[0,-36],[0,0],[0,36],[-36,0],[36,0],[0,72]];
    for (const [dx, dy] of pts) holes.push(`<circle cx="${cx+dx}" cy="${640+dy+1.5}" r="10.5" fill="#FFF0B8" opacity="0.55"/><circle cx="${cx+dx}" cy="${640+dy}" r="9" fill="#0D0B09"/>`);
  }
  return `
  <defs>
    <linearGradient id="metal" x1="0" x2="1" y1="0" y2="0">
      <stop offset="0" stop-color="#4a3510"/>
      <stop offset="0.18" stop-color="#9c7526"/>
      <stop offset="0.42" stop-color="#F2D88A"/>
      <stop offset="0.55" stop-color="#E2BC5C"/>
      <stop offset="0.82" stop-color="#8a6420"/>
      <stop offset="1" stop-color="#3a290c"/>
    </linearGradient>
    <linearGradient id="strip" x1="0" x2="1">
      <stop offset="0" stop-color="#b8902f"/>
      <stop offset="0.5" stop-color="#FFF0B8"/>
      <stop offset="1" stop-color="#a07a28"/>
    </linearGradient>
    <linearGradient id="shade" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#fff" stop-opacity="0.18"/>
      <stop offset="0.35" stop-color="#fff" stop-opacity="0"/>
      <stop offset="1" stop-color="#000" stop-opacity="0.35"/>
    </linearGradient>
    <radialGradient id="ember" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#FF8A3D" stop-opacity="0.95"/>
      <stop offset="0.6" stop-color="#E0662B" stop-opacity="0.35"/>
      <stop offset="1" stop-color="#E0662B" stop-opacity="0"/>
    </radialGradient>
    <clipPath id="body"><path id="bp" d="M318 262 Q318 236 344 234 L680 234 Q706 236 706 262 L724 772 Q620 812 512 814 Q404 812 300 772 Z"/></clipPath>
  </defs>
  <g>
    <path d="M318 262 Q318 236 344 234 L680 234 Q706 236 706 262 L724 772 Q620 812 512 814 Q404 812 300 772 Z" fill="url(#metal)" stroke="#120d07" stroke-width="10"/>
    <g clip-path="url(#body)">
      <rect x="290" y="230" width="444" height="590" fill="url(#shade)"/>
      <!-- calotta piatta: bordo superiore -->
      <rect x="290" y="234" width="444" height="34" fill="#000" opacity="0.22"/>
      <!-- fascia della fronte (braccio orizzontale della croce) -->
      <rect x="290" y="418" width="444" height="40" fill="url(#metal)"/>
      <rect x="290" y="418" width="444" height="40" fill="#FFF3C4" opacity="0.18"/>
      <rect x="290" y="456" width="444" height="5" fill="#120d07" opacity="0.6"/>
      <!-- fessure degli occhi -->
      <rect x="318" y="468" width="168" height="34" rx="6" fill="#0D0B09"/>
      <rect x="538" y="468" width="168" height="34" rx="6" fill="#0D0B09"/>
      <ellipse cx="420" cy="485" rx="70" ry="13" fill="url(#ember)"/>
      <ellipse cx="604" cy="485" rx="70" ry="13" fill="url(#ember)"/>
      <!-- fascia verticale (croce) -->
      <rect x="490" y="234" width="44" height="590" fill="url(#strip)"/>
      <rect x="486" y="234" width="4" height="590" fill="#120d07" opacity="0.5"/>
      <rect x="534" y="234" width="4" height="590" fill="#120d07" opacity="0.5"/>
      ${holes.join('\n')}
      <!-- rivetti -->
      ${[330,400,624,694].map(x=>`<circle cx="${x}" cy="438" r="6" fill="#FFF0B8" opacity="0.9"/>`).join('')}
      ${[300,360,600,700].map(y=>`<circle cx="512" cy="${y}" r="5.5" fill="#6b4c14"/>`).join('')}
      <!-- bordo inferiore -->
      <path d="M296 740 Q404 780 512 782 Q620 780 728 740 L728 830 L296 830 Z" fill="#000" opacity="0.28"/>
    </g>
    <!-- bordo inferiore dorato -->
    <path d="M300 772 Q404 812 512 814 Q620 812 724 772" fill="none" stroke="#F2D88A" stroke-width="7" opacity="0.85"/>
    <path d="M330 240 L694 240" stroke="#FFF3C4" stroke-width="5" opacity="0.7"/>
  </g>`;
}
function background() {
  const rays = [];
  for (let i = 0; i < 24; i++) {
    const a = (i / 24) * Math.PI * 2;
    const x = 512 + Math.cos(a) * 760, y = 512 + Math.sin(a) * 760;
    rays.push(`<line x1="512" y1="512" x2="${x.toFixed(1)}" y2="${y.toFixed(1)}" stroke="#C9A24A" stroke-width="${i%2?2:5}" opacity="${i%2?0.05:0.09}"/>`);
  }
  return `
  <defs>
    <radialGradient id="bg" cx="0.5" cy="0.45" r="0.75">
      <stop offset="0" stop-color="#3a2c18"/>
      <stop offset="0.45" stop-color="#1a140d"/>
      <stop offset="1" stop-color="#0D0B09"/>
    </radialGradient>
    <radialGradient id="halo" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#E9C873" stop-opacity="0.35"/>
      <stop offset="0.7" stop-color="#C9A24A" stop-opacity="0.08"/>
      <stop offset="1" stop-color="#C9A24A" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1024" height="1024" fill="url(#bg)"/>
  ${rays.join('')}
  <circle cx="512" cy="512" r="330" fill="url(#halo)"/>
  <circle cx="512" cy="512" r="400" fill="none" stroke="#C9A24A" stroke-width="6" opacity="0.55"/>
  <circle cx="512" cy="512" r="384" fill="none" stroke="#C9A24A" stroke-width="2" opacity="0.3"/>`;
}
function svg({bg = true, scale = 1, opaque = true} = {}) {
  const t = `translate(512 512) scale(${scale}) translate(-512 -524)`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  ${bg ? background() : ''}
  <g transform="${t}">${helm()}</g></svg>`;
}
module.exports = { svg, background };
