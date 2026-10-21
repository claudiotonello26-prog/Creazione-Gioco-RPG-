"""Generate Style-Aligned Hero Bases for 'Gym Oath'.
- 2D Dark Fantasy Comic Inked style (Broken Monk, Fallen Knight, Cinder Boss).
- Heavy black ink lines & cel-shading.
- Natural athletic build: defined and toned, but natural shoulder width (NOT bulky/bodybuilder).
- Natural cloth drape: linen shirt has natural fabric wrinkles and drape (NOT shrink-wrapped/vacuum-sealed onto abdominal cubes).
"""

import base64
import json
import os
import sys
import time
import urllib.request
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_DIR = os.path.dirname(PIPELINE_DIR)
REF_DIR = os.path.join(PIPELINE_DIR, 'references')
BASES_DIR = os.path.join(PIPELINE_DIR, 'current_bases')
OUTPUT_DIR = os.path.join(PIPELINE_DIR, 'new_bases')
os.makedirs(OUTPUT_DIR, exist_ok=True)

sys.path.append(SCRIPT_DIR)
from chroma_processor import clean_chroma

GEMINI_KEY = os.environ.get('GEMINI_API_KEY')
if not GEMINI_KEY:
    env_path = os.path.join(PIPELINE_DIR, '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('GEMINI_API_KEY='):
                    GEMINI_KEY = line.strip().split('=', 1)[1]
                    break

API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent'

def load_b64(path):
    with open(path, 'rb') as f:
        return base64.b64encode(f.read()).decode('utf-8')

REF_BOSS = os.path.join(REF_DIR, 'ref_cinder_boss.jpg')
REF_KNIGHT = os.path.join(REF_DIR, 'ref_fallen_knight.png')
REF_MONK = os.path.join(REPO_DIR, 'assets', 'art', 'enemies', 'broken_monk_idle.png')
REF_OLD_MALE = os.path.join(REF_DIR, 'ref_old_male_base.png')
REF_OLD_FEMALE = os.path.join(REF_DIR, 'ref_old_female_base.png')

B64_BOSS = load_b64(REF_BOSS)
B64_KNIGHT = load_b64(REF_KNIGHT)
B64_MONK = load_b64(REF_MONK) if os.path.exists(REF_MONK) else None
B64_OLD_MALE = load_b64(REF_OLD_MALE) if os.path.exists(REF_OLD_MALE) else None
B64_OLD_FEMALE = load_b64(REF_OLD_FEMALE) if os.path.exists(REF_OLD_FEMALE) else None

def call_gemini_image(parts, max_retries=3):
    if not GEMINI_KEY:
        raise ValueError("GEMINI_API_KEY not found!")
    payload = {'contents': [{'parts': parts}]}
    headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_KEY
    }
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode('utf-8'), headers=headers)
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                for part in data['candidates'][0]['content']['parts']:
                    if 'inlineData' in part:
                        return base64.b64decode(part['inlineData']['data'])
        except Exception as e:
            print(f"Attempt {attempt+1} failed: {e}")
            time.sleep(3)
    return None

STYLE_INSTRUCTIONS = """CRITICAL ART STYLE DIRECTIVE FOR 'GYM OATH':
You are the lead concept artist for 'Gym Oath', a 2D Dark Fantasy Medieval Fitness RPG.
You MUST strictly match the art style of the attached reference images:
- ART MEDIUM: 2D stylized dark fantasy graphic novel / comic book character art (like Darkest Dungeon, Hades, Castlevania).
- INKING & LINEWORK: Bold, heavy, expressive black ink contour lines surrounding the entire silhouette, plus distinct black ink lines inside defining the facial features (eyes, nose, mouth, jawline), cloth folds, and boots. Sharp, crisp, visible black ink pen strokes everywhere.
- COLORING: Rich, gritty cel-shading with clear graphic block shadows. Deep charcoal shadow tones (#0D0B09) and warm antique gold / amber rim highlights (#C9A24A).
- ABSOLUTELY FORBIDDEN: NO 3D CGI airbrushing. NO smooth blended photorealistic skin."""

def generate_male_hero():
    prompt = f"""{STYLE_INSTRUCTIONS}

Reference 1 (Broken Monk) demonstrates the EXACT inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic you must follow.
Reference 2 shows the silhouette, narrow natural shoulder proportions, and lean athletic pose of the character.

TASK:
Generate the definitive NATURAL ATHLETIC MALE HERO BASE character sprite for 'Gym Oath'.
- SUBJECT: Full-body standing illustration of an athletic, lean, agile young male swordsman / knight in training.
- POSE: Confident, poised, heroic upright combat-ready 3/4 pose facing slightly left. Both feet firmly planted, arms naturally at sides with relaxed fists. Centered on the canvas.
- ANATOMY & PHYSIQUE:
  * "Fisico atletico normale, definito ma NON grosso di spalle".
  * Normal, natural shoulder width (approx 2 head widths). NOT broad, NO bulky cannonball deltoids, NO thick traps.
  * Lean, toned athletic build (agile swordsman / scout). Toned core and V-taper.
  * Arms: Toned, lean, defined forearms and biceps with crisp black ink contour lines, but slim and agile.
- CLOTHING & FABRIC DRAPE (CRITICAL):
  * Shirt: Coarse natural unbleached linen shirt with open V-neck lace-up collar, sleeves rolled up to forearms.
  * DRAPE: The shirt must drape NATURALLY like real linen fabric, with realistic inked cloth folds and wrinkles. It should NOT be shrink-wrapped or vacuum-sealed onto abdominal muscles; the athletic shape is evident from his slender V-taper frame, but individual six-pack cubes are NOT printed onto the cloth.
  * Trousers: Tough worn brown leather pants fitted on slim athletic legs with inked seam lines.
  * Gloves: Dark brown leather work bracers / gloves.
  * Boots: Sturdy cuffed medieval traveling boots in dark weathered brown leather.
- HEAD & FACE: Short buzzed hair / closely shaved scalp silhouette (clean template for modular wigs/helmets). Handsome, determined, noble young warrior expression. Eyes, nose, lips, cheekbones, and jawline sharply outlined in crisp black ink strokes, matching the dark fantasy comic style of the references.
- BACKGROUND: Flat, solid, pure uniform #FF00FF magenta background (for automated chroma key extraction). Full figure fully visible from head to toe with margin.
"""
    parts = []
    if B64_MONK:
        parts.append({'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}})
    else:
        parts.append({'inlineData': {'mimeType': 'image/jpeg', 'data': B64_BOSS}})
    if B64_OLD_MALE:
        parts.append({'inlineData': {'mimeType': 'image/png', 'data': B64_OLD_MALE}})
    parts.append({'text': prompt})

    print("Generating Refined Natural Athletic Male Hero Base (Natural Shirt Drape)...")
    img_bytes = call_gemini_image(parts)
    if img_bytes:
        raw_path = os.path.join(OUTPUT_DIR, 'new_hero_male_raw.png')
        with open(raw_path, 'wb') as f:
            f.write(img_bytes)
        print(f"Saved raw image to {raw_path}")
        clean_img = clean_chroma(raw_path)
        clean_path = os.path.join(OUTPUT_DIR, 'new_hero_male_base.png')
        clean_img.save(clean_path)
        print(f"Saved cut-out base to {clean_path}")
        return clean_path
    return None

def generate_female_hero():
    prompt = f"""{STYLE_INSTRUCTIONS}

Reference 1 (Broken Monk) demonstrates the EXACT inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic you must follow.
Reference 2 shows the silhouette, narrow natural shoulder proportions, and lean athletic pose of the character.

TASK:
Generate the definitive NATURAL ATHLETIC FEMALE HERO BASE character sprite for 'Gym Oath'.
- SUBJECT: Full-body standing illustration of an athletic, agile, heroic female paladin / shieldmaiden.
- POSE: Proud, poised, agile upright combat-ready 3/4 pose facing slightly left, matching the male hero's height and stance. Both feet firmly planted, arms naturally at sides. Centered on the canvas.
- ANATOMY & PHYSIQUE:
  * "Fisico atletico normale, proporzionato e armonioso, spalle naturali NON troppo larghe o da bodybuilder".
  * Naturally slender, toned, agile Amazonian warrior build. Realistic, graceful athletic proportions.
  * Arms: Toned, sleek athletic arms with crisp black ink contour lines, but feminine and agile.
- CLOTHING & FABRIC DRAPE (CRITICAL):
  * Shirt/Tunic: Coarse natural unbleached linen tunic with V-neck collar, short sleeves, belted with a slender leather belt at the waist.
  * DRAPE: The linen fabric must drape NATURALLY with realistic inked cloth folds and wrinkles. It should NOT be shrink-wrapped or vacuum-sealed onto abdominal muscles.
  * Trousers: Tough worn brown leather pants fitted on athletic, toned legs with inked seam lines.
  * Gloves: Dark brown leather work bracers / gloves.
  * Boots: Sturdy cuffed medieval traveling boots in dark weathered brown leather.
- HEAD & FACE: Short buzzed hair / closely shaved scalp silhouette (clean template for modular wigs/helmets). Fierce, beautiful, determined warrior expression with piercing focused eyes. Eyes, nose, lips, cheekbones, and jawline sharply outlined in crisp black ink strokes, matching the dark fantasy comic style of the references.
- BACKGROUND: Flat, solid, pure uniform #FF00FF magenta background (for automated chroma key extraction). Full figure fully visible from head to toe with margin.
"""
    parts = []
    if B64_MONK:
        parts.append({'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}})
    else:
        parts.append({'inlineData': {'mimeType': 'image/jpeg', 'data': B64_BOSS}})
    if B64_OLD_FEMALE:
        parts.append({'inlineData': {'mimeType': 'image/png', 'data': B64_OLD_FEMALE}})
    parts.append({'text': prompt})

    print("Generating Refined Natural Athletic Female Hero Base (Natural Shoulders & Drape)...")
    img_bytes = call_gemini_image(parts)
    if img_bytes:
        raw_path = os.path.join(OUTPUT_DIR, 'new_hero_female_raw.png')
        with open(raw_path, 'wb') as f:
            f.write(img_bytes)
        print(f"Saved raw image to {raw_path}")
        clean_img = clean_chroma(raw_path)
        clean_path = os.path.join(OUTPUT_DIR, 'new_hero_female_base.png')
        clean_img.save(clean_path)
        print(f"Saved cut-out base to {clean_path}")
        return clean_path
    return None

if __name__ == '__main__':
    target = sys.argv[1].lower() if len(sys.argv) > 1 else 'all'
    if target in ['male', 'all']:
        generate_male_hero()
    if target in ['female', 'all']:
        generate_female_hero()
