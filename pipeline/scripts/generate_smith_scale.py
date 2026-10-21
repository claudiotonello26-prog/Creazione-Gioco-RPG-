import os
import sys
import io
import time
import json
import base64
import urllib.request
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

REPO_DIR = r"C:\Users\pissio\Creazione-Gioco-RPG-"
PIPELINE_DIR = os.path.join(REPO_DIR, "pipeline")
RAW_DIR = os.path.join(r"C:\Users\pissio\iron-oath-art", "raw_nodes_npcs")
NPC_DIR = os.path.join(REPO_DIR, "assets", "art", "npc")

GEMINI_KEY = os.environ.get("GEMINI_API_KEY")
if not GEMINI_KEY:
    env_p = os.path.join(PIPELINE_DIR, ".env")
    if os.path.exists(env_p):
        with open(env_p, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("GEMINI_API_KEY="):
                    GEMINI_KEY = line.strip().split("=", 1)[1]
                    break

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

REF_PATHS = [
    os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "enemies", "hollow_goblin_idle.png"),
]

def load_ref_b64(path, max_dim=512):
    im = Image.open(path)
    im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

CACHED_REFS = []
for rp in REF_PATHS:
    if os.path.exists(rp):
        CACHED_REFS.append({
            "name": os.path.basename(rp),
            "b64": load_ref_b64(rp)
        })

GLOBAL_STYLE_INSTRUCTION = (
    "STYLE REFERENCES: Match the painting technique, inked outlines, level of detail, textural brushwork, "
    "and lighting of these reference images, but draw a completely different subject and use ONLY the colours written in this prompt.\n"
    "Aesthetic: Hand-painted dark fantasy illustration, souls-like mobile game art style (Dark Souls, Elden Ring, Gym Oath). "
    "Bold expressive black ink outlines defining the outer silhouette and internal anatomy/folds/crevices. "
    "Painterly cel-shading with rich but muted weathered colours, deep charcoal shadows (#0D0B09), warm antique gold rim light (#C9A24A), "
    "high contrast, sharp graphic readability even when scaled down to a small thumbnail. "
    "NO 3D CGI, no photographic skin, no smooth airbrushing, no flat cartoon, no anime, no modern elements.\n"
    "CRITICAL BACKGROUND RULE: Flat solid uniform magenta background #FF00FF filling the entire canvas from edge to edge. "
    "Pure solid uniform magenta #FF00FF background only. Absolutely NEVER use any magenta, fuchsia, or pink on the subject, skin, clothes, props, or effects. "
    "No text, no watermark, no frame, no borders, no ground shadow plate, no UI."
)

SMITH_PROMPT = (
    f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
    "SUBJECT: Master Gorran the Blacksmith (Large Close-Up Bust)\n"
    "FRAMING & SCALE (CRITICAL): Large close-up bust portrait filling the canvas height and width! "
    "The head and face are large and prominent: the top of his rounded bald head is positioned in the upper portion of the canvas near the top edge, "
    "with only a tiny breathing space above his skull. "
    "The portrait is cut cleanly at mid-chest (just under the collarbones and broad shoulders), exactly like a classic RPG character portrait bust. "
    "Do NOT zoom out, do NOT show down to the waist or hips, do NOT leave large empty gaps above the head. "
    "Broad powerful shoulders completely fill the canvas width from left to right edge.\n"
    "DETAILS: Big bald man in his forties, hearty friendly jovial smile, warm kind eyes looking directly straight into the camera / at the viewer, "
    "thick braided red-brown beard with a few singed hairs. "
    "Black soot smudges on his forehead and rugged muscular cheeks, thick powerful neck. "
    "Heavy leather apron over a sleeveless sweat-darkened coarse grey shirt. "
    "He raises his thick muscular, hairy, soot-stained arm to firmly grip and hold the heavy iron blacksmith tongs resting securely over his shoulder with his hand. "
    "Glow of the forge lighting him warm forge orange from below on one side. Welcoming master craftsman greeting the player warmly. "
    "Colours strictly: steel grey, leather brown, forge orange, natural ruddy weathered skin tones. Bold black inked outlines."
)

def generate_smith(index=1):
    parts = []
    for ref in CACHED_REFS:
        parts.append({"text": f"Style Reference ({ref['name']}): Match this dark fantasy inking and painterly shading style:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
    parts.append({"text": SMITH_PROMPT})
    
    payload = {"contents": [{"parts": parts}]}
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    print(f"Calling Gemini for Smith candidate {index}...")
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        for p in data["candidates"][0]["content"]["parts"]:
            if "inlineData" in p:
                raw_bytes = base64.b64decode(p["inlineData"]["data"])
                raw_path = os.path.join(RAW_DIR, f"smith_candidate_{index}.png")
                with open(raw_path, "wb") as f_out:
                    f_out.write(raw_bytes)
                print(f"Candidate {index} saved -> {raw_path}")
                return raw_path
    return None

def hue(c):
    c = np.asarray(c, dtype=float)
    return np.degrees(np.arctan2(np.sqrt(3) * (c[..., 1] - c[..., 2]), 2 * c[..., 0] - c[..., 1] - c[..., 2]))

def count_pink_pixels(img_rgba, bgc=np.array([255.0, 0.0, 255.0])):
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    h = hue(ar[..., :3])
    dh = np.abs(((h - hue(bgc)) + 180) % 360 - 180)
    chroma = ar[..., :3].max(-1) - ar[..., :3].min(-1)
    pink = (a > 20) & (dh < 24) & (chroma > 80) & (r > g + 40) & (b > g + 20)
    return int(pink.sum())

def process_smith_cutout(raw_path, target_size=512):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.asarray(im_pil, dtype=float)
    
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
    
    bgish = (dh < 30) & (sat > 0.22) & (r > 120) & (b > 65) & (g < 110)
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                dh_pocket = np.abs(((hue(m_color) - hue(bgc)) + 180) % 360 - 180)
                if dh_pocket < 20 and m_color[2] > 60 and m_color[0] > 110 and m_color[1] < 100:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # Outer halo strip
    for _ in range(5):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_dh = dh[edge]
        edge_r = r[edge]
        edge_g = g[edge]
        edge_b = b[edge]
        is_halo = (edge_dh < 35) & (edge_r > edge_g + 15) & (edge_b > edge_g + 8)
        edge_to_strip = np.zeros_like(obj)
        edge_to_strip[edge] = is_halo
        if not edge_to_strip.any():
            break
        obj &= ~edge_to_strip
        
    im_clean = im.copy()
    for _ in range(2):
        edge_outer = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_pinkish = edge_outer & (dh < 40) & (im_clean[..., 0] > im_clean[..., 1] + 8) & (im_clean[..., 2] > im_clean[..., 1] + 5)
        im_clean[edge_pinkish, 0] = np.minimum(im_clean[edge_pinkish, 0], im_clean[edge_pinkish, 1] + 5)
        im_clean[edge_pinkish, 2] = np.minimum(im_clean[edge_pinkish, 2], im_clean[edge_pinkish, 1] + 5)
    
    alpha = np.where(obj, 255.0, 0.0)
    ys, xs = np.nonzero(obj)
    if len(ys) == 0:
        raise ValueError("No object found")
        
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_crop = im_clean[y0:y1, x0:x1]
    alpha_crop = alpha[y0:y1, x0:x1]
    rgba_crop = np.dstack([obj_crop.astype(np.uint8), alpha_crop.astype(np.uint8)])
    crop_img = Image.fromarray(rgba_crop, "RGBA")
    
    obj_w, obj_h = crop_img.size
    print(f"Raw cut crop dimensions: width={obj_w}, height={obj_h}, aspect={obj_w/obj_h:.2f}")
    
    # Scaling strategy for NPC bust:
    # We want height to be around 495-512 px, with top around y=0..15, and width <= 495 px.
    # If the bust is wider, we scale by height (e.g. height = 505) and center horizontally,
    # or scale so max(w, h) fits properly without dwarfing the character.
    target_h = int(round(target_size * 0.98))  # ~502 px
    scale_by_h = target_h / float(obj_h)
    
    target_w = int(round(target_size * 0.94))  # ~481 px
    scale_by_w = target_w / float(obj_w)
    
    # Use the scale that makes the head large enough:
    # If scaling by width makes height < 460, scale by height instead so the character is NOT tiny!
    if obj_h * scale_by_w < 460:
        # Scale by height!
        scale = scale_by_h
        new_h = target_h
        new_w = int(round(obj_w * scale))
    else:
        scale = min(scale_by_w, scale_by_h)
        new_w = int(round(obj_w * scale))
        new_h = int(round(obj_h * scale))
        
    resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    final_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    paste_x = (target_size - new_w) // 2
    paste_y = target_size - new_h
    
    final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
    
    # Ensure pink pixels = 0
    pk = count_pink_pixels(final_canvas)
    if pk > 0:
        arr_fin = np.asarray(final_canvas).copy().astype(float)
        r_f, g_f, b_f, a_f = arr_fin[..., 0], arr_fin[..., 1], arr_fin[..., 2], arr_fin[..., 3]
        h_f = hue(arr_fin[..., :3])
        dh_f = np.abs(((h_f - hue(bgc)) + 180) % 360 - 180)
        chroma_f = arr_fin[..., :3].max(-1) - arr_fin[..., :3].min(-1)
        pink_f = (a_f > 20) & (dh_f < 24) & (chroma_f > 80) & (r_f > g_f + 40) & (b_f > g_f + 20)
        arr_fin[pink_f, 0] = np.maximum(0, arr_fin[pink_f, 1] + 15)
        arr_fin[pink_f, 2] = np.maximum(0, arr_fin[pink_f, 1] + 15)
        final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
        pk = count_pink_pixels(final_canvas)
        
    return final_canvas, pk

if __name__ == "__main__":
    for i in range(1, 3):
        raw_p = generate_smith(i)
        if raw_p:
            final_img, pk = process_smith_cutout(raw_p)
            out_test = os.path.join(REPO_DIR, f"test_smith_candidate_{i}.png")
            final_img.save(out_test, "PNG")
            
            # Check stats
            arr = np.array(final_img)
            a = arr[..., 3]
            ys, xs = np.nonzero(a > 50)
            print(f"Candidate {i} final: height={ys.max()-ys.min()+1}, top={ys.min()}, solid={np.sum(a > 50)}, pink={pk}")
