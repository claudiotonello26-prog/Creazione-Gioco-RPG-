import os
from PIL import Image, ImageDraw, ImageFont

art_dir = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
out_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\output"

f_m = Image.open(os.path.join(out_dir, "faces_male_clean.png"))
f_f = Image.open(os.path.join(out_dir, "faces_female_clean.png"))
h_m = Image.open(os.path.join(out_dir, "hair_male_clean.png"))
h_f = Image.open(os.path.join(out_dir, "hair_female_clean.png"))
b_m = Image.open(os.path.join(out_dir, "beards_male_clean.png"))

def crop_content(img, pad=10):
    bbox = img.getbbox()
    if not bbox:
        return img
    l = max(0, bbox[0] - pad)
    t = max(0, bbox[1] - pad)
    r = min(img.width, bbox[2] + pad)
    b = min(img.height, bbox[3] + pad)
    return img.crop((l, t, r, b))

sheets = [
    (crop_content(f_m), "VOLTI MASCHILI (4 Espressioni: Solare, Fiero, Severo, Calmo)"),
    (crop_content(f_f), "VOLTI FEMMINILI (4 Espressioni: Solare, Fiera, Severa, Calma)"),
    (crop_content(h_f), "CAPIGLIATURE FEMMINILI (Coda Alta, Treccia Valchiria, Bob, Lunghi Mossi, Pixie)"),
    (crop_content(h_m), "CAPIGLIATURE MASCHILI (Pompadour, Topknot/Codino, Chioma Selvaggia, Buzzcut)"),
    (crop_content(b_m), "BARBE E BAFFI MASCHILI (Baffi a Manubrio, Pizzo, Barba Piena, Barba Vichinga)")
]

# Total height
target_w = 1200
row_imgs = []
total_h = 40

for img, title in sheets:
    # Resize width to fit target_w - 40
    avail_w = target_w - 60
    scale = avail_w / img.width
    new_h = int(img.height * scale)
    if new_h > 240:
        new_h = 240
        new_w = int(img.width * (new_h / img.height))
    else:
        new_w = avail_w
    res = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    row_imgs.append((res, title, new_h))
    total_h += new_h + 60

canvas = Image.new("RGB", (target_w, total_h), (14, 12, 16))
draw = ImageDraw.Draw(canvas)

cur_y = 20
for res, title, rh in row_imgs:
    # Card background
    card_box = [20, cur_y, target_w - 20, cur_y + rh + 45]
    draw.rectangle(card_box, fill=(22, 19, 26), outline=(60, 50, 40), width=1)
    
    draw.text((35, cur_y + 10), title, fill=(201, 162, 74))
    
    # center image horizontally
    x = (target_w - res.width) // 2
    canvas.paste(res, (x, cur_y + 35), res)
    cur_y += rh + 60

out_preview = os.path.join(art_dir, "customizer_preview.jpg")
canvas.save(out_preview, quality=93)
print("Saved customizer preview to:", out_preview)
