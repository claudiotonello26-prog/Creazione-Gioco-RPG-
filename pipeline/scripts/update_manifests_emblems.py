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
    "- Background OUTSIDE the circular medallion: pure flat solid black #000000 filling the entire canvas outside the circle.\n"
    "- Medallion rim: thick round rim of dark worn metal with small rivets or simple carved runes, matching the format reference.\n"
    "- DEDICATED COLORED BACKGROUND: Inside the circular rim, the background field behind the central symbol is bathed in a rich, luminous, moody atmospheric wash of the station's accent colour.\n"
    "- Central symbol: ONE bold central symbol of the station, big and simple, with strong graphic contrast between the pale/dark symbol and the luminous colored background field.\n"
    "- Lighting strictly from the upper left.\n"
    "- Inked outlines, hand-painted dark fantasy souls-like feel, strong bold icon readability.\n"
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
            "- A circular worn dark metal medallion seal with a thick circular rim of dark pitted iron and simple carved runes.\n"
            "- Dedicated colored background: rich warm orange atmospheric wash filling the inner circular field behind the tools.\n"
            "- Central symbol: A traditional carpenter's hand saw crossed with a heavy woodworking axe over a cut tree log round ring (growth rings clearly visible).\n"
            "- Saw teeth and log rings catch warm orange light, curled wood shavings near the rim.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
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
            "- A circular worn dark metal medallion seal with a thick circular rim of dark iron and small rivets.\n"
            "- Dedicated colored background: rich glowing molten red firelight haze and smoke wash filling the inner circular field behind the furnace and crucible.\n"
            "- Central symbol: A stone smelting furnace mouth (arched opening) with a heavy dark iron crucible tilted and pouring a stream of glowing red molten metal into an ingot mould below.\n"
            "- Molten metal stream, ingot mould fill, and furnace arched mouth interior glow vibrant molten red with tiny rising embers.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
        ),
        "references": [
            "station_carpentry.png",
            "living_bellows_idle.png"
        ],
        "attempts": 2,
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
            "- Dedicated colored background: rich luminous cold steel blue atmospheric quench wash filling the inner circular field behind the anvil and hammer.\n"
            "- Central symbol: A heavy blacksmith anvil seen from the side, smith's hammer raised angled above it, and a sword blade on the anvil with a blue-white glowing hot cutting edge.\n"
            "- Strong silhouette contrast against the cold blue background wash.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
        ),
        "references": [
            "station_carpentry.png",
            "anvil_golem_idle.png"
        ],
        "attempts": 2,
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
            "STATION ACCENT COLOR: Mystic Violet #A77BE0 (mysterious, ethereal magic).\n"
            "DETAILS:\n"
            "- A circular worn dark metal medallion seal with a thick circular rim of dark iron and carved runes.\n"
            "- Dedicated colored background: rich deep mystic violet arcane nebula wash and ethereal magic haze filling the inner circular field.\n"
            "- Central symbol: A straight knight sword pointing vertically upward, its blade passing cleanly through the center of a faceted cut gemstone or rune stone.\n"
            "- Ring of glowing violet runes and four-pointed star sparks around the blade.\n"
            "- Inked outlines, hand-painted dark fantasy souls-like feel."
        ),
        "references": [
            "station_carpentry.png",
            "living_bellows_idle.png"
        ],
        "attempts": 2,
        "status": "done"
    }
]

# Update root manifest.json
with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
    root_dict = json.load(f)

for r in records:
    root_dict[r["id"]] = r

with open(MANIFEST_ROOT, "w", encoding="utf-8") as f:
    json.dump(root_dict, f, indent=2)
print(f"Updated {MANIFEST_ROOT} ({len(root_dict)} entries)")

# Update assets/art/manifest.json
with open(MANIFEST_ART, "r", encoding="utf-8") as f:
    art_list = json.load(f)

art_map = {item.get("id"): item for item in art_list if isinstance(item, dict) and "id" in item}
for r in records:
    art_map[r["id"]] = r

new_art_list = list(art_map.values())
with open(MANIFEST_ART, "w", encoding="utf-8") as f:
    json.dump(new_art_list, f, indent=2)
print(f"Updated {MANIFEST_ART} ({len(new_art_list)} entries)")

# Update iron-oath-art/manifest.json
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
