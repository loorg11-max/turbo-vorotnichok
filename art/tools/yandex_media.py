"""Картинки для страницы игры в Яндекс Играх (и VK Play) из тех же артов, что и для Steam.

Пишет в art/yandex/:
    icon_512.png      значок 512×512: Геннадий в полёте из вертикального арта 28
    cover_800x470.png обложка 800×470: широкий арт 27 и логотип 18
    showcase_1560x520.png обложка на витрину Яндекса (по желанию)
    cover_1920x1080.png большая обложка 16:9 для VK Play и витрин
Скриншоты 1920×1080 берутся готовые из art/steam/screenshots/.

    python3 art/tools/yandex_media.py      # из корня общей папки
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from steam_capsules import ROOT, cover, key_out_magenta, place  # noqa: E402

# имя: (ширина, высота, доля ширины под логотип, точка кадра)
COVERS = {
    "cover_800x470": (800, 470, 0.50, (0.6, 0.3)),
    "showcase_1560x520": (1560, 520, 0.42, (0.6, 0.25)),
    "cover_1920x1080": (1920, 1080, 0.46, (0.6, 0.3)),
}

# квадрат в арте 28 (1024×1536) вокруг Геннадия и газового столба
ICON_BOX = (232, 250, 792, 810)


def main():
    raw = os.path.join(ROOT, "art", "gpt", "raw")
    out = os.path.join(ROOT, "art", "yandex")
    os.makedirs(out, exist_ok=True)
    wide = Image.open(os.path.join(raw, "27_key_wide.png")).convert("RGBA")
    logo = key_out_magenta(Image.open(os.path.join(raw, "18_logo.png")))
    for name, (w, h, share, focus) in COVERS.items():
        c = cover(wide, w, h, focus)
        place(c, logo, share, (0.04, 0.5))
        c.convert("RGB").save(os.path.join(out, name + ".png"), optimize=True)
    tall = Image.open(os.path.join(raw, "28_key_tall.png")).convert("RGB")
    tall.crop(ICON_BOX).resize((512, 512), Image.LANCZOS).save(os.path.join(out, "icon_512.png"), optimize=True)
    print("Готово:", out)


if __name__ == "__main__":
    main()
