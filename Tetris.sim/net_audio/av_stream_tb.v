`timescale 1ns/1ps
module av_stream_tb;
 reg pixel_clk=0,phy_clk=0,reset_n=0;
 always #6.736 pixel_clk=~pixel_clk;
 always #4 phy_clk=~phy_clk;
 reg de=0;reg [10:0] x=0,y=0;reg [23:0] rgb=0;
 integer phase=0,sample_index=0;
 wire ce=reset_n && phase+48000>=74218750;
 always @(posedge pixel_clk)begin
  if(!reset_n)begin phase<=0;sample_index<=0;end
  else if(ce)begin phase<=phase+48000-74218750;sample_index<=sample_index+1;end
  else phase<=phase+48000;
 end
 net_screen_tx dut(.Clk_74M(pixel_clk),.Reset_n(reset_n),.por_n(reset_n),
 .audio_sample_ce(ce),.audio_pcm(sample_index[15:0]),
 .de(de),.hcounter(x),.vcounter(y),.rgb(rgb),.rgmii_rx_clk_i(phy_clk),.rgmii_rxd(4'd0),.rgmii_rxdv(1'b0));
 integer fd,frame,row,col;reg last_enable=0;
 always @(posedge phy_clk)begin
  #1;
  if(reset_n)begin
   if(dut.eth_udp_loopback_rgmii_inst.gmii_txen)$fwrite(fd,"%02x",dut.eth_udp_loopback_rgmii_inst.gmii_txd);
   else if(last_enable)$fwrite(fd,"\n");
   last_enable=dut.eth_udp_loopback_rgmii_inst.gmii_txen;
   if(dut.codec_overflow || dut.underflow || dut.audio_fault)begin $display("FAILED AV_OVERFLOW");$finish;end
  end
 end
 initial begin
  fd=$fopen("gmii_frames.hex","w");repeat(16)@(negedge pixel_clk);reset_n=1;repeat(64)@(negedge pixel_clk);
  for(frame=0;frame<2;frame=frame+1)for(row=0;row<750;row=row+1)for(col=0;col<1650;col=col+1)begin
   @(negedge pixel_clk);x=col;y=row;de=col<1280 && row<720;rgb={frame[7:0],row[7:0],col[9:2]};
  end
  @(negedge pixel_clk);de=0;repeat(3000)@(negedge pixel_clk);
  $fclose(fd);$display("ALL PASS AV_STREAM");$finish;
 end
endmodule
// Only board-specific DDR/PLL and unused receive blocks are mocked. The actual
// packetizer, CDC FIFOs, word serializer, IP/UDP formatter and CRC run unchanged.
module clk_wiz_0(input clk_in1,output clk_out1,locked);
 assign clk_out1=clk_in1;assign locked=1'b1;
endmodule
module rgmii_to_gmii(input reset,rgmii_rx_clk,input [3:0] rgmii_rxd,input rgmii_rxdv,
 output gmii_rx_clk,gmii_rxdv,gmii_rxer,output [7:0] gmii_rxd);
 assign gmii_rx_clk=rgmii_rx_clk;assign gmii_rxdv=0;assign gmii_rxer=0;assign gmii_rxd=0;
endmodule
module gmii_to_rgmii(input reset_n,gmii_tx_clk,input [7:0] gmii_txd,input gmii_txen,gmii_txer,
 output rgmii_tx_clk,rgmii_txen,output [3:0] rgmii_txd);
 assign rgmii_tx_clk=gmii_tx_clk;assign rgmii_txen=gmii_txen;assign rgmii_txd=gmii_txd[3:0];
endmodule
module eth_data_buf(input rst,wr_clk,rd_clk,input [7:0] din,input wr_en,rd_en,
 output [7:0] dout,output full,empty);
 assign dout=0;assign full=0;assign empty=1;
endmodule
module eth_msg_buf(input rst,clk,input [111:0] din,input wr_en,rd_en,
 output [111:0] dout,output full,empty,output [4:0] data_count);
 assign dout=0;assign full=0;assign empty=1;assign data_count=0;
endmodule
module eth_udp_rx_gmii(input reset_p,input [47:0] local_mac,input [31:0] local_ip,input [15:0] local_port,
 output clk125m_o,output [47:0] exter_mac,output [31:0] exter_ip,output [15:0] exter_port,rx_data_length,
 input data_overflow_i,output payload_valid_o,output [7:0] payload_dat_o,
 output one_pkt_done,pkt_error,debug_crc_check,input gmii_rx_clk,gmii_rxdv,input [7:0] gmii_rxd);
 assign clk125m_o=gmii_rx_clk;assign exter_mac=0;assign exter_ip=0;assign exter_port=0;assign rx_data_length=0;
 assign payload_valid_o=0;assign payload_dat_o=0;assign one_pkt_done=0;assign pkt_error=0;assign debug_crc_check=0;
endmodule
