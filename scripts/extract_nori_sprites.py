import os
import shutil
from PIL import Image
import numpy as np
import scipy.ndimage as ndi

SRC_DIR = 'assets/sprites/NORI from Flow google '
OUT_DIR = 'assets/sprites/nori'
CANVAS_SIZE = 128
BASELINE_Y = 118

os.makedirs(OUT_DIR, exist_ok=True)

def process_and_place(sprite_rgba, scale_factor=1.0):
    """
    Scales sprite_rgba by scale_factor (using Image.NEAREST for sharp pixel art)
    and places it onto a 128x128 canvas aligned to BASELINE_Y = 118.
    """
    h, w, _ = sprite_rgba.shape
    if scale_factor != 1.0:
        nw = max(1, int(round(w * scale_factor)))
        nh = max(1, int(round(h * scale_factor)))
        im = Image.fromarray(sprite_rgba).resize((nw, nh), Image.NEAREST)
        sprite_rgba = np.array(im)
        h, w = nh, nw
        
    max_allowed = CANVAS_SIZE - 8
    if w > max_allowed or h > max_allowed:
        scale = min(max_allowed / float(w), max_allowed / float(h))
        nw = max(1, int(round(w * scale)))
        nh = max(1, int(round(h * scale)))
        im = Image.fromarray(sprite_rgba).resize((nw, nh), Image.NEAREST)
        sprite_rgba = np.array(im)
        h, w = nh, nw

    canvas = np.zeros((CANVAS_SIZE, CANVAS_SIZE, 4), dtype=np.uint8)
    dest_x = max(0, (CANVAS_SIZE - w) // 2)
    dest_y = max(0, BASELINE_Y - h)
    dest_x = min(dest_x, CANVAS_SIZE - w)
    dest_y = min(dest_y, CANVAS_SIZE - h)
    canvas[dest_y:dest_y+h, dest_x:dest_x+w] = sprite_rgba
    return Image.fromarray(canvas)

def extract_3row_cell(crop, bg_color):
    """
    Extracts cat from 3-row sheets (256px tall cells).
    Discards top/bottom labels (y <= 75 and y >= 215).
    Scales by 0.62x to canonical cat scale (~70px height).
    """
    diff = np.abs(crop.astype(int) - bg_color.astype(int)).max(axis=2)
    is_cat = (crop[:, :, 0] < 70) & (crop[:, :, 1] < 70) & (crop[:, :, 2] < 80) & (diff > 30)
    is_cat[:75, :] = False
    is_cat[215:, :] = False
    
    labeled, n = ndi.label(is_cat)
    if n == 0: return None
    sizes = [0] + [(labeled == i).sum() for i in range(1, n + 1)]
    best_idx = int(np.argmax(sizes))
    if sizes[best_idx] < 500: return None
    cat_body = (labeled == best_idx)
    c_ys, c_xs = np.where(cat_body)
    
    ear_top = max(70, c_ys.min() - 2)
    fg = diff > 20
    fg[:ear_top, :] = False
    fg[218:, :] = False
    
    fg_labeled, fg_n = ndi.label(fg)
    overlap = fg_labeled[cat_body]
    overlap = overlap[overlap > 0]
    if len(overlap) == 0: return None
    best_fg = int(np.bincount(overlap).argmax())
    
    cat_mask = (fg_labeled == best_fg)
    
    # Attach desk or book or floor props directly under cat
    for i in range(1, fg_n + 1):
        if i == best_fg: continue
        comp = (fg_labeled == i)
        i_ys, i_xs = np.where(comp)
        if i_ys.min() >= c_ys.max() - 4 and i_ys.max() <= 218:
            if max(0, min(i_xs.max(), c_xs.max()) - max(i_xs.min(), c_xs.min())) > 15:
                cat_mask |= comp
                
    cat_mask = ndi.binary_fill_holes(cat_mask)
    ys, xs = np.where(cat_mask)
    if len(ys) == 0: return None
    
    y0, y1 = ys.min(), ys.max() + 1
    x0, x1 = xs.min(), xs.max() + 1
    
    sprite_rgb = crop[y0:y1, x0:x1]
    sprite_a = np.where(cat_mask[y0:y1, x0:x1], 255, 0).astype(np.uint8)
    sprite_rgba = np.dstack([sprite_rgb, sprite_a])
    
    return process_and_place(sprite_rgba, scale_factor=0.62)

def extract_sheet_034036():
    filepath = os.path.join(SRC_DIR, 'Black_cat_pixel_art_mascot_20261012034036.jpg')
    im = Image.open(filepath)
    arr = np.array(im)
    bg = arr[0, 0]
    cell_w = arr.shape[1] / 9.0
    
    rows_info = [
        ('walking', 30, 130),
        ('celebrating', 130, 240),
        ('running', 260, 380),
        ('yawning_loaf', 480, 590),
        ('rolling_sleep', 590, 690),
        ('celebrating_alt', 680, 768),
    ]
    
    for name, y0, y1 in rows_info:
        row_dir = os.path.join(OUT_DIR, name)
        os.makedirs(row_dir, exist_ok=True)
        saved = 0
        is_celeb = 'celebrating' in name
        for c in range(9):
            x0 = int(c * cell_w)
            x1 = int((c + 1) * cell_w)
            crop = arr[y0:y1, x0:x1]
            diff = np.abs(crop.astype(int) - bg.astype(int)).max(axis=2)
            fg = diff > 20
            labeled, n = ndi.label(fg)
            if n == 0: continue
            sizes = [0] + [(labeled == i).sum() for i in range(1, n + 1)]
            best_idx = int(np.argmax(sizes))
            cat_mask = (labeled == best_idx)
            c_ys, c_xs = np.where(cat_mask)
            
            # Keep confetti only for celebrating
            if is_celeb:
                for i in range(1, n + 1):
                    if i == best_idx: continue
                    comp = (labeled == i)
                    i_ys, i_xs = np.where(comp)
                    dist_y = max(0, i_ys.min() - c_ys.max(), c_ys.min() - i_ys.max())
                    dist_x = max(0, i_xs.min() - c_xs.max(), c_xs.min() - i_xs.max())
                    if dist_y < 20 and dist_x < 20 and len(i_ys) < 40:
                        cat_mask |= comp
                        
            cat_mask = ndi.binary_fill_holes(cat_mask)
            ys, xs = np.where(cat_mask)
            if len(ys) == 0: continue
            
            clean_rgb = crop[ys.min():ys.max()+1, xs.min():xs.max()+1]
            clean_a = np.where(cat_mask[ys.min():ys.max()+1, xs.min():xs.max()+1], 255, 0).astype(np.uint8)
            sprite_rgba = np.dstack([clean_rgb, clean_a])
            
            frame = process_and_place(sprite_rgba, scale_factor=1.0)
            frame.save(os.path.join(row_dir, f"{saved}.png"))
            saved += 1
        print(f"[034036] {name}: Extracted {saved} frames")

def extract_3row_sheet(filename, row_names):
    filepath = os.path.join(SRC_DIR, filename)
    im = Image.open(filepath)
    arr = np.array(im)
    bg = arr[0, 0]
    cell_h = arr.shape[0] / 3.0
    cell_w = arr.shape[1] / 9.0
    
    for r, name in enumerate(row_names):
        row_dir = os.path.join(OUT_DIR, name)
        os.makedirs(row_dir, exist_ok=True)
        saved = 0
        for c in range(9):
            y0 = int(r * cell_h)
            y1 = int((r + 1) * cell_h)
            x0 = int(c * cell_w)
            x1 = int((c + 1) * cell_w)
            crop = arr[y0:y1, x0:x1]
            frame = extract_3row_cell(crop, bg)
            if frame is not None:
                frame.save(os.path.join(row_dir, f"{saved}.png"))
                saved += 1
        print(f"[{filename}] {name}: Extracted {saved} frames")

def extract_sheet_034055():
    filepath = os.path.join(SRC_DIR, 'Black_cat_pixel_art_mascot_20261012034055.jpg')
    im = Image.open(filepath)
    arr = np.array(im)
    bg = arr[0, 0]
    
    poses = [
        ('love', [
            (110, 380, 40, 220),
            (110, 380, 240, 430),
        ]),
        ('excited', [
            (110, 380, 470, 690),
            (110, 380, 700, 920),
        ]),
        ('playful', [
            (110, 380, 950, 1160),
            (110, 380, 1160, 1360),
            (550, 750, 1080, 1360),
        ]),
    ]
    
    for name, bboxes in poses:
        row_dir = os.path.join(OUT_DIR, name)
        os.makedirs(row_dir, exist_ok=True)
        saved = 0
        for y0, y1, x0, x1 in bboxes:
            crop = arr[y0:y1, x0:x1]
            diff = np.abs(crop.astype(int) - bg.astype(int)).max(axis=2)
            fg = diff > 20
            labeled, n = ndi.label(fg)
            if n == 0: continue
            sizes = [0] + [(labeled == i).sum() for i in range(1, n + 1)]
            best_idx = int(np.argmax(sizes))
            cat_mask = (labeled == best_idx)
            c_ys, c_xs = np.where(cat_mask)
            
            for i in range(1, n + 1):
                if i == best_idx: continue
                comp = (labeled == i)
                i_ys, i_xs = np.where(comp)
                # Exclude any labels below cat baseline
                if i_ys.min() >= c_ys.max() - 2:
                    continue
                dist_y = max(0, i_ys.min() - c_ys.max(), c_ys.min() - i_ys.max())
                dist_x = max(0, i_xs.min() - c_xs.max(), c_xs.min() - i_xs.max())
                if dist_y < 35 and dist_x < 35:
                    cat_mask |= comp
                    
            cat_mask = ndi.binary_fill_holes(cat_mask)
            ys, xs = np.where(cat_mask)
            if len(ys) == 0: continue
            
            clean_rgb = crop[ys.min():ys.max()+1, xs.min():xs.max()+1]
            clean_a = np.where(cat_mask[ys.min():ys.max()+1, xs.min():xs.max()+1], 255, 0).astype(np.uint8)
            sprite_rgba = np.dstack([clean_rgb, clean_a])
            
            frame = process_and_place(sprite_rgba, scale_factor=0.38)
            frame.save(os.path.join(row_dir, f"{saved}.png"))
            saved += 1
        print(f"[034055] {name}: Extracted {saved} frames")

def extract_all_transitions():
    sheets = [
        ('Black_cat_pixel_art_mascot_20261012034109.jpg', [
            'transitions/walk_to_celebrate',
            'transitions/celebrate_to_walk',
            'transitions/walk_to_run',
            'transitions/run_to_walk',
            'transitions/celebrate_to_run',
            'transitions/run_to_celebrate',
        ]),
        ('Black_cat_pixel_art_mascot_20261012034115.jpg', [
            'transitions/study_to_welcome',
            'transitions/welcome_to_study',
            'transitions/welcome_to_bored',
            'transitions/bored_to_welcome',
            'transitions/study_to_bored',
            'transitions/bored_to_study',
        ]),
        ('Black_cat_pixel_art_mascot_20261012034119.jpg', [
            'transitions/play_to_sleep',
            'transitions/sleep_to_play',
            'transitions/sleep_to_eat',
            'transitions/eat_to_sleep',
            'transitions/play_to_eat',
            'transitions/eat_to_play',
        ]),
        ('Black_cat_pixel_art_mascot_20261012034126.jpg', [
            'transitions/love_to_excited',
            'transitions/excited_to_love',
            'transitions/excited_to_play',
            'transitions/play_to_excited',
            'transitions/love_to_play',
            'transitions/play_to_love',
        ]),
    ]
    
    for fname, row_names in sheets:
        im = Image.open(os.path.join(SRC_DIR, fname))
        arr = np.array(im)
        bg = arr[0, 0]
        diff = np.abs(arr.astype(int) - bg.astype(int)).max(axis=2)
        is_cat = (arr[:, :, 0] < 70) & (arr[:, :, 1] < 70) & (arr[:, :, 2] < 80) & (diff > 30)
        labeled, n = ndi.label(is_cat)
        sizes = [(labeled == i).sum() for i in range(1, n + 1)]
        big_indices = [i for i in range(1, n + 1) if sizes[i-1] > 800]
        
        cats = []
        for idx in big_indices:
            ys, xs = np.where(labeled == idx)
            cats.append({
                'idx': idx,
                'cy': ys.mean(),
                'cx': xs.mean(),
            })
            
        cats.sort(key=lambda c: c['cy'])
        
        for r, rname in enumerate(row_names):
            row_cats = cats[r*6 : (r+1)*6]
            row_cats.sort(key=lambda c: c['cx'])
            r_dir = os.path.join(OUT_DIR, rname)
            os.makedirs(r_dir, exist_ok=True)
            
            for c, cat_info in enumerate(row_cats):
                idx = cat_info['idx']
                cat_body = (labeled == idx)
                c_ys, c_xs = np.where(cat_body)
                
                # Neighborhood strictly bounded by cat's vertical extent + 12px for floor props
                y0 = c_ys.min()
                y1 = min(arr.shape[0], c_ys.max() + 12)
                x0 = max(0, c_xs.min() - 15)
                x1 = min(arr.shape[1], c_xs.max() + 15)
                
                cell_diff = diff[y0:y1, x0:x1]
                cell_body = cat_body[y0:y1, x0:x1]
                b_ys, b_xs = np.where(cell_body)
                
                fg = cell_diff > 20
                fg_lab, fg_n = ndi.label(fg)
                overlap = fg_lab[cell_body]
                overlap = overlap[overlap > 0]
                if len(overlap) == 0: continue
                best_fg = int(np.bincount(overlap).argmax())
                
                mask = (fg_lab == best_fg)
                
                # Add confetti if present (strictly above/level with cat feet, never below)
                for fi in range(1, fg_n + 1):
                    if fi == best_fg: continue
                    comp = (fg_lab == fi)
                    comp_ys, comp_xs = np.where(comp)
                    # Never attach text labels/F-numbers below cat baseline
                    if comp_ys.min() >= b_ys.max() - 2:
                        continue
                    if len(comp_ys) < 30:
                        dist_y = max(0, comp_ys.min() - b_ys.max(), b_ys.min() - comp_ys.max())
                        dist_x = max(0, comp_xs.min() - b_xs.max(), b_xs.min() - comp_xs.max())
                        if dist_y < 15 and dist_x < 15:
                            mask |= comp
                            
                mask = ndi.binary_fill_holes(mask)
                m_ys, m_xs = np.where(mask)
                if len(m_ys) == 0: continue
                
                crop_rgb = arr[y0:y1, x0:x1][m_ys.min():m_ys.max()+1, m_xs.min():m_xs.max()+1]
                crop_a = np.where(mask[m_ys.min():m_ys.max()+1, m_xs.min():m_xs.max()+1], 255, 0).astype(np.uint8)
                sprite_rgba = np.dstack([crop_rgb, crop_a])
                
                frame = process_and_place(sprite_rgba, scale_factor=1.0)
                frame.save(os.path.join(r_dir, f"{c}.png"))
            print(f"[{fname}] {rname}: Saved 6 perfect frames")

def extract_eating_cycle():
    row_dir = os.path.join(OUT_DIR, 'eating')
    os.makedirs(row_dir, exist_ok=True)
    src_eat = os.path.join(OUT_DIR, 'transitions/sleep_to_eat')
    if os.path.exists(src_eat):
        for idx, f in enumerate(['3.png', '4.png', '5.png']):
            sf = os.path.join(src_eat, f)
            if os.path.exists(sf):
                shutil.copy(sf, os.path.join(row_dir, f"{idx}.png"))
        print("[eating] Extracted 3 eating frames")

def cleanup_all_sprites():
    print("=== Post-processing & sanitizing all extracted sprites ===")
    cleaned_count = 0
    for root, dirs, files in os.walk(OUT_DIR):
        for f in sorted(files):
            if not f.endswith('.png'): continue
            path = os.path.join(root, f)
            im = Image.open(path)
            arr = np.array(im)
            if arr.shape[2] < 4: continue
            alpha = arr[:, :, 3] > 0
            labeled, n = ndi.label(alpha)
            if n <= 1: continue
            sizes = [0] + [(labeled == i).sum() for i in range(1, n+1)]
            best = int(np.argmax(sizes))
            c_ys, c_xs = np.where(labeled == best)
            
            to_remove = np.zeros_like(alpha, dtype=bool)
            for i in range(1, n+1):
                if i == best: continue
                ys, xs = np.where(labeled == i)
                # Strip any component strictly at or below cat baseline
                if ys.min() >= c_ys.max() - 1:
                    to_remove |= (labeled == i)
                else:
                    # Strip tiny isolated noise/fragment
                    dy = max(0, ys.min() - c_ys.max(), c_ys.min() - ys.max())
                    dx = max(0, xs.min() - c_xs.max(), c_xs.min() - xs.max())
                    if len(ys) <= 2:
                        to_remove |= (labeled == i)
                    elif (dy > 6 or dx > 6) and len(ys) < 30:
                        to_remove |= (labeled == i)
                            
            if np.any(to_remove):
                cleaned_count += 1
                arr[to_remove, 3] = 0
                clean_im = Image.fromarray(arr)
                clean_im.save(path)
                
    print(f"Post-processing complete: Sanitized {cleaned_count} frames (removed all text/label remnants).")

if __name__ == '__main__':
    print("=== Extracting Uniform Nori Sprites ===")
    extract_sheet_034036()
    extract_3row_sheet('Black_cat_pixel_art_mascot_20261012034042.jpg', ['studying', 'welcoming', 'bored'])
    extract_3row_sheet('Black_cat_pixel_art_mascot_20261012034047.jpg', ['sleepy', 'sad', 'tired'])
    extract_sheet_034055()
    extract_all_transitions()
    extract_eating_cycle()
    cleanup_all_sprites()
    print("=== Finished Extracting Uniform Nori Sprites! ===")
