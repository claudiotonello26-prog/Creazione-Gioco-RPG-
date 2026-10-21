import os
import sys
import io
import time
import json
import base64
import urllib.request
from PIL import Image

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
PIPELINE_DIR = os.path.join(REPO_DIR, "pipeline")
ENV_PATH = os.path.join(PIPELINE_DIR, ".env")

with open(ENV_PATH, "r", encoding="utf-8") as f:
    for line in f:
        if line.startswith("GEMINI_API_KEY="):
            GEMINI_KEY = line.strip().split("=", 1)[1]
            break

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

REF_PATHS = [
    os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png"),
]

def load_ref_b64(path, max_dim=512):
    im = Image.open(path)
    im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

cached_refs = []
for rp in REF_PATHS:
    if os.path.exists(rp):
        cached_refs.append({
            "name": os.path.basename(rp),
            "b64": load_ref_b64(rp)
        })

print(f"Loaded {len(cached_refs)} references.")

GLOBAL_STYLE_INSTRUCTION = (
    "STYLE REFERENCES: Match the hand-painted dark fantasy illustration style, bold black ink outlines, "
    "painterly shading, gritty textured iron/stone brushwork, and souls-like mood (Dark Souls, Elden Ring, Gym Oath) of these reference characters.\n"
    "CRITICAL FORMAT & COMPOSITION RULES:\n"
    "- Exactly ONE circular medallion/crest/seal, perfectly centered, filling 92% of the canvas.\n"
    "- Outside the circular rim: solid flat black #000000 background filling the corners. No colors or details outside the circle.\n"
    "- Medallion rim: thick round rim of dark worn forged iron/metal with small carved runes or small rivets.\n"
    "- Inside the rim: a dark field with ONE bold, iconic central symbol of the crafting station, big and simple with strong silhouette contrast.\n"
    "- Lighting from upper-left, with a soft inner atmospheric glow in the accent colour behind/inside the symbol.\n"
    "- STRICT COLOR PALETTE: MONOCHROME BASE ONLY. The entire emblem base is composed solely of black, charcoal, dark grey, mid grey, light grey, and off-white (like cold wrought iron, dark steel, and pale stone). "
    "ABSOLUTELY NO gold, NO yellow, NO bronze, NO brown, NO rust, NO green, NO rainbow hues.\n"
    "- The ONLY accent colour allowed is the specific station accent color specified below, used for the glow, hot/magic parts, and thin highlights.\n"
    "- Readability: Must read instantly as an icon even when scaled down to 128x128. Few bold shapes, clear separation, no clutter.\n"
    "- NO text, NO words, NO letters, NO numbers, NO user interface frames, NO drop shadow pedestals."
)

ANVIL_PROMPT = (
    f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
    "SUBJECT: Crafting Station Emblem - Anvil (Weapons & Armor Forging)\n"
    "STATION ACCENT COLOR: Cold Steel Blue #6E9BC9 and blue-white glowing light.\n"
    "DETAILS:\n"
    "- A circular forged iron medallion seal with a thick circular rim of dark pitted iron and subtle hammered rivets.\n"
    "- Central symbol: A massive blacksmith's anvil seen from the side, heavy and solid. A heavy smith's forging hammer is raised angled above the anvil. "
    "A straight glowing sword blade rests horizontally across the anvil face, with a striking bright blue-white glowing hot line (#6E9BC9) along its cutting edge.\n"
    "- Soft atmospheric cold steel blue (#6E9BC9) inner glow radiating from behind the anvil and around the glowing hot blade edge.\n"
    "- Subtle cold blue highlights catching the hammer edges and anvil horn.\n"
    "- All base materials (anvil body, hammer head, sword steel, medallion rim, and inner field) are strictly monochrome black, charcoal, and cold iron grey. Zero gold, zero rust, zero warm colors.\n"
    "- Bold inked outlines, hand-painted souls-like game emblem, dark fantasy craftsmanship."
)

parts = []
for ref in cached_refs:
    parts.append({"text": f"Style Reference ({ref['name']}): Match this dark fantasy painterly style and ink linework:"})
    parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})

parts.append({"text": ANVIL_PROMPT})

payload = {"contents": [{"parts": parts}]}
headers = {
    "Content-Type": "application/json",
    "x-goog-api-key": GEMINI_KEY
}

out_raw = os.path.join(PIPELINE_DIR, "output", "test_anvil_raw.png")
os.makedirs(os.path.dirname(out_raw), exist_ok=True)

print("Calling Gemini 2.5 Flash Image API...")
req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
with urllib.request.urlopen(req, timeout=90) as resp:
    data = json.loads(resp.read().decode("utf-8"))
    for p in data["candidates"][0]["content"]["parts"]:
        if "inlineData" in p:
            raw_bytes = base64.b64decode(p["inlineData"]["data"])
            with open(out_raw, "wb") as f_out:
                f_out.write(raw_bytes)
            print(f"Saved raw image to {out_raw} ({len(raw_bytes)} bytes)")
            im = Image.open(out_raw)
            print(f"Dimensions: {im.size}, mode: {im.mode}")
            break
