"""区分当前帧收集进度和上一完整观察区间的接收结果。"""
class FrameStats:
    def __init__(self):
        self.skip_first=True
        self.complete=0
        self.incomplete=0
        self.skipped=0
        self.last_missing=None

    def advance(self,old,new,missing):
        if old<0 or ((new-old)&65535)>=32768:
            self.skip_first=True
            return
        gap=(new-old)&65535
        if self.skip_first:
            self.skip_first=False
            return
        self.skipped+=max(0,gap-1)
        self.last_missing=missing
        if missing:
            self.incomplete+=1
        else:
            self.complete+=1
