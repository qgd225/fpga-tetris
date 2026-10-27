"""本机构建入口：详细输出写日志，控制台只显示三项结果。"""
import datetime
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def timing_text(report):
    try:
        text = report.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return "未取得"
    match = re.search(
        r"WNS\(ns\).*?\n\s*-+[^\n]*\n\s*"
        r"([-+\d.]+)\s+([-+\d.]+)\s+\d+\s+\d+\s+([-+\d.]+)\s+([-+\d.]+)",
        text, re.S,
    )
    if not match:
        return "未取得"
    wns, tns, whs, ths = match.groups()
    return f"WNS={wns} ns，WHS={whs} ns，TNS={tns} ns，THS={ths} ns"


def main():
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
    round_name = "story_local_" + stamp
    output = ROOT / "temporary/build_candidates" / round_name
    passed = False
    try:
        output.mkdir(parents=True, exist_ok=False)
        with (output / "console.log").open("w", encoding="utf-8") as log:
            try:
                # 防止与打开的工程或另一次构建同时修改标准运行目录。
                probe = subprocess.run(
                    ["powershell.exe", "-NoProfile", "-Command",
                     "if (Get-Process vivado,xsim,xelab,xvlog -ErrorAction SilentlyContinue) { exit 1 }"],
                    stdout=log, stderr=subprocess.STDOUT, check=False,
                )
                if probe.returncode:
                    raise RuntimeError("Vivado 或仿真进程仍在运行")
                vivado = os.environ.get("TETRIS_VIVADO") or shutil.which("vivado.bat")
                if not vivado:
                    vivado = "D:/xilinx/Vivado/2018.3/bin/vivado.bat"
                if not Path(vivado).is_file():
                    raise FileNotFoundError(vivado)
                if not (ROOT / "tools/run_functional_regression.py").is_file():
                    raise FileNotFoundError("tools/run_functional_regression.py")
                # exec python 使用本次入口的同一解释器。
                env = os.environ.copy()
                env["PATH"] = str(Path(sys.executable).parent) + os.pathsep + env.get("PATH", "")
                command = [vivado, "-mode", "batch", "-notrace", "-log", str(output / "vivado.log"),
                           "-journal", str(output / "vivado.jou"), "-source", str(ROOT / "tools/build_story.tcl"),
                           "-tclargs", round_name, "local"]
                result = subprocess.run(command, cwd=output, env=env, stdout=log,
                                        stderr=subprocess.STDOUT, check=False)
                log.flush()
                transcript = (output / "console.log").read_text(encoding="utf-8", errors="replace")
                passed = (result.returncode == 0
                          and f"STORY_BUILD_PASS {round_name}" in transcript
                          and (ROOT / "bit/Tetris.bit").is_file())
                if not passed:
                    raise RuntimeError(f"构建或验证未通过，退出码 {result.returncode}")
            except Exception as exc:
                log.write(f"\nLOCAL_BUILD_FAILURE: {exc}\n")
    except Exception:
        passed = False
    print("是否通过：" + ("通过" if passed else "未通过"))
    print("时序指标：" + timing_text(output / "timing.rpt"))
    print("bit 保存路径：" + (str(ROOT / "bit/Tetris.bit") if passed else "本次未保存"))
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
