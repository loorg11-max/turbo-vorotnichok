"""Значки достижений для Steam: 256×256 JPG, открытый и закрытый (серый) на каждое достижение.

Рисуются из картинок игры: холст 128×128 в стиле значка exe (синий фон, жёлтая рамка),
картинка по центру с целым увеличением, затем всё ×2. Если нужной картинки нет, ставится кубок,
после её прихода скрипт надо запустить снова.

    python3 art/tools/steam_icons.py      # из корня общей папки
Пишет art/steam/achievements/ACH_<ID>.jpg, ACH_<ID>_locked.jpg и лист для просмотра art/steam/achievements.png.
"""
import math
import os
import re
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
GAME = os.path.join(ROOT, "godot", "turbo-vorotnichok")
OUT = os.path.join(ROOT, "art", "steam", "achievements")
N = 128
INNER = 112
OUTLINE = (9, 12, 28)
NAVY = (30, 58, 110)
NAVY_LIGHT = (40, 73, 126)
GOLD = (255, 216, 74)
GRAY = (107, 104, 120)
GAS = [(208, 237, 78), (162, 213, 118), (126, 194, 107), (63, 122, 58)]

# достижение: что нарисовать. hero:строка,кадр — кадр Геннадия; lesha:строка,кадр — коллеги Лёши; food:id; gpt:файл; ui:файл из art/ui; medal:цвета; cup
PICK = {
    "first": "hero:4,0", "dud": "hero:6,1", "office": "hero:3,2",
    "bronze": "ui:icon_medal_bronze", "silver": "ui:icon_medal_silver", "clouds": "gpt:cloud_small",
    "far": "gpt:mark_kite", "district": "trail", "long": "gpt:mark_balloon", "perfect": "hero:3,1",
    "boom": "food:fizz", "salute": "food:sweetfizz", "squeeze": "hero:5,1",
    "dish1": "food:shawarma", "dish6": "food:double", "dish_all": "food:lunch", "mush10": "food:mush",
    "three": "three", "light": "food:tea", "regular": "gpt:tigran_small_happy", "lift": "hero:5,0",
    "daily": "food:coffee", "daily5": "food:ccoffee",
    "dish_all_pyshki": "food:pyshka", "friends": "food:shpyshka", "sweet": "food:psugar", "catch": "food:pjam",
    "dish_all_chebureki": "food:cheburek", "rail": "food:fire",
    "dish_all_hotdogs": "food:hotdog", "goal": "food:mdog",
    "space": "gpt:space_sputnik",
    "paris": "gpt:border", "china": "gpt:border",
    "duel": "lesha:3,2",
    "dish_all_canteen": "food:complex", "buffet": "food:kpure", "compote": "food:dcompote",
}


def awards():
    src = open(os.path.join(GAME, "scripts", "awards.gd"), encoding="utf-8").read()
    return re.findall(r'^\t\["(\w+)", "([^"]+)", "([^"]+)"', src, re.M)


def gpt(name):
    p = os.path.join(GAME, "art", "gpt", name + ".png")
    return Image.open(p).convert("RGBA") if os.path.exists(p) else None


def hero(row, col, who="gennady"):
    sheet = Image.open(os.path.join(GAME, "art", who + "_sheet.png")).convert("RGBA")
    fr = sheet.crop((col * 64, row * 64, col * 64 + 64, row * 64 + 64))
    return fr.crop(fr.getbbox())


def medal(main, dark):
    main, dark = tuple(bytes.fromhex(main)), tuple(bytes.fromhex(dark))
    img = Image.new("RGBA", (12, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(12):
            c = None
            if y < 6 and (abs(x - 3 - y * 0.5) < 1.5 or abs(x - 8 + y * 0.5) < 1.5):
                c = (232, 52, 42) if y < 4 else (201, 20, 16)
            d = math.dist((x + 0.5, y + 0.5), (6, 10.5))
            if d < 5.5:
                c = OUTLINE
            if d < 4.6:
                c = main if (x + y) % 5 != 0 or d > 3.0 else dark
            if 3.6 < d < 4.6 and y > 10:
                c = dark
            if c:
                img.putpixel((x, y), c + (255,))
    return img


CUP = ["..OOOOOOOOOO..", "OOOHYYYYYYDOOO", "OYOHYYYYYYDOYO", "OYOHYYYYYYDOYO", ".OOHYYYYYYDOO.",
       "..OHYYYYYYDO..", "...OHYYYYDO...", "....OOYDOO....", ".....OYDO.....", ".....OYDO.....",
       "....OOOOOO....", "...OHYYYYDO...", "...OOOOOOOO..."]


def cup():
    cols = {"O": OUTLINE, "Y": GOLD, "H": (255, 243, 168), "D": (200, 116, 30)}
    img = Image.new("RGBA", (14, 13), (0, 0, 0, 0))
    for y, row in enumerate(CUP):
        for x, ch in enumerate(row):
            if ch in cols:
                img.putpixel((x, y), cols[ch] + (255,))
    return img


def trail():
    """Летящий Геннадий и газовый след за ним: дальность."""
    h = hero(4, 0)
    img = Image.new("RGBA", (h.width + 44, h.height), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (x, r) in enumerate([(6, 3), (15, 4), (26, 5), (38, 6)]):
        y = h.height // 2 + 4 - i
        d.ellipse((x - r - 1, y - r - 1, x + r + 1, y + r + 1), fill=OUTLINE)
        d.ellipse((x - r, y - r, x + r, y + r), fill=GAS[3 - i])
    img.alpha_composite(h, (44, 0))
    return img


def three():
    s = gpt("food_shawarma")
    img = Image.new("RGBA", (s.width * 3 - 4, s.height + 8), (0, 0, 0, 0))
    for i, y in enumerate([8, 0, 8]):
        img.alpha_composite(s, (i * (s.width - 2), y))
    return img


def picture(kind):
    if kind.startswith("hero:"):
        r, c = map(int, kind[5:].split(","))
        return hero(r, c)
    if kind.startswith("lesha:"):
        r, c = map(int, kind[6:].split(","))
        return hero(r, c, "lesha")
    if kind.startswith("food:"):
        return gpt("food_" + kind[5:])
    if kind.startswith("gpt:"):
        return gpt(kind[4:])
    if kind.startswith("ui:"):
        p = os.path.join(GAME, "art", "ui", kind[3:] + ".png")
        return Image.open(p).convert("RGBA") if os.path.exists(p) else None
    if kind.startswith("medal:"):
        return medal(*kind[6:].split(","))
    return {"trail": trail, "three": three}[kind]()


def badge(pic, on):
    img = Image.new("RGB", (N, N), OUTLINE)
    d = ImageDraw.Draw(img)
    frame = GOLD if on else GRAY
    d.rounded_rectangle((2, 2, N - 3, N - 3), 18, fill=frame)
    d.rounded_rectangle((8, 8, N - 9, N - 9), 13, fill=NAVY if on else (44, 44, 56))
    # лёгкий свет сзади картинки
    d.ellipse((24, 24, N - 25, N - 25), fill=NAVY_LIGHT if on else (52, 52, 64))
    k = max(1, min(INNER // pic.width, INNER // pic.height))
    p = pic.resize((pic.width * k, pic.height * k), Image.NEAREST)
    if not on:
        g = p.convert("LA").convert("RGBA")
        a = p.getchannel("A")
        g = Image.blend(Image.new("RGBA", g.size, (44, 44, 56, 255)), g, 0.55)
        g.putalpha(a)
        p = g
    img.paste(p, ((N - p.width) // 2, (N - p.height) // 2), p)
    return img.resize((N * 2, N * 2), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    rows = awards()
    sheet = Image.new("RGB", (8 * 132 + 4, ((len(rows) + 3) // 4) * 132 + 4), OUTLINE)
    stub = []
    for i, (aid, name, _) in enumerate(rows):
        pic = picture(PICK.get(aid, "cup"))
        if pic is None:
            pic = cup()
            stub.append(aid)
        api = "ACH_" + aid.upper()
        for on, suffix in ((True, ""), (False, "_locked")):
            b = badge(pic, on)
            b.save(os.path.join(OUT, api + suffix + ".jpg"), quality=95)
            sheet.paste(b.resize((128, 128), Image.NEAREST), ((i % 4) * 264 + (0 if on else 132) + 4, (i // 4) * 132 + 4))
    sheet.save(os.path.join(OUT, "..", "achievements.png"))
    print(len(rows), "достижений; без своих картинок (кубок):", ", ".join(stub) or "нет")


if __name__ == "__main__":
    main()
