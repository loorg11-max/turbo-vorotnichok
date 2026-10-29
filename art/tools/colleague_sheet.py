"""Коллега Лёша для дуэли (0.8): тот же лист анимаций Геннадия, перекрашенный по цветам.
Тёмные волосы, голубая рубашка, серые брюки. Галстук остаётся красным: рот у листа того же цвета, и перекрасить
галстук отдельно без пятен на лице не выходит. Кожа, обувь и обводка как были.
Запуск: python3 art/tools/colleague_sheet.py  →  godot/turbo-vorotnichok/art/lesha_sheet.png"""
import colorsys
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "godot", "turbo-vorotnichok", "art")


def hls(c):
    return colorsys.rgb_to_hls(*(v / 255 for v in c[:3]))


def rgb(h, l, s, a):
    return tuple(round(v * 255) for v in colorsys.hls_to_rgb(h % 1.0, min(l, 1.0), min(s, 1.0))) + (a,)


def recolor(c):
    h, l, s = hls(c)
    if (s < 0.12 and l > 0.55) or (s < 0.4 and l > 0.9):  # рубашка: белая → голубая
        return rgb(0.57, l * 0.93, 0.55, c[3])
    if 0.58 < h < 0.7 and s > 0.3 and l < 0.5:  # брюки: синие → серые
        return rgb(0.62, l * 1.1, s * 0.18, c[3])
    if 0.015 < h < 0.075 and s > 0.6 and l < 0.5:  # волосы: рыжие → тёмно-каштановые
        return rgb(0.07, l * 0.5, s * 0.45, c[3])
    return c


def main():
    im = Image.open(os.path.join(ART, "gennady_sheet.png")).convert("RGBA")
    px = im.load()
    cache = {}
    for y in range(im.height):
        for x in range(im.width):
            c = px[x, y]
            if c[3] == 0:
                continue
            if c not in cache:
                cache[c] = recolor(c)
            px[x, y] = cache[c]
    im.save(os.path.join(ART, "lesha_sheet.png"))
    print("lesha_sheet.png", im.size, "цветов заменено:", sum(1 for k, v in cache.items() if k != v))


if __name__ == "__main__":
    main()
