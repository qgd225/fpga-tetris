# 运行：python -m PyInstaller --clean --noconfirm --workpath <temporary路径> --distpath <temporary路径> pc/TetrisPC.spec
from pathlib import Path
pc = Path(SPECPATH)
a = Analysis([str(pc / "tetris_pc_launcher.py")], pathex=[str(pc)], binaries=[], datas=[],
             hiddenimports=["PIL.ImageTk", "tkinter", "_tkinter", "pynput.keyboard._win32", "pynput.mouse._win32"],
             hookspath=[], hooksconfig={}, runtime_hooks=[], excludes=[], noarchive=False, optimize=0)
pyz = PYZ(a.pure)
exe = EXE(pyz, a.scripts, a.binaries, a.datas, [], name="TetrisPC", debug=False,
          bootloader_ignore_signals=False, strip=False, upx=False, console=True,
          disable_windowed_traceback=False, argv_emulation=False, target_arch=None,
          codesign_identity=None, entitlements_file=None)
