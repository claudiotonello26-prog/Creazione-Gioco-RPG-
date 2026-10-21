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
REF_DIR = os.path.join(PIPELINE_DIR, 'references')
BASES_DIR = os.path.join(PIPELINE_DIR, 'current_bases')
OUTPUT_DIR = os.path.join(PIPELINE_DIR, 'output')
os.makedirs(OUTPUT_DIR, exist_ok=True)

sys.path.append(SCRIPT_DIR)
from chroma_processor import clean_chroma

GEMINI_KEY = os.environ.get('GEMINI_API_KEY')
API_URL = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={GEMINI_KEY}'

# Load Reference Images
def load_b64(path):
    with open(path, 'rb') as f:
        return base64.b64encode(f.read()).decode('utf-8')

REF_BOSS = os.path.join(REF_DIR, 'ref_cinder_boss.jpg')
REF_KNIGHT = os.path.join(REF_DIR, 'ref_fallen_knight.png')
REF_MALE_BASE = os.path.join(BASES_DIR, 'hero_male_base.png')
REF_FEMALE_BASE = os.path.join(BASES_DIR, 'hero_female_base.png')

B64_BOSS = load_b64(REF_BOSS)
B64_KNIGHT = load_b64(REF_KNIGHT)
B64_MALE_BASE = load_b64(REF_MALE_BASE)
B64_FEMALE_BASE = load_b64(REF_FEMALE_BASE)

def call_gemini(parts, max_retries=3):
    if not GEMINI_KEY:
        raise ValueError("GEMINI_API_KEY environment variable is not set!")
        
    payload = {'contents': [{'parts': parts}]}
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
    for attempt in range(max_retries):
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                for part in data['candidates'][0]['content']['parts']:
                    if 'inlineData' in part:
                        return base64.b64decode(part['inlineData']['data'])
        except Exception as e:
            print(f"Attempt {attempt+1} failed: {e}")
            time.sleep(2)
    return None

STYLE_DIRECTIVE = '''You are the lead 2D artist for dark fantasy medieval mobile RPG 'Gym Oath'.
Observe the attached reference images with extreme precision:
- ART STYLE: 2D dark fantasy stylized comic / video game character illustration.
- LINEWORK: Thick, crisp, bold black inked outlines around the entire silhouette and interior line work.
- SHADING: Painterly cel-shading with antique gold / amber rim highlights (#C9A24A) and deep charcoal shadows (#0D0B09).
- Clean, readable mobile game design, positive heroic energy. NO 3D CGI airbrushing.'''

def generate_faces(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_BASE if is_male else B64_FEMALE_BASE
    subj = "athletic male knight" if is_male else "athletic female knight"
    
    prompt = f'''{STYLE_DIRECTIVE}

Reference 1 (Fallen Knight) shows the inking and cel-shading style.
Reference 2 shows the exact {subj} character head and jawline to match.

Task:
Generate a character customization sprite sheet showing 4 DISTINCT FACE EXPRESSIONS for this {subj}:
Subject: 4 head portraits arranged horizontally side by side in a row on the canvas, facing 3/4 angle slightly left.
Clean shaved buzzcut scalp silhouette (so modular hairstyles can be equipped on top):
1. Face 1 (Solare / Sorridente): Charismatic, energetic, warm heroic smile showing teeth, bright confident eyes.
2. Face 2 (Fiero / Determinato): Proud battle smirk, focused piercing eyes, confident warrior expression.
3. Face 3 (Severo / Grintoso): Battle grit, clenching jaw with fierce determined battle intensity, sharp focused eyebrows.
4. Face 4 (Calmo / Nobile): Calm, honorable, serene knight composure, steady focused gaze.

Composition: Horizontal row of 4 distinct heads, clearly spaced, identical head size and angle matching Reference 2.
Completely isolated on a flat solid pure #FF00FF magenta background.'''

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_KNIGHT}},
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
        styles = '''1. Hairstyle 1: Short textured warrior pompadour / swept back quiff.
2. Hairstyle 2: Warrior topknot / samurai bun with shaved undercut.
3. Hairstyle 3: Viking braided undercut, hair pulled back into a tight braid.
4. Hairstyle 4: Long wild medium-length warrior locks falling past the ears.
5. Hairstyle 5: Military textured buzzcut / fade with a clean hairline.'''
    else:
        styles = '''1. Hairstyle 1: High athletic ponytail with bangs framing the face.
2. Hairstyle 2: Warrior side-braid (Valkyrie braid) resting over the shoulder.
3. Hairstyle 3: Sleek modern asymmetrical bob with sharp angles.
4. Hairstyle 4: Long wavy flowing paladin locks draped over shoulders.
5. Hairstyle 5: Edgy short pixie cut with swept bangs.'''

    prompt = f'''{STYLE_DIRECTIVE}

Reference 1 (Fallen Knight) shows the inking and cel-shading style.
Reference 2 shows the exact head shape and angle of the hero base to fit.

Task:
Generate a character customization sprite sheet showing 5 MODULAR HAIRSTYLES for the {gender} hero in 'Gym Oath':
Subject: 5 standalone modular hair pieces (wigs/hairstyles) arranged horizontally side by side in a row on the canvas, facing 3/4 angle slightly left to fit the hero's head.
Rich dark brown hair color, clean comic ink outlines, cel-shaded hair strands:
{styles}

Composition: Horizontal row of 5 distinct hairstyles, clearly spaced, identical angle and scale matching the hero base head.
Completely isolated on a flat solid pure #FF00FF magenta background.'''

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_KNIGHT}},
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
    prompt = f'''{STYLE_DIRECTIVE}

Reference 1 (Fallen Knight) shows the inking and cel-shading style.
Reference 2 shows the exact male hero base jawline and face angle.

Task:
Generate a character customization sprite sheet showing 5 MODULAR FACIAL HAIR STYLES (BEARDS & MUSTACHES) for the male hero in 'Gym Oath':
Subject: 5 standalone modular facial hair pieces arranged horizontally side by side in a row on the canvas, facing 3/4 angle slightly left to fit the hero's jawline and mouth.
Dark brown hair matching the hero's palette, crisp dark ink outlines:
1. Beard 1 (Stubble): Rough masculine 3-day stubble along the jaw, chin, and upper lip.
2. Beard 2 (Handlebar): Proud, heroic curled handlebar mustache with a clean-shaven chin.
3. Beard 3 (Goatee): Sharply trimmed goatee and mustache, athletic and charismatic.
4. Beard 4 (Full Warrior Beard): Thick, well-groomed medium-length full knight beard covering chin and jaw.
5. Beard 5 (Viking Braided Beard): Long wild warrior beard braided with iron ring beads at the bottom.

Composition: Horizontal row of 5 distinct facial hair styles, clearly spaced, identical angle and scale matching the male hero's jaw.
Completely isolated on a flat solid pure #FF00FF magenta background.'''

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_KNIGHT}},
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
    print("=== GYM OATH KNIGHT CUSTOMIZER GENERATOR ===")
    print("Usage: Call specific functions or run batch.")
    # Quick test or full run can be invoked by passing args
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == 'faces':
            generate_faces('male')
            generate_faces('female')
        elif cmd == 'hair':
            generate_hairstyles('male')
            generate_hairstyles('female')
        elif cmd == 'beards':
            generate_beards()
        elif cmd == 'all':
            generate_faces('male')
            generate_faces('female')
            generate_hairstyles('male')
            generate_hairstyles('female')
            generate_beards()
    else:
        print("Run with: python generate_knight_customizer.py [all|faces|hair|beards]")
