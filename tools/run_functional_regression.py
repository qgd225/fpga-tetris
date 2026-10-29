"""Run logic regression; display, feel and listening acceptance belong to the user."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
GROUPS = "duo frame_duo level sound input_route net_keyboard horizontal_repeat hold_gesture solo_hint rgb_palette lutram optimization story game_modes rhythm".split()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="temporary/sim/functional_logs")
    parser.add_argument("--groups", default=",".join(GROUPS))
    args = parser.parse_args()
    output = (ROOT / args.output).resolve()
    if not output.is_relative_to((ROOT / "temporary").resolve()):
        raise SystemExit("Regression output must stay under temporary/")
    output.mkdir(parents=True, exist_ok=True)
    groups = args.groups.split(",")
    if any(g not in GROUPS for g in groups):
        raise SystemExit("Unknown functional group")
    inputs = {}
    for base in (ROOT / "Tetris.sim", ROOT / "temporary/sim"):
        for p in base.rglob("*"):
            if p.is_file() and p.suffix in {".v", ".sv", ".bat", ".ps1", ".py", ".vh"} and not any(part in {"build", "build_music", "xsim.dir", "__pycache__", "logs", "functional_logs"} for part in p.relative_to(base).parts):
                inputs[p.relative_to(ROOT).as_posix()] = hashlib.sha256(p.read_bytes()).hexdigest()
    hardware_inputs = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/"Tetris.srcs").rglob("*") if p.is_file() and p.suffix in {".v",".sv",".vh",".mem",".xci",".xdc"}}
    results = []
    for group in groups:
        entry = ROOT / "temporary/sim" / group / "run.bat"
        log = output / (group + ".log")
        if not entry.is_file():
            result = {"group": group, "pass": False, "error": "Missing local runner"}
        else:
            with log.open("wb") as stream:
                process = subprocess.run(["cmd.exe", "/d", "/c", "call", str(entry)], cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, check=False)
            content = log.read_text(errors="replace")
            markers = [line for line in content.splitlines() if "ALL PASS" in line]
            passed = process.returncode == 0 and bool(markers) and not re.search(r"FAILED|ERROR:|XVLOG_FAIL|XELAB_FAIL|^FAIL ", content, re.M)
            result = {"group": group, "pass": passed, "exit_code": process.returncode, "log": log.relative_to(ROOT).as_posix(), "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest(), "markers": markers}
        results.append(result)
        print(("PASS " if result["pass"] else "FAIL ") + group, flush=True)
    drift = [name for name, digest in inputs.items() if not (ROOT/name).is_file() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest() != digest]
    hardware_drift = [n for n,d in hardware_inputs.items() if not (ROOT/n).is_file() or hashlib.sha256((ROOT/n).read_bytes()).hexdigest()!=d]
    passed = all(x["pass"] for x in results) and not drift and not hardware_drift
    summary = {"pass": passed, "groups": len(groups), "results": results, "test_inputs": inputs, "changed_during_run": drift, "hardware_inputs":hardware_inputs,"hardware_changed_during_run":hardware_drift, "delegated_to_user": ["RTL previews and actual display", "game feel and supply balance", "PC live reception", "HDMI display and listening"]}
    (output/"summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(("ALL PASS" if passed else "FAILED") + " FUNCTIONAL_REGRESSION groups=" + str(len(groups)))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
