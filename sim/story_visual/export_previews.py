"""将真实 RTL 的 P6 帧转为预览；固定测试棋盘，不是上板截图。"""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).resolve().parent / "build"
OUTPUT = ROOT / "docs" / "assets" / "story_ui"
OUTPUT.mkdir(parents=True, exist_ok=True)
manifest = {"kind": "rtl_fixed_test_fixture_not_hardware_capture", "frames": {}}
manifest["rtl_source_sha256"] = {
    str(p.relative_to(ROOT)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
    for p in sorted((ROOT / "Tetris.srcs/sources_1/new").glob("story_*"))
    if p.suffix in {".v", ".vh", ".mem"}
}
for name in ("core_renderer.v", "hud_text.v", "hud_font_rom.v", "scene_sprite_rom.v"):
    p = ROOT / "Tetris.srcs/sources_1/new" / name
    manifest["rtl_source_sha256"][str(p.relative_to(ROOT)).replace("\\", "/")] = hashlib.sha256(p.read_bytes()).hexdigest()
for ppm in sorted([*SOURCE.glob("scene_duo*_phase*_state*.ppm"), SOURCE / "comms_opening.ppm"]):
    with Image.open(ppm) as frame:
        assert frame.size == (1280, 720)
        target = OUTPUT / (ppm.stem + ".png")
        frame.save(target)
        if "state0" in ppm.stem:
            frame.convert("L").save(OUTPUT / (ppm.stem + "_gray.png"))
    manifest["frames"][target.name] = {"ppm_sha256": hashlib.sha256(ppm.read_bytes()).hexdigest(),
                                        "png_sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
assert len(manifest["frames"]) == 13
sheet = Image.new("RGB", (2560, 1440))
for phase in range(4):
    with Image.open(OUTPUT / f"scene_duo1_phase{phase}_state0.png") as frame:
        sheet.paste(frame, (1280 * (phase % 2), 720 * (phase // 2)))
sheet.save(OUTPUT / "four_phases.png")
(OUTPUT / "preview-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(f"RTL_PREVIEWS_EXPORTED frames={len(manifest['frames'])}")
