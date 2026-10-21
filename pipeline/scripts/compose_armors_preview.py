import os
from PIL import Image, ImageDraw, ImageFont

art_dir = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
armors_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\output\armors"
bases_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\current_bases"

# Copy all clean armors to artifacts
files = [
    "male_tier1_gambeson_clean.png",
    "female_tier1_gambeson_clean.png",
    "male_tier2_cuoio_clean.png",
    "female_tier2_cuoio_clean.png",
    "male_tier3_piastre_clean.png",
    "female_tier3_piastre_clean.png"
]
for f in files:
    src = os.path.join(armors_dir, f)
    dst = os.path.join(art_dir, f)
    Image.open(src).save(dst)

# Load images
m_base = Image.open(os.path.join(bases_dir, "hero_male_base.png")).convert("RGBA")
m_t1 = Image.open(os.path.join(armors_dir, "male_tier1_gambeson_clean.png")).convert("RGBA")
m_t2 = Image.open(os.path.join(armors_dir, "male_tier2_cuoio_clean.png")).convert("RGBA")
m_t3 = Image.open(os.path.join(armors_dir, "male_tier3_piastre_clean.png")).convert("RGBA")

f_base = Image.open(os.path.join(bases_dir, "hero_female_base.png")).convert("RGBA")
f_t1 = Image.open(os.path.join(armors_dir, "female_tier1_gambeson_clean.png")).convert("RGBA")
f_t2 = Image.open(os.path.join(armors_dir, "female_tier2_cuoio_clean.png")).convert("RGBA")
f_t3 = Image.open(os.path.join(armors_dir, "female_tier3_piastre_clean.png")).convert("RGBA")

def crop_content(img, pad=15):
    bbox = img.getbbox()
    if not bbox:
        return img
    l = max(0, bbox[0] - pad)
    t = max(0, bbox[1] - pad)
    r = min(img.width, bbox[2] + pad)
    b = min(img.height, bbox[3] + pad)
    return img.crop((l, t, r, b))

males = [
    (crop_content(m_base), "BASE INIZIALE"),
    (crop_content(m_t1), "TIER 1: GAMBESON"),
    (crop_content(m_t2), "TIER 2: CUOIO BORCHIATO"),
    (crop_content(m_t3), "TIER 3: PIASTRE & MAGLIA")
]

females = [
    (crop_content(f_base), "BASE INIZIALE"),
    (crop_content(f_t1), "TIER 1: GAMBESON"),
    (crop_content(f_t2), "TIER 2: CUOIO BORCHIATO"),
    (crop_content(f_t3), "TIER 3: PIASTRE & MAGLIA")
]

target_h = 580
col_w = 340
total_w = col_w * 4 + 60
row_h = target_h + 80
total_h = row_h * 2 + 50

canvas = Image.new("RGB", (total_w, total_h), (14, 12, 16))
draw = ImageDraw.Draw(canvas)

# Row 1: Males
draw.text((30, 20), "PROGRESSIONE ARMATURE — EROE MASCHIO (ATLETICO & MASCOLINO)", fill=(201, 162, 74))
for idx, (img, title) in enumerate(males):
    w = int(img.width * (target_h / img.height))
    res = img.resize((w, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = 50
    # card background
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 15, y + 10), title, fill=(180, 150, 100))
    # paste centered in card
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

# Row 2: Females
y_start_f = row_h + 35
draw.text((30, y_start_f), "PROGRESSIONE ARMATURE — EROINA FEMMINA (SENSUALE & LETALE)", fill=(201, 162, 74))
for idx, (img, title) in enumerate(females):
    w = int(img.width * (target_h / img.height))
    res = img.resize((w, target_h), Image.Resampling.LANCZOS)
    x = 30 + idx * col_w
    y = y_start_f + 30
    draw.rectangle([x, y, x + col_w - 20, y + target_h + 30], fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    draw.text((x + 15, y + 10), title, fill=(180, 150, 100))
    px = x + (col_w - 20 - res.width) // 2
    canvas.paste(res, (px, y + 30), res)

out_preview = os.path.join(art_dir, "armors_progression_preview.jpg")
canvas.save(out_preview, quality=94)
print("Saved armor progression preview to:", out_preview)
