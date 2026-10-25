#!/usr/bin/env python3
"""Сводит картинку от нейросети к настоящему пиксель-арту в палитре проекта.

Что делает:
1. уменьшает до нужного размера в игровых пикселях: каждый игровой пиксель берёт
   самый частый цвет из середины своей клетки, поэтому края остаются чёткими;
2. убирает фон-хромакей (ярко-розовый #FF00FF), если указан --key;
3. переводит каждый пиксель в ближайший цвет общей палитры (turbo-full, 57 цветов:
   Turbo32 плюс оттенки с выбранного референса);
4. по желанию обрезает пустые края (--trim) и кладёт результат в проект Godot (--godot).

Пример:
  python3 pixelize.py van.png out/van.png --size 120x80 --key --trim
  python3 pixelize.py sky.png out/sky.png --size 640x360 --godot bg/sky.png
"""
import argparse
import os
from collections import Counter

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PALETTE_DIR = os.path.join(HERE, "..", "palette")
GODOT_ART = os.path.join(HERE, "..", "..", "godot", "turbo-vorotnichok", "art")


def load_palette(path):
    with open(path) as fh:
        return [tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) for h in fh.read().split()]


def nearest(c, pal, cache):
    if c not in cache:
        # «красный» вес чуть больше: так лучше держатся оттенки кожи и галстука
        cache[c] = min(pal, key=lambda p: 2 * (p[0] - c[0]) ** 2 + 4 * (p[1] - c[1]) ** 2 + 3 * (p[2] - c[2]) ** 2)
    return cache[c]


def is_key(c, tol):
    r, g, b = c[:3]
    return r > 255 - tol and b > 255 - tol and g < tol + 40


def content_bbox(im, tol):
    """Рамка вокруг всего, что не розовый фон (в пикселях исходника)."""
    import numpy as np
    a = np.asarray(im.convert("RGB")).astype(int)
    bg = (a[..., 0] > 255 - tol) & (a[..., 2] > 255 - tol) & (a[..., 1] < tol + 40)
    ys, xs = np.nonzero(~bg)
    if not len(xs):
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def downscale(im, w, h, pal, key=False, tol=90):
    """Каждый игровой пиксель берёт самый частый цвет из середины своей клетки."""
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src, dst = im.load(), out.load()
    sx, sy = im.width / w, im.height / h
    cache = {}
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
            if key and is_key(c, tol):
                continue
            dst[x, y] = nearest(c, pal, cache) + (255,)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--size", required=True, help="размер в игровых пикселях, например 480x270; 0 у одной стороны = по пропорции")
    ap.add_argument("--key", action="store_true", help="фон #FF00FF сделать прозрачным")
    ap.add_argument("--tol", type=int, default=90, help="насколько розовый считать фоном")
    ap.add_argument("--trim", action="store_true", help="обрезать прозрачные края")
    ap.add_argument("--crop", action="store_true", help="с --key: сначала обрезать исходник по рисунку, тогда --size задаёт размер самого предмета")
    ap.add_argument("--palette", default="turbo-full", help="turbo-full (57 цветов) или turbo32 (строгая)")
    ap.add_argument("--godot", help="ещё скопировать в art/ проекта Godot по этому пути, например bg/sky.png")
    a = ap.parse_args()

    pal = load_palette(os.path.join(PALETTE_DIR, a.palette + ".hex"))
    im = Image.open(a.src).convert("RGB")
    if a.key and a.crop:
        bbox = content_bbox(im, a.tol)
        if bbox:
            im = im.crop(bbox)
    w, h = (int(v) for v in a.size.lower().split("x"))
    if w == 0:
        w = round(im.width * h / im.height)
    if h == 0:
        h = round(im.height * w / im.width)

    out = downscale(im, w, h, pal, a.key, a.tol)

    if a.trim and out.getbbox():
        out = out.crop(out.getbbox())

    os.makedirs(os.path.dirname(os.path.abspath(a.dst)), exist_ok=True)
    out.save(a.dst)
    data = out.get_flattened_data() if hasattr(out, "get_flattened_data") else out.getdata()
    used = len({c for c in data if c[3]})
    print(f"{a.dst}: {out.width}×{out.height}, цветов {used} из {len(pal)}")
    if a.godot:
        target = os.path.join(GODOT_ART, a.godot)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        out.save(target)
        print(f"скопировано в проект Godot: art/{a.godot}")


if __name__ == "__main__":
    main()
