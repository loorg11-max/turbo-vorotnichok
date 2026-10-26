"""Картинки для страницы и библиотеки Steam из двух артов GPT и логотипа.

Берёт из art/gpt/raw/:
    27_key_wide.png   широкий арт без надписей (промпт 27, место под логотип слева)
    28_key_tall.png   вертикальный арт без надписей (промпт 28, место под логотип сверху)
    18_logo.png       логотип на розовом фоне (промпт 18)
и пишет в art/steam/capsules/ все размеры, которые просит Steam:
    header 920×430, small 462×174, main 1232×706, vertical 748×896,
    library_capsule 600×900, library_hero 3840×1240 (без логотипа), library_logo 1280×720 (прозрачный),
    community_icon 184×184 (из значка exe).

    python3 art/tools/steam_capsules.py                  # из корня общей папки
    python3 art/tools/steam_capsules.py --in DIR --out DIR   # свои папки (для проверки)
"""
import argparse
import os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUTLINE = (9, 12, 28)

# имя: (ширина, высота, какой арт, доля ширины под логотип, где логотип: (x, y) в долях, 0 = без логотипа)
SIZES = {
    "header": (920, 430, "wide", 0.50, (0.04, 0.5)),
    "small": (462, 174, "wide", 0.62, (0.04, 0.5)),
    "main": (1232, 706, "wide", 0.46, (0.04, 0.5)),
    "vertical": (748, 896, "tall", 0.86, (0.5, 0.04)),
    "library_capsule": (600, 900, "tall", 0.86, (0.5, 0.04)),
    "library_hero": (3840, 1240, "wide", 0, None),
}


def key_out_magenta(img):
    """Розовый фон в прозрачность, розовую кайму у краёв букв в тёмную обводку."""
    img = img.convert("RGBA")
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if r > 180 and b > 180 and g < 110:
                px[x, y] = (0, 0, 0, 0)
            elif r > 150 and b > 150 and g < 150 and abs(r - b) < 70:
                px[x, y] = OUTLINE + (255,)
    return img.crop(img.getbbox())


def cover(img, w, h, focus=(0.6, 0.5)):
    """Обрезать под пропорции w:h вокруг точки focus и уменьшить."""
    k = max(w / img.width, h / img.height)
    big = img.resize((max(w, round(img.width * k)), max(h, round(img.height * k))), Image.LANCZOS)
    x = min(max(0, round(big.width * focus[0] - w / 2)), big.width - w)
    y = min(max(0, round(big.height * focus[1] - h / 2)), big.height - h)
    return big.crop((x, y, x + w, y + h))


def fit(logo, w, h):
    k = min(w / logo.width, h / logo.height)
    return logo.resize((max(1, round(logo.width * k)), max(1, round(logo.height * k))), Image.LANCZOS)


def place(canvas, logo, share, at):
    lw = round(canvas.width * share)
    lg = fit(logo, lw, round(canvas.height * (0.8 if at[1] == 0.5 else 0.4)))
    x = round(canvas.width * at[0]) if at[0] < 0.5 else round((canvas.width - lg.width) / 2)
    y = round((canvas.height - lg.height) / 2) if at[1] == 0.5 else round(canvas.height * at[1])
    canvas.alpha_composite(lg, (x, y))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="src", default=os.path.join(ROOT, "art", "gpt", "raw"))
    ap.add_argument("--out", default=os.path.join(ROOT, "art", "steam", "capsules"))
    a = ap.parse_args()
    need = {"wide": "27_key_wide.png", "tall": "28_key_tall.png", "logo": "18_logo.png"}
    missing = [f for f in need.values() if not os.path.exists(os.path.join(a.src, f))]
    if missing:
        print("Нет картинок:", ", ".join(missing))
        return
    art = {k: Image.open(os.path.join(a.src, f)).convert("RGBA") for k, f in need.items()}
    logo = key_out_magenta(art.pop("logo"))
    os.makedirs(a.out, exist_ok=True)
    for name, (w, h, kind, share, at) in SIZES.items():
        # логотип слева, поэтому середина кадра чуть правее
        c = cover(art[kind], w, h, (0.6, 0.5) if kind == "wide" else (0.5, 0.6))
        if share:
            place(c, logo, share, at)
        c.convert("RGB").save(os.path.join(a.out, name + ".png"), optimize=True)
    lib = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    lg = fit(logo, 1200, 640)
    lib.alpha_composite(lg, ((1280 - lg.width) // 2, (720 - lg.height) // 2))
    lib.save(os.path.join(a.out, "library_logo.png"))
    icon = Image.open(os.path.join(ROOT, "godot", "turbo-vorotnichok", "art", "icon.png")).convert("RGBA")
    bg = Image.new("RGBA", icon.size, OUTLINE + (255,))
    bg.alpha_composite(icon)
    bg.convert("RGB").resize((184, 184), Image.LANCZOS).save(os.path.join(a.out, "community_icon.jpg"), quality=95)
    print("Готово:", a.out)


if __name__ == "__main__":
    main()
