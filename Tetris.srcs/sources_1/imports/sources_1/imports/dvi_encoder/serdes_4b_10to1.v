//============================================================
// 导入模块：serdes_4b_10to1
// 本工程用途：TMDS 4:1 串行化与 DDR 输出。
//============================================================
module serdes_4b_10to1(
  clkx5,
  datain_0,
  datain_1,
  datain_2,
  datain_3,
  dataout_0_p,
  dataout_0_n,
  dataout_1_p,
  dataout_1_n,
  dataout_2_p,
  dataout_2_n,
  dataout_3_p,
  dataout_3_n 
);
  input        clkx5;        
  input  [9:0] datain_0;     
  input  [9:0] datain_1;     
  input  [9:0] datain_2;     
  input  [9:0] datain_3;     
  output       dataout_0_p;  
  output       dataout_0_n;  
  output       dataout_1_p;  
  output       dataout_1_n;  
  output       dataout_2_p;  
  output       dataout_2_n;  
  output       dataout_3_p;  
  output       dataout_3_n;  

  wire dataout_0_n;
  wire dataout_1_n;
  wire dataout_2_n;
  wire dataout_3_n;

  reg [2:0] TMDS_mod5 = 0;  // 模5计数器

  reg [4:0] TMDS_shift_0h = 0, TMDS_shift_0l = 0;
  reg [4:0] TMDS_shift_1h = 0, TMDS_shift_1l = 0;
  reg [4:0] TMDS_shift_2h = 0, TMDS_shift_2l = 0;
  reg [4:0] TMDS_shift_3h = 0, TMDS_shift_3l = 0;

  wire [4:0] TMDS_0_l = {datain_0[9],datain_0[7],datain_0[5],datain_0[3],datain_0[1]};
  wire [4:0] TMDS_0_h = {datain_0[8],datain_0[6],datain_0[4],datain_0[2],datain_0[0]};

  wire [4:0] TMDS_1_l = {datain_1[9],datain_1[7],datain_1[5],datain_1[3],datain_1[1]};
  wire [4:0] TMDS_1_h = {datain_1[8],datain_1[6],datain_1[4],datain_1[2],datain_1[0]};

  wire [4:0] TMDS_2_l = {datain_2[9],datain_2[7],datain_2[5],datain_2[3],datain_2[1]};
  wire [4:0] TMDS_2_h = {datain_2[8],datain_2[6],datain_2[4],datain_2[2],datain_2[0]};

  wire [4:0] TMDS_3_l = {datain_3[9],datain_3[7],datain_3[5],datain_3[3],datain_3[1]};
  wire [4:0] TMDS_3_h = {datain_3[8],datain_3[6],datain_3[4],datain_3[2],datain_3[0]};

  // 5倍速度移位发送数据
  always @(posedge clkx5)
  begin
    TMDS_mod5 <= (TMDS_mod5[2]) ? 3'd0 : TMDS_mod5 + 3'd1;
    TMDS_shift_0h  <= TMDS_mod5[2] ? TMDS_0_h : TMDS_shift_0h[4:1];
    TMDS_shift_0l  <= TMDS_mod5[2] ? TMDS_0_l : TMDS_shift_0l[4:1];
    TMDS_shift_1h  <= TMDS_mod5[2] ? TMDS_1_h : TMDS_shift_1h[4:1];
    TMDS_shift_1l  <= TMDS_mod5[2] ? TMDS_1_l : TMDS_shift_1l[4:1];
    TMDS_shift_2h  <= TMDS_mod5[2] ? TMDS_2_h : TMDS_shift_2h[4:1];
    TMDS_shift_2l  <= TMDS_mod5[2] ? TMDS_2_l : TMDS_shift_2l[4:1];
    TMDS_shift_3h  <= TMDS_mod5[2] ? TMDS_3_h : TMDS_shift_3h[4:1];
    TMDS_shift_3l  <= TMDS_mod5[2] ? TMDS_3_l : TMDS_shift_3l[4:1];
  end

ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),    
    .SRTYPE("SYNC") 
  ) ODDR_0 (
    .Q (dataout_0        ),
    .C (clkx5            ),
    .CE(1'b1             ),
    .D1(TMDS_shift_0h[0] ),
    .D2(TMDS_shift_0l[0] ),
    .R (1'b0             ),
    .S (1'b0             ) 
  );

  OBUFDS #(
    .IOSTANDARD("DEFAULT"), 
    .SLEW("SLOW")           
  ) OBUFDS_0 (
    .O  (dataout_0_p ),
    .OB (dataout_0_n ),
    .I  (dataout_0   ) 
  );

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),    
    .SRTYPE("SYNC") 
  ) ODDR_1 (
    .Q (dataout_1        ),
    .C (clkx5            ),
    .CE(1'b1             ),
    .D1(TMDS_shift_1h[0] ),
    .D2(TMDS_shift_1l[0] ),
    .R (1'b0             ),
    .S (1'b0             ) 
  );

  OBUFDS #(
    .IOSTANDARD("DEFAULT"), 
    .SLEW("SLOW")           
  ) OBUFDS_1 (
    .O  (dataout_1_p ),
    .OB (dataout_1_n ),
    .I  (dataout_1   ) 
  );

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),    
    .SRTYPE("SYNC") 
  ) ODDR_2 (
    .Q (dataout_2        ),
    .C (clkx5            ),
    .CE(1'b1             ),
    .D1(TMDS_shift_2h[0] ),
    .D2(TMDS_shift_2l[0] ),
    .R (1'b0             ),
    .S (1'b0             ) 
  );

  OBUFDS #(
    .IOSTANDARD("DEFAULT"), 
    .SLEW("SLOW")           
  ) OBUFDS_2 (
    .O  (dataout_2_p ),
    .OB (dataout_2_n ),
    .I  (dataout_2   ) 
  );

  ODDR #(
    .DDR_CLK_EDGE("SAME_EDGE"), 
    .INIT(1'b0),    
    .SRTYPE("SYNC") 
  ) ODDR_3 (
    .Q (dataout_3        ),
    .C (clkx5            ),
    .CE(1'b1             ),
    .D1(TMDS_shift_3h[0] ),
    .D2(TMDS_shift_3l[0] ),
    .R (1'b0             ),
    .S (1'b0             ) 
  );

  OBUFDS #(
    .IOSTANDARD("DEFAULT"), 
    .SLEW("SLOW")           
  ) OBUFDS_3 (
    .O  (dataout_3_p ),
    .OB (dataout_3_n ),
    .I  (dataout_3   ) 
  );


endmodule
