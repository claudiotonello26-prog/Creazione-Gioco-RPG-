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
NODES_DIR = os.path.join(REPO_DIR, "assets", "art", "nodes")

# 1. API Key
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
    "CRITICAL BACKGROUND RULE: Flat solid magenta background #FF00FF filling the entire canvas from edge to edge. "
    "Pure solid uniform magenta #FF00FF background only. Absolutely NEVER use any magenta, fuchsia, or pink on the subject, skin, clothes, props, or effects. "
    "No text, no watermark, no frame, no borders, no ground shadow plate, no UI."
)

TARGETS = {
    "general_store": {
        "type": "npc",
        "file": os.path.join(NPC_DIR, "general_store.png"),
        "name": "Berta of the General Store",
        "framing": (
            "Framing: head and upper chest bust only (cut cleanly at mid-chest, just under the shoulders). "
            "Front-facing towards the camera/viewer (or very slight three-quarter angle), eyes looking straight into the camera / at the player with a warm, friendly and welcoming smile. "
            "Head positioned in the upper half of the canvas with a little space above the head, shoulders broad and filling the canvas width. "
            "Light source from the upper left. Weathered, believable person of a grim medieval world, warm and inviting shopkeeper, not a hero, not a monster. "
            "Clothes are worn and practical: no shiny armour, no rust, nothing dark or corrupted."
        ),
        "desc": (
            "Berta of the General Store. Woman in her fifties, round friendly face with a very warm, kind, and welcoming smile, eyes looking directly at the viewer/screen with friendly warmth. "
            "She wears a SOLID, FULLY PAINTED rustic dark red cloth bandana / headscarf (rich dark red-crimson cloth #8B2522, #9C332E) tied neatly over her hair. "
            "CRITICAL REQUIREMENT FOR THE HEADSCARF: The red bandana/headscarf covers the top of her head neatly and is COMPLETELY, SOLIDLY PAINTED in rich weathered red fabric with dark inked cloth folds. "
            "There are absolutely NO missing red spots, NO white gaps, NO transparent holes, NO unpainted patches, and NO errors on the red headscarf. The red cloth is fully and evenly colored. "
            "Grey-streaked chestnut hair peeking out neatly around the edges of the red headscarf. "
            "Small circular brass spectacles perched neatly on the bridge of her nose, friendly sparkling eyes behind them. "
            "Wearing a practical cream linen blouse, a coarse brown wool shawl draped over her shoulders, a sturdy leather apron strap over one shoulder, "
            "a carpenter's wooden pencil tucked behind her ear, and a small ring of brass keys hanging at the collar. "
            "Completely solid painted surfaces, no white noise specks, clean inked outlines, rich but muted medieval colours. "
            "Warm weathered colours strictly: rustic dark red cloth, cream linen, brown wool, brass metal, warm natural skin tones."
        )
    },
    "ash_wood": {
        "type": "node",
        "file": os.path.join(NODES_DIR, "ash_wood.png"),
        "name": "Ash Tree Woodcutting Node",
        "framing": (
            "Framing: ONE gathering node object, whole and centered, slightly from the side, filling about 85% of the canvas. "
            "Sitting on a small circular patch of its own ground (ash-covered soil and small stones) that fades out naturally at the edges with no hard square frame. "
            "No wide landscape, no horizon. Entire object surrounded by solid magenta #FF00FF background."
        ),
        "desc": (
            "Ash tree woodcutting node. Whole small gnarled ash tree with a twisted pale grey-white bark trunk and branches. "
            "CRITICAL LEAF COLOUR: The foliage leaves are painted in a very soft, pale, muted, desaturated light green leaning towards pale light grey ash (foglie di un verde molto chiaro chiaro spento tendente alla cenere chiara grigia, pale sage-ash green). "
            "The leaves are definitely NOT pure white and NOT bone white; they have a distinct soft muted pale greenish-ash tint. "
            "Sitting on a small isolated circular mound of earth dusted with powdery pale grey ash and small grey stones. "
            "Inked outlines, dark fantasy souls-like painterly style. "
            "Colours strictly: pale muted light green-ash leaves, pale grey-white bark trunk, weathered stone grey, powdery pale grey ash on the ground."
        )
    }
}

def generate_raw(item_id, info):
    parts = []
    for ref in CACHED_REFS:
        parts.append({"text": f"Style Reference ({ref['name']}): Match this dark fantasy inking and painterly shading style:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
        
    full_prompt = (
        f"{GLOBAL_STYLE_INSTRUCTION}\n\n"
        f"SUBJECT: {info['name']}\n"
        f"{info['framing']}\n"
        f"DETAILS: {info['desc']}"
    )
    parts.append({"text": full_prompt})
    
    payload = {"contents": [{"parts": parts}]}
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_KEY
    }
    
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    for attempt in range(3):
        try:
            print(f"[{item_id}] Calling Gemini API (attempt {attempt+1})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        raw_path = os.path.join(RAW_DIR, f"{item_id}.png")
                        with open(raw_path, "wb") as f_out:
                            f_out.write(raw_bytes)
                        print(f"[{item_id}] Raw image saved -> {raw_path}")
                        return raw_path, full_prompt
        except Exception as e:
            print(f"[{item_id}] Attempt {attempt+1} failed: {e}")
            time.sleep(3)
    return None, full_prompt

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

def process_cutout(raw_path, item_type="node", target_size=512):
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
                # Ensure we only flood-fill true magenta pockets, not red bandana!
                # Magenta has high blue (b > 60) and hue close to bgc
                dh_pocket = np.abs(((hue(m_color) - hue(bgc)) + 180) % 360 - 180)
                if dh_pocket < 20 and m_color[2] > 70 and m_color[0] > 120 and m_color[1] < 100:
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
        raise ValueError(f"No object found in {raw_path}")
        
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    obj_crop = im_clean[y0:y1, x0:x1]
    alpha_crop = alpha[y0:y1, x0:x1]
    rgba_crop = np.dstack([obj_crop.astype(np.uint8), alpha_crop.astype(np.uint8)])
    crop_img = Image.fromarray(rgba_crop, "RGBA")
    
    obj_w, obj_h = crop_img.size
    final_canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    if item_type == "npc":
        target_w = int(round(target_size * 0.94))
        scale = target_w / float(obj_w)
        new_w = target_w
        new_h = int(round(obj_h * scale))
        if new_h > target_size:
            scale = target_size / float(obj_h)
            new_h = target_size
            new_w = int(round(obj_w * scale))
            
        resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        paste_x = (target_size - new_w) // 2
        paste_y = target_size - new_h
        final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
    else:
        max_dim = max(obj_w, obj_h)
        target_obj_dim = int(round(target_size * 0.85))
        scale = target_obj_dim / float(max_dim)
        new_w = max(1, int(round(obj_w * scale)))
        new_h = max(1, int(round(obj_h * scale)))
        
        resized_obj = crop_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        paste_x = (target_size - new_w) // 2
        paste_y = (target_size - new_h) // 2
        final_canvas.paste(resized_obj, (paste_x, paste_y), resized_obj)
        
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
    for item_id, info in TARGETS.items():
        print(f"\n=== GENERATING {item_id} ===")
        raw_p, prompt = generate_raw(item_id, info)
        if not raw_p:
            print(f"FAILED TO GENERATE {item_id}")
            continue
        final_img, pk = process_cutout(raw_p, item_type=info["type"])
        final_img.save(info["file"], "PNG")
        print(f"Delivered {info['file']} (pink_pixels={pk})")
