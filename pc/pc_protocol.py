"""PC 显示与自测共用的 UDP 协议，不依赖图形库。"""
from dataclasses import dataclass

WIDTH, HEIGHT = 1280, 720
MAGIC = b"\xa5\x5a"


@dataclass(frozen=True)
class LinePacket:
    frame: int
    line: int
    pixels: bytes


@dataclass(frozen=True)
class PalettePacket:
    entries: tuple


def decode_packet(data):
    if len(data) < 3 or data[:2] != MAGIC:
        raise ValueError("不是 Tetris 数据包")
    if data[2] == 1:
        if len(data) != 7 + WIDTH:
            raise ValueError("行包长度错误")
        frame = int.from_bytes(data[3:5], "big")
        line = int.from_bytes(data[5:7], "big")
        if line >= HEIGHT:
            raise ValueError("行号超出画面")
        return LinePacket(frame, line, bytes(data[7:]))
    if data[2] == 2:
        if len(data) < 4 or not data[3] or len(data) != 4 + 4 * data[3]:
            raise ValueError("调色板包长度错误")
        entries = tuple((data[i], tuple(data[i + 1:i + 4])) for i in range(4, len(data), 4))
        if len({key for key, _ in entries}) != len(entries):
            raise ValueError("调色板编号重复")
        return PalettePacket(entries)
    raise ValueError("不支持的数据包类型")


def line_packet(frame=1, line=0):
    if not 0 <= frame <= 65535 or not 0 <= line < HEIGHT:
        raise ValueError("帧号或行号无效")
    return MAGIC + b"\x01" + frame.to_bytes(2, "big") + line.to_bytes(2, "big") + bytes(i % 56 for i in range(WIDTH))


def palette_packet():
    return MAGIC + bytes([2, 3, 0, 0, 0, 0, 1, 56, 182, 200, 2, 155, 107, 181])


def create_receiver(address, port):
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        try:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 8 * 1024 * 1024)
        except OSError:
            pass
        sock.bind((address, port))
        return sock
    except Exception:
        sock.close()
        raise
