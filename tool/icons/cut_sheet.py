"""Ritaglia un foglio di icone su fondo magenta (anche con alone) in PNG 256x256.
uso: cut2.py foglio.png cartella nome1,nome2,...  (ordine: righe dall'alto, poi da sinistra; '_' = scarta)"""
import sys, os, numpy as np
from PIL import Image
from scipy import ndimage as ndi
src, out, names = sys.argv[1], sys.argv[2], sys.argv[3].split(',')
im = np.asarray(Image.open(src).convert('RGB')).astype(float)
H, W, _ = im.shape
border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
bgc = np.median(border, axis=0)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
mx, mn = im.max(-1), im.min(-1)
lum = (0.3*r + 0.59*g + 0.11*b) / 255
sat = (mx - mn) / np.maximum(mx, 1)
# colore come il fondo, oppure la sua versione schiarita (alone): rosso e blu ben sopra il verde
def hue(c):
    c = np.asarray(c); return np.degrees(np.arctan2(np.sqrt(3)*(c[..., 1]-c[..., 2]), 2*c[..., 0]-c[..., 1]-c[..., 2]))
dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
bgish = (dh < 28) & (sat > 0.18) & (lum > 0.18)
lab, _ = ndi.label(bgish)
edge_labels = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
bg = np.isin(lab, list(edge_labels))
# tasche chiuse grandi del colore del fondo (dentro anelli, tra rami)
sizes = ndi.sum(bgish, lab, range(1, lab.max()+1))
for k, s in enumerate(sizes):
    if k+1 in edge_labels or s < 40 or os.environ.get('NOPOCKET'): continue
    m = im[lab == k+1].mean(0)
    if np.abs(m - bgc).max() < 60 or (dh[lab == k+1].mean() < 15 and sat[lab == k+1].mean() > 0.3) or (os.environ.get('LIGHTPOCKET') and dh[lab == k+1].mean() < 25 and lum[lab == k+1].mean() > 0.6):
        bg |= lab == k+1
obj = ~bg
# pela l'alone chiaro/rosato rimasto attaccato fuori dal contorno nero
PEEL = int(os.environ.get('PEEL', '0')) or max(10, int(0.022*max(H, W)))
halo = (lum > float(os.environ.get('DARK', '0.30'))) if os.environ.get('HARD') else (((lum > 0.42) & (sat < 0.35)) | bgish)
for _ in range(PEEL):
    e = obj & ~ndi.binary_erosion(obj, border_value=1)
    peel = e & halo
    if not peel.any(): break
    obj &= ~peel
if os.environ.get('RINGS'):
    # buchi chiari e rosati chiusi dentro anelli e catene: alone, non oggetto
    light = (lum > 0.62) & (sat < 0.4) & obj
    hl, nh = ndi.label(light)
    for k in range(1, nh+1):
        m = hl == k
        if m.sum() < 30: continue
        px = im[m]; tinted = px[(px.max(1)-px.min(1)) > 12]
        if len(tinted) < 0.3*len(px): continue
        if np.median(np.abs(((hue(tinted) - hue(bgc)) + 180) % 360 - 180)) < 22:
            obj &= ~m; holes_removed = True
    tint = ((r-g > 10) & (b-g > 5) & (lum > 0.45))
    for _ in range(6):
        e2 = obj & ~ndi.binary_erosion(obj, border_value=1)
        p2 = e2 & tint
        if not p2.any(): break
        obj &= ~p2
obj = ndi.binary_opening(obj, iterations=1)
# raggruppa i pezzi vicini (es. carboni sparsi) in oggetti
grp, n = ndi.label(ndi.binary_dilation(obj, iterations=int(os.environ.get('GROUP', '18'))))
objs = []
for k in range(1, n+1):
    m = (grp == k) & obj
    if m.sum() < 0.004*H*W: continue
    ys, xs = np.nonzero(m)
    objs.append((ys.mean(), xs.mean(), m))
# ordine: righe (per centro y con tolleranza), poi x
objs.sort(key=lambda o: o[0])
rows, cur = [], [objs[0]]
for o in objs[1:]:
    if o[0] - np.mean([c[0] for c in cur]) < H*0.12: cur.append(o)
    else: rows.append(cur); cur = [o]
rows.append(cur)
ordered = [o for row in rows for o in sorted(row, key=lambda o: o[1])]
print('oggetti trovati', len(ordered), 'nomi', len(names))
os.makedirs(out, exist_ok=True)
for (cy, cx, m), name in zip(ordered, names):
    if name == '_': continue
    ys, xs = np.nonzero(m); y0, y1, x0, x1 = ys.min(), ys.max()+1, xs.min(), xs.max()+1
    a = ndi.gaussian_filter(m[y0:y1, x0:x1].astype(float), 0.7) * m[y0:y1, x0:x1]
    rgba = np.dstack([im[y0:y1, x0:x1], a*255]).astype(np.uint8)
    o = Image.fromarray(rgba, 'RGBA'); s = max(o.size); pad = int(s*0.06); S = s+2*pad
    c = Image.new('RGBA', (S, S), (0, 0, 0, 0)); c.paste(o, ((S-o.size[0])//2, (S-o.size[1])//2))
    c = c.resize((256, 256), Image.LANCZOS)
    if os.environ.get('PINKCLEAN'):
        ar = np.asarray(c).astype(int); R, G, B = ar[..., 0], ar[..., 1], ar[..., 2]
        pinkl = (R-G > 25) & (B-G > 15) & (R > 190) & (np.abs(R-B) < 45)
        pinkl = ndi.binary_dilation(pinkl, iterations=1) & ((R-G > 12) & (B-G > 8))
        ar[..., 3][pinkl] = 0; c = Image.fromarray(ar.astype(np.uint8), 'RGBA')
    ar = np.asarray(c).astype(float)
    pk = ((ar[..., 3] > 20) & (np.abs(((hue(ar[..., :3]) - hue(bgc)) + 180) % 360 - 180) < 20) & ((ar[..., :3].max(-1)-ar[..., :3].min(-1)) > 90)).sum()
    c.save(f'{out}/{name}.png'); print(f'{name}: pixel color fondo {pk}')
