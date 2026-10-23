"""Generation and Processing Pipeline for 'Gym Oath' Commander Reynard (6 Poses).
Mobile Dark Fantasy Medieval Fitness RPG (Souls-like: Dark Souls / Elden Ring aesthetic).

Commander Reynard, the game's master-at-arms, in 6 poses -> assets/art/trainer/<id>.png
(type "cutout", generate 1024x1280 portrait 4:5, deliver 640x800 RGBA,
 NOT cropped to content: keep the same canvas and scale in all six so they line up).
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

sys.stdout.reconfigure(line_buffering=True)

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
PIPELINE_DIR = os.path.join(REPO_DIR, "pipeline")
IRON_DIR = r"C:\Users\pissio\iron-oath-art"
RAW_DIR = os.path.join(IRON_DIR, "raw")
TRAINER_REPO_DIR = os.path.join(REPO_DIR, "assets", "art", "trainer")
TRAINER_IRON_DIR = os.path.join(IRON_DIR, "assets", "art", "trainer")

MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = os.path.join(IRON_DIR, "manifest.json")
ASSETS_LIST_IRON = os.path.join(IRON_DIR, "assets_list.json")

CHECK_IMAGE_IRON = os.path.join(IRON_DIR, "check_trainer.png")
CHECK_IMAGE_ROOT = os.path.join(REPO_DIR, "check_trainer.png")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(TRAINER_REPO_DIR, exist_ok=True)
os.makedirs(TRAINER_IRON_DIR, exist_ok=True)

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

# 2. Reference Images for Mother
CREATURE_REF_PATHS = [
    os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "enemies", "hollow_goblin_idle.png"),
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

print(f"Loaded {len(CACHED_CREATURE_REFS)} creature references.")

# 3. Character & Poses Definition
CHARACTER_BASE_DESC = (
    "Commander Reynard, a veteran templar master-at-arms, tall and broad-shouldered, an old soldier who is stern but secretly kind and a little mystical. "
    "Three-quarter figure from the top of the helmet plume down to mid-thigh, the legs cut by the bottom edge of the image, body in front three-quarter view, centred, with a little empty space above the plume.\n"
    "Helmet (key feature): a fully closed great bascinet of blackened steel with thin antique-gold trim on every edge, rising to a tall pointed ogee peak; "
    "one raised vertical ridge down the middle of the face and two thinner curved ridges on each side of the dome; a gold-trimmed brow band; "
    "two narrow eye slits angled down toward the centre like a stern frown, with a faint warm golden glow deep inside (his only mystical light); "
    "a pointed beak faceplate pierced by a neat grid of small round breathing holes; riveted pivot bosses on the temples; a rounded riveted gorget; "
    "one small dent on the left of the dome. From the top peak rises a single long plume of dark crimson and bone-white feathers curving backward and down over the back of the helmet, slightly ragged at the tips.\n"
    "Armor: old, worn but cared-for blackened steel plate with thin antique-gold edging, scratched, never rusty. Large rounded pauldrons, articulated gauntlets. "
    "A long templar tabard of faded bone-white linen, frayed and soot-stained at the hem, with a large faded dark-red cross on the chest. "
    "A heavy dark crimson half-cape from the left shoulder, torn at the edges. A wide leather belt with a sheathed longsword at the hip. "
    "A rosary of small bone beads wrapped around the right gauntlet, two parchment prayer strips with red wax seals pinned on the right pauldron.\n"
    "Personality at a glance: serious, imposing and trustworthy, but likeable, with dry humour in his posture."
)

POSES = [
    {
        "id": "trainer_crossed",
        "file": "assets/art/trainer/trainer_crossed.png",
        "type": "cutout",
        "pose": "arms crossed over his chest, weight on one leg, helmet slightly lowered as if studying the viewer with a mix of severity and amusement."
    },
    {
        "id": "trainer_pointing",
        "file": "assets/art/trainer/trainer_pointing.png",
        "type": "cutout",
        "pose": "pointing forward at the viewer with the right gauntlet, the left hand on the sword pommel at his hip, giving an order."
    },
    {
        "id": "trainer_cheering",
        "file": "assets/art/trainer/trainer_cheering.png",
        "type": "cutout",
        "pose": "right fist raised high in triumph, the left hand on his belt, chest out, proud of the viewer."
    },
    {
        "id": "trainer_facepalm",
        "file": "assets/art/trainer/trainer_facepalm.png",
        "type": "cutout",
        "pose": "the right gauntlet pressed against the faceplate of his helmet in a facepalm, shoulders slumped, exasperated but amused."
    },
    {
        "id": "trainer_thinking",
        "file": "assets/art/trainer/trainer_thinking.png",
        "type": "cutout",
        "pose": "the right hand rubbing the chin of the helmet's faceplate, the left arm across the waist supporting the right elbow, head tilted, pondering."
    },
    {
        "id": "trainer_goofy",
        "file": "assets/art/trainer/trainer_goofy.png",
        "type": "cutout",
        "pose": "a goofy joking bodybuilder flex with both arms, the half-cape tangled around one arm, clearly fooling around."
    }
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
    
    pink = (a > 20) & (dh < 24) & (chroma > 80) & (r > g + 40) & (b > g + 20)
    return int(pink.sum())

def count_light_rim_pixels(img_rgba):
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    
    is_transp = (a < 40)
    outer_edge = (a >= 40) & ndi.binary_dilation(is_transp, iterations=2)
    
    lum = (0.3 * r + 0.59 * g + 0.11 * b)
    light_rim = outer_edge & (lum > 175) & (r > 150) & (g > 145) & (b > 135)
    return int(light_rim.sum())

# 5. Gemini Generation
def generate_mother(max_retries=3):
    pose_info = POSES[0]
    item_id = pose_info["id"]
    raw_path = os.path.join(RAW_DIR, f"{item_id}.png")
    
    if os.path.exists(raw_path):
        print(f"Mother image {raw_path} already exists on disk. Skipping generation.")
        return raw_path, "Existing mother image", 1
        
    parts = []
    for ref in CACHED_CREATURE_REFS:
        parts.append({
            "text": f"Style Reference ({ref['name']}): Match the painting technique, inked outlines, level of detail and lighting of these reference images, but draw a completely different subject and use ONLY the colours written in this prompt:"
        })
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
        f"CHARACTER: {CHARACTER_BASE_DESC}\n\n"
        f"POSE: {pose_info['pose']}\n"
        "COMPOSITION: Generate portrait 4:5 aspect ratio (1024x1280), three-quarter figure centered with empty space above the helmet plume, cut by bottom edge at mid-thigh. Flat solid magenta #FF00FF background."
    )
    parts.append({"text": full_prompt})
    
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {"imageConfig": {"aspectRatio": "4:5"}}
    }
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    
    for attempt in range(max_retries):
        try:
            print(f"[{item_id}] Generating Mother Image (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        img = Image.open(io.BytesIO(raw_bytes))
                        if img.size != (1024, 1280):
                            print(f"[{item_id}] Rescaling raw from {img.size} to standard (1024, 1280)...")
                            img = img.resize((1024, 1280), Image.Resampling.LANCZOS)
                        img.save(raw_path, format="PNG")
                        print(f"[{item_id}] Mother raw saved -> {raw_path}")
                        return raw_path, full_prompt, attempt + 1
        except Exception as e:
            print(f"[{item_id}] Attempt {attempt+1} error: {e}")
            time.sleep(3)
            
    raise RuntimeError("Failed to generate mother image!")

def generate_pose_edit(pose_info, mother_raw_path, max_retries=3):
    item_id = pose_info["id"]
    raw_path = os.path.join(RAW_DIR, f"{item_id}.png")
    
    if os.path.exists(raw_path):
        print(f"Pose raw image {raw_path} already exists on disk. Skipping generation.")
        return raw_path, f"Existing raw for {item_id}", 1
        
    mother_im = Image.open(mother_raw_path)
    # Ensure reasonable dimensions for base64 transfer
    mother_thumb = mother_im.copy()
    mother_thumb.thumbnail((768, 960), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    mother_thumb.save(buf, format="PNG")
    mother_b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    
    edit_instruction = (
        f"Edit this exact image. Keep the character, helmet, plume, armour, tabard, colours, size, "
        f"position on the canvas, lighting and magenta background identical. "
        f"Change only the pose of the arms and body to: {pose_info['pose']}.\n"
        "CRITICAL: Keep flat solid magenta background #FF00FF filling the entire canvas. "
        "No text, no watermark, no frame, no UI."
    )
    
    parts = [
        {"text": "Input MOTHER image of Commander Reynard to edit:"},
        {"inlineData": {"mimeType": "image/png", "data": mother_b64}},
        {"text": edit_instruction}
    ]
    
    payload = {
        "contents": [{"parts": parts}],
        "generationConfig": {"imageConfig": {"aspectRatio": "4:5"}}
    }
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    
    for attempt in range(max_retries):
        try:
            print(f"[{item_id}] Generating Pose Edit (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        img = Image.open(io.BytesIO(raw_bytes))
                        if img.size != (1024, 1280):
                            print(f"[{item_id}] Rescaling raw from {img.size} to standard (1024, 1280)...")
                            img = img.resize((1024, 1280), Image.Resampling.LANCZOS)
                        img.save(raw_path, format="PNG")
                        print(f"[{item_id}] Pose raw saved -> {raw_path}")
                        return raw_path, edit_instruction, attempt + 1
        except Exception as e:
            print(f"[{item_id}] Attempt {attempt+1} error: {e}")
            time.sleep(3)
            
    raise RuntimeError(f"Failed to generate pose edit for {item_id}!")

# 6. Cutout and Canvas Processing
def process_cutout(raw_path, deliver_size=(640, 800)):
    im_pil = Image.open(raw_path).convert("RGB")
    if im_pil.size != (1024, 1280):
        im_pil = im_pil.resize((1024, 1280), Image.Resampling.LANCZOS)
        
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
    
    # 2. Enclosed background pockets (e.g. between arms and torso)
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                if np.abs(m_color - bgc).max() < 55 and m_color[2] > 55 and m_color[0] > 105:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # 3. Drop tiny detached islands (< 2000 px)
    labeled_obj, num_obj = ndi.label(obj)
    if num_obj > 1:
        sizes = ndi.sum(obj, labeled_obj, range(1, num_obj + 1))
        max_size = max(sizes) if len(sizes) > 0 else 0
        keep_labels = [i + 1 for i, s in enumerate(sizes) if s >= 2000 or s == max_size]
        obj = np.isin(labeled_obj, keep_labels)
        
    # 4. Shrink alpha 1-2 px to strip outer magenta haze
    for _ in range(2):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_dh = dh[edge]
        edge_r = r[edge]
        edge_g = g[edge]
        edge_b = b[edge]
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
        
        # Darken any light rim along outer boundary to preserve crisp dark ink line
        edge_light = edge_outer & ((0.3*im_clean[...,0] + 0.59*im_clean[...,1] + 0.11*im_clean[...,2]) > 160)
        im_clean[edge_light, 0] = np.minimum(im_clean[edge_light, 0], 40.0)
        im_clean[edge_light, 1] = np.minimum(im_clean[edge_light, 1], 40.0)
        im_clean[edge_light, 2] = np.minimum(im_clean[edge_light, 2], 40.0)

    # 6. Soft 1px edge with drop below alpha 70
    alpha = np.where(obj, 255.0, 0.0)
    outer_edge_final = obj & ~ndi.binary_erosion(obj, border_value=1)
    alpha[outer_edge_final] = 210.0
    alpha[alpha < 70.0] = 0.0
    
    # 7. NOT cropped to content: Keep full canvas and scale down directly to 640x800 RGBA!
    rgba_full = np.dstack([im_clean.astype(np.uint8), alpha.astype(np.uint8)])
    img_full = Image.fromarray(rgba_full, "RGBA")
    
    deliver_img = img_full.resize(deliver_size, Image.Resampling.LANCZOS)
    
    # 8. Despill & light rim cleanup pass on delivered 640x800 image
    arr_fin = np.asarray(deliver_img).copy().astype(float)
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
        
    deliver_img = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
    
    pk = count_pink_pixels(deliver_img)
    lr = count_light_rim_pixels(deliver_img)
    
    return deliver_img, pk, lr

# 7. Check Sheet Builder
def build_check_sheet():
    cols = len(POSES)
    cell_w, cell_h = 640, 800
    sheet_w = cols * cell_w
    sheet_h = 2 * cell_h
    
    sheet = Image.new("RGB", (sheet_w, sheet_h), (0, 0, 0))
    
    # Row 1: flat stone grey #7F7A70 (127, 122, 112)
    bg_grey = Image.new("RGB", (sheet_w, cell_h), (127, 122, 112))
    sheet.paste(bg_grey, (0, 0))
    
    # Row 2: near-black #0D0B09 (13, 11, 9)
    bg_black = Image.new("RGB", (sheet_w, cell_h), (13, 11, 9))
    sheet.paste(bg_black, (0, cell_h))
    
    placed = 0
    for idx, p in enumerate(POSES):
        out_p = os.path.join(REPO_DIR, p["file"])
        if os.path.exists(out_p):
            im = Image.open(out_p).convert("RGBA")
            # Row 1: grey
            sheet.paste(im, (idx * cell_w, 0), im)
            # Row 2: black
            sheet.paste(im, (idx * cell_w, cell_h), im)
            placed += 1
            
    sheet.save(CHECK_IMAGE_IRON, format="PNG")
    sheet.save(CHECK_IMAGE_ROOT, format="PNG")
    print(f"Check sheet saved ({placed}/6 poses) -> {CHECK_IMAGE_IRON} and {CHECK_IMAGE_ROOT}")
    return placed

# 8. Manifest and Assets List Updates
def update_manifests_and_assets(records):
    # 1. Update iron-oath-art/assets_list.json
    assets_list = []
    if os.path.exists(ASSETS_LIST_IRON):
        try:
            with open(ASSETS_LIST_IRON, "r", encoding="utf-8") as f:
                assets_list = json.load(f)
        except Exception:
            assets_list = []
            
    existing_ids = {a.get("id") for a in assets_list if isinstance(a, dict)}
    for p in POSES:
        if p["id"] not in existing_ids:
            assets_list.append(p)
            existing_ids.add(p["id"])
            
    with open(ASSETS_LIST_IRON, "w", encoding="utf-8") as f:
        json.dump(assets_list, f, indent=2)
    print(f"Updated {ASSETS_LIST_IRON} (total assets: {len(assets_list)})")
    
    # 2. Update manifests
    for manifest_path, is_list in [(MANIFEST_ROOT, False), (MANIFEST_ART, True), (MANIFEST_IRON, False)]:
        if not os.path.exists(manifest_path):
            continue
        try:
            with open(manifest_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception:
            data = [] if is_list else {}
            
        if is_list or isinstance(data, list):
            m_map = {item.get("id"): item for item in data if isinstance(item, dict) and "id" in item}
            for r in records:
                m_map[r["id"]] = r
            new_list = list(m_map.values())
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(new_list, f, indent=2)
        else:
            for r in records:
                data[r["id"]] = r
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        print(f"Updated {manifest_path}")

# 9. Pipeline execution
def run_pipeline():
    print("=== STARTING COMMANDER REYNARD GENERATION PIPELINE ===")
    records = []
    
    # Step 1: Mother image
    mother_raw, mother_prompt, mother_att = generate_mother()
    mother_delivered, pk0, lr0 = process_cutout(mother_raw)
    
    out_repo_mother = os.path.join(REPO_DIR, POSES[0]["file"])
    out_iron_mother = os.path.join(IRON_DIR, POSES[0]["file"])
    os.makedirs(os.path.dirname(out_repo_mother), exist_ok=True)
    os.makedirs(os.path.dirname(out_iron_mother), exist_ok=True)
    mother_delivered.save(out_repo_mother, format="PNG")
    mother_delivered.save(out_iron_mother, format="PNG")
    print(f"[trainer_crossed] Saved 640x800 RGBA (pink_pixels={pk0}, light_rim_pixels={lr0})")
    
    records.append({
        "id": "trainer_crossed",
        "file": POSES[0]["file"],
        "type": "cutout",
        "size": "640x800",
        "prompt": mother_prompt,
        "references": [ref["name"] for ref in CACHED_CREATURE_REFS],
        "attempts": mother_att,
        "pink_pixels": pk0,
        "light_rim_pixels": lr0,
        "status": "done"
    })
    
    # Step 2: Pose variations (edits of mother)
    for p in POSES[1:]:
        p_id = p["id"]
        raw_p, prompt_p, att_p = generate_pose_edit(p, mother_raw)
        deliv_im, pk, lr = process_cutout(raw_p)
        
        out_repo = os.path.join(REPO_DIR, p["file"])
        out_iron = os.path.join(IRON_DIR, p["file"])
        os.makedirs(os.path.dirname(out_repo), exist_ok=True)
        os.makedirs(os.path.dirname(out_iron), exist_ok=True)
        deliv_im.save(out_repo, format="PNG")
        deliv_im.save(out_iron, format="PNG")
        print(f"[{p_id}] Saved 640x800 RGBA (pink_pixels={pk}, light_rim_pixels={lr})")
        
        records.append({
            "id": p_id,
            "file": p["file"],
            "type": "cutout",
            "size": "640x800",
            "prompt": prompt_p,
            "references": ["trainer_crossed (mother)"],
            "attempts": att_p,
            "pink_pixels": pk,
            "light_rim_pixels": lr,
            "status": "done"
        })
        
    # Step 3: Build check sheet
    build_check_sheet()
    
    # Step 4: Update manifests
    update_manifests_and_assets(records)
    print("=== PIPELINE EXECUTION COMPLETE ===")

if __name__ == "__main__":
    run_pipeline()
