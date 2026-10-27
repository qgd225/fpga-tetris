#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""便携启动入口；自测无须管理员，网络配置只提权系统帮助进程。"""
import argparse
import sys
from pc_runtime import VERSION, write_error


def main(argv=None):
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure") and not stream.isatty():
            stream.reconfigure(encoding="utf-8", errors="replace")
    args = list(sys.argv[1:] if argv is None else argv)
    if "--self-test" in args:
        args.remove("--self-test")
        import network_selftest
        return network_selftest.main(args)
    parser = argparse.ArgumentParser(description="Tetris PC 显示与控制，Windows x64 便携版")
    parser.add_argument("--version", action="version", version="TetrisPC " + VERSION)
    parser.add_argument("--check-network", action="store_true", help="仅输出网卡和路由检查结果，不提权、不修改设置")
    parser.add_argument("--no-arp", action="store_true", help="不修改网络设置")
    parser.add_argument("--interface", type=int, help="指定有线网卡索引")
    parser.add_argument("--smoke-test", action="store_true", help="仅验证图形依赖与窗口，不接收外部数据或设置网络")
    parser.add_argument("--smoke-report", help="保存图形软件检查 JSON")
    options = parser.parse_args(args)
    if options.check_network:
        import json
        from set_static_arp import network_snapshot, connection_info
        snapshot = network_snapshot()
        print(json.dumps(dict(passed=True, read_only=True, adapters=len(snapshot["adapters"]),
                              connection=connection_info(snapshot, options.interface)), ensure_ascii=False))
        return 0
    local = None
    if not options.smoke_test:
        try:
            from set_static_arp import ensure_network, network_snapshot, is_wired
            info = ensure_network(not options.no_arp, options.interface)
            if info["how"] == "ambiguous" and not options.no_arp:
                import tkinter as tk
                from tkinter import simpledialog
                snapshot = network_snapshot()
                choices = [a for a in snapshot["adapters"] if is_wired(a)]
                prompt = "请输入连接 FPGA 的网卡编号：\n" + "\n".join(str(a["idx"]) + "：" + a["name"] for a in choices)
                root = tk.Tk()
                root.withdraw()
                try:
                    index = simpledialog.askinteger("选择 FPGA 有线网卡", prompt, parent=root)
                finally:
                    root.destroy()
                if index in {int(a["idx"]) for a in choices}:
                    info = ensure_network(True, index)
            local = info["local_ip"]
        except Exception as exc:
            print("[网络] 自动检查未完成：%s；窗口仍可打开。" % exc)
    import net_screen_view
    return net_screen_view.main(local_source=local, smoke_test=options.smoke_test, smoke_report=options.smoke_report)


def entry():
    try:
        return main()
    except KeyboardInterrupt:
        return 130
    except Exception as exc:
        message = "Tetris PC 启动失败：" + str(exc)
        path = write_error(message)
        print(message + "\n日志：" + path, file=sys.stderr)
        try:
            import ctypes
            if not any(flag in sys.argv for flag in ("--smoke-test", "--check-network", "--self-test")):
                ctypes.windll.user32.MessageBoxW(0, message + "\n日志：" + path, "Tetris PC", 0x10)
        except (AttributeError, OSError):
            pass
        return 1


if __name__ == "__main__":
    raise SystemExit(entry())
