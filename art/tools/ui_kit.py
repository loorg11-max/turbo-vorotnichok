#!/usr/bin/env python3
"""Интерфейс из картинок GPT 10a–10c: панели, кнопки, шкалы.

В отличие от pixelize.py цвета берутся из самой картинки (свои 6–12 на предмет), а не
из общей палитры: в палитре нет тёмно-оранжевого, и кнопки становились красными снизу.
Потом края выравниваются, чтобы предмет растягивался как девятичастная рамка (nine-patch):
середина каждой строки и каждого столбца заливается их самым частым цветом.

  python3 ui_kit.py raw_dir out_dir [--godot]

raw_dir: папка art/gpt/raw, out_dir: куда сложить png; с --godot ещё в art/ui/ проекта Godot.
"""
import argparse
import os
import sys
from collections import Counter

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pixelize  # noqa: E402

GODOT_UI = os.path.join(HERE, "..", "..", "godot", "turbo-vorotnichok", "art", "ui")
OUTLINE = (0x09, 0x0C, 0x1C)

# имя: (картинка, номер куска по порядку чтения, во сколько раз уменьшить, цветов,
#       растяжение "hv" | "v" | "", поля рамки (слева, сверху, справа, снизу), прозрачность середины)
ITEMS = {
    "panel_big": ("10a_ui_panels", 0, 6, 10, "hv", (9, 9, 9, 9), 235),
    "panel_mid": ("10a_ui_panels", 1, 6, 10, "hv", (9, 9, 9, 9), 245),
    "btn_normal": ("10b_ui_buttons", 0, 8, 7, "hv", (6, 6, 6, 6), 255),
    "btn_hover": ("10b_ui_buttons", 1, 8, 8, "hv", (6, 6, 6, 6), 255),
    "btn_pressed": ("10b_ui_buttons", 2, 8, 6, "hv", (6, 6, 6, 6), 255),
    "btn_disabled": ("10b_ui_buttons", 3, 8, 7, "hv", (6, 6, 6, 6), 255),
    "sq_normal": ("10b_ui_buttons", 4, 8, 7, "hv", (7, 7, 7, 7), 255),
    "sq_hover": ("10b_ui_buttons", 5, 8, 8, "hv", (7, 7, 7, 7), 255),
    "sq_pressed": ("10b_ui_buttons", 6, 8, 6, "hv", (7, 7, 7, 7), 255),
    "sq_disabled": ("10b_ui_buttons", 7, 8, 7, "hv", (7, 7, 7, 7), 255),
    "close": ("10b_ui_buttons", 8, 12, 6, "", None, 255),
    "close_hover": ("10b_ui_buttons", 9, 12, 7, "", None, 255),
    "plate": ("10c_ui_hud", 0, 6, 6, "hv", (6, 6, 6, 6), 230),
    "tube": ("10c_ui_hud", 1, 6, 10, "v", (0, 14, 0, 14), 255),
    "bar": ("10c_ui_hud", 3, 6, 10, "hv", (6, 5, 6, 5), 255),
}


def pieces(path, tol=90):
    """Куски не-фона в порядке чтения (так же, как split_sheet.py): рамки в пикселях исходника."""
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    fg = ~((a[..., 0] > 255 - tol) & (a[..., 2] > 255 - tol) & (a[..., 1] < tol + 40))
    cell = 8
    h, w = fg.shape
    g = fg[: h // cell * cell, : w // cell * cell].reshape(h // cell, cell, w // cell, cell).any(axis=(1, 3))
    seen = np.zeros_like(g)
    boxes = []
    for y, x in zip(*np.nonzero(g)):
        if seen[y, x]:
            continue
        stack, pts = [(y, x)], []
        seen[y, x] = True
        while stack:
            cy, cx = stack.pop()
            pts.append((cy, cx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < g.shape[0] and 0 <= nx < g.shape[1] and g[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if len(pts) < 6:
            continue
        ys, xs = zip(*pts)
        x0, y0, x1, y1 = min(xs) * cell, min(ys) * cell, (max(xs) + 1) * cell, (max(ys) + 1) * cell
        sub = fg[y0:y1, x0:x1]
        yy, xx = np.nonzero(sub)
        boxes.append((x0 + xx.min(), y0 + yy.min(), x0 + xx.max() + 1, y0 + yy.max() + 1))
    # строки: куски, чьи середины по высоте близко, идут слева направо
    boxes.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows, cur = [], []
    for b in boxes:
        if cur and (b[1] + b[3]) / 2 - (cur[-1][1] + cur[-1][3]) / 2 > (cur[-1][3] - cur[-1][1]) / 2:
            rows.append(cur)
            cur = []
        cur.append(b)
    rows.append(cur)
    return im, [b for r in rows for b in sorted(r)]


def downscale(im, w, h, tol=90):
    """Самый частый цвет из середины клетки, розовый фон прозрачный. Цвета исходника."""
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src, dst = im.load(), out.load()
    sx, sy = im.width / w, im.height / h
    for y in range(h):
        y0 = int((y + 0.2) * sy)
        y1 = max(y0 + 1, int((y + 0.8) * sy))
        for x in range(w):
            x0 = int((x + 0.2) * sx)
            x1 = max(x0 + 1, int((x + 0.8) * sx))
            votes = Counter()
            for yy in range(y0, y1):
                for xx in range(x0, x1):
                    r, g, b = src[xx, yy]
                    votes[(r >> 3, g >> 3, b >> 3)] += 1
            k = votes.most_common(1)[0][0]
            c = (k[0] * 8 + 4, k[1] * 8 + 4, k[2] * 8 + 4)
            if pixelize.is_key(c, tol):
                continue
            dst[x, y] = c + (255,)
    return out


def quantize(im, n):
    """Свои n цветов на предмет; почти чёрный становится обводкой игры."""
    a = np.array(im)
    on = a[..., 3] > 0
    rgb = Image.fromarray(a[..., :3][on].reshape(1, -1, 3).astype(np.uint8), "RGB")
    q = rgb.quantize(n, method=Image.Quantize.MEDIANCUT).convert("RGB")
    cols = np.asarray(q).reshape(-1, 3).copy()
    dark = cols.sum(1) < 45
    cols[dark] = OUTLINE
    a[..., :3][on] = cols
    return Image.fromarray(a, "RGBA")


def _mode(pixels):
    return Counter(map(tuple, pixels)).most_common(1)[0][0]


def ninepatch(im, stretch, m, center_alpha):
    """Середина строк (h) и столбцов (v) одним цветом: рамка тянется без ряби."""
    a = np.array(im)
    h, w = a.shape[:2]
    l, t, r, b = m
    if "h" in stretch:
        for y in range(h):
            a[y, l:w - r] = _mode(a[y, l:w - r])
    if "v" in stretch:
        for x in range(w):
            a[t:h - b, x] = _mode(a[t:h - b, x])
    if center_alpha < 255:
        mid = a[t:h - b, l:w - r]
        mid[..., 3] = np.where(mid[..., 3] > 0, center_alpha, 0)
    return Image.fromarray(a, "RGBA")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw")
    ap.add_argument("out")
    ap.add_argument("--godot", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    cache = {}
    for name, (src, idx, k, n, stretch, m, alpha) in ITEMS.items():
        if src not in cache:
            cache[src] = pieces(os.path.join(a.raw, src + ".png"))
        im, boxes = cache[src]
        box = boxes[idx]
        crop = im.crop(box)
        w, h = round(crop.width / k), round(crop.height / k)
        out = quantize(downscale(crop, w, h), n)
        if stretch:
            out = ninepatch(out, stretch, m, alpha)
        out.save(os.path.join(a.out, name + ".png"))
        print(f"{name}: {w}×{h}")
        if a.godot:
            os.makedirs(GODOT_UI, exist_ok=True)
            out.save(os.path.join(GODOT_UI, name + ".png"))


if __name__ == "__main__":
    main()
