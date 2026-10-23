"""Generation and Processing Pipeline for 'Gym Oath' Exercise Demonstrations.
Batch: 56 exercise demo frames (28 pairs of _a and _b).
Deliver: 512x512 RGBA cutouts at assets/art/demos/<exercise>_a.png and _b.png
Check Sheet: check_demos.png on #7F7A70 and #0D0B09
"""

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
IRON_DIR = r"C:\Users\pissio\iron-oath-art"
RAW_DIR = os.path.join(IRON_DIR, "raw")
DEMOS_DIR = os.path.join(REPO_DIR, "assets", "art", "demos")
IRON_DEMOS_DIR = os.path.join(IRON_DIR, "assets", "art", "demos")

MANIFEST_ROOT = os.path.join(REPO_DIR, "manifest.json")
MANIFEST_ART = os.path.join(REPO_DIR, "assets", "art", "manifest.json")
MANIFEST_IRON = os.path.join(IRON_DIR, "manifest.json")
ASSETS_LIST_IRON = os.path.join(IRON_DIR, "assets_list.json")

CHECK_IMAGE_IRON = os.path.join(IRON_DIR, "check_demos.png")
CHECK_IMAGE_ROOT = os.path.join(REPO_DIR, "check_demos.png")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(DEMOS_DIR, exist_ok=True)
os.makedirs(IRON_DEMOS_DIR, exist_ok=True)

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

if not GEMINI_KEY:
    raise ValueError("GEMINI_API_KEY not found!")

API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={GEMINI_KEY}"

# 2. Style Reference Images
CREATURE_REF_PATHS = [
    os.path.join(REPO_DIR, "assets", "art", "enemies", "anvil_golem_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "bosses", "living_bellows_idle.png"),
    os.path.join(REPO_DIR, "assets", "art", "enemies", "hollow_goblin_idle.png"),
]

def load_image_b64(path, max_dim=768):
    im = Image.open(path)
    if max(im.size) > max_dim:
        im.thumbnail((max_dim, max_dim), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

CACHED_CREATURE_REFS = []
for rp in CREATURE_REF_PATHS:
    if os.path.exists(rp):
        CACHED_CREATURE_REFS.append({
            "name": os.path.basename(rp),
            "b64": load_image_b64(rp)
        })
print(f"Loaded {len(CACHED_CREATURE_REFS)} creature style references.")

# 3. Global Style Instructions
STYLE_INSTRUCTION = (
    "Gym Oath is a dark fantasy medieval fitness RPG for phones, souls-like style (Dark Souls, Elden Ring): "
    "ruined gothic world, ash, stone, iron, warm antique gold as the only bright colour.\n"
    "Hand-painted dark fantasy illustration, bold inked outlines, rich but muted colours, soft rim light, "
    "readable even as a small thumbnail. No text, no letters, no frame, no UI, no watermark.\n"
    "CRITICAL BACKGROUND RULE: Flat solid magenta background #FF00FF filling the entire canvas: "
    "no shadows, gradients, floor, smoke, particles or glow spreading on the background. "
    "Nothing of the subject is magenta or pink. Glows and smoke stay tight and opaque around the subject.\n"
    "COMPOSITION & ALIGNMENT RULE: The hero stands or lies on an imaginary floor line at about 90% of the image height, "
    "so all demos line up across the game. Absolutely NO floor drawn, no ground line drawn, no shadows on the background.\n"
    "ARMOR & PROPS: Base gear is worn but never rusty. When props (chair, box, dumbbells) are used, keep them sturdy, worn dark wood and forged iron.\n"
    "ONE subject per generation, no sheets, no variants side by side."
)

DEMO_ITEMS = [
  {"id": "demo_push_up_a", "file": "assets/art/demos/push_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a push-up: high plank on straight arms, body in a straight line."},
  {"id": "demo_push_up_b", "file": "assets/art/demos/push_up_b.png", "type": "demo", "size": 512, "from": "demo_push_up_a", "prompt": "Second position of the same exercise: the bottom of the push-up: chest just above the floor, elbows bent at about 45 degrees."},
  {"id": "demo_knee_push_up_a", "file": "assets/art/demos/knee_push_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a knee push-up: knees on the floor, arms straight, body straight from knees to head."},
  {"id": "demo_knee_push_up_b", "file": "assets/art/demos/knee_push_up_b.png", "type": "demo", "size": 512, "from": "demo_knee_push_up_a", "prompt": "Second position of the same exercise: the bottom of the knee push-up: chest near the floor, elbows bent."},
  {"id": "demo_incline_push_up_a", "file": "assets/art/demos/incline_push_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: an incline push-up with hands on a wooden chair seat, arms straight, body straight."},
  {"id": "demo_incline_push_up_b", "file": "assets/art/demos/incline_push_up_b.png", "type": "demo", "size": 512, "from": "demo_incline_push_up_a", "prompt": "Second position of the same exercise: the bottom of the incline push-up: chest close to the chair edge, elbows bent."},
  {"id": "demo_pike_push_up_a", "file": "assets/art/demos/pike_push_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a pike push-up start: hips high in an inverted V, arms straight."},
  {"id": "demo_pike_push_up_b", "file": "assets/art/demos/pike_push_up_b.png", "type": "demo", "size": 512, "from": "demo_pike_push_up_a", "prompt": "Second position of the same exercise: the bottom of the pike push-up: elbows bent, top of the head close to the floor, hips still high."},
  {"id": "demo_dip_a", "file": "assets/art/demos/dip_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a chair dip: hands on the edge of a wooden chair behind him, arms straight, legs extended forward."},
  {"id": "demo_dip_b", "file": "assets/art/demos/dip_b.png", "type": "demo", "size": 512, "from": "demo_dip_a", "prompt": "Second position of the same exercise: the bottom of the chair dip: elbows bent to 90 degrees, hips lowered."},
  {"id": "demo_floor_press_a", "file": "assets/art/demos/floor_press_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a dumbbell floor press: lying on his back, knees bent, two dumbbells pressed up with straight arms."},
  {"id": "demo_floor_press_b", "file": "assets/art/demos/floor_press_b.png", "type": "demo", "size": 512, "from": "demo_floor_press_a", "prompt": "Second position of the same exercise: the bottom of the floor press: upper arms resting on the floor, dumbbells at chest level."},
  {"id": "demo_row_a", "file": "assets/art/demos/row_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a one-arm dumbbell row: torso bent forward and flat, knees soft, dumbbell hanging from a straight arm."},
  {"id": "demo_row_b", "file": "assets/art/demos/row_b.png", "type": "demo", "size": 512, "from": "demo_row_a", "prompt": "Second position of the same exercise: the top of the row: dumbbell pulled to the hip, elbow high behind the back."},
  {"id": "demo_superman_a", "file": "assets/art/demos/superman_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying face down, arms stretched forward on the floor, legs straight."},
  {"id": "demo_superman_b", "file": "assets/art/demos/superman_b.png", "type": "demo", "size": 512, "from": "demo_superman_a", "prompt": "Second position of the same exercise: the superman hold: arms, chest and legs lifted off the floor."},
  {"id": "demo_crunch_a", "file": "assets/art/demos/crunch_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying on his back, knees bent, feet flat, hands touching the sides of his helmet."},
  {"id": "demo_crunch_b", "file": "assets/art/demos/crunch_b.png", "type": "demo", "size": 512, "from": "demo_crunch_a", "prompt": "Second position of the same exercise: the crunch: shoulders and upper back curled off the floor."},
  {"id": "demo_leg_raise_a", "file": "assets/art/demos/leg_raise_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying on his back, legs straight and together just above the floor, hands under the hips."},
  {"id": "demo_leg_raise_b", "file": "assets/art/demos/leg_raise_b.png", "type": "demo", "size": 512, "from": "demo_leg_raise_a", "prompt": "Second position of the same exercise: the leg raise: straight legs lifted to vertical."},
  {"id": "demo_plank_a", "file": "assets/art/demos/plank_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a forearm plank: forearms on the floor, body in a perfect straight line."},
  {"id": "demo_plank_b", "file": "assets/art/demos/plank_b.png", "type": "demo", "size": 512, "from": "demo_plank_a", "prompt": "Second position of the same exercise: the same forearm plank, core braced, shown from the same angle (very small difference: slightly tighter, gaze down)."},
  {"id": "demo_v_up_a", "file": "assets/art/demos/v_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying flat on his back, arms stretched overhead, legs straight."},
  {"id": "demo_v_up_b", "file": "assets/art/demos/v_up_b.png", "type": "demo", "size": 512, "from": "demo_v_up_a", "prompt": "Second position of the same exercise: the V-up: torso and straight legs lifted together, hands reaching the shins in a V shape."},
  {"id": "demo_russian_twist_a", "file": "assets/art/demos/russian_twist_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a Russian twist: seated, leaning back, feet off the floor, hands together turned to his left side."},
  {"id": "demo_russian_twist_b", "file": "assets/art/demos/russian_twist_b.png", "type": "demo", "size": 512, "from": "demo_russian_twist_a", "prompt": "Second position of the same exercise: the Russian twist turned to his right side."},
  {"id": "demo_squat_a", "file": "assets/art/demos/squat_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing tall, feet shoulder width apart, arms relaxed."},
  {"id": "demo_squat_b", "file": "assets/art/demos/squat_b.png", "type": "demo", "size": 512, "from": "demo_squat_a", "prompt": "Second position of the same exercise: the bottom of a deep bodyweight squat: thighs parallel to the floor, arms forward for balance, back straight."},
  {"id": "demo_lunge_a", "file": "assets/art/demos/lunge_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing tall, feet together, hands on hips."},
  {"id": "demo_lunge_b", "file": "assets/art/demos/lunge_b.png", "type": "demo", "size": 512, "from": "demo_lunge_a", "prompt": "Second position of the same exercise: the bottom of a forward lunge: front knee at 90 degrees, back knee just above the floor, torso upright."},
  {"id": "demo_glute_bridge_a", "file": "assets/art/demos/glute_bridge_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying on his back, knees bent, feet flat, arms on the floor."},
  {"id": "demo_glute_bridge_b", "file": "assets/art/demos/glute_bridge_b.png", "type": "demo", "size": 512, "from": "demo_glute_bridge_a", "prompt": "Second position of the same exercise: the glute bridge: hips lifted so knees, hips and shoulders form a straight line."},
  {"id": "demo_step_up_a", "file": "assets/art/demos/step_up_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: in front of a sturdy wooden box, one foot placed on top of it."},
  {"id": "demo_step_up_b", "file": "assets/art/demos/step_up_b.png", "type": "demo", "size": 512, "from": "demo_step_up_a", "prompt": "Second position of the same exercise: standing on top of the wooden box on one leg, the other knee lifted."},
  {"id": "demo_jumping_jack_a", "file": "assets/art/demos/jumping_jack_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing with feet together and arms at his sides."},
  {"id": "demo_jumping_jack_b", "file": "assets/art/demos/jumping_jack_b.png", "type": "demo", "size": 512, "from": "demo_jumping_jack_a", "prompt": "Second position of the same exercise: mid jumping jack: feet wide apart and arms raised overhead."},
  {"id": "demo_high_knees_a", "file": "assets/art/demos/high_knees_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: running on the spot: left knee driven up to hip height, right arm forward."},
  {"id": "demo_high_knees_b", "file": "assets/art/demos/high_knees_b.png", "type": "demo", "size": 512, "from": "demo_high_knees_a", "prompt": "Second position of the same exercise: running on the spot: right knee driven up to hip height, left arm forward."},
  {"id": "demo_mountain_climber_a", "file": "assets/art/demos/mountain_climber_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: a mountain climber: high plank, left knee pulled toward the chest."},
  {"id": "demo_mountain_climber_b", "file": "assets/art/demos/mountain_climber_b.png", "type": "demo", "size": 512, "from": "demo_mountain_climber_a", "prompt": "Second position of the same exercise: a mountain climber: high plank, right knee pulled toward the chest."},
  {"id": "demo_burpee_a", "file": "assets/art/demos/burpee_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing tall, ready to drop."},
  {"id": "demo_burpee_b", "file": "assets/art/demos/burpee_b.png", "type": "demo", "size": 512, "from": "demo_burpee_a", "prompt": "Second position of the same exercise: the burpee floor phase: high plank on straight arms."},
  {"id": "demo_jump_squat_a", "file": "assets/art/demos/jump_squat_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: the bottom of a squat, arms swung back, ready to jump."},
  {"id": "demo_jump_squat_b", "file": "assets/art/demos/jump_squat_b.png", "type": "demo", "size": 512, "from": "demo_jump_squat_a", "prompt": "Second position of the same exercise: mid jump: body fully extended in the air, feet off the ground, arms overhead."},
  {"id": "demo_forward_fold_a", "file": "assets/art/demos/forward_fold_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing tall, feet hip width apart, arms relaxed at his sides."},
  {"id": "demo_forward_fold_b", "file": "assets/art/demos/forward_fold_b.png", "type": "demo", "size": 512, "from": "demo_forward_fold_a", "prompt": "Second position of the same exercise: the standing forward fold: hinged at the hips, legs almost straight, torso hanging down, hands reaching the shins or the floor."},
  {"id": "demo_lunge_hold_a", "file": "assets/art/demos/lunge_hold_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: standing tall, feet together, hands on hips."},
  {"id": "demo_lunge_hold_b", "file": "assets/art/demos/lunge_hold_b.png", "type": "demo", "size": 512, "from": "demo_lunge_hold_a", "prompt": "Second position of the same exercise: the lunge hold: deep static lunge, front knee at 90 degrees, back knee just above the floor, torso upright, hands on hips, calm and steady."},
  {"id": "demo_butterfly_a", "file": "assets/art/demos/butterfly_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: seated on the floor, back straight, legs stretched forward, hands on the knees."},
  {"id": "demo_butterfly_b", "file": "assets/art/demos/butterfly_b.png", "type": "demo", "size": 512, "from": "demo_butterfly_a", "prompt": "Second position of the same exercise: the butterfly stretch: seated, soles of the feet pressed together, knees open toward the floor, hands holding the feet, back straight."},
  {"id": "demo_cobra_a", "file": "assets/art/demos/cobra_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: lying face down, hands flat on the floor under the shoulders, legs straight."},
  {"id": "demo_cobra_b", "file": "assets/art/demos/cobra_b.png", "type": "demo", "size": 512, "from": "demo_cobra_a", "prompt": "Second position of the same exercise: the cobra stretch: hips on the floor, arms pushing the chest up, back arched, gaze forward."},
  {"id": "demo_child_pose_a", "file": "assets/art/demos/child_pose_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: kneeling on the floor, sitting on his heels, back straight, hands on the thighs."},
  {"id": "demo_child_pose_b", "file": "assets/art/demos/child_pose_b.png", "type": "demo", "size": 512, "from": "demo_child_pose_a", "prompt": "Second position of the same exercise: the child's pose: kneeling, sitting back on the heels, torso folded forward over the thighs, forehead near the floor, arms stretched forward on the floor."},
  {"id": "demo_seated_twist_a", "file": "assets/art/demos/seated_twist_a.png", "type": "demo", "size": 512, "prompt": "A hero in basic worn armor: padded brown gambeson, simple open-face steel helm, leather boots and gloves. Seen from a 45-degree camera angle (three-quarter view from the front-side), whole body visible, clean readable silhouette for an exercise guide. Exercise demonstration, first position: seated on the floor, back straight, legs stretched forward."},
  {"id": "demo_seated_twist_b", "file": "assets/art/demos/seated_twist_b.png", "type": "demo", "size": 512, "from": "demo_seated_twist_a", "prompt": "Second position of the same exercise: the seated spinal twist: one knee bent with the foot crossed over the other leg, torso turned toward the bent knee, opposite elbow pressing against it, the other hand on the floor behind."}
]

# 4. Color utilities & quality checks
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

def count_light_rim_pixels(img_rgba):
    """Detects any light/cream/white rim pixels along the outer boundary of the cutout."""
    ar = np.asarray(img_rgba).astype(float)
    r, g, b, a = ar[..., 0], ar[..., 1], ar[..., 2], ar[..., 3]
    is_transp = (a < 40)
    outer_edge = (a >= 40) & ndi.binary_dilation(is_transp, iterations=2)
    lum = (0.3 * r + 0.59 * g + 0.11 * b)
    light_rim = outer_edge & (lum > 175) & (r > 150) & (g > 145) & (b > 135)
    return int(light_rim.sum())

# 5. Generation Function
def generate_image(item, max_retries=3):
    item_id = item["id"]
    is_b = item_id.endswith("_b")
    parent_id = item.get("from")
    
    parts = []
    refs_used = []
    
    if item_id == "demo_push_up_a":
        # First image: pass creature style references
        for ref in CACHED_CREATURE_REFS:
            parts.append({"text": f"Style Reference ({ref['name']}): match the painting technique, inked outlines, level of detail and lighting of these reference images, but draw a completely different subject and use ONLY the colours written in this prompt:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": ref["b64"]}})
            refs_used.append(ref["name"])
            
        full_prompt = (
            f"{STYLE_INSTRUCTION}\n\n"
            f"SUBJECT: Exercise Demonstration.\n"
            f"{item['prompt']}"
        )
        parts.append({"text": full_prompt})
        
    elif is_b:
        # Edit of _a frame
        parent_raw = os.path.join(RAW_DIR, f"{parent_id}.png")
        if not os.path.exists(parent_raw):
            raise FileNotFoundError(f"Parent raw image {parent_raw} does not exist!")
            
        parts.append({"text": "Identity & Alignment Reference (Frame A of this exact exercise):"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": load_image_b64(parent_raw, 1024)}})
        refs_used.append(f"{parent_id}.png")
        
        full_prompt = (
            "Edit this exact image. Keep the character, armour, camera angle, framing, scale, lighting, floor line and magenta background identical. "
            "Change only the body pose to the one described below.\n\n"
            f"{STYLE_INSTRUCTION}\n\n"
            f"EXERCISE POSE: {item['prompt']}"
        )
        parts.append({"text": full_prompt})
        
    else:
        # Any subsequent _a frame: pass raw/demo_push_up_a.png as identity reference
        push_up_a_raw = os.path.join(RAW_DIR, "demo_push_up_a.png")
        if not os.path.exists(push_up_a_raw):
            raise FileNotFoundError("demo_push_up_a.png must be generated first!")
            
        parts.append({"text": "Identity Reference: keep exactly the same character, armour, camera angle, framing, scale and lighting as this hero:"})
        parts.append({"inlineData": {"mimeType": "image/png", "data": load_image_b64(push_up_a_raw, 1024)}})
        refs_used.append("demo_push_up_a.png")
        
        # Also pass creature style reference for shading & line art consistency
        if CACHED_CREATURE_REFS:
            parts.append({"text": f"Style Reference ({CACHED_CREATURE_REFS[0]['name']}): match the dark fantasy inking and shading technique:"})
            parts.append({"inlineData": {"mimeType": "image/png", "data": CACHED_CREATURE_REFS[0]["b64"]}})
            refs_used.append(CACHED_CREATURE_REFS[0]["name"])
            
        full_prompt = (
            f"{STYLE_INSTRUCTION}\n\n"
            f"SUBJECT: Exercise Demonstration.\n"
            f"Keep exactly the same character, armour, camera angle, framing, scale and lighting as the identity reference.\n"
            f"{item['prompt']}"
        )
        parts.append({"text": full_prompt})
        
    payload = {"contents": [{"parts": parts}]}
    headers = {"Content-Type": "application/json"}
    req = urllib.request.Request(API_URL, data=json.dumps(payload).encode("utf-8"), headers=headers)
    
    for attempt in range(max_retries):
        try:
            print(f"[{item_id}] Calling Gemini API (attempt {attempt+1}/{max_retries})...")
            with urllib.request.urlopen(req, timeout=90) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                for p in data["candidates"][0]["content"]["parts"]:
                    if "inlineData" in p:
                        raw_bytes = base64.b64decode(p["inlineData"]["data"])
                        raw_path = os.path.join(RAW_DIR, f"{item_id}.png")
                        with open(raw_path, "wb") as f_out:
                            f_out.write(raw_bytes)
                        print(f"[{item_id}] Raw image saved ({len(raw_bytes)} bytes) -> {raw_path}")
                        return raw_path, full_prompt, refs_used, attempt + 1
        except Exception as e:
            if hasattr(e, "read"):
                try:
                    err_msg = e.read().decode("utf-8")
                    print(f"[{item_id}] Attempt {attempt+1} error detail: {err_msg}")
                except Exception:
                    pass
            print(f"[{item_id}] Attempt {attempt+1} failed: {e}")
            time.sleep(3)
            
    return None, full_prompt, refs_used, max_retries

# 6. Cutout & Processing
def process_cutout(raw_path, target_size=512):
    im_pil = Image.open(raw_path).convert("RGB")
    im = np.asarray(im_pil, dtype=float)
    H, W, _ = im.shape
    
    # 1. Background color detection from perimeter median
    border = np.concatenate([im[0], im[-1], im[:, 0], im[:, -1]])
    bgc = np.median(border, axis=0)
    
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    mx, mn = im.max(-1), im.min(-1)
    lum = (0.3 * r + 0.59 * g + 0.11 * b) / 255.0
    sat = (mx - mn) / np.maximum(mx, 1.0)
    dh = np.abs(((hue(im) - hue(bgc)) + 180) % 360 - 180)
    
    # Strictly magenta background condition
    bgish = (dh < 32) & (sat > 0.22) & (r > 115) & (b > 65) & (g < 115)
    labeled, num_features = ndi.label(bgish)
    border_labels = set(np.unique(np.concatenate([labeled[0], labeled[-1], labeled[:, 0], labeled[:, -1]]))) - {0}
    bg = np.isin(labeled, list(border_labels))
    
    # Enclosed magenta background pockets
    for lbl in range(1, num_features + 1):
        if lbl not in border_labels:
            mask_lbl = (labeled == lbl)
            if mask_lbl.sum() >= 2:
                m_color = im[mask_lbl].mean(0)
                if np.abs(m_color - bgc).max() < 55 and m_color[2] > 55 and m_color[0] > 105:
                    bg |= mask_lbl
                    
    obj = ~bg
    
    # Drop tiny detached islands (< 50 px)
    labeled_obj, num_obj = ndi.label(obj)
    if num_obj > 1:
        sizes = ndi.sum(obj, labeled_obj, range(1, num_obj + 1))
        max_size = max(sizes) if len(sizes) > 0 else 0
        keep_labels = [i + 1 for i, s in enumerate(sizes) if s >= 50 or s == max_size]
        obj = np.isin(labeled_obj, keep_labels)
        
    # Shrink alpha 1-2 px to strip outer magenta haze
    for _ in range(2):
        edge = obj & ~ndi.binary_erosion(obj, border_value=1)
        edge_dh = dh[edge]
        edge_r = r[edge]
        edge_g = g[edge]
        edge_b = b[edge]
        is_halo = (edge_dh < 35) & (edge_r > edge_g + 12) & (edge_b > edge_g + 6)
        edge_to_strip = np.zeros_like(obj)
        edge_to_strip[edge] = is_halo
        if not edge_to_strip.any():
            break
        obj &= ~edge_to_strip
        
    # Despill and Edge Darkening (bold inked outline enforcement)
    im_clean = im.copy()
    for _ in range(3):
        edge_outer = obj & ~ndi.binary_erosion(obj, border_value=1)
        # Check pink tone
        edge_pinkish = edge_outer & (dh < 40) & (im_clean[..., 0] > im_clean[..., 1] + 6) & (im_clean[..., 2] > im_clean[..., 1] + 4)
        im_clean[edge_pinkish, 0] = np.minimum(im_clean[edge_pinkish, 0], im_clean[edge_pinkish, 1] + 4)
        im_clean[edge_pinkish, 2] = np.minimum(im_clean[edge_pinkish, 2], im_clean[edge_pinkish, 1] + 4)
        
        # Check light rim on outermost 1px (in Gym Oath silhouettes have dark ink lines)
        edge_light = edge_outer & ((0.3*im_clean[...,0] + 0.59*im_clean[...,1] + 0.11*im_clean[...,2]) > 160)
        im_clean[edge_light, 0] = np.minimum(im_clean[edge_light, 0], 35.0)
        im_clean[edge_light, 1] = np.minimum(im_clean[edge_light, 1], 35.0)
        im_clean[edge_light, 2] = np.minimum(im_clean[edge_light, 2], 35.0)

    # Soft 1px edge with drop below alpha 70
    alpha = np.where(obj, 255.0, 0.0)
    outer_edge_final = obj & ~ndi.binary_erosion(obj, border_value=1)
    alpha[outer_edge_final] = 210.0
    alpha[alpha < 70.0] = 0.0
    
    rgba = np.dstack([im_clean.astype(np.uint8), alpha.astype(np.uint8)])
    full_rgba_img = Image.fromarray(rgba, "RGBA")
    
    # Scale 1024x1024 directly to target_size 512x512 with LANCZOS
    # This preserves the exact 90% floor line and coordinate alignment between frame _a and frame _b!
    final_canvas = full_rgba_img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    # Post-resize cleanup: ensure pink_pixels == 0 and light_rim_pixels == 0
    arr_fin = np.asarray(final_canvas).copy().astype(float)
    r_f, g_f, b_f, a_f = arr_fin[..., 0], arr_fin[..., 1], arr_fin[..., 2], arr_fin[..., 3]
    
    # Despill pink
    h_f = hue(arr_fin[..., :3])
    dh_f = np.abs(((h_f - hue([255.0, 0.0, 255.0])) + 180) % 360 - 180)
    chroma_f = arr_fin[..., :3].max(-1) - arr_fin[..., :3].min(-1)
    pink_mask = (a_f > 20) & (dh_f < 24) & (chroma_f > 75) & (r_f > g_f + 30) & (b_f > g_f + 12)
    if pink_mask.any():
        arr_fin[pink_mask, 0] = np.maximum(0, arr_fin[pink_mask, 1] + 8)
        arr_fin[pink_mask, 2] = np.maximum(0, arr_fin[pink_mask, 1] + 8)
        
    # Light rim despill on boundary
    is_transp_fin = (a_f < 50)
    outer_fin = (a_f >= 50) & ndi.binary_dilation(is_transp_fin, iterations=2)
    lum_f = 0.3 * r_f + 0.59 * g_f + 0.11 * b_f
    light_rim_mask = outer_fin & (lum_f > 170) & (r_f > 150) & (g_f > 145) & (b_f > 135)
    if light_rim_mask.any():
        arr_fin[light_rim_mask, 0] = np.minimum(arr_fin[light_rim_mask, 0], 35.0)
        arr_fin[light_rim_mask, 1] = np.minimum(arr_fin[light_rim_mask, 1], 35.0)
        arr_fin[light_rim_mask, 2] = np.minimum(arr_fin[light_rim_mask, 2], 35.0)
        
    final_canvas = Image.fromarray(arr_fin.astype(np.uint8), "RGBA")
    
    pk = count_pink_pixels(final_canvas)
    lr = count_light_rim_pixels(final_canvas)
    
    return final_canvas, pk, lr

# 7. Check Sheet Builder
def build_check_sheet():
    """Generates check sheet check_demos.png with every cutout twice:
    once on flat stone grey #7F7A70 (127, 122, 112)
    and once on near-black #0D0B09 (13, 11, 9).
    Arranged in 14 columns x 8 rows (4 rows grey, 4 rows black).
    """
    cols = 14
    rows_per_bg = 4
    cell_size = 512
    sheet_w = cols * cell_size
    sheet_h = 2 * rows_per_bg * cell_size
    
    sheet = Image.new("RGB", (sheet_w, sheet_h), (0, 0, 0))
    
    # Top half: stone grey #7F7A70
    bg_grey = Image.new("RGB", (sheet_w, rows_per_bg * cell_size), (127, 122, 112))
    sheet.paste(bg_grey, (0, 0))
    
    # Bottom half: near-black #0D0B09
    bg_black = Image.new("RGB", (sheet_w, rows_per_bg * cell_size), (13, 11, 9))
    sheet.paste(bg_black, (0, rows_per_bg * cell_size))
    
    placed = 0
    for idx, item in enumerate(DEMO_ITEMS):
        out_p = os.path.join(REPO_DIR, item["file"])
        if os.path.exists(out_p):
            im = Image.open(out_p).convert("RGBA")
            col = idx % cols
            row = idx // cols
            
            # Grey section
            sheet.paste(im, (col * cell_size, row * cell_size), im)
            # Black section
            sheet.paste(im, (col * cell_size, (rows_per_bg + row) * cell_size), im)
            placed += 1
            
    sheet.save(CHECK_IMAGE_IRON, format="PNG")
    sheet.save(CHECK_IMAGE_ROOT, format="PNG")
    print(f"Check sheet saved ({placed}/56 items) to {CHECK_IMAGE_IRON} and {CHECK_IMAGE_ROOT}")
    return placed

# 8. Update Manifests
def update_manifests(records):
    # 1. Update root manifest.json (dict)
    root_dict = {}
    if os.path.exists(MANIFEST_ROOT):
        try:
            with open(MANIFEST_ROOT, "r", encoding="utf-8") as f:
                root_dict = json.load(f)
        except Exception:
            root_dict = {}
    for r in records:
        root_dict[r["id"]] = r
    with open(MANIFEST_ROOT, "w", encoding="utf-8") as f:
        json.dump(root_dict, f, indent=2)
    print(f"Updated {MANIFEST_ROOT} (total entries: {len(root_dict)})")
    
    # 2. Update assets/art/manifest.json (list)
    art_list = []
    if os.path.exists(MANIFEST_ART):
        try:
            with open(MANIFEST_ART, "r", encoding="utf-8") as f:
                art_list = json.load(f)
        except Exception:
            art_list = []
    art_map = {item.get("id"): item for item in art_list if isinstance(item, dict) and "id" in item}
    for r in records:
        art_map[r["id"]] = r
    new_art_list = list(art_map.values())
    with open(MANIFEST_ART, "w", encoding="utf-8") as f:
        json.dump(new_art_list, f, indent=2)
    print(f"Updated {MANIFEST_ART} (total entries: {len(new_art_list)})")
    
    # 3. Update iron-oath-art/manifest.json (list)
    iron_list = []
    if os.path.exists(MANIFEST_IRON):
        try:
            with open(MANIFEST_IRON, "r", encoding="utf-8") as f:
                iron_list = json.load(f)
        except Exception:
            iron_list = []
    iron_map = {item.get("id"): item for item in iron_list if isinstance(item, dict) and "id" in item}
    for r in records:
        iron_map[r["id"]] = r
    new_iron_list = list(iron_map.values())
    with open(MANIFEST_IRON, "w", encoding="utf-8") as f:
        json.dump(new_iron_list, f, indent=2)
    print(f"Updated {MANIFEST_IRON} (total entries: {len(new_iron_list)})")
    
    # 4. Update iron-oath-art/assets_list.json (list of all assets)
    assets_list = []
    if os.path.exists(ASSETS_LIST_IRON):
        try:
            with open(ASSETS_LIST_IRON, "r", encoding="utf-8") as f:
                assets_list = json.load(f)
        except Exception:
            assets_list = []
    existing_ids = {a.get("id") for a in assets_list if isinstance(a, dict)}
    for r in records:
        if r["id"] not in existing_ids:
            assets_list.append({
                "id": r["id"],
                "file": r["file"],
                "type": r.get("type", "demo"),
                "size": r.get("size", 512),
                "prompt": r.get("prompt", "")
            })
            existing_ids.add(r["id"])
    with open(ASSETS_LIST_IRON, "w", encoding="utf-8") as f:
        json.dump(assets_list, f, indent=2)
    print(f"Updated {ASSETS_LIST_IRON} (total entries: {len(assets_list)})")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", type=str, default=None, help="Generate only specific ID")
    parser.add_argument("--count", type=int, default=None, help="Limit number of items to process")
    args = parser.parse_args()

    items_to_process = DEMO_ITEMS
    if args.only:
        items_to_process = [it for it in DEMO_ITEMS if it["id"] == args.only]
    elif args.count:
        items_to_process = DEMO_ITEMS[:args.count]

    print(f"Items to process: {len(items_to_process)}")
    records = []
    
    for idx, item in enumerate(items_to_process):
        aid = item["id"]
        raw_path = os.path.join(RAW_DIR, f"{aid}.png")
        final_file = item["file"]
        out_repo = os.path.join(REPO_DIR, final_file)
        out_iron = os.path.join(IRON_DIR, final_file)
        os.makedirs(os.path.dirname(out_repo), exist_ok=True)
        os.makedirs(os.path.dirname(out_iron), exist_ok=True)
        
        attempts = 1
        refs = []
        final_prompt = item["prompt"]
        
        if os.path.exists(raw_path):
            print(f"[{idx+1}/{len(items_to_process)}] Raw {raw_path} already exists, skipping API generation.", flush=True)
        else:
            raw_path, final_prompt, refs, attempts = generate_image(item)
            if not raw_path or not os.path.exists(raw_path):
                print(f"ERROR: Failed to generate {aid}", flush=True)
                continue
            # Small delay between API calls
            time.sleep(1)
            
        # Perform cutout
        print(f"[{aid}] Processing cutout...", flush=True)
        cutout_img, pk, lr = process_cutout(raw_path, target_size=item.get("size", 512))
        
        # Save both to repo and iron-oath-art
        cutout_img.save(out_repo, format="PNG")
        cutout_img.save(out_iron, format="PNG")
        print(f"[{aid}] Delivered: {out_repo} (pk={pk}, lr={lr})", flush=True)
        
        rec = {
            "id": aid,
            "file": final_file,
            "type": "demo",
            "size": item.get("size", 512),
            "prompt": final_prompt,
            "references": refs,
            "attempts": attempts,
            "pink_pixels": pk,
            "light_rim_pixels": lr,
            "status": "done"
        }
        records.append(rec)
        
    print(f"\nFinished processing {len(records)} items.", flush=True)
    update_manifests(records)
    
    # Check if all 56 exist to build check sheet
    all_exist = all(os.path.exists(os.path.join(REPO_DIR, it["file"])) for it in DEMO_ITEMS)
    if all_exist:
        build_check_sheet()
    else:
        print(f"Not all 56 items are on disk yet ({sum(1 for it in DEMO_ITEMS if os.path.exists(os.path.join(REPO_DIR, it['file'])))}/56 exist). Check sheet deferred.", flush=True)


