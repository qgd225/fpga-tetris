#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tetris 以太网：PC 端画面显示 + 键盘按键发送
正常使用时双击根目录 TetrisPC.exe 即可运行。

FPGA 发来的包：
  行包   : A5 5A 01 | 帧号2B | 行号2B | 1280 个颜色标号(每像素 1B)   共 1287 字节
  调色板 : A5 5A 02 | N | N*(标号,R,G,B)                            共 4+4N 字节
本程序发给 FPGA 的按键包：
  A5 5A 03 | 位图1B
    位图: bit0=左  bit1=右  bit2=下  bit3=旋转(上)
          bit4=小键盘0(保持)  bit5=小键盘5(开始/暂停)  bit6=小键盘9(复位)
  按下/松开立刻发一包，另外每 20ms 无条件重发一包（丢包 20ms 自愈）

注意：FPGA 不回 ARP，所以第一次用（或重启后）请运行根目录 TetrisPC.exe，
      它会自动把静态 ARP 绑到正确的网卡，然后启动本程序。
"""
import os, socket, sys, threading, time

# ======== 默认参数（要改就改这里）========
FPGA_IP     = "192.168.0.2"     # FPGA 的 IP（和 net_screen_tx 里 LOCAL_IP 一致）
FPGA_PORT   = 5000              # FPGA 的 UDP 端口
LISTEN_PORT = 5000              # 本机监听画面包的端口（不要和别的程序抢）
RESEND_S    = 0.02              # 按键包重发周期 20ms
# ========================================

W, H = 1280, 720

DEFAULT_PAL = {
    0:(0x00,0x00,0x00), 1:(0x00,0xCC,0xFF), 2:(0x99,0x33,0xCC), 3:(0xFF,0xFF,0x00),
    4:(0xE6,0x39,0x46), 5:(0x55,0xA6,0x30), 6:(0xF7,0x7F,0x24), 7:(0xFF,0x4D,0xA6),
    8:(0x99,0xEE,0xFF), 9:(0xD9,0xB3,0xE6), 10:(0xFF,0xFF,0x99), 11:(0xFF,0xB3,0xB9),
    12:(0xBD,0xE0,0xAA),13:(0xFF,0xD9,0xB3),14:(0xFF,0xB3,0xD9), 15:(0xEE,0xEE,0xEE),
    16:(0xFF,0xFF,0xFF),17:(0x10,0x10,0x10),18:(0x20,0x20,0x20), 19:(0x40,0x40,0x40),
    20:(0x60,0x60,0x60),21:(0x90,0x90,0x90),22:(0xB0,0xB0,0xB0), 23:(0xD8,0xD8,0xD8),
    24:(0x30,0x30,0x30),25:(0x00,0xE5,0xFF),26:(0x00,0x69,0x7F),
    27:(0x0A,0x0F,0x16),28:(0x08,0x1A,0x1E),29:(0x1E,0x08,0x12),
    30:(0x04,0x63,0x7E),31:(0x47,0x1F,0x67),32:(0x74,0x79,0x0D),
    33:(0x69,0x22,0x2C),34:(0x29,0x52,0x23),35:(0x71,0x41,0x1D),
    36:(0x74,0x2B,0x56),37:(0x6B,0xF0,0xFF),38:(0xFF,0x98,0xCB),
    39:(0x38,0xD9,0x96),40:(0x9B,0xD6,0x4D),41:(0xFF,0xD2,0x3F),
    42:(0xFF,0x9F,0x1C),43:(0xFF,0x6B,0x35),
    44:(0x08,0x10,0x18),45:(0x06,0x10,0x17),46:(0x0D,0x20,0x29),
    47:(0x29,0x40,0x4D),48:(0x08,0x79,0x8A),49:(0x7B,0x2B,0x54),
    50:(0x17,0x41,0x4B),51:(0x09,0x17,0x1C),52:(0x10,0x25,0x2B),
    53:(0x53,0x6A,0x76),54:(0x80,0x55,0x1F),55:(0x07,0x10,0x18),
}

pal = dict(DEFAULT_PAL)
buf = bytearray(W * H)
line_ok = [0] * H
lock = threading.Lock()
stat = {"pkt":0, "line":0, "pal":0, "last_frame":-1, "fps":0.0, "kb":0}
APP_DIR = (
    os.path.dirname(os.path.abspath(sys.executable))
    if getattr(sys, "frozen", False)
    else os.path.dirname(os.path.abspath(__file__))
)
STARTUP_LOG = os.path.join(APP_DIR, "startup_error.log")

kb_lock = threading.Lock()
kb_bits = 0
kb_ev = threading.Event()

VK_BITS = {37:0, 39:1, 40:2, 38:3, 96:4, 101:5, 105:6}
BIT_NAME = ["左", "右", "下", "旋转(上)", "小键盘0 保持", "小键盘5 开始/暂停", "小键盘9 复位", "-"]


def kb_packet(bits):
    return bytes(bytearray([0xA5, 0x5A, 0x03, bits & 0xFF]))


def kb_text():
    with kb_lock:
        b = kb_bits
    s = [BIT_NAME[i] for i in range(7) if (b >> i) & 1]
    return ("+".join(s)) if s else "无"


def kb_set(bit, down):
    global kb_bits
    with kb_lock:
        if down:
            kb_bits |= (1 << bit)
        else:
            kb_bits &= ~(1 << bit)
    kb_ev.set()


def key_vk(key):
    # 方向键回来的是 Key 枚举成员, 它没有 .vk (vk 在 key.value.vk 里)
    vk = getattr(key, "vk", None)
    if vk is None:
        vk = getattr(getattr(key, "value", None), "vk", None)
    return vk


def start_listener():
    try:
        from pynput import keyboard
    except Exception as e:
        print("[提示] 没有 pynput，键盘发送功能关闭（画面照常显示）。原因: %s" % e)
        return
    keymap = {
        keyboard.Key.left : 0,
        keyboard.Key.right: 1,
        keyboard.Key.down : 2,
        keyboard.Key.up   : 3,
    }
    seen = set()

    def one_key(key, down):
        b = None
        if key in keymap:
            b = keymap[key]
        else:
            vk = key_vk(key)
            if vk in VK_BITS:
                b = VK_BITS[vk]
            elif vk is not None and vk not in seen:
                seen.add(vk)
                print("[未识别] %r  vk=%s  (要用它就把 vk 加进脚本顶部的 VK_BITS)" % (key, vk))
        if b is not None:
            kb_set(b, down)

    def on_press(key):
        one_key(key, True)
    def on_release(key):
        one_key(key, False)
    lis = keyboard.Listener(on_press=on_press, on_release=on_release)
    lis.daemon = True
    lis.start()
    print("键盘已接管: 方向键=左/右/下/上(上=旋转), 小键盘 5=开始暂停 0=保持 9=复位 (请打开 NumLock)")


try:
    import ctypes
    ctypes.windll.winmm.timeBeginPeriod(1)     # 让 20ms 定时/重发更准
except Exception:
    pass


def local_ip_in_subnet(prefix="192.168.0."):
    """本机是否有一块网卡是 192.168.0.x；有就返回这个地址。"""
    ips = set()
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ips.add(info[4][0])
    except Exception:
        pass
    try:
        for ip in socket.gethostbyname_ex(socket.gethostname())[2]:
            ips.add(ip)
    except Exception:
        pass
    for ip in sorted(ips):
        if ip.startswith(prefix):
            return ip
    try:
        from set_static_arp import adapter_table, ipv4_table, pick_target

        ipv4s = ipv4_table()
        target_idx, _, _ = pick_target(ipv4s, adapter_table())
        for item in ipv4s:
            if item["idx"] == target_idx and item["ip"].startswith(prefix):
                return item["ip"]
    except Exception:
        pass
    return None


def tx_loop():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    # 把发送源地址钉在场地网卡上：不钉的话，去 192.168.0.2 的包可能被 WiFi/VPN 的默认路由抢走
    auto_src = None
    try:
        probe = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        probe.connect((FPGA_IP, FPGA_PORT))
        auto_src = probe.getsockname()[0]
        probe.close()
    except Exception:
        auto_src = None
    local = local_ip_in_subnet()
    if local:
        try:
            s.bind((local, 0))
            print("[按键] 源地址固定为 %s -> %s:%d" % (local, FPGA_IP, FPGA_PORT))
            if auto_src and auto_src != local:
                print("[提示] 系统原本会从 %s 发出（不是场地网段），已改为走 %s" % (auto_src, local))
        except Exception as e:
            print("[警告] 绑定本机地址 %s 失败(%s)，改用系统默认路由" % (local, e))
    else:
        print("[按键] 没找到本机 192.168.0.x 地址（源地址 %s）；按键若无效，请运行根目录 TetrisPC.exe"
              % (auto_src or "未知"))
    while True:
        kb_ev.wait(RESEND_S)
        kb_ev.clear()
        try:
            with kb_lock:
                bits = kb_bits
            s.sendto(kb_packet(bits), (FPGA_IP, FPGA_PORT))
            stat["kb"] += 1
        except Exception as exc:
            print("[警告] 按键包发送失败：%s" % exc)
            time.sleep(0.5)


def rx_loop():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 8 * 1024 * 1024)
    except OSError:
        pass
    try:
        s.bind(("0.0.0.0", LISTEN_PORT))
    except Exception as e:
        print("[提示] 端口 %d 占用中(%s)，画面显示关闭。是不是已经开了一个本程序？" % (LISTEN_PORT, e))
        return
    print("画面监听 udp 0.0.0.0:%d ..." % LISTEN_PORT)
    t0 = time.time(); n0 = 0
    while True:
        d, addr = s.recvfrom(2048)
        if len(d) < 4 or d[0] != 0xA5 or d[1] != 0x5A:
            continue
        stat["pkt"] += 1
        typ = d[2]
        if typ == 1 and len(d) >= 7 + W:
            frame = (d[3] << 8) | d[4]
            line  = (d[5] << 8) | d[6]
            if 0 <= line < H:
                with lock:
                    buf[line*W:(line+1)*W] = d[7:7+W]
                    line_ok[line] = 1
                stat["line"] += 1
                stat["last_frame"] = frame
        elif typ == 2 and len(d) >= 4:
            n = d[3]
            with lock:
                for i in range(n):
                    b = 4 + i*4
                    if b+3 < len(d):
                        pal[d[b]] = (d[b+1], d[b+2], d[b+3])
            stat["pal"] += 1
        now = time.time()
        if now - t0 >= 1.0:
            stat["fps"] = (stat["pkt"] - n0) / (now - t0)
            n0 = stat["pkt"]; t0 = now


def pal_bytes():
    p = bytearray(768)
    with lock:
        for k, v in pal.items():
            if 0 <= k < 256:
                p[k*3] = v[0]; p[k*3+1] = v[1]; p[k*3+2] = v[2]
    return bytes(p)


def main():
    # 先创建窗口句柄，确保启动失败时不会留下一个无界面的后台进程
    root = tk.Tk()
    root.withdraw()
    print("画面目标: 监听 %d 端口 <- FPGA" % LISTEN_PORT)
    print("按键目标: 发给 %s:%d（静态 ARP 由 TetrisPC.exe 自动设置）" % (FPGA_IP, FPGA_PORT))
    threading.Thread(target=rx_loop, daemon=True).start()
    start_listener()
    threading.Thread(target=tx_loop, daemon=True).start()

    root.title("Tetris  (画面 udp:%d  ->  按键 %s:%d)" % (LISTEN_PORT, FPGA_IP, FPGA_PORT))
    label = tk.Label(root, text="等待画面...", fg="white", bg="black", font=("Consolas", 12), anchor="w")
    label.pack(fill="x")
    canvas = tk.Canvas(root, width=W, height=H, highlightthickness=0, bg="black")
    canvas.pack()

    img = Image.new("P", (W, H), 0)
    img.putpalette(pal_bytes())
    imgtk = ImageTk.PhotoImage(img)
    item = canvas.create_image(0, 0, anchor="nw", image=imgtk)

    def tick():
        with lock:
            data = bytes(buf)
        im = Image.frombytes("P", (W, H), data)
        im.putpalette(pal_bytes())
        imgtk.paste(im)
        canvas.itemconfigure(item, image=imgtk)
        missing = line_ok.count(0)
        label.config(text="pkt=%d 行包=%d pkt/s=%.0f 调色板包=%d 帧号=%d 未收到的行=%d | 按键:%s 已发按键包=%d"
                          % (stat["pkt"], stat["line"], stat["fps"], stat["pal"],
                             stat["last_frame"], missing, kb_text(), stat["kb"]))
        root.after(33, tick)

    root.update_idletasks()
    root.geometry("+0+0")
    root.deiconify()
    root.lift()
    root.attributes("-topmost", True)
    root.after(500, lambda: root.attributes("-topmost", False))
    tick()
    root.mainloop()


def report_startup_error(title, message):
    # 同时写日志和弹窗；不再 input() 卡住无窗口进程
    import traceback
    detail = traceback.format_exc()
    text = "%s\n\n%s\n\n日志: %s" % (message, detail, STARTUP_LOG)
    print(text)
    try:
        with open(STARTUP_LOG, "w", encoding="utf-8") as f:
            f.write(text)
    except Exception:
        pass
    try:
        import ctypes
        ctypes.windll.user32.MessageBoxW(0, text, title, 0x10)
    except Exception:
        pass


try:
    import tkinter as tk
    from PIL import Image, ImageTk
except Exception as _e:
    print("启动失败: 缺少图形依赖（%s）" % _e)
    print("请使用根目录 TetrisPC.exe；源码开发模式需先安装 pillow 和 pynput")
    report_startup_error("Tetris PC 启动失败", "缺少图形依赖：%s" % _e)
    sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except Exception as _e:
        report_startup_error("Tetris PC 启动失败", "接收端启动失败：%s" % _e)
        sys.exit(1)
