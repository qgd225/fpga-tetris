"""重新构建候选便携 EXE；产物直接放 temporary，不自动替换正在使用的成品。"""
from pathlib import Path
import datetime
import hashlib
import json
import subprocess
import sys


def main():
    import numpy  # 成品必须包含加速后端，禁止意外打包为慢速回退版。
    pc = Path(__file__).resolve().parent
    task = pc.parent / "temporary" / ("pc_package_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S"))
    task.mkdir(parents=True)
    inputs = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in pc.iterdir() if p.suffix in {".py", ".spec", ".txt", ".bat"}}
    with (task / "package.log").open("w", encoding="utf-8") as log:
        result = subprocess.run([sys.executable, "-m", "PyInstaller", "--clean", "--noconfirm", "--distpath", str(task / "dist"),
                                 "--workpath", str(task / "build"), str(pc / "TetrisPC.spec")], cwd=task, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print("构建失败，日志：" + str(task / "package.log"))
        return result.returncode
    current = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in pc.iterdir() if p.suffix in {".py", ".spec", ".txt", ".bat"}}
    if current != inputs:
        print("构建期间源码发生变化，候选不能发布。")
        return 1
    exe = task / "dist/TetrisPC.exe"
    (task / "package-inputs.json").write_text(json.dumps({"source_inputs": inputs, "exe_sha256": hashlib.sha256(exe.read_bytes()).hexdigest(),
                                                        "platform": sys.platform, "python": sys.version}, ensure_ascii=False, indent=2), encoding="utf-8")
    print("候选程序：" + str(exe))
    print("请通过自测与图形依赖检查后再替换正式程序。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
