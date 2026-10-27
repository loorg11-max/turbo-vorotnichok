#!/usr/bin/env python3
"""Все звуки и музыка игры, сделанные кодом: ретро-синтез в духе 16-битных приставок.

Чужих записей нет, поэтому и лицензий нет: звуки наши. Каждый звук описан функцией
ниже, случайность с фиксированным зерном, так что повторный запуск даёт те же файлы.

  python3 make_sounds.py ../../godot/turbo-vorotnichok/sounds

Короткие звуки пишутся в WAV (без задержки при проигрывании), музыка в OGG через ffmpeg.
Петли (gas, squeeze, wind и музыка) склеены так, что конец переходит в начало без щелчка;
зацикливание включает сама игра (scripts/sound.gd).
"""
import os
import subprocess
import sys
import wave

import numpy as np

SR = 22050  # звуки
MSR = 32000  # музыка: тарелочкам нужны верха


# ---------------- основа синтеза ----------------

def n_of(d, sr=SR):
    return int(round(d * sr))


def tt(d, sr=SR):
    return np.arange(n_of(d, sr)) / sr


def sweep(a, b, n, curve="exp"):
    """Плавный переход частоты от a до b за n отсчётов."""
    k = np.linspace(0.0, 1.0, n)
    if curve == "exp":
        return a * (b / a) ** k
    return a + (b - a) * k


def phase(freq, sr=SR):
    return np.cumsum(np.asarray(freq, dtype=np.float64) / sr)


def _blep(t, dt):
    r = np.zeros_like(t)
    m = t < dt
    x = t[m] / dt[m]
    r[m] = x + x - x * x - 1.0
    m = t > 1.0 - dt
    x = (t[m] - 1.0) / dt[m]
    r[m] = x * x + x + x + 1.0
    return r


def square(freq, duty=0.5, sr=SR):
    """Прямоугольник без звона наложенных частот (PolyBLEP)."""
    freq = np.asarray(freq, dtype=np.float64)
    ph = phase(freq, sr) % 1.0
    dt = np.clip(freq / sr, 1e-6, 0.5)
    out = np.where(ph < duty, 1.0, -1.0)
    return out + _blep(ph, dt) - _blep((ph - duty) % 1.0, dt)


def tri(freq, sr=SR):
    ph = phase(freq, sr) % 1.0
    return 4.0 * np.abs(ph - 0.5) - 1.0


def sine(freq, sr=SR):
    return np.sin(2 * np.pi * phase(freq, sr))


def noise(n, rng):
    return rng.uniform(-1.0, 1.0, n)


def smooth_noise(n, rate, rng, sr=SR):
    """Медленно плывущее значение около нуля: для дрожания высоты."""
    pts = rng.uniform(-1.0, 1.0, int(n * rate / sr) + 3)
    x = np.linspace(0, len(pts) - 2, n)
    i = x.astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    return pts[i] * (1 - f) + pts[i + 1] * f


def lowpass(x, cutoff, sr=SR, poles=2):
    """Однополюсный фильтр (можно с меняющейся частотой среза), poles раз подряд."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=np.float64), x.shape)
    a = 1.0 - np.exp(-2 * np.pi * cutoff / sr)
    y = np.asarray(x, dtype=np.float64)
    for _ in range(poles):
        out = np.empty_like(y)
        s = 0.0
        for i in range(len(y)):
            s += a[i] * (y[i] - s)
            out[i] = s
        y = out
    return y


def highpass(x, cutoff, sr=SR):
    return x - lowpass(x, cutoff, sr, poles=1)


def bandpass(x, f0, q, sr=SR):
    """Резонансный полосовой фильтр (RBJ), частота постоянная."""
    w = 2 * np.pi * f0 / sr
    al = np.sin(w) / (2 * q)
    b0, b2 = al, -al
    a0, a1, a2 = 1 + al, -2 * np.cos(w), 1 - al
    b0, b2, a1, a2 = b0 / a0, b2 / a0, a1 / a0, a2 / a0
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i in range(len(x)):
        v = b0 * x[i] + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x[i], y1, v
        y[i] = v
    return y


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, sr=SR):
    """Огибающая: подъём a, спад d до уровня s, в конце затухание r (секунды)."""
    e = np.full(n, s, dtype=np.float64)
    na, nd, nr = n_of(a, sr), n_of(d, sr), n_of(r, sr)
    na = max(1, min(na, n))
    e[:na] = np.linspace(0, 1, na)
    nd = min(nd, n - na)
    if nd > 0:
        e[na:na + nd] = 1 + (s - 1) * np.linspace(0, 1, nd)
    if nr > 0:
        nr = min(nr, n)
        e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def decay(n, tau, sr=SR):
    return np.exp(-np.arange(n) / (tau * sr))


def place(buf, x, at, sr=SR):
    i = n_of(at, sr)
    j = min(len(buf), i + len(x))
    buf[i:j] += x[: j - i]


def loopable(x, fade, sr=SR):
    """Петля без щелчка: хвост длиной fade плавно вмешивается в начало."""
    nf = n_of(fade, sr)
    body = x[:-nf].copy()
    tail = x[-nf:]
    k = np.linspace(0, 1, nf)
    body[:nf] = body[:nf] * k + tail * (1 - k)
    return body


def norm(x, peak=0.8):
    m = np.max(np.abs(x))
    return x * (peak / m) if m > 0 else x


def note(n):
    """Частота: n полутонов от ля первой октавы (440 Гц)."""
    return 440.0 * 2 ** (n / 12.0)


# ---------------- пук: главный инструмент игры ----------------

def fart(dur, f0, f1, rng, flutter=0.18, breath=0.35, bright=900.0, sr=SR):
    """Губной «бррр»: узкий импульс на низкой частоте с дрожанием, через мягкий фильтр, плюс выдох."""
    n = n_of(dur, sr)
    base = sweep(f0, f1, n)
    wob = 1.0 + flutter * smooth_noise(n, 18, rng, sr) + 0.06 * smooth_noise(n, 60, rng, sr)
    freq = base * wob
    buzz = square(freq, duty=0.18, sr=sr)
    ph = phase(freq, sr) % 1.0
    puff = noise(n, rng) * (ph < 0.35)  # воздух вырывается толчками в такт губам
    x = lowpass(buzz, bright, sr) + breath * lowpass(puff, bright * 1.8, sr)
    x = x + 0.5 * bandpass(x, bright * 0.45, 2.5, sr)  # «мокрая» гласная
    return highpass(x, 40, sr)


# ---------------- звуки ----------------

def s_click(rng):
    n = n_of(0.05)
    x = square(sweep(1400, 950, n), 0.25) * decay(n, 0.012)
    return norm(lowpass(x, 5000), 0.35)


def s_plop(rng):
    n = n_of(0.14)
    x = sine(sweep(720, 170, n)) * env(n, 0.002, 0.13, 0, 0.01)
    x[: n_of(0.004)] += noise(n_of(0.004), rng) * 0.4
    return norm(x, 0.6)


def s_tray(rng):
    buf = np.zeros(n_of(0.25))
    for at, v in ((0.0, 1.0), (0.07, 0.45)):
        n = n_of(0.16)
        x = (sine(np.full(n, 2240)) + 0.6 * sine(np.full(n, 3370)) + 0.3 * sine(np.full(n, 5150))) * decay(n, 0.045)
        place(buf, x * v, at)
    return norm(buf, 0.45)


def _arp(notes, step, tail, duty=0.25, peak=0.55, sr=SR):
    buf = np.zeros(n_of(step * len(notes) + tail, sr))
    for k, nn in enumerate(notes):
        last = k == len(notes) - 1
        d = (tail if last else step) + 0.03
        n = n_of(d, sr)
        f = np.full(n, note(nn))
        if last:
            f = f * (1 + 0.006 * np.sin(2 * np.pi * 6 * tt(d, sr)))
        x = square(f, duty, sr) * env(n, 0.003, 0.08, 0.5 if last else 0.35, 0.05 if last else 0.02, sr)
        x += 0.4 * tri(f / 2, sr) * env(n, 0.003, 0.1, 0.3, 0.03, sr)
        place(buf, x, k * step, sr)
    return norm(lowpass(buf, 6000), peak)


def s_new_dish(rng):
    return _arp([3, 7, 10, 15, 19], 0.06, 0.28)


def s_known_dish(rng):
    return _arp([10, 15], 0.07, 0.14, peak=0.4)


def s_mush(rng):
    d = 0.7
    n = n_of(d)
    t = tt(d)
    f = sweep(230, 80, n) + 35 * np.sin(2 * np.pi * 7 * t)
    x = sine(f) * 0.8 + 0.3 * square(f, 0.3)
    x = lowpass(x, 700) * env(n, 0.01, 0.6, 0.2, 0.15)
    buf = x.copy()
    for at in (0.12, 0.3, 0.47):
        m = n_of(0.05)
        place(buf, sine(sweep(260, 640, m)) * env(m, 0.003, 0.04, 0, 0.005) * 0.5, at + rng.uniform(-0.02, 0.02))
    return norm(buf, 0.6)


def s_chomp(rng):
    n = n_of(0.12)
    x = lowpass(noise(n, rng), 2500) * decay(n, 0.03) * 1.5
    x += 0.5 * sine(sweep(160, 70, n)) * decay(n, 0.04)
    return norm(x, 0.5)


def s_step(rng):
    n = n_of(0.07)
    x = lowpass(noise(n, rng), 500) * decay(n, 0.018) + 0.5 * sine(sweep(110, 60, n)) * decay(n, 0.02)
    return norm(x, 0.28)


def s_launch(rng):
    d = 1.05
    n = n_of(d)
    x = fart(d, 78, 58, rng, flutter=0.22, breath=0.5, bright=1300) * env(n, 0.012, 0.25, 0.75, 0.35)
    w = bandpass(noise(n, rng), 900, 0.8) * np.linspace(0, 1, n) ** 2 * env(n, 0.3, 0.1, 1.0, 0.25)
    return norm(x + 0.5 * w, 0.85)


def s_gas(rng):
    d = 1.6
    x = fart(d + 0.3, 92, 92, rng, flutter=0.16, breath=0.45, bright=1300)
    return norm(loopable(x, 0.3), 0.7)


def s_squeeze(rng):
    d = 1.0
    n = n_of(d + 0.25)
    t = tt(d + 0.25)
    f = 760 * (1 + 0.05 * np.sin(2 * np.pi * 9 * t) + 0.04 * smooth_noise(n, 6, rng))
    x = square(f, 0.12) * 0.5 + sine(f) * 0.6
    x = lowpass(x, 2200) + 0.15 * bandpass(noise(n, rng), 1500, 1.5)
    return norm(loopable(x, 0.25), 0.35)


def s_boost(rng):
    d = 0.6
    n = n_of(d)
    x = fart(d, 105, 175, rng, flutter=0.25, breath=0.8, bright=1300) * env(n, 0.004, 0.2, 0.6, 0.18)
    burst = bandpass(noise(n, rng), 1400, 0.9) * decay(n, 0.12)
    return norm(x + 0.6 * burst, 0.8)


def s_boom(rng):
    d = 1.3
    n = n_of(d)
    x = lowpass(noise(n, rng), sweep(4200, 140, n), poles=2) * decay(n, 0.35) * 1.6
    x += sine(sweep(85, 28, n)) * decay(n, 0.25) * 1.2
    crack = (rng.random(n) < 0.004) * rng.uniform(-1, 1, n) * decay(n, 0.3)
    x += lowpass(crack, 3000, poles=1) * 3
    return norm(x * env(n, 0.002, 0.0, 1.0, 0.3), 0.9)


def s_record(rng):
    buf = np.zeros(n_of(1.0))
    for k, nn in enumerate([-2, 3, 7]):
        m = n_of(0.11)
        place(buf, square(np.full(m, note(nn)), 0.25) * env(m, 0.003, 0.05, 0.6, 0.02), k * 0.09)
    m = n_of(0.7)
    f = np.full(m, note(10)) * (1 + 0.007 * np.sin(2 * np.pi * 6 * tt(0.7)))
    chord = square(f, 0.25) + 0.7 * square(f * 2 ** (-5 / 12), 0.5) * 0.6 + 0.6 * tri(f / 2)
    place(buf, chord * env(m, 0.004, 0.2, 0.5, 0.3), 0.27)
    place(buf, highpass(noise(n_of(0.5), rng), 3000) * decay(n_of(0.5), 0.12) * 0.5, 0.27)
    return norm(lowpass(buf, 7000), 0.7)


def s_clouds(rng):
    scale = [0, 4, 7, 9, 12, 16, 19, 21, 24, 28, 31, 33]
    buf = np.zeros(n_of(1.4))
    for k, nn in enumerate(scale):
        m = n_of(0.6)
        f = np.full(m, note(nn - 5))
        x = (sine(f) + 0.4 * tri(f * 2)) * decay(m, 0.18)
        place(buf, x, k * 0.05)
    return norm(buf, 0.6)


def s_space(rng):
    # космос: терменвокс плывёт вверх с вибрато, сверху мерцают звёздочки
    buf = np.zeros(n_of(2.2))
    m = n_of(1.9)
    t = tt(1.9)
    glide = note(-5) * 2 ** ((np.minimum(t, 0.7) / 0.7) * 12 / 12)
    f = glide * (1 + 0.025 * np.sin(2 * np.pi * 5.5 * t))
    voice = sine(f) + 0.25 * sine(f * 2) + 0.1 * tri(f)
    place(buf, voice * env(m, 0.15, 0.4, 0.7, 0.8), 0.0)
    for k, nn in enumerate([24, 31, 28, 36, 33, 40]):
        n = n_of(0.35)
        place(buf, sine(np.full(n, note(nn))) * decay(n, 0.08) * 0.35, 0.35 + k * 0.17)
    return norm(lowpass(buf, 6000), 0.6)


def s_land(rng):
    buf = np.zeros(n_of(0.45))
    for at, v in ((0.0, 1.0), (0.16, 0.35)):
        m = n_of(0.22)
        x = sine(sweep(120, 42, m)) * decay(m, 0.07) + 1.3 * lowpass(noise(m, rng), 1400) * decay(m, 0.035)
        place(buf, x * v, at)
    return norm(buf, 0.85)


def s_award(rng):
    buf = np.zeros(n_of(0.9))
    for at, nn in ((0.0, 19), (0.12, 26)):
        m = n_of(0.7)
        f = np.full(m, note(nn))
        x = (sine(f) + 0.35 * sine(f * 2.76) * decay(m, 0.05) + 0.2 * sine(f * 5.4) * decay(m, 0.02)) * decay(m, 0.22)
        place(buf, x, at)
    return norm(buf, 0.5)


def s_medal(rng):
    return _arp([0, 4, 7, 12, 16], 0.08, 0.4, duty=0.5, peak=0.55)


def s_gurgle(rng):
    buf = np.zeros(n_of(0.55))
    for k in range(5):
        m = n_of(rng.uniform(0.04, 0.08))
        a, b = rng.uniform(150, 260), rng.uniform(380, 560)
        place(buf, sine(sweep(a, b, m)) * env(m, 0.003, 0.05, 0, 0.005), k * 0.09 + rng.uniform(0, 0.03))
    return norm(lowpass(buf, 1200), 0.5)


def s_wind(rng):
    d = 2.5
    n = n_of(d + 0.5)
    x = bandpass(noise(n, rng), 700, 0.7) * (0.7 + 0.3 * smooth_noise(n, 1.5, rng))
    return norm(loopable(x, 0.5), 0.5)


SOUNDS = {
    "click": s_click, "plop": s_plop, "tray": s_tray, "new_dish": s_new_dish,
    "known_dish": s_known_dish, "mush": s_mush, "chomp": s_chomp, "step": s_step,
    "launch": s_launch, "gas": s_gas, "squeeze": s_squeeze, "boost": s_boost,
    "boom": s_boom, "record": s_record, "clouds": s_clouds, "land": s_land,
    "award": s_award, "medal": s_medal, "gurgle": s_gurgle, "wind": s_wind, "space": s_space,
}


# ---------------- музыка ----------------
# Ноты в полутонах от ля первой октавы; «-» тянет прошлую ноту, «.» пауза; 8 восьмых в такте.
# Лад: ля фригийский доминантовый (ля, си-бемоль, до-диез, ре, ми, фа, соль): восточный базар.

KIOSK = {
    "bpm": 112,
    "lead": ["7 8 7 5 4 - 5 .", "4 5 4 1 0 - - .", "0 1 4 5 7 - 8 7", "5 4 5 7 4 - - .",
             "12 10 8 7 8 - 7 .", "5 7 8 7 5 4 1 .", "0 1 4 5 7 8 10 8", "7 5 4 1 0 - - ."],
    "roots": [0, 1, 0, 5, 5, 1, 0, 0],
}
FLIGHT = {
    "bpm": 150,
    "lead": ["12 . 12 13 16 - 13 12", "13 . 13 16 17 - 16 13", "12 . 12 13 16 - 19 17", "16 13 12 10 12 - - .",
             "19 . 19 20 19 17 16 .", "17 . 17 19 17 16 13 .", "12 13 16 17 19 20 22 20", "19 17 16 13 12 - - ."],
    "roots": [0, 1, 0, 0, 0, 5, 0, 0],
}
CHORD = {0: [0, 4, 7], 1: [1, 5, 8], 5: [5, 8, 12]}


def parse(bars):
    """Строки тактов → список (нота, начало в восьмых, длина в восьмых)."""
    out = []
    pos = 0
    for bar in bars:
        for tok in bar.split():
            if tok == "-" and out:
                out[-1][2] += 1
            elif tok not in ("-", "."):
                out.append([int(tok), pos, 1])
            pos += 1
    return out


def lead_voice(nn, dur, duty, vol, sr=MSR):
    n = n_of(dur, sr)
    t = tt(dur, sr)
    vib = 1 + 0.012 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.12) * 6, 0, 1)
    f = note(nn) * vib
    return square(f, duty, sr) * env(n, 0.004, 0.07, 0.55, 0.04, sr) * vol


def kick(sr=MSR):
    n = n_of(0.18, sr)
    return sine(sweep(130, 42, n), sr) * decay(n, 0.06, sr)


def snare(rng, sr=MSR):
    n = n_of(0.14, sr)
    return highpass(noise(n, rng), 1200, sr) * decay(n, 0.04, sr) + 0.4 * sine(np.full(n, 190.0), sr) * decay(n, 0.03, sr)


def hat(rng, sr=MSR):
    n = n_of(0.05, sr)
    return highpass(noise(n, rng), 6000, sr) * decay(n, 0.012, sr)


def dum(sr=MSR):
    n = n_of(0.25, sr)
    return sine(sweep(95, 68, n), sr) * decay(n, 0.09, sr)


def tek(rng, sr=MSR):
    n = n_of(0.06, sr)
    return bandpass(noise(n, rng), 3200, 1.2, sr) * decay(n, 0.015, sr) * 2 + 0.3 * sine(np.full(n, 420.0), sr) * decay(n, 0.01, sr)


def render(song, style, rng, sr=MSR):
    e8 = 60.0 / song["bpm"] / 2
    bars = len(song["lead"])
    length = e8 * 8 * bars
    buf = np.zeros(n_of(length + 2.0, sr))
    for nn, st, ln in parse(song["lead"]):
        place(buf, lead_voice(nn, e8 * ln, 0.25, 0.32), st * e8, sr)
    for b, r in enumerate(song["roots"]):
        t0 = b * 8 * e8
        ch = CHORD[r]
        if style == "kiosk":
            for q, off in enumerate([0, 7, 12, 7]):
                n = n_of(e8 * 2 * 0.9, sr)
                place(buf, tri(np.full(n, note(r - 24 + off)), sr) * env(n, 0.005, 0.2, 0.6, 0.05, sr) * 0.5, t0 + q * 2 * e8, sr)
            for k in (1, 3, 5, 7):  # «гармошка» на слабые доли
                n = n_of(e8 * 0.7, sr)
                stab = sum(square(np.full(n, note(c - 12)), 0.5, sr) for c in ch) / 3
                place(buf, lowpass(stab, 2500, sr, 1) * env(n, 0.004, 0.05, 0.4, 0.03, sr) * 0.13, t0 + k * e8, sr)
            for k, hit in enumerate("D.ttD.t."):
                if hit == "D":
                    place(buf, dum(sr) * 0.55, t0 + k * e8, sr)
                elif hit == "t":
                    place(buf, tek(rng, sr) * 0.25, t0 + k * e8, sr)
        else:
            for k in range(8):
                n = n_of(e8 * 0.85, sr)
                off = 12 if k % 2 else 0
                bass = 0.7 * tri(np.full(n, note(r - 24 + off)), sr) + 0.15 * square(np.full(n, note(r - 24 + off)), 0.5, sr)
                place(buf, bass * env(n, 0.004, 0.1, 0.7, 0.03, sr) * 0.5, t0 + k * e8, sr)
            for k in range(16):  # тихое арпеджио шестнадцатыми
                n = n_of(e8 / 2 * 0.8, sr)
                c = ch[k % 3] + 12
                place(buf, square(np.full(n, note(c)), 0.125, sr) * env(n, 0.002, 0.05, 0.3, 0.02, sr) * 0.07, t0 + k * e8 / 2, sr)
            for k in range(8):
                if k in (0, 3, 4):
                    place(buf, kick(sr) * 0.7, t0 + k * e8, sr)
                if k in (2, 6):
                    place(buf, snare(rng, sr) * 0.35, t0 + k * e8, sr)
                place(buf, hat(rng, sr) * (0.14 if k % 2 else 0.09), t0 + k * e8, sr)
    n = n_of(length, sr)
    out = buf[:n].copy()
    out[: len(buf) - n] += buf[n:]  # хвосты последних нот звучат в начале петли
    out = lowpass(out, 9000, sr, 1)
    return norm(out - out.mean(), 0.7)


# Пышечная: вальсок на «гармошке» в ре мажоре, 6 восьмых в такте (раз-два-три).
PYSHKI = {
    "bpm": 132,
    "lead": ["9 - - 7 5 7", "9 - 12 - 9 -", "10 - - 9 7 9", "10 - 14 - 10 -",
             "12 - 10 9 7 5", "7 - 9 - 7 -", "4 - 5 7 9 7", "5 - - - . ."],
    "roots": [5, 5, 10, 10, 5, 0, 0, 5],
}
WALTZ_CHORD = {5: [5, 9, 12], 0: [0, 4, 7, 10], 10: [10, 14, 17]}


def accordion(nn, dur, vol, sr=MSR):
    """Два чуть расстроенных голоса с мягким нажимом мехов."""
    n = n_of(dur, sr)
    t = tt(dur, sr)
    trem = 1 + 0.08 * np.sin(2 * np.pi * 6.0 * t)
    f = note(nn)
    x = square(np.full(n, f * 1.003), 0.3, sr) + square(np.full(n, f * 0.997), 0.4, sr)
    return lowpass(x, 3000, sr, 1) * trem * env(n, 0.03, 0.1, 0.75, 0.05, sr) * vol


def render_waltz(song, sr=MSR):
    e8 = 60.0 / song["bpm"] / 2
    bars = len(song["lead"])
    length = e8 * 6 * bars
    buf = np.zeros(n_of(length + 2.0, sr))
    for nn, st, ln in parse(song["lead"]):
        place(buf, accordion(nn, e8 * ln * 0.95, 0.2), st * e8, sr)
    for b, r in enumerate(song["roots"]):
        t0 = b * 6 * e8
        n = n_of(e8 * 1.8, sr)
        place(buf, tri(np.full(n, note(r - 24)), sr) * env(n, 0.005, 0.25, 0.5, 0.05, sr) * 0.55, t0, sr)
        for k in (2, 4):  # «па-па» аккордом
            m = n_of(e8 * 1.2, sr)
            stab = sum(accordion(c - 12, e8 * 1.2, 1.0) for c in WALTZ_CHORD[r]) / len(WALTZ_CHORD[r])
            place(buf, stab[:m] * 0.09, t0 + k * e8, sr)
    n = n_of(length, sr)
    out = buf[:n].copy()
    out[: len(buf) - n] += buf[n:]
    out = lowpass(out, 8000, sr, 1)
    return norm(out - out.mean(), 0.7)


# Чебуречная у вокзала: бодрая песенка в ля миноре, бас «ум-па», стук колёс на стыках рельсов
# (два удара подряд) и гудок поезда в последнем такте.
CHEBUREKI = {
    "bpm": 126,
    "lead": ["12 - 10 8 7 - 7 .", "8 7 5 3 5 - - .", "7 - 8 10 12 - 10 8", "7 - - . 7 8 7 5",
             "3 - 5 7 8 - 7 5", "5 - 7 8 10 - 8 7", "7 8 10 12 11 - 7 .", "12 - - . . . . ."],
    "roots": [0, 5, 7, 7, 0, 5, 7, 0],
}
TRAIN_CHORD = {0: [0, 3, 7], 5: [5, 8, 12], 7: [7, 11, 14]}


def whistle(dur, sr=MSR):
    """Гудок: три синуса аккордом, въезжают снизу и чуть дрожат."""
    n = n_of(dur, sr)
    t = tt(dur, sr)
    bend = 1 - 0.06 * np.exp(-t * 12)
    x = sum(sine(note(c) * bend * (1 + 0.004 * np.sin(2 * np.pi * 7 * t)), sr) for c in (3, 7, 12))
    return x / 3 * env(n, 0.04, 0.2, 0.8, 0.15, sr)


def render_train(song, rng, sr=MSR):
    e8 = 60.0 / song["bpm"] / 2
    bars = len(song["lead"])
    length = e8 * 8 * bars
    buf = np.zeros(n_of(length + 2.0, sr))
    for nn, st, ln in parse(song["lead"]):
        place(buf, lead_voice(nn, e8 * ln, 0.5, 0.26), st * e8, sr)
    for b, r in enumerate(song["roots"]):
        t0 = b * 8 * e8
        for q, off in enumerate([0, 7, 0, 7]):  # «ум» на сильные доли
            n = n_of(e8 * 0.9, sr)
            place(buf, tri(np.full(n, note(r - 24 + off)), sr) * env(n, 0.004, 0.12, 0.6, 0.03, sr) * 0.55, t0 + q * 2 * e8, sr)
        for k in (1, 3, 5, 7):  # «па» аккордом гармошки
            m = n_of(e8 * 0.6, sr)
            stab = sum(accordion(c - 12, e8 * 0.6, 1.0) for c in TRAIN_CHORD[r]) / 3
            place(buf, stab[:m] * 0.1, t0 + k * e8, sr)
        for k in (0, 1, 4, 5):  # стыки рельсов: та-дам, та-дам
            place(buf, tek(rng, sr) * (0.3 if k % 2 else 0.22), t0 + k * e8, sr)
        place(buf, dum(sr) * 0.4, t0, sr)
        for k in range(8):
            place(buf, hat(rng, sr) * 0.06, t0 + k * e8 + e8 / 2, sr)
    place(buf, whistle(e8 * 4) * 0.22, (bars - 1) * 8 * e8 + 3 * e8, sr)
    n = n_of(length, sr)
    out = buf[:n].copy()
    out[: len(buf) - n] += buf[n:]
    out = lowpass(out, 8500, sr, 1)
    return norm(out - out.mean(), 0.7)


# Хот-доги у стадиона: марш духового оркестра на трибуне в до мажоре, хлопки болельщиков, свисток судьи.
HOTDOGS = {
    "bpm": 120,
    "lead": ["7 - 7 4 7 - 12 .", "11 - 7 11 14 - - .", "9 - 5 9 12 - 9 .", "7 - 11 14 11 - 7 .",
             "12 - 12 11 12 - 7 .", "9 - 9 7 5 - 9 .", "7 9 11 12 14 - 11 7", "12 - - . 7 . 12 ."],
    "roots": [0, 7, 5, 7, 0, 5, 7, 0],
}
MARCH_CHORD = {0: [0, 4, 7], 5: [5, 9, 12], 7: [7, 11, 14]}


def clap(rng, sr=MSR):
    """Хлопок толпы: три коротких шумовых щелчка подряд."""
    n = n_of(0.12, sr)
    x = np.zeros(n)
    for k, at in enumerate((0.0, 0.011, 0.022)):
        m = n_of(0.03 if k == 2 else 0.008, sr)
        place(x, bandpass(noise(m, rng), 1500, 0.8, sr) * decay(m, 0.01 if k == 2 else 0.003, sr), at, sr)
    return x


def ref_whistle(dur, sr=MSR):
    """Свисток судьи: высокий тон с быстрой трелью горошины."""
    n = n_of(dur, sr)
    t = tt(dur, sr)
    f = 2900 * (1 + 0.03 * np.sign(np.sin(2 * np.pi * 28 * t)))
    return sine(f, sr) * env(n, 0.01, 0.05, 0.8, 0.03, sr)


def render_stadium(song, rng, sr=MSR):
    e8 = 60.0 / song["bpm"] / 2
    bars = len(song["lead"])
    length = e8 * 8 * bars
    buf = np.zeros(n_of(length + 2.0, sr))
    for nn, st, ln in parse(song["lead"]):
        # «труба»: пошире прямоугольник, чуть приглушённый
        v = lead_voice(nn, e8 * ln, 0.4, 0.26) + lead_voice(nn - 12, e8 * ln, 0.5, 0.08)
        place(buf, lowpass(v, 3200, sr, 1), st * e8, sr)
    for b, r in enumerate(song["roots"]):
        t0 = b * 8 * e8
        for q, off in enumerate([0, 7, 0, 7]):  # туба: ум-па
            n = n_of(e8 * 1.1, sr)
            tuba = 0.6 * tri(np.full(n, note(r - 24 + off)), sr) + 0.25 * square(np.full(n, note(r - 24 + off)), 0.5, sr)
            place(buf, lowpass(tuba, 900, sr, 1) * env(n, 0.01, 0.15, 0.6, 0.04, sr) * 0.5, t0 + q * 2 * e8, sr)
        for k in (1, 3, 5, 7):  # аккорд на слабые доли
            n = n_of(e8 * 0.6, sr)
            stab = sum(square(np.full(n, note(c - 12)), 0.25, sr) for c in MARCH_CHORD[r]) / 3
            place(buf, lowpass(stab, 2200, sr, 1) * env(n, 0.004, 0.05, 0.4, 0.03, sr) * 0.12, t0 + k * e8, sr)
        place(buf, kick(sr) * 0.75, t0, sr)
        place(buf, kick(sr) * 0.55, t0 + 4 * e8, sr)
        for k in (2, 6):
            place(buf, snare(rng, sr) * 0.3, t0 + k * e8, sr)
            place(buf, clap(rng, sr) * 0.45, t0 + k * e8, sr)
        if b % 2 == 1:  # дробь малого барабана в конце каждого второго такта
            for k in range(4):
                place(buf, snare(rng, sr) * (0.12 + 0.04 * k), t0 + 6 * e8 + k * e8 / 2, sr)
        for k in range(8):
            place(buf, hat(rng, sr) * 0.05, t0 + k * e8 + e8 / 2, sr)
    end = (bars - 1) * 8 * e8
    place(buf, ref_whistle(e8 * 0.6) * 0.12, end + 5 * e8, sr)
    place(buf, ref_whistle(e8 * 1.4) * 0.12, end + 6 * e8, sr)
    n = n_of(length, sr)
    out = buf[:n].copy()
    out[: len(buf) - n] += buf[n:]
    out = lowpass(out, 9000, sr, 1)
    return norm(out - out.mean(), 0.7)


MUSIC = {"music_kiosk": (KIOSK, "kiosk"), "music_flight": (FLIGHT, "flight"), "music_pyshki": (PYSHKI, "waltz"),
         "music_chebureki": (CHEBUREKI, "train"), "music_hotdogs": (HOTDOGS, "stadium")}
LOOPS = {"gas", "squeeze", "wind"}


def finish(x, loop, sr=SR):
    """Убирает постоянную составляющую (её дают узкие прямоугольники), у разовых звуков гасит хвост."""
    peak = np.max(np.abs(x))
    if loop:
        x = x - x.mean()
    else:
        x = highpass(x, 20, sr)
        nf = min(len(x), n_of(0.004, sr))
        x[-nf:] *= np.linspace(1, 0, nf)
    return norm(x, peak)


# ---------------- запись ----------------

def write_wav(path, x, sr=SR):
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "sounds"
    only = set(sys.argv[2:])
    os.makedirs(out, exist_ok=True)
    for i, (name, fn) in enumerate(SOUNDS.items()):
        if only and name not in only:
            continue
        x = finish(fn(np.random.default_rng(1000 + i)), name in LOOPS)
        write_wav(os.path.join(out, name + ".wav"), x)
        print(f"{name}.wav: {len(x) / SR:.2f} с")
    for i, (name, (song, style)) in enumerate(MUSIC.items()):
        if only and name not in only:
            continue
        rng = np.random.default_rng(2000 + i)
        if style == "waltz":
            x = render_waltz(song)
        elif style == "train":
            x = render_train(song, rng)
        elif style == "stadium":
            x = render_stadium(song, rng)
        else:
            x = render(song, style, rng)
        tmp = os.path.join(out, name + ".tmp.wav")
        write_wav(tmp, x, MSR)
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4",
                        os.path.join(out, name + ".ogg")], check=True)
        os.remove(tmp)
        print(f"{name}.ogg: {len(x) / MSR:.2f} с")


if __name__ == "__main__":
    main()
