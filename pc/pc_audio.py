"""PCM包缓冲与Windows播放；音频线程独立于画面刷新。"""
from collections import deque
import ctypes as C
import struct
import threading
import time

RATE = 48000
BLOCK = 240
PCM_GAIN = 32  # 当前FPGA混音限幅为±1024，映射到16位播放动态范围。
_retained_devices = []


class AudioBuffer:
    def __init__(self):
        self.lock = threading.Lock()
        self.samples = deque()
        self.session = None
        self.expected = 0
        self.last = 0
        self.started = False
        self.missing = self.dropped = 0
        self.input_peak = 0

    def push(self, packet):
        now = time.monotonic()
        with self.lock:
            if packet.session != self.session or now-self.last > .25:
                if self.session is not None and ((packet.session-self.session)&0xffffffff) >= 0x80000000 and now-self.last < .25:
                    return
                self.samples.clear()
                self.started = False
                self.session = packet.session
                self.expected = packet.index
            gap = (packet.index-self.expected)&0xffffffff
            if gap >= 0x80000000:
                return  # 旧包／重复包，不能回放
            if gap > RATE//10:
                self.samples.clear()
                self.started = False
            elif gap:
                self.samples.extend([0]*gap)
                self.missing += gap
            decoded=struct.unpack('<%dh' % (len(packet.pcm)//2), packet.pcm)
            self.input_peak=max(self.input_peak,max(map(abs,decoded),default=0))
            self.samples.extend(decoded)
            self.expected = (packet.index+len(packet.pcm)//2)&0xffffffff
            self.last = now
            if len(self.samples) > RATE//8:
                excess = len(self.samples)-RATE//25
                for _ in range(excess):
                    self.samples.popleft()
                self.dropped += excess
                self.started = False

    def pull(self):
        with self.lock:
            if time.monotonic()-self.last > .25:
                self.samples.clear()
                self.started = False
            if not self.started:
                if len(self.samples) < RATE//25:
                    return bytes(BLOCK*2)
                self.started = True
            # 声卡与FPGA时钟不相同：高/低水位时每块温和调整一个样本。
            take = BLOCK + (1 if len(self.samples)>RATE//16 else -1 if len(self.samples)<RATE//50 else 0)
            if len(self.samples)<take:
                self.started = False
                return bytes(BLOCK*2)
            data=[self.samples.popleft() for _ in range(take)]
        if take != BLOCK:
            adjusted=[]
            for i in range(BLOCK):
                numerator=i*(take-1)
                j,f=divmod(numerator,BLOCK-1)
                adjusted.append((data[j]*(BLOCK-1-f)+data[min(j+1,take-1)]*f)//(BLOCK-1))
            data=adjusted
        data=[max(-32768,min(32767,v*PCM_GAIN)) for v in data]
        return struct.pack('<%dh' % BLOCK,*data)


class WaveOut:
    """固定寿命的四组缓冲；关闭时先reset，再解除header并关闭设备。"""
    class Format(C.Structure):
        _fields_=[('tag',C.c_ushort),('channels',C.c_ushort),('rate',C.c_uint),('bytes_sec',C.c_uint),('align',C.c_ushort),('bits',C.c_ushort),('extra',C.c_ushort)]
    class Header(C.Structure):
        _fields_=[('data',C.c_void_p),('length',C.c_uint),('recorded',C.c_uint),('user',C.c_size_t),('flags',C.c_uint),('loops',C.c_uint),('next',C.c_void_p),('reserved',C.c_size_t)]

    def __init__(self):
        self.api=C.WinDLL('winmm')
        self.handle=C.c_void_p()
        for name,args in {
            'waveOutOpen':[C.POINTER(C.c_void_p),C.c_uint,C.POINTER(self.Format),C.c_size_t,C.c_size_t,C.c_uint],
            'waveOutPrepareHeader':[C.c_void_p,C.POINTER(self.Header),C.c_uint],
            'waveOutWrite':[C.c_void_p,C.POINTER(self.Header),C.c_uint],
            'waveOutUnprepareHeader':[C.c_void_p,C.POINTER(self.Header),C.c_uint],
            'waveOutReset':[C.c_void_p], 'waveOutClose':[C.c_void_p],
        }.items():
            fn=getattr(self.api,name);fn.argtypes=args;fn.restype=C.c_uint
        fmt=self.Format(1,1,RATE,RATE*2,2,16,0)
        self.check(self.api.waveOutOpen(C.byref(self.handle),0xffffffff,C.byref(fmt),0,0,0))
        self.blocks=[]
        try:
            for _ in range(4):
                storage=C.create_string_buffer(BLOCK*2)
                header=self.Header(C.cast(storage,C.c_void_p),BLOCK*2,0,0,0,0,None,0)
                self.check(self.api.waveOutPrepareHeader(self.handle,C.byref(header),C.sizeof(header)))
                self.blocks.append((storage,header))
        except BaseException:
            self.close();raise

    @staticmethod
    def check(result):
        if result:
            raise OSError('Windows音频错误 '+str(result))

    def close(self):
        if not self.handle:
            return
        try:
            self.check(self.api.waveOutReset(self.handle))
            deadline=time.monotonic()+1
            while any(header.flags & 0x10 for _,header in self.blocks):
                if time.monotonic()>deadline:
                    raise OSError("音频设备未归还缓冲区")
                time.sleep(.002)
            for storage,header in self.blocks:
                self.check(self.api.waveOutUnprepareHeader(self.handle,C.byref(header),C.sizeof(header)))
            self.check(self.api.waveOutClose(self.handle))
            self.handle=C.c_void_p()
        except BaseException:
            # 驱动未释放时保留Python内存，禁止让设备访问已释放的header/PCM。
            _retained_devices.append(self)
            raise

    def run(self,buffer,stop):
        try:
            while not stop.is_set():
                available=False
                for storage,header in self.blocks:
                    if not header.flags & 0x10:  # WHDR_INQUEUE
                        C.memmove(storage,buffer.pull(),BLOCK*2)
                        self.check(self.api.waveOutWrite(self.handle,C.byref(header),C.sizeof(header)))
                        available=True
                stop.wait(.001 if available else .002)
        finally:
            self.close()


def play(buffer,stop,status):
    try:
        from pc_runtime import high_resolution_timer
        with high_resolution_timer():
            WaveOut().run(buffer,stop)
    except (OSError,AttributeError) as exc:
        status['audio_error']='音频播放不可用：'+str(exc)
