from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "sim" / "_nobom"


def strip_bom(source: Path, target: Path) -> None:
    data = source.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)


for source in (ROOT / "Tetris.srcs" / "sources_1" / "new").glob("*.v"):
    strip_bom(source, OUT / source.relative_to(ROOT))

for source in (ROOT / "sim").glob("*/*.v"):
    strip_bom(source, OUT / source.relative_to(ROOT))
