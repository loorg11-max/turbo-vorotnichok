#!/usr/bin/env python3
"""Проверка баланса «Турбо белого воротничка».

Берёт продукты и рецепты прямо из scripts/data.gd, прогоняет каждый поднос (1–3 блюда,
порядок важен) через ту же физику полёта, что в scripts/main.gd, и пишет отчёт в Markdown
и полную таблицу в CSV.

Запуск:  python3 balance.py [путь к проекту] [папка для отчёта]
По умолчанию проект ../turbo-vorotnichok, отчёт рядом со скриптом.

Три способа лететь:
  вверх    идеальный старт, сразу выпрямиться и лететь строго вверх, булки не сжимать;
  булки    то же, но на подъёме «сжимать булки», пока копится газ, и отпускать для рывка;
           пузо до взрыва не доводить;
  вбок     идеальный старт и держать наклон 45°, булки не сжимать (на дальность).
Случайности (тряска от нестабильности) зафиксированы, поэтому прогоны повторяются.
"""
import csv
import itertools
import math
import random
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PROJECT = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE.parent / "turbo-vorotnichok"
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE

# константы из main.gd
GRAVITY, DRAG, DT = 9.8, 0.001, 1 / 60
V0_PERFECT, AIM = 20.0, 0.6
STORE_MAX, STORE_FILL, BOOST, TURN = 30.0, 0.8, 25.0, 1.9
MEDALS = [(1000, "золото"), (600, "серебро"), (250, "бронза")]


def load_data():
    src = (PROJECT / "scripts" / "data.gd").read_text(encoding="utf-8")
    items = {}
    for m in re.finditer(r'"(\w+)":\s*\{"name":\s*"([^"]+)",\s*"p":\s*([\d.]+),\s*"v":\s*([\d.]+),'
                         r'\s*"d":\s*([\d.]+),\s*"i":\s*(-?[\d.]+)(.*?)\}', src):
        h = re.search(r'"h":\s*(-?[\d.]+)', m[7])
        items[m[1]] = {"name": m[2], "p": float(m[3]), "v": float(m[4]), "d": float(m[5]),
                       "i": float(m[6]), "base": '"base": true' in m[7], "h": float(h[1]) if h else 0.0}
    block = src[src.index("const RECIPES"):src.index("}", src.index("const RECIPES"))]
    recipes = {m[3]: (m[1], m[2]) for m in re.finditer(r'"(\w+)\+(\w+)":\s*"(\w+)"', block)}
    return items, recipes


def depth(items, recipes):
    """Сколько шагов смешивания нужно до блюда: продукт 0, блюдо 1 + самый глубокий из двух."""
    d = {k: 0 for k, it in items.items() if it["base"]}
    grew = True
    while grew:
        grew = False
        for out, (a, b) in recipes.items():
            if out not in d and a in d and b in d:
                d[out] = 1 + max(d[a], d[b])
                grew = True
    lost = set(items) - set(d)
    if lost:
        sys.exit("Блюда, которые нельзя приготовить: " + ", ".join(sorted(lost)))
    return d


def fly(items, tray, mode, seed=1):
    rng = random.Random(seed)
    a = AIM
    vx, vy = math.sin(a) * V0_PERFECT, math.cos(a) * V0_PERFECT
    ang, hx, hy, t, top = a, 0.0, 0.0, 0.0, 0.0
    stage, store, inst, pumping = 0, 0.0, 0.0, False
    delay, fuel = items[tray[0]]["d"], items[tray[0]]["v"]
    target = 0.785 if mode == "вбок" else 0.0
    while True:
        t += DT
        it = items[tray[stage]] if stage < len(tray) else None
        ang += max(-TURN * DT, min(TURN * DT, target - ang))
        burning = it is not None and delay <= 0
        # булки: жмём, пока копится газ и пузо спокойно, потом отпускаем до конца рывка
        # жмём только на подъёме: у земли и при падении копить газ некогда
        if mode == "булки":
            if pumping and (store >= STORE_MAX or inst > 0.8 or not burning or vy < 0):
                pumping = False
            elif not pumping and store <= 0 and burning and inst < 0.5 and vy > 8:
                pumping = True
        squeeze = mode == "булки" and pumping and burning
        thrust = boost = 0.0
        if it is not None:
            if delay > 0:
                delay -= DT
            else:
                if squeeze:
                    thrust = it["p"] * 0.15
                    fuel -= DT * 0.15
                    store = min(store + it["p"] * DT * STORE_FILL, STORE_MAX)
                    inst += DT * (0.2 + it["i"] * 0.5)
                else:
                    thrust = it["p"]
                    fuel -= DT
                    inst += DT * it["i"] * 0.1
                if fuel <= 0:
                    stage += 1
                    if stage < len(tray):
                        delay, fuel = items[tray[stage]]["d"], items[tray[stage]]["v"]
        if not squeeze and store > 0:
            boost = BOOST
            store = max(0.0, store - DT * 30)
        if not squeeze:
            inst -= DT * 0.06
        inst = min(1.0, max(0.0, inst))
        if thrust > 0:
            ang += rng.uniform(-0.5, 0.5) * inst * DT * 4
        acc = thrust + boost
        sp = math.hypot(vx, vy)
        # h: блюдо толкает вбок (аджика из Чебуречной), пока горит; при сжатых булках слабее, как тяга
        side = it["h"] * thrust / it["p"] if thrust > 0 else 0.0
        vx += (math.sin(ang) * acc + side - DRAG * vx * sp) * DT
        vy += (math.cos(ang) * acc - GRAVITY - DRAG * vy * sp) * DT
        hx += vx * DT
        hy += vy * DT
        top = max(top, hy)
        if hy <= 0 and t > 0.4:
            return top, hx, t


def name(items, tray):
    return " + ".join(items[k]["name"] for k in tray)


def medal(h):
    return next((m for v, m in MEDALS if h >= v), "")


def main():
    items, recipes = load_data()
    dep = depth(items, recipes)
    keys = list(items)
    rows = []
    for n in (1, 2, 3):
        for tray in itertools.product(keys, repeat=n):
            up = fly(items, tray, "вверх")
            pump = fly(items, tray, "булки")
            side = fly(items, tray, "вбок")
            rows.append({"tray": tray, "n": n, "depth": max(dep[k] for k in tray), "up": up[0],
                         "pump": pump[0], "air": pump[2], "far": side[1], "far_air": side[2]})

    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / "balance.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["поднос", "блюд", "шагов смешивания", "вверх, м", "с булками, м", "в воздухе, с", "вбок, м"])
        for r in rows:
            w.writerow([name(items, r["tray"]), r["n"], r["depth"], round(r["up"]), round(r["pump"]),
                        round(r["air"], 1), round(r["far"])])

    best = max(rows, key=lambda r: r["pump"])
    L = []
    L.append("# Баланс: все подносы\n")
    L.append(f"Продуктов и блюд: {len(items)}, рецептов: {len(recipes)}, подносов проверено: {len(rows)} "
             "(от 1 до 3 блюд, порядок важен). Старт идеальный, на зелёной стрелке.\n")
    L.append("«Вверх»: строго вверх без булок. «С булками»: сжимать, пока копится газ, отпускать для рывка, "
             "пузо до взрыва не доводить. «Вбок»: держать наклон 45°, дальность.\n")

    L.append("## Каждое блюдо по одному\n")
    L.append("| Блюдо | Шагов | Вверх, м | С булками, м | Вбок, м | Три таких, с булками, м |")
    L.append("|---|---|---|---|---|---|")
    solo = {r["tray"][0]: r for r in rows if r["n"] == 1}
    triple = {r["tray"][0]: r for r in rows if r["n"] == 3 and len(set(r["tray"])) == 1}
    for k in sorted(keys, key=lambda k: -solo[k]["pump"]):
        r = solo[k]
        L.append(f"| {items[k]['name']} | {dep[k]} | {r['up']:.0f} | {r['pump']:.0f} | {r['far']:.0f} | {triple[k]['pump']:.0f} |")

    L.append("\n## Лучшие 15 подносов по высоте с булками\n")
    L.append("| # | Поднос | С булками, м | Вверх, м | В воздухе, с | Вбок, м |")
    L.append("|---|---|---|---|---|---|")
    top = sorted(rows, key=lambda r: -r["pump"])
    for i, r in enumerate(top[:15], 1):
        L.append(f"| {i} | {name(items, r['tray'])} | {r['pump']:.0f} | {r['up']:.0f} | {r['air']:.1f} | {r['far']:.0f} |")

    L.append("\n## Лучшие 10 подносов на дальность\n")
    L.append("| # | Поднос | Вбок, м | В воздухе, с |")
    L.append("|---|---|---|---|")
    for i, r in enumerate(sorted(rows, key=lambda r: -r["far"])[:10], 1):
        L.append(f"| {i} | {name(items, r['tray'])} | {r['far']:.0f} | {r['far_air']:.1f} |")

    L.append("\n## Лучший поднос с каждым блюдом\n")
    L.append("Насколько блюдо полезно на вершине игры: лучший поднос, где оно есть, и доля от рекорда.\n")
    L.append("| Блюдо | Лучший поднос с ним | С булками, м | От рекорда |")
    L.append("|---|---|---|---|")
    for k in sorted(keys, key=lambda k: -max(r["pump"] for r in rows if k in r["tray"])):
        r = max((r for r in rows if k in r["tray"]), key=lambda r: r["pump"])
        L.append(f"| {items[k]['name']} | {name(items, r['tray'])} | {r['pump']:.0f} | {r['pump'] / best['pump']:.0%} |")

    L.append("\n## Цели и самый короткий путь к ним\n")
    L.append("Для каждой цели: поднос, которому нужно меньше всего шагов смешивания (при равенстве самый высокий).\n")
    L.append("| Цель | Подносов достаёт | Самый короткий путь | Шагов | Результат |")
    L.append("|---|---|---|---|---|")
    for v, m in reversed(MEDALS):
        ok = [r for r in rows if r["pump"] >= v]
        if not ok:
            L.append(f"| {m.capitalize()}, {v} м | 0 | недостижимо | | |")
            continue
        r = min(ok, key=lambda r: (r["depth"], r["n"], -r["pump"]))
        L.append(f"| {m.capitalize()}, {v} м | {len(ok)} | {name(items, r['tray'])} | {r['depth']} | {r['pump']:.0f} м |")
    for v, label in [(1000, "Дальнобойщик, 1000 м вбок"), (2500, "В соседний район, 2500 м вбок")]:
        ok = [r for r in rows if r["far"] >= v]
        r = min(ok, key=lambda r: (r["depth"], r["n"], -r["far"])) if ok else None
        L.append(f"| {label} | {len(ok)} | {name(items, r['tray']) if r else 'недостижимо'} | {r['depth'] if r else ''} | "
                 f"{'%.0f вбок' % r['far'] if r else ''} |")
    ok = [r for r in rows if r["air"] >= 45]
    r = min(ok, key=lambda r: (r["depth"], r["n"], -r["air"])) if ok else None
    L.append(f"| Долгий обед, 45 с в воздухе | {len(ok)} | {name(items, r['tray']) if r else 'недостижимо'} | "
             f"{r['depth'] if r else ''} | {'%.0f с' % r['air'] if r else ''} |")

    L.append("\n## Что настораживает\n")
    warn = []
    lead = top[0]["pump"] / top[1]["pump"] if top[1]["pump"] else 0
    if lead > 1.1:
        warn.append(f"Рекордный поднос «{name(items, top[0]['tray'])}» обгоняет второй больше чем на 10% ({lead - 1:.0%}).")
    used = {k for r in top[:20] for k in r["tray"]}
    warn.append(f"В двадцати лучших подносах встречается {len(used)} разных блюд из {len(keys)}: "
                + ", ".join(items[k]["name"] for k in keys if k in used) + ".")
    useless = [k for k in keys if not items[k]["base"] and max(r["pump"] for r in rows if k in r["tray"]) < 0.5 * best["pump"]]
    if useless:
        warn.append("Блюда, с которыми нельзя набрать и половины рекорда: " + ", ".join(items[k]["name"] for k in useless) + ".")
    for k in keys:
        if items[k]["base"]:
            continue
        a, b = recipes_for(recipes, k)
        if solo[k]["up"] < max(solo[a]["up"], solo[b]["up"]):
            warn.append(f"«{items[k]['name']}» в одиночку летит ниже, чем «{items[a if solo[a]['up'] >= solo[b]['up'] else b]['name']}», из которого его делают.")
    gain = sum(r["pump"] > r["up"] * 1.02 for r in rows)
    warn.append(f"Сжимать булки по простой схеме выгодно в {gain} подносах из {len(rows)} ({gain / len(rows):.0%}): "
                "в остальных булки работают как тормоз.")
    L.extend("- " + w for w in warn)
    L.append("\nПолная таблица: balance.csv рядом с этим отчётом.")
    (OUT / "balance.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print("\n".join(L))


def recipes_for(recipes, k):
    return next(v for out, v in recipes.items() if out == k)


if __name__ == "__main__":
    main()
