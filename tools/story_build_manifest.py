"""记录构建输入；拒绝把构建期间变动后的源码与旧 bit 配对。"""
import ast
import hashlib
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RULES_FILE = "docs/AGENTS.md"



def normalized_project(content):
    project = ET.fromstring(content)
    # Vivado materializes these standard output locations after the first implementation.
    # Keep custom directory settings; exclude only the exact generated bookkeeping values.
    run=project.find("./Runs/Run[@Id='impl_1']")
    if run is not None:
        if run.get("Dir")=="$PRUNDIR/impl_1":run.attrib.pop("Dir")
        for generated in list(run.findall("GeneratedRun")):
            if generated.attrib=={"Dir":"$PRUNDIR","File":"gen_run.xml"}:run.remove(generated)
    return ET.tostring(project,encoding="utf-8")


def normalized_pc_palette(content):
    tree = ast.parse(content.decode("utf-8-sig"))
    values = [ast.literal_eval(n.value) for n in tree.body if isinstance(n, ast.Assign)
              and any(isinstance(t, ast.Name) and t.id == "DEFAULT_PAL" for t in n.targets)]
    if len(values) != 1 or set(values[0]) != set(range(56)):
        raise ValueError("Missing shared PC DEFAULT_PAL")
    return json.dumps(values[0], sort_keys=True, separators=(",", ":")).encode("ascii")


def inputs():
    if not (ROOT / RULES_FILE).is_file():
        raise SystemExit(f"Missing canonical rules file: {RULES_FILE}")
    paths = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
    ).decode("utf-8").split("\0")
    paths.append(RULES_FILE)
    result = {}
    for name in sorted(set(paths)):
        p = ROOT / name
        if not p.is_file():
            continue
        hardware = name.startswith("Tetris.srcs/") and p.suffix in {
            ".v", ".sv", ".vh", ".xdc", ".xci", ".mem", ".coe"
        }
        build = name.startswith("tools/") and p.suffix in {".tcl", ".py", ".ps1", ".bat"}
        asset = name.startswith("assets/") and p.suffix in {".json", ".wav", ".ima"}
        if hardware or build or asset or name == "pc/net_screen_view.py" or name in {"AGENTS.md", RULES_FILE, "Tetris.xpr"}:
            content = p.read_bytes()
            if name == "pc/net_screen_view.py":
                # Only this generated/shared table participates in FPGA asset consistency.
                content = normalized_pc_palette(content)
            if name == "Tetris.xpr":
                # Keep all source registration, part, strategy, constraint and clock inputs.
                content = normalized_project(content)
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
            "pc_binding": "Bind the shared DEFAULT_PAL value only; unrelated PC application code is not an FPGA build input and needs its own software verification.",
            "project_normalization": "Excluded only exact standard Vivado-generated impl_1 Dir/GeneratedRun output bookkeeping; all hooks, hardware source registration, part, strategy, constraints and custom locations remain bound.",
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
