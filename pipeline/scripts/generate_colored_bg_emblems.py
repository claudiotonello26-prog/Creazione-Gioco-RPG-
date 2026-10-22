import os
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

def load_b64(path, max_dim=512):
    im = Image.open(path)
    im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    import io
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

ref_carpentry = os.path.join(REPO_DIR, "assets", "art", "emblems", "station_carpentry.png")
ref_bellows = os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png")

FURNACE_PROMPT = (
    "STYLE & BACKGROUND REFERENCE (Carpentry Emblem):\n"
    "Notice how the carpentry reference emblem has a rich, dedicated warm atmospheric colored background wash filling the inner circular field behind the tools. We want the EXACT SAME visual structure, but for the FURNACE station with GLOWING MOLTEN RED.\n\n"
    "CRITICAL COMPOSITION & COLOR RULES:\n"
    "- Exactly ONE circular medallion/crest/seal, perfectly centered, filling about 92% of the canvas.\n"
    "- Outside the circular medallion: pure solid black #000000 flat background.\n"
    "- Medallion rim: thick round rim of dark worn metal with small rivets or simple carved runes, identical to the reference.\n"
    "- DEDICATED COLORED BACKGROUND: Inside the circular rim, the background field behind the stone furnace and crucible is bathed in a rich, luminous, glowing atmospheric MOLTEN RED (#D2452F) firelight haze and smoke wash, exactly like the dedicated colored background in the carpentry emblem.\n"
    "- Central symbol: A stone smelting furnace mouth (arched opening) with a heavy dark iron crucible tilted and pouring a stream of glowing red molten metal into an ingot mould below.\n"
    "- The molten metal stream, ingot mould fill, and furnace arched mouth glow vibrant molten red (#D2452F), with tiny embers rising.\n"
    "- The stone structure, crucible, and iron rim are dark charcoal and grey, casting strong silhouette contrast against the luminous glowing red background field.\n"
    "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability.\n"
    "- NO text, no letters, no numbers, no UI frame."
)

ENCHANT_PROMPT = (
    "STYLE & BACKGROUND REFERENCE (Carpentry Emblem):\n"
    "Notice how the carpentry reference emblem has a rich, dedicated warm atmospheric colored background wash filling the inner circular field behind the tools. We want the EXACT SAME visual structure, but for the ENCHANTING station with MYSTIC ARCANE VIOLET.\n\n"
    "CRITICAL COMPOSITION & COLOR RULES:\n"
    "- Exactly ONE circular medallion/crest/seal, perfectly centered, filling about 92% of the canvas.\n"
    "- Outside the circular medallion: pure solid black #000000 flat background.\n"
    "- Medallion rim: thick round rim of dark worn metal with small rivets or simple carved runes, identical to the reference.\n"
    "- DEDICATED COLORED BACKGROUND: Inside the circular rim, the background field behind the sword and runes is bathed in a rich, luminous, deep MYSTIC VIOLET (#A77BE0) arcane nebula wash and ethereal magic haze, exactly like the dedicated colored background in the carpentry emblem.\n"
    "- Central symbol: A straight knight sword pointing vertically upward, its blade passing cleanly through the center of a faceted cut gemstone or rune stone.\n"
    "- A ring of glowing violet runes and delicate four-pointed star sparks floating around the sword blade and gemstone.\n"
    "- The faceted gemstone, the floating runes, and the star sparks glow ethereal violet (#A77BE0).\n"
    "- The sword steel blade, hilt, and iron rim are dark charcoal and steel grey, casting strong silhouette contrast against the luminous mystic violet background field.\n"
    "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability.\n"
    "- NO text, no letters, no numbers, no UI frame."
)

def gen(name, prompt, out_p):
    parts = [
        {"text": "Background Field Reference (match this rich colored atmospheric background wash behind the symbol):"},
        {"inlineData": {"mimeType": "image/png", "data": load_b64(ref_carpentry)}},
        {"text": "Creature inking and shading reference:"},
        {"inlineData": {"mimeType": "image/png", "data": load_b64(ref_bellows)}},
        {"text": prompt}
    ]
    payload = {"contents": [{"parts": parts}]}
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json", "x-goog-api-key": GEMINI_KEY})
    print(f"Generating {name}...")
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        for p in data["candidates"][0]["content"]["parts"]:
            if "inlineData" in p:
                raw_bytes = base64.b64decode(p["inlineData"]["data"])
                with open(out_p, "wb") as f:
                    f.write(raw_bytes)
                print(f"Saved {out_p}")
                break

if __name__ == "__main__":
    import sys
    task = sys.argv[1] if len(sys.argv) > 1 else "furnace"
    if task == "furnace":
        gen("furnace", FURNACE_PROMPT, "pipeline/output/test_furnace_red_bg_raw.png")
    elif task == "enchant":
        gen("enchant", ENCHANT_PROMPT, "pipeline/output/test_enchant_violet_bg_raw.png")
