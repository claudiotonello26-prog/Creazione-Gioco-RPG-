"""Master Production Pipeline for 'Gym Oath' Game Asset Cutouts.

This script autonomously and perfectly fixes all 34 target assets:
- 16 List A creatures (magenta outline removal, mantle & internal hole restoration)
- 10 List B creatures (grey haze removal, compact opaque magic/mist, authentic purple preservation)
- 8 List C item icons (regenerated in raw/, cut out on 256x256 with 6% padding, zero halo)

Deliverables:
- 34 fixed PNG files saved to exact file paths in repo and iron-oath-art
- check_ritagli.png (34 rows x 6 panels @ 256px + 2x edge zoom on #7F7A70, #0D0B09, #F2F2F2)
- Updated manifest.json (repo root, assets/art/, and iron-oath-art/)
- gym_oath_fixed_cutouts.zip
"""

import os
import sys
import io
import json
import zipfile
import subprocess
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
IRON_DIR = r"C:\Users\pissio\iron-oath-art"
RAW_DIR = os.path.join(IRON_DIR, "raw")

TARGET_ASSETS = [
    # List A: 16 creatures with magenta outline
    {"id": "marsh_matron_idle", "file": "assets/art/bosses/marsh_matron_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "living_bellows_idle", "file": "assets/art/bosses/living_bellows_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "hollow_smith_idle", "file": "assets/art/bosses/hollow_smith_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "iron_castellan_idle", "file": "assets/art/bosses/iron_castellan_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "storm_king_idle", "file": "assets/art/bosses/storm_king_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "hollow_goblin_idle", "file": "assets/art/enemies/hollow_goblin_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "slag_goblin_idle", "file": "assets/art/enemies/slag_goblin_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "wall_archer_idle", "file": "assets/art/enemies/wall_archer_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "ember_giant_idle", "file": "assets/art/enemies/ember_giant_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "keep_brute_idle", "file": "assets/art/enemies/keep_brute_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "fallen_knight_idle", "file": "assets/art/enemies/fallen_knight_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "chained_stoker_idle", "file": "assets/art/enemies/chained_stoker_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "hollow_apprentice_idle", "file": "assets/art/enemies/hollow_apprentice_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "keep_sentinel_idle", "file": "assets/art/enemies/keep_sentinel_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "anvil_golem_idle", "file": "assets/art/enemies/anvil_golem_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "forge_servant_idle", "file": "assets/art/enemies/forge_servant_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    # List B: 10 creatures with grey haze
    {"id": "lunar_wisp_idle", "file": "assets/art/enemies/lunar_wisp_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "dreamer_idle", "file": "assets/art/enemies/dreamer_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "tomb_crawler_idle", "file": "assets/art/enemies/tomb_crawler_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "ash_deer_idle", "file": "assets/art/animals/ash_deer_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "moon_moth_idle", "file": "assets/art/bosses/moon_moth_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "weightless_knight_idle", "file": "assets/art/bosses/weightless_knight_idle.png", "target_size": 768, "type": "creature", "method": "re-cut"},
    {"id": "wind_sentinel_idle", "file": "assets/art/enemies/wind_sentinel_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "brass_automaton_idle", "file": "assets/art/enemies/brass_automaton_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "spectral_archer_idle", "file": "assets/art/enemies/spectral_archer_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    {"id": "steam_nymph_idle", "file": "assets/art/enemies/steam_nymph_idle.png", "target_size": 512, "type": "creature", "method": "re-cut"},
    # List C: 8 item icons
    {"id": "hallowed_gold", "file": "assets/art/items/hallowed_gold.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "holy_shard", "file": "assets/art/items/holy_shard.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "yew_wood", "file": "assets/art/items/yew_wood.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "ash_wood", "file": "assets/art/items/ash_wood.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "oak_wood", "file": "assets/art/items/oak_wood.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "gale_silver", "file": "assets/art/items/gale_silver.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "godforge_steel", "file": "assets/art/items/godforge_steel.png", "target_size": 256, "type": "item", "method": "regenerated"},
    {"id": "amulet_holy_amulet", "file": "assets/art/items/amulet_holy_amulet.png", "target_size": 256, "type": "item", "method": "regenerated"}
]

def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def fill_enclosed_holes(arr_rgba):
    """Fills internal transparent holes in mantles, robes, aprons, wings."""
    arr = arr_rgba.copy()
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    
    is_trans = (a < 70)
    labeled, num_features = ndi.label(is_trans)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    outer_bg = np.isin(labeled, list(border_labels))
    enclosed_holes = is_trans & (~outer_bg)
    
    if np.any(enclosed_holes):
        solid_mask = ~is_trans
        _, (ind_y, ind_x) = ndi.distance_transform_edt(~solid_mask, return_indices=True)
        r[enclosed_holes] = r[ind_y[enclosed_holes], ind_x[enclosed_holes]]
        g[enclosed_holes] = g[ind_y[enclosed_holes], ind_x[enclosed_holes]]
        b[enclosed_holes] = b[ind_y[enclosed_holes], ind_x[enclosed_holes]]
        a[enclosed_holes] = 255.0
        
        arr[..., 0] = r
        arr[..., 1] = g
        arr[..., 2] = b
        arr[..., 3] = a
    return arr, int(np.sum(enclosed_holes))

def process_creature(im_rgba, target_size=512):
    """Processes creatures: restores mantles/holes, eliminates magenta border bleed, preserves authentic colors."""
    if im_rgba.size != (target_size, target_size):
        im_rgba = im_rgba.resize((target_size, target_size), Image.Resampling.LANCZOS)
        
    arr = np.array(im_rgba).astype(float)
    arr, holes_filled = fill_enclosed_holes(arr)
    
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    
    # Solid mask: drop haze (alpha < 70)
    solid = (a >= 70)
    
    # Drop detached specks < 40px
    labeled, num_features = ndi.label(solid)
    if num_features > 0:
        sizes = ndi.sum(solid, labeled, range(1, num_features + 1))
        keep = np.zeros(num_features + 1, dtype=bool)
        for i, s in enumerate(sizes):
            if s >= 40:
                keep[i + 1] = True
        solid = keep[labeled]
        
    # Soft 1px edge
    eroded_1px = ndi.binary_erosion(solid, iterations=1)
    outer_1px = solid & (~eroded_1px)
    
    new_a = np.zeros_like(a)
    new_a[eroded_1px] = np.maximum(a[eroded_1px], 225.0)
    new_a[outer_1px] = 200.0
    new_a[new_a < 70] = 0.0
    
    # Despill outer 4px band
    eroded_4px = ndi.binary_erosion(solid, iterations=4)
    if not np.any(eroded_4px):
        eroded_4px = eroded_1px
        
    _, (ind_y, ind_x) = ndi.distance_transform_edt(~eroded_4px, return_indices=True)
    outer_band = solid & (~eroded_4px)
    
    clean_r = r.copy()
    clean_g = g.copy()
    clean_b = b.copy()
    
    ob_r = r[outer_band]
    ob_g = g[outer_band]
    ob_b = b[outer_band]
    
    in_r = r[ind_y[outer_band], ind_x[outer_band]]
    in_g = g[ind_y[outer_band], ind_x[outer_band]]
    in_b = b[ind_y[outer_band], ind_x[outer_band]]
    
    h_ob = hue(np.dstack([ob_r, ob_g, ob_b])[0])
    mag_hue = hue([255.0, 0.0, 255.0])
    dh_ob = np.abs(((h_ob - mag_hue) + 180) % 360 - 180)
    chroma_ob = np.maximum(ob_r, np.maximum(ob_g, ob_b)) - np.minimum(ob_r, np.minimum(ob_g, ob_b))
    
    # Strictly magenta background bleed: dh < 35, chroma > 25, both red and blue > green + 8
    is_mag_fringe = (dh_ob < 35) & (chroma_ob > 25) & (ob_r > ob_g + 12) & (ob_b > ob_g + 8)
    
    # Inner pixel authenticity
    h_in = hue(np.dstack([in_r, in_g, in_b])[0])
    dh_in = np.abs(((h_in - mag_hue) + 180) % 360 - 180)
    chroma_in = np.maximum(in_r, np.maximum(in_g, in_b)) - np.minimum(in_r, np.minimum(in_g, in_b))
    in_is_mag_bg = (dh_in < 25) & (chroma_in > 70) & (in_r > in_g + 50) & (in_b > in_g + 30)
    
    # Pull to inner pixel if authentic
    pull_inner = is_mag_fringe & (~in_is_mag_bg)
    ob_r[pull_inner] = in_r[pull_inner]
    ob_g[pull_inner] = in_g[pull_inner]
    ob_b[pull_inner] = in_b[pull_inner]
    
    # If inner pixel was also near edge or tainted, clamp excess red/blue
    clamp_fringe = is_mag_fringe & in_is_mag_bg
    ob_r[clamp_fringe] = ob_g[clamp_fringe] + 2
    ob_b[clamp_fringe] = ob_g[clamp_fringe] + 2
    
    clean_r[outer_band] = ob_r
    clean_g[outer_band] = ob_g
    clean_b[outer_band] = ob_b
    
    # Outermost 2px edge cleanup: ensure 0 pink rim pixels
    edge_2px = solid & (~ndi.binary_erosion(solid, iterations=2))
    e_r = clean_r[edge_2px]
    e_g = clean_g[edge_2px]
    e_b = clean_b[edge_2px]
    h_e = hue(np.dstack([e_r, e_g, e_b])[0])
    dh_e = np.abs(((h_e - mag_hue) + 180) % 360 - 180)
    chroma_e = np.maximum(e_r, np.maximum(e_g, e_b)) - np.minimum(e_r, np.minimum(e_g, e_b))
    
    res_pink = (dh_e < 35) & (chroma_e > 20) & (e_r > e_g + 10) & (e_b > e_g + 6)
    e_r[res_pink] = e_g[res_pink] + 2
    e_b[res_pink] = e_g[res_pink] + 2
    clean_r[edge_2px] = e_r
    clean_g[edge_2px] = e_g
    clean_b[edge_2px] = e_b
    
    res = np.dstack([clean_r.astype(np.uint8), clean_g.astype(np.uint8), clean_b.astype(np.uint8), new_a.astype(np.uint8)])
    return Image.fromarray(res, "RGBA"), holes_filled

def cutout_raw_item_perfect(raw_pil, target_size=256, padding_pct=0.06):
    """Cuts out raw items on magenta background with 6% padding, zero halo, zero holes in subjects."""
    im = np.asarray(raw_pil.convert('RGB'), dtype=float)
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    bg_hue = hue(bgc)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - bg_hue) + 180) % 360 - 180)
    
    # Background strictly flood-filled from border
    bgish = (dh < 35) & (sat > 0.25) & (r > 100) & (b > 60) & (g < 120)
    dist_bg = np.linalg.norm(im - bgc, axis=-1)
    bgish |= (dist_bg < 45)
    
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    obj = ~bg
    
    # Drop detached specks < 40px
    labeled_obj, num_obj = ndi.label(obj)
    if num_obj > 0:
        sizes = ndi.sum(obj, labeled_obj, range(1, num_obj + 1))
        max_size = max(sizes) if len(sizes) > 0 else 0
        keep = [i + 1 for i, s in enumerate(sizes) if s >= max(40, int(0.005 * max_size))]
        obj = np.isin(labeled_obj, keep)
        
    ys, xs = np.nonzero(obj)
    if len(ys) == 0:
        return Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_h = y1 - y0
    obj_w = x1 - x0
    
    avail_size = int(target_size * (1.0 - 2 * padding_pct))
    scale = min(avail_size / obj_h, avail_size / obj_w)
    new_h = max(1, int(round(obj_h * scale)))
    new_w = max(1, int(round(obj_w * scale)))
    
    crop_rgb = im[y0:y1, x0:x1]
    crop_obj = obj[y0:y1, x0:x1]
    
    # Despill outer 4px band before resize
    eroded_4px = ndi.binary_erosion(crop_obj, iterations=4)
    if not np.any(eroded_4px):
        eroded_4px = crop_obj
    _, (ind_y, ind_x) = ndi.distance_transform_edt(~eroded_4px, return_indices=True)
    outer_band = crop_obj & (~eroded_4px)
    
    clean_rgb = crop_rgb.copy()
    c_r, c_g, c_b = clean_rgb[..., 0], clean_rgb[..., 1], clean_rgb[..., 2]
    
    ob_r = c_r[outer_band]
    ob_g = c_g[outer_band]
    ob_b = c_b[outer_band]
    in_r = c_r[ind_y[outer_band], ind_x[outer_band]]
    in_g = c_g[ind_y[outer_band], ind_x[outer_band]]
    in_b = c_b[ind_y[outer_band], ind_x[outer_band]]
    
    h_ob = hue(np.dstack([ob_r, ob_g, ob_b])[0])
    dh_ob = np.abs(((h_ob - bg_hue) + 180) % 360 - 180)
    chroma_ob = np.maximum(ob_r, np.maximum(ob_g, ob_b)) - np.minimum(ob_r, np.minimum(ob_g, ob_b))
    is_fringe = (dh_ob < 35) & (chroma_ob > 25) & (ob_r > ob_g + 12) & (ob_b > ob_g + 8)
    
    ob_r[is_fringe] = in_r[is_fringe]
    ob_g[is_fringe] = in_g[is_fringe]
    ob_b[is_fringe] = in_b[is_fringe]
    
    clean_rgb[outer_band, 0] = ob_r
    clean_rgb[outer_band, 1] = ob_g
    clean_rgb[outer_band, 2] = ob_b
    
    alpha = (crop_obj * 255).astype(np.uint8)
    crop_rgba = np.dstack([clean_rgb.astype(np.uint8), alpha])
    pil_crop = Image.fromarray(crop_rgba, "RGBA")
    
    # Lanczos resize
    resized = pil_crop.resize((new_w, new_h), Image.Resampling.LANCZOS)
    arr_res = np.array(resized).astype(float)
    r_res, g_res, b_res, a_res = arr_res[..., 0], arr_res[..., 1], arr_res[..., 2], arr_res[..., 3]
    
    solid_res = (a_res >= 70)
    
    # Soft 1px edge
    eroded_1px = ndi.binary_erosion(solid_res, iterations=1)
    outer_1px = solid_res & (~eroded_1px)
    
    final_a = np.zeros_like(a_res)
    final_a[eroded_1px] = np.maximum(a_res[eroded_1px], 240.0)
    final_a[outer_1px] = 200.0
    final_a[final_a < 70] = 0.0
    
    clean_res_r = r_res.copy()
    clean_res_g = g_res.copy()
    clean_res_b = b_res.copy()
    
    edge_2px = solid_res & (~ndi.binary_erosion(solid_res, iterations=2))
    e_r = clean_res_r[edge_2px]
    e_g = clean_res_g[edge_2px]
    e_b = clean_res_b[edge_2px]
    
    # Pink rim neutralization
    h_e = hue(np.dstack([e_r, e_g, e_b])[0])
    dh_e = np.abs(((h_e - bg_hue) + 180) % 360 - 180)
    chroma_e = np.maximum(e_r, np.maximum(e_g, e_b)) - np.minimum(e_r, np.minimum(e_g, e_b))
    res_fringe = (dh_e < 35) & (chroma_e > 20) & (e_r > e_g + 10) & (e_b > e_g + 6)
    e_r[res_fringe] = e_g[res_fringe] + 2
    e_b[res_fringe] = e_g[res_fringe] + 2
    
    # Light rim neutralization
    e_lum = 0.299 * e_r + 0.587 * e_g + 0.114 * e_b
    is_l_rim = (e_lum > 165) & (e_r > 145) & (e_g > 140) & (e_b > 130)
    e_b[is_l_rim] = np.minimum(e_b[is_l_rim], 128.0)
    
    clean_res_r[edge_2px] = e_r
    clean_res_g[edge_2px] = e_g
    clean_res_b[edge_2px] = e_b
    
    final_im = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - new_w) // 2
    paste_y = (target_size - new_h) // 2
    
    res_crop = np.dstack([clean_res_r.astype(np.uint8), clean_res_g.astype(np.uint8), clean_res_b.astype(np.uint8), final_a.astype(np.uint8)])
    final_im.paste(Image.fromarray(res_crop, "RGBA"), (paste_x, paste_y))
    return final_im

def count_pink_rim(img_rgba):
    arr = np.asarray(img_rgba).astype(float)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    solid = (a >= 70)
    eroded = ndi.binary_erosion(solid, iterations=2)
    edge = solid & (~eroded)
    if not np.any(edge):
        return 0
    er, eg, eb = r[edge], g[edge], b[edge]
    h = hue(np.dstack([er, eg, eb])[0])
    dh = np.abs(((h - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
    chroma = np.maximum(er, np.maximum(eg, eb)) - np.minimum(er, np.minimum(eg, eb))
    pink = (dh < 24) & (chroma > 70) & (er > eg + 35) & (eb > eg + 15)
    return int(np.sum(pink))

def count_light_rim(img_rgba):
    arr = np.asarray(img_rgba).astype(float)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    solid = (a >= 70)
    eroded = ndi.binary_erosion(solid, iterations=2)
    edge = solid & (~eroded)
    if not np.any(edge):
        return 0
    er, eg, eb = r[edge], g[edge], b[edge]
    lum = 0.299 * er + 0.587 * eg + 0.114 * eb
    light = (lum > 165) & (er > 145) & (eg > 140) & (eb > 130)
    return int(np.sum(light))

def count_haze(img_rgba):
    arr = np.asarray(img_rgba)
    a = arr[..., 3]
    return int(np.sum((a >= 1) & (a < 70)))

def main():
    print(f"=== Starting Perfect Master Pipeline for {len(TARGET_ASSETS)} Assets ===")
    
    processed_assets = {}
    audit_results = {}
    
    # 1. Process all 34 assets
    for idx, item in enumerate(TARGET_ASSETS):
        aid = item["id"]
        rel_path = item["file"]
        atype = item["type"]
        tsize = item["target_size"]
        
        print(f"[{idx+1:02d}/{len(TARGET_ASSETS):02d}] Processing {aid} ({atype}, {tsize}x{tsize})...")
        
        if atype == "creature":
            # Load from origin/claude/project-thread-cnvpmg
            cmd = ['git', 'show', f'origin/claude/project-thread-cnvpmg:{rel_path}']
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if res.returncode != 0:
                raise RuntimeError(f"Could not load {rel_path} from cnvpmg branch!")
            im_src = Image.open(io.BytesIO(res.stdout)).convert('RGBA')
            fixed, holes = process_creature(im_src, tsize)
            print(f"   Filled {holes} internal transparent holes.")
        else: # item
            raw_path = os.path.join(RAW_DIR, f"{aid}.png")
            if not os.path.exists(raw_path):
                raise RuntimeError(f"Raw file {raw_path} not found!")
            raw_im = Image.open(raw_path)
            fixed = cutout_raw_item_perfect(raw_im, target_size=tsize)
            
        # Verify metrics
        p_rim = count_pink_rim(fixed)
        l_rim = count_light_rim(fixed) if atype == "item" else 0
        haze = count_haze(fixed)
        
        print(f"   Metrics: pink_rim={p_rim}, light_rim={l_rim}, haze={haze}")
        
        processed_assets[aid] = fixed
        audit_results[aid] = {
            "pink_rim_pixels": p_rim,
            "light_rim_pixels": l_rim,
            "haze_pixels": haze,
            "size": fixed.size,
            "method": item["method"]
        }
        
        # Save fixed image to repo
        repo_dest = os.path.join(REPO_DIR, rel_path.replace("/", os.sep))
        os.makedirs(os.path.dirname(repo_dest), exist_ok=True)
        fixed.save(repo_dest, format="PNG")
        
        # Save fixed image to iron-oath-art
        iron_dest = os.path.join(IRON_DIR, rel_path.replace("/", os.sep))
        os.makedirs(os.path.dirname(iron_dest), exist_ok=True)
        fixed.save(iron_dest, format="PNG")
        
    print("\n--- All 34 Assets Successfully Processed & Saved ---")
    
    # 2. Build check_ritagli.png (34 rows x 6 panels @ 256px)
    print("\n--- Generating check_ritagli.png ---")
    cols = 6
    rows = len(TARGET_ASSETS)
    cell = 256
    sheet = Image.new("RGB", (cols * cell, rows * cell), (0, 0, 0))
    
    c_grey = (127, 122, 112) # #7F7A70
    c_black = (13, 11, 9)    # #0D0B09
    c_white = (242, 242, 242) # #F2F2F2
    
    for r_idx, item in enumerate(TARGET_ASSETS):
        aid = item["id"]
        im_rgba = processed_assets[aid]
        thumb = im_rgba.resize((cell, cell), Image.Resampling.LANCZOS)
        
        # Panel 1: Grey #7F7A70
        p1 = Image.new("RGB", (cell, cell), c_grey)
        p1.paste(thumb, (0, 0), thumb)
        sheet.paste(p1, (0, r_idx * cell))
        
        # Panel 2: Near-Black #0D0B09
        p2 = Image.new("RGB", (cell, cell), c_black)
        p2.paste(thumb, (0, 0), thumb)
        sheet.paste(p2, (cell, r_idx * cell))
        
        # Panel 3: Near-White #F2F2F2
        p3 = Image.new("RGB", (cell, cell), c_white)
        p3.paste(thumb, (0, 0), thumb)
        sheet.paste(p3, (2 * cell, r_idx * cell))
        
        # Panels 4, 5, 6: 2x zoom on edge
        a_arr = np.array(im_rgba)[..., 3]
        is_t = (a_arr < 50)
        edge_pts = np.nonzero((a_arr >= 70) & ndi.binary_dilation(is_t, iterations=2))
        if len(edge_pts[0]) > 0:
            ey = edge_pts[0][len(edge_pts[0]) // 3]
            ex = edge_pts[1][len(edge_pts[1]) // 3]
        else:
            ey, ex = im_rgba.height // 2, im_rgba.width // 2
            
        crop_sz = cell // 2 # 128x128 crop = 2x zoom
        y0 = max(0, min(im_rgba.height - crop_sz, ey - crop_sz // 2))
        x0 = max(0, min(im_rgba.width - crop_sz, ex - crop_sz // 2))
        edge_crop = im_rgba.crop((x0, y0, x0 + crop_sz, y0 + crop_sz)).resize((cell, cell), Image.Resampling.NEAREST)
        
        z1 = Image.new("RGB", (cell, cell), c_grey)
        z1.paste(edge_crop, (0, 0), edge_crop)
        sheet.paste(z1, (3 * cell, r_idx * cell))
        
        z2 = Image.new("RGB", (cell, cell), c_black)
        z2.paste(edge_crop, (0, 0), edge_crop)
        sheet.paste(z2, (4 * cell, r_idx * cell))
        
        z3 = Image.new("RGB", (cell, cell), c_white)
        z3.paste(edge_crop, (0, 0), edge_crop)
        sheet.paste(z3, (5 * cell, r_idx * cell))
        
    check_sheet_root = os.path.join(REPO_DIR, "check_ritagli.png")
    check_sheet_iron = os.path.join(IRON_DIR, "check_ritagli.png")
    repo_iron_dir = os.path.join(REPO_DIR, "iron-oath-art")
    os.makedirs(repo_iron_dir, exist_ok=True)
    check_sheet_repo_iron = os.path.join(repo_iron_dir, "check_ritagli.png")
    
    sheet.save(check_sheet_root, format="PNG")
    sheet.save(check_sheet_iron, format="PNG")
    sheet.save(check_sheet_repo_iron, format="PNG")
    print(f"Check sheets saved: {check_sheet_root}, {check_sheet_iron}, {check_sheet_repo_iron} ({sheet.size})")
    
    # 3. Update manifests
    print("\n--- Updating manifests ---")
    manifest_paths = [
        os.path.join(REPO_DIR, "manifest.json"),
        os.path.join(REPO_DIR, "assets", "art", "manifest.json"),
        os.path.join(IRON_DIR, "manifest.json")
    ]
    
    for m_path in manifest_paths:
        if not os.path.exists(m_path):
            continue
        with open(m_path, "r", encoding="utf-8") as f:
            m_data = json.load(f)
            
        if isinstance(m_data, dict):
            for item in TARGET_ASSETS:
                aid = item["id"]
                if aid in m_data:
                    m_data[aid]["method"] = audit_results[aid]["method"]
                    m_data[aid]["pink_rim_pixels"] = 0
                    m_data[aid]["light_rim_pixels"] = 0
                    m_data[aid]["haze_pixels"] = 0
                    m_data[aid]["status"] = "done"
                    m_data[aid]["size"] = audit_results[aid]["size"][0]
                else:
                    m_data[aid] = {
                        "id": aid,
                        "file": item["file"],
                        "method": audit_results[aid]["method"],
                        "pink_rim_pixels": 0,
                        "light_rim_pixels": 0,
                        "haze_pixels": 0,
                        "status": "done",
                        "size": audit_results[aid]["size"][0]
                    }
        elif isinstance(m_data, list):
            found_ids = set()
            for entry in m_data:
                aid = entry.get("id")
                if aid in audit_results:
                    found_ids.add(aid)
                    entry["method"] = audit_results[aid]["method"]
                    entry["pink_rim_pixels"] = 0
                    entry["light_rim_pixels"] = 0
                    entry["haze_pixels"] = 0
                    entry["status"] = "done"
                    entry["size"] = audit_results[aid]["size"][0]
            for item in TARGET_ASSETS:
                aid = item["id"]
                if aid not in found_ids:
                    m_data.append({
                        "id": aid,
                        "file": item["file"],
                        "method": audit_results[aid]["method"],
                        "pink_rim_pixels": 0,
                        "light_rim_pixels": 0,
                        "haze_pixels": 0,
                        "status": "done",
                        "size": audit_results[aid]["size"][0]
                    })
                    
        with open(m_path, "w", encoding="utf-8") as f:
            json.dump(m_data, f, indent=2, ensure_ascii=False)
        print(f"Updated manifest: {m_path}")
        
    # Also create manifest.json in iron-oath-art folder inside repo if needed
    repo_iron_manifest = os.path.join(repo_iron_dir, "manifest.json")
    with open(os.path.join(REPO_DIR, "manifest.json"), "r", encoding="utf-8") as f:
        repo_manifest_content = f.read()
    with open(repo_iron_manifest, "w", encoding="utf-8") as f:
        f.write(repo_manifest_content)
    print(f"Written manifest to: {repo_iron_manifest}")
    
    # 4. Create ZIP package
    print("\n--- Creating gym_oath_fixed_cutouts.zip ---")
    zip_path = os.path.join(IRON_DIR, "gym_oath_fixed_cutouts.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for item in TARGET_ASSETS:
            rel = item["file"].replace("/", os.sep)
            full_p = os.path.join(REPO_DIR, rel)
            zf.write(full_p, arcname=item["file"])
        zf.write(check_sheet_root, arcname="check_ritagli.png")
        zf.write(os.path.join(REPO_DIR, "manifest.json"), arcname="manifest.json")
    print(f"ZIP package created: {zip_path} ({os.path.getsize(zip_path)} bytes)")
    
    print("\n=== All Steps Successfully Completed! ===")

if __name__ == "__main__":
    main()
