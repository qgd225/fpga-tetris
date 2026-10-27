#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""CORE-07 UI v3.1 mockup renderer (1280x720).

按 ui美化计划书.md（v3.1）的坐标与色值渲染示意图。
注意：这是设计效果图，不是 RTL 输出；字体用 5x7 点阵近似，字宽与规格中的
8x12 字库略有出入。
"""
import os
from PIL import Image, ImageDraw

W, H = 1280, 720
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ui_mock")

# ---------------- palette ----------------
C = dict(
    space="#070A10", darkest="#0A1118", card="#0C161E", field="#131D26",
    channel="#16212B", hull="#1A2530", fdot="#1C2836", dot="#22303D",
    line="#2A3644", struct="#3A4A58", struct2="#5B6E7E", txtdim="#A8B6C0",
    title="#C9D2D8", val="#E8EEF2",
    cyan="#2FA8B8", cyanl="#7FE3EC", cyand="#1B6B76",
    pink="#C4527A", pinkl="#E889A8", pinkd="#7E2E4A",
    amber="#E8A23C", amberl="#FFC96B", amberd="#8A5A18",
    red="#D8442E", redl="#FF6B35", redd="#7A2418",
    star1="#9FB0C0", star2="#5B6E7E", planet="#3A4A58",
)
def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

# ---------------- 5x7 font ----------------
G = {
 'A': ".###.|#...#|#...#|#####|#...#|#...#|#...#",
 'B': "####.|#...#|#...#|####.|#...#|#...#|####.",
 'C': ".###.|#...#|#....|#....|#....|#...#|.###.",
 'D': "####.|#...#|#...#|#...#|#...#|#...#|####.",
 'E': "#####|#....|#....|####.|#....|#....|#####",
 'F': "#####|#....|#....|####.|#....|#....|#....",
 'G': ".###.|#...#|#....|#.###|#...#|#...#|.####",
 'H': "#...#|#...#|#...#|#####|#...#|#...#|#...#",
 'I': ".###.|..#..|..#..|..#..|..#..|..#..|.###.",
 'J': "..###|...#.|...#.|...#.|...#.|#..#.|.##..",
 'K': "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#",
 'L': "#....|#....|#....|#....|#....|#....|#####",
 'M': "#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#",
 'N': "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
 'O': ".###.|#...#|#...#|#...#|#...#|#...#|.###.",
 'P': "####.|#...#|#...#|####.|#....|#....|#....",
 'Q': ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#",
 'R': "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
 'S': ".####|#....|#....|.###.|....#|....#|####.",
 'T': "#####|..#..|..#..|..#..|..#..|..#..|..#..",
 'U': "#...#|#...#|#...#|#...#|#...#|#...#|.###.",
 'V': "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
 'W': "#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#",
 'X': "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
 'Y': "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..",
 'Z': "#####|....#|...#.|..#..|.#...|#....|#####",
 '0': ".###.|#...#|#..##|#.#.#|##..#|#...#|.###.",
 '1': "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
 '2': ".###.|#...#|....#|...#.|..#..|.#...|#####",
 '3': "#####|...#.|..#..|...#.|....#|#...#|.###.",
 '4': "...#.|..##.|.#.#.|#..#.|#####|...#.|...#.",
 '5': "#####|#....|####.|....#|....#|#...#|.###.",
 '6': "..##.|.#...|#....|####.|#...#|#...#|.###.",
 '7': "#####|....#|...#.|..#..|.#...|.#...|.#...",
 '8': ".###.|#...#|#...#|.###.|#...#|#...#|.###.",
 '9': ".###.|#...#|#...#|.####|....#|...#.|.##..",
 ' ': ".....|.....|.....|.....|.....|.....|.....",
 '-': ".....|.....|.....|#####|.....|.....|.....",
 '/': "....#|...#.|...#.|..#..|.#...|.#...|#....",
 ':': ".....|..#..|..#..|.....|..#..|..#..|.....",
 '.': ".....|.....|.....|.....|.....|..##.|..##.",
 '[': ".###.|.#...|.#...|.#...|.#...|.#...|.###.",
 ']': ".###.|...#.|...#.|...#.|...#.|...#.|.###.",
}
GW, GH = 5, 7


def text_w(s, scale):
    return len(s) * GW * scale + max(0, len(s) - 1) * scale


def text(d, x, y, s, scale=2, color="#E8EEF2", tracking=0, align="l"):
    s = s.upper()
    adv = GW * scale + scale + tracking
    width = (len(s) - 1) * adv + GW * scale if s else 0
    if align == "c":
        x = x - width // 2
    elif align == "r":
        x = x - width
    col = rgb(color)
    for ch in s:
        pat = G.get(ch, G[' ']).split("|")
        for ry, row in enumerate(pat):
            for rx, bit in enumerate(row):
                if bit == "#":
                    d.rectangle([x + rx * scale, y + ry * scale,
                                 x + (rx + 1) * scale - 1, y + (ry + 1) * scale - 1], fill=col)
        x += adv
    return width


def mix(h, f):
    r, g, b = rgb(h)
    if f >= 0:
        return (int(r + (255 - r) * f), int(g + (255 - g) * f), int(b + (255 - b) * f))
    return (int(r * (1 + f)), int(g * (1 + f)), int(b * (1 + f)))


def block(d, x, y, col, face=22, gap=2):
    c = rgb(col) if isinstance(col, str) else col
    d.rectangle([x + gap // 2 + 1, y + gap // 2 + 1, x + gap // 2 + face, y + gap // 2 + face], fill=c)
    d.rectangle([x + 2, y + 2, x + 2, y + 21], fill=mix(col, 0.30) if isinstance(col, str) else c)
    d.rectangle([x + 2, y + 2, x + 21, y + 2], fill=mix(col, 0.30) if isinstance(col, str) else c)
    d.rectangle([x + 2, y + 22, x + 22, y + 22], fill=mix(col, -0.45) if isinstance(col, str) else c)
    d.rectangle([x + 22, y + 3, x + 22, y + 22], fill=mix(col, -0.45) if isinstance(col, str) else c)


# ---------------- background ----------------
def background(d, phase=3, danger=0):
    d.rectangle([0, 0, W, H], fill=rgb(C['space']))
    d.rectangle([0, 140, W, H], fill=rgb(C['hull']))
    # hull seams
    for y in (232, 328, 424, 520, 616):
        for x0 in range(0, W, 220):
            d.line([(x0, y), (x0 + 180, y)], fill=rgb("#1E2833"), width=1)
    for x in (96, 256, 1000, 1216):
        for y0 in range(140, H, 200):
            d.line([(x, y0), (x, y0 + 160)], fill=rgb("#1E2833"), width=1)
    # stars
    for sx, sy, s in ((70, 40, 1), (300, 26, 2), (520, 62, 1), (760, 22, 2), (980, 48, 1),
                      (1180, 28, 2), (420, 108, 1), (860, 104, 1), (1240, 96, 2)):
        d.rectangle([sx, sy, sx + s - 1, sy + s - 1], fill=rgb(C['star1'] if s > 1 else C['star2']))
    # planet
    px, py = 24, 68
    d.ellipse([px + 16, py + 6, px + 88, py + 48], fill=rgb(C['planet']))
    d.ellipse([px + 16, py + 6, px + 58, py + 36], fill=rgb("#243240"))
    d.ellipse([px, py + 18, px + 104, py + 34], outline=rgb(C['struct2']), width=1)
    # space / hull divider
    d.line([(0, 140), (W - 1, 140)], fill=rgb(C['line']))


# ---------------- field ----------------
def field(d, blocked, active=None, ghost=None, danger=0, dim=None):
    x0, y0, x1, y1 = 352, 144, 928, 624
    fd = rgb(C['field'])
    if dim is not None:
        fd = mix(C['field'], -dim)
    d.rectangle([x0, y0, x1 - 1, y1 - 1], fill=fd)
    # dot matrix
    dc = rgb(C['fdot']) if dim is None else mix(C['fdot'], -dim)
    for j in range(20):
        for i in range(24):
            cx, cy = x0 + i * 24 + 11, y0 + j * 24 + 11
            d.rectangle([cx, cy, cx + 1, cy + 1], fill=dc)
    # blocks
    for (i, j, t) in blocked:
        col = rgb(TYPES[t])
        if dim is not None:
            col = mix(TYPES[t], -dim)
        d.rectangle([x0 + i * 24 + 1, y0 + j * 24 + 1, x0 + i * 24 + 23, y0 + j * 24 + 23], fill=col)
    if ghost:
        cells, t = ghost
        c = mix(TYPES[t], -0.45)
        for (i, j) in cells:
            gx, gy = x0 + i * 24 + 2, y0 + j * 24 + 2
            for k in range(20):
                if (k // 4) % 2 == 0:
                    d.point((gx + k, gy), fill=c); d.point((gx + k, gy + 19), fill=c)
                    d.point((gx, gy + k), fill=c); d.point((gx + 19, gy + k), fill=c)
    if active:
        cells, t = active
        for (i, j) in cells:
            block(d, x0 + i * 24 - 1, y0 + j * 24 - 1, TYPES[t])


def frame(d, danger=0, dim=None):
    """四边不同构的场地框：顶夹爪 / 左刻度 / 右端口 / 底排线。"""
    x0, y0, x1, y1 = 352, 144, 928, 624
    ch = rgb(C['channel']) if dim is None else mix(C['channel'], -dim)
    ln = rgb(C['line']) if dim is None else mix(C['line'], -dim)
    dk = rgb(C['darkest']) if dim is None else mix(C['darkest'], -dim)
    hi = rgb(C['dot']) if dim is None else mix(C['dot'], -dim)
    st = rgb(C['struct']) if dim is None else mix(C['struct'], -dim)

    # ---- top: 6px channel with 3 clamps
    d.line([(x0 - 6, y0 - 6), (x1 + 5, y0 - 6)], fill=ln)
    d.rectangle([x0 - 6, y0 - 5, x1 + 5, y0 - 2], fill=dk)
    d.line([(x0 - 6, y0 - 1), (x1 + 5, y0 - 1)], fill=hi)
    for cx in (428, 636, 844):
        d.rectangle([cx, y0 - 6, cx + 7, y0 - 1], fill=rgb(C['hull']))
        d.rectangle([cx, y0 - 5, cx + 7, y0 - 2], fill=dk)
    # ---- left: channel + ticks
    d.line([(x0 - 6, y0 - 6), (x0 - 6, y1 + 7)], fill=ln)
    d.rectangle([x0 - 5, y0 - 6, x0 - 2, y1 + 7], fill=dk)
    d.line([(x0 - 1, y0 - 6), (x0 - 1, y1 + 7)], fill=hi)
    for k in range(11):
        ty = y0 + 48 * k
        if ty > y1:
            break
        ln_ = 4 if k % 4 else 8
        d.rectangle([x0 - 4 - (ln_ - 4), ty, x0 - 1, ty], fill=st)
    # ---- right: channel + 4 ports
    d.line([(x1 + 5, y0 - 6), (x1 + 5, y1 + 7)], fill=ln)
    d.rectangle([x1 + 2, y0 - 6, x1 + 5, y1 + 7], fill=dk)
    d.line([(x1, y0 - 6), (x1, y1 + 7)], fill=hi)
    for idx, py in enumerate((568, 504, 440, 376)):
        lit = 3 - idx <= 2 and danger >= 0 and idx == 2  # 只点亮 STABILIZE 那一档
        d.rectangle([x1, py, x1 + 5, py + 23], fill=dk)
        d.rectangle([x1, py, x1 + 5, py + 23], outline=st, width=1)
        d.rectangle([x1 + 3, py + 4, x1 + 4, py + 19], fill=rgb(C['amber']) if lit else rgb(C['dot']))
    # ---- bottom: 45 deg hatch
    for yy in range(y1, y1 + 8):
        for xx in range(x0, x1 + 6):
            if ((xx + yy) & 63) < 2:
                d.point((xx, yy), fill=st)
    # rivets
    for (rx, ry) in ((345, 168), (345, 380), (345, 592), (924, 638)):
        d.rectangle([rx, ry, rx + 3, ry + 3], fill=rgb(C['amberd']))


# ---------------- cards ----------------
def marker(d, x, y, col):
    d.rectangle([x - 1, y - 1, x + 8, y + 8], fill=rgb(C['darkest']))
    d.rectangle([x, y, x + 7, y + 7], fill=rgb(col))


def card(d, axis, title, y_title, y_rule, y_panel, side="l", p1=True, hold=False):
    xw = 112
    xl = axis - xw // 2
    # title
    text(d, axis, y_title, title, 3, C['title'], tracking=6, align="c")
    # marker
    if side == "l":
        mx = xl - 8 - 8
    else:
        mx = xl + xw + 8
    my = y_title + 5
    if hold:
        marker(d, mx, my, C['cyan'])
        d.rectangle([mx, my, mx + 3, my + 7], fill=rgb(C['cyan']))
        d.rectangle([mx + 4, my, mx + 7, my + 7], fill=rgb(C['pink']))
    else:
        marker(d, mx, my, C['cyan'] if p1 else C['pink'])
    # rule
    d.line([(xl, y_rule), (xl + xw - 1, y_rule)], fill=rgb(C['line']))
    # panel
    d.rectangle([xl, y_panel, xl + xw - 1, y_panel + xw - 1], fill=rgb(C['card']))
    d.line([(xl, y_panel), (xl + xw - 1, y_panel)], fill=rgb("#050A0E"))
    d.line([(xl, y_panel), (xl, y_panel + xw - 1)], fill=rgb("#050A0E"))
    d.line([(xl, y_panel + xw - 1), (xl + xw - 1, y_panel + xw - 1)], fill=rgb(C['dot']))
    d.line([(xl + xw - 1, y_panel), (xl + xw - 1, y_panel + xw - 1)], fill=rgb(C['dot']))
    # dot matrix 4x4
    for j in range(4):
        for i in range(4):
            px, py = xl + 8 + 12 + i * 24, y_panel + 8 + 12 + j * 24
            d.rectangle([px, py, px + 1, py + 1], fill=rgb(C['dot']))


def card_piece(d, axis, y_panel, cells, t):
    xl = axis - 48
    for (i, j) in cells:
        block(d, xl + i * 24 - 1, y_panel + 8 + j * 24 - 1, TYPES[t])


# ---------------- core ----------------
def core(d, locked=5, danger=0, dim=None):
    x0, x1 = 1016, 1064
    y1 = 608
    for i in range(8):
        sy1 = y1 - 32 * (i + 1)
        sy2 = y1 - 32 * i
        if i < locked:
            f, l = C['cyand'], C['cyan']
        elif i == locked:
            f, l = C['amberd'], C['amberl']
        else:
            f, l = C['card'], None
        if dim is not None:
            f = mix(f, -dim)
        d.rectangle([x0, sy1 + 2, x1 - 1, sy2 - 2], fill=rgb(f))
        d.rectangle([x0, sy1 + 2, x1 - 1, sy1 + 2], fill=rgb(C['darkest']))
        d.rectangle([x0, sy2 - 2, x1 - 1, sy2 - 2], fill=rgb(C['darkest']))
        if l:
            c = rgb(l) if dim is None else mix(l, -dim)
            d.rectangle([1039, sy1 + 6, 1040, sy2 - 6], fill=c)
        else:
            for dy in (sy1 + 10, sy1 + 20):
                for dx in (1028, 1044):
                    d.rectangle([dx, dy, dx + 1, dy + 1], fill=rgb(C['dot']))
        if i == locked:
            d.rectangle([1036, sy1 + 12, 1043, sy1 + 19], fill=rgb(C['amberl']))
    # top connector (open)
    d.rectangle([1032, 340, 1047, 343], fill=rgb(C['struct2']))
    d.rectangle([1032, 348, 1047, 351], fill=rgb(C['struct2']))
    # guard teeth at locked>=6
    if locked >= 6:
        g = rgb(C['red']) if danger >= 2 else rgb(C['struct'])
        for k in range(4):
            ty = 400 + k * 52
            d.rectangle([1008, ty, 1013, ty + 1], fill=g)
            d.rectangle([1067, ty, 1072, ty + 1], fill=g)


# ---------------- gloves ----------------
def gloves(d):
    for flip in (False, True):
        def X(x):
            return 1280 - x if flip else x

        def R(x1, y1, x2, y2, col):
            d.rectangle([min(x1, x2), y1, max(x1, x2), y2], fill=rgb(col))

        # forearm wedge
        d.polygon([(X(192), 704), (X(192), 662), (X(214), 650), (X(248), 650), (X(248), 704)],
                  fill=rgb("#243240"))
        # hand
        d.polygon([(X(262), 646), (X(320), 642), (X(320), 704), (X(262), 704)],
                  fill=rgb(C['struct']))
        # wrist ring
        R(X(248), 644, X(262), 704, C['struct'])
        d.line([(X(248), 644), (X(262), 644)], fill=rgb(C['struct2']))
        d.line([(X(248), 703), (X(262), 703)], fill=rgb("#0E151C"))
        # knuckles + underside shadow
        for kx in (284, 300, 316):
            d.line([(X(kx), 652), (X(kx), 692)], fill=rgb("#0E151C"))
        R(X(262), 696, X(320), 704, "#0E151C")
        d.line([(X(262), 647), (X(320), 643)], fill=rgb(C['struct2']))
        # tether
        d.line([(X(192), 668), (X(0), 644)], fill=rgb("#2E3E4C"), width=2)
        for k in range(1, 9):
            px = X(192) + (X(0) - X(192)) * k // 9
            py = 668 + (644 - 668) * k // 9
            d.rectangle([px - 1, py - 1, px + 1, py + 1], fill=rgb("#3A4A58"))


# ---------------- HUD ----------------
def hud(d, phase=3, spd=6, prog=19 / 40):
    d.line([(352, 128), (927, 128)], fill=rgb(C['line']))
    text(d, 352, 72, ["01 RECONNECT", "02 REBUILD", "03 STABILIZE", "04 RECHARGE"][phase - 1],
         3, C['title'], tracking=2)
    text(d, 866, 76, "SPD", 2, C['struct2'], tracking=2, align="r")
    text(d, 928, 76, "%d/8" % spd, 2, C['val'], tracking=2, align="r")
    d.rectangle([352, 106, 927, 111], fill=rgb(C['fdot']))
    d.rectangle([352, 106, 352 + int(575 * prog), 111], fill=rgb(C['cyan']))
    # P1 / P2
    text(d, 160, 116, "P1", 2, C['cyan'], tracking=2)
    text(d, 1120, 116, "P2", 2, C['pink'], tracking=2, align="r")


def nameplate(d, dim=None):
    d.line([(352, 633), (927, 633)], fill=rgb(C['line']))
    text(d, 352, 632, "CONTAINMENT 07", 2, C['struct2'], tracking=1)
    text(d, 928, 632, "24X20", 2, C['struct2'], tracking=1, align="r")


def left_block(d):
    text(d, 168, 498, "CORE-07", 2, C['struct2'], tracking=1)
    text(d, 168, 514, "PWR 4200V", 2, C['struct2'], tracking=1)
    text(d, 168, 530, "EVA ONLY", 2, C['amberd'], tracking=1)


def time_readout(d, t="02:18", dim=None):
    col = C['struct2'] if dim is None else mix(C['struct2'], -dim)
    vc = C['val'] if dim is None else mix(C['val'], -dim)
    text(d, 352, 650, "TIME", 2, col, tracking=2)
    text(d, 424, 650, t, 2, vc, tracking=1)


TYPES = dict(I="#38B6C8", O="#D9B23C", T="#9B6BB5", S="#4FA86B",
             Z="#C2453A", J="#3E6FBF", L="#D97B33")

ROWS = {
    19: "JJZZSSOOTTTIILLJZSO",
    18: "JJZZ..SSOOTTIILLJZS",
    17: "...ZZSSOOTTIILLJZ...",
    16: ".....SSOOTTIILL.....",
    15: "........OOTTII......",
    14: "..........TT........",
}
STACK = [(i, r, ch) for r, s in ROWS.items() for i, ch in enumerate(s) if ch != '.']
ACTIVE = ([(8, 3), (9, 3), (8, 4), (9, 4)], 'O')
GHOST = ([(8, 13), (9, 13), (8, 14), (9, 14)], 'O')


def scene_duo(dim_field=None, active=True, show_time=True):
    img = Image.new("RGB", (W, H), rgb(C['space']))
    d = ImageDraw.Draw(img)
    background(d)
    text(d, 64, 36, "CORE-07", 3, C['title'], tracking=8)
    hud(d, 3, 6, 19 / 40)
    field(d, STACK,
          ACTIVE if active else None,
          GHOST if active else None,
          dim=dim_field)
    frame(d)
    nameplate(d)
    card(d, 224, "NEXT", 140, 180, 192)
    card_piece(d, 224, 192, [(1, 0), (0, 1), (1, 1), (2, 1)], 'T')
    card(d, 224, "HOLD", 316, 356, 368, hold=True)
    card(d, 1040, "NEXT", 140, 180, 192, side="r", p1=False)
    card_piece(d, 1040, 192, [(0, 0), (1, 0), (0, 1), (0, 2)], 'L')
    text(d, 1040, 316, "CORE", 3, C['title'], tracking=6, align="c")
    core(d, 5, 0)
    left_block(d)
    if show_time:
        time_readout(d)
    gloves(d)
    return img


def scene_result():
    img = scene_duo(dim_field=0.62, active=False, show_time=False)
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = 383, 225, 787, 529
    d.rectangle([x0, y0, x1, y1], fill=rgb(C['darkest']))
    d.rectangle([x0, y0, x1, y0 + 3], fill=rgb(C['red']))
    d.line([(x0, y0), (x0, y1)], fill=rgb("#050A0E"))
    d.line([(x0, y1), (x1, y1)], fill=rgb(C['dot']))
    d.line([(x1, y0), (x1, y1)], fill=rgb(C['dot']))
    ix = x0 + 24
    text(d, ix, y0 + 20, "LINK LOST", 4, C['red'], tracking=4)
    text(d, ix, y0 + 60, "DUO REPAIR", 2, C['struct2'], tracking=2)
    d.line([(ix, y0 + 86), (ix + 320, y0 + 86)], fill=rgb(C['line']))
    rows = [("SCORE", "12480"), ("SPD", "6/8"), ("LINES", "19/40"), ("TIME", "02:18")]
    for k, (lab, val) in enumerate(rows):
        y = y0 + 102 + k * 24
        text(d, ix, y, lab, 2, C['struct2'], tracking=2)
        text(d, x1 - 24, y, val, 2, C['val'], tracking=1, align="r")
    text(d, ix, y0 + 212, "CORE 5/8 SEALED", 2, C['amber'], tracking=1)
    text(d, ix, y0 + 258, "PRESS [BTN] TO RETRY", 2, C['cyan'], tracking=1)
    return img


def scene_detail():
    img = scene_duo()
    crop = img.crop((140, 110, 940, 660))
    return crop.resize((crop.width * 2, crop.height * 2), Image.NEAREST)


def main():
    os.makedirs(OUT, exist_ok=True)
    a = scene_duo(); a.save(os.path.join(OUT, "v31_duo.png"))
    b = scene_result(); b.save(os.path.join(OUT, "v31_result.png"))
    c = scene_detail(); c.save(os.path.join(OUT, "v31_detail.png"))
    print("ok", OUT)


if __name__ == "__main__":
    main()
