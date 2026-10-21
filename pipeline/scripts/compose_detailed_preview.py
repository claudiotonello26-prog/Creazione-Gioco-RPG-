import os
from PIL import Image, ImageDraw, ImageFont

art_dir = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
curr_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\current_bases"
new_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\new_bases"

male_idle = Image.open(os.path.join(curr_dir, "hero_male_base.png")).convert("RGBA")
male_atk = Image.open(os.path.join(new_dir, "hero_male_attack_base.png")).convert("RGBA")
fem_idle = Image.open(os.path.join(curr_dir, "hero_female_base.png")).convert("RGBA")
fem_atk = Image.open(os.path.join(new_dir, "hero_female_attack_base.png")).convert("RGBA")

def crop_to_content(img, pad=20):
    bbox = img.getbbox()
    if not bbox:
        return img
    l = max(0, bbox[0] - pad)
    t = max(0, bbox[1] - pad)
    r = min(img.width, bbox[2] + pad)
    b = min(img.height, bbox[3] + pad)
    return img.crop((l, t, r, b))

m_i_c = crop_to_content(male_idle)
m_a_c = crop_to_content(male_atk)
f_i_c = crop_to_content(fem_idle)
f_a_c = crop_to_content(fem_atk)

# Create high-res 2x2 or 4-in-a-row display
# Height 800
target_h = 750
items = [
    (m_i_c, "MALE HERO - IDLE (APPROVATO)"),
    (m_a_c, "MALE HERO - ATTACCO (NUOVO)"),
    (f_i_c, "FEMALE HERO - IDLE (APPROVATA)"),
    (f_a_c, "FEMALE HERO - ATTACCO (NUOVO)")
]

scaled = []
total_w = 0
for img, title in items:
    w = int(img.width * (target_h / img.height))
    res = img.resize((w, target_h), Image.Resampling.LANCZOS)
    scaled.append((res, title))
    total_w += w + 40

grid = Image.new("RGB", (total_w + 40, target_h + 90), (14, 12, 16))
draw = ImageDraw.Draw(grid)

cur_x = 30
for img, title in scaled:
    # background card
    card_box = [cur_x - 10, 50, cur_x + img.width + 10, 50 + target_h + 10]
    draw.rectangle(card_box, fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    
    grid.paste(img, (cur_x, 55), img)
    draw.text((cur_x, 20), title, fill=(201, 162, 74))
    cur_x += img.width + 40

out_path = os.path.join(art_dir, "hero_roster_detailed.jpg")
grid.save(out_path, quality=94)
print("Detailed roster preview saved:", out_path)
