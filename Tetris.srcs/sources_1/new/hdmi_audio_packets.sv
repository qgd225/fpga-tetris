// HDMI 包调度：所有状态均在像素域，48 kHz 仅为时钟使能。
// 16 深度 FIFO 吸收有效画面期间的音频；每个音频包装 4 个双声道采样。
module hdmi_audio_packets(
    input logic clk, reset, sample_ce,
    input logic [15:0] pcm,
    input logic packet_enable, frame_end,
    output logic [23:0] header,
    output logic [55:0] sub [3:0],
    output logic overflow
);
    logic [15:0] fifo [0:15];
    logic [3:0] wr, rd;
    logic [4:0] count;
    logic [1:0] info_pending;
    logic [7:0] packet_type;
    logic [7:0] next_frame, packet_frame;
    logic [23:0] samples [3:0][1:0];
    logic [23:0] audio_header, info_header, avi_header;
    wire [55:0] audio_sub [3:0], info_sub [3:0], avi_sub [3:0];
    // 每 48 个音频采样测量一次像素周期，N=6144。
    // CTS 随实际分数采样间隔变化，无需假定 PLL 恰为 74.25 MHz。
    logic [5:0] acr_samples;
    logic [19:0] acr_cycles, cts, packet_cts;
    logic acr_pending, acr_started;
    wire acr_due = sample_ce && acr_samples == 6'd47;
    wire take_acr = packet_enable && acr_pending;
    wire take_audio = packet_enable && !acr_pending && count >= 5'd4;
    wire push = sample_ce && (count < 5'd16 || take_audio);
    integer i;
    wire [1:0] zero_bits [3:0];
    for(genvar z=0;z<4;z=z+1) assign zero_bits[z]=2'b00;
    audio_sample_packet #(.SAMPLING_FREQUENCY(4'b0010), .WORD_LENGTH(4'b0010)) audio_packet(
        .frame_counter(packet_frame), .valid_bit(zero_bits),
        .user_data_bit(zero_bits), .audio_sample_word(samples),
        .audio_sample_word_present(4'b1111), .header(audio_header), .sub(audio_sub));
    audio_info_frame audio_info(.header(info_header), .sub(info_sub));
    auxiliary_video_information_info_frame #(.VIDEO_ID_CODE(7'd4), .IT_CONTENT(1'b1)) avi(
        .header(avi_header), .sub(avi_sub));
    always_comb begin
        header = 24'd0;
        for (int j=0;j<4;j=j+1) sub[j] = 56'd0;
        case (packet_type)
            8'h01: begin
                header = 24'h000001;
                for (int j=0;j<4;j=j+1)
                    sub[j] = {8'h00,8'h18,8'h00,packet_cts[7:0],packet_cts[15:8],4'd0,packet_cts[19:16],8'd0};
            end
            8'h02: begin header=audio_header; for(int j=0;j<4;j=j+1) sub[j]=audio_sub[j]; end
            8'h84: begin header=info_header; for(int j=0;j<4;j=j+1) sub[j]=info_sub[j]; end
            8'h82: begin header=avi_header; for(int j=0;j<4;j=j+1) sub[j]=avi_sub[j]; end
            default: begin end // 空包也持续发送，静音时不停止链路。
        endcase
    end
    always_ff @(posedge clk) begin
        if (reset) begin
            wr<=0; rd<=0; count<=0; overflow<=0;
            packet_type<=0; next_frame<=0; packet_frame<=0;
            info_pending<=2'b11;
            acr_samples<=0; acr_cycles<=0; cts<=20'd74219;
            packet_cts<=20'd74219; acr_pending<=0; acr_started<=0;
            for(i=0;i<4;i=i+1) begin samples[i][0]<=0; samples[i][1]<=0; end
        end else begin
            if(push) begin fifo[wr]<=pcm; wr<=wr+1'b1; end
            if(sample_ce && !push) overflow<=1;
            if(take_audio) rd<=rd+4'd4;
            case ({push,take_audio})
                2'b10: count<=count+5'd1;
                2'b01: count<=count-5'd4;
                2'b11: count<=count-5'd3;
                default: begin end
            endcase
            acr_cycles<=acr_cycles+1'b1;
            if(sample_ce) begin
                if(acr_samples==47) begin
                    acr_samples<=0; acr_cycles<=0;
                    if(acr_started) begin cts<=acr_cycles+1'b1; acr_pending<=1; end
                    acr_started<=1;
                end else acr_samples<=acr_samples+1'b1;
            end
            if(frame_end) info_pending<=2'b11;
            if(packet_enable) begin
                if(take_acr) begin
                    packet_type<=8'h01; packet_cts<=cts;
                    // 新的测量与发送同拍时保留下一次待发标志。
                    if(!acr_due) acr_pending<=0;
                end else if(take_audio) begin
                    packet_type<=8'h02; packet_frame<=next_frame;
                    next_frame<=next_frame==188 ? 8'd0 : next_frame+8'd4;
                    for(i=0;i<4;i=i+1) begin
                        samples[i][0]<={fifo[4'(rd+i)],8'd0};
                        samples[i][1]<={fifo[4'(rd+i)],8'd0};
                    end
                end else if(info_pending[0]) begin packet_type<=8'h84; info_pending[0]<=frame_end; end
                else if(info_pending[1]) begin packet_type<=8'h82; info_pending[1]<=frame_end; end
                else packet_type<=0;
            end
        end
    end
endmodule
