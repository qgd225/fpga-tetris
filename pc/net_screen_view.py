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
from pc_protocol import decode_packet, LinePacket, create_receiver

# ======== 默认参数（要改就改这里）========
FPGA_IP     = "192.168.0.2"     # FPGA 的 IP（和 net_screen_tx 里 LOCAL_IP 一致）
FPGA_PORT   = 5000              # FPGA 的 UDP 端口
LISTEN_PORT = 5000              # 本机监听画面包的端口（不要和别的程序抢）
RESEND_S    = 0.02              # 按键包重发周期 20ms
# ========================================

W, H = 1280, 720

DEFAULT_PAL = {
    0:(0,0,0),
    1:(56,182,200),
    2:(155,107,181),
    3:(217,178,60),
    4:(194,69,58),
    5:(79,168,107),
    6:(217,123,51),
    7:(62,111,191),
    8:(116,204,216),
    9:(185,151,203),
    10:(228,201,118),
    11:(212,125,117),
    12:(132,194,151),
    13:(228,163,112),
    14:(120,154,210),
    15:(238,238,238),
    16:(232,238,242),
    17:(16,16,16),
    18:(32,32,32),
    19:(64,64,64),
    20:(96,96,96),
    21:(58,74,88),
    22:(91,110,126),
    23:(36,50,64),
    24:(48,48,48),
    25:(47,168,184),
    26:(122,36,24),
    27:(10,17,24),
    28:(42,54,68),
    29:(28,40,54),
    30:(31,100,110),
    31:(85,59,100),
    32:(119,98,33),
    33:(107,38,32),
    34:(43,92,59),
    35:(119,68,28),
    36:(34,61,105),
    37:(127,227,236),
    38:(196,82,122),
    39:(27,107,118),
    40:(126,46,74),
    41:(232,162,60),
    42:(255,201,107),
    43:(138,90,24),
    44:(7,10,16),
    45:(5,10,14),
    46:(19,29,38),
    47:(51,70,80),
    48:(34,48,61),
    49:(22,33,43),
    50:(12,22,30),
    51:(168,182,192),
    52:(201,210,216),
    53:(82,103,116),
    54:(216,68,46),
    55:(14,21,28),
}

pal = dict(DEFAULT_PAL)
buf = bytearray(W * H)
line_ok = [0] * H
lock = threading.Lock()
stat = {"pkt":0, "line":0, "pal":0, "last_frame":-1, "fps":0.0, "kb":0, "invalid":0, "error":""}
stop_event = threading.Event()
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
    return lis



def local_ip_in_subnet(prefix="192.168.0."):
    """只使用实际选中的已连接有线网卡，不按主机地址排序。"""
    from set_static_arp import network_snapshot, connection_info
    try:
        address = connection_info(network_snapshot())["local_ip"]
        return address if address and address.startswith(prefix) else None
    except Exception as exc:
        print("[网络] 无法确定有线源地址：" + str(exc))
        return None



def tx_loop(local_source=None):
    local = local_source or local_ip_in_subnet()
    if not local:
        print("[按键] 未找到有效的有线源地址，键盘发送暂未启用；画面仍可接收。")
        return
    from pc_runtime import high_resolution_timer
    with high_resolution_timer(), socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sender:
        try:
            sender.bind((local, 0))
        except OSError as exc:
            print("[按键] 无法绑定有线地址 %s：%s" % (local, exc))
            return
        print("[按键] 使用有线源地址 %s -> %s:%d" % (local, FPGA_IP, FPGA_PORT))
        try:
            while not stop_event.is_set():
                kb_ev.wait(RESEND_S)
                kb_ev.clear()
                with kb_lock:
                    bits = kb_bits
                try:
                    sender.sendto(kb_packet(bits), (FPGA_IP, FPGA_PORT))
                    stat["kb"] += 1
                except OSError as exc:
                    print("[按键] 发送失败：" + str(exc))
                    stop_event.wait(0.5)
        finally:
            try:
                sender.sendto(kb_packet(0), (FPGA_IP, FPGA_PORT))
            except OSError:
                pass



def rx_loop(receiver):
    receiver.settimeout(0.2)
    t0, n0 = time.monotonic(), 0
    try:
        while not stop_event.is_set():
            try:
                data, peer = receiver.recvfrom(65535)
            except socket.timeout:
                continue
            except OSError as exc:
                if not stop_event.is_set():
                    stat["error"] = "接收失败：" + str(exc)
                return
            stat["pkt"] += 1
            try:
                packet = decode_packet(data)
            except ValueError:
                stat["invalid"] += 1
                continue
            with lock:
                if isinstance(packet, LinePacket):
                    old_frame = stat["last_frame"]
                    if packet.frame != old_frame:
                        line_ok[:] = [0] * H
                    buf[packet.line * W:(packet.line + 1) * W] = packet.pixels
                    line_ok[packet.line] = 1
                    stat["line"] += 1
                    stat["last_frame"] = packet.frame
                else:
                    pal.update(dict(packet.entries))
                    stat["pal"] += 1
            now = time.monotonic()
            if now - t0 >= 1:
                stat["fps"] = (stat["pkt"] - n0) / (now - t0)
                n0, t0 = stat["pkt"], now
    finally:
        receiver.close()



def pal_bytes():
    p = bytearray(768)
    with lock:
        for k, v in pal.items():
            if 0 <= k < 256:
                p[k*3] = v[0]; p[k*3+1] = v[1]; p[k*3+2] = v[2]
    return bytes(p)


def main(local_source=None, smoke_test=False, smoke_report=None):
    import hashlib
    import json
    root = tk.Tk()
    root.withdraw()
    receiver = None
    listener = None
    workers = []
    stop_event.clear()
    def close():
        global kb_bits
        with kb_lock:
            kb_bits = 0
        stop_event.set()
        kb_ev.set()
        root.destroy()
    try:
        if not smoke_test:
            # 在创建后台线程前占用端口；冲突会明确报错，不留下无数据的假窗口。
            receiver = create_receiver("0.0.0.0", LISTEN_PORT)
            listener = start_listener()
            for target, args in [(rx_loop, (receiver,)), (tx_loop, (local_source,))]:
                worker = threading.Thread(target=target, args=args, daemon=True)
                worker.start()
                workers.append(worker)
        root.title("Tetris  (画面 udp:%d  ->  按键 %s:%d)" % (LISTEN_PORT, FPGA_IP, FPGA_PORT))
        root.protocol("WM_DELETE_WINDOW", close)
        label = tk.Label(root, text="等待画面...", fg="white", bg="black", font=("Consolas", 12), anchor="w")
        label.pack(fill="x")
        canvas = tk.Canvas(root, width=W, height=H, highlightthickness=0, bg="black")
        canvas.pack()
        image = Image.new("P", (W, H), 0)
        image.putpalette(pal_bytes())
        photo = ImageTk.PhotoImage(image)
        item = canvas.create_image(0, 0, anchor="nw", image=photo)
        def tick():
            with lock:
                pixels = bytes(buf)
                missing = line_ok.count(0)
            im = Image.frombytes("P", (W, H), pixels)
            im.putpalette(pal_bytes())
            photo.paste(im)
            canvas.itemconfigure(item, image=photo)
            label.config(text="行包=%d 调色板=%d 帧号=%d 本帧缺行=%d | 按键:%s 已发=%d | %s" %
                         (stat["line"], stat["pal"], stat["last_frame"], missing, kb_text(), stat["kb"], stat.get("error", "")))
            if not stop_event.is_set():
                root.after(33, tick)
        root.update_idletasks()
        root.geometry("+0+0")
        if not smoke_test:
            root.deiconify()
        tick()
        if smoke_test:
            from pynput import keyboard
            result = dict(passed=True, palette_entries=len(DEFAULT_PAL), palette_sha256=hashlib.sha256(pal_bytes()).hexdigest(),
                          tk_version=str(root.tk.call("info", "patchlevel")), keyboard_backend=keyboard.__name__,
                          network_configuration_changed=False)
            if smoke_report:
                from pathlib import Path
                report_path = Path(smoke_report)
                report_path.parent.mkdir(parents=True, exist_ok=True)
                report_path.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
            print(json.dumps(result, ensure_ascii=False), flush=True)
            root.after(250, close)
        root.mainloop()
        return 0
    finally:
        stop_event.set()
        kb_ev.set()
        if listener is not None:
            listener.stop()
        for worker in workers:
            worker.join(timeout=1)
        if receiver is not None:
            receiver.close()
        try:
            root.destroy()
        except tk.TclError:
            pass



def report_startup_error(title, message):
    from pc_runtime import write_error
    path = write_error(message)
    text = message + "\n日志：" + path
    print(text)
    try:
        import ctypes
        ctypes.windll.user32.MessageBoxW(0, text, title, 0x10)
    except (AttributeError, OSError):
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
