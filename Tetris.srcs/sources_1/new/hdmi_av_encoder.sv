// 720p HDMI 编码器：保留现有 VGA 坐标，消隐区加入数据岛与保护带。
// blank_x=0 为每行有效画面结束；370 像素消隐可容纳 10 个 32 像素包。
module hdmi_av_encoder(
    input logic pixelclk, pixelclk5x, reset,
    input logic [23:0] rgb,
    input logic [10:0] raw_h, raw_v,
    input logic de, hsync, vsync,
    input logic sample_ce,
    input logic [15:0] pcm,
    output wire tmds_clk_p, tmds_clk_n,
    output wire [2:0] tmds_data_p, tmds_data_n
);
    wire [10:0] blank_x = raw_h >= 1539 ? raw_h - 11'd1539 : raw_h + 11'd111;
    // 复位可能落在跨行数据岛中间；等待完整消隐起点，禁止发送半个岛。
    logic island_ready = 1'b0;
    always_ff @(posedge pixelclk) begin
        if(reset) island_ready<=1'b0;
        else if(blank_x==0) island_ready<=1'b1;
    end
    wire island_now = island_ready && blank_x >= 14 && blank_x < 334;
    // 包头比包的首像素提前一个周期锁存，保证 BCH 从 bit 0 开始。
    wire packet_enable = island_ready && blank_x >= 13 && blank_x < 333 && 5'(blank_x-13)==0;
    wire video_guard_now = raw_h >= 257 && raw_h < 259 && raw_v>=24 && raw_v<744;
    wire video_pre_now = raw_h >= 249 && raw_h < 257 && raw_v>=24 && raw_v<744;
    wire island_guard_now = island_ready && ((blank_x>=12 && blank_x<14) || (blank_x>=334 && blank_x<336));
    wire island_pre_now = island_ready && blank_x>=4 && blank_x<12;
    wire [23:0] header;
    wire [55:0] sub [3:0];
    wire [8:0] packet_data;
    wire [4:0] packet_counter;
    wire overflow;
    hdmi_audio_packets packets(.clk(pixelclk),.reset(reset),.sample_ce(sample_ce),.pcm(pcm),
        .packet_enable(packet_enable),.frame_end(raw_h==1538 && raw_v==743),
        .header(header),.sub(sub),.overflow(overflow));
    packet_assembler assembler(.clk_pixel(pixelclk),.reset(reset),.data_island_period(island_now),
        .header(header),.sub(sub),.packet_data(packet_data),.counter(packet_counter));
    logic [2:0] mode_d, mode_q;
    logic [23:0] rgb_q;
    logic [5:0] control_d, control_q;
    logic [11:0] island_d, island_q;
    // frame 的 RGB 已寄存一拍，因此模式先延迟一拍再与 RGB 同拍锁存。
    // 同步、包位和模式一起流水，禁止只延迟视频 DE。
    always_ff @(posedge pixelclk) begin
        if(reset) begin
            mode_d<=0; mode_q<=0; rgb_q<=0;
            control_d<=0; control_q<=0; island_d<=0; island_q<=0;
        end else begin
            mode_d<=island_guard_now ? 3'd4 : island_now ? 3'd3 : video_guard_now ? 3'd2 : de ? 3'd1 : 3'd0;
            control_d<={{1'b0,island_pre_now},{1'b0,video_pre_now||island_pre_now},{vsync,hsync}};
            // HDMI 数据岛第 0 通道 bit 3：每个岛首像素为 0，后续为 1。
            island_d<={packet_data[8:1],(blank_x!=14),packet_data[0],vsync,hsync};
            mode_q<=mode_d; control_q<=control_d; island_q<=island_d;
            rgb_q<=rgb;
        end
    end
    wire [9:0] symbols [2:0];
    for(genvar c=0;c<3;c=c+1) begin: channels
        tmds_channel #(.CN(c)) channel_encoder(.clk_pixel(pixelclk),.video_data(rgb_q[8*c+:8]),
            .data_island_data(island_q[4*c+:4]),.control_data(control_q[2*c+:2]),.mode(mode_q),.tmds(symbols[c]));
    end
    // 继续使用原有 Artix-7 DDR 并串转换及差分输出，不新增引脚。
    serdes_4b_10to1 serializer(.clkx5(pixelclk5x),
        .datain_0(symbols[0]),.datain_1(symbols[1]),.datain_2(symbols[2]),.datain_3(10'b1111100000),
        .dataout_0_p(tmds_data_p[0]),.dataout_0_n(tmds_data_n[0]),
        .dataout_1_p(tmds_data_p[1]),.dataout_1_n(tmds_data_n[1]),
        .dataout_2_p(tmds_data_p[2]),.dataout_2_n(tmds_data_n[2]),
        .dataout_3_p(tmds_clk_p),.dataout_3_n(tmds_clk_n));
endmodule
