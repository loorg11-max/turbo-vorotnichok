#!/usr/bin/env python3
"""Режет лист на розовом фоне (#FF00FF) на отдельные предметы.

Ищет связные области не-фона, склеивает близкие куски (например, пар над миской),
сортирует по строкам слева направо и сохраняет каждый кусок как отдельный PNG
с исходным розовым фоном, чтобы дальше прогнать через pixelize.py --key --crop.

  python3 split_sheet.py 08_basic_food.png out/base --names lavash,chicken,cabbage
"""
import argparse
import os

import numpy as np
from PIL import Image


def keep_main(piece, tol):
    """Оставить самую большую связную область не-фона, остальное закрасить розовым (#FF00FF)."""
    arr = np.asarray(piece).astype(int)
    fg = ~((arr[..., 0] > 255 - tol) & (arr[..., 2] > 255 - tol) & (arr[..., 1] < tol + 40))
    h, w = fg.shape
    lab = np.zeros((h, w), int)
    sizes = [0]
    for y0, x0 in zip(*np.nonzero(fg)):
        if lab[y0, x0]:
            continue
        k = len(sizes)
        lab[y0, x0] = k
        stack, n = [(y0, x0)], 0
        while stack:
            y, x = stack.pop()
            n += 1
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and fg[ny, nx] and not lab[ny, nx]:
                    lab[ny, nx] = k
                    stack.append((ny, nx))
        sizes.append(n)
    out = np.asarray(piece).copy()
    out[(lab != int(np.argmax(sizes))) & fg] = (255, 0, 255)
    return Image.fromarray(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("outdir")
    ap.add_argument("--names", help="имена через запятую в порядке чтения")
    ap.add_argument("--tol", type=int, default=90)
    ap.add_argument("--cell", type=int, default=8, help="шаг сетки поиска, пикс. исходника")
    ap.add_argument("--min", type=int, default=6, help="минимальный размер куска в клетках")
    ap.add_argument("--grid", help="КОЛОНКИxСТРОКИ: просто делить рисунок на равные ячейки, когда предметы стоят ровной сеткой")
    ap.add_argument("--main", action="store_true", help="с --grid: в ячейке оставить только самый большой кусок (обрезки соседей закрасить фоном)")
    a = ap.parse_args()

    im = Image.open(a.src).convert("RGB")
    arr = np.asarray(im).astype(int)
    fg = ~((arr[..., 0] > 255 - a.tol) & (arr[..., 2] > 255 - a.tol) & (arr[..., 1] < a.tol + 40))
    if a.grid:
        cols, rows_n = (int(v) for v in a.grid.lower().split("x"))
        ys, xs = np.nonzero(fg)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        cw, ch = (x1 - x0) / cols, (y1 - y0) / rows_n
        names = a.names.split(",") if a.names else [f"{i + 1:02d}" for i in range(cols * rows_n)]
        os.makedirs(a.outdir, exist_ok=True)
        for i, n in enumerate(names[: cols * rows_n]):
            cx, cy = i % cols, i // cols
            box = (int(x0 + cx * cw), int(y0 + cy * ch), int(x0 + (cx + 1) * cw), int(y0 + (cy + 1) * ch))
            piece = im.crop(box)
            if a.main:
                piece = keep_main(piece, a.tol)
            piece.save(os.path.join(a.outdir, n + ".png"))
        print(f"нарезано по сетке {cols}×{rows_n}: {len(names)}")
        return
    c = a.cell
    gh, gw = fg.shape[0] // c, fg.shape[1] // c
    grid = fg[: gh * c, : gw * c].reshape(gh, c, gw, c).mean(axis=(1, 3)) > 0.05
    # раздуваем на клетку, чтобы склеить близкие куски одного предмета
    g2 = grid.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            g2 |= np.roll(np.roll(grid, dy, 0), dx, 1)
    seen = np.zeros_like(g2)
    boxes = []
    for y in range(gh):
        for x in range(gw):
            if g2[y, x] and not seen[y, x]:
                stack = [(y, x)]
                seen[y, x] = True
                ys, xs = [], []
                while stack:
                    cy, cx = stack.pop()
                    ys.append(cy)
                    xs.append(cx)
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < gh and 0 <= nx < gw and g2[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            stack.append((ny, nx))
                if max(ys) - min(ys) + 1 >= a.min and max(xs) - min(xs) + 1 >= a.min:
                    boxes.append((min(xs) * c, min(ys) * c, (max(xs) + 1) * c, (max(ys) + 1) * c))
    # строки: кусок попадает в строку, если его центр по высоте внутри строки первого куска
    boxes.sort(key=lambda b: (b[1] + b[3]) / 2)
    rows = []
    for b in boxes:
        cy = (b[1] + b[3]) / 2
        if rows and rows[-1][0][1] <= cy <= rows[-1][0][3]:
            rows[-1].append(b)
        else:
            rows.append([b])
    ordered = [b for r in rows for b in sorted(r, key=lambda b: b[0])]
    names = a.names.split(",") if a.names else [f"{i + 1:02d}" for i in range(len(ordered))]
    os.makedirs(a.outdir, exist_ok=True)
    for b, n in zip(ordered, names):
        im.crop(b).save(os.path.join(a.outdir, n + ".png"))
    print(f"найдено кусков: {len(ordered)}, имён: {len(names)}")


if __name__ == "__main__":
    main()
