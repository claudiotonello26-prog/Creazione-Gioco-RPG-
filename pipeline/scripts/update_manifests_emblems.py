import os
import json

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = r"C:\Users\pissio\iron-oath-art\manifest.json"

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

records = [
    {
        "id": "station_carpentry",
        "file": "assets/art/emblems/station_carpentry.png",
        "type": "emblem",
        "size": 512,
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
        "references": [
            "anvil_golem_idle.png",
            "living_bellows_idle.png",
            "station_anvil.png"
        ],
        "attempts": 1,
        "status": "done"
    },
    {
        "id": "station_furnace",
        "file": "assets/art/emblems/station_furnace.png",
        "type": "emblem",
        "size": 512,
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
        "references": [
            "anvil_golem_idle.png",
            "living_bellows_idle.png",
            "station_anvil.png"
        ],
        "attempts": 1,
        "status": "done"
    },
    {
        "id": "station_anvil",
        "file": "assets/art/emblems/station_anvil.png",
        "type": "emblem",
        "size": 512,
        "prompt": (
            f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
            "SUBJECT: Crafting Station Emblem - Anvil (Weapons & Armor Forging)\n"
            "STATION ACCENT COLOR: Cold Steel Blue #6E9BC9 and blue-white glowing light.\n"
            "DETAILS:\n"
            "- A circular forged iron medallion seal with a thick circular rim of dark pitted iron and subtle hammered rivets.\n"
            "- Central symbol: A massive blacksmith anvil seen from the side, with a smith's hammer raised angled above it, "
            "and a sword blade lying horizontally on the anvil with a blue-white hot glowing line along its cutting edge.\n"
            "- Steel parts have cold blue highlights (#6E9BC9). The rest is strictly monochrome dark grey, charcoal, and black.\n"
            "- Soft inner glow in cold steel blue (#6E9BC9) behind and inside the central symbol.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
        ),
        "references": [
            "anvil_golem_idle.png",
            "living_bellows_idle.png"
        ],
        "attempts": 1,
        "status": "done"
    },
    {
        "id": "station_enchant",
        "file": "assets/art/emblems/station_enchant.png",
        "type": "emblem",
        "size": 512,
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
        "references": [
            "anvil_golem_idle.png",
            "living_bellows_idle.png",
            "station_anvil.png"
        ],
        "attempts": 1,
        "status": "done"
    }
]

# 1. Update root manifest.json (dict)
with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
    root_dict = json.load(f)

for r in records:
    root_dict[r["id"]] = r

with open(MANIFEST_ROOT, "w", encoding="utf-8") as f:
    json.dump(root_dict, f, indent=2)
print(f"Updated {MANIFEST_ROOT} ({len(root_dict)} entries)")

# 2. Update assets/art/manifest.json (list)
with open(MANIFEST_ART, "r", encoding="utf-8") as f:
    art_list = json.load(f)

art_map = {item.get("id"): item for item in art_list if isinstance(item, dict) and "id" in item}
for r in records:
    art_map[r["id"]] = r

new_art_list = list(art_map.values())
with open(MANIFEST_ART, "w", encoding="utf-8") as f:
    json.dump(new_art_list, f, indent=2)
print(f"Updated {MANIFEST_ART} ({len(new_art_list)} entries)")

# 3. Update iron-oath-art/manifest.json if exists
if os.path.exists(MANIFEST_IRON):
    with open(MANIFEST_IRON, "r", encoding="utf-8") as f:
        iron_list = json.load(f)
    iron_map = {item.get("id"): item for item in iron_list if isinstance(item, dict) and "id" in item}
    for r in records:
        iron_map[r["id"]] = r
    new_iron_list = list(iron_map.values())
    with open(MANIFEST_IRON, "w", encoding="utf-8") as f:
        json.dump(new_iron_list, f, indent=2)
    print(f"Updated {MANIFEST_IRON} ({len(new_iron_list)} entries)")
