module Playfield(
    input Clk_74M,
    input Reset_n,
    input [10:0]hcounter,
    input [10:0]vcounter,
    input left_p_flag,
    input right_p_flag,
    input drop_r_flag,
    input drop_en,
    input rotate_p_flag,
    input switch_r_flag,
    input Idle,
    input Playing,
    input Stop,
    input Finalize,
    input hold_p_flag,
    input [19:0]score,
    input [13:0]time_sec,
    input duo,
    input left_p_flag2,
    input right_p_flag2,
    input drop_r_flag2,
    input drop_en2,
    input rotate_p_flag2,
    input hold_p_flag2,

    output reg [479:0]state,
    output reg Piece,
    output reg ghost,
    output reg [4:0]C_num,
    output reg [4:0]R_num,
    output reg over,
    output wire clear_time,
    output wire clear_pulse,
    output reg clear_t_t,
    output reg clear_t,
    output reg [4:0]c_clear,
    output reg [2:0]type_t,
    output reg [2:0]type,
    output reg clear,
    output reg [4:0]clear_row,
    output wire [19:0]cc_d,
    output wire [19:0]rr_d,
    output reg lock_t,
    output wire lock_we,
    output wire [1:0]lock_idx,
    output reg [2:0]type_d,
    output reg en_hold,
    output reg [2:0]hold_type,
    output reg [2:0]speed_level,
    output wire land_we,
    output reg [19:0]line_t,
    output reg clear_flash,
    output reg Piece2,
    output reg ghost2,
    output wire [4:0]C_num2,
    output wire [4:0]R_num2,
    output wire [2:0]type2_out,
    output wire [19:0]cc_d2,
    output wire [19:0]rr_d2,
    output wire [2:0]type_d2_out,
    output wire lock_we2,
    output wire [1:0]lock_idx2,
    output wire land_we2,
    output wire [2:0]type_t2_out
    );

//============================================================
//    参数
//============================================================
    parameter MCNT = 74_250_000;
    parameter MCNT_LAND = 20_000_000;
    parameter MCNT_Drop = 74_250_000 - 1;//自动下落时间

    parameter [19:0]LV1_TH = 20'd4;
    parameter [19:0]LV2_TH = 20'd15;
    parameter [19:0]LV3_TH = 20'd35;
    parameter [19:0]LV4_TH = 20'd70;
    parameter [19:0]LV5_TH = 20'd150;
    parameter [19:0]LV6_TH = 20'd300;
    parameter [19:0]LV7_TH = 20'd600;

    parameter [13:0]TIME_LV1 = 14'd20;
    parameter [13:0]TIME_LV2 = 14'd60;
    parameter [13:0]TIME_LV3 = 14'd120;
    parameter [13:0]TIME_LV4 = 14'd200;
    parameter [13:0]TIME_LV5 = 14'd300;
    parameter [13:0]TIME_LV6 = 14'd440;
    parameter [13:0]TIME_LV7 = 14'd600;
    parameter CLEAR_STEP = 6_311_250;//85ms

    wire [4:0]COL = duo ? 5'd24 : 5'd20;

    //    双人模式时间阈值(放宽)
    parameter [13:0]TIME_LV1_D = 14'd40;
    parameter [13:0]TIME_LV2_D = 14'd120;
    parameter [13:0]TIME_LV3_D = 14'd240;
    parameter [13:0]TIME_LV4_D = 14'd400;
    parameter [13:0]TIME_LV5_D = 14'd600;
    parameter [13:0]TIME_LV6_D = 14'd880;
    parameter [13:0]TIME_LV7_D = 14'd1200;

    //    出生列: 双人用 24 列的三等分点
    wire [4:0]SPAWN_C1 = duo ? 5'd8  : 5'd9;
    wire [4:0]SPAWN_C2 = duo ? 5'd16 : 5'd9;

//============================================================
//    信号声明
//============================================================
//    方块位置信息
    reg [1:0]rot;
    reg [4:0]counter_c;
    reg [4:0]counter_r;
    reg [4:0]cc;
    reg [5:0]rr;
    reg land;
    reg boundary_collision_left;
    reg boundary_collision_right;
    reg touch_top;
    reg [5:0]rr_g;

//    形状 ROM
    wire [31:0]Tetromino_dout;
    reg  [4:0]Tetromino_addr;
    reg [4:0]Tetromino_addr1;
    wire [31:0]Tetromino_dout1;
    reg  [4:0]counter_ghost_r_t;

//    落地与锁定
    wire land_pulse;
    reg [1:0]lock_cnt;
    reg [4:0]cc_t [0:3];
    reg [4:0]rr_t [0:3];
    reg [24:0]counter_land;
    reg [24:0]lock_counter;

//    消行
    reg [19:0]line;
    reg clear_d;
    wire [4:0]d_clear = line[0] + line[1] + line[2] + line[3] + line[4] + line[5] + line[6] + line[7] + line[8] +
    line[9] + line[10] + line[11] + line[12] + line[13] + line[14] + line[15] + line[16] + line[17] + line[18] + line[19];
    reg [3:0]clear_tick;
    reg [24:0]clear_cnt;
    wire clear_down = (!clear_time) && (clear_d);
    reg [29:0]Drop;
    reg clear_t_d;
    reg [2:0]cl_tick;
   reg [19:0]line_d;
    reg [3:0]cl_stop;
    wire clear_step;

//    按键与下落
    reg [26:0]counter;
    reg drop_r_t;
    wire drop_hold  = (counter == MCNT) && (drop_r_t);
    wire drop_r = (drop_r_t) && (drop_r_flag);
    reg [26:0]counter_drop;

//    旋转
    reg en_rotate;
    reg [5:0] cc_r, rr_r;
    wire [7:0]weiyibiao_dout;
    wire [4:0]weiyibiao_addr;
    wire [3:0]ddc = weiyibiao_dout[7:4];
    wire [3:0]ddr = weiyibiao_dout[3:0];
    wire [10:0] ddc_ext = {{7{ddc[3]}}, ddc};
    wire [10:0] ddr_ext = {{7{ddr[3]}}, ddr};
    reg rot_block;

//    随机出块
    reg [31:0]rnd;
    reg [15:0]rnd_cnt;
    wire rnd_fb  = rnd[31] ^ rnd[21] ^ rnd[1] ^ rnd[0];
    wire rnd_stir = Idle ? (rnd_cnt[13] ^ rnd_cnt[7] ^ rnd_cnt[3]) : 1'b0;
    wire rnd_fb_eff = rnd_fb ^ rnd_stir;
    wire [31:0]rnd_n1 = {rnd[30:0], rnd_fb_eff};
    wire [3:0]rnd4t = rnd[3:0] ^ rnd_cnt[3:0];
    wire [3:0]rnd4n = rnd[7:4] ^ rnd_cnt[7:4];
    wire [3:0]r7t = (rnd4t >= 4'd7) ? (rnd4t - 4'd7) : rnd4t;
    wire [3:0]r7n = (rnd4n >= 4'd7) ? (rnd4n - 4'd7) : rnd4n;
    wire [2:0]rnd_type_t = (r7t >= 4'd7) ? (r7t - 4'd7) : r7t[2:0];
    wire [2:0]rnd_type_n = (r7n >= 4'd7) ? (r7n - 4'd7) : r7n[2:0];
    wire [3:0]rnd4t1 = rnd_n1[3:0] ^ rnd_cnt[3:0];
    wire [3:0]rnd4n1 = rnd_n1[7:4] ^ rnd_cnt[7:4];
    wire [3:0]r7t1 = (rnd4t1 >= 4'd7) ? (rnd4t1 - 4'd7) : rnd4t1;
    wire [3:0]r7n1 = (rnd4n1 >= 4'd7) ? (rnd4n1 - 4'd7) : rnd4n1;
    wire [2:0]rnd_type_t1 = (r7t1 >= 4'd7) ? (r7t1 - 4'd7) : r7t1[2:0];
    wire [2:0]rnd_type_n1 = (r7n1 >= 4'd7) ? (r7n1 - 4'd7) : r7n1[2:0];

//    Hold
    reg en_hold_t;
    wire hold_up = !en_hold_t && en_hold;
    wire hold_down = en_hold_t && !en_hold;

//    P2 方块位置信息
    reg [1:0]rot2;
    reg [4:0]counter_c2;
    reg [4:0]counter_r2;
    reg [4:0]cc2;
    reg [5:0]rr2;
    reg land2;
    reg boundary_collision_left2;
    reg boundary_collision_right2;
    reg touch_top2;
    reg [5:0]rr_g2;
    wire [31:0]Tetromino_dout2;
    reg  [4:0]Tetromino_addr2;
    reg [4:0]Tetromino_addr3;
    wire [31:0]Tetromino_dout3;
    reg  [4:0]counter_ghost_r_t2;
    wire land_pulse2;
    wire land_pulse_t2;
    reg [1:0]lock_cnt2;
    reg [4:0]cc_t2 [0:3];
    reg [4:0]rr_t2 [0:3];
    reg [24:0]counter_land2;
    reg [24:0]lock_counter2;
    reg [2:0]type2;
    reg [2:0]type_t2;
    reg [2:0]type_d2;
    reg [26:0]counter2;
    reg drop_r_t2;
    reg [26:0]counter_drop2;
    reg en_rotate2;
    reg [5:0]cc_r2, rr_r2;
    reg rot_block2;
    reg en_hold2;
    reg en_hold_t2;
    wire hold_up2 = !en_hold_t2 && en_hold2;
    wire hold_down2 = en_hold_t2 && !en_hold2;
    reg lock_t2;
    wire [9:0]douta_dummy2;

//    Duo: 互撞/顶住 + 通用幽灵扫描(本轮新增)
    reg  other_down_hold;
    reg  other_down_hold2;
    reg  [5:0]gc1, gr1;
    reg  [5:0]gc2, gr2;
    reg  ghost_blocked1, ghost_blk_state1, ghost_blk_other1;
    reg  ghost_blocked2, ghost_blk_state2, ghost_blk_other2;
    reg  [4:0]ghost_scan_r, ghost_scan_r2;
    reg  ghost_done, ghost_done2;
    reg  ghost_blk_oth, ghost_blk_oth2;
    reg  [4:0]counter_r_d1, counter_r2_d1;
    reg  [15:0]sig_p1_d, sig_p2_d;
    integer jg1;
    integer jg2;
    wire [15:0]sig_p1 = {duo, counter_c[4:0], counter_r[4:0], type[2:0], rot[1:0]};
    wire [15:0]sig_p2 = {duo, counter_c2[4:0], counter_r2[4:0], type2[2:0], rot2[1:0]};
    wire other_moved1 = (sig_p2 != sig_p2_d);
    wire other_moved2 = (sig_p1 != sig_p1_d);
    wire new_piece1 = (counter_r == 5'd0) && (counter_r_d1 != 5'd0);
    wire new_piece2 = (counter_r2 == 5'd0) && (counter_r2_d1 != 5'd0);
    wire field_chg = lock_we || lock_we2 || clear_pulse || clear_t_t || (clear_time && (!clear_t) && (!clear_pulse));
    wire ghost_restart1 = en_rotate || left_p_flag || right_p_flag || new_piece1 || hold_up || (Finalize && switch_r_flag) || clear_down || field_chg || (duo && other_moved1);
    wire ghost_restart2 = en_rotate2 || left_p_flag2 || right_p_flag2 || new_piece2 || hold_up2 || (Finalize && switch_r_flag) || clear_down || field_chg || (duo && other_moved2);

//    P2 独立信号(修复: 原克隆漏改, 误用 P1 信号)
    wire drop_hold2;
    wire drop_r2;
    wire [7:0]weiyibiao_dout2;
    wire [4:0]weiyibiao_addr2;
    wire [3:0]ddc2;
    wire [3:0]ddr2;
    wire [10:0]ddc_ext2;
    wire [10:0]ddr_ext2;

//    循环变量
    integer i;
    integer y;
    integer m;
    integer c;
    integer o;
    integer p;
    integer k;
    integer i2;

    //    行字: row_w[m] = 第 m 行 24 列(纯连线, 只作写路径的源与整行判满)
    wire [23:0]row_w [0:19];
    //    整行判满用的列掩码(单机只看 0..19 列)
    wire [23:0]full_mask = duo ? 24'hFFFFFF : 24'h000FFFFF;

    //    对方方块 4 格绝对坐标(公共连线)
    wire [5:0] oc2_0 = counter_c2 + { { 7{Tetromino_dout2[7]} }, Tetromino_dout2[7-:4] };
    wire [5:0] or2_0 = counter_r2 + { { 7{Tetromino_dout2[3]} }, Tetromino_dout2[3-:4] };
    wire [5:0] oc2_1 = counter_c2 + { { 7{Tetromino_dout2[15]} }, Tetromino_dout2[15-:4] };
    wire [5:0] or2_1 = counter_r2 + { { 7{Tetromino_dout2[11]} }, Tetromino_dout2[11-:4] };
    wire [5:0] oc2_2 = counter_c2 + { { 7{Tetromino_dout2[23]} }, Tetromino_dout2[23-:4] };
    wire [5:0] or2_2 = counter_r2 + { { 7{Tetromino_dout2[19]} }, Tetromino_dout2[19-:4] };
    wire [5:0] oc2_3 = counter_c2 + { { 7{Tetromino_dout2[31]} }, Tetromino_dout2[31-:4] };
    wire [5:0] or2_3 = counter_r2 + { { 7{Tetromino_dout2[27]} }, Tetromino_dout2[27-:4] };
    wire [5:0] oc1_0 = counter_c + { { 7{Tetromino_dout[7]} }, Tetromino_dout[7-:4] };
    wire [5:0] or1_0 = counter_r + { { 7{Tetromino_dout[3]} }, Tetromino_dout[3-:4] };
    wire [5:0] oc1_1 = counter_c + { { 7{Tetromino_dout[15]} }, Tetromino_dout[15-:4] };
    wire [5:0] or1_1 = counter_r + { { 7{Tetromino_dout[11]} }, Tetromino_dout[11-:4] };
    wire [5:0] oc1_2 = counter_c + { { 7{Tetromino_dout[23]} }, Tetromino_dout[23-:4] };
    wire [5:0] or1_2 = counter_r + { { 7{Tetromino_dout[19]} }, Tetromino_dout[19-:4] };
    wire [5:0] oc1_3 = counter_c + { { 7{Tetromino_dout[31]} }, Tetromino_dout[31-:4] };
    wire [5:0] or1_3 = counter_r + { { 7{Tetromino_dout[27]} }, Tetromino_dout[27-:4] };
    genvar gw;
    generate for(gw = 0; gw < 20; gw = gw + 1)begin : gen_roww
        assign row_w[gw] = { state[23*20+gw], state[22*20+gw], state[21*20+gw], state[20*20+gw],
                             state[19*20+gw], state[18*20+gw], state[17*20+gw], state[16*20+gw],
                             state[15*20+gw], state[14*20+gw], state[13*20+gw], state[12*20+gw],
                             state[11*20+gw], state[10*20+gw], state[9*20+gw],  state[8*20+gw],
                             state[7*20+gw],  state[6*20+gw],  state[5*20+gw],  state[4*20+gw],
                             state[3*20+gw],  state[2*20+gw],  state[1*20+gw],  state[0*20+gw] };
    end endgenerate
    integer o2;
    integer p2;
    integer k2;

//============================================================
//    提取方块信息
//============================================================
    Tetromino Tetromino_inst0(
        .clka(Clk_74M),
        .addra(Tetromino_addr),
        .douta(Tetromino_dout)
    );

//    P1 运动方块显示与判定: 形状查表 / 落底 / 左右边界 / 顶到 / 幽灵 / 与对方运动方块互撞
    always@(*)begin
        Tetromino_addr = {type[2:0], rot[1:0]};
        Piece = 1'b0;
        land = 1'b0;
        boundary_collision_left = 1'b0;
        boundary_collision_right = 1'b0;
        ghost = 1'b0;
        touch_top = 1'b0;
        other_down_hold = 1'b0;
        if(Idle || Finalize)begin
             Piece = 1'b0;
             ghost = 1'b0;
        end
        else
        for(i = 0; i < 4; i = i + 1)begin
            cc = counter_c + { { 7{Tetromino_dout[i*8+7]} }, Tetromino_dout[(i*8+7)-:4] };
            rr = counter_r + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
            //    与对方运动方块互撞: 左右阻挡 / 下行顶住(不算落底) / 重合
            if(duo)begin
                if(or2_0 == rr)begin
                    if((cc > 0) && (oc2_0 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_0 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_0 == cc) touch_top = 1'b1;
                end
                if((oc2_0 == cc) && (or2_0 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && row_w[rr + 6'd1][cc]))
                other_down_hold = 1'b1;
                if(or2_1 == rr)begin
                    if((cc > 0) && (oc2_1 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_1 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_1 == cc) touch_top = 1'b1;
                end
                if((oc2_1 == cc) && (or2_1 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && row_w[rr + 6'd1][cc]))
                other_down_hold = 1'b1;
                if(or2_2 == rr)begin
                    if((cc > 0) && (oc2_2 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_2 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_2 == cc) touch_top = 1'b1;
                end
                if((oc2_2 == cc) && (or2_2 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && row_w[rr + 6'd1][cc]))
                other_down_hold = 1'b1;
                if(or2_3 == rr)begin
                    if((cc > 0) && (oc2_3 == (cc - 6'd1))) boundary_collision_left = 1'b1;
                    if(oc2_3 == (cc + 6'd1)) boundary_collision_right = 1'b1;
                    if(oc2_3 == cc) touch_top = 1'b1;
                end
                if((oc2_3 == cc) && (or2_3 == (rr + 6'd1)) && (rr < 11'd19) && !((cc <= (COL - 1'b1)) && row_w[rr + 6'd1][cc]))
                other_down_hold = 1'b1;
            end
            if(rr == 19 || ((cc <= (COL - 1'b1)) && (rr < 19) && row_w[rr + 6'd1][cc]))//落底检测
            land = 1'b1;
            if(cc == 0 || ((cc > 0) && (cc <= (COL - 1'b1)) && (rr < 11'd20) && row_w[rr][cc - 6'd1]))//左边界碰撞检测
            boundary_collision_left = 1'b1;
            if(cc >= (COL - 1'b1) || ((cc < (COL - 1'b1)) && (rr < 11'd20) && row_w[rr][cc + 6'd1]))//右边界碰撞检测
            boundary_collision_right = 1'b1;
            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc) && (R_num == rr) && !rr[5]) //正在运动方块
            Piece = 1'b1;
            if((!rr[5]) && (cc <= (COL - 1'b1)) && (rr <= 11'd19) && row_w[rr][cc])//和已锁方块重叠=顶到
            touch_top = 1'b1;
            rr_g = counter_ghost_r_t + { { 7{Tetromino_dout[i*8+3]} }, Tetromino_dout[(i*8+3)-:4] };
            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc) && (R_num == rr_g) && !rr_g[5] && (!ghost_blk_oth) && ghost_done && (!clear_time) && (counter_ghost_r_t > (counter_r + 5'd4)))
            ghost = 1'b1;
        end
    end

//============================================================
//    划区
//============================================================
    //    横纵拆开: 列只看 hcounter, 行只看 vcounter; 无命中给哨兵 24
    always@(*)begin : blk1
        integer o;
        C_num = 5'd24;
        for(o = 0; o < 24; o = o + 1)
        if((o < COL) && hcounter >= (321 + 32*o) && hcounter < (351 + 32*o))
        C_num = o[4:0];
    end

//    行编号: 只看 vcounter, 无命中给哨兵 24
    always@(*)begin : blk2
        integer p;
        R_num = 5'd24;
        for(p = 0; p < 20; p = p + 1)
        if(vcounter >= (81 + 32*p) && vcounter < (111 + 32*p))
        R_num = p[4:0];
    end

//============================================================
//    随机方块类型选择
//============================================================
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rnd <= 32'hACE1_2C7B;
        else
        rnd <= {rnd[30:0], rnd_fb_eff};
    end

//    自由计数: 给随机取样与 Idle 搅动用
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rnd_cnt <= 16'd0;
        else
        rnd_cnt <= rnd_cnt + 16'd1;
    end

//    P1 当前方块类型: 到下一块或 Hold 时替换
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type <= 3'd0;
        else if(Idle)
        type <= rnd_type_t;
        else if((land_pulse || hold_up) && Playing)
        type <= type_t;
    end

//    P1 下一块类型: 显示在画面 Next 框上半
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_t <= 3'd0;
        else if(Idle)
        type_t <= rnd_type_n;
        else if(hold_down)
        type_t <= hold_type;
        else if(land_pulse && Playing)
        type_t <= rnd_type_n;
    end

//    P1 落锁时的类型: 交给 frame 定格子颜色
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_d <= 3'd0;
        else if(land_pulse && Playing)
        type_d <= type;
    end

//============================================================
//    按键信号处理
//    P1 软降计时: 满 MCNT 才认一次软降
    always@(posedge Clk_74M or negedge Reset_n)
    if(!Reset_n)
    counter <= 30'd0;
    else if(!drop_en)
    counter <= 30'd0;
    else if(counter < MCNT)
    counter <= counter + 30'd1;

//    P1 硬降标志: 按一次只吃一次, 松键后复位
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        drop_r_t <= 1'b1;
        else if(drop_hold)
        drop_r_t <= 1'b0;
        else if(drop_r_flag)
        drop_r_t <= 1'b1;
    end

//============================================================
//    自动下落与参考点移动
//    P1 自动下落计时: 满 Drop 自动降一格
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_drop <= 1'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_drop <= 10'd0;
            else
            counter_drop <= counter_drop;
        end
        else if(Stop)
        counter_drop <= counter_drop;
        else if(Playing)begin
            if(counter_drop == Drop)
            counter_drop <= 1'd0;
            else
            counter_drop <= counter_drop + 1'd1;
        end
        else
        counter_drop <= 1'd0;
    end
    
    wire [2:0]lv_score = (score >= LV7_TH) ? 3'd7 :
                         (score >= LV6_TH) ? 3'd6 :
                         (score >= LV5_TH) ? 3'd5 :
                         (score >= LV4_TH) ? 3'd4 :
                         (score >= LV3_TH) ? 3'd3 :
                         (score >= LV2_TH) ? 3'd2 :
                         (score >= LV1_TH) ? 3'd1 : 3'd0;

    wire [2:0]lv_time_s = (time_sec >= TIME_LV7) ? 3'd7 :
                         (time_sec >= TIME_LV6) ? 3'd6 :
                         (time_sec >= TIME_LV5) ? 3'd5 :
                         (time_sec >= TIME_LV4) ? 3'd4 :
                         (time_sec >= TIME_LV3) ? 3'd3 :
                         (time_sec >= TIME_LV2) ? 3'd2 :
                         (time_sec >= TIME_LV1) ? 3'd1 : 3'd0;

    wire [2:0]lv_time_d = (time_sec >= TIME_LV7_D) ? 3'd7 :
                         (time_sec >= TIME_LV6_D) ? 3'd6 :
                         (time_sec >= TIME_LV5_D) ? 3'd5 :
                         (time_sec >= TIME_LV4_D) ? 3'd4 :
                         (time_sec >= TIME_LV3_D) ? 3'd3 :
                         (time_sec >= TIME_LV2_D) ? 3'd2 :
                         (time_sec >= TIME_LV1_D) ? 3'd1 : 3'd0;

    //    双人: 时间阈值放宽; 规则仍为 分数等级/时间等级 取较大值
    wire [2:0]lv_time  = duo ? lv_time_d : lv_time_s;

    wire [2:0]lv_now   = (lv_score > lv_time) ? lv_score : lv_time;

//    速度等级: 分数等级与时间等级取较大值
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        speed_level <= 0;
        else
        speed_level <= lv_now;
    end
    
//    自动下落间隔: 按速度等级查表
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        Drop <= MCNT_Drop;
        else
        case(speed_level)
        0:Drop <= (MCNT_Drop*64'd80)/64'd100;
        1:Drop <= (MCNT_Drop*64'd71)/64'd100;
        2:Drop <= (MCNT_Drop*64'd63)/64'd100;
        3:Drop <= (MCNT_Drop*64'd55)/64'd100;
        4:Drop <= (MCNT_Drop*64'd46)/64'd100;
        5:Drop <= (MCNT_Drop*64'd38)/64'd100;
        6:Drop <= (MCNT_Drop*64'd30)/64'd100;
        7:Drop <= (MCNT_Drop*64'd21)/64'd100;
        endcase
     end

//    参考点移动
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_r <= 5'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_r <= 5'd0;
            else
            counter_r <= counter_r;
        end
        else if(Stop)
        counter_r <= counter_r;
        else if(Playing)begin
            if(land_we)
            counter_r <= counter_r;
            else if(land_pulse || hold_up)//归位
            counter_r <= 5'd0;
            else if(drop_r && !land && !lock_we && !other_down_hold)//软降
            counter_r <= counter_r + 1'd1;
            else if(drop_hold && !lock_we)//硬降
            counter_r <= counter_ghost_r_t;
            else if(en_rotate)//旋转
            counter_r <= counter_r + ddr_ext;
            else if(counter_drop == Drop && !land && !lock_we && !other_down_hold)//自动下落
            counter_r <= counter_r + 1'd1;
        end
        else
        counter_r <= 5'd0;
    end

//    P1 参考点列: 左右移动/旋转/归位(双人出生列 8)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_c <= SPAWN_C1;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_c <= SPAWN_C1;
            else
            counter_c <= counter_c;
        end
        else if(Stop)
        counter_c <= counter_c;
        else if(Playing)begin
            if(land_we)
            counter_c <= counter_c;
            else if(land_pulse || hold_up)//归位
            counter_c <= SPAWN_C1;
            else if(en_rotate)//旋转
            counter_c <= counter_c + ddc_ext;
            else if(!boundary_collision_left && left_p_flag && !lock_we)//左移
            counter_c <= counter_c - 1;
            else if(!boundary_collision_right && right_p_flag && !lock_we)//右移
            counter_c <= counter_c + 1;
        end
        else
        counter_c <= SPAWN_C1;
    end

//============================================================
//    方块旋转序号
//============================================================
    Tetromino Tetromino_inst1(
        .clka(Clk_74M),
        .addra(Tetromino_addr1),
        .douta(Tetromino_dout1)
    );

    weiyibiao weiyibiao_inst(
        .clka(Clk_74M),
        .addra(weiyibiao_addr),
        .douta(weiyibiao_dout)
    );

    assign weiyibiao_addr = {type[2:0],rot[1:0]};

//    P1 旋转预判: 转过去会不会出界或撞到已落格
    always@(*)begin
        Tetromino_addr1 = {type[2:0], (rot[1:0] + 1)};
        rot_block = 1'b0;
        for(k = 0; k < 4; k = k + 1)begin
            cc_r = counter_c + ddc_ext + { { 7{Tetromino_dout1[k*8+7]} }, Tetromino_dout1[(k*8+7)-:4] };
            rr_r = counter_r + ddr_ext + { { 7{Tetromino_dout1[k*8+3]} }, Tetromino_dout1[(k*8+3)-:4] };
            if((cc_r > (COL - 1'b1)) || cc_r[5])
            rot_block = 1'b1;
            else if((rr_r > 11'd19) && !rr_r[5])
            rot_block = 1'b1;
            else if((cc_r <= (COL - 1'b1)) && (rr_r <= 11'd19) && row_w[rr_r][cc_r])
            rot_block = 1'b1;
        end
        en_rotate = (rotate_p_flag) && (!rot_block) && (!lock_we);
    end

//    P1 当前旋转序号
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rot <= 2'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            rot <= 2'd0;
            else
            rot <= rot;
        end
        else if(Stop)
        rot <= rot;
        else if(Playing)begin
            if(land_we)
            rot <= rot;
            else if(en_rotate)
            rot <= rot + 2'd1;
            else if(land_pulse || hold_up)
            rot <= 2'd0;
        end
        else
        rot <= 2'd0;
    end

//============================================================
//    落地计时与锁定
//    P1 落底停留计时: 满 MCNT_LAND 就开始锁存
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_land <= 1'b0;
        else if(Playing)begin
            if(land && !lock_we)
            counter_land <= counter_land + 30'd1;
            else
            counter_land <= 1'b0;
        end
        else
        counter_land <= 1'b0;
    end

    wire land_pulse_t = (land) && (counter_land == MCNT_LAND);

//    P1 锁存启动
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_t <= 1'b0;
        else if(land_pulse)
        lock_t <= 1'b1;
        else
        lock_t <= 1'b0;
    end

//    P1 锁存计数: 4 个格子一拍写一个
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_cnt <= 2'd0;
        else if(lock_t)
        lock_cnt <= 2'd1;
        else if(lock_cnt == 2'd3)
        lock_cnt <= 2'd0;
        else if(lock_cnt != 2'd0)
        lock_cnt <= lock_cnt + 2'd1;
    end
    
//    闪白
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_counter <= 2'd0;
        else if(land_pulse_t)
        lock_counter <= 2'd1;
        else if(lock_counter == 5940000)
        lock_counter <= 2'd0;
        else if(lock_counter != 2'd0)
        lock_counter <= lock_counter + 2'd1;
    end
    
    assign land_we = (lock_counter != 0) && (lock_counter != 5940000) && (lock_counter[21]);
    assign land_pulse = (lock_counter == 5940000) ? 1:0;

    assign lock_we  = (lock_t) || (lock_cnt != 2'd0);
    assign lock_idx = (lock_t) ? 2'd0 : lock_cnt;

//    P1 落锁时 4 个格子的列
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            cc_t[0] <= 11'd0; cc_t[1] <= 11'd0; cc_t[2] <= 11'd0; cc_t[3] <= 11'd0;
        end
        else if(land_pulse)
        for(y = 0; y < 4; y = y + 1)
        cc_t[y] <= counter_c + { {7{Tetromino_dout[y*8+7]}}, Tetromino_dout[y*8+7 -:4] };
    end

//    P1 落锁时 4 个格子的行
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            rr_t[0] <= 11'd0; rr_t[1] <= 11'd0; rr_t[2] <= 11'd0; rr_t[3] <= 11'd0;
        end
        else if(land_pulse)
        for(y = 0; y < 4; y = y + 1)
        rr_t[y] <= counter_r + { {7{Tetromino_dout[y*8+3]}}, Tetromino_dout[y*8+3 -:4] };
    end

    assign cc_d = {cc_t[0],cc_t[1], cc_t[2],cc_t[3]};
    assign rr_d = {rr_t[0],rr_t[1], rr_t[2],rr_t[3]};

//============================================================
//    场地状态与消行
//============================================================
//    场地状态: 直接存 480 位(state), 写口一次写一行(清零/落锁/消行搬移都在这里)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        state <= 480'd0;
        else if(Idle)
        state <= 480'd0;
        else if(Finalize)begin
            if(switch_r_flag)begin
                state <= 480'd0;
            end
            else begin
                state <= state;
            end
        end
        else if(lock_we || (duo && lock_we2))begin
            if(lock_we && (cc_t[lock_idx] <= (COL - 1'b1)) && (rr_t[lock_idx] <= 19))
            state[cc_t[lock_idx]*20 + rr_t[lock_idx]] <= 1'b1;
            if(duo && lock_we2 && (cc_t2[lock_idx2] <= (COL - 1'b1)) && (rr_t2[lock_idx2] <= 19))
            state[cc_t2[lock_idx2]*20 + rr_t2[lock_idx2]] <= 1'b1;
        end
        else if(clear_time)begin
            if(clear_t)begin
                for(c = 0; c < 24; c = c + 1)
                        for(m = 0; m < 20; m = m + 1)
                            if(line_t[m])
                                state[c*20 + m] <= state[c*20 + m];
            end
            else if(!clear_pulse)begin
                for(c = 0; c < 24; c = c + 1)begin
                    state[c*20 + 0] <= 1'b0;
                    for(m = 1; m < 20; m = m + 1)begin
                        if(m <= clear_row)begin
                            state[c*20 + m] <= state[c*20 + m - 1];
                        end
                    end
                end
            end
        end
    end

//    整行判满: 24 格全满的行要消
    always@(*)begin : blk4
        integer m;
        clear = 1'b0;
        line = 20'd0;
        for(m = 0; m < 20; m = m + 1)begin
            if(&(row_w[m] | ~full_mask))begin
                line[m] = 1'b1;
                clear = 1'b1;
            end
        end
    end
    
    assign clear_time = clear_t || clear;
    
//    闪白次数: 消 n 行闪 2n 下
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cl_stop <= 4'd0;
    else if(!clear_t)
    cl_stop <= 4'd0;
    else if(clear_tick == 3'd0)
    cl_stop <= (d_clear << 1) - 4'd1;
    end

//    闪白分频计数
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_cnt <= 0;
    else if(!clear_t)
    clear_cnt <= 0;
    else if(clear_cnt == CLEAR_STEP)
    clear_cnt <= 0;
    else
    clear_cnt <= clear_cnt + 1;
    end

    assign clear_step = (clear_t) && (clear_cnt == CLEAR_STEP);

//    闪白标志: 消行动画期间锁住场地
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t <= 1'b0;
    else if(clear_pulse)
    clear_t <= 1'b1;
    else if(clear_step && clear_tick == cl_stop)
    clear_t <= 1'b0;
    end

//    闪白节拍
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_tick <= 3'd0;
    else if(!clear_t)
    clear_tick <= 3'd0;
    else if(clear_step)begin
        if(clear_tick == cl_stop)
        clear_tick <= 3'd0;
        else
        clear_tick <= clear_tick + 3'd1;
    end
    end

//    已消行计数(动画用)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    cl_tick <= 3'd0;
    else if(!clear_t)
    cl_tick <= 3'd0;
    else if(clear_step && cl_tick < d_clear)
    cl_tick <= cl_tick + 3'd1;
    end

//    消行节拍脉冲: 每消一行给一拍
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_t_t <= 1'b0;
    else
    clear_t_t <= clear_step && (cl_tick < d_clear);
    end

//    闪白翻转: 亮/暗交替
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    clear_flash <= 1'b1;
    else if(clear_pulse)
    clear_flash <= 1'b1;
    else if(clear_step)
    clear_flash <= !clear_flash;
    end

//    正在消的行标记
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    line_t <= 20'd0;
    else if(clear_pulse)
    line_t <= 20'd1 << clear_row;
    else if(clear_t_t)
    line_t <= line_t | line_d;
    else if(!clear_time)
    line_t <= 20'd0;
    end

//    找出还没开始消的下一行
    always@(*)begin : blk5
        integer m;
    line_d = 20'd0;
    for(m = 0; m < 20; m = m + 1)
    if(line[m] && !line_t[m])
    line_d = (20'd1 << m);
    end

//    消行搬移的上界行(最高的满行)
    always@(*)begin : blk6
        integer m;
        clear_row = 5'd0;
        for(m = 0; m < 20; m = m + 1)
        if(line[m])
        clear_row = m[4:0];
    end

//    消行开始的沿检测(延迟一拍)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        clear_d <= 1'b0;
        else
        clear_d <= clear_time;
    end

    assign clear_pulse = (clear_time) && (!clear_d);

//    本次消掉的行数(给计分/等级用)
    always@(posedge Clk_74M or negedge Reset_n)begin
    if(!Reset_n)
    c_clear <= 5'd0;
    else if(clear_t_t)
    c_clear <= d_clear;
    end

//============================================================
//    Ghost 方块
//============================================================
//============================================================
//    P1 幽灵落点: 通用逐行扫描(地板/已落格/对方运动方块)
//============================================================
    always@(*)begin
        ghost_blocked1 = 1'b0;
        ghost_blk_state1 = 1'b0;
        ghost_blk_other1 = 1'b0;
        for(jg1 = 0; jg1 < 4; jg1 = jg1 + 1)begin
            gc1 = counter_c + { { 7{Tetromino_dout[jg1*8+7]} }, Tetromino_dout[(jg1*8+7)-:4] };
            gr1 = ghost_scan_r + { { 7{Tetromino_dout[jg1*8+3]} }, Tetromino_dout[(jg1*8+3)-:4] };
            if((!gr1[5]) && (gr1 > 6'd19))
            ghost_blocked1 = 1'b1;
            else if((!gr1[5]) && (gc1 <= (COL - 1'b1)) && row_w[gr1][gc1])begin
                ghost_blocked1 = 1'b1;
                ghost_blk_state1 = 1'b1;
            end
            else if(duo)begin
                                if((gr1 == or2_0) && (gc1 == oc2_0))begin
                    ghost_blocked1 = 1'b1;
                    ghost_blk_other1 = 1'b1;
                end
                if((gr1 == or2_1) && (gc1 == oc2_1))begin
                    ghost_blocked1 = 1'b1;
                    ghost_blk_other1 = 1'b1;
                end
                if((gr1 == or2_2) && (gc1 == oc2_2))begin
                    ghost_blocked1 = 1'b1;
                    ghost_blk_other1 = 1'b1;
                end
                if((gr1 == or2_3) && (gc1 == oc2_3))begin
                    ghost_blocked1 = 1'b1;
                    ghost_blk_other1 = 1'b1;
                end
            end
        end
    end

//    幽灵扫描状态机: 触发重扫 -> 逐行推进 -> 锁存落点
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            ghost_scan_r <= 5'd0;
            ghost_done <= 1'b0;
            ghost_blk_oth <= 1'b0;
            counter_ghost_r_t <= 5'd0;
        end
        else if(ghost_restart1)begin
            ghost_scan_r <= counter_r;
            ghost_done <= 1'b0;
            ghost_blk_oth <= 1'b0;
        end
        else if(!ghost_done)begin
            if(ghost_blocked1)begin
                ghost_done <= 1'b1;
                ghost_blk_oth <= ghost_blk_other1;
                counter_ghost_r_t <= (ghost_scan_r > counter_r) ? (ghost_scan_r - 5'd1) : counter_r;
            end
            else if(ghost_scan_r < 5'd21)//上限 21: 形状行偏移都 >= -1, 到 21 必被地板挡住, 落点自然是 20
            ghost_scan_r <= ghost_scan_r + 5'd1;
            else
            ghost_done <= 1'b1;
        end
    end

//    延迟寄存(供重启条件使用)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            sig_p1_d <= 16'd0;
            sig_p2_d <= 16'd0;
            counter_r_d1 <= 5'd0;
            counter_r2_d1 <= 5'd0;
        end
        else begin
            sig_p1_d <= sig_p1;
            sig_p2_d <= sig_p2;
            counter_r_d1 <= counter_r;
            counter_r2_d1 <= counter_r2;
        end
    end

//============================================================
//    Hold 功能
//    P1 Hold 键按下/松开状态
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        en_hold <= 0;
        else if(Idle)
        en_hold <= 1'b0;
        else if(Stop)
        en_hold <= en_hold;
        else if(Finalize)begin
            if(switch_r_flag)
            en_hold <=1'b0;
            else
            en_hold <= en_hold;
        end
        else if(!en_hold && hold_p_flag)
        en_hold <= 1;
        else if(en_hold && hold_p_flag)
        en_hold <= 0;
    end

//    P1 Hold 键延迟一拍: 用来取按下/松开边沿
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        en_hold_t <= 0;
        else
        en_hold_t <= en_hold;
    end

//    Hold 槽内容(两人共用一个)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        hold_type <= 0;
        else if(hold_up)
        hold_type <= type;
        else if(hold_up2)
        hold_type <= type2;
    end

//============================================================
//    游戏结束判断
//============================================================
    always@(*)begin
        if(Idle)
        over <= 1'b0;
        else if(Finalize)begin
            if(switch_r_flag)
            over <=1'b0;
            else
            over <=1'b0;
        end
        else if((touch_top || (duo && touch_top2)) && Playing && !lock_we && !(duo && lock_we2))
        over <= 1'b1;
        else
        over <= 1'b0;
    end

//    P2 形状 ROM
    Tetromino Tetromino_inst2(
        .clka(Clk_74M),
        .addra(Tetromino_addr2),
        .douta(Tetromino_dout2)
    );

    Tetromino Tetromino_inst3(
        .clka(Clk_74M),
        .addra(Tetromino_addr3),
        .douta(Tetromino_dout3)
    );

    assign type2_out = type2;
    assign type_d2_out = type_d2;
    assign type_t2_out = type_t2;

    //    C_num2/R_num2 与 C_num/R_num 完全同源(同一次搜索), 直接复用省逻辑
    assign C_num2 = C_num;
    assign R_num2 = R_num;

    assign land_we2  = (lock_counter2 != 0) && (lock_counter2 != 5940000) && (lock_counter2[21]);
    assign land_pulse2 = (lock_counter2 == 5940000) ? 1 : 0;
    assign lock_we2  = (lock_t2) || (lock_cnt2 != 2'd0);
    assign lock_idx2 = (lock_t2) ? 2'd0 : lock_cnt2;
    assign cc_d2 = {cc_t2[0], cc_t2[1], cc_t2[2], cc_t2[3]};
    assign rr_d2 = {rr_t2[0], rr_t2[1], rr_t2[2], rr_t2[3]};

//    P2 独立的降键/落地/旋转偏移(修复克隆漏改)
    assign drop_hold2 = (counter2 == MCNT) && (drop_r_t2);
    assign drop_r2    = (drop_r_t2) && (drop_r_flag2);
    assign land_pulse_t2 = (land2) && (counter_land2 == MCNT_LAND);
    //    同拍两人取样: P2 取下一个值(开局 Idle 同时装载也算同拍)
    wire p2_late;
    assign p2_late = Idle || (land_pulse && land_pulse2);

    weiyibiao weiyibiao_inst2(
        .clka(Clk_74M),
        .addra(weiyibiao_addr2),
        .douta(weiyibiao_dout2)
    );

    assign weiyibiao_addr2 = {type2[2:0],rot2[1:0]};
    assign ddc2     = weiyibiao_dout2[7:4];
    assign ddr2     = weiyibiao_dout2[3:0];
    assign ddc_ext2 = {{7{ddc2[3]}}, ddc2};
    assign ddr_ext2 = {{7{ddr2[3]}}, ddr2};

//============================================================
//    P2 幽灵落点: 通用逐行扫描
//============================================================
    always@(*)begin
        ghost_blocked2 = 1'b0;
        ghost_blk_state2 = 1'b0;
        ghost_blk_other2 = 1'b0;
        for(jg2 = 0; jg2 < 4; jg2 = jg2 + 1)begin
            gc2 = counter_c2 + { { 7{Tetromino_dout2[jg2*8+7]} }, Tetromino_dout2[(jg2*8+7)-:4] };
            gr2 = ghost_scan_r2 + { { 7{Tetromino_dout2[jg2*8+3]} }, Tetromino_dout2[(jg2*8+3)-:4] };
            if((!gr2[5]) && (gr2 > 6'd19))
            ghost_blocked2 = 1'b1;
            else if((!gr2[5]) && (gc2 <= (COL - 1'b1)) && row_w[gr2][gc2])begin
                ghost_blocked2 = 1'b1;
                ghost_blk_state2 = 1'b1;
            end
            else if(duo)begin
                                if((gr2 == or1_0) && (gc2 == oc1_0))begin
                    ghost_blocked2 = 1'b1;
                    ghost_blk_other2 = 1'b1;
                end
                if((gr2 == or1_1) && (gc2 == oc1_1))begin
                    ghost_blocked2 = 1'b1;
                    ghost_blk_other2 = 1'b1;
                end
                if((gr2 == or1_2) && (gc2 == oc1_2))begin
                    ghost_blocked2 = 1'b1;
                    ghost_blk_other2 = 1'b1;
                end
                if((gr2 == or1_3) && (gc2 == oc1_3))begin
                    ghost_blocked2 = 1'b1;
                    ghost_blk_other2 = 1'b1;
                end
            end
        end
    end

//    P2 幽灵扫描状态机: 触发重扫 -> 逐行推进 -> 锁存落点
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            ghost_scan_r2 <= 5'd0;
            ghost_done2 <= 1'b0;
            ghost_blk_oth2 <= 1'b0;
            counter_ghost_r_t2 <= 5'd0;
        end
        else if(ghost_restart2)begin
            ghost_scan_r2 <= counter_r2;
            ghost_done2 <= 1'b0;
            ghost_blk_oth2 <= 1'b0;
        end
        else if(!ghost_done2)begin
            if(ghost_blocked2)begin
                ghost_done2 <= 1'b1;
                ghost_blk_oth2 <= ghost_blk_other2;
                counter_ghost_r_t2 <= (ghost_scan_r2 > counter_r2) ? (ghost_scan_r2 - 5'd1) : counter_r2;
            end
            else if(ghost_scan_r2 < 5'd21)//同上: 上限 21, 落点自然到 20
            ghost_scan_r2 <= ghost_scan_r2 + 5'd1;
            else
            ghost_done2 <= 1'b1;
        end
    end

//============================================================
//    P2 逻辑(与 P1 一一对应)
//============================================================
//    P2 运动方块显示与判定: 形状查表 / 落底 / 左右边界 / 顶到 / 幽灵 / 与对方运动方块互撞
    always@(*)begin
        Tetromino_addr2 = {type2[2:0], rot2[1:0]};
        Piece2 = 1'b0;
        land2 = 1'b0;
        boundary_collision_left2 = 1'b0;
        boundary_collision_right2 = 1'b0;
        ghost2 = 1'b0;
        touch_top2 = 1'b0;
        other_down_hold2 = 1'b0;
        if(Idle || Finalize || !duo)begin//单人模式下 P2 不显示也不下落
             Piece2 = 1'b0;
             ghost2 = 1'b0;
             land2 = 1'b1;
        end
        else
        for(i2 = 0; i2 < 4; i2 = i2 + 1)begin
            cc2 = counter_c2 + { { 7{Tetromino_dout2[i2*8+7]} }, Tetromino_dout2[(i2*8+7)-:4] };
            rr2 = counter_r2 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
            //    与对方运动方块互撞
            if(duo)begin
                if(or1_0 == rr2)begin
                    if((cc2 > 0) && (oc1_0 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_0 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_0 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_0 == cc2) && (or1_0 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && row_w[rr2 + 6'd1][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_1 == rr2)begin
                    if((cc2 > 0) && (oc1_1 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_1 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_1 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_1 == cc2) && (or1_1 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && row_w[rr2 + 6'd1][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_2 == rr2)begin
                    if((cc2 > 0) && (oc1_2 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_2 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_2 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_2 == cc2) && (or1_2 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && row_w[rr2 + 6'd1][cc2]))
                other_down_hold2 = 1'b1;
                if(or1_3 == rr2)begin
                    if((cc2 > 0) && (oc1_3 == (cc2 - 6'd1))) boundary_collision_left2 = 1'b1;
                    if(oc1_3 == (cc2 + 6'd1)) boundary_collision_right2 = 1'b1;
                    if(oc1_3 == cc2) touch_top2 = 1'b1;
                end
                if((oc1_3 == cc2) && (or1_3 == (rr2 + 6'd1)) && (rr2 < 11'd19) && !((cc2 <= (COL - 1'b1)) && row_w[rr2 + 6'd1][cc2]))
                other_down_hold2 = 1'b1;
            end
            if(rr2 == 19 || ((cc2 <= (COL - 1'b1)) && (rr2 < 19) && row_w[rr2 + 6'd1][cc2]))//落底检测
            land2 = 1'b1;
            if(cc2 == 0 || ((cc2 > 0) && (cc2 <= (COL - 1'b1)) && (rr2 < 11'd20) && row_w[rr2][cc2 - 6'd1]))//左边界碰撞检测
            boundary_collision_left2 = 1'b1;
            if(cc2 >= (COL - 1'b1) || ((cc2 < (COL - 1'b1)) && (rr2 < 11'd20) && row_w[rr2][cc2 + 6'd1]))//右边界碰撞检测
            boundary_collision_right2 = 1'b1;
            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc2) && (R_num == rr2) && !rr2[5]) //正在运动方块
            Piece2 = 1'b1;
            if((!rr2[5]) && (cc2 <= (COL - 1'b1)) && (rr2 <= 11'd19) && row_w[rr2][cc2])//和已锁方块重叠=顶到
            touch_top2 = 1'b1;
            rr_g2 = counter_ghost_r_t2 + { { 7{Tetromino_dout2[i2*8+3]} }, Tetromino_dout2[(i2*8+3)-:4] };
            if((hcounter >= 321) && (hcounter < (321 + 32*COL)) && (vcounter >= 81) && (vcounter < 721) && (C_num == cc2) && (R_num == rr_g2) && !rr_g2[5] && (!ghost_blk_oth2) && ghost_done2 && (!clear_time) && (counter_ghost_r_t2 > (counter_r2 + 5'd4)))
            ghost2 = 1'b1;
        end
    end

//    P2 当前方块类型: 到下一块或 Hold 时替换
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type2 <= 3'd0;
        else if(Idle)
        type2 <= p2_late ? rnd_type_t1 : rnd_type_t;
        else if((land_pulse2 || hold_up2) && Playing)
        type2 <= type_t2;
    end

//    P2 下一块类型: 显示在画面 Next 框下半
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_t2 <= 3'd0;
        else if(Idle)
        type_t2 <= p2_late ? rnd_type_n1 : rnd_type_n;
        else if(hold_down2)
        type_t2 <= hold_type;
        else if(land_pulse2 && Playing)
        type_t2 <= ((land_pulse && land_pulse2) ? rnd_type_n1 : rnd_type_n);
    end

//    P2 落锁时的类型: 交给 frame 定格子颜色
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        type_d2 <= 3'd0;
        else if(land_pulse2 && Playing)
        type_d2 <= type2;
    end

//    P2 软降计时: 满 MCNT 才认一次软降
    always@(posedge Clk_74M or negedge Reset_n)
    if(!Reset_n)
    counter2 <= 30'd0;
    else if(!drop_en2)
    counter2 <= 30'd0;
    else if(counter2 < MCNT)
    counter2 <= counter2 + 30'd1;

//    P2 硬降标志: 按一次只吃一次, 松键后复位
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        drop_r_t2 <= 1'b1;
        else if(drop_hold2)
        drop_r_t2 <= 1'b0;
        else if(drop_r_flag2)
        drop_r_t2 <= 1'b1;
    end

//    P2 自动下落计时: 满 Drop 自动降一格
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_drop2 <= 1'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_drop2 <= 10'd0;
            else
            counter_drop2 <= counter_drop2;
        end
        else if(Stop)
        counter_drop2 <= counter_drop2;
        else if(Playing)begin
            if(counter_drop2 == Drop)
            counter_drop2 <= 1'd0;
            else
            counter_drop2 <= counter_drop2 + 1'd1;
        end
        else
        counter_drop2 <= 1'd0;
    end

//    P2 参考点行: 软降/硬降/旋转/归位都改它
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_r2 <= 5'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_r2 <= 5'd0;
            else
            counter_r2 <= counter_r2;
        end
        else if(Stop)
        counter_r2 <= counter_r2;
        else if(Playing)begin
            if(land_we2)
            counter_r2 <= counter_r2;
            else if(land_pulse2 || hold_up2)//归位
            counter_r2 <= 5'd0;
            else if(drop_r2 && !land2 && !lock_we2 && !other_down_hold2)//软降
            counter_r2 <= counter_r2 + 1'd1;
            else if(drop_hold2 && !lock_we2)//硬降
            counter_r2 <= counter_ghost_r_t2;
            else if(en_rotate2)//旋转
            counter_r2 <= counter_r2 + ddr_ext2;
            else if(counter_drop2 == Drop && !land2 && !lock_we2 && !other_down_hold2)//自动下落
            counter_r2 <= counter_r2 + 1'd1;
        end
        else
        counter_r2 <= 5'd0;
    end

//    P2 参考点列: 左右移动/旋转/归位(双人出生列 16)
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_c2 <= SPAWN_C2;
        else if(Finalize)begin
            if(switch_r_flag)
            counter_c2 <= SPAWN_C2;
            else
            counter_c2 <= counter_c2;
        end
        else if(Stop)
        counter_c2 <= counter_c2;
        else if(Playing)begin
            if(land_we2)
            counter_c2 <= counter_c2;
            else if(land_pulse2 || hold_up2)//归位
            counter_c2 <= SPAWN_C2;
            else if(en_rotate2)//旋转
            counter_c2 <= counter_c2 + ddc_ext2;
            else if(!boundary_collision_left2 && left_p_flag2 && !lock_we2)//左移
            counter_c2 <= counter_c2 - 1;
            else if(!boundary_collision_right2 && right_p_flag2 && !lock_we2)//右移
            counter_c2 <= counter_c2 + 1;
        end
        else
        counter_c2 <= SPAWN_C2;
    end

//    P2 旋转预判: 转过去会不会出界或撞到已落格
    always@(*)begin
        Tetromino_addr3 = {type2[2:0], (rot2[1:0] + 1)};
        rot_block2 = 1'b0;
        for(k2 = 0; k2 < 4; k2 = k2 + 1)begin
            cc_r2 = counter_c2 + ddc_ext2 + { { 7{Tetromino_dout3[k2*8+7]} }, Tetromino_dout3[(k2*8+7)-:4] };
            rr_r2 = counter_r2 + ddr_ext2 + { { 7{Tetromino_dout3[k2*8+3]} }, Tetromino_dout3[(k2*8+3)-:4] };
            if((cc_r2 > (COL - 1'b1)) || cc_r2[5])
            rot_block2 = 1'b1;
            else if((rr_r2 > 11'd19) && !rr_r2[5])
            rot_block2 = 1'b1;
            else if((cc_r2 <= (COL - 1'b1)) && (rr_r2 <= 11'd19) && row_w[rr_r2][cc_r2])
            rot_block2 = 1'b1;
        end
        en_rotate2 = (rotate_p_flag2) && (!rot_block2) && (!lock_we2);
    end

//    P2 当前旋转序号
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        rot2 <= 2'd0;
        else if(Finalize)begin
            if(switch_r_flag)
            rot2 <= 2'd0;
            else
            rot2 <= rot2;
        end
        else if(Stop)
        rot2 <= rot2;
        else if(Playing)begin
            if(land_we2)
            rot2 <= rot2;
            else if(en_rotate2)
            rot2 <= rot2 + 2'd1;
            else if(land_pulse2 || hold_up2)
            rot2 <= 2'd0;
        end
        else
        rot2 <= 2'd0;
    end

//    P2 落底停留计时: 满 MCNT_LAND 就开始锁存
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        counter_land2 <= 1'b0;
        else if(Playing)begin
            if(land2 && !lock_we2)
            counter_land2 <= counter_land2 + 30'd1;
            else
            counter_land2 <= 1'b0;
        end
        else
        counter_land2 <= 1'b0;
    end

//    P2 锁存启动
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_t2 <= 1'b0;
        else if(land_pulse2)
        lock_t2 <= 1'b1;
        else
        lock_t2 <= 1'b0;
    end

//    P2 锁存计数: 4 个格子一拍写一个
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_cnt2 <= 2'd0;
        else if(lock_t2)
        lock_cnt2 <= 2'd1;
        else if(lock_cnt2 == 2'd3)
        lock_cnt2 <= 2'd0;
        else if(lock_cnt2 != 2'd0)
        lock_cnt2 <= lock_cnt2 + 2'd1;
    end

//    P2 锁存闪白计时
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        lock_counter2 <= 2'd0;
        else if(land_pulse_t2)
        lock_counter2 <= 2'd1;
        else if(lock_counter2 == 5940000)
        lock_counter2 <= 2'd0;
        else if(lock_counter2 != 2'd0)
        lock_counter2 <= lock_counter2 + 2'd1;
    end

//    P2 落锁时 4 个格子的列
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            cc_t2[0] <= 11'd0; cc_t2[1] <= 11'd0; cc_t2[2] <= 11'd0; cc_t2[3] <= 11'd0;
        end
        else if(land_pulse2)
        for(y = 0; y < 4; y = y + 1)
        cc_t2[y] <= counter_c2 + { {7{Tetromino_dout2[y*8+7]}}, Tetromino_dout2[y*8+7 -:4] };
    end

//    P2 落锁时 4 个格子的行
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)begin
            rr_t2[0] <= 11'd0; rr_t2[1] <= 11'd0; rr_t2[2] <= 11'd0; rr_t2[3] <= 11'd0;
        end
        else if(land_pulse2)
        for(y = 0; y < 4; y = y + 1)
        rr_t2[y] <= counter_r2 + { {7{Tetromino_dout2[y*8+3]}}, Tetromino_dout2[y*8+3 -:4] };
    end

//    P2 Hold 键按下/松开状态
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        en_hold2 <= 0;
        else if(Idle)
        en_hold2 <= 1'b0;
        else if(Stop)
        en_hold2 <= en_hold2;
        else if(Finalize)begin
            if(switch_r_flag)
            en_hold2 <=1'b0;
            else
            en_hold2 <= en_hold2;
        end
        else if(!en_hold2 && hold_p_flag2)
        en_hold2 <= 1;
        else if(en_hold2 && hold_p_flag2)
        en_hold2 <= 0;
    end

//    P2 Hold 键延迟一拍: 用来取按下/松开边沿
    always@(posedge Clk_74M or negedge Reset_n)begin
        if(!Reset_n)
        en_hold_t2 <= 0;
        else
        en_hold_t2 <= en_hold2;
    end

endmodule
