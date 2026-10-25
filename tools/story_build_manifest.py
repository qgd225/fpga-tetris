"""记录构建输入；拒绝把构建期间变动后的源码与旧 bit 配对。"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def inputs():
    paths = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
    ).decode("utf-8").split("\0")
    result = {}
    for name in sorted(set(paths)):
        p = ROOT / name
        if not p.is_file():
            continue
        hardware = name.startswith(("Tetris.srcs/", "third_party/")) and p.suffix in {
            ".v", ".sv", ".vh", ".xdc", ".xci", ".mem", ".coe"
        }
        build = name.startswith("tools/") and p.suffix in {".tcl", ".py"}
        asset = name.startswith("assets/") and p.suffix == ".json"
        if hardware or build or asset or name == "docs/story-execution-gates.md":
            result[name] = hashlib.sha256(p.read_bytes()).hexdigest()
    return result


def main():
    mode, filename = sys.argv[1:]
    path = Path(filename)
    current = inputs()
    if mode == "write":
        path.write_text(json.dumps({
            "head": subprocess.check_output(
                ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
            ).strip(),
            "inputs": current,
        }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"BUILD_INPUTS_SAVED {len(current)}")
    elif mode == "verify":
        saved = json.loads(path.read_text(encoding="utf-8"))["inputs"]
        changed = sorted(k for k in saved.keys() | current.keys()
                         if saved.get(k) != current.get(k))
        if changed:
            raise SystemExit("BUILD_INPUTS_CHANGED " + ", ".join(changed))
        print(f"BUILD_INPUTS_MATCH {len(current)}")
    else:
        raise SystemExit("Expected write or verify")


if __name__ == "__main__":
    main()
