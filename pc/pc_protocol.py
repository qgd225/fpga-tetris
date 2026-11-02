"""PC 显示与自测共用的 UDP 协议，不依赖图形库。"""
from dataclasses import dataclass
from struct import iter_unpack
try:
    import numpy as _np
except ImportError:
    _np=None
DECODER_BACKEND="NumPy" if _np is not None else "Python"

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


@dataclass(frozen=True)
class RGBChunkPacket:
    frame: int
    line: int
    x: int
    pixels: bytes


@dataclass(frozen=True)
class AudioPacket:
    session: int
    sequence: int
    index: int
    pcm: bytes


def decode_packet(data):
    if len(data) < 3 or data[:2] != MAGIC:
        raise ValueError("不是 Tetris 数据包")
    if data[2] == 6:
        if len(data)<22 or data[3]!=0:
            raise ValueError("音频包长度或版本错误")
        session,sequence,index=(int.from_bytes(data[i:i+4],"big") for i in (4,8,12))
        rate=int.from_bytes(data[16:18],"big");count=int.from_bytes(data[18:20],"big")
        if rate!=48000 or count!=240 or len(data)!=20+2*count:
            raise ValueError("音频格式或样本数错误")
        return AudioPacket(session,sequence,index,bytes(data[20:]))
    if data[2] == 4:
        if len(data) < 16 or len(data) > 1292 or (len(data) - 12) % 4 or data[3] != 0:
            raise ValueError("RGB游程包长度或版本错误")
        frame, line, x, width = (int.from_bytes(data[i:i+2], "big") for i in (4, 6, 8, 10))
        if line >= HEIGHT or not 1 <= width <= 1280 or x + width > WIDTH:
            raise ValueError("RGB分块坐标超出画面")
        counts = data[12::4]
        if 0 in counts or sum(counts) != width:
            raise ValueError("RGB游程长度或像素数错误")
        if _np is not None and len(counts)>=16:
            runs=_np.frombuffer(data,dtype=_np.uint8,offset=12).reshape(-1,4)
            pixels=(runs[:,1:].tobytes() if counts.count(1)==len(counts) else
                    _np.repeat(runs[:,1:],runs[:,0],axis=0).tobytes())
        else:
            pixels=b"".join(color*count for count,color in iter_unpack("B3s",data[12:]))
        return RGBChunkPacket(frame, line, x, bytes(pixels))
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


def rgb_chunk_packet(frame, line, x, pixels):
    """软件自测发送器，与RTL的4字节游程逐字节一致。"""
    width = len(pixels) // 3
    if len(pixels) % 3 or not 1 <= width <= 1280 or not 0 <= x <= WIDTH-width or not 0 <= line < HEIGHT or not 0 <= frame <= 65535:
        raise ValueError("RGB分块参数无效")
    out = bytearray(MAGIC + b"\x04\x00" + frame.to_bytes(2,"big") + line.to_bytes(2,"big") + x.to_bytes(2,"big") + width.to_bytes(2,"big"))
    start=0
    while start < width:
        count=1;color=pixels[start*3:start*3+3]
        while start+count < width and count < 255 and pixels[(start+count)*3:(start+count)*3+3] == color:
            count+=1
        out.extend(bytes([count])+color);start+=count
    if len(out)>1292:
        raise ValueError("RGB分块超过320段游程，请拆分发送")
    return bytes(out)


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


def rgb_line_packets(frame, line, pixels):
    """把完整RGB行按最多320段游程切包，与硬件分包边界一致。"""
    if len(pixels)!=WIDTH*3:
        raise ValueError("RGB整行长度错误")
    start=0;cursor=0;runs=0
    while cursor<WIDTH:
        if runs==320:
            yield rgb_chunk_packet(frame,line,start,pixels[start*3:cursor*3])
            start=cursor;runs=0
        color=pixels[cursor*3:cursor*3+3];end=cursor+1
        while end<WIDTH and end-cursor<255 and pixels[end*3:end*3+3]==color:
            end+=1
        cursor=end;runs+=1
    yield rgb_chunk_packet(frame,line,start,pixels[start*3:cursor*3])
