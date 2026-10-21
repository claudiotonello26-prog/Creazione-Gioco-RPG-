"""Install Knight Assets into 'assets/art/knight' structure.
Packages modular armor slots, attack bases, and customizer pieces (faces, hair, beards)
for seamless integration into the game engine.
"""

import os
import shutil
from PIL import Image
import numpy as np
from scipy.ndimage import label, find_objects, binary_dilation

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PIPELINE_DIR = os.path.dirname(SCRIPT_DIR)
REPO_DIR = os.path.dirname(PIPELINE_DIR)

BASES_DIR = os.path.join(PIPELINE_DIR, 'current_bases')
ARMORS_DIR = os.path.join(PIPELINE_DIR, 'output', 'armors')
MODULAR_DIR = os.path.join(PIPELINE_DIR, 'output', 'modular_armors')
OUT_DIR = os.path.join(PIPELINE_DIR, 'output')

KNIGHT_ART = os.path.join(REPO_DIR, 'assets', 'art', 'knight')

def install():
    print("Installing Hero bases and modular armors...")
    
    # 1. Male Idle
    m_idle = os.path.join(KNIGHT_ART, 'male', 'idle')
    os.makedirs(m_idle, exist_ok=True)
    shutil.copy(os.path.join(BASES_DIR, 'hero_male_base.png'), os.path.join(m_idle, 'base.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'male_gambeson_chest.png'), os.path.join(m_idle, 'chest_gambeson.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'male_gambeson_legs.png'), os.path.join(m_idle, 'legs_gambeson.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'male_cuoio_helm.png'), os.path.join(m_idle, 'helm_cuoio.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'male_cuoio_chest.png'), os.path.join(m_idle, 'chest_cuoio.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'male_cuoio_legs.png'), os.path.join(m_idle, 'legs_cuoio.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'male_piastre_helm.png'), os.path.join(m_idle, 'helm_piastre.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'male_piastre_chest.png'), os.path.join(m_idle, 'chest_piastre.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'male_piastre_legs.png'), os.path.join(m_idle, 'legs_piastre.png'))
    
    # 2. Female Idle
    f_idle = os.path.join(KNIGHT_ART, 'female', 'idle')
    os.makedirs(f_idle, exist_ok=True)
    shutil.copy(os.path.join(BASES_DIR, 'hero_female_base.png'), os.path.join(f_idle, 'base.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'female_gambeson_chest.png'), os.path.join(f_idle, 'chest_gambeson.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'female_gambeson_legs.png'), os.path.join(f_idle, 'legs_gambeson.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'female_cuoio_helm.png'), os.path.join(f_idle, 'helm_cuoio.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'female_cuoio_chest.png'), os.path.join(f_idle, 'chest_cuoio.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'female_cuoio_legs.png'), os.path.join(f_idle, 'legs_cuoio.png'))
    
    shutil.copy(os.path.join(MODULAR_DIR, 'female_piastre_helm.png'), os.path.join(f_idle, 'helm_piastre.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'female_piastre_chest.png'), os.path.join(f_idle, 'chest_piastre.png'))
    shutil.copy(os.path.join(MODULAR_DIR, 'female_piastre_legs.png'), os.path.join(f_idle, 'legs_piastre.png'))
    
    # 3. Attack Bases
    m_att = os.path.join(KNIGHT_ART, 'male', 'attack')
    os.makedirs(m_att, exist_ok=True)
    shutil.copy(os.path.join(BASES_DIR, 'hero_male_attack_base.png'), os.path.join(m_att, 'base.png'))
    
    f_att = os.path.join(KNIGHT_ART, 'female', 'attack')
    os.makedirs(f_att, exist_ok=True)
    shutil.copy(os.path.join(BASES_DIR, 'hero_female_attack_base.png'), os.path.join(f_att, 'base.png'))
    
    # 4. Slicing Customizer Pieces
    print("Slicing customizer pieces...")
    def slice_sheet(sheet_path, out_dir, prefix, max_iter=2, pad=6):
        os.makedirs(out_dir, exist_ok=True)
        im = Image.open(sheet_path)
        arr = np.array(im)
        alpha = (arr[:, :, 3] > 20).astype(int)
        dilated = binary_dilation(alpha, iterations=max_iter)
        labeled, _ = label(dilated)
        objs = find_objects(labeled)
        valid = [sl for sl in objs if (sl[0].stop - sl[0].start) > 40 and (sl[1].stop - sl[1].start) > 40]
        valid = sorted(valid, key=lambda sl: sl[1].start)
        
        for idx, sl in enumerate(valid):
            y_s, x_s = sl
            cl = max(0, x_s.start - pad)
            cr = min(im.width, x_s.stop + pad)
            ct = max(0, y_s.start - pad)
            cb = min(im.height, y_s.stop + pad)
            piece = im.crop((cl, ct, cr, cb))
            out_p = os.path.join(out_dir, f"{prefix}_{idx}.png")
            piece.save(out_p)
            print(f"  Saved {out_p} ({piece.size})")

    # Male Customizer
    m_cust = os.path.join(KNIGHT_ART, 'male', 'customizer')
    slice_sheet(os.path.join(OUT_DIR, 'faces_male_clean.png'), m_cust, 'face', max_iter=5)
    slice_sheet(os.path.join(OUT_DIR, 'hair_male_clean.png'), m_cust, 'hair', max_iter=2)
    slice_sheet(os.path.join(OUT_DIR, 'beards_male_clean.png'), m_cust, 'beard', max_iter=4)
    
    # Female Customizer
    f_cust = os.path.join(KNIGHT_ART, 'female', 'customizer')
    slice_sheet(os.path.join(OUT_DIR, 'faces_female_clean.png'), f_cust, 'face', max_iter=5)
    slice_sheet(os.path.join(OUT_DIR, 'hair_female_clean.png'), f_cust, 'hair', max_iter=1)
    
    print("All knight assets successfully installed into assets/art/knight/!")

if __name__ == '__main__':
    install()
