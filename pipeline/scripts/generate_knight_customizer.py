"""Knight Customizer Generator for 'Gym Oath'.
Calls Google Gemini 2.5 Flash Image API to generate modular customization layers:
- 4 Faces (Male & Female)
- 5 Hairstyles (Male & Female)
- 5 Beards / Mustaches (Male)
- Modular Knight Armor sets
"""

import base64
import json
import os
import sys
import time
import urllib.request
import numpy as np
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_DIR = os.path.dirname(PIPELINE_DIR)
REF_DIR = os.path.join(PIPELINE_DIR, 'references')
BASES_DIR = os.path.join(PIPELINE_DIR, 'current_bases')
OUTPUT_DIR = os.path.join(PIPELINE_DIR, 'output')
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
REF_MALE_BASE = os.path.join(BASES_DIR, 'hero_male_base.png')
REF_FEMALE_BASE = os.path.join(BASES_DIR, 'hero_female_base.png')

B64_BOSS = load_b64(REF_BOSS) if os.path.exists(REF_BOSS) else None
B64_MONK = load_b64(REF_MONK) if os.path.exists(REF_MONK) else B64_BOSS
B64_MALE_BASE = load_b64(REF_MALE_BASE) if os.path.exists(REF_MALE_BASE) else None
B64_FEMALE_BASE = load_b64(REF_FEMALE_BASE) if os.path.exists(REF_FEMALE_BASE) else None

def call_gemini(parts, max_retries=3):
    if not GEMINI_KEY:
        raise ValueError("GEMINI_API_KEY environment variable is not set!")
        
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
            if hasattr(e, 'read'):
                try:
                    print(f"Attempt {attempt+1} error details: {e.read().decode('utf-8')}")
                except Exception:
                    pass
            print(f"Attempt {attempt+1} failed: {e}")
            time.sleep(2)
    return None

STYLE_DIRECTIVE = """CRITICAL ART STYLE & UNIFORMITY DIRECTIVE FOR 'GYM OATH':
You are the lead concept artist for 'Gym Oath', a 2D Dark Fantasy Medieval RPG.
- ART MEDIUM: 2D stylized dark fantasy graphic novel / comic book character art (like Darkest Dungeon, Hades, Castlevania).
- INKING & LINEWORK: Bold, heavy, expressive black ink contour lines surrounding the entire silhouette, plus distinct black ink lines inside defining the facial features, muscles, and hair strands. Sharp, crisp, visible black ink pen strokes everywhere.
- COLORING & PALETTE: Rich cel-shading with clear graphic block shadows. Deep charcoal shadow tones (#0D0B09) and warm antique gold / amber rim highlights (#C9A24A). Same skin tone and lighting as the approved hero base.
- NO 3D CGI airbrushing. NO smooth blended photorealistic skin. 100% unified dark fantasy graphic novel aesthetic."""

def generate_faces(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_BASE if is_male else B64_FEMALE_BASE
    subj = "athletic male knight" if is_male else "sensual athletic female knight"
    gender_rules = (
        "CRITICAL: The 4 male expressions MUST BE DRAMATICALLY AND VISIBLY DIFFERENT FROM EACH OTHER (NOT subtle tweaks! Face 2 and Face 4 must NOT look identical!):\n"
        "- Face 1 (Solare / Sorridente): BIG CONFIDENT HEROIC SMILE SHOWING TEETH, cheerful, warm, charismatic warrior smile with visible teeth, bright eyes.\n"
        "- Face 2 (Fiero / Determinato): COCKY ASYMMETRICAL BATTLE SMIRK (one lip corner curled distinctly up into a proud smirk), one eyebrow arched, sharp confident squint.\n"
        "- Face 3 (Severo / Grintoso): BATTLE FURY WITH CLENCHED TEETH (denti serrati visibili in una smorfia di grinta e furore da battaglia), furrowed intense battle brow, ferocious warrior glare.\n"
        "- Face 4 (Calmo / Nobile): RELAXED NEUTRAL CLOSED LIPS, stoic, serene, calm noble knight composure, steady peaceful noble gaze."
        if is_male else
        "CRITICAL: The 4 female expressions MUST BE DRAMATICALLY AND VISIBLY DIFFERENT FROM EACH OTHER (NOT subtle tweaks!):\n"
        "- Face 1 (Solare / Sorridente): BIG RADIANT SMILE SHOWING TEETH, cheerful, warm, charismatic, eyes crinkled in genuine joy.\n"
        "- Face 2 (Fiera / Determinata): COCKY ASYMMETRICAL BATTLE SMIRK (one lip corner raised), arched eyebrow, piercing confident battle gaze.\n"
        "- Face 3 (Severa / Grintosa): BATTLE FURY WITH CLENCHED TEETH (denti serrati in un ringhio di battaglia), furrowed intense battle brow, deadly ferocious glare.\n"
        "- Face 4 (Calma / Nobile): Relaxed lips, serene, noble, composed paladin gaze."
    )
    
    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved {gender.capitalize()} Hero character head, face, skin tone, and clean shaved scalp template.

TASK:
Generate a character customization sprite sheet showing 4 DISTINCT MODULAR FACE EXPRESSIONS for the {subj} in 'Gym Oath':
Subject: 4 head portraits arranged horizontally side by side in a row on the canvas, facing 3/4 angle slightly right (matching Reference 2).
Clean shaved / buzzed scalp silhouette on all 4 heads (clean template so modular hairstyles can be fitted on top):
{gender_rules}

Composition:
- Horizontal row of 4 distinct heads, clearly spaced with clean margins.
- Identical head size, proportions, and 3/4 angle matching Reference 2 perfectly.
- Thick black ink outlines, expressive comic book linework, cel-shading.
- Isolated on a flat solid pure #FF00FF magenta background (for automated clean chroma key cutout).
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': base_b64}},
        {'text': prompt}
    ]
    
    print(f"Generating 4 Faces for {gender}...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, f'faces_{gender}_raw.png')
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, f'faces_{gender}_clean.png')
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

def generate_hairstyles(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_BASE if is_male else B64_FEMALE_BASE
    
    if is_male:
        styles = """1. Hairstyle 1: Messy, wild, tousled warrior quiff (ciuffo spettinato con ciocche ribelli, NOT neatly combed).
2. Hairstyle 2: Short rugged textured warrior crop (taglio corto pratico da guerriero, spettinato e sfilato).
3. Hairstyle 3: Medium-long loose wavy hair falling naturally down the sides of the face and cheeks down to just above the shoulders (capello medio lungo sciolto che va giù ai lati del viso fino a sopra le spalle, selvaggio e cavalleresco).
4. Hairstyle 4: Warrior topknot / samurai bun with shaved sides.
5. Hairstyle 5: Military textured buzzcut with clean hairline."""
    else:
        styles = """1. Hairstyle 1: High athletic Amazon ponytail with bangs framing the face.
2. Hairstyle 2: Valkyrie side-braid resting over the shoulder.
3. Hairstyle 3: Sleek modern asymmetrical bob with sharp angles.
4. Hairstyle 4: Long wavy flowing paladin locks draped over shoulders.
5. Hairstyle 5: Edgy short pixie cut with swept bangs."""

    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved {gender.capitalize()} Hero character head silhouette and angle.

TASK:
Generate a character customization sprite sheet showing 5 MODULAR HAIRSTYLES for the {gender} hero in 'Gym Oath':
Subject: 5 standalone modular hair pieces (wigs/hairstyles) arranged horizontally side by side in a row on the canvas, facing 3/4 angle matching Reference 2 so each wig fits directly onto the hero's head.
Rich dark brown / chestnut hair color with warm amber highlights, heavy black ink outlines, cel-shaded hair strands:
{styles}

Composition:
- Horizontal row of 5 distinct hairstyles, clearly spaced with clean margins.
- Identical angle and scale matching the hero base head.
- Isolated on a flat solid pure #FF00FF magenta background (for automated clean chroma key cutout).
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': base_b64}},
        {'text': prompt}
    ]
    
    print(f"Generating 5 Hairstyles for {gender}...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, f'hair_{gender}_raw.png')
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, f'hair_{gender}_clean.png')
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

def generate_beards():
    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved Male Hero jawline and face angle.

TASK:
Generate a character customization sprite sheet showing 5 MODULAR FACIAL HAIR STYLES (BEARDS & MUSTACHES) for the male hero in 'Gym Oath':
Subject: 5 standalone modular facial hair pieces arranged horizontally side by side in a row on the canvas, facing 3/4 angle matching the male hero's jawline and mouth.
Dark brown hair matching the hero's palette, crisp dark ink outlines and cel-shading:
1. Beard 1 (Barba Incolta / Stubble): Rugged, heavy 3-to-5-day rough stubble shading across the jaw, chin, cheeks, and upper lip.
2. Beard 2 (Barba Medio-Corta): Neat, short-boxed warrior beard, well-groomed, covering jaw and chin (medio corta).
3. Beard 3 (Baffi a Manubrio & Pizzo): Heroic curled handlebar mustache with a trimmed goatee.
4. Beard 4 (Barba Piena Folta): Thick, rugged, full medieval knight beard covering lower cheeks, jaw, and chin.
5. Beard 5 (Barba Vichinga Intrecciata): Long wild warrior beard braided into a single point with an iron ring bead.

Composition:
- Horizontal row of 5 distinct facial hair styles, clearly spaced with clean margins.
- Identical angle and scale matching the male hero's jaw.
- Isolated on a flat solid pure #FF00FF magenta background (for automated clean chroma key cutout).
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MALE_BASE}},
        {'text': prompt}
    ]
    
    print("Generating 5 Male Beards...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, 'beards_male_raw.png')
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, 'beards_male_clean.png')
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

if __name__ == '__main__':
    target = sys.argv[1].lower() if len(sys.argv) > 1 else 'updates'
    if target == 'male_faces':
        generate_faces('male')
    elif target == 'female_faces':
        generate_faces('female')
    elif target == 'male_hair':
        generate_hairstyles('male')
    elif target == 'custom_updates':
        generate_faces('male')
        generate_hairstyles('male')
    elif target == 'beards':
        generate_beards()
    elif target == 'updates':
        generate_faces('female')
        generate_hairstyles('male')
        generate_beards()
    elif target in ['faces', 'all']:
        generate_faces('male')
        generate_faces('female')
    if target in ['hair', 'all']:
        generate_hairstyles('male')
        generate_hairstyles('female')
    if target in ['beards', 'all']:
        generate_beards()
