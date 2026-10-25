#!/usr/bin/env python3
"""Маленькие копии персонажей из картинок GPT, например Тигран в окошке фургона.

Картинка делится на равные столбцы (по одному персонажу), каждый сводится к нужной
высоте тем же способом, что и Геннадий (среднее по клетке без розового, обводка,
своя палитра). Отдельные крошки (капли, звёздочки) выбрасываются.

  python3 small_sprite.py ../gpt/raw/07_tigran.png ../gpt/out --cols 3 \
      --names happy,shock,grumpy --height 30 --prefix tigran_small --godot gpt
"""
import argparse
import importlib.util
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


hs = _load("hero_sheet")
px = _load("pixelize")


def drop_specks(fr, keep=0.03):
    """Оставляет только куски, в которых не меньше keep от всех непрозрачных точек."""
    a = np.asarray(fr).copy()
    on = a[..., 3] > 0
    seen = np.zeros_like(on)
    total = on.sum()
    h, w = on.shape
    for y0, x0 in zip(*np.nonzero(on)):
        if seen[y0, x0]:
            continue
        stack, part = [(y0, x0)], []
        seen[y0, x0] = True
        while stack:
            y, x = stack.pop()
            part.append((y, x))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and on[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        if len(part) < total * keep:
            for y, x in part:
                a[y, x] = 0
    return Image.fromarray(a, "RGBA")


def small(im, height, tol, colors):
    fg = hs.fg_mask(im, tol)
    ys, xs = np.nonzero(fg)
    b = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    k = height / (b[3] - b[1])
    w = max(1, round((b[2] - b[0]) * k))
    fr = hs.smooth_down(im.crop(b), fg[b[1]:b[3], b[0]:b[2]], w, height)
    fr = drop_specks(fr)
    fr = fr.crop(fr.getbbox())
    cell = Image.new("RGBA", (fr.width + 2, fr.height + 2), (0, 0, 0, 0))
    cell.alpha_composite(fr, (1, 1))
    return hs.quantize_sheet(hs.outline(cell), colors)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("outdir")
    ap.add_argument("--cols", type=int, default=1, help="сколько персонажей в ряд на картинке")
    ap.add_argument("--names", required=True, help="имена через запятую, по одному на столбец")
    ap.add_argument("--height", type=int, required=True, help="высота в игровых точках")
    ap.add_argument("--prefix", required=True)
    ap.add_argument("--tol", type=int, default=90)
    ap.add_argument("--colors", type=int, default=32)
    ap.add_argument("--godot", help="папка внутри art/ проекта Godot, куда ещё положить")
    a = ap.parse_args()
    src = Image.open(a.src).convert("RGB")
    names = a.names.split(",")
    w = src.width // a.cols
    os.makedirs(a.outdir, exist_ok=True)
    for i, name in enumerate(names):
        fr = small(src.crop((i * w, 0, (i + 1) * w, src.height)), a.height, a.tol, a.colors)
        fn = f"{a.prefix}_{name}.png"
        fr.save(os.path.join(a.outdir, fn))
        if a.godot:
            fr.save(os.path.join(px.GODOT_ART, a.godot, fn))
        print(f"{fn}: {fr.width}×{fr.height}")


if __name__ == "__main__":
    main()
