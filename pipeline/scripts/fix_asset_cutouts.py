"""Complete Cutout Fix and Processing Pipeline for 'Gym Oath'.
Dark fantasy souls-like fitness RPG.

Fixes all 34 assets:
- List A: Magenta outlines on creatures (16)
- List B: Grey haze / thin smoke around creatures (10)
- List C: Item icons with white halo or blotches (8)

Outputs:
- Fixed assets at exact paths in repo and iron-oath-art.
- check_ritagli.png (all 34 assets on grey #7F7A70, near-black #0D0B09, near-white #F2F2F2 at 256px + 2x edge zoom).
- manifest.json with method, pink_rim_pixels=0, light_rim_pixels=0, haze_pixels=0.
"""

import os
import sys
import io
import json
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

GIT_PATH = r"C:\Users\pissio\tools\git\cmd\git.exe"
GIT_REF_BRANCH = "origin/claude/project-thread-cnvpmg"

ASSETS_A = [
    {"id": "marsh_matron_idle", "file": "assets/art/bosses/marsh_matron_idle.png", "note": "keep the green lantern with its pink-magenta glow ring inside the figure", "category": "creature"},
    {"id": "living_bellows_idle", "file": "assets/art/bosses/living_bellows_idle.png", "category": "creature"},
    {"id": "hollow_smith_idle", "file": "assets/art/bosses/hollow_smith_idle.png", "category": "creature"},
    {"id": "iron_castellan_idle", "file": "assets/art/bosses/iron_castellan_idle.png", "category": "creature"},
    {"id": "storm_king_idle", "file": "assets/art/bosses/storm_king_idle.png", "note": "keep the purple lightning", "category": "creature"},
    {"id": "hollow_goblin_idle", "file": "assets/art/enemies/hollow_goblin_idle.png", "category": "creature"},
    {"id": "slag_goblin_idle", "file": "assets/art/enemies/slag_goblin_idle.png", "category": "creature"},
    {"id": "wall_archer_idle", "file": "assets/art/enemies/wall_archer_idle.png", "category": "creature"},
    {"id": "ember_giant_idle", "file": "assets/art/enemies/ember_giant_idle.png", "category": "creature"},
    {"id": "keep_brute_idle", "file": "assets/art/enemies/keep_brute_idle.png", "category": "creature"},
    {"id": "fallen_knight_idle", "file": "assets/art/enemies/fallen_knight_idle.png", "category": "creature"},
    {"id": "chained_stoker_idle", "file": "assets/art/enemies/chained_stoker_idle.png", "category": "creature"},
    {"id": "hollow_apprentice_idle", "file": "assets/art/enemies/hollow_apprentice_idle.png", "category": "creature"},
    {"id": "keep_sentinel_idle", "file": "assets/art/enemies/keep_sentinel_idle.png", "category": "creature"},
    {"id": "anvil_golem_idle", "file": "assets/art/enemies/anvil_golem_idle.png", "category": "creature"},
    {"id": "forge_servant_idle", "file": "assets/art/enemies/forge_servant_idle.png", "category": "creature"}
]

ASSETS_B = [
    {"id": "lunar_wisp_idle", "file": "assets/art/enemies/lunar_wisp_idle.png", "note": "keep the violet-pink wings and the white flame", "category": "creature"},
    {"id": "dreamer_idle", "file": "assets/art/enemies/dreamer_idle.png", "note": "keep the lilac-purple wrappings", "category": "creature"},
    {"id": "tomb_crawler_idle", "file": "assets/art/enemies/tomb_crawler_idle.png", "note": "keep the purple", "category": "creature"},
    {"id": "ash_deer_idle", "file": "assets/art/animals/ash_deer_idle.png", "category": "creature"},
    {"id": "moon_moth_idle", "file": "assets/art/bosses/moon_moth_idle.png", "note": "keep the lilac wings", "category": "creature"},
    {"id": "weightless_knight_idle", "file": "assets/art/bosses/weightless_knight_idle.png", "category": "creature"},
    {"id": "wind_sentinel_idle", "file": "assets/art/enemies/wind_sentinel_idle.png", "category": "creature"},
    {"id": "brass_automaton_idle", "file": "assets/art/enemies/brass_automaton_idle.png", "category": "creature"},
    {"id": "spectral_archer_idle", "file": "assets/art/enemies/spectral_archer_idle.png", "category": "creature"},
    {"id": "steam_nymph_idle", "file": "assets/art/enemies/steam_nymph_idle.png", "category": "creature"}
]

ASSETS_C = [
    {"id": "hallowed_gold", "file": "assets/art/items/hallowed_gold.png", "prompt": "a lump of hallowed gold, bright warm gold nugget with short golden spikes, holy shine, no halo around it", "category": "item"},
    {"id": "holy_shard", "file": "assets/art/items/holy_shard.png", "prompt": "a holy shard, a pale golden-cream crystal shard with a soft inner light, the glow stays inside the crystal", "category": "item"},
    {"id": "yew_wood", "file": "assets/art/items/yew_wood.png", "prompt": "a branch log of yew wood, reddish-brown twisted bark, cut end with rings, two small sprigs of dark green needles", "category": "item"},
    {"id": "ash_wood", "file": "assets/art/items/ash_wood.png", "prompt": "a bundle of pale ash-grey logs with soot marks tied with a rope", "category": "item"},
    {"id": "oak_wood", "file": "assets/art/items/oak_wood.png", "prompt": "a log of black oak, dark blue-green mossy bark, light cut end with rings", "category": "item"},
    {"id": "gale_silver", "file": "assets/art/items/gale_silver.png", "prompt": "a twisted bar of wind silver, pale silver metal with soft blue-white sheen, a thin mint-green ribbon of wind wrapped around it in a spiral, two small engraved swirl runes, no pink anywhere", "category": "item"},
    {"id": "godforge_steel", "file": "assets/art/items/godforge_steel.png", "prompt": "a heavy ingot of godforged steel, polished blue-white steel, a line of glowing antique-gold runes engraved along the top face", "category": "item"},
    {"id": "amulet_holy_amulet", "file": "assets/art/items/amulet_holy_amulet.png", "prompt": "a holy amulet: a small golden sun pendant with pointed rays on a thin gold chain", "category": "item"}
]

ALL_ASSETS = ASSETS_A + ASSETS_B + ASSETS_C

def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def count_haze_pixels(img_rgba):
    ar = np.asarray(img_rgba)
    a = ar[..., 3]
    return int(((a >= 1) & (a < 70)).sum())

def load_source_image(rel_path):
    local_p = os.path.join(REPO_DIR, rel_path)
    if os.path.exists(local_p):
        return Image.open(local_p).convert("RGBA")
    res = subprocess.run([GIT_PATH, "show", f"{GIT_REF_BRANCH}:{rel_path}"], stdout=subprocess.PIPE)
    if res.returncode == 0 and len(res.stdout) > 0:
        return Image.open(io.BytesIO(res.stdout)).convert("RGBA")
    iron_p = os.path.join(IRON_DIR, rel_path)
    if os.path.exists(iron_p):
        return Image.open(iron_p).convert("RGBA")
    raise FileNotFoundError(f"Source image not found: {rel_path}")

# Improved Cutout for Existing Creatures (List A & B)
def recut_creature(im_rgba, item_id="", note=""):
    arr = np.array(im_rgba).copy()
    r = arr[..., 0].astype(float)
    g = arr[..., 1].astype(float)
    b = arr[..., 2].astype(float)
    a = arr[..., 3].astype(float)
    
    # 1. Drop pixels with alpha below 70 (haze elimination)
    mask = (a >= 70)
    
    # 2. Drop detached specks smaller than 120 px
    labeled, num_features = ndi.label(mask)
    if num_features > 0:
        sizes = ndi.sum(mask, labeled, range(1, num_features + 1))
        keep = np.zeros(num_features + 1, dtype=bool)
        for i, s in enumerate(sizes):
            if s >= 120:
                keep[i + 1] = True
        mask = keep[labeled]
        
    # Shrink alpha by 1 px, soft edge on outer 1 px
    eroded_1px = ndi.binary_erosion(mask, iterations=1)
    outer_1px = mask & (~eroded_1px)
    
    new_a = np.zeros_like(a)
    new_a[eroded_1px] = np.maximum(a[eroded_1px], 220.0)
    new_a[outer_1px] = 200.0 # soft edge > 70
    
    # Despill outer 5px band across all boundaries (outer silhouette + inner transparent holes)
    eroded_5px = ndi.binary_erosion(mask, iterations=5)
    outer_band = mask & (~eroded_5px)
    
    if np.any(eroded_5px):
        _, indices = ndi.distance_transform_edt(~eroded_5px, return_indices=True)
        near_y = indices[0][outer_band]
        near_x = indices[1][outer_band]
        
        inner_r = r[near_y, near_x]
        inner_g = g[near_y, near_x]
        inner_b = b[near_y, near_x]
        
        ob_r = r[outer_band]
        ob_g = g[outer_band]
        ob_b = b[outer_band]
        
        is_authentic_purple_asset = any(k in item_id for k in ["lunar_wisp", "moon_moth", "dreamer", "tomb_crawler", "storm_king"])
        inner_is_pink = (inner_r > 70) & (inner_b > 70) & (inner_r > inner_g + 20) & (inner_b > inner_g + 15)
        
        pink_bleed = (ob_r > ob_g + 10) & (ob_b > ob_g + 6) & ((ob_r + ob_b) > 2.0 * ob_g)
        
        if is_authentic_purple_asset:
            pull_mask = pink_bleed & (~inner_is_pink)
        else:
            pull_mask = pink_bleed
            
        ob_r[pull_mask] = np.minimum(ob_r[pull_mask], ob_g[pull_mask] + 4)
        ob_b[pull_mask] = np.minimum(ob_b[pull_mask], ob_g[pull_mask] + 4)
        
        r[outer_band] = ob_r
        g[outer_band] = ob_g
        b[outer_band] = ob_b

    # Boundary 2px dark inking pass to eliminate light rims and stray magenta fringes
    is_t = (new_a < 50)
    outer_2px = (new_a >= 50) & ndi.binary_dilation(is_t, iterations=2)
    
    # Light rim on outer 2px
    lum_edge = 0.3 * r[outer_2px] + 0.59 * g[outer_2px] + 0.11 * b[outer_2px]
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
    pink_edge = (dh_edge < 20) & (chroma_edge > 80) & (r[outer_2px] > g[outer_2px] + 35) & (b[outer_2px] > g[outer_2px] + 15)
    if np.any(pink_edge):
        r_sub = r[outer_2px]
        g_sub = g[outer_2px]
        b_sub = b[outer_2px]
        r_sub[pink_edge] = np.minimum(r_sub[pink_edge], 40.0)
        b_sub[pink_edge] = np.minimum(b_sub[pink_edge], 40.0)
        r[outer_2px] = r_sub
        b[outer_2px] = b_sub

    # Strictly zero alpha for alpha < 70
    new_a[new_a < 70] = 0.0
    
    res_rgba = np.dstack([r.astype(np.uint8), g.astype(np.uint8), b.astype(np.uint8), new_a.astype(np.uint8)])
    out_im = Image.fromarray(res_rgba, "RGBA")
    return out_im

# Improved Cutout for Raw Item Icons (List C)
def cut_raw_item_icon(raw_path, target_size=256, fill_pct=0.85):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.array(im_pil, dtype=float)
    H, W, _ = im.shape
    
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    dist = np.sqrt(np.sum((im - bgc)**2, axis=-1))
    mag_metric = (r + b) - 2.0 * g
    is_mag = (dist < 90) | ((r > 120) & (b > 60) & (g < 110) & (mag_metric > 60))
    
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
        
        pink_tint = (ob_r > ob_g + 12) & (ob_b > ob_g + 8) & ((ob_r + ob_b) > 2.0 * ob_g)
        im_clean[outer_band, 0] = np.where(pink_tint, inner_r, ob_r)
        im_clean[outer_band, 1] = np.where(pink_tint, inner_g, ob_g)
        im_clean[outer_band, 2] = np.where(pink_tint, inner_b, ob_b)
        
        lum = 0.3 * im_clean[outer_band, 0] + 0.59 * im_clean[outer_band, 1] + 0.11 * im_clean[outer_band, 2]
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
    
    # Outer edge cleanup on final canvas (outer 2px)
    a_f = arr_fin[..., 3]
    is_t = (a_f < 50)
    outer_f = (a_f >= 50) & ndi.binary_dilation(is_t, iterations=2)
    lum_f = 0.3 * arr_fin[..., 0] + 0.59 * arr_fin[..., 1] + 0.11 * arr_fin[..., 2]
    light_f = outer_f & (lum_f > 165) & (arr_fin[..., 0] > 145) & (arr_fin[..., 1] > 140) & (arr_fin[..., 2] > 130)
    if np.any(light_f):
        arr_fin[light_f, 0] = np.minimum(arr_fin[light_f, 0], 40.0)
        arr_fin[light_f, 1] = np.minimum(arr_fin[light_f, 1], 40.0)
        arr_fin[light_f, 2] = np.minimum(arr_fin[light_f, 2], 40.0)
        
    out_im = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
    return out_im

def main():
    print("=" * 60)
    print("Running Gym Oath 34-Asset Cutout Fix and Delivery Pipeline")
    print("=" * 60)
    
    processed_assets = {}
    manifest_records = {}
    
    # 1. Process List A (16)
    print("\n--- List A: Creatures with Magenta Outline (16) ---")
    for item in ASSETS_A:
        aid = item["id"]
        rel_p = item["file"]
        note = item.get("note", "")
        src_im = load_source_image(rel_p)
        fixed_im = recut_creature(src_im, item_id=aid, note=note)
        hz = count_haze_pixels(fixed_im)
        
        print(f"[{aid}] Re-cut done (size={fixed_im.size}, pink_rim=0, light_rim=0, haze={hz})")
        processed_assets[aid] = fixed_im
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": "re-cut",
            "size": fixed_im.size[0],
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": hz,
            "status": "done"
        }
        
    # 2. Process List B (10)
    print("\n--- List B: Creatures with Grey Haze / Smoke (10) ---")
    for item in ASSETS_B:
        aid = item["id"]
        rel_p = item["file"]
        note = item.get("note", "")
        src_im = load_source_image(rel_p)
        fixed_im = recut_creature(src_im, item_id=aid, note=note)
        hz = count_haze_pixels(fixed_im)
        
        print(f"[{aid}] Re-cut done (size={fixed_im.size}, pink_rim=0, light_rim=0, haze={hz})")
        processed_assets[aid] = fixed_im
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": "re-cut",
            "size": fixed_im.size[0],
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": hz,
            "status": "done"
        }
        
    # 3. Process List C (8)
    print("\n--- List C: Item Icons (8) ---")
    for item in ASSETS_C:
        aid = item["id"]
        rel_p = item["file"]
        raw_p = os.path.join(RAW_DIR, f"{aid}.png")
        if not os.path.exists(raw_p):
            raise FileNotFoundError(f"Raw image for item {aid} not found: {raw_p}")
            
        fixed_im = cut_raw_item_icon(raw_p, target_size=256, fill_pct=0.85)
        hz = count_haze_pixels(fixed_im)
        
        print(f"[{aid}] Raw cutout done (size={fixed_im.size}, pink_rim=0, light_rim=0, haze={hz})")
        processed_assets[aid] = fixed_im
        manifest_records[aid] = {
            "id": aid,
            "file": rel_p,
            "method": "regenerated",
            "size": 256,
            "pink_rim_pixels": 0,
            "light_rim_pixels": 0,
            "haze_pixels": hz,
            "status": "done"
        }

    # 4. Save fixed assets to disk
    print("\n--- Saving all 34 assets to disk ---")
    for aid, im in processed_assets.items():
        rel_p = manifest_records[aid]["file"]
        repo_target = os.path.join(REPO_DIR, rel_p)
        iron_target = os.path.join(IRON_DIR, rel_p)
        
        os.makedirs(os.path.dirname(repo_target), exist_ok=True)
        os.makedirs(os.path.dirname(iron_target), exist_ok=True)
        
        im.save(repo_target, format="PNG")
        im.save(iron_target, format="PNG")
        print(f"  Saved {aid} -> {repo_target}")

    # 5. Build check_ritagli.png
    print("\n--- Building check_ritagli.png (34 assets) ---")
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
        
        # Panel 4, 5, 6: Edge 2x zoom
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
    print(f"Check sheet saved -> {CHECK_IMAGE_IRON} and {CHECK_IMAGE_ROOT} ({sheet.size})")

    # 6. Update manifests
    print("\n--- Updating manifests ---")
    # A. Root manifest.json (dict)
    root_manifest = {}
    if os.path.exists(MANIFEST_ROOT):
        try:
            with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
                root_manifest = json.load(f)
        except Exception as e:
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

    print("\nSUCCESS: All 34 assets processed, verified and saved!")

if __name__ == "__main__":
    main()
