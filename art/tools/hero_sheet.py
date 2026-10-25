#!/usr/bin/env python3
"""Собирает лист анимаций Геннадия из полосок GPT (по одной картинке на анимацию).

Каждая полоска: кадры в один ряд на розовом фоне #FF00FF. Скрипт
1. делит полоску на кадры по пустым промежуткам (если их столько, сколько ждём)
   или на равные части;
2. берёт один масштаб на всю полоску, чтобы кадры не «дышали» размером;
3. сводит каждый кадр к пикселям и палитре (как pixelize.py);
4. ставит кадры в ячейки 64×64: стоящих ногами на строку 60, летящих по центру;
5. пишет gennady_sheet.png (строка = анимация) и превью ×4.

  python3 hero_sheet.py ../gpt/raw ../gennady/out --godot gennady_sheet.png

Ряды листа (их же читает main.gd): idle 3, walk 6, eat 4, launch 4, fly 4, fall 3, land 3.
"""
import argparse
import importlib.util
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("pixelize", os.path.join(HERE, "pixelize.py"))
px = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(px)

CELL = 64
BASE = 60  # строка, на которой стоят ноги

# файл, кадров, как ставить, по какому кадру мерить, до какого размера
# «h» — высота, «m» — большая сторона (для лежачей позы в полёте)
STRIPS = [
    ("idle", "12_gennady_idle.png", 3, "feet", "h", 48),
    ("walk", "13_gennady_walk.png", 6, "feet", "h", 48),
    ("eat", "14_gennady_eat.png", 4, "feet", "h", 48),
    ("launch", "15_gennady_launch.png", 4, "feet", "first_h", 48),
    ("fly", "16_gennady_fly.png", 4, "center", "m", 46),
    ("fall", "17_gennady_fall.png", 6, "feet", "first_h", 39),
]
# падение и посадка нарисованы в одной полоске
SPLIT = {"fall": (("fall", 0, 3), ("land", 3, 6))}
ROWS = ["idle", "walk", "eat", "launch", "fly", "fall", "land"]


def fg_mask(im, tol):
    a = np.asarray(im).astype(int)
    return ~((a[..., 0] > 255 - tol) & (a[..., 2] > 255 - tol) & (a[..., 1] < tol + 40))


def smooth_down(im, fg, w, h):
    """Усреднение по клетке без розового: у персонажа много мелких деталей (глаза, пальцы),
    и «самый частый цвет» их рвёт, а среднее сохраняет. Розовый в среднее не попадает,
    поэтому по краю нет каймы."""
    a = np.asarray(im).astype(np.float64) * fg[..., None]
    m = fg.astype(np.float64)
    rgb = np.stack([np.asarray(Image.fromarray(a[..., c]).resize((w, h), Image.BOX)) for c in range(3)], -1)
    cov = np.asarray(Image.fromarray(m).resize((w, h), Image.BOX))
    out = np.zeros((h, w, 4), np.uint8)
    on = cov > 0.45
    out[on, :3] = np.clip(rgb[on] / cov[on, None], 0, 255).astype(np.uint8)
    out[on, 3] = 255
    return Image.fromarray(out, "RGBA")


def outline(fr, color=(0x1A, 0x16, 0x23, 255)):
    """Тёмная обводка в 1 точку снаружи силуэта, как у Тиграна и предметов."""
    a = np.asarray(fr).copy()
    on = a[..., 3] > 0
    ring = np.zeros_like(on)
    ring[1:] |= on[:-1]
    ring[:-1] |= on[1:]
    ring[:, 1:] |= on[:, :-1]
    ring[:, :-1] |= on[:, 1:]
    ring &= ~on
    a[ring] = color
    return Image.fromarray(a, "RGBA")


def quantize_sheet(sheet, colors):
    """Общая палитра на весь лист: оттенки волос и кожи остаются своими, кадры не мерцают цветом."""
    alpha = sheet.getchannel("A")
    q = sheet.convert("RGB").quantize(colors, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    out = q.convert("RGBA")
    out.putalpha(alpha.point(lambda v: 255 if v else 0))
    return out


def split_frames(fg, n):
    """Границы кадров по столбцам: сначала по пустым промежуткам, иначе поровну."""
    cols = fg.sum(axis=0) > 2
    segs, start = [], None
    for x, on in enumerate(cols):
        if on and start is None:
            start = x
        elif not on and start is not None:
            segs.append([start, x])
            start = None
    if start is not None:
        segs.append([start, len(cols)])
    # мелкие куски (звёздочки, капли) и близкие соседи склеиваются, пока кусков больше n
    while len(segs) > n:
        gaps = [segs[i + 1][0] - segs[i][1] for i in range(len(segs) - 1)]
        i = int(np.argmin(gaps))
        segs[i] = [segs[i][0], segs[i + 1][1]]
        del segs[i + 1]
    if len(segs) == n:
        return [tuple(s) for s in segs]
    x0, x1 = int(np.nonzero(cols)[0].min()), int(np.nonzero(cols)[0].max()) + 1
    w = (x1 - x0) / n
    return [(int(x0 + i * w), int(x0 + (i + 1) * w)) for i in range(n)]


def build(raw, outdir, pal, tol, mode="smooth", colors=40):
    rows = {}
    for name, fn, n, anchor, measure, target in STRIPS:
        path = os.path.join(raw, fn)
        if not os.path.exists(path):
            print(f"нет {fn}: ряд {name} останется пустым")
            continue
        im = Image.open(path).convert("RGB")
        fg = fg_mask(im, tol)
        boxes = []
        for x0, x1 in split_frames(fg, n):
            sub = fg[:, x0:x1]
            ys, xs = np.nonzero(sub)
            boxes.append((x0 + int(xs.min()), int(ys.min()), x0 + int(xs.max()) + 1, int(ys.max()) + 1))
        hs = [b[3] - b[1] for b in boxes]
        ms = [max(b[2] - b[0], b[3] - b[1]) for b in boxes]
        ref = {"h": max(hs), "first_h": hs[0], "m": max(ms)}[measure]
        k = target / ref
        frames = []
        for b in boxes:
            w, h = max(1, round((b[2] - b[0]) * k)), max(1, round((b[3] - b[1]) * k))
            if mode == "smooth":
                fr = smooth_down(im.crop(b), fg[b[1]:b[3], b[0]:b[2]], w, h)
            else:
                fr = px.downscale(im.crop(b), w, h, pal, key=True, tol=tol)
            if fr.getbbox():
                fr = fr.crop(fr.getbbox())
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            fw, fh = fr.size
            if anchor == "feet":
                pos = ((CELL - fw) // 2, BASE - fh)
            else:
                pos = ((CELL - fw) // 2, (CELL - fh) // 2)
            cell.alpha_composite(fr, (max(1, pos[0]), max(1, pos[1])))
            if mode == "smooth":
                cell = outline(cell)
            frames.append(cell)
        print(f"{name}: {len(frames)} кадров, масштаб {k:.3f}, высоты {[f.getbbox()[3] - f.getbbox()[1] for f in frames]}")
        for row, a, z in SPLIT.get(name, ((name, 0, n),)):
            rows[row] = frames[a:z]

    sheet = Image.new("RGBA", (CELL * 6, CELL * len(ROWS)), (0, 0, 0, 0))
    for r, name in enumerate(ROWS):
        for c, fr in enumerate(rows.get(name, [])[:6]):
            sheet.alpha_composite(fr, (c * CELL, r * CELL))
    if mode == "smooth":
        sheet = quantize_sheet(sheet, colors)
    os.makedirs(outdir, exist_ok=True)
    sheet.save(os.path.join(outdir, "gennady_sheet.png"))
    bg = Image.new("RGBA", sheet.size, (0x95, 0xB9, 0xE3, 255))
    bg.alpha_composite(sheet)
    bg.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(outdir, "gennady_sheet_x4.png"))
    return sheet


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("raw", help="папка с полосками 12_…17_")
    ap.add_argument("outdir")
    ap.add_argument("--tol", type=int, default=90)
    ap.add_argument("--palette", default="turbo-full")
    ap.add_argument("--mode", default="smooth", help="smooth: среднее по клетке и общая палитра листа (для персонажей); mode: самый частый цвет и палитра игры")
    ap.add_argument("--colors", type=int, default=40, help="цветов в палитре листа в режиме smooth")
    ap.add_argument("--godot", help="ещё положить в art/ проекта Godot по этому пути")
    a = ap.parse_args()
    pal = px.load_palette(os.path.join(px.PALETTE_DIR, a.palette + ".hex"))
    sheet = build(a.raw, a.outdir, pal, a.tol, a.mode, a.colors)
    if a.godot:
        target = os.path.join(px.GODOT_ART, a.godot)
        os.makedirs(os.path.dirname(target), exist_ok=True)
        sheet.save(target)
        print(f"скопировано в проект Godot: art/{a.godot}")


if __name__ == "__main__":
    main()
