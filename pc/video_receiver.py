"""接收线程独占组帧；界面只读取最新的不可变完整帧。"""
from dataclasses import dataclass
import threading
import time
from pc_protocol import WIDTH, HEIGHT, RGBChunkPacket, _np
from reception_stats import FrameStats

FULL_LINE=(1<<WIDTH)-1


@dataclass(frozen=True)
class VideoFrame:
    serial: int
    frame: int
    pixels: bytes


class VideoReceiver:
    def __init__(self,palette):
        self.rgb=bytearray(WIDTH*HEIGHT*3)
        self.coverage=[0]*HEIGHT
        self.line_ok=[0]*HEIGHT
        self.frame=-1
        self.missing=HEIGHT
        self.last=0
        self.published=False
        self.serial=0
        self.latest=None
        self.lock=threading.Lock()
        self.frame_stats=FrameStats()
        self.palette=bytearray(256*3)
        self.update_palette(palette.items())

    def update_palette(self,entries):
        for index,color in entries:
            self.palette[index*3:index*3+3]=bytes(color)

    def accept(self,packet,now=None):
        now=time.monotonic() if now is None else now
        if packet.frame!=self.frame:
            if self.frame>=0 and ((packet.frame-self.frame)&65535)>=32768 and now-self.last<.25:
                return False
            self.frame_stats.advance(self.frame,packet.frame,self.missing)
            self.frame=packet.frame
            self.coverage[:]=[0]*HEIGHT
            self.line_ok[:]=[0]*HEIGHT
            self.missing=HEIGHT
            self.published=False
        if isinstance(packet,RGBChunkPacket):
            x=packet.x;pixels=packet.pixels;width=len(pixels)//3
        else:
            x=0;width=WIDTH
            if _np is not None:
                table=_np.frombuffer(self.palette,dtype=_np.uint8).reshape(256,3)
                pixels=table[_np.frombuffer(packet.pixels,dtype=_np.uint8)].tobytes()
            else:
                pixels=b''.join(self.palette[i*3:i*3+3] for i in packet.pixels)
        offset=(packet.line*WIDTH+x)*3
        self.rgb[offset:offset+len(pixels)]=pixels
        mask=self.coverage[packet.line] | (((1<<width)-1)<<x)
        self.coverage[packet.line]=mask
        if mask==FULL_LINE and not self.line_ok[packet.line]:
            self.line_ok[packet.line]=1
            self.missing-=1
        self.last=now
        if self.missing==0 and not self.published:
            self.serial+=1
            # 复制发生在接收线程中，且不持有界面要用的锁。
            frame=VideoFrame(self.serial,self.frame,bytes(self.rgb))
            with self.lock:
                self.latest=frame
            self.published=True
        return True

    def newest(self,last_serial):
        with self.lock:
            frame=self.latest
        return frame if frame is not None and frame.serial!=last_serial else None
