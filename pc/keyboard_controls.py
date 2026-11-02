"""双人键位与原子按键包；无图形、网络或键盘钩子依赖。"""

VK_BITS = {
    65: 0, 68: 1, 83: 2, 87: 3, 81: 4,  # P1: A D S W Q
    37: 8, 39: 9, 40: 10, 38: 11, 96: 12,  # P2: arrows, Num0
    13: 5, 101: 5, 123: 6, 105: 6, 27: 13,  # Enter/Num5, F12/Num9, Esc
}
BIT_NAMES = {0: 'P1 左', 1: 'P1 右', 2: 'P1 下落', 3: 'P1 旋转', 4: 'P1 HOLD',
             8: 'P2 左', 9: 'P2 右', 10: 'P2 下落', 11: 'P2 旋转', 12: 'P2 HOLD',
             5: '开始/暂停', 6: '复位', 13: '返回'}


def encode_keys(bits, cancelled=False):
    # A5 5A 05, P1 low 5 bits + shared switch/reset + cancel, P2 low 5 + back.
    if cancelled:
        return bytes((0xA5, 0x5A, 0x05, 0x80, 0))
    return bytes((0xA5, 0x5A, 0x05, bits & 0x7f, (bits >> 8) & 0x3f))


class KeyState:
    def __init__(self):
        self.pressed = set()
        self.cancelled = True
        self.cancel_generation=0
        self.pending_cancel=False

    def update(self, vk, down):
        if vk not in VK_BITS:
            return False
        if down:
            self.pressed.add(vk)
        else:
            self.pressed.discard(vk)
        self.cancelled = False
        return True

    def clear(self):
        self.cancel_generation+=1
        self.pending_cancel=True
        self.pressed.clear()
        self.cancelled = True

    @property
    def bits(self):
        bits = 0
        for vk in self.pressed:
            bits |= 1 << VK_BITS[vk]
        return bits

    def packet(self):
        return encode_keys(self.bits, self.cancelled or self.pending_cancel)

    def snapshot(self):
        return self.cancel_generation,self.packet()

    def acknowledge(self,generation,packet):
        if packet==encode_keys(0,True) and generation==self.cancel_generation:
            pending=self.pending_cancel
            self.pending_cancel=False
            return pending and not self.cancelled
        return False
