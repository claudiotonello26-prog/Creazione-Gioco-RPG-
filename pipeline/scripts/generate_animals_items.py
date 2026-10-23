"""Generation and Processing Pipeline for 'Gym Oath' Animals and Item Icons.
Mobile Dark Fantasy Medieval Fitness RPG (Souls-like: Dark Souls / Elden Ring aesthetic).
Batch:
- 5 Hunted Wild Animals (ash_hare_idle, red_fox_idle, grey_badger_idle, carrion_crow_idle, wild_goat_idle) -> assets/art/animals/ (512x512)
- 2 Remade Item Icons (gale_silver, godforge_steel) -> assets/art/items/ (256x256)
"""

import os
import sys
import io
import time
import json
import base64
import urllib.request
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
PIPELINE_DIR = os.path.join(REPO_DIR, "pipeline")
IRON_DIR = r"C:\Users\pissio\iron-oath-art"
RAW_DIR = os.path.join(IRON_DIR, "raw")
ANIMALS_DIR = os.path.join(REPO_DIR, "assets", "art", "animals")
ITEMS_DIR = os.path.join(REPO_DIR, "assets", "art", "items")
IRON_ANIMALS_DIR = os.path.join(IRON_DIR, "assets", "art", "animals")
IRON_ITEMS_DIR = os.path.join(IRON_DIR, "assets", "art", "items")

MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = os.path.join(IRON_DIR, "manifest.json")
ASSETS_LIST_IRON = os.path.join(IRON_DIR, "assets_list.json")

CHECK_IMAGE_IRON = os.path.join(IRON_DIR, "check_animals_items.png")
CHECK_IMAGE_ROOT = os.path.join(REPO_DIR, "check_animals_items.png")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(ANIMALS_DIR, exist_ok=True)
os.makedirs(ITEMS_DIR, exist_ok=True)
os.makedirs(IRON_ANIMALS_DIR, exist_ok=True)
os.makedirs(IRON_ITEMS_DIR, exist_ok=True)

# 1. API Key
GEMINI_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_KEY:
    env_p = os.path.join(PIPELINE_DIR, ".env")
    if os.path.exists(env_p):
        with open(env_p, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("GEMINI_API_KEY="):
                    GEMINI_KEY = line.strip().split("=", 1)[1]
                    break

if not GEMINI_KEY:
    raise ValueError("GEMINI_API_KEY not found in env or pipeline/.env!")

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

# 2. Reference Images
CREATURE_REF_PATHS = [
    os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "enemies", "hollow_goblin_idle.png"),
]

ITEM_REF_PATHS = [
    os.path.join(IRON_DIR, "assets", "art", "items", "silver_ingot.png"),
    os.path.join(IRON_DIR, "assets", "art", "items", "gold_ingot.png"),
]

def load_ref_b64(path, max_dim=512):
    im = Image.open(path)
    im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

CACHED_CREATURE_REFS = []
for rp in CREATURE_REF_PATHS:
    if os.path.exists(rp):
        CACHED_CREATURE_REFS.append({
            "name": os.path.basename(rp),
            "b64": load_ref_b64(rp)
        })

CACHED_ITEM_REFS = []
for rp in ITEM_REF_PATHS:
    if os.path.exists(rp):
        CACHED_ITEM_REFS.append({
            "name": os.path.basename(rp),
            "b64": load_ref_b64(rp)
        })

print(f"Loaded {len(CACHED_CREATURE_REFS)} creature references and {len(CACHED_ITEM_REFS)} item references.")

# 3. Batch Items Specification
BATCH_ITEMS = {
    "ash_hare_idle": {
        "id": "ash_hare_idle",
        "file": "assets/art/animals/ash_hare_idle.png",
        "type": "cutout",
        "category": "animal",
        "size": 512,
        "fill_pct": 0.80,
        "prompt": "Animal: a lean wild hare with ash-grey fur dusted with soot, long alert ears, one ear slightly torn, crouched ready to bolt. Colours: ash grey, pale bone belly, dark brown eyes.",
        "details": "Real wild animal of a grim world, level 1 prey: believable, a little ragged and wary, NOT a monster, NOT corrupted, no glowing eyes. Whole body visible, side three-quarter view, FACING LEFT, standing on nothing (no ground plate), filling about 80% of the canvas. Bold inked dark contours, dark fantasy souls-like painting style. Flat solid uniform magenta background #FF00FF filling entire canvas."
    },
    "red_fox_idle": {
        "id": "red_fox_idle",
        "file": "assets/art/animals/red_fox_idle.png",
        "type": "cutout",
        "category": "animal",
        "size": 512,
        "fill_pct": 0.80,
        "prompt": "Animal: a cunning red fox with a thick russet coat, white chest and tail tip, black legs, low sneaking stance, sharp narrow eyes. Colours: rust red, cream white, charcoal legs.",
        "details": "Real wild animal of a grim world, level 1 prey: believable, a little ragged and wary, NOT a monster, NOT corrupted, no glowing eyes. Whole body visible, side three-quarter view, FACING LEFT, standing on nothing (no ground plate), filling about 80% of the canvas. Bold inked dark contours, dark fantasy souls-like painting style. Flat solid uniform magenta background #FF00FF filling entire canvas."
    },
    "grey_badger_idle": {
        "id": "grey_badger_idle",
        "file": "assets/art/animals/grey_badger_idle.png",
        "type": "cutout",
        "category": "animal",
        "size": 512,
        "fill_pct": 0.80,
        "prompt": "Animal: a stocky grey badger with the black and white striped face, coarse silver-grey fur, short powerful legs with digging claws, head low and stubborn. Colours: silver grey, black, white stripes.",
        "details": "Real wild animal of a grim world, level 1 prey: believable, a little ragged and wary, NOT a monster, NOT corrupted, no glowing eyes. Whole body visible, side three-quarter view, FACING LEFT, standing on nothing (no ground plate), filling about 80% of the canvas. Bold inked dark contours, dark fantasy souls-like painting style. Flat solid uniform magenta background #FF00FF filling entire canvas."
    },
    "carrion_crow_idle": {
        "id": "carrion_crow_idle",
        "file": "assets/art/animals/carrion_crow_idle.png",
        "type": "cutout",
        "category": "animal",
        "size": 512,
        "fill_pct": 0.80,
        "prompt": "Animal: a big black carrion crow standing on the ground, wings half open, ragged glossy feathers with a faint blue-green sheen, heavy beak open in a caw. Colours: glossy black, dark blue-green sheen, grey beak.",
        "details": "Real wild animal of a grim world, level 1 prey: believable, a little ragged and wary, NOT a monster, NOT corrupted, no glowing eyes. Whole body visible, side three-quarter view, FACING LEFT, standing on nothing (no ground plate), filling about 80% of the canvas. Bold inked dark contours, dark fantasy souls-like painting style. Flat solid uniform magenta background #FF00FF filling entire canvas."
    },
    "wild_goat_idle": {
        "id": "wild_goat_idle",
        "file": "assets/art/animals/wild_goat_idle.png",
        "type": "cutout",
        "category": "animal",
        "size": 512,
        "fill_pct": 0.80,
        "prompt": "Animal: a shaggy wild mountain goat with long curved ridged horns, a scruffy beard, brown-grey coat with a darker stripe on the back, standing firmly. Colours: grey-brown, dark umber, horn beige.",
        "details": "Real wild animal of a grim world, level 1 prey: believable, a little ragged and wary, NOT a monster, NOT corrupted, no glowing eyes. Whole body visible, side three-quarter view, FACING LEFT, standing on nothing (no ground plate), filling about 80% of the canvas. Bold inked dark contours, dark fantasy souls-like painting style. Flat solid uniform magenta background #FF00FF filling entire canvas."
    },
    "gale_silver": {
        "id": "gale_silver",
        "file": "assets/art/items/gale_silver.png",
        "type": "cutout",
        "category": "item",
        "size": 256,
        "fill_pct": 0.85,
        "prompt": "Item: a twisted bar of wind silver, pale silver metal with soft blue-white sheen, a thin mint-green ribbon of wind wrapped around it in a spiral, two small engraved swirl runes. Colours: silver, pale blue, mint green. No pink anywhere.",
        "details": "One object, centred, slightly from above at three-quarter view, filling about 85% of the canvas, same painted icon style as silver_ingot.png and gold_ingot.png. Crisp metallic facets, bold dark ink contour lines, hand-painted dark fantasy illustration. Flat solid uniform magenta background #FF00FF filling entire canvas with no gradients or ground shadow."
    },
    "godforge_steel": {
        "id": "godforge_steel",
        "file": "assets/art/items/godforge_steel.png",
        "type": "cutout",
        "category": "item",
        "size": 256,
        "fill_pct": 0.85,
        "prompt": "Item: a heavy ingot of godforged steel, bright polished blue-white steel, a line of glowing antique-gold runes engraved along the top face, faint warm light inside the runes. Colours: steel blue-white, antique gold.",
        "details": "One object, centred, slightly from above at three-quarter view, filling about 85% of the canvas, same painted icon style as silver_ingot.png and gold_ingot.png. Crisp metallic facets, bold dark ink contour lines, hand-painted dark fantasy illustration. Flat solid uniform magenta background #FF00FF filling entire canvas with no gradients or ground shadow."
    }
}

ORDER = [
    "ash_hare_idle",
    "red_fox_idle",
    "grey_badger_idle",
    "carrion_crow_idle",
    "wild_goat_idle",
    "gale_silver",
    "godforge_steel"
]

# 4. Color utilities & quality checks
def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def count_pink_pixels(img_rgba, bgc=np.array([255.0, 0.0, 255.0])):
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    h = hue(ar[..., :3])
    dh = np.abs(((h - hue(bgc)) + 180) % 360 - 180)
    chroma = ar[..., :3].max(-1) - ar[..., :3].min(-1)
    
    # Pink fringe condition
    pink = (a > 20) & (dh < 24) & (chroma > 80) & (r > g + 40) & (b > g + 20)
    return int(pink.sum())

def count_light_rim_pixels(img_rgba):
    """Detects any light/cream/white rim pixels along the outer boundary of the cutout."""
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    
    # Outer edge: pixels with alpha > 40 adjacent to transparent area (alpha < 40)
    is_transp = (a < 40)
    outer_edge = (a >= 40) & ndi.binary_dilation(is_transp, iterations=2)
    
    lum = (0.3 * r + 0.59 * g + 0.11 * b)
    # Light rim: high brightness or washed out white/cream tone on outer edge
    light_rim = outer_edge & (lum > 175) & (r > 150) & (g > 145) & (b > 135)
    return int(light_rim.sum())

# 5. Gemini API Call
def generate_raw(item_id, max_retries=3):
    info = BATCH_ITEMS[item_id]
    category = info["category"]
    
    parts = []
    if category == "animal":
        for ref in CACHED_CREATURE_REFS:
            parts.append({"text": f"Style Reference ({ref['name']}): Match this painting technique, inked outlines, level of detail and lighting of these reference images, but draw a completely different subject and use ONLY the colours written in this prompt:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
        
        full_prompt = (
            "Gym Oath is a dark fantasy medieval fitness RPG for phones, souls-like style (Dark Souls, Elden Ring): "
            "ruined gothic world, ash, stone, iron, warm antique gold as the only bright colour.\n"
            "STYLE REFERENCES: Match the painting technique, inked outlines, level of detail and lighting of these reference images, "
            "but draw a completely different subject and use ONLY the colours written in this prompt.\n"
            "Hand-painted dark fantasy illustration, bold inked outlines, rich but muted colours, soft rim light, readable even as a small thumbnail. "
            "No text, no letters, no frame, no UI, no watermark.\n"
            "CRITICAL BACKGROUND RULE: Flat solid magenta background #FF00FF filling the whole canvas: no shadows, gradients, floor, smoke, "
            "particles or glow spreading on the background. Nothing of the subject is magenta or pink. Glows and smoke stay tight and opaque around the subject.\n\n"
            f"SUBJECT: {info['prompt']}\n"
            f"COMPOSITION: {info['details']}"
        )
    else: # item
        for ref in CACHED_ITEM_REFS:
            parts.append({"text": f"Style Reference ({ref['name']}): Match the painted icon style, metallic shading, bold inked outlines, and lighting of this reference item icon:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
            
        full_prompt = (
            "Dark fantasy medieval mobile game item icon, souls-like atmosphere (Dark Souls, Elden Ring, Gym Oath). "
            "STYLE REFERENCES: Same painted icon style as silver_ingot.png and gold_ingot.png in the repository (passed as style reference). "
            "Match the painting technique, crisp metallic facets, bold inked outlines, and lighting.\n"
            "Hand-painted dark fantasy illustration, bold inked outlines, rich but muted colours, readable even as a small inventory icon. "
            "No text, no letters, no frame, no UI, no watermark.\n"
            "CRITICAL BACKGROUND RULE: Flat solid magenta background #FF00FF filling the whole canvas: no shadows, gradients, floor, smoke, "
            "particles or glow spreading on the background. Nothing of the subject is magenta or pink.\n\n"
            f"SUBJECT: {info['prompt']}\n"
            f"COMPOSITION: {info['details']}"
        )
        
    parts.append({"text": full_prompt})
    
    payload = {"contents": [{"parts": parts}]}
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    
    for attempt in range(max_retries):
        try:
            print(f"[{item_id}] Calling Gemini API (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        raw_path = os.path.join(RAW_DIR, f"{item_id}.png")
                        with open(raw_path, "wb") as f_out:
                            f_out.write(raw_bytes)
                        print(f"[{item_id}] Raw image saved ({len(raw_bytes)} bytes) -> {raw_path}")
                        return raw_path, full_prompt, attempt + 1
        except Exception as e:
            print(f"[{item_id}] Attempt {attempt+1} error: {e}")
            time.sleep(3)
            
    return None, full_prompt, max_retries

# 6. Cutout and Processing
def process_cutout(raw_path, target_size=512, fill_pct=0.80):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.asarray(im_pil, dtype=float)
    H, W, _ = im.shape
    
    # Background color detection from perimeter median
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
    
    # 1. Background detection (magenta)
    bgish = (dh < 32) & (sat > 0.20) & (r > 110) & (b > 60) & (g < 120)
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    # 2. Enclosed background pockets (inside horns, legs, loops)
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                if np.abs(m_color - bgc).max() < 55 and m_color[2] > 55 and m_color[0] > 105:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # 3. Drop tiny detached islands (< 50 px)
    labeled_obj, num_obj = ndi.label(obj)
    if num_obj > 1:
        sizes = ndi.sum(obj, labeled_obj, range(1, num_obj + 1))
        # Keep significant components (e.g. >= 50 px or largest)
        max_size = max(sizes) if len(sizes) > 0 else 0
        keep_labels = [i + 1 for i, s in enumerate(sizes) if s >= 50 or s == max_size]
        obj = np.isin(labeled_obj, keep_labels)
        
    # 4. Shrink alpha 1-2 px to strip outer magenta haze
    for _ in range(2):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_dh = dh[edge]
        edge_r = r[edge]
        edge_g = g[edge]
        edge_b = b[edge]
        # Outer edge tinted with magenta/pink
        is_halo = (edge_dh < 35) & (edge_r > edge_g + 12) & (edge_b > edge_g + 6)
        edge_to_strip = np.zeros_like(obj)
        edge_to_strip[edge] = is_halo
        if not edge_to_strip.any():
            break
        obj &= ~edge_to_strip
        
    # 5. Despill and Edge Darkening (bold inked outline enforcement)
    im_clean = im.copy()
    for _ in range(3):
        edge_outer = obj & ~ndi.binary_erosion(obj, border_value=1)
        # Check pink tone
        edge_pinkish = edge_outer & (dh < 40) & (im_clean[..., 0] > im_clean[..., 1] + 6) & (im_clean[..., 2] > im_clean[..., 1] + 4)
        im_clean[edge_pinkish, 0] = np.minimum(im_clean[edge_pinkish, 0], im_clean[edge_pinkish, 1] + 4)
        im_clean[edge_pinkish, 2] = np.minimum(im_clean[edge_pinkish, 2], im_clean[edge_pinkish, 1] + 4)
        
        # Check light rim on outermost 1px (in Gym Oath every silhouette has dark ink lines!)
        edge_light = edge_outer & ((0.3*im_clean[...,0] + 0.59*im_clean[...,1] + 0.11*im_clean[...,2]) > 160)
        im_clean[edge_light, 0] = np.minimum(im_clean[edge_light, 0], 40.0)
        im_clean[edge_light, 1] = np.minimum(im_clean[edge_light, 1], 40.0)
        im_clean[edge_light, 2] = np.minimum(im_clean[edge_light, 2], 40.0)

    # 6. Soft 1px edge with drop below alpha 70
    alpha = np.where(obj, 255.0, 0.0)
    outer_edge_final = obj & ~ndi.binary_erosion(obj, border_value=1)
    # Set outer edge alpha to 210 (soft 1 px transition, well above 70)
    alpha[outer_edge_final] = 210.0
    alpha[alpha < 70.0] = 0.0
    
    # 7. Crop bounding box
    ys, xs = np.nonzero(alpha >= 70)
    if len(ys) == 0:
        raise ValueError(f"No object found in {raw_path}")
        
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_crop = im_clean[y0:y1, x0:x1]
    alpha_crop = alpha[y0:y1, x0:x1]
    
    rgba_crop = np.dstack([obj_crop.astype(np.uint8), alpha_crop.astype(np.uint8)])
    crop_img = Image.fromarray(rgba_crop, "RGBA")
    
    # 8. Scale to target size and center
    obj_w, obj_h = crop_img.size
    max_dim = max(obj_w, obj_h)
    target_obj_dim = int(round(target_size * fill_pct))
    scale = target_obj_dim / float(max_dim)
    new_w = max(1, int(round(obj_w * scale)))
    new_h = max(1, int(round(obj_h * scale)))
    
    resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    final_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - new_w) // 2
    paste_y = (target_size - new_h) // 2
    final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
    
    # 9. Clean any residual pink or light rim pixels on final resized image
    arr_fin = np.asarray(final_canvas).copy().astype(float)
    r_f, g_f, b_f, a_f = arr_fin[..., 0], arr_fin[..., 1], arr_fin[..., 2], arr_fin[..., 3]
    
    # Pink despill
    h_f = hue(arr_fin[..., :3])
    dh_f = np.abs(((h_f - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
    chroma_f = arr_fin[..., :3].max(-1) - arr_fin[..., :3].min(-1)
    pink_mask = (a_f > 20) & (dh_f < 24) & (chroma_f > 75) & (r_f > g_f + 35) & (b_f > g_f + 15)
    if pink_mask.any():
        arr_fin[pink_mask, 0] = np.maximum(0, arr_fin[pink_mask, 1] + 10)
        arr_fin[pink_mask, 2] = np.maximum(0, arr_fin[pink_mask, 1] + 10)
        
    # Light rim despill on boundary
    is_transp_fin = (a_f < 50)
    outer_fin = (a_f >= 50) & ndi.binary_dilation(is_transp_fin, iterations=2)
    lum_f = 0.3 * r_f + 0.59 * g_f + 0.11 * b_f
    light_rim_mask = outer_fin & (lum_f > 170) & (r_f > 150) & (g_f > 145) & (b_f > 135)
    if light_rim_mask.any():
        arr_fin[light_rim_mask, 0] = np.minimum(arr_fin[light_rim_mask, 0], 40.0)
        arr_fin[light_rim_mask, 1] = np.minimum(arr_fin[light_rim_mask, 1], 40.0)
        arr_fin[light_rim_mask, 2] = np.minimum(arr_fin[light_rim_mask, 2], 40.0)
        
    final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
    
    pk = count_pink_pixels(final_canvas)
    lr = count_light_rim_pixels(final_canvas)
    
    return final_canvas, pk, lr

# 7. Check Sheet Builder
def build_check_sheet():
    """Generates check sheet with every cutout twice:
    once on flat stone grey #7F7A70 (127, 122, 112)
    and once on near-black #0D0B09 (13, 11, 9).
    """
    cols = len(ORDER)
    cell_size = 512
    sheet_w = cols * cell_size
    sheet_h = 2 * cell_size
    
    sheet = Image.new("RGB", (sheet_w, sheet_h), (0, 0, 0))
    
    # Fill Row 1 background: flat stone grey #7F7A70
    bg_grey = Image.new("RGB", (sheet_w, cell_size), (127, 122, 112))
    sheet.paste(bg_grey, (0, 0))
    
    # Fill Row 2 background: near-black #0D0B09
    bg_black = Image.new("RGB", (sheet_w, cell_size), (13, 11, 9))
    sheet.paste(bg_black, (0, cell_size))
    
    placed = 0
    for idx, item_id in enumerate(ORDER):
        info = BATCH_ITEMS[item_id]
        out_p = os.path.join(REPO_DIR, info["file"])
        if os.path.exists(out_p):
            im = Image.open(out_p).convert("RGBA")
            # If 256x256 item icon, center within 512x512 cell
            if im.size != (cell_size, cell_size):
                cell_im = Image.new("RGBA", (cell_size, cell_size), (0, 0, 0, 0))
                px = (cell_size - im.width) // 2
                py = (cell_size - im.height) // 2
                cell_im.paste(im, (px, py), im)
                im = cell_im
                
            col_x = idx * cell_size
            # Row 1: stone grey
            sheet.paste(im, (col_x, 0), im)
            # Row 2: near-black
            sheet.paste(im, (col_x, cell_size), im)
            placed += 1
            
    sheet.save(CHECK_IMAGE_IRON, format="PNG")
    sheet.save(CHECK_IMAGE_ROOT, format="PNG")
    print(f"Check sheet saved ({placed}/{cols} items) to:")
    print(f"  - {CHECK_IMAGE_IRON}")
    print(f"  - {CHECK_IMAGE_ROOT}")
    return placed

# 8. Manifest and Assets List updates
def update_assets_list():
    existing = []
    if os.path.exists(ASSETS_LIST_IRON):
        try:
            with open(ASSETS_LIST_IRON, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception:
            existing = []
            
    by_id = {item.get("id"): item for item in existing if isinstance(item, dict) and "id" in item}
    for item_id in ORDER:
        info = BATCH_ITEMS[item_id]
        by_id[item_id] = {
            "id": info["id"],
            "file": info["file"],
            "type": info["type"],
            "size": info["size"],
            "prompt": info["prompt"]
        }
        
    with open(ASSETS_LIST_IRON, "w", encoding="utf-8") as f:
        json.dump(list(by_id.values()), f, indent=2)
    print(f"Updated {ASSETS_LIST_IRON} (total: {len(by_id)})")

def update_manifests(records):
    # 1. Update assets/art/manifest.json (array)
    existing_art = []
    if os.path.exists(MANIFEST_ART):
        try:
            with open(MANIFEST_ART, "r", encoding="utf-8") as f:
                existing_art = json.load(f)
        except Exception:
            existing_art = []
    art_map = {item.get("id"): item for item in existing_art if isinstance(item, dict) and "id" in item}
    for r in records:
        art_map[r["id"]] = r
    with open(MANIFEST_ART, "w", encoding="utf-8") as f:
        json.dump(list(art_map.values()), f, indent=2)
    print(f"Updated {MANIFEST_ART} (total entries: {len(art_map)})")
    
    # 2. Update root manifest.json (dict)
    root_dict = {}
    if os.path.exists(MANIFEST_ROOT):
        try:
            with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
                root_dict = json.load(f)
        except Exception:
            root_dict = {}
    for r in records:
        root_dict[r["id"]] = r
    with open(MANIFEST_ROOT, "w", encoding="utf-8") as f:
        json.dump(root_dict, f, indent=2)
    print(f"Updated {MANIFEST_ROOT} (total entries: {len(root_dict)})")
    
    # 3. Update iron-oath-art/manifest.json (array)
    iron_list = []
    if os.path.exists(MANIFEST_IRON):
        try:
            with open(MANIFEST_IRON, "r", encoding="utf-8") as f:
                iron_list = json.load(f)
        except Exception:
            iron_list = []
    iron_map = {item.get("id"): item for item in iron_list if isinstance(item, dict) and "id" in item}
    for r in records:
        iron_map[r["id"]] = r
    with open(MANIFEST_IRON, "w", encoding="utf-8") as f:
        json.dump(list(iron_map.values()), f, indent=2)
    print(f"Updated {MANIFEST_IRON} (total entries: {len(iron_map)})")

# 9. Main runner
def run_batch(item_ids):
    records = []
    for item_id in item_ids:
        info = BATCH_ITEMS[item_id]
        out_p_repo = os.path.join(REPO_DIR, info["file"])
        out_p_iron = os.path.join(IRON_DIR, info["file"])
        raw_p = os.path.join(RAW_DIR, f"{item_id}.png")
        
        # Check if raw already exists in iron-oath-art/raw/<id>.png
        if os.path.exists(raw_p):
            print(f"[{item_id}] Raw already exists ({raw_p}), skipping API generation.")
            attempts = 1
            prompt = info["prompt"]
        else:
            raw_p, prompt, attempts = generate_raw(item_id)
            if not raw_p or not os.path.exists(raw_p):
                print(f"[{item_id}] FAILED to generate raw!")
                continue
                
        # Perform cutout
        cutout_img, pk, lr = process_cutout(raw_p, target_size=info["size"], fill_pct=info["fill_pct"])
        
        # Save delivered files
        os.makedirs(os.path.dirname(out_p_repo), exist_ok=True)
        os.makedirs(os.path.dirname(out_p_iron), exist_ok=True)
        cutout_img.save(out_p_repo, format="PNG")
        cutout_img.save(out_p_iron, format="PNG")
        print(f"[{item_id}] Delivered to {out_p_repo} (size={cutout_img.size}, pink_pixels={pk}, light_rim_pixels={lr})")
        
        refs_used = [r["name"] for r in (CACHED_CREATURE_REFS if info["category"] == "animal" else CACHED_ITEM_REFS)]
        records.append({
            "id": item_id,
            "file": info["file"],
            "type": "cutout",
            "size": info["size"],
            "prompt": prompt,
            "references": refs_used,
            "attempts": attempts,
            "pink_pixels": pk,
            "light_rim_pixels": lr,
            "status": "done"
        })
        
    if records:
        update_assets_list()
        update_manifests(records)
        build_check_sheet()
        
    return records

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "test"
    if mode == "test":
        print("--- RUNNING STYLE TEST: ash_hare_idle ---")
        run_batch(["ash_hare_idle"])
    elif mode == "animals":
        print("--- RUNNING REMAINING ANIMALS ---")
        run_batch(["red_fox_idle", "grey_badger_idle", "carrion_crow_idle", "wild_goat_idle"])
    elif mode == "items":
        print("--- RUNNING ITEM ICONS ---")
        run_batch(["gale_silver", "godforge_steel"])
    elif mode == "all":
        print("--- RUNNING ALL IN STRICT ORDER ---")
        run_batch(ORDER)
    elif mode == "check":
        build_check_sheet()
    else:
        print(f"Unknown mode: {mode}")
