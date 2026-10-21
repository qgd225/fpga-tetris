#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tetris 以太网：PC 端画面显示 + 键盘按键发送
双击 tools\启动-画面和按键.bat 即可运行（无需命令行参数）

FPGA 发来的包：
  行包   : A5 5A 01 | 帧号2B | 行号2B | 1280 个颜色标号(每像素 1B)   共 1287 字节
  调色板 : A5 5A 02 | N | N*(标号,R,G,B)                            共 4+4N 字节
FPGA 发来的结果包（每局结束进结束画面时发，之后每 500ms 重发一次）：
  A5 5A 04 | 局序号1B | 模式1B | 分数3B | 等级1B | 累计消行2B | 用时秒2B | 异或校验1B  共 14 字节

本程序发给 FPGA 的按键包：
  A5 5A 03 | 位图1B
    位图: bit0=左  bit1=右  bit2=下  bit3=旋转(上)
          bit4=小键盘0(保持)  bit5=小键盘5(开始/暂停)  bit6=小键盘9(复位)
  按下/松开立刻发一包，另外每 20ms 无条件重发一包（丢包 20ms 自愈）

注意：FPGA 不回 ARP，所以第一次用（或重启后）请双击一次 tools\双击启动.bat，
      它会自动把静态 ARP 绑到正确的网卡，然后启动本程序。
"""
import os, socket, sys, threading, time

# ======== 默认参数（要改就改这里）========
FPGA_IP     = "192.168.0.2"     # FPGA 的 IP（和 net_screen_tx 里 LOCAL_IP 一致）
FPGA_PORT   = 5000              # FPGA 的 UDP 端口
LISTEN_PORT = 5000              # 本机监听画面包的端口（不要和别的程序抢）
RESEND_S    = 0.02              # 按键包重发周期 20ms
RANK_W      = 300               # 右侧排行榜面板宽度(像素)
SHOW_RANK   = True              # 屏幕不够宽时自动退回"状态行文字显示"
DEDUP_SEC   = 10.0              # 同一局序号在这个秒数内的重发只记一条
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
stat = {"pkt":0, "line":0, "pal":0, "last_frame":-1, "fps":0.0, "kb":0,
        "res":0, "res_dup":0, "res_bad":0}

res_lock = threading.Lock()
scores = []
last_res = {"key": None, "t": 0.0}
cur_res = {"got":False, "mode":"solo", "seq":0, "score":0, "level":0, "lines":0, "secs":0}
SCORE_CSV = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scoreboard.csv")
STARTUP_LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "startup_error.log")

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
        print("[按键] 没找到本机 192.168.0.x 地址（源地址 %s）；按键若无效，请双击 双击启动.bat"
              % (auto_src or "未知"))
    nxt = time.time()
    while True:
        now = time.time()
        if kb_ev.is_set() or now >= nxt:
            kb_ev.clear()
            nxt = now + RESEND_S
            with kb_lock:
                bits = kb_bits
            try:
                s.sendto(kb_packet(bits), (FPGA_IP, FPGA_PORT))
                stat["kb"] += 1
            except Exception:
                pass
        else:
            time.sleep(0.002)


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
        elif typ == 4:
            res_handle(d)
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


def mmss(secs):
    return "%d:%02d" % (secs // 60, secs % 60)


def res_csv_migrate():
    if not os.path.exists(SCORE_CSV):
        return
    try:
        with open(SCORE_CSV, "r", encoding="utf-8") as f:
            lines = [ln.strip() for ln in f if ln.strip()]
        if not lines or lines[0].startswith("time,mode,"):
            return
        recs = []
        for ln in lines:
            p = ln.split(",")
            if len(p) == 6 and p[0] != "time":
                recs.append([p[0], "solo", p[1], p[2], p[3], p[4], p[5]])
        tmp = SCORE_CSV + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write("time,mode,seq,score,level,lines,seconds\n")
            for p in recs:
                f.write(",".join(p) + "\n")
        os.replace(tmp, SCORE_CSV)
        print("旧成绩已迁移为单人榜: %d 条" % len(recs))
    except Exception as e:
        print("[提示] 成绩迁移失败: %s" % e)


def res_csv_load():
    res_csv_migrate()
    try:
        with open(SCORE_CSV, "r", encoding="utf-8") as f:
            for ln in f:
                p = ln.strip().split(",")
                if len(p) != 7 or p[0] == "time":
                    continue
                mode = p[1].lower()
                if mode not in ("solo", "duo"):
                    mode = "solo"
                scores.append({"time":p[0], "mode":mode, "seq":int(p[2]), "score":int(p[3]),
                               "level":int(p[4]), "lines":int(p[5]), "secs":int(p[6])})
    except Exception:
        pass


def res_csv_append(rec):
    newfile = not os.path.exists(SCORE_CSV)
    try:
        with open(SCORE_CSV, "a", encoding="utf-8") as f:
            if newfile:
                f.write("time,mode,seq,score,level,lines,seconds\n")
            f.write("%s,%s,%d,%d,%d,%d,%d\n" % (rec["time"], rec["mode"], rec["seq"], rec["score"],
                                                rec["level"], rec["lines"], rec["secs"]))
    except Exception as e:
        print("[提示] 写成绩文件失败: %s" % e)


def top5_rows(mode):
    with res_lock:
        rows = [r for r in scores if r["mode"] == mode]
    rows = sorted(rows, key=lambda r: (-r["score"], -r["lines"], r["secs"], r["seq"]))[:5]
    if not rows:
        return "还没有成绩"
    out = []
    for i, r in enumerate(rows):
        out.append("%d. %06d  L%d  %3dL  %s" % (i+1, r["score"], r["level"], r["lines"], mmss(r["secs"])))
    return "\n".join(out)


def res_handle(d):
    if len(d) not in (13, 14):
        stat["res_bad"] += 1
        return
    if len(d) == 14:
        x = 0
        for b in d[3:13]:
            x ^= b
        if x != d[13]:
            stat["res_bad"] += 1
            return
        mode = "duo" if (d[4] & 1) else "solo"
        seq = d[3]
        score = (d[5] << 16) | (d[6] << 8) | d[7]
        level = d[8] & 7
        lines = (d[9] << 8) | d[10]
        secs = (d[11] << 8) | d[12]
    else:
        x = 0
        for b in d[3:12]:
            x ^= b
        if x != d[12]:
            stat["res_bad"] += 1
            return
        mode = "solo"
        seq = d[3]
        score = (d[4] << 16) | (d[5] << 8) | d[6]
        level = d[7] & 7
        lines = (d[8] << 8) | d[9]
        secs = (d[10] << 8) | d[11]
    rec = {"time": time.strftime("%Y-%m-%d %H:%M:%S"), "mode": mode, "seq": seq,
           "score": score, "level": level, "lines": lines, "secs": secs}
    now = time.time()
    key = (mode, seq)
    with res_lock:
        dup = (key == last_res["key"]) and ((now - last_res["t"]) < DEDUP_SEC)
        if dup:
            stat["res_dup"] += 1
        else:
            last_res["key"] = key
            last_res["t"] = now
            scores.append(rec)
            stat["res"] += 1
        cur_res.update(rec)
        cur_res["got"] = True
    if not dup:
        res_csv_append(rec)
        print("收到%s成绩: 第%d局  分数=%d  等级=%d  消行=%d  用时=%s" %
              ("双人" if mode == "duo" else "单人", seq, score, level, lines, mmss(secs)))
def main():
    # 先创建窗口句柄，确保启动失败时不会留下一个无界面的后台进程
    root = tk.Tk()
    root.withdraw()
    res_csv_load()
    print("成绩文件: %s" % SCORE_CSV)
    print("画面目标: 监听 %d 端口 <- FPGA" % LISTEN_PORT)
    print("按键目标: 发给 %s:%d（静态 ARP 由 双击启动.bat 自动设置）" % (FPGA_IP, FPGA_PORT))
    threading.Thread(target=rx_loop, daemon=True).start()
    start_listener()
    threading.Thread(target=tx_loop, daemon=True).start()

    root.title("Tetris  (画面 udp:%d  ->  按键 %s:%d)" % (LISTEN_PORT, FPGA_IP, FPGA_PORT))
    label = tk.Label(root, text="等待画面...", fg="white", bg="black", font=("Consolas", 12), anchor="w")
    label.pack(fill="x")
    cur_lab = None
    solo_lab = None
    duo_lab = None
    if SHOW_RANK and (root.winfo_screenwidth() >= W + RANK_W + 20):
        body = tk.Frame(root)
        body.pack()
        canvas = tk.Canvas(body, width=W, height=H, highlightthickness=0, bg="black")
        canvas.pack(side="left")
        panel = tk.Frame(body, width=RANK_W, height=H, bg="#101010")
        panel.pack(side="left", fill="y")
        panel.pack_propagate(False)
        tk.Label(panel, text="排行榜 Top5", fg="#00E5FF", bg="#101010",
                 font=("Consolas", 14, "bold")).pack(pady=(12, 8))
        cur_lab = tk.Label(panel, text="本局: 等待结束...", fg="white", bg="#101010",
                           font=("Consolas", 11), justify="left", anchor="w")
        cur_lab.pack(fill="x", padx=10, pady=(0, 12))
        tk.Label(panel, text="SOLO TOP5", fg="#00E5FF", bg="#101010",
                 font=("Consolas", 12, "bold"), anchor="w").pack(fill="x", padx=10, pady=(4, 2))
        solo_lab = tk.Label(panel, text=top5_rows("solo"), fg="#EEEEEE", bg="#101010",
                            font=("Consolas", 11), justify="left", anchor="nw")
        solo_lab.pack(fill="x", padx=10)
        tk.Label(panel, text="DUO TOP5", fg="#FF4DA6", bg="#101010",
                 font=("Consolas", 12, "bold"), anchor="w").pack(fill="x", padx=10, pady=(10, 2))
        duo_lab = tk.Label(panel, text=top5_rows("duo"), fg="#EEEEEE", bg="#101010",
                           font=("Consolas", 11), justify="left", anchor="nw")
        duo_lab.pack(fill="both", expand=True, padx=10)
        root.geometry("+0+0")
    else:
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
        with res_lock:
            solo_best = max([r["score"] for r in scores if r["mode"]=="solo"] or [0])
            duo_best = max([r["score"] for r in scores if r["mode"]=="duo"] or [0])
        label.config(text="pkt=%d 行包=%d pkt/s=%.0f 调色板包=%d 帧号=%d 未收到的行=%d | 按键:%s 已发按键包=%d | 成绩包=%d 本局=%d分 单高=%d 双高=%d"
                          % (stat["pkt"], stat["line"], stat["fps"], stat["pal"],
                             stat["last_frame"], missing, kb_text(), stat["kb"],
                             stat["res"], cur_res["score"], solo_best, duo_best))
        if cur_lab is not None:
            if cur_res["got"]:
                cur_lab.config(text="本局 %s: %d 分\n等级 %d   消行 %d\n用时 %s\n(第 %d 局)"
                                    % (cur_res["mode"].upper(), cur_res["score"], cur_res["level"],
                                       cur_res["lines"], mmss(cur_res["secs"]), cur_res["seq"]))
            solo_lab.config(text=top5_rows("solo"))
            duo_lab.config(text=top5_rows("duo"))
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
    print("请双击 tools\\双击启动.bat，它会自动安装 pillow 和 pynput")
    report_startup_error("Tetris PC 启动失败", "缺少图形依赖：%s" % _e)
    sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except Exception as _e:
        report_startup_error("Tetris PC 启动失败", "接收端启动失败：%s" % _e)
        sys.exit(1)
