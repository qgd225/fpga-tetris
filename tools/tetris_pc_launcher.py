#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Tetris PC 便携启动器：设置静态 ARP 后启动画面与键盘控制。"""

import ctypes
import os
import subprocess
import sys
from pathlib import Path


APP_DIR = (
    Path(sys.executable).resolve().parent
    if getattr(sys, "frozen", False)
    else Path(__file__).resolve().parent
)


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def relaunch_as_admin():
    args = [arg for arg in sys.argv[1:] if arg != "--elevated"]
    args.append("--elevated")
    if getattr(sys, "frozen", False):
        executable = sys.executable
        arguments = subprocess.list2cmdline(args)
    else:
        executable = sys.executable
        arguments = subprocess.list2cmdline([str(Path(__file__).resolve())] + args)
    rc = ctypes.windll.shell32.ShellExecuteW(
        None, "runas", executable, arguments, str(APP_DIR), 1
    )
    return rc > 32


def run_arp_setup(*extra_args):
    import set_static_arp

    old_argv = sys.argv
    try:
        sys.argv = ["set_static_arp.py", *extra_args]
        return set_static_arp.main()
    finally:
        sys.argv = old_argv


def main():
    os.chdir(APP_DIR)
    no_arp = "--no-arp" in sys.argv

    if not no_arp:
        need_setup = True
        if not is_admin():
            try:
                need_setup = run_arp_setup("--check") != 0
            except Exception as exc:
                print("[提示] 静态 ARP 检查异常：%s" % exc)
            if need_setup:
                if relaunch_as_admin():
                    return 0
                print("[提示] 未获得管理员权限，静态 ARP 不会设置；画面仍可启动。")
        if need_setup and is_admin():
            try:
                run_arp_setup()
            except Exception as exc:
                print("[提示] 静态 ARP 设置异常：%s" % exc)
        print()

    import net_screen_view

    net_screen_view.main()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SystemExit:
        raise
    except Exception:
        import traceback

        traceback.print_exc()
        try:
            ctypes.windll.user32.MessageBoxW(
                0,
                "Tetris PC 启动失败，请查看当前窗口中的错误信息。",
                "Tetris PC",
                0x10,
            )
        except Exception:
            pass
        raise
