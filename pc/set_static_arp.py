#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""选择实际有线网卡；只将网络配置操作交给系统 PowerShell 提权。"""
import argparse
import ctypes
from ctypes import wintypes
import json
import os
import subprocess
from pc_runtime import log_directory

FPGA_IP = "192.168.0.2"
FPGA_MAC = "00-0a-35-01-fe-c0"
PC_IP = "192.168.0.3"
SUBNET = "192.168.0."
POWERSHELL = os.path.join(os.environ.get("SystemRoot", r"C:\Windows"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
_lines = []


def say(message=""):
    print(message)
    _lines.append(str(message))


def flush_log():
    try:
        (log_directory() / "network_setup.log").write_text("\n".join(_lines), encoding="utf-8")
    except OSError:
        pass


def ps(command):
    prefix = "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $ProgressPreference='SilentlyContinue'; "
    try:
        result = subprocess.run([POWERSHELL, "-NoProfile", "-NonInteractive", "-Command", prefix + command],
                                capture_output=True, timeout=25, creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        text = (result.stdout + result.stderr).decode("utf-8-sig", "replace").strip()
        return result.returncode, text
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, str(exc)


def network_snapshot():
    command = r"""
$ErrorActionPreference='Stop'
$a=@(Get-NetAdapter | Select-Object @{n='idx';e={$_.InterfaceIndex}},@{n='name';e={$_.Name}},@{n='status';e={$_.Status.ToString()}},@{n='media';e={$_.MediaType.ToString()}},@{n='desc';e={$_.InterfaceDescription}},@{n='virtual';e={[bool]$_.Virtual}})
$i=@(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.AddressState -eq 'Preferred'} | Select-Object @{n='idx';e={$_.InterfaceIndex}},@{n='alias';e={$_.InterfaceAlias}},@{n='ip';e={$_.IPAddress}})
$n=@(Get-NetNeighbor -IPAddress 192.168.0.2 -ErrorAction SilentlyContinue | Select-Object @{n='idx';e={$_.InterfaceIndex}},@{n='mac';e={$_.LinkLayerAddress}},@{n='state';e={$_.State.ToString()}})
$r=@(Find-NetRoute -RemoteIPAddress 192.168.0.2 -ErrorAction SilentlyContinue | Select-Object @{n='idx';e={$_.InterfaceIndex}},@{n='ip';e={$_.IPAddress}})
@{adapters=$a;ipv4=$i;neighbors=$n;routes=$r} | ConvertTo-Json -Depth 5 -Compress
"""
    rc, output = ps(command)
    if rc:
        raise RuntimeError("无法读取 Windows 网卡信息：" + output)
    try:
        data = json.loads(output)
        for key in ("adapters", "ipv4", "neighbors", "routes"):
            value = data.get(key)
            data[key] = value if isinstance(value, list) else ([] if value is None else [value])
        return data
    except (ValueError, TypeError, AttributeError) as exc:
        raise RuntimeError("Windows 网卡信息格式异常：" + output[:300]) from exc


def is_wired(adapter):
    text = (str(adapter.get("name", "")) + " " + str(adapter.get("desc", ""))).lower()
    virtual = adapter.get("virtual", False)
    if str(virtual).lower() == "true" or any(x in text for x in ("vpn", "radmin", "virtual", "wi-fi direct", "bluetooth", "loopback")):
        return False
    media = str(adapter.get("media", "")).lower()
    if any(x in media + " " + text for x in ("802.11", "wireless", "wi-fi", "wifi", "wlan", "无线")):
        return False
    return str(adapter.get("status", "")).lower() == "up" and (media.startswith("802.3") or any(x in text for x in ("ethernet", "gbe", "gigabit", "asix", "以太网")))


def pick_target(ipv4s, adapters, preferred_index=None, interface_index=None):
    wired = [a for a in adapters if is_wired(a)]
    if interface_index is not None:
        wired = [a for a in wired if int(a["idx"]) == interface_index]
    if not wired:
        return None, None, None
    indices = {int(a["idx"]) for a in wired}
    configured = [item for item in ipv4s if int(item["idx"]) in indices and str(item["ip"]).startswith(SUBNET)]
    configured.sort(key=lambda item: (int(item["idx"]) != preferred_index, item["ip"] != PC_IP, int(item["idx"])))
    if configured:
        item = configured[0]
        return int(item["idx"]), item.get("alias", "Ethernet"), "already"
    if len(wired) > 1 and interface_index is None:
        return None, None, "ambiguous"
    wired.sort(key=lambda item: int(item["idx"]) != preferred_index)
    return int(wired[0]["idx"]), wired[0]["name"], "addip"


def connection_info(snapshot, interface_index=None):
    routes = snapshot.get("routes", [])
    routed = next((x for x in routes if x.get("ip")), routes[0] if routes else {})
    preferred = int(routed["idx"]) if routed.get("idx") else None
    idx, name, how = pick_target(snapshot["ipv4"], snapshot["adapters"], preferred, interface_index)
    addresses = [x["ip"] for x in snapshot["ipv4"] if int(x["idx"]) == idx and x["ip"].startswith(SUBNET)]
    local = routed.get("ip") if routed.get("ip") in addresses else (PC_IP if PC_IP in addresses else next(iter(addresses), None))
    correct_neighbor = any(int(n["idx"]) == idx and str(n.get("mac", "")).lower().replace(":", "-") == FPGA_MAC and str(n.get("state", "")).lower() == "permanent" for n in snapshot["neighbors"])
    ready = idx is not None and local is not None and preferred == idx and routed.get("ip") in addresses and correct_neighbor
    return dict(index=idx, name=name, how=how, local_ip=local, ready=ready)


def repair_script(index, local_ip, add_ip):
    # 参数来源于已枚举网卡；固定协议地址不接收任意命令文本。
    index = int(index)
    if index <= 0:
        raise ValueError("网卡索引无效")
    import ipaddress
    local_ip = str(ipaddress.IPv4Address(local_ip))
    add = "New-NetIPAddress -InterfaceIndex $idx -IPAddress $source -PrefixLength 24 -ErrorAction Stop | Out-Null" if add_ip else ""
    return r"""
$ErrorActionPreference='Stop'
$idx=INDEX; $source='SOURCE'; $fpga='192.168.0.2'; $mac='00-0a-35-01-fe-c0'
$netsh=Join-Path $env:SystemRoot 'System32\netsh.exe'
$arp=Join-Path $env:SystemRoot 'System32\arp.exe'
$route=Join-Path $env:SystemRoot 'System32\route.exe'
function Invoke-NativeChecked($program, $arguments) {
    $savedPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        & $program @arguments 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {$ErrorActionPreference=$savedPreference}
}
try {
ADD_IP
Remove-NetNeighbor -InterfaceIndex $idx -IPAddress $fpga -Confirm:$false -ErrorAction SilentlyContinue
try {New-NetNeighbor -InterfaceIndex $idx -IPAddress $fpga -LinkLayerAddress $mac -State Permanent -ErrorAction Stop | Out-Null}
catch {
    if ((Invoke-NativeChecked $netsh @('interface','ipv4','add','neighbors',$idx,$fpga,$mac)) -ne 0) {
        if ((Invoke-NativeChecked $arp @('-s',$fpga,$mac,'-N',$source)) -ne 0) {throw '静态 ARP 修复失败'}
    }
}
Remove-NetRoute -DestinationPrefix ($fpga+'/32') -Confirm:$false -ErrorAction SilentlyContinue
try {New-NetRoute -DestinationPrefix ($fpga+'/32') -InterfaceIndex $idx -NextHop 0.0.0.0 -PolicyStore ActiveStore -RouteMetric 1 -ErrorAction Stop | Out-Null}
catch {
    if ((Invoke-NativeChecked $route @('add',$fpga,'mask','255.255.255.255','0.0.0.0','if',$idx,'metric','1')) -ne 0) {throw 'FPGA 路由修复失败'}
}
exit 0
} catch {Write-Error $_; exit 1}
""".replace("INDEX", str(index)).replace("SOURCE", local_ip).replace("ADD_IP", add)


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except (AttributeError, OSError):
        return False


def elevated_powershell(command):
    class ShellExecuteInfo(ctypes.Structure):
        _fields_ = [("cbSize", wintypes.DWORD), ("fMask", wintypes.ULONG), ("hwnd", wintypes.HWND),
                    ("lpVerb", wintypes.LPCWSTR), ("lpFile", wintypes.LPCWSTR), ("lpParameters", wintypes.LPCWSTR),
                    ("lpDirectory", wintypes.LPCWSTR), ("nShow", ctypes.c_int), ("hInstApp", wintypes.HINSTANCE),
                    ("lpIDList", ctypes.c_void_p), ("lpClass", wintypes.LPCWSTR), ("hkeyClass", wintypes.HKEY),
                    ("dwHotKey", wintypes.DWORD), ("hIcon", wintypes.HANDLE), ("hProcess", wintypes.HANDLE)]
    info = ShellExecuteInfo()
    info.cbSize = ctypes.sizeof(info)
    info.fMask = 0x40
    info.lpVerb = "runas"
    info.lpFile = POWERSHELL
    info.lpParameters = subprocess.list2cmdline(["-NoProfile", "-NonInteractive", "-Command", command])
    info.nShow = 0
    shell = ctypes.WinDLL("shell32", use_last_error=True)
    shell.ShellExecuteExW.argtypes = [ctypes.POINTER(ShellExecuteInfo)]
    shell.ShellExecuteExW.restype = wintypes.BOOL
    if not shell.ShellExecuteExW(ctypes.byref(info)):
        return False
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
    kernel.WaitForSingleObject.restype = wintypes.DWORD
    kernel.GetExitCodeProcess.argtypes = [wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD)]
    kernel.CloseHandle.argtypes = [wintypes.HANDLE]
    try:
        if kernel.WaitForSingleObject(info.hProcess, 60000) != 0:
            return False
        code = wintypes.DWORD()
        return bool(kernel.GetExitCodeProcess(info.hProcess, ctypes.byref(code))) and code.value == 0
    finally:
        kernel.CloseHandle(info.hProcess)


def ensure_network(allow_repair=True, interface_index=None):
    snapshot = network_snapshot()
    info = connection_info(snapshot, interface_index)
    if info["index"] is None:
        if info["how"] == "ambiguous":
            say("[网卡] 多块有线网卡均未配置 FPGA 网段，请选择连接 FPGA 的网卡。")
        else:
            say("[网卡] 没有已连接的有线网卡；请检查驱动、网线与网口状态。")
    elif info["ready"]:
        say("[网络] %s / %s，ARP 和路由正常。" % (info["name"], info["local_ip"]))
    elif allow_repair:
        local = info["local_ip"] or PC_IP
        conflict = info["local_ip"] is None and any(x["ip"] == PC_IP and int(x["idx"]) != info["index"] for x in snapshot["ipv4"])
        if conflict:
            say("[网络] 192.168.0.3 已属于另一网卡，未自动修改；请先解决地址冲突。")
        else:
            say("[网络] 将配置有线网卡 %s；需要时由 Windows 请求管理员确认。" % info["name"])
            script = repair_script(info["index"], local, info["how"] == "addip")
            ok = ps(script)[0] == 0 if is_admin() else elevated_powershell(script)
            info = connection_info(network_snapshot(), interface_index)
            if not ok or not info["ready"]:
                say("[网络] 配置未完成或被取消；接收窗口仍可打开，键盘控制需有效 ARP 与路由。")
    else:
        say("[网络] 只检查，不修改 ARP、IP 或路由。")
    flush_log()
    return info


def main(argv=None):
    parser = argparse.ArgumentParser(description="FPGA 有线网卡、静态 ARP 与路由检查")
    parser.add_argument("--check", action="store_true", help="只读检查")
    parser.add_argument("--interface", type=int, help="指定有线网卡索引")
    args = parser.parse_args(argv)
    try:
        return 0 if ensure_network(not args.check, args.interface)["ready"] else 2
    except Exception as exc:
        say("[错误] " + str(exc))
        flush_log()
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
