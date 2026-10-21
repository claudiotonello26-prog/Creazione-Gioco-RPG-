import os
from PIL import Image, ImageDraw, ImageFont

art_dir = r"C:\Users\pissio\.gemini\antigravity\brain\6b006a30-bc2b-405b-8416-cc5d1029fff3"
curr_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\current_bases"
new_dir = r"C:\Users\pissio\Creazione-Gioco-RPG-\pipeline\new_bases"

male_idle = Image.open(os.path.join(curr_dir, "hero_male_base.png")).convert("RGBA")
male_atk = Image.open(os.path.join(new_dir, "hero_male_attack_base.png")).convert("RGBA")
fem_idle = Image.open(os.path.join(curr_dir, "hero_female_base.png")).convert("RGBA")
fem_atk = Image.open(os.path.join(new_dir, "hero_female_attack_base.png")).convert("RGBA")

# Copy PNGs to artifact dir
male_atk.save(os.path.join(art_dir, "hero_male_attack_base.png"))
fem_atk.save(os.path.join(art_dir, "hero_female_attack_base.png"))

# Make 4-column side-by-side comparison: 4 * 450 x 700 + header
W, H = 450, 650
grid = Image.new("RGB", (W * 4, H + 60), (18, 16, 21))
draw = ImageDraw.Draw(grid)

panels = [
    (male_idle, "EROE UOMO (IDLE)"),
    (male_atk, "EROE UOMO (ATTACCO)"),
    (fem_idle, "EROINA DONNA (IDLE)"),
    (fem_atk, "EROINA DONNA (ATTACCO)")
]

for idx, (img, title) in enumerate(panels):
    im_ratio = img.width / img.height
    target_h = H - 20
    target_w = int(target_h * im_ratio)
    if target_w > W:
        target_w = W
        target_h = int(target_w / im_ratio)
    
    resized = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    x = idx * W + (W - target_w) // 2
    y = 50 + (H - target_h) // 2
    grid.paste(resized, (x, y), resized)
    
    draw.text((idx * W + 40, 18), title, fill=(201, 162, 74))

preview_path = os.path.join(art_dir, "attack_bases_preview.jpg")
grid.save(preview_path, quality=92)
print("Successfully saved preview and images to artifact directory:", preview_path)
