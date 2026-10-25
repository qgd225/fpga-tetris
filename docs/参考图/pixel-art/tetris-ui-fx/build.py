from pathlib import Path
import sys


SKILL_SCRIPTS = Path(r"C:\Users\qiguidie\.codex\skills\pixel-art-studio\scripts")
sys.path.insert(0, str(SKILL_SCRIPTS))

from pixelstudio import Sprite  # noqa: E402


ROOT = Path(__file__).resolve().parent
OUT = ROOT.parents[1] / "游戏优化参考图"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 640, 360

BLACK = "#000000"
FIELD = "#0A0F16"
P1_SLOT = "#081A1E"
P2_SLOT = "#1E0812"
PANEL = "#202020"
WHITE = "#FFFFFF"
RED = "#E63946"
ORANGE = "#F77F24"
YELLOW = "#FFFF00"
GREEN = "#55A630"
PURPLE = "#9933CC"
CYAN = "#00CCFF"
PINK = "#FF4DA6"
P1_ACCENT = "#00E5FF"
P2_ACCENT = "#FF4DA6"
P1_SOFT = "#6BF0FF"
P2_SOFT = "#FF98CB"
LIGHT_CYAN = "#99EEFF"
LIGHT_PINK = "#FFB3D9"
LIGHT_RED = "#FFB3B9"
LIGHT_YELLOW = "#FFFF99"
LIGHT_GREEN = "#BDE0AA"
LIGHT_ORANGE = "#FFD9B3"
LIGHT_PURPLE = "#D9B3E6"

PALETTE = [
    BLACK,
    FIELD,
    P1_SLOT,
    P2_SLOT,
    PANEL,
    WHITE,
    RED,
    ORANGE,
    YELLOW,
    GREEN,
    PURPLE,
    CYAN,
    PINK,
    P1_ACCENT,
    P2_ACCENT,
    P1_SOFT,
    P2_SOFT,
    LIGHT_CYAN,
    LIGHT_PINK,
    LIGHT_RED,
    LIGHT_YELLOW,
    LIGHT_GREEN,
    LIGHT_ORANGE,
    LIGHT_PURPLE,
    "#04637E",
    "#471F67",
    "#74790D",
    "#69222C",
    "#295223",
    "#71411D",
    "#742B56",
]

TYPE = {
    "I": (CYAN, LIGHT_CYAN, "#04637E"),
    "O": (YELLOW, LIGHT_YELLOW, "#74790D"),
    "T": (PURPLE, LIGHT_PURPLE, "#471F67"),
    "S": (RED, LIGHT_RED, "#69222C"),
    "Z": (GREEN, LIGHT_GREEN, "#295223"),
    "L": (ORANGE, LIGHT_ORANGE, "#71411D"),
    "J": (PINK, LIGHT_PINK, "#742B56"),
}

FEEDBACK = {
    "I": ((0, 1), (1, 1), (2, 1), (3, 1)),
    "O": ((1, 0), (2, 0), (1, 1), (2, 1)),
    "T": ((1, 0), (0, 1), (1, 1), (2, 1)),
    "S": ((1, 0), (2, 0), (0, 1), (1, 1)),
    "Z": ((0, 0), (1, 0), (1, 1), (2, 1)),
    "L": ((0, 0), (0, 1), (1, 1), (2, 1)),
    "J": ((2, 0), (0, 1), (1, 1), (2, 1)),
}

FONT_5X7 = {
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "10001", "11110", "10001", "10001", "11110"),
    "C": ("01111", "10000", "10000", "10000", "10000", "10000", "01111"),
    "D": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "F": ("11111", "10000", "10000", "11110", "10000", "10000", "10000"),
    "G": ("01110", "10001", "10000", "10111", "10001", "10001", "01110"),
    "H": ("10001", "10001", "10001", "11111", "10001", "10001", "10001"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "J": ("00111", "00010", "00010", "00010", "10010", "10010", "01100"),
    "K": ("10001", "10010", "10100", "11000", "10100", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "Q": ("01110", "10001", "10001", "10001", "10101", "10010", "01101"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "10001", "10001", "01110"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "10101", "01010"),
    "X": ("10001", "10001", "01010", "00100", "01010", "10001", "10001"),
    "Y": ("10001", "10001", "01010", "00100", "00100", "00100", "00100"),
    "Z": ("11111", "00001", "00010", "00100", "01000", "10000", "11111"),
    "0": ("01110", "10001", "10011", "10101", "11001", "10001", "01110"),
    "1": ("00100", "01100", "00100", "00100", "00100", "00100", "01110"),
    "2": ("01110", "10001", "00001", "00010", "00100", "01000", "11111"),
    "3": ("11110", "00001", "00001", "01110", "00001", "00001", "11110"),
    "4": ("00010", "00110", "01010", "10010", "11111", "00010", "00010"),
    "5": ("11111", "10000", "10000", "11110", "00001", "00001", "11110"),
    "6": ("01110", "10000", "10000", "11110", "10001", "10001", "01110"),
    "7": ("11111", "00001", "00010", "00100", "01000", "01000", "01000"),
    "8": ("01110", "10001", "10001", "01110", "10001", "10001", "01110"),
    "9": ("01110", "10001", "10001", "01111", "00001", "00001", "01110"),
    ":": ("00000", "00100", "00100", "00000", "00100", "00100", "00000"),
    ".": ("00000", "00000", "00000", "00000", "00000", "00110", "00110"),
    "/": ("00001", "00010", "00010", "00100", "01000", "01000", "10000"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    "+": ("00000", "00100", "00100", "11111", "00100", "00100", "00000"),
    "!": ("00100", "00100", "00100", "00100", "00100", "00000", "00100"),
    "?": ("01110", "10001", "00001", "00010", "00100", "00000", "00100"),
    "<": ("00010", "00100", "01000", "10000", "01000", "00100", "00010"),
    ">": ("01000", "00100", "00010", "00001", "00010", "00100", "01000"),
    " ": ("00000", "00000", "00000", "00000", "00000", "00000", "00000"),
}


def new_scene():
    return Sprite(W, H, palette=PALETTE)


def text_width(value, scale=1, spacing=1):
    if not value:
        return 0
    return (len(value) * 5 + (len(value) - 1) * spacing) * scale


def draw_text(s, x, y, value, color, scale=1, spacing=1, shadow=None):
    value = value.upper()
    if shadow is not None:
        draw_text(s, x + scale, y + scale, value, shadow, scale, spacing, None)
    cursor = x
    for ch in value:
        rows = FONT_5X7.get(ch, FONT_5X7["?"])
        for row_i, row in enumerate(rows):
            for col_i, bit in enumerate(row):
                if bit == "1":
                    px = cursor + col_i * scale
                    py = y + row_i * scale
                    if scale == 1:
                        s.px(px, py, color)
                    else:
                        s.rect(px, py, px + scale - 1, py + scale - 1, color)
        cursor += (5 + spacing) * scale


def draw_center_text(s, cx, y, value, color, scale=1, spacing=1, shadow=None):
    x = cx - text_width(value, scale, spacing) // 2
    draw_text(s, x, y, value, color, scale, spacing, shadow)


def draw_block(s, x, y, size, kind, ghost=False):
    color, light, dark = TYPE[kind]
    if ghost:
        edge = 2 if size >= 12 else 1
        x1 = x + size
        y1 = y + size
        s.rect(x + 1, y + 1, x1 - 1, y + 1 + edge - 1, light)
        s.rect(x + 1, y1 - edge, x1 - 1, y1 - 1, light)
        s.rect(x + 1, y + 1 + edge, x + edge, y1 - edge - 1, light)
        s.rect(x1 - edge, y + 1 + edge, x1 - 1, y1 - edge - 1, light)
        s.px(x + 1, y + 1, BLACK)
        s.px(x1 - 1, y + 1, BLACK)
        s.px(x + 1, y1 - 1, BLACK)
        s.px(x1 - 1, y1 - 1, BLACK)
        return

    x1 = x + size
    y1 = y + size
    s.rect(x + 1, y + 1, x1 - 1, y1 - 1, color)
    s.rect(x + 1, y + 1, x1 - 2, y + 2, light)
    s.rect(x + 1, y + 1, x + 2, y1 - 2, light)
    s.rect(x1 - 2, y + 3, x1 - 1, y1 - 1, dark)
    s.rect(x + 3, y1 - 2, x1 - 2, y1 - 1, dark)
    if size >= 8:
        glint = max(1, size // 5)
        s.rect(x + 3, y + 3, x + 2 + glint, y + 3, light)
        s.rect(x + 3, y + 4, x + 3, y + 3 + glint, light)


def draw_piece(s, bx, by, cell, kind, col, row, ghost=False):
    for dc, dr in FEEDBACK[kind]:
        draw_block(s, bx + (col + dc) * cell, by + (row + dr) * cell, cell, kind, ghost)


def draw_mini_piece(s, x, y, cell, kind):
    shape = FEEDBACK[kind]
    min_c = min(c for c, _ in shape)
    max_c = max(c for c, _ in shape)
    min_r = min(r for _, r in shape)
    max_r = max(r for _, r in shape)
    width = (max_c - min_c + 1) * cell
    height = (max_r - min_r + 1) * cell
    ox = x - width // 2
    oy = y - height // 2
    for c, r in shape:
        draw_block(s, ox + (c - min_c) * cell, oy + (r - min_r) * cell, cell, kind)


def draw_badge(s, x, y, label, accent, soft):
    s.rect(x, y, x + 27, y + 23, accent)
    s.rect(x + 2, y + 2, x + 25, y + 21, P1_SLOT if accent == P1_ACCENT else P2_SLOT)
    draw_text(s, x + 6, y + 7, label, soft, scale=2, spacing=0, shadow=BLACK)


def draw_score(s, x, y, score, accent):
    draw_text(s, x, y, "SCORE", WHITE, scale=1, spacing=1)
    draw_text(s, x, y + 10, f"{score:07d}", accent, scale=1, spacing=0)


def draw_level_bars(s, x, y, level, accent):
    draw_text(s, x, y, "LEVEL", WHITE, scale=1, spacing=1)
    for i in range(8):
        bx = x + i * 8
        if i <= level:
            color = accent if i < level else WHITE
            s.rect(bx, y + 10, bx + 5, y + 20, color)
        else:
            s.rect(bx, y + 10, bx + 5, y + 20, PANEL)
    draw_text(s, x + 68, y + 10, f"L{level}", accent, scale=1, spacing=0)


def draw_slot(s, x, y, label, kind, accent, slot_bg):
    draw_text(s, x, y, label, WHITE, scale=1, spacing=1)
    s.rect(x, y + 10, x + 39, y + 49, slot_bg)
    s.rect(x, y + 10, x + 39, y + 11, accent)
    draw_mini_piece(s, x + 20, y + 30, 7, kind)


def draw_shared_stats(s, score, lines, combo, time_text):
    draw_text(s, 64, 5, "SCORE", WHITE, scale=1, spacing=1)
    draw_text(s, 64, 17, f"{score:07d}", P1_SOFT, scale=1, spacing=0)

    draw_text(s, 116, 5, "LINES", WHITE, scale=1, spacing=1)
    draw_text(s, 116, 17, f"{lines:03d}", P1_SOFT, scale=1, spacing=0)

    draw_text(s, 160, 5, "COMBO", WHITE, scale=1, spacing=1)
    draw_text(s, 160, 17, f"x{combo}", P1_SOFT if combo > 1 else PANEL, scale=1, spacing=0)

    draw_text(s, 210, 5, "TIME", WHITE, scale=1, spacing=1)
    draw_text(s, 210, 17, time_text, P1_SOFT, scale=1, spacing=0)


def draw_side_hud(s, x, next_kind, hold_kind, accent, slot_bg):
    draw_slot(s, x, 54, "NEXT", next_kind, accent, slot_bg)
    draw_slot(s, x, 128, "HOLD", hold_kind, accent, slot_bg)


def draw_level_bar(s, x, y, level, accent, soft):
    draw_text(s, x, y, "LEVEL", WHITE, scale=2, spacing=0, shadow=BLACK)
    draw_text(s, x + 84, y + 1, f"{level:02d}", accent, scale=2, spacing=0, shadow=BLACK)

    bar_x = x + 8
    bar_y = y + 30
    bar_w = 32
    bar_h = 106
    s.rect(bar_x - 2, bar_y - 2, bar_x + bar_w + 1, bar_y + bar_h + 1, accent)
    s.rect(bar_x, bar_y, bar_x + bar_w - 1, bar_y + bar_h - 1, BLACK)

    for i in range(8):
        sy = bar_y + 3 + (7 - i) * 13
        color = accent if i <= level else PANEL
        s.rect(bar_x + 3, sy, bar_x + bar_w - 4, sy + 9, color)
        if i <= level:
            s.rect(bar_x + 3, sy, bar_x + bar_w - 5, sy + 1, soft)

    if level >= 7:
        draw_text(s, x + 50, bar_y + 2, "MAX", soft, scale=2, spacing=1, shadow=BLACK)
        draw_text(s, x + 50, bar_y + 24, "LEVEL", WHITE, scale=1, spacing=1)
    else:
        draw_text(s, x + 50, bar_y + 2, "NEXT", WHITE, scale=1, spacing=1)
        draw_text(s, x + 50, bar_y + 16, f"L{level + 1}", soft, scale=2, spacing=0, shadow=BLACK)


def draw_shared_board_frame(s, x, y, w, h, danger=False):
    border = RED if danger else PANEL
    s.rect(x - 1, y - 1, x + w, y + h, border)
    s.rect(x, y, x + w - 1, y + h - 1, FIELD)
    s.rect(x - 4, y, x - 2, y + h - 1, P1_ACCENT)
    s.rect(x + w + 1, y, x + w + 3, y + h - 1, P2_ACCENT)
    if danger:
        s.rect(x, y - 4, x + w - 1, y - 2, RED)
        for tx in range(x + 4, x + w - 4, 12):
            s.rect(tx, y - 3, tx + 5, y - 3, ORANGE)


def draw_ui_scene():
    s = new_scene()
    s.rect(0, 0, W - 1, H - 1, BLACK)

    # One shared 24x20 playfield. P1 and P2 only own their active pieces,
    # next/hold slots and input routes.
    draw_shared_board_frame(s, 160, 40, 384, 320, danger=True)
    s.rect(32, 34, 607, 35, PANEL)

    draw_badge(s, 32, 6, "P1", P1_ACCENT, P1_SOFT)
    draw_badge(s, 580, 6, "P2", P2_ACCENT, P2_SOFT)
    draw_shared_stats(s, 1200, 42, 3, "01:23")

    # Danger belongs to the shared stack, so both rails and the top band
    # communicate the same state.
    s.rect(448, 6, 543, 29, RED)
    s.rect(450, 8, 541, 27, P2_SLOT)
    draw_text(s, 459, 14, "DANGER", WHITE, scale=1, spacing=1, shadow=BLACK)
    s.rect(450, 28, 465, 28, ORANGE)

    kinds = ("I", "O", "T", "S", "Z", "L", "J")
    p1_stack = {
        1: {0: "J"},
        2: {0: "J"},
        3: {0: "L", 1: "S"},
        4: {0: "T", 1: "S"},
        5: {0: "O", 1: "Z", 2: "I"},
        6: {0: "L", 1: "Z", 2: "I", 3: "T"},
        7: {0: "J", 1: "O", 3: "S", 4: "Z"},
        8: {0: "S", 1: "L", 2: "O", 4: "I", 5: "T"},
        9: {0: "T", 1: "S", 2: "J", 3: "L", 5: "O", 6: "Z"},
        10: {0: "O", 1: "I", 2: "T", 3: "S", 4: "J", 6: "L"},
        11: {0: "L", 1: "T", 2: "S", 3: "J", 4: "O", 5: "I", 6: "Z"},
        12: {0: "J", 1: "L", 2: "O", 3: "T", 4: "S", 5: "I", 6: "Z", 7: "L"},
        13: {0: "S", 1: "J", 2: "L", 3: "O", 4: "T", 5: "I", 6: "Z", 7: "O"},
        14: {0: "Z", 1: "S", 2: "J", 3: "L", 4: "O", 5: "T", 6: "I", 7: "S", 8: "L"},
        15: {0: "I", 1: "Z", 2: "S", 3: "J", 4: "L", 5: "O", 6: "T", 7: "J", 8: "S"},
        16: {0: "T", 1: "I", 2: "Z", 3: "S", 4: "J", 5: "L", 6: "O", 7: "Z", 8: "I"},
        17: {0: "L", 1: "T", 2: "I", 3: "Z", 4: "S", 5: "J", 6: "L", 7: "O", 8: "T"},
        18: {0: "O", 1: "L", 2: "T", 3: "I", 4: "Z", 5: "S", 6: "J", 7: "L", 8: "Z"},
        19: {0: "J", 1: "O", 2: "L", 3: "T", 4: "I", 5: "Z", 6: "S", 7: "J", 8: "L"},
    }
    p2_stack = {
        3: {9: "S"},
        4: {8: "Z", 9: "S"},
        5: {8: "T", 9: "S"},
        6: {7: "L", 8: "T", 9: "I"},
        7: {7: "O", 8: "L", 9: "T"},
        8: {5: "J", 6: "Z", 7: "O", 8: "S", 9: "T"},
        9: {4: "S", 5: "J", 6: "Z", 7: "O", 8: "L", 9: "I"},
        10: {2: "T", 3: "L", 4: "S", 5: "J", 6: "Z", 7: "O", 8: "I", 9: "S"},
        11: {1: "J", 2: "T", 3: "L", 4: "S", 5: "J", 6: "Z", 7: "O", 8: "T", 9: "L"},
        12: {0: "Z", 1: "J", 2: "T", 3: "L", 4: "S", 5: "J", 6: "Z", 7: "O", 8: "T", 9: "L"},
        13: {0: "I", 1: "Z", 2: "J", 3: "T", 4: "L", 5: "S", 6: "J", 7: "Z", 8: "O", 9: "T"},
        14: {0: "O", 1: "I", 2: "Z", 3: "J", 4: "T", 5: "L", 6: "S", 7: "J", 8: "Z", 9: "O"},
        15: {0: "S", 1: "O", 2: "I", 3: "Z", 4: "J", 5: "T", 6: "L", 7: "S", 8: "J", 9: "Z"},
        16: {0: "T", 1: "S", 2: "O", 3: "I", 4: "Z", 5: "J", 6: "T", 7: "L", 8: "S", 9: "J"},
        17: {0: "L", 1: "T", 2: "S", 3: "O", 4: "I", 5: "Z", 6: "J", 7: "T", 8: "L", 9: "S"},
        18: {0: "J", 1: "L", 2: "T", 3: "S", 4: "O", 5: "I", 6: "Z", 7: "J", 8: "T", 9: "S"},
        19: {0: "Z", 1: "J", 2: "L", 3: "T", 4: "S", 5: "O", 6: "I", 7: "Z", 8: "J", 9: "L"},
    }

    for row, cells in p1_stack.items():
        for col, kind in cells.items():
            draw_block(s, 160 + col * 16, 40 + row * 16, 16, kind)
    for row, cells in p2_stack.items():
        for col, kind in cells.items():
            draw_block(s, 160 + (14 + col) * 16, 40 + row * 16, 16, kind)

    # Active pieces and their ghost positions.
    draw_piece(s, 160, 40, 16, "T", 8, 1)
    draw_piece(s, 160, 40, 16, "T", 8, 11, ghost=True)
    draw_piece(s, 160, 40, 16, "J", 16, 2)
    draw_piece(s, 160, 40, 16, "J", 16, 12, ghost=True)

    draw_side_hud(s, 32, "T", "O", P1_ACCENT, P1_SLOT)
    draw_side_hud(s, 560, "J", "I", P2_ACCENT, P2_SLOT)
    draw_level_bar(s, 32, 186, 7, P1_ACCENT, P1_SOFT)

    return s


def draw_panel(s, x, y, w, h, accent, title, subtitle):
    s.rect(x, y, x + w - 1, y + h - 1, PANEL)
    s.rect(x + 1, y + 1, x + w - 2, y + h - 2, BLACK)
    s.rect(x + 1, y + 1, x + w - 2, y + 2, accent)
    draw_text(s, x + 6, y + 7, title, WHITE, scale=1, spacing=1)
    draw_text(s, x + 6, y + 18, subtitle, accent, scale=1, spacing=0)


def draw_mini_board(s, x, y, cell, rows, active=None, ghost=None, clear=None):
    s.rect(x - 1, y - 1, x + 10 * cell, y + 20 * cell, PANEL)
    s.rect(x, y, x + 10 * cell - 1, y + 20 * cell - 1, FIELD)
    for row, cells in rows.items():
        for col, kind in cells.items():
            if clear is not None and row == clear:
                continue
            draw_block(s, x + col * cell, y + row * cell, cell, kind)
    if active:
        kind, col, row = active
        draw_piece(s, x, y, cell, kind, col, row)
    if ghost:
        kind, col, row = ghost
        draw_piece(s, x, y, cell, kind, col, row, ghost=True)


def make_stack():
    rows = {}
    for row in range(15, 20):
        rows[row] = {}
        for col in range(10):
            rows[row][col] = ("I", "O", "T", "S", "Z", "L", "J")[(row + col) % 7]
    rows[19] = {col: "I" for col in range(10)}
    return rows


def draw_line_clear_storyboard():
    s = new_scene()
    s.rect(0, 0, W - 1, H - 1, BLACK)
    draw_text(s, 16, 9, "LINE CLEAR / 8 STAGE PIXEL PIPELINE", WHITE, scale=1, spacing=1)
    draw_text(s, 446, 9, "MAX 300MS", P1_ACCENT, scale=1, spacing=1)
    s.rect(16, 22, 624, 23, PANEL)

    stages = (
        ("01 CONTACT", "T+0MS", "LOCK WRITE", WHITE),
        ("02 FLASH", "T+16MS", "FULL ROW", WHITE),
        ("03 SCAN", "T+48MS", "LEFT > RIGHT", P1_ACCENT),
        ("04 COLLAPSE", "T+96MS", "EDGE IN", ORANGE),
        ("05 FALL", "T+144MS", "STACK DROP", P1_ACCENT),
        ("06 SETTLE", "T+192MS", "LOCAL PULSE", P1_SOFT),
        ("07 SCORE", "T+240MS", "SCORE FLASH", YELLOW),
        ("08 READY", "T+300MS", "NEXT PIECE", WHITE),
    )

    for i, (title, timing, note, accent) in enumerate(stages):
        col = i % 4
        row = i // 4
        x = 16 + col * 154
        y = 34 + row * 160
        draw_panel(s, x, y, 148, 148, accent, title, timing)

        board_x = x + 12
        board_y = y + 34
        rows = make_stack()
        if i == 0:
            draw_mini_board(s, board_x, board_y, 4, rows, active=("T", 4, 11))
            s.rect(board_x, board_y + 19 * 4, board_x + 39, board_y + 79, WHITE)
        elif i == 1:
            draw_mini_board(s, board_x, board_y, 4, rows)
            s.rect(board_x, board_y + 19 * 4, board_x + 39, board_y + 79, WHITE)
        elif i == 2:
            draw_mini_board(s, board_x, board_y, 4, rows)
            for col_i in range(6):
                s.rect(board_x + col_i * 7, board_y + 19 * 4, board_x + col_i * 7 + 6, board_y + 79, WHITE)
            for col_i in range(6, 10):
                s.rect(board_x + col_i * 4, board_y + 19 * 4, board_x + col_i * 4 + 3, board_y + 79, P1_ACCENT)
        elif i == 3:
            draw_mini_board(s, board_x, board_y, 4, rows)
            for col_i in range(10):
                inset = 2 if col_i in (0, 9) else (1 if col_i in (1, 8) else 0)
                s.rect(
                    board_x + col_i * 4 + inset,
                    board_y + 19 * 4 + inset,
                    board_x + col_i * 4 + 3 - inset,
                    board_y + 79 - inset,
                    ORANGE,
                )
        elif i == 4:
            shifted = {r - 1: cells for r, cells in rows.items() if r != 19}
            draw_mini_board(s, board_x, board_y, 4, shifted)
            for col_i in range(10):
                s.rect(board_x + col_i * 4, board_y + 72, board_x + col_i * 4 + 1, board_y + 78, P1_ACCENT)
        elif i == 5:
            shifted = {r - 1: cells for r, cells in rows.items() if r != 19}
            draw_mini_board(s, board_x, board_y, 4, shifted)
            s.rect(board_x, board_y + 18 * 4, board_x + 39, board_y + 18 * 4, P1_SOFT)
            s.rect(board_x - 1, board_y + 17 * 4, board_x - 1, board_y + 79, P1_SOFT)
        elif i == 6:
            shifted = {r - 1: cells for r, cells in rows.items() if r != 19}
            draw_mini_board(s, board_x, board_y, 4, shifted)
            draw_text(s, x + 61, y + 60, "+120", YELLOW, scale=2, spacing=1)
            draw_text(s, x + 61, y + 82, "LEVEL x1", WHITE, scale=1, spacing=0)
        else:
            shifted = {r - 1: cells for r, cells in rows.items() if r != 19}
            draw_mini_board(s, board_x, board_y, 4, shifted)
            draw_piece(s, board_x, board_y, 4, "L", 3, 0)

        draw_text(s, x + 61, y + 111, note, WHITE, scale=1, spacing=0)

    return s


def level_hud(s, x, y, level, scan=False):
    draw_text(s, x, y, "LEVEL", WHITE, scale=1, spacing=1)
    for i in range(8):
        bx = x + i * 6
        color = (P1_ACCENT if i < level else PANEL)
        s.rect(bx, y + 10, bx + 4, y + 32, color)
    if scan:
        s.rect(x - 2, y + 13, x + 45, y + 14, WHITE)
        s.rect(x - 2, y + 17, x + 45, y + 18, P1_SOFT)


def draw_feedback_board():
    s = new_scene()
    s.rect(0, 0, W - 1, H - 1, BLACK)
    draw_text(s, 16, 9, "FEEDBACK MAP / WORLD FX NEVER SHAKE THE HUD", WHITE, scale=1, spacing=1)
    draw_text(s, 481, 9, "60 HZ SAFE", P2_ACCENT, scale=1, spacing=1)
    s.rect(16, 22, 624, 23, PANEL)

    titles = (
        ("01 MOVE BUFFER", "<50MS", P1_ACCENT),
        ("02 HARD DROP", "2 FRAMES", YELLOW),
        ("03 LOCK", "80MS LOCAL", ORANGE),
        ("04 LEVEL UP", "120MS HUD", P1_ACCENT),
        ("05 DANGER", "1.2S BREATH", RED),
        ("06 GAME OVER", "CAUSE + RESTART", P2_ACCENT),
    )

    for i, (title, timing, accent) in enumerate(titles):
        col = i % 3
        row = i // 3
        x = 16 + col * 206
        y = 34 + row * 160
        draw_panel(s, x, y, 200, 148, accent, title, timing)

        board_x = x + 10
        board_y = y + 36
        rows = make_stack()
        if i == 0:
            draw_mini_board(s, board_x, board_y, 5, rows, active=("T", 3, 8), ghost=("T", 5, 8))
            draw_text(s, x + 14, y + 70, "<", P1_ACCENT, scale=2, spacing=0)
            s.rect(x + 28, y + 80, x + 44, y + 81, P1_SOFT)
            draw_text(s, x + 72, y + 45, "1 STEP", WHITE, scale=1, spacing=0)
            draw_text(s, x + 72, y + 58, "NO DROP", P1_ACCENT, scale=1, spacing=0)
        elif i == 1:
            draw_mini_board(s, board_x, board_y, 5, rows, active=("I", 3, 7))
            s.rect(board_x + 3 * 5, board_y + 2 * 5, board_x + 3 * 5 + 1, board_y + 7 * 5, YELLOW)
            s.rect(board_x + 4 * 5, board_y + 2 * 5, board_x + 4 * 5 + 1, board_y + 7 * 5, YELLOW)
            s.rect(board_x, board_y + 16 * 5, board_x + 49, board_y + 16 * 5, WHITE)
            draw_text(s, x + 72, y + 46, "TRAIL 2F", WHITE, scale=1, spacing=0)
            draw_text(s, x + 72, y + 60, "IMPACT", YELLOW, scale=1, spacing=0)
        elif i == 2:
            draw_mini_board(s, board_x, board_y, 5, rows, active=("J", 3, 12))
            s.rect(board_x - 2, board_y + 16 * 5, board_x - 2, board_y + 79, ORANGE)
            s.rect(board_x + 50, board_y + 16 * 5, board_x + 50, board_y + 79, ORANGE)
            draw_text(s, x + 72, y + 46, "EDGE", WHITE, scale=1, spacing=0)
            draw_text(s, x + 72, y + 60, "ONLY", ORANGE, scale=1, spacing=0)
        elif i == 3:
            s.rect(board_x - 1, board_y - 1, board_x + 50, board_y + 79, PANEL)
            s.rect(board_x, board_y, board_x + 49, board_y + 78, FIELD)
            level_hud(s, x + 72, y + 39, 5, scan=True)
            draw_text(s, x + 72, y + 86, "L5 > L6", WHITE, scale=1, spacing=0)
            draw_text(s, x + 72, y + 100, "HUD SCAN", P1_ACCENT, scale=1, spacing=0)
        elif i == 4:
            danger_rows = {
                0: {2: "S", 4: "T", 7: "L"},
                1: {1: "I", 2: "S", 3: "J", 4: "T", 5: "O", 6: "Z", 7: "L", 8: "S"},
                2: {0: "L", 1: "I", 2: "S", 3: "J", 4: "T", 5: "O", 6: "Z", 7: "L", 8: "S", 9: "I"},
                3: {0: "Z", 1: "L", 2: "I", 3: "S", 4: "J", 5: "T", 6: "O", 7: "Z", 8: "L", 9: "S"},
            }
            for r in range(4, 20):
                danger_rows[r] = {c: ("I", "O", "T", "S", "Z", "L", "J")[(r + c) % 7] for c in range(10)}
            draw_mini_board(s, board_x, board_y, 5, danger_rows, active=("S", 3, 0))
            s.rect(board_x - 3, board_y - 1, board_x + 52, board_y + 2, RED)
            s.rect(board_x - 3, board_y + 1, board_x + 52, board_y + 2, ORANGE)
            draw_text(s, x + 72, y + 46, "DANGER", RED, scale=1, spacing=1)
            draw_text(s, x + 72, y + 60, "ROW 0-1", LIGHT_RED, scale=1, spacing=0)
            draw_text(s, x + 72, y + 74, "NO SHAKE", WHITE, scale=1, spacing=0)
        else:
            over_rows = {
                row_i: {col_i: ("I", "O", "T", "S", "Z", "L", "J")[(row_i + col_i) % 7] for col_i in range(10)}
                for row_i in range(10, 20)
            }
            draw_mini_board(s, board_x, board_y, 5, over_rows)
            s.rect(board_x, board_y, board_x + 49, board_y + 78, BLACK)
            s.rect(board_x, board_y + 79, board_x + 49, board_y + 79, P2_ACCENT)
            draw_center_text(s, x + 25, y + 45, "GAME", WHITE, scale=2, spacing=0)
            draw_center_text(s, x + 25, y + 64, "OVER", P2_ACCENT, scale=2, spacing=0)
            draw_text(s, x + 72, y + 89, "TOP OUT", LIGHT_PINK, scale=1, spacing=0)
            draw_text(s, x + 72, y + 103, "RESTART", WHITE, scale=1, spacing=0)

    return s


def export():
    scenes = (
        ("01_ui_layout", draw_ui_scene()),
        ("02_line_clear_storyboard", draw_line_clear_storyboard()),
        ("03_feedback_storyboard", draw_feedback_board()),
    )

    for name, scene in scenes:
        scene.save_png(OUT / f"{name}_640x360_master.png", scale=1)
        scene.save_png(OUT / f"{name}_1280x720.png", scale=2)
        scene.stats(print_=True)

    first = scenes[0][1]
    first.save_swatch(OUT / "00_palette_swatch.png", cell=20)


if __name__ == "__main__":
    export()
