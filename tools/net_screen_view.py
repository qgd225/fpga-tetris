#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tetris_text2  以太网画面接收端（验收用最小版本）
FPGA 发来的包：
  行包   : A5 5A 01 | 帧号2B | 行号2B | 1280 个颜色标号(每像素 1B)   共 1287 字节
  调色板 : A5 5A 02 | N | N*(标号,R,G,B)                            共 4+4N 字节
用法：
  pip install pillow
  python net_screen_view.py [监听端口]      # 默认 5000（要和 FPGA 的 tx_dst_port 一致）
"""
import socket, sys, threading, time
import tkinter as tk
from PIL import Image, ImageTk

W, H = 1280, 720
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5000

# 默认调色板（与 frame.v 的 27 种颜色一致，收到 FPGA 的调色板包会自动覆盖）
DEFAULT_PAL = {
    0:(0x00,0x00,0x00), 1:(0x00,0xCC,0xFF), 2:(0x99,0x33,0xCC), 3:(0xFF,0xFF,0x00),
    4:(0xE6,0x39,0x46), 5:(0x55,0xA6,0x30), 6:(0xF7,0x7F,0x24), 7:(0xFF,0x4D,0xA6),
    8:(0x99,0xEE,0xFF), 9:(0xD9,0xB3,0xE6), 10:(0xFF,0xFF,0x99), 11:(0xFF,0xB3,0xB9),
    12:(0xBD,0xE0,0xAA),13:(0xFF,0xD9,0xB3),14:(0xFF,0xB3,0xD9), 15:(0xEE,0xEE,0xEE),
    16:(0xFF,0xFF,0xFF),17:(0x10,0x10,0x10),18:(0x20,0x20,0x20), 19:(0x40,0x40,0x40),
    20:(0x60,0x60,0x60),21:(0x90,0x90,0x90),22:(0xB0,0xB0,0xB0), 23:(0xD8,0xD8,0xD8),
    24:(0x30,0x30,0x30),25:(0x00,0xE5,0xFF),26:(0x00,0x69,0x7F),
}
pal = dict(DEFAULT_PAL)
buf = bytearray(W * H)          # 每字节一个标号
line_ok = [0] * H               # 每行是否收到过
lock = threading.Lock()
stat = {"pkt":0, "line":0, "pal":0, "last_frame":-1, "fps":0.0}

def rx_loop():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 8*1024*1024)  # 关键：接收缓冲调大
    except OSError:
        pass
    s.bind(("0.0.0.0", PORT))
    print("listening udp 0.0.0.0:%d ..." % PORT)
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
    threading.Thread(target=rx_loop, daemon=True).start()
    root = tk.Tk()
    root.title("Tetris net screen  (udp:%d)" % PORT)
    label = tk.Label(root, text="waiting...", fg="white", bg="black", font=("Consolas", 12), anchor="w")
    label.pack(fill="x")
    img = Image.new("P", (W, H), 0)
    img.putpalette(pal_bytes())
    imgtk = ImageTk.PhotoImage(img)
    canvas = tk.Canvas(root, width=W, height=H, highlightthickness=0, bg="black")
    canvas.pack()
    item = canvas.create_image(0, 0, anchor="nw", image=imgtk)

    def tick():
        with lock:
            data = bytes(buf)
        im = Image.frombytes("P", (W, H), data)
        im.putpalette(pal_bytes())
        imgtk.paste(im)
        canvas.itemconfigure(item, image=imgtk)
        missing = line_ok.count(0)
        label.config(text="pkt=%d  行包=%d pkt/s=%.0f  调色板包=%d  帧号=%d  未收到的行=%d"
                          % (stat["pkt"], stat["line"], stat["fps"], stat["pal"], stat["last_frame"], missing))
        root.after(33, tick)

    tick()
    root.mainloop()

if __name__ == "__main__":
    main()