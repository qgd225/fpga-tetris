// Lossless nine-nibble packing; output latency remains one clock.
`include "story_voice_config.vh"
module voice_adpcm_rom(input clk,input [16:0] address,output [3:0] code);
 `include "ui_voice_pack.vh"
 wire [13:0] word_address=address/9;
 wire [3:0] sub_address=address%9;
 wire [35:0] bank_data[0:VOICE_PACK_BANKS-1];
 reg [3:0] bank_q,sub_q;reg valid_q;
 genvar k;
 generate for(k=0;k<VOICE_PACK_BANKS;k=k+1)begin:packed_banks
  ui_voice_rom_bank #(.BANK(k),.WORDS(k==VOICE_PACK_BANKS-1?VOICE_PACK_LAST_WORDS:1024)) storage(.clk(clk),.address(word_address[9:0]),.data(bank_data[k]));
 end endgenerate
 always @(posedge clk)begin bank_q<=word_address[13:10];sub_q<=sub_address;valid_q<=address<`STORY_VOICE_DEPTH;end
 assign code=valid_q?(bank_data[bank_q]>>(sub_q*4)):4'd0;
endmodule
(* keep_hierarchy="yes" *)
module ui_voice_rom_bank #(parameter BANK=0,WORDS=1024)(input clk,input [9:0] address,output reg [35:0] data);
 localparam STYLE=WORDS<512?"distributed":"block";
 (* rom_style=STYLE *) reg [35:0] memory[0:WORDS-1];
 initial begin
  case(BANK)
   0:$readmemh("ui_voice_pack_00.mem",memory);
   1:$readmemh("ui_voice_pack_01.mem",memory);
   2:$readmemh("ui_voice_pack_02.mem",memory);
   3:$readmemh("ui_voice_pack_03.mem",memory);
   4:$readmemh("ui_voice_pack_04.mem",memory);
   5:$readmemh("ui_voice_pack_05.mem",memory);
   6:$readmemh("ui_voice_pack_06.mem",memory);
   7:$readmemh("ui_voice_pack_07.mem",memory);
   8:$readmemh("ui_voice_pack_08.mem",memory);
   9:$readmemh("ui_voice_pack_09.mem",memory);
   10:$readmemh("ui_voice_pack_10.mem",memory);
   11:$readmemh("ui_voice_pack_11.mem",memory);
   12:$readmemh("ui_voice_pack_12.mem",memory);
  endcase
 end
 always @(posedge clk)data<=memory[address];
endmodule
