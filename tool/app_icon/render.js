const { chromium } = require('playwright');
const fs = require('fs');
const { svg, background } = require('./helm.js');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 1024, height: 1024 } });
  async function shot(markup, out, transparent) {
    await p.setContent(`<html><body style="margin:0;background:transparent">${markup}</body></html>`);
    await p.screenshot({ path: out, omitBackground: transparent, clip: {x:0,y:0,width:1024,height:1024} });
  }
  await shot(svg({ bg: true, scale: 1.0 }), 'icon_full.png', false);
  // Android adattiva: primo piano nella zona sicura (66%)
  await shot(svg({ bg: false, scale: 0.85 }), 'icon_fg.png', true);
  await shot(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">${background()}</svg>`, 'icon_bg.png', false);
  await b.close();
})();
