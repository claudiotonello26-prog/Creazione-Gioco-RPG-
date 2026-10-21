"""Modular Armor Slicer and Mix-and-Match Compositor for 'Gym Oath'.
Extracts modular slots (helm, chest, legs) from full armor sprites (Tiers 1, 2, 3 for Male and Female)
and validates full mix-and-match compatibility on the 1024x1024 base.
"""

import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_DIR = os.path.dirname(PIPELINE_DIR)
ARMORS_DIR = os.path.join(PIPELINE_DIR, 'output', 'armors')
BASES_DIR = os.path.join(PIPELINE_DIR, 'current_bases')
OUTPUT_MODULAR = os.path.join(PIPELINE_DIR, 'output', 'modular_armors')
os.makedirs(OUTPUT_MODULAR, exist_ok=True)

ART_DIR = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"

def extract_slots(gender, tier_name, full_armor_path, helm_y_cut, waist_y_cut, has_helm=True):
    armor = Image.open(full_armor_path).convert('RGBA')
    w, h = armor.size
    
    # Base canvas for each slot
    helm = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    chest = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    legs = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    
    arr_armor = np.array(armor)
    
    # 1. HELM
    if has_helm:
        arr_helm = arr_armor.copy()
        Y, X = np.indices((h, w))
        # Helm covers head and coif down to helm_y_cut in neck center
        helm_mask = (Y <= helm_y_cut) & (X >= 410) & (X <= 630)
        arr_helm[~helm_mask] = 0
        helm = Image.fromarray(arr_helm)
    
    # 2. CHEST (torso, pauldrons, arms, hands, down to bottom of tunic/belt)
    arr_chest = arr_armor.copy()
    Y, X = np.indices((h, w))
    # Shoulders and arms: from Y >= 160 down to hands Y <= 580
    arms_mask = (Y >= 160) & (Y <= 580) & ((X < 430) | (X > 590))
    # Torso: from Y >= 205 down to bottom of tunic/belt (waist_y_cut)
    torso_mask = (Y >= 205) & (Y <= waist_y_cut) & (X >= 430) & (X <= 590)
    chest_mask = arms_mask | torso_mask
    arr_chest[~chest_mask] = 0
    chest = Image.fromarray(arr_chest)
    
    # 3. LEGS (from waist down, thighs, knees, greaves, boots)
    arr_legs = arr_armor.copy()
    legs_overlap_y = waist_y_cut - 50
    arr_legs[:legs_overlap_y, :, :] = 0
    legs = Image.fromarray(arr_legs)
    
    # Save individual slots
    prefix = f"{gender}_{tier_name}"
    if has_helm:
        helm.save(os.path.join(OUTPUT_MODULAR, f"{prefix}_helm.png"))
    chest.save(os.path.join(OUTPUT_MODULAR, f"{prefix}_chest.png"))
    legs.save(os.path.join(OUTPUT_MODULAR, f"{prefix}_legs.png"))
    
    return helm, chest, legs

# Process Male
print("Extracting Male Slots...")
m_t1_h, m_t1_c, m_t1_l = extract_slots('male', 'gambeson', os.path.join(ARMORS_DIR, 'male_tier1_gambeson_clean.png'), 235, 525, has_helm=False)
m_t2_h, m_t2_c, m_t2_l = extract_slots('male', 'cuoio', os.path.join(ARMORS_DIR, 'male_tier2_cuoio_clean.png'), 230, 520, has_helm=True)
m_t3_h, m_t3_c, m_t3_l = extract_slots('male', 'piastre', os.path.join(ARMORS_DIR, 'male_tier3_piastre_clean.png'), 250, 530, has_helm=True)

# Process Female
print("Extracting Female Slots...")
f_t1_h, f_t1_c, f_t1_l = extract_slots('female', 'gambeson', os.path.join(ARMORS_DIR, 'female_tier1_gambeson_clean.png'), 235, 515, has_helm=False)
f_t2_h, f_t2_c, f_t2_l = extract_slots('female', 'cuoio', os.path.join(ARMORS_DIR, 'female_tier2_cuoio_clean.png'), 230, 510, has_helm=True)
f_t3_h, f_t3_c, f_t3_l = extract_slots('female', 'piastre', os.path.join(ARMORS_DIR, 'female_tier3_piastre_clean.png'), 250, 520, has_helm=True)

# Build Mix & Match Showcase
base_m = Image.open(os.path.join(BASES_DIR, 'hero_male_base.png')).convert('RGBA')
base_f = Image.open(os.path.join(BASES_DIR, 'hero_female_base.png')).convert('RGBA')

def composite_character(base, legs, chest, helm=None):
    res = base.copy()
    if legs:
        res.alpha_composite(legs)
    if chest:
        res.alpha_composite(chest)
    if helm:
        res.alpha_composite(helm)
    return res

male_combos = [
    ("T1 Gambeson Completo", composite_character(base_m, m_t1_l, m_t1_c, None)),
    ("Mix: Gambeson Legs + Cuoio Chest + Piastre Helm", composite_character(base_m, m_t1_l, m_t2_c, m_t3_h)),
    ("Mix: Cuoio Legs + Piastre Chest + Cuoio Helm", composite_character(base_m, m_t2_l, m_t3_c, m_t2_h)),
    ("Mix: Piastre Legs + Gambeson Chest + Piastre Helm", composite_character(base_m, m_t3_l, m_t1_c, m_t3_h))
]

female_combos = [
    ("T1 Gambeson Completo", composite_character(base_f, f_t1_l, f_t1_c, None)),
    ("Mix: Gambeson Legs + Cuoio Chest + Piastre Helm", composite_character(base_f, f_t1_l, f_t2_c, f_t3_h)),
    ("Mix: Cuoio Legs + Piastre Chest + Cuoio Helm", composite_character(base_f, f_t2_l, f_t3_c, f_t2_h)),
    ("Mix: Piastre Legs + Gambeson Chest + Piastre Helm", composite_character(base_f, f_t3_l, f_t1_c, f_t3_h))
]

def crop_content(img, pad=15):
    bbox = img.getbbox()
    if not bbox:
        return img
    l = max(0, bbox[0] - pad)
    t = max(0, bbox[1] - pad)
    r = min(img.width, bbox[2] + pad)
    b = min(img.height, bbox[3] + pad)
    return img.crop((l, t, r, b))

target_h = 560
col_w = 340
total_w = col_w * 4 + 60
row_h = target_h + 80
total_h = row_h * 2 + 50

canvas = Image.new("RGB", (total_w, total_h), (14, 12, 16))
draw = ImageDraw.Draw(canvas)

draw.text((30, 20), "MODULAR MIX & MATCH SHOWCASE - EROE MASCHIO (Slot intercambiabili: Gambe, Busto, Elmo)", fill=(201, 162, 74))
for idx, (title, img) in enumerate(male_combos):
    cropped = crop_content(img)
    w = int(cropped.width * (target_h / cropped.height))
    res = cropped.resize((w, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = 50
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 10, y + 10), title, fill=(180, 150, 100))
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

y_start_f = row_h + 35
draw.text((30, y_start_f), "MODULAR MIX & MATCH SHOWCASE - EROINA FEMMINA (Slot intercambiabili: Gambe, Busto, Elmo)", fill=(201, 162, 74))
for idx, (title, img) in enumerate(female_combos):
    cropped = crop_content(img)
    w = int(cropped.width * (target_h / cropped.height))
    res = cropped.resize((w, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = y_start_f + 30
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 10, y + 10), title, fill=(180, 150, 100))
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

out_preview = os.path.join(ART_DIR, "armors_modular_mix_preview.jpg")
canvas.save(out_preview, quality=94)
print("Saved modular mix preview to:", out_preview)
