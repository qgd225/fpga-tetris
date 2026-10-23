#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 FPGA(192.168.0.2) 的静态 ARP/邻居项绑定到"正确的网卡"上。

踩过的坑：直接 `arp -s 192.168.0.2 <mac>` 不指定网卡时，Windows 会按自己挑的适配器绑定。
实测被挂到了 Radmin VPN(169.254.x) 上——`arp -a` 看着是 static，但去 192.168.0.2 的包
不会从以太网发出去，于是"PC 按键没反应"。本脚本显式指定网卡，并在最后校验
"去 FPGA 的包到底走哪块网卡"。

用法：
    python set_static_arp.py --check    # 只检查，不改任何东西（不需要管理员）
    python set_static_arp.py            # 修复（需要管理员；根目录 TetrisPC.exe 会自动提权调用）
"""
import argparse
import csv
import ctypes
import io
import os
import socket
import subprocess
import sys

FPGA_IP  = "192.168.0.2"          # 与 eth_udp_loopback_rgmii.v 的 LOCAL_IP 一致
FPGA_MAC = "00-0a-35-01-fe-c0"    # 与 LOCAL_MAC 一致
PC_IP    = "192.168.0.3"          # 需要时自动给有线网卡加一个
SUBNET   = "192.168.0."
LOG      = os.path.join(os.environ.get("TEMP", "."), "tetris_static_arp.log")
POWERSHELL = os.path.join(
    os.environ.get("SystemRoot", r"C:\Windows"),
    "System32",
    "WindowsPowerShell",
    "v1.0",
    "powershell.exe",
)

_lines = []


def say(msg=""):
    print(msg)
    _lines.append(str(msg))


def flush_log():
    try:
        with open(LOG, "w", encoding="gbk", errors="replace") as f:
            f.write("\n".join(_lines) + "\n")
    except Exception:
        pass


def ps(cmd):
    """执行一段 PowerShell（强制 UTF-8 输出），返回 (rc, 文本)。"""
    full = "[Console]::OutputEncoding=[Text.Encoding]::UTF8; " + cmd
    p = subprocess.run([POWERSHELL, "-NoProfile", "-NonInteractive", "-Command", full],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out = (p.stdout or b"").decode("utf-8", "replace") + (p.stderr or b"").decode("utf-8", "replace")
    return p.returncode, out.strip()


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def csv_rows(out):
    rows = []
    for r in csv.reader(io.StringIO(out)):
        if r and r[0].strip().isdigit():
            rows.append([x.strip() for x in r])
    return rows


def ipv4_table():
    _, out = ps("Get-NetIPAddress -AddressFamily IPv4 | "
                "Select-Object InterfaceIndex,InterfaceAlias,IPAddress | ConvertTo-Csv -NoTypeInformation")
    return [dict(idx=int(r[0]), alias=r[1], ip=r[2]) for r in csv_rows(out)]


def adapter_table():
    _, out = ps("Get-NetAdapter | Select-Object InterfaceIndex,Name,Status,MediaType,"
                "InterfaceDescription,Virtual | "
                "ConvertTo-Csv -NoTypeInformation")
    return [dict(idx=int(r[0]), name=r[1], status=r[2], media=r[3],
                 desc=r[4] if len(r) > 4 else "",
                 virtual=r[5].lower() if len(r) > 5 else "false")
            for r in csv_rows(out)]


def neighbors():
    _, out = ps("Get-NetNeighbor -IPAddress %s -ErrorAction SilentlyContinue | "
                "Select-Object InterfaceIndex,LinkLayerAddress,State | ConvertTo-Csv -NoTypeInformation" % FPGA_IP)
    return [dict(idx=int(r[0]), mac=(r[1] or "").lower(), state=r[2]) for r in csv_rows(out)]


def route():
    """返回 (ifindex, 源IP)：去 FPGA 的包会从哪块网卡/哪个源地址发出。"""
    _, out = ps("Find-NetRoute -RemoteIPAddress %s -ErrorAction SilentlyContinue | "
                "Select-Object InterfaceIndex,IPAddress | ConvertTo-Csv -NoTypeInformation" % FPGA_IP)
    rows = csv_rows(out)
    if not rows:
        return None, None
    idxs = [int(r[0]) for r in rows if r[0].strip().isdigit()]
    srcs = [r[1] for r in rows if len(r) > 1]
    return (idxs[0] if idxs else None), (srcs[0] if srcs else None)


def local_v4_in_subnet(ipv4s):
    for a in ipv4s:
        if a["ip"].startswith(SUBNET):
            return a["ip"]
    return None


def probe_source():
    """不发包，只问系统：发给 FPGA 时会用哪个本机地址。"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect((FPGA_IP, 5000))
        return s.getsockname()[0]
    except Exception:
        return None
    finally:
        s.close()


def pick_target(ipv4s, adapters):
    """优先用已有场地网段地址的有线/USB网卡；否则挑一块 Up 的有线网卡。"""
    def is_virtual_noise(a):
        text = ("%s %s" % (a["name"], a["desc"])).lower()
        return any(key in text for key in
                   ("vpn", "radmin", "wi-fi direct", "wifi direct",
                    "bluetooth", "loopback", "virtual"))

    def is_wired(a):
        if a["status"].lower() != "up" or is_virtual_noise(a):
            return False
        if a["media"].lower().startswith("802.3"):
            return True
        text = ("%s %s" % (a["name"], a["desc"])).lower()
        return any(key in text for key in ("ethernet", "usb", "realtek", "asix", "rtl"))

    up_wired = [a for a in adapters if is_wired(a)]
    wired_indices = {a["idx"] for a in up_wired}
    for a in ipv4s:
        if a["idx"] in wired_indices and a["ip"].startswith(SUBNET):
            return a["idx"], a["alias"], "already"
    if up_wired:
        a = up_wired[0]
        return a["idx"], a["name"], "addip"
    return None, None, None


def describe(idx, ipv4s):
    for a in ipv4s:
        if a["idx"] == idx and a["ip"].startswith(SUBNET):
            return a["alias"]
    return "索引 %s" % idx


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只检查，不修改（不需要管理员）")
    args = ap.parse_args()

    say("=" * 60)
    say(" FPGA 静态 ARP 设置 %s" % ("（检查模式）" if args.check else ""))
    say("=" * 60)

    ipv4s = ipv4_table()
    adapters = adapter_table()
    idx, name, how = pick_target(ipv4s, adapters)

    say("[网卡] 当前 IPv4：")
    status_by_idx = {a["idx"]: a["status"] for a in adapters}
    for a in ipv4s:
        if a["ip"].startswith(SUBNET):
            if status_by_idx.get(a["idx"], "").lower() == "up":
                mark = "  <- 本机的场地网卡"
            else:
                mark = "  <- 场地地址存在，但网卡未连接"
        else:
            mark = ""
        say("        idx=%-3s %-14s %s%s" % (a["idx"], a["alias"], a["ip"], mark))

    nb = neighbors()
    say("[ARP ] 现有 192.168.0.2 的邻居项：")
    if not nb:
        say("        无（还没设过，或重启后已清空）")
    for n in nb:
        good = (n["idx"] == idx and n["mac"] == FPGA_MAC)
        say("        idx=%-3s %-17s %-10s %s" % (n["idx"], n["mac"], n["state"],
                                               "OK" if good else "<- 绑错网卡/地址不对"))

    ridx, rip = route()
    say("[路由] 去 %s 的包：" % FPGA_IP)
    if ridx is None:
        say("        查不到路由（网卡没插好/没有同网段地址）")
    else:
        say("        从 idx=%s (%s) 发出，源地址 %s  %s"
            % (ridx, describe(ridx, ipv4s), rip, "OK" if ridx == idx else "<- 走错网卡"))

    src_now = probe_source()
    if src_now:
        say("        实际会用的源地址：%s  %s"
            % (src_now, "OK" if src_now.startswith(SUBNET) else "<- 不是场地网段(会走 WiFi/VPN)"))

    ok_now = (bool(nb) and all(n["idx"] == idx and n["mac"] == FPGA_MAC for n in nb)
              and ridx == idx and (src_now is None or src_now.startswith(SUBNET)))
    if idx is None:
        say("")
        say("[结果] 没找到已连接的有线网卡。")
        say("       使用 USB 转 RJ45/扩展坞网口时，请先确认：")
        say("       1) USB 网卡驱动已安装，设备管理器中没有黄色感叹号；")
        say("       2) 网线已连接，Windows 网络连接中的以太网状态为“已连接/Up”；")
        say("       3) 不要只插 USB 网卡而不插网线，Disconnected 状态无法设置路由。")
        flush_log()
        return 2

    if args.check:
        say("")
        say("[结果] %s" % ("静态 ARP 正常，可以直接用。" if ok_now else
                          "静态 ARP 需要修复：请用根目录 TetrisPC.exe（或管理员运行本脚本）设置一次。"))
        flush_log()
        return 0 if ok_now else 2

    if not is_admin():
        say("")
        say("[错误] 需要管理员权限。请用根目录 TetrisPC.exe（会自动提权），")
        say("       或以管理员身份运行本脚本。")
        flush_log()
        return 3

    # ---- 需要时先给有线网卡补一个 192.168.0.x 地址 ----
    if how == "addip":
        say("")
        say("[配置] 给 idx=%s (%s) 添加 %s/24 ..." % (idx, name, PC_IP))
        rc, out = ps("New-NetIPAddress -InterfaceIndex %d -IPAddress %s -PrefixLength 24 "
                     "-ErrorAction Stop | Out-Null; 'OK'" % (idx, PC_IP))
        say("        %s" % (out.replace("\n", " ") if out else ("rc=%d" % rc)))

    # ---- 删掉所有旧邻居项，再在正确的网卡上新建 ----
    say("")
    say("[设置] 清除 192.168.0.2 的旧邻居项（含之前绑错的网卡）...")
    ps("Remove-NetNeighbor -IPAddress %s -Confirm:$false -ErrorAction SilentlyContinue | Out-Null"
       % FPGA_IP)

    mac_ps = FPGA_MAC.replace("-", "-").upper()
    rc, out = ps("New-NetNeighbor -InterfaceIndex %d -IPAddress %s -LinkLayerAddress %s "
                 "-State Permanent -ErrorAction Stop | Out-Null; 'OK'" % (idx, FPGA_IP, mac_ps))
    if "OK" not in out:
        say("        New-NetNeighbor 失败：%s" % out.replace("\n", " "))
        say("        改用 netsh ...")
        rc, out = ps("netsh interface ipv4 delete neighbors %d %s | Out-Null; "
                     "netsh interface ipv4 add neighbors %d %s %s; 'OK'"
                     % (idx, FPGA_IP, idx, FPGA_IP, FPGA_MAC))
        if "OK" not in out:
            say("        netsh 失败：%s" % out.replace("\n", " "))
            say("        改用 arp -s ... -N ...")
            ps("arp -s %s %s -N %s" % (FPGA_IP, FPGA_MAC, PC_IP))
    else:
        say("        ok（已绑定到 idx=%s）" % idx)

    # ---- 路由：无论如何都补一条 /32 路由，钉死从这块网卡出去 ----
    src_ip = local_v4_in_subnet(ipv4s) or PC_IP
    say("")
    say("[路由] 钉一条 %s/32 走 idx=%s（源地址 %s）..." % (FPGA_IP, idx, src_ip))
    rc, out = ps("Remove-NetRoute -DestinationPrefix %s/32 -Confirm:$false "
                 "-ErrorAction SilentlyContinue | Out-Null; "
                 "New-NetRoute -DestinationPrefix %s/32 -InterfaceIndex %d -NextHop 0.0.0.0 "
                 "-PolicyStore ActiveStore -RouteMetric 1 -ErrorAction SilentlyContinue | Out-Null; "
                 "Get-NetRoute -PolicyStore ActiveStore -AddressFamily IPv4 "
                 "-DestinationPrefix %s/32 -ErrorAction SilentlyContinue | "
                 "Select-Object -First 1 InterfaceIndex | ConvertTo-Csv -NoTypeInformation"
                 % (FPGA_IP, FPGA_IP, idx, FPGA_IP))
    route_idx = None
    for r in csv_rows(out):
        if r and r[0].strip().isdigit():
            route_idx = int(r[0])
            break
    if route_idx != idx:
        say("        New-NetRoute 失败，改用 route add ...")
        ps("route delete %s >nul 2>nul & route add %s mask 255.255.255.255 0.0.0.0 if %d metric 1"
           % (FPGA_IP, FPGA_IP, idx))
    else:
        say("        ok（活动路由 idx=%s）" % route_idx)

    # ---- 复核 ----
    say("")
    say("[复核]")
    nb = neighbors()
    ridx, rip = route()
    all_ok = True
    if not nb:
        say("        邻居项：仍然没有！")
        all_ok = False
    for n in nb:
        good = (n["idx"] == idx and n["mac"] == FPGA_MAC)
        all_ok = all_ok and good
        say("        邻居项 idx=%-3s %-17s %-10s %s"
            % (n["idx"], n["mac"], n["state"], "OK" if good else "不对"))
    if ridx == idx:
        say("        去 %s 的包从 idx=%s (%s) 发出，源地址 %s  OK"
            % (FPGA_IP, ridx, describe(ridx, ipv4s), rip))
    else:
        all_ok = False
        say("        去 %s 的包仍从 idx=%s 发出  <- 不对" % (FPGA_IP, ridx))

    src = probe_source()
    if src:
        good_src = src.startswith(SUBNET)
        all_ok = all_ok and good_src
        say("        发出去的包源地址会是 %s  %s" % (src, "OK" if good_src else "<- 不是场地网段(会走 WiFi/VPN)"))
    else:
        say("        源地址探测失败（不影响手动使用）")

    say("")
    if all_ok:
        say("[结果] 成功：静态 ARP 已绑定到正确的网卡，PC 按键应该能用了。")
    else:
        say("[结果] 仍未完全成功，把上面内容截图给管理员/我。常见原因：")
        say("        1) 网线没插好 / 插错口（PC 侧要插到连 FPGA 的那块网卡）")
        say("        2) 有线网卡被禁用（设备管理器里启用）")
    flush_log()
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
