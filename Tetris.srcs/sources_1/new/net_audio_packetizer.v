// 48kHz signed mono PCM. Packet: magic/version, session, sequence,
// first sample index, rate16/count16, then 240 little-endian int16 samples.
module net_audio_packetizer #(parameter SAMPLES=240)(
 input clk,reset_n,por_n,sample_ce,input [15:0] pcm,
 input grant,word_full,descriptor_full,
 output request,output [31:0] word_data,output word_write,
 output packet_ready,output [15:0] packet_length,output reg overflow);
 (* ram_style="block" *) reg [31:0] memory[0:511];
 localparam [15:0] SAMPLE_COUNT=SAMPLES;
 reg [9:0] wp,rp;
 reg half_valid;reg [15:0] first;
 reg [31:0] sample_index,read_index,sequence;
 reg [31:0] session=0;reg reset_d=0;
 reg [3:0] state;
 reg [7:0] remaining;
 reg [31:0] data;
 wire [9:0] used=wp-rp;
 wire recover=overflow && state==0;
 always @(posedge clk or negedge por_n) begin
  if(!por_n)begin session<=0;reset_d<=0;end
  else begin
   reset_d<=reset_n;
   if((reset_n && !reset_d) || recover)session<=session+1'b1;
  end
 end
 wire capture=sample_ce && half_valid && used<512 && !overflow;
 always @(posedge clk)begin
  if(capture)memory[wp[8:0]]<={first[7:0],first[15:8],pcm[7:0],pcm[15:8]};
  if(state==5)data<=memory[rp[8:0]];
 end
 assign request=used>=SAMPLES/2 && !overflow;
 assign packet_length=20+SAMPLES*2;
 assign word_write=grant && !word_full && (state>=1 && state<=4 || state==6 || state==8);
 assign packet_ready=grant && state==7 && !descriptor_full;
 assign word_data=state==1 ? 32'ha55a0600 : state==2 ? session :
                  state==3 ? sequence : state==4 ? read_index :
                  state==8 ? {16'd48000,SAMPLE_COUNT} : data;
 always @(posedge clk or negedge reset_n)begin
  if(!reset_n)begin wp<=0;rp<=0;half_valid<=0;first<=0;sample_index<=0;read_index<=0;sequence<=0;state<=0;remaining<=0;overflow<=0;end
  else if(recover)begin
   wp<=0;rp<=0;half_valid<=0;read_index<=sample_index;sequence<=0;overflow<=0;
  end else begin
   if(sample_ce)begin
    sample_index<=sample_index+1'b1;
    half_valid<=!half_valid;
    if(!half_valid)first<=pcm;
    else if(capture)wp<=wp+1'b1;
    else overflow<=1;
   end
   case(state)
    0:if(grant && request)begin state<=1;remaining<=SAMPLES/2;end
    1,2,3:if(word_write)state<=state+1'b1;
    4:if(word_write)state<=8;
    8:if(word_write)state<=5;
    5:state<=6;
    6:if(word_write)begin
     rp<=rp+1'b1;
     if(remaining==1)state<=7;
     else begin remaining<=remaining-1'b1;state<=5;end
    end
    7:if(packet_ready)begin state<=0;sequence<=sequence+1'b1;read_index<=read_index+SAMPLES;end
    default:state<=0;
   endcase
  end
 end
endmodule
