"""Extract True Modular Armors for 'Gym Oath'.
Author: Antigravity Agent
Cleanly sections armor into individual modular equipment slots:
- HELM: (Headwear only, closed knight bascinet with steel gorget or open-face leather helmet, NO shoulder pauldrons, NO undershirt).
- CHEST: (Torso, shoulders, arms, gauntlets down to fingertips, plus natural tunic skirt / tassets / fauld draped over legs).
- LEGS: (From waist/belt down to boots and sabatons, with full solid thighs and knee poleyns).

Eliminates all horizontal knife cuts, sliced garments, stray shirt collars, or overlapping cloth.
"""

import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_DIR = os.path.dirname(PIPELINE_DIR)
OUTPUT_ARMORS = os.path.join(PIPELINE_DIR, "output", "armors")
BRAIN_DIR = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
MODULAR_DIR = os.path.join(OUTPUT_ARMORS, "modular")
os.makedirs(MODULAR_DIR, exist_ok=True)

KNIGHT_ART = os.path.join(REPO_DIR, "assets", "art", "knight")

# Load Base Heroes
base_m = Image.open(os.path.join(KNIGHT_ART, "male", "idle", "base.png")).convert("RGBA")
base_f = Image.open(os.path.join(KNIGHT_ART, "female", "idle", "base.png")).convert("RGBA")

# Load Clean Armor Progression Sources
m_t1 = Image.open(os.path.join(OUTPUT_ARMORS, "male_tier1_gambeson_clean.png")).convert("RGBA")
m_t2 = Image.open(os.path.join(OUTPUT_ARMORS, "male_tier2_cuoio_clean.png")).convert("RGBA")
m_t3 = Image.open(os.path.join(OUTPUT_ARMORS, "male_tier3_piastre_clean.png")).convert("RGBA")

f_t1 = Image.open(os.path.join(OUTPUT_ARMORS, "female_tier1_gambeson_clean.png")).convert("RGBA")
f_t2 = Image.open(os.path.join(OUTPUT_ARMORS, "female_tier2_cuoio_clean.png")).convert("RGBA")
f_t3 = Image.open(os.path.join(OUTPUT_ARMORS, "female_tier3_piastre_clean.png")).convert("RGBA")

# Load Isolated Slot Sources from Gemini
m_t3_helm_src = Image.open(os.path.join(BRAIN_DIR, "test_male_t3_helm_clean.png")).convert("RGBA")
f_t3_helm_src = Image.open(os.path.join(BRAIN_DIR, "test_female_t3_helm_clean.png")).convert("RGBA")
m_t3_legs_src = Image.open(os.path.join(BRAIN_DIR, "test_t3_legs_clean.png")).convert("RGBA")
f_t3_legs_src = Image.open(os.path.join(BRAIN_DIR, "test_f_t3_legs_clean.png")).convert("RGBA")

Y, X = np.ogrid[:1024, :1024]

# --- HELMET CLEANING FUNCTION ---
def make_clean_piastre_helm(src_im, pts_bottom, left_bounds, right_bounds):
    arr = np.array(src_im)
    poly = left_bounds + pts_bottom + right_bounds
    mask_im = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask_im)
    draw.polygon(poly, fill=255)
    arr_mask = np.array(mask_im)
    res = np.zeros_like(arr)
    m = (arr_mask == 255) & (arr[:, :, 3] > 80)
    res[m] = arr[m]
    return Image.fromarray(res)

def build_male_slots():
    print("Building Male Modular Slots...")
    # T1 Gambeson
    # Chest: Diamond quilted tunic covering upper body down to natural curved hem Y <= 635, plus full arms
    arr_t1 = np.array(m_t1)
    mask_c1 = Image.new("L", (1024, 1024), 0)
    draw_c1 = ImageDraw.Draw(mask_c1)
    draw_c1.polygon([(340, 180), (430, 180), (430, 635), (340, 530)], fill=255) # left arm
    draw_c1.polygon([(575, 180), (665, 180), (665, 530), (575, 635)], fill=255) # right arm
    draw_c1.rectangle([420, 180, 585, 635], fill=255) # Tunic torso down to natural curved hem
    arr_mc1 = np.array(mask_c1)
    res_c1 = np.zeros_like(arr_t1)
    res_c1[(arr_mc1 == 255) & (arr_t1[:, :, 3] > 80)] = arr_t1[(arr_mc1 == 255) & (arr_t1[:, :, 3] > 80)]
    m_c1 = Image.fromarray(res_c1)
    
    # Legs: Quilted trousers with knee pads and boots from belt Y >= 420 down, full solid thighs
    arr_l1 = np.zeros_like(arr_t1)
    l1_m = (Y >= 420) & (X >= 360) & (X <= 680) & (arr_t1[:, :, 3] > 80)
    arr_l1[l1_m] = arr_t1[l1_m]
    m_l1 = Image.fromarray(arr_l1)
    
    # T2 Cuoio
    # Helm: Reinforced leather helmet with golden crest and brow band, cheek guards. No pauldrons!
    arr_t2 = np.array(m_t2)
    mask_h2 = Image.new("L", (1024, 1024), 0)
    draw_h2 = ImageDraw.Draw(mask_h2)
    draw_h2.polygon([
        (438, 30), (565, 30), (570, 140), (565, 195), (550, 208),
        (500, 208), (455, 208), (440, 195), (438, 140)
    ], fill=255)
    arr_mh2 = np.array(mask_h2)
    res_h2 = np.zeros_like(arr_t2)
    res_h2[(arr_mh2 == 255) & (arr_t2[:, :, 3] > 80)] = arr_t2[(arr_mh2 == 255) & (arr_t2[:, :, 3] > 80)]
    m_h2 = Image.fromarray(res_h2)
    
    # Chest: Cuirass + pauldrons + gauntlets + belt + 2 tassets (open groin so legs show through!)
    mask_c2 = Image.new("L", (1024, 1024), 0)
    draw_c2 = ImageDraw.Draw(mask_c2)
    draw_c2.rectangle([340, 180, 425, 540], fill=255) # left arm/gauntlet
    draw_c2.rectangle([580, 180, 670, 540], fill=255) # right arm/gauntlet
    draw_c2.rectangle([420, 180, 585, 445], fill=255) # Torso down to belt
    draw_c2.polygon([(420, 440), (472, 440), (468, 518), (420, 518)], fill=255) # left tasset
    draw_c2.polygon([(528, 440), (585, 440), (585, 518), (530, 518)], fill=255) # right tasset
    arr_mc2 = np.array(mask_c2)
    res_c2 = np.zeros_like(arr_t2)
    res_c2[(arr_mc2 == 255) & (arr_t2[:, :, 3] > 80)] = arr_t2[(arr_mc2 == 255) & (arr_t2[:, :, 3] > 80)]
    m_c2 = Image.fromarray(res_c2)
    
    # Legs: Hardened leather pants with knee poleyns and riding boots from belt Y >= 420 down
    arr_l2 = np.zeros_like(arr_t2)
    l2_m = (Y >= 420) & (X >= 360) & (X <= 680) & (arr_t2[:, :, 3] > 80)
    arr_l2[l2_m] = arr_t2[l2_m]
    m_l2 = Image.fromarray(arr_l2)
    
    # T3 Piastre
    # Helm: Spartan bascinet with closed visor, comb, and steel gorget collar trimmed to exact bottom ink line
    pts_m = [(438, 208), (445, 225), (455, 242), (470, 256), (490, 263), (510, 260), (525, 252), (540, 238), (555, 225), (572, 212)]
    left_m = [(410, 0), (410, 180), (430, 195)]
    right_m = [(580, 195), (580, 180), (580, 0)]
    m_h3 = make_clean_piastre_helm(m_t3_helm_src, pts_m, left_m, right_m)
    
    # Chest: Cuirass covering chest AND abdomen + fauld + ragged green cloth tabard + chainmail skirt
    arr_t3 = np.array(m_t3)
    # Clear black background pocket between legs
    black_pocket = (Y >= 620) & (Y <= 720) & (X >= 470) & (X <= 535) & (arr_t3[:, :, 0] < 12) & (arr_t3[:, :, 1] < 12) & (arr_t3[:, :, 2] < 12)
    arr_t3[black_pocket, 3] = 0
    
    # Natural bottom contour of male T3 chest (fauld + green cloth + chainmail):
    pts_skirt_bottom = [
        (405, 540), (420, 580), (445, 638), (452, 605), (465, 622),
        (480, 625), (495, 620), (500, 605), (515, 642), (525, 660),
        (540, 642), (555, 656), (575, 646), (595, 540)
    ]
    poly_c3 = [(340, 180), (670, 180), (670, 540), (595, 540)] + list(reversed(pts_skirt_bottom)) + [(405, 540), (340, 540)]
    mask_c3 = Image.new("L", (1024, 1024), 0)
    draw_c3 = ImageDraw.Draw(mask_c3)
    draw_c3.polygon(poly_c3, fill=255)
    draw_c3.rectangle([340, 180, 425, 550], fill=255) # left arm/gauntlet
    draw_c3.rectangle([580, 180, 670, 550], fill=255) # right arm/gauntlet
    
    arr_mc3 = np.array(mask_c3)
    res_c3 = np.zeros_like(arr_t3)
    res_c3[(arr_mc3 == 255) & (arr_t3[:, :, 3] > 80)] = arr_t3[(arr_mc3 == 255) & (arr_t3[:, :, 3] > 80)]
    m_c3 = Image.fromarray(res_c3)
    
    # Legs: Isolated chainmail chausses + steel cuisses + poleyns + greaves + sabatons from belt Y >= 415 down
    arr_tl = np.array(m_t3_legs_src)
    l3_mask = (Y >= 415) & (X >= 360) & (X <= 680) & (arr_tl[:, :, 3] > 80)
    res_l3 = np.zeros_like(arr_tl)
    res_l3[l3_mask] = arr_tl[l3_mask]
    m_l3 = Image.fromarray(res_l3)
    
    return (m_c1, m_l1), (m_h2, m_c2, m_l2), (m_h3, m_c3, m_l3)

def build_female_slots():
    print("Building Female Modular Slots...")
    # T1 Gambeson
    # Chest: Fitted quilted cream doublet tucked neatly into belt at Y=420, arms down to fingertips
    arr_t1 = np.array(f_t1)
    mask_c1 = Image.new("L", (1024, 1024), 0)
    draw_c1 = ImageDraw.Draw(mask_c1)
    draw_c1.polygon([(340, 180), (430, 180), (430, 420), (430, 530), (340, 530)], fill=255) # left arm
    draw_c1.polygon([(575, 180), (665, 180), (665, 530), (575, 530)], fill=255) # right arm
    draw_c1.rectangle([420, 180, 575, 422], fill=255) # Doublet torso tucked into belt
    arr_fc1 = np.array(mask_c1)
    res_c1 = np.zeros_like(arr_t1)
    res_c1[(arr_fc1 == 255) & (arr_t1[:, :, 3] > 80)] = arr_t1[(arr_fc1 == 255) & (arr_t1[:, :, 3] > 80)]
    f_c1 = Image.fromarray(res_c1)
    
    # Legs: Quilted trousers with knee patches and boots from belt Y >= 415 down, solid thighs
    arr_l1 = np.zeros_like(arr_t1)
    l1_m = (Y >= 415) & (X >= 360) & (X <= 670) & (arr_t1[:, :, 3] > 80)
    arr_l1[l1_m] = arr_t1[l1_m]
    f_l1 = Image.fromarray(arr_l1)
    
    # T2 Cuoio
    # Helm: Stylish open-face leather helmet with winged golden brow band and cheek guards. No pauldrons!
    arr_t2 = np.array(f_t2)
    mask_h2 = Image.new("L", (1024, 1024), 0)
    draw_h2 = ImageDraw.Draw(mask_h2)
    draw_h2.polygon([
        (440, 30), (560, 30), (565, 140), (560, 195), (545, 208),
        (500, 208), (455, 208), (442, 195), (440, 140)
    ], fill=255)
    arr_fh2 = np.array(mask_h2)
    res_h2 = np.zeros_like(arr_t2)
    res_h2[(arr_fh2 == 255) & (arr_t2[:, :, 3] > 80)] = arr_t2[(arr_fh2 == 255) & (arr_t2[:, :, 3] > 80)]
    f_h2 = Image.fromarray(res_h2)
    
    # Chest: Studded hardened leather corset/bodice with pauldrons, bracers, and gloves.
    # Peplum V-belt bottom rim (Y=435 at sides, Y=458 at center V-tip). NO trousers!
    mask_c2 = Image.new("L", (1024, 1024), 0)
    draw_c2 = ImageDraw.Draw(mask_c2)
    draw_c2.polygon([(340, 180), (425, 180), (425, 435), (430, 530), (340, 530)], fill=255) # left arm
    draw_c2.polygon([(575, 180), (665, 180), (665, 530), (575, 530)], fill=255) # right arm
    draw_c2.polygon([
        (420, 180), (575, 180),
        (575, 435), (540, 442), (500, 458), (460, 442), (420, 435)
    ], fill=255) # Bodice peplum
    arr_fc2 = np.array(mask_c2)
    res_c2 = np.zeros_like(arr_t2)
    res_c2[(arr_fc2 == 255) & (arr_t2[:, :, 3] > 80)] = arr_t2[(arr_fc2 == 255) & (arr_t2[:, :, 3] > 80)]
    f_c2 = Image.fromarray(res_c2)
    
    # Legs: Studded brown leather trousers with right-thigh guard and riding boots from belt Y >= 415 down
    arr_l2 = np.zeros_like(arr_t2)
    l2_m = (Y >= 415) & (X >= 360) & (X <= 670) & (arr_t2[:, :, 3] > 80)
    arr_l2[l2_m] = arr_t2[l2_m]
    f_l2 = Image.fromarray(arr_l2)
    
    # T3 Piastre
    # Helm: Closed-visor helmet with articulated steel gorget cowl trimmed to exact bottom rim
    pts_f = [(435, 215), (448, 233), (465, 246), (485, 253), (505, 252), (525, 245), (542, 232), (555, 218), (568, 206)]
    left_f = [(410, 0), (410, 180), (430, 195)]
    right_f = [(580, 195), (580, 180), (580, 0)]
    f_h3 = make_clean_piastre_helm(f_t3_helm_src, pts_f, left_f, right_f)
    
    # Chest: Cuirass covering chest and entire abdomen, pauldrons, vambraces, gauntlets, ragged green cloth tabard
    arr_t3 = np.array(f_t3)
    black_pocket_f = (Y >= 620) & (Y <= 720) & (X >= 470) & (X <= 535) & (arr_t3[:, :, 0] < 12) & (arr_t3[:, :, 1] < 12) & (arr_t3[:, :, 2] < 12)
    arr_t3[black_pocket_f, 3] = 0
    
    pts_f_skirt_bottom = [
        (410, 520), (415, 570), (430, 595), (445, 605), (460, 625),
        (480, 642), (490, 645), (500, 625), (510, 638), (525, 605),
        (540, 620), (555, 600), (575, 560), (595, 520)
    ]
    poly_f_c3 = [(340, 180), (670, 180), (670, 520), (595, 520)] + list(reversed(pts_f_skirt_bottom)) + [(410, 520), (340, 520)]
    mask_f_c3 = Image.new("L", (1024, 1024), 0)
    draw_f_c3 = ImageDraw.Draw(mask_f_c3)
    draw_f_c3.polygon(poly_f_c3, fill=255)
    draw_f_c3.rectangle([340, 180, 425, 540], fill=255) # left arm/gauntlet
    draw_f_c3.rectangle([580, 180, 670, 540], fill=255) # right arm/gauntlet
    
    arr_fc3 = np.array(mask_f_c3)
    res_c3 = np.zeros_like(arr_t3)
    res_c3[(arr_fc3 == 255) & (arr_t3[:, :, 3] > 80)] = arr_t3[(arr_fc3 == 255) & (arr_t3[:, :, 3] > 80)]
    f_c3 = Image.fromarray(res_c3)
    
    # Legs: Chainmail chausses + steel cuisses + poleyns + greaves + sabatons from belt Y >= 415 down
    arr_tl = np.array(f_t3_legs_src)
    l3_mask = (Y >= 415) & (X >= 350) & (X <= 680) & (arr_tl[:, :, 3] > 80)
    res_l3 = np.zeros_like(arr_tl)
    res_l3[l3_mask] = arr_tl[l3_mask]
    f_l3 = Image.fromarray(res_l3)
    
    return (f_c1, f_l1), (f_h2, f_c2, f_l2), (f_h3, f_c3, f_l3)

# Build all slots
(m_c1, m_l1), (m_h2, m_c2, m_l2), (m_h3, m_c3, m_l3) = build_male_slots()
(f_c1, f_l1), (f_h2, f_c2, f_l2), (f_h3, f_c3, f_l3) = build_female_slots()

# Save all modular slots in output/armors/modular
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

# Update Official Assets in assets/art/knight/
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

# --- STANDALONE SLOTS INSPECTION SHEET ---
# Shows the isolated individual pieces (Helm, Chest, Legs) side-by-side
slot_cards = [
    ("Helm Cuoio", m_h2), ("Chest Gambeson", m_c1), ("Legs Gambeson", m_l1),
    ("Helm Piastre", m_h3), ("Chest Cuoio", m_c2), ("Legs Cuoio", m_l2),
    ("Chest Piastre (Plates+Cloth)", m_c3), ("Legs Piastre (Greaves+Mail)", m_l3)
]

slots_canvas = Image.new("RGB", (1400, 720), (14, 12, 16))
draw_s = ImageDraw.Draw(slots_canvas)
draw_s.text((30, 20), "PEZZI MODULARI SEZIONATI SINGOLARMENTE — ISPEZIONE ASSET STANDALONE", fill=(201, 162, 74))

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
