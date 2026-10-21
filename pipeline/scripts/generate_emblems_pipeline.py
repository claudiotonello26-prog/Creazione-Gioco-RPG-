import os
import sys
import io
import time
import json
import base64
import urllib.request
import numpy as np
from PIL import Image

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
PIPELINE_DIR = os.path.join(REPO_DIR, "pipeline")
ENV_PATH = os.path.join(PIPELINE_DIR, ".env")
RAW_DIR = os.path.join(PIPELINE_DIR, "output", "raw_emblems")
EMBLEMS_DIR = os.path.join(REPO_DIR, "assets", "art", "emblems")
IRON_DIR = r"C:\Users\pissio\iron-oath-art"

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(EMBLEMS_DIR, exist_ok=True)

with open(ENV_PATH, "r", encoding="utf-8") as f:
    for line in f:
        if line.startswith("GEMINI_API_KEY="):
            GEMINI_KEY = line.strip().split("=", 1)[1]
            break

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

# Base style references
REF_ANVIL_GOLEM = os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png")
REF_LIVING_BELLOWS = os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png")
REF_ANVIL_EMBLEM = os.path.join(PIPELINE_DIR, "output", "test_anvil_cleaned_512.png")

def load_ref_b64(path, max_dim=512):
    im = Image.open(path)
    im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

GLOBAL_STYLE_INSTRUCTION = (
    "STYLE REFERENCES: Match the hand-painted dark fantasy illustration style, bold black ink outlines, "
    "gritty painterly brushwork, and souls-like mood (Dark Souls, Elden Ring, Gym Oath) of these reference characters.\n"
    "CRITICAL FORMAT & COMPOSITION RULES:\n"
    "- Exactly ONE circular medallion/crest/seal, perfectly centered, filling about 92% of the canvas.\n"
    "- Background OUTSIDE the circular medallion: pure flat solid black #000000 filling the entire canvas outside the circle. No shapes, no colors, no vignettes outside the circle.\n"
    "- Medallion rim: thick round rim of dark worn metal with small rivets or simple carved runes, matching the format reference.\n"
    "- Inside the rim: ONE bold central symbol of the station, big and simple, with strong graphic contrast between the pale symbol and the dark field.\n"
    "- Lighting strictly from the upper left.\n"
    "- Soft inner atmospheric glow in the station's accent colour behind or inside the central symbol.\n"
    "- STRICT COLOR PALETTE: MONOCHROME BASE ONLY. The entire emblem base is made only of black, charcoal, dark grey, mid grey, light grey, and off-white (like old iron, dark steel, and pale stone). "
    "ABSOLUTELY NO gold, NO yellow, NO bronze, NO brown, NO rust, NO rainbow hues.\n"
    "- The ONLY color allowed is the station's own accent colour, used for the glow, the hot/magic parts, and thin highlights.\n"
    "- Readable as a small icon: few big shapes, strong contrast, no tiny details that turn into noise when scaled to 128x128.\n"
    "- NO text, NO words, NO letters, NO numbers, NO UI frame, NO drop shadow plate."
)

EMBLEM_SPECS = {
    "station_anvil": {
        "file": "assets/art/emblems/station_anvil.png",
        "name": "Anvil Crafting Station Emblem",
        "accent_name": "Cold Steel Blue #6E9BC9",
        "hue_range": (180, 245),
        "prompt": (
            f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
            "SUBJECT: Crafting Station Emblem - Anvil (Weapons & Armor Forging)\n"
            "STATION ACCENT COLOR: Cold Steel Blue #6E9BC9 and blue-white glowing light.\n"
            "DETAILS:\n"
            "- A circular forged iron medallion seal with a thick circular rim of dark pitted iron and subtle hammered rivets.\n"
            "- Central symbol: A heavy blacksmith anvil seen from the side, with a smith's hammer raised angled above it, "
            "and a sword blade lying horizontally on the anvil with a blue-white hot glowing line along its cutting edge.\n"
            "- Steel parts have cold blue highlights (#6E9BC9). The rest is strictly monochrome dark grey, charcoal, and black.\n"
            "- Soft inner glow in cold steel blue (#6E9BC9) behind and inside the central symbol.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
        ),
        "raw_file": os.path.join(PIPELINE_DIR, "output", "test_anvil_raw.png")
    },
    "station_carpentry": {
        "file": "assets/art/emblems/station_carpentry.png",
        "name": "Carpentry Crafting Station Emblem",
        "accent_name": "Warm Orange #D9893A",
        "hue_range": (15, 48),
        "prompt": (
            f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
            "SUBJECT: Crafting Station Emblem - Carpentry (Woodworking & Bowcraft)\n"
            "STATION ACCENT COLOR: Warm Orange #D9893A (like warm wood and sawdust in lamplight).\n"
            "DETAILS:\n"
            "- A circular worn dark metal medallion seal with a thick circular rim of dark pitted iron and simple carved runes, identical in size and shape to the set reference.\n"
            "- Central symbol: A traditional carpenter's hand saw crossed with a heavy woodworking axe over a cut tree log round ring (growth rings clearly visible).\n"
            "- The sharp saw teeth and the concentric log rings catch the warm orange light (#D9893A).\n"
            "- A few curled wood shavings resting near the bottom inner rim, catching the warm orange glow.\n"
            "- Everything else (axe head, metal saw blade body, dark iron rim, background field) is strictly monochrome dark charcoal, steel grey, and black. NO brown, NO yellow, NO rust.\n"
            "- Soft inner glow in warm orange (#D9893A) radiating from behind the central symbol.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability."
        ),
        "raw_file": os.path.join(RAW_DIR, "station_carpentry_raw.png")
    },
    "station_furnace": {
        "file": "assets/art/emblems/station_furnace.png",
        "name": "Furnace / Smelting Crafting Station Emblem",
        "accent_name": "Molten Red #D2452F",
        "hue_range": (345, 25), # wrap around 0
        "prompt": (
            f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
            "SUBJECT: Crafting Station Emblem - Furnace (Smelting & Refining)\n"
            "STATION ACCENT COLOR: Glowing Molten Red #D2452F (like molten metal, fire and embers).\n"
            "DETAILS:\n"
            "- A circular worn dark metal medallion seal with a thick circular rim of dark iron and small rivets, identical in size and shape to the set reference.\n"
            "- Central symbol: A stone smelting furnace mouth (arched opening) with a heavy crucible tilted and pouring a thin stream of glowing red molten metal into an ingot mould below.\n"
            "- The molten metal stream, ingot mould fill, and furnace arched mouth interior glow vibrant molten red (#D2452F).\n"
            "- Tiny glowing red embers rise softly into the dark field above the furnace.\n"
            "- The furnace stones, crucible, ingot mould, and rim are strictly monochrome dark charcoal, grey, and black.\n"
            "- Soft inner glow in glowing molten red (#D2452F) radiating from inside the furnace mouth.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability."
        ),
        "raw_file": os.path.join(RAW_DIR, "station_furnace_raw.png")
    },
    "station_enchant": {
        "file": "assets/art/emblems/station_enchant.png",
        "name": "Enchanting Crafting Station Emblem",
        "accent_name": "Mystic Violet #A77BE0",
        "hue_range": (245, 295),
        "prompt": (
            f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
            "SUBJECT: Crafting Station Emblem - Enchanting (Awakening Weapon Auras)\n"
            "STATION ACCENT COLOR: Mystic Violet #A77BE0 (mysterious, ethereal magic, not evil or corrupted).\n"
            "DETAILS:\n"
            "- A circular worn dark metal medallion seal with a thick circular rim of dark iron and carved runes, identical in size and shape to the set reference.\n"
            "- Central symbol: A straight knight sword pointing vertically upward, its blade passing cleanly through the center of a faceted cut gemstone or rune stone.\n"
            "- A ring of small mystical violet runes and delicate four-pointed star sparks floating around the sword blade and gemstone.\n"
            "- The faceted gemstone, the floating runes, and the star sparks glow ethereal violet (#A77BE0).\n"
            "- The sword blade, crossguard, hilt, rim, and field are strictly monochrome dark steel, charcoal, and black.\n"
            "- Soft inner glow in mystic violet (#A77BE0) radiating from the enchanted gemstone.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability."
        ),
        "raw_file": os.path.join(RAW_DIR, "station_enchant_raw.png")
    }
}

def generate_raw(station_id, max_retries=3):
    spec = EMBLEM_SPECS[station_id]
    raw_path = spec["raw_file"]
    if os.path.exists(raw_path):
        print(f"[{station_id}] Raw image already exists at {raw_path}")
        return raw_path

    parts = []
    # Style references
    for p, desc in [(REF_ANVIL_GOLEM, "creature painting style"), (REF_LIVING_BELLOWS, "carved texture & inking style")]:
        if os.path.exists(p):
            parts.append({"text": f"Reference image for {desc}:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": load_ref_b64(p)}})

    # Set reference (anvil emblem) to maintain matching rim and composition
    if os.path.exists(REF_ANVIL_EMBLEM):
        parts.append({"text": "SET FORMAT REFERENCE: Match the exact rim thickness, centered circular composition, 92% diameter, upper-left lighting, and monochrome base palette of this existing emblem medallion in the set:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": load_ref_b64(REF_ANVIL_EMBLEM)}})

    parts.append({"text": spec["prompt"]})

    payload = {"contents": [{"parts": parts}]}
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }

    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    for attempt in range(max_retries):
        try:
            print(f"[{station_id}] Calling Gemini API (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        with open(raw_path, "wb") as f_out:
                            f_out.write(raw_bytes)
                        print(f"[{station_id}] Saved raw image ({len(raw_bytes)} bytes) to {raw_path}")
                        return raw_path
        except Exception as e:
            print(f"[{station_id}] Attempt {attempt+1} failed: {e}")
            time.sleep(3)

    raise RuntimeError(f"Failed to generate {station_id}")

def process_and_deliver(station_id):
    spec = EMBLEM_SPECS[station_id]
    raw_path = spec["raw_file"]
    out_path = os.path.join(REPO_DIR, spec["file"])
    h_min, h_max = spec["hue_range"]

    im = Image.open(raw_path).convert("RGB")
    arr = np.array(im).astype(float) / 255.0
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]

    # Luminance
    lum = 0.299 * r + 0.587 * g + 0.114 * b

    # HSV
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin

    hue = np.zeros_like(cmax)
    r_mask = (cmax == r) & (delta > 1e-4)
    g_mask = (cmax == g) & (delta > 1e-4)
    b_mask = (cmax == b) & (delta > 1e-4)

    hue[r_mask] = (60 * ((g[r_mask] - b[r_mask]) / delta[r_mask]) + 360) % 360
    hue[g_mask] = (60 * ((b[g_mask] - r[g_mask]) / delta[g_mask]) + 120) % 360
    hue[b_mask] = (60 * ((r[b_mask] - g[b_mask]) / delta[b_mask]) + 240) % 360

    # Soft hue mask: distance in hue space from valid accent range
    if h_min <= h_max:
        dist_left = np.maximum(0, h_min - hue)
        dist_right = np.maximum(0, hue - h_max)
        hue_dist = np.maximum(dist_left, dist_right)
    else:
        in_range = (hue >= h_min) | (hue <= h_max)
        dist1 = np.where(hue < h_min, h_min - hue, 0)
        dist2 = np.where(hue > h_max, hue - h_max, 0)
        hue_dist = np.where(in_range, 0, np.minimum(dist1, dist2))

    # Allow 15 degrees smooth transition to grayscale
    soft_factor = np.clip(1.0 - hue_dist / 15.0, 0.0, 1.0)[..., np.newaxis]
    gray_rgb = np.stack([lum, lum, lum], axis=-1)
    cleaned_arr = soft_factor * arr + (1.0 - soft_factor) * gray_rgb

    # Find medallion rim bounds to ensure centering & perfect circular border
    gray_255 = lum * 255.0
    thresh_mask = gray_255 > 12.0
    rows = np.any(thresh_mask, axis=1)
    cols = np.any(thresh_mask, axis=0)
    ymin, ymax = np.where(rows)[0][[0, -1]]
    xmin, xmax = np.where(cols)[0][[0, -1]]
    cx = (xmin + xmax) / 2.0
    cy = (ymin + ymax) / 2.0
    r_est = max((xmax - xmin) / 2.0, (ymax - ymin) / 2.0)
    print(f"[{station_id}] Detected circle center=({cx:.1f}, {cy:.1f}), radius={r_est:.1f}")

    # Use centered circle radius ~488
    H, W = arr.shape[:2]
    Y, X = np.ogrid[:H, :W]
    dist_from_center = np.sqrt((X - cx)**2 + (Y - cy)**2)
    # Smooth fade out at rim edge
    circle_alpha = np.clip((r_est + 1.0 - dist_from_center) / 3.0, 0.0, 1.0)[..., np.newaxis]
    final_arr = cleaned_arr * circle_alpha

    final_img = Image.fromarray(np.clip(final_arr * 255.0, 0, 255).astype(np.uint8))
    # Downscale to 512x512
    final_512 = final_img.resize((512, 512), Image.Resampling.LANCZOS)
    final_512.save(out_path, format="PNG")
    print(f"[{station_id}] Delivered 512x512 to {out_path}")

    # Also make 128x128 for verification check
    verif_128 = final_512.resize((128, 128), Image.Resampling.LANCZOS)
    verif_p = os.path.join(PIPELINE_DIR, "output", f"{station_id}_128.png")
    verif_128.save(verif_p, format="PNG")
    return out_path, verif_p

if __name__ == "__main__":
    sid = sys.argv[1] if len(sys.argv) > 1 else "station_anvil"
    print(f"Processing station: {sid}")
    generate_raw(sid)
    process_and_deliver(sid)
