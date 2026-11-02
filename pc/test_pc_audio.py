import struct,time,unittest
from pc_audio import AudioBuffer,BLOCK
from pc_protocol import AudioPacket,decode_packet
from keyboard_controls import KeyState

class AudioTests(unittest.TestCase):
    def test_protocol(self):
        raw=bytes.fromhex('a55a0600')+struct.pack('>IIIHH',1,2,480,48000,240)+struct.pack('<240h',*range(240))
        p=decode_packet(raw)
        self.assertEqual((p.session,p.sequence,p.index),(1,2,480))
        self.assertEqual(struct.unpack('<240h',p.pcm),tuple(range(240)))
        for bad in [raw[:-1],raw+b'0',raw[:16]+struct.pack('>HH',44100,240)+raw[20:]]:
            with self.assertRaises(ValueError):decode_packet(bad)

    def test_gap_duplicate_restart_and_bounds(self):
        b=AudioBuffer();pcm=struct.pack('<240h',*([1234]*240))
        b.push(AudioPacket(1,0,0,pcm));b.push(AudioPacket(1,2,480,pcm))
        self.assertEqual(b.missing,240)
        before=len(b.samples);b.push(AudioPacket(1,1,240,pcm));self.assertEqual(len(b.samples),before)
        for i in range(3,12):b.push(AudioPacket(1,i,i*240,pcm))
        self.assertEqual(len(b.pull()),BLOCK*2)
        b.push(AudioPacket(2,0,0,pcm));self.assertEqual(len(b.samples),240)
        b.push(AudioPacket(1,99,1000,pcm));self.assertEqual(b.session,2)
        for i in range(1,100):b.push(AudioPacket(2,i,i*240,pcm))
        self.assertLessEqual(len(b.samples),6000)
        b.last=time.monotonic()-1;self.assertEqual(b.pull(),bytes(BLOCK*2))

    def test_power_cycle_reuses_session_after_idle(self):
        b=AudioBuffer();pcm=bytes(480)
        b.push(AudioPacket(1,100,24000,pcm))
        b.last=time.monotonic()-1
        b.push(AudioPacket(1,0,0,pcm))
        self.assertEqual(b.expected,240)
        self.assertEqual(len(b.samples),240)
        b.push(AudioPacket(1,1,240,pcm))
        self.assertEqual(b.expected,480)

    def test_cancel_is_sent_before_new_keys(self):
        s=KeyState();s.update(83,True);s.clear();s.update(68,True)
        token,p=s.snapshot();self.assertEqual(p,bytes.fromhex('a55a058000'))
        s.acknowledge(token,p);self.assertEqual(s.packet(),bytes.fromhex('a55a050200'))
        s.clear();token,p=s.snapshot();s.clear();s.acknowledge(token,p)
        self.assertTrue(s.pending_cancel)

if __name__=='__main__':unittest.main()
