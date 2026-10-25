"""从仓库内单一字形/文本描述生成共享 ROM，不依赖旧工作区或外部字体。"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    data = json.loads((ROOT / "assets/story_ui.json").read_text(encoding="utf-8"))
    chars = data["characters"]
    font = data["font_rows"]
    assert len(set(chars)) == len(chars) <= 64
    assert chars.startswith(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    assert len(font) == 1024 and all(0 <= x <= 255 for x in font)
    assert any(font) and all(x == 0 for x in font[:16])
    text = []
    header = ["// 由 tools/build_story_assets.py 生成，修改 assets/story_ui.json 后重建。"]
    names = {" ": "SPACE", "-": "DASH", ":": "COLON", "/": "SLASH",
             ".": "DOT", "!": "BANG", "?": "QUESTION"}
    for i, c in enumerate(chars):
        header.append(f"    localparam [5:0] CHAR_{names.get(c, c)} = 6'd{i};")
    for name, value in data["texts"].items():
        offset = len(text)
        if isinstance(value, list):
            assert len(value) == 2 and all(len(line) <= 26 for line in value), name
            value = "".join(line.ljust(32) for line in value)
        assert len(value) <= 127 and all(c in chars for c in value), name
        text.extend(chars.index(c) for c in value)
        header.append(f"    localparam [9:0] TXT_{name} = 10'd{offset};")
        header.append(f"    localparam [6:0] LEN_{name} = 7'd{len(value)};")
    assert len(text) <= 1024, "Text capacity exceeded"
    memory = font + text + [0] * (1024 - len(text))
    target = ROOT / "Tetris.srcs/sources_1/new"
    (target / "story_font.mem").write_text(
        "".join(f"{x:02x}\n" for x in memory), encoding="ascii", newline="\n")
    (target / "story_text_ids.vh").write_text(
        "\n".join(header) + "\n", encoding="gbk", newline="\n")
    palette = data["palette_rgb"]
    assert len(palette) == 56 and len(set(palette)) == 56
    colors = ["    function [23:0] story_palette;", "    input [5:0] index;", "    begin", "        case(index)"]
    colors += [f"        6'd{i}: story_palette=24'h{rgb};" for i, rgb in enumerate(palette)]
    colors += ["        default: story_palette=24'h000000;", "        endcase", "    end", "    endfunction"]
    (target / "story_palette.vh").write_text("\n".join(colors)+"\n", encoding="ascii", newline="\n")
    sprites = json.loads((ROOT / "assets/story_sprites.json").read_text(encoding="utf-8"))["indices"]
    assert len(sprites)==4096 and all(0<=x<=3 for x in sprites)
    (target / "story_sprites.mem").write_text("".join(f"{x:x}\n" for x in sprites),encoding="ascii",newline="\n")
    print(f"STORY_ASSETS_PASS glyphs={len(chars)} text_bytes={len(text)} rom_bytes={len(memory)}")


if __name__ == "__main__":
    main()
