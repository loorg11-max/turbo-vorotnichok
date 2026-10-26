"""Архив игры для Яндекс Игр из веб-сборки Godot.

Берёт папку экспорта Web (index.html, index.js, index.wasm, index.pck, ...), подключает
SDK Яндекса (/sdk.js) и web/yandex_glue.js, ждёт SDK до запуска движка, добавляет надпись
«поверните телефон» для вертикального экрана и пакует всё в zip, который грузят в консоль Яндекса.

    python3 yandex_pack.py ПАПКА_WEB АРХИВ.zip
"""
import os
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
GLUE = os.path.join(HERE, "..", "turbo-vorotnichok", "web", "yandex_glue.js")
FILES = ["index.html", "index.js", "index.wasm", "index.pck", "index.audio.worklet.js",
         "index.png", "index.icon.png", "index.apple-touch-icon.png"]

HEAD = """<script src="/sdk.js"></script>
<script src="yandex_glue.js"></script>
<style>
body { user-select: none; -webkit-user-select: none; -webkit-touch-callout: none; }
#turbo-rotate { display: none; position: fixed; inset: 0; z-index: 10; background: #0a1a3b; color: #ede6bc;
	font: 20px sans-serif; align-items: center; justify-content: center; text-align: center; padding: 24px; }
@media (orientation: portrait) and (pointer: coarse) { #turbo-rotate { display: flex; } }
</style>
"""
BODY = '<div id="turbo-rotate">Поверните телефон горизонтально</div>\n'


def patch_html(s):
    s = s.replace('<html lang="en">', '<html lang="ru">')
    s = s.replace("</head>", HEAD + "</head>", 1)
    s = s.replace('<canvas id="canvas">', BODY + '<canvas id="canvas">', 1)
    # движок стартует после SDK Яндекса: облачное сохранение должно лечь в файл до загрузки игры
    for a, b in [("engine.startGame({", "TurboYa.boot().then(() => engine.startGame({"),
                 ("}, displayFailureNotice);", "}, displayFailureNotice));")]:
        if s.count(a) != 1:
            sys.exit("index.html не похож на шаблон Godot 4.3: не найдено " + a)
        s = s.replace(a, b)
    return s


def patch_js(s):
    # обращение к navigator.serviceWorker в чужом iframe может кинуть ошибку: спрашиваем осторожно
    safe = "(function(){try{return!!navigator.serviceWorker}catch(e){return false}})()"
    return s.replace('"serviceWorker"in navigator', safe)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
        for f in FILES:
            p = os.path.join(src, f)
            if not os.path.exists(p):
                continue
            if f == "index.html":
                z.writestr(f, patch_html(open(p, encoding="utf-8").read()))
            elif f == "index.js":
                z.writestr(f, patch_js(open(p, encoding="utf-8").read()))
            else:
                z.write(p, f)
        z.write(GLUE, "yandex_glue.js")
    print("готово:", dst, os.path.getsize(dst) // 1024, "КБ")


if __name__ == "__main__":
    main()
