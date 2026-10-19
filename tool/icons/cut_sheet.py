import sys, numpy as np
from PIL import Image
from scipy import ndimage as ndi
src, rows, cols, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
names = sys.argv[5].split(',')
im = np.asarray(Image.open(src).convert('RGB')).astype(int)
H, W, _ = im.shape
r,g,b = im[...,0], im[...,1], im[...,2]
# "pinkish": magenta or its light halo (R and B well above G, R≈B)
pink = (r-g > 22) & (b-g > 22) & (abs(r-b) < 60) & (r > 140)
import os; os.makedirs(out, exist_ok=True)
for i,name in enumerate(names):
    if not name: continue
    rr, cc = divmod(i, cols)
    y0,y1 = rr*H//rows, (rr+1)*H//rows; x0,x1 = cc*W//cols, (cc+1)*W//cols
    cell = im[y0:y1, x0:x1]; pk = pink[y0:y1, x0:x1]
    lab,_ = ndi.label(pk)
    border = set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]]))) - {0}
    sz = ndi.sum(pk, lab, range(1, lab.max()+1))
    bgc = np.median(cell[lab == list(border)[0]], axis=0) if border else np.array([220,30,220])
    holes = set()
    for k,s in enumerate(sz):
        if s < 25: continue
        m = cell[lab == k+1].mean(axis=0)
        if np.abs(m - bgc).max() < 45 or (m[0] > 225 and m[2] > 215): holes.add(k+1)
    bg = np.isin(lab, list(border | holes))
    obj = ~bg
    # keep largest object component (+ components near it), drop specks
    lo,n = ndi.label(obj)
    if n>1:
        sizes = ndi.sum(obj, lo, range(1,n+1))
        keep = [k+1 for k,s in enumerate(sizes) if s > 0.02*sizes.max()]
        obj = np.isin(lo, keep)
    # eat remaining pinkish fringe at the edge (2 px)
    for _ in range(4):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        cr,cg,cb = cell[...,0],cell[...,1],cell[...,2]
        fringe = edge & (((cr-cg > 15) & (cb-cg > 15) & (cr > 120)) | ((cr > 195) & (cb > 185)))
        obj &= ~fringe
    alpha = ndi.binary_erosion(obj, iterations=1).astype(float)
    alpha = np.maximum(alpha, 0.0)
    a = ndi.gaussian_filter(obj.astype(float), 0.6) * obj  # soft only inward
    rgba = np.dstack([cell, (a*255).astype(int)]).astype(np.uint8)
    imo = Image.fromarray(rgba, 'RGBA')
    bb = imo.getbbox(); imo = imo.crop(bb)
    s = max(imo.size); pad = int(s*0.06); S = s+2*pad
    canv = Image.new('RGBA', (S,S), (0,0,0,0)); canv.paste(imo, ((S-imo.size[0])//2, (S-imo.size[1])//2))
    canv = canv.resize((256,256), Image.LANCZOS)
    # final check: pink pixels with alpha>0
    ar = np.asarray(canv).astype(int)
    pp = ((ar[...,3]>20)&(ar[...,0]-ar[...,1]>60)&(ar[...,2]-ar[...,1]>60)&(abs(ar[...,0]-ar[...,2])<70)).sum()
    canv.save(f'{out}/{name}.png'); print(name, 'pink_px', pp)
