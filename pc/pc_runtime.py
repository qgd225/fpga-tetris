"""便携程序的用户日志与版本信息。"""
import os
from pathlib import Path
import tempfile
import traceback

VERSION = "2026.10.29.1"


def log_directory():
    base = os.environ.get("LOCALAPPDATA") or os.environ.get("TEMP") or tempfile.gettempdir()
    path = Path(base) / "TetrisPC" / "Logs"
    path.mkdir(parents=True, exist_ok=True)
    return path


def write_error(message, filename="startup_error.log"):
    detail = traceback.format_exc()
    text = message + "\n" + (detail if detail != "NoneType: None\n" else "")
    try:
        path = log_directory() / filename
        path.write_text(text, encoding="utf-8")
        return str(path)
    except OSError:
        return "日志目录不可写"


from contextlib import contextmanager


@contextmanager
def high_resolution_timer():
    """只在按键发送期间提高定时分辨率，退出后成对恢复。"""
    import ctypes
    timer = None
    try:
        candidate = ctypes.windll.winmm
        if candidate.timeBeginPeriod(1) == 0:
            timer = candidate
    except (AttributeError, OSError):
        pass
    try:
        yield
    finally:
        if timer is not None:
            timer.timeEndPeriod(1)
