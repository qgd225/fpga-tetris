"""记录构建输入；拒绝把构建期间变动后的源码与旧 bit 配对。"""
import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
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
        build = name.startswith("tools/") and p.suffix in {".tcl", ".py", ".ps1", ".bat"}
        asset = name.startswith("assets/") and p.suffix in {".json", ".wav", ".ima"}
        if hardware or build or asset or name in {"AGENTS.md", "Tetris.xpr"}:
            content = p.read_bytes()
            if name == "Tetris.xpr":
                # The candidate build disables only the publisher hook, then restores it.
                # Keep all source registration, part, strategy, constraint and clock inputs.
                project = ET.fromstring(content)
                hook = project.find("./Runs/Run[@Id='impl_1']/Strategy/Step[@Id='write_bitstream']")
                if hook is not None:
                    hook.attrib.pop("PostStepTclHook", None)
                content = ET.tostring(project, encoding="utf-8")
            result[name] = hashlib.sha256(content).hexdigest()
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
            "project_normalization": "Only impl_1/write_bitstream PostStepTclHook is excluded; it publishes files and is disabled during candidate builds.",
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
