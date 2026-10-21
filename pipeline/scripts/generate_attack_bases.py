"""Generate Attack Bases for 'Gym Oath'.
- 2D Dark Fantasy Comic Inked style (matching Broken Monk, Fallen Knight, Cinder Boss).
- FACING RIGHT: Both heroes stand on the left side of the battle screen, facing towards the RIGHT towards the monster.
- Posture: Athletic combat-ready attack guard (guardia d'attacco pronta al fendente), holding weapon angled towards the right, offhand in defensive guard.
- Male Attack Base: Masculine, athletic natural, focused battle grit, facing right.
- Female Attack Base: Sensual, athletic curves, alluring and deadly, facing right.
- Clean buzzed scalp template for modular hair/helmets.
- Uniform #FF00FF magenta background for automatic clean chroma cutout.
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
REF_MONK = os.path.join(REPO_DIR, 'assets', 'art', 'enemies', 'broken_monk_idle.png')
HERO_MALE_IDLE = os.path.join(BASES_DIR, 'hero_male_base.png')
HERO_FEMALE_IDLE = os.path.join(BASES_DIR, 'hero_female_base.png')
HERO_FEMALE_ATTACK = os.path.join(BASES_DIR, 'hero_female_attack_base.png')

B64_BOSS = load_b64(REF_BOSS) if os.path.exists(REF_BOSS) else None
B64_MONK = load_b64(REF_MONK) if os.path.exists(REF_MONK) else B64_BOSS
B64_MALE_IDLE = load_b64(HERO_MALE_IDLE) if os.path.exists(HERO_MALE_IDLE) else None
B64_FEMALE_IDLE = load_b64(HERO_FEMALE_IDLE) if os.path.exists(HERO_FEMALE_IDLE) else None
B64_FEMALE_ATTACK = load_b64(HERO_FEMALE_ATTACK) if os.path.exists(HERO_FEMALE_ATTACK) else None

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
            if hasattr(e, 'read'):
                try:
                    print(f"Attempt {attempt+1} error details: {e.read().decode('utf-8')}")
                except Exception:
                    pass
            print(f"Attempt {attempt+1} failed: {e}")
            time.sleep(3)
    return None

STYLE_INSTRUCTIONS = """CRITICAL ART STYLE & UNIFORMITY DIRECTIVE FOR 'GYM OATH':
You are the lead concept artist for 'Gym Oath', a 2D Dark Fantasy Medieval RPG.
- UNIFORM ART STYLE: The Male Hero and Female Hero MUST look like they were drawn by the EXACT SAME comic book artist in the EXACT SAME dark fantasy graphic novel style. Identical line weights, identical inking pen strokes, identical rendering technique.
- ART MEDIUM: 2D stylized dark fantasy graphic novel / comic book character art (like Darkest Dungeon, Hades, Castlevania).
- INKING & LINEWORK: Bold, heavy, expressive black ink contour lines surrounding the entire silhouette, plus distinct black ink lines inside defining the facial features, muscles, and cloth folds. Sharp, crisp, visible black ink pen strokes everywhere.
- COLORING & PALETTE: Rich cel-shading with clear graphic block shadows. Deep charcoal shadow tones (#0D0B09) and warm antique gold / amber rim highlights (#C9A24A). Same warm unbleached linen fabric for shirts, same dark brown leather for pants, gloves, and boots.
- NO 3D CGI airbrushing. NO smooth blended photorealistic skin. NO anime/manga deviations. 100% unified western dark fantasy comic aesthetic."""

def generate_male_attack():
    prompt = f"""{STYLE_INSTRUCTIONS}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved Male Hero — notice his MASCULINE FLAT CHEST, HENLEY SHIRT WITH LACES, and LEAN NATURAL ATHLETIC ARMS and SHOULDERS.

TASK:
Generate the definitive COMBAT READY ATTACK GUARD POSE MALE HERO BASE character sprite for 'Gym Oath'.

GENDER & ANATOMY (STRICTLY MASCULINE & NATURAL ATHLETIC):
- SUBJECT: Masculine young male swordsman. Flat masculine muscular chest, broad square male jawline, masculine neck.
- CRITICAL ARMS & SHOULDERS: "Fisico atletico normale, definito ma NON grosso".
  * The arms MUST BE LEAN, AGILE, AND NATURAL — NOT A BULKY SUPERHERO, NOT A BODYBUILDER!
  * Normal, realistic human arm thickness (matching Reference 2 exactly).
  * ABSOLUTELY FORBIDDEN: NO oversized bulging bicep balls, NO swollen superhero Popeye forearms, NO cannonball deltoids.
  * Lean, sinewy, toned swordsman arms.

CRITICAL ORIENTATION & DIRECTION:
- The hero stands on the LEFT side of the screen fighting a monster on the RIGHT side.
- Therefore, the hero MUST BE TURNED AND FACING TOWARDS THE RIGHT (3/4 view facing towards the right side of the canvas).
- Head, chest, and battle gaze are turned towards the RIGHT, locking eyes with the monster on the right.

POSE & COMBAT GUARD (POSTURA D'ATTACCO PRONTA AL FENDENTE A DUE MANI):
- Agile martial combat ready stance:
  * Knees bent, feet firmly planted in an athletic stance ready to advance towards the right.
  * TWO-HANDED SWORD GRIP: Both hands gripping the hilt of a medieval steel arming sword together in front of the chest in a focused two-handed attack guard.
  * The sword blade extends forward/upward angled towards the right enemy, ready to unleash a strike.
  * Left forearm and hand are in forward guard on the hilt (ready for a shield overlay or two-handed weapon).
  * Standard medieval steel arming sword / longsword (clean steel blade, sharp black ink contours, NO glow, NO blur).
- Expression: Masculine, determined warrior grimace with battle grit, eyes locked on the enemy to the right.

CLOTHING:
- Shirt: Coarse natural unbleached linen shirt with laced V-neck collar (identical to Reference 2, NOT open cleavage), natural cloth wrinkles, rolled sleeves.
- Trousers: Tough brown leather pants.
- Gloves: Dark brown leather gauntlets gripping the hilt.
- Boots: Dark brown cuffed traveling boots.
- Head: Short buzzed hair / closely shaved scalp silhouette.
- Background: Flat, solid, pure uniform #FF00FF magenta background (for automated clean chroma key extraction). Full figure fully visible on canvas with margins.
"""
    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MALE_IDLE}},
        {'text': prompt}
    ]

    print("Generating Male Hero Combat Ready Attack Guard (Facing Right, Two-Handed Grip)...")
    img_bytes = call_gemini_image(parts)
    if img_bytes:
        raw_path = os.path.join(OUTPUT_DIR, 'hero_male_attack_raw.png')
        with open(raw_path, 'wb') as f:
            f.write(img_bytes)
        print(f"Saved raw image to {raw_path}")
        clean_img = clean_chroma(raw_path)
        clean_path = os.path.join(OUTPUT_DIR, 'hero_male_attack_base.png')
        clean_img.save(clean_path)
        print(f"Saved cut-out attack base to {clean_path}")
        return clean_path
    return None

def generate_female_attack():
    prompt = f"""{STYLE_INSTRUCTIONS}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved Female Hero character head, face, and sensual athletic build in idle pose.
Reference 3 shows the Male Hero Base — the art style, line weight, inking technique, shading, and texture of the female MUST MATCH THIS REFERENCE 100% UNIFORMLY.

TASK:
Generate the definitive SENSUAL COMBAT READY ATTACK GUARD POSE FEMALE HERO BASE character sprite for 'Gym Oath'.

CRITICAL STYLE UNIFORMITY:
- The female hero MUST be drawn in the EXACT SAME graphic style as the male hero (Reference 3): identical heavy black inked contours, identical interior hatching lines, identical cel-shading and shadow depth, identical fabric and leather texture. They must look like a perfectly matched pair from the exact same dark fantasy universe.

CRITICAL ORIENTATION & DIRECTION:
- The heroine stands on the LEFT side of the screen fighting a monster on the RIGHT side.
- Therefore, the heroine MUST BE TURNED AND FACING TOWARDS THE RIGHT (3/4 view facing towards the right side of the canvas).
- Head, shoulders, and alluring battle gaze are turned towards the RIGHT, locking eyes with the monster on the right.

POSE & COMBAT GUARD (SENSUALE, AGGRAZIATA E LETALE - PRONTA AL FENDENTE A DUE MANI):
- Sensual, athletic, and agile combat ready guard stance: alluring feminine curves with deadly martial poise.
- Stance: Arched back, graceful waist twist towards the right, toned athletic legs planted in an agile, dynamic fighting stance with bent knees, ready to leap or strike towards the right.
- Arms & Hands (TWO-HANDED GRIP ON MEDIEVAL SWORD):
  * BOTH HANDS GRIPPING THE SWORD TOGETHER on the hilt in a classic medieval two-handed ready attack guard in front of the chest/torso (matching the male's combat guard logic).
  * Right hand on the upper grip, left hand on the lower grip/pommel, forearms held in a graceful yet strong forward combat guard.
  * The sword blade extends forward/upward angled towards the right enemy, ready to strike a swift piercing slash or thrust.
  * Standard medieval steel arming sword / longsword (straight double-edged steel blade, crossguard, leather grip - matching the male's weapon style, NOT a thin fencing foil).
  * This two-handed grip directly covers two-handed weapons (greatswords, polearms, giant war hammers) and also allows an equipped shield to overlay the forward left forearm seamlessly!
  * Clean steel blade with crisp black inked contours. NO motion blur, NO pink glow trails, NO magic particles.
- Expression: Confident, fierce, beautiful battle expression with sharp focused eyes locked towards the right.

PHYSIQUE & SENSUALITÀ:
- Sensual athletic build ("chiaramente più sensuale"): distinct feminine curves, narrow athletic waist, toned hips and legs, defined athletic arms, elegant silhouette.
- Outfit: Coarse unbleached linen shirt/tunic with open V-neck (matching male shirt fabric and color), natural cloth folds draping gracefully over curves, fitted brown leather trousers accentuating toned legs, dark brown leather gauntlets/bracers, cuffed medieval travelling boots.
- Head: Short buzzed hair / closely shaved scalp silhouette (clean template for modular wigs/helmets).
- Background: Flat, solid, pure uniform #FF00FF magenta background (for automated clean chroma key extraction). Full figure fully visible on canvas with margins.
"""
    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': B64_FEMALE_IDLE}},
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MALE_IDLE}},
        {'text': prompt}
    ]

    print("Generating Female Hero Combat Ready Attack Guard (Facing Right, Unified Style, Two-Handed Grip)...")
    img_bytes = call_gemini_image(parts)
    if img_bytes:
        raw_path = os.path.join(OUTPUT_DIR, 'hero_female_attack_raw.png')
        with open(raw_path, 'wb') as f:
            f.write(img_bytes)
        print(f"Saved raw image to {raw_path}")
        clean_img = clean_chroma(raw_path)
        clean_path = os.path.join(OUTPUT_DIR, 'hero_female_attack_base.png')
        clean_img.save(clean_path)
        print(f"Saved cut-out attack base to {clean_path}")
        return clean_path
    return None

if __name__ == '__main__':
    target = sys.argv[1].lower() if len(sys.argv) > 1 else 'all'
    if target in ['male', 'all']:
        generate_male_attack()
    if target in ['female', 'all']:
        generate_female_attack()
