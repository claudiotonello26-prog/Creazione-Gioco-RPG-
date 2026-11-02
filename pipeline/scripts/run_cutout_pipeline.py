"""Gym Oath 34-Asset Cutout Fix and Delivery Pipeline.
Mobile dark fantasy souls-like fitness RPG.

Fixes all 34 assets:
- List A: Magenta outlines on creatures (16)
- List B: Grey haze / thin smoke around creatures (10)
- List C: Item icons with white halo or blotches (8)

Outputs:
- Fixed assets at exact paths in repo and iron-oath-art.
- check_ritagli.png (all 34 assets on grey #7F7A70, near-black #0D0B09, near-white #F2F2F2 at 256px + 2x edge zoom).
- manifest.json with method ("re-cut" / "regenerated"), pink_rim_pixels=0, light_rim_pixels=0, haze_pixels=0.
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

CHECK_IMAGE_IRON = os.path.join(IRON_DIR, "check_ritagli.png")
CHECK_IMAGE_ROOT = os.path.join(REPO_DIR, "check_ritagli.png")

MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = os.path.join(IRON_DIR, "manifest.json")
ASSETS_LIST_IRON = os.path.join(IRON_DIR, "assets_list.json")

ZIP_BACKUP_IRON = os.path.join(IRON_DIR, "gym_oath_fixed_cutouts.zip")
ZIP_BACKUP_REPO = os.path.join(REPO_DIR, "gym_oath_fixed_cutouts.zip")

GIT_REF_BRANCH = "origin/claude/project-thread-cnvpmg"

ASSETS_A = [
    {"id": "marsh_matron_idle", "file": "assets/art/bosses/marsh_matron_idle.png", "note": "keep the green lantern with its pink-magenta glow ring inside the figure", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "living_bellows_idle", "file": "assets/art/bosses/living_bellows_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "hollow_smith_idle", "file": "assets/art/bosses/hollow_smith_idle.png", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "iron_castellan_idle", "file": "assets/art/bosses/iron_castellan_idle.png", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "storm_king_idle", "file": "assets/art/bosses/storm_king_idle.png", "note": "keep the purple lightning", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "hollow_goblin_idle", "file": "assets/art/enemies/hollow_goblin_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "slag_goblin_idle", "file": "assets/art/enemies/slag_goblin_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "wall_archer_idle", "file": "assets/art/enemies/wall_archer_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "ember_giant_idle", "file": "assets/art/enemies/ember_giant_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "keep_brute_idle", "file": "assets/art/enemies/keep_brute_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "fallen_knight_idle", "file": "assets/art/enemies/fallen_knight_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "chained_stoker_idle", "file": "assets/art/enemies/chained_stoker_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "hollow_apprentice_idle", "file": "assets/art/enemies/hollow_apprentice_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "keep_sentinel_idle", "file": "assets/art/enemies/keep_sentinel_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "anvil_golem_idle", "file": "assets/art/enemies/anvil_golem_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "forge_servant_idle", "file": "assets/art/enemies/forge_servant_idle.png", "expected_size": (512, 512), "method": "re-cut"}
]

ASSETS_B = [
    {"id": "lunar_wisp_idle", "file": "assets/art/enemies/lunar_wisp_idle.png", "note": "keep the violet-pink wings and the white flame", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "dreamer_idle", "file": "assets/art/enemies/dreamer_idle.png", "note": "keep the lilac-purple wrappings", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "tomb_crawler_idle", "file": "assets/art/enemies/tomb_crawler_idle.png", "note": "keep the purple", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "ash_deer_idle", "file": "assets/art/animals/ash_deer_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "moon_moth_idle", "file": "assets/art/bosses/moon_moth_idle.png", "note": "keep the lilac wings", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "weightless_knight_idle", "file": "assets/art/bosses/weightless_knight_idle.png", "expected_size": (768, 768), "method": "re-cut"},
    {"id": "wind_sentinel_idle", "file": "assets/art/enemies/wind_sentinel_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "brass_automaton_idle", "file": "assets/art/enemies/brass_automaton_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "spectral_archer_idle", "file": "assets/art/enemies/spectral_archer_idle.png", "expected_size": (512, 512), "method": "re-cut"},
    {"id": "steam_nymph_idle", "file": "assets/art/enemies/steam_nymph_idle.png", "expected_size": (512, 512), "method": "re-cut"}
]

ASSETS_C = [
    {"id": "hallowed_gold", "file": "assets/art/items/hallowed_gold.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "holy_shard", "file": "assets/art/items/holy_shard.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "yew_wood", "file": "assets/art/items/yew_wood.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "ash_wood", "file": "assets/art/items/ash_wood.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "oak_wood", "file": "assets/art/items/oak_wood.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "gale_silver", "file": "assets/art/items/gale_silver.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "godforge_steel", "file": "assets/art/items/godforge_steel.png", "expected_size": (256, 256), "method": "regenerated"},
    {"id": "amulet_holy_amulet", "file": "assets/art/items/amulet_holy_amulet.png", "expected_size": (256, 256), "method": "regenerated"}
]

ALL_ASSETS = ASSETS_A + ASSETS_B + ASSETS_C

def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def count_pink_rim_pixels(img_rgba):
    arr = np.asarray(img_rgba).astype(float)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    
    is_solid = (a >= 70)
    is_trans = (a < 70)
    outer_2px = is_solid & ndi.binary_dilation(is_trans, iterations=2)
    
    if not np.any(outer_2px):
        return 0
        
    er, eg, eb = r[outer_2px], g[outer_2px], b[outer_2px]
    h = hue(np.dstack([er, eg, eb])[0])
    dh = np.abs(((h - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
    chroma = np.maximum(er, np.maximum(eg, eb)) - np.minimum(er, np.minimum(eg, eb))
    
    pink = (dh < 24) & (chroma > 70) & (er > eg + 35) & (eb > eg + 15)
    return int(np.sum(pink))

def count_light_rim_pixels(img_rgba):
    arr = np.asarray(img_rgba).astype(float)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    
    is_solid = (a >= 70)
    is_trans = (a < 70)
    outer_2px = is_solid & ndi.binary_dilation(is_trans, iterations=2)
    
    if not np.any(outer_2px):
        return 0
        
    er, eg, eb = r[outer_2px], g[outer_2px], b[outer_2px]
    lum = 0.299 * er + 0.587 * eg + 0.114 * eb
    light = (lum > 165) & (er > 145) & (eg > 140) & (eb > 130)
    return int(np.sum(light))

def count_haze_pixels(img_rgba):
    arr = np.asarray(img_rgba)
    a = arr[..., 3]
    return int(np.sum((a >= 1) & (a < 70)))

def load_cnvpmg_image(rel_path):
    cmd = ["git", "show", f"{GIT_REF_BRANCH}:{rel_path}"]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode == 0 and len(res.stdout) > 0:
        return Image.open(io.BytesIO(res.stdout)).convert("RGBA")
    raise FileNotFoundError(f"Failed to load from {GIT_REF_BRANCH}:{rel_path}")

def recut_creature(im_rgba, item_id=""):
    arr = np.array(im_rgba).astype(float)
    r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
    
    # 1. Drop haze (alpha < 70)
    mask = (a >= 70)
    
    # 2. Drop detached specks smaller than 40 px
    labeled, num_features = ndi.label(mask)
    if num_features > 0:
        sizes = ndi.sum(mask, labeled, range(1, num_features + 1))
        keep = np.zeros(num_features + 1, dtype=bool)
        for i, s in enumerate(sizes):
            if s >= 40:
                keep[i + 1] = True
        mask = keep[labeled]
        
    # 3. Shrink alpha by 1 px, soft edge on outer 1 px
    eroded_1px = ndi.binary_erosion(mask, iterations=1)
    outer_1px = mask & (~eroded_1px)
    
    new_a = np.zeros_like(a)
    new_a[eroded_1px] = np.maximum(a[eroded_1px], 220.0)
    new_a[outer_1px] = 200.0
    new_a[new_a < 70] = 0.0
    
    # 4. Despill outer 4px band
    eroded_4px = ndi.binary_erosion(mask, iterations=4)
    outer_band = mask & (~eroded_4px)
    
    if np.any(eroded_4px):
        _, indices = ndi.distance_transform_edt(~eroded_4px, return_indices=True)
        near_y = indices[0][outer_band]
        near_x = indices[1][outer_band]
        
        inner_r = r[near_y, near_x]
        inner_g = g[near_y, near_x]
        inner_b = b[near_y, near_x]
        
        ob_r = r[outer_band]
        ob_g = g[outer_band]
        ob_b = b[outer_band]
        
        is_authentic_purple = any(k in item_id for k in ["lunar_wisp", "moon_moth", "dreamer", "tomb_crawler", "storm_king"])
        
        h_ob = hue(np.dstack([ob_r, ob_g, ob_b])[0])
        dh_ob = np.abs(((h_ob - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
        chroma_ob = np.maximum(ob_r, np.maximum(ob_g, ob_b)) - np.minimum(ob_r, np.minimum(ob_g, ob_b))
        pink_bleed = (dh_ob < 28) & (chroma_ob > 40) & (ob_r > ob_g + 20) & (ob_b > ob_g + 10)
        
        if is_authentic_purple:
            ob_r[pink_bleed] = inner_r[pink_bleed]
            ob_g[pink_bleed] = inner_g[pink_bleed]
            ob_b[pink_bleed] = inner_b[pink_bleed]
        else:
            ob_r[pink_bleed] = np.minimum(ob_r[pink_bleed], ob_g[pink_bleed] + 4)
            ob_b[pink_bleed] = np.minimum(ob_b[pink_bleed], ob_g[pink_bleed] + 4)
            
        r[outer_band] = ob_r
        g[outer_band] = ob_g
        b[outer_band] = ob_b

    # 5. Boundary 2px dark inking pass to eliminate light rims and stray magenta fringes
    is_t = (new_a < 50)
    outer_2px = (new_a >= 50) & ndi.binary_dilation(is_t, iterations=2)
    
    # Light rim on outer 2px
    lum_edge = 0.299 * r[outer_2px] + 0.587 * g[outer_2px] + 0.114 * b[outer_2px]
    light_edge = (lum_edge > 165) & (r[outer_2px] > 145) & (g[outer_2px] > 140) & (b[outer_2px] > 130)
    if np.any(light_edge):
        r_sub = r[outer_2px]
        g_sub = g[outer_2px]
        b_sub = b[outer_2px]
        r_sub[light_edge] = np.minimum(r_sub[light_edge], 40.0)
        g_sub[light_edge] = np.minimum(g_sub[light_edge], 40.0)
        b_sub[light_edge] = np.minimum(b_sub[light_edge], 40.0)
        r[outer_2px] = r_sub
        g[outer_2px] = g_sub
        b[outer_2px] = b_sub

    # Magenta bleed on outer 2px
    h_edge = hue(np.dstack([r[outer_2px], g[outer_2px], b[outer_2px]])[0])
    dh_edge = np.abs(((h_edge - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
    chroma_edge = np.maximum(r[outer_2px], np.maximum(g[outer_2px], b[outer_2px])) - np.minimum(r[outer_2px], np.minimum(g[outer_2px], b[outer_2px]))
    pink_edge = (dh_edge < 24) & (chroma_edge > 70) & (r[outer_2px] > g[outer_2px] + 35) & (b[outer_2px] > g[outer_2px] + 15)
    if np.any(pink_edge):
        r_sub = r[outer_2px]
        g_sub = g[outer_2px]
        b_sub = b[outer_2px]
        r_sub[pink_edge] = np.minimum(r_sub[pink_edge], 40.0)
        g_sub[pink_edge] = np.minimum(g_sub[pink_edge], 40.0)
        b_sub[pink_edge] = np.minimum(b_sub[pink_edge], 40.0)
        r[outer_2px] = r_sub
        g[outer_2px] = g_sub
        b[outer_2px] = b_sub

    # Strictly zero alpha for alpha < 70
    new_a[new_a < 70] = 0.0
    
    res = np.dstack([r.astype(np.uint8), g.astype(np.uint8), b.astype(np.uint8), new_a.astype(np.uint8)])
    return Image.fromarray(res, "RGBA")

def cut_raw_item_icon(raw_path, target_size=256, fill_pct=0.85):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.array(im_pil, dtype=float)
    H, W, _ = im.shape
    
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    dist = np.sqrt(np.sum((im - bgc)**2, axis=-1))
    mag_metric = (r + b) - 2.0 * g
    is_mag = (dist < 90) | ((r > 120) & (b > 60) & (g < 110) & (mag_metric > 50))
    
    labeled, num_features = ndi.label(is_mag)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    obj = ~bg
    
    labeled_obj, num_obj = ndi.label(obj)
    if num_obj > 0:
        sizes = ndi.sum(obj, labeled_obj, range(1, num_obj + 1))
        max_idx = np.argmax(sizes) + 1
        obj = (labeled_obj == max_idx)
        
    eroded = ndi.binary_erosion(obj, iterations=1)
    outer_1px = obj & (~eroded)
    
    alpha = np.zeros((H, W), dtype=float)
    alpha[eroded] = 255.0
    alpha[outer_1px] = 200.0
    
    eroded_3px = ndi.binary_erosion(obj, iterations=3)
    outer_band = obj & (~eroded_3px)
    
    im_clean = im.copy()
    if np.any(eroded_3px):
        _, indices = ndi.distance_transform_edt(~eroded_3px, return_indices=True)
        near_y = indices[0][outer_band]
        near_x = indices[1][outer_band]
        inner_r = im[near_y, near_x, 0]
        inner_g = im[near_y, near_x, 1]
        inner_b = im[near_y, near_x, 2]
        ob_r = im_clean[outer_band, 0]
        ob_g = im_clean[outer_band, 1]
        ob_b = im_clean[outer_band, 2]
        
        pink_tint = (ob_r > ob_g + 10) & (ob_b > ob_g + 6) & ((ob_r + ob_b) > 2.0 * ob_g + 20)
        im_clean[outer_band, 0] = np.where(pink_tint, inner_r, ob_r)
        im_clean[outer_band, 1] = np.where(pink_tint, inner_g, ob_g)
        im_clean[outer_band, 2] = np.where(pink_tint, inner_b, ob_b)
        
        lum = 0.299 * im_clean[outer_band, 0] + 0.587 * im_clean[outer_band, 1] + 0.114 * im_clean[outer_band, 2]
        light_rim = (lum > 160) & (im_clean[outer_band, 0] > 140) & (im_clean[outer_band, 1] > 140) & (im_clean[outer_band, 2] > 140)
        im_clean[outer_band, 0] = np.where(light_rim, np.minimum(im_clean[outer_band, 0], 40.0), im_clean[outer_band, 0])
        im_clean[outer_band, 1] = np.where(light_rim, np.minimum(im_clean[outer_band, 1], 40.0), im_clean[outer_band, 1])
        im_clean[outer_band, 2] = np.where(light_rim, np.minimum(im_clean[outer_band, 2], 40.0), im_clean[outer_band, 2])

    ys, xs = np.nonzero(alpha >= 70)
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    crop_rgb = im_clean[y0:y1, x0:x1]
    crop_a = alpha[y0:y1, x0:x1]
    crop_rgba = np.dstack([crop_rgb.astype(np.uint8), crop_a.astype(np.uint8)])
    crop_img = Image.fromarray(crop_rgba, "RGBA")
    
    obj_w, obj_h = crop_img.size
    max_d = max(obj_w, obj_h)
    target_d = int(round(target_size * fill_pct))
    scale = target_d / float(max_d)
    new_w = max(1, int(round(obj_w * scale)))
    new_h = max(1, int(round(obj_h * scale)))
    
    resized = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - new_w) // 2
    paste_y = (target_size - new_h) // 2
    canvas.paste(resized, (paste_x, paste_y), resized)
    
    arr_fin = np.array(canvas).astype(float)
    arr_fin[arr_fin[..., 3] < 70, 3] = 0.0
    
    a_f = arr_fin[..., 3]
    is_t = (a_f < 50)
    outer_f = (a_f >= 50) & ndi.binary_dilation(is_t, iterations=2)
    lum_f = 0.299 * arr_fin[..., 0] + 0.587 * arr_fin[..., 1] + 0.114 * arr_fin[..., 2]
    light_f = outer_f & (lum_f > 165) & (arr_fin[..., 0] > 140) & (arr_fin[..., 1] > 140) & (arr_fin[..., 2] > 130)
    if np.any(light_f):
        arr_fin[light_f, 0] = np.minimum(arr_fin[light_f, 0], 40.0)
        arr_fin[light_f, 1] = np.minimum(arr_fin[light_f, 1], 40.0)
        arr_fin[light_f, 2] = np.minimum(arr_fin[light_f, 2], 40.0)
        
    return Image.fromarray(arr_fin.astype(np.uint8), "RGBA")

def main():
    print("=" * 70)
    print("Gym Oath 34-Asset Cutout Processing Pipeline")
    print("=" * 70)
    
    processed_assets = {}
    manifest_records = {}
    
    # 1. Process List A (16)
    print("\n--- Processing List A: Creatures with Magenta Outline (16) ---")
    for item in ASSETS_A:
        aid = item["id"]
        rel_p = item["file"]
        exp_sz = item["expected_size"]
        src = load_cnvpmg_image(rel_p)
        fixed = recut_creature(src, item_id=aid)
        
        assert fixed.size == exp_sz, f"Size mismatch for {aid}: {fixed.size} != {exp_sz}"
        p_rim = count_pink_rim_pixels(fixed)
        l_rim = count_light_rim_pixels(fixed)
        haze = count_haze_pixels(fixed)
        assert p_rim == 0, f"Pink rim not zero on {aid}: {p_rim}"
        assert l_rim == 0, f"Light rim not zero on {aid}: {l_rim}"
        assert haze == 0, f"Haze not zero on {aid}: {haze}"
        
        print(f"[{aid:22}] size={str(fixed.size):12} pink_rim={p_rim} light_rim={l_rim} haze={haze} [PASS]")
        processed_assets[aid] = fixed
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": item["method"],
            "size": fixed.size[0],
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": 0,
            "status": "done"
        }
        
    # 2. Process List B (10)
    print("\n--- Processing List B: Creatures with Grey Haze / Smoke (10) ---")
    for item in ASSETS_B:
        aid = item["id"]
        rel_p = item["file"]
        exp_sz = item["expected_size"]
        src = load_cnvpmg_image(rel_p)
        fixed = recut_creature(src, item_id=aid)
        
        assert fixed.size == exp_sz, f"Size mismatch for {aid}: {fixed.size} != {exp_sz}"
        p_rim = count_pink_rim_pixels(fixed)
        l_rim = count_light_rim_pixels(fixed)
        haze = count_haze_pixels(fixed)
        assert p_rim == 0, f"Pink rim not zero on {aid}: {p_rim}"
        assert l_rim == 0, f"Light rim not zero on {aid}: {l_rim}"
        assert haze == 0, f"Haze not zero on {aid}: {haze}"
        
        print(f"[{aid:22}] size={str(fixed.size):12} pink_rim={p_rim} light_rim={l_rim} haze={haze} [PASS]")
        processed_assets[aid] = fixed
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": item["method"],
            "size": fixed.size[0],
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": 0,
            "status": "done"
        }
        
    # 3. Process List C (8)
    print("\n--- Processing List C: Item Icons (8) ---")
    for item in ASSETS_C:
        aid = item["id"]
        rel_p = item["file"]
        exp_sz = item["expected_size"]
        raw_p = os.path.join(RAW_DIR, f"{aid}.png")
        if not os.path.exists(raw_p):
            raise FileNotFoundError(f"Raw image for item {aid} not found: {raw_p}")
            
        fixed = cut_raw_item_icon(raw_p, target_size=256, fill_pct=0.85)
        
        assert fixed.size == exp_sz, f"Size mismatch for {aid}: {fixed.size} != {exp_sz}"
        p_rim = count_pink_rim_pixels(fixed)
        l_rim = count_light_rim_pixels(fixed)
        haze = count_haze_pixels(fixed)
        assert p_rim == 0, f"Pink rim not zero on {aid}: {p_rim}"
        assert l_rim == 0, f"Light rim not zero on {aid}: {l_rim}"
        assert haze == 0, f"Haze not zero on {aid}: {haze}"
        
        print(f"[{aid:22}] size={str(fixed.size):12} pink_rim={p_rim} light_rim={l_rim} haze={haze} [PASS]")
        processed_assets[aid] = fixed
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": item["method"],
            "size": 256,
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": 0,
            "status": "done"
        }

    # 4. Save all 34 assets to disk (both repo and iron-oath-art)
    print("\n--- Saving all 34 assets to repo and iron-oath-art ---")
    for aid, im in processed_assets.items():
        rel_p = manifest_records[aid]["file"]
        repo_target = os.path.join(REPO_DIR, rel_p)
        iron_target = os.path.join(IRON_DIR, rel_p)
        
        os.makedirs(os.path.dirname(repo_target), exist_ok=True)
        os.makedirs(os.path.dirname(iron_target), exist_ok=True)
        
        im.save(repo_target, format="PNG")
        im.save(iron_target, format="PNG")
        print(f"  Saved {aid} -> {rel_p}")

    # 5. Build check_ritagli.png (all 34 assets: 3 full @ 256px + 3 edge zoom 2x @ 256px)
    print("\n--- Generating check_ritagli.png (34 assets x 6 panels) ---")
    cols = 6
    rows = len(ALL_ASSETS)
    cell = 256
    sheet = Image.new("RGB", (cols * cell, rows * cell), (0, 0, 0))
    
    c_grey = (127, 122, 112) # #7F7A70
    c_black = (13, 11, 9)    # #0D0B09
    c_white = (242, 242, 242) # #F2F2F2
    
    for r_idx, item in enumerate(ALL_ASSETS):
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
        
        # Panel 4, 5, 6: 2x zoom on edge
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

    sheet.save(CHECK_IMAGE_IRON, format="PNG")
    sheet.save(CHECK_IMAGE_ROOT, format="PNG")
    print(f"Check sheet saved: {CHECK_IMAGE_IRON} and {CHECK_IMAGE_ROOT} ({sheet.size})")

    # 6. Update manifests
    print("\n--- Updating manifests ---")
    
    # A. Root manifest.json (dict)
    root_manifest = {}
    if os.path.exists(MANIFEST_ROOT):
        try:
            with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
                root_manifest = json.load(f)
        except Exception:
            root_manifest = {}
            
    for aid, rec in manifest_records.items():
        if aid in root_manifest:
            root_manifest[aid].update(rec)
        else:
            root_manifest[aid] = rec
            
    with open(MANIFEST_ROOT, "w", encoding="utf-8") as f:
        json.dump(root_manifest, f, indent=2)
    print(f"Updated {MANIFEST_ROOT}")
    
    # B. assets/art/manifest.json (list)
    art_manifest = []
    if os.path.exists(MANIFEST_ART):
        try:
            with open(MANIFEST_ART, "r", encoding="utf-8") as f:
                art_manifest = json.load(f)
        except Exception:
            art_manifest = []
            
    art_map = {item.get("id"): item for item in art_manifest if isinstance(item, dict)}
    for aid, rec in manifest_records.items():
        if aid in art_map:
            art_map[aid].update(rec)
        else:
            art_map[aid] = rec
            art_manifest.append(art_map[aid])
            
    with open(MANIFEST_ART, "w", encoding="utf-8") as f:
        json.dump(art_manifest, f, indent=2)
    print(f"Updated {MANIFEST_ART}")
    
    # C. iron-oath-art/manifest.json (list)
    iron_manifest = []
    if os.path.exists(MANIFEST_IRON):
        try:
            with open(MANIFEST_IRON, "r", encoding="utf-8") as f:
                iron_manifest = json.load(f)
        except Exception:
            iron_manifest = []
            
    iron_map = {item.get("id"): item for item in iron_manifest if isinstance(item, dict)}
    for aid, rec in manifest_records.items():
        if aid in iron_map:
            iron_map[aid].update(rec)
        else:
            iron_map[aid] = rec
            iron_manifest.append(iron_map[aid])
            
    with open(MANIFEST_IRON, "w", encoding="utf-8") as f:
        json.dump(iron_manifest, f, indent=2)
    print(f"Updated {MANIFEST_IRON}")

    # D. iron-oath-art/assets_list.json
    assets_list = []
    if os.path.exists(ASSETS_LIST_IRON):
        try:
            with open(ASSETS_LIST_IRON, "r", encoding="utf-8") as f:
                assets_list = json.load(f)
        except Exception:
            assets_list = []
    existing_ids = {a.get("id") for a in assets_list if isinstance(a, dict)}
    for aid, rec in manifest_records.items():
        if aid not in existing_ids:
            assets_list.append(rec)
            existing_ids.add(aid)
    with open(ASSETS_LIST_IRON, "w", encoding="utf-8") as f:
        json.dump(assets_list, f, indent=2)
    print(f"Updated {ASSETS_LIST_IRON}")

    # 7. Create ZIP backup in iron-oath-art and repo
    print("\n--- Creating ZIP archive of delivered assets ---")
    for zpath in [ZIP_BACKUP_IRON, ZIP_BACKUP_REPO]:
        with zipfile.ZipFile(zpath, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for aid, rec in manifest_records.items():
                rel_p = rec["file"]
                abs_p = os.path.join(REPO_DIR, rel_p)
                zf.write(abs_p, arcname=rel_p)
            zf.write(CHECK_IMAGE_ROOT, arcname="check_ritagli.png")
            zf.write(MANIFEST_ROOT, arcname="manifest.json")
        print(f"Created ZIP backup: {zpath}")

    print("\n=======================================================")
    print("SUCCESS: All 34 assets cut, verified, and saved!")
    print("=======================================================")

if __name__ == "__main__":
    main()
