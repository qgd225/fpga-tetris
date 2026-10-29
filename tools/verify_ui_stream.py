"""Check actual simulated Ethernet CRC/IP/UDP/RGB and real localhost receive path."""
from pathlib import Path
import sys,hashlib,json,zlib,socket,threading,time,random
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'pc'))
from pc_protocol import decode_packet,RGBChunkPacket,rgb_chunk_packet,rgb_line_packets,create_receiver
import net_screen_view as view
OUT=ROOT/'temporary/new_ui_finish/stream'
def main():
 packets={i:[] for i in range(4)};images={i:bytearray(1280*720*3) for i in range(4)};coverage={i:[0]*720 for i in range(4)}
 for line in (OUT/'gmii_frames.hex').read_text('ascii').splitlines():
  wire=bytes.fromhex(line);assert wire[:8]==b'\x55'*7+b'\xd5';ether=wire[8:]
  assert zlib.crc32(ether[:-4])==int.from_bytes(ether[-4:],'little'),'CRC32'
  assert ether[12:14]==b'\x08\x00';ip=ether[14:34]
  total=sum(int.from_bytes(ip[j:j+2],'big') for j in range(0,20,2))
  while total>>16:total=(total&65535)+(total>>16)
  assert total==65535,'IPv4 checksum'
  length=int.from_bytes(ether[38:40],'big')-8;payload=ether[42:42+length];p=decode_packet(payload)
  assert isinstance(p,RGBChunkPacket) and p.frame in images and length<=1292
  start=(p.line*1280+p.x)*3;images[p.frame][start:start+len(p.pixels)]=p.pixels
  coverage[p.frame][p.line]|=((1<<(len(p.pixels)//3))-1)<<p.x;packets[p.frame].append(payload)
 for f in images:
  assert all(c==(1<<1280)-1 for c in coverage[f]),('missing',f)
  expected=bytes.fromhex(''.join((OUT/f'stream_{f}.mem').read_text('ascii').split()))
  assert images[f]==expected,('RGB mismatch',f)
 receiver=create_receiver('127.0.0.1',0);target=receiver.getsockname();view.stop_event.clear()
 worker=threading.Thread(target=view.rx_loop,args=(receiver,),daemon=True);worker.start()
 with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as sender:
  for f in images:
   for i,payload in enumerate(packets[f]):
    sender.sendto(payload,target)
    if i%24==0:time.sleep(.002)
   deadline=time.monotonic()+5
   while time.monotonic()<deadline and not(view.stat['last_frame']==f and all(view.line_ok)):time.sleep(.01)
   assert view.stat['last_frame']==f and all(view.line_ok),('UDP incomplete',f,sum(view.line_ok))
   assert view.rgb_buf==images[f],('UDP pixels',f)
  sender.sendto(packets[2][0],target);time.sleep(.03);assert view.stat['last_frame']==3
  # New connection epochs can start at any frame; now exercise the real wrap.
  with view.lock:view.stat['last_frame']=65534
  sender.sendto(rgb_chunk_packet(65535,0,0,b'\x12\x34\x56'*1280),target)
  sender.sendto(rgb_chunk_packet(0,0,0,b'\xab\xcd\xef'*1280),target);time.sleep(.05)
  assert view.stat['last_frame']==0 and view.rgb_buf[:3840]==b'\xab\xcd\xef'*1280
  sender.sendto(b'\xa5\x5a\x04\x00',target);time.sleep(.03);assert view.stat['invalid']==1
 view.stop_event.set();worker.join(1);assert not worker.is_alive()
 rng=random.Random(20261028)
 for case in range(40):
  raw=rng.randbytes(3840) if case%2 else bytes([case,31,62])*1280
  parts=list(rgb_line_packets(123,42,raw));decoded=[decode_packet(p) for p in parts]
  assert b''.join(p.pixels for p in decoded)==raw and max(map(len,parts))<=1292
 summary={'pass':True,'frames':4,'pixels':3686400,'packets':sum(map(len,packets.values())),'max_payload':max(len(p) for row in packets.values() for p in row),'CRC32_verified':True,'IPv4_checksum_verified':True,'real_localhost_receiver':True,'frame_reorder_and_wrap':True,'decoded_rgb_sha256':[hashlib.sha256(v).hexdigest() for v in images.values()], 'scope':'模拟GMII与本机UDP接收已验证；PHY、HDMI与实机收流待用户上板'}
 summary['final_source_sha256']={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'Tetris.srcs/sources_1/new/net_screen_tx.v',ROOT/'Tetris.srcs/sources_1/new/ui_rgb_packetizer.v',ROOT/'Tetris.srcs/sources_1/new/ui_async_fifo.v',ROOT/'Tetris.srcs/sources_1/imports/new/eth_udp_loopback_rgmii.v',ROOT/'pc/pc_protocol.py',ROOT/'pc/net_screen_view.py']}
 for name in ['net_screen_tx','ui_rgb_packetizer']:
  assert (ROOT/f'Tetris.srcs/sources_1/new/{name}.v').read_bytes()==(OUT/(name+'_next.v')).read_bytes(),'simulated HDL drift'
 (OUT/'final_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n','utf-8')
 print('ALL PASS RGB_STREAM_PC_CRC_UDP 4 FRAMES 3686400 PIXELS')
if __name__=='__main__':main()
