"""Extract True Modular Armors and Build Showcase for 'Gym Oath'.
Extracts cleanly isolated modular slots (helm, chest, legs) with zero cut glitches,
and demonstrates perfect mix-and-match compatibility.
"""

import os
import shutil
from PIL import Image, ImageDraw, ImageFont
import numpy as np

PIPELINE_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline"
ARMORS_DIR = os.path.join(PIPELINE_DIR, "output", "armors")
BASES_DIR = os.path.join(PIPELINE_DIR, "current_bases")
MODULAR_DIR = os.path.join(PIPELINE_DIR, "output", "modular_armors")
BRAIN_DIR = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
KNIGHT_ART = r"C:\Users\pissio\Creazione-Gioco-RPG-\assets\art\knight"

os.makedirs(MODULAR_DIR, exist_ok=True)

# 1. Load Sources
base_m = Image.open(os.path.join(BASES_DIR, "hero_male_base.png")).convert("RGBA")
base_f = Image.open(os.path.join(BASES_DIR, "hero_female_base.png")).convert("RGBA")

m_t1 = Image.open(os.path.join(ARMORS_DIR, "male_tier1_gambeson_clean.png")).convert("RGBA")
m_t2 = Image.open(os.path.join(ARMORS_DIR, "male_tier2_cuoio_clean.png")).convert("RGBA")
m_t3 = Image.open(os.path.join(ARMORS_DIR, "male_tier3_piastre_clean.png")).convert("RGBA")

f_t1 = Image.open(os.path.join(ARMORS_DIR, "female_tier1_gambeson_clean.png")).convert("RGBA")
f_t2 = Image.open(os.path.join(ARMORS_DIR, "female_tier2_cuoio_clean.png")).convert("RGBA")
f_t3 = Image.open(os.path.join(ARMORS_DIR, "female_tier3_piastre_clean.png")).convert("RGBA")

m_t3_legs_src = Image.open(os.path.join(BRAIN_DIR, "test_t3_legs_clean.png")).convert("RGBA")
f_t3_legs_src = Image.open(os.path.join(BRAIN_DIR, "test_f_t3_legs_clean.png")).convert("RGBA")

m_t3_helm_src = Image.open(os.path.join(BRAIN_DIR, "test_male_t3_helm_clean.png")).convert("RGBA")
f_t3_helm_src = Image.open(os.path.join(BRAIN_DIR, "test_female_t3_helm_clean.png")).convert("RGBA")

h, w = 1024, 1024
Y, X = np.indices((h, w))

def build_male_slots():
    print("Building Male Modular Slots...")
    # T1 Gambeson
    # Chest: Upper body down to natural tunic hem Y <= 635
    arr_t1 = np.array(m_t1)
    c1_mask = ((Y >= 180) & (Y <= 600) & ((X < 430) | (X > 590))) | ((Y >= 200) & (Y <= 635) & (X >= 420) & (X <= 600))
    arr_c1 = np.zeros_like(arr_t1); arr_c1[c1_mask] = arr_t1[c1_mask]
    m_c1 = Image.fromarray(arr_c1)
    
    # Legs: Quilted pants from waist Y >= 460 down, no hands
    l1_mask = (Y >= 460) & ~((Y < 600) & ((X < 430) | (X > 590)))
    arr_l1 = np.zeros_like(arr_t1); arr_l1[l1_mask] = arr_t1[l1_mask]
    m_l1 = Image.fromarray(arr_l1)
    
    # T2 Cuoio
    # Helm: Head only Y <= 220, X: 425..575
    arr_t2 = np.array(m_t2)
    h2_mask = (Y <= 220) & (X >= 425) & (X <= 575)
    arr_h2 = np.zeros_like(arr_t2); arr_h2[h2_mask] = arr_t2[h2_mask]
    m_h2 = Image.fromarray(arr_h2)
    
    # Chest: Cuirass & tassets down to Y <= 535
    c2_mask = ((Y >= 180) & (Y <= 600) & ((X < 430) | (X > 590))) | ((Y >= 210) & (Y <= 535) & (X >= 420) & (X <= 600))
    arr_c2 = np.zeros_like(arr_t2); arr_c2[c2_mask] = arr_t2[c2_mask]
    m_c2 = Image.fromarray(arr_c2)
    
    # Legs: Leather pants from waist Y >= 460 down, no hands
    l2_mask = (Y >= 460) & ~((Y < 600) & ((X < 430) | (X > 590)))
    arr_l2 = np.zeros_like(arr_t2); arr_l2[l2_mask] = arr_t2[l2_mask]
    m_l2 = Image.fromarray(arr_l2)
    
    # T3 Piastre
    # Helm: From isolated source (head + gorget)
    arr_th = np.array(m_t3_helm_src)
    h3_mask = (Y <= 250) & (X >= 410) & (X <= 580)
    arr_h3 = np.zeros_like(arr_th); arr_h3[h3_mask] = arr_th[h3_mask]
    m_h3 = Image.fromarray(arr_h3)
    
    # Chest: Cuirass (chest + abdomen) + fauld + green cloth down to Y <= 645
    arr_t3 = np.array(m_t3)
    c3_mask = ((Y >= 180) & (Y <= 600) & ((X < 420) | (X > 595))) | ((Y >= 210) & (Y <= 645) & (X >= 420) & (X <= 595))
    arr_c3 = np.zeros_like(arr_t3); arr_c3[c3_mask] = arr_t3[c3_mask]
    m_c3 = Image.fromarray(arr_c3)
    
    # Legs: From isolated source (chainmail thighs + steel greaves + sabatons)
    arr_tl = np.array(m_t3_legs_src)
    l3_mask = (Y >= 445) & ~((Y < 600) & ((X < 425) | (X > 595)))
    arr_l3 = np.zeros_like(arr_tl); arr_l3[l3_mask] = arr_tl[l3_mask]
    m_l3 = Image.fromarray(arr_l3)
    
    return (m_c1, m_l1), (m_h2, m_c2, m_l2), (m_h3, m_c3, m_l3)

def build_female_slots():
    print("Building Female Modular Slots...")
    # T1 Gambeson
    arr_t1 = np.array(f_t1)
    c1_mask = ((Y >= 180) & (Y <= 600) & ((X < 430) | (X > 590))) | ((Y >= 200) & (Y <= 530) & (X >= 420) & (X <= 600))
    arr_c1 = np.zeros_like(arr_t1); arr_c1[c1_mask] = arr_t1[c1_mask]
    f_c1 = Image.fromarray(arr_c1)
    
    l1_mask = (Y >= 460) & ~((Y < 600) & ((X < 430) | (X > 590)))
    arr_l1 = np.zeros_like(arr_t1); arr_l1[l1_mask] = arr_t1[l1_mask]
    f_l1 = Image.fromarray(arr_l1)
    
    # T2 Cuoio
    arr_t2 = np.array(f_t2)
    h2_mask = (Y <= 220) & (X >= 425) & (X <= 575)
    arr_h2 = np.zeros_like(arr_t2); arr_h2[h2_mask] = arr_t2[h2_mask]
    f_h2 = Image.fromarray(arr_h2)
    
    c2_mask = ((Y >= 180) & (Y <= 600) & ((X < 430) | (X > 590))) | ((Y >= 210) & (Y <= 530) & (X >= 420) & (X <= 600))
    arr_c2 = np.zeros_like(arr_t2); arr_c2[c2_mask] = arr_t2[c2_mask]
    f_c2 = Image.fromarray(arr_c2)
    
    l2_mask = (Y >= 460) & ~((Y < 600) & ((X < 430) | (X > 590)))
    arr_l2 = np.zeros_like(arr_t2); arr_l2[l2_mask] = arr_t2[l2_mask]
    f_l2 = Image.fromarray(arr_l2)
    
    # T3 Piastre
    arr_th = np.array(f_t3_helm_src)
    h3_mask = (Y <= 250) & (X >= 410) & (X <= 580)
    arr_h3 = np.zeros_like(arr_th); arr_h3[h3_mask] = arr_th[h3_mask]
    f_h3 = Image.fromarray(arr_h3)
    
    arr_t3 = np.array(f_t3)
    c3_mask = ((Y >= 180) & (Y <= 600) & ((X < 420) | (X > 595))) | ((Y >= 210) & (Y <= 645) & (X >= 420) & (X <= 595))
    arr_c3 = np.zeros_like(arr_t3); arr_c3[c3_mask] = arr_t3[c3_mask]
    f_c3 = Image.fromarray(arr_c3)
    
    arr_tl = np.array(f_t3_legs_src)
    l3_mask = (Y >= 445) & ~((Y < 600) & ((X < 425) | (X > 595)))
    arr_l3 = np.zeros_like(arr_tl); arr_l3[l3_mask] = arr_tl[l3_mask]
    f_l3 = Image.fromarray(arr_l3)
    
    return (f_c1, f_l1), (f_h2, f_c2, f_l2), (f_h3, f_c3, f_l3)

# Build slots
(m_c1, m_l1), (m_h2, m_c2, m_l2), (m_h3, m_c3, m_l3) = build_male_slots()
(f_c1, f_l1), (f_h2, f_c2, f_l2), (f_h3, f_c3, f_l3) = build_female_slots()

# Save all slots
m_slots = [
    ("male_gambeson_chest.png", m_c1), ("male_gambeson_legs.png", m_l1),
    ("male_cuoio_helm.png", m_h2), ("male_cuoio_chest.png", m_c2), ("male_cuoio_legs.png", m_l2),
    ("male_piastre_helm.png", m_h3), ("male_piastre_chest.png", m_c3), ("male_piastre_legs.png", m_l3)
]
f_slots = [
    ("female_gambeson_chest.png", f_c1), ("female_gambeson_legs.png", f_l1),
    ("female_cuoio_helm.png", f_h2), ("female_cuoio_chest.png", f_c2), ("female_cuoio_legs.png", f_l2),
    ("female_piastre_helm.png", f_h3), ("female_piastre_chest.png", f_c3), ("female_piastre_legs.png", f_l3)
]

for name, im in m_slots + f_slots:
    p = os.path.join(MODULAR_DIR, name)
    im.save(p)

# Update Official Assets
m_idle = os.path.join(KNIGHT_ART, "male", "idle")
f_idle = os.path.join(KNIGHT_ART, "female", "idle")

m_c1.save(os.path.join(m_idle, "chest_gambeson.png"))
m_l1.save(os.path.join(m_idle, "legs_gambeson.png"))
m_h2.save(os.path.join(m_idle, "helm_cuoio.png"))
m_c2.save(os.path.join(m_idle, "chest_cuoio.png"))
m_l2.save(os.path.join(m_idle, "legs_cuoio.png"))
m_h3.save(os.path.join(m_idle, "helm_piastre.png"))
m_c3.save(os.path.join(m_idle, "chest_piastre.png"))
m_l3.save(os.path.join(m_idle, "legs_piastre.png"))

f_c1.save(os.path.join(f_idle, "chest_gambeson.png"))
f_l1.save(os.path.join(f_idle, "legs_gambeson.png"))
f_h2.save(os.path.join(f_idle, "helm_cuoio.png"))
f_c2.save(os.path.join(f_idle, "chest_cuoio.png"))
f_l2.save(os.path.join(f_idle, "legs_cuoio.png"))
f_h3.save(os.path.join(f_idle, "helm_piastre.png"))
f_c3.save(os.path.join(f_idle, "chest_piastre.png"))
f_l3.save(os.path.join(f_idle, "legs_piastre.png"))

print("Official knight assets updated!")

# --- COMPOSITION SHOWCASE ---
def compose(base, l, c, h=None):
    res = base.copy()
    if l: res.alpha_composite(l)
    if c: res.alpha_composite(c)
    if h: res.alpha_composite(h)
    return res

male_combos = [
    ("T1 Gambeson Completo", compose(base_m, m_l1, m_c1, None)),
    ("Mix: Gambeson Legs + Cuoio Chest + Piastre Helm", compose(base_m, m_l1, m_c2, m_h3)),
    ("Mix: Cuoio Legs + Piastre Chest + Cuoio Helm", compose(base_m, m_l2, m_c3, m_h2)),
    ("Mix: Piastre Legs + Gambeson Chest + Piastre Helm", compose(base_m, m_l3, m_c1, m_h3))
]

female_combos = [
    ("T1 Gambeson Completo", compose(base_f, f_l1, f_c1, None)),
    ("Mix: Gambeson Legs + Cuoio Chest + Piastre Helm", compose(base_f, f_l1, f_c2, f_h3)),
    ("Mix: Cuoio Legs + Piastre Chest + Cuoio Helm", compose(base_f, f_l2, f_c3, f_h2)),
    ("Mix: Piastre Legs + Gambeson Chest + Piastre Helm", compose(base_f, f_l3, f_c1, f_h3))
]

def crop_content(img, pad=15):
    bbox = img.getbbox()
    if not bbox: return img
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

draw.text((30, 20), "MODULAR MIX & MATCH SHOWCASE — EROE MASCHIO (Slot intercambiabili senza stacchi)", fill=(201, 162, 74))
for idx, (title, img) in enumerate(male_combos):
    cropped = crop_content(img)
    w_res = int(cropped.width * (target_h / cropped.height))
    res = cropped.resize((w_res, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = 50
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 10, y + 10), title, fill=(180, 150, 100))
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

y_start_f = row_h + 35
draw.text((30, y_start_f), "MODULAR MIX & MATCH SHOWCASE — EROINA FEMMINA (Slot intercambiabili senza stacchi)", fill=(201, 162, 74))
for idx, (title, img) in enumerate(female_combos):
    cropped = crop_content(img)
    w_res = int(cropped.width * (target_h / cropped.height))
    res = cropped.resize((w_res, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = y_start_f + 30
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 10, y + 10), title, fill=(180, 150, 100))
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

out_preview = os.path.join(BRAIN_DIR, "armors_modular_mix_preview.jpg")
canvas.save(out_preview, quality=94)
print("Saved armors_modular_mix_preview.jpg to:", out_preview)

# --- BONUS: STANDALONE SLOTS INSPECTION SHEET ---
# Shows the isolated individual pieces (Helm, Chest, Legs) side-by-side
slot_cards = [
    ("Helm Cuoio", m_h2), ("Chest Gambeson", m_c1), ("Legs Gambeson", m_l1),
    ("Helm Piastre", m_h3), ("Chest Cuoio", m_c2), ("Legs Cuoio", m_l2),
    ("Chest Piastre (Plates+Cloth)", m_c3), ("Legs Piastre (Greaves+Mail)", m_l3)
]

slots_canvas = Image.new("RGB", (1400, 720), (14, 12, 16))
draw_s = ImageDraw.Draw(slots_canvas)
draw_s.text((30, 20), "PEZZI MODULARI SEZIONATI SINGOLARMENTE — ISPEZIONE ASSET STANDALONE", fill=(201, 162, 74))

card_w = 160
card_h = 300
for idx, (title, piece) in enumerate(slot_cards):
    row = 0 if idx < 4 else 1
    col = idx % 4
    x = 30 + col * 340
    y = 55 + row * 330
    draw_s.rectangle([x, y, x + 320, y + 310], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw_s.text((x + 10, y + 10), title, fill=(180, 150, 100))
    cr = crop_content(piece, pad=8)
    if cr.width > 0 and cr.height > 0:
        scale = min(280 / cr.width, 250 / cr.height)
        nw, nh = int(cr.width * scale), int(cr.height * scale)
        res_p = cr.resize((nw, nh), Image.Resampling.LANCZOS)
        px = x + (320 - nw) // 2
        py = y + 40 + (250 - nh) // 2
        slots_canvas.paste(res_p, (px, py), res_p)

slots_preview_p = os.path.join(BRAIN_DIR, "armors_standalone_slots_preview.jpg")
slots_canvas.save(slots_preview_p, quality=94)
print("Saved standalone slots inspection sheet to:", slots_preview_p)
