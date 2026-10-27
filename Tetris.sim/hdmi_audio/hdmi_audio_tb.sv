// 编码：本地工作区 GBK 无 BOM，Git 仓库 UTF-8。
`timescale 1ns/1ps
module hdmi_audio_tb;
    reg clk=0; always #5 clk=~clk;
    reg reset=1, menu_left=0;
    wire active,urgent;wire [4:0] event_id;wire [3:0] step_id,note_id;
    wire signed [15:0] fx;
    sound effects(.rhythm_reject(1'b0),.rhythm_expire(1'b0),.rhythm_recharge(1'b0),.rhythm_tick(1'b0),.core_half(1'b0),.core_online(1'b0),.debris_clear(1'b0),.Clk_74M(clk),.Reset_n(!reset),
        .over(1'b0),.clear(1'b0),.clr_n(3'd0),.lvl_up(1'b0),.danger1(1'b0),.danger2(1'b0),
        .sw_short(1'b0),.sw_long(1'b0),.menu_l(menu_left),.menu_r(1'b0),
        .land1(1'b0),.land2(1'b0),.lft1(1'b0),.rgt1(1'b0),.rot1(1'b0),
        .hard1(1'b0),.soft1(1'b0),.hold1(1'b0),.blk1(1'b0),
        .lft2(1'b0),.rgt2(1'b0),.rot2(1'b0),.hard2(1'b0),.soft2(1'b0),
        .hold2(1'b0),.blk2(1'b0),.blk_rot1(1'b0),.blk_rot2(1'b0),
        .cancel(1'b0),.event_id(event_id),.step_id(step_id),.note_id(note_id),.fx_urgent(urgent),.fx_active(active));
    wire ce; wire signed [15:0] pcm;
    audio_synth synth(.clk(clk),.reset_n(!reset),.sample_ce(ce),.active(active),.event_id(event_id),.step_id(step_id),.note_id(note_id),.pcm(fx));
    game_audio_pcm source(.clk(clk),.reset_n(!reset),.fx(fx),.bgm(16'sd0),.voice(16'sd0),
        .voice_busy(1'b0),.urgent(urgent),.force_silence(1'b0),.sample_ce(ce),.pcm(pcm));
    reg [15:0] expected_pcm[0:4095];integer submitted=0,decoded_samples=0;
    always @(posedge clk)begin
        if(reset)submitted<=0;
        else if(ce)begin expected_pcm[submitted]<=pcm;submitted<=submitted+1;end
    end
    reg [10:0] h=0,v=24;
    wire de = h>=259 && h<1539 && v>=24 && v<744;
    reg [23:0] rgb=0;
    always @(posedge clk) begin
        if(reset) begin h<=0;v<=24;rgb<=0;end
        else begin
            h<=h==1649?0:h+1;
            if(h==1649) v<=v==749?0:v+1;
            rgb<=de ? {5'd0,h,8'h5a}:24'd0;
        end
    end
    hdmi_av_encoder dut(.pixelclk(clk),.pixelclk5x(clk),.reset(reset),.rgb(rgb),.raw_h(h),.raw_v(v),
        .de(de),.hsync(h<40),.vsync(v<5),.sample_ce(ce),.pcm(pcm),
        .tmds_clk_p(),.tmds_clk_n(),.tmds_data_p(),.tmds_data_n());
    integer ticks=0,last_tick=0,n=0,audio_packets=0,acr_packets=0,info_packets=0,avi_packets=0;
    integer island_pixels=0, video_pixels=0, checks=0,positive_samples=0,negative_samples=0,silent_samples=0;
    integer packet_bit=0, k,j;
    reg [31:0] hb=0;
    reg [63:0] sb[3:0];
    reg [7:0] ecc;
    reg [19:0] cts;
    reg [10:0] h1,h2,h3,v1,v2,v3;
    reg de1,de2,de3;
    reg [23:0] rgb1,rgb2;
    reg [2:0] mode_last;
    integer line_video=0,line_island=0,frame_ends=0,warmup_lines=0;
    function automatic [7:0] decode_video(input [9:0] symbol);
        reg [7:0] q,b;
        begin
            q=symbol[9] ? ~symbol[7:0] : symbol[7:0];
            b[0]=q[0];
            for(int x=1;x<8;x=x+1) b[x]=symbol[8] ? q[x]^q[x-1] : ~(q[x]^q[x-1]);
            decode_video=b;
        end
    endfunction
    function automatic [9:0] terc4(input [3:0] nibble);
        case(nibble)
            0:terc4=10'b1010011100; 1:terc4=10'b1001100011;
            2:terc4=10'b1011100100; 3:terc4=10'b1011100010;
            4:terc4=10'b0101110001; 5:terc4=10'b0100011110;
            6:terc4=10'b0110001110; 7:terc4=10'b0100111100;
            8:terc4=10'b1011001100; 9:terc4=10'b0100111001;
            10:terc4=10'b0110011100; 11:terc4=10'b1011000110;
            12:terc4=10'b1010001110; 13:terc4=10'b1001110001;
            14:terc4=10'b0101100011; 15:terc4=10'b1011000011;
        endcase
    endfunction
    reg [11:0] island_last;
    always @(posedge clk) begin
        if(reset) begin
            h1<=0;h2<=0;h3<=0;v1<=0;v2<=0;v3<=0;
            de1<=0;de2<=0;de3<=0;rgb1<=0;rgb2<=0;mode_last<=0;island_last<=0;
        end else begin
            h1<=h;h2<=h1;h3<=h2;v1<=v;v2<=v1;v3<=v2;
            de1<=de;de2<=de1;de3<=de2;
            rgb1<=rgb;rgb2<=rgb1;
            mode_last<=dut.mode_q;island_last<=dut.island_q;
        end
    end

    function automatic [7:0] ecc_step(input [7:0] old,input bit b);
        ecc_step=(old>>1)^((old[0]^b)?8'h83:0);
    endfunction
    task automatic check(input bit ok,input string msg);
        checks=checks+1;
        if(!ok) $fatal(1,"FAILED %s h=%d v=%d",msg,h,v);
    endtask
    // 从编码器流水中的 12 位岛数据重组包，独立校验 BCH、采样与 ACR。
    always @(negedge clk) if(reset) begin
        decoded_samples=0;
        packet_bit=0;line_video=0;line_island=0;warmup_lines=0;last_tick=0;
    end else begin
        ticks=ticks+1;
        if(ce) begin
            if(last_tick!=0) check(ticks-last_tick==1546 || ticks-last_tick==1547,"sample spacing");
            last_tick=ticks;n=n+1;
            if(pcm>0) positive_samples=positive_samples+1;
            else if(pcm<0) negative_samples=negative_samples+1;
            else silent_samples=silent_samples+1;
            check(pcm>= -1024 && pcm<=1024,"mixed PCM bounded");
        end
        check(!dut.overflow,"FIFO overflow");
        if(de3) begin
            line_video=line_video+1;
            check(mode_last==1,"active video mode");
            check({decode_video(dut.symbols[2]),decode_video(dut.symbols[1]),decode_video(dut.symbols[0])}===rgb2,"video RGB alignment");
        end
        if(mode_last==3) begin
            line_island=line_island+1;
            for(int c=0;c<3;c=c+1) check(dut.symbols[c]===terc4(island_last[c*4+:4]),"TERC4 encoding");
        end
        if(h3==1539) begin
            if(warmup_lines>0) begin
                check(line_island==320,"320 island pixels per line");
                check(line_video==((v3>=24 && v3<744)?1280:0),"1280 active pixels per visible line");
            end
            line_video=0;line_island=0;warmup_lines=warmup_lines+1;
        end
        if(dut.packets.info_pending==3 && h==1539 && v==743) frame_ends=frame_ends+1;
        if(dut.mode_q==3) begin
            island_pixels=island_pixels+1;
            hb[packet_bit]=dut.island_q[2];
            for(j=0;j<4;j=j+1) begin
                sb[j][packet_bit*2]=dut.island_q[4+j];
                sb[j][packet_bit*2+1]=dut.island_q[8+j];
            end
            if(packet_bit==31) begin
                ecc=0;
                for(k=0;k<24;k=k+1) ecc=ecc_step(ecc,hb[k]);
                if(hb[31:24]!==ecc) $display("DEBUG hb=%h ecc=%h counter=%d mode=%d count=%d frame=%d",hb,ecc,dut.packet_counter,dut.mode_q,dut.packets.count,dut.packets.packet_frame);
                check(hb[31:24]===ecc,"header BCH");
                for(j=0;j<4;j=j+1) begin
                    ecc=0; for(k=0;k<56;k=k+1) ecc=ecc_step(ecc,sb[j][k]);
                    check(sb[j][63:56]===ecc,"subpacket BCH");
                end
                case(hb[7:0])
                    2: begin
                        audio_packets=audio_packets+1;
                        check(hb[11:8]==15,"four samples present");
                        for(j=0;j<4;j=j+1) begin
                            check(sb[j][23:0]==sb[j][47:24],"stereo duplicate");
                            check(sb[j][7:0]==0,"16-bit alignment");
                            check(decoded_samples<submitted && sb[j][23:8]===expected_pcm[decoded_samples],"exact mixed PCM sequence through FIFO and packets");
                            decoded_samples=decoded_samples+1;
                            check(((^sb[j][23:0]) ^ (^sb[j][51:48])) == 0,"left IEC parity");
                            check(((^sb[j][47:24]) ^ (^sb[j][55:52])) == 0,"right IEC parity");
                        end
                    end
                    1: begin
                        acr_packets=acr_packets+1;
                        cts={sb[0][11:8],sb[0][23:16],sb[0][31:24]};
                        check(cts==74218 || cts==74219,"CTS tracks real PLL");
                        check({sb[0][35:32],sb[0][47:40],sb[0][55:48]}==6144,"ACR N");
                    end
                    8'h84: info_packets=info_packets+1;
                    8'h82: avi_packets=avi_packets+1;
                    0: begin end
                    default: check(0,"unexpected packet type");
                endcase
                packet_bit=0;
            end else packet_bit=packet_bit+1;
        end
    end
    initial begin
        repeat(4) @(negedge clk);reset=0;
        repeat(10000) @(negedge clk);menu_left=1;
        @(negedge clk);menu_left=0;
        repeat(2500000) @(negedge clk);
        repeat(10000) @(negedge clk);
        check(n==64'(ticks)*48000/74218750,"exact sample count");
        check(positive_samples>0 && negative_samples>0 && silent_samples>0,"real game event reaches PCM");
        check(!active && pcm==0,"effect finishes in silence");
        check(audio_packets>=25,"audio transmitted");
        check(acr_packets>=1,"ACR transmitted");
        check(info_packets>=2 && avi_packets>=2,"InfoFrames repeated across frames");
        reset=1; repeat(4) @(negedge clk);check(pcm==0,"reset mutes");
        reset=0;repeat(5000) @(negedge clk);
        check(!dut.overflow,"reset recovery FIFO");
        $display("ALL PASS HDMI audio: %0d checks, %0d samples, %0d audio packets, %0d ACR",checks,n,audio_packets,acr_packets);
        $finish;
    end
endmodule
// 物理输出另由 Vivado 综合/实现检查；此仿真聚焦协议层，不模拟高速引脚。
module serdes_4b_10to1(input clkx5,input [9:0]datain_0,datain_1,datain_2,datain_3,
    output dataout_0_p,dataout_0_n,dataout_1_p,dataout_1_n,dataout_2_p,dataout_2_n,dataout_3_p,dataout_3_n);
endmodule
