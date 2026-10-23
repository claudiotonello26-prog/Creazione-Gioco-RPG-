"""Generation and Processing Pipeline for 'Gym Oath' Expedition Maps and Chests.
Mobile Dark Fantasy Medieval Fitness RPG (Souls-like: Dark Souls / Elden Ring aesthetic).

Assets in this batch:
- 20 Expedition maps -> assets/art/maps/<id>.png (type "background", portrait 1080x1920, no transparency)
- 4 Chests -> assets/art/chests/<id>.png (type "cutout", generate 1024x1024, deliver 512x512 RGBA)

Order:
1. map_buried_forges and chest_wood first as style tests
2. other chests: chest_iron, chest_silver, chest_gold
3. remaining maps in list order
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
MAPS_DIR = os.path.join(REPO_DIR, "assets", "art", "maps")
CHESTS_DIR = os.path.join(REPO_DIR, "assets", "art", "chests")
MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = os.path.join(IRON_DIR, "manifest.json")
ASSETS_LIST_IRON = os.path.join(IRON_DIR, "assets_list.json")
CHECK_SHEET_IRON = os.path.join(IRON_DIR, "check_chests.png")
CHECK_SHEET_ROOT = os.path.join(REPO_DIR, "check_chests.png")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(MAPS_DIR, exist_ok=True)
os.makedirs(CHESTS_DIR, exist_ok=True)

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
    raise ValueError("GEMINI_API_KEY not found!")

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

# 2. Style Reference Images
REF_PATHS = [
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

CACHED_REFS = []
for rp in REF_PATHS:
    if os.path.exists(rp):
        CACHED_REFS.append({
            "name": os.path.basename(rp),
            "b64": load_ref_b64(rp)
        })

print(f"Loaded {len(CACHED_REFS)} style references.")

# 3. Chest Definitions
CHEST_GLOBAL_STYLE = (
    "STYLE REFERENCES: Match the painting technique, inked outlines, level of detail and lighting of these reference images, "
    "but draw a completely different subject and use ONLY the colours written in this prompt.\n"
    "Hand-painted dark fantasy illustration, souls-like mobile game art style (Dark Souls, Elden Ring, Gym Oath). "
    "Bold inked outlines defining the outer silhouette and metal/wood seams. "
    "Rich but muted weathered colours, deep charcoal shadows (#0D0B09), soft rim light in warm antique gold (#C9A24A) from the upper left, "
    "readable even as a small thumbnail. "
    "CRITICAL FORMAT RULES: One chest only, whole, centred, front three-quarter view, filling about 80% of the canvas. "
    "Same angle, same size, same light from the upper left across all chests. "
    "Flat solid uniform magenta background #FF00FF filling the whole canvas: no shadows, gradients, floor, smoke, particles or glow spreading on the background. "
    "Nothing of the subject is magenta or pink. Glows and smoke stay tight and opaque around the subject. "
    "No text, no letters, no frame, no borders, no UI, no watermark."
)

CHESTS_DATA = [
    {
        "id": "chest_wood",
        "file": "assets/art/chests/chest_wood.png",
        "type": "cutout",
        "size": 512,
        "prompt": (
            "Chest (Rotten Wood): A rustic, decayed wooden treasure chest constructed entirely of dark damp timber planks. "
            "Prominent natural cracked wood grain, rotting weathered oak boards, soft green moss and lichen clinging to the damp lower edges and corners. "
            "Only simple crude thin iron brackets on the corners holding the wood together. "
            "Slightly open lid revealing a faint warm ember glow inside. "
            "Colours strictly: rich weathered timber brown, damp earth brown, mossy green (#4A6B35), dark aged iron brackets. Must look unmistakably like rough decaying wood."
        )
    },
    {
        "id": "chest_iron",
        "file": "assets/art/chests/chest_iron.png",
        "type": "cutout",
        "size": 512,
        "prompt": (
            "Chest (Heavy Iron Bastion): A heavily armored fortress chest completely encased in thick, riveted dark steel and iron armor plates. "
            "Prominent forged iron rivets and heavy industrial steel bands criss-crossing the front and lid. "
            "A large heavy forged iron padlock hanging open from the central latch. "
            "Cold metallic iron sheen, specular highlights on dark steel edges, looking heavy, industrial and fortified like a medieval safe. "
            "Slightly open lid with a warm orange forge glow visible inside. "
            "Colours strictly: cold dark steel grey, charcoal iron, metallic gunmetal (#5C636E, #3D4148), with tiny hints of dark wood visible only between the heavy metal plates. Must look unmistakably metallic and heavily iron-armored."
        )
    },
    {
        "id": "chest_silver",
        "file": "assets/art/chests/chest_silver.png",
        "type": "cutout",
        "size": 512,
        "prompt": "Chest: an ornate silver chest with engraved moon and star patterns, cold blue-white sheen, lid slightly open with a pale silver glow inside. Colours: silver, pale blue."
    },
    {
        "id": "chest_gold",
        "file": "assets/art/chests/chest_gold.png",
        "type": "cutout",
        "size": 512,
        "prompt": (
            "Chest (Grand Radiant Gold of the Oath): A lavish, magnificent treasure chest made entirely of solid, brilliant antique gold and pure yellow gold leaf. "
            "Intensely and radiantly golden: ornate baroque and gothic filigree reliefs, sculpted golden lion/sword oath emblem on the lid, polished gold surfaces catching bright light. "
            "Four glowing deep ruby red gems set into the ornate golden corners. "
            "Lid slightly open with intense, dazzling warm golden rays and bright holy amber-gold light pouring out from within. "
            "Colours strictly: radiant antique gold (#E5B842), brilliant polished yellow gold (#FFD700, #F5C542), warm amber highlights, rich crimson-ruby gems (#A81C1C). Overwhelmingly golden, opulent, and shining."
        )
    }
]

# 4. Map Definitions
MAP_GLOBAL_STYLE = (
    "STYLE REFERENCES: Match the painting technique, inked outlines, level of detail, textural brushwork and lighting of these reference images, "
    "but draw a completely different subject and use ONLY the colours written in this prompt.\n"
    "Dark fantasy medieval environment painting, souls-like atmosphere, painterly digital illustration, inked details, "
    "deep charcoal shadows, muted tones, cinematic, no characters, no text, no watermark, no modern elements. "
    "Overall dark and moody (it sits behind white text).\n"
    "COMPOSITION & EXPEDITION PATH: High three-quarter bird's-eye view, like a painted adventure map of the place, NOT a top-down tile map. "
    "Tall vertical portrait composition framed in the center. "
    "The top 6% of the canvas is covered by game buttons: keep it plain dark sky or vault ceiling. "
    "A visible but subtle walkable path (trail, steps, bridge, corridor) winds through 5 stops from bottom to top: "
    "Stop 1 near bottom center (50% x, 84% y), Stop 2 curving right (68% x, 68% y), Stop 3 winding left (36% x, 53% y), "
    "Stop 4 curving right (64% x, 38% y), and the boss lair at the top center (50% x, 18% y). "
    "The boss lair at the top is lit a bit more than the rest. "
    "Keep the areas around the 5 stops calm and slightly darker so round map markers stay readable. "
    "No characters, no creatures, no text, no labels, no UI, no frame."
)

MAPS_DATA = [
    {
        "id": "map_buried_forges",
        "file": "assets/art/maps/buried_forges.png",
        "type": "background",
        "prompt": "Map background (Le Forge Sepolte): extinct furnaces in vaults under a city, black stone, cold slag, faint orange embers in cracks; boss lair at the top: a huge dead smithy with a giant anvil. Dominant palette: ember orange and soot black."
    },
    {
        "id": "map_iron_bastion",
        "file": "assets/art/maps/iron_bastion.png",
        "type": "background",
        "prompt": "Map background (Il Bastione di Ferro): the walls and inner courtyards of an iron-plated fortress never conquered, steel gates, ramparts; boss lair at the top: the keep's great iron gate. Dominant palette: ember orange and soot black."
    },
    {
        "id": "map_giants_furnace",
        "file": "assets/art/maps/giants_furnace.png",
        "type": "background",
        "prompt": "Map background (La Fornace dei Giganti): enormous furnaces built for giants, rivers of glowing molten iron, red-hot walls; boss lair at the top: a colossal furnace mouth. Dominant palette: ember orange and soot black."
    },
    {
        "id": "map_godforge",
        "file": "assets/art/maps/godforge.png",
        "type": "background",
        "prompt": "Map background (La Fucina degli Dei): a divine forge on a mountaintop of black basalt and gold veins, broken colossal hammer, holy embers; boss lair at the top: a giant golden anvil under a burning sky. Dominant palette: ember orange and soot black."
    },
    {
        "id": "map_ash_wood_forest",
        "file": "assets/art/maps/ash_wood_forest.png",
        "type": "background",
        "prompt": "Map background (Il Bosco di Cenere): a forest of burned ash-grey trees that never fall, grey ash on the ground, thin mist; boss lair at the top: a clearing around a huge dead tree. Dominant palette: moss green and earth brown."
    },
    {
        "id": "map_hunters_marsh",
        "file": "assets/art/maps/hunters_marsh.png",
        "type": "background",
        "prompt": "Map background (La Palude dei Cacciatori): a dark marsh with black oak trees, rotten boardwalks, hunting traps, green mist; boss lair at the top: a witch's hut on stilts. Dominant palette: moss green and earth brown."
    },
    {
        "id": "map_wind_gorge",
        "file": "assets/art/maps/wind_gorge.png",
        "type": "background",
        "prompt": "Map background (Le Gole del Vento): narrow rocky gorges with rope bridges, harpy nests on the cliffs, wind-torn banners; boss lair at the top: a high nest on a rock pinnacle. Dominant palette: moss green and earth brown."
    },
    {
        "id": "map_storm_peak",
        "file": "assets/art/maps/storm_peak.png",
        "type": "background",
        "prompt": "Map background (La Vetta della Bufera): a mountain path climbing to a stormy peak, snow and lightning, broken watchtowers; boss lair at the top: a ruined throne on the summit under lightning. Dominant palette: moss green and earth brown."
    },
    {
        "id": "map_bronze_crypt",
        "file": "assets/art/maps/bronze_crypt.png",
        "type": "background",
        "prompt": "Map background (La Cripta di Bronzo): underground tombs closed by great bronze doors, sarcophagi, green patina, candles; boss lair at the top: the sealed bronze gate of the main tomb. Dominant palette: antique gold and dark stone."
    },
    {
        "id": "map_golden_temple",
        "file": "assets/art/maps/golden_temple.png",
        "type": "background",
        "prompt": "Map background (Il Tempio Dorato): a temple with gilded columns, gold leaf peeling, bones of priests in alcoves, incense smoke; boss lair at the top: a golden altar. Dominant palette: antique gold and dark stone."
    },
    {
        "id": "map_hallowed_sanctum",
        "file": "assets/art/maps/hallowed_sanctum.png",
        "type": "background",
        "prompt": "Map background (Il Santuario Consacrato): a blinding holy sanctum, weeping statues with golden tears, white marble, harsh light beams; boss lair at the top: a radiant reliquary. Dominant palette: antique gold and dark stone."
    },
    {
        "id": "map_martyr_cathedral",
        "file": "assets/art/maps/martyr_cathedral.png",
        "type": "background",
        "prompt": "Map background (La Cattedrale del Martire): a black and gold gothic cathedral nave, kneeling statues, red candles; boss lair at the top: the high altar with a huge martyr statue. Dominant palette: antique gold and dark stone."
    },
    {
        "id": "map_lunar_ruins",
        "file": "assets/art/maps/lunar_ruins.png",
        "type": "background",
        "prompt": "Map background (Le Rovine Lunari): moonlit ruins on a hill, stones silvered by a huge full moon, pale blue light; boss lair at the top: a broken moon altar. Dominant palette: cold blue and silver."
    },
    {
        "id": "map_flooded_library",
        "file": "assets/art/maps/flooded_library.png",
        "type": "background",
        "prompt": "Map background (La Biblioteca Allagata): a flooded library, black water, floating books, tall shelves, living ink swirling in the water; boss lair at the top: a reading hall with a giant open tome. Dominant palette: cold blue and silver."
    },
    {
        "id": "map_fallen_observatory",
        "file": "assets/art/maps/fallen_observatory.png",
        "type": "background",
        "prompt": "Map background (L'Osservatorio Crollato): a collapsed observatory, a fallen brass telescope, star charts, a cracked dome open to a starry sky; boss lair at the top: an armillary sphere. Dominant palette: cold blue and silver."
    },
    {
        "id": "map_star_well",
        "file": "assets/art/maps/star_well.png",
        "type": "background",
        "prompt": "Map background (Il Pozzo delle Stelle): a bottomless stone well spiral with falling stars glowing deep below, cosmic blue light; boss lair at the top: the rim of the abyss with a coiled shape of stars. Dominant palette: cold blue and silver."
    },
    {
        "id": "map_silent_garden",
        "file": "assets/art/maps/silent_garden.png",
        "type": "background",
        "prompt": "Map background (Il Giardino del Silenzio): a still overgrown garden, stone lanterns, pale flowers, calm ghostly mist; boss lair at the top: a moss-covered shrine. Dominant palette: soft violet and grey."
    },
    {
        "id": "map_hanging_monastery",
        "file": "assets/art/maps/hanging_monastery.png",
        "type": "background",
        "prompt": "Map background (Il Monastero Sospeso): a monastery hanging on a cliff face, wooden walkways, prayer flags, deep chasm; boss lair at the top: the abbot's hall. Dominant palette: soft violet and grey."
    },
    {
        "id": "map_ancient_baths",
        "file": "assets/art/maps/ancient_baths.png",
        "type": "background",
        "prompt": "Map background (Le Terme degli Antichi): ancient roman-like baths, warm steam, cracked mosaics, turquoise water; boss lair at the top: the great central pool. Dominant palette: soft violet and grey."
    },
    {
        "id": "map_dream_cloister",
        "file": "assets/art/maps/dream_cloister.png",
        "type": "background",
        "prompt": "Map background (Il Chiostro del Sogno): a dreamlike cloister, violet haze, floating petals, sleeping statues, impossible arches; boss lair at the top: a bed of stone under a giant moth-wing window. Dominant palette: soft violet and grey."
    }
]

# 5. Gemini API Call
def generate_image(prompt_text, extra_refs=None, max_retries=3):
    parts = []
    for ref in CACHED_REFS:
        parts.append({"text": f"Style Reference ({ref['name']}): Match this dark fantasy inking, muted colours and shading technique:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
        
    if extra_refs:
        for eref in extra_refs:
            parts.append({"text": f"Style Reference ({eref['name']}): Match the exact perspective, lighting and proportions of this chest:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": eref["b64"]}})
            
    parts.append({"text": prompt_text})
    
    payload = {"contents": [{"parts": parts}]}
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    
    for attempt in range(max_retries):
        try:
            print(f"Calling Gemini API (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        return raw_bytes, attempt + 1
        except Exception as e:
            if hasattr(e, "read"):
                try:
                    print("API Error Detail:", e.read().decode("utf-8"))
                except Exception:
                    pass
            print(f"API attempt {attempt+1} failed: {e}")
            time.sleep(3)
            
    return None, max_retries

# 6. Map Post-Processing: resize/crop to exactly 1080x1920 (cover, centred)
def process_map_image(raw_bytes_or_path, out_path, target_w=1080, target_h=1920):
    if isinstance(raw_bytes_or_path, str):
        im = Image.open(raw_bytes_or_path).convert("RGB")
    else:
        im = Image.open(io.BytesIO(raw_bytes_or_path)).convert("RGB")
        
    w, h = im.size
    target_ar = target_w / float(target_h)
    src_ar = w / float(h)
    
    if src_ar > target_ar:
        # Source is wider than target: crop left and right
        crop_h = h
        crop_w = int(round(h * target_ar))
        crop_x = (w - crop_w) // 2
        crop_y = 0
    else:
        # Source is taller than target: crop top and bottom
        crop_w = w
        crop_h = int(round(w / target_ar))
        crop_x = 0
        crop_y = (h - crop_h) // 2
        
    cropped = im.crop((crop_x, crop_y, crop_x + crop_w, crop_y + crop_h))
    final_img = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    final_img.save(out_path, format="PNG")
    print(f"Map saved: {out_path} ({final_img.size[0]}x{final_img.size[1]})")
    return final_img

# 7. Cutout Processing & Quality Checks for Chests
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
    """Detects any light, white, or cream fringe along the outer edge of the alpha boundary."""
    ar = np.asarray(img_rgba).astype(float)
    a = ar[..., 3]
    r, g, b = ar[..., 0], ar[..., 1], ar[..., 2]
    
    # Outer 1-2px edge mask of the object
    is_solid = a > 50
    edge = is_solid & ~ndi.binary_erosion(is_solid, iterations=2)
    
    # Light/cream/white edge detection: high luminance or high minimum RGB channel
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    # In souls-like art with black inked outlines, edge outline pixels should be dark (< 130)
    light_rim = edge & (lum > 140) & (r > 120) & (g > 115) & (b > 100)
    return int(light_rim.sum())

def process_chest_cutout(raw_bytes_or_path, out_path, target_size=512, target_fill_pct=0.82):
    if isinstance(raw_bytes_or_path, str):
        im_pil = Image.open(raw_bytes_or_path).convert("RGB")
    else:
        im_pil = Image.open(io.BytesIO(raw_bytes_or_path)).convert("RGB")
        
    im = np.asarray(im_pil, dtype=float)
    H, W, _ = im.shape
    
    # Background color from perimeter median
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
    
    # Magenta background detection
    bgish = (dh < 30) & (sat > 0.22) & (r > 120) & (b > 65) & (g < 110)
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    # Enclosed pockets (holes inside handles, under latch, etc.)
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                dh_pocket = np.abs(((hue(m_color) - hue(bgc)) + 180) % 360 - 180)
                if dh_pocket < 20 and m_color[2] > 60 and m_color[0] > 110 and m_color[1] < 100:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # Shrink alpha 1-2 px to strip transition magenta boundary
    for _ in range(4):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_dh = dh[edge]
        edge_r = r[edge]
        edge_g = g[edge]
        edge_b = b[edge]
        is_halo = (edge_dh < 35) & (edge_r > edge_g + 15) & (edge_b > edge_g + 8)
        edge_to_strip = np.zeros_like(obj)
        edge_to_strip[edge] = is_halo
        if not edge_to_strip.any():
            break
        obj &= ~edge_to_strip
        
    # Drop tiny detached islands (< 50 px)
    obj_labeled, num_obj = ndi.label(obj)
    if num_obj > 1:
        sizes = ndi.sum(obj, obj_labeled, range(num_obj + 1))
        # Keep only components with size >= 50
        keep_labels = [i for i, s in enumerate(sizes) if s >= 50 and i > 0]
        obj = np.isin(obj_labeled, keep_labels)
        
    # Despill: neutralise any leftover pink tint on outer 2px
    im_clean = im.copy()
    for _ in range(2):
        edge_outer = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_pinkish = edge_outer & (dh < 40) & (im_clean[..., 0] > im_clean[..., 1] + 8) & (im_clean[..., 2] > im_clean[..., 1] + 5)
        im_clean[edge_pinkish, 0] = np.minimum(im_clean[edge_pinkish, 0], im_clean[edge_pinkish, 1] + 5)
        im_clean[edge_pinkish, 2] = np.minimum(im_clean[edge_pinkish, 2], im_clean[edge_pinkish, 1] + 5)
        
    # Remove any light/white rim on outer 1px
    for _ in range(2):
        edge_final = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_lum = 0.299 * im_clean[..., 0] + 0.587 * im_clean[..., 1] + 0.114 * im_clean[..., 2]
        edge_light = edge_final & (edge_lum > 140) & (im_clean[..., 0] > 120) & (im_clean[..., 1] > 115) & (im_clean[..., 2] > 100)
        # Clamp light edge pixels to dark inked tone
        im_clean[edge_light, 0] = np.minimum(im_clean[edge_light, 0], 35.0)
        im_clean[edge_light, 1] = np.minimum(im_clean[edge_light, 1], 35.0)
        im_clean[edge_light, 2] = np.minimum(im_clean[edge_light, 2], 35.0)
        
    # Soft 1px edge
    alpha = np.where(obj, 255.0, 0.0)
    edge_1px = obj & ~ndi.binary_erosion(obj, iterations=1, border_value=1)
    alpha[edge_1px] = 210.0
    
    # Drop semi-transparent pixels below alpha 70
    alpha[alpha < 70.0] = 0.0
    
    # Bounding box
    ys, xs = np.nonzero(alpha > 0)
    if len(ys) == 0:
        raise ValueError(f"No object found during cutout!")
        
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_crop = im_clean[y0:y1, x0:x1]
    alpha_crop = alpha[y0:y1, x0:x1]
    rgba_crop = np.dstack([obj_crop.astype(np.uint8), alpha_crop.astype(np.uint8)])
    crop_img = Image.fromarray(rgba_crop, "RGBA")
    
    # Center on square canvas (target_size=512) filling about 80-82%
    obj_w, obj_h = crop_img.size
    max_dim = max(obj_w, obj_h)
    target_dim = int(round(target_size * target_fill_pct))
    scale = target_dim / float(max_dim)
    new_w = max(1, int(round(obj_w * scale)))
    new_h = max(1, int(round(obj_h * scale)))
    
    resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    final_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - new_w) // 2
    paste_y = (target_size - new_h) // 2
    final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
    
    # Mandatory zero pink pixels & zero light rim pixels
    pk = count_pink_pixels(final_canvas)
    if pk > 0:
        arr_fin = np.asarray(final_canvas).copy().astype(float)
        r_f, g_f, b_f, a_f = arr_fin[..., 0], arr_fin[..., 1], arr_fin[..., 2], arr_fin[..., 3]
        h_f = hue(arr_fin[..., :3])
        dh_f = np.abs(((h_f - hue(bgc)) + 180) % 360 - 180)
        chroma_f = arr_fin[..., :3].max(-1) - arr_fin[..., :3].min(-1)
        pink_f = (a_f > 20) & (dh_f < 24) & (chroma_f > 80) & (r_f > g_f + 40) & (b_f > g_f + 20)
        arr_fin[pink_f, 0] = np.maximum(0, arr_fin[pink_f, 1] + 12)
        arr_fin[pink_f, 2] = np.maximum(0, arr_fin[pink_f, 1] + 12)
        final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
        pk = count_pink_pixels(final_canvas)
        
    lr = count_light_rim_pixels(final_canvas)
    if lr > 0:
        arr_fin = np.asarray(final_canvas).copy().astype(float)
        a_f = arr_fin[..., 3]
        is_s = a_f > 50
        e_m = is_s & ~ndi.binary_erosion(is_s, iterations=2)
        lum_f = 0.299 * arr_fin[..., 0] + 0.587 * arr_fin[..., 1] + 0.114 * arr_fin[..., 2]
        lr_m = e_m & (lum_f > 140) & (arr_fin[..., 0] > 120) & (arr_fin[..., 1] > 115) & (arr_fin[..., 2] > 100)
        arr_fin[lr_m, 0] = np.minimum(arr_fin[lr_m, 0], 35.0)
        arr_fin[lr_m, 1] = np.minimum(arr_fin[lr_m, 1], 35.0)
        arr_fin[lr_m, 2] = np.minimum(arr_fin[lr_m, 2], 35.0)
        final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
        lr = count_light_rim_pixels(final_canvas)
        
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    final_canvas.save(out_path, format="PNG")
    print(f"Chest saved: {out_path} (pink_pixels={pk}, light_rim_pixels={lr})")
    return final_canvas, pk, lr

# 8. Check Sheet Builder for Cutouts (Chests)
def build_chests_check_sheet(chest_images=None):
    """Makes iron-oath-art/check_chests.png with every cutout twice:
    once on flat stone grey #7F7A70 and once on near-black #0D0B09.
    """
    if chest_images is None:
        chest_images = []
        for c in CHESTS_DATA:
            p = os.path.join(REPO_DIR, c["file"])
            if os.path.exists(p):
                chest_images.append((c["id"], Image.open(p)))
            else:
                return None
                
    num = len(chest_images)
    tile_size = 512
    # 2 rows: Row 0 on #7F7A70 (127, 122, 112), Row 1 on #0D0B09 (13, 11, 9)
    sheet = Image.new("RGB", (num * tile_size, 2 * tile_size), (127, 122, 112))
    
    # Fill bottom row with near-black
    bg_black = Image.new("RGB", (num * tile_size, tile_size), (13, 11, 9))
    sheet.paste(bg_black, (0, tile_size))
    
    for i, (cid, cimg) in enumerate(chest_images):
        # Top row: stone grey
        sheet.paste(cimg, (i * tile_size, 0), cimg)
        # Bottom row: near black
        sheet.paste(cimg, (i * tile_size, tile_size), cimg)
        
    sheet.save(CHECK_SHEET_IRON, format="PNG")
    sheet.save(CHECK_SHEET_ROOT, format="PNG")
    print(f"Check sheet saved -> {CHECK_SHEET_IRON} and {CHECK_SHEET_ROOT}")
    return sheet

# 9. Update Manifests & assets_list.json
def update_all_manifests(records):
    # 1. Update assets/art/manifest.json (list)
    art_list = []
    if os.path.exists(MANIFEST_ART):
        try:
            with open(MANIFEST_ART, "r", encoding="utf-8") as f:
                art_list = json.load(f)
        except Exception:
            art_list = []
    art_map = {item.get("id"): item for item in art_list if isinstance(item, dict) and "id" in item}
    for r in records:
        art_map[r["id"]] = r
    new_art_list = list(art_map.values())
    with open(MANIFEST_ART, "w", encoding="utf-8") as f:
        json.dump(new_art_list, f, indent=2)
    print(f"Updated {MANIFEST_ART} (total: {len(new_art_list)})")
    
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
    print(f"Updated {MANIFEST_ROOT} (total: {len(root_dict)})")
    
    # 3. Update iron-oath-art/manifest.json (list)
    if os.path.exists(MANIFEST_IRON):
        try:
            with open(MANIFEST_IRON, "r", encoding="utf-8") as f:
                iron_list = json.load(f)
        except Exception:
            iron_list = []
        iron_map = {item.get("id"): item for item in iron_list if isinstance(item, dict) and "id" in item}
        for r in records:
            iron_map[r["id"]] = r
        new_iron_list = list(iron_map.values())
        with open(MANIFEST_IRON, "w", encoding="utf-8") as f:
            json.dump(new_iron_list, f, indent=2)
        print(f"Updated {MANIFEST_IRON} (total: {len(new_iron_list)})")

def update_assets_list(all_batch_items):
    """Add every asset to iron-oath-art/assets_list.json (keep what is already there)."""
    existing = []
    if os.path.exists(ASSETS_LIST_IRON):
        try:
            with open(ASSETS_LIST_IRON, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception:
            existing = []
            
    existing_ids = {item["id"] for item in existing if isinstance(item, dict) and "id" in item}
    for item in all_batch_items:
        if item["id"] not in existing_ids:
            existing.append(item)
            existing_ids.add(item["id"])
            
    with open(ASSETS_LIST_IRON, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2)
    print(f"Updated {ASSETS_LIST_IRON} (total entries: {len(existing)})")

def run_asset(item, extra_refs=None):
    aid = item["id"]
    atype = item["type"]
    prompt_text = item["prompt"]
    file_path = item["file"]
    out_path = os.path.join(REPO_DIR, file_path)
    raw_path = os.path.join(RAW_DIR, f"{aid}.png")
    
    # Check if raw already exists
    if os.path.exists(raw_path):
        print(f"[{aid}] Raw file already exists: {raw_path}. Skipping generation.")
        with open(raw_path, "rb") as f:
            raw_bytes = f.read()
        attempts = 1
    else:
        print(f"[{aid}] Generating {atype}...")
        if atype == "cutout":
            full_prompt = f"{CHEST_GLOBAL_STYLE}\n\nSUBJECT: {prompt_text}"
        else:
            full_prompt = f"{MAP_GLOBAL_STYLE}\n\nSUBJECT: {prompt_text}"
            
        raw_bytes, attempts = generate_image(full_prompt, extra_refs=extra_refs)
        if not raw_bytes:
            raise RuntimeError(f"Failed to generate {aid}")
            
        with open(raw_path, "wb") as f:
            f.write(raw_bytes)
        print(f"[{aid}] Saved raw image -> {raw_path}")
        
    # Process
    if atype == "cutout":
        final_img, pk, lr = process_chest_cutout(raw_bytes, out_path, target_size=item.get("size", 512))
        record = {
            "id": aid,
            "file": file_path,
            "type": "cutout",
            "size": 512,
            "prompt": prompt_text,
            "references": [r["name"] for r in CACHED_REFS] + ([r["name"] for r in extra_refs] if extra_refs else []),
            "attempts": attempts,
            "pink_pixels": pk,
            "light_rim_pixels": lr,
            "status": "done"
        }
    else:
        final_img = process_map_image(raw_bytes, out_path, target_w=1080, target_h=1920)
        record = {
            "id": aid,
            "file": file_path,
            "type": "background",
            "width": 1080,
            "height": 1920,
            "prompt": prompt_text,
            "references": [r["name"] for r in CACHED_REFS],
            "attempts": attempts,
            "status": "done"
        }
        
    return record

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "test"
    print(f"Running mode: {mode}")
    
    # Pre-populate assets_list.json with all batch items as requested
    all_batch = CHESTS_DATA + MAPS_DATA
    update_assets_list(all_batch)
    
    if mode in ["test", "chests", "fix-chests", "all"]:
        print("\n=== STEP 2: Processing Chests ===")
        # If in fix-chests or all, remove outdated raw files for wood, iron, gold
        if mode in ["fix-chests", "all"]:
            for fix_id in ["chest_wood", "chest_iron", "chest_gold"]:
                old_raw = os.path.join(RAW_DIR, f"{fix_id}.png")
                if os.path.exists(old_raw):
                    print(f"Removing outdated raw {old_raw} for regeneration...")
                    try:
                        os.remove(old_raw)
                    except Exception as e:
                        print(f"Warning: {e}")
                        
        chest_records = []
        for c in CHESTS_DATA:
            cid = c["id"]
            rec = run_asset(c, extra_refs=None)
            chest_records.append(rec)
            update_all_manifests([rec])
                
        # Build check sheet for chests
        build_chests_check_sheet()
        print("Chests batch completed.")
        
    if mode in ["maps", "all"]:
        print("\n=== STEP 3: Processing Expedition Maps ===")
        map_records = []
        for m in MAPS_DATA:
            rec = run_asset(m)
            map_records.append(rec)
            update_all_manifests([rec])
        print("Maps batch completed.")
        
    print("\n=== All requested assets processed successfully! ===")



