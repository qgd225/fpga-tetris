#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""无需 FPGA 的真实 UDP 自测：本机回环、外部监听和另一台电脑发送。"""
import argparse
from contextlib import closing
import ipaddress
import json
import socket
import sys
import threading
import time
from pathlib import Path
from pc_protocol import decode_packet, line_packet, palette_packet, LinePacket, PalettePacket, RGBChunkPacket, AudioPacket
from pc_runtime import VERSION


def local_addresses():
    result = {"127.0.0.1", "0.0.0.0"}
    try:
        result.update(x[4][0] for x in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET))
    except OSError:
        pass
    try:
        from set_static_arp import network_snapshot
        result.update(x["ip"] for x in network_snapshot()["ipv4"])
    except Exception:
        pass
    return result


def receive(sock, seconds, source_ip=None, expected=None):
    stats = dict(datagrams=0, bytes=0, line_packets=0, palette_packets=0, audio_packets=0, invalid_packets=0, sources=[])
    sources = set()
    protocol_sources = set()
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        sock.settimeout(max(0.001, min(0.2, deadline - time.monotonic())))
        try:
            data, peer = sock.recvfrom(65535)
        except socket.timeout:
            continue
        if source_ip and peer[0] != source_ip:
            continue
        stats["datagrams"] += 1
        stats["bytes"] += len(data)
        sources.add(peer[0])
        try:
            packet = decode_packet(data)
            protocol_sources.add(peer[0])
            if isinstance(packet, (LinePacket, RGBChunkPacket)):
                stats["line_packets"] += 1
            elif isinstance(packet, AudioPacket):
                stats["audio_packets"] += 1
            elif isinstance(packet, PalettePacket):
                stats["palette_packets"] += 1
        except ValueError:
            stats["invalid_packets"] += 1
        if expected and stats["line_packets"] >= expected[0] and stats["palette_packets"] >= expected[1]:
            break
    stats["sources"] = sorted(sources)
    stats["protocol_sources"] = sorted(protocol_sources)
    stats["passed"] = stats["line_packets"] + stats["palette_packets"] + stats["audio_packets"] > 0
    return stats


def bind_receiver(address, port):
    from pc_protocol import create_receiver
    return create_receiver(address, port)


def run_loopback(timeout=3, count=8):
    with closing(bind_receiver("127.0.0.1", 0)) as receiver:
        address = receiver.getsockname()
        failures = []
        def send():
            try:
                send_packets(address[0], address[1], count)
            except Exception as exc:
                failures.append(str(exc))
        worker = threading.Thread(target=send, daemon=True)
        worker.start()
        stats = receive(receiver, timeout, expected=(count, 1))
        worker.join(timeout)
    stats["passed"] = stats["line_packets"] == count and stats["palette_packets"] == 1 and stats["audio_packets"] == 1 and not failures and not worker.is_alive()
    stats.update(mode="loopback", bind=address[0], port=address[1], version=VERSION,
                 errors=failures, physical_network_verified=False,
                 conclusion="本机 UDP 发送、接收与 Tetris 协议解析通过；不代表网线、物理网口或防火墙入站已验证。" if stats["passed"] else "本机 UDP 自测未通过。")
    return stats


def send_packets(target, port, count=8, bind=None):
    with closing(socket.socket(socket.AF_INET, socket.SOCK_DGRAM)) as sender:
        if bind:
            sender.bind((bind, 0))
        sender.sendto(palette_packet(), (target, port))
        audio=bytes.fromhex('a55a0600')+bytes.fromhex('000000010000000000000000bb8000f0')+bytes(480)
        sender.sendto(audio,(target,port))
        for i in range(count):
            sender.sendto(line_packet(frame=1 + i // 720, line=i % 720), (target, port))
            time.sleep(0.01)
    return dict(mode="send", passed=True, target=target, port=port, sent_datagrams=count + 2,
                version=VERSION, receiver_verified=False,
                conclusion="测试包已交给系统发送；接收是否成功以另一台电脑的监听结果为准。")


def run_listen(bind="0.0.0.0", port=5000, timeout=10, source_ip=None, ready_callback=None):
    own_addresses = local_addresses()
    with closing(bind_receiver(bind, port)) as receiver:
        if ready_callback:
            ready_callback(receiver.getsockname())
        stats = receive(receiver, timeout, source_ip)
    external = [ip for ip in stats["protocol_sources"] if ip not in own_addresses and not ipaddress.ip_address(ip).is_loopback]
    stats.update(mode="listen", bind=bind, port=port, version=VERSION, external_sources=external,
                 physical_network_verified=False, external_datagrams_received=bool(external))
    if stats["passed"] and external:
        stats["conclusion"] = "已收到外部地址的 Tetris UDP 数据；请结合实际网线和所选网卡确认链路。本工具不能区分 VPN、无线或物理有线传输。"
    elif stats["passed"]:
        stats["conclusion"] = "收到本机来源的 Tetris UDP；外部网口入站仍未验证。"
    elif stats["datagrams"]:
        stats["conclusion"] = "收到 UDP，但未识别有效 Tetris 协议包；检查发送协议和来源。"
    else:
        stats["conclusion"] = "等待期间没有收到 UDP；检查对端目标 IP、网线、端口、防火墙和网卡地址。"
    return stats


def output_result(result, json_output=False, report=None):
    if json_output:
        print(json.dumps(result, ensure_ascii=False), flush=True)
    else:
        print("\n自测结果：" + ("通过" if result.get("passed") else "未通过"))
        for key, label in [("mode", "模式"), ("bind", "监听地址"), ("port", "端口"), ("datagrams", "收到 UDP 包"),
                           ("line_packets", "有效行包"), ("palette_packets", "有效调色板包"), ("invalid_packets", "其他／无效包"),
                           ("sent_datagrams", "发送包数"), ("sources", "数据来源")]:
            if key in result:
                print(f"{label}：{result[key]}")
        print(result.get("conclusion", result.get("error", "")))
    if report:
        report_path = Path(report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def interactive():
    print("Tetris 网口自测，无需 FPGA。默认不修改网卡、ARP、路由或防火墙。")
    print("1. 本机 UDP 回环：验证软件收发和协议解析")
    print("2. 监听外部网口数据：另一台电脑负责发送")
    print("3. 向另一台电脑发送测试数据")
    choice = input("请选择 [1]：").strip() or "1"
    if choice == "1":
        return ["--mode", "loopback"]
    if choice == "2":
        print("先关闭正常画面程序，避免占用 5000 端口。")
        bind = input("监听本机 IPv4 地址 [0.0.0.0]：").strip() or "0.0.0.0"
        print("另一台电脑运行：TetrisPC.exe --self-test --mode send --target <本机网卡IPv4地址>")
        return ["--mode", "listen", "--bind", bind, "--timeout", "30"]
    if choice == "3":
        target = input("接收电脑的网卡 IPv4 地址：").strip()
        return ["--mode", "send", "--target", target]
    raise ValueError("请选择 1、2 或 3")


def main(argv=None):
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure") and not stream.isatty():
            stream.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description="Tetris UDP 接收自测，无需上板")
    parser.add_argument("--mode", choices=["loopback", "listen", "send"], default="loopback", help="本机回环、外部监听、对端发送")
    parser.add_argument("--bind", help="指定本机 IPv4 地址；监听默认 0.0.0.0")
    parser.add_argument("--port", type=int, default=5000, help="外部收发端口，默认 5000；回环使用空闲临时端口")
    parser.add_argument("--target", help="发送目标电脑的 IPv4 地址")
    parser.add_argument("--source-ip", help="只统计该发送源")
    parser.add_argument("--timeout", type=float, default=10, help="等待秒数")
    parser.add_argument("--count", type=int, default=8, help="发送测试行包数")
    parser.add_argument("--json", action="store_true", help="输出机器可读结果")
    parser.add_argument("--report", help="额外保存 JSON 报告的路径")
    parser.add_argument("--interactive", action="store_true", help="中文选择菜单")
    args = parser.parse_args(argv)
    if args.interactive:
        try:
            return main(interactive())
        except (ValueError, EOFError, KeyboardInterrupt) as exc:
            print("自测已取消或输入无效：" + str(exc))
            return 2
    if not 1 <= args.port <= 65535 or not 0 < args.timeout <= 3600 or not 1 <= args.count <= 10000:
        parser.error("端口、等待时间或包数超出范围")
    try:
        for address in [args.bind, args.target, args.source_ip]:
            if address is not None:
                ipaddress.IPv4Address(address)
        if args.mode == "loopback":
            result = run_loopback(args.timeout, args.count)
        elif args.mode == "send":
            if not args.target or args.target == "0.0.0.0":
                parser.error("发送模式必须指定 --target <接收电脑IPv4地址>")
            result = send_packets(args.target, args.port, args.count, args.bind)
        else:
            def ready(address):
                print("正在监听 %s:%s，请在另一台电脑发送测试包……" % address, file=sys.stderr if args.json else sys.stdout, flush=True)
            result = run_listen(args.bind or "0.0.0.0", args.port, args.timeout, args.source_ip, ready)
    except (OSError, ValueError) as exc:
        result = dict(passed=False, mode=args.mode, error=str(exc), conclusion="自测未启动或未完成：" + str(exc))
        if isinstance(exc, OSError) and getattr(exc, "winerror", None) == 10048:
            result["conclusion"] += "；端口已占用，请关闭画面程序或指定另一端口。"
    try:
        output_result(result, args.json, args.report)
    except OSError as exc:
        print("无法写入报告：" + str(exc))
        return 1
    return 0 if result.get("passed") else 1


if __name__ == "__main__":
    raise SystemExit(main())
