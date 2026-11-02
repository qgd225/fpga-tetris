import random,unittest
from unittest.mock import patch
import pc_protocol as protocol
from pc_protocol import RGBChunkPacket,LinePacket,rgb_line_packets,decode_packet
from video_receiver import VideoReceiver

class VideoTests(unittest.TestCase):
    def test_fast_decoder_exact_and_fallback(self):
        rng=random.Random(20261102)
        for case in range(20):
            raw=rng.randbytes(3840) if case%2 else bytes((case,34,56))*1280
            packets=list(rgb_line_packets(65535,719,raw))
            accelerated=b''.join(decode_packet(p).pixels for p in packets)
            with patch.object(protocol,'_np',None):
                fallback=b''.join(decode_packet(p).pixels for p in packets)
            self.assertEqual(accelerated,raw)
            self.assertEqual(fallback,raw)
        packet=bytearray(packets[0]);packet[12]=0
        with self.assertRaises(ValueError):decode_packet(packet)

    def test_only_complete_immutable_latest_frame(self):
        v=VideoReceiver({0:(0,0,0)})
        for y in range(719):v.accept(RGBChunkPacket(1,y,0,bytes((1,2,3))*1280),now=1)
        self.assertIsNone(v.newest(0))
        v.accept(RGBChunkPacket(1,719,0,bytes((1,2,3))*1280),now=1)
        first=v.newest(0);self.assertEqual(first.pixels,bytes((1,2,3))*(1280*720))
        v.accept(RGBChunkPacket(2,0,0,bytes((4,5,6))*1280),now=1.01)
        self.assertEqual(first.pixels[:3],bytes((1,2,3)))
        self.assertIsNone(v.newest(first.serial))
        for y in range(1,720):v.accept(RGBChunkPacket(2,y,0,bytes((4,5,6))*1280),now=1.01)
        second=v.newest(0);self.assertEqual(second.frame,2)
        self.assertEqual(second.pixels,bytes((4,5,6))*(1280*720))
        self.assertFalse(v.accept(RGBChunkPacket(1,5,0,bytes(3840)),now=1.02))

    def test_coverage_duplicate_reset_and_legacy(self):
        v=VideoReceiver({1:(5,6,7)})
        p=RGBChunkPacket(65535,0,640,bytes(1920))
        v.accept(p,now=1);v.accept(p,now=1)
        self.assertEqual(v.missing,720)
        v.accept(RGBChunkPacket(65535,0,0,bytes(1920)),now=1)
        self.assertEqual(v.missing,719)
        v.accept(LinePacket(0,0,bytes([1])*1280),now=1.1)
        self.assertEqual(v.frame,0)
        self.assertEqual(v.rgb[:3840],bytes((5,6,7))*1280)
        v.accept(LinePacket(1000,0,bytes(1280)),now=1.2)
        self.assertFalse(v.accept(LinePacket(0,0,bytes(1280)),now=1.3))
        self.assertTrue(v.accept(LinePacket(0,0,bytes(1280)),now=2))

if __name__=='__main__':unittest.main()
