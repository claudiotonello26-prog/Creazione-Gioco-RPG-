"""Chroma Key Processor for 'Gym Oath' Game Assets
Extracts sprites from flat #FF00FF magenta background with zero fringe and preserves warm skin tones.
Uses only numpy, Pillow, and scipy (no heavy AI model downloads).
"""

import os
import sys
import numpy as np
from PIL import Image
from scipy.ndimage import label, binary_dilation

def clean_chroma(raw_img_or_path, edge_softness=200):
    if isinstance(raw_img_or_path, str):
        raw_img = Image.open(raw_img_or_path).convert('RGB')
    else:
        raw_img = raw_img_or_path.convert('RGB')
        
    arr = np.array(raw_img, dtype=np.float32)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    
    # Pure magenta chroma condition
    mag_metric = (r + b) - 2.5 * g
    is_bg = (r > 130) & (b > 70) & (g < 90) & (mag_metric > 100)
    
    labeled, num_features = label(is_bg)
    # Border-connected background
    border_labels = set(np.unique(labeled[0, :])) | set(np.unique(labeled[-1, :])) | set(np.unique(labeled[:, 0])) | set(np.unique(labeled[:, -1]))
    border_labels.discard(0)
    true_bg = np.isin(labeled, list(border_labels))
    
    # Enclosed background pockets (e.g. between legs or arms)
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if np.mean(r[mask_lbl]) > 140 and np.mean(b[mask_lbl]) > 80 and np.mean(g[mask_lbl]) < 90:
                true_bg = true_bg | mask_lbl
                
    alpha = np.where(true_bg, 0.0, 255.0)
    
    # Refine outer 1px edge to match dark inking without magenta halo
    edge = binary_dilation(true_bg, iterations=1) & (~true_bg)
    arr[edge, 0] = np.minimum(arr[edge, 0], 45.0)
    arr[edge, 2] = np.minimum(arr[edge, 2], 45.0)
    alpha[edge] = float(edge_softness)
    
    # Strip any bright stray halo on lower perimeter (e.g. boots)
    is_transp = (alpha == 0)
    outer_2px = binary_dilation(is_transp, iterations=3) & (~is_transp)
    halo = outer_2px & (arr[:, :, 0] > 120) & (arr[:, :, 1] > 90) & (np.arange(arr.shape[0])[:, None] > (arr.shape[0] * 0.6))
    alpha[halo] = 0.0
    
    rgba = np.dstack([arr.astype(np.uint8), alpha.astype(np.uint8)])
    return Image.fromarray(rgba, 'RGBA')

if __name__ == '__main__':
    if len(sys.argv) > 2:
        in_p, out_p = sys.argv[1], sys.argv[2]
        res = clean_chroma(in_p)
        res.save(out_p)
        print(f"Processed {in_p} -> {out_p}")
    else:
        print("Usage: python chroma_processor.py <input_raw.png> <output_clean.png>")
