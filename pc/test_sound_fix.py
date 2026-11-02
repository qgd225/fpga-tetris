import unittest,struct,time
from pc_audio import AudioBuffer,PCM_GAIN
from pc_protocol import AudioPacket
from reception_stats import FrameStats

class SoundFixTests(unittest.TestCase):
    def test_gain_and_clipping(self):
        b=AudioBuffer();b.samples.extend([-1024,-1,0,1,1024]*384);b.started=True;b.last=time.monotonic()
        out=struct.unpack('<240h',b.pull())
        self.assertEqual(out[:5],(-32768,-32,0,32,32767))
        self.assertEqual(PCM_GAIN,32)

    def test_real_capture_scale(self):
        b=AudioBuffer();b.samples.extend([126]*1920);b.started=True;b.last=time.monotonic()
        self.assertEqual(struct.unpack('<240h',b.pull()),(4032,)*240)

    def test_frame_progress_is_not_loss(self):
        s=FrameStats();s.advance(-1,100,720);s.advance(100,101,350)
        self.assertEqual((s.complete,s.incomplete),(0,0))
        s.advance(101,102,0);s.advance(102,104,2)
        self.assertEqual((s.complete,s.incomplete,s.skipped,s.last_missing),(1,1,1,2))
        s.advance(65535,0,0)
        self.assertEqual(s.complete,2)
        s.advance(1000,0,720);s.advance(0,1,123)
        self.assertEqual(s.incomplete,1)

if __name__=='__main__':unittest.main()
