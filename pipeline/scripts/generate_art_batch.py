"""Generation and Processing Pipeline for 'Gym Oath' NPCs and Gathering Nodes.
Mobile Dark Fantasy Medieval Fitness RPG (Souls-like: Dark Souls / Elden Ring aesthetic).
Generates 1024x1024 raw images via Gemini 2.5 Flash Image API with creature style references,
performs magenta chroma cutout with despill, halo removal, antialiasing, ensures pink_pixels == 0,
delivers 512x512 RGBA PNGs to assets/art/npc/ and assets/art/nodes/,
updates manifest.json, and produces check sheet check_npc_nodes.png.
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
RAW_DIR = os.path.join(r"C:\Users\pissio\iron-oath-art", "raw_nodes_npcs")
NPC_DIR = os.path.join(REPO_DIR, "assets", "art", "npc")
NODES_DIR = os.path.join(REPO_DIR, "assets", "art", "nodes")
MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
IRON_CHECK = os.path.join(r"C:\Users\pissio\iron-oath-art", "check_npc_nodes.png")
ROOT_CHECK = os.path.join(REPO_DIR, "check_npc_nodes.png")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(NPC_DIR, exist_ok=True)
os.makedirs(NODES_DIR, exist_ok=True)

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

# 2. Reference Images
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

# 3. Style Directive
GLOBAL_STYLE_INSTRUCTION = (
    "STYLE REFERENCES: Match the painting technique, inked outlines, level of detail, textural brushwork, "
    "and lighting of these reference images, but draw a completely different subject and use ONLY the colours written in this prompt.\n"
    "Aesthetic: Hand-painted dark fantasy illustration, souls-like mobile game art style (Dark Souls, Elden Ring, Gym Oath). "
    "Bold expressive black ink outlines defining the outer silhouette and internal anatomy/folds/crevices. "
    "Painterly cel-shading with rich but muted weathered colours, deep charcoal shadows (#0D0B09), warm antique gold rim light (#C9A24A), "
    "high contrast, sharp graphic readability even when scaled down to a small thumbnail. "
    "NO 3D CGI, no photographic skin, no smooth airbrushing, no flat cartoon, no anime, no modern elements.\n"
    "CRITICAL BACKGROUND RULE: Flat solid magenta background #FF00FF filling the entire canvas from edge to edge. "
    "Pure solid uniform magenta #FF00FF background only. Absolutely NEVER use any magenta, fuchsia, or pink on the subject, skin, clothes, props, or effects. "
    "No text, no watermark, no frame, no borders, no ground shadow plate, no UI."
)

# 4. Item Definitions
ITEMS = {
    # Part 1: Merchants (4 busts) - Friendly, looking into camera / viewer
    "general_store": {
        "type": "npc",
        "file": "assets/art/npc/general_store.png",
        "name": "Berta of the General Store",
        "framing": (
            "Framing: head and upper chest bust only (cut cleanly at mid-chest, just under the shoulders). "
            "Front-facing towards the camera/viewer (or very slight three-quarter angle), eyes looking straight into the camera / at the player with a warm, friendly and welcoming smile. "
            "Head positioned in the upper half of the canvas with a little space above the head, shoulders broad and filling the canvas width. "
            "Light source from the upper left. Weathered, believable person of a grim medieval world, warm and inviting shopkeeper, not a hero, not a monster. "
            "Clothes are worn and practical: no shiny armour, no rust, nothing dark or corrupted."
        ),
        "desc": (
            "Berta of the General Store. Woman in her fifties, very warm and friendly welcoming smile, kind friendly eyes looking directly at the viewer/screen. "
            "Smooth natural weathered medieval skin tones, completely solid and fully painted skin with no white specks, no glitter, and no unpainted spots. "
            "Grey-streaked chestnut hair tied in a loose bun under a solid faded red cloth headscarf. Small circular brass spectacles perched neatly on her nose. "
            "Wearing a practical cream linen blouse, a coarse brown wool shawl draped around her, a leather apron strap over one shoulder, "
            "a pencil tucked behind her ear, and a small ring of brass keys hanging at the collar. "
            "Warm, friendly shopkeeper greeting the player warmly. "
            "Warm weathered colours strictly: faded red cloth, cream linen, brown wool, brass metal, natural warm skin tones. "
            "Bold crisp black inked outlines, clean smooth cel-shading, completely solid painted surfaces with NO white specks, NO uncolored patches, NO noise artifacts."
        )
    },
    "smith": {
        "type": "npc",
        "file": "assets/art/npc/smith.png",
        "name": "Master Gorran the Blacksmith",
        "framing": (
            "Framing: head and upper chest bust only (cut cleanly at mid-chest, just under the shoulders). "
            "Front-facing towards the camera/viewer (or very slight three-quarter angle), eyes looking straight into the camera / at the player with a hearty, friendly, warm and jovial warrior smile. "
            "Head positioned in the upper half of the canvas with a little space above the head, broad powerful shoulders filling the canvas width. "
            "Light source from the upper left, plus warm forge glow from below on one side. Weathered, believable craftsman, hearty and friendly. "
            "Clothes are worn and practical: no shiny armour, no rust, nothing dark or corrupted."
        ),
        "desc": (
            "Master Gorran the Blacksmith. Big bald man in his forties, hearty friendly smile, warm kind eyes looking directly into the camera / at the viewer, "
            "thick braided red-brown beard with a few singed hairs. "
            "Black soot smudges on his forehead and rugged cheeks, thick powerful neck. "
            "Heavy leather apron over a sleeveless sweat-darkened coarse grey shirt. "
            "His thick muscular, hairy, soot-stained arm and hand is raised to firmly grip and hold the heavy iron blacksmith tongs resting securely over his shoulder. "
            "Glow of the forge lighting him warm orange from below on one side. Welcoming master craftsman greeting the player warmly. "
            "Colours strictly: steel grey, leather brown, forge orange, natural ruddy skin tones. Bold inked outlines."
        )
    },
    "hunter": {
        "type": "npc",
        "file": "assets/art/npc/hunter.png",
        "name": "Edda the Huntress",
        "framing": (
            "Framing: head and upper chest bust only (cut cleanly at mid-chest, just under the shoulders). "
            "Front-facing towards the camera/viewer (or very slight three-quarter angle), eyes looking straight into the camera / at the player with a friendly, welcoming, gentle smile and kind eyes. "
            "Head positioned in the upper half of the canvas with a little space above the head, shoulders filling the canvas width. "
            "Light source from the upper left. Weathered, believable person of a grim medieval world, friendly and trustworthy ally. "
            "Clothes are worn and practical: no shiny armour, no rust, nothing dark or corrupted."
        ),
        "desc": (
            "Edda the Huntress. Lean woman in her thirties, sharp weathered hawk-like face softened by a warm, friendly smile and kind welcoming eyes looking straight at the viewer, "
            "a thin pale scar across one cheek. "
            "Dark blonde hair braided in a practical side braid over one shoulder. "
            "Wearing a forest green-brown hooded cloak with the hood down around her neck, a rough grey wolf fur collar, "
            "a sturdy oiled leather jerkin, a thick leather quiver strap across the chest with fletched feathered arrows visible behind her shoulder, "
            "and a carved bone talisman hanging from a leather cord. Friendly, welcoming demeanor. "
            "Colours strictly: forest green, wolf fur grey, weathered leather brown, bone white. Bold inked outlines."
        )
    },
    "mage": {
        "type": "npc",
        "file": "assets/art/npc/mage.png",
        "name": "Velthar the Mage",
        "framing": (
            "Framing: head and upper chest bust only (cut cleanly at mid-chest, just under the shoulders). "
            "Front-facing towards the camera/viewer (or very slight three-quarter angle), eyes looking straight into the camera / at the player with a warm, friendly, benevolent smile and kind wise eyes. "
            "Head positioned in the upper half of the canvas with a little space above the head, shoulders filling the canvas width. "
            "Light source from the upper left. Weathered, believable person of a grim medieval world, mysterious but kind, gentle and welcoming, NOT evil, NOT corrupted. "
            "Clothes are worn and practical: no shiny armour, no rust, nothing dark or corrupted."
        ),
        "desc": (
            "Velthar the Mage. Old thin weathered scholar man, warm gentle benevolent smile, wise kind eyes with a faint subtle violet sparkle looking straight into the camera / at the viewer, "
            "long flowing silver beard and mustache. "
            "Wearing a tall soft pointed scholar hood of deep indigo cloth embroidered with small faded antique silver runes, high collar robes. "
            "The carved top of an ancient wooden staff with an embedded pale crystal visible beside his shoulder, and a few small glass potion vials with pale liquids hanging from a shoulder strap. "
            "Colours strictly: deep indigo cloth, subtle violet glow, antique silver, weathered aged parchment skin tones. Gentle, warm, kind mentor demeanor. Bold inked outlines."
        )
    },

    # Part 2: Gathering nodes - Trees (5)
    "ash_wood": {
        "type": "node",
        "file": "assets/art/nodes/ash_wood.png",
        "name": "Ash Tree Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (ash-covered soil and stones) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Ash tree woodcutting node. Whole small gnarled ash tree with a twisted pale grey-white bark trunk and branches, "
            "sparse delicate ashen grey foliage leaves, sitting on a small isolated circular mound of earth dusted with powdery pale grey ash. "
            "Inked outlines, dark fantasy painterly style. Colours strictly: ash grey, pale bone white, weathered stone grey, charcoal."
        )
    },
    "oak_wood": {
        "type": "node",
        "file": "assets/art/nodes/oak_wood.png",
        "name": "Black Oak Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (dark loam soil and moss) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Black oak woodcutting node. Thick gnarled very dark brown ancient trunk with heavy muscular bark ridges, "
            "dense dark forest-green canopy crown, powerful thick roots sprawling over a small patch of mossy dark forest loam ground. "
            "Bold inked outlines, dark fantasy style. Colours strictly: very dark timber brown, deep dark green, moss green, earthy loam."
        )
    },
    "yew_wood": {
        "type": "node",
        "file": "assets/art/nodes/yew_wood.png",
        "name": "Yew of the Dead Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (graveyard soil and dead grass) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Yew of the dead woodcutting node. Ancient twisted reddish-brown trunk with fluted fibrous bark, dense dark green yew needle crown "
            "dotted with small bright red poisonous berries. A small leaning cracked old weathered stone gravestone nestled at its foot among tangled roots. "
            "Inked outlines, grim souls-like cemetery mood. Colours strictly: reddish-brown trunk, dark needle green, bright red berries, mossy tombstone grey."
        )
    },
    "storm_resin": {
        "type": "node",
        "file": "assets/art/nodes/storm_resin.png",
        "name": "Storm Pine Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (scorched pine needles and rock) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Storm pine woodcutting node. Tall weathered mountain pine split down the middle by a lightning strike, "
            "thick golden-amber resin dripping and glowing from the deep burned fissure crack, faint delicate blue electric sparks dancing along the scorched black scar. "
            "Dark needle branches, sitting on a small patch of stony earth. "
            "Colours strictly: charred black bark, golden-amber resin, electric pale blue sparks, pine green, rocky grey. Bold inked outlines."
        )
    },
    "ebony_wood": {
        "type": "node",
        "file": "assets/art/nodes/ebony_wood.png",
        "name": "Twilight Ebony Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (dark violet-tinted stone soil) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Twilight ebony woodcutting node. Smooth elegant jet-black tree trunk with subtle wood grain, dark crown with purple-violet dusk twilight lighting "
            "illuminating the leaf edges, tiny ethereal glowing pale-violet motes of dust drifting gently around the canopy. "
            "Sitting on a small circular patch of dark rock. "
            "Colours strictly: jet-black, deep dusk purple, soft violet glow, dark obsidian earth. Bold inked outlines."
        )
    },

    # Part 2: Gathering nodes - Ores (9)
    "coal": {
        "type": "node",
        "file": "assets/art/nodes/coal.png",
        "name": "Coal Seam Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (rock and rubble) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Coal seam mining node. A rugged rock outcrop of matte dark grey slate rock embedded with jagged chunks of shiny jet-black coal, "
            "a dusting of fine black coal powder and small crushed coal chips scattered around the base on a small patch of grey quarry ground. "
            "Bold inked outlines, crisp rock facets. Colours strictly: dark slate grey, glossy pitch black, charcoal dust."
        )
    },
    "iron_ore": {
        "type": "node",
        "file": "assets/art/nodes/iron_ore.png",
        "name": "Iron Vein Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (rock and rocky dirt) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Iron vein mining node. A rugged dark fantasy rock outcrop with the raw iron vein heavily exposed and protruding: "
            "rough textured grey-brown bedrock embedded with thick bands of reddish-brown raw iron ore deposits and streaks of dull metallic silver-grey iron. "
            "Sitting on a small mound of stony gravel. "
            "Inked black outlines, faceted stone surfaces. Colours strictly: grey-brown rock, rusty reddish-brown, dull silver iron, gravel."
        )
    },
    "copper_ore": {
        "type": "node",
        "file": "assets/art/nodes/copper_ore.png",
        "name": "Copper Vein Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (rocky dirt) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Copper vein mining node. A rugged grey stone rock outcrop with thick veins and metallic nuggets of bright fiery orange-bronze raw copper metal exposed, "
            "accented by several small spots and patches of turquoise-green oxidized verdigris patina along the stone seams. "
            "Sitting on a small patch of rocky earth. "
            "Inked outlines, painterly mineral facets. Colours strictly: neutral stone grey, bright fiery orange copper, turquoise verdigris patina."
        )
    },
    "moon_silver": {
        "type": "node",
        "file": "assets/art/nodes/moon_silver.png",
        "name": "Moon Silver Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (dark cavern rock) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Moon silver mining node. Bluish-grey cavern rock formation with bright pale silver-blue crystals and veins glowing softly with an ethereal moonlight luminescence. "
            "Geometric crystalline clusters erupting from the dark rock, sitting on a small mound of cave bedrock. "
            "Inked outlines, luminous painterly highlights. Colours strictly: dark blue-grey rock, radiant pale silver-blue crystals, soft cyan-silver glow."
        )
    },
    "gold_ore": {
        "type": "node",
        "file": "assets/art/nodes/gold_ore.png",
        "name": "Cathedral Gold Vein Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (cathedral flagstone and pale rock) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Cathedral gold vein mining node. Ancient pale limestone bedrock outcrop embedded with thick, lustrous veins and heavy nuggets of gleaming raw cathedral gold. "
            "Beside the outcrop lies a weathered fallen carved cathedral stone fragment (ornate gothic relief chunk) half-buried in the pale stone rubble. "
            "Inked outlines, opulent medieval relic feel. Colours strictly: pale limestone, radiant rich yellow gold, worn gothic stone grey."
        )
    },
    "ember_ore": {
        "type": "node",
        "file": "assets/art/nodes/ember_ore.png",
        "name": "Ember Vein Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (volcanic ash and basalt) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Ember vein mining node. Jagged black porous volcanic basalt rock outcrop split by intensely glowing molten orange-red fire cracks, "
            "molten lava veins pulsing within the fissures, and tiny hot red ember motes drifting upwards from the stone. "
            "Sitting on a small circular patch of dark volcanic slag and black ash. "
            "Inked outlines, incandescent souls-like flame glow. Colours strictly: pitch-black basalt, glowing molten orange-red, incandescent yellow sparks, ash grey."
        )
    },
    "star_ore": {
        "type": "node",
        "file": "assets/art/nodes/star_ore.png",
        "name": "Fallen Star Ore Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (small impact crater rim) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Fallen star ore mining node. A meteorite stone resting in a small raised impact crater rim: deep cosmic midnight-blue metallic meteorite rock "
            "dusted with tiny sparkling white star-like specks, radiating a faint cold celestial blue-white inner glow. "
            "Sitting on a small circular patch of fused glassy impact crater earth. "
            "Inked outlines, cosmic celestial fantasy style. Colours strictly: deep midnight blue, astral white specks, cold faint blue glow, charcoal crater rim."
        )
    },
    "abyss_geode": {
        "type": "node",
        "file": "assets/art/nodes/abyss_geode.png",
        "name": "Abyss Geode Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (corrupted dark stone) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Abyss geode mining node. A large ancient stone geode cracked open on one side: rough weathered dark rocky outer shell, "
            "the hollow hollow cavity packed with razor-sharp deep purple-black crystalline amethyst spears with a pulsing eerie dark violet glow. "
            "Sitting on a small mound of cracked cavern ground. "
            "Inked outlines, dark void fantasy style. Colours strictly: rough dark slate shell, deep royal purple-black crystals, soft eerie violet glow."
        )
    },
    "living_obsidian": {
        "type": "node",
        "file": "assets/art/nodes/living_obsidian.png",
        "name": "Living Obsidian Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (glassy volcanic shards) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Living obsidian mining node. Clusters of glossy razor-sharp pitch-black obsidian spikes and volcanic glass spires jutting from a rock base, "
            "with a slow-moving organic deep red-orange light pulsing softly inside the translucent black glass as if the mineral were breathing with a heart. "
            "Sitting on a small mound of black volcanic glass shards. "
            "Inked outlines, menacing dark fantasy style. Colours strictly: glossy mirror-like pitch black, pulsing internal blood-orange/crimson light, charcoal base."
        )
    }
}

# 5. Gemini API Call
def generate_raw_image(item_id, item_info, max_retries=3):
    parts = []
    
    # Add style references
    for ref in CACHED_REFS:
        parts.append({"text": f"Style Reference ({ref['name']}): Match this dark fantasy inking and painterly shading style:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
        
    full_prompt = (
        f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
        f"SUBJECT: {item_info['name']}\n"
        f"{item_info['framing']}\n"
        f"DETAILS: {item_info['desc']}"
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
            if hasattr(e, "read"):
                try:
                    err_msg = e.read().decode("utf-8")
                    print(f"[{item_id}] Attempt {attempt+1} error detail: {err_msg}")
                except Exception:
                    pass
            print(f"[{item_id}] Attempt {attempt+1} failed: {e}")
            time.sleep(3)
            
    return None, full_prompt, max_retries

# 6. Cutout and Processing
def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def count_pink_pixels(img_rgba, bgc=np.array([255.0, 0.0, 255.0])):
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    h = hue(ar[..., :3])
    dh = np.abs(((h - hue(bgc)) + 180) % 360 - 180)
    chroma = ar[..., :3].max(-1) - ar[..., :3].min(-1)
    
    # Pink fringe condition: high alpha, hue close to magenta, high chroma, red > green and blue > green
    pink = (a > 20) & (dh < 24) & (chroma > 80) & (r > g + 40) & (b > g + 20)
    return int(pink.sum())

def process_cutout(raw_path, item_type="node", target_size=512):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.asarray(im_pil, dtype=float)
    H, W, _ = im.shape
    
    # Background color from perimeter median
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
    
    # Background detection (strictly magenta)
    bgish = (dh < 30) & (sat > 0.22) & (r > 120) & (b > 65) & (g < 110)
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    # Enclosed background pockets (even tiny holes >= 2 px)
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                if np.abs(m_color - bgc).max() < 50 and m_color[2] > 60 and m_color[0] > 110:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # Remove pink fringe / halo along outer edges (up to 5 passes)
    for _ in range(5):
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
        
    # Despill: neutralise any leftover pink tint on outer 2px boundary
    im_clean = im.copy()
    for _ in range(2):
        edge_outer = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_pinkish = edge_outer & (dh < 40) & (im_clean[..., 0] > im_clean[..., 1] + 8) & (im_clean[..., 2] > im_clean[..., 1] + 5)
        im_clean[edge_pinkish, 0] = np.minimum(im_clean[edge_pinkish, 0], im_clean[edge_pinkish, 1] + 5)
        im_clean[edge_pinkish, 2] = np.minimum(im_clean[edge_pinkish, 2], im_clean[edge_pinkish, 1] + 5)
    
    alpha = np.where(obj, 255.0, 0.0)
    
    # Bounding box
    ys, xs = np.nonzero(obj)
    if len(ys) == 0:
        raise ValueError(f"No object found in {raw_path}")
        
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_crop = im_clean[y0:y1, x0:x1]
    alpha_crop = alpha[y0:y1, x0:x1]
    
    rgba_crop = np.dstack([obj_crop.astype(np.uint8), alpha_crop.astype(np.uint8)])
    crop_img = Image.fromarray(rgba_crop, "RGBA")
    
    obj_w, obj_h = crop_img.size
    
    final_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    if item_type == "npc":
        # Merchant bust: shoulders fill width (~94%), head in upper half, anchored at bottom edge
        target_w = int(round(target_size * 0.94))
        scale = target_w / float(obj_w)
        new_w = target_w
        new_h = int(round(obj_h * scale))
        if new_h > target_size:
            scale = target_size / float(obj_h)
            new_h = target_size
            new_w = int(round(obj_w * scale))
            
        resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        paste_x = (target_size - new_w) // 2
        paste_y = target_size - new_h  # Anchor cleanly to the bottom edge
        final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
    else:
        # Gathering node: fill ~85% of canvas, perfectly centered
        max_dim = max(obj_w, obj_h)
        target_obj_dim = int(round(target_size * 0.85))
        scale = target_obj_dim / float(max_dim)
        new_w = max(1, int(round(obj_w * scale)))
        new_h = max(1, int(round(obj_h * scale)))
        
        resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        paste_x = (target_size - new_w) // 2
        paste_y = (target_size - new_h) // 2
        final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
        
    # Rigorous pink pixels verification and automatic despill cleanup
    pk = count_pink_pixels(final_canvas)
    if pk > 0:
        arr_fin = np.asarray(final_canvas).copy().astype(float)
        r_f, g_f, b_f, a_f = arr_fin[..., 0], arr_fin[..., 1], arr_fin[..., 2], arr_fin[..., 3]
        h_f = hue(arr_fin[..., :3])
        dh_f = np.abs(((h_f - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
        chroma_f = arr_fin[..., :3].max(-1) - arr_fin[..., :3].min(-1)
        pink_mask = (a_f > 20) & (dh_f < 24) & (chroma_f > 80) & (r_f > g_f + 40) & (b_f > g_f + 20)
        
        # Shift red down so r_f <= g_f + 15, keeping rich deep indigo/violet/neutral tones
        arr_fin[pink_mask, 0] = np.maximum(0, arr_fin[pink_mask, 1] + 15)
        arr_fin[pink_mask, 2] = np.clip(arr_fin[pink_mask, 2] * 1.05, 0, 255)
        final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
        pk = count_pink_pixels(final_canvas)
        
    return final_canvas, pk

# 7. Check Sheet Builder
def build_check_sheet():
    # 18 items: 3 rows of 6, or 2 rows of 9. Let's do 3 rows of 6 (canvas size 6*512 = 3072 wide, 3*512 = 1536 high)
    # Background: flat mid-green #00A859 (0, 168, 89)
    cols = 6
    rows = 3
    thumb_size = 512
    sheet = Image.new("RGB", (cols * thumb_size, rows * thumb_size), (0, 168, 89))
    
    order = [
        # Row 1: 4 merchants + 2 trees
        "general_store", "smith", "hunter", "mage", "ash_wood", "oak_wood",
        # Row 2: 3 trees + 3 ores
        "yew_wood", "storm_resin", "ebony_wood", "coal", "iron_ore", "copper_ore",
        # Row 3: 6 ores
        "moon_silver", "gold_ore", "ember_ore", "star_ore", "abyss_geode", "living_obsidian"
    ]
    
    placed = 0
    for idx, item_id in enumerate(order):
        info = ITEMS.get(item_id)
        if not info:
            continue
        out_p = os.path.join(REPO_DIR, info["file"])
        if os.path.exists(out_p):
            im = Image.open(out_p).convert("RGBA")
            c = idx % cols
            r = idx // cols
            sheet.paste(im, (c * thumb_size, r * thumb_size), im)
            placed += 1
            
    sheet.save(IRON_CHECK, format="PNG")
    sheet.save(ROOT_CHECK, format="PNG")
    print(f"Check sheet saved ({placed}/18 items) to {IRON_CHECK} and {ROOT_CHECK}")
    return placed

# 8. Manifest Update
def update_manifests(records):
    # Update assets/art/manifest.json (array)
    existing_list = []
    if os.path.exists(MANIFEST_ART):
        try:
            with open(MANIFEST_ART, "r", encoding="utf-8") as f:
                existing_list = json.load(f)
        except Exception:
            existing_list = []
            
    # Index by id
    art_map = {item.get("id"): item for item in existing_list if isinstance(item, dict) and "id" in item}
    for r in records:
        art_map[r["id"]] = r
    new_art_list = list(art_map.values())
    with open(MANIFEST_ART, "w", encoding="utf-8") as f:
        json.dump(new_art_list, f, indent=2)
    print(f"Updated {MANIFEST_ART} (total entries: {len(new_art_list)})")
    
    # Update root manifest.json (dict)
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

def run_items(id_list):
    records = []
    for tid in id_list:
        info = ITEMS[tid]
        out_p = os.path.join(REPO_DIR, info["file"])
        raw_p = os.path.join(RAW_DIR, f"{tid}.png")
        
        # Check if already generated raw
        if os.path.exists(raw_p):
            print(f"[{tid}] Using existing raw: {raw_p}")
            attempts = 1
            prompt = (
                f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
                f"SUBJECT: {info['name']}\n"
                f"{info['framing']}\n"
                f"DETAILS: {info['desc']}"
            )
        else:
            raw_p, prompt, attempts = generate_raw_image(tid, info)
            if not raw_p:
                print(f"Failed to generate {tid}!")
                continue
                
        os.makedirs(os.path.dirname(out_p), exist_ok=True)
        cutout_img, pk = process_cutout(raw_p, item_type=info["type"])
        cutout_img.save(out_p, format="PNG")
        print(f"Delivered {tid} -> {out_p} (pink_pixels={pk})")
        records.append({
            "id": tid,
            "file": info["file"],
            "type": "cutout",
            "size": 512,
            "prompt": prompt,
            "references": [ref["name"] for ref in CACHED_REFS],
            "attempts": attempts,
            "pink_pixels": pk,
            "status": "done"
        })
    update_manifests(records)
    build_check_sheet()
    return records

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "test"
    print(f"Running generate_art_batch.py in mode: {mode}")
    
    if mode == "test":
        run_items(["smith", "ash_wood", "iron_ore"])
        print("Test phase complete!")
    elif mode == "merchants":
        run_items(["general_store", "hunter", "mage"])
    elif mode == "trees":
        run_items(["oak_wood", "yew_wood", "storm_resin", "ebony_wood"])
    elif mode == "ores":
        run_items(["coal", "copper_ore", "moon_silver", "gold_ore", "ember_ore", "star_ore", "abyss_geode", "living_obsidian"])
    elif mode == "all_merchants":
        run_items(["general_store", "smith", "hunter", "mage"])
    elif mode == "all_nodes":
        run_items([
            "ash_wood", "oak_wood", "yew_wood", "storm_resin", "ebony_wood",
            "coal", "iron_ore", "copper_ore", "moon_silver", "gold_ore",
            "ember_ore", "star_ore", "abyss_geode", "living_obsidian"
        ])
    elif mode == "check":
        build_check_sheet()
    else:
        print(f"Unknown mode: {mode}")
