"""Иконка «Масло из фритюра» 28×28, нарисованная по точкам.

Корзина фритюра из картинки GPT 25 в 28 точках превращается в кашу из сетки, поэтому её рисуем сами
в палитре проекта: проволочная корзина с ручкой, внутри золотое масло, снизу капли.
    python3 art/tools/draw_oil.py OUT.png [--godot gpt/food_oil.png]
"""
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT_ART = os.path.join(HERE, "..", "..", "godot", "turbo-vorotnichok", "art")

# O обводка, M металл, W блик, S тень металла, G масло, Y светлое масло, R тёмное масло, H ручка
ART = [
    "..........................OOO",
    ".........................OHHHO",
    "........................OHHHHO",
    ".......................OHHHHO.",
    "......................OSOOOO..",
    ".....................OSO......",
    "....................OSO.......",
    "...................OSO........",
    "..OOOOOOOOOOOOOOOOOMOOO.......",
    ".OWWWWWWWWWWWWWWWWWWWWMO......",
    ".OMOMMOMMOMMOMMOMMOMMOSO......",
    ".OMYGMYGMYGMYGMYGMYGMOSO......",
    ".OMMMMMMMMMMMMMMMMMMMMSO......",
    ".OMGOMGOMGOMGOMGOMGOMOSO......",
    ".OMGYMGYMGYMGYMGYMGYMOSO......",
    ".OMMMMMMMMMMMMMMMMMMMMSO......",
    ".OMGGMGGMGGMGGMGGMGGMOSO......",
    ".OMRGMRGMRGMRGMRGMRGMOSO......",
    ".OMMMMMMMMMMMMMMMMMMMMSO......",
    ".OMRGMRRMGRMRGMRRMGRMOSO......",
    ".OSSSSSSSSSSSSSSSSSSSSSO......",
    "..OOGOOOOOOOGOOOOOOGOOO.......",
    "...OGO.....OYGO....OGO........",
    "...OGO......OGO.....O.........",
    "...OYO......OGO...............",
    "....O.......OYO...............",
    ".............O................",
]
COL = {"O": "090c1c", "M": "bcb6ad", "W": "e2e0e7", "S": "7b6f74", "G": "f59a23", "Y": "ffd84a",
       "R": "c8741e", "H": "544f4f"}


def main():
    w = max(len(r) for r in ART)
    img = Image.new("RGBA", (w, len(ART)), (0, 0, 0, 0))
    for y, row in enumerate(ART):
        for x, ch in enumerate(row):
            if ch in COL:
                img.putpixel((x, y), tuple(bytes.fromhex(COL[ch])) + (255,))
    img = img.crop(img.getbbox())
    # снизу пустая строка не нужна, но высота как у остальных иконок: 28
    canvas = Image.new("RGBA", (img.width, 28), (0, 0, 0, 0))
    canvas.alpha_composite(img, (0, 28 - img.height))
    canvas.save(sys.argv[1])
    if "--godot" in sys.argv:
        dst = os.path.join(GODOT_ART, sys.argv[sys.argv.index("--godot") + 1])
        canvas.save(dst)
        print("скопировано в проект Godot:", dst)


if __name__ == "__main__":
    main()
