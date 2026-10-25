#!/usr/bin/env python3
"""Прокачка Геннадия (талоны, версия 0.5): что дают ремень и рубашка-парашют на разных подносах.

Берёт продукты и физику из balance.py и прогоняет несколько подносов на уровнях 0–3:
высоту при игре булками (ремень) и время в воздухе и дальность вбок (рубашка).
Цифры BELT, TIE, SHIRT должны совпадать с UPGRADES в scripts/perks.gd.

    python3 upgrades.py
"""
import os
import sys, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import balance as B
items, recipes = B.load_data()
BELT = [1.0, 0.85, 0.72, 0.6]
TIE = [(1.9, 1.0), (2.4, 0.8), (2.9, 0.6), (3.4, 0.4)]
SHIRT = [0.0, 0.06, 0.12, 0.2]

def fly(tray, mode, belt=0, tie=0, shirt=0, seed=1):
    rng = random.Random(seed)
    a = B.AIM
    vx, vy = math.sin(a) * B.V0_PERFECT, math.cos(a) * B.V0_PERFECT
    ang, hx, hy, t, top = a, 0.0, 0.0, 0.0, 0.0
    stage, store, inst, pumping = 0, 0.0, 0.0, False
    delay, fuel = items[tray[0]]["d"], items[tray[0]]["v"]
    target = 0.785 if mode == "вбок" else 0.0
    turn, wob = TIE[tie]
    while True:
        t += B.DT
        it = items[tray[stage]] if stage < len(tray) else None
        ang += max(-turn * B.DT, min(turn * B.DT, target - ang))
        burning = it is not None and delay <= 0
        if mode == "булки":
            if pumping and (store >= B.STORE_MAX or inst > 0.8 or not burning or vy < 0):
                pumping = False
            elif not pumping and store <= 0 and burning and inst < 0.5 and vy > 8:
                pumping = True
        squeeze = mode == "булки" and pumping and burning
        thrust = boost = 0.0
        if it is not None:
            if delay > 0: delay -= B.DT
            else:
                if squeeze:
                    thrust = it["p"] * 0.15; fuel -= B.DT * 0.15
                    store = min(store + it["p"] * B.DT * B.STORE_FILL, B.STORE_MAX)
                    inst += B.DT * (0.2 + it["i"] * 0.5) * BELT[belt]
                else:
                    thrust = it["p"]; fuel -= B.DT
                    inst += B.DT * it["i"] * 0.1 * BELT[belt]
                if fuel <= 0:
                    stage += 1
                    if stage < len(tray): delay, fuel = items[tray[stage]]["d"], items[tray[stage]]["v"]
        if not squeeze and store > 0:
            boost = B.BOOST; store = max(0.0, store - B.DT * 30)
        if not squeeze: inst -= B.DT * 0.06
        inst = min(1.0, max(0.0, inst))
        if thrust > 0: ang += rng.uniform(-0.5, 0.5) * inst * B.DT * 4 * wob
        acc = thrust + boost
        sp = math.hypot(vx, vy)
        vx += (math.sin(ang) * acc - B.DRAG * vx * sp) * B.DT
        vy += (math.cos(ang) * acc - B.GRAVITY - B.DRAG * vy * sp) * B.DT
        if vy < 0: vy -= SHIRT[shirt] * vy * B.DT
        hx += vx * B.DT; hy += vy * B.DT
        top = max(top, hy)
        if hy <= 0 and t > 0.4: return top, hx, t

trays = [("lavash",), ("salad","salad"), ("shawarma","shawarma","shawarma"), ("glavash","fizz","fizz"), ("lunch","lunch","lunch")]
for tr in trays:
    print(" + ".join(tr))
    for lvl in range(4):
        b = fly(tr, "булки", belt=lvl); u = fly(tr,"вверх", belt=lvl)
        s = fly(tr, "булки", shirt=lvl); sd = fly(tr, "вбок", shirt=lvl)
        print(f"  ур{lvl}: ремень булки {b[0]:.0f} м | рубашка: булки {s[0]:.0f} м, {s[2]:.0f} с, вбок {sd[1]:.0f} м {sd[2]:.0f} с")
