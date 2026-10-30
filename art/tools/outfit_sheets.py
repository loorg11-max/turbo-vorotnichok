"""Наряды Геннадия (1.0): тот же лист анимаций, перекрашенный по ролям пикселей, и мелочи поверх.
Роли: рубашка (белые), брюки (синие), галстук (красное, что касается рубашки; рот того же цвета не трогаем),
волосы, остальное (кожа, обувь, обводка). Шапки ставятся на макушку, шарф на ворот; положение берётся
из самого листа по каждому кадру. Хвост шарфа и кисточки шевелятся от кадра к кадру: в полёте развеваются.
Запуск: python3 art/tools/outfit_sheets.py  →  godot/turbo-vorotnichok/art/outfit_<id>_sheet.png и превью в art/outfits_preview.png"""
import colorsys
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "godot", "turbo-vorotnichok", "art")
F = 64
ANIMS = [("idle", 3), ("walk", 6), ("eat", 4), ("launch", 4), ("fly", 4), ("fall", 3), ("land", 3)]
OUT = (0x19, 0x16, 0x23, 255)  # обводка листа


def hx(s):
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


def role(c):
    if c[3] == 0:
        return None
    h, l, s = colorsys.rgb_to_hls(*(v / 255 for v in c[:3]))
    if (s < 0.12 and l > 0.55) or (s < 0.4 and l > 0.9) or (0.65 < h < 0.75 and l > 0.45 and s < 0.2):
        return "shirt"
    if 0.58 < h < 0.7 and s > 0.3 and l < 0.5:
        return "pants"
    if (h < 0.025 or h > 0.95) and s > 0.8:
        return "red"
    if 0.015 < h < 0.075 and s > 0.6 and l < 0.5:
        return "hair"
    return "other"


def comps(pts):
    pts = set(pts)
    out = []
    while pts:
        p = pts.pop()
        st, c = [p], [p]
        while st:
            x, y = st.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    q = (x + dx, y + dy)
                    if q in pts:
                        pts.remove(q)
                        st.append(q)
                        c.append(q)
        out.append(c)
    return out


def light(c):
    return colorsys.rgb_to_hls(*(v / 255 for v in c[:3]))[1]


def ramp(cols, l, lo=0.3, hi=1.0):
    """Цвет из рампы cols (от тёмного к светлому) по светлоте l исходного пикселя."""
    t = min(max((l - lo) / (hi - lo), 0.0), 0.999)
    return hx(cols[int(t * len(cols))])


class Frame:
    """Один кадр 64×64: роли пикселей, галстук, макушка, ворот."""

    def __init__(self, im, ox, oy, name, i):
        self.ox, self.oy, self.name, self.i = ox, oy, name, i
        px = im.load()
        self.px = px
        self.role = {}
        by = {}
        for y in range(F):
            for x in range(F):
                r = role(px[ox + x, oy + y])
                if r:
                    self.role[(x, y)] = r
                    by.setdefault(r, []).append((x, y))
        shirt = max(comps(by.get("shirt", [])), key=len)
        self.shirt = set(shirt)
        hair = max(comps(by.get("hair", [])), key=len)
        hb = (min(p[0] for p in hair), min(p[1] for p in hair), max(p[0] for p in hair), max(p[1] for p in hair))
        # галстук: красное вне головы; рот того же цвета лежит внутри головы
        self.tie = set()
        for c in comps(by.get("red", [])):
            cx = sum(p[0] for p in c) / len(c)
            cy = sum(p[1] for p in c) / len(c)
            if not (hb[0] <= cx <= hb[2] and hb[1] <= cy <= hb[3]):
                self.tie |= set(c)
        # узел галстука: точка галстука ближе всех к низу головы; на нём сидит шарф
        chin = ((hb[0] + hb[2]) / 2, hb[3])
        self.knot = min(self.tie, key=lambda p: (p[0] - chin[0]) ** 2 + (p[1] - chin[1]) ** 2) if self.tie else (chin[0], chin[1] + 2)
        top = min(p[1] for p in hair)
        xs = [p[0] for p in hair if p[1] <= top + 3]
        self.crown = ((min(xs) + max(xs)) // 2, top)
        hxs = [p[0] for p in hair]
        self.head = (min(hxs), max(hxs))
        st = min(p[1] for p in shirt)
        self.neck_y = st
        row = [p[0] for p in shirt if p[1] <= st + 1]
        self.neck = (min(row), max(row))


OUTFITS = {
    # рубашка: рампа от тени к свету; узор поверх; брюки; галстук; шапка; шарф
    "friday": {"shirt": ["1d6f73", "2a9d8f", "3cc4b4", "6fe0cf"], "flowers": ["ffd23f", "ff7a3d"],
               "tie": ["8a1c7c", "c43aa8"]},
    "fan": {"shirt": ["7a1418", "a81e24", "c42428", "d83a36"], "hat": "cap", "scarf": ["2f6fd0", "f4f4f4"]},
    "chef": {"pants_check": True, "hat": "chef", "tie": ["c8c8c8", "f4f4f4"]},
    "cosmo": {"shirt": ["9a3b0c", "d4581a", "f07a2a", "ffab5e"], "pants": ["7a2e08", "a8400f", "d4581a"],
              "tie": ["d4581a", "f07a2a"], "hat": "helmet"},
    "tourist": {"stripes": ["1f3a8a"], "hat": "beret"},
    "director": {"shirt": ["15161f", "24263a", "34374f", "4a4e6a"], "pants": ["0f1018", "1c1d2b", "2a2c40"],
                 "tie": ["a87a12", "e0b02a", "ffe066"], "collar": True},
}

# шапки, нижняя строка садится на макушку; O — обводка, буквы — цвета; Геннадий смотрит вправо
CAP = [
    ".....OOOOOO.......",
    "...OOBBBBBBOO.....",
    "..OBBBBWWBBBBO....",
    ".OBBBBBWWBBBBBO...",
    ".OBBBBBBBBBBBBO...",
    "OWWWWWWWWWWWWWOOOO",
    ".OOOOOOOOOOOOOBBBO",
    "..............OOO.",
]
CHEF = [
    "...OOO..OOO...",
    "..OWWWOOWWWO..",
    ".OWWWWWWWWWWO.",
    ".OWWWWWWWWWWO.",
    ".OWWWWWWWWWWO.",
    "..OWWWWWWWWO..",
    "..OWWWWWWWWO..",
    ".OGGGGGGGGGGO.",
    ".OWWWWWWWWWWO.",
    ".OOOOOOOOOOOO.",
]
BERET = [
    "........OO.....",
    ".....OOOOOO....",
    "...OOKKKKKKOO..",
    ".OOKKKKKKKKKKO.",
    "OKKKKKKKKKKKKKO",
    "OKKKKKKKKKKKKKO",
    ".OOOOOOOOOOOOO.",
]
HELMET = [  # шлемофон, как у Гагарина: купол, ремешок, наушник сбоку
    "....OOOOOOOO....",
    "..OOWWWWWWWWOO..",
    ".OWWWWWWWWWWWWO.",
    "OWWWWRRRRRWWWWWO",
    "OWWWWWWWWWWWWWWO",
    "OWWWWWWWWWOOOOO.",
    "OWWWWWWWWO......",
    "OWWWWOOOWO......",
    "OWWWOGGGOO......",
    "OWWWOGGGO.......",
    "OWWWWOOOO.......",
    "OWWWWWWO........",
    "OWWWWWWO........",
    ".OWWWWWO........",
    "..OOOOO.........",
]
HAT_COL = {"B": hx("2f6fd0"), "W": hx("f4f4f4"), "G": hx("c9c4cf"), "K": hx("2a2433"), "R": hx("d83a2a"), "O": OUT}
# где у шапки макушка относительно нижней строки (насколько шапка налезает на волосы) и сдвиг вбок
HATS = {"cap": (CAP, 6, 1), "chef": (CHEF, 5, -1), "beret": (BERET, 4, 1), "helmet": (HELMET, 14, -2)}


def stamp(px, pat, cx, by, dx=0):
    """Нарисовать шапку pat: центр по x в cx (с учётом сдвига dx), нижняя строка на y = by."""
    h, w = len(pat), len(pat[0])
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch != ".":
                px[cx - w // 2 + i + dx, by - h + 1 + j] = HAT_COL[ch]


def dress(im, fr, o):
    px = im.load()
    ox, oy = fr.ox, fr.oy
    for (x, y), r in fr.role.items():
        c = px[ox + x, oy + y]
        l = light(c)
        n = None
        if (x, y) in fr.tie and "scarf" in o:  # галстук становится концом шарфа: в полёте развевается
            n = hx(o["scarf"][(x // 2) % 2]) if l > 0.25 else hx("16285f")
        elif (x, y) in fr.tie and "tie" in o:
            n = ramp(o["tie"], l, 0.2, 0.6)
        elif r == "shirt" and (x, y) in fr.shirt:
            if "shirt" in o:
                n = ramp(o["shirt"], l, 0.35, 1.0)
            if "flowers" in o and l > 0.8 and (x * 3 + y * 5) % 9 == 0:
                n = hx(o["flowers"][(x + y) % 2])
            if "stripes" in o and (y + fr.i) % 3 == 0:
                n = ramp(["16285f", "1f3a8a"], l, 0.5, 1.0)
        elif r == "pants":
            if "pants" in o:
                n = ramp(o["pants"], l, 0.1, 0.5)
            if o.get("pants_check"):
                n = hx("2a2433") if ((x // 2) + (y // 2)) % 2 else hx("e8e4ea")
        if o.get("collar") and r == "shirt" and fr.tie and (x, y) in fr.shirt:
            # белая рубашка в вырезе пиджака: клин над галстуком
            kx, ky = fr.knot
            if 0 <= y - ky + 2 <= 3 and abs(x - kx) <= 3 - (y - ky + 2) // 2 and (x, y) not in fr.tie:
                n = ramp(["b6b3c8", "e2dfde", "faf9f8"], l, 0.5, 1.0)
        if n:
            px[ox + x, oy + y] = n[:3] + (c[3],)
    cx, top = fr.crown
    if "hat" in o:
        pat, sink, dx = HATS[o["hat"]]
        bob = fr.i % 2 if o["hat"] == "chef" and fr.name in ("walk", "fly") else 0  # колпак подпрыгивает
        stamp(px, pat, ox + cx, oy + top + sink - bob, dx)
    if "scarf" in o:
        kx, ky = fr.knot
        cols = [hx(c) for c in o["scarf"]]
        for x in range(kx - 5, kx + 4):
            for y in (ky - 1, ky):
                if px[ox + x, oy + y][3] and fr.role.get((x, y)) != "hair":
                    px[ox + x, oy + y] = cols[(x // 2) % 2]

def main():
    src = Image.open(os.path.join(ART, "gennady_sheet.png")).convert("RGBA")
    frames = []
    for r, (n, k) in enumerate(ANIMS):
        for i in range(k):
            frames.append(Frame(src, i * F, r * F, n, i))
    previews = []
    for oid, o in OUTFITS.items():
        im = src.copy()
        for fr in frames:
            dress(im, fr, o)
        im.save(os.path.join(ART, "outfit_%s_sheet.png" % oid))
        previews.append(im)
    bg = Image.new("RGBA", (src.width * len(previews), src.height), (58, 60, 90, 255))
    for k, im in enumerate(previews):
        bg.alpha_composite(im, (k * src.width, 0))
    bg.resize((bg.width * 2, bg.height * 2), Image.NEAREST).save(os.path.join(HERE, "..", "outfits_preview.png"))
    print("нарядов:", len(previews))


if __name__ == "__main__":
    main()
