from pathlib import Path
import sys


SKILL_SCRIPTS = Path(r"C:\Users\qiguidie\.codex\skills\pixel-art-studio\scripts")
sys.path.insert(0, str(SKILL_SCRIPTS))

from pixelstudio import Sprite  # noqa: E402
from build import (  # noqa: E402
    BLACK,
    ORANGE,
    PANEL,
    P1_ACCENT,
    P1_SOFT,
    P2_ACCENT,
    P2_SOFT,
    WHITE,
    draw_text,
)


ROOT = Path(__file__).resolve().parent
SOURCE = Path(
    r"C:\Users\qiguidie\AppData\Local\Temp"
    r"\codex-clipboard-a90e864b-cd82-4727-81ae-1b5b6a860402.png"
)
OUT = ROOT.parent / "游戏优化参考图"
OUT.mkdir(parents=True, exist_ok=True)


def draw_player_badge(s, x, y, label, accent, soft):
    s.rect(x, y, x + 104, y + 45, accent)
    s.rect(x + 3, y + 3, x + 101, y + 42, BLACK)
    draw_text(s, x + 22, y + 8, label, soft, scale=4, spacing=0, shadow=BLACK)


def draw_shared_header(s):
    # Release HUD has no packet/debug line.
    s.rect(0, 0, 1928, 119, BLACK)
    s.rect(295, 45, 450, 145, BLACK)
    s.rect(430, 45, 800, 145, BLACK)
    s.rect(1180, 45, 1640, 145, BLACK)

    draw_player_badge(s, 50, 56, "P1", P1_ACCENT, P1_SOFT)
    draw_player_badge(s, 1685, 56, "P2", P2_ACCENT, P2_SOFT)

    draw_text(s, 520, 52, "TIME", WHITE, scale=2, spacing=1, shadow=BLACK)
    draw_text(s, 520, 79, "00:02", WHITE, scale=7, spacing=0, shadow=BLACK)

    draw_text(s, 1250, 52, "SCORE", WHITE, scale=2, spacing=1, shadow=BLACK)
    draw_text(s, 1250, 79, "0000000", WHITE, scale=7, spacing=0, shadow=BLACK)


def draw_level_bar(s, level=0, max_level=7):
    # Remove the old LV0 label and the narrow in-board level rail.
    s.rect(395, 50, 476, 1115, BLACK)
    s.rect(30, 738, 390, 1115, BLACK)

    draw_text(s, 50, 738, "LEVEL", WHITE, scale=4, spacing=0, shadow=BLACK)
    draw_text(s, 210, 744, f"{level:02d}", P1_ACCENT, scale=3, spacing=0, shadow=BLACK)

    bar_x = 74
    bar_y = 808
    bar_w = 94
    seg_h = 20
    gap = 3
    s.rect(bar_x - 4, bar_y - 4, bar_x + bar_w + 3, bar_y + 8 * seg_h + 7 * gap + 3, P1_ACCENT)
    s.rect(bar_x, bar_y, bar_x + bar_w - 1, bar_y + 8 * seg_h + 7 * gap - 1, BLACK)

    for i in range(8):
        sy = bar_y + (7 - i) * (seg_h + gap)
        color = P1_ACCENT if i <= level else PANEL
        s.rect(bar_x + 5, sy, bar_x + bar_w - 6, sy + seg_h - 1, color)
        if i <= level:
            s.rect(bar_x + 5, sy, bar_x + bar_w - 7, sy + 2, P1_SOFT)

    stage = min(level + 1, 8)
    draw_text(s, 210, 826, "STAGE", WHITE, scale=2, spacing=1)
    draw_text(s, 210, 858, f"{stage:02d}/08", P1_SOFT, scale=3, spacing=0, shadow=BLACK)

    if level >= max_level:
        draw_text(s, 210, 910, "MAX", P1_SOFT, scale=3, spacing=1, shadow=BLACK)
        draw_text(s, 210, 948, "LEVEL", WHITE, scale=2, spacing=1)
    else:
        draw_text(s, 210, 910, "NEXT", WHITE, scale=2, spacing=1)
        draw_text(s, 210, 940, f"L{level + 1}", P1_SOFT, scale=3, spacing=0, shadow=BLACK)

def draw_leaderboard_divider(s):
    s.rect(1930, 0, 1933, 1115, PANEL)
    s.rect(1934, 0, 1934, 1115, BLACK)


def export():
    s = Sprite.from_png(SOURCE, scale=1)
    draw_shared_header(s)
    draw_level_bar(s, level=0)
    draw_leaderboard_divider(s)

    s.save_png(OUT / "04_current_ui_optimized.png", scale=1)
    s.stats(print_=True)


if __name__ == "__main__":
    export()
