"""Knight Armor Sets Generator for 'Gym Oath'.
Generates 3 Tiers of Modular Armor Overlays for Male and Female:
- Tier 1: Gambeson (Quilted Canvas & Leather, BARE HEAD, NO awkward coif)
- Tier 2: Cuoio Rinforzato (Studded Hardened Leather, bronze studs, stylish open-face helmet)
- Tier 3: Piastre & Maglia (Spartan Dark Souls style, battle-worn steel, CLOSED VISOR HELMET)

User Directives:
- Tier 1: Diamond quilted canvas for both, bare head / no awkward hood.
- Tier 2: Adapt male colors to match the gorgeous female bronze-studded leather; stylish open-face helmet for both.
- Tier 3: Spartan, basic, grounded dark fantasy Souls knight with closed visor helmet for both (referencing uploaded Souls image).
- #FF00FF magenta background for clean chroma cutout.
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
OUTPUT_DIR = os.path.join(PIPELINE_DIR, 'output', 'armors')
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

REF_MONK = os.path.join(REPO_DIR, 'assets', 'art', 'enemies', 'broken_monk_idle.png')
REF_BOSS = os.path.join(REF_DIR, 'ref_cinder_boss.jpg')
REF_SOULS = os.path.join(REF_DIR, 'ref_souls_knight.png')
HERO_MALE_IDLE = os.path.join(BASES_DIR, 'hero_male_base.png')
HERO_FEMALE_IDLE = os.path.join(BASES_DIR, 'hero_female_base.png')

B64_MONK = load_b64(REF_MONK) if os.path.exists(REF_MONK) else (load_b64(REF_BOSS) if os.path.exists(REF_BOSS) else None)
B64_SOULS = load_b64(REF_SOULS) if os.path.exists(REF_SOULS) else None
B64_MALE_IDLE = load_b64(HERO_MALE_IDLE) if os.path.exists(HERO_MALE_IDLE) else None
B64_FEMALE_IDLE = load_b64(HERO_FEMALE_IDLE) if os.path.exists(HERO_FEMALE_IDLE) else None

def call_gemini(parts, max_retries=3):
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
            time.sleep(2)
    return None

STYLE_DIRECTIVE = """CRITICAL ART STYLE & UNIFORMITY DIRECTIVE FOR 'GYM OATH':
You are the lead concept artist for 'Gym Oath', a 2D Dark Fantasy Medieval RPG.
- ART MEDIUM: 2D stylized dark fantasy graphic novel / comic book character art (like Darkest Dungeon, Hades, Castlevania).
- INKING & LINEWORK: Bold, heavy, expressive black ink contour lines surrounding the entire silhouette, plus distinct black ink lines inside defining plates, leather seams, cloth quilting, and metal edges. Sharp, crisp black ink pen strokes everywhere.
- COLORING: Rich cel-shading with clear graphic block shadows. Deep charcoal shadow tones (#0D0B09) and warm antique gold / amber rim highlights (#C9A24A).
- NO 3D CGI airbrushing. NO smooth blended photorealistic rendering."""

def generate_tier1_gambeson(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_IDLE if is_male else B64_FEMALE_IDLE
    hero_title = "Male Hero" if is_male else "Female Hero"

    desc = (
        "Quilted diamond-stitched heavy padded gambeson tunic in weathered natural warm canvas (#D4C5A9), dark brown leather fastening straps with brass buckles across the chest, reinforced padded vambraces on forearms, and quilted diamond-stitched gambeson breeches with knee pads over traveling boots."
        if is_male else
        "Sleek form-fitting diamond-quilted gambeson in the SAME natural warm canvas (#D4C5A9) diamond-stitch fabric as the male, beautifully tailored to her sensual athletic hourglass silhouette, cinched at her narrow waist with a brown leather buckle belt, padded vambraces, and CRITICAL: MATCHING DIAMOND-QUILTED CANVAS GAMBESON LEGS/PANTS (pantaloni e cosciali in tessuto trapuntato chiaro a rombi, matching the tunic exactly, NOT leather, NOT bare/white leggings), with leather knee cuffs and boots."
    )

    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved {hero_title} character in idle pose.

TASK:
Generate the full-body character sprite for the {hero_title} wearing Tier 1 Gambeson in 'Gym Oath':
- SUBJECT: {hero_title} wearing the complete Gambeson set:
  {desc}
- HEAD (CRITICAL): BARE HEAD WITH SHORT HAIR (NO mail coif, NO hood, NO bonnet helmet!). The character's face from Reference 2 is completely bare and visible, noble and heroic.
- POSE & PROPORTIONS:
  * Full-body standing 3/4 pose facing slightly right, identical in scale, height, and stance to Reference 2.
  * {"Masculine athletic natural build." if is_male else "Sensual, alluring athletic curves with narrow waist."}
- BACKGROUND: Flat, solid, pure uniform #FF00FF magenta background (for automated clean chroma key cutout). Full figure fully visible with margins.
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': base_b64}},
        {'text': prompt}
    ]

    out_name = f"{gender}_tier1_gambeson"
    print(f"Generating Tier 1 Gambeson for {gender} (Bare Head, Diamond Quilted)...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, f"{out_name}_raw.png")
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, f"{out_name}_clean.png")
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

def generate_tier2_cuoio(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_IDLE if is_male else B64_FEMALE_IDLE
    hero_title = "Male Hero" if is_male else "Female Hero"

    desc = (
        "Heavy boiled leather cuirass in DARK ESPRESSO / DARK CHOCOLATE BROWN LEATHER (cuoio scuro, NOT red, NOT orange, NOT terracotta), reinforced with polished antique bronze rivets, studs, and buckles. Layered dark leather shoulder pauldrons with bronze edges, dark leather bracers, and studded dark brown leather greaves with bronze knee cops. Dark, rugged, grounded warrior aesthetic."
        if is_male else
        "Sensual and deadly sculpted dark leather brigandine cuirass with polished bronze studs, accentuating her athletic curves, narrow waist and arched posture, sleek contoured leather shoulder guards, and fitted leather greaves with bronze knee cops."
    )

    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved {hero_title} character in idle pose.

TASK:
Generate the full-body character sprite for the {hero_title} wearing Tier 2 Cuoio Rinforzato (Studded Hardened Leather) in 'Gym Oath':
- SUBJECT: {hero_title} wearing the complete hardened leather armor:
  {desc}
- HELMET (CRITICAL - OPEN FACE & STYLISH):
  * Sleek, stylish open-face leather and bronze helmet (open barbute / contoured leather helm with polished bronze brow plate and cheek guards).
  * The face MUST BE COMPLETELY OPEN AND VISIBLE ("sempre viso aperto"), showing the handsome/alluring facial features, eyes, nose, mouth and jaw, stylish and flattering.
- POSE & PROPORTIONS:
  * Full-body standing 3/4 pose facing slightly right, identical in scale, height, and stance to Reference 2.
  * {"Masculine athletic build." if is_male else "Sensual, alluring athletic curves."}
- BACKGROUND: Flat, solid, pure uniform #FF00FF magenta background (for automated clean chroma key cutout). Full figure fully visible with margins.
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': base_b64}},
        {'text': prompt}
    ]

    out_name = f"{gender}_tier2_cuoio"
    print(f"Generating Tier 2 Cuoio for {gender} (Dark Bronze Studded Leather, Stylish Open Helmet)...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, f"{out_name}_raw.png")
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, f"{out_name}_clean.png")
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

def generate_tier3_piastre(gender='male'):
    is_male = (gender.lower() == 'male')
    base_b64 = B64_MALE_IDLE if is_male else B64_FEMALE_IDLE
    hero_title = "Male Hero" if is_male else "Female Hero"

    male_specific = """  * STEEL CUIRASS COVERS CHEST AND ENTIRE ABDOMEN: A rugged, battle-worn steel plate breastplate/cuirass that COVERS BOTH THE PECTORALS AND THE ABDOMEN down to the belt/waistline (protecting both chest and belly together with forged steel plates). The heavy riveted chainmail hauberk is prominent underneath: visible on the arms/sleeves, shoulders, neck, ribs, and hanging below the belt.""" if is_male else """  * STEEL PLATE CUIRASS COVERS CHEST AND ABDOMEN: Fitted steel cuirass covering both chest and abdomen down to the waistline, with alluring athletic curves. Heavy riveted chainmail visible on shoulders, sleeves, and under the belt."""

    prompt = f"""{STYLE_DIRECTIVE}

Reference 1 (Broken Monk) demonstrates the inking line weight, graphic shadow blocks, and dark fantasy comic aesthetic.
Reference 2 shows the approved {hero_title} base silhouette and stance.
Reference 3 shows the EXACT TARGET INSPIRATION: Classic Spartan Dark Souls Knight Armor (weathered steel plate over chainmail, closed visor fluted helmet, tattered dark waist cloth).

TASK:
Generate the full-body character sprite for the {hero_title} wearing Tier 3 RUDIMENTARY SPARTAN SOULS-STYLE KNIGHT ARMOR in 'Gym Oath':
- SUBJECT: Rudimentary, basic early-game medieval knight armor inspired by Dark Souls / Demon's Souls:
{male_specific}
  * CHAINMAIL IS PRIMARY & PROMINENT: A heavy, rugged, riveted chainmail hauberk covering the shoulders, arms, collar/neck, and lower waist skirt.
  * HELMET (MANDATORY - CLOSED VISOR / A VISO COPERTO): Classic Souls knight fluted helmet / bascinet with a CLOSED STEEL VISOR, narrow horizontal eye slit, and neck gorget. Face is fully covered.
  * LIMBS & WAIST: Asymmetrical battle-worn steel shoulder pauldron strapped over chainmail, articulated steel vambraces, tattered dark green cloth/chainmail skirt beneath the belt, and steel greaves over chainmail legs and sabatons.
  * AESTHETIC: Rudimentary, spartan, gritty battle-worn steel and chainmail (siamo ancora a livelli bassi!).
- POSE & PROPORTIONS:
  * Full-body standing 3/4 pose facing slightly right, matching Reference 2.
  * {"Solid masculine knight presence." if is_male else "Sleek, athletic feminine proportions clearly readable underneath the steel plates."}
- BACKGROUND: Flat, solid, pure uniform #FF00FF magenta background (for automated clean chroma key cutout). Full figure fully visible with margins.
"""

    parts = [
        {'inlineData': {'mimeType': 'image/png', 'data': B64_MONK}},
        {'inlineData': {'mimeType': 'image/png', 'data': base_b64}},
    ]
    if B64_SOULS:
        parts.append({'inlineData': {'mimeType': 'image/png', 'data': B64_SOULS}})
    parts.append({'text': prompt})

    out_name = f"{gender}_tier3_piastre"
    print(f"Generating Tier 3 Rudimentary Spartan Souls Knight for {gender} (Cuirass covers Chest & Abdomen, Chainmail Prominent, Closed Visor)...")
    img_data = call_gemini(parts)
    if img_data:
        raw_p = os.path.join(OUTPUT_DIR, f"{out_name}_raw.png")
        with open(raw_p, 'wb') as f:
            f.write(img_data)
        clean_p = os.path.join(OUTPUT_DIR, f"{out_name}_clean.png")
        clean_chroma(raw_p).save(clean_p)
        print(f"Saved {clean_p}")
        return clean_p
    return None

if __name__ == '__main__':
    target = sys.argv[1].lower() if len(sys.argv) > 1 else 'updates'
    if target == 'updates':
        generate_tier1_gambeson('female')
        generate_tier2_cuoio('male')
        generate_tier3_piastre('male')
        generate_tier3_piastre('female')
    elif target in ['t1', 'all']:
        generate_tier1_gambeson('male')
        generate_tier1_gambeson('female')
    elif target in ['t2', 'all']:
        generate_tier2_cuoio('male')
        generate_tier2_cuoio('female')
    elif target in ['t3', 'all']:
        generate_tier3_piastre('male')
        generate_tier3_piastre('female')
